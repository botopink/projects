# Front 50 — onze CLI

**Track:** E onze
**Priority:** medium — an app that cannot be scaffolded, served or built is a library with no users;
but nothing else in the milestone is blocked by it, which is why it is medium and not high
**Target:** both — and the split is per command. The CLI *process* compiles to commonJS, because it
runs on a developer's machine before any server exists. `create` drives neither half; `dev` and
`build` drive both (the erlang half is the compiled server, the js half is the client bundle front 68
emits); `start` drives only the erlang half, since by then the js half is a directory of files
**Wave:** 9
**Depends on:** 49 (config, alias map, registry), 01 (`process`, `path`), 22 (the route table the
generated manifest registers into), 26 · 48 (per the wave table), 68 (the client bundle `build`
drives), 71 (the release `start` runs), 60 (the prerender pass `build` invokes)
**Owns:** `modules/onze-cli/src/**`, `modules/onze-cli/test/**`
**Does not touch:** `repository/onze/src/**` (F49 · F51 · F52), `repository/onze/examples/blog/**`
(F53), `repository/onze/modules/onze-bundler/**` (F68),
`repository/onze/modules/onze-release/**` (F71), every other repository
**Reference:** `NEXTJS-DOCS.md § 29. CLI`, `§ 2. Instalação e Configuração`,
`§ 24. Deploy` (what `start` runs) ·
<https://nextjs.org/docs/app/api-reference/cli/next> ·
<https://nextjs.org/docs/app/api-reference/cli/create-next-app>

---

## Problem

There is no way to go from "I want an onze app" to a served page. `botopink build` compiles a
package; it does not know what `app/` is, it does not generate a route manifest, it does not start a
BEAM node, and it does not produce a browser bundle. `bpmp` installs dependencies and stops there.

The gap is concrete in three places. First, the `app/` convention only exists if something walks the
directory — front 49 establishes that this walk cannot happen at comptime (botopink's comptime sees
declarations, not directories), so a build-time walker is not an optimization, it is the only
mechanism. Second, front 68's client bundle needs a caller: the bundler is a library, and something
has to hand it the route table and the output directory. Third, the milestone's exit gate says
`repository/onze/examples/blog` must render "under both `onze dev` and `onze build` &&
`onze start`" — those are four commands that do not exist, named in a gate that cannot be run until
they do.

## Current state

- `repository/onze/modules/` does not exist. `repository/rakun/modules/` does, and is the shape to
  copy: each module has its own `botopink.json` with a `dependencies` map pointing at `../../`, plus
  `src/root.bp` (`repository/rakun/modules/rakun-web/botopink.json`).
- `libs/std/src/process.bp` today declares `exit`, `cwd`, `platform`, `arch`, `pid` — introspection
  only, no spawner (`process.bp:28-62`). Front 01 adds the spawn surface this front needs.
- `libs/std/src/path.bp` already has `join`, `normalize`, `dirname`, `basename`, `extname`,
  `relative`, `resolve`, `split`, `isAbsolute` (`path.bp:24-179`). This front adds nothing to it.
- `libs/std/src/fs.bp` already has `readText`, `writeText`, `exists`, `list`, `mkdir`, `rm`, `copy`
  and `stat` — and `stat` returns `FileStat(size, mtime, isDir)` with `mtime` in epoch milliseconds
  (`fs.bp:20-24`, `:99`). The dev watcher is built on that, not on a new `fs.watch`.
- `botopink` itself provides `build`, `check` and `test` with a `--target` flag
  (`modules/compiler-cli/AGENTS.md:273`). The CLI wraps them; it does not replace them.

## Mechanism

Four commands plus a diagnostic. Each is a pipeline over the same three stages — *resolve*, *generate*,
*drive* — and the only thing that differs between them is which drivers run and whether the result is
a running process or a directory.

**Resolve.** Read `onze.json` into front 49's `OnzeConfig`, read the `alias` map out of
`botopink.json`, and locate the project root by walking up from `process.cwd()` to the first directory
containing `botopink.json`. Everything downstream takes the resolved config as a value; no command
reads a file twice.

**Generate.** Walk `<root>/<config.appDir>`, classify each entry by basename against the routing-file
table (`NEXTJS-DOCS.md § 3`), and write the `pub mod` tree under `<root>/<config.outDir>/` — the second
half of front 22's convention, described in front 49's *Seam 1*. The walk is `fs.list` plus `fs.stat`,
recursive, skipping `_`-prefixed folders. Alias prefixes in the app's own imports are rewritten here,
by `resolveAlias` from front 49. The segment string each file yields is compared against that file's
`#[page]` / `#[layout]` / `#[getRoute]` argument, and a mismatch fails the build.

**Generate also stages the tree, and it has to.** `app/blog/[slug]/page.bp` cannot be reached by a
botopink `mod` path: a module path segment is an identifier, and `[slug]`, `(marketing)` and
`@analytics` are not. Next.js does not hit this because a JS import is a string. So the generate stage
copies `app/**` into `<outDir>/app/**`, rewriting every non-identifier directory name to a legal one
and recording the original on the `RouteEntry`:

| `app/` directory | staged directory | route effect |
|---|---|---|
| `[slug]` | `d_slug` | `/:slug` |
| `[...rest]` | `c_rest` | catch-all |
| `[[...rest]]` | `o_rest` | optional catch-all |
| `(marketing)` | `g_marketing` | no segment |
| `@analytics` | `s_analytics` | named slot (front 61) |
| `_components` | — | not staged, not routed |

The compiler only ever sees the staged tree, and the staged tree is what the generated `pub mod` lines name.
Two consequences the README states rather than leaving to be discovered: an error message points at a
staged path, so the CLI maps it back to the authored path before printing it; and two authored
directories that stage to the same name (`[slug]` and `d_slug` side by side) is a build error naming
both.

**Drive.** Hand the generated manifest and the resolved config to the fronts that do real work:
`botopink build --target erlang` for the server modules, front 68 for the client bundle, front 60 for
the prerender pass, front 71 for the release. The CLI runs external programs through std's `process`
spawner and owns none of those steps itself. A CLI that grows its own bundler is a CLI that has two
bundlers.

### What each command actually does, and which half it drives

| Command | Erlang half | JS half |
|---|---|---|
| `create` | writes `onze.json` and the `app/` scaffold | writes `botopink.json` with the alias map and the four dependencies |
| `dev` | stage + generate the module tree → check decorator arguments → `botopink build --target erlang` → boot the rakun server (front 04) on `config.port` | drive front 68 in incremental mode; push the rebuilt chunk to the open page |
| `build` | stage + generate + check → compile server modules to BEAM → run front 60's prerender pass → write `<outDir>/server/` and `<outDir>/prerender/` | drive front 68 → write `<outDir>/static/` with content-hashed names (front 03) |
| `start` | boot the release front 71 packaged, reading config at boot | serves `<outDir>/static/` as files; compiles nothing |
| `info` | prints the OTP version it found | prints botopink and library versions |

**`dev`'s reload loop is polling, deliberately.** There is no `fs.watch` in std and front 01 does not
charter one. The loop is: every 250 ms, `fs.stat` each `.bp` file under `appDir`, `components/` and
`lib/`, compare `mtime` against the previous pass, and on any change re-run *generate* and *drive*.
This is slower than inotify and it is portable across both backends with primitives that already
exist; the README says the interval is configurable and that the mechanism is polling, rather than
implying a watcher it does not have.

**`build` fails, it does not warn.** A route that front 60 cannot prerender in static-export mode, an
`env.read` of a non-`ONZE_PUBLIC_` name reached from a client module (front 49's rule, front 68's
enforcement), a segment holding both `page.bp` and `route.bp` — each fails the build naming the file.
There is no flag that downgrades any of them.

## Steps

### Step 1 — Module shape and entry point

```
modules/onze-cli/
├── botopink.json          # dependencies: onze (../../), std
├── src/
│   ├── root.bp            # pub mod resolve; scan; generate; create; dev; build; start; info; main
│   ├── resolve.bp         # project root + OnzeConfig + alias map
│   ├── scan.bp            # app/ walk → RouteEntry[]
│   ├── generate.bp        # RouteEntry[] → `pub mod` tree + decorator check
│   ├── create.bp
│   ├── dev.bp
│   ├── build.bp
│   ├── start.bp
│   ├── info.bp
│   └── main.bp            # argv dispatch
└── test/
    ├── scan_test.bp
    ├── generate_test.bp
    ├── create_test.bp
    └── resolve_test.bp
```

`fronts.md` gives this front `modules/onze-cli/src/**` and `modules/onze-cli/test/**`;
`modules/onze-cli/botopink.json` sits outside that glob and lands here too, under the same hand-off
rule track A uses for `libs/std/src/root.bp`. The coordinator is told rather than the file being taken
silently.

**Acceptance:**
- [ ] `botopink build` succeeds in `modules/onze-cli/`
- [ ] `onze` with no arguments prints the command list and exits non-zero
- [ ] An unknown command names itself in the error and exits non-zero

### Step 2 — `resolve`: project root, config, aliases

```bp
pub type Project(
    root: string,
    config: OnzeConfig,
    aliases: AliasMap,
)

#[@result]
pub fn resolveProject(startDir: string) -> @Result<Project, string>
```

Walk up from `startDir` to the first directory containing `botopink.json`. Missing `onze.json` is
not an error — `defaultConfig()` covers it; a malformed one is, and the error names the file.

**Acceptance:**
- [ ] `resolveProject` from a nested directory finds the root
- [ ] A directory with no `botopink.json` above it reds with a message naming `botopink.json`
- [ ] A project with no `onze.json` resolves to `defaultConfig()` with `name` taken from
      `botopink.json`
- [ ] An `alias` entry whose target escapes the root reds, naming the entry

### Step 3 — `scan`: the `app/` walk

```bp
pub type RouteEntry(
    pattern: string,      // "/blog/:slug"
    kind: string,         // "page" | "layout" | "loading" | "error" | "not-found" | "route" | "template" | "default"
    authoredPath: string, // "app/blog/[slug]/page.bp"  — what the developer sees in an error
    modulePath: string,   // "app.blog.d_slug.page"     — what the compiler sees after staging
    declared: string,     // the decorator argument the file actually carries
)

#[@result]
pub fn scanApp(root: string, appDir: string) -> @Result<RouteEntry[], string>
```

The classification rules, all from `NEXTJS-DOCS.md § 3`:

| Folder form | Effect on the pattern |
|---|---|
| `blog` | appends `/blog` |
| `[slug]` | appends `/:slug` |
| `[...rest]` | appends `/*rest` (catch-all — front 22 owns the matching) |
| `[[...rest]]` | appends an optional catch-all — front 22 owns "matches zero segments" |
| `(marketing)` | appends nothing; the group exists for layout sharing only |
| `@analytics` | a named slot — front 61 owns it; `scan` records it and does not flatten it |
| `_components` | skipped entirely, with everything under it |

**Acceptance:**
- [ ] `app/blog/[slug]/page.bp` scans to `pattern "/blog/:slug"`, `kind "page"`
- [ ] `app/(marketing)/about/page.bp` scans to `"/about"` — the group does not appear
- [ ] `app/_components/card.bp` produces no entry
- [ ] A segment holding both `page.bp` and `route.bp` reds, naming the segment (fold-in 7 is front
      22's to enforce at registration; `scan` catches it earlier, and both tests exist)
- [ ] Every convention file carries the decorator its kind requires, and the scan names the file when
      one is missing
- [ ] `authoredPath` round-trips: every error the CLI prints names the authored path, never the staged
      one, and `scan_test.bp` asserts the mapping for each row of the staging table
- [ ] `[slug]` and a literal `d_slug` sibling reds, naming both directories

### Step 4 — `generate`: the module tree, and the check

A route is registered from a **decorator argument** — `#[page("blog/[slug]")]`, `#[layout("blog")]`
(jhonstart front 30's UI decorators, copied into rakun's table by onze's boot), `#[getRoute("api/posts")]`
(rakun front 25's), all read with front 22's segment grammar — because `@Decl` carries no source location and a decorator cannot read the
file it annotates (`language-gaps.md`). That splits the file-system convention in two: the argument,
which the developer writes, and the module actually compiled, which the tree decides. This step owns
the second half and the check that stops the two drifting.

What it writes is `pub mod` lines, not registrations:

```bp
// GENERATED by onze build — do not edit.
pub mod app;
```

and, in `<outDir>/app/root.bp`, one `pub mod` per staged directory and per convention file, sorted.
Loading a module is what runs its decorators; there is no registry call for the CLI to emit.

```bp
pub fn generateTree(entries: RouteEntry[]) -> string
pub fn checkTree(files: AppFile[], declared: Array<#(string, string)>) -> TreeError[]
```

`checkTree` compares each file's directory-derived segment against its decorator argument and fails the
build naming the **authored** path, never the staged one — the developer has never seen `d_slug`.

**Acceptance:**
- [ ] The generated module begins with a `// GENERATED by onze build — do not edit.` banner
- [ ] `pub mod` lines are sorted, so two builds of an unchanged tree produce byte-identical output —
      which is what makes front 03's build id stable
- [ ] `app/blog/[slug]/page.bp` carrying `#[page("posts/[slug]")]` fails the build, naming
      `app/blog/[slug]/page.bp`, `blog/[slug]` and `posts/[slug]`
- [ ] A convention file with no decorator at all fails the build, naming the file and the decorator it
      needs
- [ ] The generated text compiles: `generate_test.bp` writes it to a temp directory and runs
      `botopink check` over it

### Step 5 — `create`, with flags and an interactive path

`create` has two entry paths and one set of defaults. The defaults are stated here, once, and both
paths use them.

| Flag | Default | Meaning |
|---|---|---|
| `--port <n>` | `3000` | written into `onze.json` |
| `--src-dir` | off | put `app/`, `components/`, `lib/` under `src/` and set `appDir` accordingly |
| `--import-alias <prefix>` | `@/` | the alias prefix written into `botopink.json` |
| `--emilia` / `--no-emilia` | on | scaffold with emilia tokens in the layout, or with a bare `<style>` |
| `--example <name>` | none | copy `examples/<name>` instead of the minimal scaffold |
| `--lang <tag>` | `en` | the `lang` attribute, written once on the document element in `app/layout.bp` |
| `--yes` | off | take every default and skip the prompts |

Without `--yes` and with a TTY, `create` prompts for project name, port, alias prefix and `--src-dir`,
in that order, each prompt showing its default. With `--yes`, or without a TTY (CI), it takes the
defaults and prints the resolved set before writing. A flag given explicitly is never prompted for.
`create` writes the `dependencies` map **and** runs `bpmp install`, so the scaffolded app passes
`botopink check` with no manual step on a clean machine. `onze add <lib>` (a wrapper over `bpmp add`)
is not chartered — `../../deferred.md`.

The scaffold it writes:

```
my-app/
├── botopink.json      # deps: onze, jhonstart, rakun, emilia, std; alias map
├── onze.json        # name, port, basePath, appDir, publicDir, outDir
├── app/
│   ├── layout.bp      # root layout: #[layout("")], emilia tokens, lang on <html>
│   └── page.bp        # one page
└── public/
```

**Acceptance:**
- [ ] `onze create my-app --yes` creates the tree above and exits zero
- [ ] `onze create my-app --yes --src-dir` writes `appDir: "src/app"` and puts `app/` under `src/`
- [ ] `onze create my-app --yes --import-alias "~/"` writes `~/components` into the alias map
- [ ] `create` into a non-empty directory refuses and names the directory; `--yes` does not override
      that, because the flag means "take the defaults", not "overwrite my files"
- [ ] The scaffolded app passes `botopink check` immediately after `create`, with no edits

### Step 6 — `dev`

```
onze dev            # config.port
onze dev -p 4000    # override, without touching onze.json
```

Resolve → generate → `botopink build --target erlang` → boot the rakun server → start the poll loop →
drive front 68 in incremental mode. Print the origin (`config.origin()`) once the listener is up, and
print each rebuild with the file that triggered it and the elapsed milliseconds.

**Acceptance:**
- [ ] `onze dev` serves `/` from the scaffolded app and prints `http://localhost:3000`
- [ ] Editing `app/page.bp` re-renders on the next request without restarting the node
- [ ] Adding `app/about/page.bp` makes `/about` resolve without a restart — the manifest is
      regenerated, not just recompiled
- [ ] A compile error prints the compiler's own message and leaves the previous build serving
- [ ] `-p` does not write to `onze.json`

### Step 7 — `build`

```
onze build
```

Resolve → generate → compile server modules for erlang → front 68 for the client bundle → front 60's
prerender pass → write `<outDir>/`:

```
.onze/
├── app_tree.bp        # generated `pub mod` tree (source, kept for debugging)
├── app/               # the staged app tree the compiler actually sees
├── server/            # compiled BEAM modules
├── static/            # content-hashed client chunks, CSS, fonts, images
├── prerender/         # front 60's prerendered HTML + payloads
└── build-id           # front 03's content hash over the inputs
```

**Acceptance:**
- [ ] `onze build` on the scaffolded app exits zero and produces the five entries above
- [ ] Two builds of an unchanged tree produce the same `build-id`
- [ ] A client module reading a non-`ONZE_PUBLIC_` variable fails the build, naming the variable and
      the module (the rule is front 49's, the enforcement front 68's, and the *failure* is this
      command's exit code)
- [ ] `build` does not start a server and does not open a port

### Step 8 — `start`

```
onze start
onze start -p 8080
```

Boot what front 71 packaged. `start` compiles nothing: if `<outDir>/` is missing or its `build-id` does
not match the current source, it says so and exits non-zero rather than silently rebuilding, because a
production start that quietly recompiles is a production start that can fail for a reason nobody
logged.

**Acceptance:**
- [ ] `onze build && onze start` serves the same routes `onze dev` served
- [ ] `onze start` with no `<outDir>/` exits non-zero naming the missing directory
- [ ] `PORT` in the environment overrides `config.port`, and `-p` overrides both — one documented
      precedence, asserted
- [ ] A `SIGTERM` drains in-flight renders before exiting (front 71 owns the drain; this command owns
      forwarding the signal)

### Step 9 — `info`

```
$ onze info
onze        0.0.1
botopink      1.0.9-beta
OTP/erts      28.0 / 16.0
jhonstart     0.0.1
rakun         0.0.1
emilia        0.0.1
project       blog  (/home/me/blog)
appDir        app
outDir        .onze
port          3000
basePath      (none)
alias         @/components → components, @/lib → lib
```

The diagnostic a bug report should carry. It reads versions from each dependency's `botopink.json` and
the OTP version from the runtime, and it prints the **resolved** config — the merge of defaults,
`onze.json` and the environment — not the file's contents.

**Acceptance:**
- [ ] `onze info` runs outside a project and prints the tool versions with `project (none)`
- [ ] Inside a project it prints the resolved config, and a value overridden by the environment is
      marked as such
- [ ] Every library listed is one this front actually resolved; a missing dependency prints
      `(not found)` rather than being omitted

## Examples

- [`examples/scaffold-example.bp`](./examples/scaffold-example.bp) — the `app/page.bp` and
  `app/layout.bp` that `onze create --yes` writes: the smallest thing that serves.
- [`examples/generated-routes-example.bp`](./examples/generated-routes-example.bp) — the generated
  `pub mod` tree, the staging table that produces it, and `checkTree` failing a file whose
  `#[page(…)]` argument no longer matches where the file lives.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| Declared parameter defaults are never applied | every `jhonstart` call in both examples spells `attrs:` | pass every argument explicitly | apply the declared default at the call site (ground truth §2.24) |
| No assignment to a `self` field | the dev watcher's previous-mtime table is rebuilt each pass instead of updated in place | rebuild the value | mutable record fields |
| `#[@future]` is required on any fn returning `@Future<T>` | `RootLayout` in `scaffold-example.bp` | write the marker | infer the effect from the return type |

None of the CLI's own mechanisms need a language change: a build-time walker, a text generator and a
process spawner are all ordinary botopink.

## Test plan

`modules/onze-cli/test/` on **commonJS only**, and the README says why rather than claiming dual
coverage: the CLI process is a developer-machine tool that runs before any BEAM node exists, so an
erlang row for it would test a program nobody runs. The *artifacts* it produces are tested on erlang —
by front 53's app, which is compiled and served by these commands.

- `resolve_test.bp` — root discovery from a nested directory, missing `botopink.json`, absent
  `onze.json`, escaping alias.
- `scan_test.bp` — every row of the folder-form table above, plus the `page.bp`+`route.bp` conflict and
  the `_`-prefixed skip. Fixtures are directory trees created under `.botopinkbuild/tmp/` with `fs.mkdir`
  and removed after, so the suite needs no checked-in fixture tree.
- `generate_test.bp` — deterministic ordering, the async/sync entry-point choice, and a round trip:
  generate, write, `botopink check`.
- `create_test.bp` — the flag table's defaults, `--src-dir`, `--import-alias`, and the refusal to write
  into a non-empty directory.

`dev`, `build` and `start` are covered end-to-end by the milestone's exit gate against front 53's app,
not by unit tests here — a unit test for "boots a BEAM node" is a slower, less honest version of the
gate that already exists.

## Definition of done

- [ ] `modules/onze-cli/` exists with the nine source modules and four test modules above
- [ ] `onze create`, `dev`, `build`, `start`, `info` all run against the scaffolded app
- [ ] The defaults table in step 5 is reproduced in `docs.md` and in `onze create --help`, generated
      from one source so the three cannot drift
- [ ] `modules/onze-cli/AGENTS.md` written, per the standing rule that a layout change updates the
      matching `AGENTS.md` in the same commit
- [ ] The front's tests are green on its assigned target — commonJS, for the reason stated above

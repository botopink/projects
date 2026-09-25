# Front 02 — packaging: the module and example structure of every library

**Track:** cross-cutting (A std · B rakun · C jhonstart · D emilia · E onze) — the packaging half of [`95-ecosystem-package-restructure/`](./95-ecosystem-package-restructure/README.md), beside this file; the std/testing/asserts half is [`../01-std/`](../01-std/)
**Priority:** high — every library front of this milestone writes into a directory this front creates, and every `-test` submodule and example project is invisible to the gate until the discovery change here lands
**Target:** none of its own — a structural front; each submodule and example declares the target its library is assigned (`overview.md` § Which target runs what)
**Wave:** 1, **alongside each library's first front** (rakun 04 · jhonstart 94 · emilia 54 · onze 49), after `01-std` (wave 0)
**Depends on:** `01-std` (the `onze` directory is free, `std/testing/asserts` and `std/testing/snapshots` exist, `@src()` is specified) · read-only: `00 · 10-cli-residuals` for the discovery carve-out, if needed
**Owns:** the rows of `02-packaging` in [`../fronts.md`](../fronts.md): every `repository/<lib>/botopink.json`, every `modules/<lib>/` and `modules/<lib>-test/` skeleton, every `examples/<project>/botopink.json`, `repository/botopink-lang/scripts/test-libs.sh`, `scripts/known-red-libs.txt`, `docs/botopink-json.md`, and — by the carve-out decision 75 names, landed — `modules/manifest/**` and the `manifest.scanRoots` call sites in `lib-test-runner/src/discovery.zig`, `compiler-cli/src/cli/{config,libs}.zig`, `language-server/src/project_graph.zig`, `bpmp/src/manifest.zig`
**Does not touch:** `libs/std/src/**` (01-std) · the source files inside any submodule (their fronts) · `repository/botopink-lang/modules/compiler-core/**` and `compiler-cli/**` (00) · the per-library cut beyond the three mandatory directories — that is each library's `modules.md`
**Reference:** `repository/botopink-lang/docs/botopink-json.md` (the manifest, as landed) · `repository/rakun/modules/README.md` and the thirteen `modules/rakun-*/botopink.json` at HEAD · `repository/botopink-lang/modules/compiler-cli/src/cli/{config,libs}.zig` (what a manifest means to the compiler) · `modules/lib-test-runner/src/discovery.zig` (what the gate can see) · `libs/std/AGENTS.md` § Tests · Spring Boot 4 starters (`/home/ericfillipe/develop/spring-boot-4/docs/02-desenvolvendo-com-spring-boot.md` § Starters) · Next.js project structure (`NEXTJS-DOCS.md` § 3) · Tailwind's package cut (`TAILWIND_CSS_DOCS.md` § 2: one core, three integration packages)

---

## Problem

Front 95 said every library gets `modules/` + `examples/` and stopped at a picture. Four things the
picture did not say, each measured against the tree and the compiler at HEAD:

1. **The compiler cannot see a submodule.** `from "rakun-web"` resolves by *name* across the root
   list — `BOTOPINK_LIB_ROOTS`, then for each ancestor `D` of cwd `D/repository/botopink-lang/libs`,
   `D/repository`, `D/libs`, then `.botopinkbuild/deps/` — and takes the first root with
   `rakun-web/botopink.json` as an **immediate child** (`compiler-cli/src/cli/libs.zig:loadOne`).
   `repository/rakun/modules/rakun-web/` is a child of no root. The `"path": "../../"` that every
   rakun submodule manifest already writes is parsed into `DepSpec.path` (`config.zig`) and **never
   read** by the loader.
2. **The gate cannot see a submodule or an example either.** `botopink-lib-test` discovers
   `<root>/*/botopink.json` (`lib-test-runner/src/discovery.zig:discover`), one level deep. Today
   `zig build test-libs` reports six libraries; the thirteen scaffolded rakun submodules and the seven
   existing example projects are not cells.
3. **A dependency's `entry` is never followed.** The loader reads only `src` and `files` of a
   dependency's manifest (`LibManifest`) and ships each listed file as `<dep>/<stem>`. Every
   `modules/rakun-*/botopink.json` declares `"entry": "root.bp"` and no `files`, so a consumer that
   did resolve one would get **zero modules**. `entry` is what the resolver follows for the package
   being *built*; `files` is what a *consumer* sees.
4. **`bpmp` rejects the object form.** `modules/bpmp/src/manifest.zig:85-96` returns
   `ManifestInvalid` unless `dependencies` is a string array; the compiler and the language server
   accept both. Every example manifest and every rakun submodule manifest is already in object form.

None of these is a library's problem to solve twice. All four are closed by step 1 (landed): a
member resolves by its manifest name (1), the runner and the loader expand `workspaces` (2), `files`
is what a consumer sees and a library member without it is `✗ ships nothing` (3), `bpmp` reads the
same model and the string array is a located error everywhere (4). This front states the shape once
and hands each library its `modules.md` to refine the cut.

## Current state

Measured by reading the trees on 2026-09-20.

| Repository | `botopink.json` shape | `modules/` | `examples/` | Tests |
|---|---|---|---|---|
| `rakun` | `name rakun`, `src src/`, `targets ["commonJS"]`, `files [http, runtime, decorators, bootstrap, rakun.d]` | **13** submodules, each `botopink.json` (`name rakun-<x>`, `entry root.bp`, `targets [commonJS, erlang]`, `dependencies {rakun: {path: ../../}}`, **no `files`**) + `src/root.bp` (a comment) + empty `test/` | `examples/rakun/` (`rakun-app`, git dep on `rakun` branch `feat`) | `test/{di,overlapping_routes,router,scopes,server}_test.bp` |
| `jhonstart` | `files [element, hooks, html, router.d, server.d]`, `targets [commonJS, erlang]` | none | `examples/{jhonstart-app,jhonstart-counter,jhonstart-html,jhonstart-todo}/` — three with a manifest (git dep, branch `feat`), `jhonstart-app` without one | `test/html_test.bp` |
| `emilia` | `files [root, tokens, emilia]`, `targets [commonJS, erlang]` | none | `examples/emilia-card/` (git deps on `jhonstart` + `emilia`) | inline `test` blocks in `src/*.bp` |
| `onze` (mocking) | `files [onze.bp]`, `targets [commonJS, erlang]` | none | `examples/onze/` (`onze-demo`) + a loose `examples/mock_synthesis.bp` | `test/onze_test.bp` |
| `erika` | `files [root, erika]`, `target commonJS` | none | `examples/erika-linq/` | inline |
| `libs/std` | `entry root.bp`, `files [primitives, builtins.d, builtins_fns.d]` | — (std is not a package tree) | — | inline in `src/*.bp`; `test/` compiles against the ambient global env (`libs/std/AGENTS.md`) |

Every `examples/*/out/` directory is committed build output (`out/jhonstart/element.js`, …). It is
what the old `git` dependency form produced; the path form below makes `out/` reproducible and it
stops being committed.

## Mechanism

The workspace rule of decisions [75](../decisions-taken.md#75-a-workspaces-manifest-npm-style-declares-a-librarys-members)
and [76](../decisions-taken.md#76-dependencies-is-the-object-form-only), as landed on the compiler's
`feat` (step 1). `repository/botopink-lang/docs/botopink-json.md` is the authority for every field
and every message; this section states what the rule means for a library.

### 1. One reader, two kinds of manifest

`modules/manifest/src/root.zig` is the one model of `botopink.json`, imported by the compiler
(`botopink build/check/run/test`, `compiler-cli/src/cli/{config,libs}.zig`), the language server
(`language-server/src/project_graph.zig`), the lib-test runner (`lib-test-runner/src/discovery.zig`)
and `bpmp` (`bpmp/src/manifest.zig`). The fields, the shapes and the refusals are therefore the
same in every tool, and a refusal is a **located error** — message, file, line and column of the
offending entry, in the compiler's diagnostic shape. Nothing is parsed and ignored; no field
switches a refusal off (decision 67).

A manifest is a **package** or a **workspace**:

| | Package | Workspace |
|---|---|---|
| Recognised by | no `workspaces` | `"workspaces": [...]` |
| Carries | `name`, `version`, `description`, `src`, `entry`, `target`, `targets`, `files`, `dependencies`, `botopink`, `requires` | `name`, `version`, `description`, `targets`, `workspaces` — `src`, `files`, `entry`, `dependencies` are **refused** |
| Is | what `from "<name>"` resolves to; a runner row per target | a list of members; never imported, never a runner row; `botopink build/…` inside it is refused |
| Members | — | each glob expansion holding a `botopink.json`; a member is a package whose `name` is its import name — it is reached by that name, never by its directory |

`workspaces` takes two forms: `"<dir>/*"` — every child of `<dir>` holding a `botopink.json` (a
child without one is not a member) — and a literal `"<dir>"`, which must hold one. Paths are inside
the workspace (no `..`, no absolute path, no other `*`); workspaces do not nest. A workspace's
`targets` is the default every member inherits when it declares none, and a member may only
**restrict** it (widening is a located error).

### 2. The shape — one workspace per library

```
repository/<lib>/
├── botopink.json                  WORKSPACE: name, version, targets, "workspaces": ["modules/*", "examples/*"]
├── AGENTS.md
├── modules/
│   ├── <lib>/                     CORE — what `from "<lib>"` gives a consumer
│   │   ├── botopink.json          name <lib>, entry root.bp, files [...], targets ⊆ the workspace's
│   │   ├── src/root.bp            `pub mod` tree of the core
│   │   ├── src/*.bp
│   │   ├── test/*_test.bp         flat suite; may import the package (`compiler-cli/AGENTS.md`)
│   │   └── test/__snapshots__/    contract 7 — beside the tests that write them
│   ├── <lib>-test/                ALWAYS PRESENT — assert<Subject>(loc, …) helpers, fixtures, builders
│   │   ├── botopink.json          name <lib>-test, dependencies { "<lib>": { "workspace": true } }
│   │   ├── src/root.bp
│   │   └── test/                  the helpers' own tests + __snapshots__/
│   └── <lib>-<domain>/            WHERE WARRANTED — cut at a consumption boundary, not by file count
│       ├── botopink.json          name <lib>-<domain>, files [...], dependencies { "<lib>": { "workspace": true }, … }
│       ├── src/root.bp
│       └── test/ (+ __snapshots__/)
└── examples/
    └── <project>/                 a MEMBER and a RUNNABLE PROJECT, not a snippet
        ├── botopink.json          name <project>, entry main.bp, target, dependencies { "<lib>": { "workspace": true }, "<other-lib>": { "path": … } }
        ├── src/main.bp            (or app/ for an onze app)
        ├── test/*_test.bp         + __snapshots__/ — an example is tested like a module
        └── README.md              what it demonstrates and the upstream section it mirrors
```

Three mandatory directories per library — `modules/<lib>/`, `modules/<lib>-test/`, `examples/` —
and the rest is the library's call. The three rules of front 95 still govern the cut:

- **Every package has a `<lib>-test` member.** Spring ships `spring-boot-starter-test` beside
  every starter; Next.js ships nothing and every project reinvents its harness. The first is the
  model. `<lib>-test` depends on its core and on std, and a consumer that wants to test *against* a
  library adds `<lib>-test` — never `<lib>`'s own `test/`.
- **A submodule is cut at a consumption boundary.** Spring's starters (`-web`, `-data-jpa`,
  `-security`, `-actuator`, `-cache`, `-validation`, `-amqp`/`-kafka`, `-quartz`, `-mail`,
  `-websocket`, `-hateoas`) each name a thing a consumer takes without the rest; Tailwind is the
  counter-reference (one core, three integration packages). `emilia` follows Tailwind, `rakun`
  follows Spring, `jhonstart` and `onze` sit between (Next.js exposes `next/link`, `next/image`,
  `next/navigation` as entry points of **one** package; a submodule only where the target profile
  differs).
- **The core owns `from "<lib>"`.** The umbrella is a workspace: nothing is importable from it, and
  a dependency that names it — by `git` under a root or by `path` — is refused with the member
  list. `from "<lib>"` resolves to the member named `<lib>`, `from "<lib>-web"` to the member named
  `<lib>-web`. A consumer never reaches into another package's `src/`.

### 3. Manifests — the fields each kind carries

| Field | Workspace `repository/<lib>/` | Module `modules/<lib>[-x]/` | Example `examples/<p>/` | Read by |
|---|---|---|---|---|
| `name` | `<lib>` — what a lookup answers with when something imports the umbrella by mistake | `<lib>` or `<lib>-<x>` — this **is** the import name | `<p>` | every reader |
| `version` | the library's | the same, every member | `0.0.1` | compiler, bpmp |
| `description` | one line | one line, ending in the target profile | one line, naming the upstream section | — |
| `workspaces` | `["modules/*", "examples/*"]` | refused | refused | every reader |
| `src` | **refused** | `src/` (default) | `src/` or `app/` | compiler, LSP, loader |
| `entry` | **refused** | `root.bp` — followed when this package is **built/tested** | `main.bp` | resolver |
| `files` | **refused** | every module a **consumer** may import, `root.bp` first — the only thing the loader ships; **mandatory** for a library member (§ 6) | omitted — an application ships nothing by design | `libs.zig`, `project_graph.zig`, `bpmp pack` |
| `target` | — | the member's default for `botopink build/run/test` | the example's | `botopink build/run/test` |
| `targets` | the default the members inherit | absent (inherits) or a **restriction** (`onze-cli`: `["erlang"]`) | absent or a restriction | `botopink-lib-test` |
| `dependencies` | **refused** | object form; siblings as `{ "workspace": true }`; std never listed | object form; the own library's members as `{ "workspace": true }`, another library's core by `path` or `git` | compiler, LSP, runner, bpmp |
| `botopink`, `requires` | omitted | omitted until a release | omitted | bpmp only |

### 4. `dependencies` — the object form, and the sibling form

```json
"dependencies": {
  "<name>": { "path": "<relative directory>" },
  "<name>": { "git": "<url>", "branch": "<b>" | "tag": "<t>" | "rev": "<sha>" },
  "<name>": { "workspace": true }
}
```

The key is the import name; each entry declares **exactly one source** (decision 76 — the string
array is a located error in every tool, `bpmp` included):

| Source | Resolves to | Rule |
|---|---|---|
| `{ "path": "…" }` | `<project>/<path>`, which must hold a `botopink.json` whose `name` is the key | Honoured directly by the compiler and the LSP — no root is consulted. For a library **outside** the workspace (`emilia-card` → `jhonstart`). A `path` to a sibling member, or to the workspace itself, is refused. |
| `{ "git": "…", pin }` | the library named `<name>` under the **library roots**, then the `bpmp install` store `.botopinkbuild/deps/<name>/` | The pin is **exactly one** of `branch`, `tag`, `rev` — not a literal `ref` (bpmp's clone needs the pin's kind; a second spelling would be a knob). A pin without `git` is refused. The compiler resolves by name and never fetches. |
| `{ "workspace": true }` | the **sibling member** of the enclosing workspace named `<name>` | The only way a member depends on a sibling (decision 75). Outside a workspace, or naming no sibling, refused. `false` is refused. |

**Library roots**, in order: `BOTOPINK_LIB_ROOTS`; then for each ancestor `D` of the project,
nearest first: `D` itself when `D/botopink.json` is a workspace (its members), `D/repository/botopink-lang/libs`
(the bundled `std`, `routing`, `actions` and `validation`), `D/repository`, `D/libs`; then `<project>/.botopinkbuild/deps`. A root
contributes every immediate child directory holding a `botopink.json` (a package named by the
directory) **and every member of a workspace found there, named by its manifest** — so
`repository/rakun` under the `D/repository` root contributes `rakun`, `rakun-web`, … and never
`rakun` the umbrella. Two members with one `name` across roots is a located error on both (the
first-root-wins rule decision 75 retires; two plain packages with one name keep it).

### 5. `<lib>-test` — what it exposes, and on what it stands

```bp
//// <lib>-test — test helpers for <lib>.
////
//// Depends on: std (testing.asserts, testing.snapshots), <lib> (core, { "workspace": true })
//// Target: inherited from the workspace

import {testing: {asserts, snapshots}} from "std";
import { Token, Theme, defaultTheme } from "emilia";

// One assert<Subject>(loc, …) per thing the library produces. The location is
// @src() at the call site (contract 7); the helper never computes a path itself.
pub fn assertCss(loc: SourceLocation, tokens: Token[]) -> @Result<void, string> {
    val css = emiliaToCss(tokens, defaultTheme());
    return snapshots.assertSnapshot(loc, css);
}

// Builders and fixtures — where most of the value is.
pub fn sampleTheme() -> Theme { … }

// No re-implementation of std: a `-test` that defines its own `equal` is a bug.
```

Rules, each checkable:

- **`assert<Subject>(loc, …) -> @Result<void, string>`** is the only helper shape. `loc` is the
  first parameter, always a `SourceLocation` from `@src()`, handed to `snapshots` unchanged. A
  helper that takes a path string is wrong.
- **`__snapshots__/` lives beside the tests that write it** — `modules/<x>/test/__snapshots__/`
  for a module, `examples/<p>/test/__snapshots__/` for an example, `src/__snapshots__/` for a
  library whose tests are inline (`emilia`, `std`). `snapshots.path(loc)` derives it from
  `loc.file`; nothing configures it.
- **A `-test` member re-exports nothing from std.** A consumer writes `import {testing.asserts} from "std"`
  beside `import { assertCss } from "emilia-test"`.
- **Mocking is `std/testing/mocks`** (decision 71); a `-test` member keeps only the injection pairing.
- **The per-library `test-snap.md` is the map** of every `assert<Subject>`, every test that calls
  it and the `.snap` path it produces; `test-snap-examples.md` does the same for `examples/**`.

### 6. Examples are members, tested like modules

An example is `repository/<lib>/examples/<project>/`, matched by the `examples/*` glob, and it is a
row of the gate: it compiles on its declared target and its `test/` runs. An example member has
`entry: main.bp` (or `src/main.bp` present), which makes it an **application**: it ships nothing,
and needs no `files`. Three rules:

- **An example depends on its own library's members with `{ "workspace": true }` and on other
  libraries' cores by `path`** (`emilia-card` → `{ "emilia": { "workspace": true }, "jhonstart": { "path": "../../../jhonstart/modules/jhonstart" } }`);
  the direction rule in § 9 applies to the example as a consumer. The `git` form is for a consumer
  **outside** the ecosystem, after a release — it is why every example commits its `out/` today.
- **An example carries a `README.md`** naming the upstream section it mirrors (`overview.md` §
  Mapping the three sources) and the front whose feature it exercises.
- **`examples/<lib>-<thing>/`** is the name (`jhonstart-counter`, `emilia-card`, `rakun-app`,
  `onze-blog`) — the library first, so the flat listing across repositories reads.

The loose `examples/mock_synthesis.bp` in the old `onze` and the manifest-less
`jhonstart/examples/jhonstart-app/` are not members: the glob skips a child without a manifest,
silently by design — a directory that wants to be tested declares itself.

### 7. Discovery — what `zig build test-libs` and `botopink test` see

One function, `manifest.scanRoots`, in the runner, the loader, the LSP and `bpmp`: read each root,
take every immediate child holding a `botopink.json`; when that manifest is a workspace, expand its
`workspaces` and treat each member as a lib-root entry named by its manifest. No recursion, no
environment variable beyond the pre-existing `BOTOPINK_LIB_ROOTS`, no special case for the meta
repository (it has no manifest; each `repository/<lib>` is a workspace and the gate iterates them).

- The runner prints **one row per member**, examples included, on every target the member's
  (inherited or restricted) `targets` allows; the umbrella has no row. `✗` is the only status that
  fails the run; `scripts/known-red-libs.txt` names a red cell with the front that owns it.
- A **library member** (`root.bp`-rooted) that lists no `files` **ships nothing**: `botopink test`
  inside it fails, and the runner marks every cell `✗ ships nothing` — the thirteen scaffolded rakun
  manifests read exactly that until migrated (§ 11).
- `botopink test` inside a member needs nothing new: cwd is the member, `src/` and `test/` are its
  own, `{ "workspace": true }` resolves through the enclosing workspace. `botopink test` in the
  workspace directory is refused with the member list.

**What was measured before the decision.** Two routes were costed when `loadOne` still resolved
only immediate children of a root and `discovery.zig` walked one level: route A — `scripts/test-libs.sh`
exporting `BOTOPINK_LIB_ROOTS` with every `repository/*/modules` and `repository/*/examples`
(no Zig, but name uniqueness by first-root-wins and an umbrella that answered to the core's name);
route B — a nested walk in `discovery.zig` alone (the compiler still blind to `from "rakun-web"`).
Decision 75 superseded both with the shared model: the members are named by their manifests, the
umbrella is never a lookup answer, and a duplicate name is a refusal instead of a silent first win.

### 8. The located errors

Every refusal is one of the message shapes `docs/botopink-json.md` tabulates, located on the
manifest entry that is wrong (or, at resolution time, on the project's `dependencies` entry).
Grouped as the document groups them:

**The `dependencies` shape** — `"dependencies" must be an object, not an array — write { "<name>": { … } }; for example ["erika"] becomes { "erika": { "path": "../erika" } }` · `"dependencies" must be an object` · `dependency "x" must be an object` · `dependency "x" declares no source — one of "git", "path" or "workspace": true is required` · `dependency "x" declares more than one source` · `dependency "x" declares more than one pin — exactly one of "branch", "tag" or "rev"` · `dependency "x" pins a ref without a "git" source` · `dependency "x": "workspace" can only be true` · `dependency "x": "git" must be a string` (and `path`, `branch`, `tag`, `rev`).

**Resolution** — `"x": { "workspace": true } but <project>/botopink.json is not a member of any workspace` · `"x": { "workspace": true } names no member of <ws>/botopink.json (members: a, b, c)` · `"x": path "../x" holds no botopink.json (looked at <abs>)` · `"x": path "../y" holds a package named "y" — the dependency key is the import name and must match` · `"x": path "../x" points at the sibling member "x" — use { "workspace": true }` · `"x": path "../ws" is a workspace, not a package — depend on one of its members: a, b, c` · `"x" is a workspace, not a package — import one of its members: a, b, c` · `dependency 'x' was not found under any library root` · `dependency 'x' lists "gone.bp" in files, but <path> does not exist`.

**The workspace** — `a workspace manifest cannot carry "files"` (and `src`, `entry`, `dependencies`) · `workspaces entry "modules/**" is not a supported form — use "<dir>/*" … or a literal "<dir>"` · `workspaces entry "modules/*": <ws>/modules is not a directory that can be read` · `workspaces entry "modules/ghost": …/botopink.json does not exist` · `"inner" is a member of <ws>/botopink.json and cannot itself be a workspace — workspaces do not nest` · `member name "dup" is declared twice in <ws>/botopink.json: <a> and <b>` · `"erlang" is not one of the workspace's targets ["commonJS"] — a member may only restrict the workspace's targets` · `"web" cannot depend on itself` · `"core": path "../core" points at the sibling member "core" — use { "workspace": true }` · `"umbrella": path "../../" points at the workspace itself — … depend on one of its members with { "workspace": true }` · `<ws>/botopink.json is a workspace, not a package — run this command inside one of its members: a, b, c` · `"x" is declared by two libraries: <dirA> and <dirB> — a name resolves to one library; rename one of them` · `ships nothing: manifest has no "files" — a workspace member that is a library lists every module a consumer may import`.

**Every manifest** — `botopink.json is not valid JSON` · `botopink.json must be a JSON object` · `botopink.json has no "name"` · `"name" must be a string` · `"files" must be an array of strings` (`— entry 2 is not a string`).

The `– / ✗ ships nothing` row and the duplicate-name refusal are the two the gate itself produces;
the rest reach a developer from the compiler and, as editor diagnostics on the manifest, from the
LSP.

### 9. Dependency direction

The rule holds for libraries and members alike. An edge is a
`dependencies` entry; the graph is acyclic and the gate checks it by building.

```
std  ◄──  <lib>  ◄──  <lib>-<domain>  ◄──  <lib>-test  ◄──  examples/<project>
                                                            (and any -test of a library above it)

libraries:   emilia ──► jhonstart (Element)          rakun ──► (nothing)
             onze ──► rakun, jhonstart, emilia        jhonstart ──► (nothing)
```

| Rule | Why |
|---|---|
| A core depends on std and on other libraries' **cores** only — never on a member of another library, never on a `-test` | The core is what `from "<lib>"` means; a core that needs `rakun-web` has the wrong cut |
| A domain member depends on its core, on std, and on other domain members of the **same** workspace (`rakun-actuator` → `rakun-actuator-api`, contract 5c), all as `{ "workspace": true }` — never on another library's member | Cross-library edges are between cores, so a library is one node in the graph above |
| `<lib>-test` depends on its core, on std, and on the domain members it asserts over; **a core never depends on `-test`** | An import of `<lib>-test` from a core's `src/` is a build error by construction — the core's manifest lists no such dependency |
| A `-test` may depend on a lower library's `-test` (`onze-test` → `rakun-test`, `jhonstart-test`) by `path` | `onze` tests reach the server through `rakun-test`'s request double (front 19); [`../deferred.md`](../deferred.md) records why there is no shared double |
| An example may depend on **several** libraries — its own by `{ "workspace": true }`, others' cores or `-test`s by `path` | `emilia-card` → `jhonstart` + `emilia` today; `onze-blog` → all four |
| A bundled package — `std`, `routing`, `actions`, `validation` — is never listed | It is embedded in the compiler (`routing`: decision 115, `01-std/04-routing-lib`; `actions` and `validation`: decision 116, `01-std/05-actions-lib`, `01-std/06-validation-lib`); listing it is a resolver error |
| No edge from any library into `repository/botopink-lang/**` | The compiler knows none of this (`overview.md` § Rules) |

Direction between libraries: `emilia` depends on `jhonstart` for `Element`
(front 48), `onze` depends on the other three, `rakun` and `jhonstart` depend on nothing but the bundled `std`, `routing`, `actions` and `validation` — each is neutral like std, so importing it is not an edge between them (decisions 115, 116).

### 10. The `onze` name takeover

The order is fixed by [`../fronts.md`](../fronts.md) § Conflict rules: `01-std` removes
`repository/onze/` (the mocking library — its predicates are in `std/testing/asserts`, its mocks in
`std/testing/mocks`, decision 71; the repository is tagged and archived, decision 79); then this front
creates `repository/onze/` as the orchestrator workspace with the skeleton members (`onze`,
`onze-test`, `onze-cli`, `onze-bundler`, `onze-assets`, `onze-release` — `06-onze/modules.md`
decides whether release is its own); then front 49 fills `modules/onze/src/`. The two never hold
the directory at once, and `grep -rl onze13 repository` is empty from the first commit of this
front — as is every `**Owns:**` line and every manifest `name` under `specs/1.0.10-beta/`; front 95
(beside this file) and `../unification.md` still carry the old name.

### 11. The migration each library track does

The same four moves per library, in one worktree per repository, landing as a merge into that
repository's `feat`:

1. **Umbrella → workspace.** `repository/<lib>/botopink.json` loses `src`, `entry`, `files`,
   `dependencies` (each is now a located error there) and gains `"workspaces": ["modules/*", "examples/*"]`;
   its `targets` becomes the members' default.
2. **Core → `modules/<lib>/`.** The existing `src/*.bp` and `test/*.bp` move under
   `modules/<lib>/`, whose manifest carries `name <lib>`, `entry root.bp` and `files` listing every
   consumer-visible module (`root.bp` first). `from "<lib>"` now resolves to this member.
3. **Submodules → `{ "workspace": true }`.** Every `modules/<lib>-*/botopink.json` replaces
   `{ "<lib>": { "path": "../../" } }` (now the *points at the workspace itself* refusal) with
   `{ "<lib>": { "workspace": true } }` and gains `files` — until it does, its rows read
   `✗ ships nothing`.
4. **Examples → members.** Every `examples/<p>/` gets a manifest with `entry main.bp`, the own
   library as `{ "workspace": true }`, other libraries by `path`; `out/` leaves git.

rakun goes first (`.tasks/rakun-workspace`: thirteen scaffolded members plus the core to create);
jhonstart, emilia and onze follow with their first front. The `-test` members are created empty
(`root.bp` with an empty `pub` surface and one inline `test`) and filled once `01-std` steps 2–3
give them `asserts` and `snapshots` to stand on.

## Per-library proposal — the starting point

**To be refined by each library's `modules.md`** (`../03-rakun/modules.md`, `../04-jhonstart/modules.md`,
`../05-emilia/modules.md`, `../06-onze/modules.md`). This table is what front 95 and the
ownership rows of [`../fronts.md`](../fronts.md) imply; the library agent owns the final cut and the front → directory table that
[`../fronts.md`](../fronts.md) copies.

| Library | Core | `-test` | Domain submodules (proposed) | Cut follows |
|---|---|---|---|---|
| **rakun** — the 13 scaffolded dirs are being migrated to the workspace rule in `.tasks/rakun-workspace` (§ 11) | `rakun` — DI, `#[bean]`/`#[configuration]`/`#[value]`, `App`, bootstrap, config/profiles (05), context (06), the file router and SSR spine (22–25, 60–66, 72, 74) | `rakun-test` — `FakeRequest`, `MockMvc`, context reset, broker double (front 19) | `rakun-web` (07, 20, 65, 82) · `rakun-data` (08, 09, 77, 78, 83) · `rakun-security` (10, 79) · `rakun-actuator` + `rakun-actuator-api` (11, 76, 87) · `rakun-cache` (12) · `rakun-client` (13) · `rakun-messaging` (15, 86, 89–91) · `rakun-scheduling` (16, 84) · `rakun-logging` (17) · `rakun-session` (18) · `rakun-hateoas` (21) · and the `../fronts.md` rows that name more: `rakun-i18n` (64), `rakun-starters` (73), `rakun-metrics`/`observability` (75), `rakun-devtools` (80), `rakun-release` (81), `rakun-tx` (83), `rakun-mail` (85), `rakun-cli` (88), `rakun-stream` (89), `rakun-rsocket` (92), `rakun-ws` (93) | Spring starters, one per `spring-boot-starter-*` a consumer takes alone |
| **jhonstart** | `jhonstart` — `Element`, hooks, rendering, router (26), server components (28), streaming (30), boundaries (31), metadata (32), elements (94) | `jhonstart-test` — render helpers, element comparison, `assertElement(loc, …)`, `assertHtml(loc, …)` | `jhonstart-html` (the `html` DSL — 95's proposal, the byte-equality tests live there) · `jhonstart-forms` (67 — js-target, so a different target profile) · `jhonstart-router`? — 95 said no (one file, coupled to the core); `04-jhonstart/modules.md` decides | Next.js entry points: one package, a submodule only where the target profile differs (`'use client'` code is commonJS-only) |
| **emilia** | `emilia` — tokens, every `<section>TokenToCss`, theme (54), preflight (55), cascade/output (56), escape hatches (57), containers (58), compose (59), attributes (48) | `emilia-test` — `assertCss(loc, tokens)`, `assertSheet(loc, …)`, `sampleTheme()`, the contract-4 literal fixture | `emilia-theme`? · `emilia-modifiers`? — 95 said **two submodules only**; the theme and the modifiers are layers of one pipeline and no consumer takes one without the others. Listed because the plan named them; `05-emilia/modules.md` confirms or refuses | Tailwind: one core, integrations apart. The integration here is front 48's html hook, which is part of the core because it is the only consumer |
| **onze** | `onze` — orchestrator types, config, integration layer (49), the styling seam (69) | `onze-test` — app scaffolding helpers, route-table assertions, `assertRouteTable(loc, …)`, `assertPayload(loc, …)` | `onze-cli` (50) · `onze-bundler` (68) · `onze-assets` (51, 52, 69, 70) · `onze-release` (71) · `onze-pipeline`? — the plan named it; if it is 69's styling seam it belongs in `onze-assets` as the `../fronts.md` rows already say | Next.js `next` + `create-next-app`: the CLI and the bundler are what a deploy takes without the other |
| **std** | — (not a package tree; `libs/std/src/*.bp` with `pub mod` in `root.bp`) | — (`asserts` and `snapshots` **are** the test surface every `-test` stands on) | — | `01-std/` |

**rakun already has thirteen scaffolded submodules** under `repository/rakun/modules/` —
`rakun-actuator`, `rakun-cache`, `rakun-client`, `rakun-data`, `rakun-hateoas`, `rakun-logging`,
`rakun-messaging`, `rakun-scheduling`, `rakun-security`, `rakun-session`, `rakun-test`,
`rakun-validation`, `rakun-web` — each with `botopink.json` (`entry root.bp`, `targets [commonJS,
erlang]`, `dependencies {rakun: {path: ../../}}`, no `files`), a `src/root.bp` holding a comment, and
an empty `test/`. `../03-rakun/modules.md` must reconcile them with the `../fronts.md` ownership rows, which
name eleven more (`rakun-i18n`, `rakun-starters`, `rakun-metrics`, `rakun-observability`,
`rakun-devtools`, `rakun-release`, `rakun-tx`, `rakun-mail`, `rakun-cli`, `rakun-stream`,
`rakun-rsocket`, `rakun-ws`, plus `rakun-actuator-api` from contract 5c) and one inconsistency
(`75` owns `modules/rakun-metrics/**` and tests `modules/rakun-observability/test/**`). The core
`modules/rakun/` does not exist and `rakun-core` is what `modules/README.md` calls `../src/`. Under the
landed model every one of the thirteen reads `✗ ships nothing` and its `{ "path": "../../" }` is the
*points at the workspace itself* refusal — `.tasks/rakun-workspace` is the migration (step 2).
`rakun-validation` is the one of the thirteen that leaves rakun rather than migrating: it is the
bundled library `validation` (decision 116, `01-std/06-validation-lib`), and rakun front 14 Step 7
deletes the member.

## Module ↔ Spring starter

The consumption-boundary argument for the rakun cut; `repository/rakun/modules/README.md` carries the
same table at HEAD.

| Spring Boot 4 | rakun module | Fronts |
|---|---|---|
| `spring-boot-starter` — auto-configuration, logging, YAML; `SpringApplication` | `rakun` (core) | 04 · 05 · 06 · 72 |
| Externalized config, profiles | `rakun` (core) | 05 |
| `-webmvc` / `-webflux` — MVC, filters, CORS, WebSocket, static resources | `rakun-web` | 07 · 20 · 65 · 82 |
| `-data-jpa` / `-data-jdbc` / `-data-mongodb` / `-data-redis` — SQL, NoSQL, migrations, entities | `rakun-data` | 08 · 09 · 77 · 78 |
| `-security`, `-security-oauth2-client`, `-security-saml2` | `rakun-security` | 10 · 79 |
| `-actuator` | `rakun-actuator` (+ `-api`) | 11 · 76 · 87 |
| `-cache` | `rakun-cache` | 12 |
| `RestClient` / `WebClient` | `rakun-client` | 13 |
| `-validation` | the bundled library `validation` (`01-std/06-validation-lib`, decision 116) — no rakun member; rakun sets its message source | 14 |
| `-amqp` / `-kafka` / `-activemq` / `-artemis` / `-pulsar` / `-rsocket` / `-integration` | `rakun-messaging` (+ `rakun-stream`, `rakun-rsocket`) | 15 · 86 · 89 · 90 · 91 · 92 |
| `-quartz`, `@Scheduled` | `rakun-scheduling` | 16 · 84 |
| logging | `rakun-logging` | 17 |
| `-session-data-redis` / `-session-jdbc` | `rakun-session` | 18 |
| `-test` | `rakun-test` | 19 |
| `-hateoas` | `rakun-hateoas` | 21 |
| `-mail` | `rakun-mail` | 85 |
| `-webservices` | `rakun-ws` | 93 |
| Erlang/BEAM runtime (no Spring analogue — the JVM) | `rakun` (core), `src/sidecars/rakun_runtime.erl` | 04 |

## Which library owns each Next.js surface, and convention over configuration

The cross-library ownership argument: a feature's package is decided by which
half of the boundary runs it (`overview.md` § Which target runs what), not by which upstream package
exported it.

| Next.js | botopink | Library · front |
|---|---|---|
| React | `Element`, hooks, `html` DSL | jhonstart · 94 (+ the existing core) |
| React Server Components | `#[@future] fn → @Future<Element>` | jhonstart · 28 |
| `'use client'` | the boundary, hydrate point | jhonstart · 29; the bundle, onze · 68 |
| `next/link` | `Link` | jhonstart · 27 |
| `next/navigation` (`useRouter`) | `useRouter` | jhonstart · 26 |
| `next/image` | `Image` | onze · 51 (`onze-assets`) |
| `next/font` | font loading | onze · 52 (`onze-assets`) |
| App Router (`app/`) | `app/` convention + file router | rakun · 22 |
| `layout` / `page` / `template` / `default` | `layout.bp` / `page.bp` / … | rakun · 22, 61 |
| `loading` | `loading.bp` | jhonstart · 30 |
| `error` / `not-found` / `global-error` | `error.bp` / `not-found.bp` / `global-error.bp` | jhonstart · 31 |
| `route.ts` | `route.bp` | rakun · 25 |
| Server Actions | `'use server'` + form dispatch | rakun · 24; the client half jhonstart · 67 |
| Middleware | `middleware.bp` | rakun · 07 |
| `fetch` + cache, `'use cache'`, `revalidatePath/Tag` | the cache store | rakun · 12 |
| `generateMetadata` | `generateMetadata` | jhonstart · 32 |
| `ImageResponse` | OG image generation | onze · 70 |
| `cookies()` / `headers()` / `after()` / `draftMode()` | request context | rakun · 62 |
| `redirect` / `notFound` | navigation signals | rakun · 63 |
| `generateStaticParams`, `revalidate` | static generation | rakun · 60 |
| Tailwind CSS | `emilia` tokens | emilia · 33–59 |
| CSS Modules | `emilia` scoped classes (contract 4) | emilia · 48 |
| `create-next-app`, `next dev/build/start` | `onze create/dev/build/start` | onze · 50 |
| `next.config.js` | `modules/onze/src/config.bp` | onze · 49 |
| self-hosting, `output: standalone` | OTP release | onze · 71, rakun · 81 |

**Convention over configuration:** file-system routing,
decorator-based metadata and emilia tokens are conventions, not configuration — and so is this
front's layout. `modules/<lib>/` is the core because of its **name**, `<lib>-test` is the test
submodule because of its **suffix**, `examples/<p>/test/__snapshots__/` is where a snapshot goes
because of **where the test is**. There is no manifest field that relocates any of them, and none is
added.

## Steps

### Step 1 — The manifest model: workspaces, members, the object form — LANDED

Landed on the compiler's `feat` (2026-09-20) as the `00 · 10-cli-residuals` carve-out decision 75
names: `modules/manifest/` (workspace vs package, `workspaces` globs, members named by their
manifests, `targets` inheritance), object-form `dependencies` only (`git`/`path`/`{ "workspace": true }`,
one source, one pin `branch|tag|rev`), `manifest.scanRoots` in the runner, the loader, the LSP and
`bpmp`, `botopink test` per member with `✗ ships nothing`, `docs/botopink-json.md`, and the located
errors of § 8 — 47 fixtures. This closes what the pre-decision plan spelled as three steps
(the umbrella rule, discovery, the schema document).

**Acceptance (met):**
- [x] `docs/botopink-json.md` exists and every field it documents is read by a named parser; the string-array `dependencies` is a located error in every tool, `bpmp` included
- [x] a `{ "path": … }` dependency is honoured by the compiler and the LSP without a root
- [x] a workspace member resolves by its manifest `name` from a consumer under the roots; the umbrella is never a lookup answer
- [x] `zig build test-libs` prints one row per member and none for the workspace; a library member without `files` is `✗ ships nothing`

### Step 2 — Each library's umbrella becomes a workspace

The four moves of § 11, per library, rakun first — in `.tasks/rakun-workspace`: the workspace
manifest, `modules/rakun/` created from `src/` + `test/` with `files`, the thirteen scaffolded
members re-pointed to `{ "rakun": { "workspace": true } }` and given `files`, `examples/rakun/rakun-app`
as a member. jhonstart, emilia and onze (after `01-std` has removed the old `onze`) follow with
their first front, in their own worktrees.

**Acceptance:**
- [ ] `import { Element } from "jhonstart";`, `import { Token } from "emilia";`, `import { … } from "rakun";` resolve to `modules/<lib>/` from a consumer under the roots — each pinned by an example member that imports it
- [ ] `import { … } from "rakun-web";` from an example resolves to `rakun-web/root` (one module, not zero); no `modules/*/botopink.json` in any repository lacks `files`; no manifest carries `{ "path": "../../" }`
- [ ] `import { … } from "jhonstart-test";` (and emilia, rakun, onze) resolves to a member with an empty `pub` surface and one inline `test` that passes
- [ ] `jhonstart/modules/jhonstart/test/html_test.bp` green at its new path; every emilia inline test green at its new path; rakun's five `test/*_test.bp` green through the core
- [ ] `zig build test-libs` lists every `modules/*` and `examples/*` member on every target its (inherited or restricted) `targets` allows, and no `rakun`/`jhonstart`/`emilia`/`onze` umbrella row — the listing diffed against `find repository -name botopink.json`
- [ ] `scripts/known-red-libs.txt` names every red row with a front number that exists in `specs/1.0.10-beta/`, and `zig build test-libs` exits 0 with them in place
- [ ] every `AGENTS.md` in a moved directory reflects the tree, same commit

### Step 3 — Examples become members

Every existing example gets (or corrects) a manifest — `entry main.bp`, the own library as
`{ "workspace": true }`, other libraries' cores by `path` — `out/` leaves git (and `.gitignore`),
a `README.md` names the upstream section, and `jhonstart-app` gets a manifest or moves into a
front's spec `examples/`. `examples/mock_synthesis.bp` leaves with the old `onze`.

**Acceptance:**
- [ ] every `examples/<p>/` has `botopink.json`, `README.md`, and builds under `zig build test-libs` on its declared target
- [ ] `git ls-files | grep 'examples/.*/out/'` is empty in every repository
- [ ] `emilia-card` still runs and prints what it printed before the move (verified by running, output compared)
- [ ] no example manifest carries a `git` dependency on a library of this ecosystem

### Step 4 — `<lib>-test` filled

Waits on `01-std` steps 2–3 (`std/testing/asserts`, `std/testing/snapshots`). Each `-test` member gains its first
`assert<Subject>(loc, …)` and the `test-snap.md` row that names it; nothing else of this front
depends on it.

**Acceptance:**
- [ ] each `modules/<lib>-test/src/root.bp` exports at least one `assert<Subject>(loc, …) -> @Result<void, string>` that hands `loc` to `snapshots` unchanged
- [ ] `0N-<lib>/test-snap.md` lists it with the `.snap` path it produces

## Gate

- [x] `zig build test` green in `repository/botopink-lang` with `modules/manifest/` (step 1, landed)
- [ ] `zig build test-libs` green with the per-member row list as the acceptance artefact
- [ ] `botopink format --check` clean in every moved tree
- [ ] `grep -rl onze13 repository` empty; no `**Owns:**` line, manifest `name` or directory under `specs/1.0.10-beta/` carries `onze13` (`../unification.md` and front 95 excepted)
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] one worktree per repository moved; each lands as a merge into that repository's `feat`, then the meta submodule bump — the seven remotes unified at the end (`overview.md` exit gate)

## Blast radius

Every repository moves files; no behaviour changes. What re-records: nothing — this front owns no
snapshot directory and creates only empty `__snapshots__/` locations. What goes red and is listed as
known-red until its front lands: any member row that is `✗ ships nothing` until its manifest gains
`files` (rakun's thirteen, until step 2), and the four erlang cells of
`erika/jhonstart/onze/rakun` already listed today. What a library front must redo if it lands
*before* this front: nothing, by construction — the wave rule sequences the tree before the first
front of each library.

## Notes

- The umbrella keeps a `botopink.json` because it is the workspace: the runner and the LSP find the
  library through it, and it answers no import. The pre-decision compromise (an umbrella with no
  `files` that the roots ordered behind the core) is gone with routes A/B.
- `path` is honoured by the loader and the LSP directly; the `language-gaps.md` rows that said
  otherwise close with step 1. Inside a workspace the sibling form is `{ "workspace": true }`, and a
  `path` to a sibling is a refusal — not a second spelling.
- The pin on a `git` dependency is `branch | tag | rev` (exactly one), not the literal `ref`
  decision 76's text wrote — `bpmp install` needs the pin's kind, and a second spelling would be the
  knob decision 67 refuses (the *Implemented* note under 76).
- Front 95's `asserts` → `assert` rename was already withdrawn in its own Step 1 ("keep the existing
  `asserts.bp` name"); `01-std/asserts-api.md` is the authority.
- What this front deliberately does not decide: whether `jhonstart-html`, `emilia-theme`,
  `emilia-modifiers`, `onze-pipeline` or `onze-release` exist. Each library's `modules.md` decides,
  with the consumption-boundary test above as the criterion, and `../fronts.md` copies the result.

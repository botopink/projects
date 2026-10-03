# Track 08 — bpp: Astro's feature set on the stack

**Repos:** `repository/jhonstart` · `repository/onze` · `repository/rakun` · `repository/emilia` ·
`repository/botopink-lang` (front 116 only) · **Reference:** the Astro documentation
(`/home/ericfillipe/develop/astro/astro-docs/`, 25 pages).

**Depends on:** `00-gate`; `03-bundled-libs/125-validation-zod` steps 0–2 (a `Schema<T>` is what a
collection and an action take); the fronts of tracks 04, 05 and 07 named in § Order.

The page-by-page map of the reference — 161 rows, each with the file that answers it today or the
front that adds it — is [`surface.md`](./surface.md).

## Goal

Astro is a file-routed, server-first framework with islands, and so is the stack: onze scans an
`app/` tree of eight file kinds, rakun serves and prerenders it, jhonstart renders it and hydrates
`#[client]` functions, emilia styles it. Of the 161 reference rows, 59 are on disk and running,
14 are on disk in one library and not connected by onze (a front of track 04, 05 or 07 owns the
wiring), 70 are added by this track, 3 wait on the compiler (a comptime body cannot read a file)
and 15 have no meaning here (adapters, other UI frameworks, CSS preprocessors, a plugin host).

What the track adds, in the order it costs:

1. **The template** (118). A page today is builder calls; the `html """…"""` DSL drops static
   attributes, takes only string holes, lowers a component tag as an ordinary call and emits a
   self-closing tag at the root (`jhonstart-html/src/html.bp`).
2. **Content** (121). No Markdown renderer, frontmatter reader or collection exists anywhere.
3. **Islands beyond "load"** (120). No hydration strategy, no server island.
4. **Scoped CSS, view transitions, typed actions, `locals`** (119, 126, 127, 123).
5. **The single-file look** (116) — a header over markup in a file of its own; the last thing the
   features need, not the first.

When the track is done a page reads:

```bpp
---
import {layouts.BaseLayout};
import {components.PostCard};
import {getCollection} from "onze-content";
import {content.blog};

val posts = await getCollection(blog());
val title = "Blog";
---
<BaseLayout title={title}>
  <h1>{title}</h1>
  {if (posts.isEmpty()) { <p class="empty">Nothing here yet.</p> }}
  <ul>
    {posts.map({ post -> <li><PostCard post={post} client:visible /></li> })}
  </ul>
</BaseLayout>

<style>
  ul { list-style: none; padding: 0; }
  .empty { color: gray; }
</style>
```

Every piece of it is ordinary botopink underneath. The header between the two `---` lines holds
declarations, copied to the module, and the statements of the function the file unfolds to
(decisions 198, 199, 212, 213); the markup is the literal handed to jhonstart's default function
`html` (decision 200); names the file does not bind resolve through jhonstart's `prelude.bp`
(decision 266); `{…}` holds a botopink expression — a lambda and an `if`, not an arrow function and
a ternary; `<PostCard post={post} />` is a call whose props value has `post` as a field (decision
192); `<style>` is scoped by emilia. The same page written as a `.bp` module with
`return html """…""";` compiles to the same thing, and is what fronts 117–127 are built and tested
against.

## Fronts

All eleven are **not started**: no code of the track exists in any repository.

| Front | Priority | State | What | Depends on (open) |
|---|---|---|---|---|
| [`118-bpp-components/`](./118-bpp-components/README.md) | **critical** — every other front writes markup through it | not started · ready to open | The template language: `{expr}` of any renderable type, attributes that render, components called with their props, slots, fragments, markup inside `if` / `case` / lambdas, `set:html`, `class:list`, `<style>` and `<script>` handed to sinks; jhonstart's `prelude.bp` and the node type | — |
| [`121-bpp-content/`](./121-bpp-content/README.md) | **high** — the largest piece of new code | not started · steps 1–2 ready to open | New member `onze-content`: Markdown (CommonMark + GFM) to `Element`, frontmatter, collections with a `Schema<T>`, `getCollection` / `getEntry` / `render`, `.md` pages, RSS | `08-f` (step 3) · 118, 117 (step 6) · `07-onze/53` (step 7) |
| [`120-bpp-islands/`](./120-bpp-islands/README.md) | **high** | not started | `client:idle` / `visible` / `media` / `only`; `server:defer` with a fallback slot and sealed props | 118 · 119 · 117 · `05-jhonstart/26` · `04-rakun/22` · `07-onze/49`, `50` · `08-e2` (step 4) |
| [`117-bpp-routing/`](./117-bpp-routing/README.md) | high | not started | `.bpp` / `.md` / `.html` as app files, `staticPaths` with data, `paginate`, partials, static endpoints, the eight priority rules as tests | `03-bundled-libs/102` · `04-rakun/22` · `07-onze/49`, `50` · 121 steps 1–2 · `bpp-g` (step 1) |
| [`119-bpp-styling/`](./119-bpp-styling/README.md) | medium | not started · blocked by `08-d` | Scoped `<style>`, `is:global`, `:global()`, `define:vars`, the cascade order | `08-d` (every step) · 118, `05-jhonstart/26` (step 2) |
| [`127-bpp-actions/`](./127-bpp-actions/README.md) | medium | not started | An action typed by a `#[schema]` record: JSON and form input, `ActionError`, a typed client call | 125 step 6 · `03-bundled-libs/103` · `04-rakun/22` · `05-jhonstart/67` · `07-onze/49` · 117 · 120 · 126 · 123 (step 4) |
| [`122-bpp-data/`](./122-bpp-data/README.md) | medium | not started | The `Astro` global, mapped; the three holes — page-side status and headers, `rewrite`, `site` | `05-jhonstart/26` · `07-onze/49` · `03-bundled-libs/102` · 118 · 120 |
| [`123-bpp-middleware/`](./123-bpp-middleware/README.md) | medium | not started | `locals`, `sequence`, a response rewritten after `next`, `actionContext` | `04-rakun/04` · `04-rakun/65` |
| [`126-bpp-view-transitions/`](./126-bpp-view-transitions/README.md) | low | not started | `transition:name` / `animate` / `persist`, `navigate`, the five lifecycle events, the route announcer | `05-jhonstart/27` · 118 · 120 |
| [`116-bpp-file-format/`](./116-bpp-file-format/README.md) | medium | not started | The `.bpp` file kind: `"bpp": "jhonstart"` in the application's manifest; the header between two `---` is botopink, the rest the literal of jhonstart's `html`; the package's prelude | 118 · `05-jhonstart/26` step 0 · `01-compiler/26` · `01-compiler`'s prelude scope · `bpp-f` (step 2) · `bpp-g` (step 6) |
| [`124-bpp-cli/`](./124-bpp-cli/README.md) | high — last | not started · blocked by `08-h` | `onze sync`, `onze create-key`, the config keys, component `<script>` bundling, the built style sheet, the `.bpp` scaffold | `08-h` · `08-e2` (steps 1, 3) · `07-onze/50`, `71` · every other front of the track · `07-onze/53` (step 5) |

## Order

```
00-gate ─► 03-bundled-libs/125 steps 0–2 (Schema<T>) ─────────────────────────────┐
                                                                                  │
wave A   118-bpp-components        (alone in html.bp, in the core after 26 step 0; carve-outs│
                                    before 34, 33, 26 and 119 open — decision 189)         │
         121-bpp-content steps 1–2 (alone in a new member: Markdown); step 3 on 08-f       │
         119-bpp-styling step 1    (alone in emilia/src/scoped.bp — on decision 08-d)      │
                    │                                                             │
wave B   123-bpp-middleware ◄── 04-rakun/04 (the core) · 04-rakun/65 (rakun-web)  │
         117-bpp-routing    ◄── 03-bundled-libs/102 · 04-rakun/22 · 07-onze/49 · 50 │
         120-bpp-islands    ◄── 05-jhonstart/26 · 07-onze/50 (lazy starters) · 117 (rakun-app) │
         122-bpp-data       ◄── 05-jhonstart/26 · 07-onze/49 · 120 (the core)     │
         126-bpp-view-transitions ◄── 05-jhonstart/27 (the reconcile driver) · 120 (html.bp) │
         119 step 2 · 121 steps 4–6 · 127-bpp-actions ◄──────────────────────────┘
         116-bpp-file-format ◄── 118 · 05-jhonstart/26 · 01-compiler/26 (decisions 198–200, 212, 213, 221, 266)
                    │
wave C   124-bpp-cli        ◄── 07-onze/50 · every front above
                    │
         124 step 5: the second example app — the blog as `.bpp`, under 07-onze/53's acceptance script
```

The waves say what each front waits on; the wave numbers the coordinator opens threads from, with
the other tracks, are [`../fronts.md`](../fronts.md) § Execution order of tracks 03–08.

- **118 is first.** A front that adds a directive (`client:visible`, `server:defer`,
  `transition:name`, `define:vars`) needs a template that parses directives; a front that renders
  Markdown needs `Element` values the template can splice. Nothing needs the `.bpp` extension.
- **116 is not first.** The compiler cannot lex HTML and emit calls to jhonstart —
  `build.zig`'s lib-agnostic check fails `zig build test` when `modules/compiler-core/src` names a
  library — and need not: compiler-core receives `Module{path, source, declaration, srcPath}` and
  never looks at an extension. What `.bpp` needs from the toolchain is one manifest key, the unfold,
  the prelude scope, and the places in four tools that list source extensions — generic work, and
  every feature of the track is testable without it.
- **124 is last.** It adds commands and config keys over what the other fronts build, and
  `07-onze/50` owns `onze dev`.

## Who else owns the files

Every front here except 121 edits files a front of another track owns. `fronts.md`'s rule
applies — sequenced, never together — and the sequence is visible from both sides:

| This front edits | Also owned by | Sequence |
|---|---|---|
| the `[name]={expr}` attributes outside `html.bp` — emilia's `attributes.bp` and `emilia.bp`, `examples/emilia-card`, the core's two files, `jhonstart-emilia`'s bridge test, `document-shell` (118 step 1) | `06-emilia/34`; `06-emilia/33`; `05-jhonstart/26`; 119 | named one-line carve-outs by 118, each landed before the owning front opens (decision 189) |
| `jhonstart/src/prelude.bp` (new, 118) | `05-jhonstart/26` | a carve-out of 26's member, by 118 (decision 266) |
| `jhonstart/src/{client.bp, render.bp, island_runtime.mjs}` (120) · `server.bp`, `error_boundary.bp` (122) | `05-jhonstart/26` | after 26; 120, then 122, one at a time on the member's `botopink.json` and `root.bp` |
| `jhonstart-link/**` — new files only, plus two lines of `link_runtime.mjs` (126) | `05-jhonstart/27` | after 27 |
| `jhonstart-forms/src` — new `typed_call.bp` (127) | `05-jhonstart/67`, `03-bundled-libs/103` | after both |
| `jhonstart-dom-test` — a test file per front (119, 120, 126, 127); `fake_dom.mjs` (120's observers, 126's `startViewTransition` double) | `05-jhonstart/26` | each front owns the test file it adds; `fake_dom.mjs` stays 26's and is edited by one front at a time after 26 — 120, then 126 (decision 189) |
| `html.bp` (`jhonstart/src/html.bp` after 26 step 0) — one lowering arm each (119, 120, 126) | 118 | after 118; one appending front at a time, in that order |
| `onze-cli/src/scan.bp` (117) · `onze-cli/**`, `onze-bundler/**` (124) | `07-onze/50`, `03-bundled-libs/102` | after both |
| `onze/src/paginate.bp` (117) · `onze/src/config.bp` — the `site` key (122), the other keys (124) (decision 189) | `07-onze/49` | after 49 |
| `onze-server/src/server.bp` — the island route, the content boot step | `07-onze/49` | after 49 |
| `rakun-app/src/{static_gen,actions}.bp` (117, 127) · new `server_islands.bp` (120), `typed_action.bp` (127) | `04-rakun/22` | after 22; 117, then 120, then 127, one at a time on the member's `botopink.json` and `root.bp` |
| `rakun/src/locals.bp` (new) · `rakun-web/src/{middleware,filter}.bp` (123) | `04-rakun/04` (the core) · `04-rakun/65` (rakun-web) | after 04 and after 65 (decision 189) |
| `libs/routing/src/{segment,conventions}.bp` (117) · `navigation.bp` (122) | `03-bundled-libs/102` | after 102 |
| `libs/actions/src/outcome.bp` (127) | `03-bundled-libs/103` | after 103 |
| `emilia/src/` — one new file (119) | `06-emilia/34` | beside it: 34 does not touch `scoped.bp` |
| `compiler-cli/**`, `language-server/**` (116) | `01-compiler/26-cli-tooling` | 116 opens after 26 |

## Handed to other tracks

Found by the reanalysis, owned elsewhere. Each is a row of `surface.md` in the **wire** box.

| Item | Where | Owner |
|---|---|---|
| A static attribute in `html """…"""` never reaches the rendered tree | `jhonstart-html/src/html.bp:138-146`, `:233-234` | 118 fixes it; reported because every existing use of the DSL is affected |
| `data-jh-on-click` is written by the server and read by nothing | `jhonstart/modules/jhonstart/src/island_runtime.mjs` — one `addEventListener`, the refresh button (`:98`) | `05-jhonstart/26` (it carries front 29) |
| `Metadata` is rendered by jhonstart and onze passes `[]` | `onze-server/src/server.bp:116` | `07-onze/53` (ONZ-53-3) |
| `serveApp`, `serveActions`, `prerenderAll`, the image route: implemented in rakun and onze-assets, not called by `bootServer` | `onze-server/src/server.bp:212-221` | `07-onze/49` · `50` · `51` |
| The scan records a decorator's argument and never compares it with the file's directory | `onze-cli/src/scan.bp:36-56`, `:66-96` — read, not run | `07-onze/50`; 117 step 0 measures it |
| `io.http.fetch` is GET only | `libs/std/src/io/http.bp` | `02-std-and-packaging` (the row `03-bundled-libs/README.md` names) |
| `<Picture>`, `getImage`, remote patterns | `onze-assets` | `07-onze/51` |
| The lib-agnostic gate greps for three of the five library names (`rakun\|jhonstart\|erika`); `onze` and `emilia` occur in compiler-core comments | `repository/botopink-lang/build.zig`; `codegen/erlang.zig` | `01-compiler/08-hygiene` |

## Rules in force

Decisions the fronts are written against, one line each; the full text is in
[`../decisions-taken.md`](../decisions-taken.md).

| Decision | Rule | Fronts |
|---|---|---|
| 190 | The library decides which types an embedded `{expr}` may have and refuses the others with a located comptime error; the compiler owes the means (a `language-gaps.md` row). Until then the template reads `{expr}` from the raw text and re-emits it through `build` | 118 step 2 |
| 191 | jhonstart's `html` accepts in a hole: a `string`; a number or a `bool` as its `toString()` text; a component of the same base (`Element`, base `ElementBase`); a list of them; the node type. Anything else is a comptime error at the expression | 118 step 2 |
| 192 | On a component tag the attributes are the fields of the type of the component's first parameter; an undeclared attribute, a wrong type, a required field left unwritten are errors at the attribute | 118 steps 1, 4 |
| 193 · 223 | A component takes children only through a `children` field of its props, typed `Node` (decision 223 names jhonstart's node type `Node`, replacing `JhonstartNode`/`Children`); content in a component without one is an error at the tag | 118 step 4 · `05-jhonstart` |
| 204 | A hole of type `?T` is refused at the hole | 118 step 2 |
| 207 | A props type may be written inline in a parameter (`props: type(…)`) | 118 · `01-compiler/01-checker` |
| 198 · 212 | A `.bpp` file is another spelling of a `.bp` module: the application's `botopink.json` names a package (`"bpp": "<package>"`) and the toolchain unfolds the file onto that package's `pub default fn`, naming no library. The header sits between two `---` lines at the very start of the file and is copied into the module as written; everything after the second `---` (or the whole file, with no header) is the literal. A first line that is not `---` in a file that has one, or a header never closed, is an error at the line. No `template.emit` / `template.slice` | 116 |
| 199 | `type Props(…)` in the header is the convention: the file unfolds to a function taking `props: Props`, or no parameter without one, never a `pub val`. The header's declarations (`import`, `type`, `pub`) stay at module level; its statements (`val`, `use`) become the body ahead of the `return` | 116 · 118 · 120 |
| 213 | The function is the module's `pub default fn`, named after the file: `components/PostCard.bpp` is `pub default fn PostCard(props: Props) -> Element`, imported `import {components.PostCard};`; a file name that is not a function name is an error | 116 · 118 |
| 200 | `html` is the `pub default fn` of the core member `jhonstart` (`import html, {Element} from "jhonstart";`); `jhonstart-html` is deleted; an application's manifest reads `"bpp": "jhonstart"` | `05-jhonstart/26` step 0 · 116 · 118 |
| 221 | A `page.bpp` gets its decorator from the header (a line just before the closing `---`) or, failing that, from the file's name, through the `"bppKinds"` map the `bpp` package's `botopink.json` declares; a header decorator that differs from the file name's is an error | 116 step 2 · 117 step 1 |
| 266 | The `bpp` package's `src/prelude.bp` (imports of the package's own modules only) is the `.bpp` module's last scope; an item is imported only when a name of the file resolves through it; the header wins; binding the default function's name is an error. 118 writes jhonstart's `prelude.bp` | 116 · 118 |
| 186 · 202 | The stage a page renders in is a comptime fact: `#[page]` prerenders a page that reaches no `#[serverOnly]` hook, and renders per request one that does; no page declares or forces its stage (no `prerender` export, no `output` key) | 117 step 2 · 123 · 124 |
| 203 | One routing convention: the `app/` tree, a directory per route; a `.bpp` is valid where a `page.bp` is; no `pages/` tree | 117 step 1 |
| 222 | A route handler (`route.bp`, every method) is always server, at request time, never prerendered | 117 step 4 · 121 step 5 |
| 224 | Server-island props are configurable, default **sealed** (AES-256-GCM in the URL; key `ONZE_KEY` or generated at build, `onze create-key`); the mode is set in `onze.json` `"islands": {"props": "sealed"}`, per project | 120 step 4 · 124 |
| 189 | The track's ordering and ownership calls (carve-outs, `fake_dom.mjs`, `site` by 122) | all |

There is no relative-path import in botopink: a module of the same package is
`import {components.card.Card};`, a package `import {x} from "pkg";` — the header of a `.bpp` file
follows the language's own form.

## Decisions the maintainer owes

Open: `08-d`, `08-e2`, `08-f`, `08-h` (below) and `bpp-f`, `bpp-g` (full text in
[`../decisions-pending.md`](../decisions-pending.md)). Each takes the next free number in
`decisions-taken.md` when answered.

- `bpp-f` — the return type of the function a `.bpp` file unfolds to (`-> Element` against a header
  that `await`s or `use`s). Blocks 116 step 2.
- `bpp-g` — how a `page.bpp` gets its `route: PageContext` and its `params`. Blocks 116 step 6,
  117 step 1.

### 08-d · Who scopes CSS

**Measured.** emilia compiles `Token[]` and is "not a runtime CSS engine. No selector parsing" (`emilia/AGENTS.md:602`).
onze-assets renames the classes of `*.module.css` (`onze-assets/src/style_module.bp`). Decision
113: emilia is CSS, jhonstart is HTML.
**Options.** (a) emilia gains `scopeCss(scope, css)`, reached through the `jhonstart-emilia`
bridge; (b) onze-assets, beside the module renamer; (c) jhonstart's `html` scopes its own `<style>`.
**Recommendation.** (a). (c) puts a CSS parser in the HTML library; (b) makes scoped styles
unavailable to a jhonstart application that does not use onze.
**Blocks.** All of 119.

### 08-e2 · Which modes the islands props setting may name

**Raised by** decision 224, which makes the mode configurable with `sealed` as the default and
leaves the other values open, noting that decision 67 forbids a setting that weakens a rule.
**Options.** (a) `sealed` only — the key exists with one value (or is dropped), since any other
mode is weaker; (b) `sealed` and `signed` (readable by the visitor, tamper-proof — 08-e's former
option (b)); (c) as (b), plus `server` (kept on the server under a random id — nothing in the URL,
the shell no longer cacheable across instances — 08-e's former option (c)).
**Recommendation.** (a): decision 67's reading — a mode that publishes what a page passes, or
defeats caching, is a setting that weakens the rule.
**Blocks.** 120 step 4 (what `seal` / `unseal` dispatch on); 124 steps 1 and 3 (the config key and
what `create-key` serves).

### 08-f · Where Markdown and YAML live

**Measured.** No Markdown code in the tree. One YAML-subset reader, in rakun's config
(`rakun/modules/rakun/src/config.bp:340`); `03-bundled-libs/README.md` § "What does not move"
says the config readers go to std "when a second consumer appears".
**Options.** (a) both in the new member `onze-content`; (b) Markdown in `onze-content`, YAML in
std as `yaml` (97's tree) with rakun's reader deleted by rakun's front; (c) a bundled `markdown`
package.
**Recommendation.** (b). Frontmatter is the second consumer the bundled-libs README was waiting
for. Markdown has one consumer, so decision 115's "two or more libraries" does not make it a
package. Until `yaml` lands in std, 121 step 3 reads frontmatter with its own copy and deletes it
on std's landing.
**Blocks.** 121 step 3 (frontmatter); under (c), where steps 1–2 live; a row for
`02-std-and-packaging/97`.

### 08-h · The config file and the commands

**Measured.** `onze.json` exists and refuses unknown keys (49-c); `onze create | info | build |
start` exist and `dev` is a stub (`onze-cli/src/main.bp`); `botopink` has no framework command
(`compiler-cli/src/main.zig`).
**Options.** (a) `onze.json` and `onze <command>`; (b) a second file (`bpp.json`) and `botopink
dev` / `preview` in the compiler's CLI.
**Recommendation.** (a). (b) makes the compiler's CLI a framework's CLI.
**Blocks.** 124.

## Rules for this track

- **The compiler knows no library.** 116 is the only front that edits `repository/botopink-lang`,
  and what it adds names no library and knows no syntax: a manifest key, the `.bpp` extension in
  the tools' lists, the unfold of a file onto the default function of the package the key names
  (decision 198), and the prelude as a generic last scope (decision 266). What the markup means is
  that function's — jhonstart's `html`.
- **A library front never touches `modules/**`.** A need is a row in
  [`language-gaps.md`](../language-gaps.md) and a nearest form.
- **The libraries keep their concerns** (decision 113): the template is jhonstart's, CSS is
  emilia's, the request and the route table are rakun's, onze wires. No front here adds a fifth
  library.
- **The most restrictive behaviour, and no configuration that bypasses it** (decision 67). A
  directive the template does not know is a compile error at its span, not an attribute that
  renders. `client:*` on a function that is not `#[client]` does not build.
- **Astro's names are kept where the stack has no name of its own** (`client:visible`,
  `server:defer`, `set:html`, `class:list`, `transition:name`) **and replaced where it has one**:
  there is no `Astro` global — a page has parameters, hooks and navigation signals
  ([`122-bpp-data/`](./122-bpp-data/README.md) is the table).
- **Examples are code.** Each front's `examples/` holds what its steps are aiming at; when a step
  lands, its example moves into the member's tests or `examples/` tree and must compile. An
  `-example.bp` file is one compilable unit with its tests. Where a feature is written in a page,
  a layout or a component, `examples/src/` holds the same code as the `.bpp` files of an
  application — laid out as the application's tree, because a `.bpp` file's name and directory
  are part of what it says — and compiles when 116 lands (116 step 6). The examples of
  `05-jhonstart` and `07-onze/53` that hold a page, a layout or a component carry their `.bpp`
  form the same way. `04-rakun` and `06-emilia` carry none: their examples are services and
  token tests, and a file with no markup has nothing to put after the header.
- **`status.md` is the only file that carries status.**

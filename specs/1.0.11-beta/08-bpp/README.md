# Track 08 — bpp: Astro's feature set on the stack

**Repos:** `repository/jhonstart` · `repository/onze` · `repository/rakun` · `repository/emilia` ·
`repository/botopink-lang` (front 116 only) · **Reference:** the Astro documentation
(`/home/ericfillipe/develop/astro/astro-docs/`, 25 pages) · **New in this milestone** — nothing here
is carried from 1.0.10.

**Depends on:** `00-gate`; `03-bundled-libs/125-validation-zod` steps 0–2 (a `Schema<T>` is what a
collection and an action take); the fronts of tracks 04, 05 and 07 named in § Order.

The page-by-page map of the reference — 160 rows, each with the file that answers it today or the
front that adds it — is [`surface.md`](./surface.md).

## What the stack already is

Astro is a file-routed, server-first framework with islands. So is the stack 1.0.10-beta landed:
onze scans an `app/` tree of eight file kinds, rakun serves and prerenders it, jhonstart renders
it and hydrates `#[client]` functions, emilia styles it. `surface.md` counts the consequence:

| Of 160 reference rows | |
|---|---|
| on disk and running | 60 |
| on disk in one library, not connected by onze — owned by a front of track 04, 05 or 07 | 14 |
| added by this track | 70 |
| waiting on the compiler (a comptime body cannot read a file) | 3 |
| without meaning here (adapters, other UI frameworks, CSS preprocessors, a plugin host) | 13 |

What Astro has and the stack does not, in the order it costs:

1. **The template.** A page here is a function returning builder calls
   (`article([h1([text(t, attrs: [])], attrs: [])], attrs: [])`). The `html """…"""` DSL exists and
   is not usable for a page: a hole is a string, a static attribute is dropped from the tree, a
   component tag is an ordinary call, a self-closing tag is emitted at the root
   (`jhonstart-html/src/html.bp:110-253`). Front **118**.
2. **Content.** No Markdown renderer, no frontmatter reader, no collection anywhere in the six
   repositories. Front **121**.
3. **Islands beyond "load".** No hydration strategy, no server island. Front **120**.
4. **Scoped CSS, view transitions, typed actions, `locals`.** Fronts **119**, **126**, **127**,
   **123**.
5. **The single-file look** — a script fence over markup, in a file of its own. Front **116**, and
   it is the last thing the features need, not the first.

## What a page looks like when the track is done

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

Every piece of it is ordinary botopink underneath (decisions 198, 199). The header before `---`
holds declarations, copied to the module, and the statements of the function the file unfolds
to; the markup is the literal handed to jhonstart's default function `html` (decision 200);
`{…}` holds a botopink expression — a lambda and an `if`, not an arrow function and a ternary;
`<PostCard post={post} />` is a call whose props value has `post` as a field (decision 192);
`<style>` is scoped by emilia. The
same page written as a `.bp` module with `return html """…""";` compiles to the same thing, and is
what fronts 117–127 are built and tested against.

## Fronts

| Front | Priority | Owns | What |
|---|---|---|---|
| [`118-bpp-components/`](./118-bpp-components/README.md) | **critical** — every other front writes markup through it | `html.bp` and its tests — in the core `jhonstart` after `05-jhonstart/26` step 0 (decision 200) | The template language: `{expr}` of any renderable type, attributes that render, components as labelled calls, slots, fragments, markup inside `if` / `case` / lambdas, `set:html`, `class:list`, `<style>` and `<script>` handed to sinks |
| [`121-bpp-content/`](./121-bpp-content/README.md) | **high** — the largest piece of new code | new member `onze/modules/onze-content/**` | Markdown (CommonMark + GFM) to `Element`, frontmatter, collections with a `Schema<T>`, `getCollection` / `getEntry` / `render`, `.md` pages, RSS |
| [`120-bpp-islands/`](./120-bpp-islands/README.md) | **high** | `jhonstart` island files; new `rakun-app/src/server_islands.bp` | `client:idle` / `visible` / `media` / `only`; `server:defer` with a fallback slot and sealed props |
| [`117-bpp-routing/`](./117-bpp-routing/README.md) | high | `onze-cli/src/scan.bp` lines, `routing` segment grammar, `rakun-app/src/static_gen.bp` lines | `.bpp` / `.md` / `.html` as app files, `staticPaths` with props, `paginate`, partials, static endpoints, the eight priority rules as tests |
| [`119-bpp-styling/`](./119-bpp-styling/README.md) | medium | new `emilia/modules/emilia/src/scoped.bp`; `jhonstart-emilia/**` | Scoped `<style>`, `is:global`, `:global()`, `define:vars`, the cascade order |
| [`127-bpp-actions/`](./127-bpp-actions/README.md) | medium | `rakun-app/src/actions.bp` lines, `jhonstart-forms` lines | An action typed by a `#[schema]` record: JSON and form input, `ActionError`, a typed client call |
| [`122-bpp-data/`](./122-bpp-data/README.md) | medium | `jhonstart/src/server.bp` lines | The `Astro` global, mapped; the three holes — page-side status and headers, `rewrite`, `site` |
| [`123-bpp-middleware/`](./123-bpp-middleware/README.md) | medium | `rakun-web/src/middleware.bp` lines, new `locals.bp` | `locals`, `sequence`, a response rewritten after `next`, `actionContext` |
| [`126-bpp-view-transitions/`](./126-bpp-view-transitions/README.md) | low | new files in `jhonstart-link` | `transition:name` / `animate` / `persist`, `navigate`, the five lifecycle events, the route announcer |
| [`116-bpp-file-format/`](./116-bpp-file-format/README.md) | medium | `botopink-lang`: `modules/manifest`, `compiler-cli`, `language-server`, `lib-test-runner`; `vscode-extension` | The `.bpp` file kind (decisions 198–200): `"bpp": "jhonstart"` in the application's manifest; the header before `---` is botopink, the rest the literal of jhonstart's default function `html` |
| [`124-bpp-cli/`](./124-bpp-cli/README.md) | high — last | `onze-cli/**`, `onze-bundler/**` lines, `onze/src/config.bp` | `onze sync`, `onze create-key`, five config keys, component `<script>` bundling, the built style sheet, the `.bpp` scaffold |

## Order

```
00-gate ─► 03-bundled-libs/125 steps 0–2 (Schema<T>) ─────────────────────────────┐
                                                                                  │
wave A   118-bpp-components        (alone in html.bp, in the core after 26 step 0; carve-outs│
                                    before 34, 33, 26 and 119 open — decision 189)         │
         121-bpp-content steps 1–3 (alone in a new member: Markdown, frontmatter) │
         119-bpp-styling step 1    (alone in emilia/src/scoped.bp — on decision 08-d)      │
                    │                                                             │
wave B   123-bpp-middleware ◄── 04-rakun/04 (the core) · 04-rakun/65 (rakun-web)  │
         117-bpp-routing    ◄── 03-bundled-libs/102 · 04-rakun/22 · 07-onze/49 · 50 │
         120-bpp-islands    ◄── 05-jhonstart/26 · 07-onze/50 (lazy starters) · 117 (rakun-app) │
         122-bpp-data       ◄── 05-jhonstart/26 · 07-onze/49 · 120 (the core)     │
         126-bpp-view-transitions ◄── 05-jhonstart/27 (the reconcile driver) · 120 (html.bp) │
         119 step 2 · 121 steps 4–6 · 127-bpp-actions ◄──────────────────────────┘
         116-bpp-file-format ◄── 118 · 05-jhonstart/26 · 01-compiler/26 (decisions 198–200)
                    │
wave C   124-bpp-cli        ◄── 07-onze/50 · every front above
                    │
         124 step 5: the second example app — the blog as `.bpp`, under 07-onze/53's acceptance script
```

The waves here say what each front waits on; the wave numbers the coordinator opens threads from,
with the other tracks, are [`../fronts.md`](../fronts.md) § Execution order of tracks 03–08.

**Why 118 is first.** A front that adds a directive (`client:visible`, `server:defer`,
`transition:name`, `define:vars`) needs a template that parses directives. A front that renders
Markdown needs `Element` values the template can splice. Nothing needs the `.bpp` extension.

**Why 116 is not first.** The file format reads as the foundation, and would be if the compiler
lexed HTML and emitted calls to jhonstart. It cannot do that — `build.zig:342-355` fails `zig
build test` when `modules/compiler-core/src` names a library — and does not need to:
compiler-core receives `Module{path, source, declaration}` (`module.zig:5-15`) and never looks at
an extension. What `.bpp` needs from the toolchain is one manifest key, a template body that can
emit declarations and keep an origin, and the places in four tools that list source extensions. That is real work, it is generic, and every
feature of the track is testable without it.

**Why 124 is last.** It adds commands and config keys over what the other fronts build, and
`07-onze/50` owns `onze dev`.

## Who else owns the files

Every front here except 121 edits files a front of another track owns. `fronts.md`'s rule applies —
sequenced, never together — and the sequence is visible from both sides:

| This front edits | Also owned by | Sequence |
|---|---|---|
| the `[name]={expr}` attributes outside `html.bp` — emilia's `attributes.bp` and `emilia.bp`, `examples/emilia-card`, the core's two files, `jhonstart-emilia`'s bridge test, `document-shell` (118 step 1) | `06-emilia/34`; `06-emilia/33`; `05-jhonstart/26`; 119 | named one-line carve-outs by 118, each landed before the owning front opens (decision 189) |
| `jhonstart/src/{client.bp, render.bp, island_runtime.mjs}` (120) · `server.bp`, `error_boundary.bp` (122) · new `bpp.bp` (116) | `05-jhonstart/26` | after 26; 120, then 122, one at a time on the member's `botopink.json` and `root.bp` |
| `jhonstart-link/**` — new files only, plus two lines of `link_runtime.mjs` (126) | `05-jhonstart/27` | after 27 |
| `jhonstart-forms/src` — new `typed_call.bp` (127) | `05-jhonstart/67`, `03-bundled-libs/103` | after both |
| `jhonstart-dom-test` — a test file per front (119, 120, 126, 127); `fake_dom.mjs` (120's observers, 126's `startViewTransition` double) | `05-jhonstart/26` | each front owns the test file it adds; `fake_dom.mjs` stays 26's and is edited by one front at a time after 26 — 120, then 126 (decision 189) |
| `html.bp` (`jhonstart/src/html.bp` after 26 step 0) — one lowering arm each (119, 120, 126) | 118 | after 118; one appending front at a time, in that order |
| `onze-cli/src/scan.bp` (117) · `onze-cli/**`, `onze-bundler/**` (124) | `07-onze/50`, `03-bundled-libs/102` | after both |
| `onze/src/paginate.bp` (117) · `onze/src/config.bp` — the `site` key (122), the other four keys (124) (decision 189) | `07-onze/49` | after 49 |
| `onze-server/src/server.bp` — the island route, the content boot step | `07-onze/49` | after 49 |
| `rakun-app/src/{static_gen,actions}.bp` (117, 127) · new `server_islands.bp` (120), `typed_action.bp` (127) | `04-rakun/22` | after 22; 117, then 120, then 127, one at a time on the member's `botopink.json` and `root.bp` |
| `rakun/src/locals.bp` (new) · `rakun-web/src/{middleware,filter}.bp` (123) | `04-rakun/04` (the core) · `04-rakun/65` (rakun-web) | after 04 and after 65 (decision 189) |
| `libs/routing/src/{segment,conventions}.bp` (117) · `navigation.bp` (122) | `03-bundled-libs/102` | after 102 |
| `libs/actions/src/outcome.bp` (127) | `03-bundled-libs/103` | after 103 |
| `emilia/src/` — one new file (119) | `06-emilia/34` | beside it: 34 does not touch `scoped.bp` |

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
| The lib-agnostic gate greps for three of the five library names (`rakun\|jhonstart\|erika`); `onze` and `emilia` occur in compiler-core comments | `repository/botopink-lang/build.zig:342-355`; `codegen/erlang.zig:6687`, `:8525` | `01-compiler/08-hygiene` |

## Decisions the maintainer owes

Lettered `08-a…`; each takes the next free number (214 onward,
[`../decisions-pending.md`](../decisions-pending.md)) when answered. Answered: `08-a` and `08-i`
(decision 198), `08-a2` (199), `08-a3` (200), `08-c` (190, with 191–193 for what it leaves to the
library), `08-g` (202, on decision 186). Open: `08-b`, `08-d`, `08-e`, `08-f`, `08-h`.

### Answered — what a `.bpp` file is (`08-a`, `08-i`, `08-a2`, `08-a3`; decisions 198–200)

| Decision | Rule | Where |
|---|---|---|
| 198 | A `.bpp` file is another spelling of a `.bp` module, unfolded by the toolchain onto a library's default function. The application's `botopink.json` names a package, `"bpp": "<package>"`, and the toolchain uses that package's `pub default fn` — a template function — naming no library itself. Everything before a `---` line is ordinary botopink, copied into the module as written; everything after it, or the whole file when there is no `---` line, is the literal handed to the default function. The template entry gains nothing — no `template.emit`, no `template.slice`: the module-level half is the header, so `08-i` has no question left | 116 |
| 199 | `type Props(…)` in the header is the convention. A `.bpp` file unfolds to a function, never a `pub val`: with `type Props(…)`, `card.bpp` is `pub fn card(props: Props) -> Element`; with none, `pub fn card() -> Element`. The header's declarations (`import`, `type`, `pub`) stay at module level; its statements (`val`, `use`) become the function's body ahead of `return html """…""";`. Attributes are the fields of `Props` (192), children its `children` field (193) | 116 · 118 · 120 |
| 200 | `html` is the `pub default fn` of the core member `jhonstart` — `import html, {Element, renderToString} from "jhonstart";` — and the member `jhonstart-html` is deleted (decision 187's criterion). The manifest reads `"bpp": "jhonstart"`; `jhonstart-emilia` and the two examples that depended on `jhonstart-html` import from the core | `05-jhonstart/26` step 0 · 116 · 118 |

There is no relative-path import in botopink: a module of the same package is
`import {components.card.Card};`, a package `import {x} from "pkg";` — the header of a `.bpp`
file follows the language's own form.

### 08-b · One routing convention, or two

**Measured.** onze routes by directory: `app/blog/[slug]/page.bp` (`onze/src/types.bp`
`appFileKinds`, eight kinds). Astro routes by file: `src/pages/blog/[slug].astro`.
**Options.** (a) one — a `.bpp` (or `.md`) file is accepted wherever a `.bp` app file is:
`app/blog/[slug]/page.bpp`; (b) a second scanner for a `pages/` tree, file = route.
**Recommendation.** (a). Two conventions in one project are two answers to "which file serves
`/about`", and the directory form is the one that has layouts, loading and error files beside the
page.
**Blocks.** 117 step 1.

### Answered — what a template accepts (`08-c`; decisions 190–193)

`08-c` is answered and 118 is written against it. The rules, each a row of
[`../decisions-taken.md`](../decisions-taken.md):

| Decision | Rule | Where |
|---|---|---|
| 190 | The library decides which types an embedded expression may have and refuses the others with a comptime error located at the expression; the compiler provides the means — an embedded expression of any type reaches the template function with its type readable at comptime and its position, and the function can raise a located error (a `language-gaps.md` row, owner `01-compiler`). The surface is `{expr}`. Until the means exist, the template function reads `{expr}` out of the literal's raw text and re-emits it through `build`, where a wrong type is the checker's error at the template call | 118 step 2 |
| 191 | A template of jhonstart's `html` accepts in `{expr}` a closed list: a `string`; a number of any numeric type and a `bool`, each written as its `toString()` text, the same on every target; a component of the same base context as the template (`Element`, base `ElementBase`); a list of such components; and the node type, which names exactly that set. A record, an optional, a function, a component of another base: a comptime error located at the expression | 118 step 2 |
| 192 | On a component tag the attributes are the fields of the type of the **first parameter** of the component's function: each name must be one of those fields, each value has that field's type. An undeclared attribute, a value of another type, and a field with no default left unwritten are comptime errors located at the attribute. Native HTML tags are not covered by the decision | 118 steps 1 and 4 |
| 193 | A component takes children only when the type of its first parameter declares a `children` field, whose type says what is acceptable — `children: JhonstartNode`, the node type (decision 191's set; the type jhonstart calls `Children` today takes this name). Content inside the tag of a component whose props declare no `children` is a comptime error at the tag; a second `children` parameter beside the props goes away | 118 step 4; hand-offs to `05-jhonstart` |

### 08-d · Who scopes CSS

**Measured.** emilia compiles `Token[]` and is "not a CSS processor" (`emilia/AGENTS.md:602`).
onze-assets renames the classes of `*.module.css` (`onze-assets/src/style_module.bp:1-36`).
Decision 113: emilia is CSS, jhonstart is HTML.
**Options.** (a) emilia gains `scopeCss(scope, css)`, reached through the `jhonstart-emilia`
bridge; (b) onze-assets, beside the module renamer; (c) jhonstart-html scopes its own `<style>`.
**Recommendation.** (a). (c) puts a CSS parser in the HTML library; (b) makes scoped styles
unavailable to a jhonstart application that does not use onze.
**Blocks.** 119.

### 08-e · What a server island does with its props

**Measured.** Astro encrypts them into the island's URL with a per-build key. An action id here
is an HMAC (`rakun-app/src/actions.bp:237`). std has `hmacSha256` and no cipher
(`libs/std/AGENTS.md`, `hash`); rakun is erlang-only, and OTP's `crypto` has AES-GCM.
**Options.** (a) sealed — AES-256-GCM through one Erlang host cell in rakun-app, key from
`ONZE_KEY` or generated per build; (b) signed only — readable by the visitor, tamper-proof; (c)
kept on the server under a random id — nothing in the URL, and the shell is no longer cacheable
across instances.
**Recommendation.** (a). (b) publishes whatever a page passes; (c) defeats the reason the feature
exists.
**Blocks.** 120 step 4; 124 (`onze create-key`).

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

### Answered — the stage a page renders in (`08-g`; decisions 186, 202)

A page is produced along three stages — comptime (the build, where a page is prerendered),
server (request time), client (decision 186). No page declares its stage (decision 202):
jhonstart's existing `#[page]` decorator (`routes.bp:220`, `pub fn page(comptime decl: @Decl,
seg: string)`) reads, through the checker capability of decision 186, whether the page reaches a
`#[serverOnly]` hook by `use`; a page that reaches none is prerendered at comptime by that
decorator, a page that reaches one is rendered per request. There is no `pub val prerender`, no
`output` key in `onze.json`, and no way to force a page that reaches no server hook to render per
request. `117` step 2 · `124` · `05-jhonstart/26` step 8.

### 08-h · The config file and the commands

**Measured.** `onze.json` exists and refuses unknown keys (49-c); `onze create | info | build |
start` exist (`onze-cli/src/main.bp:19-104`); `botopink` has no framework command
(`compiler-cli/src/main.zig:121-170`).
**Options.** (a) `onze.json` and `onze <command>`; (b) a second file (`bpp.json`) and `botopink
dev` / `preview` in the compiler's CLI.
**Recommendation.** (a). (b) makes the compiler's CLI a framework's CLI.
**Blocks.** 124.

## Rules for this track

- **The compiler knows no library.** 116 is the only front that edits `repository/botopink-lang`,
  and what it adds names no library and knows no syntax: a manifest key, the `.bpp` extension in
  the tools' lists, and the unfold of a file onto the default function of the package the key
  names (decision 198). What the markup means is that function's — jhonstart's `html`.
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
  token tests, and a file with no markup has nothing to put after a fence.
- **`status.md` is the only file that carries status.**

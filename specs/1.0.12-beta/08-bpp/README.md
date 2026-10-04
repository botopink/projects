# Track 08 — bpp: Astro's feature set on the stack

**Repos:** `repository/jhonstart` · `repository/onze` · `repository/rakun` · `repository/emilia` ·
`repository/botopink-lang` (116 only) · **Reference:** Astro docs (`/home/ericfillipe/develop/astro/astro-docs/`, 25 pages).
**Depends on:** `00-gate`; `03-bundled-libs/125-validation-zod` steps 0–2 (`Schema<T>`, taken by
collections and actions); the 04/05/07 fronts in § Order. **Map:** [`surface.md`](./surface.md) (161 rows).

## Goal

onze scans an `app/` tree of eight file kinds, rakun serves/prerenders, jhonstart renders and
hydrates `#[client]` functions, emilia styles. Of 161 rows: 59 running; 14 on disk in one library,
unwired by onze (a 04/05/07 front owns it); 70 added here; 3 wait on the compiler (a comptime body
cannot read a file); 15 meaningless here (adapters, other UI frameworks, CSS preprocessors, plugin host).

Added, by cost:

1. **Template** (118). Pages are builder calls; `html """…"""` drops static attributes, takes only
   string holes, lowers a component tag as a plain call, emits a self-closing root tag (`jhonstart-html/src/html.bp`).
2. **Content** (121). No Markdown renderer, frontmatter reader or collection exists.
3. **Islands beyond "load"** (120). No hydration strategy, no server island.
4. **Scoped CSS, view transitions, typed actions, `locals`** (119, 126, 127, 123).
5. **Single-file look** (116) — header over markup in its own file; last.

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
    {posts.map({ post -> <li><PostCard #[clientVisible] post={post} /></li> })}
  </ul>
</BaseLayout>

<style>
  ul { list-style: none; padding: 0; }
  .empty { color: gray; }
</style>
```

Header = module declarations + statements of the unfolded function (198, 199, 212, 213); markup =
literal of jhonstart's default `html` (200); unbound names via jhonstart's `prelude.bp` (270); `{…}`
is botopink (lambda, `if`; no arrow, no ternary); `<PostCard post={post} />` is a call with props
field `post` (192); `<style>` scoped by emilia. The `.bp` form (`return html """…""";`) compiles
identically; fronts 117–127 are built and tested on it.

## Fronts

All eleven **not started**.

| Front | Priority | State | What | Depends on (open) |
|---|---|---|---|---|
| [`118-bpp-components/`](./118-bpp-components/README.md) | **critical** — all markup goes through it | not started · ready to open | `{expr}` of any renderable type, rendering attributes, components with props, slots, fragments, markup in `if` / `case` / lambdas, `set:html`, `class:list`, `<style>` / `<script>` to sinks; jhonstart's `prelude.bp` and node type | — |
| [`121-bpp-content/`](./121-bpp-content/README.md) | **high** — largest new code | not started · steps 1–2 ready to open | New member `onze-content`: Markdown (CommonMark + GFM) to `Element`, frontmatter, collections with `Schema<T>`, `getCollection` / `getEntry` / `render`, `.md` pages, RSS | `08-f` (step 3) · 118, 117 (step 6) · `07-onze/53` (step 7) |
| [`120-bpp-islands/`](./120-bpp-islands/README.md) | **high** | not started | `#[clientIdle]` / `#[clientVisible]` / `#[clientMedia]` / `#[clientOnly]`; `#[serverDefer]` with fallback slot, sealed props | 118 · 119 · 117 · `05-jhonstart/26` · `04-rakun/22` · `07-onze/49`, `50` |
| [`117-bpp-routing/`](./117-bpp-routing/README.md) | high | not started | `.bpp` / `.md` / `.html` app files, `staticPaths` with data, `paginate`, partials, static endpoints, eight priority rules as tests | `03-bundled-libs/102` · `04-rakun/22` · `07-onze/49`, `50` · 121 steps 1–2 · `bpp-g` (step 1) |
| [`119-bpp-styling/`](./119-bpp-styling/README.md) | medium | not started · blocked by `08-d` | Scoped `<style>`, `#[isGlobal]`, `:global()`, `#[defineVars]`, cascade order | `08-d` (every step) · 118, `05-jhonstart/26` (step 2) |
| [`127-bpp-actions/`](./127-bpp-actions/README.md) | medium | not started | Action typed by a `#[schema]` record: JSON/form input, `ActionError`, typed client call | 125 step 6 · `03-bundled-libs/103` · `04-rakun/22` · `05-jhonstart/67` · `07-onze/49` · 117 · 120 · 126 · 123 (step 4) |
| [`122-bpp-data/`](./122-bpp-data/README.md) | medium | not started | `Astro` global mapped; holes: page-side status/headers, `rewrite`, `site` | `05-jhonstart/26` · `07-onze/49` · `03-bundled-libs/102` · 118 · 120 |
| [`123-bpp-middleware/`](./123-bpp-middleware/README.md) | medium | not started | `locals`, `sequence`, response rewritten after `next`, `actionContext` | `04-rakun/04` · `04-rakun/65` |
| [`126-bpp-view-transitions/`](./126-bpp-view-transitions/README.md) | low | not started | `#[transitionName]` / `#[transitionAnimate]` / `#[transitionPersist]`, `navigate`, five lifecycle events, route announcer | `05-jhonstart/27` · 118 · 120 |
| [`116-bpp-file-format/`](./116-bpp-file-format/README.md) | medium | not started | `.bpp` kind: `"bpp": "jhonstart"` in the app manifest; header between two `---` is botopink, rest the `html` literal; the package's prelude | 118 · `05-jhonstart/26` step 0 · `01-compiler/26` · `01-compiler`'s prelude scope · `bpp-g` (step 6) |
| [`124-bpp-cli/`](./124-bpp-cli/README.md) | high — last | not started · blocked by `08-h` | `onze sync`, `onze create-key`, config keys, component `<script>` bundling, built style sheet, `.bpp` scaffold | `08-h` · `07-onze/50`, `71` · every other front · `07-onze/53` (step 5) |

## Order

Waves (cross-track numbers: [`../fronts.md`](../fronts.md) § Execution order of tracks 03–08):

- **A** (after `00-gate` → 125 steps 0–2): 118 (alone in `html.bp`, in the core after 26 step 0;
  carve-outs before 34, 33, 26, 119 open — decision 189) · 121 steps 1–2 (alone, new member;
  step 3 on 08-f) · 119 step 1 (alone in `emilia/src/scoped.bp`, on 08-d).
- **B**: 123 ◄ `04-rakun/04` (core), `04-rakun/65` (rakun-web) · 117 ◄ `03-bundled-libs/102`,
  `04-rakun/22`, `07-onze/49`, `50` · 120 ◄ `05-jhonstart/26`, `07-onze/50` (lazy starters), 117
  (rakun-app) · 122 ◄ 26, 49, 120 (core) · 126 ◄ `05-jhonstart/27` (reconcile driver), 120
  (`html.bp`) · 119 step 2 · 121 steps 4–6 · 127 · 116 ◄ 118, 26, `01-compiler/26` (decisions
  198–200, 212, 213, 221, 270).
- **C**: 124 ◄ `07-onze/50`, every front above; 124 step 5 = second example app, the blog as
  `.bpp`, under 07-onze/53's acceptance script.

Why: **118 first** — tag annotations (`#[clientVisible]`, `#[serverDefer]`, `#[transitionName]`,
`#[defineVars]`, 278) need a parsing template; Markdown needs `Element` to splice; nothing needs `.bpp`.
**116 not first** — the compiler cannot lex HTML and emit jhonstart calls (`build.zig`'s
lib-agnostic check fails `zig build test` when `modules/compiler-core/src` names a library) and
need not: compiler-core gets `Module{path, source, declaration, srcPath}`, no extension. `.bpp`
needs one manifest key, the unfold, the prelude scope, the source-extension lists of four tools —
generic; every feature is testable without it. **124 last** — commands/keys over the others' work;
`07-onze/50` owns `onze dev`.

## Who else owns the files

Every front but 121 edits files owned by another track's front; sequenced, never together (`fronts.md`).

| This front edits | Also owned by | Sequence |
|---|---|---|
| `[name]={expr}` attributes outside `html.bp` — emilia's `attributes.bp`, `emilia.bp`, `examples/emilia-card`, the core's two files, `jhonstart-emilia`'s bridge test, `document-shell` (118 step 1) | `06-emilia/34`; `06-emilia/33`; `05-jhonstart/26`; 119 | named one-line carve-outs by 118, each landed before the owner opens (189) |
| `jhonstart/src/prelude.bp` (new, 118) | `05-jhonstart/26` | carve-out of 26's member, by 118 (270) |
| `jhonstart/src/{client.bp, render.bp, island_runtime.mjs}` (120) · `server.bp`, `error_boundary.bp` (122) | `05-jhonstart/26` | after 26; 120 then 122, one at a time on the member's `botopink.json`, `root.bp` |
| `jhonstart-link/**` — new files, plus two lines of `link_runtime.mjs` (126) | `05-jhonstart/27` | after 27 |
| `jhonstart-forms/src` — new `typed_call.bp` (127) | `05-jhonstart/67`, `03-bundled-libs/103` | after both |
| `jhonstart-dom-test` — a test file per front (119, 120, 126, 127); `fake_dom.mjs` (120's observers, 126's `startViewTransition` double) | `05-jhonstart/26` | each front owns its test file; `fake_dom.mjs` stays 26's, after 26 one front at a time — 120, then 126 (189) |
| `html.bp` (`jhonstart/src/html.bp` after 26 step 0) — one lowering arm each (119, 120, 126) | 118 | after 118; one at a time, that order |
| `onze-cli/src/scan.bp` (117) · `onze-cli/**`, `onze-bundler/**` (124) | `07-onze/50`, `03-bundled-libs/102` | after both |
| `onze/src/paginate.bp` (117) · `onze/src/config.bp` — `site` (122), other keys (124) (189) | `07-onze/49` | after 49 |
| `onze-server/src/server.bp` — island route, content boot step | `07-onze/49` | after 49 |
| `rakun-app/src/{static_gen,actions}.bp` (117, 127) · new `server_islands.bp` (120), `typed_action.bp` (127) | `04-rakun/22` | after 22; 117, 120, 127, one at a time on the member's `botopink.json`, `root.bp` |
| `rakun/src/locals.bp` (new) · `rakun-web/src/{middleware,filter}.bp` (123) | `04-rakun/04` (core) · `04-rakun/65` (rakun-web) | after 04 and 65 (189) |
| `libs/routing/src/{segment,conventions}.bp` (117) · `navigation.bp` (122) | `03-bundled-libs/102` | after 102 |
| `libs/actions/src/outcome.bp` (127) | `03-bundled-libs/103` | after 103 |
| `emilia/src/` — one new file (119) | `06-emilia/34` | beside it: 34 does not touch `scoped.bp` |
| `compiler-cli/**`, `language-server/**` (116) | `01-compiler/26-cli-tooling` | 116 opens after 26 |

## Handed to other tracks

Each a **wire** row of `surface.md`.

| Item | Where | Owner |
|---|---|---|
| Static attribute in `html """…"""` never reaches the rendered tree | `jhonstart-html/src/html.bp:138-146`, `:233-234` | 118 fixes it; reported because every DSL use is affected |
| `data-jh-on-click` written by the server, read by nothing | `jhonstart/modules/jhonstart/src/island_runtime.mjs` — one `addEventListener`, the refresh button (`:98`) | `05-jhonstart/26` (carries front 29) |
| `Metadata` rendered by jhonstart, onze passes `[]` | `onze-server/src/server.bp:116` | `07-onze/53` (ONZ-53-3) |
| `serveApp`, `serveActions`, `prerenderAll`, image route: in rakun and onze-assets, not called by `bootServer` | `onze-server/src/server.bp:212-221` | `07-onze/49` · `50` · `51` |
| Scan records a decorator's argument, never compares it with the file's directory | `onze-cli/src/scan.bp:36-56`, `:66-96` — read, not run | `07-onze/50`; 117 step 0 measures it |
| `io.http.fetch` is GET only | `libs/std/src/io/http.bp` | `02-std-and-packaging` (the row `03-bundled-libs/README.md` names) |
| `<Picture>`, `getImage`, remote patterns | `onze-assets` | `07-onze/51` |
| Lib-agnostic gate greps three of five names (`rakun\|jhonstart\|erika`); `onze`, `emilia` occur in compiler-core comments | `repository/botopink-lang/build.zig`; `codegen/erlang.zig` | `01-compiler/07-residuals` (step 8) |

## Rules in force

Labels only; text in [`../decisions-taken.md`](../decisions-taken.md).

| Decision | Rule | Fronts |
|---|---|---|
| 190 | Library decides `{expr}` types, located comptime error; compiler owes the means (`language-gaps.md` row); meanwhile raw text re-emitted through `build` | 118 step 2 |
| 191 | Hole accepts `string`; number/`bool` as `toString()`; same-base component (`Element`, base `ElementBase`); list of them; node type | 118 step 2 |
| 192 | Component attributes = fields of its first parameter's type; errors at the attribute | 118 steps 1, 4 |
| 193 · 223 | Children only via a `children: Node` props field (`Node` replaces `JhonstartNode`/`Children`); else error at the tag | 118 step 4 · `05-jhonstart` |
| 204 | `?T` hole refused | 118 step 2 |
| 207 | Inline props type `props: type(…)` | 118 · `01-compiler/01-checker` |
| 198 · 212 | `.bpp` = `.bp` module unfolded onto the `pub default fn` of the package in `"bpp": "<package>"`; header between two leading `---`, copied as written; rest is the literal; bad first line / unclosed header is an error at the line; no `template.emit` / `template.slice` | 116 |
| 199 | `type Props(…)` → `props: Props` parameter (none without it), never `pub val`; declarations (`import`, `type`, `pub`) stay module-level, statements (`val`, `use`) become the body before `return` | 116 · 118 · 120 |
| 213 | `pub default fn` named after the file (`components/PostCard.bpp` → `pub default fn PostCard(props: Props) -> Element`, `import {components.PostCard};`); non-function file name is an error | 116 · 118 |
| 200 | `html` = `pub default fn` of core `jhonstart` (`import html, {Element} from "jhonstart";`); `jhonstart-html` deleted; manifest `"bpp": "jhonstart"` | `05-jhonstart/26` step 0 · 116 · 118 |
| 221 · 285 | A `.bpp` decorator only when the header writes it (line before the closing `---`); a file's role (page, layout) is the framework's route table, never the toolchain's — it knows the `bpp` package, its `html` and its prelude only | 116 step 2 · 117 step 1 |
| 270 | `bpp` package's `src/prelude.bp` (own modules only) is the last scope; imported only when a name resolves through it; header wins; binding the default function's name is an error; 118 writes jhonstart's | 116 · 118 |
| 186 · 202 | Stage is comptime: `#[page]` prerenders unless it reaches a `#[serverOnly]` hook; no `prerender` export, no `output` key | 117 step 2 · 123 · 124 |
| 203 | One convention: `app/` tree, directory per route; `.bpp` where `page.bp` is; no `pages/` | 117 step 1 |
| 222 | Route handler (`route.bp`, every method) always server, never prerendered | 117 step 4 · 121 step 5 |
| 224 | Server-island props default **sealed** (AES-256-GCM in the URL; `ONZE_KEY` or build-generated, `onze create-key`); per project `onze.json` `"islands": {"props": "sealed"}` | 120 step 4 · 124 |
| 278 | Directives are tag annotations: `#[name(args)]` inside the tag, a function in scope, `html` acting on its return type; `#[clientOnly]` one function for hook and tag; values become values (§ Tag annotations) | 118 · 119 · 120 · 126 · `05-jhonstart/26` step 8 |
| 189 | Ordering and ownership (carve-outs, `fake_dom.mjs`, `site` by 122) | all |

No relative imports: same package `import {components.card.Card};`, a package `import {x} from "pkg";`; `.bpp` headers likewise.

## Tag annotations (278)

Every annotation this track creates. Each is a function, resolved in the caller's scope (the
`.bpp` prelude imports the core's; `jhonstart-link`'s are imported by name); `html` calls it at
comptime and acts on its **return type**; a tag carries its annotations as blocks or one list (286). First parameter: `comptime decl: @Decl` = component tags
only; `comptime tag: Tag` = any tag. One result of each type per tag.

| Annotation | Astro | First parameter · returns | Declared in | Front |
|---|---|---|---|---|
| `#[isRaw]` | `is:raw` | `Tag` · `RawBody` | `jhonstart/src/html.bp` | 118 step 5 |
| `#[isGlobal]` | `is:global` | `Tag` (`<style>`) · `StyleMode.Global` | `jhonstart/src/html.bp` (119's arm) | 119 step 2 |
| `#[isInline]` | `is:inline` | `Tag` (`<style>`, `<script>`) · `StyleMode.Inline` | `jhonstart/src/html.bp` (119's arm) | 119 step 2 · 124 |
| `#[defineVars(a, b)]` | `define:vars` | `Tag` (`<style>`) · `StyleVars` | `jhonstart/src/html.bp` (119's arm) | 119 step 2 |
| `#[clientLoad]` | `client:load` | `@Decl` · `Hydrate.Load` | `jhonstart/src/island_strategy.bp` | 120 step 1 |
| `#[clientIdle(timeoutMs)]` | `client:idle` | `@Decl` · `Hydrate.Idle` | `island_strategy.bp` | 120 step 1 |
| `#[clientVisible(rootMargin)]` | `client:visible` | `@Decl` · `Hydrate.Visible` | `island_strategy.bp` | 120 step 1 |
| `#[clientMedia(query)]` | `client:media` | `@Decl` · `Hydrate.Media` | `island_strategy.bp` | 120 step 1 |
| `#[clientOnly]` | `client:only` | `@Decl` · `Hydrate.Only` — also decision 186's hook marker, one function | `jhonstart/src/stage.bp` | `05-jhonstart/26` step 8 (marker) · 120 step 1 (return) |
| `#[serverDefer]` | `server:defer` | `@Decl` · `Defer` | `jhonstart/src/deferred.bp` | 120 step 4 |
| `#[transitionName(name)]` | `transition:name` | `Tag` · `TransitionName` | `jhonstart-link/src/transitions.bp` | 126 step 1 |
| `#[transitionAnimate(a)]` | `transition:animate` | `Tag` · `TransitionAnimate` | `transitions.bp` | 126 step 1 |
| `#[transitionPersist(key?)]` | `transition:persist` | `Tag` · `TransitionPersist` | `transitions.bp` | 126 step 1 |
| `#[transitionPersistProps]` | `transition:persist-props` | `Tag` · `TransitionPersistProps` | `transitions.bp` | 126 step 1 |

Not annotations — values: `set:html={s}` → `{raw(s)}`; `set:text={s}` → `{s}`; `class:list={[…]}` →
`class={classList([…])}` (`classList` new in the core, 118 step 5). The arm for each return type is
appended to `html.bp` by the front in the last column, in 118 → 119 → 120 → 126 order. Compiler
needs (no new row): annotation arguments are embedded expressions — the `language-gaps.md` row 118
step 2 owns.

## Decisions the maintainer owes

Open: `08-d`, `08-f`, `08-h` (below) and `08-j`, `bpp-g`, `props-d`, `props-e`,
`props-f` ([`../decisions-pending.md`](../decisions-pending.md)); contradictions `ctr-f`, `ctr-g`, `ctr-t` (116).

- `08-j` — how rakun's `local()` carries jhonstart's `#[serverOnly]`. Blocks 123 step 1's third box.
- `bpp-g` — how a `page.bpp` gets `route: PageContext` and `params`. Blocks 116 step 6, 117 step 1.
- `props-d` · `props-e` · `props-f` — native tag attributes, named slot, spread on a component. Block 118 steps 1, 4.

### 08-d · Who scopes CSS

**Measured.** emilia compiles `Token[]`, "not a runtime CSS engine. No selector parsing"
(`emilia/AGENTS.md:602`); onze-assets renames `*.module.css` classes (`onze-assets/src/style_module.bp`); decision 113.
**Options.** (a) emilia `scopeCss(scope, css)` via the `jhonstart-emilia` bridge; (b) onze-assets,
beside the module renamer; (c) jhonstart's `html` scopes its own `<style>`.
**Recommendation.** (a). (c) puts a CSS parser in the HTML library; (b) excludes jhonstart apps without onze.
**Blocks.** All of 119.

### 08-f · Where Markdown and YAML live

**Measured.** No Markdown code. One YAML-subset reader, rakun's config
(`rakun/modules/rakun/src/config.bp:340`); `03-bundled-libs/README.md` § "What does not move":
config readers go to std "when a second consumer appears".
**Options.** (a) both in new member `onze-content`; (b) Markdown in `onze-content`, YAML in std as
`yaml` (97's tree), rakun's reader deleted by rakun's front; (c) a bundled `markdown` package.
**Recommendation.** (b). Frontmatter is that second consumer; Markdown has one, so decision 115's
"two or more libraries" makes no package. Until std's `yaml`, 121 step 3 keeps its own copy, deleted on landing.
**Blocks.** 121 step 3 (frontmatter); under (c), where steps 1–2 live; a row for `02-std-and-packaging/97`.

### 08-h · The config file and the commands

**Measured.** `onze.json` refuses unknown keys (49-c); `onze create | info | build | start` exist,
`dev` a stub (`onze-cli/src/main.bp`); `botopink` has no framework command (`compiler-cli/src/main.zig`).
**Options.** (a) `onze.json` and `onze <command>`; (b) `bpp.json` and `botopink dev` / `preview`.
**Recommendation.** (a); (b) makes the compiler's CLI a framework's.
**Blocks.** 124.

## Rules for this track

- **The compiler knows no library.** Only 116 edits `repository/botopink-lang`: a manifest key,
  `.bpp` in the tools' lists, the unfold (198), the prelude as generic last scope (270) — no
  library name, no syntax. Markup meaning is jhonstart's `html`.
- **A library front never touches `modules/**`.** A need = a [`language-gaps.md`](../language-gaps.md) row + nearest form.
- **Libraries keep their concerns** (113): template jhonstart, CSS emilia, request/route table rakun, wiring onze. No fifth library.
- **Most restrictive, no bypass** (67): an unbound annotation is the unbound-name error at its
  span, a written `prefix:name` directive an error naming the annotation; a `Hydrate` annotation on
  a non-`#[client]` component does not build.
- **Astro's directives are annotations or values** (278): an instruction is `#[preName(…)]` inside
  the tag — the Astro name joined (`client:visible` → `#[clientVisible]`) —, a value an ordinary
  attribute or hole (`set:html` → `{raw(…)}`, `class:list` → `class={classList(…)}`). Other Astro
  names kept where the stack has none, **replaced where it has one**: no `Astro` global — parameters,
  hooks, navigation signals ([`122-bpp-data/`](./122-bpp-data/README.md) is the table).
- **Examples are code.** `examples/` holds each step's target; on landing it moves into the
  member's tests or `examples/` and must compile. An `-example.bp` is one compilable unit with its
  tests. Page/layout/component code also sits under `examples/src/` as an app's `.bpp` tree (name
  and directory carry meaning), compiling when 116 lands (116 step 6). `05-jhonstart` and
  `07-onze/53` examples holding a page, layout or component carry the `.bpp` form too; `04-rakun`
  and `06-emilia` none (services, token tests — no markup).
- **`status.md` is the only file that carries status.**

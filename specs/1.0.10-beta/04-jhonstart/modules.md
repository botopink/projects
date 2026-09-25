# Track C — jhonstart · modules

**Repo:** `repository/jhonstart` · **Pattern:** front 95 (`../02-packaging/95-ecosystem-package-restructure/README.md`) — `modules/<name>/`, `modules/<name>-test/`, `modules/<name>-<domain>/`, `examples/**` · **Fronts delivering into it:** 26 · 27 · 28 · 29 · 30 · 31 · 32 · 67 · 94 · **Cross-track files landing here:** front 48's `html_attrs.bp` (emilia track)

## 0 · Where the tree is

Fronts 94, 26, 28 and 27 have landed. Three facts about the tree that the cut below has to be read
against:

- **(a) The submodule split has not happened.** `repository/jhonstart/` has exactly **one** member,
  `modules/jhonstart/`. `html.bp` — which § 6 assigns to `jhonstart-html` — is in core, and so are
  front 27's `link.bp` and `reconcile.bp`. The cut below is a plan, not a description; whoever
  performs it does so as its own front, and until then every front reads "core".
- **(b) § 4's `jhonstart-link` row is unsettled.** A member cannot declare `["commonJS", "erlang"]`
  *and* carry four `#[@External.Node]` cells that anything on the erlang row calls: a foreign cell
  that is **called** reds the other target's compile at the caller's body (`` `__cellStatus` has no
  `#[@External.<Target>(…)]` for the erlang backend ``), while the same cell declared and never
  called compiles clean. Front 27 ships the **pure** half — `link.bp` and `reconcile.bp` reach no
  host cell and all 35 assertions run on both rows — and leaves the four cells to front 68. When they
  arrive they must be dual-target, or live behind a wrapper nothing on erlang calls, or sit in a
  commonJS-only member; the row has to choose one and say which.
- **(c) `root.bp` and `botopink.json` are edited by the front that adds the module**, in its own
  commit — the package's `AGENTS.md` records the convention. A hand-off to front 94 would leave an
  intermediate state that does not build.

## 1 · The cut

```
repository/jhonstart/
├── botopink.json                      workspace manifest → modules/
├── modules/
│   ├── jhonstart/                     CORE — the app model and front 30's render      target: both
│   ├── jhonstart-html/                the `html """…"""` DSL + the attribute slot       target: both (comptime)
│   ├── jhonstart-link/                client navigation: Link, prefetch, reconciler    target: js (renders on both)
│   ├── jhonstart-forms/               form binding, action state, optimistic, <Form>   target: js (renders on both)
│   ├── jhonstart-emilia/              the bridge: RenderPlugin over emilia's flush()   target: both (as core)
│   └── jhonstart-test/                render/stream/route harness + assert<Subject>    target: both (dev)
└── examples/                          § 7
```

One criterion decides core versus submodule, and it is checkable by grep: **core is what front 30's render reaches.** The render (`render.bp`) calls `isVoidTag`/`isRawTextTag` (94), `Boundary`/`Suspense`/`resolve`/`fillHtml` (30), `renderBoundaryChecked`/`isSignal` (31), `islandAttr`/`islandEntry` (29), `renderHead`/`mergeMetadata` (32), `RouterState` (26) and `request()` (28); everything it reaches is core. `Link`, `reconcile`, `formAttrs`, `actionState` are reached only by application components and by onze front 68's generated entry — they are submodules. The bridge `jhonstart-emilia` is a submodule for the other admissible reason: it is the one member with a dependency (emilia) core must not have. No rakun module imports jhonstart and jhonstart imports no rakun module (decision 113); onze hands the route data in.

### 1.1 File placement

| Submodule | `src/` | From front | Frozen? |
|---|---|---|---|
| `jhonstart` | `element.bp` | — (v0) | yes |
| `jhonstart` | `elements.bp` | 94 | — |
| `jhonstart` | `hooks.bp` | — (v0) | yes |
| `jhonstart` | `router.bp` (replaces `router.d.bp`) | 26 | — |
| `jhonstart` | `server.bp` (replaces `server.d.bp`) | 28 | — |
| `jhonstart` | `client.bp` | 29 | — |
| `jhonstart` | `suspense.bp`, `streaming.bp`, `render.bp`, `plugin.bp`, `globals.bp`, `render.mjs` | 30 | — |
| `jhonstart` | `error_boundary.bp` | 31 | — |
| `jhonstart` | `metadata.bp` | 32 | — |
| `jhonstart-html` | `html.bp` | — (v0) | yes (one import line changes at the move, § 1.3) |
| `jhonstart-html` | `html_attrs.bp` | 48 (track D) | — |
| `jhonstart-link` | `link.bp`, `reconcile.bp` | 27 | — |
| `jhonstart-forms` | `form.bp`, `form_state.bp` | 67 | — |
| `jhonstart-emilia` | `root.bp` (`plugin()`) | 30 | — |
| `jhonstart-test` | one `assert_<subject>.bp` per front + `harness.bp` | all nine (§ 5) | — |

`root.bp` of each submodule lists its `pub mod` lines in front-number order; the front that adds a module appends its own line and its `files` entry in its own commit (§ 0 (c)).

### 1.2 The merged `modules/jhonstart/src/root.bp`

```bp
pub mod element;
pub mod hooks;
pub mod router;          // front 26
pub mod server;          // front 28
pub mod client;          // front 29
pub mod suspense;        // front 30
pub mod streaming;       // front 30
pub mod render;          // front 30
pub mod plugin;          // front 30
pub mod globals;         // front 30
pub mod error_boundary;  // front 31
pub mod metadata;        // front 32
pub mod elements;        // front 94
```

`html` leaves this list (§ 1.3). `router.d.bp` and `server.d.bp` leave `botopink.json`'s `files` when fronts 26 and 28 land, as their READMEs already require.

### 1.3 Cross-submodule imports — the only edits the move causes

| File | Today | After the move | Why |
|---|---|---|---|
| `html.bp:92` | `import {Element} from "element";` | `import {Element} from "jhonstart";` | `element` is no longer a sibling module; `html.bp` is frozen for content, and this is the one line the relocation touches — the same allowance front 95 makes for `html_test.bp` |
| `html_attrs.bp` (48) | "imports only `element`" | `import {Element} from "jhonstart";` | same |
| `link.bp`, `reconcile.bp` (27) | `import {Element} from "element";` | `import {Element, RouterState} from "jhonstart";` | 27 reads `RouterState.segments()` for `layoutKeys` |
| `form.bp`, `form_state.bp` (67) | `from "element"` | `import {Element, push, form, input, …} from "jhonstart"; import {prefetch} from "jhonstart-link";` | 67 depends on 26 (`push`), 27 (prefetch), 94 (constructors) |

Every other `import {…} from "<sibling>"` in the fronts' step code stays a sibling import because both files land in the same submodule (`server.bp` ← `router`'s `pairValue`; `streaming.bp` ← `suspense`'s `Boundary`).

### 1.4 Consumer import map

The fronts and their examples write `import {…} from "jhonstart"` for every symbol. Under this cut that line resolves for core symbols; the two submodules are imported by name. This table is what an implementer applies when the file is created in `repository/jhonstart/examples/**` or `modules/*/test/**`.

| Symbol group | Import |
|---|---|
| `Element`, `text`, `div`, … (v0 eight) · `nav`, `form`, `input`, `htmlTag`, `el`, `isVoidTag`, … (94) · `state`/`memo`/… (hooks) | `from "jhonstart"` |
| `RouterState`, `router`, `pathname`, `params`, `searchParams`, `selectedLayoutSegment(s)`, `push`, `replace`, `back`, `forward`, `refresh`, `prefetch`, `pairValue`, `snapshot` (26) | `from "jhonstart"` |
| `RequestData`, `request`, `cookies`, `headers`, `renderServerComponent` (28) | `from "jhonstart"` |
| `client`, `clientProps`, `Island`, `clientMount`, `serverSlot`, `islandEntry`, `hydrate`, `propsFor`, `serverOnly` (29) | `from "jhonstart"` |
| `Boundary`, `Suspense`, `holeId`, `Chunk`, `resolve`, `fillHtml`, `shellHtml`, `renderNode`, `raw`, `Segment`, `compose`, `Payload`, `writePayload`, `RenderHooks`, `defaultHooks`, `setHooks`, `App`, `app`, `PageInput`, `render`, `renderStream`, `RenderPlugin`, `globals`, `readPayload`, `registerFill` (30) | `from "jhonstart"` |
| `plugin` (30, the bridge) | `from "jhonstart-emilia"` |
| `ErrorInfo`, `ErrorBoundary`, `renderBoundary`, `renderBoundaryChecked`, `catchError`, `infoFor`, `serverInfoFor`, `digestOf`, `isSignal`, `notFound`, `wrap` (31) | `from "jhonstart"` |
| `Metadata`, `OpenGraph`, `TwitterCard`, `Icons`, `Viewport`, `emptyMetadata`, `emptyOpenGraph`, `mergeMetadata`, `mergeViewport`, `renderHead`, `renderViewport`, `pick`, `pickList`, `applyTemplate` (32) | `from "jhonstart"` |
| `html` (DSL) · `html_attrs` surface (48) | `from "jhonstart-html"` |
| `Link`, `LinkProps`, `linkProps`, `withPrefetch`/`withReplace`/`withScroll`/`withTarget`/`withClass`, `prefetchMode`, `layoutKey`, `layoutKeys`, `sharedDepth`, `reconcile`, `LinkStatus`, `linkStatus`, `linkMount`, `__jhLinkPrefetch` (27) | `from "jhonstart-link"` |
| `ActionState`, `newActionState`, `parseActionState`, `FormBinding`, `formAction`, `formAttrs`, `hiddenActionField`, `actionState`, `FormStatus`, `formStatus`, `optimistic`, `applyOptimistic`, `SearchFormProps`, `searchFormProps`, `searchFormAttrs`, `formMount` (67) | `from "jhonstart-forms"` |
| `assertHtml`, `assertStream`, … (§ 5) | `from "jhonstart-test"` (dev) |

## 2 · Candidate verdicts

The starting proposal was one submodule per front name. Each candidate against front 95's two admissible reasons — *a consumer wants this part without the rest* or *a different target profile* — plus dependency direction and which fronts deliver into it.

| Candidate | Verdict | Reason |
|---|---|---|
| `jhonstart` (core) | **keep** | Holds front 30's render and every module it renders through. Eight fronts deliver into it (26 · 28 · 29 · 30 · 31 · 32 · 94 + frozen v0). Target both: every module renders on erlang (server pass) and re-renders on js. |
| `jhonstart-html` | **keep, narrowed** | Front 95's split stands — the DSL is comptime template evaluation a builder-only consumer never invokes, and every 26–32/67 example is builder-only, which proves the consumer exists. Narrowed: 95's parenthetical "(the html DSL **and element constructors**)" predates front 94, which decided constructors are imported `from "jhonstart"` and must be indistinguishable from `element.bp`'s eight. Constructors stay in core; this submodule is `html.bp` + 48's `html_attrs.bp`. Depends on core (`Element`); nothing in core depends on it — the DSL resolves tags in the *caller's* scope. |
| `jhonstart-router` | **merge into core** | `router.bp` owns `pairValue`, imported by 28 and 32 (`language-gaps.md` assigns it to 26); `RouterState` is filled by the server render and read by every layout. A domain submodule the core imports inverts the dependency direction. Front 26 is erlang, wave 1 — it is the foundation, not a domain. |
| `jhonstart-link` | **keep** | Front 27 alone: `link.bp` + `reconcile.bp`. js target — its four cells are `#[@External.Node]` with no erlang twin; nothing in core or in front 30's render imports it; a statically generated site (front 60) or a no-bundle server render ships without it. Depends on core (26's `RouterState.segments()`, 94's `a`). The pure `Link` render still runs on erlang, which is why the submodule's manifest declares both targets and its gate is commonJS. |
| `jhonstart-server` | **merge into core** | `server.bp` binds front 62's request context — the server render itself. A core without it has nothing to render. |
| `jhonstart-client` (29) | **merge into core** | `Island`, `clientMount`, `islandEntry`, `serverSlot` are called by front 30's render during the BEAM pass to build the payload's `i` rows; `#[client]`/`#[clientProps]` are applied in component files that are server-rendered. The one browser cell, `hydrate()`, is the per-island entry point front 68's generated module imports — one import from core. Splitting 29 would make the server pipeline depend on a submodule named "client". |
| `jhonstart-streaming` | **merge into core** | `Suspense`/`resolve`/`fillHtml`/`shellHtml` are the flush contract of front 30's render, which lives beside them; erlang, with `render.mjs` as the browser half. |
| `jhonstart-errors` | **merge into core** | `renderBoundaryChecked` is what front 30's `compose` calls around every segment; `isSignal` is front 63's discriminator; `global-error.bp` needs 94's `htmlTag`/`body`, both core. |
| `jhonstart-metadata` | **merge into core** | `renderHead`/`mergeMetadata` run inside front 30's document build; imports `pairValue` (core) and std `escape`. |
| `jhonstart-forms` | **keep** | Front 67 alone: `form.bp` + `form_state.bp`. js target; the deepest front in the track; the only jhonstart code pinned to a **rakun** contract literal (front 24's envelope and golden `state` fixture). A read-only site ships without it. Depends on core (`push`, `form`/`input`/`button`/`label`) and on `jhonstart-link` (`__jhLinkPrefetch` for the GET `<Form>`). Nothing depends on it. |
| `jhonstart-elements` (94) | **merge into core** | Front 94's own acceptance: "a reader cannot tell from a call site whether a tag came from `element.bp` or from `elements.bp`", and `isVoidTag`/`isRawTextTag` are consumed by front 30's `renderNode`. |
| `jhonstart-emilia` | **keep** (new) | Decision 113's bridge: `plugin()` implements front 30's `RenderPlugin` over emilia's `flush()`. A submodule because it is the one member that depends on emilia — core must not (a consumer without emilia ships without it), and emilia imports nobody. Owned by front 30. Its test is where the contract-4 class literal meets the rendered document on the jhonstart side, since core cannot import emilia. |
| `jhonstart-hooks` | **drop** | Frozen `hooks.bp`, imports `Element`, one file — front 95's "would produce submodules with one file each". |
| `jhonstart-test` | **keep** | Mandatory by the pattern. § 5. |

Net: **six directories** — core, `-html`, `-link`, `-forms`, `-emilia`, `-test`.

## 3 · Dependency graph

```
                    std (01 escape · 02 async · 03 hash · querystring · testing.asserts · testing.snapshots)
                     │
                     ▼
              ┌── jhonstart ──────────────────────────────────────────────────────────┐
              │   element · elements(94) · hooks · router(26) · server(28)             │
              │   client(29) · suspense/streaming/render/plugin/globals(30)            │
              │   error_boundary(31) · metadata(32)                                    │
              └───────┬──────────────────┬───────────────────────┬──────────────────────┘
                      │                  │                       │
                      ▼                  ▼                       ▼
             jhonstart-html      jhonstart-link (27)     jhonstart-emilia (30) ──► emilia
             html · html_attrs(48)        │               (RenderPlugin over flush())
                                          ▼
                                 jhonstart-forms (67) ◄── contract literal only (24's envelope)
                                          │
                                          ▼
                              jhonstart-test  ◄── depends on core, -html, -link, -forms + std testing.asserts + testing.snapshots
                                          │
                                          ▼
                                 onze (49 boot · 68 entry · 53 example app) ──► rakun
```

Edges are `botopink.json` dependencies. Three facts the graph encodes:

- **jhonstart and rakun never import each other; onze is the only package that names both** (decision 113). The route data, the matcher (front 26's `match`), the action ids (front 67) and the chunk writer reach jhonstart as values onze hands in. `server.bp` binds `rakun_request_context` by `#[@External.Erlang]` module name — a host-module string, not a package import — so jhonstart's manifest lists no rakun dependency. A page's `notFound()` is jhonstart's own (front 31), translated by onze into rakun's 404.
- **emilia enters through the bridge only.** `jhonstart-emilia` is the one member that imports emilia; core and every other member know only `RenderPlugin`, and front 30's gate asserts that the string `emilia` appears nowhere under `modules/jhonstart/`. Front 48 owns `html_attrs.bp` inside this repo, emilia-unaware plumbing; emilia's `html_hook.bp` imports no jhonstart module (`styled`/`cls` return plain pairs and strings).
- **Front 68's generated entry** imports `hydrate`, `readPayload`, `registerFill` and `globals` from core, `linkMount` from `jhonstart-link`, `formMount` from `jhonstart-forms` — ordinary imports, one call each; the only browser globals are the two `globals.bp` aliases (`__bp0`, `__bp1`).

## 4 · Target of each submodule

| Submodule | `targets` in manifest | Gate (`zig build test-libs -- --lib jhonstart`) | Why both are declared |
|---|---|---|---|
| `jhonstart` | `["erlang", "commonJS"]` | **both** — 94's constructors must produce the identical `Element` on both; 26/28/30/31/32 assert on erlang; 29's markers assert on both | the server pass renders every module; front 68 re-renders the same code in the browser |
| `jhonstart-html` | `["erlang", "commonJS"]` | both — the DSL is comptime; its output is a builder pipeline that runs wherever the builders do | same |
| `jhonstart-link` | **unsettled — see the amendment at the top** | the pure half (`link.bp`, `reconcile.bp`) gates on **both**, as landed: 35 assertions, no host cell reached. The four `#[@External.Node]` cells are front 68's and cannot join a member that declares erlang unless nothing on that row calls them | `Link` is pure and is rendered by the server — which is exactly why the pure half and the cells cannot share one `targets` array without a decision |
| `jhonstart-forms` | `["commonJS", "erlang"]` | **commonJS** — `form_state_test.bp` would pass on erlang and is deliberately not claimed there | `formAttrs`/`hiddenActionField` render in the server pass — the progressive-enhancement markup |
| `jhonstart-emilia` | `["erlang", "commonJS"]` | **both** — the plugin runs wherever front 30's render does | the render runs on erlang; the manifest matches core's so the bridge never narrows it |
| `jhonstart-test` | `["erlang", "commonJS"]` | runs under whichever target the consuming suite runs | helpers are pure over strings |

Host cells by submodule — the rule the manifests encode: core carries `#[@External.Erlang]` cells (26's five, 28's six) plus the `#[@External.Node]` cells 26 (dual-target `__jhNavigate`), 29 (`hydrate`/`__jhClientPropsRaw`) and 30 (`readPayload`/`registerFill`, called only from onze's generated entry) declare; `-link` and `-forms` carry `#[@External.Node]` only and **no** `#[@External.Erlang]` cell, asserted by grep in each submodule's gate.

## 5 · `jhonstart-test`

Depends on: `std` (`import {testing: {asserts, snapshots}, querystring} from "std"` — decisions 106/107; only the leaves enter scope, so `asserts.equal` and `snapshots.match` are spelled as before), `jhonstart`, `jhonstart-html`, `jhonstart-link`, `jhonstart-forms`. Every helper is `pub fn assert<Subject>(loc: SourceLocation, …) -> @Result<void, string>`; each renders its subject to a deterministic string and hands it to `snapshots.match(loc, text)` (`../../01-std/snapshots.md`). Exact signatures and the text each one produces are in [`test-snap.md § 0`](./test-snap.md).

| File | Exposes | Filled by front |
|---|---|---|
| `harness.bp` | `renderToString` re-export · `renderToStream(shell: Element, boundaries: Array<Boundary>) -> @Future<Array<string>>` — shell then fills in **declaration** order (a test harness has no scheduler; front 30's completion order is its own test) · `simulateNavigation(from: RouterState, to: RouterState) -> Navigation` — the pure reconciler decision (`layoutKeys`, `sharedDepth`, remounted depth) · `fixtureRouter(path, pattern, params, search) -> RouterState` · `fixtureRequest(…) -> RequestData` · `stubEnvelope(ok, state, redirect) -> string` | 94 (harness skeleton), 26, 27, 28, 67 |
| `assert_html.bp` | `assertHtml(loc, e: Element)` — `renderToString(e)`, one line | 94 |
| `assert_route.bp` | `assertRoute(loc, r: RouterState)` · `assertActiveLink(loc, nav: Element, path: string)` — the anchors of `nav` with an `active` marker | 26 |
| `assert_link.bp` | `assertLink(loc, l: Element)` · `assertNavigation(loc, n: Navigation)` | 27 |
| `assert_server.bp` | `assertRequest(loc, r: RequestData)` — a server component is snapshotted by `val tree = await Page(params); try assertHtml(@src(), tree);` (`await` is legal in a `test` block; a future-returning helper would put `try` on the wrong side of `await`) | 28 |
| `assert_island.bp` | `assertClientBundleEntry(loc, islands: Array<Island>)` — the payload `i` rows plus each placeholder | 29 |
| `assert_stream.bp` | `assertStream(loc, chunks: Array<string>)` — one chunk per block, in order | 30 |
| `assert_render.bp` | `assertDocument(loc, doc: string)` — the document front 30's `render` produced, one line per chunk · `assertPayload(loc, p: Payload)` — `writePayload(p)` | 30 |
| `assert_error_boundary.bp` | `assertErrorBoundary(loc, b: ErrorBoundary)` — the `renderBoundaryChecked` outcome tagged `ok`/`error` | 31 |
| `assert_metadata.bp` | `assertMetadata(loc, m: Metadata)` · `assertViewport(loc, v: Viewport)` | 32 |
| `assert_form.bp` | `assertForm(loc, f: Element)` · `assertActionState(loc, s: ActionState)` · `assertOptimistic(loc, base: i32, actions: i32[])` | 67 |

Rules carried from front 95 § 5: import std's `testing.asserts`, never re-implement `equal`; expose fixtures (`fixtureRouter`, `fixtureRequest`, `stubEnvelope`), not only assertions; `#[mock]` pairing is documented in the submodule README, and the host runtime behind it lives in the first `-test` submodule that needs it (rakun's, not this one).

## 6 · Front → directory ownership

One source directory per front. The `jhonstart-test` column is the helper file each front also adds; it is not a second owner of the front's source.

| Front | Source dir | Files | Adds to `jhonstart-test` | Gate target |
|---|---|---|---|---|
| **94** element-surface | `modules/jhonstart/src/` | `elements.bp`, `root.bp`, `botopink.json` | `harness.bp`, `assert_html.bp` | both |
| **26** router | `modules/jhonstart/src/` | `router.bp` (− `router.d.bp`) | `assert_route.bp`, `fixtureRouter` | erlang |
| **28** server-components | `modules/jhonstart/src/` | `server.bp` (− `server.d.bp`) | `assert_server.bp`, `fixtureRequest` | erlang |
| **27** link | `modules/jhonstart-link/src/` | `link.bp`, `reconcile.bp`, `root.bp`, `botopink.json` | `assert_link.bp`, `simulateNavigation` | commonJS |
| **29** client-directive | `modules/jhonstart/src/` | `client.bp` | `assert_island.bp` | commonJS |
| **30** render and streaming | `modules/jhonstart/src/` · `modules/jhonstart-emilia/` | `suspense.bp`, `streaming.bp`, `render.bp`, `plugin.bp`, `globals.bp`, `render.mjs` · the bridge's `botopink.json`, `src/root.bp`, `test/` | `assert_stream.bp`, `assert_render.bp`, `renderToStream` | both |
| **31** error-boundaries | `modules/jhonstart/src/` | `error_boundary.bp` | `assert_error_boundary.bp` | erlang |
| **32** metadata | `modules/jhonstart/src/` | `metadata.bp` | `assert_metadata.bp` | erlang |
| **67** forms | `modules/jhonstart-forms/src/` | `form.bp`, `form_state.bp`, `root.bp`, `botopink.json` | `assert_form.bp`, `stubEnvelope` | commonJS |
| *48 (track D)* | `modules/jhonstart-html/src/` | `html_attrs.bp` | — (tested from emilia) | both |
| *— (v0, frozen)* | `modules/jhonstart/src/` · `modules/jhonstart-html/src/` | `element.bp`, `hooks.bp` · `html.bp` | — | both |

Tests: each front's `test/<name>_test.bp` moves with its source into the same submodule's `test/`, and its `__snapshots__/` sits beside it. `test/html_test.bp` and 94's `test/elements_test.bp` live in `modules/jhonstart-html/test/` — both are consumer-position DSL resolution tests.

## 7 · Relations to the other tracks

| Track | Front | Relation | What crosses |
|---|---|---|---|
| emilia (D) | **48** attributes | 48 owns `modules/jhonstart-html/src/html_attrs.bp` — the only cross-repo file. jhonstart stays emilia-unaware; `[class]={expr}` reaches `attrs` (`html.bp:234-241`) and emilia's `html_hook.bp` produces the class string without importing jhonstart. | a `#("class", "e_<hex>")` pair, nothing else |
| emilia (D) | **56** cascade-and-output | `flush()` is what the `jhonstart-emilia` bridge (front 30) calls from `RenderPlugin.head` / `chunk`; emilia does not change for it and imports nobody. The bridge's test asserts contract 4's class literal on the jhonstart side. | the `<style>` string `flush()` returns |
| rakun (B) | **23** ssr-pipeline | Imports nothing from jhonstart. It matches the route, opens the request scope and writes the chunks front 30's `renderStream` hands its writer — both ends wired by onze. | the chunk strings; the render outcome (`""` or a signal reason) that onze turns into a status |
| rakun (B) | **24** server-actions | Owns the action id and envelope that `jhonstart-forms` carries and decodes; builds no markup — the form is 67's, and the id reaches it through onze. | the golden `state` fixture, asserted verbatim on both sides |
| rakun (B) | **22** file-routing · **62** request-context · **63** navigation-signals · **66** metadata-file-routes | 22 discovers `loading.bp`/`error.bp`/`not-found.bp`/`global-error.bp` and owns the matcher onze hands 26 as `match`; 62 is the erlang module `server.bp` binds; 63's `jhonstart:` reasons are the ones `isSignal` and 31's own `notFound()` spell (a contract literal, `contracts.md § 5b`); 66 serves the paths `openGraph.images` names. | route table `t`; `k=v&k=v` strings; the signal prefix; image paths |
| onze (E) | **49** stand-up | Boots the app: `app(plugins: [emiliaPlugin()])`, fills `RenderHooks`, hands front 22's matcher and rakun's chunk writer to front 30's render. | the plugin list; `PageInput`; the writer |
| onze (E) | **68** client-bundle | Generates the entry that calls `registerFill(globals.fill, …)`, `hydrate()`, `linkMount()`, `formMount()`; enforces 29's boundary rules over the module graph. | `__jhClient_<Name>` markers; the `server-only` import predicate |
| onze (E) | **53** example-app | The first place a browser is in the loop; imports every symbol in § 1.4. | — |
| std (A) | **01** · **02** · **03** | `escape.html`/`escape.attribute` (28, 32); `async` spawn/gather over thunks (30); `hash.contentHash` (31). | — |

## 8 · `repository/jhonstart/examples/**`

Existing: `jhonstart-counter/`, `jhonstart-html/`, `jhonstart-todo/` (v0, pure client, stay as-is); `jhonstart-app/` (gated/aspirational, superseded by `blog-ssr` below and removed when it lands). New projects, one per consumer shape, each with `botopink.json`, `src/`, `test/` and its own `__snapshots__/`:

| Project | Shape | Fronts exercised | Depends on | Target |
|---|---|---|---|---|
| `examples/blog-ssr/` | the server-rendered blog: root layout, `/blog/[slug]` page with two sequential loaders, `loading.bp`, `error.bp`, `not-found.bp`, `global-error.bp`, static + dynamic metadata, viewport | 26 · 28 · 30 · 31 · 32 · 94 | `jhonstart`, `jhonstart-test`, `std` | erlang |
| `examples/nav-shell/` | a docs shell: sidebar with active-segment highlighting, prefetch policy per route kind, pending checkout link, shared-layout reuse across a transition | 26 · 27 · 94 | `jhonstart`, `jhonstart-link`, `jhonstart-test` | both (link gate commonJS) |
| `examples/islands/` | a like-button island per post, a theme provider wrapping server children, the payload `i` rows | 28 · 29 · 94 | `jhonstart`, `jhonstart-test` | both |
| `examples/forms/` | create-post form with per-field message, optimistic like with nested `formStatus` button, GET search `<Form>` | 67 · 29 · 26 · 27 · 94 | `jhonstart`, `jhonstart-link`, `jhonstart-forms`, `jhonstart-test`, `std` | commonJS |
| `examples/document-shell/` | `htmlTag`/`head`/`body` document built once with constructors and once with `html """…"""` over the same tags; void-element and `main` caveats as literals | 94 · (DSL) | `jhonstart`, `jhonstart-html`, `jhonstart-test` | both |

Every `.bp` under `examples/**` and every `.snap` it produces is mapped in [`test-snap-examples.md`](./test-snap-examples.md).

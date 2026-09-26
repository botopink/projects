# Track C — jhonstart · modules

**Repo:** `repository/jhonstart` · **Pattern:** front 95 (`../02-packaging/95-ecosystem-package-restructure/README.md`) — `modules/<name>/`, `modules/<name>-test/`, `modules/<name>-<domain>/`, `examples/**` · **Fronts delivering into it:** 26 · 27 · 28 · 29 · 30 · 31 · 32 · 67 · 94 · **Cross-track files landing here:** front 48's `html_attrs.bp` (emilia track)

## 0 · Where the tree is

The six members of § 1 exist. What is still to be written into them:

- **`jhonstart-test` is empty** — `src/root.bp` holds one inline test proving the core resolves from
  the member. The helpers of § 5 are owed by the fronts in its *Filled by* column.
- **The example projects of § 8 do not exist yet**; `examples/jhonstart-app/` is still the
  manifest-less aspirational sketch.
- **`jhonstart-link` / core browser cells are dual-target** (§ 4) — the choice is implemented and
  awaits confirmation in `../decisions-pending.md` 27-a.

`root.bp` and `botopink.json` are edited by the front that adds the module, in its own commit (the
package's `AGENTS.md` records the convention).

## 1 · The cut

```
repository/jhonstart/
├── botopink.json                      WORKSPACE: targets [commonJS, erlang], workspaces [modules/*, examples/*]
├── modules/
│   ├── jhonstart/                     CORE — the app model and front 30's render
│   ├── jhonstart-html/                the `html """…"""` DSL (comptime)
│   ├── jhonstart-link/                client navigation: Link, prefetch, remount decision, browser cells
│   ├── jhonstart-forms/               form binding, action state, optimistic, the GET search form
│   ├── jhonstart-emilia/              the bridge: RenderPlugin over emilia's flush(), payload `s`
│   └── jhonstart-test/                render/stream/route harness + assert<Subject>   (dev)
├── examples/                          § 8
├── refusals/                          one project per compile-time refusal of the library (not members)
└── repro/                             jhonstart-free compiler repros (not members)
```

Every member declares no `targets` and inherits the workspace's two.

One criterion decides core versus submodule, and it is checkable by grep: **core is what front 30's render reaches.** The render (`render.bp`, `streaming.bp`) calls `isVoidTag`/`isRawTextTag` (94), `Boundary`/`Suspense`/`resolve`/`fillHtml` (30), `renderBoundaryChecked`/`isSignal` (31), `islandAttr`/`islandEntry` (29), `renderHead`/`mergeMetadata` (32), `RouterState`/`fill` (26) and `enterRequest`/`request()` (28); everything it reaches is core. `Link`, `layoutKeys`, `formAttrs`, `actionState` are reached only by application components and by onze front 68's generated entry — they are submodules. The bridge `jhonstart-emilia` is a submodule for the other admissible reason: it is the one member with a dependency (emilia) core must not have. No rakun module imports jhonstart and jhonstart imports no rakun module (decision 113); onze hands the route data in.

### 1.1 File placement

| Submodule | `src/` | From front | Frozen? |
|---|---|---|---|
| `jhonstart` | `element.bp` | — (v0) | yes |
| `jhonstart` | `elements.bp` | 94 | — |
| `jhonstart` | `hooks.bp`, `client_runtime.bp` + `client_runtime.mjs` | — (v0) | `hooks.bp` yes |
| `jhonstart` | `router.bp` + `router_runtime.mjs` / `sidecars/jhonstart_router.erl` | 26 | — |
| `jhonstart` | `client_app.bp` + `client_app.mjs` / `sidecars/jhonstart_client_app.erl` | 26 | — |
| `jhonstart` | `server.bp` + `server_runtime.mjs` / `sidecars/jhonstart_server.erl` | 28 | — |
| `jhonstart` | `client.bp` + `island_runtime.mjs` / `sidecars/jhonstart_island.erl` | 29 | — |
| `jhonstart` | `suspense.bp`, `streaming.bp`, `render.bp`, `plugin.bp`, `globals.bp`, `routes.bp`, `render.mjs`, `routes.mjs`, `sidecars/jhonstart_render.erl`, `sidecars/jhonstart_routes.erl` | 30 | — |
| `jhonstart` | `error_boundary.bp` + `signal_runtime.mjs` / `sidecars/jhonstart_signal.erl` | 31 | — |
| `jhonstart` | `metadata.bp` | 32 | — |
| `jhonstart` | `html_attrs.bp` | 48 (track D) | — |
| `jhonstart-html` | `html.bp` | — (v0) | yes |
| `jhonstart-link` | `link.bp` + `link_runtime.mjs` / `sidecars/jhonstart_link.erl`, `reconcile.bp` | 27 | — |
| `jhonstart-forms` | `form.bp` + `form_runtime.mjs` / `sidecars/jhonstart_forms.erl` | 67 | — |
| `jhonstart-emilia` | `root.bp` (`plugin()`, `classesIn`) | 30 | — |
| `jhonstart-test` | one `assert_<subject>.bp` per front + `harness.bp` | all nine (§ 5) | — |

`root.bp` of each submodule lists its `pub mod` lines in front-number order; `botopink.json`'s `files`
is in **dependency** order (a module after every module it imports).

### 1.2 `modules/jhonstart/src/root.bp`

```bp
pub mod element;
pub mod hooks;
pub mod router;         // front 26
pub mod client_app;     // front 26 (clientApp, decision 117)
pub mod server;         // front 28
pub mod client;         // front 29
pub mod suspense;       // front 30
pub mod streaming;      // front 30
pub mod render;         // front 30
pub mod plugin;         // front 30
pub mod globals;        // front 30
pub mod routes;         // front 30
pub mod error_boundary; // front 31
pub mod metadata;       // front 32
pub mod elements;       // front 94
pub mod html_attrs;     // front 48
mod client_runtime;
```

No `.d.bp` module is left in the package.

### 1.3 Cross-submodule imports

A module in a submodule imports the core by package name; a module in the core imports a sibling by
module name (`import {pairValue} from "router";`).

| File | Import |
|---|---|
| `html.bp` | `import {Element} from "jhonstart";` |
| `link.bp` | `import {Element, ElementBase} from "jhonstart";` |
| `form.bp` | `import {Element, ElementBase, input, form, snapshot, push, …} from "jhonstart"; import {linkPrefetch} from "jhonstart-link";` plus the bundled `actions` (decision 116) |
| `jhonstart-emilia/src/root.bp` | `import {RenderPlugin} from "jhonstart"; import {flush} from "emilia";` |
| `html_attrs.bp` (48, core) | `import {Element, renderToString} from "element";` — names no styling library |

### 1.4 Consumer import map

The fronts and their examples write `import {…} from "jhonstart"`; that resolves for core symbols, and
the submodules are imported by name. This table is what an implementer applies when a file is created
in `repository/jhonstart/examples/**` or `modules/*/test/**`.

| Symbol group | Import |
|---|---|
| `Element`, `ElementBase`, `text`, `div`, … (v0 eight) · `nav`, `form`, `input`, `htmlTag`, `el`, `isVoidTag`, … (94) · `state`/`effect`/`memo`/`ref`/`reducer` (hooks) · `classAttr`, `withAttrs`, `attrValue` (48) | `from "jhonstart"` |
| `RouterState`, `router`, `pathname`, `params`, `searchParams`, `selectedLayoutSegment(s)`, `push`, `replace`, `back`, `forward`, `refresh`, `prefetch`, `lastNavigation`, `pairValue`, `snapshot`, `fill`, `navigationFor`, `applySignal`, `resolveRoute`, `ClientApp`, `clientApp` (26) | `from "jhonstart"` |
| `RequestData`, `request`, `enterRequest`, `leaveRequest`, `cookies`, `headers`, `renderServerComponent`, `renderComponent` (28) | `from "jhonstart"` |
| `client`, `clientProps`, `islandId`, `islandAttrOf`, `islandAttr`, `Island`, `clientMount`, `islandEntry`, `propsOf`, `serverSlotAttr`, `serverSlot`, `serverOnly`, `hydrate`, `propsFor` (29) | `from "jhonstart"` |
| `Boundary`, `Suspense`, `holeId`, `Chunk`, `resolve`, `fillHtml`, `shellHtml`, `renderNode`, `raw`, `compose`, `Payload`, `writePayload`, `RenderHooks`, `defaultHooks`, `setHooks`, `App`, `app`, `PageInput`, `Response`, `RenderPlugin`, `globals`, `readPayload`, `registerFill`, `registerSignal`, `page`, `layout`, `template`, `defaultView`, `PageContext`, `LayoutProps`, `uiTable`, `UiSegment`, `segment` (30) | `from "jhonstart"` |
| `plugin` (30, the bridge) | `from "jhonstart-emilia"` |
| `ErrorInfo`, `ErrorBoundary`, `renderBoundary`, `renderBoundaryChecked`, `catchError`, `infoFor`, `serverInfoFor`, `digestOf`, `isSignal`, `notFound`, `redirect`, `notFoundReason`, `redirectReason`, `wrap` (31) | `from "jhonstart"` |
| `Metadata`, `OpenGraph`, `TwitterCard`, `Icons`, `Viewport`, `emptyMetadata`, `emptyOpenGraph`, `emptyViewport`, `mergeMetadata`, `mergeViewport`, `renderHead`, `renderViewport`, `pick`, `pickList`, `applyTemplate` (32) | `from "jhonstart"` |
| `html` (DSL) | `from "jhonstart-html"` |
| `Link`, `LinkProps`, `linkProps`, `withPrefetch`/`withReplace`/`withScroll`/`withTarget`/`withClass`, `prefetchMode`, `layoutKey`, `layoutKeys`, `sharedDepth`, `LinkStatus`, `linkStatusOf`, `linkStatus`, `linkMount`, `linkPrefetch`, `linkRouteKind` (27) | `from "jhonstart-link"` |
| `FormBinding`, `formAction`, `formAttrs`, `hiddenActionField`, `actionForm`, `submitForm`, `invokeAction`, `formMount`, `setWireNames`, `actionState`, `FormStatus`, `formStatus`, `optimistic`, `applyOptimistic`, `SearchFormProps`, `searchFormProps`, `searchFormAttrs`, `searchHref`, `prefetchSearch` (67) — `ActionState`, `newActionState` and `parseActionState` are the bundled library `actions`' (decision 116), imported `from "actions"` | `from "jhonstart-forms"` |
| `assertHtml`, `assertStream`, … (§ 5) | `from "jhonstart-test"` (dev) |

## 2 · Candidate verdicts

Each candidate against front 95's two admissible reasons — *a consumer wants this part without the rest* or *a different target profile* — plus dependency direction and which fronts deliver into it.

| Candidate | Verdict | Reason |
|---|---|---|
| `jhonstart` (core) | **keep** | Holds front 30's render and every module it renders through (26 · 28 · 29 · 30 · 31 · 32 · 94 + frozen v0 + 48's `html_attrs.bp`). Every module renders on erlang (server pass) and re-renders on js. |
| `jhonstart-html` | **keep, narrowed** | The DSL is comptime template evaluation a builder-only consumer never invokes, and every 26–32/67 example is builder-only. Narrowed: constructors are imported `from "jhonstart"` and are indistinguishable from `element.bp`'s eight (front 94), so they stay in core; this submodule is `html.bp`. Depends on core (`Element`); nothing in core depends on it — the DSL resolves tags in the *caller's* scope. |
| `jhonstart-router` | **merge into core** | `router.bp` owns `pairValue`, imported by 28; `RouterState` is filled by the server render and read by every layout. A domain submodule the core imports inverts the dependency direction. |
| `jhonstart-link` | **keep** | Front 27 alone: `link.bp` + `reconcile.bp`. Nothing in core or in front 30's render imports it; a statically generated site (front 60) or a no-bundle server render ships without it. Depends on core. |
| `jhonstart-server` | **merge into core** | `server.bp` reads the `RequestData` the render received — the server render itself. |
| `jhonstart-client` (29) | **merge into core** | `Island`, `clientMount`, `islandEntry`, `serverSlot` are called by front 30's render during the BEAM pass to build the payload's `i` rows; `hydrate()` is one import from core for front 68's entry. Splitting 29 would make the server pipeline depend on a submodule named "client". |
| `jhonstart-streaming` | **merge into core** | `Suspense`/`resolve`/`fillHtml`/`shellHtml` are the flush contract of front 30's render, which lives beside them. |
| `jhonstart-errors` | **merge into core** | `renderBoundaryChecked` is what front 30's `compose` calls around every segment; `isSignal` is `routing`'s `navigation.isSignalReason` (decision 116); `global-error.bp` needs 94's `htmlTag`/`body`. |
| `jhonstart-metadata` | **merge into core** | `renderHead`/`mergeMetadata` run inside front 30's document build. |
| `jhonstart-forms` | **keep** | Front 67 alone: `form.bp`. It reads front 24's envelope and writes the JSON-RPC body through the bundled library `actions` (decision 116). A read-only site ships without it. Depends on core and on `jhonstart-link` (`linkPrefetch` for the GET form). Nothing depends on it. |
| `jhonstart-elements` (94) | **merge into core** | "A reader cannot tell from a call site whether a tag came from `element.bp` or from `elements.bp`", and `isVoidTag`/`isRawTextTag` are consumed by front 30's `renderNode`. |
| `jhonstart-emilia` | **keep** | Decision 113's bridge: `plugin()` implements front 30's asynchronous `RenderPlugin` over emilia's `@Task`-returning `flush()` and contributes the payload's `s` key (decision 114). The one member that depends on emilia — core must not, and emilia imports nobody. Owned by front 30. Its test is where the contract-4 class literal meets the rendered document (emilia's former integration test, decision 114). |
| `jhonstart-hooks` | **drop** | Frozen `hooks.bp`, one file. |
| `jhonstart-test` | **keep** | Mandatory by the pattern. § 5. |

Net: **six directories** — core, `-html`, `-link`, `-forms`, `-emilia`, `-test`.

## 3 · Dependency graph

```
                    std (escape · encoding · async · hash · json · testing.asserts · testing.snapshots)
                    routing (bundled, decisions 115/116: table · match · route_kinds · slot_states · url_rules · navigation · pattern)
                    actions (bundled, decision 116: state · envelope · rpc · refresh — 26 and 67)
                     │
                     ▼
              ┌── jhonstart ──────────────────────────────────────────────────────────┐
              │   element · elements(94) · hooks · router/client_app(26) · server(28)  │
              │   client(29) · suspense/streaming/render/plugin/globals/routes(30)     │
              │   error_boundary(31) · metadata(32) · html_attrs(48)                   │
              └───────┬──────────────────┬───────────────────────┬──────────────────────┘
                      │                  │                       │
                      ▼                  ▼                       ▼
             jhonstart-html      jhonstart-link (27)     jhonstart-emilia (30) ──► emilia
             html                         │               (RenderPlugin over flush())
                                          ▼
                                 jhonstart-forms (67) ◄── 24's envelope, through `actions`
                                          │
                                          ▼
                              jhonstart-test  ◄── depends on core, -html, -link, -forms + std testing.asserts + testing.snapshots
                                          │
                                          ▼
                                 onze (49 boot · 68 entry · 53 example app) ──► rakun
```

Edges are `botopink.json` dependencies. Three facts the graph encodes:

- **jhonstart and rakun never import each other; onze is the only package that names both** (decision 113). The route data, the action ids and the wire names `actionField` / `actionHeader` (front 67's `setWireNames`), the `RequestData` (front 28) and a `Response` (front 30 — status, header, write, close) onze builds over rakun's `ChunkWriter` reach jhonstart as values onze hands in. The matcher and the routing codecs are the compiler-bundled library `routing` (decision 115), which core imports like std — not an edge to rakun, and never listed in a manifest. No jhonstart cell names a rakun host module. The UI file conventions (`#[page]`, `#[layout]`, `#[template]` — each a `fn … -> @Component<ElementBase, Element>`, decision 117 — `PageContext`, `LayoutProps`) are jhonstart's (front 30, `routes.bp`); rakun holds only an opaque `PageRenderer` per route. A page's or layout's `notFound()` and `redirect(url)` are jhonstart's own (front 31) and jhonstart handles them end to end (decision 117): front 30's render answers a 404 or a 307 through the `Response` before the first chunk and writes markup after it, and front 26's `clientApp` handles them in a client-only app; onze has no `case` on a signal. A server action's `redirect` is rakun's, read from the envelope's `n` by front 26.
- **emilia enters through the bridge only.** `jhonstart-emilia` is the one member that imports emilia; core and every other member know only `RenderPlugin`, and front 30's gate asserts that the string `emilia` appears nowhere under `modules/jhonstart/`. Front 48's `html_attrs.bp` is emilia-unaware plumbing; emilia's `html_hook.bp` imports no jhonstart module (`styled`/`cls` return plain pairs and strings).
- **Front 68's generated entry** imports `hydrate`, `readPayload`, `registerFill`, `registerSignal` and `globals` from core, `linkMount` from `jhonstart-link`, `formMount` from `jhonstart-forms` — ordinary imports, one call each; the only browser globals are the three `globals()` aliases (`__bp0`, `__bp1`, `__bp2`).

## 4 · Target of each submodule

Every member inherits `["commonJS", "erlang"]` from the workspace, and `zig build test-libs -- --lib <member>` runs every suite on **both** rows.

| Submodule | Why both |
|---|---|
| `jhonstart` | the server pass renders every module on erlang; front 68 re-renders the same code in the browser; 94's constructors must produce the identical `Element` on both |
| `jhonstart-html` | the DSL is comptime; its output is a builder pipeline that runs wherever the builders do |
| `jhonstart-link` | `Link` is pure and rendered by the server; the browser half's cells are dual-target |
| `jhonstart-forms` | `formAttrs`/`hiddenActionField` render in the server pass — the progressive-enhancement markup |
| `jhonstart-emilia` | the plugin runs wherever front 30's render does |
| `jhonstart-test` | helpers are pure over strings |

**Host cells are dual-target** — the rule the manifests encode: every browser cell (`#[@External.Node]`)
carries an `#[@External.Erlang]` twin whose answer is what is true on a server (no link in flight,
nothing prefetched, nothing hydrated, no props, a quiet form), because a **called** single-target cell
reds the other target's compile at the caller and every member is compiled on both rows. Each host half
ships beside its module (`<name>_runtime.mjs` / `sidecars/jhonstart_<name>.erl`). This is
`../decisions-pending.md` 27-a, implemented and awaiting confirmation.

## 5 · `jhonstart-test`

Depends on: `std` (`import {testing: {asserts, snapshots}, querystring} from "std"` — decisions 106/107; only the leaves enter scope), `jhonstart`, `jhonstart-html`, `jhonstart-link`, `jhonstart-forms`. Every helper is `pub fn assert<Subject>(loc: SourceLocation, …) -> @Result<void, string>`; each renders its subject to a deterministic string and hands it to `snapshots.match(loc, text)` (`../01-std/snapshots.md`). Exact signatures and the text each one produces are in [`test-snap.md § 0`](./test-snap.md).

None of these files exists yet; the member holds only its `root.bp` smoke test.

| File | Exposes | Filled by front |
|---|---|---|
| `harness.bp` | `renderToString` re-export · `renderToStream(shell: Element, boundaries: Array<Boundary>) -> @Task<Array<string>>` — shell then fills in **declaration** order (a test harness has no scheduler; front 30's completion order is its own test) · `simulateNavigation(from: RouterState, to: RouterState) -> Navigation` — the pure remount decision (`layoutKeys`, `sharedDepth`, remounted depth) · `fixtureRouter(path, pattern, params, search) -> RouterState` · `fixtureRequest(…) -> RequestData` · `stubEnvelope(ok, state, redirect) -> string` · `renderStreamCollect(app, input, req)` and `renderRecorded(app, input, req, streaming) -> @Task<RecordedResponse>` — front 30's render over a recording `Response` (decision 117) | 94 (harness skeleton), 26, 27, 28, 30, 67 |
| `assert_html.bp` | `assertHtml(loc, e: Element)` — `renderToString(e)`, one line | 94 |
| `assert_route.bp` | `assertRoute(loc, r: RouterState)` · `assertActiveLink(loc, nav: Element, path: string)` — the anchors of `nav` with an `active` marker | 26 |
| `assert_link.bp` | `assertLink(loc, l: Element)` · `assertNavigation(loc, n: Navigation)` | 27 |
| `assert_server.bp` | `assertRequest(loc, r: RequestData)` — a server component is snapshotted by `val tree = await Page(params); try assertHtml(@src(), tree);` (`await` is legal in a `test` block) | 28 |
| `assert_island.bp` | `assertClientBundleEntry(loc, islands: Array<Island>)` — the payload `i` rows plus each placeholder | 29 |
| `assert_stream.bp` | `assertStream(loc, chunks: Array<string>)` — one chunk per block, in order | 30 |
| `assert_render.bp` | `assertDocument(loc, doc: string)` — the document front 30's `render` wrote, one line per chunk · `assertResponse(loc, r: RecordedResponse)` — the status, the headers and the chunks a recording `Response` received, and how many times it was closed · `assertPayload(loc, p: Payload)` — `writePayload(p)` | 30 |
| `assert_error_boundary.bp` | `assertErrorBoundary(loc, b: ErrorBoundary)` — the `renderBoundaryChecked` outcome tagged `ok`/`error` | 31 |
| `assert_metadata.bp` | `assertMetadata(loc, m: Metadata)` · `assertViewport(loc, v: Viewport)` | 32 |
| `assert_form.bp` | `assertForm(loc, f: Element)` · `assertActionState(loc, s: ActionState)` · `assertOptimistic(loc, base: i32, actions: i32[])` | 67 |

Rules carried from front 95 § 5: import std's `testing.asserts`, never re-implement `equal`; expose fixtures (`fixtureRouter`, `fixtureRequest`, `stubEnvelope`), not only assertions; `#[mock]` pairing is documented in the submodule README, and the host runtime behind it lives in the first `-test` submodule that needs it (rakun's, not this one).

## 6 · Front → directory ownership

One source directory per front. The `jhonstart-test` column is the helper file each front also adds; it is not a second owner of the front's source.

| Front | Source dir | Files | Adds to `jhonstart-test` |
|---|---|---|---|
| **94** element-surface | `modules/jhonstart/src/` | `elements.bp` | `harness.bp`, `assert_html.bp` |
| **26** router | `modules/jhonstart/src/` | `router.bp`, `client_app.bp` + host halves | `assert_route.bp`, `fixtureRouter` |
| **28** server-components | `modules/jhonstart/src/` | `server.bp` + host halves | `assert_server.bp`, `fixtureRequest` |
| **27** link | `modules/jhonstart-link/src/` | `link.bp`, `reconcile.bp`, host halves, `root.bp`, `botopink.json` | `assert_link.bp`, `simulateNavigation` |
| **29** client-directive | `modules/jhonstart/src/` | `client.bp` + host halves | `assert_island.bp` |
| **30** render and streaming | `modules/jhonstart/src/` · `modules/jhonstart-emilia/` | `suspense.bp`, `streaming.bp`, `render.bp`, `plugin.bp`, `globals.bp`, `routes.bp` + host halves · the bridge's `botopink.json`, `src/root.bp`, `test/` | `assert_stream.bp`, `assert_render.bp`, `renderToStream` |
| **31** error-boundaries | `modules/jhonstart/src/` | `error_boundary.bp` + host halves | `assert_error_boundary.bp` |
| **32** metadata | `modules/jhonstart/src/` | `metadata.bp` | `assert_metadata.bp` |
| **67** forms | `modules/jhonstart-forms/src/` | `form.bp` + host halves, `root.bp`, `botopink.json` | `assert_form.bp`, `stubEnvelope` |
| *48 (track D)* | `modules/jhonstart/src/` | `html_attrs.bp` | — (tested from emilia) |
| *— (v0, frozen)* | `modules/jhonstart/src/` · `modules/jhonstart-html/src/` | `element.bp`, `hooks.bp` · `html.bp` | — |

Tests: each front's `test/<name>_test.bp` sits in the same submodule's `test/` as its source, with its `__snapshots__/` beside it. `html_test.bp` and 94's `elements_test.bp` live in `modules/jhonstart-html/test/` — both are consumer-position DSL resolution tests.

## 7 · Relations to the other tracks

| Track | Front | Relation | What crosses |
|---|---|---|---|
| emilia (D) | **48** attributes | 48 owns `modules/jhonstart/src/html_attrs.bp` — the only cross-repo file. jhonstart stays emilia-unaware; `[class]={expr}` reaches `attrs` and emilia's `html_hook.bp` produces the class string without importing jhonstart. | a `#("class", "e_<hex>")` pair, nothing else |
| emilia (D) | **56** cascade-and-output | `flush()` is what the `jhonstart-emilia` bridge (front 30) awaits from `RenderPlugin.head` / `chunk`; the classes it flushed become the payload's `s` through `RenderPlugin.payload`; emilia does not change for it and imports nobody. The bridge's test asserts contract 4's class literal on the jhonstart side. | the `<style>` string `flush()` returns |
| rakun (B) | **23** ssr-pipeline | Imports nothing from jhonstart. It matches the route, opens the request scope, calls the opaque `PageRenderer` onze registered and puts on the socket what front 30's `renderStream` writes through the `Response` onze built over rakun's `ChunkWriter` (`setStatus`, `setHeader`, `write`, `close`) — both ends wired by onze. | the status and headers set before the first write; the chunk strings |
| rakun (B) | **24** server-actions | Owns the action id and envelope that `jhonstart-forms` carries and decodes; builds no markup — the form is 67's, and the id reaches it through onze. | the envelope and the RPC body, through the bundled library `actions` (decision 116) — no literal asserted on both sides |
| rakun (B) | **22** file-routing · **62** request-context · **63** navigation-signals · **66** metadata-file-routes | 22 scans `app/` for `loading.bp`/`error.bp`/`not-found.bp`/`global-error.bp` and specifies the matcher, which 26 imports from the bundled `routing` as rakun does; 62's request is what onze turns into the `RequestData` the render receives; the `nav:` reasons 63 and 31's own `notFound()` raise are `routing`'s `navigation` vocabulary (decision 116), which `isSignal`, 26 (`signalFromWire`) and 30 (the late signal) import; 66 serves the paths `openGraph.images` names. | route table `t`; the `RequestData` onze builds; the `nav:` reasons, through `routing`; image paths |
| onze (E) | **49** stand-up | Boots the app: `app(plugins: [emiliaPlugin()])`, fills `RenderHooks`, copies front 30's `uiTable()` into rakun's table, registers one `PageRenderer` per page calling `renderStream(input, req, res)` with a `Response` adapted over rakun's `ChunkWriter`, passes `allowedRedirects` to `app`, hands the action wire names to 67 (`setWireNames`) and rakun. | the plugin list; `allowedRedirects`; `PageInput`; the `RequestData`; the `Response`; `actionField` / `actionHeader` |
| onze (E) | **68** client-bundle | Generates the entry that calls `registerFill(globals().fill, …)`, `registerSignal(globals().signal, allowedRedirects: …)`, `hydrate()`, `linkMount()`, `formMount()`; enforces 29's boundary rules over the module graph; brings the transition driver `reconcile(current, target)` (27). | `__jhClient_<Name>` markers; the `server-only` import predicate |
| onze (E) | **53** example-app | The first place a browser is in the loop; imports every symbol in § 1.4. | — |
| std (A) | **01** · **02** · **03** | `escape.html`/`escape.attribute` (30, 32); `encoding.formParse`/`formStringify` (26, 28, 29 — decision 116); `async` spawn/gather over thunks (30); `hash.contentHash` (31); `json.quote`/`array`/`object` and `escape.scriptJson` (30's payload) and `json.decode` (30's `readPayload`), all `01-std-lib-enablement` (decision 117). | — |

## 8 · `repository/jhonstart/examples/**`

Existing members: `jhonstart-counter/`, `jhonstart-markup/` (the `html """…"""` DSL cross-module), `jhonstart-todo/` (v0, pure client, stay as-is). `jhonstart-app/` has no manifest (aspirational, not a member) and is removed when `blog-ssr` lands.

To create — one per consumer shape, each with `botopink.json`, `src/`, `test/` and its own `__snapshots__/`:

| Project | Shape | Fronts exercised | Depends on | Target |
|---|---|---|---|---|
| `examples/blog-ssr/` | the server-rendered blog: root layout, `/blog/[slug]` page with two sequential loaders, `loading.bp`, `error.bp`, `not-found.bp`, `global-error.bp`, static + dynamic metadata, viewport | 26 · 28 · 30 · 31 · 32 · 94 | `jhonstart`, `jhonstart-test`, `std` | erlang |
| `examples/nav-shell/` | a docs shell: sidebar with active-segment highlighting, prefetch policy per route kind, pending checkout link, shared-layout reuse across a transition | 26 · 27 · 94 | `jhonstart`, `jhonstart-link`, `jhonstart-test` | both |
| `examples/islands/` | a like-button island per post, a theme provider wrapping server children, the payload `i` rows | 28 · 29 · 94 | `jhonstart`, `jhonstart-test` | both |
| `examples/forms/` | create-post form with per-field message, optimistic like with nested `formStatus` button, GET search form | 67 · 29 · 26 · 27 · 94 | `jhonstart`, `jhonstart-link`, `jhonstart-forms`, `jhonstart-test`, `std` | commonJS |
| `examples/document-shell/` | `htmlTag`/`head`/`body` document built once with constructors and once with `html """…"""` over the same tags; void-element and `main` caveats as literals | 94 · (DSL) | `jhonstart`, `jhonstart-html`, `jhonstart-test` | both |

Every `.bp` under `examples/**` and every `.snap` it produces is mapped in [`test-snap-examples.md`](./test-snap-examples.md).

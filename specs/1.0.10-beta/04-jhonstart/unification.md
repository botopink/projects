# Track C — jhonstart · unification

The proof that nothing was lost carrying the jhonstart track from `specs/1.0.9-beta/` into this directory, and that the 1.0.7-beta draft (`specs/1.0.7-beta/02…08-jhonstart-*`, `16-emilia-jhonstart-integration`, the jhonstart sections of `examples-bp.md`, `overview.md`, `fronts.md`) is absorbed. Method: every old section, requirement, API name, example, decision, reference row and rationale was matched against the 1.0.9 counterpart; anything absent or decided differently is quoted under `## Carried from 1.0.7-beta FNN <name>` at the foot of the front's README, and every `.bp` snippet of `examples-bp.md` without an equivalent file is placed in the front's `examples/` as `carried-<topic>-example.bp`. § 5 holds the per-section verdict tables; § 4 the Next.js reference rows the merge still misses.

## 1 · 1.0.9 → 1.0.10 (mechanical, byte-identical)

| 1.0.9 path | 1.0.10 path | Links rewritten | Appended |
|---|---|---|---|
| `26-jhonstart-router/` | `04-jhonstart/26-jhonstart-router/` | none needed (§ 1.1) | `## Carried from 1.0.7-beta F02 jhonstart-router` · 2 example files |
| `27-jhonstart-link/` | `04-jhonstart/27-jhonstart-link/` | none | `F03 jhonstart-link` · 1 example file |
| `28-jhonstart-server-components/` | `04-jhonstart/28-jhonstart-server-components/` | none | `F04 jhonstart-server-components` · 3 example files |
| `29-jhonstart-client-directive/` | `04-jhonstart/29-jhonstart-client-directive/` | none | `F05 jhonstart-client-directive` · 3 example files |
| `30-jhonstart-streaming/` | `04-jhonstart/30-jhonstart-streaming/` | none | `F06 jhonstart-streaming` · 3 example files |
| `31-jhonstart-error-boundaries/` | `04-jhonstart/31-jhonstart-error-boundaries/` | none | `F07 jhonstart-error-boundaries` · 3 example files |
| `32-jhonstart-metadata/` | `04-jhonstart/32-jhonstart-metadata/` | none | `F08 jhonstart-metadata` · 2 example files |
| `67-jhonstart-forms/` | `04-jhonstart/67-jhonstart-forms/` | none | nothing — `Replaces: new`, no 1.0.7 counterpart |
| `94-jhonstart-element-surface/` | `04-jhonstart/94-jhonstart-element-surface/` | none | `F16 emilia-jhonstart-integration` (jhonstart side only) · 2 example files |
| `48-emilia-attributes/` | `../05-emilia/48-emilia-attributes/` | — (emilia track) | emilia-owned F16 residue listed in § 3, not appended here |
| `tracks/README.md` (test contract) | `../01-std/{src-builtin,snapshots,asserts-api}.md` | cited from `test-snap.md § 0` | — |
| `fronts.md` Track C · `overview.md` Track C · `contracts.md § 2/3` | `README.md` (this dir) · `modules.md` · `../../contracts.md` | — | — |

### 1.1 Why no link was rewritten

`grep -rhoE '\]\([^)]*\)' 04-jhonstart/**/*.md` finds only `./examples/*.bp` links — every cross-front and top-level reference in the nine READMEs is a backticked coordinate in prose (`contracts.md § 2`, `23-rakun-ssr-pipeline/README.md:278`, `language-gaps.md`, `fronts.md`), not a Markdown link. The copies are byte-identical to the on-disk 1.0.9 files above the appended section. Resolution of those coordinates in this milestone:

| Coordinate as written | Resolves to |
|---|---|
| `contracts.md § N` | `../../contracts.md § N` |
| `language-gaps.md`, `fronts.md`, `overview.md`, `deferred.md` | `../../language-gaps.md`, `../../fronts.md`, `../../overview.md`, `../../deferred.md` |
| `NN-rakun-*/README.md:L` (22 · 23 · 24 · 53 · 62 · 63 · 66) | `../../03-rakun/NN-rakun-*/README.md:L` (53 → `../../06-onze/53-onze-example-app/`) |
| `01-std-lib-enablement/README.md:L`, front 02, front 03 | `../../01-std/NN-std-*/README.md:L` |
| `1.0.7-beta/0N-jhonstart-*` (`Replaces:` lines) | `../../../1.0.7-beta/0N-jhonstart-*` — historical, kept verbatim |
| `48-emilia-attributes` | `../../05-emilia/48-emilia-attributes/` |
| front 68 (client bundle) | `../../06-onze/68-onze-client-bundle/` |
| `specs/1.0.10-beta/` (the "gaps appear in a 1.0.10 spec" acceptance items) | `../../language-gaps.md` — this milestone |

## 2 · 1.0.7 → 1.0.9/1.0.10 — what had to be appended

| 1.0.7 front | 1.0.9 counterpart | Verdict | Appended (count) | Examples carried |
|---|---|---|---|---|
| `02-jhonstart-router` | 26 | re-decided almost everywhere (`Router` behavior → `RouterState` record; `push`/`replace` as methods → free functions over one dual `__jhNavigate` cell; `Dict` → pair lists; `onze13/runtime` → `jhonstart_router`); truly absent: `botopink check` gate, "examples using `router.d.bp` still compile", branch name, the "no API change" claim, 1.0.7 phase/critical-path lines, overview row `next/navigation → useRouter behavior` | 12 subsections + 8 reference rows | `carried-programmatic-navigation-example.bp`, `carried-route-params-example.bp` (Breadcrumb skipped: in `active-nav-example.bp`) |
| `03-jhonstart-link` | 27 | re-decided: positional `Link(href, children, prefetch:…)` → `Link(linkProps(href), children)` + `with*`; `data-onze13-link="true"` family → `data-onze-l="1"` family; click/prefetch moved from "runtime, not here" to implemented here; gate commonJS only. Truly absent: pass-through `attrs` parameter, branch name, phase lines | 10 subsections + 7 reference rows | `carried-link-replace-example.bp` (NavBar and prefetch-off BlogList skipped: in `post-list-links-example.bp`) |
| `04-jhonstart-server-components` | 28 | re-decided: `Request` behavior over `Dict` with `body` → `RequestData` six pair-list fields, no `body`; `use request()` → plain `request()`; `onze13/runtime` cells → six `rakun_request_context` cells; provider F09 → front 62; gate erlang. Truly absent: the v0.beta.12 `use-await-prefix`/`async-generators` history, the `Http`-mirrors-`Element` rationale, branch name, module column / phase / conflict-matrix rows | 12 subsections + 5 reference rows | `carried-blog-page-fetch-example.bp`, `carried-search-page-request-example.bp`, `carried-users-page-database-example.bp` |
| `05-jhonstart-client-directive` | 29 | re-decided: `val __jhonstart_client_<name> = true` → pure `__jhClient_<Name>()` with emit-before-fail; runtime `isClientComponent` registry → front 68 graph walk; `renderClientComponent`/`data-jhonstart-client` → `clientMount`/`data-onze-i` + payload `i`; hydration now in scope. Truly absent: "`use` legal in any `-> Element` body" line, branch name, "deprecate when native `'use client'` arrives" note, phase rows | 11 subsections + 5 reference rows | `carried-counter-client-state-example.bp`, `carried-timer-client-effect-example.bp` (no `effect` example existed), `carried-dashboard-mixed-server-client-example.bp` |
| `06-jhonstart-streaming` | 30 | re-decided: `SuspenseProps` with `data-jhonstart-fallback` attribute → `Boundary` thunk + `data-onze-h`; "transport is rakun's follow-up" → front 23's written flush contract; gate erlang. Truly absent: branch name, emilia-styled `loading.bp`, root `app/loading.bp` row | 8 subsections + 8 reference rows | `carried-suspense-fallback-example.bp`, `carried-loading-emilia-example.bp`, `carried-granular-streaming-example.bp` |
| `07-jhonstart-error-boundaries` | 31 | re-decided: `ErrorBoundaryProps(fallback: fn(error: string), children)` → `ErrorBoundary` record + `case` over `@Result`; `error.bp` export `Error(error, retry)` + `#[client]` → `ErrorPage(info)` + `data-onze-reset`; `notFound()` caught → front 63 signal passed through; root `error.bp` → `global-error.bp`. Truly absent: `NotFoundBoundary`/`data-jhonstart-not-found-boundary`, `Dict` params / `post == null`, branch name, root `app/not-found.bp` row | 9 subsections + reference rows | `carried-segment-error-client-example.bp`, `carried-not-found-server-component-example.bp`, `carried-not-found-emilia-example.bp` |
| `08-jhonstart-metadata` | 32 | strict superset; re-decided for the record: `pub val metadata` → `pub fn metadata()`; `generateMetadata(params: Dict)` → pair list + `parent`; both exports → front-23 error; `OpenGraph.type` → `ogType`; optionals → `""`/`[]`; `collectMetadata()` cell dropped; `renderMetadataToHtml` → `renderHead` with escaping. Reference rows: `ImageResponse (OG) → jhonstart + onze13` (now 66/70), decorator-based metadata principle | 9 subsections + 6 reference rows | `carried-static-metadata-example.bp`, `carried-dynamic-metadata-example.bp` |
| `16-emilia-jhonstart-integration` (jhonstart side) | 94 (+ 48 in track D) | absent from both 48 and 94: the `[emilia]={expr}` DSL surface and its lowering to `attrs: [#("class", emilia([...]))]` (48 decides `[class]={c}` pre-bound, `html.bp` frozen); the DSL handler registry (lookup-by-name); `html_attrs.bp` as an emilia "bridge" (48 makes it emilia-unaware); the old integration test shape; generic per-name handlers / future data/ARIA handlers. Real gap: 94's merged `root.bp` omits 48's `pub mod html_attrs;` — supplied in the appendix at its front-number position; in this milestone the line lives in `jhonstart-html`'s `root.bp` (`modules.md § 1.1`) | 7 subsections + 5 reference rows | `carried-emilia-attribute-html-dsl-example.bp`, `carried-responsive-modifiers-example.bp` |
| `examples-bp.md § F02–F08, F16` | per front above | 19 snippets: 16 carried as files, 3 skipped as present in substance (named in the rows above) | — | 16 files |
| `overview.md` / `fronts.md` jhonstart rows | 26–32 headers, `README.md` (this dir) | mapping rows present except those listed per front; the 1.0.7 dependency graph (`02 → 03/04 → 05…`) is superseded by `README.md § 3` | in each front's `### Reference rows from 1.0.7 overview/fronts` | — |

Two inconsistencies surfaced by the walk, recorded rather than silently fixed (the 1.0.9 text is verbatim):

| Where | What | Disposition in 1.0.10 |
|---|---|---|
| 94 *What the consuming fronts do* row for 32 vs 32 *Mechanism* | 94 says `renderHead` "emits `meta`/`link`/`title` **elements** from this surface rather than a string"; 32 specifies `renderHead(m) -> string` and tests byte-identical output | 32's own README is authoritative for 32: `renderHead -> string`, built from 94's `title`/`meta`/`link` constructors and rendered through the same walker front 23 uses. `test-snap.md § 32` asserts the string. |
| `specs/1.0.9-beta/48-emilia-attributes/examples/` | empty on disk although 48's README links `./examples/attributes-example.bp` | emilia track's to fill; the jhonstart-side snippet is carried in 94's `examples/carried-emilia-attribute-html-dsl-example.bp` |

## 3 · Emilia-owned F16 residue (absent from 48, not appended here)

For the emilia track (`../05-emilia/48-emilia-attributes/`) to pick up: the `registerEmiliaHandler()` role of `html_hook.bp` (48 ships `cls`/`clsWith` instead); the 1.0.7 `fronts.md` rule "emilia requires jhonstart (for the `Element` type)"; the overview mapping "CSS Modules → emilia scoped classes".

## 4 · Next.js reference rows the merge still misses

The client/React half of `NEXTJS-DOCS.md` walked against the nine fronts. A row is *missed* when no jhonstart front owns it and no other track's front is named for it.

| `NEXTJS-DOCS.md` | Item | Owner in 1.0.9 | Status |
|---|---|---|---|
| § 7 · § 13 *Streaming de dados com `use`* | React `use(promise)` in a client component — a promise created on the server, awaited in the browser | none | **missed** — botopink's `use` prefix is the `@Context` capability, not a promise unwrap; `Boundary.child` is a server thunk. Candidate for `../../deferred.md`: needs a serializable pending value crossing the `i` payload. |
| § 10 *Invocando via event handlers* | calling a server action from `onClick`/`startTransition`, reading its result without a form | 24 (scripted POST, contract 3) · 68 (runtime) | **partly missed** — jhonstart has the `data-onze-on-click` handler id (29) and no hook that awaits an action result outside a form. `actionState()` (67) is form-bound. |
| § 14 *Erros em event handlers* · *`startTransition`* | `useTransition`/`startTransition` | 31 (states the semantics), 68 (routes the failure) | **missed as API** — no `transition` hook in `hooks.bp` (frozen) and no front adds one. |
| § 18 *Memoização de dados* | React `cache()` per-request memoization | 62 | covered by rakun (per-request memoization is 62's) — not a jhonstart surface |
| § 18 *OG Images dinâmicas (ImageResponse)* · *Metadata Files* | `opengraph-image`, `sitemap`, `robots`, `manifest` | 66 · 70 | covered by rakun/onze; 32 owes `openGraph.images` paths |
| § 25 `<Image>` · § 16 | `next/image` | 51 (onze) | covered elsewhere |
| § 25 `<Script>` | `next/script` strategies `beforeInteractive` / `afterInteractive` / `lazyOnload`, `onLoad` | 68 (emission order, `beforeInteractive` chunks only) | **missed as API** — 94 has a raw-text `script` constructor; no strategy attribute, no `lazyOnload`. |
| § 7 hooks beyond `useState` | `useContext`, `useCallback`, `useTransition`, `useDeferredValue`, `useId` | `hooks.bp` (frozen: `state`/`effect`/`memo`/`ref`/`reducer`) | **missed** — outside every front's scope by the freeze; `useId` matters for hydration-stable ids and has no owner. |
| § 5 `template.tsx` | a layout that remounts per navigation | 22 (file routing) | not a jhonstart surface; 27's `layoutKey` would need a "never shared" flag — unowned |
| § 8 *Client-side Transitions* · *History API nativa* · § 26 navigation table · `useLinkStatus` | — | 26 · 27 | covered |
| § 7 · § 27 `'use client'`, *Context Provider*, *Intercalação com children*, `server-only` | — | 29 | covered |
| § 13 `loading.tsx`, `<Suspense>` | — | 30 | covered |
| § 14 `error.tsx`, `not-found.tsx`, `global-error.tsx`, `catchError`, *Erros esperados* | — | 31 (+ 63, 67) | covered |
| § 18 static / `generateMetadata`; `generateViewport`, title template (upstream only) | — | 32 (reference gaps recorded there) | covered |
| § 10 *Formulários*, `useActionState`, § 25 `<Form>`; `useFormStatus`, `useOptimistic` (upstream React only) | — | 67 (reference gaps recorded there) | covered |

## 5 · Per-section verdict tables

One table per 1.0.7 front, as produced by the walk (old section · verdict · where in the new README).

### F02 jhonstart-router → Front 26 — absorption summary

| Old section (`1.0.7-beta/02-jhonstart-router/README.md`) | Verdict | Where in new (`1.0.10-beta/04-jhonstart/26-jhonstart-router/README.md`) |
|---|---|---|
| Header · Next.js reference (useRouter · useParams) | covered | **Reference:** line (adds use-search-params) |
| Header · Priority critical | covered | **Priority:** |
| Header · Depends on F01 (onze13-stand-up) | covered | **Depends on:** 01 · 22 · 23 · 94 |
| Header · Owns `src/router.bp` (promote from .d.bp) | covered | **Owns:** (adds `pairValue`, `test/router_test.bp`) |
| Header · Does not touch element/hooks/html/server.d.bp/server.bp | covered | **Does not touch:** (`server.d.bp` not named; `server.bp` is) |
| Problem | covered | § Problem (expanded with immutability argument) |
| Current state (4 bullets) | covered | § Current state bullets 1–3; § Problem ¶2 (`attrs` slot); § Mechanism *five hooks* (`@Context`/`use`) |
| Examples in bp · `useRouter` + `router.pathname()` | different decision → appended | `pathname()` / `RouterState.path`; examples/active-nav-example.bp |
| Examples in bp · `router.params().get("slug")` | different decision → appended | `param(name)` over pair list, § Step 1 |
| Mechanism · `Router` behavior + `RouterState` implementor | different decision → appended | § Mechanism *The erlang half* — behavior dropped |
| Mechanism · `@Context<Element, Router>` over host cell (commonJS module-global / erlang process dict) | different decision → appended | § Step 2 cells (erlang), § *Native History API* (client rebuild) |
| Mechanism · `push`/`replace` mutate host cell | different decision → appended | § Step 4 free functions, 307 redirect on erlang |
| Mechanism · initial state from rakun SSR (F09) | covered (renumbered) | fronts 22/23 in § Mechanism, § *What crosses* |
| Step 1 · `RouterState` w/ `Dict` fields + 4 methods + acceptance | different decision → appended | § Step 1 (five fields, `param`/`searchParam`/`segments`/`segment`) |
| Step 2 · `onze13/runtime` dual-target cells + acceptance | different decision → appended | § Step 2 (`jhonstart_router`), § Step 4 (`__jhNavigate`) |
| Step 2 · acceptance "`botopink check` passes" | absent → appended | — |
| Step 3 · `useRouter() -> @Context<Element, Router>` + acceptance | different decision → appended | § Step 3 (`RouterState`; `use` form type-checked) |
| Step 4 · delete router.d.bp, edit botopink.json/root.bp | different decision → appended | § Step 5 — handed to front 94 |
| Step 4 · acceptance "All existing tests still pass" | absent → appended | — (only "front's tests green on its target") |
| Step 5 · `dict`-based test + commonJS+erlang | different decision → appended | § Test plan, § Step 1 acceptance (pair list, erlang) |
| Gate · `botopink test` green (commonJS + erlang) | different decision → appended | § Test plan (erlang row) |
| Gate · router.d.bp removed · botopink.json/root.bp · AGENTS.md | covered | § Step 5, § Definition of done |
| Gate · Commit on `fix/jhonstart-router` | absent → appended | — |
| Blast radius · "no API change for consumers" | different decision → appended | API did change (see appendix) |
| Blast radius · botopink.json/root.bp changes | covered | § Step 5 hand-off |
| Blast radius · "examples using router.d.bp still compile" | absent → appended | — |
| Notes · push/replace no-op during SSR; client nav is a follow-up | different decision → appended | § Step 4 verb table (307 redirect; fronts 27/29) |
| Notes · `Router` behavior stays the same interface | different decision → appended | § Mechanism — behavior dropped |
| overview.md front-table row | covered (substance) | header + § Mechanism |
| overview.md mapping `next/navigation (useRouter)` → `useRouter behavior` | different decision → appended (table) | `RouterState` record |
| fronts.md ownership row (router.bp · router_test.bp) | covered | **Owns:** |
| fronts.md Conflict Note 1 (F02 before F03) | covered (substance) | 27 **Depends on:** 26; § Step 5 |
| fronts.md dependency graph / critical path / phases | absent → appended (table) | replaced by **Wave** / **Depends on** |

**Appended items:** 12 subsections (2 example quotes, Mechanism, Steps 1–5, Gate, Blast radius, Notes) + 1 reference-rows table (8 rows, 2 of them absent/different).

**Example files written (`26-examples/`):** 2 — `carried-programmatic-navigation-example.bp` (LoginForm), `carried-route-params-example.bp` (BlogPost). Skipped 1: *useRouter in a component* (Breadcrumb) — its substance (read the pathname, render it in a breadcrumb span) is in `examples/active-nav-example.bp`; the old `router.pathname()` call shape is preserved in the appendix quote.

### F03 jhonstart-link → Front 27 — absorption summary

| Old section (`1.0.7-beta/03-jhonstart-link/README.md`) | Verdict | Where in new (`1.0.10-beta/04-jhonstart/27-jhonstart-link/README.md`) |
|---|---|---|
| Header · Next.js reference (Link Component · Linking and Navigating) | covered | **Reference:** line |
| Header · Priority critical | covered | **Priority:** |
| Header · Depends on F02 | covered | **Depends on:** 26 · 60 · 23 · 68 · 94 |
| Header · Owns `src/link.bp` | covered | **Owns:** (adds `reconcile.bp`, two test files) |
| Header · Does not touch router/element/hooks/html/server.d.bp | covered | **Does not touch:** (`server.d.bp` not named) |
| Problem | covered | § Problem (expanded: runtime half, defaults gap) |
| Current state (3 bullets) | covered | § Current state (`router.d.bp:27-28`, `element.bp:3-8`, `:55-67`) |
| Examples in bp · basic `Link("/", [text("Home")])` | different decision → appended | `Link(linkProps(href), children)`; examples/post-list-links-example.bp `header()` |
| Examples in bp · `prefetch: false` | different decision → appended | `withPrefetch(props, false)`; `archiveRow` |
| Mechanism · renders `<a>` with href | covered | § *The render half* props table |
| Mechanism · `data-onze13-link` marker | different decision → appended | `data-onze-l="1"` |
| Mechanism · prefetch/replace/scroll props | covered | props table (+ `target`, `className`) |
| Mechanism · pass-through `attrs` parameter | absent → appended | — (only `target`/`class` via `LinkProps`) |
| Step 1 · anchor string `data-onze13-link="true"` | different decision → appended | § Step 2 acceptance `data-onze-l="1"` |
| Step 1 · compiles on commonJS + erlang | covered | § Step 2 acceptance "renders identically on erlang and js" |
| Step 2 · parameter defaults + `data-onze13-*` `"true"/"false"` | different decision → appended | § Step 1 `linkProps`, § Step 2 `"0"/"1"` |
| Step 3 · remove Link from router.d.bp; botopink.json; root.bp | covered | § Step 5 — Module wiring (front 26 deletes; front 94 wires) |
| Step 4 · tests against old API; commonJS + erlang | different decision → appended | § Test plan (commonJS gate; one both-target anchor assertion) |
| Gate · `botopink test` green · botopink.json/root.bp · AGENTS.md | covered | § Test plan, § Step 5, § Definition of done |
| Gate · Commit on `fix/jhonstart-link` | absent → appended | — |
| Blast radius · "new file link.bp, no other changes" | different decision → appended | four owned files; router.d.bp removal is front 26's |
| Blast radius · consumers get a real Link | covered | § Problem |
| Notes · click interception is a client-runtime concern, not here | different decision → appended | § *The runtime half* `__onzeLinkMount`, § reconciler |
| Notes · prefetch is a client-runtime concern, not here | different decision → appended | § *Prefetch strategy*, `__onzeLinkPrefetch` |
| overview.md front-table row | covered (substance) | § Mechanism |
| overview.md mapping `next/link` → `Link component` | covered (substance) | § Mechanism; `linkStatus` added |
| fronts.md ownership row (link.bp · link_test.bp) | covered | **Owns:** |
| fronts.md Conflict Note 1 (F02 before F03) | covered (substance) | **Depends on:** 26; § Step 5 |
| fronts.md dependency graph / critical path / phases | absent → appended (table) | replaced by **Wave** / **Depends on** |

**Appended items:** 10 subsections (2 example quotes, Mechanism, Steps 1/2/3/4, Gate, Blast radius, Notes) + 1 reference-rows table (7 rows, 1 absent).

**Example files written (`27-examples/`):** 1 — `carried-link-replace-example.bp` (SettingsPage, `replace: true`; no new example exercises the `replace` prop — `search-params-example.bp` uses the programmatic `replace()` verb). Skipped 2: *Basic Link* (NavBar) — substance in `post-list-links-example.bp` `header()`; *Link with prefetch disabled* (BlogList) — substance in `post-list-links-example.bp` `archiveRow`/`BlogIndex`. The old positional call shape is preserved in the appendix quotes.

### F04 jhonstart-server-components → Front 28 — absorption summary

| Old section (1.0.7-beta/04) | Verdict | Where in new (1.0.10-beta/04-jhonstart/28) |
|---|---|---|
| Header — Next.js reference (server-and-client-components, fetching-data) | covered | header *Reference* (both URLs + NEXTJS-DOCS §7/§9/§26) |
| Header — Priority critical | covered | header *Priority* |
| Header — Depends on F02 (router) | covered | header *Depends on* (26 · 01 · 23 · 62 · 94) |
| Header — Owns `server.bp` (promote from `server.d.bp`) | covered | header *Owns* (+ `test/server_test.bp`) |
| Header — Does not touch router/link/element/hooks/html | covered | header *Does not touch* (extended with client.bp, root.bp, botopink.json) |
| Problem — `server.d.bp` stubs, `request()`/`Request` host-bound | covered | *Problem* para 2, *Current state* bullet 1 |
| Problem — `#[@future]` landed v0.beta.12; `use-await-prefix`/`async-generators` gap "partially closed" | absent → appended | appendix § History note |
| Current state — `Request` behavior + `request()` as `#[@External.Node]` stubs | covered | *Current state* bullet 1 |
| Current state — `#[@future] fn -> @Future<Element>` parseable | covered | *Current state* bullet 4 |
| Current state — `await` works inside `#[@future]` fn | covered | *Current state* bullets 4–5 |
| Current state — SSR pipeline F09 provides Request object | different decision → appended | *Mechanism § 3* (front 62 request context; front 23 payload) |
| Exemplos — BlogPage with `fetch().then({ r -> r.json() })` | different decision → appended | *Mechanism § 4*, *Step 4* (named loaders, statement-level await) |
| Exemplos — SearchPage with `use request()` / `req.query("q")` | different decision → appended | *Language gaps* row 1 (plain `request()`), *Step 1* (`queryParam`) |
| Mechanism — `RequestData` implements `Request` (path/params/query/headers/body) | different decision → appended | *Mechanism § 1*, *Step 1*, *Step 5* (behavior dropped, six fields, pair lists) |
| Mechanism — `request() -> @Context<Http, Request>` host cell | different decision → appended | *Step 2*, *Language gaps* row 1 |
| Mechanism — server components are `#[@future] fn -> @Future<Element>` | covered | *Mechanism* intro, *Step 3* |
| Mechanism — host runtime sets request context before rendering | covered | *Mechanism § 3*, `request-scope-example.bp` header |
| Step 1 — `Dict` fields, `implement Request`, `path()/params()/query()` | different decision → appended | *Step 1* (pair lists, `pairValue` from front 26, by-name accessors) |
| Step 1 acceptance — implements `Request`; methods have bodies | different decision / covered | *Step 1* acceptance |
| Step 2 — `getRequest` Node+Erlang cells (`onze13/runtime`, `onze13_runtime`) | different decision → appended | *Step 2* (six erlang cells on `rakun_request_context`, no Node cell) |
| Step 2 acceptance — cells for both targets | different decision → appended | *Step 2* acceptance (erlang only) |
| Step 3 — `BlogPost(params: Dict)` pattern | covered (param shape differs) → appended for the `Dict` form | *Step 3*, *Step 4*, `blog-post-page-example.bp` |
| Step 3 acceptance — compiles / await works / returns `@Future<Element>` | covered | *Step 3* acceptance |
| Step 4 — delete `server.d.bp`, edit `botopink.json` + `root.bp` | different decision → appended | *Step 5* (front 94 owns root.bp/botopink.json) |
| Step 5 — test with `dict.fromList`/`dict.empty`/`req.path()` | different decision → appended | *Test plan* items 1–2, *Step 1* |
| Step 5 acceptance — pass on commonJS + erlang | different decision → appended | *Test plan* (erlang gate; commonJS expected to fail at first cell) |
| Gate — `botopink test` green | covered | *Definition of done* last box |
| Gate — `server.d.bp` removed, `server.bp` in place | covered | *Step 5*, *Definition of done* box 1 |
| Gate — AGENTS.md updated | covered | *Step 5* acceptance, *Definition of done* box 5 |
| Gate — commit on `fix/jhonstart-server-components` | absent → appended | appendix § Gate — branch name |
| Blast radius — `.d.bp` → `.bp` promotion | covered | *Step 5* |
| Blast radius — no API change for consumers | different decision → appended | *Step 5* / *Definition of done* (Request + Http dropped) |
| Blast radius — `root.bp` gains `pub mod server;` | covered | *Step 5* (handed to front 94) |
| Notes — HTTP lifecycle is rakun's (F09) | different decision → appended | *Mechanism § 3* (front 62) |
| Notes — `Http` phantom mirrors `Element` | different decision → appended | *Language gaps* row 1 (Http dropped) |
| overview.md front row (critical · jhonstart · jhonstart-core · request() hook) | partially covered → reference row appended | header; module column and "hook" wording not restated |
| overview.md Next.js mapping row (RSC → `#[@future] fn → @Future<Element>`) | covered → reference row appended for record | *Mechanism* mapping block |
| fronts.md ownership row (`src/server.bp`, `test/server_test.bp`) | covered → reference row appended for record | header *Owns* |
| fronts.md conflict-matrix row / Phase-1 ordering | absent → reference row appended | header *Wave 2* + *Depends on* replace them |
| examples-bp.md — BlogPage (fetch) | not in new examples → `carried-blog-page-fetch-example.bp` | — |
| examples-bp.md — SearchPage (use request) | not in new examples → `carried-search-page-request-example.bp` | — |
| examples-bp.md — UsersPage (db.user.findAll) | not in new examples → `carried-users-page-database-example.bp` | — |

Appended items: 12 subsections + 1 reference-row table (5 rows). Example files written: 3 (none of the three examples-bp.md snippets is present in substance in the new `examples/`).

### F05 jhonstart-client-directive → Front 29 — absorption summary

| Old section (1.0.7-beta/05) | Verdict | Where in new (1.0.10-beta/04-jhonstart/29) |
|---|---|---|
| Header — Next.js reference (server-and-client-boundary, use-client) | covered | header *Reference* (both URLs + NEXTJS-DOCS §7/§27) |
| Header — Priority high | covered | header *Priority* |
| Header — Depends on F04 | covered | header *Depends on* (28 · 23 · 68 soft · 94) |
| Header — Owns `client.bp` | covered | header *Owns* (+ `test/client_test.bp`) |
| Header — Does not touch router/link/server/element/hooks/html | covered | header *Does not touch* (+ root.bp, botopink.json) |
| Problem — Next.js `'use client'` boundary; all components server by default; interactive ones need to declare | covered | *Problem* paras 1–3 |
| Current state — no boundary mechanism | covered | *Current state* bullet 1 |
| Current state — everything renders via `renderToString` (SSR) | covered | *Problem* para 1 |
| Current state — hooks have SSR-only bodies | covered | *Problem* para 1, *Current state* bullet 2 |
| Current state — `use` prefix legal in any `-> Element` body | absent → appended | appendix § Current state (rule lives in front 28 *Language gaps*) |
| Exemplos — zero-param `Counter` with `use state(0)` / `onClick` attr | different decision → appended | *Mechanism § The props* (record param), `like-button-client-example.bp` (`data-onze-on-click`) |
| Exemplos — `DashboardPage` calling `Counter()` directly + `await RecentPosts()` in array | different decision → appended | *Mechanism § The placeholder* (`clientMount`/island), front 28 *Step 4* (statement-level await) |
| Mechanism — comptime decorator emits metadata | covered | *Mechanism § The marker* |
| Mechanism — serialized as references, hydrated by client runtime | covered (wording appended for record) | *Mechanism § The placeholder*, *Step 4* (`hydrate()`) |
| Mechanism — no `'use client'` syntax, so a decorator | covered | *Problem* para 4 |
| Mechanism — `Counter` code (attrs variant) | different decision → appended | as above |
| Step 1 — `client(comptime decl)` emitting `val __jhonstart_client_<name> = true;` | different decision → appended | *Mechanism § The marker*, *Step 1* (pure fn `__jhClient_<Name>`, emit-before-fail, returnType check) |
| Step 1 acceptance — compiles / fn -> Element / fails on non-fn | covered | *Step 1* acceptance |
| Step 2 — `isClientComponent` Node+Erlang cells | different decision → appended | *Mechanism § The marker* (no runtime registry), *Step 5* contract table (front 68) |
| Step 2 acceptance — cells for both targets; true for annotated | different decision → appended | *Step 4* acceptance (Node cells only; no Erlang cell) |
| Step 3 — `renderClientComponent(name, props)` with `data-jhonstart-client`/`-props` | different decision → appended | *Mechanism § The placeholder*, *Step 3* (`clientMount`, `data-onze-i`, payload `i` row) |
| Step 3 acceptance — placeholder divs; carries name + props | different decision → appended | *Step 3* acceptance (id only on element) |
| Step 4 — test with nested `#[client] fn` + `assert true` | different decision → appended | *Test plan* item 1 (`__jhClient_X() == "X"`) |
| Step 4 acceptance — pass on commonJS + erlang | different decision → appended | *Test plan* (commonJS gate; one erlang assertion on pure fns) |
| Gate — `botopink test` green | covered | *Definition of done* last box |
| Gate — `client.bp` in `botopink.json` and `root.bp` | covered (front 94 owns the edit) | *Step 5*, *Definition of done* box 1 |
| Gate — AGENTS.md updated | covered | *Step 5* acceptance |
| Gate — commit on `fix/jhonstart-client-directive` | absent → appended | appendix § Gate — branch name |
| Blast radius — new file, no existing-file changes; opt-in via `#[client]` | covered (quoted for record) | header *Does not touch*, *Mechanism* |
| Notes — hydration not implemented here | different decision → appended | *Step 4* (`hydrate()`, `propsFor` cells; front 68 entry) |
| Notes — convention, compiler unaware | covered | *What this front is not*, *Problem* para 4 |
| Notes — future deprecation for native `'use client'` syntax | absent → appended | appendix § Notes |
| overview.md front row (high · jhonstart · jhonstart-core · 'use client' boundary) | partially covered → reference row appended | header; module column not restated |
| overview.md Next.js mapping row ('use client' → `#[client]` decorator / convention) | covered → reference row appended for record | *Mechanism § The marker* |
| fronts.md ownership row (`src/client.bp`, `test/client_test.bp`) | covered → reference row appended for record | header *Owns* |
| fronts.md conflict-matrix row / Phase-2 ordering | absent → reference row appended | header *Wave 3* + *Depends on* replace them |
| examples-bp.md — Counter with state (module-level `#[client]` before imports) | different form, partially covered by `like-button-client-example.bp` → `carried-counter-client-state-example.bp` | module-level placement of `#[client]` and zero-param form are not in any new example |
| examples-bp.md — Timer with `use effect` / `setInterval` | not in new examples → `carried-timer-client-effect-example.bp` | no new example uses `effect` |
| examples-bp.md — DashboardPage mixing direct call + await | not in new examples → `carried-dashboard-mixed-server-client-example.bp` | `theme-provider-example.bp` covers mixing via `clientMount`, not via direct call |

Appended items: 11 subsections + 1 reference-row table (5 rows). Example files written: 3 (Counter kept because the module-level `#[client]` placement and zero-param shape are a distinct form; Timer and Dashboard have no counterpart in the new `examples/`).

### F06 jhonstart-streaming → Front 30 — absorption summary

| Old section (`1.0.7-beta/06-jhonstart-streaming/README.md`) | Verdict | Where in new (`1.0.10-beta/04-jhonstart/30-jhonstart-streaming/README.md`) |
|---|---|---|
| Header · Next.js reference (Streaming, Loading UI) | covered | *Reference* line (both URLs) |
| Header · Priority high | covered | *Priority* |
| Header · Depends on F04 | covered | *Depends on:* 28 (+ 02, 23, 94) |
| Header · Owns `streaming.bp`, `suspense.bp` | covered | *Owns* (+ `test/streaming_test.bp`) |
| Header · Does not touch router/link/server/client/element/hooks | covered | *Does not touch* |
| Problem | covered | *Problem* |
| Current state · `renderToString` synchronous | covered | *Current state* bullet 1 |
| Current state · no `<Suspense>` concept | covered | *Problem* para 2 |
| Current state · no `loading.bp` convention | covered | *Problem* para 3, *Mechanism › `loading.bp`* |
| Current state · `#[@future]` await blocking | covered | *Current state* bullets 3, 5 (eager `@Future`) |
| Exemplos em bp · Suspense com fallback (`SuspenseProps`, `children: [await PostList()]`) | different decision → appended | `Boundary` thunk, *Mechanism › What makes it actually stream* |
| Exemplos em bp · `loading.bp` with `emilia([.Bg.Gray100])` | absent (emilia styling) → appended + example file | convention itself in *Mechanism › `loading.bp`*, `examples/loading-convention-example.bp` |
| Mechanism · `Suspense` wraps component + fallback; SSR renders fallback; content streamed/hydrated later | different decision → appended | *Mechanism › The erlang half*, *The js half* |
| Step 1 · `SuspenseProps`/`Suspense(props)`, `data-jhonstart-suspense`/`data-jhonstart-fallback` | different decision → appended | Step 1 (`Boundary`, `Suspense(b)`, `data-onze-h`, `holeId`) |
| Step 1 · acceptance (compiles / children with fallback metadata / data attributes) | different decision → appended | Step 1 acceptance (child absent from shell) |
| Step 2 · `loading.bp` convention, file router wraps `page.bp` | covered | *Mechanism › `loading.bp`* (front 22 discovers, front 23 wraps) |
| Step 2 · acceptance (documented / F14 wires it) | covered | *Mechanism › `loading.bp`*, Step 4 |
| Step 3 · streaming render deferred to rakun F09 | different decision → appended | *Mechanism › The erlang half* ("Ordering and flushing are front 23's"), Step 4 flush contract |
| Step 4 · test asserting children rendered | different decision → appended | *Test plan* item 1 (fallback, not child) |
| Step 4 · acceptance "commonJS + erlang" | different decision → appended | *Target: erlang*, *Test plan* (no js row) |
| Gate · `botopink test` green | covered | *Definition of done* last item |
| Gate · `suspense.bp` in `botopink.json` + `root.bp` | covered | Step 5 (handed to front 94) |
| Gate · AGENTS.md updated | covered | Step 5 acceptance |
| Gate · Commit on `fix/jhonstart-streaming` | absent → appended | — |
| Blast radius · new files only, consumers use `Suspense` | covered | *Does not touch*, *Mechanism* |
| Notes · full streaming is rakun F09 | different decision → appended | front 23 owns flushing |
| Notes · SSR renders fallback + children together, client swaps | different decision → appended | *Current state* last bullet (rejected) |
| examples-bp.md § F06 · Suspense com fallback | not equivalent → example file | `30-examples/carried-suspense-fallback-example.bp` |
| examples-bp.md § F06 · loading.bp automático (emilia) | not equivalent → example file | `30-examples/carried-loading-emilia-example.bp` |
| examples-bp.md § F06 · Streaming granular (two boundaries) | not equivalent → example file | `30-examples/carried-granular-streaming-example.bp` |
| overview.md · front table row | covered | header block |
| overview.md · `loading.tsx` → `loading.bp` mapping | covered | *Mechanism › `loading.bp`* |
| overview.md · app tree root `loading.bp` "Global loading UI" | absent → appended (reference rows) | — |
| overview.md · app tree nested `loading.bp` | covered | per-segment `Boundary` |
| fronts.md · ownership row (src + `test/streaming_test.bp`) | covered | *Owns* |
| fronts.md · conflict matrix F06 row | covered | *Does not touch* |
| fronts.md · Phase 2 parallel scheduling | different decision → appended (reference rows) | *Wave: 3* |

Appended items: 8 subsections (7 quoted items + reference-rows table with 8 rows, of which 1 absent and 1 different decision). Example files written: 3. Skipped as already present in substance: 0.

### F07 jhonstart-error-boundaries → Front 31 — absorption summary

| Old section (`1.0.7-beta/07-jhonstart-error-boundaries/README.md`) | Verdict | Where in new (`1.0.10-beta/04-jhonstart/31-jhonstart-error-boundaries/README.md`) |
|---|---|---|
| Header · Next.js reference (Error Handling, error.js, not-found.js) | covered | *Reference* line (all three URLs) |
| Header · Priority high | covered | *Priority* |
| Header · Depends on F04 | covered | *Depends on:* 28 (+ 03, 94, 17, 24, 63) |
| Header · Owns `error_boundary.bp` | covered | *Owns* (+ `test/error_boundary_test.bp`) |
| Header · Does not touch router/link/server/client/suspense/element/hooks | covered | *Does not touch* |
| Problem | covered | *Problem* |
| Current state · no boundary mechanism | covered | *Current state* bullet 1 |
| Current state · errors propagate and crash render | covered | *Problem* para 1 |
| Current state · no `error.bp`/`not-found.bp` conventions | covered | *Problem* para 2 |
| Exemplos em bp · `error.bp` with `#[client]`, `Error(error, retry)`, `onClick` retry | different decision → appended + example file | *The three file conventions* (`ErrorPage(info)`), *`reset` / `retry`* (`data-onze-reset`) |
| Exemplos em bp · `notFound()` in server component (`Dict` params, `post == null`) | different decision → appended + example file | *Navigation signals are not errors*, `examples/not-found-example.bp` (`throw notFound()`) |
| Mechanism · `ErrorBoundary` wraps children, catches render errors | different decision → appended | *The erlang half* (`case` over `@Result`) |
| Mechanism · `error.bp` per segment via file router | covered | *The three file conventions* row 1, front 22/23 |
| Mechanism · `not-found.bp` 404 UI | covered | conventions table row 2 |
| Mechanism · `global-error.bp` root-level | covered | conventions table row 3 (`htmlTag`/`body`) |
| Mechanism · code `ErrorBoundary(props)` with `data-jhonstart-error-boundary`; client catches runtime errors | different decision → appended | Step 2 (`wrap`, `data-onze-e`), *The js half* rule 1 |
| Step 1 · `ErrorBoundaryProps(fallback: fn(error: string), children)` | different decision → appended | Step 1 (`ErrorInfo`, `ErrorBoundary` record) |
| Step 1 · `NotFoundBoundary` / `data-jhonstart-not-found-boundary` | absent → appended | — (single boundary type; front 23 renders `not-found.bp`) |
| Step 1 · acceptance (compile / children with metadata) | different decision → appended | Step 1/2 acceptance |
| Step 2 · `error.bp` exports `fn Error() -> Element` | different decision → appended | `ErrorPage(info: ErrorInfo)` + shadowing rationale |
| Step 2 · `not-found.bp` exports `fn NotFound() -> Element` | covered | conventions table row 2 |
| Step 2 · `global-error.bp` must include `<html>` and `<body>` | covered | conventions table row 3, Step 5, DoD |
| Step 2 · example `app/blog/error.bp` (`Error()` with h1/p) | different decision → appended | `examples/segment-error-example.bp` (`ErrorPage`) |
| Step 2 · acceptance (documented / F14 wires it) | covered | Step 5, front 22/23 |
| Step 3 · `notFound()` declared `#[@External.Node]` + `#[@External.Erlang]` | different decision → appended | *Current state* bullet 4 (front 63 owns), Step 3 (`isSignal`) |
| Step 3 · acceptance "throws an error the boundary catches" | different decision (reversed) → appended | Step 3 acceptance (signal not caught) |
| Step 4 · test `ErrorBoundary renders children` | different decision → appended | *Test plan* items 1–7 |
| Step 4 · acceptance "commonJS + erlang" | different decision → appended | *Target: erlang*, *Test plan* (js row is front 29's) |
| Gate · `botopink test` green | covered | *Definition of done* last item |
| Gate · `error_boundary.bp` in `botopink.json` + `root.bp` | covered | Step 5 (handed to front 94) |
| Gate · AGENTS.md updated | covered | Step 5 acceptance |
| Gate · Commit on `fix/jhonstart-error-boundaries` | absent → appended | — |
| Blast radius · new file only, consumers use boundaries | covered | *Does not touch*, *Mechanism* |
| Notes · SSR catch + client runtime catch | covered | *The erlang half*, *The js half* |
| Notes · `notFound()` special error, file router renders `not-found.bp` | covered | *Navigation signals are not errors* (front 23) |
| examples-bp.md § F07 · error.bp por segmento | not equivalent → example file | `31-examples/carried-segment-error-client-example.bp` |
| examples-bp.md § F07 · not-found.bp (emilia + `Link("/blog", …)`) | not equivalent (emilia styling, old `Link` signature) → example file | `31-examples/carried-not-found-emilia-example.bp`; substance partly in `examples/not-found-example.bp` |
| examples-bp.md § F07 · notFound() em server component | not equivalent → example file | `31-examples/carried-not-found-server-component-example.bp` |
| overview.md · front table row | covered | header block, conventions table |
| overview.md · `error.tsx` → `error.bp`, `not-found.tsx` → `not-found.bp` mappings | covered | conventions table |
| overview.md · app tree root `error.bp` "Global error boundary" | different decision → appended (reference rows) | `global-error.bp` |
| overview.md · app tree root `not-found.bp` "Global 404" | absent → appended (reference rows) | — |
| overview.md · app tree nested `[slug]/not-found.bp` | covered | `examples/not-found-example.bp` |
| fronts.md · ownership row (src + `test/error_boundary_test.bp`) | covered | *Owns* |
| fronts.md · conflict matrix F07 row | covered | *Does not touch* |
| fronts.md · Phase 2 parallel scheduling | different decision → appended (reference rows) | *Wave: 3* |

Appended items: 6 subsections (5 quoted items + reference-rows table with 10 rows, of which 1 absent and 2 different decision). Example files written: 3. Skipped as already present in substance: 0 (the not-found.bp snippet was carried for its emilia styling and old `Link` signature, though its page substance is in `examples/not-found-example.bp`).

### 1.0.7 F08 jhonstart-metadata → 1.0.10 04-jhonstart/32-jhonstart-metadata

| Old section (1.0.7 F08 README) | Verdict | Where in new |
|---|---|---|
| Header — Next.js reference | covered | header **Reference** |
| Header — priority medium / depends F04 / owns `metadata.bp` / does-not-touch | covered | header (depends widened to 28 · 01 · 26 · 66; owns adds `test/metadata_test.bp`) |
| Problem | covered | *Problem* |
| Current state (no API, no head tags, `renderToString` body only) | covered | *Current state*, *Problem* ¶1 |
| Examples — static `pub val metadata: Metadata` | different decision → appended | *Mechanism › Exports are functions, both of them* |
| Examples — `generateMetadata(params: Dict<string,string>)` | different decision → appended | *Mechanism* line 64 (`params, parent`; `Array<#(string,string)>` + `pairValue`) |
| Mechanism — bullets (static/dynamic export; SSR renders into `<head>`) | covered | *Mechanism*; "Front 23 splices the returned string" |
| Mechanism — code with both exports in one `page.bp` | different decision → appended | "Exporting both is a front-23 error" |
| Step 1 — record set (`type`, no `siteName`/`titleTemplate`; TwitterCard value comment) | covered with different decision → appended | Step 1 (`ogType`, `siteName`, `titleTemplate`) |
| Step 1 acceptance — "All fields are optional" | different decision → appended | *The record, and the absence convention*; *Language gaps* row 3 |
| Step 2 — `collectMetadata()` host cell | different decision → appended | *Current state* ("Both are dropped") |
| Step 3 — `renderMetadataToHtml` | different decision → appended | `renderHead`, *Rendering the head*, Step 3 |
| Step 4 — test + "commonJS + erlang" | different decision → appended | *Test plan* (erlang only; "There is no js row") |
| Gate — `botopink test`, manifest/root, AGENTS.md | covered | Step 5, *Definition of done* (root/files handed to 94) |
| Gate — branch `fix/jhonstart-metadata` | absent → appended (table row) | — |
| Blast radius | covered | header, *Mechanism* |
| Notes — F09 calls `collectMetadata`, injects into `<head>` | covered with different decision | front 23 resolves by name, splices string |
| Notes — `generateMetadata` async because it fetches | covered | *Mechanism* ¶1, example header |
| examples-bp.md § F08 — Metadata estático | not equivalent → file written | `32-examples/carried-static-metadata-example.bp` |
| examples-bp.md § F08 — Metadata dinâmico | not equivalent (Dict params, co-located component, `type:`) → file written | `32-examples/carried-dynamic-metadata-example.bp` |
| overview.md:14 front row ("OG images") | different decision → reference table | front 66 file routes |
| overview.md:151 `generateMetadata` mapping | covered | *Mechanism* |
| overview.md:152 `ImageResponse (OG)` → jhonstart + onze13 | different decision → reference table | front 66 (rakun) |
| overview.md:84 "decorator-based metadata" | different decision → reference table | named exports |
| fronts.md:14 ownership row | covered | header **Owns** |
| fronts.md:76,87 Phase 3 | covered | Wave 3 |

Appended items: 9 subsections (8 quoted + gate table) + 1 reference table (6 rows). Example files written: 2.

### 1.0.7 F16 emilia-jhonstart-integration → 1.0.9 48-emilia-attributes (emilia) / 1.0.10 04-jhonstart/94-jhonstart-element-surface (jhonstart)

| Old section (1.0.7 F16 README) | Verdict | Where in new |
|---|---|---|
| Header — Next.js CSS reference, Tailwind analog | covered by 48 | 48 header **Reference** |
| Header — priority high / depends F15 / owns `html_hook.bp` + `html_attrs.bp` / does-not-touch | covered by 48 (F15 folded in) | 48 header **Owns**, **Replaces** |
| Problem — `<div [emilia]={…}>` in the html DSL | different decision → appended (94) | 48 *html_hook.bp*, *Blocked* row 2 |
| Current state — static attrs, "no dynamic attribute syntax", no emilia | covered by 48, corrected | 48 *Current state* (`[class]={expr}` exists), *Blocked* row 3 |
| Mechanism — `[name]={expr}` extension + lowering to `#("class", emilia([...]))` | different decision → appended (94) | 48 *html_hook.bp* (pre-bound `val`, `[class]={c}`) |
| Exemplos em bp — `[emilia]` README example | different decision → appended (94) | — |
| Step 1 — html DSL handler registry (lookup by name, pass expr) | absent from both → appended (94) | `html.bp:240` lowers to `bracketPair` unconditionally |
| Step 2 — `registerEmiliaHandler()` in `emilia/src/html_hook.bp` | different decision, emilia-owned, covered by 48 — not appended | 48 Step 3 (`cls`, `clsWith`) |
| Step 3 — `html_attrs.bp` "bridge / handler registration" | different decision → appended (94), cites 48 | 48 Step 4 (emilia-unaware; imports only `element`) |
| Step 4 — `test "html DSL supports [emilia] attribute"`, both targets | different decision → appended (94) | 48 Step 5, *Test plan* (`integration_test.bp`, both targets) |
| Gate — `botopink test`, files in place, DSL works, AGENTS.md both repos | covered by 48 | 48 *Definition of done* |
| Gate — branch `fix/emilia-jhonstart-integration` | absent, procedural, front replaced by 48 — not appended | — |
| Blast radius | covered by 48 | 48 header, *Current state* |
| Notes — two repos, coordination | covered by 48 | 48 header; 1.0.9 fronts.md:203-205, 247 |
| Notes — generic handlers for other libs; future data/ARIA handlers | absent from both → appended (94) | — |
| examples-bp.md § F16 — Atributo [emilia] no html DSL | not equivalent → file written (48 `examples/` is empty; its README cites a missing `attributes-example.bp`) | `94-examples/carried-emilia-attribute-html-dsl-example.bp` |
| examples-bp.md § F16 — Responsivo com modifiers | not equivalent → file written | `94-examples/carried-responsive-modifiers-example.bp` |
| fronts.md:22 ownership row | covered by 48; `pub mod html_attrs;` missing from 94's merged `root.bp` listing → appended (94) | 48 Step 4 vs 94 *The two shared files* |
| fronts.md:61 conflict note F15 ↔ F16 | covered (moot) → reference table | 1.0.9 overview.md:21 |
| fronts.md:103 rule 2 "emilia requires jhonstart (for Element type)" | emilia-owned, absent from 48 — not appended | — |
| overview.md:22 front row | covered by 48 → reference table | 1.0.9 overview.md:21, 186 |
| overview.md:80 single cross-repo exception | covered → reference table | 1.0.9 overview.md:289 |
| overview.md:153 Tailwind → emilia Token enum | emilia-owned, covered by 48 reference | 48 header |
| overview.md:154 CSS Modules → emilia scoped classes | emilia-owned, absent from 48 — not appended | — |
| fronts.md:76,87 Phase 3 | covered | 48 wave 2 |

Appended items: 7 subsections + 1 reference table (5 rows). Example files written: 2. Emilia-owned, absent from 48, not appended: 3 (`registerEmiliaHandler` role, `emilia requires jhonstart` manifest rule, CSS Modules mapping).

## 6 · The `use` rename sweep (2026-09-20)

[`00-compiler-carry-over/19-use-activation`](../00-compiler-carry-over/19-use-activation/README.md) states the rule: a hook is `pub fn <noun>(…) -> @Context<Owner, R>` with no `use` prefix in its name; `use <noun>(…)` activates it; the plain call is the server-pass value. Applied across this track — 17 doubled `use`-plus-`use<Noun>()` sites → 0. The Next.js names survive only where the text names Next's API as the reference (§ 4 rows, `## Carried from 1.0.7-beta` headings and quotes, the *Reference gaps* sections, upstream URLs), each marked `[now …]` at its first occurrence.

| Old name | New name | Files touched |
|---|---|---|
| `useRouter` | `router` | `26/README.md` (Step 3, § Carried — both example blocks respelled, binding `router` → `r`), `26/examples/carried-programmatic-navigation-example.bp`, `26/examples/carried-route-params-example.bp`, `modules.md` |
| `usePathname` | `pathname` | `26/README.md`, `26/examples/active-nav-example.bp`, `modules.md`, `test-snap-examples.md` |
| `useParams` | `params` | `26/README.md`, `modules.md` |
| `useSearchParams` | `searchParams` | `26/README.md`, `26/examples/search-params-example.bp`, `modules.md` |
| `useSelectedLayoutSegment(s)` | `selectedLayoutSegment(s)` | `26/README.md`, `26/examples/active-nav-example.bp`, `modules.md`, `test-snap-examples.md` |
| `useLinkStatus` | `linkStatus` | `27/README.md`, `27/examples/pending-link-example.bp`, `modules.md`, `test-snap.md`, `test-snap-examples.md` |
| `useFormStatus` | `formStatus` | `67/README.md`, `67/examples/optimistic-like-example.bp`, `29/README.md`, `modules.md`, `test-snap.md`, `README.md` (graph) |
| `useOptimistic` | `optimistic` | `67/README.md`, `67/examples/optimistic-like-example.bp` (now `val #(shown, push) = use optimistic(…)`), `modules.md`, `README.md` (graph) |
| `useActionState` | `actionState` | `67/README.md`, `67/examples/create-post-form-example.bp`, `29/README.md`, `modules.md`, `test-snap.md` (case name + `.snap` path), `README.md` (graph) |
| helper `actionState(message)` | `newActionState(message)` | `67/README.md` (Step 1 + § *Naming under the `use` rule*), `67/examples/create-post-form-example.bp`, `modules.md`, `test-snap.md` — the hook took the noun |

Not renamed, and why: `26/README.md:20`, `:42` quote `router.d.bp`'s current header and cells (the file being replaced); § 4 rows here name Next's API; `67/README.md` **Reference:** line names `NEXTJS-DOCS.md`'s section titles; upstream URLs.

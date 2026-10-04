# Front 22 — The app router: page `Request`, handlers, regeneration, the dynamic mark, spans, actions

**Priority:** critical — onze 49/53 (actions, prerender, page `Request`) and jhonstart 27/32 wait
here; the member is every onze application's server half · **State:** not started
**Depends on:** 128 (logger and span API are the core's after it — decision 187) · 04 step 5 (core
`Request`'s `rawQuery()`, `headerNames()`, `headers()`, `queryDict()`) · `rakun-app` consumer
commits of `03-bundled-libs/102` step 3 and `103` step 2, before 128 (decision 188) · decision 186
(step 4; its checker capability for the final state) · onze 50 (R24-1), onze 53 and jhonstart 30
(R24-2) · jhonstart 32 (R64-2 and 66's two boxes — rakun owns nothing in them) · lg2-q (`@Decl`
source location — segment stays an explicit argument) · 03r-m … 03r-q (confirmations)
**Owns:** `modules/rakun-app/**` · `repository/rakun/AGENTS.md` § The file-convention route table,
§ SSR, § Actions
**Does not touch:** `modules/rakun-web/**` (65's; chain consumed through its API) · `rakun-cache`
(12's) · core's `src/logging/**` (17's; called, not edited) · `repository/{onze,jhonstart}/**` ·
after this front, while their front holds them: `src/i18n.bp`'s cookie and q-value lines (104) and
generic half (105), `src/static_gen.bp`'s `StaticParams` column (`08-bpp/117`), new
`src/server_islands.bp` (120) and `src/typed_action.bp` (127) · 130's decision-216 sites in
`src/{route_handler,actions}.bp` (track README § Order)

## Goal

Page `Request` exposes the core's headers and raw query; a root `middleware.bp` runs in the chain;
handlers asserted under the `Handler` phase and inside the chain; a failed regeneration logged via
the core's logger; the i18n redirect keeps the query byte for byte; rakun's own reads never mark a
page dynamic; `render` / `action` / `handler` spans emitted; refresh envelope uses `refreshValue()`.

## Mechanism

- **R62-3.** `ssr.bp`'s page request delegates `headerNames()`, `headers()`, `queryDict()`,
  `rawQuery()` to the core frame (04 step 5); onze-server hardcodes `[]` today.
- **R22-1.** `file_router.bp`'s scan records a root `middleware.bp` (beside `botopink.json`, not
  under `appDir`) in `ScanReport.middleware`; nothing reads it yet. Boot registers the file's
  exported entry through `rakun-web`'s `registerMiddleware`; hand-off asserted through
  `fixtures/middleware`; what runs in the file is 65's chain.
- **R25-3/4.** Handlers dispatched by `rkDispatchHttp` after the chain; `OPTIONS` without an
  `#[optionsRoute]` (`route_handler.bp` `optionsRoute`) falls to the chain's CORS entry. Asserted
  over `fixtures/routing` with a recording filter.
- **R60-1.** `static_gen.bp` logs a failed regeneration once through the core's logger with the
  request id (today: standard error and `regenerationFailures()`).
- **R64-1.** `i18n.bp`'s redirect appends `rawQuery()` verbatim, not a query rebuilt from decoded pairs.
- **R23-1 (decision 186).** Comptime vs per-request render is a compile-time fact: a page reaching a
  `#[serverOnly]` hook through `use` renders per request; the build writes each route's kind into
  `routing`'s `k` blob (`pattern|S|D`); `static_gen.bp` only reads it. Until the checker capability
  lands (`language-gaps.md`, `01-compiler/01-checker`) the bridge is
  `ChunkWriter.markDynamic(reason: string) -> i32`, called by the renderer, `static_gen.bp` reading only explicit marks;
  `rakun_ssr.erl`'s implicit `markDynamic(<<"searchParams">>)` on a query read deleted. The bridge
  goes with jhonstart's own `markDynamic` when the capability lands.
- **R11-7.** Span API is the core's after 128, so the manifest (`rakun`, `rakun-web`, `rakun-cache`)
  gains no edge; `ssr.bp`, `actions.bp`, `route_handler.bp` wrap renderer, action body and handler
  body in `startSpan(name, attrs)` / `endSpan`, imported from `rakun`.
- **R24-2.** `actions.bp` imports `refreshValue` from bundled `actions`; `actions_test.bp` still
  passes the literal `"refresh"` (`scripted("refresh", "")`).

No env-gated cell. R24-1, R24-2 depend on onze 50 / 53 and jhonstart 30; stay open, named.

## Open

### Step 1 — The page `Request` and the scan hand-off (R62-3, R22-1)

- [ ] `ssr_test.bp`: a `PageRenderer` receiving a request with two headers and `?a=1&b=%20` reads `headerNames()` (both), `headers()` (both values), `queryDict()` (`a=1`, `b= `), `rawQuery()` (`a=1&b=%20`)
- [ ] `file_router_scan_test.bp`: `fixtures/middleware` (root `middleware.bp`, no `pub mod` naming it) — a request through the app runs the file's entry (a header it sets is on the response); `fixtures/routing` (no root file) registers nothing, chain length unchanged

### Step 2 — Handlers (R25-1 … R25-4)

- [ ] `route_handler_test.bp`: inside a handler `requestPhase()` is `Handler`, previous phase restored after; a dispatch copy without `setPhase` makes `revalidateTag` inside the handler raise (negative case, via a test-only dispatcher flag)
- [ ] `fixtures/conflict-both` (`page.bp` + `route.bp`): the scan reports the segment, the handler registry holds nothing for it
- [ ] `OPTIONS /api/x` with no `#[optionsRoute]` answered by the chain's CORS entry (recording filter saw it, no handler ran); with one registered the handler runs, the filter's CORS arm does not
- [ ] a filter rejecting with 403 means a recording handler never ran

### Step 3 — Regeneration and i18n (R60-1, R64-1)

- [ ] `static_gen_test.bp`: a raising regeneration logged once through the core's logger with the request id (no sink); stale entry served; a later regeneration succeeds
- [ ] `i18n_test.bp`: the locale redirect for `/x?y=%20&z=a%2Fb#frag` is `/en/x?y=%20&z=a%2Fb`, byte for byte

### Step 4 — The dynamic mark, interim bridge (R23-1, decision 186)

Final state (decision 277): `static_gen.bp` reads the route's `S` / `D` from the `k` blob; the
interim boxes below hold until `05-jhonstart/26` step 8 lands.

- [ ] `ssr_test.bp`: a renderer reading `queryDict()` without `markDynamic` leaves the page static; one calling `markDynamic("searchParams")` makes it dynamic — through `static_gen.bp`'s decision
- [ ] `rakun_ssr.erl` has no implicit mark on any accessor (grep cell over the sidecar source)
- [ ] `AGENTS.md` § SSR states the rule and the `ChunkWriter` method; contract 5d in the milestone's `contracts.md` amended by the maintainer (named, not edited here)
- [ ] after `05-jhonstart/26` step 8: `static_gen.bp`'s "the trial render touched a dynamic API"
      reason deleted — the kind comes from the `k` blob; `ChunkWriter.markDynamic` deleted

### Step 5 — Spans (R11-7)

- [ ] `botopink.json` gains no dependency; `ssr_test.bp`, `actions_test.bp`, `route_handler_test.bp` each assert one span (`render`, `action`, `handler`) with the route as attribute, via the core's span test subscriber; with no subscriber nothing emitted

### Step 6 — Actions (R24-1, R24-2, RX-2, RX-13)

- [ ] `actions_test.bp`: literal `"refresh"` is `refreshValue()`; the envelope's `payload` parsed by bundled `actions`' contract-2 reader once jhonstart 30's reader is in `actions` — until then the cell asserts the pathname field by name and the box stays open naming 30
- [ ] R24-1: `actions_build_test.bp` compares field by field the registration record of a file with `pub val useServer = true;` and a decorated one — written now against a hand-attached directive in `fixtures/`, closes the day onze 50 attaches it
- [ ] RX-2 (60, 61, 64, 66): decorator-argument default re-measured in `segment_config_test.bp`, `i18n_test.bp`; README records the result
- [ ] RX-13: `actions_test.bp` and the `actions-cache` fixture spell no `__bp_action` / `X-Bp-Action` (onze's defaults, decision 114); `grep -rn '__bp_action\|X-Bp-Action' modules/rakun-app` empty

### Step 7 — file roles are the framework's (decision 285)

The compiler applies nothing by file name: an unfolded `page.bpp` is a plain `pub default fn`. The
file-convention route table (this member's) is generated at build from `routing`'s kinds (102,
171) and calls jhonstart's `page` / `layout` / … as comptime functions on each default function.

- [ ] the generated table: `pub val routes = comptime [layout("", rootLayout), page("blog/[slug]",
      blogSlugPage), …]`, one entry per app file, by `routing`'s `kindOf(path)`; no `bppKinds` read
- [ ] a route file whose name is no identifier (`not-found.bpp`) imported with an alias by the
      generated table (289); the import form for such a path segment stated here before landing
- [ ] a page's `S` / `D` from `@typeInfo(f).hooks` (277) through that call, the same as the decorator
      form; `onze build`'s report unchanged (`07-onze/49` step 5)

### Step 8 — no segment configuration — everything in `#[page]` (decision 290)

- [ ] `segment_config.bp`'s `dynamic` / `DynamicMode`, `fetchCache` / `FetchCache`,
      `registerSegmentConfig(seg, …)` and the layout-to-page inheritance (03r-o) deleted; nothing
      forces a stage (202) — `S` / `D` is `#[page]`'s, from `Decl.hooks` (277)
- [ ] `revalidate` and `dynamicParams` read from the page's `#[page]` meta (or the route table's
      `page(seg, f, …)` call, step 7); `static_gen.bp`'s regeneration and the unknown-param rule
      unchanged in behaviour; `segment_config_test.bp` and `static_gen_test.bp` rewritten to it

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-app`; `examples/rakun-ssr` still builds.

## Blast radius

Step 4 changes which pages are static under onze: today every page with a query read is dynamic,
after it only pages whose renderer marks. onze 49's `pageInput` must call `markDynamic` when
jhonstart's render reports `d` (`07-onze/49` step 5) — the bridge until decision 186's compile-time
kind replaces both. Step 1 widens the page `Request` additively; `examples/rakun-ssr` and
onze-server compile unchanged.

## Notes

- 03r-m (revalidation inside an action expires), 03r-n (a JSON-RPC argument is a form-encoded field
  list), 03r-o (segment config defaults), 03r-p (slot ownership), 03r-q (i18n in rakun-app)
  implemented; confirmation only.
- Ticked by another track: R64-2 (jhonstart 32 consumes `Alternate[]`), 66's "front 32 emits
  `<link rel="manifest" …>`" and "front 32 consumes `imagesFor` and `iconsFor`".
- Kept for open markers: `examples/route-handler-example.bp` (lg2-a, lg2-b),
  `verb-exports-carried-example.bp` (no export reflection).

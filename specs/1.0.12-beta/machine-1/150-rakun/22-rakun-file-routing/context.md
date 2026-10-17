# Front 22 — The app router: page `Request`, handlers, regeneration, the dynamic mark, spans, actions

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [150-rakun](../README.md): s1 → 150 s13 · s2 → 150 s13 · s3 → 150 s13 · s4 → 150 s13 · s5 → 150 s13 · s6 → 150 s13 · s7 → 150 s13 · s8 → 150 s13. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** critical — onze 49/53 (actions, prerender, page `Request`) and jhonstart 27/32 wait
here; the member is every onze application's server half · **State:** not started
**Depends on:** 128 (logger and span API are the core's after it — decision 187) · 04 step 5 (core
`Request`'s `rawQuery()`, `headerNames()`, `headers()`, `queryDict()`) · `rakun-app` consumer
commits of `03-bundled-libs/102` step 3 and `103` step 2, before 128 (decision 188) · decision 186
(step 4; its checker capability for the final state) · onze 53 and jhonstart 30
(R24-2) · jhonstart 32 (R64-2 and 66's two boxes — rakun owns nothing in them) · 403 (`@Decl` has no
source location — the segment an argument, from the generated route table, 285) · 03r-m, n, p, q (confirmations; 03r-o closed by 290 — step 8)
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

No env-gated cell. R24-2 depends on onze 53 and jhonstart 30; stays open, named. R24-1's directive is gone (282, 303 — step 6).

## Blast radius

Step 4 changes which pages are static under onze: today every page with a query read is dynamic,
after it only pages whose renderer marks. onze 49's `pageInput` must call `markDynamic` when
jhonstart's render reports `d` (`07-onze/49` step 5) — the bridge until decision 186's compile-time
kind replaces both. Step 1 widens the page `Request` additively; `examples/rakun-ssr` and
onze-server compile unchanged.

## Notes

- 03r-m (revalidation inside an action expires), 03r-n (a JSON-RPC argument is a form-encoded field
  list), 03r-p (slot ownership), 03r-q (i18n in rakun-app) implemented; confirmation only. 03r-o
  (segment config defaults) closed by 290: no segment config, inheritance gone (step 8).
- Ticked by another track: R64-2 (jhonstart 32 consumes `Alternate[]`), 66's "front 32 emits
  `<link rel="manifest" …>`" and "front 32 consumes `imagesFor` and `iconsFor`".
- Kept for open markers: `examples/route-handler-example.bp` (the byte gap — 346 —, lg2-b),
  `verb-exports-carried-example.bp` (no export reflection — under 282 that is the design, not a gap:
  a verb is a decorator, `pub fn GET` never a role by its name; its `language-gaps.md` row is to be
  re-read by the row's owner).

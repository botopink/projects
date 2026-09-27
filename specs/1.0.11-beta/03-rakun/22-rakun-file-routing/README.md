# Front 22 — The app router (`rakun-app`'s tail)

**Priority:** critical — onze 49/53 (actions, prerender, the page `Request`), jhonstart 27/32 (the static decision, `Alternate[]`) and the one-writer rule for the dynamic mark all wait here; the member is the server half of every onze application
**Carries:** 23 · 24 · 25 · 60 · 61 · 63 · 64 · 66 (61, 63, 66 files only)
**Depends on:** `04-rakun-erlang-runtime` step 1 (`rkReportFailure`, 03r-y) and step 5 (the core `Request`'s `rawQuery()`, `headerNames()`, `headers()`, `queryDict()`) · maintainer 03r-ai (the dynamic mark), 03r-aj (the span edge), 03r-m / 03r-n / 03r-o / 03r-p / 03r-q (confirmations) · onze 50 (R24-1's `useServer` directive), onze 53 and jhonstart 30 (R24-2's payload) · jhonstart 32 (R64-2 and 66's two boxes — rakun owns nothing in them) · compiler lg2-q (`@Decl` source location — the segment stays an explicit argument)
**Owns:** `modules/rakun-app/**` · `repository/rakun/AGENTS.md` § The file-convention route table, § SSR, § Actions
**Does not touch:** `modules/rakun-web/**` (65's; the chain is consumed through its API) · `rakun-cache` (12's) · `rakun-logging` (the sink is the core's) · `repository/onze/**`, `repository/jhonstart/**`

---

## Carried from 1.0.10

| Id | From (`specs/1.0.10-beta/03-rakun/`) | Box, as written |
|---|---|---|
| R22-1 | `22-rakun-file-routing/README.md` § Step 5 — Scan-time conflicts | "A `middleware.bp` at the **project root** — beside `botopink.json`, not under `appDir` — is discovered by the same scan that discovers `appDir`, with no `pub mod` line naming it, and is handed to front 07. The discovery is this front's; what runs in it is front 07's. A project with no root `middleware.bp` scans clean and registers nothing, which is the common case and …" — `file_router.bp:301-303` records the path in `ScanReport.middleware`; the hand-off to the chain is not asserted (`file_router_scan_test.bp:137`) |
| R23-1 | closed `status.md` L123 | "the dynamic mark has two writers … rakun's `markDynamic("searchParams")` fires on any read of the `Request`'s query" |
| R24-1 | `24-rakun-server-actions/README.md` § Step 1 — `#[serverAction]`, both spellings | "A file carrying `pub val useServer = true;` produces, for each of its `pub fn`s, the same registration record as the hand-written decorator — compared field by field, not by eyeball. — open: the directive is attached by `onze build` (onze front 50), which does not exist yet" |
| R24-2 | same § Step 6 — The JSON-RPC entry point and `router.refresh()` | "The header set to `refreshValue()` (`X-Bp-Action: refresh` …) returns an envelope whose `payload` parses as a contract-2 payload with the current pathname, and whose `state` is empty. — open: `actions_test.bp` … holds the envelope, the empty …" — the payload is contract 2, jhonstart 30's; the literal `"refresh"` at `actions_test.bp:365` is replaced by `refreshValue()` from the bundled `actions` |
| R25-1 | `25-rakun-route-handlers/README.md` § Step 2 — Reading the request | "`setPhase(RequestPhase.Handler)` is entered before the handler body and the previous phase is restored after. Removing the call makes a revalidation from a handler raise, and that negative case is the test." |
| R25-2 | same § Step 5 — Coexistence, precedence and the method-not-allowed answer | "`page.bp` and `route.bp` in one segment is a scan error naming the segment (the error text is front 22's; this front asserts the handler side registered nothing)." |
| R25-3 | same § Step 5 | "`OPTIONS` is answered by front 07's chain unless an `#[optionsRoute]` is registered for the segment, in which case the explicit handler runs and the chain does not." (`route_handler.bp:213` registers the explicit handler) |
| R25-4 | same § Step 5 | "A handler runs inside front 07's filter chain, so a filter that rejects the request means the handler is never entered — asserted by a handler that records having run." |
| R60-1 | `60-rakun-static-generation/README.md` § Step 5 — Revalidation and single flight | "A regeneration that raises leaves the stale entry in place, logs once through front 17, and does not prevent a later regeneration from succeeding. — open: … the line goes to the node's standard error and `regenerationFailures()`, not through front 17 — rakun-app does not depend on rakun-logging" |
| R64-1 (filter half) | `64-rakun-i18n-routing/README.md` § Step 4 — The negotiation filter | "The redirect preserves the query string and the fragment-free remainder of the URL byte for byte. — open: the chain hands the query as decoded `name\tvalue` pairs, so the redirect rebuilds it" |
| R11-7 (the work) | `11-rakun-actuator/README.md` § Step 8 | "`render`, `action` and `handler` spans are emitted by fronts 23, 24 and 25 through this front's API, with no second hook into the request path" — 03r-aj |
| R62-3 (the forwarding) | closed `status.md` L82 | the page `Request` handed to a `PageRenderer` exposes the core's `headerNames()` / `headers()` / `queryDict()` / `rawQuery()` |
| RX-2 | closed READMEs of 60, 61, 64, 66 | the "declared defaults" text — re-measure in `segment_config_test.bp` and `i18n_test.bp` |

Other track, ticked by them: R64-2 (jhonstart 32 consumes `Alternate[]`), 66's "Front 32 emits
`<link rel="manifest" …>`" and "Front 32 consumes `imagesFor` and `iconsFor`".

## Problem

Every onze request marks the page dynamic, because building `RequestData.query` reads the query
through rakun's marking accessor (`rakun_ssr.erl` `markDynamic`). The page `Request` cannot list
its headers or query, so `RequestData.query` / `.headers` are `[]` in onze-server. A root
`middleware.bp` is found and not handed to the chain. A handler is not asserted to run inside the
chain, nor under the `Handler` phase. A failed regeneration goes to standard error. The i18n
redirect re-encodes the query.

## Current state

`modules/rakun-app`: 14 test files + `fixtures/{actions-cache,conflict-both,conflict-roots,middleware,routing}`,
204 tests green; six sidecars. `file_router.bp:301` `val middlewarePath = …`, `:303`
`middleware: middleware` in `ScanReport`. `route_handler.bp:213` `optionsRoute` emits a
`registerRoute("OPTIONS", …)`. `static_gen.bp` keeps `regenerationFailures()`. `actions.bp:50`
imports `refreshValue` from `actions`; `actions_test.bp:365` still compares a literal `"refresh"`.
No `startSpan` call in the member; the manifest lists `rakun`, `rakun-web`, `rakun-cache`.

## Mechanism

- R22-1: `ScanReport.middleware` is read by the app's boot (`rkAppInstall`), which registers the
  file's exported chain entry through `rakun-web`'s `registerMiddleware` — the hand-off exists in
  the boot path; the test drives a request through `fixtures/middleware` and asserts the entry ran.
- R23-1 (03r-ai (a)): `ChunkWriter` gains `markDynamic(reason: string) -> i32`; `rakun_ssr.erl`'s
  implicit mark on query reads is deleted; `static_gen.bp`'s decision reads only explicit marks.
- R25-3/4: handlers are dispatched by `rkDispatchHttp` after the chain; `OPTIONS` without a
  registered handler falls to the chain's CORS entry. Both are assertions over `fixtures/routing`
  with a recording filter.
- R60-1: `static_gen.bp` calls `rkReportFailure("regeneration", requestId, text)` (03r-y).
- R64-1: `i18n.bp`'s redirect appends `rawQuery()` verbatim.
- R11-7: the manifest gains `rakun-actuator-api`; `ssr.bp` / `actions.bp` / `route_handler.bp` wrap
  the renderer, the action body and the handler body in `startSpan(name, attrs)` / `endSpan`.
- R62-3: `ssr.bp`'s page request delegates the four accessors to the core frame.

## Gate stance

No env-gated cell. R24-1 and R24-2 depend on onze 50 / 53 and jhonstart 30 and stay open, named,
until those land; they are not gated cells here.

## Steps

### Step 1 — The page `Request` and the scan hand-off (R62-3, R22-1)

**Acceptance:**
- [ ] `ssr_test.bp`: a `PageRenderer` receiving a request with two headers and `?a=1&b=%20` reads `headerNames()` (both), `headers()` (both values), `queryDict()` (`a=1`, `b= `), `rawQuery()` (`a=1&b=%20`)
- [ ] `file_router_scan_test.bp`: `fixtures/middleware` (a root `middleware.bp`) — a request through the app runs the file's entry (a header it sets is on the response); `fixtures/routing` (no root file) registers nothing and the chain length is unchanged

### Step 2 — Handlers (R25-1 … R25-4)

**Acceptance:**
- [ ] `route_handler_test.bp`: inside a handler `requestPhase()` is `Handler` and after it the previous phase is restored; a copy of the dispatch without `setPhase` makes `revalidateTag` inside the handler raise (the negative case, through a test-only flag on the dispatcher)
- [ ] `fixtures/conflict-both` (`page.bp` + `route.bp`): the scan reports the segment and the handler registry holds nothing for it
- [ ] `OPTIONS /api/x` with no `#[optionsRoute]` is answered by the chain's CORS entry (the recording filter saw it, no handler ran); with one registered the handler runs and the filter's CORS arm does not
- [ ] a filter that rejects with 403 means a recording handler never ran

### Step 3 — Regeneration and i18n (R60-1, R64-1)

**Acceptance:**
- [ ] `static_gen_test.bp`: a regeneration that raises calls the failure sink once with the request id; the stale entry is served; a later regeneration succeeds
- [ ] `i18n_test.bp`: the locale redirect for `/x?y=%20&z=a%2Fb#frag` is `/en/x?y=%20&z=a%2Fb`, byte for byte

### Step 4 — One writer for the dynamic mark (R23-1, 03r-ai)

**Acceptance:**
- [ ] `ssr_test.bp`: a renderer that reads `queryDict()` and never calls `markDynamic` leaves the page static; one that calls `markDynamic("searchParams")` makes it dynamic — asserted through `static_gen.bp`'s decision
- [ ] `rakun_ssr.erl` has no implicit mark on any accessor (a grep cell over the sidecar source)
- [ ] `AGENTS.md` § SSR states the rule and the `ChunkWriter` method; contract 5d's text in the milestone's `contracts.md` is amended by the maintainer (named, not edited here)

### Step 5 — Spans (R11-7, 03r-aj)

**Acceptance:**
- [ ] `botopink.json` lists `rakun-actuator-api`; `ssr_test.bp`, `actions_test.bp`, `route_handler_test.bp` each assert one span (`render`, `action`, `handler`) with the route as an attribute, through `rakun-actuator-api`'s test subscriber; with no subscriber nothing is emitted

### Step 6 — Actions (R24-1, R24-2)

**Acceptance:**
- [ ] `actions_test.bp:365`: the literal `"refresh"` is `refreshValue()`; the envelope's `payload` is parsed by the bundled `actions`' contract-2 reader (when jhonstart 30's reader is in `actions`; until then the cell asserts the pathname field by name and the box stays open naming 30)
- [ ] R24-1: when onze 50 attaches `pub val useServer = true;`, `actions_build_test.bp` compares the emitted registration record of a directive file with a decorated one field by field — written now against a hand-attached directive in `fixtures/`, so the box closes the day 50 lands
- [ ] RX-2: the decorator-argument default re-measured in `segment_config_test.bp` and `i18n_test.bp`; the README records the result

## Gate

- [ ] `botopink test --target erlang` green in `modules/rakun-app`; `examples/rakun-ssr` still builds
- [ ] `botopink format --check` clean
- [ ] `AGENTS.md` sections updated
- [ ] commit on `fix/22-rakun-file-routing`

## Blast radius

Step 4 changes which pages are static under onze: today every page with a query read is dynamic;
after it, only pages whose renderer marks are. onze 49's `pageInput` must call `markDynamic` when
jhonstart's render reports `d` — onze's half, named in the cross-track table. Step 5 adds a manifest
edge (acyclic: `rakun-actuator-api` → `rakun`). Step 1 widens the page `Request`; `rakun-ssr`
example and onze-server compile unchanged (additive).

## Notes

- 03r-m (revalidation inside an action expires), 03r-n (a JSON-RPC argument is a form-encoded
  field list), 03r-o (segment config defaults), 03r-p (slot ownership), 03r-q (i18n in rakun-app)
  are implemented; confirmation only.
- `examples/route-handler-example.bp` (lg2-a, lg2-b) and `verb-exports-carried-example.bp` (no
  export reflection) are copied here for their open markers.

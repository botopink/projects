# Front 11 — Actuator: Health, Info and the Endpoint Host (the host's tail)

**Priority:** medium — thirteen open boxes, five of which are the assertions of behaviour that already exists (`shutdown`, `traceparent`); the rest are the inventory endpoints operators read first
**Carries:** 76 · 87 (files only — no open box)
**Depends on:** `04-rakun-erlang-runtime` only if R11-5 needs a boot hook the core lacks (the front measures first; a needed hook is reported to 04, not written here) · `22-rakun-file-routing` for R11-7 (03r-aj: the spans are emitted in `rakun-app`; this front ticks the box when 22's test asserts them through this member's API)
**Owns:** `modules/rakun-actuator/**` · `modules/rakun-actuator-api/**` · `repository/rakun/AGENTS.md` § The actuator
**Does not touch:** `rakun-app` (22's), `rakun-client` (13's), the core

---

## Carried from 1.0.10

| Id | From (`specs/1.0.10-beta/03-rakun/11-rakun-actuator/README.md`) | Box, as written |
|---|---|---|
| R11-1 | § Step 5 — `beans`, `configprops`, `mappings` | "`configprops` lists every key front 05 registered, with the bound value and the source it came from" |
| R11-2 | § Step 5 | "`mappings` lists decorator routes and file-router routes, each labelled with its source" |
| R11-3 | § Step 6 — `startup` and boot-step timing | "`config.load`, `eager.init`, each `#[postConstruct]` and `listener.bind` all appear" |
| R11-4 | § Step 7 — `shutdown` | "`POST /actuator/shutdown` triggers front 07's drain sequence" · "Without front 76 granting access it answers 405, and it is never enabled by front 11's own default" · "A `GET` on it answers 405" · "The response is written before the listener stops accepting" — implemented by 76 in `src/management.bp` (`rakun_probes_shutdown`, `management.bp:257-263`); closes on tick once the four are asserted from this member's tests |
| R11-5 | § Step 8 — `instrumentation.bp` and spans | "`#[instrumentation]` runs before configuration is loaded and before any bean is constructed" |
| R11-6 | § Step 8 | "Front 13's outbound client sends `traceparent` carrying the current span" — closes on tick: `rakun-client/src/transport.bp:236-237` (`startSpan("http.client.request", …)`, `follow(out, traceparentOf(span), 0)`); the assertion is 13's `request_test.bp` |
| R11-7 | § Step 8 | "`render`, `action` and `handler` spans are emitted by fronts 23, 24 and 25 through this front's API, with no second hook into the request path" — 22's work under 03r-aj |
| R11-8 | § Definition of done | "`modules/rakun-actuator-api/` exists, depends on nothing, and is what fronts 08 · 09 · 12 · 15 · 16 · 17 · 18 · 77 · 85 import" · "`modules/rakun-actuator/` exists with the endpoint host, the health and info registries, the four registry-reading endpoints, `shutdown`, `instrumentation.bp` and the sidecar" · "Spans are emitted for request, render, action and handler, `:telemetry`-shaped, with W3C trace propagation, and cost nothing with no subscriber" |
| RX-1 | closed `status.md` L117 | `src/endpoint_host.bp:136` and `:152` — `?? EndpointResponse(…)` replaced by `if (x == null)` narrowing |

## Problem

`GET /actuator/configprops` answers keys without their source; `mappings` does not say which
router registered a route; `startup` has no named steps; `shutdown` exists (76) but the host's own
tests do not assert its four rules; nothing asserts that `#[instrumentation]` runs before
configuration loads.

## Current state

`modules/rakun-actuator`: 11 test files + `audit/` (2) + `exchanges/` (1), 77 tests green;
`modules/rakun-actuator-api`: 2 files, 10 tests green. `src/management.bp` (76) implements the
shutdown endpoint over `rakun_probes.erl`. `src/instrumentation.bp` registers `#[instrumentation]`
types at module load; when they run relative to `config.load` is not asserted.
`rakun-actuator-api` depends on `rakun` only — "depends on nothing" in the closed DoD reads "on no
rakun member but the core".

## Mechanism

- R11-1: 05's registry (`rkConfigSources()`) already records key, value and source for the
  catalogue (03r-c); `configprops` renders the value without the source. One field.
- R11-2: the route table (`rkRoutePaths()`) does not carry the registrar. The core's `registerRoute`
  takes a `source` tag (`"decorator"` / `"file"`) — a widening 04 owns; until it lands, `mappings`
  labels by the handler name prefix (`__rkHandler_`) — the front measures whether the prefix is
  enough and reports to 04 if not.
- R11-3: `startup` reads the boot event log 06 keeps (`rkBootSteps()`); the four names are the
  events `bootSequenceFor` already emits under other labels. Rename to the documented ones in the
  endpoint's rendering, not in the core.
- R11-5: `#[instrumentation]` types register at module load; `bootSequenceFor` runs them as event 0
  if the hook exists. The front asserts the order with a recorder; if the core runs them later, the
  fix is 04's and this box waits on it.

## Gate stance

No env-gated cell. Every box is asserted through `MockMvc` / the endpoint host in-process.

## Steps

### Step 1 — Inventory endpoints (R11-1, R11-2, R11-3)

**Acceptance:**
- [ ] `registry_endpoints_test.bp`: `configprops` lists every registered key with `value` and `source` (`application.yaml`, `env`, `default`), one entry per key
- [ ] `mappings` lists a decorator route and a file-router route, each with `source: "decorator" | "file"` — from `fixtures/` of the host, one of each
- [ ] `startup` answers `config.load`, `eager.init`, one `postConstruct:<Type>` per hook and `listener.bind`, each with a duration

### Step 2 — `shutdown` (R11-4, closes on tick)

**Acceptance:**
- [ ] `endpoint_test.bp`: `POST /actuator/shutdown` with 76 granting access calls the drain and the recorded order is "response written" before "listener stopped"
- [ ] without the grant it is 405; `GET` is 405; the default exposure does not include it

### Step 3 — Instrumentation and spans (R11-5, R11-6, R11-7, R11-8)

**Acceptance:**
- [ ] `instrumentation_test.bp`: an `#[instrumentation]` recorder runs before `config.load` and before any constructor — or the box is reported to 04 with the measured order
- [ ] R11-6 ticked with a pointer to 13's `request_test.bp` cell
- [ ] R11-7 ticked when 22's `ssr_test.bp` / `actions_test.bp` / `route_handler_test.bp` assert one span each through `rakun-actuator-api`
- [ ] `span_test.bp`: with no subscriber, 1 000 `startSpan`/`endSpan` pairs cost under 5 ms measured with `io.clock` (the "cost nothing" box, made measurable)
- [ ] the three DoD boxes ticked, the first reworded to "depends on the core only"

### Step 4 — Hygiene

**Acceptance:**
- [ ] `endpoint_host.bp:136,152` narrowed with `if (x == null)`; the two `EndpointResponse(status: 0 …)` dummies gone (RX-1)

## Gate

- [ ] `botopink test --target erlang` green in both members
- [ ] `botopink format --check` clean
- [ ] `AGENTS.md` § The actuator updated
- [ ] commit on `fix/11-rakun-actuator`

## Blast radius

`mappings` and `configprops` bodies gain a field each; onze's `ONZ-71` shutdown cells read
`POST /actuator/shutdown` and are unaffected by the assertions. If R11-2 needs the route registrar
tag, 04 widens `registerRoute` and every registrar passes the tag — a signature change 04 sequences.

## Notes

03r-t (keys under `rakun.management.*`) and 03r-u (the liveness allow-list) are implemented;
confirmation only.

# Front 11 — Actuator: inventory endpoints, `shutdown`, instrumentation and spans

**Priority:** medium — the inventory endpoints operators read first, and the assertions of behaviour
that already exists (`shutdown`, `traceparent`) · **State:** not started
**Depends on:** 128 (it moves the actuator API into the core) · 04 only if R11-5 needs a boot hook the
core lacks (measured first; a needed hook is reported to 04, not written here) · 22 for R11-7 (the
spans are emitted in `rakun-app` with no new edge — decision 187; this front ticks the box when 22
asserts them) · 03r-t / 03r-u (confirmations)
**Owns:** `modules/rakun-actuator/**` · `modules/rakun/src/actuator_api/**`, `test/actuator_api/**`,
`src/sidecars/rakun_actuator_api.erl` · `repository/rakun/AGENTS.md` § The actuator
**Does not touch:** `rakun-app` (22's), `rakun-client` (13's), the rest of the core (04's —
`botopink.json` and `src/root.bp` included) · 130's decision-216 sites in `src/actuator_api/**`
(track README § Order)

## Goal

`configprops` shows each key's source, `mappings` each route's registrar, `startup` the named boot
steps; `shutdown`'s four rules and `#[instrumentation]`'s order are asserted; the span cost is
measured; the closed DoD is ticked against the post-128 tree.

## Mechanism

- **R11-1.** `registry_endpoints.bp` `configpropsJson()` renders each key's value without the source
  it came from. The core's configuration (`src/config.bp`, the eight sources walked in order) knows
  which source supplied a key; the front measures whether that is readable from the host — if not,
  the accessor is a widening reported to 04 — and adds the field.
- **R11-2.** The route table (`rkRoutePaths()`) does not carry the registrar. The core's
  `registerRoute` would take a `source` tag (`"decorator"` / `"file"`) — a widening 04 owns; until it
  lands, `mappings` labels by the handler-name prefix (`__rkHandler_`, written by `rakun-app`'s
  `route_handler.bp`); the front measures whether the prefix is enough (130 may rename it) and
  reports to 04 if not.
- **R11-3.** `startup` (`instrumentation.bp` `startupRead`) renders `startupSteps()`, recorded by
  `timeStep(name, …)` around the boot's steps; the four documented names are given in the
  endpoint's rendering (or the `timeStep` labels), not in the core.
- **R11-4.** `src/management.bp` (76) implements `shutdown` over `rakun_probes.erl`
  (`rakun_probes_shutdown`); the box is the host's own assertion.
- **R11-5.** `src/instrumentation.bp` registers `#[instrumentation]` types at module load; the front
  asserts with a recorder that they run before `config.load`; if the core runs them later, the fix is
  04's and the box waits on it.

Every box is asserted through `MockMvc` / the endpoint host in-process; nothing is env-gated.

## Open

### Step 1 — Inventory endpoints (R11-1, R11-2, R11-3)

- [ ] `registry_endpoints_test.bp`: `configprops` lists every registered key with `value` and `source` (`application.yaml`, `env`, `default`), one entry per key
- [ ] `mappings` lists a decorator route and a file-router route, each with `source: "decorator" | "file"` — from the host's `fixtures/`, one of each
- [ ] `startup` answers `config.load`, `eager.init`, one `postConstruct:<Type>` per hook and `listener.bind`, each with a duration

### Step 2 — `shutdown` (R11-4, closes on tick)

- [ ] `endpoint_test.bp`: `POST /actuator/shutdown` with 76 granting access calls the drain, and the recorded order is "response written" before "listener stopped"
- [ ] without the grant it is 405; `GET` is 405; the default exposure does not include it

### Step 3 — Instrumentation and spans (R11-5 … R11-8)

- [ ] `instrumentation_test.bp`: an `#[instrumentation]` recorder runs before `config.load` and before any constructor — or the box is reported to 04 with the measured order
- [ ] R11-6 ticked with a pointer to 13's `request_test.bp` cell (`rakun-client`'s `transport.bp` sends `traceparent` from `startSpan("http.client.request", …)`)
- [ ] R11-7 ticked when 22's `ssr_test.bp` / `actions_test.bp` / `route_handler_test.bp` assert one span each through the core's span API
- [ ] `actuator_api/span_test.bp`: with no subscriber, 1 000 `startSpan`/`endSpan` pairs cost under 5 ms measured with `io.clock`
- [ ] R11-8's three DoD boxes ticked, the first reworded to "the actuator API lives in the core (`modules/rakun/src/actuator_api/**`, decision 187) and is what 08 · 09 · 12 · 15 · 16 · 17 · 18 · 77 · 85 import"; the other two ("`modules/rakun-actuator/` exists with the endpoint host, the health and info registries, the four registry-reading endpoints, `shutdown`, `instrumentation.bp` and the sidecar"; "spans for request, render, action and handler, `:telemetry`-shaped, with W3C propagation, costing nothing with no subscriber") as written

### Step 4 — Hygiene (RX-1)

- [ ] `endpoint_host.bp:136,152` narrowed with `if (x == null)`; the two `EndpointResponse(status: 0 …)` / `(status: 404 …)` dummies gone

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-actuator` and in `modules/rakun` (the `test/actuator_api/` files in the run).

Blast radius: `mappings` and `configprops` bodies gain a field each; onze's `ONZ-71` shutdown cells
read `POST /actuator/shutdown` and are unaffected. If R11-2 needs the registrar tag, 04 widens
`registerRoute` and every registrar passes it — a signature change 04 sequences.

# Front 11 — Actuator: inventory endpoints, `shutdown`, instrumentation and spans

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [150-rakun](../README.md): s1 → 150 s15 · s2 → 150 s15 · s3 → 150 s15 · s4 → 150 s15. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** medium — the inventory endpoints operators read first; assertions of existing
behaviour (`shutdown`, `traceparent`) · **State:** not started
**Depends on:** 128 (moves the actuator API into the core) · 04 only if R11-5 needs a boot hook the
core lacks (measured first; reported to 04, not written here) · 22 for R11-7 (spans emitted in
`rakun-app`, no new edge — decision 187; ticks when 22 asserts them) · 03r-t / 03r-u (confirmations)
**Owns:** `modules/rakun-actuator/**` · `modules/rakun/src/actuator_api/**`, `test/actuator_api/**`,
`src/sidecars/rakun_actuator_api.erl` · `repository/rakun/AGENTS.md` § The actuator
**Does not touch:** `rakun-app` (22's), `rakun-client` (13's), rest of the core (04's —
`botopink.json`, `src/root.bp` included) · 130's decision-216 sites in `src/actuator_api/**`
(track README § Order)

## Goal

`configprops` shows each key's source, `mappings` each route's registrar, `startup` the named boot
steps; `shutdown`'s four rules and `#[instrumentation]`'s order asserted; span cost measured; closed
DoD ticked against the post-128 tree.

## Mechanism

- **R11-1.** `registry_endpoints.bp` `configpropsJson()` renders values without their source. The
  core's configuration (`src/config.bp`, eight sources walked in order) knows the supplying source;
  measure whether the host can read it (else an accessor widening reported to 04), add the field.
- **R11-2.** Route table (`rkRoutePaths()`) lacks the registrar. The core's `registerRoute` would
  take a `source` tag (`"decorator"` / `"file"`) — 04's widening; until then `mappings` labels by the
  handler-name prefix (`__rkHandler_`, written by `rakun-app`'s `route_handler.bp`); measure whether
  the prefix is enough (130 may rename it), report to 04 if not.
- **R11-3.** `startup` (`instrumentation.bp` `startupRead`) renders `startupSteps()`, recorded by
  `timeStep(name, …)` around boot steps; the four documented names given in the endpoint's rendering
  (or `timeStep` labels), not in the core.
- **R11-4.** `src/management.bp` (76) implements `shutdown` over `rakun_probes.erl`
  (`rakun_probes_shutdown`); the box is the host's own assertion.
- **R11-5.** `src/instrumentation.bp` registers `#[instrumentation]` types at module load; a recorder
  asserts they run before `config.load`; if the core runs them later, the fix is 04's, the box waits.

Every box via `MockMvc` / the in-process endpoint host; nothing env-gated.

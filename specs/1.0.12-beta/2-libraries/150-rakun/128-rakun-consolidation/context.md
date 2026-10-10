# Front 128 — rakun consolidation: nine members move in with the member that needs them

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** critical — first of the track (decision 187); every other rakun front edits a member
it moves, an import it rewrites or a manifest it changes · **State:** steps 0–10 written as one patch
each (rakun is hooked; the coordinator lands them) — every box ticked
**Depends on:** rakun consumer commits of `03-bundled-libs/102` step 3
(`rakun-app/src/{file_router,static_gen}.bp`, `rakun-hateoas/src/hal.bp`) and `103` step 2
(`rakun-app/src/actions.bp`) landed first (decision 188) — not landed · no `01-compiler/130` rakun
commit in flight while open ([`../README.md`](../04-rakun/track.md) § Order, the 130 rule — decision 339)
**Owns:** while open, every member of `repository/rakun/modules/**`, `starters/**`, `examples/**`,
the workspace `botopink.json`, `modules/README.md`, `repository/rakun/AGENTS.md`,
`.github/workflows/` and `scripts/git-hooks/` where they list members · [`../modules.md`](../04-rakun/modules.md) · this directory
**Does not touch:** what any file *does* — a move changes a path, a `pub mod` line, a manifest, an
import, never a body · the core's `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp` (frozen) ·
`repository/botopink-lang/**`, `repository/{onze,jhonstart}/**`

No other rakun front holds a worktree while this is open.

## Goal

25 members → 16 (decision 187): core absorbs `rakun-actuator-api`, `rakun-logging`; `rakun-tx`,
`rakun-devtools` → `rakun-data`; `rakun-release` → `rakun-cli`; `rakun-hateoas` → `rakun-web`;
`rakun-ws` (SOAP) → `rakun-client`; `rakun-rsocket`, `rakun-stream` → `rakun-messaging`. The core
calls its own logger (no failure-report plugin — 187 over 184); `rakun-app` opens spans through
its existing dependency (03r-aj). `rakun-web`, `rakun-actuator` stay members. No test lost.

## Mechanism

| Merged member | Moves into | Its files after the move |
|---|---|---|
| `rakun-actuator-api` | `rakun` | `modules/rakun/src/actuator_api/**`, `test/actuator_api/**`, `src/sidecars/rakun_actuator_api.erl` |
| `rakun-logging` | `rakun` | `modules/rakun/src/logging/**`, `test/logging/**`, `src/sidecars/rakun_logging.erl` |
| `rakun-hateoas` | `rakun-web` | `modules/rakun-web/src/hateoas/**`, `test/hateoas/**` |
| `rakun-ws` | `rakun-client` | `modules/rakun-client/src/ws/**`, `test/ws/**`, `src/sidecars/rakun_ws.erl` |
| `rakun-tx` | `rakun-data` | `modules/rakun-data/src/tx/**`, `test/tx/**` |
| `rakun-devtools` | `rakun-data` | `modules/rakun-data/src/devtools/**`, `test/devtools/**`, `src/sidecars/rakun_devtools.erl` |
| `rakun-release` | `rakun-cli` | `modules/rakun-cli/src/release/**`, `test/release/**`, `src/sidecars/rakun_release.erl` |
| `rakun-rsocket` | `rakun-messaging` | `modules/rakun-messaging/src/rsocket/**`, `test/rsocket/**`, `src/sidecars/rakun_rsocket.erl` |
| `rakun-stream` | `rakun-messaging` | `modules/rakun-messaging/src/stream/**`, `test/stream/**`, `src/sidecars/rakun_stream.erl` |

Each merge, four edits:

1. **Files move** into a sub-directory named after the merged member — the shape of `sql/`,
   `pulsar/`, `jms/` (the tree's convention, not the decision's; step 0's export measurement can
   refuse it). Sidecar keeps file name and atom, so no `#[@External.Erlang]` template changes.
   `rakun-ws` keeps `ws/` (merged, not renamed).
2. **Absorber's `botopink.json` and `src/root.bp`** gain the `files` entries and `pub mod` lines,
   appended after its own, plus the merged member's missing dependencies (`rakun-cli` gains
   `rakun-web`; `rakun-messaging` gains `rakun-actuator`, `rakun-data`). Merged directory and
   manifest deleted.
3. **Every dependant's manifest** drops the merged name; every `import … from "rakun-<merged>"`
   names the absorber.
4. **The split's seams go**: no failure-report plugin; the span API is the core's.

Resulting members and graph: [`../modules.md`](../04-rakun/modules.md) § Members, § The graph; step 0's
baseline: below. Pulsar stays in `rakun-messaging/src/pulsar/` (274): `pulsar/**` moves with nothing.

## Blast radius

- Every rakun front sequences after this, at the new paths ([`../README.md`](../04-rakun/track.md) § Where a merged member's front works).
- Nine `test-libs` cells disappear (tests run in the absorber's cell); the restriction audit loses nine rows.
- `03-bundled-libs`' consumer files move: 17's logging files switched to `log` are
  `modules/rakun/src/logging/**`; `107-release` edits `modules/rakun-cli/src/release/release.bp`;
  102's `hal.bp` commit lands first and moves with the file; 130's landed `rakun-hateoas` edits likewise.
- `rakun-messaging` gains `rakun-actuator`, `rakun-data` (every messaging consumer loads the data
  member); `rakun-cli` gains `rakun-web`.

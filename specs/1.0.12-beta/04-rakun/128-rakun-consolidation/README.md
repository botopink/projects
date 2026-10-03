# Front 128 — rakun consolidation: nine members move in with the member that needs them

**Priority:** critical — the first front of the track (decision 187); every other rakun front edits
a member this one moves, an import it rewrites or a manifest it changes · **State:** not started
**Depends on:** the rakun consumer commits of `03-bundled-libs/102` step 3
(`rakun-app/src/{file_router,static_gen}.bp`, `rakun-hateoas/src/hal.bp`) and `103` step 2
(`rakun-app/src/actions.bp`), landed before it opens (decision 188) — not landed ·
no `01-compiler/130` rakun commit in flight while it is open ([`../README.md`](../README.md) § Order,
the 130 rule, to confirm)
**Owns:** while open, every member of `repository/rakun/modules/**`, `starters/**`, `examples/**`, the
workspace `botopink.json`, `modules/README.md`, `repository/rakun/AGENTS.md`, `.github/workflows/`
and `scripts/git-hooks/` where they list members · [`../modules.md`](../modules.md) · this directory
**Does not touch:** what any file *does* — a move changes a path, a `pub mod` line, a manifest and an
import, never a body · `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp` of the core (frozen) ·
`repository/botopink-lang/**`, `repository/{onze,jhonstart}/**`

No other rakun front holds a worktree while this one is open.

## Goal

The 25 members become 16 (decision 187): the core absorbs `rakun-actuator-api` and `rakun-logging`;
`rakun-tx` and `rakun-devtools` move into `rakun-data`, `rakun-release` into `rakun-cli`,
`rakun-hateoas` into `rakun-web`, `rakun-ws` (SOAP) into `rakun-client`, `rakun-rsocket` and
`rakun-stream` into `rakun-messaging`. With logging and the span API in the core, the core calls its
own logger (no failure-report plugin — 187 over 184) and `rakun-app` opens spans through the
dependency it has (03r-aj). `rakun-web` and `rakun-actuator` stay members. No test is lost.

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

Each merge is the same four edits:

1. **The files move** into a sub-directory named after the merged member — the shape `sql/`,
   `pulsar/`, `jms/` already have (the tree's convention, not the decision's; step 0's export
   measurement can refuse it). A sidecar keeps its file name and atom, so no `#[@External.Erlang]`
   template changes. `rakun-ws` keeps `ws/` (merged, not renamed).
2. **The absorbing member's `botopink.json` and `src/root.bp`** gain the `files` entries and `pub mod`
   lines, appended after its own, and the merged member's dependencies it lacks (`rakun-cli` gains
   `rakun-web`; `rakun-messaging` gains `rakun-actuator` and `rakun-data`). The merged directory and
   manifest are deleted.
3. **Every dependant's manifest** drops the merged name; every `import … from "rakun-<merged>"` names
   the absorbing member.
4. **The seams the split forced go with it**: no failure-report plugin; the span API is the core's.

The resulting members and graph are [`../modules.md`](../modules.md) § Members and § The graph; the
on-disk facts step 0 starts from are § On disk until 128 lands. The `rakun-pulsar` question (03r-ad,
91) is untouched: `pulsar/**` stays where it is.

## Open

One step per merge, in dependency order; each lands green on its own.

### Step 0 — Measure

- [ ] for each merge, the `pub` names of the merged member's `root.bp` against the absorbing
      member's: a name both export is listed with the declaration that keeps it
- [ ] `grep -rn 'from "rakun-\(actuator-api\|logging\|hateoas\|ws\|tx\|devtools\|release\|rsocket\|stream\)"' repository/`
      — the imports to rewrite, per repository; a hit outside `repository/rakun` is reported to the
      front that owns the file and its merge waits for that commit (none today)
- [ ] the restriction audit's count before the front (`zig build test-libs`: 38) and the rakun rows;
      the total test count of every rakun member (the Gate compares it)

### Step 1 — `rakun-actuator-api` into the core

- [ ] `modules/rakun-actuator-api/` is gone; its files are under `modules/rakun/src/actuator_api/` and
      `test/actuator_api/`; `botopink test --target erlang` green in `modules/rakun` with the moved
      tests in the run
- [ ] no manifest under `repository/rakun` names `rakun-actuator-api` (14 dependants today); every
      dependant's suite green under erlang
- [ ] `startSpan` / `endSpan` / `traceId` are `pub` from the core's `root.bp`

### Step 2 — `rakun-logging` into the core

- [ ] `modules/rakun-logging/` is gone; its files are under `modules/rakun/src/logging/` and
      `test/logging/`; the core's suite green with them
- [ ] the core's `after()` reports a deferred function's failure through its own logger; no
      `rkInstallFailureSink` / `rkReportFailure` exists (`grep -rn` over `modules/` — empty today, and
      stays empty)
- [ ] `rakun-starter` brings `rakun` only; `starter_manifest_test.bp` asserts it

### Step 3 — `rakun-hateoas` into `rakun-web`

- [ ] `modules/rakun-hateoas/` is gone; `hal_test` runs under `modules/rakun-web/test/hateoas/`;
      `rakun-web`'s suite green

### Step 4 — `rakun-ws` into `rakun-client`

- [ ] `modules/rakun-ws/` is gone; `client_test` and `envelope_test` run under
      `modules/rakun-client/test/ws/`; `rakun-client`'s suite green
- [ ] `grep -rn '"rakun-ws"' repository/rakun` is empty, and no manifest names a renamed SOAP member (merged, not renamed — decision 187)

### Step 5 — `rakun-tx` into `rakun-data`

- [ ] `modules/rakun-tx/` is gone; `outbox_test` and `saga_test` run under
      `modules/rakun-data/test/tx/`; `rakun-data` and `rakun-mail` green

### Step 6 — `rakun-devtools` into `rakun-data`

- [ ] `modules/rakun-devtools/` is gone; `db_console_test` and `devtools_test` run under
      `modules/rakun-data/test/devtools/`; `rakun-data` green

### Step 7 — `rakun-release` into `rakun-cli`

- [ ] `modules/rakun-release/` is gone; `release_test` runs under `modules/rakun-cli/test/release/`;
      `rakun-cli`'s manifest lists `rakun`, `rakun-actuator`, `rakun-web`; its suite green

### Step 8 — `rakun-rsocket` into `rakun-messaging`

- [ ] `modules/rakun-rsocket/` is gone; `codec_test` and `interaction_test` run under
      `modules/rakun-messaging/test/rsocket/`; `rakun-messaging` green

### Step 9 — `rakun-stream` into `rakun-messaging`

- [ ] `modules/rakun-stream/` is gone; its three test files run under
      `modules/rakun-messaging/test/stream/`; `rakun-messaging`'s manifest lists `rakun-actuator` and
      `rakun-data`; its suite green

### Step 10 — The consumer surface and the record

- [ ] every starter's manifest and `brings` list names surviving members only; the three examples build
- [ ] `modules/README.md`, `AGENTS.md`, the CI workflow and the hook list the members that exist
- [ ] [`../modules.md`](../modules.md): § Members and § The graph re-measured against the tree;
      § On disk until 128 lands deleted
- [ ] the restriction audit's new count is recorded here, with the nine rows it lost

**Gate:** standard (fronts.md § Gate) +
- [ ] `botopink test --target erlang` green in every member of `repository/rakun/modules`, the test
      count equal to step 0's total — a move loses no test
- [ ] `zig build test-libs -- --target erlang --lib rakun` green; the three examples build; the
      starters lint
- [ ] the import grep of step 0 is empty over `repository/`
- [ ] `botopink format --check` clean in every member touched

## Blast radius

- Every rakun front sequences after this one and names its files at the new paths
  ([`../README.md`](../README.md) § Where a merged member's front works).
- Nine `test-libs` cells disappear; their tests run in the absorbing member's cell; the restriction
  audit loses nine rows.
- `03-bundled-libs`' consumer files move: the logging files 17 switches to `log` are
  `modules/rakun/src/logging/**`; `107-release` edits `modules/rakun-cli/src/release/release.bp`;
  102's `hal.bp` commit lands before this front and moves with the file. 130's landed edits in
  `rakun-hateoas` move the same way.
- `rakun-messaging` gains `rakun-actuator` and `rakun-data`, so every messaging consumer loads the
  data member; `rakun-cli` gains `rakun-web`.

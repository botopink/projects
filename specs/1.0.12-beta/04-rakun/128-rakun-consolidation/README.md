# Front 128 — rakun consolidation: nine members move in with the member that needs them

**Priority:** critical — first of the track (decision 187); every other rakun front edits a member
it moves, an import it rewrites or a manifest it changes · **State:** steps 0–10 written as one patch
each (rakun is hooked; the coordinator lands them) — every box ticked
**Depends on:** rakun consumer commits of `03-bundled-libs/102` step 3
(`rakun-app/src/{file_router,static_gen}.bp`, `rakun-hateoas/src/hal.bp`) and `103` step 2
(`rakun-app/src/actions.bp`) landed first (decision 188) — not landed · no `01-compiler/130` rakun
commit in flight while open ([`../README.md`](../README.md) § Order, the 130 rule — decision 339)
**Owns:** while open, every member of `repository/rakun/modules/**`, `starters/**`, `examples/**`,
the workspace `botopink.json`, `modules/README.md`, `repository/rakun/AGENTS.md`,
`.github/workflows/` and `scripts/git-hooks/` where they list members · [`../modules.md`](../modules.md) · this directory
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

Resulting members and graph: [`../modules.md`](../modules.md) § Members, § The graph; step 0's
baseline: below. Pulsar stays in `rakun-messaging/src/pulsar/` (274): `pulsar/**` moves with nothing.

## Open

One step per merge, dependency order; each lands green alone.

### Step 0 — Measure

- [x] for each merge, the `pub` names of the merged member's `root.bp` against the absorbing
      member's: a name both export is listed with the declaration that keeps it — none: every
      top-level `pub fn` / `pub type` / `pub behavior` / `pub declare` of each merged `src/` against
      the absorber's (the core with `actuator_api/` before `logging/`, `rakun-data` with `tx/` before
      `devtools/`, `rakun-messaging` with `rsocket/` before `stream/`) shares no name; no sub-directory
      name is a module of the absorber
- [x] `grep -rn 'from "rakun-\(actuator-api\|logging\|hateoas\|ws\|tx\|devtools\|release\|rsocket\|stream\)"' repository/`
      — the imports to rewrite, per repository; a hit outside `repository/rakun` is reported to the
      front that owns the file and its merge waits for that commit (none today) — all in
      `repository/rakun`: 57 files import `rakun-actuator-api` (4 of them also by the path `rakun-actuator-api/audit_seam`),
      2 `rakun-tx` (one by `rakun-tx/outbox`), 1 `rakun-release/release`; the rest name no merged
      member (one doc comment in `rakun-hateoas/src/root.bp`)
- [x] the restriction audit's count before the front (`zig build test-libs`: 38) and the rakun rows;
      the total test count of every rakun member (the Gate compares it) — `botopink-lib-test --list`:
      38 audits, 36 of them rakun's (25 modules, 8 starters, 3 examples, each excluding `commonJS`);
      `botopink test --target erlang` (compiler `615c086d`, rakun `236947f`; the same on `106c84b3` / `c0e991c` and `56d4bc29` / `08f32ab`): `rakun` 375 ·
      `rakun-actuator` 103 · `rakun-actuator-api` 10 · `rakun-app` 204 · `rakun-cache` 56 · `rakun-cli` 25 ·
      `rakun-client` 70 · `rakun-data` 128 · `rakun-devtools` 21 · `rakun-hateoas` 14 · `rakun-logging` 54 ·
      `rakun-mail` 32 · `rakun-messaging` 91 · `rakun-metrics` 41 · `rakun-release` 12 · `rakun-rsocket` 16 ·
      `rakun-scheduling` 100 · `rakun-security` 100 · `rakun-session` 35 · `rakun-stream` 24 · `rakun-test` 27 ·
      `rakun-tx` 32 · `rakun-web` 209 · `rakun-websocket` 27 · `rakun-ws` 13 — **1 819**, 0 failed

### Step 1 — `rakun-actuator-api` into the core

- [x] `modules/rakun-actuator-api/` is gone; its files are under `modules/rakun/src/actuator_api/` and
      `test/actuator_api/`; `botopink test --target erlang` green in `modules/rakun` with the moved
      tests in the run — 385 / 0 (375 + 10). The core's `di_test.bp` asserted `rkScannedCount() == 2`;
      a sibling test module is loaded into every module's run, so `actuator_api/registration_test.bp`'s
      five `#[component]` records count too: the assertion is now "each of the file's two records
      registers exactly once" (`names.split(",")` filtered, `== 1` each) and `rkScannedCount() >= 2`
- [x] no manifest under `repository/rakun` names `rakun-actuator-api` (14 dependants today); every
      dependant's suite green under erlang — every member's count unchanged; the eight test files that
      write a fixture project's manifest (`*build_test.bp`, `command_decorator_test.bp`) drop its path
      dependency; `version_set.bp` drops its row; `info_test.bp` asserts `"rakun":"0.0.1"` where it
      asserted `"rakun-actuator-api":"0.0.1"` (the resolved modules of `rakun-actuator`)
- [x] `startSpan` / `endSpan` / `traceId` are `pub` from the core's `root.bp` — through
      `pub mod actuator_api;` (`traceId` is a field of the `pub type Span`); every consumer imports them
      `from "rakun"`

### Step 2 — `rakun-logging` into the core

- [x] `modules/rakun-logging/` is gone; its files are under `modules/rakun/src/logging/` and
      `test/logging/`; the core's suite green with them — 439 / 0 (385 + 54)
- [x] no failure-report seam exists — `rkInstallFailureSink` / `rkReportFailure`, `grep -rn` over
      `modules/` empty, and stays empty; a deferred `after()` failure reaching the core's logger is
      `04-rakun/17` step 4 (decision 365), after 128 lands — empty after every merge
- [x] `rakun-starter` brings `rakun` only; `starter_manifest_test.bp` asserts it — inside the web
      starter's test, renamed "rakun-starter brings rakun only; rakun-starter-web resolves rakun and
      rakun-web, …" (no test added or lost)

### Step 3 — `rakun-hateoas` into `rakun-web`

- [x] `modules/rakun-hateoas/` is gone; `hal_test` runs under `modules/rakun-web/test/hateoas/`;
      `rakun-web`'s suite green — 223 / 0 (209 + 14)

### Step 4 — `rakun-ws` into `rakun-client`

- [x] `modules/rakun-ws/` is gone; `client_test` and `envelope_test` run under
      `modules/rakun-client/test/ws/`; `rakun-client`'s suite green — 83 / 0 (70 + 13). One template
      names a compiled record's atom, which carries the package and the module path:
      `rakun_ws@ws@@SoapFault` → `rakun_client@ws@ws@@SoapFault` (`ws.bp:45`)
- [x] `grep -rn '"rakun-ws"' repository/rakun` is empty, and no manifest names a renamed SOAP member (merged, not renamed — decision 187)

### Step 5 — `rakun-tx` into `rakun-data`

- [x] `modules/rakun-tx/` is gone; `outbox_test` and `saga_test` run under
      `modules/rakun-data/test/tx/`; `rakun-data` and `rakun-mail` green — 160 / 0 (128 + 32) and 32 / 0

### Step 6 — `rakun-devtools` into `rakun-data`

- [x] `modules/rakun-devtools/` is gone; `db_console_test` and `devtools_test` run under
      `modules/rakun-data/test/devtools/`; `rakun-data` green — 181 / 0 (160 + 21). `rakun-cli`'s
      `--watch` looked for `"rakun-devtools"` in a project's manifest, a name no member has now: it
      looks for `"rakun-data"` (the track README: a merged name in code means the absorber), and its
      refusal and test say `rakun-data (front 80's devtools)`; the trace fixture depends on `rakun-data`

### Step 7 — `rakun-release` into `rakun-cli`

- [x] `modules/rakun-release/` is gone; `release_test` runs under `modules/rakun-cli/test/release/`;
      `rakun-cli`'s manifest lists `rakun`, `rakun-actuator`, `rakun-web`; its suite green — 37 / 0
      (25 + 12); `release/` is appended after `cli.bp`, which imports it, and builds

### Step 8 — `rakun-rsocket` into `rakun-messaging`

- [x] `modules/rakun-rsocket/` is gone; `codec_test` and `interaction_test` run under
      `modules/rakun-messaging/test/rsocket/`; `rakun-messaging` green — 107 / 0 (91 + 16)

### Step 9 — `rakun-stream` into `rakun-messaging`

- [x] `modules/rakun-stream/` is gone; its three test files run under
      `modules/rakun-messaging/test/stream/`; `rakun-messaging`'s manifest lists `rakun-actuator` and
      `rakun-data`; its suite green — 131 / 0 (107 + 24)

### Step 10 — The consumer surface and the record

- [x] every starter's manifest and `brings` list names surviving members only; the three examples build
      — after every step, the eight starters and three examples `botopink build --target erlang`, exit 0
- [x] `modules/README.md`, `AGENTS.md`, the CI workflow and the hook list the members that exist —
      each merge's patch moves its section and table row; the workflow's routing comment drops
      `rakun-hateoas`; the hook names no member
- [x] [`../modules.md`](../modules.md): § Members and § The graph re-measured against the tree;
      § On disk until 128 lands deleted — every manifest's dependencies equal § Members' column
- [x] the restriction audit's new count is recorded here, with the nine rows it lost — 29 (rakun 27):
      the `commonJS` audits of `rakun-actuator-api`, `rakun-logging`, `rakun-hateoas`, `rakun-ws`,
      `rakun-tx`, `rakun-devtools`, `rakun-release`, `rakun-rsocket`, `rakun-stream` (`--list`)

**Gate:** standard (fronts.md § Gate) +
- [x] `botopink test --target erlang` green in every member of `repository/rakun/modules`, the test
      count equal to step 0's total — a move loses no test — 16 members, **1 819**, 0 failed: `rakun` 439 ·
      `rakun-actuator` 103 · `rakun-app` 204 · `rakun-cache` 56 · `rakun-cli` 37 · `rakun-client` 83 ·
      `rakun-data` 181 · `rakun-mail` 32 · `rakun-messaging` 131 · `rakun-metrics` 41 · `rakun-scheduling` 100 ·
      `rakun-security` 100 · `rakun-session` 35 · `rakun-test` 27 · `rakun-web` 223 · `rakun-websocket` 27;
      the set of passing test names equal to step 0's but two titles (step 2's starter test, step 6's
      `--watch` test)
- [x] `zig build test-libs -- --target erlang --lib rakun` green; the three examples build; the
      starters lint — measured as CI runs it (`BOTOPINK_LIB_ROOTS=<rakun> botopink-lib-test --target
      erlang,commonJS --strict --cold`) on the eleventh patch's tree over rakun `236947f`, compiler
      `df6bc571`: the 16 rakun test cells green, 11 build cells, 27 restrictions audited, 0 not
      structural (the sibling `styled` cell, outside rakun, red on its own `@Context<StyledBase>`);
      on `615c086d` one parallel run met `rakun-websocket`'s load-dependent cells, green in every
      sequential run; the starter lint is `starter_manifest_test.bp`, in the core's 439
- [x] the import grep of step 0 is empty over `repository/`
- [x] `botopink format --check` clean in every member touched — a reformat-only eleventh patch over
      the fourteen members the merges touch, 273 files (rakun was not canonical before 128; untouched and
      still not canonical: `rakun-test` 8 files, `examples/` 4; `rakun-app` and the starters are); the
      moves' patches carry no reformat

## Blast radius

- Every rakun front sequences after this, at the new paths ([`../README.md`](../README.md) § Where a merged member's front works).
- Nine `test-libs` cells disappear (tests run in the absorber's cell); the restriction audit loses nine rows.
- `03-bundled-libs`' consumer files move: 17's logging files switched to `log` are
  `modules/rakun/src/logging/**`; `107-release` edits `modules/rakun-cli/src/release/release.bp`;
  102's `hal.bp` commit lands first and moves with the file; 130's landed `rakun-hateoas` edits likewise.
- `rakun-messaging` gains `rakun-actuator`, `rakun-data` (every messaging consumer loads the data
  member); `rakun-cli` gains `rakun-web`.

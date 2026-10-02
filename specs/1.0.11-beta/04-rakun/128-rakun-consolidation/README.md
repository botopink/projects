# Front 128 — rakun consolidation: nine members move in with the member that needs them

**Priority:** critical — the first front of the track (decision 187): every other rakun front edits
a member this one moves, renames an import this one rewrites, or reads a manifest this one changes
**Carries:** — (new in this milestone; decision 187, which supersedes decision 184 and `03r-ac` and
answers `03r-aj`)
**Depends on:** `00-gate` green with `99-gate-rakun` landed and pushed · the rakun consumer commits
of `03-bundled-libs/102` step 3 (`rakun-app/src/{file_router,static_gen}.bp`,
`rakun-hateoas/src/hal.bp`) and `103` step 2 (`rakun-app/src/actions.bp`), which go before any
library front opens (decision 188) and edit files this front moves
**Owns:** for the length of the front, every member of `repository/rakun/modules/**`,
`starters/**`, `examples/**`, the workspace `botopink.json`, `modules/README.md`,
`repository/rakun/AGENTS.md`, `.github/workflows/` and `scripts/git-hooks/` where they list
members · [`../modules.md`](../modules.md) · this directory
**Does not touch:** what any file *does* — a move changes a path, a `pub mod` line, a manifest and
an import, never a body · `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp` of the core
(frozen) · `repository/botopink-lang/**` · `repository/{onze,jhonstart}/**` (an import of a merged
member found there is reported to the front that owns the file — step 0)

No other rakun front holds a worktree while this one is open: it runs alone in the repository.

---

## Problem

rakun is cut into 25 members, and for nine of them the cut buys nothing: the member is either
loaded by everything, or used by exactly one other member.

```
$ cd repository/rakun && ls modules | wc -l
25
```

| Fact | Measured |
|---|---|
| members · source lines under `modules/*/src` | 25 · 51 932 |
| members that always load `rakun` + `rakun-web` + `rakun-actuator` + `rakun-actuator-api` | 18 of 25 — the four are 20 042 lines |
| starters that carry `rakun-logging` | every one (`rakun-starter` brings it, and every other starter brings `rakun-starter`) |
| `rakun-tx` | 478 lines · used by `rakun-mail` only |
| `rakun-release` | 455 lines · used by `rakun-cli` only |
| `rakun-hateoas` | 227 lines |
| `rakun-ws` | 317 lines |
| `rakun-rsocket` | 560 lines |
| `rakun-stream` | 665 lines |
| `rakun-devtools` | 564 lines |

A member another member always needs is not a plugin (decision 187): it is a directory boundary
that costs a manifest, a `-test` cell, a row of the restriction audit and an edge every consumer
spells. The split also created the seam questions `03r-y` and `03r-aj` — the core could not log
and `rakun-app` could not open a span without an edge — which exist only because logging and the
span API sit outside the core.

## Current state

Measured at the answer of decision 187, on `repository/rakun` (the manifests of
[`../modules.md`](../modules.md) § Members):

- `rakun-actuator-api` depends on `rakun` only and is a dependency of 12 members; `rakun-logging`
  depends on `rakun` and `rakun-actuator-api`.
- `rakun-tx` and `rakun-devtools` depend on `rakun` and `rakun-data`; `rakun-release` on `rakun`,
  `rakun-web`, `rakun-actuator-api`, `rakun-actuator`; `rakun-hateoas` on `rakun`, `rakun-web`;
  `rakun-ws` on `rakun`, `rakun-client`; `rakun-rsocket` on `rakun`, `rakun-messaging`;
  `rakun-stream` on `rakun`, `rakun-actuator-api`, `rakun-actuator`, `rakun-data`,
  `rakun-messaging`.
- A member that already holds several subjects keeps each in a sub-directory of `src/` and of
  `test/`: `rakun-data/src/{sql,orm,migration}/**`, `rakun-messaging/src/{pulsar,jms,reliability}/**`
  with `test/{jms,pulsar,reliability}/**`.
- The restriction audit of `00-gate/113` counts 38 restrictions; every rakun member is one row
  (`"targets": ["erlang"]`).

## Mechanism

| Merged member | Moves into | Its files after the move |
|---|---|---|
| `rakun-actuator-api` | `rakun` (the core) | `modules/rakun/src/actuator_api/**`, `test/actuator_api/**`, `src/sidecars/rakun_actuator_api.erl` |
| `rakun-logging` | `rakun` (the core) | `modules/rakun/src/logging/**`, `test/logging/**`, `src/sidecars/rakun_logging.erl` |
| `rakun-hateoas` | `rakun-web` | `modules/rakun-web/src/hateoas/**`, `test/hateoas/**` |
| `rakun-ws` | `rakun-client` | `modules/rakun-client/src/ws/**`, `test/ws/**`, `src/sidecars/rakun_ws.erl` |
| `rakun-tx` | `rakun-data` | `modules/rakun-data/src/tx/**`, `test/tx/**` |
| `rakun-devtools` | `rakun-data` | `modules/rakun-data/src/devtools/**`, `test/devtools/**`, `src/sidecars/rakun_devtools.erl` |
| `rakun-release` | `rakun-cli` | `modules/rakun-cli/src/release/**`, `test/release/**`, `src/sidecars/rakun_release.erl` |
| `rakun-rsocket` | `rakun-messaging` | `modules/rakun-messaging/src/rsocket/**`, `test/rsocket/**`, `src/sidecars/rakun_rsocket.erl` |
| `rakun-stream` | `rakun-messaging` | `modules/rakun-messaging/src/stream/**`, `test/stream/**`, `src/sidecars/rakun_stream.erl` |

`rakun-web` and `rakun-actuator` stay members. A merge is the same four edits every time:

1. **The files move** into a sub-directory named after the merged member — the shape `sql/`,
   `pulsar/` and `jms/` already have. A sidecar keeps its file name and its atom
   (`src/sidecars/rakun_<name>.erl`), so no `#[@External.Erlang]` template changes.
2. **The absorbing member's `botopink.json` and `src/root.bp`** gain the `files` entries and the
   `pub mod` lines, appended after its own; it takes over the merged member's dependencies it does
   not already have (`rakun-cli` gains `rakun-web`; `rakun-messaging` gains `rakun-actuator` and
   `rakun-data`). The merged member's directory and manifest are deleted.
3. **Every dependant's manifest** drops the merged member's name, and every
   `import … from "rakun-<merged>"` names the absorbing member instead.
4. **The seams the split forced are deleted with it**: the core calls its own logger, so no
   failure-report plugin exists (decision 187 over 184), and the span API is the core's, so
   `rakun-app` reaches it through the dependency it has (`03r-aj`).

The graph after the nine moves, every edge pointing at a lower level:

```
L0  rakun (+ actuator-api, logging)
L1  rakun-web (+ hateoas) ◄ rakun      rakun-test ◄ rakun      rakun-client (+ ws) ◄ rakun
L2  rakun-actuator ◄ web
L3  rakun-data (+ tx, devtools) ◄ actuator      rakun-metrics ◄ web·client·actuator
    rakun-cli (+ release) ◄ web·actuator
L4  rakun-scheduling ◄ web·actuator·data      rakun-mail ◄ data
    rakun-messaging (+ rsocket, stream) ◄ metrics·client·actuator·data
L5  rakun-session ◄ web·actuator·data·scheduling
L6  rakun-security ◄ web·data·client·session      rakun-cache ◄ web·actuator·session
L7  rakun-websocket ◄ web·data·security      rakun-app ◄ web·cache
```

Decision 185's rule stays for what is optional: `rakun-cache` and `rakun-client` remain separate
members and meet through the core's tag epoch.

## Steps

One step per merge, in dependency order; each lands green on its own.

### Step 0 — Measure

**Acceptance:**
- [ ] for each of the nine merges, the `pub` names of the merged member's `root.bp` against the
      absorbing member's: a name both export is listed with the declaration that keeps it
- [ ] `grep -rn 'from "rakun-\(actuator-api\|logging\|hateoas\|ws\|tx\|devtools\|release\|rsocket\|stream\)"' repository/`
      — the list of imports to rewrite, per repository; a hit outside `repository/rakun` is
      reported to the front that owns the file, and the merge that causes it waits for that commit
- [ ] the restriction audit's count before the front (`zig build test-libs`: 38 today) and the
      rows that are rakun's

### Step 1 — `rakun-actuator-api` into the core

**Acceptance:**
- [ ] `modules/rakun-actuator-api/` is gone; its files are under `modules/rakun/src/actuator_api/`
      and `test/actuator_api/`; `botopink test --target erlang` green in `modules/rakun` with the
      moved tests in the run
- [ ] no manifest under `repository/rakun` names `rakun-actuator-api`; every dependant's suite is
      green under erlang
- [ ] `startSpan` / `endSpan` / `traceId` are `pub` from the core's `root.bp`

### Step 2 — `rakun-logging` into the core

**Acceptance:**
- [ ] `modules/rakun-logging/` is gone; its files are under `modules/rakun/src/logging/` and
      `test/logging/`; the core's suite is green with them
- [ ] the core's `after()` reports a deferred function's failure through its own logger; no
      `rkInstallFailureSink` / `rkReportFailure` exists (`grep -rn` over `modules/` is empty)
- [ ] `rakun-starter` brings `rakun` only; `starter_manifest_test.bp` asserts it

### Step 3 — `rakun-hateoas` into `rakun-web`

**Acceptance:**
- [ ] `modules/rakun-hateoas/` is gone; `hal_test` runs under `modules/rakun-web/test/hateoas/`;
      `rakun-web`'s suite green

### Step 4 — `rakun-ws` into `rakun-client`

**Acceptance:**
- [ ] `modules/rakun-ws/` is gone; `client_test` and `envelope_test` run under
      `modules/rakun-client/test/ws/`; `rakun-client`'s suite green
- [ ] `grep -rn '"rakun-ws"\|"rakun-soap"' repository/rakun` is empty (the member is merged, not
      renamed — decision 187 over `03r-ac`)

### Step 5 — `rakun-tx` into `rakun-data`

**Acceptance:**
- [ ] `modules/rakun-tx/` is gone; `outbox_test` and `saga_test` run under
      `modules/rakun-data/test/tx/`; `rakun-data` and `rakun-mail` green

### Step 6 — `rakun-devtools` into `rakun-data`

**Acceptance:**
- [ ] `modules/rakun-devtools/` is gone; `db_console_test` and `devtools_test` run under
      `modules/rakun-data/test/devtools/`; `rakun-data` green

### Step 7 — `rakun-release` into `rakun-cli`

**Acceptance:**
- [ ] `modules/rakun-release/` is gone; `release_test` runs under `modules/rakun-cli/test/release/`;
      `rakun-cli`'s manifest lists `rakun`, `rakun-actuator`, `rakun-web`; its suite green

### Step 8 — `rakun-rsocket` into `rakun-messaging`

**Acceptance:**
- [ ] `modules/rakun-rsocket/` is gone; `codec_test` and `interaction_test` run under
      `modules/rakun-messaging/test/rsocket/`; `rakun-messaging` green

### Step 9 — `rakun-stream` into `rakun-messaging`

**Acceptance:**
- [ ] `modules/rakun-stream/` is gone; its three test files run under
      `modules/rakun-messaging/test/stream/`; `rakun-messaging`'s manifest lists `rakun-actuator`
      and `rakun-data`; its suite green

### Step 10 — The consumer surface and the record

**Acceptance:**
- [ ] every starter's manifest and `brings` list names surviving members only; the three examples
      build
- [ ] `modules/README.md`, `AGENTS.md`, the CI workflow and the hook list the members that exist
- [ ] [`../modules.md`](../modules.md) § Members and § The graph are the tree; its § After front
      128 is deleted
- [ ] the restriction audit's new count is recorded here, with the nine rows it lost

## Gate

- [ ] `botopink test --target erlang` green in every member of `repository/rakun/modules`, the
      test count equal to step 0's total — a move loses no test
- [ ] `zig build test-libs -- --target erlang --lib rakun` green; the three examples build; the
      starters lint
- [ ] the import grep of step 0 is empty over `repository/`
- [ ] `botopink format --check` clean in every member touched
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Commit on `front/128-rakun-consolidation`; landing is the maintainer's step

## Blast radius

- **Every rakun front of this track sequences after this one** and names its files at their new
  path ([`../README.md`](../README.md) § Where a merged member's front works).
- **Nine `test-libs` cells disappear** and their tests run in the absorbing member's cell; the
  restriction audit loses the same nine rows.
- **Consumers of a merged member change one import line**: inside rakun, in this front; in
  `repository/onze`, through its owner (`07-onze/49` imports rakun through `onze-server` only).
- **`03-bundled-libs`' consumer files move**: the logging files front 17 switches to the bundled
  `log` are `modules/rakun/src/logging/**`, `107-release` edits
  `modules/rakun-cli/src/release/release.bp`; 102's `hal.bp` commit lands before this front and
  moves with the file.
- **`rakun-messaging` and `rakun-cli` gain edges** (`rakun-actuator`, `rakun-data`; `rakun-web`),
  so every consumer of `rakun-messaging` loads the data member.

## Notes

- Decision 187's nine merges leave 16 members (25 − 9); the decision row states 16.
- A sub-directory per merged member is the tree's own convention (`sql/`, `pulsar/`, `jms/`), not
  a rule the decision states; step 0's export measurement is what can refuse it.
- `rakun-ws` keeps the directory name `ws/`: decision 187 says it is merged, not renamed.
- `91-rakun-pulsar`'s member question (`03r-ad`) is untouched: `pulsar/**` stays where it is.

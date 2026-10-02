# Front 99 — gate-rakun: every rakun cell green on the target rakun declares, and the repository's own gate runs

**Priority:** critical — 25 of the gate's 36 red `test-libs` cells are rakun's erlang cells, the
repository's own pre-commit fails before it runs a single test, and every `04-rakun` front waits
on this one.
**Depends on:** none to start (gate-g's recommendation is the starting assumption; the front stops
if the maintainer answers rc3-a otherwise). `113` lands after it.
**Owns:** `repository/rakun/**` for the duration of the front — in particular the files named in
the steps: the 42 `(if …)` sites, `modules/rakun-actuator/test/health_test.bp:67,71,89`,
`modules/rakun-app/test/ssr_test.bp:309,313,318`, `starters/rakun-starter-test/botopink.json:21-23`,
`modules/rakun-metrics/src/export.bp` (the `CacheLife` workaround), `modules/rakun-websocket/test/limits_test.bp`,
`modules/rakun-session/test/store_test.bp`, `modules/rakun-websocket/test/broadcast_test.bp`,
`modules/rakun-app/src/{static_gen,route_slots,metadata_routes,actions}.bp` (the comment lines the
hook's greps match), `examples/rakun-ssr/**`, `.github/workflows/test.yml`, `.gitignore`,
`scripts/git-hooks/**`, and a reformat-only commit over `modules/rakun/**` and
`modules/rakun-app/**` (PK-5).
**Does not touch:** `repository/botopink-lang/**` (a compiler defect met here is a row for
`../../01-compiler/` and the cell stays red until it lands — reported, not worked around by deleting
the test; R3 below has a library-side workaround that is not a deletion); `scripts/restricted-targets.txt`
(113's; it is deleted, not edited); any other repository.

The front may run as **three worktrees on disjoint member sets** (report L's chunks A, B, C —
`front/gate-rakun-a`, `-b`, `-c`, one front number, merged in that order) because the members do
not share files; chunk D (metrics, CI, hook) follows C, on the same branch as C or its own.

---

## Problem

Measured at the milestone's open (report A `scratchpad/libs.txt`, per-cell digest `cells.txt`;
report L for the repository's own gate): 25 rakun erlang cells FAIL, 6 pass, 5 have no tests; the
pre-commit hook fails at stage 1b (the front 22/23 greps) before `botopink test` runs;
`examples/rakun-ssr` does not build. The 35 commonJS cells are the restricted matrix (decision 113)
and are not this front's — gate-a makes them stop existing.

## Current state

Re-measured with the milestone's pinned compiler (the build from botopink-lang `eec364de`),
`botopink test` inside every `modules/*` member (what the pre-commit hook runs) and `botopink build`
of every example, on 2026-09-27 — after the PK-5 reformat for `rakun` and `rakun-app`:

| Member | Result | Member | Result |
|---|---|---|---|
| `rakun` | 374 / 0 | `rakun-messaging` | 91 / 0 |
| `rakun-actuator` | 103 / 0 | `rakun-metrics` | 41 / 0 |
| `rakun-actuator-api` | 10 / 0 | `rakun-release` | 12 / 0 |
| `rakun-app` | 204 / 0 | `rakun-rsocket` | 16 / 0 |
| `rakun-cache` | 55 / 0 | `rakun-scheduling` | 100 / 0 |
| `rakun-cli` | 25 / 0 | `rakun-security` | 100 / 0 |
| `rakun-client` | 70 / 0 (`BOTOPINK_BIN` set) | `rakun-session` | 35 / 0 |
| `rakun-data` | 128 / 0 | `rakun-stream` | 24 / 0 |
| `rakun-devtools` | 21 / 0 | `rakun-test` | 27 / 0 |
| `rakun-hateoas` | 14 / 0 | `rakun-tx` | 32 / 0 |
| `rakun-logging` | 54 / 0 | `rakun-web` | 209 / 0 |
| `rakun-mail` | 32 / 0 | `rakun-websocket` | 27 / 0 |
| | | `rakun-ws` | 13 / 0 |

Examples: `rakun`, `rakun-container`, `rakun-ssr` — 3 / 3 build. Starters: 8, no code, linted by
`rakun/test/starter_manifest_test.bp` (green inside `rakun`'s 374).

What the front changed, by root cause (report A § R1–R5, report L § Reds):

| Cause | Where | State |
|---|---|---|
| **R1** `if-operand` — 42 listed sites | `rakun-data` 25, `rakun-messaging` 6, `rakun-ws` 3, `rakun-app` 2, `rakun-scheduling`, `rakun-devtools`, `rakun-release`, `rakun-security` 2, `rakun-web` | every site is `val x = if (c) { a } else { b };` before its use (a lambda body becomes a block with `return`). Two more the grep missed and the compiler would have refused: `messaging/container.bp`'s nested `if (…) (if …) else …`, and the `(if (v) "true" else "false")` the `orm/entity.bp` and `orm/repository.bp` decorators **emit** for a `bool` column (now the unparenthesised call-argument form — no rakun fixture has a `bool` column, so no cell exercised it). `0 if-operand` diagnostics over the 25 members' logs |
| **R2** `-> any` | `rakun-actuator/test/health_test.bp`, `rakun-app/test/ssr_test.bp` | `unknown` — rc3-b's spelling, already implemented and what std's `async.bp` host handles use |
| **R3** `unknown type 'CacheLife'` — a compiler defect | `rakun-metrics` | the re-check happens in **`test/export_test.bp`** (it imports `otlpClient() -> RestClient` and nothing from `rakun-client`); importing `CacheLife` in `src/export.bp` changes nothing, `RestClient, CacheLife` in the test moves the red to `ClientResponse`, and the seven names `RestClient, RestClientBuilder, RequestSpec, HttpClientSettings, ClientResponse, CacheLife, Outbound` make the cell green. `../../language-gaps.md`'s row carries the measurement; a two-package reduction compiles clean, so the compiler row reproduces on the real pair with that import line removed. Owner `../../01-compiler/01-checker` |
| **R4** the hook's stage 1b greps | `scripts/git-hooks/lib/runner-standalone.sh` | the greps read code (`codeLines` drops `//` comments) and whole identifiers (`onze`, `jhonstart` as words; the UI types decision 114 names — `Element`, `ElementView`, `Children`, `LayoutProps`, `PageProps` — never the substring `Element`); the seven lines say "the orchestrator" / "the UI library". Verified: a synthetic `import … from "onze"` and a synthetic `e: Element` in code fail the hook; `onze` in a comment and `xmlElement` in code pass |
| **R5** a path dependency on a workspace root | `starters/rakun-starter-test/botopink.json` | `onze` and `onze-test` as `repository/onze/modules/<name>` path edges; the starter lint's allow-list names both |
| **R6** `websocket/test/limits_test.bp:48` | `rakun-websocket` | green after R1 (27 / 0) — it was the cascade, not a queue-cap defect |
| `examples/rakun-ssr` | the examples gate | builds after R1 |

Tolerances, all deleted:

| Tolerance | State |
|---|---|
| `rakun-session/test/store_test.bp` Redis arm (`RAKUN_TEST_REDIS_URL`, `SKIPPED`) | deleted — no RESP double exists yet (`rakun-test/src` holds none); `../../deferred.md` row; `saveCommand` keeps its own cell; `grep -rn "SKIPPED\|skipped: \|RAKUN_TEST_" modules --include=*.bp` → 0 hits (the `migrate.bp` record field aside) |
| `rakun-websocket/test/broadcast_test.bp` `skipped:` | replaced by a same-node `pg` broadcast to two subscriber processes (`rkWsPgBroadcast` / `pg_broadcast/2`; `two_node_broadcast/2`, `remote_subscriber/2`, `wait_members/2` deleted) — asserts `2|<payload>|<payload>` |
| CI `allow_fail: true`, `commonJS` and `beam` rows, core member only | `erlang` × {ubuntu-24.04, macos-14}, every row hard; Erlang/OTP 28 on every row; one `botopink-lib-test --target erlang --strict` per row from a scratch directory with `BOTOPINK_LIB_ROOTS` naming the repository — the runner's discovery covers every module, starter and example (a `--lib rakun` would be the core member alone) and nothing outside the workspace; onze, jhonstart and emilia checked out under `botopink-lang/repository/` as dependencies (`rakun-starter-test` depends on `onze` and `onze-test` by `path`; the workflow had no such checkout); the hook's other stages (the greps, the examples) on every row; `BOTOPINK_BIN` exported from the built binary. `grep -c "allow_fail: true"` → 0; `grep -c "target: commonJS\|target: beam"` → 0. No windows row (gate-f: the compiler has none), `ubuntu-24.04` because of the compiler's glibc pin (101's README has the row) |
| pre-commit warns and skips without a compiler; `known-broken-examples.txt` branch; a runner text of rakun's own | `scripts/git-hooks/lib/runner-standalone.sh` is one text in the five library repositories (`sha256sum` equal ×5; the meta `hook-integrity` check 4): a missing compiler **fails** the gate (message says how to provide one; a `BOTOPINK_BIN` that is not an executable fails too); the walk for it stops at the enclosing checkout's `repository/botopink-lang/` (a worktree nested under the main checkout never borrows the main checkout's binary); the known-broken branch is gone; `botopink test --target erlang` in every workspace member — the 25 modules, the 8 starters, the 3 examples: 36 cells. The greps are rakun's own stage in `scripts/git-hooks/repository-stages.sh`, run by the shared runner in a child process (it can add a red, never skip a shared stage) and read with `grep … >/dev/null` (a `grep -q` under `pipefail` could report a match as none) |
| no `*.snap.new` guard | `.gitignore` lists `*.snap.new` and `*.snap.md.new`; the hook refuses a staged one (verified: a staged `x.snap.new` exits 1) |
| `botopink format --check` drift in `modules/rakun`, `modules/rakun-app` (PK-5) | reformatted, one reformat-only commit; `--check` exits 0; both members green after it (374 / 0, 204 / 0). The one source-shape lint (`actions_test.bp`, `writeEnvelope(ActionEnvelope(`) reads a whitespace-free copy of the file |

## What is left

- The workflow's command shape is measured in a scratch layout of its checkout
  (`botopink-lang/{libs,repository/{rakun,onze,jhonstart,emilia}}`, a scratch working directory,
  `BOTOPINK_LIB_ROOTS` naming `repository/rakun`): `botopink-lib-test --target erlang --strict` →
  25 passed, 0 failed, 11 no-tests (the starters and the examples), 0 skipped; the greps and 3 / 3
  example builds green.
- The workflow green on `feat` after the push — the landing step: it triggers on push / PR to
  `feat`, `master`, `main` only, and the repaired file is unrun (the rows before the repair were
  red at the last pushed tip: `erlc: FileNotFound` at `zig build install` on the commonJS rows,
  `GLIBC_2.36 not found` on ubuntu-22.04).
- `rakun-websocket` depends on the machine: alone on an idle machine it is 27 / 0; under load
  `test/limits_test.bp:48` reads an outbound queue of 51 against the cap of 50 (26 / 1 — measured
  twice, 2026-10-01 inside the hook at load 40–110 and 2026-10-02 alone at load 106). One hook run was
  35 of 36 cells for that reason; the next was 36 / 36. Owner: `../../04-rakun/` (the cap's enforcement
  in the websocket runtime, or the test's bound) — a library row, not a compiler one.
- `scripts/gate.sh --cold` in `repository/botopink-lang` with this rakun checkout — the meta gate's
  stage 8 reads the erlang lines; this front did not run the compiler's gate (compiler fronts share
  the machine) — 113 reads the counts.
- The lesson the migration paid for once: a binding moves the evaluation earlier. `oauth2_test.bp`'s
  terminal bound `optionalSession()` before `accessToken("idp")` and the cell went 99 / 1 (the
  refresh is what ends the session the next read sees); the operands are bound in their original
  left-to-right order and the cell is 100 / 0. `AGENTS.md` § gotchas says so.

## Steps

### Step 1 — migrate the `(if …)` operand sites — done

The 42 listed sites and the 2 the grep missed (above); `grep -rnE "[=(,\[+:]\s*\(if \(|return \(if \(|\(if \(.*\) .*else .*\)\." repository/rakun --include=*.bp` → 0. A binding moves the
evaluation earlier: where an operand has a side effect (the oauth2 terminal) the operands are
bound in their original left-to-right order.

### Step 2 — the `-> any` declarations and the `CacheLife` closure — done

`unknown` for the six declarations; the seven-name closure import in `export_test.bp`; the R3 row
in `../../language-gaps.md` carries the measurement (the reduction that does not reproduce
included).

### Step 3 — `rakun-starter-test` depends on onze members — done

### Step 4 — the two `SKIPPED` cells — done (gate-h)

### Step 5 — leftovers and the examples — done

R6 was the cascade; `orm_test`'s `__rkDerived_*` names resolve once `rakun-data` compiles; the three
examples build.

### Step 6 — greps, hook, guard, CI — done (gate-i, gate-j)

### Step 7 — PK-5 reformat — done

## Gate

- [x] every `modules/*` member green under `botopink test` on erlang with the pinned compiler —
  25 of 25 (1,817 / 0)
- [x] `botopink build` of the 3 examples: 3 / 3
- [x] the hook's refusals verified one by one (missing compiler, staged `*.snap.new`, synthetic
  `from "onze"`, synthetic `Element` in code; comment-only `onze` and `xmlElement` pass)
- [x] `(cd repository/rakun && scripts/git-hooks/pre-commit)` green end to end in one run — 2026-10-02,
  as the hook of the gate-repair commit: 36 / 36 cells, 3 / 3 builds, the greps, exit 0 (an earlier run
  on a loaded machine was 35 / 36 on `rakun-websocket`, § What is left)
- [ ] `scripts/gate.sh --cold` in `repository/botopink-lang` with this rakun checkout: no rakun
  erlang line but `pass` / `no tests` (the commonJS lines disappear with 113)
- [ ] the workflow green on `feat` after the push
- [x] `repository/rakun/AGENTS.md` updated (the hook's stages and greps, the CI matrix, the removed
  environment variable, the if-operand advice)
- [x] step 7 — `botopink format --check modules/rakun modules/rakun-app` exits 0

## Blast radius

- Every `04-rakun` front (`04`, `08`, `09`, `11`, `12`, `13`, `15`, `17`, `19`, `22`, `65`, `73`,
  `74`, `79`, `81`, `88`, `91`, `92`, `93`) starts from this front's landing — they share
  `rakun-data/src/orm/**`, `rakun-messaging/src/**`, `rakun-app/src/**`, the starters' manifests
  and the test files above. `04-rakun/README.md` already says so.
- `onze-server·erlang` (100) compiles only when `rakun-data` and `rakun-scheduling` do: 100 verifies
  its `onze-server` cell against this front's tree.
- `113` deletes the 18 + 17 rakun ledger lines in the commit that lands the manifest rule — this
  front does not edit the ledger; `113` also lands the `BOTOPINK_BIN` export the fixture-build tests
  need in CI.
- `../../01-compiler/01-checker` receives R3.

## Notes

- rakun is erlang-only (decision 113): nothing here adds a node binding, an `.mjs` or a commonJS
  row; the commonJS cells stop existing with gate-a.
- The compiler knows no library: a red that is the compiler's (R3, or a checker gap the migration
  exposes) is filed, not worked around by deleting the test.

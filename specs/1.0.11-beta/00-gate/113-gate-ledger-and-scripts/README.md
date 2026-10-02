# Front 113 — gate-ledger-and-scripts: the manifest is the single source of truth; the two ledgers are deleted; a restriction is audited, not counted

**Priority:** critical — it is what turns "84 passed, 36 failed, 13 restricted" into a line whose
only red number is `failed`, and it is the keystone of stage 8: until the two ledger files are gone
the stage is red for everyone.
**Depends on:** `99`, `100`, `101`, `108`, `109` (the five library tips this front measures
against). `115` starts from this front's `test-libs.sh` and `lib-test-runner`.
**Owns:** `scripts/restricted-targets.txt` (deleted) · `scripts/known-red-libs.txt` (deleted) ·
`scripts/test-libs.sh` · `modules/lib-test-runner/**` · `scripts/AGENTS.md` (§ test-libs.sh) ·
`modules/lib-test-runner/AGENTS.md` · `modules/compiler-cli/src/cli/test_cmd.zig` (the
`BOTOPINK_BIN` export only — `TEST_BIN_ENV` and four lines of `testTmpEnv`) ·
`modules/compiler-cli/tests/test_tooling.sh` (the `[libs]` audit rows and the `[env]` rows) ·
`.github/workflows/test.yml` (the `libs` job's header comment and the `zig fmt --check modules`
step) · the meta repository's `scripts/language-gap-markers.sh` and the `## Marker index` of
`../../language-gaps.md` · verification (read-only) of
`repository/{rakun,jhonstart,emilia,onze,erika}/.gitignore` and `scripts/git-hooks/**`.
**Does not touch:** any library repository's files (the five fronts own them; this front *checks*
them and reports); `scripts/gate.sh` beyond the four comment lines of its stage-8 description
(`gate.sh:31-35`; the script is 115's); `tests/language/**` and the beam path of `test_cmd.zig`
(111's); `scripts/format-check.sh` (112's).

---

## Problem

```
$ zig build test-libs          # at the milestone's open
test-libs: 84 passed, 36 failed, 0 known red, 13 restricted (pinned), 0 skipped, 9 without tests
test-libs: restricted cells missing from scripts/restricted-targets.txt: … (21)
test-libs: pinned failed counts that moved (pinned→measured): … (9)
```

Three of the four numbers after "passed" were tolerance: `known red` (a file that pinned a red to a
library commit), `restricted (pinned)` (a file that pinned a failed *count* for a cell the member's
own manifest excludes) and the two refusals that followed. `scripts/test-libs.sh` always passed
`--include-unsupported`, so every excluded cell ran and its verdict was the ledger's, not the
cell's.

## Current state

Measured on the compiler tip this front starts from with the five libraries at their landed tips
(rakun `a340dac`, onze `559771f`, jhonstart `8a9e0f2`, erika `f4fda89`, emilia `6b766c1`), 86
libraries × `commonJS`, `erlang` = 172 (library, target) pairs.

| | Before this front (ledgers as they were) | With this front |
|---|---|---|
| Summary | `117 passed, 2 failed, 0 known red, 11 restricted (pinned), 0 skipped, 15 without tests` | `test-libs: 117 passed, 2 failed, 15 without tests, 38 restrictions audited` |
| Ledger refusals | 19 restricted cells with no line · 8 pinned counts moved · 3 stale lines | none — there is no ledger |
| Cells | 172 run (every excluded cell ran under `--include-unsupported`) | **134** — the cells the manifests declare (`--list`: 119 `cell:test` + 11 `cell:compile` + 4 `cell:nothing-to-compile`) |
| Excluded pairs | 38, each a ledger verdict | **38**, each audited — `botopink build --target <excluded>`, no test run |
| Exit | 1 | 1 — `test-libs: FAILED cells: onze-cli·commonJS onze-cli·erlang`, and nothing else |

The two red cells are `onze-cli·commonJS` (1 test) and `onze-cli·erlang` (3 tests). Neither is this
front's and neither is hidden, restricted or skipped: a checker defect (`ambiguous-import-use` when
two modules each export a `pub fn` of one name and a third imports one) and std's erlang `fs.walk`
on a root ending in `/.` — both owned outside these files. Stage 8 is green the moment they are.

- **The manifest decides the matrix.** `discovery.libSupportsTarget` is the one rule that says
  whether a (library, target) pair is a cell (`main.zig`, `Cell.Kind.of`). No flag, variable or file
  runs an excluded target: `--include-unsupported`, `libRunsTarget`, the `restricted` JSON field,
  `BOTOPINK_KNOWN_RED_LIBS` and `BOTOPINK_RESTRICTED_TARGETS` are deleted, with both ledger files.
- **A cell that exists is green or the run fails.** `test-libs.sh` reads `cell_summary` and
  nothing else decides a cell.
- **A restriction is audited on every run** (`runner.captureAudit` / `classifyAudit`): for each
  excluded target `botopink test` can run, `botopink build --target <excluded>` must be refused and
  its first error must be the missing host binding. `ok` → `·`, one line quoting the refusal;
  anything else → `not_structural`, `!`, exit 1 with
  `the restriction is not structural — … delete the "targets" line, or file the compiler row that
  makes the build refuse it`.
- **`--list`** prints the plan without running it, so the cell count is a command and not a number
  kept by hand: `zig build test-libs -- --list | grep -c $'\tcell:'` → 134.

### The restriction audit, pair by pair

Every excluded pair of the workspace, with the refusal that proves it structural (the run's own
lines; `at` is the location the compiler printed). 38 of 38 `ok`.

| Member | Excluded target | The build's first error (the refusal) | At |
|---|---|---|---|
| `jhonstart-dom-test` | `erlang` | `callGlobal` has no `#[@External.<Target>(…)]` for the erlang backend | `src/root.bp:37:12` |
| `onze-server` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun` | `commonJS` | `rkCwd` has no `#[@External.<Target>(…)]` for the node backend | `src/autoconfig_registry.bp:283:23` |
| `rakun-actuator` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-actuator-api` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-app` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-cache` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-cli` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-client` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-container-example` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-data` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-devtools` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-example` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-hateoas` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-logging` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-mail` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-messaging` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-metrics` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-release` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-rsocket` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-scheduling` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-security` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-session` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-ssr-example` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-starter` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-starter-actuator` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-starter-cache` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-starter-data-sql` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-starter-messaging` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-starter-security` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-starter-test` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-starter-web` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-stream` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-test` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-tx` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-web` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-websocket` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |
| `rakun-ws` | `commonJS` | `numeralText` has no `#[@External.<Target>(…)]` for the node backend | `rakun/config.bp:323:26` |

The restrictions the manifests carry are three: rakun's workspace `"targets": ["erlang"]`, inherited
by its 36 members (decision 113); `onze-server` `["erlang"]` (it stands on rakun); and
`jhonstart-dom-test` `["commonJS"]` (a document on node; no DOM on the BEAM). `onze-cli` and
`onze-og` carry no `targets` any more.

## Mechanism

`test-libs.sh` used to make `--include-unsupported` unconditional, and the runner turned every
manifest exclusion into a ran-and-measured cell whose verdict the script read off a ledger. With the
flag gone the manifest decides; with the audit the manifest cannot lie: an exclusion is accepted
only while the compiler itself refuses the member on that target for want of a host binding.

The compiler's refusal (`MissingExternal.diagnostic`, `compiler-core/src/codegen/moduleOutput.zig`)
carries **no error id** — it prints `error: \`f\` has no \`#[@External.<Target>(…)]\` for the
<backend> backend`. The classifier therefore reads that fixed text (`runner.HOST_BINDING_MARK`) and
names no library. It can only stop accepting: if the compiler rewords the refusal, every audit
answers `not_structural` and the run fails; `compiler-cli/tests/test_tooling.sh` holds the two
together with three real builds. An id on the diagnostic (`01-compiler`, a row below) would let the
classifier read an id instead.

## Steps

### Step 1 — measure the green matrix on the five landed trees

**Acceptance:**
- [x] the passed count and the excluded set recorded in this README (§ Current state): 117 passed,
  15 without tests, 38 excluded pairs; `zig build test-libs -- --list` → 172 lines = 134 `cell:*` +
  38 `audit`, and the 38 are exactly the pairs the ledger-era run reported as restricted
- [ ] the run's `FAILED cells:` line is absent — it names `onze-cli·commonJS onze-cli·erlang`
  (§ Current state); it goes when the two defects outside this front are fixed

### Step 2 — the runner: manifest rule and restriction audit (gate-a, gate-d)

**Acceptance:**
- [x] `botopink-lib-test --help` has no `--include-unsupported` (the flag is `error: unknown flag`,
  exit 2); `grep -rn "include_unsupported\|restricted" modules/lib-test-runner/src` → 0
- [x] a synthetic workspace (`modules/compiler-cli/tests/test_tooling.sh`, `[libs] an excluded
  target is audited`, run by `zig build test-cli`): a member with `"targets": ["erlang"]` and an
  `@External.Erlang`-only cell → `restriction_audit` `ok`, exit 0, and no `commonJS` cell; the same
  member with a Node binding too → `not_structural` (`\`botopink build --target commonJS\`
  succeeds`), exit 1 with no cell red; a member excluded from commonJS that does not parse →
  `not_structural` quoting its first error, exit 1. The classifier's own unit tests
  (`runner.zig`: `classifyAudit` × 5, `isHostBindingRefusal`, `firstErrorLine`; `main.zig`:
  `Cell.Kind.of`) pin the text and the rule
- [x] the audit runs the 38 (member, target) pairs: all `ok` (table above)

### Step 3 — `test-libs.sh`: two ledgers gone, one line printed

**Acceptance:**
- [x] `test ! -e scripts/restricted-targets.txt -a ! -e scripts/known-red-libs.txt`
- [x] the summary is `test-libs: <P> passed, <F> failed, <N> without tests, <A> restrictions
  audited` (`, <X> restrictions not structural` and `, <S> not runnable by botopink test` appended
  only when not zero, and each fails the run); measured `test-libs: 117 passed, 2 failed, 15 without tests, 38 restrictions audited`
- [x] `grep -rn "restricted-targets\|known-red-libs\|include-unsupported" scripts .github
  modules/lib-test-runner docs.md README.md` → 0
- [ ] `0 failed` — waits on the two `onze-cli` cells

### Step 4 — `scripts/AGENTS.md` and `modules/lib-test-runner/AGENTS.md`

**Acceptance:**
- [x] `grep -c "Live entries" scripts/AGENTS.md` = 0; § known-red-libs.txt and
  § restricted-targets.txt are gone, § test-libs.sh states the manifest rule, the audit and the
  line; `lib-test-runner/AGENTS.md` § The restriction audit; the root `AGENTS.md` (the `test-libs`
  paragraphs, the CI row — no windows row, every step named — and § Local gate stages 1, 3 and 8)

### Step 4b — `botopink test` exports the compiler's own path to the test process

`test_cmd.zig` `testTmpEnv` puts `BOTOPINK_BIN` — `std.process.executablePathAlloc` — in the
runners' environment when the variable is unset; a value the caller set passes through.

**Acceptance:**
- [x] `test_tooling.sh`, `[env] BOTOPINK_BIN in a test is the running compiler, unless the caller
  set it`: a test printing `env.read("BOTOPINK_BIN")` prints the running binary's absolute path with
  the variable unset and `/caller/chose/this` with it set, on commonJS and erlang
- [x] `zig build test-libs -- --lib rakun-client --target erlang` → `pass` with no `BOTOPINK_BIN` in
  the shell
- [x] the variable's sentence in `modules/compiler-cli/AGENTS.md` (§ Env and the behaviours list)
  and `docs.md` § Tests

### Step 4c — the `// LANGUAGE GAP` marker check

`scripts/language-gap-markers.sh` (meta repository; `hook-integrity` check 5). A marker is the
literal `// LANGUAGE GAP` in a tracked `.bp` file of a repository under `repository/` or of the meta
repository outside the closed milestones' spec trees. Measured: **27 markers in 19 files** — 2 in
library code (`rakun-cache/src/cache.bp:540`, `rakun-cache/test/granularity_test.bp:20`) and 25 in
17 example files under `specs/1.0.11-beta/{04-rakun,07-onze}/**/examples/`. The five notes report L
listed are **not** markers: each is prose that says "language gap" (emilia `tokens.bp:2194`, rakun
`conditions.bp:283`, `session.bp:7`, `sql/query.bp:33`, `exchange.bp:48`), and each already has a row
by content. `parallel-fetch-example.bp:31` has no copy under `specs/1.0.11-beta`.

The check is by file: `../../language-gaps.md` § Marker index holds one row per file with a marker —
path from the meta root, marker count, the gap rows named — and the script fails on a file with no
row, a count that differs, a named gap row that is gone, and a row for a file with no marker.

**Acceptance:**
- [x] `scripts/language-gap-markers.sh` prints the 27 and exits 0
  (`language-gap-markers: 27 marker(s) in 19 file(s), every one names a row of
  specs/1.0.11-beta/language-gaps.md`); deleting an index row → exit 1 naming the file and its
  markers; deleting the gap row a marker names → exit 1; a count that differs → exit 1; a row for a
  file with no marker → exit 1
- [x] rows in `../../language-gaps.md`: the 19 index rows; one stub gap row, **No reflection over a
  module's exports** (owner `01-compiler` — the half of `verb-exports-carried-example.bp:4` that had
  no row of its own); the five notes mapped to their existing rows, owner named

### Step 5 — the five repositories' guards (gate-i), read-only

Measured in scratch clones of `repository/<lib>` at the tips above (a clone outside any checkout,
`BOTOPINK_BIN` unset, `PATH=/usr/bin:/bin`): a staged `probe.snap.new` and a staged
`probe.snap.md.new` each run through `scripts/git-hooks/pre-commit`; then the hook with nothing
staged and no compiler reachable.

| Repository | `.gitignore` names both | hook refuses a staged candidate | hook refuses with no compiler | no skip list | identical clauses |
|---|---|---|---|---|---|
| emilia | ✓ | ✓ exit 1 | ✓ exit 1 | ✓ | text A |
| erika | ✓ | ✓ exit 1 | ✓ exit 1 | ✓ | text A |
| jhonstart | ✓ | ✓ exit 1 | ✓ exit 1 | ✓ | text A |
| onze | ✓ | ✓ exit 1 | ✓ exit 1 | ✓ | ✗ text B |
| rakun | ✓ | ✓ exit 1 | ✓ exit 1 | ✓ | ✗ text C |

`scripts/git-hooks/pre-commit` is one text in the five. `lib/runner-standalone.sh` is **three**:
emilia = erika = jhonstart (217 lines), onze (203), rakun (222), and the guard clauses themselves —
`locateBotopink` / the no-compiler refusal, and stage 1's candidate refusal — differ in wording
between the three. The behaviour is the same in all five; the texts are not, and the meta
`hook-integrity` check 4 (byte-identical) is red on them.

**Acceptance:**
- [ ] a five-row table, all ✓ — four columns are ✓ in all five; "identical clauses" is ✗ for onze
  and rakun. Reported to the library fronts (100, 99); the unification is theirs, and this table is
  re-measured on the unified tips (the commands are the paragraph above plus
  `sha256sum repository/*/scripts/git-hooks/lib/runner-standalone.sh`)

## Gate

- [x] `zig build test` from a cold runtime cache, green — stage 4 of `scripts/gate.sh --cold` ✓; `zig build test --summary all`:
  33/33 steps, 2597/2597 tests (`lib-test-runner`: 63)
- [ ] `zig build test-libs` → `0 failed`, no ledger column, every audit `ok` — no ledger column and
  38 of 38 audits `ok`; `2 failed` (`onze-cli`, both targets)
- [ ] `scripts/gate.sh --cold` green in this front's worktree with the five library checkouts at
  their landed tips — measured once at this front's tip: stages 1, 2, 3, 4, 4b, 5, 6, 7 ✓;
  stage 8 ✗ on exactly the two `onze-cli` cells (`test-libs: 117 passed, 2 failed, 15 without tests,
  38 restrictions audited`); the gate prints nothing after its first red stage, so 9 and 10 were run
  on their own: `language tests: 1251 passed, 1 expected failures, 0 failed` and
  `docs: 94 fences — 94 checked, 0 skipped, 0 failed`, both exit 0
- [x] `scripts/AGENTS.md`, `modules/lib-test-runner/AGENTS.md` updated in the same commit as the code
- [x] commit on `front/113-gate-ledger-and-scripts` in `repository/botopink-lang` and in the meta
  repository; no push, no merge

## What is left

| Item | Owner | State |
|---|---|---|
| `onze-cli·commonJS`, `onze-cli·erlang` red | the checker row (`ambiguous-import-use` on two modules exporting one name) and std's erlang `fs.walk` (a root ending in `/.`) | outside this front; stage 8 and the three open boxes above close with them |
| `runner-standalone.sh` is three texts | 100 (onze), 99 (rakun) — the library-infra unification | step 5's last column; re-measure on the unified tips |
| the missing-host-binding refusal has no error id | `01-compiler` (`codegen/moduleOutput.zig`, `MissingExternal.diagnostic`) | the audit reads its fixed text; with an id the classifier reads the id — one line in `runner.zig`, one in `test_tooling.sh` |
| `rakun-client/test/exchange_build_test.bp:26` ends its shell prelude with `exit 0` when no compiler is found | `04-rakun` | with `BOTOPINK_BIN` exported by `botopink test` the branch is unreachable under `botopink test`; the `exit 0` is a skip that reads as a pass and goes |
| `modules/compiler-cli/tests/test_tooling.sh` prints `SKIPPED` and exits 0 when `node` is not on `PATH` | `01-compiler/26-cli-tooling` | not this front's; a skip that reads as a pass |

## Blast radius

- `../../02-std-and-packaging/98-packaging-tail` step 4 and PK-1: there is no ledger to read or
  write.
- `../../04-rakun` 03r-ah is answered by gate-a; `05-jhonstart/modules.md:18,34,36` rows close.
- Each library's own CI runs `zig build test-libs -- --lib <m> --target <t>` for declared targets
  only; a workflow row on an excluded target now produces no cell — only the audit line.
- A consumer of the runner's `--json`: `cell_summary` lost `"restricted"`; an excluded pair has no
  `cell_summary` and a `{"event":"restriction_audit",…}` in its place; `run_summary` gained
  `"audited"` and `"not_structural"`.
- `115` re-measures stage 8: 38 fewer `botopink test` runs (the excluded pairs are no longer cells)
  and 38 audit builds added.

## Notes

- The `--json` raw mode of `test-libs.sh` stays, and `--list` joins it: both are the runner's
  output, not a verdict.
- An excluded target `botopink test` cannot run (beam, wasm) is neither a cell nor an audit — no
  cell could exist there, so the exclusion hides nothing the run could measure. The runner reports
  it as the CLI's own limit (`~`; a failure under `--strict`), without a spawn, and `test-libs.sh`
  fails the run on it (`NOT RUNNABLE` — a pair that did not run is never a pass; it is met only when
  such a target is asked for by name). When `botopink test` learns a backend, `Target.supported`
  widens and its exclusions are audited from then on.
- "First error" is deliberate: a build that reports any other error before the host-binding
  refusal is a red in its own right. The beam-only template refusal (`… template does not compile
  for the beam backend`) and a missing erlang sidecar are not accepted as structural: in both the
  binding exists, and what is wrong is somebody's to fix.
- `test-libs.sh` exits with the runner's own status whenever that is non-zero and nothing the
  script counted failed — a verdict the script did not read is never a pass.

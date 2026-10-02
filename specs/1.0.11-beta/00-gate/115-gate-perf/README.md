# Front 115 — gate-perf: the green gate under a wall-clock budget, with nothing skipped or narrowed

**Priority:** high — the maintainer asked for it explicitly: a gate that takes ~50 minutes is a gate
people run less often. It optimises the *green* gate; it fixes no red and buys no time by narrowing
a stage (decision 67 — coverage is never traded for speed; beam in `--target all` and the
libraries' new cells are inside the budget, not outside it).
**Depends on:** every other `00-gate` front — `111` (its `run.sh` is this front's starting point:
four targets, no expected-failures reader), `113` (its `test-libs.sh` and `lib-test-runner`: the
manifest rule and the audit), `110`, `112`, `114`, and the five library fronts (a red cell's time
is not the gate's time).
**Owns:** `scripts/gate.sh` (the per-stage timing report) · `scripts/test-libs.sh` ·
`tests/language/run.sh` · `modules/compiler-cli/src/cli/libs.zig` (the dependency-closure compile
cache) and the `.botopinkbuild/` / `${XDG_CACHE_HOME}/botopink/` cache layout it introduces ·
`modules/lib-test-runner/**` (cell scheduling, the erlang node pool) · the meta repository's
`scripts/` (new: `scripts/worktree-add.sh`) and the meta `AGENTS.md` § Worktrees · `scripts/AGENTS.md`
§ gate.sh · this README's measurement tables.
**Does not touch:** any stage's *content* (what a stage runs, which cells, which targets — a
stage that runs fewer cells after this front is a defect of this front); `compiler-core`'s pipeline
(a compile made faster inside `compiler-core` is `../../01-compiler/`'s); the emitters; snapshots.

---

## Problem

The gate, measured before this front (the `00-gate` landing tips, `scripts/gate.sh --cold` with the
stage times of step 5 added and nothing else; load 25 / 70 / 125 min / median / max on 16 CPUs —
other threads' suites were running, as they always are on this machine):

```
stage 2  zig build (Debug)           9 s        29 CPU-s     (zig cache warm)
stage 4  zig build test             52 s       390 CPU-s
stage 7  zig build test-cli         83 s        75 CPU-s
stage 8  zig build test-libs      3339 s     12760 CPU-s
stage 9  zig build test-language  1207 s      1279 CPU-s
…                                 56m43s wall in all
```

Where the time went, cell by cell (`ps` sampled once a second; wall of the cell's `botopink test`):
rakun-scheduling 1758 s, onze-cli·erlang 1482 s, rakun-messaging 1184 s, rakun-data 1148 s,
onze-cli·commonJS 740 s, rakun-app 599 s, rakun-security 514 s; every `emilia-*`, `onze-*` and
`jhonstart-emilia` erlang cell ~230 s, ~180 of them CPU-seconds of the compiler process itself.
Four causes, none of them a stage doing too much:

1. **The gate ran a Debug compiler.** `zig build` defaults to Debug; the same `emilia-borders`
   erlang cell is 189 CPU-s under the Debug `botopink` and 15 under ReleaseSafe — the mode
   `release.yml` ships — with byte-identical output.
2. **A test's scratch directory was inside the run directory.** `BOTOPINK_TEST_TMPDIR` was
   `<run dir>/tmp`, and every erlang runner compiles and loads every `.erl` under its own directory
   before its tests (`'__bp_load_siblings'/0`). rakun's build tests write fixture projects there —
   6 511 fixture `.erl` in rakun-scheduling's run — so every test module after them compiled and
   loaded all of them: ~5 CPU-minutes per module, and a fixture's modules loaded over the run's own.
3. **Every `botopink build --target erlang` compiled its whole closure with the OTP compiler**
   (`checkErlang`), and rakun's build tests spawn 22 builds of one closure in one cell.
4. **onze's own build ran one `erlc` over ~4 000 modules** (`compileBeam`): one scheduler, ~80 s
   per `onze build`, five of them in onze-cli's suite, on both of its cells.

## Current state

| What | Where |
|---|---|
| Stages 2–10 print their wall clock and CPU-seconds; the last line is the total against the budget; stages 8–10 are held to their runners' `--list` plan | `scripts/gate.sh` § stage times, § counts, § budget |
| Every binary the stages run is ReleaseSafe; every `zig build` of the gate passes `-Doptimize=ReleaseSafe`, stage 4's unit tests stay Debug | `scripts/gate.sh` § build mode |
| Stages 4, 4b, 5 and 6 start beside the ReleaseSafe build (they read nothing it produces) and are reported in their place | `scripts/gate.sh` § ahead of the build |
| `BOTOPINK_TEST_TMPDIR` is `<run dir>.tmp`, the run directory's sibling, removed with it; row C3d pins it | `compiler-cli/src/cli/test_cmd.zig` `testTmpDir` |
| `checkErlang` answers a source whose exact bytes the same OTP compiler accepted from `$XDG_CACHE_HOME/botopink/erlcheck/` (acceptances only) | `compiler-cli/src/cli/build.zig`, `libs.userCacheDir` |
| `botopink-lib-test` starts the cells longest-last-time first (`$XDG_CACHE_HOME/botopink/lib-test/durations.tsv`); output order unchanged | `lib-test-runner/src/schedule.zig` |
| `tests/language/run.sh --list` prints the plan; a run prints `cells: <J> jobs — <R> run, <A> audits` | `tests/language/run.sh` |
| onze's `compileBeam` deals the server's `.erl` to one `erlc` per CPU | `onze/modules/onze-cli/src/build.bp` |
| The five libraries' hook runs stages 4 and 5 on a cell pool (`gatePool`), report in plan order | `<lib>/scripts/git-hooks/lib/runner-standalone.sh` |
| `scripts/worktree-add.sh <name>` opens a worktree with `core.hooksPath` in every submodule that tracks a hook | meta `scripts/`, meta `AGENTS.md` § Worktrees |

## Steps

### Step 1 — the baseline: every stage from a cold cache on an idle machine

The baseline above and the runs of § Measurements were taken on the shared machine: it was never
idle while this front ran (load 14–125, other threads' compiler suites), so no row is the idle
measurement the step asks for. What the loaded runs fix is the ratio and the critical path, and
from them the budget's derivation: cold = the ReleaseSafe build of the compiler (3m17s, 684
CPU-s at load 57; its long pole is one LLVM thread for `botopink`) + the longest side-by-side stage
— `test-libs`, whose CPU (~1 850 CPU-s, ~115 s over 16 cores) is below its longest cell
(onze-cli·erlang, 140–220 s) — + 20 %: **≈ 7 min cold, ≈ 4 min warm** (no compiler rebuild) on
16 idle cores, inside the working assumption. The budget in `gate.sh` stays the working
assumption, 10 min cold and 5 min warm, until the idle runs amend it.

**Acceptance:**
- the idle three-run table (median, load, commit) → `133-gate-speed` step 1 (decision 229 amends the budget)
- [x] the budget written in step 5 and in `../README.md` § Exit gate (`budget_cold=600`, `budget_warm=300`)

### Step 2 — the dependency-closure compile cache

What the step aimed at moved. After step 1's causes were removed, the Zig-side compile of a
cell's closure is 1–5 s of ReleaseSafe CPU (`emilia-borders`: 1.4 s on commonJS, ~5 s on erlang,
comptime node included), and the OTP-compiler half of the erlang build — the larger one, 15 CPU-s
of that cell — is now answered from a content-keyed verdict cache (`build.zig` `checkErlang`,
`$XDG_CACHE_HOME/botopink/erlcheck/<k[0..2]>/<k>.ok`, `k` = SHA-256 of the source bytes, the
options, the OTP release and the erts / `compiler` / `stdlib` versions and
`ERL_COMPILER_OPTIONS`; acceptances only, a refusal is compiled and printed every time; the
`.beam` cache's model, staged and renamed, reaped by age). Caching the *Zig* compile of a
dependency package — its emitted modules and typed export tables — needs `compiler-core` to take
a pre-typed package as input, which this front does not touch; with the closure at 1–5 s a cell it
is no longer where the gate's time is. Decision 225 answered the question: the closure cache is
built by `131-gate-build-cache`, which also moves this step's verdict cache, the `.beam` cache and
the cell durations under `.botopinkbuild/cache/`.

**Acceptance:**
- [x] the erlang verdict cache: an accepted build twice under one cache writes the same keys, a changed source is a new key, a refused one is refused (and printed) on every build — `cli_contract.sh` § the erlang check's verdict cache, red against the pre-front binary; `emilia-borders` built with an empty and a warm cache: identical `out/` trees (`diff -r`) and identical logs
- the per-cell `out/` diff, empty vs warm cache → `131-gate-build-cache` step 3's first box; measured here: the 172 cell and audit lines and the summary are identical (`XDG_CACHE_HOME` empty: no `.beam`, verdict or duration entry; 6m13s, 2 031 CPU-s at load ~60)
- the closure cache's own boxes (a changed std byte, a rebuilt compiler, each a miss) are `131-gate-build-cache` step 3's
- [x] stage 8 wall clock and CPU-s before/after in this README's table (§ Measurements)

### Step 3 — `test-libs` cell parallelism bounded by cores, the erlang node reused

Measured (b) first, as the step says: the pool's admission is unchanged, and with causes 1–4 gone
the erlang start-up is no longer the cost (a whole emilia erlang cell is ~30 s at load 60, mostly
its compile and its test modules). What the stage's wall clock still waited for was the *order*:
the pool took cells in discovery order and onze-cli, the longest cell, was discovered late (started
at 244 s of a 473 s stage). `botopink-lib-test` now starts the cells longest-last-time first
(`schedule.zig`: the machine's duration history, unknown cells first, ties in plan order); every
spawning cell runs once and the output is still emitted in plan order. (a), a persistent test node,
is not built: after the fixes nothing measured points at it.

**Acceptance:**
- [x] stage 8 wall clock before/after (§ Measurements); CPU-s: 12 760 → ~1 850 — the work is the same cells, the CPU is the Debug compiler and the fixture compiles that are gone
- [x] `--jobs 1` and the default print the same bytes but for the timing values the children print (`--lib erika-linq` and `--lib std`, `--json`, durations stripped: one difference, the timestamp inside a TLS `NOTICE REPORT` run log)
- the isolation cell pair → `133-gate-speed` step 2 (the isolation pair of each target)

### Step 4 — `run.sh`: cells batched per target

(b) is what landed: the `std` compile of a cell is the ReleaseSafe compiler's (~0.1 s) and its OTP
check a verdict-cache hit; every job is ≤ 2 s wall. The stage is ~800 CPU-s of 1 241 jobs, and its
wall clock on the shared machine is the pool's admission yielding to the other threads (a job is
admitted while `procs_running` ≤ CPUs), not a job. (a) is not built. `run.sh --list` prints the
plan, and a run's `cells:` line is what `gate.sh` holds to it.

**Acceptance:**
- [x] `run.sh --target all` prints the same tally before and after: `language tests: 1515 passed, 0 failed`, `narrowings: 30 exclusions audited`, 1 241 jobs; wall clock before/after in § Measurements
- `run.sh --jobs 1` against the default, byte for byte → `133-gate-speed` step 2 (every cell's output byte-identical); here the runner's ordering is unchanged and the `cells:` line is a count

### Step 5 — the budget as acceptance; every stage's time in the report; nothing narrowed

`gate.sh` prints `✓ <stage> — <wall> wall, <n> CPU-s` for every stage and ends
`gate: every stage passed — <wall> wall, <n> CPU-s (budget 10m00s cold)`; over budget it prints
`gate: over budget — …; load …` in yellow and exits 0. Before stages 4b–10 start it reads the
plans (`scripts/test-libs.sh --list`, `tests/language/run.sh --list`, `scripts/check-docs.sh
--list`) and after stages 8, 9 and 10 it holds their tallies to them, failing the gate on any
difference (`plan: 134 cells and 38 audits, as --list declares`).

**Acceptance:**
- the idle-core runs under budget → `133-gate-speed` step 2 and § Gate (≤ 5 min cold, ≤ 1 min warm, decision 229); the loaded runs are in § Measurements
- [x] the report prints one time per stage and the total; `scripts/AGENTS.md` § gate.sh documents the line
- [x] stage 8 runs every cell the manifests declare (113's count), stage 9 every cell of four targets (111's count), stage 10 every fence (114's count) — the counts printed equal the `--list` counts, asserted by `gate.sh`

### Step 6 — the worktree script (carried from 25 § Not a step)

Meta `scripts/worktree-add.sh <name> [<base>]`: `git worktree add .tasks/<name> -b front/<name>`
under the main checkout, `git submodule update --init --recursive`, `core.hooksPath
scripts/git-hooks` in every submodule that tracks `scripts/git-hooks/pre-commit` (all seven), and
`repository/botopink-lang` on `front/<name>`; the meta `AGENTS.md` § Worktrees names it as the one
way to open a worktree.

**Acceptance:**
- [x] `scripts/worktree-add.sh x && git -C .tasks/x/repository/botopink-lang config core.hooksPath` → `scripts/git-hooks`; a commit in that worktree runs the gate (a probe worktree: `git commit --allow-empty` printed `── pre-commit ──` and `gate.sh --staged` queued on the gate lock; the probe was removed)
- [x] the meta `AGENTS.md` updated in the same commit

## Measurements

Every run: `scripts/gate.sh --cold` on this front's tree, 16 CPUs shared with the other
threads (load min / median / max over the run), the `.beam` cache warm. "Cold build" = the
compiler's sources changed, so stage 2 rebuilds the ReleaseSafe binaries.

| Stage | Before (Debug) | After, cold build | After, warm build | After, warm build, start order |
|---|---:|---:|---:|---:|
| load | 25 / 70 / 125 | 14 / 57 / 78 | 25 / 65 / 88 | 43 / 69 / 88 |
| 2 `zig build` | 9 s · 29 CPU-s (Debug, warm) | 3m17s · 684 | 0.2 s · 0 | 0.2 s · 0 |
| 4 `zig build test` | 52 s · 390 | 59 s · 361 (beside stage 2) | 57 s · 355 | 57 s · 356 |
| 4b parity | 7 s · 8 | 10 s · 10 | 10 s · 9 | 9 s · 9 |
| 5 `test-bpmp` | 3 s · 3 | 1 s · 1 | 1 s · 1 | 1 s · 1 |
| 6 beam export audit | 15 s · 90 | 20 s · 95 | 21 s · 92 | 18 s · 92 |
| 7 `test-cli` | 83 s · 75 | 44 s · 51 | 50 s · 51 | 49 s · 51 |
| 8 `test-libs` | 3339 s · 12 760 | 6m41s · 1 859 | 7m53s · 1 817 | 6m42s · 1 805 |
| 9 `test-language` | 1207 s · 1 279 | 7m41s · 798 | 7m52s · 802 | 8m00s · 795 |
| 10 `test-docs` | 25 s · 32 | 6 s · 8 | 7 s · 8 | 7 s · 8 |
| **gate** | **56m43s** | **11m00s · 3 865** | **8m52s · 3 136** | **9m00s · 3 116** |

Under this load stage 9 is the last to finish: its ~800 CPU-s are 1 241 jobs of ≤ 2 s, and its
pool, like stage 8's, admits a job only while the machine's runnable threads are at most its CPUs
— a pool that yields to the other threads, by design (25's rule).

The tallies are the same in every run: `test-libs: 119 passed, 0 failed, 15 without tests, 38
restrictions audited` (134 cells + 38 audits, the `--list` plan); `language tests: 1515 passed, 0
failed`, `narrowings: 30 exclusions audited`, 1 241 jobs on `*`, commonJS, erlang, wasm and beam;
`docs: 94 fences — 94 checked, 0 skipped, 0 failed`; `beam_export_audit: 490/490`.

The slowest cells, wall (load ~65): rakun-scheduling 1758 s → 66 s, onze-cli·erlang 1482 s →
222 s, rakun-messaging 1184 s → 48 s, rakun-data 1148 s → 57 s, onze-cli·commonJS 740 s → 189 s,
rakun-app 599 s → 77 s, emilia·erlang 285 s → 68 s.

What each change saves, measured alone:

| Change | Measured |
|---|---|
| ReleaseSafe binaries | `emilia-borders`·erlang 231 s → 31 s wall, 189 → 15 CPU-s, the same JSON (durations stripped) |
| scratch beside the run directory | rakun-scheduling: ~5 CPU-minutes per test module after its build tests → none; the cell 1758 s → 55–66 s (with ReleaseSafe) |
| erlang verdict cache | `emilia-borders` `botopink build --target erlang`, Debug: 28 s → 19 s, the 4 093 OTP compiles answered from the cache; same `out/`, same log |
| onze `compileBeam` on one `erlc` per CPU | onze-cli·erlang alone (ReleaseSafe): 305 s → 143 s, `build: the scaffold` 91 s → 38 s |
| stages 4, 4b, 5, 6 beside the build | stage 4's ~60 s and the audits' ~30 s leave the serial path |
| start order by duration history | onze-cli, the longest cell, starts at 0 s of stage 8 instead of 244 s; stage 8 7m53s → 6m42s at a similar load (65 → 69) |
| library hooks on a cell pool | emilia's hook (34 cells, 30 builds) 79 s at load ~50 — measured ~4 000 s serial with a Debug compiler; onze 222 s (its onze-cli cells), rakun 165 s, erika 7 s |

## Gate

- [x] `zig build test` from a cold runtime cache, green (stage 4 of every run above)
- [x] `scripts/gate.sh --cold` green, every stage's count equal to its `--list` — green with every count equal to its plan in every run, and on the integrated `feat` 2026-10-02 (12m16s at load, printed yellow over budget; 9m31s on the run before)
- under budget on the reference machine → `133-gate-speed` § Gate (idle runs)
- [x] `run.sh` identical tallies — identical in every run (§ Measurements); an empty-cache `test-libs` prints the warm run's 172 cell and audit lines and summary, line for line
- the per-cell emitted-module diff, warm vs empty cache → `131-gate-build-cache` step 3
- [x] `scripts/AGENTS.md`, `modules/compiler-cli/AGENTS.md` and `src/cli/AGENTS.md` (the scratch directory, the verdict cache), `modules/lib-test-runner/AGENTS.md` (the start order), `tests/language/AGENTS.md` (`--list`), the meta `AGENTS.md`, and each library's `AGENTS.md` (the hook's pool) updated in the same commits
- [x] the work is on `feat` in `repository/botopink-lang`, the five libraries and the meta repository

## Open

The front's code is on `feat`; its open measurements are carried:

- **The idle measurement** (steps 1, 5) → `133-gate-speed` steps 1–2, against decision 229's budget.
- **The per-cell `out/` diff** (step 2) → `131-gate-build-cache` step 3.
- **`run.sh --jobs 1`** and the isolation pair (steps 3, 4) → `133-gate-speed` step 2.
- **The Zig closure cache (step 2).** Moved to `131-gate-build-cache` (decision 225), with the
  stores this front put under `$XDG_CACHE_HOME/botopink`.
- **CI runs Debug binaries.** `.github/workflows/test.yml` builds with `zig build` (Debug); its
  `libs` job would run the same ~12× faster with `-Doptimize=ReleaseSafe`, the mode `release.yml`
  ships. Not this front's file.
- **A plain `zig build` after a gate** puts Debug binaries back into `zig-out/`, and the library
  hooks run whatever is there; a library thread that rebuilds Debug pays the Debug price in its
  hook.

## Blast radius

- Every later front runs a faster gate; none changes behaviour on this front's account.
- `../../01-compiler/26-cli-tooling` owns `compiler-cli/**` afterwards: the verdict cache is in
  `build.zig` and `libs.userCacheDir` names the per-user cache directory, both documented in
  `src/cli/AGENTS.md`; `botopink clean` (26's sentence) learns the cache directories.
- `../../01-compiler/25`'s carried rows (this README § Current state) close here; 25 has no
  directory in `01-compiler` (`../../01-compiler/carried.md` points here).

## Notes

- `persistent_erlang.zig` — the discarded design for comptime evaluation over a persistent `erl` —
  is not reopened by step 3; a test-runner node is a different process with a different owner, and
  even that is measured before it is written.
- Speed is measured on an idle machine only; a number taken under another gate's load is not a
  measurement (25's tables say so in every row).

# Front 25 — gate-perf

**Priority:** high — every front runs `scripts/gate.sh` before it lands, several at once on one
machine; a slow gate is paid by every landing
**Depends on:** none
**Owns:** `repository/botopink-lang/scripts/{gate.sh,check-docs.sh,test-libs.sh,lib/pool.sh}` ·
`repository/botopink-lang/modules/test-shard/**` · the compiler-core test step of `build.zig` ·
`repository/botopink-lang/tests/language/run.sh` (the runner only — not the cells, not
`expected-failures.txt`) · `repository/botopink-lang/modules/lib-test-runner/**` · the `AGENTS.md`
of those directories · no snapshot directory
**Does not touch:** `modules/compiler-core/**` (every front's), `modules/compiler-cli/src/cli/**`
beyond a measured row below, the language cells, `scripts/known-red-libs.txt`,
`scripts/restricted-targets.txt`, the libraries

---

## Problem

The gate (`scripts/gate.sh`, ten ordered stages) is the landing check of every front, and several
fronts run it at the same time on the maintainer's 16-CPU machine. It runs each stage one after the
other and several stages run their own work one item at a time. Decision 67 holds: the gate must
keep checking exactly what it checks — no flag, mode or skip list that makes it faster by looking
at less. The only admissible gains are doing the same work in less wall clock (bounded parallelism
whose output is byte-identical to the serial run) or doing the same work with less CPU (not
repeating a computation whose answer cannot differ).

## Current state

`botopink-lib-test` already runs its cells on a bounded pool (front `00 · gate-perf` step 1, landed:
one worker per CPU bounded by `MemAvailable / 768 MiB`, a cell admitted only while `procs_running` ≤
CPUs, cells emitted in discovery order). `botopink test --target erlang` already compiles every
`.erl` of a run once (`test_cmd.zig` `precompileErlang`), and `libs.shipErlSidecars` already asks
`sidecarOwner` once per library and probes each (owner, qualifier) pair once per run — the two
erlang items the step-1 line listed as next are landed; what they still cost is part of the
`test-libs` CPU below.

### How it was measured

`scripts/gate.sh`'s stages 2–10, in its order, each wrapped with bash `time` (wall, user, sys —
user and sys include every reaped child), from an rsync copy of this worktree at
`~/.cache/bp-gateperf/copy/` — outside `/home/ericfillipe/develop/botopink-lang`, because library
resolution walks up the tree and would find the main checkout's libraries too — with `TMPDIR` in
the same directory (the user's `/tmp` quota fills up under several agents and fails a run with
`EDQUOT`). The copy's `repository/botopink-lang` is a fresh `git init` of the tree (the gate asks
`git rev-parse --show-toplevel`). The harness is `~/.cache/bp-gateperf/timed-gate.sh`; unlike
`gate.sh` it continues past a red stage so that every stage is timed.

- **warm**: the runtime cache and the zig cache as the previous run left them.
- **cold**: `--cold` (the runtime cache deleted — the run that decides a merge), zig cache warm.
- **fresh**: `--cold` on a copy with no local `.zig-cache` (the compiler builds from source).

Machine: 16 CPUs, 30 GiB RAM, zig 0.16.0, OTP 29, node v25.8.0, wasmtime 45.0.0. **Load:** other
agents were running their own gates and `zig build test` on the same machine throughout (load
average 7–38 during the baseline); every number below is under that load, and a row is comparable
with another only as "same machine, similar load".

### Baseline per stage (compiler `82e32e36`, 2026-09-26)

| Stage | warm wall s | warm CPU s | cold wall s | cold CPU s | fresh wall s |
|---|---:|---:|---:|---:|---:|
| 2 `zig build` | 0.1 | 0.1 | 0.1 | 0.1 | 5.8 |
| 3 `format-check.sh` | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 |
| 4 `zig build test` | 25.9 | 29.4 | 138.0 | 257.6 | 146.9 |
| 4b `snap_audit.sh --mode=runtime-parity` | 2.9 | 6.3 | 2.5 | 5.6 | 2.6 |
| 5 `zig build test-bpmp` | 0.4 | 0.3 | 0.4 | 0.3 | 2.1 |
| 6 `beam_export_audit.sh` | 8.2 | 84.8 | 8.2 | 85.2 | 9.8 |
| 7 `zig build test-cli` | 16.9 | 33.7 | 16.9 | 33.8 | 17.0 |
| 8 `zig build test-libs` | 52.6 | 692.4 | 56.0 | 691.4 | 59.5 |
| 9 `zig build test-language` | 28.9 | 189.5 | 33.1 | 201.5 | 31.2 |
| 10 `zig build test-docs` | 8.4 | 8.3 | 9.5 | 9.3 | 8.6 |
| **total** | **144.3** | **1044.8** | **264.8** | **1284.9** | **283.6** |

Verdicts of that baseline, which every step must reproduce: every stage green except
`test-libs`, red at this compiler with the sibling checkouts of this worktree — four known reds that
now pass (`emilia-card·commonJS`, `jhonstart-html·commonJS`, `jhonstart-html·erlang`,
`jhonstart-todo·commonJS`) and two pinned counts that moved (`emilia-card·erlang`,
`jhonstart-todo·erlang`, `build→0`). That red is **real on `feat` at this pin, not an artifact of
the copy**: the meta commit pins jhonstart at its decision-102–104/128 sweep (`0c32c7b`, `9339f3f`),
which is what the "21-effect-chain window" lines of `scripts/known-red-libs.txt` waited for, and the
lines were not deleted when it landed — the landing front's edit, not this one's. The copy resolves
each library once (no ancestor of `~/.cache/bp-gateperf/copy` holds a `repository/` or `libs/`).
The stage's timing is valid all the same: `botopink-lib-test` runs every cell and the wrapper
decides the verdict after the last one, so a red `test-libs` did all of a green one's work.
`test-docs`' exit 1 in the step-1 comparison logs is the red fixture those runs were given on
purpose; on the real docs it exits 0 in every run. `test-language`: 644 passed, 29 expected failures,
0 failed. `test-docs`: 72 fences — 59 checked, 5 skipped, 0 failed.

Reading the table:

- **Warm, the gate is 144 s of which `test-libs` + `test-language` + `test-cli` are 98 s.** Only
  `test-libs` uses the machine (692 CPU-s in 53 s ≈ 13 CPUs); `test-language` ran 4 cells at a time
  (190 CPU-s in 29 s), `test-docs` and `test-cli` one thing at a time.
- **Cold adds 112 s, all in `zig build test`** — 258 CPU-s in 138 s, ≈ 1.9 CPUs: the codegen
  snapshots re-execute their RUN LOGs (node, erl, wasmtime) with the runtime cache empty.
- **The stages after `zig build test` are 118 s of wall clock and 1016 CPU-s** — about 64 s if the
  machine were ours alone, so running them side by side is worth more than any one of them.

## Steps

Ordered by measured gain. Every step proves equivalence against the previous behaviour — the same
stdout and stderr bytes (modulo the timings the children print), the same exit status, on the real
suite and on a fixture with a red cell — and adds its row to § Measurements.

### Step 1 — the shell runners on the shared bounded pool

`tests/language/run.sh` ran its cells 4 at a time (`--jobs 4`) with no admission control, and
`scripts/check-docs.sh` checked its fences one at a time. Both now take `botopink-lib-test`'s pool
rule from one file, `scripts/lib/pool.sh` (sourced): one job per CPU bounded by
`MemAvailable / 768 MiB`, and a job admitted only while `procs_running` ≤ CPUs whenever another job
of the same run is in flight. `run.sh` already wrote each verdict to its own file and sorted them
before comparing; `check-docs.sh` now writes its report in fence order with a placeholder per check,
runs the checks on the pool, and prints the report with each placeholder replaced by its verdict.

**Acceptance:**
- [x] `run.sh` and `check-docs.sh`, default vs `--jobs 1` vs the pre-change script: identical stdout,
      stderr and exit status — the whole language suite (644 passed / 29 expected / 0 failed, exit 0;
      default 18.3 s, `--jobs 1` 106.5 s, the old `--jobs 4` 28.8 s), `--target beam` (136 / 7 / 1,
      exit 1 — the one pre-existing `run/effect_method.bp` red), three red cells planted — a wrong
      `.out`, a parse error, a failing `assert` next to a passing one (646 / 29 / 8, exit 1); the docs
      (72 fences — 59 checked, 5 skipped, 0 failed; 8.5 s → 1.5 s, `--jobs 1` 9.0 s) and a docs
      fixture with a failing module fence, a failing `body` fence, a `skip` with no reason, a project
      with no `src/main.bp`, a failing project and an unknown directive (6 failed, exit 1)
- [x] § Measurements row

### Step 2 — the compiler-core suite as shards

What dominated `zig build test`, measured by running the compiler-core test binary by hand with a
timestamp per test line (`~/.cache/bp-gateperf/zbt/`): of the six test binaries, compiler-core is
2046 of the 2426 tests and all but ~1 s of the stage (the language-server's 216 tests take 0.6 s,
the other four under 0.2 s together). zig's default test runner is **serial inside one process**,
and the time is spread over hundreds of tests, none above 0.26 s warm or 1.5 s cold: warm it is
21.5 s, `codegen/tests` 17.0 s of it; from a cold runtime cache it is 134.8 s — `codegen/tests/wat`
22.6 s, `features` 21.1 s, `control_flow` 20.4 s, `builtins` 12.3 s, `dispatch` 10.0 s, … — each
test waiting on the `node` / `erlc` + `erl` / `wasmtime` its RUN LOG spawns (1111 executions fill the
cache). A serial process over a wait-bound suite is the whole cost.

`modules/test-shard/runner.zig` is zig 0.16's default runner restricted to the tests whose index is
`i` modulo `n` (`BOTOPINK_TEST_SHARD=<i>/<n>`, unset = every test), and `build.zig` runs the one
compiler-core test binary as `-Dtest-shards` run steps (default CPUs, at most 8) side by side. Every
test runs exactly once and is still reported by name through the build runner's protocol — failure,
leak, logged error, timeout. The suite was already written for concurrent processes over one
checkout (`test_scratch` roots per process, the runtime cache written by rename, the snapshot trace
opened `O_APPEND`), which is what makes the shards safe. Files outside the runners: `build.zig`'s
compiler-core test step and the new `modules/test-shard/`.

**Acceptance:**
- [x] the names the 8 shards run are exactly the unsharded binary's 2046, none twice; the build
      summary reads 2426/2426 at 1 shard and at 8
- [x] a planted failing test, a leaking test and a test that logs an error: each named, "2428/2429
      tests passed (1 failed)" and exit 1, at `-Dtest-shards=1` and at the default
- [x] § Measurements row

### Step 3 — the independent stages side by side

After `zig build test`, stages 4b–10 read the built tree and write only their own scratch
directories (`test-cli`'s scripts share `zig-out/` and fixture `out/` among themselves, which is why
they stay one stage, run in order). Run them concurrently with each stage's output captured and
printed as one block in `gate.sh`'s order; the gate's verdict is the first red stage **in that
order**, so the failure named is the one the serial gate names and the exit code is the same. The
"cheapest stage that can see it" guarantee keeps its meaning for stages 1–4 (they still gate
everything after them); among 4b–10 a red stage no longer saves the time of the stages after it —
the cost of a red run, not of a green one. The pools inside `test-libs` and `test-language` already
admit by `procs_running`, so two of them side by side share the CPUs instead of doubling the load.

**Acceptance:**
- [x] same stage blocks, same order, same exit status as the serial gate — compared on one copy of
      the tree with colours, random ids, seeds and timings stripped: identical with `test-libs` red
      (stage 8, both exit 1), all green (both exit 0 — the copy's `known-red-libs.txt` and
      `restricted-targets.txt` aligned with its libraries for the run, § Current state), a red
      language cell planted (stage 9, exit 1) and a red docs fence planted (stage 10, exit 1)
- [x] § Measurements row

### Step 4 — `test-libs`' erlang cells (open)

With steps 1–3 landed, `test-libs` is the gate's critical path: ~55–63 s of wall clock and ~690 of
its ~1100 CPU-seconds, running beside everything else. Measured cell by cell with
`botopink-lib-test --include-unsupported --jobs 1` (the stderr header of each cell timestamped;
the copy at `~/.cache/bp-gateperf/libs/`): **356 s serial, 257 s of it the erlang cells** against
99 s for commonJS. The longest cell is `emilia · erlang` (27.2 s), then `emilia-typography`
(14.5 s), `rakun` (14.5 s), `emilia-text-decoration` (11.7 s), `emilia-card` (11.1 s), `std`
(9.9 s); the fifteen `emilia-*` example members take 8–15 s each on erlang and ~4 s on commonJS.

One erlang cell traced (`strace -f -e execve`, `emilia/examples/emilia-borders`, 9.1 s wall /
22 CPU-s, commonJS 4.1 s): ~6 s compiling the project with its dependencies (`emilia`, `std`) in the
`botopink` process, ~3.3 s in `precompileErlang` compiling every emitted `.erl` once, ~2.5 s in the
`escript` that runs the tests. Every `emilia-*` member compiles the same `emilia` and `std` modules
to the same `.erl` text and then to the same `.beam`, fifteen times over, in every gate.

Remaining work, in order of measured size:
1. **A content-keyed `.beam` cache for `precompileErlang`** (`modules/compiler-cli/src/cli/test_cmd.zig`):
   the key is the `.erl` bytes, the compile options and the running OTP release; a hit copies the
   `.beam` beside the source, a miss compiles as today and publishes by rename (two gates share it),
   a source that does not compile is never cached (so its refusal is unchanged). ~3 s × ~30 erlang
   cells per gate. It needs a reaping rule like `clean-tmp`'s.
2. The per-cell compile of the same dependency modules (~4–6 s a cell on both targets) is the
   compiler's own pipeline (`compiler-core`) — a front of its own, after `front/24-integration`.

### Not a step: the hooks in worktrees

`git worktree add` of the meta repository shares the meta config, but each submodule of a worktree
is a separate git directory (`.git/worktrees/<name>/modules/repository/<sub>`) whose config has no
`core.hooksPath` — so `scripts/git-hooks/pre-commit` never runs on a compiler commit made in a
worktree (measured: `git config core.hooksPath` is empty in
`.tasks/25-gate-perf/repository/botopink-lang`). Proposal: a tracked meta script,
`scripts/worktree-add.sh <name>`, that runs `git worktree add .tasks/<name> -b front/<name>`,
`git submodule update --init --recursive` and then
`git -C .tasks/<name>/repository/botopink-lang config core.hooksPath scripts/git-hooks` (and the same
for every submodule that tracks a hook), with the meta `AGENTS.md` § Worktrees naming it as the one
way to open a worktree. A `post-checkout` hook cannot do it: it would itself have to be installed.

## Measurements

One row per landed step, cumulative. Wall and CPU in seconds; "rest" is stages 2, 3, 4b, 5 and 6.
Δ is the warm total against the baseline.

| Row | Date | Compiler | Warm total | Cold total | CPU warm | `zig build test` | `test-libs` | `test-language` | `test-cli` | `test-docs` | rest | Δ vs baseline (warm) | Load |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| baseline | 2026-09-26 | `82e32e36` | 144.3 | 264.8 | 1044.8 | 25.9 / 138.0 cold | 52.6 | 28.9 | 16.9 | 8.4 | 11.6 | — | other agents' gates; load 22–27 (cold run 22–24) |
| step 1 — the shell runners on the pool | 2026-09-26 | `112d248a` | 130.1 | 292.2 | 1071.0 | 23.6 / 154.4 cold | 56.5 | 19.9 | 17.5 | 1.5 | 11.3 | −14.2 s (−9.8 %) | other agents' gates; load 34–37 (cold run 7→37) |
| step 2 — compiler-core as 8 shards | 2026-09-26 | `49cc56aa` | 125.0 | 160.9 | 1099.5 | 6.8 / 33.7 cold | 63.5 | 21.4 | 18.5 | 1.8 | 13.0 | −19.3 s (−13.4 %); cold −103.9 s (−39.2 %) | other agents' gates; load 36–43 (cold run 11→36) |
| step 3 — stages 4b–10 side by side | 2026-09-26 | `9724b417` | 89.4 | 116.0 | 1119.7 | side by side | side by side | side by side | side by side | side by side | side by side | −54.9 s (−38.0 %); cold −148.8 s (−56.2 %) | other agents' gates; load 46–52, the heaviest of the four rows |

Step 3's row is `scripts/gate.sh` itself timed whole (stages 4b–10 overlap, so they have no wall
clock of their own), on the copy with its `test-libs` ledger aligned so every stage runs. Back to
back on that copy, warm, the serial gate took 125.5 s and the side-by-side one 101.5 s (load
35–48); with a red cell at stage 9 or 10, 102.8 → 81.5 s and 111.7 → 81.3 s. CPU-seconds stay
within 7 % of the baseline across the three steps — the work is the same, only its overlap moved.

Step 2's own gain is `zig build test` 25.9 → 6.8 s warm (−74 %) and 138.0 → 33.7 s cold (−76 %), at
+12 CPU-s warm (each shard starts its own process and `erl`). Its warm total moved less than that
because `test-libs` ran 7 s slower under a load of 36–43, a stage step 2 does not touch.

The cold total of step 1 is higher than the baseline's because the machine was: the stages step 1
does not touch moved by +16 s (`zig build test` cold) and +7 s (`test-libs`) between the two runs.
Per stage, step 1 is `test-language` 28.9 → 19.9 s warm (−31 %) and `test-docs` 8.4 → 1.5 s warm
(−82 %), at +1 % gate CPU-seconds (`test-language` 189.5 → 215.2 CPU-s; more of its cells overlap,
each a little slower). The earlier measurement that kept `--jobs 4` (`11-tooling`, "one job per CPU
moved nothing measurable") was without the admission rule and under a different load; the
comparisons above ran the three variants back to back on one tree.

## Gate

- [x] `zig build test` in this worktree before every commit (hooks do not run in worktrees)
- [x] the full suite a changed runner drives, before and after, with equivalent verdicts
- [x] `AGENTS.md` of every directory touched, updated in the same commit
- [x] Commit on `front/25-gate-perf`; no push, no merge

## Blast radius

None on the language: no cell, no snapshot, no expected-failure line moves. `front/24-integration`
adds ~150 language cells; they run on the same pool with no change. The pools raise the momentary
CPU demand of one gate — bounded by the admission rule, which is the same one `test-libs` has run
with since step 1 of `00 · gate-perf`.

## Notes

- **Outside this front, test-related, reported rather than fixed.** Under a load of ~40,
  `libs/std`'s `async: delay ---- takes at least the requested time` (`async.bp:265`, commonJS)
  failed once in the unchanged serial gate and passed on every other run — a wall-clock assertion
  that reds under load. The tests front owns it.
- `scripts/known-red-libs.txt` / `scripts/restricted-targets.txt` are stale at this pin (§ Current
  state); the comparisons that needed a green `test-libs` aligned them in the measurement copy only.
- Files touched outside `scripts/` and the runners: `build.zig` (the compiler-core test step, step
  2), the new `modules/test-shard/`, and the `AGENTS.md` of the root, `modules/`, `scripts/` and
  `tests/language/`.

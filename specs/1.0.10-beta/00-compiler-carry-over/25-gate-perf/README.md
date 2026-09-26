# Front 25 — gate-perf

**Priority:** high — every front runs `scripts/gate.sh` before it lands, several at once on one
machine; a slow gate is paid by every landing
**Depends on:** none
**Owns:** `repository/botopink-lang/scripts/{gate.sh,check-docs.sh,test-libs.sh,lib/pool.sh}` ·
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
- [ ] `run.sh` and `check-docs.sh`, default vs `--jobs 1` vs the pre-change script: identical stdout,
      stderr and exit status on the real suite and on a fixture with red cells
- [ ] § Measurements row

### Step 2 — the independent stages side by side

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
- [ ] same stage blocks, same order, same exit status as the serial gate — green, and with a red
      stage planted in the middle and at the end
- [ ] § Measurements row

### Step 3 — `test-libs`' CPU (692 CPU-s warm, the largest cost)

To measure per cell (`botopink test` per library and target): which part is compile, comptime
`erl`, `precompileErlang`, `escript` start-up per test module. Candidates only after the measurement
names the dominant one.

### Step 4 — `zig build test` from a cold runtime cache (138 s, ≈ 1.9 CPUs used)

The snapshot RUN LOG executions run with little parallelism. The executor is
`modules/compiler-core/src/codegen/runtime.zig`, every compiler front's file: measure which tests
dominate and propose; a change there waits until front 24 has landed.

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
| baseline | 2026-09-26 | `82e32e36` | 144.3 | 264.8 | 1044.8 | 25.9 / 138.0 cold | 52.6 | 28.9 | 16.9 | 8.4 | 11.6 | — | other agents' gates, load 7–38 |

## Gate

- [ ] `zig build test` in this worktree before every commit (hooks do not run in worktrees)
- [ ] the full suite a changed runner drives, before and after, with equivalent verdicts
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Commit on `front/25-gate-perf`; no push, no merge

## Blast radius

None on the language: no cell, no snapshot, no expected-failure line moves. `front/24-integration`
adds ~150 language cells; they run on the same pool with no change. The pools raise the momentary
CPU demand of one gate — bounded by the admission rule, which is the same one `test-libs` has run
with since step 1 of `00 · gate-perf`.

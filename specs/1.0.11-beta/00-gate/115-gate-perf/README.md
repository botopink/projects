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

```
$ time scripts/gate.sh --cold            # at the open, through a copy that continues past reds
stage 8  test-libs       1944 s
stage 9  test-language    794 s
stage 4  zig build test    41 s (cold)
…                                        # ≈ 50 min wall clock, dominated by test-libs
```

Measured at the open (report A; load 58–68 on 16 CPUs — other gates were running; the numbers are
inflated and are a ceiling, not a baseline). For scale, `1.0.10-beta`'s `25-gate-perf` measured
the same gate at its close, warm, with the ledger aligned: `test-libs` 69.5 s, `test-language`
~20 s, the whole gate 131.5 s warm / 268.6 s cold (`specs/1.0.10-beta/00-compiler-carry-over/25-gate-perf/README.md`
§ Measurements, load 45–73); `run.sh --target beam` alone 28 s at the open (`lang_beam.txt`);
warm `zig build test` ~7 s (25's step 2). The two measurements differ by an order of magnitude and
neither was taken on an idle machine — step 1 settles what the gate costs.

What is known about where the time goes (25's step 4 trace of one erlang cell, 9.1 s wall):
~6 s compiling the project *with its dependencies* in the `botopink` process, ~3.3 s
`precompileErlang` (now served by the `.beam` cache, `test_cmd.zig:167`), ~2.5 s the `escript`
that runs the tests. The first part is the one 25 left: "the per-cell compile of the same
dependency modules (~4–6 s a cell on both targets): it is the compiler's own pipeline, a front of
its own" — every `emilia-*` member compiles `emilia` and `std` again; every rakun member compiles
`rakun` and `std` again; 113's restriction audit adds 39 such builds.

## Current state

| Stage | What it re-does per cell | Parallelism today |
|---|---|---|
| 4 `zig build test` | 8 shards (25 step 2) | the build system's |
| 4b–10 side by side | one process each (25 step 3), each with a bounded pool (`lib/pool.sh`) | pools admit a job while runnable threads ≤ CPUs |
| 8 `test-libs` | per cell: resolve the closure (`libs.zig:232` `loadDependencies`, `:328` `DepClosure`), compile every module of every dependency, emit, ship sidecars, precompile (`.beam` cache hit), run | `botopink-lib-test --jobs` (default one per CPU bounded by memory) |
| 9 `test-language` | per (cell, target): `botopink build`/`run`/`test`, one process; `test/` cells compile `std` each time | `run.sh --jobs`, `xargs -P` (`run.sh:440`) |
| 10 `test-docs` | per fence: a scratch project and `botopink check` | `pool.sh` |

Carried from 25 (`§ Not a step`): the hooks in worktrees — a submodule of a meta worktree has no
`core.hooksPath`, so `scripts/git-hooks/pre-commit` never runs on a compiler commit made in a
worktree (measured there: `git config core.hooksPath` empty in
`.tasks/<name>/repository/botopink-lang`); proposal: a tracked meta `scripts/worktree-add.sh <name>`
that adds the worktree, inits submodules, and sets `core.hooksPath scripts/git-hooks` in every
submodule that tracks a hook, named by the meta `AGENTS.md` § Worktrees as the one way to open a
worktree. It is this front's because the gate that is not run is the slowest gate of all.

## Mechanism

Three costs, three tools: (1) the same dependency closure compiled once per cell — a cache keyed by
content; (2) cells serialised where they could overlap, and an `erl` node started per cell — a
pool; (3) no number printed per stage — nobody can see which stage moved. None of them changes
what a stage asserts.

## Steps

### Step 1 — the baseline: every stage from a cold cache on an idle machine

`scripts/gate.sh --cold` in the main checkout with every `00-gate` front landed, on 16 cores with
nothing else running (load < 2 at start, recorded), three runs; per stage: wall, CPU-seconds
(`/usr/bin/time -v` or `perf stat` per launched stage), and — for stages 8 and 9 — the per-cell
serial cost (`botopink-lib-test --jobs 1` timestamped; `run.sh --jobs 1`). Record the table here:

| Stage | Wall (s) | CPU-s | Per-cell serial | What it re-does per cell |
|---|---:|---:|---|---|
| 2, 3, 4, 4b, 5, 6, 7, 8, 9, 10 | … | … | … | … |

From the table, **set the budget**: the acceptance of step 5 is a number this step derives and
writes into this README before step 2 starts. The derivation: the cold `zig build test` floor
(≈ 34 s at 25's step 2) plus the longest of the side-by-side stages after steps 2–4, plus 20 %
headroom; the working assumption from 25's numbers is **≤ 10 min cold on 16 idle cores**, and
**≤ 5 min warm** — amended by the measurement, never by dropping a stage.

**Acceptance:**
- [ ] the table filled from three runs (median), with the load and the commit
- [ ] the budget written in step 5 and in `../README.md` § Exit gate

### Step 2 — the dependency-closure compile cache

One compile of a dependency closure per gate run: `libs.zig`'s `loadDependencies`/`DepClosure`
(`:232-378`) resolves the closure per cell and the CLI compiles every module of it. Cache the
*result* of compiling a dependency package for a target — keyed by the content hash of the
package's sources + manifest + the compiler binary's hash + target + the options that reach the
emitter — so that the second cell that needs `emilia` on erlang reads the emitted modules (and
their typed export tables) instead of compiling them. Where it lives: 25 measured that a
per-project `.botopinkbuild/` shares nothing across cells because each cell runs from its own
directory; the `.beam` cache went to `${XDG_CACHE_HOME:-$HOME/.cache}/botopink/beam/`. Options:
(a) the same machine-wide store, `…/botopink/closure/<k[0..2]>/<k>/` (shared by every checkout
and gate; reaped by age like the `.beam` cache); (b) the checkout root's `.botopinkbuild/closure/`
(the gate runs from the root; `test-libs` cells run from member directories but the runner knows
the root). **Recommend (a)** — it is the `.beam` cache's model, already reaped and race-safe
(staging + rename), and a worktree gate benefits from the main checkout's entries. The key must
include the compiler binary's hash: an entry from another compiler is a miss, never a wrong
module. A hit is verified the way 25 verified `.beam` hits: cells compiled with a warm cache and
with none produce byte-identical outputs and identical test logs (ids and timings stripped).
The restriction audit (113) uses the same cache: 39 builds that share rakun's closure.

**Acceptance:**
- [ ] `zig build test-libs` with an empty cache and warm: the same cell lines, the same passed count, byte-identical emitted modules for every cell (a script diffs `out/` trees)
- [ ] one byte changed in `libs/std/src/collections.bp` → every entry that includes std is a miss (a new key), nothing stale served
- [ ] the compiler binary rebuilt with one changed emitter line → every entry a miss
- [ ] stage 8 wall clock and CPU-s before/after in this README's table

### Step 3 — `test-libs` cell parallelism bounded by cores, the erlang node reused

The runner's `--jobs` is one per CPU bounded by memory; measure whether cells actually overlap
(the pool's admission vs. the erlang cells' own `erl` start-up: each cell starts an `escript`/`erl`
— 2.5 s of the 9.1 s trace). Options: (a) a persistent `erl` node per gate run that loads each
cell's `.beam` into a fresh code path and runs its tests in an isolated process group (the model
`persistent_node` uses for comptime — **never** the discarded `persistent_erlang.zig` design for
comptime evaluation; this is the test runner's own node, started and stopped by the gate); (b) keep
one `erl` per cell and only fix the pool's admission. Measure (b) first; (a) only if start-up is the
remaining cost after step 2. Every cell's isolation is asserted: a test that leaves a process
registered or an ETS table behind must not be visible to the next cell (a synthetic pair of cells
pins it).

**Acceptance:**
- [ ] stage 8 wall clock before/after; CPU-s within 10 % (the work is the same)
- [ ] the isolation cell pair green; `--jobs 1` and the default print the same bytes (25 step 1's rule)

### Step 4 — `run.sh`: cells batched per target

`run.sh` runs one `botopink` process per (cell, target). Options: (a) `botopink build` of every
`run/` cell of one target in one process (the CLI compiles `std` once and emits N programs), then
run each; (b) the closure cache of step 2 applied to `std` so each process's compile is a hit.
Measure both; (b) comes for free from step 2 and may be enough. The `test/` cells and `modules/`
cells keep one process each (a `botopink test` is a project). Nothing about which cells run on
which target moves (111's audit stays the runner's).

**Acceptance:**
- [ ] `run.sh --target all` prints the same tally and the same per-cell lines before and after; wall clock before/after in the table
- [ ] `run.sh --jobs 1` and the default: the same bytes

### Step 5 — the budget as acceptance; every stage's time in the report; nothing narrowed

`gate.sh`: each `report` line prints the stage's wall clock and CPU-s (`launch` records start/end;
stages 2–4 timed inline) and the final line prints the total: `gate: every stage passed — 4m12s
wall, 1180 CPU-s (budget 10m00s cold)`. A run over the budget does **not** fail the gate (a slow
machine is not a red) — it prints `over budget` in yellow and the number, and this front's
acceptance is the number on the reference machine. What *does* fail: any stage that ran fewer
cells than the manifests and the trees declare — `gate.sh` compares the counts stages 8 and 9
print with the counts a `--list` of each runner prints, so a stage cannot be narrowed to win time.

**Acceptance:**
- [ ] `scripts/gate.sh --cold` on 16 idle cores: wall ≤ the budget step 1 wrote (working assumption ≤ 10 min cold, ≤ 5 min warm); three runs, median, recorded here
- [ ] the report prints one time per stage and the total; `scripts/AGENTS.md` § gate.sh documents the line
- [ ] stage 8 runs every cell the manifests declare (113's count), stage 9 every cell of four targets (111's count), stage 10 every fence (114's count) — the counts printed equal the `--list` counts, asserted by `gate.sh`

### Step 6 — the worktree script (carried from 25 § Not a step)

Meta `scripts/worktree-add.sh <name>`: `git worktree add .tasks/<name> -b front/<name>`,
`git submodule update --init --recursive`, then `git -C .tasks/<name>/repository/<sub> config
core.hooksPath scripts/git-hooks` for every submodule that tracks `scripts/git-hooks/pre-commit`;
the meta `AGENTS.md` § Worktrees names it as the one way to open a worktree (and the manual
sequence is deleted from the section). A `post-checkout` hook cannot do it (it would itself have
to be installed).

**Acceptance:**
- [ ] `scripts/worktree-add.sh x && git -C .tasks/x/repository/botopink-lang config core.hooksPath` → `scripts/git-hooks`; a commit in that worktree runs the gate
- [ ] the meta `AGENTS.md` updated in the same commit

## Gate

- [ ] `zig build test` from a cold runtime cache, green
- [ ] `scripts/gate.sh --cold` green, under budget on the reference machine, every stage's count equal to its `--list`
- [ ] `zig build test-libs` byte-identical outputs warm vs. empty cache; `run.sh` identical tallies
- [ ] `scripts/AGENTS.md`, `modules/compiler-cli/AGENTS.md` (the closure cache), `modules/lib-test-runner/AGENTS.md`, the meta `AGENTS.md` updated in the same commits
- [ ] commits on `fix/gate-perf` in `repository/botopink-lang` and `front/gate-perf` in the meta repository; no push, no merge

## Blast radius

- Every later front runs a faster gate; none changes behaviour on this front's account.
- `../../01-compiler/26-cli-tooling` owns `compiler-cli/**` afterwards: the closure cache is in
  `libs.zig` and is documented there; `botopink clean` (26's sentence) learns the cache directory.
- `../../01-compiler/25`'s carried rows (this README § Current state) close here; 25 has no
  directory in `01-compiler` (`../../01-compiler/carried.md` points here).

## Notes

- `persistent_erlang.zig` — the discarded design for comptime evaluation over a persistent `erl` —
  is not reopened by step 3; a test-runner node is a different process with a different owner, and
  even that is measured before it is written.
- Speed is measured on an idle machine only; a number taken under another gate's load is not a
  measurement (25's tables say so in every row).

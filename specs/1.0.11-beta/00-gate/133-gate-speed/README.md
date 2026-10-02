# Front 133 — gate-speed: 5 minutes cold, 1 minute warm, nothing skipped but by equal content

**Priority:** high — decision 229: the cold gate (the run that decides a landing) under 5 minutes on
16 idle cores, and a warm run under 1 minute, with test consistency untouched.
**Depends on:** `115-gate-perf` (the stage times, plan counts and budget it built), `131-gate-build-cache`
(every cache under `.botopinkbuild/cache/`; this front's cell-result store lives beside it and follows
the same rules), the gate green on `feat`.
**Owns:** `scripts/gate.sh` (`budget_cold`, `budget_warm`, the warm/cold contract), `tests/language/run.sh`,
`scripts/test-libs.sh`, `modules/lib-test-runner/**` (the cell-result store and the per-cell cost),
`scripts/check-docs.sh` (its per-fence cost), `modules/compiler-cli/src/cli/{test_cmd,run}.zig` (what a
cell spawns), this README's measurement tables, and the `AGENTS.md` of each directory touched.
**Does not touch:** what any stage runs (cells, targets, fences, audits); the checker's rules; the
emitters' output; snapshots. A stage that runs fewer cells, or answers a cell from anything but an
identical input, is this front's defect.

---

## The rule (decision 229)

1. **Cold ≤ 5 min** wall on 16 idle cores (`budget_cold=300`). `--cold` runs every cell, fence and
   audit from scratch — no result store is read. It decides every landing.
2. **Warm ≤ 1 min** wall on the same machine (`budget_warm=60`), after a change to a few files. A
   warm run may answer a cell from a stored result **only when the cell's key is equal**: the
   compiler binary's build id, the target, the runtime's version (`node`, OTP release, the wasm
   runner), and the SHA-256 of every byte the cell reads (its sources, its manifest, its `.expect` /
   `.out` files, every dependency package's sources, std). A key that differs in one byte runs the
   cell. No dependency analysis decides what to skip — equal content does.
3. **Only passes are stored.** A failed cell runs again on every run, as the erlang verdict cache
   stores only acceptances (115).
4. **The store lives in `.botopinkbuild/cache/results/`** (decision 225's layout): deleting
   `.botopinkbuild/` wipes it, `--cold` neither reads nor writes it.
5. **No persistent runtime process.** A long-lived `erl` / node / test server across cells or runs
   is out (the maintainer's standing rule against `persistent_erlang`); per-cell cost is cut inside
   the cell's own process.
6. Over budget stays a printed yellow line, never a red (115): a slow machine is not a broken tree.

## Problem

Each stage's own command, run one at a time on 16 cores **loaded** by three other worktree threads
(load min / median / max over each stage's run in § Measurements), with the ReleaseSafe binaries of
stage 2 — CPU-s is the load-robust figure, wall is indicative only:

| Stage | Wall | CPU-s | Share | Runs in the gate |
|---|---:|---:|---:|---|
| 2 `zig build` ReleaseSafe, local Zig cache cold (global cache warm) | 2m41s | 323 | 7 % | serial |
| 2 `zig build` ReleaseSafe, warm | 0.2s | 0 | — | serial |
| 3 `format-check.sh` | 0.1s | 0 | — | serial |
| 4 `zig build test`, Debug build and runtime cache cold | 2m34s | 436 | 10 % | beside 2 |
| 4 `zig build test`, warm | 15s | 62 | — | beside 2 |
| 4b runtime parity · 5 `test-bpmp` · 6 beam export audit | 6s · 3s · 18s | 9 · 4 · 105 | 3 % | beside 2 |
| 7 `test-cli` | 1m12s | 67 | 2 % | side by side |
| 8 `test-libs` (138 cells, 38 audits) | 5m37s | **2144** | **48 %** | side by side |
| 9 `test-language` (1616 jobs) | 6m53s | **1332** | **30 %** | side by side |
| 10 `test-docs` (100 fences) | 10s | 10 | — | side by side |
| 11 `tsc-check.sh` | 13s | 13 | — | side by side |
| **total, cold** | | **4443** | | |

The gate's own `--cold` run, loaded, measured 4503 CPU-s and 9m31s: within 2 % of this total. 4443 CPU-s on 16
cores is 4m38s with perfect packing, so 5 min cold needs **less CPU**, not only better scheduling;
1 min warm needs most cells answered from the store.

**The three biggest CPU sinks**, of the 4443:

1. **`test-libs` erlang cells — 1720 CPU-s, 39 %** (emilia 621, onze 536, rakun 419, jhonstart 80,
   std and libs 58, erika 6).
2. **`test-language` erlang and beam jobs — 1139 CPU-s, 26 %** (erlang 709, beam 430). The
   commonJS, wasm and `reject/` jobs together are 57.
3. **The Zig builds — 759 CPU-s, 17 %**: stage 4's Debug test binaries (436) and stage 2's
   ReleaseSafe binaries (323), both only when the compiler's sources changed.

Behind sinks 1 and 2 is one mechanism: **an `erl` start costs 0.34 CPU-s for 0.1 s of wall**, 0.21
CPU-s of it the idle schedulers' busy wait (16 schedulers, 16 dirty-CPU, 10 dirty-IO), and an erlang
cell starts four VMs (two in `botopink build`, `compileAll`, the program), a beam cell three. The
compiler itself is ~0.06 CPU-s of a cell. Outside the gate (`ERL_FLAGS="+sbwt none +sbwtdcpu none
+sbwtdio none"`, nothing else changed, the same verdicts but for one isolation flake, § Measurements) stage 9 fell 1332 → 826 CPU-s and stage 8
2144 → 1557: **~1090 CPU-s, a quarter of the gate, is erl schedulers spinning**.

The biggest single cell: `onze-cli`·commonJS, 337 CPU-s and 3m36s wall alone (none of it `erl`);
`onze-cli`·erlang is 4m41s wall under this load — each longer than the 2m20s a 5-minute cold gate
leaves after a cold stage 2.

## Steps

### Step 1 — where the CPU goes

Per stage, per target and per cell kind: CPU-s and wall, and inside a cell the split between the
compiler (check, emit), the runtime spawn (`erl` start, `node` start, wasm runner) and the program
itself. Three cold runs on an idle machine (the median), and the same with a warm Zig cache.

**Acceptance:**
- [ ] the table above re-measured idle, plus: `test-language` per target (commonJS, erlang, wasm,
      beam) and per cell kind (`run/`, `test/`, `modules/`, `reject/`, audits); `test-libs` per
      library; each cell's compile / spawn / run split for a sample of 50 cells per target
- [x] the three biggest CPU sinks named, each with its share of the total
- [x] the compiler's own throughput: `botopink build` of rakun's whole workspace and of `libs/std`
      per target, cold and warm Zig cache — lines of `.bp` per second for check and for emit, peak
      memory — beside the same measure for comparable compilers on comparable code where one can be
      run here (Gleam on a project of similar size, `tsc --noEmit` on the emitted `.d.ts`), each with
      its version and command, so the comparison can be repeated

### Step 2 — cold under 5 minutes

Cut the CPU found in step 1 without changing what runs — candidates, ordered by step 1: the
compiler work a cell repeats (std and the dependency closure typed once — 131's cache serves the
dependencies, never the cell's own sources); a runtime start per cell that can be one start per
batch of cells **inside one run** only where the cells cannot observe each other (separate module
namespaces, no shared process state — each batch member's output byte-identical to its solo run,
asserted by an isolation pair per target); the order cells start (the longest first, 115's schedule)
so the critical path ends with the rest.

**Acceptance:**
- [ ] `scripts/gate.sh --cold` ≤ 5 min wall on 16 idle cores, three runs, median, every stage's
      count equal to its `--list` plan
- [ ] every cell's output byte-identical to the pre-front run (a script diffs every cell's printed
      result and every emitted module) — consistency is measured, not assumed
- [ ] the isolation pair of each target green (a cell that would see another's state fails it)

### Step 3 — the cell-result store and warm under 1 minute

The store of rule 2–4: written only on a pass, keyed by the full content key, read only by a run
without `--cold`. `run.sh`, `test-libs.sh` and `check-docs.sh` print, per stage, how many cells ran
and how many were answered from the store (`1616 jobs — 31 run, 1585 from store`), so a reader sees
what was not executed.

**Acceptance:**
- [ ] after a cold run, a warm run with no change answers every pass from the store and runs every
      failure; ≤ 1 min wall
- [ ] one byte changed in a cell's `.bp` → that cell runs; in `libs/std/src/collections.bp` → every
      cell whose key includes std runs; the compiler rebuilt with one changed emitter line → every
      cell runs
- [ ] a changed `node` or OTP release → every cell of that target runs
- [ ] `rm -rf .botopinkbuild` → the next run is cold in effect (nothing answered from the store)
- [ ] a typical change (one compiler source file, the cells it affects) ≤ 1 min wall, measured

## Measurements

Step 1's numbers, every one on 16 cores **loaded** by other worktree threads (load1 sampled every
5 s; min / median / max per run below). CPU-s is user + sys of the command and every child it
waited for (`getrusage(RUSAGE_CHILDREN)`), peak memory is the largest single process's max RSS.
Toolchain: zig 0.16.0, OTP 28 (erts 16.4, via mise), node v25.8.0, wasmtime from `~/.wasmtime`.
**Needs an idle machine to confirm:** every wall clock here; the three-run medians the acceptance
asks for (each stage ran once); and the busy-wait saving — an idle machine has more idle schedulers
spinning, so the default's cost there may be larger, and contention inflates CPU-s by an unknown
few per cent under load.

### Per stage, load

| Stage | Load min / median / max |
|---|---|
| 2 `zig build` cold | 11 / 24 / 80 |
| 4 `zig build test` cold | 61 / 81 / 95 |
| 7 `test-cli` | 83 / 87 / 97 |
| 8 `test-libs` | 31 / 90 / 121 |
| 9 `test-language` | 9 / 70 / 85 |
| 4b, 5, 6, 10, 11 | 76 / 79 / 88 |

### `test-language` per target and cell kind

CPU-s of each job's one `botopink` command (`run`, `test`, `check`, `build`) with everything it
spawns; jobs / CPU-s. The stage's 1332 CPU-s are these 1196, the `--self-test` suite's 28 jobs (15)
and the runner's own shell, `node` and pool work (121).

| Kind | commonJS | erlang | wasm | beam | `*` | all |
|---|---:|---:|---:|---:|---:|---:|
| `run/` | 203 / 16.4 | 206 / 427.4 | 191 / 11.2 | 206 / 260.2 | | 806 / 715.1 |
| `test/` | 69 / 5.7 | 69 / 129.1 | | 69 / 67.8 | | 207 / 202.5 |
| `modules/` (run kind) | 83 / 6.4 | 84 / 143.8 | 81 / 4.6 | 84 / 95.8 | | 332 / 250.6 |
| `modules/` (test kind) | 4 / 0.4 | 5 / 8.6 | | 5 / 5.8 | | 14 / 14.7 |
| `reject/` | | | | | 222 / 11.1 | 222 / 11.1 |
| audits | 8 / 0.5 | 3 / 0.2 | 21 / 1.2 | 3 / 0.2 | | 35 / 2.0 |
| **all** | **367 / 29.3** | **367 / 709.0** | **293 / 17.0** | **367 / 429.7** | **222 / 11.1** | **1616 / 1196.2** |
| CPU-s per job | 0.08 | 1.93 | 0.06 | 1.17 | 0.05 | 0.74 |
| all, erl busy wait off | 30.2 | 381.3 | 17.4 | 256.5 | 9.9 | 695.3 |

No job exceeds 2.7 CPU-s; half the CPU is in the 290 costliest jobs, all erlang or beam. The
`run.sh` report is the same in both runs: `language tests: 2061 passed, 0 failed`, 1616 jobs.

### `test-libs` per library

Cells / CPU-s per repository and target (the commonJS rows of rakun are its 36 audits), then the
costliest cells. Wall is the cell's own, under load.

| Repository | commonJS | erlang | erlang, busy wait off |
|---|---:|---:|---:|
| emilia | 17 / 34 | 17 / 621 | 415 |
| onze | 9 / 352 | 9 / 536 | 343 |
| rakun | 36 / 14 | 36 / 419 | 293 |
| jhonstart | 15 / 7 | 15 / 80 | 49 |
| botopink-lang (`libs/*`, std, examples) | 6 / 3 | 6 / 58 | 36 |
| erika | 3 / 1 | 3 / 6 | 4 |
| **all** (cells and audits) | **86 / 411** | **86 / 1720** | **1140** |

| Cell | CPU-s | Wall |
|---|---:|---:|
| `onze-cli`·commonJS | 337 | 3m36s |
| `emilia`·erlang | 145 | 2m31s |
| `onze-bundler`·erlang | 108 | 1m58s |
| `onze-cli`·erlang | 95 | 4m41s |
| `onze-assets`·erlang | 82 | 1m41s |
| `blog`·erlang | 74 | 1m31s |
| `rakun-app`·erlang | 66 | 1m56s |
| `onze`·erlang | 62 | 1m14s |
| `onze-release`·erlang | 53 | 1m09s |
| each of the 15 `emilia-*` examples·erlang | 28–32 | 16–33s |

Stage total 2144 CPU-s (1557 with the busy wait off). In the second run `onze-assets`·commonJS
failed once — `gate: no onze module calls flush() or defines a sink` walks `..` with `fs.walk`
while sibling cells write their `.botopinkbuild/` trees; a cell that sees another's files is the
isolation defect step 2 asserts against.

### Inside a cell: compile, runtime start, program

50 `run/` cells (every 3.5th of the 176 without a `.targets`, `.exit` or `.expect` sidecar), each
on each target: `botopink build` (B), `botopink run` (T) and the runtime alone on the built output
(X: `node out/main.js`, `wasmtime out/main.wat`, `erl -noshell -pa out/<erl|beam> -eval
"'language_tests@main':main([]), halt()."`); the same for `pub fn main() { @print("hi"); }` (X₀).
Program = X − X₀; runtime start and load = (T − B) − program. Mean CPU-s per cell:

| Target | Compile (B) | Runtime start + load | Program | Cell (T) | Hello world (T) | VMs started |
|---|---:|---:|---:|---:|---:|---|
| commonJS | 0.059 | 0.035 | 0.00 | 0.092 | 0.094 | 1 `node` |
| wasm | 0.053 | 0.010 | 0.00 | 0.063 | 0.059 | 1 `wasmtime` |
| erlang | 0.860 | 0.871 | 0.025 | 1.756 | 1.670 | 4 `erl`: 2 in `build`, `compileAll`, the program |
| beam | 0.428 | 0.829 | 0.030 | 1.288 | 1.206 | 3 `erl`: 1 in `build`, `compileAll` (`+from_asm`), the program |

The compiler's own check and emit is the commonJS/wasm `B`, ~0.06 CPU-s; the rest of an erlang or
beam `B` is the `erl` it starts. The programs themselves cost nothing measurable.

One `erl` start, 10 runs, mean:

| Command | CPU-s | Wall |
|---|---:|---:|
| `erl -noshell -eval 'halt().'` (through the mise shim) | 0.351 | 0.10 s |
| the same, the `erl` script directly | 0.335 | 0.10 s |
| `+sbwt none +sbwtdcpu none +sbwtdio none` | 0.121 | 0.09 s |
| `+S 1:1` | 0.116 | 0.09 s |
| `+S 1:1` and the three `+sbwt… none` | 0.095 | 0.10 s |
| `node -e 0` | 0.017 | 0.02 s |

### The compiler's throughput

`botopink check` and `botopink build --target <t>` in a copy of the project; cold = no
`.botopinkbuild/` and no `out/`, warm = the same command again. Median of three; lines are the
`src/` `.bp` lines. There is no phase-timing flag: check is `botopink check`, emit is build − check.

| Project | Command | CPU-s cold / warm | Wall cold | Peak RSS | Lines per CPU-s |
|---|---|---:|---:|---:|---:|
| `libs/std` (10 668 lines, 32 modules) | `check` | 0.146 / 0.154 | 0.15 s | 136 MB | 73 000 |
| | `build --target commonJS` | 0.181 / 0.181 | 0.19 s | 131 MB | emit ~300 000 |
| | `build --target erlang` | 0.968 / 1.002 | 0.97 s | 123 MB | (OTP verification `erl`) |
| | `build --target beam` | 0.549 / 0.556 | 0.83 s | 124 MB | (one `erl`) |
| | `build --target wasm` | 0.149 / 0.139 | 0.17 s | 132 MB | refused: std's host functions have no wasm binding |
| rakun core (8 958 lines + std, 49 modules) | `check` | 0.42 / 0.42 | 0.8 s | 541 MB | ~47 000 with std |
| rakun workspace (35 members, 37 090 own lines) | `check`, Σ members | 10.6 / 10.6 | 25.5 s | 541 MB | each member re-checks rakun core and std |
| | `build --target erlang`, Σ members | 48.2 / 45.2 | 73.3 s | 337 MB | |

Warm equals cold: the compiler keeps no per-module result between runs (131's cache is not on this
branch). `rakun-starter-test` is left out: its `onze` path dependency is outside the copy.

The same measure beside it — Gleam 1.19.0-rc3 (built from source, release profile) on
`gleam_stdlib` 1.0.5 (9 699 lines in `src/`, no dependencies), cold = `rm -rf build/dev build/prod`;
and TypeScript 7.0.2 (`npx -y -p typescript@7.0.2`, as `scripts/tsc-check.sh` pins it):

| Compiler | Command | CPU-s cold / warm | Peak RSS | Lines per CPU-s, cold |
|---|---|---:|---:|---:|
| Gleam | `gleam check --target javascript` | 0.119 / 0.017 | 44 MB | 81 000 |
| Gleam | `gleam check --target erlang` | 0.649 / 0.595 | 85 MB | (starts `erl`) |
| Gleam | `gleam build --target javascript` | 0.184 / 0.018 | 46 MB | 53 000 |
| Gleam | `gleam build --target erlang` | 3.77 / 0.56 | 539 MB | (`erlc` of every module) |
| tsc | `tsc --noEmit --strict --lib es2022 --module commonjs <files>` on std's emitted `.d.ts` (`botopink build --target commonJS --typescript`; 32 files, 1 686 lines) | 0.125 / — | 52 MB | 13 500 |

botopink's cold check runs at Gleam's rate; Gleam's warm run is 10× faster through its incremental
cache, and its erlang build spends its time in `erlc` as botopink's cells spend theirs in `erl`.
`tsc` exits 2 on std's `.d.ts`: `testing/snapshots.d.ts` names `SourceLocation` without declaring
it (std is outside `tsc-check.sh`'s project set).

### What 5 minutes cold needs

When the compiler changed, stage 2 is ~2m40s serial (LLVM, one thread per executable; stage 4 and
the audits fit beside it), leaving ~2m20s for stages 7–11: 16 × 140 ≈ 2240 CPU-s at perfect
packing, ~1800 at 80 %. Stages 7–11 are 3566 CPU-s today: **~1750 CPU-s must go**, and no cell may
run longer than ~2 minutes wall. Turning the busy wait off covers ~1090 of it; the rest is the
`erl` starts themselves (4 per erlang cell, 3 per beam cell) and `onze-cli`. With stage 2 warm the
budget is 16 × 300 ≈ 4800 CPU-s, and the long cells are the limit, not the total.

### How it was measured

- Per job and per cell: a stand-in `botopink` (a small C program that runs the real binary and
  appends its wall, `RUSAGE_CHILDREN` CPU and max RSS to a log), passed as `run.sh --compiler` and as
  `BOTOPINK_BIN` to `test-libs.sh`; a nested call is not logged twice.
- Busy wait off: the same runs with `ERL_FLAGS="+sbwt none +sbwtdcpu none +sbwtdio none"` in the
  environment, which every `erl` the compiler and the cells start reads.
- The VMs a cell starts: `strace -f -e trace=execve` on `botopink run --target erlang|beam`.

## Gate

- [ ] `scripts/gate.sh --cold` green and ≤ 5 min idle; a warm `scripts/gate.sh` ≤ 1 min idle
- [ ] every `AGENTS.md` of a touched directory updated in the same commit
- [ ] commits on `front/133-gate-speed`; no push, no merge — landing is the coordinator's step

## Blast radius

- `gate.sh`'s budget lines change (`budget_cold=300`, `budget_warm=60`); the pre-commit and
  pre-merge hooks run the warm gate, so a commit's check gets fast; the landing still runs `--cold`.
- CI runs every row cold (a fresh runner has no store) — CI time is not this front's target.

## Notes

- Sequenced after 131 (shares `gate.sh`, `lib-test-runner` and the `.botopinkbuild/cache/` layout).
  Step 1 (measurement only) may run beside it.

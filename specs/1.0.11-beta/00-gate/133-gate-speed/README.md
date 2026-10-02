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

Measured on 2026-10-02, `scripts/gate.sh --cold` on botopink-lang `e5ac9a21`, 16 cores **loaded**
(five worktree threads and an OTP source build running):

| Stage | Wall | CPU-s | Runs |
|---|---|---|---|
| 2 `zig build` ReleaseSafe | 2m35s | 787 | serial |
| 4 `zig build test` | 51s | 404 | serial |
| 9 `test-language` (1616 jobs) | **6m54s** | 1229 | side by side — the critical path |
| 8 `test-libs` (138 cells, 38 audits) | 4m24s | 1896 | side by side |
| 7 `test-cli` | 1m09s | 63 | side by side |
| 4b, 5, 6, 10, 11 | < 20s each | 130 | side by side |
| **total** | **9m31s** | **4503** | |

4503 CPU-s on 16 cores is 4m41s with perfect parallelism, so 5 min cold needs **less CPU**, not only
better scheduling; 1 min warm needs most cells answered from the store.

## Steps

### Step 1 — where the CPU goes

Per stage, per target and per cell kind: CPU-s and wall, and inside a cell the split between the
compiler (check, emit), the runtime spawn (`erl` start, `node` start, wasm runner) and the program
itself. Three cold runs on an idle machine (the median), and the same with a warm Zig cache.

**Acceptance:**
- [ ] the table above re-measured idle, plus: `test-language` per target (commonJS, erlang, wasm,
      beam) and per cell kind (`run/`, `test/`, `modules/`, `reject/`, audits); `test-libs` per
      library; each cell's compile / spawn / run split for a sample of 50 cells per target
- [ ] the three biggest CPU sinks named, each with its share of the total
- [ ] the compiler's own throughput: `botopink build` of rakun's whole workspace and of `libs/std`
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

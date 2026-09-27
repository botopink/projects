# Front 25 — gate-perf: two follow-ups

**Priority:** low — C-33 landed (the pool, the shards, the stages side by side, the `.beam` cache);
what is left is one measured row outside the runners' ownership and one script for the meta
repository.
**Depends on:** `00-gate` (the gate it times must be green first; the gate's own stages — the
widened `zig fmt` check, the widened `TREES` — add wall clock this front re-measures) · the
maintainer (the meta script's `AGENTS.md` sentence).
**Owns:** `repository/botopink-lang/scripts/{gate.sh,check-docs.sh,test-libs.sh,lib/pool.sh}` ·
`modules/test-shard/**` · the compiler-core test step of `build.zig` · `tests/language/run.sh` (the
runner — not the cells, not `expected-failures.txt`, and not the `all)` line at `:155`, 12's
carve-out) · `modules/lib-test-runner/**` · the `AGENTS.md` of those directories · the meta
repository's `scripts/worktree-add.sh` (new) and the meta `AGENTS.md` § Worktrees sentence
**Does not touch:** `modules/compiler-core/**` (every front's — the per-cell compile row is
reported, not fixed here), `modules/compiler-cli/src/cli/**` (26; step 4's `test_cmd.zig` cache is
landed), the language cells, `scripts/{known-red-libs,restricted-targets}.txt` (00-gate), the
libraries, `libs/std/src/async.bp` (the std track — the delay flake).

## Carried from 1.0.10

| Item | 1.0.10 spec | Heading |
|---|---|---|
| the per-cell dependency compile | `25-gate-perf/README.md` | § Step 4, last paragraph ("~4–6 s a cell on both targets: the compiler's own pipeline, a front of its own") |
| the hooks in worktrees | `25-gate-perf/README.md` | § Not a step |
| the `async` delay flake | `25-gate-perf/README.md` | § Notes, first bullet (`async.bp`, a wall-clock assertion under load; possibly closed since — the std track re-measures) |

## Steps

### Step 1 — the per-cell dependency compile, measured as a row

Every `test-libs` cell compiles the same dependency modules (`std`, the library) from source
(~4–6 s a cell at 1.0.10's measurement); the `.beam` cache removed the erlang recompile, not the
botopink compile. Re-measure at the open with `strace -f -e execve` and a timestamp per stage on
one `emilia-*` member and one rakun member; write the row here with the stage that costs it. A
content-keyed compile cache in compiler-core (the pipeline's output per module keyed by source
bytes, options and compiler version) is a front of its own in the next milestone — this front
files it with the measurement, and edits nothing under `compiler-core/**`.

**Acceptance:**
- [ ] the row: per cell, the botopink compile's wall clock and CPU, the dependency modules recompiled, on commonJS and erlang; the candidate keyed cache's expected saving computed from it
- [ ] a spec stub named in `../../deferred.md` (or the next milestone's opening list) with this row as its measurement

### Step 2 — the hooks in worktrees (the meta repository)

`git worktree add` of the meta repository shares the meta config, but each submodule of a
worktree is a separate git directory whose config has no `core.hooksPath`, so
`scripts/git-hooks/pre-commit` never runs on a compiler commit made in a worktree (measured in
1.0.10: `git config core.hooksPath` empty in `.tasks/<name>/repository/botopink-lang`). A tracked
meta script, `scripts/worktree-add.sh <name>`, runs `git worktree add .tasks/<name> -b front/<name>`,
`git submodule update --init --recursive`, then `git -C .tasks/<name>/repository/<sub> config
core.hooksPath scripts/git-hooks` for every submodule that tracks a hook; the meta `AGENTS.md`
§ Worktrees names it as the one way to open a worktree. A `post-checkout` hook cannot do it (it
would itself have to be installed).

**Acceptance:**
- [ ] the script in the meta repository; `git -C .tasks/<new>/repository/botopink-lang config core.hooksPath` answers `scripts/git-hooks` after one run; a commit in that worktree runs the hook (a planted `zig fmt` red refuses the commit)
- [ ] the meta `AGENTS.md` § Worktrees sentence; the compiler's `AGENTS.md` note "hooks do not run in worktrees" struck

### Step 3 — the gate re-timed after 00-gate

The baseline table of 1.0.10 (§ Measurements) re-run once the gate's widened stages land (`zig fmt
--check modules`, the five extra `TREES`, beam in `test-language`'s `all`), one row here, same
machine, load noted; a stage that grew more than its work explains itself or gets a step.

**Acceptance:**
- [ ] the row; no stage regressed beyond the work it added

## Gate

- [ ] `zig build test` in this front's worktree before every commit; the full suite a changed runner drives, before and after, with equivalent verdicts
- [ ] `AGENTS.md` of every directory touched in the same commit
- [ ] Commit on `fix/25-gate-perf` (compiler) and the meta branch of the same name (the script); no push, no merge

## Blast radius

None on the language: no cell, no snapshot, no expected-failure line moves.

## Notes

- Decision 67 holds: the gate keeps checking exactly what it checks; the only admissible gains are
  the same work in less wall clock (bounded parallelism, byte-identical output) or the same work
  with less CPU (not repeating a computation whose answer cannot differ).
- Decision 143 (library resolution stops at the enclosing checkout) is what lets the gate run in a
  worktree; the rsync-copy harness of 1.0.10 is for timing only.

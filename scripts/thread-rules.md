# Thread rules

Every thread the coordinator opens reads this file first (decision 484). Its prompt then states only
what is the task's own: the step, its boxes, its worktree, its model.

## Commits

- Never `--no-verify`, never `git commit -n`: a red hook is fixed, not skipped.
- Commit in your repository only, on the branch `worktree-add.sh` made. Never push; the coordinator
  lands. Never open a PR.
- **Right before the final commit, `git fetch origin` and rebase onto `origin/feat`**, so the landing
  is a fast-forward and the hook's gate already ran on the base being landed on.
- **Exception, the maintainer's (2026-10-12), until 144 B-60 lands:** a thread on a 144 step in
  botopink-lang commits with `--no-verify`, runs only the tests its change reaches (the unit tests it
  touches, the snapshots it changes, its cells on every target) plus `zig fmt --check modules` (the
  hook's first stage — fix what it names), and lands its own commit:
  `git fetch origin && git rebase origin/feat`, re-run what the rebase touched, then
  `rtk proxy git push origin HEAD:feat` — fast-forward only, never force, confirmed with
  `git ls-remote origin feat`. The libraries and every other front keep the two rules above. This
  paragraph is removed when B-60 lands.
- End each commit message with the attribution line the coordinator's prompt gives.
- Never commit `*.snap.new`, `*.snap.md.new` or `todo.md`.

## Gate and tests

- The hook runs `scripts/gate.sh --no-conformance`; conformance is `feat`'s pipeline's (470, 477).
- No `gate.sh --cold` inside a `--repo` / `--lang` worktree (meta `AGENTS.md` § Worktrees, 4b).
- Run only the tests your change reaches; a foreground `zig build test` gets at most 60 s, a longer
  run goes to the background.
- Measure no time: timings belong to the final measurement step (163 s9).
- Kill a stuck `beam.smp` by PID, never `pkill -f` with the pattern in the same command line.
- `zig build test` prints `error[reserved-word-as-name]` at `libs/std/src/path.bp:5` (`reservedProbe`): that is
  `comptime/tests/located_errors.zig` building the diagnostic on purpose, not a failure — read the exit status.

## Cells and snapshots

- A cell's expected answer is the language's, never the compiler's: never invent an expected value,
  never edit a cell or a snapshot to match the compiler.
- **A `snapshot/targets/<t>/` departure never records a compiler defect** (458): a wrong answer on a
  target is a 144 row, and the cell stays red or out until that step lands.
- A new cell is red on the parent and green after.

## Specs and documents

- A spec states what remains and what blocks it: no `.tasks/…`, `/tmp/`, task branch or worktree
  name (`scripts/scratch-refs.py` exits 0), no commit hash, no status narrative.
- An English/Portuguese pair: English holds the meaning; the Portuguese is its most direct
  translation — nothing condensed, reworded or dropped; ids, code and examples as in English.
- Code, comments, commits and files in English. A code or layout change updates the matching
  `AGENTS.md` in the same commit.
- A choice no decision or README fixes is a question in the report, never decided by the thread.

## The report

At most one line per item, details only when the coordinator asks:

```
Done:      <each box: done / not done, why>
Commits:   <repository: short subject per commit>
Outside:   <anything changed that the boxes did not ask for, or "nothing">
Questions: <each open choice, or "none">
```

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
  touches, the snapshots it changes, its cells on every target) plus `zig fmt --check modules`,
  `scripts/check-docs.sh` (the hook's cheap stage — fix what it names) and `botopink format <file>` on each `.bp` it
  adds or changes (`--no-verify` skips the hook that applies the formatter, decision 524 — format that file alone, never
  a bare `botopink format` over a directory), and lands its
  own commit:
  `git fetch origin && git rebase origin/feat`, re-run what the rebase touched, then
  `rtk proxy git push origin HEAD:feat` — fast-forward only, never force, confirmed with
  `git ls-remote origin feat`. The libraries and every other front keep the two rules above. This
  paragraph is removed when B-60 lands.
- **Exception, the maintainer's (2026-10-15):** a commit whose only change is the `decisions-taken.md`
  `scripts/decisions-split.ts` writes (decision 482) is made with `--no-verify` in every repository — the hook's gate
  tests nothing it changes. Any other file in the commit → the hook, through `scripts/gate.sh exec`.
- End each commit message with the attribution line the coordinator's prompt gives.
- Never commit `*.snap.new`, `*.snap.md.new` or `todo.md`.

## Gate and tests

- The hook runs `scripts/gate.sh --no-conformance`; conformance is `feat`'s pipeline's (470, 477).
- **Under 768 / 769 (until the maintainer says otherwise): conformance is machine 2's.** A machine-1 thread runs only the
  cells its change reaches (its new cells and the ones whose code it touches, by name), never `cell check` over the whole
  `conformance/modules`, and skips a front's Conformance step. Concretely: a library's gate is always
  `scripts/gate.sh --no-conformance` (never bare, never `--cold`); `botopink cell check` takes one cell's path at a
  time (`conformance/modules/<…>/<cell>`), never a directory of cells or a library's `conformance/`. A red met outside the change is listed under Outside for
  machine 2, never fixed. A new cell goes where 765 homes it: `conformance/modules/decisions-taken/<slug>-<N>/cases/<cell>/`
  for the decision it proves, else `conformance/modules/<prefix>/cases/<cell>/`; once B-157's moves land, `git rebase
  origin/feat` follows the renames.
- No `gate.sh --cold` inside a `--repo` / `--lang` worktree (meta `AGENTS.md` § Worktrees, 4b).
- **Every heavy command runs under the machine's pool** (the pool is the machine's, so any checkout of the
  meta repository serves — the main one for a `--repo` / `--lang` task):
  `scripts/gate.sh exec <step> -- <command>…` for each `zig build`,
  `zig build test`, `botopink cell check`, test binary run, and each library `git commit` (its hook runs
  a gate). It waits for a free job and holds the lock only while the command executes (the maintainer,
  2026-10-12). Never a gate or a build outside it.
  The command runs in the meta repository's root (`gate.sh` changes to it), not in your directory: a
  command that must run inside a worktree (a library's own `scripts/gate.sh`, its `git commit`) is given
  as a script that changes to it first, or with an absolute path that does not depend on the directory.
- Run only the tests your change reaches; a foreground `zig build test` gets at most 60 s, a longer
  run goes to the background.
- Measure no time: timings belong to the final measurement step (163 s9).
- Kill a stuck `beam.smp` by PID, never `pkill -f` with the pattern in the same command line.
- Wait on a PID (`wait`, `kill -0 <pid>`) or a file, never on `pgrep -f <pattern>`: the waiting shell holds the pattern
  in its own command line, so it matches itself and never ends. Before the report, kill every loop and background
  job you started — none outlives the thread.
- **Every wait has a deadline and an owner.** A polling loop runs under `timeout` (`timeout 2h bash -c 'until …; do
  sleep 30; done'`), never bare; it waits only on a PID or a file of a command this thread started, and the file
  is one that command is sure to write at its end (an `exit` line the script echoes), never another thread's
  output or a task-output file of the harness. One wait per command: a wait that timed out is killed before a new
  one is started, never left beside it.
- **Your scratch files are your own.** The session's scratch directory is shared by every thread: write yours under
  a subdirectory named after your task (`<scratch>/<task>/build.log`, `cells.txt`, …), never a bare common name
  (`cells.txt`, `t.log`) another thread may write or wait on.
- **The scratch directory is small** (a tmpfs under a user quota; a full one fails every command of every thread):
  logs and short results only. A binary, a copied compiler, a scratch project or a build output goes under your
  worktree (`.tasks/<name>/`), never under the scratch directory; delete your scratch subdirectory before the report.
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
  name (`scripts/scratch-refs.ts` exits 0), no commit hash, no status narrative.
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

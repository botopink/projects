# AGENTS.md

Guidance for AI agents working in the botopink meta repository.

This repository holds no source code of its own. It pins the compiler and the
libraries as submodules under `repository/` and keeps the planning documents
(`specs/`, `todo.md`). Code guidance lives next to the code: start at
[`repository/botopink-lang/AGENTS.md`](repository/botopink-lang/AGENTS.md) and read the
closest `AGENTS.md` in each directory you touch.

## Layout

| Path | What |
|---|---|
| `repository/botopink-lang/` | Compiler (`modules/compiler-core`), CLI, language server, lib-test-runner, `libs/std` |
| `repository/{emilia,erika,jhonstart,onze,rakun}/` | Libraries written in botopink |
| `repository/vscode-extension/` | VS Code extension |
| `specs/1.0.11-beta/` | Current milestone: `00-gate` first (a 100 % green gate in every repository, zero tolerated reds, cut one front per repository / compiler area, plus a gate-performance front), then `01-compiler` · `02-std-and-packaging` · `03-bundled-libs` (what the frameworks copy from each other, extracted under decisions 115–117; plus `125-validation-zod`, Zod's feature set in `validation`) · `04-rakun` · `05-jhonstart` · `06-emilia` · `07-onze` · `08-bpp` (Astro's feature set on the four libraries; `116` alone edits the compiler, for the generic `.bpp` file kind). A reference-driven front carries a `surface.md` — every row of its reference and where it lands — and an `examples/` directory with the code its steps aim at. Index in `overview.md`, ownership and the parallel groups in `fronts.md`, the living checklist in `status.md`, the 1.0.10 → 1.0.11 map in `carried.md` and each track's `carried.md`; new fronts start from `specs/__template.md`. A carried front keeps its global number; decisions continue at 144 |
| `specs/1.0.10-beta/` | Closed ecosystem milestone (`closure.md`, measured at the close); frozen — every open item moved to `specs/1.0.11-beta/` with the deep dives it still needs copied beside it |
| `specs/1.0.5-beta/` | Closed compiler milestone (`closure.md`); its open work went to 1.0.10-beta's `00-compiler-carry-over/` and now lives in `specs/1.0.11-beta/01-compiler/` |
| `specs/1.0.0-beta/` … `1.0.4-beta/` | Closed. 1.0.6–1.0.9-beta were absorbed into 1.0.10-beta and deleted (decision 68); the mapping in `specs/1.0.10-beta/unification.md` |
| `.github/workflows/` | The meta repository's CI: `hook-integrity.yml`, one job on push/PR to `feat`/`main` — see § CI |
| `scripts/` | The meta repository's own tools: `worktree-add.sh <name> [<base>]` — opens a task worktree (§ Worktrees); `language-gap-markers.sh` — every `// LANGUAGE GAP` marker in a tracked `.bp` file (the repositories under `repository/`, and this one outside the closed milestones' spec trees) against the `## Marker index` of the milestone's `language-gaps.md`; CI check 5 |
| `todo.md` | Live plan of the task in the current checkout/worktree — git-ignored, never committed |
| `architecture.md` | Comptime evaluation pipeline, current state |
| `CHANGELOG.md` | Release log |

## CI

`.github/workflows/hook-integrity.yml` is the one job of this repository (1.0.11-beta
00-gate, front 114), every check hard, plain bash over a checkout with submodules:

1. every submodule pointer is an ancestor of (or equal to) its remote `feat` — a bump never
   points at an unpushed commit (`git -C repository/<sub> merge-base --is-ancestor HEAD FETCH_HEAD`);
2. every path in § Layout above exists on disk (the first backticked path of each row, `{a,b}`
   expanded; the git-ignored `todo.md` row is excluded);
3. no `*.snap.new`, `*.snap.md.new` or `todo.md` is tracked in this repository or any submodule;
4. the five libraries' pre-commit guards are one text — `scripts/git-hooks/pre-commit` and
   `scripts/git-hooks/lib/runner-standalone.sh` byte-identical across emilia, erika, jhonstart,
   onze and rakun, each `.gitignore` naming `*.snap.new` and `*.snap.md.new`, no
   `scripts/known-broken-examples.txt`, each `AGENTS.md` naming `git config core.hooksPath
   scripts/git-hooks`;
5. `scripts/language-gap-markers.sh` exits 0 — every `// LANGUAGE GAP` marker has a row in the
   milestone's `language-gaps.md`: each file that holds one is a row of its `## Marker index` with
   the file's marker count and the gap rows it names, and a missing row, a count that differs, a
   named gap row that is gone and a row for a file with no marker each fail the check.

A red check names the repository and the front that owns the fix; nothing here is soft.

## Worktrees

Parallel tasks run in git worktrees of this repository under `.tasks/<name>` (next to
the main checkout), one branch per task (`git worktree list` shows the active ones).
A worktree is opened one way:

```sh
scripts/worktree-add.sh <name> [<base>]   # base defaults to feat
```

It adds `.tasks/<name>` on a new branch `front/<name>` (under the main checkout,
from whichever worktree it runs), runs `git submodule update --init --recursive`
there, sets `core.hooksPath scripts/git-hooks` in every submodule that tracks
`scripts/git-hooks/pre-commit`, and puts `repository/botopink-lang` on a branch
`front/<name>`. The hooks step is the reason the script exists: a submodule of a
worktree is a repository of its own, so nothing configured in the main checkout's
submodules reaches it, and without the step a commit there runs no gate at all.

Inside a worktree, edit files under that worktree's path only — never the main
checkout. Work in `repository/botopink-lang` on the branch the script created (a
library on a branch of the same name, when the task commits there). Commit in the
submodule first, then commit the submodule bump in the meta repo.

## Build and test

All Zig commands run from `repository/botopink-lang/`:

```sh
zig build          # botopink + botopink-lsp
zig build test     # compiler-core + language-server (~17s)
zig build test-libs / test-backends / test-vscode / test-bpmp
```

- Comptime evaluation spawns a persistent `erl`; `erl`/`erlc` must be on `PATH`.
  CommonJS snapshot tests execute with `node`.
- `zig build test -- --test-filter` is not forwarded in Zig 0.16. To run a subset,
  run the test binary directly (`.zig-cache/o/<hash>/test`; the hash appears after
  `failed command:` in the log).
- `zig build test --test-timeout 20s` names the test that hangs; "test runner failed to
  respond" means nothing is running (e.g. a child process holding the runner's stdio).
- Quick iteration without the suite: `zig-out/bin/botopink build --target erlang --out out`
  in a scratch project.
- Do not `pkill -f <pattern>` in the same command line that contains the pattern — it kills
  the shell itself; kill `beam.smp` by PID.
- Snapshots live in `modules/<package>/snapshots/`; a mismatch writes `<slug>.snap.md.new`
  next to the snapshot. Do not commit `.snap.md.new` files.

## Conventions

- Code, comments, commit messages and compiler docs are in English. Planning documents
  (`todo.md`, `specs/1.0.0-beta/01-test-green/`, `02-type-system.md`, `architecture.md`)
  are in Portuguese — keep each file in its current language.
- Any code or layout change updates the matching `AGENTS.md` in the same commit.
- Specs describe current state and remaining work; do not keep status narratives,
  commit hashes or superseded approaches in them.

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
| `specs/1.0.4-beta/` | Current milestone specs — the open work of 1.0.2-beta and 1.0.3-beta merged; index in `overview.md`; new specs start from `specs/__template.md` |
| `specs/1.0.1-beta/` | Previous milestone (delivered; open items carried into 1.0.2-beta, now `1.0.4-beta`) |
| `specs/1.0.0-beta/` | Closed |
| `todo.md` | Live plan of the task in the current checkout/worktree — git-ignored, never committed |
| `architecture.md` | Comptime evaluation pipeline, current state |
| `CHANGELOG.md` | Release log |

## Worktrees

Parallel tasks run in git worktrees of this repository under `.tasks/<name>` (next to
the main checkout), one branch per task (`git worktree list` shows the active ones).

Inside a worktree, edit files under that worktree's path only — never the main
checkout. Work in `repository/botopink-lang` on a branch with the same name as the
meta branch (check out or create it if the submodule is on a detached HEAD). Commit in
the submodule first, then commit the submodule bump in the meta repo.
Run `git submodule update --init --recursive` if a sibling submodule is empty.

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

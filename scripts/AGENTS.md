# scripts

> Path: `scripts/` (workspace-global, lives **above** `repository/`)
> Workspace overview: [`../repository/AGENTS.md`](../repository/AGENTS.md)

Workspace maintenance scripts (bash). Born in the `docs-refactor` spec
(`tasks/v0.beta.2/specs/docs-refactor.md`, F4). They detect both layouts —
the workspace shape (`repository/botopink-lang/`) and a legacy flat tree —
so the same script works in either.

## Tree

```text
scripts/
├── AGENTS.md          ← you are here
├── doc-health.sh      ← doc invariants: orphan source dirs, broken md links, volatile counters
├── install-hooks.sh   ← wire scripts/git-hooks/pre-commit into meta + every submodule
├── install-tooling.sh ← build + install/update botopink-lsp and the VS Code extension
├── status.sh          ← print a set's status.md rollup table (usage: status.sh v0.beta.2)
├── test-vscode.sh     ← lazy npm ci + npm test for the VS Code extension
└── git-hooks/         ← tracked source of truth for the workspace pre-commit gate
    ├── pre-commit                       ← wrapper, symlinked into every project
    └── lib/
        ├── test-runner.sh               ← detect project, dispatch to runner
        ├── lib/
        │   ├── colors.sh                ← pass/fail/warn helpers
        │   └── botopink-bin.sh          ← locate botopink binary
        └── runners/
            ├── meta.sh                  ← meta gate + recursive submodule scan
            ├── botopink-lang.sh         ← zig build + zig build test + libs/* loop
            ├── bp-lib.sh                ← botopink test (.bp lib)
            └── vscode-extension.sh      ← npm test (one-shot npm ci bootstrap)
```

## Conventions

- `set -euo pipefail`; run from anywhere (each script `cd`s to the repo root).
- Read-only by default — scripts print to stdout; the caller redirects into files.
  (`install-tooling.sh` and `install-hooks.sh` are the exceptions: the first
  writes a binary to a PATH dir + installs the VS Code extension, the second
  creates symlinks under each project's `.git/hooks/`. Both are idempotent.)
- Exit 0 = healthy, 1 = violations (one line per violation on stderr).

## `test-libs.sh` lives under botopink-lang

The `test-libs.sh` wrapper that `zig build test-libs` invokes lives at
[`repository/botopink-lang/scripts/test-libs.sh`](../repository/botopink-lang/scripts/test-libs.sh)
— not here. The in-tree path is what makes `zig build test-libs` work
in both the meta workspace layout (`<meta>/repository/botopink-lang/`)
AND the standalone lib-checkout CI layout (`<lib>/botopink-lang/`),
since the build.zig SystemCommand resolves the relative
`scripts/test-libs.sh` at the build root in either case. The script's
own `cd "$(git rev-parse --show-toplevel)"` + `if [ -f repository/
botopink-lang/build.zig ]; then ...` chain detects which layout it's
running under.

Run it from the meta workspace via `zig build test-libs` (which
shells out internally) or directly:

```sh
bash repository/botopink-lang/scripts/test-libs.sh -- --target erlang --lib rakun
```

## Hook layout

`scripts/git-hooks/pre-commit` is the workspace's tracked pre-commit
gate — the **same file** is symlinked into every project's
`.git/hooks/pre-commit` (or `.git/modules/<path>/hooks/pre-commit` for
submodules). It sources `lib/test-runner.sh`, which auto-detects the
project type at `$(git rev-parse --show-toplevel)` and dispatches to
the matching runner:

| Project type     | Detected by                              | Runner                                |
|------------------|------------------------------------------|---------------------------------------|
| meta             | `.gitmodules` at the root                | `lib/runners/meta.sh` (+ submodule scan) |
| botopink-lang    | `build.zig` + `modules/`                 | `lib/runners/botopink-lang.sh`        |
| vscode-extension | `package.json` with `"vscode"` key       | `lib/runners/vscode-extension.sh`     |
| `.bp` lib        | `botopink.json` only                     | `lib/runners/bp-lib.sh`               |

`scripts/install-hooks.sh` is the bootstrap. It walks `.gitmodules`,
resolves each submodule's git dir (handles linkfile `.git` files via
`git rev-parse --git-dir`), and symlinks the `pre-commit` source into
every project at once. Idempotent — re-runs are no-ops. Backs up any
pre-existing non-symlink hook to `pre-commit.bak.<ts>` so a
contributor's local custom hook is preserved. `--check` exits non-zero
on drift; `--meta-only` skips submodules for partial clones.

The meta runner additionally **scans staged submodule pointer bumps**
(`git diff --cached` ∩ submodule paths) and recursively runs the
bumped submodule's gate against the staged SHA, in a throwaway
worktree under `.tasks/_hook-<sub>-<sha7>/`. On success the worktree
is removed; on failure it is preserved + the path printed so the user
can inspect. A 10-minute budget per submodule protects against
runaway suites — the failure message points at `split your commit —
don't bump multiple submodules at once`.

A `.github/workflows/hook-integrity.yml` job replays the tracked hook
against every PR head (7-matrix, one axis per project) to catch
`--no-verify` bypasses + symlink drift.

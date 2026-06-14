# TODO — recursive-test-gate (v0.beta.19)

> Branch: `task/recursive-test-gate` · Worktree: `.tasks/recursive-test-gate/`
> Spec: [`tasks/v0.beta.19/specs/recursive-test-gate.md`](../../tasks/v0.beta.19/specs/recursive-test-gate.md)
> Set: [`tasks/v0.beta.19/README.md`](../../tasks/v0.beta.19/README.md)
> Status rollup: [`tasks/v0.beta.19/status.md`](../../tasks/v0.beta.19/status.md)

Local pre-commit gate, version-controlled and recursive — every
project (meta + 6 submodules) gets a tracked `scripts/git-hooks/pre-commit`
that runs its own gate; the meta hook additionally validates staged
submodule pointer bumps by running the submodule's gate at the staged
SHA in a throwaway worktree. One bootstrap script
(`scripts/install-hooks.sh`) wires all 7 symlinks idempotently; a
`hook-integrity.yml` CI smoke catches `--no-verify` bypasses.

## F0 — extract the current meta hook to tracked source

- [x] Copy `.git/hooks/pre-commit` (existing meta hook) verbatim to
      `scripts/git-hooks/pre-commit`. No behaviour change yet.
- [x] Move the body of the test loop into
      `scripts/git-hooks/lib/runners/meta.sh` as `metaGate()`.
- [x] Replace `.git/hooks/pre-commit` with a symlink to
      `../../scripts/git-hooks/pre-commit` (the tracked source).
- [x] `git commit --allow-empty -m test` once to confirm the new
      symlinked hook behaves identically.

## F1 — extract shared helpers

- [x] `scripts/git-hooks/lib/lib/colors.sh` — pass/fail/warn shell
      helpers (lifted from the current hook's preamble).
- [x] `scripts/git-hooks/lib/lib/botopink-bin.sh` — `locateBotopink`
      function: env > nearest ancestor
      `repository/botopink-lang/zig-out/bin/botopink` > `$PATH` >
      skip+warn.
- [x] `scripts/git-hooks/lib/test-runner.sh` — `runProjectGate(root)`:
      detect project type (`.gitmodules` → meta; `build.zig` +
      `modules/` → botopink-lang; `botopink.json` only → bp-lib;
      `package.json` with `botopink.lsp` markers → vscode-extension)
      and dispatch.

## F2 — write per-project gates

- [x] `runners/botopink-lang.sh` — current "Compilation" + "Tests" +
      "libs/* botopink test" loop, but inside `repository/botopink-lang/`.
- [x] `runners/bp-lib.sh` — `botopink test` in the lib's cwd; locate
      the binary via `botopink-bin.sh`; skip + warn if missing.
- [x] `runners/vscode-extension.sh` — `npm test`; bootstrap
      `npm install` once if `node_modules/` missing; reuse
      `scripts/test-vscode.sh` logic where possible.
- [x] `runners/meta.sh` — current four-step gate plus the new "scan
      staged submodule bumps" routine (see F3).

## F3 — submodule pointer scan in meta gate

- [x] In `runners/meta.sh` after the existing steps: `git diff --cached
      --name-only` ∩ `.gitmodules` paths.
- [x] For each hit: resolve staged SHA from `git diff --cached <path>`;
      `git -C repository/<sub> worktree add
      .tasks/_hook-<sub>-<sha7> <sha>`; cd in; `runProjectGate $(pwd)`.
- [x] On success: `git -C repository/<sub> worktree remove
      .tasks/_hook-<sub>-<sha7>`. On failure: leave the worktree, print
      the inspect path, fail the meta commit.
- [x] Race-safety: if the worktree already exists at the path (previous
      failed commit), reuse it; never double `worktree add`.
- [x] Time budget: 10 minutes per submodule; longer fails with
      "split your commit — don't bump multiple submodules at once".

## F4 — per-submodule tracked pre-commit

- [x] In each of the 6 submodule repos
      (botopink-lang/erika/jhonstart/onze/rakun/vscode-extension): add
      `scripts/git-hooks/pre-commit` (thin shim) +
      `scripts/git-hooks/lib/runner-standalone.sh` (per-project gate
      for the standalone-clone path).
- [x] Update each submodule's `AGENTS.md` "CI" section with a new
      "Local gate" subsection pointing at the tracked hook +
      `scripts/install-hooks.sh`.

## F5 — install-hooks.sh

- [x] `scripts/install-hooks.sh`: walks `.gitmodules`, resolves each
      submodule's git dir (handles linkfile `.git` files), symlinks
      each `pre-commit`. Backs up existing non-symlink files to
      `pre-commit.bak.<ts>`.
- [x] `--check` flag: print ✓/⚠/✗ per project, exit non-zero on any
      missing or drifted.
- [x] `--meta-only` flag: skip submodules (for partial clones).
- [x] Idempotent — re-run is a no-op.

## F6 — CI guard

- [x] `.github/workflows/hook-integrity.yml`: 1 job, 7-matrix (one per
      project). Per axis: `install-hooks.sh`, then
      `install-hooks.sh --check`, then replay the tracked hook against
      HEAD (the bypass-catcher).
- [x] Triggers: `push` to any branch + `pull_request`.

## F7 — docs

- [x] `scripts/AGENTS.md` — new "Hook layout" section pointing at
      `git-hooks/` tree + `install-hooks.sh` + the per-project dispatch
      table from this spec.
- [x] `repository/AGENTS.md` — one-line row in the workspace overview
      noting every submodule has a tracked pre-commit hook and
      `install-hooks.sh` wires all 7 at once.
- [x] `repository/botopink-lang/AGENTS.md` — replace its existing
      "pre-commit" paragraph with a pointer to the tracked source +
      install script.
- [x] Each lib's `AGENTS.md` — "Local gate" subsection per F4.
- [ ] This set's `README.md` + `status.md` — flip the
      recursive-test-gate row to `done` once merged into `feat`.

## Acceptance — test scenarios (from spec)

```
hook ---- install-hooks.sh on a fresh clone: 7 symlinks created, --check green
hook ---- install-hooks.sh idempotent: re-run is a no-op, still --check green
hook ---- install-hooks.sh refuses to silently overwrite a local custom hook
hook ---- install-hooks.sh --meta-only: only the meta hook is installed
hook ---- a contributor with a pre-existing non-symlink hook gets a .bak file + warning
meta ---- commit at meta with no submodule bump: only meta gate runs
meta ---- commit at meta bumping rakun pointer: rakun's gate runs in throwaway worktree
meta ---- commit at meta bumping 2 submodules: both gates run; if any fails, commit fails
meta ---- bumped submodule's gate fails: throwaway worktree is preserved + path printed
meta ---- bumped submodule's gate passes: throwaway worktree is cleaned up
meta ---- two parallel meta commits bumping different submodules: each gets its own worktree
sub  ---- commit inside repository/erika: erika gate runs (botopink test)
sub  ---- commit inside repository/erika with botopink binary missing: yellow warn, no commit-block
sub  ---- commit inside repository/vscode-extension: npm test runs; fresh clone bootstraps node_modules
sub  ---- commit inside repository/botopink-lang: zig build + zig build test + libs/* loop runs
sub  ---- commit inside repository/botopink-lang touching a libs/std test that fails: commit blocked
sub  ---- commit inside repository/jhonstart with a .bp test failure: commit blocked, error names the test
ci   ---- hook-integrity.yml on a PR: all 7 axes green; install + --check + replay
ci   ---- contributor pushes with --no-verify and a red test: hook-integrity catches it
ci   ---- contributor edits .git/hooks/pre-commit locally (drift): hook-integrity --check red
edge ---- meta hook timeout: a submodule whose gate takes >10min fails with "split your commit"
edge ---- staged submodule SHA does not exist in the submodule (push not done yet): clear error
edge ---- submodule pointer staged for *removal* (deleted submodule): scan skips it cleanly
edge ---- meta worktree under .tasks/_integrate-<slug>: hook still finds the tracked source
```

## Exit gate (per `tasks/AGENTS.md` workflow §5)

- [x] All F0–F7 boxes ticked.
- [x] All acceptance scenarios above pass on a local rerun.
- [x] `scripts/install-hooks.sh --check` green on a fresh clone.
- [x] `hook-integrity.yml` green on the PR.
- [x] Touched docs synced (`scripts/AGENTS.md`, `repository/AGENTS.md`,
      `repository/botopink-lang/AGENTS.md`, each lib's `AGENTS.md`).
- [x] Merged into `feat` over SSH via a throwaway
      `.tasks/_integrate-recursive-test-gate/` worktree (per workflow);
      `status.md` flipped to `done`.
- [x] Worktree + branch cleaned up after the merge.

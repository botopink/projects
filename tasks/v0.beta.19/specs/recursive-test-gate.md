# recursive-test-gate — pre-commit must prove every project (meta + submodules) is green

**Slug**: recursive-test-gate
**Depends on**: nothing (independent of Frentes A/B/C; consumes whatever
  `zig build test` / `botopink test` / `npm test` each project ships today)
**Files**:
  - **meta hook**: `scripts/install-hooks.sh` (new) ·
    `scripts/git-hooks/pre-commit` (new, version-controlled source of truth) ·
    `scripts/git-hooks/lib/test-runner.sh` (new, shared per-project dispatcher)
  - **per-submodule hooks**: `repository/botopink-lang/scripts/git-hooks/pre-commit` ·
    `repository/erika/scripts/git-hooks/pre-commit` ·
    `repository/jhonstart/scripts/git-hooks/pre-commit` ·
    `repository/onze/scripts/git-hooks/pre-commit` ·
    `repository/rakun/scripts/git-hooks/pre-commit` ·
    `repository/vscode-extension/scripts/git-hooks/pre-commit`
  - **wiring**: `scripts/install-hooks.sh` symlinks each project's
    `.git/hooks/pre-commit` → its tracked `scripts/git-hooks/pre-commit`
    (meta uses `.git/hooks`; submodules use `.git/modules/<path>/hooks` —
    the script resolves both)
  - **CI guard**: `.github/workflows/hook-integrity.yml` (new, one-job
    smoke that asserts the tracked hook ran against the head SHA on every PR)
**Touches docs**: `scripts/AGENTS.md` (new "Hook layout" section) ·
  `repository/AGENTS.md` (workspace overview — submodule pre-commit row) ·
  `repository/botopink-lang/AGENTS.md` (replace its existing "pre-commit"
  paragraph) · each sibling lib's `AGENTS.md` (CI section gains a
  "Local gate" subsection) · this set's `README.md` + `status.md`
**Status**: pending

## Problem

The repo today has **one** pre-commit hook, sitting unversioned at
`.git/hooks/pre-commit` in the meta repo. Two consequences:

1. **Submodules are unguarded.** A `cd repository/erika && git commit` —
   the way Eric paralleliza work across `.tasks/<slug>/` worktrees and the
   way each lib's own author would commit — skips every test. Whether
   `erika`/`jhonstart`/`onze`/`rakun`/`vscode-extension`/`botopink-lang`
   builds and passes its own tests at HEAD is **untested locally**; the
   feedback loop is "push, wait for the lib's `test.yml`, get a red CI".
   That gap is what `tasks/v0.beta.18/specs/lib-test-workflows.md`
   acknowledged ("per-lib CI catches regressions per push") but did not
   close — CI is the *backup*, the local hook is the *primary* gate.
2. **The meta hook is not version-controlled.** It lives in
   `.git/hooks/` only. A fresh clone (CI runner, new contributor, the
   throwaway `.tasks/_integrate-<slug>` worktrees that v0.beta.7's
   consolidation memo documents) has **no hook at all**, so the very
   merge step that integrates a worktree into `feat` runs without the
   gate. The hook also doesn't recurse: when a submodule pointer is
   staged for bump, the hook never runs that submodule's tests at the
   staged SHA — it just trusts the pointer.

Net effect: a commit can land that

- breaks a submodule's tests, OR
- bumps a submodule pointer to a SHA whose tests are red, OR
- bypasses the hook entirely because someone cloned fresh and never
  re-installed the hook.

The closing wave for v0.beta.19 is the right moment to fix this once.
Every other spec in this set assumes "all tests pass before commit" as
an invariant — this spec **makes that invariant enforceable**.

## Goal

A single tracked hook per project, installed by a single bootstrap
script, that on `git commit`:

- runs the project's *own* test gate (Zig build+test for botopink-lang,
  `botopink test` for the `.bp` libs, `npm test` for vscode-extension),
- if the commit is in the **meta repo** and any submodule pointer is
  staged for bump, additionally checks out the staged SHA in a
  throwaway worktree and runs *that submodule's* gate against it,
- refuses to run if `.git/hooks/pre-commit` is not the symlink to the
  tracked source (catches drift / accidental local edits / fresh clones
  that forgot the bootstrap),
- is itself smoked by a CI job, so a PR cannot land if a contributor
  bypassed the hook (`--no-verify`) and the result is red against the
  tracked gate.

After this spec lands:

- every commit on every project runs that project's tests **first**,
- every submodule pointer bump in the meta repo runs the **submodule's**
  tests at the staged SHA **before** the meta commit succeeds,
- a contributor who clones fresh runs one command (`scripts/install-hooks.sh`)
  to wire all 7 hooks at once,
- a contributor who bypasses with `--no-verify` is caught by CI.

## What "the project's own gate" means — per project

The hook does **not** invent a gate per project. It dispatches to the
project's existing test contract, captured in one table:

| Project | Working dir | Gate (already exists today) |
|---|---|---|
| meta (`botopink-lang/`) | repo root | `zig build` + `zig build test` in `repository/botopink-lang/`, then `botopink test` in every `repository/botopink-lang/libs/*` (the present hook), then the **per-submodule gate of every submodule whose pointer is staged** (this spec adds it) |
| `repository/botopink-lang` | `repository/botopink-lang/` | `zig build` + `zig build test` + `zig build test-libs` (skip if `node`/`escript` missing — `scripts/test-libs.sh` already pre-flights this) + `botopink test` in every `libs/*` |
| `repository/erika` | `repository/erika/` | `botopink test` (binary located via `BOTOPINK_BIN` env or the closest ancestor `repository/botopink-lang/zig-out/bin/botopink`); skip + warn if the binary is missing |
| `repository/jhonstart` | `repository/jhonstart/` | same as erika |
| `repository/onze` | `repository/onze/` | same as erika |
| `repository/rakun` | `repository/rakun/` | same as erika |
| `repository/vscode-extension` | `repository/vscode-extension/` | `npm test` if `node_modules/` present; otherwise `npm install && npm test` once and warn (the `test-vscode.sh` script's bootstrap path) |

"Skip if X missing" is a **warning, not a pass** — the hook prints a
yellow line, exits with code 0 *for that target*, and the dispatcher
records it in the run log. A target with no possible runtime cannot
gate; that's recorded as the project's known limitation, not absorbed
silently.

## What "submodule pointer staged for bump" means

In meta-repo `git diff --cached --name-only`, any path that is itself a
registered submodule (per `.gitmodules`) and is staged with a different
SHA than `HEAD:<path>` is "staged for bump". For each such submodule:

```text
1. resolve the staged SHA (git diff --cached <path> ↦ "new ID")
2. git worktree add .tasks/_hook-<slug>-<sha7> <staged-sha> in the submodule
3. cd into that worktree and run the submodule's own gate (per the table)
4. on success: git worktree remove .tasks/_hook-<slug>-<sha7>
5. on failure: leave the worktree (so the user can inspect) + fail the meta commit
```

The throwaway worktree path mirrors v0.beta.7's
`.tasks/_integrate-<slug>` pattern and the per-task convention in
`tasks/AGENTS.md`. The worktree is on the **submodule's** `.git`, not
the meta's — so it doesn't pollute the meta's `.tasks/` listing for
active worktrees.

## Examples

### meta commit, no submodule bump
```bash
$ git add tasks/v0.beta.19/specs/recursive-test-gate.md
$ git commit -m "spec: recursive-test-gate"
── pre-commit ──
✓ No conflict markers
✓ zig fmt OK (0 files)
  Building (repository/botopink-lang)... ✓
  Testing (zig build test)... ✓
  Testing libs/std (.bp)... ✓
  Testing libs/erika (.bp)... ✓
  (submodule pointer scan: no submodule bumps staged — skipping recursive gate)
── pre-commit passed ──
```

### meta commit that bumps `repository/rakun`
```bash
$ ( cd repository/rakun && git checkout feat && git pull )
$ git add repository/rakun
$ git commit -m "chore(submodules): bump rakun"
── pre-commit ──
✓ No conflict markers
✓ zig fmt OK (0 files)
  Building (repository/botopink-lang)... ✓
  Testing (zig build test)... ✓
  (submodule pointer scan: 1 bump staged → rakun e1478d9..a3f29c8)
  Testing rakun @ a3f29c8 in throwaway worktree...
    Building (rakun-side gate: botopink test)...
    ✓ rakun: 13 tests green
  Cleaning up worktree .tasks/_hook-rakun-a3f29c8
── pre-commit passed ──
```

### submodule commit (cd into rakun, edit, commit)
```bash
$ cd repository/rakun
$ vim libs/rakun/src/Server.bp
$ git add libs/rakun/src/Server.bp
$ git commit -m "feat: 404 fallback"
── pre-commit (rakun) ──
✓ No conflict markers
  Testing rakun (botopink test)... ✓ 13 tests green
── pre-commit passed ──
```

### bypassed hook caught by CI
```bash
$ git commit --no-verify -m "wip"
$ git push
# CI fires: .github/workflows/hook-integrity.yml runs the tracked
# pre-commit against the HEAD SHA in a fresh clone. Fails red:
# "scripts/git-hooks/pre-commit refused to pass — see logs".
```

### fresh clone — bootstrap
```bash
$ git clone --recurse-submodules git@github.com:botopink/botopink-lang.git
$ cd botopink-lang
$ scripts/install-hooks.sh
✓ meta: .git/hooks/pre-commit → ../../scripts/git-hooks/pre-commit
✓ repository/botopink-lang: .git/modules/repository/botopink-lang/hooks/pre-commit → ../../../../../repository/botopink-lang/scripts/git-hooks/pre-commit
✓ repository/erika: (similar)
✓ repository/jhonstart: (similar)
✓ repository/onze: (similar)
✓ repository/rakun: (similar)
✓ repository/vscode-extension: (similar)
── all 7 hooks installed ──
```

## Target shape — the tracked hook

`scripts/git-hooks/pre-commit` is **the same file** at every project, in
the sense that:

- it always runs the four common checks (conflict markers, `zig fmt`
  for staged `.zig` files, line-ending sanity, large-file warning),
- then it sources `scripts/git-hooks/lib/test-runner.sh` and calls
  `runProjectGate "$(git rev-parse --show-toplevel)"`,
- which detects the project (presence of `build.zig` → botopink-lang
  layout; `botopink.json` → `.bp` lib; `package.json` with
  `vscode:prepublish` → vscode-extension; `.gitmodules` → meta) and
  dispatches to the right per-project routine.

Layout:

```text
scripts/git-hooks/
├── pre-commit                          # the wrapper — every project symlinks to this
└── lib/
    ├── test-runner.sh                  # detect + dispatch
    ├── runners/
    │   ├── meta.sh                     # meta repo's gate (current hook + submodule bump scan)
    │   ├── botopink-lang.sh            # zig build + zig build test + zig build test-libs + libs/*
    │   ├── bp-lib.sh                   # botopink test (erika / jhonstart / onze / rakun)
    │   └── vscode-extension.sh         # npm test
    └── lib/
        ├── colors.sh                   # pass/fail/warn helpers (shared)
        └── botopink-bin.sh             # locate the botopink binary (env > nearest ancestor > $PATH > skip+warn)
```

Inside each per-submodule project, the file at
`repository/<sub>/scripts/git-hooks/pre-commit` is **a thin shim**:

```bash
#!/usr/bin/env bash
set -euo pipefail
# Tracked submodule pre-commit shim. Sources the meta repo's shared
# runner if reachable; otherwise falls back to the per-project gate
# inline (CI's hook-integrity job runs against a fresh clone where
# the meta is the ancestor).
META_ROOT=$(git rev-parse --show-superproject-working-tree 2>/dev/null || true)
if [ -n "$META_ROOT" ] && [ -f "$META_ROOT/scripts/git-hooks/lib/test-runner.sh" ]; then
    . "$META_ROOT/scripts/git-hooks/lib/test-runner.sh"
    runProjectGate "$(git rev-parse --show-toplevel)"
else
    # Standalone clone (lib's own CI, bpmp checkout, etc.) — run the
    # per-project gate without the shared runner.
    . "$(git rev-parse --show-toplevel)/scripts/git-hooks/lib/runner-standalone.sh"
    runStandaloneGate
fi
```

The shim works in **both** layouts: nested under the meta workspace
(uses the shared runner), and as a standalone clone (its own
`scripts/git-hooks/lib/runner-standalone.sh` covers the gate).

## install-hooks.sh — what it does

```bash
scripts/install-hooks.sh [--check] [--meta-only]
```

- Walks `.gitmodules` to enumerate the 6 submodules; computes each
  one's git dir via `git -C <path> rev-parse --git-dir` (handles both
  in-place `.git` and the meta's `.git/modules/<path>/` linkfile).
- For each: replace `<gitdir>/hooks/pre-commit` with a relative symlink
  to the project's tracked `scripts/git-hooks/pre-commit`. Backs up any
  pre-existing **non-symlink** file to `pre-commit.bak.<ts>` and prints
  a warning (so a local custom hook is preserved, not deleted).
- Also installs the meta repo's own hook the same way.
- `--check` mode prints the install state of all 7 hooks (✓ tracked,
  ⚠ custom local, ✗ missing) and exits non-zero if any is missing or
  drifted.

The script is idempotent. Re-running on an already-installed tree is a
no-op (every symlink already points where it should).

## hook-integrity.yml — CI smoke

One job, one matrix axis (the 7 projects). For each:

```yaml
- uses: actions/checkout@v4
  with: { submodules: recursive }
- name: Install hooks
  run: scripts/install-hooks.sh
- name: Verify hook integrity
  run: scripts/install-hooks.sh --check
- name: Replay pre-commit against HEAD
  run: |
    # stage the HEAD tree as if it were a fresh commit, then dry-run
    # the tracked hook against it. Refuses if the hook fails.
    git reset --soft HEAD~1 || true
    git add -A
    .git/hooks/pre-commit
```

The "replay against HEAD" step catches `--no-verify` bypasses: if the
landed commit fails the tracked hook, the PR is red.

## Steps

### F0 — extract the current meta hook to tracked source
- [ ] Copy `.git/hooks/pre-commit` (existing meta hook) verbatim to
      `scripts/git-hooks/pre-commit`. No behaviour change yet.
- [ ] Move the body of the test loop into
      `scripts/git-hooks/lib/runners/meta.sh` as `metaGate()`.
- [ ] Replace `.git/hooks/pre-commit` with a symlink to
      `../../scripts/git-hooks/pre-commit` (the tracked source).
- [ ] Run `git commit --allow-empty -m test` once to confirm the new
      symlinked hook behaves identically.

### F1 — extract shared helpers
- [ ] `scripts/git-hooks/lib/lib/colors.sh` — pass/fail/warn shell
      helpers (lifted from the current hook's preamble).
- [ ] `scripts/git-hooks/lib/lib/botopink-bin.sh` — `locateBotopink`
      function: env > nearest ancestor `repository/botopink-lang/zig-out/bin/botopink`
      > `$PATH` > skip+warn.
- [ ] `scripts/git-hooks/lib/test-runner.sh` — `runProjectGate(root)`:
      detect project type (`.gitmodules` → meta; `build.zig` +
      `modules/` → botopink-lang; `botopink.json` only → bp-lib;
      `package.json` with `botopink.lsp` markers → vscode-extension)
      and dispatch.

### F2 — write per-project gates
- [ ] `runners/botopink-lang.sh` — current "Compilation" + "Tests" +
      "libs/* botopink test" loop, but **inside `repository/botopink-lang/`**
      (no workspace-vs-flat detection needed; that becomes a meta-only
      concern).
- [ ] `runners/bp-lib.sh` — `botopink test` in the lib's cwd; locate
      the binary via `botopink-bin.sh`; skip + warn if missing.
- [ ] `runners/vscode-extension.sh` — `npm test`; bootstrap `npm install`
      once if `node_modules/` missing; reuse `scripts/test-vscode.sh`
      logic where possible.
- [ ] `runners/meta.sh` — current four-step gate **plus** the new
      "scan staged submodule bumps" routine (see F3).

### F3 — submodule pointer scan in meta gate
- [ ] In `runners/meta.sh` after the existing steps: run
      `git diff --cached --name-only` and filter against `.gitmodules`
      paths. For each hit:
      - resolve staged SHA: `git diff --cached <path> | awk '/^\+Subproject commit/ { print $3 }'`
      - `git -C repository/<sub> worktree add .tasks/_hook-<sub>-<sha7> <sha>`
      - cd into the throwaway worktree, run `runProjectGate "$(pwd)"`
      - on success: `git -C repository/<sub> worktree remove .tasks/_hook-<sub>-<sha7>`
      - on failure: print a clear error pointing at the worktree (don't
        clean it up — the user wants to inspect)
- [ ] Race-safety: if a worktree already exists at the path (rare —
      previous failed commit), reuse it; do not double-`worktree add`.
- [ ] Time budget: the meta scan is allowed up to 10 minutes per
      submodule (the lib gates run fast); if longer, fail with a
      "split your commit — don't bump multiple submodules at once"
      message.

### F4 — per-submodule tracked pre-commit
- [ ] In each of the 6 submodule repos: add
      `scripts/git-hooks/pre-commit` (the shim above) +
      `scripts/git-hooks/lib/runner-standalone.sh` (the per-project
      gate for the standalone-clone path).
- [ ] Update each submodule's `AGENTS.md` "CI" section with a new
      "Local gate" subsection pointing at the tracked hook +
      `scripts/install-hooks.sh`.

### F5 — install-hooks.sh
- [ ] `scripts/install-hooks.sh`: walks `.gitmodules`, resolves each
      submodule's git dir (handles linkfile `.git` files), symlinks
      each `pre-commit`. Backs up existing non-symlink files.
- [ ] `--check` flag: print ✓/⚠/✗ per project, exit non-zero on any
      missing or drifted.
- [ ] `--meta-only` flag: skip submodules (for partial clones).
- [ ] Re-run safe (idempotent).

### F6 — CI guard
- [ ] `.github/workflows/hook-integrity.yml`: 1 job, 7-matrix
      (one per project), runs `install-hooks.sh` then
      `install-hooks.sh --check` then replays the tracked hook against
      HEAD (the bypass-catcher).
- [ ] Triggers: `push` to any branch + `pull_request`.

### F7 — docs
- [ ] `scripts/AGENTS.md` — new "Hook layout" section pointing at
      `git-hooks/` tree + `install-hooks.sh` + the per-project
      dispatch table from this spec.
- [ ] `repository/AGENTS.md` — add a one-line row to the workspace
      overview noting that every submodule has a tracked pre-commit
      hook and how to install all 7 at once.
- [ ] `repository/botopink-lang/AGENTS.md` — replace its existing
      "pre-commit" paragraph with a pointer to the tracked source +
      install script.
- [ ] Each lib's `AGENTS.md` — "Local gate" subsection per F4.
- [ ] This set's `README.md` + `status.md` — add the
      recursive-test-gate row.

## Test scenarios

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

## Notes

- **Why "recursive" instead of "the meta hook tests everything in one go"?**
  Three reasons. (1) The submodules are independently committable: every
  lib repo has its own author, its own CI, its own release cadence. The
  hook must run *inside* the submodule where the commit happens, not
  only at the meta. (2) When the meta bumps a submodule pointer, it
  must validate the **staged SHA**, not whatever the working tree at
  `repository/<sub>` currently shows — those can differ during a partial
  rebase. Hence the throwaway worktree on the staged SHA. (3) Eric works
  in parallel across `.tasks/<slug>/` worktrees (memory:
  `feedback_user_works_in_parallel.md`); each worktree gets its own
  hook because each worktree is a separate Git checkout.

- **Why a tracked hook + bootstrap instead of `core.hooksPath`?**
  `core.hooksPath` is a global config knob, not per-repo, and the user's
  memory rule "NEVER update the git config" (CLAUDE.md global) rules
  it out. A bootstrap script that creates symlinks is per-repo, explicit,
  and uninstallable. The hook-integrity CI catches the case where
  someone forgot to run the bootstrap.

- **Why catch `--no-verify` in CI instead of forbidding it locally?**
  `--no-verify` is sometimes legitimate (the maintainer is debugging the
  hook itself, or shipping a hotfix while the gate is being repaired).
  The local hook should *not* prevent it; the CI guard ensures the
  landed commit is still green against the tracked gate, so a bypass
  reaches `feat` only if the tests actually pass.

- **Why warn instead of fail when the botopink binary is missing in a
  bp-lib gate?** A fresh checkout of `repository/erika` standalone (no
  meta) has no compiler nearby. Forcing the lib author to build the
  compiler before every commit is hostile; CI runs the full gate and
  catches any regression. The local hook still **runs** the gate when
  possible (the common case: meta workspace has `zig-out/bin/botopink`
  built), and falls back to a yellow warning only when it cannot.

- **Why the throwaway worktree at `.tasks/_hook-<sub>-<sha7>/` and not
  `tmp/` or `/tmp/`?** Mirrors the existing
  `.tasks/_integrate-<slug>/` pattern from v0.beta.7's consolidation
  memo. Keeps every Git worktree the project creates under the same
  `.tasks/` umbrella; `tmp/` would pollute the working tree, and
  `/tmp/` defeats the inspect-on-failure use case (users don't
  remember to look outside the repo).

- **Why per-submodule `scripts/git-hooks/pre-commit` files instead of
  one canonical file the meta script symlinks?** The submodules are
  **independent repos**: each gets cloned standalone (lib authors,
  `bpmp` packing, the v0.beta.18 lib-test-workflows CI matrix's
  `actions/checkout` step). A submodule's tracked hook **must** live
  inside the submodule's own tree, or a standalone clone would have no
  hook at all. The thin shim shape keeps the duplication at "one
  source line per project" — the substantive logic lives in the meta's
  shared runner when reachable, in the per-project standalone runner
  otherwise.

- **No interaction with the spec/worktree workflow.** This spec adds a
  hook layer; it does not change how worktrees are created, how `feat`
  integrates, or how `status.md` rolls up. The hook runs **inside**
  whatever worktree the user has; the `.tasks/<slug>/` machinery in
  `tasks/AGENTS.md` §"Workflow" is unchanged.

- **Cross-spec coordination.**
  - [`frente-c-distribution`](frente-c-distribution.md) §J
    (`module-auto-tag`) already shipped — this spec adds a local gate
    that runs **before** the tag workflow fires on push. Belt + braces.
  - [`tasks/v0.beta.18/specs/lib-test-workflows.md`](../../v0.beta.18/specs/lib-test-workflows.md)
    documents the per-lib CI matrix. This spec is the **local** twin
    of that CI — they cover the same gates, on the same projects, at
    different points in the pipeline (pre-push vs pre-merge).
  - [`tasks/v0.beta.13/specs/lib-test-runner.md`](../../v0.beta.13/specs/lib-test-runner.md)
    shipped `botopink-lib-test` + `zig build test-libs`; the
    botopink-lang gate calls these. No code is duplicated.

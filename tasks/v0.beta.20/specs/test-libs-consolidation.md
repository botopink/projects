# test-libs-consolidation — single source for the test-libs wrapper

**Slug**: test-libs-consolidation
**Depends on**: ci-pipelines-green (the in-tree copy under bot-lang
landed there to make `zig build test-libs` work in the lib-checkout
CI layout — `cd <lib>/botopink-lang && bash scripts/test-libs.sh`).
**Files**:
  - `scripts/test-libs.sh` (delete the meta copy)
  - `scripts/AGENTS.md` (path note: wrapper lives in
    `repository/botopink-lang/scripts/test-libs.sh`)
  - every meta caller that currently shells out to
    `scripts/test-libs.sh` (`grep -rn 'scripts/test-libs.sh'` in the
    meta tree to enumerate; expected: build.zig of bot-lang already
    uses the relative `scripts/test-libs.sh` which resolves to
    bot-lang's copy at the in-tree relative path)
  - `tasks/v0.beta.20/status.md`
**Status**: pending

## Problem

After `ci-pipelines-green`'s in-tree wrapper fix
(`build(test-libs): ship the wrapper inside botopink-lang/scripts/`),
the `scripts/test-libs.sh` file now exists in **two places**:

- `<meta>/scripts/test-libs.sh` — the legacy meta-workspace path,
  used by anyone who runs `scripts/test-libs.sh` from the meta repo
  root directly.
- `<bot-lang>/scripts/test-libs.sh` — the in-tree copy that
  `zig build test-libs` invokes via the relative `scripts/test-libs.sh`
  path (the path that the build.zig SystemCommand resolves at the
  build-root cwd).

Both copies are byte-identical at landing time. Once either is
touched, the other drifts silently — a familiar two-sources-of-truth
trap.

The wrapper's content already handles both layouts
(`cd "$(git rev-parse --show-toplevel)"` + `if [ -f
repository/botopink-lang/build.zig ]; then ...`), so picking one
location and pointing every caller at it is mechanical.

## Goal

After this spec lands:

- `<meta>/scripts/test-libs.sh` is **deleted**.
- Every meta caller that shelled out to the meta copy now uses
  `repository/botopink-lang/scripts/test-libs.sh` (or invokes
  `zig build test-libs` which resolves to the same path internally).
- `<meta>/scripts/AGENTS.md` carries a one-line note: "test-libs.sh
  lives under `repository/botopink-lang/scripts/` — see the
  path-detection logic inside the script."
- `tasks/v0.beta.20/status.md` `test-libs-consolidation` row reads
  `done`.

## Solution

### F1 — enumerate callers

```bash
cd <meta>
grep -rn 'scripts/test-libs.sh' . \
  --include='*.sh' --include='*.zig' --include='*.yml' \
  --include='*.md' --include='*.json' | grep -v node_modules
```

Expected hits (best guess at write-time):
- `scripts/test-libs.sh` itself (the file being deleted)
- `repository/botopink-lang/build.zig` (already uses the in-tree
  path `scripts/test-libs.sh`, resolved at bot-lang's build root —
  no change needed)
- `scripts/AGENTS.md` (doc reference, update to bot-lang path)
- `tasks/v0.beta.??/specs/recursive-test-gate.md` or sibling spec
  files (doc references; update for consistency)
- per-task TODO.md files referencing the wrapper (purely
  documentation; update on the same commit)

### F2 — update callers to bot-lang path

For each non-doc caller:
- Replace `scripts/test-libs.sh` with
  `repository/botopink-lang/scripts/test-libs.sh` (if invoked from
  meta root).

For doc callers (.md):
- Replace the path with
  `repository/botopink-lang/scripts/test-libs.sh` and add a sentence
  pointing at this spec.

### F3 — delete `<meta>/scripts/test-libs.sh`

```bash
git rm scripts/test-libs.sh
```

### F4 — update `scripts/AGENTS.md`

Add (or update) the section describing the wrapper's home:

```markdown
### `test-libs.sh`

Lives at `repository/botopink-lang/scripts/test-libs.sh` (in-tree so
both the meta workspace layout and the standalone lib-checkout
layout resolve it via the same relative `scripts/test-libs.sh` path
inside bot-lang). The script's `cd "$(git rev-parse
--show-toplevel)"` + `if [ -f repository/botopink-lang/build.zig ];
then ...` chain detects which layout it's running under.
```

### F5 — meta commit + status.md

Single meta commit: F1's caller updates + F3's deletion + F4's
AGENTS.md note + flip this set's row in `tasks/v0.beta.20/status.md`
to `done`.

## Steps

1. **F1** — enumerate via the `grep -rn` above; record the list as a
   one-line comment at the top of this spec (audit trail).
2. **F2** — update non-doc callers (likely zero — bot-lang's
   build.zig already uses the in-tree path).
3. **F3** — delete `<meta>/scripts/test-libs.sh` via `git rm`.
4. **F4** — update `scripts/AGENTS.md`.
5. **F5** — one meta commit (no bot-lang changes needed since the
   in-tree copy is already authoritative).

## Test scenarios

- After F3+F4 lands: `find <meta> -name test-libs.sh` returns exactly
  one path: `<meta>/repository/botopink-lang/scripts/test-libs.sh`.
- After the commit: `zig build test-libs --target commonJS` still
  works from the meta workspace root (since bot-lang's build.zig
  resolves the wrapper internally).
- After the commit: `bash repository/botopink-lang/scripts/test-libs.sh`
  invoked from the meta root prints the runtime-preflight warnings
  + invokes `botopink-lib-test` (sanity smoke).

## Notes

- **Don't symlink across the submodule boundary.** Submodule + worktree
  + windows + symlinks is a recipe for fragility — keep the wrapper as
  a single concrete file inside bot-lang.
- **Don't add a third home.** If someone proposes ` install-tooling.sh`
  copies the wrapper into meta on first-run "for convenience", treat
  that as a regression — the in-tree path resolution already works
  in both layouts.
- **The `botopink-lang` submodule pointer is the contract.** When
  a meta clone updates submodules, it picks up the wrapper
  automatically — no extra install step needed.

## Exit gate

This spec is **done** when:

- `<meta>/scripts/test-libs.sh` no longer exists in the meta repo.
- `<meta>/scripts/AGENTS.md` carries the path note.
- A fresh clone of meta + recursive submodule init can run
  `zig build test-libs --target commonJS` from the meta root without
  any "file not found" surface.
- `tasks/v0.beta.20/status.md` `test-libs-consolidation` row reads
  `done`.

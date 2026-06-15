# TODO — ci-pipelines-green

Spec: [tasks/v0.beta.19/specs/ci-pipelines-green.md](tasks/v0.beta.19/specs/ci-pipelines-green.md)
Worktree: `.tasks/ci-pipelines-green/` (branch `task/ci-pipelines-green` off
`origin/feat`)
Slug: `ci-pipelines-green`
Status: F1+F2+F3 landed locally across all 7 repos (6 submodule commits + meta
edits ready); F4 (pointer bumps + meta commit) + F5 (push + CI verify)
pending.

## Root causes (verified against live run logs on 2026-06-15)

1. **`mlugg/setup-zig@v1` cannot download Zig 0.16.0.** The 0.16.0 release
   moved the tarball path on `ziglang.org` from `zig-<os>-<arch>-…` to
   `zig-<arch>-<os>-…`. v1 of the action + every community mirror still
   resolve the old layout — every install errors with "Unable to locate
   executable file: zig". `mlugg/setup-zig@v2` (currently v2.2.1) reads
   the new manifest. **Pinned bump: `@v1` → `@v2` everywhere.**
2. **vscode-extension `npm test` ships a quoted glob** that Node 20's
   `--test` does not expand. The package.json script is
   `node --test "test/**/*.test.ts"` — runner reports `Could not find
   '/…/test/**/*.test.ts'` and exits 1, cascading into the meta repo's
   `hook-integrity.yml`. **Fix: replace the quoted glob with the
   directory form `--test test/`.**
3. **Node 20 actions are deprecated and switch to Node 24 on
   2026-06-16** (i.e. tomorrow). Bump `actions/checkout@v4 → @v5` and
   `actions/setup-node@v4 → @v5` everywhere in the same sweep.

## Files this task touches

All edits land **on each submodule's `feat` branch** (six independent
PRs/pushes), then the meta repo bumps the vscode-extension pointer and
commits the F1+F2 changes to its own `hook-integrity.yml` + README/status.

```
repository/botopink-lang/.github/workflows/test.yml       F1+F2
repository/botopink-lang/.github/workflows/tag.yml        F2
repository/botopink-lang/.github/workflows/release.yml    F2
repository/jhonstart/.github/workflows/test.yml           F1+F2
repository/jhonstart/.github/workflows/tag.yml            F2
repository/rakun/.github/workflows/test.yml               F1+F2
repository/rakun/.github/workflows/tag.yml                F2
repository/erika/.github/workflows/test.yml               F1+F2
repository/erika/.github/workflows/tag.yml                F2
repository/onze/.github/workflows/test.yml                F1+F2
repository/onze/.github/workflows/tag.yml                 F2
repository/vscode-extension/.github/workflows/test.yml    F2
repository/vscode-extension/.github/workflows/tag.yml     F2
repository/vscode-extension/.github/workflows/release.yml F2
repository/vscode-extension/package.json                  F3 (test script glob)
.github/workflows/hook-integrity.yml                      F1+F2
tasks/v0.beta.19/README.md                                docs (done in F0)
tasks/v0.beta.19/status.md                                F5 close-out
```

## Plan / checklist

### F0 — kickoff (this commit)

- [x] Spec landed at `tasks/v0.beta.19/specs/ci-pipelines-green.md`.
- [x] Scope-table row added to `tasks/v0.beta.19/README.md`.
- [x] Order block extended with the ci-pipelines-green entry.
- [x] TODO.md (this file) authored.
- [x] Initial commit on `task/ci-pipelines-green` to record the spec
      seed (324fc2b).

### F1 — `mlugg/setup-zig` v1 → v2 (per repo, on each lib's `feat`)

- [x] botopink-lang `test.yml` (2 call sites: jobs `test` + `test-libs`).
- [x] jhonstart `test.yml` (source-build branch).
- [x] rakun `test.yml`.
- [x] erika `test.yml` (beam + commonJS matrix entries).
- [x] onze `test.yml`.
- [x] meta `hook-integrity.yml` (matrix axes meta + repository/botopink-lang).

Verify per repo after push:
- Look for `Fetching zig-…0.16.0.tar.xz` followed by a 200 + an actual
  `zig version: 0.16.0` line in the next workflow step.

### F2 — `actions/checkout@v5` + `actions/setup-node@v5` (sweep)

- [x] botopink-lang `test.yml`, `tag.yml`, `release.yml`.
- [x] jhonstart `test.yml`, `tag.yml`.
- [x] rakun `test.yml`, `tag.yml`.
- [x] erika `test.yml`, `tag.yml`.
- [x] onze `test.yml`, `tag.yml`.
- [x] vscode-extension `test.yml`, `tag.yml`, `release.yml`.
- [x] meta `hook-integrity.yml`.

Verify per run: no `Node.js 20 actions are deprecated` warning above the
run summary.

### F3 — vscode-extension `npm test` glob

- [x] Edit `repository/vscode-extension/package.json`:
      `"test": "node --disable-warning=MODULE_TYPELESS_PACKAGE_JSON --test test/*.test.ts"`
      (spec authored `--test test/`; Node 25 — and likely Node 20 — treats
      the positional as a file path rather than a directory walk, so the
      shell-expanded `test/*.test.ts` form is portable across every Node
      and shell. Same discovery shape the broken `"test/**/*.test.ts"`
      glob was reaching for.)
- [x] Local smoke: `cd repository/vscode-extension && npm test` →
      `test/unit.test.ts` runs, 15/15 tests pass.
- [ ] Push to vscode-extension `feat`.

### F4 — meta pointer bump

- [ ] Sweep all 6 submodule pointers to their `task/ci-pipelines-green`
      heads (each branched off `origin/feat`, fast-forwards on push).
- [ ] Commit hook-integrity.yml + tasks/v0.beta.19/status.md + TODO.md
      tick + 6 pointer bumps in a single meta commit; gate spawns a
      throwaway worktree per bumped submodule and recursively replays
      its gate against the staged SHA.
- [ ] Push meta + each submodule branch to `origin/feat` in lockstep
      (one fast-forward each).

### F5 — docs roll + verify

- [x] `tasks/v0.beta.19/status.md` gains a one-line entry for this slug.
- [ ] `gh run list --repo botopink/<repo> --workflow test --branch feat
      --limit 1` returns `success` for botopink-lang, jhonstart, rakun,
      erika, onze, vscode-extension.
- [ ] `gh run list --repo botopink/projects --workflow hook-integrity
      --branch feat --limit 1` returns `success`.
- [ ] One whitespace-only push to each lib's `feat` confirms the chain
      stays green for ~10 min end-to-end.

## Gotchas

- **`.tasks/<slug>/.github/workflows/`**: every per-task worktree
  (`frente-a-compiler`, `frente-b-rules-tooling`, `prim-op-annotation`,
  `std-expansion-tail`, *this one*) carries its own copy of
  `hook-integrity.yml`. **Do not edit those.** They die when the
  worktree is removed. Only the source-of-truth at
  `.github/workflows/hook-integrity.yml` on the meta repo's `feat`
  branch matters.
- **Mid-merge state on the main worktree**: at kickoff time the main
  worktree was carrying a half-finished merge (TODO.md, status.md,
  submodule pointer edits in the index). This worktree is rooted at
  `origin/feat` so it doesn't share that state — keep edits here, do
  not `cd` back to the main tree.
- **Don't bump Zig**: spec is scope-tight on CI. Any Zig version change
  goes through `build.zig.zon` `minimum_zig_version` in its own gate.
- **Don't add `actions/cache` for zig**: setup-zig@v2 already does the
  cache + community-mirror fallback; an `actions/cache` layer adds
  maintenance without fixing the root cause.
- **SSH everywhere**: memory rule — push to `origin` always via SSH
  (already configured in `.gitmodules`). Do not introduce `gh repo
  push` / HTTPS tokens for any of the 7 pushes.

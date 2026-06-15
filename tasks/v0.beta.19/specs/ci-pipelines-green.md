# ci-pipelines-green — repair every red workflow in the botopink org

**Slug**: ci-pipelines-green
**Depends on**: nothing (purely workflow-yaml + one `npm test` glob fix)
**Files**:
  - **botopink-lang**:
    `repository/botopink-lang/.github/workflows/test.yml` ·
    `repository/botopink-lang/.github/workflows/release.yml` ·
    `repository/botopink-lang/.github/workflows/tag.yml`
  - **jhonstart**: `repository/jhonstart/.github/workflows/test.yml` ·
    `repository/jhonstart/.github/workflows/tag.yml`
  - **rakun**: `repository/rakun/.github/workflows/test.yml` ·
    `repository/rakun/.github/workflows/tag.yml`
  - **erika**: `repository/erika/.github/workflows/test.yml` ·
    `repository/erika/.github/workflows/tag.yml`
  - **onze**: `repository/onze/.github/workflows/test.yml` ·
    `repository/onze/.github/workflows/tag.yml`
  - **vscode-extension**:
    `repository/vscode-extension/.github/workflows/test.yml` ·
    `repository/vscode-extension/.github/workflows/tag.yml` ·
    `repository/vscode-extension/.github/workflows/release.yml` ·
    `repository/vscode-extension/package.json` (the `test` script glob)
  - **meta**: `.github/workflows/hook-integrity.yml`
**Touches docs**: `tasks/v0.beta.19/README.md` (scope table + Order block) ·
  this set's `status.md` (current-state row)
**Status**: pending

## Problem

Every `test`-class workflow in the botopink org is red as of 2026-06-15.
Three independent root causes, one of them with a hard deadline tomorrow.

### Root cause #1 — `mlugg/setup-zig@v1` cannot download Zig 0.16.0

Every workflow that builds the compiler calls

```yaml
- uses: mlugg/setup-zig@v1
  with:
    version: 0.16.0
```

Run-log excerpt (botopink-lang test.yml, macos-14, 2026-06-15 02:54):

```
Fetching zig-macos-aarch64-0.16.0.tar.xz
Cache miss. Fetching Zig 0.16.0
Attempting mirror: https://zigmirror.hryx.net/zig    → 404
Attempting mirror: https://pkg.machengine.org/zig    → 404
Attempting mirror: https://zig.linus.dev/zig         → 404
Attempting mirror: https://fs.liujiacai.net/zigbuilds → 404
Attempting mirror: https://zig.nekos.space/zig       → 503, 503, 503
Attempting official: https://ziglang.org/builds      → 404
##[error]Unable to locate executable file: zig.
```

Verified upstream cause: the official `ziglang.org/download/index.json`
manifest for 0.16.0 publishes the tarball at

```
https://ziglang.org/download/0.16.0/zig-x86_64-linux-0.16.0.tar.xz
```

Note the *arch-then-os* segment ordering (`zig-x86_64-linux-…`) — the v1
action and every community mirror still resolve the *os-then-arch* pattern
(`zig-linux-x86_64-…`), which is why the official URL also 404s. The
upstream layout change shipped with 0.16.0; `mlugg/setup-zig` released
**v2.0.0** (jul 2025) to adopt the new manifest path, with v2.2.1 as of
2026-01-19 the current head. Pinning at `@v1` is the trap.

**Repos affected** (every workflow that installs zig, all on the latest
red run):

| Repo | Workflow | Where |
|---|---|---|
| botopink-lang | `test.yml` | jobs `test` + `test-libs` (×2) |
| jhonstart | `test.yml` | source-build branch |
| rakun | `test.yml` | source-build branch |
| erika | `test.yml` | beam + commonJS matrices |
| onze | `test.yml` | commonJS matrix |
| meta (projects) | `hook-integrity.yml` | meta + repository/botopink-lang axes |

### Root cause #2 — vscode-extension `npm test` glob is unexpanded

`repository/vscode-extension/package.json` ships

```json
"test": "node --disable-warning=MODULE_TYPELESS_PACKAGE_JSON --test \"test/**/*.test.ts\""
```

Run-log (vscode-extension test.yml, ubuntu-22.04):

```
> botopink@0.3.0 test
> node --disable-warning=MODULE_TYPELESS_PACKAGE_JSON --test "test/**/*.test.ts"

Could not find '/home/runner/work/vscode-extension/vscode-extension/test/**/*.test.ts'
##[error]Process completed with exit code 1.
```

The shell sees the literal quoted string and hands it to node; Node 20's
`--test` does **not** expand glob patterns (that landed in Node 22 as
`--test --experimental-test-coverage` glob support, GA-d as plain glob
support a couple minors later). `test/unit.test.ts` exists locally —
the runner just never finds it.

This failure cascades into the meta repo's `hook-integrity.yml` because
that workflow runs each submodule's tracked pre-commit hook, which
for the vscode-extension axis runs `npm test`.

### Root cause #3 — Node 20 actions are deprecated, hard switch tomorrow

Every red run carries this warning (truncated):

```
Node.js 20 actions are deprecated. The following actions are running on
Node.js 20 and may not work as expected: actions/checkout@v4,
actions/setup-node@v4, mlugg/setup-zig@v1. Actions will be forced to run
with Node.js 24 by default starting June 16th, 2026.
```

That date is **2026-06-16**, i.e. tomorrow. After the switch, any v4-pinned
action that hasn't been verified against Node 24 may break in surprising
ways. The latest compatible majors are `actions/checkout@v5`,
`actions/setup-node@v5`, `mlugg/setup-zig@v2`.

## Goal

Every workflow listed under **Files** above is green on its `feat` branch
HEAD by the end of this spec, with the following guarantees:

- **Zig installs reliably**: `mlugg/setup-zig@v2` (pinned to the major,
  currently resolves to v2.2.1) on every job that calls `zig`.
- **vscode-extension `npm test` finds its test files** on the runner
  with the same shape the local `npm test` already exercises.
- **No deprecation-warning chain**: `actions/checkout@v5`,
  `actions/setup-node@v5`, `mlugg/setup-zig@v2` everywhere. The
  2026-06-16 forced Node-24 switch becomes a no-op for these repos.
- **`hook-integrity.yml` lights up green** on its `replay` matrix —
  i.e. fix #1 + fix #2 land together so the meta workflow stops
  cascading.

After this spec lands:

- the latest push to `feat` on every botopink repo turns the `test`
  check green,
- the meta `hook-integrity` workflow turns green on the same push,
- a new contributor cloning fresh and pushing a no-op commit sees CI
  green within ~5 min,
- there is one tracked note in `status.md` documenting the action
  versions in play so the next deprecation cycle has a single
  bump-target list.

## Solution

### F1 — `mlugg/setup-zig` v1 → v2 (one-line swap per call site)

Replace every

```yaml
- uses: mlugg/setup-zig@v1
  with:
    version: 0.16.0
```

with

```yaml
- uses: mlugg/setup-zig@v2
  with:
    version: 0.16.0
```

Call sites (8 total, all confirmed):

- `repository/botopink-lang/.github/workflows/test.yml` lines 34–37, 73–76
- `repository/jhonstart/.github/workflows/test.yml` lines 76–80
- `repository/rakun/.github/workflows/test.yml` (same shape)
- `repository/erika/.github/workflows/test.yml` (beam + commonJS jobs)
- `repository/onze/.github/workflows/test.yml`
- `.github/workflows/hook-integrity.yml` lines 41–45

No `version:` change needed — 0.16.0 stays. The v2 manifest reader is
what unblocks the download.

### F2 — `actions/checkout` v4 → v5, `actions/setup-node` v4 → v5

Every workflow listed under **Files** above gets `@v4` → `@v5` on both
actions. These are surface-compatible majors — no other input change
required for the way this repo uses them (no `lfs:`, no `submodules: …`
removal, no `cache:` semantics change against npm).

### F3 — vscode-extension `npm test` glob

Change `package.json` `test` script from

```json
"test": "node --disable-warning=MODULE_TYPELESS_PACKAGE_JSON --test \"test/**/*.test.ts\""
```

to

```json
"test": "node --disable-warning=MODULE_TYPELESS_PACKAGE_JSON --test test/"
```

Node's `--test <dir>` walks the directory tree and runs every
`*.test.{js,ts,mjs,cjs}` it finds — exactly the discovery shape the glob
was reaching for, and it works on Node 20 (no Node-22 dependency).
Manually verify on the workspace: `cd repository/vscode-extension &&
npm test` should pick up `test/unit.test.ts` and stay green.

### F4 — meta hook-integrity wiring stays unchanged

`.github/workflows/hook-integrity.yml` only needs the F1 + F2 bumps
(action versions). The cascading vscode-extension failure on the
`repository/vscode-extension` matrix axis disappears once F3 lands
**in the vscode-extension submodule** and the meta `feat` bumps the
pointer to that SHA.

### F5 — documentation roll

- `tasks/v0.beta.19/status.md` gains a one-line current-state entry
  pointing at this spec slug.
- `tasks/v0.beta.19/README.md` scope table gains the row, Order block
  gains `ci-pipelines-green → independent of every other spec`.
- No `AGENTS.md` edits — the workflow YAMLs are the documentation; the
  spec itself is the change record.

## Steps

1. **F1 — bump `mlugg/setup-zig`** across all 6 repos that build zig,
   in this order (each is one commit on the lib's `feat` branch):
   - botopink-lang test.yml (2 call sites)
   - jhonstart test.yml
   - rakun test.yml
   - erika test.yml (beam + commonJS)
   - onze test.yml
   - meta hook-integrity.yml
   For each: push → wait for the `test` check → verify zig installs
   (look for `Fetching zig-…0.16.0.tar.xz` followed by a 200 + an
   actual `zig version` line in the next step).
2. **F2 — bump `actions/checkout@v5` + `actions/setup-node@v5`** on
   every YAML in **Files**. Same per-repo cadence as F1; can be the
   *same commit* as F1 in each repo.
3. **F3 — vscode-extension `npm test` glob**:
   - edit `repository/vscode-extension/package.json` `test` script,
   - run `npm test` locally to confirm `test/unit.test.ts` is picked
     up and the suite passes,
   - commit + push to vscode-extension `feat`.
4. **F4 — meta pointer bump**: from the meta repo, `git submodule
   update --remote repository/vscode-extension` to advance the
   pointer to the F3 SHA, then commit + push so the next
   `hook-integrity` run picks up the green vscode-extension HEAD.
5. **F5 — docs roll**: update `tasks/v0.beta.19/status.md` +
   `README.md` in the meta repo (same commit as the meta pointer
   bumps, or a follow-up — both are fine).
6. **Verify**:
   - `gh run list --repo botopink/<repo> --workflow test --limit 1`
     returns `success` for each of the 6 repos with a test workflow.
   - `gh run list --repo botopink/projects --workflow hook-integrity
     --limit 1` returns `success`.
   - `gh run watch <run-id>` on one of each shape to eyeball the logs
     and confirm: zig installs from the v2 manifest URL (no 404s in
     the mirror chain), node test runner discovers `test/unit.test.ts`,
     no Node-20 deprecation warning above the run summary.

## Test scenarios

A single push to each lib's `feat` is the smoke. Concrete expectations:

- **botopink-lang test.yml**: `test (ubuntu-22.04|macos-14|windows-2022)`
  + `test-libs (ubuntu-22.04|macos-14)` all green; `test-libs
  (windows-2022)` stays allow-fail (pre-existing pinned red, out of
  scope).
- **jhonstart/rakun/erika/onze test.yml**: every `commonJS` matrix
  green; erika `beam` matrix green on ubuntu/macos.
- **vscode-extension test.yml**: ubuntu-22.04 green, `test/unit.test.ts`
  reported as passed.
- **meta hook-integrity.yml**: all 7 matrix axes (`meta` + 6 submodules)
  green. The matrix continues to use ubuntu-latest — the F1/F2 bumps
  do not change the matrix shape.

## Notes

- **Why not pin `mlugg/setup-zig` at a SHA**: the org already pins
  `@v1` (a moving major); the bump to `@v2` keeps the same posture.
  If a future deprecation needs a more conservative pin, that's a
  separate spec.
- **Why not bump Zig**: 0.16.0 is what `build.zig.zon`'s
  `minimum_zig_version` declares; this spec stays scope-tight and
  only touches CI. Any Zig bump goes through its own gate.
- **Why not pre-cache Zig**: `actions/cache` for the zig install is
  attractive but adds maintenance (cache key on `0.16.0`) without
  fixing the root cause. v2 already implements the official-manifest
  fallback + the community mirror retry; that's enough.
- **`release.yml` workflows**: included in **Files** because they
  receive the F2 action-version bumps for the Node-24 deadline.
  They are not currently red on the latest runs (release flows
  trigger on tag pushes, not branch pushes), but the deprecation
  applies to them too — bump in the same sweep.
- **`.tasks/<slug>/.github/workflows/`**: every per-task worktree has
  its own copy of the meta `hook-integrity.yml`. Those die when the
  worktree is removed; do **not** edit the per-task copies. The
  worktree-aware install-hooks fix already in `feat` is the
  upstream guard.
- **Co-ordination with `recursive-test-gate`**: file-disjoint —
  `recursive-test-gate` owns `.github/workflows/hook-integrity.yml`
  as a *new* file in its own scope; this spec edits the *landed*
  version on `feat`. They cannot conflict because
  `recursive-test-gate` is already merged on `feat` (8a153ce).

## Exit gate

This spec is **done** when, against the meta repo's `feat` branch
HEAD with all 6 submodule pointers at their respective `feat` HEADs:

- `gh run list --repo botopink/botopink-lang --workflow test --branch
  feat --limit 1` shows `success`,
- the same query against `jhonstart`, `rakun`, `erika`, `onze`,
  `vscode-extension` shows `success`,
- `gh run list --repo botopink/projects --workflow hook-integrity
  --limit 1` shows `success`,
- a fresh push (e.g. a whitespace-only README touch) to `feat` on
  each repo turns the corresponding `test` check green within
  ~10 min end-to-end,
- no Node-20 deprecation warning lines appear in the new runs,
- `tasks/v0.beta.19/status.md` carries the closing entry.

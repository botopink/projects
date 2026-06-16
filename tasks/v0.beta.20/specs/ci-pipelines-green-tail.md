# ci-pipelines-green-tail — wind down ci-pipelines-green's transitional shims

**Slug**: ci-pipelines-green-tail
**Depends on**: `ci-pipelines-green` (v0.beta.19) — landed across all 7
repos with the F1–F5 sweep + twelve uncovered follow-up layers as of
meta `53456cf` / bot-lang `b6afe7c`.
**Files**:
  - `repository/botopink-lang/.github/workflows/test.yml` (drop the
    diagnostic shim + the `ERL_AFLAGS` env)
  - `repository/botopink-lang/modules/compiler-core/src/codegen/runtime.zig`
    (document the stdout-only contract — no behaviour change)
  - `.github/workflows/hook-integrity.yml` (drop the job-level
    `ERL_AFLAGS` env)
  - `tasks/v0.beta.19/status.md` (`ci-pipelines-green` row → **done**)
  - `tasks/v0.beta.20/status.md` (this set's `ci-pipelines-green-tail`
    row reaches **done** on the closing commit)
**Status**: pending

## Problem

The `ci-pipelines-green` investigation phase landed three transitional
shims on `feat` that should now be removed:

1. **Diagnostic `Upload snap .new files (on failure)` step** in
   `botopink-lang/test.yml`. It was added to download the snapshot
   framework's `.snap.md.new` files when the residual
   `if_with_else_branch` mismatch was being diagnosed. The OTP 28 bump
   closed that residual; the artifact upload is now dead weight on
   every failed run.
2. **`ERL_AFLAGS: "-kernel logger_level critical"` env var** on the
   `zig build test` step in `botopink-lang/test.yml` AND on the
   job-level `env:` block in meta `hook-integrity.yml`. It was added
   while debugging the same residual — the hypothesis at the time was
   that Erlang's startup logger was tripping `executeErlang`'s
   strict-stderr short-circuit. The actual root cause turned out to be
   OTP 27's `erlc` treating the BIF-shadowing diagnostic as an error;
   the `ERL_AFLAGS` env is no longer doing anything.
3. **Decision pending on the `runtime.zig` stdout-only contract**.
   `executeErlang` and `executeBeamAsm` were changed to return
   stdout-only on success (drop stderr from the RUN LOG capture). The
   change is defensible standalone — `combineOutput(stdout, stderr)`
   captured a host-dependent surface — but it's not yet documented as
   the new contract.

The remaining gap is the **status.md `done` flip**: `ci-pipelines-green`
currently reads with `pending F4 + F5` qualifiers in
`tasks/v0.beta.19/status.md`. Once F1–F3 below land and the workflows
go green for a full cycle, the row flips to `done`.

## Goal

After this spec lands:

- `botopink-lang/.github/workflows/test.yml` and meta
  `.github/workflows/hook-integrity.yml` carry **only** the production
  steps + env they need — no diagnostic shims, no transitional
  flags.
- `runtime.zig` carries a short prose comment on the stdout-only
  contract (the `executeErlang` body already has one — promote to a
  module-level note so future contributors don't re-introduce the
  strict-stderr check).
- `tasks/v0.beta.19/status.md`'s `ci-pipelines-green` row reads
  `done` (no `(partial)` qualifier).
- `tasks/v0.beta.20/status.md` carries the `ci-pipelines-green-tail`
  row reaching `done` on the closing commit.
- The latest push on `feat` for both `botopink-lang test` and meta
  `hook-integrity` is `success`, **without** the transitional shims.

## Solution

### F0 — verify OTP 28 closes the residual on the latest run

Passive. Wait for the CI run on the meta+bot-lang HEAD that includes
the OTP 28 bump (`erlef/setup-beam@v1` with `otp-version: '28'`).

Expected:
- `gh run list --repo botopink/botopink-lang --workflow test --branch
  feat --limit 1` → `success` (ubuntu + macos; windows allow-fail per
  `backends-parity-windows`).
- `gh run list --repo botopink/projects --workflow hook-integrity
  --branch feat --limit 1` → `success` (all 7 matrix axes).

If still red on either: file the residual as a new gap, do **not**
proceed with F1–F3 (the shims may still be load-bearing).

### F1 — drop the diagnostic artifact upload

In `repository/botopink-lang/.github/workflows/test.yml`, delete the
step:

```yaml
- name: Upload snap .new files (on failure)
  if: failure()
  uses: actions/upload-artifact@v4
  with:
    name: snap-diffs-${{ matrix.runner }}
    path: modules/compiler-core/snapshots/**/*.snap.md.new
    if-no-files-found: ignore
    retention-days: 7
```

The snapshot framework still writes `.snap.md.new` on every mismatch —
re-add the artifact upload temporarily if a future investigation needs
the diff, but the steady-state workflow is artifact-free.

### F2 — drop the `ERL_AFLAGS` env

In `botopink-lang/test.yml`'s `zig build test` step, replace:

```yaml
- name: zig build test
  env:
    ERL_AFLAGS: "-kernel logger_level critical"
  run: zig build test
```

with:

```yaml
- name: zig build test
  run: zig build test
```

In meta `.github/workflows/hook-integrity.yml`, remove the job-level
`env:` block:

```yaml
jobs:
  replay:
    name: replay pre-commit (${{ matrix.project }})
    runs-on: ubuntu-latest
    env:
      ERL_AFLAGS: "-kernel logger_level critical"
    strategy: ...
```

becomes:

```yaml
jobs:
  replay:
    name: replay pre-commit (${{ matrix.project }})
    runs-on: ubuntu-latest
    strategy: ...
```

Re-run; if a new red surfaces because of the drop, document what
stderr it's silencing and re-add with a precise comment.

### F3 — document the `runtime.zig` stdout-only contract

In `repository/botopink-lang/modules/compiler-core/src/codegen/runtime.zig`,
promote the inline comment in `executeErlang` to a module-level note,
so the same contract is plainly stated for `executeBeamAsm` and any
future runtime helper:

```zig
//! RUN LOG capture contract: snapshot-bound runtime helpers
//! (`executeErlang`, `executeBeamAsm`, `executeJavaScript`,
//! `executeWat`) return *stdout-only* on success. Including stderr in
//! the snapshot makes the RUN LOG host-dependent (Erlang's startup
//! logger, Node's experimental warnings, wasmtime's deprecation
//! notices) — and `isProcessSuccess(term)` already covers the
//! "runtime crashed" surface the original `combineOutput(stdout,
//! stderr)` shape was trying to expose. If a future test needs
//! stderr in the snapshot, add `executeXCapturingStderr` next to it
//! — never re-introduce strict `stderr.len > 0 → empty` short-
//! circuits that prove fragile under runner-specific noise.
```

No behaviour change — pure docs.

### F4 — docs roll

- `tasks/v0.beta.19/status.md`: flip the `ci-pipelines-green` row to
  read `done` and update the trailing prose to reflect the closeout
  (drop the `pending F4 + F5` qualifier).
- `tasks/v0.beta.20/status.md`: this row enters `done` on the closing
  commit. (The set's other specs — `backends-parity-erlang`,
  `backends-parity-windows`, `test-libs-consolidation` — land on
  their own schedules.)

## Steps

1. **F0** — wait for the OTP 28 run to confirm green on both
   workflows (passive).
2. **F1** — single-file edit on `botopink-lang/test.yml` (drop the
   artifact step). One bot-lang commit + meta pointer bump.
3. **F2** — single-file edits on `botopink-lang/test.yml` +
   `.github/workflows/hook-integrity.yml` (drop the `ERL_AFLAGS`
   env). Same commit cadence: one bot-lang commit, one meta commit
   (with the hook-integrity.yml edit + pointer bump in the same).
4. **F3** — single-file docs edit on `runtime.zig`. Same commit as
   F2 on bot-lang (zero-LOC behaviour change keeps the gate quick).
5. **F4** — single meta commit flipping `status.md` rows + closing
   prose.

Each landing is a fast-forward push on `feat`; no rebase / merge
expected unless Eric advances `feat` mid-flight.

## Test scenarios

- After F1: `gh run list --repo botopink/botopink-lang --workflow test
  --branch feat --limit 1` reports `success`; the run summary shows
  **no** `snap-diffs-*` artifacts uploaded.
- After F2: same query reports `success`; the run log shows the
  `zig build test` step with **no** `env:` block above it.
- After F3: `git log -p modules/compiler-core/src/codegen/runtime.zig`
  shows the new module-level doc-comment as the only change; the gate
  runs and `zig build test` is green.
- After F4: `grep -A1 'ci-pipelines-green' tasks/v0.beta.19/status.md`
  shows `done`; `tasks/v0.beta.20/status.md` shows
  `ci-pipelines-green-tail` `done`.

## Notes

- **Don't roll the OTP version back**. OTP 28's erlc treats the
  shadowed-BIF diagnostic as a warning where OTP 27 treated it as an
  error. The codegen test fixture is the source of truth — if a
  future OTP tightens it back to error, the fix is the codegen
  emitting `-compile({no_auto_import,…}).` (which
  `backends-parity-erlang` is authoring), not pinning a different
  OTP.
- **Don't re-introduce the strict stderr check** in `runtime.zig`.
  The strict check is what made the original residual appear in the
  first place. If a future test needs stderr in the snapshot, add a
  `executeXCapturingStderr` helper alongside (see F3 docs comment).
- **Don't squash F1–F3 into one commit**. Each is independent and
  individually revertable. Keep them as separate per-repo commits
  with matching meta pointer bumps.

## Exit gate

This spec is **done** when, against the meta repo's `feat` branch
HEAD with all 6 submodule pointers at their respective `feat` HEADs:

- F0 confirmed green on both `botopink-lang test` and meta
  `hook-integrity`.
- F1, F2, F3 commits all landed on `feat` (bot-lang +/or meta).
- `tasks/v0.beta.19/status.md` `ci-pipelines-green` row reads
  `done`.
- `tasks/v0.beta.20/status.md` `ci-pipelines-green-tail` row reads
  `done`.
- A subsequent no-op push on `feat` (whitespace touch on the README)
  still turns the `test` + `hook-integrity` checks green within
  ~5 min end-to-end, with **no** transitional shims in the workflow
  logs.

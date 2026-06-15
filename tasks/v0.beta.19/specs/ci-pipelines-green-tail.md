# ci-pipelines-green-tail — finish ci-pipelines-green + deferred reds

**Slug**: ci-pipelines-green-tail
**Depends on**: ci-pipelines-green (the main spec — landed across all 7
repos with the F1–F5 sweep + 12 follow-up sweeps as of meta `53456cf` /
bot-lang `b6afe7c`)
**Files**:
  - **botopink-lang**:
    `repository/botopink-lang/.github/workflows/test.yml` ·
    `repository/botopink-lang/modules/compiler-core/src/codegen/runtime.zig` ·
    `repository/botopink-lang/scripts/test-libs.sh` (sync vs meta) ·
    `repository/botopink-lang/modules/compiler-core/src/comptime/runtime/erlang.zig`
    (OTP-27 / erlang JSON module mismatch — only if OTP-28 bump exposes
    new gaps)
  - **meta**: `.github/workflows/hook-integrity.yml` ·
    `scripts/test-libs.sh` (sync vs bot-lang) · `tasks/v0.beta.19/status.md`
  - **lib workflows** (deferred — handled in separate specs, see below):
    each of `repository/{erika,jhonstart,onze,rakun}/.github/workflows/test.yml`
**Touches docs**: `tasks/v0.beta.19/status.md` (ci-pipelines-green row →
`done`) · `tasks/v0.beta.19/README.md` (Scope table + Order block)
**Status**: pending

## Problem

The main `ci-pipelines-green` spec closed the three explicit root causes
plus four uncovered layers of pre-existing reds (erlang install, REF=feat
default, Node 22 + strip-types, test-libs wrapper path, wasmtime install,
OTP 27→28, ERL_AFLAGS, runtime.zig stderr-drop, wasmtime version pin,
diagnostic shim). The current head leaves a small tail of cleanup,
verification, and explicitly-deferred reds:

1. **Diagnostic shim still in the workflow**: the `Upload snap .new
   files (on failure)` step in `botopink-lang/test.yml` was added to
   diagnose the residual `if_with_else_branch` snap mismatch. Once OTP 28
   is confirmed to close that residual, the artifact upload step is
   dead weight — remove it.
2. **`ERL_AFLAGS` env var possibly dead weight**: I added
   `ERL_AFLAGS: "-kernel logger_level critical"` to both `test.yml` and
   `hook-integrity.yml` while debugging the residual. OTP 28's compile
   path doesn't emit the same erlc error, so the env var may no longer
   be doing anything. Verify and remove.
3. **`runtime.zig` stderr-drop change**: `executeErlang` and
   `executeBeamAsm` no longer combine stdout + stderr into the RUN LOG —
   they return stdout-only. This is a defensible change (host-independent
   RUN LOG capture), but if OTP 28 closes the residual on its own, the
   minimal-surface revert is keeping `combineOutput(...)`. Decide:
   stdout-only (host-independent, drops legit stderr info) vs.
   `combineOutput` (host-dependent but captures all output). Recommend:
   keep stdout-only as the new contract — the original behavior was
   fragile.
4. **`scripts/test-libs.sh` duplicated**: the wrapper now lives at BOTH
   `<meta>/scripts/test-libs.sh` (legacy meta-workspace path) AND
   `<bot-lang>/scripts/test-libs.sh` (in-tree, layout-agnostic). Two
   sources will drift. Pick one:
     - **(a) bot-lang owns it**: meta deletes its copy, every script
       caller goes through the submodule path. Cleanest long-term, but
       requires touching every meta entry point that currently shells
       out to `scripts/test-libs.sh`.
     - **(b) meta owns it, bot-lang symlinks**: cross-repo symlinks
       are fragile (git submodules + worktrees + windows == drift).
     - **(c) accept the duplicate**: byte-identical content, both kept
       in sync manually. Cheapest, but earns "two sources of truth"
       label.
     Recommended: (a) — single source in bot-lang, meta caller(s)
     updated to `repository/botopink-lang/scripts/test-libs.sh`.
5. **Lib `test.yml` allow_fail rows tracked as deferred reds** (see
   "Out-of-scope reds" below): erika/jhonstart/onze/rakun all have
   per-axis `allow_fail: true` on erlang + windows-commonJS axes so the
   workflow conclusion reflects the spec's hard gate. The underlying
   reds need their own specs.

## Goal

After this tail spec lands:

- The cleanup items (1)–(4) are resolved, and the CI YAML side of
  ci-pipelines-green is minimal-surface — no diagnostic shims, no dead
  env vars, no duplicated wrappers.
- `tasks/v0.beta.19/status.md`'s `ci-pipelines-green` row flips from
  the in-progress state to **done**.
- The out-of-scope reds are formally recorded as separate specs (one
  per root cause) with crisp problem statements so they can be
  scheduled independently.

## Solution

### F0 — verify OTP 28 closes the residual

Wait for the latest `botopink-lang/test.yml` (head `b6afe7c`) + meta
`hook-integrity.yml` (head `53456cf` pending follow-up) runs to land.
Expected:

- `gh run list --repo botopink/botopink-lang --workflow test --branch
  feat --limit 1` shows `success` on the ubuntu+macos axes.
- `gh run list --repo botopink/projects --workflow hook-integrity
  --branch feat --limit 1` shows `success` on the meta + bot-lang axes
  (the other 5 axes are already green per the most recent runs).

If still red:
- Pull the `snap-diffs-ubuntu-22.04` artifact, diff against the local
  committed snapshot, and identify the next layer.
- If the issue is another OTP-version-dependent erlc warning-as-error
  (a different fixture has a different shadowed BIF), the fix is
  one of:
    (a) add a `+nowarn_X` flag to `executeErlang`'s `erlc` invocation
    (botopink-lang source change in `codegen/runtime.zig`);
    (b) emit `-compile({no_auto_import,[...]}).` in the codegen for any
    function whose name matches an auto-imported BIF (botopink-lang
    source change in `codegen/erlang.zig`).
  (b) is the more correct fix — the generated code shouldn't depend on
  a forgiving erlc.

### F1 — remove the diagnostic artifact step

In `repository/botopink-lang/.github/workflows/test.yml`, delete:

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

Justification: the diagnostic was load-bearing during ci-pipelines-green's
investigation phase. Once the workflow is green, the artifact upload is
dead code — the snap framework still writes `.new` files locally for
the next iteration's `gh run download` flow if needed.

### F2 — remove `ERL_AFLAGS` (if OTP 28 alone suffices)

In `botopink-lang/test.yml`'s `zig build test` step + `hook-integrity.yml`'s
job-level `env`, drop:

```yaml
env:
  ERL_AFLAGS: "-kernel logger_level critical"
```

Justification: the flag was intended to silence Erlang's startup logger
notice that triggered the strict "any stderr → empty RUN LOG"
short-circuit. With OTP 28 + the runtime.zig stdout-only change, this
flag is no longer doing anything — drop it to keep the workflow
minimal-surface.

Verify by:
- Re-run the workflows with the env removed.
- If still green: drop is safe.
- If a new red surfaces: re-add with a comment explaining what stderr
  it suppresses.

### F3 — `runtime.zig` stdout-only contract (decision)

Two paths:

- **(a) Keep stdout-only** (recommended): the change is defensible on its
  own — `executeErlang`'s RUN LOG should be host-independent, and
  capturing stderr from `erl -noinput` is a stale design (the original
  intent was to surface runtime errors, but `isProcessSuccess(term)`
  already covers that). Document the contract in `runtime.zig` (the
  comment already added in `b8fc80c` is enough).

- **(b) Revert to `combineOutput`**: only if OTP 28 closes the residual
  AND the test fixtures' snapshots have stderr content that the
  framework should still capture. Verify by walking
  `snapshots/codegen/{erlang,beam_asm}/**/*.snap.md` for any RUN LOG
  block whose content looks like an erlang error report. If found, the
  snapshots were recorded with stderr — revert is needed. If not found,
  (a) wins.

Recommended audit:

```bash
cd repository/botopink-lang/modules/compiler-core
grep -lE '^=ERROR REPORT|^=NOTICE REPORT|^=PROGRESS REPORT' \
  snapshots/codegen/{erlang,beam_asm}/**/*.snap.md
```

If empty, keep stdout-only.

### F4 — consolidate `scripts/test-libs.sh` (decision: bot-lang owns)

1. Inspect every meta caller that currently shells out to
   `scripts/test-libs.sh` (likely `scripts/test-libs.sh` itself is only
   called from `build.zig` — but verify with `grep -rn 'scripts/test-libs.sh'`
   in the meta tree).
2. Update those callers to use
   `repository/botopink-lang/scripts/test-libs.sh`.
3. Delete `<meta>/scripts/test-libs.sh`.
4. Add a short note in `scripts/AGENTS.md` ("test-libs.sh lives under
   `repository/botopink-lang/scripts/` — see the path-detection logic
   inside the script").

### F5 — docs roll

- `tasks/v0.beta.19/status.md`: ci-pipelines-green row flips to **done**.
- `tasks/v0.beta.19/README.md`: Scope table row update; Order block
  adds `ci-pipelines-green-tail → consumes ci-pipelines-green's CI
  surface, independent of every other spec`.
- This file gets a closing note when F0–F4 complete.

## Out-of-scope reds (deferred to dedicated specs)

These were uncovered by ci-pipelines-green's investigation but are NOT
in scope for ci-pipelines-green or this tail. Each gets its own spec.

### A — backends-parity-erlang-tail

**Problem**: every sibling lib's `test` workflow has the erlang +
beam matrix axes marked `allow_fail: true` because the erlang/erlc
codegen path has known reds: shadowed BIFs (`abs/1`), function-name
collisions with module names, and missing JSON encoders on older OTP
versions. Memory: `project_stdlib_backends_parity`.

**Files**: `modules/compiler-core/src/codegen/erlang.zig` (emit
`-compile({no_auto_import,[abs/1,...]}).` for shadowed BIFs);
`modules/compiler-core/src/codegen/beam_asm.zig` (parity); each
sibling lib's `repository/<lib>/.github/workflows/test.yml` (drop the
erlang allow_fail once the codegen is fixed).

**Acceptance**: erika/jhonstart/onze/rakun erlang + beam matrix axes
turn green on `feat`, allow_fail markers removed.

### B — backends-parity-windows-pwsh

**Problem**: windows-2022 commonJS matrix axes fail with
`bash: ../../scripts/test-libs.sh` resolved against PowerShell's
`${LIB_NAME}` expansion gap (PowerShell doesn't expand POSIX-style
shell vars). Every sibling lib carries this red as
`allow_fail: true`.

**Files**: each sibling lib's `.github/workflows/test.yml` — either
switch the `run:` shell to `bash` explicitly + escape via env var, or
pass the lib name via `env: LIB_NAME: …` and a `pwsh`-compatible
syntax.

**Acceptance**: windows-2022 commonJS axes turn green across all 4
sibling libs.

### C — botopink-lang windows snapshot drift

**Problem**: 763 tests under `modules/compiler-core/src/parser/tests/`,
`comptime/tests/`, `codegen/tests/` fail on windows-2022 with snap
mismatch (CRLF vs LF + windows path-separator drift in the captured
test output). The botopink-lang `test (windows-2022)` axis carries
`allow_fail: true`. Memory: `project_zig016_parallel_test_flakiness`
covers a different snap-related flake; this windows gap is separate.

**Files**: `modules/compiler-core/src/utils/snap.zig` (normalise line
endings + path separators before comparing); each snapshot file
that was recorded on windows or has windows-sensitive content.

**Acceptance**: botopink-lang `test (windows-2022)` axis turns green,
allow_fail removed.

### D — distribution: `test-libs.sh` symlink across submodule (optional)

If F4's "bot-lang owns" decision turns out to be inconvenient — e.g. a
fresh meta clone without submodules can't run `zig build test-libs`
locally — consider a small bootstrap step in `install-tooling.sh` that
copies `repository/botopink-lang/scripts/test-libs.sh` into
`<meta>/scripts/` (treating the meta one as a regenerated cache). Pure
optionality; track as a deferred follow-up.

## Steps

1. **F0 — verify OTP 28 closes the residual** (passive wait; on red,
   downgrade to source-level fix per the if-still-red branch above).
2. **F1 — remove the artifact upload step** (commit + push to bot-lang
   `feat`).
3. **F2 — remove `ERL_AFLAGS`** (commit + push to bot-lang `feat` AND
   meta `feat` hook-integrity.yml).
4. **F3 — `runtime.zig` audit + decide** (script the snapshot audit;
   record the decision in this file + the runtime.zig comment).
5. **F4 — consolidate `scripts/test-libs.sh`** (commit + push to bot-lang
   first if needed, then meta).
6. **F5 — docs roll** (status.md flips to `done`, this file gets the
   close-out section).
7. **Author specs A–D** as separate files under
   `tasks/v0.beta.19/specs/` (or v0.beta.20 if the v.19 set is already
   closed by then).

## Test scenarios

After F0–F4 land:

- `gh run list --repo botopink/botopink-lang --workflow test --branch
  feat --limit 1` shows `success` (ubuntu + macos green; windows
  allow-fail).
- `gh run list --repo botopink/projects --workflow hook-integrity
  --branch feat --limit 1` shows `success` (all 7 matrix axes green).
- `git diff origin/feat --stat` for both bot-lang and meta shows
  net-negative line counts (removed: artifact step, ERL_AFLAGS,
  duplicate script) with no test reds.

## Notes

- **Don't roll the OTP version backward**: OTP 28's erlc gives a
  *warning* where OTP 27 gave an *error* for the `abs/1` shadowing case.
  The codegen test fixture is the source of truth — if a future OTP
  tightens the diagnostic to error again, the fix is the codegen
  emitting `-compile({no_auto_import,[...]}).`, not pinning OTP.
- **Don't re-introduce the strict stderr check** in `runtime.zig`:
  the strict check is what made the residual appear in the first place.
  If a future test needs to capture stderr (e.g. an error-codegen
  fixture), use a separate code path (`executeErlangCapturingStderr`).
- **Don't squash F1–F4 into one commit**: each is independent and
  individually revertable. Keep them as separate per-repo commits with
  matching meta pointer bumps.

## Exit gate

This tail spec is **done** when, against the meta repo's `feat` branch
HEAD with all 6 submodule pointers at their respective `feat` HEADs:

- F0 confirmed: `botopink-lang test` + meta `hook-integrity` runs both
  `success`.
- F1–F4 commits landed on `feat` (per the per-step Steps above).
- `tasks/v0.beta.19/status.md`'s `ci-pipelines-green` row reads
  **done** (no `(partial)` or `(deferred)` qualifier).
- Specs A–D authored (one file each, under `tasks/v0.beta.19/specs/`
  or `tasks/v0.beta.20/specs/`), with their own scope tables /
  problem statements / exit gates.
- This file's "Close-out" section (added on completion) lists every
  commit SHA that landed under it.

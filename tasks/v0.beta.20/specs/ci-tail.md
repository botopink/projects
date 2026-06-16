# ci-tail — CI cleanup (closes v0.beta.19 `ci-pipelines-green` 2 deferreds + transitional shims)

**Slug**: ci-tail
**Depends on**: v0.beta.19 `ci-pipelines-green` — landed across 7 repos (F1–F5 + 12 follow-up layers as of meta `53456cf` / bot-lang `b6afe7c`); this set winds down the transitional shims and closes the 2 deferred reds (`backends-parity` erlang + windows).
**Files**: `repository/botopink-lang/.github/workflows/test.yml` · `runtime.zig` doc · meta `hook-integrity.yml` · meta `scripts/test-libs.sh` (delete) · `codegen/erlang.zig` + `codegen/beam_asm.zig` (BIF directive) · `compiler-core/src/utils/snap.zig` (LF + path-sep normalisation) · 5× `.github/workflows/test.yml` (4 sibling libs + bot-lang).
**Touches docs**: `tasks/v0.beta.19/status.md` (`ci-pipelines-green` row → done) · `tasks/v0.beta.20/status.md`.
**Status**: partial — 2 sub-specs across 2 stages; both have halves landed.

## Current state (partials landed on origin/feat — meta 28929e2 / bot-lang 0568466)

| Sub-spec | Landed | Remaining |
|---|---|---|
| **01-cleanup** | B-half: meta `scripts/test-libs.sh` deleted (`e3b9d3a`) · bot-lang in-tree wrapper is canonical · A-half partial: F1 (artifact step drop) `c8e1e6d` · F2 (`ERL_AFLAGS` drop) `c8e1e6d`+`7bf9e17` · F3 (`runtime.zig` doc) `08ad75f` | B-half: AGENTS.md `scripts/` path note + caller updates · A0/A4 confirmation that v19 row → done on `tasks/v0.beta.19/status.md` |
| **02-backends-parity** | E-half: `codegen/erlang.zig` BIF auto-import directive (now **annotation-driven** from `libs/std/src/erlang.bp` `@External.Erlang("erlang", "<symbol>")` decls via `prelude.pkg_modules` — `0568466`) + 4 snapshot regens (`max/2`, `node/0`, 2× `abs/1`) | E-half: `codegen/beam_asm.zig` parity audit · 4× sibling lib `test.yml` `allow_fail: false` flip on erlang+beam axes (currently 4 libs still red on erlang — pre-existing, tracked here) · W-half (all): sibling-lib `shell: bash` fix · `snap.zig` CRLF+path normalisation · bot-lang snap regen on windows · drop windows `allow_fail` rows across 5 workflow YAMLs · **extend `std/erlang.bp` catalog**: today ~32 single-word BIFs covered (palavras únicas que botopink camelCase shadowiza); BIFs com payload-of-args (`spawn/2..4`, `monitor/3`, `apply/3`, `error/2..3`, `exit/2`, `halt/1..2`, `nodes/1`, `register/2`, `link/2`, `monitor/3`, `process_info/2`, `register/2`, `spawn_link/N`, `spawn_monitor/3`, `spawn_opt/N`) ainda não cobertos por overloads contíguas — feature de `fn-param-default-expansion` que permite trailing defaults em `declare fn` liberará a forma compacta |

## DAG

```
01-cleanup (drops v19 shims + consolidates test-libs.sh)
  └─▶ 02-backends-parity (erlang BIF directive + windows-2022 snap norm + shell-var)
```

---


---

## ci-tail-01-cleanup — wind down v19 transitional shims + consolidate `test-libs.sh`

**Slug**: ci-tail-01-cleanup (combines `ci-pipelines-green-tail` + `test-libs-consolidation`)
**Depends on**: `ci-pipelines-green` (v0.beta.19) — landed across all 7
  repos with the F1–F5 sweep + twelve uncovered follow-up layers as of
  meta `53456cf` / bot-lang `b6afe7c`. Both halves of this spec build
  on the same v19 work and can be picked up in any order; the resulting
  cleanup commits are file-disjoint, so there's no internal ordering
  requirement between A (shims) and B (libs).
**Files**:
  - **A — shims** (drop transitional state in workflows + runtime doc):
    - `repository/botopink-lang/.github/workflows/test.yml` (drop the
      diagnostic shim step + the `ERL_AFLAGS` env)
    - `repository/botopink-lang/modules/compiler-core/src/codegen/runtime.zig`
      (document the stdout-only contract — no behaviour change)
    - `.github/workflows/hook-integrity.yml` (drop the job-level
      `ERL_AFLAGS` env)
    - `tasks/v0.beta.19/status.md` (`ci-pipelines-green` row → **done**)
  - **B — libs consolidation** (single source for `test-libs.sh`):
    - `scripts/test-libs.sh` (delete the meta copy)
    - `scripts/AGENTS.md` (path note: wrapper lives in
      `repository/botopink-lang/scripts/test-libs.sh`)
    - every meta caller of `scripts/test-libs.sh`
  - **Both halves**:
    - `tasks/v0.beta.20/status.md` (this row reaches **done** on the closing commit)
**Status**: pending

### Problem

The `ci-pipelines-green` investigation phase landed three transitional
shims **and** an in-tree wrapper copy on `feat` that should now be
finalised:

**A — shims still in workflows + runtime:**

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
`tasks/v0.beta.19/status.md`. Once A's F1–F3 land and the workflows
go green for a full cycle, the row flips to `done`.

**B — `test-libs.sh` in two places:**

After `ci-pipelines-green`'s in-tree wrapper fix
(`build(test-libs): ship the wrapper inside botopink-lang/scripts/`),
the `scripts/test-libs.sh` file now exists in **two places**:

- `<meta>/scripts/test-libs.sh` — the legacy meta-workspace path, used
  by anyone who runs `scripts/test-libs.sh` from the meta repo root
  directly.
- `<bot-lang>/scripts/test-libs.sh` — the in-tree copy that
  `zig build test-libs` invokes via the relative `scripts/test-libs.sh`
  path (the path that the build.zig SystemCommand resolves at the
  build-root cwd).

Both copies are byte-identical at landing time. Once either is
touched, the other drifts silently — a familiar two-sources-of-truth
trap. The wrapper's content already handles both layouts
(`cd "$(git rev-parse --show-toplevel)"` + `if [ -f
repository/botopink-lang/build.zig ]; then ...`), so picking one
location and pointing every caller at it is mechanical.

### Goal

After this spec lands:

**A — shims out:**
- `botopink-lang/.github/workflows/test.yml` and meta
  `.github/workflows/hook-integrity.yml` carry **only** the production
  steps + env they need — no diagnostic shims, no transitional flags.
- `runtime.zig` carries a short prose comment on the stdout-only
  contract (the `executeErlang` body already has one — promote to a
  module-level note so future contributors don't re-introduce the
  strict-stderr check).
- `tasks/v0.beta.19/status.md`'s `ci-pipelines-green` row reads
  `done` (no `(partial)` qualifier).

**B — libs single-source:**
- `<meta>/scripts/test-libs.sh` is **deleted**.
- Every meta caller that shelled out to the meta copy now uses
  `repository/botopink-lang/scripts/test-libs.sh` (or invokes
  `zig build test-libs` which resolves to the same path internally).
- `<meta>/scripts/AGENTS.md` carries a one-line note: "test-libs.sh
  lives under `repository/botopink-lang/scripts/` — see the
  path-detection logic inside the script."

**Both:**
- `tasks/v0.beta.20/status.md` `ci-tail-01-cleanup` row reads `done`.
- The latest push on `feat` for both `botopink-lang test` and meta
  `hook-integrity` is `success`, **without** the transitional shims
  and with **one** `test-libs.sh`.

### Solution

#### A0 — verify OTP 28 closes the residual on the latest run

Passive. Wait for the CI run on the meta+bot-lang HEAD that includes
the OTP 28 bump (`erlef/setup-beam@v1` with `otp-version: '28'`).

Expected:
- `gh run list --repo botopink/botopink-lang --workflow test --branch
  feat --limit 1` → `success` (ubuntu + macos; windows allow-fail per
  `ci-tail-02-backends-parity (W half)`).
- `gh run list --repo botopink/projects --workflow hook-integrity
  --branch feat --limit 1` → `success` (all 7 matrix axes).

If still red on either: file the residual as a new gap, do **not**
proceed with A1–A3 (the shims may still be load-bearing).

#### A1 — drop the diagnostic artifact upload

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

#### A2 — drop the `ERL_AFLAGS` env

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
`env:` block (with `ERL_AFLAGS`). Re-run; if a new red surfaces
because of the drop, document what stderr it's silencing and re-add
with a precise comment.

#### A3 — document the `runtime.zig` stdout-only contract

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

#### B1 — enumerate `test-libs.sh` callers

```bash
cd <meta>
grep -rn 'scripts/test-libs.sh' . \
  --include='*.sh' --include='*.zig' --include='*.yml' \
  --include='*.md' --include='*.json' | grep -v node_modules
```

Expected hits:
- `scripts/test-libs.sh` itself (the file being deleted)
- `repository/botopink-lang/build.zig` (already uses the in-tree
  path `scripts/test-libs.sh`, resolved at bot-lang's build root —
  no change needed)
- `scripts/AGENTS.md` (doc reference, update to bot-lang path)
- `tasks/v0.beta.??/specs/recursive-test-gate.md` or sibling spec
  files (doc references; update for consistency)
- per-task TODO.md files referencing the wrapper (purely
  documentation; update on the same commit)

#### B2 — update callers + delete the meta copy

For each non-doc caller (likely zero — bot-lang's build.zig already
uses the in-tree path):
- Replace `scripts/test-libs.sh` with
  `repository/botopink-lang/scripts/test-libs.sh` (if invoked from
  meta root).

For doc callers (`.md`):
- Replace the path with
  `repository/botopink-lang/scripts/test-libs.sh` and add a sentence
  pointing at this spec.

Then `git rm scripts/test-libs.sh`.

#### B3 — update `scripts/AGENTS.md`

Add (or update) the section describing the wrapper's home:

```markdown
#### `test-libs.sh`

Lives at `repository/botopink-lang/scripts/test-libs.sh` (in-tree so
both the meta workspace layout and the standalone lib-checkout
layout resolve it via the same relative `scripts/test-libs.sh` path
inside bot-lang). The script's `cd "$(git rev-parse
--show-toplevel)"` + `if [ -f repository/botopink-lang/build.zig ];
then ...` chain detects which layout it's running under.
```

#### C — docs roll

- `tasks/v0.beta.19/status.md`: flip the `ci-pipelines-green` row to
  read `done` and update the trailing prose to reflect the closeout
  (drop the `pending F4 + F5` qualifier).
- `tasks/v0.beta.20/status.md`: this row enters `done` on the closing
  commit.

### Steps

A and B are independent — pick either order; the spec is **done** when
both close.

A — shims:
1. **A0** — wait for OTP 28 run to confirm green on both workflows (passive).
2. **A1** — single-file edit on `botopink-lang/test.yml` (drop the
   artifact step). One bot-lang commit + meta pointer bump.
3. **A2** — single-file edits on `botopink-lang/test.yml` +
   `.github/workflows/hook-integrity.yml` (drop the `ERL_AFLAGS` env).
4. **A3** — single-file docs edit on `runtime.zig`. Same commit as A2 on bot-lang.

B — libs:
1. **B1** — enumerate via `grep -rn` and record the list as a one-line audit comment.
2. **B2** — update non-doc callers (likely zero) + `git rm scripts/test-libs.sh`.
3. **B3** — update `scripts/AGENTS.md`.

C — closeout: one meta commit flipping `status.md` rows.

Each landing is a fast-forward push on `feat`; no rebase / merge
expected unless Eric advances `feat` mid-flight.

### Test scenarios

After A1: `gh run list --repo botopink/botopink-lang --workflow test
--branch feat --limit 1` reports `success`; the run summary shows
**no** `snap-diffs-*` artifacts uploaded.

After A2: same query reports `success`; the run log shows the
`zig build test` step with **no** `env:` block above it.

After A3: `git log -p modules/compiler-core/src/codegen/runtime.zig`
shows the new module-level doc-comment as the only change; the gate
runs and `zig build test` is green.

After B2+B3: `find <meta> -name test-libs.sh` returns exactly one
path: `<meta>/repository/botopink-lang/scripts/test-libs.sh`.

After B2: `zig build test-libs --target commonJS` still works from the
meta workspace root (since bot-lang's build.zig resolves the wrapper
internally).

After C: `grep -A1 'ci-pipelines-green' tasks/v0.beta.19/status.md`
shows `done`; `tasks/v0.beta.20/status.md` shows `ci-tail-01-cleanup`
`done`.

### Notes

- **Don't roll the OTP version back**. OTP 28's erlc treats the
  shadowed-BIF diagnostic as a warning where OTP 27 treated it as an
  error. The codegen test fixture is the source of truth — if a
  future OTP tightens it back to error, the fix is the codegen
  emitting `-compile({no_auto_import,…}).` (which
  `ci-tail-02-backends-parity (E half)` is authoring), not pinning a
  different OTP.
- **Don't re-introduce the strict stderr check** in `runtime.zig`.
  The strict check is what made the original residual appear in the
  first place. If a future test needs stderr in the snapshot, add a
  `executeXCapturingStderr` helper alongside (see A3 docs comment).
- **Don't symlink across the submodule boundary** for `test-libs.sh`.
  Submodule + worktree + windows + symlinks is a recipe for
  fragility — keep the wrapper as a single concrete file inside
  bot-lang.
- **Don't add a third home** for the wrapper. If someone proposes
  `install-tooling.sh` copies it into meta on first-run "for
  convenience", treat that as a regression — the in-tree path
  resolution already works in both layouts.
- **The `botopink-lang` submodule pointer is the contract.** When
  a meta clone updates submodules, it picks up the wrapper
  automatically — no extra install step needed.
- **Don't squash A1–A3 into one commit**. Each is independent and
  individually revertable. Keep them as separate per-repo commits
  with matching meta pointer bumps. B can land as a single meta
  commit (no bot-lang changes needed).

### Exit gate

This spec is **done** when, against the meta repo's `feat` branch
HEAD with all submodule pointers at their respective `feat` HEADs:

- A0 confirmed green on both `botopink-lang test` and meta
  `hook-integrity`.
- A1, A2, A3 commits all landed on `feat` (bot-lang +/or meta).
- B2 + B3 landed on `feat` (meta only).
- `<meta>/scripts/test-libs.sh` no longer exists; `find <meta> -name
  test-libs.sh` returns exactly one path inside bot-lang.
- `<meta>/scripts/AGENTS.md` carries the path note.
- A fresh clone of meta + recursive submodule init can run
  `zig build test-libs --target commonJS` from the meta root without
  any "file not found" surface.
- `tasks/v0.beta.19/status.md` `ci-pipelines-green` row reads `done`.
- `tasks/v0.beta.20/status.md` `ci-tail-01-cleanup` row reads `done`.
- A subsequent no-op push on `feat` (whitespace touch on the README)
  still turns the `test` + `hook-integrity` checks green within
  ~5 min end-to-end, with **no** transitional shims in the workflow
  logs.

---

## ci-tail-02-backends-parity — close `allow_fail` rows on erlang + windows axes

**Slug**: ci-tail-02-backends-parity (combines `backends-parity-erlang` + `backends-parity-windows`)
**Depends on**: `ci-tail-01-cleanup` (the v19 `ci-pipelines-green`
authored the `allow_fail: true` rows this spec retires; once the
v19 shims are dropped, this spec's two halves close the remaining
allow_fail rows on **erlang** and **windows-2022** axes across the
org). The two halves (E — erlang BIF shadowing; W — windows
snapshot drift + shell-var) are **independent** at the file level
and may land in either order.
**Files**:
  - **E — erlang BIF shadowing** (codegen + sibling-lib YAMLs):
    - `repository/botopink-lang/modules/compiler-core/src/codegen/erlang.zig`
      (emit `-compile({no_auto_import,[…]}).` for any user function
      whose name matches an auto-imported BIF)
    - `repository/botopink-lang/modules/compiler-core/src/codegen/beam_asm.zig`
      (parity check — the BEAM Assembly backend reads the same fixtures)
    - regenerate every `repository/botopink-lang/modules/compiler-core/
      snapshots/codegen/{erlang,beam_asm}/**/*.snap.md` that gains the
      prelude directive
    - `repository/{erika,jhonstart,onze,rakun}/.github/workflows/test.yml`
      (drop `allow_fail: true` on erlang + beam axes)
  - **W — windows-2022** (sibling-lib half + bot-lang half):
    - `repository/{erika,jhonstart,onze,rakun}/.github/workflows/test.yml`
      (shell-var fix + drop `allow_fail: true` on windows-2022 commonJS)
    - `repository/botopink-lang/.github/workflows/test.yml` (drop windows
      `allow_fail: true`)
    - `repository/botopink-lang/modules/compiler-core/src/utils/snap.zig`
      (LF + path-separator normalisation before compare)
    - regenerate every `repository/botopink-lang/modules/compiler-core/
      snapshots/codegen/wat/wasm/*.snap.md` that drifts under
      windows-2022 (audit step)
  - **Both halves**: `tasks/v0.beta.20/status.md`
**Status**: pending

### Problem

The v19 ci-pipelines-green campaign left two **`allow_fail: true`**
classes open on the lib + bot-lang CI workflows:

#### E — Erlang BIF shadowing

The codegen test fixture `if_with_else_branch` is one example, not
the only one. Several botopink test programs define functions whose
names clash with Erlang's auto-imported BIFs:

- `abs/1` (the residual that ci-pipelines-green's investigation exposed)
- `length/1`, `size/1`, `element/2`, `tuple_size/1`, … (every BIF
  listed in https://www.erlang.org/doc/man/erlang.html#auto-imported-bifs)

Newer Erlang/erlc versions (OTP 28+, possibly OTP 27 depending on
the specific BIF) treat the diagnostic `ambiguous call of overridden
pre Erlang/OTP R14 auto-imported BIF` as a **compile error**, not a
warning. The botopink-lang `runtime.zig` chain returns empty RUN LOG
on `erlc` failure → snapshot mismatch.

ci-pipelines-green pinned OTP 28 (where the diagnostic is a warning
for at least `abs/1`), but the moment another fixture introduces a
function whose shadowing is upgraded to an error, the residual
reappears. The proper fix is in the **codegen**, not in the OTP pin:

> Emit `-compile({no_auto_import,[abs/1,length/1,…]}).` in the
> generated module's prelude for every function whose name + arity
> matches an auto-imported BIF.

This is exactly the directive erlc's diagnostic message recommends:

```
use erlang:abs/1 or "-compile({no_auto_import,[abs/1]}).\" to resolve
name clash
```

The lib workflows (erika/jhonstart/onze/rakun) currently mark erlang
+ beam axes `allow_fail: true` so the workflow conclusion can be
`success`. Once the codegen emits the directive and snapshots are
regenerated, those rows go away.

#### W — Windows-2022

The windows-2022 axes carry **two unrelated reds**, both currently
masked by `allow_fail: true`:

**W.A — sibling-lib PowerShell shell-var expansion.**
`repository/{erika,jhonstart,onze,rakun}/.github/workflows/test.yml`
runs the lib-test step with:

```yaml
- name: zig build test-libs --lib ${{ env.LIB_NAME }} --target ${{ matrix.target }} (source)
  if: ${{ vars.BOTOPINK_USE_RELEASE_FASTPATH != 'true' }}
  working-directory: botopink-lang
  run: zig build test-libs -- --lib "${LIB_NAME}" --target "${{ matrix.target }}"
```

On the windows-2022 runner the default shell is `pwsh`, which does
NOT expand POSIX `${LIB_NAME}` — it treats the literal as an empty
string, so the command becomes `zig build test-libs -- --lib ""
--target "commonJS"` → `error: no lib named ''`.

Fix: pin `shell: bash` on the run step (CI already ships `bash` on
the windows-2022 image via Git for Windows).

**W.B — bot-lang `test (windows-2022)` snapshot drift.**
bot-lang's main `test` job on windows-2022 reports ~760 failing
snapshots out of ~1230. Mix of:
- **CRLF vs LF**: the snapshot framework's `compareOrCreate` (in
  `modules/compiler-core/src/utils/snap.zig`) compares byte-by-byte
  after trimming `\n\r` from the trailing whitespace, but does not
  normalise mid-content line endings.
- **Path-separator drift**: a handful of snapshots embed `/`-style
  paths in error messages or import lines; windows produces
  `\\`-style.

Fix: a normalisation layer in `snap.zig` that runs before compare,
applying `\r\n → \n` and conservatively normalising path separators
on lines that look like paths.

### Goal

After this spec lands:

- `repository/botopink-lang/.../codegen/erlang.zig` emits the
  `-compile({no_auto_import,…}).` directive in the generated module
  prelude whenever any user function shadows an auto-imported BIF.
- `codegen/beam_asm.zig` audited; either parity emit or a comment
  pointing here.
- All 4 sibling lib `test.yml` files drop their `allow_fail: true`
  rows for **erlang + beam + windows-2022** axes; workflow
  conclusion is `success` on every push.
- bot-lang's own `test` workflow goes green on the regenerated
  snapshots without re-introducing any `allow_fail` /
  `continue-on-error`.
- `tasks/v0.beta.20/status.md` `ci-tail-02-backends-parity` row
  reads `done`.

### Solution

#### E1 — extend `codegen/erlang.zig` with a BIF auto-import audit

Audit table (build it once, comptime if possible — the BIF list is
fixed per OTP release):

```
abs/1, adler32/1, adler32/2, adler32_combine/3, alias/0, alias/1,
apply/2, apply/3, atom_to_binary/1, atom_to_binary/2, atom_to_list/1,
binary_part/2, binary_part/3, binary_to_atom/1, binary_to_atom/2, …
element/2, error/1, error/2, error/3, exit/1, exit/2, float/1,
float_to_binary/1, float_to_binary/2, float_to_list/1,
float_to_list/2, garbage_collect/0, garbage_collect/1,
garbage_collect/2, get/0, get/1, get_keys/0, get_keys/1, group_leader/0,
group_leader/2, halt/0, halt/1, halt/2, hd/1, integer_to_binary/1,
integer_to_binary/2, integer_to_list/1, integer_to_list/2,
iolist_size/1, iolist_to_binary/1, iolist_to_iovec/1, is_alive/0,
is_atom/1, is_binary/1, is_bitstring/1, is_boolean/1, is_float/1,
is_function/1, is_function/2, is_integer/1, is_list/1, is_map/1,
is_map_key/2, is_number/1, is_pid/1, is_port/1, is_process_alive/1,
is_record/2, is_record/3, is_reference/1, is_tuple/1, length/1,
link/1, list_to_atom/1, list_to_binary/1, list_to_bitstring/1,
list_to_existing_atom/1, list_to_float/1, list_to_integer/1,
list_to_integer/2, list_to_pid/1, list_to_port/1, list_to_ref/1,
list_to_tuple/1, make_ref/0, map_get/2, map_size/1, max/2,
memory/0, memory/1, min/2, monitor/2, monitor/3, monitor_node/2,
monitor_node/3, node/0, node/1, nodes/0, nodes/1, nodes/2,
now/0, open_port/2, pid_to_list/1, port_close/1, port_command/2,
port_command/3, port_connect/2, port_control/3, port_info/1,
port_info/2, port_to_list/1, ports/0, pre_loaded/0, process_flag/2,
process_flag/3, process_info/1, process_info/2, processes/0,
purge_module/1, put/2, ref_to_list/1, register/2, registered/0,
round/1, self/0, send/2, send/3, send_after/3, send_after/4,
setelement/3, size/1, spawn/1, spawn/2, spawn/3, spawn/4,
spawn_link/1, spawn_link/2, spawn_link/3, spawn_link/4,
spawn_monitor/1, spawn_monitor/2, spawn_monitor/3, spawn_monitor/4,
spawn_opt/2, spawn_opt/3, spawn_opt/4, spawn_opt/5, spawn_request/1,
spawn_request/2, spawn_request/3, spawn_request/4, spawn_request/5,
spawn_request_abandon/1, split_binary/2, start_timer/3, start_timer/4,
statistics/1, term_to_binary/1, term_to_binary/2, term_to_iovec/1,
term_to_iovec/2, throw/1, time/0, tl/1, trunc/1, tuple_size/1,
tuple_to_list/1, unalias/1, unique_integer/0, unique_integer/1,
unlink/1, unregister/1, whereis/1
```

For each module that codegen emits:
1. Collect the set of `{FunctionName, Arity}` declared in the source.
2. Intersect with the BIF table above.
3. If the intersection is non-empty, prepend
   `-compile({no_auto_import,[abs/1, length/1, ...]}).` to the module
   prelude (after `-module(...).` and before `-export([...]).`).

#### E2 — `codegen/beam_asm.zig` parity

The BEAM Assembly backend goes through the same `erlc +from_asm`
pipeline. Audit the BEAM ASM emitter for the same shadowing risk; if
the same diagnostic fires (it shouldn't, since BEAM ASM compiles the
already-disambiguated assembly), add a parity check. If not, add a
comment pointing here so a future reader understands the asymmetry.

#### E3 — regenerate erlang+beam snapshots

After E1 + E2, every snapshot whose ERLANG section now carries the
`-compile({no_auto_import,…}).` line needs the recorded snapshot
updated:

```bash
cd repository/botopink-lang
for f in modules/compiler-core/snapshots/codegen/erlang/erlang/*.snap.md.new; do
  mv "$f" "${f%.new}"
done
for f in modules/compiler-core/snapshots/codegen/beam_asm/beam/*.snap.md.new; do
  mv "$f" "${f%.new}"
done
```

Commit the regen separately from the codegen change for clean review.

#### E4 — drop `allow_fail` on erlang+beam axes (4 sibling libs)

In each `repository/{erika,jhonstart,onze,rakun}/.github/workflows/test.yml`:

```yaml
- { runner: ubuntu-22.04, target: erlang,   allow_fail: true  }
- { runner: macos-14,     target: erlang,   allow_fail: true  }
```

→

```yaml
- { runner: ubuntu-22.04, target: erlang,   allow_fail: false }
- { runner: macos-14,     target: erlang,   allow_fail: false }
```

Same for beam axes. Push each lib's commit; verify the workflow goes green.

#### W1 — sibling-lib shell-var fix (4 sibling libs)

In each of `repository/{erika,jhonstart,onze,rakun}/.github/workflows/test.yml`,
update the `zig build test-libs ...` step:

```yaml
- name: zig build test-libs --lib ${{ env.LIB_NAME }} --target ${{ matrix.target }} (source)
  if: ${{ vars.BOTOPINK_USE_RELEASE_FASTPATH != 'true' }}
  working-directory: botopink-lang
  shell: bash    # <-- added
  run: zig build test-libs -- --lib "${LIB_NAME}" --target "${{ matrix.target }}"
```

Adding `shell: bash` pins the run step to bash on every runner,
including windows-2022 (via Git Bash).

#### W2 — drop `allow_fail` on windows-2022 commonJS (4 sibling libs)

After W1 confirms green:

```yaml
- { runner: windows-2022, target: commonJS, allow_fail: true  }
```

→

```yaml
- { runner: windows-2022, target: commonJS, allow_fail: false }
```

#### W3 — bot-lang `snap.zig` normalisation

In `repository/botopink-lang/modules/compiler-core/src/utils/snap.zig`,
extend `compareOrCreate` (line ~61) and `checkText` (line ~46) with
a pre-compare normalisation:

```zig
fn normalizeForCompare(allocator: std.mem.Allocator, raw: []const u8) ![]u8 {
    // 1. CRLF → LF
    var crlf_norm: std.ArrayListUnmanaged(u8) = .empty;
    var i: usize = 0;
    while (i < raw.len) : (i += 1) {
        if (i + 1 < raw.len and raw[i] == '\r' and raw[i + 1] == '\n') {
            try crlf_norm.append(allocator, '\n');
            i += 1;
        } else {
            try crlf_norm.append(allocator, raw[i]);
        }
    }
    // 2. Path separator: `\\` → `/` on lines that look like paths
    //    (contain `.bp`, `.erl`, `.js`, or known src/test prefixes).
    //    Conservative — don't munge error messages that legitimately
    //    contain `\\n`.
    // … walk lines, normalise as above …
    return crlf_norm.toOwnedSlice(allocator);
}
```

Apply to both `expected` (read from disk) and `actual` (just
captured) before the `std.mem.eql` check.

#### W4 — bot-lang wat-snapshot audit / regen

After W3, run `zig build test` once on a windows runner. Walk the
produced `.snap.md.new` files; any that don't match the recorded
snapshot indicate either:
- the normalisation isn't catching some path-separator case → tighten
  the heuristic, or
- the snapshot itself was recorded on a CRLF host and needs to be
  rewritten in LF.

Commit the regen as a separate bot-lang commit.

#### W5 — bot-lang drop windows `allow_fail`

In `repository/botopink-lang/.github/workflows/test.yml`:

```yaml
- runner: windows-2022
  allow_fail: true
```

→

```yaml
- runner: windows-2022
  allow_fail: false
```

(or drop the matrix-include shape if every entry is now `false`,
returning to the simple list form ci-pipelines-green inherited.)

#### C — closeout (one meta commit)

One meta commit advances all five submodule pointers (bot-lang +
4 sibling libs) + flips this set's row in
`tasks/v0.beta.20/status.md` to `done`.

### Steps

E and W are **independent** — pick either order. W.A (sibling shell-var)
is the smallest single-edit fastest path; lands first if you want CI
green at maximum speed.

E — erlang BIF shadowing:
1. **E1** — `codegen/erlang.zig` change in bot-lang.
2. **E2** — `codegen/beam_asm.zig` parity check in the same bot-lang commit.
3. **E3** — snapshot regen as a separate bot-lang commit.
4. **E4** — four sibling lib commits, one per repo, dropping the
   erlang + beam `allow_fail` rows.

W — windows-2022:
1. **W1** — four sibling lib commits adding `shell: bash`.
2. **W2** — four sibling lib commits dropping windows-2022 commonJS
   `allow_fail` (after W1 confirms green).
3. **W3** — bot-lang `snap.zig` normalisation: pure source change.
4. **W4** — windows-runner regen sweep (temporary diagnostic shim
   to upload `.snap.md.new`).
5. **W5** — bot-lang drop windows `allow_fail`.

C — closeout: one meta commit bumping 5 submodule pointers + flipping
row in `status.md`.

### Test scenarios

After E1+E3 + E4 land per lib: `gh run list --repo botopink/<lib>
--workflow test --branch feat --limit 1` shows `success`, with the
erlang + beam axes contributing green and no `allow_fail` rows.

After E4 lands on bot-lang: `gh run list --repo botopink/botopink-lang
--workflow test --branch feat --limit 1` shows `success`; the
`codegen/erlang/erlang/if_with_else_branch.snap.md` (and siblings)
carry the new prelude line where applicable.

After W1+W2 lands per lib: `gh run list --repo botopink/<lib>
--workflow test --branch feat --limit 1` reports `success`, with the
windows-2022 commonJS axis green and no `allow_fail` row.

After W3+W4+W5: `gh run list --repo botopink/botopink-lang --workflow
test --branch feat --limit 1` reports `success`, with the windows-2022
axis green and no `continue-on-error`.

After C: `grep -A1 'ci-tail-02-backends-parity'
tasks/v0.beta.20/status.md` shows `done`.

### Notes

- **OTP version is now decoupled from this spec** (E). Once the
  codegen emits the directive, the residual is closed regardless of
  how strict the host's `erlc` is. `ci-tail-01-cleanup`'s A0 still
  verifies the current OTP 28 pin holds; this spec makes the codegen
  forward-compatible to OTP 29, 30, … .
- **The auto-imported BIF list drifts across OTP releases.** When
  generating the table, prefer comptime introspection
  (`erlang:get_module_info(erlang, exports)`) over a hardcoded list —
  the latter rots silently.
- **Don't emit the directive unconditionally.** Modules with no
  shadowing functions should not carry the line — keeps the
  generated code minimal and the snapshot diffs small.
- **Don't normalise paths inside error messages** (W). The `snap.zig`
  normalisation must be conservative — replacing `\\` with `/`
  unconditionally would break any snapshot that legitimately captures
  a regex pattern like `\\.bp`. The heuristic fires only on lines
  that contain a file extension marker.
- **`shell: bash` on windows-2022 uses Git Bash**, which ships with
  the windows-2022 image. No additional install step needed.

### Exit gate

This spec is **done** when, against `feat` HEAD across all repos:

- E1+E2 (codegen emit) + E3 (snapshot regen) on
  `repository/botopink-lang` `feat` without any allow_fail re-introduction.
- W3 (snap.zig normalisation) + W4 (regen) + W5 (drop windows allow_fail)
  on bot-lang `feat`.
- Each of `repository/{erika,jhonstart,onze,rakun}` `feat` carries
  E4 (erlang + beam allow_fail removed) + W1 (`shell: bash`) + W2
  (windows-2022 commonJS allow_fail removed).
- meta `feat` carries the pointer bumps + `status.md` row → `done`.
- Every affected `gh run list` reports `success` on the latest push,
  with **zero** `allow_fail: true` rows in any of the 5 workflow YAMLs.

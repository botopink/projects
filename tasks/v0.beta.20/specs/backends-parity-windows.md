# backends-parity-windows — close the windows-2022 reds across the org

**Slug**: backends-parity-windows
**Depends on**: ci-pipelines-green (the windows allow_fail rows in each
sibling lib's test.yml + bot-lang's `test (windows-2022)` matrix entry
were authored there).
**Files**:
  - **sibling-lib half** (independent of the bot-lang half):
    - `repository/erika/.github/workflows/test.yml`
    - `repository/jhonstart/.github/workflows/test.yml`
    - `repository/onze/.github/workflows/test.yml`
    - `repository/rakun/.github/workflows/test.yml`
  - **bot-lang half** (the heavier surface):
    - `repository/botopink-lang/.github/workflows/test.yml`
    - `repository/botopink-lang/modules/compiler-core/src/utils/snap.zig`
      (LF + path-separator normalisation before compare)
    - regenerate every `repository/botopink-lang/modules/compiler-core/
      snapshots/codegen/wat/wasm/*.snap.md` (windows-2022 reports
      CRLF differences here too, not just the parser tests) — audit
      via a single `zig build test` on a windows runner once the
      normalisation lands.
**Touches docs**: `tasks/v0.beta.20/status.md`
**Status**: pending

## Problem

The windows-2022 axes carry **two unrelated reds**, both inherited as
`allow_fail: true` markers by ci-pipelines-green:

### Half A — sibling-lib PowerShell shell-var expansion

`repository/{erika,jhonstart,onze,rakun}/.github/workflows/test.yml`
runs the lib-test step with:

```yaml
- name: zig build test-libs --lib ${{ env.LIB_NAME }} --target ${{ matrix.target }} (source)
  if: ${{ vars.BOTOPINK_USE_RELEASE_FASTPATH != 'true' }}
  working-directory: botopink-lang
  run: zig build test-libs -- --lib "${LIB_NAME}" --target "${{ matrix.target }}"
```

On the windows-2022 runner, the default shell is `pwsh` (PowerShell
Core), which does NOT expand POSIX `${LIB_NAME}` — it treats the
literal as an empty string. The actual command becomes:

```
zig build test-libs -- --lib "" --target "commonJS"
```

→ `error: no lib named '' found across the library roots`.

The fix is either:
- pin `shell: bash` on the run step (works everywhere; CI already
  has `bash` on the windows-2022 image via `Git for Windows`), or
- replace the inline `${LIB_NAME}` reference with the GH Actions
  `${{ env.LIB_NAME }}` expansion (resolved at job parse time, not
  shell-time).

### Half B — bot-lang `test (windows-2022)` snapshot drift

bot-lang's main `test` job on windows-2022 reports 763 failing
snapshots out of 1230. The cause is a mix of:
- **CRLF vs LF**: the snapshot framework's `compareOrCreate` (in
  `modules/compiler-core/src/utils/snap.zig`) compares byte-by-byte
  after trimming `\n\r` from the trailing whitespace, but does not
  normalise mid-content line endings. A file that was recorded on a
  LF host but captured on a CRLF host fails.
- **Path-separator drift**: a handful of snapshots embed `/`-style
  paths in error messages or import lines; windows produces
  `\\`-style.

`backends-parity-windows` adds a normalisation layer to `snap.zig`
that runs before compare:
1. Replace `\r\n` with `\n` in both expected and actual.
2. Replace path separators in any line that *looks like* a path
   (heuristic: lines containing `.bp` or `.erl` or `.js` extensions).

Snapshots that need re-recording on windows after the normalisation
lands are an explicit audit step.

## Goal

After this spec lands:

- Each sibling lib's `windows-2022 · commonJS` axis goes green; the
  workflow's `allow_fail: true` row for windows-2022 is dropped.
- bot-lang's `test (windows-2022)` axis goes green; the matrix entry
  drops `allow_fail: true` and the `continue-on-error` job-level
  setting.
- `tasks/v0.beta.20/status.md` `backends-parity-windows` row reads
  `done`.

## Solution

### F1 — sibling-lib shell-var fix (half A)

In each of `repository/{erika,jhonstart,onze,rakun}/.github/workflows/test.yml`,
update the `zig build test-libs ...` step (and any sibling step that
references `${LIB_NAME}`):

```yaml
- name: zig build test-libs --lib ${{ env.LIB_NAME }} --target ${{ matrix.target }} (source)
  if: ${{ vars.BOTOPINK_USE_RELEASE_FASTPATH != 'true' }}
  working-directory: botopink-lang
  shell: bash
  run: zig build test-libs -- --lib "${LIB_NAME}" --target "${{ matrix.target }}"
```

Adding `shell: bash` pins the run step to bash on every runner,
including windows-2022 (via Git Bash). The inline `${LIB_NAME}`
expansion now resolves at shell parse time, not pwsh.

### F2 — drop the windows allow_fail row on each sibling lib

Once F1 confirms windows-2022 commonJS goes green, replace:

```yaml
- { runner: windows-2022, target: commonJS, allow_fail: true  }
```

with:

```yaml
- { runner: windows-2022, target: commonJS, allow_fail: false }
```

(Or remove the matrix-level `continue-on-error` entirely if every row
now reads `false`.)

### F3 — bot-lang `snap.zig` normalisation (half B)

In `repository/botopink-lang/modules/compiler-core/src/utils/snap.zig`,
extend `compareOrCreate` (line ~61) and `checkText` (line ~46) with a
pre-compare normalisation:

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
    //    Keep this conservative — don't munge error messages that
    //    legitimately contain `\\n`.
    // … walk lines, normalise as above …
    return crlf_norm.toOwnedSlice(allocator);
}
```

Apply to both `expected` (read from disk) and `actual` (just
captured) before the `std.mem.eql` check.

### F4 — bot-lang snapshot audit / regen

After F3, run `zig build test` once on a windows runner (via the
workflow's diagnostic shim if needed — re-add the artifact upload
temporarily). Walk the produced `.snap.md.new` files; any that don't
match the recorded snapshot indicate either:
- the normalisation isn't catching some path-separator case → tighten
  the heuristic, or
- the snapshot itself was recorded on a CRLF host and needs to be
  rewritten in LF.

Commit the regen as a separate bot-lang commit.

### F5 — bot-lang drop windows allow_fail

In `repository/botopink-lang/.github/workflows/test.yml`'s main `test`
job matrix:

```yaml
- runner: windows-2022
  allow_fail: true
```

→

```yaml
- runner: windows-2022
  allow_fail: false
```

(or drop the entire matrix-include shape if every entry is now
`false`, returning to the simple list form ci-pipelines-green
inherited.)

### F6 — docs roll

`tasks/v0.beta.20/status.md` `backends-parity-windows` row → `done`.

## Steps

1. **F1** — sibling-lib shell-var fix lands across 4 repos in one
   sweep (file-disjoint, no risk of merge conflict).
2. **F2** — after CI confirms F1 goes green on windows-2022 commonJS,
   drop the allow_fail rows in a follow-up sweep on the same 4 repos.
3. **F3** — bot-lang `snap.zig` normalisation: pure source change,
   commit + push. zig build test gates on Linux locally, so any
   regression there is caught at commit.
4. **F4** — windows-runner regen sweep: push a temporary diagnostic
   shim to upload the `.snap.md.new` files, download, audit, regen
   the snapshots that need it, push the regen.
5. **F5** — bot-lang `test (windows-2022)` allow_fail drop.
6. **F6** — meta commit bumping 5 submodule pointers + closing row
   in `status.md`.

## Test scenarios

- After F1+F2 lands per lib: `gh run list --repo botopink/<lib>
  --workflow test --branch feat --limit 1` reports `success`, with
  the windows-2022 commonJS axis green and no allow_fail row.
- After F3+F4+F5 lands: `gh run list --repo botopink/botopink-lang
  --workflow test --branch feat --limit 1` reports `success`, with
  the windows-2022 axis green and no continue-on-error.

## Notes

- **The two halves are independent.** Half A (sibling-lib shell-var)
  is one-line edits across 4 repos and lands fast. Half B (bot-lang
  windows snapshot drift) is heavier — it's safe to land Half A first
  and let Half B follow on its own cadence.
- **Don't normalise paths inside error messages.** The `snap.zig`
  normalisation must be conservative — replacing `\\` with `/`
  unconditionally would break any snapshot that legitimately captures
  a regex pattern like `\\.bp`. The heuristic in F3 only fires on
  lines that contain a file extension marker.
- **`shell: bash` on windows-2022 uses Git Bash**, which ships with
  the windows-2022 image. No additional install step needed.

## Exit gate

This spec is **done** when:

- Each sibling lib `test` workflow reports `success` on `feat` with
  no `allow_fail: true` rows.
- bot-lang's `test` workflow reports `success` on `feat` with no
  `continue-on-error` carve-outs.
- meta `tasks/v0.beta.20/status.md` `backends-parity-windows` row
  reads `done`.

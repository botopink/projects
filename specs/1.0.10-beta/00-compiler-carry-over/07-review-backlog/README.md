# Front 07 — review-backlog

**Priority:** medium — nothing ships wrong because of it, but the open rows of the 1.0.1-beta
snapshot review sit between the suite and "every snapshot proves what its test claims", and a row that
names a compiler defect must reach the front that owns the file
**Depends on:** wave A — [`01-checker`](../01-checker/README.md) and the backend front that owns each
column ([`02-erlang`](../02-erlang/README.md), [`03-beam`](../03-beam/README.md),
[`04-js`](../04-js/README.md), [`05-wasm`](../05-wasm/README.md)). Wave B —
[`06-comptime-dedup`](../../../1.0.5-beta/06-comptime-dedup/README.md) steps 1 and 2, both landed
**Owns:** `src/utils/snap.zig` · `scripts/snap_audit.sh` (+ its `scripts/AGENTS.md` section) ·
`src/codegen/tests/**` · `src/comptime/tests/**` **except** `helpers.zig` · `src/parser/tests/**` ·
`modules/language-server/src/tests/**` · the per-report status lines in
[`../../1.0.1-beta/06-snapshot-review/`](../../../1.0.1-beta/06-snapshot-review/)
**Does not touch:** any lowering (02–05), the checker and parser sources (01),
`comptime/snapshot.zig`, `libs/std/**`, `modules/language-server/src/**` outside `src/tests/`
([`11-tooling`](../11-tooling/README.md)). A `wrong-output` row that needs one of these is
**registered** in the owning front's README with its snapshot name, not fixed here.

Paths are relative to `repository/botopink-lang/modules/compiler-core/`, except those starting with
`scripts/` or `modules/`, which are relative to `repository/botopink-lang/`. Report citations
(`codegen-features.md:85`) are lines in the 1.0.1-beta review reports. Carry-over item: C-22 — see
[`../README.md`](../README.md).

---

## What exists

- **Orphan detection.** `BOTOPINK_SNAP_TRACE=<file>` at both `compareOrCreate` choke points
  (append-safe), test helpers carrying `@src()` into the trace, `scripts/snap_audit.sh --mode=orphans`.
- **Review worksheet.** `scripts/snap_audit.sh --mode=review` emits one TSV row per unique snapshot
  with its test `file:line` and a verdict seeded from the reports by header cell.
- **The snapshot layout.** `snapshots/codegen/<runtime>/<target>/` — the codegen suite recorded under
  both comptime runtimes (`beam`, `wat`) and checked equal by `snap_audit.sh --mode=runtime-parity`;
  `snapshots/comptime/{ast,errors,runtime,templates}/` — one copy per test since 06 step 1;
  `snapshots/parser/`; `modules/language-server/snapshots/lsp/`. A test rename in
  `src/codegen/tests/**` moves one file per target in each runtime tree; anywhere else, one.
- **The decisions the rows waited on** — decisions 1–5 and decision 8 of 1.0.4-beta. No row in this
  front reopens one.
- **Reports closed or worked:** 3.11 `parser.md` (closed), 3.12 `lsp.md` (closed — its last two rows
  under step 3), 3.3 `codegen-wat-narrowing.md` and 3.6 `codegen-comptime-misc.md` (test fixes landed,
  `wrong-output` rows registered).

## The reports

| Batch | Report | Open rows (1.0.2-beta re-derivation) | Wave |
|---|---|---|---|
| 3.1 | `codegen-features.md` | 168 | A |
| 3.2 | `codegen-control_flow.md` | 87 | A |
| 3.4 | `codegen-values-dispatch-externals.md` | 99 | A |
| 3.5 | `codegen-builtins-aggregates.md` | 66 | A |
| 3.3 | `codegen-wat-narrowing.md` | worked; `:70` left | A |
| 3.6 | `codegen-comptime-misc.md` | worked; registered rows close with their fronts | — |
| 3.7 | `comptime-errors-effects.md` | 48 | B |
| 3.8 | `comptime-decls-variants.md` | 59 | B |
| 3.9 | `comptime-templates-types-exprs.md` | 40 | B |
| 3.10 | `comptime-generics-effects-decorators.md` | 78 | B |

Every report carries a `**Status (1.0.1-beta close)**` block telling the reader to re-derive each row
at HEAD; that block is not the status line steps 1 and 2 append. The rows cite a corpus that has moved
under them — re-derive, never trust a cited line.

## Rows handed over by front 06

- **`scripts/snap_audit.sh`'s per-backend comptime arm** was dead after 06's layout change; remove
  it if it is still there. The classifier today reads `codegen/<runtime>/<target>` and
  `comptime/<dir>` (step 5).
- **`src/comptime/tests/infer_decls.zig`'s `"infer: implement block is invisible to the binding
  list"`** names a behaviour that is gone: `implement` blocks appear now, read from
  `OkData.transformed.decls`. Renaming the test renames its snapshot slug.

## Steps

### Step 1 — wave A: the codegen reports (3.1, 3.2, 3.4, 3.5, and 3.3's `:70`)

After [`01-checker`](../01-checker/README.md) and the backend front that owns the column. **Split by
backend**: a report's `erlang` column can be re-derived once [`02-erlang`](../02-erlang/README.md)'s
rows have landed, without waiting for [`05-wasm`](../05-wasm/README.md). A row with cells in several
columns waits for the last of them.

For every non-`ok` row: re-derive it at HEAD — many closed with the backend fronts, and the decisions
turn the `uncertain` rows into ordinary verdicts — then fix the test (`wrong-test`, `weak`,
`duplicate`, `skip-undocumented`) or register the `wrong-output` in the owning front's README with its
snapshot name.

The tests named *"lowers byte-identically across backends"* are named by decision 1: they either
hold, or carry the name the decision implies.

**Acceptance (per report):**
- [ ] Every non-`ok` row re-derived at HEAD and closed: fixed, registered with the snapshot name in
      the owning front's README, or struck with a written reason
- [ ] The two stale beam `null` rows struck (`codegen-control_flow.md:196`, the `{atom,nil}` half of
      `codegen-features.md:211`)
- [ ] A status line appended to the report naming the commit that closed it and which columns it
      covers
- [ ] `scripts/snap_audit.sh --mode=review` re-run after the batch: every row the report struck is
      `ok` or absent from the worksheet's seeded verdicts

### Step 2 — wave B: the comptime reports (3.7–3.10)

After [`01-checker`](../01-checker/README.md) (the shared root causes land once). 06 step 2 renders
the inferred types and removed the `id` field, so a row graded `weak` for "the JSON does not show the
type" is gradeable now — many become `ok` or a real `wrong-output` with no test change.

The batches whose `wrong-output` rows land in `comptime/infer.zig` conflict with each other: one
worker, one batch at a time.

**Acceptance:** as step 1, per report, plus:
- [ ] No test rename in `src/comptime/tests/**` landed before 06 step 1 (checked by the commit order)

### Step 3 — the questions no decision answers

The `uncertain` rows no decision answers each get an answer or are carried forward **by name**. Closed
already: `lsp.md:104` `completion_decorator_record` (C-19: `PostService  [Struct]  detail: type
PostService(name: string, count: i32)`, pinned with `completion_type_enum_detail` /
`completion_behavior_detail`) and `lsp.md:103` `hover_interface_method` (the footer names the
declaring behavior).

**Acceptance:**
- [ ] Each remaining row answered in its report, or listed by name in the next milestone
- [ ] No row is carried as "uncertain" without a named owner or a written reason

### Step 4 — the two mis-named `externals.zig` tests

`src/codegen/tests/externals.zig` has two tests named for an equivalence the compiler does not
implement:

```zig
test "js: External.<Target> ---- template equivalent to @external(target, template)" {
test "js: External.<Target> ---- mixed with @external() in one decl" {
```

Both bodies use `#[@External.Erlang(…), @External.Node(…)]` only; the comment above them already says
"The enum-variant form … is the only form."

**Acceptance:**
- [ ] Both tests carry a name that describes what they assert; their snapshot files (one per target
      in each runtime tree) are renamed in the same commit (`git mv`), contents byte-identical
- [ ] `scripts/snap_audit.sh --mode=orphans` after the rename: 0 orphans, 0 unrecorded
- [ ] Sequenced after [`04-js`](../04-js/README.md), [`02-erlang`](../02-erlang/README.md),
      [`03-beam`](../03-beam/README.md) and [`05-wasm`](../05-wasm/README.md) have landed — the
      snapshot directories are theirs

### Step 5 — `snap_audit.sh` follows the comptime layout

06 step 1 replaced `comptime/{node,erlang,beam,wasm}/` with one copy per test; the classifier's arm
that collapsed the four copies into one review row can match nothing.

**Acceptance:**
- [ ] The classifier reads `ast/` and `errors/`; `--mode=review` labels every comptime row
- [ ] `--mode=legacy`, `--mode=orphans`, `--mode=coverage` give the same counts as before the layout
      change for every non-comptime family
- [ ] `scripts/AGENTS.md`'s `snap_audit.sh` section names the new layout
- [ ] Landed **with** 06 step 1, not after it — the two commits are one landing, or 06 takes this edit
      as a named carve-out

## Gate

- [ ] `scripts/gate.sh --cold` green in this front's worktree
- [ ] A traced run (`BOTOPINK_SNAP_TRACE`) after each batch: 0 orphans, traced = on disk
- [ ] Warm re-run: same pass count, 0 leaks, 0 `.snap.md.new`
- [ ] `AGENTS.md` of the snapshot-producing directories updated in the same commit as a test rename
      or deletion
- [ ] Commit on a branch; no push, no merge — landing is the maintainer's step

## Notes

- **Nothing here changes emitted output.** A row that would is registered in the owning front, not
  fixed. This front moves a snapshot only by renaming its test.
- The reports' tables are the audit record and are not edited, except for the status line per report
  and the strikes step 1 asks for.
- The three copies of `slugify`/`slugFromSrc` (`codegen/tests/helpers.zig`,
  `comptime/tests/helpers.zig`, `parser/tests/helpers.zig`) are not merged: the `": "` truncation is a
  behaviour every snapshot name depends on, and changing it renames hundreds of files. Not in this
  milestone unless the maintainer adds it.
- The content-identical comptime error pairs listed in
  [`06-comptime-dedup`](../../../1.0.5-beta/06-comptime-dedup/README.md#current-state) are `duplicate`
  rows of this front; deduplicating them is a rename — wave B.
- Stale comments in this front's own test files are [`08-hygiene`](../08-hygiene/README.md)'s sweep,
  handed here or landed after: `codegen/tests/builtins.zig:382` still says commonJS lowers `assert` to
  `console.assert` (decision 4 is implemented on all four backends), and
  `codegen/tests/control_flow.zig:73,76`, `codegen/tests/narrowing.zig:105` and
  `codegen/tests/wat.zig:86` cite the
  retired front numbers `06-wasm` and `07-checker`.

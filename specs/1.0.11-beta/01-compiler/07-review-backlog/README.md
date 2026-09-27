# Front 07 — review-backlog

**Priority:** low — nothing ships wrong because of it, but the open rows of the 1.0.1-beta snapshot
review sit between the suite and "every snapshot proves what its test claims", and a row that
names a compiler defect must reach the front that owns the file. Never opened in 1.0.5 or 1.0.10
(C-22, all boxes unticked).
**Depends on:** `02-erlang`, `03-beam`, `04-js`, `05-wasm` landed (step 4 renames in their snapshot
directories; wave A's columns are re-derived against their output) · `01-checker` landed (wave B's
shared root causes) · `00-gate` (nothing of this front's files is a gate item).
**Owns:** `modules/compiler-core/src/utils/snap.zig` · `scripts/snap_audit.sh` (and its
`scripts/AGENTS.md` section) · `src/codegen/tests/**` (the test sources; a backend front's
fixtures are its carve-out while it runs) · `src/comptime/tests/**` except `helpers.zig` ·
`src/parser/tests/**` · `modules/language-server/src/tests/**` · the per-report status lines in
`specs/1.0.1-beta/06-snapshot-review/` · snapshot **renames** only (`git mv`, byte-identical)
**Does not touch:** any lowering (02–05), the checker and parser sources (01), `comptime/snapshot.zig`,
`codegen/snapshot.zig` (18), `libs/std/**`, `modules/language-server/src/**` outside `src/tests/`
(26). A `wrong-output` row that needs one of these is **registered** in the owning front's README
with its snapshot name, not fixed here.

Paths are relative to `repository/botopink-lang/modules/compiler-core/`, except those starting with
`scripts/` or `modules/`, which are relative to `repository/botopink-lang/`. Report citations
(`codegen-features.md:85`) are lines in the 1.0.1-beta review reports.

## Carried from 1.0.10

| Item | 1.0.10 spec | Heading |
|---|---|---|
| C-22 whole | `07-review-backlog/README.md` · `00/README.md` | every step · § C-22 |
| the `infer_decls.zig` rename | `07-review-backlog/README.md` | § Rows handed over by front 06 |
| the comment sites in these files | `08-hygiene/README.md` | § Open, items 2 and 3 (the `C-22` rows of its ownership table) |

## What exists

- **Orphan detection.** `BOTOPINK_SNAP_TRACE=<file>` at both `compareOrCreate` choke points
  (append-safe), test helpers carrying `@src()` into the trace, `scripts/snap_audit.sh --mode=orphans`.
- **Review worksheet.** `scripts/snap_audit.sh --mode=review` emits one TSV row per unique snapshot
  with its test `file:line` and a verdict seeded from the reports by header cell.
- **The snapshot layout.** `snapshots/codegen/<runtime>/<target>/` — the codegen suite recorded under
  both comptime runtimes (`beam`, `wat`) and checked equal by `snap_audit.sh --mode=runtime-parity`;
  `snapshots/comptime/{ast,errors,runtime,templates}/` — one copy per test; `snapshots/parser/`;
  `modules/language-server/snapshots/lsp/`. A test rename in `src/codegen/tests/**` moves one file
  per target in each runtime tree; anywhere else, one. The classifier reads `codegen/<runtime>/<target>`
  and `comptime/<dir>` (`scripts/snap_audit.sh:42,54` at HEAD) — 1.0.10's step 5 holds.
- **The decisions the rows waited on** — decisions 1–5 and decision 8 of 1.0.4-beta, and decision
  8's run-time tails as 02–05 land them in this milestone. No row here reopens one.
- **Reports closed or worked:** 3.11 `parser.md` (closed), 3.12 `lsp.md` (closed — its last two rows
  closed by C-19), 3.3 `codegen-wat-narrowing.md` and 3.6 `codegen-comptime-misc.md` (test fixes
  landed, `wrong-output` rows registered). Every other report is untouched since 1.0.2-beta's
  re-derivation.

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
under them twice since — re-derive, never trust a cited line.

## Steps

### Step 1 — wave A: the codegen reports (3.1, 3.2, 3.4, 3.5, and 3.3's `:70`)

After the backend front that owns each column has landed. **Split by backend**: a report's `erlang`
column can be re-derived once 02's rows have landed, without waiting for 05. A row with cells in
several columns waits for the last of them.

For every non-`ok` row: re-derive it at HEAD — many closed with the backend fronts, and the decisions
turn the `uncertain` rows into ordinary verdicts — then fix the test (`wrong-test`, `weak`,
`duplicate`, `skip-undocumented`) or register the `wrong-output` in the owning front's README with its
snapshot name.

The tests named *"lowers byte-identically across backends"* are named by decision 1: they either
hold, or carry the name the decision implies.

**Acceptance (per report):**
- [ ] every non-`ok` row re-derived at HEAD and closed: fixed, registered with the snapshot name in the owning front's README, or struck with a written reason
- [ ] the two stale beam `null` rows struck (`codegen-control_flow.md:196`, the `{atom,nil}` half of `codegen-features.md:211`)
- [ ] a status line appended to the report naming which columns it covers and the date of the re-derivation (no commit hash — the report's own git history carries it)
- [ ] `scripts/snap_audit.sh --mode=review` re-run after the batch: every row the report struck is `ok` or absent from the worksheet's seeded verdicts

### Step 2 — wave B: the comptime reports (3.7–3.10)

After `01-checker` (the shared root causes land once). The comptime snapshots render the inferred
types (06 step 2 of 1.0.5), so a row graded `weak` for "the JSON does not show the type" is
gradeable now — many become `ok` or a real `wrong-output` with no test change.

The batches whose `wrong-output` rows land in `comptime/infer.zig` conflict with each other: one
worker, one batch at a time.

**Acceptance:** as step 1, per report, plus:
- [ ] no test rename in `src/comptime/tests/**` breaks a `comptime/errors/` pair (the content-identical error pairs are `duplicate` rows — deduplicating one is a rename)

### Step 3 — the questions no decision answers

The `uncertain` rows no decision answers each get an answer or are carried forward **by name**.
Closed already: `lsp.md:104` `completion_decorator_record` (C-19) and `lsp.md:103`
`hover_interface_method`.

**Acceptance:**
- [ ] each remaining row answered in its report, or listed by name in the next milestone
- [ ] no row is carried as "uncertain" without a named owner or a written reason

### Step 4 — the two mis-named `externals.zig` tests, and `infer_decls.zig:147`

`src/codegen/tests/externals.zig:55` and `:67` (at HEAD) are named for an equivalence the compiler
does not implement (`template equivalent to @external(target, template)`, `mixed with @external()
in one decl`); both bodies use `#[@External.Erlang(…), @External.Node(…)]` only.
`src/comptime/tests/infer_decls.zig:147` `"infer: implement block is invisible to the binding
list"` names a behaviour that is gone: `implement` blocks appear, read from
`OkData.transformed.decls`.

**Acceptance:**
- [ ] the three tests carry names that describe what they assert; their snapshot files (one per target in each runtime tree for the two codegen ones; one for the comptime one) renamed in the same commit by `git mv`, contents byte-identical
- [ ] `scripts/snap_audit.sh --mode=orphans` after the rename: 0 orphans, 0 unrecorded
- [ ] sequenced after 02, 03, 04, 05 have landed — the snapshot directories are theirs

### Step 5 — the comment sites in these files (08 items 2–3)

`codegen/tests/control_flow.zig:73` ("pinned, 06-wasm" — `05-wasm`), `:76` ("07-checker's to land"
— landed), `narrowing.zig:90` ("registered with 07-checker" — landed), `builtins.zig:365` (commonJS
"still lowers to `console.assert`" — decision 4 is implemented on all four backends);
`comptime/tests/std_target_gating.zig:6`, `infer_errors.zig:455` and
`language-server/src/tests/hover.zig:304` (the retired `@external(<target>, …)` form taught as
current, and the `primitives.d.bp` mention). Re-measure each line at the step's open; the numbers
drift.

**Acceptance:**
- [ ] `grep -rn '06-wasm\|07-checker\|F7 checker' src/` returns nothing; no comment in `src/codegen/tests/**` describes a lowering the backends have changed; 08 verifies its items 2–3

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in this front's worktree
- [ ] a traced run (`BOTOPINK_SNAP_TRACE`) after each batch: 0 orphans, traced = on disk
- [ ] warm re-run: same pass count, 0 leaks, 0 `.snap.md.new`
- [ ] `scripts/snap_audit.sh --mode=runtime-parity` green after every rename (a rename moves both runtime trees)
- [ ] `AGENTS.md` of the snapshot-producing directories updated in the same commit as a test rename or deletion; `scripts/AGENTS.md`'s `snap_audit.sh` section current
- [ ] Commit on `fix/07-review-backlog`; no push, no merge

## Blast radius

None on emitted output. Renames move files in every runtime tree (two per codegen test per
target); nothing else. A `wrong-output` found here lands in the owning front's README as a row,
which may reopen a landed front — that is the point.

## Notes

- **Nothing here changes emitted output.** A row that would is registered in the owning front, not
  fixed. This front moves a snapshot only by renaming its test.
- The reports' tables are the audit record and are not edited, except for the status line per
  report and the strikes step 1 asks for.
- The three copies of `slugify`/`slugFromSrc` (`codegen/tests/helpers.zig`,
  `comptime/tests/helpers.zig`, `parser/tests/helpers.zig`) are not merged: the `": "` truncation
  is a behaviour every snapshot name depends on, and changing it renames hundreds of files.
- Wave A's commonJS and wasm columns are re-derivable at the open; erlang and beam after 02 and 03
  land their C-07 tails.

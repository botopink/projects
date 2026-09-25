# Front 07 — review-backlog

**Priority:** medium — nothing ships wrong because of it, but ~700 open review rows sit between the
suite and "every snapshot proves what its test claims", and a row that names a compiler defect must
reach the front that owns the file **before that front closes**. This milestone is the last one in
which the erlang, beam, js and wasm fronts are open.
**Depends on:** wave A — [`02-erlang`](../02-erlang/README.md), [`03-beam`](../03-beam/README.md),
[`04-js`](../04-js/README.md), [`05-wasm`](../05-wasm/README.md) and
[`01-checker`](../01-checker/README.md) landed (all five re-record the codegen snapshots its rows
cite). Wave B — [`06-comptime-dedup`](../../../1.0.5-beta/06-comptime-dedup/README.md) step 2 landed, and step 1
before any test rename in `src/comptime/tests/**`
**Owns:** `src/utils/snap.zig` · `scripts/snap_audit.sh` (+ its `scripts/AGENTS.md` section) ·
`src/codegen/tests/**` · `src/comptime/tests/**` **except** `helpers.zig`
([`06-comptime-dedup`](../../../1.0.5-beta/06-comptime-dedup/README.md)) · `src/parser/tests/**` ·
`modules/language-server/src/tests/**` · the per-report status lines in
[`../../1.0.1-beta/06-snapshot-review/`](../../../1.0.1-beta/06-snapshot-review/)
**Does not touch:** any lowering (02–05), the checker and parser sources (01), `comptime/snapshot.zig`
(06), `libs/std/**`, `modules/language-server/src/**` outside `src/tests/`
([`11-tooling`](../11-tooling/README.md)). A `wrong-output` row that needs one of these is
**registered** in the owning front's README with its snapshot name, not fixed here.

Paths are relative to `repository/botopink-lang/modules/compiler-core/`, except those starting with
`scripts/` or `modules/`, which are relative to `repository/botopink-lang/`. Report citations
(`codegen-features.md:85`) are lines in the 1.0.1-beta review reports. Measured at `c2dd780`.

---

## Delivered before this front

- **Orphan detection.** `BOTOPINK_SNAP_TRACE=<file>` at both `compareOrCreate` choke points
  (append-safe), test helpers carrying `@src()` into the trace,
  `scripts/snap_audit.sh --mode=orphans`. The traced run at 1.0.2-beta: 2451 snapshots on disk = 2451
  traced, **0 orphans**.
- **Review worksheet.** `scripts/snap_audit.sh --mode=review` emits one TSV row per unique snapshot
  with its test `file:line` and a verdict seeded from the reports by header cell. Its path classifier
  collapses the four comptime runtime copies into one row (`:499-501`).
- **The decisions the rows waited on.** Decisions 1–5 (2026-09-16) and
  [decision 8](../../../1.0.4-beta/08-review-backlog/decision-8-language.md) (2026-09-17, superseding
  1a, 6 and 7). No row in this front reopens one.
- **Four reports closed or worked:** 3.11 `parser.md` (one duplicate set deleted), 3.12 `lsp.md`
  (closed but for two rows, one of which — `hover_interface_method` — closed on 2026-09-17 by
  `dfc34a9`), 3.3 `codegen-wat-narrowing.md` and 3.6 `codegen-comptime-misc.md` (test fixes landed,
  `wrong-output` rows registered).

## Problem

The per-report residuals are open for eight of the twelve reports, and the rows cite a corpus that
has moved under them.

### The corpus

```
$ find modules/compiler-core/snapshots modules/language-server/snapshots -name '*.snap.md' | wc -l
2687
```

| Family | Files | Unique |
|---|---|---|
| `codegen/{commonJS,erlang}` | 315 each | 315 each |
| `codegen/{beam,wasm}` | 314 each | 314 each |
| `codegen/errors/{beam,commonJS,erlang,wasm}` | 3 each | 3 each |
| `parser` | 224 | 224 |
| `comptime/{node,erlang,beam,wasm}` | 202 each | **202 total** — four byte-identical copies |
| `comptime/{node,erlang}/errors` | 135 each | **135 total** — two copies |
| `comptime/templates` | 1 | 1 |
| `lsp` (`modules/language-server/snapshots`) | 114 | 114 |
| **total** | **2687** | **1946** |

The 2451-vs-2687 gap and the 741-file comptime duplication are why wave B waits for
[`06-comptime-dedup`](../../../1.0.5-beta/06-comptime-dedup/README.md) step 1: a `duplicate` or `wrong-test` fix in
`src/comptime/tests/**` renames a slug, and a rename moves **four** files before that step and one
after.

### The reports

Verdict cells counted at `c2dd780` by grepping each report's tables. These are the **raw** audit
rows, not the re-derived open count — the 1.0.2-beta re-derivation is the second column, and the gap
between them is what step 1 and step 2 re-derive again.

| Batch | Report | Table rows | Non-`ok` verdict cells | Open at the 1.0.2-beta re-derivation | Wave |
|---|---|---|---|---|---|
| 3.1 | `codegen-features.md` | 189 | 174 | 168 | A |
| 3.2 | `codegen-control_flow.md` | 102 | 68 | 87 | A |
| 3.4 | `codegen-values-dispatch-externals.md` | 117 | 96 | 99 | A |
| 3.5 | `codegen-builtins-aggregates.md` | 88 | 70 | 66 | A |
| 3.3 | `codegen-wat-narrowing.md` | 92 | 42 | 37 | worked; `:70` → A |
| 3.6 | `codegen-comptime-misc.md` | 54 | 32 | 30 | worked; registered rows close with their fronts |
| 3.7 | `comptime-errors-effects.md` | 63 | 52 | 48 | B |
| 3.8 | `comptime-decls-variants.md` | 84 | 65 | 59 | B |
| 3.9 | `comptime-templates-types-exprs.md` | 69 | 46 | 40 | B |
| 3.10 | `comptime-generics-effects-decorators.md` | 93 | 84 | 78 | B |
| 3.11 | `parser.md` | 56 | 32 | — | closed |
| 3.12 | `lsp.md` | 63 | 38 | 2 | step 3 |

Every report already carries a `**Status (1.0.1-beta close)**` block telling the reader to re-derive
each row at HEAD; that block is not the status line step 1 and step 2 append.

## What changed under the rows since 1.0.4-beta

The 1.0.4-beta document ordered wave A "after 01 step 6" and wave B "after 07's step 2". Both
orderings still hold, but **they now name different fronts**, and one of the two premises has grown.

| 1.0.4-beta said | 1.0.5-beta reading |
|---|---|
| wave A after **01 step 6** — "which re-records every print-text RUN LOG" | 1.0.4's 01 step 6 was decision 8's run time on all four backends in one front. It is now four file-disjoint fronts — [`02-erlang`](../02-erlang/README.md), [`03-beam`](../03-beam/README.md), [`04-js`](../04-js/README.md), [`05-wasm`](../05-wasm/README.md) — **plus [`01-checker`](../01-checker/README.md)**, which is what types what they lower. Wave A therefore waits for **five** fronts, not one; but it can be split per backend, because each of the four owns one `snapshots/codegen/<target>/` directory and a report's rows are per-backend columns |
| wave B after **07 step 2** (the renderer) | unchanged in substance: it is now [`06-comptime-dedup`](../../../1.0.5-beta/06-comptime-dedup/README.md) step 2. Step 1 is a *new* additional precondition for any **rename**, which 1.0.4-beta only noted in its blast radius |
| the backend fronts "have closed" by wave A | they have not — they are this milestone's 02–05. A surviving `wrong-output` row therefore **has** an owner to register with, which the 1.0.4-beta text assumed it would not |

Measured evidence that the rows have moved: **113 compiler-core snapshots and 10 LSP snapshots were
re-recorded between `26d4fdc` and `c2dd780`** — 25 `parser`, 14 `codegen/wasm`, 10 `codegen/erlang`,
10 `codegen/commonJS`, 6 `codegen/beam`, 48 comptime (16 unique slugs). Those are the partial checker
and grammar waves alone. A row re-derived before
[`01-checker`](../01-checker/README.md) closes is re-derived twice.

## Rows handed over by front 06

Two, both verified by that front and left unedited because they are this front's files:

- **`scripts/snap_audit.sh:501`'s per-backend arm is dead code.** Front 06's own README predicted the
  classifier would break; it did not — the `else` arm picks up `comptime/ast`, `comptime/errors` and
  `comptime/templates`, one line per slug, 0 orphans, exit 0, and the AST suite's label was renamed
  from `comptime` to `comptime/ast`. What is left is removing the arm that can no longer match.
- **`src/comptime/tests/infer_decls.zig:143`** is named `"infer: implement block is invisible to the
  binding list"` and the behaviour it names is gone: `implement` blocks appear now, read from
  `OkData.transformed.decls`. Renaming the test renames its snapshot slug, which is why it waits for
  this front.

## Steps

### Step 1 — wave A: the codegen reports (3.1, 3.2, 3.4, 3.5, and 3.3's `:70`)

After [`01-checker`](../01-checker/README.md) and the backend front that owns the column. **Split by
backend**: the four backend fronts are file-disjoint and land separately, so a report's `erlang`
column can be re-derived when [`02-erlang`](../02-erlang/README.md) closes without waiting for
[`05-wasm`](../05-wasm/README.md). A row with cells in several columns waits for the last of them.

For every non-`ok` row: re-derive it at the new HEAD — many will have closed with the backend fronts,
and the decisions turn the `uncertain` rows into ordinary verdicts — then fix the test
(`wrong-test`, `weak`, `duplicate`, `skip-undocumented`) or register the `wrong-output` in the owning
front's README with its snapshot name.

The four tests named *"lowers byte-identically across backends"* are named by decision 1: they either
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

After [`01-checker`](../01-checker/README.md) (the shared root causes land once) and
[`06-comptime-dedup`](../../../1.0.5-beta/06-comptime-dedup/README.md) step 2, which turns many `weak` rows into `ok`
or into a real `wrong-output` with no test change: 57 of the 69 rendered `?` are a renderer artefact
and every `"id"` is `0`, so a row graded `weak` for "the JSON does not show the type" is not gradeable
until that lands. **No test in `src/comptime/tests/**` is renamed before
[`06-comptime-dedup`](../../../1.0.5-beta/06-comptime-dedup/README.md) step 1** — a rename moves four files until then.

The batches whose `wrong-output` rows land in `comptime/infer.zig` conflict with each other: one
worker, one batch at a time.

**Acceptance:** as step 1, per report, plus:
- [ ] No test rename in `src/comptime/tests/**` landed before 06 step 1 (checked by the commit order)

### Step 3 — the questions no decision answers

The `uncertain` rows no decision answers each get an answer or are carried forward **by name**.
Two of 1.0.4-beta's list are resolved:

| Row | State at `c2dd780` |
|---|---|
| `lsp.md:104` `completion_decorator_record` | **closed** by `f952bfc6` (C-19): line 17 reads `PostService  [Struct]  detail: type PostService(name: string, count: i32)`; the degraded path keeps every well-typed `val` since 06 N23 (`other` is completable, asserted by the test). Pinned with `completion_type_enum_detail` / `completion_behavior_detail` (front 11's carve-out) |
| `lsp.md:103` `hover_interface_method` | **closed** 2026-09-17 by `dfc34a9`: the footer names the declaring behavior (`*from `behavior Signed` (via I32)*`) |

**Acceptance:**
- [ ] Each remaining row answered in its report, or listed by name in the next milestone
- [ ] No row is carried as "uncertain" without a named owner or a written reason

### Step 4 — the two mis-named `externals.zig` tests

`src/codegen/tests/externals.zig:53` and `:65` are named for an equivalence the compiler does not
implement:

```zig
:53  test "js: External.<Target> ---- template equivalent to @external(target, template)" {
:65  test "js: External.<Target> ---- mixed with @external() in one decl" {
```

Both bodies use `#[@External.Erlang(…), @External.Node(…)]` only; the comment two lines above them
already says "The enum-variant form … is the only form." Renaming them moves their snapshots in
`snapshots/codegen/{commonJS,erlang,beam,wasm}/`.

This was an unowned item of 1.0.4-beta's `fronts.md`, suggested owner 08 — **claimed here**.

**Acceptance:**
- [ ] Both tests carry a name that describes what they assert; the four snapshot files per test are
      renamed in the same commit (`git mv`), contents byte-identical
- [ ] `scripts/snap_audit.sh --mode=orphans` after the rename: 0 orphans, 0 unrecorded
- [ ] Sequenced after [`04-js`](../04-js/README.md), [`02-erlang`](../02-erlang/README.md),
      [`03-beam`](../03-beam/README.md) and [`05-wasm`](../05-wasm/README.md) have landed — the four
      directories are theirs

### Step 5 — `snap_audit.sh` follows the new comptime layout

[`06-comptime-dedup`](../../../1.0.5-beta/06-comptime-dedup/README.md) step 1 deletes `comptime/{node,erlang,beam,wasm}/`.
`scripts/snap_audit.sh`'s path classifier has an explicit arm for those four names
(`:499-501`: `if (seg[5] ~ /^(node|erlang|wasm|beam)$/) suite = … "comptime/errors" : "comptime"`),
whose only job is to collapse the four copies into one review row. After step 1 it matches nothing and
every comptime row loses its suite label.

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
- [ ] Commit on `fix/review-backlog`; no push, no merge — landing is the maintainer's step

## Blast radius

- **Test renames move snapshot files.** In `src/codegen/tests/**` a rename moves four files (one per
  backend directory); in `src/comptime/tests/**` it moves **four before
  [`06-comptime-dedup`](../../../1.0.5-beta/06-comptime-dedup/README.md) step 1 and one after**; in
  `src/parser/tests/**` and `modules/language-server/src/tests/**`, one.
- **Nothing here changes emitted output.** A row that would is registered in the owning front, not
  fixed. The corpus this front may touch is 2687 files / 1946 unique, and it moves **none** of them by
  content.
- **Registrations reach open fronts.** Unlike 1.0.4-beta, the four backend fronts are open in this
  milestone, so a surviving `wrong-output` row has a named owner. A row that outlives all four is the
  maintainer's to schedule.

## Notes

- The reports' tables are the audit record and are not edited, except for the status line per report
  and the strikes step 1 asks for.
- The three copies of `slugify`/`slugFromSrc` (`codegen/tests/helpers.zig`,
  `comptime/tests/helpers.zig`, `parser/tests/helpers.zig`) are still not merged: the `": "`
  truncation is a behaviour every snapshot name depends on, and changing it renames hundreds of files.
  `comptime/tests/helpers.zig` is [`06-comptime-dedup`](../../../1.0.5-beta/06-comptime-dedup/README.md)'s, so the merge
  needs that front's agreement. Not in this milestone unless the maintainer adds it.
- The six content-identical comptime error pairs listed in
  [`06-comptime-dedup`](../../../1.0.5-beta/06-comptime-dedup/README.md#current-state) are `duplicate` rows of this
  front, not layout copies. Deduplicating them is a rename — wave B, after 06 step 1.
- Stale comments in this front's own test files are [`08-hygiene`](../08-hygiene/README.md)'s sweep,
  handed here or landed after: `codegen/tests/builtins.zig:382` still says commonJS lowers `assert` to
  `console.assert` (decision 4 is implemented on all four backends), and
  `codegen/tests/control_flow.zig:73,76`, `codegen/tests/narrowing.zig:105` and
  `codegen/tests/wat.zig:86` cite the retired front numbers `06-wasm` and `07-checker`.

---

## Rows for `fronts.md`

**Ownership table:**

```markdown
| **07** [`review-backlog`](./README.md) | `src/utils/snap.zig` · `scripts/snap_audit.sh` · `src/codegen/tests/**` · `src/comptime/tests/**` except `helpers.zig` (06's) · `src/parser/tests/**` · `modules/language-server/src/tests/**` · the status lines of the 1.0.1-beta reports (meta repo) | — (moves a snapshot only by renaming its test) | not started — wave A after 01 + 02–05, wave B after 06 step 2 |
```

**Conflict notes** (against the other thirteen fronts):

| With | Verdict | Why |
|---|---|---|
| **01 checker** | **no** — 01 first | 01's rows are the shared root cause of wave A and wave B, and it re-records the snapshots the rows cite. A row re-derived before it is re-derived twice |
| **02 erlang · 03 beam · 04 js · 05 wasm** | **no** — each first, per column | 07 owns the test sources those fronts add fixtures to, and its rows cite their snapshot directories. Wave A splits per backend: a report's `erlang` column re-derives when 02 closes. Step 4's rename moves four files, one in each of their directories |
| **06 comptime-dedup** | **no** — 06 first | Shared: `src/comptime/tests/` (06 owns `helpers.zig`, 07 the rest) and `scripts/snap_audit.sh` (07's file, which 06 step 1 breaks — step 5 is that edit, landed with 06) |
| **08 hygiene** | **no** — 07 first | 08's comment sweep over `src/codegen/tests/**` and `src/comptime/tests/**` is 5 known sites in 4 files; comment-only, safe to make and expensive to merge. Land it after 07, or hand 07 the sweep |
| **09 ecosystem-residuals · 10 cli-residuals · 12 language-tests** | yes | No shared file, no shared snapshot directory |
| **11 tooling** | **no** — 11 first | 07 owns `modules/language-server/src/tests/**`, 11 owns `modules/language-server/src/**`. A 07 test rename moves an LSP snapshot 11 may have just re-recorded; and `completion_decorator_record` (step 3) is re-recorded by whoever fixes `buildRecordDeclName` (01) |
| **13 module-identity** | **no** — 13 first | 13 re-records ≈ 188 files in `snapshots/codegen/{erlang,beam}/` and changes the shape wave A's erlang and beam columns grade |
| **14 comptime-on-beam** | **no** — 14 first | It renames the `----- COMPTIME ERLANG` section of 48 snapshots (measured at `c2dd780`) — 28 in `snapshots/codegen/**` and 20 in `snapshots/comptime/**`, the exact files wave B's 3.6 and 3.9 rows read |

**Front-table row (`overview.md`):**

```markdown
| [`07-review-backlog`](./README.md) | medium | not started — wave A after 01 + 02–05, wave B after 06 | The per-report residuals of the 1.0.1-beta snapshot review, over a corpus of 2687 snapshot files (1946 unique): eight reports still open, re-derived at HEAD and then fixed as a test or registered as a `wrong-output` in the front that owns the file. Plus the two mis-named `externals.zig` tests and the `snap_audit.sh` classifier 06's layout change breaks |
```

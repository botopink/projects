# Front 08 — review-backlog

**Priority:** medium — nothing ships wrong because of it, but ~700 open review rows sit between the
suite and "every snapshot proves what its test claims", and the rows that name a compiler defect
must reach the front that owns the file before that front closes
**Status:** not started as a front. It is what is left of 1.0.2-beta front 09 (review-tooling),
whose steps 1–3 landed — see [Delivered](#delivered-by-102-beta-review-tooling)
**Depends on:** wave A (reports 3.1, 3.2, 3.4, 3.5) — [`../06-checker/`](../06-checker/README.md)
landed. The backend fronts 01–04 add fixtures to the test sources this front owns and re-record
the snapshots its rows cite, and the checker can move all four codegen directories again; a row
re-derived before either lands is re-derived twice. Wave B (reports 3.7–3.10) —
[`../07-comptime-dedup/`](../07-comptime-dedup/README.md) step 2 landed
**Owns:** `src/utils/snap.zig` · `scripts/snap_audit.sh` (+ its `scripts/AGENTS.md` section) ·
`src/codegen/tests/**` (except `externals.zig`'s `gleam_stdlib` fixtures, carved out to
[`../04-js-bridges/`](../04-js-bridges/README.md) H6) · `src/comptime/tests/**` (except
`decorator_regression.zig`, carved out to [`../05-cli-residuals/`](../05-cli-residuals/README.md), and
`helpers.zig`, which [`../07-comptime-dedup/`](../07-comptime-dedup/README.md) edits first) ·
`src/parser/tests/**` · `modules/language-server/src/tests/**` · the per-report status lines in
[`../../1.0.1-beta/06-snapshot-review/`](../../1.0.1-beta/06-snapshot-review/) · the decision
reference [`semantics-decisions.md`](./semantics-decisions.md)
**Does not touch:** any lowering (01–04), the checker and parser sources (06), `comptime/snapshot.zig`
(07), `libs/std/**`. A `wrong-output` row that needs one of these is **registered** in the owning
front's README with its snapshot name, not fixed here.

Paths are relative to `repository/botopink-lang/modules/compiler-core/`, except those starting with
`scripts/` or `modules/`, which are relative to `repository/botopink-lang/`. Report citations
(`codegen-features.md:85`) are lines in the 1.0.1-beta review reports.

---

## Delivered by 1.0.2-beta review-tooling

- **Step 1 — orphan detection.** `BOTOPINK_SNAP_TRACE=<file>` at both `compareOrCreate` choke points
  (append-safe), test helpers carry `@src()` into the trace, `scripts/snap_audit.sh --mode=orphans`.
  Traced run: 2451 snapshots on disk = 2451 traced, **0 orphans**; unset, nothing changes.
- **Step 2 — review worksheet.** `scripts/snap_audit.sh --mode=review` emits one TSV row per unique
  snapshot with its test `file:line` and a verdict seeded from the reports by header cell.
- **Step 3 — the four semantics decisions**, decided by the maintainer 2026-09-16, every
  recommendation accepted: 1 → a `__bp_print/1` helper; 2 → a block is a statement, its value comes
  from `break`; 3 → box `?T` on wasm, `0` = null; 4 → `assert` always fatal with message and
  `file:line`. [`semantics-decisions.md`](./semantics-decisions.md) is the reference and names the
  implementing handoff in each front.
- **Step 4, partly:** 3.11 `parser.md` closed (one duplicate set deleted); 3.12 `lsp.md` closed but
  for the two rows below; 3.3 `codegen-wat-narrowing.md` and 3.6 `codegen-comptime-misc.md` worked
  (test fixes landed, `wrong-output` rows registered — see [`backlog.md`](./backlog.md#registered-from-33-and-36)).

## Problem

The per-report residuals are still open for eight of the twelve reports, and two review questions
have no owner.

| Batch | Report | Open at the 1.0.2-beta count | State |
|---|---|---|---|
| 3.1 | `codegen-features.md` | 168 | **unblocked** by the decisions — wave A |
| 3.2 | `codegen-control_flow.md` | 87 | **unblocked** — wave A; strike `:196` (beam `null`, closed) |
| 3.4 | `codegen-values-dispatch-externals.md` | 99 | **unblocked** — wave A |
| 3.5 | `codegen-builtins-aggregates.md` | 66 | **unblocked** — wave A |
| 3.3 | `codegen-wat-narrowing.md` | 37 | worked; `:70` `optional_chaining_on_record_null_returns_zero` was blocked on decision 3 — now wave A |
| 3.6 | `codegen-comptime-misc.md` | 30 | worked; the registered rows close with their fronts |
| 3.7 | `comptime-errors-effects.md` | 48 | wave B |
| 3.8 | `comptime-decls-variants.md` | 59 | wave B |
| 3.9 | `comptime-templates-types-exprs.md` | 40 | wave B |
| 3.10 | `comptime-generics-effects-decorators.md` | 78 | wave B |
| 3.11 | `parser.md` | — | closed |
| 3.12 | `lsp.md` | 2 | see the two rows below |

Per-class counts, table shapes and where to read each report: [`backlog.md`](./backlog.md).

## Steps

### Step 1 — wave A: the codegen reports (3.1, 3.2, 3.4, 3.5, and 3.3's `:70`)

After [`../06-checker/`](../06-checker/README.md) lands (and therefore after 01–05). For every non-`ok` row that is not withdrawn: re-derive it at the new HEAD —
many will have closed with the backend fronts, and the decisions turn the `uncertain` rows into
ordinary verdicts — then fix the test (`wrong-test`, `weak`, `duplicate`, `skip-undocumented`) or
register the `wrong-output` in the owning front ([`backlog.md` § where a closed row lands](./backlog.md#where-a-closed-row-lands)).
Backend fronts will have closed by then: register a surviving `wrong-output` row in
[`../fronts.md`](../fronts.md#unowned-items) for the maintainer to schedule, rather than reopening a
landed front.

The four "lowers byte-identically across backends" tests are named by decision 1: they either hold
once 01/02's H1 lands, or carry the name the decision implies.

**Acceptance (per report):**
- [ ] Every non-`ok` row re-derived at HEAD and closed: fixed, registered with the snapshot name, or
      struck with a written reason
- [ ] The two stale beam `null` rows struck (`codegen-control_flow.md:196`, the `{atom,nil}` half of
      `codegen-features.md:211`; its `slice/3` half is beam B4)
- [ ] A status line appended to the report saying what closed it

### Step 2 — wave B: the comptime reports (3.7–3.10)

After [`../06-checker/`](../06-checker/README.md) (the shared root causes land once) and
[`../07-comptime-dedup/`](../07-comptime-dedup/README.md) step 2 (which turns many `weak` rows into
`ok` or a real `wrong-output` with no test change). The batches whose `wrong-output` rows land in
`comptime/infer.zig` conflict with each other: one worker, one batch at a time.

**Acceptance:** as step 1, per report.

### Step 3 — the questions no decision answers

The 7 `uncertain` rows listed in [`backlog.md`](./backlog.md#the-7-uncertain-rows-no-decision-answers)
each get an answer or are carried forward by name. Two are resolved already:
`lsp.md:104` `completion_decorator_record` is a checker defect (the degraded completion path drops
every `val` — [`../06-checker/`](../06-checker/README.md) Step 0, N4). **`lsp.md:103`
`hover_interface_method` is a decision for the maintainer**: `abs` is declared in `interface Signed`
and the receiver is an `I32` — should the hover footer name the declaring interface (`Signed`, the
recommendation from the 1.0.2-beta re-derivation) or the receiver's? The fix site is
`modules/language-server/src/engine.zig`, which no front owns
([`../fronts.md`](../fronts.md#unowned-items)).

**Acceptance:**
- [ ] Each of the 7 rows answered in its report, or listed by name in the next milestone
- [ ] `hover_interface_method`'s answer recorded; its snapshot re-recorded by whoever takes
      `engine.zig`

## Gate

- [ ] `scripts/gate.sh --cold` green in this front's worktree
- [ ] A traced run (`BOTOPINK_SNAP_TRACE`) after each batch: 0 orphans, traced = on disk
- [ ] Warm re-run: same pass count, 0 leaks, 0 `.snap.md.new`
- [ ] `AGENTS.md` of the snapshot-producing directories updated in the same commit as a test
      rename or deletion
- [ ] Commit on `fix/review-backlog`; no push, no merge — landing is the maintainer's step

## Blast radius

- **Test renames move snapshot files** — a `duplicate` or `wrong-test` fix renames a slug. In
  `src/comptime/tests/**` that is four files per slug before [`../07-comptime-dedup/`](../07-comptime-dedup/README.md)
  step 1 and one after, which is one more reason wave B waits for it.
- **Nothing here changes emitted output.** A row that would is registered, not fixed.
- **Registrations reach closed fronts.** By wave A the backend fronts and the checker have landed; surviving
  `wrong-output` rows become the maintainer's to schedule (next milestone or a follow-up front).

## Notes

- The reports' tables are the audit record and are not edited, except for the status line per
  report and the strikes step 1 asks for.
- The three copies of `slugify`/`slugFromSrc` (`codegen/tests/helpers.zig`,
  `comptime/tests/helpers.zig`, `parser/tests/helpers.zig`) are still not merged: the `": "`
  truncation is a behaviour every snapshot name depends on, and changing it is a rename of hundreds
  of files. Now that step 1's trace can prove nothing was orphaned, it can be its own step — not in
  this milestone unless the maintainer adds it.
- Unowned finding from the 3.6 re-derivation: error snapshots render `┌─ :L:C` with no file name
  (`comptime/error.zig`). Assigned to [`../06-checker/`](../06-checker/README.md) Step 0, N9.

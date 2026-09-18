# Front 08 — review-backlog

**Delivered in part.** The front never opened as a worktree; what it delivered in 1.0.4-beta is the
**decisions** the rest of the milestone was built on, and they are the reason this directory is the
milestone's language reference:

- **[`decision-8-language.md`](./decision-8-language.md)** — written and decided 2026-09-17 (meta
  `8d16da87`), the language design fronts 12, 15, 06, 17 and 01 implement: written generic types
  carry all their arguments (`Self<T>` included), the `unknown` and union types, `is` testing values,
  `case` arms as `Pattern { n -> … }` with `when` guards, tuple labels as compile-time names, one
  source-shaped formatter per type, `#[@result] … -> @Result<T, E>`, and `loop (condition)` instead
  of `while`. It supersedes decisions 1a, 6 and 7.
- **[`semantics-decisions.md`](./semantics-decisions.md)** — decisions 1–5, decided 2026-09-16 with
  every recommendation accepted, each naming the front that implements it.

Its **steps 1–3** were delivered earlier, as 1.0.2-beta review-tooling; the per-report backlog
(step 4) is carried whole.

**Owned:** `src/utils/snap.zig` · `scripts/snap_audit.sh` · `src/codegen/tests/**` (minus 01's
`KNOWN`-note carve-out) · `src/comptime/tests/**` · `src/parser/tests/**` ·
`modules/language-server/src/tests/**` · the per-report status lines in
[`../../1.0.1-beta/06-snapshot-review/`](../../1.0.1-beta/06-snapshot-review/) · the two decision
references above.

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
  `file:line`.
- **Step 4, partly:** 3.11 `parser.md` closed (one duplicate set deleted); 3.12 `lsp.md` closed but
  for two rows, **both of which 1.0.4-beta closed** (below); 3.3 `codegen-wat-narrowing.md` and
  3.6 `codegen-comptime-misc.md` worked (test fixes landed, `wrong-output` rows registered — see
  [`backlog.md`](./backlog.md#registered-from-33-and-36)).

## Closed during 1.0.4-beta

| Row | Closed by |
|---|---|
| `lsp.md:103` `hover_interface_method` — should the hover footer name the declaring interface or the receiver's? | Decided for the declaring behavior and implemented by front 14, `dfc34a9`: `*from `behavior Signed` (via I32)*`, and `*from `behavior Array`*` when they agree |
| `lsp.md:104` `completion_decorator_record` — the degraded completion path dropped every `val` | Front 06's N4/N23, `574134a` (the `@emit` fallback keeps well-typed `val`s). The snapshot's other defect — the `record { … }` type name — is carried |
| `codegen-comptime-misc.md:186`'s `┌─ :L:C` root cause (an error snapshot names no file) | **not** closed — it is 06 N9, carried |

## The backlog, as measured

Open for eight of the twelve reports at the 1.0.2-beta count. The counts are the record; the rows
themselves are in [`backlog.md`](./backlog.md).

| Batch | Report | Open rows | State at the close of 1.0.4-beta |
|---|---|---|---|
| 3.1 | `codegen-features.md` | 168 | unblocked by the decisions — wave A |
| 3.2 | `codegen-control_flow.md` | 87 | unblocked — wave A; strike `:196` (beam `null`, closed) |
| 3.4 | `codegen-values-dispatch-externals.md` | 99 | unblocked — wave A |
| 3.5 | `codegen-builtins-aggregates.md` | 66 | unblocked — wave A |
| 3.3 | `codegen-wat-narrowing.md` | 37 | worked; `:70` `optional_chaining_on_record_null_returns_zero` unblocked by decision 3 |
| 3.6 | `codegen-comptime-misc.md` | 30 | worked; the registered rows close with their fronts |
| 3.7 | `comptime-errors-effects.md` | 48 | wave B |
| 3.8 | `comptime-decls-variants.md` | 59 | wave B |
| 3.9 | `comptime-templates-types-exprs.md` | 40 | wave B |
| 3.10 | `comptime-generics-effects-decorators.md` | 78 | wave B |
| 3.11 | `parser.md` | — | **closed** |
| 3.12 | `lsp.md` | 2 | **closed** — both rows above |

## What it left, and where

Everything below is **1.0.5-beta `07-review-backlog`**.

| Residual | Note |
|---|---|
| **Wave A** — reports 3.1, 3.2, 3.4, 3.5 and 3.3's `:70`. It waits on the checker and on the decision-8 run time: both re-record the codegen snapshots its rows cite, and the formatter re-records every print-text RUN LOG. A row re-derived before them is re-derived twice | after `01-checker` and the four backend fronts |
| **Wave B** — reports 3.7–3.10. It waits on the comptime-snapshot layout, which turns many `weak` rows into `ok` or a real `wrong-output` with no test change | after `06-comptime-dedup` step 2 |
| **The 7 `uncertain` rows no decision answers** — [`backlog.md`](./backlog.md#the-7-uncertain-rows-no-decision-answers). Two were resolved (both `lsp.md` rows above); five need an answer or a name in the next milestone | — |
| **Two tests in `codegen/tests/externals.zig` (`:53`, `:65`) are named for an equivalence the compiler does not implement** — renaming moves snapshots | found by 09's step 5 sweep, 2026-09-17 |
| **`tests/helpers.zig` renders its own diagnostic**, so `codegen.generate` drops failed-module entries — reading `result.diagnostic` there is the test-source half of 05 step 2 | handed over by 05 |
| **The three copies of `slugify`/`slugFromSrc`** (`codegen/tests/helpers.zig`, `comptime/tests/helpers.zig`, `parser/tests/helpers.zig`) are still not merged: the `": "` truncation is a behaviour every snapshot name depends on, and changing it renames hundreds of files. Step 1's trace can now prove nothing was orphaned, so it can be its own step | not scheduled unless the maintainer adds it |
| **Test comments the backend landings left behind** — `codegen/tests/builtins.zig` ~`:365` still says commonJS lowers `assert` to `console.assert`; `codegen/tests/control_flow.zig` ~`:308`, `features.zig` ~`:866` and `values.zig` ~`:401` cite retired front numbers. Read at `ed15323` | handed over by 09's comment sweep |

## Notes

- The reports' tables are the audit record and are not edited, except for a status line per report
  and the strikes wave A asks for.
- Nothing in this front changes emitted output. A row that would is registered against the front that
  owns the file, not fixed here — and by wave A every 1.0.4-beta front has closed, so a surviving
  `wrong-output` row is registered against a 1.0.5-beta front by name.

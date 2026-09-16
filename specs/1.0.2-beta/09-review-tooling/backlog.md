# Review backlog — open rows per report

The twelve reports in [`../../1.0.1-beta/06-snapshot-review/`](../../1.0.1-beta/06-snapshot-review/)
are the audit record. **Their tables stay there, verbatim; this file only counts them and says where
to read.** Every row was written before the 1.0.1-beta fix waves, so a row is not proof of a live
defect: re-derive it at HEAD before acting. At least one class has already closed that way —
[`semantics-decisions.md` § decision 3](./semantics-decisions.md#decision-3) strikes two beam
`null` rows.

## Totals

**783 evidence rows across the twelve reports, 777 open.** 4 rows are re-graded `ok` inside non-`ok`
tables and 2 are withdrawn. Measured 2026-09-16 on the report files as they are on disk.

**Counting method** (reproducible with a short script over the Markdown): for each table, the header
cell containing `verdict` fixes a column index and every data row's value in that column is read; the
twelve summary "Verdict counts" / "Counts" tables are excluded; a composite verdict
(`uncertain (semantics) + weak`) takes its worst class, matching each report's own stated rule. A
table with no `verdict` header is not counted — that is what excludes
`codegen-wat-narrowing.md` `## WAT executed manually` and the `@print` matrix in
`codegen-builtins-aggregates.md`.

| Class | Rows | What closing one means |
|---|---|---|
| `wrong-output` | 397 | a compiler fix in the front that owns the file, or a registration there with the snapshot name |
| `weak` | 182 (180 open) | the snapshot does not prove what the test claims — often fixed for free by the comptime renderer work in [`../10-comptime-dedup/`](../10-comptime-dedup/README.md) |
| `wrong-test` | 126 | the test name or source does not match what it checks |
| `duplicate` | 30 | delete one of a pair |
| `known` | 25 | already tracked elsewhere (erlc output leak, `deallocate` without `allocate`, the wasm RUN LOG stub) |
| `uncertain` | 14 | 7 answered by [`semantics-decisions.md`](./semantics-decisions.md); 7 are separate questions, [listed below](#the-7-uncertain-rows-no-decision-answers) |
| `legacy-syntax` | 4 | `parser.md` only — hygiene items 5.12/5.13 ([`../11-hygiene/`](../11-hygiene/README.md)) |
| `skip-undocumented` | 1 | — |
| `orphan` | **0** | declared in 8 summary tables, never once an evidence row |

`misnamed`/`naming` is **not** a verdict class — naming problems are graded `wrong-test` or `weak`.
`withdrawn` is a disposition, not a verdict.

The 6 rows that are not open:

| Row | Disposition |
|---|---|
| `codegen-features.md:227` `array_instance_default_fn_methods` | re-graded `ok (latent)` |
| `codegen-values-dispatch-externals.md:167` `external_global_math` | re-graded `ok (divergence noted)` — keep it; decision 1 depends on this grading |
| `parser.md:119` `enum_section_single_section_sibling_bare_variant` | re-graded `ok · corrected (was uncertain)` |
| `parser.md:128` (`errors.zig` parse-error tests, first row) | `ok` |
| `comptime-templates-types-exprs.md` `### Withdrawn (moved to \`ok\`)` (`:139`) | 2 rows, both formerly `weak` — the only genuinely closed sub-table in the corpus |

## Per report

Open counts, descending. The pointer is the heading to read.

| Batch | Report | Open | By class | Read from |
|---|---|---|---|---|
| 3.1 | `codegen-features.md` | **168** | wrong-output 121 · weak 34 · uncertain 5 · wrong-test 5 · known 3 | `## All non-ok findings (per slug)` (152 rows), indexed by `## Systemic root causes` (17 rows, `S1…S17` — fix an `S` once and a block of rows falls) |
| 3.4 | `codegen-values-dispatch-externals.md` | **99** | wrong-output 62 · weak 12 · wrong-test 11 · known 10 · uncertain 2 · duplicate 1 · skip-undocumented 1 | `## Non-\`ok\` findings` (95 rows; re-check verdicts are inline as `**Re-check:** …`, not a column) + `## Harness-level findings` (5) |
| 3.2 | `codegen-control_flow.md` | **87** | wrong-output 54 · weak 16 · wrong-test 9 · known 5 · duplicate 2 · uncertain 1 | `## Findings table (all non-\`ok\` findings)`. `### Cosmetic (not counted)` is out of scope by the report's own rule |
| 3.10 | `comptime-generics-effects-decorators.md` | **78** | wrong-test 30 · weak 28 · duplicate 11 · wrong-output 8 · uncertain 1 | `## Non-ok findings` (every verdict carries `(H)`/`(M)`/`(L)`; 23 of the 30 `wrong-test` are `(H)`) |
| 3.5 | `codegen-builtins-aggregates.md` | **66** | wrong-output 46 · weak 13 · wrong-test 3 · known 2 · uncertain 2 | `## Findings table (all non-\`ok\` items)` (61) + `## Harness-level findings` (5). The `@print` matrix at `:159` has no verdict column |
| 3.8 | `comptime-decls-variants.md` | **59** | weak 30 · wrong-test 15 · wrong-output 13 · uncertain 1 | `## Non-\`ok\` findings`, indexed by `## Cross-cutting findings` (`X1…X10`, no verdicts — root causes) |
| 3.7 | `comptime-errors-effects.md` | **48** | wrong-output 24 · weak 9 · wrong-test 9 · duplicate 6 | `## Non-ok findings` (verdicts carry `(low)`/`(med)`/`(high)`; only 2 are `high`) |
| 3.9 | `comptime-templates-types-exprs.md` | **40** | weak 17 · wrong-test 15 · wrong-output 7 · duplicate 1 | `## Non-\`ok\` findings` — **stop before `### Withdrawn (moved to \`ok\`)`** |
| 3.3 | `codegen-wat-narrowing.md` | **37** | wrong-output 26 · wrong-test 8 · weak 3 | `## Non-ok findings`. The `## WAT executed manually (wasmtime 45.0.0)` table (41 rows) is a run log, not verdicts |
| 3.11 | `parser.md` | **33** | wrong-test 12 · wrong-output 10 · legacy-syntax 4 · weak 4 · duplicate 3 | `## Findings: snapshots that are not \`ok\`` — **seven** tables, one per class — **and** `## Findings: \`errors.zig\` parse-error tests`, which the first heading does not cover |
| 3.12 | `lsp.md` | 32 rows, **~15 truly open** | wrong-output 12 · weak 9 · duplicate 5 · wrong-test 4 · uncertain 2 | `## Non-ok findings`. Its header blockquote (`:10`) already declares **every `wrong-output` row**, all snapshot-renderer findings and 3 of the 5 duplicates closed — re-derive before counting |
| 3.6 | `codegen-comptime-misc.md` | **30** | wrong-output 14 · wrong-test 5 · weak 5 · known 5 · duplicate 1 | `## 1. Findings table (all non-\`ok\`)` |
| | **Total** | **777** | wrong-output 397 · weak 180 · wrong-test 126 · duplicate 30 · known 25 · uncertain 14 · legacy-syntax 4 · skip-undocumented 1 | |

### Caveats before quoting these numbers

1. **Rows ≠ tests.** The codegen reports (3.1, 3.2, 3.4, 3.5) carry a backend column, so one test
   can produce several rows (one per backend or backend group); their own `## Verdict counts` tables are
   per-test roll-ups and will not match. Use the row figures for backlog size, the reports' count
   tables for "how many tests are affected".
2. **Index tables are counted too.** `codegen-features.md` `## Systemic root causes` has a verdict
   column, so its 17 `S` rows are in the 168 — and some of them name the same fixture as a per-slug
   row (S15 ≡ `:133`, S16 ≡ `:217`). The total is an upper bound on distinct findings.
3. **`lsp.md` is counted at 32** although its own header declares roughly half closed; the 777 does
   not subtract them.
4. **Stale rows are counted.** The two beam `null` rows struck by decision 3
   (`codegen-control_flow.md:196`, `codegen-features.md:211`) are still in the 777.
5. **Table shapes vary.** The `re-check` column is 4th in some reports, last in others, and inline
   in two; `lsp.md` alone has a `sev` column; `parser.md` splits by class into seven tables. Any
   tooling written for `--mode=review` ([README step 2](./README.md#step-2--review-worksheet)) must
   not assume a fixed column index.
6. **Legacy-syntax may already be closed.** [`../11-hygiene/README.md`](../11-hygiene/README.md)
   records 5.12 and the parser half of 5.13 as closed in 1.0.1-beta; re-derive `parser.md`'s 4
   `legacy-syntax` rows before counting them.

## Where a closed row lands

A row is fixed by the front that owns the file it needs. This front fixes test-side rows
(`wrong-test`, `weak`, `duplicate`, `skip-undocumented`, `legacy-syntax`) in the test files it owns,
and routes the rest:

| Report | `wrong-output` owner |
|---|---|
| 3.1, 3.2, 3.4, 3.5, 3.6 | by backend: [`../04-beam/`](../04-beam/README.md), [`../05-erlang/`](../05-erlang/README.md), [`../06-wasm/`](../06-wasm/README.md), [`../08-js-bridges/`](../08-js-bridges/README.md) |
| 3.3 | [`../06-wasm/`](../06-wasm/README.md) (WAT), [`../07-checker/`](../07-checker/README.md) (narrowing rules) |
| 3.7, 3.8, 3.9, 3.10 | [`../07-checker/`](../07-checker/README.md); renderer rows (`?`, `"id": 0`, missing declaration kinds) to [`../10-comptime-dedup/`](../10-comptime-dedup/README.md) |
| 3.11 | [`../07-checker/`](../07-checker/README.md) owns `parser/{decls,exprs,patterns}.zig` |
| 3.12 | nobody — `modules/language-server/` is in no front's ownership; register and report |

Two rows close from other fronts: the `pick`/`omit`/`partial`/`mergeRecords` intercept shadowing
user fns (3.6) and "user `pick` vs the builtin" (3.3) are one defect, `src/comptime/infer.zig:6901`,
closed by [`../03-std-surface/`](../03-std-surface/README.md) step 1 (6a); the "dangling import for
template-only symbols" (3.6) is its step 3 (6d). Coordinate so the rows are struck, not re-opened.

**Ordering.** Batches whose `wrong-output` rows land in `src/comptime/infer.zig` (3.7–3.10) conflict
with each other and with the checker front: land the shared checker root causes once, first.

## Uncertain rows

### The 7 answered by a decision

| Row | Decision |
|---|---|
| `codegen-features.md:85` S16 | [1 — `@print` text](./semantics-decisions.md#decision-1) |
| `codegen-features.md:217` `array_join_lowers_byte_identically_across_backends` | [1](./semantics-decisions.md#decision-1) (same fixture as S16) |
| `codegen-features.md:84` S15 | [2 — block / tail value](./semantics-decisions.md#decision-2) |
| `codegen-features.md:124` `codegen_use_tuple_destructure_state_to_usestate` | [2](./semantics-decisions.md#decision-2) |
| `codegen-features.md:133` `codegen_inline_implement_context_base_erased_at_runtime` | [2](./semantics-decisions.md#decision-2) (same fixture as S15) |
| `codegen-control_flow.md:179` `case_nested_case_in_block_arm` | [2](./semantics-decisions.md#decision-2) |
| `codegen-builtins-aggregates.md:90` `assert_with_message` | [4 — `assert`](./semantics-decisions.md#decision-4) |

Decision 3 (`null`) answers no `uncertain` row; it strikes two stale rows and unblocks the wasm
narrowing rows.

<a id="the-7-uncertain-rows-no-decision-answers"></a>

### The 7 uncertain rows no decision answers

Separate design questions. They must not be lost when the decisions close.

| Row | Question |
|---|---|
| `codegen-builtins-aggregates.md:102` `assert_pattern_with_enum_variant` | Is the `Ok` in `if ((_match instanceof Ok))` the `@Result` variant or a user enum? The source never declares it |
| `codegen-values-dispatch-externals.md:104` `operators_equality_maps_to` | beam emits `is_eq` (arithmetic) where erlang emits `=:=` (exact) — a bug, or guaranteed safe by the typing? |
| `codegen-values-dispatch-externals.md:183` `external_a3_result_template_owned_declare_fn` | The committed RUN LOG `42` came from a stale cache entry; a cold run would blank it. Is the pinned value trustworthy? |
| `comptime-decls-variants.md:139` `path_access_with_bad_tail_raises_focused_error` | The caret points at the last path segment (col 25), not the offending one (col 19) — intended? |
| `comptime-generics-effects-decorators.md:113` `generic_enum_result_t_with_ok_and_err` | Bare generic `Result` accepts any instantiation while bare `Option.None` is rejected against `Option<i32>`. Is bare `Result` legal? |
| `lsp.md:103` `hover_interface_method` | `abs` is declared in `interface Signed`, not `I32` — should the hover footer name the declaring or the receiver interface? |
| `lsp.md:104` `completion_decorator_record` | `usePost` is missing from its own completion list — correct, or a sign the degraded path drops `val` bindings? |

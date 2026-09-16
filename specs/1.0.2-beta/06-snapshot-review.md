# Spec 06 — Snapshot review, residuals

**Version:** 1.0.2-beta
**Priority:** medium — the harness is trustworthy now; what is left is the backlog it exposed
**Depends on:** nothing to start. **Step 2 is the gate for the rest** — four unanswered language
questions block rows in six reports at once, and fixing a row before its question is answered
records the wrong answer in a snapshot. Step 3 overlaps the type-system spec (checker root causes)
and the codegen-hardening spec (per-backend output and WAT execution)

---

## Objective

Finish what [`1.0.1-beta/06-snapshot-review.md`](../1.0.1-beta/06-snapshot-review.md) started: the
tooling that keeps the snapshot set honest, the review rows the fix waves did not reach, the
**four cross-backend semantics questions the review could not decide**, and the deduplication of
the comptime copies.

The four decisions are the point of this spec. Step 2 makes each of them decidable: what every
backend does today, with the deciding `file:line` and the snapshot that shows it; the options; a
recommendation; and what closes when it is answered.

Paths are relative to `repository/botopink-lang/modules/` unless stated otherwise.

## Current state

The harness contract landed: the RUN LOG is decided by exit status, a failing compile fails its
snapshot test (or records a `COMPILE DIAGNOSTIC` when the test is about the failure), a missing
snapshot fails without `BOTOPINK_SNAP_CREATE=1`, every backend is compared in one round, and
`HARNESS_VERSION` is in the runtime cache key. Measured at HEAD:

| | |
|---|---|
| `*.snap.md` | 2442 (2342 under `compiler-core/snapshots/`, 100 under `language-server/snapshots/lsp/`) — **0 zero-byte**, 0 source-only, 0 `*.snap.md.new` on disk |
| per backend | `codegen/{commonJS,erlang}` 279 · `codegen/{beam,wasm}` 278 · `codegen/errors` 4 |
| comptime copies | `comptime/{node,erlang}` 305 · `comptime/{beam,wasm}` 199 — 1008 files for 305 unique snapshots (step 5) |
| documented compile-error skips | 11 slugs, 44 `COMPILE DIAGNOSTIC` snapshots |
| `zig build test` | green, 0 leaks |
| wasm RUN LOGs | still empty — `executeWat` (`compiler-core/src/codegen/runtime.zig:547-558`) returns `""` unconditionally; owned by the codegen-hardening spec |

**The twelve reports in [`1.0.1-beta/06-snapshot-review/`](../1.0.1-beta/06-snapshot-review/) were
written before the fix waves.** Their evidence tables are the audit record and are kept verbatim,
but a row is no longer proof of a live defect: re-derive each one against HEAD before acting. At
least one whole class has already closed that way — see step 2, decision 3.

---

## Steps

### Step 1 — Tooling

Two of the four step-1 items shipped (`*.snap.md.new` is git-ignored; a missing snapshot fails
without `BOTOPINK_SNAP_CREATE=1`). The two that keep the set honest over time did not.

1. **Orphan detection.** The file name is the slug of the test description
   (`utils/snap.zig` `slugFromSrc` → `slugify`), so renaming or deleting a test leaves its
   snapshot behind and nothing reports it. Add an opt-in `BOTOPINK_SNAP_TRACE=<file>` that makes
   `compiler-core/src/utils/snap.zig` and `language-server/src/tests/snapshot.zig` append every
   checked path; run the suite with it and diff against `find … -name '*.snap.md'`.
2. **Review worksheet.** `scripts/snap_audit.sh` has `--mode={runlog,legacy,values,coverage}` and
   cannot relate a snapshot to its test. Add `--mode=review`, emitting one row per unique snapshot
   (`suite`, `slug`, `test file:line`, `path(s)`, `verdict`), seeded from the reports.

**Acceptance:**
- [ ] Orphan list produced from a full run; it is empty, or every entry is deleted
- [ ] `--mode=review` emits a row for every snapshot in every suite
- [ ] `scripts/AGENTS.md` documents both

### Step 2 — Decide the cross-backend semantics the review could not

Four questions. Each currently shows up in the reports as "the four backends disagree and nothing
says which is right". Decide them, write the decision into the language reference or
`codegen/AGENTS.md`, then the blocked rows become ordinary `wrong-output` fixes.

Only **7 of the 14 `uncertain` rows** in the corpus map to these four (see step 3); the other 7 are
separate design questions and are listed there so they are not lost.

---

#### Decision 1 — the text `@print` produces

**Today.**

| Backend | Lowering | Deciding site | `@print("hi")` prints |
|---|---|---|---|
| commonJS | `console.log($args)` | `compiler-core/src/codegen/commonJS.zig:917-918` | `hi` |
| erlang | `io:format("~p~n", [$args])` | `codegen/erlang.zig:1453-1455` | `<<"hi">>` |
| beam | the same `~p~n` through `io:format/2` | `codegen/beam_asm.zig:3352-3359` (1 arg), `:3316-3350` (2…16 args) | `<<"hi">>` |
| wasm | `$__print_str` / `$__print_i32` / `$__print_bool` / `$__print_f64` over `fd_write` | the helper set is named at `codegen/wat/wat_ast.zig:405-415` and defined in `codegen/wat/wat_prelude.zig` | unobservable — `executeWat` is a stub |

Both erlang backends widen a single control sequence to one per argument
(`erlang.zig:1500-1509` `widenFormatTemplate`; `beam_asm.zig:3336-3347` builds `"~p ~p …~n"`), so
arity is already handled — the divergence is purely the `~p` verb.

Four tests are named *"lowers byte-identically across backends"*. Their RUN LOGs at HEAD:

| Slug | node | erlang | beam | wasm |
|---|---|---|---|---|
| `array_at_lowers_byte_identically_across_backends` | `10` | `10` | `10` | empty |
| `array_indexof_lowers_byte_identically_across_backends` | `2` | `2` | `2` | empty |
| `array_join_lowers_byte_identically_across_backends` | `10, 20, 30` | `<<"10, 20, 30">>` | `<<"10, 20, 30">>` | empty |
| `array_slice_2_arg_lowers_byte_identically_across_backends` | **empty** | `[2,3,4]` | `[2,3,4]` | empty |

Integers already agree. Only the **string** case diverges — and `array_slice_2_arg`'s empty node log
is a different defect entirely (the module-health spec's step 6c: `String.prototype.slice` is
patched to a `require("./gleam_stdlib.mjs")` that throws).

**Options.**

| | What it means | Cost |
|---|---|---|
| A | Keep `~p`. State that textual equality across backends is not a goal; rename the four tests to say "same lowering", not "byte-identical output" | Cheapest. Leaves `@print` of a string unreadable on two backends |
| B | Type-directed: emit `~ts` when the argument's inferred type is `string`, `~p` otherwise | Needs the type at the call site. The typed erlang path has it; **the untyped comptime path does not** (`erlang.zig:383-388` exists precisely because inference never ran over those bodies), so comptime `@print` would still diverge |
| C | A synthesised `__bp_print/1` helper that dispatches at runtime: `is_binary(X) -> io:format("~ts~n",[X]); _ -> io:format("~p~n",[X])` | One helper per erlang-family backend. Works on the typed **and** the untyped path. There is a precedent of exactly this shape: `__bp_text/1` (`erlang.zig:425-432`), a binary-first guarded clause chain; and beam already synthesises helpers on demand |

**Recommendation: C.** It is the only option that makes the untyped comptime path agree too, and
the pattern is already in the tree. Two things must be written down alongside it:

- **Numeric formatting stays divergent.** `~p` of `1.0` is `1.0`; `console.log(1.0)` is `1`. That is
  `codegen-values-dispatch-externals.md:167` (`external_global_math`), already graded
  `ok (divergence noted)` — keep it graded that way and say so in `codegen/AGENTS.md`.
- Once `executeWat` exists, wasm's `$__print_*` family must match the same rule.

**Closes:** `codegen-features.md:85` (**S16**) and `:217` (`array_join_…`) — the two `uncertain`
rows in class (a) — plus every row in reports 3.1/3.5 that compares `@print` text across backends.

**Acceptance:**
- [ ] `@print` of a string produces the same bytes on commonJS, erlang and beam, in typed and
      comptime code
- [ ] Numeric formatting divergence is stated as intended in `codegen/AGENTS.md`
- [ ] The four "byte-identically" tests either hold or carry the name the decision implies

---

#### Decision 2 — the value of a block, and of a fn body's tail expression

**Today**, for a `case` arm that is a block with no `break`
(snapshots `codegen/{commonJS,erlang,beam,wasm}/case_nested_case_in_block_arm.snap.md`,
source `val result = case 42 { 0 -> { case 1 { 0 -> 54; _ -> 1; }; }; _ -> 1; };`):

| Backend | What the arm yields | Evidence |
|---|---|---|
| commonJS | **discarded** — the inner `(() => {…})()` is emitted as an expression statement and the outer arrow falls through to `return 1` | `commonJS/…:16-23` |
| erlang | the inner value — a nested `case … end` in tail position | `erlang/…:18-25` |
| beam | a **fun**: `{make_fun3, {f, 7}, 0, 0, {x, 0}, {list, []}}` lands in x0; the closure itself ends `{move, {atom, ok}, {x, 0}}`, so even calling it yields `ok` | `beam/…:16-17, 44` |
| wasm | `i32.const 0 ;; lambda` | `wasm/…:24` |
| comptime AST | typed `?` | `comptime/snapshot.zig` renders from syntax, not inference (step 4) |

The same disagreement in a fn body with a declared return type is
`codegen-features.md:84` (**S15**): node returns `undefined`, erlang returns the value, beam
returns `ok`.

**Options.**

| | Rule | Consequence |
|---|---|---|
| A | A block **is** an expression; its value is its last expression statement | Matches erlang only. node, beam and wasm all need codegen changes; and it silently gives a value to existing blocks that end in a side-effecting call |
| B | A block is a **statement**; its value is `unit` unless it ends in `break <e>`. The checker rejects a block in value position without `break`, and a fn with a non-`unit` return type whose body falls off the end | Matches the implemented majority (3 of 4 backends already produce no useful value). The construct already exists — `break <e>` is the block-value form throughout the language, and `comptime { break e; }` is the same shape |

**Recommendation: B**, enforced by a checker diagnostic rather than by four codegen changes. The
divergence then becomes unreachable instead of being papered over backend by backend, and no
existing program changes meaning. Note that `comptime { break e; }` is currently typed `void`
(`comptime-templates-types-exprs.md`) — that is the same rule mis-implemented, and it is fixed by
the same work.

**Closes:** the four `uncertain` rows in class (b) — `codegen-features.md:84, 124, 133` and
`codegen-control_flow.md:179` — plus the "else-less `if` as a value" and "`try` in a
non-`#[@result]` fn" type questions in report 3.2.

**Acceptance:**
- [ ] A block or fn body used as a value without `break`/`return` is a located checker error
- [ ] No backend emits a fun, a lambda placeholder or a discarded IIFE for a block arm
- [ ] The rule is in the language reference, with the `break` form shown

---

#### Decision 3 — the representation of `null`

**The beam half of this question is already closed at HEAD — the recorded rows are stale.**
`codegen/beam_asm.zig:1843-1850` emits `{atom, undefined}` and carries the reason in a comment
("`undefined`, not `nil`: `nil` is the empty *list* on BEAM, and the `@Option` helpers here … test
absence against `undefined`"); `:4297` does the same. `grep '{atom, nil}' snapshots/codegen/beam/`
returns nothing, and `codegen/beam/case_multiple_subjects.snap.md:30, 33` now read
`{move, {atom, undefined}, {x, 0}}`. **Strike** `codegen-control_flow.md:196` (`case_multiple_subjects`,
`weak (null representation)`) and `codegen-features.md:211` (`option_method_on_tuple_element`,
`wrong-output`, which cites a `beam_asm.zig:4060` line that no longer exists).

**What is left is wasm only.**

| Backend | `null` lowers to | Deciding site |
|---|---|---|
| commonJS | JS `null` | `codegen/commonJS.zig:2148` |
| erlang | atom `undefined` | `codegen/erlang.zig:2991` |
| beam | atom `undefined` | `codegen/beam_asm.zig:1843-1850`, `:4297` |
| wasm | `i32.const 0` | `codegen/wat.zig:2164` — `.null_ => try self.emit(zero)` |

So a `?i32` holding a real `0` is indistinguishable from `null` on wasm, and every narrowing test
that checks a `?i32` for absence is unverifiable.

**Options.**

| | Representation | Cost |
|---|---|---|
| A | Two i32s — a present flag plus the value | Every signature carrying an optional changes arity |
| B | A sentinel outside the useful range (e.g. `i32.MIN`) | Cheap, and wrong for a full-range `i32` |
| C | Box it: `?T` is an i32 offset into linear memory; `0` is null, non-zero is the address of the payload | Matches the value model wasm already uses — strings are interned as offsets, `$__heap_ptr` starts at 256 (`codegen/wat.zig`), so `0` is already an impossible address |

**Recommendation: C.** It keeps `0 == null`, which the backend already assumes everywhere, and
needs no signature changes. It costs a heap cell per non-null optional, which is the same price
strings already pay.

**Depends on it:** `codegen-wat-narrowing.md`'s `?i32` null-carrier row and the narrowing rows
around it. Verification of any of them also needs `executeWat` (codegen-hardening spec).

**Acceptance:**
- [ ] `null` and the integer `0` are distinguishable in a wasm `?i32`
- [ ] The representation of `null` on all four backends is one table in `codegen/AGENTS.md`
- [ ] The two stale beam rows are struck in their reports with the reason

---

#### Decision 4 — the severity of `assert` outside test mode

This is not a question about severity. **`assert` is a no-op on two of the four backends.**
Source `fn f() { assert false, "error message"; }` (snapshots `*/assert_with_message.snap.md`):

| Backend | Emitted | Effect | Deciding site |
|---|---|---|---|
| commonJS | `console.assert(false, "error message");` | prints to stderr, **continues**, exit 0 | `codegen/commonJS.zig:2427-2431` |
| erlang | `true = (false).` | raises `{badmatch, false}` — **the message and location are dropped** | `codegen/erlang.zig:3636` |
| beam | `{move,{atom,undefined},{x,0}}` then `{move,{atom,ok},{x,0}}` | **nothing** — `f()` returns `ok`. `grep assert codegen/beam_asm.zig` → **0 matches** | — |
| wasm | `(func $f (result i32) i32.const 0)` — the body is gone | **nothing.** `grep assert codegen/wat.zig` → **0 matches** | — |
| all, **test mode** | `__bp_assert(cond, msg, loc)` / `erlang:error({bp_assert, Msg, Where})` | a tagged throw the runner catches per test, then continues | `commonJS.zig:2418-2425`, `erlang.zig:3637-3645` |

**Options.**

| | Rule | Consequence |
|---|---|---|
| A | `assert` is always fatal, on every backend, carrying the message and the `file:line` | node reuses the `__bp_assert` helper it already has, rethrowing instead of recording; erlang reuses the `{bp_assert, Msg, Where}` raise it already builds; beam and wasm need an implementation (a `erlang:error/1` call and an `unreachable`, respectively) |
| B | `assert` is debug-only, compiled out outside test mode | node and erlang must stop emitting anything; beam and wasm already comply. Cheapest, but it makes `assert` useless in a shipped program |
| C | Keep the per-backend behaviour and document it | Not viable — on beam and wasm there is nothing to document but the absence |

**Recommendation: A.** The helper exists on both backends that emit anything, it fixes erlang's
dropped message and location for free, and a construct that silently vanishes on half the targets
is exactly the blind spot the module-health spec's step 5 is about (no snapshot asserts on stdout
on any backend). If B is chosen instead, `assert` must be removed from the language reference's
list of runtime checks and the two backends that still emit must be changed — B is not the
no-work option it looks like.

**Closes:** `codegen-builtins-aggregates.md:90` (`assert_with_message`, the one `uncertain` row in
class (d)) and the "beam `assert` bodies dropped" class in report 3.5.

**Acceptance:**
- [ ] `assert false, "msg"` behaves identically on all four backends outside test mode
- [ ] The failure names the message and the `file:line` on every backend that fails
- [ ] Test mode is unchanged: the runner catches per test and continues

---

### Step 3 — Act on the per-report residuals

Each report is file-disjoint and can be handled in its own branch. For every non-`ok` row that is
not withdrawn: re-derive it at HEAD, then fix the test (`wrong-test`, `weak`, `duplicate`,
`skip-undocumented`, `legacy-syntax`) or the compiler (`wrong-output`) — or register the
`wrong-output` in the type-system / codegen-hardening spec with the snapshot name when the fix is
large.

**Size of the backlog.** 783 evidence rows across the twelve reports, **777 open** (4 rows are
re-graded `ok` inside non-`ok` tables, 2 are withdrawn). Counting method: for each table, the
header cell containing `verdict` fixes a column index and every data row's value in that column is
read; the twelve summary "Verdict counts" tables are excluded; a composite verdict
(`uncertain (semantics) + weak`) takes its worst class, matching each report's own stated rule.

| Class | Rows | What closing one means |
|---|---|---|
| `wrong-output` | 397 | a compiler fix, or a registration in the type-system / codegen-hardening spec |
| `weak` | 182 (180 open) | the snapshot does not prove what the test claims — often fixed for free by step 4 |
| `wrong-test` | 126 | the test name or source does not match what it checks |
| `duplicate` | 30 | delete one of a pair |
| `known` | 25 | already tracked elsewhere (erlc output leak, `deallocate` without `allocate`, the wasm RUN LOG stub) |
| `uncertain` | 14 | 7 answered by step 2; 7 are separate questions, listed below |
| `legacy-syntax` | 4 | `parser.md` only — spec 05 items 5.12/5.13 |
| `skip-undocumented` | 1 | — |
| `orphan` | **0** | declared in 8 summary tables, never once an evidence row |

`misnamed`/`naming` is **not** a verdict class — naming problems are graded `wrong-test` or `weak`.
`withdrawn` is a disposition, not a verdict.

**Per report.** Open counts, descending. The pointer is the heading to read; do not copy the
tables — they are the audit record and stay in `1.0.1-beta/06-snapshot-review/`.

| Batch | Report | Open | By class | Read from |
|---|---|---|---|---|
| 3.1 | `codegen-features.md` | **168** | wrong-output 121 · weak 34 · uncertain 5 · wrong-test 5 · known 3 | `## All non-ok findings (per slug)` (152 rows), indexed by `## Systemic root causes` (17 rows, `S1…S17` — fix an `S` once and a block of rows falls) |
| 3.4 | `codegen-values-dispatch-externals.md` | **99** | wrong-output 62 · weak 12 · wrong-test 11 · known 10 · uncertain 2 · duplicate 1 · skip-undocumented 1 | `## Non-ok findings` (95 rows; re-check verdicts are inline as `**Re-check:** …`, not a column) + `## Harness-level findings` (5) |
| 3.2 | `codegen-control_flow.md` | **87** | wrong-output 54 · weak 16 · wrong-test 9 · known 5 · duplicate 2 · uncertain 1 | `## Findings table (all non-ok findings)`. `### Cosmetic (not counted)` is out of scope by the report's own rule |
| 3.10 | `comptime-generics-effects-decorators.md` | **78** | wrong-test 30 · weak 28 · duplicate 11 · wrong-output 8 · uncertain 1 | `## Non-ok findings` (every verdict carries `(H)`/`(M)`/`(L)`; 23 of the 30 `wrong-test` are `(H)`) |
| 3.5 | `codegen-builtins-aggregates.md` | **66** | wrong-output 46 · weak 13 · wrong-test 3 · known 2 · uncertain 2 | `## Findings table (all non-ok items)` (61) + `## Harness-level findings` (5). The `@print` matrix at `:159` has no verdict column |
| 3.8 | `comptime-decls-variants.md` | **59** | weak 30 · wrong-test 15 · wrong-output 13 · uncertain 1 | `## Non-ok findings`, indexed by `## Cross-cutting findings` (`X1…X10`, no verdicts — root causes) |
| 3.7 | `comptime-errors-effects.md` | **48** | wrong-output 24 · weak 9 · wrong-test 9 · duplicate 6 | `## Non-ok findings` (verdicts carry `(low)`/`(med)`/`(high)`; only 2 are `high`) |
| 3.9 | `comptime-templates-types-exprs.md` | **40** | weak 17 · wrong-test 15 · wrong-output 7 · duplicate 1 | `## Non-ok findings` — **stop before `### Withdrawn (moved to ok)`**, the only genuinely closed sub-table in the corpus (2 rows) |
| 3.3 | `codegen-wat-narrowing.md` | **37** | wrong-output 26 · wrong-test 8 · weak 3 | `## Non-ok findings`. The `## WAT executed manually (wasmtime 45.0.0)` table (41 rows) is a run log, not verdicts |
| 3.11 | `parser.md` | **33** | wrong-test 12 · wrong-output 10 · legacy-syntax 4 · weak 4 · duplicate 3 | `## Findings: snapshots that are not ok` — **seven** tables, one per class — **and** `## Findings: errors.zig parse-error tests`, which the first heading does not cover |
| 3.12 | `lsp.md` | 32 rows, **~15 truly open** | wrong-output 12 · weak 9 · duplicate 5 · wrong-test 4 · uncertain 2 | `## Non-ok findings`. Its header blockquote (`:10`) already declares **every `wrong-output` row**, all snapshot-renderer findings and 3 of the 5 duplicates closed — re-derive before counting |
| 3.6 | `codegen-comptime-misc.md` | **30** | wrong-output 14 · wrong-test 5 · weak 5 · known 5 · duplicate 1 | `## 1. Findings table (all non-ok)` |

Two caveats before quoting these numbers:

1. **Rows ≠ tests.** Six reports (3.1, 3.2, 3.4, 3.5, and the two-table reports) carry one row per
   slug × backend, so one test can produce four rows; their own `## Verdict counts` tables are
   per-test roll-ups and will not match. Use the row figures for backlog size, the reports' count
   tables for "how many tests are affected".
2. **Table shapes vary.** The `re-check` column is 4th in some reports, last in others, and inline
   in two; `lsp.md` alone has a `sev` column; `parser.md` splits by class into seven tables. Any
   tooling written for step 1's `--mode=review` must not assume a fixed column index.

**The 7 `uncertain` rows step 2 does not answer.** They are separate design questions and must not
be lost when step 2 closes:

| Row | Question |
|---|---|
| `codegen-builtins-aggregates.md:102` `assert_pattern_with_enum_variant` | Is the `Ok` in `if ((_match instanceof Ok))` the `@Result` variant or a user enum? The source never declares it |
| `codegen-values-dispatch-externals.md:104` `operators_equality_maps_to` | beam emits `is_eq` (arithmetic) where erlang emits `=:=` (exact) — a bug, or guaranteed safe by the typing? |
| `codegen-values-dispatch-externals.md:183` `external_a3_result_template_owned_declare_fn` | The committed RUN LOG `42` came from a stale cache entry; a cold run would blank it. Is the pinned value trustworthy? |
| `comptime-decls-variants.md:139` `path_access_with_bad_tail_raises_focused_error` | The caret points at the last path segment (col 25), not the offending one (col 19) — intended? |
| `comptime-generics-effects-decorators.md:113` `generic_enum_result_t_with_ok_and_err` | Bare generic `Result` accepts any instantiation while bare `Option.None` is rejected against `Option<i32>`. Is bare `Result` legal? |
| `lsp.md:103` `hover_interface_method` | `abs` is declared in `interface Signed`, not `I32` — should the hover footer name the declaring or the receiver interface? |
| `lsp.md:104` `completion_decorator_record` | `usePost` is missing from its own completion list — correct, or a sign the degraded path drops `val` bindings? |

**Ordering.** Batches touching `comptime/infer.zig` (3.7–3.10) conflict with each other and with
the type-system spec: land the shared checker root causes once, first. Two rows also close from
other specs — the `pick`/`omit`/`partial`/`mergeRecords` intercept shadowing user fns (3.6) and
"user `pick` vs the builtin" (3.3) are one defect, `comptime/infer.zig:6901`, owned by the
module-health spec's step 6a; the "dangling import for template-only symbols" (3.6) is its step 6d.

**Acceptance (per batch):**
- [ ] Every non-`ok` row re-derived at HEAD and closed: fixed, registered elsewhere with the
      snapshot name, or struck with a written reason
- [ ] A short status line appended to the report saying what closed it

### Step 4 — The comptime AST renderer

`comptime/snapshot.zig` serialises the AST from syntax rather than from inference, which makes a
large share of the `weak` rows in 3.7–3.10 unverifiable rather than wrong:

- every non-`.named` `TypeRef` and every unbound var prints `"?"`; `.func` prints its return type
  only;
- `"id"` is always `0`;
- interfaces, `implement` blocks, record/enum methods, variants, sections and doc comments are
  never serialised;
- fn bodies show raw source, `case` binding names are dropped, and the `indent` field holds a
  binding name.

Render from the inferred types instead, and serialise the declaration kinds that are missing. Many
`weak` verdicts become `ok` (or a real `wrong-output`) with no test change — the `weak` class is
182 rows, the second largest in the corpus, and most of it lives in the four reports this step
covers.

**Acceptance:**
- [ ] No `"?"` in a snapshot for a type inference resolved
- [ ] Interfaces, implements, methods and variants appear in `TYPED AST JSON`
- [ ] The re-recorded snapshots reviewed, not blanket-accepted

### Step 5 — Deduplicate the comptime copies

The comptime suite writes the same file under four backend directories (`comptime/tests/helpers.zig`
keeps them only to avoid churn). At HEAD: `comptime/{beam,wasm}` hold 199 files each and
`comptime/{node,erlang}` 305 (199 success + 106 error) — 1008 files for 305 unique snapshots, all
byte-identical. Record each once under a backend-independent path, delete the redundant files and
update `comptime/AGENTS.md`.

**Acceptance:**
- [ ] 305 comptime snapshot files, not 1008
- [ ] `zig build test` green and the snapshot paths documented

### Step 6 — Close

- [ ] All four step-2 decisions written down, in the language reference or `codegen/AGENTS.md`
- [ ] Every reviewed row closed: fixed, or registered in the type-system / codegen-hardening spec
      with the snapshot name
- [ ] 0 empty and 0 source-only snapshots unless the test documents why (holds today — keep it)
- [ ] `zig build test` green with `compiler-core/.botopinkbuild/runtime-cache` deleted before the
      run, and again on the warm cache it leaves: same pass count, 0 leaks, 0 `.snap.md.new` on disk
- [ ] Orphan list empty from a traced run
- [ ] `AGENTS.md` of the snapshot-producing directories and `scripts/AGENTS.md` updated

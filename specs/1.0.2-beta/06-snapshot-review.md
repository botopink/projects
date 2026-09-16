# Spec 06 — Snapshot review, residuals

**Version:** 1.0.2-beta
**Priority:** medium — the harness is trustworthy now; what is left is the backlog it exposed
**Depends on:** nothing to start. Step 3 overlaps the type-system spec (checker root causes) and
the codegen-hardening spec (per-backend output and WAT execution) — fix a shared root cause once,
in one branch, before the per-report cleanup

---

## Objective

Finish what [`1.0.1-beta/06-snapshot-review.md`](../1.0.1-beta/06-snapshot-review.md) started: the
tooling that keeps the snapshot set honest, the review rows the fix waves did not reach, the
cross-backend semantics the review could not decide, and the deduplication of the comptime copies.

Paths are relative to `repository/botopink-lang/modules/` unless stated otherwise.

## Current state

The harness contract landed: the RUN LOG is decided by exit status, a failing compile fails its
snapshot test (or records a `COMPILE DIAGNOSTIC` when the test is about the failure), a missing
snapshot fails without `BOTOPINK_SNAP_CREATE=1`, every backend is compared in one round, and
`HARNESS_VERSION` is in the runtime cache key. Verified at HEAD:

| | |
|---|---|
| `*.snap.md` | 2442 — **0 zero-byte**, 0 source-only, 0 `*.snap.md.new` on disk |
| documented compile-error skips | 11 slugs, 44 `COMPILE DIAGNOSTIC` snapshots |
| `zig build test` | green, 0 leaks |
| wasm RUN LOGs | still empty — `executeWat` is a stub (spec 06 H5), owned by the codegen-hardening spec |

**The twelve reports in [`1.0.1-beta/06-snapshot-review/`](../1.0.1-beta/06-snapshot-review/) were
written before the fix waves.** Their evidence tables are the audit record and are kept verbatim,
but a row is no longer proof of a live defect: re-derive each one against HEAD before acting.

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

Four questions block rows in several reports at once; each currently shows up as "the four
backends disagree and nothing says which is right". Decide them, write the decision down, then the
rows become ordinary `wrong-output` fixes.

1. **`@print` text.** erlang/beam use `~p`, so a string prints `<<"hi">>` where node prints `hi`.
   Nothing documents textual equality across backends as a goal — but several tests assert it.
2. **The value of a block / tail expression.** For a `case` arm that is a block with no `break`,
   node discards it, erlang returns the inner value, beam returns a fun and wasm drops it; the
   comptime snapshot types it `?`.
3. **The null representation.** beam emits `{atom,nil}` while its own option helpers test
   `undefined`; wasm carries `?i32` null as `i32.const 0`, indistinguishable from a real 0.
4. **`assert` severity outside test mode.** `console.assert` prints and continues; erlang raises
   `{badmatch,false}`; test mode throws.

**Acceptance:**
- [ ] Each of the four written down (language reference or `codegen/AGENTS.md`), with the backends
      made to agree or the divergence stated as intended
- [ ] The tests that assert cross-backend equality either hold or are rewritten to the decision

### Step 3 — Act on the per-report residuals

Each report is file-disjoint and can be handled in its own branch. For every non-`ok` row that is
not withdrawn: re-derive it at HEAD, then fix the test (`wrong-test`, `weak`, `duplicate`,
`skip-undocumented`, `legacy-syntax`) or the compiler (`wrong-output`) — or register the
`wrong-output` in the type-system / codegen-hardening spec with the snapshot name when the fix is
large.

What each report still carries, by class. "Closed" means the wave that owned the class landed, not
that every row was re-checked.

| Batch | Report | Closed by the 1.0.1-beta waves | Still open |
|---|---|---|---|
| 3.1 | `codegen-features` | harness provenance notes; beam register clobber and `%%`-comment calls; erlang `default fn` injection and variant patterns; wasm module validity | beam semantic gaps (`yield`→`return`, closure captures and destructured params lowered to atoms, `await`); multi-arg `@print` on beam/wasm; commonJS destructuring SyntaxErrors, `pub val` not exported, `.d.ts` param types; std `.bp` (`./gleam_stdlib.mjs`, `string:suffix/2`); 34 weak + 4 wrong-test + 2 duplicate. 4 uncertain cells → step 2 |
| 3.2 | `codegen-control_flow` | harness (H1/H2 and the 24 zero-byte files); erlang guards, variant patterns, loops; beam registers; wasm validity | commonJS invalid JS (`return for …`, `return return`, `return continue`, `if ()`); beam `break v`/`continue`, `lists:foreach` arity, missing `allocate`; type questions (else-less `if` as a value, `try` in a non-`#[@result]` fn); 6 weak + 8 wrong-test + 2 duplicate. 1 uncertain → step 2 |
| 3.3 | `codegen-wat-narrowing` | parser gaps behind 4 zero-byte slugs; beam operand staging; wasm module validity | beam field-access fall-through label, anon record literal, `.len`, live-count rejections; wasm `$__print_i32` sign fix-up (`-12` → `-21`), narrowing binder as a global, `?i32` null carrier; commonJS `.len` → `undefined`; std `.bp` `slice`; checker gaps (`slice` arity, user `pick` vs the builtin, `!opt` narrowing); ~6 weak |
| 3.4 | `codegen-values-dispatch-externals` | harness H1–H3/H5; beam register clobber; erlang exports and patterns; wasm emission | beam `declare fn` externals as local stubs returning `ok`, name mangling, `self` as an atom; erlang non-short-circuit `and`/`or`, imported record ctor, star-import call; commonJS/TS typedef shape; checker accepts arity mismatch on a trailing lambda; 16 duplicate + 26 weak + ~5 misnamed. 2 uncertain → step 2 |
| 3.5 | `codegen-builtins-aggregates` | harness H1/H2/H4 and the vacuous-pass hole; parser gaps behind 4 dead tests | beam `assert` bodies dropped, `todo`/`panic` payload lost, `..rest` spread, live-count rejections; erlang multi-arg `io:format`, records matched as tuples, `todo` charlist; commonJS `val assert` binding, list-pattern checks, ctor without `new`; wasm top-level `val` initializers dropped (every global a 0 placeholder); ~20 weak. 2 uncertain → step 2 |
| 3.6 | `codegen-comptime-misc` | harness H1–H4/H6; beam parameter clobber and module-level vals; erlang module-level vals; wasm emission | typedef emitter (`p.typeName` empty, `i32` leaked); dangling import for template-only symbols; the comptime validator rejecting every identifier and the `pick`/`omit`/`partial`/`mergeRecords` builtin intercept shadowing user fns; missing `ref/1` in the template host; 1 duplicate + 5 weak |
| 3.7 | `comptime-errors-effects` | harness outcome check; the `default` keyword blocking one fixture | the checker rows: `TypeError` constructors with no location (~12), operand-first unification swapping expected/found, effect rules R3/R4/R10/R12/R15, exhaustiveness carets on the arm body, the stale `Available std modules: bool.` hint, no numeric-operand check; 9 weak + 9 wrong-test + 6 duplicate; the diagnostic-renderer gutter and constraint join |
| 3.8 | `comptime-decls-variants` | harness outcome check (10 source-only files); comptime folding (`3.14 * 2.0 → 0`) | checker: unannotated methods typed by a fresh var and unknown methods accepted, record-update spread positional, `case` type never unified with its arms, returns never unified; hard-coded `@Option<T>` message; `methodNotActive` never constructed; ~6 wrong-test + 30 weak. 1 uncertain (caret on the last path segment) |
| 3.9 | `comptime-templates-types-exprs` | harness outcome check; 2 rows withdrawn (`COMPTIME REPLY` now pins them) | checker: `case` fresh var, `val assert … catch` swallowing unbound/pattern errors (8 rows), returns not unified, `comptime { break e; }` typed `void`, pipeline through a bare fn ident; nested template expansion not recursed (a hidden miscompile); the lossy AST renderer (step 4); ~10 test-quality rows |
| 3.10 | `comptime-generics-effects-decorators` | harness outcome check (22 source-only files); parser gaps in ~18 fixtures | checker: returns not unified, case payload bindings untyped, method bodies best-effort, `@field`/`@makeRecord`/`@RecordKeys` types, order-sensitive record unification behind `pick`, generic arity/default gaps, type-guard fns typed by the narrowed type; leading-dot enum literal in a decorator body → `erl_lint {unbound_var,…}`; `assertInfersOk` building an env without `templateEval`; 11 duplicate + 28 weak + ~14 naming. 1 uncertain |
| 3.11 | `parser` | **the whole location class** (multi-line/`\\` token lines, interpolation hole spans, tagged-call keys, the col-as-byte-offset bug) and **the 4 legacy-syntax rows** (spec 05 5.12/5.13); both vacuous `errors.zig` tests | `pub_fn_type_meta_kind_{single,multiple_pipe}_constraints` (names say `pub fn`, source has `"isPub": false`); `use_multiple_hooks_in_function` (a duplicate of three single-hook tests); the untested areas the report flags — comment attachment (0 coverage) and node-`id` uniqueness |
| 3.12 | `lsp` | **all wrong-output rows** (interface-member extraction, semantic-token classes, document-symbol kinds and children, signature-help labels, field details, end-of-identifier cursors), the snapshot-renderer gaps (target-file underline, WorkspaceEdits, symbol ranges) and 3 of the 5 duplicates | `hover_fn_polymorphic` and `rename_ranges_correct` (still duplicates of their twins); the weak rows whose fixtures do not type-check, so a degraded path is pinned as the answer. 2 uncertain rows → design questions |

Batches touching `comptime/infer.zig` (3.7–3.10) conflict with each other and with the type-system
spec: land the shared checker root causes once, first.

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
`weak` verdicts become `ok` (or a real `wrong-output`) with no test change.

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

- [ ] Every reviewed row closed: fixed, or registered in the type-system / codegen-hardening spec
      with the snapshot name
- [ ] 0 empty and 0 source-only snapshots unless the test documents why (holds today — keep it)
- [ ] `zig build test` green with `compiler-core/.botopinkbuild/runtime-cache` deleted before the
      run, and again on the warm cache it leaves: same pass count, 0 leaks, 0 `.snap.md.new` on disk
- [ ] Orphan list empty from a traced run
- [ ] `AGENTS.md` of the snapshot-producing directories and `scripts/AGENTS.md` updated

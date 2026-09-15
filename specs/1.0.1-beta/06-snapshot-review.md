# Spec 06 — Snapshot review

**Version:** 1.0.1-beta
**Priority:** high — the snapshots are the oracle of most of the suite
**Depends on:** spec 01 (a clean run, so every `.snap.md.new` on disk is a real mismatch)
**Feeds:** spec 03 (wrong RUN LOGs / codegen bugs found here are fixed there)

---

## Objective

Every `*.snap.md` and every `*.snap.md.new` is reviewed against the test that produces it,
and each one gets a verdict: the recorded output is what that test is meant to show — or
it is fixed, re-recorded, deleted, or registered as a known bug. A green suite then means
"the compiler does the right thing", not "the compiler does what it did when the snapshot
was first written".

Paths are relative to `repository/botopink-lang/modules/`.

## Current state

2442 `*.snap.md`, all tracked; 0 `*.snap.md.new` on disk; no snapshots in the sibling libs.

| Suite | Directory (`*/snapshots/`) | Files | Sections | Producer |
|---|---|---|---|---|
| codegen | `compiler-core/snapshots/codegen/{commonJS,erlang,beam,wasm}` | 278 × 4, plus `test_runner.snap.md` in commonJS and erlang only | `SOURCE CODE`, `COMPTIME ERLANG` / `COMPTIME REPLY`, `COMPTIME VALUES`, `JAVASCRIPT` / `ERLANG` / `BEAM ASSEMBLY` / `WASM TEXT`, `RUN LOG` | `compiler-core/src/codegen/snapshot.zig` |
| codegen errors | `compiler-core/snapshots/codegen/errors/<target>/` | 4 (1 test) | `SOURCE CODE`, `ERROR` | same |
| comptime | `compiler-core/snapshots/comptime/{node,erlang,beam,wasm}` | 199 × 4 | `SOURCE CODE`, `COMPTIME ERLANG` / `COMPTIME REPLY`, `COMPTIME VALUES`, `BOTOPINK TRANSFORM CODE`, `TYPED AST JSON` | `compiler-core/src/comptime/snapshot.zig` |
| comptime errors | `compiler-core/snapshots/comptime/{node,erlang}/errors` | 106 × 2 | `SOURCE CODE`, `ERROR` | `compiler-core/src/comptime/tests/helpers.zig` |
| comptime templates | `compiler-core/snapshots/comptime/templates` | 1 | rendered `TypeError` | `comptime/tests/templates.zig` (`checkText`) |
| parser | `compiler-core/snapshots/parser` | 213 | AST as a bare JSON block (no section headers, no source) | `compiler-core/src/parser/tests/*.zig` |
| lsp | `language-server/snapshots/lsp` | 102 | `SOURCE`, one request section (`HOVER`, `COMPLETION`, `DEFINITION`, `SEMANTIC TOKENS`, …) | `language-server/src/tests/snapshot.zig` |

Facts that shape the review:

- **Missing snapshots are auto-accepted.** `compiler-core/src/utils/snap.zig` `compareOrCreate`
  writes a missing snapshot, prints `snap created:` and the test **passes** — nothing
  forces a review of a first recording.
- **Orphans are invisible.** The file name is the slug of the test description
  (`slugFromSrc` → `slugify`). Renaming or deleting a test leaves the old snapshot behind,
  and nothing reports it.
- **Comptime copies are identical.** The 199 comptime snapshots are byte-identical across
  node/erlang/beam/wasm, and the 106 error snapshots across node/erlang (there is no
  `beam/errors` or `wasm/errors`). The real review set is 306 comptime files, not 1009 — and
  the copies are a candidate for deduplication.
- **Backend sets differ by one file.** `test_runner.snap.md` exists only under
  `codegen/commonJS` and `codegen/erlang`; every other codegen slug exists on all
  4 backends.
- **Parser snapshots carry no source.** A parser snapshot is only the AST JSON; reviewing it
  needs the source string from the test.
- **`.snap.md.new` is not git-ignored** in `repository/botopink-lang/.gitignore` (1.0.0-beta
  had 9 committed by mistake).
- **The comptime runtime exchange is in the snapshots.** Every decorator/template evaluation
  on `erl` writes `COMPTIME ERLANG -- <template|decorator> <fn>` (the lowered body plus the
  `main/0` that encodes the reply, without module header or host glue) and `COMPTIME REPLY`
  (the JSON sent back to compiler-core, or the compile/runtime error text) — see
  `comptime/trace.zig`. `COMPTIME VALUES` lists `ct_N: <declaration> → literal`, so a wrong
  fold shows next to its source (`val pi = comptime 3.14 * 2.0 → 0`). No decorator test
  writes a snapshot today (`decorator_invocation` / `decorator_regression` assert directly),
  so only template exchanges appear.
- The codegen tree is `codegen/<target>/` and `codegen/errors/<target>/` (the reports in
  `06-snapshot-review/` use these paths).
- `scripts/snap_audit.sh --mode={runlog,legacy,values,coverage}` already classifies RUN LOGs
  and legacy surface; it does not relate a snapshot to its test.

Unique review volume: 278 codegen sources × 4 outputs (+ `test_runner` × 2), 306 comptime, 213 parser, 102 lsp.

---

## What "makes sense with the test" means

For each snapshot, open the test that produces it (the test description is the slug) and check:

1. **Name ↔ source.** The `SOURCE CODE` exercises what the test name says (a test named
   `narrow ---- case enum area with print` really narrows on an enum `case` and prints).
2. **Source ↔ output**, per suite:
   - codegen: the generated code implements the source (no `%% unsupported` comments, no
     `undefined`, no stray atoms in place of calls); the `RUN LOG` is the output the
     source's `@print`s must produce — computed by hand, not copied from another backend.
     A source with `@print` and an empty RUN LOG is a finding unless the test documents a skip.
     The 4 backends agree on the RUN LOG, or the difference is explained.
   - comptime: types in `TYPED AST JSON` are the expected ones; each `COMPTIME VALUES` line's
     literal is the fold of the declaration printed next to it; `COMPTIME ERLANG` implements
     the template/decorator body (and `main/0` passes the captures/handle the call site
     implies); `COMPTIME REPLY` is the expansion (`source` / `value` / `custom` /
     `contributions`) the body should produce for those inputs; `BOTOPINK TRANSFORM CODE`
     matches it.
   - errors: the error is the one the test is about (right message, right location), not an
     unrelated earlier error that happens to make the test "reject".
   - parser: the AST matches the source structure (precedence, spans, node kinds).
   - lsp: the response is correct for the cursor/range in the section header.
3. **Test ↔ assertion.** The test asserts something beyond the snapshot when it should
   (e.g. `outcome == .typeError`), and the snapshot would change if the feature broke.

### Verdicts

| Verdict | Action |
|---|---|
| `ok` | nothing |
| `wrong-output` | fix the compiler, re-record; if the fix is large, register it in spec 03 (codegen) or spec 02 (types) with the snapshot name |
| `wrong-test` | name or source does not match the intent — fix the test, re-record |
| `weak` | output right but would not catch a regression — tighten the source or add an assertion |
| `skip-undocumented` | empty/partial output by design — document the skip in the test |
| `orphan` | no test produces it — delete |
| `duplicate` | same source and output as another snapshot with no added coverage — merge or delete the test |

---

## First-pass review (read-only, all suites)

A first pass reviewed every suite against its tests. Generated code was executed outside the
repo (`node`, `erlc`/`erl`, `erlc +from_asm`, `wasmtime`) and hand-computed outputs were compared
with the recorded RUN LOGs. Full evidence tables (quoted lines, expected vs actual, suggested
fix location) are in [`06-snapshot-review/`](./06-snapshot-review/). Some checker probes used a
`zig-out/bin/botopink` built one day before HEAD; those claims also cite HEAD source lines.
**Re-confirm each finding before fixing it.**

| Report | Scope | Unit | ok | wrong-output | wrong-test | weak | duplicate | other |
|---|---|---|---|---|---|---|---|---|
| [`codegen-features`](./06-snapshot-review/codegen-features.md) | `codegen/tests/features.zig` | test×backend cells (252) | 130 | 108 | 4 | 3 | — | 4 uncertain, 3 known |
| [`codegen-control_flow`](./06-snapshot-review/codegen-control_flow.md) | `control_flow.zig` | tests (44) | 1 | 26 | 8 | 6 | 2 | 1 uncertain |
| [`codegen-wat-narrowing`](./06-snapshot-review/codegen-wat-narrowing.md) | `wat.zig` + `narrowing.zig` | tests (45) | 8 | 25 | 9 | 3 | — | — |
| [`codegen-values-dispatch-externals`](./06-snapshot-review/codegen-values-dispatch-externals.md) | `values`/`dispatch`/`externals.zig` | cells (204) | 62 | 60 | 11 | 26 | 16 | 16 skip-undoc, 11 known, 2 uncertain |
| [`codegen-builtins-aggregates`](./06-snapshot-review/codegen-builtins-aggregates.md) | `builtins`/`aggregates.zig` | tests (53) | 5 | 39 | 4 | 5 | — | — |
| [`codegen-comptime-misc`](./06-snapshot-review/codegen-comptime-misc.md) | `codegen/tests/comptime.zig` + misc + codegen orphans | tests (36) | 6 | 14 | 5 | 5 | 1 | 5 known |
| [`comptime-errors-effects`](./06-snapshot-review/comptime-errors-effects.md) | `infer_errors`/`exhaustiveness`/`effect_*` | tests (92) | 44 | 24 | 9 | 9 | 6 | — |
| [`comptime-decls-variants`](./06-snapshot-review/comptime-decls-variants.md) | `infer_decls`/`variants` | tests (81) | 22 | 13 | 15 | 30 | — | 1 uncertain |
| [`comptime-templates-types-exprs`](./06-snapshot-review/comptime-templates-types-exprs.md) | `templates`/`types`/`infer_exprs` | tests (103) | 61 | 6 | 15 | 20 | 1 | — |
| [`comptime-generics-effects-decorators`](./06-snapshot-review/comptime-generics-effects-decorators.md) | typeinfo/effects/generics/defaults/narrowing/decorators + comptime orphans | tests (161) | 84 | 7 | 30 | 27 | 11 | 2 uncertain |
| [`parser`](./06-snapshot-review/parser.md) | 213 parser snapshots | snapshots | 182 | 9 | 10 | 4 | 3 | 4 legacy-syntax, 1 uncertain |
| [`lsp`](./06-snapshot-review/lsp.md) | 102 LSP snapshots | snapshots | 70 | 12 | 4 | 9 | 5 | 2 uncertain |

No orphan snapshots and no test without its snapshot, in any suite. The comptime copies are
byte-identical for all 199 + 106 slugs (`comptime/tests/helpers.zig:91-97` keeps 4 directories
only to avoid churn).

### Harness defects — the suite is green on outputs nobody checks

Verified against HEAD while consolidating:

| # | Defect | Where | Effect |
|---|---|---|---|
| H1 | BEAM success check inverted: `if (assemble_result.len == 0) return ""` (also for aux modules). A successful `erlc +from_asm` prints nothing | `codegen/runtime.zig:365`, `:375` | Fresh runs never execute BEAM. Every non-empty BEAM RUN LOG comes from the git-ignored `compiler-core/.botopinkbuild/runtime-cache` (470 entries, oldest 2026-06-27). A clean checkout / CI records empty BEAM RUN LOGs |
| H2 | Any `erlc` output (warnings included) returns an empty RUN LOG | `codegen/runtime.zig:305-314` | Erlang programs with a warning never run; also the 13 leaks of spec 01 |
| H3 | Parse/type errors produce no output and the test still passes: codegen backends `continue` on `.parseError`/`.typeError`; comptime writes only `SOURCE CODE`; the compare trims both sides | `codegen/commonJS.zig:52-53` (and siblings), `comptime/snapshot.zig:640-642`, `utils/snap.zig` | **116 codegen snapshot files are 0 bytes (29 tests × 4)** and **39 comptime snapshots are source-only** — all are failing programs recorded as passing (top-level `@print`, `if`/`loop` without parentheses, `default` as a name, `struct`, `as`/`Ok(..)` patterns, user `fn pick` shadowed by the builtin) |
| H4 | Missing snapshot auto-created, test passes | `utils/snap.zig` `compareOrCreate`; LSP `snapshot.zig` | First recordings never reviewed |
| H5 | `executeWat` stub | `codegen/runtime.zig` | Every wasm RUN LOG empty; most WAT modules are invalid when run (spec 03 step 2) |
| H6 | Parser error tests return early when no error detail is produced | `parser/tests/helpers.zig:109` | "assignment without val" and "reserved word in expression" compare nothing |
| H7 | `language-server/src/tests/snapshot_test.zig` not imported by `test_root.zig` (and would not compile); `src/tests/root.zig` is a stale copy | language-server tests | dead tests |
| H8 | `BOTOPINK TRANSFORM CODE` only written when a comptime `val` exists | `comptime/snapshot.zig` | the expansion is visible in `COMPTIME REPLY`, but the program after splicing it (and after `@emit` contributions) is not shown for modules without comptime `val`s |
| H9 | `assertComptimeAst` / `assertJs` never check the outcome (`comptime_err`, validation errors) | `comptime/tests/helpers.zig`, `codegen/tests/helpers.zig` | e.g. `comptime_block_with_break` records a validation error as success |

### Root causes behind the `wrong-output` findings (reported, re-confirm before fixing)

**Type checker (`comptime/infer.zig`, `comptime/eval.zig`)** → spec 02
- `return` value never unified with the declared return type (`infer.zig:2867-2870`, `5459-5561`): `fn f() -> i32 { return "s"; }` passes; hides many "happy path" tests.
- `case` expression type is a fresh variable, never tied to its arms (`infer.zig:7468`).
- `&&`/`||`/`!` errors swap expected/found (`unifyAt` operand-first, `infer.zig:5372-5373`, `5411`).
- `comptime val` folds every binary op as integer (`eval.zig:85-96`): `pi`/`banner` fold to `0`.
- Type-guard fn `-> n is T` typed as `T` instead of `bool` (`infer.zig:2731`).
- `@field` returns the record type; `@RecordKeys` returns `Array<string>` not unifying with `string[]`; `@makeRecord(ident)` unresolved.
- Generic enum unit variants lose type args (`Option.None` : `Option`); case pattern bindings not typed from variant fields.
- Method-body errors skipped; methods without return annotation typed `?`; unknown methods and unknown field types accepted.
- Record update spread positional, ignores labels (`infer.zig:7201`).
- `effect-missing-wrapper` can never fire for primitive returns (`infer.zig:2796`); R12 id clash with `diagnostics.zig`.
- Builtin `pick` (type manipulation) shadows user functions named `pick`.
- Many error diagnostics carry no location (implement/interface, extend, pub-default, RG3, `1 + true`).

**Parser / lexer** → spec 05 (or a parser spec)
- Parse error location stored as column but printed as byte offset: every error lands on line 1 (`print.zig:155`).
- Multi-line / backslash strings stamped with the end line (`lexer.zig:372-388`); `${…}` hole expressions positioned relative to the hole (`exprs.zig:1729`).
- Retired `@[` opener still accepted (`parser.zig:307-309`); `@external(node, …)` and snake_case left in 4 parser fixtures.

**commonJS** → spec 03
- std `.slice` is a `default fn` requiring `./gleam_stdlib.mjs` (not shipped) and patches `Array/String.prototype.slice` (`libs/std/src/primitives.bp`); any `.slice` crashes.
- Destructuring with `..` emits `{ x, ... }` (SyntaxError); `return for …` / `return continue` / `return if (`; `if () return null;`.
- `pub val` not exported; enum payload destructured by binding name; `.len` → `undefined`; typedefs `x: ` without type.

**erlang** → spec 03
- Case guards dropped; enum/variant patterns emitted as `{tag, Circle, R}` (variable, not atom).
- Multi-argument `@print` format string takes 1 argument (badarg); string `+` as arithmetic.
- `default fn` instance methods called as undefined local functions (`slice/3`, `all/2`, …).
- `string:suffix/2` does not exist in OTP (`primitives.bp` l.143-144); `&&`/`||` → `and`/`or` (no short-circuit); `lists:foreach` with a 2-arity fun; `try … catch throw` → `{ok,{error,…}}`.

**beam** → spec 03 (largest group)
- Register clobbering: operands staged into `{x,0}` before saving — tuple elements, call arguments, function parameters and `self` overwritten (`lowerTupleLit`, `materializeCallArgs` use `scratch_base = cur_arity`; ~54 function bodies affected). Explains `{20,20}`, `both(false,false)`, `lengthSq 90.0`, string compare with itself.
- `case` arms without a match test (enum unit variants, string literals).
- `declare fn` externals become local functions returning `ok`; unresolved method/local calls emitted as `%%` comments.
- `null` → `nil` but option helpers test `undefined`; `assert` dropped; `yield` → `return`; multi-arg `@print` prints the first argument only; validator rejections (`not_live`, `uninitialized_reg`).

**wasm** → spec 03 step 2
- Invalid modules: `(local …)` mid-body, values left on the stack, missing functions, `(param $ i32)`, specialized functions without `(result i32)` (`transform.zig:272`), top-level array/tuple/call `val`s as `i32.const 0` placeholders.
- String `==` by pointer, string `+` as pointer sum, strings/bools printed as numbers; `$__print_i32` prints `-12` as `-21`.

**language server** → new LSP item
- `collectInterfaceMembers` (`engine.zig:4099-4156`) leaks comments, attributes and body locals into completion/hover details.
- Document symbols report `val X = enum/record` as `Variable`; signature-help labels are types only (active-param highlight wrong); semantic tokens classify record fields and `true` as `variable`.
- `type_definition_record_val` cursor on whitespace records `null` as the expected answer.

**Test quality (all suites)**
- Test names not matching sources (lambda tests without lambdas, `pipeline_with_labeled_args` without labels, `missing_string_patterns_with_wildcard` without wildcard, `star_fn_*` naming).
- Descriptions containing `": "` truncate slugs (`t_inside_future_…`).
- ~100 `weak` tests: no `@print`/`main`, empty responses, trivially constant sources.
- ~45 duplicates (byte-identical sources/outputs across files, e.g. `generic_defaults.zig` vs `parser/tests/effect_rejections.zig`, `rf*` vs `effect_future`).

---

## Steps

### Step 0 — Fix the harness first (H1–H9)

Without this, fixing the compiler changes nothing visible and a re-review is meaningless.

1. H1: invert the BEAM checks (fail on non-zero exit / non-empty diagnostic, not on empty output).
2. H2: separate `erlc` warnings from errors (exit status), keep running on warnings; put
   compiler errors in the RUN LOG (or a `COMPILE ERROR` section) instead of dropping them.
3. H3/H9: a codegen or comptime snapshot test fails when the program does not compile unless the
   test explicitly expects an error; record the diagnostic in the snapshot.
4. H4 (see step 1), H6, H7, H8 (write `BOTOPINK TRANSFORM CODE` whenever a template expanded or a
   decorator contributed, not only when a comptime `val` exists).
5. Clear `.botopinkbuild/runtime-cache` and run the suite from a cold cache; the cache key must
   include the harness version so stale entries cannot mask a change.
6. Expect a large wave of `.snap.md.new`: triage it with step 2.

### Step 1 — Tooling

1. Record touched snapshots: an opt-in env var (e.g. `BOTOPINK_SNAP_TRACE=<file>`) makes
   `utils/snap.zig` and `language-server/src/tests/snapshot.zig` append every checked path.
   Run the suite with it and diff against `find … -name '*.snap.md'` → orphan list (the first
   pass found none; this keeps it that way).
2. Add `*.snap.md.new` to `repository/botopink-lang/.gitignore`.
3. Stop auto-accepting: a missing snapshot fails the test unless an explicit env var
   (e.g. `BOTOPINK_SNAP_CREATE=1`) is set.
4. Add a `--mode=review` to `scripts/snap_audit.sh` that emits one row per unique snapshot
   (`suite`, `slug`, `test file:line`, `path(s)`, `verdict`), seeded from the first-pass reports.

**Acceptance:**
- [ ] Orphan list produced from a full run
- [ ] `.snap.md.new` ignored; missing snapshot fails without the create flag
- [ ] Review worksheet generated for all suites

### Step 2 — `.snap.md.new` triage

After step 0, run `zig build test` from a cold cache and review every `.snap.md.new` written:
diff it against the `.snap.md`, decide fix (accept) or regression (fix the code), using the
first-pass reports as the expected values. Zero `.snap.md.new` left on disk at the end.

### Step 3 — Act on the first-pass findings, by report

Each report is file-disjoint and can be handled in its own branch. For every non-`ok` row:
re-confirm, then fix the test (`wrong-test`, `weak`, `duplicate`, `skip-undocumented`,
`legacy-syntax`) or the compiler (`wrong-output`), or register the `wrong-output` in spec 02/03
with the snapshot name when the fix is large.

| Batch | Report | Done |
|---|---|---|
| 3.1 | `codegen-features` | [ ] |
| 3.2 | `codegen-control_flow` | [ ] |
| 3.3 | `codegen-wat-narrowing` | [ ] |
| 3.4 | `codegen-values-dispatch-externals` | [ ] |
| 3.5 | `codegen-builtins-aggregates` | [ ] |
| 3.6 | `codegen-comptime-misc` | [ ] |
| 3.7 | `comptime-errors-effects` | [ ] |
| 3.8 | `comptime-decls-variants` | [ ] |
| 3.9 | `comptime-templates-types-exprs` | [ ] |
| 3.10 | `comptime-generics-effects-decorators` | [ ] |
| 3.11 | `parser` | [ ] |
| 3.12 | `lsp` | [ ] |

Batches touching `comptime/infer.zig` (3.7–3.10) or `codegen/beam_asm.zig` (3.2–3.6) conflict:
fix the shared root causes above once, in one branch, before the per-report cleanup.

### Step 4 — Deduplicate comptime copies

The comptime suite writes the same file under 4 backend directories (byte-identical for all
slugs). Record it once (backend-independent path) and delete the redundant files; update
`comptime/AGENTS.md`.

### Step 5 — Close

- [ ] Harness defects H1–H9 fixed
- [ ] Every first-pass row closed: fixed, or registered in spec 02/03 with the snapshot name
- [ ] 0 empty and 0 source-only snapshots unless the test documents why
- [ ] `zig build test` green from a cold runtime cache, 0 `.snap.md.new` on disk
- [ ] `AGENTS.md` of the snapshot-producing dirs and `scripts/AGENTS.md` updated

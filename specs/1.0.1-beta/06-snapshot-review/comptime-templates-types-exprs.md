# Snapshot review: comptime `templates.zig` / `types.zig` / `infer_exprs.zig` + `fail_span_in_template`

Repo: `repository/botopink-lang`, paths relative to `modules/compiler-core/`.
Review mode: read-only. No `zig build`. Extra evidence came from the CLI `zig-out/bin/botopink`, running
`botopink check` / `botopink build` on throwaway projects in the scratchpad. These runs are labelled **probe**.
First pass: prebuilt binary from 2026-09-14, which could not run template bodies.
Re-check: binary rebuilt from HEAD (`96ff203`, 2026-09-15 19:48); template bodies now run, so template
expansions were verified against `COMPTIME REPLY` and against the `out/main.js` that `build` writes.

> **Status (1.0.1-beta close):** the harness defects this report leans on (H1-H10) are fixed: the RUN LOG is decided by the process exit status, an `erlc` warning no longer blanks a log, a program that does not compile fails its snapshot test (or records a `COMPILE DIAGNOSTIC`), every backend is compared in one round, and the 0-byte snapshots are gone. The checker rows below predate the comptime-folding wave and are otherwise untouched - re-derive each one at HEAD before acting on it. Residuals are tracked in [`1.0.2-beta/09-review-tooling/README.md`](../../1.0.2-beta/09-review-tooling/README.md). The tables below are the audit record and are kept verbatim.

## Re-check summary (2026-09-15, HEAD `96ff203`, rebuilt binary)

Scope: every non-`ok` row (42), cross-cutting findings C1–C10, top 10. Every probe was re-run
(scratchpad `rev-ct-templates-generics/`). Test line numbers in the three test files are unchanged.

| classification | non-ok rows | C1–C10 |
|---|---|---|
| confirmed | 34 | 9 |
| corrected | 6 | 1 |
| withdrawn | 2 | 0 |
| uncertain | 0 | 0 |

Notable changes:
- **C1 corrected.** Runtime-evaluated template bodies now show their result in `COMPTIME REPLY -- template <fn>`
  (e.g. `{"source": "\"hey!\"", "kind": "code"}`, `{"value": 6, "kind": "value"}`). Still invisible:
  (a) expansions done by the V1 inspection driver (`return <@Expr param>`, `return @expr(…)`, `return @code("…")`,
  `infer.zig:3599` `classifyTemplateBody`), which produce no trace section at all;
  (b) the post-reply hole substitution (`__bp_hole_q_0` → `name`, `infer.zig:3417`);
  (c) `BOTOPINK TRANSFORM CODE`, still gated on `ok.comptime_script` (`snapshot.zig:553`).
- **New hidden miscompile (`net_new_nested_template_call_inside_a_template_body`, now wrong-output).** `build` emits
  `const s = inner();`. The nested `inner("deep")` from the runtime reply is not expanded, its argument is
  dropped, and node fails with `ReferenceError: inner is not defined`. The snapshot stays green because the val
  is still typed `string`.
- **Withdrawn (2):** `runtime_template_body_text_build_end_to_end` and `runtime_template_body_expr_lifts_a_computed_value`.
  COMPTIME REPLY now pins the splice, and `build` agrees (`const s = "hey!";`, `const n = 6;`).
- **Corrected:**
  - `negation_unary_minus` is now a hidden bug: `val n = -"s";` is accepted and typed `string`.
  - `tuple_destructuring_binds_variables`: the suggested "move to top level" fix is invalid, because top-level
    tuple destructuring is a parse error.
  - `local_binding_inside_comptime`: the COMPTIME VALUES format changed, and TRANSFORM CODE shows the block unfolded.
  - `runtime_template_body_lookup_miss_drives_control_flow` and `…parts_with_a_hole…`: the evidence was narrowed.
- Line shifts in `snapshot.zig`:
  - `typeNameFromTypeRef` 236-241
  - case repr 393-400
  - `"id"` 443/454
  - `"indent"` 57/117
  - transform gate 553
  - failed-outcome arms 642-644

  `infer.zig` lines unchanged. The `return` arm spans 5459-5561.
- Counts: ok 61→63, weak 20→17, wrong-output 6→7.
- Probe caveat: `botopink build` prints `Compiled` and exits 0 on type errors, including a template `fail()`, and
  then writes no output. `check` is used for every diagnostic below.

## Counts

| verdict | count |
|---|---|
| ok | 63 (61 + 2 withdrawn weak) |
| wrong-output | 7 (+1: nested template) |
| wrong-test | 15 |
| weak | 17 |
| duplicate | 1 |
| orphan | 0 |
| uncertain | 0 |
| **total tests** | **103** (templates 37, types 34, infer_exprs 32) |

Snapshot-writing tests in the batch: 79, plus `comptime/templates/fail_span_in_template` (re-counted: templates 6 AST + 7 error, types 34, infer_exprs 31 + 1).
- Every `assertComptimeAst` slug has all 4 copies: `comptime/{node,erlang,beam,wasm}/<slug>.snap.md`. All copies are byte-identical (re-checked with `diff -rq`).
- Every `assertTypeErrorSnap` slug has both copies: `node/errors` and `erlang/errors`. They are byte-identical.
- No orphan snapshots: every file under `snapshots/comptime/**` maps to a test slug or a literal path in `src/`.
- No `.new` files.

---

## Cross-cutting findings (root causes behind many per-slug verdicts)

| # | Finding | Evidence | Impact | Re-check |
|---|---|---|---|---|
| C1 | **Template expansions are only partly snapshotted.** Runtime-evaluated bodies show the reply in `COMPTIME REPLY`. V1-driver expansions and hole substitution never show up. `BOTOPINK TRANSFORM CODE` and `COMPTIME VALUES` are still emitted only when `ok.comptime_script != null`, meaning only when a `comptime` val exists. | `src/comptime/snapshot.zig:552` `comptimeMod.trace.render(…, ok.comptime_traces)` always runs. `:553` `if (ok.comptime_script) \|ct\| { … "BOTOPINK TRANSFORM CODE" …}`. Reply examples: `runtime_template_body_text_build_end_to_end` `"source": "\"hey!\""`; `…lookup_miss…` `"source": "\"ok\""`; `…expr_lifts…` `"value": 6`; `…parts_with_a_hole…` `"source": "\"\" + \"<p>\" + __bp_hole_q_0 + \"</p>\""`; `net_new_nested…` `"source": "inner(\"deep\")"`. There are no trace sections for V1 bodies (`template_fn_with_expr_param_compiles_through_the_pipeline`, the nested `inner`), because `classifyTemplateBody` (`infer.zig:3599`) expands them without the runtime. | Runtime replies are now pinned. Still unchecked: pass-through, `@expr` and `@code` expansions; the hole→caller-expr substitution; and whether a reply's code is expanded again (it is not; see the nested row). | **corrected**. The original "never snapshotted" claim is too strong since `4862f9b`. |
| C2 | **`fn_def` param and return types render as `"?"` for any non-`.named` TypeRef.** | `snapshot.zig:236-241` `typeNameFromTypeRef … .named => …, else => "?"`. `TypeRef` also has `array`, `tuple_`, `optional`, `function`, `generic`, `typeparam` and `record_type` (`ast.zig:1485-1505`). Examples: `template_fn_with_expr_param_compiles_through_the_pipeline.snap.md` `"name": "template", "type": "?", "is_comptime": true` … `"return_type": "?"`; `loop_yield_accumulation.snap.md` `"type": "?"` / `"return_type": "?"`; `if_null_check_binding_returns_optional.snap.md` `"type": "?"`; `try_expression_result_type_unified_with_return.snap.md` `"return_type": "?"`. | These are placeholder types in "TYPED AST JSON". `@Expr<string>`, `i32[]`, `?string` and `@Result<i32, string>` cannot be told apart. | confirmed (line 235→236) |
| C3 | **A `case` expression's type is a fresh type variable that is never unified with its arms.** | `src/comptime/infer.zig:7468` `return TypedExpr{ .collection = .{ .loc = loc, .type_ = try env.freshVar(), …case…`. The JSON shows `"return_type": "?"`. Probe: `val label = case 42 { 0 -> "zero"; 1 -> "one"; _ -> "many"; }; val z: bool = label;` is accepted. The `case` JSON also drops the binding name: there is no `indent`/`label` key (`snapshot.zig:393-400`). | The inference bug is real. The "union" tests cannot and do not show a union. | confirmed |
| C4 | **A `comptime { break e; }` block is typed `void`.** | `infer.zig:7524` `bodyType = … typedBody[typedBody.len - 1].expr.getType()`. The last statement is the `break` jump, which is `void`. Probe: `val hash = comptime { break 6364 + 11; }; val z: i32 = hash;` gives `type mismatch: expected i32, got void at main:2:14`. | The typed binding disagrees with the folded value 6375. `build` emits `const hash = 6375;`. | confirmed. Extra detail: the snapshot's TRANSFORM CODE prints the block unfolded (`val hash = comptime { break 6364 + 11; };`), while `val x = comptime 10 + 5;` is folded to `val x = 15;`. |
| C5 | **Record/enum `"id"` is always 0**, even for two distinct types in one module. | `snapshot.zig:443` and `:454` `.id = resolvedTypeId orelse 0`. Outside this batch, `snapshots/comptime/node/narrow_optional_chaining_field_access.snap.md` has `Inner` and `Outer` both at `"id": 0`. Across all `comptime/node` snapshots, `grep` finds 53× `"id": 0` and no other value (the only other `"id"` keys are record *fields* named `id`). | `id` is a meaningless placeholder. In this batch: `Button`, `Color`, `Shape`. | confirmed (line 442→443/454) |
| C6 | **A `return <e>` inside a fn body is not unified with the declared return type.** | `infer.zig:5459-5561`: the `.@"return"` arm infers the value, records lowerings, and returns `.type_ = void` with no unify against the fn's return. Probe: `fn f() -> i32 { return "s"; }` passes `check`. | Fn-body tests (`if_expression_*`, `loop_*`, `negation_*`, `if_null_check_*`) cannot catch wrong body types. The snapshots only render the *declared* signature. | confirmed (arm range 5524→5561) |
| C7 | **`val assert <pattern> = e catch h` swallows type errors and never checks the pattern.** | `infer.zig:7543-7555`: "Use a fresh type variable when the expression can't be inferred (e.g. unbound var)" and `catch \|err\| … freshVar()` for both subject and handler. Probe: `fn f() { val assert 42 = answer catch 0; }` passes; `fn f(x: string) { val assert 42 = x catch 0; }` also passes. | The 8 `assert_pattern_*` snapshots bless programs full of unbound names. | confirmed |
| C8 | **Non-`.ok` outcomes (parse/type error) produce a SOURCE-only snapshot without the error.** | `snapshot.zig:642-644` `.validationError => {}, .typeError => {}, .parseError => {}`. | 6 snapshots in this batch are silent parse-error snapshots (see table). | confirmed (640→642) |
| C9 | **A pipeline through a bare fn identifier is typed `function`.** | Probe: `fn double(x: i32) -> i32 {…} fn inc(…) … val result = 1 \|> double \|> inc; val z: i32 = result;` gives `type mismatch: expected i32, got function at main:4:14`. The call form `5 \|> add(3) \|> multiply(2) \|> format(…)` correctly yields `string` (`val z: i32 = result;` gives `got string`). | Hidden by `pipeline_simple_chain`: its `val result` lives inside `fn main`, which is not serialized. | confirmed |
| C10 | Cosmetic: the JSON key is `"indent"` where `"ident"` is meant. | `snapshot.zig:57` and `:117` `try jws.objectField("indent");` | naming | confirmed (116→117, plus 57) |

---

## Non-`ok` findings

| slug | test file:line | verdict | evidence (quoted, path) | expected vs actual | suggested fix | re-check |
|---|---|---|---|---|---|---|
| local_binding_inside_comptime | infer_exprs.zig:45 | wrong-output | `snapshots/comptime/node/local_binding_inside_comptime.snap.md`: `ct_0: val hash = comptime {` `break 6364 + 11;` `} → 6375` … `"indent": "hash",` `"return_type": "void"`. TRANSFORM CODE: `val hash = comptime {` `break 6364 + 11;` `};` (not folded). | Expected `hash: i32`, since the folded value is the integer 6375. Actual: `void` (C4). The name is also wrong: the source `val hash = comptime { break 6364 + 11; };` has no *local binding*. TRANSFORM shows the block, while `build` emits `const hash = 6375;`. | In `inferComptimeExpr .comptimeBlock`, type the block from its `break` value (or unify the break values). Rename the test, or add `val a = 6364;` inside the block. Make TRANSFORM show the folded block. | **corrected**: COMPTIME VALUES quote format updated; unfolded TRANSFORM noted; probe still `got void`. |
| case_on_enum_variants_all_arms_return_string | infer_exprs.zig:51 | wrong-output | `…/node/case_on_enum_variants_all_arms_return_string.snap.md`: 4× `"return_type": "string"` in `match`, then `"return_type": "?"` for the case. The `case` object has no binding name for `label`. | Expected case type `string`. Actual `?` (C3). | Unify every arm body type into the case result var (infer.zig:7468). Emit the binding name in the `case` repr. | confirmed |
| case_with_variant_field_bindings_body_does_not_use_bound_vars | infer_exprs.zig:88 | wrong-output | `…/node/case_with_variant_field_bindings_body_does_not_use_bound_vars.snap.md`: `"param": "Shape"`, arms all `"string"`, case `"return_type": "?"` | Expected `string`. Actual `?` (C3). | Same as above. | confirmed |
| case_arms_with_different_types_string_i32_union | infer_exprs.zig:154 | wrong-output | `…/node/case_arms_with_different_types_string_i32_union.snap.md`: arms `"string"`, `"i32"`; case `"return_type": "?"` | The name promises `string \| i32`; `typeNameOf` supports `.union_` (`snapshot.zig:525`) and would render `string \| i32`. Actual `?`. No union is ever built (C3). Probe: `val z: bool = label; val w: string = label;` fails only on the *second* use (`expected string, got bool at main:3:17`), which shows the case type is a free var. | Implement the arm-type join (union) or unify. Regenerate. | confirmed |
| case_arms_with_same_type_no_union | infer_exprs.zig:163 | wrong-output | `…/node/case_arms_with_same_type_no_union.snap.md`: 3× `"string"` arms, case `"return_type": "?"` | Expected `string`. Actual `?`. This test and the "union" test render identically, so "no union" is unobservable. | Same as above. | confirmed |
| case_arms_three_distinct_types_union_of_three | infer_exprs.zig:173 | wrong-output | `…/node/case_arms_three_distinct_types_union_of_three.snap.md`: arms `"string"`, `"i32"`, `"f64"`; case `"return_type": "?"` | Expected `string \| i32 \| f64`. Actual `?`. | Same as above. | confirmed |
| net_new_nested_template_call_inside_a_template_body | templates.zig:818 | **wrong-output (hidden miscompile)** (was weak) | `…/node/net_new_nested_template_call_inside_a_template_body.snap.md`: `COMPTIME REPLY -- template outer` `"source": "inner(\"deep\")"`. There is no trace for `inner` (a V1 pass-through), and the JSON has only `"indent": "s", "return_type": "string"`. Probe `build` on the test source: `out/main.js` = `const s = inner();`; `node out/main.js` gives `ReferenceError: inner is not defined`. Control: `val s = inner("deep");` written directly builds to `const s = "deep";`. | Expected `const s = "deep";` (the test comment says "which then expands in turn"). Actual: the reply's `inner("deep")` is type-checked as `string` in the caller, but the emitted code keeps an unexpanded call to a template fn that never reaches codegen, and its argument is lost. | Make the transform recurse into recorded expansions: the reply-parsed tree's own template calls must be substituted too. Root cause not isolated. `templateExpansions` is keyed by `ast.Loc` (`infer.zig:3257`), and the inner expansion's loc comes from the re-parsed reply source. Assert the final code (TRANSFORM section, or `templateExpansions` content). | **corrected**: upgraded from weak. The runtime probe shows a real miscompile. |
| integer_and_float_literals | infer_exprs.zig:21 | wrong-test | `…/node/integer_and_float_literals.snap.md` has only `----- SOURCE CODE -- main.bp` with `val x = 42; val y = 3.14; @print(x, y);`. There is no TYPED AST section, so the outcome was not `.ok` (C8). | Expected `x: i32`, `y: f64`. Actual: a parse error. Probe: the source gives `error: parse error in main`; without the `@print` line it checks. A top-level `@print(...)` statement does not parse. | Drop the `@print` line, or wrap it in `fn main() { … }`. Make the harness fail on non-`.ok` outcomes (reuse `assertCompilesOk`). | confirmed |
| string_literal | infer_exprs.zig:29 | wrong-test | `…/node/string_literal.snap.md` is SOURCE-only: `val greeting = "hello"; @print(greeting);` | Same cause: top-level `@print` gives a parse error (probe re-run). | Same fix. | confirmed |
| binary_operators | infer_exprs.zig:36 | wrong-test | `…/node/binary_operators.snap.md` is SOURCE-only: `val sum = 1 + 2; val product = 3.0 * 2.0; val joined = "a" + "b"; @print(sum, product, joined);` | Expected `sum: i32`, `product: f64`, `joined: string`. Actual: a parse error. Probe: the same 3 vals without `@print` pass `check`. | Same fix. | confirmed (quote fixed: `3.0 * 2.0`) |
| case_on_integer_with_wildcard | infer_exprs.zig:68 | wrong-test | `…/node/case_on_integer_with_wildcard.snap.md` is SOURCE-only, ending `@print(desc);` | A parse error, same cause. Probe: the source without `@print` checks. | Same fix. (After that, C3 will show `"?"`.) | confirmed |
| case_with_or_patterns | infer_exprs.zig:78 | wrong-test | `…/node/case_with_or_patterns.snap.md` is SOURCE-only, ending `@print(parity);` | A parse error. Probe: the source without `@print` checks. | Same fix. | confirmed |
| self_field_access_in_method | types.zig:269 | wrong-test | `…/node/self_field_access_in_method.snap.md` is SOURCE-only: `val Point = struct {` … `fn sum() -> i32 { return self.x + self.y; },` | A parse error: the `struct` keyword/form no longer exists. Probe: `val Point = struct { x: i32, y: i32, };` gives a parse error, while `record Point { x: i32, y: i32, fn sum(self: Self) -> i32 { return self.x + self.y; } }` checks. | Rewrite as `record Point { … fn sum(self: Self) -> i32 {…} }`. | confirmed |
| assert_pattern_with_catch_throw | types.zig:83 | wrong-test | `…/node/assert_pattern_with_catch_throw.snap.md`: `val assert Person(name, age) = r catch throw Error("is not person");` gives OK JSON with `"return_type": "void"` | `Person`, `r` and `Error` are undeclared, and `throw` is used outside `#[@result]`. It still compiles because of the C7 swallow. Probe: `fn f() { val z = r; }` gives `unbound variable 'r' at main:1:18`, but the assert form passes. | Declare `record Person`, a subject param and an error type in a `#[@result]` fn. Make assertPattern check the pattern against the subject and stop swallowing unbound errors. | confirmed (all 8 sources re-probed: all `Checked`) |
| assert_pattern_with_catch_default_value | types.zig:91 | wrong-test | `…/node/assert_pattern_with_catch_default_value.snap.md`: `val assert Person(name, age) = r catch Person(name: "bob", age: 12);` | Same: `Person` and `r` are unbound and swallowed. | Same fix. | confirmed |
| assert_pattern_with_string_literal | types.zig:99 | wrong-test | `…/node/assert_pattern_with_string_literal.snap.md`: `val assert "hello" = greeting catch throw Error("not hello");` | `greeting` and `Error` are unbound. A probe with the exact source passes `check`. | Same fix. | confirmed |
| assert_pattern_with_number_literal | types.zig:107 | wrong-test | `…/node/assert_pattern_with_number_literal.snap.md`: `val assert 42 = answer catch throw Error("not 42");` | `answer` and `Error` are unbound; probe confirms the source is accepted. | Same fix. | confirmed |
| assert_pattern_with_enum_variant | types.zig:115 | wrong-test | `…/node/assert_pattern_with_enum_variant.snap.md`: `val assert Ok(value) = result catch throw Error("not ok");` | `result` and `Error` are unbound, and `Ok` has no enum in scope. | Same fix. | confirmed |
| assert_pattern_with_empty_list | types.zig:123 | wrong-test | `…/node/assert_pattern_with_empty_list.snap.md`: `val assert [] = list catch throw Error("not empty");` | `list` and `Error` are unbound. | Same fix. | confirmed |
| assert_pattern_with_multiple_element_list | types.zig:131 | wrong-test | `…/node/assert_pattern_with_multiple_element_list.snap.md`: `val assert [1, 2, 3] = numbers catch throw Error("not matching");` | `numbers` and `Error` are unbound. | Same fix. The 8 `assert_pattern_*` JSONs are structurally identical, so they are near-duplicates. | confirmed |
| assert_pattern_with_list_and_rest | types.zig:139 | wrong-test | `…/node/assert_pattern_with_list_and_rest.snap.md`: `val assert [first, second, ..rest] = items catch [];` | `items` is unbound. | Same fix. | confirmed |
| q_custom_executes_code_identically_the_tree_is_retrievable_by_loc | templates.zig:522 | wrong-test | `src/comptime/tests/templates.zig:555-556` comment: "`rows[0] + 1` type-checks, so the splice produced an `i32[]` exactly as returning `e.build("[10, 20]")` would". The code at :526 is `e.build("41")` and at :532 is `val answer = rows + 1;`. Leaf span at :527: `Span(5, 9, 1)` over `"select id"`. | The comment describes a different program. Offsets 5..9 are `"t id"`; the field `id` sits at 7..9. Only `start == 5` is asserted (:576), so a wrong span passes. No snapshot. | Fix the comment. Use `Span(7, 9, 1)` and assert `end`. | confirmed |
| template_fn_with_expr_param_compiles_through_the_pipeline | templates.zig:293 | weak | `…/node/template_fn_with_expr_param_compiles_through_the_pipeline.snap.md`: no COMPTIME ERLANG/REPLY section, because `return template;` is a V1 pass-through (`infer.zig:3607`) that never runs the runtime. No TRANSFORM section. `"type": "?"` for `template`; only `"indent": "c", "return_type": "string"`. | Expected to show the expansion `val c = "\n<p>hello</p>\n";` (C1). Actual: only the type. Params render `"?"` (C2). Probe `build`: `const c = "\n<p>hello</p>\n";` (correct but unpinned). | Always emit `BOTOPINK TRANSFORM CODE` (at least when `templateExpansions` is non-empty). | confirmed. The new trace sections do not cover V1 expansions. |
| runtime_template_body_lookup_miss_drives_control_flow | templates.zig:420 | weak | `…/node/runtime_template_body_lookup_miss_drives_control_flow.snap.md`: `COMPTIME REPLY -- template need` `"source": "\"ok\""`; `"indent": "r", "return_type": "string"`; `"id": 0` for `Button` (C5) | The splice `"ok"` is now visible (probe `build`: `const r = "ok";`). Still, only the miss path is covered; there is no hit counterpart. Probe with `t.lookup("Button")`: `check` gives `error: should be missing at main:11:14`. | Add a hit case that expects the `fail` diagnostic. | **corrected**: "splice not visible" dropped; the missing-hit-case gap remains. |
| runtime_template_body_parts_with_a_hole_splices_the_caller_expression | templates.zig:480 | weak | `…/node/runtime_template_body_parts_with_a_hole_splices_the_caller_expression.snap.md`: `COMPTIME REPLY -- template html` `"source": "\"\" + \"<p>\" + __bp_hole_q_0 + \"</p>\""`; the capture in COMPTIME ERLANG is `text => <<"<p>__bp_hole_q_0</p>">>`; JSON `"indent": "page", "return_type": "string"` | The test name's core claim, that the hole splices `name`, is still unobservable. The reply carries the placeholder `__bp_hole_q_0`, and the placeholder→`name` substitution happens afterwards in Zig (`infer.zig:3417`). Probe `build`: `const page = ((("" + "<p>") + name) + "</p>");` (correct but unpinned). | Emit TRANSFORM CODE for template modules, or assert the substituted expansion. | **corrected**: the reply is now visible, but only with the placeholder. |
| mixed_signature_plain_string_literal_arg_is_collected_alongside_capture | templates.zig:652 | weak | `templates.zig:667-668` `const exp = env.templateExpansions.get(.{ .line = 4, .col = 9 }); try std.testing.expect(exp != null);` | The name claims the plain arg is *collected*, but nothing inspects it (e.g. `PlainArg{paramName="prefix", source="\"pre:\""}`). The expansion content ("hello") is not checked either. Probe `build`: `const c = "hello";`. | Assert on the recorded plain args and on the expansion node's literal. | confirmed |
| mixed_signature_number_literal_arg_is_accepted | templates.zig:671 | weak | `templates.zig:684-685` only `exp != null` | The type of `c` is not checked (a `@Expr<T>` returning a `string` capture). Probe: `val z: i32 = c;` gives `expected i32, got string`; `build` gives `"8080"`. | Assert `env.lookup("c")` is `string`. | confirmed |
| markup_dsl_component_tags_resolve_to_calls | templates.zig:839 | weak | `templates.zig:846` `return q.build("fragment([Page1(), Page2()])");` | The template ignores the text `<Page1/><Page2/>` and hardcodes the calls, so "tags resolve to calls" is not exercised. There is no snapshot, and only `.ok` is asserted. Probe `build`: `const page = fragment([Page1(), Page2()]);`, the hardcoded string verbatim. | Derive the calls from `q.text()`/`parts()`, or rename the test. | confirmed |
| net_new_splice_type_error_reports_at_the_splice_site | templates.zig:786 | duplicate | `…/node/errors/net_new_splice_type_error_reports_at_the_splice_site.snap.md`: `val p = port();` `┌─ :4:9` `expected: i32  found: bool`. Compare `…/errors/splice_bound_violation_at_the_call_site_f6.snap.md`: `val d = bad();` `┌─ :4:9` `expected: i32  found: string`. | Same shape, same code path (V1 `@expr` lift → `finishExpansion` unify, `infer.zig:3240-3258`), same span. Only the lifted literal's type differs. | Drop one, or turn the second into a genuinely different case (e.g. `@code("true")` or a runtime-body lift). | confirmed |
| tuple_destructuring_binds_variables | types.zig:153 | weak | `…/node/tuple_destructuring_binds_variables.snap.md`: body `"source": "val #(first, second) = #(1, \"hello\");"`, fn `"return_type": "void"` | The name claims the bindings, but `first: i32` / `second: string` are not visible. Fn locals are not serialized. Probe: bindings *are* typed correctly in the fn (`val z: bool = first;` gives `expected bool, got i32`). | Add typed-use assertions inside the fn (`val a: i32 = first; val b: string = second;` checks). Top-level placement is **not** an option: `val #(first, second) = #(1, "hello");` at top level gives `parse error in main`. | **corrected**: suggested fix changed. Top-level tuple destructuring does not parse. |
| pipeline_simple_chain | types.zig:173 | weak (hidden bug) | `…/node/pipeline_simple_chain.snap.md`: `"source": "val result = 1 \|> double \|> inc;"`; `main` `"return_type": "void"` | The type of `result` is not visible. Probe (C9): the same pipeline at top level is typed `function`, not `i32`. The snapshot passes while inference is wrong. | Put `val result` at top level so JSON shows `i32`. Fix bare-ident pipeline inference. | confirmed |
| comment_single_line | types.zig:194 | weak | `…/node/comment_single_line.snap.md`: JSON only `fn_def main` / `"source": "null;"` | Comments are not represented anywhere, so "single line comment" is only a parse-smoke test. The JSON section is identical to `module_comment_top_of_file` (same md5). | Assert comment tokens/AST (`trailingComments`/doc fields) or move to the parser/format tests. | confirmed |
| doc_comment_before_fn | types.zig:203 | weak | `…/node/doc_comment_before_fn.snap.md`: `fn_def greet` has no doc field | The doc comment is not reflected. | Same. | confirmed |
| module_comment_top_of_file | types.zig:212 | weak | `…/node/module_comment_top_of_file.snap.md`: JSON byte-identical to `comment_single_line` (`fn_def main`, `"source": "null;"`) | Near-duplicate. The `////` module comment is not reflected. | Same. | confirmed |
| negation_unary_minus | types.zig:222 | **weak (hidden bug)** | `…/node/negation_unary_minus.snap.md`: `"source": "return -x;"`, declared `"return_type": "i32"` | Only the declared signature is visible (C6). Probe: `fn negate(x: string) -> i32 { return -x; }` passes `check`. **New:** unary minus itself accepts non-numerics. `val n = -"s";` at top level passes `check`, and `val z: bool = n;` gives `expected bool, got string`, so `-"s"` is typed `string`. | Top-level `val n = -(3);` (typed `i32`, probe) plus a type-error snapshot for `-"s"`. That snapshot will currently fail to red until unary minus requires a numeric operand. | **corrected**: upgraded to hidden bug. The negative case the fix proposed is itself accepted. |
| loop_break_with_value | types.zig:240 | weak (hidden bug) | `…/node/loop_break_with_value.snap.md`: `"type": "?"` for `arr`, `"return_type": "i32"`, body `"return loop (arr) { x ->"` | Probe: `val r = loop (arr) { x -> if (x > 10) { break x; }; }; val z: i32 = r;` gives `expected i32, got array`, and `val z: i32[] = r;` passes. The loop-with-break is typed `i32[]`, yet the fn declares `-> i32`. It passes only because of C6. | Top-level form plus a JSON type, or a typed-use assertion. Decide the break-value typing and fix return unification. | confirmed |
| if_null_check_binding_returns_optional | types.zig:281 | weak | `…/node/if_null_check_binding_returns_optional.snap.md`: `"name": "name", "type": "?"`, `"return_type": "?"` | The name claims the result is optional. Both the param and return render `"?"` (C2), and the body type is not shown. Probe: `val n: ?string = null; val r = if (n) { e -> e; }; val z: i32 = r;` gives `expected i32, got string`. So the if-without-else is typed `string`, not `?string`, and the claim appears false (hidden by C6). `val z: ?string = r;` also checks, but that only shows `string`→`?string` assignability. | Render `?T` in `typeNameFromTypeRef`, and use a top-level binding to expose the type. | confirmed |
| if_expression_result_type_from_then_branch | infer_exprs.zig:201 | weak | `…/node/if_expression_result_type_from_then_branch.snap.md`: body `"val r = if (n > 0) { \"positive\"; };"`; only `val s` → `"string"` from the declared signature | The type of `r` is not visible. Probe: changing the fn to `-> bool` still checks (C6), so the snapshot proves nothing about the then-branch type. At top level, a probe shows `r: string` (`val z: i32 = r;` gives `got string`). | Top-level `val r = if (…) {…};` so the JSON shows it. | confirmed |
| stdlib_array_method_dispatch_xs_isempty_sugar | infer_exprs.zig:290 | weak | `…/node/stdlib_array_method_dispatch_xs_isempty_sugar.snap.md`: only the body lines `"val empty = xs.isEmpty();"` | The type of `empty` and the dispatch lowering are not visible. Probe: `val empty: string = xs.isEmpty();` gives `expected string, got bool at main:3:28`, so the behaviour is correct but unasserted. | Top-level `val` (JSON would show `bool`) or assert `instanceLowerings`. | confirmed |
| stdlib_array_method_dispatch_ys_contains_with_arg | infer_exprs.zig:299 | weak | `…/node/stdlib_array_method_dispatch_ys_contains_with_arg.snap.md`: only `"val found = ys.contains(2);"` | Same. Probe gives `got bool` (correct, but unasserted). | Same. | confirmed |

### Withdrawn (moved to `ok`)

| slug | test file:line | former verdict | withdrawal reason |
|---|---|---|---|
| runtime_template_body_text_build_end_to_end | templates.zig:408 | weak | The splice is now pinned: `COMPTIME REPLY -- template shout` `"source": "\"hey!\""` (plus the lowered body in COMPTIME ERLANG). A wrong splice such as `"hey"` would change the snapshot. Probe `build`: `const s = "hey!";`. The test also asserts `.ok` via `assertCompilesOk`. |
| runtime_template_body_expr_lifts_a_computed_value | templates.zig:438 | weak | The lift is now pinned: `COMPTIME REPLY -- template six` `"value": 6, "kind": "value"`. Probe `build`: `const n = 6;`. |

---

## `ok` slugs / tests

Some entries carry a minor note; none of the notes changes the verdict. (Not individually re-probed in the
re-check, except where noted.)

### templates.zig (28)
- expr_param_capture_plain_string_arg_arrives_unevaluated (L54, asserts only)
- expr_param_capture_multiline_template_with_hole_keeps_parts (L81)
- scope_snapshot_lookup_hit_and_miss (L109)
- expr_methods_typecheck_and_record_lowerings (L145): 12 lowerings match the 12 `TemplateOp` members in `env.zig:192`.
- fail_span_maps_into_the_caller_s_template (L182) → `snapshots/comptime/templates/fail_span_in_template.snap.md`
  - Message `error: component \`Buttom\` not found in caller scope`, `┌─ :5:2`, caret under `B` of `<Buttom label="Send"/>` (col 2, the first char after `<`). Correct. Re-checked: unchanged.
  - Note: the test passes `.line = 1` while `Buttom` is on template line 2 under the documented 1-based convention. This is harmless on the contiguous-text path, which ignores `span.line`.
- expr_argument_must_be_a_literal_string_v1 (L221): `:5:14` points at `tpl`, correct.
  - Note: the message still says "an \`expr\` argument" (legacy lowercase name for `@Expr`).
- expr_argument_is_typed_in_the_caller_against_inner_t (L231): `:4:15` points at the string literal; `expected: bool / found: string`.
- context_exposes_declaration_position_and_scope_for_second_layer_languages (L240): `line => 7, col => 13` is the `"""` on `val c = dsl """`. Correct.
- context_source_bindings_build_methods_typecheck_against_std_syntax (L280). Note: "std.syntax" in the name is stale; the contract lives in `builtins.d.bp`.
- bounded_expansion_is_transparent_to_the_caller_f6 (L306)
- generic_expr_t_return_reveals_the_expansion_type_per_call_f6 (L328)
- explicit_value_lift_via_expr_builtin_f6 (L348)
- splice_bound_violation_at_the_call_site_f6 (L364): `:4:9` points at `bad`; `expected: i32 found: string`.
- template_body_not_expandable_by_the_v1_driver_f6 (L373): `:5:9` points at `hard`. The error exists only because `assertTypeErrorSnap` has no eval ctx (`infer.zig:3213`); this is intentional per the name.
- runtime_template_body_text_build_end_to_end (L408): withdrawn from weak in the re-check; COMPTIME REPLY pins `"hey!"`.
- runtime_template_body_expr_lifts_a_computed_value (L438): withdrawn from weak in the re-check; COMPTIME REPLY pins `6`.
- runtime_fail_maps_into_the_caller_s_template (L450)
- a_fn_returning_exprcustom_t_is_recognized_as_a_template_fn (L503)
- the_exprcustom_carrier_code_names_no_sub_language (L583)
- anonymous_record_literal_types_structurally_and_fields_resolve (L608)
- unknown_field_on_an_anonymous_record (L624): `:2:13` points at `prot`.
  - Note: `'record' has no field 'prot'` gives no shape for the anonymous record; a better message would be `record { port: i32 }`.
- yaml_model_static_record_lift_reveals_the_structure_v1_driver (L631)
- non_expr_template_param_must_receive_a_literal_v1 (L688): `:5:23` points at `p`.
- holed_fallback_span_hole_on_first_non_opening_line_maps_correctly (L700)
- net_new_a_hole_captures_a_bare_variable_reference (L732)
- net_new_an_empty_template_is_handled_gracefully (L762)
- net_new_two_template_invocations_expand_independently (L797)
- markup_dsl_expr_splices_as_a_text_child (L852). Note: text parts are dropped by design, and only `.ok` is asserted.

### types.zig (17)
- array_literal_infers_element_type: `string[]`
- val_with_array_type_annotation: `string[]`
- array_prepend_with_empty_array: `i32[]`
- array_prepend_with_single_element_array: `i32[]`
- array_prepend_with_multiple_elements_array: `i32[]`
- assert_simple_assertion
- assert_with_arithmetic_comparison
- assert_with_message. Note: a probe shows `assert false, 12` is also accepted (the message is not type-checked). Re-checked: still accepted.
- assert_array_equality
- tuple_literal_infers_element_types: `#(string,string)`
- val_with_tuple_type_annotation: `#(string,string)`
- tuple_literal_with_mixed_types: `#(i32,string)`
- pipeline_multiple_parameters. A probe confirms the call-form pipeline yields `string`; the snapshot does not show it.
- range_iterate_0_to_n
- loop_yield_accumulation. Return and param render `"?"` (C2); a probe confirms the yield loop is an array.
- assign_pluseq_on_var. A probe shows `count += "a"` is rejected, so the `+=` check works. Re-checked: `expected i32, got string`.
- if_null_check_binding_with_else. Param renders `"?"` (C2); a probe shows the result is `string`, which is correct.

### infer_exprs.zig (18)
- lt_comparison_returns_bool
- logical_and_returns_bool
- logical_or_returns_bool
- logical_not_returns_bool
- chained_logical_operators
- logical_not_with_parens
- concat_with_i32_rhs_coerces_to_string
- concat_with_i32_lhs_coerces_to_string
- null_literal_type_is_optional: `optional<?>`, matching the name.
- optional_annotation_string_val: `optional<string>`
- optional_annotation_i32_val_with_null: `optional<i32>`
- if_expression_with_else_branch
- null_check_binding_if_x_e_body_ignores_binding
- try_expression_result_type_unified_with_return. `fetch` renders `"return_type": "?"` (C2).
- try_catch_handler_provides_fallback. Same C2 note.
- assign_number_literal_to_var
- assign_string_to_var
- assign_type_mismatch_error: `:3:5`, `expected: i32 found: string`.
  - Note: the caret sits on the target `x`, not on the offending value `"oops"` (col 9). This is acceptable but arguably imprecise.

---

## Top 10 most serious

Re-check status in brackets.

1. **[new in re-check] Nested template expansion miscompiles.** In `net_new_nested_template_call_inside_a_template_body`,
   `build` emits `const s = inner();`, which gives `ReferenceError: inner is not defined` at runtime. The snapshot is green because
   the val is typed `string` and COMPTIME REPLY only shows the first level (`inner("deep")`).
2. **C1: template expansions are only partly visible** [corrected].
   - Runtime replies are now pinned in `COMPTIME REPLY`.
   - V1-driver expansions (pass-through/`@expr`/`@code`) have no trace section.
   - The hole substitution appears only as the placeholder `__bp_hole_q_0`.
   - `snapshot.zig:553` still gates TRANSFORM CODE on `comptime_script`.
   - The second level of a nested expansion is invisible, and it is wrong (item 1).
3. **C3: a `case` expression is typed as a free type var** (`infer.zig:7468` `env.freshVar()`) [confirmed]. 5 snapshots show `"return_type": "?"`, and the three "union" tests cannot show any union. Probe: an all-string `case` is assignable to `bool`.
4. **6 silent parse-error snapshots (C8)** [confirmed]. `integer_and_float_literals`, `string_literal`, `binary_operators`, `case_on_integer_with_wildcard` and `case_with_or_patterns` fail on a top-level `@print(...)`; `self_field_access_in_method` fails on the removed `struct` form. The harness records SOURCE-only and stays green.
5. **C6: `return` values are never unified with the declared fn return type** [confirmed]. `fn f() -> i32 { return "s"; }` passes `check`. This masks the hidden bugs behind `loop_break_with_value`, `if_null_check_binding_returns_optional`, `if_expression_result_type_from_then_branch` and `negation_unary_minus`.
6. **C7: the 8 `assert_pattern_*` tests bless invalid programs** [confirmed]. Unbound subjects and `Error`, plus `throw` outside `#[@result]`, are swallowed by `infer.zig:7543-7555`, and the pattern is never checked against the subject.
7. **C9 hidden by `pipeline_simple_chain`:** `1 |> double |> inc` is typed `function` (probe) [confirmed]. The snapshot cannot see it because the val is fn-local.
8. **`local_binding_inside_comptime`:** `hash` is typed `void` while the folded value is 6375 (C4) [confirmed]. The test name also mismatches the source, and TRANSFORM CODE shows the block unfolded.
9. **C2: placeholder `"?"` types in TYPED AST JSON** for every non-named TypeRef (`@Expr<string>`, `i32[]`, `?string`, `@Result<…>`) [confirmed]. Seen across the template, loop, optional and try snapshots.
10. **`loop_break_with_value`:** the loop-with-break is inferred as `i32[]` (probe) under a fn declared `-> i32`, and it is accepted [confirmed].
    Runner-ups:
    - C5: record/enum `"id"` is always 0 (`snapshot.zig:443/454`) [confirmed].
    - Unary minus accepts `string` (`val n = -"s";`, hidden by `negation_unary_minus`) [new].
    - The duplicate splice-error test.
    - The stale comment and wrong leaf span in the `q.custom` test.
    - The mixed-signature tests assert only `exp != null`.

## Incidental observations from the re-check (not scored)

- `botopink build` exits 0 and prints `Compiled` when the module has a type error, both for `val x: i32 = "s";` and for a
  template `fail()` (the lookup-hit variant). It writes no `out/` at all. Only `check` reports the diagnostic.
- The markup-DSL probe builds `fn fragment(items: Element[]) -> Element { Element(); }` to
  `function fragment(items) { new Element(); }`, with no `return`. Not investigated; it may be intended semantics for a
  `;`-terminated last statement.

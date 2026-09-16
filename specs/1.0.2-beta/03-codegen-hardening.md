# Spec 03 — Codegen Hardening

**Version:** 1.0.2-beta
**Priority:** high
**Continues:** [`../1.0.1-beta/03-codegen-hardening.md`](../1.0.1-beta/03-codegen-hardening.md)
**Depends on:** nothing — the harness delivered in 1.0.1-beta is the measuring instrument

---

## Objective

Every observable codegen snapshot records the output the program is supposed to produce, on
every backend. The harness is now honest about what ran; what is left is the lowering itself.

Paths are relative to `repository/botopink-lang/modules/compiler-core/`, except where they
start with `libs/`, which is relative to `repository/botopink-lang/`.

## Current state

`zig build test` is green and every snapshot's RUN LOG is now the result of a real run
(or of a real compile failure). The measurements below are what the four backends look like
through that instrument.

`scripts/snap_audit.sh --mode=coverage` — label `a` = source without
`@print`/`@assert`/`@panic`, `b` = has one and a `fn main`, `c` = has one but no `fn main`:

| backend | a/empty | a/nonempty | b/missing | b/empty | b/nonempty | c/empty | total |
|---|---|---|---|---|---|---|---|
| node (commonJS) | 145 | 1 | 3 | 18 | 110 | 2 | 279 |
| erlang | 146 | 0 | 3 | 6 | 122 | 2 | 279 |
| beam | 145 | 0 | 3 | 18 | 110 | 2 | 278 |
| wasm | 145 | 0 | 3 | 128 | 0 | 2 | 278 |

- `a/missing` and `c/nonempty` are 0 everywhere.
- `b/empty` is a program that ran and exited non-zero — a crash, not silence.
- `b/missing` is the same three slugs on all four targets: the documented
  `assertJsCompileError` skips whose programs do not reach codegen at all
  (`narrow_and_condition_field_access`: `&&` in an `if` condition is a parse error;
  `narrow_assert_pattern_with_print`: `assert x is Some(n)` is a parse error;
  `string_slice_without_end_arg_slices_to_source_length`: `s.slice(2)` is an arity mismatch).
  These are frontend gaps, not codegen gaps — they belong to the type-system/parser spec, and
  each one unblocks a codegen fixture here.
- `COMPILE ERROR` blocks left in a RUN LOG: 1 (erlang `comptime_block_with_break`), 0
  elsewhere.
- Cross-backend agreement on the observable snapshots: of the 131 beam `b` snapshots, 71
  reproduce the erlang RUN LOG exactly and 57 differ (18 of those by crashing); erlang is the
  reference in nearly every one of those 57.
- All 282 `WASM TEXT` blocks pass `wasmtime compile`; `executeWat`
  (`src/codegen/runtime.zig:553`) is still a stub, which is why every wasm RUN LOG is empty.
- `src/comptime/runtime/persistent_erl.zig` still has **0** tests.

---

## Step 1 — commonJS runtime gaps

The one backend nothing was done to in 1.0.1-beta: 18 `b/empty` (the program crashes) and 13
RUN LOGs recording `undefined` / `NaN`.

| Gap | Evidence | Fix |
|---|---|---|
| std string/array methods are `@External.Node("./gleam_stdlib.mjs", …)`, a file shipped nowhere; the emitted prelude `require`s it, so any call crashes with `Error: Cannot find module './gleam_stdlib.mjs'` | `libs/std/src/primitives.bp:118`, `:122`, `:140`, `:145`, `:150`, … — 10 commonJS snapshots require the file (`string_methods_map_to_native_js_names`, `string_slice_both_bounds`, `array_slice_2_arg_…`, `array_instance_default_fn_methods`, `array_zip_via_external_node_template`, `option_method_on_tuple_element`, …) | Lower these to the native JS method (`.slice`, `.length`, `.split`, `.startsWith`, …) as the annotation names, or ship the module |
| `.len` passes through unchanged as a property read → `undefined`, and `NaN` in arithmetic | `src/codegen/commonJS.zig:2168` (`identAccess` has no `len` arm, unlike `erlang.zig:3041` / `wat.zig:3107` / `beam_asm.zig:2573`); `string_concat_of_two_literals`, `string_length_after_concat`, `list_literal_len_reads_length_prefix`, `list_literal_of_strings_len`, `list_literal_of_records_len`, `empty_list_literal_len_is_zero`, `string_len_participates_in_arithmetic` | Map `.len` to `.length` on a string/array receiver |
| `@Result` `case` arms test `subject.tag === "Ok"` while `#[@result]` materialises `{ ok: … }` / `{ error: … }`, so no arm matches | `src/codegen/commonJS.zig:2967`; emitted `fetch` in `narrow_case_result_ok_err_with_print` returns `({ ok: "data" })`, RUN LOG `undefined` twice | One shape: either build the case test against `ok` / `error` keys (as `erlang.zig`'s `resultTag` does) or make the `#[@result]` lowering emit `{ tag, … }` |
| externals that resolve to a module symbol crash or print nothing | `external_call_emits_module_symbol`, `external_import_binds_symbol`, `external_target_template_equivalent_to_external_target_template` (all `b/empty`) | — |

The remaining commonJS crashes (`return for (…)`, `return continue`, `const { x, ... } = p`,
`function greet({ name, ... } = )`, `if () return null;`) are the JS bridges: they are owned
by [`04-emitter-centralization.md`](./04-emitter-centralization.md), where deleting each
bridge's build site is the fix. Do not fix them here.

**Acceptance:**
- [ ] commonJS `b/empty` ≤ the count explained by the bridges in spec 04
- [ ] No commonJS RUN LOG records `undefined` / `NaN` except where the program really prints
      a none/null value (`optional_fn_return_null_path`, `array_at_lowers_byte_identically_across_backends`)
- [ ] `zig build test` green

## Step 2 — erlang residuals

Six `b/empty`, one `COMPILE ERROR`, and the `Ast.Expr.r("")` fallbacks that still drop a
value.

| Snapshot | Symptom | Cause |
|---|---|---|
| `comptime_block_with_break` | `COMPILE ERROR (erlc): main.erl:6:6: variable 'X' is unbound` — emitted `result() -> (X * 2).` | `comptimeNode`'s `.comptimeBlock` arm (`src/codegen/erlang.zig:3626-3632`) returns only the `break` expression and drops the statements before it. The value is already folded (`COMPTIME VALUES: ct_0 → 20`), so emitting the folded literal is the smaller fix |
| `destructure_record_parameter_in_fn`, `destructure_record_val_binding` | crash | record destructuring |
| `endswith_lowers_via_external_beam_single_line_body` | crash | `#[@External.Beam]`-only method reached on erlang |
| `narrow_case_option_some_none` | crash | `@Option` case arms |
| `narrow_else_if_chain_with_null_checks` | crash | null-check chain |
| `try_with_inline_catch_handler` | crash | inline `catch` handler |

`Ast.Expr.r("")` still stands in for a missing value at `erlang.zig:2308` (a bare `yield;`
item in an eager generator list), `:3174` / `:3176` / `:3184` (`return` / `try` / `yield`
with no value) and `:3632`; and for an unreachable case at `:2967`, `:2977`, `:3537`,
`:3768`. Each renders as nothing, which is how the bare-`break` bug produced a syntactically
broken module before it was fixed. Give the value-carrying ones a real node and make the
unreachable ones an error (spec 04 step 2 in 1.0.2-beta tracks the unreachable half).

**Acceptance:**
- [ ] 0 `COMPILE ERROR` blocks under `snapshots/codegen/erlang/`
- [ ] erlang `b/empty` = 0
- [ ] No `Ast.Expr.r("")` left in a value position

## Step 3 — beam runtime gaps

57 of the 131 beam `b` snapshots disagree with the erlang RUN LOG, 18 of them by crashing.
They fall into the classes below; the first is by far the largest, and the first three
account for most of the 18 crashes.

| Class | Count | Evidence | Fix |
|---|---|---|---|
| A module's **own** top-level `val` is not emitted as a function, and a bare reference falls through to `{move, {atom, <name>}, {x, 0}}` | 22 snapshots | `src/codegen/beam_asm.zig:1824` — the fallthrough after the local / comptime-value / `crossOwnerOf` (`:1812`) checks. `val sum = 1 + 2; @print(sum)` assembles a module with no `sum/0` and prints `sum` (`val_binary_expression`). Also `fn_private_function_with_return`, `fn_pub_exported_function`, `fn_with_local_binding`, `lambda_standalone_with_params`, `comptime_folding_*` (4), `comptime_val_comptime_val_folds_arithmetic_to_literal`, `comptime_block_with_break`, `comptime_specialization_…`, `loop_map_with_break_simple`, `loop_map_with_break_add_tax`, `loop_even_numbers_with_break`, `loop_filter_with_conditional_break`, `template_end_to_end_*` (5), `stdlib_result_isok_and_iserror_predicates` | Emit every module-level `val` as a 0-arity function and export it, as `erlang.zig` already does, then route the bare reference through a local `call` |
| `declare fn` externals without an `@External.Beam` body become local functions returning `ok` | 8 | `external_a2_chained_host_call_renders_verbatim`, `external_a2_method_on_global_template_keeps_receiver_bound`, `external_call_emits_module_symbol`, `external_global_math`, `external_import_binds_symbol`, `external_target_mixed_with_external_in_one_decl`, `external_target_template_equivalent_to_external_target_template` (RUN LOG `ok`); `external_a3_result_template_owned_declare_fn` (`-1` via `unwrapOr`) | Resolve to the `@External.Erlang` form where one exists, otherwise fail the lowering loudly |
| String `+` and interpolation lower to the arithmetic `{gc_bif, '+', …}` on two binaries → `badarith`, so the whole program dies (empty RUN LOG) | 8 | `string_concat_of_two_literals` (`{move, {literal, <<"hi ">>}, {x, 0}}` … `{gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}`), `string_interpolation_lowers_to_concat`, `string_length_after_concat`, `reserved_word_identifiers`, `builtin_print_with_variable`, `narrow_early_return_with_print`, `narrow_case_option_some_none`, `narrow_else_if_chain_with_null_checks` | Concatenate as a binary, as `erlang.zig` does (`<<A/binary, B/binary>>`) |
| `@print` inside a loop-body closure crashes | 3 | `builtin_print_in_loop`, `loop_side_effect_print_in_iterator`, `iterator_fromlist_yields_array_items` — each builds `make_fun3` + `lists:foreach/2` and exits non-zero | — |
| String instance methods | 4 | `string_methods_map_to_native_js_names` (crashes), `endswith_lowers_via_external_beam_single_line_body` (crashes), `string_slice_both_bounds` (prints `5`, erlang `3`), `string_slice_result_length_is_readable` (prints `6`, erlang `4`) | — |
| Unresolved method calls leave the receiver in `{x, 0}` and emit a `%% unresolved method call: <name>/<n>` comment | 28 snapshots carry at least one `%%` marker (20 distinct method names, plus 6 `%% unsupported: record literal` and 2 `%% unsupported: interface literal`) | `array_zip_via_external_node_template` prints `[1,2,3]` where erlang prints `[{1,<<"a">>},…]`; `array_instance_default_fn_methods`, `bool_instance_default_fn_methods`, `numeric_instance_methods_external_default_fn`, `dispatch_inherent_record_method_call` | — |
| Anonymous record / interface-literal field reads → `undefined` | 4 | `anon_record_let_bound_then_field_read_by_name`, `nested_anon_record_chained_field_read`, `interface_literal_basic`, `interface_literal_with_fields` | — |
| Loop `yield` / `break` accumulation | 1+ | `loop_break_with_value` prints `[ok,ok,15,20]`, erlang `[15,20]`; `yield` lowers to `return` | — |
| `@Result` `case` arms print the whole tuple | 1 | `narrow_case_result_ok_err_with_print` prints `{ok,<<"data">>}`, erlang `<<"OK:data">>` | — |
| Unclassified crashes | 4 | `import_cross_module_record_construct_and_assoc_fn`, `narrow_if_null_check_with_print` (`if (x) { n -> … }` on `?i32`), `template_end_to_end_yaml_model_computes_a_typed_record`, `try_with_inline_catch_handler` | Triage with `erlc +from_asm` + `erl` on the recorded `.S` |

**Two latent register bugs** are invisible in the tree because the recorded modules carry a
narrow `{exports, …}` form and `erlc +from_asm` drops unexported functions before validating
them. Rewriting each snapshot's exports to name every function and assembling it rejects 2 of
275 modules:

| Snapshot | Rejection |
|---|---|
| `field_assign_self_field_update` | `'Counter_inc'/0+9`: `{put_map_exact,{f,0},{x,0},{x,0},2,{list,[{atom,count},{x,1}]}}` — `{bad_type,…}` |
| `stdlib_associated_fn_namespace_injected` | `'Pair_mapFirst'/2+23`: `{test_heap,3,3}` — `{{x,1},not_live}` (same in `'Pair_mapSecond'`) |

Both are the staging sites `src/codegen/AGENTS.md` names as still using x-registers
(`lowerTupleLit` / `lowerRecordConstruct` / `lowerTaggedTuple` / `materializeCallArgs`). The
same clobber is what makes `stdlib_associated_fn_namespace_injected` print `1 42 10` where
erlang prints `1 42 22`.

**Acceptance:**
- [ ] Every beam `b` snapshot reproduces the erlang RUN LOG, or the divergence is documented
      in its test
- [ ] beam `b/empty` = 0
- [ ] The full-export audit assembles 275/275 modules; add it as a checked script under
      `scripts/` so the exports form cannot hide a rejection again

## Step 4 — WAT execution

`executeWat` (`src/codegen/runtime.zig:553`) returns `""`; wasm is the only backend with 0
observable RUN LOGs (128 `b/empty`). CI already installs `wasmtime` and every module loads,
so wiring it in is a small change behind the same `runWithTimeout` / `runCaptured` wrapper.

**What turning it on today would pin.** Running each `b` module under `wasmtime run` and
comparing with the commonJS RUN LOG:

| Outcome | Count |
|---|---|
| reproduces the commonJS RUN LOG byte-for-byte | 54 |
| differs | 72 |
| traps (`option_method_on_tuple_element`, `try_with_inline_catch_handler`) | 2 |

Of the 72 differences, 21 differ only because commonJS itself records an empty log and 13
because commonJS records `undefined` / `NaN` — so commonJS is not a usable oracle until
step 1 lands. 40 of the 72 are wasm printing nothing but zeros.

The dominant wasm defects behind them, all already honest placeholders in the emitted text
(48 snapshots carry at least one):

| Placeholder | Occurrences | Meaning |
|---|---|---|
| `;; unresolved call: <f>/<n>` | 59 | instance / array / std / external methods with no lowering (`join`, `at`, `zip`, `of`, `indexOf`, `toUpper`, `str_length`, `floor`, …) |
| `;; lambda` | 9 | a lambda used as a *value* lowers to `i32.const 0` (no table / `call_indirect`) |
| `;; cross-module import not linked (wasm single-module)` | 8 | — |
| `;; loop over unknown iterable` | 5 | — |

Plus: a `loop` used as a comprehension runs its body but always yields `0`; `case`
discriminates only numeric and `or`-of-numeric patterns, so a variant pattern runs the first
arm with its payload binding unset; an `f64` aggregate field round-trips at `f32` precision;
and a string reached through a receiver whose type is not recovered prints as its pointer
(`interface_literal_basic` prints `276`, `template_end_to_end_*` print `301`/`307`/`320`/`351`).

**Ordering.** Do step 1 first (so commonJS is a valid oracle), then decide:

1. fix the unresolved-call and lambda-value classes, then turn `executeWat` on; or
2. turn it on immediately and mark each wrong fixture as a documented skip.

The recommendation is (1): turning it on now pins 74 knowingly-wrong RUN LOGs as baseline,
which is the exact failure mode 1.0.1-beta spent the milestone undoing.

**Acceptance:**
- [ ] Decision recorded in `src/codegen/AGENTS.md`
- [ ] `executeWat` either executes or its doc comment states the deliberate skip
- [ ] No wasm RUN LOG is accepted while its module is known to print the wrong value

## Step 5 — `persistent_erl` regression tests

`src/comptime/runtime/persistent_erl.zig` has 0 tests and is reached only through template /
decorator evaluation (`template_eval.zig`, `decorator_eval.zig` → `evalDetailed`). Add:

- spawn + round-trip of a trivial module;
- respawn after the `erl` child is killed mid-session;
- `main/0` exceeding `eval_timeout_ms` → `runtime_error`, with the server still serving;
- frame edge cases: empty payload, large payload, non-ASCII bytes;
- compile/runtime error text reaching `evalDetailed` and the compiler diagnostic;
- no orphan `beam.smp` after the tests.

**Acceptance:**
- [ ] The tests above exist and pass
- [ ] `zig build test` leaves no `beam.smp` behind

## Step 6 — Missing codegen coverage

Add snapshot tests (all four backends, documented skips) for optional/null, cross-module
imports, interface/implement, records/enums, generics, lambdas/operators/annotations
(`src/codegen/tests/{values,features,aggregates}.zig`), and template/`@Expr` holes with
runtime values and comptime eval results (`src/codegen/tests/comptime.zig`). Where a defect
above is only visible through a silent source, make the test print the result — the 145
`a/empty` snapshots per backend are exactly the fixtures that can hide one.

## Step 7 — Final sweep

`zig build test` (from a cold runtime cache) `&& zig build test-libs && zig build
test-backends` green, with the coverage pivot and the full-export audit recorded in
`src/codegen/AGENTS.md`.

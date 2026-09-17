# wasm — the causes, ranked

> Carried from `1.0.2-beta/06-wasm/` into 1.0.4-beta. `file:line` and counts were measured at that milestone's
> commit — re-locate by symbol. `F1…F12` and bare front numbers are the old numbering: see
> [`../fronts.md`](../fronts.md#old-front-numbers).

Eleven causes cover every wasm defect the measurement found: 27 `b` modules that abort because the
backend gave up on a call, 1 that aborts on an out-of-bounds load, and 35 that run to completion and
print the wrong value. W1 alone closes 27 and is the keystone.

Paths are relative to `repository/botopink-lang/modules/compiler-core/`, except those starting with
`libs/`, which are relative to `repository/botopink-lang/`. Every `file:line` is at HEAD.

## How the numbers were measured

They are not read off the snapshots — a snapshot's RUN LOG only says what the harness recorded, and
for wasm it records nothing at all (`executeWat`, `src/codegen/runtime.zig:553`, returns `""`).
Each backend's emitted code was extracted from the snapshot and executed outside the suite:

| Backend | How |
|---|---|
| commonJS | `node --check <module>.js` on every emitted module (syntax), then `node main.js` |
| erlang | `erlc -o . <mod>.erl` per module, then `erl -noshell -eval "main:'_botopink_main'()"` inside a `try … catch C:E:S -> …` so the crash class and stack are visible instead of an empty log |
| beam | `erlc +from_asm` per module, same runner; plus a full-export audit |
| wasm | `wasmtime run <module>.wat` (wasmtime 45), stdout + exit status |

Cross-backend agreement is compared under a **representation mapping**, because erlang and beam
print through `~p`: `<<"x">>` → `x`, `<<>>` → empty, `1.0` → `1`, `[ 2, 4 ]` → `[2,4]`. Comparing
the raw text instead reports 22 extra commonJS fixtures as "wrong" that differ only in how a string
is rendered. "N fixtures differ" always means N under this mapping.

Label `a` = source without `@print`/`@assert`/`@panic`; `b` = has one and a `fn main`; `c` = has one
but no `fn main`. Of the 131 `b` fixtures, 3 never reach codegen (`narrow_and_condition_field_access`,
`narrow_assert_pattern_with_print`, `string_slice_without_end_arg_slices_to_source_length` — frontend
gaps, [`../06-checker/README.md`](../06-checker/README.md)), leaving 128 comparable:

| backend | reproduces erlang | aborts | runs, prints something else | …of which **erlang** is the wrong one |
|---|---|---|---|---|
| commonJS | 96 | 15 | 17 | 6 |
| beam | 70 | 13 | 45 | 3 |
| wasm | 62 | 29 | 37 | 3 |

The wasm row, restated against the *program's* expected output rather than against erlang:

| Outcome | `b` (128) | `a` (145) | How it reconciles with the row above |
|---|---|---|---|
| runs to completion with the value the program means (`a` prints nothing by construction) | 64 | 134 | 62 that reproduce erlang + the 2 E1 fixtures where erlang crashes and wasm is right |
| runs to completion, prints the wrong value | 35 | — | 37 − those 2 |
| aborts on `unreachable` from an unresolved call | **27** | 3 | W1 |
| aborts on `unreachable` from `@todo` / `@panic` (correct behaviour) | 1 | 8 | `try_with_inline_catch_handler` (erlang's E4 — an abort is the right answer) |
| aborts on an out-of-bounds load | 1 | 0 | W10 |

27 + 35 + 1 = **63** defective `b` fixtures; W1…W11 close exactly those 63 (27 + 36, W10 being the one
abort among the 36).

`wasmtime compile` still accepts all 282 `WASM TEXT` blocks. Since `src/codegen/wat.zig:3038` turned
an unlowerable call into `unreachable` instead of folding it to a constant, loading is no longer the
interesting property — running is.

### The placeholders in the emitted text

The backend is honest in its text: each shape it cannot lower leaves a `;;` comment next to a
placeholder. Recounted at HEAD with `rg -oF '<placeholder>' snapshots/codegen/wasm/`:

| Placeholder | Occurrences | Snapshots | of which `b` |
|---|---|---|---|
| `;; unresolved call: <f>/<n>` (now on `unreachable`) | 59 | 38 | 27 |
| `;; lambda` (a lambda as a *value* → `i32.const 0`) | 9 | 9 | 1 |
| `;; cross-module import not linked (wasm single-module)` | 8 | 5 | 3 |
| `;; … (unknown receiver type)` | 6 | 5 | 5 |
| `;; loop over unknown iterable` | 5 | 4 | 3 |
| `;; folded non-numeric literal` | 3 | 3 | 0 |

52 snapshots carry at least one; 32 of them are label `b`.

Coverage (`scripts/snap_audit.sh --mode=coverage`): a/empty 145 · a/nonempty 0 · b/missing 3 ·
b/empty 128 · b/nonempty 0 · c/empty 2. On the other backends `b/empty` means "ran and exited
non-zero"; on wasm the 128 are the fixtures `executeWat` never ran.

## The ranked table

| # | Cause | Closes | Deciding site |
|---|---|---|---|
| W1 | The backend is never handed `instance_lowerings`, so no method call can resolve | **27** | `src/codegen/wat.zig:174` (the call), `:3038` (the `unreachable`) |
| W2 | A **string** reaches `@print` as a raw pointer and is printed as an integer | **10** | `lowerPrintArg`, `src/codegen/wat.zig:2366-2384` |
| W4 | A `loop` used as a **comprehension** runs its body and always yields `0` | **6** | the loop lowering; `isArrayExpr` (`src/codegen/AGENTS.md` §wat) |
| W5 | A `comptime { … break v; }` top-level `val` stays `0` | **4** | `emitGlobalVal`, `src/codegen/wat.zig:1705` |
| W6 | `case` discriminates only numeric and `or`-of-numeric patterns | **4** | the `case` lowering |
| W7 | `@Option` none is the bare value `0`, indistinguishable from a real `0` | **4** | a carrier decision, not a line |
| W3 | A **bool** prints as `1` / `0` | **3** | the `isBoolExpr` arm, `src/codegen/wat.zig:2372` |
| W8 | Field access on a receiver whose type is not recovered | **2** | `src/codegen/wat.zig:3183`, `:3186` |
| W9 | `array.slice` returns the raw bytes | **1** | — |
| W10 | `xs.at` / `xs.slice` over an empty array reads out of bounds | **1** | — |
| W11 | A non-string operand is dropped from a string concat | **1** | — |

W2 and W3 share one site and are ranked by that site (13 fixtures) in
[`README.md`](./README.md) step 4.

## W1 — the backend is never handed `instance_lowerings` (27 fixtures)

`codegenEmit` (`src/codegen/wat.zig:174`) calls

```zig
const code = try emitWat(alloc, ct.name, ok.transformed, ok.comptime_vals, ok.dispatch_rewrites, &cross);
```

Every other backend also passes `ok.instance_lowerings`:

```zig
// src/codegen/erlang.zig:332
const code = try emitErlang(alloc, ct.name, ok.transformed, ok.comptime_vals, ok.dispatch_rewrites, ok.instance_lowerings, module_test_mode, &cross);
// src/codegen/beam_asm.zig:428
const code = try emitBeamAsm(alloc, ct.name, ok.transformed, ok.comptime_vals, ok.dispatch_rewrites, ok.instance_lowerings, &cross);
```

Without that map, wasm has no `emitPrimMethod`, no `tryEmitPrimAnnotation` and no externals table.
`lowerCollectionMethod` (`src/codegen/wat.zig:3044`) serves exactly two methods, `at/1` and
`length/0`; everything else falls to `lowerPlainCall`'s

```zig
// src/codegen/wat.zig:3038
try self.emitCf(.@"unreachable", "unresolved call: {s}/{d}", .{ cc.callee, cc.args.len });
```

Its doc comment at `src/codegen/wat.zig:3004-3009` still describes the behaviour that line replaced
— "a callee this module never defines lowers to a zero placeholder plus a comment" — and is now
wrong.

### The seven sub-classes

The 27 fixtures split by what the unresolved callee is. Passing the map is the keystone; each
sub-class then needs its own lowering.

| Sub-class | Fixtures | Callees | What it needs |
|---|---|---|---|
| primitive / interface instance `default fn` | **10** | `join`, `fold`, `isEmpty`, `all`, `indexOf`, `zip`, `negate`, `nor`, `nand`, `exclusiveOr`, `abs`, `min`, `max`, `clamp`, `isEven`, `toUpper`, `toLower`, `contains`, `startsWith`, `endsWith` | the instance lowering the other backends already get from `instance_lowerings`; the bodies live in `libs/std/src/primitives.bp` |
| `#[@External.*]` `declare fn` | **8** | `b64encode`, `stringify`, `parseInt`, `str_length`, `floor`, `abs` | **a decision, not a lowering** — wasm has no host. Either a WASI import, a compile-time error, or a documented `unreachable` |
| interface associated fn / `from "std"` namespace call | **3** | `Pair.of`, `Array.first`, `order.toInt` | resolve the associated / namespaced symbol |
| cross-module symbol | **3** | `Pato`, `swim`, `ok`, `App` | the symbol lives in another module and wasm is single-module (`;; cross-module import not linked (wasm single-module)`) |
| lambda bound to a name, then called | **1** (+3 label `a`) | `add/2` | a lambda as a value lowers to `i32.const 0 ;; lambda`, so the named binding has nothing to call |
| record inherent method | **1** | `atual/0` | resolve the method against the record's decl |
| `join` after a `;; loop over unknown iterable` | **1** | `join` | W4's `isArrayExpr` widening first; the call then falls into the first sub-class |

The three label-`a` aborts are the `lambda_*` fixtures. No RUN LOG can ever show them, which is the
argument for fixing the lambda sub-class by construction rather than waiting for a `b` fixture.

### The 38 snapshots that carry `;; unresolved call:` today

`rg -lF ';; unresolved call:' snapshots/codegen/wasm/` at HEAD — the set step 2's acceptance
shrinks. 27 are the `b` aborts above, 3 are the label-`a` `lambda_*` aborts; the rest carry the
marker on a path the program does not reach.

`array_indexof_lowers_byte_identically_across_backends`, `array_instance_default_fn_methods`,
`array_join_lowers_byte_identically_across_backends`, `array_zip_via_external_node_template`,
`bool_instance_default_fn_methods`, `call_qualified_module_call_resolves_arity`,
`call_qualified_module_call_with_trailing_lambda_arity`, `dispatch_inherent_record_method_call`,
`dispatch_multi_module_extension_activated_via_star_import`,
`dispatch_multi_module_implement_on_an_imported_record`,
`dispatch_string_contains_lowers_to_native_includes`,
`dispatch_string_startswith_lowers_to_native_startswith`,
`endswith_lowers_via_external_beam_single_line_body`,
`external_a2_chained_host_call_renders_verbatim`,
`external_a2_method_on_global_template_keeps_receiver_bound`,
`external_a3_result_template_owned_declare_fn`, `external_call_emits_module_symbol`,
`external_global_math`, `external_import_binds_symbol`,
`external_target_mixed_with_external_in_one_decl`,
`external_target_template_equivalent_to_external_target_template`,
`import_cross_module_record_construct_and_assoc_fn`, `import_multi_module_pub_fn_import`,
`interface_associated_fn_namespace`, `iterator_fromlist_yields_array_items`,
`lambda_multi_param_with_type_annotation`, `lambda_multi_statement_body`,
`lambda_simple_standalone`, `lambda_standalone_with_params`, `lambda_with_parameter`,
`lambda_with_type_annotation`, `numeric_instance_methods_external_default_fn`,
`record_fn_typed_field_hook_shape_record`, `record_method_with_throw`,
`stdlib_associated_fn_namespace_injected`, `std_package_order_enum_module_with_type_export`,
`string_methods_map_to_native_js_names`, `try_catch_tail_on_method_call`.

## W2 and W3 — a string or a bool reaches `@print` as an i32 (13 fixtures, one site)

`lowerPrintArg` (`src/codegen/wat.zig:2366`) tries, in order, `isStringExpr` (`:2367`), `isBoolExpr`
(`:2372`) and `wasmTypeOf` (`:2377`), then falls to `$__print_i32` (`:2383-2384`). When the value's
type is not recovered it is an i32 pointer, the last arm wins, and the **address** is printed.

**W2 — 10 fixtures:**

| Fixture | wasm prints |
|---|---|
| `interface_literal_basic` | `276` |
| `loop_side_effect_print_in_iterator` | `256 268 284` |
| the five `template_end_to_end_*` | `301` / `307` / `320` / `351` / `256` |
| `destructure_tuple_val_binding` | `12 256` |
| `try_multiple_catch_with_different_fallbacks` | `288 0` |
| `if_simple_conditional_in_fn_body` | `256 0` |

**W3 — 3 fixtures**, the `isBoolExpr` arm (`:2372`) missing a bool it cannot prove, so `true`/`false`
print as `1`/`0`: `narrow_type_guard_basic_codegen`, `throw_inside_case_arm`,
`throw_inside_loop_body`.

**The fix is not in `lowerPrintArg`** — it is in what `isStringExpr` / `isBoolExpr` can prove. A
record/tuple field, a `case` result, a `try` result and a comptime-produced global all need a
recovered type. W8 has the same root.

**Caveat — `if_simple_conditional_in_fn_body` is only half W2's.** Its source is
`val r = if (n > 0) { "positive"; };` called with `5` and `-3`. The module's data segment places
`"positive"` at 256 (`(data (i32.const 256) "\08\00\00\00positive")`) and the `else` arm is
`i32.const 0`, so `256` is W2 and the `0` is the value of a value-less `if` — a question the
language has not answered (commonJS `undefined`, erlang `ok`, beam `undefined`, wasm `0`). W2 fixes
the first line; the second belongs to [`../06-checker/README.md`](../06-checker/README.md) and is
not re-recorded here.

## W4 — a `loop` used as a comprehension always yields `0` (6 fixtures)

`loop_break_with_value`, `loop_even_numbers_with_break`, `loop_filter_with_conditional_break`,
`loop_map_with_break_add_tax`, `loop_map_with_break_simple`, `loop_yield_accumulation`. The body runs
but nothing is accumulated: `yield` / `break <v>` must append into a new array blob that is the
loop's value.

4 of the 6 also carry `;; loop over unknown iterable`. `isArrayExpr` is deliberately narrow
(`src/codegen/AGENTS.md` §wat), so widening it is part of W4, not a separate cleanup.

These six are the same language shape the commonJS JS-1 bridge stands for
([`../04-js-bridges/bridges.md`](../04-js-bridges/bridges.md)): a `loop` in value position. And
`loop_break_with_value`'s own expected value is unsettled — `fn find(arr) -> i32` returns a list
(beam's B7 note, [`../01-beam/README.md`](../01-beam/README.md)); settle the return type in the
checker front before re-recording it.

## W5 — a `comptime { … break v; }` top-level `val` stays `0` (4 fixtures)

`comptime_block_with_break`, `comptime_folding_block_with_break_value_inlines_result`,
`comptime_folding_float_multiplication_folds_to_literal`,
`comptime_folding_multiplication_binds_tighter_than_addition`.

The global is declared `(global $pi2 (mut i32) (i32.const 0))` and `$__init_globals` sets it to
`i32.const 0` — the folded value never reaches `emitGlobalVal` (`src/codegen/wat.zig:1705`), and the
global's type is i32 even for an f64 value. The direct-literal form (`val v1 = comptime 1 + 1;`)
already works. Same language shape as erlang E5 and beam B1(a).

## W6 — `case` discriminates only numeric patterns (4 fixtures)

| Fixture | wasm prints |
|---|---|
| `case_string_literal_patterns` | `hello hello hello` |
| `narrow_case_enum_area_with_print` | `0 0` — the first arm runs with its payload unbound |
| `narrow_case_option_some_none` | `empty empty` |
| `narrow_case_result_ok_err_with_print` | `OK:` then raw payload bytes |

Needs string equality in a pattern test (`$__str_eq` exists) and a variant-tag test plus payload
binding.

## W7 — `@Option` none is `0` (4 fixtures)

| Fixture | wasm | the others |
|---|---|---|
| `array_at_lowers_byte_identically_across_backends` | `0` | `undefined` |
| `optional_fn_return_null_path` | `0` | — |
| `narrow_if_null_check_with_print` | `0` | `42` |
| `narrow_type_guard_if_codegen` | prints nothing | — |

A **carrier decision, not a bug fix**: pick a sentinel (a tagged pointer, or `-1`) and state it in
`src/codegen/AGENTS.md` before changing any lowering. It changes how every optional is represented
in wasm, so it can move a fixture that looks unrelated.

## W8…W11 — the tail (5 fixtures)

| # | Fixture | What happens | Mechanism |
|---|---|---|---|
| W8 | `template_end_to_end_yaml_model_computes_a_typed_record` | builds the record correctly (`8004`, `1` in memory) but reads `.port` as `0` | `src/codegen/wat.zig:3183` / `:3186` emit `i32.const 0 ;; field access .<f> (unknown receiver type)` (`:3183` is the optional-access twin). Same root as W2 |
| W8 | `interface_literal_with_fields` | reads `.fields.length` as `0` | same |
| W9 | `array_slice_2_arg_lowers_byte_identically_across_backends` | prints three NUL bytes | `array.slice` returns the raw bytes instead of an array |
| W10 | `option_method_on_tuple_element` | traps on an out-of-bounds load | `xs.at` / `xs.slice` over an empty array — the only non-`unreachable` trap |
| W11 | `narrow_else_if_chain_with_null_checks` | prints `nonzero:` and loses the `42` | a non-string operand dropped from a string concat — the wasm mirror of erlang E2 ([`../02-erlang/causes.md`](../02-erlang/causes.md)); agree on what a non-string operand renders as |

## Where wasm is right and erlang is wrong

Three `b` fixtures differ from erlang because **erlang** is the wrong backend. Do not "fix" wasm to
match them ([`../02-erlang/causes.md`](../02-erlang/causes.md#erlang-is-not-the-oracle)):

| Fixture | erlang | wasm | Cause |
|---|---|---|---|
| `destructure_record_parameter_in_fn` | crash | the program's value | E1 |
| `destructure_record_val_binding` | crash | the program's value | E1 |
| `try_with_inline_catch_handler` | crash | `unreachable` abort | E4 — the program calls `@todo()`, so an abort is the right answer |

## Edges

- **W1's instance-method and external sub-classes reach `libs/std/src/primitives.bp`**. The
  1.0.2-beta std-surface front that owned it has landed and no front owns `libs/std` until
  [`../12-surface-cutover/`](../12-surface-cutover/README.md); a lowering that needs a std change
  stops and reports.
- **W4 and JS-1, W11 and E2, W5 and E5/B1** are one language shape seen from several backends.
  Neither side waits for the other, but agree on the value the program means before either
  re-records.
- **W7 is a representation choice**, decided 2026-09-16 (box `?T`, `0` = null —
  [decision 3](../08-review-backlog/semantics-decisions.md#decision-3)). Record it before any lowering
  changes.

# Spec 03 — Codegen Hardening

**Version:** 1.0.1-beta
**Priority:** medium
**Depends on:** spec 06 step 0 (harness defects H1/H2/H5 in `src/codegen/runtime.zig`) and
spec 01 step 1 (leak-free `executeErlang`; same file)

---

## Objective

Every codegen snapshot either records real runtime output in its RUN LOG or is an explicit,
documented skip; the wrong RUN LOGs recorded as baseline are fixed; the comptime `erl`
runtime has direct regression tests.

Paths are relative to `repository/botopink-lang/modules/compiler-core/`.

## Current state

- Snapshot tests run generated code per backend through `src/codegen/runtime.zig`
  (`executeJavaScript` → `node`, `executeErlang` → `erlc` + `erl`, `executeBeamAsm` →
  `erlc +from_asm` + `erl`), all behind `runWithTimeout`, which returns `""` on success
  without output **and** on non-zero exit: a program that crashes (JS `SyntaxError`, missing
  `./gleam_stdlib.mjs`, erl `undef`/`badarg`, `erlc` error) records an empty RUN LOG, the same
  as one that prints nothing.
- Outputs are cached by content hash in the git-ignored `.botopinkbuild/runtime-cache`.
  **The beam and erlang RUN LOGs depend on that cache** (spec 06 H1/H2):
  - H1 (`runtime.zig:365`, `:375`): `executeBeamAsm` treats the empty output of a
    *successful* `erlc +from_asm` as failure, so a fresh run never executes BEAM. All 78
    non-empty beam RUN LOGs exist only via the local cache; from a cold cache 70 of them are
    recorded empty and 3 multi-module ones change.
  - H2 (`runtime.zig:305-314`): any `erlc` output (warnings included) returns `""`. From a cold
    cache 5 erlang RUN LOGs become empty (`array_zip_via_external_node_template`,
    `builtin_print_return_value_void`, `builtin_result_namespace_qualified_call_lowers_inline`,
    `external_a3_result_template_owned_declare_fn`, `stdlib_associated_fn_namespace_injected`)
    and 1 changes.
  - Fix H1/H2 (spec 06 step 0) and re-record from a cold cache **before** auditing the RUN LOGs
    below; the numbers for beam/erlang will move.
- `executeWat` is a stub returning `""`: WAT snapshots are generated but never executed. Its doc
  comment still describes the removed embedded interpreter (`comptime/runtime/wasm3_host.runWat`,
  `wat_to_wasm.compile` — neither exists); `codegen/wat.zig:69` repeats the reference. CI
  (`.github/workflows/test.yml`) already installs `wasmtime`.
- `src/comptime/runtime/persistent_erl.zig` has 0 tests. It is reached only through template /
  decorator evaluation (`template_eval.zig`, `decorator_eval.zig` → `evalDetailed`), i.e. from
  `comptime/tests/{templates,decorator_invocation,decorator_regression}.zig` and the codegen
  template tests. `comptime/tests/eval_pipeline.zig` does not reach it (comptime `val`s fold in
  Zig, `comptime/eval.zig`).
- Measured at HEAD with a warm cache (`scripts/snap_audit.sh --mode=coverage`). Label: `a` =
  source without `@print`/`@assert`/`@panic`; `b` = has one of them and `fn main`; `c` = has one
  but no `fn main`. State: RUN LOG section `missing` / `empty` / `nonempty`.

  | backend | a/missing | a/empty | a/nonempty | b/empty | b/nonempty | c/empty | total |
  |---|---|---|---|---|---|---|---|
  | node (commonJS) | 30 | 145 | 1 | 13 | 88 | 2 | 279 |
  | erlang | 30 | 146 | 0 | 37 | 64 | 2 | 279 |
  | beam | 30 | 145 | 0 | 23 | 78 | 2 | 278 |
  | wasm | 30 | 145 | 0 | 101 | 0 | 2 | 278 |
  | errors | — | — | — | — | — | 4 (`c/missing`) | 4 |

  `b/missing` and `c/nonempty` are 0 everywhere. The 30 `a/missing` per backend include the 29
  tests whose snapshot files are 0 bytes (spec 06 H3: failed compiles recorded as passing).
  RUN LOGs containing `undefined`: commonJS 9, erlang 1, beam 4, wasm 0.

The spec 06 reports ([`06-snapshot-review/`](./06-snapshot-review/)) list every codegen
`wrong-output` with evidence. Its root causes are folded into the table below; each was
re-checked at HEAD by running the recorded code (`node`, `erlc`/`erl`, `erlc +from_asm`,
`wasmtime`) unless marked *reported, unconfirmed*.

## Step 1 — Backend runtime gaps

After spec 06 step 0, re-audit every `b`/`c` snapshot with an empty RUN LOG and every
`undefined` RUN LOG; fix it or mark it as an intentional skip (documented in the test).

| Backend | File | Gap |
|---|---|---|
| commonJS | `src/codegen/commonJS.zig`, `libs/std/src/primitives.bp` | std string/array methods (`slice`, `length`, `split`, …) are `@External.Node("./gleam_stdlib.mjs", …)`, a file shipped nowhere; the emitted prelude patches `Array/String.prototype.slice` and requires it, so any `.slice` crashes (`string_slice_both_bounds`). Record destructuring with `..` emits `{ x, ... }` (SyntaxError, `destructure_record_*`). `return for …` (`loop_break_with_value`), `return continue`, `return if (…) … else …` (`if_conditional_with_else_branch`). `.len` → `undefined`/`NaN` (5 of the 9 `undefined` RUN LOGs). `@Result` case arms test `_s.tag === "Ok"` against the `{ ok: … }` runtime shape (`narrow_case_result_ok_err_with_print` prints `undefined`). `if` without `else` as an expression yields `undefined`. *Reported, unconfirmed:* `pub val` not exported; typedefs `x: ` without type; `try`/`catch` propagation |
| erlang | `src/codegen/erlang.zig` | `caseNode` (~l.3056) never emits `arm.guard` — guards dropped (`case_guard_variant_field_guard`). `patternNode` (~l.3104) builds variant patterns as `{tag, Ast.Expr.r(v.name), …}`: raw text → a variable, plus a `tag` element the constructor (`{'Circle', 2.0}`) does not have → `case_clause` (`narrow_case_enum_area_with_print`). Bare ident patterns become atoms only for locally declared variants (`enum_variants`), so imported unit variants (`Lt` from std `order`) bind a variable and the first arm always matches. Top-level `val` bound in `'_botopink_main'/0` but read in `main/0` (`Cfg`/`Page` unbound in `template_end_to_end_yaml_model_computes_a_typed_record`, `…_holed_html_via_parts_runs`); specialized fn reading a module `val` (`COMMANDS` in `comptime_partial_runtime_array_loop…`). Pipeline stages that are bare fn names lower to variables (`Inc(Double(1))`, `pipeline_simple_chain`). String `+` lowers to arithmetic `+` on binaries everywhere (`string_concat_of_two_literals`, template expansions). `@print` template `io:format("~p~n", [$args])` (~l.1340) takes one argument (badarg with several). `default fn` instance methods called as undefined locals (`all/2` in `array_instance_default_fn_methods`). `endsWith` → `string:suffix/2`, which does not exist in OTP (`primitives.bp` l.143-144). `&&`/`\|\|` → `and`/`or`, no short-circuit (~l.2629). *Reported, unconfirmed:* `lists:foreach` with a 2-arity fun; `try … catch throw` → `{ok,{error,…}}` |
| beam | `src/codegen/beam_asm.zig` | Register clobbering: `lowerTupleLit` (~l.3419) and `materializeCallArgs` (~l.3328) stage operands at `scratch_base = cur_arity` after lowering each into `{x,0}`; with `cur_arity == 0` slot 0 aliases `{x,0}` → tuple `{20,20}` (`tuple_construct_then_destructure` prints `40`), `both(false,false)` (`operators_logical_and`), `Pair.of(1,"one")` → both `"one"`. Case subject clobbered after the first failing arm (`case_string_literal_patterns` prints `hello hi hi`). `case` on enum unit variants emits no match test (`std_package_order_enum_module_with_type_export`). `@print` lowers only `args[0]` (`lowerBuiltinCall`, ~l.3161). `declare fn` externals without `@External.Beam` become local functions returning `ok` (`external_target_template_equivalent…`, `external_a3_result_template_owned_declare_fn`). Unresolved method calls emitted as `%% unresolved method call` comments (`zip/2`). `try`/`catch` on `@Result` rejected by the validator (`try_catch_on_result_with_default_fallback`: `Internal consistency check failed`, `test_heap`). Anonymous record field read → `undefined`. `.len` returns the value itself (`list_literal_len_reads_length_prefix` prints `[1,2,3]`). 0-arity `pub val` functions `deallocate` without `allocate` and are not exported (`val_pub_val_declaration`); an imported `pub val` lowers to the atom `{atom, 'HOST'}` instead of `config:'HOST'()` (`import_multi_module_pub_val_import`); a module `val` read from `main` is the atom `page` (`template_end_to_end_holed_html_via_parts_runs`). *Reported, unconfirmed:* `null` → `nil` while option helpers test `undefined`; `assert` dropped; `yield` → `return`; other validator rejections (`not_live`, `uninitialized_reg`) |
| wasm | `src/codegen/wat.zig`, `src/comptime/transform.zig` | Run through `wasmtime 45 run --invoke _botopink_main`, the 101 `b` wasm snapshots: 49 fail, 52 run, 21 of those print the commonJS RUN LOG. Invalid modules: `(local …)` mid-body (literal and enum `case`, `try`/`catch`), values left on / missing from the stack (externals `floor`/`str_length`, loops, `if`), `(param $ i32)` for destructured params, missing functions for instance/array/std methods (`$join`, `$at`, `$zip`, `$of`, `$toUpper`, …), module `val`s as unknown globals (`$page` in every `template_end_to_end_*`). Specialized functions get `.returnType = null` (`transform.zig:272`). Strings/bools printed as integers/pointers; `$__print_i32` reverses negative digits (`-42` → `-24`, `negation_simple_unary_minus`); multi-arg `@print` prints the first argument. *Reported, unconfirmed:* string `==` by pointer, string `+` as pointer sum |

**Wrong RUN LOGs recorded as baseline** — fix and re-accept. Every beam value below is reproduced
by assembling the recorded `.S` directly, but the suite only shows it via the runtime cache (H1);
from a cold cache these RUN LOGs are empty.

| Snapshot | Backend | Prints | Want | Cause |
|---|---|---|---|---|
| `array_zip_via_external_node_template` | beam | `[<<"a">>,<<"b">>,<<"c">>]` | `[{1,<<"a">>},…]` | `xs.zip(ys)` emitted as `%% unresolved method call: zip/2`; prints `ys` |
| `external_a3_result_template_owned_declare_fn` | beam | `-1` | `42` | `declare fn parseInt` (Erlang/Node externals only) becomes a local fn returning `ok`; `unwrapOr` takes the fallback |
| `stdlib_associated_fn_namespace_injected` | beam | `<<"one">>`, `42`, `10` | `1`, `42`, `22` | `materializeCallArgs` clobbering: `Pair.of(1, "one")` and `Function.compose(f, g)` receive the last argument twice |
| `std_package_order_enum_module_with_type_export` | beam | `-1`, `<<"less">>` | `-1`, `<<"greater">>` | `describe` has no match test on the enum atom; the first arm always runs |
| `std_package_order_enum_module_with_type_export` | erlang | `-1`, `<<"less">>` | `-1`, `<<"greater">>` | imported unit variant `Lt` emitted as a variable pattern (also warning-gated by H2) |
| `tuple_construct_then_destructure` | beam | `40` | `30` | `lowerTupleLit` clobbering (`{20,20}`) |
| `case_string_literal_patterns` | beam | `hello`, `hi`, `hi` | `hello`, `ola`, `hi` | subject register overwritten after the first failing arm |

**Acceptance:**
- [ ] Suite re-recorded from a cold runtime cache after spec 06 H1/H2
- [ ] No unexplained empty or `undefined` RUN LOG; each skip documented in its test
- [ ] The baseline snapshots above print the expected values
- [ ] `template_end_to_end_*` run on erlang and beam with the expected output

## Step 2 — WAT execution

Decide between running WAT through `wasmtime` in `executeWat` (same `runWithTimeout` wrapper;
CI already installs it) or accepting empty WAT RUN LOGs as the baseline. Running it today would
turn 49 of the 101 `b` wasm snapshots into load failures (see the wasm row), so the decision
comes with either the invalid-module fixes or documented skips. Rewrite the stale `executeWat`
doc comment (and `wat.zig:69`) either way; spec 05 item 5.6 overlaps.

**Acceptance:**
- [ ] Decision recorded in `src/codegen/AGENTS.md`
- [ ] wasm RUN LOGs either populated or explicitly documented as not executed

## Step 3 — Missing codegen coverage

Add snapshot tests (all backends, documented skips) for: optional/null, cross-module imports,
interface/implement, records/enums, generics, lambdas/operators/annotations
(`src/codegen/tests/{values,features,aggregates}.zig`), and template/`@Expr` holes with runtime
values and comptime eval results (`src/codegen/tests/comptime.zig`). Where a gap above is only
visible through a silent source (e.g. `destructure_tuple_var_binding` builds `{20,20}` and prints
nothing), make the test print the result.

## Step 4 — `persistent_erl` regression tests

- Spawn + round-trip of a trivial module.
- Respawn after the `erl` child is killed mid-session.
- `main/0` exceeding the eval timeout (`eval_timeout_ms`) → `runtime_error`, server keeps serving.
- Frame edge cases: empty payload, large payload, non-ASCII bytes.
- Compile/runtime error text reaches the caller (`evalDetailed`) and the compiler diagnostic.
- No orphan `beam.smp` after the tests.

## Step 5 — Final sweep

`zig build test` (from a cold runtime cache) `&& zig build test-libs && zig build test-backends`
green.

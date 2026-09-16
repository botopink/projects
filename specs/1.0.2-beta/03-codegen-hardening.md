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
start with `libs/`, which is relative to `repository/botopink-lang/`. Every `file:line` is at
HEAD.

## How the numbers below were measured

They are not read off the snapshots — a snapshot's RUN LOG only says what the harness recorded,
and for wasm it records nothing at all. Each backend's emitted code was extracted from the
snapshot and executed outside the suite:

| Backend | How |
|---|---|
| commonJS | `node --check <module>.js` on every emitted module (syntax), then `node main.js` |
| erlang | `erlc -o . <mod>.erl` per module, then `erl -noshell -eval "main:'_botopink_main'()"` inside a `try … catch C:E:S -> …` so the crash class and stack are visible instead of an empty log |
| beam | `erlc +from_asm` per module, same runner; plus the full-export audit below |
| wasm | `wasmtime run <module>.wat` (wasmtime 45), stdout + exit status |

Cross-backend agreement is compared under a **representation mapping**, because erlang and beam
print through `~p`: `<<"x">>` → `x`, `<<>>` → empty, `1.0` → `1`, `[ 2, 4 ]` → `[2,4]`. Comparing
the raw text instead reports 22 extra commonJS fixtures as "wrong" that differ only in how a
string is rendered. A spec row that says "N fixtures differ" always means N under this mapping.

---

## Current state

`zig build test` is green and every snapshot's RUN LOG is the result of a real run (or of a real
compile failure). `scripts/snap_audit.sh --mode=coverage` — label `a` = source without
`@print`/`@assert`/`@panic`, `b` = has one and a `fn main`, `c` = has one but no `fn main`:

| backend | a/empty | a/nonempty | b/missing | b/empty | b/nonempty | c/empty | total |
|---|---|---|---|---|---|---|---|
| node (commonJS) | 145 | 1 | 3 | 18 | 110 | 2 | 279 |
| erlang | 146 | 0 | 3 | 6 | 122 | 2 | 279 |
| beam | 145 | 0 | 3 | 18 | 110 | 2 | 278 |
| wasm | 145 | 0 | 3 | 128 | 0 | 2 | 278 |

- `a/missing` and `c/nonempty` are 0 everywhere.
- `b/empty` is a program that ran and exited non-zero — a crash, not silence.
- `b/missing` is the same three slugs on all four targets: the documented `assertJsCompileError`
  skips whose programs do not reach codegen at all (`narrow_and_condition_field_access`,
  `narrow_assert_pattern_with_print`, `string_slice_without_end_arg_slices_to_source_length`).
  Frontend gaps, not codegen gaps — they belong to the type-system/parser spec, and each one
  unblocks a codegen fixture here (and `narrow_assert_pattern_with_print` is what blocks spec 04
  step 5).
- `COMPILE ERROR` blocks left in a RUN LOG: 1 (erlang `comptime_block_with_break`), 0 elsewhere.
- `src/comptime/runtime/persistent_erl.zig` still has **0** tests.

### Where each backend stands against the others

Of the 131 `b` fixtures, 3 never reach codegen, leaving 128 comparable. The first three columns
sum to 128; the fourth re-counts rows already inside one of them.

| backend | reproduces erlang | aborts | runs, prints something else | …of which **erlang** is the wrong one |
|---|---|---|---|---|
| commonJS | 96 | 15 | 17 | 6 |
| beam | 70 | 13 | 45 | 3 |
| wasm | 62 | 29 | 37 | 3 |

wasm is not executed by the suite at all; its row is `wasmtime run` output measured as above.

**Erlang is not the oracle.** The 1.0.1-beta measurement assumed it was; running the other three
found seven fixtures where erlang is the backend that is wrong, four of them silently:

| Fixture | erlang | who is right | Cause |
|---|---|---|---|
| `throw_inside_case_arm` | `true true` | beam (`true false`) | E8 below |
| `std_package_order_enum_module_with_type_export` | `-1 less` | commonJS (`-1 greater`) | E6 below |
| `narrow_type_guard_if_codegen` | `false` | commonJS (`true`) | E7 below |
| `iterator_fromlist_yields_array_items` | `<<>>` | commonJS (`1,2,3`) | an eager `#[@iterator]` list is consumed as empty |
| `comptime_block_with_break` | `COMPILE ERROR` | commonJS (`20`) | E5 below |
| `endswith_lowers_via_external_beam_single_line_body` | crash | commonJS (`true`) | E3 below |
| `destructure_record_val_binding` / `destructure_record_parameter_in_fn` | crash | commonJS, beam, wasm | E1 below |

A cross-backend assertion must therefore be written against the *program's* expected output, not
against whatever erlang printed.

---

## Step 1 — commonJS

15 fixtures abort and 17 run and print something else. Of the 17, six are fixtures where **erlang**
is the wrong one and one is an undecided language question, leaving 10 real commonJS wrong values.
Five causes cover all 25 (15 aborts + 10 wrong values), ranked by how many they close; two of the
five are not commonJS's to fix.

| # | Cause | Closes | Mechanism, deciding line, fix shape | Local? |
|---|---|---|---|---|
| C1 | The std string/array methods are `#[@External.Node("./gleam_stdlib.mjs", …)]` and that file exists nowhere in the repository | **9** | `libs/std/src/primitives.bp` names it 22 times (`:118`, `:122`, `:140`, `:145`, `:150`, `:154`, `:158`, `:162`, `:174`, `:178`, `:231`, `:235`, `:561`, `:565`, `:569`, `:581`, `:590`, `:594`, `:598`, `:602`, `:828`, `:832`); `external_import_binds_symbol` names a second phantom, `./stdlib.mjs`. 11 snapshots emit the `require`; it sits **inside the method body**, so only a fixture that actually calls the method dies (`Error: Cannot find module './gleam_stdlib.mjs'`). `gleam_stdlib.mjs` is **the Gleam language's runtime** (the symbols are Gleam's: `string_length`, `starts_with`, `trim_start`; `libs/std/src/order.bp:1` admits the borrowing), so shipping it is not an option — botopink would depend on another language's ABI for `slice`. Lower each of these to the native JS method the annotation already names (`slice`, `split`, `startsWith`, `trim`, `indexOf`, `join`, `map`, `filter`, `push`, `pop`). | `libs/std` only — **no compiler change**, which is why it belongs to the std-surface row and not to a backend row |
| C2 | The JS bridges emit JavaScript that does not parse | **8** (6 visible) | Owned by [`04-emitter-centralization.md`](./04-emitter-centralization.md) steps 1–3. `node --check` over every emitted module finds **12** unparseable snapshots; 8 are label `b`, and 2 of those 8 are invisible today because erlang crashes on the same fixture. Do not fix them here. | — |
| C3 | `.len` passes through as a property read → `undefined`, and `NaN` in arithmetic | **7** | `src/codegen/commonJS.zig:2171` — the `identAccess` arm has no `len` case; `rg '"len"' commonJS.zig` is empty, while `erlang.zig:3041`, `wat.zig:3111` and `beam_asm.zig:2573` all have one. Fixtures: `string_concat_of_two_literals`, `string_length_after_concat`, `string_len_participates_in_arithmetic`, `list_literal_len_reads_length_prefix`, `list_literal_of_strings_len`, `list_literal_of_records_len`, `empty_list_literal_len_is_zero`. Map `.len` to `.length` on a string/array receiver. | local |
| C4 | An enum variant's payload is destructured **by the binding name**, not by the declared field name | **2** | `src/codegen/commonJS.zig:2957` — `props[bi] = .{ .key = bb };`, where `bb` is the *binding*. `Shape.Circle(radius)` builds `{ tag: "Circle", radius }`, and the arm `Circle(r) ->` emits `const { r } = _s;` — `r` is never a key, so the binding is `undefined` (`narrow_case_enum_area_with_print` prints `NaN NaN`, `narrow_case_option_some_none` prints `value: undefined`). The prop must carry the declared field as the key and the binding as the value (`const { radius: r } = _s;`); positional order comes from the same `collectTypeShapes` field order erlang uses. | local |
| C5 | `@Result` `case` arms test `subject.tag === "Ok"` while `#[@result]` materialises `{ ok: … }` / `{ error: … }` | **1** | `src/codegen/commonJS.zig:2967` — the same `.variant` arm as C4, four lines down. Emitted `fetch` in `narrow_case_result_ok_err_with_print` returns `({ ok: "data" })` and both arms miss → `undefined` twice. One shape: build the arm test against the `ok`/`error` keys (as `erlang.zig`'s `resultTag` does), or make `#[@result]` emit `{ tag, … }`. The first is smaller and leaves `try`/`catch` (`"error" in _r`) consistent. | local |

`if_simple_conditional_in_fn_body` is the one remaining difference and is **not a defect to fix
blindly**: `val r = if (n > 0) { "positive"; };` with no `else` yields `undefined` on commonJS,
`ok` on erlang, `undefined` on beam and `0` on wasm. Four backends, four answers to a question
the language has not answered. Decide the value of a value-less `if` in
[`02-type-system.md`](./02-type-system.md) and make all four agree; do not re-record here.

**New gate.** `node --check` on every emitted module costs nothing and would have caught all 12
unparseable snapshots, 4 of which are label `a` and therefore invisible to the RUN LOG forever
(`case_multiple_subjects`, `destructure_record_val_binding_with_spread`,
`loop_continue_in_iteration`, `range_open_ended_range`). Add it to `runtime.zig`'s
`executeJavaScript` path (a `COMPILE ERROR (node --check):` block, mirroring
`COMPILE ERROR (erlc):`), so an unparseable module is recorded instead of being silently empty.

**Acceptance:**
- [ ] `node --check` passes for every module under `snapshots/codegen/commonJS/`, or the failure
      is recorded as a `COMPILE ERROR (node --check):` block
- [ ] commonJS `b/empty` ≤ the count explained by the bridges in spec 04
- [ ] No commonJS RUN LOG records `undefined` / `NaN` except where the program really prints a
      none/null value (`optional_fn_return_null_path`,
      `array_at_lowers_byte_identically_across_backends`)
- [ ] `zig build test` green

## Step 2 — erlang

Six fixtures abort, one emits a module that does not compile, and three print a wrong value
silently. Eight causes, one fixture each except where noted; the crash class comes from running
the emitted `.erl` under a `try … catch`.

| # | Cause | Closes | Mechanism, deciding line, fix shape | Local? |
|---|---|---|---|---|
| E1 | A record destructuring lowers to a **tuple** pattern, but a record is a **map** | **2** | `destructPatternExpr` (`src/codegen/erlang.zig:2857-2868`), deciding line **`:2867`** `return .{ .tuple = items.items };`. `val { x, y } = p` emits `{X, Y} = P` against `#{x => 3, y => 4}` → `{badmatch, #{x => 3,y => 4}}`; `fn greet({ name, .. }: Person)` emits `greet({Name, _})` → `function_clause`. The `.names` arm must build `.map` with `exact = true` (`beam/erl_ast.zig:130-135` already carries `MapField.exact` for `:=`), i.e. `#{name := Name}`; `.tuple_` keeps the tuple. Reached from `fnForms` (params), `stmtExpr` `:2905` (`val`) and `propagateTryExpr` `:2837`. | local — the model already has the node |
| E2 | A **non-string** operand of a string `+` is written as a `/binary` segment | **2** | `concatSegments` (`erlang.zig:2002-2021`), deciding line **`:2020`** `try out.append(b.arena, .{ .value = value, .type = "binary" });` — the segment type is a constant. `"value: " + v` with `v : i32` emits `<<"value: ", V/binary>>` → `badarg` with `error_info` `{2, binary, type, 42}`. `isStringExpr` (`:2026`) proves the *chain* is a string because one operand is a literal; the per-segment check is missing. Give each segment the type its own operand proves: `binary` when `isStringExpr(e)`, otherwise a stringify — `formatNode` (`:3592`) already builds `iolist_to_binary(io_lib:format("~p", [E]))`, or `integer_to_binary/1` for an integer operand. Fixtures: `narrow_case_option_some_none`, `narrow_else_if_chain_with_null_checks`. | local |
| E3 | `string:suffix/2` is not an OTP function | **1** | `libs/std/src/primitives.bp:143` `#[@External.Erlang("string", "suffix")]` and `:144` `@External.Beam(""" {call_ext, 2, {extfunc, string, suffix, 2}}.""")` — `erl` answers `undef [{string,suffix,[<<"foobar">>,<<"bar">>],[]}]`. Not a codegen gap at all: the annotation names a function OTP never had. Replace with a real suffix test (`binary:longest_common_suffix/1`, or `string:find(S, Suf, trailing)` compared against `Suf`). Fixture: `endswith_lowers_via_external_beam_single_line_body`. | `libs/std` only — std-surface row |
| E4 | `@todo()` raises, and the `try … catch` lowering is a `case`, which cannot catch a raise | **1** | `try fetch() catch 0` lowers to `case fetch() of {ok,V} -> …; {error,E} -> … end`, but `@todo()` inside the `#[@result]` `fetch/0` emits `erlang:error({todo, <<"not implemented">>})`. The raise flies past the `case` and the program dies. Two shapes: make `@todo`/`@panic` inside a `#[@result]` body return `{error, …}`, or wrap the propagating `case` in a real `try … catch error:E`. The second matches what `throw` already does and is the smaller change. Fixture: `try_with_inline_catch_handler`. Note wasm gets this fixture **right** for the wrong reason (`unreachable` aborts, which is also an abort). | local |
| E5 | A comptime block drops every statement before its `break` | **1** | `comptimeNode`'s `.comptimeBlock` arm (`erlang.zig:3625-3633`) returns only the `break` expression; `val result = comptime { val x = 10; break x * 2; };` emits `result() -> (X * 2).` → `main.erl:6:6: variable 'X' is unbound`. The value is already folded (`COMPTIME VALUES: ct_0 → 20`), so `topValForms` (`:2240`) reading `comptime_vals` for a `comptime` val is the smaller fix — that is exactly what commonJS does (`const result = 20;`). **The same latent bug sits in `commonJS.zig:2405-2415` and is only unreached because the decl-level path folds first.** | local |
| E6 | A `case` pattern naming a variant of an **imported** enum is lowered as a variable | **1** | The consumer module of `std_package_order_enum_module_with_type_export` emits `case O of Lt -> <<"less">>; Gt -> …` — `Lt` and `Gt` are unquoted, so the first arm binds and matches anything. `enum_variants` is populated from the module's own decls; `collectImportedTypes` carries an imported record's fields but not an imported enum's variants. Silent wrong answer: prints `less` where the program means `greater`. beam reproduces it; commonJS is right. | needs `collectImportedTypes` to carry variants — small model change |
| E7 | A `return` inside a narrowed `if` arm is discarded | **1** | `fn isString(x: ?string) -> x is string { if (x) { s -> return true; }; return false; }` emits `case X of undefined -> undefined; S -> true; _ -> ok end, false.` — the `case` value is thrown away and `false` is returned unconditionally. The binding-form `if` goes through `condNode`/`mutatingExpr` instead of `earlyReturnIfExpr`, which is what nests the rest of the body in the false arm. Silent wrong answer: prints `false` where the program means `true`. Also emits a dead `_ -> ok` clause. | local |
| E8 | `return <case>` in a `#[@result]` fn wraps the **whole** case in `{ok, …}` | **1** | `return case s { Ok -> 1; Fail -> throw "failed"; }` emits `{ok, case S of 'Ok' -> 1; 'Fail' -> {error, <<"failed">>} end}` — the throwing arm becomes `{ok, {error, …}}` and `isOk()` answers `true`. The `#[@result]` wrap must be pushed **into** each non-jumping arm. Silent wrong answer; beam is right. commonJS has the same shape spelled as `return return ({ error: … })` — a SyntaxError, and therefore the JS-1 row in spec 04. Fixing the wrap here fixes the JS shape too. | shared with commonJS — the wrap decision is in the transform pass, not the backend |

### The `Ast.Expr.r("")` inventory

13 `Ast.Expr.r(` in `erlang.zig`. **Seven** stand in for a missing value (not five, as 1.0.1-beta
recorded): `:2308` (a bare `yield;` item in an eager generator list), `:3174` (`return` with no
value), `:3175` (`throw` with no value), `:3176` (`try` with no value), `:3184` (`yield` with no
value), `:3628` (a comptime block whose `break` carries no value) and `:3632` (a comptime block
with no `break` at all). Each renders as nothing, which is how the bare-`break` bug produced a
syntactically broken module before it was fixed. Give every one a real node. The other six are
spec 04's: four unreachable fallbacks (`:2967`, `:2977`, `:3537`, `:3768`), the `headCall` head
(`:3668`) and the host template text (`:1566`).

**Acceptance:**
- [ ] 0 `COMPILE ERROR` blocks under `snapshots/codegen/erlang/`
- [ ] erlang `b/empty` = 0
- [ ] No `Ast.Expr.r("")` left in a value position (7 sites)
- [ ] E6, E7 and E8 have a fixture whose RUN LOG is the value the *program* means, cross-checked
      against commonJS and beam

## Step 3 — beam

58 of the 128 comparable `b` fixtures disagree with erlang, 13 of them by aborting. Twelve causes
cover 55 of the 58 (the other 3 are the fixtures where erlang is wrong); the first cause alone
accounts for 22. Its blast radius is wider than that: 23 snapshots move a top-level `val`'s name
as an atom (21 label `b`, 2 label `a`), and two more fixtures reach the same line through a
closure free variable and through `self`.

| # | Cause | Closes | Mechanism, deciding line, fix shape | Local? |
|---|---|---|---|---|
| B1 | **An identifier the emitter cannot resolve is emitted as an atom of its own name** | **22** | `src/codegen/beam_asm.zig:1824` — `try beamEmitter.writeMove(self.out, Term.atomOf(n), 0);`, the fallthrough after the `reg_map` (`:1792`), comptime-value (`:1804`) and `crossOwnerOf` (`:1812`) checks. It is silent and it produces a *value*, so the program runs and prints a word. Three distinct things reach it: **(a)** the module's **own** top-level `val` — `beam_asm.zig:514` and `:562` emit the 0-arity function only `if (!has_main_0 …)`, so any module with a `fn main()` never gets one, and `val sum = 1 + 2; @print(sum)` assembles a module with no `sum/0` and prints `sum`; **(b)** a **closure free variable** — `loop (0..n) { i -> @print(n - i) }` lowers the lambda with a fresh `reg_map`, so the enclosing `n` becomes the atom `n` and the body dies with `badarith [{erlang,'-',[n,0]}]`; **(c)** **`self`** in a `val`-bound record method — `'Counter_inc'/0` is emitted with arity 0 and moves `{atom, self}` into `{x,0}`, which is the first of the two latent register rejections below. Fix: drop the `!has_main_0` guard and reserve/export/emit every **named** top-level `val` as a 0-arity function (`erlang.zig:2240` `topValForms` is the model — only `_`-named synthetic statements stay ordered inside `_botopink_main`); make the lambda lowering carry the enclosing frame; thread `self` as a real parameter; and then make `:1824` **fail loudly** (a `%% unresolved identifier` note plus an abort) instead of inventing an atom. | model change (the val-as-function decision), then local |
| B2 | A `declare fn` external with no `@External.Beam` body becomes a local function returning `ok` | **8** | `external_a2_chained_host_call_renders_verbatim`, `external_a2_method_on_global_template_keeps_receiver_bound`, `external_call_emits_module_symbol`, `external_global_math`, `external_import_binds_symbol`, `external_target_mixed_with_external_in_one_decl`, `external_target_template_equivalent_to_external_target_template` (all print `ok`); `external_a3_result_template_owned_declare_fn` prints `-1` via `unwrapOr`. Resolve to the `@External.Erlang` form where one exists (a BEAM `call_ext` to the same `{module, symbol}`), otherwise fail the lowering loudly. | local |
| B3 | String `+` and interpolation lower to the arithmetic `{gc_bif, '+', …}` on two binaries | **6** (+2 hidden) | `string_concat_of_two_literals` emits `{move, {literal, <<"hi ">>}, {x,0}}` … `{gc_bif, '+', {f,0}, 2, [{x,1},{x,0}], {x,0}}` → `badarith [{erlang,'+',[<<"hi ">>,<<"there">>]}]`. Also `string_interpolation_lowers_to_concat`, `string_length_after_concat`, `reserved_word_identifiers`, `builtin_print_with_variable`, `narrow_early_return_with_print`. Two more (`narrow_case_option_some_none`, `narrow_else_if_chain_with_null_checks`) carry the same defect but are invisible in the diff because erlang aborts on them too (E2). Build a binary instead, as `erlang.zig`'s `stringConcatNode` (`:1996`) does — and port E2's per-segment type decision at the same time, or beam inherits the same `badarg`. | local |
| B4 | Primitive / interface instance methods are not lowered (`%% unresolved method call`) | **8** | 28 snapshots carry at least one `%%` marker (20 distinct method names). The 8 that show as a wrong value: `array_instance_default_fn_methods` (`fold/3`, `all/2` — prints `[1,2,3]` where erlang prints `6` / `true`), `array_zip_via_external_node_template` (`zip/2`), `bool_instance_default_fn_methods` (`negate/1`, `nor/2`, `nand/2`, `exclusiveOr/2` — every answer inverted), `numeric_instance_methods_external_default_fn` (`abs/1`, `min/2`, `max/2`, `clamp/3`, `isEven/1`), `dispatch_inherent_record_method_call` (`atual/1` — prints the whole map), `string_methods_map_to_native_js_names` (`split/2` "complex arg" + `slice/3`, dies with `{case_clause, <<"Hello,World">>}`), `string_slice_both_bounds` and `string_slice_result_length_is_readable` (`slice/3`, off by the start offset). The marker means the receiver was left in `{x,0}` and the call dropped. | needs the annotation / template path of `src/codegen/AGENTS.md` §Primitive methods extended |
| B5 | Record and interface **literals** are unsupported | **4** | `%% unsupported: record literal` (6 occurrences) and `%% unsupported: interface literal` (2). `anon_record_let_bound_then_field_read_by_name`, `nested_anon_record_chained_field_read`, `interface_literal_basic` print `undefined`; `interface_literal_with_fields` dies with `badarg [{erlang,length,[undefined]}]`. beam already builds records through `put_map_assoc` for a declared `record`; an anonymous literal needs the same. | local |
| B6 | An indexed loop builds a 2-parameter fun for `lists:foreach/2` | **1** | `loop (messages, 0..) { msg, i -> … }` → `make_fun3` of arity 2 handed to `lists:foreach/2`, which passes **one** element → `function_clause`. erlang solved this with `lists:enumerate(Start, Xs)` and a single `{I, Item}` tuple parameter (`codegen/AGENTS.md` §erlang/Loops); beam must do the same. `loop_side_effect_print_in_iterator`. | local |
| B7 | A loop comprehension lowers through `lists:map` instead of `lists:filtermap` | **1** | `loop_break_with_value` prints `[ok,ok,15,20]` where erlang prints `[15,20]`: the non-breaking arm yields `ok` instead of being filtered out. erlang's `filterMapFunBody` is the shape. (The fixture's own expected value is itself unsettled — `fn find(arr) -> i32` returns a **list**; settle that in spec 02 before re-recording.) | local |
| B8 | `@Result` `case` arms print the whole tuple | **1** | `narrow_case_result_ok_err_with_print` prints `{ok,<<"data">>}` where erlang prints `<<"OK:data">>` — the arm pattern does not destructure. | local |
| B9 | Register staging clobbers a live x-register | **1** | `stdlib_associated_fn_namespace_injected` prints `1 42 10` where erlang prints `1 42 22`; the full-export audit rejects `'Pair_mapFirst'/2+23`, `'Pair_mapSecond'/2+23` and `'Pair_swap'/1+18` with `{test_heap,3,3}` / `{{x,1},not_live}`. This is the staging-site class `src/codegen/AGENTS.md` names (`lowerTupleLit` / `lowerRecordConstruct` / `lowerTaggedTuple` / `materializeCallArgs`). | local |
| B10 | A value-less `if` yields `undefined` | **1** | `if_simple_conditional_in_fn_body`. Same undecided-value question as commonJS — settle in spec 02, do not re-record. | — |
| B11 | An `if`-with-binding on a nullable prints nothing | **1** | `narrow_if_null_check_with_print`: the assembled module runs, exits 0 and prints **nothing** — the narrowed arm never fires for `x = 42`. (The current harness records this as `b/empty`, which reads as "crashed"; it did not.) | local |
| B12 | Cross-module record construction + associated fn aborts | **1** | `import_cross_module_record_construct_and_assoc_fn` — erlang and commonJS both print `hi` / `8080`. | local |

Three more fixtures differ because **erlang** is wrong, not beam: `throw_inside_case_arm` (E8),
`destructure_record_parameter_in_fn` and `destructure_record_val_binding` (E1). Do not "fix" beam
to match them.

### The full-export audit

Two register bugs are invisible in the tree because the recorded modules carry a narrow
`{exports, …}` form and `erlc +from_asm` drops unexported functions before validating them.
Rewriting each snapshot's exports to name every `{function, …}` form and assembling: **269
modules assembled, 2 rejected.**

| Snapshot | Rejection | Cause |
|---|---|---|
| `field_assign_self_field_update` | `'Counter_inc'/0+9`: `{put_map_exact,{f,0},{x,0},{x,0},2,{list,[{atom,count},{x,1}]}}` — `{bad_type,{needed,{t_map,any,any}},{actual,{t_atom,[self]}}}` | **B1(c)**, not a staging bug: the function is emitted at arity 0 and `{move, {atom, self}, {x, 0}}` puts an atom where a map is required |
| `stdlib_associated_fn_namespace_injected` | `'Pair_mapFirst'/2+23`, `'Pair_mapSecond'/2+23`, `'Pair_swap'/1+18`: `{test_heap,3,3}` — `{{x,1},not_live}` | **B9** |

Ship the audit as `scripts/beam_export_audit.sh` so the narrow exports form cannot hide a
rejection again.

**Acceptance:**
- [ ] Every beam `b` snapshot reproduces the value the program means, or the divergence is
      documented in its test
- [ ] beam `b/empty` = 0
- [ ] `beam_asm.zig:1824` no longer invents an atom: an unresolved identifier is a hard failure
- [ ] `scripts/beam_export_audit.sh` assembles 269/269 and runs in the gate

## Step 4 — wasm

`executeWat` (`src/codegen/runtime.zig:553`) returns `""`, so wasm is the only backend with 0
observable RUN LOGs. All 282 `WASM TEXT` blocks still pass `wasmtime compile` — but since
`wat.zig:3038` turned an unlowerable call into `unreachable` instead of folding it to a constant,
loading is no longer the interesting property: **29 of the 128 executable `b` modules now abort
at run time.**

Measured by running every module under `wasmtime run`:

| Outcome | `b` (128) | `a` (145) |
|---|---|---|
| runs to completion with the value the program means (`a` prints nothing by construction) | 64 | 134 |
| runs to completion, prints the wrong value | 35 | — |
| aborts on `unreachable` from an unresolved call | 27 | 3 |
| aborts on `unreachable` from `@todo` / `@panic` (correct behaviour) | 1 | 8 |
| aborts on an out-of-bounds load | 1 | 0 |

The honest placeholders left in the emitted text:

| Placeholder | Occurrences | Snapshots | of which `b` |
|---|---|---|---|
| `;; unresolved call: <f>/<n>` (now on `unreachable`) | 59 | 38 | 27 |
| `;; lambda` (a lambda as a *value* → `i32.const 0`) | 9 | 9 | 1 |
| `;; cross-module import not linked (wasm single-module)` | 8 | 5 | 3 |
| `;; … (unknown receiver type)` | 6 | 5 | 5 |
| `;; loop over unknown iterable` | 5 | 4 | 3 |
| `;; folded non-numeric literal` | 3 | 3 | 0 |

52 snapshots carry at least one; 32 of them are label `b`.

### Causes, ranked

| # | Cause | Closes | Mechanism, deciding line, fix shape |
|---|---|---|---|
| W1 | **The backend is never handed `instance_lowerings`, so no method call can resolve** | **27** | `codegenEmit` (`wat.zig:174`) calls `emitWat(alloc, ct.name, ok.transformed, ok.comptime_vals, ok.dispatch_rewrites, &cross)` — every other backend also passes `ok.instance_lowerings` (`erlang.zig:332`, `beam_asm.zig:428`). wasm has no `emitPrimMethod`, no `tryEmitPrimAnnotation` and no externals table; `lowerCollectionMethod` (`wat.zig:3044`) serves exactly two methods, `at/1` and `length/0`, and everything else falls to `lowerPlainCall`'s `unreachable` at **`wat.zig:3038`** (whose doc comment at `:3004-3009` still describes the old constant-folding behaviour and must be corrected). The 27 fixtures split into seven sub-classes by what the unresolved callee is — **10** primitive/interface instance `default fn`s (`join`, `fold`, `isEmpty`, `all`, `indexOf`, `zip`, `negate`, `nor`, `nand`, `exclusiveOr`, `abs`, `min`, `max`, `clamp`, `isEven`, `toUpper`, `toLower`, `contains`, `startsWith`, `endsWith`), **8** `#[@External.*]` `declare fn`s (`b64encode`, `stringify`, `parseInt`, `str_length`, `floor`, `abs`), **3** interface associated fns / `from "std"` namespace calls (`Pair.of`, `Array.first`, `order.toInt`), **3** cross-module symbols (`Pato`, `swim`, `ok`, `App`), **1** lambda bound to a name and then called (`add/2`; plus 3 label-`a` fixtures), **1** record inherent method (`atual/0`), **1** `join` after a `;; loop over unknown iterable`. Passing the map is the keystone; each sub-class then needs its own lowering, and the external sub-class needs a decision (wasm has no host — either a WASI import, a compile-time error, or a documented `unreachable`). |
| W2 | A **string** reaches `@print` as a raw pointer and is printed as an integer | **10** | `lowerPrintArg` (`wat.zig:2366`): `isStringExpr` (`:2367`) → `isBoolExpr` (`:2372`) → `wasmTypeOf` (`:2377`) → `$__print_i32` (`:2383-2384`). When the receiver's type is not recovered the value is an i32 pointer and the last arm wins, so the *address* is printed: `interface_literal_basic` → `276`, `loop_side_effect_print_in_iterator` → `256 268 284`, the five `template_end_to_end_*` → `301`/`307`/`320`/`351`/`256`, `destructure_tuple_val_binding` → `12 256`, `try_multiple_catch_with_different_fallbacks` → `288 0`, `if_simple_conditional_in_fn_body` → `256 0`. The fix is not in `lowerPrintArg` — it is in what `isStringExpr` can prove: a record/tuple field, a `case` result, a `try` result and a comptime-produced global all need a recovered type. |
| W4 | A `loop` used as a **comprehension** runs its body and always yields `0` | **6** | `loop_break_with_value`, `loop_even_numbers_with_break`, `loop_filter_with_conditional_break`, `loop_map_with_break_add_tax`, `loop_map_with_break_simple`, `loop_yield_accumulation`. `yield` / `break <v>` must accumulate into a new array blob; 4 of the 6 also carry `;; loop over unknown iterable` (`isArrayExpr` is deliberately narrow — see `codegen/AGENTS.md` §wat). |
| W5 | A `comptime { … break v; }` top-level `val` stays `0` | **4** | `comptime_block_with_break`, `comptime_folding_block_with_break_value_inlines_result`, `comptime_folding_float_multiplication_folds_to_literal`, `comptime_folding_multiplication_binds_tighter_than_addition`. The global is declared `(global $pi2 (mut i32) (i32.const 0))` and `$__init_globals` sets it to `i32.const 0` — the folded value never reaches `emitGlobalVal` (`wat.zig:1705`), and the global's type is i32 even for an f64 value. Same language shape as erlang E5 and beam B1; the direct-literal form (`val v1 = comptime 1 + 1;`) already works. |
| W6 | `case` discriminates only numeric and `or`-of-numeric patterns | **4** | `case_string_literal_patterns` prints `hello hello hello`; `narrow_case_enum_area_with_print` runs the first arm with its payload unbound (`0 0`); `narrow_case_option_some_none` prints `empty empty`; `narrow_case_result_ok_err_with_print` prints `OK:` then raw payload bytes. Needs string equality (`$__str_eq` exists) and a variant-tag test plus payload binding. |
| W7 | `@Option` none is the bare value `0`, indistinguishable from a real `0` | **4** | `array_at_lowers_byte_identically_across_backends` (`0` vs `undefined`), `optional_fn_return_null_path` (`0`), `narrow_if_null_check_with_print` (`0` vs `42`), `narrow_type_guard_if_codegen` (prints nothing). A carrier decision, not a bug fix — pick a sentinel (a tagged pointer, or `-1`) and state it in `codegen/AGENTS.md`. |
| W3 | A **bool** prints as `1` / `0` | **3** | Same site as W2, the `isBoolExpr` arm (`wat.zig:2372`): `narrow_type_guard_basic_codegen`, `throw_inside_case_arm`, `throw_inside_loop_body`. |
| W8 | Field access on a receiver whose type is not recovered | **2** | `wat.zig:3183`/`:3186` emit `i32.const 0 ;; field access .<f> (unknown receiver type)`. `template_end_to_end_yaml_model_computes_a_typed_record` builds the record correctly (`8004`, `1` in memory) but reads `.port` as `0`; `interface_literal_with_fields` reads `.fields.length` as `0`. Same root as W2. |
| W9 | `array.slice` returns the raw bytes | **1** | `array_slice_2_arg_lowers_byte_identically_across_backends` prints three NUL bytes. |
| W10 | `xs.at` / `xs.slice` over an empty array reads out of bounds | **1** | `option_method_on_tuple_element` — the only non-`unreachable` trap. |
| W11 | A non-string operand is dropped from a string concat | **1** | `narrow_else_if_chain_with_null_checks` prints `nonzero:` and loses the `42` — the wasm mirror of erlang E2. |

Three more fixtures differ because **erlang** is wrong: `destructure_record_parameter_in_fn`,
`destructure_record_val_binding` (E1) and `try_with_inline_catch_handler` (E4 — wasm's
`unreachable` is the right answer for a program that calls `@todo()`).

### The `executeWat` decision

**Turning it on today pins 35 knowingly-wrong RUN LOGs and 29 empty ones.** The empty ones are
the dangerous half: `runtime.zig` records an empty RUN LOG for any non-zero exit
(`:537-542`), so a `wasm trap: wasm 'unreachable'` would be recorded exactly like a program that
ran fine and printed nothing — the failure mode 1.0.1-beta spent the milestone undoing, and
`narrow_if_null_check_with_print` on beam already shows how it misleads.

So the condition is not "fix everything first". It is:

> `executeWat` may be turned on once **a wasm abort is recorded as a visible block** — a
> `RUNTIME TRAP (wasmtime):` section carrying the trap message, exactly as
> `COMPILE ERROR (erlc):` is recorded today (`runtime.zig:507`, `compileFailureLog`) — **and**
> W1 is closed, so reaching `unreachable` always means the *program* aborted rather than the
> backend giving up.

With those two in place nothing can be silently wrong: a trap shows as a trap, a wrong value
shows as a wrong value, and each remaining wrong value is pinned only with the divergence stated
in its test. Recommended order:

1. Record the trap block (a small change in `runtime.zig`; no lowering work). Do this first — it
   is what makes every later step's result legible.
2. W1 (pass `instance_lowerings`, then the seven sub-classes).
3. Turn `executeWat` on; bump `HARNESS_VERSION`, because a warm cache would hide the change.
4. W2/W3 (13 fixtures, one site), then W4, W5, W6, then the rest.

Mechanics: `wasmtime run <module>.wat` accepts the `.wat` text directly and runs the `_start`
export the backend already emits, so `executeWat` is `runCaptured` + the existing content-keyed
cache. wasm is single-module, so there is no `aux` leg. Do **not** reuse the erlang early-bail
heuristic: a wasm module with no `@print` can still trap, and that is exactly what must be seen.

**Acceptance:**
- [ ] A wasm abort is recorded as `RUNTIME TRAP (wasmtime):` + the message, never as an empty log
- [ ] `emitWat` receives `instance_lowerings`; `wat.zig:3038` is reachable only for a shape with
      no lowering, and its doc comment describes what it does now
- [ ] `executeWat` either executes or its doc comment states the deliberate skip and why
- [ ] No wasm RUN LOG is accepted while its module is known to print the wrong value
- [ ] The decision is recorded in `src/codegen/AGENTS.md`

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

Add snapshot tests (all four backends, documented skips) for optional/null, cross-module imports,
interface/implement, records/enums, generics, lambdas/operators/annotations
(`src/codegen/tests/{values,features,aggregates}.zig`), and template/`@Expr` holes with runtime
values and comptime eval results (`src/codegen/tests/comptime.zig`).

Where a defect above is only visible through a silent source, make the test print the result —
the 145 `a/empty` snapshots per backend are exactly the fixtures that hide one, and the
measurement found real defects living there today: **4 commonJS `a` snapshots emit unparseable
JavaScript** and **3 wasm `a` snapshots abort on an unresolved call** (the three `lambda_*`
fixtures), none of which any RUN LOG can ever show.

## Step 7 — Final sweep

`zig build test` (from a cold runtime cache) `&& zig build test-libs && zig build test-backends`
green, with the coverage pivot, the full-export audit and the `executeWat` decision recorded in
`src/codegen/AGENTS.md`.

---

## Parallelism

These rows are cut by the file they edit. Two rows may run at the same time only when they share
no source file **and** no snapshot directory.

| Row | Owns | Rows from this spec | Also owns from spec 04 |
|---|---|---|---|
| **std surface** | `libs/std/src/primitives.bp` | C1, E3 | — |
| **commonJS** | `codegen/commonJS.zig`, `codegen/js/**`, `codegen/typescript.zig`, `snapshots/codegen/commonJS/` | C3, C4, C5, the `node --check` gate | steps 1–6 (JS-1…JS-6) |
| **erlang** | `codegen/erlang.zig`, `codegen/beam/erl_ast.zig`, `codegen/beam/erl_emitter.zig`, `snapshots/codegen/erlang/` | E1, E2, E4, E5, E6, E7, the 7 value `raw` sites | steps 8, 10 |
| **beam** | `codegen/beam_asm.zig`, `codegen/beam/beam_emitter.zig`, `snapshots/codegen/beam/` | B1–B12, the export audit | step 9 |
| **wasm** | `codegen/wat.zig`, `codegen/wat/**`, `snapshots/codegen/wasm/` | W1–W11 | step 7 |
| **harness** | `codegen/runtime.zig`, `codegen/snapshot.zig`, `scripts/**` | the trap block, `executeWat`, step 5 | — |

Notes on the edges:

- **`libs/std/src/primitives.bp` is the one file all four backends need** (C1, E3, B4, W1's
  external and instance-method sub-classes). It must be its own row and land **first**; no
  backend row may edit it, because one edit there re-records snapshots in all four directories.
- **erlang and beam share `codegen/beam/`.** `erl_ast.zig` / `erl_emitter.zig` belong to the
  erlang row; `beam_emitter.zig` to the beam row. E2 and B3 are the same defect expressed twice
  and should be fixed in the same wave, erlang first.
- **E8 is not a backend row.** The `#[@result]` wrap that produces `{ok, {error, …}}` on erlang
  and `return return` on commonJS lives in the transform pass; it lands once and re-records both
  directories, so it must not run beside the erlang or commonJS rows.
- **The harness row must land before the wasm row finishes**, since `executeWat` decides whether
  the wasm row's work is visible at all. It touches no backend file and can run beside any of
  them.
- The `if`-with-no-else value (C-tail, B10) and the `loop`-as-value return type (B7) are language
  questions for [`02-type-system.md`](./02-type-system.md); no backend row re-records them.

# beam — the causes, ranked

Twelve causes cover 55 of the 58 fixtures where beam disagrees with the other backends. The other
three are fixtures where **erlang** is the wrong backend (see the last section). The first cause
alone accounts for 22.

Paths are relative to `repository/botopink-lang/modules/compiler-core/`, except those starting with
`libs/`, which are relative to `repository/botopink-lang/`. Every `file:line` is at HEAD.

## How the numbers were measured

They are not read off the snapshots — a snapshot's RUN LOG only says what the harness recorded.
Each backend's emitted code was extracted from the snapshot and executed outside the suite:

| Backend | How |
|---|---|
| commonJS | `node --check <module>.js` on every emitted module (syntax), then `node main.js` |
| erlang | `erlc -o . <mod>.erl` per module, then `erl -noshell -eval "main:'_botopink_main'()"` inside a `try … catch C:E:S -> …` so the crash class and stack are visible instead of an empty log |
| beam | `erlc +from_asm` per module, same runner; plus the full-export audit below |
| wasm | `wasmtime run <module>.wat` (wasmtime 45), stdout + exit status |

Cross-backend agreement is compared under a **representation mapping**, because erlang and beam
print through `~p`: `<<"x">>` → `x`, `<<>>` → empty, `1.0` → `1`, `[ 2, 4 ]` → `[2,4]`. Comparing
the raw text instead reports 22 extra commonJS fixtures as "wrong" that differ only in how a string
is rendered. "N fixtures differ" always means N under this mapping.

Of the 131 `b` fixtures, 3 never reach codegen, leaving 128 comparable:

| backend | reproduces erlang | aborts | runs, prints something else | …of which **erlang** is the wrong one |
|---|---|---|---|---|
| commonJS | 96 | 15 | 17 | 6 |
| beam | 70 | 13 | 45 | 3 |
| wasm | 62 | 29 | 37 | 3 |

## The ranked table

| # | Cause | Closes | Mechanism, deciding line, fix shape | Local? |
|---|---|---|---|---|
| B1 | **An identifier the emitter cannot resolve is emitted as an atom of its own name** | **22** | See the section below. | model change (the val-as-function decision), then local |
| B2 | A `declare fn` external with no `@External.Beam` body becomes a local function returning `ok` | **8** | `external_a2_chained_host_call_renders_verbatim`, `external_a2_method_on_global_template_keeps_receiver_bound`, `external_call_emits_module_symbol`, `external_global_math`, `external_import_binds_symbol`, `external_target_mixed_with_external_in_one_decl`, `external_target_template_equivalent_to_external_target_template` (all print `ok`); `external_a3_result_template_owned_declare_fn` prints `-1` via `unwrapOr`. Resolve to the `@External.Erlang` form where one exists (a BEAM `call_ext` to the same `{module, symbol}`), otherwise fail the lowering loudly. | local |
| B3 | String `+` and interpolation lower to the arithmetic `{gc_bif, '+', …}` on two binaries | **6** (+2 hidden) | `string_concat_of_two_literals` emits `{move, {literal, <<"hi ">>}, {x,0}}` … `{gc_bif, '+', {f,0}, 2, [{x,1},{x,0}], {x,0}}` → `badarith [{erlang,'+',[<<"hi ">>,<<"there">>]}]`. Also `string_interpolation_lowers_to_concat`, `string_length_after_concat`, `reserved_word_identifiers`, `builtin_print_with_variable`, `narrow_early_return_with_print`. Two more (`narrow_case_option_some_none`, `narrow_else_if_chain_with_null_checks`) carry the same defect but are invisible in the diff because erlang aborts on them too (E2). Build a binary instead, as `src/codegen/erlang.zig`'s `stringConcatNode` (`:1996`) does — and port E2's per-segment type decision at the same time, or beam inherits the same `badarg`. | local |
| B4 | Primitive / interface instance methods are not lowered (`%% unresolved method call`) | **8** | 28 snapshots carry at least one `%%` marker (20 distinct method names). The 8 that show as a wrong value: `array_instance_default_fn_methods` (`fold/3`, `all/2` — prints `[1,2,3]` where erlang prints `6` / `true`), `array_zip_via_external_node_template` (`zip/2`), `bool_instance_default_fn_methods` (`negate/1`, `nor/2`, `nand/2`, `exclusiveOr/2` — every answer inverted), `numeric_instance_methods_external_default_fn` (`abs/1`, `min/2`, `max/2`, `clamp/3`, `isEven/1`), `dispatch_inherent_record_method_call` (`atual/1` — prints the whole map), `string_methods_map_to_native_js_names` (`split/2` "complex arg" + `slice/3`, dies with `{case_clause, <<"Hello,World">>}`), `string_slice_both_bounds` and `string_slice_result_length_is_readable` (`slice/3`, off by the start offset). The marker means the receiver was left in `{x,0}` and the call dropped. | needs the annotation / template path of `src/codegen/AGENTS.md` §Primitive methods extended |
| B5 | Record and interface **literals** are unsupported | **4** | `%% unsupported: record literal` (6 occurrences) and `%% unsupported: interface literal` (2). `anon_record_let_bound_then_field_read_by_name`, `nested_anon_record_chained_field_read`, `interface_literal_basic` print `undefined`; `interface_literal_with_fields` dies with `badarg [{erlang,length,[undefined]}]`. beam already builds records through `put_map_assoc` for a declared `record`; an anonymous literal needs the same. | local |
| B6 | An indexed loop builds a 2-parameter fun for `lists:foreach/2` | **1** | `loop (messages, 0..) { msg, i -> … }` → `make_fun3` of arity 2 handed to `lists:foreach/2`, which passes **one** element → `function_clause`. erlang solved this with `lists:enumerate(Start, Xs)` and a single `{I, Item}` tuple parameter (`src/codegen/AGENTS.md` §erlang/Loops); beam must do the same. `loop_side_effect_print_in_iterator`. | local |
| B7 | A loop comprehension lowers through `lists:map` instead of `lists:filtermap` | **1** | `loop_break_with_value` prints `[ok,ok,15,20]` where erlang prints `[15,20]`: the non-breaking arm yields `ok` instead of being filtered out. erlang's `filterMapFunBody` is the shape. (The fixture's own expected value is itself unsettled — `fn find(arr) -> i32` returns a **list**; settle that in the checker front before re-recording.) | local |
| B8 | `@Result` `case` arms print the whole tuple | **1** | `narrow_case_result_ok_err_with_print` prints `{ok,<<"data">>}` where erlang prints `<<"OK:data">>` — the arm pattern does not destructure. | local |
| B9 | Register staging clobbers a live x-register | **1** | `stdlib_associated_fn_namespace_injected` prints `1 42 10` where erlang prints `1 42 22`; the full-export audit rejects `'Pair_mapFirst'/2+23`, `'Pair_mapSecond'/2+23` and `'Pair_swap'/1+18` with `{test_heap,3,3}` / `{{x,1},not_live}`. This is the staging-site class `src/codegen/AGENTS.md` names (`lowerTupleLit` / `lowerRecordConstruct` / `lowerTaggedTuple` / `materializeCallArgs`). | local |
| B10 | A value-less `if` yields `undefined` | **1** | `if_simple_conditional_in_fn_body`. An undecided language question, not a beam defect — see the note below. | — |
| B11 | An `if`-with-binding on a nullable prints nothing | **1** | `narrow_if_null_check_with_print`: the assembled module runs, exits 0 and prints **nothing** — the narrowed arm never fires for `x = 42`. (The current harness records this as `b/empty`, which reads as "crashed"; it did not.) | local |
| B12 | Cross-module record construction + associated fn aborts | **1** | `import_cross_module_record_construct_and_assoc_fn` — erlang and commonJS both print `hi` / `8080`. | local |

## B1 — an unresolvable identifier becomes an atom (22 fixtures)

**Deciding line:** `src/codegen/beam_asm.zig:1824` —
`try beamEmitter.writeMove(self.out, Term.atomOf(n), 0);`

It is the fallthrough after three checks: the `reg_map` lookup (`:1792`), the comptime-value lookup
(`:1804`) and `crossOwnerOf` (`:1812`). It is silent and it produces a *value*, so the program runs
and prints a word.

**Its blast radius is wider than the 22.** 23 snapshots move a top-level `val`'s name as an atom
(21 label `b`, 2 label `a`), and two more fixtures reach the same line by a different route.

Three distinct things reach it:

| Route | What happens | Fix |
|---|---|---|
| **(a)** the module's **own** top-level `val` | `src/codegen/beam_asm.zig:514` and `:562` emit the 0-arity function only `if (!has_main_0 …)`, so any module with a `fn main()` never gets one. `val sum = 1 + 2; @print(sum)` assembles a module with **no `sum/0`** and prints `sum` | drop the `!has_main_0` guard; reserve, export and emit every **named** top-level `val` as a 0-arity function. `src/codegen/erlang.zig:2240` (`topValForms`) is the model — only `_`-named synthetic statements stay ordered inside `_botopink_main` |
| **(b)** a **closure free variable** | `loop (0..n) { i -> @print(n - i) }` lowers the lambda with a fresh `reg_map`, so the enclosing `n` becomes the atom `n` and the body dies with `badarith [{erlang,'-',[n,0]}]` | make the lambda lowering carry the enclosing frame |
| **(c)** **`self`** in a `val`-bound record method | `'Counter_inc'/0` is emitted with arity 0 and moves `{atom, self}` into `{x,0}` — the first of the two loader rejections below | thread `self` as a real parameter |

Then make `:1824` **fail loudly** — a `%% unresolved identifier` note plus an abort — instead of
inventing an atom. Without that last part, the fourth route nobody has found yet becomes the next
silent wrong answer.

## The full-export audit

Two register bugs are invisible in the tree because the recorded modules carry a narrow
`{exports, …}` form and `erlc +from_asm` drops unexported functions before validating them.
Rewriting each snapshot's exports to name every `{function, …}` form and assembling: **269 modules
assembled, 2 rejected.**

| Snapshot | Rejection | Cause |
|---|---|---|
| `field_assign_self_field_update` | `'Counter_inc'/0+9`: `{put_map_exact,{f,0},{x,0},{x,0},2,{list,[{atom,count},{x,1}]}}` — `{bad_type,{needed,{t_map,any,any}},{actual,{t_atom,[self]}}}` | **B1(c)**, not a staging bug: the function is emitted at arity 0 and `{move, {atom, self}, {x, 0}}` puts an atom where a map is required |
| `stdlib_associated_fn_namespace_injected` | `'Pair_mapFirst'/2+23`, `'Pair_mapSecond'/2+23`, `'Pair_swap'/1+18`: `{test_heap,3,3}` — `{{x,1},not_live}` | **B9** |

Ship the audit as `scripts/beam_export_audit.sh` so the narrow exports form cannot hide a rejection
again. The exports form it audits is written by hand in `emitBeamAsm` — see
[`emitter.md`](./emitter.md) — so the audit must land **before** that refactor, or the
"byte-identical" claim is checked against a tree whose rejections are still hidden.

## Where beam is right and erlang is wrong

Three of the 58 differences are not beam's:

| Fixture | erlang | beam | Cause |
|---|---|---|---|
| `throw_inside_case_arm` | `true true` | `true false` — **right** | E8: the `#[@result]` wrap is applied to the whole `case` instead of to each non-jumping arm |
| `destructure_record_parameter_in_fn` | crash | right | E1: a record destructuring lowers to a tuple pattern, but a record is a map |
| `destructure_record_val_binding` | crash | right | E1 |

A cross-backend assertion must be written against the *program's* expected output, not against
whatever erlang printed. Full list in
[`../05-erlang/causes.md`](../05-erlang/causes.md#erlang-is-not-the-oracle).

## The two rows that are language questions

| Row | Fixture | Why it is not a beam fix |
|---|---|---|
| B10 | `if_simple_conditional_in_fn_body` | `val r = if (n > 0) { "positive"; };` with no `else` yields `undefined` on commonJS, `ok` on erlang, `undefined` on beam and `0` on wasm. Four backends, four answers to a question the language has not answered. Decide it in [`../07-checker/README.md`](../07-checker/README.md) and make all four agree |
| B7 (the value, not the shape) | `loop_break_with_value` | `fn find(arr) -> i32` returns a list. The `lists:filtermap` shape is a beam fix; the declared return type is the checker's |

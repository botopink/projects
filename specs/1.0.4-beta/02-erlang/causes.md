# erlang — the causes

> Carried from `1.0.2-beta/05-erlang/` into 1.0.4-beta. `file:line` and counts were measured at that milestone's
> commit — re-locate by symbol. `F1…F12` and bare front numbers are the old numbering: see
> [`../fronts.md`](../fronts.md#old-front-numbers).

Eight causes cover every erlang defect the measurement found: six fixtures that abort, one module
that does not compile, and three that print a wrong value silently. One fixture each except E1 and
E2.

Paths are relative to `repository/botopink-lang/modules/compiler-core/`, except those starting with
`libs/`, which are relative to `repository/botopink-lang/`. Every `file:line` is at HEAD.

## How the numbers were measured

They are not read off the snapshots — a snapshot's RUN LOG only says what the harness recorded.
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

Of the 131 `b` fixtures, 3 never reach codegen, leaving 128 comparable:

| backend | reproduces erlang | aborts | runs, prints something else | …of which **erlang** is the wrong one |
|---|---|---|---|---|
| commonJS | 96 | 15 | 17 | 6 |
| beam | 70 | 13 | 45 | 3 |
| wasm | 62 | 29 | 37 | 3 |

## Erlang is not the oracle

The 1.0.1-beta measurement assumed erlang was the reference backend and compared the other three
against it. Running all four found **seven fixtures where erlang is the one that is wrong**, four
of them silently — the program exits 0 and prints an answer that is not the answer.

| Fixture | erlang | who is right | Cause |
|---|---|---|---|
| `throw_inside_case_arm` | `true true` | beam (`true false`) | E8 |
| `std_package_order_enum_module_with_type_export` | `-1 less` | commonJS (`-1 greater`) | E6 |
| `narrow_type_guard_if_codegen` | `false` | commonJS (`true`) | E7 |
| `iterator_fromlist_yields_array_items` | `<<>>` | commonJS (`1,2,3`) | an eager `#[@iterator]` list is consumed as empty |
| `comptime_block_with_break` | `COMPILE ERROR` | commonJS (`20`) | E5 |
| `endswith_lowers_via_external_beam_single_line_body` | crash | commonJS (`true`) | E3 |
| `destructure_record_val_binding` / `destructure_record_parameter_in_fn` | crash | commonJS, beam, wasm | E1 |

> **A cross-backend assertion must be written against the *program's* expected output, not against
> whatever erlang printed.** Three of the seven appear in the beam and wasm fronts as "fixtures
> where erlang is wrong — do not fix the backend to match".

`iterator_fromlist_yields_array_items` is the one row here with no numbered cause: an eager
`#[@iterator]` list is consumed as empty. It is an erlang output bug and belongs to this front, but
its mechanism has not been traced to a deciding line yet — trace it before scheduling it.

## The causes

| # | Cause | Closes | Mechanism, deciding line, fix shape | Local? |
|---|---|---|---|---|
| E1 | A record destructuring lowers to a **tuple** pattern, but a record is a **map** | **2** | `destructPatternExpr` (`src/codegen/erlang.zig:2857-2868`), deciding line **`:2867`** `return .{ .tuple = items.items };`. `val { x, y } = p` emits `{X, Y} = P` against `#{x => 3, y => 4}` → `{badmatch, #{x => 3,y => 4}}`; `fn greet({ name, .. }: Person)` emits `greet({Name, _})` → `function_clause`. The `.names` arm must build `.map` with `exact = true` (`src/codegen/beam/erl_ast.zig:130-135` already carries `MapField.exact` for `:=`), i.e. `#{name := Name}`; `.tuple_` keeps the tuple. Reached from `fnForms` (params), `stmtExpr` `:2905` (`val`) and `propagateTryExpr` `:2837`. | local — the model already has the node |
| E2 | A **non-string** operand of a string `+` is written as a `/binary` segment | **2** | `concatSegments` (`src/codegen/erlang.zig:2002-2021`), deciding line **`:2020`** `try out.append(b.arena, .{ .value = value, .type = "binary" });` — the segment type is a constant. `"value: " + v` with `v : i32` emits `<<"value: ", V/binary>>` → `badarg` with `error_info` `{2, binary, type, 42}`. `isStringExpr` (`:2026`) proves the *chain* is a string because one operand is a literal; the per-segment check is missing. Give each segment the type its own operand proves: `binary` when `isStringExpr(e)`, otherwise a stringify — `formatNode` (`:3592`) already builds `iolist_to_binary(io_lib:format("~p", [E]))`, or `integer_to_binary/1` for an integer operand. Fixtures: `narrow_case_option_some_none`, `narrow_else_if_chain_with_null_checks`. | local |
| E3 | `string:suffix/2` is not an OTP function | **1** | `libs/std/src/primitives.bp:143` `#[@External.Erlang("string", "suffix")]` and `:144` `@External.Beam(""" {call_ext, 2, {extfunc, string, suffix, 2}}.""")` — `erl` answers `undef [{string,suffix,[<<"foobar">>,<<"bar">>],[]}]`. Not a codegen gap at all: the annotation names a function OTP never had. Replace with a real suffix test (`binary:longest_common_suffix/1`, or `string:find(S, Suf, trailing)` compared against `Suf`). Fixture: `endswith_lowers_via_external_beam_single_line_body`. | `libs/std` only — `std-surface` (1.0.2-beta, landed) |
| E4 | `@todo()` raises, and the `try … catch` lowering is a `case`, which cannot catch a raise | **1** | `try fetch() catch 0` lowers to `case fetch() of {ok,V} -> …; {error,E} -> … end`, but `@todo()` inside the `#[@result]` `fetch/0` emits `erlang:error({todo, <<"not implemented">>})`. The raise flies past the `case` and the program dies. Two shapes: make `@todo`/`@panic` inside a `#[@result]` body return `{error, …}`, or wrap the propagating `case` in a real `try … catch error:E`. The second matches what `throw` already does and is the smaller change. Fixture: `try_with_inline_catch_handler`. Note wasm gets this fixture **right** for the wrong reason (`unreachable` aborts, which is also an abort). | local |
| E5 | A comptime block drops every statement before its `break` | **1** | `comptimeNode`'s `.comptimeBlock` arm (`src/codegen/erlang.zig:3625-3633`) returns only the `break` expression; `val result = comptime { val x = 10; break x * 2; };` emits `result() -> (X * 2).` → `main.erl:6:6: variable 'X' is unbound`. The value is already folded (`COMPTIME VALUES: ct_0 → 20`), so `topValForms` (`:2240`) reading `comptime_vals` for a `comptime` val is the smaller fix — that is exactly what commonJS does (`const result = 20;`). **The same latent bug sits in `src/codegen/commonJS.zig:2405-2415` and is only unreached because the decl-level path folds first.** | local |
| E6 | A `case` pattern naming a variant of an **imported** enum is lowered as a variable | **1** | The consumer module of `std_package_order_enum_module_with_type_export` emits `case O of Lt -> <<"less">>; Gt -> …` — `Lt` and `Gt` are unquoted, so the first arm binds and matches anything. `enum_variants` is populated from the module's own decls; `collectImportedTypes` carries an imported record's fields but not an imported enum's variants. Silent wrong answer: prints `less` where the program means `greater`. beam reproduces it; commonJS is right. | needs `collectImportedTypes` to carry variants — small model change |
| E7 | A `return` inside a narrowed `if` arm is discarded | **1** | `fn isString(x: ?string) -> x is string { if (x) { s -> return true; }; return false; }` emits `case X of undefined -> undefined; S -> true; _ -> ok end, false.` — the `case` value is thrown away and `false` is returned unconditionally. The binding-form `if` goes through `condNode`/`mutatingExpr` instead of `earlyReturnIfExpr`, which is what nests the rest of the body in the false arm. Silent wrong answer: prints `false` where the program means `true`. Also emits a dead `_ -> ok` clause. | local |
| E8 | `return <case>` in a `#[@result]` fn wraps the **whole** case in `{ok, …}` | **1** | `return case s { Ok -> 1; Fail -> throw "failed"; }` emits `{ok, case S of 'Ok' -> 1; 'Fail' -> {error, <<"failed">>} end}` — the throwing arm becomes `{ok, {error, …}}` and `isOk()` answers `true`. The `#[@result]` wrap must be pushed **into** each non-jumping arm. Silent wrong answer; beam is right. commonJS has the same shape spelled as `return return ({ error: … })` — a SyntaxError, and therefore the JS-1 row of [`../04-js-bridges/bridges.md`](../04-js-bridges/bridges.md). Fixing the wrap here fixes the JS shape too. | shared with commonJS — the wrap decision is in the transform pass, not the backend |

## Edges

- **E2 and beam's B3 are the same defect expressed twice.** Fix them in the same wave, erlang
  first, and have beam port the per-segment type decision — otherwise beam inherits the `badarg`.
  See [`../01-beam/causes.md`](../01-beam/causes.md).
- **E8 is not a backend row.** The `#[@result]` wrap that produces `{ok, {error, …}}` on erlang and
  `return return` on commonJS lives in the transform pass; it lands once and re-records both
  directories, so it must not run beside the erlang or the js-bridges front. Agree the owner before
  starting it.
- **E5 and the commonJS twin** (`src/codegen/commonJS.zig:2405-2415`) are one defect in two
  backends, and the JS side is the js-bridges front's JS-2 audit row. Neither waits for the other,
  but both should land in the same milestone or the comptime block behaves differently per target.
- **E3 belonged to the std-surface front** and landed with it (1.0.2-beta), before this front
  started.

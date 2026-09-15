# Snapshot review: codegen `builtins.zig` (31 tests) + `aggregates.zig` (22 tests)

Repo root: `/home/ericfillipe/develop/botopink-lang/repository/botopink-lang`

## Re-check summary (HEAD `96ff203`, 2026-09-15)

Every non-`ok` row and every harness note below was re-verified at HEAD. Since the first pass the
snapshot tree was flattened (`96ff203`, pure move) to `snapshots/codegen/<target>/<slug>.snap.md`,
so all paths in this document were rewritten; the *content* of every snapshot file in this batch is
byte-identical to the first-pass revision (`beb19e9`) — the new `COMPTIME ERLANG`/`COMPTIME REPLY`
sections and the new `ct_N: <declaration> → literal` form touch no slug of this batch.

61 finding rows + 5 harness notes:

| classification | count |
|---|---|
| confirmed | 56 findings + 4 harness notes (H1–H4) |
| corrected | 3 findings (`builtin_print_in_if_branch`, `builtin_print_in_loop`, `interface_literal_*`) + 1 harness note (H5) |
| withdrawn | 0 |
| uncertain (re-checked, deliberately still open) | 2 findings (`assert*` node semantics, `assert_pattern_with_enum_variant`) |

Notable corrections:
- The three `wrong-test` rows claimed an empty `.snap.md` *cannot pass*. That is wrong: a parse/type
  error drops the module (`commonJS.zig:52-53` and siblings), `buildSnapshotMulti`
  (`codegen/snapshot.zig:142-154`) then returns `""`, and `utils/snap.zig:81-84` trims both sides —
  so `"" == ""` and the test passes **vacuously**. The tests are green and assert nothing.
- `interface_literal_*` cause is no longer uncertain: `val DeclKind = record { Record: "Record" };`
  does not parse (a `val X = record { … }` binding is read as a record *type* declaration, so
  string-literal "types" are rejected). The same record literal **inside a call argument** parses
  fine, so only the `DeclKind` line has to change.
- H5 (blank `.d.ts` sections) is not an emitter bug: `codegen/typescript.zig` emits only `pub`
  declarations (`:68`, `:87`, `:141`, `:179`, `:223`, `:295`). 23 non-blank typedef sections exist
  elsewhere in the tree. The residual weakness (these fixtures pin nothing in that section) stands.
- H1/H2 are now **empirically** confirmed, not just by code reading: with a cold runtime cache 70
  beam RUN LOGs and 5 erlang RUN LOGs go empty. Every non-empty RUN LOG in this batch was traced to
  a `2026-06-27` cache entry by recomputing `runtime.zig:cacheKey`.

Path legend:
- `S/commonJS/<slug>` = `modules/compiler-core/snapshots/codegen/commonJS/<slug>.snap.md`
- `S/erlang/<slug>`, `S/beam/<slug>`, `S/wasm/<slug>` — same shape (`codegen/errors/<target>/` for
  the error snapshots).

Scratch verification dir (re-check): `<scratch>/rev-builtins-ctmisc/`
(`run_all.py` + `run_builtins.log` = extract and run every code section per backend, `beamrun/run.py`
= export-all BEAM re-assembly + `erl -eval` calls, `jsrun/checks.js` = JS semantics, `cachekey.py` =
recomputed `runtime.zig` cache keys, `orphans.py` = slug/orphan scan, `probe/` = a throwaway
`botopink new` project driven with `zig-out/bin/botopink check`).
Tools: OTP 29 `erlc`/`erl`, node 25.8, `wasmtime 45.0.0`. Nothing in the repo was modified and no
`zig build` was run; `zig-out/bin/botopink` (built 2026-09-15 19:48, i.e. after every parser commit
in this tree) was used read-only to probe parseability.

## Counts

53 tests: 52 snapshot slugs + 1 `assertJsContains` test (`codegen: test runner excluded from normal
build`, no snapshot). `test_runner` uses test mode, so it only has node and erlang snapshots. That is
expected. Re-verified at HEAD with `orphans.py`: no slug collisions, no orphan snapshots, no missing
files for these prefixes (296 `test` blocks repo-wide, 280 snapshot-producing; 279 commonJS / 279
erlang / 278 beam / 278 wasm files, all accounted for).

Primary verdict per test (the worst verdict wins) — unchanged by the re-check:

| verdict | tests |
|---|---|
| ok | 5 |
| wrong-output | 39 |
| wrong-test | 4 |
| weak | 5 |
| known (primary) | 0 (known issues also show up as secondary items in 16 tests, see table) |
| uncertain (primary) | 0 (2 secondary uncertain items) |
| skip-undocumented / orphan / duplicate | 0 |

## Harness-level findings (affect several slugs in this batch)

| id | verdict | re-check | evidence | expected vs actual | suggested fix |
|---|---|---|---|---|---|
| H1 | wrong-output (harness) | confirmed (now empirically) | `src/codegen/runtime.zig:364-365`: `const assemble_result = try runWithTimeout(... "erlc", "+from_asm" ...);` `if (assemble_result.len == 0) return allocator.dupe(u8, "");` (same inverted test for aux modules at `:375`) | A successful `erlc +from_asm` prints nothing — re-confirmed: every assembly that succeeded in `run_builtins.log` produced empty stdout **and** stderr. So the check is inverted and a cold-cache run returns `""` for **every** BEAM RUN LOG; it is known today that a cold cache empties 70 beam RUN LOGs. The 5 non-empty BEAM RUN LOGs in this batch (`builtin_print_single_argument`, `builtin_print_multiple_arguments`, `builtin_print_expression`, `builtin_print_return_value_void`, `record_implement_fields_round_trip_at_runtime`) only reproduce from `modules/compiler-core/.botopinkbuild/runtime-cache/`. Keys recomputed in `cachekey.py`: all 5 hit, all dated `2026-06-27 01:12–01:13` (e.g. beam `builtin_print_multiple_arguments` → `OK:<<"Hello">>\n`). | Invert to "non-zero exit ⇒ empty", like `executeErlang`, then regenerate with the cache cleared. |
| H2 | weak (harness) | confirmed (now empirically) | `runtime.zig:306` `if (compile_out.len > 0) return allocator.dupe(u8, "");` (aux modules: `:314`) plus `runWithTimeout:61-67`, which appends stderr on exit 0 | Any erlc **warning** (warnings go to stderr) blanks the erlang RUN LOG. It is known today that a cold cache empties 5 erlang RUN LOGs, `builtin_print_return_value_void` among them: `S/erlang/builtin_print_return_value_void` shows `<<"started">>`/`<<"done">>` but erlc prints `main.erl:9:5: Warning: variable 'X' is unused` (reproduced). Its RUN LOG comes only from cache entry `5eaabc882cd5…` (`OK:<<"started">>\n<<"done">>\n`, 2026-06-27 01:13). | Treat only a non-zero erlc exit as failure (check the exit status, or `+nowarn`), or stop emitting unused bindings (`_X`). |
| H3 | known | confirmed | `runtime.zig:393-401` `executeWat` discards its input and returns `""` | Every wasm RUN LOG is empty (noted once here, not repeated per test). Running the WAT by hand with wasmtime found the real output bugs listed below. | - |
| H4 | weak | confirmed | `runtime.zig:275` `if (std.mem.indexOf(u8, erl_code, "_botopink_main") == null) return ""` | In test mode the erlang module only exports `main/1` and the string `_botopink_main` never appears in it (`grep -c` = 0), so `S/erlang/test_runner` has an empty RUN LOG. Running it by hand (`erl -eval 'main:main([])'`) prints the same envelope as node, ending in `2 passed, 0 failed`. | Also run `main/1` in test mode, or emit `_botopink_main` in test mode. |
| H5 | weak (was: emitter bug) | **corrected** | Every `S/commonJS/*` in this batch has `----- TYPESCRIPT TYPEDEF -- main.d.ts` containing only blank lines, including `S/commonJS/record_two_fields` | Not an emitter defect: `codegen/typescript.zig` skips every non-`pub` declaration (`:68` fn, `:87`, `:141` record, `:179` enum, `:223` interface, `:295`), and every fixture in this batch is non-`pub`. A tree-wide scan finds 23 non-blank typedef sections (e.g. `val_pub_val_declaration`, `std_package_order_enum_module_with_type_export`). What survives is only the weakness: for these fixtures the section pins nothing. | Either add one `pub` fixture that exercises the typedef, or drop the section when it is empty. |

## Findings table (all non-`ok` items)

| slug | backend(s) | verdict | re-check | evidence (quoted lines + path) | expected vs actual | suggested fix |
|---|---|---|---|---|---|---|
| assert_simple_assertion, assert_with_arithmetic_comparison, assert_with_message, assert_array_equality | beam | wrong-output | confirmed | `S/beam/assert_with_message` (the same body appears in all 4): `{allocate, 0, 0}.` `{move, {atom, undefined}, {x, 0}}.` `{move, {atom, ok}, {x, 0}}.` `{deallocate, 0}.` | The assertion should be evaluated and raise on false. The body is dropped entirely: re-ran with the function exported — `m_as1:f() => ok`, `m_as0:f() => ok`. | Lower `assert` in beam_asm, e.g. `is_eq_exact` + `erlang:error`. |
| same 4 | wasm | wrong-output | confirmed | `S/wasm/assert_simple_assertion`: `(func $f` `i32.const 0` `)` | The module should be valid. wasmtime rejects all 4: `failed to compile: wasm[0]::function[0]::f … Invalid input WebAssembly code at offset 51: type mismatch: values remaining on stack at end of block`. | Lower assert to `if (i32.eqz cond) unreachable`, and never leave a value in a void func. |
| same 4 | node | uncertain | uncertain (unchanged) | `S/commonJS/assert_with_message`: `console.assert(false, "error message");` | Re-ran in `jsrun/checks.js`: `console.assert` prints `Assertion failed: error message` to stderr and execution continues. Erlang raises (`main:f()` → `CRASH error:{badmatch,false}`), and test mode uses a throwing `__bp_assert`. Whether non-fatal asserts in a normal JS build are intended is still undecided. | Decide on the semantics. If asserts should be fatal, lower to `if (!c) throw ...`. |
| assert_with_message | erlang | wrong-output | confirmed | `S/erlang/assert_with_message`: `true = (false).` | The message `"error message"` is dropped; at runtime the failure is `error:{badmatch,false}`. erlc also warns `main.erl:4:5: Warning: no clause will ever match`. | Emit `case C of true -> ok; _ -> erlang:error({assert, Msg}) end`; test mode already emits the analogous `erlang:error({bp_assert, <<"assertion failed">>, <<"main.bp:7">>})`. |
| assert_array_equality | node vs erlang | weak | confirmed | `S/commonJS/assert_array_equality`: `console.assert(([] === []));` and `S/erlang/assert_array_equality`: `true = (([] =:= [])).` | JS evaluates `[] === []` to `false` (re-checked), so the assertion always fails; erlang evaluates it to `true` (`main:f() => true`). Documented as "backend-defined" in `src/codegen/tests/values.zig:332-336`, but nothing runs, so the test pins nothing about equality. | Add a `main` that prints the result, or note in the test that it is ref-eq. |
| assert_pattern_with_catch_throw, _catch_default_value, _list_pattern, _string_literal, _number_literal, _enum_variant, _empty_list, _multiple_element_list, _list_and_rest (9) | all | weak (source) | confirmed | e.g. `S/commonJS/assert_pattern_with_catch_throw` SOURCE: `val assert Person(name, age) = r catch throw Error("is not person");`. `r`, `items`, `greeting`, `answer`, `result`, `list`, `numbers`, `Person` and `Error` are never declared, and there is no `main`. | These sources could not typecheck or run. Only the code shape is pinned, and no RUN LOG can catch a regression. | Declare the scrutinee and record, add `main` with `@print` of the bound names. |
| same 9 | erlang | wrong-output | confirmed | `S/erlang/assert_pattern_with_catch_throw`: `case R of {tag, Person, Name, Age} -> R; _ -> erlang:throw('Error'(<<"is not person">>)) end.` | The module should compile. erlc exits 1 for all 9: `main.erl:4:10: variable 'R' is unbound`, `main.erl:4:64: function 'Error'/1 undefined` (`'Person'/2 undefined` in `_catch_default_value`). Two codegen bugs are independent of the undeclared names: (a) `Person`/`Ok` are emitted as **variables** inside the pattern, so any `{tag,_,_,_}` matches, while records are maps everywhere else (`S/erlang/record_implement_fields_round_trip_at_runtime`: `#{tag => <<"x">>, n => 5}`), so this tuple pattern can never match a real record; (b) `throw Error(...)` calls a nonexistent local `'Error'/1`. `Name`/`Age`/`First`… are also bound only inside the case clause. | Match records as maps (`#{name := Name, age := Age}`), lower `Error(msg)` to a real constructor, and bind pattern variables in the enclosing scope. |
| same 9 | beam | wrong-output | confirmed | `S/beam/assert_pattern_with_list_and_rest` (same body in all 9): `{move, {atom, undefined}, {x, 0}}.` `{move, {atom, ok}, {x, 0}}.` | Pattern test, bindings and throw/default should all appear; everything is dropped (`m_ap1:f() => ok`). | Implement `val assert` in beam_asm. |
| same 9 | wasm | wrong-output | confirmed | `S/wasm/assert_pattern_with_catch_throw`: `(func $f` `i32.const 0` `)` | wasmtime, all 9: `values remaining on stack at end of block` (offset 51). | As for assert. |
| same 9 | node | wrong-output | confirmed | `S/commonJS/assert_pattern_with_list_pattern`: `(() => { const _match = items; if ((Array.isArray(_match) && _match.length >= 1)) { return _match; } else { throw Error("not a list"); } })();` | `val assert [first, ..] = items` should bind `first`, but the IIFE result is discarded. Re-checked: reading `first` afterwards gives `ReferenceError: first is not defined`. | Emit `const [first] = (IIFE)` or destructure. |
| assert_pattern_with_multiple_element_list | node | wrong-output | confirmed | `S/commonJS/assert_pattern_with_multiple_element_list`: `if ((Array.isArray(_match) && _match.length >= 3))` | Pattern `[1, 2, 3]` should require exactly 3 elements with values 1,2,3. `[9,9,9,9]` is accepted (re-checked). Erlang correctly emits `case Numbers of [1, 2, 3]`. | Emit an exact length check plus element equality. |
| assert_pattern_with_empty_list | node | wrong-output | confirmed | `S/commonJS/assert_pattern_with_empty_list`: `if ((Array.isArray(_match)))` | Pattern `[]` should require length 0. `[1,2]` is accepted (re-checked). | Add `&& _match.length === 0`. |
| assert_pattern_with_list_and_rest | node | wrong-output | confirmed | `S/commonJS/assert_pattern_with_list_and_rest`: `_match.length >= 2` ... `return _match;` | The `>=2` check is right, but `first`/`second`/`rest` are never bound. | Destructure. |
| assert_pattern_with_catch_default_value | node | wrong-output | confirmed | `S/commonJS/assert_pattern_with_catch_default_value`: `else { return Person("bob", 12); }` | The record ctor needs `new`, as in `S/commonJS/record_implement_fields_round_trip_at_runtime` (`return new E("x", 5);`). With a class `Person` it throws `TypeError: Class constructor Person cannot be invoked without 'new'` (re-checked). | Use the record-ctor lowering in the catch arm. |
| assert_pattern_with_enum_variant | node | uncertain | uncertain (unchanged) | `S/commonJS/assert_pattern_with_enum_variant`: `if ((_match instanceof Ok))` | `Ok` is the `@Result` variant, and elsewhere results are `{ok: …}`/`{error: …}` objects (`S/commonJS/stdlib_result_isok_and_iserror_predicates`: `"error" in _r`), so `instanceof Ok` throws (`ReferenceError: Ok is not defined`, re-checked) or never matches. The source never declares `Ok`, so it may be a user enum. | Clarify in the test source which `Ok` is meant. |
| builtin_todo_with_message | beam | wrong-output | confirmed | `S/beam/builtin_todo_with_message`: `{move, {atom, undef}, {x, 0}}.` `{call_ext, 1, {extfunc, erlang, error, 1}}.` | Expected `erlang:error({todo, <<"implement this function">>})` (what erlang emits — verified: `CRASH error:{todo,<<"implement this function">>}`). Actual raises `error:undef` with the message lost (`m_b1:notImplemented() => CRASH error:undef`), and `undef` is also Erlang's reason for undefined functions, so it is misleading. Source: `beam_asm.zig:3156` `if (... "todo")) "undef" else "panic"`. | Build a `{todo, Msg}` tuple. |
| builtin_panic_with_message | beam | wrong-output | confirmed | `S/beam/builtin_panic_with_message`: `{move, {atom, panic}, {x, 0}}.` | Expected `error({panic, <<"something went wrong">>})` (erlang: verified). Actual `m_b2:fail() => CRASH error:panic`, message lost. | Same. |
| builtin_todo_with_message, builtin_panic_with_message | all | weak | confirmed | no `main`, so no RUN LOG | A regression in the error payload would go unnoticed. | Add a `main` that catches and prints. |
| builtin_print_multiple_arguments | erlang | wrong-output + known (leak) | confirmed | `S/erlang/builtin_print_multiple_arguments`: `io:format("~p~n", [<<"Hello">>, 42, true]).`, RUN LOG empty | erlc: `main.erl:5:23: Warning: the format string requires an argument list with 1 argument, but the argument list contains 3 arguments` — on stderr, so `runtime.zig:306` blanks the RUN LOG (H2). Independently the code crashes: `CRASH error:badarg` in `io:format/2`. Expected all 3 values. Template: `erlang.zig:1340` `"io:format(\"~p~n\", [$args])"`. | Build a format string with one `~p` per arg, or print each arg. |
| builtin_print_multiple_arguments | beam | wrong-output | confirmed | `S/beam/builtin_print_multiple_arguments`: only `{move, {literal, <<"Hello">>}, {x, 0}}.` then `{call_ext, 2, {extfunc, io, format, 2}}`. RUN LOG: `<<"Hello">>` | Expected `42` and `true` too. Only `cc.args[0]` is lowered (`beam_asm.zig:3162-3165`, inside the `print` arm at `:3162-3172`); re-ran the assembly: prints `<<"Hello">>`. The RUN LOG exists only through cache key `603862464c0b…` (2026-06-27, H1). | Lower all args. |
| builtin_print_multiple_arguments | wasm | wrong-output | confirmed | `S/wasm/builtin_print_multiple_arguments`: only `(data (i32.const 256) "\05\00\00\00Hello")`, with no 42/true | `wasmtime run` prints only `Hello` (re-run). `wat.zig:1751-1772` handles only `cc.args[0]`. | Lower all args. |
| builtin_print_with_variable | erlang | wrong-output + known (leak) | confirmed | `S/erlang/builtin_print_with_variable`: `io:format("~p~n", [(<<"Hello, ">> + Name)]).`, RUN LOG empty | erlc: `main.erl:6:39: Warning: evaluation of operator '+'/2 will fail with a 'badarith' exception` (stderr ⇒ blank RUN LOG, H2), and the code crashes: `CRASH error:badarith [{erlang,'+',[<<"Hello, ">>,<<"worl"...>>]…`. String `+` must lower to `<<A/binary, B/binary>>`. Expected `<<"Hello, world">>`. | Type-directed string concat in erlang.zig. |
| builtin_print_with_variable | beam | wrong-output | confirmed | `S/beam/builtin_print_with_variable`: `{gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 0}], {x, 0}}.` | Expected binary concat. Actual `CRASH error:badarith` (re-ran the assembled module). | Same. |
| builtin_print_with_variable | wasm | wrong-output | confirmed | `S/wasm/builtin_print_with_variable`: `i32.const 268` `local.get $name` `i32.add` `call $__print_i32` | Expected `Hello, world`. `wasmtime run` prints `524` (268 + 256), re-run. | Concat strings, and print them with fd_write rather than `__print_i32`. |
| builtin_print_return_value_void | wasm | wrong-output | confirmed | `S/wasm/builtin_print_return_value_void`: `i32.const 256` `call $log` `drop` and `(func $log (param $msg i32)` `local.get $msg` `call $__print_i32` | wasmtime: `failed to compile: wasm[0]::function[2]::main … Invalid input WebAssembly code at offset 149: type mismatch: expected a type but nothing on stack` (drop after a void call). `@print(msg)` of a string parameter would also print the pointer as an integer instead of `started`. | Don't `drop` void calls, and pick the print lowering by type. |
| builtin_print_return_value_void | erlang | weak | confirmed | RUN LOG `<<"started">>`/`<<"done">>` | Correct for the program, but cache-masked: erlc warns `variable 'X' is unused` (H2), and this is one of the 5 erlang RUN LOGs that go empty on a cold cache. | See H2. |
| stdlib_result_map_transforms_ok_propagates_error_intact | beam | wrong-output | confirmed | `S/beam/stdlib_result_map_transforms_ok_propagates_error_intact`: `{get_tuple_element, {x, 0}, 1, {x, 2}}.` `{test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.` | Live=3 but `x1` was never set. `erlc +from_asm` fails (exit 1, re-run): `main:1: function main/0+13: … Instruction: {test_heap,{alloc,[{words,0},{floats,0},{funs,1}]},3} Error: {{x,1},not_live}`. | Compute live correctly, or move V into x1 before `test_heap`. |
| stdlib_result_flatmap_chains_and_flattens | beam | wrong-output | confirmed | `S/beam/stdlib_result_flatmap_chains_and_flattens`: same `{test_heap, {alloc, ...}, 3}.` after `get_tuple_element ... {x, 2}` | Same validator error at `main/0+13`, exit 1. | Same. |
| stdlib_chain_map_flatmap_unwrapor_types_correctly | beam | wrong-output | confirmed | `S/beam/stdlib_chain_map_flatmap_unwrapor_types_correctly`: `{test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.` | Same validator error `{{x,1},not_live}`, exit 1. | Same. |
| stdlib_result_map…, stdlib_result_flatmap…, stdlib_chain… | wasm | wrong-output | confirmed | `S/wasm/stdlib_result_map_transforms_ok_propagates_error_intact`: `(else` … `(local $n i32)` … `(local $_res1 i32)` inside the function body | Locals must be declared in the function header. wasmtime: `unknown operator or unexpected token --> main.wat:24:6 | (local $n i32)` (flatMap: line 27, chain: line 29) — re-run, same lines. | Hoist lambda-param and temp locals to the function header. |
| stdlib_option_map_flatmap_and_unwrapor_mirror_result | erlang | wrong-output | confirmed | `S/erlang/stdlib_option_map_flatmap_and_unwrapor_mirror_result`: `(<<"Hello ">> + N)` | Binary concat expected; `+` on binaries is badarith. It compiles (unused-var warnings only, re-run), but the code is wrong. | String concat lowering. |
| stdlib_option_map_flatmap_and_unwrapor_mirror_result | beam | wrong-output | confirmed | `S/beam/stdlib_option_map_flatmap_and_unwrapor_mirror_result`: `{move, {x, 0}, {x, 3}}.` `{test_heap, {alloc, [...]}, 1}.` … `{move, {x, 3}, {x, 0}}.` and in `'-greet/1-fun-0-'`: `{move, {literal, <<"Hello ">>}, {x, 0}}.` `{move, {x, 0}, {x, 1}}.` `{gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.` | With `greet` exported the validator fails (re-run): `main:1: function greet/1+13: … Instruction: {move,{x,3},{x,0}} Error: {uninitialized_reg,{x,3}}`. The committed form only assembles because `greet` is unexported and dropped before validation. The lambda also overwrites its parameter `n` (x0) with `"Hello "` before reading it, and uses `'+'` on binaries. | Fix live counting and the argument clobber, and add binary concat. |
| stdlib_option_map_flatmap_and_unwrapor_mirror_result | wasm | wrong-output | confirmed | `S/wasm/stdlib_option_map_flatmap_and_unwrapor_mirror_result`: `(then` `(local $n i32)` and `i32.const 256` `local.get $n` `i32.add` | wasmtime: `unknown operator or unexpected token --> main.wat:22:6`. String concat is also pointer addition. | Hoist locals and add a concat helper. |
| stdlib_result_* (4), stdlib_option_* (2), stdlib_chain (1) | all | weak | confirmed | e.g. SOURCE `fn parseAge(s: string) -> @Result<i32, string> { @todo(); }` and `val r = parseAge("42").map({ n -> n + 1 });`, with every RUN LOG empty | The names promise behaviour, but every producer is `@todo()` and nothing is printed. Re-ran all four backends: node `Error: not implemented`, erlang `CRASH error:{todo,<<"not implemented">>}`, beam `error:undef`/validator reject, wasm `wasm trap: unreachable` in `parseAge`. Neither the Ok nor the Error branch is ever exercised. | Give producers real bodies returning Ok and Error, and `@print` the results. |
| stdlib_result_isok_and_iserror_predicates | erlang | weak | confirmed | `S/erlang/stdlib_result_isok_and_iserror_predicates`: `Ok = (fun(R) -> case R of {ok, _} -> true; _ -> false end end)(R),` | erlc: `main.erl:9:15: Warning: variable 'R' shadowed in 'fun'` (twice, re-run). Harmless now, but it would blank the RUN LOG as soon as a `@print` is added (H2). | Use a fresh lambda var name (e.g. `R__`). |
| record_method_with_todo_placeholder | erlang | wrong-output (minor) | confirmed | `S/erlang/record_method_with_todo_placeholder`: `erlang:error({todo, "not implemented"}).` vs `S/erlang/stdlib_result_map_transforms_ok_propagates_error_intact`: `erlang:error({todo, <<"not implemented">>}).` | Re-ran both: charlist `{todo,"not implemented"}` here, binary `{todo,<<"not implemented">>}` there — same builtin, two shapes. Source: `erlang.zig:1329` argc=0 template `"erlang:error({todo, \"not implemented\"})"`. | Use `<<"not implemented">>` in the argc=0 templates for `todo` and `panic`. |
| record_method_with_todo_placeholder | beam | wrong-output (minor) | confirmed | `S/beam/record_method_with_todo_placeholder`: `{move, {atom, undef}, {x, 0}}.` `{call_ext_only, 1, {extfunc, erlang, error, 1}}.` | `{todo, <<"not implemented">>}` expected; actual `m_r5:'Unimplemented_process'(#{}) => CRASH error:undef`. | As for builtin_todo. |
| test_runner | node | weak | confirmed | `S/commonJS/test_runner` RUN LOG: `  duration 0ms` (twice) | Wall-clock timing sits in the snapshot. A slow host would print `1ms`; the value is frozen by cache key `7c83e68fac1b…` (2026-06-27 01:13, recomputed — the entry's payload is exactly the snapshot's RUN LOG). | Normalise the duration in snapshot mode. |
| test_runner | erlang | weak | confirmed | `S/erlang/test_runner` RUN LOG empty | See H4 (`_botopink_main` never appears in the test-mode module). Running `main:main([])` by hand prints the same envelope as node. | See H4. |
| test_runner_excluded_from_normal_build | node only | weak | confirmed | `builtins.zig:322-323`: `assertJsContains(... &.{"function add"})` / `assertJsNotContains(... "__bp_test", "__bp_assert", "__bp_run_tests")` | Only commonJS is checked. Erlang/beam exclusion of `'__bp_test_0'`/`'__bp_run_tests'` is untested. | Loop over the erlang config as well. |
| builtin_print_in_if_branch | all 4 | wrong-test | **corrected** | All 4 snapshot files are **0 bytes** (`git cat-file -s` = 0). SOURCE in test (`builtins.zig:244-254`): `if x > 0 {` | Parser `src/parser/exprs.zig:139-145` requires `if (cond)` (`:142` `_ = try this.consume(.leftParenthesis);`). Re-probed with `zig-out/bin/botopink check` (built after every parser commit here): this source → `error: parse error in main`, while `if (x > 0) {` checks clean. **Correction:** the earlier claim that "the test cannot pass" is wrong — the parse error drops the module (`commonJS.zig:52-53`, `erlang.zig:315-316`, `beam_asm.zig:403-404`, `wat.zig:96-97`), `buildSnapshotMulti` (`codegen/snapshot.zig:142-154`) returns `""` and `utils/snap.zig:81-84` trims both sides, so the test passes **vacuously** and asserts nothing. | Change to `if (x > 0) { ... }`, give it a `main` that calls `check`, and regenerate. Also make `assertJs` fail when there are zero outputs. |
| builtin_print_in_loop | all 4 | wrong-test | **corrected** | All 4 snapshot files are 0 bytes. SOURCE (`builtins.zig:265-276`): `loop {` … `val i = i - 1;` | `parseLoopExpr` (`src/parser/exprs.zig:1604`, `:1617` `_ = try this.consume(.leftParenthesis);`) requires `loop (iter) {`; the binary reports `error: parse error in main` (re-probed). Same vacuous-pass correction as above. Even if it parsed, `val i = i - 1;` shadows rather than mutates, so the loop would never terminate. | Rewrite with `loop (0..n) { i -> @print(i); }` or `var`, and regenerate. |
| interface_literal_basic, interface_literal_with_fields | all 4 | wrong-test | **corrected** (cause found) | All 8 snapshot files are 0 bytes, committed empty by `8d88372 test: add interface literal tests …` (2026-09-14). SOURCE: `val DeclKind = record { Record: "Record", Fn: "Fn" };` `val decl = @Decl(kind: DeclKind.Record, ...)` | Probed at HEAD: `val DeclKind = record { Record: "Record", Fn: "Fn" };` **alone** → `error: parse error in main`; `val D = record { a: 1 };` also fails; `val D = record { a: i32 };` checks clean. So a `val X = record { … }` binding parses as a record *type* declaration and rejects literal field "types". The interface literal itself is fine: `val decl = @Decl(kind: "Record", …, fields: [record { name: "x", typeName: "i32", annotations: [] }], …);` checks clean — an anonymous record literal inside a call argument parses. Same vacuous-pass correction: the tests are green and assert nothing. | Replace the `DeclKind` line (plain strings, or an enum) and regenerate; fix the zero-output hole in `assertJs`. |
| record_methods_using_self_fields_in_arithmetic | beam | wrong-output | confirmed | `S/beam/record_methods_using_self_fields_in_arithmetic`: `{get_map_elements, {f, 6}, {x, 0}, {list, [{atom, x}, {x, 0}]}}.` `{label, 6}.` `{move, {x, 0}, {x, 1}}.` `{test, is_map, {f, 7}, [{x, 0}]}.` | Self (x0) is overwritten by the first field read. Re-ran: `'Vec2_lengthSq'(#{x=>3.0,y=>4.0})` returns `90.0` (should be `25.0`; the erlang backend returns `25.0`). `'Vec2_scale'(#{x=>3.0,y=>4.0}, 2.0)` happens to be right (`6.0`) because it reads only `.x`. | Load fields into scratch registers and keep self in x0/y. |
| record_methods_using_self_fields_in_arithmetic | wasm | wrong-output | confirmed | `S/wasm/record_methods_using_self_fields_in_arithmetic`: `(func $Vec2_lengthSq (param $self i32) (result i32)` `i32.load ;; .x` `i32.mul` | Fields are `f64` in the source, but the code is i32 load/mul/result, so fractional values are wrong. | Use `f64.load`/`f64.mul` and an `(result f64)` type. |
| record_method_with_throw | erlang | wrong-output | confirmed | `S/erlang/record_method_with_throw`: `erlang:throw('Error'(<<"invalid invoice">>)).` | erlc exit 1: `main.erl:9:18: function 'Error'/1 undefined`. | Lower `new Error(msg)` to a real term, e.g. `{error, Msg}`. |
| record_method_with_throw | beam | wrong-output | confirmed | `S/beam/record_method_with_throw`: `%% unresolved local call: Error/1` and `{call_ext_only, 1, {extfunc, erlang, throw, 1}}.` and `Invoice_total` with the same x0 clobber `{get_map_elements, {f, 6}, {x, 0}, {list, [{atom, subtotal}, {x, 0}]}}.` | The `%%` marker is an unsupported-lowering comment; `throw` gets a bare binary (`'Invoice_validate'(…)` → `CRASH throw:<<"invalid invoice">>`). `'Invoice_total'(#{subtotal=>100.0, taxRate=>0.5})` returns `1.01e4` instead of `150.0` (re-run). | Fix the Error ctor and the self clobber. |
| record_method_with_throw | wasm | wrong-output | confirmed | `S/wasm/record_method_with_throw`: `call $Error` | wasmtime: `unknown func: failed to find name $Error --> main.wat:18:10`. Fields are also f64 lowered as i32. | Emit an Error ctor or `unreachable`, and use f64. |
| record_shorthand_declaration_without_val_name | beam | wrong-output | confirmed | `S/beam/record_shorthand_declaration_without_val_name`: `{get_map_elements, {f, 4}, {x, 0}, {list, [{atom, x}, {x, 0}]}}.` … `{move, {x, 0}, {x, 2}}.` `{test, is_map, {f, 6}, [{x, 0}]}.` | `'Vec2_dot'(#{x=>1.0,y=>2.0}, #{x=>3.0,y=>5.0})` returns `18.0` instead of `13.0` (re-run); `self.y` is never read because self was clobbered. | Same as record_methods. |
| record_shorthand_declaration_without_val_name | wasm | wrong-output | confirmed | `S/wasm/record_shorthand_declaration_without_val_name`: `(func $Vec2_dot (param $self i32) (param $other i32) (result i32)` `i32.load ;; .x` | f64 fields lowered as i32. | f64 lowering. |
| array_string_array_literal, array_val_with_array_type_annotation, array_prepend_with_empty_array, _single_element_array, _multiple_elements_array, array_prepend_with_identifier | beam | known | confirmed | e.g. `S/beam/array_string_array_literal`: `{move, nil, {x, 0}}.` … `{deallocate, 0}.` with no `{allocate…}` | Re-ran with the functions exported: the validator fails for all 6, `Instruction: {deallocate,0} Error: {allocated,none}`. With `deallocate` removed the values are correct except for the identifier case: `xs() => [<<"hello">>,<<"world">>]`, `array() => [<<"65454">>]`, `list1() => [1]`, `list2() => [1,2,3]`, `list3() => [1,2,3,4]`, `rest() => [3,4]` (but `list() => [1,2]`, see below). | Known. |
| array_prepend_with_identifier | erlang | wrong-output (+ known) | confirmed | `S/erlang/array_prepend_with_identifier`: `list() ->` `[1, 2, rest].` | Expected `[1, 2] ++ rest()` = `[1,2,3,4]`; `main:list()` returns `[1,2,rest]` (re-run): the top-level val is referenced as an atom (the known "top-level val read" issue) **and** the spread is lost. Literal spreads work (`[1, 2] ++ [3, 4]` in `S/erlang/array_prepend_with_multiple_elements_array`). | Lower `..ident` to `++ ident()`. |
| array_prepend_with_identifier | beam | wrong-output | confirmed | `S/beam/array_prepend_with_identifier`: `list/0` builds only `{integer, 2}` and `{integer, 1}` on `nil` | Expected `[1,2,3,4]`, actual `[1,2]` (re-run after removing `deallocate`). `..rest` is silently dropped. | Call `rest/0` and append. |
| array_* (6), tuple_string_pair_literal, tuple_val_with_tuple_type_annotation, tuple_mixed_types, tuple_literal_pair, tuple_nested_tuples, call_children_coercion_list_single_text | wasm | wrong-output | confirmed | e.g. `S/wasm/array_string_array_literal`: `(global $__heap_ptr (mut i32) (i32.const 256))` `(global $xs (mut i32) (i32.const 0))`; `S/wasm/call_children_coercion_list_single_text`: `(global $many (mut i32) (i32.const 0))` | Top-level `val` initializers (arrays, tuples, calls) are dropped and every global is a 0 placeholder. No data segment, no allocation, no start/init function. The WAT validates (wasmtime compile rc=0) but has no semantics. | Emit a module init function that allocates and stores the value. |
| tuple_string_pair_literal, tuple_val_with_tuple_type_annotation, tuple_mixed_types, tuple_literal_pair | beam | wrong-output (+ known deallocate) | confirmed | `S/beam/tuple_string_pair_literal`: `{move, {literal, <<"56454">>}, {x, 0}}.` `{move, {x, 0}, {x, 0}}.` `{move, {literal, <<"85484">>}, {x, 0}}.` `{move, {x, 0}, {x, 1}}.` `{put_tuple2, {x, 0}, {list, [{x, 0}, {x, 1}]}}.` | The first element is overwritten by the second. Re-run (deallocate removed): `t() => {<<"85484">>,<<"85484">>}` for both tuple_string_pair_literal and tuple_val_with_tuple_type_annotation, mixed → `{<<"5452">>,<<"5452">>}`, pair → `{<<"hello">>,<<"hello">>}`. | Move element i into x_i (the `{move,{x,0},{x,0}}` should target x_i). |
| tuple_nested_tuples | beam | wrong-output (+ known) | confirmed | `S/beam/tuple_nested_tuples` (same clobber pattern, 3 `put_tuple2`) | Expected `{{1,2},{3,4}}`, actual `nested() => {{4,4},{4,4}}` (re-run). | Same. |
| record_fn_typed_field_hook_shape_record | erlang | wrong-output | confirmed | `S/erlang/record_fn_typed_field_hook_shape_record`: `set(S, maps:get(value, S)),` | erlc exit 1: `main.erl:11:5: function set/2 undefined`. Expected `(maps:get(set, S))(maps:get(value, S))`. | Call fn-typed fields as closures. |
| record_fn_typed_field_hook_shape_record | beam | wrong-output | confirmed (instruction sharpened) | `S/beam/record_fn_typed_field_hook_shape_record`: `%% unresolved method call: set/2` and in `make/0`: `{move, {x, 0}, {x, 1}}.` `{test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.` … `{put_map_assoc, {f, 0}, {literal, #{}}, {x, 0}, 3, {list, [{atom, value}, {x, 1}, {atom, set}, {x, 2}]}}.` | The `s.set(...)` call is dropped (the `%%` comment is all that is left). When exported, the validator fails in `make/0` at the `put_map_assoc` instruction: `Error: {{x,1},not_live}` (re-run). | Implement closure-field calls and fix live counting. |
| record_fn_typed_field_hook_shape_record | wasm | wrong-output | confirmed | `S/wasm/record_fn_typed_field_hook_shape_record`: `i32.const 0 ;; lambda` and `call $set` | Lambda placeholder; wasmtime: `unknown func: failed to find name $set --> main.wat:24:10`. | Use a funcref table + `call_indirect`. |
| call_children_coercion_list_single_text | beam | wrong-output | confirmed | `S/beam/call_children_coercion_list_single_text`: `{move, {x, 0}, {x, 1}}.` `{call, 0, {f, 3}}.` `{put_list, {x, 0}, {x, 1}, {x, 0}}.` (no `allocate`) | x1 does not survive a `call`, and there is no stack frame. Exported, the validator rejects three functions (re-run): `many/0+8 … Instruction: {call,0,{f,2}} Error: {allocated,none}`, `one/0+5` the same, `txt/0+8 … {call_last,1,{f,4},0}`. Related to the missing-allocate family, but the lost x1 across the call is separate. | Allocate a frame and keep partial lists in y registers. |
| call_children_coercion_list_single_text | all | weak | confirmed | SOURCE `fn box(children: Children) -> string { return "x"; }` | `box` ignores its argument and nothing is printed, so all code is identical regardless of coercion. The snapshot cannot detect a coercion regression (the test is really a type-check test). | Print or inspect `children`, or move to an infer test. |

## `@print` formatting consistency across backends

Lowering (line numbers re-checked at HEAD): node `console.log($args)` (`commonJS.zig:971`), erlang
`io:format("~p~n", [$args])` (`erlang.zig:1340`), beam `io:format("~p~n", [Arg0])` with only the first
argument (`beam_asm.zig:3162-3172`), and wasm `fd_write` for string literals, otherwise
`$__print_i32` of the first argument only (`wat.zig:1751-1772`).

What the snapshots in this batch show (plus re-run node/erl/beam/wasmtime executions):

| value | node | erlang | beam | wasm (wasmtime, RUN LOG stubbed) |
|---|---|---|---|---|
| string literal `"Hello, World!"` | `Hello, World!` | `<<"Hello, World!">>` | `<<"Hello, World!">>` | `Hello, World!` |
| int expr `x * 2` | `20` | `20` | `20` | `20` |
| field `mk().n` | `5` | `5` | `5` | `5` |
| multiple args `"Hello", 42, true` | `Hello 42 true` | badarg crash (format mismatch), empty log | `<<"Hello">>` (args dropped) | `Hello` (args dropped) |
| string concat `"Hello, " + name` | `Hello, world` | badarith crash | badarith crash | `524` (pointer sum) |
| string param `msg` | `started` | `<<"started">>` | `<<"started">>` | would print pointer ints (module invalid anyway) |

Assessment (unchanged after the re-check):
- Erlang and BEAM agree with each other (`~p`, so binaries show as `<<"...">>`). Node prints raw
  strings. The split is consistent across the batch and comes straight from the templates. Nothing
  documents cross-backend textual equality as a goal, so it stays **uncertain whether intended**. The
  RUN LOGs are not comparable across backends for strings, records (`#{n => 5,tag => <<"x">>}` vs JS
  objects), bools or floats.
- Real bugs, independent of that design choice: multi-arg `@print` (erlang format/arity mismatch;
  beam and wasm drop args 1..n); string values in wasm printed as i32 pointers; string `+` lowered as
  arithmetic in erlang, beam and wasm.
- Suggested: add a shared runtime `print` helper per target that formats strings raw
  (`io:put_chars`/`~s` for binaries), joins args with spaces, and matches node. Or state explicitly
  that RUN LOGs are backend-native.

## `ok` slugs (all re-run)

- `builtin_print_single_argument` (node `Hello, World!`, erlang/beam `<<"Hello, World!">>`, wasmtime
  `Hello, World!`; beam log cache-backed per H1)
- `builtin_print_expression` (all 4 print `20`)
- `record_implement_fields_round_trip_at_runtime` (node/erlang/beam `5`; wasmtime `5`; beam log
  cache-backed per H1)
- `record_two_fields` (JS class; erlang/beam/wasm emit no runtime artefact, consistent with map
  records)
- `tuple_access_elements` (`t[0]` / `element(1, T)` / beam `getFirst({7,x})` → `7` / wasm `i32.load`)

## Notes on method

- Erlang: every `ERLANG` block was recompiled with `erlc` and, where a module exists, executed with
  `erl -eval` under a try/catch (`run_builtins.log`, `erlrun/`).
- BEAM: every `.S` was assembled with `erlc +from_asm`, then re-assembled with all functions exported
  so the validator checks them (the committed modules mostly export nothing, so unused local
  functions are dropped before validation, which hides errors). Functions were then called through
  `erl -eval` (`beamrun/run.py`).
- WASM: every WAT was checked with `wasmtime compile`, and modules with `_start` were run with
  `wasmtime run`.
- JS semantics were re-checked in `jsrun/checks.js`.
- Runtime cache hits were reproduced by recomputing `runtime.zig:cacheKey` in Python
  (`cachekey.py`); note the aux list is never empty for these fixtures (the entry module is passed to
  itself as `("main", code)`), which the recomputation accounts for.
- Parseability of the 4 empty-snapshot sources was probed with `zig-out/bin/botopink check` (binary
  built 2026-09-15 19:48, after every parser commit in this tree) inside a throwaway project in the
  scratch dir. The parser-source citations remain the primary evidence.

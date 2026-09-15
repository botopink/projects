# Snapshot review: `modules/compiler-core/src/codegen/tests/control_flow.zig`

- **Repo root:** `/home/ericfillipe/develop/botopink-lang/repository/botopink-lang`
- **Tests reviewed:** 44. 42 of them use `assertJsSingle`, which writes a snapshot for all 4 backends. 2 use `assertJsContains` (needle checks only, no snapshot).
- **Snapshots reviewed:** 168 (42 × 4). **24 of them are 0-byte files** (6 tests × 4 backends).
- **Scratch runs:**
  - Generated code was copied to `scratchpad/run-control_flow/{js,erl,S,wat}/<slug>/`.
  - `erlc` 29 / `erlc +from_asm`, `node --check`, `node`, `erl` and `wasmtime` 45 were run on every file.
  - Fixtures with no `main` were probed by exporting every function (`probe.py`, `jsprobe.py`, `probe/`).
- **Slug check:**
  - Every `assertJsSingle` test has all 4 snapshot files. No orphan snapshots were found for the `case_ / loop_ / if_ / try_ / throw_ / catch_ / mutual_` prefixes.
  - 7 slugs repeat test names in `src/comptime/tests/{variants,types}.zig` and `src/format/tests/patterns.zig`. Those tests write to `snapshots/comptime/...` or other trees, so nothing collides.

Path abbreviations used below (all under `modules/compiler-core/snapshots/codegen/`):
`N/` = `commonJS/`, `E/` = `erlang/`, `B/` = `beam/`, `W/` = `wasm/`.

## Verdict counts (one primary verdict per test, 44 tests)

| verdict | count |
|---|---|
| ok | 1 |
| wrong-output | 26 |
| wrong-test | 8 (6 of these are 0-byte baselines) |
| weak | 6 |
| duplicate | 2 |
| uncertain | 1 |
| known | 0 as primary. It appears as a secondary verdict on 6 tests: 4 erlang erlc-leak tests and 3 BEAM `deallocate`-without-`allocate` tests, with 1 test in both groups. |
| skip-undocumented / orphan | 0 |

Standing known issue: wasm RUN LOG is always empty because `executeWat` is a stub (`src/codegen/runtime.zig:393-401`). It is recorded here once and not repeated per test.

---

## Cross-cutting findings (these explain many rows below)

**H1. BEAM runtime check is inverted. BEAM RUN LOGs can only come from the cache (or a hand edit).** Verdict: wrong-output (harness). Affects every BEAM RUN LOG in the batch.

- `src/codegen/runtime.zig:364-365`:
  - `const assemble_result = try runWithTimeout(allocator, io, &.{ "erlc", "+from_asm", "-o", tmp_dir, asm_filename }, RUNTIME_TIMEOUT_NS);`
  - `if (assemble_result.len == 0) return allocator.dupe(u8, "");`
- The aux loop has the same inverted check at `:375`.
- **Verified:** `erlc +from_asm main.S` prints 0 bytes on success for all 36 non-empty `.S` files of this batch. So a successful assembly returns `""` before `erl` ever runs.
- **Consequence:** a non-empty BEAM RUN LOG can only come from a `.botopinkbuild/runtime-cache` hit (`cacheRead` runs before assembling). The cache is never refilled, because `cacheWrite` is only reached after execution.
- **History:** commit `80e2766` introduced the line and cleared the BEAM RUN LOGs, e.g. `B/case_string_literal_patterns.snap.md` lost `<<"hello">>/<<"hi">>/<<"hi">>`. Commit `58dd5e9` ("update codegen snapshots", Crush-assisted) put them back. On a cold cache every BEAM snapshot with a RUN LOG will mismatch.
- **Fix:** restore the success test: `if (assemble_result.len > 0) return ""` (or check the exit term, as the pre-`80e2766` code did). Apply the same fix to `aux_assemble`.

**H2. Six tests have 0-byte snapshot files on all 4 backends.** Verdict: wrong-test (empty baseline).

- Affected slugs: `loop_map_with_break_add_tax`, `loop_filter_with_conditional_break`, `loop_map_with_break_simple`, `loop_even_numbers_with_break`, `throw_inside_case_arm`, `throw_inside_loop_body`.
- `ls -la` shows size `0` for all 24 files. `git cat-file -s HEAD:…/commonJS/loop_map_with_break_simple.snap.md` returns `0`, and has since `0c30a38 initial commit`.
- `buildSnapshot` always writes `----- SOURCE CODE`, so `compareOrCreate` (`src/utils/snap.zig:61-119`) can never match an empty baseline. These 6 tests are red, or error out before snapshotting. Nothing about their codegen is pinned. No `.snap.md.new` files exist.
- Old non-empty copies in `~/.cline/worktrees/e81c4/...` show that JS then emitted invalid code: `const dobrados = for (const [id] of Object.entries(ids)) {`.
- **Fix:** regenerate the baselines (delete the empty files and run the test), then review them.

**H3. Erlang and BEAM `@print` use `~p`, so strings print as `<<"...">>` while JS prints the bare text.** Verdict: wrong-output (backend divergence).

- `src/codegen/erlang.zig:1330`: `putInlineErlangBuiltinTemplate("print", "io:format(\"~p~n\", [$args])")`.
- `src/codegen/beam_asm.zig:3166`: `Term.str("~p~n")`.
- Example: `N/case_number_literal_patterns` RUN LOG is `zero / one / many`, while `E/` and `B/` show `<<"zero">> / <<"one">> / <<"many">>`.
- Affects `case_number_literal_patterns`, `case_string_literal_patterns`, `case_or_patterns_with_numbers`, `if_simple_conditional_in_fn_body`, `if_conditional_with_else_branch`.
- **Fix:** use a runtime formatter that prints binaries with `~ts` and other values with `~p`, or accept the divergence and document it.

**H4. Multi-argument `@print(a, b, …)` is broken on erlang, BEAM and wasm.** Verdict: wrong-output.

- **erlang:** `io:format("~p~n", [A, B])` has one `~p` but N args.
  - erlc warns: `Warning: the format string requires an argument list with 1 argument, but the argument list contains 2 arguments`.
  - This warning is the reason for the known "erlc output dropped" leak.
  - Even when compiled and run by hand it crashes: `{error,badarg,[{io,format,["~p~n",[0,0]],…`.
- **BEAM:** `beam_asm.zig:3161-3171` lowers only `cc.args[0]` (`if (cc.args.len > 0) try self.lowerExprIntoX0(cc.args[0].value.*);`). The other arguments are silently dropped.
- **wasm:** `wat.zig:1750-1771` lowers only `cc.args[0]`. Non-literal strings go through `$__print_i32`, which prints the data pointer (e.g. `288`) instead of the text.
- Affects `try_nested_try_catch`, `try_catch_preserves_surrounding_bindings`, `try_multiple_catch_with_different_fallbacks`.

**H5. wasm backend emits invalid modules in most fixtures of this batch.** Verdict: wrong-output.

- **`(local …)` declared mid-body.**
  - `wat.zig:2053-2057` (`lowerCase`: `try self.fmt("    (local ${s} i32)\n", .{subj_local});` after `lowerExpr(subject)`).
  - `wat.zig:1805-1810` (`declRes`: "Declared inline").
  - wasmtime rejects this: `Error: unknown operator or unexpected token --> main.wat:11:6 | (local $__case_0 i32)`.
- **Void functions that leave a value on the stack.**
  - `$main` ends with `call $classify` and no `drop`.
  - `loop_side_effect_over_range` ends with `i32.const 0`.
  - wasmtime rejects this: `type mismatch: values remaining on stack at end of block`.
- **Case arms silently dropped.** In `wat.zig:2087-2092` the `.stringLit` arm emits `local.get $subj` / `drop`, then the arm body, and never tests the subject. The `.list`, guarded, variant and `.multi` patterns fall into `else => lowerExpr(arm.body)` (`wat.zig:2116-2118`), which always returns the first arm.
- **Loops over collections are not implemented.** `wat.zig:2542`: `try self.w("    i32.const 0 ;; loop over non-range\n");`.
- **Lambdas replaced by a placeholder.** `wat.zig:1685`: `.function => try self.w("    i32.const 0 ;; lambda\n")`.

---

## Findings table (all non-`ok` findings)

| slug | backend(s) | verdict | evidence (quoted, path) | expected vs actual | suggested fix |
|---|---|---|---|---|---|
| case_number_literal_patterns | erlang, beam | wrong-output (H3) | `E/…`, `B/…` RUN LOG: `<<"zero">>` `<<"one">>` `<<"many">>` | expected `zero/one/many` (as `N/`); actual binary term syntax | H3 |
| case_number_literal_patterns | wasm | wrong-output (H5) | `W/…`: `local.get $n` / `(local $__case_0 i32)` / `local.set $__case_0`; `$main` ends `i32.const 7` / `call $classify` with no `drop`; `local.get $result` / `call $__print_i32` | valid module printing strings. wasmtime says `unknown operator … (local $__case_0 i32)`. Once fixed it would still print pointers (256/264/272). | `wat.zig` `lowerCase` (hoist locals). Drop the value of the last expression statement in void fns. Print strings via fd_write. |
| case_string_literal_patterns | beam | **wrong-output** | `B/case_string_literal_patterns.snap.md`: label 11 `{move, {x, 0}, {x, 1}}.` then `{move, {literal, <<"pt">>}, {x, 0}}.` / `{test, is_eq, {f, 12}, [{x, 1}, {x, 0}]}`. RUN LOG: `<<"hello">>` `<<"hi">>` `<<"hi">>` | expected `hello, ola, hi`. After the first test fails, `{x,0}` holds the literal `<<"en">>`, not the subject, so `"pt"` never matches (confirmed by running the `.S`). | `beam_asm.zig` `lowerCase` `.stringLit` (3500-3518): emit `{move,{x,1},{x,0}}` at the `next` label, or test `[{x,0},{literal,…}]` without clobbering `{x,0}`. |
| case_string_literal_patterns | erlang | wrong-output (H3) | `E/…` RUN LOG `<<"hello">>` … | format divergence | H3 |
| case_string_literal_patterns | wasm | wrong-output (H5) | `W/…`: `local.get $__case_0` / `drop` / `i32.const 256` / `local.set $msg`. Only `hello` is in the data section; `"ola"`/`"hi"` are never emitted. | always "hello" plus an invalid mid-body local | `wat.zig:2087` `.stringLit` arm: implement `$__str_eq` compare |
| case_or_patterns_with_numbers | erlang, beam | wrong-output (H3) | RUN LOG `<<"weekday">>` … | format divergence | H3 |
| case_or_patterns_with_numbers | wasm | wrong-output (H5) | `W/…`: `(local $__case_0 i32)` after `local.get $day`; `$main` has a trailing `call $classify` with no drop | invalid module | H5 |
| if_simple_conditional_in_fn_body | all | wrong-output (divergence) | `N/…` RUN LOG `positive` / `undefined`; `E/…` `_ -> ok` with RUN LOG `ok`; `B/…` `{move, {atom, undefined}, {x, 0}}` with RUN LOG `undefined`; `W/…` `(else i32.const 0)` | else-less `if` is used as a value in `val r` and returned as `string`. The 4 backends yield `undefined` / `ok` / `undefined` / `0`. Either the type checker should reject this (or type it `?string`) or the backends should agree. | type checker: reject or mark optional. `erlang.zig`: else-less if should yield `undefined` (match BEAM). |
| if_simple_conditional_in_fn_body | wasm | wrong-output (H5) | `W/…` `$main`: `i32.sub` / `call $sign` with no `drop` | wasmtime: `values remaining on stack at end of block` | H5 |
| if_conditional_with_else_branch | erlang, beam | wrong-output (H3) | RUN LOG `<<"positive">>` `<<"non-positive">>` | format divergence | H3 |
| if_conditional_with_else_branch | wasm | wrong-output | `W/…`: `call $describe` / `call $__print_i32` | running it in wasmtime prints `256` / `268` (pointers), not the strings | `wat.zig:1750-1771` print of a string-typed expression |
| try_propagate_without_catch | all | weak | `N/…` has no `_botopink_main`; RUN LOG empty on every backend. `fetch()` is `@todo()`. | Nothing runs. `process` is a non-`#[@result]` fn returning `i32`, yet it propagates an error object (`if ("error" in _try0) return _try0;`). Minor divergence: BEAM `{move, {atom, undef}, {x, 0}}` + `erlang:error/1` vs erlang `erlang:error({todo, <<"not implemented">>})`. | Add `main` and a real Ok/Error fetch. Consider rejecting `try` in a non-result fn. |
| try_with_inline_catch_handler | all | weak | `N/…` `fetch() { (() => { throw new Error("not implemented") })(); }`; RUN LOG empty on JS/erlang/BEAM | `@todo` panics before `catch` runs (node exits non-zero, erlang `{todo,…}`, BEAM `undef`, wasm `unreachable`), so the catch path is never exercised and the RUN LOG proves nothing. | Make `fetch` `throw "x"` so the handler prints `0`. |
| case_list_patterns_empty_single_spread | beam | **wrong-output** | `B/…`: `{test, is_nonempty_list, {f, 6}, [{x, 0}]}.` / `{get_list, {x, 0}, {x, 1}, {x, 0}}.` / `{move, {literal, <<"one">>}, {x, 0}}.` with no `is_nil` check on the tail | `["a","b","c"]` must give `"many"` (JS/erlang agree). The probe `main:describe()` on the assembled `.S` returns `<<"one">>`. `get_list` also clobbers the subject in `{x,0}` for later arms. | `beam_asm.zig` `lowerCase` `.list` (~3610-3630): after the fixed elems with no spread, emit `{test,is_nil,…}` on the tail. Save the subject before `get_list`. |
| case_list_patterns_empty_single_spread | wasm | wrong-output (H5) | `W/…`: `(local $__case_0 i32)` / `local.set $__case_0` / `i32.const 280` / `return` (280 = `"empty"`) | always "empty"; invalid module | `wat.zig` `emitCaseArms` list patterns |
| case_list_patterns_empty_single_spread | all | weak | no `main`, RUN LOG empty | the BEAM bug above is invisible | add `main` with `@print(describe())` |
| loop_side_effect_print_in_iterator | erlang | known (erlc leak), plus a real bug | `E/…`: `lists:foreach(fun(Msg, I) ->` | erlc says `main.erl:6:28: Warning: variable 'I' is unused`, which triggers the leak. **Even when compiled by hand it crashes:** `{error,function_clause,[{lists,foreach,[#Fun<main.0.39240815>,…` because `lists:foreach` needs an arity-1 fun. Expected `Erro 404 / Sucesso 200 / Aviso 500`. | `erlang.zig:2744-2752` `.loop`: with 2 params, iterate `lists:zip(Xs, lists:seq(0, length(Xs)-1))` with `fun({Msg, I}) ->`, and name unused params `_I`. |
| loop_side_effect_print_in_iterator | beam | **wrong-output** | `B/…`: `{function, '-main/0-fun-0-', 2, 9}.` passed to `{call_ext, 2, {extfunc, lists, foreach, 2}}`; RUN LOG empty | running the `.S` gives `function_clause` in `lists:foreach`; expected 3 lines | `beam_asm.zig` `lowerLoop` (3882+): same zip/index lowering as erlang |
| loop_side_effect_print_in_iterator | wasm | wrong-output (H5) | `W/…`: `local.set $messages` / `i32.const 0 ;; loop over non-range` in void `$main`, and no fd_write import | loop body never emitted; invalid module | `wat.zig:2531-2543` `lowerLoop` |
| loop_side_effect_over_range | wasm | wrong-output (H5) | `W/…` `$main` ends `)` `)` then `i32.const 0` | wasmtime: `values remaining on stack`. The loop itself is correct. | `lowerRangeLoop`: do not push a trailing value in statement position |
| loop_map_with_break_add_tax | all 4 | wrong-test (H2) | `N/`,`E/`,`B/`,`W/loop_map_with_break_add_tax.snap.md` are 0 bytes | baseline missing; test cannot pass | regenerate and review |
| loop_filter_with_conditional_break | all 4 | wrong-test (H2) | 0-byte files | same | same |
| loop_map_with_break_simple | all 4 | wrong-test (H2) | 0-byte files | same | same |
| loop_even_numbers_with_break | all 4 | wrong-test (H2) | 0-byte files | same | same |
| case_or_patterns_with_block_arm_body | beam | wrong-output, plus known (`deallocate` without `allocate`) | `B/…` label 6: `{make_fun3, {f, 8}, 0, 0, {x, 0}, {list, []}}.` / `{jump, {f, 4}}.`; the fun body ends `{move, {atom, ok}, {x, 0}}.`; `parity/0` has `{deallocate, 0}.` with no `allocate` | expected `"odd"`. Actual: the block arm becomes a closure returning `ok`. With `parity` exported, erlc rejects it: `Internal consistency check failed … Instruction: {deallocate,0} Error: {allocated,none}`. | `beam_asm.zig`: lower a block arm inline (like `erlang.zig` `caseBodyNode`), not as `make_fun3` |
| case_or_patterns_with_block_arm_body | wasm | wrong-output | `W/…`: `(global $parity (mut i32) (i32.const 0))` and nothing else | the whole case expression is dropped | `wat.zig`: top-level `val` with a non-constant initializer needs a start function |
| case_or_patterns_with_block_arm_body | all | weak | no `main`/print; RUN LOG empty | the constant subject `5` is never observed | add `@print(parity)` in `main` |
| case_union_return_type_from_mismatched_arms | beam | known (`deallocate` without `allocate`) | `B/…` `result/0`: `{move, {integer, 42}, {x, 0}}.` … `{deallocate, 0}.` with no `allocate` | validator rejects it once the function is live (verified) | known |
| case_union_return_type_from_mismatched_arms | wasm | wrong-output | `W/…`: `(global $result (mut i32) (i32.const 0))` | case dropped; union type never represented | as above |
| case_union_return_type_from_mismatched_arms | all | weak | no RUN LOG | nothing is observed | add a print |
| case_nested_case_in_block_arm | all | uncertain (semantics) + weak | `N/…`: `if (_s === 0) { (() => {…})(); }` then `return 1;` (inner value discarded). `E/…`: `0 -> case 1 of … end;` (inner value returned). `B/…`: `{make_fun3, {f, 7}, …}` (fun returned; inner fun ends `{move, {atom, ok}, {x, 0}}`). `W/…`: `(global $result (mut i32) (i32.const 0))`. BEAM also has `deallocate` without `allocate` (known). | The 4 backends disagree on a block arm with no `break`. The comptime snapshot types it as `"return_type": "?"`. The subject is `42` and inner and outer defaults are both `1`, so no output could expose the divergence. | Decide the semantics (implicit block value vs `break` required), then use a subject of `0` and a distinct inner value |
| loop_break_with_value | commonJS | **wrong-output** | `N/…`: `return for (const x of arr) {` / `(() => { if ((x > 10)) { return return x; } })();`; RUN LOG empty | `node --check`: `SyntaxError: Unexpected token 'for'`. Expected `15`. | `commonJS.zig` `.loop` expr (~2670-2770): lower `break v` in value position as `for…{ if(c) return v; }` inside an IIFE |
| loop_break_with_value | erlang | **wrong-output** | `E/…`: `lists:foreach(fun(X) -> case (X > 10) of true -> X; _ -> ok end end, Arr).` RUN LOG `ok` | expected `15`, actual `ok` | `erlang.zig:2744-2752`: treat `break v` as early exit (a recursive helper, or `lists:search`) |
| loop_break_with_value | beam | **wrong-output** | `B/…`: `{call_ext, 2, {extfunc, lists, map, 2}}`; the fun returns `X` or `ok`. RUN LOG `[ok,ok,15,20]` | expected `15` | `beam_asm.zig` `lowerLoop` |
| loop_break_with_value | wasm | wrong-output (H5) | `W/…` `$find`: `i32.const 0 ;; loop over non-range` / `return` | wasmtime prints `0` | `wat.zig:2542` |
| loop_continue_in_iteration | commonJS | **wrong-output** | `N/…`: `(() => { if (((x % 2) !== 0)) { return continue; } })();` inside `arr.map` | `SyntaxError: Unexpected token 'continue'` | `commonJS.zig`: `continue` inside a map callback should `return` a skip sentinel, or lower to a `for` loop with `push` |
| loop_continue_in_iteration | erlang | **wrong-output** | `E/…`: `true ->` / `%% continue;` / `_ -> ok` | erlc: `main.erl:8:15: syntax error before: '->'` (the clause body is only a comment) | `erlang.zig`: lower `continue` in a yield loop as a filter (`lists:filtermap`) |
| loop_continue_in_iteration | beam | **wrong-output** | `B/…` fun: `{gc_bif, 'rem', …, {x, 0}}.` / `{test, is_ne_exact, {f, 6}, [{x, 1}, {integer, 0}]}.` / `{move, {atom, ok}, {x, 0}}.` … label 7 returns `{x,0}` (the rem result) | the probe `sumEvens([1,2,3,4])` gives `[ok,0,ok,0]`; expected `[2,4]` | `beam_asm.zig` `lowerLoop` |
| loop_continue_in_iteration | wasm | wrong-output (H5) | `W/…` `i32.const 0 ;; loop over non-range` | stub | `wat.zig:2542` |
| loop_continue_in_iteration | test | wrong-test / weak | source: `fn sumEvens(arr: i32[]) -> i32 { return loop (arr) { x -> … yield x; }; }` with no `main` | The name and `-> i32` promise a sum, but the body yields a filtered list. Nothing runs. | Rename to `evens` with `-> i32[]` and add `main` with `@print(evens([1,2,3,4]))` |
| loop_yield_accumulation | wasm | wrong-output (H5) | `W/…` `$doubles`: `i32.const 0 ;; loop over non-range` | wasmtime prints `0`; expected `[2,4,6]` | `wat.zig:2542` |
| if_null_check_binding | erlang | **wrong-output** | `E/…`: `case Name of undefined -> undefined; N -> N; _ -> ok end,` then `<<"unknown">>.` | the `return n` is lost. Probe `getName(<<"bob">>)` gives `<<"unknown">>`. erlc: `Warning: this clause cannot match because a previous clause at line 6 always matches`. | `erlang.zig`: `if (x) { n -> return … }` should become `case Name of undefined -> <<"unknown">>; N -> N end` (the rest of the fn goes into the `undefined` branch) |
| if_null_check_binding | beam | **wrong-output** | `B/…`: `{test, is_eq, {f, 4}, [{x, 0}, {atom, true}]}.` / `{move, {atom, n}, {x, 0}}.` | tests `== true` instead of non-null and returns the atom `n` instead of the value. Probe: `getName(<<"bob">>)` gives `<<"unknown">>`. | `beam_asm.zig`: null-check `if` binding should test `is_ne_exact … {atom, undefined}` and bind the local, not an atom |
| if_null_check_binding | wasm | wrong-output | `W/…`: `global.get $n` | wasmtime: `unknown global: failed to find name $n` | `wat.zig`: bind the `if` capture as a local |
| if_null_check_binding | all | weak | no `main` | none of the above shows in any RUN LOG | add `main` calling it with a value and with `null` |
| case_multiple_subjects | commonJS | **wrong-output** | `N/…`: `if () return null;` (twice) | `SyntaxError: Unexpected token ')'` | `commonJS.zig` `buildCondStr` for `.multi` (`_s[0] === 0 && _s[1] === 0`) |
| case_multiple_subjects | wasm | wrong-output (H5) | `W/…` `$process`: `local.get $a` / `(local $__case_0 i32)` / `local.set $__case_0` / `i32.const 0` | only the first subject is lowered; arms dropped; invalid | `wat.zig` `lowerCase` (`c.subjects[0]` only) |
| case_multiple_subjects | beam | weak (null representation) | `B/…`: `{move, {atom, nil}, {x, 0}}.` vs `E/…` `undefined` | `null` is `nil` on BEAM but `undefined` on erlang (and BEAM uses `undefined` elsewhere, e.g. `if_simple_conditional`). No main. | unify the null atom in `beam_asm.zig` |
| case_nested_case_in_fn_body | beam | **wrong-output** | `B/…`: `{make_fun3, {f, 7}, …}` for the arm; the inner fun has `{move, {atom, x}, {x, 0}}.` and ends `{move, {atom, ok}, {x, 0}}.` | the probe `process(0)` returns `#Fun<main.0.…>`; expected `<<"zero">>`. The captured variable `x` is lowered to the atom `x`. | `beam_asm.zig`: lower `break case…` block arms inline; resolve captured locals |
| case_nested_case_in_fn_body | wasm | wrong-output | `W/…`: `(then i32.const 0 ;; lambda )`; mid-body `(local $__case_0 i32)` | inner case replaced by a placeholder; invalid | `wat.zig:1685`, `lowerCase` |
| case_nested_case_in_fn_body | all | weak | no main | — | add prints |
| try_catch_with_throw_rethrow | erlang | **wrong-output** | `E/…`: `R = case fetch() of {ok, TryV0} -> TryV0; {error, _TryE0} -> {error, <<"fetch failed">>} end,` / `{ok, R}.` | the probe `strict()` gives `{ok,{error,<<"fetch failed">>}}`; expected `{error,<<"fetch failed">>}` (JS and BEAM return early) | `erlang.zig` try/catch (~2715-2740): a `throw` or `return` handler must end the function, not produce a value |
| try_catch_with_throw_rethrow | wasm | wrong-output (H5) | `W/…` inside `(then`: `(local $_res0 i32)`; later `(local $_res1 i32)` | invalid module | `wat.zig:1805` `declRes` |
| try_catch_with_return_fallback | erlang / all | weak | `E/…`: `{error, _TryE0} -> (-1) end,` / `R.` (the `return` is not an early exit) | Correct only because the next statement is `return r`. A fixture with a statement after the `try` would expose the erlang bug above. No main. | add a statement after the `try` (e.g. `@print("unreachable")`) and a `main` |
| try_nested_try_catch | erlang | known (erlc leak), dug | `E/…`: `io:format("~p~n", [A, B]),` | erlc says `main.erl:23:23: Warning: the format string requires an argument list with 1 argument, but the argument list contains 2 arguments`. Run by hand: `{error,badarg,[{io,format,["~p~n",[0,0]]…`. Expected `0 0` / `0`. | H4 (`erlang.zig:1330`: build `~p ~p~n` per arg count) |
| try_nested_try_catch | beam | **wrong-output** (H4) | `B/…` process: a single `{call_ext, 2, {extfunc, io, format, 2}}` after `{move, {y, 0}, {x, 0}}.`; RUN LOG `0` / `0` | expected `0 0` / `0`; `b` dropped | `beam_asm.zig:3161` |
| try_nested_try_catch | wasm | wrong-output (H4) | `W/…`: `local.get $a` / `call $__print_i32` (no `$b`) | wasmtime prints `0` / `0` | `wat.zig:1750` |
| try_catch_tail_on_method_call | beam | **wrong-output** | `B/…` `run`: `%% unresolved method call: parse/1` then directly `{test, is_tagged_tuple, {f, 6}, [{x, 0}, 2, {atom, ok}]}.` | `parse` is never called; the probe `run(#{})` gives `0` | `beam_asm.zig:2329`: resolve the record method `Parser_parse` for receiver type `Parser` |
| try_catch_tail_on_method_call | wasm | wrong-output | `W/…` `run`: `call $parse` (the function is `$Parser_parse`, and `$p` is not passed) | wasmtime: `unknown func: failed to find name $parse` | `wat.zig` method-call lowering |
| try_catch_tail_on_method_call | commonJS, erlang | wrong-output (inconsistent) | `N/…` `parse() { throw new ParseError("bad input"); }` but `run` does `"error" in _try0`; `E/…` `erlang:throw(#{msg => <<"bad input">>})` but `run` matches `{ok,_}/{error,_}` | `parse` lacks `#[@result]`, so `throw` becomes a native exception while the caller expects a Result value. JS probe: `THREW {"msg":"bad input"}`. Erlang probe: the thrown map escapes. The 4 backends disagree (BEAM `0`, wasm invalid). `E/` also names it plain `parse/1` (collision risk) vs BEAM `'Parser_parse'`. | Fixture: add `#[@result]` to `parse` (or have the checker infer it from the `@Result` return). Add a `main`. |
| throw_string_literal | all | weak | no `main`; `W/…` `i32.const 256` / `unreachable` | Nothing is observed. wasm loses the payload (the trap cannot be caught); probably by design. | add a `main` that catches and prints |
| throw_record_constructor | wasm | wrong-output (H5) | `W/…` `$validate` (void): `(if (result i32) (then … unreachable) (else i32.const 0))` with no `drop` | wasmtime: `values remaining on stack at end of block` | `wat.zig`: an `if` in statement position should be a void `(if` |
| throw_record_constructor | all | weak | no `main` | — | — |
| try_propagate_in_multi_statement_fn | wasm | wrong-output (H5) | `W/…` `$pipeline`: `local.set $b` / `(local $_res0 i32)` | invalid module | `wat.zig:1805` |
| try_propagate_in_multi_statement_fn | all | weak | no `main` | JS/erlang/BEAM probes return `{error,{path:"/data"}}` (correct) but nothing is pinned by a RUN LOG | add `main` |
| try_catch_with_lambda_handler | beam | **wrong-output** | `B/…` label 6: `{move, {atom, undefined}, {x, 0}}.` | the lambda handler `fn(e) { return 0; }` is replaced by `undefined`; the probe `safe()` gives `undefined`, expected `0` | `beam_asm.zig` try/catch handler: when the handler is `.function`, apply it to the error value |
| try_catch_with_lambda_handler | wasm | weak / wrong-output | `W/…` `(then i32.const 0 ;; lambda )` | The placeholder `0` happens to equal the lambda's return value, so this passes by coincidence. | `wat.zig:1685` |
| catch_tail_on_binary_expression | test | wrong-test | source: `val r = getA() catch 0;` | The name says "tail on binary expression" but the source has no binary expression (e.g. `getA() + 1 catch 0`). Backends are consistent and correct (probe `compute()` gives `0` everywhere). No main. | rename, or change the source to a binary operand |
| try_catch_with_case_handler | test | wrong-test | source: `val r = try fetch() catch 0;` | The name says "case handler" but there is no `case` in the handler (e.g. `catch fn(e) { case e { ErrorKind.NotFound -> 1; _ -> 2 } }`). Backends are consistent (`0`). | fix the source or the name |
| throw_inside_case_arm | all 4 | wrong-test (H2) | 0-byte snapshot files | baseline missing; test cannot pass | regenerate and review |
| throw_inside_loop_body | all 4 | wrong-test (H2) | 0-byte snapshot files | same | same |
| try_catch_preserves_surrounding_bindings | erlang | known (erlc leak), dug | `E/…`: `io:format("~p~n", [Prefix, Data, Suffix]),` | erlc says `main.erl:17:23: Warning: the format string requires an argument list with 1 argument, but the argument list contains 3 arguments`. Run by hand: `{error,badarg,[{io,format,["~p~n",[10,0,20]]…`. Expected `10 0 20` / `30`. | H4 |
| try_catch_preserves_surrounding_bindings | beam | **wrong-output** (H4) | `B/…` RUN LOG `10` / `30` (only `{move, {y, 0}, {x, 0}}` is printed) | expected `10 0 20` / `30` | `beam_asm.zig:3161` |
| try_catch_preserves_surrounding_bindings | wasm | wrong-output (H4) | `W/…`: `local.get $prefix` / `call $__print_i32` | wasmtime prints `10` / `30` | `wat.zig:1750` |
| try_multiple_catch_with_different_fallbacks | erlang | known (erlc leak), dug | `E/…`: `io:format("~p~n", [Name, Age]).` | erlc says `main.erl:23:23: Warning: the format string requires an argument list with 1 argument, but the argument list contains 2 arguments`. Run by hand: `{error,badarg,[{io,format,["~p~n",[<<"anonymous">>,0]]…`. Expected `anonymous 0`. | H4 |
| try_multiple_catch_with_different_fallbacks | beam | **wrong-output** (H4) | `B/…` RUN LOG `<<"anonymous">>` | expected `anonymous 0`; `age` dropped | `beam_asm.zig:3161` |
| try_multiple_catch_with_different_fallbacks | wasm | wrong-output (H4) | `W/…`: `local.get $name` / `call $__print_i32` | wasmtime prints `288` (the pointer of `"anonymous"`) | `wat.zig:1750` |
| catch_tail_on_function_call_no_try | all | weak | no `main`, RUN LOG empty | All backends are correct by probe (`-1`), but nothing is pinned. | add `main` |
| js: case ---- guard clause on bound identifier (needle test) | commonJS | duplicate | same source as `case_guard_bound_identifier_numeric_guard` | Needles `const x = _s;`, `if ((x > 0)) return "positive";`, `if (_s === 0) return "zero";`, `return "negative";` all appear in `N/case_guard_bound_identifier_numeric_guard.snap.md`. The needle test adds nothing. | delete, or keep only one form |
| js: case ---- guard clause on variant fields (needle test) | commonJS | duplicate | same source as `case_guard_variant_field_guard` | Needles `if (_s.tag === "Circle") {` and `if ((r > 10)) return "big circle";` appear in `N/case_guard_variant_field_guard.snap.md`. | same |
| case_guard_bound_identifier_numeric_guard | erlang | **wrong-output** | `E/…`: `case N of` / `X ->` / `<<"positive">>;` / `0 ->` … (no `when`) | The guard is dropped. The probe `[classify(5),classify(0),classify(-3)]` gives `[<<"positive">>,<<"positive">>,<<"positive">>]`. erlc: `Warning: this clause cannot match because a previous clause at line 5 always matches`. | `erlang.zig` `caseNode` (3046-3068) ignores `arm.guard`: emit `X when X > 0 ->` |
| case_guard_bound_identifier_numeric_guard | wasm | wrong-output | `W/…` `$classify`: `(local $__case_0 i32)` / `local.set $__case_0` / `i32.const 256` / `return` | always "positive"; `zero`/`negative` never emitted; invalid module | `wat.zig` `emitCaseArms` `.ident` + guard |
| case_guard_bound_identifier_numeric_guard | all | weak | no `main`. The test comment says commonJS/erlang/wasm "capture their own current behaviour". | The wrong erlang/wasm output is pinned rather than flagged; BEAM correctness (probe gives `positive, zero, negative`) is not pinned by a RUN LOG. | add `main` with 3 calls |
| case_guard_variant_field_guard | erlang | **wrong-output** | `E/…`: `{tag, Circle, R} ->` | The guard is dropped, and `Circle` is an unbound *variable*, so any 3-tuple `{tag,_,_}` matches. erlc: `Warning: variable 'Circle' is unused`. Probe `big({tag,'Circle',5})` gives `<<"big circle">>`; expected `other`. Enum layout `{tag, Name, R}` also disagrees with BEAM `{'Circle', R}` (`is_tagged_tuple … 2, {atom, 'Circle'}`). | `erlang.zig:3094` use `Ast.Expr.a(v.name)` (atom) and emit `when R > 10`. Unify the variant layout with BEAM. |
| case_guard_variant_field_guard | wasm | wrong-output | `W/…` `$big`: `i32.const 256` / `return` (256 = `"big circle"`) | always "big circle"; invalid mid-body local | `wat.zig` variant patterns |
| case_guard_variant_field_guard | all | weak | no `main` | BEAM correctness (probe `[big circle, other, other]`) is not pinned | add `main` |
| mutual_recursion_forward_reference_bare_if_base_case_on_every_backend | all | weak | source `fn main() -> bool { return isEven(10); }` has no `@print`; RUN LOG empty on all 4 | The test comment says this guards the BEAM regression where `isEven(10)` returned the atom `undefined`, but no RUN LOG checks the value. Probes: BEAM `[main(), isEven(3), isOdd(3)]` gives `[true,false,true]`; erlang and JS agree; wasm runs without a trap. | `@print(isEven(10))` in `main` |

### Cosmetic (not counted)

- All 42 snapshot tests carry a `js:` prefix (or `case guard`) although they snapshot all 4 backends.
- `N/*` TYPESCRIPT TYPEDEF sections contain only blank lines, one per declaration.
- JS prints arrays as `[ 2, 4, 6 ]` while erlang/BEAM print `[2,4,6]` (`loop_yield_accumulation`).

---

## `ok` slugs

- `if_with_else_branch`: all 4 backends are correct. JS/erlang/BEAM RUN LOG `5` / `3`; the wasm module is valid and wasmtime prints `5` / `3`.

Per-backend parts that are correct inside non-ok tests (for reference, not counted as ok):

- **commonJS correct:**
  - case_number_literal_patterns, case_string_literal_patterns, case_or_patterns_with_numbers
  - case_list_patterns_empty_single_spread, loop_side_effect_print_in_iterator, loop_side_effect_over_range, loop_yield_accumulation
  - case_or_patterns_with_block_arm_body, case_nested_case_in_fn_body, if_null_check_binding
  - try_catch_with_throw_rethrow, try_catch_with_return_fallback, try_nested_try_catch, try_propagate_in_multi_statement_fn, try_catch_with_lambda_handler
  - catch_tail_on_binary_expression, try_catch_with_case_handler, try_catch_preserves_surrounding_bindings, try_multiple_catch_with_different_fallbacks, catch_tail_on_function_call_no_try
  - case_guard_*, mutual_recursion
- **erlang correct (apart from H3 formatting):**
  - case_* literal / or, if_conditional_with_else_branch, loop_side_effect_over_range, loop_yield_accumulation
  - case_list_patterns, case_or_patterns_with_block_arm_body, case_multiple_subjects, case_nested_case_in_fn_body
  - try_propagate_in_multi_statement_fn, try_catch_with_lambda_handler, catch_tail_*, try_catch_with_case_handler, throw_*, mutual_recursion
- **beam correct:**
  - case_number_literal_patterns, case_or_patterns_with_numbers, if_conditional_with_else_branch, loop_side_effect_over_range, loop_yield_accumulation
  - try_catch_with_throw_rethrow, try_catch_with_return_fallback, try_propagate_in_multi_statement_fn, catch_tail_*, try_catch_with_case_handler, throw_*
  - case_guard_bound_identifier_numeric_guard, case_guard_variant_field_guard, mutual_recursion
- **wasm valid and correct:** try_catch_with_return_fallback, catch_tail_on_binary_expression, catch_tail_on_function_call_no_try, try_catch_with_case_handler, try_propagate_without_catch, mutual_recursion.

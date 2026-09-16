# The decorator regression tests, and what they actually prove

`comptime/tests/decorator_regression.zig` has 4 passing tests. Passing says the decorator body
*evaluated*; it does not say the test would notice if the lowering it names broke. This is the one
unproven assertion left from 1.0.1-beta spec 01.

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/`; `codegen/erlang.zig`
line numbers are the same file the comptime-dispatch front cites.

## What each test actually lowers to

The generated comptime module is reachable without instrumenting the compiler: a `botopink check`
on a project whose `src/main.bp` carries the decorator leaves the script at
`.botopinkbuild/tmp/decorator/decorator_<hash>.erl`. Recorded from HEAD, with the noise (prelude,
`fail/2`, `main/0`) elided:

| Test | Emitted Erlang | Lowering, at HEAD |
|---|---|---|
| `loop in body` | `lists:foreach(fun(F) -> case (maps:get(name, F) =:= <<"bad">>) of true -> fail(Decl, <<"field 'bad' not allowed">>); _ -> ok end end, maps:get(fields, Decl))` | `codegen/erlang.zig:3908` — `arrayPrimFallbackNode`'s `forEach` arm (`lists:foreach/2`) |
| `conditional in body` | `case (maps:get(kind, Decl) =:= 'Record') of true -> case ('__bp_len'(maps:get(fields, Decl), len) > 5) of true -> fail(Decl, <<"too many fields">>); …` | `codegen/erlang.zig:3055` (`.len` → `'__bp_len'/2`) + `codegen/erlang.zig:406` (the `is_list` clause, `length(X)`) |
| `string concat in body` | `Msg = <<"invalid name: ">>, Msg@1 = '__bp_add'(Msg, maps:get(name, Decl)), case … fail(Decl, Msg@1)` | `codegen/erlang.zig:2060`–`2084` (`bindExpr`, the `Name@N` versioning) + `codegen/erlang.zig:390` (the `is_binary/is_binary` clause of `'__bp_add'/2`) |
| `@emit in body` | `emit('__bp_add'('__bp_add'(<<"pub fn helper_">>, maps:get(name, Decl)), <<"() -> i32 { return 42; }">>))` | `codegen/erlang.zig:3077` (`+` → `'__bp_add'/2` in the untyped path) + `codegen/erlang.zig:390` |

**Corrected:** `loop in body` does **not** exercise the `forEach` accumulator fusion
(`codegen/erlang.zig:2424` `detectFoldFusion`, called from `bodyNode:2403`, and
`codegen/erlang.zig:2479` `foldFusionExpr`). That path needs a `var acc = init;` statement
immediately before the `forEach`, and this decorator body has none, so it takes the plain
`lists:foreach/2` arm instead. **Nothing in the 4 tests reaches the fold fusion.**

## What the assertions permit

`assertRejects` (`comptime/tests/decorator_regression.zig:24`) requires `outcome == .typeError` and
matches the needle against `typeError.message()` with `std.mem.indexOf`, not against the rendered
report (the report quotes the source, where the expected text appears as a string literal).
`assertAccepts` (`:10`) requires `outcome == .ok`.

For all three rejecting tests the needle happens to be the *whole* message, so a garbled value
would be caught; what is not caught is a lowering that still arrives at the same message by a
different route.

## The two tests that already survive their mutation

| Test | Mutation | Why it stays green |
|---|---|---|
| `loop in body` | make `codegen/erlang.zig:3908` emit `lists:foreach(Action, [hd(Xs)])` — visit only the first element | the fixture is `record HasBad { bad: string, good: i32 }` and `bad` is the **first** field, so the one visited field is the one that fails |
| `conditional in body` | make the `is_list` clause of `'__bp_len'/2` (`codegen/erlang.zig:406`) return a constant `999` instead of `length(X)` | `999 > 5` is still true, so `decl.fail("too many fields")` still fires with the same message |

Both tests are blind to any mutation of their lowering that preserves a single bit: "the first
element is visited" / "the length is greater than five". That is the gap this front closes.

`string concat in body` and `@emit in body` are mutation-sensitive as written: dropping the
`is_binary`/`is_binary` clause of `'__bp_add'/2` makes `A + B` raise `badarith` on two binaries, and
the runtime reply changes from `{"kind":"fail",…}` to `{"kind":"error",…}` — in test 3 the needle is
gone, in test 4 `helper_Service` is never emitted and `useHelper` reds on an unbound name.

## Running one test

`zig build test -- --test-filter` is not forwarded in Zig 0.16, but `build.zig:110` exposes the
filter as a build option, so the mutation loop is

```sh
zig build test -Dtest-filter="decorator regression"
```

which cuts a full-suite cycle down to the 4 tests. The decorator evaluations spawn `erl`, so
`erl`/`erlc` must be on `PATH`. The loop is cheap: each decorator evaluation is one `erl` round trip
(~80 ms measured, plus ~130 ms for the first `erlc` of the session).

## The matrix

For each row, apply the mutation in a dirty working tree, run
`zig build test -Dtest-filter="decorator regression"`, record pass/fail, revert. The "expected"
column is the verdict this analysis predicts; a disagreement is itself a finding and belongs in the
front's notes.

| # | Test | Mutation | Site | Expected today |
|---|---|---|---|---|
| M1 | loop in body | `lists:foreach(A, Xs)` → `lists:foreach(A, [hd(Xs)])` | `codegen/erlang.zig:3908` | **passes** (blind) |
| M2 | loop in body | `"foreach"` → `"map"` | `codegen/erlang.zig:3908` | **passes** (blind) — `lists:map/2` still visits every element, so the decorator still throws |
| M3 | loop in body | receiver `maps:get(fields, …)` → an empty list | `codegen/erlang.zig:3908` (`this.exprNode(b, recv.*)`) | fails (`.ok`, not `.typeError`) |
| M4 | conditional in body | `is_list` clause body `length(X)` → `999` | `codegen/erlang.zig:406`–`411` | **passes** (blind) |
| M5 | conditional in body | drop the `is_list` clause, so a list falls through to `maps:get(Field, X)` | `codegen/erlang.zig:406` | fails (`badarg` → reply `kind=error`) |
| M6 | conditional in body | `.len` → `'__bp_len'/2` becomes a plain `maps:get` | `codegen/erlang.zig:3055` | fails |
| M7 | string concat in body | drop the `is_binary, is_binary` clause of `'__bp_add'/2` | `codegen/erlang.zig:390`–`404` | fails (`badarith`) |
| M8 | string concat in body | `bindExpr` reuses the bare name instead of `Name@N` | `codegen/erlang.zig:2071` | fails (`badmatch` on the second `Msg =`) |
| M9 | @emit in body | `'__bp_add'/2` binary clause emits `<<A/binary>>` (drops `B`) | `codegen/erlang.zig:390`–`398` | fails (`helper_Service` unbound) |
| M10 | @emit in body | the emitted body text `{ return 42; }` becomes `{ return 0; }` — simulated by rewriting the fixture's own literal | fixture | **passes** (blind: the test never observes the emitted value) |

## How to tighten the blind ones

Three of the four tests need a companion the mutation cannot satisfy. The rule: a rejecting fixture
proves the failure path; an **accepting** fixture over the *same decorator body* proves the lowering
computed a real value rather than a value that happens to trip the branch.

| Test | Add | Kills |
|---|---|---|
| loop in body | a second rejecting fixture whose offending field is **last** (`record HasBad { good: i32, bad: string }`), and an accepting fixture with no `bad` field at all | M1, M2 — a truncated or skipped iteration reds one of the two; a `forEach` that fails spuriously reds the third |
| conditional in body | an accepting fixture with 3 fields and a second with exactly 5 (the boundary `5 > 5` is false), keeping the 6-field rejection | M4 — no constant satisfies "> 5 for six fields and ≤ 5 for five"; an off-by-one in `length/1` reds the 5-field case |
| @emit in body | assert the emitted source text, not only that the module compiles — see below | M10 |
| string concat in body | change `assertRejects` to compare the whole message with `expectEqualStrings` | a future lowering that appends or truncates |

For `@emit in body` the emitted text is reachable without a new compiler hook. The accepting outcome
carries `OkData.comptime_traces` (`comptime.zig:108`), a
`[]const trace.Entry { kind, name, erl, reply }` (`comptime/trace.zig:13`), where `reply` is the
runtime's JSON — for this decorator,
`{"kind":"ok","contributions":["pub fn helper_Service() -> i32 { return 42; }"]}`. The test asserts
that string exactly. The same `erl` field gives the other three tests a lowering-shape assertion on
their **accepting** fixture (`lists:foreach(`, `'__bp_len'(`, `'__bp_add'(`), which is the "assert
on the generated Erlang" option; a rejecting fixture has no `OkData`, so this is only available on
the accepting side.

`.botopinkbuild/tmp/decorator/decorator_<hash>.erl` surviving a `botopink check` is the fastest way
to see what a decorator body lowered to; the same text is what `trace.Entry.erl` carries.

## The lowering no decorator test reaches

`detectFoldFusion` / `foldFusionExpr` (`codegen/erlang.zig:2424`, `:2479`) and the
mutation-through-a-closure case are the untyped comptime path's most intricate lowering, and no
decorator test reaches them. One test whose decorator body is
`var count = 0; decl.fields.forEach({ f -> count = count + 1; }); if (count > 5) { decl.fail(…) }`
lowers through `lists:foldl/3` and closes that, with the same accept/reject pair as the rows above.

The *fix* for mutation through a closure is the comptime-dispatch front's
([`../01-comptime-dispatch/closure-mutation.md`](../01-comptime-dispatch/closure-mutation.md)); the
test that proves the fold fusion is exercised at all is this front's, and it is worth adding whether
or not that fix lands, because the fusion is live today and untested.

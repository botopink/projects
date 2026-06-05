----- SOURCE CODE -- std/bool.bp
```botopink
//// Gleam-inspired `bool` module (`import {bool} from "std";`).
//// Pure-operator logic — no host backing, compiles once for every backend.
//// Function names follow the language convention: camelCase.
//// First real `"std"` package module (qualified calls lower to a per-module
//// output: `out/std/bool.js` / remote `bool:negate/1`).

pub fn negate(b: bool) -> bool {
    return !b;
}

pub fn nor(a: bool, b: bool) -> bool {
    return !(a || b);
}

pub fn nand(a: bool, b: bool) -> bool {
    return !(a && b);
}

pub fn exclusiveOr(a: bool, b: bool) -> bool {
    return a != b;
}

pub fn exclusiveNor(a: bool, b: bool) -> bool {
    return a == b;
}

// Zig-style co-located test (stdlib-tests F0: impl modules MAY carry inline
// `test` blocks; excluded from normal builds, run by `botopink test`).
test "inline: negate truth table" {
    assert negate(false);
    assert !negate(true);
}

```

----- ERLANG -- std/bool.erl
```erlang
-module(bool).
-export([negate/1, nor/2, nand/2, exclusiveOr/2, exclusiveNor/2]).

%%% Gleam-inspired `bool` module (`import {bool} from "std";`).

%%% Pure-operator logic — no host backing, compiles once for every backend.

%%% Function names follow the language convention: camelCase.

%%% First real `"std"` package module (qualified calls lower to a per-module

%%% output: `out/std/bool.js` / remote `bool:negate/1`).

negate(B) ->
    (not B).

nor(A, B) ->
    (not ((A or B))).

nand(A, B) ->
    (not ((A and B))).

exclusiveOr(A, B) ->
    (A =/= B).

exclusiveNor(A, B) ->
    (A =:= B).

% Zig-style co-located test (stdlib-tests F0: impl modules MAY carry inline

% `test` blocks; excluded from normal builds, run by `botopink test`).

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {bool} from "std";

fn main() {
    val flipped = bool.negate(false);
    @print(bool.exclusiveOr(flipped, false));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% import bool

main() ->
    Flipped = bool:negate(false),
    io:format("~p~n", [bool:exclusiveOr(Flipped, false)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
true
```

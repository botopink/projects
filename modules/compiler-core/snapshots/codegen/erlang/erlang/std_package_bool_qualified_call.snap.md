----- SOURCE CODE -- std/bool.bp
```botopink
//// Gleam-style `bool` module (`import {bool} from "std";`), inspired by
//// `gleam/bool`. Pure-operator logic — no host backing, compiles once for
//// every backend. First real `"std"` package module (qualified calls lower
//// to a per-module output: `out/std/bool.js` / remote `bool:negate/1`).

pub fn negate(b: bool) -> bool {
    return !b;
}

pub fn nor(a: bool, b: bool) -> bool {
    return !(a || b);
}

pub fn nand(a: bool, b: bool) -> bool {
    return !(a && b);
}

pub fn exclusive_or(a: bool, b: bool) -> bool {
    return a != b;
}

pub fn exclusive_nor(a: bool, b: bool) -> bool {
    return a == b;
}

```

----- ERLANG -- std/bool.erl
```erlang
-module(bool).
-export([negate/1, nor/2, nand/2, exclusive_or/2, exclusive_nor/2]).

%%% Gleam-style `bool` module (`import {bool} from "std";`), inspired by

%%% `gleam/bool`. Pure-operator logic — no host backing, compiles once for

%%% every backend. First real `"std"` package module (qualified calls lower

%%% to a per-module output: `out/std/bool.js` / remote `bool:negate/1`).

negate(B) ->
    (not B).

nor(A, B) ->
    (not ((A or B))).

nand(A, B) ->
    (not ((A and B))).

exclusive_or(A, B) ->
    (A =/= B).

exclusive_nor(A, B) ->
    (A =:= B).
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {bool} from "std";

fn main() {
    val flipped = bool.negate(false);
    @print(bool.exclusive_or(flipped, false));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% import bool

main() ->
    Flipped = bool:negate(false),
    io:format("~p~n", [bool:exclusive_or(Flipped, false)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
true
```

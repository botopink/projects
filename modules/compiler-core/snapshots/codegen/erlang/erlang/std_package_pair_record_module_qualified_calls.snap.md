----- SOURCE CODE -- std/pair.bp
```botopink
//// Gleam-style `pair` module (`import {pair} from "std";`), inspired by
//// `gleam/pair`. A pair IS a 2-tuple `#(a, b)` (same as Gleam) — structural,
//// so no generic-record instantiation is involved. Pure logic, compiles once
//// for every backend.

// NOTE: named `of` (not `new`) — `new` is a reserved keyword.
pub fn of<A, B>(first: A, second: B) -> #(A, B) {
    return #(first, second);
}

pub fn first<A, B>(p: #(A, B)) -> A {
    return p._0;
}

pub fn second<A, B>(p: #(A, B)) -> B {
    return p._1;
}

pub fn swap<A, B>(p: #(A, B)) -> #(B, A) {
    return #(p._1, p._0);
}

pub fn mapFirst<A, B, C>(p: #(A, B), transform: fn(value: A) -> C) -> #(C, B) {
    return #(transform(p._0), p._1);
}

pub fn mapSecond<A, B, C>(p: #(A, B), transform: fn(value: B) -> C) -> #(A, C) {
    return #(p._0, transform(p._1));
}

```

----- ERLANG -- std/pair.erl
```erlang
-module(pair).
-export([of/2, first/1, second/1, swap/1, mapFirst/2, mapSecond/2]).

%%% Gleam-style `pair` module (`import {pair} from "std";`), inspired by

%%% `gleam/pair`. A pair IS a 2-tuple `#(a, b)` (same as Gleam) — structural,

%%% so no generic-record instantiation is involved. Pure logic, compiles once

%%% for every backend.

% NOTE: named `of` (not `new`) — `new` is a reserved keyword.

of(First, Second) ->
    {First, Second}.

first(P) ->
    element(1, P).

second(P) ->
    element(2, P).

swap(P) ->
    {element(2, P), element(1, P)}.

mapFirst(P, Transform) ->
    {transform(element(1, P)), element(2, P)}.

mapSecond(P, Transform) ->
    {element(1, P), transform(element(2, P))}.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {pair} from "std";

fn main() {
    val p = pair.of(1, "one");
    val q = pair.swap(p);
    @print(pair.first(q));
    @print(pair.second(q));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% import pair

main() ->
    P = pair:of(1, <<"one">>),
    Q = pair:swap(P),
    io:format("~p~n", [pair:first(Q)]),
    io:format("~p~n", [pair:second(Q)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

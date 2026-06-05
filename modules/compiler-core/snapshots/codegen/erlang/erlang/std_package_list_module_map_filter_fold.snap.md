----- SOURCE CODE -- std/list.bp
```botopink
//// Gleam-style `list` module (`import {list} from "std";`), inspired by
//// `gleam/list`, built over the builtin `Array<T>`. Pure logic — transforms
//// delegate to the builtin Array methods; `fold` drives a mutable
//// accumulator through `forEach`.

pub fn length<T>(xs: Array<T>) -> i32 {
    return xs.length;
}

pub fn is_empty<T>(xs: Array<T>) -> bool {
    return xs.length == 0;
}

pub fn contains<T>(xs: Array<T>, x: T) -> bool {
    return xs.indexOf(x) != -1;
}

pub fn first<T>(xs: Array<T>) -> ?T {
    return xs.at(0);
}

pub fn rest<T>(xs: Array<T>) -> Array<T> {
    return xs.slice(1, xs.length);
}

pub fn take<T>(xs: Array<T>, n: i32) -> Array<T> {
    return xs.slice(0, n);
}

pub fn drop<T>(xs: Array<T>, n: i32) -> Array<T> {
    return xs.slice(n, xs.length);
}

pub fn reverse<T>(xs: Array<T>) -> Array<T> {
    return xs.reverse();
}

pub fn map<T, U>(xs: Array<T>, transform: fn(item: T) -> U) -> Array<U> {
    return xs.map(transform);
}

pub fn filter<T>(xs: Array<T>, keep: fn(item: T) -> bool) -> Array<T> {
    return xs.filter(keep);
}

pub fn fold<T, A>(xs: Array<T>, initial: A, f: fn(acc: A, item: T) -> A) -> A {
    var acc = initial;
    xs.forEach({ x -> acc = f(acc, x); });
    return acc;
}

pub fn all<T>(xs: Array<T>, pred: fn(item: T) -> bool) -> bool {
    return xs.filter(pred).length == xs.length;
}

pub fn any<T>(xs: Array<T>, pred: fn(item: T) -> bool) -> bool {
    return xs.filter(pred).length != 0;
}

```

----- ERLANG -- std/list.erl
```erlang
-module(list).
-export([length/1, is_empty/1, contains/2, first/1, rest/1, take/2, drop/2, reverse/1, map/2, filter/2, fold/3, all/2, any/2]).

%%% Gleam-style `list` module (`import {list} from "std";`), inspired by

%%% `gleam/list`, built over the builtin `Array<T>`. Pure logic — transforms

%%% delegate to the builtin Array methods; `fold` drives a mutable

%%% accumulator through `forEach`.

length(Xs) ->
    Xs_length.

is_empty(Xs) ->
    (Xs_length =:= 0).

contains(Xs, X) ->
    (Xs:indexOf(X) =/= (-1)).

first(Xs) ->
    Xs:at(0).

rest(Xs) ->
    Xs:slice(1, Xs_length).

take(Xs, N) ->
    Xs:slice(0, N).

drop(Xs, N) ->
    Xs:slice(N, Xs_length).

reverse(Xs) ->
    Xs:reverse().

map(Xs, Transform) ->
    Xs:map(Transform).

filter(Xs, Keep) ->
    Xs:filter(Keep).

fold(Xs, Initial, F) ->
    Acc = Initial,
    Xs:forEach(fun(X) ->
        Acc = f(Acc, X)
    end),
    Acc.

all(Xs, Pred) ->
    (Xs:filter(Pred)_length =:= Xs_length).

any(Xs, Pred) ->
    (Xs:filter(Pred)_length =/= 0).
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {list} from "std";

fn main() {
    val xs = [1, 2, 3, 4];
    val doubled = list.map(xs, { x -> x * 2 });
    @print(list.fold(doubled, 0, { acc, x -> acc + x }));
    @print(list.length(list.filter(xs, { x -> x > 2 })));
    @print(list.contains(xs, 3));
    @print(list.take(xs, 2).join(","));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% import list

main() ->
    Xs = [1, 2, 3, 4],
    Doubled = list:map(Xs, fun(X) ->
        (X * 2)
    end),
    io:format("~p~n", [list:fold(Doubled, 0, fun(Acc, X) ->
        (Acc + X)
    end)]),
    io:format("~p~n", [list:length(list:filter(Xs, fun(X) ->
        (X > 2)
    end))]),
    io:format("~p~n", [list:contains(Xs, 3)]),
    io:format("~p~n", [list:take(Xs, 2):join(<<",">>)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

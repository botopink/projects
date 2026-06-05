----- SOURCE CODE -- std/list.bp
```botopink
//// Gleam-inspired `list` module (`import {list} from "std";`), built over
//// the builtin `Array<T>`. Pure logic — transforms delegate to the builtin
//// Array methods; `fold` drives a mutable accumulator through `forEach`.
//// Function names follow the language convention: camelCase.

pub fn length<T>(xs: Array<T>) -> i32 {
    return xs.length;
}

pub fn isEmpty<T>(xs: Array<T>) -> bool {
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

pub fn find<T>(xs: Array<T>, pred: fn(item: T) -> bool) -> ?T {
    return xs.filter(pred).at(0);
}

pub fn count<T>(xs: Array<T>, pred: fn(item: T) -> bool) -> i32 {
    return xs.filter(pred).length;
}

pub fn append<T>(xs: Array<T>, ys: Array<T>) -> Array<T> {
    var out = [];  // no annotation — body `val: Array<T>` resolves T as a NAMED type (gap)
    xs.forEach({ x -> out.push(x); });
    ys.forEach({ y -> out.push(y); });
    return out;
}

pub fn prepend<T>(xs: Array<T>, x: T) -> Array<T> {
    var out = [x];
    xs.forEach({ item -> out.push(item); });
    return out;
}

// Helper (not exported): append every item of `xs` onto `out` in place.
// Kept top-level — nested trailing lambdas inside a lambda body do not
// parse yet (catalogued parser gap).
fn pushAll<T>(out: Array<T>, xs: Array<T>) {
    xs.forEach({ x -> out.push(x); });
}

// Inverted condition — a bare `return;` does not parse yet (catalogued
// parser gap), so the recursion guards by only descending while `start < stop`.
fn pushRange(out: Array<i32>, start: i32, stop: i32) {
    if (start < stop) {
        out.push(start);
        pushRange(out, start + 1, stop);
    };
}

pub fn flatten<T>(xss: Array<Array<T>>) -> Array<T> {
    var out = [];  // no annotation — body `val: Array<T>` resolves T as a NAMED type (gap)
    xss.forEach({ inner -> pushAll(out, inner); });
    return out;
}

// NOTE: the transform is typed `-> V` (a bare generic) — fn-type returns
// must be plain names (parser limit, same note as the old option module);
// `V` unifies with the produced `Array<U>` at the call site.
pub fn flatMap<T, U, V>(xs: Array<T>, transform: fn(item: T) -> V) -> Array<U> {
    return flatten(xs.map(transform));
}

// `range(start, stop)` — half-open `[start, stop)`. NOTE: params are not
// named `from`/`to` — `from` is a reserved keyword.
pub fn range(start: i32, stop: i32) -> Array<i32> {
    var out = [];
    pushRange(out, start, stop);
    return out;
}


```

----- ERLANG -- std/list.erl
```erlang
-module(list).
-export([length/1, isEmpty/1, contains/2, first/1, rest/1, take/2, drop/2, reverse/1, map/2, filter/2, fold/3, all/2, any/2, find/2, count/2, append/2, prepend/2, flatten/1, flatMap/2, range/2]).

%%% Gleam-inspired `list` module (`import {list} from "std";`), built over

%%% the builtin `Array<T>`. Pure logic — transforms delegate to the builtin

%%% Array methods; `fold` drives a mutable accumulator through `forEach`.

%%% Function names follow the language convention: camelCase.

length(Xs) ->
    maps:get(length, Xs).

isEmpty(Xs) ->
    (maps:get(length, Xs) =:= 0).

contains(Xs, X) ->
    (Xs:indexOf(X) =/= (-1)).

first(Xs) ->
    Xs:at(0).

rest(Xs) ->
    Xs:slice(1, maps:get(length, Xs)).

take(Xs, N) ->
    Xs:slice(0, N).

drop(Xs, N) ->
    Xs:slice(N, maps:get(length, Xs)).

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
    (maps:get(length, Xs:filter(Pred)) =:= maps:get(length, Xs)).

any(Xs, Pred) ->
    (maps:get(length, Xs:filter(Pred)) =/= 0).

find(Xs, Pred) ->
    Xs:filter(Pred):at(0).

count(Xs, Pred) ->
    maps:get(length, Xs:filter(Pred)).

append(Xs, Ys) ->
    Out = [],
    % no annotation — body `val: Array<T>` resolves T as a NAMED type (gap),
    Xs:forEach(fun(X) ->
        Out:push(X)
    end),
    Ys:forEach(fun(Y) ->
        Out:push(Y)
    end),
    Out.

prepend(Xs, X) ->
    Out = [X],
    Xs:forEach(fun(Item) ->
        Out:push(Item)
    end),
    Out.

% Helper (not exported): append every item of `xs` onto `out` in place.

% Kept top-level — nested trailing lambdas inside a lambda body do not

% parse yet (catalogued parser gap).

pushAll(Out, Xs) ->
    Xs:forEach(fun(X) ->
        Out:push(X)
    end).

% Inverted condition — a bare `return;` does not parse yet (catalogued

% parser gap), so the recursion guards by only descending while `start < stop`.

pushRange(Out, Start, Stop) ->
    case (Start < Stop) of
        true ->
            Out:push(Start),
            pushRange(Out, (Start + 1), Stop);
        _ -> ok
    end.

flatten(Xss) ->
    Out = [],
    % no annotation — body `val: Array<T>` resolves T as a NAMED type (gap),
    Xss:forEach(fun(Inner) ->
        pushAll(Out, Inner)
    end),
    Out.

% NOTE: the transform is typed `-> V` (a bare generic) — fn-type returns

% must be plain names (parser limit, same note as the old option module);

% `V` unifies with the produced `Array<U>` at the call site.

flatMap(Xs, Transform) ->
    flatten(Xs:map(Transform)).

% `range(start, stop)` — half-open `[start, stop)`. NOTE: params are not

% named `from`/`to` — `from` is a reserved keyword.

range(Start, Stop) ->
    Out = [],
    pushRange(Out, Start, Stop),
    Out.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {list} from "std";

fn main() {
    @print(list.range(1, 5).join(","));
    @print(list.append([1, 2], [3, 4]).join(","));
    @print(list.prepend([2, 3], 1).join(","));
    @print(list.flatten([[1, 2], [3]]).join(","));
    @print(list.count(list.range(0, 10), { x -> x > 6 }));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% import list

main() ->
    io:format("~p~n", [list:range(1, 5):join(<<",">>)]),
    io:format("~p~n", [list:append([1, 2], [3, 4]):join(<<",">>)]),
    io:format("~p~n", [list:prepend([2, 3], 1):join(<<",">>)]),
    io:format("~p~n", [list:flatten([[1, 2], [3]]):join(<<",">>)]),
    io:format("~p~n", [list:count(list:range(0, 10), fun(X) ->
        (X > 6)
    end)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

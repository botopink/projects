----- SOURCE CODE -- std/int.bp
```botopink
//// Integer utilities module (`import {int} from "std";`).
//// Pure-botopink math helpers for `i32` values. No host backing —
//// compiles once for every backend.
//// Function names follow the language convention: camelCase.

pub fn absoluteValue(n: i32) -> i32 {
    return if (n < 0) { -n; } else { n; };
}

pub fn min(a: i32, b: i32) -> i32 {
    return if (a < b) { a; } else { b; };
}

pub fn max(a: i32, b: i32) -> i32 {
    return if (a > b) { a; } else { b; };
}

pub fn clamp(n: i32, lo: i32, hi: i32) -> i32 {
    return min(max(n, lo), hi);
}

pub fn isEven(n: i32) -> bool {
    return n % 2 == 0;
}

pub fn isOdd(n: i32) -> bool {
    return n % 2 != 0;
}

// NOTE: `to_string` (convert integer to its decimal string representation).
// Botopink coerces numbers to string in `+` contexts — `"" + n` works.
pub fn toString(n: i32) -> string {
    return "" + n;
}

test "inline: absoluteValue" {
    assert absoluteValue(0) == 0;
    assert absoluteValue(3) == 3;
}

test "inline: min and max" {
    assert min(2, 5) == 2;
    assert max(2, 5) == 5;
}

test "inline: clamp in range" {
    assert clamp(3, 0, 5) == 3;
}

test "inline: isEven" {
    assert isEven(4);
    assert !isEven(3);
}

test "inline: isOdd" {
    assert isOdd(7);
    assert !isOdd(8);
}

```

----- ERLANG -- std/int.erl
```erlang
-module(int).
-export([absoluteValue/1, min/2, max/2, clamp/3, isEven/1, isOdd/1, toString/1]).

%%% Integer utilities module (`import {int} from "std";`).

%%% Pure-botopink math helpers for `i32` values. No host backing —

%%% compiles once for every backend.

%%% Function names follow the language convention: camelCase.

absoluteValue(N) ->
    case (N < 0) of
        true ->
            (-N);
        false ->
            N
    end.

min(A, B) ->
    case (A < B) of
        true ->
            A;
        false ->
            B
    end.

max(A, B) ->
    case (A > B) of
        true ->
            A;
        false ->
            B
    end.

clamp(N, Lo, Hi) ->
    min(max(N, Lo), Hi).

isEven(N) ->
    ((N rem 2) =:= 0).

isOdd(N) ->
    ((N rem 2) =/= 0).

% NOTE: `to_string` (convert integer to its decimal string representation).

% Botopink coerces numbers to string in `+` contexts — `"" + n` works.

toString(N) ->
    (<<"">> + N).





```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {int} from "std";

fn main() {
    @print(int.absoluteValue(5));
    @print(int.min(3, 7));
    @print(int.max(3, 7));
    @print(int.clamp(10, 0, 5));
    @print(int.isEven(4));
    @print(int.isOdd(3));
    @print(int.toString(42));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% import int

main() ->
    io:format("~p~n", [int:absoluteValue(5)]),
    io:format("~p~n", [int:min(3, 7)]),
    io:format("~p~n", [int:max(3, 7)]),
    io:format("~p~n", [int:clamp(10, 0, 5)]),
    io:format("~p~n", [int:isEven(4)]),
    io:format("~p~n", [int:isOdd(3)]),
    io:format("~p~n", [int:toString(42)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

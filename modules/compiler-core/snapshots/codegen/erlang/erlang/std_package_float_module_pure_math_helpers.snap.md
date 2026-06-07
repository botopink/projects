----- SOURCE CODE -- std/float.bp
```botopink
//// Float utilities module (`import {float} from "std";`).
//// Math helpers for `f64` values. Host-backed for rounding primitives.
//// Function names follow the language convention: camelCase.

pub fn absoluteValue(n: f64) -> f64 {
    return if (n < 0.0) { -n; } else { n; };
}

pub fn min(a: f64, b: f64) -> f64 {
    return if (a < b) { a; } else { b; };
}

pub fn max(a: f64, b: f64) -> f64 {
    return if (a > b) { a; } else { b; };
}

pub fn clamp(n: f64, lo: f64, hi: f64) -> f64 {
    return min(max(n, lo), hi);
}

#[@external(erlang, "math", "floor"),
  @external(node, "Math", "floor")]
pub declare fn floor(n: f64) -> f64;

#[@external(erlang, "math", "ceil"),
  @external(node, "Math", "ceil")]
pub declare fn ceiling(n: f64) -> f64;

#[@external(erlang, "math", "round"),
  @external(node, "Math", "round")]
pub declare fn round(n: f64) -> f64;

#[@external(erlang, "math", "sqrt"),
  @external(node, "Math", "sqrt")]
pub declare fn squareRoot(n: f64) -> f64;

// NOTE: `toString` for floats — coerces via string concat.
pub fn toString(n: f64) -> string {
    return "" + n;
}

test "float absoluteValue" {
    assert absoluteValue(0.0) == 0.0;
    assert absoluteValue(-3.5) == 3.5;
    assert absoluteValue(2.1) == 2.1;
}

test "float min and max" {
    assert min(1.5, 2.5) == 1.5;
    assert max(1.5, 2.5) == 2.5;
}

test "float clamp" {
    assert clamp(3.0, 0.0, 5.0) == 3.0;
    assert clamp(-1.0, 0.0, 5.0) == 0.0;
    assert clamp(9.9, 0.0, 5.0) == 5.0;
}

test "float toString" {
    assert toString(1.5) == "1.5";
}

```

----- ERLANG -- std/float.erl
```erlang
-module(float).
-export([absoluteValue/1, min/2, max/2, clamp/3, toString/1]).

%%% Float utilities module (`import {float} from "std";`).

%%% Math helpers for `f64` values. Host-backed for rounding primitives.

%%% Function names follow the language convention: camelCase.

absoluteValue(N) ->
    case (N < 0.0) of
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

%% external fn floor -> math:floor

%% external fn ceiling -> math:ceil

%% external fn round -> math:round

%% external fn squareRoot -> math:sqrt

% NOTE: `toString` for floats — coerces via string concat.

toString(N) ->
    (<<"">> + N).




```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {float} from "std";

fn main() {
    @print(float.absoluteValue(2.5));
    @print(float.min(1.5, 2.5));
    @print(float.max(1.5, 2.5));
    @print(float.clamp(3.0, 0.0, 5.0));
    @print(float.toString(3.14));
    @print(float.floor(2.9));
    @print(float.ceiling(2.1));
    @print(float.round(2.5));
    @print(float.squareRoot(9.0));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% import float

main() ->
    io:format("~p~n", [float:absoluteValue(2.5)]),
    io:format("~p~n", [float:min(1.5, 2.5)]),
    io:format("~p~n", [float:max(1.5, 2.5)]),
    io:format("~p~n", [float:clamp(3.0, 0.0, 5.0)]),
    io:format("~p~n", [float:toString(3.14)]),
    io:format("~p~n", [float:floor(2.9)]),
    io:format("~p~n", [float:ceiling(2.1)]),
    io:format("~p~n", [float:round(2.5)]),
    io:format("~p~n", [float:squareRoot(9.0)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

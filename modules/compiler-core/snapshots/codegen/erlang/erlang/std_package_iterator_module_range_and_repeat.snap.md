----- SOURCE CODE -- std/iterator.bp
```botopink
//// Lazy iterator utilities module (`import {iterator} from "std";`).
//// Built on botopink's `*fn` / `@Iterator<T>` generator mechanism.
//// Function names follow the language convention: camelCase.
////
//// NOTE: higher-order ops (map/filter/fold) require consuming an iterator
//// via `loop (iter) { ... }` which is the iteration form in botopink.
//// Use the `list` module for eager transforms on arrays.

// Internal recursive helper: yields integers [cur, stop).
*fn doRange(cur: i32, stop: i32) -> @Iterator<i32> {
    if (cur < stop) {
        yield cur;
        return doRange(cur + 1, stop);
    };
}

// `range(start, stop)` — half-open `[start, stop)`, yields lazily.
pub *fn range(start: i32, stop: i32) -> @Iterator<i32> {
    return doRange(start, stop);
}

// `repeat(value, times)` — yields `value` exactly `times` times, lazily.
*fn doRepeat<T>(value: T, remaining: i32) -> @Iterator<T> {
    if (remaining > 0) {
        yield value;
        return doRepeat(value, remaining - 1);
    };
}

pub *fn repeat<T>(value: T, times: i32) -> @Iterator<T> {
    return doRepeat(value, times);
}

```

----- ERLANG -- std/iterator.erl
```erlang
-module(iterator).
-export([range/2, repeat/2]).

%%% Lazy iterator utilities module (`import {iterator} from "std";`).

%%% Built on botopink's `*fn` / `@Iterator<T>` generator mechanism.

%%% Function names follow the language convention: camelCase.

%%% 

%%% NOTE: higher-order ops (map/filter/fold) require consuming an iterator

%%% via `loop (iter) { ... }` which is the iteration form in botopink.

%%% Use the `list` module for eager transforms on arrays.

% Internal recursive helper: yields integers [cur, stop).

%% *fn (async/generator) — eager lowering
doRange(Cur, Stop) ->
    case (Cur < Stop) of
        true ->
            Cur,
            doRange((Cur + 1), Stop);
        _ -> ok
    end.

% `range(start, stop)` — half-open `[start, stop)`, yields lazily.

%% *fn (async/generator) — eager lowering
range(Start, Stop) ->
    doRange(Start, Stop).

% `repeat(value, times)` — yields `value` exactly `times` times, lazily.

%% *fn (async/generator) — eager lowering
doRepeat(Value, Remaining) ->
    case (Remaining > 0) of
        true ->
            Value,
            doRepeat(Value, (Remaining - 1));
        _ -> ok
    end.

%% *fn (async/generator) — eager lowering
repeat(Value, Times) ->
    doRepeat(Value, Times).
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {iterator} from "std";

fn main() {
    val gen = iterator.range(0, 3);
    val gen2 = iterator.repeat(42, 2);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% import iterator

main() ->
    Gen = iterator:range(0, 3),
    Gen2 = iterator:repeat(42, 2).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

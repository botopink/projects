----- SOURCE CODE -- std/iterator.bp
```botopink
//// Lazy iterator utilities module (`import {iterator} from "std";`).
//// Built on botopink's `*fn` / `@Iterator<T>` generator mechanism.
//// Function names follow the language convention: camelCase.
////
//// Lazy producers: range, repeat, fromList.
//// Eager consumers (return Array): map, filter, take, toList.
//// Pure fold: fold.
////
//// NOTE: `fromList` is a `*fn` generator; the JS codegen emits `.map()`
//// for `loop { yield }` bodies, which is broken for non-Array iterables.
//// Known gap — tracked in TODO.md. Use `loop (array) { … }` directly.

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

// `fromList(xs)` — wrap an Array as a lazy @Iterator<T>.
// NOTE: JS codegen converts loop+yield to .map(); the generator yields
// nothing at runtime. Use `loop (array) { item -> … }` for eager iteration.
pub *fn fromList<T>(xs: Array<T>) -> @Iterator<T> {
    loop (xs) { item ->
        yield item;
    };
}

// `toList(iter)` — eagerly collect an @Iterator<T> into Array<T>.
pub fn toList<T>(iter: @Iterator<T>) -> Array<T> {
    var out = [];
    loop (iter) { item ->
        out.push(item);
    };
    return out;
}

// `fold(iter, initial, f)` — reduce an iterator to a single accumulator value.
pub fn fold<T, A>(iter: @Iterator<T>, initial: A, f: fn(acc: A, item: T) -> A) -> A {
    var acc = initial;
    loop (iter) { item ->
        acc = f(acc, item);
    };
    return acc;
}

// `map(iter, f)` — apply `f` to each item, return eager Array<U>.
pub fn map<T, U>(iter: @Iterator<T>, f: fn(item: T) -> U) -> Array<U> {
    var out = [];
    loop (iter) { item ->
        val v = f(item);
        out.push(v);
    };
    return out;
}

// `filter(iter, pred)` — keep items matching `pred`, return eager Array<T>.
pub fn filter<T>(iter: @Iterator<T>, pred: fn(item: T) -> bool) -> Array<T> {
    var out = [];
    loop (iter) { item ->
        if (pred(item)) { out.push(item); };
    };
    return out;
}

// `take(iter, n)` — first n items as eager Array<T>.
pub fn take<T>(iter: @Iterator<T>, n: i32) -> Array<T> {
    var out = [];
    var count = 0;
    loop (iter) { item ->
        if (count < n) { out.push(item); };
        count = count + 1;
    };
    return out;
}

```

----- ERLANG -- std/iterator.erl
```erlang
-module(iterator).
-export([range/2, repeat/2, fromList/1, toList/1, fold/3, map/2, filter/2, take/2]).

%%% Lazy iterator utilities module (`import {iterator} from "std";`).

%%% Built on botopink's `*fn` / `@Iterator<T>` generator mechanism.

%%% Function names follow the language convention: camelCase.

%%% 

%%% Lazy producers: range, repeat, fromList.

%%% Eager consumers (return Array): map, filter, take, toList.

%%% Pure fold: fold.

%%% 

%%% NOTE: `fromList` is a `*fn` generator; the JS codegen emits `.map()`

%%% for `loop { yield }` bodies, which is broken for non-Array iterables.

%%% Known gap — tracked in TODO.md. Use `loop (array) { … }` directly.

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

% `fromList(xs)` — wrap an Array as a lazy @Iterator<T>.

% NOTE: JS codegen converts loop+yield to .map(); the generator yields

% nothing at runtime. Use `loop (array) { item -> … }` for eager iteration.

%% *fn (async/generator) — eager lowering
fromList(Xs) ->
    lists:map(fun(Item) ->
        Item
    end, Xs).

% `toList(iter)` — eagerly collect an @Iterator<T> into Array<T>.

toList(Iter) ->
    Out = [],
    lists:foreach(fun(Item) ->
        Out:push(Item)
    end, Iter),
    Out.

% `fold(iter, initial, f)` — reduce an iterator to a single accumulator value.

fold(Iter, Initial, F) ->
    Acc = Initial,
    lists:foreach(fun(Item) ->
        Acc = f(Acc, Item)
    end, Iter),
    Acc.

% `map(iter, f)` — apply `f` to each item, return eager Array<U>.

map(Iter, F) ->
    Out = [],
    lists:foreach(fun(Item) ->
        V = f(Item),
        Out:push(V)
    end, Iter),
    Out.

% `filter(iter, pred)` — keep items matching `pred`, return eager Array<T>.

filter(Iter, Pred) ->
    Out = [],
    lists:foreach(fun(Item) ->
        case pred(Item) of
            true ->
                Out:push(Item);
            _ -> ok
        end
    end, Iter),
    Out.

% `take(iter, n)` — first n items as eager Array<T>.

take(Iter, N) ->
    Out = [],
    Count = 0,
    lists:foreach(fun(Item) ->
        case (Count < N) of
            true ->
                Out:push(Item);
            _ -> ok
        end,
        Count = (Count + 1)
    end, Iter),
    Out.
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

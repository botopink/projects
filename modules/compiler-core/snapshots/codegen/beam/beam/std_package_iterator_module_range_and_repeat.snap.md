----- SOURCE CODE -- std/iterator.bp
```botopink
//// Lazy iterator utilities module (`import {iterator} from "std";`).
//// Built on botopink's `*fn` / `@Iterator<T>` generator mechanism.
//// Function names follow the language convention: camelCase.
////
//// Lazy producers: range, repeat, fromList.
//// Eager consumers (return Array): map, filter, take, toList.
//// Pure fold: fold.

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

----- BEAM ASSEMBLY -- std/iterator.S
```erlang
{module, std/iterator}.
{exports, [{range, 2}, {repeat, 2}, {fromList, 1}, {toList, 1}, {fold, 3}, {map, 2}, {filter, 2}, {take, 2}]}.
{attributes, []}.
{labels, 40}.
%%% Lazy iterator utilities module (`import {iterator} from "std";`).
%%% Built on botopink's `*fn` / `@Iterator<T>` generator mechanism.
%%% Function names follow the language convention: camelCase.
%%% 
%%% Lazy producers: range, repeat, fromList.
%%% Eager consumers (return Array): map, filter, take, toList.
%%% Pure fold: fold.
% Internal recursive helper: yields integers [cur, stop).

%% *fn (async/generator) — eager lowering
{function, doRange, 2, 3}.
  {label, 2}.
    {line, [{location, "std/iterator.erl", 1}]}.
    {func_info, {atom, std/iterator}, {atom, doRange}, 2}.
  {label, 3}.
    {allocate, 0, 2}.
    {test, is_lt, {f, 22}, [{x, 0}, {x, 1}]}.
    {deallocate, 0}.
    return.
    {gc_bif, '+', {f, 0}, 2, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {x, 3}, {x, 1}}.
    {call_last, 2, {f, 3}, 0}.
  {label, 22}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 0}.
    return.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.
% `range(start, stop)` — half-open `[start, stop)`, yields lazily.

%% *fn (async/generator) — eager lowering
{function, range, 2, 5}.
  {label, 4}.
    {line, [{location, "std/iterator.erl", 2}]}.
    {func_info, {atom, std/iterator}, {atom, range}, 2}.
  {label, 5}.
    {allocate, 0, 2}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    {call_last, 2, {f, 3}, 0}.
% `repeat(value, times)` — yields `value` exactly `times` times, lazily.

%% *fn (async/generator) — eager lowering
{function, doRepeat, 2, 7}.
  {label, 6}.
    {line, [{location, "std/iterator.erl", 3}]}.
    {func_info, {atom, std/iterator}, {atom, doRepeat}, 2}.
  {label, 7}.
    {allocate, 0, 2}.
    {test, is_lt, {f, 23}, [{integer, 0}, {x, 1}]}.
    {deallocate, 0}.
    return.
    {move, {x, 0}, {x, 2}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 1}, {integer, 1}], {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {x, 3}, {x, 1}}.
    {call_last, 2, {f, 7}, 0}.
  {label, 23}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 0}.
    return.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

%% *fn (async/generator) — eager lowering
{function, repeat, 2, 9}.
  {label, 8}.
    {line, [{location, "std/iterator.erl", 4}]}.
    {func_info, {atom, std/iterator}, {atom, repeat}, 2}.
  {label, 9}.
    {allocate, 0, 2}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    {call_last, 2, {f, 7}, 0}.
% `fromList(xs)` — wrap an Array as a lazy @Iterator<T>.

%% *fn (async/generator) — eager lowering
{function, fromList, 1, 11}.
  {label, 10}.
    {line, [{location, "std/iterator.erl", 5}]}.
    {func_info, {atom, std/iterator}, {atom, fromList}, 1}.
  {label, 11}.
    {allocate, 0, 1}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 1}.
    {make_fun3, {f, 25}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.
% `toList(iter)` — eagerly collect an @Iterator<T> into Array<T>.

{function, toList, 1, 13}.
  {label, 12}.
    {line, [{location, "std/iterator.erl", 6}]}.
    {func_info, {atom, std/iterator}, {atom, toList}, 1}.
  {label, 13}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 1}.
    {make_fun3, {f, 27}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
% `fold(iter, initial, f)` — reduce an iterator to a single accumulator value.

{function, fold, 3, 15}.
  {label, 14}.
    {line, [{location, "std/iterator.erl", 7}]}.
    {func_info, {atom, std/iterator}, {atom, fold}, 3}.
  {label, 15}.
    {allocate, 1, 3}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 29}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 3}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
% `map(iter, f)` — apply `f` to each item, return eager Array<U>.

{function, map, 2, 17}.
  {label, 16}.
    {line, [{location, "std/iterator.erl", 8}]}.
    {func_info, {atom, std/iterator}, {atom, map}, 2}.
  {label, 17}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 31}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
% `filter(iter, pred)` — keep items matching `pred`, return eager Array<T>.

{function, filter, 2, 19}.
  {label, 18}.
    {line, [{location, "std/iterator.erl", 9}]}.
    {func_info, {atom, std/iterator}, {atom, filter}, 2}.
  {label, 19}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 33}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
% `take(iter, n)` — first n items as eager Array<T>.

{function, take, 2, 21}.
  {label, 20}.
    {line, [{location, "std/iterator.erl", 10}]}.
    {func_info, {atom, std/iterator}, {atom, take}, 2}.
  {label, 21}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 37}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-fromList/1-fun-0-', 1, 25}.
  {label, 24}.
    {line, [{location, "std/iterator.erl", 6}]}.
    {func_info, {atom, std/iterator}, {atom, '-fromList/1-fun-0-'}, 1}.
  {label, 25}.
    {allocate, 0, 1}.
    {deallocate, 0}.
    return.

{function, '-toList/1-fun-1-', 1, 27}.
  {label, 26}.
    {line, [{location, "std/iterator.erl", 7}]}.
    {func_info, {atom, std/iterator}, {atom, '-toList/1-fun-1-'}, 1}.
  {label, 27}.
    {allocate, 0, 1}.
    {move, {atom, out}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    %% unresolved method call: push/2
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '-fold/3-fun-2-', 1, 29}.
  {label, 28}.
    {line, [{location, "std/iterator.erl", 8}]}.
    {func_info, {atom, std/iterator}, {atom, '-fold/3-fun-2-'}, 1}.
  {label, 29}.
    {allocate, 0, 1}.
    %% assign to unknown variable: acc
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '-map/2-fun-3-', 1, 31}.
  {label, 30}.
    {line, [{location, "std/iterator.erl", 9}]}.
    {func_info, {atom, std/iterator}, {atom, '-map/2-fun-3-'}, 1}.
  {label, 31}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {x, 0}}.
    %% unresolved local call: f/1
    {move, {x, 0}, {y, 0}}.
    {move, {atom, out}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    %% unresolved method call: push/2
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '-filter/2-fun-4-', 1, 33}.
  {label, 32}.
    {line, [{location, "std/iterator.erl", 10}]}.
    {func_info, {atom, std/iterator}, {atom, '-filter/2-fun-4-'}, 1}.
  {label, 33}.
    {allocate, 0, 1}.
    {move, {x, 0}, {x, 0}}.
    %% unresolved local call: pred/1
    {test, is_eq, {f, 34}, [{x, 0}, {atom, true}]}.
    {move, {atom, out}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    %% unresolved method call: push/2
    {jump, {f, 35}}.
  {label, 34}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 0}.
    return.
  {label, 35}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '-take/2-fun-5-', 1, 37}.
  {label, 36}.
    {line, [{location, "std/iterator.erl", 11}]}.
    {func_info, {atom, std/iterator}, {atom, '-take/2-fun-5-'}, 1}.
  {label, 37}.
    {allocate, 0, 1}.
    {move, {atom, count}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, n}, {x, 0}}.
    {test, is_lt, {f, 38}, [{x, 1}, {x, 0}]}.
    {move, {atom, out}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    %% unresolved method call: push/2
    {jump, {f, 39}}.
  {label, 38}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 0}.
    return.
  {label, 39}.
    %% assign to unknown variable: count
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
Execution error: error.FileNotFound```

----- SOURCE CODE -- main.bp
```botopink
import {iterator} from "std";

fn main() {
    val gen = iterator.range(0, 3);
    val gen2 = iterator.repeat(42, 2);
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 8}.

{function, main, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 3}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {atom, iterator}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    {move, {x, 2}, {x, 2}}.
    %% unresolved method call: range/3
    {move, {x, 0}, {y, 0}}.
    {move, {atom, iterator}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {integer, 42}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    {move, {x, 2}, {x, 2}}.
    %% unresolved method call: repeat/3
    {move, {x, 0}, {y, 1}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '_botopink_main', 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '_botopink_main'}, 0}.
  {label, 5}.
    {call_only, 0, {f, 3}}.

{function, main, 1, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, main}, 1}.
  {label, 7}.
    {call_only, 0, {f, 5}}.
```

----- RUN LOG -----
```logs
```

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

----- BEAM ASSEMBLY -- std/list.S
```erlang
{module, std/list}.
{exports, [{length, 1}, {isEmpty, 1}, {contains, 2}, {first, 1}, {rest, 1}, {take, 2}, {drop, 2}, {reverse, 1}, {map, 2}, {filter, 2}, {fold, 3}, {all, 2}, {any, 2}, {find, 2}, {count, 2}, {append, 2}, {prepend, 2}, {flatten, 1}, {flatMap, 2}, {range, 2}]}.
{attributes, []}.
{labels, 76}.
%%% Gleam-inspired `list` module (`import {list} from "std";`), built over
%%% the builtin `Array<T>`. Pure logic — transforms delegate to the builtin
%%% Array methods; `fold` drives a mutable accumulator through `forEach`.
%%% Function names follow the language convention: camelCase.

{function, length, 1, 3}.
  {label, 2}.
    {line, [{location, "std/list.erl", 1}]}.
    {func_info, {atom, std/list}, {atom, length}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {get_map_elements, {f, 46}, {x, 0}, {list, [{atom, length}, {x, 0}]}}.
  {label, 46}.
    {deallocate, 0}.
    return.

{function, isEmpty, 1, 5}.
  {label, 4}.
    {line, [{location, "std/list.erl", 2}]}.
    {func_info, {atom, std/list}, {atom, isEmpty}, 1}.
  {label, 5}.
    {allocate, 0, 1}.
    {get_map_elements, {f, 47}, {x, 0}, {list, [{atom, length}, {x, 0}]}}.
  {label, 47}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 48}, [{x, 1}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 49}}.
  {label, 48}.
    {move, {atom, false}, {x, 0}}.
  {label, 49}.
    {deallocate, 0}.
    return.

{function, contains, 2, 7}.
  {label, 6}.
    {line, [{location, "std/list.erl", 3}]}.
    {func_info, {atom, std/list}, {atom, contains}, 2}.
  {label, 7}.
    {allocate, 0, 2}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {x, 3}, {x, 1}}.
    %% unresolved method call: indexOf/2
    {move, {x, 0}, {x, 2}}.
    {test, is_ne_exact, {f, 50}, [{x, 2}, {integer, -1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 51}}.
  {label, 50}.
    {move, {atom, false}, {x, 0}}.
  {label, 51}.
    {deallocate, 0}.
    return.

{function, first, 1, 9}.
  {label, 8}.
    {line, [{location, "std/list.erl", 4}]}.
    {func_info, {atom, std/list}, {atom, first}, 1}.
  {label, 9}.
    {allocate, 0, 1}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    %% unresolved method call: at/2
    {deallocate, 0}.
    return.

{function, rest, 1, 11}.
  {label, 10}.
    {line, [{location, "std/list.erl", 5}]}.
    {func_info, {atom, std/list}, {atom, rest}, 1}.
  {label, 11}.
    {allocate, 0, 1}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {get_map_elements, {f, 52}, {x, 0}, {list, [{atom, length}, {x, 0}]}}.
  {label, 52}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 3}, {x, 2}}.
    %% unresolved method call: slice/3
    {deallocate, 0}.
    return.

{function, take, 2, 13}.
  {label, 12}.
    {line, [{location, "std/list.erl", 6}]}.
    {func_info, {atom, std/list}, {atom, take}, 2}.
  {label, 13}.
    {allocate, 0, 2}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 4}}.
    {move, {x, 2}, {x, 0}}.
    {move, {x, 3}, {x, 1}}.
    {move, {x, 4}, {x, 2}}.
    %% unresolved method call: slice/3
    {deallocate, 0}.
    return.

{function, drop, 2, 15}.
  {label, 14}.
    {line, [{location, "std/list.erl", 7}]}.
    {func_info, {atom, std/list}, {atom, drop}, 2}.
  {label, 15}.
    {allocate, 0, 2}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {get_map_elements, {f, 53}, {x, 0}, {list, [{atom, length}, {x, 0}]}}.
  {label, 53}.
    {move, {x, 0}, {x, 4}}.
    {move, {x, 2}, {x, 0}}.
    {move, {x, 3}, {x, 1}}.
    {move, {x, 4}, {x, 2}}.
    %% unresolved method call: slice/3
    {deallocate, 0}.
    return.

{function, reverse, 1, 17}.
  {label, 16}.
    {line, [{location, "std/list.erl", 8}]}.
    {func_info, {atom, std/list}, {atom, reverse}, 1}.
  {label, 17}.
    {allocate, 0, 1}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 1}, {x, 0}}.
    {call_last, 1, {f, 17}, 0}.

{function, map, 2, 19}.
  {label, 18}.
    {line, [{location, "std/list.erl", 9}]}.
    {func_info, {atom, std/list}, {atom, map}, 2}.
  {label, 19}.
    {allocate, 0, 2}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {x, 3}, {x, 1}}.
    {call_last, 2, {f, 19}, 0}.

{function, filter, 2, 21}.
  {label, 20}.
    {line, [{location, "std/list.erl", 10}]}.
    {func_info, {atom, std/list}, {atom, filter}, 2}.
  {label, 21}.
    {allocate, 0, 2}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {x, 3}, {x, 1}}.
    {call_last, 2, {f, 21}, 0}.

{function, fold, 3, 23}.
  {label, 22}.
    {line, [{location, "std/list.erl", 11}]}.
    {func_info, {atom, std/list}, {atom, fold}, 3}.
  {label, 23}.
    {allocate, 1, 3}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 55}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 4}}.
    {move, {x, 3}, {x, 0}}.
    {move, {x, 4}, {x, 1}}.
    %% unresolved method call: forEach/2
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, all, 2, 25}.
  {label, 24}.
    {line, [{location, "std/list.erl", 12}]}.
    {func_info, {atom, std/list}, {atom, all}, 2}.
  {label, 25}.
    {allocate, 0, 2}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {x, 3}, {x, 1}}.
    {call, 2, {f, 21}}.
    {get_map_elements, {f, 56}, {x, 0}, {list, [{atom, length}, {x, 0}]}}.
  {label, 56}.
    {move, {x, 0}, {x, 2}}.
    {get_map_elements, {f, 57}, {x, 0}, {list, [{atom, length}, {x, 0}]}}.
  {label, 57}.
    {test, is_eq, {f, 58}, [{x, 2}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 59}}.
  {label, 58}.
    {move, {atom, false}, {x, 0}}.
  {label, 59}.
    {deallocate, 0}.
    return.

{function, any, 2, 27}.
  {label, 26}.
    {line, [{location, "std/list.erl", 13}]}.
    {func_info, {atom, std/list}, {atom, any}, 2}.
  {label, 27}.
    {allocate, 0, 2}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {x, 3}, {x, 1}}.
    {call, 2, {f, 21}}.
    {get_map_elements, {f, 60}, {x, 0}, {list, [{atom, length}, {x, 0}]}}.
  {label, 60}.
    {move, {x, 0}, {x, 2}}.
    {test, is_ne_exact, {f, 61}, [{x, 2}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 62}}.
  {label, 61}.
    {move, {atom, false}, {x, 0}}.
  {label, 62}.
    {deallocate, 0}.
    return.

{function, find, 2, 29}.
  {label, 28}.
    {line, [{location, "std/list.erl", 14}]}.
    {func_info, {atom, std/list}, {atom, find}, 2}.
  {label, 29}.
    {allocate, 0, 2}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {x, 3}, {x, 1}}.
    {call, 2, {f, 21}}.
    {move, {x, 0}, {x, 2}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {x, 3}, {x, 1}}.
    %% unresolved method call: at/2
    {deallocate, 0}.
    return.

{function, count, 2, 31}.
  {label, 30}.
    {line, [{location, "std/list.erl", 15}]}.
    {func_info, {atom, std/list}, {atom, count}, 2}.
  {label, 31}.
    {allocate, 0, 2}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {x, 3}, {x, 1}}.
    {call, 2, {f, 21}}.
    {get_map_elements, {f, 63}, {x, 0}, {list, [{atom, length}, {x, 0}]}}.
  {label, 63}.
    {deallocate, 0}.
    return.

{function, append, 2, 33}.
  {label, 32}.
    {line, [{location, "std/list.erl", 16}]}.
    {func_info, {atom, std/list}, {atom, append}, 2}.
  {label, 33}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 65}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {x, 3}, {x, 1}}.
    %% unresolved method call: forEach/2
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 67}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {x, 3}, {x, 1}}.
    %% unresolved method call: forEach/2
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, prepend, 2, 35}.
  {label, 34}.
    {line, [{location, "std/list.erl", 17}]}.
    {func_info, {atom, std/list}, {atom, prepend}, 2}.
  {label, 35}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, nil, {x, 0}}.
    {test_heap, 2, 3}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 69}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {x, 3}, {x, 1}}.
    %% unresolved method call: forEach/2
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
% Helper (not exported): append every item of `xs` onto `out` in place.
% Kept top-level — nested trailing lambdas inside a lambda body do not
% parse yet (catalogued parser gap).

{function, pushAll, 2, 37}.
  {label, 36}.
    {line, [{location, "std/list.erl", 18}]}.
    {func_info, {atom, std/list}, {atom, pushAll}, 2}.
  {label, 37}.
    {allocate, 0, 2}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 71}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {x, 3}, {x, 1}}.
    %% unresolved method call: forEach/2
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.
% Inverted condition — a bare `return;` does not parse yet (catalogued
% parser gap), so the recursion guards by only descending while `start < stop`.

{function, pushRange, 3, 39}.
  {label, 38}.
    {line, [{location, "std/list.erl", 19}]}.
    {func_info, {atom, std/list}, {atom, pushRange}, 3}.
  {label, 39}.
    {allocate, 0, 3}.
    {test, is_lt, {f, 72}, [{x, 1}, {x, 2}]}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 4}}.
    {move, {x, 3}, {x, 0}}.
    {move, {x, 4}, {x, 1}}.
    %% unresolved method call: push/2
    {move, {x, 0}, {x, 3}}.
    {gc_bif, '+', {f, 0}, 3, [{x, 1}, {integer, 1}], {x, 0}}.
    {move, {x, 0}, {x, 4}}.
    {move, {x, 2}, {x, 5}}.
    {move, {x, 3}, {x, 0}}.
    {move, {x, 4}, {x, 1}}.
    {move, {x, 5}, {x, 2}}.
    {call, 3, {f, 39}}.
    {jump, {f, 73}}.
  {label, 72}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 0}.
    return.
  {label, 73}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, flatten, 1, 41}.
  {label, 40}.
    {line, [{location, "std/list.erl", 20}]}.
    {func_info, {atom, std/list}, {atom, flatten}, 1}.
  {label, 41}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 1}.
    {make_fun3, {f, 75}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    %% unresolved method call: forEach/2
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
% NOTE: the transform is typed `-> V` (a bare generic) — fn-type returns
% must be plain names (parser limit, same note as the old option module);
% `V` unifies with the produced `Array<U>` at the call site.

{function, flatMap, 2, 43}.
  {label, 42}.
    {line, [{location, "std/list.erl", 21}]}.
    {func_info, {atom, std/list}, {atom, flatMap}, 2}.
  {label, 43}.
    {allocate, 0, 2}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {x, 3}, {x, 1}}.
    {call, 2, {f, 19}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 1, {f, 41}, 0}.
% `range(start, stop)` — half-open `[start, stop)`. NOTE: params are not
% named `from`/`to` — `from` is a reserved keyword.

{function, range, 2, 45}.
  {label, 44}.
    {line, [{location, "std/list.erl", 22}]}.
    {func_info, {atom, std/list}, {atom, range}, 2}.
  {label, 45}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 1}, {x, 2}}.
    {call, 3, {f, 39}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '-fold/3-fun-0-', 1, 55}.
  {label, 54}.
    {line, [{location, "std/list.erl", 12}]}.
    {func_info, {atom, std/list}, {atom, '-fold/3-fun-0-'}, 1}.
  {label, 55}.
    {allocate, 0, 1}.
    %% assign to unknown variable: acc
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '-append/2-fun-1-', 1, 65}.
  {label, 64}.
    {line, [{location, "std/list.erl", 17}]}.
    {func_info, {atom, std/list}, {atom, '-append/2-fun-1-'}, 1}.
  {label, 65}.
    {allocate, 0, 1}.
    {move, {atom, out}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    %% unresolved method call: push/2
    {deallocate, 0}.
    return.

{function, '-append/2-fun-2-', 1, 67}.
  {label, 66}.
    {line, [{location, "std/list.erl", 17}]}.
    {func_info, {atom, std/list}, {atom, '-append/2-fun-2-'}, 1}.
  {label, 67}.
    {allocate, 0, 1}.
    {move, {atom, out}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    %% unresolved method call: push/2
    {deallocate, 0}.
    return.

{function, '-prepend/2-fun-3-', 1, 69}.
  {label, 68}.
    {line, [{location, "std/list.erl", 18}]}.
    {func_info, {atom, std/list}, {atom, '-prepend/2-fun-3-'}, 1}.
  {label, 69}.
    {allocate, 0, 1}.
    {move, {atom, out}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    %% unresolved method call: push/2
    {deallocate, 0}.
    return.

{function, '-pushAll/2-fun-4-', 1, 71}.
  {label, 70}.
    {line, [{location, "std/list.erl", 19}]}.
    {func_info, {atom, std/list}, {atom, '-pushAll/2-fun-4-'}, 1}.
  {label, 71}.
    {allocate, 0, 1}.
    {move, {atom, out}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    %% unresolved method call: push/2
    {deallocate, 0}.
    return.

{function, '-flatten/1-fun-5-', 1, 75}.
  {label, 74}.
    {line, [{location, "std/list.erl", 21}]}.
    {func_info, {atom, std/list}, {atom, '-flatten/1-fun-5-'}, 1}.
  {label, 75}.
    {allocate, 0, 1}.
    {move, {atom, out}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    {call, 2, {f, 37}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
Execution error: error.FileNotFound```

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

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 12}.

{function, main, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {atom, list}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 5}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    {move, {x, 2}, {x, 2}}.
    %% unresolved method call: range/3
    {move, {x, 0}, {x, 0}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    %% unresolved method call: join/2
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, list}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, nil, {x, 0}}.
    {test_heap, 4, 1}.
    {move, {x, 0}, {x, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {put_list, {x, 0}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {put_list, {x, 0}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {test_heap, 4, 1}.
    {move, {x, 0}, {x, 0}}.
    {move, {integer, 4}, {x, 0}}.
    {put_list, {x, 0}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {integer, 3}, {x, 0}}.
    {put_list, {x, 0}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    {move, {x, 2}, {x, 2}}.
    %% unresolved method call: append/3
    {move, {x, 0}, {x, 0}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    %% unresolved method call: join/2
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, list}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, nil, {x, 0}}.
    {test_heap, 4, 1}.
    {move, {x, 0}, {x, 0}}.
    {move, {integer, 3}, {x, 0}}.
    {put_list, {x, 0}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {put_list, {x, 0}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    {move, {x, 2}, {x, 2}}.
    %% unresolved method call: prepend/3
    {move, {x, 0}, {x, 0}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    %% unresolved method call: join/2
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, list}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, nil, {x, 0}}.
    {test_heap, 4, 1}.
    {move, {x, 0}, {x, 0}}.
    {move, nil, {x, 0}}.
    {test_heap, 2, 1}.
    {move, {x, 0}, {x, 0}}.
    {move, {integer, 3}, {x, 0}}.
    {put_list, {x, 0}, {x, 0}, {x, 0}}.
    {put_list, {x, 0}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, nil, {x, 0}}.
    {test_heap, 4, 1}.
    {move, {x, 0}, {x, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {put_list, {x, 0}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {put_list, {x, 0}, {x, 0}, {x, 0}}.
    {put_list, {x, 0}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    %% unresolved method call: flatten/2
    {move, {x, 0}, {x, 0}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    %% unresolved method call: join/2
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, list}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {atom, list}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 10}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    {move, {x, 2}, {x, 2}}.
    %% unresolved method call: range/3
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 9}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    {move, {x, 2}, {x, 2}}.
    %% unresolved method call: count/3
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
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

{function, '-main/0-fun-0-', 1, 9}.
  {label, 8}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '-main/0-fun-0-'}, 1}.
  {label, 9}.
    {allocate, 0, 1}.
    {test, is_lt, {f, 10}, [{integer, 6}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 11}}.
  {label, 10}.
    {move, {atom, false}, {x, 0}}.
  {label, 11}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```

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

----- BEAM ASSEMBLY -- std/list.S
```erlang
{module, std/list}.
{exports, [{length, 1}, {is_empty, 1}, {contains, 2}, {first, 1}, {rest, 1}, {take, 2}, {drop, 2}, {reverse, 1}, {map, 2}, {filter, 2}, {fold, 3}, {all, 2}, {any, 2}]}.
{attributes, []}.
{labels, 45}.
%%% Gleam-style `list` module (`import {list} from "std";`), inspired by
%%% `gleam/list`, built over the builtin `Array<T>`. Pure logic — transforms
%%% delegate to the builtin Array methods; `fold` drives a mutable
%%% accumulator through `forEach`.

{function, length, 1, 3}.
  {label, 2}.
    {line, [{location, "std/list.erl", 1}]}.
    {func_info, {atom, std/list}, {atom, length}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {get_map_elements, {f, 28}, {x, 0}, {list, [{atom, length}, {x, 0}]}}.
  {label, 28}.
    {deallocate, 0}.
    return.

{function, is_empty, 1, 5}.
  {label, 4}.
    {line, [{location, "std/list.erl", 2}]}.
    {func_info, {atom, std/list}, {atom, is_empty}, 1}.
  {label, 5}.
    {allocate, 0, 1}.
    {get_map_elements, {f, 29}, {x, 0}, {list, [{atom, length}, {x, 0}]}}.
  {label, 29}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 30}, [{x, 1}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 31}}.
  {label, 30}.
    {move, {atom, false}, {x, 0}}.
  {label, 31}.
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
    {test, is_ne_exact, {f, 32}, [{x, 2}, {integer, -1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 33}}.
  {label, 32}.
    {move, {atom, false}, {x, 0}}.
  {label, 33}.
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
    {get_map_elements, {f, 34}, {x, 0}, {list, [{atom, length}, {x, 0}]}}.
  {label, 34}.
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
    {get_map_elements, {f, 35}, {x, 0}, {list, [{atom, length}, {x, 0}]}}.
  {label, 35}.
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
    {make_fun3, {f, 37}, 0, 0, {x, 0}, {list, []}}.
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
    {get_map_elements, {f, 38}, {x, 0}, {list, [{atom, length}, {x, 0}]}}.
  {label, 38}.
    {move, {x, 0}, {x, 2}}.
    {get_map_elements, {f, 39}, {x, 0}, {list, [{atom, length}, {x, 0}]}}.
  {label, 39}.
    {test, is_eq, {f, 40}, [{x, 2}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 41}}.
  {label, 40}.
    {move, {atom, false}, {x, 0}}.
  {label, 41}.
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
    {get_map_elements, {f, 42}, {x, 0}, {list, [{atom, length}, {x, 0}]}}.
  {label, 42}.
    {move, {x, 0}, {x, 2}}.
    {test, is_ne_exact, {f, 43}, [{x, 2}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 44}}.
  {label, 43}.
    {move, {atom, false}, {x, 0}}.
  {label, 44}.
    {deallocate, 0}.
    return.

{function, '-fold/3-fun-0-', 1, 37}.
  {label, 36}.
    {line, [{location, "std/list.erl", 12}]}.
    {func_info, {atom, std/list}, {atom, '-fold/3-fun-0-'}, 1}.
  {label, 37}.
    {allocate, 0, 1}.
    %% assign to unknown variable: acc
    {move, {atom, ok}, {x, 0}}.
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
    val xs = [1, 2, 3, 4];
    val doubled = list.map(xs, { x -> x * 2 });
    @print(list.fold(doubled, 0, { acc, x -> acc + x }));
    @print(list.length(list.filter(xs, { x -> x > 2 })));
    @print(list.contains(xs, 3));
    @print(list.take(xs, 2).join(","));
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 16}.

{function, main, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 3}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, nil, {x, 0}}.
    {test_heap, 8, 1}.
    {move, {x, 0}, {x, 0}}.
    {move, {integer, 4}, {x, 0}}.
    {put_list, {x, 0}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {integer, 3}, {x, 0}}.
    {put_list, {x, 0}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {put_list, {x, 0}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {put_list, {x, 0}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, list}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 9}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    {move, {x, 2}, {x, 2}}.
    %% unresolved method call: map/3
    {move, {x, 0}, {y, 1}}.
    {move, {atom, list}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 11}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    {move, {x, 2}, {x, 2}}.
    {move, {x, 3}, {x, 3}}.
    %% unresolved method call: fold/4
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, list}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {atom, list}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 13}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    {move, {x, 2}, {x, 2}}.
    %% unresolved method call: filter/3
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    %% unresolved method call: length/2
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, list}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    {move, {x, 2}, {x, 2}}.
    %% unresolved method call: contains/3
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, list}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    {move, {x, 2}, {x, 2}}.
    %% unresolved method call: take/3
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

{function, '-main/0-fun-0-', 1, 9}.
  {label, 8}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '-main/0-fun-0-'}, 1}.
  {label, 9}.
    {allocate, 0, 1}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {integer, 2}], {x, 0}}.
    {deallocate, 0}.
    return.

{function, '-main/0-fun-1-', 2, 11}.
  {label, 10}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '-main/0-fun-1-'}, 2}.
  {label, 11}.
    {allocate, 0, 2}.
    {gc_bif, '+', {f, 0}, 2, [{x, 0}, {x, 1}], {x, 0}}.
    {deallocate, 0}.
    return.

{function, '-main/0-fun-2-', 1, 13}.
  {label, 12}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '-main/0-fun-2-'}, 1}.
  {label, 13}.
    {allocate, 0, 1}.
    {test, is_lt, {f, 14}, [{integer, 2}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 15}}.
  {label, 14}.
    {move, {atom, false}, {x, 0}}.
  {label, 15}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```

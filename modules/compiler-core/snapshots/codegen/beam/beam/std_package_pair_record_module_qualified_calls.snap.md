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

----- BEAM ASSEMBLY -- std/pair.S
```erlang
{module, std/pair}.
{exports, [{of, 2}, {first, 1}, {second, 1}, {swap, 1}, {mapFirst, 2}, {mapSecond, 2}]}.
{attributes, []}.
{labels, 22}.
%%% Gleam-style `pair` module (`import {pair} from "std";`), inspired by
%%% `gleam/pair`. A pair IS a 2-tuple `#(a, b)` (same as Gleam) — structural,
%%% so no generic-record instantiation is involved. Pure logic, compiles once
%%% for every backend.
% NOTE: named `of` (not `new`) — `new` is a reserved keyword.

{function, of, 2, 3}.
  {label, 2}.
    {line, [{location, "std/pair.erl", 1}]}.
    {func_info, {atom, std/pair}, {atom, of}, 2}.
  {label, 3}.
    {allocate, 0, 2}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {test_heap, 3, 4}.
    {put_tuple2, {x, 0}, {list, [{x, 2}, {x, 3}]}}.
    {deallocate, 0}.
    return.

{function, first, 1, 5}.
  {label, 4}.
    {line, [{location, "std/pair.erl", 2}]}.
    {func_info, {atom, std/pair}, {atom, first}, 1}.
  {label, 5}.
    {allocate, 0, 1}.
    {get_map_elements, {f, 14}, {x, 0}, {list, [{atom, _0}, {x, 0}]}}.
  {label, 14}.
    {deallocate, 0}.
    return.

{function, second, 1, 7}.
  {label, 6}.
    {line, [{location, "std/pair.erl", 3}]}.
    {func_info, {atom, std/pair}, {atom, second}, 1}.
  {label, 7}.
    {allocate, 0, 1}.
    {get_map_elements, {f, 15}, {x, 0}, {list, [{atom, _1}, {x, 0}]}}.
  {label, 15}.
    {deallocate, 0}.
    return.

{function, swap, 1, 9}.
  {label, 8}.
    {line, [{location, "std/pair.erl", 4}]}.
    {func_info, {atom, std/pair}, {atom, swap}, 1}.
  {label, 9}.
    {allocate, 0, 1}.
    {get_map_elements, {f, 16}, {x, 0}, {list, [{atom, _1}, {x, 0}]}}.
  {label, 16}.
    {move, {x, 0}, {x, 1}}.
    {get_map_elements, {f, 17}, {x, 0}, {list, [{atom, _0}, {x, 0}]}}.
  {label, 17}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, 3, 3}.
    {put_tuple2, {x, 0}, {list, [{x, 1}, {x, 2}]}}.
    {deallocate, 0}.
    return.

{function, mapFirst, 2, 11}.
  {label, 10}.
    {line, [{location, "std/pair.erl", 5}]}.
    {func_info, {atom, std/pair}, {atom, mapFirst}, 2}.
  {label, 11}.
    {allocate, 0, 2}.
    {move, {x, 1}, {x, 1}}.
    {get_map_elements, {f, 18}, {x, 0}, {list, [{atom, _0}, {x, 0}]}}.
  {label, 18}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 2}, {x, 0}}.
    {call_fun, 1}.
    {move, {x, 0}, {x, 2}}.
    {get_map_elements, {f, 19}, {x, 0}, {list, [{atom, _1}, {x, 0}]}}.
  {label, 19}.
    {move, {x, 0}, {x, 3}}.
    {test_heap, 3, 4}.
    {put_tuple2, {x, 0}, {list, [{x, 2}, {x, 3}]}}.
    {deallocate, 0}.
    return.

{function, mapSecond, 2, 13}.
  {label, 12}.
    {line, [{location, "std/pair.erl", 6}]}.
    {func_info, {atom, std/pair}, {atom, mapSecond}, 2}.
  {label, 13}.
    {allocate, 0, 2}.
    {get_map_elements, {f, 20}, {x, 0}, {list, [{atom, _0}, {x, 0}]}}.
  {label, 20}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 1}}.
    {get_map_elements, {f, 21}, {x, 0}, {list, [{atom, _1}, {x, 0}]}}.
  {label, 21}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 2}, {x, 0}}.
    {call_fun, 1}.
    {move, {x, 0}, {x, 3}}.
    {test_heap, 3, 4}.
    {put_tuple2, {x, 0}, {list, [{x, 2}, {x, 3}]}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
Execution error: error.FileNotFound```

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
    {move, {atom, pair}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"one">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    {move, {x, 2}, {x, 2}}.
    %% unresolved method call: of/3
    {move, {x, 0}, {y, 0}}.
    {move, {atom, pair}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    %% unresolved method call: swap/2
    {move, {x, 0}, {y, 1}}.
    {move, {atom, pair}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    %% unresolved method call: first/2
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, pair}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    %% unresolved method call: second/2
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
```

----- RUN LOG -----
```logs
<<"one">>
<<"one">>
```

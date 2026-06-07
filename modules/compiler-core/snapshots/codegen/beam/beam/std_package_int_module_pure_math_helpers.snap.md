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

test "int absoluteValue" {
    assert absoluteValue(0) == 0;
    assert absoluteValue(-5) == 5;
    assert absoluteValue(5) == 5;
}

test "int min and max" {
    assert min(3, 7) == 3;
    assert max(3, 7) == 7;
    assert min(-1, 0) == -1;
}

test "int clamp" {
    assert clamp(3, 0, 5) == 3;
    assert clamp(-1, 0, 5) == 0;
    assert clamp(10, 0, 5) == 5;
}

test "int isEven and isOdd" {
    assert isEven(4);
    assert !isEven(3);
    assert isOdd(7);
    assert !isOdd(8);
}

test "int toString" {
    assert toString(42) == "42";
    assert toString(0) == "0";
}

```

----- BEAM ASSEMBLY -- std/int.S
```erlang
{module, std/int}.
{exports, [{absoluteValue, 1}, {min, 2}, {max, 2}, {clamp, 3}, {isEven, 1}, {isOdd, 1}, {toString, 1}]}.
{attributes, []}.
{labels, 26}.
%%% Integer utilities module (`import {int} from "std";`).
%%% Pure-botopink math helpers for `i32` values. No host backing —
%%% compiles once for every backend.
%%% Function names follow the language convention: camelCase.

{function, absoluteValue, 1, 3}.
  {label, 2}.
    {line, [{location, "std/int.erl", 1}]}.
    {func_info, {atom, std/int}, {atom, absoluteValue}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {test, is_lt, {f, 16}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '-', {f, 0}, 1, [{integer, 0}, {x, 0}], {x, 0}}.
    {jump, {f, 17}}.
  {label, 16}.
  {label, 17}.
    {deallocate, 0}.
    return.

{function, min, 2, 5}.
  {label, 4}.
    {line, [{location, "std/int.erl", 2}]}.
    {func_info, {atom, std/int}, {atom, min}, 2}.
  {label, 5}.
    {allocate, 0, 2}.
    {test, is_lt, {f, 18}, [{x, 0}, {x, 1}]}.
    {jump, {f, 19}}.
  {label, 18}.
    {move, {x, 1}, {x, 0}}.
  {label, 19}.
    {deallocate, 0}.
    return.

{function, max, 2, 7}.
  {label, 6}.
    {line, [{location, "std/int.erl", 3}]}.
    {func_info, {atom, std/int}, {atom, max}, 2}.
  {label, 7}.
    {allocate, 0, 2}.
    {test, is_lt, {f, 20}, [{x, 1}, {x, 0}]}.
    {jump, {f, 21}}.
  {label, 20}.
    {move, {x, 1}, {x, 0}}.
  {label, 21}.
    {deallocate, 0}.
    return.

{function, clamp, 3, 9}.
  {label, 8}.
    {line, [{location, "std/int.erl", 4}]}.
    {func_info, {atom, std/int}, {atom, clamp}, 3}.
  {label, 9}.
    {allocate, 0, 3}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    {call, 2, {f, 7}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 2}, {x, 4}}.
    {move, {x, 3}, {x, 0}}.
    {move, {x, 4}, {x, 1}}.
    {call_last, 2, {f, 5}, 0}.

{function, isEven, 1, 11}.
  {label, 10}.
    {line, [{location, "std/int.erl", 5}]}.
    {func_info, {atom, std/int}, {atom, isEven}, 1}.
  {label, 11}.
    {allocate, 0, 1}.
    {gc_bif, 'rem', {f, 0}, 1, [{x, 0}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 22}, [{x, 1}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 23}}.
  {label, 22}.
    {move, {atom, false}, {x, 0}}.
  {label, 23}.
    {deallocate, 0}.
    return.

{function, isOdd, 1, 13}.
  {label, 12}.
    {line, [{location, "std/int.erl", 6}]}.
    {func_info, {atom, std/int}, {atom, isOdd}, 1}.
  {label, 13}.
    {allocate, 0, 1}.
    {gc_bif, 'rem', {f, 0}, 1, [{x, 0}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 24}, [{x, 1}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 25}}.
  {label, 24}.
    {move, {atom, false}, {x, 0}}.
  {label, 25}.
    {deallocate, 0}.
    return.
% NOTE: `to_string` (convert integer to its decimal string representation).
% Botopink coerces numbers to string in `+` contexts — `"" + n` works.

{function, toString, 1, 15}.
  {label, 14}.
    {line, [{location, "std/int.erl", 7}]}.
    {func_info, {atom, std/int}, {atom, toString}, 1}.
  {label, 15}.
    {allocate, 0, 1}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
Execution error: error.FileNotFound```

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
    {allocate, 0, 0}.
    {move, {atom, int}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {integer, 5}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    %% unresolved method call: absoluteValue/2
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, int}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 7}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    {move, {x, 2}, {x, 2}}.
    %% unresolved method call: min/3
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, int}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 7}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    {move, {x, 2}, {x, 2}}.
    %% unresolved method call: max/3
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, int}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {integer, 10}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {integer, 5}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    {move, {x, 2}, {x, 2}}.
    {move, {x, 3}, {x, 3}}.
    %% unresolved method call: clamp/4
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, int}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    %% unresolved method call: isEven/2
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, int}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    %% unresolved method call: isOdd/2
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, int}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {integer, 42}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    %% unresolved method call: toString/2
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
```

----- RUN LOG -----
```logs
5
7
7
5
4
3
42
```

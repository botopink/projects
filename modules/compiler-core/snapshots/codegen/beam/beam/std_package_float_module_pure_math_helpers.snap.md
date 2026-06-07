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

----- BEAM ASSEMBLY -- std/float.S
```erlang
{module, std/float}.
{exports, [{absoluteValue, 1}, {min, 2}, {max, 2}, {clamp, 3}, {floor, 1}, {ceiling, 1}, {round, 1}, {squareRoot, 1}, {toString, 1}]}.
{attributes, []}.
{labels, 26}.
%%% Float utilities module (`import {float} from "std";`).
%%% Math helpers for `f64` values. Host-backed for rounding primitives.
%%% Function names follow the language convention: camelCase.

{function, absoluteValue, 1, 3}.
  {label, 2}.
    {line, [{location, "std/float.erl", 1}]}.
    {func_info, {atom, std/float}, {atom, absoluteValue}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {test, is_lt, {f, 20}, [{x, 0}, {float, 0.0}]}.
    {gc_bif, '-', {f, 0}, 1, [{integer, 0}, {x, 0}], {x, 0}}.
    {jump, {f, 21}}.
  {label, 20}.
  {label, 21}.
    {deallocate, 0}.
    return.

{function, min, 2, 5}.
  {label, 4}.
    {line, [{location, "std/float.erl", 2}]}.
    {func_info, {atom, std/float}, {atom, min}, 2}.
  {label, 5}.
    {allocate, 0, 2}.
    {test, is_lt, {f, 22}, [{x, 0}, {x, 1}]}.
    {jump, {f, 23}}.
  {label, 22}.
    {move, {x, 1}, {x, 0}}.
  {label, 23}.
    {deallocate, 0}.
    return.

{function, max, 2, 7}.
  {label, 6}.
    {line, [{location, "std/float.erl", 3}]}.
    {func_info, {atom, std/float}, {atom, max}, 2}.
  {label, 7}.
    {allocate, 0, 2}.
    {test, is_lt, {f, 24}, [{x, 1}, {x, 0}]}.
    {jump, {f, 25}}.
  {label, 24}.
    {move, {x, 1}, {x, 0}}.
  {label, 25}.
    {deallocate, 0}.
    return.

{function, clamp, 3, 9}.
  {label, 8}.
    {line, [{location, "std/float.erl", 4}]}.
    {func_info, {atom, std/float}, {atom, clamp}, 3}.
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

{function, floor, 1, 11}.
  {label, 10}.
    {line, [{location, "std/float.erl", 5}]}.
    {func_info, {atom, std/float}, {atom, floor}, 1}.
  {label, 11}.
    {allocate, 0, 1}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, ceiling, 1, 13}.
  {label, 12}.
    {line, [{location, "std/float.erl", 6}]}.
    {func_info, {atom, std/float}, {atom, ceiling}, 1}.
  {label, 13}.
    {allocate, 0, 1}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, round, 1, 15}.
  {label, 14}.
    {line, [{location, "std/float.erl", 7}]}.
    {func_info, {atom, std/float}, {atom, round}, 1}.
  {label, 15}.
    {allocate, 0, 1}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, squareRoot, 1, 17}.
  {label, 16}.
    {line, [{location, "std/float.erl", 8}]}.
    {func_info, {atom, std/float}, {atom, squareRoot}, 1}.
  {label, 17}.
    {allocate, 0, 1}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.
% NOTE: `toString` for floats — coerces via string concat.

{function, toString, 1, 19}.
  {label, 18}.
    {line, [{location, "std/float.erl", 9}]}.
    {func_info, {atom, std/float}, {atom, toString}, 1}.
  {label, 19}.
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
    {move, {atom, float}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {float, 2.5}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    %% unresolved method call: absoluteValue/2
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, float}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {float, 1.5}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {float, 2.5}, {x, 0}}.
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
    {move, {atom, float}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {float, 1.5}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {float, 2.5}, {x, 0}}.
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
    {move, {atom, float}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {float, 3.0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {float, 0.0}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {float, 5.0}, {x, 0}}.
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
    {move, {atom, float}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {float, 3.14}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    %% unresolved method call: toString/2
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, float}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {float, 2.9}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    %% unresolved method call: floor/2
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, float}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {float, 2.1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    %% unresolved method call: ceiling/2
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, float}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {float, 2.5}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    %% unresolved method call: round/2
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, float}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {float, 9.0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    %% unresolved method call: squareRoot/2
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
2.5
2.5
2.5
5.0
3.14
2.9
2.1
2.5
9.0
```

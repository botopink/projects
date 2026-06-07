----- SOURCE CODE -- std/bool.bp
```botopink
//// Gleam-inspired `bool` module (`import {bool} from "std";`).
//// Pure-operator logic — no host backing, compiles once for every backend.
//// Function names follow the language convention: camelCase.
//// First real `"std"` package module (qualified calls lower to a per-module
//// output: `out/std/bool.js` / remote `bool:negate/1`).

pub fn negate(b: bool) -> bool {
    return !b;
}

pub fn nor(a: bool, b: bool) -> bool {
    return !(a || b);
}

pub fn nand(a: bool, b: bool) -> bool {
    return !(a && b);
}

pub fn exclusiveOr(a: bool, b: bool) -> bool {
    return a != b;
}

pub fn exclusiveNor(a: bool, b: bool) -> bool {
    return a == b;
}

test "bool negate" {
    assert negate(false);
    assert negate(negate(true));
}

test "bool nor" {
    assert nor(false, false);
    assert negate(nor(true, false));
}

test "bool nand" {
    assert nand(true, false);
    assert negate(nand(true, true));
}

test "bool exclusiveOr" {
    assert exclusiveOr(true, false);
    assert negate(exclusiveOr(true, true));
}

test "bool exclusiveNor" {
    assert exclusiveNor(true, true);
    assert negate(exclusiveNor(true, false));
}

```

----- BEAM ASSEMBLY -- std/bool.S
```erlang
{module, std/bool}.
{exports, [{negate, 1}, {nor, 2}, {nand, 2}, {exclusiveOr, 2}, {exclusiveNor, 2}]}.
{attributes, []}.
{labels, 26}.
%%% Gleam-inspired `bool` module (`import {bool} from "std";`).
%%% Pure-operator logic — no host backing, compiles once for every backend.
%%% Function names follow the language convention: camelCase.
%%% First real `"std"` package module (qualified calls lower to a per-module
%%% output: `out/std/bool.js` / remote `bool:negate/1`).

{function, negate, 1, 3}.
  {label, 2}.
    {line, [{location, "std/bool.erl", 1}]}.
    {func_info, {atom, std/bool}, {atom, negate}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {test, is_eq, {f, 12}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 13}}.
  {label, 12}.
    {move, {atom, true}, {x, 0}}.
  {label, 13}.
    {deallocate, 0}.
    return.

{function, nor, 2, 5}.
  {label, 4}.
    {line, [{location, "std/bool.erl", 2}]}.
    {func_info, {atom, std/bool}, {atom, nor}, 2}.
  {label, 5}.
    {allocate, 0, 2}.
    {test, is_ne_exact, {f, 14}, [{x, 0}, {atom, true}]}.
    {move, {x, 1}, {x, 0}}.
    {jump, {f, 15}}.
  {label, 14}.
    {move, {atom, true}, {x, 0}}.
  {label, 15}.
    {test, is_eq, {f, 16}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 17}}.
  {label, 16}.
    {move, {atom, true}, {x, 0}}.
  {label, 17}.
    {deallocate, 0}.
    return.

{function, nand, 2, 7}.
  {label, 6}.
    {line, [{location, "std/bool.erl", 3}]}.
    {func_info, {atom, std/bool}, {atom, nand}, 2}.
  {label, 7}.
    {allocate, 0, 2}.
    {test, is_eq, {f, 18}, [{x, 0}, {atom, true}]}.
    {move, {x, 1}, {x, 0}}.
    {jump, {f, 19}}.
  {label, 18}.
    {move, {atom, false}, {x, 0}}.
  {label, 19}.
    {test, is_eq, {f, 20}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 21}}.
  {label, 20}.
    {move, {atom, true}, {x, 0}}.
  {label, 21}.
    {deallocate, 0}.
    return.

{function, exclusiveOr, 2, 9}.
  {label, 8}.
    {line, [{location, "std/bool.erl", 4}]}.
    {func_info, {atom, std/bool}, {atom, exclusiveOr}, 2}.
  {label, 9}.
    {allocate, 0, 2}.
    {test, is_ne_exact, {f, 22}, [{x, 0}, {x, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 23}}.
  {label, 22}.
    {move, {atom, false}, {x, 0}}.
  {label, 23}.
    {deallocate, 0}.
    return.

{function, exclusiveNor, 2, 11}.
  {label, 10}.
    {line, [{location, "std/bool.erl", 5}]}.
    {func_info, {atom, std/bool}, {atom, exclusiveNor}, 2}.
  {label, 11}.
    {allocate, 0, 2}.
    {test, is_eq, {f, 24}, [{x, 0}, {x, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 25}}.
  {label, 24}.
    {move, {atom, false}, {x, 0}}.
  {label, 25}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
Execution error: error.FileNotFound```

----- SOURCE CODE -- main.bp
```botopink
import {bool} from "std";

fn main() {
    val flipped = bool.negate(false);
    @print(bool.exclusiveOr(flipped, false));
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
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {atom, bool}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    %% unresolved method call: negate/2
    {move, {x, 0}, {y, 0}}.
    {move, {atom, bool}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    {move, {x, 2}, {x, 2}}.
    %% unresolved method call: exclusiveOr/3
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
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
false
```

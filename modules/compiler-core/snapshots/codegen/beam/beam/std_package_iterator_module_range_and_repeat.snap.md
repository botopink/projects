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

----- BEAM ASSEMBLY -- std/iterator.S
```erlang
{module, std/iterator}.
{exports, [{range, 2}, {repeat, 2}]}.
{attributes, []}.
{labels, 12}.
%%% Lazy iterator utilities module (`import {iterator} from "std";`).
%%% Built on botopink's `*fn` / `@Iterator<T>` generator mechanism.
%%% Function names follow the language convention: camelCase.
%%% 
%%% NOTE: higher-order ops (map/filter/fold) require consuming an iterator
%%% via `loop (iter) { ... }` which is the iteration form in botopink.
%%% Use the `list` module for eager transforms on arrays.
% Internal recursive helper: yields integers [cur, stop).

%% *fn (async/generator) — eager lowering
{function, doRange, 2, 3}.
  {label, 2}.
    {line, [{location, "std/iterator.erl", 1}]}.
    {func_info, {atom, std/iterator}, {atom, doRange}, 2}.
  {label, 3}.
    {allocate, 0, 2}.
    {test, is_lt, {f, 10}, [{x, 0}, {x, 1}]}.
    {deallocate, 0}.
    return.
    {gc_bif, '+', {f, 0}, 2, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {x, 3}, {x, 1}}.
    {call_last, 2, {f, 3}, 0}.
  {label, 10}.
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
    {test, is_lt, {f, 11}, [{integer, 0}, {x, 1}]}.
    {deallocate, 0}.
    return.
    {move, {x, 0}, {x, 2}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 1}, {integer, 1}], {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {x, 3}, {x, 1}}.
    {call_last, 2, {f, 7}, 0}.
  {label, 11}.
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

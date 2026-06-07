----- SOURCE CODE -- std/string.bp
```botopink
//// String utilities module (`import {string} from "std";`).
//// Qualified wrappers over the built-in String interface methods.
//// Follows the Gleam-inspired naming convention: camelCase.

pub fn split(s: string, sep: string) -> Array<string> {
    return s.split(sep);
}

pub fn trim(s: string) -> string {
    return s.trim();
}

pub fn trimStart(s: string) -> string {
    return s.trim_start();
}

pub fn trimEnd(s: string) -> string {
    return s.trim_end();
}

pub fn contains(s: string, sub: string) -> bool {
    return s.contains(sub);
}

pub fn startsWith(s: string, prefix: string) -> bool {
    return s.starts_with(prefix);
}

pub fn endsWith(s: string, suffix: string) -> bool {
    return s.ends_with(suffix);
}

pub fn slice(s: string, start: i32, end: i32) -> string {
    return s.slice(start, end);
}

pub fn replace(s: string, pattern: string, with: string) -> string {
    return s.replace(pattern, with);
}

pub fn toUpper(s: string) -> string {
    return s.to_upper();
}

pub fn toLower(s: string) -> string {
    return s.to_lower();
}

// `join` takes an array of strings and a separator — Array<string>.join(sep).
pub fn join(parts: Array<string>, sep: string) -> string {
    return parts.join(sep);
}

test "inline: split and join round-trip" {
    val parts = split("a,b,c", ",");
    assert join(parts, "-") == "a-b-c";
}

test "inline: contains" {
    assert contains("hello world", "world");
    assert !contains("hello", "xyz");
}

test "inline: startsWith and endsWith" {
    assert startsWith("foobar", "foo");
    assert endsWith("foobar", "bar");
}

test "inline: slice" {
    assert slice("hello", 1, 3) == "el";
}

```

----- BEAM ASSEMBLY -- std/string.S
```erlang
{module, std/string}.
{exports, [{split, 2}, {trim, 1}, {trimStart, 1}, {trimEnd, 1}, {contains, 2}, {startsWith, 2}, {endsWith, 2}, {slice, 3}, {replace, 3}, {toUpper, 1}, {toLower, 1}, {join, 2}]}.
{attributes, []}.
{labels, 26}.
%%% String utilities module (`import {string} from "std";`).
%%% Qualified wrappers over the built-in String interface methods.
%%% Follows the Gleam-inspired naming convention: camelCase.

{function, split, 2, 3}.
  {label, 2}.
    {line, [{location, "std/string.erl", 1}]}.
    {func_info, {atom, std/string}, {atom, split}, 2}.
  {label, 3}.
    {allocate, 0, 2}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {x, 3}, {x, 1}}.
    {call_last, 2, {f, 3}, 0}.

{function, trim, 1, 5}.
  {label, 4}.
    {line, [{location, "std/string.erl", 2}]}.
    {func_info, {atom, std/string}, {atom, trim}, 1}.
  {label, 5}.
    {allocate, 0, 1}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 1}, {x, 0}}.
    {call_last, 1, {f, 5}, 0}.

{function, trimStart, 1, 7}.
  {label, 6}.
    {line, [{location, "std/string.erl", 3}]}.
    {func_info, {atom, std/string}, {atom, trimStart}, 1}.
  {label, 7}.
    {allocate, 0, 1}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 1}, {x, 0}}.
    %% unresolved method call: trim_start/1
    {deallocate, 0}.
    return.

{function, trimEnd, 1, 9}.
  {label, 8}.
    {line, [{location, "std/string.erl", 4}]}.
    {func_info, {atom, std/string}, {atom, trimEnd}, 1}.
  {label, 9}.
    {allocate, 0, 1}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 1}, {x, 0}}.
    %% unresolved method call: trim_end/1
    {deallocate, 0}.
    return.

{function, contains, 2, 11}.
  {label, 10}.
    {line, [{location, "std/string.erl", 5}]}.
    {func_info, {atom, std/string}, {atom, contains}, 2}.
  {label, 11}.
    {allocate, 0, 2}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {x, 3}, {x, 1}}.
    {call_last, 2, {f, 11}, 0}.

{function, startsWith, 2, 13}.
  {label, 12}.
    {line, [{location, "std/string.erl", 6}]}.
    {func_info, {atom, std/string}, {atom, startsWith}, 2}.
  {label, 13}.
    {allocate, 0, 2}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {x, 3}, {x, 1}}.
    %% unresolved method call: starts_with/2
    {deallocate, 0}.
    return.

{function, endsWith, 2, 15}.
  {label, 14}.
    {line, [{location, "std/string.erl", 7}]}.
    {func_info, {atom, std/string}, {atom, endsWith}, 2}.
  {label, 15}.
    {allocate, 0, 2}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {x, 3}, {x, 1}}.
    %% unresolved method call: ends_with/2
    {deallocate, 0}.
    return.

{function, slice, 3, 17}.
  {label, 16}.
    {line, [{location, "std/string.erl", 8}]}.
    {func_info, {atom, std/string}, {atom, slice}, 3}.
  {label, 17}.
    {allocate, 0, 3}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 4}}.
    {move, {x, 2}, {x, 0}}.
    {move, {x, 0}, {x, 5}}.
    {move, {x, 3}, {x, 0}}.
    {move, {x, 4}, {x, 1}}.
    {move, {x, 5}, {x, 2}}.
    {call_last, 3, {f, 17}, 0}.

{function, replace, 3, 19}.
  {label, 18}.
    {line, [{location, "std/string.erl", 9}]}.
    {func_info, {atom, std/string}, {atom, replace}, 3}.
  {label, 19}.
    {allocate, 0, 3}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 4}}.
    {move, {x, 2}, {x, 0}}.
    {move, {x, 0}, {x, 5}}.
    {move, {x, 3}, {x, 0}}.
    {move, {x, 4}, {x, 1}}.
    {move, {x, 5}, {x, 2}}.
    {call_last, 3, {f, 19}, 0}.

{function, toUpper, 1, 21}.
  {label, 20}.
    {line, [{location, "std/string.erl", 10}]}.
    {func_info, {atom, std/string}, {atom, toUpper}, 1}.
  {label, 21}.
    {allocate, 0, 1}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 1}, {x, 0}}.
    %% unresolved method call: to_upper/1
    {deallocate, 0}.
    return.

{function, toLower, 1, 23}.
  {label, 22}.
    {line, [{location, "std/string.erl", 11}]}.
    {func_info, {atom, std/string}, {atom, toLower}, 1}.
  {label, 23}.
    {allocate, 0, 1}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 1}, {x, 0}}.
    %% unresolved method call: to_lower/1
    {deallocate, 0}.
    return.
% `join` takes an array of strings and a separator — Array<string>.join(sep).

{function, join, 2, 25}.
  {label, 24}.
    {line, [{location, "std/string.erl", 12}]}.
    {func_info, {atom, std/string}, {atom, join}, 2}.
  {label, 25}.
    {allocate, 0, 2}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {x, 3}, {x, 1}}.
    {call_last, 2, {f, 25}, 0}.
```

----- RUN LOG -----
```logs
Execution error: error.FileNotFound```

----- SOURCE CODE -- main.bp
```botopink
import {string} from "std";

fn main() {
    val parts = string.split("a,b,c", ",");
    @print(string.join(parts, "|"));
    @print(string.contains("hello world", "world"));
    @print(string.startsWith("foobar", "foo"));
    @print(string.slice("hello", 1, 3));
    @print(string.trim("  hi  "));
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
    {move, {atom, string}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {literal, <<"a,b,c">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    {move, {x, 2}, {x, 2}}.
    %% unresolved method call: split/3
    {move, {x, 0}, {y, 0}}.
    {move, {atom, string}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"|">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    {move, {x, 2}, {x, 2}}.
    %% unresolved method call: join/3
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, string}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {literal, <<"hello world">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"world">>}, {x, 0}}.
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
    {move, {atom, string}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {literal, <<"foobar">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"foo">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    {move, {x, 2}, {x, 2}}.
    %% unresolved method call: startsWith/3
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, string}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {literal, <<"hello">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    {move, {x, 2}, {x, 2}}.
    {move, {x, 3}, {x, 3}}.
    %% unresolved method call: slice/4
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, string}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {literal, <<"  hi  ">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    %% unresolved method call: trim/2
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
<<"|">>
<<"world">>
<<"foo">>
3
<<"  hi  ">>
```

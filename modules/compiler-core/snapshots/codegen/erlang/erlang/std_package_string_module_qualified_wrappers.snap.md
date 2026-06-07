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

test "string split and length" {
    val s = "a,b";
    val parts = s.split(",");
    assert parts.length == 2;
}

test "string trim" {
    val padded = "  hi  ";
    assert padded.trim() == "hi";
}

test "string slice via method" {
    val h = "hello";
    assert h.slice(1, 3) == "el";
    assert h.slice(0, 2) == "he";
}

```

----- ERLANG -- std/string.erl
```erlang
-module(string).
-export([split/2, trim/1, trimStart/1, trimEnd/1, contains/2, startsWith/2, endsWith/2, slice/3, replace/3, toUpper/1, toLower/1, join/2]).

%%% String utilities module (`import {string} from "std";`).

%%% Qualified wrappers over the built-in String interface methods.

%%% Follows the Gleam-inspired naming convention: camelCase.

split(S, Sep) ->
    S:split(Sep).

trim(S) ->
    S:trim().

trimStart(S) ->
    S:trim_start().

trimEnd(S) ->
    S:trim_end().

contains(S, Sub) ->
    S:contains(Sub).

startsWith(S, Prefix) ->
    S:starts_with(Prefix).

endsWith(S, Suffix) ->
    S:ends_with(Suffix).

slice(S, Start, End) ->
    S:slice(Start, End).

replace(S, Pattern, With) ->
    S:replace(Pattern, With).

toUpper(S) ->
    S:to_upper().

toLower(S) ->
    S:to_lower().

% `join` takes an array of strings and a separator — Array<string>.join(sep).

join(Parts, Sep) ->
    Parts:join(Sep).







```

----- RUN LOG -----
```logs
```

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

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% import string

main() ->
    Parts = string:split(<<"a,b,c">>, <<",">>),
    io:format("~p~n", [string:join(Parts, <<"|">>)]),
    io:format("~p~n", [string:contains(<<"hello world">>, <<"world">>)]),
    io:format("~p~n", [string:startsWith(<<"foobar">>, <<"foo">>)]),
    io:format("~p~n", [string:slice(<<"hello">>, 1, 3)]),
    io:format("~p~n", [string:trim(<<"  hi  ">>)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

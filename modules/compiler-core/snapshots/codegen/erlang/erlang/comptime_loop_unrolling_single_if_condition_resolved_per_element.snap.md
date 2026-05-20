----- SOURCE CODE -- main.bp
```botopink
val COMMANDS = comptime ["calc", "noop", "help"];

fn execute(comptime slug: string, input: i32) -> i32 {
    var output = 0;
    loop (COMMANDS) { cmd ->
        if (cmd == slug) {
            output = input * 2;
        };
    };
    return output;
}

fn main() {
    val r1 = execute("calc", 10);
    val r2 = execute("noop", 42);
}
```

----- COMPTIME ERLANG -- main.erl
```erlang
-module(main).
-export([main/1]).

main(_) ->
    Values = [
        #{<<"id">> => <<"ct_0">>, <<"value">> => ["calc", "noop", "help"]}
    ],
    Json = json:encode(Values),
    io:format("~s~n", [Json]).
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export([_botopink_main/0]).

COMMANDS() ->
    [undefined, undefined, undefined].

_botopink_main() ->
    R1 = execute_$0(10),
    R2 = execute_$1(42).

execute_$0(Input) ->
    Output = 0,
    Output = (Input * 2),
    Output.

execute_$1(Input) ->
    Output = 0,
    Output = (Input * 2),
    Output.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
fn main() -> string {
    val func: fn(String)-> string = {s ->
        return s;
    };
    return func("hello");
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export([_botopink_main/0]).

_botopink_main() ->
    Func = fun(S) ->
        S
    end,
    func(<<"hello">>).
```

----- RUN LOG -----
```logs
Execution error: error.FileNotFound```

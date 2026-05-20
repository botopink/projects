----- SOURCE CODE -- main.bp
```botopink
fn main() {
    @print("Hello, World!");
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export([_botopink_main/0]).

_botopink_main() ->
    io:format("~p~n", [<<"Hello, World!">>]).
```

----- RUN LOG -----
```logs
```

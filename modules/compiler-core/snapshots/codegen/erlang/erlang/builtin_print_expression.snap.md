----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val x = 10;
    @print(x * 2);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export([_botopink_main/0]).

_botopink_main() ->
    X = 10,
    io:format("~p~n", [(X * 2)]).
```

----- RUN LOG -----
```logs
```

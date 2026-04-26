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

main() ->
    X = 10,
    io:format("~p~n", [(X * 2)]).
```

----- RUN LOG -----
```logs
// Erlang execution not yet implemented```

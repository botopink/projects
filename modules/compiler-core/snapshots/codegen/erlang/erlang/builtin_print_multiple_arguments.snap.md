----- SOURCE CODE -- main.bp
```botopink
fn main() {
    @print("Hello", 42, true);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

main() ->
    io:format("~p~n", [<<"Hello">>, 42, True]).
```

----- RUN LOG -----
```logs
// Erlang execution not yet implemented```

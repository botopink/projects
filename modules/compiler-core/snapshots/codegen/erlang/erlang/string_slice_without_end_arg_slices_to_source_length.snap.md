----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val s = "hello";
    val tail = s.slice(2);
    @print(tail.len);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    S = <<"hello">>,
    Tail = S:slice(2),
    io:format("~p~n", [Tail_len]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

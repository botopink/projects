----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val hw = "hello world";
    @print(hw.contains("world"));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    Hw = <<"hello world">>,
    io:format("~p~n", [Hw:contains(<<"world">>)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val s = "abcdef";
    val mid = s.slice(1, 5);
    @print(mid.len);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    S = <<"abcdef">>,
    Mid = S:slice(1, 5),
    io:format("~p~n", [maps:get(len, Mid)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

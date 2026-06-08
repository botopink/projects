----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val s = "Hello,World";
    @print(s.toUpper());
    @print(s.toLower());
    @print(s.split(",").join("|"));
    @print(s.slice(0, 5));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    S = <<"Hello,World">>,
    io:format("~p~n", [S:toUpper()]),
    io:format("~p~n", [S:toLower()]),
    io:format("~p~n", [S:split(<<",">>):join(<<"|">>)]),
    io:format("~p~n", [S:slice(0, 5)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

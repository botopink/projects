----- SOURCE CODE -- main.bp
```botopink
fn main() {
    @print(true.negate());
    @print(false.nor(false));
    @print(true.nand(true));
    @print(true.exclusiveOr(false));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% interface Bool

main() ->
    io:format("~p~n", [true:negate()]),
    io:format("~p~n", [false:nor(false)]),
    io:format("~p~n", [true:nand(true)]),
    io:format("~p~n", [true:exclusiveOr(false)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

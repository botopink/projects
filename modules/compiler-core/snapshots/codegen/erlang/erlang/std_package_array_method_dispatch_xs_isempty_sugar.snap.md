----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val xs: Array<i32> = [];
    @print(xs.isEmpty());
    val ys = [1, 2, 3];
    @print(ys.isEmpty());
    @print(ys.length());
    @print(ys.contains(2));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% import list

main() ->
    Xs = [],
    io:format("~p~n", [list:isEmpty(Xs)]),
    Ys = [1, 2, 3],
    io:format("~p~n", [list:isEmpty(Ys)]),
    io:format("~p~n", [list:length(Ys)]),
    io:format("~p~n", [list:contains(Ys, 2)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

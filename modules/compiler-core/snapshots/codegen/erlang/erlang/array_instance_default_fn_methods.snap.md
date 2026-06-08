----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val xs = [1, 2, 3];
    @print(xs.prepend(0).join(","));
    @print(xs.fold(0, { a, x -> a + x }));
    @print(xs.isEmpty());
    @print(xs.all({ x -> x > 0 }));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% interface Array

main() ->
    Xs = [1, 2, 3],
    io:format("~p~n", [Xs:prepend(0):join(<<",">>)]),
    io:format("~p~n", [Xs:fold(0, fun(A, X) ->
        (A + X)
    end)]),
    io:format("~p~n", [Xs:isEmpty()]),
    io:format("~p~n", [Xs:all(fun(X) ->
        (X > 0)
    end)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

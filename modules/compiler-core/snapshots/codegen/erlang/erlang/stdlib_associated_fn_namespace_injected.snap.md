----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val p = Pair.of(1, "one");
    @print(Pair.first(p));
    @print(Function.identity(42));
    val inc = Function.compose({ x -> x + 1 }, { y -> y * 2 });
    @print(inc(10));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% interface Function

%% interface Pair

main() ->
    P = pair:'of'(1, <<"one">>),
    io:format("~p~n", [pair:first(P)]),
    io:format("~p~n", [function:identity(42)]),
    Inc = function:compose(fun(X) ->
        (X + 1)
    end, fun(Y) ->
        (Y * 2)
    end),
    io:format("~p~n", [Inc(10)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

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

identity(X) ->
    X.

compose(F, G) ->
    fun(A) ->
        G(F(A))
    end.

flip(F) ->
    fun(B, A) ->
        F(A, B)
    end.

constant(X) ->
    fun(Ignored) ->
        X
    end.

%% interface Pair

'of'(First, Second) ->
    {First, Second}.

first(P) ->
    element(1, P).

second(P) ->
    element(2, P).

swap(P) ->
    {element(2, P), element(1, P)}.

mapFirst(P, Transform) ->
    {Transform(element(1, P)), element(2, P)}.

mapSecond(P, Transform) ->
    {element(1, P), Transform(element(2, P))}.

main() ->
    P = pair:'of'(1, <<"one">>),
    io:format("~p~n", [first(P)]),
    io:format("~p~n", [identity(42)]),
    Inc = compose(fun(X) ->
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

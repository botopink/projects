----- SOURCE CODE -- main.bp
```botopink
fn firstAndRest(xs: Array<i32>) -> #(Array<i32>, ?i32) {
    val head = xs.at(0);
    val rest = xs.slice(1, xs.length);
    return #(rest, head);
}

fn main() {
    val result = firstAndRest([1, 2, 3]);
    val head = result._1;
    @print(head.unwrapOr(-1));
    val empty = firstAndRest([]);
    @print(empty._1 == null);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

firstAndRest(Xs) ->
    Head = Xs:at(0),
    Rest = Xs:slice(1, maps:get(length, Xs)),
    {Rest, Head}.

main() ->
    Result = firstAndRest([1, 2, 3]),
    Head = element(2, Result),
    io:format("~p~n", [(fun(O) -> case O of undefined -> ((-1)); V -> V end end)(Head)]),
    Empty = firstAndRest([]),
    io:format("~p~n", [(element(2, Empty) =:= undefined)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

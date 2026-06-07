----- SOURCE CODE -- main.bp
```botopink
fn checkAll(xs: Array<i32>) -> bool {
    return xs.isEmpty();
}

fn main() {
    @print(checkAll([]));
    @print(checkAll([1]));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% import list

checkAll(Xs) ->
    list:isEmpty(Xs).

main() ->
    io:format("~p~n", [checkAll([])]),
    io:format("~p~n", [checkAll([1])]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

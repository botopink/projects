----- SOURCE CODE -- main.bp
```botopink
*fn fromList<T>(xs: Array<T>) -> @Iterator<T> {
    loop (xs) { item ->
        yield item;
    };
}

*fn doRange(cur: i32, stop: i32) -> @Iterator<i32> {
    if (cur < stop) {
        yield cur;
        return doRange(cur + 1, stop);
    };
}

fn toList<T>(iter: @Iterator<T>) -> Array<T> {
    var out = [];
    loop (iter) { item ->
        out.push(item);
    };
    return out;
}

fn main() {
    @print(toList(fromList([1, 2, 3])).join(","));
    @print(toList(doRange(0, 3)).join(","));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% *fn (async/generator) — eager lowering
fromList(Xs) ->
    lists:map(fun(Item) ->
        Item
    end, Xs).

%% *fn (async/generator) — eager lowering
doRange(Cur, Stop) ->
    case (Cur < Stop) of
        true ->
            Cur,
            doRange((Cur + 1), Stop);
        _ -> ok
    end.

toList(Iter) ->
    Out = [],
    lists:foreach(fun(Item) ->
        Out:push(Item)
    end, Iter),
    Out.

main() ->
    io:format("~p~n", [toList(fromList([1, 2, 3])):join(<<",">>)]),
    io:format("~p~n", [toList(doRange(0, 3)):join(<<",">>)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

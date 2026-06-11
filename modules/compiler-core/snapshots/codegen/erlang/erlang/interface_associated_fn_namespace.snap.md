----- SOURCE CODE -- main.bp
```botopink
interface Pairish<A, B> {
    default fn of(first: A, second: B) -> #(A, B) {
        return #(first, second);
    }
    default fn first(p: #(A, B)) -> A {
        return p._0;
    }
}

fn main() {
    val p = Pairish.of(1, "one");
    @print(Pairish.first(p));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% interface Pairish

'of'(First, Second) ->
    {First, Second}.

first(P) ->
    element(1, P).

main() ->
    P = 'of'(1, <<"one">>),
    io:format("~p~n", [first(P)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
1
```

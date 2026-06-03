----- SOURCE CODE -- main.bp
```botopink
val Swimmer = interface {
    fn swim(self: Self);
}
record Pato { id: i32 }
val PatoNada = implement Swimmer for Pato {
    fn swim(self: Self) {
        return self.id;
    }
}
PatoNada*;
fn main() {
    val donald = Pato(2);
    @print(donald.swim());
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% interface Swimmer

-record(Pato, {id}).

%% implement Swimmer for Pato

swim(Self) ->
    Self_id.

%% activate PatoNada

main() ->
    Donald = Pato(2),
    io:format("~p~n", [swim(Donald)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```

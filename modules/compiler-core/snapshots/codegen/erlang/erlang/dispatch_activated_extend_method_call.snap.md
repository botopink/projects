----- SOURCE CODE -- main.bp
```botopink
record Pato { id: i32 }
val PatoVoa = extend Pato {
    fn fly(self: Self) {
        return self.id;
    }
}
PatoVoa*;
fn main() {
    val donald = Pato(7);
    @print(donald.fly());
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% record Pato: id

%% extend Pato

fly(Self) ->
    maps:get(id, Self).

%% activate PatoVoa

main() ->
    Donald = #{id => 7},
    io:format("~p~n", [fly(Donald)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
7
```

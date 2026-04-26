----- SOURCE CODE -- main.bp
```botopink
fn f() {
    assert [] == [];
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

f() ->
    true = (([] =:= [])).
```

----- RUN LOG -----
```logs
// Erlang execution not yet implemented```

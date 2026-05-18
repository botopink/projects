----- SOURCE CODE -- main.bp
```botopink
fn f() {
    assert true;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

f() ->
    true = (True).
```

----- RUN LOG -----
```logs
Execution error: error.FileNotFound```

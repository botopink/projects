----- SOURCE CODE -- main.bp
```botopink
fn getFirst(t: #(i32, string)) -> i32 {
    return t._0;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

getFirst(T) ->
    T__0.
```

----- RUN LOG -----
```logs
Execution error: error.FileNotFound```

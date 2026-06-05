----- SOURCE CODE -- main.bp
```botopink
fn n() -> i32 {
    val s = "hello";
    return s.len;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

n() ->
    S = <<"hello">>,
    maps:get(len, S).
```

----- RUN LOG -----
```logs
```

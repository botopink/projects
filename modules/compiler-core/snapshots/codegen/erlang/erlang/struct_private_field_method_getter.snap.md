----- SOURCE CODE -- main.bp
```botopink
val Counter = struct {
    _count: i32 = 0,
    fn increment(self: Self) {
        self._count += 1;
    }
    get count(self: Self) -> i32 {
        return self._count;
    }
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

-record(Counter, {_count}).

increment() ->
    %% field assignment is not directly supported in Erlang.
```

----- RUN LOG -----
```logs
Execution error: error.FileNotFound```

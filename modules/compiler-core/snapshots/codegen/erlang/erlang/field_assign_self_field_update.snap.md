----- SOURCE CODE -- main.bp
```botopink
val Counter = struct {
    count: i32 = 0,
    fn inc() {
        self.count += 1;
    }
};
```

----- ERLANG -- main.erl
```erlang
-module(main).

-record(Counter, {count}).

inc() ->
    %% field += not directly supported in Erlang.
```

----- RUN LOG -----
```logs
// Erlang execution not yet implemented```

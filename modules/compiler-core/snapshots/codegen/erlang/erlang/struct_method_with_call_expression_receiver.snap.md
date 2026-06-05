----- SOURCE CODE -- main.bp
```botopink
val Logger = struct {
    _prefix: string = "",
    fn setPrefix(self: Self, p: string) {
        self._prefix = p;
    }
    fn log(self: Self, msg: string) {
        console.log(self._prefix, msg);
    }
    get prefix(self: Self) -> string {
        return self._prefix;
    }
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% struct Logger: _prefix

setPrefix(P) ->
    %% field assignment is not directly supported in Erlang.

log(Msg) ->
    Console:log(maps:get('_prefix', Self), Msg).
```

----- RUN LOG -----
```logs
```

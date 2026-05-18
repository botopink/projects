----- SOURCE CODE -- main.bp
```botopink
loop (0..10) { i ->
    @print(i);
};
```

----- ERLANG -- main.erl
```erlang
-module(main).

_loop() ->
    lists:foreach(fun(I) ->
        io:format("~p~n", [I])
    end, lists:seq(0, 10)).
```

----- RUN LOG -----
```logs
Execution error: error.FileNotFound```

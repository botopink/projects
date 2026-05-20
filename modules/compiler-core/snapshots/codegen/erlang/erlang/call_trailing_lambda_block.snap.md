----- SOURCE CODE -- main.bp
```botopink
fn run() {
    @todo();
}
fn main() {
    run { x ->
        return "done";
    };
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export([_botopink_main/0]).

run() ->
    erlang:error({todo, "not implemented"}).

_botopink_main() ->
    run(fun(X) ->
        <<"done">>
    end).
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
fn calc(factor: i32) -> i32 {
    @todo();
}
fn main() {
    val r = calc(2) { a, b ->
        return 0;
    };
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export([_botopink_main/0]).

calc(Factor) ->
    erlang:error({todo, "not implemented"}).

_botopink_main() ->
    R = calc(2, fun(A, B) ->
        0
    end).
```

----- RUN LOG -----
```logs
```

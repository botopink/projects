----- SOURCE CODE -- main.bp
```botopink
fn main() {
    var #(x, y) = #(10, 20);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export([_botopink_main/0]).

_botopink_main() ->
    {X, Y} = {10, 20}.
```

----- RUN LOG -----
```logs
Execution error: error.FileNotFound```

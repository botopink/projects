----- SOURCE CODE -- main.bp
```botopink
pub fn max(a: i32, b: i32) -> i32 {
    if (a < b) {
        return b;
    } else {
        return a;
    }
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export([max/2]).

max(A, B) ->
    case (A < B) of
        true ->
            B;
        false ->
            A
    end.
```

----- RUN LOG -----
```logs
```

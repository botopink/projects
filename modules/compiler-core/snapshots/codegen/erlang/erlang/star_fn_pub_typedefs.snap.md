----- SOURCE CODE -- main.bp
```botopink
pub *fn loadOne(x: i32) -> @Future<i32> {
    return x;
}
pub *fn count() -> @Iterator<i32> {
    yield 1;
}
pub *fn pulses() -> @AsyncIterator<i32, string> {
    yield 1;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export([loadOne/1, count/0, pulses/0]).

loadOne(X) ->
    X.

count() ->
    1.

pulses() ->
    1.
```

----- RUN LOG -----
```logs
```

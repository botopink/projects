----- SOURCE CODE -- math.bp
```botopink
pub fn double(x: i32) -> i32 {
    return x * 2;
}
```

----- ERLANG -- math.erl
```erlang
-module(math).
-export([double/1]).

double(X) ->
    (X * 2).
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
use {double} = @root()
val result = double(21);
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% use double

result() ->
    double(21).
```

----- RUN LOG -----
```logs
```

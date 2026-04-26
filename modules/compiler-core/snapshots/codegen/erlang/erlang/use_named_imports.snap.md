----- SOURCE CODE -- main.bp
```botopink
use { foo, bar } from "mylib";
```

----- ERLANG -- main.erl
```erlang
-module(main).

-import(mylib, [foo/0, bar/0]).
```

----- RUN LOG -----
```logs
// Erlang execution not yet implemented```

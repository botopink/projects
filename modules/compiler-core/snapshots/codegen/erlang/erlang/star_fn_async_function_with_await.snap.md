----- SOURCE CODE -- main.bp
```botopink
*fn fetch(x: i32) -> @Future<i32> {
    return x;
}
*fn loadTwice(x: i32) -> @Future<i32> {
    val a = await fetch(x);
    return a + a;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

fetch(X) ->
    X.

loadTwice(X) ->
    A = fetch(X),
    (A + A).
```

----- RUN LOG -----
```logs
```

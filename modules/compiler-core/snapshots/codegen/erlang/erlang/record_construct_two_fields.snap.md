----- SOURCE CODE -- main.bp
```botopink
record Point { x: i32, y: i32 }
fn make() -> Point {
    return Point(x: 3, y: 4);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

-record(Point, {x, y}).

make() ->
    Point(3, 4).
```

----- RUN LOG -----
```logs
```

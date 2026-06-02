----- SOURCE CODE -- main.bp
```botopink
enum Shape {
    Circle(r: i32),
    Square(side: i32),
}
fn makeCircle() -> Shape {
    return Shape.Circle(r: 5);
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 4}.

{function, makeCircle, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, makeCircle}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {atom, Shape}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {integer, 5}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 1}, {x, 1}}.
    %% unresolved method call: Circle/2
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```

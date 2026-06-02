----- SOURCE CODE
val Plain = struct { x: i32 }
fn make() -> Plain {
    Plain(x: 0);
}
fn comp() -> @Context<Element, i32> {
    use p = make();
    0;
}

----- ERROR
error: `use` requires @Context
  ┌─ :6:5
  │
6 │     use p = make();
  │     ^

  `Plain` does not implement @Context — `use` requires @Context<_, _>

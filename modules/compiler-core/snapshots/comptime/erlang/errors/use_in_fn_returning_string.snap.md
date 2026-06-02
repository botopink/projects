----- SOURCE CODE
fn state(initial: i32) -> @Context<Element, i32> {
    initial;
}
fn bad() -> string {
    use x = state(0);
    "hi";
}

----- ERROR
error: `use` not allowed
  ┌─ :5:5
  │
5 │     use x = state(0);
  │     ^

  function returns `string` which does not implement @Context

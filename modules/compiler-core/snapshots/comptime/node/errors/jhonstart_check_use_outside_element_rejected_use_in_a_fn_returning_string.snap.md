----- SOURCE CODE
fn state(initial: i32) -> @Context<Element, i32> { initial; }
fn bad() -> string {
    val value = use state(0);
    "nope";
}

----- ERROR
error: `use` not allowed
  ┌─ :3:17
  │
3 │     val value = use state(0);
  │                 ^

  function returns `string` which does not implement @Context

----- SOURCE CODE
fn state(initial: i32) -> @Context<Element, i32> {
    initial;
}
fn connection() -> @Context<Http, i32> {
    0;
}
fn bad() -> @Context<Element, i32> {
    use c = connection();
    state(0);
}

----- ERROR
error: ContextBase mismatch
  ┌─ :8:5
  │
8 │     use c = connection();
  │     ^

  function returns @Context<Element, _>
  but the `use` expression returns @Context<Http, _>

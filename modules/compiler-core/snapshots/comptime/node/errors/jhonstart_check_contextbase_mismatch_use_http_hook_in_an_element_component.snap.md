----- SOURCE CODE
fn state(initial: i32) -> @Context<Element, i32> { initial; }
fn request() -> @Context<Http, i32> { 0; }
fn bad() -> @Context<Element, i32> {
    val r = use request();
    state(0);
}

----- ERROR
error: ContextBase mismatch
  ┌─ :4:13
  │
4 │     val r = use request();
  │             ^

  function returns @Context<Element, _>
  but the `use` expression returns @Context<Http, _>

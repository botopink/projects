----- SOURCE CODE
*fn gen() -> @Iterator<i32> {
    yield :nope 1;
}

----- ERROR
error: `yield` targets an unknown label
  ┌─ :2:5
  │
2 │     yield :nope 1;
  │     ^

  hint: Label a `*fn` (`-> @Iterator<T> :name`) or a `loop :name (...)`.

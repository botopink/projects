----- SOURCE CODE
fn bad() -> @Future<i32> {
    return 0;
}

----- ERROR
error: a function returning `@Future`/`@Iterator`/`@AsyncIterator` must be declared `*fn`
  ┌─ :2:5
  │
2 │     return 0;
  │     ^

  hint: Prefix the function with `*` to make it async/generator.

----- SOURCE CODE
fn notAsync() -> i32 {
    val x = await ready();
    return x;
}

----- ERROR
error: `await` can only be used inside an async `*fn`
  ┌─ :2:13
  │
2 │     val x = await ready();
  │             ^

  hint: Mark the enclosing function `*fn` with a `@Future`/`@AsyncIterator` return type.

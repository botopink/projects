----- SOURCE CODE
*fn bad() -> string {
    return "x";
}

----- ERROR
error: a `*fn` must return `@Future<_>`, `@Iterator<_>` or `@AsyncIterator<_, _>`
  ┌─ :2:5
  │
2 │     return "x";
  │     ^

  hint: Drop the `*` if this is a plain function, or change the return type.

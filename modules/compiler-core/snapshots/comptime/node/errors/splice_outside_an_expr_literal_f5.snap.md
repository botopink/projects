----- SOURCE CODE
pub fn html(comptime template: expr string) -> expr string {
    return ${template};
}

----- ERROR
error: a `${…}` splice is only valid inside an `expr { … }` literal
  ┌─ :2:12
  │
2 │     return ${template};
  │            ^

  hint: Wrap the surrounding code in `expr { … }` — outside quoted code there is nothing to splice into.

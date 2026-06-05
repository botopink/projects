----- SOURCE CODE
pub fn bad(comptime template: expr string) -> expr string {
    return expr { ${"plain string"} };
}

----- ERROR
error: type mismatch
  ┌─ :2:21
  │
2 │     return expr { ${"plain string"} };
  │                     ^

  expected: expr<?>
  found:    string

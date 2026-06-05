----- SOURCE CODE
pub fn bad() -> expr i32 {
    return expr { "not an int" };
}
val d = bad();

----- ERROR
error: type mismatch
  ┌─ :4:9
  │
4 │ val d = bad();
  │         ^

  expected: i32
  found:    string

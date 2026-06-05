----- SOURCE CODE
pub fn check(comptime cond: expr bool) -> expr bool {
    return cond;
}
val c = check("not a bool");

----- ERROR
error: type mismatch
  ┌─ :4:15
  │
4 │ val c = check("not a bool");
  │               ^

  expected: bool
  found:    string

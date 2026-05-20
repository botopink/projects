----- SOURCE CODE
val Color = enum {
    Red,
    Green,
    Blue,
};
val name = fn(c: Color) -> string {
    case c {
        Red -> "red";
    }
};

----- ERROR
error: type mismatch
  ┌─ :7:5
  │
7 │     case c {
  │     ^

  expected: exhaustive
  found:    Color

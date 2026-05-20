----- SOURCE CODE
val categorize = fn(s: string) -> string {
    case s {
        "hello" -> "greeting";
    }
};

----- ERROR
error: type mismatch
  ┌─ :2:5
  │
2 │     case s {
  │     ^

  expected: exhaustive
  found:    string

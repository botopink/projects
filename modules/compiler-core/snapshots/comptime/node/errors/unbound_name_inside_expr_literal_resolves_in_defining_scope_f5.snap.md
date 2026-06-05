----- SOURCE CODE
pub fn quoted() -> expr string {
    return expr { missing_name };
}

----- ERROR
error: unbound variable
  ┌─ :2:19
  │
2 │     return expr { missing_name };
  │                   ^

  'missing_name' is not in scope

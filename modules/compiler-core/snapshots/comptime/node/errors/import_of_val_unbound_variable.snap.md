----- SOURCE CODE
use {SECRET} = @root()
val x = SECRET;

----- ERROR
error: unbound variable
  ┌─ :2:9
  │
2 │ val x = SECRET;
  │         ^

  'SECRET' is not in scope

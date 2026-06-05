----- SOURCE CODE
pub fn hard(comptime t: expr string) -> expr string {
    val x = t.text();
    return t;
}
val c = hard "SELECT 1";

----- ERROR
error: cannot expand this template function at compile time
  ┌─ :5:9
  │
5 │ val c = hard "SELECT 1";
  │         ^

  hint: The V1 expansion driver supports bodies of the form `return <expr param>`, `return expr { … }` (single expression, `${param}` holes), or a splice-free value. Template-method bodies (text/parts/lookup) require the comptime runtime (F6-full).

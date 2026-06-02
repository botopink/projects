----- SOURCE CODE
val Swimmer = interface {
    fn swim(self: Self);
}
record Pato { id: i32 }
val PatoNada = implement Swimmer for Pato {
    fn swim(self: Self) {
        return self.id;
    }
}
val donald = Pato(1);
val r = donald.swim();

----- ERROR
error: method not active
  ┌─ :11:9
  │
11 │ val r = donald.swim();
  │         ^

  'Pato' has no active method 'swim'
  hint: activate the extension with `PatoNada*`

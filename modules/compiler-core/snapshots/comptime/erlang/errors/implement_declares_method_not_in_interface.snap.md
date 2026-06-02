----- SOURCE CODE
val Swimmer = interface {
    fn swim(self: Self);
}
record Pato { id: i32 }
val PatoNada = implement Swimmer for Pato {
    fn swim(self: Self) {
        return self.id;
    }
    fn fly(self: Self) {
        return self.id;
    }
}

----- ERROR
error: method not in interface

  'PatoNada' declares method 'fly' not found in interface 'Swimmer'

----- SOURCE CODE -- pond.bp
```botopink
pub val Swimmer = interface {
    fn swim(self: Self);
}
pub record Pato { id: i32 }
```

----- TYPED AST JSON -- pond.json
```json
{
  "declarations": [
    {
      "ast": "interface_def",
      "name": "Swimmer"
    },
    {
      "ast": "record_def",
      "name": "Pato",
      "id": 0,
      "fields": {
        "id": "i32"
      }
    }
  ]
}
```


----- SOURCE CODE -- main.bp
```botopink
import {Swimmer, Pato} from "pond";
val PatoNada = implement Swimmer for Pato {
    fn swim(self: Self) {
        return self.id;
    }
}
val donald = Pato(1);
val splash = donald.swim();
```


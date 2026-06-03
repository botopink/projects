----- SOURCE CODE -- main.bp
```botopink
record Pato { id: i32 }
val PatoVoa = extend Pato {
    fn fly(self: Self) {
        return self.id;
    }
}
PatoVoa*;
fn main() {
    val donald = Pato(7);
    @print(donald.fly());
}
```

----- JAVASCRIPT -- main.js
```javascript
class Pato {
    constructor(id) {
        this.id = id;
    }
}

// extend Pato
const PatoVoa = {
    fly(self) {
        return self.id;
    },
};



function main() {
    const donald = Pato(7);
    console.log(PatoVoa.fly(donald));
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```

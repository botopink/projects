----- SOURCE CODE -- pond.bp
```botopink
pub val Swimmer = interface {
    fn swim(self: Self);
}
pub record Pato { id: i32 }
```

----- JAVASCRIPT -- pond.js
```javascript
// interface Swimmer
//   fn swim(...)

class Pato {
    constructor(id) {
        this.id = id;
    }
}
```

----- TYPESCRIPT TYPEDEF -- pond.d.ts
```typescript
export declare interface Swimmer {
    swim(): void;
}


export declare class Pato {
    readonly id: i32;
    constructor(id: i32);
}

```

----- RUN LOG -----
```logs
```

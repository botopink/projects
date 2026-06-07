----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val xs: Array<i32> = [];
    @print(xs.isEmpty());
    val ys = [1, 2, 3];
    @print(ys.isEmpty());
    @print(ys.length());
    @print(ys.contains(2));
}
```

----- JAVASCRIPT -- main.js
```javascript
const list = require("./std/list.js");

function main() {
    const xs = [];
    console.log(list.isEmpty(xs));
    const ys = [1, 2, 3];
    console.log(list.isEmpty(ys));
    console.log(list.length(ys));
    console.log(list.contains(ys, 2));
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

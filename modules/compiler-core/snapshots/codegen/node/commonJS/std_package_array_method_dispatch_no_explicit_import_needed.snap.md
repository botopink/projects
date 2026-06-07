----- SOURCE CODE -- main.bp
```botopink
fn checkAll(xs: Array<i32>) -> bool {
    return xs.isEmpty();
}

fn main() {
    @print(checkAll([]));
    @print(checkAll([1]));
}
```

----- JAVASCRIPT -- main.js
```javascript
const list = require("./std/list.js");

function checkAll(xs) {
    return list.isEmpty(xs);
}

function main() {
    console.log(checkAll([]));
    console.log(checkAll([1]));
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

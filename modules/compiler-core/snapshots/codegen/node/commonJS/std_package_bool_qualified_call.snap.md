----- SOURCE CODE -- std/bool.bp
```botopink
//// Gleam-style `bool` module (`import {bool} from "std";`), inspired by
//// `gleam/bool`. Pure-operator logic — no host backing, compiles once for
//// every backend. First real `"std"` package module (qualified calls lower
//// to a per-module output: `out/std/bool.js` / remote `bool:negate/1`).

pub fn negate(b: bool) -> bool {
    return !b;
}

pub fn nor(a: bool, b: bool) -> bool {
    return !(a || b);
}

pub fn nand(a: bool, b: bool) -> bool {
    return !(a && b);
}

pub fn exclusive_or(a: bool, b: bool) -> bool {
    return a != b;
}

pub fn exclusive_nor(a: bool, b: bool) -> bool {
    return a == b;
}

```

----- JAVASCRIPT -- std/bool.js
```javascript
//// Gleam-style `bool` module (`import {bool} from "std";`), inspired by

//// `gleam/bool`. Pure-operator logic — no host backing, compiles once for

//// every backend. First real `"std"` package module (qualified calls lower

//// to a per-module output: `out/std/bool.js` / remote `bool:negate/1`).

function negate(b) {
    return (!b);
}
exports.negate = negate;

function nor(a, b) {
    return (!((a || b)));
}
exports.nor = nor;

function nand(a, b) {
    return (!((a && b)));
}
exports.nand = nand;

function exclusive_or(a, b) {
    return (a !== b);
}
exports.exclusive_or = exclusive_or;

function exclusive_nor(a, b) {
    return (a === b);
}
exports.exclusive_nor = exclusive_nor;
```

----- TYPESCRIPT TYPEDEF -- std/bool.d.ts
```typescript
export declare function negate(b: ): bool;


export declare function nor(a: , b: ): bool;


export declare function nand(a: , b: ): bool;


export declare function exclusive_or(a: , b: ): bool;


export declare function exclusive_nor(a: , b: ): bool;

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {bool} from "std";

fn main() {
    val flipped = bool.negate(false);
    @print(bool.exclusive_or(flipped, false));
}
```

----- JAVASCRIPT -- main.js
```javascript
const bool = require("./std/bool.js");

function main() {
    const flipped = bool.negate(false);
    console.log(bool.exclusive_or(flipped, false));
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
true
```

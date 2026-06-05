----- SOURCE CODE -- std/bool.bp
```botopink
//// Gleam-inspired `bool` module (`import {bool} from "std";`).
//// Pure-operator logic — no host backing, compiles once for every backend.
//// Function names follow the language convention: camelCase.
//// First real `"std"` package module (qualified calls lower to a per-module
//// output: `out/std/bool.js` / remote `bool:negate/1`).

pub fn negate(b: bool) -> bool {
    return !b;
}

pub fn nor(a: bool, b: bool) -> bool {
    return !(a || b);
}

pub fn nand(a: bool, b: bool) -> bool {
    return !(a && b);
}

pub fn exclusiveOr(a: bool, b: bool) -> bool {
    return a != b;
}

pub fn exclusiveNor(a: bool, b: bool) -> bool {
    return a == b;
}

// Zig-style co-located test (stdlib-tests F0: impl modules MAY carry inline
// `test` blocks; excluded from normal builds, run by `botopink test`).
test "inline: negate truth table" {
    assert negate(false);
    assert !negate(true);
}

```

----- JAVASCRIPT -- std/bool.js
```javascript
//// Gleam-inspired `bool` module (`import {bool} from "std";`).

//// Pure-operator logic — no host backing, compiles once for every backend.

//// Function names follow the language convention: camelCase.

//// First real `"std"` package module (qualified calls lower to a per-module

//// output: `out/std/bool.js` / remote `bool:negate/1`).

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

function exclusiveOr(a, b) {
    return (a !== b);
}
exports.exclusiveOr = exclusiveOr;

function exclusiveNor(a, b) {
    return (a === b);
}
exports.exclusiveNor = exclusiveNor;

// Zig-style co-located test (stdlib-tests F0: impl modules MAY carry inline

// `test` blocks; excluded from normal builds, run by `botopink test`).
```

----- TYPESCRIPT TYPEDEF -- std/bool.d.ts
```typescript
export declare function negate(b: ): bool;


export declare function nor(a: , b: ): bool;


export declare function nand(a: , b: ): bool;


export declare function exclusiveOr(a: , b: ): bool;


export declare function exclusiveNor(a: , b: ): bool;

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {bool} from "std";

fn main() {
    val flipped = bool.negate(false);
    @print(bool.exclusiveOr(flipped, false));
}
```

----- JAVASCRIPT -- main.js
```javascript
const bool = require("./std/bool.js");

function main() {
    const flipped = bool.negate(false);
    console.log(bool.exclusiveOr(flipped, false));
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

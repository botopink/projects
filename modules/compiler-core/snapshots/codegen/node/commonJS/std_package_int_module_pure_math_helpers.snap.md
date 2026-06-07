----- SOURCE CODE -- std/int.bp
```botopink
//// Integer utilities module (`import {int} from "std";`).
//// Pure-botopink math helpers for `i32` values. No host backing —
//// compiles once for every backend.
//// Function names follow the language convention: camelCase.

pub fn absoluteValue(n: i32) -> i32 {
    return if (n < 0) { -n; } else { n; };
}

pub fn min(a: i32, b: i32) -> i32 {
    return if (a < b) { a; } else { b; };
}

pub fn max(a: i32, b: i32) -> i32 {
    return if (a > b) { a; } else { b; };
}

pub fn clamp(n: i32, lo: i32, hi: i32) -> i32 {
    return min(max(n, lo), hi);
}

pub fn isEven(n: i32) -> bool {
    return n % 2 == 0;
}

pub fn isOdd(n: i32) -> bool {
    return n % 2 != 0;
}

// NOTE: `to_string` (convert integer to its decimal string representation).
// Botopink coerces numbers to string in `+` contexts — `"" + n` works.
pub fn toString(n: i32) -> string {
    return "" + n;
}

test "inline: absoluteValue" {
    assert absoluteValue(0) == 0;
    assert absoluteValue(3) == 3;
}

test "inline: min and max" {
    assert min(2, 5) == 2;
    assert max(2, 5) == 5;
}

test "inline: clamp in range" {
    assert clamp(3, 0, 5) == 3;
}

test "inline: isEven" {
    assert isEven(4);
    assert !isEven(3);
}

test "inline: isOdd" {
    assert isOdd(7);
    assert !isOdd(8);
}

```

----- JAVASCRIPT -- std/int.js
```javascript
//// Integer utilities module (`import {int} from "std";`).

//// Pure-botopink math helpers for `i32` values. No host backing —

//// compiles once for every backend.

//// Function names follow the language convention: camelCase.

function absoluteValue(n) {
    return (() => { if ((n < 0)) { return (-n); } else { return n; } })();
}
exports.absoluteValue = absoluteValue;

function min(a, b) {
    return (() => { if ((a < b)) { return a; } else { return b; } })();
}
exports.min = min;

function max(a, b) {
    return (() => { if ((a > b)) { return a; } else { return b; } })();
}
exports.max = max;

function clamp(n, lo, hi) {
    return min(max(n, lo), hi);
}
exports.clamp = clamp;

function isEven(n) {
    return ((n % 2) === 0);
}
exports.isEven = isEven;

function isOdd(n) {
    return ((n % 2) !== 0);
}
exports.isOdd = isOdd;

// NOTE: `to_string` (convert integer to its decimal string representation).

// Botopink coerces numbers to string in `+` contexts — `"" + n` works.

function toString(n) {
    return ("" + n);
}
exports.toString = toString;
```

----- TYPESCRIPT TYPEDEF -- std/int.d.ts
```typescript
export declare function absoluteValue(n: ): i32;


export declare function min(a: , b: ): i32;


export declare function max(a: , b: ): i32;


export declare function clamp(n: , lo: , hi: ): i32;


export declare function isEven(n: ): bool;


export declare function isOdd(n: ): bool;


export declare function toString(n: ): string;

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {int} from "std";

fn main() {
    @print(int.absoluteValue(5));
    @print(int.min(3, 7));
    @print(int.max(3, 7));
    @print(int.clamp(10, 0, 5));
    @print(int.isEven(4));
    @print(int.isOdd(3));
    @print(int.toString(42));
}
```

----- JAVASCRIPT -- main.js
```javascript
const int = require("./std/int.js");

function main() {
    console.log(int.absoluteValue(5));
    console.log(int.min(3, 7));
    console.log(int.max(3, 7));
    console.log(int.clamp(10, 0, 5));
    console.log(int.isEven(4));
    console.log(int.isOdd(3));
    console.log(int.toString(42));
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
5
3
7
5
true
true
42
```

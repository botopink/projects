----- SOURCE CODE -- std/float.bp
```botopink
//// Float utilities module (`import {float} from "std";`).
//// Math helpers for `f64` values. Host-backed for rounding primitives.
//// Function names follow the language convention: camelCase.

pub fn absoluteValue(n: f64) -> f64 {
    return if (n < 0.0) { -n; } else { n; };
}

pub fn min(a: f64, b: f64) -> f64 {
    return if (a < b) { a; } else { b; };
}

pub fn max(a: f64, b: f64) -> f64 {
    return if (a > b) { a; } else { b; };
}

pub fn clamp(n: f64, lo: f64, hi: f64) -> f64 {
    return min(max(n, lo), hi);
}

#[@external(erlang, "math", "floor"),
  @external(node, "Math", "floor")]
pub declare fn floor(n: f64) -> f64;

#[@external(erlang, "math", "ceil"),
  @external(node, "Math", "ceil")]
pub declare fn ceiling(n: f64) -> f64;

#[@external(erlang, "math", "round"),
  @external(node, "Math", "round")]
pub declare fn round(n: f64) -> f64;

#[@external(erlang, "math", "sqrt"),
  @external(node, "Math", "sqrt")]
pub declare fn squareRoot(n: f64) -> f64;

// NOTE: `toString` for floats — coerces via string concat.
pub fn toString(n: f64) -> string {
    return "" + n;
}

test "float absoluteValue" {
    assert absoluteValue(0.0) == 0.0;
    assert absoluteValue(-3.5) == 3.5;
    assert absoluteValue(2.1) == 2.1;
}

test "float min and max" {
    assert min(1.5, 2.5) == 1.5;
    assert max(1.5, 2.5) == 2.5;
}

test "float clamp" {
    assert clamp(3.0, 0.0, 5.0) == 3.0;
    assert clamp(-1.0, 0.0, 5.0) == 0.0;
    assert clamp(9.9, 0.0, 5.0) == 5.0;
}

test "float toString" {
    assert toString(1.5) == "1.5";
}

```

----- JAVASCRIPT -- std/float.js
```javascript
//// Float utilities module (`import {float} from "std";`).

//// Math helpers for `f64` values. Host-backed for rounding primitives.

//// Function names follow the language convention: camelCase.

function absoluteValue(n) {
    return (() => { if ((n < 0.0)) { return (-n); } else { return n; } })();
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

const floor = Math.floor;
exports.floor = floor;

const ceiling = Math.ceil;
exports.ceiling = ceiling;

const round = Math.round;
exports.round = round;

const squareRoot = Math.sqrt;
exports.squareRoot = squareRoot;

// NOTE: `toString` for floats — coerces via string concat.

function toString(n) {
    return ("" + n);
}
exports.toString = toString;
```

----- TYPESCRIPT TYPEDEF -- std/float.d.ts
```typescript
export declare function absoluteValue(n: ): f64;


export declare function min(a: , b: ): f64;


export declare function max(a: , b: ): f64;


export declare function clamp(n: , lo: , hi: ): f64;


export declare function floor(n: ): f64;


export declare function ceiling(n: ): f64;


export declare function round(n: ): f64;


export declare function squareRoot(n: ): f64;


export declare function toString(n: ): string;

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {float} from "std";

fn main() {
    @print(float.absoluteValue(2.5));
    @print(float.min(1.5, 2.5));
    @print(float.max(1.5, 2.5));
    @print(float.clamp(3.0, 0.0, 5.0));
    @print(float.toString(3.14));
    @print(float.floor(2.9));
    @print(float.ceiling(2.1));
    @print(float.round(2.5));
    @print(float.squareRoot(9.0));
}
```

----- JAVASCRIPT -- main.js
```javascript
const float = require("./std/float.js");

function main() {
    console.log(float.absoluteValue(2.5));
    console.log(float.min(1.5, 2.5));
    console.log(float.max(1.5, 2.5));
    console.log(float.clamp(3.0, 0.0, 5.0));
    console.log(float.toString(3.14));
    console.log(float.floor(2.9));
    console.log(float.ceiling(2.1));
    console.log(float.round(2.5));
    console.log(float.squareRoot(9.0));
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
2.5
1.5
2.5
3
3.14
2
3
3
3
```

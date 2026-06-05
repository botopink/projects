----- SOURCE CODE -- std/pair.bp
```botopink
//// Gleam-style `pair` module (`import {pair} from "std";`), inspired by
//// `gleam/pair`. A pair IS a 2-tuple `#(a, b)` (same as Gleam) — structural,
//// so no generic-record instantiation is involved. Pure logic, compiles once
//// for every backend.

// NOTE: named `of` (not `new`) — `new` is a reserved keyword.
pub fn of<A, B>(first: A, second: B) -> #(A, B) {
    return #(first, second);
}

pub fn first<A, B>(p: #(A, B)) -> A {
    return p._0;
}

pub fn second<A, B>(p: #(A, B)) -> B {
    return p._1;
}

pub fn swap<A, B>(p: #(A, B)) -> #(B, A) {
    return #(p._1, p._0);
}

pub fn mapFirst<A, B, C>(p: #(A, B), transform: fn(value: A) -> C) -> #(C, B) {
    return #(transform(p._0), p._1);
}

pub fn mapSecond<A, B, C>(p: #(A, B), transform: fn(value: B) -> C) -> #(A, C) {
    return #(p._0, transform(p._1));
}

```

----- JAVASCRIPT -- std/pair.js
```javascript
//// Gleam-style `pair` module (`import {pair} from "std";`), inspired by

//// `gleam/pair`. A pair IS a 2-tuple `#(a, b)` (same as Gleam) — structural,

//// so no generic-record instantiation is involved. Pure logic, compiles once

//// for every backend.

// NOTE: named `of` (not `new`) — `new` is a reserved keyword.

function of(first, second) {
    return [first, second];
}
exports.of = of;

function first(p) {
    return p[0];
}
exports.first = first;

function second(p) {
    return p[1];
}
exports.second = second;

function swap(p) {
    return [p[1], p[0]];
}
exports.swap = swap;

function mapFirst(p, transform) {
    return [transform(p[0]), p[1]];
}
exports.mapFirst = mapFirst;

function mapSecond(p, transform) {
    return [p[0], transform(p[1])];
}
exports.mapSecond = mapSecond;
```

----- TYPESCRIPT TYPEDEF -- std/pair.d.ts
```typescript
export declare function of(first: , second: ): [A, B];


export declare function first(p: ): A;


export declare function second(p: ): B;


export declare function swap(p: ): [B, A];


export declare function mapFirst(p: , transform: fn): [C, B];


export declare function mapSecond(p: , transform: fn): [A, C];

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {pair} from "std";

fn main() {
    val p = pair.of(1, "one");
    val q = pair.swap(p);
    @print(pair.first(q));
    @print(pair.second(q));
}
```

----- JAVASCRIPT -- main.js
```javascript
const pair = require("./std/pair.js");

function main() {
    const p = pair.of(1, "one");
    const q = pair.swap(p);
    console.log(pair.first(q));
    console.log(pair.second(q));
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
one
1
```

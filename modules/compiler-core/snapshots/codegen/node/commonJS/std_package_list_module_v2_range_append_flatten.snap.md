----- SOURCE CODE -- std/list.bp
```botopink
//// Gleam-inspired `list` module (`import {list} from "std";`), built over
//// the builtin `Array<T>`. Pure logic — transforms delegate to the builtin
//// Array methods; `fold` drives a mutable accumulator through `forEach`.
//// Function names follow the language convention: camelCase.

pub fn length<T>(xs: Array<T>) -> i32 {
    return xs.length;
}

pub fn isEmpty<T>(xs: Array<T>) -> bool {
    return xs.length == 0;
}

pub fn contains<T>(xs: Array<T>, x: T) -> bool {
    return xs.indexOf(x) != -1;
}

pub fn first<T>(xs: Array<T>) -> ?T {
    return xs.at(0);
}

pub fn rest<T>(xs: Array<T>) -> Array<T> {
    return xs.slice(1, xs.length);
}

pub fn take<T>(xs: Array<T>, n: i32) -> Array<T> {
    return xs.slice(0, n);
}

pub fn drop<T>(xs: Array<T>, n: i32) -> Array<T> {
    return xs.slice(n, xs.length);
}

pub fn reverse<T>(xs: Array<T>) -> Array<T> {
    return xs.reverse();
}

pub fn map<T, U>(xs: Array<T>, transform: fn(item: T) -> U) -> Array<U> {
    return xs.map(transform);
}

pub fn filter<T>(xs: Array<T>, keep: fn(item: T) -> bool) -> Array<T> {
    return xs.filter(keep);
}

pub fn fold<T, A>(xs: Array<T>, initial: A, f: fn(acc: A, item: T) -> A) -> A {
    var acc = initial;
    xs.forEach({ x -> acc = f(acc, x); });
    return acc;
}

pub fn all<T>(xs: Array<T>, pred: fn(item: T) -> bool) -> bool {
    return xs.filter(pred).length == xs.length;
}

pub fn any<T>(xs: Array<T>, pred: fn(item: T) -> bool) -> bool {
    return xs.filter(pred).length != 0;
}

pub fn find<T>(xs: Array<T>, pred: fn(item: T) -> bool) -> ?T {
    return xs.filter(pred).at(0);
}

pub fn count<T>(xs: Array<T>, pred: fn(item: T) -> bool) -> i32 {
    return xs.filter(pred).length;
}

pub fn append<T>(xs: Array<T>, ys: Array<T>) -> Array<T> {
    var out = [];  // no annotation — body `val: Array<T>` resolves T as a NAMED type (gap)
    xs.forEach({ x -> out.push(x); });
    ys.forEach({ y -> out.push(y); });
    return out;
}

pub fn prepend<T>(xs: Array<T>, x: T) -> Array<T> {
    var out = [x];
    xs.forEach({ item -> out.push(item); });
    return out;
}

// Helper (not exported): append every item of `xs` onto `out` in place.
// Kept top-level — nested trailing lambdas inside a lambda body do not
// parse yet (catalogued parser gap).
fn pushAll<T>(out: Array<T>, xs: Array<T>) {
    xs.forEach({ x -> out.push(x); });
}

// Inverted condition — a bare `return;` does not parse yet (catalogued
// parser gap), so the recursion guards by only descending while `start < stop`.
fn pushRange(out: Array<i32>, start: i32, stop: i32) {
    if (start < stop) {
        out.push(start);
        pushRange(out, start + 1, stop);
    };
}

pub fn flatten<T>(xss: Array<Array<T>>) -> Array<T> {
    var out = [];  // no annotation — body `val: Array<T>` resolves T as a NAMED type (gap)
    xss.forEach({ inner -> pushAll(out, inner); });
    return out;
}

// NOTE: the transform is typed `-> V` (a bare generic) — fn-type returns
// must be plain names (parser limit, same note as the old option module);
// `V` unifies with the produced `Array<U>` at the call site.
pub fn flatMap<T, U, V>(xs: Array<T>, transform: fn(item: T) -> V) -> Array<U> {
    return flatten(xs.map(transform));
}

// `range(start, stop)` — half-open `[start, stop)`. NOTE: params are not
// named `from`/`to` — `from` is a reserved keyword.
pub fn range(start: i32, stop: i32) -> Array<i32> {
    var out = [];
    pushRange(out, start, stop);
    return out;
}


```

----- JAVASCRIPT -- std/list.js
```javascript
//// Gleam-inspired `list` module (`import {list} from "std";`), built over

//// the builtin `Array<T>`. Pure logic — transforms delegate to the builtin

//// Array methods; `fold` drives a mutable accumulator through `forEach`.

//// Function names follow the language convention: camelCase.

function length(xs) {
    return xs.length;
}
exports.length = length;

function isEmpty(xs) {
    return (xs.length === 0);
}
exports.isEmpty = isEmpty;

function contains(xs, x) {
    return (xs.indexOf(x) !== (-1));
}
exports.contains = contains;

function first(xs) {
    return xs.at(0);
}
exports.first = first;

function rest(xs) {
    return xs.slice(1, xs.length);
}
exports.rest = rest;

function take(xs, n) {
    return xs.slice(0, n);
}
exports.take = take;

function drop(xs, n) {
    return xs.slice(n, xs.length);
}
exports.drop = drop;

function reverse(xs) {
    return xs.reverse();
}
exports.reverse = reverse;

function map(xs, transform) {
    return xs.map(transform);
}
exports.map = map;

function filter(xs, keep) {
    return xs.filter(keep);
}
exports.filter = filter;

function fold(xs, initial, f) {
    let acc = initial;
    xs.forEach((x) => {
    acc = f(acc, x);
});
    return acc;
}
exports.fold = fold;

function all(xs, pred) {
    return (xs.filter(pred).length === xs.length);
}
exports.all = all;

function any(xs, pred) {
    return (xs.filter(pred).length !== 0);
}
exports.any = any;

function find(xs, pred) {
    return xs.filter(pred).at(0);
}
exports.find = find;

function count(xs, pred) {
    return xs.filter(pred).length;
}
exports.count = count;

function append(xs, ys) {
    let out = [];
    // no annotation — body `val: Array<T>` resolves T as a NAMED type (gap);
    xs.forEach((x) => {
    return out.push(x);
});
    ys.forEach((y) => {
    return out.push(y);
});
    return out;
}
exports.append = append;

function prepend(xs, x) {
    let out = [x];
    xs.forEach((item) => {
    return out.push(item);
});
    return out;
}
exports.prepend = prepend;

// Helper (not exported): append every item of `xs` onto `out` in place.

// Kept top-level — nested trailing lambdas inside a lambda body do not

// parse yet (catalogued parser gap).

function pushAll(out, xs) {
    xs.forEach((x) => {
    return out.push(x);
});
}

// Inverted condition — a bare `return;` does not parse yet (catalogued

// parser gap), so the recursion guards by only descending while `start < stop`.

function pushRange(out, start, stop) {
    (() => { if ((start < stop)) { out.push(start); return pushRange(out, (start + 1), stop); } })();
}

function flatten(xss) {
    let out = [];
    // no annotation — body `val: Array<T>` resolves T as a NAMED type (gap);
    xss.forEach((inner) => {
    return pushAll(out, inner);
});
    return out;
}
exports.flatten = flatten;

// NOTE: the transform is typed `-> V` (a bare generic) — fn-type returns

// must be plain names (parser limit, same note as the old option module);

// `V` unifies with the produced `Array<U>` at the call site.

function flatMap(xs, transform) {
    return flatten(xs.map(transform));
}
exports.flatMap = flatMap;

// `range(start, stop)` — half-open `[start, stop)`. NOTE: params are not

// named `from`/`to` — `from` is a reserved keyword.

function range(start, stop) {
    let out = [];
    pushRange(out, start, stop);
    return out;
}
exports.range = range;
```

----- TYPESCRIPT TYPEDEF -- std/list.d.ts
```typescript
export declare function length(xs: ): i32;


export declare function isEmpty(xs: ): bool;


export declare function contains(xs: , x: ): bool;


export declare function first(xs: ): T | null;


export declare function rest(xs: ): Array<T>;


export declare function take(xs: , n: ): Array<T>;


export declare function drop(xs: , n: ): Array<T>;


export declare function reverse(xs: ): Array<T>;


export declare function map(xs: , transform: fn): Array<U>;


export declare function filter(xs: , keep: fn): Array<T>;


export declare function fold(xs: , initial: , f: fn): A;


export declare function all(xs: , pred: fn): bool;


export declare function any(xs: , pred: fn): bool;


export declare function find(xs: , pred: fn): T | null;


export declare function count(xs: , pred: fn): i32;


export declare function append(xs: , ys: ): Array<T>;


export declare function prepend(xs: , x: ): Array<T>;






export declare function flatten(xss: ): Array<T>;


export declare function flatMap(xs: , transform: fn): Array<U>;


export declare function range(start: , stop: ): Array<i32>;

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {list} from "std";

fn main() {
    @print(list.range(1, 5).join(","));
    @print(list.append([1, 2], [3, 4]).join(","));
    @print(list.prepend([2, 3], 1).join(","));
    @print(list.flatten([[1, 2], [3]]).join(","));
    @print(list.count(list.range(0, 10), { x -> x > 6 }));
}
```

----- JAVASCRIPT -- main.js
```javascript
const list = require("./std/list.js");

function main() {
    console.log(list.range(1, 5).join(","));
    console.log(list.append([1, 2], [3, 4]).join(","));
    console.log(list.prepend([2, 3], 1).join(","));
    console.log(list.flatten([[1, 2], [3]]).join(","));
    console.log(list.count(list.range(0, 10), (x) => {
    return (x > 6);
}));
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
1,2,3,4
1,2,3,4
1,2,3
1,2,3
3
```

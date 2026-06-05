----- SOURCE CODE -- std/list.bp
```botopink
//// Gleam-style `list` module (`import {list} from "std";`), inspired by
//// `gleam/list`, built over the builtin `Array<T>`. Pure logic — transforms
//// delegate to the builtin Array methods; `fold` drives a mutable
//// accumulator through `forEach`.

pub fn length<T>(xs: Array<T>) -> i32 {
    return xs.length;
}

pub fn is_empty<T>(xs: Array<T>) -> bool {
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

```

----- JAVASCRIPT -- std/list.js
```javascript
//// Gleam-style `list` module (`import {list} from "std";`), inspired by

//// `gleam/list`, built over the builtin `Array<T>`. Pure logic — transforms

//// delegate to the builtin Array methods; `fold` drives a mutable

//// accumulator through `forEach`.

function length(xs) {
    return xs.length;
}
exports.length = length;

function is_empty(xs) {
    return (xs.length === 0);
}
exports.is_empty = is_empty;

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
```

----- TYPESCRIPT TYPEDEF -- std/list.d.ts
```typescript
export declare function length(xs: ): i32;


export declare function is_empty(xs: ): bool;


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

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {list} from "std";

fn main() {
    val xs = [1, 2, 3, 4];
    val doubled = list.map(xs, { x -> x * 2 });
    @print(list.fold(doubled, 0, { acc, x -> acc + x }));
    @print(list.length(list.filter(xs, { x -> x > 2 })));
    @print(list.contains(xs, 3));
    @print(list.take(xs, 2).join(","));
}
```

----- JAVASCRIPT -- main.js
```javascript
const list = require("./std/list.js");

function main() {
    const xs = [1, 2, 3, 4];
    const doubled = list.map(xs, (x) => {
    return (x * 2);
});
    console.log(list.fold(doubled, 0, (acc, x) => {
    return (acc + x);
}));
    console.log(list.length(list.filter(xs, (x) => {
    return (x > 2);
})));
    console.log(list.contains(xs, 3));
    console.log(list.take(xs, 2).join(","));
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
20
2
true
1,2
```

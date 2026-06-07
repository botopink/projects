----- SOURCE CODE -- std/iterator.bp
```botopink
//// Lazy iterator utilities module (`import {iterator} from "std";`).
//// Built on botopink's `*fn` / `@Iterator<T>` generator mechanism.
//// Function names follow the language convention: camelCase.
////
//// Lazy producers: range, repeat, fromList.
//// Eager consumers (return Array): map, filter, take, toList.
//// Pure fold: fold.
////
//// NOTE: `fromList` is a `*fn` generator; the JS codegen emits `.map()`
//// for `loop { yield }` bodies, which is broken for non-Array iterables.
//// Known gap — tracked in TODO.md. Use `loop (array) { … }` directly.

// Internal recursive helper: yields integers [cur, stop).
*fn doRange(cur: i32, stop: i32) -> @Iterator<i32> {
    if (cur < stop) {
        yield cur;
        return doRange(cur + 1, stop);
    };
}

// `range(start, stop)` — half-open `[start, stop)`, yields lazily.
pub *fn range(start: i32, stop: i32) -> @Iterator<i32> {
    return doRange(start, stop);
}

// `repeat(value, times)` — yields `value` exactly `times` times, lazily.
*fn doRepeat<T>(value: T, remaining: i32) -> @Iterator<T> {
    if (remaining > 0) {
        yield value;
        return doRepeat(value, remaining - 1);
    };
}

pub *fn repeat<T>(value: T, times: i32) -> @Iterator<T> {
    return doRepeat(value, times);
}

// `fromList(xs)` — wrap an Array as a lazy @Iterator<T>.
// NOTE: JS codegen converts loop+yield to .map(); the generator yields
// nothing at runtime. Use `loop (array) { item -> … }` for eager iteration.
pub *fn fromList<T>(xs: Array<T>) -> @Iterator<T> {
    loop (xs) { item ->
        yield item;
    };
}

// `toList(iter)` — eagerly collect an @Iterator<T> into Array<T>.
pub fn toList<T>(iter: @Iterator<T>) -> Array<T> {
    var out = [];
    loop (iter) { item ->
        out.push(item);
    };
    return out;
}

// `fold(iter, initial, f)` — reduce an iterator to a single accumulator value.
pub fn fold<T, A>(iter: @Iterator<T>, initial: A, f: fn(acc: A, item: T) -> A) -> A {
    var acc = initial;
    loop (iter) { item ->
        acc = f(acc, item);
    };
    return acc;
}

// `map(iter, f)` — apply `f` to each item, return eager Array<U>.
pub fn map<T, U>(iter: @Iterator<T>, f: fn(item: T) -> U) -> Array<U> {
    var out = [];
    loop (iter) { item ->
        val v = f(item);
        out.push(v);
    };
    return out;
}

// `filter(iter, pred)` — keep items matching `pred`, return eager Array<T>.
pub fn filter<T>(iter: @Iterator<T>, pred: fn(item: T) -> bool) -> Array<T> {
    var out = [];
    loop (iter) { item ->
        if (pred(item)) { out.push(item); };
    };
    return out;
}

// `take(iter, n)` — first n items as eager Array<T>.
pub fn take<T>(iter: @Iterator<T>, n: i32) -> Array<T> {
    var out = [];
    var count = 0;
    loop (iter) { item ->
        if (count < n) { out.push(item); };
        count = count + 1;
    };
    return out;
}

```

----- JAVASCRIPT -- std/iterator.js
```javascript
//// Lazy iterator utilities module (`import {iterator} from "std";`).

//// Built on botopink's `*fn` / `@Iterator<T>` generator mechanism.

//// Function names follow the language convention: camelCase.

//// 

//// Lazy producers: range, repeat, fromList.

//// Eager consumers (return Array): map, filter, take, toList.

//// Pure fold: fold.

//// 

//// NOTE: `fromList` is a `*fn` generator; the JS codegen emits `.map()`

//// for `loop { yield }` bodies, which is broken for non-Array iterables.

//// Known gap — tracked in TODO.md. Use `loop (array) { … }` directly.

// Internal recursive helper: yields integers [cur, stop).

function* doRange(cur, stop) {
     if ((cur < stop)) { yield cur; return doRange((cur + 1), stop); };
}

// `range(start, stop)` — half-open `[start, stop)`, yields lazily.

function* range(start, stop) {
    return doRange(start, stop);
}
exports.range = range;

// `repeat(value, times)` — yields `value` exactly `times` times, lazily.

function* doRepeat(value, remaining) {
     if ((remaining > 0)) { yield value; return doRepeat(value, (remaining - 1)); };
}

function* repeat(value, times) {
    return doRepeat(value, times);
}
exports.repeat = repeat;

// `fromList(xs)` — wrap an Array as a lazy @Iterator<T>.

// NOTE: JS codegen converts loop+yield to .map(); the generator yields

// nothing at runtime. Use `loop (array) { item -> … }` for eager iteration.

function* fromList(xs) {
    xs.map((item) => {
    return item;
});
}
exports.fromList = fromList;

// `toList(iter)` — eagerly collect an @Iterator<T> into Array<T>.

function toList(iter) {
    let out = [];
    for (const item of iter) {
    out.push(item);
};
    return out;
}
exports.toList = toList;

// `fold(iter, initial, f)` — reduce an iterator to a single accumulator value.

function fold(iter, initial, f) {
    let acc = initial;
    for (const item of iter) {
    acc = f(acc, item);
};
    return acc;
}
exports.fold = fold;

// `map(iter, f)` — apply `f` to each item, return eager Array<U>.

function map(iter, f) {
    let out = [];
    for (const item of iter) {
    const v = f(item);
    out.push(v);
};
    return out;
}
exports.map = map;

// `filter(iter, pred)` — keep items matching `pred`, return eager Array<T>.

function filter(iter, pred) {
    let out = [];
    for (const item of iter) {
    (() => { if (pred(item)) { return out.push(item); } })();
};
    return out;
}
exports.filter = filter;

// `take(iter, n)` — first n items as eager Array<T>.

function take(iter, n) {
    let out = [];
    let count = 0;
    for (const item of iter) {
    (() => { if ((count < n)) { return out.push(item); } })();
    count = (count + 1);
};
    return out;
}
exports.take = take;
```

----- TYPESCRIPT TYPEDEF -- std/iterator.d.ts
```typescript


export declare function range(start: , stop: ): IterableIterator<i32>;




export declare function repeat(value: , times: ): IterableIterator<T>;


export declare function fromList(xs: ): IterableIterator<T>;


export declare function toList(iter: ): Array<T>;


export declare function fold(iter: , initial: , f: fn): A;


export declare function map(iter: , f: fn): Array<U>;


export declare function filter(iter: , pred: fn): Array<T>;


export declare function take(iter: , n: ): Array<T>;

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {iterator} from "std";

fn main() {
    val gen = iterator.range(0, 3);
    val gen2 = iterator.repeat(42, 2);
}
```

----- JAVASCRIPT -- main.js
```javascript
const iterator = require("./std/iterator.js");

function main() {
    const gen = iterator.range(0, 3);
    const gen2 = iterator.repeat(42, 2);
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

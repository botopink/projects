----- SOURCE CODE -- std/iterator.bp
```botopink
//// Lazy iterator utilities module (`import {iterator} from "std";`).
//// Built on botopink's `*fn` / `@Iterator<T>` generator mechanism.
//// Function names follow the language convention: camelCase.
////
//// NOTE: higher-order ops (map/filter/fold) require consuming an iterator
//// via `loop (iter) { ... }` which is the iteration form in botopink.
//// Use the `list` module for eager transforms on arrays.

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

```

----- JAVASCRIPT -- std/iterator.js
```javascript
//// Lazy iterator utilities module (`import {iterator} from "std";`).

//// Built on botopink's `*fn` / `@Iterator<T>` generator mechanism.

//// Function names follow the language convention: camelCase.

//// 

//// NOTE: higher-order ops (map/filter/fold) require consuming an iterator

//// via `loop (iter) { ... }` which is the iteration form in botopink.

//// Use the `list` module for eager transforms on arrays.

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
```

----- TYPESCRIPT TYPEDEF -- std/iterator.d.ts
```typescript


export declare function range(start: , stop: ): IterableIterator<i32>;




export declare function repeat(value: , times: ): IterableIterator<T>;

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

----- SOURCE CODE -- std/iterator.bp
```botopink
//// Lazy iterator utilities module (`import {iterator} from "std";`).
//// Built on botopink's `*fn` / `@Iterator<T>` generator mechanism.
//// Function names follow the language convention: camelCase.
////
//// Lazy producers: range, repeat, fromList.
//// Eager consumers (return Array): map, filter, take, toList.
//// Pure fold: fold.

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

----- WASM TEXT -- std/iterator.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  ;; Lazy iterator utilities module (`import {iterator} from "std";`).
  ;; Built on botopink's `*fn` / `@Iterator<T>` generator mechanism.
  ;; Function names follow the language convention: camelCase.
  ;; 
  ;; Lazy producers: range, repeat, fromList.
  ;; Eager consumers (return Array): map, filter, take, toList.
  ;; Pure fold: fold.
  ;; Internal recursive helper: yields integers [cur, stop).
  ;; *fn (async/generator) — eager lowering
  (func $doRange (param $cur i32) (param $stop i32) (result i32)
    local.get $cur
    local.get $stop
    i32.lt_s
    (if (result i32)
      (then
    local.get $cur
    local.get $cur
    i32.const 1
    i32.add
    local.get $stop
    call $doRange
    return
      )
      (else
        i32.const 0
      )
    )
  )
  ;; `range(start, stop)` — half-open `[start, stop)`, yields lazily.
  ;; *fn (async/generator) — eager lowering
  (func $range (export "range") (param $start i32) (param $stop i32) (result i32)
    local.get $start
    local.get $stop
    call $doRange
    return
  )
  ;; `repeat(value, times)` — yields `value` exactly `times` times, lazily.
  ;; *fn (async/generator) — eager lowering
  (func $doRepeat (param $value i32) (param $remaining i32) (result i32)
    local.get $remaining
    i32.const 0
    i32.gt_s
    (if (result i32)
      (then
    local.get $value
    local.get $value
    local.get $remaining
    i32.const 1
    i32.sub
    call $doRepeat
    return
      )
      (else
        i32.const 0
      )
    )
  )
  ;; *fn (async/generator) — eager lowering
  (func $repeat (export "repeat") (param $value i32) (param $times i32) (result i32)
    local.get $value
    local.get $times
    call $doRepeat
    return
  )
  ;; `fromList(xs)` — wrap an Array as a lazy @Iterator<T>.
  ;; *fn (async/generator) — eager lowering
  (func $fromList (export "fromList") (param $xs i32) (result i32)
    i32.const 0 ;; loop over non-range
  )
  ;; `toList(iter)` — eagerly collect an @Iterator<T> into Array<T>.
  (func $toList (export "toList") (param $iter i32) (result i32)
    (local $__mem0 i32)
    (local $out i32)
    global.get $__heap_ptr
    local.set $__mem0
    local.get $__mem0
    local.set $out
    i32.const 0 ;; loop over non-range
    drop
    local.get $out
    return
  )
  ;; `fold(iter, initial, f)` — reduce an iterator to a single accumulator value.
  (func $fold (export "fold") (param $iter i32) (param $initial i32) (param $f i32) (result i32)
    (local $acc i32)
    local.get $initial
    local.set $acc
    i32.const 0 ;; loop over non-range
    drop
    local.get $acc
    return
  )
  ;; `map(iter, f)` — apply `f` to each item, return eager Array<U>.
  (func $map (export "map") (param $iter i32) (param $f i32) (result i32)
    (local $__mem0 i32)
    (local $out i32)
    global.get $__heap_ptr
    local.set $__mem0
    local.get $__mem0
    local.set $out
    i32.const 0 ;; loop over non-range
    drop
    local.get $out
    return
  )
  ;; `filter(iter, pred)` — keep items matching `pred`, return eager Array<T>.
  (func $filter (export "filter") (param $iter i32) (param $pred i32) (result i32)
    (local $__mem0 i32)
    (local $out i32)
    global.get $__heap_ptr
    local.set $__mem0
    local.get $__mem0
    local.set $out
    i32.const 0 ;; loop over non-range
    drop
    local.get $out
    return
  )
  ;; `take(iter, n)` — first n items as eager Array<T>.
  (func $take (export "take") (param $iter i32) (param $n i32) (result i32)
    (local $__mem0 i32)
    (local $out i32)
    (local $count i32)
    global.get $__heap_ptr
    local.set $__mem0
    local.get $__mem0
    local.set $out
    i32.const 0
    local.set $count
    i32.const 0 ;; loop over non-range
    drop
    local.get $out
    return
  )
)
```

----- RUN LOG -----
```logs
Execution error: error.FileNotFound```

----- SOURCE CODE -- main.bp
```botopink
import {iterator} from "std";

fn main() {
    val gen = iterator.range(0, 3);
    val gen2 = iterator.repeat(42, 2);
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $main
    (local $gen i32)
    (local $gen2 i32)
    i32.const 0
    i32.const 3
    call $range
    local.set $gen
    i32.const 42
    i32.const 2
    call $repeat
    local.set $gen2
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
)
```

----- RUN LOG -----
```logs
```

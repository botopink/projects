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

----- WASM TEXT -- std/iterator.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  ;; Lazy iterator utilities module (`import {iterator} from "std";`).
  ;; Built on botopink's `*fn` / `@Iterator<T>` generator mechanism.
  ;; Function names follow the language convention: camelCase.
  ;; 
  ;; NOTE: higher-order ops (map/filter/fold) require consuming an iterator
  ;; via `loop (iter) { ... }` which is the iteration form in botopink.
  ;; Use the `list` module for eager transforms on arrays.
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

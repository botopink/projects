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

----- WASM TEXT -- std/float.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\00\00\00\00")
  (global $__heap_ptr (mut i32) (i32.const 260))
  ;; Float utilities module (`import {float} from "std";`).
  ;; Math helpers for `f64` values. Host-backed for rounding primitives.
  ;; Function names follow the language convention: camelCase.
  (func $absoluteValue (export "absoluteValue") (param $n f64) (result f64)
    local.get $n
    f32.const 0.0
    i32.lt_s
    (if (result f64)
      (then
    i32.const 0
    local.get $n
    i32.sub
      )
      (else
    local.get $n
      )
    )
    return
  )
  (func $min (export "min") (param $a f64) (param $b f64) (result f64)
    local.get $a
    local.get $b
    i32.lt_s
    (if (result f64)
      (then
    local.get $a
      )
      (else
    local.get $b
      )
    )
    return
  )
  (func $max (export "max") (param $a f64) (param $b f64) (result f64)
    local.get $a
    local.get $b
    i32.gt_s
    (if (result f64)
      (then
    local.get $a
      )
      (else
    local.get $b
      )
    )
    return
  )
  (func $clamp (export "clamp") (param $n f64) (param $lo f64) (param $hi f64) (result f64)
    local.get $n
    local.get $lo
    call $max
    local.get $hi
    call $min
    return
  )
  (func $floor (export "floor") (param $n f64) (result f64)
  )
  (func $ceiling (export "ceiling") (param $n f64) (result f64)
  )
  (func $round (export "round") (param $n f64) (result f64)
  )
  (func $squareRoot (export "squareRoot") (param $n f64) (result f64)
  )
  ;; NOTE: `toString` for floats — coerces via string concat.
  (func $toString (export "toString") (param $n f64) (result i32)
    i32.const 256
    local.get $n
    i32.add
    return
  )
)
```

----- RUN LOG -----
```logs
Execution error: error.FileNotFound```

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

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $main
    f32.const 2.5
    call $absoluteValue
    call $__print_i32
    drop
    f32.const 1.5
    f32.const 2.5
    call $min
    call $__print_i32
    drop
    f32.const 1.5
    f32.const 2.5
    call $max
    call $__print_i32
    drop
    f32.const 3.0
    f32.const 0.0
    f32.const 5.0
    call $clamp
    call $__print_i32
    drop
    f32.const 3.14
    call $toString
    call $__print_i32
    drop
    f32.const 2.9
    call $floor
    call $__print_i32
    drop
    f32.const 2.1
    call $ceiling
    call $__print_i32
    drop
    f32.const 2.5
    call $round
    call $__print_i32
    drop
    f32.const 9.0
    call $squareRoot
    call $__print_i32
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  (func $__print_i32 (param $n i32)
    (local $buf i32) (local $len i32) (local $neg i32) (local $d i32)
    (local $i i32) (local $j i32) (local $tmp i32)
    i32.const 100
    local.set $buf
    local.get $n
    i32.const 0
    i32.lt_s
    (if
      (then
        i32.const 1
        local.set $neg
        i32.const 0
        local.get $n
        i32.sub
        local.set $n
      )
    )
    (block $done
      (loop $digits
        local.get $n
        i32.const 10
        i32.rem_u
        i32.const 48
        i32.add
        local.set $d
        local.get $buf
        local.get $len
        i32.add
        local.get $d
        i32.store8
        local.get $len
        i32.const 1
        i32.add
        local.set $len
        local.get $n
        i32.const 10
        i32.div_u
        local.set $n
        local.get $n
        i32.const 0
        i32.gt_u
        br_if $digits
      )
    )
    ;; reverse
    i32.const 0
    local.set $i
    local.get $len
    i32.const 1
    i32.sub
    local.set $j
    (block $rdone
      (loop $rev
        local.get $i
        local.get $j
        i32.ge_u
        br_if $rdone
        local.get $buf
        local.get $i
        i32.add
        i32.load8_u
        local.set $tmp
        local.get $buf
        local.get $i
        i32.add
        local.get $buf
        local.get $j
        i32.add
        i32.load8_u
        i32.store8
        local.get $buf
        local.get $j
        i32.add
        local.get $tmp
        i32.store8
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        local.get $j
        i32.const 1
        i32.sub
        local.set $j
        br $rev
      )
    )
    ;; add neg sign + newline
    local.get $neg
    (if
      (then
        local.get $buf
        local.get $len
        i32.add
        local.get $buf
        local.get $len
        call $__memmove
        local.get $buf
        i32.const 45
        i32.store8
        local.get $len
        i32.const 1
        i32.add
        local.set $len
      )
    )
    local.get $buf
    local.get $len
    i32.add
    i32.const 10
    i32.store8
    local.get $len
    i32.const 1
    i32.add
    local.set $len
    ;; fd_write
    i32.const 0
    local.get $buf
    i32.store
    i32.const 4
    local.get $len
    i32.store
    i32.const 1
    i32.const 0
    i32.const 1
    i32.const 8
    call $fd_write
    drop
  )
  (func $__memmove (param $dst i32) (param $src i32) (param $len i32)
    (local $i i32)
    local.get $len
    i32.const 1
    i32.sub
    local.set $i
    (block $done
      (loop $loop
        local.get $i
        i32.const 0
        i32.lt_s
        br_if $done
        local.get $dst
        local.get $i
        i32.add
        local.get $src
        local.get $i
        i32.add
        i32.load8_u
        i32.store8
        local.get $i
        i32.const 1
        i32.sub
        local.set $i
        br $loop
      )
    )
  )
)
```

----- RUN LOG -----
```logs
```

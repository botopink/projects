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

----- WASM TEXT -- std/int.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\00\00\00\00")
  (global $__heap_ptr (mut i32) (i32.const 260))
  ;; Integer utilities module (`import {int} from "std";`).
  ;; Pure-botopink math helpers for `i32` values. No host backing —
  ;; compiles once for every backend.
  ;; Function names follow the language convention: camelCase.
  (func $absoluteValue (export "absoluteValue") (param $n i32) (result i32)
    local.get $n
    i32.const 0
    i32.lt_s
    (if (result i32)
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
  (func $min (export "min") (param $a i32) (param $b i32) (result i32)
    local.get $a
    local.get $b
    i32.lt_s
    (if (result i32)
      (then
    local.get $a
      )
      (else
    local.get $b
      )
    )
    return
  )
  (func $max (export "max") (param $a i32) (param $b i32) (result i32)
    local.get $a
    local.get $b
    i32.gt_s
    (if (result i32)
      (then
    local.get $a
      )
      (else
    local.get $b
      )
    )
    return
  )
  (func $clamp (export "clamp") (param $n i32) (param $lo i32) (param $hi i32) (result i32)
    local.get $n
    local.get $lo
    call $max
    local.get $hi
    call $min
    return
  )
  (func $isEven (export "isEven") (param $n i32) (result i32)
    local.get $n
    i32.const 2
    i32.rem_s
    i32.const 0
    i32.eq
    return
  )
  (func $isOdd (export "isOdd") (param $n i32) (result i32)
    local.get $n
    i32.const 2
    i32.rem_s
    i32.const 0
    i32.ne
    return
  )
  ;; NOTE: `to_string` (convert integer to its decimal string representation).
  ;; Botopink coerces numbers to string in `+` contexts — `"" + n` works.
  (func $toString (export "toString") (param $n i32) (result i32)
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

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $main
    i32.const 5
    call $absoluteValue
    call $__print_i32
    drop
    i32.const 3
    i32.const 7
    call $min
    call $__print_i32
    drop
    i32.const 3
    i32.const 7
    call $max
    call $__print_i32
    drop
    i32.const 10
    i32.const 0
    i32.const 5
    call $clamp
    call $__print_i32
    drop
    i32.const 4
    call $isEven
    call $__print_i32
    drop
    i32.const 3
    call $isOdd
    call $__print_i32
    drop
    i32.const 42
    call $toString
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

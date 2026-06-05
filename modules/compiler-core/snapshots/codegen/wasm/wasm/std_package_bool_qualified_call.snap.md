----- SOURCE CODE -- std/bool.bp
```botopink
//// Gleam-inspired `bool` module (`import {bool} from "std";`).
//// Pure-operator logic — no host backing, compiles once for every backend.
//// Function names follow the language convention: camelCase.
//// First real `"std"` package module (qualified calls lower to a per-module
//// output: `out/std/bool.js` / remote `bool:negate/1`).

pub fn negate(b: bool) -> bool {
    return !b;
}

pub fn nor(a: bool, b: bool) -> bool {
    return !(a || b);
}

pub fn nand(a: bool, b: bool) -> bool {
    return !(a && b);
}

pub fn exclusiveOr(a: bool, b: bool) -> bool {
    return a != b;
}

pub fn exclusiveNor(a: bool, b: bool) -> bool {
    return a == b;
}

```

----- WASM TEXT -- std/bool.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  ;; Gleam-inspired `bool` module (`import {bool} from "std";`).
  ;; Pure-operator logic — no host backing, compiles once for every backend.
  ;; Function names follow the language convention: camelCase.
  ;; First real `"std"` package module (qualified calls lower to a per-module
  ;; output: `out/std/bool.js` / remote `bool:negate/1`).
  (func $negate (export "negate") (param $b i32) (result i32)
    local.get $b
    i32.eqz
    return
  )
  (func $nor (export "nor") (param $a i32) (param $b i32) (result i32)
    local.get $a
    local.get $b
    i32.or
    i32.eqz
    return
  )
  (func $nand (export "nand") (param $a i32) (param $b i32) (result i32)
    local.get $a
    local.get $b
    i32.and
    i32.eqz
    return
  )
  (func $exclusiveOr (export "exclusiveOr") (param $a i32) (param $b i32) (result i32)
    local.get $a
    local.get $b
    i32.ne
    return
  )
  (func $exclusiveNor (export "exclusiveNor") (param $a i32) (param $b i32) (result i32)
    local.get $a
    local.get $b
    i32.eq
    return
  )
)
```

----- RUN LOG -----
```logs
Execution error: error.FileNotFound```

----- SOURCE CODE -- main.bp
```botopink
import {bool} from "std";

fn main() {
    val flipped = bool.negate(false);
    @print(bool.exclusiveOr(flipped, false));
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $main
    (local $flipped i32)
    global.get $false
    call $negate
    local.set $flipped
    local.get $flipped
    global.get $false
    call $exclusiveOr
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

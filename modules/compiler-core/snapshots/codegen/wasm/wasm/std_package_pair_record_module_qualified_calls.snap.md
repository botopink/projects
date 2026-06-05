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

pub fn map_first<A, B, C>(p: #(A, B), transform: fn(value: A) -> C) -> #(C, B) {
    return #(transform(p._0), p._1);
}

pub fn map_second<A, B, C>(p: #(A, B), transform: fn(value: B) -> C) -> #(A, C) {
    return #(p._0, transform(p._1));
}

```

----- WASM TEXT -- std/pair.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  ;; Gleam-style `pair` module (`import {pair} from "std";`), inspired by
  ;; `gleam/pair`. A pair IS a 2-tuple `#(a, b)` (same as Gleam) — structural,
  ;; so no generic-record instantiation is involved. Pure logic, compiles once
  ;; for every backend.
  ;; NOTE: named `of` (not `new`) — `new` is a reserved keyword.
  (func $of (export "of") (param $first i32) (param $second i32) (result i32)
    (local $__mem0 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    local.get $first
    i32.store
    local.get $__mem0
    local.get $second
    i32.store offset=4
    local.get $__mem0
    return
  )
  (func $first (export "first") (param $p i32) (result i32)
    local.get $p
    i32.load
    return
  )
  (func $second (export "second") (param $p i32) (result i32)
    local.get $p
    i32.load offset=4
    return
  )
  (func $swap (export "swap") (param $p i32) (result i32)
    (local $__mem0 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    local.get $p
    i32.load offset=4
    i32.store
    local.get $__mem0
    local.get $p
    i32.load
    i32.store offset=4
    local.get $__mem0
    return
  )
  (func $map_first (export "map_first") (param $p i32) (param $transform i32) (result i32)
    (local $__mem0 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    local.get $p
    i32.load
    call $transform
    i32.store
    local.get $__mem0
    local.get $p
    i32.load offset=4
    i32.store offset=4
    local.get $__mem0
    return
  )
  (func $map_second (export "map_second") (param $p i32) (param $transform i32) (result i32)
    (local $__mem0 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    local.get $p
    i32.load
    i32.store
    local.get $__mem0
    local.get $p
    i32.load offset=4
    call $transform
    i32.store offset=4
    local.get $__mem0
    return
  )
)
```

----- RUN LOG -----
```logs
Execution error: error.FileNotFound```

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

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (data (i32.const 256) "\03\00\00\00one")
  (global $__heap_ptr (mut i32) (i32.const 264))
  (func $main
    (local $p i32)
    (local $q i32)
    i32.const 1
    i32.const 256
    call $of
    local.set $p
    local.get $p
    call $swap
    local.set $q
    local.get $q
    call $first
    call $__print_i32
    drop
    local.get $q
    call $second
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

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

----- WASM TEXT -- std/list.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  ;; Gleam-style `list` module (`import {list} from "std";`), inspired by
  ;; `gleam/list`, built over the builtin `Array<T>`. Pure logic — transforms
  ;; delegate to the builtin Array methods; `fold` drives a mutable
  ;; accumulator through `forEach`.
  (func $length (export "length") (param $xs i32) (result i32)
    i32.const 0 ;; field access .length
    return
  )
  (func $is_empty (export "is_empty") (param $xs i32) (result i32)
    i32.const 0 ;; field access .length
    i32.const 0
    i32.eq
    return
  )
  (func $contains (export "contains") (param $xs i32) (param $x i32) (result i32)
    local.get $x
    call $indexOf
    i32.const 0
    i32.const 1
    i32.sub
    i32.ne
    return
  )
  (func $first (export "first") (param $xs i32) (result i32)
    i32.const 0
    call $at
    return
  )
  (func $rest (export "rest") (param $xs i32) (result i32)
    local.get $xs
    i32.const 1
    i32.const 0 ;; field access .length
    call $__str_slice
    return
  )
  (func $take (export "take") (param $xs i32) (param $n i32) (result i32)
    local.get $xs
    i32.const 0
    local.get $n
    call $__str_slice
    return
  )
  (func $drop (export "drop") (param $xs i32) (param $n i32) (result i32)
    local.get $xs
    local.get $n
    i32.const 0 ;; field access .length
    call $__str_slice
    return
  )
  (func $reverse (export "reverse") (param $xs i32) (result i32)
    call $reverse
    return
  )
  (func $map (export "map") (param $xs i32) (param $transform i32) (result i32)
    local.get $transform
    call $map
    return
  )
  (func $filter (export "filter") (param $xs i32) (param $keep i32) (result i32)
    local.get $keep
    call $filter
    return
  )
  (func $fold (export "fold") (param $xs i32) (param $initial i32) (param $f i32) (result i32)
    (local $acc i32)
    local.get $initial
    local.set $acc
    i32.const 0 ;; lambda
    call $forEach
    drop
    local.get $acc
    return
  )
  (func $all (export "all") (param $xs i32) (param $pred i32) (result i32)
    i32.const 0 ;; field access .length
    i32.const 0 ;; field access .length
    i32.eq
    return
  )
  (func $any (export "any") (param $xs i32) (param $pred i32) (result i32)
    i32.const 0 ;; field access .length
    i32.const 0
    i32.ne
    return
  )
  (func $__str_slice (param $src i32) (param $start i32) (param $end i32) (result i32)
    (local $newlen i32) (local $dst i32)
    local.get $end
    local.get $start
    i32.sub
    local.set $newlen
    global.get $__heap_ptr
    local.set $dst
    ;; bump heap by 4 (length prefix) + newlen
    global.get $__heap_ptr
    i32.const 4
    local.get $newlen
    i32.add
    i32.add
    global.set $__heap_ptr
    ;; store length prefix
    local.get $dst
    local.get $newlen
    i32.store
    ;; copy bytes: dst+4 <- src+4+start
    local.get $dst
    i32.const 4
    i32.add
    local.get $src
    i32.const 4
    i32.add
    local.get $start
    i32.add
    local.get $newlen
    memory.copy
    local.get $dst
  )
)
```

----- RUN LOG -----
```logs
Execution error: error.FileNotFound```

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

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (data (i32.const 256) "\01\00\00\00,")
  (global $__heap_ptr (mut i32) (i32.const 264))
  (func $main
    (local $__mem0 i32)
    (local $xs i32)
    (local $doubled i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 16
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 1
    i32.store
    local.get $__mem0
    i32.const 2
    i32.store offset=4
    local.get $__mem0
    i32.const 3
    i32.store offset=8
    local.get $__mem0
    i32.const 4
    i32.store offset=12
    local.get $__mem0
    local.set $xs
    local.get $xs
    i32.const 0 ;; lambda
    call $map
    local.set $doubled
    local.get $doubled
    i32.const 0
    i32.const 0 ;; lambda
    call $fold
    call $__print_i32
    drop
    local.get $xs
    i32.const 0 ;; lambda
    call $filter
    call $length
    call $__print_i32
    drop
    local.get $xs
    i32.const 3
    call $contains
    call $__print_i32
    drop
    i32.const 256
    call $join
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

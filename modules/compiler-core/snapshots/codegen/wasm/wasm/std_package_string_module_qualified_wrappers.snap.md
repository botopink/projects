----- SOURCE CODE -- std/string.bp
```botopink
//// String utilities module (`import {string} from "std";`).
//// Qualified wrappers over the built-in String interface methods.
//// Follows the Gleam-inspired naming convention: camelCase.

pub fn split(s: string, sep: string) -> Array<string> {
    return s.split(sep);
}

pub fn trim(s: string) -> string {
    return s.trim();
}

pub fn trimStart(s: string) -> string {
    return s.trim_start();
}

pub fn trimEnd(s: string) -> string {
    return s.trim_end();
}

pub fn contains(s: string, sub: string) -> bool {
    return s.contains(sub);
}

pub fn startsWith(s: string, prefix: string) -> bool {
    return s.starts_with(prefix);
}

pub fn endsWith(s: string, suffix: string) -> bool {
    return s.ends_with(suffix);
}

pub fn slice(s: string, start: i32, end: i32) -> string {
    return s.slice(start, end);
}

pub fn replace(s: string, pattern: string, with: string) -> string {
    return s.replace(pattern, with);
}

pub fn toUpper(s: string) -> string {
    return s.to_upper();
}

pub fn toLower(s: string) -> string {
    return s.to_lower();
}

// `join` takes an array of strings and a separator — Array<string>.join(sep).
pub fn join(parts: Array<string>, sep: string) -> string {
    return parts.join(sep);
}

test "inline: split and join round-trip" {
    val parts = split("a,b,c", ",");
    assert join(parts, "-") == "a-b-c";
}

test "inline: contains" {
    assert contains("hello world", "world");
    assert !contains("hello", "xyz");
}

test "inline: startsWith and endsWith" {
    assert startsWith("foobar", "foo");
    assert endsWith("foobar", "bar");
}

test "inline: slice" {
    assert slice("hello", 1, 3) == "el";
}

```

----- WASM TEXT -- std/string.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  ;; String utilities module (`import {string} from "std";`).
  ;; Qualified wrappers over the built-in String interface methods.
  ;; Follows the Gleam-inspired naming convention: camelCase.
  (func $split (export "split") (param $s i32) (param $sep i32) (result i32)
    local.get $sep
    call $split
    return
  )
  (func $trim (export "trim") (param $s i32) (result i32)
    call $trim
    return
  )
  (func $trimStart (export "trimStart") (param $s i32) (result i32)
    call $trim_start
    return
  )
  (func $trimEnd (export "trimEnd") (param $s i32) (result i32)
    call $trim_end
    return
  )
  (func $contains (export "contains") (param $s i32) (param $sub i32) (result i32)
    local.get $sub
    call $contains
    return
  )
  (func $startsWith (export "startsWith") (param $s i32) (param $prefix i32) (result i32)
    local.get $prefix
    call $starts_with
    return
  )
  (func $endsWith (export "endsWith") (param $s i32) (param $suffix i32) (result i32)
    local.get $suffix
    call $ends_with
    return
  )
  (func $slice (export "slice") (param $s i32) (param $start i32) (param $end i32) (result i32)
    local.get $s
    local.get $start
    local.get $end
    call $__str_slice
    return
  )
  (func $replace (export "replace") (param $s i32) (param $pattern i32) (param $with i32) (result i32)
    local.get $pattern
    local.get $with
    call $replace
    return
  )
  (func $toUpper (export "toUpper") (param $s i32) (result i32)
    call $to_upper
    return
  )
  (func $toLower (export "toLower") (param $s i32) (result i32)
    call $to_lower
    return
  )
  ;; `join` takes an array of strings and a separator — Array<string>.join(sep).
  (func $join (export "join") (param $parts i32) (param $sep i32) (result i32)
    local.get $sep
    call $join
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
import {string} from "std";

fn main() {
    val parts = string.split("a,b,c", ",");
    @print(string.join(parts, "|"));
    @print(string.contains("hello world", "world"));
    @print(string.startsWith("foobar", "foo"));
    @print(string.slice("hello", 1, 3));
    @print(string.trim("  hi  "));
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (data (i32.const 256) "\05\00\00\00a,b,c")
  (data (i32.const 268) "\01\00\00\00,")
  (data (i32.const 276) "\01\00\00\00|")
  (data (i32.const 284) "\0b\00\00\00hello world")
  (data (i32.const 300) "\05\00\00\00world")
  (data (i32.const 312) "\06\00\00\00foobar")
  (data (i32.const 324) "\03\00\00\00foo")
  (data (i32.const 332) "\05\00\00\00hello")
  (data (i32.const 344) "\06\00\00\00  hi  ")
  (global $__heap_ptr (mut i32) (i32.const 356))
  (func $main
    (local $parts i32)
    i32.const 256
    i32.const 268
    call $split
    local.set $parts
    local.get $parts
    i32.const 276
    call $join
    call $__print_i32
    drop
    i32.const 284
    i32.const 300
    call $contains
    call $__print_i32
    drop
    i32.const 312
    i32.const 324
    call $startsWith
    call $__print_i32
    drop
    global.get $string
    i32.const 332
    i32.const 1
    call $__str_slice
    call $__print_i32
    drop
    i32.const 344
    call $trim
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
```

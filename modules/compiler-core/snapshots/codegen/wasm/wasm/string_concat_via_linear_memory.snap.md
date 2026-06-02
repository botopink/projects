----- SOURCE CODE -- main.bp
```botopink
fn greeting() -> string {
    return "Hello, " + "World";
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "Hello, ")
  (data (i32.const 264) "World")
  (global $__heap_ptr (mut i32) (i32.const 272))
  (func $greeting (result i32)
    i32.const 256 ;; "Hello, " ptr
    i32.const 7 ;; "Hello, " len
    i32.const 264 ;; "World" ptr
    i32.const 5 ;; "World" len
    call $__str_concat
    return
  )
  (func $__str_concat (param $a i32) (param $alen i32) (param $b i32) (param $blen i32) (result i32)
    (local $base i32)
    global.get $__heap_ptr
    local.set $base
    global.get $__heap_ptr
    local.get $alen
    local.get $blen
    i32.add
    i32.add
    global.set $__heap_ptr
    local.get $base
    local.get $a
    local.get $alen
    memory.copy
    local.get $base
    local.get $alen
    i32.add
    local.get $b
    local.get $blen
    memory.copy
    local.get $base
  )
)
```

----- RUN LOG -----
```logs
```

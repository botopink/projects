----- SOURCE CODE -- main.bp
```botopink
fn describe() -> string {
    val items = ["a", "b", "c"];
    return case items {
        [] -> "empty";
        [x] -> "one";
        [first, ..rest] -> "many";
    };
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "a")
  (data (i32.const 260) "b")
  (data (i32.const 264) "c")
  (data (i32.const 268) "empty")
  (global $__heap_ptr (mut i32) (i32.const 276))
  (func $describe (result i32)
    (local $__mem0 i32)
    (local $items i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 12
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 256
    i32.store
    local.get $__mem0
    i32.const 260
    i32.store offset=4
    local.get $__mem0
    i32.const 264
    i32.store offset=8
    local.get $__mem0
    local.set $items
    local.get $items
    (local $__case_0 i32)
    local.set $__case_0
    i32.const 268
    return
  )
)
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
record ApiError { msg: string }
fn fetch() -> @Result<i32, ApiError> {
    throw ApiError(msg: "not found");
}
fn strict() -> @Result<i32, string> {
    val r = try fetch() catch throw "fetch failed";
    return r;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "not found")
  (data (i32.const 268) "fetch failed")
  (global $__heap_ptr (mut i32) (i32.const 280))
  (func $fetch (result i32)
    (local $__mem0 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 4
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 256
    i32.store
    local.get $__mem0
    unreachable
  )
  (func $strict (result i32)
    (local $_try0 i32)
    (local $r i32)
    call $fetch
    local.set $_try0
    local.get $_try0
    i32.load ;; Result tag (0 = Ok, non-zero = Error)
    (if (result i32)
      (then
    i32.const 268
    unreachable
      )
      (else
    local.get $_try0
    i32.load offset=4 ;; Ok payload
      )
    )
    local.set $r
    local.get $r
    return
  )
)
```

----- RUN LOG -----
```logs
```

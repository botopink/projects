----- SOURCE CODE -- main.bp
```botopink
record Error { msg: string }
fn fetch() -> @Result<#(i32, i32), Error> {
    throw Error(msg: "boom");
}
fn f() {
    val #(a, b) = try fetch() catch throw Error(msg: "failed");
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "boom")
  (data (i32.const 260) "failed")
  (global $__heap_ptr (mut i32) (i32.const 268))
  (func $fetch (result i32)
    i32.const 256
    call $Error
    unreachable
  )
  (func $f
    (local $_try0 i32)
    (local $a i32)
    (local $b i32)
    call $fetch
    local.set $_try0
    local.get $_try0
    i32.load ;; Result tag (0 = Ok, non-zero = Error)
    (if (result i32)
      (then
    i32.const 260
    call $Error
    unreachable
      )
      (else
    local.get $_try0
    i32.load offset=4 ;; Ok payload
      )
    )
    local.set $b
    local.set $a
  )
)
```

----- RUN LOG -----
```logs
```

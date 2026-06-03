----- SOURCE CODE -- main.bp
```botopink
val Shape = enum {
    Circle(r: i32),
    Square(s: i32),
}
fn big(sh: Shape) -> string {
    return case sh {
        Circle(r) if r > 10 -> "big circle";
        _ -> "other";
    };
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "big circle")
  (global $__heap_ptr (mut i32) (i32.const 268))
  (func $big (param $sh i32) (result i32)
    local.get $sh
    (local $__case_0 i32)
    local.set $__case_0
    i32.const 256
    return
  )
)
```

----- RUN LOG -----
```logs
```

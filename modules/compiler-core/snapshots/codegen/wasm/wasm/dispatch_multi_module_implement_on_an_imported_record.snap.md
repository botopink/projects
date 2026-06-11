----- SOURCE CODE -- pond.bp
```botopink
pub val Swimmer = interface {
    fn swim(self: Self);
}
pub record Pato { id: i32 }
```

----- WASM TEXT -- pond.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
)
```

----- RUN LOG -----
```logs
```

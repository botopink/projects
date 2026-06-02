----- SOURCE CODE -- main.bp
```botopink
record Person { name: string }
fn firstName(p: Person) -> @Option<string> { @todo(); }
fn shout(s: string) -> @Option<string> { @todo(); }
fn greet(p: Person) -> string {
    return firstName(p)
        .map({ n -> "Hello " + n })
        .flatMap({ n -> shout(n) })
        .unwrapOr("Hello stranger");
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $firstName (param $p i32) (result i32)
    unreachable
  )
  (func $shout (param $s i32) (result i32)
    unreachable
  )
  (func $greet (param $p i32) (result i32)
    ;; builtin stub
    return
  )
)
```

----- RUN LOG -----
```logs
```

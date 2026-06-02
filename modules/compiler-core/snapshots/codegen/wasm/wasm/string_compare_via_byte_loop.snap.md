----- SOURCE CODE -- main.bp
```botopink
fn sameWord() -> bool {
    return "foo" == "bar";
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "foo")
  (data (i32.const 260) "bar")
  (global $__heap_ptr (mut i32) (i32.const 264))
  (func $sameWord (result i32)
    i32.const 256
    i32.const 3
    i32.const 260
    i32.const 3
    call $__str_eq
    return
  )
  (func $__str_eq (param $a i32) (param $alen i32) (param $b i32) (param $blen i32) (result i32)
    (local $i i32)
    local.get $alen
    local.get $blen
    i32.ne
    (if
      (then i32.const 0 return)
    )
    (block $done
      (loop $cmp
        local.get $i
        local.get $alen
        i32.ge_u
        br_if $done
        local.get $a
        local.get $i
        i32.add
        i32.load8_u
        local.get $b
        local.get $i
        i32.add
        i32.load8_u
        i32.ne
        (if
          (then i32.const 0 return)
        )
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cmp
      )
    )
    i32.const 1
  )
)
```

----- RUN LOG -----
```logs
```

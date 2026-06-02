# WAT — remaining features

**Branch**: `task/wat-features`
**Depends on**: nothing (independent)
**Status**: in progress
**File**: `wat.zig`

> **Situação (2026-06-02):** branch atualizada sobre `feat`. O `feat` já trazia
> try/catch (tag-based if/else), pipeline (`a |> f` → `call $f`) e destructure
> parcial (`local.set` por campo). Esta task completa os itens restantes em
> `wat.zig`: destructure real por offset, string concat/compare via memória
> linear e representação de enum/record como tagged structs.

## Steps

- [x] Destructure patterns (record, tuple) — load por offset a partir do ptr
- [x] Pipeline operator lowering (já em `feat`)
- [x] String operations (concat, compare) via linear memory
- [x] Enum/record representation in linear memory (tagged structs)
- [x] try/catch → tag-based if/else (já em `feat` via `trycatch-lowering`)

## Examples

### Record destructure
```bp
record Point { x: i32, y: i32 }
fn sumXY(p: Point) -> i32 {
    val { x, y } = p;
    return x + y;
}
```
```wat
;; x = i32.load offset=0 ; y = i32.load offset=4
(i32.add (i32.load (local.get $p)) (i32.load offset=4 (local.get $p)))
```

### String concat via linear memory
```bp
fn name() -> string {
    return "a" + "b";
}
```
```wat
;; copy bytes of "a" and "b" into a new region; return (ptr, len)
```

### Pipeline operator
```bp
fn double(x: i32) -> i32 { return x * 2; }
fn run() -> i32 {
    return 21 |> double;
}
```

## Test scenarios

```
wasm ---- destructure record → i32.load per offset
wasm ---- destructure tuple → sequential loads
wasm ---- pipeline a |> f → call f(a)
wasm ---- chained pipeline a |> f |> g → g(f(a))
wasm ---- string concat → alloc + memory.copy, returns (ptr,len)
wasm ---- string compare → byte loop in linear memory
wasm ---- enum payload → tagged struct (i32 tag + fields) in memory
wasm ---- record 2 fields → contiguous layout, store per offset
wasm ---- try/catch → if/else on the Ok/Error tag
```

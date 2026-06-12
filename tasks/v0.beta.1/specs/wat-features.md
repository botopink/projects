# WAT — remaining features

**Branch**: `feat/wat-features`
**Depends on**: nothing (independent)
**Status**: pending
**File**: `wat.zig`

## Steps

- [ ] Destructure patterns (record, tuple)
- [ ] Pipeline operator lowering
- [ ] String operations (concat, compare) via linear memory
- [ ] Enum/record representation in linear memory (tagged structs)
- [ ] try/catch → tag-based if/else (align with `feat/trycatch-lowering`)

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
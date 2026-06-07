# stdlib interface redesign — loose functions → interface methods

**Slug**: `stdlib-interface`
**Depends on**: `generic-inference` (generic methods need fresh type vars per call site)
**Files**: `libs/std/src/*.d.bp`, `libs/std/src/*.bp`; `modules/compiler-core/src/comptime/infer.zig` (method dispatch on primitive types and enums)
**Touches docs**: `libs/std/AGENTS.md`; `libs/std/src/docs.md`; `libs/std/src/examples.md`
**Status**: pending

## Problem

The current stdlib modules (`bool.bp`, `list.bp`, `order.bp`, `pair.bp`, etc.) are
**namespaces with loose functions** — called as `list.map(xs, f)` or
`bool.negate(x)`. This diverges from how `Array<T>` already works
(method: `xs.map(f)`).

Consistency with the native form is better: `xs.fold(0, f)` instead of
`list.fold(xs, 0, f)`, `o.reverse()` instead of `order.reverse(o)`.

Also, `io.d.bp` is an unnecessarily isolated declaration file — it can be a
section in `builtins.d.bp` like the other primitives.

**`primitives.d.bp` is the reference model**: it already declares
`interface I32 / U32 / I64 / U64 / F32 / F64 / Bool` with `self: Self` methods
(`to_string`, `abs`, `clamp`, …). This spec extends that pattern to the rest of
the stdlib instead of keeping loose namespace functions.

## Target architecture

Each module becomes an **interface extension** in the type's declaration file:

| Current module | Becomes | Target interface |
|---|---|---|
| `bool.bp` | section in `primitives.d.bp` | `interface Bool { … }` |
| `int.bp` | section in `primitives.d.bp` | `interface I32 { … }` |
| `float.bp` | section in `primitives.d.bp` | `interface F64 { … }` |
| `string.bp` | merged into `string.d.bp` | `interface String { … }` |
| `list.bp` | merged into `array.d.bp` | `interface Array<T> { … }` (additional methods) |
| `order.bp` | new `order.d.bp` | `interface OrderOps` + enum `Order` |
| `pair.bp` | new `pair.d.bp` | `interface Pair<A, B>` on `#(A, B)` |
| `iterator.bp` | merged into `builtins.d.bp` | `interface Iterator<T>` (eager operations) |
| `dict.bp` | stays `.bp` with methods | `pub record Dict<K,V>` with methods |
| `sets.bp` | stays `.bp` with methods | `pub record Set<T>` with methods |
| `queue.bp` | stays `.bp` with methods | `pub record Queue<T>` with methods |
| `string_builder.bp` | stays `.bp` with methods | `pub record StringBuilder` with methods |
| `function.bp` | eliminated or kept as utils | useful static functions (no natural receiver) |
| `io.d.bp` | merged into `builtins.d.bp` | `// ── I/O ──` section |

`syntax.bp` (expr-templates data model) is out of scope — it stays as-is.

## Target syntax

### bool — methods on the primitive type `bool`

```bp
// primitives.d.bp — extend the existing interface Bool
interface Bool {
    fn toString(self: Self) -> string           // normalized from to_string
    fn negate(self: Self) -> bool
    fn nor(self: Self, other: bool) -> bool
    fn nand(self: Self, other: bool) -> bool
    fn exclusiveOr(self: Self, other: bool) -> bool
    fn exclusiveNor(self: Self, other: bool) -> bool
}
```

```bp
// call site (no import)
val x = true.negate();
val y = false.nor(false);
```

### int — methods on `i32`

```bp
// primitives.d.bp — extend the existing interface I32 (abs/clamp already there)
interface I32 {
    fn toString(self: Self) -> string           // normalized from to_string
    fn abs(self: Self) -> i32
    fn clamp(self: Self, min: i32, max: i32) -> i32
    fn min(self: Self, other: i32) -> i32
    fn max(self: Self, other: i32) -> i32
    fn isEven(self: Self) -> bool
    fn isOdd(self: Self) -> bool
}
```

```bp
val n = (-5).abs();   // 5
val e = 4.isEven();   // true
```

### order — methods on the `Order` enum

```bp
// order.d.bp (new declaration file)
pub enum Order { Lt, Eq, Gt }

interface OrderOps {
    fn toInt(self: Order) -> i32
    fn reverse(self: Order) -> Order
}
```

```bp
// no import
val o = Order.Lt;
val n = o.toInt();      // -1
val r = o.reverse();    // Order.Gt
```

### pair — methods on `#(A, B)`

```bp
// pair.d.bp (new declaration file)
interface Pair<A, B> {
    fn first(self: #(A, B)) -> A
    fn second(self: #(A, B)) -> B
    fn swap(self: #(A, B)) -> #(B, A)
    fn mapFirst<C>(self: #(A, B), f: fn(A) -> C) -> #(C, B)
    fn mapSecond<C>(self: #(A, B), f: fn(B) -> C) -> #(A, C)
}
```

```bp
val p = #("hello", 42);
val s = p.swap();       // #(42, "hello")
val n = p.second();     // 42
```

### list — merged into `Array<T>`

```bp
// array.d.bp — additional section (list ops)
interface Array<T> {
    // … existing ops …

    fn fold<A>(self: Self, initial: A, f: fn(acc: A, item: T) -> A) -> A
    fn flatMap<U>(self: Self, f: fn(item: T) -> Array<U>) -> Array<U>
    fn flatten(self: Self) -> Array<T>        // where T = Array<U>
    fn append(self: Self, other: Array<T>) -> Array<T>
    fn prepend(self: Self, item: T) -> Array<T>
    fn take(self: Self, n: i32) -> Array<T>
    fn drop(self: Self, n: i32) -> Array<T>
    fn first(self: Self) -> ?T
    fn rest(self: Self) -> Array<T>
    fn find(self: Self, pred: fn(T) -> bool) -> ?T
    fn all(self: Self, pred: fn(T) -> bool) -> bool
    fn any(self: Self, pred: fn(T) -> bool) -> bool
    fn count(self: Self, pred: fn(T) -> bool) -> i32
    fn isEmpty(self: Self) -> bool
    fn range(start: i32, stop: i32) -> Array<i32>   // static fn
}
```

### iterator — eager operations on the `Iterator<T>` interface

```bp
// builtins.d.bp — extended interface Iterator<T>
pub interface Iterator<T> {
    fn next(self: Self) -> ?T

    // eager operations (return Array)
    fn toList(self: Self) -> Array<T>
    fn fold<A>(self: Self, initial: A, f: fn(acc: A, item: T) -> A) -> A
    fn map<U>(self: Self, f: fn(item: T) -> U) -> Array<U>
    fn filter(self: Self, pred: fn(item: T) -> bool) -> Array<T>
    fn take(self: Self, n: i32) -> Array<T>
}
```

### io — merged into `builtins.d.bp`

```bp
// builtins.d.bp — new section (replacing io.d.bp)

// ── I/O ────────────────────────────────────────────────────────────────────────

#[@external(node, "console", "log"),
  @external(erlang, "io", "format")]
pub declare fn print(message: string);

#[@external(node, "console", "log"),
  @external(erlang, "io", "format")]
pub declare fn println(message: string);

#[@external(node, "console", "debug"),
  @external(erlang, "io", "format")]
pub declare fn debug(value: string);
```

## Steps

### F0 — Merge `io.d.bp` into `builtins.d.bp` (smallest impact, no deps)

- [ ] Move the 3 declarations from `io.d.bp` into a `// ── I/O ──` section in `builtins.d.bp`
- [ ] Delete `io.d.bp`
- [ ] Remove `io_mod` from `prelude.zig` and from `std_pkg_modules` in `comptime.zig`
- [ ] Remove `io.d.bp` from `std_bp_files` in `build.zig`
- [ ] Keep `import {io} from "std"` working: `print`/`println`/`debug` are
      builtins now — no qualified module, accessed directly or as `io.print`
      via the builtin namespace
- [ ] Update `libs/std/AGENTS.md`

### F1 — Methods on `bool` (primitives.d.bp)

- [ ] Extend the existing `interface Bool` in `primitives.d.bp` with the 5 methods
- [ ] Normalize legacy snake_case in `primitives.d.bp` to camelCase (`to_string` → `toString`)
      across all interfaces (I32/U32/I64/U64/F32/F64/Bool)
- [ ] Remove (or keep as alias) `bool.bp` — if kept, becomes an empty `.d.bp`
- [ ] Adjust `registerStdlib` / `prelude.zig`: remove `bool.bp` embedding if eliminated
- [ ] Confirm method dispatch: `true.negate()` → inference via `primitives.d.bp`
- [ ] Migrate inline tests to the new call form

### F2 — Methods on `i32` and `f64` (primitives.d.bp)

- [ ] Extend `interface I32` with `{ min, max, isEven, isOdd }` (`to_string`/`abs`/`clamp` exist)
- [ ] Extend `interface F64` with `{ min, max, squareRoot via #[@external] }` (`floor`/`ceil`/`round` exist)
- [ ] Remove `int.bp` and `float.bp` (or keep as transitional shims)
- [ ] Migrate inline tests to method syntax

### F3 — `Order` enum with methods (new `order.d.bp`)

- [ ] Create `libs/std/src/order.d.bp` with `pub enum Order { Lt, Eq, Gt }` and `interface OrderOps`
- [ ] Remove `order.bp` (functions migrated to the interface)
- [ ] Update prelude.zig + comptime.zig + build.zig
- [ ] Migrate `order_test.bp` to method syntax

### F4 — `Pair<A, B>` interface on `#(A, B)` (new `pair.d.bp`)

- [ ] Create `libs/std/src/pair.d.bp` with `interface Pair<A, B>` over the `#(A, B)` type
- [ ] Remove `pair.bp`
- [ ] Confirm that `inferMethodCallExpr` resolves methods on tuples `#(A, B)`
- [ ] Migrate `pair_test.bp` to method syntax

### F5 — List ops on `Array<T>` (extended array.d.bp)

- [ ] Add `fold`, `flatMap`, `flatten`, `append`, `prepend`, `take`, `drop`,
      `first`, `rest`, `find`, `all`, `any`, `count`, `isEmpty`, `range` to `interface Array<T>`
- [ ] Remove `list.bp`
- [ ] Confirm that the generics of `fold<A>` etc. work via `generic-inference`
- [ ] Migrate `list_test.bp` to method syntax (`xs.fold(0, f)`, `xs.take(3)`, etc.)

### F6 — Extended `String` interface (string.d.bp)

- [ ] Move the implementations from `string.bp` into `string.d.bp` as declarations
- [ ] Confirm snake_case → camelCase mapping (or normalize at the definition)
- [ ] Remove `string.bp`
- [ ] Migrate `string_test.bp` and inline tests

### F7 — `Iterator<T>` with eager operations (builtins.d.bp)

- [ ] Add `toList`, `fold`, `map`, `filter`, `take` to `interface Iterator<T>`
- [ ] Remove `iterator.bp` (or keep `range`, `repeat` as generator functions)
- [ ] Migrate `iterator_test.bp`

### F8 — Records with methods: `Dict<K,V>`, `Set<T>`, `Queue<T>`, `StringBuilder`

- [ ] Convert call syntax to method dispatch: `d.insert("k", v)` instead of
      `dict.insert(d, "k", v)` — the compiler probably already supports this if the
      record has the methods declared
- [ ] Update the corresponding test files

### F9 — Remove eliminated modules and update the prelude

- [ ] Remove `.bp` files that became `.d.bp` or were eliminated from `prelude.zig`
- [ ] Remove entries from `std_pkg_modules` in `comptime.zig`
- [ ] Remove from `std_bp_files` in `build.zig`
- [ ] Update `libs/std/AGENTS.md` (tree + tables)
- [ ] Update `libs/std/src/docs.md` + `libs/std/src/examples.md` to method syntax

## Test scenarios

```
comptime ---- bool methods: true.negate() resolves via primitives.d.bp
comptime ---- int methods: 5.clamp(0, 3) resolves
comptime ---- order enum method: Order.Lt.toInt() == -1
comptime ---- pair methods: #(1, "a").swap() == #("a", 1)
comptime ---- array list ops: [1,2,3].fold(0, { acc, x -> acc + x }) == 6
comptime ---- iterator methods: range(0, 5).toList().length == 5
codegen/node ---- bool method dispatch lowers correctly
codegen/node ---- int method toString: 42.toString() == "42"
```

## Notes

- **Naming (decided 2026-06-07)**: camelCase is the standard (`isEven`,
  `exclusiveOr`, `toString`). The snake_case methods in the existing
  `primitives.d.bp`/`string.d.bp` (`to_string`, `trim_start`) are legacy — F1/F2/F6
  normalize them to camelCase. Normalizing at the definition also shrinks the
  backend-parity F2 name-mapping table (only JS-prototype mismatches like
  `toUpper` → `toUpperCase` remain).
- **Method dispatch on primitive types** (`bool`, `i32`, `f64`) needs support in
  `inferMethodCallExpr` for interface lookup by receiver type. Check whether this
  already works for `Array<T>` and reuse the same mechanism.
- `function.bp` has no natural receiver — `identity`, `constant` are static
  functions. It can stay as a utility namespace (does not become an interface).
  `compose` and `flip` could be methods on function types (`fn(A)->B`), but that
  is more complex.
- `range(start, stop)` is a static function (no receiver) — it can become a
  builtin function in `builtins.d.bp` or a static method of `Array<i32>`.
- F5 (list ops on Array) depends on `generic-inference` so that `fold<A>` works
  correctly with fresh type vars per call site.
- The records (`Dict`, `Set`, `Queue`, `StringBuilder`) already support method
  dispatch via record fields if the compiler treats them as self — confirm before F8.

# std

> Path: `libs/std/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../AGENTS.md`](../../AGENTS.md)
> Docs: [`./docs.md`](docs.md) · Examples: [`src/examples.md`](src/examples.md)

Botopink standard library. `src/` is **`.bp`-only** (language-neutral source).
The files are embedded as compile-time strings and loaded by `compiler-core`
into the type environment during inference; the embed/loader glue lives in
`modules/compiler-core/src/comptime/stdlib/prelude.zig`, next to its consumer.

## Tree

```text
std/
├── AGENTS.md          ← you are here
├── docs.md            ← how the stdlib reaches the compiler + conventions
├── botopink.json      ← package metadata
├── src/               ← .bp source modules (inline tests only in non-generic modules)
│   ├── docs.md            ← registry + per-file roles
│   ├── examples.md        ← stdlib usage in `.bp` (Array, String, builtins)
│   ├── primitives.d.bp    ← numeric + bool interfaces
│   ├── array.d.bp         ← generic Array<T> interface
│   ├── string.d.bp        ← String interface methods
│   ├── syntax.bp          ← std.syntax — `@Expr` template data model + interface Expr<E>
│   ├── builtins.d.bp      ← @typeOf / @sizeOf / @panic / … (NOT embedded yet — see below)
│   ├── bool.bp            ← `bool` std module  ◀ inline tests (5 blocks)
│   ├── pair.bp            ← `pair` std module
│   ├── order.bp           ← `order` std module (`pub enum Order`)  ◀ inline tests (3 blocks)
│   ├── list.bp            ← `list` std module (over Array<T>)
│   ├── int.bp             ← `int` std module  ◀ inline tests (5 blocks)
│   ├── float.bp           ← `float` std module  ◀ inline tests (4 blocks)
│   ├── string.bp          ← `string` std module  ◀ inline tests (7 blocks)
│   ├── iterator.bp        ← `iterator` std module (lazy `*fn` generators + eager higher-order ops)
│   ├── dict.bp            ← `dict` std module (`pub record Dict<K,V>`)
│   ├── sets.bp            ← `sets` std module (`pub record Set<T>`)
│   ├── function.bp        ← `function` std module (`identity`/`compose`/`flip`/`constant`)
│   ├── io.d.bp            ← `io` std module (decl — `#[@external]` backed)
│   ├── string_builder.bp  ← `string_builder` std module (`pub record StringBuilder`)
│   └── queue.bp           ← `queue` std module (`pub record Queue<T>`, FIFO)
└── test/              ← external tests (generic modules + builtins)
    ├── array_test.bp      ← builtin Array<T> surface: join/reverse/indexOf/at/map/filter/slice
    ├── option_test.bp     ← ?T builtin methods (map/flatMap/unwrapOr) + `?.` chaining
    ├── result_test.bp     ← builtin result namespace: map/then/unwrap/isOk/isError
    ├── pair_test.bp       ← pair module: of/first/second/swap/mapFirst/mapSecond
    ├── list_test.bp       ← list module: fold/map/filter/range/append/prepend/flatten/all/any
    ├── iterator_test.bp   ← iterator module: range/toList/fold/map/filter/take
    ├── dict_test.bp       ← dict module: empty/insert/lookup/hasKey/delete/size/fold/merge/mapValues
    ├── set_test.bp        ← sets module: empty/insert/contains/delete/fromList/union/intersection/difference
    ├── function_test.bp   ← function module: identity/compose/flip/constant
    └── queue_test.bp      ← queue module: empty/enqueue/peek/dequeue/toList/fromList
```

## Source modules (src/)

| File | Role |
|---|---|
| `primitives.d.bp` | `interface I32 { … }`, `interface U32 { … }`, …, `interface Bool { … }`. |
| `array.d.bp` | `interface Array<T>` — `length`, `at`, `push`, `pop`, `contains`, `slice`, `join`, `reverse`, `indexOf`, `forEach`, `map`, `filter`. |
| `string.d.bp` | `interface String` — `len`, `split`, `to_upper/lower`, `contains`, `starts_with`, `ends_with`, `trim*`, `replace`, `slice`, `char_at`, `index_of`, `to_string`. |
| `syntax.bp` | `std.syntax` — data model for `@Expr` templates: `struct Span`, `enum Part`, `enum BindingKind`, `struct Binding`, `struct Source`, `struct Context`, and `interface Expr<E>`. Comptime-only; no codegen. |
| `builtins.d.bp` | Reflection (`typeOf`, `typeName`, `sizeOf`, …), numeric (`min`, `max`, `abs`, `as`), runtime (`panic`, `trap`, `src`). **Not embedded by `prelude.zig` yet** — registered programmatically in `comptime/env.zig`. |
| `bool.bp` | `negate`, `nor`, `nand`, `exclusiveOr`, `exclusiveNor` — pure-operator logic. `option`/`result` are NOT std modules (builtin namespaces). |
| `int.bp` | `absoluteValue`, `min`, `max`, `clamp`, `isEven`, `isOdd`, `toString`. |
| `float.bp` | `absoluteValue`, `min`, `max`, `clamp`, `toString`; `floor`, `ceiling`, `round`, `squareRoot` via `#[@external]`. |
| `string.bp` | `split`, `trim`, `trimStart`, `trimEnd`, `contains`, `startsWith`, `endsWith`, `slice`, `replace`, `toUpper`, `toLower`, `join`. |
| `iterator.bp` | Lazy producers: `range(start, stop)`, `repeat(value, times)`, `fromList(xs)` via `*fn`. Eager consumers (return `Array`): `toList`, `map`, `filter`, `take`. Fold: `fold`. Note: `fromList` JS codegen has a known gap — see TODO.md. |
| `dict.bp` | `pub record Dict<K, V>` (association list over `Array<#(K, V)>`). `empty`, `lookup`, `hasKey`, `insert`, `delete`, `size`, `isEmpty`, `keys`, `values`, `fold`, `merge`, `mapValues`. O(n) lookup. |
| `sets.bp` | `pub record Set<T>` (deduplicated `Array<T>`). `empty`, `contains`, `size`, `isEmpty`, `insert`, `delete`, `toList`, `fromList`, `union`, `intersection`, `difference`. (Named `sets.bp` — `set` is a keyword.) |
| `function.bp` | `identity`, `compose` (left-to-right), `flip`, `constant`. Pure combinators. |
| `io.d.bp` | `print`, `println`, `debug` — host-backed via `#[@external]`. Declaration-only. |
| `string_builder.bp` | `pub record StringBuilder` (wraps `Array<string>`). `empty`, `append`, `prepend`, `toString`, `fromString`, `fromStrings`, `length`, `isEmpty`. |
| `queue.bp` | `pub record Queue<T>` (FIFO, front at index 0). `empty`, `size`, `isEmpty`, `enqueue`, `dequeue` (returns `#(Queue<T>, ?T)`), `peek`, `toList`, `fromList`. O(n) enqueue (copy-on-write). |

## Tests (test/)

Run with:

```bash
cd libs/std && botopink test            # all suites
botopink test --filter "array map"      # by name substring
```

**Non-generic modules** carry inline `test { … }` blocks directly in their
`src/` file (Zig-style co-location): `bool.bp`, `int.bp`, `float.bp`,
`order.bp`, `string.bp`. `*.d.bp` files are excluded from compilation.

**Generic modules** (pair, list, iterator, dict, sets, function, queue) use
external `*_test.bp` files in `test/` because `registerStdlib` processes
each module's source (including inline test blocks) with `.generic` type
variables not yet instantiated — any call to a generic function inside an
inline test block throws `TypeError.typeMismatch`, cascading to all
`freshTestEnv` consumers. Non-generic modules are immune (their functions
have no type variables), which is why inline tests work there.

### Coverage (commonJS target)

| Surface | Covered |
|---|---|
| `String` | `split`, `.length`, `trim`, `slice` |
| `Array<T>` | `join`, `reverse`, `indexOf`, `at`, `map`, `filter`, `slice` |
| `?T` (option) | `map`, `flatMap`, `unwrapOr`; `?.` member access |
| `result` namespace | `map`, `then`, `unwrap`, `isOk`, `isError` |
| `bool` module | `negate`, `nor`, `nand`, `exclusiveOr`, `exclusiveNor` |
| `order` module | `lt`/`eq`/`gt`, `toInt`, `reverse`, `case` over `Order` |
| `pair` module | `of`, `first`, `second`, `swap`, `mapFirst`, `mapSecond` |
| `list` module | `fold`, `map`, `filter`, `range`, `append`, `prepend`, `flatten`, `all`, `any`, `find`, `count`, `take`, `drop`, `reverse`, `first`, `rest`, `contains`, `isEmpty`, `flatMap` |
| `int` module | `absoluteValue`, `min`, `max`, `clamp`, `isEven`, `isOdd`, `toString` |
| `float` module | `absoluteValue`, `min`, `max`, `clamp`, `toString` |
| `iterator` module | `range`, `toList`, `fold`, `map`, `filter`, `take` |
| `dict` module | `empty`, `lookup`, `hasKey`, `insert`, `delete`, `size`, `isEmpty`, `keys`, `values`, `fold`, `merge`, `mapValues` |
| `sets` module | `empty`, `contains`, `size`, `isEmpty`, `insert`, `delete`, `toList`, `fromList`, `union`, `intersection`, `difference` |
| `function` module | `identity`, `compose`, `flip`, `constant` |
| `queue` module | `empty`, `enqueue`, `peek`, `dequeue`, `toList`, `fromList` |

**Blocked — snake_case method JS mapping**: `s.to_upper()` etc. are emitted verbatim;
no JS equivalent. Add tests when typed-value dispatch lands.

**Blocked — Erlang/BEAM**: escript loads only the entry module; std modules are
unreachable. All coverage is commonJS-only.

## Wiring

`comptime/env.zig` → `registerStdlib` → `prelude.zig` → embeds each `.bp` string
→ type `Env`. Each `.bp` file is exposed as an anonymous import in `build.zig`
(`std_bp_files`).

When adding a `.bp` file:
1. Add to `std_bp_files` in the root `build.zig`.
2. Add `pub const <name>_mod = @embedFile("<name>.bp");` to `prelude.zig`.
3. Add `.{ .path = "std/<name>", .source = @import("std_prelude").<name>_mod }` to `std_pkg_modules` in `comptime.zig`.

## Conventions

- Stable, additive signatures — renames force snapshot churn.
- Interface declarations (`.d.bp`) must stay declarative (no method bodies).
- No Zig in `libs/std/` — loader/glue changes belong in `compiler-core`.
- Method receivers must be `val`-bound identifiers — literal receivers don't parse yet.
- Equality assertions on arrays use `.join(...)` (structural `==` is reference equality in JS).
- `new`/`get`/`set` are keyword tokens — use `empty`/`lookup`/`insert` instead.

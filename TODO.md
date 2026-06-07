# TODO — stdlib-gleam

> Live checklist for branch `task/stdlib-gleam` (worktree `.tasks/stdlib-gleam/`).
> Spec (intent, immutable): [`tasks/v0.beta.2/specs/stdlib-gleam.md`](tasks/v0.beta.2/specs/stdlib-gleam.md)
>

> **Goal**: grow `libs/std` into a Gleam-style stdlib — `list`, `dict`, `set`,
> `option`, `result`, `order`, `pair`, `bool`, `iterator`, `function`, `int`,
> `float`, `string`, `io` — callable as `import {list}; list.map(xs, f)` or
> via pipeline `xs |> list.map(f)`. Each module lands with its test suite.

## F0 — module layout + wiring + conventions
- [x] Relocate `prelude.zig` → `modules/compiler-core/src/comptime/stdlib/prelude.zig`
- [x] `build.zig` updated for new `std_prelude` module path
- [x] `prelude.zig` `@embedFile`s each `.bp`/`.d.bp` via relative path into `libs/std/src/`
- [x] `libs/std/AGENTS.md` + `libs/std/src/AGENTS.md` document the layout
- [x] Calling convention: qualified (`list.map(xs, f)`) + pipeline (`xs |> list.map(f)`)

## F1 — `#[@external]` annotation syntax
- [x] `#[@external(target, module, symbol)]` attribute on `pub declare fn`
- [x] `builtins.d.bp`: `pub enum Target { ... }` + `fn external(...)`
- [x] Inference: `declare fn` is typed from signature alone (no body required)
- [x] Codegen: each backend reads the external annotations

## F2 — `option` + `result` (effect types)
- [x] `?T` — builtin spelling only; `map`/`flatMap`/`unwrapOr` lowered inline
- [x] `result` — builtin namespace; `map`/`then`/`unwrap`/`isOk`/`isError`
- [x] `option_test.bp` + `result_test.bp`

## F3 — `order` + `bool` + `pair`
- [x] `order.bp` + `bool.bp` + `pair.bp`
- [x] `order_test.bp` + `bool_test.bp` + `pair_test.bp`

## F4 — `list` (core module over `Array<T>`)
- [x] `list.bp`: fold/map/filter/flatMap/flatten/range/append/prepend/reverse/take/drop/first/rest/contains/isEmpty/find/all/any/count
- [x] `list_test.bp`

## F5 — `dict` + `set`
- [x] `dict.bp`: `pub record Dict<K, V>` (association list) — new/get/hasKey/insert/delete/size/isEmpty/keys/values/fold/merge/mapValues + inline tests
- [x] `set.bp`: `pub record Set<T>` (deduplicated Array) — new/contains/size/isEmpty/insert/delete/toList/fromList/union/intersection/difference + inline tests
- [x] `dict_test.bp` + `set_test.bp`
- [x] `prelude.zig` + `comptime.zig` + `build.zig` wired for dict/set/function/io/string_builder

## F6 — `int` + `float`
- [x] `int.bp`: absoluteValue/min/max/clamp/isEven/isOdd/toString + inline tests
- [x] `float.bp`: absoluteValue/min/max/clamp/toString + floor/ceiling/round/squareRoot via `#[@external]` + inline tests
- [x] `number_test.bp`

## F7 — `string` + `string_builder`
- [x] `string.bp`: split/trim/trimStart/trimEnd/contains/startsWith/endsWith/slice/replace/toUpper/toLower/join + inline tests
- [x] `string_builder.bp`: `pub record StringBuilder` — new/append/prepend/toString/fromString/fromStrings/length/isEmpty + inline tests
- [x] `string_test.bp`

## F8 — `iterator` (lazy sequences)
- [x] `iterator.bp`: `range(start, stop)` + `repeat(value, times)` via `*fn` generators
- [x] `fromList`, `map`, `filter`, `take`, `fold`, `toList` — implemented via `loop (iter) { … }` (eager ops return `Array`)
- [x] `iterator_test.bp`: 10 tests covering range/toList/fold/map/filter/take

## F9 — `function` + `io`
- [x] `function.bp`: identity/compose/flip/constant + inline tests
- [x] `function_test.bp`
- [x] `io.d.bp`: print/println/debug via `#[@external]`

## F10 — extended modules (optional)
- [x] `queue.bp`: `pub record Queue<T>` — empty/enqueue/dequeue/peek/size/isEmpty/toList/fromList + `queue_test.bp` (7 tests)
- [ ] `bit_array`, `uri`, `regexp`, `dynamic` — per demand (need external host infrastructure)

## Known gaps (not blocking; catalogued for follow-up tasks)

1. **snake_case method JS name mapping** — `s.to_upper()` verbatim; needs typed-value dispatch. Blocks fuller string coverage.
2. **Builtin method lowering is commonJS-only** — Erlang/BEAM codegen untested.
3. **Erlang test runner can't reach "std" package modules** — escript loads entry module only. Multi-file compile pending.
4. **Literal method receivers don't parse** — `"a,b".split(",")` is a parse error; must bind to `val` first.
5. **Structural `==` on arrays is reference equality in JS** — tests compare via `.join(...)`.
6. **Local generic fns share type across call sites** — std module fns escape via `instantiateType`.
7. **`?.` codegen on erlang/beam/wasm** — blocked on record-field-access gap.
8. **`iterator.fromList` JS codegen** — `*fn` + `loop { yield }` emits `.map()` which is broken for non-Array iterables; use `loop (array) { item -> … }` directly.

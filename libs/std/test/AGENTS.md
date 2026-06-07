# libs/std/test

> Path: `libs/std/test/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

`.bp` test suite for the standard library, written with the `test { … }`
construct and run by `botopink test` from `libs/std/` (the runner discovers
both `src/` and `test/`; declaration modules `*.d.bp` are excluded from
compilation — they are type surface only).

## Layout (stdlib-tests F0 decision)

- One `<module>_test.bp` file per stdlib module, in this directory.
- Implementation modules MAY also carry inline `test` blocks next to their
  functions (Zig-style); declaration modules (`*.d.bp`) have no bodies, so
  their behaviour is tested here against the builtin lowering. First inline
  test lives in `src/bool.bp`. `"std"` package copies emitted as dependencies
  of other projects never include test blocks (no double-run).

## Tree

```text
test/
├── AGENTS.md           ← you are here
├── array_test.bp       ← builtin Array<T> surface: join/reverse/indexOf/at/map/filter/slice
├── bool_test.bp        ← bool std module: negate/nor/nand/exclusiveOr/exclusiveNor
├── option_test.bp      ← ?T builtin methods (map/flatMap/unwrapOr) + `?.` chaining
├── order_test.bp       ← order std module: lt/eq/gt, toInt, reverse, case over Order
├── pair_test.bp        ← pair std module: of/first/second/swap/mapFirst/mapSecond
├── result_test.bp      ← builtin result namespace: map/then/unwrap/isOk/isError
├── string_test.bp      ← builtin String surface: split/length/trim/slice
├── list_test.bp        ← list std module: fold/map/filter/range/append/prepend/flatten/all/any
├── number_test.bp      ← int + float std modules: absoluteValue/min/max/clamp/isEven/toString
├── iterator_test.bp    ← iterator std module: range/toList/fold/map/filter/take (eager consumers via loop)
├── dict_test.bp        ← dict std module: empty/insert/lookup/hasKey/delete/size/fold/merge/mapValues
├── set_test.bp         ← sets std module: empty/insert/contains/delete/fromList/union/intersection/difference
├── function_test.bp    ← function std module: identity/compose/flip/constant
└── queue_test.bp       ← queue std module: empty/enqueue/peek/dequeue/FIFO order/fromList/toList
```

## Running

```bash
cd libs/std && botopink test            # all suites
botopink test --filter "array map"      # by name substring
```

## Coverage status

Covered today (lowers correctly on the commonJS target):

| Surface | Methods |
|---|---|
| `String` | `split`, `.length` (on the split result), `trim`, `slice` |
| `Array<T>` | `join`, `reverse`, `indexOf`, `at`, `map`, `filter`, `slice` |
| `?T` (option) | `map`, `flatMap`, `unwrapOr`; `?.` member access (incl. null short-circuit) |
| `result` namespace | `map`, `then`, `unwrap`, `isOk`, `isError` (producer: `*fn -> @Result<D, E>`) |
| `bool` module | `negate`, `nor`, `nand`, `exclusiveOr`, `exclusiveNor` |
| `order` module | `lt`/`eq`/`gt`, `toInt`, `reverse`, `case` over the exported `Order` enum |
| `pair` module | `of`, `first`, `second`, `swap`, `mapFirst`, `mapSecond` |
| `list` module | `fold`, `map`, `filter`, `range`, `append`, `prepend`, `flatten`, `all`, `any`, `find`, `count`, `take`, `drop`, `reverse`, `first`, `rest`, `contains`, `isEmpty`, `flatMap` |
| `int` module | `absoluteValue`, `min`, `max`, `clamp`, `isEven`, `isOdd`, `toString` |
| `float` module | `absoluteValue`, `min`, `max`, `clamp`, `toString` |
| `iterator` module | `range`, `toList`, `fold`, `map`, `filter`, `take` (eager consumers via `loop (iter) { … }`) |
| `dict` module | `empty`, `lookup`, `hasKey`, `insert`, `delete`, `size`, `isEmpty`, `keys`, `values`, `fold`, `merge`, `mapValues` |
| `sets` module | `empty`, `contains`, `size`, `isEmpty`, `insert`, `delete`, `toList`, `fromList`, `union`, `intersection`, `difference` |
| `function` module | `identity`, `compose`, `flip`, `constant` |
| `queue` module | `empty`, `enqueue`, `peek`, `dequeue`, `toList`, `fromList` |

**Blocked — snake_case builtin methods lack a JS name mapping** (typed-value
method dispatch; the blind emitter writes `s.to_upper()` verbatim and JS has
no such method): `to_upper`, `to_lower`, `contains`, `starts_with`,
`ends_with`, `trim_start`, `trim_end`, `replace`, `char_at`, `index_of`,
`to_string`, `len()`; Array `push`/`pop`/`forEach` (mutation/effects) are
also untested. Add their tests when the mapping lands.

**Blocked — Erlang/BEAM**: std modules are Erlang-unreachable (escript only
loads the entry module; known gap #3). All test coverage is commonJS-only.

## Conventions

- Everything in English.
- Method receivers must be `val`-bound identifiers — string/array *literal*
  receivers (`"a,b".split(",")`) do not parse yet (parser gap, catalogued in
  the task TODO).
- Equality assertions on arrays compare via `.join(...)` until structural
  `==` on arrays lands (`assert xs == [1, 2]` lowers to reference equality
  in JS).

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
  their behaviour is tested here against the builtin lowering.

## Tree

```text
test/
├── AGENTS.md        ← you are here
├── array_test.bp    ← builtin Array<T> surface: join/reverse/indexOf/at/map/filter/slice
├── bool_test.bp     ← bool std module: negate/nor/nand/exclusive_or/exclusive_nor
├── option_test.bp   ← ?T builtin methods (map/flatMap/unwrapOr) + `?.` chaining
├── order_test.bp    ← order std module: lt/eq/gt, to_int, reverse, case over Order
├── pair_test.bp     ← pair std module: of/first/second/swap/map_first/map_second
├── result_test.bp   ← builtin result namespace: map/then/unwrap/is_ok/is_error
└── string_test.bp   ← builtin String surface: split/length/trim/slice
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
| `result` namespace | `map`, `then`, `unwrap`, `is_ok`, `is_error` (producer: `*fn -> @Result<D, E>`) |
| `bool` module | `negate`, `nor`, `nand`, `exclusive_or`, `exclusive_nor` |
| `order` module | `lt`/`eq`/`gt`, `to_int`, `reverse`, `case` over the exported `Order` enum |
| `pair` module | `of`, `first`, `second`, `swap`, `map_first`, `map_second` |

**Blocked — snake_case builtin methods lack a JS name mapping** (typed-value
method dispatch; the blind emitter writes `s.to_upper()` verbatim and JS has
no such method): `to_upper`, `to_lower`, `contains`, `starts_with`,
`ends_with`, `trim_start`, `trim_end`, `replace`, `char_at`, `index_of`,
`to_string`, `len()`; Array `push`/`pop`/`forEach` (mutation/effects) are
also untested. Add their tests when the mapping lands.

**Blocked — modules not yet implemented** (depend on `stdlib-gleam` F4–F9):
`list`, `dict`, `set`, `int`/`float` (module form), `iterator`, `function`.
The planned one-file-per-module layout for them is in
`tasks/v0.beta.2/specs/stdlib-tests.md`.

## Conventions

- Everything in English.
- Method receivers must be `val`-bound identifiers — string/array *literal*
  receivers (`"a,b".split(",")`) do not parse yet (parser gap, catalogued in
  the task TODO).
- Equality assertions on arrays compare via `.join(...)` until structural
  `==` on arrays lands (`assert xs == [1, 2]` lowers to reference equality
  in JS).

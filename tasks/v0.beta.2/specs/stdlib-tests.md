# stdlib-tests — `.bp` tests for `libs/std`, via `test-blocks` (Zig-style)

**Slug**: stdlib-tests
**Depends on**: test-blocks, stdlib-gleam
**Files**: libs/std/test/**/*.bp and/or co-located `test { … }` inside `libs/std/src/*.bp`
**Touches docs**: libs/std/AGENTS.md, libs/std/docs.md, libs/std/src/AGENTS.md, libs/std/src/examples.md
**Status**: F0 done + F1 done + F4 partial (branch task/test-blocks) — suites
for option (`?T` methods + `?.`), builtin `result` namespace, and the
stdlib-gleam F3 modules (bool/order/pair), plus the first inline (Zig-style)
test in `src/bool.bp`: 32/32 green on commonJS. Remaining suites (list, dict,
set, int/float, iterator, function) blocked on `stdlib-gleam` F4–F9;
snake_case builtin method mapping still blocks fuller string coverage; the
erlang escript runner can't reach `"std"` package modules yet —
see libs/std/test/AGENTS.md + the worktree TODO.md.

> **Goal**: a runnable test suite **for the standard library** (`libs/std`), written
> in `.bp` with the new `test { … }` construct and run by `botopink test`. Modeled on
> how the Zig stdlib (https://ziglang.org/documentation/master/) keeps `test` blocks
> next to each function — every `libs/std` module gets coverage for its public API.
>
> **Memory caveat (by design).** bp does **not** manage memory access / allocation /
> freeing, so the allocator/pointer-centric parts of a Zig-style stdlib have no bp
> analog and are **not** tested here. Anything bp cannot express is catalogued in the
> sibling spec [`zig-feature-gaps`](zig-feature-gaps.md) for later evaluation.

## Why it depends on two specs

- `test-blocks` — provides `test { … }` + `assert` + `botopink test` (the mechanism).
- `stdlib-gleam` — provides the modules under test (`list`, `dict`, `option`, …).

## Layout (decided in F0)

- Impl modules (`list.bp`, `option.bp`, …) MAY carry **inline** `test` blocks next to
  the functions (Zig-style).
- Declaration modules (`int.d.bp`, `string.d.bp`, …) get a separate `*_test.bp` (no
  body to attach to).
- Proposal: `libs/std/test/<module>_test.bp`, one file per module, discovered by
  `botopink test`.

## Coverage — one test file per stdlib module

| Module | Test file | Representative cases |
|---|---|---|
| `list` | `list_test.bp` | `fold`, `map`, `filter`, `reverse`, `take`/`drop`, `zip`, `sort` |
| `dict` | `dict_test.bp` | `insert`/`get` → `?V`, `delete`, `keys`/`values`, `merge` |
| `set` | `set_test.bp` | `insert`/`contains`, `union`, `intersection` |
| `option` | `option_test.bp` | `map`, `then`, `unwrap`, `or`, `is_some`/`is_none` |
| `result` | `result_test.bp` | `map`, `map_error`, `then`, `unwrap`, `from_option` |
| `order` | `order_test.bp` | `reverse`, `negate`, comparisons |
| `bool` / `pair` | `bool_pair_test.bp` | `negate`/`guard`; `first`/`second`/`swap` |
| `int` / `float` | `number_test.bp` | `parse`, `clamp`, `to_float`, `round`/`floor` |
| `string` | `string_test.bp` | `split`, `join`, `replace`, `slice`, `starts_with` |
| `iterator` | `iterator_test.bp` | `range`, `map`, `filter`, `take`, `to_list` |
| `function` | `function_test.bp` | `identity`, `compose`, `flip` |

## Steps

### F0 — suite layout + discovery
- [ ] Decide inline-vs-separate (above) and the `libs/std/test/` location
- [ ] Confirm `botopink test` discovers stdlib tests (depends on `test-blocks` F4)
- [ ] Add `libs/std/test/AGENTS.md` describing the suite (one file per module)

### F1 — effect types: `option` + `result`
```bp
// libs/std/test/option_test.bp
import {option};

test "option.map applies over some, skips none" {
    assert(option.map(some(3), { x -> x * 2 }) == some(6));
    assert(option.map(none, { x -> x * 2 }) == none);
}

test "option.unwrap falls back on none" {
    assert(option.unwrap(none, 0) == 0);
}
```
```bp
// libs/std/test/result_test.bp
import {result};

test "result.then short-circuits on error" {
    val r = result.then(Error("bad"), { n -> Ok(n + 1) });
    assert(result.is_ok(r) == false);
}
```

### F2 — `list` (the core module)
```bp
// libs/std/test/list_test.bp
import {list};

test "list.fold sums" {
    assert(list.fold([1, 2, 3, 4], 0, { acc, x -> acc + x }) == 10);
}

test "list.map and filter" {
    assert(list.map([1, 2, 3], { x -> x * x }) == [1, 4, 9]);
    assert(list.filter([1, 2, 3, 4], { n -> n % 2 == 0 }) == [2, 4]);
}

test "list.reverse" {
    assert(list.reverse([1, 2, 3]) == [3, 2, 1]);
}
```

### F3 — `dict` + `set`
```bp
import {dict};

test "dict.get returns option" {
    val d = dict.new() |> dict.insert("a", 1);
    assert(dict.get(d, "a") == some(1));
    assert(dict.get(d, "z") == none);
}
```

### F4 — numbers + `string`
```bp
import {int, string};

test "int.clamp bounds" {
    assert(int.clamp(10, 0, 5) == 5);
    assert(int.clamp(-3, 0, 5) == 0);
}

test "string.join" {
    assert(string.join(["a", "b", "c"], "-") == "a-b-c");
}
```

### F5 — `iterator` + `order` + `function`
```bp
import {iterator as iter, function as fun};

test "iterator pipeline" {
    val xs = iter.range(0, 4) |> iter.map({ n -> n * n }) |> iter.to_list();
    assert(xs == [0, 1, 4, 9]);
}

test "function.compose" {
    val inc = { x -> x + 1 };
    val dbl = { x -> x * 2 };
    assert(fun.compose(inc, dbl)(3) == 8);   // dbl(inc(3))
}
```

## Test scenarios

```
cli ---- botopink_test_runs_stdlib_suite_green   (every module's tests pass)
cli ---- suite_covers_each_module                (one test file per stdlib module)
cli ---- inline_tests_in_impl_modules_run        (Zig-style co-located test blocks)
```

## Notes

- Depends on `stdlib-gleam` modules existing — sequence tests behind (or alongside)
  each module's implementation phase.
- Equality assertions on arrays/records rely on structural `==`; if missing, this
  surfaces an `expect().to_equal()` need (also noted in `test-blocks`).
- **No memory/allocator/pointer tests** — see [`zig-feature-gaps`](zig-feature-gaps.md).
- Everything in English, including this file.
```

# Task: test-blocks + stdlib-tests (continuation)

**Branch**: task/test-blocks (worktree `.tasks/test-blocks/`)
**Specs**:
- `tasks/v0.beta.2/specs/test-blocks.md` (mechanism — DONE, merged into feat)
- `tasks/v0.beta.2/specs/stdlib-tests.md` (suite — in progress)

**State**: worktree fast-forwarded to feat `4ceb72f` (2026-06-05) — now includes
expr-templates AND stdlib-gleam F0–F3 (`bool.bp`, `order.bp`, `pair.bp`, builtin
`result` namespace, `?.` chaining, `from "std"` package imports). That unblocks
the first stdlib-tests suites beyond F0.

---

## Part 1 — test-blocks (mechanism) — DONE (see merged history)

Shipped: `test {…}` / `test "name" {…}` declarations, `assert` requires bool,
commonJS (node) + erlang (escript) runners via `Config.test_mode`,
`botopink test [--filter] [--target]`, `src/` + `test/` discovery.

Leftovers (deferred, not blocking):
- [ ] WASM test runner via the WASI harness
- [ ] Warn on duplicate test names (needs decl-level warning infra)
- [ ] Final docs pass: root docs.md `test`/`assert` reference; cli AGENTS/examples

---

## Part 2 — stdlib-tests: `.bp` suite for `libs/std`

### F0 — layout + discovery — DONE
- [x] `test/<module>_test.bp` per module; impl modules may carry inline tests
- [x] `botopink test` discovers `src/` + `test/`; `*.d.bp` excluded
- [x] First green suites: `string_test.bp` (3) + `array_test.bp` (6) — 9/9

### F1 — effect types (UNBLOCKED by stdlib-gleam F2)
> Revised design: `result` is a **builtin namespace** (no import);
> `option` is just `?T` + builtin methods (`map`/`flatMap`/`unwrapOr`) + `?.`.
- [x] `result_test.bp`: `result.map`, `then`, `unwrap`, `is_ok`, `is_error`
      (builtin namespace; producers need `*fn -> @Result<D, E>` — F2d rule)
- [x] `option_test.bp`: `?T` methods `map`, `flatMap`, `unwrapOr`; `?.` member
      access incl. null short-circuit (method-call chaining: when a `?.m()`
      use case lands in std modules)
- [x] FIX (compiler, found by these suites): `transform.zig` never walked
      `test { … }` decl bodies nor `assert` condition/message subexpressions —
      method/namespace lowerings (`__bp_result_*`, `?T` methods) were skipped
      inside tests (`result is not defined`, `x.map is not a function` at
      runtime). Phase 1/2 now scan+rewrite `.@"test"` bodies and `.comptime_`
      assert/assertPattern arms.

### F4 (partial) — small foundations (UNBLOCKED by stdlib-gleam F3)
- [x] `bool_test.bp`: `negate`, `nor`, `nand`, `exclusive_or`, `exclusive_nor`
- [x] `order_test.bp`: `lt`/`eq`/`gt` constructors, `to_int`, `reverse`,
      `case` over the exported `Order` enum
- [x] `pair_test.bp`: `of`, `first`, `second`, `swap`, `map_first`, `map_second`

### Still blocked (modules don't exist yet — stdlib-gleam F4–F9)
- [ ] `list_test.bp` (F2): fold, map, filter, reverse, take/drop, zip, sort
- [ ] `dict_test.bp` + `set_test.bp` (F3)
- [ ] `number_test.bp` (`int`/`float` via `@[external]`) + extended `string_test`
- [ ] `iterator_test.bp` + `function_test.bp` (F5)

### Docs
- [ ] Keep `libs/std/test/AGENTS.md` tree/coverage current per commit
- [ ] `libs/std/AGENTS.md` / `docs.md` / `src/AGENTS.md` / `src/examples.md`
      final pass when the suite stabilizes

---

## Known constraints (carry-overs)

- Method receivers must be `val`-bound — literal receivers don't parse.
- Array equality via `.join(...)` — structural `==` lowers to JS `===`.
- snake_case builtin string methods (`to_upper`, …) lack JS name mapping.
- `test/` files are `*_test.bp`, never define `main`.
- Pre-commit runs `zig build` + tests — keep the tree green per commit.
- Update the matching AGENTS.md in the same commit as any code/layout change.
- Everything in English.

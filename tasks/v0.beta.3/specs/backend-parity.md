# Backend parity + stdlib gaps

**Slug**: `backend-parity`
**Depends on**: nothing
**Files**: `modules/compiler-core/src/codegen/{js,erlang,wasm}.zig`; `modules/compiler-core/src/comptime/runtime/{node,erlang,wasm}.zig`; `libs/std/src/*.bp`
**Touches docs**: `libs/std/AGENTS.md` (remove resolved known gaps); `modules/compiler-core/src/codegen/AGENTS.md`
**Status**: pending

## Goal

Close the six open backend/stdlib gaps documented in `stdlib-gleam` known gaps
(items 1, 2, 3, 4, 7, 8) plus the WASM test runner and duplicate-name warning
deferred from `test-blocks`. These are independent of each other and can be
tackled in any order — phase them by impact.

## Steps

### F0 — `iterator.fromList` JS codegen (known gap #8)

`*fn fromList<T>(xs: Array<T>) -> @Iterator<T>` currently emits `.map()` for the
`loop (xs) { item -> yield item; }` body. This is wrong for non-Array iterables
and also redundant for Array (`.map()` transforms; we want identity yield).

- [ ] In JS codegen, detect `*fn` bodies containing `loop (arr) { item -> yield item; }`
      pattern and emit a proper generator function that `yield*`s the array
      (or emits `function*(xs) { for (const x of xs) yield x; }`)
- [ ] Alternative: change `fromList` implementation to use a different construct
      that the JS codegen already handles correctly
- [ ] Add snapshot: `codegen/node/iterator_fromList_yields_array_items`
- [ ] Update `iterator_test.bp`: add a test for `fromList` once codegen is fixed
- [ ] Remove known gap #8 from `libs/std/AGENTS.md` and `TODO.md`

### F1 — Literal method receivers (known gap #4)

`"a,b".split(",")` is currently a parse error — the parser rejects string literals
as method call receivers and requires binding to a `val` first.

- [ ] Parser: allow a string literal (and other literal types) as the receiver
      in a method call expression — `StringLit "." ident "(" args ")"` is valid
- [ ] Inference: the literal is typed normally; the method lookup proceeds as
      usual on the inferred type
- [ ] Formatter: round-trips stable
- [ ] Snapshot: `parser/literal_method_receiver`
- [ ] Update `string_test.bp` and inline string tests to use the direct form
      where appropriate
- [ ] Remove known gap #4 from `libs/std/AGENTS.md`

### F2 — snake_case → camelCase method name dispatch (known gap #1)

`s.to_upper()` is emitted verbatim in JS and fails at runtime because JS
`String.prototype` uses `toUpperCase()`. Same for `to_lower`, `trim_start`,
`trim_end`, `starts_with`, `ends_with`, `index_of`, `char_at`.

- [ ] In the JS codegen method-call lowering, apply a name-mapping table for
      string/array builtin methods: `to_upper` → `toUpperCase`, `to_lower` →
      `toLowerCase`, `trim_start` → `trimStart`, `trim_end` → `trimEnd`,
      `starts_with` → `startsWith`, `ends_with` → `endsWith`,
      `index_of` → `indexOf`, `char_at` → `charAt`
- [ ] Alternatively: normalize all method names to camelCase at the type-checker
      layer (applied universally, not just for string/array)
- [ ] Add snapshot: `codegen/node/string_snake_to_camel_dispatch`
- [ ] Add inline tests for `toUpper`, `toLower` in `string.bp` once lowering works
- [ ] Remove known gap #1 from `libs/std/AGENTS.md`

### F3 — Erlang/BEAM std package loading (known gap #3)

The Erlang escript test runner loads only the entry module; `"std"` package
modules are unreachable because multi-file compilation is not yet wired.

- [ ] Investigate Erlang multi-module compile: emit each std module as a separate
      `.erl` / `.beam` file, then reference via module name in the entry module
- [ ] Or: inline all std module code into the generated entry module (simpler,
      avoids multi-file orchestration, but larger output)
- [ ] Wire the std package into `comptime/runtime/erlang.zig` so qualified
      calls like `list:map(Xs, F)` reach the correct Erlang module
- [ ] Add snapshot: `codegen/erlang/std_package_list_map_via_erlang`
- [ ] Remove known gap #3 from `libs/std/AGENTS.md`

### F4 — `?.` codegen for Erlang/BEAM/WASM (known gap #7)

Optional chaining `?.` works on commonJS but is not lowered for Erlang, BEAM, or
WASM (blocked on record-field-access gap).

- [ ] Identify the exact record-field-access gap blocking `?.` in each backend
- [ ] Erlang: lower `x?.field` to a case/match expression on `{ok, Val}`
- [ ] WASM/WAT: lower to a conditional check on the optional tag
- [ ] Snapshots per backend: `codegen/erlang/optional_chain`, `codegen/wasm/optional_chain`
- [ ] Remove known gap #7 from `libs/std/AGENTS.md`

### F5 — WASM test runner (deferred from `test-blocks`)

The `test-blocks` spec deferred the WASM test runner. Run `test { … }` blocks on
the WASM backend.

- [ ] Emit test runner shim for WASM output (similar to JS runner)
- [ ] Wire WASM runner into `botopink test` CLI (alongside node/erlang)
- [ ] Snapshot: `codegen/wasm/test_runner_basic`

### F6 — Duplicate test name warning (deferred from `test-blocks`)

Two `test "same name" { … }` blocks in the same file should emit a warning (not
an error — behavior is still deterministic, last one wins or first one wins).

- [ ] In `inferTestDecl` (or a post-inference pass), collect test names per
      source file and emit `Diagnostic.warning` on duplicates
- [ ] Snapshot: `comptime/duplicate_test_name_warning`

## Test scenarios

```
codegen/node ---- iterator_fromList_yields_array_items
parser ---- literal_method_receiver
codegen/node ---- string_snake_to_camel_dispatch
codegen/erlang ---- std_package_list_map_via_erlang
codegen/erlang ---- optional_chain
codegen/wasm ---- optional_chain
codegen/wasm ---- test_runner_basic
comptime ---- duplicate_test_name_warning
```

## Notes

- Each phase is independent; tackle in order of impact (F0 fixes a correctness
  bug; F1 improves ergonomics; F2 unblocks string module; F3 requires more
  infrastructure than the others).
- F3 (Erlang std package) is the heaviest item — may need its own branch.
- The `io` module (`io.d.bp`) already has correct multi-target `#[@external]`
  annotations: `#[@external(node, "console", "log"), @external(erlang, "io", "format")]`.
  F3 may transitively fix io runtime on Erlang if std package loading is resolved.
- Known gap #2 (builtin method lowering commonJS-only) is a subset of F3
  (Erlang backend) and F2 (name mapping) — no separate phase needed.
- Known gap #5 (structural `==` on arrays is reference equality in JS) is a
  deep semantic gap — deferred; document workaround (`.join(…)`) in `AGENTS.md`
  and do not add a fix phase here.

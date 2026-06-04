# Task: stdlib-gleam

**Branch**: task/stdlib-gleam (worktree `.tasks/stdlib-gleam/`)
**Spec**: `tasks/v0.beta.2/specs/stdlib-gleam.md`
**Depends on**: nothing

**Goal**: grow `libs/std` from 4 declaration files into a Gleam-style module set
(`list`, `dict`, `set`, `option`, `result`, `order`, `bool`, `pair`, `int`, `float`,
`string`, `string_builder`, `iterator`, `function`, `io`), callable as
`import {list}; list.map(xs, f)` or via pipeline `xs |> list.map(f)`.

**Architecture (working assumption — hybrid, flippable):**
- Pure-logic modules → real `.bp` implementations (compile once, all backends):
  `list`, `dict`, `set`, `option`, `result`, `order`, `pair`, `bool`, `iterator`, `function`.
- Primitive/host-backed → declarations + externals (`.d.bp`, codegen/FFI per target):
  `int`, `float`, `string`, `io`, `bit_array`.

**Files**: `libs/std/src/*.bp`, `libs/std/src/*.d.bp` (`.bp`-only — no Zig in libs/std);
loader relocated `libs/std/src/prelude.zig` → `modules/compiler-core/src/comptime/stdlib/prelude.zig`
(+ `build.zig`); F1 (`@external`) touches `modules/compiler-core/src/{lexer,parser,ast,comptime,codegen}/*`.

**Docs to update**: `libs/std/AGENTS.md`, `libs/std/docs.md`, `libs/std/src/AGENTS.md`,
`libs/std/src/examples.md`, root `docs.md` (language reference: `@external`),
`modules/compiler-core/src/codegen/AGENTS.md`.

---

## F0 — module layout + wiring + conventions
- [x] Relocate embed/loader glue out of `libs/std/`: move `prelude.zig` to
      `modules/compiler-core/src/comptime/stdlib/prelude.zig` (next to its consumer —
      `comptime` calls `registerStdlib`); `libs/std/src/` keeps only `.bp`/`.d.bp`
- [x] Update `build.zig` for the relocated `std_prelude` Zig module path
- [x] Relocated `prelude.zig` `@embedFile`s each `.bp`/`.d.bp` — NOTE: relative
      paths escaping the module root are rejected by Zig (`embed of file outside
      package path`); instead each file is an anonymous import declared in
      `build.zig` (`std_bp_files` → `addAnonymousImport`), embedded by name
- [x] Update `libs/std/AGENTS.md` + `docs.md` (+ `src/AGENTS.md`, `src/docs.md`,
      `libs/AGENTS.md`, `modules/docs.md`, new `comptime/stdlib/AGENTS.md`,
      `comptime/AGENTS.md` tree): `src/` is `.bp`-only; loader lives in compiler-core
- [ ] Decide calling convention: qualified (`list.map(xs, f)`) and/or pipeline
      (`xs |> list.map(f)`) — revisit at F2 when the first impl module lands

## F1 — annotation syntax `@[…]` + `external` builtin (FFI primitive; prerequisite for decl modules)
`@external` is NOT a parser keyword — it is a builtin function declared in
`builtins.d.bp`, invoked inside generic annotation syntax `@[ … ]` above a declaration.
- [x] Builtins: declared in `builtins.d.bp` (documentation — the file is not yet
      embedded; validation is programmatic in `comptime/infer.zig`):
      `enum Target { node, typescript, erlang, beam, wasm }` +
      `fn external(target: Target, module: string, symbol: string)`
- [x] Lexer/parser: annotation block `@[ <builtin-call> ("," <builtin-call>)* ]`
      (no lexer change needed — `.at` + `.leftSquareBracket`; `parseAnnotations`
      handles both `#[…]` and `@[…]`; `skipAnnotationsLookaheadFrom` + top-level
      dispatch extended; `parseFnBody` allows bodyless fn when `external` present)
- [x] AST: reuses existing `decl.annotations: []Annotation { name, args }`;
      added `FnDecl.isExternal()` / `FnDecl.externalFor(target)` + `ast.ExternalRef`
- [x] Inference: `validateExternalAnnotation` (arity 3, target ∈ Target,
      module/symbol string literals); bodyless external fn typed from signature
- [x] Codegen: erlang lowers calls to remote `module:symbol(Args)` (decl emits
      nothing, excluded from export); commonJS emits
      `const { symbol: name } = require("module")` (+ `exports.name` for pub);
      no matching target → `error.MissingExternalTarget` at the call site;
      beam/wasm untouched for now (external fn emits as empty local fn — F6 scope)
- [x] Tests: parser `annotation_block_at_bracket` (+ decl-then-next-decl),
      comptime `external_builtin_typechecks_args` + `external_wrong_arity` +
      `external_fn_no_body_typechecks`, codegen `external_call_emits_module_symbol`
      + `external_import_binds_symbol` (all 4 targets snapshotted)

## F2 — `option` + `result` (effect types over built-ins)
- [ ] `option.bp`: `map`, `then` (flat_map), `unwrap`, `or`, `is_some`, `is_none`, `to_result`
- [ ] `result.bp`: `map`, `map_error`, `then`, `unwrap`, `unwrap_error`, `or`, `is_ok`, `from_option`
- Note: build on the EXISTING `@Option`/`@Result` method work (`map`/`flatMap`/`unwrapOr`
  from the stdlib-result task) — extend, don't duplicate.

## F3 — `order` + `bool` + `pair` (small foundations)
- [ ] `order.bp`: `enum Order { Lt, Eq, Gt }` + `reverse`, `negate`, `to_int`
- [ ] `bool.bp`: `negate`, `and`, `or`, `to_string`, `guard`
- [ ] `pair.bp`: `first`, `second`, `map_first`, `map_second`, `swap`

## F4 — `list` (the core module, over `Array<T>`)
- [ ] Folds: `fold`, `fold_right`, `reduce`
- [ ] Transform: `map`, `index_map`, `filter`, `filter_map`, `flat_map`, `flatten`
- [ ] Query: `length`, `is_empty`, `contains`, `find`, `all`, `any`, `count`
- [ ] Build/slice: `append`, `prepend`, `reverse`, `take`, `drop`, `first`, `rest`, `range`
- [ ] Combine: `zip`, `unzip`, `intersperse`, `sort` (with `order`)
- Note: confirm list patterns `[]` / `[x, ..rest]` are accepted by the parser
  (used in every impl).

## F5 — `dict` + `set`
- [ ] `dict.bp`: `new`, `get`, `insert`, `delete`, `keys`, `values`, `size`, `merge`, `fold`, `map_values`
- [ ] `set.bp`: `new`, `insert`, `contains`, `delete`, `union`, `intersection`, `to_list` (on top of `dict`)

## F6 — `int` + `float` (declarations + externals, via F1 `@[external(…)]`)
- [ ] `int.d.bp`: `parse`, `to_float`, `to_string`, `absolute_value`, `min`, `max`, `clamp`, `power`, `is_even`
- [ ] `float.d.bp`: `parse`, `round`, `floor`, `ceiling`, `truncate`, `to_string`, `power`, `square_root`

## F7 — `string` (+ `string_builder`, via F1 `@[external(…)]`)
- [ ] Extend `string.d.bp` to Gleam's surface: `length`, `reverse`, `replace`, `split`,
      `join`, `pad_left`, `pad_right`, `slice`, `contains`, `starts_with`, `to_graphemes`
- [ ] `string_builder.bp`: `new`, `append`, `from_strings`, `to_string` (efficient concat)

## F8 — `iterator` (lazy sequences)
- [ ] `iterator.bp`: `from_list`, `map`, `filter`, `take`, `fold`, `to_list`, `range`, `repeat`
- [ ] Build on botopink's `@Iterator<_>` / `*fn` generators

## F9 — `function` + `io` (`io` via F1 `@[external(…)]`)
- [ ] `function.bp`: `identity`, `compose`, `flip`, `const`
- [ ] `io.d.bp`: `print`, `println`, `debug` (host-backed)

## F10 — extended modules (optional)
- [ ] `bit_array`, `uri`, `regexp`, `dynamic`, `queue` — scope per demand

---

## Test scenarios

```
comptime ---- option_map_some_none           (inference: ?T threads through)
comptime ---- result_then_chains_error
comptime ---- list_fold_map_filter_infer
comptime ---- list_sort_with_order
comptime ---- dict_get_returns_option
comptime ---- iterator_range_map_to_list
codegen/node ---- list_map_filter            (CommonJS output)
codegen/erlang ---- list_fold                 (Erlang output)
codegen/beam ---- option_unwrap               (BEAM output)
codegen/wasm ---- int_clamp                   (WAT output / external)
parser ---- module_qualified_call list.map(xs, f)
parser ---- annotation_block_at_bracket            (@[ external(…), external(…) ] over a decl)
comptime ---- external_builtin_typechecks_args     (external(target, module, symbol) vs builtins.d.bp)
comptime ---- external_fn_no_body_typechecks
codegen/erlang ---- external_call_emits_module_symbol  (string:length/1)
codegen/node ---- external_call_emits_import           (import {string_length})
```

## Notes
- Architecture is the one open decision. Hybrid is the assumption; declarations-only
  fallback = turn every `.bp` impl into a `.d.bp` signature + push bodies into codegen.
- Each new file MUST get a matching `@embedFile` in the relocated `prelude.zig`
  (under `modules/compiler-core/src/comptime/stdlib/`) or inference won't see it.
- Keep signatures additive/stable — renames churn every codegen/comptime snapshot.
- Update the matching `AGENTS.md` for every code/layout change in the same commit.

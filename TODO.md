# Task: test-blocks + stdlib-tests

**Branch**: task/test-blocks (worktree `.tasks/test-blocks/`)
**Specs**:
- `tasks/v0.beta.2/specs/test-blocks.md` (mechanism — no dependencies)
- `tasks/v0.beta.2/specs/stdlib-tests.md` (suite — depends on test-blocks, stdlib-gleam)

**Order**: test-blocks first (provides `test { … }` + `assert` + `botopink test`),
then stdlib-tests (uses the mechanism to cover `libs/std`).

---

## Part 1 — test-blocks: `test { … }` / `test "name" { … }` declarations

Goal: first-class `test` declaration (Zig/Gleam-style). Tests live next to the code,
are collected at compile time, and run with `botopink test`. Anonymous and named forms.

Grammar (top-level declaration):
```
testDecl ::= "test" string? block
```

### F0 — `test` declaration (front-end) — DONE
- [x] Lexer: `test` keyword token (already existed as a reserved word)
- [x] Parser: top-level `test string? block` → `TestDecl` (`parser/decls.zig: parseTestDecl`)
- [x] AST: `TestDecl { name: ?[]const u8, body: []Stmt, loc }` + `DeclKind.@"test"`
- [x] Formatter: round-trip stable (`fmtTestDecl`; no trailing semicolon)
- [x] Snapshots: `parser/test_anonymous`, `parser/test_named`, `parser/test_named_with_message_assert`
- [x] Codegen: all 5 backends (commonJS/erlang/beam_asm/wat/typescript) skip `.@"test"` in normal build
- [x] Docs: parser/format/codegen AGENTS.md + parser/examples.md + root docs.md (Test Blocks section)

### F1 — `assert` builtin
> **Finding (F0):** `assert` already exists as an expression-level *keyword*
> (`assert cond [, "msg"]` — no call parens; AST: `comptime_.assert` in
> `parser/exprs.zig:253`). Canonical style is keyword form, not `assert(...)`.
> F1 should adapt the existing assert (runtime lowering + failure recording)
> rather than add a new builtin in `builtins.d.bp`.
- [x] Review existing `comptime_.assert` semantics: runtime lowering exists per backend (JS `console.assert`, Erlang `true = (...)`); kept for normal builds
- [x] Inference: `cond: bool` (unified in `infer.zig` `.assert` case; snapshot `comptime/*/errors/assert_requires_bool`); usable broadly (Zig-style), only `test` blocks collected by runner
- [x] Lowering (commonJS test mode): `assert c[, m]` → `__bp_assert(c, m, "<module>.bp:<line>")` which throws; the runner catches per test, records the failure, and continues

### F2 — inference / validation — DONE (duplicate-name warning deferred)
- [x] A `test` body type-checks like a `fn` body returning void (`inferTestDecl` in both `inferDecl` and `inferDeclTyped` paths; snapshots `comptime/*/errors/test_body_type_error`)
- [x] `test` is a **top-level** declaration only (parse error inside fn body — F0)
- [ ] Optional: warn on duplicate test names (deferred — no warning infra at decl level yet)
- [x] Tests excluded from normal `build`/`run` output (codegen skips — F0)

### F3 — codegen + runner (phase by backend)
- [x] Collect all `TestDecl`s into a generated registry per target (`__bp_tests` array; `Config.test_mode` flag)
- [x] **CommonJS/node** first: each test emits as `__bp_test_N()` + `__bp_run_tests()` runner; `main/0` not auto-invoked in test mode
- [x] **Erlang/BEAM**: tests emit as `'__bp_test_N'/0` functions + `'__bp_run_tests'/1` runner + `main/1` escript entry; `assert` lowers to a caught `erlang:error({bp_assert, Msg, Loc})`; verified green/fail/filter via `botopink test --target erlang`
- [ ] **WASM**: emit + run via the WASI harness (deferred)
- [x] Snapshot: `codegen/node/commonJS/test_runner` (+ normal-build exclusion check)
- [x] Snapshot: `codegen/erlang/erlang/test_runner`

### F4 — `botopink test` CLI + reporting — DONE (commonJS)
- [x] New subcommand `modules/compiler-cli/src/cli/test_cmd.zig` (artifacts → `.botopinkbuild/test-out/`)
- [x] Compile in test mode, run via node, aggregate exit codes per module
- [x] Report: name, pass/fail, failure message + source loc, summary counts; exit 1 on any failure
- [x] `--filter <substr>` to select tests by name (passed to the runner via argv)

### Bonus — parser: calls as binary operands (pre-existing gap, required by tests)
- [x] `f(args) == x` / `f(args) + 1` etc. failed to parse anywhere (also on `feat`).
      Fixed: `parsePrimary` now parses `ident(args)` calls + `.method(args)` chain links,
      and `parseExpr`'s call-chain shortcut rolls back when a binary operator follows
      (`isBinaryOpNext`). Snapshots: `parser/call_as_binary_operand`,
      `parser/method_chain_as_binary_operand`, `parser/assert_on_call_equality`.

### test-blocks scenarios
```
parser ---- test_anonymous            (test { … })
parser ---- test_named                (test "name" { … })
parser ---- test_rejects_in_fn_body   (top-level only)
comptime ---- assert_requires_bool
comptime ---- test_body_typechecks
format ---- test_roundtrip
codegen/node ---- test_runner_emits_registry
codegen/erlang ---- test_runner_eunit
cli ---- botopink_test_runs_and_reports
cli ---- botopink_test_filter
```

### test-blocks docs
- [ ] docs.md (language reference: `test`/`assert`)
- [ ] modules/compiler-core/src/parser/{AGENTS.md,examples.md}
- [ ] modules/compiler-core/src/codegen/AGENTS.md
- [ ] modules/compiler-cli/src/cli/{AGENTS.md,examples.md}

---

## Part 2 — stdlib-tests: `.bp` test suite for `libs/std`

Goal: runnable test suite for the standard library, written in `.bp` with `test { … }`
and run by `botopink test`. Modeled on the Zig stdlib (test blocks next to functions).
No memory/allocator/pointer tests (bp doesn't manage memory) — gaps go to
`tasks/v0.beta.2/specs/zig-feature-gaps.md`.

### F0 — suite layout + discovery — DONE
- [x] Decided: impl modules MAY carry inline `test` blocks; declaration modules (`*.d.bp`) get separate `libs/std/test/<module>_test.bp`
- [x] `botopink test` discovers `test/` in addition to `src/` (test modules compile last so `src/` exports resolve); `*.d.bp` declaration files excluded from compilation (scanner)
- [x] Cross-module imports work in the runner: `module.js` aggregator merges all module exports; runners execute only as the entry module (`require.main === module`)
- [x] Added `libs/std/test/AGENTS.md` (layout, running, coverage status, gaps)
- [x] First green suites: `libs/std/test/string_test.bp` (3 tests) + `array_test.bp` (6 tests) — 9/9 pass via `cd libs/std && botopink test`

### F1 — effect types: `option` + `result`
- [ ] `option_test.bp`: `map`, `then`, `unwrap`, `or`, `is_some`/`is_none`
- [ ] `result_test.bp`: `map`, `map_error`, `then`, `unwrap`, `from_option`

### F2 — `list` (the core module)
- [ ] `list_test.bp`: `fold`, `map`, `filter`, `reverse`, `take`/`drop`, `zip`, `sort`

### F3 — `dict` + `set`
- [ ] `dict_test.bp`: `insert`/`get` → `?V`, `delete`, `keys`/`values`, `merge`
- [ ] `set_test.bp`: `insert`/`contains`, `union`, `intersection`

### F4 — numbers + `string`
- [ ] `number_test.bp`: `int.parse`, `int.clamp`, `to_float`, `float.round`/`floor`
- [ ] `string_test.bp`: `split`, `join`, `replace`, `slice`, `starts_with`
- [ ] `bool_pair_test.bp`: `bool.negate`/`guard`; `pair.first`/`second`/`swap`
- [ ] `order_test.bp`: `reverse`, `negate`, comparisons

### F5 — `iterator` + `function`
- [ ] `iterator_test.bp`: `range`, `map`, `filter`, `take`, `to_list`
- [ ] `function_test.bp`: `identity`, `compose`, `flip`

### stdlib-tests scenarios
```
cli ---- botopink_test_runs_stdlib_suite_green   (every module's tests pass)
cli ---- suite_covers_each_module                (one test file per stdlib module)
cli ---- inline_tests_in_impl_modules_run        (Zig-style co-located test blocks)
```

### stdlib-tests docs
- [ ] libs/std/AGENTS.md, libs/std/docs.md
- [ ] libs/std/src/AGENTS.md, libs/std/src/examples.md

---

## Discovered gaps (catalogued for follow-up specs)

1. **Snake_case builtin methods have no JS name mapping** — the blind commonJS
   emitter writes `s.to_upper()` verbatim; only methods whose botopink name
   matches the JS native (`split`, `trim`, `slice`, `join`, `reverse`,
   `indexOf`, `at`, `map`, `filter`) work. Blocks most of `string_test.bp`.
   Needs typed-value method dispatch (loc-keyed rewrites, like F6 extension
   dispatch) — stdlib/method-lowering work, not test-blocks.
2. **Literal method receivers don't parse** — `"a,b".split(",")` is a parse
   error (also on `feat`); receivers must be `val`-bound identifiers.
3. **Structural `==` on arrays** — lowers to JS `===` (reference equality);
   suites compare via `.join(...)`. Surfaces the `expect().to_equal()` need
   noted in both specs.
4. **`fn main/0` defined in a `test/` module** would collide with `src/main`
   module names — convention: `test/` files are `*_test.bp`, no main.

## Fixed along the way (pre-existing, reproduced on `feat`)

- Parser: calls/method-chains as binary operands (`f(x) == 3`,
  `s.split(",").length == 2`) — see Part 1 bonus.
- commonJS codegen: lambda tail expressions now `return` their value
  (`ns.map({ x -> x * x })` produced `undefined` before); 4 Result/Option
  snapshots re-baselined with the corrected output.
- erlang codegen: `true`/`false` identifiers emitted as unbound `True`/`False`
  variables — now stay lowercase atoms; 5 erlang snapshots re-baselined
  (run logs now show real output instead of crashes).

## Notes

- Part 2 modules (`list`, `dict`, `option`, `result`, `iterator`, …) depend on
  `stdlib-gleam` existing — F1–F5 of stdlib-tests remain blocked on it; write
  each module's tests alongside its implementation.
- `assert` failing must **not** abort the run — record + continue so the runner reports all results. (Done: per-test catch in the runner.)
- Pre-commit runs `zig build` + tests — keep the tree green per commit.
- Everything in English, including this file.
---

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
> **OPEN DECISION (blocks F2)** — calling convention for stdlib modules.
> `import {option}; option.map(x, f)` needs stdlib module namespacing in
> inference, which does not exist yet (`registerStdlib` flattens everything
> into one global env). Options on the table:
> 1. real namespace: module→exports table in inference (correct, more work)
> 2. flat prefix: register `option.map` as a qualified/prefixed global binding
>    and reuse erlang's PascalCase lowering (`List.map` → `list:map`)
> 3. methods on types: `xs.map(f)` via extension dispatch instead of Gleam-style
>    `list.map(xs, f)`

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

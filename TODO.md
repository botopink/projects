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
- [ ] **Erlang/BEAM**: emit eunit-style test functions
- [ ] **WASM**: emit + run via the WASI harness (deferred)
- [x] Snapshot: `codegen/node/commonJS/test_runner` (+ normal-build exclusion check)
- [ ] Snapshot: `codegen/erlang/test_runner` (with the Erlang runner)

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

## Notes

- Part 2 modules (`list`, `dict`, `option`, `result`, `iterator`, …) depend on
  `stdlib-gleam` existing — F1–F5 of stdlib-tests remain blocked on it; write
  each module's tests alongside its implementation.
- `assert` failing must **not** abort the run — record + continue so the runner reports all results. (Done: per-test catch in the runner.)
- Pre-commit runs `zig build` + tests — keep the tree green per commit.
- Everything in English, including this file.

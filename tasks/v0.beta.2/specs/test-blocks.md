# test-blocks — `test { … }` / `test "name" { … }` declarations (Zig/Gleam-style)

**Slug**: test-blocks
**Depends on**: nothing
**Files**: modules/compiler-core/src/{lexer,parser,ast,comptime,format,codegen}/*, modules/compiler-cli/src/cli/* (a `test` subcommand), libs/std/src/builtins.d.bp (assert)
**Touches docs**: docs.md (language reference: `test`/`assert`), modules/compiler-core/src/parser/{AGENTS.md,examples.md}, modules/compiler-core/src/codegen/AGENTS.md, modules/compiler-cli/src/cli/{AGENTS.md,examples.md}
**Status**: mostly done (branch task/test-blocks) — F0 front-end, F1 assert,
F2 inference, F3 runners (commonJS + erlang; WASM deferred), F4 `botopink test`
CLI all landed. Remaining: WASM runner, optional duplicate-name warning.

> **Goal**: a first-class `test` declaration, like Zig (`test "name" { … }`) and
> Gleam (test modules) — tests live next to the code, are collected at compile time,
> and run with `botopink test`. Anonymous (`test { … }`) and named
> (`test "addition" { … }`) forms.

## Target syntax

```bp
test {
    assert(1 + 1 == 2);
}

test "addition works" {
    val r = add(2, 3);
    assert(r == 5);
}
```

Grammar (top-level declaration):
```
testDecl ::= "test" string? block
```
- optional string literal = the test name (anonymous test has none)
- `block` is the same statement block used by `fn` bodies
- `assert(cond)` (and `assert(cond, msg)`) is a builtin that fails the enclosing test

## Examples

### Anonymous + named
```bp
test { assert(true); }

test "string split" {
    val parts = string.split("a,b", ",");
    assert(parts.length == 2);
}
```

### Assertion with message + equality helper
```bp
test "map doubles" {
    val got = list.map([1, 2, 3], { x -> x * 2 });
    assert(got == [2, 4, 6], "map should double each element");
}
```

### Running
```bash
botopink test            # compile + run every test block in the project
botopink test --filter "split"   # only tests whose name matches
```
```text
running 3 tests
  ok   addition works
  ok   string split
  FAIL map doubles  (expected [2,4,6], got [2,4,5])  at src/list_test.bp:12
2 passed, 1 failed
```

## Steps

### F0 — `test` declaration (front-end)
- [ ] Lexer: `test` keyword token
- [ ] Parser: top-level `test string? block` → `TestDecl`
- [ ] AST: `TestDecl { name: ?[]const u8, body: Block, loc }`
- [ ] Formatter: round-trip stable (`test { … }`, `test "name" { … }`)
- [ ] Snapshots: `parser/test_anonymous`, `parser/test_named`

### F1 — `assert` builtin
- [ ] Declare in `builtins.d.bp`: `fn assert(cond: bool)` and `fn assert(cond: bool, msg: string)`
- [ ] Inference: `assert` returns nothing; `cond: bool`; usable only inside a `test` body (or anywhere? decide — Zig allows it broadly)
- [ ] Lowering: `assert(c)` → a runtime check that records a failure (with `src` loc) instead of a hard panic, so the runner can continue

### F2 — inference / validation
- [ ] A `test` body type-checks like a `fn` body returning `Nil`/void
- [ ] `test` is a **top-level** declaration only (error inside a fn/block)
- [ ] Optional: warn on duplicate test names
- [ ] Tests are excluded from normal `build`/`run` output (only compiled under `test`)

### F3 — codegen + runner (phase by backend)
- [ ] Collect all `TestDecl`s into a generated registry per target
- [ ] **CommonJS/node** first: emit each test as a function + a runner entry; `botopink test` executes via node
- [ ] **Erlang/BEAM**: emit eunit-style test functions
- [ ] **WASM**: emit + run via the WASI harness (or mark deferred)
- [ ] Snapshots: `codegen/node/test_runner`, `codegen/erlang/test_runner`

### F4 — `botopink test` CLI + reporting
- [ ] New subcommand in `modules/compiler-cli/src/cli/` (alongside build/run/check/format)
- [ ] Compile in test mode, run, collect pass/fail
- [ ] Report: name, pass/fail, failure message + source loc, summary counts
- [ ] `--filter <substr>` to select tests by name

## Test scenarios

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

## Notes

- This is botopink's **own language** test construct (`.bp` tests run by
  `botopink test`) — distinct from the compiler's internal Zig snapshot suite
  (`zig build test`), which is unaffected.
- `assert` failing should **not** abort the whole run — record + continue, so the
  runner reports all results. A separate hard `@panic` already exists for aborts.
- Open: does `assert` work outside `test` blocks (Zig-style, broadly) or only inside
  tests? Default here: usable broadly, but only `test` blocks are collected by the runner.
- Equality in `assert(got == expected)` relies on structural `==`; confirm the
  inference/codegen support it for arrays/records, else add an `expect().to_equal()` helper.
- Everything in English, including this file.
```

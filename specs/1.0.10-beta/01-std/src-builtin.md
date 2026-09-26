# `@src()` — the source-location builtin

Step 1 of the front. Paths are under `repository/botopink-lang/modules/compiler-core/src/` unless
said otherwise.

## What it is

```bp
pub type SourceLocation(file: string, line: i32, column: i32, fnName: string)

fn where() -> SourceLocation {
    return @src();
}

test "src: a test knows its own name" {
    val loc = @src();
    try asserts.equals(loc.fnName, "src: a test knows its own name");
    try asserts.equals(loc.file, "src/example.bp");
}
```

`@src()` is a value of type `SourceLocation` naming the place it is written. It is evaluated at
compile time: the four fields are literals at the call site and the expression costs nothing at
run time. It mirrors Zig's `@src()` (`std.builtin.SourceLocation{module, file, fn_name, line,
column}`) — the compiler's own snapshot tests are written that way (`codegen/tests/builtins.zig`:
`try h.assertJsSingle(std.testing.allocator, @src(), …)`), and the std contract is the same test
written in botopink.

## The record

| Field | Type | Value |
|---|---|---|
| `file` | `string` | the path of the source file **relative to the root of the package it belongs to**, forward slashes, with extension: `src/emilia.bp`, `test/onze_test.bp`, `src/shapes/circle.bp` |
| `line` | `i32` | 1-based line of the `@` character |
| `column` | `i32` | 1-based column of the `@` character — the same numbers the diagnostics print as `--> <file>:L:C` |
| `fnName` | `string` | see *What `fnName` is* |

**Why package-relative and not absolute.** The value goes into failure messages, into the
`__snapshots__/` path (`snapshots.md`), and therefore into files that are committed and compared
across machines and CI runners. An absolute path would make every snapshot header host-specific and
every `FAIL` line unreproducible. Package-relative is also what the runner prints — `TEST
<file>:<line>` (`compiler-cli/AGENTS.md` § *`botopink test` output format*).

**Why the package root and not `src/`.** `snapshots.path(loc)` is `<dir of loc.file>/__snapshots__/…`.
A test in `src/emilia.bp` and one in `test/emilia_test.bp` must not share a directory, and
`src/`-relative paths (what `env.modulePath` holds) would collapse them. The package root is the
directory that holds `botopink.json`, and `botopink test` runs from it, so `path(loc)` resolves
against the process's working directory with no further lookup.

**Why no `module` field.** The package name lives in `botopink.json` and the front end never sees
it; `file` is already unique inside a package, and the `-test` helpers do not need the package name.
Adding a field later is **not** additive — a record constructor's arity changes and every
hand-written `SourceLocation(…)` literal breaks — so the four-field record is the decision.

## What `fnName` is

| Position of `@src()` | `fnName` |
|---|---|
| inside `test "css: modifiers ---- hover"` | `css: modifiers ---- hover` — the test name, verbatim, no `test.` prefix |
| inside an unnamed `test { … }` | `test_<idx>` — the same fallback the commonJS test registry uses |
| inside `fn tokensToCss(…)` | `tokensToCss` |
| inside a method `fn thenReturn(self: Self, …)` of `type Stub` | `Stub.thenReturn` |
| inside a lambda | the enclosing named fn/test/method — a lambda has no name |
| at module level (`val loc = @src();`) | `""` |
| inside a `comptime { … }` block or a decorator body | the enclosing fn, or `""` |

The raw test name rather than Zig's `test.<name>` because the one consumer of `fnName` —
`snapshots.path` — reads the suite and slug straight out of it, and the runner's `TEST` line
prints the raw name. A test name may contain spaces and colons and a fn name may not, so the two
never collide.

## Checker rule

`@src()` is an expression of type `SourceLocation`. It is legal anywhere a value is legal: a `val`
initializer, an argument, a `return`, a record field, module scope. It takes no arguments, no type
arguments, and no trailing lambda. It is not a type, not an annotation and not a statement.

| Form | Result |
|---|---|
| `@src()` | `SourceLocation` |
| `@src(1)`, `@src(x)`, `@src{ … }` | `error[src-takes-no-arguments]` at the call |
| `@src` without parentheses | parse error, as for every builtin call |
| `@Src()` | `error[unknown-builtin]` — builtin names are exact |
| `val x: i32 = @src();` | ordinary type mismatch: `expected i32, got SourceLocation` |

## How it lowers — a record literal, on every backend

`@src()` is **rewritten during inference** into the ordinary constructor call
`SourceLocation(file: "src/a.bp", line: 12, column: 15, fnName: "x: y")`, with the four arguments
as literal expressions — the same "rewrite at inference, lower as ordinary code" route
`@makeRecord(…)` takes (`tryEvalMakeRecord`). From then on it is a record construction like any
other:

| Backend | Output for the example |
|---|---|
| commonJS | `new SourceLocation("src/a.bp", 12, 15, "x: y")` |
| erlang | `#{file => <<"src/a.bp">>, line => 12, column => 15, fnName => <<"x: y">>}` |
| beam | the same map, as `.S` instructions |
| wasm | a heap record with four fields |

**No codegen file changes**, and every pre-existing codegen fixture stays byte-identical. If a
backend needs a change to lower `@src()`, the rewrite is wrong, not the backend.

`SourceLocation` is declared in the reflection prelude (`comptime.zig` `decl_reflection_src`, beside
`Span`, `Annotation`, `Param`, `Field`, `Method` and `Decl`), registered into every `Env`, and the
backends learn its field list the way they learn `Span`'s. The documented surface is in
`libs/std/src/builtins.d.bp` beside `@Decl`, and in `docs.md` § *Builtins*.

**Where the compiler keeps the inputs.** `Module.srcPath` (`module.zig`; `""` means `<path>.bp`, what
the tests and the LSP pass) is computed by the CLI as `<src dir name>/<module path>.bp` for package
modules and `test/<name>.bp` for flat test files, and copied to `env.srcPath`; `env.currentFnName`
is set and restored by the fn, test and method walkers of `comptime/infer.zig`.

## The test body as a fallible context

**Inside a `test` body, a `try` whose operand is `Error(e)` ends the test as `FAIL <name> (<e>) at
<file>:<line>`.** On commonJS the propagate form emitted inside the test function is
`throw new Error(<e>)`, which the runner's `catch` prints as the FAIL line; on erlang the test
function raises `erlang:error(<e>)`, which the escript runner catches. `<e>` is the error string; a
non-string `E` is rendered with the backend's `$stringify` form. The `at <file>:<line>` is the
test's own line; the assertion's line is in the message when the helper put it there with `@src()`.

## Tests and snapshots in `modules/compiler-core`

Fixture names follow `codegen/tests/helpers.zig` (`slugFromSrc`): the text after the first `": "`
of the Zig test name, slugified with `_`.

| Zig test (in `codegen/tests/builtins.zig`) | Fixture(s) | Asserts |
|---|---|---|
| `"js: src ---- in a test"` | `src_in_a_test.snap.md` | `new SourceLocation("main.bp", L, C, "src: in a test")` with the literal numbers |
| `"js: src ---- in a fn"`, `"… in a method"`, `"… at module level"` | one fixture each | the four `fnName` forms |
| `"js: src ---- equals a hand-written constructor"` | `src_equals_a_hand_written_constructor.snap.md` | the output for `@src()` and for `SourceLocation(file: …, …)` written by hand is the same text apart from the literals |
| `"erlang: src ---- in a test"`, `"beam: …"`, `"wasm: …"` | `src_in_a_test.snap.md` per backend | the record-construction form of each backend |
| `"js: src ---- run log"`, `"erlang: src ---- run log"` | run-log fixtures (`h.assertJsRunLog`, `h.assertErlangRunLog`) | `@print(@src().line)` prints the literal line |
| `"js: src ---- with an argument is refused"`, `"js: unknown builtin ---- is refused"` | error fixtures | the two diagnostics, located |
| `"js: test body ---- try on an Error fails the test"`, `"erlang: …"` | run-log fixtures under test mode (`h.assertJsTestMode`) | the `FAIL <name> (<e>) at main.bp:N` line |
| `comptime/tests/infer_exprs.zig` | `snapshots/comptime/ast/src_types_as_sourcelocation.snap.md` | the typed AST carries `SourceLocation` for `val loc = @src();` |

In the compiler's own harness `file` is `main.bp` — the module is compiled with `.path = "main.bp"`
and no package, so `srcPath` defaults to `<path>.bp`. The package-relative form (`src/a.bp`) is
asserted once through the CLI, in `compiler-cli/tests/test_tooling.sh`, by a scratch package whose
test prints `@src().file`.

## Diagnostics

| Code | When | Text |
|---|---|---|
| `src-takes-no-arguments` | `@src(…)` with any argument, or `@src{ … }` | `` `@src()` takes no arguments `` |
| `unknown-builtin` | a `@name(…)` call no arm of `inferBuiltinCallReturnType` recognises | `` unknown builtin `@name` `` — with the nearest known name when the edit distance is 1 |

The second is not `@src`-specific: a typo such as `@pritn("x")` is refused instead of typing as
`void` (decision 67).

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| `ast.Loc` carries no file | `file` | read `env.srcPath` at the call site | a `file` on `Loc`, so a provenance-carrying `@Expr` capture keeps its origin file too |
| `@Decl` carries no source location (`language-gaps.md`, front 22's row) | not this front | — | `@Decl` carrying a `SourceLocation`; a separate front |

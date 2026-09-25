# `@src()` — the source-location builtin

Step 1 of the front, and the one compiler change track A admits this milestone. Every file:line
below is at meta HEAD `b5ceb203`, submodule `repository/botopink-lang`, paths under
`modules/compiler-core/src/` unless said otherwise. Measured 2026-09-20.

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
column}`) in ergonomics — the compiler's own snapshot tests are already written that way
(`codegen/tests/builtins.zig:17-22`: `test "js: assert ---- simple assertion" { try
h.assertJsSingle(std.testing.allocator, @src(), …` ) — and the std contract is the same test
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
every `FAIL` line unreproducible. Package-relative is also what the runner already prints — `TEST
<file>:<line>` (`compiler-cli/AGENTS.md` § *`botopink test` output format*).

**Why the package root and not `src/`.** `snapshots.path(loc)` is `<dir of loc.file>/__snapshots__/…`.
A test in `src/emilia.bp` and one in `test/emilia_test.bp` must not share a directory, and
`src/`-relative paths (what `env.modulePath` holds today — `compiler-cli/src/cli/scanner.zig:100-103`:
"path relative to src_dir, without extension") would collapse them. The package root is the directory
that holds `botopink.json`, and `botopink test` runs from it, so `path(loc)` resolves against the
process's working directory with no further lookup.

**Why no `module` field.** Zig has one. Here the package name lives in `botopink.json` and the
front end (`comptime.zig`, `Env`) never sees it; `file` is already unique inside a package, and the
`-test` helpers do not need the package name. Adding a field later is **not** additive — a record
constructor's arity changes and every hand-written `SourceLocation(…)` literal breaks — so the
four-field record is the decision.

## What `fnName` is

| Position of `@src()` | `fnName` |
|---|---|
| inside `test "css: modifiers ---- hover"` | `css: modifiers ---- hover` — the test name, verbatim, no `test.` prefix |
| inside an unnamed `test { … }` | `test_<idx>` — the same fallback the commonJS registry uses (`codegen/commonJS.zig:516`) |
| inside `fn tokensToCss(…)` | `tokensToCss` |
| inside a method `fn thenReturn(self: Self, …)` of `type Stub` | `Stub.thenReturn` |
| inside a lambda | the enclosing named fn/test/method — a lambda has no name |
| at module level (`val loc = @src();`) | `""` |
| inside a `comptime { … }` block or a decorator body | the enclosing fn, or `""` |

The raw test name rather than Zig's `test.<name>` because the one consumer of `fnName` —
`snapshots.path` — reads the suite and slug straight out of it, and the runner's `TEST` line already
prints the raw name. A test name may contain spaces and colons and a fn name may not, so the two
never collide in practice.

## Checker rule

`@src()` is an expression of type `SourceLocation`. It is legal anywhere a value is legal: a `val`
initializer, an argument, a `return`, a record field, module scope. It takes no arguments, no type
arguments, and no trailing lambda. It is not a type, not an annotation and not a statement.

| Form | Result |
|---|---|
| `@src()` | `SourceLocation` |
| `@src(1)`, `@src(x)`, `@src{ … }` | `error[src-takes-no-arguments]` at the call |
| `@src` without parentheses | parse error, as for every builtin call (`parser/exprs.zig:1110-1174`) |
| `@Src()` | `error[unknown-builtin]` — builtin names are exact |
| `val x: i32 = @src();` | ordinary type mismatch: `expected i32, got SourceLocation` |

## How it lowers — a record literal, on every backend

`@src()` is **rewritten during inference** into the ordinary constructor call
`SourceLocation(file: "src/a.bp", line: 12, column: 15, fnName: "x: y")`, with the four arguments
as literal expressions. From then on it is a record construction like any other, and each backend
lowers it through the path it already has:

| Backend | Record-constructor path | Output for the example |
|---|---|---|
| commonJS | `codegen/commonJS.zig:3830` (`class_names.contains(cc.callee)` → `new`) | `new SourceLocation("src/a.bp", 12, 15, "x: y")` |
| erlang | `codegen/erlang.zig:5384` (`record_fields.get(cc.callee)` → map) | `#{file => <<"src/a.bp">>, line => 12, column => 15, fnName => <<"x: y">>}` |
| beam | `codegen/beam_asm.zig:3756` → `lowerRecordConstruct` `:5001` | the same map, as `.S` instructions |
| wasm | `codegen/wat.zig:1903` (`callKind` → `.record_ctor`) → `lowerRecordCtor` `:5971` | a heap record with four fields |

The precedent for "rewrite at inference, lower as ordinary code" is `tryEvalMakeRecord`
(`comptime/infer.zig:8304`), which turns `@makeRecord(…)` into a typed record before codegen sees
it. `@src()` follows it. **No codegen file changes**, and every pre-existing codegen fixture stays
byte-identical, which is the front's cheapest gate.

The `SourceLocation` type itself must be *declared* somewhere every module sees it. It joins the
reflection prelude — `comptime.zig:576-594`, `decl_reflection_src`, the embedded botopink source that
already declares `Span(start: i32, end: i32, line: i32)`, `Annotation`, `Param`, `Field`, `Method`
and `Decl`. It is registered by `registerStdlib` (`comptime.zig:955`) into every `Env`, and the
backends learn its field list the way they learn `Span`'s (commonJS `:1210`, erlang `:3123`,
beam `:1784`, wat `:1000`). The documented surface goes in `libs/std/src/builtins.d.bp` beside
`@Decl` (`builtins.d.bp:425-477`), and `docs.md` § *Builtins* gains the example above.

## Compiler files to touch

| File | Change |
|---|---|
| `comptime.zig:576` `decl_reflection_src` | `+ pub type SourceLocation(file: string, line: i32, column: i32, fnName: string)` |
| `comptime/env.zig:379` | `modulePath` stays; `+ srcPath: []const u8 = ""` (package-relative display path) and `+ currentFnName: []const u8 = ""` |
| `comptime.zig:370`, `:465` | where `env.modulePath = mod.path;` is set, also set `env.srcPath = mod.srcPath` |
| `module.zig:5` `Module` | `+ srcPath: []const u8 = ""` — "" means `<path>.bp` (the tests and the LSP pass only `path`) |
| `compiler-cli/src/cli/scanner.zig:100-112`, `resolver.zig:152` | compute `srcPath` = `<src dir name>/<module path>.bp` for package modules and `test/<name>.bp` for flat test files; the absolute `.file` already there is the input |
| `comptime/infer.zig:3011` `inferFnDecl`, `:2189` `inferTestDecl`, the method walker | set/restore `env.currentFnName` (`name`, `t.name orelse "test_<idx>"`, `"<Type>.<method>"`) |
| `comptime/infer.zig:4246` `inferBuiltinCallReturnType` | `+` arm `"src"`: `cc.args.len != 0` → `src-takes-no-arguments`; else answer `env.namedType("SourceLocation")` and record a rewrite `loc → SourceLocation(file: env.srcPath, line: loc.line, column: loc.col, fnName: env.currentFnName)` the way `:8304` records `@makeRecord` |
| `comptime/infer.zig:4443` | the silent `return env.namedType("void")` becomes `error[unknown-builtin]` naming the builtin |
| `comptime/diagnostics.zig` | `+ src_takes_no_arguments = "src-takes-no-arguments"`, `+ unknown_builtin = "unknown-builtin"` |
| `comptime/error.zig:349` (next to `tryOnNonResult`) | the two message renderers |
| `libs/std/src/builtins.d.bp:425` | the documented `SourceLocation` record and a comment block for `@src()` |
| `docs.md` § Builtins, § Tests | the example; the `try`-in-a-test paragraph |
| `repository/vscode-extension/syntaxes/botopink.tmLanguage.json` | `src` in the builtin list — outside compiler-core, same commit train |
| `modules/compiler-core/AGENTS.md`, `comptime/AGENTS.md`, `comptime/tests/AGENTS.md`, `codegen/tests/AGENTS.md`, `compiler-cli/src/cli/AGENTS.md` | same commit |

**Nothing in `codegen/*.zig`.** If a backend needs a change to lower `@src()`, the rewrite is wrong,
not the backend.

## The test body as a fallible context

The contract writes `try assertCss(@src(), …);` directly inside a `test` block. Today:

- inference accepts it — `comptime/infer.zig:6965-6969` types a `.try_` jump through
  `tryUnwrapOrError` with no requirement on the enclosing declaration, and `inferTestDecl`
  (`:2189`) sets `throwContext = .unchecked` and an implicit `.future` effect so `await` already
  works in a test (`emilia.bp:475-480`);
- lowering is unverified — `codegen/commonJS.zig:615` classifies it as `TryForm.propagate`, whose
  emission inside a `@Result`-returning fn is `return { error: … }`; inside `async function __bp_test_N`
  (`commonJS.zig:1518`) that return would end the test **green** with a value the runner ignores.

The rule this front fixes: **inside a `test` body, a `try` whose operand is `Error(e)` ends the
test as `FAIL <name> (<e>) at <file>:<line>`.** On commonJS the propagate form emitted inside
`__bp_test_N` is `throw new Error(<e>)` — the runner's existing `catch` prints the FAIL line; on
erlang the test function (`codegen/erlang.zig:3661`) raises `erlang:error(<e>)`, which the escript
runner already catches. `<e>` is the error string; a non-string `E` is rendered with the backend's
`$stringify` form. The `at <file>:<line>` is the test's own line, as today; the assertion's line is
in the message when the helper put it there with `@src()`.

## Tests and snapshots to add in `modules/compiler-core`

Fixture names follow `codegen/tests/helpers.zig:80` (`slugFromSrc`): the text after the first
`": "` of the Zig test name, slugified with `_`.

| Zig test (in `codegen/tests/builtins.zig`) | Fixture(s) | Asserts |
|---|---|---|
| `"js: src ---- in a test"` | `snapshots/codegen/commonJS/src_in_a_test.snap.md` | `new SourceLocation("main.bp", L, C, "src: in a test")` with the literal numbers |
| `"js: src ---- in a fn"`, `"… in a method"`, `"… at module level"` | one fixture each | the four `fnName` forms |
| `"js: src ---- equals a hand-written constructor"` | `src_equals_a_hand_written_constructor.snap.md` | the JS for `@src()` and for `SourceLocation(file: …, …)` written by hand is the same text apart from the literals |
| `"erlang: src ---- in a test"`, `"beam: …"`, `"wasm: …"` | `snapshots/codegen/{erlang,beam,wasm}/src_in_a_test.snap.md` | the record-construction form of each backend |
| `"js: src ---- run log"`, `"erlang: src ---- run log"` | run-log fixtures (`h.assertJsRunLog` `:505`, `h.assertErlangRunLog` `:571`) | `@print(@src().line)` prints the literal line |
| `"js: src ---- with an argument is refused"`, `"js: unknown builtin ---- is refused"` | `snapshots/codegen/errors/commonJS/…` (`codegen/snapshot.zig:230`) | the two diagnostics, located |
| `"js: test body ---- try on an Error fails the test"`, `"erlang: …"` | run-log fixtures under test mode (`h.assertJsTestMode` `:408`) | the `FAIL <name> (<e>) at main.bp:N` line |
| `comptime/tests/infer_exprs.zig` | `snapshots/comptime/ast/src_types_as_source_location` | the typed AST carries `SourceLocation` for `val loc = @src();` |

In the compiler's own harness `file` is `main.bp` — `comptimeMod.compile` receives `.path =
"main.bp"` and no package, so `srcPath` defaults to `<path>` as the *Compiler files* table says. The
package-relative form (`src/a.bp`) is asserted once through the CLI, in
`compiler-cli/tests/test_tooling.sh`, by a scratch package whose test prints `@src().file`.

## Diagnostics

| Code | When | Text |
|---|---|---|
| `src-takes-no-arguments` | `@src(…)` with any argument, or `@src{ … }` | `` `@src()` takes no arguments `` |
| `unknown-builtin` | a `@name(…)` call no arm of `inferBuiltinCallReturnType` recognises | `` unknown builtin `@name` `` — with the nearest known name when the edit distance is 1, the way `removedBuiltinType` (`parser.zig:79`, `print.zig:84-87`) points at the replacement |

The second is not `@src`-specific and is the larger change: today a typo such as `@pritn("x")` types
as `void` and lowers to whatever the backend makes of an unknown builtin. Decision 67 settles it —
refuse. `zig build test-libs` after the change is the measurement of what it reds; the expectation,
from `grep -rn "@[a-z]" --include=*.bp` across the workspace, is nothing.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| `Env` does not know the enclosing declaration's name | `fnName` | add `currentFnName` (this front) | — closed by step 1 |
| `ast.Loc` carries no file (`ast.zig:87-90`) | `file` | read `env.srcPath` at the call site | a `file` on `Loc`, so a provenance-carrying `@Expr` capture keeps its origin file too (`infer.zig:3741` already reaches for `p.modulePath` for the same reason) |
| `@Decl` carries no source location (`language-gaps.md`, front 22's row) | not this front | — | once `SourceLocation` exists, `@Decl` can carry one; a separate front |

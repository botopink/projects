# `std/testing/asserts` — the canonical assertion API

`import {testing.asserts} from "std";` then qualified calls, `try` at the call site — only the leaf
`asserts` enters scope (decision 107). This document is the reference every `<lib>-test` submodule
builds on.

## The shape of every function

```bp
pub fn equals<T>(actual: T, expected: T) -> @Result<void, string> {
    if (actual != expected) {
        throw "asserts.equals: values differ";
    };
    return;
}
```

Five rules, each with its reason:

1. **`-> @Result<void, string>`.** Success is `Ok`, failure is `Error(message)`.
   The caller writes `try asserts.equals(a, b);` and a failure propagates to the enclosing
   `test` body, which ends as `FAIL <name> (<message>) at <file>:<line>` (`src-builtin.md` § *The
   test body as a fallible context*). A `-test` helper that is itself `-> @Result<void, string>`
   composes it with `try` and nothing else. Nothing in the module panics.
2. **`actual` first, `expected` second**, everywhere — `equals(actual, expected)`,
   `contains(actual, needle)`, `matches(actual, pattern)`, `lengthIs(actual, expected)`.
3. **One literal message per function**, `asserts.<fn>: <what>`. No string interpolation of the
   values: a generic `T` has no `toString`, and rendering it needs a host cell — which would put a
   `declare fn` on the pure path and break rule 5. The call site's `@src()` and the runner's
   `at <file>:<line>` say where; the message says which check.
4. **Pure botopink on the path that runs everywhere.** `==`, `!=`, `== false`, `.length`,
   `.contains()`, `.startsWith()`, `.endsWith()`, `.indexOf()`, `.isOk()`, `.isError()`, `!= null`
   — host-backed primitives only. A primitive `default fn` (`Bool.negate`, `Array.contains`) is not
   lowered when a std module is compiled as a consumer's embedded import, so none is used
   (`libs/std/AGENTS.md`).
5. **No `pub declare fn` in the file.** STD-001 (`comptime/tests/std_target_gating.zig`) rejects an
   `import {…} from "std"` on a target where a *`pub`* `declare fn` has no `@External` cell; private
   cells are not gated. The four functions that need a host — `matches`, `deepEquals`, `throws`,
   `throwsWith` — sit on the private cells `regexMatches`, `canonical` and `tryCatch`, and the
   module docblock names them as commonJS/erlang at run time.

## The surface

### Boolean

| Function | Signature | Fails when | Message |
|---|---|---|---|
| `isTrue` | `(condition: bool) -> @Result<void, string>` | `condition == false` | `asserts.isTrue: condition was false` |
| `isFalse` | `(condition: bool) -> @Result<void, string>` | `condition == true` | `asserts.isFalse: condition was true` |

### Equality

| Function | Signature | Fails when | Message |
|---|---|---|---|
| `equals` | `<T>(actual: T, expected: T)` | `actual != expected` | `asserts.equals: values differ` |
| `notEquals` | `<T>(actual: T, expected: T)` | `actual == expected` | `asserts.notEquals: values match` |
| `approxEquals` | `(actual: f64, expected: f64, tolerance: f64)` | `abs(actual - expected) > tolerance`, written `d > t || -d > t` (no `math` import) | `asserts.approxEquals: values differ by more than tolerance` |
| `deepEquals` | `<T>(actual: T, expected: T)` | `canonical(actual) != canonical(expected)` — private cell, see below | `asserts.deepEquals: values differ structurally` |

`==` is the language's rule: structural for primitives, reference for arrays and records on
commonJS (`===`) and structural on erlang (`=:=`). `equals` on two arrays therefore passes on erlang
and fails on commonJS — `libs/std/AGENTS.md` § *Conventions* already says "array equality in
assertions uses `.join(...)`". `deepEquals` is the cross-target answer: it renders both sides with
the private `canonical<T>(v: T) -> string` cell — `JSON.stringify($0)` on Node,
`iolist_to_binary(io_lib:format("~0tp", [$0]))` on Erlang — the same renderer `mocks.key` uses
as the key of the call log. Both sides render on the same target, so key order is the same on both.

### Nil

| Function | Signature | Fails when | Message |
|---|---|---|---|
| `isNil` | `<T>(value: ?T)` | `value != null` | `asserts.isNil: value was present` |
| `isNotNil` | `<T>(value: ?T)` | `value == null` | `asserts.isNotNil: value was null` |

`!= null`, never truthiness — on commonJS `if (x)` is false for `0` (`libs/std/AGENTS.md`).

### Result

| Function | Signature | Fails when | Message |
|---|---|---|---|
| `isOk` | `<T, E>(result: @Result<T, E>)` | `result.isError()` | `asserts.isOk: result was Error` |
| `isError` | `<T, E>(result: @Result<T, E>)` | `result.isOk()` | `asserts.isError: result was Ok` |

The payload is read by the caller with the builtin methods `builtins.d.bp` documents:
`try asserts.equals(r.unwrapOr(0), 42);`. The module does not rely on a `case` over `Ok(v)`/`Error(e)`
inside a `@Result`-returning body.

### String

| Function | Signature | Fails when | Message |
|---|---|---|---|
| `contains` | `(actual: string, needle: string)` | `actual.contains(needle) == false` | `asserts.contains: needle not in actual` |
| `notContains` | `(actual: string, needle: string)` | `actual.contains(needle)` | `asserts.notContains: needle found in actual` |
| `startsWith` | `(actual: string, prefix: string)` | `actual.startsWith(prefix) == false` | `asserts.startsWith: prefix does not match` |
| `endsWith` | `(actual: string, suffix: string)` | `actual.endsWith(suffix) == false` | `asserts.endsWith: suffix does not match` |
| `matches` | `(actual: string, pattern: string)` | the private `regexMatches` cell answers false | `asserts.matches: pattern did not match` |

`matches` sits on the private `regexMatches` cell, the template of `regex.matches` with the
arguments actual-first: PCRE-ish on both targets, `new RegExp(pattern).test(actual)` /
`re:run(actual, pattern) =/= nomatch`.

### Collection

| Function | Signature | Fails when | Message |
|---|---|---|---|
| `isEmpty` | `<T>(actual: T[])` | `actual.length != 0` | `asserts.isEmpty: array was not empty` |
| `isNotEmpty` | `<T>(actual: T[])` | `actual.length == 0` | `asserts.isNotEmpty: array was empty` |
| `lengthIs` | `<T>(actual: T[], expected: i32)` | `actual.length != expected` | `asserts.lengthIs: length differs` |
| `includes` | `<T>(actual: T[], element: T)` | `element` not found in `actual` | `asserts.includes: element not found` |
| `notIncludes` | `<T>(actual: T[], element: T)` | `element` found in `actual` | `asserts.notIncludes: element found` |

Membership is `==` per element, so `includes` on an array of records is reference equality on
commonJS — the same caveat as `equals`, and the same remedy (`deepEquals` on
the element you extracted with `.at(i)`).

### Numeric

| Function | Signature | Fails when | Message |
|---|---|---|---|
| `between` | `(actual: i32, low: i32, high: i32)` | `actual < low` or `actual > high` (inclusive both ends) | `asserts.between: value out of range` |
| `greaterThan` | `(actual: i32, bound: i32)` | `actual <= bound` | `asserts.greaterThan: value not greater` |
| `lessThan` | `(actual: i32, bound: i32)` | `actual >= bound` | `asserts.lessThan: value not less` |

`i32` only. A generic `T` cannot be compared with `<` under the current inference, and `f64` callers
have `approxEquals`. `positive`/`negative` are `greaterThan(x, 0)` / `lessThan(x, 0)` and are not
separate functions.

### Exceptions

| Function | Signature | Fails when | Message |
|---|---|---|---|
| `throws` | `(body: fn() -> i32)` | `body` completes normally | `asserts.throws: body did not raise` |
| `throwsWith` | `(body: fn() -> i32, needle: string)` | `body` completes, **or** the caught message does not contain `needle` | `asserts.throwsWith: body did not raise` · `asserts.throwsWith: message does not contain needle` |

Both sit on the private `tryCatch` cell (an IIFE `try/catch` answering `{ok: 0}`/`{error: msg}` on
Node; `try … catch __C:__E` on Erlang). The body is `fn() -> i32` because a closure whose only
statement is `@panic` does not unify with `unit`, so callers end the body with `0;`.

To assert that a **`@Result`-returning** body fails, `throws` is the wrong tool — that is
`isError(body())`. `throws` is for a `@panic` or a host throw from code that does not return a `@Result`.

### Utility

| Function | Signature | Answers | Message |
|---|---|---|---|
| `fail` | `(message: string) -> @Result<void, string>` | always `Error` | `asserts.fail: <message>` |
| `errorText` | `(r: @Result<void, string>) -> string` | never — its return is not a `@Result`; answers the `Error` payload, or `""` for `Ok` | — |

`fail` is the one function whose message carries caller text; it is the escape for a branch the
test asserts is unreachable. `errorText` is how a test reads a failure message to snapshot it
(`test-snap.md`): a plain `case r { Ok(v) -> ""; Error(e) -> e; }` — matching over the builtin
`Result` enum in a function that does not itself return a `@Result`, which is the one place the
checker's manual-construction rule does not apply.

## Failure message format

```
asserts.<fn>: <what>
```

Lowercase function name, a colon, a space, a short clause. The runner prints it inside the `FAIL`
line unchanged:

```
FAIL css: modifiers ---- hover on md breakpoint  (asserts.equals: values differ)  at src/emilia.bp:442
```

A helper that wants to say more prefixes before it propagates — `snapshots.assertAs` does
(`snapshots.md`), and a `<lib>-test` helper may — but never rewrites the `asserts.` part, so a
reader can grep the message to the function.

## Backend notes

| Backend | `asserts` compiles | Runs | Notes |
|---|---|---|---|
| commonJS | yes | yes | `botopink test` target |
| erlang | yes | yes | `botopink test` target |
| beam | yes | yes | the private cells' `@External.Erlang` templates are compiled at build time |
| wasm | yes | pure functions yes | wasm has no host: the module is emitted without `matches`/`deepEquals`/`throws`/`throwsWith`, and a call of one is refused where it is written, naming the cell it reaches |

"Compiles" means `import {testing.asserts} from "std"` passes STD-001 on that target, which it does because
the file has no `pub declare fn`, and building a program that imports it succeeds on all four. `beam` and `wasm` are not `botopink test` targets
(`compiler-cli/AGENTS.md` § *`botopink test` output format*), so no test executes there; the
guarantee that matters is that a library compiled for beam/wasm can still import the module.

## Migration table — old names → `testing.asserts` / `testing.mocks`

The names the old `asserts.bp` and the old `onze` exported, and what a caller writes today.

| Old | Today | Note |
|---|---|---|
| `truthy(condition)` · `falsy(condition)` | `isTrue` · `isFalse` | answers `Error` instead of panicking |
| `equal(a, b)` · `notEqual(a, b)` · `approxEqual(a, b, tolerance)` | `equals` · `notEquals` · `approxEquals` | same tests, actual first |
| `contains(haystack, needle)` | `contains(actual, needle)` | |
| `matches(pattern, actual)` | `matches(actual, pattern)` | argument order is actual-first |
| `throws(body, message)` | `throws(body)` · `throwsWith(body, needle)` | `throwsWith` checks the message |
| `type AssertError(message, file, line)` | removed | `@src()` supplies file/line and the `@Result` channel carries the message |
| `eq(v)` · `anyInt()` · `anyString()` | `mocks.eq` · `mocks.anyInt` · `mocks.anyString` | matchers, not assertions — they push onto the matcher stack `mocks` reads |
| `atLeastOnce()` · `times(n)` · `never()` | `mocks.atLeastOnce` · `mocks.times` · `mocks.never` | verification specs — `onze-migration.md` |
| `onzeKey<T>(v)` | `asserts`' private `canonical` and `mocks.key` (`pub declare fn`) | the same two templates in two files, because a std module cannot call another |

Not shipped:

| Name | Why |
|---|---|
| `positive`, `negative` | `greaterThan(x, 0)` / `lessThan(x, 0)` |
| `isOkAnd`, `throwsType`, `typeOf` | need a `case` over `@Result` inside a result body, a typed catch, and a type-name intrinsic respectively; none exists (`language-gaps.md`) |
| `setup`, `teardown`, `setupAll`, `teardownAll` | runner hooks are a toolchain gap (`README.md` § *Not in this front*) |

## The inline tests

At the foot of `asserts.bp`, one `test` per function per path, written with `try`. The pattern for
a fail path uses `isError` over the assertion's own result — no host cell, no panic:

```bp
test "asserts: equals fails on different values" {
    val r = equals(1, 2);
    try isError(r);
}
```

`test-snap.md` lists the ones that also record a snapshot (the message texts, pinned as evidence so
a message cannot drift without a `.new` file appearing).

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| A function cannot forward a `@Result` (`return r` re-wraps) | `snapshots.assertAs` calling `asserts`; every `-test` helper | `try inner(); return;` | a `return` that passes a `@Result` through |
| No structural equality | `deepEquals` | render both sides through a private host cell | a compiler-builtin structural `==` that reports the first differing path |
| No value rendering for a generic `T` | every message | literal messages | `Display` on every primitive and a derived one on records (decision 8 § 7, `libs/std/AGENTS.md`) |

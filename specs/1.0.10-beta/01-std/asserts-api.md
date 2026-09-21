# `std/asserts` — the canonical assertion API

`import {asserts} from "std";` then qualified calls, `try` at the call site. This document is the
reference every `<lib>-test` submodule builds on; `1.0.9-beta/tracks/README.md:26` named it as
`tracks/std/asserts.md` and it was never written.

## The shape of every function

```bp
#[@result]
pub fn equals<T>(actual: T, expected: T) -> @Result<void, string> {
    if (actual != expected) {
        throw "asserts.equals: values differ";
    };
    return;
}
```

Five rules, each with its reason:

1. **`#[@result]`, `-> @Result<void, string>`.** Success is `Ok`, failure is `Error(message)`.
   The caller writes `try asserts.equals(a, b);` and a failure propagates to the enclosing
   `test` body, which ends as `FAIL <name> (<message>) at <file>:<line>` (`src-builtin.md` § *The
   test body as a fallible context*). A `-test` helper that is itself `-> @Result<void, string>`
   composes it with `try` and nothing else. The old module's `@panic` could do none of that.
2. **`actual` first, `expected` second**, everywhere — `equals(actual, expected)`,
   `contains(actual, needle)`, `matches(actual, pattern)`, `lengthIs(actual, expected)`. The old
   `matches(pattern, actual)` was the one function with the other order; it flips.
3. **One literal message per function**, `asserts.<fn>: <what>`. No string interpolation of the
   values: a generic `T` has no `toString`, and rendering it needs a host cell — which would put a
   `declare fn` on the pure path and break rule 5. The call site's `@src()` and the runner's
   `at <file>:<line>` say where; the message says which check.
4. **Pure botopink on the path that runs everywhere.** `!=`, `==`, `.negate()`, `.length()`,
   `.contains()`, `.startsWith()`, `.endsWith()`, `.isOk()`, `.isError()`, `.at()`, `!= null` —
   the same primitives `content_hash.bp` and `path.bp` compose.
5. **No `pub declare fn` in the file.** STD-001 (`comptime/tests/std_target_gating.zig`,
   `infer.zig:85-93`) rejects an `import {…} from "std"` on a target where a *`pub`* `declare fn`
   has no `@External` cell; private cells are not gated. The four functions that need a host —
   `matches`, `deepEquals`, `throws`, `throwsWith` — keep their cells private, exactly as
   `asserts.bp:72` (`tryCatch`) and `:85` (`regexMatches`) do today, and the module docblock names
   them as commonJS/erlang at run time.

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
| `approxEquals` | `(actual: f64, expected: f64, tolerance: f64)` | `abs(actual - expected) > tolerance` (inline `if`, no `math` import) | `asserts.approxEquals: values differ by more than tolerance` |
| `deepEquals` | `<T>(actual: T, expected: T)` | `canonical(actual) != canonical(expected)` — private cell, see below | `asserts.deepEquals: values differ structurally` |

`==` is the language's rule: structural for primitives, reference for arrays and records on
commonJS (`===`) and structural on erlang (`=:=`). `equals` on two arrays therefore passes on erlang
and fails on commonJS — `libs/std/AGENTS.md` § *Conventions* already says "array equality in
assertions uses `.join(...)`". `deepEquals` is the cross-target answer: it renders both sides with
the private `canonical<T>(v: T) -> string` cell — `JSON.stringify($0)` on Node,
`iolist_to_binary(io_lib:format("~0tp", [$0]))` on Erlang — lifted verbatim from the old
`onze.bp:39-41` (`onzeKey`), where it was the key of the call log for exactly this reason. Both
sides render on the same target, so key order is the same on both.

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

The payload is read by the caller with the builtin methods `builtins.d.bp:33-40` documents:
`try asserts.equals(r.unwrapOr(0), 42);`. A `case` over `Ok(v)`/`Error(e)` inside a `#[@result]`
body is not exercised anywhere in the tree today, so the module does not depend on it.

### String

| Function | Signature | Fails when | Message |
|---|---|---|---|
| `contains` | `(actual: string, needle: string)` | `actual.contains(needle) == false` | `asserts.contains: needle not in actual` |
| `notContains` | `(actual: string, needle: string)` | `actual.contains(needle)` | `asserts.notContains: needle found in actual` |
| `startsWith` | `(actual: string, prefix: string)` | `actual.startsWith(prefix) == false` | `asserts.startsWith: prefix does not match` |
| `endsWith` | `(actual: string, suffix: string)` | `actual.endsWith(suffix) == false` | `asserts.endsWith: suffix does not match` |
| `matches` | `(actual: string, pattern: string)` | the private `regexMatches` cell answers false | `asserts.matches: pattern did not match` |

`matches` keeps the cell it has (`asserts.bp:85-88`, byte-identical to `regex.matches`): PCRE-ish on
both targets, `new RegExp($0).test($1)` / `re:run($1, $0) =/= nomatch`. Argument order flips to
actual-first; the template's `$0`/`$1` swap with it.

### Collection

| Function | Signature | Fails when | Message |
|---|---|---|---|
| `isEmpty` | `<T>(actual: T[])` | `actual.length() != 0` | `asserts.isEmpty: array was not empty` |
| `isNotEmpty` | `<T>(actual: T[])` | `actual.length() == 0` | `asserts.isNotEmpty: array was empty` |
| `lengthIs` | `<T>(actual: T[], expected: i32)` | `actual.length() != expected` | `asserts.lengthIs: length differs` |
| `includes` | `<T>(actual: T[], element: T)` | `actual.contains(element) == false` (`primitives.bp:435`) | `asserts.includes: element not found` |
| `notIncludes` | `<T>(actual: T[], element: T)` | `actual.contains(element)` | `asserts.notIncludes: element found` |

`Array.contains` is `==` per element (`primitives.bp:435`), so `includes` on an array of records is
reference equality on commonJS — the same caveat as `equals`, and the same remedy (`deepEquals` on
the element you extracted with `.at(i)`).

### Numeric

| Function | Signature | Fails when | Message |
|---|---|---|---|
| `between` | `(actual: i32, low: i32, high: i32)` | `actual < low` or `actual > high` (inclusive both ends) | `asserts.between: value out of range` |
| `greaterThan` | `(actual: i32, bound: i32)` | `actual <= bound` | `asserts.greaterThan: value not greater` |
| `lessThan` | `(actual: i32, bound: i32)` | `actual >= bound` | `asserts.lessThan: value not less` |

`i32` only. A generic `T` cannot be compared with `<` under the current inference, and `f64` callers
have `approxEquals`. 1.0.9 front 95's `positive`/`negative` are `greaterThan(x, 0)` /
`lessThan(x, 0)` and are not separate functions.

### Exceptions

| Function | Signature | Fails when | Message |
|---|---|---|---|
| `throws` | `(body: fn() -> i32)` | `body` completes normally | `asserts.throws: body did not raise` |
| `throwsWith` | `(body: fn() -> i32, needle: string)` | `body` completes, **or** the caught message does not contain `needle` | `asserts.throwsWith: body did not raise` · `asserts.throwsWith: message does not contain needle` |

Both sit on the private `tryCatch` cell `asserts.bp:72-78` has today (an IIFE `try/catch`
answering `{ok: 0}`/`{error: msg}` on Node; `try … catch __C:__E` on Erlang). The `i32` sentinel
stays for the reason the current file gives: a closure whose only statement is `@panic` does not
unify with `unit`, so callers end the body with `0;`. The old `throws(body, message)` accepted a
message and ignored it (`asserts.bp:73-76`); the new pair makes the check real and the name say so.

To assert that a **`@Result`-returning** body fails, `throws` is the wrong tool — that is
`isError(body())`. `throws` is for a `@panic` or a host throw from code that is not `#[@result]`.

### Utility

| Function | Signature | Answers | Message |
|---|---|---|---|
| `fail` | `(message: string) -> @Result<void, string>` | always `Error` | `asserts.fail: <message>` |
| `errorText` | `(r: @Result<void, string>) -> string` | never — not `#[@result]`; answers the `Error` payload, or `""` for `Ok` | — |

`fail` is the one function whose message carries caller text; it is the escape for a branch the
test asserts is unreachable. `errorText` is how a test reads a failure message to snapshot it
(`test-snap.md`): a plain `case r { Ok(v) -> ""; Error(e) -> e; }` — matching over the builtin
`Result` enum (`builtins.d.bp:23-26`) in a function that is not itself `#[@result]`, which is the
one place the checker's manual-construction rule (`infer.zig:8214`) does not apply.

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
| beam | yes | pure functions yes; `matches`/`deepEquals`/`throws`/`throwsWith` unresolved at lowering | private cells carry no `@External.Beam`; the docblock names the four |
| wasm | yes | as beam | `wat` renders no templates (`libs/std/AGENTS.md`) |

"Compiles" means `import {asserts} from "std"` passes STD-001 on that target, which it does because
the file has no `pub declare fn`. `beam` and `wasm` are not `botopink test` targets
(`compiler-cli/AGENTS.md` § *`botopink test` output format*), so no test executes there; the
guarantee that matters is that a library compiled for beam/wasm can still import the module.

## Migration table — old onze and old `asserts.bp` → `std/asserts`

Every symbol the two old surfaces exported, and where it is now. "Behaviour" is byte-for-byte unless
the row says otherwise.

| Old | Where | New | Behaviour |
|---|---|---|---|
| `truthy(condition)` | `asserts.bp:14` | `isTrue(condition)` | returns `Error` instead of panicking; message `asserts.isTrue: condition was false` (was `asserts.truthy: …`) |
| `falsy(condition)` | `asserts.bp:22` | `isFalse(condition)` | same change |
| `equal(a, b)` | `asserts.bp:30` | `equals(actual, expected)` | same change; same `!=` test |
| `notEqual(a, b)` | `asserts.bp:40` | `notEquals(actual, expected)` | same change |
| `approxEqual(a, b, tolerance)` | `asserts.bp:50` | `approxEquals(actual, expected, tolerance)` | same change; same inline `abs` |
| `contains(haystack, needle)` | `asserts.bp:60` | `contains(actual, needle)` | same change; same `.contains()` |
| `matches(pattern, actual)` | `asserts.bp:90` | `matches(actual, pattern)` | **argument order flips**; cell byte-identical |
| `throws(body, message)` | `asserts.bp:73` | `throws(body)` · `throwsWith(body, needle)` | `message` was ignored; `throwsWith` checks it |
| `type AssertError(message, file, line)` | `asserts.bp:57` | **removed** | constructed only by its own test; `@src()` now supplies file/line and the `@Result` channel carries the message |
| `tryCatch` (private) | `asserts.bp:72` | `tryCatch` (private) | unchanged |
| `regexMatches` (private) | `asserts.bp:85` | `regexMatches` (private) | unchanged |
| `eq(v)` | `onze.bp:66` | `mocks.eq(v)` | a **matcher**, not an assertion — 1.0.9 front 95 § 3 filed it under assertions; it pushes onto the matcher stack and belongs with the runtime that reads it |
| `anyInt()` / `anyString()` | `onze.bp:73-81` | `mocks.anyInt()` / `mocks.anyString()` | matchers — same reason |
| `atLeastOnce()` / `times(n)` / `never()` | `onze.bp:87-97` | `mocks.atLeastOnce()` … | verification specs — `onze-migration.md` |
| `onzeKey<T>(v)` | `onze.bp:39` | `asserts.canonical` (private) **and** `mocks.key` (`pub declare fn`) | the same two templates in two files, because a std module cannot call another |
| — | 1.0.9 front 95 plan | `deepEquals`, `startsWith`, `endsWith`, `isEmpty` (was `empty`), `isNotEmpty` (was `notEmpty`), `lengthIs` (was `hasLength`), `includes`, `between`, `isOk`, `isError` (was `isErr`), `fail` | new; names aligned to the `is`/`Is` convention this document fixes |
| — | 1.0.9 front 95 plan | `positive`, `negative` | **not shipped** — `greaterThan(x, 0)` / `lessThan(x, 0)` |
| — | 1.0.9 front 95 plan | `isOkAnd`, `throwsType`, `typeOf` | **not shipped** — need a `case` over `@Result` inside a result body, a typed catch, and a type-name intrinsic respectively; none exists (`language-gaps.md`) |
| — | 1.0.9 front 95 plan | `setup`, `teardown`, `setupAll`, `teardownAll` | **not shipped** — runner hooks are a toolchain gap (`unification.md`) |

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
| `-> @Result<void, string>` with an empty `return;` is unexercised in the tree | every function here | `@Result<i32, string>` and `return 0;` — what `asserts.bp:72` does today | verify or fix in step 1 (`src-builtin.md` § acceptance) — the contract is written for `void` |
| A function cannot forward a `@Result` (`return r` re-wraps) | `snapshots.assertAs` calling `asserts`; every `-test` helper | `try inner(); return;` | a `return` that passes a `@Result` through |
| No structural equality | `deepEquals` | render both sides through a private host cell | a compiler-builtin structural `==` that reports the first differing path |
| No value rendering for a generic `T` | every message | literal messages | `Display` on every primitive and a derived one on records (decision 8 § 7, `libs/std/AGENTS.md`) |

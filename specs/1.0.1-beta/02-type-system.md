# Spec 02 — Type System

**Version:** 1.0.1-beta
**Priority:** medium — does not block a green suite
**Depends on:** comptime eval on `erl` (done in 1.0.0-beta)

---

## Objective

Types as comptime values that are actually evaluated (not special-cased by name in
inference), type construction through `#[@code]`, std type functions written in `.bp`, and
complete narrowing.

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/`.

## What already exists

- **Inference builtins** (`comptime/infer.zig`): `@typeInfo(T)` → `TypeInfo`, `@TypeOf(v)`,
  `@makeRecord(fields)`, `@RecordKeys(T)`, `@field(v, name)`, `@comptimeError(msg)`. They
  resolve **types** during inference; they do not compute values.
- **Type functions by name** (`infer.zig` `tryResolveTypeManipulationCall`): `mergeRecords`,
  `mapFields`, `partial`, `omit`, `pick` are recognised by name and resolved in Zig.
  `libs/std/src/types.bp` declares `mapFields`/`partial`/`omit`/`pick` over `@makeRecord`,
  but the bodies never run (and `types.bp` is not wired into `root.bp` — see spec 05).
- **Tests:** `comptime/tests/builtins_typeinfo.zig` (31): typeInfo, TypeOf, makeRecord,
  RecordKeys, field, comptimeError, mergeRecords, partial, omit, pick.
- **Type guards:** the parser accepts `-> x is T` (`FnDecl.typeGuardParam`, `parser/decls.zig`).
- **Narrowing:** `comptime/tests/narrowing.zig` (19 tests: null-check, `case` on Result/enum,
  OR patterns, guards, `assert … is`, early return, type guard, `&&`, `?.`, `else if`) and
  `codegen/tests/narrowing.zig` (11 tests with RUN LOG).
- **Comptime eval:** decorators and templates run on the persistent `erl` through
  `erlang.emitComptimeModule`; `val x = comptime …` is folded in Zig (`comptime/eval.zig`).

---

## Part A — Types as values

| Step | What | Acceptance |
|---|---|---|
| 1 | `type` as a first-class comptime value: `val T = i32`, `comptime T: type`, `-> type` return | usable as annotation, value, parameter and return |
| 2 | `#[@code]` on fn: the returned `TypeInfo` becomes the type at the call site (`val p: Point() = Point()(x: 1, y: 2)`), including comptime parameters | annotation parses, type is lifted, constructor usable |
| 3 | `@typeInfo`/`@TypeOf` produce **values** (`TypeInfo.Record(fields: [...])`, `TypeInfo.Optional(inner: …)`) | correct values for primitives, record, enum, optional, array |
| 4 | Comptime eval loop for `.bp` fns with `comptime` params (`if`, `loop`, `break` with a type value), on top of the `erl` eval | `types.bp` fns executed, not resolved by name |
| 5 | Std in `.bp`: `mergeRecords`, `partial`, `omit`, `pick` with `#[@code]`; `recordKeys`, `field` as fns over `@typeInfo`. Remove `tryResolveTypeManipulationCall` and the `@makeRecord`/`@RecordKeys`/`@field` builtins | `builtins_typeinfo.zig` passes without the special cases |

Step 4 note: `comptime val` is folded in Zig and cannot evaluate calls; type-level eval with
control flow has to go through the `erl` path (as decorators/templates do) or extend
`comptime/eval.zig` — decide in step 4.

## Part B — Narrowing

| Step | What | Acceptance |
|---|---|---|
| 6 | Audit the 13 narrowing patterns against the existing tests and close gaps (e.g. narrowing in the `else` of a null-check, type guard across an `else if` chain) | each pattern has a positive test; narrowing errors have a snapshot |
| 7 | Narrowing codegen coverage on the 4 backends | ≥1 test with RUN LOG per runtime-relevant pattern |

Part B is independent of Part A. Steps 2–5 and Part B all touch `comptime/infer.zig` — do
not parallelise them across branches.

---

## Open questions

- `@code("…")` already exists as a template builtin (text → code). Confirm the `#[@code]`
  annotation name does not clash, or pick another name.

# Types as values — what exists versus what the steps assume

The goal: `type` as a first-class comptime value, type construction through `#[@code]`, and std
type functions written in `.bp` that are **actually executed** — replacing the name-keyed type
functions and the type-resolving builtins that inference special-cases today.

The steps below were written against an imagined starting point. At HEAD several of their
assumptions do not hold: the two `.bp` modules they build on do not compile, `mapFields` is
implemented nowhere, and the other four type functions already work — as Zig builtins resolved by
name. This file puts each assumption next to what exists, then the steps.

Rows referenced here (C4b, C6, C10) are in [`rows.md`](./rows.md); the grammar gaps in
[`parser-gaps.md`](./parser-gaps.md); ordering in [`groups.md`](./groups.md).

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/` unless stated
otherwise. Line numbers are at `botopink-lang` HEAD; re-locate by the quoted symbol.

## Existing machinery

- **Inference builtins** (`infer.zig` `inferBuiltinCallReturnType`, l.3797, called at l.6889):
  `@typeInfo(T)` → the `TypeInfo` type (l.3838), `@TypeOf(v)` → the argument's type (l.3843),
  `@makeRecord(fields)` → fresh var (l.3849; a literal `RecordField` array is resolved earlier by
  `tryEvalMakeRecord`, l.3966 / call site l.6885), `@RecordKeys(T)` → `Array<string>` (l.3854),
  `@field(v, name)` → the type of `v` (l.3859), `@comptimeError(msg)` → custom error. They resolve
  **types** during inference; they compute no values.
- **The value domain** (`TypeInfo`, `RecordField`, `EnumVariant`, `TypeInfoKind`) is declared in
  `comptime.zig` `type_info_src`. `TypeInfo` is an **enum with payload variants**
  (`Record(fields: RecordField[])`, `Optional(inner: string)`, …) — not a record. This one fact is
  why both `.bp` modules below fail.
- **Type functions by name** (`infer.zig` `tryResolveTypeManipulationCall`, l.4041, called at
  l.6901 for every non-builtin call *before* user bindings **and before the receiver check**):
  `mergeRecords`, `partial`, `omit`, `pick` are resolved in Zig and **work today**; `mapFields` is
  matched and returns `null` (l.4071-4072, not implemented).
- **`.bp` type functions**: `libs/std/src/types.bp` (`mapFields`/`partial`/`omit`/`pick`) and
  `libs/std/src/reflect.bp` (`mergeRecords`) are absent from `libs/std/src/root.bp`, so they are
  never loaded — `botopink check` in `libs/std` prints `module not reached by any mod path` for
  both (and for `primitives.bp`).
- **Types as values**: any value binding is accepted as an annotation through the `env.zig`
  `resolveTypeName` bindings fallback (l.916-928: `val T = i32; val x: T = "s"` reds, but
  `val n = 5; val x: n = 7` also checks); an unknown name becomes an opaque named type (l.930-931).
  `comptime T: type` parameters do not constrain other parameters. A call in annotation position
  (`val z: mk() = …`) does not parse.
- **`@code(text)`** already exists as a builtin valid only inside template fns (`infer.zig`
  l.3808-3828, lowered through `template_eval.zig`).

## Current state versus what the steps assume

| Thing | What the steps assume | What exists at HEAD |
|---|---|---|
| `libs/std/src/types.bp` | a `.bp` implementation of `mapFields`/`partial`/`omit`/`pick` to be executed | **does not compile.** `botopink check` on it → `unknown field 'Record' on type 'TypeInfo' at main:23:16`. `TypeInfo` is an enum (`comptime.zig` `type_info_src`), so `info.Record.fields` is not field access — it must be `case info { Record(fields) -> … }`. It is also in no `mod` tree (`root.bp` does not declare it) |
| `libs/std/src/reflect.bp` | a `.bp` implementation of `mergeRecords` | **does not parse.** Three stacked defects, confirmed by peeling them one at a time: (1) l.26 uses the keyword `and`, which is not an operator — botopink has only `&&`; (2) with `&&` it still fails, because the `if` condition parses at `prec.equality` ([`parser-gaps.md`](./parser-gaps.md#if-a--b--if-a--b)) — `if ((… && …))` is needed; (3) with both fixed it reaches `unknown field 'Record' on type 'TypeInfo' at main:24:17`, the same enum defect as `types.bp`. Also in no `mod` tree |
| `mapFields` | resolved by name today, to be replaced by the `.bp` body | `tryResolveTypeManipulationCall` matches the name and returns `null` (l.4049-4053 accepts it, l.4071-4072 returns null), so the call falls through to the ordinary call path and is typed as an ordinary user call — i.e. it is *not* implemented in either place |
| `mergeRecords`, `partial`, `omit`, `pick` | to be written in `.bp` | **already work** as Zig resolution in `tryResolveTypeManipulationCall`, pinned by `comptime/tests/builtins_typeinfo.zig` — and the same name-keyed resolution is what reds `libs/std` today (C6: `random.bp`'s own `pick` is claimed, `error: pick expects a type and field names at random:141:13`) |
| `@typeInfo` / `@TypeOf` produce values | A3 | `eval.zig` `valueOf` l.149 folds `@typeInfo` to the opaque `.object` and l.150 folds `@TypeOf` to a type *name* string. At the type level `@TypeOf(1)` is `i32`, not a `type` value (probe: `val n: string = @TypeOf(1);` → `expected string, got i32`) |
| A comptime eval loop | A4 | `eval.zig` handles `if` (l.198-204), `loop` (l.205), `case` with a wildcard/binder arm only (l.182-190), `break` (l.194) and scope lookup (l.156-163) — but **no function application** (a non-builtin call returns `.null_` at l.152). `error.zig` `validateComptimeExpr` rejects a call (l.449), a `case` (l.458) and a `loop` (the `else` at l.485) *before* the folder ever sees them, and `validateComptime` only visits top-level `val` decls (l.383-388) |
| `type` as a value | A1 | `env.zig` l.916-928 accepts any binding in annotation position. There is no `type` kind in `comptime/types.zig` |
| A call in TypeRef position | A2 | does not parse (`val z: mk() = 1;` → parse error) |

### What pins the current behaviour

`comptime/tests/builtins_typeinfo.zig` (31 tests) is the only fixture family that pins these: 27
`assertComptimeAstSingle` (typed-AST snapshots under `snapshots/comptime/{node,erlang}/`) and 4
`assertTypeErrorSnap` (`comptimeError: string literal raises custom error`,
`mergeRecords: conflict raises error`, `omit: non-existent field raises error`,
`pick: field email not found raises type error`). The file's header says it verifies resolution
"during inference" and defers full comptime evaluation — that is exactly the layer this work
replaces. 3 of its slugs already render a `typeNameOf` `?` (`single_field_returns_record_type`,
`multiple_fields_returns_record_type`, +1), i.e. `@makeRecord` produces an unresolved var rather
than a record type. 30 fixtures across the suite use any of these builtins or names.

The builtin probes at HEAD (C6): `val xv: string = @field(p, "x")` → `expected string, got P`;
`val k: string[] = @RecordKeys(P)` → `expected array, got Array`.

## Steps

| Step | What | Acceptance |
|---|---|---|
| A0 | Make the two std modules compilable and loaded, since every later step builds on them: rewrite `info.Record.fields` as a `case` on the `TypeInfo` enum in both files, replace `and` with `&&` in `reflect.bp` and either parenthesise the condition (`if ((… && …))`) or land the `if`-condition grammar fix, and declare both in `libs/std/src/root.bp`. This is the `libs/std` half of the std front's work; C6 is the compiler half | `botopink check` in `libs/std` is clean with `types.bp` and `reflect.bp` in the `mod` tree and no "module not reached" warning for either |
| A1 | `type` as a first-class comptime value: `val T = i32`, `comptime T: type`, `-> type` return. Replace the bindings-as-types fallback (C10) with a real `type` kind; a `comptime T: type` argument binds `T` for the remaining parameters and the return | usable as annotation, value, parameter and return; `id(i32, "s")` reds; `val n = 5; val x: n = 7` reds |
| A2 | `#[@code]` on a fn: the returned `TypeInfo` becomes the type at the call site (`val p: Point() = Point()(x: 1, y: 2)`), comptime parameters included. Needs a call in TypeRef position, which does not parse today | the annotation parses, the type is lifted, the constructor is usable |
| A3 | `@typeInfo`/`@TypeOf` produce **values** (`TypeInfo.Record(fields: [...])`, `TypeInfo.Optional(inner: …)`) of the existing `TypeInfo` enum, and `validateComptimeExpr` accepts them | correct values for primitives, record, enum, optional, array |
| A4 | A comptime eval loop for `.bp` fns with `comptime` params (`if`, `loop`, `break` with a type value, `case` on `TypeInfo`) | `types.bp`/`reflect.bp` fns are executed, not resolved by name |
| A5 | Std in `.bp`: `mergeRecords`, `mapFields`, `partial`, `omit`, `pick` with `#[@code]`; `recordKeys`, `field` as fns over `@typeInfo`. Remove `tryResolveTypeManipulationCall` and the `@makeRecord`/`@RecordKeys`/`@field` builtins | `comptime/tests/builtins_typeinfo.zig` (31 tests) passes without the special cases; a user fn **or method** named like a std type function is not shadowed |

### A0 — ownership, and what the source got wrong

A0 edits only `libs/std/**`, which [`03-std-surface`](../03-std-surface/README.md) owns; it is that
front's step, listed here because every later step builds on it. Its acceptance ("`botopink check`
in `libs/std` is clean") **cannot be met until C6 lands** in this front — `libs/std` is red on the
`pick` shadowing regardless of `types.bp` and `reflect.bp`.

The source phrases the `reflect.bp` fix as "replace `and` with `&&` … (or land the `if`-condition
grammar fix and keep the operator)". That contradicts its own current-state row: `and` is not an
operator at all, so no grammar fix lets `reflect.bp` keep it. Defects (1) and (2) are stacked, not
alternatives — `and` → `&&` is required, and then *either* the double parentheses *or* the grammar
fix. The step above is written that way.

### A1 — overlap with C10

A1 replaces the bindings arm of `resolveTypeName` (`env.zig` l.916-928) with a real `type` kind.
C10 (landing group G1) adds the two-pass typedef registration and turns the opaque-named-type
fallback (l.930-931) into `unknownTypeName`. **Do C10's two-pass registration there and let A1
delete the bindings arm** — otherwise the same code is rewritten twice. A1 therefore lands after
G1.

### A2 — a grammar change

A call in TypeRef position is a parser change (the TypeRef grammar), not a checker one; it is
recorded in [`parser-gaps.md`](./parser-gaps.md#grammar-edits-this-front-makes-outside-the-five-gaps).

**Open question, due before A2:** `@code(text)` already exists as a builtin valid only inside
template fns (`infer.zig` l.3808-3828, lowered through `template_eval.zig`); `#[@code]` would be
the first `#[@…]` annotation that is neither an effect (`ast.zig` `EffectKind`) nor `@external`.
The positions do not clash syntactically, but confirm the shared name is intended or pick another.

### A4 — two ways to evaluate, decide in the step

`validateComptimeExpr` rejects a call, a `loop` and a `case` before `eval.zig` sees them, and
`eval.zig` has no function application. Type-level eval with control flow therefore has to go
through the `erl` path (as decorators and templates do) or extend `eval.zig` + `error.zig` —
decide in A4. `eval.zig` already implements `if`/`loop`/`break`/scope, so the cheaper half of
"extend" is mostly the validator.

Two things from C4b bear on the "extend" option: `eval.zig` deliberately returns `.null_` for
anything it cannot reduce (l.213-215), which a type-level evaluator must turn into an error rather
than a silent `null`; and `validateComptime` only visits top-level `val` declarations
(`validateDecl` l.383-388), so a `comptime` expression inside a fn body — where a `.bp` type
function's body lives — is never validated today.

If the `erl` path is chosen, the evaluator lives in `comptime/template_eval.zig` /
`comptime/decorator_eval.zig`, which [`01-comptime-dispatch`](../01-comptime-dispatch/README.md)
owns: A4 then cannot start until that front lands, and needs its owner's agreement.

### A5 — supersedes C6's builtin rows, not its shadowing fix

A5 deletes `@makeRecord`/`@RecordKeys`/`@field` and `tryResolveTypeManipulationCall`, so C6's
builtin-specific acceptance (`@field` returns the field type, `@RecordKeys` unifies with
`string[]`, `@makeRecord` accepts a comptime binding) drops if A5 lands first. C6's **shadowing
fix does not drop and must land first**: `libs/std` is red on it today, and A5 cannot even be
measured against a std that does not compile.

The `.bp` half of A5 (`mergeRecords`, `mapFields`, `partial`, `omit`, `pick`, `recordKeys`,
`field` in `libs/std/src/`) is again `libs/std/**`, owned by
[`03-std-surface`](../03-std-surface/README.md); the compiler half (the deletions) is here. They
must land together or `builtins_typeinfo.zig` has nothing to resolve against — sequence the two
fronts, since `03-std-surface` re-records every backend and runs alone (`fronts.md` note 1).

## Order and parallelism

```
C6 shadowing fix (G0) ──► A0 (03-std-surface) ──► A3 ──► A4 ──► A5 (with 03-std-surface's .bp half)
C10 two-pass (G1) ─────► A1 ──► A2 (needs the TypeRef-call grammar + the #[@code] name decision)
```

A2–A5 all touch `comptime/infer.zig`, as do Part 0 and [`narrowing.md`](./narrowing.md) B6 — do
not parallelise them across branches. A3 and A4 also touch `comptime/eval.zig` and
`comptime/error.zig`, which C4b edits; C4b is small and lands in G0, so it goes first.

**Acceptance for the whole of this file** (the README's step 7):
- [ ] `val T = i32`, `comptime T: type` and `-> type` are usable as annotation, value, parameter and
      return; `id(i32, "s")` reds; `val n = 5; val x: n = 7` reds
- [ ] `types.bp`/`reflect.bp` fns are **executed**, not resolved by name
- [ ] `comptime/tests/builtins_typeinfo.zig` (31 tests) passes without the special cases, and
      `tryResolveTypeManipulationCall` plus the `@makeRecord`/`@RecordKeys`/`@field` builtins are
      deleted

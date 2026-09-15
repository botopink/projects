# Spec 02 — Type System

**Version:** 1.0.1-beta
**Priority:** medium — does not block a green suite
**Depends on:** comptime eval on `erl` (done in 1.0.0-beta); spec 06 step 0 H3/H9 (a snapshot
test must fail when its program does not compile) before any test rewrite here can be trusted

---

## Objective

A checker that actually rejects wrong programs (return, `case`, patterns, methods, record
update), types as comptime values that are actually evaluated (not special-cased by name in
inference), type construction through `#[@code]`, std type functions written in `.bp`, and
narrowing that parses, type-checks and runs.

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/`. Line numbers are
at the time of writing; re-locate by the quoted symbol.

## What already exists

- **Inference builtins** (`comptime/infer.zig` `inferBuiltinCallReturnType`, l.3829-3960):
  `@typeInfo(T)` → the `TypeInfo` type, `@TypeOf(v)` → the argument's type, `@makeRecord(fields)`
  → fresh var (a literal `RecordField` array is resolved earlier by `tryEvalMakeRecord`,
  l.6882/3964), `@RecordKeys(T)` → `Array<string>`, `@field(v, name)` → the type of `v`,
  `@comptimeError(msg)` → custom error. They resolve **types** during inference; they compute no
  values. The value domain (`TypeInfo`, `RecordField`, `EnumVariant`, `TypeInfoKind`) is
  declared in `comptime.zig` `type_info_src` and registered into the global env.
- **Type functions by name** (`infer.zig` `tryResolveTypeManipulationCall`, l.4039, called for
  every non-builtin call at l.6899 before user bindings are consulted): `mergeRecords`,
  `partial`, `omit`, `pick` are resolved in Zig; `mapFields` is matched but returns `null`
  (not implemented).
- **`.bp` type functions** (not in `libs/std/src/root.bp`, so never loaded — see spec 05 item
  5.1): `libs/std/src/types.bp` has `mapFields`/`partial`/`omit`/`pick`,
  `libs/std/src/reflect.bp` has `mergeRecords`. Neither compiles today: `types.bp` fails with
  `unknown field 'Record' on type 'TypeInfo'` (`info.Record.fields` on an enum), `reflect.bp`
  does not parse (a boolean operator inside an `if` condition, see Part B `&&`).
- **Tests:** `comptime/tests/builtins_typeinfo.zig` (31): typeInfo, TypeOf, makeRecord,
  RecordKeys, field, the 4 introspection types, comptimeError, mergeRecords, partial, omit,
  pick. Snapshots `record_value_returns_record_type` and `record_value_field_access` are
  source-only (anonymous `record { … }` value does not parse); `single/multiple_fields_returns_record_type`
  record `?`; `*_returns_string_array` record `Array<string>`.
- **Types as values today:** any value binding is accepted as an annotation through the
  `env.zig` `resolveTypeName` bindings fallback (l.916-928: `val T = i32; val x: T = "s"` reds,
  but `val n = 5; val x: n = 7` also checks); unknown names become opaque named types
  (l.930-931). `comptime T: type` parameters do not constrain other parameters
  (`fn id(comptime T: type, v: T) -> T` accepts `id(i32, "s")`). A call in annotation position
  (`val z: mk() = …`) does not parse.
- **Type guards:** `-> x is T` parses (`parser/decls.zig` l.369-376 → `FnDecl.typeGuardParam`,
  `ast.zig` l.1751) and registers `env.typeGuardFns` (`infer.zig` l.530, l.2851), used for
  then-branch narrowing in `if` (`infer.zig` l.5806-5830).
- **Narrowing:** `comptime/tests/narrowing.zig` (19 tests, 11 pattern sections: if null-check,
  `case` on `@Result`, `case` on enum variants, OR patterns, guards, `assert … is`, early
  return, type guard, `&&`, `?.`, `else if`; plus 1 error test). 16 of its 18 success snapshots
  are source-only (top-level `@print`, unparseable syntax — see Part B). `codegen/tests/narrowing.zig`
  (11 tests × 4 backends): 5 tests write 0-byte snapshots on every backend (`early_return`,
  `assert_pattern`, `type_guard_if`, `case_option_some_none`, `and_condition`); of the 6 with a
  RUN LOG only 4 print the expected value, each on some backends: `if_null_check` (js, erlang),
  `optional_chaining` and `type_guard_basic` (js, erlang, beam), `case_enum_area` (beam).
- **Comptime eval:** decorators and templates run on the persistent `erl` through
  `erlang.emitComptimeModule` (snapshots show `COMPTIME ERLANG` / `COMPTIME REPLY`);
  `val x = comptime …` is folded in Zig (`comptime/eval.zig`, listing
  `ct_N: <declaration> → literal` under `COMPTIME VALUES`). Its input is gated by
  `comptime/error.zig` `validateComptimeExpr` (l.384), which rejects calls, identifiers,
  `if`/`loop` and `&&`/`||`, so the folder's `@typeInfo`/`@TypeOf`/branch arms are unreachable
  from a `comptime` val.
- **Snapshot limits** (affect every acceptance below): the typed JSON renders any non-`.named`
  TypeRef as `?` (`comptime/snapshot.zig` `typeNameFromTypeRef`, l.236-241) and never shows fn
  locals, so checker fixes are asserted with annotated top-level `val`s and error snapshots.

---

## Part 0 — Checker correctness

Each row was confirmed by reading the code and by `botopink check` on a scratch project. These
hide failures in many "happy path" tests (see `06-snapshot-review/comptime-*.md`); fixing them
will red tests and possibly `libs/` code — regenerate and review, and keep `zig build test-libs`
green.

| Step | What (evidence) | Acceptance |
|---|---|---|
| C1 | `return` never unified with the declared return type: `inferFnDecl` discards body results ("we ignore the result for now", `infer.zig` l.2868-2871); the `.@"return"` jump is typed `void` with no unify (l.5561). Same gap for the `@Generator` R channel and untyped lambdas | `fn f() -> i32 { return "s"; }` reds at the value; `#[@generator]` `return 42` against `R = string` reds |
| C2 | `case` expression typed as a fresh var, arms never unified (`infer.zig` l.7468); `comptime { break e; }` typed from its last statement, i.e. `void` (l.7524) | `val a: bool = case 42 { 0 -> "a"; _ -> "b"; };` reds; decide union vs error for mismatched arms and pin it in `case_arms_*union*`; `val h = comptime { break 1; }; val z: i32 = h;` checks |
| C3 | Operand orientation and constraints: `&&`/`\|\|` (l.5371-5372) and `!` (l.5410) call `unifyAt(operand, bool)` although `unifyAt` is target-first, so expected/found are swapped; `+`/`-`/`*` use `unify` without a location (l.5383, l.5391) and accept strings (`"a" * "b"`, `-"s"` check); `yield` is swapped too (`yield "s"` in `@Iterator<i32>` says `expected string, got i32`) | `1 && true` → `expected: bool, found: i32` with a caret; `"a" * "b"` and `-"s"` red with a location |
| C4 | `comptime val` folding: every binary op folds through `evalConstInt` (`comptime/eval.zig` l.85-96), so floats/strings become `0` and comparisons become integer `0`, which makes every `if` in a folded block take `else` (l.169-173); unsupported shapes fold to `null` silently | `ct_0: val pi = comptime 3.14 * 2.0 → 6.28`, `"Hello, " + "World" → "Hello, World"`, `1 < 2 → true` (`expressions_of_multiple_types` regenerated); an unfoldable expression is a comptime error, never `0`/`null` |
| C5 | Type-guard fns typed as the narrowed type, not `bool`: the return TypeRef of `-> x is T` is `T` (`parser/decls.zig` l.375) and is used as the call type (`buildFnSignatureType` `infer.zig` l.709-712, `inferFnDecl` l.2731-2734); a guard call in `if` then fails `unifyAt(bool, …)` (l.5831), so the narrowing at l.5806-5830 is unreachable | `val b: bool = isPositive(5);` checks; `if (isStr(y)) { val s: string = y; }` checks with `y: ?string`; the body must return `bool` |
| C6 | Type builtins: `@field` returns the record type (l.3856-3859: `val xv: i32 = @field(p, "x")` → `got P`); `@RecordKeys` builds nominal `Array` (l.3851-3853) that does not unify with `string[]` (`array`); `@makeRecord(ident)` is a fresh var because `tryEvalMakeRecord` only reads literal arrays; `pick` errors point at the call, not the missing name; `tryResolveTypeManipulationCall` runs before user bindings, so a user `fn pick(…)` is shadowed (`pick: first argument must be a type name`) | a user fn named `pick`/`omit`/`partial`/`mergeRecords` resolves to the user fn; `@field` returns the field type; `val k: string[] = @RecordKeys(P)` checks; `@makeRecord(fields)` with a comptime `val fields` builds the record. The builtin-specific rows are dropped if step 5 lands first; the shadowing fix is needed either way |
| C7 | Generic arguments lost: enum unit variants are typed `namedType(Enum)` with no args (`infer.zig` l.5224; contrast `env.zig` `resolveTypeName` l.904-913, which adds fresh args), so `val n: Option<i32> = Option.None;` → `expected Option, got Option`; chained defaults are not enforced (`record Sym<T, U = T>` accepts `Sym<i32>` with `right: "two"`) | both examples behave (the first checks, the second reds); `generic_enum_option_t_unit_and_payload_variants` shows `Option<i32>` for `n` |
| C8 | Pattern bindings untyped: `bindPatternNamesForSubject` (`infer.zig` l.4849-4890) binds every variant payload, OR alternative, guard identifier and list element to `freshVar()` | `A(v) -> f(v)` with `A(v: i32)` and `f(s: string)` reds; same for `Dog(b) \| Cat(b)`, `x if (x > 0) -> f(x)`, `Ok(v)`/`Err(e)` on `@Result`, `[first, ..rest]` |
| C9 | Methods: record/enum method bodies are best-effort and skipped on errors (`inferTypeMethods` doc, l.2911; `return self.nope;` checks); methods without a return annotation get no stored signature and fall back to a fresh var (l.1002-1006); unknown methods take the permissive path (l.6490: `donald.swim()` checks with no `swim`) | a type error in a record method body reds; `val a: string = d.quack()` reds when `quack` returns `self.id`; calling an undefined method reds (`methodNotActive` / unknown method) |
| C10 | Unknown type names accepted: `resolveTypeName` falls back to an opaque named type (`env.zig` l.930-931; `record Q { lat: bogusType }` checks) and accepts any value binding as a type (l.916-928) | unknown type name reds at the TypeRef; a non-type binding in annotation position reds; forward references to records/enums declared later still check |
| C11 | Record update spread is positional: with one spread and fewer than two other args it unifies against field 0, otherwise labels are ignored (`infer.zig` l.7201-7230; `Person(..alice, age: 25)` → arity error, `nickname: 25` checks) | label-based update: `..alice, age: 25` checks; unknown label → `unknown field` at the label; wrong value type → caret at the value; spreading another variant reds with a variant message (`variant_mismatch`, `non_existent_field`, `field_type_mismatch` regenerated) |
| C12 | Expression gaps: `val assert P = e catch h` swallows inference errors of `e` and `h` and never checks `P` against `e` (l.7543-7555); a pipeline into a bare fn identifier is typed as the function (`1 \|> double` : `function`, l.7291-7297) and a pipeline call with the wrong arity is not reported (l.7258) | `val assert 42 = answer catch 0;` with `answer` unbound reds; `val r: i32 = 1 \|> double;` checks; `1 \|> add(1, 2)` for a 2-ary `add` reds |
| C13 | Diagnostics: `effect-missing-wrapper` (R4) is unreachable for primitive returns because every primitive is `.named` (l.2796-2799); effect errors are located at the first body statement (l.2789) or nowhere for `declare fn` (l.2073); many `TypeError`s carry no location (`missingMethod`/`unknownMethod`/`ambiguousMethod` l.330-385, extend/activation l.761-783, pub-default l.190-196, RG3, arithmetic `unify`) | `#[@result] fn f() -> i32` reports `effect-missing-wrapper` at the return type; every error snapshot listed in `comptime-errors-effects.md` root cause 5 has a `┌─` location |

Order: C1 and C8 first (they unmask most vacuous tests), then C2, C5, C3, the rest in any order.
C4 is `comptime/eval.zig` + `comptime/error.zig` only and can run beside the others.

## Part A — Types as values

| Step | What | Acceptance |
|---|---|---|
| 1 | `type` as a first-class comptime value: `val T = i32`, `comptime T: type`, `-> type` return. Replace the bindings-as-types fallback (C10) with a real `type` kind; a `comptime T: type` argument binds `T` for the remaining parameters and the return | usable as annotation, value, parameter and return; `id(i32, "s")` reds; `val n = 5; val x: n = 7` reds |
| 2 | `#[@code]` on fn: the returned `TypeInfo` becomes the type at the call site (`val p: Point() = Point()(x: 1, y: 2)`), including comptime parameters. Needs a call in TypeRef position (does not parse today) | annotation parses, type is lifted, constructor usable |
| 3 | `@typeInfo`/`@TypeOf` produce **values** (`TypeInfo.Record(fields: [...])`, `TypeInfo.Optional(inner: …)`) of the existing `TypeInfo` enum; `validateComptimeExpr` accepts them | correct values for primitives, record, enum, optional, array |
| 4 | Comptime eval loop for `.bp` fns with `comptime` params (`if`, `loop`, `break` with a type value, `case` on `TypeInfo`), on top of the `erl` eval | `types.bp`/`reflect.bp` fns executed, not resolved by name |
| 5 | Std in `.bp`: `mergeRecords`, `mapFields`, `partial`, `omit`, `pick` with `#[@code]` (rewrite the bodies to match on `TypeInfo` instead of `info.Record.fields`, wire the module in `root.bp`); `recordKeys`, `field` as fns over `@typeInfo`. Remove `tryResolveTypeManipulationCall` and the `@makeRecord`/`@RecordKeys`/`@field` builtins | `builtins_typeinfo.zig` passes without the special cases; a user fn named like a std type function is not shadowed |

Step 4 note: `comptime val` is folded in Zig and cannot evaluate calls or control flow
(`validateComptimeExpr` rejects them before `eval.zig` sees them); type-level eval with control
flow has to go through the `erl` path (as decorators/templates do) or extend
`comptime/eval.zig` + `comptime/error.zig` — decide in step 4, after C4.

## Part B — Narrowing

Current state per pattern (checker behaviour from `botopink check`, test state from the
`comptime/tests/narrowing.zig` snapshots):

| Pattern | Checker | Comptime test |
|---|---|---|
| `if (x) { n -> … }` | works: `n` is the inner type | 2 tests source-only (top-level `@print`); `if_null_check_chained` has no null check and uses an unparseable `?record { … }` |
| early return / negative check (`if (!x) { return …; }`, `x == null`, `x != null`) and the `else` of a check | not implemented: `!` requires `bool`, comparisons with `null` do not narrow | source-only + type error |
| `case` on `@Result` / enum payloads | bindings untyped (C8) | source-only; `different_payload_types` uses a nested pattern `Err(Timeout(msg))` that does not parse; `nested_variant_access` uses `val` as a field name |
| OR patterns | bindings untyped (C8) | JSON present, asserts nothing |
| guards `x if (…) ->` | bindings untyped (C8) | source-only; `guard_variant_field` is non-exhaustive (checker is right) |
| `assert x is P;` | does not parse (only `val assert P = e catch h`, see C12) | 2 tests source-only |
| type guard `-> x is T` | call typed `T` (C5); guard on an `i32` param is vacuous | source-only; `narrowing_in_if` uses an `_ ->` binder the `if` parser rejects (`parser/exprs.zig` l.152 accepts identifiers only) |
| `&&` | `if` conditions are parsed at `prec.equality` (`parser/exprs.zig` l.143), so `if (a && b)` is a parse error (`if ((a && b))` parses); the RHS narrowing in `inferBinaryOpExpr` (l.5345-5357) then fails `b && b.weight > 10` on `?Box` because the LHS must be `bool` | source-only |
| `?.` | works (`o.inner?.value` : `?i32`) | JSON shows `?` only |
| `else if` chain | n/a — the test has no null check (`x == 0` on `?i32`) | source-only |

| Step | What | Acceptance |
|---|---|---|
| 6 | Rewrite `comptime/tests/narrowing.zig` so every source parses (no top-level `@print`, named record payloads, supported patterns) and each pattern asserts the narrowed type through an annotated `val` plus a negative error snapshot. Decide and implement or drop: `&&`/`\|\|` in `if` conditions, `_` as `if` binder, `assert x is P`, negative/early-return and `else` narrowing, nested patterns. Depends on C5 and C8 | no source-only narrowing snapshot; every kept pattern has a positive and a negative test; dropped patterns are deleted from both test files |
| 7 | Narrowing codegen on the 4 backends: rewrite the 5 fixtures that write 0-byte snapshots, and fix the `else if` fixture (no null check, `"nonzero: " + x`). Backend output bugs found here (JS destructures payloads by binder name, erlang/beam variant patterns, `return if` in JS, wasm narrowing bindings) go to spec 03 | ≥1 test with a correct RUN LOG per runtime-relevant pattern on commonJS, erlang and beam (wasm once spec 03 step 2 runs WAT) |

Part B step 6 parser changes (`parser/exprs.zig`) are independent of Part A. Part 0, steps 2–5
and step 6 all touch `comptime/infer.zig` — do not parallelise them across branches; C4 and
step 7 can run beside them.

---

## Open questions

- `@code(text)` already exists as a builtin valid only inside template fns (`infer.zig`
  l.3806; lowered through `template_eval.zig`). `#[@code]` would be the first `#[@…]` annotation
  that is neither an effect (`ast.zig` `EffectKind`) nor `@external`; the positions do not clash
  syntactically, but confirm the shared name is intended or pick another.
- Mismatched `case` arms (C2): union type (`typeNameOf` already renders `.union_`) or error.

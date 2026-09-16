# Spec 02 — Type system

**Version:** 1.0.2-beta
**Priority:** high — the checker accepts wrong programs, so a large share of the "happy path"
suite asserts nothing
**Depends on:** none (the harness precondition — a snapshot test fails when its program does
not compile — landed in 1.0.1-beta spec 01)

---

## Objective

A checker that rejects wrong programs (return, `case`, patterns, methods, record update),
types as comptime values that are actually evaluated instead of special-cased by name in
inference, type construction through `#[@code]`, std type functions written in `.bp`, and
narrowing that parses, type-checks and runs on every backend.

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/`. Line numbers are
at `botopink-lang` HEAD; re-locate by the quoted symbol.

## Current state

Every row below was re-confirmed at HEAD by reading the code and by `botopink check` on a
scratch project. The probe output is quoted in each row.

**Closed by the 1.0.1-beta comptime-folding wave — do not re-open:**

- **C4** (`comptime val` folding): `comptime/eval.zig` folds by operand kind, `comptime { … }`
  has a scope in `comptime/error.zig` + `eval.zig`, and `comptime <RecordCtor>(…)` is rejected
  on purpose. Only one residual remains, tracked as **C4b** below.

**Unchanged since the milestone opened** — `comptime/infer.zig` and `comptime/env.zig` were
touched in 1.0.1-beta only by the parser wave (which removed `captureExprArg`'s mirror
compensation) and by the snapshot-trace wave. No checker row was fixed.

### Existing machinery

- **Inference builtins** (`infer.zig` `inferBuiltinCallReturnType`, l.3797): `@typeInfo(T)` →
  the `TypeInfo` type, `@TypeOf(v)` → the argument's type, `@makeRecord(fields)` → fresh var
  (a literal `RecordField` array is resolved earlier by `tryEvalMakeRecord`, l.3966 / call
  site l.6885), `@RecordKeys(T)` → `Array<string>` (l.3853), `@field(v, name)` → the type of
  `v` (l.3858), `@comptimeError(msg)` → custom error. They resolve **types** during inference;
  they compute no values. The value domain (`TypeInfo`, `RecordField`, `EnumVariant`,
  `TypeInfoKind`) is declared in `comptime.zig` `type_info_src`.
- **Type functions by name** (`infer.zig` `tryResolveTypeManipulationCall`, l.4041, called at
  l.6901 for every non-builtin call *before* user bindings): `mergeRecords`, `partial`, `omit`,
  `pick` are resolved in Zig; `mapFields` is matched and returns `null` (l.4071, not
  implemented).
- **`.bp` type functions**: `libs/std/src/types.bp` (`mapFields`/`partial`/`omit`/`pick`) and
  `libs/std/src/reflect.bp` (`mergeRecords`) are still absent from `libs/std/src/root.bp`, so
  they are never loaded (see 1.0.1-beta spec 05 item 5.1). `types.bp` fails with
  `unknown field 'Record' on type 'TypeInfo'` (`info.Record.fields` on an enum); `reflect.bp`
  does not parse (a boolean operator inside an `if` condition — see C3 / Part B `&&`).
- **Types as values**: any value binding is accepted as an annotation through the `env.zig`
  `resolveTypeName` bindings fallback (l.893-931: `val T = i32; val x: T = "s"` reds, but
  `val n = 5; val x: n = 7` also checks); an unknown name becomes an opaque named type
  (l.930-931). `comptime T: type` parameters do not constrain other parameters. A call in
  annotation position (`val z: mk() = …`) does not parse.
- **Type guards**: `-> x is T` parses (`parser/decls.zig` l.346-354 → `FnDecl.typeGuardParam`)
  and registers `env.typeGuardFns` (`infer.zig` l.539, l.2865); the then-branch narrowing is
  at `infer.zig` l.5806-5830.
- **Snapshot limits** (they shape every acceptance below): the typed JSON renders any
  non-`.named` TypeRef as `?` (`comptime/snapshot.zig` `typeNameFromTypeRef`, l.239-244) and
  shows a fn body as raw source lines, so a checker fix is asserted with annotated top-level
  `val`s plus an error snapshot.

---

## Part 0 — Checker correctness

Fixing these will red tests and possibly `libs/` code — regenerate and review, and keep
`zig build test-libs` green.

| Step | What (evidence at HEAD) | Acceptance |
|---|---|---|
| C1 | `return` is never unified with the declared return type: `inferFnDecl` discards body results ("we ignore the result for now", `infer.zig` l.2868); the `.@"return"` jump is typed `void` with no unify (l.5563). `fn f() -> i32 { return "s"; }` checks. Same gap for the `@Generator` R channel and untyped lambdas | `fn f() -> i32 { return "s"; }` reds at the value; `#[@generator]` `return 42` against `R = string` reds |
| C2 | `case` is typed as a fresh var and the arms are never unified (`infer.zig` l.7470): `val a: bool = case 42 { 0 -> "a"; _ -> "b"; };` checks. `comptime { … }` is typed from its last statement, i.e. `void` (l.7524-7527): `val h = comptime { break 1; }; val z: i32 = h;` reds with `expected i32, got void` — the 1.0.1 folder evaluates the block but inference still does not | `val a: bool = case 42 { … };` reds; decide union vs error for mismatched arms and pin it in `case_arms_*union*`; `val h = comptime { break 1; }; val z: i32 = h;` checks |
| C3 | Operand orientation and constraints: `&&`/`\|\|` (l.5374-5375) and `!` (l.5413) call `unifyAt(operand, bool)` although `unifyAt` is target-first, so expected/found are swapped — `(1 && true)` reports `expected i32, got bool`. `+` short-circuits to `string` whenever either side is a string (l.5382), `+` and `-`/`*`/`/`/`%` then call `unify` with no location (l.5386, l.5394) so `"a" * "b"` checks, and `.neg` applies no constraint at all (l.5417) so `-"s"` checks. `yield` is swapped the same way | `1 && true` → `expected: bool, found: i32` with a caret; `"a" * "b"` and `-"s"` red with a location |
| C4b | An irreducible fold is silently `null` rather than a comptime error. `comptime/error.zig` `validateComptimeExpr` rejects most unfoldable shapes up front (calls, record literals, `loop`, `case`, out-of-scope identifiers), but a division by zero and `-"s"` still reach `eval.zig` `binary` / `valueOf` and fold to `null_`, which `literal` writes as `null` | `comptime 1 / 0` and `comptime -"s"` are comptime errors located at the expression, not `null` |
| C5 | A type-guard fn is typed as the narrowed type, not `bool`: `parser/decls.zig` l.346-354 stores `T` as the fn's `returnType` when it parses `-> x is T`, and that is used as the call type (`buildFnSignatureType` l.709-712, `inferFnDecl` l.2731-2734). `val b: bool = isPositive(5);` reds with `expected bool, got i32`, and a guard call in `if` then fails `unifyAt(bool, …)`, so the narrowing at l.5806-5830 is unreachable | `val b: bool = isPositive(5);` checks; `if (isStr(y)) { val s: string = y; }` checks with `y: ?string`; the guard body must return `bool` |
| C6 | Type builtins: `@field` returns the receiver's type (l.3858-3861) — `val xv: string = @field(p, "x")` reds with `got P`; `@RecordKeys` builds a nominal `Array` (l.3853) that does not unify with `string[]` — `expected array, got Array`; `@makeRecord(ident)` is a fresh var because `tryEvalMakeRecord` only reads literal arrays; `pick` errors point at the call, not the missing name; `tryResolveTypeManipulationCall` (l.4041) runs before user bindings, so a user `fn pick(…)` is shadowed | a user fn named `pick`/`omit`/`partial`/`mergeRecords` resolves to the user fn; `@field` returns the field type; `val k: string[] = @RecordKeys(P)` checks; `@makeRecord(fields)` with a comptime `val fields` builds the record. The builtin-specific rows drop if Part A step 5 lands first; the shadowing fix is needed either way |
| C7 | Generic arguments are lost on enum unit variants: they are typed `namedType(Enum)` with no args (`infer.zig` l.5228), unlike `env.zig` `resolveTypeName` l.904-913 which adds fresh args. `val n: Option<i32> = Option.None;` reds with `expected Option, got Option`. Chained defaults are not enforced either (`record Sym<T, U = T>` accepts `Sym<i32>` with `right: "two"`) | both examples behave (the first checks, the second reds); `generic_enum_option_t_unit_and_payload_variants` shows `Option<i32>` for `n` |
| C8 | Pattern bindings are untyped: `bindPatternNamesForSubject` (`infer.zig` l.4851) binds every variant payload, OR alternative, guard identifier and list element to `freshVar()`. With `enum E { A(v: i32), B }` and `fn f(s: string)`, `case e { A(v) -> f(v); … }` checks | `A(v) -> f(v)` reds; same for `Dog(b) \| Cat(b)`, `x if (x > 0) -> f(x)`, `Ok(v)`/`Err(e)` on `@Result`, `[first, ..rest]` |
| C9 | Methods: record/enum method bodies are best-effort and errors are swallowed (`inferTypeMethods` l.2916, l.2967); a method with no return annotation gets no stored signature and falls back to a fresh var (l.1002-1006); an unknown method takes the permissive path (l.6492) — `d.swim()` on a record with no `swim` checks | a type error in a record method body reds; `val a: string = d.quack()` reds when `quack` returns `self.id`; calling an undefined method reds (`methodNotActive` / unknown method) |
| C10 | Unknown type names are accepted: `resolveTypeName` falls back to an opaque named type (`env.zig` l.930-931) — `record Q { lat: bogusType }` checks — and accepts any value binding as a type (l.916-928) | an unknown type name reds at the TypeRef; a non-type binding in annotation position reds; forward references to records/enums declared later still check |
| C11 | Record update spread is positional: with one spread and fewer than two other args the args unify against the fields by index, otherwise labels are ignored (`infer.zig` l.7203-7213). `Person(..alice, age: 25)` on `record Person { name: string, age: i32 }` reds with `expected string, got Person` — it matched field 0 | label-based update: `..alice, age: 25` checks; an unknown label → `unknown field` at the label; a wrong value type → caret at the value; spreading another variant reds with a variant message (`variant_mismatch`, `non_existent_field`, `field_type_mismatch` regenerated) |
| C12 | Expression gaps: `val assert P = e catch h` swallows the inference errors of both `e` and `h` behind a fresh var and never checks `P` against `e` (l.7544-7558); a pipeline into a bare fn identifier is typed as the function — `val r: i32 = 1 \|> double;` reds with `expected i32, got function` (l.7292-7295) — and a pipeline call with the wrong arity is not reported (l.7258-7266) | `val assert 42 = answer catch 0;` with `answer` unbound reds; `val r: i32 = 1 \|> double;` checks; `1 \|> add(1, 2)` for a 2-ary `add` reds |
| C13 | Diagnostics: `effect-missing-wrapper` (R4) is unreachable because every primitive return type is `.named`, so `infer.zig` l.2796-2799 always picks `effect_wrapper_mismatch` — `#[@result] fn f() -> i32` reports `effect-wrapper-mismatch` located at the first body statement (`fnLoc`, l.2789), not at the return type; a bodyless `declare fn` gets no location at all. Many `TypeError`s still carry no location (`comptime/error.zig` `unknownField` l.197, `missingMethod` l.253, `unknownMethod` l.257, `ambiguousMethod` l.265, extend/activation, pub-default, RG3, arithmetic `unify`) | `#[@result] fn f() -> i32` reports `effect-missing-wrapper` at the return type; every error snapshot listed in 1.0.1-beta `06-snapshot-review/comptime-errors-effects.md` root cause 5 has a `┌─` location |

Order: C1 and C8 first (they unmask most vacuous tests), then C2, C5, C3, the rest in any
order. C4b is `comptime/eval.zig` + `comptime/error.zig` only and can run beside the others.

## Part A — Types as values

| Step | What | Acceptance |
|---|---|---|
| A1 | `type` as a first-class comptime value: `val T = i32`, `comptime T: type`, `-> type` return. Replace the bindings-as-types fallback (C10) with a real `type` kind; a `comptime T: type` argument binds `T` for the remaining parameters and the return | usable as annotation, value, parameter and return; `id(i32, "s")` reds; `val n = 5; val x: n = 7` reds |
| A2 | `#[@code]` on a fn: the returned `TypeInfo` becomes the type at the call site (`val p: Point() = Point()(x: 1, y: 2)`), comptime parameters included. Needs a call in TypeRef position, which does not parse today | the annotation parses, the type is lifted, the constructor is usable |
| A3 | `@typeInfo`/`@TypeOf` produce **values** (`TypeInfo.Record(fields: [...])`, `TypeInfo.Optional(inner: …)`) of the existing `TypeInfo` enum, and `validateComptimeExpr` accepts them. Today `eval.zig` `valueOf` folds `@typeInfo` to the opaque `.object` and `@TypeOf` to a type *name* string | correct values for primitives, record, enum, optional, array |
| A4 | A comptime eval loop for `.bp` fns with `comptime` params (`if`, `loop`, `break` with a type value, `case` on `TypeInfo`) | `types.bp`/`reflect.bp` fns are executed, not resolved by name |
| A5 | Std in `.bp`: `mergeRecords`, `mapFields`, `partial`, `omit`, `pick` with `#[@code]` (rewrite the bodies to match on `TypeInfo` instead of `info.Record.fields`, wire the module into `root.bp`); `recordKeys`, `field` as fns over `@typeInfo`. Remove `tryResolveTypeManipulationCall` and the `@makeRecord`/`@RecordKeys`/`@field` builtins | `comptime/tests/builtins_typeinfo.zig` (31 tests) passes without the special cases; a user fn named like a std type function is not shadowed |

A4 note: `comptime/error.zig` `validateComptimeExpr` still rejects a call (`.call` other than a
pipeline), a `loop` and a `case` before `eval.zig` sees them, and `eval.zig` has no function
application. Type-level eval with control flow therefore has to go through the `erl` path (as
decorators and templates do) or extend `eval.zig` + `error.zig` — decide in A4.

## Part B — Narrowing

The 1.0.1-beta harness wave rebased the fixtures: every narrowing test now compiles or is a
documented compile-error skip, and the codegen fixtures that wrote 0-byte snapshots are gone.
What the tests *assert* is still open.

**Checker, per pattern (from `botopink check` at HEAD):**

| Pattern | Checker |
|---|---|
| `if (x) { n -> … }` | works — `n` is the inner type |
| early return / negative check (`if (!x) { return …; }`, `x == null`, `x != null`) and the `else` of a check | not implemented: `!` requires `bool`, comparisons with `null` do not narrow |
| `case` on `@Result` / enum payloads | bindings untyped (C8) |
| OR patterns | bindings untyped (C8) |
| guards `x if (…) ->` | bindings untyped (C8) |
| `assert x is P;` | does not parse — only `val assert P = e catch h` exists (C12); `comptime/tests/narrowing.zig` records this as a documented skip |
| type guard `-> x is T` | the call is typed `T` (C5) |
| `&&` | `if` conditions are parsed at `prec.equality` (`parser/exprs.zig` l.136), so `if (a && b)` is a parse error while `if ((a && b))` parses; the LHS narrowing in `inferBinaryOpExpr` (l.5347-5358) then fails `b && b.weight > 10` on `?Box`, because `.@"and"` unifies both operands with `bool` at l.5374-5375. Recorded as a documented skip in both narrowing test files |
| `?.` | works (`o.inner?.value` : `?i32`) |
| `else if` chain | n/a — the fixture has no null check (`x == 0` on `?i32`) |

**Comptime tests** (`comptime/tests/narrowing.zig`, 19 tests): the 15 success fixtures now all
record a `TYPED AST JSON` section (3 more are documented compile-error skips, 1 is an error
snapshot), but none of them asserts a narrowed type — the JSON renders a fn
body as raw source lines and a non-`.named` return as `?` (`comptime/snapshot.zig`
`typeNameFromTypeRef`), so the snapshot only proves the program compiles.

**Codegen tests** (`codegen/tests/narrowing.zig`, 11 tests × 4 backends): 9 run, 2 are
documented compile-error skips (`assert_pattern`, `and_condition`). Every RUN LOG at HEAD:

| Fixture | commonJS | erlang | beam | wasm |
|---|---|---|---|---|
| `if_null_check_with_print` | `42` | `42` | *(empty)* | *(empty)* |
| `case_enum_area_with_print` | `NaN` `NaN` | `12.56` `9.0` | `12.56` `9.0` | *(empty)* |
| `case_result_ok_err_with_print` | `undefined` ×2 | `<<"OK:data">>` `<<"ERR:fail">>` | `{ok,<<"data">>}` `{error,<<"fail">>}` | *(empty)* |
| `early_return_with_print` | `hello world` `nobody` | `<<"hello world">>` `<<"nobody">>` | *(empty)* | *(empty)* |
| `type_guard_basic_codegen` | `true` | `true` | `true` | *(empty)* |
| `type_guard_if_codegen` | `true` | `false` | `false` | *(empty)* |
| `case_option_some_none` | `value: undefined` `empty` | *(empty)* | *(empty)* | *(empty)* |
| `optional_chaining_field_access` | `42` | `42` | `42` | *(empty)* |
| `else_if_chain_with_null_checks` | *(empty)* | *(empty)* | *(empty)* | *(empty)* |

Only `optional_chaining_field_access` and `type_guard_basic_codegen` agree across the three
executing backends. `type_guard_if_codegen` is a live cross-backend disagreement
(`true` vs `false`); the JS payload bindings (`undefined`, `NaN`) and the BEAM `case`
arm that prints the raw `{ok,…}` tuple are backend bugs.

| Step | What | Acceptance |
|---|---|---|
| B6 | Make `comptime/tests/narrowing.zig` assert the narrowing: each pattern gets an annotated top-level `val` pinning the narrowed type plus a negative error snapshot. Decide and implement or drop the documented skips: `&&`/`\|\|` in `if` conditions (`parser/exprs.zig` l.136), `_` as an `if` binder (l.145 accepts identifiers only), `assert x is P`, negative/early-return and `else` narrowing, nested patterns. Depends on C5 and C8 | every kept pattern has a positive and a negative test; no fixture whose only assertion is "it compiles"; dropped patterns are deleted from both test files |
| B7 | Narrowing codegen on the 4 backends: every executing backend of a fixture prints the same, correct value. Fix the `else_if_chain` fixture (no null check, `"nonzero: " + x`). Backend output bugs found here (JS destructuring payloads by binder name, erlang/beam variant patterns, BEAM printing the unmatched tuple, `return if` in JS, wasm narrowing bindings) belong to the codegen spec | the table above has one identical, correct RUN LOG per row across commonJS, erlang and beam (wasm once the WAT runner executes) |

Part 0, A2–A5 and B6 all touch `comptime/infer.zig` — do not parallelise them across branches.
The B6 parser changes (`parser/exprs.zig`) are independent of Part A; C4b and B7 can run
beside everything else.

---

## Open questions

- `@code(text)` already exists as a builtin valid only inside template fns (`infer.zig`
  l.3806, lowered through `template_eval.zig`). `#[@code]` would be the first `#[@…]`
  annotation that is neither an effect (`ast.zig` `EffectKind`) nor `@external`; the positions
  do not clash syntactically, but confirm the shared name is intended or pick another.
- Mismatched `case` arms (C2): a union type (`typeNameOf` already renders `.union_`) or an
  error.

# Checker rows — mechanism, deciding site, probe

The correctness rows of front 07. Each row is stated as: **where** it is decided (`file:line` at
HEAD), **why** it was written that way, what **correct** means, the **probe** that shows it at
HEAD, and the **acceptance** condition. The blast radius and the library exposure of each row are
in [`blast-radius.md`](./blast-radius.md); the landing order is in [`groups.md`](./groups.md).

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/`. Line numbers are at
`botopink-lang` HEAD; re-locate by the quoted symbol.

## The four mechanisms

Every row except C4b, C6, C7, C10 and C11 is an instance of one of these.

| # | Mechanism | Why it is written that way | Rows |
|---|---|---|---|
| M1 | **A fresh type variable is the escape hatch.** `env.freshVar()` unifies with anything, so any construct the checker cannot type yet is given one and nothing downstream ever contradicts it | Deliberate: a fresh var imposes no ordering constraint, so a construct can be typed before the information that would type it exists (a method body before its signature, a pattern binding before the subject's variant table is consulted). It also keeps a gap from failing the whole compile | C1, C2, C5, C8, C9, C12 |
| M2 | **`unifyAt` is target-first and several callers pass operand-first.** `unifyAt(env, a, b, loc)` (`infer.zig` l.3769-3777) documents `a` = the declared/expected type; `TypeError.typeMismatch(a, b)` renders "expected `a`, got `b`" | A local slip, not a decision — the `if` condition at l.5833 and `assert` at l.7535 get it right (`unifyAt(bool, cond)`), the boolean operators and `!` do not | C3, C13 |
| M3 | **One-way optional subsumption is reached from the wrong side.** `unify.zig` l.48-52 lets an *expected* `?T` accept a plain `T`. Arithmetic calls `unify(env, lhsTy, rhsTy)` with the operand as `a`, so an operand of type `?i32` silently subsumes the other operand | The subsumption itself is correct and load-bearing (`val x: ?i32 = 5`). It leaks only because arithmetic passes an operand where the function expects a declared type. Probe: `fn f(x: ?i32) -> i32 { return x + 1; }` checks | C3, and every "narrowing is not needed" false negative in [`narrowing.md`](./narrowing.md) |
| M4 | **Best-effort walks swallow errors.** `inferTypeMethods` (l.2916-2967) explicitly documents that a method body tripping an inference gap is skipped so the gap does not fail the compile | Deliberate, and currently load-bearing: it exists because the bodies *do* trip gaps. Removing it without first fixing the gaps reds every library with a record method | C9 |

`unify` itself never carries a location (`comptime/unify.zig` l.37, 54, 58, 66, 76, 85, 97, 102,
109, 119, 127 all build the error with no `loc`). A location appears only when the caller went
through `unifyAt`; the two arithmetic call sites (`infer.zig` l.5386, l.5394) do not.

## Existing machinery

- **Inference builtins** (`infer.zig` `inferBuiltinCallReturnType`, l.3797, called at l.6889):
  `@typeInfo(T)` → the `TypeInfo` type (l.3838), `@TypeOf(v)` → the argument's type (l.3843),
  `@makeRecord(fields)` → fresh var (l.3849; a literal `RecordField` array is resolved earlier by
  `tryEvalMakeRecord`, l.3966 / call site l.6885), `@RecordKeys(T)` → `Array<string>` (l.3854),
  `@field(v, name)` → the type of `v` (l.3859), `@comptimeError(msg)` → custom error. They resolve
  **types** during inference; they compute no values. The value domain (`TypeInfo`, `RecordField`,
  `EnumVariant`, `TypeInfoKind`) is declared in `comptime.zig` `type_info_src`; `TypeInfo` is an
  **enum with payload variants** (`Record(fields: RecordField[])`, `Optional(inner: string)`, …).
- **Type functions by name** (`infer.zig` `tryResolveTypeManipulationCall`, l.4041, called at
  l.6901 for every non-builtin call *before* user bindings **and before the receiver check**):
  `mergeRecords`, `partial`, `omit`, `pick` are resolved in Zig; `mapFields` is matched and returns
  `null` (l.4071-4072, not implemented).
- **`.bp` type functions**: `libs/std/src/types.bp` (`mapFields`/`partial`/`omit`/`pick`) and
  `libs/std/src/reflect.bp` (`mergeRecords`) are absent from `libs/std/src/root.bp`, so they are
  never loaded — `botopink check` in `libs/std` prints `module not reached by any mod path` for
  both (and for `primitives.bp`). Neither compiles: see
  [`types-as-values.md`](./types-as-values.md).
- **Types as values**: any value binding is accepted as an annotation through the `env.zig`
  `resolveTypeName` bindings fallback (l.916-928: `val T = i32; val x: T = "s"` reds, but
  `val n = 5; val x: n = 7` also checks); an unknown name becomes an opaque named type (l.930-931).
  `comptime T: type` parameters do not constrain other parameters. A call in annotation position
  (`val z: mk() = …`) does not parse.
- **Type guards**: `-> x is T` parses (`parser/decls.zig` l.349-357 → `FnDecl.typeGuardParam`) and
  registers `env.typeGuardFns` (`infer.zig` l.539, l.2865); the then-branch narrowing is at
  `infer.zig` l.5808-5845.

## What a typed-AST snapshot can and cannot assert

These shape every acceptance above. Two different functions produce a `?` in a typed-AST snapshot
and they mean **opposite** things:

- `typeNameFromTypeRef` (`comptime/snapshot.zig` l.239-244) renders an **annotation** and is purely
  syntactic — only `.named` survives, so `?i32`, `T[]`, `#(A,B)`, `fn(A) -> B`, `Option<T>`, a
  typeparam and an anonymous record are all `?`. It never consults inference, so **it does not move
  when the checker becomes strict**. 52 of the 78 `?`s in `snapshots/comptime/node` come from here
  (28 fn return types, 22 fn params, 2 record fields).
- `typeNameOf` (`comptime/snapshot.zig` l.477) renders an **inferred** type and prints `?` for a
  `.typeVar` — that is the checker admitting it does not know. The other **26 `?`s, spread over 17
  slugs** in each comptime backend dir, come from here (12 in `case` arms, 7 under a `val`, 7 under
  a `call`). 51 files per dir contain a `?` of either kind; only those 17 (68 files across the four
  dirs) are the visible blast radius of M1 — **do not `grep '"?"'` to size a row.**
- A fn body is shown as raw source lines (`extractFnBody`, l.246-257). So a checker fix is asserted
  with annotated top-level `val`s plus an error snapshot, never by reading a body out of a snapshot.

`comptime/snapshot.zig` itself is owned by [`10-comptime-dedup`](../10-comptime-dedup/README.md),
which renders from inference instead of from syntax. If that front lands first, the
`typeNameFromTypeRef` `?`s disappear for a different reason and the counts above stop holding.

### The tripwire set

The 17 slugs (identical names in all four comptime dirs) where the checker visibly punts today:
`case_arms_with_different_types_string_i32_union`, `case_union_return_type_from_mismatched_arms`,
`case_with_variant_field_bindings_body_does_not_use_bound_vars` (+7 more `case_*`);
`inherent_record_method_is_always_available`,
`local_extension_method_resolves_without_activation`,
`multi_module_extension_activated_via_star_import`,
`qualified_extension_call_needs_no_activation`; `single_field_returns_record_type`,
`multiple_fields_returns_record_type` (+1 `@makeRecord`). C2, C6, C8 and C9 all collapse onto this
same set — regenerating those 68 files covers the majority of the observable churn.

## Row index

| Row | Site | Mechanism (one line) | Blast radius |
|---|---|---|---|
| C1 | `infer.zig` l.2868-2871, l.5526-5563 | M1 — the body is walked for effect only and `.@"return"` is typed `void` without unifying its value against the declared return type | **library** + **many** |
| C2 | `infer.zig` l.7470 (`case`), l.7524-7529 (`comptime {}`) | M1 — `case` gets a fresh var and its arms are never unified; a `comptime` block is typed from its last *statement*, so a `break`-carrying block is `void` | **many** (case) + **none** (comptime block) |
| C3 | `infer.zig` l.5374-5375, l.5382-5395, l.5413, l.5417; `unify.zig` l.48-52 | M2 + M3 — boolean operands unify operand-first, `+` short-circuits to `string`, arithmetic calls bare `unify` (no location, and optional subsumption leaks), `.neg` applies no constraint | **many** (error snapshots) + possible **library** |
| C4b | `eval.zig` l.249-250, l.260-261, l.266-272, l.139-143 | an irreducible fold returns `.null_` instead of raising | **none** |
| C5 | `parser/decls.zig` l.349-357; `infer.zig` l.709-712, l.2731-2734 | the parser stores the *narrowed* type as the fn's `returnType`, so a guard call is typed `T`, not `bool` | **few** + **unblocks** |
| C6 | `infer.zig` l.3849-3861, l.4041-4072, l.6901 | name-keyed resolution runs before user bindings and before the receiver check | **few** + **unblocks** (`libs/std`) |
| C7 | `infer.zig` l.5228 | a unit variant is typed `namedType(Enum)` with no args, unlike `env.zig` l.904-913 which supplies fresh ones | **few** — zero library sites |
| C8 | `infer.zig` l.4851-4894 | M1 — `bindPatternNamesForSubject` receives `subjectType` but uses it only to tell a variant name from a binder; every binding gets `freshVar()` | **library** + **many** |
| C9 | `infer.zig` l.2916-2967 (bodies), l.1002-1006 (signatures), l.7105-7114 (dispatch) | M4 — method bodies are walked best-effort, an unannotated method stores no signature, and an unresolved `recv.m(…)` returns a fresh var | **library** |
| C10 | `env.zig` l.916-931 | `resolveTypeName` falls through to an opaque named type, and accepts any value binding | **library** |
| C11 | `infer.zig` l.7203-7232 | a record-update call unifies args against fields **by index**; labels are read only to skip the `..` spread | **few** — zero library sites |
| C12 | `infer.zig` l.7544-7563 (`val assert`), l.7293-7299 + l.7258-7267 (pipeline) | M1 — `val assert` swallows both sub-inferences behind a fresh var; a pipeline into a bare identifier is typed as the function; a pipeline arity mismatch is skipped, not reported | **few** — zero library sites |
| C13 | `infer.zig` l.2789, l.2796-2799; 9 unlocated `TypeError.custom` sites; all of `unify.zig` | the effect diagnostic branches on `.named` (always true for a primitive) and locates at the first body statement; many errors carry no `loc` at all | **many** (error snapshots) |

---

## C1 — `return` is never unified with the declared return type

| | |
|---|---|
| **Where** | `infer.zig` l.2868-2871 (`// Infer body (for type checking; we ignore the result for now).`) and the `.@"return"` arm l.5526-5563, which builds `valPtr` and then types the jump `void` (l.5563) without unifying `valPtr` with `retType` (computed at l.2731-2734) |
| **Why** | `retType` is in scope, so this is not an ordering problem — the body walk was written to record lowerings (`result_jump_lowerings` l.5542-5545, `future_jump_lowerings` l.5560) and the unify step was never added. The `#[@result]` / `#[@future]` arms *do* inspect the returned value's type (l.5536, l.5556), so the plumbing exists |
| **Correct** | `env` carries the current fn's return type (like `env.starFn` / `env.throwContext` already do, saved/restored at l.2822-2827); `.@"return"` unifies `unifyAt(retType, value, valueLoc)`. A bare `return;` unifies against `void`. **The target inside an effect body is the wrapper's inner channel, not the wrapper**: `#[@result]` → the `R` of `@Result<R, E>`, `#[@future]` → the `T` of `@Future<T, E>`, `#[@generator]` → the `R` channel, `#[@context]` → the `X` of `@Context<B, X>`; `#[@iterator]` already forbids `return <expr>` (l.5491-5501). That is not a concession — it is the auto-wrap contract the lowering already records (`wrap_ok` l.5544, `wrap_resolved` l.5560), and it is 9 of the 44 library sites, 5 of them `@Context` in `jhonstart/src/hooks.bp`. A lambda with no declared return type unifies its `return`s with each other |
| **Probe at HEAD** | `fn f() -> i32 { return "s"; }` → `Checked`. `record Sym<T, U = T> { left: T, right: U } fn pair() -> Sym<i32> { return Sym(left: 1, right: "two"); }` → `Checked` (this is why C7's chained-default claim is unobservable today) |
| **Acceptance** | `fn f() -> i32 { return "s"; }` reds at the value with a caret; `#[@generator]` `return 42` against `R = string` reds; `val f = fn(x: i32) -> i32 { return "s"; };` reds |

## C2 — `case` is a fresh variable; a `comptime` block is typed from its last statement

Two independent defects; they may land separately.

| | |
|---|---|
| **Where (a)** | `infer.zig` l.7470 — the `case` node is built with `.type_ = try env.freshVar()`. Arms are inferred (l.7452) and restored (l.7456) but never unified with each other. Exhaustiveness *is* checked (l.7467-7469) |
| **Where (b)** | `infer.zig` l.7524-7529 — `comptimeBlock` takes the type of the last typed statement; a `break 1;` statement is a `.jump`, typed `void` at l.5563 |
| **Why** | (a) A fresh var avoids deciding the mismatched-arm policy (union vs error) — the decision is still open, see the README's Notes. (b) The 1.0.1 folding wave made `eval.zig` `blockValue` (l.303-317) evaluate the block's `break` value, but inference was not taught the same rule |
| **Correct** | (a) The `case` type is the unification of the arm types; an arm that is a `.jump` (`return`/`break`/`continue`) contributes nothing. (b) A `comptime` block's type is the type of its `break` value (`blockResult`'s rule), `void` when there is none |
| **Probe at HEAD** | `val a: bool = case 42 { 0 -> "a"; _ -> "b"; };` → `Checked`. `val h = comptime { break 1; }; val z: i32 = h;` → `type mismatch: expected i32, got void at main:2:14` |
| **Acceptance** | `val a: bool = case 42 { … };` reds; the mismatched-arm policy is pinned in `case_arms_*union*`; `val h = comptime { break 1; }; val z: i32 = h;` checks |
| **Ordering** | (a) is the same value flow as C1: both decide "what type does this position produce", and 31 of C1's 44 library sites are `return <ident>` where the ident came from a `case` — C1 cannot check them and C2a has nothing to check them against. One branch, C1 first |

## C3 — Operand orientation, arithmetic constraints, and the subsumption leak

| | |
|---|---|
| **Where** | `infer.zig` l.5374-5375 (`.@"and"`/`.@"or"`) and l.5413 (`.not`) call `unifyAt(operand, bool, loc)` — operand-first, against the contract at l.3769-3771. `.add` short-circuits to `string` when *either* side is a string (l.5382) and otherwise calls bare `unify(env, lhsTy, rhsTy)` (l.5386); `.sub`/`.mul`/`.div`/`.mod` the same (l.5394). `.neg` (l.5417) applies no constraint at all. `yield` (l.5777) is swapped the same way |
| **Why** | A slip, not a decision: `if` conditions (l.5833) and `assert` (l.7535) call the same helper correctly. The `.add` string short-circuit is intentional (string coercion) but it fires on `1 + "a"` too |
| **Correct** | `unifyAt(bool, operand, operandLoc)` for `&&`/`\|\|`/`!`/`yield`, located at the *operand*, not the whole expression. Arithmetic constrains both operands to a numeric interface and reports at the offending operand; `.neg` constrains to numeric; `+` keeps the string coercion only when both sides are string-compatible |
| **The leak** | Because arithmetic passes an operand as `unify`'s `a`, `unify.zig` l.48-52 (expected `?T` accepts a plain `T`) fires in the operand direction. `fn f(x: ?i32) -> i32 { return x + 1; }` checks at HEAD and the result type is `?i32`. Every [`narrowing.md`](./narrowing.md) "why does this compile without narrowing" question resolves here |
| **Probe at HEAD** | `val q: bool = (1 && true);` → `expected i32, got bool at main:1:18` (reversed). `val q = "a" * "b";` → `Checked`. `val q = -"s";` → `Checked` |
| **Acceptance** | `1 && true` → `expected: bool, found: i32` with a caret on `1`; `"a" * "b"` and `-"s"` red with a location; `fn f(x: ?i32) -> i32 { return x + 1; }` reds |

## C4b — an irreducible comptime fold yields `null`

| | |
|---|---|
| **Where** | `comptime/eval.zig` `binary` l.249-250 and l.260-261 return `.null_` for a zero divisor; `numeric` (l.266-272) returns null for a string operand so `valueOf`'s `.neg` arm (l.139-143) folds `-"s"` to `.null_`; `literal` (l.378) then writes `null` |
| **Why** | Deliberate and documented (l.213-215: "Anything the folder cannot reduce … yields `null` rather than a bogus `0`"). `comptime/error.zig` `validateComptimeExpr` (l.431-487) is the intended gate — it rejects calls (l.449), record literals and `case` (l.458), `loop` (the `else` at l.485) and out-of-scope identifiers (l.481) *before* the folder runs. Division by zero and a negated string pass validation because they are structurally legal |
| **Correct** | The folder distinguishes "not foldable" (already rejected upstream) from "evaluates to an error": a zero divisor and a non-numeric `.neg` operand raise a comptime error located at the expression |
| **Also worth fixing here** | `validateComptime` only visits top-level `val` declarations (`validateDecl` l.383-388 matches `.val` only), so a `comptime` expression inside a fn body is never validated |
| **Probe at HEAD** | `val q = comptime 1 / 0;` → `Checked` |
| **Acceptance** | `comptime 1 / 0` and `comptime -"s"` are comptime errors located at the expression, not `null` |

## C5 — a type-guard fn is typed as the narrowed type, not `bool`

| | |
|---|---|
| **Where** | `parser/decls.zig` l.349-357 — on `-> x is T` the parser sets `typeGuardParam = x` **and** `returnType = T`. `buildFnSignatureType` (l.709-712) and `inferFnDecl` (l.2731-2734) then use `T` as the call's type |
| **Why** | The parser had nowhere else to put `T`: `FnDecl` has `typeGuardParam: ?[]const u8` but no narrowed-type slot, so the type was parked in `returnType`. The narrowing consumer (`infer.zig` l.5822-5826) reads it back out of `env.typeGuardFns.narrowedTypeName`, which is filled from `f.returnType` at l.2860-2865 |
| **Correct** | `FnDecl` gains `typeGuardType: ?ast.TypeRef`; `returnType` becomes `bool`. `env.typeGuardFns` is filled from the new slot. The guard body is then checked against `bool` (which needs C1 to be observable) |
| **Consequence** | The narrowing at l.5808-5845 is unreachable today: the `if` condition path calls `unifyAt(bool, condType)` at l.5833 and the guard call's type is `T`, so the branch errors before the narrowed binding is used. C5 is the prerequisite for the two `type_guard_*` narrowing rows |
| **Probe at HEAD** | `fn isPositive(n: i32) -> n is i32 { return n > 0; } val b: bool = isPositive(5);` → `expected bool, got i32 at main:2:15` |
| **Acceptance** | `val b: bool = isPositive(5);` checks; `if (isStr(y)) { val s: string = y; }` checks with `y: ?string`; the guard body must return `bool` |

## C6 — the type builtins and the name-keyed type functions

| | |
|---|---|
| **Where** | `@field` returns the receiver's type (l.3858-3861); `@RecordKeys` builds a nominal `Array<string>` (l.3853-3855) that does not unify with the `array` the `string[]` annotation resolves to; `@makeRecord(ident)` is a fresh var because `tryEvalMakeRecord` (l.3966-4032) only walks a literal array; `tryResolveTypeManipulationCall` (l.4041) is called at l.6901 before user bindings **and before any receiver handling** |
| **Why** | These builtins were the 1.0.0-beta stopgap for "types as values" — they resolve a *type* because inference had no value domain to resolve into. [`types-as-values.md`](./types-as-values.md) step A5 deletes them |
| **Correct** | `@field(v, "x")` returns the field's type; `@RecordKeys(T)` returns the same `array` type an annotation produces; `@makeRecord` accepts a comptime-known binding; user bindings win over the name-keyed table |
| **The shadowing is not hypothetical** | `libs/std` does not compile at HEAD: `libs/std/src/random.bp` declares `pub fn pick<T>` and its own test calls it, which `tryResolveTypeManipulationCall` claims → `error: pick expects a type and field names at random:141:13`. A *method* is hijacked too: `record P { val x: i32, fn pick(self: Self) -> i32 { … } } val v = p.pick();` → `error: pick expects a type and field names`, because l.6901 runs before the receiver branch at l.6981 |
| **Probe at HEAD** | `val xv: string = @field(p, "x")` → `expected string, got P`; `val k: string[] = @RecordKeys(P)` → `expected array, got Array`; `fn pick(a: i32, b: i32) -> i32 {…} val v: i32 = pick(1, 2);` → `pick: first argument must be a type name` |
| **Acceptance** | a user fn **or method** named `pick`/`omit`/`partial`/`mergeRecords` resolves to the user's; `@field` returns the field type; `val k: string[] = @RecordKeys(P)` checks; `@makeRecord(fields)` with a comptime `val fields` builds the record. The builtin-specific rows drop if [`types-as-values.md`](./types-as-values.md) step A5 lands first; the shadowing fix is needed either way |
| **Cross-front** | [`03-std-surface`](../03-std-surface/README.md) also names this collision and cannot fix it without renaming a public std function. Decide before that front lands, or it renames `random.pick` and this front renames it back |

## C7 — generic arguments are lost on enum unit variants

| | |
|---|---|
| **Where** | `infer.zig` l.5228 — `const ty = try env.namedType(receiverName);` for a variant reached as `Enum.Variant`, with no generic args |
| **Why** | The path at l.5210-5243 only validates that the member names a variant; it returns the enum's bare nominal type. `env.zig` `resolveTypeName` l.904-913 solves the same problem correctly (allocate one fresh var per declared generic param) — this site was simply never taught it |
| **Correct** | l.5228 builds `Enum<fresh, …>` with one fresh var per declared generic param, exactly as `resolveTypeName` does — then `Option<i32>` unifies |
| **Chained defaults** | `record Sym<T, U = T>` accepting `Sym<i32>` with `right: "two"` is a **C1** observation, not a separate defect: the mismatch is on a `return` value and nothing unifies it. It becomes visible the moment C1 lands; verify it then rather than fixing it here |
| **Probe at HEAD** | `enum Option2<T> { Some(v: T), None } val n: Option2<i32> = Option2.None;` → `expected Option2, got Option2` |
| **Acceptance** | `val n: Option2<i32> = Option2.None;` checks; `generic_enum_option_t_unit_and_payload_variants` shows `Option<i32>` for `n` |

## C8 — pattern bindings are untyped

| | |
|---|---|
| **Where** | `infer.zig` `bindPatternNamesForSubject` l.4851-4894. Every arm binds `freshVar()`: variant `.binding` (l.4865), variant `.fields` (l.4869), variant `.literals` (l.4874, which also passes a *fresh* subject type down), list elements and spread (l.4881, l.4886), `.ident` (l.4861). `.@"or"` (l.4890) binds only the first alternative's names |
| **Why** | The function *receives* `subjectType` and uses it only for `isEnumVariantNameForSubject` (l.4860) — i.e. to tell a variant name from a binder. The variant payload table needed to type the bindings is already reachable (`env.lookupTypeDef`, used at l.4970 and l.5214), so this is an unfinished implementation, not a constraint |
| **Correct** | Resolve the subject's typedef, find the variant, and bind each payload field to its declared type, instantiated against the subject's generic args. `.literals` recurses with the payload field's type, not a fresh var. An OR pattern binds the *unification* of the same name across all alternatives (and reds when the alternatives disagree). A list pattern binds elements to the array's element type and the spread to the array type. A guard identifier (`x if (x > 0)`) is the subject type |
| **Probe at HEAD** | `enum E { A(v: i32), B } fn f(s: string) -> string {…} case e { A(v) -> f(v); B -> "b"; }` → `Checked` |
| **Acceptance** | `A(v) -> f(v)` reds; same for `Dog(b) \| Cat(b)`, `x if (x > 0) -> f(x)`, `Ok(v)`/`Err(e)` on `@Result`, `[first, ..rest]` |

## C9 — method bodies, unannotated methods, and unknown methods

| | |
|---|---|
| **Where** | `inferTypeMethods` l.2916-2967 — documented BEST-EFFORT: "a method whose body trips an inference gap is skipped". `registerInherentMethodTypes` l.1002-1006 — a method with no `returnType` gets **no stored signature** ("rather than mis-typing them as `void`"). `inferCallExpr` l.7105-7114 — after inherent / extension / std-array / Result-Option / template / primitive dispatch all miss, the call is typed `freshVar()`. Swallow site: l.2970-2975 (`_ = inferExpr(env, stmt.expr) catch { env.lastError = null; break; }`) |
| **Why** | All three are deliberate and all three are M4 or M1. The best-effort walk was added so a gap in one method body would not fail the module; the missing signature avoids a wrong `void`; the final fallback exists because struct getters and activated extensions are not resolved here |
| **Correct** | Method bodies join the strict contract that `default fn` interface bodies already have (`inferInterfaceDefaultBodies`). An unannotated method's return type comes from inferring its body once, then is stored. The l.7105-7114 fallback becomes `TypeError.unknownMethod` / `methodNotActive` when the receiver's type is known and nominal; it stays permissive only for a receiver whose type is still an unresolved type variable. Note the comment at l.7105 is stale — it cites "struct getters", and no fixture in the suite declares a `struct` at all; the live case is the `implement`-block symbol bound to `freshVar()` at l.754-755 |
| **Probe at HEAD** | `record D { val id: i32, fn bad(self: Self) -> string { val z: string = self.id; return z; } }` → `Checked` (a real mismatch inside a method body, silently swallowed). `val d = D(id: 1); val q = d.swim();` with no `swim` → `Checked` |
| **Acceptance** | a type error in a record method body reds; `val a: string = d.quack()` reds when `quack` returns `self.id`; calling an undefined method reds (`methodNotActive` / `unknownMethod`) |
| **Ordering** | After C1 and C8: many swallowed method-body errors are `return` and `case` shaped, so the count only means something once those two are strict |

## C10 — unknown type names are accepted

| | |
|---|---|
| **Where** | `env.zig` `resolveTypeName` l.930-931 (`// Fallback: treat as an opaque named type (forward reference, etc.)`) and l.916-928 (any value binding is accepted, with a documented carve-out at l.925-927 for an imported constructor naming its own type) |
| **Why** | The fallback is load-bearing for **forward references**: a record annotated with a type declared later in the file, and a type that lives in another module whose typedef was not registered. The bindings arm is load-bearing for imported records/structs/enums, where the import binds a constructor value but the typedef stays in the defining module |
| **Correct** | Two-pass resolution: register every typedef in the module (and every imported typedef) before annotations resolve, then the fallback becomes `TypeError.unknownTypeName` at the TypeRef. The bindings arm keeps only the constructor carve-out (l.925-927) and reds for a non-type binding |
| **Probe at HEAD** | `record Q { lat: bogusType }` → `Checked`. `val n = 5; val x: n = 7;` → `Checked` (while `val T = i32; val x: T = "s";` correctly reds) |
| **Acceptance** | an unknown type name reds at the TypeRef; a non-type binding in annotation position reds; forward references to records/enums declared later still check |
| **Overlap** | [`types-as-values.md`](./types-as-values.md) step A1 replaces the bindings arm with a real `type` kind. Do C10's two-pass registration here and let A1 delete the bindings arm — otherwise the same code is rewritten twice |

`Children` in `jhonstart/src/element.bp` looks undeclared to a library-scoped resolver but is
compiler-known (`infer.zig` l.3785 `childrenCoercion`) — whatever the two-pass registration is, it
must consult the same table. `libs/std` annotates `-> unit` in four `declare fn`s (`env.bp:30`,
`env.bp:35`, `process.bp:28`, `random.bp:28`); `unit` is not a primitive (`env.zig` l.855-868 lists
`void`, not `unit`) and is declared nowhere — it exists only because of this fallback. Rename to
`void` as part of C10. `RecordField` (6 positions in `types.bp`/`reflect.bp`) *is* declared, in
`comptime.zig` `type_info_src`, and survives C10.

## C11 — record update spread is positional

| | |
|---|---|
| **Where** | `infer.zig` l.7203-7213 — when `spreadCount != 1 or nonSpreadCount < 2` the call takes the "historical spread behavior" path: arity check against `f.params.len`, then `unifyAt(paramType, arg)` **by index**. Otherwise (l.7221-7232) the args are walked skipping the `..` label, still positionally. Labels never select a field |
| **Why** | The comment says it: "Keep the historical spread behavior (and snapshots) for narrow update/error cases" — the label-based path was never written, and the two branches exist to keep three error snapshots unchanged |
| **Correct** | A call carrying a `..` spread is a record **update**, not a constructor call: the spread's type must be the same record (or a compatible variant), each remaining arg is matched to the field its label names, an unknown label reds at the label, and a wrong value type reds at the value |
| **Probe at HEAD** | `record Person { name: string, age: i32 } val alice = Person(name: "a", age: 1); val b = Person(..alice, age: 25);` → `expected string, got Person at main:3:18` (it matched field 0) |
| **Acceptance** | `..alice, age: 25` checks; an unknown label → `unknown field` at the label; a wrong value type → caret at the value; spreading another variant reds with a variant message (`variant_mismatch`, `non_existent_field`, `field_type_mismatch` regenerated) |

## C12 — `val assert`, and pipelines

| | |
|---|---|
| **Where** | `infer.zig` l.7544-7563 — `assertPattern` catches `error.TypeError` from **both** the expression (l.7546-7550) and the handler (l.7553-7557), substituting a fresh-var `null` literal; the pattern `ap.pattern` is never checked against the expression's type. Pipeline: l.7293-7299 — an RHS that is not a call is typed as-is, so `1 \|> double` has the type of `double` (a function); l.7258-7267 — the arity check is `if (f.params.len == totalArgs)`, and a mismatch just skips unification |
| **Why** | The `catch` was added so an unbound identifier in an assert would not fail the module (it is a test-shaped form). The pipeline arity `if` guards against unifying a wrong number of params — it should report instead |
| **Correct** | `val assert P = e catch h` infers `e` strictly, checks `P` against `e`'s type (the same machinery C8 builds), and unifies `h` with the bound type. `lhs \|> f` where `f` is a 1-ary function is the call `f(lhs)` and has type `f`'s return. A pipeline arity mismatch is `TypeError.arityMismatch` at the RHS |
| **Probe at HEAD** | `val assert 42 = answer catch 0;` with `answer` unbound → `Checked`. `val r: i32 = 1 \|> double;` → `expected i32, got function`. `val r = 1 \|> add(1, 2);` for a 2-ary `add` → `Checked` |
| **Acceptance** | `val assert 42 = answer catch 0;` with `answer` unbound reds; `val r: i32 = 1 \|> double;` checks; `1 \|> add(1, 2)` for a 2-ary `add` reds |

## C13 — diagnostics: the effect code, and missing locations

| | |
|---|---|
| **Where** | `infer.zig` l.2789 — `const fnLoc: ?ast.Loc = if (f.body.len > 0) f.body[0].expr.getLoc() else null;` (the same line exists at l.2073). l.2796-2799 — the code is `effect_wrapper_mismatch` when the return type derefs to `.named`, else `effect_missing_wrapper`; every primitive return type is `.named`, so the second branch is unreachable. Unlocated errors: `unify.zig` l.37/54/58/66/76/85/97/102/109/119/127 (located only via `unifyAt`), the two bare `unify` calls at `infer.zig` l.5386 and l.5394, and 9 `TypeError.custom` sites — `infer.zig` l.72, 99, 191, 2161, 2200, 2637, 3951, 4640, 4701 — plus `unknownInterface` l.330, `unknownMethod` l.336/355, `ambiguousMethod` l.359, `missingMethod` l.385, `extendRequiresInterface` l.761, `redundantActivation` l.781, `notAnExtension` l.783 |
| **Why** | `fnLoc` predates the declaration having a usable span; the `.named` test was a proxy for "is a wrapper type" that never distinguished "wrong wrapper" from "no wrapper". The unlocated constructors are simply call sites that never got `.withLoc` |
| **Correct** | The effect check branches on whether the return type *is* one of the effect wrappers (`classifyAsyncReturn` already computes this at l.2788), not on its type-kind; the diagnostic is located at `f.returnType`'s span, and a bodyless `declare fn` gets the declaration's span. Every listed site gets a `.withLoc` |
| **Probe at HEAD** | `#[@result] fn f() -> i32 { return 1; }` → `effect-wrapper-mismatch … at main:1:28` (the body statement) |
| **Acceptance** | `#[@result] fn f() -> i32` reports `effect-missing-wrapper` at the return type; every error snapshot named in the review corpus' unlocated-error root cause has a `┌─` location |
| **Ordering** | Land with C3 — both rewrite `snapshots/comptime/*/errors/` and doing them separately regenerates 212 files twice |

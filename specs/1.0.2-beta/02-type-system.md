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

---

## Current state

Every row below was re-confirmed at HEAD by reading the code and by
`zig-out/bin/botopink check` on a scratch project. The probe output is quoted in each row.

**Closed by the 1.0.1-beta comptime-folding wave — do not re-open:**

- **C4** (`comptime val` folding): `comptime/eval.zig` folds by operand kind, `comptime { … }`
  has a scope in `comptime/error.zig` + `eval.zig`, and `comptime <RecordCtor>(…)` is rejected
  on purpose. Only one residual remains, tracked as **C4b** below.

**Unchanged since the milestone opened** — `comptime/infer.zig` and `comptime/env.zig` were
touched in 1.0.1-beta only by the parser wave (which removed `captureExprArg`'s mirror
compensation) and by the snapshot-trace wave. No checker row was fixed.

### The four mechanisms behind the Part 0 rows

Every row except C4b, C7, C10 and C11 is an instance of one of these. Fixing a mechanism once
is cheaper than fixing its instances, and the rows that share a mechanism share a snapshot
regeneration.

| # | Mechanism | Why it is written that way | Rows |
|---|---|---|---|
| M1 | **A fresh type variable is the escape hatch.** `env.freshVar()` unifies with anything, so any construct the checker cannot type yet is given one and nothing downstream ever contradicts it | Deliberate: a fresh var imposes no ordering constraint, so a construct can be typed before the information that would type it exists (a method body before its signature, a pattern binding before the subject's variant table is consulted). It also keeps a gap from failing the whole compile | C1, C2, C5, C8, C9, C12 |
| M2 | **`unifyAt` is target-first and several callers pass operand-first.** `unifyAt(env, a, b, loc)` (`infer.zig` l.3769-3777) documents `a` = the declared/expected type; `TypeError.typeMismatch(a, b)` renders "expected `a`, got `b`" | A local slip, not a decision — the `if` condition at l.5833 and `assert` at l.7535 get it right (`unifyAt(bool, cond)`), the boolean operators and `!` do not | C3, C13 |
| M3 | **One-way optional subsumption is reached from the wrong side.** `unify.zig` l.48-52 lets an *expected* `?T` accept a plain `T`. Arithmetic calls `unify(env, lhsTy, rhsTy)` with the operand as `a`, so an operand of type `?i32` silently subsumes the other operand | The subsumption itself is correct and load-bearing (`val x: ?i32 = 5`). It leaks only because arithmetic passes an operand where the function expects a declared type. Probe: `fn f(x: ?i32) -> i32 { return x + 1; }` checks | C3, and every "narrowing is not needed" false negative in Part B |
| M4 | **Best-effort walks swallow errors.** `inferTypeMethods` (l.2916-2967) explicitly documents that a method body tripping an inference gap is skipped so the gap does not fail the compile | Deliberate, and currently load-bearing: it exists because the bodies *do* trip gaps. Removing it without first fixing the gaps reds every library with a record method | C9 |

`unify` itself never carries a location (`comptime/unify.zig` l.37, 54, 58, 66, 76, 85, 97,
102, 109, 119, 127 all build the error with no `loc`). A location appears only when the caller
went through `unifyAt`; the two arithmetic call sites (`infer.zig` l.5386, l.5394) do not.

### Existing machinery

- **Inference builtins** (`infer.zig` `inferBuiltinCallReturnType`, l.3797, called at l.6889):
  `@typeInfo(T)` → the `TypeInfo` type (l.3838), `@TypeOf(v)` → the argument's type (l.3843),
  `@makeRecord(fields)` → fresh var (l.3849; a literal `RecordField` array is resolved earlier
  by `tryEvalMakeRecord`, l.3966 / call site l.6885), `@RecordKeys(T)` → `Array<string>`
  (l.3854), `@field(v, name)` → the type of `v` (l.3859), `@comptimeError(msg)` → custom
  error. They resolve **types** during inference; they compute no values. The value domain
  (`TypeInfo`, `RecordField`, `EnumVariant`, `TypeInfoKind`) is declared in `comptime.zig`
  `type_info_src`; `TypeInfo` is an **enum with payload variants**
  (`Record(fields: RecordField[])`, `Optional(inner: string)`, …).
- **Type functions by name** (`infer.zig` `tryResolveTypeManipulationCall`, l.4041, called at
  l.6901 for every non-builtin call *before* user bindings **and before the receiver check**):
  `mergeRecords`, `partial`, `omit`, `pick` are resolved in Zig; `mapFields` is matched and
  returns `null` (l.4071-4072, not implemented).
- **`.bp` type functions**: `libs/std/src/types.bp` (`mapFields`/`partial`/`omit`/`pick`) and
  `libs/std/src/reflect.bp` (`mergeRecords`) are absent from `libs/std/src/root.bp`, so they
  are never loaded — `botopink check` in `libs/std` prints `module not reached by any mod path`
  for both (and for `primitives.bp`). Neither compiles: see **Part A, current state**.
- **Types as values**: any value binding is accepted as an annotation through the `env.zig`
  `resolveTypeName` bindings fallback (l.916-928: `val T = i32; val x: T = "s"` reds, but
  `val n = 5; val x: n = 7` also checks); an unknown name becomes an opaque named type
  (l.930-931). `comptime T: type` parameters do not constrain other parameters. A call in
  annotation position (`val z: mk() = …`) does not parse.
- **Type guards**: `-> x is T` parses (`parser/decls.zig` l.349-357 → `FnDecl.typeGuardParam`)
  and registers `env.typeGuardFns` (`infer.zig` l.539, l.2865); the then-branch narrowing is
  at `infer.zig` l.5808-5845.
- **Snapshot limits** (they shape every acceptance below). Two different functions produce a
  `?` in a typed-AST snapshot and they mean opposite things:
  - `typeNameFromTypeRef` (`comptime/snapshot.zig` l.239-244) renders an **annotation** and is
    purely syntactic — only `.named` survives, so `?i32`, `T[]`, `#(A,B)`, `fn(A) -> B`,
    `Option<T>`, a typeparam and an anonymous record are all `?`. It never consults inference,
    so **it does not move when the checker becomes strict**. 52 of the 78 `?`s in
    `snapshots/comptime/node` come from here (28 fn return types, 22 fn params, 2 record
    fields).
  - `typeNameOf` (`comptime/snapshot.zig` l.477) renders an **inferred** type and prints `?`
    for a `.typeVar` — that is the checker admitting it does not know. The other **26 `?`s,
    spread over 17 slugs** in each comptime backend dir, come from here (12 in `case` arms,
    7 under a `val`, 7 under a `call`). 51 files per dir contain a `?` of either kind; only
    those 17 (68 files across the four dirs) are the visible blast radius of M1 — do not
    `grep '"?"'` to size a row.
  - A fn body is shown as raw source lines (`extractFnBody`, l.246-257). So a checker fix is
    asserted with annotated top-level `val`s plus an error snapshot.

### Suite size (the regeneration cost of any row below)

733 `test` declarations (437 comptime + 296 codegen), 726 of them carrying inline `.bp` source.

| Artefact | Count | Moved by |
|---|---|---|
| `assertInfersOk` fixtures (no snapshot — "it compiles") | 76 | C1, C2, C8, C9, C10 — these are where a fix turns a vacuous test into a real one, or into a red |
| `assertTypeErrorSnap` fixtures (error snapshots, 2 copies each under `snapshots/comptime/{node,erlang}/errors/`) | 107 tests / 106 slugs × 2 dirs = 212 files | C3, C13 (message text and `┌─` boxes) |
| `assertComptimeAst*` typed-AST snapshots (4 byte-identical copies per slug: `node`, `erlang`, `wasm`, `beam`) | 199 slugs / 796 files | C2, C5, C6, C7, C8, C11 |
| …of which carry a `typeNameOf` `.typeVar` `?` | **17 slugs / 68 files** | the tripwire set — 10× `case_*`, 4× extension/method dispatch, 3× `@makeRecord` |
| `assertComptimeCompileError` documented skips | 9 | the parser gaps below |
| codegen snapshots | 279 commonJS / 279 erlang / 278 beam / 278 wasm | only a fixture that **newly fails to compile** (all-or-nothing); codegen snapshots carry no type rendering |
| parser snapshots | 215 | the parser gaps below |

### Library baseline (what a checker row can and cannot be measured against)

`zig-out/bin/botopink check` at HEAD, per checked-out library:

| Library | `.bp` | Today | Owner of the red |
|---|---|---|---|
| `libs/std` | 30 files / 4823 lines | **red** — `error: pick expects a type and field names at random:141:13` | **C6** (and spec 08 step 6) |
| erika | 3 / 1031 | **red** — `the template module did not compile` | spec 01 (wave 0, comptime dispatch) |
| rakun | 15 / 1064 | **red** — `a declared dependency was not found under the libs root` | spec 08 step 7 |
| jhonstart | 16 / 894 | green | — |
| onze | 5 / 444 | green | — |
| emilia | 4 / 803 | green | — |

Consequence for every **library**-class row below: the measurement pass can only *compile*
jhonstart, onze and emilia today. `libs/std`, erika and rakun contribute nothing to a compile
count until C6 and wave 0 land — so C6 first, then re-measure.

### Library exposure, counted by construct

Counted over library `src/` only (tests and examples excluded), by reading every `.bp` file.
This is what decides each row's class; three rows turn out to cost **nothing**.

| Construct (row) | std | erika | jhonstart | onze | rakun | emilia | total |
|---|---|---|---|---|---|---|---|
| fns with `-> T` and ≥1 `return e;` (**C1** denominator) | 122 | 45 | 11 | 10 | 6 | 30 | **224 fns / 245 returns** |
| …of those, would plausibly red (**C1**) | 9 | 1 | 5 | 0 | 0 | 29 | **44** |
| `case` arms binding a payload **and using** the binding (**C8**) | 0 | 0 | 0 | 0 | 0 | 35 | **35** |
| `case` as a value / with genuinely different arm types (**C2a**) | 4 / 0 | 0 | 0 | 0 | 0 | 28 / 0 | **32 / 0** |
| record-update spread `Name(..x, f: v)` (**C11**) | 0 | 0 | 0 | 0 | 0 | 0 | **0** |
| calls to a method the receiver does not declare (**C9**) | 0 | 0 | 0 | 0 | 0 | 0 | **0** |
| record/enum method bodies currently best-effort (**C9**) | 31 | 39 | 0 | 2 | 7 | 0 | **79** |
| annotations naming an undeclared type (**C10**) | 9 | 0 | 1 | 0 | 0 | 28 | **38** |
| generic enum unit variant at a concrete instantiation (**C7**) | 0 | 0 | 0 | 0 | 0 | 0 | **0** |
| `\|>` pipelines of any shape (**C12**) | 0 | 0 | 0 | 0 | 0 | 0 | **0** |

**C7, C11 and C12's pipeline half cost zero library migration.** There is no `..` spread, no
`|>`, and no `Option`-shaped generic enum in any `.bp` file in the repository (the three
generic enums — `Result<R,E>`, `IteratorStep<T,E,C>`, `Yield<T,R>` in
`libs/std/src/builtins.d.bp`) carry payloads on every variant. `C2a` breaks **zero** libraries
too: all 32 `case`-as-value blocks are type-homogeneous, so arm unification only newly
type-checks them.

**emilia carries 92 of the ~117 affected sites on 680 lines** (29 C1 + 35 C8 + 28 C10), all
funnelling through one design decision: `tokens.bp` declares a single `pub enum Token` with
nested sections, and `emilia.bp` annotates 27 presumed compiler-synthesized section names
(`TokenText`, `TokenPadX`, `TokenBorderColor`, …) that are declared nowhere, binds their
payloads in `case` arms, and returns the result through `return out;`. **C1, C2a, C8 and C10
must land in one wave or emilia does not compile at any intermediate point** — this is the
single hardest scheduling constraint in Part 0.

Two shapes deserve a decision before any of that starts:

| Shape | Sites | Why it is not simply "wrong code" |
|---|---|---|
| **Effect-wrapper unwrap**: a fn declared `-> @Result<D,E>` / `-> @Future<T>` / `-> @Context<B,X>` whose body returns the **bare inner value** | 9 — `libs/std/src/primitives.bp:517`, `libs/std/src/http.bp:71`, `jhonstart/src/hooks.bp:29,37,43,49,57`, `emilia/src/emilia.bp:57` | This *is* the auto-wrap contract: `infer.zig` l.5531-5547 records `wrap_ok` and l.5554-5561 `wrap_resolved` precisely because the author writes the bare value. C1's unification target inside an effect body is therefore the wrapper's **inner** channel, never the wrapper. `@Context` has no such lowering today and `jhonstart/src/hooks.bp` is five of the nine sites — extend the rule to `@Context<B, X>` → `X` or hooks dies wholesale |
| **`return <ident>` where the ident came from a `case`** | 31 — 28 in `emilia/src/emilia.bp`, plus `libs/std/src/order.bp:30` and `unicode.bp:88` | Today those idents are fresh vars (C2a), so C1 alone cannot check them and C2a alone has nothing to check them against. They are the concrete reason C1 and C2a are one landing group |

One more fixture-free finding: `libs/std` annotates `-> unit` in four `declare fn`s
(`env.bp:30`, `env.bp:35`, `process.bp:28`, `random.bp:28`). `unit` is not a primitive
(`env.zig` l.855-868 lists `void`, not `unit`) and is not declared anywhere — it exists only
because of the C10 fallback. Rename to `void` as part of C10. `RecordField` (6 positions in
`types.bp`/`reflect.bp`) *is* declared, in `comptime.zig` `type_info_src`, and survives C10.

### The tripwire set

The 17 slugs (identical names in all four comptime dirs) are where the checker
visibly punts today: `case_arms_with_different_types_string_i32_union`,
`case_union_return_type_from_mismatched_arms`,
`case_with_variant_field_bindings_body_does_not_use_bound_vars` (+7 more `case_*`);
`inherent_record_method_is_always_available`,
`local_extension_method_resolves_without_activation`,
`multi_module_extension_activated_via_star_import`,
`qualified_extension_call_needs_no_activation`;
`single_field_returns_record_type`, `multiple_fields_returns_record_type` (+1 `@makeRecord`).
Items C2, C6, C8 and C9 all collapse onto this same set — regenerating those 68 files covers
the majority of the observable churn.

---

## Part 0 — Checker correctness

### Row index

**Blast-radius classes** used below:

| Class | Meaning |
|---|---|
| **none** | no fixture or library changes; only new tests |
| **few** | under ~20 snapshot files move, all mechanical regeneration |
| **many** | a whole snapshot family regenerates (≥ 100 files), review needed |
| **library** | `libs/std` or a sibling library stops compiling — needs a migration plan before the fix lands |
| **unblocks** | a library or fixture that is red *today* goes green |

| Row | Site | Mechanism (one line) | Blast radius |
|---|---|---|---|
| C1 | `infer.zig` l.2868-2871, l.5526-5563 | M1 — the body is walked for effect only and `.@"return"` is typed `void` without unifying its value against the declared return type | **library** + **many** |
| C2 | `infer.zig` l.7470 (`case`), l.7524-7529 (`comptime {}`) | M1 — `case` gets a fresh var and its arms are never unified; a `comptime` block is typed from its last *statement*, so a `break`-carrying block is `void` | **many** (case) + **none** (comptime block) — no library breaks, but it is C1's prerequisite |
| C3 | `infer.zig` l.5374-5375, l.5382-5395, l.5413, l.5417; `unify.zig` l.48-52 | M2 + M3 — boolean operands unify operand-first, `+` short-circuits to `string`, arithmetic calls bare `unify` (no location, and optional subsumption leaks), `.neg` applies no constraint | **many** (error snapshots) + possible **library** (the arithmetic constraints) |
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

### C1 — `return` is never unified with the declared return type

| | |
|---|---|
| **Where** | `infer.zig` l.2868-2871 (`// Infer body (for type checking; we ignore the result for now).`) and the `.@"return"` arm l.5526-5563, which builds `valPtr` and then types the jump `void` (l.5563) without unifying `valPtr` with `retType` (computed at l.2731-2734) |
| **Why** | `retType` is in scope, so this is not an ordering problem — the body walk was written to record lowerings (`result_jump_lowerings` l.5542-5545, `future_jump_lowerings` l.5560) and the unify step was never added. The `#[@result]` / `#[@future]` arms *do* inspect the returned value's type (l.5536, l.5556), so the plumbing exists |
| **Correct** | `env` carries the current fn's return type (like `env.starFn` / `env.throwContext` already do, saved/restored at l.2822-2827); `.@"return"` unifies `unifyAt(retType, value, valueLoc)`. A bare `return;` unifies against `void`. **The target inside an effect body is the wrapper's inner channel, not the wrapper**: `#[@result]` → the `R` of `@Result<R, E>`, `#[@future]` → the `T` of `@Future<T, E>`, `#[@generator]` → the `R` channel, `#[@context]` → the `X` of `@Context<B, X>`; `#[@iterator]` already forbids `return <expr>` (l.5491-5501). That is not a concession — it is the auto-wrap contract the lowering already records (`wrap_ok` l.5544, `wrap_resolved` l.5560), and it is 9 of the 44 library sites, 5 of them `@Context` in `jhonstart/src/hooks.bp`. A lambda with no declared return type unifies its `return`s with each other |
| **Probe at HEAD** | `fn f() -> i32 { return "s"; }` → `Checked`. `record Sym<T, U = T> { left: T, right: U } fn pair() -> Sym<i32> { return Sym(left: 1, right: "two"); }` → `Checked` (this is why C7's chained-default claim is unobservable today) |
| **Acceptance** | `fn f() -> i32 { return "s"; }` reds at the value with a caret; `#[@generator]` `return 42` against `R = string` reds; `val f = fn(x: i32) -> i32 { return "s"; };` reds |
| **Blast radius** | **library** + **many**. The single highest-risk row. **301** of the 726 source-carrying fixtures pair a declared `-> T` with a non-trivial `return` (380 such returns: 107 bare identifier, 77 other, 74 binop, 63 call/ctor, 25 `return case`, 21 trivially-matching literal, 4 `return if`). **15** fixtures pin a type *only* through `return v` and assert nothing today — `infer_generics.zig` (6), `effects.zig` + `effect_result.zig` (6), `infer_decls.zig` (2); `generic_defaults.zig` is the same shape (`fn pair() -> Sym<i32> { return Sym(left: 1, right: 2); }`). Library code has never been checked on this axis at all |
| **Library exposure** | 224 fns / 245 `return` statements have a declared type; **44** would plausibly red, in four shapes: 9 effect-wrapper unwraps (covered by the rule above, so 0 after it), **31 `return <ident>` where the ident came from a `case`** (unfixable without C2a — 28 of them in `emilia/src/emilia.bp`, plus `libs/std/src/order.bp:30` and `unicode.bp:88`), 3 returns into an unconstrained method generic (`libs/std/src/primitives.bp:711,737,761` in `default fn flatten/flat/fill<E>`) and 1 `return if (…) {…} else {…}` into a scalar (`libs/std/src/path.bp:84`, whose arms are also not unified today) |
| **Migration** | The 301 fixtures are an upper bound, not a work estimate — most unify on the first try. Pre-audit the two risky sub-populations: the **25 `return case`** fixtures and the **107 bare-identifier returns** (where a fresh var from elsewhere is doing the work). Land C1 behind a walk that *reports* instead of failing, triage, then flip to hard errors. C1 and C2a must be in the same wave (31 of the 44 library sites need both); C8 must be a separate commit within it, or the triage becomes unreadable |

### C2 — `case` is a fresh variable; a `comptime` block is typed from its last statement

Two independent defects; they may land separately.

| | |
|---|---|
| **Where (a)** | `infer.zig` l.7470 — the `case` node is built with `.type_ = try env.freshVar()`. Arms are inferred (l.7452) and restored (l.7456) but never unified with each other. Exhaustiveness *is* checked (l.7467-7469) |
| **Where (b)** | `infer.zig` l.7524-7529 — `comptimeBlock` takes the type of the last typed statement; a `break 1;` statement is a `.jump`, typed `void` at l.5563 |
| **Why** | (a) A fresh var avoids deciding the mismatched-arm policy (union vs error) — the decision is still open, see Open questions. (b) The 1.0.1 folding wave made `eval.zig` `blockValue` (l.303-317) evaluate the block's `break` value, but inference was not taught the same rule |
| **Correct** | (a) The `case` type is the unification of the arm types; an arm that is a `.jump` (`return`/`break`/`continue`) contributes nothing. (b) A `comptime` block's type is the type of its `break` value (`blockResult`'s rule), `void` when there is none |
| **Probe at HEAD** | `val a: bool = case 42 { 0 -> "a"; _ -> "b"; };` → `Checked`. `val h = comptime { break 1; }; val z: i32 = h;` → `type mismatch: expected i32, got void at main:2:14` |
| **Acceptance** | `val a: bool = case 42 { … };` reds; the mismatched-arm policy is pinned in `case_arms_*union*`; `val h = comptime { break 1; }; val z: i32 = h;` checks |
| **Blast radius** | (a) **many**, and — unexpectedly — **zero library breakage**: all 32 `case`-as-value blocks in the libraries are type-homogeneous, so arm unification only newly type-checks them (8 emilia blocks mix a string literal, a call and a concat, but all three are `string`). In the suite, 45 fixtures use `case` as a value (24 of them `return case`), **none** binds it to an *annotated* `val`, and 10 of the 17 tripwire slugs are `case_*` — including two whose names already promise the union policy (`case_arms_with_different_types_string_i32_union`, `case_union_return_type_from_mismatched_arms`); read those two before deciding. (b) **none** — no fixture at HEAD binds a `comptime` block to an annotated `val`, which is exactly why the defect survived |
| **Ordering** | (a) is the same value flow as C1: both decide "what type does this position produce", and 31 of C1's 44 library sites are `return <ident>` where the ident came from a `case` — C1 cannot check them and C2a has nothing to check them against. One branch, C1 first |

### C3 — Operand orientation, arithmetic constraints, and the subsumption leak

| | |
|---|---|
| **Where** | `infer.zig` l.5374-5375 (`.@"and"`/`.@"or"`) and l.5413 (`.not`) call `unifyAt(operand, bool, loc)` — operand-first, against the contract at l.3769-3771. `.add` short-circuits to `string` when *either* side is a string (l.5382) and otherwise calls bare `unify(env, lhsTy, rhsTy)` (l.5386); `.sub`/`.mul`/`.div`/`.mod` the same (l.5394). `.neg` (l.5417) applies no constraint at all. `yield` (l.5777) is swapped the same way |
| **Why** | A slip, not a decision: `if` conditions (l.5833) and `assert` (l.7535) call the same helper correctly. The `.add` string short-circuit is intentional (string coercion) but it fires on `1 + "a"` too |
| **Correct** | `unifyAt(bool, operand, operandLoc)` for `&&`/`\|\|`/`!`/`yield`, located at the *operand*, not the whole expression. Arithmetic constrains both operands to a numeric interface and reports at the offending operand; `.neg` constrains to numeric; `+` keeps the string coercion only when both sides are string-compatible |
| **The leak** | Because arithmetic passes an operand as `unify`'s `a`, `unify.zig` l.48-52 (expected `?T` accepts a plain `T`) fires in the operand direction. `fn f(x: ?i32) -> i32 { return x + 1; }` checks at HEAD and the result type is `?i32`. Every Part B "why does this compile without narrowing" question resolves here |
| **Probe at HEAD** | `val q: bool = (1 && true);` → `expected i32, got bool at main:1:18` (reversed). `val q = "a" * "b";` → `Checked`. `val q = -"s";` → `Checked` |
| **Acceptance** | `1 && true` → `expected: bool, found: i32` with a caret on `1`; `"a" * "b"` and `-"s"` red with a location; `fn f(x: ?i32) -> i32 { return x + 1; }` reds |
| **Blast radius** | **many** on the error snapshots (the 212 files under `snapshots/comptime/*/errors/` — any fixture whose message names a boolean or arithmetic mismatch flips its expected/found). Possible **library** from the arithmetic constraints: string/number `+` mixing is common in `libs/std` and in erika/jhonstart string building. Regenerate together with C13 — both rewrite the same family |

### C4b — an irreducible comptime fold yields `null`

| | |
|---|---|
| **Where** | `comptime/eval.zig` `binary` l.249-250 and l.260-261 return `.null_` for a zero divisor; `numeric` (l.266-272) returns null for a string operand so `valueOf`'s `.neg` arm (l.139-143) folds `-"s"` to `.null_`; `literal` (l.378) then writes `null` |
| **Why** | Deliberate and documented (l.213-215: "Anything the folder cannot reduce … yields `null` rather than a bogus `0`"). `comptime/error.zig` `validateComptimeExpr` (l.431-487) is the intended gate — it rejects calls (l.449), record literals and `case` (l.458), `loop` (the `else` at l.485) and out-of-scope identifiers (l.481) *before* the folder runs. Division by zero and a negated string pass validation because they are structurally legal |
| **Correct** | The folder distinguishes "not foldable" (already rejected upstream) from "evaluates to an error": a zero divisor and a non-numeric `.neg` operand raise a comptime error located at the expression |
| **Also worth fixing here** | `validateComptime` only visits top-level `val` declarations (`validateDecl` l.383-388 matches `.val` only), so a `comptime` expression inside a fn body is never validated |
| **Probe at HEAD** | `val q = comptime 1 / 0;` → `Checked` |
| **Acceptance** | `comptime 1 / 0` and `comptime -"s"` are comptime errors located at the expression, not `null` |
| **Blast radius** | **none**. Touches `comptime/eval.zig` + `comptime/error.zig` only; can run beside every other row |

### C5 — a type-guard fn is typed as the narrowed type, not `bool`

| | |
|---|---|
| **Where** | `parser/decls.zig` l.349-357 — on `-> x is T` the parser sets `typeGuardParam = x` **and** `returnType = T`. `buildFnSignatureType` (l.709-712) and `inferFnDecl` (l.2731-2734) then use `T` as the call's type |
| **Why** | The parser had nowhere else to put `T`: `FnDecl` has `typeGuardParam: ?[]const u8` but no narrowed-type slot, so the type was parked in `returnType`. The narrowing consumer (`infer.zig` l.5822-5826) reads it back out of `env.typeGuardFns.narrowedTypeName`, which is filled from `f.returnType` at l.2860-2865 |
| **Correct** | `FnDecl` gains `typeGuardType: ?ast.TypeRef`; `returnType` becomes `bool`. `env.typeGuardFns` is filled from the new slot. The guard body is then checked against `bool` (which needs C1 to be observable) |
| **Consequence** | The narrowing at l.5808-5845 is unreachable today: the `if` condition path calls `unifyAt(bool, condType)` at l.5833 and the guard call's type is `T`, so the branch errors before the narrowed binding is used. C5 is the prerequisite for the two `type_guard_*` Part B rows |
| **Probe at HEAD** | `fn isPositive(n: i32) -> n is i32 { return n > 0; } val b: bool = isPositive(5);` → `expected bool, got i32 at main:2:15` |
| **Acceptance** | `val b: bool = isPositive(5);` checks; `if (isStr(y)) { val s: string = y; }` checks with `y: ?string`; the guard body must return `bool` |
| **Blast radius** | **few** + **unblocks**. `narrow_type_guard_basic_codegen` and `narrow_type_guard_if_codegen` exist in all four backend snapshot dirs; the JS lowering already emits a plain `return true`, so the emitted text should not move — only the typed-AST snapshots. Check that no backend keys on the guard fn's return type being `T` |

### C6 — the type builtins and the name-keyed type functions

| | |
|---|---|
| **Where** | `@field` returns the receiver's type (l.3858-3861); `@RecordKeys` builds a nominal `Array<string>` (l.3853-3855) that does not unify with the `array` the `string[]` annotation resolves to; `@makeRecord(ident)` is a fresh var because `tryEvalMakeRecord` (l.3966-4032) only walks a literal array; `tryResolveTypeManipulationCall` (l.4041) is called at l.6901 before user bindings **and before any receiver handling** |
| **Why** | These builtins were the 1.0.0-beta stopgap for "types as values" — they resolve a *type* because inference had no value domain to resolve into. Part A step 5 deletes them |
| **Correct** | `@field(v, "x")` returns the field's type; `@RecordKeys(T)` returns the same `array` type an annotation produces; `@makeRecord` accepts a comptime-known binding; user bindings win over the name-keyed table |
| **The shadowing is not hypothetical** | `libs/std` does not compile at HEAD: `libs/std/src/random.bp` declares `pub fn pick<T>` and its own test calls it, which `tryResolveTypeManipulationCall` claims → `error: pick expects a type and field names at random:141:13`. A *method* is hijacked too: `record P { val x: i32, fn pick(self: Self) -> i32 { … } } val v = p.pick();` → `error: pick expects a type and field names`, because l.6901 runs before the receiver branch at l.6981 |
| **Probe at HEAD** | `val xv: string = @field(p, "x")` → `expected string, got P`; `val k: string[] = @RecordKeys(P)` → `expected array, got Array`; `fn pick(a: i32, b: i32) -> i32 {…} val v: i32 = pick(1, 2);` → `pick: first argument must be a type name` |
| **Acceptance** | a user fn **or method** named `pick`/`omit`/`partial`/`mergeRecords` resolves to the user's; `@field` returns the field type; `val k: string[] = @RecordKeys(P)` checks; `@makeRecord(fields)` with a comptime `val fields` builds the record. The builtin-specific rows drop if Part A step 5 lands first; the shadowing fix is needed either way |
| **Blast radius** | **few** + **unblocks**. `comptime/tests/builtins_typeinfo.zig` (31 tests) is the only fixture family that pins these: 27 `assertComptimeAstSingle` (typed-AST snapshots under `snapshots/comptime/{node,erlang}/`) and 4 `assertTypeErrorSnap` (`comptimeError: string literal raises custom error`, `mergeRecords: conflict raises error`, `omit: non-existent field raises error`, `pick: field email not found raises type error`). The file's header says it verifies resolution "during inference" and defers full comptime evaluation — that is exactly the layer Part A replaces. 3 of its slugs already render a `typeNameOf` `?`, i.e. `@makeRecord` produces an unresolved var rather than a record type. 30 fixtures across the suite use any of these builtins or names. The shadowing fix makes `libs/std` compile |
| **Cross-spec** | Spec 08 step 6 (wave 0, `libs/std/**`) also names this collision. Wave 0 cannot fix it without renaming a public std function — the durable fix is here (C6) or in Part A step 5. Decide before wave 0 lands, or wave 0 renames `random.pick` and wave 2 renames it back |

### C7 — generic arguments are lost on enum unit variants

| | |
|---|---|
| **Where** | `infer.zig` l.5228 — `const ty = try env.namedType(receiverName);` for a variant reached as `Enum.Variant`, with no generic args |
| **Why** | The path at l.5210-5243 only validates that the member names a variant; it returns the enum's bare nominal type. `env.zig` `resolveTypeName` l.904-913 solves the same problem correctly (allocate one fresh var per declared generic param) — this site was simply never taught it |
| **Correct** | l.5228 builds `Enum<fresh, …>` with one fresh var per declared generic param, exactly as `resolveTypeName` does — then `Option<i32>` unifies |
| **Chained defaults** | `record Sym<T, U = T>` accepting `Sym<i32>` with `right: "two"` is a **C1** observation, not a separate defect: the mismatch is on a `return` value and nothing unifies it. It becomes visible the moment C1 lands; verify it then rather than fixing it here |
| **Probe at HEAD** | `enum Option2<T> { Some(v: T), None } val n: Option2<i32> = Option2.None;` → `expected Option2, got Option2` |
| **Acceptance** | `val n: Option2<i32> = Option2.None;` checks; `generic_enum_option_t_unit_and_payload_variants` shows `Option<i32>` for `n` |
| **Blast radius** | **few** — **2** fixtures (`infer: generic enum Option<T> ---- unit and payload variants`, where `val n = Option.None;` pins no `T` at all, and `variant inference: pattern matching on generic enum`, where a bare `None` is returned into `-> Option<i32>`); 6 fixtures declare a generic enum at all. Neither shows a `?` today, so this row is invisible in the tripwire set — regenerate the two slugs deliberately. **Zero library sites**: the only three generic enums in the ecosystem (`Result<R,E>`, `IteratorStep<T,E,C>`, `Yield<T,R>`, all in `libs/std/src/builtins.d.bp`) carry a payload on every variant, and no `Option` enum exists — optionality is the `?T` / `null` sugar. No codegen change: variant lowering is name-keyed, not type-keyed |

### C8 — pattern bindings are untyped

| | |
|---|---|
| **Where** | `infer.zig` `bindPatternNamesForSubject` l.4851-4894. Every arm binds `freshVar()`: variant `.binding` (l.4865), variant `.fields` (l.4869), variant `.literals` (l.4874, which also passes a *fresh* subject type down), list elements and spread (l.4881, l.4886), `.ident` (l.4861). `.@"or"` (l.4890) binds only the first alternative's names |
| **Why** | The function *receives* `subjectType` and uses it only for `isEnumVariantNameForSubject` (l.4860) — i.e. to tell a variant name from a binder. The variant payload table needed to type the bindings is already reachable (`env.lookupTypeDef`, used at l.4970 and l.5214), so this is an unfinished implementation, not a constraint |
| **Correct** | Resolve the subject's typedef, find the variant, and bind each payload field to its declared type, instantiated against the subject's generic args. `.literals` recurses with the payload field's type, not a fresh var. An OR pattern binds the *unification* of the same name across all alternatives (and reds when the alternatives disagree). A list pattern binds elements to the array's element type and the spread to the array type. A guard identifier (`x if (x > 0)`) is the subject type |
| **Probe at HEAD** | `enum E { A(v: i32), B } fn f(s: string) -> string {…} case e { A(v) -> f(v); B -> "b"; }` → `Checked` |
| **Acceptance** | `A(v) -> f(v)` reds; same for `Dog(b) \| Cat(b)`, `x if (x > 0) -> f(x)`, `Ok(v)`/`Err(e)` on `@Result`, `[first, ..rest]` |
| **Blast radius** | **library** + **many**, but concentrated: **emilia is the only library that binds a payload and uses it** — 35 sites of 44 binding arms in `emilia/src/emilia.bp` (20 pass-to-fn, 12 pass-to-fn *and* string-concat, 3 pure concat), all on the nested-section `Token` enum. No `Ok(v)`/`Some(x)`, **no OR alternation, no `x if (…)` guard and no `[first, ..rest]` pattern exists in any library** — those three sub-cases are fixture-only work. In the suite, **36** fixtures bind and use a pattern name (20 guards, 16 ctor payloads, 5 OR, 3 list), concentrated in `comptime/tests/narrowing.zig` (9), `variants.zig` (7), `codegen/tests/control_flow.zig` (6), `codegen/tests/narrowing.zig` (4). Second-highest-risk row after C1, and what makes half of Part B assertable |
| **Migration** | Same shape as C1: a reporting pass over the libraries first. Land after C1 (a payload binding is often fed to a `return`, so C1 alone already surfaces some of these) but in its own commit |

### C9 — method bodies, unannotated methods, and unknown methods

| | |
|---|---|
| **Where** | `inferTypeMethods` l.2916-2967 — documented BEST-EFFORT: "a method whose body trips an inference gap is skipped". `registerInherentMethodTypes` l.1002-1006 — a method with no `returnType` gets **no stored signature** ("rather than mis-typing them as `void`"). `inferCallExpr` l.7105-7114 — after inherent / extension / std-array / Result-Option / template / primitive dispatch all miss, the call is typed `freshVar()` |
| **Why** | All three are deliberate and all three are M4 or M1. The best-effort walk was added so a gap in one method body would not fail the module; the missing signature avoids a wrong `void`; the final fallback exists because struct getters and activated extensions are not resolved here |
| **Correct** | Method bodies join the strict contract that `default fn` interface bodies already have (`inferInterfaceDefaultBodies`). An unannotated method's return type comes from inferring its body once, then is stored. The l.7105-7114 fallback becomes `TypeError.unknownMethod` / `methodNotActive` when the receiver's type is known and nominal; it stays permissive only for a receiver whose type is still an unresolved type variable. Note the comment at l.7105 is stale — it cites "struct getters", and no fixture in the suite declares a `struct` at all; the live case is the `implement`-block symbol bound to `freshVar()` at l.754-755 |
| **Probe at HEAD** | `record D { val id: i32, fn bad(self: Self) -> string { val z: string = self.id; return z; } }` → `Checked` (a real mismatch inside a method body, silently swallowed). `val d = D(id: 1); val q = d.swim();` with no `swim` → `Checked` |
| **Acceptance** | a type error in a record method body reds; `val a: string = d.quack()` reds when `quack` returns `self.id`; calling an undefined method reds (`methodNotActive` / `unknownMethod`) |
| **Library exposure** | **Unknown-method calls: 0** — every `.m(` in every library resolves to a declared fn, a primitive-interface method, a builtin (`?T` / `@Result` dispatch: 73 `unwrapOr`, 8 `isOk`/`isError`, 5 `unwrap`/`then`) or a fn-typed record field (`jhonstart/src/hooks.bp:70` `c.set(9)`). So the l.7105-7114 half is free. **Method bodies currently swallowed: 79** — erika 39, std 31, rakun 7, onze 2, jhonstart 0, emilia 0. erika's 39 are the largest single exposure in Part 0 and have *never* been type-checked (`erika/src/erika.bp:24` `pub fn toArray(self: Self) -> Array<T>`, `:105` `return Query(items: sorted);` inside `orderBy<K>` — every `Query<T>` method chains generic `Array<T>` methods). Interface `default fn` bodies (std 48, erika 1) are already strict via `inferInterfaceDefaultBodies` and are not part of this delta. Swallow site: l.2970-2975 (`_ = inferExpr(env, stmt.expr) catch { env.lastError = null; break; }`) |
| **Blast radius** | **library**, and the least predictable row: the best-effort walk exists *because* real bodies trip gaps. Note erika is red today for an unrelated reason (spec 01), so its 39 bodies cannot even be measured until wave 0 lands. In the *suite* the exposure is small — 4 of the 17 tripwire slugs are extension/method dispatch (`inherent_record_method_is_always_available`, `local_extension_method_resolves_without_activation`, `multi_module_extension_activated_via_star_import`, `qualified_extension_call_needs_no_activation`), and a wider grep for undeclared receiver methods returns 73 fixtures that are almost all false positives (stdlib array/string methods resolved elsewhere, the 12 `@Expr` template methods, and negative tests that already assert a red). Instrument first — make `inferTypeMethods` count and print the swallowed errors over `libs/std` + the five siblings, and read the list before deciding whether C9 is one row or three |
| **Ordering** | After C1 and C8: many swallowed method-body errors are `return` and `case` shaped, so the count only means something once those two are strict |

### C10 — unknown type names are accepted

| | |
|---|---|
| **Where** | `env.zig` `resolveTypeName` l.930-931 (`// Fallback: treat as an opaque named type (forward reference, etc.)`) and l.916-928 (any value binding is accepted, with a documented carve-out at l.925-927 for an imported constructor naming its own type) |
| **Why** | The fallback is load-bearing for **forward references**: a record annotated with a type declared later in the file, and a type that lives in another module whose typedef was not registered. The bindings arm is load-bearing for imported records/structs/enums, where the import binds a constructor value but the typedef stays in the defining module |
| **Correct** | Two-pass resolution: register every typedef in the module (and every imported typedef) before annotations resolve, then the fallback becomes `TypeError.unknownTypeName` at the TypeRef. The bindings arm keeps only the constructor carve-out (l.925-927) and reds for a non-type binding |
| **Probe at HEAD** | `record Q { lat: bogusType }` → `Checked`. `val n = 5; val x: n = 7;` → `Checked` (while `val T = i32; val x: T = "s";` correctly reds) |
| **Acceptance** | an unknown type name reds at the TypeRef; a non-type binding in annotation position reds; forward references to records/enums declared later still check |
| **Library exposure** | **38** annotation sites name a type declared nowhere: emilia 28 (the presumed compiler-synthesized nested-section names — `emilia.bp:103` `fn textTokenToCss(t: TokenText)`, `:187` `padScaleX(s: TokenPadX)`, `:334` `borderColorToCss(c: TokenBorderColor)`, …, plus `:23` `-> unit`), std 9 (`-> unit` in `env.bp:30,35`, `process.bp:28`, `random.bp:28` — rename to `void`; the `RecordField` sites in `types.bp`/`reflect.bp` *are* declared, in `comptime.zig` `type_info_src`, and survive), jhonstart 1 (`server.d.bp:28` `-> @Context<Http, Request>` — `Http` is declared nowhere). `Children` in `jhonstart/src/element.bp` looks undeclared to a library-scoped resolver but is compiler-known (`infer.zig` l.3785 `childrenCoercion`) — whatever the two-pass registration is, it must consult the same table |
| **Blast radius** | **library**. emilia's 28 are the real work and they are the same 28 that C8 touches — the nested-section enum has to grow real declared section types (or emilia has to stop annotating them) before C10 can land. Host/FFI type names in `#[@external]` declarations also become hard errors. In the suite the exposure is **~7** fixtures — the ones annotating with a *variant* name or an undeclared name (`Circle`, `Square`, `Some`, `None`, `Wibble`, `Wobble`, `Container`, plus `Order`/`TypeInfoKind`/`RecordField`); 9 more that a naive grep flags (`Array`, `Span`, `Binding`, `Children`, `TypeInfo`, `Option`, `Result`) are registered builtins and resolve legitimately. The two-pass registration must land *before* the fallback is removed, and the removal is the last commit of the row |
| **Overlap** | Part A step 1 replaces the bindings arm with a real `type` kind. Do C10's two-pass registration here and let A1 delete the bindings arm — otherwise the same code is rewritten twice |

### C11 — record update spread is positional

| | |
|---|---|
| **Where** | `infer.zig` l.7203-7213 — when `spreadCount != 1 or nonSpreadCount < 2` the call takes the "historical spread behavior" path: arity check against `f.params.len`, then `unifyAt(paramType, arg)` **by index**. Otherwise (l.7221-7232) the args are walked skipping the `..` label, still positionally. Labels never select a field |
| **Why** | The comment says it: "Keep the historical spread behavior (and snapshots) for narrow update/error cases" — the label-based path was never written, and the two branches exist to keep three error snapshots unchanged |
| **Correct** | A call carrying a `..` spread is a record **update**, not a constructor call: the spread's type must be the same record (or a compatible variant), each remaining arg is matched to the field its label names, an unknown label reds at the label, and a wrong value type reds at the value |
| **Probe at HEAD** | `record Person { name: string, age: i32 } val alice = Person(name: "a", age: 1); val b = Person(..alice, age: 25);` → `expected string, got Person at main:3:18` (it matched field 0) |
| **Acceptance** | `..alice, age: 25` checks; an unknown label → `unknown field` at the label; a wrong value type → caret at the value; spreading another variant reds with a variant message (`variant_mismatch`, `non_existent_field`, `field_type_mismatch` regenerated) |
| **Blast radius** | **few** — **5** fixtures in total, all in `comptime/tests/variants.zig`, 3 of them already error tests (`record update error: field type mismatch`, `record update error: non-existent field`, plus the `as`-pattern skip). **Zero library sites**: `..` appears in no `.bp` file in the repository (the `dotDot` token exists at `lexer/token.zig` l.41 and nothing uses it). The current behaviour is wrong enough that no working code can depend on it — this is the cheapest correctness row in Part 0 |

### C12 — `val assert`, and pipelines

| | |
|---|---|
| **Where** | `infer.zig` l.7544-7563 — `assertPattern` catches `error.TypeError` from **both** the expression (l.7546-7550) and the handler (l.7553-7557), substituting a fresh-var `null` literal; the pattern `ap.pattern` is never checked against the expression's type. Pipeline: l.7293-7299 — an RHS that is not a call is typed as-is, so `1 \|> double` has the type of `double` (a function); l.7258-7267 — the arity check is `if (f.params.len == totalArgs)`, and a mismatch just skips unification |
| **Why** | The `catch` was added so an unbound identifier in an assert would not fail the module (it is a test-shaped form). The pipeline arity `if` guards against unifying a wrong number of params — it should report instead |
| **Correct** | `val assert P = e catch h` infers `e` strictly, checks `P` against `e`'s type (the same machinery C8 builds), and unifies `h` with the bound type. `lhs \|> f` where `f` is a 1-ary function is the call `f(lhs)` and has type `f`'s return. A pipeline arity mismatch is `TypeError.arityMismatch` at the RHS |
| **Probe at HEAD** | `val assert 42 = answer catch 0;` with `answer` unbound → `Checked`. `val r: i32 = 1 \|> double;` → `expected i32, got function`. `val r = 1 \|> add(1, 2);` for a 2-ary `add` → `Checked` |
| **Acceptance** | `val assert 42 = answer catch 0;` with `answer` unbound reds; `val r: i32 = 1 \|> double;` checks; `1 \|> add(1, 2)` for a 2-ary `add` reds |
| **Blast radius** | **few**. **`\|>` appears in no `.bp` file in the repository** (the `pipe` token is at `lexer/token.zig` l.38 and no surface code uses it), so both pipeline fixes are free of library migration. The `val assert` half needs C8's pattern-vs-type machinery |

### C13 — diagnostics: the effect code, and missing locations

| | |
|---|---|
| **Where** | `infer.zig` l.2789 — `const fnLoc: ?ast.Loc = if (f.body.len > 0) f.body[0].expr.getLoc() else null;` (the same line exists at l.2073). l.2796-2799 — the code is `effect_wrapper_mismatch` when the return type derefs to `.named`, else `effect_missing_wrapper`; every primitive return type is `.named`, so R4 is unreachable. Unlocated errors: `unify.zig` l.37/54/58/66/76/85/97/102/109/119/127 (located only via `unifyAt`), the two bare `unify` calls at `infer.zig` l.5386 and l.5394, and 9 `TypeError.custom` sites — `infer.zig` l.72, 99, 191, 2161, 2200, 2637, 3951, 4640, 4701 — plus `unknownInterface` l.330, `unknownMethod` l.336/355, `ambiguousMethod` l.359, `missingMethod` l.385, `extendRequiresInterface` l.761, `redundantActivation` l.781, `notAnExtension` l.783 |
| **Why** | `fnLoc` predates the declaration having a usable span; the `.named` test was a proxy for "is a wrapper type" that never distinguished "wrong wrapper" from "no wrapper". The unlocated constructors are simply call sites that never got `.withLoc` |
| **Correct** | The effect check branches on whether the return type *is* one of the effect wrappers (`classifyAsyncReturn` already computes this at l.2788), not on its type-kind; the diagnostic is located at `f.returnType`'s span, and a bodyless `declare fn` gets the declaration's span. Every listed site gets a `.withLoc` |
| **Probe at HEAD** | `#[@result] fn f() -> i32 { return 1; }` → `effect-wrapper-mismatch … at main:1:28` (the body statement) |
| **Acceptance** | `#[@result] fn f() -> i32` reports `effect-missing-wrapper` at the return type; every error snapshot listed in 1.0.1-beta `06-snapshot-review/comptime-errors-effects.md` root cause 5 has a `┌─` location |
| **Blast radius** | **many** on error snapshots, zero on programs. Adding a `┌─` box to a snapshot that had none is a pure diff; it is the *only* way a future regression in those errors becomes visible |
| **Ordering** | Land with C3 — both rewrite `snapshots/comptime/*/errors/` and doing them separately regenerates 212 files twice |

### Landing groups

| Group | Rows | Library cost | Why together |
|---|---|---|---|
| **G0 — free wins, land first** | C6, C4b, C11, C7, C12 pipeline | **zero** for all five (no `..`, no `\|>`, no generic unit variant anywhere; C6 *unblocks* `libs/std`) | File-disjoint from each other and from everything below. C6 must be first of all — `libs/std` is red on it today, and every measurement below needs std to compile |
| **G1 — the emilia wave** | C1, C2(a), C8, C10 | **92 sites in emilia**, 9 in std, 5 in jhonstart | emilia does not compile at any intermediate point: its nested-section `Token` enum supplies C10's 28 undeclared annotations, C8's 35 payload bindings and C1's 28 `return out;` at once, and 31 of C1's 44 library sites need C2a to have a type to check. Sequence *inside* the wave: C2a → C1 → C8 → C10, one commit each, emilia migrated alongside |
| **G2 — narrowing prerequisites** | C5, then C12 `val assert` | zero | C5 makes a guard call usable in an `if` (it is typed `T` today, so the narrowing at l.5836-5845 is dead code); `val assert` needs C8's pattern-vs-type check. With G1 they unblock Part B step B6 |
| **G3 — strictness** | C9 | **79 method bodies** — erika 39, std 31, rakun 7, onze 2 | Needs the measurement in its row, which needs std and erika compiling (G0's C6, and wave 0 for erika) and needs G1 landed — many swallowed errors are `return`- and `case`-shaped |
| **G4 — diagnostics, land last** | C3, C13 | possible, from C3's arithmetic constraints | One regeneration of the 212 error-snapshot files instead of two — and G1/G3 add new error snapshots that would otherwise be written in the old format |

---

## Parser gaps

Five grammar gaps. Four of them own **seven of the nine** `assertComptimeCompileError`
documented skips — `comptime/tests/variants.zig` (4: three `as`-pattern, one nested/unnamed
payload) and `comptime/tests/narrowing.zig` (3: two `assert … is`, one `&&`) — plus the two
`codegen/tests/narrowing.zig` skips (`assert_pattern` l.83, `and_condition` l.144). The
remaining two comptime skips are the helper's own definition and the C4 `comptime <RecordCtor>`
rejection, which stays. **No checker row can close any of these.**

| Gap | Site | Grammar change | Closes | Blast radius |
|---|---|---|---|---|
| `if (a \|\| b)` / `if (a && b)` | `parser/exprs.zig` l.136 — `parseBinaryExpr(alloc, prec.equality)`; `prec.equality = 2` is documented at `parser.zig` l.1137-1139 as "the entry point for operand positions where `\|\|`/`&&` are not accepted (if-conditions, yields, ranges, assignments…)" | `prec.lowest` at l.136 only. The condition is parenthesised by the grammar (`consume(.leftParenthesis)` l.135, `consume(.rightParenthesis)` l.138), so there is no ambiguity to protect against — unlike the other four `prec.equality` call sites (l.208, 254, 319, 330, 1643) which are **not** delimited and must stay | `comptime/tests/narrowing.zig:285`, `codegen/tests/narrowing.zig:144`, and `libs/std/src/reflect.bp` (see Part A) | **few** — parser snapshots for `if`; verified at HEAD: `if ((a && b))` already parses and checks |
| `_` as an `if` binder | `parser/exprs.zig` l.145 — `this.check(.identifier) and this.peekAt(1).kind == .rightArrow` | also accept `.underscore` and set `binding = null` (the branch is still the null-check form, it just discards the value) | the `if (x) { _ -> … }` form named in Part B step B6 | **none** |
| `<Pattern> as <name>` | `parser/patterns.zig` `parseSimplePattern` l.160-262 (and `parsePattern` l.140-157). The `as` keyword exists in the lexer (`lexer.zig` l.695) | `Pattern` gains a `.bound = { pattern: *Pattern, name: []const u8 }` variant; `parsePattern` wraps its result when it sees `.as`. **Every** pattern consumer must handle it: `infer.zig` `bindPatternNamesForSubject`, `patternIsCatchAll` (l.4926), `collectFullyCoveredVariants` (l.4962), `alreadyCoveredVariant` (l.4989), and the pattern lowering in all four backends | `comptime/tests/variants.zig:291`, `:309`, `:328` | **many** — a new AST node crosses every backend. This is the most expensive of the four and the least valuable; consider deleting the three tests instead and recording the decision here |
| Unnamed variant payload + nested constructor patterns | Declaration: `parser/decls.zig` l.1167-1178 requires `identifier` `:` `TypeRef` per payload field. Pattern: `parser/patterns.zig` l.230-246 — the `.fields` payload consumes bare identifiers (`consume(.identifier)` l.236), so `Single(Ok(v))` parses `Ok` as a binder and then chokes on `(` | Declaration: `EnumVariantField.name` becomes optional with positional fallback names, which changes every backend's variant lowering and the `TypeInfo`/`EnumVariant` surface. Pattern: merge `.fields` and `.literals` into one `[]Pattern` payload so `parseSimplePattern` recurses | `comptime/tests/variants.zig:343` | **many** (declaration side) / **few** (pattern side). Recommend: implement the **pattern** half (nested constructor patterns are genuinely useful and C8 needs the recursion anyway), and drop the unnamed-payload half — named payloads are the language's convention |
| `assert <expr> is <Pattern>` | No production exists; `parser/exprs.zig` implements only `assert <Pattern> = <expr> catch <handler>` (the `.assertPattern` node consumed at `infer.zig` l.7544) | a new statement form that binds the pattern's names into the **enclosing** scope for the rest of the block (unlike `case`, which scopes them to an arm). Needs a scope-extending binding site in `inferStmtsTyped`, plus C8 to type what it binds | `comptime/tests/narrowing.zig:213`, `:230`, `codegen/tests/narrowing.zig:83` | **few** parser + **new** checker work. Depends on C8 |

---

## Part A — Types as values

### Current state vs what the steps assume

| Thing | What the steps assume | What exists at HEAD |
|---|---|---|
| `libs/std/src/types.bp` | a `.bp` implementation of `mapFields`/`partial`/`omit`/`pick` to be executed | **does not compile.** `botopink check` on it → `unknown field 'Record' on type 'TypeInfo' at main:23:16`. `TypeInfo` is an enum (`comptime.zig` `type_info_src`), so `info.Record.fields` is not field access — it must be `case info { Record(fields) -> … }`. It is also in no `mod` tree (`root.bp` does not declare it) |
| `libs/std/src/reflect.bp` | a `.bp` implementation of `mergeRecords` | **does not parse.** Three stacked defects, confirmed by peeling them one at a time: (1) l.26 uses the keyword `and`, which is not an operator — botopink has only `&&`; (2) with `&&` it still fails, because the `if` condition parses at `prec.equality` (the parser gap above) — `if ((… && …))` is needed; (3) with both fixed it reaches `unknown field 'Record' on type 'TypeInfo' at main:24:17`, the same enum defect as `types.bp`. Also in no `mod` tree |
| `mapFields` | resolved by name today, to be replaced by the `.bp` body | `tryResolveTypeManipulationCall` matches the name and returns `null` (l.4049-4053 accepts it, l.4071-4072 returns null), so the call falls through to the ordinary call path and is typed as an ordinary user call — i.e. it is *not* implemented in either place |
| `@typeInfo` / `@TypeOf` produce values | A3 | `eval.zig` `valueOf` l.149 folds `@typeInfo` to the opaque `.object` and l.150 folds `@TypeOf` to a type *name* string. At the type level `@TypeOf(1)` is `i32`, not a `type` value (probe: `val n: string = @TypeOf(1);` → `expected string, got i32`) |
| A comptime eval loop | A4 | `eval.zig` handles `if` (l.198-204), `loop` (l.205), `case` with a wildcard/binder arm only (l.182-190), `break` (l.194) and scope lookup (l.156-163) — but **no function application** (a non-builtin call returns `.null_` at l.152). `error.zig` `validateComptimeExpr` rejects a call (l.449), a `case` (l.458) and a `loop` (the `else` at l.485) *before* the folder ever sees them, and `validateComptime` only visits top-level `val` decls (l.383-388) |
| `type` as a value | A1 | `env.zig` l.916-928 accepts any binding in annotation position. There is no `type` kind in `comptime/types.zig` |
| A call in TypeRef position | A2 | does not parse (`val z: mk() = 1;` → parse error) |

### Steps

| Step | What | Acceptance |
|---|---|---|
| A0 | Make the two std modules compilable and loaded, since every later step builds on them: rewrite `info.Record.fields` as a `case` on the `TypeInfo` enum in both files, replace `and` with `&&` in `reflect.bp` (or land the `if`-condition grammar fix and keep the operator), and declare both in `libs/std/src/root.bp`. This is the `libs/std` half of spec 08 step 6; C6 is the compiler half | `botopink check` in `libs/std` is clean with `types.bp` and `reflect.bp` in the `mod` tree and no "module not reached" warning for either |
| A1 | `type` as a first-class comptime value: `val T = i32`, `comptime T: type`, `-> type` return. Replace the bindings-as-types fallback (C10) with a real `type` kind; a `comptime T: type` argument binds `T` for the remaining parameters and the return | usable as annotation, value, parameter and return; `id(i32, "s")` reds; `val n = 5; val x: n = 7` reds |
| A2 | `#[@code]` on a fn: the returned `TypeInfo` becomes the type at the call site (`val p: Point() = Point()(x: 1, y: 2)`), comptime parameters included. Needs a call in TypeRef position, which does not parse today | the annotation parses, the type is lifted, the constructor is usable |
| A3 | `@typeInfo`/`@TypeOf` produce **values** (`TypeInfo.Record(fields: [...])`, `TypeInfo.Optional(inner: …)`) of the existing `TypeInfo` enum, and `validateComptimeExpr` accepts them | correct values for primitives, record, enum, optional, array |
| A4 | A comptime eval loop for `.bp` fns with `comptime` params (`if`, `loop`, `break` with a type value, `case` on `TypeInfo`) | `types.bp`/`reflect.bp` fns are executed, not resolved by name |
| A5 | Std in `.bp`: `mergeRecords`, `mapFields`, `partial`, `omit`, `pick` with `#[@code]`; `recordKeys`, `field` as fns over `@typeInfo`. Remove `tryResolveTypeManipulationCall` and the `@makeRecord`/`@RecordKeys`/`@field` builtins | `comptime/tests/builtins_typeinfo.zig` (31 tests) passes without the special cases; a user fn **or method** named like a std type function is not shadowed |

A4 note: `validateComptimeExpr` rejects a call, a `loop` and a `case` before `eval.zig` sees
them, and `eval.zig` has no function application. Type-level eval with control flow therefore
has to go through the `erl` path (as decorators and templates do) or extend `eval.zig` +
`error.zig` — decide in A4. Note that `eval.zig` already implements `if`/`loop`/`break`/scope,
so the cheaper half of "extend" is mostly the validator.

A5 supersedes C6's builtin-specific rows but **not** its shadowing fix, which must land first
(`libs/std` is red on it today).

---

## Part B — Narrowing

The 1.0.1-beta harness wave rebased the fixtures: every narrowing test now compiles or is a
documented compile-error skip, and the codegen fixtures that wrote 0-byte snapshots are gone.
What the tests *assert* is still open.

**Checker, per pattern (from `botopink check` at HEAD):**

| Pattern | Checker | Mechanism |
|---|---|---|
| `if (x) { n -> … }` | works — `n` is the inner type | `infer.zig` l.5795-5806 unwraps `optional<T>` |
| `if (x) { _ -> … }` | does not parse | parser gap (binder accepts `.identifier` only, l.145) |
| early return / negative check (`if (!x) { return …; }`) | not implemented — `!` requires `bool` and reports it reversed (`expected i32, got bool`) | C3 (M2) at l.5413 |
| `x == null` / `x != null`, and the `else` of a check | parses and checks, but **does not narrow**: inside the branch `x` is still `?i32` (`val y: i32 = x;` → `expected i32, got optional`) | no comparison-narrowing exists; `inferBranchExpr` narrows only through a binder (l.5795) or a type guard (l.5810-5832) |
| `?i32` used arithmetically with no narrowing at all | **wrongly accepted** — `return x + 1` checks | C3 / M3: the optional subsumption in `unify.zig` l.48-52 reached from the operand side |
| `case` on `@Result` / enum payloads | bindings untyped | C8 |
| OR patterns | bindings untyped, and only the first alternative's names are bound | C8 (l.4890) |
| guards `x if (…) ->` | bindings untyped | C8 |
| `assert x is P;` | does not parse | parser gap |
| type guard `-> x is T` | the call is typed `T`, so the `if` rejects it before the narrowing at l.5836-5845 runs | C5 |
| `&&` | `if (a && b)` is a parse error (parser gap); `if ((a && b))` parses, and `inferBinaryOpExpr` l.5348-5359 *does* narrow an optional LHS identifier before inferring the RHS — but l.5374-5375 then unifies the LHS with `bool`, so `b && b.weight > 10` on `?Box` reds | parser gap + C3 |
| `?.` | works (`o.inner?.value` : `?i32`) | l.5251-5257 |
| `else if` chain | n/a — the fixture has no null check (`x == 0` on `?i32`) | fixture defect, see B7 |

**Comptime tests** (`comptime/tests/narrowing.zig`, 19 tests): the 15 success fixtures now all
record a `TYPED AST JSON` section (3 more are documented compile-error skips, 1 is an error
snapshot), but none of them asserts a narrowed type. The JSON shows a fn body as raw source
lines and renders an annotation syntactically (`typeNameFromTypeRef`), and a narrowed type is
by definition the one no annotation wrote — so the snapshot only proves the program compiles.
The assertion has to be an annotated top-level `val` (whose inferred side goes through
`typeNameOf`) plus a negative error snapshot.

**Codegen tests** (`codegen/tests/narrowing.zig`, 11 tests × 4 backends): 9 run, 2 are
documented compile-error skips (`assert_pattern`, `and_condition`). Every RUN LOG at HEAD
(read from `snapshots/codegen/<backend>/narrow_<slug>.snap.md`):

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

**Caveat for B7's "identical RUN LOG":** erlang and beam print a string as an Erlang binary
(`<<"hello world">>`) where commonJS prints `hello world`. Rows that print a string therefore
cannot be byte-identical across backends without either a `@print` lowering that formats a
binary as text, or a normalisation rule in the comparison. Decide which before B7 starts —
it is a codegen decision, not a checker one, and it affects `early_return_with_print` and
`case_result_ok_err_with_print` here as well as rows in spec 03.

| Step | What | Acceptance |
|---|---|---|
| B6 | Make `comptime/tests/narrowing.zig` assert the narrowing: each pattern gets an annotated top-level `val` pinning the narrowed type plus a negative error snapshot. Decide and implement or drop the documented skips: `&&`/`\|\|` in `if` conditions (`parser/exprs.zig` l.136 → `prec.lowest`), `_` as an `if` binder (l.145), `assert x is P`, negative/early-return and `else` narrowing, nested patterns. Depends on C5, C8 and — for the "no narrowing needed" false negatives — C3's fix to the subsumption leak | every kept pattern has a positive and a negative test; no fixture whose only assertion is "it compiles"; dropped patterns are deleted from both test files |
| B7 | Narrowing codegen on the 4 backends: every executing backend of a fixture prints the same, correct value under the string-rendering rule decided above. Fix the `else_if_chain` fixture (no null check, `"nonzero: " + x`). Backend output bugs found here (JS destructuring payloads by binder name, erlang/beam variant patterns, BEAM printing the unmatched tuple, `return if` in JS, wasm narrowing bindings) belong to the codegen spec | the table above has one identical, correct RUN LOG per row across commonJS, erlang and beam (wasm once the WAT runner executes) |

Part 0, A2–A5 and B6 all touch `comptime/infer.zig` — do not parallelise them across branches.
The B6 parser changes (`parser/exprs.zig`) are independent of Part A; C4b and B7 can run
beside everything else.

---

## Open questions

- `@code(text)` already exists as a builtin valid only inside template fns (`infer.zig`
  l.3808-3828, lowered through `template_eval.zig`); `#[@code]` would be the first `#[@…]`
  annotation that is neither an effect (`ast.zig` `EffectKind`) nor `@external`. The positions
  do not clash syntactically, but confirm the shared name is intended or pick another.
- Mismatched `case` arms (C2): a union type (`typeNameOf` already renders `.union_`, and
  `unify.zig` l.115-130 unifies unions element-wise) or an error. A union makes `case` usable
  as an expression over heterogeneous arms; an error is simpler and matches every other
  position in the language. **The library survey says the cheaper answer is free**: all 32
  `case`-as-value blocks in all six libraries are type-homogeneous, so nothing outside the
  fixtures needs a union. Two fixture slugs
  (`case_arms_with_different_types_string_i32_union`,
  `case_union_return_type_from_mismatched_arms`) were named for the union answer — read them
  before overruling it.
- `<Pattern> as <name>` (the parser gap table): implement or delete the three tests. A new
  `Pattern` node reaches all four backends for a form no library uses.
- Unnamed enum variant payloads: the recommendation above is to drop them and keep `name: Type`
  as the convention. Confirm, then delete the declaration half of
  `comptime/tests/variants.zig:343` and keep the nested-pattern half.

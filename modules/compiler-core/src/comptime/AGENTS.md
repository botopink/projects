# compiler-core/src/comptime

> Path: `modules/compiler-core/src/comptime/`
> Parent: [`../AGENTS.md`](../AGENTS.md)
> Docs: [`./docs.md`](docs.md) · Examples: [`./examples.md`](examples.md)

Hindley-Milner type inference, comptime evaluation, and the AST transform
pass that specializes comptime calls. The target-agnostic façade is at
`../comptime.zig`.

## Tree

```text
comptime/
├── AGENTS.md          ← you are here
├── docs.md            ← architecture: type system, Aggregator 5-step pass
├── examples.md        ← comptime usage in `.bp` source
├── types.zig          ← core Type union(enum)
├── env.zig            ← Env (binding name → *Type) + builtins/stdlib loading
├── infer.zig          ← `inferProgramTyped` — HM walk
├── unify.zig          ← type-variable unification + occurs check
├── error.zig          ← structured TypeError with source ranges + hints
├── eval.zig           ← evaluation driver (delegates to runtime/)
├── render.zig         ← comptime value → target literal
├── specialize.zig     ← `SpecializedFn`, `SpecCache`, `specialize()`
├── transform.zig      ← `Aggregator` — drives the full transform pass
├── template.zig       ← `@Expr` templates: CapturedExpr, ScopeSnapshot, fail diagnostics
├── template_eval.zig  ← runtime-backed template body evaluation (node) — F6-full
├── decorator_eval.zig ← runtime-backed decorator body invocation (node) — annotation processors (P2)
├── snapshot.zig       ← comptime snapshot helpers
├── stdlib/            ← std prelude loader — see stdlib/AGENTS.md
│   └── prelude.zig        ← @embedFile of libs/std/src/*.bp (std_prelude module root)
├── tests.zig          ← barrel: aggregates tests/<feature>.zig for test_root.zig
├── tests/             ← comptime tests, split by feature
│   ├── helpers.zig        ← shared harness (`assertComptimeAst`, `assertTypeErrorSnap`, …)
│   ├── infer_exprs.zig    ← literal/binary/case/control-flow inference
│   ├── infer_decls.zig    ← pub fn/record/struct/interface/implement/test-block inference
│   ├── infer_generics.zig ← type meta-kind & generic inference
│   ├── infer_errors.zig   ← inference type errors (`infer error: …`)
│   ├── types.zig          ← types / type_unification
│   ├── variants.zig       ← variant/record-update/pattern/@print/AST probes
│   ├── exhaustiveness.zig ← case exhaustiveness (+errors)
│   ├── effects.zig        ← throw/context/@Result effect checking
│   ├── templates.zig      ← @Expr capture / scope snapshot / methods / expansion / markup DSL
│   ├── decorators.zig     ← decorator recognition + generic argument validation (P1)
│   └── decorator_invocation.zig ← decorator body invocation + fail diagnostics (P2)
└── runtime/           ← Node.js + Erlang eval backends — see runtime/AGENTS.md
```

## Files

| File | Role |
|---|---|
| `types.zig` | All type representations as `union(enum)`. |
| `env.zig` | Type environment — scopes, builtins + stdlib, `TypeDef.contextBase`, `FnContext`, static-extension-dispatch tables (`extensions`, `activations`, `inherentMethods`, `dispatchRewrites`), the `"std"` package tables (`stdModules`: module → fn exports; `stdModuleTypes`: module → pub type decls, registered into the importer by `markStdImports` — type export; `stdImports`: names imported via `from "std"` — explicit import wins over same-named value bindings like the primitive `bool`), the lib-agnostic `decorators` table (decorator name →
`DecoratorSig{ params }`, filled by `registerDecoratorSig` for any fn/delegate whose
first param is `comptime _: @Decl`; drives `#[d(args)]` argument checking), and the loc-keyed lowering maps `method_lowerings` (`@Result`/`@Option` methods + the builtin `result` namespace, `qualified` flag) + `result_jump_lowerings` (`return`/`throw` → `__bp_ok`/`__bp_error` in `*fn -> @Result` fns) + `jsMethodRenames` (type-directed JS-only method renames, e.g. `string` `contains` → native `includes`; recorded only when the receiver's static type makes a global name-map unsafe, since `record Set` also declares `contains`). |
| `infer.zig` | Main HM inference: `inferProgramTyped(...) → []TypedBinding`. `registerExtensions` pre-pass + `resolveReceiverCall` implement F6 static extension dispatch. `registerFnSignatures` pre-pass (via `buildFnSignatureType`) binds every top-level `fn` signature *before* any body is inferred, so mutually-recursive / forward-referenced top-level fns resolve (a fn's signature is fully determined by its declared param/return types + generics, so the pre-pass type matches the one `inferFnDecl` re-derives for self-recursion). Ends with `validateProgram` — `implement`/interface coverage + getter/setter type checks. Top-level `test { … }` bodies type-check like void `fn` bodies via `inferTestDecl` (no binding produced); `assert cond` unifies `cond` with `bool`. **Type method bodies** (`stdlib-backends-parity`): `inferTypeMethods` walks record/struct/enum method bodies (previously only signatures were registered) — binding the type generics, `Self`, the method generics + params, then inferring each statement. This type-checks method/`default fn` bodies AND records the codegen lowerings for the calls inside; it is **best-effort** (a body that trips an inference gap is skipped, not a hard error) so the LINQ-heavy stdlib lib still compiles. **Value-receiver instance calls** are recorded in the loc-keyed `instanceLowerings` table (`env.zig`): `.record <typeName>` (codegen resolves local vs imported owner) or `.prim <PrimKind>` (array/string/bool/int/float — the non-JS backends map it to a host op). `primMethodReturnType` recovers an array/string method's real return type so a chain (`xs.filter(f).at(0)` → `?T`) keeps tracking through it; `arr.length`/`s.length`/`.len` field access records a `.prim` entry too (→ `length`/`string:length`). commonJS ignores `instanceLowerings` (native dispatch). |
| `unify.zig` | Unification with substitution + occurs check. |
| `error.zig` | Structured type errors with source ranges and hints (incl. `missingMethod`/`unknownMethod`/`unknownInterface`/`ambiguousMethod`). |
| `eval.zig` | Builds eval scripts, calls runtime, parses JSON results. |
| `render.zig` | Converts an evaluated comptime value into a target literal. |
| `specialize.zig` | Pure AST specialization — unroll loops, fold static if/case. |
| `transform.zig` | `Aggregator` — drives specialize + rewrite + inline + dead-code; lowers `@Result`/`@Option` method calls to `__bp_<domain>_<op>(…)` and `return`/`throw` in `*fn -> @Result` fns to `return __bp_ok(…)`/`return __bp_error(…)` (`tryLowerResultJump`). Walks `fn` AND `test { … }` decl bodies, including `assert` condition/message subexpressions (`.comptime_` stmt/expr arms) — lowerings inside test asserts apply like anywhere else. |
| `template.zig` | `@Expr` template infrastructure: `CapturedExpr` (an argument bound to a `comptime p: @Expr<T>` param, captured unevaluated with provenance), `PlainArg` (a non-`@Expr` param that received a literal value at the call site — emitted as a plain JS binding in the eval script), `ScopeSnapshot` (V1 origin scope: caller's top-level decls + imports, serializable via `toJsonAlloc`), `contextJsonAlloc` (the full second-layer handle), and `mapSpanToLoc`/`failDiagnostic` (rustc-style `fail`/`failAt` diagnostics pointing inside the caller's `"""…"""`). `mapSpanToLoc` fallback for holed templates uses `capture.loc.line + span.line - 1` (span.line is 1-based, line 1 = opening `"""` line). |
| `template_eval.zig` | F6-full: runs a non-V1 template body in the **node** eval runtime (host-side comptime, independent of the compile target). Captures become JS objects implementing the comptime surface (`text`/`parts`/`source`/`context`/`lookup`/`bindings`/`build`/`fail`/`failAt`) over the `contextJsonAlloc` handle; plain args are emitted as JS bindings before capture objects; params are passed in declaration order. The script reports one protocol result — `code` (parse + splice), `value` (`@expr` lift → literal), `capture` (param pass-through), `fail` (template diagnostic), `error`. Erlang evaluator parity (running bodies via erlang for erlang-only environments) is a recorded follow-up. |
| `decorator_eval.zig` | Annotation processors (P2): runs a decorator body in the **node** eval runtime over the declaration it annotates. The serialized `@Decl` handle becomes a `__decl(...)` object exposing the reflection fields (`kind`/`name`/`fields`/`methods`/`returnType`/`annotations`) + `fail`/`failAt`; a global `DeclKind` mirrors the registered enum. The script reports `ok` (placement accepted), `fail` (scoped diagnostic), or `error`. Driven by `infer.zig invokeDecorators`, which serializes each annotated decl and surfaces a `fail` as a `TypeError`. Like template eval, node-only and skipped in tooling paths. |
| `snapshot.zig` | Snapshot helpers. |
| `tests.zig` | Barrel aggregating `tests/<feature>.zig`; harness in `tests/helpers.zig`. |

## Quick-reference testing helpers

```zig
try assertTypes(alloc, source, &.{ .{ "x", "i32" }, .{ "f", "fn(i32) i32" } });
try assertTypeErrorSnap(alloc, @src(), source);
```

## `@Expr` templates (expr-templates)

`@Expr<E>` is the builtin expression type (encoded as named type `"Expr"`
with one arg). The generic parameter is **mandatory** — a result type only
the expansion knows is an ordinary fn generic (`fn yaml<T>(…) -> @Expr<T>`,
fresh var per `genericMap`). There is no `expr` keyword — only `type`
remains a meta-kind; `@Expr` params require the `comptime` modifier via a
semantic check in `inferFnDecl`.

An argument bound to a `comptime p: @Expr<T>` parameter is type-checked in
the caller and captured **unevaluated**. Wiring in `infer.zig` / `env.zig`:

- `inferFnDecl` records `@Expr` params per function (`env.fnExprParams`) and
  registers fns returning `@Expr<…>` as template fns (`env.templateFns`);
  `env.inTemplateFn` gates the construction builtins while their bodies infer.
- `buildScopeSnapshot` (start of `inferProgram*`) collects the module's
  top-level decls + imports into `env.scopeSnapshot` — the V1 origin scope
  for `lookup`/`bindings` (function locals are not visible).
- At a call site, `captureExprArg` unifies the argument's type against the
  inner `T` of `@Expr<T>`, enforces the V1 literal rule (must be a literal
  string), and records a `template.CapturedExpr` in `env.exprCaptures`
  (keyed by call loc) with text/parts, the opening-line location (the lexer
  stamps multiline literals with their *closing* line), module path, and the
  scope snapshot. `template.contextJsonAlloc` serializes the whole handle
  for the runtime-backed evaluator (F6-full).
- `inferTemplateMethod` resolves the comptime-only methods on `@Expr`
  receivers (`value`/`text`/`parts`/`source`/`context`/`lookup`/`bindings`/
  `build`/`fail`/`failAt`) and `ref()` on `Binding`, recording
  `env.templateLowerings` (keyed by call loc). The contract is declared as
  `interface Expr<E>` in `libs/std/src/syntax.bp` (plain stdlib, preloaded
  by `registerStdlib`), alongside `Span`/`Part`/`Binding`/`Source`/`Context`.
- Construction is **explicit** — no implicit value lifting. The builtins
  `@expr(value)` (lift a comptime value as code) and `@code(text)` (parse
  generated source text) are typed in `inferBuiltinCallReturnType` and only
  valid inside a template function.
- `template.failDiagnostic`/`mapSpanToLoc` build the rustc-style diagnostic
  whose span lands inside the caller's `"""…"""` literal.

Call-site expansion: `expandTemplateCall` (inferCallExpr) expands template
calls during inference. The V1 classifier reduces `return <@Expr param>`
(pass-through), `return @expr(E)` (E must not reference the template's own
params — those go to the runtime), and `return @code("…")` by inspection;
anything richer runs in the **eval runtime** (`template_eval.zig`) when
`env.templateEval` is set — `comptime.zig` provides it in the full `compile`
pipeline only (tooling/LSP keeps the V1 error). Mixed signatures: non-`@Expr`
params must receive literal values; `literalToJsAlloc` serializes them as JS;
`expandTemplateCallViaRuntime` verifies `captures.len + plainArgs.len == tfn.params.len`.
Runtime expansions are memoized by callee + capture texts + scope JSON +
plain arg values (`env.templateEvalCache`); scope JSON detects binding changes
between builds; holed captures remain non-memoized. Either way the
expansion is re-inferred in the caller's env (splice + re-check), unified
against a concrete `-> @Expr<T>` bound (an unconstrained generic `T` reveals
the type per call site), and recorded in `env.templateExpansions`
(loc-keyed); the transform pass substitutes the untyped AST at those locs
and drops template fns (never specialized, never emitted). Holed templates
(slice 2): parts cross into JS as Text/Interp entries — Interp exposes a
`code` placeholder (`__bp_hole_<param>_<i>`) the DSL embeds in built source;
`substituteHoles` splices the caller's hole AST back after parse; holed
captures are not memoized. Cross-module: the export registry carries
template FnDecls (comptime.zig `template_registry`); imports register them
via `registerImportedTemplateFn` so calls expand in the importing module
(template-built code re-infers in the CALLER's scope — V1 hygiene caveat).
Imported `pub` nominal types (`record`/`struct`/`enum`) likewise carry their
AST decl across the boundary (comptime.zig `type_decl_registry`); `resolveImports`
re-registers them via `registerImportedTypeDecl` so the importer sees the full
`TypeDef` — `implements`/`contextBase`/fields — not just the constructor value
binding (and skips the redundant constructor rebind for those names). Mirrors the
`from "std"` `stdModuleTypes` path. Without it an imported type's
`implement @Context<…>` is invisible to the `use`-legality check
(`contextInfoFromReturn` → `lookupTypeDef`), and a local fn annotated with an
imported type resolves the annotation to the constructor func — `resolveTypeName`
(env.zig) guards the latter by mapping a constructor binding back to its named type.
`lookup()`/`bindings()` results expose `ref()` (the binding's name as code).
`@expr(record { … })` lifts anonymous structural records (`Type.record`,
F10) — computed objects come back through `literalFromJson`. Remaining
limits (recorded): all params must be `@Expr` captures; node runtime only.

## Annotation processors / decorators (P1 + P2)

A **decorator** is an ordinary comptime function whose first parameter is
`comptime _: @Decl` (the reflection handle, declared in `libs/std/src/builtins.d.bp`
and recognized in the parser as a bare builtin via `TypeRef.isDeclType`). Both
the `pub fn` and bodyless `declare fn` (delegate) forms are recognized. The core
provides only the generic protocol — recognize → reflect → invoke → apply; it
never knows what a marker means (that lives in the lib body, in `.bp`).

- `registerFnSignatures` calls `registerDecoratorSig` for every top-level `fn`
  and `delegate`; when the first param is `comptime _: @Decl` it records the
  trailing signature (everything after the handle) **and the body-carrying
  `FnDecl`** in `env.decorators` (name → `DecoratorSig{ params, fn_decl }`).
- The `@Decl` cluster (`enum DeclKind` + `struct Decl`/`Field`/`Method`/`Param`/
  `Annotation`/`Span`) is registered into the global env by `comptime.zig
  registerStdlib` from `decl_reflection_src`, so a decorator body type-checks. It
  is a `struct` (not an interface) so the **aggregate** members resolve too —
  `decl.fields`/`decl.methods`/`decl.annotations` (array types interface `val`s
  don't parse) — which is what a wiring decorator iterates. The shape matches the
  handle JSON and the `__decl` runtime object.
- `@compilerError(message)` — the generic compile-time error builtin (declared in
  `builtins.d.bp`, return-typed `noreturn` via a fresh var in
  `inferBuiltinCallReturnType`, lowered to `__compilerError(...)` by commonJS).
  The preferred way for a comptime body — a decorator or an `@Expr` template — to
  reject its input: the `decorator_eval`/`template_eval` preludes define
  `__compilerError` as a `__failRaw` throw, so it surfaces as the same scoped
  diagnostic as `decl.fail`, but needs no `@Decl` handle.
- `validateDecorators` (pass 3, before `validateProgram`) walks every
  declaration's `annotations` — record/struct/enum/fn/interface + their methods —
  and for each `#[name(args)]` whose `name` is a recognized decorator,
  `checkDecoratorArgs` type-checks the trailing args: arity (honoring trailing
  defaults) + a per-argument lexical kind check (`string`/numeric/`bool`/enum
  member). Unknown markers stay lenient (a lib may simply not be loaded).
- **P2 invocation:** `invokeDecorators` (right after `validateDecorators`) runs
  each body-carrying decorator over the declaration it annotates. `buildHandleJson`
  serializes the decl into a `@Decl` handle (kind/name/fields/methods/returnType/
  annotations); `decorator_eval.zig` emits the body as plain JS, binds a `__decl`
  object + the trailing args, runs it in the **node** runtime, and reports
  `ok` / `fail{message,span}` / `error`. A `fail`/`failAt` becomes a scoped
  `TypeError`; placement/arg rules live entirely in the lib body. Runs only in
  the full compile pipeline (`env.templateEval` set); tooling/LSP paths skip it.
  Diagnostic locs are coarse for now (message carries the detail; precise spans
  are a follow-up).
- Method-site **and** field-site decorators now parse on record/struct bodies
  (`parseRecordBody`/`parseStructBody` read member-level annotations before a `fn`
  or a field; `RecordField`/`StructField` carry an `annotations` slice). So
  `#[getMapping]` on a controller method and `#[inject]`/`#[value]` on a field both
  reach `validateDecorators` + `invokeDecorators`, which walk fields (reflected as
  `DeclKind.Field` — `name` + the field's `returnType`) alongside methods. Adding
  the `annotations` field re-serializes the parser AST, so the record/struct
  parser snapshots were regenerated.
- **P3 wiring contribution:** a decorator body contributes generated top-level
  declarations via `@emit(source)` (declared in `builtins.d.bp`; lowered to
  `__emit` by commonJS; the `decorator_eval` prelude collects the strings and
  returns them in `Outcome.ok`). `runDeclDecorators` accumulates them into
  `env.contributions`; `analyzeModule`/`analyzeSource` then **splice** the
  contributed sources onto the module and **re-analyze it once** with
  `env.skipDecoratorInvoke = true` (so the generated decls are inferred + emitted
  without re-running decorators — no re-contribution, no loop). This is how a
  framework lib builds singletons / a DI graph / a router table as ordinary code,
  with no wiring logic in the core.
- Decorator fns are **comptime-only** and dropped from codegen by `transform.zig`
  (Phase 3 decl filter, next to the template-fn drop): a `fn` whose first param is
  `comptime _: @Decl` is never emitted, so its body's `@emit`/`@compilerError`/
  `decl.fail` (→ `__emit`/`__compilerError`/`__decl`) never leaks into real output.
  The decls it contributed via `@emit` are already spliced into the module and
  stay.

## `@Context<B, R>` capability inference (F7)

`use` is a **prefix operator** (`use <hookcall>`); any binding is done by the
enclosing `val`/`var` (`val {v, s} = use state(0)`, `use effect { … }` for void).
The AST node is `Expr.useHook { inner }`. It is gated by the function's **return type**:

- The return must implement `@Context<ContextBase, Return>` — either directly
  (`fn f() -> @Context<Element, R>`) or via a named type whose inline
  `implement` clause lists `@Context<…>` (`struct implement @Context<Element, R>`).
- Every `use` expression in the body must itself return `@Context<B, _>` with the
  **same** `ContextBase` as the function. Validation is transitive through custom
  hooks (a hook's return type carries its `ContextBase`).

Wiring in `infer.zig`:

- Registration computes `TypeDef.contextBase` from a decl's `implement` clause
  (`contextBaseFromImplements`).
- `inferFnDecl` records the body's capability in `env.fnContext`
  (`contextInfoFromReturn`) and restores it afterwards.
- `inferUseHookExpr` checks `env.fnContext` then `validateUseBase` (compares
  ContextBases), and exposes the hook's Return type `R` as the prefix's type.
  Diagnostics: `useNotAllowed`, `useNotContext`, `contextMismatch`.
- A destructuring `val {v, s} = use …` binds leniently via `bindUseDestructure`
  (the Return type need not be a record).

Codegen (F8) lowers `use` per target. CommonJS maps it to React hooks
(`state` → `useState`, `memo`/`effect` get an inferred dependency array); the
other targets treat `use` as a transparent prefix (bind the call result into a
slot). Phantom `@Context` base structs (`struct implement @Context { }`, no
members) are erased — see `codegen/AGENTS.md`.

## Anonymous record types + `Children` coercion

- `resolveTypeRefInContext` lowers a `TypeRef.record_type` (`{ f: T, … }`) to a
  structural `Type.record`; it unifies field-by-field with a `record { … }`
  literal (`unify.zig`, same field set + order, V1).
- `childrenCoercion` (checked at the top of `unifyAt`, which is always called
  target-first) lets an argument bind to a parameter declared `Children` when
  it is another `Children`, any array (`Element[]` — the list form), a `string`
  (→ a text child), or a single value implementing `@Context` (an `Element` →
  a one-element list). One-directional: only fires when the *declared* type is
  `Children`. This is the builder children model `div([a, b])`/`div(a)`/`div("…")`.
- A record field whose type is a function (`set: fn(next: T)`) needs no special
  inference — it is an ordinary `Type.func` field and codegen stores the closure
  like any field (`new State(0, (n) => {})`).

## `case` exhaustiveness + reachability

A single-subject `case` on an **enum** or **string** subject is checked by
`checkCaseExhaustiveness` in `infer.zig` (run after the arms are typed):

- **Coverage** — each unguarded arm fully covers a variant when it is a bare
  variant ident (`Red`), or a `Variant(payload)` whose payload is irrefutable
  (only bindings / wildcards, e.g. `Err(_)`, `Rgb(r, g, b)`). Refined payloads
  (`Ok(1)`) do **not** cover the variant. OR-patterns cover each alternative.
- **Catch-all** — `_`, or an identifier that is not a variant name, binds the
  whole subject. A `string` subject is an open domain: only a catch-all makes it
  exhaustive.
- **Guards** — a guarded arm may fail its guard, so it neither covers a variant
  nor shadows later arms.
- **Diagnostics** — `nonExhaustive` (lists the missing enum variants, or asks
  for a wildcard on an open domain) and `redundantPattern` (an arm after a
  catch-all, or a repeated variant, is unreachable).

## Children

- [`runtime/AGENTS.md`](runtime/AGENTS.md) — Node.js + Erlang external eval.

For the full 5-step `Aggregator` walk, type-system overview, and
unification rules see [`./docs.md`](docs.md). For comptime usage in
`.bp` source see [`./examples.md`](examples.md).

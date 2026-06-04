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
├── snapshot.zig       ← comptime snapshot helpers
├── stdlib/            ← std prelude loader — see stdlib/AGENTS.md
│   └── prelude.zig        ← @embedFile of libs/std/src/*.bp (std_prelude module root)
├── tests.zig          ← barrel: aggregates tests/<feature>.zig for test_root.zig
├── tests/             ← comptime tests, split by feature
│   ├── helpers.zig        ← shared harness (`assertComptimeAst`, `assertTypeErrorSnap`, …)
│   ├── infer_exprs.zig    ← literal/binary/case/control-flow inference
│   ├── infer_decls.zig    ← pub fn/record/struct/interface/implement inference
│   ├── infer_generics.zig ← typeparam & generic inference
│   ├── infer_errors.zig   ← inference type errors (`infer error: …`)
│   ├── types.zig          ← types / type_unification
│   ├── variants.zig       ← variant/record-update/pattern/@print/AST probes
│   ├── exhaustiveness.zig ← case exhaustiveness (+errors)
│   └── effects.zig        ← throw/context/@Result effect checking
└── runtime/           ← Node.js + Erlang eval backends — see runtime/AGENTS.md
```

## Files

| File | Role |
|---|---|
| `types.zig` | All type representations as `union(enum)`. |
| `env.zig` | Type environment — scopes, builtins + stdlib, `TypeDef.contextBase`, `FnContext`, and static-extension-dispatch tables (`extensions`, `activations`, `inherentMethods`, `dispatchRewrites`). |
| `infer.zig` | Main HM inference: `inferProgramTyped(...) → []TypedBinding`. `registerExtensions` pre-pass + `resolveReceiverCall` implement F6 static extension dispatch. Ends with `validateProgram` — `implement`/interface coverage + getter/setter type checks. |
| `unify.zig` | Unification with substitution + occurs check. |
| `error.zig` | Structured type errors with source ranges and hints (incl. `missingMethod`/`unknownMethod`/`unknownInterface`/`ambiguousMethod`). |
| `eval.zig` | Builds eval scripts, calls runtime, parses JSON results. |
| `render.zig` | Converts an evaluated comptime value into a target literal. |
| `specialize.zig` | Pure AST specialization — unroll loops, fold static if/case. |
| `transform.zig` | `Aggregator` — drives specialize + rewrite + inline + dead-code. |
| `snapshot.zig` | Snapshot helpers. |
| `tests.zig` | Barrel aggregating `tests/<feature>.zig`; harness in `tests/helpers.zig`. |

## Quick-reference testing helpers

```zig
try assertTypes(alloc, source, &.{ .{ "x", "i32" }, .{ "f", "fn(i32) i32" } });
try assertTypeErrorSnap(alloc, @src(), source);
```

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

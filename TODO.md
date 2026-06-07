# TODO — generic-inference

> Live checklist for branch `task/generic-inference` (worktree `.tasks/generic-inference/`).
> Spec (intent, immutable): [`tasks/v0.beta.3/specs/generic-inference.md`](tasks/v0.beta.3/specs/generic-inference.md)

> **Goal**: every call to a generic function gets a **fresh instantiation** of its
> `.generic` type vars (standard HM instantiation in `inferCallExpr`). Unblocks
> inline tests in generic std modules and is a prerequisite for `stdlib-interface`.

## F0 — Audit current flow ✅
- [x] Trace `inferCallExpr` for `identity(42)`: it looked up the raw fn type and
      passed `.generic` vars straight into `unifyAt` — no instantiation step
- [x] `types.zig` had no instantiate helper; `infer.zig` had `instantiateType`
      (ctor/std-export use) substituting `.unbound`+`.generic` indiscriminately
- [x] Entry points needing the fix: plain call (`env.lookup(callee)` path),
      pipeline call path, and identifier-as-value path in `inferIdentifierExpr`

## F1 — Implement per-call instantiation ✅
- [x] `instantiateGenericType(env, ty)` in `infer.zig`: standard HM instantiation —
      one substitution map across params + return, replaces only `.generic` vars
      with fresh `.unbound` (left `.unbound` shared). `instantiateType` gained an
      `InstantiateMode` so ctor/std-export paths keep `.allVars` behavior
- [x] `inferFnDecl` now generalizes: declared `<T>` params still unbound after the
      body become `.generic` (let-polymorphism), so each use site instantiates fresh
- [x] Applied at the plain-call, pipeline-call, and identifier-as-value sites
- [x] 2 regression tests in `infer_generics.zig` (two-calls-different-types,
      fn-referenced-as-value); 1010/1010 tests green

## F2 / F3 — superseded by `stdlib-interface`
The loose-function generic modules (`pair.bp`, `list.bp`, …) are being converted
to **interfaces** (`pair.d.bp`, `interface Array<T>`, …) under the
`stdlib-interface` spec — so adding inline `test` blocks to them is moot; their
surface moves to method syntax with its own tests. F1 (the actual fix) is the
deliverable here. Inline-test re-enablement is replaced by the interface
migration's per-phase test files.

## Notes
- Fix is purely `infer.zig` — no parser or AST changes.
- `unify.zig`'s `.generic` guard stays as a safeguard.
- `stdlib-interface` migration now proceeds on this branch (user decision
  2026-06-07: full migration here).

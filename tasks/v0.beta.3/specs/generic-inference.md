# Generic type instantiation — per-call-site fresh type variables

**Slug**: `generic-inference`
**Depends on**: nothing
**Files**: `modules/compiler-core/src/comptime/infer.zig` (primary: `inferCallExpr`), `modules/compiler-core/src/comptime/unify.zig`, `modules/compiler-core/src/comptime/types.zig`
**Touches docs**: `libs/std/AGENTS.md` (remove known-gap #6 note once fixed; inline tests can be added to generic modules)
**Status**: pending

## Problem

When `inferCallExpr` resolves a call to a generic function, it currently passes
the function's **raw type** (with `.generic` type vars) directly to `unifyAt`.
`unify.zig:55` rejects `.generic` immediately:

```zig
.generic => {
    // Generic vars should be instantiated before unification.
    env.lastError = TypeError.typeMismatch(ta, tb);
    return error.TypeError;
},
```

This causes two visible failures:

### 1 — Inline test blocks in generic stdlib modules

`registerStdlib` infers each module source (including `test { … }` blocks) in a
scratch env. If any test block calls a generic function (e.g. `insert(empty(),
"k", 0)` in `dict.bp`), `inferCallExpr` tries to unify `Dict<K_generic,
V_generic>` (the function's raw return type) against the call-site types. The
`.generic` vars throw `TypeError`, which propagates out of `registerStdlib` and
causes every `freshTestEnv` caller to fail — 39+ compiler tests cascade.

Current workaround: generic modules (`pair`, `list`, `iterator`, `dict`, `sets`,
`function`, `queue`) cannot carry inline test blocks. Only non-generic modules
(`bool`, `int`, `float`, `order`, `string`) have inline tests.

### 2 — Multiple calls to the same generic fn in one scope (known gap #6)

Even if a single call works (via some path that tolerates `.generic`), a second
call to the same generic function with a different concrete type fails because
the first call's resolution locks the type var to the first type. Example:

```bp
val a = identity(42);    // A locked to i32
val b = identity("hi");  // A = i32, arg = string → TypeError
```

## Target behavior

Every call to a generic function produces a **fresh instantiation**: a new set of
`.typeVar` substitution variables derived from the function's `.generic` params.
The fresh vars are unified with the argument types, propagated to the return type,
and discarded after the call expression is resolved. Two calls in the same scope
each get their own fresh vars and never conflict.

```bp
// Both work in the same scope; each call gets fresh A
val a = identity(42);    // fresh A1 unified with i32 → A1=i32
val b = identity("hi");  // fresh A2 unified with string → A2=string
```

```bp
// Works inside a registerStdlib test block
test "dict insert and lookup" {
    val d = insert(empty(), "key", 99);   // K=string, V=i32 from args
    assert lookup(d, "key").unwrapOr(0) == 99;
}
```

## Steps

### F0 — Audit current flow

- [ ] Trace `inferCallExpr` for a generic function call (e.g. `identity(42)`)
      from type lookup through `unifyAt` — document which line does (or skips)
      instantiation
- [ ] Confirm `types.zig` has (or lacks) an `instantiate(fn_type, env)` helper
      that replaces each `.generic` var with a fresh `.typeVar`
- [ ] Identify all call-path entry points that need the fix
      (`inferCallExpr`, `inferMethodCallExpr`, `inferPipelineExpr`)

### F1 — Implement per-call instantiation

- [ ] Add `instantiateGeneric(env, fn_type) -> FnType` to `types.zig`:
      walk the fn's param types and return type; replace each `.generic` var
      with a fresh `env.freshTypeVar()` (same substitution map reused across
      params + return so `fn(x: A) -> A` yields the same fresh var for both)
- [ ] Call `instantiateGeneric` at the top of `inferCallExpr`, before
      the `unifyAt` loop — operate on the instantiated copy, not the raw type
- [ ] Same patch for `inferMethodCallExpr` and pipeline call paths if they
      have independent unification loops

### F2 — Fix `registerStdlib` inline tests in generic modules

- [ ] Re-enable inline test blocks for `dict.bp`, `sets.bp`, `list.bp`,
      `iterator.bp`, `function.bp`, `queue.bp`, `pair.bp`
- [ ] Add 5–10 representative inline test blocks per module (constrain type vars
      via concrete literal arguments, not via separate `val` annotations)
- [ ] Remove the corresponding external `*_test.bp` files where inline blocks
      now cover the same surface (or keep both — inline = fast/local,
      external = qualified-import contract; decide per module)
- [ ] Update `libs/std/AGENTS.md`: remove the "inline tests only in
      non-generic modules" restriction note; update the tree + coverage table

### F3 — Snapshot + test coverage

- [ ] New snapshot: `codegen/node/commonJS/generic_fn_two_call_sites` —
      `identity(42)` then `identity("hi")` in same scope, both succeed
- [ ] New snapshot: `comptime/generic_instantiation_per_call` — verifies
      fresh vars, not shared vars, are used
- [ ] Run `zig build test` — confirm no regressions across all backends

## Test scenarios

```
comptime ---- generic fn: single call instantiates fresh vars
comptime ---- generic fn: two calls with different types in same scope
comptime ---- generic fn: inline test block in dict.bp resolved correctly
codegen/node ---- generic_fn_two_call_sites
```

## Notes

- The fix is purely in `infer.zig` / `types.zig` — no parser or AST changes.
- `unify.zig`'s `.generic` guard is correct as a safeguard; instantiation should
  happen before `unify` is ever called with a `.generic` var.
- When a generic function is defined in the same file (not in stdlib), the same
  instantiation path must work — not stdlib-specific.
- Stdlib functions use `.generic` vars because they're registered once into the
  global env. Each call site must get fresh `.typeVar` copies via instantiation.
- After this fix, the inline test limitation noted in `libs/std/AGENTS.md` (and
  `stdlib-gleam` known gap #6) is resolved and should be removed from both.
- `expr-templates` comptime expansion calls generic functions internally;
  this fix is a prerequisite for expr-templates to work correctly.

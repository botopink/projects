# stdlib-backends-parity — finish beam/wasm lowering + dispatch + literal-receiver codegen

**Slug**: stdlib-backends-parity
**Depends on**: nothing (the JS path, A1 **erlang** lowering, A3 method-body inference, and the literal-receiver **parser** all landed in `feat`)
**Files**: `modules/compiler-core/src/codegen/beam_asm.zig`, `modules/compiler-core/src/codegen/wat.zig`, `modules/compiler-core/src/codegen/erlang.zig`, `modules/compiler-core/src/comptime/infer.zig`, `modules/compiler-core/src/comptime/env.zig`
**Touches docs**: `modules/compiler-core/src/codegen/AGENTS.md`, `modules/compiler-core/src/comptime/AGENTS.md`
**Status**: pending

> The open remainder of v0.beta.7 `stdlib-backends-parity`. Pure
> language/stdlib/backend work — **no** framework knowledge — so it parallels every
> lib spec in this set. Stdlib coupling in the core is allowed (std is the embedded
> standard library); this spec de-couples nothing.

## Context — what already landed (v0.beta.7)

- **A1 erlang** value-receiver instance/associated-method lowering (record/enum/
  struct methods bind `self`; `instanceLowerings` loc-keyed table; Array/String
  prim lowering; enum-case atoms). `std_erlang.sh` `order` 3/3 green.
- **A3** method / `default fn` body inference (`inferTypeMethods`); generic-
  extends-generic resolves through the existing machinery.
- **Literal-receiver parser** (`parsePostfixChain`, `3b514a7`): `[1,2].map(f)` /
  `"x".contains(y)` parse and chain off literals — **codegen** still pending (F1).
- **F6** duplicate test-name warning.

What remains is **beam/wasm** lowering, the `@[external]` associated fns, and the
Part B codegen tails.

## Target syntax

No new surface. The same `.bp` that runs on `commonJS`/`erlang` must produce
equivalent output on `beam`/`wasm`:

```bp
val xs = [1, 2, 3];
val n = xs.map({ x -> x * 2 }).filter({ x -> x > 2 }).len();   // instance methods
val m = [1, 2].map(f).len();                                   // LITERAL receiver
val r = Array.range(0, 3);                                     // @[external] associated fn
val name = user?.profile?.name;                                // optional chaining
```

## Steps

### A1b — mirror the method lowering on beam + wasm
- [ ] Port the instance/associated-method lowering (Array/Bool/numeric tower/
      String + `Pair.of`/`Function.compose`) from `erlang.zig` to `beam_asm.zig`
      and `wat.zig` (they still emit the old value-receiver form for primitives).
- [ ] Extend `std_erlang.sh` parity (`dict`/`queue`/`sets`/`erika`) — close the
      remaining blockers: structural `==`/`!=` on tuples/maps, `?T` option chaining
      through method results, erika `case … of` codegen + LINQ inference gaps.

### A2 (remainder) — `@[external]` associated fns
- [ ] `Array.range`/`Array.repeat` and the other `@[external]` associated fns lower
      on every backend; ship the companion host modules (`primitives.mjs`/`.erl`).

### B — backend-parity tails
- [ ] **F1** literal method receivers reach **codegen** on every backend (parser
      done; thread the loc-keyed lowering for a literal receiver through each
      emitter).
- [ ] **F2** snake_case→camelCase dispatch normalization (legacy `to_string` →
      `toString`, etc.). Memory: [[feedback_camelcase_naming]].
- [ ] **F3** erlang/beam load the std modules the same way node does (erlang
      partial; beam pending).
- [ ] **F4** `?.` optional-chaining codegen on **beam/wasm** (commonJS + erlang
      done).
- [ ] **F5** wasm test runner (`wasmtime`) so `botopink test` runs on the wasm
      target (`test_cmd` currently gates to commonJS/erlang).

## Test scenarios

```
codegen/beam ---- array map/filter/len chain lowers + runs (parity with node/erlang)
codegen/beam ---- Array.range(0,3) lowers to the host external + runs
codegen/wasm ---- u?.v?.w optional chain guards on undefined
codegen/*    ---- [1,2].map(f).len() (literal receiver) reaches codegen on every backend
infer        ---- legacy to_string normalizes to toString dispatch
run          ---- std_erlang.sh green for order/dict/queue/sets
test         ---- the wasm runner executes a test module (wasmtime)
```

## Notes

- Backend-parity only — no new language surface; `commonJS`/`erlang` are the
  reference behaviour. Where a backend genuinely can't match (e.g. wasm
  single-module), **record the limit** rather than fake it.
- Parallel-safe with the lib specs (touches the codegen emitters + stdlib/dispatch
  regions of `infer.zig`, not the loader/decorator machinery). A late merge near
  the same `infer.zig` lines resolves as the consolidations have before. Memory:
  [[project_stdlib_backends_parity]], [[reference_worktree_merge_param_threading]].
- The `erika` LINQ blockers on erlang (structural equality, option chaining,
  `case … of`) are the long-pole of A1b — they also unblock erika on the beam.

# stdlib-backends-parity — finish the non-JS backends + dispatch + inference

**Slug**: stdlib-backends-parity
**Depends on**: nothing (the JS path + Part C tooling + A2 `s.contains` already in `feat`)
**Files**: `modules/compiler-core/src/codegen/erlang.zig`, `modules/compiler-core/src/codegen/beam_asm.zig`, `modules/compiler-core/src/codegen/wat.zig`, `modules/compiler-core/src/comptime/infer.zig`, `modules/compiler-core/src/comptime/env.zig`, `modules/compiler-core/src/parser/*` (literal method receivers)
**Touches docs**: `modules/compiler-core/src/codegen/AGENTS.md`, `modules/compiler-core/src/comptime/AGENTS.md`
**Status**: pending

> The open remainder of v0.beta.6's `stdlib-backends-and-tooling` after Part C
> (editor tooling) and Part A2 (`s.contains`→native `includes`) landed in `feat`.
> Pure language/stdlib/backend work — **no** framework knowledge, so it parallels
> `annotation-processors` (different files / different regions of `infer.zig`).

## Target syntax

No new surface. The same `.bp` that runs on `commonJS` today must produce
equivalent output on `erlang`/`beam`/`wasm`:

```bp
val xs = [1, 2, 3];
val n = xs.map({ x -> x * 2 }).filter({ x -> x > 2 }).len();   // instance methods
val r = Array.range(0, 3);                                     // associated/@[external] fn
val name = user?.profile?.name;                                // optional chaining
```

## Steps

### A1 — mirror JS instance/associated-method lowering on the other backends
- [ ] Port the instance-method + associated-method lowering already done for
      `commonJS` (Array/Bool/numeric tower/String + `Pair.of`/`Function.compose`)
      to `erlang.zig`, `beam_asm.zig`, `wat.zig`.
- [ ] Make the `std_erlang.sh` suite green (parity with the node suite).

### A2 (remainder) — `@[external]` associated fns
- [ ] `Array.range`/`Array.repeat` and the other `@[external]` associated fns lower
      on every backend; ship the companion host modules (`primitives.mjs`/`.erl`).

### A3 — inference correctness
- [ ] Type-check `default fn` bodies (not just signatures).
- [ ] Handle generic-extends-generic (`implement Foo<A> for Bar<A>`).
- [ ] Parse + infer literal method receivers (`[1,2].map(...)`, `"x".contains(...)`)
      where the receiver is a literal, not a binding.

### B — backend-parity F1–F6 (carried from v0.beta.3)
- [ ] F1 literal method receivers reach codegen on every backend.
- [ ] F2 snake_case→camelCase dispatch normalization (legacy `to_string` etc.).
- [ ] F3 erlang/beam load the std modules the same way node does.
- [ ] F4 `?.` optional-chaining codegen on erlang/beam/wasm (commonJS done).
- [ ] F5 wasm test runner (`wasmtime`) so `botopink test` runs on the wasm target.
- [ ] F6 duplicate test-name warning.

## Test scenarios

```
codegen/erlang ---- array map/filter/len chain lowers + runs (parity with node)
codegen/beam   ---- Array.range(0,3) lowers to the host external + runs
codegen/wasm   ---- u?.v?.w optional chain guards on undefined
infer          ---- a default fn body type-checks (a wrong body is an error)
infer          ---- implement Foo<A> for Bar<A> resolves
run            ---- std_erlang.sh is green (backend parity with the node suite)
test           ---- duplicate test name emits a warning; wasm runner executes tests
```

## Notes

- Parallel-safe with `annotation-processors`: this touches the codegen emitters +
  the stdlib/dispatch regions of `infer.zig`, not the decorator/loader machinery.
  If both land near the same `infer.zig` lines, the later merge resolves it (as
  the v0.beta.6 consolidation already did).
- Backend-parity only — no new language surface; `commonJS` is the reference
  behaviour. Where a backend genuinely can't match (e.g. wasm single-module),
  record the limit rather than fake it (cf. `cross-module-codegen`).
- Stdlib coupling in the core is allowed (std is the embedded standard library);
  this spec does **not** de-couple anything — that is `annotation-processors`'
  job for the *non-std* libs.

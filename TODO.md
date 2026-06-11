# TODO — stdlib-backends-parity  (backends · Wave 2 of 3)

> Task branch `task/stdlib-backends-parity` · spec
> [`tasks/v0.beta.10/specs/stdlib-backends-parity.md`](tasks/v0.beta.10/specs/stdlib-backends-parity.md).
> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test (no `--no-verify`).
> **Depends on:** nothing (JS path, A1 erlang lowering, A3 method-body inference, the
> literal-receiver parser all landed in `feat`). **Coordination:** touches
> `infer.zig` + the 3 codegen emitters — same files as `cross-module-codegen` (and
> `effect-annotations`); different regions (stdlib/dispatch lowering vs cross-package
> index), but **sequence the merges**. Backend-parity only — no new surface;
> commonJS/erlang are the reference; record genuine backend limits, don't fake them.

## A1b — mirror the method lowering on beam + wasm
- [ ] Port instance/associated-method lowering (Array/Bool/numeric tower/String +
      `Pair.of`/`Function.compose`) from `erlang.zig` to `beam_asm.zig` + `wat.zig`;
      the `forEach`-accumulator → fold fusion idiom too (closures can't rebind
      captures).
- [ ] Extend `dict`/`queue`/`sets`/`erika` parity on beam — structural `==`/`!=` on
      tuples/maps, `?T` option chaining through method results, erika `case … of`
      codegen + LINQ inference gaps (the long pole, also unblocks erika on beam).

## A2 (remainder) — `#[@external]` associated fns
- [ ] `Array.range`/`Array.repeat` + other `#[@external]` associated fns lower on
      every backend; ship companion host modules (`primitives.mjs`/`.erl`). Closes
      the `examples/erika-linq` `Array.range` cross-module workaround.

## B — backend-parity tails
- [ ] **F1** literal method receivers reach **codegen** on every backend (parser
      done; thread the loc-keyed lowering through each emitter).
- [ ] **F2** snake_case→camelCase dispatch normalization (legacy `to_string` →
      `toString`).
- [ ] **F3** erlang/beam load the std modules the same way node does (erlang
      partial; beam pending).
- [ ] **F4** `?.` optional-chaining codegen on **beam/wasm** (commonJS+erlang done).
- [ ] **F5** wasm test runner (`wasmtime`) so `botopink test` runs on wasm.

## Done gate
- [ ] beam: array map/filter/len chain + `Array.range(0,3)` lower and run (parity
      with node/erlang); wasm: `u?.v?.w` guards on undefined; literal receiver
      `[1,2].map(f).len()` reaches codegen on every backend; `to_string` normalizes
      to `toString`; the wasm runner executes a test module.
- [ ] `zig build && zig build test` green.

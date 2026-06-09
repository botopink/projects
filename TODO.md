# TODO — stdlib-backends-parity

> Task branch `task/stdlib-backends-parity` · spec
> [`tasks/v0.beta.7/specs/stdlib-backends-parity.md`](../../tasks/v0.beta.7/specs/stdlib-backends-parity.md).
> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test.
> Independent / parallel-safe with `annotation-processors`. No framework knowledge;
> stdlib coupling in the core is allowed (this spec de-couples nothing).

## A1 — mirror JS instance/associated-method lowering on the other backends
- [ ] Port commonJS instance + associated-method lowering (Array/Bool/numeric/
      String + `Pair.of`/`Function.compose`) to `erlang.zig`, `beam_asm.zig`, `wat.zig`.
- [ ] `std_erlang.sh` suite green (parity with the node suite).

## A2 (remainder) — `@[external]` associated fns
- [ ] `Array.range`/`Array.repeat` + other `@[external]` associated fns lower on
      every backend; ship companion host modules (`primitives.mjs`/`.erl`).

## A3 — inference correctness
- [ ] Type-check `default fn` bodies (not just signatures).
- [ ] Generic-extends-generic (`implement Foo<A> for Bar<A>`).
- [ ] Parse + infer literal method receivers (`[1,2].map(...)`, `"x".contains(...)`).

## B — backend-parity F1–F6
- [ ] F1 literal method receivers reach codegen on every backend.
- [ ] F2 snake_case→camelCase dispatch normalization.
- [ ] F3 erlang/beam load std modules the way node does.
- [ ] F4 `?.` optional-chaining codegen on erlang/beam/wasm.
- [ ] F5 wasm test runner (`wasmtime`) so `botopink test` runs on wasm.
- [ ] F6 duplicate test-name warning.

## Done gate
- [ ] `zig build && zig build test` green; `std_erlang.sh` green.
- [ ] `codegen/AGENTS.md` + `comptime/AGENTS.md` updated.

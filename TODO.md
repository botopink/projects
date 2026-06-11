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
- [~] **beam** instance-method lowering: `instance_lowerings` threaded into
      `beam_asm.zig`; `emitPrimMethod` lowers Array `map`/`filter`/`forEach`/
      `reverse`/`contains`/`len` + String `length`/`toUpper`/`toLower`/`trim`/
      `split`/1-arg `slice` to `call_ext` (`lists:`/`erlang:`/`string:`). Verified
      end-to-end: `[1,2,3].map(f).filter(g).len()` assembles + runs `2` (parity
      with node/erlang). Also fixed a pre-existing arity-0 array-literal bug
      (`[Elem|Elem]` improper lists). **Pending:** the inline-fun / arithmetic /
      structural-compare methods (`join`/`indexOf`/`at`/`isEmpty`/2-arg `slice`/
      `append`/`prepend`/`push`/`string contains`), fold-fusion, and **wasm**.
- [ ] Extend `dict`/`queue`/`sets`/`erika` parity on beam — structural `==`/`!=` on
      tuples/maps, `?T` option chaining through method results, erika `case … of`
      codegen + LINQ inference gaps (the long pole, also unblocks erika on beam).

## A2 (remainder) — `#[@external]` associated fns
- [ ] `Array.range`/`Array.repeat` + other `#[@external]` associated fns lower on
      every backend; ship companion host modules (`primitives.mjs`/`.erl`). Closes
      the `examples/erika-linq` `Array.range` cross-module workaround.

## B — backend-parity tails
- [x] **F1** literal method receivers reach **codegen** on every backend: the
      loc-keyed `instance_lowerings` dispatch keys off the call loc regardless of
      receiver kind, so `[1,2,3].map(f).len()` runs on beam (`3`) + erlang, and
      commonJS now emits the `.length` PROPERTY for `arr.len()`/`.size()`/`.length()`
      + `str.length()` (inference records a type-gated `length` rename;
      `lowerExpr` skips call parens for it) — verified `3`/`3`/`5` on node.
- [~] **F2** snake_case→camelCase dispatch: primitives.d.bp already uses camelCase
      (`toString` maps to the host `to_string` SYMBOL); the related parity gap was
      `arr.len()`/`size()` on commonJS, now fixed (see F1). Legacy user-side
      `to_string()` normalization not separately needed (no such call surfaced).
- [ ] **F3** erlang/beam load the std modules the same way node does (erlang
      partial; beam pending).
- [~] **F4** `?.` optional-chaining codegen: **beam DONE** (`lowerIdentAccess`
      guards on `{atom, undefined}` with `is_eq`, short-circuits + chains; present
      path runs, parity erlang/node). **wasm**: records aren't laid out by name in
      linear memory (pre-existing gap), so `?.` can't be realized — recorded as a
      genuine backend limit (`;; (unsupported on wasm)`), not faked.
- [ ] **F5** wasm test runner (`wasmtime`) so `botopink test` runs on wasm.

## Done gate
- [ ] beam: array map/filter/len chain + `Array.range(0,3)` lower and run (parity
      with node/erlang); wasm: `u?.v?.w` guards on undefined; literal receiver
      `[1,2].map(f).len()` reaches codegen on every backend; `to_string` normalizes
      to `toString`; the wasm runner executes a test module.
- [ ] `zig build && zig build test` green.

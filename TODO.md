# TODO — stdlib-backends-parity  (backend · Wave 1)

> Task branch `task/stdlib-backends-beam` · spec
> [`tasks/v0.beta.8/specs/stdlib-backends-parity.md`](../../tasks/v0.beta.8/specs/stdlib-backends-parity.md).
> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test (no `--no-verify`).
> **Depends on: nothing.** Start now. The one core/std-touching strand; stdlib coupling
> in the core is allowed.
>
> ⚠ Touches `comptime/infer.zig` — same file as `generic-loader-binding` (different
> regions: stdlib/dispatch inference vs import binding; the later merge resolves it,
> like the v0.beta.7 typeDeclRegistry/decoratorRegistry overlap).

## A1b — mirror the method lowering on beam + wasm
- [ ] Port the instance/associated-method lowering (Array/Bool/numeric tower/String +
      `Pair.of`/`Function.compose`) from `erlang.zig` to `beam_asm.zig` and `wat.zig`
      (they still emit the old value-receiver form for primitives). NB: the
      `forEach`-accumulator → `lists:foldl` fusion is erlang-only so far; beam/wasm
      need the same idiom (their closures can't rebind captured vars either).
- [x] **`std_erlang.sh` green for `dict`/`queue`/`sets`** (31/31, was 9/31). Two fixes:
      (1) parser per-link loc collision (`self.pairs.length` → `length(length(Self))`),
      committed in `566e927`; (2) `forEach`-accumulator fold fusion + `join` element
      stringification, committed in `ec7d895`. `erika`/LINQ still blocked (`?T` option
      chaining through chained method results + `case … of` codegen + LINQ inference).
      Note: erlang `==`/`!=` is `=:=`/`=/=`, already structural on tuples/maps/lists.

## A2 (remainder) — `@[external]` associated fns
- [ ] `Array.range`/`Array.repeat` + the other `@[external]` associated fns lower on
      every backend; ship companion host modules (`primitives.mjs`/`.erl`).
      (NB: `examples/erika-linq` had to avoid `Array.range` cross-module — this closes it.)

## B — backend-parity tails
- [ ] **F1** literal method receivers reach **codegen** on every backend (parser done;
      thread the loc-keyed lowering for a literal receiver through each emitter).
- [ ] **F2** snake_case→camelCase dispatch normalization (legacy `to_string` → `toString`).
- [ ] **F3** erlang/beam load std modules the way node does (erlang partial; beam pending).
- [ ] **F4** `?.` optional-chaining codegen on **beam/wasm** (commonJS + erlang done).
- [ ] **F5** wasm test runner (`wasmtime`) so `botopink test` runs on wasm.

## Done gate
- [ ] beam map/filter/len chain + `Array.range` run (parity with node/erlang).
- [ ] wasm `?.` guards; literal receivers codegen on every backend.
- [x] `std_erlang.sh` green for order/dict/queue/sets (31/31). wasm runner still pending.
- [~] `codegen/AGENTS.md` updated (erlang fold-fusion + join). `comptime/AGENTS.md`
      pending (no infer change yet). `zig build && zig build test` green.

## Notes
- Backend-parity only — `commonJS`/`erlang` are the reference. Record limits (e.g. wasm
  single-module) rather than fake them.

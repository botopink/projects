# primitive-interface-default-fns — emit Array/String/Bool/numeric instance default fns on erlang + beam

**Slug**: primitive-interface-default-fns
**Depends on**: [`generic-inference-foundation`](generic-inference-foundation.md)
  (consumes `instance_lowerings[loc] = .prim{<kind>}` produced by F1).
**Files**: `modules/compiler-core/src/codegen/{erlang,beam_asm}.zig` ·
  new `modules/compiler-core/src/codegen/tests/primitive_interface_default_fns.zig`
  · snapshots under `modules/compiler-core/snapshots/codegen/`
**Touches docs**: `modules/compiler-core/src/codegen/AGENTS.md` (the
  erlang + beam_asm Remaining-gaps rows narrow significantly)
**Status**: pending

## Background

v0.beta.19's frente-a-compiler §B4 was deferred because its closure
requires the keystone above (Self primitive kind resolution). The
erlang + beam `emitInterface` paths today skip instance `default fn`s
(those with `self` as first param) — see `codegen/erlang.zig:3090`
"Instance default fns (with `self`) are a separate gap, not emitted
here."

Concrete user-visible symptom (`zig build test-libs --lib erika
--target erlang`):

```
.botopinkbuild/test-out/erika.erl:90:  function drop/2 undefined
.botopinkbuild/test-out/erika.erl:95:  function forEach/2 undefined
.botopinkbuild/test-out/erika.erl:249: function fold/3 undefined
```

These are calls to Array's instance `default fn`s (`drop`/`forEach`/
`fold`) inside erika's pure-bp methods. Once `Self` resolves to
Array<T> via the keystone, the bodies become emittable as plain
local fns on erlang + beam.

## Checklist

- [ ] **F1-erlang** — Extend `emitInterface` in `codegen/erlang.zig`
      to also emit instance default fns (`has_self == true`) as bare
      local functions named after the method. For methods carrying
      an `@external(erlang, …)` annotation, skip the local definition
      (the host-backed template wins via `emitPrimMethod` at the call
      site). Also walk `prelude.primitives` so the primitive
      interfaces (Array/String/Bool/numeric) join the per-module
      emission pass even though they aren't in `program.decls`.
- [ ] **F1-beam** — Mirror on `codegen/beam_asm.zig` with BEAM ASM
      label reservation (`reserveFn` for each new local) and body
      emission (`emitFn` reuses the standard expr pipeline since the
      body is pure botopink — closures, prim calls, branches, val
      bindings all already lower correctly). Validate against
      `erlc +from_asm` by reassembling every touched snapshot.
- [ ] **F2-test** — `tests/codegen/primitive_interface_default_fns.zig`:
      one fixture per backend that exercises every now-emitted method
      (Array's `drop`/`take`/`fold`/`find`/`count`/`all`/`any`/`first`/
      `rest`/`contains` on Array<i32>; String's analogues). Assert the
      emitted code + run end-to-end under node / escript / `erlc
      +from_asm; erl`.
- [ ] **F3-libs** — `zig build test-libs` flips erika / jhonstart /
      onze / rakun rows green on the erlang column. Confirm
      `zig build test-libs --target beam` (once the wasm-test-runner
      spec lands beam-test support) also green.
- [ ] **F4-docs** — `codegen/AGENTS.md` `erlang.zig` + `beam_asm.zig`
      Remaining-gaps rows drop the "instance default fns not
      emitted" entry and the "(also broken on Erlang)" qualifier on
      every method now covered.

## Test scenarios

```
F1-erlang ---- drop/2, forEach/2, fold/3 (+ the rest) emit as bare
                local fns in every consuming erlang module; bodies
                cascade through emitPrimMethod for host calls.
                Snapshots regen byte-clean.
F1-beam   ---- same set emits as BEAM ASM labels; `erlc +from_asm`
                assembles + `erl` runs the snapshot fixtures.
F3-libs   ---- the 4 lib reds (erika/jhonstart/onze/rakun) flip green
                on erlang via `zig build test-libs`.
```

## Notes

- Memory `project_stdlib_backends_parity` already pins this as the
  remaining backend-parity work for v0.beta.19+.
- **No `--no-verify`**; **SSH for git**; **AGENTS.md in the same
  commit**.
- This spec does **not** introduce new prim methods — only emits the
  existing default fn bodies. New prim methods land via
  [`prim-op-template-instance-methods`](prim-op-template-instance-methods.md).

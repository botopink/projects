# generic-inference-foundation — Self primitive kind resolution + generic var instantiation

**Slug**: generic-inference-foundation
**Depends on**: nothing in v0.beta.20 — file-disjoint with every other
  v0.beta.20 spec at the source level.
**Files**: `modules/compiler-core/src/comptime/{infer,unify,types}.zig`
  · `libs/std/src/{order,sets,dict,queue}.bp` (re-fold external inline
  tests) · `libs/std/AGENTS.md` · new
  `modules/compiler-core/src/comptime/tests/inference.zig`
**Touches docs**: `libs/std/AGENTS.md` ·
  `modules/compiler-core/src/comptime/AGENTS.md`
**Status**: pending

## Background

`instance_lowering` in `comptime/infer.zig` is the bridge between
inference's typed tree and codegen's per-backend emitter. When `Self`
inside a primitive interface `default fn` body can't be resolved to
the call-site receiver's primitive kind, the body's nested method
calls (`self.slice(…)`, `self.forEach(…)`) never get tagged with
`instance_lowerings[loc] = .prim{<kind>}` — so codegen falls through
to bare local calls that resolve to nothing on erlang/beam.

This is the keystone deferred from v0.beta.19's frente-a-compiler
§B1+B2+B5. It unblocks the companion
`primitive-interface-default-fns` spec (which emits the default fn
bodies as local mangled fns on erlang/beam) AND the
`typed-method-dispatch` spec (which tags local-record method calls
with `.record{TypeName}` via the same dispatch infrastructure).

Memory `project_generic_inference_gap` recorded this gap originally
in v0.beta.3 planning; v0.beta.19 surfaced four lib-test reds
(erika/jhonstart/onze/rakun on erlang) blocked on this fix.

## Checklist

- [ ] **F1** — Resolve `Self`'s primitive kind inside an interface
      `default fn` body. In `comptime/infer.zig` `instance_lowering`,
      when the enclosing interface is a primitive (Array/string/
      numeric/Bool — known via `primitiveInterfaceName`), substitute
      `Self`'s kind from the call-site receiver before re-typing the
      body. Records the resolved kind in
      `instance_lowerings[<callsite-loc>] = .prim{<kind>}` so every
      codegen consumer (`emitPrimMethod` on erlang/beam, the
      prototype patcher on commonJS, the wat layout pass) sees the
      tag.
- [ ] **F2** — Instantiate callee generic vars before `unifyAt` so a
      generic inline `test { … }` re-uses the module's `<T>` for the
      test's local bindings. Then fold the externalised `*_test.bp`
      shadow files back to inline `test` blocks inside `order.bp` /
      `sets.bp` / `dict.bp` / `queue.bp`.
- [ ] **F3** — Drop the generic-module inline-test caveat in
      `libs/std/AGENTS.md`; add inference unit tests for F1/F2 in a
      new file `modules/compiler-core/src/comptime/tests/inference.zig`.
- [ ] **F4** — Update `modules/compiler-core/src/comptime/AGENTS.md`
      to document the `instance_lowerings` `.prim` variant and the
      Self-resolution pass.

## Test scenarios

```
F1   ---- erika Array.drop default fn body typechecks under inference;
          commonJS still green; the dump for `xs.drop(n)` shows
          `instance_lowerings[loc] = .prim{.array}`.
F2   ---- order/sets/dict/queue inline `test { … }` blocks all green
          on commonJS+erlang; the shadow `*_test.bp` files are deleted
          from the repo.
F3+F4 -- comptime/tests/inference.zig: every F1/F2 case lands as a
          unit test (no shell, no codegen — pure infer); AGENTS.md
          Self-resolution row authored.
```

## Notes

- **No `--no-verify`.** Every commit through pre-commit (zig build +
  test + per-lib `botopink test`).
- **SSH for git remote ops** (memory `feedback_always_ssh_git`).
- **AGENTS.md in the same commit as the code** (memory
  `feedback_agents_md_maintenance`).
- The cross-primitive-method routing inside default fn bodies (e.g.
  `drop` calls `self.slice` which itself routes via
  `prim_erlang_dispatch`) is implicit in F1 — once the receiver is
  tagged `.prim{.array}` the existing `emitPrimMethod` switch handles
  the call. The companion spec
  `primitive-interface-default-fns` covers the emission side.

# prim-op-template-instance-methods — extend `@external` template to instance methods on every backend

**Slug**: prim-op-template-instance-methods
**Depends on**: nothing in v0.beta.20 — file-disjoint with every other
  v0.beta.20 spec at the source level. (Honest discovery during
  v0.beta.19 §A7: the gate is not BEAM bytecode templates as
  originally framed — it's that NO backend's codegen consumes
  `@external(<backend>, "<template>")` for instance methods today.
  This spec fills that gap on all 4.)
**Files**: `modules/compiler-core/src/codegen/{commonJS,erlang,beam_asm,wat}.zig`
  (annotation consumer for instance methods) · `libs/std/src/primitives.d.bp`
  (new method authored via 1 annotation per backend) · new
  `modules/compiler-core/src/codegen/tests/primitive_methods_byte_identical.zig`
**Touches docs**: `modules/compiler-core/src/codegen/AGENTS.md` ·
  `modules/compiler-core/src/comptime/AGENTS.md` ·
  `libs/std/AGENTS.md`
**Status**: pending

## Background

The `prim-op-annotation` keystone (v0.beta.19 satellite) landed
dispatch-table support for **associated** prim methods (no `self`
receiver — `Array.range`, `Pair.of`). Adding a new **instance**
method (`xs.zip(ys)`) via one `#[@external]` per backend was the
explicit goal of v0.beta.19's §A7, but the attempt revealed that
no backend's codegen consumes `@external(<backend>, "<template>")`
for instance method calls — the prototype patchers on commonJS and
the call-site emitters on erlang/beam/wat all assume host-symbol
form (`mod.symbol` / `module:symbol`), not `$`-marker template
form.

Once each backend's instance-method emitter learns to render a
template (`primOpTemplate.render` already exists — just route to
it), adding `Array.zip` (or any future method) is **one** annotation
per backend in `primitives.d.bp` + a test fixture.

This is the pattern that lets the language ship new prim methods at
zero `.zig` cost going forward — a strict generalisation of the §A
keystone refactor from v0.beta.19.

## Checklist

- [ ] **F1-commonJS** — Extend the prototype patcher in
      `codegen/commonJS.zig` so an interface `fn` (not `default fn`)
      carrying `@external(node, "<template>")` patches
      `<Owner>.prototype.<method>` with a JS body rendered via
      `primOpTemplate.render` (`$self → this`, `$N → arguments[N]`,
      `$args → ...arguments`).
- [ ] **F2-erlang** — At the call site in `codegen/erlang.zig`,
      `recv.method(args)` whose method is an annotated instance
      template renders the body inline. `tryEmitPrimAnnotation`
      already runs for receiver `.prim`-tagged calls; extend it to
      also recognise non-`default fn` instance methods (the existing
      iteration over `i.methods` filters out non-default — drop
      that filter and gate by "method has `@external(erlang, "<template>")`"
      instead).
- [ ] **F3-beam** — Same as F2 on `codegen/beam_asm.zig`. The
      `tryEmitPrimAnnotation` path already routes to
      `primRecvOnly` / `primFunThenList` / `primRecvThenArgs` based
      on the template shape — extend to read instance-method
      annotations alongside default-fn ones.
- [ ] **F4-wat** — Same on `codegen/wat.zig`. Simple
      `(local.get $self) ... call $...` shapes ship here. Inline-fun
      shapes (the `iolist_to_binary(lists:join(...))` family) are
      not portable to wasm without compile-time AST work — record
      as a known gap in the AGENTS row and route those to the
      [`beam-inline-prim-methods`](beam-inline-prim-methods.md) spec
      for the BEAM equivalent.
- [ ] **F5-array-zip** — `Array.zip<U>(self: Self, other: U[]) ->
      Array<#(T, U)>` lands in `primitives.d.bp` with ONE annotation
      per backend. Suggested templates:
      - commonJS: `$self.map((__x, __i) => [__x, ($0)[__i]]).slice(0, Math.min($self.length, ($0).length))`
      - erlang: `lists:zipwith(fun(__X, __Y) -> {__X, __Y} end, lists:sublist($self, length($0)), lists:sublist($0, length($self)))`
      - beam: same shape (template-driven)
      - wat: deferred — log as known gap (no native zip in wat; needs
        a generated helper which is out of scope here).
- [ ] **F6-test** — `primitive_methods_byte_identical.zig`: compile a
      fixture using `xs.zip(ys)` on each backend and assert the
      emitted code shape **without editing any `.zig`** in the
      lowering paths. F4's wat deferral keeps the test 3-of-4 there.

## Test scenarios

```
F5-erlang ---- `[1,2,3].zip(["a","b","c"])` emits the
                `lists:zipwith(fun(__X,__Y)->{__X,__Y} end, ...)`
                shape; runs under escript → `[{1,<<"a">>},{2,<<"b">>},{3,<<"c">>}]`.
F5-node    ---- same fixture on node emits the `$self.map((__x, __i)
                => [__x, ($0)[__i]])...` form; runs → `[[1,"a"],[2,"b"],
                [3,"c"]]`.
F5-beam    ---- same template renders at register level via
                `tryEmitPrimAnnotation`; `erlc +from_asm` assembles
                + the result matches the erlang fixture.
F6         ---- the test fixture compiles on 3+ targets with ZERO
                .zig edits in the codegen lowering paths.
```

## Notes

- **Template grammar** lives in `comptime/primOpTemplate.zig` (markers
  `$self` / `$0..N` / `$args`); this spec only adds **consumer**
  sites in the per-backend emitters.
- **No `--no-verify`**; **SSH for git**; **AGENTS.md in the same
  commit**.
- Future prim methods (`Array.chunks`, `String.repeat`,
  `Array.partition`) follow the same pattern.

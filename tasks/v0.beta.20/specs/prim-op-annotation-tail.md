# prim-op-annotation-tail — finish §A2 four-backend story (BEAM + wat)

**Slug**: prim-op-annotation-tail
**Depends on**: `std-expansion-tail` §A2 commonJS + erlang twin
  (`a7c6d07` + `52d6101`); `prim-op-annotation` v0.beta.19 partial
  close (`64a3436` — Family 1 9/19 erlang done, BEAM/commonJS/wat
  deferred).
**Files**:
- `modules/compiler-core/src/codegen/beam_asm.zig` (`user_beam_templates` +
  `tryEmitUserTemplate` mirroring the commonJS/erlang shape).
- `modules/compiler-core/src/codegen/wat.zig` (template dispatch + emitter
  context for the wat instruction encoder).
- `libs/std/src/primitives.d.bp` (BEAM/wat external annotations on the
  15 §A6-deferred methods + the 4 inline BEAM allow-list arms).
- `tests/codegen/prim_op_chained_beam.zig` + `tests/codegen/prim_op_chained_wat.zig`
  (new fixtures pinning each backend's chained-template behaviour).
**Touches docs**: `libs/std/AGENTS.md` "Per-target reach (today)" row
  (4/4 backends), `modules/compiler-core/src/codegen/AGENTS.md`
  (Remaining gaps roll), `CHANGELOG.md`.
**Status**: pending

## Premise

`std-expansion-tail` landed the §A2 per-callee template dispatch on
the commonJS + erlang backends:

- `Emitter.user_node_templates` / `Emitter.user_erlang_templates` —
  populated from `collectExternals` when the annotation symbol is a
  `$`-bearing template or carries `when(argc == N)` branches.
- `tryEmitUserTemplate(callee, cc)` — renders inline at the call site
  via `primOpTemplate.render`.
- Decl emit skips the `const fn = recv.method;` (commonJS) /
  `:module:symbol(args)` (erlang) alias path; the template renders
  per call site.

The remaining backends — BEAM bytecode and wat (WebAssembly text) —
keep the inline allow-list switch arms that `prim-op-annotation`
v0.beta.19 deferred (memory `project_v0beta19_prim_op_annotation`:
"4 inline arms + BEAM/commonJS/wat deferred"). For BEAM the deferral
was the right call at the time — 3/4 backends viable without it — but
the `std-expansion-tail-followup` adds new chained-host-call surfaces
(`fs`, `http`, `json`) that BEAM's inline switch can't reach without
re-authoring every method. The cleaner path is the §A2 twin: register
the templates once in `collectExternals` and let the shared renderer
walk them.

The wat backend is at "not yet wired" status per the v0.beta.19
`libs/std/AGENTS.md` "Per-target reach (today)" row. The wat
template-dispatch builds on the existing instruction encoder; the
4-byte / 8-byte / control-flow shapes wat uses for the §A6-deferred
operations stay the same — the template carrier is just where the
emitter renders them from instead of an inline `eq(u8, callee, "X")`
switch arm.

## Steps

### P-A — BEAM `user_beam_templates`

- [ ] `codegen/beam_asm.zig` — add `user_beam_templates:
      std.StringHashMap(BuiltinBeamCall)` (or whatever the existing
      struct shape is — verify against `prim_beam_dispatch`).
- [ ] `Emitter.init` — initialise the map; `Emitter.deinit` walks +
      frees the entries (mirror the commonJS/erlang shape).
- [ ] `collectExternals` — route templates into `user_beam_templates`
      when `externalHasArityBranches("beam")` OR
      `primOpTemplate.looksLikeTemplate(ref.symbol)`; skip the
      `externals` map.
- [ ] `tryEmitUserTemplate(callee, cc)` — mirror the
      commonJS/erlang shape (single-template path + arity-branched
      path; render via `primOpTemplate.render`).
- [ ] Call-site dispatch — insert the `if (user_beam_templates.contains
      (cc.callee))` arm before the existing `externals.get` path.
- [ ] Sub-emitter struct literals (the `var sw = Emitter{...}` shape) —
      pass `user_beam_templates` through.
- [ ] Decl emit — when the fn is in `user_beam_templates`, emit a doc
      breadcrumb (mirror commonJS) instead of the bare-symbol comment.

### P-B — wat `user_wat_templates`

- [ ] `codegen/wat.zig` — add `user_wat_templates` field of the same
      shape.
- [ ] `collectExternals` (wat-side equivalent) routes templates.
- [ ] `tryEmitUserTemplate` for wat — the template renders wat
      instructions; the `primOpTemplate.render` walker passes through
      any byte that isn't a marker, so a wat template like
      `i32.const $0 i32.const $1 i32.add` lowers verbatim.
- [ ] Call-site dispatch — wat's call-emit point gets the same
      pre-`externals` arm.

### P-C — migrate the 4 BEAM inline allow-list arms

The `project_v0beta19_prim_op_annotation` memory cites "4 inline arms"
on BEAM that the v0.beta.19 partial close kept. Audit them, add the
`@external(beam, "<template>")` annotation on each method in
`primitives.d.bp`, and delete the inline arms.

- [ ] Audit `codegen/beam_asm.zig` for surviving `mem.eql(callee, …)`
      arms (search pattern: `mem.eql(u8, callee, ` in `emitPrimMethod`).
- [ ] For each, author the equivalent BEAM template in
      `primitives.d.bp`. The byte-identical migration contract is the
      same as the erlang Family-1 close in `64a3436`.
- [ ] Per-method BEAM snapshots stay pinned (the run-log shape doesn't
      change; the emit path does).

### P-D — wat backend §A6 dispatch parity

The wat backend currently doesn't have a `tryEmitPrimAnnotation`
equivalent at all per the AGENTS row. This phase wires it up using the
template carrier so wat closes the §A6 surface alongside BEAM.

- [ ] `codegen/wat.zig` — author `tryEmitPrimAnnotation` for `Array<T>`
      / `String` / `Bool` interface methods, mirroring the erlang
      shape from `codegen/erlang.zig` (the `PrimErlangCall` struct +
      `prim_erlang_dispatch` map). Reuse the shared
      `primOpTemplate.render` walker.
- [ ] `primitives.d.bp` — author `@external(wat, "<template>")` for
      every surviving §A6 method; the templates carry the wat
      instruction sequence.
- [ ] Per-method wat snapshots.

### P-E — fixtures + AGENTS roll

- [ ] `tests/codegen/prim_op_chained_beam.zig` — pin two
      arity-branched + one chained template on BEAM (mirror the
      `tests/codegen/externals.zig` §A2 fixtures).
- [ ] `tests/codegen/prim_op_chained_wat.zig` — same for wat.
- [ ] `libs/std/AGENTS.md` "Per-target reach (today)" row — flip from
      "erlang full; commonJS uses jsMethodRenames; wat not yet wired"
      to "every backend reads the full template grammar".
- [ ] `modules/compiler-core/src/codegen/AGENTS.md` Remaining-gaps
      roll — drop the §A6 "irreducible allow-list" row.
- [ ] `CHANGELOG.md` entry under `Added` / `Changed`.

## Test scenarios

```
beam   prim-op-annotation Family 1 ports (the 4 inline arms) emit byte-identical
beam   §A2 chained host call (BEAM template) renders at the call site, not aliased
wat    §A2 template renders at the call site
wat    §A6 method dispatch from primitives.d.bp annotations (no inline switch)
all   `botopink-lib-test --lib std --target all` green
```

## Notes

- The `commonJS template path strips this` discovery from
  `std-expansion-tail` doesn't apply to BEAM (BEAM emits bytecode, no
  alias) or wat (no method shape). But the template form still
  preserves the surface contract: one annotation row in
  `primitives.d.bp` per method per backend.
- Snapshots are the contract — every byte-identical re-emit pins the
  migration. Snapshot churn in this spec is **expected and contained**
  to the per-method `*.snap.md` files under
  `snapshots/codegen/{beam,wasm}/`.

## Exit gate

- [ ] All P-A through P-E checkboxes ticked.
- [ ] `botopink-lib-test --lib std --target all` green (4/4 backends).
- [ ] No remaining `mem.eql(u8, callee, "X")` arms in BEAM
      `emitPrimMethod` or wat's equivalent.
- [ ] `libs/std/AGENTS.md` "Per-target reach (today)" row reflects
      4/4 backend coverage.
- [ ] CHANGELOG entry under `Added`.

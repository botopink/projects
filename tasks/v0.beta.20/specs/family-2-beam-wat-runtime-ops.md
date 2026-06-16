# family-2-beam-wat-runtime-ops — drive `@Result` / `@Option` ops from annotations on BEAM + wat

**Slug**: family-2-beam-wat-runtime-ops
**Depends on**: `prim-op-annotation` commits `7f8f259` (erlang) +
`f9918b1` (commonJS) — Family 2 erlang + node landed via
`tryEmitBuiltinAnnotation`; this spec closes the remaining two backends.
**Files**:
- `modules/compiler-core/src/codegen/beam_asm.zig` — delete
  `emitResultOptionOp` (~lines 2624–2740); add `__bp_…` entries to a
  new `registerInlineBuiltinBeamDispatch` (mirror the erlang one); route
  the `__bp_` callee path through `tryEmitBuiltinAnnotation` (or its
  BEAM-side sibling).
- `modules/compiler-core/src/codegen/wat.zig` — delete
  `emitResultOptionOp` (~lines 1417–1570); add `__bp_…` entries
  to a new `registerInlineBuiltinWatDispatch`; route through dispatch.
- `modules/compiler-core/src/codegen/AGENTS.md` — §"Annotation-driven
  lowering" gains a BEAM + wat row.
**Touches docs**: `modules/compiler-core/src/codegen/AGENTS.md` ·
  `CHANGELOG.md`.
**Status**: pending

## Background

`prim-op-annotation` Family 2 retired the hand-rolled `emitResultOptionOp`
switch on the erlang + commonJS backends (commits `7f8f259` + `f9918b1`):
the nine comptime-synthesised `__bp_…` callees now lower through
`tryEmitBuiltinAnnotation` reading from the `builtin_<backend>_dispatch`
table seeded in `registerInlineBuiltinDispatch`. The same shape works
for **BEAM** and **wat**, with two complications:

1. BEAM is bytecode — templates emit text but BEAM-asm emits opcodes
   like `put_tuple2 {atom,ok} V`, `move {atom,ok} {x,N}`, branches.
   A template string can capture those sequences (BEAM-asm is text
   too), but the renderer's `$self` / `$N` markers need a different
   stringifier (`emitArg` writes register tokens or atoms, not the
   target's value-rendering).

2. wat is wasm S-exprs — same issue: `$0` / `$1` are virtual
   slot indices the renderer doesn't natively understand on a
   stack-based VM. The `emitArg(i)` callback needs a wat-aware
   stringifier that emits a `(local.get $arg_i)` style fragment, with
   the caller setting up the stack frame for the inline fun.

This spec addresses both via a small extension to the template renderer
(per-backend marker policy on `emitArg`) and bulk migration to the
annotation-driven path.

## Premise

After this spec lands, **every backend** consumes `@Result` / `@Option`
runtime ops via one entry in `builtin_<backend>_dispatch` instead of a
hand-rolled `emitResultOptionOp` switch. The grammar surface is the
same single-string template form; the per-backend differences live in
the ctx struct each backend supplies to `primOpTemplate.render`.

## Target surface

Each backend's `register…Dispatch` gains the nine `__bp_…` entries (mirror
the erlang shape from `prim-op-annotation/7f8f259`):

```zig
// BEAM
try this.putInlineBeamBuiltin("__bp_ok", &.{
    .{ .argc = 1, .template = "{put_tuple2 {atom,ok} $0}" },
});
try this.putInlineBeamBuiltin("__bp_result_map", &.{
    .{ .argc = 2, .template =
        "(fun(R) -> case R of {ok, V} -> {ok, ($1)(V)}; _ -> R end end)($0)" },
});
// ... etc, mirror the erlang templates (BEAM consumes the same Erlang
//     source emitter — the `$N` substitutions render the same way).
```

```zig
// wat
try this.putInlineWatBuiltin("__bp_ok", &.{
    .{ .argc = 1, .template =
        "(struct.new $bp_result_ok $0)" },
});
try this.putInlineWatBuiltin("__bp_result_map", &.{
    .{ .argc = 2, .template =
        "(if (struct.test $bp_result_ok $0) (then (struct.new $bp_result_ok (call_ref $1 (struct.get $bp_result_ok 0 $0)))) (else $0))" },
});
// ... etc.
```

The caller path collapses to:

```zig
if (std.mem.startsWith(u8, cc.callee, "__bp_")) {
    if (try this.tryEmitBuiltinAnnotation(cc.callee, cc)) return;
    return error.UnmappedBpRuntimeOp;
}
```

`emitResultOptionOp` is deleted on both backends.

## Compiler path

### F0 — BEAM Family 2

- [ ] `beam_asm.zig`: add `registerInlineBuiltinBeamDispatch` mirroring
      the erlang shape; seed the nine `__bp_…` entries with BEAM-asm
      templates.
- [ ] Route the `__bp_` callee dispatch path through
      `tryEmitBuiltinBeamAnnotation` (or extend the existing
      `tryEmitBuiltinAnnotation` to accept BEAM ctx shape).
- [ ] Delete `emitResultOptionOp` in `beam_asm.zig`.

### F1 — wat Family 2

- [ ] `wat.zig`: add `registerInlineBuiltinWatDispatch`; seed the nine
      `__bp_…` entries with wasm-instruction templates.
- [ ] Route the `__bp_` callee path through dispatch.
- [ ] Delete `emitResultOptionOp` in `wat.zig`.

### F2 — tests + snapshots

- [ ] Existing `@Result` / `@Option` snapshot tests on BEAM + wat diff
      empty against pre-F0 HEAD (byte-identical migration).
- [ ] Negative: a synthesised `__bp_garbage` callee reds with
      `UnmappedBpRuntimeOp` on each backend (not silently emit nothing).

### F3 — docs

- [ ] `codegen/AGENTS.md` §"Annotation-driven lowering" gains a row for
      BEAM + wat:
      `BEAM | tryEmitBuiltinBeamAnnotation → builtin_beam_dispatch | seeded inline at registerInlineBuiltinBeamDispatch.`
- [ ] `CHANGELOG.md` under v0.beta.20:
      `refactor(codegen): @Result/@Option ops annotation-driven on every backend; emitResultOptionOp deleted.`

## Test scenarios

```
F0-byte   ---- diff snapshots/codegen/beam/ for @Result/@Option fixtures against pre-F0 HEAD: empty
F1-byte   ---- diff snapshots/codegen/wat/ for @Result/@Option fixtures against pre-F1 HEAD: empty
F2-empty  ---- post-F1 `git grep emitResultOptionOp modules/compiler-core/src/codegen/` finds zero hits
F2-red    ---- `__bp_garbage` reds with UnmappedBpRuntimeOp on every backend
F3-docs   ---- codegen/AGENTS.md + CHANGELOG.md updated in the same commit as the last F1 hunk
gate      ---- `zig build test` + `zig build test-libs` + `zig build test-backends` green
```

## Notes

- **Cross-spec interaction.** Completes Family 2 of
  `prim-op-annotation`'s migration table — closes the last item on
  "post-F2 `git grep 'if (eq(u8, callee,' codegen/erlang.zig
  codegen/beam_asm.zig codegen/commonJS.zig codegen/wat.zig` finds zero
  hits" (the spec's F2-empty test scenario).
- **Per-memory:** SSH for git remote ops; AGENTS.md updated in the same
  commit as the code; commit messages in English; functions in
  camelCase.

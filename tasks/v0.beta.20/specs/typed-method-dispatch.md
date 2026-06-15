# typed-method-dispatch — local-record method dispatch via mangled local fns on erlang + beam

**Slug**: typed-method-dispatch
**Depends on**: [`generic-inference-foundation`](generic-inference-foundation.md)
  — the inference pass tagging call-site receivers with `.record{TypeName}`
  shares infrastructure with the keystone's `.prim{kind}` tagging.
**Files**: `modules/compiler-core/src/comptime/infer.zig` (tagging) ·
  `modules/compiler-core/src/codegen/{erlang,beam_asm}.zig` (consume tag)
  · new cross-backend snapshots
**Touches docs**: `modules/compiler-core/src/codegen/AGENTS.md`
**Status**: pending

## Background

v0.beta.19's frente-a-compiler §D3 deferred typed-value method
dispatch on erlang/beam. Today, `p.parse(x)` where `p: Parser`
lowers to the bare local call `parse(P, X)` — works for LOCAL
records (the bare fn exists because `emitRecord` emits it by name)
but the call doesn't honour the record's own associated-fn mangling
convention (`'Parser_parse'`). Imported records already work via
`imported_types` mapping (emitting `<owner>:'Parser_parse'(P, X)`);
the local-record path is the gap.

## Checklist

- [ ] **F1-infer** — In `comptime/infer.zig`, when a call's receiver
      resolves to a record/struct type, record
      `instance_lowerings[<loc>] = .record{<TypeName>}`. The map and
      variant already exist (the keystone consumes `.prim`); this
      section adds the `.record` variant population for LOCAL records
      (cross-module already populated).
- [ ] **F2-erlang** — In `codegen/erlang.zig`, the call emitter's
      `.record` branch already exists at line ~2268 — extend to
      emit the mangled local `'Parser_parse'(P, X)` for LOCAL records
      (not the bare `parse(P, X)`). Cross-module path (already
      `<owner>:'Parser_parse'`) stays.
- [ ] **F3-beam** — Same on `codegen/beam_asm.zig`. The `instance
      _lowerings.get(loc).record` branch consumes the mangled name
      via `fnLabelsFor("'Parser_parse'", arity + 1)` (the receiver
      counts as the first arg).
- [ ] **F4-test** — A fixture defining `record Parser { … } fn
      parse(self, x) { … }`, then `p.parse(x)`. Snapshot pinned on
      both backends: emitted call uses the mangled form.
- [ ] **F5-docs** — `codegen/AGENTS.md` erlang + beam_asm rows: drop
      "typed-value method dispatch (`p.parse()`)" from Remaining
      gaps.

## Test scenarios

```
F4-erlang ---- `record Parser { … } parse(self, x){…}; p.parse(x)`
                emits `'Parser_parse'(P, X)` (not `parse(P, X)`).
F4-beam    ---- same fixture emits `{call, 2, {f, <label-of-Parser_parse>}}`.
F4-libs    ---- existing record-method tests stay green (no
                regression).
```

## Notes

- This spec is intentionally narrow: only local-record method
  dispatch. Cross-module record method dispatch is already correct
  via `imported_types`.
- **No `--no-verify`**; **SSH for git**; **AGENTS.md in the same
  commit**.

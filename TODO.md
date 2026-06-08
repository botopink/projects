# TODO — implement-completeness

> Live checklist for branch `task/implement-completeness` (worktree
> `.tasks/implement-completeness/`).
> Spec (intent, immutable): [`tasks/v0.beta.6/specs/implement-completeness.md`](tasks/v0.beta.6/specs/implement-completeness.md)

> **Goal**: `implement` parses + codegens in every documented form. Surfaced
> attaching `@Context` to jhonstart's `Element` (G5–G7). G7 is a **correctness
> bug** (inline `struct implement` values drop their fields at runtime) — fix it
> first. Files: `parser/decls.zig`, `parser/types.zig`, `codegen/commonJS.zig`,
> `codegen/erlang.zig`.

## F0 — parser
- [x] G5: array-typed (and other suffixed) fields inside an inline
      `struct implement … { … }` body — `parseStructBody` now uses `parseTypeRef`;
      `StructField.typeName` → `typeRef: TypeRef`. Test:
      `parser: struct implement with array-typed field`.
- [x] G6: generic interface (`Iface<A,B>`, incl. `@Context<…>`) in standalone
      `implement <Iface> for <Type> { }` — `ImplementDecl.interfaces` →
      `[]TypeRef`, parsed via `parseTypeRef`. Test:
      `parser: implement generic interface for type`.

## F1 — codegen (the real bug, prioritize)
- [x] G7: inline `struct implement … { fields }` emits a real constructor that
      assigns fields (matching `record`) — `emitStruct` in `commonJS.zig` now
      emits `constructor(...)` (field inits → param defaults). Erlang already
      lowered struct construction to a `#{…}` map via `collectTypeShapes`, so it
      had parity already. node + erlang RUN LOGs both print `5`.

## F2 — regression coverage
- [x] `js: struct implement ---- fields round-trip at runtime` — runs `mk().n`
      on every backend; node + erlang snapshots assert `5` (was `undefined`).

## Notes
- jhonstart V1 already dodges all three (`record … implement @Context`), so this
  unblocks the *next* phase, not the green core. The broken forms are now fixed.
- Out of scope: beam/wasm struct-field round-trip is still incomplete (the test
  snapshots record their current — wrong/empty — output); spec only required
  node + erlang parity. Labeled-arg reordering is unchanged from `record`
  (call site emits args in written order).
- Docs updated: `docs.md` §Implement (generic interface + inline struct-implement
  with fields), `codegen/AGENTS.md` (struct constructor emission).

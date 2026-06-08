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
- [ ] G5: array-typed (and other suffixed) fields inside an inline
      `struct implement … { … }` body
- [ ] G6: generic interface (`Iface<A,B>`, incl. `@Context<…>`) in standalone
      `implement <Iface> for <Type> { }`

## F1 — codegen (the real bug, prioritize)
- [ ] G7: inline `struct implement … { fields }` must emit a real constructor
      that assigns fields (positional + labeled), matching `record`, on every
      backend (`new E("x", 5)` must populate `tag`/`n`)

## F2 — regression coverage
- [ ] a `codegen/node` test that *runs* a `struct implement` value and asserts a
      field round-trips (gap existed because only inference was tested)

## Notes
- jhonstart V1 already dodges all three (`record … implement @Context`), so this
  unblocks the *next* phase, not the green core. Either fix the broken forms or
  remove them from the documented surface.

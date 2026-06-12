# TODO — lsp-definition-completeness

> Task branch `task/lsp-definition-completeness` · spec
> [`tasks/v0.beta.15/specs/lsp-definition-completeness.md`](tasks/v0.beta.15/specs/lsp-definition-completeness.md).
> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test (no `--no-verify`).
> **Depends on (all DONE on `feat`):** `lsp-project-awareness` (definition + local-scope +
> project-graph), `sublanguage-lsp` (engine definition/hover plumbing), `module-system`
> (`mod`/`pub mod` + sibling resolution).

Goal: go-to-definition lands on **record fields**, **member access**, **builtin methods** and
**`mod` references** — not just top-level names and locals. Make method resolution
type-aware (receiver type, not first-`fn`-name-wins) by reusing the receiver-type +
member-enumeration + project-graph machinery the LSP already has for completion/hover.

Reproductions (each gains a regression test) live in `libs/erika/src/{erika,root}.bp`:
R2 `.reverse` → `Array.reverse` (not `Query`'s own); R3 `Query(items:)` label; R4 `self.items`;
R5 same-named method on the right record; R6 `.forEach` builtin; R7 `pub mod erika;`.

## F0 — reproductions first
- [x] Failing tests under `modules/language-server/src/tests/` for R2–R7 using the real
      erika shape (record with fields + methods, `Name(field: …)` ctor call, `self.field`
      in a method, builtin `xs.forEach(…)`, `pub mod <name>;` over a sibling file). Must
      fail on `feat` — including R2 (must assert jump lands on `Array.reverse`, not `Query`).

## F1 — member-access definition (`recv.field` / `recv.method`) — R2, R4, R5
- [x] Cursor on the member name of `recv.member`: detect the `.` to the left
      (mirror `dotContext`/`prefixAt`), resolve the receiver's named type like
      `dotCompletion` Case 2, locate the field-or-method `member` inside that record body,
      return its name-token location. Type-aware (fixes R5, corrects R2), reaches fields
      (fixes R4). Fall back to current name scan only when receiver type is unknown.

## F1b — builtin-receiver methods → `primitives.d.bp` — R6
- [x] Builtin receiver (`Array`/`string`/numeric/`bool`/…): route via
      `builtinInterfaceForType` (`engine.zig:3360`) to the embedded interface source, run
      `findDeclLocation` over `libs/std/src/primitives.d.bp`, return the method decl there.
      Reuses the exact hover resolution; jump target is a real on-disk URI (no virtual doc).

## F2 — `self.field` — R4 (the erika case)
- [x] Resolve `self` (`self: Self`) to the enclosing record decl so `self.items` jumps to
      the `items` field. `Self` ⇒ the record whose body lexically encloses the cursor.

## F3 — named constructor-argument labels (`Name(field: …)`) — R3
- [x] Cursor on a labeled argument name in `Name(field: …)`: resolve `Name` to its record
      decl, jump to the `field` decl. (Identifier followed by `:` inside a call whose callee
      is a record type.)

## F4 — `mod` reference → sibling module file — R7
- [x] Cursor on a `mod` / `pub mod` decl name: resolve via `project_graph.zig` sibling map
      to the backing file (`<name>.bp` or `<name>/mod.bp`), return a Location at file start
      (or its `pub mod`/root decl). File-level jump, not a token scan.

## F5 — cross-module fields
- [x] Extend `definitionInModules` (`engine.zig:504`) so a field/method on a receiver whose
      type is declared in another module (or an embedded `"std"` module) jumps there too,
      honoring `require_pub` for the field's owning declaration.

## F6 — docs + tests
- [x] Note the new member/module resolution paths in `modules/language-server/AGENTS.md`
      and `docs.md`. Add snapshot/unit coverage for F1–F5.

## Done gate
- [x] R2–R7 resolve in `libs/erika/src/{erika,root}.bp` + the regression fixtures; method
      go-to-def is type-aware (builtin + user types) without regressing existing name-based
      jumps; `mod` names open their backing file.
- [x] `zig build test` green (LSP definition tests incl. R2–R7 + F5).
      `botopink-lib-test` unchanged vs baseline: the 5 reds (erlang case…of in
      erika/jhonstart/onze/rakun + erika-LINQ commonJS generic-inference-gap) are
      **pre-existing**, verified identical with the change stashed — this LSP-only
      change touches no compiler/codegen path.

## Implementation notes
- `engine.definitionMember` (new) is the type-aware entry: `receiverChain` →
  `resolveChainType` (binding type / literal / `self`→`enclosingTypeName`, narrowing
  through `stepField`) → `findMemberInTokens` (user record body) or
  `findInterfaceMemberRange` (embedded `primitives.d.bp`, returned as
  `TypedDefinition.builtin` for the server to materialize). `ctorCalleeBefore` (F3),
  `modRefNameAt`+`findModuleFile` (F4), `findMemberDeclAcross` (F5, `require_pub`).
- The server gates on the cheap `needsTypedDefinition` and runs the typed path
  **before** the name scan; on a typed miss it falls through (no regression).
  Added `CompileResult.bindingsFor(uri)` so the active module's bindings are used
  (the old first-`ok` pick returned a dependency's bindings under a graph compile).

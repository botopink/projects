# v0.beta.15 — plan

## Premise

v0.beta.14 (`lsp-project-awareness`) gave the LSP a project module graph, a local-scope
symbol model, and a decorator-body binding fix — so completion/definition/hover now fire on
real multi-module, decorator-emitting files. But **go-to-definition still resolves by a token
scan**: it finds a declaration keyword followed by the name. That covers top-level decls and
locals and nothing else. Real navigation is almost entirely **member access** (`recv.field`,
`recv.method`), **builtin methods** (`xs.forEach`), **named constructor labels**
(`Name(field: …)`), and **module references** (`pub mod erika;`) — none of which have a
preceding declaration keyword in the file the cursor is in.

## Method

The fix is **reuse, not new machinery**. The LSP already resolves a receiver's named type
for completion (`dotCompletion` Case 2), maps builtins to their interface source
(`builtinInterfaceForType`), enumerates a record's members for document symbols, and maps
`mod` siblings to files (`project_graph.zig`). Definition must consult these instead of the
bare name scan:

1. **F1 member-access** — resolve the receiver's named type, find the member inside that
   record's body, return its name-token location (type-aware: fixes the first-`fn`-name-wins
   defect). Fall back to the name scan only when the receiver type is unknown.
2. **F1b builtin receivers** — route through `builtinInterfaceForType` to the embedded
   interface source and run `findDeclLocation` over the real on-disk `primitives.d.bp` — the
   jump target is a real URI, no virtual-document plumbing.
3. **F2 `self.field`** — `Self` ⇒ the lexically enclosing record.
4. **F3 named ctor labels** — `Name(field: …)` → the `field` decl in `Name`'s record.
5. **F4 `mod` refs** — resolve the name through the project graph to its backing file.
6. **F5 cross-module fields** — extend `definitionInModules`, honoring `require_pub`.

Each step is independently shippable and gets a regression test under
`modules/language-server/src/tests/` using the **real erika shape** (a record with fields +
methods, a `Name(field:)` ctor call, `self.field`, a builtin `xs.forEach`, a `pub mod`).
The tests must fail on `feat` — including R2, which asserts the jump lands on `Array.reverse`,
not `Query`'s own `reverse`.

## Risks / coordination

- **No regression of name-based jumps.** F1 falls back to the current scan when the receiver
  type is unknown, so today's same-file top-level jumps never break.
- **Builtin jump target is a real file.** `primitives.d.bp` is on disk (`array_interface_src`/
  `string_interface_src` are embedded copies of it) — point the Location at the real URI.
- **`.d.bp` discipline.** The builtin jump lands in `libs/std/src/primitives.d.bp`; that's a
  declaration-surface `.d.bp` and a legitimate navigation target even though it's excluded
  from compilation. See [[project_libs_module_migration_done]].

## Done means

R2–R7 resolve in `libs/erika/src/{erika,root}.bp` and the regression fixtures; method
go-to-def is type-aware (builtin and user types) without regressing existing jumps; `mod`
names open their backing file; `language-server/AGENTS.md` + `docs.md` describe the new
member/module resolution paths; `zig build test` + `botopink-lib-test` stay green.

# v0.beta.10 — Wave 2: the LSP reader, backend work, and the lib structural migration

> The biggest **parallel wave**: six specs. The sub-language reader, three core/codegen
> strands, the lib module-migration, and the VS Code renderer. Two coordination notes
> apply (one runtime edge, codegen merge-order) — everything else is module-disjoint.
> See [`../AGENTS.md`](../AGENTS.md). Live progress → [`status.md`](status.md).

## The wave — six specs

| Spec | Area | Depends on |
|---|---|---|
| [sublanguage-lsp](specs/sublanguage-lsp.md) | `modules/language-server/*` | `expr-custom` (Wave 1) |
| [stdlib-backends-parity](specs/stdlib-backends-parity.md) | core codegen emitters + stdlib dispatch | nothing |
| [cross-module-codegen](specs/cross-module-codegen.md) | core codegen emitters (cross-package types) | nothing |
| [effect-annotations](specs/effect-annotations.md) | core `parser`/`infer`/codegen + `builtins.d.bp` + `libs/std` codemod | nothing |
| [libs-module-migration](specs/libs-module-migration.md) | `libs/{erika,jhonstart,onze,rakun,server,client}` onto the tree | `module-system` (Wave 1) |
| [sublanguage-vscode](specs/sublanguage-vscode.md) | `modules/vscode-extension/*` | `sublanguage-lsp` (this wave) |

## Why these six are Wave 2

- **sublanguage-lsp** — the Custom-AST reader, unblocked by `expr-custom` (Wave 1).
- **stdlib-backends-parity** / **cross-module-codegen** / **effect-annotations** — the
  three remaining core/codegen strands, all independent. They follow `module-system`'s
  Wave-1 emitter edits.
- **libs-module-migration** — needs `module-system` (Wave 1). It re-roots the lib
  *structure* (`root.bp` + `mod`/`pub mod`) **before** the lib *content* rewrites in
  Wave 3 (erika/html/rakun keep one file each, so the structure it lays down stays
  valid).
- **sublanguage-vscode** — the renderer.

## Two coordination notes (not blockers)

1. **One runtime edge, same wave:** `sublanguage-vscode` renders `sublanguage-lsp`'s
   semantic tokens. The grammar/theme work develops in parallel; vscode just **verifies
   last** against the running LSP at the end of the wave.
2. **Three codegen-emitter specs here** (`stdlib-backends-parity`,
   `cross-module-codegen`, `effect-annotations`) — with only three waves the
   one-emitter-per-wave rule can't hold, so these **sequence by merge-order**. They edit
   different emitter regions (stdlib dispatch · cross-package linking · the
   function-keyword lowering), so conflicts are localized.

Otherwise disjoint: `language-server`, the codegen emitters, the six lib packages, and
the VS Code extension are separate modules.

## What each spec delivers (summaries)

- **sublanguage-lsp** — comptime-driven semantic tokens + diagnostics + hover/def for
  sub-language content, from the Custom AST. Generic over `CustomNode`; serves both
  Wave-3 producers.
- **stdlib-backends-parity** — A1b beam/wasm lowering, A2 `#[@external]` assoc fns,
  Part B (literal-receiver codegen, snake→camel, beam std loading, `?.` beam/wasm, wasm
  test runner).
- **cross-module-codegen** — link imported concrete types to the owning emitted module
  on erlang/beam/wasm (commonJS done). v0.beta.6 orphan; review/rebase `a9e2ad2`.
- **effect-annotations** — `#[@<effect>]` replaces `*fn`; **annotation is
  implementation-only** (interfaces/`.d.bp` use the wrapper, no annotation); codegen off
  the effect kind (byte-identical to `*fn`); codemod every `*fn`.
- **libs-module-migration** — `root.bp` + `mod`/`pub mod` per lib (erika, jhonstart,
  onze, rakun, server, client); keep each `botopink test` green. `libs/std` is the pilot
  inside `module-system`.
- **sublanguage-vscode** — re-scope the string grammar so the LSP's tokens render inside
  `erika "…"`/`html """…"""`; theme mapping. No static grammar.

## Hand-off to Wave 3

`libs-module-migration` lays down each lib's module tree; Wave 3 (`erika-query-ast`,
`jhonstart-html-ast`, `rakun`) then rewrites those libs' **content** within that tree.

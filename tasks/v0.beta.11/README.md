# v0.beta.11 — Wave 3: the lib-content rewrites

> The final **parallel wave**: three disjoint lib specs — the two sub-language producers
> and the rakun framework tail. Each in its own lib package, on top of the module tree
> laid down in Wave 2. See [`../AGENTS.md`](../AGENTS.md). Live progress →
> [`status.md`](status.md).

## The wave — three disjoint, parallel specs

| Spec | Area (no overlap) | Depends on |
|---|---|---|
| [erika-query-ast](specs/erika-query-ast.md) | `libs/erika/src/erika.bp` | `expr-custom` (Wave 1) |
| [jhonstart-html-ast](specs/jhonstart-html-ast.md) | `libs/jhonstart/src/html.bp` | `expr-custom` (Wave 1) |
| [rakun](specs/rakun.md) | `libs/rakun/*` + `libs/server/*` | nothing |

Three different lib packages — no shared files.

## Why these three are Wave 3

All three rewrite **lib content** that sits on top of earlier waves:

- **erika-query-ast** + **jhonstart-html-ast** are the two sub-language **producers** —
  they need `expr-custom`'s `@ExprCustom` carrier (Wave 1) to emit the dual lowering.
  Same mechanism, disjoint libs → parallel.
- **rakun** is independent (DI scopes + real server), pure botopink in its own libs.

They land **after** `libs-module-migration` (Wave 2), which re-rooted these libs onto
the module tree. Because each producer keeps a single file (`erika.bp` / `html.bp` —
the lexer/AST/parser live inside it), and rakun edits its existing modules, the Wave-2
structure stays valid; this wave only rewrites the **bodies**.

## What each spec delivers (summaries)

- **erika-query-ast** — SQL lexer + private AST + parser in `erika.bp`; dual lowering
  (③ executable `@Expr<T>`, ④ generic `CustomNode`) → `q.custom(④, ③)`. Behaviour parity;
  `failAt` spans for syntax errors.
- **jhonstart-html-ast** — the same front-end for `html """…"""`: markup lexer +
  `MarkupNode` AST + parser; dual lowering (③ `@Expr<Element>`, ④ `CustomNode`).
- **rakun** — F2 DI scopes (singleton, `#[configuration]`/`#[bean]`, `#[value]`) + F5
  real `libs/server` over `#[@external]` + the runtime-`.mjs` shipping (G2). Lib-side
  via `@emit`.

## End state

After Wave 3 the whole backlog is landed across the three waves: both keystones + the
test gate (Wave 1), the LSP reader + backend parity + module migration + vscode
rendering + effect annotations (Wave 2), and the sub-language producers + rakun (Wave 3)
— first-class, tooling-visible `erika "…"` and `html """…"""`, an explicit module system
with every lib migrated, named effect annotations, and the lib test gate.

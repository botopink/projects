# v0.beta.11 — working notes (Wave 3 of 3)

Final wave of the three-wave re-grouping (see [v0.beta.9/plan.md](../v0.beta.9/plan.md)).

## Wave 3 = three disjoint lib-content rewrites

- **erika-query-ast** (`libs/erika/src/erika.bp`) — SQL lexer + AST + parser; dual
  lowering. Needs `expr-custom` (Wave 1).
- **jhonstart-html-ast** (`libs/jhonstart/src/html.bp`) — the same for `html """…"""`.
  Needs `expr-custom`. Disjoint lib from erika → parallel.
- **rakun** (`libs/rakun`/`libs/server`) — DI scopes + real server. Independent.

## Why content rewrites land last

These edit lib **content** on top of the module tree that `libs-module-migration`
(Wave 2) laid down. Each producer keeps a single file (the lexer/AST/parser live inside
`erika.bp`/`html.bp`), and rakun edits its existing modules — so the Wave-2 structure is
untouched; this wave only rewrites bodies. All three are different lib packages → fully
parallel, no shared files.

## End state

The whole backlog is landed: both keystones + the test gate (Wave 1); the LSP reader,
backend parity, module migration, vscode rendering, and effect annotations (Wave 2); the
sub-language producers + rakun (Wave 3).

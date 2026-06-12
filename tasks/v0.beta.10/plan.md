# v0.beta.10 — working notes (Wave 2 of 3)

Wave 2 of the three-wave re-grouping (see [v0.beta.9/plan.md](../v0.beta.9/plan.md)).
Eric's split puts the **lib structural migration here, before the lib-content rewrites
in Wave 3** — the inverse of content-first. It works because the Wave-3 producers keep
one file each, so the module tree this wave lays down stays valid.

## Wave 2 = LSP reader + core/codegen strands + lib migration + vscode (6 specs)

- **sublanguage-lsp** (`language-server`) — Custom-AST reader; needs `expr-custom`
  (Wave 1).
- **stdlib-backends-parity** / **cross-module-codegen** / **effect-annotations** —
  three independent core/codegen strands.
- **libs-module-migration** (`libs/*`) — re-roots each lib onto the module tree; needs
  `module-system` (Wave 1).
- **sublanguage-vscode** (`vscode-extension`) — renders the LSP's tokens.

## Two coordination notes

1. **Runtime edge, same wave:** `sublanguage-vscode` depends on `sublanguage-lsp` at
   runtime. The grammar/theme work proceeds in parallel; vscode just verifies last
   against the running LSP.
2. **Three codegen-emitter specs** (`stdlib`, `cross-module`, `effect-annotations`) —
   with three waves they can't be one-per-wave, so they **sequence by merge-order**.
   Different emitter regions (stdlib dispatch · cross-package linking · function-keyword
   lowering) keep conflicts localized.

Otherwise the six are module-disjoint: language-server, codegen emitters, the six lib
packages, and the VS Code extension.

## Hand-off

`libs-module-migration` lays down each lib's `root.bp`/`mod` tree; Wave 3 rewrites those
libs' content (erika/html bodies, rakun) within it.

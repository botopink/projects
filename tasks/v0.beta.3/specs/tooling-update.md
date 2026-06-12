# Tooling update — language-server + vscode-extension catch-up

**Slug**: `tooling-update`
**Depends on**: nothing (grammar/snippet items track already-landed syntax; LSP items
for interface methods land after `stdlib-interface`)
**Files**: `modules/language-server/src/*`; `modules/vscode-extension/{syntaxes,snippets.json,package.json,src/extension.ts}`
**Touches docs**: `modules/language-server/AGENTS.md`; `modules/vscode-extension/AGENTS.md`; both `docs.md`

**Status**: pending

## Problem

The language surface grew across v0.beta.1/2 — test blocks (`test "name" { … }` +
`assert`), `#[@external(target, module, symbol)]` attributes, `@Expr<E>` /
`@Result<D, E>` / `@Option` builtin types, `*fn` effect marker, import rework
(`import {A, X*} from "std"`), pipelines (`|>`), optional chaining (`?.`),
anonymous record literals — but the editor tooling lagged:

- The TextMate grammar (`botopink.tmLanguage.json`) has not been re-synced with
  `compiler-core/src/lexer/token.zig` since the import rework (last extension
  commit: a0c77f1).
- `snippets.json` has no snippets for `test` blocks, `#[@external]`, `*fn`, or
  `import { … } from "std"`.
- The LSP feature set (hover, completion, documentSymbol, codeAction) predates
  test blocks and the stdlib modules — e.g. test blocks don't appear as document
  symbols and std module members may not complete after `import {list} from "std"`.
- **Known bug (reported 2026-06-07): go-to-definition (ctrl+click) is not
  working** — `textDocument/definition` either returns nothing or the extension
  fails to surface it. Highest-priority item of this spec (F0a below).

Per `modules/vscode-extension/AGENTS.md`: the keyword list **must stay in sync**
with `token.zig`, and the extension itself has no compiler knowledge — semantic
gaps belong to `language-server`, lexical gaps to the grammar.

## Steps

### F0a — Fix go-to-definition (ctrl+click) regression

- [ ] Reproduce: `textDocument/definition` over stdio against a workspace file —
      same-file `val`/`fn`, cross-module `pub` symbol, std module fn
- [ ] Bisect: LSP engine (`src/engine.zig` definition path + `project_index.zig`)
      vs extension wiring (`extension.ts` client capabilities)
- [ ] Likely suspects: import rework (`import {A, X*} from "name"`) changed how
      the project index resolves symbols; new AST categories changed node lookup
      at position
- [ ] Fix + snapshot under `snapshots/lsp/` (same-file, cross-module, std module)

### F0 — Audit (grammar vs lexer, feature inventory)

- [ ] Diff the keyword classes in `syntaxes/botopink.tmLanguage.json` against
      `compiler-core/src/lexer/token.zig` — list missing/stale keywords
- [ ] Inventory post-v0.beta.1 syntax not highlighted: `#[@external(…)]`
      attributes, `@`-prefixed builtin types (`@Expr`, `@Result`, `@Option`,
      `@Iterator`), `*fn`, `|>`, `?.`, template holes, anonymous record literals
- [ ] Inventory LSP gaps per feature (hover/completion/documentSymbol/
      codeAction/foldingRange) against the same syntax list

### F1 — TextMate grammar sync

- [ ] Update keyword groups in `botopink.tmLanguage.json` to match `token.zig`
- [ ] Add scopes: attribute (`#[@external(…)]`), builtin `@Type` names,
      `*fn` effect marker, pipeline `|>`, optional chaining `?.`
- [ ] Mirror the changes in `botopink.codeblock.json` (markdown ```bp injection)
- [ ] Manual smoke: open `libs/std/src/*.bp` + `*_test.bp` and check colouring

### F2 — Snippets + language configuration

- [ ] Add snippets: `test` block (+ `assert`), `#[@external]` declare fn,
      `*fn` effectful fn, `import { … } from "std"`
- [ ] Review `language-configuration.json` on-enter/auto-close rules against the
      current syntax (template strings, attributes) — adjust if needed

### F3 — LSP: test blocks + stdlib surface

- [ ] `documentSymbol`: emit a symbol per `test "name" { … }` block
- [ ] `foldingRange`: fold test blocks
- [ ] `completion`: std module members complete after `import {list} from "std"`
      (qualified `list.` dot-trigger) — verify against the project index
- [ ] `hover`: signatures for std module fns and `#[@external]` declares
- [ ] Snapshots under `snapshots/lsp/` for each new behavior

### F4 — LSP: interface-method dispatch (after `stdlib-interface`)

- [ ] `completion` on receiver dot: `true.` / `42.` / `xs.` lists interface
      methods from `primitives.d.bp` / `array.d.bp`
- [ ] `hover` + `signatureHelp` resolve interface methods on primitives
- [ ] Snapshots: `lsp/completion_primitive_methods`, `lsp/hover_interface_method`

### F5 — Manifest + docs

- [ ] Bump `package.json` version; refresh README feature list
- [ ] Update both `AGENTS.md` + `docs.md` (feature scope tables)
- [ ] `zig build test` in `modules/language-server` — snapshots green

## Test scenarios

```
lsp ---- documentSymbol includes test blocks
lsp ---- completion: std module members after import from "std"
lsp ---- hover: #[@external] declare fn signature
lsp ---- completion: primitive receiver lists interface methods (post stdlib-interface)
```

## Notes

- F0–F3 + F5 are independent of the other v0.beta.3 specs and can start
  immediately; only F4 waits for `stdlib-interface`.
- Grammar work is purely lexical — keep the "no compiler-internal knowledge"
  rule from `vscode-extension/AGENTS.md`; anything semantic goes to the LSP.
- `botopink-lsp` is launched with no args — do not add subcommands.

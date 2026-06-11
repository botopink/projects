# TODO — sublanguage-lsp  (LSP · Wave 2 of 3)

> Task branch `task/sublanguage-lsp` · spec
> [`tasks/v0.beta.10/specs/sublanguage-lsp.md`](tasks/v0.beta.10/specs/sublanguage-lsp.md).
> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test (no `--no-verify`).
> **Depends on:** `expr-custom` (Wave 1, reads `CustomNode` trees via the core
> tooling-access API). Generic: the LSP knows `CustomNode`, not SQL/HTML —
> comptime-driven highlight, no static grammar.

## F0 — pull the Custom AST into the engine
- [x] `compileTypesOnly(…, eval_ctx)` gained an opt-in template-eval context so
      `@ExprCustom` bodies run via `node` and surface on `OkData.custom_ast`.
      `LspCompiler` carries `io`+`eval_root`; `CompileResult.customAstFor(uri)`
      exposes the entries; `customContentStart` anchors `span` to the literal.

## F1 — semantic tokens for string content
- [x] `engine.customSemanticTokens` maps each `CustomNode.label`
      (keyword/property/string/number/operator → legend; `string`/`number`/
      `operator` appended at indices 11–13 in `protocol.zig`) + `span` to a range;
      `mergeSemanticTokens` re-sorts into the lexer stream. Wired in
      `handleSemanticTokens`; snapshot `sublanguage_semantic_tokens.snap.md`.

## F2 — diagnostics from the sub-language
- [x] `q.failAt(span, msg)` → `template.failDiagnostic` → `typeError` located
      **inside** the literal → ordinary diagnostic (existing `diagnosticsFor`
      path, now reached because templates expand). Test: a malformed query ranged
      on the offending token (`sublanguage.zig` F2).

## F3 — associations: hover + go-to-definition
- [x] `engine.customRefNameAt` finds the deepest covering node's `ref.name`;
      `hoverCustomRef` renders the bound symbol's card, `definitionCustomRef`
      jumps to its declaration (shared `renderBindingHover`/`findDeclLocation`).
      Wired in `handleHover` (custom-first) + `handleDefinition` (gated on
      `cursorInString`). Tests in `sublanguage.zig` (F3).

## F4 — capabilities + docs
- [x] Legend re-advertised automatically (`protocol.legend`). Sub-language path
      documented in `language-server/AGENTS.md`. Snapshot + diagnostic + hover +
      definition tests under `src/tests/sublanguage.zig`.

## Done gate
- [x] `q "select name"` → `select` highlights as keyword, `name` as property
      (snapshot); a malformed query yields a diagnostic ranged inside the string
      (F2); hover/go-to-def on a bound node resolve via `ref` (F3).
- [x] A plain string with no sub-language is unchanged (no custom tokens emitted).
- [~] `zig build && zig build test` green — running (pre-commit re-verifies).

# Editor experience — LSP enrichment + VS Code integration

**Slug**: `editor-experience`
**Depends on**: `tooling-update` (grammar/snippet sync + go-to-def fix land first); `stdlib-interface` (semantic data for primitive method dispatch)
**Files**: `modules/language-server/src/*`; `modules/vscode-extension/{src/extension.ts,package.json}`
**Touches docs**: `modules/language-server/AGENTS.md` + `docs.md`; `modules/vscode-extension/AGENTS.md` + `docs.md`

**Status**: pending

## Problem

`tooling-update` brings the editor tooling back to **parity** with the current
syntax (grammar sync, snippets, go-to-definition fix, std-member completion). The
LSP already serves `hover / completion / definition / references / rename /
formatting / foldingRange / documentSymbol / codeAction / signatureHelp` and a
minimal `inlayHint`. This spec goes **beyond parity** — the high-value editor
features that are still missing:

- **No semantic tokens** — highlighting is purely lexical (TextMate). Types,
  interface methods, `*fn` effects, builtin `@Type`s, comptime params are not
  distinguished. `semanticTokens` is the single biggest LSP gap (0 coverage).
- **Inlay hints are minimal** — inferred `val` types and lambda param types are
  not surfaced, despite the type checker already computing them.
- **VS Code has no task/test integration** — `package.json` contributes
  `commands` only; there is **no** `taskDefinitions`, no `codeLens`, no Testing
  API. `test "…" { … }` blocks and `botopink test` aren't reachable from the UI.

## Steps

### F0 — Semantic tokens (LSP)

- [ ] Advertise `semanticTokensProvider` (legend: `type`, `interface`, `enum`,
      `enumMember`, `function`, `method`, `parameter`, `variable`, `property`,
      `keyword`, `comment`, modifiers `declaration`/`readonly`/`defaultLibrary`)
- [ ] Drive tokens from the typed AST (`comptime` bindings) — distinguish builtin
      `@Type`s, interface methods on receivers, `*fn` effectful fns, comptime params
- [ ] `textDocument/semanticTokens/full` (+ `range`); snapshots under `snapshots/lsp/semantic_tokens_*`
- [ ] Extension: enable semantic highlighting (no `package.json` change needed —
      capability is server-driven)

### F1 — Inlay hints (LSP)

- [ ] Type hints on `val x = …` (inferred type after the name), suppressed when annotated
- [ ] Parameter-name hints at call sites; lambda param type hints
- [ ] Respect client `inlayHint` resolve + `workspace/inlayHint/refresh` on edits
- [ ] Snapshots `snapshots/lsp/inlay_hints_*`

### F2 — VS Code: tasks + problem matcher

- [ ] `taskDefinitions` + a `TaskProvider` for `check` / `build` / `test` / `format`
      (shells the `botopink` CLI; honours the active target)
- [ ] `problemMatcher` parsing `botopink check` diagnostics → Problems panel
- [ ] Output channel for CLI runs

### F3 — VS Code: CodeLens + status bar

- [ ] CodeLens above each `test "…" { … }` block → "Run test" (filtered `botopink test --filter`)
- [ ] CodeLens above `fn main` → "Run"
- [ ] Status-bar item showing the active codegen target (`commonJS`/`erlang`/…),
      click to switch (writes `botopink.json` / passes `--target`)

### F4 — VS Code: Testing API (Test Explorer)

- [ ] Discover `test "…"` blocks across the workspace via the LSP `documentSymbol`
      test-block symbols (from `tooling-update` F3)
- [ ] Run/run-all through `botopink test`; map pass/fail + assertion messages back
      to the Test Explorer tree
- [ ] Per-test "Run" gutter icons

### F5 — Docs + manifest

- [ ] Bump `package.json`; refresh README feature list (semantic tokens, inlay
      hints, tasks, test explorer)
- [ ] Update both `AGENTS.md` + `docs.md` capability tables
- [ ] `zig build test` in `modules/language-server` — snapshots green

## Test scenarios

```
lsp ---- semanticTokens: interface method vs free fn vs *fn distinguished
lsp ---- semanticTokens: builtin @Type (@Result/@Option/@Expr) classified
lsp ---- inlayHint: `val n = 1 + 2` shows `: i32`
vscode ---- task provider runs `botopink check` into Problems panel
vscode ---- codeLens "Run test" appears above each test block
vscode ---- Test Explorer lists and runs workspace test blocks
```

## Notes

- Keep the `vscode-extension/AGENTS.md` rule: the extension carries **no
  compiler knowledge**. Semantic classification comes from the LSP
  (`semanticTokens`); CodeLens/Test-Explorer wiring is UI only, driven by LSP
  symbols + the CLI.
- F0/F1 are server-driven and independent; F2–F4 are extension-side and can run
  in parallel once `tooling-update` F3 (test-block symbols) lands.
- Reuse the existing `format` command for LSP `formatting` rather than
  duplicating logic.

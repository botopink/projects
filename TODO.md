# TODO — sublanguage-vscode  (vscode · Wave 2 of 3)

> Task branch `task/sublanguage-vscode` · spec
> [`tasks/v0.beta.10/specs/sublanguage-vscode.md`](tasks/v0.beta.10/specs/sublanguage-vscode.md).
> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test (no `--no-verify`).
> **Depends on:** `sublanguage-lsp` at **runtime** (consumes its semantic tokens) —
> author this last and verify against a running `botopink-lsp`. The highlight is
> comptime-driven from the LSP; VSCode is a pure renderer (no SQL/HTML grammar).

## F0 — don't swallow the string interior as one opaque scope
- [x] **Chose option (a):** keep the `string.quoted` scopes and let the LSP's
      semantic tokens override the interior per-range. `package.json` forces
      `editor.semanticHighlighting.enabled: true` for `[botopink]`, so semantic
      tokens win across *every* theme (not just the default dark/light ones that
      opt in). A plain string carries no semantic tokens → stays `string`-coloured
      (F2 "unchanged"). Decision documented in the `strings` repository comment.
      Option (b) was rejected: a neutral interior scope would de-colour plain
      strings too, since the grammar can't tell sub-language strings apart.

## F1 — semantic token type mapping
- [x] Added `contributes.semanticTokenScopes` in `package.json` mapping each
      sub-language token type (keyword/property/string/number/operator) to fallback
      TextMate scopes, so themes that don't directly style the semantic type still
      colour it. `extension.ts` unchanged — `vscode-languageclient` auto-registers
      the semantic-tokens feature once the server advertises the provider.

## F2 — verify end-to-end in the editor
- [~] **Gated on `sublanguage-lsp`** (runtime dependency). The LSP does not yet
      emit semantic tokens for string interiors / sub-language content
      (`language-server/src/engine.zig` `semanticTokens()` skips string literals;
      legend in `protocol.zig` lacks `string`/`number`/`operator`). The renderer
      side is complete and correct; live `erika "select …"` verification must be
      done once `sublanguage-lsp` lands its F0–F4. The manifest is ready for it.

## F3 — optional static fallback (follow-up, not blocking)
- [ ] **Optional (follow-up, omitted):** a prefix-keyed TextMate injection would
      fight the semantic tokens and can never know the real fields/bindings — left
      out deliberately; the comptime-driven LSP path is the source of truth.

## Done gate
- [~] `erika "…"` highlighted by LSP semantic tokens / squiggle / unchanged plain
      string / survives theme switches — **renderer ready, blocked on
      `sublanguage-lsp`** for the live editor check (see F2).
- [ ] `zig build && zig build test` green (pre-commit; extension edits are
      JSON/Markdown only and don't touch Zig).

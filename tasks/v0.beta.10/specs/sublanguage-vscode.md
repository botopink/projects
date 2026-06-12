# sublanguage-vscode — render the LSP's sub-language tokens inside string literals

**Slug**: sublanguage-vscode
**Depends on**: [`sublanguage-lsp`](sublanguage-lsp.md) at runtime (it consumes the LSP's semantic tokens)
**Files**: `modules/vscode-extension/syntaxes/botopink.tmLanguage.json`, `modules/vscode-extension/src/extension.ts`, `modules/vscode-extension/package.json` (semantic token theme mapping if needed)
**Touches docs**: `modules/vscode-extension/AGENTS.md`
**Status**: pending

> **The highlight is comptime-driven from the LSP, not a static grammar.** The user
> asked "can't this be comptime?" — yes. The work here is to let the LSP's semantic
> tokens *win* inside string literals, not to hand-write a SQL/HTML TextMate grammar.

## Intent — let VSCode show what the LSP computed (#3 / the user's question)

The LSP ([`sublanguage-lsp`](sublanguage-lsp.md)) emits semantic tokens for the
sub-language content of `erika "…"` / `html """…"""`. The `vscode-languageclient`
already forwards `textDocument/semanticTokens/full`, so VSCode receives them. The
one obstacle: today the TextMate grammar paints the whole string interior as one
opaque `string.quoted` scope, and a theme's string colour can visually dominate.
This spec makes the semantic tokens take effect inside strings.

## Steps

### F0 — don't swallow the string interior as one opaque scope
- [ ] In `botopink.tmLanguage.json` (strings, ~lines 125-164), stop emitting a
      single `string.quoted` span over the *entire* triple-quoted / prefixed-string
      body so semantic tokens have ranges to colour. Either (a) keep the string scope
      but rely on semantic-token override (verify the active themes let semantic
      tokens win over `string`), or (b) give the interior a neutral
      `meta.embedded.block.botopink`-style content scope (mirroring the markdown
      code-block injection in `botopink.codeblock.json`) that defers to semantic
      tokens. Pick whichever renders correctly across the default dark/light themes.

### F1 — semantic token type mapping
- [ ] Ensure every semantic token type the LSP uses for sub-languages
      (`keyword`/`property`/`string`/`number`/`operator`) has a theme mapping so it
      renders. Add `semanticTokenScopes` / `configurationDefaults` in `package.json`
      if a type would otherwise be uncoloured.

### F2 — verify end-to-end in the editor
- [ ] With the LSP running, open a `.bp` with `erika "select name from users where
      age >= 18"`: confirm `select`/`from`/`where` render as keywords, `name`/`users`
      as properties, the literal/number distinctly — driven by the LSP, updating as
      the query changes. A malformed query shows the squiggle from F2 of the LSP spec.
- [ ] Confirm a plain (non-sub-language) string is visually unchanged.

### F3 — optional static fallback (follow-up, not blocking)
- [ ] **Optional:** a minimal TextMate injection keyed on the `erika`/`html` prefix
      for an instant pre-LSP highlight. Record it as a follow-up — the comptime-driven
      LSP path is the source of truth; the static grammar can never know the real
      fields/bindings, so it stays a best-effort cosmetic fallback, omitted if it
      fights the semantic tokens.

## Test scenarios

```
editor ---- erika "…" content is highlighted by the LSP's semantic tokens, live
editor ---- malformed query shows the LSP diagnostic squiggle inside the string
editor ---- a plain string literal is unchanged
editor ---- the sub-language tokens survive theme switches (dark/light)
```

## Notes

- No SQL/HTML grammar is authored — that would be the static, non-comptime path the
  user is moving away from. VSCode is a pure renderer of LSP-computed tokens.
- `extension.ts` likely needs **no** change (the client already forwards semantic
  tokens); the work is grammar-scoping + theme mapping. Confirm the client requests
  semantic tokens (it does when the server advertises the provider).
- This spec is small and depends on the LSP spec only at runtime — author it last,
  verify against a running `botopink-lsp`. Memory: [[project_v0beta5_frameworks]]
  (jhonstart/html context), [[project_jhonstart_language_gaps]].

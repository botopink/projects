# sublanguage-lsp — the language-server "sees" embedded sub-languages via the Custom AST

**Slug**: sublanguage-lsp
**Depends on**: [`expr-custom`](expr-custom.md) — reads the `CustomNode` trees through the core tooling-access API
**Files**: `modules/language-server/src/engine.zig`, `modules/language-server/src/compiler.zig`, `modules/language-server/src/server.zig` (capabilities), `modules/language-server/src/protocol.zig` (token legend if extended)
**Touches docs**: `modules/language-server/AGENTS.md`
**Status**: pending

> **Generic.** The LSP knows `CustomNode`, not SQL. It maps `node.label` → a
> semantic-token type and `node.ref` → an origin symbol. Any lib that returns
> `@ExprCustom` (erika today, `html` later) lights up with no LSP change. This is the
> **comptime-driven** highlight: the tokens come from the lib's own analysis, run by
> the LSP, not from a static grammar.

## Intent — #5: dispose the sub-language + make associations

Today string literals are opaque to the LSP (`engine.zig:2545` even disables
completion inside strings). The LSP already runs the full compile (`compiler.zig`
→ `compileTypesOnly`), which **expands the template fns at comptime** — so the
`erika "…"` body runs and (with [`expr-custom`](expr-custom.md)) produces a
`CustomNode` tree stored by location. This spec consumes that tree.

```
botopink-lsp compiles the doc
   → comptime expansion runs erika's lexer/parser
   → CustomNode trees available via the core tooling API (per erika "…" site)
   → LSP emits: semantic tokens (label→type) · diagnostics (failAt) · hover/def (ref)
   → VSCode renders them inside the string
```

## Steps

### F0 — pull the Custom AST into the engine
- [ ] After `compileTypesOnly`, read the `{ loc, callee, root: CustomNode }` entries
      from the core tooling-access API (expr-custom F3). Map each node's `span`
      (offset into the template text) + the template's `Source` to an absolute
      document range (reuse the existing offset↔position conversion in
      `lsp_types.zig`).

### F1 — semantic tokens for string content
- [ ] In `engine.semanticTokens()` (`engine.zig:2281`), after the normal lexer pass,
      emit additional tokens for every `CustomNode` range, typed by `label`
      (`keyword`/`property`/`string`/`number`/`operator` → existing legend entries;
      add any missing type to the legend at `engine.zig:244` + `protocol.zig`).
      These override the opaque `string` token for the covered ranges. Delta-encoding
      stays sorted (insert the sub-language tokens in document order).

### F2 — diagnostics from the sub-language
- [ ] Confirm a sub-language `q.failAt(span, msg)` surfaces as a `validationError`
      (`compiler.zig:86`) and that its span maps to the **range inside the string**,
      not the whole template. Add an LSP diagnostics test with a malformed
      `erika "…"`.

### F3 — associations: hover + go-to-definition (#5)
- [ ] Hover over a `CustomNode` with a `ref: Binding` shows the bound symbol (kind +
      name). Go-to-definition on such a node jumps to that symbol's declaration
      (reuse `handleDefinition`, `server.zig:297`, via the `Binding`). Relax the
      in-string guard (`engine.zig:2545`) for ranges covered by a Custom AST so these
      features work inside the literal.

### F4 — capabilities + docs
- [ ] If the token legend grew, re-advertise it in `handleInitialize`
      (`server.zig:142`). Document the sub-language path in
      `language-server/AGENTS.md`. Add snapshot tests under `snapshots/lsp/` for an
      `erika "…"` document (semantic tokens + a diagnostic + a hover).

## Test scenarios

```
lsp ---- erika "select name from users": select/from → keyword tokens, name/users → property
lsp ---- a malformed query yields a diagnostic whose range is inside the string
lsp ---- hover on the source token shows the bound collection symbol (via ref)
lsp ---- go-to-definition on the source token jumps to its declaration
lsp ---- a plain string with no sub-language is unchanged (still opaque)
```

## Notes

- **Comptime-driven, not TextMate.** This is the answer to "can the highlight be
  comptime?" — yes: the LSP runs the lib's comptime analysis and serves the tokens.
  The VSCode side ([[sublanguage-vscode]]) only renders them.
- Performance: the LSP already compiles on every change; the Custom AST is a
  by-product of that compile, so no extra evaluator run is needed beyond what
  `compileTypesOnly` already does. If template expansion proves too slow for
  keystroke latency, cache the Custom AST per document version (follow-up).
- Fully generic: html/markup adopting `@ExprCustom` gets the same treatment for
  free. Memory: [[feedback_compiler_unaware_of_jhonstart]].

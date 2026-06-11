# jhonstart-html-ast — a real markup lexer + AST + parser in the lib, emitting `@ExprCustom`

**Slug**: jhonstart-html-ast
**Depends on**: [`expr-custom`](expr-custom.md) — needs `@ExprCustom<T>` + `CustomNode` + `q.custom`
**Files**: `libs/jhonstart/src/html.bp` (lexer, AST, parser, dual lowering), `libs/jhonstart/test/*.bp`
**Touches docs**: `libs/jhonstart/AGENTS.md`, `libs/jhonstart/docs.md`
**Status**: pending

> **HARD RULE.** All of this is `libs/jhonstart/*.bp` — pure botopink in the comptime
> evaluator. No core code. The markup AST is **jhonstart's private type**; it is
> converted to the generic `CustomNode` tree only at the `q.custom(...)` boundary.
> The sibling of [[erika-query-ast]] — same mechanism, disjoint lib. Memory:
> [[project_jhonstart_language_gaps]], [[feedback_compiler_unaware_of_jhonstart]],
> [[feedback_prefer_bp_over_dbp]].

## Intent — replace the split/slice scanner with a proper front-end (#1, ②) for `html`

The current `html """…"""` body scans the markup with `split`/`slice`/`join` and a
`tagStack`/`childStack` state machine, building the builder-call pipeline as a
**string**. Exactly like erika's SQL form, this loses the markup's own tree, so
tooling can't see the HTML. This spec gives `html` the same three-stage front-end,
all in `html.bp`, so it joins erika as a tooling-visible sub-language:

```
html """<div class="card"><p>${name}</p></div>"""
   ② lexer → Token[]  → ② parser → MarkupNode tree (jhonstart's markup AST)
                                       ├─ ③ lower → @Expr<Element>  (div([p([text(name)])]) builder calls)
                                       └─ ④ lower → CustomNode      (generic reference tree)
                                return q.custom(customRoot, code)   → @ExprCustom<Element>
```

## Steps

### F0 — lexer (markup tokenizer with spans)
- [ ] A `Token { kind, text, span }` model (`kind`: `tagOpen`/`tagClose`/
      `tagSelfClose`/`attrName`/`attrValue`/`text`/`hole`). Scan the template's
      `parts()` (Text + `${…}` Interp holes) tracking byte offsets so every token —
      tag name, attribute, text run, hole — carries a real `Span`. Replaces the
      `split("<")`/`split(">")`/`slice`/`join` scanning (which destroys positions).
      Comptime-evaluator ops only; mind the gotchas
      ([[reference_bp_parser_comptime_gotchas]]).

### F1 — markup AST (jhonstart's private records)
- [ ] `MarkupNode` as a small tree: `Element { tag, attrs: Attr[], children:
      MarkupNode[], span }`, `Text { value, span }`, `Hole { exprIndex, span }` (an
      `${…}` interpolation — the already-typed caller expression, referenced by part
      index), `Attr { name, value, span }`. Plain botopink records — jhonstart's own
      model, not exposed to the core.

### F2 — parser (tokens → markup AST)
- [ ] Recursive-descent over the tag stream: open tag → push, matching close → pop,
      self-closing → leaf, text/hole → child of the current element, attributes
      attach to their element. A mismatched/unclosed tag reports `q.failAt(span, msg)`
      at the offending tag's span (so the LSP underlines it) — not a whole-template
      `fail`. Preserve the implicit-fragment behaviour (multiple roots wrap in a
      `fragment`, so the caller needn't import it).

### F3 — lowering ③: markup AST → `@Expr<Element>` (the executable builders)
- [ ] Walk `MarkupNode` and produce the builder-call expression: a lowercase tag →
      `tag([children])` resolved in the **caller's scope** (the consumer
      `import {div, p, …}` the builders; an unknown tag is a scoped error via
      `q.lookup`/`q.fail`); text parts → `text("…")`; `${expr}` holes splice the
      caller's typed expression as a child. **Behaviour parity** with today's html —
      the existing jhonstart tests + example stay green. `<Component/>` lookup stays a
      future layer.

### F4 — lowering ④: markup AST → `CustomNode` (the reference tree)
- [ ] Convert the same `MarkupNode` tree into a generic `CustomNode` tree: tag names
      → `label "tag"` (an editor maps it to a keyword/entity colour), attribute names
      → `"property"`, attribute string values → `"string"`, text runs → `"string"`/
      neutral, holes → a node spanning the `${…}` whose content stays normal botopink
      (the hole expression is already a typed botopink expr — leave it to the normal
      highlighter). Set `ref` on a tag node to the builder `Binding` it resolves to
      (via `q.lookup`), so the LSP can associate `<div>` with its imported builder (#5).
- [ ] `return q.custom(customRoot, code)`.

### F5 — tests (in `libs/jhonstart/test/`)
- [ ] Parser unit tests: nested tags, attributes, self-closing tags, text + `${}`
      holes mixed, the implicit-fragment multi-root case. A mismatched tag asserts a
      `failAt` at the right span.
- [ ] Behaviour parity: the existing jhonstart html tests + example still pass —
      `code` lowers to the same `Element` builder tree.

## Test scenarios

```
comptime ---- lexer tokenizes <div><p>x</p></div> with correct tag/text spans
comptime ---- parser builds the nested Element tree; mismatched close → failAt at span
run      ---- the lowered @Expr<Element> builds the same Element tree as today
comptime ---- CustomNode labels tags as "tag", attrs as "property", values as "string"
comptime ---- a ${hole} node spans the interpolation; tag ref points at its builder
```

## Notes

- Sibling of [[erika-query-ast]]: **same mechanism** (`@Expr<string>` → lex → private
  AST → dual lowering → `q.custom`), **disjoint lib** (`libs/jhonstart` vs
  `libs/erika`), so it's a separate, parallel spec per the granularity rule. Both
  prove the `@ExprCustom` carrier is generic across very different sub-languages
  (SQL vs markup).
- The reader/renderer specs ([[sublanguage-lsp]], [[sublanguage-vscode]]) are generic
  over `CustomNode` — they light up `html """…"""` with **no change** once this spec
  produces the tree. That genericity is the whole point.
- Holes (`${…}`) are botopink, not markup — keep them as normal botopink highlight;
  the markup tree only owns the tags/attrs/text around them.
- No new markup features (no `<Component/>`, no directives) — a real front-end for the
  existing surface. Memory: [[project_jhonstart_language_gaps]] (F2/html context).

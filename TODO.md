# TODO — jhonstart-html-ast (Wave 3 of 3, v0.beta.11)

**Branch**: `task/jhonstart-html-ast` (from `origin/feat` @ f50de6d)
**Slug**: jhonstart-html-ast · **Spec**: `tasks/v0.beta.11/specs/jhonstart-html-ast.md`
**Depends on**: `expr-custom` (landed in `feat`) — `@ExprCustom<T>` + `CustomNode` + `q.custom`
**Status**: pending

> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test
> (no `--no-verify`).

## HARD RULE

All of this is `libs/jhonstart/*.bp` — pure botopink in the comptime evaluator. **No
core code.** The markup AST is jhonstart's private type; converted to the generic
`CustomNode` tree only at the `q.custom(...)` boundary. Sibling of
[erika-query-ast] — same mechanism, disjoint lib. camelCase fn names.

## Intent — replace the split/slice scanner with a proper front-end for `html`

Today `html """…"""` scans markup with `split`/`slice`/`join` + a `tagStack`/
`childStack` state machine, building the builder-call pipeline as a **string**, so
tooling can't see the HTML. Give `html` the same three-stage front-end in `html.bp`:

```
html """<div class="card"><p>${name}</p></div>"""
   ① lexer → Token[] → ② parser → MarkupNode tree (jhonstart's markup AST)
                                    ├─ ③ lower → @Expr<Element>  (div([p([text(name)])]))
                                    └─ ④ lower → CustomNode       (generic reference tree)
                             return q.custom(customRoot, code) → @ExprCustom<Element>
```

## Steps

### F0 — lexer (markup tokenizer with spans)
- [ ] `Token { kind, text, span }` (`kind`: tagOpen/tagClose/tagSelfClose/attrName/
      attrValue/text/hole). Scan the template's `parts()` (Text + `${…}` Interp holes)
      tracking byte offsets so every token carries a real `Span`. Replaces the
      `split("<")`/`split(">")`/`slice`/`join` scanning. Comptime-evaluator ops only.

### F1 — markup AST (jhonstart's private records)
- [ ] `MarkupNode` tree: `Element { tag, attrs: Attr[], children: MarkupNode[], span }`,
      `Text { value, span }`, `Hole { exprIndex, span }` (a `${…}` interpolation — the
      already-typed caller expr by part index), `Attr { name, value, span }`. Plain
      botopink records, not exposed to the core.

### F2 — parser (tokens → markup AST)
- [ ] Recursive-descent over the tag stream: open tag → push, matching close → pop,
      self-closing → leaf, text/hole → child of current element, attributes attach to
      their element. Mismatched/unclosed tag → `q.failAt(span, msg)` at the offending
      tag (LSP underline), not a whole-template `fail`. Preserve implicit-fragment
      (multiple roots wrap in `fragment` so the caller needn't import it).

### F3 — lowering ③: markup AST → @Expr<Element>
- [ ] Produce the builder-call expr: lowercase tag → `tag([children])` resolved in the
      **caller's scope** (consumer `import {div, p, …}`; unknown tag → scoped error via
      `q.lookup`/`q.fail`); text → `text("…")`; `${expr}` holes splice the caller's
      typed expr as a child. Behaviour parity with today; `<Component/>` stays future.

### F4 — lowering ④: markup AST → CustomNode
- [ ] Convert the same `MarkupNode` tree to a generic `CustomNode` tree: tag names →
      `label "tag"`, attr names → `property`, attr string values → `string`, text →
      `string`/neutral, holes → a node spanning the `${…}` whose content stays normal
      botopink (already-typed expr — leave to the normal highlighter). Set `ref` on a
      tag node to the builder `Binding` it resolves to (via `q.lookup`).
- [ ] `return q.custom(customRoot, code)`.

### F5 — tests (`libs/jhonstart/test/`)
- [ ] Parser unit tests: nested tags, attributes, self-closing, text + `${}` holes
      mixed, the implicit-fragment multi-root case; a mismatched tag asserts `failAt`
      at the right span.
- [ ] Behaviour parity: existing jhonstart html tests + example still pass — `code`
      lowers to the same `Element` builder tree.

## Test scenarios

```
comptime ---- lexer tokenizes <div><p>x</p></div> with correct tag/text spans
comptime ---- parser builds the nested Element tree; mismatched close → failAt at span
run      ---- the lowered @Expr<Element> builds the same Element tree as today
comptime ---- CustomNode labels tags as "tag", attrs as "property", values as "string"
comptime ---- a ${hole} node spans the interpolation; tag ref points at its builder
```

## Notes

- Sibling of erika-query-ast: same mechanism (`@Expr<string>` → lex → private AST →
  dual lowering → `q.custom`), disjoint lib. Proves `@ExprCustom` is generic across
  SQL vs markup.
- The reader/renderer specs (sublanguage-lsp, sublanguage-vscode) are generic over
  `CustomNode` — they light up `html """…"""` with no change once this produces the tree.
- Holes (`${…}`) are botopink, not markup — keep them as normal botopink highlight.
- No new markup features (no `<Component/>`, no directives) — a real front-end for the
  existing surface.
- Keep `libs/jhonstart/AGENTS.md` + `docs.md` updated in the same commit.

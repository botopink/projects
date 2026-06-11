# TODO — jhonstart-html-ast (Wave 3 of 3, v0.beta.11)

**Branch**: `task/jhonstart-html-ast` (from `origin/feat` @ f50de6d)
**Slug**: jhonstart-html-ast · **Spec**: `tasks/v0.beta.11/specs/jhonstart-html-ast.md`
**Depends on**: `expr-custom` (landed in `feat`) — `@ExprCustom<T>` + `CustomNode` + `q.custom`
**Status**: DONE — F0–F5 implemented; 15 lib tests + 6 example tests green

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

### F0 — lexer (markup tokenizer with spans) — DONE
- [x] Token `record { kind, text, span(start/finish), code }` (`kind`: open/close/
      selfclose/attrName/attrValue/text/hole). The lexer walks `template.parts()`
      (Text + `${…}` Interp holes); each token records its source part text + base so
      its byte `Span` is recovered in the parser pass (no `i32` counter is mutated in
      the lexer's nested `forEach` — that trips comptime inference). Replaces the old
      `split("<")`/`split(">")`/`slice`/`join` scanning. Comptime-evaluator ops only.

### F1 — markup AST (jhonstart's private model) — DONE (conceptual)
- [x] The markup tree is realized in the parser's stack walk (open/close frames +
      child accumulators), the same way erika's SQL AST lives in its token scan —
      NOT as separately materialized `record Element/Text/Hole/Attr` values: the
      comptime evaluator emits only the `html` fn, so a sibling `record` lowers to a
      JS class the body can't `new`, and it has no array indexing to read a frame
      stack of node records back. Token records ARE anonymous `record { … }` (they
      lower to JS object literals); the named node types stay documentation.

### F2 — parser (tokens → markup tree) — DONE
- [x] A flat stack pass over the token stream: open tag → push name + "" child
      accumulator, matching close → pop and wrap `tag([...])`, self-closing → leaf,
      text/hole → child of current frame, attributes captured. A mismatched, unexpected,
      or unclosed tag → `q.failAt(span, msg)` at the offending tag (verified:
      `<div><p>hi</div>` → *mismatched closing tag `</div>`, expected `</p>`* at the
      `</div>` span), not a whole-template `fail`. Implicit-fragment preserved (a
      single root returns bare; multiple roots wrap in `fragment`).

### F3 — lowering ③: markup tree → @Expr<Element> — DONE
- [x] The builder-call string: lowercase tag → `tag([children])` resolved in the
      **caller's scope** (`q.lookup` sets the tag node's `ref`; an unknown tag stays an
      unbound diagnostic at the call site, parity); text → `text("…")`; `${expr}` holes
      splice the caller's typed expr via the `Interp` `code` placeholder. Behaviour
      parity with the old body (tests + example green); `<Component/>` stays future.

### F4 — lowering ④: markup tree → CustomNode — DONE
- [x] A generic `CustomNode` overlay (flat under one root, erika's shape): tag names →
      `label "tag"` + `q.lookup` `ref` to the builder `Binding`, attr names → `property`,
      attr values → `string`, text → `string`, holes → neutral `"none"` spanning the
      `Interp` (0-width per the infra — its content stays normal botopink highlight).
- [x] `return q.custom(customRoot, q.build(code))`.

### F5 — tests (`libs/jhonstart/test/`) — DONE
- [x] `test/html_test.bp`: nested tags, attributes, self-closing-shaped nesting, text +
      `${}` holes mixed, the implicit-fragment multi-root case, multi-line indentation.
      The mismatched-tag `failAt`/span is verified out-of-suite (a failing markup aborts
      compilation, so it can't be an in-suite `assert`).
- [x] Behaviour parity: `test/html_test.bp` (9) + `examples/jhonstart-html` (6) green —
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

- Sibling of erika-query-ast: same mechanism (`@Expr<string>` → lex → private AST →
  dual lowering → `q.custom`), disjoint lib. Proves `@ExprCustom` is generic across
  SQL vs markup.
- The reader/renderer specs (sublanguage-lsp, sublanguage-vscode) are generic over
  `CustomNode` — they light up `html """…"""` with no change once this produces the tree.
- Holes (`${…}`) are botopink, not markup — keep them as normal botopink highlight.
- No new markup features (no `<Component/>`, no directives) — a real front-end for the
  existing surface.
- Keep `libs/jhonstart/AGENTS.md` + `docs.md` updated in the same commit.

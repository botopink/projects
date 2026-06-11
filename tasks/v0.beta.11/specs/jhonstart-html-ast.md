# jhonstart-html-ast — a real markup lexer + AST + parser in the lib, emitting `@ExprCustom`

**Slug**: jhonstart-html-ast
**Depends on**: [`expr-custom`](expr-custom.md) — needs `@ExprCustom<T>` + `CustomNode` + `q.custom`
**Files**: `libs/jhonstart/src/html.bp` (lexer, AST, parser, dual lowering), `libs/jhonstart/test/*.bp`
**Touches docs**: `libs/jhonstart/AGENTS.md`, `libs/jhonstart/docs.md`
**Status**: IMPLEMENTED (commit `ed1bf30`) — front-end real (lexer → tokens → stack
parser → dual lowering → `q.custom`) verde: 9 testes `test/html_test.bp` + 6 do
`examples/jhonstart-html` + pre-commit em todos os backends. Três desvios do texto
literal ficam abaixo em **§ What is NOT done (deviations)** — todos deliberados e
alinhados ao irmão `erika-query-ast` já mesclado.

## What is NOT done (deviations from the literal spec)

1. **CustomNode is emitted FLAT (one root + flat children), not a nested tree.**
   F4 pede "convert the same MarkupNode tree into a generic `CustomNode` tree"
   (aninhada). Foi entregue plano-sob-um-root, **exatamente como o `erika "…"` já
   mesclado na `feat`** — cada token (tag/attr/value/text/hole) vira um nó com
   span+label+`ref`, todos sob um root `fragment`. Nenhum teste/consumidor exige
   aninhamento (o highlight do LSP usa spans+labels, não a hierarquia). Aninhar é
   possível bottom-up pela mesma pilha do parser — **follow-up opcional** se a
   tooling vier a precisar da árvore.

2. **The private markup AST (F1) is conceptual, not materialized as `record
   Element/Text/Hole/Attr`.** A HARD RULE proíbe código no core, e o avaliador
   comptime (`template_eval.zig`) emite SÓ a fn `html` sobre um prelúdio native-JS:
   um `record` nominal viraria classe JS que o corpo não consegue `new`, e não há
   indexação de array (`.at()`/`arr[i]`) pra reler uma pilha de nós-record. O "AST"
   vive na pilha do parser (frames open/close + acumuladores de filhos) — **igual
   ao AST SQL do erika**, que também não materializa records. Tokens são `record
   { … }` anônimos (viram object literals). Fechar isto exigiria mudar o core
   (proibido), então **não é fechável dentro da HARD RULE**.

3. **The "comptime unit tests" of the Test-scenarios block are not in-suite
   asserts.** O `CustomNode`/spans é reference-only (lido pelo language server, não
   inspecionável em runtime) e um markup inválido faz `q.failAt` **abortar a
   compilação** — logo não vira `assert`. A cobertura entregue: paridade por render
   (`test/html_test.bp`) + verificação do `failAt`/span fora da suíte
   (`<div><p>hi</div>` → *mismatched closing tag `</div>`, expected `</p>`* no span
   do `</div>`). A correção dos spans/labels do `CustomNode` é coberta pelos testes
   LSP do core (`sublanguage`), genéricos sobre `CustomNode` — não pela lib. Mesma
   escolha do erika.

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
- [x] A `Token { kind, text, span }` model (`kind`: `tagOpen`/`tagClose`/
      `tagSelfClose`/`attrName`/`attrValue`/`text`/`hole`). Scan the template's
      `parts()` (Text + `${…}` Interp holes) tracking byte offsets so every token —
      tag name, attribute, text run, hole — carries a real `Span`. Replaces the
      `split("<")`/`split(">")`/`slice`/`join` scanning (which destroys positions).
      Comptime-evaluator ops only; mind the gotchas
      ([[reference_bp_parser_comptime_gotchas]]).

### F1 — markup AST (jhonstart's private records) — ⚠ conceptual (see deviation #2)
- [~] `MarkupNode` as a small tree: `Element { tag, attrs: Attr[], children:
      MarkupNode[], span }`, `Text { value, span }`, `Hole { exprIndex, span }` (an
      `${…}` interpolation — the already-typed caller expression, referenced by part
      index), `Attr { name, value, span }`. Plain botopink records — jhonstart's own
      model, not exposed to the core.

### F2 — parser (tokens → markup AST) — done (iterative stack, not recursive descent)
- [x] Recursive-descent over the tag stream: open tag → push, matching close → pop,
      self-closing → leaf, text/hole → child of the current element, attributes
      attach to their element. A mismatched/unclosed tag reports `q.failAt(span, msg)`
      at the offending tag's span (so the LSP underlines it) — not a whole-template
      `fail`. Preserve the implicit-fragment behaviour (multiple roots wrap in a
      `fragment`, so the caller needn't import it).

### F3 — lowering ③: markup AST → `@Expr<Element>` (the executable builders) — done
- [x] Walk `MarkupNode` and produce the builder-call expression: a lowercase tag →
      `tag([children])` resolved in the **caller's scope** (the consumer
      `import {div, p, …}` the builders; an unknown tag is a scoped error via
      `q.lookup`/`q.fail`); text parts → `text("…")`; `${expr}` holes splice the
      caller's typed expression as a child. **Behaviour parity** with today's html —
      the existing jhonstart tests + example stay green. `<Component/>` lookup stays a
      future layer.
      > Note: an unknown tag is NOT hard-failed — it keeps today's parity (the
      > emitted `tag([...])` surfaces as an unbound diagnostic at the call site).
      > `q.lookup` is still consulted, to set the `CustomNode` `ref` (F4).

### F4 — lowering ④: markup AST → `CustomNode` (the reference tree) — ⚠ FLAT, not nested (deviation #1)
- [~] Convert the same `MarkupNode` tree into a generic `CustomNode` tree: tag names
      → `label "tag"` (an editor maps it to a keyword/entity colour), attribute names
      → `"property"`, attribute string values → `"string"`, text runs → `"string"`/
      neutral, holes → a node spanning the `${…}` whose content stays normal botopink
      (the hole expression is already a typed botopink expr — leave it to the normal
      highlighter). Set `ref` on a tag node to the builder `Binding` it resolves to
      (via `q.lookup`), so the LSP can associate `<div>` with its imported builder (#5).
      > Labels (`tag`/`property`/`string`/neutral) + per-tag `ref` are DONE; the tree
      > is FLAT (one root + flat children) like `erika`, not nested — see deviation #1.
- [x] `return q.custom(customRoot, code)`.

### F5 — tests (in `libs/jhonstart/test/`) — ⚠ behaviour-parity only (deviation #3)
- [~] Parser unit tests: nested tags, attributes, self-closing tags, text + `${}`
      holes mixed, the implicit-fragment multi-root case. A mismatched tag asserts a
      `failAt` at the right span.
      > Delivered as RENDER-based parity tests (the `CustomNode`/spans are
      > reference-only, not runtime-inspectable; an invalid markup `failAt`s and
      > aborts compilation, so it can't be an in-suite `assert`). The mismatched-tag
      > `failAt`/span was verified out-of-suite. See deviation #3.
- [x] Behaviour parity: the existing jhonstart html tests + example still pass —
      `code` lowers to the same `Element` builder tree (`test/html_test.bp` = 9,
      `examples/jhonstart-html` = 6).

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

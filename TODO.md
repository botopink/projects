# TODO — erika-query-ast (Wave 3 of 3, v0.beta.11)

**Branch**: `task/erika-query-ast` (from `origin/feat` @ f50de6d)
**Slug**: erika-query-ast · **Spec**: `tasks/v0.beta.11/specs/erika-query-ast.md`
**Depends on**: `expr-custom` (landed in `feat`) — `@ExprCustom<T>` + `CustomNode` + `q.custom`
**Status**: pending

> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test
> (no `--no-verify`).

## HARD RULE

All of this is `libs/erika/*.bp` — pure botopink in the comptime evaluator. **No core
code.** The SQL AST is erika's private type; it is converted to the generic
`CustomNode` tree only at the `q.custom(...)` boundary. camelCase fn names.

## Intent — replace the split/join scanner with a proper front-end

Today `erika "…"` normalizes the string with `split`/`join` and walks a flat token
list with a `mode` state machine, building the pipeline as a **string** for
`q.build(...)`. Replace it with a real three-stage front-end, all in `erika.bp`:

```
text → ① lexer → Token[] → ② parser → SelectStmt (erika's SQL AST)
                                        ├─ ③ lower → @Expr<T>     (of(…).where(…).toArray())
                                        └─ ④ lower → CustomNode   (generic reference tree)
                                 return q.custom(customRoot, code) → @ExprCustom<T>
```

## Steps

### F0 — lexer (tokenizer with spans)
- [x] `Token { kind, text, span }` (`kind`: keyword/ident/star/comma/op/string/
      number/paren). Scans `q.text()` char-by-char tracking byte offsets so every
      token carries a real `Span` — no more `split`/`join`. **Note:** every token is
      emitted through a *single* `append` site (the `pending` flush) — appending
      records from 3+ branchy sites trips a comptime type-checker mis-unification.

### F1 — SQL AST (erika's private records)
- [x] `SelectStmt`-shaped value (`star` / `fields` / `srcName`+`srcSpan` / `orGroups`
      / `orderName`+`orderSpan`+`orderDesc`), `Field { name, span }`, comparison
      records, `or`-of-`and`-of-comparison `where` tree. **Modelled with anonymous
      `record { … }`** (not named records): the comptime evaluator emits only the
      template fn + `Span`/`CustomNode`, so a named `Token(…)` ctor is undefined —
      anon records lower to plain JS object literals. Still erika-private, never
      exposed to core. `?where`/`?order` are 0-length-list / bool sentinels.

### F2 — parser (tokens → SQL AST)
- [x] Token-bucketing recursive-descent: `select` field-list (`*` or comma list),
      `from` source, optional `where` predicate (precedence: or < and < comparison,
      structural in the `orGroups` nesting), optional `order by field [asc|desc]`.
      A dangling-operator condition → `q.failAt(opSpan, msg)`; unknown collection →
      `q.failAt(srcSpan, msg)` — both at the offending token, not whole-template.

### F3 — lowering ③: SQL AST → @Expr<T>
- [x] Produces `of(source).where({row -> …}).orderBy(…).select({row -> …}).toArray()`.
      Behaviour preserved exactly (single-field unwraps; multi-field → `record {…}`;
      `*` → `toArray()`; `=`→`==`, `<>`→`!=`, `and`→`&&`, `'x'`→`"x"`). Source
      resolved via `q.lookup`; `q.failAt` if unknown. All 29 in-file tests green.

### F4 — lowering ④: SQL AST → CustomNode
- [x] Converts the same tokens to a generic `CustomNode` tree with `span` + a
      `label` per node (select/from/where/order/by/asc/desc → `keyword`; idents →
      `property`; string → `string`; number → `number`; comparison/logical ops →
      `operator`). `ref` set on the source node to the `q.lookup` `Binding`.
- [x] `return q.custom(customRoot, code)`.

### F5 — tests (in-file in `src/erika.bp`, the established convention)
- [x] Parser scenarios: `select *`, single/multi field, `where` with and/or/cmp
      (`+ precedence`), `order by … desc`, `<>`, the multi-line `"""…"""` form.
      (failAt-at-span is impl'd but un-`.bp`-testable — a malformed query aborts the
      module compile; covered by the generic sublanguage-lsp Zig fixtures instead.)
- [x] Behaviour parity: `examples/erika-linq` (6 green) + the 29 in-file tests pass.

## Test scenarios

```
comptime ---- lexer tokenizes "select a, b from xs" with correct spans
comptime ---- parser builds SelectStmt; where-precedence (or < and < cmp) is correct
run      ---- the lowered @Expr<T> runs identically to the pre-refactor pipeline
comptime ---- CustomNode tree labels select/from/where as keyword, fields as property
comptime ---- a syntax error reports failAt at the offending token's span
```

## Notes

- Dual lowering (③ executable, ④ reference) walks the **same** `SelectStmt` — one or
  two small passes driven by one AST so they never drift.
- No Option runtime → model "optional" as a sentinel or 0/1-length list (as today).
- No new SQL operators — same surface, just a real front-end.
- Keep `libs/erika/AGENTS.md` + `docs.md` updated in the same commit.

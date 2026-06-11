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
- [ ] `Token { kind, text, span }` (`kind`: keyword/ident/star/comma/op/string/
      number/paren). Scan `q.text()` char-by-char tracking byte offsets so every
      token carries a real `Span` — no more `split`/`join`. Comptime-evaluator ops
      only (native string index/slice; `if` is an expression; bare-`if` only last;
      no `?T` Option runtime).

### F1 — SQL AST (erika's private records)
- [ ] `SelectStmt { star: bool, fields: Field[], source: SourceRef, where: ?Predicate,
      orderBy: ?OrderBy }`; `Field { name, span }`; `SourceRef { name, span }`;
      `Predicate` (Compare/And/Or/Ident/Lit, each with span); `OrderBy { field, desc,
      span }`. Plain botopink records, not exposed to the core.

### F2 — parser (tokens → SQL AST)
- [ ] Recursive-descent: `select` field-list (`*` or comma list), `from` source,
      optional `where` predicate (precedence: or < and < comparison), optional
      `order by field [asc|desc]`. Malformed query → `q.failAt(span, msg)` at the
      offending token (LSP underline), not a whole-template `fail`.

### F3 — lowering ③: SQL AST → @Expr<T>
- [ ] Produce `of(source).where({row -> …}).orderBy(…).select({row -> …}).toArray()`.
      Preserve today's behaviour exactly (single-field projection unwraps; multi-field
      → `record {…}`; `*` → `toArray()`; `=`→`==`, `<>`→`!=`, `and`→`&&`, `'x'`→`"x"`).
      Resolve source in caller scope via `q.lookup`; `q.fail` if unknown. Keeps tests green.

### F4 — lowering ④: SQL AST → CustomNode
- [ ] Convert the same `SelectStmt` to a generic `CustomNode` tree with `span` + a
      `label` per node (select/from/where/order → `keyword`; idents → `property`;
      string → `string`; number → `number`; comparison/logical → `operator`). Set
      `ref` on the source node (+ resolvable columns) to the `q.lookup` `Binding`.
- [ ] `return q.custom(customRoot, code)`.

### F5 — tests (`libs/erika/test/`)
- [ ] Parser unit tests: `select *`, single/multi field, `where` with and/or/cmp,
      `order by … desc`, the multi-line `"""…"""` form; a malformed query asserts
      `failAt` at the right span.
- [ ] Behaviour parity: `examples/erika-linq` + the ~30 in-file tests still pass.

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

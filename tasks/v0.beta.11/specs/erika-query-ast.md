# erika-query-ast — a real SQL lexer + AST + parser in the lib, emitting `@ExprCustom`

**Slug**: erika-query-ast
**Depends on**: [`expr-custom`](expr-custom.md) — needs `@ExprCustom<T>` + `CustomNode` + `q.custom`
**Files**: `libs/erika/src/erika.bp` (lexer, AST, parser, dual lowering), tests in-file
**Touches docs**: `libs/erika/AGENTS.md`, `libs/erika/docs.md`
**Status**: DONE (F0–F4 complete; F5 with one un-automatable assertion — see below)

> **HARD RULE.** All of this is `libs/erika/*.bp` — pure botopink running in the
> comptime evaluator. No core code. The SQL AST is **erika's private type**; it is
> converted to the generic `CustomNode` tree only at the `q.custom(...)` boundary.
> Memory: [[project_erika_dsl_done]], [[feedback_prefer_bp_over_dbp]],
> [[feedback_camelcase_naming]].

## Intent — replace the split/join scanner with a proper front-end (#1, ②)

The current `erika "…"` body normalizes the string with `split`/`join` and walks a
flat token list with a `mode` state machine, building the pipeline as a **string**
for `q.build(...)`. This spec replaces that with a real, three-stage front-end, all
in `erika.bp`:

```
text → ① lexer → Token[]  → ② parser → SelectStmt (erika's SQL AST)
                                          ├─ ③ lower → @Expr<T>  (of(…).where(…).toArray())
                                          └─ ④ lower → CustomNode (generic reference tree)
                                   return q.custom(customRoot, code)   → @ExprCustom<T>
```

## Steps

### F0 — lexer (tokenizer with spans)
- [ ] A `Token { kind, text, span }` model (`kind`: `keyword`/`ident`/`star`/
      `comma`/`op`/`string`/`number`/`paren`). Scan `q.text()` character-by-character
      tracking byte offsets so every token carries a real `Span` into the source —
      no more `split`/`join` (which destroys positions). Keep to comptime-evaluator
      ops (native string indexing/slicing; see [[reference_bp_parser_comptime_gotchas]]
      — no `?T` Option runtime; `if` is an expression; bare-`if` only last).

### F1 — SQL AST (erika's private records)
- [ ] `SelectStmt { star: bool, fields: Field[], source: SourceRef, where: ?Predicate,
      orderBy: ?OrderBy }`; `Field { name, span }`; `SourceRef { name, span }`;
      `Predicate` (a small expression tree: `Compare`/`And`/`Or`/`Ident`/`Lit`, each
      with a span); `OrderBy { field, desc, span }`. Plain botopink records — erika's
      own model, not exposed to the core.

### F2 — parser (tokens → SQL AST)
- [ ] Recursive-descent: `select` field-list (`*` or comma-separated), `from`
      source, optional `where` predicate (precedence: `or` < `and` < comparison),
      optional `order by field [asc|desc]`. On a malformed query, `q.failAt(span,
      msg)` at the offending token's span (so the LSP can underline it) — not a
      whole-template `fail`.

### F3 — lowering ③: SQL AST → `@Expr<T>` (the executable pipeline)
- [ ] Walk `SelectStmt` and produce the `of(source).where({row -> …}).orderBy(…)
      .select({row -> …}).toArray()` expression. Preserve today's behaviour exactly
      (single-field projection unwraps; multi-field → `record { … }`; `*` →
      `toArray()`; predicate operator mapping `=`→`==`, `<>`→`!=`, `and`→`&&`, `'x'`
      → `"x"`). Resolve the source collection in the caller's scope via `q.lookup` —
      `q.fail` if unknown. This half keeps the existing tests green.

### F4 — lowering ④: SQL AST → `CustomNode` (the reference tree)
- [ ] Convert the same `SelectStmt` into a generic `CustomNode` tree: each token/
      node carries its `span` + a `label` for tooling (`select`/`from`/`where`/`order`
      → `"keyword"`; field/source/column idents → `"property"`; string lit →
      `"string"`; number → `"number"`; comparison/logical ops → `"operator"`). Set
      `ref` on the source node (and, where resolvable, column nodes) to the
      `q.lookup` `Binding`, so the LSP can associate them (#5).
- [ ] `return q.custom(customRoot, code)`.

### F5 — tests (in `libs/erika/test/`)
- [ ] Parser unit tests: `select *`, single/multi field, `where` with `and`/`or`/
      comparisons, `order by … desc`, the multi-line `"""…"""` form. A malformed
      query asserts a `failAt` at the right span.
- [ ] Behaviour parity: the existing `examples/erika-linq` + the ~30 in-file tests
      still pass — `code` runs identically.

## Test scenarios

```
comptime ---- lexer tokenizes "select a, b from xs" with correct spans
comptime ---- parser builds SelectStmt; where-precedence (or < and < cmp) is correct
run      ---- the lowered @Expr<T> runs identically to the pre-refactor pipeline
comptime ---- CustomNode tree labels select/from/where as keyword, fields as property
comptime ---- a syntax error reports failAt at the offending token's span
```

## Notes

- The dual lowering (③ executable, ④ reference) walks the **same** `SelectStmt` —
  keep them in one pass or two small passes, but driven by one AST so they never
  drift.
- Comptime constraints push the parser toward explicit records + index/slice ops;
  no Option runtime, so model "optional" as a sentinel or a 0/1-length list, as the
  current code does for `where`/`order`.
- No new SQL operators — same surface as today, just a real front-end. New operators
  are a follow-up. Memory: [[project_v0beta9_tail]] (erika tail context).

## Status — what landed (commit `d764df3`, `task/erika-query-ast`)

All in `libs/erika/src/erika.bp`, zero core code (HARD RULE held):

- **F0 lexer** — DONE. Char-by-char scan of `q.text()` → `Token[]`, each token with a
  real `Span`. Implementation note: every token is emitted through a **single**
  `toks.append` site (the `pending` flush) — appending records from 3-plus branchy
  sites trips a comptime type-checker mis-unification (`expected string, got array`).
- **F1 SQL AST** — DONE, with a **deliberate deviation**: the AST is modelled with
  **anonymous `record { … }`** values, **not named records** (`SelectStmt`/`Token`/…).
  The comptime evaluator emits only the template fn plus the `Span`/`CustomNode`
  prelude, so a named `Token(…)` constructor is `undefined` at eval time; anonymous
  records lower to plain JS object literals and stay erika-private. `?where`/`?order`
  are 0-length-list / bool sentinels (no Option runtime), as the spec allows.
- **F2 parser** — DONE. Token-bucketing descent; `where` parsed into `or`-of-`and`-of-
  comparison groups so `or < and < comparison` precedence is structural. `q.failAt`
  at the offending token for a dangling operator and for an unknown collection.
- **F3 lowering → `@Expr<T>`** — DONE. Byte-identical to the pre-refactor pipeline;
  all 25 pre-existing tests stay green.
- **F4 lowering → `CustomNode`** — DONE. Same tokens → labelled reference tree; source
  node carries the `q.lookup` `ref`. `return q.custom(root, q.build(pipe))`.
- **F5 tests** — DONE *except one assertion* (below). 4 new in-file tests cover
  `and`/`or`/precedence/`<>`; 29 in-file + `examples/erika-linq` (6) pass; full
  `zig build test` green.

### NOT done / known limitation

- **No `.bp` test asserts `failAt` at a span.** A malformed `erika "…"` query inside a
  `.bp` file makes `q.failAt` **abort that module's compilation**, so it cannot live
  as a passing `botopink test` block (no negative-test / `#[test(fails)]` builtin
  exists in botopink). The `failAt`-ranged-at-span path *is* implemented and was
  verified manually (`condition needs a value after '>='` and `unknown collection`,
  each at the right column). The generic builtin path is covered by the synthetic
  **Zig** fixtures `sublanguage F2` (language-server) and `template: fail span maps`
  (comptime templates) — kept lib-agnostic on purpose (the core never names erika).
  Closing this would need either a botopink negative-test builtin or a new synthetic
  Zig fixture for the dangling-operator case — both out of scope here.
- **`ref` is set on the source node only**, not (yet) on resolvable column nodes —
  F4 lists columns as optional ("where resolvable"); left as a follow-up.

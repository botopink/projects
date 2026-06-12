# expr-custom — `@ExprCustom<T>`: a template return that carries both executable code and a reference AST

**Slug**: expr-custom
**Depends on**: nothing (builds on the `@Expr` template mechanism already in `feat`)
**Files**: `libs/std/src/builtins.d.bp` (the `@Expr`/`std.syntax` surface), `modules/compiler-core/src/comptime/infer.zig`, `modules/compiler-core/src/comptime/template.zig`, `modules/compiler-core/src/comptime/template_eval.zig`, `modules/compiler-core/src/comptime/env.zig`, `modules/compiler-core/src/comptime/transform.zig`, `modules/compiler-core/src/root.zig` (tooling-access API)
**Touches docs**: `modules/compiler-core/src/comptime/AGENTS.md`, `libs/std/src/builtins.d.bp`
**Status**: pending

> **HARD RULE.** The core learns **nothing** about any sub-language. It gains one
> generic carrier type (`@ExprCustom<T>` = executable code + an opaque reference
> tree of `CustomNode`s) and the machinery to splice the code and store the tree.
> `kind`/`label` on a node are **opaque strings the lib chose** — the core never
> branches on `"select"`/`"where"`/`"sql"`. The lib-agnostic gate
> (`grep -riE "rakun|jhonstart|erika" compiler-core/src`) stays green. Memory:
> [[feedback_no_lib_specific_in_core]], [[feedback_compiler_unaware_of_jhonstart]].

## Intent — the keystone of the pipeline

A sub-language template fn today returns `@Expr<T>`: it builds a **string** of
botopink source and `q.build("…")` re-parses it. That loses the sub-language's own
tree, so tooling can never "see" the SQL/markup. This spec adds a return that
carries **two** things at once — the user's model (steps ③/④):

```
erika "select name, age from users where age >= 18"
   ② lex+parse → erika's OWN SQL AST (lib-internal)
   ③ SQL AST → @Expr<T> botopink   (the of(…).where(…).toArray() that RUNS)
   ④ SQL AST → CustomNode tree     (generic, canonical, spans+labels — reference only)
   ⑤ return q.custom(tree, code)   → @ExprCustom<T>
```

The **`code`** half travels the existing `@Expr<T>` path (re-inferred in the
caller, spliced, lowered to every backend) — runtime behaviour is unchanged. The
**`tree`** half is stored by call-location and never affects execution; it is the
"standard custom AST, for reference" the language-server reads (#5).

## New surface (generic — `std.syntax`, `libs/std/src/builtins.d.bp`)

```bp
// A node of ANY embedded sub-language, in one canonical shape the core/tooling
// understand without knowing the language. `kind`/`label` are opaque tags the
// lib picks; `span` indexes the @Expr<string> source text; `ref` optionally ties
// a node (e.g. a queried collection, a column) to a caller-scope symbol.
pub struct CustomNode {
    kind: string,             // lib-chosen tag: "select" / "field" / "predicate" / "literal" …
    span: Span,               // offsets into the template's source text (Span already exists)
    label: string,            // semantic category tooling maps to a token type: "keyword"/"property"/"string"/"number"/"operator"
    ref: ?Binding,            // optional association to an origin-scope symbol (a q.lookup result)
    children: CustomNode[],
}

// What `@ExprCustom<T>` lowers to: the executable expression + the reference tree.
pub struct CustomExpr<T> {
    code: Expr<T>,            // ③ — the botopink expression that actually runs
    ast: CustomNode,          // ④ — the sub-language tree, reference only
}

pub interface Expr<E> {
    // … existing methods (text/parts/source/context/lookup/bindings/build/fail/failAt) …
    // Pack a reference tree + the executable code into the custom return.
    fn custom<R>(self: Self, ast: CustomNode, code: Expr<R>) -> CustomExpr<R>
}
```

A template fn opts in by its return type: `pub fn erika<T>(comptime q: @Expr<string>)
-> @ExprCustom<T>`. `CustomNode`/`Span`/`Binding` are plain public structs the lib
fills with record literals — no per-node core builders needed beyond `q.custom`.

## Steps

### F0 — recognize `@ExprCustom<T>` as a template return
- [ ] `ast.zig`: an `isExprCustomType(TypeRef)` sibling of `isExprType` (builtin
      generic named `ExprCustom`). `infer.zig`: a fn returning `@ExprCustom<T>` is a
      template fn (extend the `env.templateFns` / `inTemplateFn` detection at the
      existing `isExprType` sites, ~`infer.zig:2102`/`1995`).

### F1 — the carrier type + `q.custom`
- [ ] Add `CustomNode` / `CustomExpr<T>` + `Expr.custom` to `builtins.d.bp`.
- [ ] `template_eval.zig`: the comptime evaluator must serialize a returned
      `CustomExpr` (the `code` as the existing expansion outcome; the `ast` as a JSON
      `CustomNode` tree) and the core must deserialize both. Extend the runtime
      outcome union (`code`/`value`/`capture`/`fail`) with a `custom { code, ast }`
      variant.

### F2 — split the two halves
- [ ] **code →** feed `code` into the existing expansion path
      (`finishExpansion`/`substituteHoles`, `infer.zig:2418`) exactly as a plain
      `@Expr<T>` return: re-infer in the caller, splice, record in
      `env.templateExpansions`. Backends and the transform pass see only the spliced
      botopink — **zero runtime/codegen change**.
- [ ] **ast →** store the `CustomNode` root keyed by the call location in a new
      `env.customAstByLoc` (sibling of `templateExpansions`). It is never lowered,
      never reaches codegen.

### F3 — tooling-access API (generic)
- [ ] Expose a read API from `compiler-core` `root.zig`: given a compiled module,
      return the list of `{ loc, callee, root: CustomNode }` custom-AST entries. This
      is what `sublanguage-lsp` consumes. No sub-language names; just the canonical
      node shape. Spans are relative to each template's source text; the API also
      surfaces each template's `Source` (file/line/col of the opening quote) so a
      consumer can map a `span` to an absolute document position.

### F4 — docs + gate
- [ ] `comptime/AGENTS.md`: document the `@ExprCustom` model (code vs reference
      tree, the storage-by-location, the tooling API). Confirm the lib-agnostic gate
      stays green — add a test that `grep -riE "select|sql"` style sub-language
      vocabulary does not appear in the new core code.

## Test scenarios

```
infer   ---- a fn returning @ExprCustom<T> is recognized as a template fn
run     ---- q.custom(tree, code) executes `code` identically to returning that @Expr<T>
core    ---- the CustomNode tree is retrievable by call-location via the tooling API
core    ---- span offsets resolve against the template text; ref carries a Binding
gate    ---- grep finds no sub-language vocabulary in compiler-core/src
```

## Notes

- The `code` half is behaviourally identical to today's `@Expr<T>` return — this is
  a **superset**, not a rewrite. A lib can still return plain `@Expr<T>`; `custom`
  is opt-in for libs that want tooling visibility.
- The reference tree is **canonical and generic on purpose** (the user's "AST custom
  padrão só para referência"): erika converts its private SQL AST into `CustomNode`s
  at the boundary, so the core/LSP handle every sub-language uniformly. The lib's own
  SQL AST never enters the core.
- `ref: ?Binding` is what powers the LSP "associações" (#5) — a column/source node
  can point at the caller-scope symbol it resolves to (via the existing `lookup`).
- Consumers: [[erika-query-ast]] (producer) and [[sublanguage-lsp]] (reader). The
  `html` DSL in jhonstart can later adopt `@ExprCustom` with no core change.

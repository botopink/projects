# Tooling — Language Server + Formatter + Language Features

**Branch**: `feat/tooling` (or split into `feat/lsp`, `feat/formatter`)
**Depends on**: the corresponding syntax features (import, use, implement) for their specific parts
**Status**: done

## Language Server
- [x] Go-to-definition for imported symbols — `engine.definitionInModules` resolves a
      symbol to a `pub` declaration in another module; the server gathers candidate
      module sources from `ProjectIndex` on a local miss.
- [x] Auto-complete for record/struct fields — `dotCompletion` now completes members
      both for value receivers (`origin.`) and type-name receivers (`Point.`).
- [x] Auto-complete for enum variants — `Status.` lists variants (fixed: the type-decl
      binding is matched directly instead of via its mangled named type).
- [x] Diagnostic squiggles for type errors — inference errors are no longer swallowed;
      `analyzeModule` surfaces a located `typeError` outcome that the LSP renders as a
      diagnostic (and `botopink check` prints).

## Formatter
- [x] Format `@Result<D, E>` consistently (already correct; covered by tests)
- [x] Format `comptime` param modifiers with type constraints (already correct; tested)
- [x] Format `@Context<B, R>` implementations — inline `struct implement @Context<B, R>`
      round-trips (tested)

## Language Features

### Lambda syntax
- [x] Lambda with full type annotations: `val f: fn(string, i32) -> string = { s, i -> … }`
      — `fn(...) -> ...` annotations now lower to a `.func` type and unify with lambdas.
- [x] Infer param types from context when an annotation is present — params bind to the
      annotated types *before* the body is inferred. (Note: only top-level `val`
      annotations carry context; local `val` bindings have no annotation slot, and
      passing a bare lambda to a `fn`-typed parameter still needs fn-typed params in
      regular `fn` decls — separate syntax work.)

### Pattern matching
- [~] Exhaustiveness checking for case expressions — partial (pre-existing): a single
      non-wildcard arm on an enum/string subject is rejected. Full coverage analysis is
      future work.
- [x] Nested pattern matching (pattern inside pattern) — `Ok(Some(n))` already works
      (tested).
- [x] Guard clauses: `case x { n if n > 0 -> … }` — parser, AST, inference (guard must be
      `bool`), formatter and commonJS codegen. Guard codegen for erlang/beam/wasm tracks
      those targets' own roadmaps.

## Examples

### Lambda with full type annotation
```bp
val f: fn(string, i32) -> string = { s, i -> s + i.to_string() };
```

### Guard clause
```bp
fn classify(n: i32) -> string {
    return case n {
        x if x > 0  -> "positive";
        0           -> "zero";
        _           -> "negative";
    };
}
```

### Nested pattern
```bp
fn unwrap(r: @Result<@Option<i32>, string>) -> i32 {
    return case r {
        Ok(Some(n)) -> n;
        Ok(None)    -> 0;
        Error(_)    -> -1;
    };
}
```

## Test scenarios

```
lsp ---- go-to-definition on imported symbol (import {std.List};)
lsp ---- autocomplete for struct/record field
lsp ---- autocomplete for enum variant
lsp ---- diagnostic squiggle on type error
formatter ---- @Result<D, E> formatted consistently
formatter ---- comptime param with type constraint
formatter ---- @Context<B, R> implementation
lambda ---- lambda with full type annotation infers params
lambda ---- lambda without annotation infers from context
pattern ---- non-exhaustive case → warning/error
pattern ---- nested pattern Ok(Some(n))
pattern ---- guard clause n if n > 0
```
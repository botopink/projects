# Tooling — Language Server + Formatter + Language Features

**Branch**: `feat/tooling` (or split into `feat/lsp`, `feat/formatter`)
**Depends on**: the corresponding syntax features (import, use, implement) for their specific parts
**Status**: pending

## Language Server
- [ ] Go-to-definition for imported symbols (`import {std.List};`)
- [ ] Auto-complete for record/struct fields
- [ ] Auto-complete for enum variants
- [ ] Diagnostic squiggles for type errors in the editor

## Formatter
- [ ] Format `@Result<D, E>` consistently
- [ ] Format `comptime` param modifiers with type constraints
- [ ] Format `@Context<B, R>` implementations

## Language Features

### Lambda syntax
- [ ] Lambda with full type annotations: `val f: fn(string, i32) -> string = { s, i -> … }`
- [ ] Infer param types from context when an annotation is present

### Pattern matching
- [ ] Exhaustiveness checking for case expressions
- [ ] Nested pattern matching (pattern inside pattern)
- [ ] Guard clauses: `case x { n if n > 0 -> … }`

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
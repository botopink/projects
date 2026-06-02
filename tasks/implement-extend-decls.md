# `implement` / `extend` — named declarations

**Branch**: `feat/implement-extend-decls`
**Phase**: F4 + F5
**Depends on**: nothing (independent). F4 and F5 are parallel to each other.
**Status**: pending (inline `struct implement` already parses — commits `abb4eb2`/`ce98b8d`)

## Target syntax

```bp
// trait impl — always NAMED
pub PatoNada implement Nada for Pato { fn swim(self: Self) { … } }    // shorthand
val PatoNada = implement Nada for Pato { … }                          // explicit
struct Pato implement Nada { … }                                      // inline (already exists)

// extension WITHOUT trait — new keyword `extend`
pub PatoExtra extend Pato { fn quack(self: Self) -> string { … } }    // shorthand
val PatoExtra = extend Pato { … }                                     // explicit
```

An anonymous impl/extension is an error (the name is required for `X*` activation in
`feat/import-rework`).

## Steps

### F4 — named implement shorthand
1. AST: `ImplementDecl { name: []const u8, isPub, trait: TypeRef, target: TypeRef, methods: []FnDecl }` (name required)
2. Parser: `pub? Name implement Trait for Type {}` → shorthand
3. Parser: `pub? val Name = implement Trait for Type {}` → explicit (already exists via val-form)
4. Parser: error if `implement Trait for Type {}` has no name
5. Format: preserve shorthand vs explicit
6. Snapshots: `implement_shorthand_named`, `implement_shorthand_named_pub`, `implement_anonymous_rejected`, `format/implement_shorthand_named`

### F5 — `extend Type {}`
1. Lexer: token `extend` (distinct from `extends`) + recognition in `identifierType`
2. AST: `ExtendDecl { name, isPub, target: TypeRef, methods: []FnDecl }` + `Decl.extend`
3. Parser: `pub? Name extend Type {}` / `pub? val Name = extend Type {}`
4. Parser: error if unnamed
5. Format: emit the original form
6. Snapshots: `extend_shorthand_named`, `extend_explicit_named`, `extend_anonymous_rejected`, `format/extend_shorthand_named`

## Test scenarios

```
parser ---- PatoNada implement Nada for Pato {}            (shorthand)
parser ---- pub PatoNada implement Nada for Pato {}        (pub)
parser ---- implement Nada for Pato {} (error: must be named)
parser ---- PatoExtra extend Pato {}
parser ---- val PatoExtra = extend Pato {}
parser ---- extend Pato {} (error: must be named)
```

## Notes

- Method resolution/dispatch is consumed by `feat/extension-dispatch` (F6).
- Broad interface/struct/record coverage (semantic validation, getter/setter,
  qualified disambiguation) lives in `interface-coverage.md`.
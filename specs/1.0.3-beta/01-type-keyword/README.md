# Front 01 — `type` keyword (unify `record` and `enum`)

**Priority:** critical — the type-system surface has four keywords (`record`, `enum`, `interface`,
`implement`) where two would do. The distinction between "named fields" and "tagged variants" is
a shape difference, not a declaration-kind difference.
**Depends on:** none
**Owns:** `lexer/token.zig`, `lexer.zig`, `parser/**`, `ast.zig` · `snapshots/parser/`, `snapshots/lexer/`
**Does not touch:** `comptime/**` (F2), `format.zig` (F3), `codegen/**` (F4–F7), `libs/**` (F8)

---

## Problem

Today the language has two declaration forms that share 80% of their structure:

```bp
record Point { x: i32, y: i32 }
enum Shape { Circle(radius: f64), Square(side: f64) }
```

Both:
- Take a name, optional generics, optional `implement` clause
- Contain members (fields or variants) with optional types and defaults
- May carry methods (`fn name(self: Self)`)
- Are constructed with `Name(args)` syntax
- Produce named types in the type environment

The only difference is the **shape of the body**: fields vs variants. That is a body-level
distinction, not a declaration-level one.

## Current state

Measured at HEAD:

| Keyword | Declarations in std | Declarations in libs | Parser entry points | AST node |
|---|---|---|---|---|
| `record` | 42 | 28 | `parseRecordDecl`, `parseShorthandRecordDecl` | `RecordDecl` |
| `enum` | 19 | 11 | `parseEnumDecl`, `parseShorthandEnumDecl` | `EnumDecl` |
| `interface` | 23 | 17 | `parseInterfaceDecl`, `parseShorthandInterfaceDecl` | `InterfaceDecl` |

Total: 83 type declarations that could be one keyword.

## Mechanism

The parser dispatches on the keyword token (`parser.zig:305–320` for shorthand, `parser.zig:444–453`
for val-form). The AST has three separate `DeclKind` variants (`ast.zig:1621–1629`). The type
environment registers them separately (`env.zig:26`: `TypeDef.record` vs `TypeDef.enum_`).

The unification collapses `RecordDecl` and `EnumDecl` into a single `TypeDecl` node. The parser
inspects the declaration to decide the shape:

- **Has `(fields)` before `{`** → record shape (form 1), parse fields from parentheses
- **Has `constructor(...)` inside `{`** → record shape (form 2), parse fields from constructor
- **Has only `{variants}`** → enum shape, parse variants from body
- **Has only `{methods}`** → namespace (record with no fields)
- **Mixed** → parse error (a type is either a record or an enum, not both)

Both record forms produce the same AST — the parser normalizes form 2 into the same shape as form 1.

## Proposal — the `type` keyword

### Syntax

Records have **two equivalent forms** — fields in parentheses or `constructor` in the body:

```bp
// Form 1: fields in parentheses (preferred for simple records)
pub type Point(x: i32, y: i32) {
    fn distance(self: Self) -> f64 {
        return (self.x * self.x + self.y * self.y).squareRoot();
    }
}

// Form 2: constructor in body (preferred when you want to group ctor with methods)
pub type Point {
    constructor(x: i32, y: i32)

    fn distance(self: Self) -> f64 {
        return (self.x * self.x + self.y * self.y).squareRoot();
    }
}

// Enum: variants in body (only form)
pub type Shape {
    Circle(radius: f64),
    Square(side: f64),
}

// Generic record — form 1
pub type Dict<K, V>(pairs: Array<#(K, V)>) {
    pub fn lookup(self: Self, key: K) -> ?V { ... }
}

// Generic record — form 2
pub type Dict<K, V> {
    constructor(pairs: Array<#(K, V)>)

    pub fn lookup(self: Self, key: K) -> ?V { ... }
}

// Generic enum
pub type Result<R, E> {
    Ok(result: R),
    Error(error: E),
}

// With implement — form 1
pub type Element(tag: string, children: Array<Element>) implement @Context<Element, Element> {
    pub fn render(self: Self) -> string { ... }
}

// With implement — form 2
pub type Element implement @Context<Element, Element> {
    constructor(tag: string, children: Array<Element>)

    pub fn render(self: Self) -> string { ... }
}

// Record with only methods (namespace) — no constructor
pub type Math {
    pub fn add(a: i32, b: i32) -> i32 { return a + b; }
    pub fn sub(a: i32, b: i32) -> i32 { return a - b; }
}

// Enum with sections (unchanged shape, new keyword)
pub type Token {
    Color {
        Red { 100, 200, 300 },
        Blue { 100, 200, 300 },
        Hex(value: string),
    }
    Pad {
        X { 1, 2, 4, 8 },
        Y { 1, 2, 4 },
    }
}
```

### Val-form (anonymous types)

```bp
// Record literal (unchanged semantics, new keyword)
val p = type { x: 10, y: 20 };

// Named type via val — form 1
val Point = type(x: i32, y: i32) {};

// Named type via val — form 2
val Point = type { constructor(x: i32, y: i32) };

// Enum via val
val Color = type { Red, Green, Blue };
```

### Constructor syntax (unchanged)

```bp
// Record construction
val p = Point(x: 10, y: 20);

// Enum variant construction
val c = Color.Red;
val r = Result.Ok(result: 42);
val s = Shape.Circle(radius: 5.0);
```

### Pattern matching (unchanged)

```bp
pub fn describe(s: Shape) -> string {
    return case s {
        Circle(radius) -> "circle with radius " + radius.toString(),
        Square(side) -> "square with side " + side.toString(),
    };
}
```

## Migration examples

### Example 1 — Simple record

**Before (1.0.2-beta):**
```bp
pub record Response {
    status: i32,
    body: string,
}
```

**After (1.0.3-beta) — Form 1 (preferred):**
```bp
pub type Response(status: i32, body: string) {
}
```

**After (1.0.3-beta) — Form 2 (alternative):**
```bp
pub type Response {
    constructor(status: i32, body: string)
}
```

### Example 2 — Generic record with methods

**Before:**
```bp
pub record Set<T> {
    items: Array<T>,
    pub fn contains(self: Self, x: T) -> bool { ... }
    pub fn size(self: Self) -> i32 { ... }
}
```

**After (1.0.3-beta) — Form 1:**
```bp
pub type Set<T>(items: Array<T>) {
    pub fn contains(self: Self, x: T) -> bool { ... }
    pub fn size(self: Self) -> i32 { ... }
}
```

**After (1.0.3-beta) — Form 2:**
```bp
pub type Set<T> {
    constructor(items: Array<T>)

    pub fn contains(self: Self, x: T) -> bool { ... }
    pub fn size(self: Self) -> i32 { ... }
}
```

### Example 3 — Simple enum

**Before:**
```bp
pub enum Order {
    Lt,
    Eq,
    Gt,
}
```

**After:**
```bp
pub type Order {
    Lt,
    Eq,
    Gt,
}
```

### Example 4 — Generic enum with payloads

**Before:**
```bp
pub enum Result<R, E> {
    Ok(result: R),
    Error(error: E),
}
```

**After:**
```bp
pub type Result<R, E> {
    Ok(result: R),
    Error(error: E),
}
```

### Example 5 — Enum with sections

**Before:**
```bp
pub enum Token {
    Color {
        Red { 100, 200, 300, 400, 500, 600, 700, 800, 900 },
        Blue { 100, 200, 300, 400, 500, 600, 700, 800, 900 },
        Hex(value: string),
    }
    Pad {
        X { 1, 2, 4, 8, 16 },
        Y { 1, 2, 4, 8 },
    }
    Hover(inner: Token[]),
}
```

**After:**
```bp
pub type Token {
    Color {
        Red { 100, 200, 300, 400, 500, 600, 700, 800, 900 },
        Blue { 100, 200, 300, 400, 500, 600, 700, 800, 900 },
        Hex(value: string),
    }
    Pad {
        X { 1, 2, 4, 8, 16 },
        Y { 1, 2, 4, 8 },
    }
    Hover(inner: Token[]),
}
```

### Example 6 — Record with `implement`

**Before:**
```bp
pub record Element implement @Context<Element, Element> {
    tag: string,
    value: string,
    children: Children,
    attrs: Array<#(string, string)>,
}
```

**After (1.0.3-beta) — Form 1:**
```bp
pub type Element(tag: string, value: string, children: Children, attrs: Array<#(string, string)>) implement @Context<Element, Element> {
}
```

**After (1.0.3-beta) — Form 2:**
```bp
pub type Element implement @Context<Element, Element> {
    constructor(tag: string, value: string, children: Children, attrs: Array<#(string, string)>)
}
```

### Example 7 — Anonymous record literal

**Before:**
```bp
val state = record { current: initial };
```

**After:**
```bp
val state = type { current: initial };
```

### Example 8 — Comptime `@expr` with record literal

**Before:**
```bp
pub fn conf<T>(comptime q: @Expr<string>) -> @Expr<T> {
    return @expr(record {
        server: record { host: "0.0.0.0", port: 8000 },
        debug: true,
    });
}
```

**After:**
```bp
pub fn conf<T>(comptime q: @Expr<string>) -> @Expr<T> {
    return @expr(type {
        server: type { host: "0.0.0.0", port: 8000 },
        debug: true,
    });
}
```

## Steps

### Step 1 — Lexer: add `type` and `constructor` keywords, remove `record`/`enum`

Add `type` and `constructor` to `TokenKind` in `lexer/token.zig`. In `lexer.zig:keywordOrIdent`,
map `"type"` and `"constructor"` to the new tokens. Remove `record` and `enum` from the keyword
table — they are no longer recognized.

**Acceptance:**
- [ ] `type` tokenizes as `TokenKind.type`
- [ ] `constructor` tokenizes as `TokenKind.constructor`
- [ ] `record` and `enum` are removed from the keyword table — using them produces a parse error
- [ ] `lexer/tests/` updated with the new tokens

### Step 2 — Parser: unify `parseRecordDecl` and `parseEnumDecl` into `parseTypeDecl`

Create `parseTypeDecl` and `parseShorthandTypeDecl` in `parser/decls.zig`. The parser inspects
the declaration to decide the shape:

- If `type Name(params)` has parentheses before `{` → record shape (form 1), parse fields from parentheses
- If `type Name { constructor(...) }` has constructor inside body → record shape (form 2)
- If `type Name { ... }` has only variants in body → enum shape
- If `type Name { ... }` has only methods in body → namespace (record with no fields)

Both record forms produce the same AST node. The parser normalizes form 2 into form 1 internally.

**Acceptance:**
- [ ] `type Point(x: i32, y: i32) {}` parses as a record-shaped `TypeDecl` (form 1)
- [ ] `type Point { constructor(x: i32, y: i32) }` parses as a record-shaped `TypeDecl` (form 2)
- [ ] `type Color { Red, Green, Blue }` parses as an enum-shaped `TypeDecl`
- [ ] `type Counter(n: i32) { fn current(self: Self) -> i32 { ... } }` parses as record with methods (form 1)
- [ ] `type Counter { constructor(n: i32); fn current(self: Self) -> i32 { ... } }` parses as record with methods (form 2)
- [ ] `type Math { fn add(a: i32, b: i32) -> i32 { ... } }` parses as namespace
- [ ] `record Name(x: i32) {}` produces a parse error (keyword removed)
- [ ] `enum Name { A, B }` produces a parse error (keyword removed)

### Step 3 — AST: introduce `TypeDecl`, remove `RecordDecl`/`EnumDecl`

In `ast.zig`, add:

```zig
pub const TypeDecl = struct {
    name: []const u8,
    id: u32 = 0,
    isPub: bool = false,
    annotations: []Annotation = &.{},
    genericParams: []GenericParam = &.{},
    implement: []TypeRef = &.{},
    shape: TypeShape,
    methods: []InterfaceMethod,
};

pub const TypeShape = union(enum) {
    record: []RecordField,
    enum_: []EnumVariant,
    sections: []EnumSection,
};
```

Keep `RecordDecl` and `EnumDecl` as internal AST nodes for one milestone to ease the migration
of downstream consumers (comptime, formatter, codegen), but the parser no longer produces them —
all type declarations produce `TypeDecl`.

**Acceptance:**
- [ ] `DeclKind` has a `.type_` variant carrying `TypeDecl`
- [ ] `DeclKind.record` and `DeclKind.@"enum"` are removed
- [ ] All parser tests pass with the new node

### Step 4 — Expression parser: `record { … }` becomes `type { … }`

In `parser/exprs.zig`, the record-literal expression (`record { name: value }`) becomes
`type { name: value }`. The AST node `Expr.recordLit` is renamed to `Expr.typeLit`.

**Acceptance:**
- [ ] `type { x: 10, y: 20 }` parses as a type literal
- [ ] `record { x: 10, y: 20 }` produces a parse error (keyword removed)
- [ ] The literal's type is inferred as an anonymous record type (unchanged semantics)

### Step 5 — Comptime: `registerRecord`/`registerEnum` accept `TypeDecl`

In `comptime/infer.zig`, update `registerRecord` and `registerEnum` to accept `TypeDecl` and
dispatch on `shape`. The type environment (`env.zig`) keeps `TypeDef.record` and `TypeDef.enum_`
unchanged — the runtime representation does not change, only the AST node that feeds it.

**Acceptance:**
- [ ] `registerTypeDecl` dispatches on `TypeDecl.shape` to the existing record/enum registration
- [ ] All comptime tests pass (snapshots re-recorded if the diagnostic text changed)
- [ ] `zig build test` green

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in this front's worktree
- [ ] `record` and `enum` are completely removed — using them produces a parse error
- [ ] `type` parses both record and enum shapes
- [ ] No runtime behavior change — only the AST node and diagnostic text differ
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Commit on `fix/type-keyword`; no push, no merge

## Blast radius

This is the largest syntactic change since the comptime rewrite. Every `.bp` file in every
library must be migrated (F8) — there is no deprecation path, the old keywords are removed
immediately. Every snapshot test that pins parser output, comptime diagnostics, or codegen
text will need re-recording (F2–F7). The migration is mechanical (`record` → `type`,
`enum` → `type`), but the volume is high: 83 declarations in std + libs, plus every test
fixture.

The hard cutover (no deprecation period) is chosen because the migration is fully mechanical
and the volume is manageable. A deprecation period would double the maintenance cost (two
keywords, two AST paths, two sets of diagnostics) for one milestone with no benefit.

## Notes

The proposal keeps the **runtime representation** unchanged: records are still maps (Erlang),
classes (JS), or memory slots (WASM); enums are still atoms + tagged tuples (Erlang), frozen
objects (JS), or tag + payload (WASM). Only the **surface syntax** and the **AST node** change.

The `implement` clause is unchanged. The `extends` clause (interfaces only) is unchanged. The
method syntax is unchanged. The constructor call syntax is unchanged. The pattern-matching
syntax is unchanged.

The only visible change is the keyword: `record` → `type`, `enum` → `type`.

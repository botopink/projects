# Deep dive — the `type` declaration

> Carried from `1.0.3-beta/02-surface-cutover/` into 1.0.4-beta. `file:line` and counts were measured at that milestone's
> commit — re-locate by symbol. `F1…F4` and bare front numbers are 1.0.3-beta's numbering: see
> [`../fronts.md`](../fronts.md#old-front-numbers).
> **Delivered** with front 12 (`botopink-lang` `ed575b5`). The acceptance lists below are the
> front's original checklist, kept as the specification of the grammar that shipped; the gate that
> passed is in [`README.md`](./README.md).

Part of [front 03](./README.md). Replaces `record` and `enum`.

## Today

Measured at `botopink-lang` `41981e3`:

- **Record** (`parser/decls.zig:755–813`): `[annotations] [pub] record Name<G> [implement B, …] { … }`.
  The body mixes fields `[annotations] [val] name: Type [= default],` and methods (`pub fn`, `fn`,
  `declare fn`) in any order. Defaults may sit on any field. Comments are skipped and lost
  (`skipComments`). `record Point(x: i32) {}` is a parse error; the comment on `RecordDecl`
  (`ast.zig:1838`) that says otherwise is stale.
- **Enum** (`parser/decls.zig:1013–1073`): `[pub] enum Name<G> [implement …] { … }`. Items are
  `Variant`, `Variant(f: T [= d], …)` and sections `Name { … }` (numeric leaves allowed). Methods may
  sit anywhere among the variants. A comment inside the body is a parse error; annotations on
  variants and on payload fields are parse errors.
- **Val-form**: `val Name = record<G> { … }` / `val Name = enum<G> { … }` (`parser.zig:444–453`).
- **Construction**: labeled `Point(x: 1, y: 2)` and positional `Point(1, 2)` both check today;
  variants `Shape.Circle(radius: 1)` / `Shape.Circle(1)`.
- **`type` is already a keyword** (`lexer.zig:729`): the kind of types in type position —
  `comptime T: type`, `-> type`, with an optional `|` constraint list (`parser/types.zig:162–177`,
  `parser.zig:1112`, `parser/decls.zig:57`). That meaning does not change.

## Grammar

```
typeDecl     := annotation* 'pub'? 'type' Name genericParams? fieldList? implementClause? typeBody?
valTypeDecl  := annotation* 'pub'? 'val' Name '=' 'type' genericParams? fieldList? implementClause? typeBody?

fieldList    := '(' field (',' field)* ','? ')'
field        := comment* annotation* Name ':' TypeRef ('=' Expr)?

typeBody     := '{' bodyItem* '}'
bodyItem     := comment
              | variant ','?            -- comma optional only before '}' or before a method
              | section
              | method
variant      := annotation* Name variantFields?
variantFields:= fieldList               -- the same production as the record field list
section      := Name '{' sectionItem (',' sectionItem)* ','? '}'
method       := annotation* 'pub'? ('fn' | 'declare' 'fn') signature (block | ';')
```

- `genericParams` go right after the name (shorthand) or right after `type` (val-form), as today.
- `implementClause` goes after the field list: `type Element(tag: string) implement @Context<E, E> { … }`.
- An empty field list `()` is rejected: a record with no fields omits the parentheses.
- The body is optional. `type Point(x: i32, y: i32)` is a complete declaration.

## Shape resolution

The parser decides the shape from what it has already consumed — no lookahead past the body:

| Field list | Body contains a variant or section | Shape | Registers as |
|---|---|---|---|
| present | no | record | `TypeDef.record` |
| present | yes | **error** `type-record-with-variants` | — |
| absent | yes | enum | `TypeDef.enum_` |
| absent | no (only methods, empty, or no body) | record with no fields | `TypeDef.record` |

Consequences, all measured against today's code:

- The 38 records with methods and no fields (10 in libraries, about 28 in Zig tests) stay records.
- Enums with methods (6 in Zig tests) stay enums.
- `enum E {}` (an enum with no variants) becomes a record with no fields. No library declares one.
- Inside the body, a variant and a method are told apart by the first token: a method starts with
  `pub`, `fn`, `declare` or an annotation followed by one of those; a variant starts with a `Name`.

## Separators

The rule for the whole milestone lives in [`separators.md`](./separators.md). For `type`:

- Fields in the field list: `,`; trailing comma allowed.
- Variants: `,`; trailing comma allowed.
- Sections end with `}` and take no comma. Items inside a section: `,`.
- Methods take no comma. A bodyless method (`declare fn`) ends with `;`.
- Variants come before methods. A variant after a method is `type-variant-after-method`: the comma
  rule stays unambiguous and the formatter never has to reorder. (Zig tests with enum methods: 6;
  libraries: 0.)

## What the field list keeps from records

| Feature | Today (record body) | Today (variant payload) | 1.0.3 field list |
|---|---|---|---|
| Default on any field | yes | yes | yes |
| Annotation on a field (`#[value("app.timezone")] timezone: string`) | yes | parse error | yes |
| Comment between fields | skipped, lost | parse error | kept on the field, printed by the formatter |
| Trailing comma | yes | yes | yes |
| `val` prefix | accepted | — | **removed** — `type-field-val-prefix` with a fix-it |

The field list is one production shared by `type Name(…)` and `Variant(…)`, so variant payloads gain
annotations and comments in the same change.

## Removed keywords

`record`, `enum` and `interface` leave the lexer and lex as identifiers. The parser recognises them
by lexeme where a declaration or a val-form body starts, and where `record {` starts an expression,
and raises a targeted error instead of a generic syntax error — the same pattern as the removed
`*fn` syntax (`parser.zig:90`, `parser/decls.zig:285–324`, message in `print.zig`):

| Source | Code | Message |
|---|---|---|
| `record Point { … }` | `removed-keyword-record` | `record` was replaced by `type Point(fields) { methods }` in 1.0.3 |
| `enum Color { … }` | `removed-keyword-enum` | `enum` was replaced by `type Color { variants }` in 1.0.3 |
| `interface Printable { … }` | `removed-keyword-interface` | `interface` was renamed to `behavior` in 1.0.3 |
| `record { x: 1 }` (expression) | `removed-record-literal` | anonymous records are labeled tuples in 1.0.3: `#(x: 1)` |
| `{ x: i32 }` (type position) | `removed-record-type` | anonymous record types are labeled tuples in 1.0.3: `#(x: i32)` |

Every diagnostic carries a location — the defect "parse errors carry no location" stays in
1.0.2-beta, but these five are pinned with a location in their snapshots.

## AST

```zig
pub const TypeDecl = struct {
    name: []const u8,
    id: u32 = 0,
    isPub: bool = false,
    annotations: []Annotation = &.{},
    genericParams: []GenericParam = &.{},
    implement: []TypeRef = &.{},
    shape: TypeShape,
    methods: []InterfaceMethod = &.{},   // records and enums already store methods this way (ast.zig:1454, 1860)
    trailingComma: bool = false,
};

pub const TypeShape = union(enum) {
    record: []Field,
    enum_: struct { variants: []EnumVariant, sections: []EnumSection },
};

/// One field — of a record field list or of a variant payload.
pub const Field = struct {
    name: []const u8,
    typeRef: TypeRef,
    default: ?Expr = null,
    annotations: []Annotation = &.{},
    comments: [][]const u8 = &.{},
};
```

- `DeclKind.record` and `DeclKind.@"enum"` are replaced by `DeclKind.type_`.
- `RecordField` and `EnumVariantField` merge into `Field`.
- Parser ids: `nextId("type")` → `type_NNNN` (was `record_NNNN` / `enum_NNNN`).
- `comptime/env.zig` keeps `TypeDef = { record, struct_, enum_ }` — registration dispatches on
  `TypeDecl.shape` to the existing `registerRecord` (`infer.zig:915`) and `registerEnum`
  (`infer.zig:1209`).
- User-facing text names the declaration `type`; it says *record type* / *enum type* only when the
  shape is the point of the message (e.g. `enum-variant-arity-mismatch`).

## Formatter

Rules 2 and 3 of [`separators.md`](./separators.md#the-rule):

- Field list: compact without a trailing comma, open with one; a `//` comment opens it.
- Variants and section items: same rule. A body with a method is always open (one variant per
  line, trailing comma added), because a `fn` definition is always open.
- A record with no body prints no braces.
- One blank line between the last variant (or the field list's closing `)`) and the first method.
- Round-trip: `format(parse(src))` re-parses to the same AST, and formatting twice is a no-op.

## Parser acceptance cases

- [ ] `type Point(x: i32, y: i32)` → record, no body
- [ ] `type Stack<T>(items: T[]) { pub fn size(self: Self) -> i32 { … } }` → record with methods
- [ ] `type Element(tag: string) implement @Context<Element, Element> { }` → record with implement
- [ ] `type Config(\n // c\n #[value("k")] host: string = "0.0.0.0",\n port: i32,\n)` → comment and annotation kept
- [ ] `type Order { Lt, Eq, Gt }` → enum
- [ ] `type Shape { Circle(radius: f64), Square(side: f64), pub fn area(self: Self) -> f64 { … } }` → enum with a method
- [ ] `type Token { Color { Red { 100, 500 }, Hex(value: string), } Hover(inner: Token[]), }` → enum with sections
- [ ] `type MathOps { pub fn add(a: i32, b: i32) -> i32 { … } }` → record with no fields
- [ ] `val Dict = type<K, V>(pairs: Array<#(K, V)>) { … }` → val-form record
- [ ] `type P(x: i32) { A }` → `type-record-with-variants`
- [ ] `type P()` → error, empty field list
- [ ] `type S { fn f(self: Self) {} A }` → `type-variant-after-method`
- [ ] `type P(val x: i32)` → `type-field-val-prefix`
- [ ] `record P { x: i32 }`, `enum E { A }`, `record { x: 1 }`, `fn f(p: { x: i32 })` → the removed-keyword diagnostics above, with location
- [ ] `comptime T: type` and `-> type` still parse as the kind of types

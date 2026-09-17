# Specs — 1.0.3-beta

The type-system surface shrinks. `record` and `enum` collapse into one `type` keyword, `interface`
becomes `behavior`, the anonymous record becomes a **labeled tuple** `#(x: 10, y: 20)`, and seven
keywords with no surface meaning leave the lexer. Separators get one rule: a comma separates data
items, never declarations. The language keeps its expressive power — named fields, variants with
payloads, sections, generics, `implement`, methods — with fewer keywords and one way to write each
thing.

**Entry criterion:** 1.0.2-beta is closed. This milestone rewrites the source of about 700
snapshots and touches every file the twelve 1.0.2-beta fronts own; running both at once guarantees
merge conflicts, and the library gate (`zig build test-libs`) cannot go green while `libs/std` and
four libraries do not compile.

## Decisions

| Topic | Decision |
|---|---|
| Records | `type Name<G>(fields) implement B { methods }` — fields in parentheses, the declaration mirrors construction `Name(x: 1)`. One form only; no `constructor` keyword. Body optional. |
| Enums | `type Name<G> { Variant, Variant(f: T), Section { … }, methods }` — a body with at least one variant or section. |
| Record with no fields | `type Name { methods }` — a body with no variant. |
| Field list | Shared by record declarations and variant payloads: annotations, comments, defaults, trailing comma. No `val` prefix — values are immutable. |
| Anonymous record | Labeled tuple `#(x: 10, y: 20)`, type `#(x: i32, y: i32)`. Labels live in the type only; the runtime value **is** a tuple. Replaces `record { … }` literals and the `{ x: T }` type. |
| Interfaces | `behavior Name { … }`. Same semantics. |
| Separators | `,` separates data items (fields, variants, tuple elements, arguments); no trailing comma → compact on one line, trailing comma → one item per line; a `fn` definition is always open. Members are not comma-separated: a bodyless `fn` or a `val` field ends with `;`, a member that ends with `}` takes nothing. |
| Dead keywords | `auto`, `derive`, `get`, `macro`, `opaque`, `private`, `set` become identifiers. |
| Migration | Hard cutover, no deprecation window. Migration is manual (beta phase). Removed keywords get a targeted diagnostic. |
| Runtime | Unchanged for named records, enums and behaviors. Anonymous records change from map/object to tuple. |

## Fronts

| Front | Priority | What |
|---|---|---|
| [`01-dead-keywords/`](./01-dead-keywords/README.md) | medium | Drop seven keywords; `get`/`set` accessors become methods. Small, ready, runs first. |
| [`02-surface-cutover/`](./02-surface-cutover/README.md) | critical | `type`, `behavior`, labeled tuples and separators in the parser, the AST, every Zig consumer, `libs/std`, the embedded prelude, every Zig test source and every snapshot — landed through green commits with a transitional dual grammar that never ships. |
| [`03-ecosystem-migration/`](./03-ecosystem-migration/README.md) | high | emilia, erika, jhonstart, onze, rakun migrated manually; `test-libs` cells green; submodule sweep. |
| [`04-tooling-and-docs/`](./04-tooling-and-docs/README.md) | high | Language-server texts and completions, VS Code grammar and snippets, user docs. |

## Order

```
F1 dead-keywords ──► F2 surface-cutover ──┬──► F3 ecosystem-migration
                                          └──► F4 tooling-and-docs
```

F1 runs first (small, ready). F2 waits for F1: it edits the same lexer, parser and language-server
files. F3 and F4 are file-disjoint and run in parallel once F2 lands — the libraries need the new
compiler, the editor texts need the final grammar.

F2 is the critical path. It cannot be cut by backend: `DeclKind` is a tagged union, and removing
a variant stops every consumer from compiling, so the AST change and all its Zig consumers move
together (see [`02-surface-cutover/README.md`](./02-surface-cutover/README.md#why-one-front)).

## Found during the review — belongs to 1.0.2-beta

Measured while validating the examples against the compiler at `botopink-lang` `41981e3`. None of
these is caused or fixed by this milestone.

| # | Where | Defect |
|---|---|---|
| 1 | commonJS | A record method named `print` lowers `d.print()` to `console.log(console.log())`. |
| 2 | commonJS | A behavior `default fn` calling another member (`self.max(lo).min(hi)`) fails at runtime: `self.max is not a function`. |
| 3 | commonJS | An enum method is not attached to variant values: `Shape.Square(4).area is not a function` (Erlang prints `16`). |
| 4 | commonJS | `pair.0` is emitted verbatim (invalid JS); `?T.map` lowers to `Array.prototype.map`. |
| 5 | checker | A record field typed by a behavior rejects an implementing record: `expected Handler, got H`. |
| 6 | checker | A default on a non-last record field is not applied: `record P { x: i32 = 0, y: i32 }` then `P(y: 2)` → `'P' expects 2 argument(s)`. |
| 7 | checker | `botopink check` does not report unknown type names (`NoSuchType`, `Dict` without import) nor `return "x"` in a function returning `i32`. |
| 8 | CLI | Parse errors carry no location: `parse error in main`. |
| 9 | docs | `docs.md` shows `implement A for B { … }` without `val`, which does not parse. |

## Rules carried from 1.0.2-beta

- **A backend builds a model, an emitter renders it.** The unified `TypeDecl` and the labeled
  tuple feed the existing per-backend models.
- **The gate is a cold runtime cache.** Every front's gate runs `zig build test` from a cold cache.
- **A snapshot is evidence, not a baseline.** A re-recorded snapshot is accepted only when its
  `RUN LOG` is unchanged or the change is explained; manual classification separates
  source-only diffs from output diffs so the second group is reviewed, not bulk-accepted.
- **Every commit is green.** The pre-commit hook runs `zig build` and `zig build test`; no
  `--no-verify`. F2 is sequenced into commits that each pass it.

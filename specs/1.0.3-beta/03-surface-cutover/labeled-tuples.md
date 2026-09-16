# Deep dive — labeled tuples replace anonymous records

Part of [front 03](./README.md). Replaces the `record { … }` literal and the `{ x: T }` type.

## Today

Measured at `botopink-lang` `41981e3`:

| | Tuple | Anonymous record |
|---|---|---|
| Literal | `#(1, "a")` (`parser/exprs.zig:1159`) | `record { x: 1, y: "a" }` (`parser/exprs.zig:1121`) |
| Type | `#(i32, string)` (`parser/types.zig:46–60`) | `{ x: i32, y: string }` (`parser/types.zig:104–121`) |
| Access | `t._0` | `r.x` |
| JS | `[1, "a"]` | `({ x: 1, y: "a" })` |
| Erlang | `{1, <<"a">>}` | map (`erlang.zig:3169`, `fieldMap`) |
| Typing | positional | exact: a missing, extra or reordered field is a mismatch; a nominal record is not assignable (`expected record, got User`) |

Because the checker already treats anonymous record types as exact and ordered, and never lets a
nominal record flow into one, moving them onto the tuple runtime does not change which programs
type-check.

Uses outside Zig tests (all of them `.bp` code compiled by botopink — no host JavaScript reads the
fields by name):

- `jhonstart/src/hooks.bp:37,49,57` — `@Context` capabilities (`{}`, `current`, `state`/`dispatch`).
- `jhonstart/src/html.bp:91–148` — lexer tokens (7 literals, 7 fields each).
- `erika/src/erika.bp:375,417,466,503,839` — SQL tokens and rows; `erika.bp:570` **generates** the
  text `record { … }` inside a string.
- `examples/yamlconf/yamlconf.bp:12–13` — `@expr(record { … })`.
- `libs/std/src/types.bp` (`partial`, `omit`, `pick`, `mergeRecords`) and `reflect.bp` — produce
  anonymous record types; doc comments show `record { … }`.

## Syntax

```bp
val p = #(x: 10, y: 20);              // labeled tuple
val t = #(10, 20);                    // plain tuple, unchanged
val unit = #();                       // empty tuple — replaces `record { }`

fn origin() -> #(x: i32, y: i32) {    // labeled tuple type — replaces `{ x: i32, y: i32 }`
    return #(x: 0, y: 0);
}

pub fn effect(run: fn(), deps: any[]) -> @Context<Element, #()> { … }
```

- Either every element has a label or none does. `#(x: 1, 2)` is `tuple-mixed-labels`.
- Labels are unique within a tuple: `#(x: 1, x: 2)` is `tuple-duplicate-label`.
- In type position, `#(` followed by `Name :` is a labeled tuple type; otherwise a plain tuple type.
- Layout follows the comma rule: `#(x: 1, y: 2)` compact, `#(x: 1, y: 2,)` open.

## Typing

- **Labels and order are part of the type.** `#(x: i32, y: i32)` and `#(y: i32, x: i32)` are
  different types; so are `#(x: i32)` and `#(a: i32)`.
- **Labeled → plain is allowed** (labels are forgotten): a `#(x: i32, y: i32)` value is accepted
  where `#(i32, i32)` is expected. **Plain → labeled is not**, except a tuple literal checked
  against a labeled expected type, which takes the labels (`val p: #(x: i32) = #(1)`).
- **Nominal records never convert.** `Point(x: 1, y: 2)` is not a `#(x: i32, y: i32)` — same as
  today.
- **Access:** `p.x` resolves statically to the element index. `p._0` stays valid on a labeled tuple.
  Accessing a label on a value whose type is not a known labeled tuple (a generic `T` without a
  bound, `any`) is a type error `tuple-label-unknown-type` — there is no field name at runtime to
  look up.
- **Patterns:** tuple patterns stay positional.
- **Generics:** a labeled tuple through `T` keeps its labels in the instantiated type
  (`same(#(name: "a")).name` checks — measured today with `record { … }` through a generic).

## Runtime

A labeled tuple is the plain tuple of the same arity on every backend; the label is erased after
type checking.

| Backend | `#(x: 10, y: 20)` | `p.y` |
|---|---|---|
| commonJS | `[10, 20]` | `p[1]` |
| Erlang | `{10, 20}` | `element(2, P)` |
| BEAM | tuple, `put_tuple2` | `get_tuple_element` index 1 |
| wasm | the tuple layout | the tuple element offset |

Accepted costs:

- `@print(p)` and `toString` show the tuple (`[10, 20]`), not the labels.
- Codegen text of every snapshot that builds an anonymous record changes (map/object → tuple).
  The `RUN LOG` of those snapshots must not change unless it prints a whole anonymous record.

## Comptime

- `partial`, `omit`, `pick` (`libs/std/src/types.bp`) produce labeled tuple types whose labels
  follow the **source record's field order**; `mergeRecords(A, B)` produces A's fields in order,
  then B's fields that A does not have, in B's order. The diagnostic texts about these operations
  (`comptime/infer.zig`) say *labeled tuple*.
- `@expr(#(port: 8000))` lifts a labeled tuple; `@Expr<#(port: i32)>` types it.
- The comptime evaluator (templates and decorators executed on a runtime) builds tuples; token
  records in `html.bp` and `erika.bp` become labeled tuples and are only read by label inside
  `.bp` code, so no evaluator-host contract changes.

## AST

- `CollectionExpr.kind.recordLit` is removed; `tupleLit` gains `labels: ?[][]const u8`.
- `TypeRef.record_type` / `RecordTypeField` are removed; `TypeRef.tuple_` gains labels.
- The typed JSON dump used by parser/comptime snapshots renames accordingly.

## Acceptance

- [ ] `#(x: 1, y: 2)` parses, types as `#(x: i32, y: i32)`, and `p.y` reads the second element on commonJS, Erlang, BEAM and wasm (one snapshot per backend, `RUN LOG` pinned)
- [ ] `#()` is the empty tuple and replaces `record { }` / `{}`
- [ ] `#(x: 1, 2)` → `tuple-mixed-labels`; `#(x: 1, x: 2)` → `tuple-duplicate-label`
- [ ] Reordered labels mismatch; labeled → plain accepted; plain → labeled rejected except for a literal
- [ ] `fn f<T>(v: T) -> i32 { return v.x; }` → `tuple-label-unknown-type`
- [ ] `partial`/`omit`/`pick`/`mergeRecords` produce labeled tuple types in the documented order
- [ ] `@expr(#(port: 8000))` with `@Expr<#(port: i32)>` runs (yamlconf shape)

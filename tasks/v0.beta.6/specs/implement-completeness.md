# implement-completeness — `implement` parses & codegens in every form

**Slug**: implement-completeness
**Depends on**: nothing
**Files**: `modules/compiler-core/src/parser/decls.zig`, `modules/compiler-core/src/parser/types.zig`, `modules/compiler-core/src/codegen/commonJS.zig`, `modules/compiler-core/src/codegen/erlang.zig`
**Touches docs**: `docs.md` (§Implement), `modules/compiler-core/src/codegen/AGENTS.md`
**Status**: done — G5–G7 merged into `feat` (be13669 / ece318b)

> **Why.** Surfaced attaching `@Context` to jhonstart's `Element` (gaps G5–G7).
> A `record` carrying an inline `implement @Context<…>` clause works end-to-end,
> but the two `struct`/standalone forms the language also documents are broken:
> one fails to parse, the other type-checks but produces wrong code. These are
> bugs in existing surface, not new features.

## Target syntax

```bp
// (A) inline struct-implement with an array-typed field
val E = struct implement @Context<E, E> { tag: string, children: E[] }

// (B) standalone implement of a GENERIC interface
record E { tag: string }
val C = implement @Context<E, E> for E { }

// (C) inline struct-implement constructs correctly at runtime
val v = E(tag: "x", n: 5);   // v.n == 5  (today: undefined)
```

## Examples

### G5 — array field inside an inline `struct implement { }` body — does not parse
```bp
val E = struct implement @Context<E, E> { children: E[] }   // parse error
```
A plain `record E { children: E[] }` parses; the same array field inside a
`struct implement … { }` body does not. (A named-record field parses, which is
the current workaround.)

### G6 — standalone `implement <generic-iface> for <T>` — does not parse
```bp
val C = implement @Context<E, E> for E { }     // parse error
val C = implement Foo<A, B> for E { }          // parse error
val C = implement Printable for Person { … }   // OK (non-generic)
```
The docs' `implement Iface for Type { }` form parses only a *non-generic*
interface; any generic interface (incl. `@Context<…>`) fails.

### G7 — inline `struct implement { fields }` drops fields at codegen — **bug**
```bp
val E = struct implement @Context<E, E> { tag: string, n: i32 }
fn mk() -> E { return E(tag: "x", n: 5); }
// mk().n reads `undefined` at runtime
```
The JS emitter produces a constructor-less class:
```js
class E { tag; n; }
function mk() { return new E("x", 5); }   // args ignored → fields undefined
```
A `record` emits a real constructor and works; the inline `struct implement`
form must do the same. (This was latent: context-inference tests only ever
*type-check* this form via `assertInfersOk`, never run it.)

## Steps

### F0 — parser
- [ ] G5: allow array-typed (and other suffixed) fields inside an inline
      `struct implement … { … }` body — reuse the record-field type parser
- [ ] G6: allow a generic interface (`Iface<A, B>`, incl. `@Context<…>`) in the
      standalone `implement <Iface> for <Type> { }` form

### F1 — codegen (the real bug)
- [ ] G7: an inline `struct implement … { fields }` value must emit a constructor
      that assigns its fields (positional + labeled), matching `record` codegen,
      on every backend; `new E("x", 5)` must populate `tag`/`n`

### F2 — regression coverage
- [ ] A `codegen/node` test that *runs* a `struct implement` value and asserts a
      field round-trips (the gap existed because only inference was tested)

## Test scenarios

```
parser  ---- struct_implement_array_field     (G5)
parser  ---- implement_generic_interface_for   (G6)
codegen/node ---- struct_implement_fields_run  (G7 — mk().n == 5 at runtime)
codegen/erlang ---- struct_implement_fields_run (parity)
```

## Notes

- jhonstart dodges all three by declaring `Element` as
  `record Element implement @Context<Element, Element> { … }` (a `record` with an
  inline `implement` clause — parses, and a record emits a real constructor). So
  this spec is not a jhonstart blocker, but the broken forms are real and should
  either be fixed or explicitly removed from the language surface/docs.
- G7 is a correctness bug; prioritize it over G5/G6 (which have the record
  workaround).

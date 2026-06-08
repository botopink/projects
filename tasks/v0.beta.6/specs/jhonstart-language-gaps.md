# jhonstart-language-gaps — record/array ergonomics blocking the UI framework

**Slug**: jhonstart-language-gaps
**Depends on**: nothing (pure language features)
**Files**: `modules/compiler-core/src/parser*.zig`, `modules/compiler-core/src/comptime/*` (type inference + coercions), `modules/compiler-core/src/codegen/*`
**Touches docs**: `modules/compiler-core/src/comptime/AGENTS.md`, `modules/compiler-core/src/codegen/AGENTS.md`, `libs/jhonstart/*`
**Status**: pending

## Intent

Building `libs/jhonstart` (the React/Next-style UI framework, v0.beta.5) the
framework was held to **"no workarounds"** and surfaced four *language* gaps —
features botopink can't yet express that block the idiomatic hook + `html` APIs.
They are language-level (not jhonstart-specific) and are grouped here because
they form one coherent cluster: making records and arrays ergonomic enough for a
component/hook API. Verified empirically on `task/jhonstart`.

## The gaps

### G1 — records cannot carry function-typed fields
A hook returns the shape `{ value, set }` where `set` is a function. A record
field typed as a function (`set: fn(next: T)`) is currently inexpressible, so the
builder-API hook shape can't be named.
```bp
record State<T> { value: T, set: fn(next: T) }   // G1: fn-typed field
```

### G2 — no anonymous record TYPE syntax
Only record *value* literals exist; there is no anonymous record *type* (e.g. a
return type `-> { value: T, set: fn(T) }`), forcing a named record for every
transient shape.

### G3 — `fn() -> T[]` does not parse
An array as a function-type *return* (`fn() -> Element[]`) fails to parse —
blocks hook/builder signatures returning lists.

### G4 — no `Element[]` → `Children` coercion
`div { [a, b] }` needs an `Element[]` (or `string`) to coerce into the
`Children` parameter; without the coercion the builder API can't take a list of
children.

## Steps

### F0 — G1 fn-typed record fields
- [ ] Parse + infer a record field whose type is a function type; codegen stores
      it like any field (a closure value).

### F1 — G2 anonymous record types
- [ ] Anonymous record *type* syntax usable as an annotation / return type.

### F2 — G3 array-as-return parsing
- [ ] `fn(...) -> T[]` (and nested `?T[]`, `T[][]`) parse + infer.

### F3 — G4 Children coercion
- [ ] `Element` → `[Element]` and `string` → text-node coercions into a
      `Children`-typed parameter (the rule jhonstart's `div { … }` needs).

## Test scenarios

```
parser ---- a record with a fn-typed field parses (G1)
parser ---- fn() -> T[] parses (G3)
infer  ---- {value, set} hook shape type-checks via fn-typed field (G1)
infer  ---- an anonymous record type is accepted as a return annotation (G2)
infer  ---- div { [a, b] } coerces Element[] into Children (G4)
```

## Notes

- These are the four blockers recorded in `task/jhonstart`'s TODO + the v0.beta.5
  jhonstart spec Notes; this spec promotes them to first-class language work.
- Each gap is independently shippable — split into separate `task/<slug>`
  branches if parallelism helps; kept as one spec because they share the goal
  (unblock the jhonstart builder + `html` APIs) and the same files.
- jhonstart F4–F5 (SSR / server loaders) remain gated on the async specs
  (`use-await-prefix`, `async-generators`) from `tasks/v0.beta.1/`, not here.

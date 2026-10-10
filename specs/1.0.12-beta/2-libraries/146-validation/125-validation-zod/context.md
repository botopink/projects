# Front 125 — validation zod: Zod's feature set in botopink

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [146-validation](../README.md): open → 146 s1 · gate → 146 s1. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** high for the step 0–2 residue (`08-bpp/121` content collections and `08-bpp/127`
actions take the `#[validated]` type — decision 306); medium for the rest · **State:** partial: steps 0–3 done;
steps 4–12 landed in 306's shape but for the boxes that wait on `01-checker` steps 24 / 28, 134 step 4,
`@typeInfo(T).fields` and the `Decl.variants` gap (step 9's meta-schema check, decision 399, is built: Ajv vendored under `test/tools/`)
**Depends on:** `01-compiler/01-checker` step 24 (decision 280, step 7) · decision 325 (07-j: every step, 306's shape). Written against decisions 144 (undeclared keys), 145 (emitted names),
183 (`07-m`: coercion, step 6), 257 (`07-n`: `Schema<T>` lives in `validation` — amended by 306: the
place stays, the value is private), 306–308
**Owns:** `repository/validation/src/**` · `repository/validation/test/**` · `repository/validation/AGENTS.md` ·
`repository/validation/botopink.json` — except `src/messages.bp`'s `interpolate`, moved to `i18n` by
`105-i18n` between two steps of this front, never during one (decision 189)
**Does not touch:** the compiler (`modules/**`) — a need is a row in
[`language-gaps.md`](../../../language-gaps.md) and a nearest form · `libs/std/**` (97) · other shared
packages · consumer files in rakun, jhonstart, onze (a consumer imports a marker in its own front)

Feature map — all 211 reference rows with their box: [`surface.md`](surface.md). Target code per
step: [`examples/`](examples/).

## Goal

Zod's core is `parse`: untrusted data in, typed value or located issues out. `#[validated]`'s
`v.validate()` checks an **already typed** value, so every JSON / form / config boundary builds the
record by hand (`language-gaps.md`: "No `record ↔ Json` derivation"; 39 functions named `…Json(`
outside tests, 33 in rakun). Not a regex demand — `regex.matches(` outside `libs/std` and
`repository/validation`: 0; `#[pattern(…)]` outside the library: 1, in a test; `registerConstraint(`
outside: 0; private format walks: 3 `isHex` (`jhonstart-emilia/src/root.bp` — leaves with the member, `08-bpp/119`, decision 338 —,
`rakun-web/src/static.bp`, `rakun-actuator-api/src/span.bp`). The need is `Json` → record; the rest
follows: the `#[validated]` type derives parse / decode / bind / encode / JSON Schema as members
(306 — `#[schema]` folds into it; field markers compose, no public `Schema<T>`), checks grow from 13
markers to 71, reports gain views and locales.

With steps 4–12 applied, `repository/validation`: 8 067 source lines in thirteen modules — `root`, `path`,
`report`, `messages`, `locales`, `formats`, `derived` (the machinery the members call), `table`,
`spi`, `constraints`, `binding`, `codecs`, `decorators` (`#[validated]`, 73 constraint markers and
the field and type markers of steps 4–12) — 246 tests in twenty-seven files, green on erlang and
commonJS. Consumers: rakun's `rakun/src/{config,config_check}.bp` (its `Duration` / `DataSize` are `#[validated]`) and `onze-content`'s collections (a type's `parse`).

Already provided: JSON tree `json.Json { Null, Bool, Num, Str, Arr, Obj }`,
`json.decode(s) -> @Result<Json, string>` (document order, duplicates refused), `Json` methods `members` / `field` /
`items` (97) · fallible return `@Result<T, E>`, `try`, `try … catch`, `case` (`docs.md`) · `A | B`,
`unknown`, `x is T` · `#(A, B)`, `type Shape { Circle(radius: f64) }`, `?T` · `Dict<K, V>`, `Set<T>`
(`libs/std/src/collections.bp`) · field defaults `type Port(number: i32 = 80, host: string)` ·
derived records `partial(T)`, `pick`, `omit`, `mergeRecords` (`comptime/infer.zig`; `Type.partial` /
`Type.pick` / `Type.omit` / `Type.merge` / `Type.required` with 307) · type-writing
decorator `@emit("pub type …")` (`rakun-data/src/orm/entity.bp`) · text helpers `regex.compile` /
`captures`, `unicode.normalize` / `codepoints`, `url.parse`, `encoding.base64Decode` / `hexDecode`,
`clock.parseIso8601` / `toCivil`, `string.parseFloat` (97).

## Mechanism

Zod's one object model (type via `z.infer`, and parser) is split in two here.

**The type is the schema.** A `#[validated]` record or enum is reflected (`decl.fields`, each
field's `typeName` and `annotations`; `decl.variants`) and the decorator gives the type its members
(decision 216) — the checks `validate()` / `constraints()` and the parse half (306, 327):

| Member | Zod's |
|---|---|
| `T.parse(input: Json) -> @Result<T, ValidationReport>` | `.parse` / `.safeParse` |
| `T.parseAt(input: Json, at: string) -> @Result<T, ValidationReport>` | the same, for a value at path `at` of a larger document — what a nested field calls |
| `T.decode(text: string) -> @Result<T, ValidationReport>` | `.parse(JSON.parse(text))`, a syntax error as one violation coded `invalidJson` |
| `T.bind(pairs: Array<#(string, string)>) -> @Result<T, ValidationReport>` | `z.coerce.*` over a form or a query |
| `T.encode(v: T) -> @Result<Json, ValidationReport>` | `.encode` |
| `T.jsonSchema() -> string` | `z.toJSONSchema` |
| `T.options() -> Array<string>` (an enum) | `.options` / `.values` |

- Decoder: straight-line, one statement per field; every field decoded, every violation collected,
  record built only when the list is empty — "all violations, not fail-fast" is the shape, not an
  option (`binding.bp`'s header).
- A field of another `#[validated]` type → its `T.parseAt` (and `T.__json`, `T.__schemaNode`):
  members travel with the type, so no second declaration is seen.
- Checks not duplicated: `T.parseAt` calls `validate()` on the built record, `T.encode` before it
  writes.

**Decision 306: the type is the only schema, and `#[schema]` becomes `#[validated]`.** One decorator
checks (`validate()`, `constraints()`) and parses (the table above, as members — `Player.parse(doc)`, 327);
`#[schema]` goes. `Schema<T>`, `Codec<A, B>`, `schemas.*` and `checks.*` are no longer public:
`schemas.bp` is the private machinery the emitted decoders call. What only a value could say is a
field marker:

```bp
#[validated]
pub type Invite(
    #[minLength(1)] title: string,
    #[each(email, lowercased)] guests: Array<string>,            // was emails() + #[with("emails")]
    #[codec(decode: isoToMillis, encode: formatIso)] startsAt: i64,  // was schemas.codec(…)
    #[preprocess(digitsToNumber)] seats: i32,                    // was schemas.preprocess(…)
    #[refine(isEven)] tables: i32,                               // was schemas.int().refine(…)
)

#[validated(transparent)]                                        // encoded as its one field: "a@b.c"
pub type Email(#[email] value: string)

pub type Pet = Cat | Dog | Fish;                                 // was schemas.union3(…)
```

- A loose value: declare a type, or call the `constraints.v*` predicates.
- Another library takes the **type**: `comptime source: type T`, refused unless
  `@typeInfo(T).meta(Validated)` (298) — `collection(BlogPost)` (121), `paginate(…, Astronaut)` (117),
  an action's input and output from its signature (127).
- A `surface.md` row no declaration says naturally (`pipe`, `xor`, `both`, `lazy`, `custom`, …): a
  marker where one reads well on a field, else `n/a (306)` with its reason.

**Platform facts fixing the shape** (measured on erlang and commonJS; each a line of
`repository/validation/AGENTS.md` § Language notes and, where testable, a case of `test/platform_test.bp`;
compiler rows in `language-gaps.md`):

- **A result is built by a function.** `Ok(v)` / `Error(e)` are patterns, not constructors; a
  `throw` in a `case` arm does not become the function's `Error`. Every decoder is a named function
  that tests first and throws from a top-level `if`.
- **Library named through a namespace; types are leaves** (decision 145): no type through a
  namespace, so import `{schemas, schemas.Schema, report.ValidationReport, report.Violation}`.
- **A library function is called, not passed:** a namespace member resolves at the call;
  `schemas.of(schemas.decodeString)` is an unbound name. Per wrapper level under a field
  (`Array<Array<i32>>`, `?Array<string>`) the decorator emits one named function and passes that.
- **Text constructor is `schemas.text()`:** a function named `string` shadows the primitive type in
  every annotation of its module.
- **Generic value → optional through a list** — `[v].at(0)` — since
  `fn some<T>(v: T) -> ?T { return v; }` is "recursive type detected".
- **Length in code points** — `unicode.codepoints(s).length`; `"😀".length()` is 2 on commonJS, 1 on
  erlang, so no length marker uses `length()`.
- **`f32` is a double on both targets** (`1.5f`; `0.1f` reads back `0.1`): `#[float32]` is a range
  check on an `f64`. No std `f64` → integer conversion: an `i32` / `i64` field comes from three host
  cells in `schemas.bp`.
- **`url.parse` answers every input** (no case folding, default port kept, `[::1]` split at its
  first colon, `not a url` / `http://` / `http://a b.com/` answered): `#[url]` splits the authority
  and checks scheme, host and port itself.

## Decisions

### 07-j → decision 325

Every step, in 306's shape; `surface.md` re-sorted into marker, declared type or `n/a (306)`.

### ctr-u → decision 327

`#[validated]`'s members without the type's name: `Player.parse(doc)`, `parseAt`, `decode`, `bind`,
`encode`, `jsonSchema`; step 12 and `surface.md`'s rows use them.

## Notes

- **Not in the compiler:** `repository/validation` is a repository of its own (decision 326); a
  consumer declares it in `dependencies`, and a step's size is the package's, not the binary's.
- **Members beyond 327's list** (library decisions, reported): an enum's `options()`; `__json`,
  `__schemaNode`, `__schemaDefs` — the contract one type's members call on another's, `__`-named;
  the machinery module is `derived` (306 makes `schemas` private, and a consumer must still import
  what the emitted members name); the per-parse source is `messages.underSource(source, run)`, not a
  member, so a type's signature names no `MessageSource`.
- **`#[validated]`'s contract stays:** rakun's config binder calls `validate()` / `constraints()` by
  name (decision 216); every existing marker keeps code, message, table row.
- **`Violation.field` is a path only for nested data**; flat record → the field's name, as before.
- **Consumers unchanged here:** the three `isHex` walks, hand-written `…Json(` functions, route
  handlers reading query fields — candidates in each member's owning front.
- **Snapshots:** none in `repository/validation/test/`, none added — JSON Schema asserted as literals.
- **Not added:** `z.function`, `z.promise`, `z.symbol`, `z.undefined`, `z.nan`, typed registries,
  `fromJSONSchema`, JIT switches — each `n/a` with reason in `surface.md`. None is "later".
- **Async:** derived schemas are synchronous. `schemas.refineAsync` (private after 306; step 12
  sorts its row) answers a `Schema` whose `parse`
  is `-> @Task<@Result<…>>`; on erlang `@Task` is eager (`language-gaps.md` lg2-b) — "may call a
  `@Task` function", not "concurrent".
- **Cross-backend regex:** intersection of PCRE (`re:run/2`) and ECMAScript, grammar at
  `constraints.bp:212-219`: no backslash class, no lookaround. Formats not sayable in it — `emoji`,
  `ipv6`, `iban`, `creditCard`, the ISO family — are walks; `parity_test.bp` holds the claim.
- **Decision 67:** a marker on an uncheckable field type is a located compile error; step 3's
  `refusal_test.bp` has one row per marker and fails when the counts differ.


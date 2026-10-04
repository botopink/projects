# Front 125 — validation zod: Zod's feature set in botopink

**Priority:** high for the step 0–2 residue (`08-bpp/121` content collections and `08-bpp/127`
actions take the `#[validated]` type — decision 306); medium for the rest · **State:** partial: steps 0–2 on
feat with residue; steps 3–12 open
**Depends on:** `01-compiler/01-checker` step 24 (decision 280, step 7) · `07-j` (size). Written against decisions 144 (undeclared keys), 145 (emitted names),
183 (`07-m`: coercion, step 6), 257 (`07-n`: `Schema<T>` lives in `validation`)
**Owns:** `libs/validation/src/**` · `libs/validation/test/**` · `libs/validation/AGENTS.md` ·
`libs/validation/botopink.json` — except `src/messages.bp`'s `interpolate`, moved to `i18n` by
`105-i18n` between two steps of this front, never during one (decision 189)
**Does not touch:** the compiler (`modules/**`) — a need is a row in
[`language-gaps.md`](../../language-gaps.md) and a nearest form · `libs/std/**` (97) · other bundled
packages · consumer files in rakun, jhonstart, onze (a consumer imports a marker in its own front)

Feature map — all 211 reference rows with their box: [`surface.md`](./surface.md). Target code per
step: [`examples/`](./examples/).

## Goal

Zod's core is `parse`: untrusted data in, typed value or located issues out. `#[validated]`'s
`v.validate()` checks an **already typed** value, so every JSON / form / config boundary builds the
record by hand (`language-gaps.md`: "No `record ↔ Json` derivation"; 39 functions named `…Json(`
outside tests, 33 in rakun). Not a regex demand — `regex.matches(` outside `libs/std` and
`libs/validation`: 0; `#[pattern(…)]` outside the library: 1, in a test; `registerConstraint(`
outside: 0; private format walks: 3 `isHex` (`jhonstart-emilia/src/root.bp`,
`rakun-web/src/static.bp`, `rakun-actuator-api/src/span.bp`). The need is `Json` → record; the rest
follows: `#[schema]` derives parse / decode / bind / encode / JSON Schema, `Schema<T>` composes,
checks grow from 13 markers to 71, reports gain views and locales.

On feat `libs/validation`: 2 134 source lines — `report.bp`, `constraints.bp` (20 `v*` predicates),
`decorators.bp` (`#[validated]`, 13 markers, `#[schema]`), `messages.bp`, `spi.bp`, `binding.bp`,
`table.bp`, `path.bp`, `schemas.bp` — 98 tests in eleven files, green on erlang and commonJS.
Consumers: rakun's `rakun/src/{config,config_check}.bp`; jhonstart and onze import nothing.

Already provided: JSON tree `json.Json { Null, Bool, Num, Str, Arr, Obj }`,
`json.decode(s) -> @Result<Json, string>` (document order, duplicates refused), `Json` methods `members` / `field` /
`items` (97) · fallible return `@Result<T, E>`, `try`, `try … catch`, `case` (`docs.md`) · `A | B`,
`unknown`, `x is T` · `#(A, B)`, `type Shape { Circle(radius: f64) }`, `?T` · `Dict<K, V>`, `Set<T>`
(`libs/std/src/collections.bp`) · field defaults `type Port(number: i32 = 80, host: string)` ·
derived records `partial(T)`, `pick`, `omit`, `mergeRecords` (`comptime/infer.zig`) · type-writing
decorator `@emit("pub type …")` (`rakun-data/src/orm/entity.bp`) · text helpers `regex.compile` /
`captures`, `unicode.normalize` / `codepoints`, `url.parse`, `encoding.base64Decode` / `hexDecode`,
`clock.parseIso8601` / `toCivil`, `string.parseFloat` (97).

## Mechanism

Zod's one object model (type via `z.infer`, and parser) is split in two here.

**The type is the schema.** A `#[schema]` record or enum is reflected as `#[validated]` reflects it
(`decl.fields`, each field's `typeName` and `annotations` — `decorators.bp`'s `validated`); the
decorator `@emit`s functions named after the type. Decision 216 retires loose `@emit`
(`#[validated]` adds members `validate()` / `constraints()`); `#[schema]`'s free functions still use
it; whether they become members (`Player.parse(input)`) is open (`ctr-u`):

| Emitted | Zod's |
|---|---|
| `pub fn schemaOf<T>() -> Schema<T>` | the schema value |
| `pub fn parse<T>(input: Json) -> @Result<T, ValidationReport>` | `.parse` / `.safeParse` |
| `pub fn parse<T>At(input: Json, at: string) -> @Result<T, ValidationReport>` | the same, for a value at path `at` of a larger document — what a nested field calls |
| `pub fn decode<T>(text: string) -> @Result<T, ValidationReport>` | `.parse(JSON.parse(text))`, a syntax error as one violation coded `invalidJson` |
| `pub fn bind<T>(pairs: Array<#(string, string)>) -> @Result<T, ValidationReport>` | `z.coerce.*` over a form or a query |
| `pub fn encode<T>(v: T) -> @Result<Json, ValidationReport>` | `.encode` |
| `pub fn jsonSchemaOf<T>() -> string` | `z.toJSONSchema` |

- Decoder: straight-line, one statement per field; every field decoded, every violation collected,
  record built only when the list is empty — "all violations, not fail-fast" is the shape, not an
  option (`binding.bp`'s header).
- A field of another `#[schema]` type → call `parse<ThatType>At` by name (no second declaration seen).
- Checks not duplicated: a type with markers is also `#[validated]`; `parse<T>` calls `validate()`
  on the built record. A marker on a `#[schema]` type not `#[validated]` is a compile error
  (decision 67).

**Decision 306: the type is the only schema, and `#[schema]` becomes `#[validated]`.** One decorator
checks (`validate()`, `constraints()`) and parses (the table above, as members — spelling `ctr-u`'s);
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
    #[check(isEven)] tables: i32,                                // was schemas.int().refine(…)
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
`libs/validation/AGENTS.md` § Language notes and, where testable, a case of `test/platform_test.bp`;
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
- **`f32` has no literal** (`val f: f32 = 1.5;` mismatches), no std `f64` → integer conversion: an
  `i32` / `i64` field comes from three host cells in `schemas.bp`.

## Done

- Step 0 — six of eight platform facts are `test/platform_test.bp` cases (generic record with a
  function field and a generic method; union as generic argument and `is`; code-point length;
  decorator calling a sibling function and taking a default; module named through its namespace;
  JSON number is `f64`); `AGENTS.md` § Language notes rewritten from them
- Step 1 — `path.bp` (`root`, `key`, `index`, `segments`, quoted key reads back), the seven
  structural codes with built-in templates; `parity_test.bp`'s digest unchanged
- Step 2 — `schemas.bp` (`Schema<T>` with `parse`, `parseAt`, `decode`, `accepts`, `optional`,
  `array`; `text`, `int`, `long`, `float`, `boolean`, `anyJson`), `#[schema]` emitting
  `schemaOf<T>`, `parse<T>`, `parse<T>At`, `decode<T>` (decision 257); three bad fields → three
  violations in declaration order; undeclared key refused (decision 144); self-naming type decodes;
  `schema_parity_test.bp` holds twenty documents under one digest on both targets

## Open

### Step 0 residue — the two platform facts not yet tests

- [ ] `f32` round-trips on both targets — a `test/platform_test.bp` case (today only a note in
      `AGENTS.md` § Language notes)
- [ ] `url.parse` against the reference's WHATWG examples (§ URLs): a `test/platform_test.bp` case
      per input where it answers differently
- [ ] a fact found false changes the dependent step **in this README**, same commit — no design the
      platform refuses is kept

### Step 2 residue

- [ ] `examples/signup-schema-example.bp` and `nested-and-arrays-example.bp` compile and pass as
      suite cases, both targets (`test/schema_test.bp` declares its own `Signup` today)
- [ ] `parseCategory` over a four-level recursive document; a self-reference 2 000 levels deep
      does not exhaust the stack on either target (decoder recurses through `Arr`, depth is the
      document's — the test pins it; today's test is 3 levels)
- [ ] `#[schema]` on a type with an unsupported field type is a located compile error naming field
      and type — refusal exists in `decorators.bp`; a test asserts it
- [ ] `schemas.bp`'s private `itemsOf` / `membersOf` and `pub fn fieldOf` give way to std's `Json`
      methods (`input.items()`, `input.members()`; emitted `schemas.fieldOf(input, "…")` →
      `input.field("…") ?? Json.Null` or a function under another name);
      `grep -n "fn itemsOf\|fn membersOf\|fn fieldOf" libs/validation/src` is empty — the box
      `97-std-dedupe` step 2 waits on

### Step 3 — Checks and formats

Every `surface.md` row of §§ 4.3, 4.4, 4.6–4.8 and the length rows of §§ 4.19–4.27 marked `add · 3`:
8 string checks, 41 format markers, 7 numeric markers, 2 date bounds — 58 markers — plus length
markers on `Array`, `Dict`, `Set`. Each: a predicate in `constraints.bp`, a marker in
`decorators.bp`, a `checks.*` function, a built-in template, and (with parameters) a `table.bp` row.

- [ ] `constraints_test.bp`: three accepted and three refused inputs per predicate, refused ones from
      the reference's examples where given (`"555-555-5555"` for `e164`, `"2020-1-1"` for
      `isoDate`, `"usd"` for `currencyCode`, `"DE89 3704 0044 0532"` for `iban`)
- [ ] `parity_test.bp` runs every predicate on both targets against one digest
- [ ] each marker on a field type it cannot check is a compile error; `test/refusal_test.bp` lists
      one refusal per marker
- [ ] no predicate reaches a host cell: `grep -c '@External' src/constraints.bp` is `0`

### Step 4 — Enums, literals, unions, tuples, maps, sets

`#[schema]` on a payload-less enum (variant name is the wire value); `#[literal]`, `#[oneOf]`; fields
typed `A | B`, `#(A, B)`, `Dict<K, V>`, `Set<T>`; `schemas.union2…5`, `xor2…5`, `both`, `tuple2…5`,
`tupleRest`, `dict`, `set`, `never`, `nil` (`Json.Null` only, for unions); tagged enum whose variants
name `#[schema]` records (`#[tag("status")]`).

- [ ] `examples/enums-and-unions-example.bp` and `collections-example.bp` pass on both targets
- [ ] a union whose arms all fail reports one `invalidUnion` naming each arm's first violation; a
      `Set` with a repeated item reports `duplicate` at the second occurrence's index
- [ ] `#[tag]` on an enum with a variant lacking a matching `#[schema]` record is a compile error

### Step 5 — Object policy and derived types

Unknown keys (`#[stripUnknown]`, `#[rest]`), `#[present]`, `#[orElse]`, `#[orElseOf]`,
`#[fallback]`, `#[fallbackOf]`. Derived types are the language's (decision 307):
`#[validated] pub val RecipePatch = partial(Recipe);`, `pick(Recipe, .title)`, `omit`, `required`,
`mergeRecords(Dog, Breed)` — the markers `#[pick]`, `#[omit]`, `#[partial]`, `#[required]`,
`#[extending]` go.

- [ ] `examples/object-policy-example.bp` and `derived-types-example.bp` pass on both targets
- [ ] `#[validated] pub val RecipePatch = partial(Recipe);` decodes with every field optional and keeps
      `Recipe`'s markers; a second module imports and constructs it (after `01-checker` step 28)
- [ ] `derived-types-example.bp` rewritten to the five functions; no `#[extending]` repeating fields
- [ ] `#[orElse]` with a literal not decoding as the field's type is a compile error

### Step 6 — Coercion, transforms, and the form binder

`#[coerce]`, `#[stringbool]`, transforms (`#[trim]`, `#[lowercased]`, `#[uppercased]`,
`#[normalized]`, `#[normalizedUrl]`), `bindFloat`, `bind<T>` over `Array<#(string, string)>` (what
`querystring.parse` and `encoding.formParse` answer). Repeated name → an array field's items;
undeclared name → unknown-key rule. Coercion per target type, same on both targets (decision 183):
`bool` reads the `stringbool` set; a number reads the integer grammar + fraction and exponent; `""`
and `null` are absent; else `invalidType`.

- [ ] `examples/coercion-and-forms-example.bp` passes on both targets
- [ ] `bindSignup` over `email=a%40b.c&age=x&tags=a&tags=b` reports `age` as `invalidType` and
      builds nothing; with `age=30` builds `tags: ["a", "b"]`
- [ ] the existing four binders keep their tests unchanged (`binding_test.bp`)

### Step 7 — Refinements and messages

`#[check(rule, at: .field, message: "…", code: .Custom)]` on the type and `#[check(message: "…")]` on
the rule function itself (decision 280 — `01-checker/examples/decorator-arguments-280.md` example 1;
the string forms `#[check("fn", "fieldA,fieldB")]` go), `#[stopOnFirst]`,
`#[message("…")]`, `#[typeMessage("…")]`, `Schema.refine`, `Schema.parseWith(input, source)`.

- [ ] `examples/refine-and-messages-example.bp` passes on both targets
- [ ] a `#[check]` naming a missing function, a missing field (`.confrim`) or a rule of another
      signature fails at that argument (280); a `#[check]` on a rule function outside the module
      declaring the validated type is refused
- [ ] `surface.md` § 5's resolution order is one test with six rows, each overriding the next

### Step 8 — Combinators and codecs

`Schema.map`, `schemas.tryMap`, `pipe`, `preprocess`, `custom`, `refineAsync`; `Codec<A, B>`,
`schemas.codec`, `invert`; `#[with]`, `#[map]`, `#[codec]`; `encode<T>`; `codecs.bp` with the twelve
recipes.

- [ ] `examples/transform-and-codec-example.bp` passes on both targets
- [ ] every recipe: `decode(encode(x)) == x` over five values, `encode(decode(t)) == t` over five
      canonical texts
- [ ] `encode<T>` of a value failing `validate()` is an `Error`, not a document

### Step 9 — Reflection, error views, metadata, JSON Schema

`Schema.fields()`, `.keys()`, `.options()`, `.isOptional()`; `report.flatten()`, `.tree()`,
`.pretty()`; `#[title]`, `#[describe]`, `#[example]`, `#[deprecated]`, `#[schemaId]`;
`spi.registerSchema`; `jsonSchemaOf<T>`, `inputJsonSchemaOf<T>`, `table.toDraft07`,
`table.toOpenApi30`, `table.withRefBase`, `spi.registeredJsonSchemas`.

- [ ] `examples/error-views-example.bp` and `json-schema-example.bp` pass on both targets
- [ ] `jsonSchemaOf<T>` for the reference's § 8 examples is the reference's document, key order
      aside — eleven literals
- [ ] emitted document validates against the 2020-12 meta-schema: one node script under
      `test/tools/`, run by `test/json_schema_test.bp` on commonJS, skipped by nothing; on erlang
      the same literals compared byte for byte
- [ ] `T.constraints()` unchanged for the thirteen existing markers (`table_test.bp`)

### Step 10 — Locales

`locales/` — `en` (built-in table, moved), `ptBR`, `es`: one `fn() -> MessageSource` each.

- [ ] every `builtInTemplate` code has an entry in every shipped locale; a missing one fails
      `test/locales_test.bp` by name
- [ ] `setMessageSource(locales.ptBR())` changes the message of every code and of no placeholder
### Step 11 — references, not strings (decision 281)

Step 7's `#[check]` is the first (280 example 1); the rest of the string-named arguments:

- [ ] ~~`#[extending(Dog)]`, `#[partial(Recipe)]` take the type~~ — the markers go (307)
- [ ] ~~`#[with(emails)]` takes the function value~~ — `#[with]` goes (306, step 12)
- [ ] `#[orElse(.Tuna)]` takes a value of the field's type (`T`, 280 (2))
- [ ] `#[wireNames("Salmon=salmon,…")]` → `#[wireName("salmon")]` on each variant: the variant is the
      reference, the wire spelling a string (another system's name)

### Step 12 — the type is the only schema; `#[schema]` becomes `#[validated]` (decision 306)

Narrows steps 4, 7, 8 and 9: their `schemas.*` / `Schema.*` / `checks.*` items become the markers
below or `n/a (306)`; the items about types and markers stand.

- [ ] `#[schema]` deleted from `decorators.bp`; `#[validated]` emits what it emitted (members per
      `ctr-u`) beside `validate()` / `constraints()`; a type carrying both today migrates to the one;
      rakun's config binder (`validate()` / `constraints()` by name) unchanged
- [ ] `Schema<T>`, `Codec<A, B>`, `Check<T>`, `schemas`, `checks` not exported from `root.bp`;
      `grep -rn "schemas\.\|checks\.\|Schema<" ` outside `libs/validation/src` answers nothing in
      `repository/` (consumers in 117, 121, 127 move by their fronts)
- [ ] the field markers `#[each(…markers)]`, `#[codec(decode: f, encode: g)]`, `#[map(f)]`,
      `#[tryMap(f)]`, `#[preprocess(f)]`, `#[check(rule)]` on a field, and `#[validated(transparent)]`
      (one field, encoded as that field) — each with a decoding test on both targets and a located
      refusal (wrong function signature, `transparent` on a type with two fields, `#[each]` on a
      non-collection)
- [ ] `#[with]` goes (step 11's `#[with(emails)]` box with it)
- [ ] `surface.md`: every row re-sorted — a marker, a type, or `n/a (306)` with its reason; the
      `union2…5` / `tuple2…5` / `xor2…5` families gone (nat-d4)
- [ ] reflection (step 9) reads the type: `@typeInfo(T)` and its meta, not `Schema.fields()`;
      `jsonSchemaOf<T>` from the declaration only
- [ ] every example under `examples/` rewritten: `#[validated]` for `#[schema]`, no `schemas.*` /
      `checks.*` / `Schema<T>` in application code (`transform-and-codec-example.bp`,
      `collections-example.bp`'s `tupleRest`, `refine-and-messages-example.bp`'s value refine, …)

## Decisions

### 07-j · How much of Zod is the front

**Measured.** `surface.md`: 211 reference rows; 11 native, 37 have, 134 add, 7 need a compiler row,
20 have no meaning here, 2 out of the reference's core.
**Options.** (a) markers only — §§ 4.3, 4.4, 4.6 (step 3 alone); (b) steps 0–2 and 3: `parse<T>` for
flat records + markers; (c) every step.
**Recommendation.** (c), in step order. (a) lacks the function Zod is named for; (b) leaves unions,
coercion, codecs hand-written by consumers — the cost `language-gaps.md` records.
**Blocks.** the front's size.

`ctr-u` — decision 216 against `#[schema]`'s free `@emit` ([`../../decisions-pending.md`](../../decisions-pending.md)). Steps 3–10.

## Notes

- **Embedded source grows:** `libs/validation` is compiled into the binary (`build.zig`'s
  `bundled_packages`); step 3 reports binary size before and after.
- **`#[validated]`'s contract stays:** rakun's config binder calls `validate()` / `constraints()` by
  name (decision 216); every existing marker keeps code, message, table row.
- **`Violation.field` is a path only for nested data**; flat record → the field's name, as before.
- **Consumers unchanged here:** the three `isHex` walks, hand-written `…Json(` functions, route
  handlers reading query fields — candidates in each member's owning front.
- **Snapshots:** none in `libs/validation/test/`, none added — JSON Schema asserted as a literal.
- **Not added:** `z.function`, `z.promise`, `z.symbol`, `z.undefined`, `z.nan`, typed registries,
  `fromJSONSchema`, JIT switches — each `n/a` with reason in `surface.md`. None is "later".
- **Async:** derived schemas are synchronous. `schemas.refineAsync` answers a `Schema` whose `parse`
  is `-> @Task<@Result<…>>`; on erlang `@Task` is eager (`language-gaps.md` lg2-b) — "may call a
  `@Task` function", not "concurrent".
- **Cross-backend regex:** intersection of PCRE (`re:run/2`) and ECMAScript, grammar at
  `constraints.bp:212-219`: no backslash class, no lookaround. Formats not sayable in it — `emoji`,
  `ipv6`, `iban`, `creditCard`, the ISO family — are walks; `parity_test.bp` holds the claim.
- **Decision 67:** a marker on an uncheckable field type is a located compile error; step 3's
  `refusal_test.bp` has one row per marker and fails when the counts differ.

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `--target commonJS`
green and `botopink format --check src test` clean in `libs/validation`
- [ ] `zig build test-libs`: rakun's two `#[validated]` consumers still green — the name contract
      `validate()` / `constraints()` (decision 216) did not move
- [ ] every file under `examples/` is a suite case — an example that does not compile is red

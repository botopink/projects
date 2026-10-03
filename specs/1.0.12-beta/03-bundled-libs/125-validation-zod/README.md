# Front 125 — validation zod: Zod's feature set in botopink

**Priority:** high for the step 0–2 residue — `08-bpp/121` (content collections) and `08-bpp/127`
(actions) take the `Schema<T>` steps 0–2 landed; medium for the rest · **State:** partial: steps
0–2 on feat with residue; steps 3–10 open
**Depends on:** `07-j` (the front's size). Written against decisions 144 (undeclared keys), 145 (the
emitted names), 183 (`07-m`: coercion, step 6) and 257 (`07-n`: `Schema<T>` lives in `validation`)
**Owns:** `libs/validation/src/**` · `libs/validation/test/**` · `libs/validation/AGENTS.md` ·
`libs/validation/botopink.json` — but for one line: `src/messages.bp`'s `interpolate` is moved
to `i18n` by `105-i18n`, whose commit lands between two steps of this front, never during one
(decision 189)
**Does not touch:** the compiler (`modules/**`) — a need is a row in
[`language-gaps.md`](../../language-gaps.md) and a nearest form; `libs/std/**` (97's); the other
bundled packages; any consumer file in rakun, jhonstart or onze — a consumer that wants a marker
imports it, in its own front

The full feature map — all 211 rows of the reference, with the box each one falls in — is
[`surface.md`](./surface.md). The code each step is aiming at is under [`examples/`](./examples/).

## Goal

Zod's core operation is `parse`: untrusted data in, a typed value or a list of located issues out.
`#[validated]`'s `v.validate()` checks a value that is **already typed**, so every boundary that receives
JSON, a form or a config file built the record by hand (`language-gaps.md`: "No `record ↔ Json`
derivation"; 39 functions named `…Json(` outside tests, 33 in rakun). The demand is not more
regexes — `regex.matches(` outside `libs/std` and `libs/validation`: 0; `#[pattern(…)]` outside the
library: 1, in a test; `registerConstraint(` outside: 0; private format walks: 3 `isHex`
(`jhonstart-emilia/src/root.bp`, `rakun-web/src/static.bp`, `rakun-actuator-api/src/span.bp`). It is
the function from `Json` to a record, and the rest of Zod follows from having it: when the front
lands, `#[schema]` derives parse / decode / bind / encode / JSON Schema, `Schema<T>` composes, the
checks grow from 13 markers to 71, reports gain views and locales.

On feat `libs/validation` is 2 134 lines of source — `report.bp`, `constraints.bp` (20 `v*`
predicates), `decorators.bp` (`#[validated]`, 13 markers, `#[schema]`), `messages.bp`, `spi.bp`,
`binding.bp`, `table.bp`, `path.bp`, `schemas.bp` — and 98 tests in eleven files, green on erlang
and commonJS. Consumers: rakun's `rakun/src/{config,config_check}.bp`; jhonstart and onze import
nothing from it.

What the language and std already provide, each something a `parse` does not have to build:

| Need | Where it is |
|---|---|
| a parsed JSON tree | `json.Json { Null, Bool, Num, Str, Arr, Obj }`, `json.decode(s) -> @Result<Json, string>` — members in document order, duplicates refused; the `Json` methods `members` / `field` / `items` (97) |
| a fallible return | `@Result<T, E>`, `try`, `try … catch`, `case` (`docs.md`) |
| unions and an untyped value | `A \| B`, `unknown`, `x is T` |
| tuples, enums with payloads, optionals | `#(A, B)`, `type Shape { Circle(radius: f64) }`, `?T` |
| maps and sets | `Dict<K, V>`, `Set<T>` (`libs/std/src/collections.bp`) |
| field defaults | `type Port(number: i32 = 80, host: string)` |
| derived record types | `partial(T)`, `pick`, `omit`, `mergeRecords` (`comptime/infer.zig`) |
| a decorator that writes types | `@emit("pub type …")` (`rakun-data/src/orm/entity.bp`) |
| text helpers | `regex.compile` / `captures`, `unicode.normalize` / `codepoints`, `url.parse`, `encoding.base64Decode` / `hexDecode`, `clock.parseIso8601` / `toCivil`, `string.parseFloat` (97) |

## Mechanism

Zod is one object model used two ways: as a type (`z.infer`) and as a parser. botopink splits the
two, and the front follows the split.

**The type is the schema.** A record or an enum marked `#[schema]` is reflected the way
`#[validated]` reflects it — `decl.fields`, each field's `typeName` and `annotations`
(`decorators.bp`'s `validated`) — and the decorator `@emit`s functions named after the type.
Decision 216 retires the loose `@emit` (`#[validated]` now adds the members `validate()` /
`constraints()` to the type); `#[schema]`'s free functions still use it, and whether they become
members (`Player.parse(input)`) is not decided (`ctr-u`):

| Emitted | Zod's |
|---|---|
| `pub fn schemaOf<T>() -> Schema<T>` | the schema value |
| `pub fn parse<T>(input: Json) -> @Result<T, ValidationReport>` | `.parse` / `.safeParse` |
| `pub fn parse<T>At(input: Json, at: string) -> @Result<T, ValidationReport>` | the same, for a value that sits at the path `at` of a larger document — what a nested field calls |
| `pub fn decode<T>(text: string) -> @Result<T, ValidationReport>` | `.parse(JSON.parse(text))`, a syntax error as one violation coded `invalidJson` |
| `pub fn bind<T>(pairs: Array<#(string, string)>) -> @Result<T, ValidationReport>` | `z.coerce.*` over a form or a query |
| `pub fn encode<T>(v: T) -> @Result<Json, ValidationReport>` | `.encode` |
| `pub fn jsonSchemaOf<T>() -> string` | `z.toJSONSchema` |

The decoder is emitted as straight-line code, one statement per field: every field is decoded,
every violation collected, and the record is constructed only when the list is empty — "all
violations, not fail-fast" stays the shape rather than an option (`binding.bp`'s header). A field
whose type is another `#[schema]` type is decoded by calling `parse<ThatType>At`, by name, so a
decorator never needs to see a second declaration. Checks are not duplicated in a second
decorator: a type that carries markers is also `#[validated]`, and `parse<T>` calls
`validate()` on the record it built. A marker on a `#[schema]` type that is not `#[validated]` is
a compile error — a check nothing runs is the failure this library designs out (decision 67).

**A schema is also a value.** `Schema<T>` is a record holding the decoder, with methods for the
wrappers and combinators for what a type declaration cannot say:

```bp
pub type Schema<T>(…) {
    pub fn parse(self: Self<T>, input: Json) -> @Result<T, ValidationReport>
    pub fn decode(self: Self<T>, text: string) -> @Result<T, ValidationReport>
    pub fn accepts(self: Self<T>, input: Json) -> bool
    pub fn optional(self: Self<T>) -> Schema<?T>
    pub fn array(self: Self<T>) -> Schema<Array<T>>
    pub fn check(self: Self<T>, c: Check<T>) -> Schema<T>
    pub fn refine(self: Self<T>, ok: fn(v: T) -> bool, code: string, message: string) -> Schema<T>
    pub fn map<U>(self: Self<T>, f: fn(v: T) -> U) -> Schema<U>
}
```

`schemas.text()`, `schemas.int()`, `schemas.union2(a, b)`, `schemas.pipe(a, b)`,
`schemas.codec(inner, decode, encode)` build them; `checks.minLength(2)` is a `Check<string>`, so a
string check on a number schema does not compile. A derived type reaches a hand-built schema with
one marker — `#[with("slugSchema")] slug: string` — and that is the whole seam between the layers.

`Schema<T>` is also what another library takes when it must accept "any schema": a content
collection's `schema:` and an action's `input:` are parameters of that type.

**What the platform fixes about the shape** (measured on erlang and commonJS; each is a line of
`libs/validation/AGENTS.md` § Language notes and, where a test can hold it, a case of
`test/platform_test.bp`; the compiler rows are in `language-gaps.md`):

- **A result is built by a function.** `Ok(v)` and `Error(e)` are patterns, not constructors, and
  a `throw` inside a `case` arm does not become the function's `Error`. Every decoder is a named
  function that tests first and throws from a top-level `if`.
- **The library is named through a namespace; its types are leaves** (decision 145). A type cannot
  be spelled through a namespace, so an application imports
  `{schemas, schemas.Schema, report.ValidationReport, report.Violation}`.
- **A library function is called, not passed.** A namespace member is resolved where it is called:
  `schemas.of(schemas.decodeString)` is an unbound name. For each wrapper level under a field
  (`Array<Array<i32>>`, `?Array<string>`) the decorator emits one named function and passes that.
- **The text constructor is `schemas.text()`.** A function named `string` shadows the primitive
  type in every annotation of its module.
- **A generic value becomes an optional through a list** — `[v].at(0)` — because
  `fn some<T>(v: T) -> ?T { return v; }` is "recursive type detected".
- **Length is counted in code points** — `unicode.codepoints(s).length`. `"😀".length()` is 2 on
  commonJS and 1 on erlang, so no length marker may be written against `length()`.
- **`f32` has no literal** (`val f: f32 = 1.5;` is a mismatch) and std has no `f64` → integer
  conversion: an `i32` / `i64` field is produced by three host cells in `schemas.bp`.

## Done

- Step 0 — six of the eight platform facts are cases of `test/platform_test.bp` (a generic record
  with a function field and a generic method; a union as a generic argument and `is`; the
  code-point length; a decorator calling a sibling function and taking a default; a module named
  through its namespace; a JSON number is an `f64`), and `AGENTS.md` § Language notes is rewritten
  from them
- Step 1 — `path.bp` (`root`, `key`, `index`, `segments`, a quoted key reads back) and the seven
  structural codes with built-in templates; `parity_test.bp`'s digest unchanged
- Step 2 — `schemas.bp` (`Schema<T>` with `parse`, `parseAt`, `decode`, `accepts`, `optional`,
  `array`; `text`, `int`, `long`, `float`, `boolean`, `anyJson`) and `#[schema]` emitting
  `schemaOf<T>`, `parse<T>`, `parse<T>At`, `decode<T>` (decision 257); three bad fields report three
  violations in declaration order; an undeclared key is refused (decision 144); a type naming
  itself decodes; `schema_parity_test.bp` holds twenty documents under one digest on both targets

## Open

### Step 0 residue — the two platform facts not yet tests

- [ ] `f32` round-trips on both targets — a case of `test/platform_test.bp` (today only a note,
      `AGENTS.md` § Language notes)
- [ ] `url.parse` against the WHATWG examples of the reference (§ URLs): a case per input where it
      answers differently, in `test/platform_test.bp`
- [ ] a fact that turns out false changes the step that depended on it **in this README**, in the
      same commit — the spec does not keep a design the platform refuses

### Step 2 residue

- [ ] `examples/signup-schema-example.bp` and `nested-and-arrays-example.bp` compile and pass as
      cases of the suite, both targets (`test/schema_test.bp` declares its own `Signup` today)
- [ ] `parseCategory` over a four-level recursive document, and a self-reference 2 000 levels deep
      does not exhaust the stack on either target (the decoder recurses through `Arr`, so the depth
      is the document's — the test pins what it is; today's test is 3 levels)
- [ ] `#[schema]` on a type with a field of an unsupported type is a located compile error naming
      the field and the type — the refusal exists in `decorators.bp`; a test asserts it
- [ ] `schemas.bp`'s private `itemsOf` / `membersOf` and `pub fn fieldOf` give way to std's `Json`
      methods (`input.items()`, `input.members()`; the emitted `schemas.fieldOf(input, "…")` becomes
      `input.field("…") ?? Json.Null` or a function under another name);
      `grep -n "fn itemsOf\|fn membersOf\|fn fieldOf" libs/validation/src` is empty — the box
      `97-std-dedupe` step 2 waits on

### Step 3 — Checks and formats

Every row of `surface.md` §§ 4.3, 4.4, 4.6–4.8 and the length rows of §§ 4.19–4.27 marked
`add · 3`: 8 string checks, 41 format markers, 7 numeric markers, 2 date bounds — 58 markers — and
the length markers on `Array`, `Dict` and `Set`. Each is a predicate in `constraints.bp`, a marker in `decorators.bp`, a
`checks.*` function, a built-in template and — when it has parameters — a row of `table.bp`.

- [ ] `constraints_test.bp`: three accepted and three refused inputs per predicate, the refused
      ones taken from the reference's own examples where it gives them (`"555-555-5555"` for
      `e164`, `"2020-1-1"` for `isoDate`, `"usd"` for `currencyCode`, `"DE89 3704 0044 0532"` for
      `iban`)
- [ ] `parity_test.bp` runs every predicate on both targets against one digest
- [ ] each marker on a field type it cannot check is a compile error; `test/refusal_test.bp` lists
      one refusal per marker
- [ ] no predicate reaches a host cell: `grep -c '@External' src/constraints.bp` is `0`

### Step 4 — Enums, literals, unions, tuples, maps, sets

`#[schema]` on a payload-less enum (the variant name is the wire value); `#[literal]`, `#[oneOf]`;
fields typed `A | B`, `#(A, B)`, `Dict<K, V>`, `Set<T>`; `schemas.union2…5`, `xor2…5`, `both`,
`tuple2…5`, `tupleRest`, `dict`, `set`, `never`, `nil` (`Json.Null` only, for unions); a tagged enum whose variants name `#[schema]`
records (`#[tag("status")]`).

- [ ] `examples/enums-and-unions-example.bp` and `collections-example.bp` pass on both targets
- [ ] a union whose arms all fail reports one `invalidUnion` whose message names each arm's first
      violation; a `Set` with a repeated item reports `duplicate` at the second occurrence's index
- [ ] `#[tag]` on an enum with a variant that has no matching `#[schema]` record is a compile error

### Step 5 — Object policy and derived types

Unknown keys (`#[stripUnknown]`, `#[rest]`), `#[present]`, `#[orElse]`, `#[orElseOf]`,
`#[fallback]`, `#[fallbackOf]`; the type-emitting markers `#[pick]`, `#[omit]`, `#[partial]`,
`#[required]`, and the check `#[extending]` (`extends` is a keyword — `lexer.zig:754`).

- [ ] `examples/object-policy-example.bp` and `derived-types-example.bp` pass on both targets
- [ ] `#[partial("RecipePatch")]` emits a type a second module imports and constructs
- [ ] `#[orElse]` with a literal that does not decode as the field's type is a compile error

### Step 6 — Coercion, transforms, and the form binder

`#[coerce]`, `#[stringbool]`, the transform markers (`#[trim]`, `#[lowercased]`, `#[uppercased]`,
`#[normalized]`, `#[normalizedUrl]`), `bindFloat`, and `bind<T>` over `Array<#(string, string)>` —
the shape `querystring.parse` and `encoding.formParse` answer. A repeated name becomes an array
field's items; a name the type does not declare follows the unknown-key rule. Coercion is a
grammar per target type, the same on erlang and commonJS (decision 183): `bool` reads the
`stringbool` set, a number reads the integer grammar extended with a fraction and an exponent,
`""` and `null` are absent, and anything else is `invalidType`.

- [ ] `examples/coercion-and-forms-example.bp` passes on both targets
- [ ] `bindSignup` over `email=a%40b.c&age=x&tags=a&tags=b` reports `age` as `invalidType` and
      builds nothing; the same input with `age=30` builds `tags: ["a", "b"]`
- [ ] the existing four binders keep their tests unchanged (`binding_test.bp`)

### Step 7 — Refinements and messages

`#[check("fn")]` and `#[check("fn", "fieldA,fieldB")]` on the type, `#[stopOnFirst]`,
`#[message("…")]`, `#[typeMessage("…")]`, `Schema.refine`, `Schema.parseWith(input, source)`.

- [ ] `examples/refine-and-messages-example.bp` passes on both targets
- [ ] a `#[check]` naming a function that does not exist, or one with another signature, fails at
      the annotation's module with the function's name in the message
- [ ] the resolution order of `surface.md` § 5 is one test with six rows, each overriding the next

### Step 8 — Combinators and codecs

`Schema.map`, `schemas.tryMap`, `pipe`, `preprocess`, `custom`, `refineAsync`; `Codec<A, B>`,
`schemas.codec`, `invert`; `#[with]`, `#[map]`, `#[codec]`; `encode<T>`; `codecs.bp` with the
twelve recipes.

- [ ] `examples/transform-and-codec-example.bp` passes on both targets
- [ ] for every recipe, `decode(encode(x)) == x` over five values, and `encode(decode(t)) == t`
      over five canonical texts
- [ ] `encode<T>` of a value that fails `validate()` is an `Error`, not a document

### Step 9 — Reflection, error views, metadata, JSON Schema

`Schema.fields()`, `.keys()`, `.options()`, `.isOptional()`; `report.flatten()`, `.tree()`,
`.pretty()`; `#[title]`, `#[describe]`, `#[example]`, `#[deprecated]`, `#[schemaId]`;
`spi.registerSchema`; `jsonSchemaOf<T>`, `inputJsonSchemaOf<T>`, `table.toDraft07`,
`table.toOpenApi30`, `table.withRefBase`, `spi.registeredJsonSchemas`.

- [ ] `examples/error-views-example.bp` and `json-schema-example.bp` pass on both targets
- [ ] `jsonSchemaOf<T>` for the reference's § 8 examples is the reference's document, key order
      aside — eleven literals
- [ ] the emitted document validates against the 2020-12 meta-schema; the check is one node script
      under `test/tools/`, run by `test/json_schema_test.bp` on commonJS and skipped by nothing: on
      erlang the same literals are compared byte for byte instead
- [ ] `T.constraints()` is unchanged for the thirteen existing markers (`table_test.bp`)

### Step 10 — Locales

`locales/` — `en` (the built-in table, moved), `ptBR`, `es`: one `fn() -> MessageSource` each.

- [ ] every code of `builtInTemplate` has an entry in every shipped locale; a missing one fails
      `test/locales_test.bp` by name
- [ ] `setMessageSource(locales.ptBR())` changes the message of every code and of no placeholder
## Decisions

### 07-j · How much of Zod is the front

**Measured.** `surface.md`: 211 reference rows; 11 native, 37 have, 134 add, 7 need a compiler row,
20 have no meaning here, 2 out of the reference's core.
**Options.** (a) the markers only — §§ 4.3, 4.4, 4.6 (step 3 alone); (b) steps 0–2 and 3:
`parse<T>` for flat records plus the markers; (c) every step.
**Recommendation.** (c), landed in step order. (a) leaves the library without the function Zod is
named for; (b) leaves unions, coercion and codecs for the consumers to hand-write, which is the
state `language-gaps.md` already records as a cost.
**Blocks.** the front's size.

`ctr-u` — decision 216 against `#[schema]`'s free `@emit` ([`../../decisions-pending.md`](../../decisions-pending.md)). Steps 3–10.

## Notes

- **The embedded source grows.** `libs/validation` is compiled into the compiler binary
  (`build.zig`'s `bundled_packages`); step 3 reports the binary's size before and after.
- **`#[validated]`'s contract does not move.** rakun's config binder calls the members
  `validate()` / `constraints()` by name (decision 216); every existing marker keeps its code, its message and its table row.
- **`Violation.field` is a path only for nested data**; a flat record's `field` is the field's
  name, as before.
- **Consumers do not change in this front.** The three `isHex` walks, the hand-written `…Json(`
  functions and the route handlers that read fields from the query become candidates, each in the
  front that owns its member.
- **Snapshots:** `libs/validation/test/` has no snapshot directory and this front adds none — a
  JSON Schema is asserted as a literal.
- **What this front does not add, and why.** `z.function`, `z.promise`, `z.symbol`,
  `z.undefined`, `z.nan`, typed registries, `fromJSONSchema` and the JIT switches: `surface.md`
  marks each `n/a` with its reason. None is "later".
- **Async.** A derived schema is synchronous. `schemas.refineAsync` answers
  `Schema` whose `parse` is `-> @Task<@Result<…>>`; on erlang a `@Task` is eager
  (`language-gaps.md` lg2-b), so "async" there means "may call a `@Task` function", not
  "concurrent".
- **Cross-backend regex.** Every regex is written in the intersection of PCRE (`re:run/2`) and
  ECMAScript, the grammar documented at `constraints.bp:212-219`: no backslash class, no
  lookaround. Where a format cannot be said in that grammar — `emoji`, `ipv6`, `iban`,
  `creditCard`, the ISO family — the predicate is a walk, and `parity_test.bp` is what holds the
  claim up.
- **Decision 67.** A marker on a field whose type it cannot check is a located compile error. The
  refusal table grows with every marker; a missing arm is a marker that silently passes, so step
  3's `refusal_test.bp` has one row per marker and fails when the two counts differ.

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `--target commonJS`
green and `botopink format --check src test` clean in `libs/validation`
- [ ] `zig build test-libs`: rakun's two consumers of `#[validated]` still green — the name
      contract `validate()` / `constraints()` (decision 216) did not move
- [ ] every file under `examples/` is a case of the suite — an example that does not compile is red

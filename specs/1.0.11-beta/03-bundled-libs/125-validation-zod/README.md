# Front 125 — validation: Zod's feature set in botopink

**Priority:** high for steps 0–2 — `08-bpp/121` (content collections) and `08-bpp/127` (actions)
take a `Schema<T>` and cannot start without it; medium for the rest.
**Depends on:** `00-gate` (a green gate before a new constraint reaches both targets);
`02-std-and-packaging/97-std-dedupe` (its `Json` accessors and `parseFloat` are what steps 2 and 6
read with). Step 6 is written against decision 183 (`07-m`: a grammar per target type); the
undeclared-key rule against decision 144 and the emitted names against decision 145. Open:
`07-n` (step 2) and `07-j` (the front's size).
**Owns:** `libs/validation/src/**` · `libs/validation/test/**` · `libs/validation/AGENTS.md` ·
`libs/validation/botopink.json` — but for one line: `src/messages.bp:96` (`interpolate`) is moved
to `i18n` by `105-i18n`, whose commit lands between two steps of this front, never during one
(decision 189)
**Does not touch:** the compiler (`modules/**`) — a need is a row in
[`language-gaps.md`](../../language-gaps.md) and a nearest form; `libs/std/**` (97's); the other
bundled packages; any consumer file in rakun, jhonstart or onze — a consumer that wants a marker
imports it, in its own front.

The full feature map — all 205 rows of the reference, with the box each one falls in — is
[`surface.md`](./surface.md). The code each step is aiming at is under [`examples/`](./examples/).

---

## Problem

Zod's core operation is `parse`: untrusted data in, a typed value or a list of located issues out.
`libs/validation` has no such function. What it has is `validate<TypeName>(v: TypeName)`
(`decorators.bp:199-207`), which checks a value that is **already typed** — so every boundary that
receives JSON, a form or a config file builds the record by hand first:

```bp
// ../../07-onze/53-onze-example-app/examples/route-handler-example.bp:95-101
val parsed = bodyJson(req);          // validates that the text is JSON, answers the text
val title = req.query("title");      // …so the handler reads its fields from the query instead
```

and `language-gaps.md` carries the cost as a row of its own: "**No `record ↔ Json` derivation** —
a record is serialised and parsed by hand-written field lists" (39 functions named `…Json(`
outside tests: 33 in rakun, 6 in the compiler's libs).

More markers alone would not answer it. Whether the consumers are short of predicates was
measured on 2026-10-01, over `repository/**/*.bp`:

| Looked for | Found |
|---|---|
| `regex.matches(` outside `libs/std` and `libs/validation` — a hand-rolled format check | **0** |
| `#[pattern(…)]` outside the library | **1**: a URL shape, in a test (`rakun/modules/rakun/test/config_check_test.bp:40`) |
| `registerConstraint(` call sites outside the library | **0** |
| private format walks | **3** `isHex` (`jhonstart-emilia/src/root.bp:39`, `rakun-web/src/static.bp:271`, `rakun-actuator-api/src/span.bp:149`) |

The demand is not more regexes. It is the function from `Json` to a record, and the rest of Zod
follows from having it.

## Current state

Measured 2026-10-01 at `repository/botopink-lang/libs/validation/`:

| Module | Lines | Holds |
|---|---|---|
| `report.bp` | 119 | `Violation(field, code, message, invalidValue)`, `ValidationReport` (`isValid`, `merge`, `toJson`, `toProblemDetail`, `empty`, `of`) |
| `constraints.bp` | 258 | 20 `v*` predicates, `emailPattern` |
| `decorators.bp` | 338 | `#[validated]` and 13 markers |
| `messages.bp` | 161 | `MessageSource`, `templateFor`, `interpolate`, 15 built-in templates |
| `spi.bp` | 149 | `Constraint`, `registerConstraint`, `vConstraint` — 7 host cells |
| `binding.bp` | 187 | `bindInt`, `bindBool`, `bindRequired`, `bindEpochMillis`, the accumulator — 6 host cells |
| `table.bp` | 116 | `constraintTableJson` and the blob grammar |
| `test/*.bp` | 1 038 | seven files, suite `validation:`, green on erlang and commonJS |

Consumers: `rakun/modules/rakun/src/{config,config_check}.bp` and `rakun-starter-web/src/root.bp`.
jhonstart and onze import nothing from it.

What the language and std already provide — each row is something a `parse` needs and does not
have to build:

| Need | Where it is |
|---|---|
| a parsed JSON tree | `json.Json { Null, Bool, Num, Str, Arr, Obj }`, `json.decode(s) -> @Result<Json, string>` — members in document order, duplicates refused (`libs/std/src/json.bp:113-143`) |
| a fallible return | `@Result<T, E>`, `try`, `try … catch`, `case` (`docs.md:1467-1529`) |
| unions and an untyped value | `A \| B`, `unknown`, `x is T` (`docs.md:620-646`) |
| tuples, enums with payloads, optionals | `#(A, B)`, `type Shape { Circle(radius: f64) }`, `?T` (`docs.md:400-439`) |
| maps and sets | `Dict<K, V>`, `Set<T>` (`libs/std/src/collections.bp:27`, `:246`) |
| field defaults | `type Port(number: i32 = 80, host: string)` (`docs.md:1340`) |
| derived record types | `partial(T)`, `pick`, `omit`, `mergeRecords` (`comptime/infer.zig:6439`) |
| a decorator that writes types | `@emit("pub type …")` (`rakun-data/src/orm/entity.bp:183`) |
| text helpers | `regex.compile` / `captures`, `unicode.normalize` / `codepoints`, `url.parse`, `encoding.base64Decode` / `hexDecode`, `clock.parseIso8601` / `toCivil` |

## Mechanism

Zod is one object model used two ways: as a type (`z.infer`) and as a parser. botopink splits the
two, and the front follows the split.

**The type is the schema.** A record or an enum marked `#[schema]` is reflected the way
`#[validated]` reflects it today — `decl.fields`, each field's `typeName` and `annotations`
(`decorators.bp:55-66`) — and the decorator `@emit`s functions named after the type, the contract
`validate<TypeName>` already established (`decorators.bp:11-17`):

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
violations, not fail-fast" stays the shape rather than an option (`binding.bp:22-24`). A field
whose type is another `#[schema]` type is decoded by calling `parse<ThatType>At`, by name, so a
decorator never needs to see a second declaration. Checks are not duplicated in a second
decorator: a type that carries markers is also `#[validated]`, and `parse<T>` calls
`validate<T>` on the record it built. A marker on a `#[schema]` type that is not `#[validated]` is
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
`test/platform_test.bp`):

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

## Steps

Steps 0–2 are the keystone and land as one unit; 3–10 are independent of each other except where
stated, and each lands green on its own.

### Step 0 — Measure what the design stands on

Eight facts the steps below depend on, none of which this spec may assume. Each becomes a test in
`test/platform_test.bp` that runs on both targets, so the answer is recorded as code:

- [ ] a generic record with a function field and a generic method (`Schema<T>.map<U>`) compiles and
      runs on erlang and commonJS — the shape `Box<T>.map<U>` has in `docs.md:578-586`
- [ ] `A | B` as a generic argument (`Schema<string | i32>`) and `x is string` on a `Json` payload
      at run time, both targets
- [ ] `"é".length()`, `"😀".length()` and `.at(i)` over both — code points or code units, and
      whether the two targets agree (`language-gaps.md`: `indexOf` counts bytes on erlang)
- [ ] a decorator body calling a bodied function of its own module — `validation/AGENTS.md` says it
      cannot; `language-gaps.md` (the lg2-w row) says a bodied one travels and only a host
      `declare fn` does not. One of the two is stale
- [ ] `import {schemas} from "validation"` binds a namespace and `schemas.text()` resolves in
      code a decorator emitted into a consumer — the bundled-package case of what
      `#[mocks.mock]` does for std
- [ ] a marker declared with a default (`pub fn uuidV(comptime decl: @Decl, version: i32 = 4)`) and
      applied as `#[uuidV]` — `decorators.bp:231-235` says a default is never applied; `docs.md:1333`
      says the checker fills it
- [ ] `f32` round-trips on both targets
- [ ] `url.parse` against the WHATWG examples of the reference (§ URLs): the list of inputs where
      it answers differently

**Acceptance:**
- [ ] `test/platform_test.bp` green on erlang and commonJS, each case asserting one literal
- [ ] `AGENTS.md` § Language notes rewritten from the eight results, the stale line deleted
- [ ] a fact that turns out false changes the step that depended on it **in this README**, in the
      same commit — the spec does not keep a design the platform refuses

### Step 1 — The report carries paths and structural codes

`Violation.field` becomes the rendered path: `email`, `address.street`, `tags[1]`,
`members.alice`. The record keeps its four fields, so `toJson`, `toProblemDetail` and every
consumer of `field` read what they read today for a flat record.

- `path.bp`: `root()`, `key(at, name)`, `index(at, i)`, `segments(field) -> Array<string>`
- seven codes with built-in templates: `invalidType` (`{expected}`, `{received}`),
  `unrecognizedKey`, `invalidUnion`, `invalidValue` (`{options}`), `duplicate`, `invalidJson`
  (`{reason}`), `custom`

**Acceptance:**
- [ ] `test/path_test.bp`: `segments("items[2].name")` is `["items", "2", "name"]`; a key holding
      `.` or `[` is written `["a.b"]` and reads back
- [ ] `messages_test.bp` covers the seven templates; `parity_test.bp`'s digest is unchanged for the
      twenty existing inputs

### Step 2 — `Schema<T>`, the primitives, and `#[schema]` on a record

`schemas.bp` — `Schema<T>`, `text`, `int`, `long`, `float`, `boolean`, `anyJson`, `optional`,
`array`, and the functions the emitted code calls (`fieldOf`, `memberPath`, `objectProblems`,
`unknownKeys`, `optionalOf`, `decodeArrayOf`, `decodeText`); `decorators.bp` — `#[schema]`
emitting `schemaOf<T>`, `parse<T>`, `parse<T>At`, `decode<T>` for a record whose fields are `string`, `i32`, `i64`, `f64`, `bool`, `Json`, `?T`,
`Array<T>` and other `#[schema]` types, itself included.

- `i32`: a `Num` with no fraction, inside the range; `i64`: integral and within ±(2^53 − 1)
- a missing key and `null` are the same absent value for `?T`, and `required` for `T`
- an undeclared key is refused from the first commit (decision 144)

**Acceptance:**
- [ ] `examples/signup-schema-example.bp` and `nested-and-arrays-example.bp` compile and pass as
      `test/schema_test.bp` cases, both targets
- [ ] a record with three bad fields reports three violations, in declaration order
- [ ] `parseCategory` over a four-level recursive document, and a self-reference 2 000 levels deep
      does not exhaust the stack on either target (the decoder recurses through `Arr`, so the depth
      is the document's — the test pins what it is)
- [ ] `#[schema]` on a type with a field of an unsupported type is a located compile error naming
      the field and the type
- [ ] `parity_test.bp` gains twenty documents; one digest, both targets

### Step 3 — Checks and formats

Every row of `surface.md` §§ 4.3, 4.4, 4.6–4.8 and the length rows of §§ 4.19–4.27 marked
`add · 3`: 8 string checks, 41 format markers, 7 numeric markers, 2 date bounds — 58 markers — and
the length markers on `Array`, `Dict` and `Set`. Each is a predicate in `constraints.bp`, a marker in `decorators.bp`, a
`checks.*` function, a built-in template and — when it has parameters — a row of `table.bp`.

**Acceptance:**
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
`tuple2…5`, `tupleRest`, `dict`, `set`, `never`; a tagged enum whose variants name `#[schema]`
records (`#[tag("status")]`).

**Acceptance:**
- [ ] `examples/enums-and-unions-example.bp` and `collections-example.bp` pass on both targets
- [ ] a union whose arms all fail reports one `invalidUnion` whose message names each arm's first
      violation; a `Set` with a repeated item reports `duplicate` at the second occurrence's index
- [ ] `#[tag]` on an enum with a variant that has no matching `#[schema]` record is a compile error

### Step 5 — Object policy and derived types

Unknown keys (`#[stripUnknown]`, `#[rest]`), `#[present]`, `#[orElse]`, `#[orElseOf]`,
`#[fallback]`, `#[fallbackOf]`; the type-emitting markers `#[pick]`, `#[omit]`, `#[partial]`,
`#[required]`, and the check `#[extending]` (`extends` is a keyword — `lexer.zig:754`).

**Acceptance:**
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

**Acceptance:**
- [ ] `examples/coercion-and-forms-example.bp` passes on both targets
- [ ] `bindSignup` over `email=a%40b.c&age=x&tags=a&tags=b` reports `age` as `invalidType` and
      builds nothing; the same input with `age=30` builds `tags: ["a", "b"]`
- [ ] the existing four binders keep their tests unchanged (`binding_test.bp`)

### Step 7 — Refinements and messages

`#[check("fn")]` and `#[check("fn", "fieldA,fieldB")]` on the type, `#[stopOnFirst]`,
`#[message("…")]`, `#[typeMessage("…")]`, `Schema.refine`, `Schema.parseWith(input, source)`.

**Acceptance:**
- [ ] `examples/refine-and-messages-example.bp` passes on both targets
- [ ] a `#[check]` naming a function that does not exist, or one with another signature, fails at
      the annotation's module with the function's name in the message
- [ ] the resolution order of `surface.md` § 5 is one test with six rows, each overriding the next

### Step 8 — Combinators and codecs

`Schema.map`, `schemas.tryMap`, `pipe`, `preprocess`, `custom`, `refineAsync`; `Codec<A, B>`,
`schemas.codec`, `invert`; `#[with]`, `#[map]`, `#[codec]`; `encode<T>`; `codecs.bp` with the
twelve recipes.

**Acceptance:**
- [ ] `examples/transform-and-codec-example.bp` passes on both targets
- [ ] for every recipe, `decode(encode(x)) == x` over five values, and `encode(decode(t)) == t`
      over five canonical texts
- [ ] `encode<T>` of a value that fails `validate<T>` is an `Error`, not a document

### Step 9 — Reflection, error views, metadata, JSON Schema

`Schema.fields()`, `.keys()`, `.options()`, `.isOptional()`; `report.flatten()`, `.tree()`,
`.pretty()`; `#[title]`, `#[describe]`, `#[example]`, `#[deprecated]`, `#[schemaId]`;
`spi.registerSchema`; `jsonSchemaOf<T>`, `inputJsonSchemaOf<T>`, `table.toDraft07`,
`table.toOpenApi30`, `table.withRefBase`, `spi.registeredJsonSchemas`.

**Acceptance:**
- [ ] `examples/error-views-example.bp` and `json-schema-example.bp` pass on both targets
- [ ] `jsonSchemaOf<T>` for the reference's § 8 examples is the reference's document, key order
      aside — eleven literals
- [ ] the emitted document validates against the 2020-12 meta-schema; the check is one node script
      under `test/tools/`, run by `test/json_schema_test.bp` on commonJS and skipped by nothing: on
      erlang the same literals are compared byte for byte instead
- [ ] `constraintsOf<T>` is unchanged for the thirteen existing markers (`table_test.bp`)

### Step 10 — Locales

`locales/` — `en` (the built-in table, moved), `ptBR`, `es`: one `fn() -> MessageSource` each.

**Acceptance:**
- [ ] every code of `builtInTemplate` has an entry in every shipped locale; a missing one fails
      `test/locales_test.bp` by name
- [ ] `setMessageSource(locales.ptBR())` changes the message of every code and of no placeholder

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in this front's worktree
- [ ] `../../zig-out/bin/botopink test --target erlang` and `--target commonJS` green in
      `libs/validation`
- [ ] `../../zig-out/bin/botopink format --check src test` clean
- [ ] `zig build test-libs`: rakun's two consumers of `#[validated]` still green — the name
      contract `validate<TypeName>` / `constraintsOf<TypeName>` did not move
- [ ] every file under `examples/` is a case of the suite — an example that does not compile is red
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Commit on `front/125-validation-zod`; landing is the maintainer's step

## Blast radius

- **The embedded source grows.** `libs/validation` is compiled into the compiler binary
  (`build.zig`'s `bundled_packages`). Today it is 1 356 lines of source; 58 more predicates,
  markers and templates several times that. Step 3 reports the binary's size before and after.
- **`#[validated]`'s contract does not move.** rakun's config binder builds `validate<TypeName>` by
  name (`decorators.bp:11-17`); every existing marker keeps its code, its message and its table row.
- **`Violation.field` changes meaning only for nested data**, which no consumer has today — a flat
  record's `field` is the field's name, as before.
- **Consumers do not change in this front.** The three `isHex` walks, the 39 hand-written
  `…Json(` functions and the route handlers that read fields from the query become candidates;
  each belongs to the front that owns its member.
- **`language-gaps.md` gains seven rows** (`surface.md` § Count), beside the eight that step 0's
  measurements filed (§ Mechanism — what the platform fixes about the shape). `No record ↔ Json derivation`
  leaves the table when step 2 lands: the derivation is a decorator over `decl.fields`, which the
  row assumed needed lg2-e.
- **Snapshots:** `libs/validation/test/` has no snapshot directory, and this front adds none — a
  JSON Schema is asserted as a literal.

## Decisions the maintainer owes

Continuing the track's letters ([`../README.md`](../README.md) § Decisions).

### 07-j · How much of Zod is the front

**Measured.** `surface.md`: 205 reference rows; 27 are already the language or the library, 151 are
buildable with the decorator and reflection surface that exists, 7 need a compiler row, 18 have no
meaning here.
**Options.** (a) the markers only — §§ 4.3, 4.4, 4.6 (step 3 alone); (b) steps 0–2
and 3: `parse<T>` for flat records plus the markers; (c) every step.
**Recommendation.** (c), landed in step order. (a) leaves the library without the function Zod is
named for; (b) leaves unions, coercion and codecs for the consumers to hand-write, which is the
state `language-gaps.md` already records as a cost.
**Blocks.** the front's size; nothing in steps 0–2.

### 07-n · Where `Schema<T>` lives

**Options.** (a) `libs/validation` (`schemas.bp`); (b) std, beside `json`.
**Recommendation.** (a). It reports through `ValidationReport` and messages through
`MessageSource`; in std it would either drag both along or report a second way.
**Blocks.** step 2.

## Notes

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

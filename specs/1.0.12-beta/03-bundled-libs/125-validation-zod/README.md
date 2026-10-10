# Front 125 — validation zod: Zod's feature set in botopink

**Priority:** high for the step 0–2 residue (`08-bpp/121` content collections and `08-bpp/127`
actions take the `#[validated]` type — decision 306); medium for the rest · **State:** partial: steps 0–3 done;
steps 4–12 landed in 306's shape but for the boxes that wait on `01-checker` steps 24 / 28, 134 step 4,
`@typeInfo(T).fields`, the `Decl.variants` gap and step 9's vendored validator (399, § Open)
**Depends on:** `01-compiler/01-checker` step 24 (decision 280, step 7) · decision 325 (07-j: every step, 306's shape). Written against decisions 144 (undeclared keys), 145 (emitted names),
183 (`07-m`: coercion, step 6), 257 (`07-n`: `Schema<T>` lives in `validation` — amended by 306: the
place stays, the value is private), 306–308
**Owns:** `repository/validation/src/**` · `repository/validation/test/**` · `repository/validation/AGENTS.md` ·
`repository/validation/botopink.json` — except `src/messages.bp`'s `interpolate`, moved to `i18n` by
`105-i18n` between two steps of this front, never during one (decision 189)
**Does not touch:** the compiler (`modules/**`) — a need is a row in
[`language-gaps.md`](../../language-gaps.md) and a nearest form · `libs/std/**` (97) · other shared
packages · consumer files in rakun, jhonstart, onze (a consumer imports a marker in its own front)

Feature map — all 211 reference rows with their box: [`surface.md`](./surface.md). Target code per
step: [`examples/`](./examples/).

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
- Step 0 residue — the last two platform facts are `platform_test.bp` cases: an `f32` (`1.5f`) is a
  double on both targets and round-trips unchanged; `url.parse` against WHATWG, one case per input
  where they differ (case kept, default port kept, `mailto:` read as one scheme, `[::1]` split at its
  first colon, four inputs WHATWG refuses answered); `#[url]` (step 3) and `#[float32]` rewritten to
  those facts (§ Mechanism, `surface.md`)
- Step 2 residue — `signup-schema-example.bp` and `nested-and-arrays-example.bp` are suite cases
  (`test/*_example_test.bp`, the example byte for byte but for the import lines); a four-level
  `Category` decodes and a bad leaf is reported at its full path; a self-reference 2 000 levels deep
  decodes on both targets, over a document built as a value and over its JSON text (std's
  `json.decode` reads by a loop since `fix-js-gaps`; its recursion overflowed node's stack between
  1 000 and 1 500 levels);
  `test/refusal_test.bp` runs `botopink check` over a fixture and asserts the unsupported field
  type's refusal, message and location; `schemas.bp` reads with std's `Json.items()` /
  `.members()` and the emitted decoder with `input.field("…") ?? Json.Null` — `itemsOf`,
  `membersOf`, `fieldOf` gone (the box `97-std-dedupe` step 2 waits on)
- Step 3 — 58 markers (8 string checks, 41 formats, 7 numeric, 2 date bounds) and the length
  markers on `Array`, `Dict`, `Set`: each a rule in the new `src/formats.bp` (walks and
  intersection-grammar regexes, no host cell), a `constraints.bp` predicate, a marker in
  `decorators.bp`, a built-in template and, with parameters, a `table.bp` row;
  `grep -c '@External' src/constraints.bp` is 0. `constraints_test.bp` holds three accepted and
  three refused inputs per string predicate (the reference's `"555-555-5555"`, `"2020-1-1"`,
  `"usd"`, `"DE89 3704 0044 0532"` among the refused) and the boundaries of the numeric, list,
  dict, set and date ones; `parity_test.bp` runs every predicate through one 62-row digest on both
  targets; `refusal_test.bp` has one row per marker of `markerNames()` (71, the count asserted) and
  15 argument refusals; `checks-and-formats-example.bp` is a suite case. Markers now check `?string`
  / `?i32` / `?i64` / `?f64` fields when present. Not added: the `checks.*` functions — 306 makes
  them private, and no module of them exists. `#[safeInt]`'s refusal is reachable on erlang only
  (commonJS cannot build an `i64` past ±(2^53 − 1)). Embedded source +78 203 bytes (88 411 → 166 614)
- Step 4 — `#[validated]` on a payload-less enum decodes the variant's name (`Fish.options()` the
  variants); `#[literal]` (`string`, `i32`, `bool`) and `#[oneOf("a,b")]` (73 markers); fields typed
  `A | B` (one `invalidUnion` naming each arm's first violation; absent is `required` unless an arm is
  `?T` / `Json`), `#(A, B, …)` (exact length, items at `at[i]`), `Dict<K, V>` (`K` text, `i32` or a
  `#[validated]` enum; `#[exhaustive]` needs every variant), `Set<T>` (`duplicate` at the second
  occurrence); `#[tag("status")]` over payload records named `<Enum><Variant>` (a record of the
  variant's own name is built as the variant — measured). `union2…5`, `xor2…5`, `both`, `tuple2…5`,
  `tupleRest`, `pairs`, `never`, `nil` not added — `n/a (306)`. `enums_and_unions_example_test.bp`,
  `collections_example_test.bp`
- Step 5 — `#[stripUnknown]`, `#[rest]` (`Dict<string, T>`, one), `#[present]`, `#[orElse(literal)]`,
  `#[orElseOf(f)]`, `#[fallback(literal)]`, `#[fallbackOf(f)]` (a value that does not decode or fails
  its checks); a literal not of the field's type is refused at the field.
  `object_policy_example_test.bp`; `derived-types-example.bp` rewritten to `Type`'s methods (not a
  suite case until `01-checker` step 28)
- Step 6 — `#[coerce]` (decision 183; `#[coerce] #[isoDatetime]` on an `i64` reads an instant),
  `#[stringbool]`, `#[trim]`, `#[lowercased]`, `#[uppercased]`, `#[normalized(form)]`,
  `#[normalizedUrl]`, `bindFloat`, `T.bind(pairs)` over `derived.formDocument` (a repeated name an
  array's items, an unchecked checkbox `false`, an undeclared name the unknown-key rule); the four
  binders' tests unchanged. `coercion_and_forms_example_test.bp`
- Step 7 — `#[message("…")]`, `#[typeMessage("…")]`, `#[stopOnFirst]`, the per-parse source
  `messages.underSource(source, { -> T.parse(doc) })`; the six levels of § 5's resolution order are
  `test/message_order_test.bp`. `refine_and_messages_example_test.bp` (all but the type-level
  `#[check]`)
- Step 8 — `T.encode` (runs `validate()` first) and `T.__json`, every field type decode reads;
  `#[preprocess(f)]`, `#[check(rule)]` on a field, `#[each("marker")]` (checks and transforms on
  items, at `field[i]`); `codecs.bp`, Zod's twelve recipes as decode / encode pairs, each an inverse
  over five values and five canonical texts (`codecs_test.bp`). `transform_and_codec_example_test.bp`
- Step 9 — `report.flatten()`, `.tree()`, `.pretty()`; `#[title]`, `#[describe]`, `#[example]`,
  `#[deprecated]`, `#[schemaId]` (`$id`), `#[jsonSchema]` (unrepresentable refused); `T.jsonSchema()`
  (2020-12, `$defs`, `{"$ref": "#"}` for the document's own type), `table.toDraft07`,
  `table.toOpenApi30`, `table.withRefBase`, `spi.registerSchema` / `registeredJsonSchemas`;
  `json_schema_test.bp` holds sixteen of § 8's documents and nodes (key order aside);
  `T.constraints()` unchanged (`table_test.bp`). `error_views_example_test.bp`,
  `json_schema_example_test.bp`
- Step 10 — `locales.en()` (the built-in table), `ptBR()`, `es()`: a template for every code of
  `messages.codes()` (82), each a different text with the same placeholders (`locales_test.bp`)
- Step 11 — `#[orElse(.Tuna)]` / `#[fallback(.Worm)]`: an enum field's default is its variant by
  reference (280 (2)'s declared shape `orElse<T>(decl: @Decl<T>, value: T)`)
- Step 12 — `#[schema]` deleted: `#[validated]` gives every type the members of 327 — `parse`,
  `parseAt`, `decode`, `bind`, `encode`, `jsonSchema` (an enum also `options`) — beside `validate()` /
  `constraints()`; `Schema<T>` and its combinators deleted; `schemas.bp` is `derived.bp`, the
  private machinery the members call (`import {derived} from "validation";` in a consumer, for the
  emitted code); `#[validated(transparent)]` (one field, read and written as that field; two fields
  refused); `#[with]` never added; every example rewritten (eleven are suite cases); `surface.md`
  re-sorted (209 rows: 136 have, 17 `n/a (306)`, 20 add with their blockers). Consumers: rakun core's
  `Duration` / `DataSize` and `typed_config_test.bp`'s nested records carry `#[validated]` (a
  `#[validated]` record's field types are schemas too), two rakun tests import `derived` / `Json`;
  `onze-content`'s `defineCollection` takes the type's `parse` (`{ d -> T.parse(d) }`) instead of a
  `Schema<T>` — rakun 375 / 0 (erlang), onze-content 714 / 0 (commonJS, erlang)

## Open

Decision 325 (07-j) fixed the scope: every step, in order. What is left of steps 4–12, with what it
waits on:

| Step | Box | Waits on |
|---|---|---|
| 4 | `#[tag]` on an enum whose variant has no payload record is a compile error at the annotation (today it fails where the emitted code names the record) | the **`Decl.variants`** gap row (payload fields not reflected) |
| 5 | `derived-types-example.bp` passes; `#[validated] pub val RecipePatch = Type.partial(Recipe);` decodes with every field optional, keeps `Recipe`'s markers, and is imported and constructed by a second module | `01-checker` step 28 (`Type`'s calls answered) · 134 step 4 (`pick` / `omit`, decision 267) |
| 7 | the type-level `#[check(rule, at: .field, message: "…", code: .Custom)]` and `#[check(message: "…")]` on the rule; a `#[check]` naming a missing function, a missing field (`.confrim`) or a rule of another signature fails at that argument; one on a rule outside the type's module refused | `01-checker` step 24 (280) |
| 8 | `#[map(f)]`, `#[tryMap(f)]`, `#[codec(decode: f, encode: g)]` — they read `f`'s parameter type | `01-checker` step 24 (280 (2)) |
| 9 | the emitted document validates against the 2020-12 meta-schema: Ajv's standalone 2020 build vendored under `test/tools/` (`check-schema.js`), run by `test/json_schema_test.bp` through `io.process.run("node", …)` on commonJS for every emitted document; its version and hash in `AGENTS.md`; tests only — never in `src/`, `files` or a consumer (399) | nothing — 399 answers it |
| 11 | `#[wireName("salmon")]` on each variant | the **`Decl.variants`** gap row (annotations of variants) |
| 12 | a located refusal for a field marker's function of the wrong signature (`#[preprocess]`, `#[check]`; `#[map]`, `#[tryMap]`, `#[codec]` with them) | `01-checker` step 24 |
| 12 | reflection reads the type — `@typeInfo(T).fields`, `@typeInfo(T).meta(Validated)` — and a library takes the type (`comptime source: type T`) | `@typeInfo(T).fields` (`typeinfo-unknown-member`, `01-checker`) · 298 |

Step 3 touches step 24 in one place: `#[gt]`, `#[lt]` and `#[multipleOf]` declare their bound
`comptime value: f64` and `#[validated]` gives it the field's type from the lexeme (`5` → `5.0` on an
`f64` field, a fraction refused on an integer one); under 280 (2) the bound is `@Decl<T>`'s `T` —
step 24's migration of the markers rewrites those three signatures, `#[orElse]` / `#[fallback]`'s
values (step 11) and `#[validated]`'s run-time `form` (a comptime parameter takes no default —
`language-gaps.md`).

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

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `--target commonJS`
green and `botopink format --check src test` clean in `repository/validation`
- [x] rakun's two `#[validated]` consumers still green — the name contract `validate()` /
      `constraints()` (decision 216) did not move (rakun core 375 / 0 on erlang, with the consumer
      patch); `zig build test-libs` itself is the cold gate's
- [ ] every file under `examples/` is a suite case — eleven of twelve; `derived-types-example.bp`
      waits on `01-checker` step 28

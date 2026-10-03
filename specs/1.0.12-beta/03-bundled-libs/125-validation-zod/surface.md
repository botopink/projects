# 125-validation-zod — surface: every Zod feature, and where it lands in botopink

The reference is the Zod 4 documentation, <https://zod.dev/> (Zod 4.x; the API pages under
<https://zod.dev/api>); this file walks it section by section, its § numbers following the
reference's sections in order (§§ 1–13). Every "the language has no …" claim below names the place
that says so in `repository/botopink-lang` (`docs.md`, `libs/std`, `libs/validation`). A row whose
step landed (steps 0–2) reads **have**.

## How to read it

Zod describes data with **runtime values** and infers the type from them. botopink describes data
with **type declarations** and derives the functions from them at compile time. So each Zod
feature lands in one of five boxes:

| Box | Meaning |
|---|---|
| **native** | The language or std already is the feature; nothing to build. The row names the spelling |
| **have** | `libs/validation` covers it today, under the spelling shown |
| **add · N** | This front adds it in step *N* of [`README.md`](./README.md) |
| **gap** | It needs a compiler change; the row names the nearest form that works today and the `language-gaps.md` row |
| **n/a** | It has no meaning on this platform; the reason is stated |

Two layers carry the additions, and a row names which:

- **derive** — a marker on a type or a field; `#[schema]` reads it and emits code (`decorators.bp`).
- **combinator** — a function of module `schemas` that answers a `Schema<T>` value, composed by
  hand (`schemas.array(schemas.text())`), and reachable from a derived type with `#[with("fn")]`.

## What the map stands on

A Zod feature "does not map" only when the language has nothing to map it to. Eight facts decide
most of the table, and each is easy to assume the other way:

| It is tempting to say | Measured |
|---|---|
| a statically typed language has no union at the value level | `A \| B` is a type, `x is T` narrows it — `docs.md:620-646` |
| … and no `any` | `unknown` holds any value and must be tested before use — `docs.md:622-626` |
| there is no tuple type | `#(A, B)`, labelled `#(x: A, y: B)` — `docs.md:400-414`, `:567` |
| there are no maps or sets to validate | `Dict<K, V>`, `Set<T>` — `libs/std/src/collections.bp:27`, `:246` |
| records are nominal, so `.extend` / `.pick` / `.omit` / `.partial` have no counterpart | `mergeRecords(A, B)`, `partial(T)`, `omit(T, "f")`, `pick(T, ["f"])` are comptime type functions — `comptime/infer.zig:6439`, `libs/std/AGENTS.md` |
| `.default(v)` needs new machinery | a record field declares its default (`type Port(number: i32 = 80, host: string)`) — `docs.md:1320-1356` |
| `.parse()` is `validate<TypeName>()`, which exists | `validate<TypeName>(v: TypeName)` takes a value that is **already typed** (`decorators.bp:199-207`). Zod's `parse` takes `unknown`. The library has no function from untrusted data to a typed value; that function is the front |
| `z.coerce.date()` is `bindEpochMillis` | `bindEpochMillis` reads integer text (`binding.bp:178-187`); `new Date(value)` reads ISO text too. `clock.parseIso8601` exists (`io/clock.bp:141`) and is the missing half |

---

## § 3 · Basic usage

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.object({…})` defining a schema | `#[schema] pub type Player(username: string, xp: i32)` | have | derive. The declaration is the schema and the inferred type at once |
| `Player.parse(input)` — throws | `try parsePlayer(input)` in a `@Result` function | have | emitted `pub fn parsePlayer(input: Json) -> @Result<Player, ValidationReport>`; `try` propagates the report (`docs.md:1467-1529`) |
| `Player.safeParse(input)` | `parsePlayer(input)` — the `@Result` itself, read with `case` or `try … catch` | have | one function for both: only `@Result` fails (decisions 120 · 121) |
| `Player.parseAsync` / `safeParseAsync` | `-> @Task<@Result<T, ValidationReport>>` for a schema with an async check | add · 8 | combinator `schemas.refineAsync`; a derived type stays synchronous |
| `Player.validate(input)` — boolean, no error built | `schemaOfPlayer().accepts(input)` | have | runs the same decoder with a counting sink instead of a list |
| `ZodError.issues` — `code`, `path`, `message`, `expected` | `ValidationReport.violations` — `field` (the rendered path), `code`, `message`, `invalidValue` | have | `Violation` exists (`report.bp:28-33`); `field` is the rendered path (`address.street`, `tags[1]`); the structural codes are step 1's |
| `z.infer<typeof Player>` | the type is `Player` | native | there is no second declaration to infer from |
| `z.input<>` / `z.output<>` | `Schema<T>` has one type; a transforming schema is `Schema<Out>` built from a `Schema<In>` | add · 8 | `schemas.map(inner, f)`; the input type is the argument of the inner schema |

## § 4.1 · Primitives and coercion

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.string()` | field `string` · `schemas.text()` | have | accepts `Json.Str` only |
| `z.number()` | field `f64` · `schemas.float()` | have | `Json.Num`; `NaN` / `Infinity` never arrive — `json.decode` refuses them (`json.bp:99-100`) |
| `z.boolean()` | field `bool` · `schemas.boolean()` | have | |
| `z.bigint()` | field `i64` · `schemas.long()` | have | a JSON number is an `f64`: accepted when integral and within ±2^53; beyond that the wire form is digit text under `#[coerce]`. There is no arbitrary-precision integer — **n/a** past `i64` |
| `z.symbol()` | — | n/a | JavaScript-only value kind |
| `z.undefined()` · `z.void()` | — | n/a | one absent value, `null`, typed `?T` (`docs.md:1000-1003`) |
| `z.null()` | `schemas.nil()` | add · 4 | accepts `Json.Null` only; used inside unions |
| `z.coerce.string()` | `#[coerce]` on a `string` field | add · 6 | `Num` and `Bool` are rendered; `null` is refused (Zod turns it into `"null"`) — decision `07-m` |
| `z.coerce.number()` | `#[coerce]` on `i32` / `i64` / `f64` · `bindInt` (have) · `bindFloat` | add · 6 | reads `Json.Str` with the grammar `isIntegerText` already defines (`binding.bp:105-119`), extended with a fraction and an exponent |
| `z.coerce.boolean()` | `#[coerce]` on `bool` · `bindBool` (have) | have · add · 6 | **not** Zod's truthiness: `"false"` is `false` here. The accepted set is `z.stringbool`'s, below — decision `07-m` |
| `z.coerce.bigint()` | `#[coerce]` on `i64` | add · 6 | digit text through `rawToI64` (`binding.bp:144-146`) |
| `z.coerce.date()` | `#[coerce] #[isoDatetime]` on an `i64` field (epoch milliseconds) | add · 6 | `clock.parseIso8601` (`io/clock.bp:141`); integer text stays `bindEpochMillis` |
| `z.coerce.number<number>()` — typed input | — | n/a | the input is always `Json` |

## § 4.2 · Literals

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.literal("tuna")` | `#[literal("tuna")]` on a `string` field · `schemas.literal("tuna")` | add · 4 | also `i32` and `bool` literals |
| `z.literal(["red","green","blue"])` | a payload-less enum (`type Color { Red, Green, Blue }`) as the field type, or `#[oneOf("red,green,blue")]` on a `string` | add · 4 | the enum is the typed form; `oneOf` takes one comma-joined argument because a decorator argument is a raw lexeme (`language-gaps.md` lg2-i) |
| `colors.values` | `schemaOfColor().options()` | add · 4 | `Array<string>`, declaration order |

## § 4.3 · Strings — checks and transforms

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `.max(n)` | `#[maxLength(n)]` · `checks.maxLength(n)` | add · 3 | `#[sizeBetween(min, max)]` stays (have) |
| `.min(n)` | `#[minLength(n)]` | add · 3 | |
| `.length(n)` | `#[length(n)]` | add · 3 | |
| `.nonempty()` | `#[notEmpty]` | have | `decorators.bp:86-94` |
| `.regex(re)` | `#[pattern("…")]` | have | the intersection grammar of `constraints.bp:212-219` |
| `.startsWith(s)` · `.endsWith(s)` · `.includes(s)` | `#[startsWith("…")]` · `#[endsWith("…")]` · `#[includes("…")]` | add · 3 | plain `string` methods |
| `.uppercase()` · `.lowercase()` | `#[uppercase]` · `#[lowercase]` | add · 3 | a check, not a transform: fails when the value has a letter of the other case |
| length in Unicode code points | step 0 measures `"é".length()` and `"😀".length()` on both targets | add · 0 | `indexOf` already disagrees with `length` on erlang (`language-gaps.md`, "`string.indexOf` counts bytes"); a length marker is only as portable as `length()` is |
| `.trim()` | `#[trim]` | add · 6 | transform: applied by `parse<T>` before the checks run |
| `.toLowerCase()` · `.toUpperCase()` | `#[lowercased]` · `#[uppercased]` | add · 6 | named apart from the checks above on purpose |
| `.normalize()` | `#[normalized("NFC")]` | add · 6 | `unicode.normalize` (`unicode.bp:79`) |

## § 4.4 · String formats

Every format is one predicate in `constraints.bp`, one marker, one combinator check and one
built-in message. "walk" means a plain-botopink scan with no regex; "regex" means the intersection
grammar. None reaches a host cell.

| Zod | botopink | Box | How |
|---|---|---|---|
| `z.email()` | `#[email]` | have | regex (`constraints.bp:217-219`) |
| `z.email({ pattern })` — html5, rfc5322, unicode | `#[emailHtml5]` · `#[emailRfc5322]` · `#[emailUnicode]` | add · 3 | regex each; the default stays the one shipped |
| `z.uuid()` | `#[uuid]` | add · 3 | regex; RFC 9562 version and variant nibbles |
| `z.uuid({ version })` · `z.uuidv4()` · `z.uuidv6()` · `z.uuidv7()` | `#[uuidV(4)]` (1–8) | add · 3 | the version nibble compared |
| `z.guid()` | `#[guid]` | add · 3 | the 8-4-4-4-12 shape, no nibble check |
| `z.url()` | `#[url]` | add · 3 | `url.parse` (`url.bp:46`) plus a scheme-and-host requirement; step 0 lists where it differs from WHATWG |
| `z.url({ hostname, protocol })` | `#[urlHost("…")]` · `#[urlProtocol("…")]` | add · 3 | patterns over the parsed parts |
| `z.url({ normalize })` | `#[normalizedUrl]` | add · 6 | transform: `url.serialize(url.parse(v))` |
| `z.httpUrl()` | `#[httpUrl]` | add · 3 | `http` / `https` and a dotted host |
| `z.hostname()` | `#[hostname]` | add · 3 | walk, RFC 1123 labels |
| `z.e164()` | `#[e164]` | add · 3 | regex |
| `z.emoji()` | `#[emoji]` | add · 3 | walk over `unicode.codepoints` (`unicode.bp:55`) against the emoji ranges; no regex class for it in the intersection grammar |
| `z.base64()` | `#[base64]` | add · 3 | `encoding.base64Decode` answers `@Result` (`encoding.bp:35`) |
| `z.base64url()` | `#[base64url]` | add · 3 | `encoding.base64UrlDecode` (`encoding.bp:49`) |
| `z.hex()` | `#[hex]` | add · 3 | walk — and the three private `isHex` copies (`jhonstart-emilia/src/root.bp:39`, `rakun-web/src/static.bp:271`, `rakun-actuator-api/src/span.bp:149`) become consumers, by their own fronts |
| `z.jwt()` · `z.jwt({ alg })` | `#[jwt]` · `#[jwtAlg("HS256")]` | add · 3 | three base64url segments; the header decoded with `json.decode` for `alg`. Shape only — verifying a signature is not validation |
| `z.nanoid()` · `z.cuid()` · `z.cuid2()` · `z.ulid()` | `#[nanoid]` · `#[cuid]` · `#[cuid2]` · `#[ulid]` | add · 3 | regex each |
| `z.ipv4()` · `z.ipv6()` | `#[ipv4]` · `#[ipv6]` | add · 3 | walk (octet range; `::` compression) |
| `z.mac()` · `z.mac({ delimiter })` | `#[mac]` · `#[macDelimiter("-")]` | add · 3 | regex |
| `z.cidrv4()` · `z.cidrv6()` | `#[cidrv4]` · `#[cidrv6]` | add · 3 | the address walk plus a prefix range |
| `z.creditCard()` | `#[creditCard]` | add · 3 | Luhn walk; single spaces or single hyphens between groups, as Zod accepts |
| `z.currencyCode()` | `#[currencyCode]` | add · 3 | the ISO 4217 table as a comma-joined literal, uppercase only |
| `z.iban()` | `#[iban]` | add · 3 | mod-97 over digit chunks — nine digits at a time, so every product stays inside `i32` |
| `z.hash("sha256", { enc })` | `#[hash("sha256")]` · `#[hashEnc("sha256", "base64url")]` | add · 3 | the length table of § "Tamanhos Esperados e Padding" and the encoding's alphabet |
| `z.iso.date()` | `#[isoDate]` | add · 3 | walk: `YYYY-MM-DD` and a calendar check |
| `z.iso.time()` · precision | `#[isoTime]` · `#[isoTimePrecision(n)]` | add · 3 | walk |
| `z.iso.datetime()` · `offset` · `local` · `precision` | `#[isoDatetime]` · `#[isoDatetimeOffset]` · `#[isoDatetimeLocal]` · `#[isoDatetimePrecision(n)]` | add · 3 | walk. `Z` only by default, as in Zod |
| `z.iso.duration()` | `#[isoDuration]` | add · 3 | walk |
| `z.stringFormat(name, fn \| regex)` | `spi.registerConstraint(name, code, check)` + `#[constraint("name")]` | have | `spi.bp:78-85`, `decorators.bp:326-338` |
| `z.regexes.*` | `constraints.emailPattern()` and one `pub fn <name>Pattern()` per regex format | add · 3 | `emailPattern` is public today (`constraints.bp:217`) |

## § 4.5 · Template literals

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.templateLiteral([...])` | `#[pattern("…")]` | have | the type-level template string has no botopink spelling; the runtime check is a regex — **n/a** as a type |

## §§ 4.6–4.8 · Numbers, integers, bigints

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `.gt(n)` · `.lt(n)` | `#[gt(n)]` · `#[lt(n)]` | add · 3 | per width, as `minValue` is (`constraints.bp:114-160`) |
| `.gte(n)` / `.min(n)` · `.lte(n)` / `.max(n)` | `#[minValue(n)]` · `#[maxValue(n)]` | have | `i32` and `f64`; refused on `i64` (an integer literal does not widen — `validation/AGENTS.md` § Language notes) |
| `.positive()` · `.nonnegative()` | `#[positive]` · `#[positiveOrZero]` | have | `i32`, `i64`, `f64` |
| `.negative()` · `.nonpositive()` | `#[negative]` · `#[negativeOrZero]` | add · 3 | named after the pair already shipped |
| `.multipleOf(n)` / `.step(n)` | `#[multipleOf(n)]` | add · 3 | `i32` by `%`; `f64` by the scaled-integer test Zod uses |
| `z.int()` — safe-integer range | field `i64` with `#[safeInt]` | add · 3 | ±(2^53 − 1) |
| `z.int32()` | field `i32` | have | the decoder refuses a fraction and a value outside the range — a structural `invalidType`, not a marker |
| `z.int64()` | field `i64` | have | as `z.bigint()` above |
| `z.float32()` · `z.float64()` | field `f64`; `#[float32]` for the single-precision range | add · 3 | `f32` exists as a primitive (`docs.md:343`); step 0 measures whether it survives both targets |
| `z.nan()` | — | n/a | a JSON document cannot carry one |
| `z.bigint().gt(5n)` … | the same markers on `i64` | gap | an `i64` bound cannot be written (the literal is `i32`). Nearest: `#[gt]` on `i64` is refused with `minValue`'s message; `#[positive]` / `#[negative]` work, because `0` widens in a comparison |

## §§ 4.9–4.10 · Booleans and dates

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.boolean()` | field `bool` | have | |
| `z.date()` | — | n/a | there is no date type; an instant is epoch milliseconds (`i64`) and a calendar date is `clock.Civil` (`io/clock.bp:117`) |
| `z.date().min(d)` · `.max(d)` | `#[pastDate]` · `#[futureDate]` (have) · `#[afterIso("…")]` · `#[beforeIso("…")]` | have · add · 3 | bounds written as ISO text, parsed once at validation |

## §§ 4.11–4.12 · Enums and stringbools

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.enum(["Salmon","Tuna"])` | `#[schema] pub type Fish { Salmon, Tuna, Trout }` | add · 4 | derive over `decl.variants` (`builtins.d.bp:592`): emits `parseFish(Json) -> @Result<Fish, …>` matching the variant **name** |
| `z.enum(Fish)` over a TS enum / object | `#[wire("salmon")]` on a variant for a wire name that differs | gap | variants are reflected as names only, with no annotations. Nearest: `#[wireNames("Salmon=salmon,Tuna=tuna")]` on the type |
| `FishEnum.enum` | the type itself (`Fish.Salmon`) | native | |
| `.exclude([...])` · `.extract([...])` | a section of the enum (`type Token { Color { Red, Gray }, Bold }` — `Token.Color` is a type) | native | `docs.md:441-467`; a section is declared, not computed |
| `z.stringbool()` | `#[stringbool]` on a `bool` field · `schemas.stringbool()` | add · 6 | `true 1 yes on y enabled` / `false 0 no off n disabled`, case-insensitive |
| `z.stringbool({ truthy, falsy, case })` | `schemas.stringboolOf(truthy, falsy, caseSensitive)` | add · 6 | combinator only |

## §§ 4.13–4.16 · Optional, nullable, nullish, unknown

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `.optional()` · `.nullable()` · `.nullish()` | field `?T` | have | one absent value: a missing key and a `null` both decode to `null` |
| `.exactOptional()` | `#[present]` on a `?T` field — the key may be absent, but `null` is refused | add · 5 | |
| `.unwrap()` | — | n/a | no schema value to unwrap; the type says it |
| `.nonoptional()` | field `T` | native | |
| `z.any()` · `z.unknown()` | field `Json` | have | the decoded tree is passed through; `unknown` is the language's own word for it but a `Json` can be walked |
| `z.never()` | `schemas.never()` | add · 4 | always a violation; used as a union arm or a catch-all |

## §§ 4.17–4.18 · Objects

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.object({…})` — strips unknown keys | `#[schema] #[stripUnknown] pub type …` | add · 5 | **not the default** — decision 144 |
| `z.strictObject({…})` | `#[schema] pub type …` | add · 5 | the default: an unknown key is a violation coded `unrecognizedKey` |
| `z.looseObject({…})` | a field `#[rest] extra: Dict<string, Json>` | add · 5 | the unknown members are kept, in document order |
| `.catchall(schema)` | `#[rest] extra: Dict<string, T>` | add · 5 | each unknown member decoded as `T` |
| `.shape` | `schemaOfDog().fields()` | add · 9 | `Array<FieldInfo>` — name, type name, markers; the same rows `constraintsOf<T>` writes |
| `.keyof()` | `schemaOfDog().keys()` | add · 9 | `Array<string>` |
| `.extend({…})` | `mergeRecords(Dog, Extra)` for the type; `#[extending("Dog")]` on a new record for its schema | gap | `mergeRecords` answers an anonymous record type a decorator cannot annotate. Nearest: declare the wider record and mark it `#[schema]`; `#[extending]` only checks that every field of `Dog` is repeated |
| `.safeExtend({…})` | the same check, always | add · 5 | `#[extending]` refuses a field retyped incompatibly |
| `.pick({…})` · `.omit({…})` | `#[schema] #[pick("JustTitle", "title")]` — the decorator **emits** the narrower record and its schema | add · 5 | `@emit` writes types today (`rakun-data/src/orm/entity.bp:183`) |
| `.partial()` · `.partial({ k: true })` | `#[partial("RecipePatch")]` — emits `RecipePatch` with every field `?T` | add · 5 | |
| `.exactPartial()` | `#[partial]` with `#[present]` carried over | add · 5 | |
| `.required()` | `#[required("RecipeFull")]` | add · 5 | emits the record with no `?` |
| `z.deepPartial()` | — | gap | a decorator sees one declaration (`language-gaps.md` lg2-k); the nested types' partials must each be marked |
| symbol keys | — | n/a | |
| recursive objects (`get subcategories()`) | a field typed with the record itself | have | `parseCategory` calls itself by name; no getter trick is needed |
| mutually recursive objects | two `#[schema]` records naming each other | have | by the name contract `parse<TypeName>` |

## §§ 4.19–4.20 · Arrays and tuples

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.array(T)` | field `Array<T>` / `T[]` | have | each item decoded with the path `field[i]` |
| `.nonempty()` | `#[notEmpty]` | have | `vNotEmptyList` |
| `.min(n)` · `.max(n)` · `.length(n)` | `#[minLength(n)]` · `#[maxLength(n)]` · `#[length(n)]` on an array field | add · 3 | `#[sizeBetween]` stays |
| checks on the items (`z.array(z.email())`) | `#[with("emails")]` naming `fn emails() -> Schema<Array<string>>` | add · 8 | a marker is a raw lexeme and cannot nest (lg2-i) |
| `.unwrap()` | — | n/a | |
| `z.tuple([A, B, C])` | field `#(A, B, C)` | add · 4 | a JSON array of exactly that length |
| `z.tuple([A], rest)` | `schemas.tupleRest(…)` | add · 4 | combinator; answers `#(A, Array<R>)` |
| `.partial()` on a tuple | a tuple of `?T` | native | |

## §§ 4.21–4.24 · Unions and intersections

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.union([A, B])` | field `A \| B` · `schemas.union2(a, b)` (to `union5`) | add · 4 | arms tried in declaration order; all fail → one `invalidUnion` violation carrying each arm's first violation |
| `.options` | `schemaOf….options()` | add · 9 | |
| `z.xor([A, B])` | `schemas.xor2(a, b)` | add · 4 | exactly one arm |
| `z.discriminatedUnion("status", […])` | `#[schema] #[tag("status")] pub type Result { Success(data: string), Failed(error: string) }` | gap | `Decl.variants` carries names, not payload fields (`builtins.d.bp:584-592`). Nearest, in this front: each variant's payload is a `#[schema]` record of the same name, and the enum's decoder dispatches on the tag to `parse<Variant>` |
| `z.getDiscriminatedOption` | `schemaOfResult().option("success")` | add · 9 | |
| nested discriminated unions | an enum whose variant payload is another tagged enum | add · 4 | by the name contract |
| `z.intersection(A, B)` | `schemas.both(a, b)` answering `#(A, B)`; for records, a record with both field sets | add · 4 | an intersection type has no spelling; the pair is the honest answer |

## §§ 4.25–4.27 · Records, maps, sets

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.record(z.string(), V)` | field `Dict<string, V>` | add · 4 | a JSON object; each member `field.key` |
| `z.record(Keys, V)` — enum keys, exhaustive | field `Dict<Fish, V>` with `#[exhaustive]` | add · 4 | every variant must be present |
| `z.partialRecord` | `Dict<Fish, V>` without the marker | add · 4 | |
| `z.looseRecord` | `#[rest]` beside declared fields | add · 5 | above |
| numeric keys | `Dict<i32, V>` | add · 4 | the key text through the integer grammar |
| `z.map(K, V)` | `Dict<K, V>` decoded from an array of pairs | add · 4 | JSON has no map; the wire form is `[[k, v], …]` |
| `.min` / `.max` / `.size` / `.nonempty` on maps and sets | the length markers | add · 3 | `Dict.size()`, `Set.size()` |
| `z.set(T)` | field `Set<T>` | add · 4 | a JSON array; a repeated item is a violation coded `duplicate`, not silently folded |

## §§ 4.28–4.30 · Files, promises, instanceof

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.file()` · `.min` · `.max` · `.mime` | — | gap | no byte type (`language-gaps.md` lg2-a); a multipart body is refused with 415 today. Nearest: validate the upload's declared `name`, `size` and `type` as a record |
| `z.promise()` | — | n/a | deprecated in Zod; a `@Task` is awaited before it is parsed |
| `z.instanceof(Class)` | `x is T` | native | `docs.md:625-626`; a host class has no botopink type |
| `z.property(k, schema)` · `z.properties({…})` | `schemas.field("status", …)` over a `Json` | add · 8 | combinator |

## §§ 4.31–4.33 · Refinements, pipes, transforms

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `.refine(fn, { error })` | field: `#[constraint("name")]` (have) · type: `#[check("fnName")]` naming `fn(v: T) -> Array<Violation>` · `schema.refine(pred, code, message)` | have · add · 7 | the type-level form is what cross-field rules need |
| `.refine(…, { path })` | the function answers the `Violation` with its own `field` | add · 7 | |
| `.refine(…, { abort: true })` | `#[stopOnFirst]` on the field | add · 7 | the default stays "every check runs" (`constraints.bp:12-14`) |
| `.refine(…, { when })` | the type-level check runs only when the report so far is empty for the fields it names: `#[check("passwordsMatch", "password,confirm")]` | add · 7 | |
| `.refine(async …)` | `schemas.refineAsync` | add · 8 | |
| `.superRefine((val, ctx) => ctx.addIssue(…))` | the same `#[check]` — it answers any number of violations | add · 7 | |
| `.check(ctx => ctx.issues.push(…))` | the same | add · 7 | one API; there is no slower one to bypass |
| `.pipe(schema)` | `schemas.pipe(a, b)` | add · 8 | |
| `z.transform(fn)` · `.transform(fn)` | `schemas.map(inner, f)` · field marker `#[map("fnName")]` | add · 8 | the field's declared type is the output type |
| transform that fails (`ctx.issues.push`, `z.NEVER`) | `schemas.tryMap(inner, f)` with `f: fn(a: A) -> @Result<B, string>` | add · 8 | the `Error` text is the message, coded `custom` |
| `z.preprocess(fn, schema)` | `schemas.preprocess(f, inner)` with `f: fn(j: Json) -> Json` | add · 8 | |
| `.overwrite(fn)` | the transform markers of § 4.3, and `#[map]` when the type does not change | add · 6 | |

## §§ 4.34–4.38 · Defaults, catch, brands, readonly

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `.default(v)` | `#[orElse("…")]` on the field | gap | the language's own form is the field default (`count: i32 = 0`), but `Field` reflects no default (`builtins.d.bp:568-572`), so the emitter cannot leave the label out. Nearest: `#[orElse]` writes the literal; when reflection grows the default, the marker becomes redundant |
| `.default(fn)` | `#[orElseOf("fnName")]` | add · 5 | called per parse |
| `.prefault(v)` | `#[orElse]` placed on a field with transforms — the literal is decoded and transformed like an input | add · 6 | one marker; "parsed, not short-circuited" is the only behaviour |
| `.catch(v)` · `.catch(fn)` | `#[fallback("…")]` · `#[fallbackOf("fnName")]` | add · 5 | on a decode or check failure the field takes the value and **no** violation is recorded; refused on a field whose type has no literal |
| `.brand<"Cat">()` | two record types | native | records are nominal: `Cat(name: string)` is not `Dog(name: string)` |
| brand direction | — | n/a | |
| `.readonly()` | — | native | a record is immutable (`docs.md:358-368`) |

## §§ 4.39–4.43 · JSON, functions, custom, apply, existing types

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.json()` | field `Json` | have | |
| `z.function({ input, output })` · `.implement` | — | n/a | a function's parameters are typed by its signature; wrapping one in a runtime check is `parse<Args>` at the boundary that calls it |
| `z.custom<T>(fn)` | `schemas.custom(f)` with `f: fn(j: Json) -> @Result<T, string>` | add · 8 | |
| `.apply(fn)` | a function over `Schema<T>` | native | schemas are values; composing them is a call |
| `z.toZod<Player>()` | — | native | the schema is derived from `Player`; it cannot drift |

## § 5 · Customising errors

| Zod | botopink | Box | Notes |
|---|---|---|---|
| check-level message (`.min(5, "Too short!")`) | `#[message("…")]` after the marker it restates | add · 7 | one more marker rather than a second argument on every marker, because a marker's arity is fixed |
| schema-level message (`z.string("Not a string!")`) | `#[typeMessage("…")]` on the field | add · 7 | restates `invalidType` |
| error map as a function | `MessageSource(locale, template)` | have | `messages.bp:35-38` |
| `iss.code` · `iss.input` · `iss.path` · `iss.minimum` … | `{field}` `{value}` and the marker's own parameters, by name | have | `messages.bp:96-114` |
| per-parse error map (`.parse(x, { error })`) | `schemaOfPlayer().parseWith(input, source)` | add · 7 | a `MessageSource` for one call, under the field-level messages |
| `reportInput: true` | `Violation.invalidValue` is always carried; `toJson` never writes it | have | `report.bp:81-93` — the reflected-input rule |
| `z.config({ customError })` | `setMessageSource(source)` | have | `messages.bp:55-57` |
| `z.config({ localeError })` — `z.config(en())` | `setMessageSource(locales.ptBR())` | add · 10 | one table module per locale under `locales/`; `en` is `builtInTemplate` |
| `z.config({ jitless })` · `memoizer` · `postProcessor` | — | n/a | no runtime code generation exists to disable |
| resolution order (check → schema → per-parse → global → locale → fallback) | `#[message]` → `#[typeMessage]` → `parseWith`'s source → `setMessageSource` (locale key, then bare key) → `builtInTemplate` | have · add · 7 | steps 4–6 are `templateFor` today (`messages.bp:82-91`) |
| 58 shipped locales | `en`, `ptBR`, `es` shipped; the rest are one file each | add · 10 | a locale is data, and `105-i18n` owns locale negotiation |

## § 6 · Formatting errors

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.treeifyError()` | `report.tree()` → `ReportTree(errors, properties, items)` | add · 9 | built from the path in `field` |
| `z.prettifyError()` | `report.pretty()` | add · 9 | `✖ <message>` / `  → at <path>`, byte-identical on both targets |
| `z.flattenError()` | `report.flatten()` → `Flat(formErrors, fieldErrors)` | add · 9 | keyed by the first path segment |
| — | `report.toJson()` · `report.toProblemDetail()` | have | RFC 9457 (`report.bp:51-69`) |

## § 7 · Metadata and registries

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `.meta({ title, description, examples, deprecated })` | `#[title("…")]` · `#[describe("…")]` · `#[example("…")]` · `#[deprecated]` on a type or a field | add · 9 | reach `fields()` and the JSON Schema |
| `.describe("…")` | `#[describe("…")]` | add · 9 | |
| `z.registry()` · `.register()` | `spi.registerSchema(id, schema)` · `spi.schemaNamed(id)` | add · 9 | the host table `spi.bp` already keeps for constraints (`spi.bp:45-74`) |
| `z.globalRegistry` with `id` | `#[schemaId("User")]`; the default id is the type's name | add · 9 | |
| typed registries (`z.registry<Meta, ZodString>()`) | — | n/a | one metadata shape |

## § 8 · JSON Schema

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.toJSONSchema(schema)` | `jsonSchemaOf<TypeName>() -> string` | add · 9 | emitted beside `constraintsOf<TypeName>` (`decorators.bp:208-216`), which stays as the compact table |
| `target` (draft-04 · 07 · 2020-12 · openapi-3.0) | `jsonSchemaOf<TypeName>()` is 2020-12; `table.toDraft07(…)` · `table.toOpenApi30(…)` rewrite it | add · 9 | |
| `metadata` | the markers of § 7 | add · 9 | |
| `unrepresentable` | a field the JSON Schema cannot say (`#[map]`, `#[check]`) is a **compile error** under `#[jsonSchema]`, and `{}` without it | add · 9 | decision 67: no silent `any` |
| `cycles: "ref"` · `reused: "ref"` | a field typed with a `#[schema]` record is `{"$ref": "#/$defs/<Name>"}` always | add · 9 | one form; a recursive type needs it and a shared one is shorter with it |
| `io: "input" \| "output"` | `inputJsonSchemaOf<TypeName>()` where a transform changes a field's wire type | add · 9 | |
| `uri` | `table.withRefBase(json, "https://…/")` | add · 9 | |
| `override` | — | n/a | the document is a string the caller may rewrite |
| format mapping (`email` → `format: "email"`, `base64` → `contentEncoding`, the rest → `pattern`) | the same table, from the marker code | add · 9 | § 8.3's rows verbatim |
| `additionalProperties: false` | written unless the type carries `#[stripUnknown]` or a `#[rest]` field | add · 9 | |
| `z.fromJSONSchema()` | — | n/a | a schema is a type declaration; generating declarations from a document is a CLI generator, not a library call — out of this front |
| `z.toJSONSchema(z.globalRegistry)` | `spi.registeredJsonSchemas()` | add · 9 | `{"schemas": {…}}` over the registry |

## § 9 · Codecs

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.codec(In, Out, { decode, encode })` | `schemas.codec(inner, decode, encode)` → `Codec<A, B>` | add · 8 | |
| `.decode()` · `.encode()` | `parse<TypeName>` · `encode<TypeName>(v: TypeName) -> Json` | add · 8 | `encode` is emitted by `#[schema]` for every type whose fields all encode |
| `.safeDecode` · `.decodeAsync` · `.encodeAsync` | the `@Result` / `@Task<@Result>` returns | add · 8 | |
| `z.invertCodec` | `schemas.invert(c)` | add · 8 | |
| composability (codecs inside objects and arrays) | a field with `#[codec("fnName")]` | add · 8 | |
| refinements run in both directions | `encode<TypeName>` runs `validate<TypeName>` first and answers `@Result` | add · 8 | |
| the recipe list — `stringToNumber`, `stringToInt`, `stringToBigInt`, `isoDatetimeToDate`, `epochSecondsToDate`, `epochMillisToDate`, `jsonCodec`, `base64ToBytes`, `hexToBytes`, `stringToURL`, `stringToHttpURL`, `uriComponent`, `stringToBoolean` | `codecs.textToInt` · `textToLong` · `textToFloat` · `isoToMillis` · `secondsToMillis` · `jsonText` · `base64Text` · `base64urlText` · `hexText` · `textToUrl` · `uriComponent` · `textToBool` | add · 8 | `utf8ToBytes` / `bytesToUtf8` are **gap** (lg2-a) |

## § 10 · AOT compilation

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.compile(schema)` — a flat, loop-free validator generated ahead of time | `#[schema]` | native | this is the only mode a derived schema has: the decoder is emitted at compile time as straight-line botopink |
| `import "zod/compile"` | — | n/a | |
| unsupported constructs fall back silently | — | n/a | nothing falls back; a combinator schema is ordinary code |
| `strict: true` | — | n/a | |
| CSP / `jitless` | — | n/a | no `new Function` on either target |

## §§ 11–13 · Ecosystem, library authors, packages

| Zod | botopink | Box | Notes |
|---|---|---|---|
| Standard Schema — "accept any schema" | a parameter typed `Schema<T>` | have | what `08-bpp/121` (collections) and `08-bpp/127` (actions) take |
| tRPC-style typed endpoints, form libraries | `08-bpp/127-bpp-actions` | — | the consumer, not this front |
| Zod → OpenAPI | `table.toOpenApi30` | add · 9 | |
| mock-data generators | — | — | not in the reference's core; no row |
| Zod Classic (methods) vs Zod Mini (functions) | one API: `Schema<T>` methods for the wrappers (`.optional()`, `.array()`, `.refine(…)`, `.map(…)`), `checks.*` functions for the checks | have · add · 8 | a check is typed by what it checks (`Check<string>`), so `schemas.int().check(checks.email())` does not compile |
| `mySchema.isOptional()` · `.isNullable()` | `schema.isOptional()` | add · 9 | |
| `mySchema.clone(def)` · `_zod.def` · `_zod.run` | `schema.fields()` / `.options()` for reflection; no internals | add · 9 | |
| `z.$ZodType` hierarchy, v3/v4 dual support, peer dependencies | — | n/a | one bundled version, shipped with the compiler |

---

## Count

211 rows, counted by the first word of the Box column (a row that is partly shipped counts for
what it already is), after steps 0–2:

| Box | Rows |
|---|---|
| native | 11 |
| have | 37 |
| add (this front) | 134 |
| gap (nearest form shipped, row filed) | 7 |
| n/a | 20 |
| consumer or out of the reference's core (`—`) | 2 |

The seven gaps: `i64` bounds, wire names on variants, payload fields of variants, `.extend` on an
anonymous record, `z.deepPartial`, `z.file`, field defaults in reflection — and the byte codecs
inside the § 9 recipe row, which share `z.file`'s cause. Each has a row in
[`../../language-gaps.md`](../../language-gaps.md) and a nearest form in the table above; none
blocks a step.

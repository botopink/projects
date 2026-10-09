# 125-validation-zod — surface: every Zod feature, and where it lands in botopink

Reference: Zod 4 documentation, <https://zod.dev/> (Zod 4.x; API pages under <https://zod.dev/api>),
walked section by section, § numbers following the reference (§§ 1–13). Every "the language has no …"
claim names its place in `repository/botopink-lang` (`docs.md`, `libs/std`, `libs/validation`). Rows
whose step landed (steps 0–2) read **have**.

## How to read it

Zod infers types from **runtime values**; botopink derives functions from **type declarations** at
compile time. Each feature lands in one of five boxes:

| Box | Meaning |
|---|---|
| **native** | The language or std already is the feature; the row names the spelling |
| **have** | `libs/validation` covers it today, under the spelling shown |
| **add · N** | Added in step *N* of [`README.md`](./README.md) |
| **gap** | Needs a compiler change; the row names the nearest working form and the `language-gaps.md` row |
| **n/a** | No meaning on this platform; reason stated |

Layers carrying additions:
- **derive** — a marker on a type or field; `#[schema]` reads it and emits code (`decorators.bp`).
- **combinator** — a `schemas` function answering a `Schema<T>`, composed by hand
  (`schemas.array(schemas.text())`), reachable from a derived type with `#[with("fn")]`.

## What the map stands on

A feature "does not map" only when the language has nothing to map it to. Eight facts decide most
rows:

| It is tempting to say | Measured |
|---|---|
| a statically typed language has no union at the value level | `A \| B` is a type, `x is T` narrows it — `docs.md:620-646` |
| … and no `any` | `unknown` holds any value, tested before use — `docs.md:622-626` |
| there is no tuple type | `#(A, B)`, labelled `#(x: A, y: B)` — `docs.md:400-414`, `:567` |
| there are no maps or sets to validate | `Dict<K, V>`, `Set<T>` — `libs/std/src/collections.bp:27`, `:246` |
| records are nominal, so `.extend` / `.pick` / `.omit` / `.partial` have no counterpart | `mergeRecords(A, B)`, `partial(T)`, `omit(T, "f")`, `pick(T, ["f"])` are comptime type functions — `comptime/infer.zig:6439`, `libs/std/AGENTS.md` |
| `.default(v)` needs new machinery | a record field declares its default (`type Port(number: i32 = 80, host: string)`) — `docs.md:1320-1356` |
| `.parse()` is `validate<TypeName>()`, which exists | `validate<TypeName>(v: TypeName)` takes an **already typed** value (`decorators.bp:199-207`); Zod's `parse` takes `unknown`. No function from untrusted data to a typed value exists; that function is the front |
| `z.coerce.date()` is `bindEpochMillis` | `bindEpochMillis` reads integer text (`binding.bp:178-187`); `new Date(value)` also reads ISO text. `clock.parseIso8601` (`io/clock.bp:141`) is the missing half |

---

## § 3 · Basic usage

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.object({…})` defining a schema | `#[schema] pub type Player(username: string, xp: i32)` | have | derive; declaration is schema and type at once |
| `Player.parse(input)` — throws | `try parsePlayer(input)` in a `@Result` function | have | emitted `pub fn parsePlayer(input: Json) -> @Result<Player, ValidationReport>`; `try` propagates (`docs.md:1467-1529`) |
| `Player.safeParse(input)` | `parsePlayer(input)` — the `@Result` itself, read with `case` or `try … catch` | have | one function: only `@Result` fails (decisions 120 · 121) |
| `Player.parseAsync` / `safeParseAsync` | `-> @Task<@Result<T, ValidationReport>>` for a schema with an async check | add · 8 | combinator `schemas.refineAsync`; derived types stay synchronous |
| `Player.validate(input)` — boolean, no error built | `schemaOfPlayer().accepts(input)` | have | same decoder, counting sink |
| `ZodError.issues` — `code`, `path`, `message`, `expected` | `ValidationReport.violations` — `field` (the rendered path), `code`, `message`, `invalidValue` | have | `Violation` (`report.bp:28-33`); `field` rendered (`address.street`, `tags[1]`); structural codes step 1's |
| `z.infer<typeof Player>` | the type is `Player` | native | no second declaration |
| `z.input<>` / `z.output<>` | `Schema<T>` has one type; a transforming schema is `Schema<Out>` built from a `Schema<In>` | add · 8 | `schemas.map(inner, f)`; input type = inner schema's |

## § 4.1 · Primitives and coercion

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.string()` | field `string` · `schemas.text()` | have | `Json.Str` only |
| `z.number()` | field `f64` · `schemas.float()` | have | `Json.Num`; `json.decode` refuses `NaN` / `Infinity` (`json.bp:99-100`) |
| `z.boolean()` | field `bool` · `schemas.boolean()` | have | |
| `z.bigint()` | field `i64` · `schemas.long()` | have | JSON number is `f64`: accepted integral within ±2^53; beyond, digit text under `#[coerce]`. No arbitrary precision — **n/a** past `i64` |
| `z.symbol()` | — | n/a | JavaScript-only |
| `z.undefined()` · `z.void()` | — | n/a | one absent value, `null`, typed `?T` (`docs.md:1000-1003`) |
| `z.null()` | `schemas.nil()` | add · 4 | `Json.Null` only; for unions |
| `z.coerce.string()` | `#[coerce]` on a `string` field | add · 6 | `Num`, `Bool` rendered; `null` refused (Zod: `"null"`) — decision `07-m` |
| `z.coerce.number()` | `#[coerce]` on `i32` / `i64` / `f64` · `bindInt` (have) · `bindFloat` | add · 6 | `Json.Str` via `isIntegerText`'s grammar (`binding.bp:105-119`) + fraction and exponent |
| `z.coerce.boolean()` | `#[coerce]` on `bool` · `bindBool` (have) | have · add · 6 | **not** Zod's truthiness: `"false"` is `false`; set is `z.stringbool`'s — decision `07-m` |
| `z.coerce.bigint()` | `#[coerce]` on `i64` | add · 6 | digit text via `rawToI64` (`binding.bp:144-146`) |
| `z.coerce.date()` | `#[coerce] #[isoDatetime]` on an `i64` field (epoch milliseconds) | add · 6 | `clock.parseIso8601` (`io/clock.bp:141`); integer text stays `bindEpochMillis` |
| `z.coerce.number<number>()` — typed input | — | n/a | input is always `Json` |

## § 4.2 · Literals

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.literal("tuna")` | `#[literal("tuna")]` on a `string` field · `schemas.literal("tuna")` | add · 4 | also `i32`, `bool` |
| `z.literal(["red","green","blue"])` | a payload-less enum (`type Color { Red, Green, Blue }`) as the field type, or `#[oneOf("red,green,blue")]` on a `string` | add · 4 | enum is the typed form; `oneOf` comma-joined since a decorator argument is a raw lexeme (`language-gaps.md` lg2-i) |
| `colors.values` | `schemaOfColor().options()` | add · 4 | `Array<string>`, declaration order |

## § 4.3 · Strings — checks and transforms

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `.max(n)` | `#[maxLength(n)]` · `checks.maxLength(n)` | add · 3 | `#[sizeBetween(min, max)]` stays (have) |
| `.min(n)` | `#[minLength(n)]` | add · 3 | |
| `.length(n)` | `#[length(n)]` | add · 3 | |
| `.nonempty()` | `#[notEmpty]` | have | `decorators.bp:86-94` |
| `.regex(re)` | `#[pattern("…")]` | have | intersection grammar, `constraints.bp:212-219` |
| `.startsWith(s)` · `.endsWith(s)` · `.includes(s)` | `#[startsWith("…")]` · `#[endsWith("…")]` · `#[includes("…")]` | add · 3 | plain `string` methods |
| `.uppercase()` · `.lowercase()` | `#[uppercase]` · `#[lowercase]` | add · 3 | check, not transform: fails on a letter of the other case |
| length in Unicode code points | step 0 measures `"é".length()` and `"😀".length()` on both targets | add · 0 | `indexOf` already disagrees with `length` on erlang (`language-gaps.md`, "`string.indexOf` counts bytes"); a length marker is as portable as `length()` |
| `.trim()` | `#[trim]` | add · 6 | transform, applied by `parse<T>` before checks |
| `.toLowerCase()` · `.toUpperCase()` | `#[lowercased]` · `#[uppercased]` | add · 6 | named apart from the checks on purpose |
| `.normalize()` | `#[normalized("NFC")]` | add · 6 | `unicode.normalize` (`unicode.bp:79`) |

## § 4.4 · String formats

Each format: one `constraints.bp` predicate, one marker, one combinator check, one built-in message.
"walk" = plain-botopink scan, no regex; "regex" = the intersection grammar. None reaches a host cell.

| Zod | botopink | Box | How |
|---|---|---|---|
| `z.email()` | `#[email]` | have | regex (`constraints.bp:217-219`) |
| `z.email({ pattern })` — html5, rfc5322, unicode | `#[emailHtml5]` · `#[emailRfc5322]` · `#[emailUnicode]` | add · 3 | regex each; default unchanged |
| `z.uuid()` | `#[uuid]` | add · 3 | regex; RFC 9562 version and variant nibbles |
| `z.uuid({ version })` · `z.uuidv4()` · `z.uuidv6()` · `z.uuidv7()` | `#[uuidV(4)]` (1–8) | add · 3 | version nibble compared |
| `z.guid()` | `#[guid]` | add · 3 | 8-4-4-4-12 shape, no nibble check |
| `z.url()` | `#[url]` | add · 3 | walk: scheme `[A-Za-z][A-Za-z0-9+.-]*`, `://`, host (labels, IPv4 or bracketed IPv6) and port 0–65535 checked here — `url.parse` (`url.bp:46`) answers every input (`platform_test.bp`) |
| `z.url({ hostname, protocol })` | `#[urlHost("…")]` · `#[urlProtocol("…")]` | add · 3 | patterns over parsed parts |
| `z.url({ normalize })` | `#[normalizedUrl]` | add · 6 | transform: `url.serialize(url.parse(v))` |
| `z.httpUrl()` | `#[httpUrl]` | add · 3 | `http` / `https`, dotted host |
| `z.hostname()` | `#[hostname]` | add · 3 | walk, RFC 1123 labels |
| `z.e164()` | `#[e164]` | add · 3 | regex |
| `z.emoji()` | `#[emoji]` | add · 3 | walk over `unicode.codepoints` (`unicode.bp:55`) against emoji ranges; no class in the grammar |
| `z.base64()` | `#[base64]` | add · 3 | `encoding.base64Decode` answers `@Result` (`encoding.bp:35`) |
| `z.base64url()` | `#[base64url]` | add · 3 | `encoding.base64UrlDecode` (`encoding.bp:49`) |
| `z.hex()` | `#[hex]` | add · 3 | walk; the three private `isHex` copies (`jhonstart-emilia/src/root.bp:39`, `rakun-web/src/static.bp:271`, `rakun-actuator-api/src/span.bp:149`) become consumers in their own fronts |
| `z.jwt()` · `z.jwt({ alg })` | `#[jwt]` · `#[jwtAlg("HS256")]` | add · 3 | three base64url segments; header `json.decode`d for `alg`. Shape only — no signature check |
| `z.nanoid()` · `z.cuid()` · `z.cuid2()` · `z.ulid()` | `#[nanoid]` · `#[cuid]` · `#[cuid2]` · `#[ulid]` | add · 3 | regex each |
| `z.ipv4()` · `z.ipv6()` | `#[ipv4]` · `#[ipv6]` | add · 3 | walk (octet range; `::` compression) |
| `z.mac()` · `z.mac({ delimiter })` | `#[mac]` · `#[macDelimiter("-")]` | add · 3 | regex |
| `z.cidrv4()` · `z.cidrv6()` | `#[cidrv4]` · `#[cidrv6]` | add · 3 | address walk + prefix range |
| `z.creditCard()` | `#[creditCard]` | add · 3 | Luhn walk; single spaces or hyphens between groups, as Zod |
| `z.currencyCode()` | `#[currencyCode]` | add · 3 | ISO 4217 table as a comma-joined literal, uppercase only |
| `z.iban()` | `#[iban]` | add · 3 | mod-97 over nine-digit chunks (products stay in `i32`) |
| `z.hash("sha256", { enc })` | `#[hash("sha256")]` · `#[hashEnc("sha256", "base64url")]` | add · 3 | length table of § "Tamanhos Esperados e Padding" + the encoding's alphabet |
| `z.iso.date()` | `#[isoDate]` | add · 3 | walk: `YYYY-MM-DD` + calendar check |
| `z.iso.time()` · precision | `#[isoTime]` · `#[isoTimePrecision(n)]` | add · 3 | walk |
| `z.iso.datetime()` · `offset` · `local` · `precision` | `#[isoDatetime]` · `#[isoDatetimeOffset]` · `#[isoDatetimeLocal]` · `#[isoDatetimePrecision(n)]` | add · 3 | walk; `Z` only by default, as Zod |
| `z.iso.duration()` | `#[isoDuration]` | add · 3 | walk |
| `z.stringFormat(name, fn \| regex)` | `spi.registerConstraint(name, code, check)` + `#[constraint("name")]` | have | `spi.bp:78-85`, `decorators.bp:326-338` |
| `z.regexes.*` | `constraints.emailPattern()` and one `pub fn <name>Pattern()` per regex format | add · 3 | `emailPattern` public today (`constraints.bp:217`) |

## § 4.5 · Template literals

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.templateLiteral([...])` | `#[pattern("…")]` | have | no botopink spelling for the type-level template string; runtime check is a regex — **n/a** as a type |

## §§ 4.6–4.8 · Numbers, integers, bigints

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `.gt(n)` · `.lt(n)` | `#[gt(n)]` · `#[lt(n)]` | add · 3 | per width, like `minValue` (`constraints.bp:114-160`) |
| `.gte(n)` / `.min(n)` · `.lte(n)` / `.max(n)` | `#[minValue(n)]` · `#[maxValue(n)]` | have | `i32`, `f64`; refused on `i64` (integer literal does not widen — `validation/AGENTS.md` § Language notes) |
| `.positive()` · `.nonnegative()` | `#[positive]` · `#[positiveOrZero]` | have | `i32`, `i64`, `f64` |
| `.negative()` · `.nonpositive()` | `#[negative]` · `#[negativeOrZero]` | add · 3 | named after the shipped pair |
| `.multipleOf(n)` / `.step(n)` | `#[multipleOf(n)]` | add · 3 | `i32` by `%`; `f64` by Zod's scaled-integer test |
| `z.int()` — safe-integer range | field `i64` with `#[safeInt]` | add · 3 | ±(2^53 − 1) |
| `z.int32()` | field `i32` | have | decoder refuses a fraction and out-of-range — structural `invalidType`, not a marker |
| `z.int64()` | field `i64` | have | as `z.bigint()` |
| `z.float32()` · `z.float64()` | field `f64`; `#[float32]` for the single-precision range | add · 3 | `f32` (`1.5f`) is a double on both targets (`platform_test.bp`), so the range is this check |
| `z.nan()` | — | n/a | JSON cannot carry one |
| `z.bigint().gt(5n)` … | the same markers on `i64` | gap | no `i64` bound literal (literal is `i32`). Nearest: `#[gt]` on `i64` refused with `minValue`'s message; `#[positive]` / `#[negative]` work (`0` widens in a comparison) |

## §§ 4.9–4.10 · Booleans and dates

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.boolean()` | field `bool` | have | |
| `z.date()` | — | n/a | no date type; instant = epoch ms (`i64`), calendar date = `clock.Civil` (`io/clock.bp:117`) |
| `z.date().min(d)` · `.max(d)` | `#[pastDate]` · `#[futureDate]` (have) · `#[afterIso("…")]` · `#[beforeIso("…")]` | have · add · 3 | bounds as ISO text, parsed once at validation |

## §§ 4.11–4.12 · Enums and stringbools

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.enum(["Salmon","Tuna"])` | `#[schema] pub type Fish { Salmon, Tuna, Trout }` | add · 4 | derive over `decl.variants` (`builtins.d.bp:592`): `parseFish(Json) -> @Result<Fish, …>` matching the variant **name** |
| `z.enum(Fish)` over a TS enum / object | `#[wire("salmon")]` on a variant for a wire name that differs | gap | variants reflected as names only, no annotations. Nearest: `#[wireNames("Salmon=salmon,Tuna=tuna")]` on the type |
| `FishEnum.enum` | the type itself (`Fish.Salmon`) | native | |
| `.exclude([...])` · `.extract([...])` | a section of the enum (`type Token { Color { Red, Gray }, Bold }` — `Token.Color` is a type) | native | `docs.md:441-467`; declared, not computed |
| `z.stringbool()` | `#[stringbool]` on a `bool` field · `schemas.stringbool()` | add · 6 | `true 1 yes on y enabled` / `false 0 no off n disabled`, case-insensitive |
| `z.stringbool({ truthy, falsy, case })` | `schemas.stringboolOf(truthy, falsy, caseSensitive)` | add · 6 | combinator only |

## §§ 4.13–4.16 · Optional, nullable, nullish, unknown

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `.optional()` · `.nullable()` · `.nullish()` | field `?T` | have | missing key and `null` both decode to `null` |
| `.exactOptional()` | `#[present]` on a `?T` field — the key may be absent, but `null` is refused | add · 5 | |
| `.unwrap()` | — | n/a | no schema value to unwrap; the type says it |
| `.nonoptional()` | field `T` | native | |
| `z.any()` · `z.unknown()` | field `Json` | have | tree passed through; `unknown` is the language's word, but a `Json` can be walked |
| `z.never()` | `schemas.never()` | add · 4 | always a violation; union arm or catch-all |

## §§ 4.17–4.18 · Objects

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.object({…})` — strips unknown keys | `#[schema] #[stripUnknown] pub type …` | add · 5 | **not the default** — decision 144 |
| `z.strictObject({…})` | `#[schema] pub type …` | add · 5 | default: unknown key → `unrecognizedKey` |
| `z.looseObject({…})` | a field `#[rest] extra: Dict<string, Json>` | add · 5 | unknown members kept, document order |
| `.catchall(schema)` | `#[rest] extra: Dict<string, T>` | add · 5 | each unknown member decoded as `T` |
| `.shape` | `schemaOfDog().fields()` | add · 9 | `Array<FieldInfo>` — name, type name, markers; `constraintsOf<T>`'s rows |
| `.keyof()` | `schemaOfDog().keys()` | add · 9 | `Array<string>` |
| `.extend({…})` | `mergeRecords(Dog, Extra)` for the type; `#[extending("Dog")]` on a new record for its schema | gap | `mergeRecords` answers an anonymous record a decorator cannot annotate. Nearest: declare the wider record `#[schema]`; `#[extending]` only checks every `Dog` field is repeated |
| `.safeExtend({…})` | the same check, always | add · 5 | `#[extending]` refuses an incompatibly retyped field |
| `.pick({…})` · `.omit({…})` | `#[schema] #[pick("JustTitle", "title")]` — the decorator **emits** the narrower record and its schema | add · 5 | `@emit` writes types today (`rakun-data/src/orm/entity.bp:183`) |
| `.partial()` · `.partial({ k: true })` | `#[partial("RecipePatch")]` — emits `RecipePatch` with every field `?T` | add · 5 | |
| `.exactPartial()` | `#[partial]` with `#[present]` carried over | add · 5 | |
| `.required()` | `#[required("RecipeFull")]` | add · 5 | emits the record with no `?` |
| `z.deepPartial()` | — | gap | a decorator sees one declaration (`lg2-k` answered by 216: project reflection via `@TypeInfo.all`, 253); each nested type's partial marked |
| symbol keys | — | n/a | |
| recursive objects (`get subcategories()`) | a field typed with the record itself | have | `parseCategory` calls itself by name; no getter trick |
| mutually recursive objects | two `#[schema]` records naming each other | have | name contract `parse<TypeName>` |

## §§ 4.19–4.20 · Arrays and tuples

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.array(T)` | field `Array<T>` / `T[]` | have | each item at path `field[i]` |
| `.nonempty()` | `#[notEmpty]` | have | `vNotEmptyList` |
| `.min(n)` · `.max(n)` · `.length(n)` | `#[minLength(n)]` · `#[maxLength(n)]` · `#[length(n)]` on an array field | add · 3 | `#[sizeBetween]` stays |
| checks on the items (`z.array(z.email())`) | `#[with("emails")]` naming `fn emails() -> Schema<Array<string>>` | add · 8 | a marker is a raw lexeme, cannot nest (lg2-i) — 280 makes it `#[with(emails)]`, a function value |
| `.unwrap()` | — | n/a | |
| `z.tuple([A, B, C])` | field `#(A, B, C)` | add · 4 | JSON array of exactly that length |
| `z.tuple([A], rest)` | `schemas.tupleRest(…)` | add · 4 | combinator; answers `#(A, Array<R>)` |
| `.partial()` on a tuple | a tuple of `?T` | native | |

## §§ 4.21–4.24 · Unions and intersections

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.union([A, B])` | field `A \| B` · `schemas.union2(a, b)` (to `union5`) | add · 4 | arms in declaration order; all fail → one `invalidUnion` carrying each arm's first violation |
| `.options` | `schemaOf….options()` | add · 9 | |
| `z.xor([A, B])` | `schemas.xor2(a, b)` | add · 4 | exactly one arm |
| `z.discriminatedUnion("status", […])` | `#[schema] #[tag("status")] pub type Result { Success(data: string), Failed(error: string) }` | gap | `Decl.variants` carries names, not payload fields (`builtins.d.bp:584-592`). Nearest, here: each payload is a same-named `#[schema]` record; the enum's decoder dispatches on the tag to `parse<Variant>` |
| `z.getDiscriminatedOption` | `schemaOfResult().option("success")` | add · 9 | |
| nested discriminated unions | an enum whose variant payload is another tagged enum | add · 4 | name contract |
| `z.intersection(A, B)` | `schemas.both(a, b)` answering `#(A, B)`; for records, a record with both field sets | add · 4 | no intersection-type spelling; the pair is the honest answer |

## §§ 4.25–4.27 · Records, maps, sets

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.record(z.string(), V)` | field `Dict<string, V>` | add · 4 | JSON object; each member `field.key` |
| `z.record(Keys, V)` — enum keys, exhaustive | field `Dict<Fish, V>` with `#[exhaustive]` | add · 4 | every variant present |
| `z.partialRecord` | `Dict<Fish, V>` without the marker | add · 4 | |
| `z.looseRecord` | `#[rest]` beside declared fields | add · 5 | above |
| numeric keys | `Dict<i32, V>` | add · 4 | key text via the integer grammar |
| `z.map(K, V)` | `Dict<K, V>` decoded from an array of pairs | add · 4 | wire form `[[k, v], …]` |
| `.min` / `.max` / `.size` / `.nonempty` on maps and sets | the length markers | add · 3 | `Dict.size()`, `Set.size()` |
| `z.set(T)` | field `Set<T>` | add · 4 | JSON array; repeated item → `duplicate`, not folded |

## §§ 4.28–4.30 · Files, promises, instanceof

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.file()` · `.min` · `.max` · `.mime` | — | gap | no byte type (`language-gaps.md` lg2-a); multipart refused with 415 today. Nearest: validate the upload's declared `name`, `size`, `type` as a record |
| `z.promise()` | — | n/a | deprecated in Zod; a `@Task` is awaited before parsing |
| `z.instanceof(Class)` | `x is T` | native | `docs.md:625-626`; a host class has no botopink type |
| `z.property(k, schema)` · `z.properties({…})` | `schemas.field("status", …)` over a `Json` | add · 8 | combinator |

## §§ 4.31–4.33 · Refinements, pipes, transforms

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `.refine(fn, { error })` | field: `#[constraint("name")]` (have) · type: `#[check("fnName")]` naming `fn(v: T) -> Array<Violation>` · `schema.refine(pred, code, message)` | have · add · 7 | type-level form for cross-field rules |
| `.refine(…, { path })` | the function answers the `Violation` with its own `field` | add · 7 | |
| `.refine(…, { abort: true })` | `#[stopOnFirst]` on the field | add · 7 | default stays "every check runs" (`constraints.bp:12-14`) |
| `.refine(…, { when })` | the type-level check runs only when the report so far is empty for the fields it names: `#[check("passwordsMatch", "password,confirm")]` | add · 7 | |
| `.refine(async …)` | `schemas.refineAsync` | add · 8 | |
| `.superRefine((val, ctx) => ctx.addIssue(…))` | the same `#[check]` — it answers any number of violations | add · 7 | |
| `.check(ctx => ctx.issues.push(…))` | the same | add · 7 | one API, no slower one to bypass |
| `.pipe(schema)` | `schemas.pipe(a, b)` | add · 8 | |
| `z.transform(fn)` · `.transform(fn)` | `schemas.map(inner, f)` · field marker `#[map("fnName")]` | add · 8 | field's declared type is the output |
| transform that fails (`ctx.issues.push`, `z.NEVER`) | `schemas.tryMap(inner, f)` with `f: fn(a: A) -> @Result<B, string>` | add · 8 | `Error` text is the message, coded `custom` |
| `z.preprocess(fn, schema)` | `schemas.preprocess(f, inner)` with `f: fn(j: Json) -> Json` | add · 8 | |
| `.overwrite(fn)` | the transform markers of § 4.3, and `#[map]` when the type does not change | add · 6 | |

## §§ 4.34–4.38 · Defaults, catch, brands, readonly

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `.default(v)` | `#[orElse("…")]` on the field | gap | language form is the field default (`count: i32 = 0`), but `Field` reflects no default (`builtins.d.bp:568-572`), so the emitter cannot omit the label. Nearest: `#[orElse]` writes the literal; redundant once reflection carries defaults |
| `.default(fn)` | `#[orElseOf("fnName")]` | add · 5 | called per parse |
| `.prefault(v)` | `#[orElse]` placed on a field with transforms — the literal is decoded and transformed like an input | add · 6 | one marker; "parsed, not short-circuited" is the only behaviour |
| `.catch(v)` · `.catch(fn)` | `#[fallback("…")]` · `#[fallbackOf("fnName")]` | add · 5 | on decode or check failure the field takes the value, **no** violation recorded; refused on a type with no literal |
| `.brand<"Cat">()` | two record types | native | nominal: `Cat(name: string)` is not `Dog(name: string)` |
| brand direction | — | n/a | |
| `.readonly()` | — | native | records are immutable (`docs.md:358-368`) |

## §§ 4.39–4.43 · JSON, functions, custom, apply, existing types

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.json()` | field `Json` | have | |
| `z.function({ input, output })` · `.implement` | — | n/a | parameters typed by the signature; a runtime check is `parse<Args>` at the calling boundary |
| `z.custom<T>(fn)` | `schemas.custom(f)` with `f: fn(j: Json) -> @Result<T, string>` | add · 8 | |
| `.apply(fn)` | a function over `Schema<T>` | native | schemas are values; composing is a call |
| `z.toZod<Player>()` | — | native | schema derived from `Player`; cannot drift |

## § 5 · Customising errors

| Zod | botopink | Box | Notes |
|---|---|---|---|
| check-level message (`.min(5, "Too short!")`) | `#[message("…")]` after the marker it restates | add · 7 | a marker's arity is fixed, so one more marker |
| schema-level message (`z.string("Not a string!")`) | `#[typeMessage("…")]` on the field | add · 7 | restates `invalidType` |
| error map as a function | `MessageSource(locale, template)` | have | `messages.bp:35-38` |
| `iss.code` · `iss.input` · `iss.path` · `iss.minimum` … | `{field}` `{value}` and the marker's own parameters, by name | have | `messages.bp:96-114` |
| per-parse error map (`.parse(x, { error })`) | `schemaOfPlayer().parseWith(input, source)` | add · 7 | a `MessageSource` for one call, under field-level messages |
| `reportInput: true` | `Violation.invalidValue` is always carried; `toJson` never writes it | have | `report.bp:81-93` — the reflected-input rule |
| `z.config({ customError })` | `setMessageSource(source)` | have | `messages.bp:55-57` |
| `z.config({ localeError })` — `z.config(en())` | `setMessageSource(locales.ptBR())` | add · 10 | one table module per locale under `locales/`; `en` is `builtInTemplate` |
| `z.config({ jitless })` · `memoizer` · `postProcessor` | — | n/a | no runtime code generation to disable |
| resolution order (check → schema → per-parse → global → locale → fallback) | `#[message]` → `#[typeMessage]` → `parseWith`'s source → `setMessageSource` (locale key, then bare key) → `builtInTemplate` | have · add · 7 | steps 4–6 are `templateFor` today (`messages.bp:82-91`) |
| 58 shipped locales | `en`, `ptBR`, `es` shipped; the rest are one file each | add · 10 | a locale is data; `105-i18n` owns negotiation |

## § 6 · Formatting errors

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.treeifyError()` | `report.tree()` → `ReportTree(errors, properties, items)` | add · 9 | built from `field`'s path |
| `z.prettifyError()` | `report.pretty()` | add · 9 | `✖ <message>` / `  → at <path>`, byte-identical on both targets |
| `z.flattenError()` | `report.flatten()` → `Flat(formErrors, fieldErrors)` | add · 9 | keyed by first path segment |
| — | `report.toJson()` · `report.toProblemDetail()` | have | RFC 9457 (`report.bp:51-69`) |

## § 7 · Metadata and registries

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `.meta({ title, description, examples, deprecated })` | `#[title("…")]` · `#[describe("…")]` · `#[example("…")]` · `#[deprecated]` on a type or a field | add · 9 | reach `fields()` and the JSON Schema |
| `.describe("…")` | `#[describe("…")]` | add · 9 | |
| `z.registry()` · `.register()` | `spi.registerSchema(id, schema)` · `spi.schemaNamed(id)` | add · 9 | `spi.bp`'s constraint host table (`spi.bp:45-74`) |
| `z.globalRegistry` with `id` | `#[schemaId("User")]`; the default id is the type's name | add · 9 | |
| typed registries (`z.registry<Meta, ZodString>()`) | — | n/a | one metadata shape |

## § 8 · JSON Schema

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.toJSONSchema(schema)` | `jsonSchemaOf<TypeName>() -> string` | add · 9 | beside `constraintsOf<TypeName>` (`decorators.bp:208-216`), kept as the compact table |
| `target` (draft-04 · 07 · 2020-12 · openapi-3.0) | `jsonSchemaOf<TypeName>()` is 2020-12; `table.toDraft07(…)` · `table.toOpenApi30(…)` rewrite it | add · 9 | |
| `metadata` | the markers of § 7 | add · 9 | |
| `unrepresentable` | a field the JSON Schema cannot say (`#[map]`, `#[check]`) is a **compile error** under `#[jsonSchema]`, and `{}` without it | add · 9 | decision 67: no silent `any` |
| `cycles: "ref"` · `reused: "ref"` | a field typed with a `#[schema]` record is `{"$ref": "#/$defs/<Name>"}` always | add · 9 | one form; recursion needs it, sharing is shorter |
| `io: "input" \| "output"` | `inputJsonSchemaOf<TypeName>()` where a transform changes a field's wire type | add · 9 | |
| `uri` | `table.withRefBase(json, "https://…/")` | add · 9 | |
| `override` | — | n/a | the document is a string the caller may rewrite |
| format mapping (`email` → `format: "email"`, `base64` → `contentEncoding`, the rest → `pattern`) | the same table, from the marker code | add · 9 | § 8.3's rows verbatim |
| `additionalProperties: false` | written unless the type carries `#[stripUnknown]` or a `#[rest]` field | add · 9 | |
| `z.fromJSONSchema()` | — | n/a | generating declarations from a document is a CLI generator, not a library call — out of this front |
| `z.toJSONSchema(z.globalRegistry)` | `spi.registeredJsonSchemas()` | add · 9 | `{"schemas": {…}}` over the registry |

## § 9 · Codecs

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.codec(In, Out, { decode, encode })` | `schemas.codec(inner, decode, encode)` → `Codec<A, B>` | add · 8 | |
| `.decode()` · `.encode()` | `parse<TypeName>` · `encode<TypeName>(v: TypeName) -> Json` | add · 8 | `#[schema]` emits `encode` for every type whose fields all encode |
| `.safeDecode` · `.decodeAsync` · `.encodeAsync` | the `@Result` / `@Task<@Result>` returns | add · 8 | |
| `z.invertCodec` | `schemas.invert(c)` | add · 8 | |
| composability (codecs inside objects and arrays) | a field with `#[codec("fnName")]` | add · 8 | |
| refinements run in both directions | `encode<TypeName>` runs `validate<TypeName>` first and answers `@Result` | add · 8 | |
| the recipe list — `stringToNumber`, `stringToInt`, `stringToBigInt`, `isoDatetimeToDate`, `epochSecondsToDate`, `epochMillisToDate`, `jsonCodec`, `base64ToBytes`, `hexToBytes`, `stringToURL`, `stringToHttpURL`, `uriComponent`, `stringToBoolean` | `codecs.textToInt` · `textToLong` · `textToFloat` · `isoToMillis` · `secondsToMillis` · `jsonText` · `base64Text` · `base64urlText` · `hexText` · `textToUrl` · `uriComponent` · `textToBool` | add · 8 | `utf8ToBytes` / `bytesToUtf8` are **gap** (lg2-a) |

## § 10 · AOT compilation

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.compile(schema)` — a flat, loop-free validator generated ahead of time | `#[schema]` | native | a derived schema's only mode: decoder emitted at compile time as straight-line botopink |
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
| Zod Classic (methods) vs Zod Mini (functions) | one API: `Schema<T>` methods for the wrappers (`.optional()`, `.array()`, `.refine(…)`, `.map(…)`), `checks.*` functions for the checks | have · add · 8 | a check is typed by its subject (`Check<string>`): `schemas.int().check(checks.email())` does not compile |
| `mySchema.isOptional()` · `.isNullable()` | `schema.isOptional()` | add · 9 | |
| `mySchema.clone(def)` · `_zod.def` · `_zod.run` | `schema.fields()` / `.options()` for reflection; no internals | add · 9 | |
| `z.$ZodType` hierarchy, v3/v4 dual support, peer dependencies | — | n/a | one bundled version, shipped with the compiler |

---

## Count

211 rows by the Box column's first word (a partly shipped row counts as what it already is), after
steps 0–2:

| Box | Rows |
|---|---|
| native | 11 |
| have | 37 |
| add (this front) | 134 |
| gap (nearest form shipped, row filed) | 7 |
| n/a | 20 |
| consumer or out of the reference's core (`—`) | 2 |

Seven gaps: `i64` bounds, wire names on variants, payload fields of variants, `.extend` on an
anonymous record, `z.deepPartial`, `z.file`, field defaults in reflection — plus the byte codecs in
§ 9's recipe row (same cause as `z.file`). Each has a [`../../language-gaps.md`](../../language-gaps.md)
row and a nearest form above; none blocks a step.

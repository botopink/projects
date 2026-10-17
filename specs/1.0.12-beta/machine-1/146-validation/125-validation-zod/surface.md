# 125-validation-zod — surface: every Zod feature, and where it lands in botopink

Reference: Zod 4 documentation, <https://zod.dev/> (Zod 4.x; API pages under <https://zod.dev/api>),
walked section by section, § numbers following the reference (§§ 1–13). Every "the language has no …"
claim names its place in `repository/botopink-lang` (`docs.md`, `libs/std`, `repository/validation`). Rows
whose step landed (steps 0–12) read **have**; every row is sorted into a marker, a declared type, or
`n/a (306)` with its reason (decision 325) — the type is the only schema (306), so a row that only a
schema value could say has no public form.

## How to read it

Zod infers types from **runtime values**; botopink derives functions from **type declarations** at
compile time. Each feature lands in one of five boxes:

| Box | Meaning |
|---|---|
| **native** | The language or std already is the feature; the row names the spelling |
| **have** | `repository/validation` covers it today, under the spelling shown |
| **add · N** | Step *N* of [`README.md`](context.md), not landed — the row names what it waits on |
| **gap** | Needs a compiler change; the row names the nearest working form and the `language-gaps.md` row |
| **n/a** | No meaning on this platform; reason stated |
| **n/a (306)** | Only a schema value could say it, and the type is the only schema (decision 306); the reason names the declared form, if any |

One layer carries every addition: a **marker** on a type or a field, read by `#[validated]`, which
gives the type its members — `validate()`, `constraints()`, `parse`, `parseAt`, `decode`, `bind`,
`encode`, `jsonSchema` (decisions 306, 327; `decorators.bp`). The combinator layer (`Schema<T>`,
`schemas.*`, `checks.*`) is gone: what it said is a field marker or a declared type, or `n/a (306)`.

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
| `.parse()` is `validate()`, which exists | `validate()` takes an **already typed** value; Zod's `parse` takes `unknown`. The function from untrusted data to a typed value is `T.parse` (327) |
| `z.coerce.date()` is `bindEpochMillis` | `bindEpochMillis` reads integer text (`binding.bp:178-187`); `new Date(value)` also reads ISO text. `clock.parseIso8601` (`io/clock.bp:141`) is the missing half |

---

## § 3 · Basic usage

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.object({…})` defining a schema | `#[validated] pub type Player(username: string, xp: i32)` | have | declaration is schema and type at once (306) |
| `Player.parse(input)` — throws | `try Player.parse(input)` in a `@Result` function | have | member (327) `Player.parse(input: Json) -> @Result<Player, ValidationReport>`; `try` propagates (`docs.md:1467-1529`) |
| `Player.safeParse(input)` | `Player.parse(input)` — the `@Result` itself, read with `case` or `try … catch` | have | one member: only `@Result` fails (decisions 120 · 121) |
| `Player.parseAsync` / `safeParseAsync` | — | n/a (306) | a declared type's parse is synchronous; an async rule is the application's own `@Task` function after `parse` |
| `Player.validate(input)` — boolean, no error built | `Player.parse(input).isOk()` | have | the same decoder; no schema value to ask (306) |
| `ZodError.issues` — `code`, `path`, `message`, `expected` | `ValidationReport.violations` — `field` (the rendered path), `code`, `message`, `invalidValue` | have | `Violation` (`report.bp:28-33`); `field` rendered (`address.street`, `tags[1]`); structural codes step 1's |
| `z.infer<typeof Player>` | the type is `Player` | native | no second declaration |
| `z.input<>` / `z.output<>` | the field's declared type is the output; the input is the document | n/a (306) | no schema value carries two types; `#[map]` (s24) reads its input from the function's parameter |

## § 4.1 · Primitives and coercion

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.string()` | field `string` | have | `Json.Str` only |
| `z.number()` | field `f64` | have | `Json.Num`; `json.decode` refuses `NaN` / `Infinity` (`json.bp:99-100`) |
| `z.boolean()` | field `bool` | have | |
| `z.bigint()` | field `i64` | have | JSON number is `f64`: accepted integral within ±2^53; beyond, digit text under `#[coerce]`. No arbitrary precision — **n/a** past `i64` |
| `z.symbol()` | — | n/a | JavaScript-only |
| `z.undefined()` · `z.void()` | — | n/a | one absent value, `null`, typed `?T` (`docs.md:1000-1003`) |
| `z.null()` | a `?T` arm, or a `Json` field | n/a (306) | `schemas.nil()` was a union arm; a declared union says absence with `?T` |
| `z.coerce.string()` | `#[coerce]` on a `string` field | have | `Num`, `Bool` rendered; `null` refused (Zod: `"null"`) — decision `07-m` |
| `z.coerce.number()` | `#[coerce]` on `i32` / `i64` / `f64` · `bindInt` · `bindFloat` | have | text by std's numeral grammar (`String.parseInt` / `parseFloat`); not a number → `invalidType`, never a zero |
| `z.coerce.boolean()` | `#[coerce]` on `bool` · `bindBool` | have | **not** Zod's truthiness: `"false"` is `false`; set is `z.stringbool`'s — decision `07-m` |
| `z.coerce.bigint()` | `#[coerce]` on `i64` | have | digit text through `String.parseInt` (±(2^53 − 1)) |
| `z.coerce.date()` | `#[coerce] #[isoDatetime]` on an `i64` field (epoch milliseconds) | have | `clock.parseIso8601` over the shape `#[isoDatetime]` (or `#[isoDatetimeOffset]`) checks |
| `z.coerce.number<number>()` — typed input | — | n/a | input is always `Json` |

## § 4.2 · Literals

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.literal("tuna")` | `#[literal("tuna")]` on a `string` field | have | also `i32`, `bool`; code `literal` |
| `z.literal(["red","green","blue"])` | a payload-less enum (`type Color { Red, Green, Blue }`) as the field type, or `#[oneOf("red,green,blue")]` on a `string` | have | enum is the typed form; `oneOf` comma-joined since a decorator argument is a raw lexeme (`language-gaps.md`) |
| `colors.values` | `Color.options()` | have | `Array<string>`, declaration order |

## § 4.3 · Strings — checks and transforms

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `.max(n)` | `#[maxLength(n)]` | have | `#[sizeBetween(min, max)]` stays (have) |
| `.min(n)` | `#[minLength(n)]` | have | |
| `.length(n)` | `#[length(n)]` | have | |
| `.nonempty()` | `#[notEmpty]` | have | `decorators.bp:86-94` |
| `.regex(re)` | `#[pattern("…")]` | have | intersection grammar, `constraints.bp:212-219` |
| `.startsWith(s)` · `.endsWith(s)` · `.includes(s)` | `#[startsWith("…")]` · `#[endsWith("…")]` · `#[includes("…")]` | have | plain `string` methods |
| `.uppercase()` · `.lowercase()` | `#[uppercase]` · `#[lowercase]` | have | check, not transform: fails on a letter of the other case |
| length in Unicode code points | the length markers count `unicode.codepoints` | have | measured in step 0 (`platform_test.bp`) |
| `.trim()` | `#[trim]` | have | transform, applied by `T.parse` before the checks |
| `.toLowerCase()` · `.toUpperCase()` | `#[lowercased]` · `#[uppercased]` | have | named apart from the checks on purpose |
| `.normalize()` | `#[normalized("NFC")]` | have | `unicode.normalize` (`unicode.bp:79`) |

## § 4.4 · String formats

Each format: one `formats.bp` rule, one `constraints.bp` predicate, one marker, one built-in message.
"walk" = plain-botopink scan, no regex; "regex" = the intersection grammar. None declares a host cell.

| Zod | botopink | Box | How |
|---|---|---|---|
| `z.email()` | `#[email]` | have | regex (`constraints.bp:217-219`) |
| `z.email({ pattern })` — html5, rfc5322, unicode | `#[emailHtml5]` · `#[emailRfc5322]` · `#[emailUnicode]` | have | regex each; default unchanged |
| `z.uuid()` | `#[uuid]` | have | regex; RFC 9562 version and variant nibbles |
| `z.uuid({ version })` · `z.uuidv4()` · `z.uuidv6()` · `z.uuidv7()` | `#[uuidV(4)]` (1–8) | have | version nibble compared |
| `z.guid()` | `#[guid]` | have | 8-4-4-4-12 shape, no nibble check |
| `z.url()` | `#[url]` | have | walk: scheme `[A-Za-z][A-Za-z0-9+.-]*`, `://`, host (labels, IPv4 or bracketed IPv6) and port 0–65535 checked here — `url.parse` (`url.bp:46`) answers every input (`platform_test.bp`) |
| `z.url({ hostname, protocol })` | `#[urlHost("…")]` · `#[urlProtocol("…")]` | have | patterns over parsed parts |
| `z.url({ normalize })` | `#[normalizedUrl]` | have | transform: `url.serialize(url.parse(v))` |
| `z.httpUrl()` | `#[httpUrl]` | have | `http` / `https`, dotted host |
| `z.hostname()` | `#[hostname]` | have | walk, RFC 1123 labels |
| `z.e164()` | `#[e164]` | have | regex |
| `z.emoji()` | `#[emoji]` | have | walk over `unicode.codepoints` (`unicode.bp:55`): `Extended_Pictographic` and `Emoji_Component` ranges of emoji-data.txt, as Zod's `\p{…}` |
| `z.base64()` | `#[base64]` | have | walk: the alphabet, a multiple of four, at most two `=` at the end (`""` is base64, as Zod) |
| `z.base64url()` | `#[base64url]` | have | walk: the URL alphabet, unpadded, no length leaving one dangling character |
| `z.hex()` | `#[hex]` | have | walk; the three private `isHex` copies (`jhonstart-emilia/src/root.bp:39`, `rakun-web/src/static.bp:271`, `rakun-actuator-api/src/span.bp:149`) become consumers in their own fronts; `jhonstart-emilia`'s leaves with the member instead (`08-bpp/119` deletes it, decision 338) |
| `z.jwt()` · `z.jwt({ alg })` | `#[jwt]` · `#[jwtAlg("HS256")]` | have | three base64url segments (stricter than Zod 4, which does not count them); header `json.decode`d: a text `alg`, `typ` `"JWT"` when present. Shape only — no signature check |
| `z.nanoid()` · `z.cuid()` · `z.cuid2()` · `z.ulid()` | `#[nanoid]` · `#[cuid]` · `#[cuid2]` · `#[ulid]` | have | regex each |
| `z.ipv4()` · `z.ipv6()` | `#[ipv4]` · `#[ipv6]` | have | walk (octet range; `::` compression) |
| `z.mac()` · `z.mac({ delimiter })` | `#[mac]` · `#[macDelimiter("-")]` | have | regex |
| `z.cidrv4()` · `z.cidrv6()` | `#[cidrv4]` · `#[cidrv6]` | have | address walk + prefix range |
| `z.creditCard()` | `#[creditCard]` | have | Luhn walk over 12–19 digits; single spaces or single hyphens between groups (one kind), as Zod |
| `z.currencyCode()` | `#[currencyCode]` | have | ISO 4217's 2025 list (funds and metals included) as a comma-joined literal, uppercase only |
| `z.iban()` | `#[iban]` | have | shape (15–34, country letters, check digits) + ISO 7064 mod 97-10 digit by digit (stays in `i32`); per-country length not checked |
| `z.hash("sha256", { enc })` | `#[hash("sha256")]` · `#[hashEnc("sha256", "base64url")]` | have | length table of § "Tamanhos Esperados e Padding" + the encoding's alphabet |
| `z.iso.date()` | `#[isoDate]` | have | walk: `YYYY-MM-DD` + calendar check |
| `z.iso.time()` · precision | `#[isoTime]` · `#[isoTimePrecision(n)]` | have | walk |
| `z.iso.datetime()` · `offset` · `local` · `precision` | `#[isoDatetime]` · `#[isoDatetimeOffset]` · `#[isoDatetimeLocal]` · `#[isoDatetimePrecision(n)]` | have | walk; `Z` only by default, as Zod; `#[isoDatetimePrecision(n)]` checks the precision beside one of the three, which fix the zones (alone it is refused) |
| `z.iso.duration()` | `#[isoDuration]` | have | walk |
| `z.stringFormat(name, fn \| regex)` | `spi.registerConstraint(name, code, check)` + `#[constraint("name")]` | have | `spi.bp:78-85`, `decorators.bp:326-338` |
| `z.regexes.*` | `constraints.emailPattern()` and one `pub fn <name>Pattern()` per regex format | have | `emailPattern` public today (`constraints.bp:217`) |

## § 4.5 · Template literals

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.templateLiteral([...])` | `#[pattern("…")]` | have | no botopink spelling for the type-level template string; runtime check is a regex — **n/a** as a type |

## §§ 4.6–4.8 · Numbers, integers, bigints

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `.gt(n)` · `.lt(n)` | `#[gt(n)]` · `#[lt(n)]` | have | per width (`I32`, `I64`, `F64`); the bound has the field's type (a fraction on an integer field is refused) |
| `.gte(n)` / `.min(n)` · `.lte(n)` / `.max(n)` | `#[minValue(n)]` · `#[maxValue(n)]` | have | `i32`, `f64`; refused on `i64` (integer literal does not widen — `validation/AGENTS.md` § Language notes) |
| `.positive()` · `.nonnegative()` | `#[positive]` · `#[positiveOrZero]` | have | `i32`, `i64`, `f64` |
| `.negative()` · `.nonpositive()` | `#[negative]` · `#[negativeOrZero]` | have | named after the shipped pair |
| `.multipleOf(n)` / `.step(n)` | `#[multipleOf(n)]` | have | `i32` / `i64` by `%`; `f64` by Zod's scaled-integer test, the step's decimals read from the lexeme |
| `z.int()` — safe-integer range | field `i64` with `#[safeInt]` | have | ±(2^53 − 1) |
| `z.int32()` | field `i32` | have | decoder refuses a fraction and out-of-range — structural `invalidType`, not a marker |
| `z.int64()` | field `i64` | have | as `z.bigint()` |
| `z.float32()` · `z.float64()` | field `f64`; `#[float32]` for the single-precision range | have | `f32` (`1.5f`) is a double on both targets (`platform_test.bp`), so the range is this check |
| `z.nan()` | — | n/a | JSON cannot carry one |
| `z.bigint().gt(5n)` … | `#[gt]`, `#[lt]`, `#[multipleOf]`, `#[negative]` on `i64` | have | an integer literal takes the `i64` its argument position asks for (`docs.md`); `#[minValue]` / `#[maxValue]` still refuse `i64` (their table rows unchanged) |

## §§ 4.9–4.10 · Booleans and dates

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.boolean()` | field `bool` | have | |
| `z.date()` | — | n/a | no date type; instant = epoch ms (`i64`), calendar date = `clock.Civil` (`io/clock.bp:117`) |
| `z.date().min(d)` · `.max(d)` | `#[pastDate]` · `#[futureDate]` (have) · `#[afterIso("…")]` · `#[beforeIso("…")]` | have | bounds as RFC 3339 text with its zone, checked at the marker, parsed by `clock.parseIso8601` at validation; strict, as `#[pastDate]` |

## §§ 4.11–4.12 · Enums and stringbools

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.enum(["Salmon","Tuna"])` | `#[validated] pub type Fish { Salmon, Tuna, Trout }` | have | over `decl.variants`: `Fish.parse` matches the variant **name**; another text is `invalidValue` with the options |
| `z.enum(Fish)` over a TS enum / object | `#[wireName("salmon")]` on a variant for a wire name that differs | gap | variants reflected as names only, no annotations (`Decl.variants` row) — step 11's box waits on it |
| `FishEnum.enum` | the type itself (`Fish.Salmon`) | native | |
| `.exclude([...])` · `.extract([...])` | a section of the enum (`type Token { Color { Red, Gray }, Bold }` — `Token.Color` is a type) | native | `docs.md:441-467`; declared, not computed |
| `z.stringbool()` | `#[stringbool]` on a `bool` field | have | `true 1 yes on y enabled` / `false 0 no off n disabled`, case-insensitive; a JSON boolean is `invalidType` |
| `z.stringbool({ truthy, falsy, case })` | — | n/a (306) | the combinator `stringboolOf` was a value; a different set is a `#[preprocess(f)]` over the text |

## §§ 4.13–4.16 · Optional, nullable, nullish, unknown

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `.optional()` · `.nullable()` · `.nullish()` | field `?T` | have | missing key and `null` both decode to `null` |
| `.exactOptional()` | `#[present]` on a `?T` field — the key may be absent, but `null` is refused | have | |
| `.unwrap()` | — | n/a | no schema value to unwrap; the type says it |
| `.nonoptional()` | field `T` | native | |
| `z.any()` · `z.unknown()` | field `Json` | have | tree passed through; `unknown` is the language's word, but a `Json` can be walked |
| `z.never()` | — | n/a (306) | a schema value refusing everything; a declared type has no arm that is never valid |

## §§ 4.17–4.18 · Objects

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.object({…})` — strips unknown keys | `#[validated] #[stripUnknown] pub type …` | have | **not the default** — decision 144 |
| `z.strictObject({…})` | `#[validated] pub type …` | have | default: unknown key → `unrecognizedKey` |
| `z.looseObject({…})` | a field `#[rest] extra: Dict<string, Json>` | have | unknown members kept, document order |
| `.catchall(schema)` | `#[rest] extra: Dict<string, T>` | have | each unknown member decoded as `T` |
| `.shape` | `@typeInfo(Dog).fields` | add · 12 | reflection reads the type (306); `fields` is `typeinfo-unknown-member` today (`01-checker`, `language-gaps.md`) |
| `.keyof()` | `Type.keys(Dog)` (307) | add · 5 | std's `Type`; waits on `01-checker` step 28 |
| `.extend({…})` | `#[validated] pub val DogWithBreed = Type.merge(Dog, Breed);` (307) | add · 5 | waits on `01-checker` step 28; `#[extending]` goes |
| `.safeExtend({…})` | `Type.merge` refuses an incompatibly retyped field (307) | add · 5 | waits on `01-checker` step 28 |
| `.pick({…})` · `.omit({…})` | `#[validated] pub val RecipeTitle = Type.pick(Recipe, .title);` · `Type.omit` (307) | add · 5 | waits on `01-checker` step 28 and 134 step 4 (the variadic parameter, 267) |
| `.partial()` · `.partial({ k: true })` | `#[validated] pub val RecipePatch = Type.partial(Recipe);` (307) | add · 5 | waits on `01-checker` step 28 |
| `.exactPartial()` | `Type.partial` with `#[present]` carried over | add · 5 | waits on `01-checker` step 28 |
| `.required()` | `#[validated] pub val RecipeFull = Type.required(Recipe);` (307) | add · 5 | waits on `01-checker` step 28 |
| `z.deepPartial()` | — | gap | a decorator sees one declaration (`lg2-k` answered by 216: project reflection via `@TypeInfo.all`, 253); each nested type's partial marked |
| symbol keys | — | n/a | |
| recursive objects (`get subcategories()`) | a field typed with the record itself | have | `Category.parseAt` calls itself; no getter trick |
| mutually recursive objects | two `#[validated]` records naming each other | have | the members' name contract (`T.parseAt`, `T.__json`) |

## §§ 4.19–4.20 · Arrays and tuples

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.array(T)` | field `Array<T>` / `T[]` | have | each item at path `field[i]` |
| `.nonempty()` | `#[notEmpty]` | have | `vNotEmptyList` |
| `.min(n)` · `.max(n)` · `.length(n)` | `#[minLength(n)]` · `#[maxLength(n)]` · `#[length(n)]` on an array field | have | `#[sizeBetween]` stays |
| checks on the items (`z.array(z.email())`) | `#[each("email")]` on an `Array<T>` / `Set<T>` field | have | one marker per `#[each]`; named as text until `Decorator` is a type in a package (`language-gaps.md`); a marker with arguments waits on 267 |
| `.unwrap()` | — | n/a | |
| `z.tuple([A, B, C])` | field `#(A, B, C)` | have | JSON array of exactly that length |
| `z.tuple([A], rest)` | — | n/a (306) | `tupleRest` was a combinator; a head and a tail are two fields |
| `.partial()` on a tuple | a tuple of `?T` | native | |

## §§ 4.21–4.24 · Unions and intersections

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.union([A, B])` | field `A \| B` | have | arms in declaration order; all fail → one `invalidUnion` naming each arm's first violation |
| `.options` | `Fish.options()` for an enum | have | a union's arms are its type (306) |
| `z.xor([A, B])` | — | n/a (306) | a declared union takes its first accepting arm; "exactly one" has no declaration (nat-d4) |
| `z.discriminatedUnion("status", […])` | `#[validated] #[tag("status")] pub type Reply { Success(value: ReplySuccess), Failed(value: ReplyFailed) }` | gap | `Decl.variants` carries names, not payload fields: each payload is a `#[validated]` record named `<Enum><Variant>`, read by name (the same-named record collides with the variant's constructor) |
| `z.getDiscriminatedOption` | — | n/a (306) | an option of a schema value; the variant's payload is its own type |
| nested discriminated unions | an enum whose variant payload is another tagged enum | have | name contract (`T.parseAt`) |
| `z.intersection(A, B)` | a record with both field sets — `Type.merge(A, B)` (307) | n/a (306) | `both` was a combinator; the merge is step 5's |

## §§ 4.25–4.27 · Records, maps, sets

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.record(z.string(), V)` | field `Dict<string, V>` | have | JSON object; each member `field.key` |
| `z.record(Keys, V)` — enum keys, exhaustive | field `Dict<Fish, V>` with `#[exhaustive]` | have | every variant present (`Fish.options()`) |
| `z.partialRecord` | `Dict<Fish, V>` without the marker | have | |
| `z.looseRecord` | `#[rest]` beside declared fields | have | above |
| numeric keys | `Dict<i32, V>` | have | key text via the integer grammar |
| `z.map(K, V)` | `Dict<K, V>`, an object on the wire | n/a (306) | the pairs wire form `[[k, v], …]` was a combinator (`schemas.pairs`); no declaration says it |
| `.min` / `.max` / `.size` / `.nonempty` on maps and sets | the length markers | have | `Dict.size()`, `Set.size()` |
| `z.set(T)` | field `Set<T>` | have | JSON array; repeated item → `duplicate`, not folded |

## §§ 4.28–4.30 · Files, promises, instanceof

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.file()` · `.min` · `.max` · `.mime` | — | gap | no byte type until 346's `Bytes` (`01-checker` step 32); multipart refused with 415 today. Nearest: validate the upload's declared `name`, `size`, `type` as a record |
| `z.promise()` | — | n/a | deprecated in Zod; a `@Task` is awaited before parsing |
| `z.instanceof(Class)` | `x is T` | native | `docs.md:625-626`; a host class has no botopink type |
| `z.property(k, schema)` · `z.properties({…})` | — | n/a (306) | a check over a `Json` value; declare the shape as a type |

## §§ 4.31–4.33 · Refinements, pipes, transforms

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `.refine(fn, { error })` | field: `#[refine(rule)]` (`rule: fn(v: T) -> bool`; built as `#[check(rule)]`, renamed by 406) · `#[constraint("name")]` (have) · type: `#[check("…", rule, at: .field, code: .Custom)]` | have · add · 7 | the type-level form takes typed arguments (280) — `01-checker` step 24 |
| `.refine(…, { path })` | `#[check("…", rule, at: .field)]` | add · 7 | `01-checker` step 24 (280) |
| `.refine(…, { abort: true })` | `#[stopOnFirst]` on the field | have | default stays "every check runs" |
| `.refine(…, { when })` | the type-level `#[check]` runs only when the fields it names have no violation | add · 7 | `01-checker` step 24 (280) |
| `.refine(async …)` | — | n/a (306) | `refineAsync` was a combinator; a declared type's checks are synchronous |
| `.superRefine((val, ctx) => ctx.addIssue(…))` | the type-level `#[check]` | add · 7 | `01-checker` step 24 |
| `.check(ctx => ctx.issues.push(…))` | the same | add · 7 | one API, no slower one to bypass |
| `.pipe(schema)` | — | n/a (306) | two schema values in a row; a field's markers and transforms run in order |
| `z.transform(fn)` · `.transform(fn)` | field marker `#[map(f)]` | add · 8 | reads `f`'s parameter type — typed decorator arguments, `01-checker` step 24 |
| transform that fails (`ctx.issues.push`, `z.NEVER`) | `#[tryMap(f)]` with `f: fn(a: A) -> @Result<B, string>` | add · 8 | `01-checker` step 24 |
| `z.preprocess(fn, schema)` | `#[preprocess(f)]` with `f: fn(input: Json) -> Json` | have | |
| `.overwrite(fn)` | the transform markers of § 4.3 | have | `#[map]` when the type does not change (s24) |

## §§ 4.34–4.38 · Defaults, catch, brands, readonly

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `.default(v)` | `#[orElse(v)]` on the field — a literal or an enum variant (`.Tuna`) | have · gap | the field default (`count: i32 = 0`) is the language's form, but `Field` reflects no default (`language-gaps.md`) |
| `.default(fn)` | `#[orElseOf(f)]` — the function itself (281) | have | called per parse |
| `.prefault(v)` | `#[orElse]` on a field with transforms — the default is transformed like an input | have | one marker |
| `.catch(v)` · `.catch(fn)` | `#[fallback(v)]` · `#[fallbackOf(f)]` | have | on decode or check failure the field takes the value, **no** violation recorded |
| `.brand<"Cat">()` | two record types | native | nominal: `Cat(name: string)` is not `Dog(name: string)` |
| brand direction | — | n/a | |
| `.readonly()` | — | native | records are immutable (`docs.md:358-368`) |

## §§ 4.39–4.43 · JSON, functions, custom, apply, existing types

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.json()` | field `Json` | have | |
| `z.function({ input, output })` · `.implement` | — | n/a | parameters typed by the signature; a runtime check is `Args.parse` at the calling boundary |
| `z.custom<T>(fn)` | — | n/a (306) | a schema value from a function; a field of a declared type with `#[preprocess]` / `#[check]` says it |
| `.apply(fn)` | — | n/a (306) | no schema value to compose |
| `z.toZod<Player>()` | — | native | the schema is `Player`; cannot drift |

## § 5 · Customising errors

| Zod | botopink | Box | Notes |
|---|---|---|---|
| check-level message (`.min(5, "Too short!")`) | `#[message("…")]` after the marker it restates | have | a marker's arity is fixed, so one more marker |
| schema-level message (`z.string("Not a string!")`) | `#[typeMessage("…")]` on the field | have | restates `invalidType` |
| error map as a function | `MessageSource(locale, template)` | have | `messages.bp:35-38` |
| `iss.code` · `iss.input` · `iss.path` · `iss.minimum` … | `{field}` `{value}` and the marker's own parameters, by name | have | `messages.bp:96-114` |
| per-parse error map (`.parse(x, { error })`) | `messages.underSource(source, { -> Player.parse(doc) })` | have | a `MessageSource` for one call, under field-level messages |
| `reportInput: true` | `Violation.invalidValue` is always carried; `toJson` never writes it | have | `report.bp:81-93` — the reflected-input rule |
| `z.config({ customError })` | `setMessageSource(source)` | have | `messages.bp:55-57` |
| `z.config({ localeError })` — `z.config(en())` | `setMessageSource(locales.ptBR())` | have | `locales.en()` (the built-in table), `ptBR()`, `es()` |
| `z.config({ jitless })` · `memoizer` · `postProcessor` | — | n/a | no runtime code generation to disable |
| resolution order (check → schema → per-parse → global → locale → fallback) | `#[message]` → `#[typeMessage]` → `underSource`'s source → `setMessageSource` (locale key, then bare key) → `builtInTemplate` | have | `test/message_order_test.bp`, six levels |
| 58 shipped locales | `en`, `ptBR`, `es` shipped; the rest are one function each | have | a locale is data; `105-i18n` owns negotiation |

## § 6 · Formatting errors

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.treeifyError()` | `report.tree()` → `ReportTree(errors, properties, items)` | have | built from `field`'s path |
| `z.prettifyError()` | `report.pretty()` | have | `✖ <message>` / `  → at <path>`, byte-identical on both targets |
| `z.flattenError()` | `report.flatten()` → `Flat(formErrors, fieldErrors)` | have | keyed by first path segment; an undeclared key is form-level |
| — | `report.toJson()` · `report.toProblemDetail()` | have | RFC 9457 (`report.bp:51-69`) |

## § 7 · Metadata and registries

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `.meta({ title, description, examples, deprecated })` | `#[title("…")]` · `#[describe("…")]` · `#[example("…")]` · `#[deprecated]` on a type or a field | have | reach the JSON Schema |
| `.describe("…")` | `#[describe("…")]` | have | |
| `z.registry()` · `.register()` | `spi.registerSchema(id, { -> T.jsonSchema() })` | have | host table beside the constraint registry |
| `z.globalRegistry` with `id` | `#[schemaId("User")]` — the document's `$id` | have | |
| typed registries (`z.registry<Meta, ZodString>()`) | — | n/a | one metadata shape |

## § 8 · JSON Schema

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.toJSONSchema(schema)` | `T.jsonSchema() -> string` | have | beside `T.constraints()`, kept as the compact table |
| `target` (draft-04 · 07 · 2020-12 · openapi-3.0) | `T.jsonSchema()` is 2020-12; `table.toDraft07(…)` · `table.toOpenApi30(…)` rewrite it | have | draft-04 not written |
| `metadata` | the markers of § 7 | have | |
| `unrepresentable` | a marker with no keyword (`#[check]`, `#[preprocess]`, a walk format) is a **compile error** under `#[jsonSchema]`, and `{}` without it | have | decision 67: no silent `any` where asked |
| `cycles: "ref"` · `reused: "ref"` | the document's own type is `{"$ref": "#"}`, another `#[validated]` type `{"$ref": "#/$defs/<Name>"}` | have | one form; recursion needs it |
| `io: "input" \| "output"` | the output; the input form not written | add · 9 | `inputJsonSchema` for `#[coerce]` / `#[preprocess]` fields — not a box; not added in this pass |
| `uri` | `table.withRefBase(doc, "https://…/")` | have | `base + id + ".json"` |
| `override` | — | n/a | the document is a string the caller may rewrite |
| format mapping (`email` → `format: "email"`, `base64` → `contentEncoding`, the rest → `pattern`) | the same table, from the marker | have | § 8.3's rows; a walk-checked format with no pattern is unrepresentable |
| `additionalProperties: false` | written unless the type carries `#[stripUnknown]` or a `#[rest]` field | have | |
| `z.fromJSONSchema()` | — | n/a | generating declarations from a document is a CLI generator, not a library call — out of this front |
| `z.toJSONSchema(z.globalRegistry)` | `spi.registeredJsonSchemas()` | have | `{"schemas": {…}}`, a `$ref` by id |

## § 9 · Codecs

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.codec(In, Out, { decode, encode })` | `#[codec(decode: f, encode: g)]` on a field | add · 8 | reads `f`'s parameter type — `01-checker` step 24 |
| `.decode()` · `.encode()` | `T.parse` · `T.encode(v) -> @Result<Json, ValidationReport>` | have | every `#[validated]` type |
| `.safeDecode` · `.decodeAsync` · `.encodeAsync` | the `@Result` returns | have | async is n/a (306) |
| `z.invertCodec` | — | n/a (306) | a codec value; a field's `#[codec]` names both directions |
| composability (codecs inside objects and arrays) | a field with `#[codec(…)]` | add · 8 | `01-checker` step 24 |
| refinements run in both directions | `T.encode` runs `validate()` first and answers `@Result` | have | |
| the recipe list — `stringToNumber`, `stringToInt`, `stringToBigInt`, `isoDatetimeToDate`, `epochSecondsToDate`, `epochMillisToDate`, `jsonCodec`, `base64ToBytes`, `hexToBytes`, `stringToURL`, `stringToHttpURL`, `uriComponent`, `stringToBoolean` | `codecs.textToInt` · `textToLong` · `textToFloat` · `isoToMillis` · `secondsToMillis` · `jsonText` · `base64Text` · `base64urlText` · `hexText` · `textToUrl` · `uriComponent` · `textToBool` | add · 8 | `utf8ToBytes` / `bytesToUtf8` are **gap** until 346's `Bytes` (`Bytes.fromUtf8` / `toUtf8`) |

## § 10 · AOT compilation

| Zod | botopink | Box | Notes |
|---|---|---|---|
| `z.compile(schema)` — a flat, loop-free validator generated ahead of time | `#[validated]` | native | the only mode: the decoder is emitted at compile time as straight-line botopink |
| `import "zod/compile"` | — | n/a | |
| unsupported constructs fall back silently | — | n/a | nothing falls back; a combinator schema is ordinary code |
| `strict: true` | — | n/a | |
| CSP / `jitless` | — | n/a | no `new Function` on either target |

## §§ 11–13 · Ecosystem, library authors, packages

| Zod | botopink | Box | Notes |
|---|---|---|---|
| Standard Schema — "accept any schema" | a parameter taking the type (`comptime source: type T`, refused unless `@typeInfo(T).meta(Validated)` — 298) | add · 12 | until then a parse function (`onze-content`'s `defineCollection(name, loader, { d -> T.parse(d) })`) |
| tRPC-style typed endpoints, form libraries | `08-bpp/127-bpp-actions` | — | the consumer, not this front |
| Zod → OpenAPI | `table.toOpenApi30` | have | |
| mock-data generators | — | — | not in the reference's core; no row |
| Zod Classic (methods) vs Zod Mini (functions) | one API: the type's members | n/a (306) | no schema value, no `checks.*` |
| `mySchema.isOptional()` · `.isNullable()` | the field's type (`?T`) | n/a (306) | reflection reads the type (`@typeInfo`) |
| `mySchema.clone(def)` · `_zod.def` · `_zod.run` | `@typeInfo(T)` | add · 12 | `fields` is `typeinfo-unknown-member` today (`01-checker`) |
| `z.$ZodType` hierarchy, v3/v4 dual support, peer dependencies | — | n/a | one version per `dependencies` entry (a repository of its own, decision 326) |

---

## Count

209 rows by the Box column's first word (a partly shipped row counts as what it already is), after
steps 0–12:

| Box | Rows |
|---|---|
| native | 10 |
| have | 136 |
| add (not landed — the row names its blocker) | 20 |
| gap (nearest form shipped, row filed) | 4 |
| n/a (306) | 17 |
| n/a | 20 |
| consumer or out of the reference's core (`—`) | 2 |

The `add` rows wait on `01-checker` step 24 (typed decorator arguments: `#[map]`, `#[tryMap]`,
`#[codec]`, the type-level `#[check]`), `01-checker` step 28 and 134 step 4 (std's `Type`: pick,
omit, partial, required, merge, keys), `@typeInfo(T).fields` and 298's `meta(Validated)` (reflection,
a library taking the type), or are not boxes of the front (`io: "input"`). The gaps: wire names and
payload fields of variants (`Decl.variants`), field defaults in reflection (`Field`), `z.file` and the
byte codecs (no byte type) — each a [`../../language-gaps.md`](../../../language-gaps.md) row.

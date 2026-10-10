# Front 146 — validation: Zod's feature set — the residue

**Priority:** high — the library tier (decision 433); runs after the 144 steps it names.
**Owns:** `repository/validation/**`
**Depends on:** 144 B-10 G1 (12 markers go), B-16 (derived types, `Type.Field<T>`), B-19 (298, `@typeInfo(T).fields`)
**Does not touch:** `repository/botopink-lang/**` — a compiler or std gap is a `language-gaps.md` row and this
front pauses on the 144 step that fixes it (fronts.md rules 1, 9); another library's files except a consumer
commit (decision 188), producer first.
**Gate:** standard (fronts.md § Gate); a moved block keeps its own `**Gate:**` additions.

Left by 125 (status.md): `#[tag]`'s refusal and `#[wireName]` (B-10 G1, `Decl.variants`); the type-level
`#[check]`, `#[map]` / `#[tryMap]` / `#[codec]`, the signature refusals (B-16); `Type`'s derived types (B-16);
reflection by `@typeInfo(T).fields` and 298 (B-19). typed-member-395's validation patch is landing. 105 edits
`messages.bp` between two steps of this front, never during one. Consumer commits it receives: B-02, B-08 (17),
B-20 (the 330 codemod), 142 s1 (`json`).

## Alias table

Old ids stay valid in `decisions-taken.md`'s *Where* column, `language-gaps.md`'s owners and the
closed records: each resolves here. A "box n" counts the old step's open boxes, in order.

| Old id | Step here |
|---|---|
| `125-validation-zod` open | 146 s1 |
| `125-validation-zod` gate | 146 s1 |
| `97-std-dedupe` s2 residue box 1 | 146 s2 |

## Steps

### 146 s1 — what is left of 125's steps 4–12, and the examples as suite cases

- [ ] 125 step 7's typed-member route lands in validation (decisions 370, 384, 385, 395, 404, 406): a type-level
      `#[check("…", rule)]` records `Check<T>(message, rule)` as typed meta, `#[validated]` hands on the member
      `__typeChecks` running every one through `for (comptime @typeInfo(T).metaAll(Check))`, `validate()` (so
      `parse`, `decode`, `encode`) appends its violations after the field checks, `#[check]` on a field refused naming
      `#[refine]` — built as validation's patch on `front/typed-member-395` (the compiler half is on botopink-lang
      `feat`, `9bfbed18`), held: on erlang `test/refine_and_messages_example_test.bp`'s case "decode runs the
      type-level rules…" fails while another test module's `Signup` answers `Signup.decode` · 144 B-10 G1 (the
      cross-module type-name fix, structural, decision 430)

#### Open (was `125-validation-zod` open)

Decision 325 (07-j) fixed the scope: every step, in order. What is left of steps 4–12, with what it
waits on:

| Step | Box | Waits on |
|---|---|---|
| 4 | `#[tag]` on an enum whose variant has no payload record is a compile error at the annotation (today it fails where the emitted code names the record) | the **`Decl.variants`** gap row (payload fields not reflected) |
| 5 | `derived-types-example.bp` passes; `#[validated] pub val RecipePatch = Type.partial(Recipe);` decodes with every field optional, keeps `Recipe`'s markers, and is imported and constructed by a second module | `01-checker` step 28 (`Type`'s calls answered) · 134 step 4 (`pick` / `omit`, decision 267) |
| 7 | the type-level `#[check("…", rule, at: .field, code: .Custom)]` and `#[check("…")]` on the rule (406: `message` first, required; `#[check]` on a field refused, naming `#[refine]`); a `#[check]` naming a missing function, a missing field (`.confrim`) or a rule of another signature fails at that argument; one on a rule outside the type's module refused; several on one type are one `validate` — each `#[check]` an `addMeta(Check(…))`, `#[validated]` the member reading `metaAll(Check)` (404) | `01-checker` step 24 (280) |
| 8 | `#[map(f)]`, `#[tryMap(f)]`, `#[codec(decode: f, encode: g)]` — they read `f`'s parameter type | `01-checker` step 24 (280 (2)) |
| 11 | `#[wireName("salmon")]` on each variant | the **`Decl.variants`** gap row (annotations of variants) |
| 12 | a located refusal for a field marker's function of the wrong signature (`#[preprocess]`, `#[check]`; `#[map]`, `#[tryMap]`, `#[codec]` with them) | `01-checker` step 24 |
| 12 | reflection reads the type — `@typeInfo(T).fields`, `@typeInfo(T).meta(Validated)` — and a library takes the type (`comptime source: type T`) | `@typeInfo(T).fields` (`typeinfo-unknown-member`, `01-checker`) · 298 |

Step 3 touches step 24 in one place: `#[gt]`, `#[lt]` and `#[multipleOf]` declare their bound
`comptime value: f64` and `#[validated]` gives it the field's type from the lexeme (`5` → `5.0` on an
`f64` field, a fraction refused on an integer one); under 280 (2) the bound is `@Decl<T>`'s `T` —
step 24's migration of the markers rewrites those three signatures, `#[orElse]` / `#[fallback]`'s
values (step 11) and `#[validated]`'s run-time `form` (a comptime parameter takes no default —
`language-gaps.md`).

#### Gate additions (was `125-validation-zod` gate)

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `--target commonJS`
green and `botopink format --check src test` clean in `repository/validation`
- [x] rakun's two `#[validated]` consumers still green — the name contract `validate()` /
      `constraints()` (decision 216) did not move (rakun core 375 / 0 on erlang, with the consumer
      patch); `zig build test-libs` itself is the cold gate's
- [ ] every file under `examples/` is a suite case — eleven of twelve; `derived-types-example.bp`
      waits on `01-checker` step 28

### 146 s2 — no `Json` accessor copy left (97 s2 residue)

#### Step 2 residue — no `Json` accessor copy left in the library repositories — part (was `97-std-dedupe` s2 residue box 1)

The copies left the compiler with their libraries (138); each is its owner's step (§ Consumers):

- [ ] `repository/validation/src/derived.bp`'s `pub fn membersOf(j: Json)` (a one-line wrapper of
      `j.members()`, named by `#[validated]`'s emitted code, `decorators.bp` `encRest`) and
      `formats.bp`'s private `isObject` — `125-validation-zod` step 2 residue
- Not copies: `routing/src/segment.bp`'s `kindName(k: SegmentKind)`, `log/test/reports_test.bp`'s
  `fieldOf(r: LogRecord, …)`, `rakun-app/test/navigation_test.bp`'s `kindName(out: NavOutcome)`; the
  kind tests std's `Json` does not carry (`onze/src/config.bp` `isString`, rakun's `isArray` /
  `isText` / `isNum`) wait on step 15's readers

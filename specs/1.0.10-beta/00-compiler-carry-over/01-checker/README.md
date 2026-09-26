# Front 01 — checker

**Priority:** critical — it is the only front of this milestone that four other fronts read from.
Decision 8's grammar parses and nothing types it, so `unknown`, unions, `is` and every `case` arm
written in the decided spelling are accepted as syntax and refused as types
**Depends on:** nothing. It runs from the first day
**Owns:** `modules/compiler-core/src/comptime/{infer,types,unify,env,transform,eval,error}.zig` ·
`modules/compiler-core/snapshots/comptime/**` · `modules/compiler-core/src/parser/{decls,exprs,patterns}.zig`
(steps 4 and 10) · `libs/std/**` and `examples/**` (step 11 only)
**Does not touch:** `src/codegen/**` — every backend file belongs to
[`02-erlang`](../02-erlang/README.md), [`03-beam`](../03-beam/README.md),
[`04-js`](../04-js/README.md), [`05-wasm`](../05-wasm/README.md) · `modules/compiler-cli/**` ·
`modules/language-server/src/**` · `src/utils/snap.zig`, `src/comptime/snapshot.zig` and the test
harness

Paths are relative to `repository/botopink-lang/` unless a row says otherwise. Every `file:line`,
count and output below was measured against `botopink-lang` `c2dd780` on 2026-09-18 — the command is
given with the number.

---

## Problem

Decision 8's grammar landed in `d0c27f6` (`unknown` as a keyword, `A | B` types, `x is T` as an
expression, `Pattern { body }` arms with `when`, `1...9`, `.Variant`, labels and `..`). None of it is
typed. Each commit said so at its definition site; this is what the compiler answers today
(`zig-out/bin/botopink check` on a one-module project, `c2dd780`):

```
val a: unknown = 42;                          → type mismatch: expected unknown, got i32
val v: i32 | string = 1;                      → type mismatch: expected |, got i32
val b: bool = a is i32;                       → type mismatch: expected bool, got void
case s { .Circle(r) { r } .Rect(w) { w } }    → non-exhaustive `case` on 'Shape':
                                                missing variant(s) Circle, Rect
case x { 0 { "zero" } _ { n -> "other" } }    → type mismatch: expected string, got function
```

and this is what it still accepts:

```
case x { 0 { "zero" } 1 { "one" } }           → Checked   (literal arms, no `_`, on i32)
fn get(b: Box) -> i32                         → Checked   (Box<T> written without its argument)
fn get(self: Self) -> T   in a type Box<T>    → Checked   (bare Self, §1.2)
fn connect(host: string, port: i32 = 80)      → 'connect' expects 2 argument(s), got 1
val n = 5; val x: n = 7;                       → Checked   (a value binding as a type)
#[@external(node, "Math.abs($0)")]            → Checked, binds no host, no diagnostic
fn f() -> i32 { val x = 1; }                   → Checked   (decision 2: no value, non-unit return)
```

## Current state

`zig build test-language` at `c2dd780`: **205 passed, 54 expected failures, 0 failed**. **31** of the
54 lines name a row of this front; of the other 23, 7 are [`02-erlang`](../02-erlang/README.md)'s,
7 [`04-js`](../04-js/README.md)'s, 4 [`05-wasm`](../05-wasm/README.md)'s, 2 belong to
[`13-module-identity`](../13-module-identity/README.md) (§7's record and variant text) and 3 to [`10-cli-residuals`](../../../1.0.5-beta/10-cli-residuals/README.md). The 31 are listed
in [Acceptance — the `expected-failures.txt` lines this front deletes](#acceptance--the-expected-failurestxt-lines-this-front-deletes)
and they are this front's acceptance: a step is done when its lines are gone and the suite is still
`0 failed`.

What front 06 of 1.0.4-beta landed, and is **not** to be re-opened — each re-probed at `c2dd780`:

| Row | Probe at `c2dd780` | Verdict |
|---|---|---|
| C1 `return` unified with the declared return type | `fn f() -> i32 { return "s"; }` reds | closed |
| C2a/C2b `case` typed from its arms, `comptime` block from its `break` | `val a: bool = case 42 {…}` reds | closed |
| C3 operand orientation, arithmetic operands | `1 && true` reds `expected bool, found i32` on `1`; `"a" * "b"`, `-"s"` red | closed |
| C5 type guard typed `bool` | `if (isStr(y)) { val s: string = y; }` on `y: ?string` **checks** | closed (N3 with it) |
| C8 pattern bindings typed, N28 sections | `A(v) -> f(v)` reds | closed |
| C9 method bodies strict | `d.swim()` reds; an unannotated method's return type is stored | closed |
| C10 + N30 unknown type names | `record Q { lat: bogusType }` reds **at the annotation** | closed |
| C12 `val assert` | `val assert 42 = answer catch 0;` with `answer` unbound reds | closed |
| C12 pipeline half | `val r: i32 = 1 \|> double;` **checks**; `1 \|> add(1, 2)` for 2-ary `add` reds at the RHS | closed — the 1.0.4 spec still lists it as open; it is not |
| C4b, C6, C7, C11, N4/N23, N17, N26, N27 | G0 (`13f61fa`, `ada3911`, `cab0bf7`) | closed |
| N9 `┌─` box with no file name — **the CLI half** | `botopink check` prints ` --> src/main.bp:5:12` | closed in the CLI renderer, **open in the snapshot renderer** — step 9 |
| N13 an undeclared name passes the check | reds at the name | closed |
| N24 tuple labels | `r.current` on `fn ref<T>() -> #(current: T)`; `c.set(9)` on a fn-typed element | closed |
| N25 effect wrapper ↔ annotation | `-> @Result` without its effect annotation reds | closed except three diagnostics — step 8; the annotation itself leaves with C-32 (decision 118) |

The rows below reproduce. Nothing in this front is carried on trust.

## Mechanism

Two mechanisms produce the whole of steps 1–6, and they are the two the 1.0.4 spec named M1 and M2
with the instances renamed:

| # | Mechanism | Where | Rows |
|---|---|---|---|
| **G1** | **Decision 8's grammar landed as a reserved spelling, not as a type.** `unknown` is `TypeRef.named` under `ast.unknown_type_name`; a union is `TypeRef.generic` under `ast.union_type_name` (`"\|"`); `x is T` is the `is` builtin call with the type in the call's `isType` slot. Each was deliberately written that way — a new `ast.TypeRef` variant does not compile without edits to `comptime/infer.zig`, `codegen/typescript.zig`, `format.zig` and the language server. Inference has never been taught any of the three, so it compares the spelling nominally: `expected unknown`, `expected \|`, `expected bool, got void` | `comptime/infer.zig`, `comptime/types.zig`, `comptime/unify.zig` | N19, N20, N21 |
| **G2** | **An arm's shape is not read back.** The `Pattern { body }` arm lands as the same lambda node the older block arm produced, and the dot shorthand keeps its leading `.` inside the pattern's name. Inference reads neither: it unifies the arm with a `function` type, and `.Circle` is matched against the variant table as the literal name `.Circle`, which no variant carries | `comptime/infer.zig` — the `case` arm walk and `bindPatternNamesForSubject` | N22, §5.4 |

The remaining steps are unrelated single rows; each carries its own site.

## Steps

Steps 1–5 are decision 8's inference and land in that order: §3 needs §2's assignability rule, §4
narrows into a union, §5's arms resolve against what §4 tests, and exhaustiveness counts what §5
resolved. The full row-by-row statement, in decision 8's own words with the probe for each, is
[`decision-8-inference.md`](./decision-8-inference.md); the rest is
[`residual-rows.md`](./residual-rows.md); the counts are [`blast-radius.md`](./blast-radius.md).

### Step 1 — `unknown` is a type (N19, decision 8 §2)

`unknown` reaches inference as `TypeRef.named` spelled `ast.unknown_type_name`, and unifies
nominally: nothing goes in and nothing comes out. §2 is the opposite — everything goes in, nothing
comes out unchecked.

| §    | Rule |
|---|---|
| 2.1 | every type is assignable **to** `unknown`; `unknown` is assignable to nothing but `unknown` |
| 2.2 | allowed: `@print`, `==`, `!=`, assignment to `unknown`, passing to a generic (`T = unknown`). Refused, each with a location: arithmetic, field access, indexing, method calls |
| 2.3 | `==` / `!=` with an `unknown` operand compares numbers by value (the run-time half is each backend's) |
| 2.4 | a `pub` declaration whose **inferred** type contains `unknown` is an error; a written `unknown` is fine |
| 1.4 | a non-`pub` binding that falls to `unknown` gets a warning naming the annotation to write |
| 2.5 | there is no `any` |

**Acceptance:**
- [x] `val a: unknown = 42;` checks and `val y: i32 = a;` reds with a location naming `is` — re-verified at `ffe2db69`: "an `unknown` value cannot be used as another type without testing it", hint `if (x is i32) { … }` (`unify.zig`)
- [x] `a + 1`, `a.x`, `a[0]`, `a.len()` each red at the operation; `@print(a)` and `a == 2` check — re-verified at `ffe2db69` (`a[0]` reds as the method call it is under C-02)
- [x] `pub fn f() { … }` whose inferred return contains `unknown` reds; `pub fn parse(s: string) -> unknown` checks — compiler `bdbbeae6`: a `pub val` with no written type inferred as containing `unknown` is refused at the value. A `fn`'s return is written, never inferred (§1.1): an unannotated `fn` is `void`, so the `fn` half has nothing to infer — a `return <value>` from an unannotated fn is R7's (decision 2) row
- [x] `var out = [];` warns and names `var out: i32[] = [];` — compiler `bdbbeae6` (decision 57's channel; `botopink check` prints `warning: … annotate it: `var out: i32[] = [];``). Only the `[]` birth is built; the rest of §1.4 (a type argument never decided by a later use) is not — see `comptime/AGENTS.md`
- [x] `reject/case_unknown_without_wildcard.bp` and `reject/case_shorthand_on_unknown.bp` are rejected for **their own** reason (step 5 finishes them) — the first by exhaustiveness (already at `ffe2db69`), the second by "`.Some` on an `unknown` value names no enum — write the variant's full name" (compiler `bdbbeae6`; it had come to check clean); its line left `expected-failures.txt`

### Step 2 — union types (N20, decision 8 §3)

A union reaches inference as `TypeRef.generic` named `"|"` with its members as arguments, and
`unionMembers()` reads them back. Give it a type kind, an assignability rule and a join.

| § | Rule |
|---|---|
| 3.1 | `A \| B` in every type position; `(i32 \| string)[]` is an array of the union, `i32 \| string[]` is an `i32` or an array of `string` — the grammar already binds it that way |
| 3.2 | inferred from array literals, `if` branches and `case` arms, **with no error**; a branch that `return`s / `throw`s / `break`s does not contribute; `1` and `null` give `?i32`; `[1, 2.5]` gives `f64[]` |
| 3.3 | a use is allowed only when every member allows it, else narrow first; a `case` covering every member needs no `_` |
| 3.4 | join `Option<A> \| Option<B>` → `Option<A\|B>`, same for `Box`, `@Result`, `Dict` (key and value); **arrays never join** |
| — | the misuse is reported **at the use**, pointing at the branch that widened it (§3.2's diagnostic sketch) |

**Acceptance:**
- [x] `val v: i32 | string = 1;` checks; `val n: i32 = v + 1;` reds at the use and names the widening branch — it checks and reds at the use; for an INFERRED union the message names the `if`/`case` that widened it (compiler `9475bbf1`; an annotated union has no widening branch to name)
- [x] `val v = if (c) { 1 } else { "a" };` checks with no error and `v` is `i32 | string` — re-verified at `ffe2db69`
- [x] `i32[] | string[]` does not unify with `(i32 | string)[]` — re-verified at `ffe2db69` (type mismatch at the value)
- [x] `test/case_exhaustive.bp` compiles on commonJS and erlang — no line left in `expected-failures.txt`; green in `run.sh --target all`

### Step 3 — `is`, narrowing and the always-false warning (N21, decision 8 §4)

The `is` call is typed `void`. Type it `bool`, narrow the tested binding inside the branch and inside
the guarded arm's body, and convert an integral `f64` to the tested integer type inside the block.

| § | Rule |
|---|---|
| 4.1 | numbers by range, not by origin: `2.0 is i32` is true, `2.5 is i32` is false, `x is f64` is true for any number; inside the block the value **is** the tested type |
| 4.2 | what may follow `is`: a primitive, a named type's constructor, `#(…)` (arity + each element), `Box<unknown>` (`Box<i32>` is an error — the argument is not checkable). `Option.Some(v)` binding a payload is refused by the parser today (`is-variant-binding`); a payload is read in a `case` arm — decide whether `is` grows a pattern or the refusal stands |
| 4.3 | `a is string` on a statically-known `i32` is a **warning**, always false |
| — | narrowing also applies through `&&` (step 10's grammar), through a `when (…)` guard into that arm's body (§5.3), and through the type-guard fn form `-> x is T`, which already narrows (C5) |

**Acceptance:**
- [x] `val b: bool = a is i32;` checks; `if (a is i32) { @print(a + 1); }` checks with `a: unknown` — re-verified at `ffe2db69`
- [x] `val a: i32 = 1; a is string` warns "always false" with a location, and still checks — compiler `bdbbeae6` (`warnAlwaysFalseIs`, decision 57's channel)
- [x] `x is Box<i32>` reds naming §4.2; `x is Box<unknown>` checks — re-verified at `ffe2db69` ("`is` cannot test the type argument of `Box`")
- [x] the `is` residual of §4.2 (a pattern after `is`) is decided and the decision is written in [`decision-8-inference.md`](./decision-8-inference.md) — decision 25 of 1.0.5 (b): `is` answers a `bool`, `case` is the only construct that binds; the parser's `is-variant-binding` refusal stands

### Step 4 — `case` arm resolution (N22, decision 8 §5, §5.3b)

Four independent defects behind one row. Each reproduces on its own.

| # | Defect at `c2dd780` | Probe |
|---|---|---|
| a | a **lambda-shaped arm body** is unified as a `function` | `case x { 0 { "zero" } _ { n -> "other" } }` → `expected string, got function` |
| b | a **dotted or shorthand variant path** is not resolved against the matched value's type | `case s { .Circle(r) { r } .Rect(w) { w } }` → `missing variant(s) Circle, Rect` |
| c | **labels, `rest` and arity** in a variant payload are not checked (P4, P7) | `reject/case_arity_without_rest.bp` is rejected, but not by the missing-field diagnostic |
| d | a **section** of an enum-shaped `type` is not a type named by its path, and a section value does not write in the leading-dot form either (N28's value side, N29) | `type Token { Text { Bold, Italic }, … }`: `Token.Text.Bold` → `unknown field 'Bold' on type 'Token'`; `val t: Token.Text = .Bold;` → `unbound variable 'Bold'` |

P3 is the rule to implement for (a): the arm body is a **lambda body** — its last expression is the
arm's value — and `{ n -> … }` binds the whole matched value, already narrowed (P1, P5). Matching
into a section (`case t { Text(Bold) { … } }`) is a **refinement**, never coverage (§5.3b) — step 5
depends on that distinction.

The parser half of (d) is this front's too: a section body carrying a `fn` does not parse, and
`EnumSection` has no method slot. §5.3b leaves that unimplemented on purpose — do not add it here.

**Acceptance:**
- [x] `test/case_tuples.bp`, `test/case_guards.bp`, `test/case_variants.bp`, `run/case_values.bp` and `test/case_sections.bp` compile and run on commonJS and erlang — none has a line left; green in `run.sh --target all` at `ffe2db69`
- [x] `reject/case_missing_variant.bp` is rejected **because `Rect` is missing**, not because `.Circle` does not resolve — "missing variant(s) Rect"
- [x] `reject/case_arity_without_rest.bp` names the missing field — "missing required field 'height' on type 'Rect'"
- [x] `val t: Token.Text = .Bold;` checks, `Token.Text.Bold` checks, and a `case` over `Token.Text` is exhaustive on its own members with no `_` — compiler `909acc34` (`val w: Token.Text = Token.Text.Italic;` too); `run/section_path_resolution`

### Step 5 — exhaustiveness (decision 8 §5.4)

Exhaustiveness is checked (`infer.zig`, the `case` walk), but only over enum variants, and it counts
an arm the moment its pattern names a variant.

| Situation | Today at `c2dd780` | §5.4 |
|---|---|---|
| a guarded arm | **counted** — `case x { i32 when (x > 0) { … } i32 when (x <= 0) { … } }` compiles | never counts; `_` required |
| literal arms only on `i32` / `string` | **not checked** — `case x { 0 { … } 1 { … } }` compiles | `_` required |
| the matched value is `unknown` | reaches step 1's assignability first | `_` required |
| every union member covered | no union type exists yet | no `_` |
| a type covered whole (`i32 { … }` on an `i32`) | — | no `_` |
| a refinement into a section (`Text(Bold)`) | — | does **not** cover `Text` (§5.3b) |

**Acceptance:**
- [x] `reject/case_only_guarded_arms.bp` and `reject/case_literals_only.bp` are rejected, each with a located message naming `_` — re-verified at `ffe2db69`
- [x] `reject/case_unknown_without_wildcard.bp` is rejected **by exhaustiveness over `unknown`**, not by assignability — "`case` on 'unknown' is not exhaustive"
- [x] a `case` covering every member of a union needs no `_`; a `case` whose only coverage of a section is a refinement still needs one — re-verified at `ffe2db69` (`Text(Bold)` alone: "missing variant(s) Text")

### Step 6 — generics §1.1 and §1.2 (N18)

A written generic type without its arguments, and a bare `Self` inside a declaration with type
parameters, both check (exit 0).

**Acceptance:**
- [x] `fn get(b: Box) -> i32` reds "`Box` needs 1 type argument"; `Pair<i32>` for a 2-parameter `Pair` reds with both counts — compiler `e7f1af11`
- [x] inside `type Box<T>`, `self: Self` reds and names `Self<T>`; inside `type Point(x: i32)`, `Self` stays right — `e7f1af11` (`Self<…>` in a plain declaration is refused as well)
- [x] §1.2's A1 rule: a non-generic type implementing a generic behavior writes `Self` and binds the behavior's parameters to the implementation's arguments — `Point(x: 1).map({ x -> "a" })` reds, `Box(value: 1).map({ x -> "a" })` checks as `Box<string>` — `e7f1af11`, pinned by `comptime/tests/infer_errors.zig` `generics: …`
- [x] `reject/generic_missing_argument.bp` and `reject/self_without_argument.bp` are rejected — their lines left `expected-failures.txt`; the `.expect` columns corrected to the caret every annotation diagnostic uses (5:11, 5:22)

**Sibling libraries under the rule** (measured with `botopink-lib-test` over a scratch copy of the five
repositories, `feat` binary against this one: 50 → 46 passing cells, the 4 new reds all erika's).
`erika` writes bare `Self` 39 times in `Query<T>` / `Grouping<K, V>`; the mechanical migration is
[`erika-self-migration.patch`](./erika-self-migration.patch) (`patch -p1` from the erika checkout) and
with it `modules/erika` is 31 / 31 on commonJS and erlang and `examples/erika-linq` runs on both. It
lands with erika's own front (`09-ecosystem-residuals`, C-14) before this front merges; jhonstart,
rakun, emilia and onze are unaffected.

### Step 7 — arity and trailing defaults (N1, N2)

`transform.expandTrailingDefaultsWithParams` is complete and unreachable: inference reds the call
before the transform runs. The analysis, the nine arity-check sites and the one that is already
correct (the decorator-application check, `required ≤ args ≤ params.len`) are carried whole in
[`trailing-defaults.md`](./trailing-defaults.md).

**Acceptance:**
- [x] a free fn, a record constructor and an instance method each accept a call that omits a trailing default, and the injected argument reaches codegen through `transform.zig` — landed as C-04; re-run at `ffe2db69`: `80` / `0` / `6` on commonJS and erlang
- [x] a missing **required** argument still reds (diagnostic D3) — "'connect' expects 2 argument(s), got 0"
- [x] `type P(x: i32 = 0, y: i32)` then `P(y: 2)` checks and `x` is `0` at run time
- [x] `test/fn_defaults.bp` passes on commonJS and erlang — no line left

### Step 8 — the rows other fronts handed over, and the checker's own tail

Each reproduces; sites and probes in [`residual-rows.md`](./residual-rows.md).

| # | Row | Probe at `c2dd780` |
|---|---|---|
| R1 | **Landed** (C-19 for the three live builders; compiler `ddeb887f` deleted `buildStructDeclName` with the rest of the `StructDecl` path, which nothing called). **A `type` declaration's constructor binding is named `record { … }`** — and its three siblings name `struct {`, `enum {` and `interface `, surfaces front 12 deleted. `infer.zig:1832` `buildRecordDeclName`, `:1859` `buildStructDeclName`, `:1891` `buildInterfaceDeclName`, `:1936` `buildEnumDeclName` | read at `c2dd780`; hover and completion print a surface that no longer parses |
| R2 | **Landed.** `import { User, makeUser }` with `User(role: Role)` checks and runs without naming `Role`: the import registers the types the declaration mentions (fields, variant fields, method signatures, transitively) as types only — `Role(…)` still needs `Role` in the clause. The caret half has no probe left (the probe no longer reds) | cell: `tests/language/modules/import_type_closure` |
| R3 | **Landed** — `reject/external_lowercase_target.bp` is rejected ("external target", 4:3) and has no `expected-failures.txt` line; re-run at `ffe2db69`. **`#[@external(node, "…")]` in lower case passes `check` and binds no host**, silently. Only `External.<Target>` matches `FnDecl.isExternal` | `#[@external(node, "Math.abs($0)")] declare fn absVal(x: i32) -> i32;` → `Checked` |
| R4 | **Landed.** A behavior-typed parameter or constructor field accepts an implementer, directly or through `extends` (`unifyArgument`); a non-implementer reds at the value | cells: `comptime/tests/infer_errors.zig` `behavior-typed field …` |
| R5 | **Landed.** `val Circle(r) = s;` binds `r` typed when the pattern cannot fail (one-variant `type`, record constructor, spread-only list); a refutable one is `refutable-val-pattern` at the binding, naming `val assert` and `case` | cells: `comptime/tests/infer_errors.zig` `val destructure: …` |
| R6 | **Landed.** `Array.range(0, 3)` resolves through its behavior's name and types `array<i32>`, so `.map` records its lowering; erlang emits `lists:map(…, array_range(0, 3))` and prints `[2, 3, 4]` — no `'__bp_prim_map'` | cell: `comptime/tests/infer_errors.zig` `associated fn: …` |
| R7 | **Landed** (compiler `ddeb887f`): both probes red with a location; `reject/fn_falls_off_end`, `reject/if_without_else_value`; `docs.md` § fn and § If / else state the rules. **Decision 2 is not enforced** (1.0.4 N6): a valueless block in value position and a non-`unit` fn that falls off its end both check | `fn f() -> i32 { val x = 1; }` → `Checked`. This is what makes the four backends' block-as-value lowerings dead code; each backend deletes its own |
| R8 | **Landed.** `val n = 5; val x: n = 7;` is `'n' is a value, not a type`, located; `val T = i32;` / `val U = T;` are types (`Env.typeValueNames`); function-typed and declaration bindings (imports, std's `Array`) keep resolving. The real `type` kind of A1 is not built | cells: `comptime/tests/infer_errors.zig` `type position: …` |
| R9 | **Landed.** Each of the three N25 cells is refused for its own reason with the caret on the offending token: the return type (the missing-annotation message), the `catch` (`AssertPattern.catchLoc`), the second annotation's `#`; their lines left `expected-failures.txt` | `reject/wrapper_without_annotation.bp`, `reject/val_assert_after_catch.bp`, `reject/two_effect_markers.bp` |

**Does not reproduce — do not carry:**

| 1.0.4 row | Probe at `c2dd780` | Evidence |
|---|---|---|
| **A type error's location names the wrong module** | a `mod other;` whose `other.bp` writes `x: Nope` reds at `src/other.bp:1:17` and the failing module is named `other` | C10 + N30 gave `TypeRef` a `Loc` |
| **C12's pipeline half** | `val r: i32 = 1 \|> double;` checks; `1 \|> add(1, 2)` reds at the RHS | G0 (`ada3911`) |
| **N3** (`if (guard(v))` with `v: ?string`) | checks and narrows | C5 (`2b03e41`) |
| **N13**, **N17**, **N23** | each reds / points as specified | landed |
| **`while` in `libs/std`** | `grep -rn while libs/std --include=*.bp` → 5 hits, all comments | migrated |

**Acceptance:** each row above reds or checks as its "Correct" column says, with a location, and R7
is followed by a note to the four backend fronts naming the lowerings that become dead. — **met**: R1–R9 landed. **The note, by name:** no program that checks reaches a block used as a value any more, so these lowerings lose their producers — `02-erlang`: the tail `case` that yields a block's last expression; `03-beam`: the `make_fun3` closures that wrap a value block (12 sites in `codegen/beam_asm.zig`); `04-js`: the `(() => { … })()` IIFE a value `if`/`case` block emits (27 `(() =>` sites in `codegen/commonJS.zig`); `05-wasm`: the `;; lambda` value block. Each front deletes its own after measuring which sites are still reached by a `case`/`if` that `return`s in every arm (those keep a value and are not dead).

### Step 9 — diagnostics: the `.withLoc` sweep and the error box's file name (C13 bulk, N9)

One landing, because the family regenerates whole. Measured at `c2dd780`:

| What | Count | Command |
|---|---|---|
| error snapshots | **270** (135 `comptime/node/errors`, 135 `comptime/erlang/errors`) | `find snapshots/comptime -path '*errors*' -type f \| wc -l` |
| of those, the box reads `┌─ :L:C` with **no file name** (N9) | **226** | `grep -lE '┌─ :[0-9]+:[0-9]+'` over that set |
| of those, **no box at all** (C13's unlocated raisers) | **44** (22 slugs × 2 dirs) | the same set, `'┌─' not in file` |
| `TypeError` constructions in `comptime/unify.zig` | **27**, of which **0** call `.withLoc` | `grep -c` |
| `TypeError.custom` sites in `comptime/infer.zig` | **92**, of which **9** carry `.withLoc` on the same line | `grep -c` |

The 44 slugs are the interface/implement family (`implement_missing_a_required_interface_method`,
`duplicate_method_across_interfaces_without_qualification`, …), the effect-wrapper family
(`1g_rg3_future_rejects_t_is_required`, …) and the external family (`external_wrong_arity`,
`external_builtin_typechecks_args`) — listed in [`blast-radius.md`](./blast-radius.md).

Land this **last**: steps 1–8 add error snapshots, and every one written before the sweep is written
in the old format.

**Acceptance:**
- [ ] every error snapshot's box names its file
- [ ] 0 `TypeError` raised from `comptime/unify.zig` without a location; the two bare `unify` arithmetic call sites go through `unifyAt` — **the arithmetic half landed** (compiler `3a504c90`: both sites are `unifyAt` the right operand, three snapshots gained a box); `unify.zig` itself still raises unlocated errors that its callers locate
- [ ] a `throw` under `fn f() -> i32` reports `effect-try-without-fallible-channel` at the `throw`, not at the first body statement (the annotated form this box named leaves with C-32, decision 118)
- [ ] the 44 box-less snapshots have a box; the re-recorded 270 are **read** for expected/found orientation, not bulk-accepted — **measured at `ffe2db69`: 23 box-less of 166** (one directory now); 11 located by compiler `e361fd69` (RG3, `@Option<T>`, the two `@External` shapes), 12 remain — the implement/extend/behavior coverage refusals, the two `pub default` duplicates, the two activation refusals — whose declarations carry no location in the AST (`ImplementDecl`, `ExtendDecl`, `FnDecl`, `ModDecl`); giving them one re-records the parser dumps, which is this step's own landing. The file name in the box (143 snapshots) is `snapshot.zig`'s and the harness's, outside this front's files

### Step 10 — the parser gaps that are inference-side

Five gaps; all five reproduce at `c2dd780`. Two of them carry
a recommendation to delete the tests rather than implement the grammar — the decision is the
maintainer's and is listed in [Decisions the maintainer owes](#decisions-the-maintainer-owes).

| Gap | Probe at `c2dd780` | Change | Blast radius |
|---|---|---|---|
| `if (a && b)` / `if (a \|\| b)` | `Unexpected token` at `&&` | `parser/exprs.zig` `prec.equality` → `prec.lowest` **at the `if` condition only**; the other eleven `prec.equality` sites stay | few — `if` parser snapshots. Needed by step 3's narrowing through `&&` |
| `_` as an `if` binder | `Unexpected token` at `_` | also accept `.underscore` before `->`, `binding = null` | none |
| `assert <expr> is <Pattern>` | `is-variant-binding` at the `(` | a statement form binding into the **enclosing** scope; needs step 4's pattern typing | few parser + new checker work |
| `<Pattern> as <name>` | `Unexpected token` at `as` | a `Pattern.bound` variant — reaches all four backends' pattern lowerings | **Decided (decision 11): not part of the language** — the three tests and their snapshots are deleted |
| unnamed variant payload (declaration half) | — | optional field names + a reflected surface | many. **Recommend: drop; keep `name: Type`.** The pattern half (`.Some(#(a, b))`) **landed** with `dff3446` |

**Acceptance:**
- [x] `if (a && b)` and `if (a || b)` parse; every other `prec.equality` call site is unchanged
- [x] `if (x) { _ -> … }` parses with `binding = null`
- [x] `assert e is P;` either parses and binds into the enclosing scope, or its three tests are deleted and the decision recorded
- [x] `<Pattern> as <name>` and the unnamed-payload declaration are implemented or their tests deleted, each with the decision recorded in [`residual-rows.md`](./residual-rows.md)

### Step 11 — decision 8 in the sources (`libs/std`, `examples`)

Once steps 1–8 accept decision 8's forms, write them. Measured at `c2dd780`:

| Migration | Count | Command |
|---|---|---|
| generic `type` / `behavior` declarations in `libs/std` writing a bare `Self` | **16 declarations**, `Self<…>` used **0** times | `grep -rnE '^(pub )?(type\|behavior) [A-Za-z0-9_]+<' libs/std --include=*.bp`; `grep -rn 'Self<' libs/std --include=*.bp` |
| `self: Self` occurrences across `libs/std`, `examples` and the compiler's own `.bp` fixtures | **129** | `grep -rn 'self: Self[,)]' libs/std examples modules/compiler-core/src --include=*.bp` |
| unannotated `val`/`var … = [];` (§1.4 would warn) | **5**, all in `libs/std` (`dict.bp:73`, `primitives.bp:489`, `:546`, `:561`, `:575`) | `grep -rnE '^\s*(val\|var)\s+\w+\s*=\s*\[\]\s*;' libs/std examples --include=*.bp` |
| `while` in `libs/std` / `examples` code | **0** (5 hits, all comments) | `grep -rn while libs/std examples --include=*.bp` |
| `-> @Result` in `libs/std` without its effect annotation | **0 of 14** | measured by `3e7cd62` |
| `behavior Display` declared anywhere in `libs/std` | **0** | `grep -rn 'behavior Display\|implement Display' libs/std --include=*.bp` |

The last row is a gap decision 8 §7 assumes closed: "`libs/std` implements `Display` for `Dict`".
`behavior Display` does not exist, and `Dict` does not implement it. The four backend fronts' §7
acceptance ("`Display` honoured when nested") cannot be measured against `libs/std` until this step
declares it — `tests/language/run/display_print.bp` declares its own, which is what the backends
test against meanwhile.

**Acceptance:**
- [x] no bare `Self` in a generic declaration in `libs/std` or `examples`; the 16 declarations carry `Self<…>` — `e7f1af11` (79 sites; `examples/` had none)
- [x] the 5 unannotated `= []` bindings carry an annotation and §1.4 warns on none of them — `bdbbeae6`
- [x] `behavior Display` is declared in `libs/std` and `Dict<K, V>` implements it (§7's `Dict("a": 1, "b": 2)`) — `builtins.d.bp` declares it (decision 27); `Dict` implements it with compiler `a91e21f9`, `@print(d)` → `Dict("a": 1, "b": 2)` on commonJS and erlang, `dict.bp`'s test
- [x] `zig build test`, `test-libs` and `test-language` green — at `a91e21f9`: `zig build test` green, `test-libs` 8 / 0 over the bundled libraries (the sibling libraries unchanged against `feat` in a scratch copy, erika with its migration patch), `run.sh` 825 / 22 / 0

### Step 12 — one flat table under four symptoms

Four defects that have been filed separately all resolve a **bare name** through one flat,
program-wide table, and the table has no owner and no dissent check. Each was re-measured against
`2e6bb4ac` on the date above; the command and the exact output are in `status.md` beside each row.

| # | Spelling | What happens today |
|---|---|---|
| 1 | `.Red` where two enums each declare `Red` | commonJS: `ReferenceError: Red is not defined`. **erlang binds the *wrong enum's* variant** to a correctly-typed name and dies later at a `case` with no arm — `{case_clause, main__t__warm__v__red}` |
| 2 | `.Zeta` against a section type `Token.Layout.Break` | `unbound variable 'Zeta'` on both targets, with **no collision anywhere in the program** — a section leaf has no shorthand at all |
| 3 | the same, where a top-level payload variant shares the leaf's name | `type mismatch: expected __Token__Layout__Break, got function` — the lookup found the variant's *factory function* and reported a type problem for a resolution problem |
| 3b | `.Color.Hex("#abc")` annotated `: Token`, where front 54's `Ns` enum also has a `Color` member | `'Hex' is not declared in any behavior implemented for 'Ns'` — the resolver walked into `Ns`, a type the author never mentioned, ignoring the annotation written one token earlier |
| 3c | `Shape.Circle(r: 3)` — **fully qualified** — where `Hole` also declares a `Circle` | `type mismatch: expected Shape, got Hole`. The qualification, which is the documented way to disambiguate, is ignored; with a control renaming `Hole.Circle` to `Hole.Round` the same program answers `9`. This is the row that matters most: it defeats the workaround the other rows rely on |
| 4 | a leading-dot enum path resolved by hash order | **closed** (the resolver now reads the expected type), and it is the precedent: the fix was to ask the question the caller actually has instead of taking the first answer the table offers |

Row 4 is why these belong together rather than in four commits: it fixed one consumer of the table
and left the table alone. Rows 1–3c are the other consumers. Row 3b shows the table is consulted **before** the expected type, even where the expected type is written on the same line. Row 3c shows it is consulted before the *qualification the author wrote*, which is why none of these can be worked around by spelling the path out — and why the acceptance below cannot be satisfied by a better diagnostic alone.

**What the step has to decide first** — and it is a language question, not an implementation one:
*does a section leaf have a shorthand?* Row 2 says it does not today, and the emilia track has ten
landed fronts that write the full path everywhere, so nothing is blocked either way. If the answer
is no, row 2's diagnostic should say so by name (`a section leaf has no leading-dot shorthand; write
the full path`) rather than `unbound variable`, and row 3's must stop being a type error. If the
answer is yes, all three rows are one fix.

**Acceptance**
- [x] a bare name that two declarations claim is a **named refusal**, never a silent pick — decision 67, and the atom-collision check in `crossModule.zig` is the precedent for what loud looks like — compiler `909acc34`: "`Circle` is a variant of `Shape` and of `Hole`, and nothing here says which — write `Shape.Circle` or `Hole.Circle`" (`Env.variantClaims`). **The language answer the step asked for first**: a section leaf *has* a leading-dot shorthand, exactly where a top-level variant has one — where the position's type is that section — and none elsewhere (a named refusal)
- [x] row 1's erlang half cannot survive: binding one enum's variant to another enum's type is a wrong value, not a wrong message — the leading dot is spliced in qualified (`Warm.Red`), so no backend picks
- [x] **row 3c is the gate for the whole step**: `Shape.Circle(…)` types as `Shape` whenever `Shape` declares `Circle`, regardless of what any other enum declares. If the fully-qualified spelling still resolves by table order, nothing else here is really closed — `Env.variantCtors`; `9` on commonJS, erlang and wasm
- [x] row 3 reports a resolution failure, not a type mismatch — with the section expected it resolves; without, `.Zeta` is refused as "a leaf of the section `Token.Layout.Break`"
- [x] every one of the four has a language cell, and each cell is **proved able to fail** by planting the pre-fix behaviour — `run/variant_leading_dot_expected` (rows 1, 3c), `reject/variant_name_ambiguous` (row 1 unexpected), `run/section_path_resolution` (rows 2, 3, 3b), `reject/section_leaf_without_expectation`; each run with the `feat` binary fails as the row describes
- [x] the two targets agree, and the cells say so — three of these four answer differently on commonJS and erlang, which is how they stayed open — the cells run on commonJS, erlang and wasm with one `.out` each. Left for 05-wasm: a `case` arm's leading-dot PATTERN is resolved by the backend, and wasm's `findVariant` takes the first enum declaring the name (a `.Red` arm over `Cold` traps when `Warm` also declares `Red` first)

**Not this step.** The *cross-module* name-keyed registry (`CrossModule.exports`, `variant_enum`,
`type_owner_path`, `imported_fns`) is the same shape one level up and is `02-erlang`'s, in worktree
`.tasks/cross-module-exports`. The two should read each other's fix before either lands.

### Step 13 — a local binding escapes its function

Found by jhonstart front 29, verified against `ead0b645` in two shapes.

**Bare.** A `val` declared inside one function is visible to every top-level declaration *after* it:

```bp
fn holder() -> string { val v = "inner"; return v; }
fn later()  -> string { return v; }
```

This **compiles**. commonJS then throws `ReferenceError: v is not defined` at run time and erlang's
`erlc` refuses the emitted module with `variable 'V' is unbound`. The checker handed both backends a
program that names something nothing declares — which is the whole defect: not that the program
fails, but that it was accepted.

**Shadowing**, which is the form that actually bites. A local whose name matches an exported
declaration retypes that declaration for the *next* function:

```bp
pub fn p(label: string) -> string { … }
fn first()  -> i32    { val p = Thing(n: 3); return p.n; }
fn second() -> string { return p("x"); }      // error: expected string, got Thing
```

Inside a hook-activating body (a `@Component` return under decision 118) front 29 got the same error **with no line and no column**. In
`repository/jhonstart` the exported tag constructors include `p`, `a`, `li`, `text`, `form`, `link`,
`title` and `body`, so every file in that package is one declaration order away from it.

Repro: `repository/jhonstart/repro/local-binding-leaks-to-later-decls/` — twelve lines, jhonstart-free.

**Acceptance**
- [x] the bare shape is **refused at compile time**, located at the use, naming the function the
      binding belongs to — compiler `883b578d`: "unbound variable 'v' — `v` is a local of `holder`, and a
      local ends with its body"
- [x] the shadowing shape resolves `p` to the exported declaration, and a local named `p` shadows it
      **only inside the function that declares it** — `883b578d` (body scopes: `Env.openBodyScope`)
- [x] the `@Component`-body case carries a line and a column — a located message is not optional because
      the body is a comptime one — the unlocated mismatch no longer arises: the shadowing is gone, and the one
      diagnostic left in this family (`unboundAt`) is located at the use in every body
- [x] cells for both, each proved able to fail by planting the pre-fix behaviour, and the bare one
      asserted on **both** rows, since today it fails differently on each — `reject/local_binding_escapes`
      (a `check`-time refusal, so one cell covers every row) and `run/local_shadow_ends_with_body`
      (`3` / `p:x` on commonJS, erlang and wasm); run with the `feat` binary, the first is accepted and the
      second reds `expected string, got Thing` on all three

### Step 14 — decision 112: DSL hygiene (each name resolves in the scope of whoever wrote it)

[Decision 112](../../decisions-taken.md) (maintainer, 2026-09-26). A DSL's `e.build(…)` text has two
authors, and today the whole built text resolves in the **consumer's** scope: a private helper the
library writes (`double(` … `)`) is `unbound variable 'double'`, an alias the consumer wrote
(`area as surface`) is unbound the same way, and a consumer that declares its own `double` has it
**silently captured** (21 instead of 40).

- Text the library writes in `e.build` resolves in the **library's** module, private names included,
  and carries that declaration's identity `<lib>@<path>@@<Decl>` (decision 109).
- Text from `e.text()` resolves at the **call site** — the consumer's imports, aliases (decision 110)
  and locals.
- `e.lookup(name)` resolves at the call site and returns the **declaration's identity, never the
  alias** (`e.lookup("surface")` → `shapesdsl@shapesdsl@@area`).

`e.build` already receives the two parts separately; the compiler marks each span with its author and
the DSL author writes nothing extra. The `@Expr`/`@ExprCustom` surface does not change.

**Acceptance**
- [ ] the three rows of decision 112's table print 40 — private helper, consumer alias, consumer's own
      `double` not captured; the three `run/` cells are front 12's ([`../12-language-tests/README.md`](../12-language-tests/README.md) step 4, item 5)
- [ ] `e.lookup("surface")` answers `area`'s identity, and hover / go-to-definition / the `CustomNode`
      point at `area`
- [ ] no `reject/` cell (the decision adds none)

## Acceptance — the `expected-failures.txt` lines this front deletes

`repository/botopink-lang/tests/language/expected-failures.txt`, at `c2dd780`. **31 of 54.** A line
goes with the step that makes it pass; the suite must stay `0 failed` after each deletion (a listed
test that passes fails the run).

| Step | Lines |
|---|---|
| 1 (`unknown`) | `* reject/case_unknown_without_wildcard.bp` · `* reject/case_shorthand_on_unknown.bp` (with step 5) · `commonJS \| test/case_unknown.bp` · `erlang \| test/case_unknown.bp` |
| 2 (unions) | `commonJS \| test/case_exhaustive.bp` · `erlang \| test/case_exhaustive.bp` |
| 3 (`is`) | contributes to `test/case_unknown.bp` |
| 4 (arms) | `commonJS\|erlang \| test/case_arms.bp` (the cell writes `1..9`; §5.2 settled on `1...9` — the cell belongs to [`12-language-tests`](../12-language-tests/README.md), not to the compiler) · `commonJS\|erlang \| test/case_variants.bp` · `commonJS\|erlang \| test/case_tuples.bp` · `commonJS\|erlang \| test/case_guards.bp` · `commonJS\|erlang \| run/case_values.bp` · `wasm \| run/case_values.bp` · `commonJS\|erlang \| test/case_sections.bp` · `* reject/case_missing_variant.bp` · `* reject/case_arity_without_rest.bp` |
| 5 (exhaustiveness) | `* reject/case_only_guarded_arms.bp` · `* reject/case_literals_only.bp` |
| 6 (generics) | `* reject/generic_missing_argument.bp` · `* reject/self_without_argument.bp` |
| 7 (defaults) | `commonJS \| test/fn_defaults.bp` · `erlang \| test/fn_defaults.bp` |
| 8 (R3, R9) | `* reject/external_lowercase_target.bp` · `* reject/wrapper_without_annotation.bp` · `* reject/val_assert_after_catch.bp` · `* reject/two_effect_markers.bp` |

Two lines are attributed to `06 N12` in the file and are **not** this front's: `commonJS |
test/loop_break_value.bp` (both tests) is a commonJS lowering — `break <value>` yields a one-element
array — and belongs to [`04-js`](../04-js/README.md). The same defect reproduces on wasm, where no
line exists because `botopink test` does not run wasm.

## Gate

- [ ] `scripts/gate.sh --cold` green in this front's worktree (`zig build`, cold `zig build test`, `test-cli`, `test-libs`, `test-language`)
- [ ] `botopink check` clean in `libs/std` and in every `examples/` project
- [ ] the six sibling libraries still compile (`zig build test-libs`, 11 cells) — a library that reds gets a migration plan in this front's commit, not a `known-red-libs.txt` line
- [ ] every re-recorded error snapshot **read** for expected/found orientation and for a `┌─` box that names its file
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Commit on `fix/checker`; no push, no merge

## Blast radius

Measured at `c2dd780` — full tables in [`blast-radius.md`](./blast-radius.md).

| What | Count |
|---|---|
| `snapshots/comptime/**` files this front owns | **1079** (`node` 337, `erlang` 337, `beam` 202, `wasm` 202, `templates` 1) |
| of those, error snapshots | **270** — step 9 re-records the family whole |
| error snapshots whose box gains a file name | **226** |
| error snapshots that gain a box | **44** |
| `TypeError` sites to locate | **27** in `unify.zig` (0 located today) + **83** unlocated `TypeError.custom` in `infer.zig` |
| `libs/std` sites step 11 rewrites | 16 generic declarations · 5 `= []` bindings · 1 new `behavior Display` + its `Dict` implementation |

**It can also move all four codegen snapshot directories** (1258 files), because a fixture that
newly fails to compile takes its codegen snapshots with it. That is the one place this front meets
the four backend fronts, and it is all-or-nothing: a codegen snapshot carries no type rendering, so a
fixture that still compiles does not move. Steps 1–8 must therefore be run once against each backend
directory before landing, and any fixture they kill is reported to the owning backend front rather
than deleted.

## Notes

- **The four backend fronts read this front's output, not its files.** They share no source file and
  no snapshot directory with it. Each depends on the **step** that feeds it, not on the whole front:
  §7's formatter needs nothing from here, `is` / unions / `case` at run time need steps 1–5, and the
  dead block-as-value lowerings need step 8's R7. That per-step dependency is repeated in each
  backend README.
- **A named type's run-time identity is not this front's.** Steps 1–5 type `is Person`, a union of
  named types and a `case` over them; making a **value** answer which named type it is at run time is
  [`13-module-identity`](../13-module-identity/README.md)'s third half. This front's acceptance stops at the checker.
- **`format.zig` is not owned here** and it re-prints what the parser records. Step 10's grammar
  changes and step 4's parser half must keep `botopink format` round-tripping; a formatter defect
  found here is reported, not fixed.
- **Do not parallelise inside this front.** Steps 1–8 and 11 all touch `comptime/infer.zig`; only
  step 10's `parser/exprs.zig` half is independent of it.

## Decisions the maintainer owes

Four of these are already in [`../decisions-pending.md`](../../../1.0.5-beta/decisions-pending.md) and are listed here
only so the step that waits on one can find it: **D1 = #1**, **D2 = #11**, **D3 = #12**,
**D7 = #10**, and R3's question (a lower-case `#[@external]`) = **#15**. **D4, D5 and D6 are new** —
they were found probing `c2dd780` for this front and are not in that document yet.

| # | Decision | Measured context |
|---|---|---|
| D1 (= #1) | **Settled by decision 103 (the async generator named `futureGenerator`), then by decision 122: `@Stream<T>`, no annotation.** Neither `AsyncGenerator` (decision 8 §9's table) nor `AsyncIterator` (the compiler's `EffectKind.returnWrapper`, `libs/std/src/builtins.d.bp`'s `behavior AsyncIterator<T, E, C>`, the docs) survives; the rename lands with [`21-effect-chain`](../21-effect-chain/README.md) | `grep -rn AsyncIterator --include=*.zig --include=*.bp --include=*.md` → **69** hits; `AsyncGenerator` → **1** (decision 8 itself). Renaming crosses `libs/std`, the user docs and the compiler; `3e7cd62` enforced the spelling that exists and recorded the discrepancy in `comptime/AGENTS.md` |
| D2 (= #11) | **Decided: `<Pattern> as <name>` is not part of the language.** The three tests in `comptime/tests/variants.zig` and their snapshots are deleted | the parser half is local; the consumer half is a new `ast.Pattern` variant in four backend lowerings this front does not own. No library uses the form |
| D3 (= #12) | **Unnamed variant payloads: drop or implement.** The pattern half landed with `dff3446`; the declaration half remains | it changes the reflected `TypeInfo`/`EnumVariant` surface as well as four backends |
| D4 (**new**) | **`is` with a payload pattern.** The parser refuses `x is Some(v)` with a located `is-variant-binding`; §4.2 lists the form | decide whether `is` carries a pattern or the refusal stands and `case` is the only reader |
| D5 (**new**) | **Mismatched `case` arms: a union or an error?** §3.2 says the union, and step 2 makes one implementable. Two fixture slugs were named for the union answer | all 32 `case`-as-value blocks in the six libraries are type-homogeneous, so either answer costs zero migration |
| D6 (**new**) | **Who declares `behavior Display`.** §7 says `libs/std` implements it for `Dict`; `libs/std` declares no such behavior. Step 11 is scoped to do it — confirm, because four backend fronts' §7 acceptance reads it | `grep -rn 'behavior Display' libs/std` → 0 |
| D7 (= #10) | **`#[@code]` shares the name of the existing `@code(text)` builtin** (valid only inside template fns). Needed before types-as-values A2 | `infer.zig` `@code` builtin; no syntactic clash, but the shared name should be intended |

## Rows for `fronts.md`

**Ownership row**

| Front | Source it owns | Snapshots it owns | Spec rows |
|---|---|---|---|
| **01** [`checker`](./README.md) | `modules/compiler-core/src/comptime/{infer,types,unify,env,transform,eval,error}.zig` · `modules/compiler-core/src/parser/{decls,exprs,patterns}.zig` (steps 4, 10) · `libs/std/**`, `examples/**` (step 11 only) | `modules/compiler-core/snapshots/comptime/**` (1079) | steps 1–11; 31 of the 54 `expected-failures.txt` lines |

> **Beyond the coordinator's table.** The row above claims `src/parser/{decls,exprs,patterns}.zig`
> and, for step 11 only, `libs/std/**` and `examples/**`. Neither was in the ownership line the
> milestone plan gave this front, and both are unavoidable: steps 4 and 10 are grammar work the
> checker cannot do from `comptime/**`, and step 11 *is* the source migration. If the maintainer
> would rather cut them out, step 4's parser half and steps 10 and 11 move with them.

**Conflict notes**

1. **01 × 02/03/04/05 — `yes`, they run together.** No shared source file and no shared snapshot
   directory. What they share is the typed AST 01 produces, so each backend front depends on the
   **step** that feeds it (steps 1–5 for `is`/unions/arms, step 8's R7 for the dead block-as-value
   lowerings, nothing at all for §7's formatter), not on the front. One caveat, and it is real: when
   a step makes a fixture stop compiling, that fixture's codegen snapshots go with it in all four
   directories. 01 reports such a fixture to the owning backend front instead of deleting it.
2. **01 × [`13-module-identity`](../13-module-identity/README.md) — `no`.** 13 needs a value to answer which named type it is; 01 types
   `is Person`, a union of named types and a `case` over them. The cut agreed with the maintainer is
   that 01 owns the checker half and 13 the run-time half, but 13's checker-visible surface
   (`@Decl`, the type-identity intercepts) lives in `comptime/infer.zig`, which 01 owns whole.
   **Sequence: 01's steps 1–5 first**, then 13 — otherwise 13 writes identity rules against an
   inference that does not yet know a union from a nominal type.
3. **01 × [`14-comptime-on-beam`](../14-comptime-on-beam/README.md) — `no`.** 14 moves comptime evaluation onto beam; `comptime/eval.zig`
   and `comptime/error.zig` are 01's. 01's use of them is small (step 8's R8, types-as-values A1);
   hand 14 those two files as a carve-out, or sequence 14 after 01.
4. **01 × [`06-comptime-dedup`](../../../1.0.5-beta/06-comptime-dedup/README.md) — `no`.** It restructures `snapshots/comptime/**`, which 01
   re-records. 01 first.
5. **01 × [`07-review-backlog`](../07-review-backlog/README.md) — `no`.** It owns the test sources 01 adds fixtures to
   (`src/comptime/tests/**`, `src/parser/tests/**`); 01's new fixtures and their `KNOWN` notes are a
   carve-out, named in each landing note.
6. **01 × [`08-hygiene`](../08-hygiene/README.md) — `no`.** Its comment sweeps touch every file 01 owns; each sweep lands
   after 01.
7. **01 × [`09-ecosystem-residuals`](../09-ecosystem-residuals/README.md) — `seq`.** The six libraries compile against 01's checker; step 11
   migrates `libs/std` and `examples`, [`09-ecosystem-residuals`](../09-ecosystem-residuals/README.md) the libraries. 01 first.
8. **01 × [`10-cli-residuals`](../../../1.0.5-beta/10-cli-residuals/README.md) — `yes`.** No shared file. One file both touch by deletion only:
   `tests/language/expected-failures.txt`, where each deletes the lines its rows close.
9. **01 × [`12-language-tests`](../12-language-tests/README.md) — `yes`.** It adds cells and no source; it shares only
   `expected-failures.txt`, delete-only. `test/case_arms.bp` writes `1..9` and needs **its** edit, not
   a compiler change — 01 does not own that cell.

**Front-table row**

| [`01-checker/`](./README.md) | critical | Decision 8's inference — `unknown`, unions, `is` and narrowing, `case` arms and exhaustiveness — plus generics §1, trailing defaults, the `.withLoc` diagnostic sweep, the parser gaps inference needs, and decision 8 written into `libs/std` and `examples` |

---

## Handed over by `15-language-surface` (`109f6c9`)

Front 15 made two forms parse that nothing types. Neither is a new AST variant, by the argument `is`
already used, so the work is inference-side only.

1. **Landed** — `adder(3)(4)` types: `inferCallExpr` infers the `calleeExpr` and applies it (a `fn`
   taking the written arguments; the call's type is its return). `test/curried_call.bp` compiles; its
   two lines are C-09's backend half (commonJS emits `(4)`, erlang `''(4)`). A leading-dot head
   (`.Circle(radius: 1)`, front 15's steps 3–5 row 1) is the variant constructor of the position's
   expected enum, spliced in as `Shape.Circle(…)`, and a located refusal with no expected enum.

2. **`xs[0]` types as `void`.** The index is the builtin call `ast.index_builtin_name` (`"[]"`) over
   `(receiver, index)` — `ast.zig:1681-1703` states the contract. Inference has to type it **by the
   receiver**: the element type for an array, the value type for a dict, a character for a string, the
   member type for a tuple with a constant index — decide whether the answer is `T` or `?T`, and
   **refuse an index on `unknown`**, which `decision-8:112` already lists among the operations
   `unknown` has none of. Slicing is the same node with a `range` second argument.

**And one that is yours to spend, not 15's:**
[decision 36](../../../1.0.5-beta/decisions-taken.md#20-is-a-pattern-range-inclusive) is ~10 lines in
`parser/patterns.zig`'s `finishRangePattern` (`:269-274`) plus dropping `dotDotDot` from the lexer —
but `patterns.zig` is this front's step-4 grammar and the change re-records its `case` snapshots, so 15
left it. Measured while it was there: `1...9`, the spelling today's diagnostic recommends, **works on
no backend** — `case 9 { 1...9 { 1 } _ { 0 } }` answers `undefined` on commonJS and `0` on erlang,
because a brace-arm is neither typed nor lowered. That is the same defect as the 17 lines already
filed here.

---

## Handed over by `15-language-surface` steps 3–5 (`front/15-language-surface`)

Three rows of [`surface-gaps.md`](../15-language-surface/surface-gaps.md) are the checker's, measured
again at `4fe1747e`:

1. **`.Circle(radius: 1)` in expression position parses** — it did not at `c2dd780` — and reds
   `unbound variable ''` at the `(`: a leading-dot variant with a payload call, in a position whose
   expected type is a `val`'s annotation. This is the same empty-name diagnostic `status.md` already
   lists for the typed array literal (`[.EffectShadowRaw("…")]`); the parser's node is a `dotIdent`
   head with a call link, and whatever the answer is, a message quoting an empty name is not it.
2. **Answered — the refusal stands** (decision 8 §6 T1: "construction has no labels"; the labels
   ride the TYPE and the variables a tuple is built from). T7's warning — a variable's name
   differing from the written label — landed with compiler `dd20304d`. **`#(x: 1, y: 2)` — the labeled tuple construction** — is now refused by the parser as
   `tuple-literal-label`, at the label, instead of `novalBinding` at the value. The form itself is
   §6's and yours: when it parses, delete the refusal in `parseTupleLitExpr` (one `if`) and its R10
   case, and the labels ride the tuple type. Until then `#(1, 2)` and `.0`/`.1` is what compiles.
3. **`Box<i32>(value: 1).get()`** — explicit type arguments at a constructor call — still reds
   `novalBinding` at `value`. 15 did not name it: `decision-8:60-64` writes the form, so it is a gap
   (§1.3) rather than a decision, and naming it would record an absence the document contradicts.

## Handed over by `11-tooling`

Three rows, each measured through `botopink check` rather than through the language server, so none of
them is a rendering problem:

1. **Landed** — C-02 types `xs[0]` as `?T`, and the message now reads `expected string, got ?string`
   (compiler `b21ebfbb`: a mismatch spells `?T`, `T[]` and a section's path, never the internal
   `optional`). **`xs[0]` types as `void`.** `val first: string = xs[0];` → `error: type mismatch: expected string,
   got void`. `ast.zig:1734` already assigns the index expression's typing to this front; the
   consequence 11 found is that hover, inlay hints and the annotation code action all offer `: void`
   for every index expression.
2. **Landed** (`4dd24965`, decision 44) — **`val v: optional<i32> = null;` checks clean** — the checker's internal name (`infer.zig:4590`) is
   reachable as a type annotation, which [decision 2](../../../1.0.5-beta/decisions-taken.md) and `builtins.d.bp:56-58`
   say no spelling but `?T` is. Opened as [question 44](../../../1.0.5-beta/decisions-pending.md).
3. **Landed** (`4dd24965`) — **`val v: Option<i32> = null;`** answers `type mismatch: expected Option, got optional` — not the
   pointed diagnostic `builtins.d.bp:56-58` promises, and the message leaks the internal name.


## Handed over by `01-std/01-std-lib-enablement` (2026-09-25)

1. **Landed** (compiler `3a504c90`) — **An integer literal is `i32` and never widens to `i64`.** With `n: i64`, `n * 1000` is `type
   mismatch: expected i64, got i32`, and so are `val k: i64 = 1000;`, `t - (t % 1000)`, a literal or a
   literal product (`3 * 86400000`) passed to an `i64` parameter, and `r.unwrapOr(0)` on an
   `@Result<i64, _>` — the last one unlocated (`--> src/time.bp`, no line). `std/time` works around it
   with a private identity cell `wide(n: i32) -> i64` (`libs/std/src/time.bp`), and its `Duration`
   builders take `i32` because of it. The cell goes when a literal takes the integer type its context
   asks for.

## Decided by the maintainer on 2026-09-26 (`tmp/decisoes-pendentes.md`) — landed

1. **`try x catch null` in a `?U` position** types — the handler `null` makes the whole a `?U`; a
   handler of another type is refused at the handler (compiler `ca0d6b15`,
   `run/try_catch_null_and_noreturn_narrowing`, `reject/try_catch_handler_mismatch`).
2. **Narrowing after a `noreturn` call** — a branch ending in a call whose declared return is
   `noreturn` (`notFound()`, `redirect(…)`, `@panic`, `@todo`) exits like a `return` for narrowing
   and for decision 2 (`ca0d6b15`).
3. **A component called inside a component** (decisions 104/118/128, guide § 4.3) — in a body whose
   return is `@Component<C, _>`, a call answering `@Component<C, T>` whose `T` owns the context is
   typed `T` and `await` is spliced for the backends; as `use`'s operand, outside a component body
   or under another base it keeps its wrapper (`ca0d6b15`, `run/component_call_renders`).
4. **Decision 110 for types and type aliases** — `import {Point as P}`, `import {Pair as Two}`,
   `import {dict.Dict as D} from "std"`; the alias is checker-local, the emitted name the declared
   one; `import-alias-on-type` deleted (`bfc5e76d`, `modules/import_alias_on_type`).


# Decision 8's inference, row by row

The grammar of [decision 8](../../../1.0.4-beta/08-review-backlog/decision-8-language.md) sections 2, 3,
4 and 5 landed on `botopink-lang` `d0c27f6`. Nothing types it. This file states what the checker owes
each section, in the decision's own words, with the probe that shows the gap at `c2dd780` and the
site that decides it.

Every probe is `zig-out/bin/botopink check` on a one-module project built from `botopink new`, run
2026-09-18 against `botopink-lang` `c2dd780`. Paths are relative to
`repository/botopink-lang/modules/compiler-core/src/`.

---

## Why the three types are spellings and not types

Each grammar commit says so at the definition site, and each gives the same reason: a new variant on
`ast.TypeRef` (or on `ast.Pattern`) does not compile without editing `comptime/infer.zig`,
`codegen/typescript.zig`, `format.zig` and the language server — files the grammar front did not own.

| Form | How it reaches inference | Commit |
|---|---|---|
| `unknown` | `TypeRef.named` under the reserved spelling `ast.unknown_type_name`; `unknown` is a lexer keyword and `isReservedWord` refuses it as a name, so no source can mean anything else | `6c849ae` |
| `A \| B` | `TypeRef.generic` under the reserved name `ast.union_type_name` (`"\|"`), members as arguments, read back with `unionMembers()`. `\|` is the loosest type operator, so `i32 \| string[]` is `i32` or `string[]` and `(i32 \| string)[]` is the array of the union | `4a3449f` |
| `x is T` | the `is` builtin call (`ast.is_builtin_name`) with the value as its only argument and the type in the call's `isType` slot. `parseIsExpr` is the tightest level of the expression grammar, so `a is i32 == b` is `(a is i32) == b` | `3b491e3` |
| `Pattern { body }`, `when (…)`, `1...9`, `.Variant`, labels, `..`, `#(…)` | `ast.PatternShape` plus two new fields on the existing `variant` node; the decision-8 arm body lands as the **lambda node** the older block arm already produced | `dff3446` |

Promoting each to a real type kind is a rename away once both halves are in one tree — which is what
this front is.

---

## §2 — `unknown` (N19)

| | |
|---|---|
| **Probe** | `val a: unknown = 42;` → `type mismatch: expected unknown, got i32` at `1:34` |
| **Where** | `comptime/unify.zig` compares two `.named` types by name; `unknown` is `.named "unknown"`, so only `unknown` unifies with it — the exact opposite of §2.1 |
| **Correct** | a one-way rule in `unify`: every type is assignable **to** `unknown`; `unknown` is assignable only to `unknown`. The reverse direction is the located error §2.1 sketches, and its hint names `is` |

| § | Obligation | State at `c2dd780` |
|---|---|---|
| 2.1 | every value goes in; nothing comes out unchecked | nothing goes in |
| 2.2 | allowed: `@print(x)`, `x == y`, `x != y`, assignment to `unknown`, passing to a generic. Refused: arithmetic, field access, indexing, method calls | unreachable — 2.1 reds first |
| 2.3 | `==` with an `unknown` operand compares numbers by value | unreachable; the run-time half is each backend's |
| 2.4 | a `pub` declaration whose **inferred** type contains `unknown` is an error | not implemented |
| 1.4 | a non-`pub` binding falling to `unknown` warns and names the annotation to write | not implemented — `var out = [];` checks silently; **5** such bindings in `libs/std` |
| 2.5 | no `any` | holds — there is no such type |

`reject/case_unknown_without_wildcard.bp` and `reject/case_shorthand_on_unknown.bp` are rejected
today, both **by 2.1 firing first**. They must be rejected by §5.4 and by §5.2's "on `unknown` write
the full name" instead, which is why step 1 and step 5 share them.

---

## §3 — union types (N20)

| | |
|---|---|
| **Probe** | `val v: i32 \| string = 1;` → `type mismatch: expected \|, got i32` at `1:39` — the reserved name printed verbatim |
| **Where** | inference resolves `TypeRef.generic` by name; `"\|"` is not a declared type, so `resolveTypeName` answers a nominal type spelled `\|` |
| **Correct** | a union type kind in `comptime/types.zig`; `unify` accepts a member into the union and refuses the union into a member; `typeNameOf` renders `A \| B` |

| § | Obligation | Note |
|---|---|---|
| 3.1 | the syntax, at any depth | parses already; the binding is right (`4a3449f`'s three snapshots pin it) |
| 3.2 | inferred from array literals, `if` branches and `case` arms **with no error**; a `return`/`throw`/`break` branch does not contribute; `1` and `null` give `?i32`; `[1, 2.5]` gives `f64[]` | this is [decision 5 / D5](./README.md#decisions-the-maintainer-owes) — the mismatched-arm policy |
| 3.3 | a use is allowed only when every member allows it; a `case` covering every member needs no `_` | feeds step 5 |
| 3.4 | `Option<A> \| Option<B>` → `Option<A\|B>`; same for `Box`, `@Result`, `Dict` (key and value); **arrays never join**. A user `type` joins when its parameter is only read | the "only read" test is a member-signature walk: no member takes a `T` |
| — | the misuse is reported **at the use**, naming the branch that widened it | two locations in one diagnostic — the use and the widening branch |

`unknown` versus a union (§3.5): the same run-time test and the same wasm box; the difference is what
the checker guarantees — exhaustiveness and assignability. Keep them distinct type kinds.

---

## §4 — `is` tests the value, not the origin (N21)

| | |
|---|---|
| **Probe** | `val a: i32 = 1; val b: bool = a is i32;` → `type mismatch: expected bool, got void` at the `is` |
| **Where** | the `is` call is an unknown builtin, so `inferBuiltinCallReturnType` has no arm for it and the call is typed `void` |
| **Correct** | type the call `bool`, read `isType`, and record a narrowing for the tested binding |

| § | Obligation | State |
|---|---|---|
| 4.1 | numbers by **range**: `2.0 is i32` true, `2.5 is i32` false, `x is f64` true for any number. Inside the block the value **is** the tested type — `if (a is i32) { @print(a + 1); }` prints `3` | not typed; the run-time half is each backend's |
| 4.2 | what may follow `is`: a primitive; a named type's constructor; `#(i32, string)` (arity and each element); `Box<unknown>` — `Box<i32>` is an **error**, the argument is not checkable | the parser accepts all of them into `isType`; nothing checks them |
| 4.2 | `Option.Some(v)` / `.Some(v)` binding a payload | **refused by the parser** with a located `is-variant-binding` at the `(`, hinting at a `case` arm. Decision D4: does `is` grow a pattern, or does the refusal stand? |
| 4.3 | `a is string` on a statically-known `i32` is a **warning**, always false | no warning |

Narrowing has three entries and they must agree: the `if` condition (through step 10's `&&`
widening), a `when (…)` guard into that arm's body (§5.3), and the type-guard fn form `-> x is T`,
which already narrows since C5 (`2b03e41`). The narrowing machinery at the `if`-condition path
(`infer.zig`, `env.typeGuardFns`) is the one to extend, not a second one.

---

## §5 — `case` and patterns (N22)

Four defects, each reproducing on its own.

### (a) the arm body is a lambda that is never unwrapped

```
case x { 0 { "zero" } _ { n -> "other" } }   →  type mismatch: expected string, got function
```

P3: the body **is** a lambda body — its last expression is the arm's value. P1: `{ n -> … }` binds
the whole matched value, already narrowed. P5: the bound variable's type comes from the matched value
(`Option<string>` → `v: string`, `Option<i32|string>` → `v: i32|string`, `unknown` → `v: unknown`).
The arm's contribution to the `case` type is the lambda's **result**, and an arm whose body jumps
(`return`/`throw`/`break`) contributes nothing (§3.2).

This is the single defect behind five of the suite's cells: `test/case_tuples.bp`,
`test/case_guards.bp`, `test/case_exhaustive.bp`, `test/case_unknown.bp` and `test/case_sections.bp`.

### (b) a dotted or shorthand variant path is not resolved against the matched value

```
case s { .Circle(r) { r } .Rect(w) { w } }   →  missing variant(s) Circle, Rect
```

The leading `.` stays inside the pattern's name — that is what tells a variant path from a binding
(`dff3446`). The variant table is matched against the literal text, so `.Circle` matches nothing and
every variant reads as missing. P8: on a typed subject the enum comes from the matched value's type;
on `unknown` the full name is required, and the diagnostic must say so (that is
`reject/case_shorthand_on_unknown.bp`'s own reason).

### (c) labels, rest and arity in a payload

P4 — a variant binds by label (`Option.Some(value: v)`) or by position (`Option.Some(v)`).
P6 — a tuple pattern is positional only; a label in one is a parse error already.
P7 — `..` ignores the rest, at the end, once; **without it the arity and the fields must match**, and
that is what `reject/case_arity_without_rest.bp` asserts. It is rejected today for another reason.

### (d) a section is not a type named by its path (§5.3b)

```
type Token { Text { Bold, Italic }, Color { Red } }
fn textCss(t: Token.Text) -> string { … }
Token.Text.Bold            →  unknown field 'Bold' on type 'Token'
val t: Token.Text = .Bold; →  unbound variable 'Bold'
```

`9242b66` landed the type side against emilia's own spelling; the two forms above still red. §5.3b
asks for both: `Token`, `Token.Text` and `Token.Text.Size` resolve **in type position**, and a value
is written with the same path its type uses. No compiler-invented flat name (`TokenText`).

**Matching into a section is a refinement, never coverage.** `case t { Text(Bold) { … } }` leaves
`Text` open exactly as `Ok(1)` leaves `Ok` open. Counting a refinement as full coverage is what §5.4
forbids and what the compiler did before N28.

**Methods on a section are out of scope**: `EnumSection` has no slot for them and a section body with
a `fn` does not parse. §5.3b calls that an unimplemented capability, not a prohibition — do not add
it here.

---

## §5.4 — exhaustiveness

Exhaustiveness *is* checked, over enum variants, and an arm counts the moment its pattern names a
variant. §5.4 is a different rule.

| Situation | `c2dd780` | §5.4 |
|---|---|---|
| every enum variant / union member / `true`+`false` covered | no `_` needed (variants only) | no `_` |
| a type covered whole (`i32 { … }` on an `i32`) | not modelled | no `_` |
| **an arm has `when` and no unguarded arm covers the rest** | the guarded arm **counts** — `reject/case_only_guarded_arms.bp` compiles | **`_` required**; guarded arms never count |
| the matched value is `unknown` | §2.1 reds first | `_` required |
| **literals only (`0 { … }`) on `i32` / `string`** | compiles — `reject/case_literals_only.bp` | `_` required |
| a variant or member missing | reds | `_`, or handle it |
| a refinement into a section | — | does not cover the section |

Probe, verbatim:

```
case x { 0 { "zero" } 1 { "one" } }                             → Checked
case x { i32 when (x > 0) { … } i32 when (x <= 0) { … } }       → Checked
```

The second one shows the shape of the fix: the coverage walk must separate "this arm's pattern
covers P" from "this arm runs whenever P matches". A guard makes the second false while leaving the
first true, and only the second may be counted.

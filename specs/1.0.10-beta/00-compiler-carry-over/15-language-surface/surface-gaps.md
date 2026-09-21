> Carried from `specs/1.0.5-beta/15-language-surface/surface-gaps.md`, status at carry (2026-09-20): landed (`109f6c97`); the hold-backs are C-05 (module-level `var`), C-11 (the trailing lambda's one-line body) and C-13 (decision 29's parser half, re-ordered by decision 60 — the patch is beside this file)

# The written surface against the parser

The seven forms of [decision 14](../../../1.0.5-beta/decisions-taken.md#14-seven-forms-that-do-not-parse) were found
**by accident**, while writing test cells. This file is the deliberate version: every concrete
spelling the project's documents and sources write, probed against the compiler.

**Method.** **268 probes** at `botopink-lang` `c2dd780`, each a minimal module dropped into a scratch
project and run through `botopink check` with `BOTOPINK_LIB_ROOTS` pointing at the worktree's `libs/`.
The compiler was built in a scratch worktree — never in `repository/botopink-lang`, never in
`.tasks/`. A form "parses" when the diagnostic is not a parse error; it "checks" when `check` exits 0.

**Sources walked.** `specs/1.0.4-beta/08-review-backlog/decision-8-language.md` (§1–§11),
`docs.md`, `specs/1.0.4-beta/MIGRATION.md`, `specs/1.0.4-beta/EXAMPLES.md`, `libs/std/src/**`,
`examples/**`, and the five libraries' `src/**` and `docs.md`. **`MIGRATION.md` and `EXAMPLES.md` are
not in the compiler repository** — `docs.md:17` links to the specs repository, and that is where they
live; a reader of `botopink-lang` alone cannot find them.

**Headline.** Beyond decision 14's seven:

| | Count |
|---|---|
| forms the documents write that **do not parse** | **24** — the 6 real forms of decision 14 (see [`seven-forms.md`](./seven-forms.md#what-the-seven-really-are)) plus **18 more** |
| forms that parse but **check in a way that contradicts the document that writes them** | **22** |
| of those 22, already owned by a front | **17** — [`01-checker`](../01-checker/README.md) steps 1–5 and 7 |
| of those 22, owned by **nobody** | **5** |
| forms confirmed working that a document says are **not implemented** | **4** — `docs.md`'s "decided, not yet implemented" table is stale in the compiler's favour |

**The single largest finding is not in decision 14's list at all**: there is **no index expression**
in the grammar. `a[0]` is a parse error in every position.

---

## (b) Written and does not parse — 24

**D** = the front's judgement is **defect** (a document promises the form and the compiler contradicts
it). **?** = **decision** (the language may simply not want it; recording the absence is the whole
work). The owner column is what the front proposes; the maintainer takes it.

### Already settled by decision 14 — 6

| Form | Written at | Diagnostic | | Owner |
|---|---|---|---|---|
| `adder(3)(4)` | `tests/language/test/closure_capture.bp:5` | `Unexpected token` at the second `(` | D | **15**, step 4 |
| `("ab").length`, `(a == b).toString()` — **any** `(expr).method` | `decision-8:178` reads `.length` off a narrowed value | `Unexpected token` at the `.` | D | **15**, step 4 |
| `#(a: i32, b: string)[]` | decision 8 §6 writes labeled tuples | `Unexpected token` at the `[` | D | **15**, step 4 |
| `x ?? 0` | — | `Unexpected token` | ? | **15**, step 3 — a named diagnostic |
| `var n = 0;` at module level | — | `Unexpected token` at `var` | ? | **15**, step 3 — a named diagnostic |
| a bare `if` with no `;` before the next statement | — | `Unexpected token` at the next statement | ? | **15**, step 2 — a grammar decision, and `loop` and `case` behave identically |

### New — the array-suffix family completes decision 14's fourth form — 2

| Form | Written at | Diagnostic | | Owner |
|---|---|---|---|---|
| `(i32 \| string)[]` — **and any parenthesised type at all**, e.g. `(i32)` | `decision-8:141`, as *the* way to spell an array of a union | `Unexpected token` at the `(` | **D** | **15**, step 4 |
| `@Result<i32, string>[]` — a builtin generic with an array suffix | the shape `decision-8:27` writes for a user generic (`Box<Option<i32>>[]`, which **does** parse) | `Unexpected token` at the `[` | **D** | **15**, step 4 |

Both are the same missing rule as `#(…)[]`: `parseBaseTypeRef` applies the `T[]` wrap once, on the
named-type path only (`parser/types.zig:293-300`), and three arms `return` before reaching it. The
`(…)` form has no arm at all. **`decision-8:141`'s spelling is unwritable**, and the unparenthesised
`i32 | string[]` — which parses — means something else.

### New — the six the front judges defects — 6

Two of them have no owner at all; the other four are this front's, and each has a named deciding line.

| Form | Written at | Diagnostic | | Owner |
|---|---|---|---|---|
| **`xs[0]` — there is no index expression** | `decision-8:112` lists indexing among the operations `unknown` refuses, which presupposes it exists | `Unexpected token` at the `[`, in **every** position: read, write, string, dict | **D** | **unowned — a decision** |
| `xs[0..2]` — slicing | `decision-8:447`: "`..` belongs to iteration **and slicing** only" | `Unexpected token` | **D** | **unowned — a decision** |
| `//` comment inside an `if` **then**-branch or a lambda body — and every `loop (…) { x -> … }` body is a lambda body. A `//` in a fn body, a `test` body or an `if` **else**-branch parses | `docs.md:362`, `:540` — self-declared | `Unexpected token` on the comment | **D** | **15**, step 4 — two block loops inlined before `parseBlock` grew its options (`exprs.zig:162-179`, `:944-951`); the same two loops drop a blank line, which is [`16-formatter`](../16-formatter/README.md)'s G5 |
| `42.toString()` — a method on an **integer literal**. `"ab".toUpperCase()` parses | `libs/std/src/primitives.bp:33` declares `Integer.toString` | `Unexpected token` at `toString` | **D** | **15**, step 4 — `lexer.zig:544` |
| `fn emit(source: string)` — a bodyless top-level fn with **no return type**. `) F` and `) noreturn` both parse | `libs/std/src/builtins.d.bp:194`, `:309` — **`libs/std` declares three of them** | `Unexpected token` | **D** | **15**, step 2 → a decision |
| `#(x: 1, y: 2)` — labeled tuple **construction** | `MIGRATION.md:299` classifies it as a *checker* gap ("parses today and is simply accepted") | `There must be a 'val' or 'var' to bind a variable to a value` — a parser refusal, with an unrelated message | **D** | **15** for the message; the form is **01**'s §6 |

`42.toString()`'s deciding line is exact: `lexer.zig:544` consumes a `.` after a digit run whenever
the character after it is not another `.`:

```zig
if (!self.isAtEnd() and self.peek() == '.' and self.peekNext() != '.') {
```

so `42.toString` lexes as the number `42.` followed by the identifier `toString`. One more clause —
the next character must be a digit — closes it, and the `..` guard already in place shows the shape.

### New — plausibly deliberate, listed so the absence is on the record — 10

| Form | Written at | Diagnostic | | Owner |
|---|---|---|---|---|
| `Box<i32>(value: 1).get()` — explicit type arguments at a **constructor call** | `decision-8:60-64` (`>` followed by `(` is a type-argument list) | `There must be a 'val' or 'var'…` | **D** | **01**, §1.3 — the parser half is 15's if 01 wants it |
| `.Circle(radius: 1.0)` — a leading-dot variant in **expression** position | only the **pattern** position is written (`MIGRATION.md:193`) | `Unexpected token` at the `(` | ? | **15**, step 2 |
| a `fn` inside an enum **section** body | `decision-8:313` says so in as many words | `Unexpected token` at `fn` | ? | **01**, step 4 already claims it |
| `[..a, 3]` / `[...a, 3]` — array spread in an expression | not written; `[first, ..rest]` **patterns** are | `Unexpected token` | ? | **15**, step 2 |
| `implement A for P { … }` at top level | not written — `type P(…) implement A` is the form | `Unexpected token` at `for` | ? | **15**, step 2 |
| a standalone `extend P { … }` | not written; the keyword appears only in a diagnostic | `An \`implement\`/\`extend\` block must be named` | ? | **15**, step 2 — **unverified** whether any spelling of a standalone `extend` exists |
| `1 << 2`, `a & b`, `a ^ b` — bitwise operators | not written | `unexpected character` / `Unexpected token` | ? | **15**, step 2 |
| `'a'` — a character literal | not written | `unexpected character` | ? | **15**, step 2 |
| `c ? 1 : 2` — a ternary | not written | `Unexpected token` | ? | **15**, step 2 |
| a nested `fn` inside a fn body | not written | `Unexpected token` | ? | **15**, step 2 |

---

## (c) Parses, and checks against the document — 22

**Most of this is already owned, and that is the point of listing it**: an audit that cannot tell
"nobody is working on this" from "front 01 step 2 is working on this" produces noise. 17 of the 22
belong to [`01-checker`](../01-checker/README.md).

### Owned by `01-checker` — 17

| Form | Written at | Today | 01's step |
|---|---|---|---|
| `case x { _ { 1 } }` as a **value** | `MIGRATION.md:25`, `decision-8:235-244` | `expected i32, got void` — the brace arm's body is never typed | step 4 |
| `case x { _ { n -> n + 1 } }` (§5.1 P1 whole-value binding) | `decision-8:255` | `expected i32, got function` | step 4 |
| `case x { i32 { … } }` — a type arm | `decision-8:238` | `expected i32, got function` | step 4 |
| `case r { #("SP", p) { p } _ { 0 } }` | `MIGRATION.md:179` | `expected i32, got void`; the **arrow** form checks | step 4 |
| `case r { #(0, ..) { 1 } … }` | `MIGRATION.md:202` | same | step 4 |
| `case x { 0 when (x == 0) { 1 } _ { 2 } }` | `decision-8:276-284` | same | step 4 |
| `case s { Shape.Circle(r) { … } .Square(s) { … } }` | `MIGRATION.md:192-193` | `non-exhaustive: missing variant(s) Circle, Square` — a **qualified or leading-dot** variant pattern contributes nothing to exhaustiveness, in the arrow form too | step 5 |
| `x is i32` as a value; `if (a is i32) { … }` | `decision-8:200-210` | `expected bool, got void` — `is` produces `void` | step 3 |
| `assert x is Some(n)` | `decision-8:223` | `error[is-variant-binding]` — a direct contradiction of §4.2, and [decision 25](../../../1.0.5-beta/decisions-taken.md) settles it: `is` does not bind | step 3 / closed |
| `val v: i32 \| string = 1;`; `f(1)` into a union parameter | `decision-8:140`, `:173` | `expected \|, got i32` — nothing is assignable **into** a union, so a union parameter can never receive an argument | step 2 |
| `case v { i32 { … } string { … } }` on a union | `decision-8:176-180` | `expected i32, got union` | steps 2, 4 |
| `val a: unknown = 42;`; `-> unknown` | `decision-8:104`, `:155` | `expected unknown, got i32` | step 1 |
| `val xs = [1, "a"]`; `if (c) { 1 } else { "a" }`; `[1, 2.5]`; `if (c) { 1 } else { null }` | `decision-8:147-152` — each with its inferred type, and `:150` says "no error" | four separate `type mismatch`es | step 2 |
| `first<string>([])` | `decision-8:67` | `expected string, got bool` — `<` is read as comparison, so the call becomes a `bool` | step 6 |
| a fn parameter default is not applied — `greet("world")` | `docs.md:384` | `'greet' expects 2 argument(s), got 1` | step 7 |
| `fn get(b: Box)` — a generic without its type arguments is silently accepted | `MIGRATION.md:297`, `decision-8:19-27` | accepted, no diagnostic | step 6 |
| `var out = [];` / `pub val z = [];` unannotated | `decision-8:155` | accepted, no warning | steps 1, 6 |

### Owned by nobody — 5

| Form | Written at | Today | Proposed owner |
|---|---|---|---|
| **`Option.None`, `Option<i32>.None`, `Some(1)`** | `decision-8:66`, `:84`, `docs.md:396` | `unbound variable 'Option'` / `'Some'` — **no `Option` enum is in scope at all**, although `?T` optionals and `.unwrapOr()` work | **unowned** — `libs/std`, and the same shape as [decision 2](../../../1.0.5-beta/decisions-taken.md#2-optiont-does-not-exist-either) ("`?T` is the only spelling"), which suggests the documents are wrong rather than the compiler |
| **`any`** parses and checks, and `libs/std/src/builtins.d.bp:88` uses it as a default type argument (`behavior It<T, E = any, C = void>`) | `decision-8:129-133` says `any` **does not exist** | accepted everywhere | **unowned** — the standard library depends on a type the language decision deletes |
| `#[@asyncGenerator] fn f() -> @AsyncGenerator<i32>` | `decision-8:436`, `MIGRATION.md:238` | `effect-wrapper-mismatch: requires -> @AsyncIterator<…>` | **08-hygiene** — [decision 1](../../../1.0.5-beta/decisions-taken.md#1-asyncgeneratort-does-not-exist) settled the compiler is right; the two documents still say otherwise |
| `#[@External.Node("$stringify($0)")]` | `libs/std/src/builtins.d.bp:156` | `compilation failed  PrimOpStringifyUnsupported` on node; the erlang target accepts it | **04-js** |
| `loop { break 1; }` yields an **array**, not the value | `docs.md:533` | an array | **02-erlang** / **04-js** — already in their rows |

---

## What the documents say is missing and is not

`docs.md`'s "Decided, not yet implemented" table is stale in the compiler's favour. Four rows:

| `docs.md` says | Measured at `c2dd780` |
|---|---|
| `:535` — `val assert Ok(value) = …` leaves the binding unbound | **binds**, and checks |
| `:536` — the no-`catch` form "aborts the parser" | refused with exactly the diagnostic `decision-8:428` asks for |
| `:534` — `1...9` in a pattern is not parsed | parses and checks; `1..9` is refused with `error[pattern-range-exclusive]` naming `...` |
| `:532` — brace `case` arms are not parsed | they **parse** (they do not type — see (c) above) |

A reader who trusts that table routes around four forms that work and writes the one form —
brace arms — that parses and then fails to type. **Correcting it is `08-hygiene`'s**, and this front
hands it over rather than editing `docs.md`.

## Two shapes worth naming, because they are patterns and not rows

**1. A rule applied on one path and copied onto some others.** `parseBaseTypeRef`'s `T[]` wrap exists
**twice** — once on the named-type path (`types.zig:293-300`) and once copied into the `unknown` arm
(`:88-95`) — and is absent from the tuple arm and the builtin-generic arm. `parsePostfixChain` is
called from seven arms of `parsePrimary` and not from the eighth. In both cases the gap is not a
decision anyone took; it is a rule that was never hoisted, and the forms that fall through it are
found one at a time, by accident, forever. **Step 4 hoists both**, which is the difference between
closing decision 14's four forms and closing the reason there were seven.

**2. One diagnostic for forty-eight kinds of wrong.** `ParseErrorType` has 48 variants and `print.zig`
renders a named, located message for 47; every form in (b) above hits the 48th,
`unexpectedToken` — "Unexpected token" and "Check the syntax around this position." A reader cannot
tell a form the language decided against from one nobody has written yet, which is exactly how
`??`, module-level `var`, `a[0]` and the rest went unfiled. **Step 3 is the smaller half of this front
and the half that stops the next seven from being found by accident.**

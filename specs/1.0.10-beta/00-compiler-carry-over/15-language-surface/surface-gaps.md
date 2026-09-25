# The written surface against the parser

Every concrete spelling the project's documents and sources write, probed against the compiler.

**Method.** **268 probes** at `botopink-lang` `c2dd780`, each a minimal module dropped into a scratch
project and run through `botopink check` with `BOTOPINK_LIB_ROOTS` pointing at the worktree's `libs/`.
A form "parses" when the diagnostic is not a parse error; it "checks" when `check` exits 0. Rows the
front's R1–R8 closed (the array-suffix family, `(expr).method`, `adder(3)(4)`, `42.toString()`, the
`//` comment inside a then-branch or lambda body, the index and slice, the bodyless fn) are not
listed; [`README.md`](./README.md) § *Current state* carries them.

**Sources walked.** `specs/1.0.4-beta/08-review-backlog/decision-8-language.md` (§1–§11),
`docs.md`, `specs/1.0.4-beta/MIGRATION.md`, `specs/1.0.4-beta/EXAMPLES.md`, `libs/std/src/**`,
`examples/**`, and the five libraries' `src/**` and `docs.md`. **`MIGRATION.md` and `EXAMPLES.md` are
not in the compiler repository** — `docs.md:17` links to the specs repository, and that is where they
live.

---

## (b) Written and does not parse

**D** = **defect** (a document promises the form and the compiler contradicts it). **?** =
**decision** (the language may simply not want it; recording the absence is the whole work).

### Decided absent — the message is the work

| Form | Written at | Diagnostic | | Owner |
|---|---|---|---|---|
| `x ?? 0` | — | `Unexpected token` | ? | **15**, step 3 — a named diagnostic (decision 14) |
| `var n = 0;` at module level | — | `Unexpected token` at `var` | ? | **C-05** — decision 28: it parses |
| a bare `if`, `loop` or `case` with no `;` before the next statement | — | `Unexpected token` at the next statement | ? | **C-13** — decision 29 (c) |

### A defect with a named deciding line

| Form | Written at | Diagnostic | | Owner |
|---|---|---|---|---|
| `#(x: 1, y: 2)` — labeled tuple **construction** | `MIGRATION.md:299` classifies it as a *checker* gap ("parses today and is simply accepted") | `There must be a 'val' or 'var' to bind a variable to a value` — a parser refusal, with an unrelated message | **D** | **15** for the message; the form is **01**'s §6 |
| `#[mark(-20)]` — a negative literal as a decorator argument | rakun front 07's ordering band | `this token cannot appear here · unexpected `20`` — the caret on the digits | **D** | **15**, step 4b |

### Plausibly deliberate, listed so the absence is on the record — 10

| Form | Written at | Diagnostic | | Owner |
|---|---|---|---|---|
| `Box<i32>(value: 1).get()` — explicit type arguments at a **constructor call** | `decision-8:60-64` (`>` followed by `(` is a type-argument list) | `There must be a 'val' or 'var'…` | **D** | **01**, §1.3 — the parser half is 15's if 01 wants it |
| `.Circle(radius: 1.0)` — a leading-dot variant in **expression** position | only the **pattern** position is written (`MIGRATION.md:193`) | `Unexpected token` at the `(` | ? | **15**, step 3 |
| a `fn` inside an enum **section** body | `decision-8:313` says so in as many words | `Unexpected token` at `fn` | ? | **01**, step 4 |
| `[..a, 3]` / `[...a, 3]` — array spread in an expression | not written; `[first, ..rest]` **patterns** are | `Unexpected token` | ? | **15**, step 3 |
| `implement A for P { … }` at top level | not written — `type P(…) implement A` is the form | `Unexpected token` at `for` | ? | **15**, step 3 |
| a standalone `extend P { … }` | not written; the keyword appears only in a diagnostic | `An \`implement\`/\`extend\` block must be named` | ? | **15**, step 3 — **unverified** whether any spelling of a standalone `extend` exists |
| `1 << 2`, `a & b`, `a ^ b` — bitwise operators | not written | `unexpected character` / `Unexpected token` | ? | **15**, step 3 (`language-gaps.md`'s first row) |
| `'a'` — a character literal | not written | `unexpected character` | ? | **15**, step 3 |
| `c ? 1 : 2` — a ternary | not written | `Unexpected token` | ? | **15**, step 3 |
| a nested `fn` inside a fn body | not written | `Unexpected token` | ? | **15**, step 3 |

---

## (c) Parses, and checks against the document — 22

17 of the 22 belong to [`01-checker`](../01-checker/README.md); the step column is 01's, mapped to
C-items in [`../README.md`](../README.md).

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
| `assert x is Some(n)` | `decision-8:223` | `error[is-variant-binding]` — decision 25 settles it: `is` does not bind | step 3 / closed |
| `val v: i32 \| string = 1;`; `f(1)` into a union parameter | `decision-8:140`, `:173` | `expected \|, got i32` — nothing is assignable **into** a union | step 2 |
| `case v { i32 { … } string { … } }` on a union | `decision-8:176-180` | `expected i32, got union` | steps 2, 4 |
| `val a: unknown = 42;`; `-> unknown` | `decision-8:104`, `:155` | `expected unknown, got i32` | step 1 |
| `val xs = [1, "a"]`; `if (c) { 1 } else { "a" }`; `[1, 2.5]`; `if (c) { 1 } else { null }` | `decision-8:147-152` — each with its inferred type, and `:150` says "no error" | four separate `type mismatch`es | step 2 |
| `first<string>([])` | `decision-8:67` | `expected string, got bool` — `<` is read as comparison | step 6 |
| a fn parameter default is not applied — `greet("world")` | `docs.md:384` | `'greet' expects 2 argument(s), got 1` | step 7 (C-04; the cross-module half is open) |
| `fn get(b: Box)` — a generic without its type arguments is silently accepted | `MIGRATION.md:297`, `decision-8:19-27` | accepted, no diagnostic | step 6 (C-15) |
| `var out = [];` / `pub val z = [];` unannotated | `decision-8:155` | accepted, no warning | steps 1, 6 |

### Owned by nobody — 5

| Form | Written at | Today | Proposed owner |
|---|---|---|---|
| **`Option.None`, `Option<i32>.None`, `Some(1)`** | `decision-8:66`, `:84`, `docs.md:396` | `unbound variable 'Option'` / `'Some'` — no `Option` enum is in scope, although `?T` optionals and `.unwrapOr()` work | the documents are wrong — decisions 2 and 32: `?T` is the only spelling; C-18's document corrections |
| **`any`** parses and checks, and `libs/std/src/builtins.d.bp` uses it as a default type argument on the generator wrappers (`@ResultGenerator<T, E = any>`, `@FutureGenerator<T, E = any>` under decision 103) | `decision-8:129-133` says `any` **does not exist** | accepted everywhere | C-18 (decision 31) — the standard library depends on a type the language decision deletes |
| `#[@asyncGenerator] fn f() -> @AsyncGenerator<i32>` | `decision-8:436`, `MIGRATION.md:238` | the spelling is `#[@futureGenerator] fn f() -> @FutureGenerator<T, E>` (decisions 98 and 103); the two documents still write `@AsyncGenerator` | **08-hygiene** — decision 1 settled the compiler is right |
| `#[@External.Node("$stringify($0)")]` | `libs/std/src/builtins.d.bp:156` | `compilation failed  PrimOpStringifyUnsupported` on node; the erlang target accepts it | **04-js** |
| `loop { break 1; }` yields an **array**, not the value | `docs.md:533` | an array | **22-loops** — decision 105: `break v` outside a generator scope is refused; a loop is a statement |

---

## What the documents say is missing and is not

`docs.md`'s "Decided, not yet implemented" table is stale in the compiler's favour. Four rows:

| `docs.md` says | Measured at `c2dd780` |
|---|---|
| `:535` — `val assert Ok(value) = …` leaves the binding unbound | **binds**, and checks |
| `:536` — the no-`catch` form "aborts the parser" | refused with exactly the diagnostic `decision-8:428` asks for |
| `:534` — `1...9` in a pattern is not parsed | parses and checks; `1..9` is refused with `error[pattern-range-exclusive]` naming `...` |
| `:532` — brace `case` arms are not parsed | they **parse** (they do not type — see (c) above) |

Correcting it is `08-hygiene`'s; this front hands it over rather than editing `docs.md`.

## One diagnostic for forty-eight kinds of wrong

`ParseErrorType` has 48 variants and `print.zig` renders a named, located message for 47; every form
in (b) hits the 48th, `unexpectedToken`. A reader cannot tell a form the language decided against
from one nobody has written yet, which is how `??`, module-level `var` and `a[0]` went unfiled.
Step 3 of the [README](./README.md) is the half that stops the next seven from being found by
accident.

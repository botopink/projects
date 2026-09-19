# Decisions taken — 1.0.5-beta

Answered by the maintainer, kept here as the record the fronts implement against. The numbering is
the one they had in [`decisions-pending.md`](./decisions-pending.md), which never reuses a number.

**One reading trap, because it is in several sections at once.** A front named by a number that
[`fronts.md`](./fronts.md) does not carry — front 20 — or named in a past tense for work this
milestone's front of that number has not started — front 06's grammar and support passes, front 17's
cells, front 15's `example-programs.md` — is **1.0.4-beta's** numbering, kept as it was written. This
milestone's owner is the one the *Decided* line names; where a `Blocks:` line still carries the old
number it is corrected in place, in brackets.

| # | Question | Answer |
|---|---|---|
| [1](#1-asyncgeneratort-does-not-exist) | `@AsyncGenerator<T>` or `@AsyncIterator<T>`? | correct the spec to `@AsyncIterator<T>` |
| [2](#2-optiont-does-not-exist-either) | Is `Option<T>` a spelling? | no — `?T` is the only one |
| [4](#4-the-order-that-dissolves-the-circular-dependency--settled) | The milestone's order | `06` → `14` → `13` → backends — **amended by [62](#62-the-order-of-what-is-left-in-the-milestone)**, whose own correction then makes the question moot: `06`'s layout step landed before this session (`579ab0d`) |
| [7](#7-a-types-methods-are-function-not-method) | LSP `Method` or Test Explorer? | the extension gives way |
| [8](#8-beam-as-a-target-of-the-language-suite) | `beam` in the language suite? | yes — it executes |
| [9](#9-arrayunique-is-broken-on-both-backends) | Who fixes `Array.unique`? | rewrite the body in `libs/std` |
| 3 | Is `import { X };` a form at all? | both forms stay — the shorthand is made to resolve |
| 5 | What *is* a value on the JS backends? | a class per declaration, a subclass per variant |
| [6](#6-the-erlang-output-layout--with-the-two-trees-written-out) | Flat or nested erlang output? | flat, one directory per target — scope corrected: `out/erl/` and `out/beam/`; commonJS and wasm keep `out/<module path>` |
| 10 | `@code` taken twice | rename the proposed annotation |
| 11 | `<Pattern> as <name>` | delete the form and its tests |
| 12 | Unnamed variant payloads | rejected, with a located diagnostic |
| 13 | `external-annotations.md`'s C1/C8 | steps of `01-checker` |
| [14](#14-seven-forms-that-do-not-parse) | Seven forms that do not parse | four parse, three absent, the rest to `15-language-surface` — **amended by [28](#28-what-decision-14-left-unassigned)**: every form is supported, no slot is absent |
| 15 | A lower-case `#[@external(node, …)]` | a located error |
| 16 | The `mod` path warning | fix the cause; do not exempt or document — **implemented 2026-09-18, and it converged on option (b); see the note below** |
| 17 | rakun's erlang story | rakun supports every target; `libs/std` grows to carry it |
| [18](#18-emilias-tokensbp-and-format---check) | emilia's `tokens.bp` and `format --check` | exempt now; `16-formatter` audits the formatter — the exemption is **withdrawn by [34](#34-the-format---check-exemption-does-not-exist)** |
| 19 | The comptime renderer's `id` | removed |
| [20](#20-is-a-pattern-range-inclusive) | Is a pattern range inclusive? | one spelling — `..`, as in Zig; `...` leaves the grammar — **amended by [53](#53-the-range-spelling-is-zigs-split--inclusive-in-a-pattern--exclusive-in-a-slice)**: `...` stays, inclusive, as the pattern spelling |
| [21](#21-t1-or-t2-for-the-erlang-record) | Tagged map or tagged tuple? | T2, the tagged tuple — measured cost of the choice: **354 cell-writes over 210 files** |
| 22 | Who designs wasm's boxed value? | `13-module-identity`, for every backend |
| 23 | Does a `behavior` need an atom? | reserve `__b__`, emit nothing |
| [24](#24-does-step-3-of-14-comptime-on-beam-happen-at-all) | Does step 3 of 14 happen? | every step — the principle governs; **[62](#62-the-order-of-what-is-left-in-the-milestone) defers it until after `13`** |
| 25 | Does `is` carry a pattern? | no; `case` is the only construct that binds |
| 27 | Who declares `behavior Display`? | `01-checker`, in `libs/std` |
| 26 | `case` arms of different types | they union — inference may produce a union |
| 35 | Structural equality | structural — it follows from 37 |
| 37 | Is a record immutable? | **yes** — the checker rejects `p.f = v` |
| [29](#29-does-a-block-shaped-statement-end-itself) | Does a block-shaped statement end itself? | **(c)** — no `;` after a **braced** block ([60](#60-the-parser-accepts-an-optional--before-the-formatter-picks-a-side) narrows it); **245** sites migrate |
| 30 | Is there an index expression? | **yes** — `xs[0]` parses everywhere |
| [31](#31-does-any-exist) | Does `any` exist? | deleted, for now; `Iterator` gets a real default — **not landed**, and `any` is the host vocabulary of `erlang.bp` / `beam.bp`, not one use |
| 32 | `Option.None` / `Some(1)` in value position | removed from the documents; the optional is `?T` |
| [33](#33-a-bodyless-fn-with-no-return-type) | A bodyless `fn` with no return type | **(b)** — it declares one; **one** `libs/std` line gains `-> void` (measured; the estimate said three) |
| 34 | The `format --check` exemption | **(c)** — no exemption; decision 18's is withdrawn |
| [36](#36-does--exclude-its-end-in-a-pattern) | Does `..` exclude its end in a pattern? | yes — exclusive everywhere — **amended by [53](#53-the-range-spelling-is-zigs-split--inclusive-in-a-pattern--exclusive-in-a-slice)**: `..` is not a pattern spelling; in a pattern it is `...`, inclusive |
| [28](#28-what-decision-14-left-unassigned) | What decision 14 left unassigned | **every form is supported**; five distinct forms, none absent — module-level `var`'s grammar is the half still unlanded |
| 38 | Is a `val` immutable? | **yes** — assigning to one is a located error naming `var` |
| 39 | Who creates the ETS table? | the module emits a registered owner process |
| 40 | `+=` under `Ets` on a non-integer | **(a)** — refused, with the recomposition diagnostic |
| 41 | Is a misspelled `@BeamMemory` an error? | **(a)** — the member and the argument names are validated; the three members stand |
| 42 | A `Dict` under `Ets` with `keyed` unwritten | **(b)** — the default stands, no warning; `docs.md` carries it |
| 51 | `keyed = true` on a `List<T>` | **(c)** — `keyed` is a `Dict`-only argument; on a list it is the "needs a keyed container" error |
| 52 | A condition loop that never breaks | **(a)** — `null` on every backend; erlang and beam stop answering the variable group |
| [54](#54-a-t-is-matched-by-null-and-a-binder) | The pattern surface of a `?T` | **(b)** — `null` and a binder; `.Some(v)` / `.None` on a `?T` becomes an error — and the `null` arm **does not parse yet**: a parser row as well as a checker one |
| 57 | Does `comptime/**` get a warning channel? | **yes** — a `warnings` list on the `Env`, inside a row of `01-checker` |
| 58 | Who owns the inline `implement { }` check? | `01-checker` — the same check as the separate block |
| 59 | Who recounts `expected-failures.txt`'s tally? | whoever deletes a line, **from the file** — never from their own delta |
| 53 | The range spelling | **(a)** — amend 20 and 36 to Zig's split: `...` inclusive in a pattern, `..` exclusive in a slice and a range |
| 55 | `break <value>` in a collection loop | **(a)** — it contributes its value **and ends the loop** |
| 56 | `run --target erlang`'s exit status | **(a)** — take `erl`'s `1`; the contract is amended in the same commit |
| 60 | Decision 29's impossible order | **(b)** — the parser accepts `;` as optional first, as its own landing; **(c)** amends the wording |
| [61](#61-the-formatters-canonical-layout--four-rules) | The formatter's canonical layout | four rules, all the conventional form — see below; B4's shape **already parses**. **Landed**: 607 lines across six trees, and `fits` is broken underneath it ([question 65](./decisions-pending.md#65-does-the-formatter-learn-to-measure-width)) |
| [62](#62-the-order-of-what-is-left-in-the-milestone) | The order of what is left | 06 after 01's steps 4–5 — **moot, 06 landed at `579ab0d`** · 13's halves 2–3 now · 14 step 3 after 13 · BR5 out of 1.0.5 · `std/beam` before 17 · three defects this wave |
| [43](#43-beammemory-lives-in-two-layers--and-off-the-beam-the-annotation-is-a-no-op-while-the-module-is-an-error) | Where does `@BeamMemory` live? | **(b)** two layers; the no-op/hard-error tension resolves as **(a)**; `Cluster` stays out of the core — layer 1 landed; layer 2's route to it is [question 64](./decisions-pending.md#64-how-does-beammemorys-layer-2-reach-layer-1-when-the-erlang-backend-emits-no-wrapper) |
| 44 | Is `optional<i32>` a valid spelling? | **(a)** — refused; `?T` is the only spelling |
| 45 | Is a member access on a `?T` an error? | **(a)** — yes, naming `?.` |
| 46 | What does `d["k"]` answer on a `Dict`? | **(a)** — the checker records the receiver, each backend routes to `lookup` |
| [47](#47-absent-has-one-spelling-null) | Is an out-of-range read `undefined` or `null`? | **(a)** — one spelling of absent: `null`; three backends to move, and the read's *type* is [decision 63](#63-an-index-answers-t-and-an-absent-key-fails-rather-than-answering) — `T`, with an absent key a **failure** |
| 48 | Who teaches the formatter to print `var`? | **(a)** — a named carve-out of `format.zig` for `17`, in the same commit as the form |
| 49 | When does `17` open? | **(a)** — after `01`'s step 4 is committed |
| 50 | How much of `17` runs in 1.0.5-beta? | **(a)** — steps 0–3b; steps 4–8 become a spec for the milestone after `13` |
| [67](#67-the-most-restrictive-behaviour-and-no-configuration-that-bypasses-it) | How strict, and may it be configurable? | **the most restrictive behaviour, and no configuration that bypasses it** — a standing principle: stricter side by default, exemptions **structural** and never a knob |
| [63](#63-an-index-answers-t-and-an-absent-key-fails-rather-than-answering) | Does an index answer `T` or `?T`? | **superseded 2026-09-19** — `xs[k]` is sugar for `xs.at(k)`, so the type is the method's: see the amendment below |
| [66](#66-format---check-looks-at-the-whole-project--and-something-has-to-call-it) | Does `format --check` look at the whole tree? | **(a)** — every `.bp` and `.d.bp` of a project, gated on the parse defects, with `tests/language/reject/**` exempt; and it needs a **caller**, because no gate runs it today |
| [64](#64-the-erlang-backend-emits-a-wrapper-per-host-bound-std-declare-fn--and-stdbeam-stays-its-own-module) | How does `@BeamMemory`'s layer 2 reach layer 1? | **(a)** — the erlang backend emits a wrapper per host-bound std `declare fn`; and **(i)**, `std/beam` stays its own module |

---

## 1. `@AsyncGenerator<T>` does not exist

**Decided 2026-09-18 by the maintainer: (a).** The spec is corrected to `@AsyncIterator<T>`;
`01-checker`'s N25 text follows it.

**Measured.** [`decision-8-language.md` §9](../1.0.4-beta/08-review-backlog/decision-8-language.md)
pairs the annotation `#[@asyncGenerator]` with the return type `@AsyncGenerator<T>`. The annotation
exists — `infer.zig` handles `.asyncGenerator` — but **the type does not**: `libs/std/src/builtins.d.bp`
declares `behavior AsyncIterator`, and 39 files across the compiler and the standard library write
`AsyncIterator`. Front 06 implemented N25 (an effect's annotation must agree with its wrapper) using
the spelling that exists.

**Options.** (a) Correct the spec to `@AsyncIterator<T>`. (b) Rename 39 files' worth of `AsyncIterator`
to `AsyncGenerator`, and with it the `behavior` a user implements.

**Recommendation: (a).** The code is the reality here, the two names mean the same thing, and the
rename would touch a public `behavior` name for no semantic gain. The spec is one table row.

**Blocks:** decision 8 §9 being a true document; 03's N25 acceptance text *(read `01-checker`'s — the
Decided line above names it, and `03` here is the previous milestone's numbering)*.

---

---

## 2. `Option<T>` does not exist either

**Decided 2026-09-18 by the maintainer: (a).** `?T` is the only spelling; decision 8's `Option<…>`
lines are corrected. **One sub-question the decision opens, and it is the real one:** how does `case`
read an optional? Today `if (x) { v -> … }` unwraps and `case` has no null arm, so a `case` over `?T`
has nothing to name the absent side with.

**Recommendation.** `.Some(v)` and `.None` in pattern position only — the two spellings decision 8
already uses, bound to `?T` rather than to a type called `Option`:

```botopink
val name: ?string = lookup(id);
val label = case name {
    .Some(n) { n }
    .None    { "unknown" }
};
```

That keeps one type (`?T`), gives `case` two arms to be exhaustive over, and asks nothing new of the
backends: `.Some`/`.None` are already patterns the parser accepts. `01-checker`'s step 4 types them
against `?T` instead of against a named enum.

**Measured.** `builtins.d.bp:56-58` says it in as many words: "The optional type is `?T` — the ONLY
spelling. Optional is not a concrete named type: `Option<T>` / `Optional<T>` annotations are rejected
with a pointed diagnostic." Decision 8 nonetheless writes `Option<i32>.None` and `Option.Some(v)`
across seven sections, and `val z = Option<i32>.None;` answers `unbound variable 'Option'` (front 15,
`example-programs.md`).

**Options.** (a) Correct decision 8 to `?T`, with `.Some` / `.None` in pattern position only.
(b) Introduce `Option<T>` as a real named type alongside `?T`.

**Recommendation: (a).** (b) buys a second spelling for one concept and costs inference, four
backends, the printer and every document — while `.Some(v)` / `.None` already work as patterns, which
is where decision 8 actually uses them. If the goal is a value-position constructor, that is a
separate, smaller question: `?T`'s constructor, not a new type.

**Blocks:** 02's `case` cells over optionals *(1.0.4-beta's numbering — in this milestone the cells are
[`12-language-tests`](./12-language-tests/README.md)'s, as
[decision 54](#54-a-t-is-matched-by-null-and-a-binder) records)*; the correctness of decision 8
§§2–5 and §9.

---

---

## 4. The order that dissolves the circular dependency — **settled**

**Decided 2026-09-18 by the maintainer: `14-comptime-on-beam` first, then `13-module-identity`, then
the backend fronts.** Kept here because it is the decision the rest of the order rests on, and because
it has a price that has to stay visible.

**What it dissolves.** Decision 8's run-time half needs a value that knows its own type — on erlang a
record is a map with no tag, so `Person(name: "a", age: 1) == Vec(name: "a", age: 1)` answers **true**.
That identity is 13's third half, and 13 used to be ordered *after* the backends, which is a cycle.
With 13 first the identity already exists when 02–05 lower `is`, unions, `case` over named types and
the per-type formatter. The cut that was going to break the cycle (backends keep primitives, tuples,
the wasm box and `loop`; the named-type half goes to 13) is **no longer needed** — it survives in
[`13-module-identity/halves-and-ordering.md`](./13-module-identity/halves-and-ordering.md) §5.2 as the
fallback, and becomes necessary again only if 02 or 03 is opened before 13's second and third halves
land.

**It also settles two smaller things.** 14's step 2 makes the comptime module **keyed by declaration**,
which is exactly the key `erlDeclAtom` wants, so 13 inherits `buildModule` instead of fighting it; and
every snapshot is written once instead of 13 re-recording 318 cells on top of what the backends had
just produced.

**The price, measured.** `02-erlang` and `03-beam` **stand still** while 13's second and third halves
run: 13 owns `erlang.zig` and `beam_asm.zig` wholesale there and re-records **318** cells in their two
directories. 13's first half is the exception — four atom sites, no emitted shape, a carve-out rather
than a stop. `04-js` and `05-wasm` are unaffected and run throughout.

**One ordering it does not settle** is `06-comptime-dedup` against 14, measured while verifying this
one: dedup first → 14 re-records **5** comptime cells; 14 first → **20**, of which dedup then deletes
15. Dedup first, by 15 mechanical re-recordings.

**Amended 2026-09-18 by [decision 62](#62-the-order-of-what-is-left-in-the-milestone).** What this decision was taken for survives whole:
`14-comptime-on-beam` before `13-module-identity`, and 13 before the backend fronts read the identity.
What does not survive is the position of `06-comptime-dedup`. 14 landed its steps 0–2 without it, and 62
puts 06 **after** `01-checker`'s steps 4–5, keeping it a prerequisite only for 01's steps 6–11 — so the
order in the summary row, `06` → `14` → `13` → backends, is read from 62 for that one move, here as
well as in [`fronts.md`](./fronts.md)'s Order section, which 62 also supersedes. The 15 mechanical
re-recordings measured just above are what 62 traded away deliberately: 01's step 4 was written and
waiting on the four backends, and re-laying the snapshot directory underneath it was the worse of the
two costs. **And 2026-09-18 the question dissolved rather than being answered**: 06's work is already in
`feat` at `579ab0d` — `snapshots/comptime/` holds the 338 files the front promised — so the first arrow of
this order describes work that has landed, and nothing is sequenced behind it. See 62's correction.

---

---

## 7. A type's methods are `Function`, not `Method`

**Decided 2026-09-18 by the maintainer: (a).** The extension recognises a test by its declaration,
and the language server emits `Method`. Both land in one sweep across the two repositories.

**Measured.** The language server reports a type's methods as `SymbolKind.Function`. Making them
`Method` is correct for the outline and **breaks the VS Code Test Explorer**, which classifies every
`Method` symbol as a `test "…"` block (`repository/vscode-extension/src/symbolNodes.ts`; the LSP
protocol has no `Test` kind).

**Options.** (a) Teach the extension to recognise a test by its declaration (`test "…"`), not by the
symbol kind, then emit `Method`. (b) Leave both as they are and document it.

**Recommendation: (a).** The outline is user-facing and wrong today; the Test Explorer's rule is an
internal shortcut that the extension owns. The two land in one sweep across the two repositories.

**The sub-question (a) forces:** how does the extension then recognise a `test "…"` block? By a
marker in the symbol's `detail`, by another `SymbolKind`, or **by its parent in the tree** — a `test`
block is a child of the file, a method is a child of a type. The last is the cheapest and the only
one that does not invent a convention; decide it with (a), because until then the language server is
kept wrong on purpose so that the extension stays right.

**Blocks:** `11-tooling`.

---

---

## 8. `beam` as a target of the language suite

**Measured — and this corrects an earlier recommendation.** `botopink test` refuses the beam target
and `botopink run --target beam` writes `out/main.S` and stops, which is why `tests/language/AGENTS.md`
records beam as non-executable. Front 06's support pass then ran the rest of the path: `erlc +from_asm
main.S` produces `main.beam`, and `erl -noshell -pa . -eval 'main:main(), halt().'` prints the
program's output. **The artefact executes, with a tool the gate already runs** (the beam export audit
is stage 5). The recorded reason does not hold.

**Options.** (a) Teach the runner the two extra commands and add beam as a third executable target.
(b) Keep beam's coverage in the codegen snapshots.

**Decided 2026-09-18 by the maintainer: (a)** — the suite runs on beam. The blocker was never
execution, it was a missing two-line path: `erlc +from_asm` then `erl -noshell -pa . -eval`, both
tools the gate already runs.

**Scheduling, which the decision leaves to the front:** 13's policy 3 changes how many `.S` files a
program emits and where they live, so a runner written against today's layout is written twice. It
lands as 13's closing step unless the maintainer wants beam coverage before then, at that price.

**Blocks:** `12-language-tests`'s coverage claim for beam, and `tests/language/AGENTS.md`, which
states a reason that measurement contradicts.

**Landed 2026-09-18, and not as scheduled.** The two-command path is in `run.sh` already, before 13's
closing step: front 12's header is a run with a beam column (`beam 14/20/0`), front 03 reports
`--target beam` at **18 / 16 / 0**, and the probe re-measured for
[decision 53](#53-the-range-spelling-is-zigs-split--inclusive-in-a-pattern--exclusive-in-a-slice)
runs on beam where it used to stop at `out/main.S`. So the scheduling paragraph above no longer describes
the tree: what 13's policy 3 will change is how many `.S` files a program emits and where they live, and
the runner written against today's layout is the one that has to be re-pointed then — which is a row of
13, not a reason to wait.

---

---

## 9. `Array.unique` is broken on both backends

**Decided 2026-09-18 by the maintainer: (b).** The body is rewritten in `libs/std` to avoid calling a
method on an optional inside a `default fn`. `01-checker` keeps the lowering as a row of its own, but
`Array.unique` stops being blocked on it.

**Measured.** `[1, 1, 2].unique()` fails on erlang (`function unwrapOr/2 undefined`) and on node
(`prev.unwrapOr is not a function`): its body calls a method on an optional (`prev.unwrapOr(x)`)
inside a `default fn`, a shape no backend lowers. The body is in `libs/std`, which has no owner; the
lowering is the checker's.

**Options.** (a) `01-checker` lowers a method call on an optional inside a `default fn` body, and
`libs/std` keeps the body it has. (b) Rewrite the body in `libs/std` to avoid the shape.

**Recommendation: (a), with (b) as the fallback** if the lowering turns out to need the typed-method
dispatch that is itself open. Either way the maintainer has to assign the `libs/std` edit, because no
front owns that file.

**Blocks:** a standard-library function that is documented and does not run.


---

---

## 3. The import surface, and the fence that documents it

**Decided 2026-09-18 by the maintainer: keep both forms, and make the shorthand work.** Not the
counter-proposal — the rule is that `import { Element };` is a form of the language and must resolve
the sibling module correctly, beside `import { Element } from "element";`. So the work is: the
shorthand resolves by name and emits the right `require`, an unresolved import is a located error
(front 20's patch lands), and `docs.md`'s import section becomes a compiling cell teaching **both**
forms. The defect was never the form, it was the resolution.

**Reformulated 2026-09-18.** The question was put as "how do we keep the docs gate green", which is
the wrong half. The maintainer's rule is the right half: *the documentation shows the current form,
and a reference to another module is always written `import { <names> } from "<module>"`*. The fence
is then a consequence, not a decision.

**Measured.** Two import forms exist today:

```botopink
import { Element } from "element";   // names the module — always correct
import { Element };                  // the shorthand — no module named
```

The shorthand is what broke three libraries. It emits `require("../module")` on commonJS —
`emilia-card`, `jhonstart-counter`, `-html` and `-todo` all built and then died at run time with
`Cannot find module '../module'` — and front 13 fixed all four by **writing the module name in a
`from` clause**. It also passes `check` when the module does not exist at all, which is front 20's
defect A, implemented and parked.

**Counter-proposal.** Do not decide the fence. Decide the surface, and the fence follows:

1. **`import { X } from "<module>";` is the only form.** The shorthand is removed, with a located
   diagnostic naming the module the compiler would have guessed. One form, one meaning, and the
   `require("../module")` defect has no way to be reached.
2. **An unresolved import is a located error** — front 20's patch lands with it, no longer blocked.
3. **`docs.md`'s import section becomes a real compiling cell** (`docs-check: project modules`): a
   tiny project that declares `geometry` and `shapes/circle`, plus one line showing a library
   dependency. It teaches the one true form and the gate proves it.

**Cost, measured:** the shorthand appears in the five libraries only where front 13 already replaced
it; `grep -rn "^import {[^}]*};" repository/*/src libs/std/src` is the migration list, and it is short.

**Blocks:** front 20's defect A *(1.0.4-beta's numbering — in this milestone the unresolved-import
error is [`10-cli-residuals`](./10-cli-residuals/README.md)'s, and it is in `feat`)*; `08-hygiene`
step 3; every import example in the documentation.

---

---

## 5. What a value *is* on the JS backends

**Decided 2026-09-18 by the maintainer: the class-per-declaration, subclass-per-variant shape**, with
a payload-less variant as a singleton — exactly the sketch below. `13-module-identity`'s third half
therefore has nothing to do on the JS side: the prototype is the identity.

**Reformulated 2026-09-18**, after the maintainer's answer: *"os tipos e variantes no JS devem ser
vinculados ao polimorfismo prototype"*. That is a bigger and better question than the one asked, and
the measurement supports it.

**Measured** (`13-module-identity/representation.md`, from the emitted code):

| botopink | commonJS emits | Knows its own type? |
|---|---|---|
| `Person(name: "Ana", age: 30)` | `new Person("Ana", 30)` — **a real class** | **yes**, `instanceof` |
| `Shape.Circle(radius: 5)` | `{ tag: "Circle", radius: 5 }` — a plain object | partly, by reading `.tag` |
| `Shape.Dot` | `"Dot"` — **a bare string** | **no** |
| any of them, in the `.d.ts` | `declare class Person` · `{ tag: "Circle" }` · `{ tag: "Dot" }` | the last one **contradicts the `.js`** |

So the backend is already half prototype-based: a record is a class, a variant is not. The
inconsistency is the defect, and the bare string is only its sharpest edge.

**Counter-proposal — finish what the backend already does for records.** A `type` emits a class per
declaration and a subclass per variant:

```js
class Shape {}
class Shape$Circle extends Shape { constructor(radius) { super(); this.radius = radius; } }
class Shape$Dot    extends Shape {}
const Dot = new Shape$Dot();            // a payload-less variant is a singleton
```

What each decision-8 feature then becomes, on this backend, for free:

| Feature | Lowering |
|---|---|
| `x is Shape` | `x instanceof Shape` |
| `case x { .Circle(r) { … } .Dot { … } }` | `instanceof` per arm — exhaustiveness is the class list |
| §7 printing | a method on the prototype; a subclass overrides it |
| a union of named types | `instanceof A \|\| instanceof B` |
| the `.d.ts` | real classes, and the contradiction is gone |

It also explains a bug front 06 found and fixed by another route: commonJS emitted
`_match instanceof Ok`, testing a class **no module emits**, so every `val assert Ok(…)` fell through
to its handler. Under this proposal that code was right and the emitter was behind it.

**Cost, measured.** 315 commonJS snapshots change shape (25 of them carry a `tag:` object or a bare
string today, so the rest change only where a variant is constructed or matched); cross-module variant
identity needs the class imported, which the module system already does for types; a value handed to
a host JS library is a class instance rather than a plain object, which `JSON.stringify` renders the
same minus the `tag` field. `13-module-identity`'s third half then has **nothing to do on JS** — the
prototype *is* the identity.

**What the maintainer still owes:** confirmation that this is the shape wanted, since it is larger
than the question asked — and whether a record's class should also carry the variant machinery, or
only a `type` with variants gets subclasses.

**Blocks:** `04-js`'s decision-8 half; `13-module-identity`'s third half on the JS side.

---

---

## 6. The erlang output layout — with the two trees written out

**Decided 2026-09-18 by the maintainer: (a), flat**, one directory per target.

**Reformulated 2026-09-18:** the question was asked without showing what either answer looks like.
Here they are, for one project.

```
src/main.bp
src/models/user.bp        type Pessoa(nome: string, idade: i32)   behavior Greeter
src/services/user.bp      fn load(id: i32) -> Pessoa
```

Under `13-module-identity` this program is **five** BEAM modules: the three files' own modules, plus
one for `Pessoa` and one for `Greeter` (policy 3). `erlc` refuses a `-module` atom that does not equal
the file's basename, so the file name *is* the atom either way. The only question is which directories
hold them.

**(a) flat**

```
out/erl/main.erl
out/erl/models@user.erl
out/erl/models@user__t__pessoa.erl
out/erl/models@user__b__greeter.erl
out/erl/services@user.erl
```

**(b) nested**

```
out/erl/main.erl
out/erl/models/models@user.erl                ← the directory says "models", and so does the file
out/erl/models/models@user__t__pessoa.erl
out/erl/models/models@user__b__greeter.erl
out/erl/services/services@user.erl
```

**The difference that decides it is not aesthetics, it is how the program is run.** The BEAM loads
code from the directories on its path:

```
(a)  erl -pa out/erl -s main _botopink_main
(b)  erl -pa out/erl -pa out/erl/models -pa out/erl/services … -s main _botopink_main
```

Under (b) the CLI has to walk the tree and pass one `-pa` per directory, and it has to do it again for
every dependency — while the atom already carries the path that the directories repeat.

**Recommendation: (a), flat, one directory per target** (`out/erl/`, `out/js/`, `out/wasm/`). It is
also what `botopink run --target erlang` needs in order to work at all: it runs `escript out/main.erl`
today, which compiles only the file it is handed, and the fix is `erl -noshell -pa <one directory>`.

**Blocks:** `13-module-identity` step 0, and `10-cli-residuals`' three `modules/*` cells.

**Scope, corrected 2026-09-18 after [`13-module-identity`](./13-module-identity/README.md) implemented
it.** The recommendation's parenthesis — `out/erl/`, `out/js/`, `out/wasm/` — reads as a move for all
four targets, and front 13's step 2 kept commonJS and wasm at `out/<module path>`, with an acceptance
that demands the **commonJS tree stay byte-identical**. Front 13 is the side to read, because this
decision's own argument only reaches the BEAM: the whole "difference that decides it" is `erl -pa` — the
BEAM loads code from the directories on its path, and a nested tree costs one `-pa` per directory and
per dependency. Nothing equivalent is true of `require` or of a `.wasm` file. So what landed, and what
this decision should be read as, is **`out/erl/` for erlang and `out/beam/` for beam, flat, with
commonJS and wasm unchanged**. Moving those two as well is a separate row with a snapshot price
(315 commonJS cells) and no `-pa` argument behind it; it has not been asked for.

---

---

## 10. `@code` is taken twice

**Decided 2026-09-18 by the maintainer: (a).** The proposed annotation is renamed; `@code(text)`
keeps the name it already has.

**Measured.** `@code(text)` is an existing builtin (a template body reads its own source through it);
the checker's types-as-values step proposes an **annotation** `#[@code]` for a different purpose. Two
things would answer to one name, in two syntactic positions.

**Options.** (a) Rename the proposed annotation. (b) Keep both and disambiguate by position.

**Recommendation: (a).** (b) asks every reader — and the language server's hover — to know which
`@code` they are looking at; the annotation has no users yet, so the rename is free today and never
again.

**Blocks:** `01-checker`'s types-as-values step.

---

---

## 11. `<Pattern> as <name>`

**Decided 2026-09-18 by the maintainer: (b).** The three tests and the row go; the form is not part
of the language.

**Measured.** Three tests name the form (`Ok(v) as whole`); it has never parsed. Front 06's grammar
half landed decision 8's `case` arms without it, and decision 8 does not ask for it.

**Options.** (a) Implement it. (b) Delete the three tests and the row.

**Recommendation: (b).** Nothing in decision 8, `libs/std` or the five libraries writes it; a form
kept alive only by its own tests is a promise the language is not making.

**Blocks:** `01-checker`'s parser-gap step.

---

---

## 12. Unnamed variant payloads

**Decided 2026-09-18 by the maintainer: (b).** An unnamed variant payload is rejected, with a
located diagnostic naming the field form.

**Measured.** The grammar allows a variant payload with no field name in some positions; decision 8
§5 names fields in every pattern it writes, and the parser front recommended dropping the form.

**Options.** (a) Keep them. (b) Drop them, with a located diagnostic naming the field form.

**Recommendation: (b)**, for the same reason as 11 — and a payload nobody can name is a payload no
`case` arm can bind.

**Blocks:** `01-checker`'s parser-gap step.

---

---

## 13. The external-annotation rows that never had a step

**Decided 2026-09-18 by the maintainer: (a).** C1 and C8 become steps of `01-checker`.

**Measured.** [`external-annotations.md`](../1.0.4-beta/06-checker/external-annotations.md)'s C1 and
C8 (STD-001) name front 06 as their owner, but 06's steps never listed them — they were carried
through the whole milestone without ever being scheduled.

**Options.** (a) Put them in `01-checker` explicitly, with steps. (b) Move them to the milestone
after this one.

**Recommendation: (a).** A row that names an owner and appears in no step is how work becomes
invisible; scheduling it is what makes (b) an honest choice later.

**Blocks:** STD-001.

---

---

## 14. Seven forms that do not parse

**Decided 2026-09-18 by the maintainer: the recommendation, plus a front for the rest.** Four forms
are made to parse and three are recorded as deliberately absent — and the remaining surface questions
go to a new front, [`15-language-surface`](./15-language-surface/README.md), which reviews them in
detail rather than deciding them one at a time under pressure.

**Measured.** Front 17 found seven spellings that do not parse while writing cells: `adder(3)(4)`
(calling a returned function), `??`, `var` at module level, `#(a: i32)[]` (an array of labeled
tuples), and three more listed in its report. Each is a language question, not a defect: the
compiler is consistent, the question is whether the language wants the form.

**Options.** Per form: make it parse, or record it as deliberately absent.

**Recommendation:** make **four** parse — `adder(3)(4)` (a function is a value; not calling its
result is arbitrary), `#(a: i32)[]` (decision 8 §6 writes labeled tuples, and an array of them is the
obvious next line), and the two that decision 8 already implies. Record `??`, `var` at module level
and the remaining form as **deliberately absent**: `??` was thought to duplicate `catch` and `?.`,
and module-level `var` to contradict decision 2 — **both readings were wrong, and decision 28 corrects
them**: `catch` is `@Result`-only, and decision 2 is about the value of a block, not about module
state.

**Blocks:** `01-checker` and whatever picks up the grammar's tail.

**Amended 2026-09-18 by [decision 28](#28-what-decision-14-left-unassigned).** The "three recorded as
deliberately absent" did not survive its own measurement, and the correction is 28's whole first half:
two of the seven reported forms were **one production**, so the third absent slot was empty; and the two
readings that made `??` and module-level `var` absent were both false — `catch` is `@Result`-only, and
decision 2 is about the value of a block, not about module state. Read this decision's answer as *every
form is supported*, with 28's table as the list and its count of five as the count. The one half of that
list still unlanded is module-level `var`'s grammar, whose semantics are
[`17-beam-memory`](./17-beam-memory/README.md)'s.


---

---

## 15. A lower-case `#[@external(node, …)]`

**Decided 2026-09-18 by the maintainer: (a).** The lower-case spelling is a located error naming the
capitalised form; `01-checker` owns it.

**Measured.** Only `External.<Target>` matches `FnDecl.isExternal`, so the lower-case spelling passes
`check`, binds no host, and says nothing. Front 17 wrote a `reject/` cell for it and listed it against
a row that does not exist.

**Options.** (a) A located error naming the capitalised form. (b) Accept both spellings.

**Recommendation: (a).** (b) means two spellings for a form that names a host symbol, and the failure
mode of getting it wrong is silence at run time. The decision needs an owner as much as an answer:
the annotation grammar is `01-checker`'s.

**Blocks:** a `reject/` cell that currently names nothing.

---

---

## 16. The `not reached by any mod path` warning

**Decided 2026-09-18 by the maintainer: neither (a) nor (b) — fix the cause.** The warning is not to
be documented or exempted: the module it names is made reachable, so the condition that produces the
warning stops existing. A warning the standard library prints on every run is a warning nobody reads.

**Measured.** `libs/std` prints it on every gate run, for a module that the manifest's `files` list
declares but no `mod` path reaches.

**Options.** (a) Document it. (b) Exempt a module that `files` declares. (c) Add it to `root.bp`.

**Recommendation: (b).** The manifest is the consumer surface; a module listed there is reachable by
definition, and (c) would put a module in the build tree to silence a warning about the build tree.

**Blocks:** a warning the standard library prints at every gate run, which is how a real one gets
missed.

---

---

## 17. rakun's erlang story

**Decided 2026-09-18 by the maintainer: rakun supports every target, and `libs/std` grows what it
needs to.** Not (a), (b) or (c) as posed: the framework is not to be node-only, and the gap is not
rakun's to close alone — a library that binds a host needs a portable surface underneath it. So the
work splits: `libs/std` gains the target-portable primitives rakun's container, router and server rest
on, and rakun binds them per target. That is larger than a residual and is scoped as such.

**Measured.** rakun has **17 `@External.Node` declarations and no `@External.Erlang`**; its DI
container, router and HTTP server are 231 lines of `runtime.mjs`. Its erlang cell is the one skip in
`test-libs` (11 passed, 0 failed, 1 skipped).

**Options.** (a) Port `runtime.mjs` to erlang. (b) Declare rakun node-only and delete the `allow_fail`
lines. (c) Port the container and the router, leave the HTTP server node-only.

**Recommendation: (c).** The container and the router are the framework; the HTTP server is a host
binding, and erlang's is a different animal from node's. (b) is honest but closes a door the language
opened on purpose; (a) is a project, not a residual.

**Blocks:** the last non-green library cell — today a skip whose reason lives in a manifest key.

---

---

## 18. emilia's `tokens.bp` and `format --check`

**Decided 2026-09-18 by the maintainer: (a) now, plus a front to audit the formatter.** The
exemption is temporary and names the defect in the file; the standing intent is that **everything
stays formatted**, so [`16-formatter`](./16-formatter/README.md) reviews whether the formatter is
sound — the four red libraries are its evidence, not its scope.

**Measured.** `format --check` is red on four of five libraries (emilia 3 files, erika 2, jhonstart 3,
rakun 2; onze clean), and the formatter is idempotent — so the reds are disagreements about the
canonical form, not instability. emilia's `tokens.bp` is the sharp case: formatting it **hoists six
public variants above the sections**, because the parser records no member positions.

**Options.** (a) Exempt `tokens.bp` from `format --check` until the parser records positions.
(b) Fix the parser first, then format everything.

**Recommendation: (a), with the exemption naming the defect in the file itself.** (b) blocks four
libraries' formatting on a parser change that belongs to another front; (a) keeps the repository from
holding a file the formatter would corrupt, as long as the exemption says so where a reader will meet
it.

**Blocks:** `09-ecosystem-residuals`'s `format` step.

---

---

## 19. The comptime renderer's `id` field

**Decided 2026-09-18 by the maintainer: (b).** The field is removed.

**Measured.** 71 snapshots carry `"id": 0` across 65 files, and **no snapshot carries a non-zero id**.
The field is rendered and never varies.

**Options.** (a) Make it a real id. (b) Remove it.

**Recommendation: (b), and decide it before `01-checker` renames `buildRecordDeclName`.** A field that
is always zero is a field that every unrelated edit re-records; removing it after the rename means the
ids start matching by accident and the question never gets asked again.

**Blocks:** `06-comptime-dedup`'s third step.

---

---

## 20. Is a pattern range inclusive?

**Decided 2026-09-18 by the maintainer: one spelling, `..`, as in Zig.** Not (a) or (b) as posed —
the answer removes a spelling instead of choosing between two meanings: `...` leaves the grammar, and
`..` is the only range, in patterns and in iteration alike. **This reverses part of what front 06's
grammar half just landed** (`dff3446` implemented `1...9` with a `pattern-range-exclusive` diagnostic
pointing at `1..9`); that diagnostic inverts, and the `...` token goes.

**Measured.** `1...9` parses and checks; `loop (0..4)` is exclusive. Decision 8 fixes the spelling
(`A...B`, `..` stays iteration) but the cells front 17 wrote work around the boundary rather than
assert it, because nothing states whether `9` is matched.

**Options.** (a) Inclusive — `1...9` matches 9, which is what the Zig spelling it borrows means.
(b) Exclusive, to agree with `..`.

**Recommendation: (a).** Two spellings exist precisely so that one can be inclusive and the other not;
making both exclusive leaves the language with a second syntax for the same meaning. Write it into
decision 8 §5 and let front 12 turn the work-arounds into assertions.

**Blocks:** `12-language-tests`'s range cells.

**Amended 2026-09-18 by [decision 53](#53-the-range-spelling-is-zigs-split--inclusive-in-a-pattern--exclusive-in-a-slice).** The reason
this answer gave is the part that failed: Zig has **both** spellings, in different positions — `1...9`
inclusive in a `switch` prong, `0..3` and `xs[0..2]` exclusive in a range and a slice — and `1..9`
inside a `switch` does not exist there at all. So "one spelling, `..`, as in Zig" was the divergent
reading and the compiler was the Zig-consistent side. **`...` does not leave the grammar**: it stays,
inclusive, as the **pattern** spelling, and `..` stays exclusive in a slice and in iteration. Nothing in
the compiler moves — `1...9` is what it already parses, and `dff3446` stands. Front 12's range cells are
written against 53's split, not against this text.


---

---

## 21. T1 or T2 for the erlang record

**Decided 2026-09-18 by the maintainer: T2, the tagged tuple** — against the recommendation, which
was T1. The measurement stands as recorded: T2 costs 6 words per record against T1's 2, and the 2.5×
speed claim did not reproduce. The maintainer's call is the shape, not the benchmark.

**Measured.** A record is a map today. Giving it an identity means either **T1**, a tagged map
(`#{'__type' => '…', name => …}`), or **T2**, a tagged tuple. T1 costs **+2 words per record and
+0.165 ns per construction**, and erlang's map pattern matching is a *subset* match, so field access,
destructuring and `case` do not change at all. T2's claimed 2.5× advantage **does not reproduce**:
`erlc +to_asm` deletes the whole test when the shape is statically known, and through an opaque call
the two are within 0.5 ns. What remains for T2 is 6 words per record, not speed.

**Recommendation: T1.** The whole argument for T2 was a speed claim that measurement withdrew, and T1
changes no existing pattern in `libs/std` or the five libraries.

**Blocks:** `13-module-identity`'s third half.

**The chosen option's cost, measured 2026-09-18 by
[`13-module-identity`](./13-module-identity/README.md) while sizing halves 2–3 — and it is larger than
the record said.** T1 was "one key in a map": construction gains a field, and access, destructuring and
patterns are unchanged, because erlang's map matching is a subset match — 144 cells, one or two emitted
lines each. **T2 rewrites construct *and* access *and* destructure *and* patterns**: 66 erlang cells
(`maps:get` 40 · `#{… :=}` 5 · `#{… =>}` 53) and 73 beam cells (`get_map_elements` 42 ·
`put_map_assoc` 55 · `is_map` 45). So half 3 becomes a **shape** change of the same size as half 2, and
the milestone's largest snapshot movement is now **354 cell-writes over 210 distinct files** — 144 of
them written twice, because half 3's set sits inside half 2's. **The answer does not move**: this
decision already ruled that the maintainer's call is the shape and not the benchmark, and a price is not
a new argument. It is recorded here so that the price is visible where the shape was chosen, and so that
reopening it, if the maintainer wants to, starts from a number.

---

---

## 22. wasm has no identity at all

**Decided 2026-09-18 by the maintainer: (a).** `13-module-identity` designs the boxed value for
every backend, wasm included.

**Measured.** On wasm a record is a bump-allocated pointer, an enum a cell holding an ordinal, and a
unit variant **is the integer 0** — `Color.Red` is literally `i32.const 0`. Nothing there can answer
what type it is, and a record prints as a raw heap address.

**Options.** (a) `13-module-identity` designs the boxed value for all backends, wasm included.
(b) `05-wasm` designs its own while implementing decision 8.

**Recommendation: (a).** Under (b) `is Person` means one thing on three backends and another on wasm,
and the difference surfaces first in a user's program, not in a test.

**Blocks:** `05-wasm`'s decision-8 half.

---

---

## 23. Does a `behavior` need an atom?

**Decided 2026-09-18 by the maintainer: (a).** The `__b__` qualifier is reserved and emits nothing.

**Measured.** A2 reserves the `__b__` qualifier for a `behavior`, and nothing in the front uses it: a
behavior emits no module today, and policy 3's module-per-declaration covers `type` and `implement`.

**Options.** (a) Reserve the spelling, emit nothing. (b) Emit a module per behavior too.

**Recommendation: (a).** Reserving costs one line in the decoder and keeps the door open; emitting
costs a module per behavior for a construct with no run-time representation.

**Blocks:** nothing today — decide it before the decoder is written, or it becomes a rename.

---

---

## 24. Does step 3 of `14-comptime-on-beam` happen at all?

**Decided 2026-09-18 by the maintainer: every step, step 3 included.** The principle governs, not
the build time: no Erlang source in the compile path. The cost recorded below is therefore the price
of the principle, not an argument against it — and step 3 needs `beam_asm.zig`, so it sequences after
`03-beam` and `13-module-identity` rather than opening with steps 0–2.

**Measured.** Steps 0–2 take `erika-linq`'s erl side from **960 ms to ≈ 49 ms** — 911 ms off a
1 592 ms build, and they touch no backend. Step 3 (`.S` + `erlc +from_asm`) takes those 49 ms to
**≈ 11 ms**: another 38 ms, **≈ 5.6 % of what remains**, in exchange for ≈ 1 500–2 500 LOC, a *second*
lowering of every comptime construct, an `erl_ast → .S` renderer that does not exist (27 expression
variants, one renderer, and it emits Erlang source), and `beam_asm.zig`, which belongs to `03-beam`
and to 13 wholesale.

**The question is which goal governs.** If it is build time, step 3 is optional and the front should
stop at step 2. If it is the principle — *no Erlang source anywhere in the compile path* — then step 3
is the front, and its cost is the price of the principle.

**Recommendation: stop at step 2**, and reopen step 3 as its own front if the principle is the goal.

**Blocks:** `14-comptime-on-beam`'s scope, before its step 3 opens.

**Sequenced 2026-09-18 by [decision 62](#62-the-order-of-what-is-left-in-the-milestone).** Step 3 still
happens — the principle is not reopened — and 62 answers *when*: **deferred until after
`13-module-identity`**, with the blocker this decision could only assert now measured. The *typed* beam
backend already fails the case the untyped comptime mode exists for, and 13 is what fixes identity on
beam. So the recommendation recorded below — *stop at step 2* — is not the milestone's order and never
became it: the deferral is a place in the queue, not a withdrawal, and it is where this decision's own
sentence ("it sequences after `03-beam` and `13-module-identity`") already pointed.

---

---

## 25. Does `is` carry a pattern?

**Decided 2026-09-18 by the maintainer: (b).** `is` answers a `bool`; `case` is the only construct
that binds. The form leaves decision 8 §4.2.

**Measured.** The parser refuses `x is Some(v)` with a located `is-variant-binding` diagnostic, while
decision 8 §4.2 lists the form. So the language currently says two things.

**Options.** (a) `is` carries a pattern and binds its payload. (b) The refusal stands and `case` is
the only construct that binds.

**Recommendation: (b).** `case` already binds payloads, with exhaustiveness behind it; `is` answering
a `bool` *and* binding a name makes a narrowing rule that has to explain what `v` is when the test is
false. Strike the form from §4.2 rather than implement two ways to destructure.

**Blocks:** `01-checker`'s step 3, and the `is` cells of `12-language-tests`.

---

---

## 27. Who declares `behavior Display`?

**Decided 2026-09-18 by the maintainer: (a).** `01-checker` declares `behavior Display` in
`libs/std` as part of its decision-8 source step.

**Measured.** Decision 8 §7 says `libs/std` implements `Display` for `Dict`. `grep -rn 'behavior
Display' libs/std` returns **0**, and `Dict` implements nothing of the sort. The §7 acceptance of
**all four** backend fronts reads this.

**Options.** (a) `01-checker` declares it in `libs/std` as part of its step 11 (decision 8 in the
sources). (b) Each backend front assumes its own shape.

**Recommendation: (a).** (b) is how the same behavior ends up with four definitions; and step 11 is
already the step that puts decision 8 into `libs/std`.

**Blocks:** the §7 step of `02-erlang`, `03-beam`, `04-js` and `05-wasm` — four fronts reading one
missing declaration.

---

## 26. `case` arms of different types — and what an inferred union costs

**Decided 2026-09-18 by the maintainer: (a) — the arms union.** Inference may produce a union type;
a `case` whose arms disagree is not an error, it is a value of the union of their types.

**What (a) commits the milestone to**, recorded here because these are its costs and they are now
work, not arguments:

1. **A union can appear in a type nobody wrote.** `val label = case n { 0 { "zero" } _ { n } };`
   gives `label: string | i32` with no annotation in sight, so union types are no longer only an
   annotation feature — they are part of ordinary inference (`01-checker` steps 2 and 4 become **one**
   step: union inference and arm typing are the same problem under (a)).
2. **Every backend carries a value whose type is a union**, which is the same requirement
   [decision 22](./decisions-taken.md) places on the wasm boxed value, arriving by a second road —
   `13-module-identity` designs one box that answers for both.
3. **`@print` decides at run time what a union value is** (decision 8 §7): the per-type formatter must
   dispatch on the value's own identity, not on a written type. On erlang and beam that is the tagged
   tuple of decision 21; on JS the prototype of decision 5; on wasm the box of decision 22.
4. **A diagnostic prints unions**: `expected string, got string | i32` has to read well, and the
   union's member order has to be stable or the message is non-deterministic.
5. The two fixture slugs named for this answer
   (`case_arms_with_different_types_string_i32_union`) keep their names and become real.

Zero migration today: all 32 `case`-as-value blocks across the six libraries are homogeneous.

**Reformulated 2026-09-18**, with the examples the question was missing. The question is not really
about `case`: it is about whether a **union type can be produced by inference**, or only by being
written down.

**The program in question.**

```botopink
fn describe(n: i32) -> string {
    val label = case n {
        0 { "zero" }        // this arm is a string
        _ { n }             // this arm is an i32
    };
    return label;           // …so what is `label`?
}
```

**(a) the arms union** — `label` is `string | i32`, and nothing more happens here. The cost lands on
the next line: to *use* `label` you must narrow it, and the union travels through inference into
places nobody wrote one:

```botopink
val label = case n { 0 { "zero" } _ { n } };   // label: string | i32
@print(label);                                  // which formatter? the printer must handle both
val up = label.toUpper();                       // error — `i32` has no `toUpper`
if (label is string) { @print(label.toUpper()); }   // this is what the programmer must write
```

**(b) the arms must agree** — the `case` above is an error, and the programmer converts:

```botopink
val label = case n { 0 { "zero" } _ { n.toString() } };   // label: string
```

**(c) — the counter-proposal, which the file did not have: the arms must agree *unless the union is
written*.**

```botopink
val a = case n { 0 { "zero" } _ { n } };                  // error: arms disagree —
                                                          // annotate `string | i32` if that is meant
val b: string | i32 = case n { 0 { "zero" } _ { n } };    // fine: the union is written
```

**Why (c).** Under (a) a union can appear in a type nobody wrote, and then every backend must carry a
value whose type is a union, every error message must print one, and `@print` must decide what to do
with it at run time — that is the same problem [decision 22](./decisions-taken.md) is solving for
wasm, arriving by a second road. Under (c) unions stay a thing the programmer asks for, which is
where decision 8 §3 actually uses them (annotations, parameters, returns), and the diagnostic teaches
the annotation instead of silently widening.

**Measured, so the cost of each is known:** all **32** `case`-as-value blocks across the six
libraries are homogeneous — every arm already agrees. So (a), (b) and (c) cost **zero migration**
today; the difference is entirely about what the language promises next. Two fixture slugs are named
for answer (a) (`case_arms_with_different_types_string_i32_union`) and would be renamed under (b) or
(c).

**Recommendation: (c).** It is (b)'s cost with (a)'s expressiveness, and it is the only one of the
three where an inferred type never contains a union the programmer did not write.

**Blocks:** `01-checker`'s steps 2 and 4 — union inference and `case` arm typing are the same step
under (a), and two different steps under (c).

---


---

## 16 — how it was implemented, and why it looks like the option that was refused

**`botopink-lang` `315a38f`, landed 2026-09-18.** The decision was *fix the cause, do not exempt and do
not document*. The front did fix the cause — and the fix reads like option (b), the exemption. That is
worth writing down rather than hiding, because the convergence is the finding:

`collectOrphans` knew the `mod` chain and nothing else, so **anything a package ships by another route
was an orphan by construction**. The manifest's `files` list is that other route: it is what
`libs.loadDependencies` loads when the package is a dependency, so a module named there *is* reached —
by whoever loads it. A module now has two ways into a build, and the warning means "neither".

So the predicate changed, not a list of exceptions — but since `files` is where the second route is
written, the code looks like an exemption for `files`. The front checked the alternatives before
concluding that, and each is recorded: `build.zig`'s `std_core_files` is build-time and unreadable by
the distributed binary; `prelude.zig` exposes the ambient files' **contents**, not their names, and
naming them there would make the compiler know the standard library's internal file names, which
`prelude.zig:31-33` and `build.zig:44-52` say is avoided on purpose.

Two measurements that bound the change: only `primitives.bp` can trigger the warning at all (the two
`.d.bp` files are skipped by `isSource`), and **`libs/std` is the only package in the checkout that
warns** — the five libraries already reach every file of their `files` through their own `mod`
chains. So nothing real is hidden by it today.

`zig build test-libs` now prints **zero** `not reached by any mod path` lines, where it printed two per
run, and stays 11 passed / 0 failed / 1 skipped.

---

## 37. Is a record immutable?

**Decided 2026-09-18 by the maintainer: (a) — a record is immutable.** `p.age = 31` must not happen.
The checker rejects a field assignment with a located diagnostic naming the update form
(`Person(..p, age: 31)`), which already works; the erlang emitter's comment path becomes dead code and
stops producing a module that will not compile; and `val` starts meaning what it reads as.

**Measured 2026-09-18**, after the maintainer asked whether the value could be immutable. It is not,
and the three backends disagree in the worst available way. This program checks — on a `val`:

```botopink
type Person(name: string, age: i32)
fn birthday(p: Person) { p.age = 99; }
fn main() {
    val p = Person(name: "a", age: 30);
    val alias = p;
    p.age = 31;
    @print(p.age); @print(alias.age); birthday(p); @print(p.age);
}
```

| backend | what happens |
|---|---|
| commonJS | `31` · `31` · `99` — it mutates, **the alias sees it**, and mutation through a parameter propagates: a record is a mutable reference |
| wasm | `31` · `31` · `99` — identical |
| erlang | **the module does not compile**: the emitter writes `%% field assignment is not directly supported in Erlang.` where the statement goes, leaving `birthday(P) ->` with an empty body → `syntax error before: '->'` |

So the checker accepts, two backends make identity observable, and the third emits a comment where a
statement belongs. The erlang emitter already knows the operation is impossible — it just says so in a
place that cannot say anything.

**Migration cost: zero.** `grep` over `libs/std`, `examples/**` and all five libraries finds **0**
field assignments. Nothing written in this language mutates a field.

**Options.** (a) A record is immutable: the checker rejects `p.f = v` with a located diagnostic naming
the update form (`Person(..p, age: 31)`, which already works). (b) A record is mutable, and erlang
learns to emit the copy-and-rebind that would make it work. (c) It stays as it is.

**Recommendation: (a).** Three things fall out of it rather than having to be decided:

1. **[Decision 35](#35-structural-equality-is-not-legislated) dissolves.** With no mutation, identity
   is unobservable, so structural `==` is not a choice between semantics — it is the only one that can
   be told apart from the other.
2. The erlang comment path becomes **dead code**, and with it a module that does not compile.
3. `val` starts meaning what it reads as. Today `val p` protects the binding and not the value.

**On `Object.freeze`, which the maintainer raised** — measured, and it does not do the job alone:

- Emitted modules carry **no `"use strict"`**, and in sloppy mode an assignment to a frozen property
  **fails silently**: `Object.freeze({a:1}).a = 2` leaves `a` at 1 and throws nothing. Enforcement
  without strict mode is theatre. Under `"use strict"` it throws `TypeError`.
- It costs: 2 000 000 constructions took **2 ms** plain and **45 ms** frozen (node v25), ~21 ns per
  value.

So freeze is a **run-time** guard for something the checker can refuse at compile time, for free, on
all four backends at once. Its remaining use is real but narrow: stopping *host* JavaScript from
mutating a botopink value across the interop boundary. Worth keeping as an opt-in, not as the
mechanism.

**Blocks:** decision 35; `02-erlang` (a module that does not compile); `01-checker` (the diagnostic).

---

---

## 35. Structural equality is not legislated

**Answered 2026-09-18 by [decision 37](#37-is-a-record-immutable), not chosen on its own.** With a
record immutable, identity is **unobservable** — no program can tell two structurally equal values
apart except by `==` itself — so structural equality is not one semantics among three, it is the only
one that can be distinguished from the others. `==` on two values of the same named type compares
field by field, and the same rule covers arrays, tuples and variants.

The work it leaves is per backend, and the measurement of it stands: erlang already answers
structurally and keeps doing so under [decision 21](#21-t1-or-t2-for-the-erlang-record); commonJS and
wasm answer `false` today for record, array, tuple and variant alike, so both need a structural
compare — on JS a `__bp_eq` prelude helper (the mechanism already exists for `__bp_show`), and on wasm
after the box of [decision 22](#22-wasm-has-no-identity-at-all). The remaining question is only where
to call it: the commonJS emitter walks the **untyped** AST, so it cannot tell a primitive `==` from a
composite one without the checker marking the site, the way `method_lowerings` already does by `Loc`.

**Measured** (front 12, writing the type-identity cells): `Person(name: "Ana") == Person(name: "Ana")`
answers **`false` on commonJS** and **`true` on erlang**. No decision covers it and no front owns it,
so the cell that found it declares the omission in a comment rather than listing itself against a row
that does not exist.

**Options.** (a) `==` on two values of the same named type compares **structurally** — field by field.
(b) It compares identity, and structural comparison is a method. (c) It stays backend-defined, which
is what it is today.

**Recommendation: (a), and written into decision 8.** The language has no reference semantics anywhere
else the programmer can observe — records are values in the surface — and (c) is the one answer that
cannot be taught: the same program answers two things on two backends. Note that (a) arrives anyway
through [decision 21](./decisions-taken.md): once a record is a tagged tuple carrying its type, erlang's
`==` already answers structurally, so the JS side is where the work is.

**Blocks:** `12-language-tests`' equality cells; it is also the second half of `test/type_identity.bp`,
which today fails only because the erlang record is a bare map.

---

---

## 29. Does a block-shaped statement end itself?

**Decided 2026-09-18 by the maintainer: (c) — a block-shaped statement ends itself.** Against the
recommendation, which was to keep the `;`. `if`, `loop` and `case` in statement position take **no**
`;` after the closing brace; the rule is uniform across the three, as the question required.

**What it costs, measured before the answer:** ~**274** `};` sites across the ecosystem
(tests/language 88, erika 86, jhonstart 43, emilia 30, `libs/std` 23, examples 3, onze 1) — not all of
them are a block in statement position, but that is the order of the migration. Two fronts move
together: `15-language-surface` makes the parser reject the trailing `;`, and `16-formatter` stops
printing it, or every formatted file re-grows what the parser now refuses.

**Measured.** `if`, `loop` and `case` parse **with** a `;` after the closing brace. Whether that `;`
should be required, optional or rejected is a question nobody has been asked; the grammar simply grew
one answer.

**Options.** (a) Required, as today. (b) Optional. (c) Rejected — a block-shaped statement ends itself.

**No recommendation** — this is taste, and the point is to ask it **once** rather than let each front
meet it separately. What is not taste: whichever answer, it should be the same for the three.

**Blocks:** `15-language-surface` step 2.

**Re-measured 2026-09-18 by the compiler, while `15-language-surface` landed: 245 sites, not ~274** —
and the distribution the estimate gave is wrong in both directions: `libs/std` **51** (estimated 23),
`tests/language` **44** (estimated 88), erika 78, jhonstart 35, rakun **31** (unlisted before),
examples and CLI tests 5, onze 1, and **emilia 0** (estimated 30).

**The parser half is written and deliberately uncommitted.** A 76-line patch — `isBlockShapedStmt`
plus a `blockStatementSemicolon` parse error with its localised message — is parked at
[`15-language-surface/decision-29-parser-half.patch`](./15-language-surface/decision-29-parser-half.patch)
and applies to `src/parser.zig` at `109f6c9`. It is not committed to the compiler because
rejecting the trailing `;` rejects `libs/std`'s embedded prelude: **every** compile fails, and no
single front can land it with a green gate. The landing is one coordinated sequence:
`16-formatter` stops printing the `;` → 15 applies the patch → `12-language-tests` (44),
`libs/std` (51) and `09-ecosystem-residuals` (145 across the siblings) migrate in the same change.

**Amended 2026-09-18 by [decision 60](#60-the-parser-accepts-an-optional--before-the-formatter-picks-a-side), in both halves.**
The landing sequence written just above **cannot run**: a block-shaped statement without its `;` is a
parse error today, so a formatter that stopped printing it would emit text its own parser refuses, and
`assertIdempotent` re-parses pass 1 — every formatter test would fail and every formatted file would
stop compiling. The order is: the **parser** first, accepting the `;` as optional (`semicolonPolicy`) as
a landing of its own, which re-records nothing and breaks no file; then the printer chooses a side; then
12, `libs/std` and 09 migrate at leisure. And the rule is **narrowed to the braced form**: a braceless
statement — `if (c) return x;` — has no closing brace to end itself and keeps its `;`. The five
libraries alone hold 30+ braceless sites, so the two readings would have migrated different files. The
site count to read is the re-measured **245**, not the estimate's ~274.

---

---

## 30. Is there an index expression?

**Decided 2026-09-18 by the maintainer: (a) — the language gets an index expression.** `xs[0]` parses
in every position, and the decision 8 sections that presuppose one stop being aspirational. It is
parser work plus a lowering in each of the four backends, so it is the largest of the eight.

**Measured.** `xs[0]` is a **parse error in any position** — there is no index expression in the
language. Decision 8 presupposes one twice (`:112`, `:447`), and so does ordinary reading of every
array example.

**Options.** (a) Add it. (b) Keep arrays accessed only through methods (`at`, `first`, …) and correct
decision 8.

**Recommendation: (a).** An array with no index syntax is a surprise in every direction — the
documents assume it, the libraries work around it, and `at` returning an optional is a different
feature, not a replacement.

**Blocks:** the decision 8 sections that presuppose it; `15-language-surface` step 4.

**Landed in the parser 2026-09-18** — `feat` `109f6c9`, front `15-language-surface`. Also with **no new
AST variant**: an index is the builtin call `ast.index_builtin_name` (`"[]"`) over `(receiver, index)`,
contract at `ast.zig:1681-1703`. One node serves indexing and slicing, because the index is an ordinary
expression: `xs[0..2]` is the same call with a `range` argument, `d["k"]` with a string. What remains is
`01-checker` typing it by the receiver (and refusing it on `unknown`, `decision-8:112`) and **one
lowering in each of fronts 02–05**; until then it reaches the unrecognised-builtin path, where `x is T`
used to be. `xs[0] = 5` — an index in write position — is still an error and needs assignment-target
grammar, which decision 37 makes a question rather than a gap.

---

---

## 31. Does `any` exist?

**Decided 2026-09-18 by the maintainer: (a), for now.** `any` is deleted and `Iterator` gets a real
default type argument. The "for now" is recorded as written: if a later need for an escape hatch
appears, it comes back as its own decision rather than as a type that quietly disables the checker.

**Measured.** `any` parses **and checks**, and `libs/std/src/builtins.d.bp:88` uses it as a default
type argument — while decision 8 (`:129-133`) says in as many words that no type turns the checker
off.

**Options.** (a) Delete `any` and give `Iterator` a real default. (b) Keep it and correct decision 8.

**Recommendation: (a).** A type that means "stop checking" is the one thing decision 8 refuses by
name; the single use is a default that can be written properly.

**Blocks:** `libs/std`'s `Iterator` declaration; `01-checker`'s source step.

**Correction, 2026-09-18, measured by [`09-ecosystem-residuals`](./09-ecosystem-residuals/README.md)**
while landing `libs/std/src/beam.bp`. Two things here are wrong, and the second changes what "delete it"
has to mean. **The count is wrong by roughly sixty**: `builtins.d.bp:88` is not the single use — every
declaration in `libs/std/src/erlang.bp` writes `any`, and so do the ten new `#[@External.Erlang]`
primitives of `beam.bp`. And **this decision has not landed**: `any` still parses and checks at
`3cfb65cb`. What the same pass measured is that `any` is not the escape hatch the word suggests —
**it unifies only with itself**. `beam.pdPut("k", 1)` reds with *expected any, got string* and
`val a: any = 1` with *expected any, got i32*, while a value produced by another host call goes through.
So `any` is a closed type that no botopink value inhabits, and what it actually serves is the **host
vocabulary** of `erlang.bp` and `beam.bp`. Deleting it therefore owes those declarations a replacement
spelling, not only a diagnostic; `Iterator`'s default is the smaller half.

---

---

## 32. Are `Option.None` and `Some(1)` value names?

**Decided 2026-09-18 by the maintainer: remove them and rewrite as `?T`.** Every `Option.None` and
`Some(1)` in value position leaves the documents; the optional is `?T`, and `.Some` / `.None` stay
patterns, as decision 2 settled.

**Measured.** The documents write them in value position. Decision 2 already settled that `?T` is the
only optional and `.Some` / `.None` are patterns — so the documents contradict a decision already
taken.

**Recommendation.** The documents are wrong; correct them rather than re-open decision 2.

**Blocks:** the `docs.md` and decision-8 lines that write them.

---

---

## 33. A bodyless `fn` with no return type

**Decided 2026-09-18 by the maintainer: (b) — a bodyless `fn` declares its return type.** Against the
recommendation. `fn f(x: string)` with no body and no `-> …` stays a parse error, and the **three
`libs/std` declarations that write it are the ones that change**, gaining `-> void`. The rule reads:
a declaration without a body says what it answers, even when the answer is nothing.

**Measured.** `fn f(x: string)` — no body, no return type — does not parse, and `libs/std` **declares
three of them**.

**Options.** (a) Make it parse. (b) Require `-> void` or a body.

**Recommendation: (a).** The standard library already writes the form; either it parses or those three
declarations are wrong, and they read as deliberate.

**Blocks:** `15-language-surface` step 4.

**Landed 2026-09-18** — `feat` `109f6c9`. And the "three `libs/std` declarations" are, measured,
**one**: `libs/std/src/builtins.d.bp:197` `fn emit(source: string)` → `-> void`. The others counted are
different grammars — `:12`, `:16` and `:20` are `pub declare fn …;`, and `:398`/`:399`/`:463`/`:464`
plus `primitives.bp:349`/`:377` are `behavior` members. **A second question follows from that**: should
the three `declare fn` also name `-> void`, for the same reason? It is not what this decision answered.

---

---

## 34. The `format --check` exemption does not exist

**Decided 2026-09-18 by the maintainer: (c), for now — no exemption mechanism.** Against the
recommendation, and it **withdraws the exemption granted by [decision 18](#18-emilias-tokensbp-and-format---check)**:
emilia's `tokens.bp` is formatted like every other file and the hoist is accepted.

Two consequences to carry. The hoist is a **fidelity** loss, not a correctness one — front 16 measured
that the emitted output is byte-identical on all four backends after it (13 variants at 4 sites). And
`16-formatter` must land its `default`-deleting fix **before** `09-ecosystem-residuals` formats
anything, or three files lose `pub default mod` / `pub default fn` and the check reports them clean.

**Measured.** [Decision 18](./decisions-taken.md) exempted emilia's `tokens.bp` from `format --check`
— but there is **no exemption mechanism**: `format_cmd.zig` has no skip list of any kind. The decision
assumed a feature.

**Options.** (a) A key in `botopink.json` (a list of paths the check skips, with a reason string).
(b) A marker comment in the file itself. (c) No exemption — the file is formatted and the hoist
accepted.

**Recommendation: (a)**, built by `10-cli-residuals`, which owns `format_cmd.zig`. It keeps the reason
next to the project rather than hidden in a file, and `--check` can print it, so a reader meets the
defect instead of wondering why one file is exempt.

**Blocks:** `16-formatter`'s exemption; `09-ecosystem-residuals`' format step.

**Withdrawn 2026-09-18 by [decision 34](#34-the-format---check-exemption-does-not-exist).** There was no
exemption to grant: `format_cmd.zig` has no skip list of any kind, so this decision assumed a feature.
`tokens.bp` is formatted like every other file and the variant hoist is accepted — front 16 measured the
emitted output byte-identical on all four backends from both orderings, so it is a fidelity loss and not
a correctness one. The second half of this decision stands and has been done: `16-formatter` audited the
formatter, and [decision 61](#61-the-formatters-canonical-layout--four-rules) is the layout it stopped
on.

**Confirmed rather than reopened, 2026-09-19 by
[decision 66](#66-format---check-looks-at-the-whole-project--and-something-has-to-call-it).** Widening the
scan grants `tests/language/reject/**` an exemption, and it is deliberately **not** either mechanism this
decision refused: the runner knows what that directory is, nothing declares the exemption and nothing opts
into it. `format_cmd.zig` still gets no skip list — under
[decision 67](#67-the-most-restrictive-behaviour-and-no-configuration-that-bypasses-it) that absence is a
property to keep, not the gap this decision measured it as.

---

## 36. Does `..` exclude its end **in a pattern**?

**Decided 2026-09-18 by the maintainer: (a) — `..` is exclusive everywhere**, in a pattern exactly as
in a loop. It is one sentence in decision 8 §5, and front 12 turns its work-arounds into assertions.

**Measured.** [Decision 20](./decisions-taken.md) removed `...` and made `..` the only range, "in
patterns and in iteration alike". `loop (0..4)` is exclusive, so a pattern `1..9` is *implicitly*
exclusive — but nothing says so, and front 12's cells still work around the boundary instead of
asserting it.

**Options.** (a) Exclusive, matching `loop`. (b) Inclusive in a pattern, exclusive in a loop — the same
spelling meaning two things by position.

**Recommendation: (a).** (b) is what decision 20 refused when it removed the second spelling. What is
missing is not the answer but the sentence: decision 8 §5 has to say it, and front 12 turns the
work-arounds into assertions.

**Blocks:** `12-language-tests`' range cells.

**Not landed, and measured further on 2026-09-18.** Front 15 left the edit — ~10 lines in
`parser/patterns.zig`'s `finishRangePattern` (`:269-274`) plus dropping `dotDotDot` from the lexer —
because `patterns.zig` is `01-checker`'s step-4 grammar and the change re-records its `case` snapshots.
**`1...9`, the spelling today's diagnostic recommends, works on no backend**: `case 9 { 1...9 { 1 } _ { 0 } }`
answers `undefined` on commonJS and `0` on erlang, because a brace-arm of `case` is neither typed nor
lowered — the defect already filed with `01-checker`. So the run-time semantics this decision asks for
is the one that already exists; what is missing is the spelling and the sentence in decision 8 §5.

**Amended 2026-09-18 by [decision 53](#53-the-range-spelling-is-zigs-split--inclusive-in-a-pattern--exclusive-in-a-slice).** `..` is
exclusive in a slice and in iteration, and it is **not a pattern spelling at all**: in a pattern the
range is `...` and it *includes* its end — which is what the compiler already does, and what Zig does.
Option (b) is not what 53 chose either: it is not one spelling meaning two things by position, it is two
spellings in two positions, as in the language both decisions cited. So the ~10-line
`finishRangePattern` edit this decision was waiting for is **not to be made**, `dotDotDot` stays in the
lexer, and the sentence decision 8 §5 needs is 53's split. The surviving defect is the one the paragraph
above names and 53 re-measured: a brace-armed `case` range is not lowered on every backend.

---

---

## 28. What decision 14 left unassigned

**Decided 2026-09-18 by the maintainer: every form is supported.** Not "four parse, two absent" and not
"four and three" — **all of them parse**, and the count closes at five distinct forms because two of
the seven reported were one production and the seventh was never a missing form.

| Reported form | Answer |
|---|---|
| `adder(3)(4)` — calling a call's result | parses |
| `(expr).method` — one production, reported twice (`(sql "…").length`, `(a == b).toString()`, and plain `("ab").length` fail identically) | parses |
| `#(a: i32, b: string)[]` — and its family: `@Result<…>[]`, `(i32 \| string)[]` | parses |
| `??` | **parses** — reversing decision 14's "deliberately absent" |
| `var` at module level | **parses** — reversing decision 14's "deliberately absent" |
| a bare `if` not last in its block | never was a missing form; the `;` after it goes, by [decision 29](#29-does-a-block-shaped-statement-end-itself) |

**Two corrections to what this file argued, both measured after the answer, both mine:**

1. **`??` is not a duplicate of `catch` and `?.`.** `catch` is `@Result`-only — `val b = a catch 0;`
   on an `a: ?i32` reds with `` `try` requires a @Result<D, E> value, found 'optional' ``. There is
   **no** operator today that gives an optional a default; `?.` chains and `if (a) { v -> … }` is a
   statement. So `??` fills a real gap, and the recommendation to drop it rested on a false premise.
2. **Module-level `var` contradicts no decision.** This file, and front 15's documents, attributed
   "a module has no mutable state" to decision 2 — decision 2 is about **the value of a block and of a
   fn body's tail expression** and says nothing of the sort. The sentence comes from
   `rakun/AGENTS.md:22` and `rakun/src/runtime.bp:4`, where a library *observes* the property while
   working around it. It was an unstated property, not a taken decision, and the attribution was
   propagated without being checked.

**What module-level `var` costs, and what it may repay.** commonJS is a module-level `let` and wasm a
mutable global; **erlang and beam have no module-level mutable storage at all**, so it needs the
process dictionary (`put/get`) — which is exactly what emilia already does by hand through
`@External.Erlang`. Against that: rakun keeps its scan registry, DI cache and router in **231 lines of
`runtime.mjs`** *because* the language has no module state, and `rakun/AGENTS.md` says so in those
words. Module-level `var` therefore reaches into
[decision 17](#17-rakuns-erlang-story) — it may remove the reason that runtime exists, rather than
porting it.

**Blocks:** `15-language-surface` steps 1 and 4; and the `var` half should be scheduled **with**
decision 17's `libs/std` work, not before it.

**Measured.** Decision 14 said "four parse, three are deliberately absent" — but front 15 found the
seven are **six**: `(sql "").length` and `(a == b).toString()` are the *same* production (any
`(expr).method` fails, `("ab").length` included). And the seventh is not a missing form at all: `if`,
`loop` and `case` do parse, with a `;`. Front 17's text, and decision 14's third "absent" slot, rest
on a description that does not reproduce.

**Recommendation.** The parenthesised pair is one production and counts once; the third absent slot is
**empty**, and decision 14 is amended to "four parse, two absent" rather than inventing a third.

**Blocks:** `15-language-surface` step 1.

**Landed 2026-09-18** — `feat` `109f6c9`, front `15-language-surface`. All five forms parse, `??`
included. `a ?? b` carries **no new AST node**: it desugars into the optional-binding `if` the language
already had, bound to `ast.nullish_binding_name`, so no backend has anything to do for it — only
`16-formatter` has to print it back, which it does not yet.

**Correction, 2026-09-18, measured by [`12-language-tests`](./12-language-tests/README.md):** this
decision's landing note must not be read as saying module-level `var` parses. It does **not** —
`var counter = 0;` and `pub var counter = 0;` are both `this token cannot appear here` at `1:1` at
`109f6c9`. Front 15 measured the form and deliberately left it (*"the grammar is trivial; the
semantics are the `@BeamMemory` design"*), and its semantics are now
[`17-beam-memory`](./17-beam-memory/README.md), gated on
[decision 38](#38-a-val-is-immutable) — answered since — and on
[decision 49](#49-17-opens-after-01s-step-4-is-committed) for when that front opens.

---

## 38. A `val` is immutable

**Decided 2026-09-18 by the maintainer: (a).** Assigning to a `val` — local or module-level — is a
located error naming `var`; a `var` allows it.

**Measured, 2026-09-18, at `feat` `1379659`.** The rule is not new; it is a rule one backend already
enforces and the checker does not:

```botopink
fn main() { val x: i32 = 0; x = 1; @print(x); }
```
```
$ botopink check
   Checked in 62.09ms
$ botopink run
out/main.js:34    x = 1;
TypeError: Assignment to constant variable.
```

`commonJS` emits `const` for a `val`, so node throws; the other three targets disagree in silence. The
decision moves an existing rule from run time to compile time.

**The migration cost is zero, and it is measured** — the acceptance box of `17`'s step 1 said
"unmeasured today". Over `libs/std`, `examples/**` and the five libraries: **82** assignments to a bare
name, and **all 82** to a name the same file declares `var` (`var out = self;` in
`libs/std/src/dict.bp:57`, `var acc = initial;` in `:65`). **Zero** assignments to a `val`. The local
`var` already exists and is written 109 times. *The query is textual and per file: it does not see a
`val` shadowing a `var` of the same name in another scope, and field assignment (`self.x = …`) was
decision 37's query, not this one.*

**Blocks:** step 1 of [`17-beam-memory`](./17-beam-memory/README.md) — which needs `var` to mean
something — and the two diagnostics it carves out of [`01-checker`](./01-checker/README.md).

---

## 39. The module emits a registered owner for its ETS table

**Decided 2026-09-18 by the maintainer: (a).** A module with a `var` under `Ets` emits an owner
process, registered under a name qualified by the module, that re-creates the table when it dies (hot
reload, crash), plus the `whereis` guard every read and write goes through. Roughly fifteen lines per
module, `{heir, self(), undefined}` and the `{'ETS-TRANSFER', …}` receive included.

**Measured.** Without the owner, five processes × three increments read `3, 3, 3, 3, 3` (total 0);
with it, `3, 6, 9, 12, 15` (total 15). The guard costs +94% on a read and +69% on an increment
(`ets:lookup_element` 15.38 ns → 29.76 ns with `whereis`; `ets:update_counter` 21.05 → 35.63) over
2 000 000 operations — 15 ns nobody notices, and the design does not get to call it free.

**Blocks:** step 4 of [`17-beam-memory`](./17-beam-memory/README.md), now deferred by decision 50.

---

## 40. `+=` under `Ets` is refused on a type that is not an integer

**Decided 2026-09-18 by the maintainer: (a).** The recomposition diagnostic covers it.

**Measured.** `ets:update_counter` answers `{ok, N}` for `i32`/`i64` and `{error, badarg}` for `f64`
(with increment `1.0` **and** `1`), `bool` and binary — same table, same call. It is the only atomic
read-modify-write the BEAM offers, so "`+=` is atomic under `Ets`" is an integer-only promise: on an
`f64` the `+=` would become lookup + insert, the very pattern the rule beside it refuses.

**Why not (b) or (c).** (b) makes the rule unpredictable from what the author wrote. (c), a
`ets:select_replace` CAS loop, has no measured cost and serves a case nobody has asked for; it stays
available as a *later* lowering, because it is compatible with (a) — the refusal becomes an emission
and no program that compiled changes meaning.

**Blocks:** the §5 text of `docs.md` (front 08 writes it), and rule (b)'s diagnostic in
[`17-beam-memory`](./17-beam-memory/README.md).

---

## 41. A misspelled `@BeamMemory` is a compile error

**Decided 2026-09-18 by the maintainer: (a).** The member and the argument names are validated in the
commit the annotation is born in. The three members stand — **`ProcessDict`** (which is also what a
`var` with no annotation means), **`Ets`** and **`PersistentTerm`**: writing the default out loud is a
legitimate thing to do, and the front's own README had already answered it that way
([`17-beam-memory`](./17-beam-memory/README.md), *"Does `ProcessDict` exist as an explicit spelling,
being the default? **Yes.**"*).

```botopink
#[@BeamMemory.Etz] var x: i32 = 0;
// error: unknown member `Etz` in `@BeamMemory` — expected `ProcessDict`, `Ets` or `PersistentTerm`

#[@BeamMemory.Ets(keyd = true)] var x: i32 = 0;
// error: unknown argument `keyd` — expected `keyed`

#[@BeamMemory.Ets(keyed = true)] var n: i32 = 0;
// error: `keyed` needs a keyed container — an `i32` has no key

#[@BeamMemory.ProcessDict] var x: i32 = 0;
// accepted — the default, said out loud
```

**Measured.** `#[@TotallyMadeUp.Nonsense(whatever = 42)]` on a `fn` **passes `check`** with no
diagnostic, so without this the annotation would be accepted, ignored, and the state would sit
somewhere other than where the author wrote it — the failure family decision 15 already named.

**Blocks:** step 3 of [`17-beam-memory`](./17-beam-memory/README.md), which decision 50 keeps in this
milestone.

**Correction, 2026-09-18, measured by [`09-ecosystem-residuals`](./09-ecosystem-residuals/README.md):**
the four programs above cannot be measured in the position they are written in. `#[…]` above a
**module-level binding** does not parse at `3cfb65cb` (`unexpected `#``), so this decision's measurement
— `#[@TotallyMadeUp.Nonsense(whatever = 42)]` passing `check` — was taken on a `fn`, and the annotation
can only be measured there until [`17-beam-memory`](./17-beam-memory/README.md)'s step 1 lands the
`val`/`var` carrier. A confirmation rather than a surprise, and it does not move the answer: the
validation is still born in the annotation's own commit (step 3), and step 1 is what gives the
annotation a declaration to sit on.

---

## 42. A `Dict` under `Ets` with `keyed` unwritten keeps the default, with no warning

**Decided 2026-09-18 by the maintainer: (b).** The default stays `keyed = false` and the compiler says
nothing: replacing the whole container is a thing authors legitimately want. The behaviour **and the
performance difference** are stated in `docs.md`, which front 08 writes.

**`keyed` is a `Dict`-only argument** — see decision 51 below; a `List<T>` under `Ets` stores its whole
value like anything else.

**Measured.** `keyed = false` against `keyed = true`, per write: 10 keys 254 ns → 51 ns (4.9×), 1 000
keys 25 190 → 47 ns (537×), 10 000 keys 301 864 → 60 ns (**5 061×**). Two processes writing
**different** keys 20 000 times each under `keyed = false` lost **six** writes silently
(`a => 19994`, `b => 20000`). The sentences `docs.md` must carry are in step 6 of the front.

**Note after [decision 57](#57-srccomptime-gets-a-warning-channel).** The recommendation this answer
overrode was written *conditionally*: front 17's README proposed a located warning "**if** the warning
channel exists", and it did not (`grep -rn warning` over `comptime/*.zig` → 0). 57 has since granted the
channel, as a `warnings` list on the `Env` inside a row of `01-checker`. **The answer does not move** —
(b) stands, the compiler still says nothing, and `docs.md` carries the behaviour and the performance
difference. What the channel removes is the *reasoning*: the warning is refused because replacing a whole
container is a thing authors legitimately want, not because there was nowhere to print one.

**Blocks:** step 6 of [`17-beam-memory`](./17-beam-memory/README.md) and the `docs.md` text. The list
half waits on nothing: [decision 51](#51-keyed--true-is-a-dict-only-argument) answered it the same day — `keyed` is a `Dict`-only
argument, and a `List<T>` under `Ets` stores its whole value.

---

## 43. `@BeamMemory` lives in two layers — and off the BEAM the annotation is a no-op while the module is an error

**Decided 2026-09-18 by the maintainer: (b), with the tension resolved as (a).**

**Layer 1**, `libs/std/src/beam.bp` (no `.zig`, the shape `libs/std/src/erlang.bp` already has): ten
`#[@External.Erlang]` primitives — `pdGet`/`pdPut`/`pdErase`, `etsWhereis`/`etsNew`/`etsGet`/`etsPut`/
`etsBump`, `ptGet`/`ptPut` — and `pub mod beam;` in `root.bp`. **Layer 2**, the core: three mode names
and how a binding's read and write lower onto layer 1. No line of `.zig` names ETS, `persistent_term`
or the process dictionary. `libs/std/src/beam.bp` does **not** exist today (27 files in
`libs/std/src`, none of them `beam`), and this front specifies it while front 09 lands it.

**The tension the option came with, decided: (a).** The annotation is a silent no-op on commonJS and
wasm; a hand-written `import { beam } from "std"` is `std-unsupported-on-target` there, the diagnostic
`std/erlang` already gives. The two live at different levels of intent: the annotation says *where
state lives when more than one place is possible*, and on a target with a single execution context it
has nothing to say; the import says *give me the host primitives*, and there the error is the honest
answer. What (a) obliges is one sentence in `docs.md` saying exactly that. Rejected: making the
annotation an error off the BEAM (every program that names memory then needs a per-target
conditional), and resolving `std/beam` everywhere (ten emissions per backend, and it invents a process
dictionary for targets with no processes).

**Confirmation 2 of the same message:** `Cluster` stays **out of the core** — it goes to `libs/std` as
an explicit type with its consistency model declared.

**Blocks:** the size of [`17-beam-memory`](./17-beam-memory/README.md), and its step 3b, which front
09 lands.

**Landed 2026-09-18** — layer 1 is committed and gate-green. `libs/std/src/beam.bp` exists, with the ten
`#[@External.Erlang]` primitives and `pub mod beam;` in `root.bp`, landed by
[`09-ecosystem-residuals`](./09-ecosystem-residuals/README.md) **before front 17 opens**, which is what
[decision 62](#62-the-order-of-what-is-left-in-the-milestone) ordered. Two corrections the landing measured, neither of them to the answer:

- **The tension paragraph is right, and a call is not what triggers it.** `@External.Erlang` covers
  *both* BEAM targets (`codegen.zig:74-77` maps `.erlang` and `.beam` to one lookup name), and
  `std-unsupported-on-target` fires on the **import**: a bare `import { beam } from "std"` reds off the
  BEAM before any call site is reached. Read "the module is an error there" as the import being the
  error, not the tenth call.
- **Layer 2 has no route to layer 1 through the erlang backend, and this decision never named the
  dependency.** A qualified std host call lowers to a call on the std module — `beam:pdPut(Slot, Slot)`
  — while the emitted `out/std/beam.erl` is `-module(beam).` **and nothing else**: no export, no
  function. It is not this module's doing; `out/std/process.erl` is `-module(process).` plus a
  `no_auto_import` line and no function either, where commonJS emits real wrappers
  (`function cwd() { return process.cwd(); }`). The backend emits **no wrapper for a host-bound std
  `declare fn`** at all. So front 17's step 3b cannot meet its fourth acceptance bullet ("re-run under
  `erl`") today whatever layer 1 looks like, and layer 2 cannot lower a binding's read and write onto
  layer 1 *as botopink calls* until that backend row lands — and that row is in front 02's, or 13's,
  files. The one alternative, layer 2 emitting `erlang:put/2` from `.zig`, is precisely what this
  decision chose against. Opened as [question 64](./decisions-pending.md#64-how-does-beammemorys-layer-2-reach-layer-1-when-the-erlang-backend-emits-no-wrapper),
  because either this decision gains a dependency or its mechanism is reopened, and that is the
  maintainer's call.

**Correction, 2026-09-19, re-measured after front 13's half 1 renamed the std atoms.** The substance of the
second bullet is intact and unchanged — zero `-export`, zero function, `undef` at run time, and the erlang
backend still emits no wrapper for a host-bound std `declare fn` — but three of its spellings are stale and
one of its claims was never right as written:

- The path is **`out/erl/std@beam.erl`**, not `out/std/beam.erl`. The module line is
  **`-module(std@beam).`**, not `-module(beam).`. The emitted call is **`std@beam:pdPut(T, T)`**, not
  `beam:pdPut(Slot, Slot)`.
- **"`-module(beam).` and nothing else"** is wrong about the file even with the name corrected. It is
  **162 lines**: the `-module` attribute, then 161 lines carrying `beam.bp`'s own `////` header re-emitted
  as blank-separated `%%%` comments. Nothing else *executable*, which is the point the bullet makes; but a
  reader who goes looking for a two-line file will not find one, and the emitted header is the reason the
  gap is invisible in a listing.
- **`libs/std/src/beam.bp`'s own header carries all three stale spellings**, in the paragraph beginning
  *"One thing layer 2 cannot yet do through this module, measured"*. That file is
  [`09-ecosystem-residuals`](./09-ecosystem-residuals/README.md)'s; whoever next opens it should re-spell
  them there, because that header is where a reader of layer 1 meets this finding first.
- And front 17's step 3b fails its **third** acceptance bullet, not its fourth. The third is the one
  ending *"and re-run under `erl`"*; the fourth is *"**Not** a `.zig` line"*, which layer 1 **satisfies** —
  `libs/std/src/beam.bp` landed with no `.zig` at all, which is this decision's own mechanism holding.

---

## 44. `optional<i32>` is not a valid spelling

**Decided 2026-09-18 by the maintainer: (a).** `optional<T>` is refused, with the pointed diagnostic
`builtins.d.bp:56-58` already documents for the other two spellings (use `?T`).

**Measured** by [`11-tooling`](./11-tooling/README.md) at `19a3b01`: `val v: optional<i32> = null;`
**passes `check`** — `optional` is the checker's own internal name — while `val w: Option<i32> = null;`
is refused with a generic `type mismatch` that *leaks that internal name* (`infer.zig:4590`). Front 11
has just stopped the language server from echoing it back at users, including a code action that wrote
`: optional<i32>` **into the user's file**; leaving the checker accepting it re-opens the door from the
other side. Decision 2 already settled that `?T` is the only optional spelling.

**Blocks:** a row of [`01-checker`](./01-checker/README.md).

---

## 45. A member access on a `?T` is an error naming `?.`

**Decided 2026-09-18 by the maintainer: (a).**

**Measured** by [`04-js`](./04-js/README.md): `rs.at(0).b` is accepted today, because `rs.at(0)` is
`?#(a: i32, b: string)` — so the label-to-position rewrite (`infer.zig:6186`) never fires and the
backend emits `.b` verbatim. It is the third appearance of one shape of defect in this milestone
(decisions 37 and 38 are the others): the checker accepts something the backends then answer
differently. The `?.` spelling already exists, so the diagnostic writes itself, and
`val v = rs.at(0)?.b;` is the correction — where the label rewrite *does* fire.

**Blocks:** front 12's `§6 T4` cell, whose owner row moves from `04 step 2` to
[`01-checker`](./01-checker/README.md).

---

## 46. `d["k"]` on a `Dict` routes to `lookup`

**Decided 2026-09-18 by the maintainer: (a).** The checker records the receiver kind at the index call
site, as it already does for primitive method receivers, and each backend routes a dict index to
`lookup`.

**Measured.** Today the checker types the index call `void`, `instanceLowerings` has no entry, commonJS
emits a plain property read and the program answers **`undefined`** — silently, on a `Dict` that holds
the key. Decision 30's own text writes `d["k"]` as the dict read, so refusing the form would be
withdrawing what that decision granted.

**Sequencing, and it is why this was answered now rather than later:** the worktrees of `02-erlang`,
`03-beam` and `05-wasm` are open **now** and each has just landed decision 30's index lowering, so the
dict route is one more arm in code each front already wrote. Answered after they close, it is four
fronts reopened for one arm each.

**Blocks:** the `d["k"]` half of decision 30 in all four backends; front 12 left the cell out for
exactly this reason.

**What this decision is not, measured 2026-09-18 by
[`13-module-identity`](./13-module-identity/README.md):** it is not the same fix as "beam reaches parity
with erlang on `.length` over an index receiver", and the two are easy to blur because both are index
expressions whose member the checker never typed. erlang answers `xs[0].length` correctly through a
**type-free runtime helper** — `__bp_len(Recv, Member)` at `erlang.zig:4804-4811` — which fires precisely
*when inference recorded nothing*, not through a receiver kind. The receiver-kind route this decision
asks for runs through `instanceLowerings.put`, and that fires only at **method-call** sites in
`infer.zig`: there is no index or slice arm at all. So the beam `.length` defect — the third of the three
[decision 62](#62-the-order-of-what-is-left-in-the-milestone) claims for this wave — is beam growing
erlang's helper, and this decision is the checker growing an arm it does not have. Two rows, not one.

**Correction, 2026-09-19, measured twice on a rebuilt binary: the paragraph above measured one backend of
three, and "silently" is true of that one.** On a `Dict` that **holds** the key, `@print(d["k"])` answers:

```
commonJS: undefined
erlang:   Runtime terminating during boot ({{bp_unsupported_index,#{pairs=>[{<<"k">>,1}]},<<"k">>},
          [{main,'__bp_index',2,[{file,"out/erl/main.erl"},{line,16}]}, …]})
wasm:     wasm trap: wasm `unreachable` instruction executed
```

erlang **brings the node down** — `__bp_index/2` has no map clause and falls through to a
`bp_unsupported_index` throw — and wasm **traps** on an `unreachable`. Three answers, not one. It does not
move the answer, which was already (a); it moves the *urgency*, and in the direction this decision's own
text understates. A silent `undefined` on one backend is a wrong answer to fix when the checker reaches
it; a program that cannot run on two of four targets is the form being unusable, so the `lookup` route is
not a polish row beside decision 30's index — it is what makes `d["k"]` execute at all outside commonJS.
And it is one more instance of the pattern the `.length` paragraph above names: what inference never
recorded, each backend answers its own way.
[Decision 63](#63-an-index-answers-t-and-an-absent-key-fails-rather-than-answering) then says what the route
answers: the index consults `lookup` and **fails** on its empty answer, unless the declared value type is
optional, in which case it returns it. So the arm this decision asks for is a lookup *and* a check, on all
four backends.

---

## 47. Absent has one spelling: `null`

**Decided 2026-09-18 by the maintainer: (a).** An `array_at` prelude helper answers `null`, matching
the string helper.

**Measured** on commonJS: `xs.at(9)` and `xs[9]` answer `undefined`, while `"abc".charAt(9)` answers
`null` through `__bp_string_char_at` — two spellings of absence in one backend, and front 04 had to
loosen the optional guard to `!=` so `?.` and `??` would agree. (b) — writing down that `?T` means
"`null` or `undefined`" — works today only because of that loosening; it puts two values behind one
type, and every future `===` in a hand-written host template is a bug waiting.

**Priority.** The lowest of the three questions answered with it: it blocks nothing today, so it lands
with [`01-checker`](./01-checker/README.md)'s own pass.

**Measured after the answer, and "it blocks nothing" is true only of the helper.** The *spelling* has
rows: front 05 reports the other word still printed where commonJS prints `null`, and front 12's cell
`index_an_index_past_the_end_answers_zero` answers `undefined` on three backends and `0` on wasm — under
a slug that asserts a third word again. [Decision 52](#52-a-condition-loop-that-never-breaks-answers-null) then needs this same spelling for an
exhausted condition loop, where four snapshots pin the current text. Those are rows under this decision,
one per backend, and `decision-8 §7` names neither word. What is **not** settled here is the *type* of
an out-of-range read — `T` or `?T` — which is
[decision 63](#63-an-index-answers-t-and-an-absent-key-fails-rather-than-answering), answered (a) with a
rider: `T`, and an absent key fails rather than answering either word.

---

## 48. The formatter's `var` arm is a carve-out of `16`, landed by `17`

**Decided 2026-09-18 by the maintainer: (a).** One `ValDecl` printer arm reading the new `mutable`
field, and one `assertLossless` case, in the **same commit** that makes `var` parse — a named
carve-out of `16-formatter`'s `src/format.zig`, not a reopening of that front.

**Measured.** `var` is a lexer token (`src/lexer/token.zig:115`) that **no** parser or formatter line
mentions at `feat` `1379659`. `16-formatter` landed steps 3–5 the same day (`37d3dc7`) — the front
whose whole finding was that the formatter **deleted the word `default`** — and it landed
`assertLossless` with it. `09-ecosystem-residuals` has already committed the five libraries formatted,
so a printer arm arriving one commit late edits committed files.

This is rule 19 of [`fronts.md`](./fronts.md) applied: a new form arrives with its round-trip
confirmed. The alternatives both leave a window in which `botopink format` deletes `var` from a valid
file.

**Blocks:** step 1 of [`17-beam-memory`](./17-beam-memory/README.md).

---

## 49. `17` opens after `01`'s step 4 is committed

**Decided 2026-09-18 by the maintainer: (a).**

**Measured.** `01-checker` holds **+208/−23 uncommitted lines in `src/comptime/infer.zig`** in
`.tasks/checker` — its step 4, the `case`-arm typing, which was blocked on three backend defects that
are now fixed on all four backends. Front 17's steps 1 and 3 want two diagnostics in the same file,
beside decision 37's at `:2742`. Waiting costs hours; not waiting costs a hand-merge of a working
208-line diff in the hottest file of the milestone, which is the failure the project's own record
describes as an auto-merge breaking parameter threading after a post-fork refactor.

Rejected (c) — `01` writing both diagnostics itself — not because it is wrong, but because it moves
decision 38's rule into the checker front's numbering and leaves decision 38 without a single owner.

**Blocks:** the opening of [`17-beam-memory`](./17-beam-memory/README.md).

---

## 50. `17` runs steps 0–3b in this milestone; steps 4–8 become a spec for the next

**Decided 2026-09-18 by the maintainer: (a).**

**Measured.** Steps 4–5 — the three BEAM modes — need `13-module-identity`, which has not started, and
`13` needs `06` → `14` first (`14` landed steps 0–2; `06` has not started). Steps 0, 1, 2, 3 and 3b
need none of it.

What lands in this wave: `var` parses at module level, a `val` is immutable (decision 38), commonJS and
wasm carry a module `var`, the annotation is validated (decision 41), the formatter prints the form
(decision 48), and `libs/std/src/beam.bp` is specified for front 09 (decision 43). What does not: the
`Ets`, `PersistentTerm` and process-dictionary **emission**, and with it the 96 lines of
`rakun/src/runtime.mjs` the front promised to remove — they need their owner.

Rejected: the whole front after `13`, which makes `17` the critical path and lands nothing; and steps
0–2 only, which is decision 41's failure family by construction — `#[@BeamMemory.Etz]` accepted and
ignored, an annotation born without being trustworthy.

**Blocks:** nothing — it is the scope every other row of this front is read against.

**Re-read against [decision 62](#62-the-order-of-what-is-left-in-the-milestone) and what has landed since.** Two parentheses of the
measurement above have moved, and the scope has not. `13-module-identity` **has** started — `.tasks/identity`,
step 0 and half 1, with halves 2–3 running now by 62 — and 06 is no longer 13's prerequisite: 62 puts it
after 01's steps 4–5 — and 62's own correction goes further: 06 has **already landed** (`579ab0d`, 338
comptime snapshots), so "06 has not started" was never true of the tree this decision was measured
against. Step 3b's module is now **landed** rather than pending: front 09 committed
`libs/std/src/beam.bp` before 17 opens, which is 62's answer and [decision 43](#43-beammemory-lives-in-two-layers--and-off-the-beam-the-annotation-is-a-no-op-while-the-module-is-an-error)'s split. So
what this front still owes step 3b is the acceptance run, and that run is blocked by
[question 64](./decisions-pending.md#64-how-does-beammemorys-layer-2-reach-layer-1-when-the-erlang-backend-emits-no-wrapper).
The scope stands exactly as decided: steps 0–3b this milestone, steps 4–8 a spec for after 13.

---

## 51. `keyed = true` is a `Dict`-only argument

**Decided 2026-09-18 by the maintainer: (c).** `List<T>` does **not** join `Dict` under `keyed` — the
half of confirmation 1 that proposed it was withdrawn together with the `ProcessDict` half. A list under
`Ets` stores its whole value, and `#[@BeamMemory.Ets(keyed = true)]` on one is the same located error
decision 41 already writes: *`keyed` needs a keyed container*.

**Why it is the right shape, not just the smaller one.** In a `Dict` the element's key **is** the user's
key, which is what makes the mode unambiguous and what the measurement measured (254 → 51 ns at 10 keys,
301 864 → 60 ns at 10 000, and six of 40 000 writes lost silently under `keyed = false`). A list has no
such key, and neither reading survives: with the **index** as the key, two processes appending at the
same time choose the same index and the length becomes the contended row `keyed` exists to remove — so
the mode would be honest for positional update only, never for append; with an **element identity**, the
value is no longer a list but a `Dict<Id, T>` with an order, which is a type question wearing a storage
answer.

Positional update stays available later, as its own row with its own measurement; nothing about (c)
forecloses it.

**Blocks:** nothing. Step 3 of [`17-beam-memory`](./17-beam-memory/README.md) validates `keyed` against
`Dict` only, and step 4 — deferred by decision 50 — has one container to emit instead of two.

---

## 52. A condition loop that never breaks answers `null`

**Decided 2026-09-18 by the maintainer: (a).** A loop with no `break <value>` has no value to give, on
every backend.

**Measured.** erlang printed **`3`** — the loop's variable group — where commonJS printed **`null`**, and
front 04's landed test asserts `null` citing decision 8 §10. The divergence only became observable when
front 02's `a9e9d03` made the program terminate at all.

**What it costs, by backend.** commonJS is already right. erlang and beam print `undefined` for the
exhausted loop and must print the `null` spelling instead — four snapshots pin the current text, and
front 03's D6 fixture (`8 / 4 / 3 / undefined`) is one of them. wasm is the last backend where a
condition loop still *collects*, so it owes §10 as a whole (`[8] / 4 / [3] / []`), not only this row.

**Blocks:** nothing — but the four pinned snapshots mean the row cannot be landed by editing a text: it
is one row per backend, and the cell comes first.

**Correction, 2026-09-18, measured by [`12-language-tests`](./12-language-tests/README.md):** the
paragraph above is wrong about three of the four backends. An exhausted condition loop prints **`3`** on
erlang — the loop's variable group, which is what the divergence was always about — the atom **`ok`** on
beam, and **`0`** on wasm. **None of them prints `undefined`**: that word is
[decision 47](#47-absent-has-one-spelling-null)'s row, not this one, and the `[]` in the wasm quartet
quoted above is `0` for this row, whatever the rest of §10 owes there. commonJS is still the backend that
is already right, and the shape of the work does not move: one row per backend, the cell first.

---

## 54. A `?T` is matched by `null` and a binder

**Decided 2026-09-18 by the maintainer: (b).** `case x { null { … } v { … } }` — the shape `??` and `?.`
already use — and **not** `.Some(v)` / `.None`, which becomes a located error.

**Measured.** The optional had no working pattern form at all: `.Some(v)` / `.None` over a `?i32 = 5`
**compiled and printed nothing** (exit 0), while `Option.Some(value: v)` fell through to `_`. Both
silent. Decisions 2 and 32 had already removed `Option<T>` and `Option.Some` from the language.

**What the answer obliges.** Three things, and the third is the one that would otherwise be forgotten:
`null` and a binder are typed and lowered as a pattern (the binder is the payload, narrowed); a variant
pattern over a `?T` is a located error naming the `null` form; and the `is-variant-binding` diagnostic's
hint — which still recommends `case x { Option.Some(value: v) { … } }`, a spelling the language does not
have — is corrected in the same pass. Rejected (a): it would have made the optional a variant everywhere
except in `??` and `?.`, which are the two readers authors already use.

**Blocks:** a row of [`01-checker`](./01-checker/README.md), and the cells
[`12-language-tests`](./12-language-tests/README.md) writes for the optional.

**Correction, 2026-09-18, measured by [`12-language-tests`](./12-language-tests/README.md), twice over.**
Neither half moves the answer, and both enlarge it:

1. **The decided spelling does not parse.** `case x { null { … } v { … } }` is
   `error: this token cannot appear here --> src/main.bp:21:22` with `^^^^ unexpected `null`` on **every**
   target. This decision measured only the variant spelling, so its row is a **parser** row as much as a
   checker one — and the honest statement of the state is that a `?T` has *no* working pattern form at
   all: neither the one that is refused nor the one that is chosen.
2. **The variant spelling does not "print nothing".** `.Some(v)` / `.None` over a `?i32 = 5` prints
   `undefined` on commonJS, `0` on wasm and `5` on beam, and dies with `no case clause matching 5` on
   erlang: four wrong answers, exit 0 on three of them. "Compiled and printed nothing, exit 0" was one
   backend generalised to four.

---

## 57. `src/comptime/**` gets a warning channel

**Decided 2026-09-18 by the maintainer: build it (a).** A `warnings` list on the `Env`, rendered like a
`TypeError`, inside a row of [`01-checker`](./01-checker/README.md).

**Measured.** `grep -rn warning modules/compiler-core/src/comptime/*.zig` → **0**. Four obligations want
one and have been stuck behind it: decision 8 §1.4, §2.4, §4.3 and decision 42's `keyed`-on-a-`Dict`
warning — which is why 42's own recommendation was written conditionally. It is the smallest piece of
infrastructure in the milestone that unblocks the most rows, and the renderer already exists.

**Blocks:** it *unblocks* — those four rows stop being "no channel, so error or `docs.md`".

---

## 58. The inline `implement <Behavior> { }` check is `01-checker`'s row

**Decided 2026-09-18 by the maintainer: (a).** It is the same check as the separate `implement X for Y`
block, applied to the inline form; it is not a question about meaning.

**Measured.** `type Money(cents: i32) implement Display { }` **passes** — with a locally declared
`Display` and with the long-registered `Generator` — while only the separate block is covered by the
`implement_missing_a_required_interface_method` snapshot family. So the inline form asserts that a type
satisfies a behavior and nothing verifies the assertion: the same family as decisions 37, 38 and 45, the
checker accepting what a backend then answers on its own.

**Blocks:** a row of [`01-checker`](./01-checker/README.md) — it had none.

---

## 59. Whoever deletes an `expected-failures.txt` line recounts its header from the file

**Decided 2026-09-18 by the maintainer: (a).** The rule stays where it is written, in the file: recount
**from the file**, never from your own delta. Moving the paragraph into `run.sh`'s output — the real fix
for a number kept by hand in a file seven fronts share — is a row of
[`12-language-tests`](./12-language-tests/README.md) for when it reopens, not a merge correction.

**Measured, twice in one day.** The paragraph was two lines stale from front 04's landing, which deleted
two lines without re-tallying; then fronts 02 and 03 rewrote the same block from different baselines and
conflicted. Re-derived from the file, the truth was 58 lines / 53 under `--target all` / 5 beam-only, and
both fronts' arithmetic was individually right and jointly wrong. One sub-claim in that paragraph is
**still** stale and is front 12's to correct: it says "24 lines name a second row", and the count is 19.

**Blocks:** nothing. It is the rule every front now follows, and the drift it catches is reported rather
than silently adjusted.

**Correction, 2026-09-18, re-derived from the file by
[`12-language-tests`](./12-language-tests/README.md) at `b5a9b85d`:** the sub-claim this decision hands
front 12 is **not** stale — this text is. The paragraph already says **19** lines name a second row, and
19 is the count, so there is nothing to correct in the file. The rule stands, and so does its lesson,
now applied to the decision that stated it: a number kept by hand in a file seven fronts share is
re-derived from the file, including when the claim that it drifted is a decision's. And the numbers have
moved again since — the fronts 12 × 13 merge conflicted on this very paragraph, both sides having
rewritten it from different baselines, and re-deriving from the merged file gave **77 lines**, 66 under
`--target all`, 11 beam-only, 12 starred and **23** naming a second row. Every figure in this decision is
therefore a date, not a fact: read the file.

---

## 53. The range spelling is Zig's split: `...` inclusive in a pattern, `..` exclusive in a slice

**Decided 2026-09-18 by the maintainer: (a).** Decisions 20 and 36 are **amended**; the compiler's
behaviour does not move.

**Measured, and it is why the amendment goes this way.** Both decisions cite Zig as their reason, and the
citation was wrong. `zig version` 0.16.0:

```zig
const r = switch (x) { 1...9 => true, else => false };   // passes — `...` in a pattern, INCLUSIVE
for (0..3) |_| n += 1;                                   // passes — `..` in a for range, EXCLUSIVE
try expect(xs[0..2].len == 2);                           // passes — `..` in a slice, EXCLUSIVE
const r = switch (x) { 1..9 => true, else => false };    // error: expected '=>', found '..'
```

Zig has **both** spellings, in different positions, and `1..9` inside a `switch` does not exist there at
all. So botopink's compiler — `...` inclusive in a pattern, `..` exclusive in a slice — was the
Zig-consistent side, and "one spelling, `..`, as in Zig" was the divergent one. The maintainer confirmed
after reading the measurement: *"o zig tem os dois `...` e `..`, então pode fazer igual"*.

**What moves:** the text of decisions 20 and 36, and the `pattern-range-exclusive` diagnostic, which
currently tells the author to write the spelling those decisions banned. **What does not move:** any
emitter.

**One defect survives the amendment, and it is the serious half.** `case 9 { 1...9 { 1 } _ { 0 } }`
answers **1** on commonJS, **0** on erlang and **256** on wasm, and beam emits only `out/main.S`. That is
the range pattern not being implemented on two backends, and it needs a cell in
[`12-language-tests`](./12-language-tests/README.md) plus a row per backend under any spelling.

**Correction, 2026-09-18, re-measured by [`12-language-tests`](./12-language-tests/README.md)** at
`b5a9b85d` and `3cfb65cb`, at five points instead of one — and the single point is why the paragraph
above is wrong in two halves:

| `case n { 1...9 { 1 } _ { 0 } }` | n=5 | n=1 | n=9 | n=0 | n=10 | the reading |
|---|---|---|---|---|---|---|
| commonJS | 1 | 1 | 1 | 0 | 0 | correct |
| erlang | 0 | 0 | 0 | 0 | 0 | the arm **never** matches |
| wasm | 0 | 0 | 0 | 0 | 0 | never — and **not** `256` |
| beam | 1 | 1 | 1 | 1 | 1 | the arm **always** matches |

So wasm answers `0`, not `256`, and beam **runs**: "emits only `out/main.S`" stopped being true when
`run.sh` gained its beam path. At `n = 9` alone the four read `1 / 0 / 0 / 1`, which makes beam's `1`
look like the right answer when it is a false positive — **a single-value probe cannot measure a
range**, and that is worth keeping as a rule. The defect is also worse than recorded: not two backends
missing the pattern, but two that never match and one that always does.

**And the diagnostic does not move.** "What moves" lists `pattern-range-exclusive` beside the text of 20
and 36, but that diagnostic fires on `1..9` *in a pattern* and recommends `1...9` — the spelling this
amendment blesses ([20](#20-is-a-pattern-range-inclusive) records it landing in `dff3446`;
[36](#36-does--exclude-its-end-in-a-pattern) calls it "the spelling today's diagnostic
recommends"). What moves is the text of decisions 20 and 36, and nothing in the compiler, exactly as the
first line of this decision says.

---

## 55. `break <value>` in a collection loop contributes its value and ends the loop

**Decided 2026-09-18 by the maintainer: (a).** Written into decision 8 §10 rather than left to the
emitters.

**Measured on all four backends** — `val r = loop ([10, 20, 30]) { x -> … }; @print(r);`:

| body | commonJS | beam | erlang | wasm |
|---|---|---|---|---|
| `yield x * 2;` | `[20, 40, 60]` | `[20, 40, 60]` | `[20,40,60]` | `[20,40,60]` |
| `if (x == 20) { break x; };` | `[20]` | `[20]` | `[20]` | `[20]` |
| `yield x * 2; if (x == 20) { break 99; };` | `[20, 40, 60]` | `[20, 40, 60]` | `[ok,99,ok]` | `[20,40,99,60]` |
| `if (x == 20) { break 99; }; yield x * 2;` | `[20, 99, 60]` | `[20, 99, 60]` | `[20,40,60]` | `[20,99,40,60]` |
| `yield x * 2; if (x == 20) { break; };` | `[20, 40, 60]` | `[20, 40, 60]` | `ok` | `[20, 40]` |

The two ingredients agree on all four when they appear alone. Together, nothing does: **no backend stops
the loop** in the third row, only wasm stops it in the fifth, erlang loses the accumulated values in
both, and in three of the four **swapping two adjacent lines changes the answer**.

**Under this decision** the three disagreeing rows are `[20, 40, 99]`, `[20, 99]` and `[20, 40]`, and
today **wasm alone** answers one of them (the fifth). Rejected: answering only the value and discarding
the accumulator, which would give one `val r = loop …` two possible types depending on which path ran at
run time — something no other construct in the language does; and refusing the combination, which is
cheap and honest but forbids "accumulate while searching, and record what you found".

**Blocks:** a cell per row in [`12-language-tests`](./12-language-tests/README.md) — being written now,
carrying this decision's column as its `.out` — and then one row per backend against it.

**Two things this decision owes its implementers, reported 2026-09-18 by
[`12-language-tests`](./12-language-tests/README.md).**

- **Front 02 has no step for it.** `04`'s step 3 and `05`'s step 4 are both titled `break <value>`, and
  `03`'s step 3 carries D7's beam measurement, so three backends have a numbered home; front 02's step 5
  is the **condition** loop, and nothing in its nine steps is §10's *collection* loop. The cells landed
  carrying `02 (no step; decision 55, reported 2026-09-18)` rather than inventing a row. Either front
  02's README gains the step, or this paragraph is the record of its absence.
- **It turns a green cell red on all four backends** — the only place in the milestone where that
  happened. `test/loop_collection.bp` asserted `3` / `2,4,6` for
  `loop ([1, 2, 3]) { x -> break x * 2; }` and every backend agreed, because they share one accumulator
  and none of them stops at a `break`; under this decision the answer is `[2]`. That agreement was
  exactly the evidence the decision had to override, which is worth saying in as many words: four
  backends agreeing is not four backends being right.

---

## 56. `botopink run --target erlang` takes `erl`'s exit status

**Decided 2026-09-18 by the maintainer: (a).** The crash status becomes `1`, and
`modules/compiler-cli/AGENTS.md`'s command contract is amended **in the same commit** as the runner fix,
so the change is documented where it is read.

**Measured** by [`10-cli-residuals`](./10-cli-residuals/README.md): the runner runs
`escript out/main.erl`, which compiles only the file it is handed, so three `modules/*` cells and
`examples/modules` fail on erlang with correct, qualified emitted code. The fix is `erlc -o <out_dir>`
over every emitted `.erl` found recursively — the layout nests while the module atom is flat — then
`erl -noshell -pa <out_dir> -eval "<module>:main([]), halt()."`, with `main([])` because `main/0` is only
emitted when `main` is `pub`. At that shape all four projects print what they mean. A `1 / 0` program
exits `127` under escript and `1` under `erl`.

Rejected: mapping `erl`'s failure back onto `127`, which preserves an accident and leaves a mapping the
next reader takes for meaning; and defining a status per outcome across four targets, which is a real
command-contract row for when someone needs a distinguishable status, not a rider on a runner fix.

**Blocks:** nothing now — front 13 has the answer and is implementing the runner row.

---

## 60. The parser accepts an optional `;` before the formatter picks a side

**Decided 2026-09-18 by the maintainer: (b), with (c) as the wording fix.**

**Measured.** Decision 29's recorded order — *"16 stops printing the `;` → 15 applies the parser patch →
12, `libs/std` and 09 migrate"* — cannot run, because a block-shaped statement without its `;` is a parse
error today:

```
error: this token cannot appear here --> src/main.bp:3:5
3 |     loop (3) { @print(1); };
  |     ^^^^ unexpected `loop`
  = hint: The statement before it may be missing its `;`
```

A formatter that stopped printing the `;` would emit text its own parser refuses, and `assertIdempotent`
re-parses pass 1 — every formatter test would fail and every formatted file would stop compiling.

**So the parser goes first**, accepting both spellings (`semicolonPolicy` → optional) as a landing of its
own: strictly accepting, re-records nothing, breaks no file, and it turns an impossible sequence into two
ordinary ones. Only then does the printer choose a side, and migration follows at leisure.

**And (c) is written down too**, because the decision and the patch that implements it disagree: front
15's parked `isBlockShapedStmt` tests the **node**, so it rejects `if (c) return x;` — a braceless `if`,
which has no closing brace to end itself — while decision 29's wording is about the closing brace.
Decision 29 is narrowed to the **braced** form; a braceless statement keeps its `;`. The five libraries
alone hold 30+ braceless sites, so the two readings would have migrated different files.

**Blocks:** it *unblocks* — the formatter half of decision 29, front 16's step 6 ordering, and front 15's
parked patch.

---

## 61. The formatter's canonical layout — four rules

**Decided 2026-09-18 by the maintainer: the conventional form in all four.** Front 16's step 6 says a
rule that changes how every library looks is the maintainer's, and these are the four it stopped on. Each
was re-measured by running `botopink format` over a hand-written file at `3cfb65c`.

**1. A lambda *argument*'s body indents +4, and its closing `});` aligns with the call.** Today:

```botopink
    xs.forEach({ x ->
            @print(x);          // +8 from the call line
        });                     // +4
```
It is the largest single source of churn in front 09's diffs (erika and jhonstart).

**2. A lambda with an empty body stays inline** — `{ next -> }`. Today it explodes into three lines whose
middle line carries **eight spaces and nothing else**, in a formatter that avoids trailing whitespace
everywhere else.

**3. The one-line rule covers a parameterless lambda.** Today `{ -> 3 + 4 }` explodes while
`{ n -> n * 2 }` stays inline — `fmtLambdaAt`'s one-line rule simply does not test the no-parameter case.

**4. A `fn` signature that does not fit breaks one parameter per line, with a trailing comma**, closing
on its own line:

```botopink
fn aVeryLongFunctionName(
    firstParameter: i32,
    secondParameter: string,
    thirdParameter: bool,
) -> string {
```

Today the formatter joins that into **104 columns** against `LINE_WIDTH = 80`, because a signature has no
break available. **Measured, and it decides the cost: that shape already parses** — `botopink check` on
exactly the text above answers `Checked in 66.60ms`, trailing comma included. So rule 4 is a printer-only
change; no parser work, no grammar decision.

**What it costs.** Rules 2 and 3 are corrections — the formatter contradicts itself — and move nothing
committed. Rules 1 and 4 change the shape of committed files, which is why they were the maintainer's:
front 09 reformats the five libraries in one commit, deliberately now, while its 861 changed lines are
recent, rather than after more code is written in the old shape.

**Blocks:** step 6 of [`16-formatter`](./16-formatter/README.md), then one reformat commit in
[`09-ecosystem-residuals`](./09-ecosystem-residuals/README.md).

**Landed 2026-09-18** — all four rules, and the measured cost is **607 lines** across the six trees:
erika 165, `libs/std` 160, rakun 139, jhonstart 106, onze 37, emilia 0, of which rule 1 accounts for 428
and rule 4 for 123. Forty-eight of `libs/std`'s belong to no rule — they are pre-existing, because that
tree has never been formatted.

**And rule 4 had to route around a broken predicate, which is the next decision of this class.**
`fmtParams`' `group` was never missing: **`fits` stops at the first `concat`** and then answers "fits" for
any non-negative budget, so *every* group in the formatter renders flat. Rule 4 therefore landed as a
`Doc.widthChoice` whose flat width is measured at build time against the real column — which is why a
method four columns in breaks four columns earlier, and why the trailing ` {` or `;` counts, the boundary
being exact at 80/81. Teaching `fits` to measure through `concat`/`nest`/`group` would make array
literals, calls, type unions and every comma list start breaking by width **at once**: a canonical-form
choice per construct, and several hundred lines on top of these 607. That is the same class of call this
decision was, so it is the maintainer's and not a front's — opened as
[question 65](./decisions-pending.md#65-does-the-formatter-learn-to-measure-width). Rule 3 also stops at `arrow_when_empty`,
for the parse-error reason recorded in [`decisions-pending.md`](./decisions-pending.md).

---

## 62. The order of what is left in the milestone

**Decided 2026-09-18 by the maintainer**, six calls, none of them about meaning and each of them costing
rework in the wrong order:

| call | answer | why |
|---|---|---|
| `06-comptime-dedup` before or after `01-checker`? | **After** 01's steps 4 and 5 — **moot, see the correction below** | 01's step 4 waited the whole milestone for the four backends and is written; changing the snapshot layout underneath it is the worst of both. 06 stays a prerequisite for 01's steps 6–11 |
| When do 13's halves 2–3 run? | **Now**, straight after half 1 | They own both emitters wholesale and re-record ≈318 cells — and fronts 02 and 03 have nothing actionable left (everything behind 01 or 13), so nothing is stalled |
| Does `14-comptime-on-beam` step 3 happen? | **Deferred until after 13** | Its blocker is measured: the *typed* beam backend already fails the case the untyped mode exists for, and 13 is what fixes identity on beam |
| beam's BR5 (string templates at 50×) | **Out of 1.0.5**, its own spec with the measurement | Re-measured: `base64:encode` 0.113 → 5.722 µs/call (**50.6×**). The block is structural — nothing in this compiler parses Erlang, and the parked branch is a 836-line Zig lexer+parser that no longer builds |
| When does `libs/std/src/beam.bp` (17's step 3b) land? | **Before** front 17 opens — front 09 closes its part first | The module compiles per target under `test-libs` with no consumer, so it does not need 17 in flight |
| The ~20 defects with an owner and no row | **Three this wave**, the rest a 1.0.6 list | `Type.assoc()`'s missing return type (front 01), `Shape.unit()` emitting `{unit}` (02/13), and beam swallowing `.length` on an index receiver (03). The first reproduces inside one module; the third is silent with exit 0 |

**Blocks:** nothing — this *is* the schedule the remaining fronts are read against, and it supersedes the
Order section of [`fronts.md`](./fronts.md) where the two differ, and
[decision 4](#4-the-order-that-dissolves-the-circular-dependency--settled) where they differ about 06.

**Correction, 2026-09-18: the first call is moot, and it was answered against a stale row.**
`06-comptime-dedup`'s work is **already in the tree**. `snapshots/comptime/` holds exactly **338**
`.snap.md` files — the number `fronts.md` states as the front's *promise* — and the commit that did it is
`579ab0d0`, *"refactor(comptime): one snapshot per test, not four byte-identical copies per slug"*, an
ancestor of `feat` landed before this session. Front 13 met the same fact from the other side while
re-deriving its step 0: it measured the corpus at 1 859 snapshots against its README's 2 573, for exactly
this reason. So there is no snapshot layout left to change underneath 01's step 4, this row's *why* no
longer describes anything, and — the half that matters for planning — **front 01's steps 6 to 11 are
behind nothing.** Nothing else in this milestone should be sequenced behind 06; where a document still
does (`fronts.md`'s 06 row and its conflict-matrix notes 2 and 13,
[decision 4](#4-the-order-that-dissolves-the-circular-dependency--settled)'s order,
[decision 50](#50-17-runs-steps-03b-in-this-milestone-steps-48-become-a-spec-for-the-next)'s measurement)
it is reading a front that has already landed. What remains open is whether the front's *other* steps —
the `id` field of [decision 19](#19-the-comptime-renderers-id-field) among them — are also in `579ab0d`;
nobody has re-derived that, and it is the one thing left to check before the row is closed.

---

## 67. The most restrictive behaviour, and no configuration that bypasses it

**Decided 2026-09-19 by the maintainer, as a standing principle rather than a row:** *"eu gosto de que seja
sempre o mais restritivo possível e sem configuração para burlar isso"* — always the most restrictive
behaviour available, and **no configuration through which anyone can get around it**.

**What prompted it** belongs in the record, because it is the clearest example there is. Answering
[question 63](#63-an-index-answers-t-and-an-absent-key-fails-rather-than-answering) he compared with
TypeScript, where the strict index check *exists* and is called `noUncheckedIndexedAccess` — a **flag**, off
by default, so the default lies: `const v: number = d["k"]` compiles and `v` can be `undefined`. The check
is not missing there; it is optional, which under this principle amounts to the same thing, because the
shape everyone actually gets is the loose one.

**What it means for a question.** Where the options offer *refuse* against *accept*, or *fail* against
*warn*, the recommendation defaults to the stricter side unless the strict side would have to invent new
semantics in order to exist. A front writing an option list writes that default into it rather than
discovering it here. And where an exemption cannot be avoided it is **structural** — a directory whose
meaning the tool knows, a form the grammar does not admit — and never a knob: a skip list, a per-file pragma
or an environment variable is precisely the configuration this principle refuses, because an exemption with
a switch on it travels to wherever someone finds it convenient.

**What it reinforces.** The no-`--no-verify` rule, from the other side: the gate is not skipped, and now it
is not loosened either. And it rules a whole shape of answer out in advance — "keep the strict behaviour and
add a flag for the people it inconveniences" is not an answer this record will recommend.

**Consequences already recorded.** It is why
[decision 63](#63-an-index-answers-t-and-an-absent-key-fails-rather-than-answering) departs from TypeScript
at run time; why
[decision 66](#66-format---check-looks-at-the-whole-project--and-something-has-to-call-it)'s `reject/**`
exemption has to be structural and `format_cmd.zig` must **not** grow the skip list it currently lacks; why
option (b) of
[question 64](./decisions-pending.md#64-how-does-beammemorys-layer-2-reach-layer-1-when-the-erlang-backend-emits-no-wrapper)
is out, emitting `erlang:put/2` from `.zig` being exactly the bypass of a decision already taken; and why
option (b) of [question 65](./decisions-pending.md#65-does-the-formatter-learn-to-measure-width) is the
weakest of its three, because it keeps a predicate that answers wrongly for every caller as the permanent
state.

**Blocks:** nothing, and everything after it — this is a rule for how the remaining options are written and
chosen, not a row a front implements.

---

## 63. An index answers `T`, and an absent key fails rather than answering

**Decided 2026-09-19 by the maintainer: (a), with a rule that is stricter than (a) as it was written.** In
his words: *"nesse caso só pode ser atribuído null se o V for ?V — deveria falhar se não for esse caso e a
key nem foi definida. Veja como typescript se comporta."* Three rules:

- an index answers the element or the value type, **`T`** — not `?T`, and not the `void` the checker
  answers today;
- **`null` may come out only where the declared value type is itself optional**: `Dict<string, ?i32>`
  indexes to `?i32`, and that is the one shape in which absence is a value;
- where the value type is **not** optional and the key or the index is absent, the program **fails**. It
  does not answer `undefined` and it does not answer `null`.

**TypeScript, measured because the answer cites it** (`tsc 5.9.3`):

```
# strict: true, no noUncheckedIndexedAccess     → both compile, exit 0
const v: number = d["k"];      // d: Record<string, number>
const e: number = xs[9];       // xs: number[]

# strict: true + noUncheckedIndexedAccess: true → exit 2
a.ts(3,7): error TS2322: Type 'number | undefined' is not assignable to type 'number'.
a.ts(4,7): error TS2322: Type 'number | undefined' is not assignable to type 'number'.
```

So TypeScript's **default** is this question's option (a) and its opt-in flag is option (b): on the typing
side the answer is TS-default-shaped, `at` returning an optional stays the different feature decision 30
argued it was, and no line in `libs/std`, `examples/**` or the five libraries grows a `?.`. **The rider
departs from TypeScript at run time, on purpose, and that is
[decision 67](#67-the-most-restrictive-behaviour-and-no-configuration-that-bypasses-it) in action.** TS's
default answers `undefined` and says nothing — the hole option (a) is otherwise accepted with — and its
strict form is a *flag*, which 67 counts as not having it. This closes the hole instead: the type is `T`
because the ordinary case is a key that is there, and the extraordinary case is a *failure* rather than a
value the type does not describe.

**What it costs, and it inverts who owes the work.** Measured 2026-09-19, twice, on a dict that **holds**
the key — the outputs in full are under [decision 46](#46-dk-on-a-dict-routes-to-lookup):

| backend | today | what it owes |
|---|---|---|
| commonJS | `undefined`, silently | **the outlier.** It must start failing — the only backend whose current behaviour this decision rules out entirely |
| erlang | the node dies: `{bp_unsupported_index, #{pairs => [{<<"k">>,1}]}, <<"k">>}` thrown from `__bp_index/2` | closest to intent, and still wrong: a crash during boot is not a **located** failure |
| wasm | `unreachable` trap | in between — it stops, with nothing to read |

Three per-backend rows, then, plus the checker row that types the index `T` (item 2 of front 15's handover,
`ast.zig:1734`) and [decision 46](#46-dk-on-a-dict-routes-to-lookup)'s `lookup` route, which this answer
turns from a neighbouring row into a **prerequisite**: a dict index has to consult `lookup` *and* fail on
its empty answer, unless the value type is optional, in which case it returns it.

**What it does not touch.** [Decision 47](#47-absent-has-one-spelling-null) stands where it applies: `at`
answers `null`, and so does an index whose value type is `?T`. What 63 removes is `null` as the answer to an
index whose type is *not* optional. And front 12's cell
`index_an_index_past_the_end_answers_zero` now needs a third rewrite — its slug asserts `zero`, its text
asserts `undefined`, and the answer is a failure on all four backends.

**Blocks:** `01-checker`'s `xs[0]` typing row and, through it, the index lowering in all four backends; the
three per-backend rows above; the slug and the expected text of
`index_an_index_past_the_end_answers_zero`; and the three rows under decision 47.

---

## 66. `format --check` looks at the whole project — and something has to call it

**Decided 2026-09-19 by the maintainer: (a).** The scan widens to every `.bp` **and** `.d.bp` of a project,
gated on the parse defects, with a **declared exemption for `tests/language/reject/**`** — a corpus whose
purpose is to be refused, and the one place where a red is the fixture working.

**And the exemption is structural, by
[decision 67](#67-the-most-restrictive-behaviour-and-no-configuration-that-bypasses-it): the runner knows
what that directory is, and `format_cmd.zig` does not grow a skip list.** This inverts the finding front 16
recorded at its step 7. "There is no exemption mechanism today — `format_cmd.zig` takes either an explicit
file list or every `src/**.bp` the scanner names, with no skip list" was written as a gap to be filled; it
is a **constraint to preserve**. `reject/**` is exempt because of what it *is*, one directory the tool
recognises by name, and not because a configuration file says so — a knob would be the bypass 67 refuses,
and the first file anyone added to it would be a file someone did not want to format.

**This does not reopen [decision 34](#34-the-format---check-exemption-does-not-exist); it confirms it.** 34
refused an exemption *mechanism* — a `botopink.json` key (its option (a)) and a marker comment in the file
(its (b)) — and took (c), no mechanism at all, against its own recommendation. That is decision 67 before 67
was written down. A structural `reject/**` arm is neither of the options 34 refused: no project declares it,
nothing opts into it, and emilia's `tokens.bp` — the file 34 was about — stays formatted like every other.

**Two measurements the decision carries with it, because without them widening the scan changes nothing.**

**Fourteen of the twenty-seven directories that carry a `botopink.json` are red today, over 18 files, and
not one of them for a `test/` or a `.d.bp` reason** — every one is inside that project's own `src/**`. Nine
are outside the compiler: `examples/stdlib-tour`, `emilia/examples/emilia-card`,
`erika/examples/erika-linq`, `jhonstart/examples/{jhonstart-counter,jhonstart-html,jhonstart-todo}` and the
three `tests/language/modules/*` cells; five are fixtures under `modules/compiler-cli/tests/**`. So the
third axis of scope — the **nested project** — is where the drift actually collected, and it contradicts
`modules/compiler-core/src/format/AGENTS.md:111`. The five libraries' own `src/**` stay clean, which is why
this was invisible: the check was run per library and the rot is in the projects nested inside them.

**And no gate anywhere calls `format --check`.** `scripts/gate.sh` runs `zig fmt --check` over staged
`.zig` and nothing else; `scripts/git-hooks/pre-commit` names neither `format` nor `fmt`; none of the three
`.github/workflows/*.yml` does either. A widened scan that nothing invokes is a wider silence, so this
decision is two changes and not one: the scan's scope, and a caller for it.

**Blocks:** the gate itself (front 09's step 1) and the structural `reject/**` arm in `format_cmd.zig`,
which is [`10-cli-residuals`](./10-cli-residuals/README.md)'s file — an arm, not a mechanism. Behind the two
parse defects:
`libs/std/src/builtins.d.bp`'s `await` (front 01's step 11 / front 08) and the trailing lambda's one-line
body (front 15's parser surface, and the three `examples/jhonstart-app` files with it). And the three
`tests/language/modules/*` cells are front 12's, so widening hands a row to a front that had none.

---

## 64. The erlang backend emits a wrapper per host-bound std `declare fn` — and `std/beam` stays its own module

**Decided 2026-09-19 by the maintainer: (a) on the route, (i) on the sub-question.**

**Measured** by [`09-ecosystem-residuals`](./09-ecosystem-residuals/README.md) while landing
`libs/std/src/beam.bp`, and reproduced twice since. The erlang backend emits **no wrapper for any
host-bound std `declare fn`**: `out/erl/std@beam.erl` is 162 lines of which exactly one is code
(`-module(std@beam).`), `out/erl/std@erlang.erl` has two, and commonJS at the same place emits
`function cwd() { return process.cwd(); }`. So a qualified std host call resolves, type-checks, emits a
correct call — and dies:

```
botopink run --target erlang, exit 1
Runtime terminating during boot ({undef,[{'std@erlang',self,[],[]}, …]})
```

**The decisive fact is where it dies: in `std@erlang:self()`, not in `pdPut`.** The gap belongs to every
host-bound declaration in `libs/std` on the BEAM — `erlang.bp` included — so the row pays for itself
outside [`17-beam-memory`](./17-beam-memory/README.md), and it is what makes decision 43's two layers mean
what they say. It lands as a numbered row of front **02** or front **13**, whichever holds `erlang.zig`
when it is scheduled; 13 owns that file wholesale while its halves 2–3 run, which makes 13 the natural
home.

Rejected **(b)**, layer 2 emitting `erlang:put/2` and the ETS calls from `.zig`: it is precisely the bypass
decision 67 forbids — it buys the behaviour by withdrawing a decision taken on purpose — and, measured, it
does not even fix the general case, since `std@erlang:self()` stays `undef`. Rejected **(c)**, deferring
layer 2 with steps 4–5: it leaves layer 1 in the tree with no caller and step 3b's third acceptance bullet
permanently unrunnable, which is the shape decision 50 refused when it refused "steps 0–2 only".

**The sub-question, and why the answer is two modules.** The maintainer asked whether `std/beam` needs to
be separate from `std/erlang` at all, since `@External.Erlang` already covers both BEAM targets
(`codegen.zig:74-77` maps `.erlang` and `.beam` to the same lookup name). It stays separate because
`erlang.bp` is **read by the emitter at compile time** (`codegen/erlang.zig:184-206`) to build the
auto-imported BIF table — it is compiler input, not only a list of declarations. Merging ten primitives
nobody auto-imports into it makes the emitter read what does not concern it, and leaves the next reader to
work out why half the file is not in the table. The honest version of one module is the reverse: move the
BIF table out of `erlang.bp` first.

**Blocks:** it unblocks — step 3b's third acceptance bullet, and every read/write lowering of
`17-beam-memory`'s steps 4–5.

---

## 63 · amendment, 2026-09-19 — an index is sugar for a method call, and the method comes from a behavior

**Decided by the maintainer**, and it supersedes the answer recorded above. His words: *"`xs[0]` é só um
alias para `xs.at(0)`"*, and then *"crie behavior para essas funções `at` e `slice`, para que outros tipos
que implementem possam usar o mesmo recurso"*.

**The rule.** The index expression has **no typing rule of its own**. It rewrites to a method call, and the
type is whatever that method answers:

| written | rewrites to | type |
|---|---|---|
| `xs[0]` | `xs.at(0)` | `?T` |
| `d["k"]` | `d.at("k")` | `?V` |
| `s[1]` | `s.at(1)` | `?string` |
| `xs[0..2]` | `xs.slice(0, 2)` | `T[]` |
| `xs[1..]` | `xs.slice(1, null)` | `T[]` |

**And what the method *is* comes from a behavior**, so indexing stops being a privilege of three built-in
types. Ambient, like `Display` (decision 27), and for the same reason: the syntax has to find the method
without the author having imported anything.

```botopink
pub behavior Index<K, V> {
    fn at(self: Self, key: K) -> ?V;
}

pub behavior Slice<V> {
    fn slice(self: Self, start: i32, end: ?i32) -> V;
}
```

`Array<T>` implements `Index<i32, T>` and `Slice<T[]>`; `string` implements `Index<i32, string>` and
`Slice<string>`; `Dict<K, V>` implements `Index<K, V>`. A library's own `Matrix`, `Row` or `Buffer` becomes
indexable without touching the compiler, which is what the core-stays-generic rule asks for.

**Three measured facts the design had to respect.** There is **no `Range` type** — `start..end` is an AST
node (`ast.zig:778`), not a value, which is why `slice` takes two arguments and an open end passes `null`.
`string` spells its reader `charAt` (`primitives.bp:208`), so it renames or declares `at` beside it — the
rename costs **one** call in the whole ecosystem. And **a tuple cannot be covered**: `t[0]` needs a
*constant* index and answers a type *per position*, which `at(key: K) -> ?V` cannot express with one `V`,
so the tuple stays a checker special case and the behavior covers the other three.

**Why this replaces the earlier answer.** As recorded above, decision 63 cost four rows — the checker
typing by receiver, plus three backends changing behaviour, with commonJS the outlier that had to start
failing. As sugar for a method call it costs **one**: the rewrite. **No backend changes at all**, because
the lowering becomes an ordinary method call that all four already emit and already test. Decision 46
(`d["k"]` routes to `lookup`) becomes trivial — the route *is* the call — and decision 47's `null` keeps a
single place to come out of.

**Migration: zero, measured.** There are **5** index expressions in the entire ecosystem and **4 of them
are the cell `tests/language/run/index_expression.bp`**; the fifth is inside a JavaScript template. The
argument once made against "an index always answers an optional" — that every index written in the
ecosystem would grow a `?.` — is false, because none is written.

**The rows, and none of them waits on front 13:**

| # | row | file | measured cost |
|---|---|---|---|
| 1 | the two behaviors | `libs/std/src/builtins.d.bp` | ~10 lines |
| 2 | `Array` implements both | `libs/std/src/primitives.bp` | `at` exists; `slice` is new |
| 3 | `string` implements both | `libs/std/src/primitives.bp` | `charAt` → `at`: **1** call; `slice` is new |
| 4 | `Dict` implements `Index` | `libs/std/src/dict.bp` | `lookup` → `at`: 9 calls outside the file, 18 inside, **~83 snapshots** (the name reaches emitted code) |
| 5 | the rewrite `xs[k]` → `.at(k)`, `xs[a..b]` → `.slice(a, b)` | `src/comptime/transform.zig` | **no backend moves** |
| 6 | the form in `docs.md` | `docs.md` | one paragraph |

Rows 1–4 are `libs/std`, which front **09** lands as it landed `std/beam`; row 5 is front **01**'s; row 6
is front **08**'s.


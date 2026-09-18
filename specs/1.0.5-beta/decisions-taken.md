# Decisions taken — 1.0.5-beta

Answered by the maintainer, kept here as the record the fronts implement against. The numbering is
the one they had in [`decisions-pending.md`](./decisions-pending.md), which never reuses a number.

| # | Question | Answer |
|---|---|---|
| [1](#1-asyncgeneratort-does-not-exist) | `@AsyncGenerator<T>` or `@AsyncIterator<T>`? | correct the spec to `@AsyncIterator<T>` |
| [2](#2-optiont-does-not-exist-either) | Is `Option<T>` a spelling? | no — `?T` is the only one |
| [4](#4-the-order-that-dissolves-the-circular-dependency--settled) | The milestone's order | `06` → `14` → `13` → backends |
| [7](#7-a-types-methods-are-function-not-method) | LSP `Method` or Test Explorer? | the extension gives way |
| [8](#8-beam-as-a-target-of-the-language-suite) | `beam` in the language suite? | yes — it executes |
| [9](#9-arrayunique-is-broken-on-both-backends) | Who fixes `Array.unique`? | rewrite the body in `libs/std` |
| 3 | Is `import { X };` a form at all? | both forms stay — the shorthand is made to resolve |
| 5 | What *is* a value on the JS backends? | a class per declaration, a subclass per variant |
| 6 | Flat or nested erlang output? | flat, one directory per target |
| 10 | `@code` taken twice | rename the proposed annotation |
| 11 | `<Pattern> as <name>` | delete the form and its tests |
| 12 | Unnamed variant payloads | rejected, with a located diagnostic |
| 13 | `external-annotations.md`'s C1/C8 | steps of `01-checker` |
| 14 | Seven forms that do not parse | four parse, three absent, the rest to `15-language-surface` |
| 15 | A lower-case `#[@external(node, …)]` | a located error |
| 16 | The `mod` path warning | fix the cause; do not exempt or document — **implemented 2026-09-18, and it converged on option (b); see the note below** |
| 17 | rakun's erlang story | rakun supports every target; `libs/std` grows to carry it |
| 18 | emilia's `tokens.bp` and `format --check` | exempt now; `16-formatter` audits the formatter |
| 19 | The comptime renderer's `id` | removed |
| 20 | Is a pattern range inclusive? | one spelling — `..`, as in Zig; `...` leaves the grammar |
| 21 | Tagged map or tagged tuple? | T2, the tagged tuple |
| 22 | Who designs wasm's boxed value? | `13-module-identity`, for every backend |
| 23 | Does a `behavior` need an atom? | reserve `__b__`, emit nothing |
| 24 | Does step 3 of 14 happen? | every step — the principle governs |
| 25 | Does `is` carry a pattern? | no; `case` is the only construct that binds |
| 27 | Who declares `behavior Display`? | `01-checker`, in `libs/std` |
| 26 | `case` arms of different types | they union — inference may produce a union |
| 35 | Structural equality | structural — it follows from 37 |
| 37 | Is a record immutable? | **yes** — the checker rejects `p.f = v` |
| 29 | Does a block-shaped statement end itself? | **(c)** — no `;`; ~274 sites migrate |
| 30 | Is there an index expression? | **yes** — `xs[0]` parses everywhere |
| 31 | Does `any` exist? | deleted, for now; `Iterator` gets a real default |
| 32 | `Option.None` / `Some(1)` in value position | removed from the documents; the optional is `?T` |
| 33 | A bodyless `fn` with no return type | **(b)** — it declares one; three `libs/std` lines gain `-> void` |
| 34 | The `format --check` exemption | **(c)** — no exemption; decision 18's is withdrawn |
| 36 | Does `..` exclude its end in a pattern? | yes — exclusive everywhere |

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

**Blocks:** decision 8 §9 being a true document; 03's N25 acceptance text.

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

**Blocks:** 02's `case` cells over optionals; the correctness of decision 8 §§2–5 and §9.

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

**Blocks:** front 20's defect A; `08-hygiene` step 3; every import example in the documentation.

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
and the remaining form as **deliberately absent**: `??` duplicates `catch` and `?.`, and module-level
`var` contradicts decision 2's "a module has no mutable state", which is the rule the whole comptime
protocol rests on.

**Blocks:** `01-checker` and whatever picks up the grammar's tail.


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

## 37. Is a record immutable?

**Decided 2026-09-18 by the maintainer: (a) — a record is immutable.** `p.age = 31` must not happen.
The checker rejects a field assignment with a located diagnostic naming the update form
(`Person(..p, age: 31)`), which already works; the erlang emitter's comment path becomes dead code and
stops producing a module that will not compile; and `val` starts meaning what it reads as.**Measured 2026-09-18**, after the maintainer asked whether the value could be immutable. It is not,
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
composite one without the checker marking the site, the way `method_lowerings` already does by `Loc`.**Measured** (front 12, writing the type-identity cells): `Person(name: "Ana") == Person(name: "Ana")`
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

---


This file stays because the fronts will fill it again. A front that meets a question it cannot answer
from the code writes it here rather than guessing, in the shape the others used:

> **Measured.** What was observed, with the command or program that produced it and the file or commit
> that can be re-read.
>
> **Options.** Each one stated so that choosing between them is possible without reading the code.
>
> **Recommendation.** One, argued — a question with no recommendation is a question the front did not
> finish thinking about.
>
> **Blocks.** The step, front or landed work that waits on the answer.

Numbers are never reused: the next question added here is **28**, whatever has left the file since.

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

---

---

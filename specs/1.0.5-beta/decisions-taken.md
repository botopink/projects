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
| 16 | The `mod` path warning | fix the cause; do not exempt or document |
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

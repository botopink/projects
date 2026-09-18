# Decisions the maintainer owes — 1.0.5-beta

Twenty open questions the milestone cannot answer for itself. Each is stated with the evidence that
produced it, the options, a recommendation, and what it blocks. **The numbers are stable**: a question
that has been answered leaves this file for [`decisions-taken.md`](./decisions-taken.md) and its number
is not reused, so a front citing "decision 5" keeps citing the same thing. They were found by the fronts of
1.0.4-beta while implementing, not while planning: every "measured" line below was produced by a
command or by running a program, and the file or commit is named so it can be repeated.

| # | Question | Blocks | Recommended |
|---|---|---|---|
| [3](#3-the-import-surface-and-the-fence-that-documents-it) | Is `import { X };` (no `from`) a form at all? | front 20's defect A, every import example | one form only |
| [5](#5-what-a-value-is-on-the-js-backends) | What *is* a value on JS — object or prototype? | `is`, `case`, printing on JS | classes, as records already are |
| [6](#6-the-erlang-output-layout--with-the-two-trees-written-out) | `out/erl/<atom>.erl` flat, or nested? | 13's first half, `botopink run` | flat |
| [10](#10-code-is-taken-twice) | `@code(text)` and `#[@code]` share a name | 01's types-as-values step | rename the annotation |
| [11](#11-pattern-as-name) | Implement `<Pattern> as <name>` or delete its tests? | 01's parser-gap step | delete |
| [12](#12-unnamed-variant-payloads) | Keep unnamed variant payloads? | 01's parser-gap step | drop them |
| [13](#13-the-external-annotation-rows-that-never-had-a-step) | Where do `external-annotations.md`'s C1/C8 go? | STD-001 | into 01, explicitly |
| [14](#14-seven-forms-that-do-not-parse) | Should each of seven forms parse? | 01 and the grammar's tail | decide four, drop three |
| [15](#15-a-lower-case-externalnode--) | Is `#[@external(node, …)]` a located error? | a `reject/` cell with no owner | yes, and 01 owns it |
| [16](#16-the-not-reached-by-any-mod-path-warning) | What does `libs/std` do about the `mod` path warning? | a warning on every gate run | exempt what `files` declares |
| [17](#17-rakuns-erlang-story) | Port `runtime.mjs`, go node-only, or port half? | the last skipped library cell | port container and router |
| [18](#18-emilias-tokensbp-and-format---check) | Exempt the file, or fix the parser first? | `format --check` on four libraries | exempt, and say why in the file |
| [19](#19-the-comptime-renderers-id-field) | Keep `"id"` or remove it? | every `libs/std` edit re-recording | remove it |
| [20](#20-is-a-pattern-range-inclusive) | Does `1...9` include 9? | cells that work around the edge | yes — and say so in decision 8 |
| [21](#21-t1-or-t2-for-the-erlang-record) | Tagged map or tagged tuple for a record? | 13's third half | T1, the tagged map |
| [22](#22-wasm-has-no-identity-at-all) | Who designs wasm's boxed value? | `is` meaning one thing | 13, not 05 |
| [23](#23-does-a-behavior-need-an-atom) | Does `behavior` get a module atom? | A2's reserved `__b__` | reserve, do not emit |
| [24](#24-does-step-3-of-14-happen-at-all) | Is the goal build time, or the principle? | 14's scope | build time — stop at step 2 |
| [25](#25-does-is-carry-a-pattern) | `x is Some(v)`, or is `case` the only reader? | §4.2 | `case` only |
| [26](#26-case-arms-of-different-types-union-or-error) | Union, or an error? | two fixture slugs named for the answer | union |
| [27](#27-who-declares-behavior-display) | `behavior Display` does not exist | §7 on **four** backend fronts | 01 declares it |

---

## 3. The import surface, and the fence that documents it

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

## 5. What a value *is* on the JS backends

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

## 6. The erlang output layout — with the two trees written out

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

## 10. `@code` is taken twice

**Measured.** `@code(text)` is an existing builtin (a template body reads its own source through it);
the checker's types-as-values step proposes an **annotation** `#[@code]` for a different purpose. Two
things would answer to one name, in two syntactic positions.

**Options.** (a) Rename the proposed annotation. (b) Keep both and disambiguate by position.

**Recommendation: (a).** (b) asks every reader — and the language server's hover — to know which
`@code` they are looking at; the annotation has no users yet, so the rename is free today and never
again.

**Blocks:** `01-checker`'s types-as-values step.

---

## 11. `<Pattern> as <name>`

**Measured.** Three tests name the form (`Ok(v) as whole`); it has never parsed. Front 06's grammar
half landed decision 8's `case` arms without it, and decision 8 does not ask for it.

**Options.** (a) Implement it. (b) Delete the three tests and the row.

**Recommendation: (b).** Nothing in decision 8, `libs/std` or the five libraries writes it; a form
kept alive only by its own tests is a promise the language is not making.

**Blocks:** `01-checker`'s parser-gap step.

---

## 12. Unnamed variant payloads

**Measured.** The grammar allows a variant payload with no field name in some positions; decision 8
§5 names fields in every pattern it writes, and the parser front recommended dropping the form.

**Options.** (a) Keep them. (b) Drop them, with a located diagnostic naming the field form.

**Recommendation: (b)**, for the same reason as 11 — and a payload nobody can name is a payload no
`case` arm can bind.

**Blocks:** `01-checker`'s parser-gap step.

---

## 13. The external-annotation rows that never had a step

**Measured.** [`external-annotations.md`](../1.0.4-beta/06-checker/external-annotations.md)'s C1 and
C8 (STD-001) name front 06 as their owner, but 06's steps never listed them — they were carried
through the whole milestone without ever being scheduled.

**Options.** (a) Put them in `01-checker` explicitly, with steps. (b) Move them to the milestone
after this one.

**Recommendation: (a).** A row that names an owner and appears in no step is how work becomes
invisible; scheduling it is what makes (b) an honest choice later.

**Blocks:** STD-001.

---

## 14. Seven forms that do not parse

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

## 15. A lower-case `#[@external(node, …)]`

**Measured.** Only `External.<Target>` matches `FnDecl.isExternal`, so the lower-case spelling passes
`check`, binds no host, and says nothing. Front 17 wrote a `reject/` cell for it and listed it against
a row that does not exist.

**Options.** (a) A located error naming the capitalised form. (b) Accept both spellings.

**Recommendation: (a).** (b) means two spellings for a form that names a host symbol, and the failure
mode of getting it wrong is silence at run time. The decision needs an owner as much as an answer:
the annotation grammar is `01-checker`'s.

**Blocks:** a `reject/` cell that currently names nothing.

---

## 16. The `not reached by any mod path` warning

**Measured.** `libs/std` prints it on every gate run, for a module that the manifest's `files` list
declares but no `mod` path reaches.

**Options.** (a) Document it. (b) Exempt a module that `files` declares. (c) Add it to `root.bp`.

**Recommendation: (b).** The manifest is the consumer surface; a module listed there is reachable by
definition, and (c) would put a module in the build tree to silence a warning about the build tree.

**Blocks:** a warning the standard library prints at every gate run, which is how a real one gets
missed.

---

## 17. rakun's erlang story

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

## 18. emilia's `tokens.bp` and `format --check`

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

## 19. The comptime renderer's `id` field

**Measured.** 71 snapshots carry `"id": 0` across 65 files, and **no snapshot carries a non-zero id**.
The field is rendered and never varies.

**Options.** (a) Make it a real id. (b) Remove it.

**Recommendation: (b), and decide it before `01-checker` renames `buildRecordDeclName`.** A field that
is always zero is a field that every unrelated edit re-records; removing it after the rename means the
ids start matching by accident and the question never gets asked again.

**Blocks:** `06-comptime-dedup`'s third step.

---

## 20. Is a pattern range inclusive?

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

## 21. T1 or T2 for the erlang record

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

## 22. wasm has no identity at all

**Measured.** On wasm a record is a bump-allocated pointer, an enum a cell holding an ordinal, and a
unit variant **is the integer 0** — `Color.Red` is literally `i32.const 0`. Nothing there can answer
what type it is, and a record prints as a raw heap address.

**Options.** (a) `13-module-identity` designs the boxed value for all backends, wasm included.
(b) `05-wasm` designs its own while implementing decision 8.

**Recommendation: (a).** Under (b) `is Person` means one thing on three backends and another on wasm,
and the difference surfaces first in a user's program, not in a test.

**Blocks:** `05-wasm`'s decision-8 half.

---

## 23. Does a `behavior` need an atom?

**Measured.** A2 reserves the `__b__` qualifier for a `behavior`, and nothing in the front uses it: a
behavior emits no module today, and policy 3's module-per-declaration covers `type` and `implement`.

**Options.** (a) Reserve the spelling, emit nothing. (b) Emit a module per behavior too.

**Recommendation: (a).** Reserving costs one line in the decoder and keeps the door open; emitting
costs a module per behavior for a construct with no run-time representation.

**Blocks:** nothing today — decide it before the decoder is written, or it becomes a rename.

---

## 24. Does step 3 of `14-comptime-on-beam` happen at all?

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

## Carve-outs to grant

Three small grants the schedule needs. Each was verified cheap, and each belongs to a front that is
not the one asking:

| Grant | From | To | Verified |
|---|---|---|---|
| Two call sites in `infer.zig` — `decoratorEval.evaluate` (`:2341`) and `templateEval.evaluate` (`:3522`) | `01-checker` | `14-comptime-on-beam` | the lines were relocated at `c2dd780`; nothing else in the file moves |
| The evaluation-protocol half of `runtime/persistent_erl.zig` | `08-hygiene` | `14-comptime-on-beam` | no open hygiene step names the file; the group that touched it is delivered |
| The four module-atom sites in `erlang.zig` / `beam_asm.zig` (13's first half) | `02-erlang`, `03-beam` | `13-module-identity` | no emitted shape changes — a carve-out, not a stop |


---

## 25. Does `is` carry a pattern?

**Measured.** The parser refuses `x is Some(v)` with a located `is-variant-binding` diagnostic, while
decision 8 §4.2 lists the form. So the language currently says two things.

**Options.** (a) `is` carries a pattern and binds its payload. (b) The refusal stands and `case` is
the only construct that binds.

**Recommendation: (b).** `case` already binds payloads, with exhaustiveness behind it; `is` answering
a `bool` *and* binding a name makes a narrowing rule that has to explain what `v` is when the test is
false. Strike the form from §4.2 rather than implement two ways to destructure.

**Blocks:** `01-checker`'s step 3, and the `is` cells of `12-language-tests`.

---

## 26. `case` arms of different types: union, or error?

**Measured.** §3.2 says the arms' types union; two fixture slugs are already **named** for that answer
(`case_arms_with_different_types_string_i32_union`). And the migration cost is zero either way: all
**32** `case`-as-value blocks across the six libraries are homogeneous.

**Options.** (a) Union them, which step 2 of `01-checker` makes implementable. (b) An error.

**Recommendation: (a).** It is what §3.2 already says and what the fixtures are named for; (b) would
rename two slugs to assert the opposite of the document.

**Blocks:** `01-checker`'s step 2 and step 4.

---

## 27. Who declares `behavior Display`?

**Measured.** Decision 8 §7 says `libs/std` implements `Display` for `Dict`. `grep -rn 'behavior
Display' libs/std` returns **0**, and `Dict` implements nothing of the sort. The §7 acceptance of
**all four** backend fronts reads this.

**Options.** (a) `01-checker` declares it in `libs/std` as part of its step 11 (decision 8 in the
sources). (b) Each backend front assumes its own shape.

**Recommendation: (a).** (b) is how the same behavior ends up with four definitions; and step 11 is
already the step that puts decision 8 into `libs/std`.

**Blocks:** the §7 step of `02-erlang`, `03-beam`, `04-js` and `05-wasm` — four fronts reading one
missing declaration.

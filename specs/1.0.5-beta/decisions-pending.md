# Decisions the maintainer owes — 1.0.5-beta

Twenty-six open questions and one settled decision, all of which the milestone cannot answer for itself. Each one is stated with the evidence that
produced it, the options, a recommendation, and what it blocks. They were found by the fronts of
1.0.4-beta while implementing, not while planning: every "measured" line below was produced by a
command or by running a program, and the file or commit is named so it can be repeated.

| # | Question | Blocks | Recommended |
|---|---|---|---|
| [1](#1-asyncgeneratort-does-not-exist) | `@AsyncGenerator<T>` or `@AsyncIterator<T>`? | decision 8 §9 being true | rename the spec |
| [2](#2-optiont-does-not-exist-either) | Is `Option<T>` a spelling? | decision 8 §§2–5, 9 | `?T` stays the only one |
| [3](#3-the-import-fence-in-docsmd) | How does `docs.md`'s import example compile? | an unresolved `import` reding | make it a real project |
| [4](#4-the-order-that-dissolves-the-circular-dependency) | 14 → 13 → backends, or the named-type cut? | every backend front | adopt the order |
| [5](#5-a-commonjs-unit-variant-is-a-bare-string) | Tag a unit variant, or change the `.d.ts`? | `is`, `case`, printing on JS | tag it |
| [6](#6-the-erlang-output-layout) | `out/erl/<atom>.erl` flat, or nested? | 13's first half | flat |
| [7](#7-a-types-methods-are-function-not-method) | Who gives way, the LSP or the Test Explorer? | an outline that names methods | teach the extension |
| [8](#8-beam-as-a-target-of-the-language-suite) | Make `beam` executable for the suite? | 12's coverage on beam | not yet |
| [9](#9-arrayunique-is-broken-on-both-backends) | Who owns a `libs/std` body no backend lowers? | `Array.unique` | 01 + a `libs/std` edit |
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

## 1. `@AsyncGenerator<T>` does not exist

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

## 2. `Option<T>` does not exist either

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

## 3. The import fence in `docs.md`

**Measured.** Front 20 implemented "an unresolved `import` is a located error" — today
`import {area} from "geometry";` with no such module exits 0 from both `check` and `build` and emits
code. The fix is written and **cannot land**: it reds `docs.md:78`, whose fence names `geometry`,
`shapes.circle` and the `erika` dependency purely to illustrate the four import forms, and
`zig build test-docs` is gate stage 9.

**Options.** (a) Mark the fence `<!-- docs-check: skip … -->` with its reason. (b) Turn it into a
`project modules` cell — the sibling modules exist, only the library dependency line stays
illustrative and moves to its own skipped fence.

**Recommendation: (b).** The whole point of the docs gate is that no fence is vacuously green, and
this is the fence the docs front itself named as the worst offender. (a) keeps the compiler honest
and the documentation unverified, which is the trade the gate exists to refuse.

**Blocks:** front 20's defect A, implemented and stashed.

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

## 5. A commonJS unit variant is a bare string

**Measured.** `commonJS.zig:1563-1566` emits a unit variant as the string `"Dot"`, so `d is string`
would answer true — while the `.d.ts` the same compiler emits declares `{ tag: "Dot" }` for that
value. The `.js` and the `.d.ts` contradict each other, and **no snapshot covers it**.

**Options.** (a) Tag unit variants like every other variant. (b) Change the `.d.ts` to say `string`.

**Recommendation: (a).** `is`, `case` and per-type printing all need the tag, the `.d.ts` already
promises it, and (b) would make the JS backend the only one where a variant is not a variant.

**Blocks:** `04-js`'s decision-8 half; `13-module-identity`'s third half on the JS side.

---

## 6. The erlang output layout

**Measured.** `erlc` refuses a `-module` atom that does not match the file's basename, and
`+no_error_module_mismatch` produces a `.beam` the code server then refuses to load
(`beam_load.c(186)`). So the atom decides the file name, and an atom that encodes the source path
cannot coexist with today's mirrored `out/<path>.erl` tree.

**Options.** (a) `out/erl/<atom>.erl`, flat. (b) Keep a nested tree and accept that the leaf name is
the full atom anyway.

**Recommendation: (a).** Under policy 3 one `.bp` yields several modules; a nested tree then holds
directories whose names repeat inside every file name in them.

**Blocks:** `13-module-identity` step 0.

---

## 7. A type's methods are `Function`, not `Method`

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

## 8. `beam` as a target of the language suite

**Measured — and this corrects an earlier recommendation.** `botopink test` refuses the beam target
and `botopink run --target beam` writes `out/main.S` and stops, which is why `tests/language/AGENTS.md`
records beam as non-executable. Front 06's support pass then ran the rest of the path: `erlc +from_asm
main.S` produces `main.beam`, and `erl -noshell -pa . -eval 'main:main(), halt().'` prints the
program's output. **The artefact executes, with a tool the gate already runs** (the beam export audit
is stage 5). The recorded reason does not hold.

**Options.** (a) Teach the runner the two extra commands and add beam as a third executable target.
(b) Keep beam's coverage in the codegen snapshots.

**Recommendation: (a), scheduled after [`13-module-identity`](./13-module-identity/).** The blocker
was never execution, it was a missing two-line path — but 13's policy 3 changes how many `.S` files a
program emits and where they live, so building the runner against today's layout means writing it
twice. Add it as 13's landing step, not before.

**Blocks:** `12-language-tests`'s coverage claim for beam, and `tests/language/AGENTS.md`, which
states a reason that measurement contradicts.

---

## 9. `Array.unique` is broken on both backends

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

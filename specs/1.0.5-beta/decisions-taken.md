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

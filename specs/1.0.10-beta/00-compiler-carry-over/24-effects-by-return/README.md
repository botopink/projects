# Front 24 — effects by return type: `@Task`, `@Iterator` / `@Stream`, `async { }`, `iter` / `stream`

**Track:** compiler (carry-over item **C-32**)
**Priority:** critical — every effectful body in the compiler, std and the five libraries is written
against six annotations and a `@Future<T, E>` that can fail; decisions 118–128 replace both, with no
compatibility window (decision 127), so nothing effectful compiles against the new surface until
this front lands, and every library front's examples are written in the old one.
**Depends on:** decisions [118–128](../../decisions-taken.md#118-the-return-type-is-the-annotation)
(registered) · [`21-effect-chain`](../21-effect-chain/README.md) merged into `feat` or closed — which
one is the maintainer's call (Notes, open point 1) · [`22-loops`](../22-loops/README.md) (landed on
`feat`). Runs alone among the surface fronts: it rewrites the same files as 21, 22 and 23.
**Owns:** `libs/std/src/builtins.d.bp` (the effect behaviors) · `ast.zig`'s `EffectKind`, the new
`AsyncBlock` and `GenLoop` nodes · `comptime/effect_chain.zig` · `parser/decls.zig`'s annotation
handling (the six names parsed only to be refused) · `parser/exprs.zig`'s `async`, `iter`, `stream`
prefixes and the `try` / `await` arms · `comptime/infer.zig`'s effect legality, the `return` rule,
`await` typing, the iterator/factory scan, the loop's generator typing, the `use` gate
(`contextInfoFromReturn`, `FnContext.annotated` / `env.inContextFn`) · `comptime/diagnostics.zig`'s
effect codes · the effect lowering of `codegen/{commonJS,erlang,beam_asm,wat}.zig` and the name
mapping of `codegen/typescript.zig` · the `async` / `iter` / `stream` printer arms in `format.zig`
(a named carve-out of [`16-formatter`](../16-formatter/README.md)) · `modules/compiler-cli/src/cli/migrate.zig`
and its dispatch in `main.zig` (a named carve-out of `10-cli-residuals`) · `docs.md` § Loops,
§ use, § Effects, § Results, § Iterators, § Host bindings · `comptime/AGENTS.md`,
`codegen/AGENTS.md`, `parser/AGENTS.md`, `libs/std/AGENTS.md` · the `tests/language` effect, generator
and loop cells and every snapshot spelling an effect name · `scripts/known-red-libs.txt` during the
library sweeps · E7's rows in `libs/std/src/{async,http}.bp` · in the libraries: every effect
annotation and wrapper of jhonstart, rakun, emilia, onze and erika (E7, through the ledger) · in the
specs: the examples of the fronts listed under *Spec surface* (E8).
**Does not touch:** `lexer.zig` (the three new words are contextual, decided in the parser) · the
loop keywords, statements `void`, ranges and labels (22, landed) · `parseImportItem`,
`project_graph.zig`, `libs/std/src/**` beyond `builtins.d.bp`, `async.bp` and `http.bp`
([`23-std-purity`](../23-std-purity/README.md)) · `std/async`'s semantics on erlang (eager or
spawned — [`01-std/02-std-async-primitives`](../../01-std/02-std-async-primitives/README.md)) ·
`decisions-*.md` · the language server and `repository/vscode-extension` (highlighting the
contextual words is `11-tooling`'s, after this lands).

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/` unless a row says
otherwise. Counts and lines were measured 2026-09-25 at compiler `feat` `0beaa1f9` (the main
checkout) with `grep -rEo` over `compiler-core/src`, `libs`, `tests`, `compiler-core/snapshots`,
`docs.md` and the sibling repositories.

The language this front lands is written out in full in [`guide.md`](./guide.md) — the
maintainer's guide, in English, which step E8 turns into `docs.md`. The decisions are the contract;
the guide is the prose and the examples.

---

## Problem

The effect of a function is said twice: once as an annotation (`#[@future]`) and once as the return
wrapper (`-> @Future<T, E>`), with R1/R2 refusing any disagreement between the two and R5 forbidding
a second annotation. And the chain says every effect can fail — `@Future<T, E = any>` extends
`@Result` (`libs/std/src/builtins.d.bp:140`), so `await x` propagates the error, every hook may
`throw` and a `for` over a fallible generator is an implicit `try` that needs the level of the body
that iterates. Decisions 118–128 change all of it:

| Today | After |
|---|---|
| `#[@X]` annotation + `@X` wrapper in the return | the wrapper in the return only (118) |
| `@Future<T, E>` (may fail) | `@Task<T>` (never fails); failure is `@Task<@Result<T, E>>` (120) |
| `await x` propagates the error | `await x` answers the `@Result`; `try await x` propagates (120) |
| `@Use` ⊃ `@Future` ⊃ `@Result` (every hook may `throw`) | `@Component` ⊃ `@Task`; `throw` / `try` only when `T` is a `@Result` (121) |
| `@Use<C, T>` (hook) and `@Component<T>` ≡ `@Use<B, T>` (component) | one wrapper, `@Component<C, T>`, for both (128) |
| `@Generator<T>` | `@Iterator<T>` (122) |
| `@ResultGenerator<T, E>` | `@Iterator<@Result<T, E>>` (122) |
| `@FutureGenerator<T, E>` | `@Stream<@Result<T, E>>` (or `@Stream<T>`) (122) |
| `YieldStep<T, E = void>` with `Error` | `YieldStep<T>` = `{ Yield, Done }` (122) |
| `for` over a fallible generator does an implicit `try` | `for` hands over the `@Result`; the `try` is explicit (122) |
| `#[@generator] loop` (`loop` only) | `iter loop` / `iter while` / `iter for` (125) |
| `#[@futureGenerator] loop` | `stream loop` / `stream while` / `stream for` (125) |
| — | `async { … }` → `@Task<T>` (124) |

The idea that ties it together: **only `@Result` fails.** The other wrappers never fail and carry a
`@Result` in the value when they need one; `throw` and `try` are legal wherever a layer of the
return is a `@Result`.

## Current state

**The compiler at `feat` `0beaa1f9`** still carries the pre-102 names, because front 21 has not
merged:

| What | Where |
|---|---|
| `EffectKind` — `result`, `future`, `generator`, `iterator`, `futureGenerator`, `context`; `all`, `annotationName`, `returnWrapper`, `fromAnnotationName` | `ast.zig:2237-2280` |
| the chain: `clauses`, `yielding_wrappers`, `grants`, `grantingEffects`, `refusal`, the drift tests against `builtins.d.bp` | `comptime/effect_chain.zig:40`, `:51`, `:106`, `:120`, `:133`, `:180-272` |
| the annotation → effect read, R5 (`effect-duplicate-annotation`) | `parser/decls.zig:477`, `:487`, `:573` (`effectFromAnnotations`), `:596` (`firstDuplicateEffect`); the annotated loop at `parser/exprs.zig:2009` |
| `try` / `try … catch` and `await` parsing — `try`'s operand is a full `parseExpr`, so `try await x` is already `try (await x)` | `parser/exprs.zig:122`, `:137` |
| R1–R4 (annotation ↔ wrapper, `effect-wrapper-mismatch`, `effect-missing-wrapper`) and `effect-missing-annotation` (a plain `fn` returning an async wrapper is refused — the rule 118 inverts) | `comptime/infer.zig:3600-3650` |
| `contextInfoFromReturn`; `env.inContextFn = eff == .context` | `comptime/infer.zig:1146`, `:3693`; `FnContext.annotated` at `comptime/env.zig:150`, `inContextFn` at `:520` |
| the legality checks: `throw` context from the effect, `yield` / `await` per fn, `try` refusal, `await` refusal (`effect-await-without-future`), `yield` refusal, the `for`-over-generator level gate (`for-over-fallible-generator`) | `comptime/infer.zig:3869`, `:4001-4003`, `:8280`, `:8359`, `:8399`, `:8640-8663` |
| the effect codes | `comptime/diagnostics.zig:31-89`, `:177`, `:208` |
| `Result<R, E>`, `Iterator<T, E, C>`, `IteratorStep`, `Iterable`, `Yield<T, R>`, `Generator<T, R>`, `Future<T, E = any> extends Result`, `FutureGenerator<T, E, C>`, `Context<ContextBase, Return>` | `libs/std/src/builtins.d.bp:24`, `:95`, `:99`, `:123`, `:129`, `:134`, `:140`, `:157`, `:211` |
| the loop node: `LoopExprOf` with `keyword` and `generator: ?EffectKind` (the `#[@X] loop` of decision 105) | `ast.zig:661-672` |
| commonJS: `effectShape` (`future` → `async function`, generators → `function*`, `futureGenerator` → `async function*`), `contextShape` (a context body is `async` only when it awaits) | `codegen/commonJS.zig:1788`, `:1827` |
| TypeScript and wat name mappings (`Future` → `Promise`, `Iterator` → `IterableIterator`, `FutureGenerator` → `AsyncGenerator`) | `codegen/typescript.zig:413`, `codegen/wat.zig:5247`, `:6235` |
| `await`, `use`, `yield`, `for`, `while` are lexer keywords; `async`, `iter`, `stream` are not | `lexer.zig:748`, `:775`, `:784`, `:756`, `:778` |
| `botopink migrate` exists — it derives the module tree (`pub mod X;`), takes only `--dry-run`, and has no subcommand | `modules/compiler-cli/src/cli/migrate.zig:1`, `main.zig:166` |
| no `Task` or `Stream` type in `libs/std/src/*.bp`; `std/async` is written over `@Future<T>` thunks | `libs/std/src/async.bp:90-236` |

**Front 21 has landed on its branch, not on `feat`.** `.tasks/21-effect-chain`
(`front/21-effect-chain`) carries its four steps: the three generators over
`YieldStep<T, E = void>` (`.iterator` → `.resultGenerator`, `@Generator<T>` infallible,
`@FutureGenerator<T, E>` without `C`), `#[@use]` with `@Use<C, T>` / `@Component<T>` and
`@Context<Base>` as the owner marker (`EffectKind.use` with a set-valued `returnWrapper`,
`effect_chain.zig` clauses `Use ⊃ Future`, `Component ⊃ Use`, one flag
`inContextFn == annotated`, commonJS `async function` for every `#[@use]` body), `getContext`, and
the jhonstart sweep. **Front 22 has landed on `feat`**: `for` / `while` / `loop { }`, statements
`void`, `#[@generator] loop` as a generator on four backends (commonJS `function*` IIFE; erlang items
under a `make_ref()` key in the process dictionary; beam a y-slot accumulator; wasm an array in
`(block $__gen<n>)`), `a...b`, and the `generator-loop-closed-scope` refusal.

**What is reused, per the migration plan (§ 1).** From 21 and 22, independent of the syntax:
the `use` ⊃ `await` check; the one-base check of `use` (`validateUseBase`, `comptime/infer.zig:10002`);
`@Context<Base>` as the owner marker and the two context wrappers, merged into `@Component<C, T>`
(decision 128); one flag for the `use` gate; commonJS `async function` for every `use` body; the generator scopes and the nearest-scope
rule; `yield :label`; `break v` as an item; the refusal of `break :outer` across a closed border;
the four backends' lowering of an annotated loop (re-keyed from `generator: ?EffectKind` to
`GenLoop.kind`). **What stops:** renaming towards `@ResultGenerator`, `@FutureGenerator` and the
`#[@resultGenerator]` / `#[@futureGenerator]` / `#[@use]` annotations; `@Use` and the
`@Component<T>` ≡ `@Use<B, T>` sugar (one wrapper, 128); treating `@Future` as part of
the failure chain (`@Future ⊃ @Result`). 21's and 22's cells move to § *Cells* below, re-spelled.

**Blast radius of the old spellings** (matches, `feat` `0beaa1f9`; 21's branch has already moved
`#[@iterator]` / `#[@context]` to their decision-103/102 names):

| Spelling | src | libs | tests | snaps | `docs.md` | jhonstart | rakun | emilia |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `#[@result]` | 183 | 91 | 19 | 369 | 8 | 0 | 17 | 0 |
| `#[@future]` | 143 | 19 | 39 | 149 | 10 | 73 | 37 | 12 |
| `#[@context]` / `#[@use]` | 110 | 1 | 58 | 55 | 20 | 72 | 0 | 0 |
| `#[@generator]` / `#[@iterator]` / `#[@resultGenerator]` | 149 | 6 | 37 | 79 | 18 | 0 | 0 | 0 |
| `#[@futureGenerator]` | 48 | 3 | 6 | 108 | 5 | 0 | 0 | 0 |
| `@Future<` | 99 | 37 | 24 | 61 | 11 | 69 | 51 | 17 |
| `@Generator<` / `@Iterator<` / `@ResultGenerator<` | 92 | 4 | 22 | 70 | 8 | 0 | 0 | 0 |
| `@FutureGenerator<` | 20 | 1 | 2 | 28 | 1 | 0 | 0 | 0 |
| `#[@X] loop` / `while` / `for` | 41 | 0 | 15 | 9 | 6 | 0 | 0 | 0 |
| `await` (each a `try await` candidate) | 142 | 49 | 36 | 43 | 13 | 44 | 50 | 242 |

onze (recreated) and erika carry none of the annotations at this pin.

**Spec surface.** The library fronts' READMEs and examples are written in the pre-118 model (`grep
-rEo` over `specs/1.0.10-beta`, matches of the six annotations, `#[@context]`, `#[@iterator]`,
`@Future<`, `@ResultGenerator`, `@FutureGenerator`, `@Generator<`; no library front writes a
`#[@X] loop`). Each front's README says so in its *Current state*; E8 rewrites them with the codemod:

| Track | Fronts (matches) | Track files |
|---|---|---|
| `01-std` | 01-std-lib-enablement (11) · 02-std-async-primitives (46) · 05-actions-lib (2) · `examples/` (8) | `README.md`, `asserts-api.md`, `snapshots.md`, `src-builtin.md`, `test-snap.md` |
| `02-packaging` | the README (2) | — |
| `03-rakun` | 04 (2) · 07 (9) · 08 (3) · 11 (1) · 12 (5) · 13 (12) · 14 (1) · 15 (1) · 16 (1) · 22 (4) · 23 (17) · 24 (17) · 25 (34) · 60 (7) · 62 (7) · 63 (10) · 65 (2) · 66 (9) · 77 (1) · 79 (2) · 86 (1) · 92 (15) · 93 (3) | `test-snap.md` (72), `test-snap-examples.md` (22), `unification.md` |
| `04-jhonstart` | 26 (19) · 27 (5) · 28 (47) · 29 (9) · 30 (42) · 31 (15) · 32 (15) · 67 (13) | `README.md` § 6 (9), `modules.md`, `test-snap.md` (23), `test-snap-examples.md`, `unification.md` |
| `05-emilia` | 33–42 · 44–47 (6 each) · 43 (4) · 48 (8) · 56 (7) | `modules.md`, `test-snap-examples.md` |
| `06-onze` | 49 (7) · 50 (5) · 51 (5) · 52 (15) · 53 (54) · 68 (2) · 69 (4) · 70 (8) · 71 (8) | `modules.md`, `test-snap.md` (11), `test-snap-examples.md` (10) |
| milestone | — | `contracts.md` (12), `language-gaps.md` (7), `overview.md` (the page-signal rule) |
| `00` | 01-checker, 02-erlang, 13-module-identity, 15-language-surface, 19-use-activation, 20-builtins-surface, 21-effect-chain, 22-loops | their cells are re-specified here (§ *Cells*) |

## Mechanism

**The effect is read from the syntactic return.** At the declaration, the checker looks at the
return type *as written*: if it is one of `@Result`, `@Task`, `@Component`, `@Iterator`,
`@Stream`, the body enters that level. An alias is resolved to type the function, never to activate
(`effect-wrapper-behind-alias`). `EffectKind` stays the one list, keyed by wrapper instead of
annotation — one value per wrapper family (`result`, `task`, `component`,
`iterator`, `stream` is the natural cut; E1/E3 settle it).

**Two independent answers from the return.** The *level* (`use` / `await` / `yield`, from the
outermost wrapper and the chain `@Component ⊃ @Task`, `@Stream ⊃ @Task`, `@Iterator`) and the
*fallible channel* (is there a `@Result` in any layer?). `throw` / `try` read only the second;
`effect_chain.zig`'s `grants(eff, .try_)` becomes a function of the return, not of the level.

**`builtins.d.bp` at the end of E1:**

```botopink
pub behavior Context<Base> { }

pub type Result<R, E> { … }                              // unchanged; the one fallible wrapper
pub behavior Task<T>                                    { fn map<R>(self: Self, f: fn(value: T) -> R) -> Task<R>; … }
pub behavior Component<C, T> extends Task               { }

pub type YieldStep<T> { Yield(value: T), Done }
pub behavior Iterator<T>                                { fn next(self: Self) -> YieldStep<T>; }
pub behavior Stream<T> extends Task                     { fn next(self: Self) -> Task<YieldStep<T>>; }
```

The exact method set of `Task` ("`.map`, `.then` and the like, without an error parameter") is E1's
to write and the maintainer's to confirm (Notes, open point 4). `Future`, `Generator`,
`ResultGenerator`, `FutureGenerator`, `Iterator<T, E, C>`, `IteratorStep`, `Iterable`, `Yield<T, R>`
and `Context<B, R>` are gone, not aliased (decision 127).

**Backends** (the plan's table, E5):

| Construct | commonJS | erlang / beam / wasm |
|---|---|---|
| `@Result` return | as today | as today |
| `@Task` / `@Component` return | `async function` (104 kept) | eager Task, `await` = identity |
| `throw` in `@Task<@Result<…>>` | `return {Error: e}` — does **not** reject the Promise | answers `Error(e)` |
| `async { }` | `(async () => { … })()` | runs the block in place |
| `@Iterator` with `yield` | `function*` | today's `@Generator` representation, renamed |
| `@Stream` with `yield` | `async function*` | today's `@FutureGenerator` representation, renamed |
| factory (`@Iterator` / `@Stream` with no `yield`) | plain function | plain function |
| `iter …` | `(function* () { … })()` | the function's lowering, inline |
| `stream …` | `(async function* () { … })()` | the function's lowering, inline |
| failing `throw` / `try` on a `@Result` item | `yield {Error: e}; return;` | emit `Error(e)` and end |
| `@External` → `@Task<@Result<…>>` | `try { await p } catch (e) { return {Error: …} }` | `{error, R}` → `Error(R)` |
| `@External` → `@Task<T>` | `await p`; a rejection is a fatal failure | as today |

commonJS generators cannot be arrow functions, so `this` and captured variables need the treatment
ordinary closures get. A Promise that resolves with `Error` instead of rejecting changes what JS
code consuming botopink receives: the changelog says so, and an interop helper (`unwrapOrThrow`) is
offered if the maintainer wants one (Notes, open point 6).

## Steps

Each step leaves the compiler working, with the cells of the steps before it green. The order is
the plan's; the merge order is § *Merge order*.

### Step E1 — the prelude types

`@Future<T, E>` → `@Task<T>`, with `.map`, `.then` and the like carrying no error parameter;
`@Generator` → `@Iterator`; `@Stream<T>` created; `@ResultGenerator` and `@FutureGenerator` removed;
`YieldStep<T, E = void>` → `YieldStep<T>` without `Error`. `effect_chain.zig`'s clauses become
`Component ⊃ Task`, `Stream ⊃ Task`; `yielding_wrappers` = `{Iterator, Stream}`; the
drift test reads the new file both ways. Before renaming, check that std does not already use
`Stream` or `Task` for something else (a byte stream, a job queue) — measured on `0beaa1f9`: it does
not; re-measure at the step's base, and rename the std side first if it now does.

**Acceptance:**
- [x] `builtins.d.bp` is the shape under *Mechanism*; `grep -rnE 'Future|Generator|IteratorStep|Iterable|Yield<|Use<' libs/std/src/builtins.d.bp` finds nothing
- [x] the prelude compiles on all backends (commonJS, erlang, beam, wasm) and no old symbol is exported
- [x] the `effect_chain.zig` drift test green with the new clauses; `comptime/AGENTS.md` and `libs/std/AGENTS.md` in the same commit

### Step E2 — the parser

`async` before `{` → an `AsyncBlock` node; `iter` / `stream` before `loop` / `while` / `for` /
`for await` → `GenLoop { kind, loop }` in expression position (replacing `LoopExpr.generator`); the
three words are contextual — outside those positions they stay identifiers; `try await x` is
`try (await x)` (already so, `parser/exprs.zig:122` — pin it with a test); the six annotations
`#[@result]`, `#[@future]`, `#[@use]`, `#[@generator]`, `#[@resultGenerator]`, `#[@futureGenerator]`
are recognised only to raise `effect-annotation-removed` with a fix-it pointing at the span (on a
`loop`: `iter` / `stream`); `@Future`, `@Generator`, `@ResultGenerator`, `@FutureGenerator`, `@Use` in a
type raise `effect-type-removed`, and `@Iterator<T, E>` `iterator-error-param-removed`. The `format.zig`
arms print the three prefixes back.

**Acceptance:**
- [ ] every new form in [`guide.md`](./guide.md) parses, each with a `parser/tests/` case and an `assertLossless` round-trip
- [x] every old form raises the right code with the fix-it located on the annotation / type argument — `reject/` cells per row of the diagnostics table below
- [ ] `g.iter()`, `val stream = 1`, `http.stream(…)`, `import {async} from "std"` and `async.allOf(…)` parse as identifiers (`test/contextual_words.bp`)
- [x] `src/parser/AGENTS.md`, `src/format/AGENTS.md` in the same commit

### Step E3 — types and effects

1. **Effect mode from the return** (118): the syntactic return decides the level; an alias types but
   does not activate (`effect-wrapper-behind-alias`); R1–R5, `effect-missing-annotation` and
   `effect-duplicate-annotation` go (a function has one return).
2. **The fallible channel apart from the chain** (121): level and "a `@Result` in some layer" are
   computed separately; `throw` / `try` read the second only.
3. **`return`** (119): wrapping through every layer, pass-through, `effect-return-ambiguous-nesting`.
4. **`await`** (120): types `@Task<X>` → `X` and propagates nothing; `effect-await-without-task`
   where there is no await channel.
5. **Iterator or factory** (123): scan the body for the function's own `yield` / `break v` (not into
   closures, not into inner `iter` / `stream` loops); `iter-mixed-yield-return`.
6. **The inferred `@Result` value / item** in `async { }`, `iter` and `stream` from `throw` / `try`,
   unifying `E`; `gen-infer-conflicting-errors` when it does not unify.
7. **Closure of `async { }` and of `iter` / `stream` loops**: the body starts a new capability
   context, like a closure; `return` inside `async { }` types against the block.
8. **Delete the old rule** "iterating a fallible generator needs an error channel"
   (`for-over-fallible-generator`, `comptime/infer.zig:8640-8663`): `for` over any `@Iterator` is
   legal in any function.
9. **The hint on the type error** when a `@Result` is used as `U`: from an `await`, suggest
   `try await`; from a `for` item, suggest `try r`; for an inferred value, point also at the `try` /
   `throw` that made it a `@Result` — the most common error of the migration.

**Acceptance:**
- [ ] every ✗ in [`guide.md`](./guide.md) answers exactly the code of the diagnostics table below, and every example without ✗ types
- [ ] the *Return and effect mode*, *`@Task` and failure*, *Chain and `use`*, *`async { }`*, *Iterators* (type half) and *Prefixed loops* cells green on four targets
- [x] the hint of item 9 in a `reject/` cell's `.expect` for each of the three sources
- [x] `comptime/AGENTS.md` in the same commit

### Step E4 — consumption (`for` / `for await`)

`for` over `@Iterator<X>` hands over `X` (a `@Result` when `X` is one); the implicit `try` that
existed for `@ResultGenerator` is removed; `for await` requires an await channel — a `@Task` /
`@Component` return, an `async { }` block or a `stream`.

**Acceptance:**
- [x] `for` with `try r` propagates, `for` with `case` continues (`run/iterator_result_items.bp`)
- [x] `for await` without an await channel is `effect-await-without-task` (`reject/for_await_without_task.bp`)

### Step E5 — the backends

The table under *Mechanism*, on commonJS, erlang, beam and wasm. `effectShape` / `contextShape`
(`codegen/commonJS.zig:1788`, `:1827`) key on the return; the annotated-loop lowerings of 22 are
re-keyed to `GenLoop`; the host rows of decision 126. TypeScript: `@Task` → `Promise`, `@Iterator` →
`IterableIterator`, `@Stream` → `AsyncGenerator`.

**Acceptance:**
- [ ] the *Iterators*, *Streams*, *Host* and *`@Task` and failure* run cells green on four targets by running, no `expected-failures.txt` line
- [x] JS: a `throw` in `@Task<@Result<…>>` resolves the Promise with `Error`, never rejects (`run/task_throw_resolves_error.bp`, node)
- [x] every re-recorded snapshot classified: rename, `async function` where a body did not await, a RUN LOG changed by running
- [ ] `CHANGELOG.md` entry for the JS interop change; `codegen/AGENTS.md` in the same commit

### Step E6 — the codemod `botopink migrate effects`

§ *Codemod* below. It runs first on the internal libraries (E7) to validate itself.

**Acceptance:**
- [ ] a snapshot of the codemod over one file holding every automatic pattern of § *Codemod* (`snapshots/cli/migrate_effects_all_patterns.snap.md` or wherever E6 puts CLI snapshots)
- [ ] a second snapshot over the review patterns, each carrying `// TODO(migrate-effects)`
- [ ] idempotent: a second run changes nothing; `--dry-run` reports without writing
- [ ] `modules/compiler-cli/src/cli/AGENTS.md` in the same commit

### Step E7 — the libraries

- `std/async`: the signatures with `@Task` —
  `allOf(Array<@Task<@Result<T, E>>>) -> @Task<@Result<Array<T>, E>>` (stops at the first error),
  `allOf(Array<@Task<T>>) -> @Task<Array<T>>`, and `timeout` answering
  `@Task<@Result<T, TimeoutError>>` (or joining the Task's `E`); whether `allSettled` stays is
  decided here (Notes, open point 3);
- `std/http` and the other I/O modules: `@Task<@Result<…>>` returns;
- `jhonstart`: hooks (`state`, `cookies`, …), components, `#[page]` / `#[layout]` / `#[template]`;
  components that used `try` / `throw` to propagate now handle with `catch` / `case` /
  `notFound()`;
- `rakun`: request hooks, server actions (`@Task<@Result<ActionResult, E>>`);
- `onze` and the bundled libraries (`routing`, `actions`, `validation`);
- the generated page code is still an `async function` on commonJS.

Each library lands through `scripts/known-red-libs.txt` as 21 step 4 and 22 step 4: the compiler
commit with the library in the ledger, the library sweep, the ledger line deleted in the next
compiler commit.

**Acceptance:**
- [x] `std/async` and `std/http` signatures closed and green **before** the codemod runs on the libraries (§ *Merge order*, 5)
- [ ] `zig build test-libs` green on every row at its pre-sweep counts; `known-red-libs.txt` back to its header
- [ ] `grep -rnE '#\[@(result|future|use|generator|resultGenerator|futureGenerator)\]|@(Future|Use)<|@(Result|Future)?Generator<' repository/{jhonstart,rakun,emilia,onze,erika} libs/` finds nothing
- [ ] the meta submodule pointers bumped in the same sweep

### Step E8 — documentation

`docs.md` § Effects, § Results, § Iterators, § use, § Loops and § Host bindings replaced by
[`guide.md`](./guide.md)'s text; the spec examples and the library READMEs updated (the *Spec
surface* table — each front's *Current state* line is deleted as its examples are rewritten); the
new codes added to the diagnostics reference (`comptime/diagnostics.zig`'s table and
`comptime/AGENTS.md`); the 1.0.10-beta changelog.

**Acceptance:**
- [ ] `scripts/check-docs.sh` green; every `docs.md` fence compiles
- [ ] `grep -rnE '#\[@(result|future|use|generator|resultGenerator|futureGenerator)\]|@(Future|Use)<|@ResultGenerator|@FutureGenerator' specs/1.0.10-beta --include=*.md --include=*.bp` finds only `decisions-taken.md` (the record)
- [ ] no front README keeps the "pre-118 effect annotations" line

## Diagnostics

Names marked \* are new; the others exist and only change their text.

| Code | When | Fix-it |
|---|---|---|
| `effect-try-without-fallible-channel` | `throw` / `try` with no `@Result` in any layer of the return | use `try … catch`, or put `@Result` in the return |
| `effect-await-without-task` \* | `await` without an await channel (today's `effect-await-without-future`, renamed) | change the return to `@Task`, or use `async { }` |
| `use-without-context-effect` | `use` without a `@Component` return | change the return |
| `effect-wrapper-behind-alias` \* | a capability used under an aliased return | write the wrapper literally |
| `effect-return-ambiguous-nesting` \* | a `return` that fits two layers | explicit `Ok(…)` |
| `iter-await` \* | `await` in an `@Iterator` or an `iter …` loop | use `@Stream` / `stream …` |
| `iter-mixed-yield-return` \* | `yield` and `return <iterator>` in one body | pick one |
| `gen-infer-conflicting-errors` \* | two `E`s in the body of `async { }` / `iter` / `stream` | annotate the `val` |
| `effect-annotation-removed` \* | `#[@result]`, `#[@future]`, `#[@use]`, `#[@generator]`, `#[@resultGenerator]`, `#[@futureGenerator]` | remove the annotation (on a loop: `iter` / `stream`) |
| `effect-type-removed` \* | `@Future`, `@Generator`, `@ResultGenerator`, `@FutureGenerator`, `@Use` | the new name (`@Use<C, T>` → `@Component<C, T>`) |
| `iterator-error-param-removed` \* | `@Iterator<T, E>` | `@Iterator<@Result<T, E>>` |

Codes that exist today and that the plan's table does not name — `effect-throw-without-fallible-channel`,
`effect-missing-annotation`, `effect-duplicate-annotation`, `effect-missing-wrapper`,
`effect-wrapper-mismatch`, `for-over-fallible-generator`, `yield-without-generator`,
`generator-loop-closed-scope` — are listed in Notes, open point 2.

## Cells

Each line is a compile cell (✓ types / ✗ the expected code) in `tests/language/{test,reject}/` and,
where it runs, a `run/` cell on the four targets; the codegen snapshots of the run cells are
re-recorded under `snapshots/codegen/{beam,wat}/<target>/` (decision 85). 21's and 22's effect,
generator and loop cells are re-spelled into these.

**Return and effect mode**
- [ ] ✓ `@Result` with `throw`, `try`, `return T`, `return @Result`
- [ ] ✓ `@Task<@Result<U, E>>`: `return U`, `return @Result`, `return @Task<…>` (three layers)
- [ ] ✗ `effect-return-ambiguous-nesting` with `@Result<@Result<…>>`
- [ ] ✗ `effect-wrapper-behind-alias`
- [ ] ✓ an alias on a function **without** capabilities (it only passes a value along)

**`@Task` and failure**
- [ ] ✓ `@Task<T>` with `await` and no `try`
- [ ] ✗ `throw` in `@Task<i32>`
- [ ] ✓ `await t` answers the `@Result`; `try await t` propagates; `try await t catch x`
- [ ] ✗ `try await` in a `@Task<i32>` function (no `@Result`)
- [ ] ✓ JS run: a `throw` in `@Task<@Result<…>>` resolves the Promise with `Error`, does not reject

**Chain and `use`**
- [ ] ✓ `@Component<C, T>` with `use` + `await`, as a hook (any `T`) and as a component (`T: @Context<C>`)
- [ ] ✓ `@Component<C, @Result<T, E>>` with `try await`
- [ ] ✗ `try` in `@Component<ElementBase, Element>`
- [ ] ✗ `await` under `@Result`; `use` under `@Task`; two bases in one `@Component`; `use` of a component (its `T` owns the context)

**`async { }`**
- [ ] ✓ in a plain function, passed to `async.allOf`
- [ ] ✓ without `throw` / `try` → `@Task<T>`; with → `@Task<@Result<U, E>>`
- [ ] ✓ `return` leaves the block, not the function
- [ ] ✗ `use` inside `async { }` in a `@Component` function (closure)
- [ ] ✗ `gen-infer-conflicting-errors`

**Iterators**
- [ ] ✓ `fibonacci`, `firstNegative` (run: the exact sequence)
- [ ] ✓ `@Result` item: `yield try`, `throw` → the last item is `Error`, then `Done`
- [ ] ✓ `for` with `try r` propagates; `for` with `case` continues
- [ ] ✓ factory (`return iter for …`) vs iterator
- [ ] ✗ `throw` with an item that is not a `@Result`; `iter-await`; `iter-mixed-yield-return`; `iterator-error-param-removed`

**Streams**
- [ ] ✓ `pages` + `for await` (run with a simulated http, including a failure in the middle)
- [ ] ✓ `stream loop` with no failure → `@Stream<T>`
- [ ] ✗ `for await` without an await channel

**Prefixed loops**
- [ ] ✓ `iter loop` / `iter while` / `iter for` as a `val` and as an argument
- [ ] ✓ `break v` in the prefixed loop ends the sequence
- [ ] ✓ `yield` in an inner `for` feeds the outer `iter`; `yield :label`
- [ ] ✗ `break :outer` crossing the border
- [ ] ✓ `g.iter()`, `val stream = 1`, `http.stream(…)`, `async.allOf(…)` stay identifiers

**Host**
- [ ] ✓ `@External.Node` with `-> @Task<@Result<T, string>>`: a rejected Promise becomes `Error`
- [ ] ✓ `@External.Erlang` with `{error, R}` becomes `Error(R)`

**Migration**
- [ ] ✗ each old annotation gives `effect-annotation-removed` with the right fix-it
- [ ] ✗ `@Future<…>` gives `effect-type-removed` suggesting `@Task<@Result<…>>`
- [ ] ✗ `@Use<C, T>` gives `effect-type-removed` suggesting `@Component<C, T>`; `@Component<T>` (one argument) is a type-arity error
- [ ] the codemod snapshot over a file with every pattern of § *Codemod* (E6)

## Codemod

`botopink migrate effects`. **Automatic (no review):**

| Pattern | Rewrite |
|---|---|
| `#[@result]` / `#[@future]` / `#[@use]` / `#[@generator]` / `#[@resultGenerator]` / `#[@futureGenerator]` on a function | remove the line / the attribute item |
| `@Future<T, E>` | `@Task<@Result<T, E>>` |
| `@Future<T>` | `@Task<T>` |
| `await x` where `x: @Future<U, E>`, the use expects `U`, in a function with `@Result` in the return | `try await x` |
| `@Generator<T>` | `@Iterator<T>` |
| `@ResultGenerator<T, E>` and `@Iterator<T, E>` | `@Iterator<@Result<T, E>>` |
| `@FutureGenerator<T, E>` | `@Stream<@Result<T, E>>` |
| `#[@generator] loop { … }` / `#[@resultGenerator] loop { … }` | `iter loop { … }` |
| `#[@futureGenerator] loop { … }` | `stream loop { … }` |
| `#[@X] loop { for (xs) { … }; break; }` | `iter for (xs) { … }` (when the `for` is the only statement before the `break`) |
| `YieldStep<T, E>` | `YieldStep<T>` |
| `@Use<C, T>` | `@Component<C, T>` |
| `@Component<T>` | `@Component<B, T>`, `B` read from `T implement @Context<B>` (the checker's types, like `try await`) |

**Needs review (marked `// TODO(migrate-effects)`):**
- `await` in a hook or component whose `T` is not a `@Result` (e.g. `@Component<ElementBase, Element>`): the
  error used to propagate and now has nowhere to go; the codemod does not choose between `catch`,
  `case` and `notFound()`;
- `throw` in a hook / component whose `T` is not a `@Result`: decide whether the hook returns a
  `@Result` or the error is handled there;
- `for` over what was a `@ResultGenerator`: the implicit `try` is gone. The codemod inserts `try x`
  at the first use of the loop variable when the function has a `@Result` in its return; otherwise it
  marks;
- `for await` over what was a `@FutureGenerator`: likewise;
- `case` over `YieldStep` with an `.Error` arm;
- functions that called `.next()` by hand on a generator and handled `Error`;
- wrapper aliases used as the return of an effect function;
- JS code consuming botopink functions that expected a rejected Promise.

Run it on the internal libraries first (E7), to validate it. The `await` → `try await` rewrite is
reliable only where the function's return is known, which is why it needs the checker's types, not
a text pass.

## Merge order

1. Decisions 118–128 approved and registered (done: `decisions-taken.md`)
2. E1 + E2 (prelude and parser, with the old-syntax errors)
3. E3 + E4 (checking and consumption), with the § *Cells* suite
4. E5 (backends), with the run and interop cells
5. E7, part: close the `std/async` and `std/http` signatures
6. E6 + E7 (the codemod applied to the libraries; libraries green on every target)
7. E8 (guide and diagnostics reference) and the 1.0.10-beta changelog

## Gate

- [ ] `scripts/gate.sh --cold` green at every commit; `test-libs` at baseline (a library through the ledger only during its sweep)
- [ ] `zig build test-language` green on the four targets with § *Cells*; every re-recorded RUN LOG verified by running
- [ ] the `effect_chain.zig` drift test green with `builtins.d.bp` at its final shape
- [ ] `AGENTS.md` of every directory touched, in the same commit as each change
- [ ] Commit on `front/24-effects-by-return`; no push, no merge — landing is the maintainer's step

## Risks and open points

- **`await` → `try await` en masse.** The most visible change: almost every `await` in I/O code gains
  a `try` (the table under *Current state* counts the candidates). The type-error hint (E3.9) and the
  codemod have to be good, or the migration becomes a run of type errors far from their cause.
- **Components lose propagation.** jhonstart code that let an error rise out of a page has to decide
  what to show. Worth considering, in the library (not the compiler), a helper like `orNotFound(r)`
  or an error boundary per layout.
- **JS interop.** botopink Promises stop rejecting on expected failures. Whoever consumes them from
  JS has to know: document it and offer a helper.
- **`std/async`.** The `allOf` / `timeout` signatures with and without `@Result` have to be closed in
  E7 before the libraries migrate.
- **Names in std.** If `Stream` or `Task` exist with another meaning, E1 depends on renaming them
  first (none at `0beaa1f9`).
- **The cost of a `@Result` per item** in large iterators: measure on erlang and wasm; if it weighs,
  specialise the `Ok` `yield` in the backend.
- **Inference in blocks and loops.** Silent promotion is contained by the type (using the value as
  `U` breaks at the use site), but the error appears far from the `try` that caused it; the message
  must also point at the `try` / `throw` that made the value a `@Result`.

## Blast radius

The *Current state* tables: ≈ 885 matches in `compiler-core/src`, ≈ 160 in `libs`, ≈ 930 in
snapshots (the doubled `{beam,wat}` tree of decision 85 doubles the codegen share), 3 libraries at
this pin (jhonstart, rakun, emilia; onze and the bundled libraries as they gain code), and the
examples of 60 library fronts and `02-packaging`. Every snapshot movement is a rename, an `async function` on commonJS where a body did
not await, a RUN LOG changed by running (a JS Promise resolving with `Error`; a `for` no longer
propagating), or a new cell.

## Notes

**Open points the two documents do not decide** — each goes to `decisions-pending.md` as the step
that meets it is reached, with the Measured / Options / Recommendation / Blocks shape:

1. **Front 21's branch.** Its four steps sit on `front/21-effect-chain`, unmerged, and implement
   names 118–128 remove (`@ResultGenerator`, `@FutureGenerator`, `#[@resultGenerator]`,
   `#[@futureGenerator]`, `#[@use]`, `Use ⊃ Future`). Whether 21 merges into `feat` first (this front
   then renames from 21's surface) or closes unmerged (this front starts from `feat`'s pre-102 names
   and cherry-picks what § 1 of the plan reuses) is not stated.
2. **The existing codes the plan's table does not name.** `effect-throw-without-fallible-channel`
   (the guide's examples use `effect-try-without-fallible-channel` for a `throw` too — merged or
   kept?); `effect-missing-annotation`, `effect-duplicate-annotation`, `effect-missing-wrapper` (no
   annotation left to miss or duplicate); `effect-wrapper-mismatch` (its last use, `@Component<X>` with
   `X` owning no context, leaves with 128 — deleted or kept for another mismatch?); `for-over-fallible-generator` (the rule it enforces is deleted, E3.8);
   `yield-without-generator` and `generator-loop-closed-scope` (the guide gives the refusals no
   code). The guide's refusals for a component `use`d, `use` in a closure, `break :outer` out of
   `async { }`, and `#[layout] … -> Element` carry no code either.
3. **`std/async`.** `allSettled` in or out; `timeout`'s error (`TimeoutError` or the Task's `E`
   joined); and the guide's `async.allOf([fetchUser(1), …])` takes started Tasks, while
   `01-std/02-std-async-primitives` takes `fn() -> @Future<T>` thunks because an eager erlang future
   gives no concurrency — which shape `allOf` takes is open.
4. **`@Task`'s methods.** "`.map`, `.then` and the like" — the exact set (`flatMap`? `mapError` has
   nothing to map) is not listed.
5. **`@Future<T>` had an error channel.** `Future<T, E = any>` means a `-> @Future<T>` body could
   `throw` with `E = any`; the codemod's `@Future<T>` → `@Task<T>` is only safe where the body neither
   throws nor tries. Such bodies are not in the plan's review list; they belong there, marked.
6. **The interop helper.** "if it is the case, offer `unwrapOrThrow`": whether it ships, and where
   (std or the JS runtime), is not stated.
7. **`botopink migrate` already has a meaning** (the module tree, no subcommand). Whether
   `migrate` alone keeps it beside `migrate effects` is not stated.
8. **Decision 117's failing render.** `renderStream` "resolves when the response is closed, and a
   failed render is the future's error"; under 120 its return must carry a `@Result` — which `E`,
   and whether `Response.write` / `ChunkWriter.write` / `RenderPlugin.head` stay infallible
   `@Task<…>`, is jhonstart's / rakun's / onze's contract to settle (decision 121's note).
9. **Labels on a prefixed loop.** 105's labels extend to the annotated loop; where the label sits
   in `iter for :outer (xs)` versus `iter :outer for (xs)` is not written.

**The two source documents** — the maintainer's guide and migration plan, written in Portuguese —
are carried here in English: the language rules in decisions 118–128 and [`guide.md`](./guide.md),
the plan in this README.

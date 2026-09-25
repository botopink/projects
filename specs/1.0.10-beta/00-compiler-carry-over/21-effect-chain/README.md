# Front 21 — the effect chain: `@Use`/`@Component`, the three generators, and the owner marker

**Track:** compiler (carry-over item **C-29**)
**Priority:** critical — `builtins.d.bp` spells the `use` capability as `@Context<B, R>`, which is
also the name of the type that carries the context tree, and spells `yield` twice (`@Generator<T, R>`,
`@Iterator<T, E, C>`) with two step enums and two end-payload channels nothing consumes. Every hook,
component and generator in the ecosystem is written against those names, and jhonstart (36
`#[@context]`, 24 `@Context<`) is the library that compiles against them today.
**Depends on:** [`20-builtins-surface`](../20-builtins-surface/README.md) landed —
`comptime/effect_chain.zig` and the `EffectKind`-driven legality checks are what this front renames
and extends. Nothing else: no effect *lowering* changes (the erlang/beam lowerings are C-01/C-07's and
are untouched).
**Owns:** `libs/std/src/builtins.d.bp` (the behaviors of decisions 102/103) · `ast.zig`'s
`EffectKind` (`annotationName`, `returnWrapper`, `fromAnnotationName`, `all`) ·
`comptime/effect_chain.zig` (`clauses`, `yielding_wrappers`, the drift test) · `parser/decls.zig`'s
annotation names, `parseAnnotations`' keyword acceptance and the post-return label ·
`comptime/infer.zig`'s effect legality (R1/R2, the generator refusals, `contextInfoFromReturn`,
`FnContext.annotated` / `env.inContextFn`, `validateUseBase`, the level a collection loop over a
generator needs) · `comptime/stdlib/prelude.zig:16` and the two `context-getcontex-*` diagnostic
codes (decision 108) · `codegen/typescript.zig` and `codegen/wat.zig` **name mappings only**
(decision 98's carve-out, extended) · `codegen/commonJS.zig` `fnKeyword` (`.use` → `async function`)
· `docs.md` § effects, § generators, § use · `comptime/AGENTS.md` · the snapshots those re-record
(measured below) · `scripts/known-red-libs.txt`'s jhonstart line for the duration of step 4 · in
`repository/jhonstart`: `modules/jhonstart/src/element.bp:8`, the 36 annotations, the 24 wrappers,
`server.bp`'s `request()`.
**Does not touch:** `lexer.zig`, `parser/exprs.zig`, the loop forms and the `yield`/`break v` gating
inside loop bodies ([`22-loops`](../22-loops/README.md)) · `libs/std/src/*.bp` other than
`builtins.d.bp`, `parser/decls.zig`'s `parseImportItem`, `project_graph.zig`
([`23-std-purity`](../23-std-purity/README.md)) · any effect *lowering* in `codegen/**` beyond the two
mappings and `fnKeyword` · `specs/1.0.10-beta/04-jhonstart/**` (already spelled to decisions
102–107; step 4 is the jhonstart *library* sweep only) · `decisions-*.md`.

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/` unless a row says
otherwise. Counts were measured at compiler `feat` `4fe1747e` (2026-09-25) with `grep -rn` over
`compiler-core/src`, `libs` and `snapshots`.

---

## Problem

Three names lie, and one exception breeds questions.

1. **`@Context` is two things.** `pub behavior Context<ContextBase, Return>` is the wrapper a
   `#[@context]` body returns *and* the marker a type implements to own a context tree
   (`Element implement @Context<Element, Element>`). The second parameter exists only because the
   same behavior serves as a return wrapper; the first is vacuous because `Element` is its own base
   (decision 96 fixed the base, not the doubled role).
2. **Two names for `yield`.** `@Generator<T, R>` (`next -> Yield<T, R>`) and `@Iterator<T, E, C>`
   (`next -> IteratorStep<T, E, C>`) are one protocol under two step enums; `R` and `C` are two
   spellings of "the payload of the end", and nothing in the tree consumes either — the only client
   of `C` is `transform.zig`'s internal `@IteratorStep` for the F4I tail. `@FutureGenerator<T, E, C>`
   inherits `C` for the same non-reason.
3. **The bare `-> Element` form in an effect body** is the one exception to "every effect body writes
   its wrapper" (decisions 88/95: "or a type that implements the wrapper"). Because R5 allows one
   annotation and the bare form carries none of the chain, decisions 89 and 90 had to unwrap
   `@Future<T>` to find an owner so a server component could `use` — and questions 91, 92 and 93
   followed from the unwrap (decision 104 revokes both).
4. **`getContex`** is missing a letter in nine files, two diagnostic codes and three snapshot slugs
   (question 99).

Decisions [102](../../decisions-taken.md#102-contextbase-is-the-context-owner-marker-only-use-answers-usec-t-or-componentt),
[103](../../decisions-taken.md#103-a-generators-prefix-is-the-level-it-extends-generatort--resultgeneratort-e--futuregeneratort-e),
[104](../../decisions-taken.md#104-only-use-grants-use--decisions-89-and-90-revoked) and
[108](../../decisions-taken.md#108-getcontex--getcontext) answer all four; this front lands them.

## Current state

`EffectKind` has six values — `result`, `future`, `generator`, `iterator`, `futureGenerator`,
`context` — each with one annotation and one required return wrapper; `effect_chain.zig` derives
its clauses from `EffectKind.all`, and R1/R2 accept exactly one wrapper per kind. `FnContext.annotated`
is set by `#[@context]` **or** by a wrapper effect whose unwrapped return owns a context (decision
90); `env.inContextFn` is set by `eff == .context` alone (question 93). commonJS emits
`async function` for a `#[@context]` body only when its built body carries an `await` (`fnKeyword`,
`contextShape`).

Blast radius, measured (lines in `compiler-core/src` · `libs` · `snapshots`):

| Spelling | src | libs | snaps | Becomes |
|---|---:|---:|---:|---|
| `#[@context]` / `.context` / `@Context<` | 103 + 24 + 123 | 1 + 1 + 7 | 36 + 84 | `#[@use]` / `.use` · `@Component<T>` / `@Use<C, T>` · `@Context<Base>` (marker only) |
| `#[@iterator]` / `.iterator` / `@Iterator<` | 75 + 76 + 68 | 5 + 12 | 38 + 40 | `#[@resultGenerator]` / `.resultGenerator` / `@ResultGenerator<T, E>` |
| `FutureGenerator<T, E, C>` | 47 | 7 | 19 | `@FutureGenerator<T, E>` — loses `C` |
| `IteratorStep` / `Yield<` | 7 + 25 | 6 + 2 | 0 + 6 | `YieldStep<T, E = void>` |
| `#[@generator]` / `@Generator<` | 45 | 1 + 4 | 15 | `@Generator<T>` — loses `R` |

Sibling libraries: jhonstart carries 36 `#[@context]` and 24 `@Context<`; rakun and emilia write
only `@Future`, which does not change. The pre-commit gate (`scripts/gate.sh`, stage `test-libs`)
compiles the siblings from the shared checkout, so the compiler cannot land step 2 with jhonstart
green unless the library is in `scripts/known-red-libs.txt` for exactly the commits between the
compiler change and the sweep.

## Mechanism

**The chain is `EffectKind.all`.** `annotationName`, `returnWrapper`, `fromAnnotationName`,
`effect_chain.zig`'s `clauses` and `yielding_wrappers` all derive from that one list, which is why
the work is one `EffectKind` value per commit and why the drift test that reads `builtins.d.bp` in
both directions stays green at every commit. `#[@use]` is the only value whose `returnWrapper` is a
**set** (`{Component, Use}`); R1/R2 accept any member of the set, and `effect_chain.zig` gains one
clause per wrapper (`Use ⊃ Future`, `Component ⊃ Use`).

**The matrix this front lands** (decisions 102/103; `#[@future]`, `#[@result]`, decisions 96 and
98 and R5 are unchanged):

```
@Result<T, E>           (base)           try                   #[@result]
@Future<T, E>           extends Result   await · try           #[@future]
@Use<C, T>              extends Future   use · await · try     #[@use]
@Component<T>           extends Use      use · await · try     #[@use]     ≡ @Use<B, T>, T: @Context<B>

@Generator<T>           (isolated)       yield                 #[@generator]
@ResultGenerator<T, E>  extends Result   yield · try           #[@resultGenerator]
@FutureGenerator<T, E>  extends Future   yield · await · try   #[@futureGenerator]

@Context<Base>          (marker)         —                     —           the type that carries the tree; not a wrapper
```

Six annotations, seven wrappers; `yield` stays exclusive to the three generators, `use` to `#[@use]`;
the annotation grants everything at or below its level and nothing above (decision 95's rule, kept).
`YieldStep<T, E = void> { Yield(value: T), Done, Error(error: E) }` is the one step enum.
`Yield<T, R>`, `IteratorStep<T, E, C>`, `Iterable<T, E, C>` and the two-parameter `Context<B, R>` are
deleted, not aliased (decision 67). The whole file, at the end of step 2:

```botopink
pub behavior Context<Base> { }

pub behavior Result<T, E = any> {
    fn map<R>(self: Self, transform: fn(value: T) -> R) -> Self<R, E>;
    fn flatMap<R>(self: Self, transform: fn(value: T) -> Self<R, E>) -> Self<R, E>;
    fn mapError<F>(self: Self, transform: fn(error: E) -> F) -> Self<T, F>;
    fn unwrapOr(self: Self, default: T) -> T;
}
pub behavior Future<T, E = any> extends Result           { fn await(self: Self) -> Result<T, E>; }
pub behavior Use<C, T> extends Future                   { }
pub behavior Component<T> extends Use                   { }

pub type YieldStep<T, E = void> { Yield(value: T), Done, Error(error: E) }
pub behavior Generator<T>                                { fn next(self: Self) -> YieldStep<T, void>; }
pub behavior ResultGenerator<T, E = any> extends Result  { fn next(self: Self) -> YieldStep<T, E>; }
pub behavior FutureGenerator<T, E = any> extends Future  { fn next(self: Self) -> Future<YieldStep<T, E>, E>; }
```

**The owner is read, never unwrapped.** The base of a `#[@use]` body is `C` for `-> @Use<C, _>` and
the `B` of `T: @Context<B>` for `-> @Component<T>`; `contextInfoFromReturn` looks through nothing.
`@Component<X>` with `X` not implementing `@Context` is `effect-wrapper-mismatch`. Every `use` in one
body shares the base (96); the second `use` at another base is refused naming both. A component is
**called** (`Card()`), never `use`d; `use f()` requires `f: @Use<C, _>` at the body's base, so hooks
compose. `fn Loading() -> Element` with no annotation is an ordinary function (question 92, (b)).

**One flag.** `FnContext.annotated == env.inContextFn`, both set by `#[@use]` alone (104): the
`getContext` gate and the `use` gate are one question, and the hint that asked for an annotation R5
refuses goes with them (question 93, (a)).

**commonJS.** `fnKeyword` answers `async function` for every `#[@use]` body, awaiting or not — as
it already does for `#[@future]` (`commonJS.zig:1792`). Every hook and component returns a Promise on
that target and every caller `await`s it. erlang, wasm and beam do not change: their `@Future` is
eager and `await` is the identity.

## Steps

Each step is a green commit; inside a step, one `EffectKind` value per commit.

### Step 1 — the generators (decision 103)

`Iterator → ResultGenerator<T, E = any>`; `IteratorStep → YieldStep<T, E = void>`;
`FutureGenerator<T, E, C> → FutureGenerator<T, E>`; `Generator<T, R> → Generator<T>` with
`next -> YieldStep<T, void>`; `Yield<T, R>` and `Iterable<T, E, C>` deleted. `#[@iterator]` and
`.iterator` are renamed with the wrapper. `try`/`throw` in a `#[@generator]` body are refused naming
the reason and the wrapper that has a channel
(`` `@Generator` has no error channel; use `@ResultGenerator<T, E>` ``). In a generator body
`break v` **emits `v` and ends** (≡ `yield v; break;`) and a bare `break` outside a loop ends the
generator; the `Done(completion: C)` payload goes with `C`. A collection loop over a generator is a
`try` (`@ResultGenerator`) or an `await` + `try` (`@FutureGenerator` — `loop await` today,
`for await` after 22-loops) in the body that iterates, and needs that level; `@Generator<T>` is
iterable in any body, a plain `fn` included — that is what the infallible wrapper buys.

**Acceptance:**
- [ ] `grep -rn 'Iterator\b\|IteratorStep\|Yield<\|Iterable' libs/std/src/builtins.d.bp modules/`
      finds nothing; `EffectKind.all` has `resultGenerator` where it had `iterator`; the drift test
      green at every commit
- [ ] a `#[@generator]` body with `try` is refused with the diagnostic above; a `#[@resultGenerator]`
      body with `try` compiles; a `#[@futureGenerator]` body with `await` and `try` compiles — one
      `reject/` or `test/` cell each, on the four targets
- [ ] `break v` in a `#[@generator] fn` emits `v` as the last item, run on all four;
      `run/loop_yield_then_break_value.bp` re-specified to that answer (its decision-55 reading is
      C-06's and is superseded — [`22-loops`](../22-loops/README.md))
- [ ] a plain `fn` iterating a `@Generator<T>` compiles and runs; a plain `fn` iterating a
      `@ResultGenerator<T, E>` is refused naming `try` and the level; a `#[@result]` body iterating it
      compiles
- [ ] the 38 + 40 iterator snapshots and the 19 + 6 + 15 generator snapshots re-recorded and
      classified: rename-only diffs, plus the RUN LOGs step 1 changes by running
- [ ] `docs.md` § generators carries the three wrappers and `YieldStep`; `comptime/AGENTS.md` updated
      in the same commit

### Step 2 — `@Context<Base>`, `@Use<C, T>`, `@Component<T>`, `#[@use]` (decisions 102 and 104)

`Context<ContextBase, Return>` becomes `pub behavior Context<Base> { }`, a marker with no methods;
`pub behavior Use<C, T> extends Future { }` and `pub behavior Component<T> extends Use { }` are the
wrappers; `EffectKind.context → .use` with `returnWrapper = {Component, Use}`; `#[@context] →
#[@use]`; the bare `-> Element` form in an effect body is refused with `effect-missing-wrapper`;
`contextInfoFromReturn` reads `C` or `T`'s `B` and unwraps nothing; `FnContext.annotated` and
`env.inContextFn` are one flag set by `#[@use]`; `fnKeyword` on commonJS answers `async function`
for `.use`. Decisions 89 and 90 are revoked by 104 and this step deletes their code. `use` is a lexer
keyword (`lexer.zig:752`), so `parseAnnotations` must accept a keyword token as the annotation name
after `#[@` — the same change 22-loops needs for `#[@generator] loop`, made here first.

104 is not separable from 102: without the bare form there is no owner to unwrap and no second
annotation to want.

**Acceptance:**
- [ ] `#[@use] fn counter() -> @Use<ElementBase, i32> { val s = use state(0); … }` and
      `#[@use] fn Page() -> @Component<Element> { val n = use counter(); val d = await load(); val c = try read(); … }`
      infer and run on four targets, `Element implement @Context<ElementBase>` declared in the cell
- [ ] `#[@future] fn Page() -> @Future<Element> { use pathname(); }` is `use-without-context-effect`
      naming `#[@use]`; `fn Loading() -> Element` with no annotation is an ordinary function;
      `#[@use] fn f() -> string` is `effect-wrapper-mismatch`; `#[@use] fn f() -> Element` (bare) is
      `effect-missing-wrapper`; `@Component<X>` with `X` not a `@Context` owner is
      `effect-wrapper-mismatch`
- [ ] two bases in one body refused at the second `use` naming both (96, kept); `use Card()` where
      `Card: @Component<Element>` is refused — a component is called
- [ ] `@getContext(T)` works in every `#[@use]` body and nowhere else; the hint no longer names an
      annotation R5 refuses
- [ ] commonJS: every `#[@use]` body is `async function`; the `contextShape` body scan is deleted;
      erlang/wasm/beam output for the same programs differs only in the renamed atoms and strings
- [ ] `grep -rn '#\[@context\]\|@Context<[^>]*,' modules/ libs/ tests/` finds nothing; the 36 + 84
      snapshots re-recorded and classified; the 8 `tests/language` `use` cells of front 19 re-spelled
      and green on four targets; `docs.md` § use and § effects carry the matrix above

### Step 3 — `getContex` → `getContext` (decision 108)

The intrinsic in `builtins.d.bp` / `builtins_fns.d.bp`, `prelude.zig:16`, `comptime.zig`, `env.zig`,
`infer.zig`, the codes `context-getcontext-outside-context-fn` and
`context-getcontext-expects-type`, RC4/RC5 in `comptime/tests/infer_errors.zig`, `docs.md`, and the
three snapshot slugs (moved by `git mv`).

**Acceptance:** `grep -rn 'getContex\b' repository/` returns nothing; the three snapshots moved, not
re-recorded; RC4/RC5 fire with the new codes.

### Step 4 — the jhonstart sweep

`modules/jhonstart/src/element.bp:8` → `implement @Context<ElementBase>` (the base name is the
library's, decision 96); the 36 `#[@context]` → `#[@use]`; the 24 `@Context<Element, X>` →
`@Use<ElementBase, X>` (hooks) or `@Component<Element>` (components); `server.bp`'s `request()` →
`@Use<ElementBase, Request>`; every server component `#[@future] fn … -> @Future<Element>` that
activates a hook → `#[@use] fn … -> @Component<Element>`. The ledger sequence: the compiler commit
of step 2 lands with `jhonstart` in `scripts/known-red-libs.txt`; the sweep lands in
`repository/jhonstart`; the ledger line is deleted in the next compiler commit — adjacent commits,
and a listed cell that passes fails the gate, so the window is exactly one commit wide.

**Acceptance:** jhonstart `zig build test-libs` green on commonJS and erlang at its pre-sweep counts;
`grep -rn '#\[@context\]\|@Context<Element, ' repository/jhonstart` returns nothing;
`known-red-libs.txt` back to its header; the meta submodule pointer bumped in the same sweep.

## Gate

- [ ] `scripts/gate.sh --cold` green in this front's worktree at every commit; `test-libs` at
      baseline (jhonstart through the ledger during step 4 only)
- [ ] `zig build test-language` green on the four targets with the cells above; every re-recorded
      RUN LOG verified by running
- [ ] the `effect_chain.zig` drift test green with `builtins.d.bp` at its final shape
- [ ] `AGENTS.md` of `src/comptime/`, `src/codegen/`, `src/parser/`, `libs/std/` in the same commit
      as each change
- [ ] Commit on `fix/effect-chain`; no push, no merge — landing is the maintainer's step

## Blast radius

The table under *Current state*: ≈ 400 source lines, ≈ 250 snapshot files, one library. Every
snapshot movement is a rename except the RUN LOGs step 1 changes (`break v` as the last item) and
the commonJS outputs step 2 changes (`async function` where a `#[@context]` body did not await).
Fronts 19 and 20 lose their remaining effect-side steps to this front (each says so). C-06's
decision-55 cells are re-specified here and by 22-loops.

## Handoff

- **To [`22-loops`](../22-loops/README.md):** the loop keywords (`for`, `while`, `for await`),
  `yield`/`break v` gated by a generator *scope* rather than a generator *fn* (so that
  `#[@generator] loop { … }` is a scope), and `break v` outside a generator scope refused. Step 1
  states the semantics on the loop forms that exist today.
- **To [`19-use-activation`](../19-use-activation/README.md):** its rule for libraries is restated
  there against this surface; its step 3 (tuple destructure) is unaffected.

## Notes

- Decisions 89 and 90 are revoked by 104; question 91 is moot; 92 closes (b); 93 closes (a); 97
  closes (b) through 103; 99 closes (a) as 108. R5, decision 96 and decision 98 are unchanged.
- `@Future` is kept as the one word for suspension; `@Use` and `@Component` are the two forms of one
  capability, and `#[@use]` ↔ `@Use` share the name like the other five pairs (decision 98 § 1
  intact; `@Component<T>` is sugar for `@Use<B, T>`, not a wrapper with a rule of its own).
- The libraries the compiler does not know: `ElementBase` (jhonstart) and whatever rakun names its
  request base are the libraries' words; the compiler reads the base off `implement @Context<Base>`.

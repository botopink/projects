# Front 20 — the builtins surface

**Track:** compiler (carry-over item **C-28**)
**Priority:** critical — `libs/std/src/builtins.d.bp` is the one file that says what the language's
own types are; every front that writes an effect, a hook or an indexable type reads it.
**Target:** all — the declarations are backend-independent; what changes per backend is only which
cells prove the rules.
**Depends on:** decisions [95](../../decisions-taken.md#95-the-effects-are-a-chain-context--future--result-and-every-effect-can-fail),
[96](../../decisions-taken.md#96-one-contextbase-per-function-and-element-carries-its-base) and
[98](../../decisions-taken.md#98-one-word-for-suspension-future-the-async-generator-effect-is-futuregenerator--futuregenerator);
amended by [102](../../decisions-taken.md#102-contextbase-is-the-context-owner-marker-only-use-answers-usec-t-or-componentt),
[103](../../decisions-taken.md#103-a-generators-prefix-is-the-level-it-extends-generatort--resultgeneratort-e--futuregeneratort-e),
[104](../../decisions-taken.md#104-only-use-grants-use--decisions-89-and-90-revoked) and
[108](../../decisions-taken.md#108-getcontex--getcontext), whose implementation is
[`21-effect-chain`](../21-effect-chain/README.md).
**Owns:** `repository/botopink-lang/libs/std/src/builtins.d.bp` ·
`modules/compiler-core/src/comptime/effect_chain.zig` and the effect-legality and anchor checks in
`comptime/infer.zig` (`try` / `await` / `use` / `yield`, RC1–RC5) and their diagnostics ·
`EffectKind` in `ast.zig` · `docs.md` § effects, § builtins, § use · the `tests/language` and
`comptime/tests` cells for each rule — all of which 21-effect-chain takes over for decisions
102–104 and 108.
**Does not touch:** any `codegen/**` lowering (each backend's front owns its own — this front changes
what is *legal*, never what is *emitted*; the name mappings in `codegen/typescript.zig` and
`codegen/wat.zig` are the one carve-out) · `libs/std/src/*.bp` other than `builtins.d.bp` · the
five library repositories, except that `Element`'s declaration is named here and changed by
jhonstart's own sweep (21 step 4).

---

## Problem

The builtins file is the language's own vocabulary. Twelve findings of its review, each with the
line it sits on and where it stands:

| # | Finding | Where | Stands |
|---|---|---|---|
| F1 | `Context` declared twice in one module — the hook wrapper `behavior Context<ContextBase, Return>` and the Expr-template record `type Context(source, text, multiline)` | `:177`, `:404` | closed — one `Context`; under 102 the behavior is `Context<Base>`, a marker |
| F2 | the async-generator annotation and its wrapper disagreed | `builtins.d.bp:123`, `ast.zig:2072` | closed — `#[@futureGenerator]` → `@FutureGenerator` (98); `C` leaves under 103 (21) |
| F3 | `Generator<T, R>` has no error channel while `Iterator<T, E = any, C = void>` has one | `:109`, `:88` | decided — 103: `@Generator<T>` stays infallible (97-b), `R` leaves, `try`/`throw` refused naming `@ResultGenerator<T, E>`; 21 step 1 |
| F4 | `Result`'s variants are `Ok` / `Error`, the prose said `Result::Ok` / `Result::Err` | `:24`, `:284-286` | closed — the type wins |
| F5 | `Future` proved the chain with a method, not a clause | `:116` | closed — the chain is `effect_chain.zig`; `fn await` is the unwrap |
| F6 | § 1C said `yield`, `await`, `throw` are forbidden in a context body | `:354` | closed — 95: `await` and `try` are legal there; `use` is what only `#[@use]` grants (104) |
| F7 | `getContex` is missing a `t` | `builtins.d.bp`, `prelude.zig:16`, `docs.md`, RC4/RC5 | decided — 108; 21 step 3 |
| F8 | `Context<ContextBase, Return>` is empty and `Element` is its own base | `:177`; `jhonstart/modules/jhonstart/src/element.bp:8` | decided — 96 (a base per owner) and 102 (`@Context<Base>`, one parameter); 21 steps 2 and 4 |
| F9 | `External` is asymmetric (`inline` on `Erlang`/`Node`/`Beam`, not on `Wasm`/`Typescript`) and duplicates `Target` | the `External` and `Target` declarations | step 4 |
| F10 | the intrinsics at the foot were written in another dialect (no `pub`, no `->`) | the runtime/reflection section | closed |
| F11 | `?T`'s `expect(self, default: T) -> T` was documented as identical to `unwrapOr` | the option section | closed — `expect` deleted and refused (an unknown method on a `?T` typed permissively and failed at run time, which is why deleting the arm alone was not enough) |
| F12 | `Iterable.iter(self) -> Iterator<T, E, C>` answers a behavior as a value | `:100` | decided — 103 deletes `Iterable`; a type that wants to be iterated exposes a method answering a generator; 21 step 1 |

## Current state

> **Superseded surface.** The effect names below (`@Future`, `@Use`, `@Generator` and its two
> prefixed forms, `#[@<effect>]` annotations) are the pre-118 surface this front landed.
> Decisions [118–128](../../decisions-taken.md#118-the-return-type-is-the-annotation), landed by
> [`24-effects-by-return`](../24-effects-by-return/README.md), replaced them: the return type is the
> annotation, and `builtins.d.bp` now declares `Task`, `Component<C, T>` (extends `Task`),
> `Iterator`, `Stream` (extends `Task`) and `YieldStep<T>`. `comptime/effect_chain.zig` and its drift
> tests follow that file. What this front built — the chain as `effect_chain.zig` asked by every
> capability check, the two-way drift test, one anchor per body, `External`'s `inline` table —
> still stands under the new names.

`EffectKind` has six values (`result`, `future`, `generator`, `iterator`, `futureGenerator`,
`context`), each with an annotation spelling and a required return wrapper (`ast.zig`); R5 allows
one effect annotation per fn (`parser/decls.zig:407`). The chain is `comptime/effect_chain.zig`,
asked by the `try` / `await` / `use` / `yield` checks, with a drift test that reads `builtins.d.bp`
in both directions — a `behavior` carries `extends`, and `builtins.d.bp` is parsed by nothing, so
the chain cannot be `implement` clauses in the file. `try` is gated by the enclosing body; `yield`
fails closed outside a generator body. `FnContext.annotated` is set by `#[@context]` or by a wrapper
effect whose unwrapped return owns a context, and `env.inContextFn` by `eff == .context` alone — one
flag under 104. Language suite 401/53/0, beam 49/23/0.

The chain decision 95 ordered, under the names decisions 102/103 give it, is 21-effect-chain's
*Mechanism*: `@Component<T> ⊃ @Use<C, T> ⊃ @Future<T, E> ⊃ @Result<T, E>`;
`@FutureGenerator<T, E> ⊃ @Future`; `@ResultGenerator<T, E> ⊃ @Result`; `@Generator<T>` isolated;
`@Context<Base>` a marker outside the chain.

## Mechanism

**The chain is the type, not a table in the checker.** The legality of `try` / `await` / `use` /
`yield` in a body is "does the body's wrapper extend the wrapper that capability belongs to", asked
of `effect_chain.zig`, whose clauses derive from `EffectKind.all`. A capability written above the
body's level is refused, located, naming the level it would need — never accepted and ignored
(decision 67).

**One anchor per body** (96). The body's base is fixed — by `C` of `@Use<C, _>` or the `B` of
`T: @Context<B>` under 102; a `use` anchored elsewhere is refused at its own site naming both bases.

## Steps

### Step 4 — the residues

F9: `External` gains `inline` everywhere or loses it, and says why it is not `Target`. One paragraph
and one cell.

**Acceptance:**
- [x] `inline` is symmetric across the five `External` variants, or its absence on `Wasm` /
      `Typescript` is stated in the file; a cell
- [x] `builtins.d.bp` says in one sentence why `External` is not `Target`

Steps 0–3 and 5 (the measured table, the file agreeing with itself, the chain, one anchor per body,
`docs.md` and the cells) are in the tree — *Current state* is their record. F3, F7, F8 and F12 land
with 21-effect-chain under decisions 103, 108, 102 and 103.

## Gate

- [x] `zig build test` green from a cold cache; the drift test green — measured at compiler
      `0cd949a4` (post-24 `builtins.d.bp`) with `.zig-cache`, `zig-out` and
      `modules/compiler-core/.botopinkbuild/runtime-cache` deleted: 23/23 steps, 2474/2474 tests
      (compiler-core 2075); `zig build test -Dtest-filter="effect chain"` 6/6 in compiler-core —
      "every clause here is declared in builtins.d.bp", "builtins.d.bp declares no clause this
      module does not carry" and "every effect wrapper is declared, and no removed one is" are the
      drift tests
- [ ] `builtins.d.bp` formats — `botopink format --check libs/std/src/builtins.d.bp` refuses the
      file on two parser rows, neither this front's: (1) an unannotated top-level
      `[pub] declare fn` is routed by `parser.zig`'s top-level dispatch to
      `parseShorthandDelegateDecl` (`parser/decls.zig`), which takes no generic parameters, no `_`
      parameter name and a one-token return type — `field<T, F>` (`:312`) and
      `getContext<T>(comptime _: type) -> Component<T, any>` (`:395`); (2) a behavior's `val` member
      takes a one-identifier type (`BehaviorField.typeName`), so `Decl`'s `val fields: Field[];`
      (`:582–586`) does not parse. With both rows bypassed in a scratch copy the rest of the file
      parses and the formatter's diff is layout only (the multi-annotation `#[A, B]` split into two
      `#[…]`, `{ }` → `{}`, trailing-comment alignment, blank lines). Once the file parses,
      `scanDeclareFnExternal` (commonJS / erlang), which parses this file and `catch return`s today,
      starts reading its `#[External.*]` declarations — measure the codegen snapshots then
- [x] step 4's cell; `libs/std/AGENTS.md` in the same commit
- [x] Commit on `front/20-builtins-surface`; no push, no merge — landing is the maintainer's step

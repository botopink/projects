# Front 21 — the effect chain: one grant of `use`, one step enum, and the owner marker

**Track:** compiler (carry-over item **C-29**)
**State:** closed. Its outcomes hold in the return-type surface of
[`24-effects-by-return`](../24-effects-by-return/README.md) (decisions 118–128), which owns the effect
chain, `EffectKind`, `effect_chain.zig` and the effect legality. Nothing is open.

Decisions [102](../../decisions-taken.md#102-contextbase-is-the-context-owner-marker-only-use-answers-usec-t-or-componentt),
103, [104](../../decisions-taken.md#104-only-use-grants-use--decisions-89-and-90-revoked) and
[108](../../decisions-taken.md#108-getcontex--getcontext), as amended by 118–128.

---

## What holds

1. **`@Context<Base>` is the owner marker only** (102). `pub behavior Context<Base> { }` has no
   methods and is not a return wrapper: a type implements it to own a context tree
   (`Element implement @Context<ElementBase>` in jhonstart). The base name is the library's; the
   compiler reads it off the `implement` clause.
2. **One grant of `use`** (104, 128). Only a `-> @Component<C, T>` return grants `use`; the base is
   `C`, read off the return and never unwrapped from `T`. A component is the `@Component<C, T>`
   whose `T` implements `@Context<C>` — it is called, and `use` of it is refused; a `T` owning a
   context at another base is `effect-wrapper-mismatch`; `@Component` with one type argument is a
   type-arity error.
3. **One flag.** `FnContext.annotated == env.inContextFn`, both set by the `@Component` return: the
   `use` gate and the `@getContext` gate are one question.
4. **commonJS.** Every `@Component` body is an `async function`, awaiting or not; a caller `await`s
   it. erlang, wasm and beam are eager and `await` is the identity.
5. **One step enum** (103, 122). `YieldStep<T> { Yield(value: T), Done }` is the only step. In a
   generator scope `break v` **emits `v` and ends** (≡ `yield v; break;`), and a bare `break` outside
   a loop ends the generator.
6. **`getContext`** (108). The intrinsic, `prelude.zig`, the codes
   `context-getcontext-outside-context-fn` and `context-getcontext-expects-type`, and the three
   snapshot slugs carry the full spelling.
7. **jhonstart** writes every hook as `fn <noun>(…) -> @Component<ElementBase, T>`, every
   component as `fn … -> @Component<ElementBase, Element>`, and `request()` as a hook.

A function that activates nothing is a plain `fn … -> Element`. The libraries' base names
(`ElementBase` in jhonstart, `RequestBase` in rakun) are the libraries' words; the compiler knows
neither.

## Cells

`run/generator_break_value.bp` (`break v` is the last item), `run/generator_levels.bp`,
`run/yield_step_next.bp`, `test/yield_step_next.bp`, `run/context_use.bp`, `run/use_one_base.bp`,
`reject/use_of_component.bp`, `reject/use_two_bases.bp`, `reject/use_in_closure.bp`,
`reject/yield_step_error_param.bp`; RC4 / RC5 in `comptime/tests/infer_errors.zig` for
`getContext`.

## Closed

- [x] `run/generator_break_value.bp` on wasm — green: a bare `break` at a generator body's own level
      ends it (`wat.zig` `emitGenEnd`); the cell prints its `.out` on commonJS, erlang, wasm and beam

# Front 19 — the `use` activation: hooks, components, and the boundary directives

**Track:** compiler (carry-over item **C-27**)
**Priority:** high — jhonstart's whole hook and component surface (fronts 26–32, 67, 94) is written
against `use`; `docs.md` § *use — imports, activation, and hooks* documents it. What is left here is
step 3 (tuple destructuring from a `use`); the grant is decision 104's and lands in
[`21-effect-chain`](../21-effect-chain/README.md).
**Depends on:** C-08 (parser gaps) for the tuple-pattern half of step 3;
[`21-effect-chain`](../21-effect-chain/README.md) for the spelling of every example below.
**Owns:** the `use` rules in `src/parser.zig` (the activation statement `:394-397`,
`useAfterBranchGuard` `:697`, `:737-745`, `:772`, `useBranchSeen`, `bindingUseLoc`, `freshUseScope`)
and `src/parser/exprs.zig:116-124` · the `use` functions of `src/comptime/infer.zig`
(`contextBaseFromImplements` `:963`, `contextInfoFromReturn` `:976`, `contextBaseOfType` `:1002`,
`bindingSourceType` `:1020`, the body scope `:3009-3013`, `inferUseHookExpr` `:8134`,
`validateUseBase` `:8160`, `bindUseDestructure` `:8176`) — their effect-side rewrite under decisions
102/104 is 21's · the `useHook` lowering arm in the four emitters (`codegen/commonJS.zig`,
`codegen/erlang.zig:5216`, `codegen/wat.zig:2814`, `codegen/beam_asm.zig:2912`) · `docs.md` § use ·
the `tests/language` `use` cells (`test/context_use.bp`, `run/context_use.bp`,
`reject/use_{after_return,inside_branch,in_plain_fn,without_context_effect,owner_mismatch,at_module_level}.bp`)
· the `snapshots/**` those re-record.
**Does not touch:** jhonstart's own files — the library writes its hooks to the rule stated here (the
`#[@use]` sweep is 21 step 4) · `18-comptime-runtimes/` · `EffectKind`, `effect_chain.zig`,
`builtins.d.bp` ([`20-builtins-surface`](../20-builtins-surface/README.md), then 21).

Paths are relative to `repository/botopink-lang/modules/compiler-core/` unless a row says otherwise.
Decisions: [87](../../decisions-taken.md#87-the-boundary-directives-stay-library-decorators--use-never-leaves-a-function-body)
the boundary directives are library decorators and `use` never leaves a function body ·
[88](../../decisions-taken.md#88-use-lowers-transparently-and-a-component-is-context-fn---element)
`use f(x)` lowers to `f(x)` on every backend · [96](../../decisions-taken.md#96-one-contextbase-per-function-and-element-carries-its-base)
one base per body · [102](../../decisions-taken.md#102-contextbase-is-the-context-owner-marker-only-use-answers-usec-t-or-componentt)
a component is `#[@use] fn … -> @Component<T>`, a hook `#[@use] fn … -> @Use<Base, R>`,
`T implement @Context<Base>` · [104](../../decisions-taken.md#104-only-use-grants-use--decisions-89-and-90-revoked)
only `#[@use]` grants `use`; 89 and 90 revoked · [108](../../decisions-taken.md#108-getcontex--getcontext)
`getContext`.

---

## Problem

Two things a framework needs from `use` are not in the tree:

1. **One grant.** `FnContext.annotated` is set by `#[@context]` or by a wrapper effect whose unwrapped
   return owns a context, and `env.inContextFn` (the `@getContex` gate) by `eff == .context` alone —
   two flags for one capability, and a hint that asks for an annotation R5 refuses beside
   `#[@future]`. Decision 104 makes them one flag set by `#[@use]`; 21-effect-chain lands it.
2. **Tuple destructuring.** `val #(shown, push) = use optimistic(b, f)` parses and lowers, but every
   element is a fresh type variable — `R`'s tuple element types are not propagated and no arity is
   checked (`infer.zig:8194-8196`). Step 3.

## Current state

`Element` is `type Element(…) implement @Context<Element, Element>`
(`repository/jhonstart/modules/jhonstart/src/element.bp:8`); the cells declare their own owner
(`comptime/tests/effects.zig:244`). The construct runs as `tests/language` cells on commonJS,
erlang, wasm and beam — 8 cells, none in `expected-failures.txt`.

| # | Program | Parses | Infers | Lowers (all four) | Derived from |
|---|---|---|---|---|---|
| 1 | `#[@context] fn C() -> Element { val c = use state(0); … }` | yes | yes — `c : State<i32>` (`R`) | `state(0)` — a plain call | `parser/exprs.zig:118-124` · `infer.zig:3011-3013`, `:8134-8151`, `:1020-1027` · `snapshots/codegen/*/codegen_use_*_is_a_plain_call.snap.md` |
| 2 | `#[@future] fn P(params) -> @Future<Element> { val r = use request(); … }` | yes | yes — the owner is read through `@Future<T>`; **refused after 21-effect-chain** (104): a server component that activates is `#[@use] fn … -> @Component<Element>` | plain call | `infer.zig` `contextInfoFromReturn`, `FnContext.annotated` |
| 3 | `fn f() -> string { val x = use state(0); … }` | yes | **no** — `use-of-non-context-fn` | — | `infer.zig:8135-8142`; `effects.zig:293-302` |
| 3b | `fn Widget() -> Element { val c = use state(0); }` — no annotation | yes | **no** — `use-without-context-effect`, naming the annotation | — | `comptime/error.zig`, `comptime/diagnostics.zig`; `reject/use_without_context_effect.bp` |
| 4 | `use` after `if`/`return`/`loop`/`case` at the same block level; `val c = use …` after a `return`; `use` inside a branch's own block | **no** — `` `use` must be in static prefix`` | — | — | `parser.zig` (`useBranchSeen`, `bindingUseLoc`; `freshUseScope` for a fn, method, `test` or lambda body) · `parser/tests/errors.zig:52-69`; `reject/use_{after_return,inside_branch}.bp` |
| 5 | `val f = { -> use state(0) }` inside a component | yes | yes — a lambda resets `throwContext`, `starFn` and labels, not `fnContext` | plain call inside the arrow | `infer.zig:9100-9121` — **derived, no cell** |
| 6 | custom hook `#[@context] fn counter(n) -> @Context<Element, State<i32>> { return state(n); }`; `val c = use counter(5)` | yes | yes — the `return` is checked against `R` | `counter(5)` | `infer.zig:3360-3362`; `effects.zig:280-297` |
| 7 | `val {value, set} = use state(0)` | yes | yes — each name bound to the field of `R` by name | plain call, then the destructure | `infer.zig:7371-7372`, `:8180-8193` · `codegen_use_object_destructure_*` |
| 8 | `val #(shown, push) = use optimistic(b, f)` | yes (`parser/exprs.zig:661-676`) | yes, but every element is a **fresh type var** | plain call, then the tuple destructure | `infer.zig:8194-8196` · `codegen_use_tuple_destructure_*`, `codegen/tests/features.zig:209-221` |
| 9 | hook called without `use`: `val c = state(7); c.value` | yes | the call is ordinary; `c` is the wrapper (`bindingSourceType` runs only under `use`) | plain call | `infer.zig:8150`; `run/context_use.bp` (`fn Plain() -> Element { val c = state(7); … }`) |
| 10 | `Name*;` at module level | yes | **always an error**: `redundantActivation` for a local extension, else `notAnExtension` | emits nothing | `parser/decls.zig:219-225`, `:263-272`; `infer.zig:879-899` |
| 11 | `import { x* } from "…"` | yes | `env.activations.put("x")` | a `require` / import form | `parser/decls.zig:247`; `infer.zig:897` |

The static-prefix guard is switched on in `parseStmtListInBraces` (`parser.zig:772`) — every
brace-delimited block, a syntactic rule independent of the return type. `docs.md` documents the
three-production grammar (`ImportItem`, `ActivationStmt`, `UseExpr`), the hook / component /
custom-hook shapes and every diagnostic verbatim. [`surface.md`](./surface.md) is the per-construct
table.

## Mechanism

**Two roles, one keyword.** `lexer.zig:752` makes `use` a keyword. (1) As a **declaration** it is
`DeclKind.use: ImportDecl` (`ast.zig:1934`) — the `import { … } from "…"` form (`parser.zig:385-387`)
and the **activation statement** `Name*;` (`parser.zig:394-397`, `ImportDecl.activationOnly`
`ast.zig:57`). Activation is about *extensions*: `import { name* }` opts an imported
`implement`/`extend` into scope (`infer.zig:879-899`, "Rule B"); the bare `Name*;` names a local
symbol and is refused either way. (2) As an **expression prefix** it is `Expr.useHook` (`ast.zig:198`,
`:602-621`): `use <call>`, parsed by `parser/exprs.zig:116-124` as a prefix operator whose operand is
a whole expression. The binding is never part of `use` (`ast.zig:605-609`).

**The base.** `inferFnDecl` computes `env.fnContext` from the declared return type before visiting
the body (`infer.zig:3009-3013`; `:3277-3279` for `implement` methods). Under decision 104 the base is
`C` for `-> @Use<C, _>` and the `B` of `T: @Context<B>` for `-> @Component<T>`, and
`contextInfoFromReturn` unwraps nothing; `inferUseHookExpr` (`:8134-8152`) then requires the operand
to be `@Use<C, _>` at the body's base (`validateUseBase` `:8160-8172`; else `use-of-non-context-fn`
or `context-anchor-violation`), and every `use` in one body shares the base (96). `@getContext(T)`
reads the active provider of `T` under the same flag (104, 108).

**What the binding gets.** The typed `useHook` node's type is `bindingSourceType(operand type)` — the
`R` of the wrapper (`:1020-1027`, `:8150`): `val c = use state(0)` binds `c : State<i32>`;
`val {value, set} = use state(0)` binds by field name (`:8180-8193`); `val #(a, b) = use …` binds
fresh vars (`:8194-8196`). Without `use`, the call's type is the wrapper itself.

**Lowering.** `use f(x)` is `f(x)` on every backend (88): `commonJS.zig` `buildExpr(inner)` in
statement and value position, `erlang.zig:5214-5216`, `wat.zig:2812-2814`, `beam_asm.zig:2910-2912`.
No rename, no inferred dependency array — a hook that takes one declares it as a parameter. On
commonJS every `#[@use]` body is `async function` (104); the client runtime is jhonstart's half.

## The rule for libraries

The normative surface under decisions 87, 88, 96, 102 and 104, spelled as 21-effect-chain lands it
(`#[@context]` / `@Context<Element, R>` in the tree until then).

1. **A hook** is `#[@use] pub fn <noun>(…) -> @Use<Base, R>` — **no `use` prefix in its name**; the
   keyword is the activation, the name is the noun of what is yielded: `state`, `effect`, `memo`,
   `ref`, `reducer`, `router`, `pathname`, `params`, `searchParams`, `selectedLayoutSegment`,
   `selectedLayoutSegments`, `linkStatus`, `formStatus`, `actionState`, `optimistic`, `request`.
   camelCase. `Base` is what the library's owner type declares (`Element implement
   @Context<ElementBase>`; the name is jhonstart's, 96). A hook that composes hooks is the same shape
   and `use`s them.
2. **Activation** is `val x = use <noun>(…)` (or a bare `use <noun>(…);` for a void hook, or
   `val {a, b} = use <noun>(…)`), in the **static prefix** of a `#[@use]` body. `use f()` requires
   `f: @Use<Base, _>` at the body's base; every `use` in one body agrees on `Base`. Never
   `use use<Noun>()`.
3. **The same fn called without `use` is an ordinary call** — the SSR / first-render value; the
   binding's type is the wrapper, and the caller needs no annotation (row 9).
4. **A component** is `#[@use] fn … -> @Component<Element>` — `@Use<ElementBase, Element>` without
   repeating the base. A component is **called** (`Card()`), never `use`d. A component that activates
   nothing is a plain `fn … -> Element` with no annotation (104). A **server component** that awaits
   and activates is the same `#[@use] fn … -> @Component<Element>` — `Component ⊃ Future ⊃ Result`,
   so `await` and `try` are legal in it (95); `#[@future] fn … -> @Future<Element>` activates nothing.
   R5 stands: one annotation per fn. Every effect annotation is lowercase; a capital `#[@Use]` is an
   unknown annotation, silently ignored.
5. **A binding from a hook never reuses the hook's name.** `val router = use router()` shadows the
   imported fn for the rest of the module's inference — `env.bindings` is one flat `StringHashMap`
   (`comptime/env.zig:346-347`, `:841-847`), and `inferFnDecl` restores nothing on exit (the only
   restore is `restorePatternBindings` for `case` arms, `infer.zig:5440-5450`). Derived, not run.
   Write `val r = use router()`, `val path = use pathname()`.
6. **Type constructors stay PascalCase** (`ActionState(…)`, `FormStatus(…)`, `LinkStatus(…)`,
   `RouterState(…)`); a hook and a constructor of the same noun never collide. A *helper* that builds
   a value of that type takes a verb (`parseActionState`, `newActionState`), never the bare noun the
   hook owns.

## Steps

### Step 3 — destructuring from a `use`

`val {a, b} = use …` works (row 7). `val #(a, b) = use …` parses and lowers but its elements are
fresh vars (row 8): `bindUseDestructure` (`infer.zig:8194-8196`) must bind each name to the
corresponding element of `R` when `R` is a tuple type (`ast.zig:1763` `tuple_: []TypeRef`), and
refuse an arity mismatch. The labeled-tuple half (`#(state: S, dispatch: fn(…))` losing its labels
through generic instantiation, `hooks.bp:75-77`) stays with C-08 / 01-checker; this step is the
positional half only.

**Acceptance:**
- [ ] `val #(shown, push) = use optimistic(12, addLike)` binds `shown : i32`,
      `push : fn(action: i32)`; a cell on four targets
- [ ] `val #(a) = use optimistic(…)` is an arity error, located; a `reject/` cell
- [ ] `67-jhonstart-forms/examples/optimistic-like-example.bp` compiles with the tuple form
- [ ] row 5 — a `use` inside a nested closure — gets a cell, or stays recorded as derived

Steps 0, 1, 4 and 5 (the measurement; the documentation and the static-prefix holes; the boundary
directives — no compiler change, decision 87; the lowering contract — decision 88) are in the tree,
and *Current state* is their record. Step 2 (the grant for a server component) is decision 104's and
is 21-effect-chain step 2.

## Gate

- [x] `docs.md` documents `use` (both roles), the static-prefix rule and the diagnostics
- [x] the static-prefix guard holds at any nesting; a fn, method, `test` or lambda body starts its
      own prefix
- [x] `tests/language` has `use` cells green on commonJS, erlang, wasm and beam
- [x] `use f(x)` is `f(x)` on every backend; `grep -rl useState snapshots/` is empty
- [ ] `val #(a, b) = use …` binds element types — step 3
- [x] every component and custom hook in `04-jhonstart` is `#[@use] fn … -> @Component<Element>` /
      `#[@use] fn <noun>(…) -> @Use<ElementBase, _>` (decisions 102/104);
      `grep -rn "use use" specs/1.0.10-beta/04-jhonstart repository/jhonstart` → 0
- [ ] `AGENTS.md` of `src/comptime/` in the same commit as step 3; commit on `fix/use-activation`;
      no push, no merge

## Blast radius

Step 3 is `bindUseDestructure` and one snapshot pair (`codegen_use_tuple_destructure_*`, four
targets). Everything effect-side — the annotation, the wrappers, the owner rule, `async function` on
commonJS — moves with 21-effect-chain, which re-spells the 8 `use` cells and jhonstart's 36 + 24
sites.

## Notes

- Decision 8 § 5.1 P6 is the tuple *pattern* `#(a, b)` in `case` (`parser/patterns.zig:193-196`), a
  sibling of the binding form step 3 completes.
- The `use` prefix is **not** React's `use(promise)`: Next's *Streaming de dados com `use`* is out of
  scope for that reason (`04-jhonstart/unification.md` § 4).
- The provider stack behind `@getContext` is nobody's front yet.

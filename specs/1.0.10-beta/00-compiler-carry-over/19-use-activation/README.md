# Front 19 — the `use` activation: hooks, components, and the boundary directives

**Track:** compiler (carry-over item **C-27**)
**State:** closed. What it built — the `use` statement, the static-prefix guard, tuple and record
destructuring from a `use`, the lowering contract — holds under the effect surface of
[`24-effects-by-return`](../24-effects-by-return/README.md) (decisions 118–128), which owns the
`use` gate from here on. One box is open, and it is front 67's (§ *Open*).
**Owns (still):** the `use` rules in `src/parser.zig` (the activation statement, `useAfterBranchGuard`,
`useBranchSeen`, `bindingUseLoc`, `freshUseScope`) and the `use` prefix in `src/parser/exprs.zig` ·
the `use` binding functions of `src/comptime/infer.zig` (`bindingSourceType`, `inferUseHookExpr`,
`validateUseBase`, `bindUseDestructure`) · the `useHook` lowering arm of the four emitters ·
`docs.md` § use · the `tests/language` `use` cells. The `use` *gate* (which return grants `use`) is
front 24's (`contextInfoFromReturn`, `FnContext.annotated` / `env.inContextFn`).

Paths are relative to `repository/botopink-lang/modules/compiler-core/`. Decisions:
[87](../../decisions-taken.md#87-the-boundary-directives-stay-library-decorators--use-never-leaves-a-function-body)
the boundary directives are library decorators and `use` never leaves a function body ·
[88](../../decisions-taken.md#88-use-lowers-transparently-and-a-component-is-context-fn----element)
`use f(x)` lowers to `f(x)` on every backend · [96](../../decisions-taken.md#96-one-contextbase-per-function-and-element-carries-its-base)
one base per body · [104](../../decisions-taken.md#104-only-use-grants-use--decisions-89-and-90-revoked)
one grant of `use` · [108](../../decisions-taken.md#108-getcontex--getcontext) `getContext` ·
[118](../../decisions-taken.md#118-the-return-type-is-the-annotation) the return is the annotation ·
128 one context wrapper, `@Component<C, T>`.

[`surface.md`](./surface.md) is the per-construct table.

---

## The surface

**Two roles, one keyword.** `use` is a lexer keyword. As a **declaration** it is `DeclKind.use:
ImportDecl` — the `import { … } from "…"` form and the **activation statement** `Name*;`
(`ImportDecl.activationOnly`): `import { name* }` opts an imported `implement` / `extend` into scope;
a bare `Name*;` at module level is always refused (`redundantActivation` for a local extension, else
`notAnExtension`). As an **expression prefix** it is `Expr.useHook`: `use <call>`, a prefix operator
whose operand is a whole expression; the binding is never part of `use`.

**The grant** (decisions 104, 118, 128). Only a function whose written return is
`@Component<C, T>` may `use`. `C` is the context base; `T` is what the function returns:

- a **hook** returns any `T` — `fn state<T>(initial: T) -> @Component<ElementBase, State<T>>`;
- a **component** returns a `T` that `implement`s `@Context<C>` —
  `fn Card() -> @Component<ElementBase, Element>`. A component is **called** (`Card()`), never
  `use`d.

`use f()` requires `f` to be a hook at the body's base; every `use` in one body shares the base
(96); a function that activates nothing is a plain `fn … -> Element`. `@Component ⊃ @Task`, so a
hook or component may `await`; `throw` / `try` only where `T` is a `@Result` (121).
`@getContext(T)` reads the active provider of `T` under the same grant (108).

**The static prefix.** `use` must come before any `if` / `case` / loop / `return` of its block, at
any nesting; a fn, method, `test` or lambda body starts its own prefix. The guard is switched on in
`parseStmtListInBraces` — a syntactic rule, independent of the return type.

**What the binding gets.** The typed `useHook` node's type is `bindingSourceType(operand type)` — the
`T` of the hook: `val c = use state(0)` binds `c : State<i32>`; `val {value, set} = use state(0)`
binds by field name; `val #(a, b) = use …` binds each name to the element of a tuple `T` at its
position, commits an unresolved `T` (a generic hook) to a tuple of the pattern's arity, and refuses
another arity or a non-tuple `T` at the binding (`use-tuple-arity`, decision 67). Without `use`, a
hook call is an ordinary call and its type is the wrapper.

**Lowering.** `use f(x)` is `f(x)` on every backend (88); no rename, no inferred dependency array.
On commonJS every `@Component` body is an `async function` and a caller `await`s it; erlang, wasm and
beam are eager and `await` is the identity.

## The rule for libraries

1. **A hook** is `pub fn <noun>(…) -> @Component<Base, T>` — **no `use` prefix in its name**; the
   keyword is the activation, the name is the noun of what is yielded: `state`, `effect`, `memo`,
   `ref`, `reducer`, `router`, `pathname`, `params`, `searchParams`, `selectedLayoutSegment`,
   `selectedLayoutSegments`, `linkStatus`, `formStatus`, `actionState`, `optimistic`, `request`.
   camelCase. `Base` is the library's (`Element implement @Context<ElementBase>` in jhonstart, 96).
   A hook that composes hooks is the same shape and `use`s them.
2. **Activation** is `val x = use <noun>(…)` (or a bare `use <noun>(…);`, or
   `val {a, b} = use …`, or `val #(a, b) = use …`) in the static prefix of a `@Component` body.
   Never `use use<Noun>()`.
3. **The same fn called without `use` is an ordinary call** — the SSR / first-render value; the
   binding's type is the wrapper.
4. **A component** is `fn … -> @Component<Base, Element>` and is called, never `use`d. A function
   that activates nothing is a plain `fn … -> Element`.
5. **A binding from a hook never reuses the hook's name.** `val router = use router()` shadows the
   imported fn for the rest of the module's inference (`surface.md` § 4). Write
   `val r = use router()`, `val path = use pathname()`.
6. **Type constructors stay PascalCase** (`ActionState(…)`, `FormStatus(…)`, `LinkStatus(…)`,
   `RouterState(…)`); a *helper* that builds a value of that type takes a verb (`parseActionState`,
   `newActionState`), never the bare noun the hook owns.

## Cells

`tests/language`, green on commonJS, erlang, wasm and beam: `test/context_use.bp`,
`run/context_use.bp` (hooks, components, record and tuple destructure — `Liked()` — and a function
that activates nothing), `run/use_one_base.bp`;
`reject/use_{after_return,inside_branch,in_plain_fn,without_context_effect,owner_mismatch,at_module_level,in_closure,two_bases,of_component,under_task,tuple_arity,tuple_of_non_tuple}.bp`.
Codegen snapshots `codegen_use_*_is_a_plain_call`, `codegen_use_object_destructure_*`,
`codegen_use_tuple_destructure_*`; `grep -rl useState snapshots/` is empty.

## Open

- [ ] `67-jhonstart-forms/examples/optimistic-like-example.bp` compiles with the tuple form — the
      hooks it imports (`optimistic`, `formStatus`) live in jhonstart's `jhonstart-forms` member;
      compiling the example is front 67's.

## Notes

- The labeled-tuple half (`#(state: S, dispatch: fn(…))` losing its labels through generic
  instantiation) is C-08 / `01-checker`'s; this front's destructure is positional.
- Decision 8 § 5.1 P6 is the tuple *pattern* `#(a, b)` in `case`, a sibling of the binding form.
- The `use` prefix is **not** React's `use(promise)` (`04-jhonstart/unification.md` § 4).
- The provider stack behind `@getContext` has no front yet.

# Front 19 — the `use` activation: hooks, components, and the boundary directives

**Track:** compiler (carry-over item **C-27**)
**Priority:** high — jhonstart's whole hook and component surface (fronts 26–32, 67, 94) is written against `use`, and the language reference (`repository/botopink-lang/docs.md`, 670 lines) does not document it: `grep -n 'Context\|\buse\b' docs.md` hits two prose lines (`:34`, `:70`) and no construct.
**Depends on:** C-08 (parser gaps) for the tuple-pattern half of step 3; C-01 only where a row names it.
**Owns:** the `use` rules in `src/parser.zig` (the activation statement `:394-397`, `useAfterBranchGuard` `:697`, `:737-745`, `:772`) and `src/parser/exprs.zig:116-124` · `src/comptime/infer.zig`'s `@Context` functions (`contextBaseFromImplements` `:963`, `contextInfoFromReturn` `:976`, `contextBaseOfType` `:1002`, `bindingSourceType` `:1020`, the body scope `:3009-3013`, `inferUseHookExpr` `:8134`, `validateUseBase` `:8160`, `bindUseDestructure` `:8176`) · the `useHook` lowering in the four emitters (`codegen/commonJS.zig:2372-2398`, `:2466-2526`, `:2966`; `codegen/erlang.zig:5216`; `codegen/wat.zig:2814`; `codegen/beam_asm.zig:2912`) · `docs.md` § the section step 1 adds · `tests/language/**` cells for `use` · `snapshots/**` re-records those cells cause.
**Does not touch:** jhonstart's own files (`repository/jhonstart/src/hooks.bp`, `router.d.bp`, `docs.md`) — the library front rewrites its hooks to the rule stated here; this front specifies the rule. `00-compiler-carry-over/18-comptime-runtimes/` (another front, in flight).

Paths are relative to `repository/botopink-lang/modules/compiler-core/` unless a row says otherwise. Every `file:line` was read at `botopink-lang` `d55a3b87`, `jhonstart` `13d1672`, meta `b5ceb203` (2026-09-20). Nothing was compiled or run: every outcome below is **derived from the cited lines**, and the rows say so. [`surface.md`](./surface.md) is the per-construct table; [`evidence.md`](./evidence.md) holds the excerpts.

---


> **Decisions taken 2026-09-20 (after this front was written):** 87 — answered `[A]` (library decorators) where (d) was recommended; held for confirmation in [`decisions-pending.md`](../../decisions-pending.md); [88](../../decisions-taken.md#88-use-lowers-transparently-and-a-component-is-context-fn---element) — `use f(x)` lowers to `f(x)` on every backend **and a component is `#[@Context] fn … -> Element`**, with `Element` implementing the context behavior — this amends *The rule for libraries* below (a component was "any `fn … -> Element`"); [89](../../decisions-taken.md#89-future-is-unwrapped-for-the-context-owner) — `@Future<T>` is unwrapped for the owner. Steps 2, 4 and 5 implement the answers; the option text is kept as the record.

## Problem

A reader of the jhonstart specs found `val router = use useRouter();` (`04-jhonstart/26-jhonstart-router/README.md:370`, `:377`, its examples, front 27's `use useLinkStatus()`, front 67's `use useActionState(…)` — 17 sites, `grep -rn "use use" specs/1.0.10-beta/04-jhonstart` before this front). The keyword and a React-style `use` prefix doubled, because nothing documents that the keyword *is* the activation and the name is the noun. The library itself has the same doubling: `router.d.bp:25` declares `useRouter`, `hooks.bp:100` a custom hook `useCounter`, `examples/jhonstart-todo/src/main.bp:28` writes `use useToggle(true)`. Only `hooks.bp:30-58` (`state`, `effect`, `memo`, `ref`, `reducer`) is spelled the way the language intends.

Three things a framework needs from `use` do not exist:

1. **`use` inside a server component.** A server component returns `@Future<Element>` (`28-jhonstart-server-components/README.md:253`, `:289`); `contextInfoFromReturn` (`infer.zig:976-990`) recognises only a `@Context<…>` return or a named type whose inline `implement` lists `@Context`, so `use request()` in that body is `use-of-non-context-fn` (`language-gaps.md` row "`use` is legal only on `@Context<Element, _>` inside a `-> Element` body").
2. **A stated lowering contract.** On commonJS the prefix is *not* transparent: `use state(0)` emits `useState(0)` (`commonJS.zig:2477-2486`), a free identifier the module never imports — `jhonstart-counter/out/main.js:20` imports `state`, `:34` calls `useState(0)`. On erlang, wasm and beam the prefix is transparent (`erlang.zig:5216`, `wat.zig:2814`, `beam_asm.zig:2912`). A hook named by the rule (`fn counter(…)`) called as `use counter(5)` therefore emits `useCounter(5)` — undefined at run time on the one target the hooks run on.
3. **A spelling for the boundary directives.** Next's `'use client'` / `'use server'` / `'use cache'` are written three different ways across the specs (`#[client]` 92 occurrences, `'use server'` 10, `#[useCache]` 3, `'use cache'` 21 — measured below), none of them a language construct.

## Current state

Measured by reading the code; no row was executed. "Element" below is `type Element(…) implement @Context<Element, Element>` (`repository/jhonstart/src/element.bp:8`; the test cells write `val Element = type implement @Context<Element, Element> { }`, `comptime/tests/effects.zig:244`).

| # | Program | Parses | Infers | commonJS | erlang · wasm · beam | Derived from |
|---|---|---|---|---|---|---|
| 1 | `fn C() -> Element { val c = use state(0); … }` | yes | yes — `c : State<i32>` (`R`) | `const c = useState(0)` | `state(0)` — plain call | `parser/exprs.zig:118-124` · `infer.zig:3011-3013`, `:8134-8151`, `:1020-1027` · `commonJS.zig:2372-2376`, `:2477-2486` · `erlang.zig:5216`, `wat.zig:2814`, `beam_asm.zig:2912`; recorded: `snapshots/codegen/commonJS/codegen_use_tuple_destructure_state_to_usestate.snap.md` |
| 2 | `#[@future] fn P(params) -> @Future<Element> { val r = use request(); … }` | yes | **no** — `use-of-non-context-fn: `use` not allowed: function returns '@Future<Element>'` | — | — | `infer.zig:979-989` (only `Context` or a named type with `contextBase`) · `error.zig:335` |
| 3 | `fn f() -> string { val x = use state(0); … }` | yes | **no** — same diagnostic, `'string'` | — | — | `infer.zig:8135-8142`; cell `comptime/tests/effects.zig:293-302` |
| 4 | `fn C() -> Element { if (a) { … }; use effect { … }; … }` | **no** — `` `use` must be in static prefix`` | — | — | — | `parser.zig:737-745`, `print.zig:88-91`; cell `parser/tests/errors.zig:52-69` |
| 4b | `fn C() -> Element { return x; val c = use state(0); }` | **yes** — the guard tests the statement's *first* token (`this.check(.use)`), and this statement starts with `val` | yes | `useState(0)` after the `return` | plain call | `parser.zig:738` — a hole in the static-prefix rule; step 1 closes it |
| 4c | `fn C() -> Element { if (a) { use effect { … }; } … }` | **yes** — `seenBranch` is local to each `parseBlockBody`; the inner block starts clean | yes | `useEffect(…)` inside the `if` | plain call | `parser.zig:735`, `:737-745` — the second hole |
| 5 | `fn C() -> Element { val f = { -> use state(0) }; … }` (nested closure) | yes | yes — a lambda resets `throwContext`, `starFn` and labels, **not** `fnContext` | `useState(0)` inside the arrow | plain call | `infer.zig:9100-9121` |
| 6 | custom hook `fn useAuth() -> AuthState` with `AuthState … implement @Context<Element, AuthState>` and `use state(0)` in its body; `val {loggedIn} = use useAuth()` in a component | yes | yes | `useAuth()` passes through (already `use`+Upper) | plain call | cell `effects.zig:280-297`; `commonJS.zig:2480-2483` |
| 6b | custom hook by the rule: `fn counter(n) -> @Context<Element, State<i32>> { return state(n); }`; `val c = use counter(5)` | yes | yes — the body's `return` is checked against `R` | **`useCounter(5)`** while the definition is `function counter` — ReferenceError at run time | `counter(5)` | `infer.zig:3360-3362` · `commonJS.zig:2484-2485`; the definition side: the snapshot above emits `function state(initial)` and calls `useState(0)` |
| 7 | `val {value, set} = use state(0)` | yes | yes — each name bound to the field of `R` by name, fresh var if unknown | `const { value, set } = useState(0)` | plain call, then the `val`'s destructure | `infer.zig:7371-7372`, `:8180-8193`; `commonJS.zig:2382-2391`; recorded `codegen_use_object_destructure_state_to_usestate.snap.md` |
| 8 | `val #(shown, push) = use optimistic(b, f)` | **yes** — `parser/exprs.zig:661-676` | yes, but every element is a **fresh type var** — `R`'s tuple element types are not propagated | `const [ shown, push ] = useOptimistic(b, f)` | plain call, then the tuple destructure | `infer.zig:8194-8196`; recorded `codegen_use_tuple_destructure_state_to_usestate.snap.md`. `67-jhonstart-forms/README.md:358` ("no array or tuple destructuring in a binding") was stale — corrected by this front's sweep |
| 9 | hook called without `use`: `val c = state(7); c.value` (SSR / first-render value) | yes | the binding is typed `@Context<Element, State<i32>>` — `bindingSourceType` runs only under `use` (`:8150`); the member access on it type-checks in the library's own test but the unwrap site was not located — **unverified** | `const c = state(7)` | plain call | `jhonstart/src/hooks.bp:69-73` (executed by `zig build test-libs`); `jhonstart-counter/out/main.js:51`; `infer.zig:8150` |
| 10 | `Name*;` at module level | yes | **always an error today**: `redundantActivation` if `Name` is a local extension, else `notAnExtension` | emits nothing | erlang: a comment; wasm/beam: skipped | `parser/decls.zig:219-225`, `:263-272`; `infer.zig:879-899`; `commonJS.zig:1999-2000`; `erlang.zig:1396`; `wat.zig:290`; `beam_asm.zig:1159` |
| 11 | `import { x* } from "…"` | yes | `env.activations.put("x")` — opts an imported extension in | a `require` | import forms | `parser/decls.zig:247`; `infer.zig:897` |

Two more facts the table rests on:

- The static-prefix guard is switched on in **`parseStmtListInBraces` (`parser.zig:772`)** — every brace-delimited block the parser reads through it (fn bodies, `test` bodies, `if` branches via `parseBlockOrExpr` `:779-781`), not only `-> Element` bodies. It is a syntactic rule, independent of the return type.
- The language suite has **no `use` cell**: `grep -rl 'use state\|@Context' tests/language` hits nothing; `tests/language/AGENTS.md:393` records the reason — "`@Context` / `use` (lowers to React hooks on commonJS, no erlang lowering — it needs a host framework)". The construct is exercised only by compiler-core unit cells (`parser/tests/errors.zig:52`, `parser/tests/expressions.zig:19`, `comptime/tests/effects.zig:243-380`, `comptime/tests/infer_errors.zig:661`, `codegen/tests/features.zig:196-250`).

## Mechanism

**Two roles, one keyword.** `lexer.zig:752` makes `use` a keyword. (1) As a **declaration** it is `DeclKind.use: ImportDecl` (`ast.zig:1934`) — the `import { … } from "…"` form (`parser.zig:385-387`) and the **activation statement** `Name*;` (`parser.zig:394-397`, `ImportDecl.activationOnly` `ast.zig:57`). Activation is about *extensions*: `import { name* }` opts an imported `implement`/`extend` into scope (`infer.zig:879-899`, "Rule B"); the bare `Name*;` names a local symbol and is refused either way. (2) As an **expression prefix** it is `Expr.useHook` (`ast.zig:198`, `:602-621`): `use <call>`, parsed by `parser/exprs.zig:116-124` as a prefix operator whose operand is a whole expression. The binding is never part of `use` — "`val`/`var` handle it" (`ast.zig:605-609`).

**Capability from the return type.** `inferFnDecl` computes `env.fnContext` from the declared return type before visiting the body (`infer.zig:3009-3013`; `:3277-3279` for `implement` methods): `contextInfoFromReturn` (`:976-990`) answers `implementsContext = true, base = B` for `-> @Context<B, R>` directly, or for `-> T` where `T`'s registered definition carries `contextBase` — which `registerRecord` fills from an inline `implement @Context<B, _>` (`:1062-1070`, `contextBaseFromImplements` `:963-974`). Anything else (`string`, `void`, `@Future<Element>`) is `implementsContext = false`, and every `use` in that body is `useNotAllowed` (`:8135-8142`, message `error.zig:335`).

**Agreement on the ContextBase.** `inferUseHookExpr` (`:8134-8152`) infers the operand, then `validateUseBase` (`:8160-8172`) requires the operand's type to implement `@Context` (`contextBaseOfType` `:1002-1016`; else `useNotContext`, `error.zig:336`) and its `B` to equal the enclosing fn's `B` (else `contextMismatch`: "context-anchor-violation: function returns @Context<Element, _> but `use` returns @Context<Http, _>", `error.zig:337`). A fn returning `@Context` with no base (`fc.base == null`) accepts any hook (`:8168`). The same anchor is what `@getContex(T)` checks under `#[@context]` (RC3, `:4389-4400`) — the `#[@context]` effect exists (`print.zig:108`, `infer_errors.zig:664`) and is orthogonal to `use`: a hook returns `@Context<B, X>` "with or without `#[@context]`" (`:3358-3362`).

**What `R` becomes.** The typed `useHook` node's type is `bindingSourceType(operand type)` — the second argument of `@Context<B, R>` (`:1020-1027`, `:8150`). So `val c = use state(0)` binds `c : State<i32>`; `val {value, set} = use state(0)` binds by field name on `R` (`:8180-8193`); `val #(a, b) = use …` binds fresh vars (`:8194-8196`). Without `use`, the call's type is `@Context<B, R>` itself.

**The static prefix.** `parseBlockBody` (`parser.zig:720-765`) with `useAfterBranchGuard` set (`:772`, every `parseStmtListInBraces` block) flags `seenBranch` on a statement that *starts* with `if`, `return`, `loop` or `case` (`:742-743`) and refuses a later statement that *starts* with `use` (`:738-741`, `useAfterBranch`, message `print.zig:88-91`). Rows 4b/4c: the check reads the first token only, so `val c = use …` after a `return` and a `use` inside a branch's own block both pass. This is the Rules-of-Hooks idea made syntax, and it is currently two tokens short of it.

**Lowering.** erlang (`erlang.zig:5214-5216`), wasm (`wat.zig:2812-2814`) and beam (`beam_asm.zig:2910-2912`) treat `use` as a transparent prefix and lower the operand. commonJS does not: `buildStmt` (`commonJS.zig:2372-2376`, `:2382-2391`, `:2398`) and `buildExpr` (`:2966`) route the operand through `buildHookCall` (`:2490-2511`), which (a) renames a bare callee by the React convention `state → useState` (`hookName` `:2477-2486`; a callee already `use[A-Z]…` passes through), (b) appends an inferred dependency array for `memo`/`effect`/`callback`/`layoutEffect`/`imperativeHandle` (`hookTakesDeps` `:2469-2473`, `buildHookDeps` `:2513-2526`, the names bound by earlier hooks in `hook_state` `:815`), and (c) leaves a receiver call (`x.hook()`) unrenamed (`:2500-2503`). The renamed identifier is never imported or declared — `jhonstart-counter/out/main.js:20` vs `:34`. Five hook names and one naming convention of one host framework live in the compiler; the ecosystem rule is that the compiler knows none of the libraries (`feedback_no_lib_specific_in_core`; `29-jhonstart-client-directive` and `hooks.bp:9-11` both *describe* this lowering as "the target's hook convention").

## The rule for libraries

This is the normative surface. It is what the code enforces today, minus the commonJS rename (step 5), plus the two holes of the guard (step 1).

1. **A hook** is `pub fn <noun>(…) -> @Context<Owner, R>` — **no `use` prefix in its name**. The keyword is the activation; the name is the noun of what is yielded: `state`, `effect`, `memo`, `ref`, `reducer`, `router`, `pathname`, `params`, `searchParams`, `selectedLayoutSegment`, `selectedLayoutSegments`, `linkStatus`, `formStatus`, `actionState`, `optimistic`, `request`. camelCase, as every botopink function (`feedback_camelcase_naming`).
2. **Activation** is `val x = use <noun>(…)` (or a bare `use <noun>(…);` for a void hook, or `val {a, b} = use <noun>(…)`), in the **static prefix** of a body whose return type is `Owner` — a component, `fn … -> Element` — or implements `@Context<Owner, _>` — a **custom hook** composing hooks. Every `use` in one body agrees on `Owner`. Never `use use<Noun>()`.
3. **The same fn called without `use` is an ordinary call** — the SSR / first-render value. Legal today (row 9): the call is `inferCallExpr`, the binding's type is `@Context<Owner, R>`, the four backends emit the call. This is how `jhonstart-counter`'s `StatefulBadge` (`main.bp:35-42`), `hooks.bp`'s tests and `04-jhonstart/test-snap.md`'s server-pass cases read a hook.
4. **A component** is `fn … -> Element`; a **server component** is `#[@future] fn … -> @Future<Element>` (step 2 makes `use` legal there); a **custom hook** returns `@Context<Element, R>` or a named type that `implement @Context<Element, _>`.
5. **A binding from a hook never reuses the hook's name.** `val router = use router()` shadows the imported fn for the rest of the module's inference — `env.bindings` is one flat `StringHashMap` (`comptime/env.zig:346-347`, `:841-847`), and `inferFnDecl` restores nothing on exit (the only restore is `restorePatternBindings` for `case` arms, `infer.zig:5440-5450`). Derived, not run; `surface.md` § shadowing records it as unverified. Write `val r = use router()`, `val path = use pathname()`.
6. **Type constructors stay PascalCase** (`ActionState(…)`, `FormStatus(…)`, `LinkStatus(…)`, `RouterState(…)`); a hook and a constructor of the same noun therefore never collide. A *helper* that builds a value of that type takes a verb (`parseActionState`, `newActionState`), never the bare noun the hook owns — `04-jhonstart/67-jhonstart-forms/README.md` § *Naming under the `use` rule* applies this.

## Steps

### Step 0 — Measure

In a scratch worktree of `repository/botopink-lang` (never in place), compile the eleven programs of *Current state* on the four targets and record the outcome beside each row; the rows are derived, this step makes them measured. Then count the doubled spellings in the ecosystem: `grep -rnE '\buse use|fn use[A-Z]' repository/jhonstart` (expected: `router.d.bp:25`, `hooks.bp:100`, `examples/jhonstart-todo/src/main.bp:28`, plus `docs.md:57`) — these are the library front's, listed here so the count is known.

**Acceptance:** each row of the table carries "measured" or the corrected outcome; `04-jhonstart/README.md` § *Written with `use`* links this file.

### Step 1 — Document `use` and `@Context`, and close the guard's two holes

`docs.md` gains a section (under *Expressions*, `docs.md:296`, and a pointer from *Functions*, `:493`) with the exact grammar:

```
UseExpr        := "use" Expr                       // prefix; operand is a call
ActivationStmt := DottedName "*" ";"               // module level only
ImportItem     := DottedName "*"? ("as" Ident)?
```

and the rules: (a) `use` is legal only in a body whose return type implements `@Context<Owner, _>`; (b) the operand's type must implement `@Context<Owner, _>` with the same `Owner`; (c) the expression's type is `R`; (d) **static prefix** — every `use` precedes every `if`, `case`, `loop` and `return` of the *function body*, at any nesting; (e) without `use` the call is ordinary. The four diagnostics verbatim: `useAfterBranch` (`print.zig:88-91`), `use-of-non-context-fn` ×2 and `context-anchor-violation` (`error.zig:335-337`), plus `redundantActivation`/`notAnExtension` for the statement (`error.zig:341-343`).

Close the holes: `parseBlockBody` tests the *statement* for a `useHook` anywhere at its top level (a `val`/`var` whose value is `useHook`, or a bare `useHook`) — `commonJS.zig:160-165` `useHookInner` is the shape to reuse — and `seenBranch` is threaded into nested blocks of the same fn body (a lambda body starts clean: it is another function). Add cells: `parser/tests/errors.zig` for rows 4b and 4c; `tests/language/` gets its first `use` cells — the static-prefix rejections are backend-free (`reject/`), and rows 1, 3, 6b, 7, 8 run on erlang/wasm/beam where the prefix is transparent (the AGENTS.md:393 reason applies only to commonJS's rename, which step 5 removes).

**Acceptance:** `docs.md` documents both roles with the grammar above; rows 4b/4c are parse errors with the existing message; `tests/language` has ≥ 5 `use` cells green on erlang; `hooks.bp:104-117` still type-checks unchanged.

### Step 2 — `use` inside `#[@future] fn … -> @Future<Element>`

The gap (`language-gaps.md` row "`use` is legal only on `@Context<Element, _>` inside a `-> Element` body"; front 28 keeps `server.d.bp` gated for it). Two rules are possible:

| Option | Rule | Consequence |
|---|---|---|
| (a) **unwrap the effect** | `contextInfoFromReturn` looks through `@Future<T>` (and only `@Future`) and takes `T`'s base: `-> @Future<Element>` has `Owner = Element` | `use request()` requires `request : -> @Context<Element, Request>`, not `@Context<Http, Request>` as `server.d.bp:26` declares — the server hook's owner becomes the tree it renders into. One base per render tree, which is what RC2/RC3 already assume. `#[@future]` bodies keep `await` in their static prefix (an `await` is not a branch). |
| (b) **the hook owns the future** | `request : -> @Context<@Future<Element>, Request>`; `contextBaseOfType` renders the base as the string `@Future<Element>` | Two anchors for one tree; a client hook (`state`, owner `Element`) becomes `contextMismatch` inside a server component — which is *correct* (a server component has no client state) but reached by an accident of string equality, and every server hook must be redeclared per effect. |

**Recommendation: (a)**, with the explicit consequence that a client hook is then *type-legal* in a server component. Decision 67 asks for the stricter side unless it invents semantics — and (b) invents an anchor that is not a type. The strictness (a) loses is recovered where it belongs: front 29's client boundary (`#[client]`) is the rule that says which hooks a server body may activate, and front 28's `request()` is declared with owner `Element`. This is raised as **question 89** below because it changes a type rule.

**Acceptance:** `#[@future] fn Page(params) -> @Future<Element> { val req = use request(); … }` infers with `request : -> @Context<Element, Request>`; the same body with `-> @Future<string>` is `use-of-non-context-fn`; `language-gaps.md` row 53 closes; `jhonstart/examples/jhonstart-app/app/posts/[id]/page.bp:26` compiles.

### Step 3 — Destructuring from a `use`

`val {a, b} = use …` works (row 7). `val #(a, b) = use …` parses and lowers but its elements are fresh vars (row 8): `bindUseDestructure` (`infer.zig:8194-8196`) must bind each name to the corresponding element of `R` when `R` is a tuple type (`ast.zig:1763` `tuple_: []TypeRef`), and refuse an arity mismatch. The labeled-tuple half (`#(state: S, dispatch: fn(…))` losing its labels through generic instantiation, `hooks.bp:75-77`) stays with C-08 / front 01; this step is the positional half only.

**Acceptance:** `val #(shown, push) = use optimistic(12, addLike)` binds `shown : i32`, `push : fn(action: i32)`; `val #(a) = use optimistic(…)` is an arity error; `67-jhonstart-forms/examples/optimistic-like-example.bp` compiles with the tuple form (the sweep already writes it).

### Step 4 — The boundary directives (question 87)

Measured across `specs/1.0.10-beta` (`grep -rhoE … | wc -l`): `#[client]` **92** (04-jhonstart 15 in 9 files, 06-onze 5, absorbed 6; the decorator is front 29's); `'use client'` 33 (all prose naming Next); `'use server'` **10** (02-packaging 1, 03-rakun/24 2, 06-onze/53 1, absorbed 3); `#[useCache]` **3** (03-rakun/12); `'use cache'` 21 (03-rakun/12 2, 03-rakun/modules.md 1, language-gaps.md 1, absorbed 4, prose); `#![…]` inner attribute 3 (03-rakun/12 1, language-gaps.md 1, absorbed 1); `#[server]` 0. So today: client = a decorator the library defines, server = a string in prose, cache = a proposed inner attribute nobody parses.

**Question 87 — for `decisions-pending.md` (the coordinator numbers it).**
**Raised by:** `00-compiler-carry-over/19-use-activation` step 4.
**Measured.** The three directives above; the parser already has an activation statement `Name*;` (`parser.zig:394-397`) that is *always* an error at inference (`infer.zig:891-897`) — a free production. `#[client]` is a decorator resolved by jhonstart (front 29), so the compiler cannot act on it; `language-gaps.md` proposes `#![useCache]` and the language has no inner attribute.
**Options.** (a) **keep the library decorator** `#[client]` / `#[server]` / `#[cache]` — the compiler knows nothing, front 68's bundler splits by reading jhonstart's emitted marker; (b) **a module-level activation on the same keyword**: `client*;` / `server*;` / `cache*;` — reuses the parsed `Name*;` form, but `*` means "opt an extension in" and these are not extensions; (c) **an inner attribute** `#![client]` — a new production, module-level only, library-defined like (a); (d) **a `use` directive that names the module's *target***: `use client;` / `use server;` — new production (`"use" Ident ";"` at module level), understood by the compiler as "this module's code runs on the `client`/`server` half of the project's target split" — library-agnostic, because a *target* is something the compiler already knows (the `botopink.json` target and the `--target` flag); `cache` is not a target and stays a library decorator (`#[cache]`, front 12).
**Recommendation.** (d) for `client`/`server`, (a) for `cache`, and under decision 67: a module carrying `use client;` may not declare a `#[@External.Erlang]` cell and a module carrying `use server;` may not activate a hook whose owner is `Element` — refusals, not warnings, and no flag. Rejected: (b), because it overloads `*`; (c), because an attribute the compiler ignores is (a) with more syntax. Until answered, the specs keep `#[client]` (front 29 owns it) and `'use server'` stays prose.
**Blocks.** Nothing in 1.0.10 — front 29 ships `#[client]`; the front that lands (d) rewrites 29's 5 occurrences, 26/27/31's 5, and 03-rakun/24's 2.

### Step 5 — The lowering contract per backend (question 88)

**Question 88 — for `decisions-pending.md`.**
**Raised by:** this front, *Current state* rows 1, 6b.
**Measured.** commonJS renames `use <noun>(…)` to `use<Noun>(…)` and appends a deps array for five names (`commonJS.zig:2469-2526`); the emitted name is never declared (`jhonstart-counter/out/main.js:20`, `:34`; the recorded snapshot `codegen_use_tuple_destructure_state_to_usestate.snap.md` defines `function state` and calls `useState`). erlang, wasm and beam lower `use f(x)` to `f(x)`. `hooks.bp:9-11` and `docs.md:41-43` (jhonstart) describe the rename as the design.
**Options.** (a) **transparent on every backend** — `use f(x)` lowers to `f(x)`; the client runtime supplies hook semantics by *what `f` does*, i.e. jhonstart's `state` becomes a `#[@External.Node("jhonstart/client-runtime", "state")]` cell on the client build and stays the pure SSR body on the server build (front 29's split already exists for cells); dependency arrays are the hook's own argument (`memo(compute, deps)` already takes `deps: any[]`, `hooks.bp:43`), not inferred by the compiler; (b) **keep the rename and make it explicit** — `#[@hook("useState")]` on the hook declaration names the host identifier, the compiler emits an import for it; (c) keep as is.
**Recommendation.** (a). It is the only option under which the compiler knows no library (`feedback_no_lib_specific_in_core`), the only one under which the four backends agree, and the only one under which row 6b (a hook named by the rule) runs. Decision 67: (c) is a silent ReferenceError and is refused outright; (b) is a knob. Consequence: `hookName`, `hookTakesDeps`, `buildHookDeps`, `hook_state` (`commonJS.zig:813-815`, `:2466-2526`) are deleted; the four commonJS snapshots re-record to plain calls; `tests/language/AGENTS.md:393`'s exclusion is lifted.
**Blocks.** jhonstart's client runtime (front 29/68) — it must provide `state`/`effect`/`memo` as cells on the client build; nothing in 1.0.10's server-side fronts.

## Gate

- `docs.md` documents `use` (both roles), `@Context<Owner, R>`, the static-prefix rule and the six diagnostics — step 1.
- Rows 4b and 4c are parse errors; `parser/tests/errors.zig` has both cells — step 1.
- `tests/language` has `use` cells green on erlang, wasm and beam — step 1.
- `use` in a `#[@future] fn … -> @Future<Element>` body infers under rule (a) or the answer to 89 — step 2.
- `val #(a, b) = use …` binds element types — step 3.
- Questions 87, 88, 89 are in `decisions-pending.md` — steps 2, 4, 5.
- `grep -rn "use use" specs/1.0.10-beta/04-jhonstart repository/jhonstart` → 0; `grep -rnE '\bfn use[A-Z]' specs/1.0.10-beta/04-jhonstart` → 0 (done by this front's sweep, kept by the gate).

## Blast radius

**Spelling changes in jhonstart's specs** (done, 2026-09-20; `04-jhonstart/unification.md` § 6 is the row): `26-jhonstart-router/{README.md, examples/active-nav-example.bp, search-params-example.bp, carried-programmatic-navigation-example.bp, carried-route-params-example.bp}` · `27-jhonstart-link/{README.md, examples/pending-link-example.bp}` · `29-jhonstart-client-directive/README.md:197` · `67-jhonstart-forms/{README.md, examples/create-post-form-example.bp, optimistic-like-example.bp}` · `modules.md` · `test-snap.md` · `test-snap-examples.md` · `unification.md` · `README.md`. Fronts 28, 30, 31, 32, 94 write no hook and are untouched.

**jhonstart's own files (the library front, not this one):** `src/router.d.bp:25` (`useRouter`), `src/hooks.bp:100` (`useCounter`), `examples/jhonstart-todo/src/main.bp:28` (`useToggle`), `docs.md:57`.

**Compiler:** step 1 touches `parser.zig:737-745` and adds cells; step 3 touches `infer.zig:8194-8196`; step 5 (if 85 → (a)) deletes `commonJS.zig:2466-2526` and re-records `snapshots/codegen/commonJS/codegen_use_{effect_void_hook_empty_deps,memo_infers_dependency_array,object_destructure_state_to_usestate,tuple_destructure_state_to_usestate}.snap.md`; step 2 touches `infer.zig:976-990`.

## Notes

- `decisions-taken.md` (1.0.5) binds nothing here: `grep -n 'Context\|activation\|\buse\b' specs/1.0.5-beta/decisions-taken.md` finds one prose "use" (`:926`). Decision 8 § 5.1 P6 is the tuple *pattern* `#(a, b)` in `case` (`parser/patterns.zig:193-196`), a sibling of the binding form step 3 completes.
- The `use` prefix is **not** React's `use(promise)`: `04-jhonstart/unification.md` § 4 already records that Next's *Streaming de dados com `use`* is missed for that reason.
- `router.d.bp:25`'s `useRouter` is exactly the case row 6 makes work by accident (`use`+Upper passes `hookName` through). Under the rule it is `router()`, and front 26's Step 3 already redefines it from `snapshot()`.
- The `#[@context]` effect and `@getContex(T)` (`infer.zig:4370-4400`) are the provider side of the same anchor; they are not part of this front's surface and are not documented either — step 1 should at least name them.

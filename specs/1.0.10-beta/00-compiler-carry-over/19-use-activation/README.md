# Front 19 — the `use` activation: hooks, components, and the boundary directives

**Track:** compiler (carry-over item **C-27**)
**Priority:** high — jhonstart's whole hook and component surface (fronts 26–32, 67, 94) is written against `use`. The language reference did not document the construct at all when this front was written; it now carries § *use — imports, activation, and hooks* (step 1). What is left is steps 2 and 3.
**Depends on:** C-08 (parser gaps) for the tuple-pattern half of step 3; C-01 only where a row names it.
**Owns:** the `use` rules in `src/parser.zig` (the activation statement `:394-397`, `useAfterBranchGuard` `:697`, `:737-745`, `:772`) and `src/parser/exprs.zig:116-124` · `src/comptime/infer.zig`'s `@Context` functions (`contextBaseFromImplements` `:963`, `contextInfoFromReturn` `:976`, `contextBaseOfType` `:1002`, `bindingSourceType` `:1020`, the body scope `:3009-3013`, `inferUseHookExpr` `:8134`, `validateUseBase` `:8160`, `bindUseDestructure` `:8176`) · the `useHook` lowering in the four emitters (`codegen/commonJS.zig:2372-2398`, `:2466-2526`, `:2966`; `codegen/erlang.zig:5216`; `codegen/wat.zig:2814`; `codegen/beam_asm.zig:2912`) · `docs.md` § the section step 1 adds · `tests/language/**` cells for `use` · `snapshots/**` re-records those cells cause.
**Does not touch:** jhonstart's own files (`repository/jhonstart/src/hooks.bp`, `router.d.bp`, `docs.md`) — the library front rewrites its hooks to the rule stated here; this front specifies the rule. `00-compiler-carry-over/18-comptime-runtimes/` (another front, in flight).

Paths are relative to `repository/botopink-lang/modules/compiler-core/` unless a row says otherwise. *Current state* and [`surface.md`](./surface.md) are the **2026-09-20 baseline**, read before any of this front landed; what has changed since is the *Landed since* table below, and a row of the baseline that steps 1 and 5 overtook is marked there. [`evidence.md`](./evidence.md) holds the excerpts.

**Decided.** [87](../../decisions-taken.md#87-the-boundary-directives-stay-library-decorators--use-never-leaves-a-function-body): the boundary directives stay **library decorators** and `use` never leaves a function body — step 4 closes with **no compiler change**. [88](../../decisions-taken.md#88-use-lowers-transparently-and-a-component-is-context-fn---element): `use f(x)` lowers to `f(x)` on every backend, and a component is `#[@context] fn … -> Element` with `Element` implementing the context behavior — steps 1 and 5, **landed**. [89](../../decisions-taken.md#89-future-is-unwrapped-for-the-context-owner): `contextInfoFromReturn` looks through `@Future<T>` and takes `T`'s owner — step 2. [90](../../decisions-taken.md#90-a-wrapper-effect-whose-return-owns-a-context-activates-on-its-own): a fn carrying a **wrapper effect** (`#[@future]`) whose unwrapped return type owns a context activates hooks **without** `#[@context]`; R5 stands, so `#[@future] #[@context]` remains `effect-duplicate-annotation` — step 2's second half, **ready to write**.

---

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

### Landed since (compiler `feat`, 2026-09-20 — steps 1 and 5)

| What | Where | Decision |
|---|---|---|
| **`#[@context]` is the activating body's annotation.** `FnContext.annotated` is set by the lowercase effect `#[@context]` alone; a body whose return type implements `@Context` but carries no annotation is refused at the `use` — `` use-without-context-effect: `use` needs `#[@context]` on the enclosing fn 'Widget': its return type 'Element' implements @Context, but only a `#[@context]` body activates a hook ``. A capital `#[@Context]` is an unknown annotation, **silently ignored**; no alias was added | `comptime/infer.zig` (`contextInfoFromReturn`, the `use` arm), `comptime/error.zig` (`useWithoutContextEffect`), `comptime/diagnostics.zig` (`use_without_context_effect`) | 88, 67 |
| **The commonJS rename is gone.** `.useHook` is `buildExpr(inner)` in both statement and value position, as erlang, wasm and beam already were; `hookName`, `hookTakesDeps`, `buildHookDeps` and `hook_state` are deleted (0 occurrences in `codegen/commonJS.zig`). `use f(x)` is `f(x)` on **every** backend, and no dependency array is inferred — a hook that takes one declares it as a parameter | `codegen/commonJS.zig` | 88 |
| **The snapshots say so.** The four `codegen_use_*` cells are re-recorded and renamed to what they now assert (`…_is_a_plain_call`, `…_memo_is_a_plain_call_with_no_inferred_deps`) and exist once per target directory — 16 files; `grep -rl useState snapshots/` is empty | `snapshots/codegen/{commonJS,erlang,wasm,beam}/` | 88 |
| **Both holes of the static prefix are closed.** `useBranchSeen` is a parser field set by `if`/`case`/`loop`/`return` as they are parsed, so a `use` inside a branch's own block sees the branch (row 4c); `bindingUseLoc` reads the parsed statement, so `val c = use …` after a `return` is refused at the `use` token (row 4b); `parseFnBodyInBraces` carries `freshUseScope`, so a fn, method, `test` or lambda body starts its own prefix | `parser.zig` (`parseBlock`, `parseStmtListInBraces`, `parseFnBodyInBraces`, `bindingUseLoc`) | — |
| **`docs.md` documents both roles** — § *use — imports, activation, and hooks*: the three-production grammar (`ImportItem`, `ActivationStmt`, `UseExpr`), the hook/component/custom-hook shapes, and every diagnostic verbatim (`use-without-context-effect`, `use-of-non-context-fn` ×2, `context-anchor-violation`, `` `use` must be in static prefix ``, `redundantActivation`, `notAnExtension`), plus decision 87's "`use` never leaves a function body" and decision 88's lowering paragraph | `repository/botopink-lang/docs.md` | 87, 88 |
| **The language suite has `use` cells** — **8**: `test/context_use.bp`, `run/context_use.bp` and `reject/use_{after_return,inside_branch,in_plain_fn,without_context_effect,owner_mismatch,at_module_level}.bp`. They declare their own owner type (`type Element(…) implement @Context<Element, Element>`), so no host framework is needed. Green on commonJS, erlang, wasm **and** beam, with no line in `expected-failures.txt`; `tests/language/AGENTS.md`'s exclusion is lifted | `repository/botopink-lang/tests/language/` | 88 |

**What the baseline above no longer says.** *Current state* rows 1, 2, 6b, 7 and 8 and their commonJS columns, and the same columns of [`surface.md`](./surface.md) § 1 and § 3, describe the rename; it is deleted. Row 4b and row 4c are parse errors. Row 2 is step 2's, unchanged — `contextInfoFromReturn` still does not look through `@Future<T>`. Every row's inference outcome now also requires `#[@context]` on the enclosing fn, or a wrapper effect under decision 90.

## Mechanism

**Two roles, one keyword.** `lexer.zig:752` makes `use` a keyword. (1) As a **declaration** it is `DeclKind.use: ImportDecl` (`ast.zig:1934`) — the `import { … } from "…"` form (`parser.zig:385-387`) and the **activation statement** `Name*;` (`parser.zig:394-397`, `ImportDecl.activationOnly` `ast.zig:57`). Activation is about *extensions*: `import { name* }` opts an imported `implement`/`extend` into scope (`infer.zig:879-899`, "Rule B"); the bare `Name*;` names a local symbol and is refused either way. (2) As an **expression prefix** it is `Expr.useHook` (`ast.zig:198`, `:602-621`): `use <call>`, parsed by `parser/exprs.zig:116-124` as a prefix operator whose operand is a whole expression. The binding is never part of `use` — "`val`/`var` handle it" (`ast.zig:605-609`).

**Capability from the return type.** `inferFnDecl` computes `env.fnContext` from the declared return type before visiting the body (`infer.zig:3009-3013`; `:3277-3279` for `implement` methods): `contextInfoFromReturn` (`:976-990`) answers `implementsContext = true, base = B` for `-> @Context<B, R>` directly, or for `-> T` where `T`'s registered definition carries `contextBase` — which `registerRecord` fills from an inline `implement @Context<B, _>` (`:1062-1070`, `contextBaseFromImplements` `:963-974`). Anything else (`string`, `void`, `@Future<Element>`) is `implementsContext = false`, and every `use` in that body is `useNotAllowed` (`:8135-8142`, message `error.zig:335`).

**Agreement on the ContextBase.** `inferUseHookExpr` (`:8134-8152`) infers the operand, then `validateUseBase` (`:8160-8172`) requires the operand's type to implement `@Context` (`contextBaseOfType` `:1002-1016`; else `useNotContext`, `error.zig:336`) and its `B` to equal the enclosing fn's `B` (else `contextMismatch`: "context-anchor-violation: function returns @Context<Element, _> but `use` returns @Context<Http, _>", `error.zig:337`). A fn returning `@Context` with no base (`fc.base == null`) accepts any hook (`:8168`). The same anchor is what `@getContex(T)` checks under `#[@context]` (RC3, `:4389-4400`) — the `#[@context]` effect exists (`print.zig:108`, `infer_errors.zig:664`) and is orthogonal to `use`: a hook returns `@Context<B, X>` "with or without `#[@context]`" (`:3358-3362`).

**What `R` becomes.** The typed `useHook` node's type is `bindingSourceType(operand type)` — the second argument of `@Context<B, R>` (`:1020-1027`, `:8150`). So `val c = use state(0)` binds `c : State<i32>`; `val {value, set} = use state(0)` binds by field name on `R` (`:8180-8193`); `val #(a, b) = use …` binds fresh vars (`:8194-8196`). Without `use`, the call's type is `@Context<B, R>` itself.

**The static prefix.** `parseBlockBody` (`parser.zig:720-765`) with `useAfterBranchGuard` set (`:772`, every `parseStmtListInBraces` block) flags `seenBranch` on a statement that *starts* with `if`, `return`, `loop` or `case` (`:742-743`) and refuses a later statement that *starts* with `use` (`:738-741`, `useAfterBranch`, message `print.zig:88-91`). Rows 4b/4c: the check reads the first token only, so `val c = use …` after a `return` and a `use` inside a branch's own block both pass. This is the Rules-of-Hooks idea made syntax, and it is currently two tokens short of it.

**Lowering.** erlang (`erlang.zig:5214-5216`), wasm (`wat.zig:2812-2814`) and beam (`beam_asm.zig:2910-2912`) treat `use` as a transparent prefix and lower the operand. commonJS does not: `buildStmt` (`commonJS.zig:2372-2376`, `:2382-2391`, `:2398`) and `buildExpr` (`:2966`) route the operand through `buildHookCall` (`:2490-2511`), which (a) renames a bare callee by the React convention `state → useState` (`hookName` `:2477-2486`; a callee already `use[A-Z]…` passes through), (b) appends an inferred dependency array for `memo`/`effect`/`callback`/`layoutEffect`/`imperativeHandle` (`hookTakesDeps` `:2469-2473`, `buildHookDeps` `:2513-2526`, the names bound by earlier hooks in `hook_state` `:815`), and (c) leaves a receiver call (`x.hook()`) unrenamed (`:2500-2503`). The renamed identifier is never imported or declared — `jhonstart-counter/out/main.js:20` vs `:34`. Five hook names and one naming convention of one host framework live in the compiler; the ecosystem rule is that the compiler knows none of the libraries (`feedback_no_lib_specific_in_core`; `29-jhonstart-client-directive` and `hooks.bp:9-11` both *describe* this lowering as "the target's hook convention").

## The rule for libraries

This is the normative surface, as decisions 87–90 settled it. Items 1–3, 5 and 6 are what the code enforces today; item 4's server-component half is step 2.

1. **A hook** is `pub fn <noun>(…) -> @Context<Owner, R>` — **no `use` prefix in its name**, and **no annotation**: a hook that activates nothing needs none. The keyword is the activation; the name is the noun of what is yielded: `state`, `effect`, `memo`, `ref`, `reducer`, `router`, `pathname`, `params`, `searchParams`, `selectedLayoutSegment`, `selectedLayoutSegments`, `linkStatus`, `formStatus`, `actionState`, `optimistic`, `request`. camelCase, as every botopink function (`feedback_camelcase_naming`).
2. **Activation** is `val x = use <noun>(…)` (or a bare `use <noun>(…);` for a void hook, or `val {a, b} = use <noun>(…)`), in the **static prefix** of an **activating body** (item 4). Every `use` in one body agrees on `Owner`. Never `use use<Noun>()`.
3. **The same fn called without `use` is an ordinary call** — the SSR / first-render value, and it needs no annotation on its caller. Legal today (row 9): the call is `inferCallExpr`, the binding's type is `@Context<Owner, R>`, the four backends emit the call. This is how `jhonstart-counter`'s `StatefulBadge`, `hooks.bp`'s tests and `04-jhonstart/test-snap.md`'s server-pass cases read a hook.
4. **An activating body carries the effect, or has a wrapper effect that already answers for it** (decisions 88 and 90). A **component** is `#[@context] fn … -> Element` — a bare `fn … -> Element` is an ordinary function, and a `use` in it is `use-without-context-effect`. A **custom hook** composing hooks is `#[@context] fn <noun>(…) -> @Context<Element, R>` (or a named type that `implement @Context<Element, _>`). A **server component** is `#[@future] fn … -> @Future<Element>` and takes **no second annotation** — R5 allows one effect annotation per fn, and under decision 90 the wrapper effect activates on its own because `@Future<Element>` unwraps to the owner `Element`. The annotation is lowercase: `#[@Context]` with a capital is an unknown annotation the compiler silently ignores.
5. **A binding from a hook never reuses the hook's name.** `val router = use router()` shadows the imported fn for the rest of the module's inference — `env.bindings` is one flat `StringHashMap` (`comptime/env.zig:346-347`, `:841-847`), and `inferFnDecl` restores nothing on exit (the only restore is `restorePatternBindings` for `case` arms, `infer.zig:5440-5450`). Derived, not run; `surface.md` § shadowing records it as unverified. Write `val r = use router()`, `val path = use pathname()`.
6. **Type constructors stay PascalCase** (`ActionState(…)`, `FormStatus(…)`, `LinkStatus(…)`, `RouterState(…)`); a hook and a constructor of the same noun therefore never collide. A *helper* that builds a value of that type takes a verb (`parseActionState`, `newActionState`), never the bare noun the hook owns — `04-jhonstart/67-jhonstart-forms/README.md` § *Naming under the `use` rule* applies this.

## Steps

### Step 0 — Measure — LANDED with step 1

The eleven derived rows of *Current state* were the front's baseline; the eight `tests/language` cells now execute the same constructs on all four targets, which is what makes them measured, and `surface.md` § 0 says which rows the landing overtook. The ecosystem count is the library front's and is now **0** on both spellings (`grep -rnE '\buse use|fn use[A-Z]' repository/jhonstart`).

**Acceptance:**
- [x] the constructs of the table run on commonJS, erlang, wasm and beam as `tests/language` cells
- [x] `04-jhonstart/README.md` § *Written with `use`, under `#[@context]`* links this file
- [ ] row 5 — a `use` **inside** a nested closure, `val f = { -> use state(0) }` — has no cell and stays **derived**; the cells exercise a lambda passed as a hook *argument*, which is the opposite case. Row 9 (the un-activated call) is covered: `fn Plain() -> Element { val c = state(7); … }`

### Step 1 — Document `use` and `@Context`, require the effect, close the guard's two holes — LANDED

The four parts are in *Landed since*: the `#[@context]` requirement and its `use-without-context-effect` diagnostic (decision 88), the `docs.md` section with the three-production grammar and every diagnostic verbatim, both static-prefix holes (rows 4b and 4c), and the eight `tests/language` cells. Step 5 landed with it, because the language cells could not run on commonJS while the rename was still there.

**Acceptance:**
- [x] `docs.md` documents both roles with the grammar, the hook / component / custom-hook shapes, and the six diagnostics verbatim
- [x] rows 4b and 4c are parse errors with the existing `` `use` must be in static prefix `` message; a lambda body starts its own prefix
- [x] a `-> Element` body that activates a hook without `#[@context]` is `use-without-context-effect`; a capital `#[@Context]` is not an alias (decision 67)
- [x] `tests/language` has 8 `use` cells, green on commonJS, erlang, wasm and beam, none in `expected-failures.txt`
- [x] `repository/jhonstart/src/hooks.bp` type-checks — with `#[@context]` on its activating bodies, which is the library front's half of decision 88

### Step 2 — `use` inside `#[@future] fn … -> @Future<Element>` — REMAINING

Two rules, both decided, neither written in the compiler yet.

Decision **89**: `contextInfoFromReturn` looks through `@Future<T>` — and only `@Future` — and takes `T`'s owner, so `-> @Future<Element>` has `Owner = Element` and `request()` is declared `pub declare fn request() -> @Context<Element, Request>`, not the `@Context<Http, Request>` `server.d.bp` carries today. The server hook's owner becomes the tree it renders into: one base per render tree, which is what RC2/RC3 already assume, and `await` stays legal in the static prefix (an `await` is not a branch).

Decision **90**: `FnContext.annotated` (`infer.zig:987`) is set either by `#[@context]` **or** by a wrapper effect whose unwrapped return type owns a context — so `#[@future] fn Page() -> @Future<Element>` activates hooks with **no second annotation**. R5 is unamended: `#[@future] #[@context]` stays `effect-duplicate-annotation`. Decision 88 is untouched where there is no wrapper effect, and decision 67 keeps both refusals: a body with no effect annotation that activates is still `use-without-context-effect`, and `#[@context]` on a fn whose return owns no context is still `effect-wrapper-mismatch`.

What decision 89 gives up is that a client hook (`state`, owner `Element`) becomes *type-legal* inside a server component. It is recovered where it belongs — front 29's `#[client]`, a library decorator under decision 87, is the rule that says which hooks a server body may activate.

**Acceptance:**
- [ ] `#[@future] fn Page(params) -> @Future<Element> { val req = use request(); … }` infers, with `request : -> @Context<Element, Request>` and no `#[@context]` on `Page`
- [ ] `#[@future] fn f() -> @Future<string> { val x = use state(0); }` is `use-of-non-context-fn`
- [ ] `#[@future] #[@context] fn Page() -> @Future<Element>` is still `effect-duplicate-annotation`; `#[@context] fn f() -> string` is still `effect-wrapper-mismatch`; `fn Widget() -> Element { val c = use state(0); }` is still `use-without-context-effect`
- [ ] `language-gaps.md` row 53 is closed — the row already names decisions 89 and 90 as its answer and this step is what lands it
- [ ] `jhonstart/examples/jhonstart-app/app/posts/[id]/page.bp` compiles; front 28's `server.d.bp` loses its gate and re-declares `request()` with owner `Element`

### Step 3 — Destructuring from a `use`

`val {a, b} = use …` works (row 7). `val #(a, b) = use …` parses and lowers but its elements are fresh vars (row 8): `bindUseDestructure` (`infer.zig:8194-8196`) must bind each name to the corresponding element of `R` when `R` is a tuple type (`ast.zig:1763` `tuple_: []TypeRef`), and refuse an arity mismatch. The labeled-tuple half (`#(state: S, dispatch: fn(…))` losing its labels through generic instantiation, `hooks.bp:75-77`) stays with C-08 / front 01; this step is the positional half only.

**Acceptance:** `val #(shown, push) = use optimistic(12, addLike)` binds `shown : i32`, `push : fn(action: i32)`; `val #(a) = use optimistic(…)` is an arity error; `67-jhonstart-forms/examples/optimistic-like-example.bp` compiles with the tuple form (the sweep already writes it).

### Step 4 — The boundary directives — CLOSED, no compiler change

**Decision 87.** The boundary directives stay **library decorators**: `#[client]` (front 29 owns it) and `#[cache]` (front 12); `#[server]` has no occurrence in the specs and is the libraries' to spell if they need one. `use` is the activation keyword inside a function body and takes no second, module-level role; front 68's bundler splits by reading the marker jhonstart emits, and the two refusals — an Erlang cell in a client module, a client hook in a server module — are the libraries' to implement, not the compiler's. The `use client;` / `use server;` production this front recommended is rejected, in the maintainer's words: `use` is not for `use client;` / `use server;` outside a function body. This step therefore closes with **no compiler change** and no new production; the free `Name*;` activation statement stays what it is (an extension opt-in, always an error for a local symbol).

What the specs keep, unchanged by this step: `#[client]` across 04-jhonstart and 06-onze, `'use server'` as prose naming Next's directive, and `#[cache]` / `#![useCache]` in 03-rakun — the last is front 12's, and the module-level-annotation row of `language-gaps.md` (owned by 15-language-surface) is where its spelling is still open.

**Acceptance:**
- [x] no production, no diagnostic and no emitter arm is added for a boundary directive
- [x] `docs.md` says it: "`use` never leaves a function body … a framework's boundary markers are its own decorators (`#[client]`)"

### Step 5 — The lowering contract per backend — LANDED

**Decision 88.** `use f(x)` lowers to `f(x)` on **every** backend. The commonJS rename and the inferred dependency arrays are deleted (`hookName`, `hookTakesDeps`, `buildHookDeps`, `hook_state`), so five hook names and one host framework's naming convention leave the compiler — the ecosystem rule that the compiler knows none of the libraries (`feedback_no_lib_specific_in_core`) holds again, the four backends agree, and a hook named by the rule (*Current state* row 6b, `fn counter(…)` activated as `use counter(5)`) runs instead of raising a `ReferenceError`. A hook that takes a dependency array declares it as a parameter (`memo(compute, deps)`); nothing is inferred.

The client runtime is jhonstart's half, not the compiler's: it supplies hook semantics by what `f` *does*, as a cell resolved to the client build, while the same module's pure body stays the server pass.

**Acceptance:**
- [x] `.useHook` is the operand on all four backends; no rename, no inferred deps in `codegen/commonJS.zig`
- [x] the four `codegen_use_*` snapshots re-recorded and renamed to what they assert, once per target (16 files); `grep -rl useState snapshots/` is empty
- [x] `tests/language/AGENTS.md`'s "it needs a host framework" exclusion is lifted — the `use` cells are green on commonJS too

## Gate

- [x] `docs.md` documents `use` (both roles), `@Context<Owner, R>`, the static-prefix rule and the six diagnostics — step 1.
- [x] Rows 4b and 4c are parse errors, and a `-> Element` body that activates without `#[@context]` is `use-without-context-effect` — step 1.
- [x] `tests/language` has `use` cells green on commonJS, erlang, wasm and beam — steps 1 and 5.
- [x] `use f(x)` is `f(x)` on every backend — step 5.
- [ ] `use` in a `#[@future] fn … -> @Future<Element>` body infers, with no second annotation — step 2 (decisions 89 and 90).
- [ ] `val #(a, b) = use …` binds element types — step 3.
- [x] `grep -rn "use use" specs/1.0.10-beta/04-jhonstart repository/jhonstart` → 0; `grep -rnE '\bfn use[A-Z]' specs/1.0.10-beta/04-jhonstart` → 0.
- [x] every component and custom hook in `04-jhonstart` is `#[@context] fn … -> Element` / `#[@context] fn <noun>(…) -> @Context<Element, _>`, and every server component is `#[@future] fn … -> @Future<Element>` with no second annotation — decisions 88 and 90.

## Blast radius

**jhonstart's specs.** The `use`-prefix sweep (`04-jhonstart/unification.md` § 6 is the row) covered `26-jhonstart-router`, `27-jhonstart-link`, `29-jhonstart-client-directive`, `67-jhonstart-forms` and the track's four maps. Decision 88's `#[@context]` sweep then reached every front that writes a component — 26, 27, 28, 29, 30, 31, 32, 67 — **39** declarations, plus the rule statements in `README.md`, `unification.md` and `test-snap.md`. Front 94 declares no component (its surface is lowercase element builders) and is untouched; `modules.md` and `test-snap-examples.md` carry no component declaration.

**jhonstart's own files (the library front, not this one):** `src/hooks.bp`, `src/router.d.bp`, `src/client_runtime.{bp,mjs}`, `examples/jhonstart-{counter,todo}`, `docs.md`.

**Compiler:** steps 1 and 5 landed in `parser.zig`, `comptime/{infer,error,diagnostics}.zig`, `codegen/commonJS.zig`, `docs.md`, `tests/language/**` and `snapshots/codegen/**`. Step 2 is `infer.zig`'s `contextInfoFromReturn` and the `annotated` rule; step 3 is `bindUseDestructure`.

## Notes

- `decisions-taken.md` (1.0.5) binds nothing here: `grep -n 'Context\|activation\|\buse\b' specs/1.0.5-beta/decisions-taken.md` finds one prose "use" (`:926`). Decision 8 § 5.1 P6 is the tuple *pattern* `#(a, b)` in `case` (`parser/patterns.zig:193-196`), a sibling of the binding form step 3 completes.
- The `use` prefix is **not** React's `use(promise)`: `04-jhonstart/unification.md` § 4 already records that Next's *Streaming de dados com `use`* is missed for that reason.
- `router.d.bp`'s `useRouter` was the case *Current state* row 6 made work by accident — `use`+Upper passed the rename through. With the rename gone the accident is gone too; under the rule the hook is `router()`, and front 26's Step 3 redefines it from `snapshot()`.
- `@getContex(T)` (`infer.zig:4370-4400`) reads the active provider of `T` on the same owner tree, under the same `#[@context]` effect decision 88 made the activating body's annotation. `docs.md` names it; the provider stack itself is nobody's front yet.

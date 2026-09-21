# Front 19 — `use` surface, construct by construct

Derived from the code at `botopink-lang` `d55a3b87` (paths relative to `modules/compiler-core/src/`); nothing here was compiled. A row marked **recorded** has a checked-in snapshot or unit cell that shows the outcome; every other row is derived from the cited lines. `Element` is `type Element(…) implement @Context<Element, Element>` (`repository/jhonstart/src/element.bp:8`).

## 1 · The table

| Construct | Parses? | Infers? | commonJS | erlang | wasm | beam | Diagnostic (verbatim) | Cites |
|---|---|---|---|---|---|---|---|---|
| `val c = use state(0);` in `fn C() -> Element` | yes — `Expr.useHook{inner}` | yes; `c : R` = `State<i32>` | `const c = useState(0);` (renamed, undeclared) | `state(0)` | `state(0)` | `state(0)` | — | `parser/exprs.zig:116-124`; `infer.zig:3011-3013`, `:8134-8151`; `commonJS.zig:2372-2376`, `:2477-2486`; `erlang.zig:5216`; `wat.zig:2814`; `beam_asm.zig:2912`; **recorded** `snapshots/codegen/commonJS/codegen_use_tuple_destructure_state_to_usestate.snap.md` |
| `use effect { -> cleanup(); };` bare statement | yes | yes (type `R`, discarded) | `useEffect(() => {…}, []);` — deps inferred | `effect(…)` | `effect(…)` | `effect(…)` | — | `commonJS.zig:2398`, `:2469-2473`, `:2513-2526`; **recorded** `codegen_use_effect_void_hook_empty_deps.snap.md`; cell `parser/tests/expressions.zig:19-27` |
| `val d = use memo { -> count * 2 };` after `val {count, setCount} = use state(0)` | yes | yes | `const doubled = useMemo(() => {…}, [count]);` | plain | plain | plain | — | `commonJS.zig:2513-2534` (`hook_state` names referenced in the lambda body); **recorded** `codegen_use_memo_infers_dependency_array.snap.md` |
| `use` in `#[@future] fn P(…) -> @Future<Element>` | yes | **no** | — | — | — | — | `use-of-non-context-fn: `use` not allowed: function returns '@Future<Element>' which does not implement @Context` | `infer.zig:976-990` (`.generic` named `Context` or `.named` with `contextBase` only); `error.zig:335` |
| `use` in `fn f() -> string` | yes | **no** | — | — | — | — | `use-of-non-context-fn: `use` not allowed: function returns 'string' which does not implement @Context` | `infer.zig:8135-8142`; **recorded** cell `comptime/tests/effects.zig:293-302` |
| `use` at module level / in a `test` body with no fn | yes | **no** — `env.fnContext == null` | — | — | — | — | same message with `'void'` | `infer.zig:8135-8138` |
| `use plain()` where `plain : -> User` (not a `@Context`) inside a context fn | yes | **no** | — | — | — | — | `use-of-non-context-fn: `use` requires @Context: 'User' does not implement @Context` | `infer.zig:8161-8165`; `error.zig:336`; **recorded** cell `comptime/tests/infer_errors.zig:661-671` |
| `use connection()` (`@Context<Http, _>`) inside `-> Element` | yes | **no** | — | — | — | — | `context-anchor-violation: function returns @Context<Element, _> but `use` returns @Context<Http, _>` | `infer.zig:8166-8171`; `error.zig:337`; **recorded** cell `effects.zig:304-316` |
| `use` in a fn returning bare `@Context<_, _>` with no base rendered | yes | yes — any base accepted | — | — | — | — | — | `infer.zig:8168` (`fc.base orelse return`) |
| `use state(0);` **after** `if`/`return`/`loop`/`case` at the same block level | **no** | — | — | — | — | — | `` `use` must be in static prefix`` · hint `Move all `use` statements to the top of the function body, before any `if`, `case`, `loop`, or `return`` | `parser.zig:737-745`; `print.zig:88-91`; **recorded** cell `parser/tests/errors.zig:52-69` |
| `val c = use state(0);` after a `return` | **yes** (hole) | yes | as row 1 | plain | plain | plain | — | `parser.zig:738` checks only `this.check(.use)` at statement start; the statement starts with `val` |
| `use effect {…};` inside an `if` block's own body | **yes** (hole) | yes | as row 2 | plain | plain | plain | — | `parser.zig:735` (`seenBranch` local to the block), `:720-765` |
| `use` inside a nested closure `{ -> use state(0) }` in a component | yes | yes — the closure inherits `env.fnContext` | `useState(0)` inside the arrow | plain | plain | plain | — | `infer.zig:9100-9121` (resets `throwContext`, `starFn`, labels only) |
| custom hook `fn useAuth() -> AuthState` (`AuthState … implement @Context<Element, AuthState>`) with `use state(0)` in its body; `val {loggedIn} = use useAuth()` | yes | yes | `const { loggedIn } = useAuth();` (pass-through: `use`+Upper) | plain | plain | plain | — | `commonJS.zig:2480-2483`; **recorded** cell `effects.zig:280-297` |
| custom hook by the rule `fn counter(n) -> @Context<Element, State<i32>> { return state(n); }`; `val c = use counter(5)` | yes | yes — `return` checked against `R` | **`useCounter(5)`**, definition emitted as `function counter` → ReferenceError | `counter(5)` | `counter(5)` | `counter(5)` | — | `infer.zig:3358-3362`; `commonJS.zig:2484-2485`; the snapshot of row 1 shows `function state(initial)` + `useState(0)` |
| `val {a, b} = use …` | yes | yes — `a`, `b` bound to `R`'s fields by name; fresh var if `R` has no such field | `const { a, b } = useState(0);` | plain + destructure | plain + destructure | plain + destructure | — | `infer.zig:7371-7372`, `:8180-8193`; `commonJS.zig:2382-2391`, `:2247`; **recorded** `codegen_use_object_destructure_state_to_usestate.snap.md` |
| `val #(a, b) = use …` | **yes** | yes — each element a **fresh var**; `R`'s tuple element types not propagated; no arity check | `const [ a, b ] = useState(0);` | plain + tuple destructure | plain + tuple destructure | plain + tuple destructure | — | `parser/exprs.zig:661-676`; `infer.zig:8194-8196`; `commonJS.zig:2248`; **recorded** `codegen_use_tuple_destructure_state_to_usestate.snap.md`, cell `codegen/tests/features.zig:209-221` |
| hook called **without** `use`: `val c = state(7); c.value` | yes | the call is ordinary; `c : @Context<Element, State<i32>>` at the binding (the `R` unwrap runs only under `use`); the member access type-checks in the library's own cell — unwrap site **not located, unverified** | `const c = state(7);` | `state(7)` | `state(7)` | `state(7)` | — | `infer.zig:8150` (unwrap under `use` only); `repository/jhonstart/src/hooks.bp:69-73`; `examples/jhonstart-counter/out/main.js:51` |
| `Name*;` at module level | yes — `ImportDecl{activationOnly = true}` | **no, always** — local extension → `redundantActivation`; anything else → `notAnExtension` | emits nothing | a `%% activate` comment form | skipped | skipped | `` `Name*` is redundant: an extension declared in this module is auto-applied; `*` is only for imports`` · `'Name' does not name an implement/extend symbol` | `parser/decls.zig:219-225`, `:263-272`; `parser.zig:394-397`; `infer.zig:879-899`; `error.zig:341`, `:343`; `commonJS.zig:1999-2000`; `erlang.zig:1396`; `wat.zig:290`; `beam_asm.zig:1159` |
| `import { x* } from "lib"` | yes — `ImportPath.activate` | yes — `env.activations.put("x")` | `require` | import form | import form | import form | — | `parser/decls.zig:247`; `infer.zig:897`; `commonJS.zig:464` |
| `use` where the operand is a **method call** `obj.hook()` | yes | as the operand infers | `obj.hook()` — the receiver form is **not renamed** | plain | plain | plain | — | `commonJS.zig:2500-2503` |

## 2 · Where the guard is switched on

`BlockParseOptions.useAfterBranchGuard` (`parser.zig:697`) is `true` in exactly one caller: `parseStmtListInBraces` (`parser.zig:767-773`), which every brace-delimited statement block goes through — fn bodies, `test` bodies, `if`/`else` blocks via `parseBlockOrExpr` (`:779-781`). It is therefore a property of *every block*, not of `-> Element` bodies; the type-level restriction is inference's (`env.fnContext`). The two callers that read a prologue before the first statement (`if (c) { x -> … }` and `{ a, b -> … }` lambdas) call `parseBlockBody` directly with their own options (`:704-719` comment) — whether they pass the guard was not verified.

## 3 · What each backend does with `Expr.useHook`

| Backend | Site | Behaviour |
|---|---|---|
| commonJS | `codegen/commonJS.zig:160-165` `useHookInner` · `:2372-2376` (`val`) · `:2382-2391` (`val {…}`/`#(…)`) · `:2398` (bare) · `:2966` (value position) → `buildHookCall` `:2490-2511` | rename by `hookName` (`:2477-2486`: `state → useState`; `use[A-Z]…` passes; empty callee → `use`); deps array appended for `memo`, `effect`, `callback`, `layoutEffect`, `imperativeHandle` (`:2469-2473`) from `hook_state` (`:813-815`, names bound by earlier hooks, `:2247-2248`, `:2374`); receiver calls unrenamed |
| erlang | `codegen/erlang.zig:5214-5216` | transparent — `exprNode(inner)` |
| wasm (WAT) | `codegen/wat.zig:2812-2814` (+ `:2193`, `:2714`, `:3748`, `:5664`, `:6297`, `:7007` walk through it) | transparent — `lowerExpr(inner)` |
| beam | `codegen/beam_asm.zig:2910-2912` (+ `:180`, `:662`, `:860`, `:6270`) | transparent — `lowerExprIntoX0(inner)` |
| formatter | `format.zig:749` | `"use " ++ fmtExpr(inner)` |
| typescript typedef | — (no `useHook` arm; `codegen/typescript.zig:55` handles the `.use` *decl*) | not applicable |

The jhonstart claim "the `use` prefix lowers to the target's hook convention (React `useState`… on `commonJS`)" (`repository/jhonstart/src/hooks.bp:9-11`, `docs.md:41-43`) is **true for the name and false for the binding**: the renamed identifier is emitted but never imported or declared. `examples/jhonstart-counter/out/main.js:20` — `const { state } = require("./jhonstart/hooks.js");` — and `:34` — `const c = useState(0);`.

## 4 · Shadowing — a local named like an imported hook (unverified)

`Env.bindings` is one `StringHashMap(*Type)` (`comptime/env.zig:346-347`); `lookup`/`bind` are a flat get/put (`:841-847`). `inferFnDecl` saves and restores `fnContext`, `throwContext`, `starFn` and labels around a body (`infer.zig:3011-3013`, `:9100-9121` for lambdas) but not `bindings`; the only binding restore in the file is `restorePatternBindings` for `case` arms (`:5440-5450`). Derived consequence, **not run**: after `val router = use router();` in one fn, `router` is bound to `RouterState` for every later fn of the same module, and a later `router()` call would infer as a call on a record. The same holds for a parameter named `params` in a module that imports the hook `params`. The rule for libraries (README § *The rule for libraries* item 5) is written to avoid the case; step 0 measures it.

## 5 · The library sites that do not follow the rule today

| Site | Spelling | Under the rule |
|---|---|---|
| `repository/jhonstart/src/router.d.bp:25` | `pub declare fn useRouter() -> @Context<Element, Router>` | `router()` — front 26 Step 3 already redefines it |
| `repository/jhonstart/src/hooks.bp:100` | `fn useCounter(start: i32) -> @Context<Element, State<i32>>` (test-local) | `counter(start)` — would break on commonJS until question 85 lands |
| `repository/jhonstart/examples/jhonstart-todo/src/main.bp:28` | `val open = use useToggle(true);` | `use toggle(true)` — same caveat |
| `repository/jhonstart/docs.md:57` | `fn useCounter(start: i32) -> …` | same |
| `repository/jhonstart/src/hooks.bp:30-58` | `state`, `effect`, `memo`, `ref`, `reducer` | already the rule |
| `repository/jhonstart/src/server.d.bp:26` | `pub declare fn request() -> @Context<Http, Request>` | the name is the rule; the owner is step 2's question 86 |

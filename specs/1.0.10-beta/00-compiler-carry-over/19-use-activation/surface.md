# Front 19 — `use` surface, construct by construct

Paths relative to `modules/compiler-core/src/`. A row marked **recorded** has a checked-in snapshot
or cell; every other row is derived from the cited lines. `Element` is
`type Element(…) implement @Context<Element, Element>`
(`repository/jhonstart/modules/jhonstart/src/element.bp:8`) until 21-effect-chain's sweep makes it
`implement @Context<ElementBase>` (decision 102). The activating annotation is `#[@context]` in the
tree and `#[@use]` after 21-effect-chain (102); nothing else grants `use` (104).

## 1 · The table

| Construct | Parses? | Infers? | Lowers (all four) | Diagnostic (verbatim) | Cites |
|---|---|---|---|---|---|
| `val c = use state(0);` in an annotated `-> Element` body | yes — `Expr.useHook{inner}` | yes; `c : R` = `State<i32>` | `state(0)` | — | `parser/exprs.zig:116-124`; `infer.zig:3011-3013`, `:8134-8151`; **recorded** `snapshots/codegen/*/codegen_use_*_is_a_plain_call.snap.md` |
| `use effect { -> cleanup(); };` bare statement | yes | yes (type `R`, discarded) | `effect(…)` — no inferred deps | — | **recorded** `codegen_use_*_memo_is_a_plain_call_with_no_inferred_deps.snap.md`; `parser/tests/expressions.zig:19-27` |
| `use` in `#[@future] fn P(…) -> @Future<Element>` | yes | yes in the tree; **refused after 21-effect-chain** (104) | plain call | after 21: `use-without-context-effect` | `infer.zig` `contextInfoFromReturn` |
| `use` in `fn f() -> string` | yes | **no** | — | `use-of-non-context-fn: `use` not allowed: function returns 'string' which does not implement @Context` | `infer.zig:8135-8142`; **recorded** `comptime/tests/effects.zig:293-302`, `reject/use_in_plain_fn.bp` |
| `use` in an unannotated `-> Element` body | yes | **no** | — | `use-without-context-effect: …` — names the annotation | `comptime/error.zig`; **recorded** `reject/use_without_context_effect.bp` |
| `use` at module level / in a `test` body with no fn | yes | **no** — `env.fnContext == null` | — | same message with `'void'` | `infer.zig:8135-8138`; **recorded** `reject/use_at_module_level.bp` |
| `use plain()` where `plain : -> User` inside a context fn | yes | **no** | — | `use-of-non-context-fn: `use` requires @Context: 'User' does not implement @Context` | `infer.zig:8161-8165`; **recorded** `comptime/tests/infer_errors.zig:661-671` |
| `use connection()` anchored at another base inside `-> Element` | yes | **no** | — | `context-anchor-violation: function returns @Context<Element, _> but `use` returns @Context<Http, _>` | `infer.zig:8166-8171`; **recorded** `effects.zig:304-316`, `reject/use_owner_mismatch.bp` |
| `use` in a fn returning bare `@Context<_, _>` with no base rendered | yes | yes — any base accepted | — | — | `infer.zig:8168` (`fc.base orelse return`) — gone with 102: a `#[@use]` body always has a base |
| `use state(0);` after `if`/`return`/`loop`/`case`; `val c = use …` after a `return`; `use` inside an `if` block's own body | **no** | — | — | `` `use` must be in static prefix`` · hint `Move all `use` statements to the top of the function body, before any `if`, `case`, `loop`, or `return`` | `parser.zig` (`useBranchSeen`, `bindingUseLoc`); **recorded** `parser/tests/errors.zig:52-69`, `reject/use_{after_return,inside_branch}.bp` |
| `use` inside a nested closure `{ -> use state(0) }` in a component | yes | yes — the closure inherits `env.fnContext` | plain call inside the arrow | — | `infer.zig:9100-9121` — derived, no cell |
| custom hook `#[@context] fn counter(n) -> @Context<Element, State<i32>> { return state(n); }`; `val c = use counter(5)` | yes | yes — `return` checked against `R` | `counter(5)` | — | `infer.zig:3358-3362`; **recorded** `effects.zig:280-297` |
| `val {a, b} = use …` | yes | yes — bound to `R`'s fields by name; fresh var if absent | plain + destructure | — | `infer.zig:7371-7372`, `:8180-8193`; **recorded** `codegen_use_object_destructure_*` |
| `val #(a, b) = use …` | yes | each element a **fresh var**; no arity check — step 3 | plain + tuple destructure | — | `parser/exprs.zig:661-676`; `infer.zig:8194-8196`; **recorded** `codegen_use_tuple_destructure_*`, `codegen/tests/features.zig:209-221` |
| hook called **without** `use`: `val c = state(7); c.value` | yes | ordinary call; `c` is the wrapper; the member access type-checks in the library's own cell | `state(7)` | — | `infer.zig:8150`; `repository/jhonstart/modules/jhonstart/src/hooks.bp:69-73`; **recorded** `run/context_use.bp` |
| `Name*;` at module level | yes — `ImportDecl{activationOnly = true}` | **no, always** | emits nothing (erlang: a comment form) | `` `Name*` is redundant: an extension declared in this module is auto-applied; `*` is only for imports`` · `'Name' does not name an implement/extend symbol` | `parser/decls.zig:219-225`, `:263-272`; `infer.zig:879-899`; `error.zig:341`, `:343` |
| `import { x* } from "lib"` | yes — `ImportPath.activate` | yes — `env.activations.put("x")` | `require` / import form | — | `parser/decls.zig:247`; `infer.zig:897`; `commonJS.zig:464` |
| `use` where the operand is a method call `obj.hook()` | yes | as the operand infers | `obj.hook()` | — | `commonJS.zig` `buildExpr(inner)` |

## 2 · Where the guard is switched on

`BlockParseOptions.useAfterBranchGuard` (`parser.zig:697`) is `true` in `parseStmtListInBraces`
(`parser.zig:767-773`), which every brace-delimited statement block goes through;
`parseFnBodyInBraces` carries `freshUseScope`, so a fn, method, `test` or lambda body starts its own
prefix; `useBranchSeen` is set by `if`/`case`/`loop`/`return` as they are parsed and `bindingUseLoc`
reads the parsed statement, so the guard sees a `use` at any nesting and behind a `val`.

## 3 · What each backend does with `Expr.useHook`

| Backend | Site | Behaviour |
|---|---|---|
| commonJS | `codegen/commonJS.zig` — statement, destructuring and value positions | transparent — `buildExpr(inner)`; no rename, no inferred dependency array |
| erlang | `codegen/erlang.zig:5214-5216` | transparent — `exprNode(inner)` |
| wasm (WAT) | `codegen/wat.zig:2812-2814` | transparent — `lowerExpr(inner)` |
| beam | `codegen/beam_asm.zig:2910-2912` | transparent — `lowerExprIntoX0(inner)` |
| formatter | `format.zig:749` | `"use " ++ fmtExpr(inner)` |
| typescript typedef | — (no `useHook` arm; `codegen/typescript.zig:55` handles the `.use` *decl*) | not applicable |

## 4 · Shadowing — a local named like an imported hook (derived, not run)

`Env.bindings` is one `StringHashMap(*Type)` (`comptime/env.zig:346-347`); `lookup`/`bind` are a flat
get/put (`:841-847`). `inferFnDecl` saves and restores `fnContext`, `throwContext`, `starFn` and
labels around a body (`infer.zig:3011-3013`, `:9100-9121` for lambdas) but not `bindings`; the only
binding restore is `restorePatternBindings` for `case` arms (`:5440-5450`). Derived consequence:
after `val router = use router();` in one fn, `router` is bound to `RouterState` for every later fn
of the same module, and a later `router()` call infers as a call on a record. The rule for libraries
(README item 5) avoids the case.

## 5 · The library sites

`repository/jhonstart/modules/jhonstart/src/hooks.bp` (`state`, `effect`, `memo`, `ref`, `reducer`,
`counter`, `toggle`) and `router.bp` (`router`, `pathname`, …) follow the rule; `server.bp`'s
`request()` becomes `#[@use] pub fn request() -> @Use<ElementBase, Request>` in 21-effect-chain
step 4, together with every other annotation and wrapper in that library.

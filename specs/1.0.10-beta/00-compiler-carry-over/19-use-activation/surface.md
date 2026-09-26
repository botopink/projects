# Front 19 — `use` surface, construct by construct

Paths relative to `modules/compiler-core/src/`. A row marked **recorded** has a checked-in snapshot
or cell. The owner type is `type Element(…) implement @Context<ElementBase>` (jhonstart; a cell
declares its own). Only a `-> @Component<C, T>` return grants `use` (decisions 104, 118, 128).

## 1 · The table

| Construct | Parses? | Infers? | Lowers (all four) | Diagnostic | Cites |
|---|---|---|---|---|---|
| `val c = use state(0);` in a `-> @Component<ElementBase, Element>` body | yes — `Expr.useHook{inner}` | yes; `c : T` = `State<i32>` | `state(0)` | — | **recorded** `snapshots/codegen/*/codegen_use_*_is_a_plain_call.snap.md`, `run/context_use.bp` |
| `use effect { -> cleanup(); };` bare statement | yes | yes (type `T`, discarded) | `effect(…)` — no inferred deps | — | **recorded** `codegen_use_*_memo_is_a_plain_call_with_no_inferred_deps.snap.md` |
| `use` in a `-> @Task<Element>` body | yes | **no** | — | `use-without-context-effect` | **recorded** `reject/use_under_task.bp` |
| `use` in `fn f() -> string` / an unwrapped `-> Element` body | yes | **no** | — | `use-without-context-effect` — `use` requires a `@Component<…>` return | **recorded** `reject/use_in_plain_fn.bp`, `reject/use_without_context_effect.bp` |
| `use` at module level / in a `test` body with no fn | yes | **no** | — | `use-without-context-effect` | **recorded** `reject/use_at_module_level.bp` |
| `use` of a hook anchored at another base | yes | **no** | — | `context-anchor-violation` | **recorded** `reject/use_owner_mismatch.bp` |
| two `use`s at two bases in one body | yes | **no** — at the second `use`, naming both | — | every `use` in one function resolves against the same ContextBase | **recorded** `reject/use_two_bases.bp` |
| `use Card()` where `Card` is a component | yes | **no** | — | a component is called, not `use`d | **recorded** `reject/use_of_component.bp` |
| `use state(0);` after `if`/`return`/`loop`/`case`; `val c = use …` after a `return`; `use` inside an `if` block's own body | **no** | — | — | `` `use` must be in static prefix`` · hint `Move all `use` statements to the top of the function body, before any `if`, `case`, `loop`, or `return`` | `parser.zig` (`useBranchSeen`, `bindingUseLoc`); **recorded** `parser/tests/errors.zig`, `reject/use_{after_return,inside_branch}.bp` |
| `use` inside a nested closure `{ -> use state(0) }` | yes | **no** — the closure is not the `@Component` body | — | `use-without-context-effect` | **recorded** `reject/use_in_closure.bp` |
| a hook that `use`s hooks: `fn counter(n: i32) -> @Component<Element, State> { val s = use state(n); return s; }` | yes | yes — `return` checked against `T` | `counter(5)` | — | **recorded** `run/context_use.bp` (`Composed()`) |
| `val {a, b} = use …` | yes | yes — bound to `T`'s fields by name | plain + destructure | — | **recorded** `codegen_use_object_destructure_*`, `run/context_use.bp` (`Fields()`) |
| `val #(a, b) = use …` | yes | yes — each name bound to the element of a tuple `T` at its position; an unresolved `T` committed to a tuple of the pattern's arity | plain + tuple destructure | `use-tuple-arity: `val #(…)` binds 1 name(s) but the hook yields a tuple of 2` · `use-tuple-arity: `val #(…)` binds 2 name(s) but the hook yields 'i32', which is not a tuple` — at the binding | `infer.zig` `bindUseDestructure`; **recorded** `codegen_use_tuple_destructure_*`, `run/context_use.bp` (`Liked()`), `reject/use_tuple_{arity,of_non_tuple}.bp` |
| hook called **without** `use`: `val c = state(7); c.value` | yes | ordinary call; `c` is the wrapper | `state(7)` | — | `infer.zig` — `bindingSourceType` runs only under `use` |
| `Name*;` at module level | yes — `ImportDecl{activationOnly = true}` | **no, always** | emits nothing (erlang: a comment form) | `` `Name*` is redundant: an extension declared in this module is auto-applied; `*` is only for imports`` · `'Name' does not name an implement/extend symbol` | `parser/decls.zig`; `infer.zig` |
| `import { x* } from "lib"` | yes — `ImportPath.activate` | yes — `env.activations.put("x")` | `require` / import form | — | `parser/decls.zig`; `infer.zig` |
| `use` where the operand is a method call `obj.hook()` | yes | as the operand infers | `obj.hook()` | — | `commonJS.zig` `buildExpr(inner)` |

## 2 · Where the guard is switched on

`BlockParseOptions.useAfterBranchGuard` is `true` in `parseStmtListInBraces`, which every
brace-delimited statement block goes through; `parseFnBodyInBraces` carries `freshUseScope`, so a fn,
method, `test` or lambda body starts its own prefix; `useBranchSeen` is set by
`if`/`case`/loop/`return` as they are parsed and `bindingUseLoc` reads the parsed statement, so the
guard sees a `use` at any nesting and behind a `val`.

## 3 · What each backend does with `Expr.useHook`

| Backend | Behaviour |
|---|---|
| commonJS | transparent — `buildExpr(inner)`; no rename, no inferred dependency array; the enclosing `@Component` body is an `async function` |
| erlang | transparent — `exprNode(inner)` |
| wasm (WAT) | transparent — `lowerExpr(inner)` |
| beam | transparent — `lowerExprIntoX0(inner)` |
| formatter | `"use " ++ fmtExpr(inner)` |
| typescript typedef | no `useHook` arm (the `.use` *decl* is handled); not applicable |

## 4 · Shadowing — a local named like an imported hook (derived, not run)

`Env.bindings` is one `StringHashMap(*Type)` (`comptime/env.zig`); `lookup`/`bind` are a flat
get/put. `inferFnDecl` saves and restores `fnContext`, `throwContext` and labels around a body but not
`bindings`; the only binding restore is `restorePatternBindings` for `case` arms. Derived
consequence: after `val router = use router();` in one fn, `router` is bound to `RouterState` for
every later fn of the same module, and a later `router()` call infers as a call on a record. The rule
for libraries (README item 5) avoids the case; the leak itself is `01-checker`'s (a local `val`
leaking into later declarations, `status.md` Pending).

## 5 · The library sites

`repository/jhonstart/modules/jhonstart/src/hooks.bp` (`state`, `effect`, `memo`, `ref`), `router.bp`
(`router`, `pathname`, `params`, `searchParams`, `selectedLayoutSegment[s]`) and `server.bp`'s `request()` are
`fn … -> @Component<ElementBase, T>`; `jhonstart-forms` carries `formStatus`, `actionState` and
`optimistic` in the same shape.

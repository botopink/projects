# Async, Generator & Iterator (`*fn`, `await`, `yield`, `loop await`)

**Branch**: `feat/async-generators`
**Depends on**: `feat/use-await-prefix` for the `await` prefix (the rest is independent)
**Status**: pending

> `*fn` is sugar: it marks that the return implements `@Future<_>` or `@Iterator<_>`.
> The `await`/`yield` rules follow from the return type, not from `*fn` itself.

## Steps

### Lexer + AST
1. Lexer: `await` token in `TokenKind` + `identifierType`
2. AST: `Expr.await` variant (prefix, like `try`) — may reuse `awaitPrefix` from `feat/use-await-prefix`
3. AST: `isStarFn: bool` field on `FnDecl` / fn expressions
4. AST: `awaitLoop: bool` field on `LoopExpr` (for `loop await`)
5. AST: `label: ?[]const u8` field on `JumpExpr.yield`, `LoopExpr`, `FnDecl`

### Parser
6. `*fn` — detect `*` before `fn`
7. `await expr` prefix (like `try`)
8. `loop await (iter) { … }`
9. labels `:name` after `loop` or after a `*fn` return type
10. `yield :label expr` — optional label
11. error if `*fn` has no body

### Inference
12. `*fn`: return must implement `@Future<_>` or `@Iterator<_>`
13. error if a normal `fn` returns `@Future`/`@Iterator` (must use `*fn`)
14. `await expr`: verify `@Future<T>`, result = `T`; error if fn doesn't implement `@Future`
15. `yield expr` in `*fn`: unify with `T` of `@Iterator<T>`
16. labels: verify the reference exists
17. `loop await`: verify `@AsyncIterator<T, E>`, infer param `T`
18. `try await expr`: unwrap `@Future<@Result<T,E>>` → `T`

### Codegen

| Feature | CommonJS | Erlang | BEAM ASM | WAT |
|---|---|---|---|---|
| `*fn` async | `async function` | spawn + receive | spawn/receive OTP | state machine |
| `*fn` generator | `function*` | stateful process | spawn + msg | state machine |
| `*fn` async gen | `async function*` | spawn + receive loop | spawn + receive | callback chain |
| `await expr` | `await expr` | `receive`/`gen_server:call` | receive + match | continuation |
| `yield expr` | `yield expr` | send | send | store + return |
| `loop await` | `for await` | receive loop | receive + match | callback loop |

TypeScript `.d.ts`: `@Future<T>` → `Promise<T>`, `@Iterator<T>` → `IterableIterator<T>`, `@AsyncIterator<T,E>` → `AsyncIterableIterator<T>`

### Formatter + LSP
- Formatter: `*fn`, `await expr`, `loop await`, `yield :label`
- LSP hover: unwrapped type of `await`/`yield`; autocomplete `next()`/`iter()`/`map()`

## Test scenarios

```
parser ---- *fn async/generator/async-gen declaration
parser ---- *fn with label :gen after return type
parser ---- await prefix / await chained / loop await
parser ---- yield :gen / yield :acc / yield no label
inference ---- *fn @Future/@Iterator valid; string (error); fn normal returning @Future (error)
inference ---- await unwraps T; await outside *fn (error); await non-@Future (error)
inference ---- yield unifies; yield :label exists/nonexistent
inference ---- loop await infers T; non-async-iterable (error); try await double unwrap
codegen ---- async fetch / generator fibonacci / async gen stream
codegen ---- await / yield / loop await / yield :label / try await
```
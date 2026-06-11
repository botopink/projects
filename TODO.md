# TODO — expr-custom  (core keystone · Wave 1)

> Task branch `task/expr-custom` · spec
> [`tasks/v0.beta.9/specs/expr-custom.md`](tasks/v0.beta.9/specs/expr-custom.md).
> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test (no `--no-verify`).
> **Depends on: nothing.** Keystone — unblocks `sublanguage-lsp` (Wave 2) +
> `erika-query-ast`/`jhonstart-html-ast` (Wave 3). Start now.

> **HARD RULE.** Zero sub-language vocabulary in `compiler-core/src`. `@ExprCustom`
> carries a generic `CustomNode` tree (`kind`/`label` are opaque strings the lib picks).
> The lib-agnostic gate stays green.
>
> **STATUS: DONE.** All F0–F4 + done-gate complete; `zig build && zig build test` green (1091 tests). `q.custom` rides the same builtin path as `build`/`fail` (`inferTemplateMethod` + `__capture` prelude + `Outcome`); `code` reuses the `@code` splice path unchanged, `ast` stored in `env.customAstByLoc`, surfaced on `OkData.custom_ast` (re-exported via `root.zig`).

## F0 — recognize `@ExprCustom<T>` as a template return
- [x] `ast.zig`: `isExprCustomType(TypeRef)` (builtin generic `ExprCustom`).
- [x] `infer.zig`: a fn returning `@ExprCustom<T>` is a template fn (extend the
      `isExprType` template-fn detection sites).

## F1 — the carrier type + `q.custom`
- [x] `builtins.d.bp`: add `CustomNode { kind, span, label, ref:?Binding, children }` +
      `CustomExpr<T> { code: Expr<T>, ast: CustomNode }` + `Expr.custom(ast, code)`.
- [x] `template_eval.zig`: serialize/deserialize a returned `CustomExpr` (extend the
      runtime outcome union with a `custom { code, ast }` variant).

## F2 — split the two halves
- [x] **code →** feed into the existing expansion path (`finishExpansion`/
      `substituteHoles`) exactly as a plain `@Expr<T>` return — zero runtime/codegen change.
- [x] **ast →** store the `CustomNode` root by call-location in `env.customAstByLoc`
      (never lowered, never reaches codegen).

## F3 — tooling-access API (generic)
- [x] `root.zig`: expose `{ loc, callee, root: CustomNode }` entries per compiled module
      (+ each template's `Source` for span→document mapping). This is what
      `sublanguage-lsp` consumes. No sub-language names.

## F4 — docs + gate
- [x] `comptime/AGENTS.md`: document the `@ExprCustom` model (code vs reference tree,
      storage-by-location, tooling API).
- [x] Test: no sub-language vocabulary leaked into the new core code; lib-agnostic gate green.

## Done gate
- [x] `q.custom(tree, code)` executes `code` identically to returning that `@Expr<T>`.
- [x] the `CustomNode` tree is retrievable by call-location via the tooling API.
- [x] `zig build && zig build test` green.

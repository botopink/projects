# v0.beta.9 — Wave 1: the two keystones + independent roots

> A **parallel wave**: four specs at once. The two keystones everything downstream
> needs (`expr-custom` for sub-languages, `module-system` for modules) land here, beside
> two self-contained independents. First of **three** waves (v0.beta.9 → v0.beta.11),
> re-grouped so each version is exactly what can be touched in parallel; dependencies
> cross to a later wave. See [`../AGENTS.md`](../AGENTS.md). Live progress →
> [`status.md`](status.md).

## The wave — four parallel specs

| Spec | Area | Depends on |
|---|---|---|
| [expr-custom](specs/expr-custom.md) | core comptime: `template_eval`/`infer`/`transform` + `builtins.d.bp` | nothing |
| [module-system](specs/module-system.md) | core `parser`/`scanner`/resolver + codegen boundaries; pilots `libs/std` | nothing |
| [lib-test-runner](specs/lib-test-runner.md) | a **new** `modules/lib-test-runner/` Zig module | nothing |
| [mutual-recursion](specs/mutual-recursion.md) | inference regression only (fix already landed) — near-zero code | nothing |

## Why these four are Wave 1

- **expr-custom** and **module-system** are the **two keystones**. `expr-custom`'s
  `@ExprCustom` carrier unblocks `sublanguage-lsp` (Wave 2) and the two sub-language
  producers (`erika-query-ast`, `jhonstart-html-ast`, Wave 3). `module-system`'s
  `mod`/`pub mod` tree unblocks `libs-module-migration` (Wave 2). Both must land a wave
  ahead of their consumers.
- **lib-test-runner** (a brand-new module) and **mutual-recursion** (regression-only —
  the forward-ref fix already landed, verified on all four backends 2026-06-10) are
  self-contained independents riding along at full parallelism.

The two keystones touch different core regions (`expr-custom`: comptime/template/
builtins; `module-system`: parser/resolver/codegen) — a late merge resolves any
`infer.zig` overlap, as prior consolidations did.

## What each spec delivers (summaries)

- **expr-custom** — `@ExprCustom<T>` = `{ code: Expr<T>, ast: CustomNode }`. `code`
  rides the existing `@Expr<T>` splice/codegen path (zero runtime change); `ast` (a
  generic `kind`/`span`/`label`/`ref` tree) is stored by call-location + exposed via a
  read-only tooling API. No sub-language vocabulary in the core.
- **module-system** — `mod`/`pub mod`, `root.bp`/`main.bp`, `mod.bp` folder index, tree
  resolution + path-visibility, codegen boundaries/reexports; migration generator
  piloted on `libs/std` + `examples/*`.
- **lib-test-runner** — `modules/lib-test-runner/` runs `botopink test --target <t>`
  per `libs/*` × target, aggregates a matrix, exits non-zero on any red test.
- **mutual-recursion** — confirm forward refs **run** on erlang/beam + commit the
  regression test. Test-only unless a backend run surfaces a codegen gap.

## Hand-off

- `expr-custom` → `sublanguage-lsp` (Wave 2) + `erika-query-ast`/`jhonstart-html-ast`
  (Wave 3).
- `module-system` → `libs-module-migration` (Wave 2). Its F4 codegen-emitter edits are
  the first of four such specs; `stdlib`/`cross-module`/`effect` (all Wave 2) follow by
  merge-order.

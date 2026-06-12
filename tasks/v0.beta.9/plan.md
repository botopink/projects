# v0.beta.9 — working notes (Wave 1 of 3)

The backlog is grouped into **three parallel waves** (Eric, 2026-06-10; max 3 waves).
Each version = exactly what can be touched at once; dependencies cross to a later wave.
Hard rule = **logical dependency** (a keystone lands a wave before its consumers);
shared-emitter conflicts resolve by **merge-order** (the same late-merge discipline the
prior overlaps used).

## Wave 1 = the two keystones + two independents

- **expr-custom** (keystone) — the `@ExprCustom<T>` carrier; unblocks `sublanguage-lsp`
  (Wave 2) and the two producers `erika-query-ast`/`jhonstart-html-ast` (Wave 3).
- **module-system** (keystone) — `mod`/`pub mod` + the tree; unblocks
  `libs-module-migration` (Wave 2). Pilots `libs/std` + `examples/*`.
- **lib-test-runner** — new self-contained module.
- **mutual-recursion** — regression-only (fix already landed on all four backends).

The keystones touch different core regions (template/builtins vs parser/resolver) — a
late merge resolves any `infer.zig` overlap. `lib-test-runner`/`mutual-recursion` are
fully disjoint.

## Why both keystones go first

`expr-custom`'s carrier and `module-system`'s `mod` syntax are prerequisites for the
later waves' lib work — landing both here keeps Waves 2–3 clean. `module-system`'s F4
emitter edits are the first of four codegen-emitter specs; `stdlib`/`cross-module`/
`effect` (all Wave 2) follow by merge-order.

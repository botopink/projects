# v0.beta.13 — plan

## Premise

The codebase moved fast across v0.beta.1–12. The test scenarios scattered through those
specs mix three states: (a) still valid, (b) valid behaviour but written in dead syntax,
(c) describing features that were dropped or replaced. This version distils a single,
current, **de-duplicated** scenario set per area, tagged for coverage.

## Method (how each spec was derived)

1. Extract every `## Test scenarios` block from `tasks/v0.beta.*/specs/*.md`.
2. Drop scenarios whose feature no longer exists or whose syntax is dead (see the table
   in the README).
3. Rewrite survivors in current syntax and merge duplicates across versions (e.g. the
   rakun scenarios appear in v5/v7/v8/v11 — collapsed to one current set).
4. Cross-check against the live test tree to tag `[have]` vs `[gap]`:
   - Zig: `modules/compiler-core/src/**/tests/*.zig` + `snapshots/**`.
   - `.bp`: `libs/*/test/*.bp` and inline `test {}` in `libs/*/src/*.bp`.
   - Execution: `modules/compiler-cli/tests/*.sh` (node/erlang full; beam/wasm scripted).
5. Where coverage is unclear from inspection, tag `[gap?]` — verify before writing.

## Known structural coverage gaps (cross-cutting, called out per spec)

- **beam + wasm execution** is NOT in `zig build test`; only codegen snapshots + two bash
  scripts (`mutual_recursion.sh`, `std_erlang.sh`) actually run them. Every `run/beam` and
  `run/wasm` scenario is therefore a `[gap]` unless a script covers it.
- **lib test matrix** (`lib-test-runner`) runs libs on node+erlang; beam/wasm are
  skipped-unsupported by default. erika/jhonstart/std lib execution coverage in the matrix
  is unconfirmed (they have inline `test {}` but no `test/` dir target like rakun/onze).
- **cross-module extension dispatch** lowers correctly on commonJS only; erlang/beam/wasm
  still emit local dispatch (recorded in earlier specs).

## Three parallel fronts (file-disjoint)

The work is partitioned into **3 fronts** by file territory so they run in parallel with
zero conflict (see [`README.md`](README.md) for the territory table):

- **Front A — core** (`front-a-core.md`) → `modules/compiler-core/**` Zig tests + snapshots.
- **Front B — libs & examples** (`front-b-libs.md`) → `libs/**` + `examples/**`.
- **Front C — runtime & editor** (`front-c-runtime.md` + `language-server.md` +
  `vscode-extension.md`) → `modules/{language-server,vscode-extension,compiler-cli/tests,
  lib-test-runner}`.

Boundary-spanning areas were split at the file seam: backends-parity → snapshots (A) +
execution scripts (C); sub-languages → lib expansion (B) + LSP overlay (C). Within a front,
do the high-leverage core areas first; across fronts there is no ordering — pick any.

## Done means

`zig build test` + `botopink-lib-test` stay green with the new tests added; every `[gap]`
is either closed (test added) or reclassified as a recorded product limitation.

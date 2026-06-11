# Parser Split — break the 3824-line `parser.zig` into per-sub-grammar files

**Branch**: `feat/parser-split` (worktree `task/parser-split`)
**Depends on**: nothing for the code; **coordinate with `test-reorg`** — both touch
`src/parser/` (that task adds `src/parser/tests/`, this one adds impl modules
beside it). Land one, rebase the other. No conflict in content, only in directory.
**Files**: `modules/compiler-core/src/parser.zig` (split) + new
`modules/compiler-core/src/parser/{decls,exprs,patterns,types}.zig`.
Read-only on the rest of the tree. **No AST changes, no snapshot regeneration.**
**Status**: pending

## Problem

`parser.zig` is **3824 lines**: a single `Parser` struct (l.102–3762) with
**105 methods**, plus a small tail of free helpers. It's the only oversized
source file worth splitting, because its methods form **weakly-coupled
sub-grammars** that talk to each other *only* through the token cursor
(`peek`/`advance`/`consume`) — not through shared logic. That thin seam
(`(p: *Parser) -> !Node`) is exactly a module boundary.

(Contrast: `infer.zig`, the codegen backends, and the `*tests.zig` monoliths are
**not** split here — they're either one tightly-coupled algorithm, already one
unit per backend, or a flat test list. See `tasks/test-reorg.md` for the tests.)

## Key invariant (why this is safe)

This is a **pure mechanical refactor**: no behavior change, identical AST output.

- A method `fn parseExpr(self: *Parser, …)` becomes a free function
  `pub fn parseExpr(p: *Parser, …)` in a sibling file. Same body, same `p.peek()`
  calls. Zig needs no inheritance for this — and `usingnamespace` is gone in
  0.15+, so free-functions-on-`*Parser` is *the* idiom.
- `Parser` keeps the state + core cursor methods; it exposes thin wrappers
  (`pub fn parseExpr(self) { return exprs.parseExpr(self); }`) so external
  call-sites (`parser.zig`'s `parse`, the LSP, codegen) are untouched.
- Cross-file `@import` cycle (`parser.zig` ↔ `parser/exprs.zig`) is fine — Zig
  resolves `@import` cycles as long as the **struct definition + state live in
  one file only** (here: `parser.zig`).

➜ **Zero `.snap.md` churn. No `test "…"` renamed. `zig build test` stays green
at every commit.**

## Target layout

```text
src/
├── parser.zig          ← Parser struct + state + cursor core + thin wrappers
│                          + the existing tail (ListSpreadError & friends)
└── parser/
    ├── decls.zig        ← val/fn/struct/record/enum/interface/implement/extend
    ├── exprs.zig        ← parseExpr…parsePrimary/pipeline/binary/lambda/loop/range
    ├── patterns.zig     ← parseCaseExpr / parsePattern / parseListPattern
    ├── types.zig        ← parseTypeRef / parseBaseTypeRef / parseGenericParams
    └── tests.zig + docs.md + examples.md + AGENTS.md  ← unchanged by this task
```

Each new file: `const P = @import("../parser.zig"); const Parser = P.Parser;` then
`pub fn parse…(p: *Parser, …)`. AST/token type aliases stay re-exported from
`parser.zig` (or move to a shared import — keep it minimal).

## Split map (by current line ranges in `parser.zig`)

| Stays in `parser.zig` (core) | l.102–286, 387–711, 3635–3676 + tail 3763–3824 |
|---|---|
| `parse`, `parseValForm`, `parseBlock*`, `parseParamList`, `parseAnnotations`, `parseDeclPreamble`, `consume`/`match`/`check`/`advance`/`peek`/`peekAt`, `ListSpreadError` helpers | ~700 lines |

| → `parser/decls.zig` | `parseValDecl`(713), `parseImportDecl`(969)…`parseEnumBody`(1840): fn/delegate/interface/struct/record/implement/extend/enum + shorthands |
|---|---|
| → `parser/types.zig` | `parseTypeRef`(812), `parseBaseTypeRef`(830), `parseGenericParams`(2155), `parseImplementClause`(2170) |
| → `parser/patterns.zig` | `parseCaseExpr`(1843), `parsePattern`(1963), `parseSimplePattern`(1983), `parseListPattern`(2088) |
| → `parser/exprs.zig` | `parseExpr`(2321)…`parseRangeExpr`(3743): localbind/pipeline/binary/primary/tuple/array/block/lambda/callargs/trailing-lambda/loop/range |

Target: each file < ~900 lines, `parser.zig` down to ~900 from 3824.

## Steps

- [ ] **Phase 0 — seam check.** Confirm no method dispatches on `@src().file`
  or otherwise depends on living in `parser.zig`. List any method that touches
  private fields the wrapper pattern can't reach (none expected — all state is
  on `Parser`). Decide the minimal alias-export set.
- [ ] **Phase 1 — types.zig.** Smallest, fewest callers. Extract, add wrappers,
  `zig build test` (0 snapshot churn). Commit.
- [ ] **Phase 2 — patterns.zig.** Same recipe. Commit.
- [ ] **Phase 3 — decls.zig.** Largest by line count; mind the many shorthand
  helpers. Commit.
- [ ] **Phase 4 — exprs.zig.** The hot path (precedence climbing); verify no
  perf-sensitive inlining was relied on. Commit.
- [ ] **Phase 5 — docs.** Rewrite `src/parser/AGENTS.md` (it currently says
  "the parser implementation itself is at `../parser.zig`") to document the new
  multi-file layout + the free-function-on-`*Parser` convention. Update
  `src/AGENTS.md` / `compiler-core/AGENTS.md` where they describe parser layout.
  Same commit as the code (per root AGENTS.md rule).

## Acceptance

- `zig build test` passes from `modules/compiler-core/` **and** workspace root.
- `git status` shows **zero** changed `.snap.md` files.
- No `test "…"` string changed; no external import of `parser.zig` changed.
- `git log -p` shows pure moves + wrapper insertion (no logic edits).
- `parser.zig` < ~1000 lines; each `parser/*.zig` < ~900 lines.
- `parser/AGENTS.md` describes the new layout (no stale "impl is at ../parser.zig").

## Method note (per root AGENTS.md)

Develop in a worktree: `git worktree add .tasks/parser-split -b task/parser-split feat`.
All Read/Edit/Write target `.../botopink-lang/.tasks/parser-split/...`. The
pre-commit hook runs `zig fmt` + `zig build` + `zig build test`, so each phase
commit is self-verifying. Keep `AGENTS.md` updated in the same commit.

## Test scenarios

```
seam       -- every moved method reaches Parser state via *Parser, no @src().file dep
types      -- parseTypeRef et al. moved, all parser tests pass, 0 snapshot churn
patterns   -- case/pattern tests pass after move, 0 churn
decls      -- struct/record/enum/interface/implement/extend tests pass, 0 churn
exprs      -- operator/lambda/pipeline/loop/range tests pass, 0 churn
cycle      -- parser.zig ↔ parser/*.zig @import cycle compiles
external   -- LSP + codegen still import parser.zig unchanged; build green
```

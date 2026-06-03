# Test Reorg — split monolithic `tests.zig` into per-feature `tests/` folders

**Branch**: `feat/test-reorg` (worktree `task/test-reorg`)
**Depends on**: nothing (pure test move; touches no compiler source)
**Files**: every `modules/compiler-core/src/<stage>/tests.zig` (read-only on the
rest of the tree). No `.snap.md` regeneration, no backend code.
**Status**: pending

## Problem

Each compiler-core stage keeps **one** giant `tests.zig`:

| File | test blocks | lines |
|---|---|---|
| `src/lexer/tests.zig`    | 144 | 1220 |
| `src/parser/tests.zig`   | 199 | 1946 |
| `src/format/tests.zig`   | 211 | 2159 |
| `src/comptime/tests.zig` | 195 | 2673 |
| `src/codegen/tests.zig`  | 190 | 2699 |

These are too large to navigate, diff, or `--test-filter` mentally. The
language-server already uses the good pattern — `src/tests/<feature>.zig` files
aggregated by `test_root.zig`. This task brings compiler-core to the same shape,
but **per stage**: `src/<stage>/tests/<feature>.zig` + a thin barrel.

## Key invariant (why this is safe)

Snapshot paths are derived from the **test name**, not the file name. In
`codegen/tests.zig`, `slugFromSrc(loc)` uses `loc.fn_name` (the text after
`": "`) — the source file is never part of the slug. Same holds for the other
stages' snapshot helpers.

➜ **Moving a `test "…" { … }` block to another file does not change its
snapshot.** The only hard rule: **never rename a test**. Keep every
`test "<stage>: <name>"` string byte-for-byte identical. (Verify this assumption
per stage in Phase 0 before moving anything in that stage.)

## Target layout (mirrors language-server's `src/tests/`)

```text
src/<stage>/
├── tests.zig            ← barrel: only `test { _ = @import("tests/<f>.zig"); … }`
└── tests/
    ├── helpers.zig      ← shared harness (imports + assert* fns), `pub`-exported
    ├── <feature>.zig    ← `const h = @import("helpers.zig");` + the test blocks
    └── …
```

- `test_root.zig` stays **unchanged** — it keeps importing `./<stage>/tests.zig`.
- `build.zig` stays unchanged.
- Each feature file imports the shared harness from `helpers.zig` (the
  module-level `fn`s currently at the top of each monolith become `pub fn`).

## Per-stage split

### lexer (144) → `src/lexer/tests/`
- `helpers.zig` — token-collection + assert harness
- `recognizes.zig` — single-token recognition (`recognizes …`, ~73)
- `tokenizes.zig` — multi-token sequences (`tokenizes …`, ~14)
- `strings.zig` — string literals, escapes, `\\u{…}`, unterminated
- `keywords.zig` — reserved words, `self`/`Self`, `macro`/`implement`, semicolons
- `errors.zig` — invalid escapes / error tokens

### parser (199) → `src/parser/tests/`
- `helpers.zig` — parse + AST-assert harness (`assert`, `validateListSpread`)
- `declarations.zig` — struct/record/enum/interface/implement, val/const/pub
- `imports.zig` — import / star / delegate
- `expressions.zig` — operator/lambda/array/tuple/case/builtin/range
- `destructuring.zig` — destructure/shorthand/assign

### format (211) → `src/format/tests/`
- `helpers.zig` — round-trip format harness
- `declarations.zig` — struct/interface/implement/fn/const/val/let/pub
- `imports.zig` — import
- `expressions.zig` — binary/call/access/lambda/list/tuple/array/float
- `patterns.zig` — case / pattern
- `comments.zig` — comments / doc / todo
- `idempotent.zig` — idempotent round-trips

### comptime (195) → `src/comptime/tests/`
- `helpers.zig` — `assertTypeAst`, infer harness, `@print` probes
- `infer.zig` — `infer …` (~108; split into `infer_core` / `infer_generics` if >80)
- `types.zig` — types / type_unification (~34)
- `exhaustiveness.zig` — exhaustiveness (~9)
- `effects.zig` — throw / context (~14)
- `variants.zig` — variant/record/pattern/@Result

### codegen (190) → `src/codegen/tests/`
- `helpers.zig` — `slugify`/`freshEnv`/`assertJs`/`assertJsError`/
  `assertJsSingle`/`assertJsContains` + the `configs` array
- `js_basics.zig` — val/fn/call/operators/array/tuple/struct/record
- `js_control_flow.zig` — case/loop/if/try/throw
- `js_comptime.zig` — comptime (~19)
- `js_builtins.zig` — builtin/stdlib/assert
- `js_features.zig` — lambda/enum/destructure/star/import/range/pipeline/negation
- `wat.zig` — wat (~5)

## Steps

- [ ] **Phase 0 — per stage, confirm the invariant.** Read each stage's
  snapshot helper and confirm the slug/path comes from the test name, not
  `@src().file`. If any stage keys on the file name, stop and note it here —
  that stage needs a different approach.
- [ ] **Phase 1 — lexer.** Extract `helpers.zig` (top-of-file `fn`→`pub fn`),
  move test blocks into the feature files verbatim, write the `tests.zig`
  barrel, `zig build test` (0 snapshot churn expected). Commit.
- [ ] **Phase 2 — parser.** Same recipe. Commit.
- [ ] **Phase 3 — format.** Same recipe. Commit.
- [ ] **Phase 4 — comptime.** Same recipe; split `infer.zig` further if needed.
  Commit.
- [ ] **Phase 5 — codegen.** Same recipe (largest helper surface). Commit.
- [ ] **Phase 6 — docs.** Update `src/<stage>/AGENTS.md` (and
  `src/AGENTS.md` / `compiler-core/AGENTS.md` where they describe the test
  layout) to point at the new `tests/` folders. Update `git diff --stat`
  expectations note if any.

## Acceptance

- `zig build test` passes from `modules/compiler-core/` **and** the workspace root.
- `git status` shows **zero** changed `.snap.md` files (the move is name-stable).
- No `test "…"` string was renamed (`git log -p` shows pure moves +
  helper extraction).
- `test_root.zig` and both `build.zig` files are unchanged.
- Each new `tests/<feature>.zig` is < ~600 lines; no monolith remains.

## Method note (per root AGENTS.md)

Develop in a worktree: `git worktree add .tasks/test-reorg -b task/test-reorg feat`.
All Read/Edit/Write target `.../botopink-lang/.tasks/test-reorg/...`. The
pre-commit hook runs `zig fmt` + `zig build` + `zig build test`, so each phase
commit is self-verifying. Keep `AGENTS.md` updated in the same commit that moves
the files.

## Test scenarios

```
invariant -- moving a test block does not alter its .snap.md path (slug = test name)
lexer     -- all 144 tests pass after split, 0 snapshot churn
parser    -- all 199 tests pass after split, 0 snapshot churn
format    -- all 211 tests pass after split, 0 snapshot churn
comptime  -- all 195 tests pass after split, 0 snapshot churn
codegen   -- all 190 tests pass after split, 0 snapshot churn
wiring    -- test_root.zig unchanged; `zig build test` discovers every block
filter    -- `zig build test -- --test-filter "lexer: recognizes plus"` still hits
```

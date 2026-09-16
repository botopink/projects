# Spec 05 — Repo hygiene

**Version:** 1.0.1-beta
**Status:** closed — what this spec did not reach is carried by
[`1.0.2-beta/11-hygiene/README.md`](../1.0.2-beta/11-hygiene/README.md)
**Priority:** low

---

## Objective

Close the findings of the 1.0.0-beta docs audit and the hygiene findings of the snapshot review
(spec 06) that are not compiler bugs. Seventeen items were opened (5.1–5.17); the milestone
closed four of them. This file records what changed and how it is verified; the other thirteen
keep their numbers in the 1.0.2-beta spec.

Paths are relative to `repository/botopink-lang/` unless they start with `meta:`.

---

## What the milestone delivered

### 5.11 — Dead language-server test files (spec 06 H7)

`modules/language-server/src/tests/snapshot_test.zig` (the unit tests of the snapshot renderers)
was in no test root and would not have compiled; `src/tests/root.zig` was a stale second entry
list that the build never read.

| Change | Where |
|---|---|
| `snapshot_test.zig` registered in the build's test root | `src/test_root.zig:25` |
| `appendSourceWithCursor` made `pub` so the unit tests can call it | `src/tests/snapshot.zig:664` |
| The stale second entry list deleted | `src/tests/root.zig` (gone) |
| Doc corrected — the file is the renderers' unit suite, not "the shared snapshot harness" | `src/tests/AGENTS.md:7,17` |

**Verified:** `src/tests/` no longer contains `root.zig`; `test_root.zig` imports
`./tests/snapshot_test.zig`; `zig build test` is green.

### 5.12 — The retired `@[…]` annotation opener is rejected

`parseAnnotations` accepted `@[…]` as a "legacy form (kept for migration)" and marked every
annotation in it builtin. It is now a diagnostic of its own.

| Change | Where |
|---|---|
| `ParseErrorType.retiredAnnotationBlock` added | `modules/compiler-core/src/parser.zig:122` |
| `parseAnnotations` rejects `@[`, spanning the two opener characters | `parser.zig:678` (`fromTokenSpan(.retiredAnnotationBlock, …, "@[".len)`) |
| Message, caret caption and hint naming the `#[@name(…)]` replacement | `modules/compiler-core/src/print.zig:124-128` |
| The lookaheads still *recognise* `@[`, so a stale opener reaches this diagnostic instead of a bare "unexpected token" | `parser.zig:656-668`, `parser/AGENTS.md:118` |
| Parser error test asserting the rejection and its rendered text | `parser/tests/errors.zig:141-160` |

**Verified:** the rendered diagnostic is ``error: the `@[…]` annotation block was retired`` with
``write `#[…]` instead`` under the caret; no `.bp` in the tree or in the sibling libraries uses `@[`.

### 5.13 (parser fixtures) — Retired vocabulary migrated

The parser fixtures that still carried the retired `@external(<target>, …)` form and snake_case
names were rewritten and their snapshots re-recorded.

| Fixture | Now |
|---|---|
| `parser/tests/declarations.zig:398-399`, `:598-599` | `#[@External.Erlang(…), @External.Node(…)]` |
| `parser/tests/declarations.zig:406-410` | `absoluteValue` |
| `parser/tests/expressions.zig:687` | `s?.toUpper()` |

The comment sites and `comptime/tests/infer_decls.zig` were **not** rewritten — see 5.13 in the
1.0.2-beta spec.

### 5.15 — Ignore rules

| Change | Where |
|---|---|
| `*.snap.md.new` ignored (spec 06 step 1.2 — a snapshot mismatch writes one next to the snapshot; 1.0.0-beta committed 9 by mistake) | `.gitignore` |
| `erl_crash.dump` ignored in the compiler repo | `.gitignore` |
| `erl_crash.dump` and `/.serena/` ignored in the meta repo | `meta:.gitignore` |

**Verified:** `find modules -name '*.snap.md.new'` is empty and `git status` in either repo is
clean of both patterns.

---

## Acceptance (met)

- [x] 5.11, 5.12, 5.15 fixed; 5.13 fixed for the parser fixtures
- [x] The matching `AGENTS.md` files (`src/tests/AGENTS.md`, `parser/AGENTS.md`) updated with the change
- [x] `zig build` and `zig build test` green
- [x] Every item not closed here re-checked at HEAD and carried, with its number, to
      [`1.0.2-beta/11-hygiene/README.md`](../1.0.2-beta/11-hygiene/README.md)

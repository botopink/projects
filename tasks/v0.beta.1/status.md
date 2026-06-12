# Task status

> **Single source of truth for v0.beta.1 state.** The README carries no status
> column — it links here. (Today hand-maintained; `scripts/status.sh` will later
> regenerate it — see the `docs-refactor` spec, F4.)
>
> Real survey cross-referencing each spec (`specs/*.md`) **and the `TODO.md`
> of every worktree in `.tasks/{name}/`** with the git history and branch state.
> The `Status` headers in `specs/*.md` are coarse and reflect the moment the spec
> was written; the `TODO.md` inside each worktree is more faithful, since it
> follows the branch tip. This is the synthesis.
>
> Reference branch: `feat` (HEAD `3746eae`), already rebased onto `origin/feat`.
> Survey date: 2026-06-02.

## Summary

| # | Task | Branch | Real status | Where it is |
|---|---|---|---|---|
| 1 | ast-simplification | `task/ast-simplification` | ✅ Done (Phases 1–7) | in `feat` |
| 2 | import-rework | `task/import-rework` | ✅ Done (F0–F2) | in `feat` |
| 3 | use-await-prefix | `task/use-await-prefix` | ✅ Done (F3, absorbed) | in `feat` |
| 4 | implement-extend-decls | `task/implement-extend-decls` | ✅ Done (F4–F5) | in `feat` |
| 5 | context-inference | `task/context-inference` | ✅ Done (F7) | in `feat` |
| 6 | throw-check | `task/throw-check` | ✅ Done | in `feat` |
| 7 | trycatch-lowering | `task/trycatch-lowering` | ✅ Done (all backends) | in `feat` |
| 8 | typeparam | `task/typeparam` | ✅ Done | in `feat` |
| 9 | async-generators | `task/async-generators` | ✅ Done | in `feat` |
| 10 | erlang-gaps | `task/erlang-gaps` | ✅ Done | in `feat` |
| 11 | interface-coverage | `task/interface-coverage` | ✅ Done (Phases 1–4) | in `feat` |
| 12 | beam-asm | `task/beam-asm` | 🔶 Partial (Phases 1–2 + ranges + try/catch; Phases 3–9 pending) | in `feat` |
| 13 | stdlib-result | `task/stdlib-result` | 🟡 Implemented (BEAM/WASM backends = stub), **not in `feat`** | branch `task/stdlib-result` (`5f279b5`) |
| 14 | extension-dispatch | `task/extension-dispatch` | 🟡 Implemented (F6); non-JS codegen = follow-up, **not in `feat`** | branch `task/extension-dispatch` (`fb43ef2`) |
| 15 | hook-codegen | `task/hook-codegen` | 🟡 Implemented (F8), **not in `feat`** | branch `task/hook-codegen` (`26ee8a5`) |
| 16 | tooling | `task/tooling` | 🟡 Implemented (`case` exhaustiveness = partial), **not in `feat`** | branch `task/tooling` (`464ce4c`) |
| 17 | wat-features | `task/wat-features` | ⛔ Not started (branch stuck at the base commit) | — |

**Count:** 11 done · 1 partial · 4 ready-but-not-integrated · 1 not started.

---

## ✅ Done and integrated into `feat`

### 1. ast-simplification (Phases 1–7)
Full parser/AST refactor. Commits `98eac26` → `5a89d88` (construction helpers,
block unification, table-driven binary operators, flattening of `BinOp`/`UnaryOp`/`Loop`,
merge of `lambda`/`fnExpr` into `FunctionExpr`, unification of the declaration preamble,
merge of pattern variants). Marked done in `4538bf1`.

### 2. import-rework (F0–F2)
`import {A, X*} [from "name"]` syntax. Commit `a0c77f1` (parse + dispatch activation via `*`).

### 3. use-await-prefix (F3)
Prefix operators `use` and `await`. Delivered in a distributed way: `useHook` in `a42d948`,
use-hook support in `3d00c0a`, and the `await` token/prefix alongside the async-generators delivery.

### 4. implement-extend-decls (F4–F5)
Named `implement` (shorthand) + `extend` declarations. Commit `274da22`, done in `63da4ee`.

### 5. context-inference (F7)
`@Context<B, R>` capability inference (`use` rules). Commit `f78a5fc` (+ validation and tests).

### 6. throw-check
Type-check of `throw` against the enclosing function's `@Result<D, E>` `E`. Commit `5ed68d9`.

### 7. trycatch-lowering
Lowering of `try`/`catch` to Ok/Error pattern matching across **all** backends
(CommonJS, Erlang, BEAM ASM, WAT). Commit `b108139`.

### 8. typeparam
Typeparam constraints (`comptime f: typeparam A | B`) — parse, inference, validation,
specialization. Commit `21b23be`.

### 9. async-generators
`*fn`, `await`, `yield :label`, `loop await`, iterators. Commits `f6a0d62` (front-end),
`ffad0fb` (inference validation), `3ee8e44` (Erlang/BEAM/WAT lowering), `3746eae` (LSP).

### 10. erlang-gaps
Lowering of module-qualified calls + closing gaps in `case` patterns. Commit `38117cb`.

### 11. interface-coverage (Phases 1–4)
Per `.tasks/interface-coverage/TODO.md` (Status: *done — all four phases*):
- ✅ Phase 1 parser, Phase 2 inference, Phase 4 codegen (struct→class, record→constructor,
  Erlang map+accessors, BEAM/WAT) — largely pre-existing.
- ✅ Phase 3 semantic validation — `validateProgram` pass (commit `e10b01b`):
  `missingMethod`, `unknownMethod`, `unknownInterface`, `ambiguousMethod` + getters/setters.
- Note: the **external dispatch** of methods (`obj.m()` → `Sym.m(obj)`) is NOT part of this task —
  it lives in `extension-dispatch` (see §14, not merged).

---

## 🔶 Partially done (in `feat`)

### 12. beam-asm
- ✅ Phases 1–2 + ranges via `lists:seq/2` + try/catch in statement position (commit `5a9302b`,
  plus `1705da2`, `d090e36`).
- ⏳ Pending: Phase 3 (strings/binaries), 4 (records/structs), 5 (enums), 6 (closures/lambdas),
  7 (full ranges), 8 (full try/catch), 9 (polish).

---

## 🟡 Implemented, but **still outside `feat`** (awaiting integration)

> These have code ready on the branch, but were not merged into `feat`. Each one also
> lives as a worktree in `.tasks/`.

### 13. stdlib-result — `.tasks/stdlib-result/TODO.md` (Status: done)
`@Result` / `@Option` methods (`map`, `flatMap`, `unwrapOr`, `isOk`/`isError`, `@Option` mirror).
Brought along a **method-call** subsystem: `CallExpr.receiver` became an expression (chains
`a().map(f).unwrapOr(0)`), inference registers lowerings in `Env.method_lowerings` (keyed by loc),
and `transform` rewrites to builtins `__bp_<domain>_<op>(...)`.
- ✅ All 5 steps + 9 test scenarios.
- ⚠️ Codegen: **CommonJS and Erlang** emit the correct inline form; **BEAM and WASM** emit a
  **documented stub** (no `Result` runtime representation / higher-order inlining yet).
- Branch `task/stdlib-result` (`5f279b5`). **Integration worktree:**
  `.tasks/_integrate-stdlib-result` (branch `integrate/stdlib-result`), where it was combined with the
  other features; contains **uncommitted** changes in `CHANGELOG.md` and `docs.md`.

### 14. extension-dispatch (F6) — `.tasks/extension-dispatch/TODO.md` (Status: implemented ✅)
Static extension dispatch (Rust/C# model): `obj.m()` resolves only if the impl/extension is
**activated** (`X*` in the import or `X*;`). Syntax `import {A, X*, B as C}`, `Name*;`, `val Name = extend T {…}`.
- ✅ Inference: all 8 steps (activation set, `env.extensions` table, inherent→activated→error
  resolution, qualified calls, error messages). Rewrites keyed by loc in `env.dispatchRewrites`.
- ✅ **CommonJS** codegen complete (impl/extend → namespace object; `obj.m()` → `Sym.m(obj)`).
- ⏳ **Erlang / BEAM / WAT / TypeScript** codegen: the decls compile, but the call-site
  rewrite is **follow-up**.
- ⚠️ On this branch the snapshot suite is not wired into `zig build test` (root = `root.zig`);
  snapshots generated by running the suite directly.
- Open points: orphan rule (P2), re-export of `pub import` (P3), scope of `X*` (P4).
- Branch `task/extension-dispatch` (`fb43ef2`). Prerequisite for the external dispatch of interface-coverage.

### 15. hook-codegen (F8) — `.tasks/hook-codegen/TODO.md`
Lowering of `use` hooks (`val {v, s} = use state(0)` → `useState(0)` in CommonJS; emission of
`@Context` interfaces in the `.d.ts`; "phantom" erasure of the inline implement). Branch
`task/hook-codegen` (`26ee8a5`), built on context-inference (F7).

### 16. tooling — `.tasks/tooling/TODO.md` (Status: done)
- ✅ **LSP**: go-to-definition of imported symbols, autocomplete of struct/record fields and enum
  variants, type-error diagnostics (squiggles).
- ✅ **Formatter**: `@Result<D, E>`, `comptime` with constraints, inline `struct implement @Context<B, R>`.
- ✅ **Lambdas**: full type annotation `val f: fn(string,i32)->string = {…}` with param inference.
- ✅ **Pattern matching**: nested patterns (`Ok(Some(n))`), guard clauses (`case x { n if n>0 -> … }`
  with parser/AST/inference/formatter/CommonJS; guard codegen for erlang/beam/wasm follows their roadmap).
- 🔶 **`case` exhaustiveness**: partial (pre-existing) — only rejects a single non-wildcard arm;
  full coverage analysis is future work.
- Branch `task/tooling` (`464ce4c`).

---

## ⛔ Not started

### 17. wat-features
The `task/wat-features` branch is stuck at `3d00c0a` (the roadmap's base commit), with no work of its own.
The planned features (destructure, pipeline lowering, string ops, enum/record layout in linear
memory, tag-based try/catch) were **not implemented** — the WAT try/catch that exists came from
`trycatch-lowering`, not from this task.

---

## `.tasks/` worktrees

The project uses one worktree per task in `.tasks/`. Current state (`git worktree list`):

| Worktree | Branch | Commit | Note |
|---|---|---|---|
| `_integrate-stdlib-result` | `integrate/stdlib-result` | `b02829b` | integration; uncommitted changes |
| `async-generators` | `task/async-generators` | `821019c` | work already in `feat` (rebased) |
| `extension-dispatch` | `task/extension-dispatch` | `fb43ef2` | outside `feat` |
| `f6-dispatch` | `f6-dispatch` | `ad2fa44` | old pre-rebase tip of `feat` |
| `hook-codegen` | `task/hook-codegen` | `26ee8a5` | outside `feat` |
| `interface-coverage` | `task/interface-coverage` | `e10b01b` | already in `feat` |
| `stdlib-result` | `task/stdlib-result` | `5f279b5` | outside `feat` |
| `tooling` | `task/tooling` | `464ce4c` | outside `feat` |
| `use-await-prefix` | `task/use-await-prefix` | `3d00c0a` | already in `feat` |
| `wat-features` | `task/wat-features` | `3d00c0a` | not started |
| (several `prunable`) | … | … | branches already in `feat`, prunable worktrees (`git worktree prune`) |

> Each worktree in `.tasks/{name}/` carries its own `TODO.md` at the branch-tip state —
> it is the granular source (per-step checkboxes) used to build this document. The `prunable`
> worktrees (branches already in `feat`) can be cleaned with `git worktree prune`.

## Suggested next steps

1. **Integrate into `feat`** the 4 branch-ready features: `tooling`, `stdlib-result`,
   `extension-dispatch` (F6) and `hook-codegen` (F8) — respecting dependencies
   (`context-inference`, already in `feat`, enables `hook-codegen`).
2. **Finish codegen** for the pending backends: external dispatch for Erlang/BEAM/WAT/TS
   (`extension-dispatch`) and a real `@Result`/`@Option` runtime in BEAM/WASM (`stdlib-result`).
3. **Advance beam-asm** Phases 3–9 (strings, records, enums, closures, polish).
4. **Implement wat-features** from scratch.
5. **`case` exhaustiveness** (full coverage analysis) — pending in `tooling`.

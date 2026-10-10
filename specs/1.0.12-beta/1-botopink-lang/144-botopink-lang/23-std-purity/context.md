# Front 23 — std purity: the gate's rows and three confirmations

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [144-botopink-lang](../README.md): s1 → B-27 · s2 → B-27. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** low · **State:** not started (std tree of decisions 106–111 landed in 1.0.10, C-31)
**Depends on:** maintainer confirmations 23-b, std-c (23-c → 317) · std track (`../02-std-and-packaging/`,
owner of `libs/std/src/**`)
**Owns:** `modules/language-server/src/project_graph.zig`'s import-tree cells (carve-out —
`modules/language-server/src/tests/**` is 07's) · `libs/std/AGENTS.md` (with 07) · `docs.md` §
imports, § std (with 07 — supplied here, placed by 07) · import-tree paragraphs of the `AGENTS.md`
of `src/parser/`, `src/comptime/`, `src/codegen/`, `modules/language-server/` · the `modules/import_*`
cells it verifies
**Does not touch:** `parser/decls.zig`'s `parseImportItem`, `comptime/infer.zig`'s import binding,
the four `emitUse` (01, 02–05) · `libs/std/src/**` · `build.zig`'s `stdPkgFilesFromRoot` ·
`builtins.d.bp`, `primitives.bp`, `erlang.bp`, `beam.bp`

Paths relative to `repository/botopink-lang/`.

## Goal

Decision 106's import tree (pure root, `io/`, `testing/`) and decision 107's grammar pinned by
four-target cells and LSP snapshots, documented in the five `AGENTS.md`; the four 1.0.10 choices
confirmed by number.

## Decisions

- 23-c confirmed (317) · 23-b, std-c — to confirm (23-a moot: both forms landed); statements in
  [1.0.10's `decisions-pending.md`](../../../../1.0.10-beta/decisions-pending.md)

**Gate:** standard (fronts.md § Gate) + `zig build test-libs` at baseline

## Notes

- A std row a compiler front measures goes to `../../02-std-and-packaging/` with the cell; this
  front's files = compiler documents and LSP cells.
- Decision 71 holds with path `testing.mocks`: one module, lib-agnostic.

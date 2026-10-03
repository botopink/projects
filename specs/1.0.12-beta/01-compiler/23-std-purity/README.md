# Front 23 — std purity: the gate's rows and three confirmations

**Priority:** low · **State:** not started (std tree of decisions 106–111 landed in 1.0.10, C-31)
**Depends on:** maintainer confirmations 23-b, 23-c, std-c · std track (`../02-std-and-packaging/`,
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

## Open

### Step 1 — the gate's rows

`zig build test-language` green on four targets with the import cells (`modules/import_alias_on_type`,
`import_std_type_through_module`, `import_std_folder_namespace`, `import_type_closure*`,
`import_type_alias`); language-server tests with the `project_graph.zig` cells (one `lsp/` snapshot
per import spelling).

- [ ] `run.sh --target all` green on the `modules/import_*` cells — measured, the box ticked
- [ ] `grep -l 'import {' modules/language-server/snapshots/lsp/*.snap.md` lists one snapshot per spelling (dotted, grouped, `*`, `as`, a folder leaf); missing ones added
- [ ] the five `AGENTS.md` name the tree and the grammar; `docs.md` § imports / § std verified against the grammar (07 places any correction)

### Step 2 — the confirmations

23-b (`base64` retired), 23-c (the two `botopink test` folder fixes in `test_cmd.zig` / `libs.zig`,
landed), std-c (namespace rewrite): each confirmed or reversed; a reversal opens a step in the owner
(26 for 23-c, 01 for std-c).

- [ ] the three ids in `../../decisions-taken.md` with their numbers, or a reversal's step named

## Decisions

- 23-b, 23-c, std-c — to confirm (23-a moot: both forms landed); statements in
  [1.0.10's `decisions-pending.md`](../../../1.0.10-beta/decisions-pending.md)

**Gate:** standard (fronts.md § Gate) + `zig build test-libs` at baseline

## Notes

- A std row a compiler front measures goes to `../../02-std-and-packaging/` with the cell; this
  front's files = compiler documents and LSP cells.
- Decision 71 holds with path `testing.mocks`: one module, lib-agnostic.

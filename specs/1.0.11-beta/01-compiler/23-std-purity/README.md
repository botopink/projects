# Front 23 — std purity: the gate's rows

**Priority:** low — steps 1–6 are landed (C-31); what is open is the gate's own rows and four
confirmations.
**Depends on:** `00-gate` (FC-1 — `libs/std` reformatted and in `TREES` before this front's
`AGENTS.md` edits) · the std track (`../02-std-and-packaging/`, which owns `libs/std/src/**` this
milestone) · maintainer confirmations 23-a, 23-b, 23-c, std-c.
**Owns:** `modules/language-server/src/project_graph.zig`'s import-tree cells (the carve-out 1.0.10
granted from 11 — `modules/language-server/src/tests/**` is 07's, the cells are added as a named
carve-out) · `libs/std/AGENTS.md` (with 08) · `docs.md` § imports, § std (with 08 — this front
supplies, 08 places) · the `AGENTS.md` of `src/parser/`, `src/comptime/`, `src/codegen/`,
`modules/language-server/` for the import-tree paragraphs · the cells `modules/import_*` it verifies
**Does not touch:** `parser/decls.zig`'s `parseImportItem`, `comptime/infer.zig`'s import binding,
the four `emitUse` (landed; 01 and 02–05 own the files now) · `libs/std/src/**` (the std track) ·
`build.zig`'s `stdPkgFilesFromRoot` (landed; 18's `build.zig`) · `scripts/known-red-libs.txt`
(00-gate) · `builtins.d.bp`, `primitives.bp`, `erlang.bp`, `beam.bp`.
**Does not touch until 00-gate lands:** `libs/std/AGENTS.md` (FC-1 reformats the tree it documents).

Paths are relative to `repository/botopink-lang/`.

## Carried from 1.0.10

| Item | 1.0.10 spec | Heading |
|---|---|---|
| the gate's rows | `23-std-purity/README.md` | § Gate, boxes 2–4 |
| 23-a, 23-b, 23-c, std-c | `decisions-pending.md` | the four ids |
| the `docs.md:756` grammar | `23-std-purity/README.md` | § Step 1, last box — **verified replaced**; closed on tick |
| step 4's `reject/` cell | `23-std-purity/README.md` | § Step 4 — satisfied by the `std_package_a_root_module_importing_*` error snapshots; closed on tick |

## What holds

The tree of decision 106 (a pure root, `io/`, `testing/`), the import grammar of decision 107,
decisions 110 and 111's use side (`comptime/std_namespace.zig`, std-c), the purity refusal
(`std-root-imports-io`), the consumer sweep, `known-red-libs.txt` at its header. Measured at the
open: `zig build test-libs -- --lib std` at its count on commonJS and erlang.

## Steps

### Step 1 — the gate's rows

`zig build test-language` green on four targets with the import cells
(`modules/import_alias_on_type`, `import_std_type_through_module`, `import_std_folder_namespace`,
`import_type_closure*`, `import_type_alias`); `modules/language-server` tests green with the
`project_graph.zig` cells (one `lsp/` snapshot per import spelling — verify they exist; add the
missing ones as the named carve-out); the five `AGENTS.md` carry the import-tree paragraphs.

**Acceptance:**
- [ ] `run.sh --target all` (and `beam`) green on the `modules/import_*` cells — measured, the boxes ticked
- [ ] `grep -l 'import {' modules/language-server/snapshots/lsp/*.snap.md` lists one snapshot per spelling (dotted, grouped, `*`, `as`, a folder leaf); the missing ones added
- [ ] the five `AGENTS.md` name the tree and the grammar; `docs.md` § imports / § std verified against the grammar (08 places any correction)

### Step 2 — the confirmations

23-a (the `collections` leaf — both forms landed), 23-b (`base64` retired), 23-c (the two
`botopink test` folder fixes, a compiler-cli carve-out landed), std-c (the namespace rewrite): each
confirmed or reversed by the maintainer; a reversal opens a step in the owning front (26 for 23-c,
01 for std-c).

**Acceptance:**
- [ ] the four ids in `../decisions-taken.md` with their numbers, or a reversal's step named

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in this front's worktree
- [ ] `zig build test-libs` at baseline; `zig build test-language` green on four targets
- [ ] `AGENTS.md` ×5 in the same commit
- [ ] Commit on `fix/23-std-purity`; no push, no merge

## Blast radius

None on emitted output; documents and cells.

## Notes

- `libs/std/src/**` moved to the std track this milestone: a std row a compiler front measures
  (C-35's body, T18's template, `asserts.bp` under ck-host, the `async` delay flake) is handed to
  `../02-std-and-packaging/` with the cell; this front's remaining files are the compiler's
  documents and the LSP's cells.
- Decision 71 holds with the path `testing.mocks`: one module, lib-agnostic.

# Front 26 — cli-tooling: a program built by the CLI serves on the BEAM, and every driver speaks

**Priority:** high · **State:** partial: steps 1, 2 (boxes 1–2), 3 (box 2), 4 (box 1) and 5 on feat;
steps 2 (box 3), 3, 4, 6, 7, 8 open
**Depends on:** `compiler-core`'s `ModuleOutput` carrying the warnings (step 4 — a `codegen.zig`
carve-out named in the commit) · decision-gated lg2-v (a git subdirectory — the manifest side is
`../../02-std-and-packaging/98-packaging-tail/` step 4; the `bpmp` resolver half opens here when
answered) · `23-std-purity` step 2 (23-c's two `botopink test` fixes confirmed — this front's files)
**Owns:** `modules/compiler-cli/**` (`src/cli/{build,run,test_cmd,libs,sources,config,resolver}.zig`,
the rest, `tests/**`) · `modules/bpmp/**` except `src/manifest.zig` under 98's step 4 ·
`modules/language-server/src/**` except `src/tests/**` (07) and `project_graph.zig`'s import-tree
cells (23) · `modules/language-server/snapshots/lsp/**` · `repository/vscode-extension/**` ·
`scripts/test-vscode.sh` · root `build.zig` except 18's `render-resident` / `compiler-web` steps
(decision 219) · the cells its steps add
**Does not touch:** `modules/compiler-core/**` (a CLI row that needs the emitter is 02's or 03's
step, named) · `scripts/gate.sh`, `scripts/check-docs.sh` (`00-gate/114`) · `modules/manifest/**` (98)

Paths are relative to `repository/botopink-lang/modules/` unless a row says otherwise.

## Goal

`botopink build` / `run` ship and load every sidecar `test` does, on erlang and beam; an import
names only a declared dependency (decision 242); `build`, `test` and the LSP print the checker's
warnings as `check` does.

## Done

- Step 1 — the sidecars ship for `build` and `run`, on erlang and beam; with `02-erlang` step 9 the T1 row closes (`modules/erlang_host_sidecar_shipped` as a built program, `compiler-cli/tests/cli_contract.sh`)
- Step 2, boxes 1–2 — a nested module's sidecar and a sidecar named like an emitted atom (T16, C-25: `modules/sidecar_called_from_folder_module`, `modules/sidecar_named_like_emitted_atom`)
- Step 3, box 2 — the jhonstart-forms shape re-measured: a package declaring only `jhonstart-forms` builds and runs (decision 143)
- Step 4, box 1 — the LSP renders a checker warning (`diagnostics_checker_warning`, severity Warning)
- Step 5 — `botopink clean` removes `.botopinkbuild/` whole, written in `docs.md` § Backends and `clean --help`

## Open

### Step 2 — rakun's workaround (box 3)

- [ ] rakun fronts 77/78's `src/orm_host.bp` workaround deletable — the rakun track's row, noted
      so it sees the fix

### Step 3 — only a direct dependency is importable (T4, decision 242)

`import {rkProp} from "rakun";` with only `rakun-starter-web` declared is `error: unresolved import
source "rakun" — declare it in botopink.json "dependencies"` (`cli/sources.zig`,
`proj.dependencyNames`); the rakun starters declare what they import. `import {linkPrefetch} from
"jhonstart-link"` from a package declaring only `jhonstart-forms` is the same refusal.

- [ ] `modules/transitive_package_import` — `.expect` with the named diagnostic, on four targets

### Step 4 — `Env.warnings` reach `build` and `test`

`codegen.generateWith` drops the comptime session (`OkData.warnings`) before it returns and
`ModuleOutput` has no warnings field; the CLI half is a renderer call once it has one
(`diagnostics.renderOutcome`'s `.ok` arm).

- [ ] a `test-cli` contract case: `build` and `test` print the `var out = [];` warning; C-18's box 3 closed

### Step 6 — lg2-v's resolver half (decision-gated)

When lg2-v is answered with a `subdir` field, `bpmp`'s resolver checks the dependency out at the
subdirectory (98 step 4 owns the manifest model); nothing before.

### Step 7 — the `build.zig` `test-docs` comment (handed by `00-gate/114`)

`build.zig`'s `test-docs` comment (near `:574`) still describes `<!-- docs-check: skip <reason> -->`,
which decision 157 deleted.

- [ ] the comment describes `check-docs.sh`'s `reject` / `project` / `body` directives

### Step 8 — decision 206's residuals (from `129-import-without-from`)

The language server runs no import-source check (F4 or `module-import-with-from`): an editor shows
`from "<own module>"` as resolving until `botopink check` refuses it. And `from "<own package
name>"` inside the package itself (a bundled library's own tests: `log` 1, `routing` 1,
`validation` 2, `std` 8 files) still reads the package's own modules — measure whether that is the
rule (the package is its own name) or a leftover, and write the answer.

- [ ] the LSP reports `module-import-with-from` and `unresolved import source` as `check` does — one
      `lsp/` snapshot each
- [ ] a package importing itself by name: the rule written in `docs.md` § Imports (07 places it) and
      pinned by a `resolver.zig` unit test, or the imports migrated and refused

**Gate:** standard (fronts.md § Gate) + `zig build test-cli`, `test-bpmp`, `test-vscode` green; the
language-server tests green with the new snapshots · `zig build test-libs` at baseline (rakun's
members exercise every sidecar path)

## Notes

- `project_graph.zig` is shared with 23 (the import-tree cells) and `src/tests/**` with 07; both are
  named carve-outs, sequenced by commit.
- The `wip/br5-beam-templates` branch (C-24) is the maintainer's to delete.

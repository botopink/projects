# Front 26 — cli-tooling: a program built by the CLI serves on the BEAM, and every driver speaks

**Priority:** high · **State:** partial: steps 1, 2 (boxes 1–2), 3 (box 2), 4 (box 1) and 5 on feat;
steps 2 (box 3), 3, 4, 6, 7, 8 open
**Depends on:** `compiler-core`'s `ModuleOutput` carrying warnings (step 4 — `codegen.zig` carve-out
named in the commit) · decision-gated lg2-v (git subdirectory — manifest side is
`../../02-std-and-packaging/98-packaging-tail/` step 4; `bpmp` resolver half opens here when
answered) · 23-c's two `botopink test` fixes confirmed (decision 317 — this front's files, kept)
**Owns:** `modules/compiler-cli/**` (`src/cli/{build,run,test_cmd,libs,sources,config,resolver}.zig`,
the rest, `tests/**`) · `modules/bpmp/**` except `src/manifest.zig` under 98's step 4 ·
`modules/language-server/src/**` except `src/tests/**` (07) and `project_graph.zig`'s import-tree
cells (23) · `modules/language-server/snapshots/lsp/**` · `repository/vscode-extension/**` ·
`scripts/test-vscode.sh` · root `build.zig` except 18's `render-resident` / `compiler-web` steps
(decision 219) · its cells
**Does not touch:** `modules/compiler-core/**` (a CLI row needing the emitter is a named 02/03 step)
· `scripts/gate.sh`, `scripts/check-docs.sh` (`00-gate/114`) · `modules/manifest/**` (98)

Paths relative to `repository/botopink-lang/modules/` unless a row says otherwise.

## Goal

`botopink build` / `run` ship and load every sidecar `test` does, on erlang and beam; imports name
only declared dependencies (decision 242); `build`, `test` and the LSP print checker warnings as
`check` does.

## Done

- Step 1 — sidecars ship for `build` and `run` on erlang and beam; with `02-erlang` step 9 T1 closes (`modules/erlang_host_sidecar_shipped` as a built program, `compiler-cli/tests/cli_contract.sh`)
- Step 2, boxes 1–2 — nested module's sidecar, sidecar named like an emitted atom (T16, C-25: `modules/sidecar_called_from_folder_module`, `modules/sidecar_named_like_emitted_atom`)
- Step 3, box 2 — jhonstart-forms shape re-measured: a package declaring only `jhonstart-forms` builds and runs (decision 143)
- Step 4, box 1 — LSP renders a checker warning (`diagnostics_checker_warning`, severity Warning)
- Step 5 — `botopink clean` removes `.botopinkbuild/` whole, in `docs.md` § Backends and `clean --help`

## Open

### Step 2 — rakun's workaround (box 3)

- [ ] rakun fronts 77/78's `src/orm_host.bp` workaround deletable — rakun track's row, noted here

### Step 3 — only a direct dependency is importable (T4, decision 242)

`import {Request} from "rakun";` with only `rakun-starter-web` declared = `error: unresolved import
source "rakun" — declare it in botopink.json "dependencies"` (`cli/sources.zig`,
`proj.dependencyNames`); rakun starters declare what they import. Same refusal for `import
{linkPrefetch} from "jhonstart-link"` from a package declaring only `jhonstart-forms`.

- [ ] `modules/transitive_package_import` — `.expect` with the named diagnostic, on four targets

### Step 4 — `Env.warnings` reach `build` and `test`

`codegen.generateWith` drops the comptime session (`OkData.warnings`) before returning;
`ModuleOutput` has no warnings field. CLI half then = a renderer call (`diagnostics.renderOutcome`'s
`.ok` arm).

- [ ] a `test-cli` contract case: `build` and `test` print the `var out = [];` warning; C-18's box 3 closed

### Step 6 — lg2-v's resolver half (decision-gated)

If lg2-v is answered with a `subdir` field, `bpmp`'s resolver checks the dependency out at the
subdirectory (98 step 4 owns the manifest model); nothing before.

### Step 7 — the `build.zig` `test-docs` comment (handed by `00-gate/114`)

`build.zig`'s `test-docs` comment (near `:574`) still describes `<!-- docs-check: skip <reason> -->`
(deleted by decision 157).

- [ ] the comment describes `check-docs.sh`'s `reject` / `project` / `body` directives

### Step 8 — decision 206's residuals (from `129-import-without-from`)

- LSP runs no import-source check (F4 or `module-import-with-from`): editor shows `from "<own
  module>"` resolving until `botopink check` refuses it.
- `from "<own package name>"` inside the package still reads its own modules; decision 309 refuses it
  (`module-import-with-from`, as 206). Measured 9 Oct: no test imports its own package by name; 3 std
  sources do (`std/src/querystring.bp:28`, `std/src/testing/snapshots.bp:49-51`, `std/src/io/fs.bp:20`).

- [ ] the LSP reports `module-import-with-from` and `unresolved import source` as `check` does — one
      `lsp/` snapshot each
- [ ] `from "<own package name>"` is `error[module-import-with-from]` (309), pinned by a `resolver.zig`
      unit test; the three std sources migrated to the brace form in the same commit (a named
      `libs/std/src` carve-out)

**Gate:** standard (fronts.md § Gate) + `zig build test-cli`, `test-bpmp`, `test-vscode` green;
language-server tests green with new snapshots · `zig build test-libs` at baseline (rakun's members
exercise every sidecar path)

## Notes

- `project_graph.zig` shared with 23 (import-tree cells), `src/tests/**` with 07: named carve-outs,
  sequenced by commit.
- `wip/br5-beam-templates` branch (C-24) is the maintainer's to delete.

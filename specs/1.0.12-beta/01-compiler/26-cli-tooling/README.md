# Front 26 — cli-tooling: a program built by the CLI serves on the BEAM, and every driver speaks

**Priority:** high · **State:** partial: steps 1, 2 (box 3 measured, rakun's row), 3, 4, 5, 6, 7 and 8
done; step 9 open
**Depends on:** `../../02-std-and-packaging/98-packaging-tail/` step 4 (decision 344's manifest
side; the `bpmp` resolver half is step 6) · 23-c's two `botopink test` fixes confirmed (decision 317 — this front's files, kept)
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
- Step 2, box 3 — measured: rakun fronts 77/78's `src/orm_host.bp` workaround is deletable (moved to `src/orm/host.bp`, rakun-data 128 passed); the deletion is a rakun-track row
- Step 3 — only a direct dependency is importable: decision 242's located refusal (`unresolved import source "<x>" — declare it in botopink.json "dependencies"`), cell `modules/transitive_package_import` on four targets
- Step 4 — `build` and `test` print checker warnings as `check` does (the `var out = [];` warning, a `test-cli` contract case; C-18's box 3 closed)
- Step 7 — `build.zig`'s `test-docs` comment describes `check-docs.sh`'s `reject` / `project` / `body` directives
- Step 8, box 1 — the LSP reports `module-import-with-from` and `unresolved import source` as `check` does, one `lsp/` snapshot each
- Step 8, box 2 — `from "<own package name>"` is `error[module-import-with-from]` (309): an embedded std module's brace import reads as `from "std"` (`comptime.zig`), `resolver.sourceProblem` tests the package's own name, the three std sources migrated (`modules/import_own_package_with_from`, `dependency_imports_itself_with_from`, `cli_contract.sh`)
- Step 6 — a git dependency's `subdir` (decision 344, the resolver half): `bpmp install` clones a repository once per ref into `<store>/<repo_key>/<rev>/`, links `.botopinkbuild/deps/<name>` to `<checkout>/<subdir>`, and two dependencies on one repository share the checkout (`share_checkout`; a lockfile pinning them at two commits refused); `dep/member.zig` refuses, located, a `subdir` with no `botopink.json`, holding a workspace (naming its members' subdirs) or another package's name, and a `path` / `workspace` dependency of the package's closure leaving the checkout (by spelling or a symbolic link) — before any link is written; the CLI resolves a linked dependency's own dependencies from the link's target (`libs.linkFreeDir`), so rakun-web's `../rakun` is the sibling at the same ref. `tests/cli_contract.sh` over a local bare repository (47 assertions; 40 red against the parent's `bpmp` + `botopink`, 3 against the parent's `botopink` alone), `dep/member.zig` / `dep/resolver.zig` / `install.zig` unit tests, `libs.zig` `linkFreeDir` test
- Row (309 in the LSP) — the language server makes decision 309's refusal: `resolver.importSourceProblems` takes `own`, `engine.importDiagnostics` passes it, the server reads it from the nearest manifest's `name` (a dependency's own inside its sources); `lsp/diagnostics_import_own_package_with_from` and a server-level test over a scratch package, both red on the parent (`unresolved import source`)

## Open

### Step 9 — a dependency's sidecars and imports answer as its own build does

- [ ] a transitive dependency's sidecar ships: a project outside the rakun workspace depending on a
      member by `path` failed `build` with "`rakun_actuator` / `rakun_probes` is not a sidecar of
      this project" — `libs.sidecarOwner` asked only the project's direct `dependencies`, then the
      roots by name; it now walks the closure the build resolved (`closureOwner`) ·
      `tests/cli_contract.sh` "a dependency of a path dependency", `libs.zig` unit test
- [ ] a dependency's module importing a package it does not declare is decision 242's located
      `unresolved import source` (at the dependency's file), not `unbound variable` —
      `libs.loadOne` runs `resolver.checkSources` against the dependency's own manifest ·
      `modules/dependency_imports_undeclared_package`, four targets

**Gate:** standard (fronts.md § Gate) + `zig build test-cli`, `test-bpmp`, `test-vscode` green;
language-server tests green with new snapshots · `zig build test-libs` at baseline (rakun's members
exercise every sidecar path)


### Rows other fronts found

- [ ] `botopink check` / `build` print a type error's message and box but not its hint: the
      `PersistentTerm` write (`infer.zig`'s hint names `#[@BeamMemory.Ets]`) and
      `std-unsupported-on-target` carry one and the terminal shows none; a parse error's
      `= hint:` line prints (measured by `07` step 6; `docs.md` § `@BeamMemory` cites the hint)

## Notes

- `project_graph.zig` shared with 23 (import-tree cells), `src/tests/**` with 07: named carve-outs,
  sequenced by commit.
- `wip/br5-beam-templates` branch (C-24) is the maintainer's to delete.

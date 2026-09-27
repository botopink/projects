# Front 26 — cli-tooling

**Priority:** high — the toolchain rows of the rakun sweep (`language-gaps.md` T1, T4, T16) and the
beam sidecar are what stand between a library that is green under `botopink test` and a program
that serves on the BEAM; no carried front owned `compiler-cli/**`, `bpmp/**` or
`language-server/src/**`, so this number is new (the 1.0.10 series stopped at 25).
**Depends on:** `00-gate` (EF-1, EF-2 — the sidecar's CLI half is the gate's fix in this front's
files; ZF-1…5, ZF-11 — `bpmp/src/**` ×4, `cli/test_cmd.zig`, `language-server/src/engine.zig` are
six of the eleven `zig fmt` files; FC-3 — `compiler-cli/tests` reformatted) · `02-erlang` step 9
(the sibling loader under `build`; this front ships the sidecars for the same entry points) ·
maintainer decision 26-a (step 3) · decision-gated lg2-v (a git subdirectory — the manifest side is
`../02-std-and-packaging/98-packaging-tail/` step 4; the `bpmp` resolver half opens here when
answered) · `23-std-purity` step 2 (23-c's two `botopink test` fixes confirmed — they are this
front's files).
**Owns:** `modules/compiler-cli/**` (`src/cli/{build,run,test_cmd,libs,sources,config,resolver}.zig`,
the rest, `tests/**`) · `modules/bpmp/**` except `src/manifest.zig` under 98's step 4 · `modules/language-server/src/**`
except `src/tests/**` (07) and `project_graph.zig`'s import-tree cells (23) · `modules/language-server/snapshots/lsp/**`
· `repository/vscode-extension/**` · `scripts/test-vscode.sh` · the cells its steps add
**Does not touch:** `modules/compiler-core/**` (every other front's — a CLI row that needs the
emitter is 02's or 03's step, named) · `scripts/gate.sh` (25) · `scripts/{known-red-libs,restricted-targets}.txt`
(00-gate) · `modules/manifest/**` (98).
**Does not touch until 00-gate lands:** `cli/{build,run,test_cmd}.zig` and `cli/libs.zig` (EF-1/EF-2
land there; this front's steps 1–4 rebase on the gate's commit) · `bpmp/src/commands/{self_uninstall,self_update}.zig`,
`bpmp/src/{registry,storage}.zig`, `cli/test_cmd.zig`, `language-server/src/engine.zig` (ZF) ·
`compiler-cli/tests/**/*.bp` (FC-3).

Paths are relative to `repository/botopink-lang/modules/` unless a row says otherwise.

## Carried from 1.0.10

| Item | 1.0.10 spec | Heading |
|---|---|---|
| the beam sidecar's CLI half | `tests/language/expected-failures.txt` (the two beam lines) · `03-beam/README.md` | § Open rows |
| C-25's sidecar half and `botopink clean` | `00/README.md` | § C-25, boxes 1–2 |
| T1, T4, T16 | `language-gaps.md` | "A built erlang program cannot load its `.erl` sidecars" · "A package reached only transitively loads but cannot be imported" · "`shipErlSidecars` reads a nested module's folder as a dependency name" |
| lg2-v | `language-gaps.md` · `decisions-pending.md` | "`DepSpec` has no subdirectory field" |
| `Env.warnings` not printed | `00/README.md` | § C-18, box 3 ("`build` / `test` / the LSP do not print them yet") |
| the transitive workspace dependency | `19-use-activation/README.md` | § Notes, first bullet (jhonstart-forms → jhonstart-link) |
| the `wip/br5-beam-templates` branch | `00/README.md` | § C-24 (the maintainer deletes it — noted, not a step) |
| 23-c's two fixes | `decisions-pending.md` | 23-c (landed in `test_cmd.zig` / `libs.zig`; confirmed by 23 step 2) |

## Problem

| Row | Program | Answer at the open |
|---|---|---|
| EF-1/2 | `botopink build --target beam` of a project with `src/sidecars/lt_greeter.erl` | the `.erl` is not shipped to `out/beam/` (`cli/build.zig`'s beam path calls no `shipErlSidecars`); `text:shout/1` is `undef` |
| T1 | `botopink build --target erlang` then `erl -pa out/erl` on a program calling a sidecar | `undef` — the loader is emitted under the test flag only (02 step 9) and `build` / `run` ship the sidecar only under `test` (`libs.shipErlSidecars` is reached from `test_cmd.zig`; verify `build.zig`'s path) |
| T16 | a project whose modules sit in `src/orm/*.bp` calling a sidecar | never shipped — `libs.zig`'s `sidecarOwner` (`:1099` at HEAD) reads `orm/entity`'s first segment as package `orm` |
| C-25 | a sidecar file named like an emitted module's ATOM (`<pkg>@<path>.erl`) | never consulted — `shipErlSidecars` matches emitted module atoms against basenames only; a sidecar whose atom an emitted module already owns should be a build error, not a skip |
| T4 | an application declaring `rakun-starter-web` only, importing `from "rakun"` | "unresolved import source" (`cli/sources.zig:52,104`, `proj.dependencyNames`) while decision 143 loads `rakun` |
| `Env.warnings` | `var out = [];` under `botopink build`, `botopink test`, the LSP | no warning printed; only `botopink check` renders `OkData.warnings` |
| `botopink clean` | `.botopinkbuild/tmp/{template,decorator}/*.erl` | 14's step 3 deleted the staging; `clean` removes `.botopinkbuild/` whole — verify and write the sentence in `docs.md` / the CLI's help (C-25 box 2) |

Measured at the open with the compiler at the milestone's HEAD; the rakun repros are the sweep's
(`$HOME/.cache/bp-rakun/*`).

## Steps

### Step 1 — the sidecars ship for `build` and `run`, on erlang and beam (after 00-gate)

00-gate lands EF-1/EF-2 (the beam path ships and loads). This front makes the erlang and beam
`build` / `run` paths ship every sidecar `test` ships (with 02 step 9's loader), so a built program
serves on the BEAM (rakun front 81's "the tarball starts and serves").

**Acceptance:**
- [ ] `modules/erlang_host_sidecar_shipped` passes as a **built** program on erlang and beam (`build`, then `erl -pa out/<target>`), pinned by a `test-cli` contract script (`compiler-cli/tests/cli_contract.sh` gains the case)
- [ ] language-gaps T1 closes with 02 step 9

### Step 2 — a nested module's sidecar, and a sidecar named like an atom (T16, C-25)

`sidecarOwner` tells the project's own modules from a dependency's by the build's module table
(a module whose source is under the project's `src/` is the project's, whatever its folder — the
rule 23-c already wrote for `botopink test`), so `src/orm/*.bp` ships `sidecars/orm_host.erl`; and a
sidecar whose file is named like an emitted module's atom is a located build error naming both,
one predicate away from `crossModule.zig`'s collision check.

**Acceptance:**
- [ ] `modules/sidecar_called_from_folder_module` — a sidecar called only from `src/orm/entity.bp` runs on erlang and beam
- [ ] `modules/sidecar_named_like_emitted_atom` — `.expect` names the collision (a project cell that must not build)
- [ ] rakun fronts 77/78's `src/orm_host.bp` workaround deletable — the rakun track's row

### Step 3 — a transitively reached package (T4, 26-a)

Per 26-a (a): only direct dependencies are importable, and the diagnostic names the package to
declare ("`rakun` is loaded for `rakun-starter-web` but not declared by this project — add it to
`dependencies`"); or (b): every resolved package is an import source. Either way the 19-use
note (a package outside the jhonstart workspace depending on `jhonstart-forms` does not resolve
`jhonstart-link` — `DepClosure` in `libs.zig`) is re-measured under decision 143 and closed or
filed as its own row here.

**Acceptance:**
- [ ] `modules/transitive_package_import` — `.expect` with the named diagnostic ((a)) or a run ((b)), on four targets
- [ ] the jhonstart-forms shape re-measured; a cell if it still reproduces

### Step 4 — `Env.warnings` reach every driver

`botopink build`, `botopink test` and the language server render `OkData.warnings` as `check`
does (`warning:` lines; the LSP as diagnostics of severity warning).

**Acceptance:**
- [ ] a `test-cli` contract case: `build` and `test` print the `var out = [];` warning; one `lsp/` snapshot with the warning diagnostic
- [ ] C-18's box 3 ticked

### Step 5 — `botopink clean` and the C-24 branch

Verify `clean` removes `.botopinkbuild/` whole (14's delivered row) and write the sentence where
the CLI documents `clean`; the `wip/br5-beam-templates` branch is the maintainer's to delete (a
note in this README's close, not a step).

**Acceptance:**
- [ ] the sentence in `docs.md` (08 places) and `botopink clean --help`; C-25 box 2 ticked

### Step 6 — lg2-v's resolver half (decision-gated)

When lg2-v is answered with a `subdir` field, `bpmp`'s resolver checks the dependency out at the
subdirectory (98 step 4 owns the manifest model); nothing before.

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in this front's worktree
- [ ] `zig build test-cli`, `test-bpmp`, `test-vscode` green; the language-server tests green with the new snapshot
- [ ] `zig build test-libs` at baseline (rakun's members exercise every sidecar path)
- [ ] `AGENTS.md` of `compiler-cli/`, `bpmp/`, `language-server/` in the same commit as each step
- [ ] Commit on `fix/26-cli-tooling`; no push, no merge

## Blast radius

Step 1 changes what every erlang / beam build writes to `out/` (sidecars copied); step 2 reds a
project whose sidecar collides with an emitted atom (none measured); step 3 (a) reds an
application importing from an undeclared transitive package — the rakun starters' consumers are
the measured shape, and the row's workaround (declare both) already holds.

## Notes

- The 1.0.10 `10-cli-residuals` sub-front was 1.0.5's and had no 1.0.10 directory; its rows
  reached this milestone through `language-gaps.md`'s toolchain table, which is why they are
  listed there by T-number.
- `project_graph.zig` is shared with 23 (the import-tree cells) and `src/tests/**` with 07; both
  are named carve-outs, sequenced by commit.

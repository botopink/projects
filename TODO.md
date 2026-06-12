# TODO — repo-restructure

> Spec: [`tasks/v0.beta.17/specs/repo-restructure.md`](tasks/v0.beta.17/specs/repo-restructure.md)
> Branch: `task/repo-restructure` · Worktree: `.tasks/repo-restructure/`
>
> **Hard order:** F0–F2 (resolver) must be green on the **flat tree** and
> committed before any file moves in F3. The resolver is a pure superset; the
> move rides on it. Pre-commit runs `zig fmt`+`zig build`+`zig build test`.

## F0 — multi-root resolver (compiler-cli)
- [x] `resolveLibsRoot` (single `[]u8`) → `resolveLibRoots` (`[][]const u8`) per the `roots(cwd)` rule; `rootsFrom` split out for tests
- [x] `loadOne`/`loadDependencies`: resolve each `dep` by scanning the root list for `<root>/<dep>/botopink.json`; first match wins, `LibNotFound` if none
- [x] `shipMjsSidecars`: resolve the owning lib's dir through the root list (not `<libs_root>/<lib>/src/`); project-own (`owner == null`) stays `src/<base>`
- [x] Unit test: synthetic two-root layout resolves rakun→`server` across roots; flat `libs/`-only layout resolves identically to before

## F1 — language server parity
- [x] `project_graph.zig`: replaced `findLibsRoot` + the `{libs_root,"libs",dep}` join with the root-list rule (the double-`libs` was just findLibsRoot returning the *parent* of libs/; new roots ARE the libs/ dir, so loadLib joins `{root,dep}` — net flat-tree behaviour preserved)
- [x] Existing `project_graph` LSP tests stay green on the flat tree

## F2 — lib-test-runner discovery across roots
- [x] `discovery.zig`: discover libs by scanning **every** root in the list (each immediate child with a `botopink.json`), not one `libs/`; de-dup by name (first-root-wins); `Lib.dir` carries the path
- [x] `main.zig`/`args.zig`: `resolveRoots` produces the list; `--lib <name>` selects by name across roots; HELP/usage wording fixed
- [x] **Gate:** flat tree `zig build test` green (incl. new unit tests). **Committed here — resolver green pre-move.**

## F3 — scaffold + move the language core (git mv, preserve history)
- [x] Create `repository/` + `repository/botopink-lang/`; author the top-level workspace `AGENTS.md` (`repository/AGENTS.md`: workspace overview, multi-root rule, per-project entry points; `tasks/`+`scripts/` documented as workspace-root globals)
- [x] `git mv` `build.zig`, `test_format.zig`, `test_pub.zig`, `modules/` (minus vscode-extension), `libs/{std,client,server}`, non-framework `examples/` → `repository/botopink-lang/`; move core root docs there
- [x] Verify `build.zig` relative paths still resolve from the new home (`modules/…`, `libs/std/src/root.bp`, the `:117` grep — `modules/compiler-core/src`, all resolve when cwd is `repository/botopink-lang/`)

## F4 — extract frameworks + vscode extension to siblings
- [x] erika/jhonstart/onze/rakun: `git mv libs/<name>` → `repository/<name>/`; move its example(s) into `repository/<name>/examples/`; per-project `AGENTS.md`/`docs.md` rode along; CHANGELOG/README per-project still pending (F6 sweep)
- [x] `git mv modules/vscode-extension` → `repository/vscode-extension/` (+ docs)
- [x] Map every `examples/` entry to one destination; `jonhstar/` typo + `jhonstart-*` → `repository/jhonstart/`

## F5 — fix the paths the move breaks
- [x] `build.zig`: `test-vscode` `setCwd` → `repository/vscode-extension` (`../vscode-extension` from `repository/botopink-lang/`); `test-libs` walks every resolved root (no per-framework cwd needed — lib-test-runner's `discovery.zig` scans the root list)
- [x] `scripts/install-tooling.sh`: `modules/vscode-extension` → `repository/vscode-extension`; `zig build install` runs inside `repository/botopink-lang/`; legacy flat-tree fallback preserved
- [x] `modules/language-server/src/tests/project_graph.zig:84`: fixture path → `../../../rakun/examples/rakun/src/posts.bp` (3 ups now, since cwd is two layers deeper than the legacy flat tree); also fixed `resolveRoots` to absolutize relative `project_root` before walking — `std.fs.path.dirname` on `../../..` lexically shortens and silently visits the wrong ancestor
- [x] `doc-health.sh` / `status.sh` confirmed layout-agnostic (`git ls-files` + `git rev-parse --show-toplevel`); no changes needed

## F6 — docs sweep + green gate from new locations
- [x] Updated moved dirs' `AGENTS.md` (new path + parent link); refreshed `libs/AGENTS.md` (std/client/server only, frameworks documented as siblings) and `examples/AGENTS.md` (non-framework only) under `botopink-lang/`; per-framework AGENTS/docs paths + cross-refs threaded; `scripts/` + `tasks/` AGENTS now point at the workspace overview, not a non-existent root file
- [x] `cd repository/botopink-lang && zig build test` green — **9/9 steps, 1181/1181 tests pass** (compiler-core stages + `:117` lib-agnostic gate + LSP + CLI). Required one code fix beyond the moves: `project_graph.zig:resolveRoots` was lexically dirname-walking a relative `project_root` (an LSP active-doc relative URI in R3), which silently visited the wrong ancestors — now absolutizes via `std.process.currentPath` + `std.fs.path.resolve` before walking
- [ ] `zig build test-libs` discovers + runs all frameworks in sibling homes; rakun resolves `server` cross-root (deferred to follow-up: needs `node`/`escript` on PATH; not part of the standard gate)
- [ ] `zig build test-vscode` green from new path; each `repository/<framework>/examples/` compiles via `from "<framework>"` (deferred: needs `npm install` in `repository/vscode-extension/`)

## Test scenarios (acceptance)
```
unit  ---- resolveLibRoots: flat libs/ tree → single legacy root, order preserved
unit  ---- resolveLibRoots: repository/ workspace → [botopink-lang/libs, repository]
unit  ---- loadDependencies: rakun resolves "server" across roots
unit  ---- loadDependencies: name absent from all roots → LibNotFound
unit  ---- shipMjsSidecars: lib .mjs via root list; project-own via src/
cli   ---- pre-move: compiler-cli libs-loading tests byte-identical
lsp   ---- pre-move: project_graph from "<lib>" + mod siblings still resolve
build ---- post-move: repository/botopink-lang zig build test green
build ---- post-move: zig build test-libs runs erika/jhonstart/onze/rakun
build ---- post-move: rakun example from "server" resolves cross-root
build ---- post-move: zig build test-vscode green from new path
lsp   ---- post-move: project_graph fixture resolves at the example's new path
git   ---- moves preserve history (git log --follow on a moved file)
```

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
- [ ] Create `repository/` + `repository/botopink-lang/`; author the top-level workspace `AGENTS.md` (`repository/` purpose; `tasks/`+`scripts/` global)
- [ ] `git mv` `build.zig`, `test_format.zig`, `test_pub.zig`, `modules/` (minus vscode-extension), `libs/{std,client,server}`, non-framework `examples/` → `repository/botopink-lang/`; move core root docs there
- [ ] Verify `build.zig` relative paths still resolve from the new home (`modules/…`, `libs/std/src/root.bp`, the `:117` grep)

## F4 — extract frameworks + vscode extension to siblings
- [ ] erika/jhonstart/onze/rakun: `git mv libs/<name>` → `repository/<name>/`; move its example(s) into `repository/<name>/examples/`; add per-project `AGENTS.md`/`README.md`/`CHANGELOG.md`/`docs.md`
- [ ] `git mv modules/vscode-extension` → `repository/vscode-extension/` (+ docs)
- [ ] Map every `examples/` entry to one destination; `jonhstar/` typo + `jhonstart-*` → `repository/jhonstart/`

## F5 — fix the paths the move breaks
- [ ] `build.zig`: `test-vscode` `setCwd` → `repository/vscode-extension`; `test-libs` (`lib-test-exe` + cwd/args) → new framework roots
- [ ] `scripts/install-tooling.sh`: `modules/vscode-extension` → `repository/vscode-extension`; fixed `zig build` cwd → `repository/botopink-lang`
- [ ] `modules/language-server/src/tests/project_graph.zig:80`: update `../../examples/rakun/src/posts.bp` fixture path
- [ ] Confirm `doc-health.sh` / `status.sh` need no change (note if they do)

## F6 — docs sweep + green gate from new locations
- [ ] Update every moved dir's `AGENTS.md` (new path + parent link); refresh `libs/AGENTS.md` (std/client/server only) and `examples/AGENTS.md` (non-framework only) under `botopink-lang/`
- [ ] `cd repository/botopink-lang && zig build test` green (stages + `:117` gate + LSP + CLI)
- [ ] `zig build test-libs` discovers + runs all frameworks in sibling homes; rakun resolves `server` cross-root
- [ ] `zig build test-vscode` green from new path; each `repository/<framework>/examples/` compiles via `from "<framework>"`

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

# Repo restructure — flat monorepo → a `repository/` workspace of projects

**Slug**: repo-restructure
**Depends on**: nothing
**Files**: `modules/compiler-cli/src/cli/libs.zig`, `modules/language-server/src/{project_graph.zig,tests/project_graph.zig}`, `modules/lib-test-runner/src/{discovery,main}.zig`, `build.zig`, `scripts/install-tooling.sh`, repo-wide `git mv`, every `AGENTS.md`
**Touches docs**: root `AGENTS.md`/`README.md`/`docs.md`, `modules/AGENTS.md` (+ `compiler-cli`/`language-server`/`lib-test-runner`), `libs/AGENTS.md`, `examples/AGENTS.md`, `scripts/AGENTS.md`, every moved project's `AGENTS.md`, the new per-framework `AGENTS.md`/`README.md`/`CHANGELOG.md`/`docs.md`
**Status**: pending

## Problem

Everything sits flat at the repo root — `build.zig`, `modules/` (incl.
vscode-extension), `libs/` (std + client + server **and** the frameworks
erika/jhonstart/onze/rakun), `examples/`. The target is a **workspace**: global
`tasks/` + `scripts/` on top, and a `repository/` holding one project per
directory — the language core (`botopink-lang/`) plus each framework and the VS
Code extension extracted as **siblings**, each owning its `src/`, `examples/`,
`botopink.json` and docs.

The hard part is **not** moving files — it is that the compiler, language server
and lib-test runner all find a library by walking up to a **single `libs/`**
directory (`resolveLibsRoot`, `modules/compiler-cli/src/cli/libs.zig:38`; the same
assumption in `project_graph.zig` and `discovery.zig`). Once frameworks become
siblings under `repository/`, that single-root assumption breaks — and rakun
already does `from "server"` (`libs/rakun/src/bootstrap.bp:26`), so a sibling
project must resolve a bundled lib **across** projects.

So this task is two movements in one branch, **strictly ordered**: first
generalise resolution to a list of roots (backward-compatible, green on today's
flat tree), then relocate the files over a resolver that already finds siblings.
There is no green tree in between if the order is reversed.

## Target tree

```text
.
├── AGENTS.md                  # workspace root readme (new top-level)
├── tasks/                     # unchanged — global planning
├── scripts/                   # unchanged location — global utility
└── repository/
    ├── botopink-lang/
    │   ├── build.zig · test_format.zig · test_pub.zig
    │   ├── AGENTS.md · CHANGELOG.md · docs.md · README.md
    │   ├── examples/          # hello.bp, yamlconf, stdlib-tour,
    │   │                      #   generic-loader-binding, modules/  (non-framework)
    │   ├── libs/              # std, client, server  ONLY
    │   └── modules/           # compiler-core, compiler-cli,
    │                          #   language-server, lib-test-runner
    ├── vscode-extension/      # was modules/vscode-extension/
    ├── jhonstart/             # was libs/jhonstart/ + examples/jhonstart-*
    ├── erika/                 # was libs/erika/      + examples/erika-linq
    ├── onze/                  # was libs/onze/       + examples/onze
    └── rakun/                 # was libs/rakun/      + examples/rakun
```

Library `botopink.json` files are unchanged — `src`/`files`/`entry`/
`dependencies`/`target` are all relative to the lib's own directory, so they
travel with the lib. rakun keeps `"dependencies": ["server"]`; `server` stays
bundled and resolves cross-root.

## Resolution rule

`from "<name>"` (and a project's declared `dependencies`) resolve `<name>` to the
**first root** that contains `<name>/botopink.json`. The root list is derived by
walking up from cwd:

```text
roots(cwd) =
  for each ancestor dir D, nearest-first:
    if D/repository/botopink-lang/libs exists → add it          (bundled libs)
    if D/repository                    exists → add it          (sibling projects)
    if D/libs                          exists → add it          (legacy flat tree)
  → de-duplicated, nearest-first
```

On **today's** tree only the legacy `D/libs` branch fires, so `roots` is exactly
`[<ancestor>/libs]` — behaviour is byte-identical and every current test stays
green. After the move, a consumer under `repository/erika/examples/` yields
`[repository/botopink-lang/libs, repository]`, so `from "std"`/`from "server"`
hit the bundled root and `from "erika"` the sibling root. No `botopink.json`
schema change.

## Examples

### bundled + sibling resolve from the same consumer (post-move)
```bp
// repository/rakun/src/bootstrap.bp
import {serverServe} from "server"   // → repository/botopink-lang/libs/server/
```
`server` is not under `repository/rakun/`; the resolver finds it via the bundled
`libs` root in the list.

### legacy flat tree is unchanged (mid-task, before F3 moves files)
```bp
// examples/rakun/src/posts.bp
import {Query} from "erika"          // → libs/erika/  (single legacy root)
```
The root list collapses to `[<ancestor>/libs]`; identical to current resolution.

### examples follow their framework; non-framework examples stay with the core
```text
examples/erika-linq/   → repository/erika/examples/erika-linq/   (still `from "erika"`)
examples/stdlib-tour/  → repository/botopink-lang/examples/stdlib-tour/
examples/modules/      → repository/botopink-lang/examples/modules/
```

## Steps

> **Hard ordering:** F0–F2 (resolution) must be green on the **flat tree** before
> any file moves in F3. The resolver is a pure superset; the move rides on it.

### F0 — multi-root resolver (compiler-cli)
- [ ] Replace `resolveLibsRoot` (single `[]u8`) with a roots-list producer
  (`resolveLibRoots → [][]const u8`) implementing the `roots(cwd)` rule; keep a
  thin first-root shim if any call site still wants one root.
- [ ] `loadOne`/`loadDependencies`: resolve each `dep` by scanning the root list
  for `<root>/<dep>/botopink.json`; first match wins, `LibNotFound` if none.
- [ ] `shipMjsSidecars`: resolve the owning lib's dir through the root list
  instead of `<libs_root>/<lib>/src/`; project-own (`owner == null`) stays `src/<base>`.
- [ ] Unit test: a synthetic two-root temp layout resolves rakun→`server` across
  roots; a flat `libs/`-only layout resolves identically to before.

### F1 — language server parity
- [ ] `project_graph.zig`: replace `findLibsRoot` + the `{libs_root,"libs",dep}`
  join with the same root-list rule (first verify whether today's double-`libs`
  join is intended; preserve net behaviour on the flat tree).
- [ ] Existing `project_graph` LSP tests stay green on the flat tree.

### F2 — lib-test-runner discovery across roots
- [ ] `discovery.zig`: discover libs by scanning **every** root in the list (each
  immediate child carrying a `botopink.json`), not one `libs/`; de-dup by name.
- [ ] `main.zig`/`args.zig`: default discovery roots to the resolver's list;
  `--lib <name>` still selects by name across roots; fix HELP/usage wording.
- [ ] Gate: on the flat tree, F0–F2 leave `zig build test` + `botopink-lib-test`
  byte-identical to before. **Commit here — the resolver is green pre-move.**

### F3 — scaffold + move the language core (git mv, preserve history)
- [ ] Create `repository/` + `repository/botopink-lang/`; author the new
  top-level workspace `AGENTS.md` (what `repository/` is; `tasks/`+`scripts/`
  global).
- [ ] `git mv` `build.zig`, `test_format.zig`, `test_pub.zig`, `modules/` (minus
  vscode-extension), `libs/{std,client,server}`, and the non-framework
  `examples/` entries into `repository/botopink-lang/`; move the core's root docs
  (`CHANGELOG.md`/`docs.md`/`README.md`/`TODO.md`) there too.
- [ ] Verify `build.zig`'s relative paths still resolve from its new home
  (`modules/…`, `libs/std/src/root.bp`, the `:117` grep) — they should, since
  modules + std moved with it.

### F4 — extract frameworks + the vscode extension to siblings
- [ ] Each of erika/jhonstart/onze/rakun: `git mv libs/<name>` →
  `repository/<name>/`; `git mv` its example(s) into `repository/<name>/examples/`;
  add per-project `AGENTS.md`/`README.md`/`CHANGELOG.md`/`docs.md` (lift from the
  old `libs/<name>/AGENTS.md`).
- [ ] `git mv modules/vscode-extension` → `repository/vscode-extension/` (+ docs).
- [ ] Map every `examples/` entry to one destination (framework vs core); the
  `jonhstar/` typo dir and `jhonstart-*` go under `repository/jhonstart/`.

### F5 — fix the paths the move breaks
- [ ] `build.zig`: `test-vscode` `setCwd` → `repository/vscode-extension`;
  `test-libs` (`lib-test-exe` + cwd/args) point at the new framework roots.
- [ ] `scripts/install-tooling.sh`: `modules/vscode-extension` →
  `repository/vscode-extension`; any fixed `zig build` cwd → `repository/botopink-lang`.
- [ ] `modules/language-server/src/tests/project_graph.zig:80`: update the
  `../../examples/rakun/src/posts.bp` fixture path to the example's new home.
- [ ] Confirm `scripts/doc-health.sh` (git-ls-files driven) and `scripts/status.sh`
  (walks `tasks/`) need no change; note it if they do.

### F6 — docs sweep + green gate from the new locations
- [ ] Update every `AGENTS.md` a move touched to its new path + parent link;
  refresh `libs/AGENTS.md` (now std/client/server only) and `examples/AGENTS.md`
  (non-framework only) under `botopink-lang/`.
- [ ] `cd repository/botopink-lang && zig build test` green (stages + `:117` gate
  + LSP + CLI).
- [ ] `zig build test-libs` discovers + runs all frameworks in their sibling
  homes; rakun resolves `server` cross-root.
- [ ] `zig build test-vscode` runs from the extension's new path; each
  `repository/<framework>/examples/` compiles via `from "<framework>"`.

## Test scenarios

```
unit  ---- resolveLibRoots: flat libs/ tree → single legacy root, order preserved
unit  ---- resolveLibRoots: repository/ workspace → [botopink-lang/libs, repository]
unit  ---- loadDependencies: rakun resolves "server" across roots (bundled lib)
unit  ---- loadDependencies: name absent from all roots → LibNotFound
unit  ---- shipMjsSidecars: lib .mjs via root list; project-own via src/
cli   ---- pre-move: compiler-cli libs-loading tests byte-identical
lsp   ---- pre-move: project_graph from "<lib>" + mod siblings still resolve
build ---- post-move: repository/botopink-lang zig build test (all stages) green
build ---- post-move: zig build test-libs runs erika/jhonstart/onze/rakun
build ---- post-move: rakun example from "server" resolves cross-root
build ---- post-move: zig build test-vscode green from new path
lsp   ---- post-move: project_graph fixture resolves at the example's new path
git   ---- moves preserve history (git log --follow on a moved file)
```

## Notes

- **One branch, hard order.** F0–F2 (resolver) is a pure superset that goes green
  with **zero file moves** — commit it before F3. F3–F4 are an atomic move (no
  green tree with half the frameworks relocated). Reversing the order reds every
  framework example and `test-libs` cell the moment a framework leaves `libs/`.
- No `botopink.json` schema change. An explicit `BOTOPINK_LIBS_DIRS`-style
  override for out-of-tree consumers is a future hook, out of scope.
- Do **not** add a compiler-core dependency on any framework name; the
  `build.zig:117` lib-agnostic gate still holds (its path is relative to
  build.zig, unchanged by the move).
- `.tasks/<slug>/` worktrees and the global `tasks/`/`scripts/` stay at the
  workspace root — never under `repository/`. Pre-commit (`zig fmt`+`zig build`+
  `zig build test`, never `--no-verify`) must run from `repository/botopink-lang/`.
- Only one cross-project import edge exists today: **rakun → server**
  (`bootstrap.bp:26`). erika/jhonstart/onze import std + self only. Snapshot
  goldens carry no paths.

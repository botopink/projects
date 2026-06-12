# v0.beta.17 — plan (reasoning scratchpad)

Mutable. Captures *why* the set is shaped this way and the blast-radius survey
that the two specs derive from. The authored intent lives in `specs/`; this file
is the thinking around them.

## The target tree (user-given)

```text
.
├── AGENTS.md                  # workspace root readme
├── tasks/                     # GLOBAL planning — stays at root
├── scripts/                   # GLOBAL utility scripts — stays at root
└── repository/
    ├── botopink-lang/         # language core (Zig ecosystem centre)
    │   ├── build.zig · AGENTS.md · CHANGELOG.md · docs.md · README.md
    │   ├── test_format.zig · test_pub.zig
    │   ├── examples/          # non-framework only (hello.bp, yamlconf, stdlib-tour,
    │   │                      #   generic-loader-binding, modules/)
    │   ├── libs/              # ONLY std, client, server
    │   └── modules/           # compiler-core, compiler-cli, language-server,
    │                          #   lib-test-runner  (NOT vscode-extension)
    ├── vscode-extension/      # extracted from modules/
    ├── jhonstart/             # extracted from libs/ — + its own examples/
    ├── erika/                 #   "
    ├── onze/                  #   "
    └── rakun/                 #   "
```

## One spec, hard internal order — why

The move itself is a `git mv` script; the danger is the **single-`libs/`
assumption** baked into three resolvers. If we move first, the tree is broken
until the resolver catches up — no green intermediate commit. So the single
`repo-restructure` spec runs two strictly-ordered movements in one branch:

1. **F0–F2 (resolver)** generalises resolution to a *list of roots*, written so
   that on **today's** flat tree the list is exactly `[<ancestor>/libs]` →
   byte-identical behaviour, all current tests green. A pure superset, committed
   green **before any file moves**.
2. **F3–F6 (move)** then relocates files over a resolver that already finds
   siblings.

Kept as one spec (not two) because both halves touch the same files
(`libs.zig`, `project_graph.zig`) and there is no parallelism to win by splitting
— it is a single, hard-ordered worktree. The F2 commit is the green gate between
the two halves.

## Blast radius — every path-coupling point (surveyed 2026-06-12)

Single-`libs/` ancestor walk — the core breakage:
- `modules/compiler-cli/src/cli/libs.zig:38` `resolveLibsRoot` → returns first
  `<ancestor>/libs`. `loadOne` builds `<libs_root>/<dep>/botopink.json`.
- `modules/compiler-cli/src/cli/libs.zig` `shipMjsSidecars` → resolves a lib's
  `.mjs` at `<libs_root>/<lib>/src/<base>`.
- `modules/language-server/src/project_graph.zig` `findLibsRoot` / `loadLib` →
  same ancestor walk; note the `{ libs_root, "libs", dep }` join (verify whether
  the double-`libs` is intended before touching).
- `modules/lib-test-runner/src/discovery.zig` `discover(libs_root, …)` →
  enumerates immediate children of one `libs/`; `main.zig` defaults the root.

`botopink.json` semantics are **safe**: `src`/`files`/`entry`/`dependencies`/
`target` are all relative to the lib's own directory, so they travel with the lib
unchanged. rakun keeps `"dependencies": ["server"]`; server stays bundled, so
this becomes the first **cross-project** dependency the multi-root resolver must
satisfy.

Hard-coded paths that the **move** (not the resolver) fixes:
- `build.zig` — `libs/std/src/…`, `stdPkgFilesFromRoot` reading
  `libs/std/src/root.bp`, and `modules/…` are all **relative to build.zig**;
  since std + modules stay under `botopink-lang/`, these keep resolving once
  build.zig moves with them. The two that DO move: `test-vscode` `setCwd
  (modules/vscode-extension)` → `repository/vscode-extension`, and `test-libs`
  which must now reach the sibling framework roots.
- `build.zig:117` lib-agnostic gate `grep … modules/compiler-core/src` — path is
  relative to build.zig, unchanged. The forbidden-name alternation
  (`rakun|jhonstart|erika`) still applies; frameworks leaving `libs/` does not
  relax it.
- `scripts/install-tooling.sh` — hard-codes `modules/vscode-extension` (→
  `repository/vscode-extension`) and runs `zig build` from a fixed dir.
- `scripts/doc-health.sh` — `git ls-files`-driven, directory-agnostic → adapts
  for free. `scripts/status.sh` — walks `tasks/` (global, unmoved) → safe.
- `modules/language-server/src/tests/project_graph.zig:80` — literal
  `../../examples/rakun/src/posts.bp`; rakun's example moves into
  `repository/rakun/examples/`, so this fixture path updates.

Cross-lib imports inside frameworks (grep of `from "`): only **rakun → server**
(`bootstrap.bp:26`, manifest dep). erika/jhonstart/onze import std + self only.
So exactly one cross-project edge to keep alive after the split.

Snapshot tests: golden outputs carry no paths → safe.

## Open questions

- **Resolution shape.** Leaning toward: walk up to the workspace root (the dir
  that contains `repository/`, or — pre-move — any dir with `libs/`), then form an
  ordered root list: `[repository/botopink-lang/libs, repository]` (post-move) or
  `[<ancestor>/libs]` (today). A name resolves at the first root holding
  `<name>/botopink.json`. Keeps `botopink.json` semantics intact; no manifest
  schema change. Confirm before building.
- **Should `server`/`client` also extract?** No — user layout keeps them bundled
  under `botopink-lang/libs/`. They are part of the language core surface.
- Whether to add an explicit `BOTOPINK_LIBS_DIRS`-style override for out-of-tree
  consumers — out of scope here, note as a future hook.

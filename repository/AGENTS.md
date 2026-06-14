# repository/ · workspace AGENTS.md

Guidance for AI agents working at the **botopink workspace** level.

> Convention: source, comments, commit messages and docs are all in **English**.
> Each directory ships its own `AGENTS.md` — read the closest one first, then
> walk up the tree.

## What this directory is

`repository/` holds every botopink **project**: the language core, the editor
tooling, and the user-facing frameworks. Each immediate child is its own
self-contained project with its own `botopink.json` (for `.bp` libs) or
`build.zig` (for Zig packages).

```text
repository/
├── AGENTS.md            ← you are here (workspace overview)
├── botopink-lang/       ← the language core (CLI, LSP, compiler, lib-test-runner, std/server/client)
├── vscode-extension/    ← VS Code extension (syntax + LSP client)
├── erika/               ← LINQ-style query DSL (.bp lib + erika-linq example)
├── jhonstart/           ← React/Next-style frontend framework (.bp lib + jhonstart-* examples)
├── onze/                ← test mocking lib (.bp lib + tests)
└── rakun/               ← Spring-style backend framework (.bp lib + example)
```

Two directories live **above** `repository/` (i.e. at the workspace root, not
here) because they are global, cross-project concerns:

- `tasks/` — versioned spec sets (the roadmap). One source of truth for what's
  being worked on; see [`tasks/AGENTS.md`](../tasks/AGENTS.md).
- `scripts/` — maintenance scripts (`install-tooling.sh`, `doc-health.sh`,
  `status.sh`) that operate across the workspace. They detect the
  `repository/botopink-lang/` layout and fall back to a legacy flat tree, so
  the same script works in both shapes.

The `.tasks/` worktrees, also at the workspace root, are per-task git worktrees
(one per `task/<name>` branch). See
[`botopink-lang/AGENTS.md`](botopink-lang/AGENTS.md) for the worktree workflow.

## Multi-root library resolution

`from "<name>"` imports and a project's `dependencies` are resolved by walking
upward from `cwd` and, at each ancestor `D`, considering these roots
(nearest-first, first-match wins):

```text
D/repository/botopink-lang/libs    ← bundled libs (std, server, client)
D/repository                       ← sibling projects (erika, jhonstart, onze, rakun, …)
D/libs                             ← legacy flat tree
```

The list de-dups; on a legacy flat tree only `D/libs` fires, so the resolver is
byte-identical to the former single-root walk. Lives in
[`botopink-lang/modules/compiler-cli/src/cli/libs.zig`](botopink-lang/modules/compiler-cli/src/cli/libs.zig),
mirrored by [the language-server's `project_graph.zig`](botopink-lang/modules/language-server/src/project_graph.zig)
and the [lib-test-runner's discovery](botopink-lang/modules/lib-test-runner/src/discovery.zig).

## Cross-project commands

```bash
# from repository/botopink-lang/
zig build            # compile CLI + LSP + lib-test-runner
zig build test       # run compiler-core + language-server tests
zig build test-libs  # walk every resolved root; run each lib's tests on every backend
zig build test-vscode # run the sibling vscode-extension's pure-fn unit tests
```

`test-libs` discovers libs by scanning every root (bundled + sibling), so a
rakun example that does `from "server"` resolves the bundled `botopink-lang/libs/server/`
across the workspace boundary.

## Per-project entry points

| Project | Entry doc |
|---|---|
| Language core | [`botopink-lang/AGENTS.md`](botopink-lang/AGENTS.md) |
| VS Code extension | [`vscode-extension/AGENTS.md`](vscode-extension/AGENTS.md) |
| erika (LINQ DSL) | [`erika/AGENTS.md`](erika/AGENTS.md) |
| jhonstart (frontend) | [`jhonstart/AGENTS.md`](jhonstart/AGENTS.md) |
| onze (mocking) | [`onze/AGENTS.md`](onze/AGENTS.md) |
| rakun (backend) | [`rakun/AGENTS.md`](rakun/AGENTS.md) |

## Conventions

- **AGENTS.md must always be kept up to date.** Whenever code or layout
  changes, update the affected `AGENTS.md` / `docs.md` in the same change.
- **English only** — every artifact (source, comments, commit messages,
  planning docs, filenames).
- **Always SSH** for remote git operations (`git@github.com:botopink/botopink-lang.git`).
- **One project per directory.** Cross-project changes touch each project's
  `AGENTS.md` so the workspace view stays consistent.
- **Tracked pre-commit hook in every project.** Each submodule ships
  `scripts/git-hooks/pre-commit` plus a self-contained
  `scripts/git-hooks/lib/runner-standalone.sh`; the meta workspace's
  [`../scripts/install-hooks.sh`](../scripts/install-hooks.sh) wires
  all 7 hooks (meta + 6 submodules) at once. A commit at the meta
  that bumps a submodule pointer also runs the bumped submodule's
  gate at the staged SHA, in a throwaway worktree. See
  [`../scripts/AGENTS.md`](../scripts/AGENTS.md) "Hook layout" for the
  full table.

# botopink/projects · workspace AGENTS.md

Guidance for AI agents working at the **workspace root** of the botopink
meta-repository.

> Convention: source, comments, commit messages, and docs are all in **English**.
> Each directory ships its own `AGENTS.md` — read the closest one first, then
> walk up the tree.

## What this repo is

`botopink/projects` is a thin meta-repository. The actual code lives in
**submodules** under [`repository/`](repository/), each one a standalone GitHub
repo:

```text
botopink/projects/
├── AGENTS.md           ← you are here (workspace root)
├── README.md           ← public-facing intro
├── docs.md             ← workspace docs hub
├── CHANGELOG.md        ← workspace changelog (submodule bumps, layout changes)
├── TODO.md             ← active task's checklist (lives at root, rewritten per task)
├── .gitmodules         ← submodule registry
├── repository/         ← submodules — see repository/AGENTS.md
│   ├── botopink-lang/      ← language core (CLI, LSP, compiler, std/server/client)
│   ├── vscode-extension/   ← VS Code extension (syntax + LSP client)
│   ├── erika/              ← LINQ-style query DSL
│   ├── jhonstart/          ← React/Next-style frontend framework
│   ├── onze/               ← test mocking lib
│   └── rakun/              ← Spring-style backend framework
├── tasks/              ← versioned spec sets (the roadmap) — see tasks/AGENTS.md
└── scripts/            ← workspace maintenance scripts
```

Per-project guidance lives **inside each submodule** — start at
[`repository/AGENTS.md`](repository/AGENTS.md) for the workspace overview and
multi-root library resolution rules.

## Submodules

| Project | Path | Remote | Branch |
|---|---|---|---|
| botopink-lang | `repository/botopink-lang/` | `git@github.com:botopink/botopink-lang.git` | `feat` |
| vscode-extension | `repository/vscode-extension/` | `git@github.com:botopink/vscode-extension.git` | `feat` |
| erika | `repository/erika/` | `git@github.com:botopink/erika.git` | `feat` |
| jhonstart | `repository/jhonstart/` | `git@github.com:botopink/jhonstart.git` | `feat` |
| onze | `repository/onze/` | `git@github.com:botopink/onze.git` | `feat` |
| rakun | `repository/rakun/` | `git@github.com:botopink/rakun.git` | `feat` |

All submodules track `feat`. Each submodule has its own `main` (release) and
`feat` (active development) branches.

## Common submodule commands

```bash
# Initialise + pull every submodule (after a plain clone)
git submodule update --init --recursive

# Pull latest feat tip from every submodule and merge
git submodule update --remote --merge

# Stage a submodule bump in the meta-repo
git add repository/<lib>
git commit -m "chore(repository/<lib>): bump submodule"
```

When editing inside a submodule, **commit and push there first**, then come
back to the workspace root and commit the gitlink bump.

## Workspace commands (from `repository/botopink-lang/`)

```bash
zig build              # compile CLI + LSP + lib-test-runner
zig build test         # compiler-core + language-server tests
zig build test-libs    # run each resolved lib's tests on every backend
zig build test-vscode  # run the sibling vscode-extension's unit tests
```

`test-libs` resolves sibling projects across the submodules; see
[`repository/AGENTS.md`](repository/AGENTS.md) for the resolution order.

## Conventions

- **AGENTS.md must always be kept up to date.** Whenever code or layout
  changes, update the affected `AGENTS.md` / `docs.md` in the same change
  (in the submodule that owns the file).
- **English only** — every artifact (source, comments, commit messages,
  planning docs, filenames).
- **Always SSH** for remote git operations.
- **One project per submodule.** Cross-project changes touch each project's
  `AGENTS.md` so the workspace view stays consistent.
- **Submodule bumps are their own commits** in the meta-repo, separate from
  workspace-level changes (`.gitmodules`, root docs).

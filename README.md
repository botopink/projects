# botopink/projects

> Meta-repository that ties together the botopink language, its editor tooling,
> and the user-facing frameworks. Each project lives as a **git submodule** under
> [`repository/`](repository/).

## Submodules

| Project | Path | Remote | What it is |
|---|---|---|---|
| **botopink-lang** | [`repository/botopink-lang/`](repository/botopink-lang/) | [github.com/botopink/botopink-lang](https://github.com/botopink/botopink-lang) | Compiler, CLI, LSP, lib-test-runner, bundled `std`/`server`/`client` libs (Zig) |
| **vscode-extension** | [`repository/vscode-extension/`](repository/vscode-extension/) | [github.com/botopink/vscode-extension](https://github.com/botopink/vscode-extension) | VS Code extension — syntax highlighting + LSP client (TypeScript) |
| **erika** | [`repository/erika/`](repository/erika/) | [github.com/botopink/erika](https://github.com/botopink/erika) | LINQ-style query DSL (`.bp` lib) |
| **jhonstart** | [`repository/jhonstart/`](repository/jhonstart/) | [github.com/botopink/jhonstart](https://github.com/botopink/jhonstart) | React/Next-style frontend framework (`.bp` lib) |
| **onze** | [`repository/onze/`](repository/onze/) | [github.com/botopink/onze](https://github.com/botopink/onze) | Test mocking lib (`.bp` lib) |
| **rakun** | [`repository/rakun/`](repository/rakun/) | [github.com/botopink/rakun](https://github.com/botopink/rakun) | Spring-style backend framework (`.bp` lib) |

All submodules track the `feat` branch.

## Clone

```bash
git clone --recursive git@github.com:botopink/projects.git
# or, after a plain clone:
git submodule update --init --recursive
```

## Pull latest from every submodule

```bash
git submodule update --remote --merge
```

## Workspace commands

Run from `repository/botopink-lang/`:

```bash
zig build              # compile CLI + LSP + lib-test-runner
zig build test         # compiler-core + language-server tests
zig build test-libs    # walk every resolved root; run each lib's tests on every backend
zig build test-vscode  # run the sibling vscode-extension's pure-fn unit tests
```

`test-libs` resolves sibling projects (`erika`, `jhonstart`, `onze`, `rakun`) by
walking up from `cwd` and picking up `D/repository/*` and
`D/repository/botopink-lang/libs/*`. See
[`repository/AGENTS.md`](repository/AGENTS.md) for the multi-root resolution rules.

## Per-project entry points

See each submodule's own `README.md`, `AGENTS.md`, `docs.md`, and `CHANGELOG.md`.

## Conventions

- Source, comments, commit messages, and docs are all in **English**.
- All remote git operations use **SSH** (`git@github.com:botopink/…`).
- Each directory ships its own `AGENTS.md`; agents read the closest one first
  and walk up the tree.

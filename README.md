# botopink (meta repository)

Umbrella repository for the botopink language: it pins the compiler and the
bundled libraries as git submodules and holds the cross-repo planning (specs and
the live task file). All source code lives in the submodules.

The language itself — syntax, compiler, CLI, LSP, standard library — is documented
in the compiler repository: [`repository/botopink-lang/README.md`](repository/botopink-lang/README.md)
and [`repository/botopink-lang/docs.md`](repository/botopink-lang/docs.md) (language reference).

## Layout

```
.
├── repository/
│   ├── botopink-lang/      compiler, CLI, language server, std (Zig)
│   ├── emilia/             type-safe CSS-in-bp library
│   ├── erika/              query DSL (`erika "…"`)
│   ├── jhonstart/          UI components / `html` DSL
│   ├── onze/               mocking library
│   ├── rakun/              backend framework (services, REST controllers)
│   └── vscode-extension/   VS Code extension
├── specs/
│   ├── __template.md       template for new specs
│   └── 1.0.0-beta/         specs for the 1.0.0-beta milestone (see overview.md)
├── todo.md                 live plan of the task checked out in this worktree
├── architecture.md         comptime evaluation pipeline (current state)
├── CHANGELOG.md            release log
└── AGENTS.md               guidance for AI agents working here
```

## Getting started

```sh
git submodule update --init --recursive
cd repository/botopink-lang
zig build          # botopink CLI + botopink-lsp
zig build test     # compiler-core + language-server tests
```

Requirements: Zig 0.16, Erlang/OTP (`erl`/`erlc` — comptime evaluation runs on the
Erlang VM), Node.js (CommonJS snapshot execution). See the compiler README for the
per-backend runtimes.

## Specs

Current milestone: [`specs/1.0.0-beta/overview.md`](specs/1.0.0-beta/overview.md).

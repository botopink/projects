# botopink/projects · docs hub

This file is an index. Each submodule keeps its own `docs.md` with the full
reference; this hub just points at them.

## Workspace overview

- [`AGENTS.md`](AGENTS.md) — agent guidance at the workspace root.
- [`README.md`](README.md) — public-facing intro, clone + submodule quickstart.
- [`repository/AGENTS.md`](repository/AGENTS.md) — workspace overview from the
  submodules root: layout, multi-root library resolution, cross-project commands.
- [`tasks/`](tasks/) — versioned spec sets (the roadmap). One folder per
  `v0.beta.N`, each holding the specs for that wave.
- [`scripts/`](scripts/) — maintenance scripts (`install-tooling.sh`,
  `doc-health.sh`, `status.sh`) that operate across the workspace.

## Per-project docs

| Project | Docs |
|---|---|
| Language core | [`repository/botopink-lang/docs.md`](repository/botopink-lang/docs.md) — language reference (`.bp` syntax + semantics, compiler internals, codegen). |
| VS Code extension | [`repository/vscode-extension/docs.md`](repository/vscode-extension/docs.md) — extension architecture, LSP client wiring. |
| erika | [`repository/erika/docs.md`](repository/erika/docs.md) — LINQ-style query lib + `erika "…"` template fn grammar. |
| jhonstart | [`repository/jhonstart/docs.md`](repository/jhonstart/docs.md) — frontend framework: components, hooks, `html """…"""` DSL. |
| onze | [`repository/onze/docs.md`](repository/onze/docs.md) — mocking runtime + `#[mock]` synthesis. |
| rakun | [`repository/rakun/docs.md`](repository/rakun/docs.md) — backend framework: scopes (`singleton`/`value`/`bean`), server runtime. |

## Where to start

- **Writing botopink code**: [`repository/botopink-lang/docs.md`](repository/botopink-lang/docs.md).
- **Using a framework**: open the corresponding `docs.md` + `examples` /
  `examples.md` in that submodule.
- **Hacking on the compiler**: [`repository/botopink-lang/AGENTS.md`](repository/botopink-lang/AGENTS.md)
  and the per-module `AGENTS.md` underneath.
- **Adding or moving a project**: update [`AGENTS.md`](AGENTS.md), this file,
  and [`repository/AGENTS.md`](repository/AGENTS.md) in the same commit.

## Multi-root library resolution

`from "<name>"` imports walk upward from `cwd` and, at each ancestor `D`,
consider these roots (nearest-first, first-match wins):

```text
D/repository/botopink-lang/libs    ← bundled libs (std, server, client)
D/repository                       ← sibling projects (erika, jhonstart, onze, rakun, …)
D/libs                             ← legacy flat tree
```

Implementations: `repository/botopink-lang/modules/compiler-cli/src/cli/libs.zig`
(CLI), `modules/language-server/src/project_graph.zig` (LSP), and the
lib-test-runner's discovery.

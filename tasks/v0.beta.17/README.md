# v0.beta.17 — the monorepo becomes a workspace of projects

> One spec, two strictly-ordered movements. Today everything lives flat at the
> repo root — `build.zig`, `modules/`, `libs/` (std + client + server **and** the
> frameworks erika/jhonstart/onze/rakun), `examples/`. This set turns the tree
> into a **workspace**: a global `tasks/` + `scripts/` at the top, and a
> `repository/` holding one project per directory — the language core
> (`botopink-lang/`) plus each framework and the VS Code extension extracted as
> **siblings**, each owning its own `src/`, `examples/`, `botopink.json`, and docs.
>
> The hard part is **not** moving files — it is that the compiler, language
> server and lib-test-runner all find a library by walking up to a single
> `libs/` directory. Once frameworks become siblings under `repository/`, that
> single-root assumption breaks. So [`repo-restructure`](specs/repo-restructure.md)
> does both within one branch, **hard-ordered**: first the engine change
> (multi-root resolution, backward-compatible, green on today's flat tree), then
> the move — pure relocation over a resolver that already understands many roots.

## Why this exists

`from "erika"` resolves through `resolveLibsRoot` (`modules/compiler-cli/src/cli/libs.zig:38`):
walk up from cwd, return the first ancestor that contains a `libs/` subdir, then
look for `<libs_root>/<name>/botopink.json`. The language server
(`project_graph.zig`) and `botopink-lib-test` (`discovery.zig`) repeat the same
single-`libs/` assumption.

This works only while **every** library is a child of one `libs/`. The target
layout deliberately splits them:

| Library | Today | After |
|---|---|---|
| `std`, `client`, `server` | `libs/<name>/` | `repository/botopink-lang/libs/<name>/` (bundled) |
| `erika`, `jhonstart`, `onze`, `rakun` | `libs/<name>/` | `repository/<name>/` (sibling project) |
| vscode extension | `modules/vscode-extension/` | `repository/vscode-extension/` |

A sibling framework that does `from "server"` (rakun already does —
`libs/rakun/src/bootstrap.bp:26`) must reach **across** projects into the lang
repo's bundled `libs/`. One ancestor walk cannot express "look in *these several*
roots", so resolution must become a **list of roots**, not one.

## Scope

| Spec | Area | Files |
|---|---|---|
| [repo-restructure](specs/repo-restructure.md) | **F0–F2 (resolver):** multi-root lib/project resolution — `from "<name>"` resolves across the bundled `libs/` **and** sibling `repository/<name>` projects; `.mjs` sidecar shipping + lib-test discovery follow the same roots; backward-compatible, green on today's flat tree. **F3–F6 (move):** `git mv` core → `repository/botopink-lang/`; extract each framework + the vscode extension to `repository/<name>/` with its own `examples/`/`botopink.json`/docs; framework examples leave the central `examples/`; `tasks/` + `scripts/` stay global; fix `build.zig` (vscode cwd, test-libs roots), `install-tooling.sh`, the LSP example fixture, every `AGENTS.md`. | `modules/compiler-cli/src/cli/libs.zig`, `modules/language-server/src/{project_graph,tests/project_graph}.zig`, `modules/lib-test-runner/src/{discovery,main}.zig`, `build.zig`, `scripts/*.sh`, repo-wide move, all `AGENTS.md` |

## Order

```text
F0–F2 resolver (green on flat tree)  ──▶  F3–F6 move (relocation over the new resolver)
```

A single hard edge, **inside** the one task: the move must run on a resolver that
already finds siblings, or the intermediate tree is broken. F0–F2 commit green
before any file moves.

## Goal

After it lands: the tree is `tasks/ · scripts/ · repository/{botopink-lang, erika,
jhonstart, onze, rakun, vscode-extension}/`. From `repository/botopink-lang/`,
`zig build test` is green; `zig build test-libs` discovers and runs **every**
framework in its new sibling home (including rakun resolving `server` across into
the bundled `libs/`); `zig build test-vscode` runs from the extension's new path;
each framework's own `examples/` compiles via `from "<framework>"`. No language
surface changes — only where files live and how libraries are found.

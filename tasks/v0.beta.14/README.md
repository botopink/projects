# v0.beta.14 — LSP works on real project files

> A single keystone spec ([`lsp-project-awareness`](specs/lsp-project-awareness.md)).
> The editor tooling (`botopink-lsp` + the VS Code extension) silently goes dark on
> the files that matter most: library sources with `comptime` decorator bodies,
> example apps that apply emitting decorators, and any file that imports from another
> module or a `from "<lib>"` package. This version makes completion, go-to-definition,
> hover, and sub-language highlighting survive those real-world shapes.

## Why this exists

Four field reports, one underlying story — **the LSP compiles each document in
isolation and has no local-scope symbol model**:

| Report | Symptom | Root cause |
|---|---|---|
| `libs/rakun/src/decorators.bp` | no completion / Ctrl+Click on `decl`, `args`, `f` | `completion()` only iterates *module-level* bindings; `findDeclLocation` only matches `val/fn/record/struct/enum/interface` keywords — params, `var`, `comptime` params, closure binders are invisible |
| `examples/rakun/posts.bp` | completion dead in the whole file | `inferProgramTyped` returns an **empty** binding list when decorators `@emit` (`infer.zig:147-151`) — bodies never inferred, so no bindings reach the LSP |
| `examples/rakun/posts.bp` | Ctrl+Click on `Response.created` (and everything) misses | single-file compile + `project_index` resolves `from "rakun"` only via the editor's workspace-root scan, not the lib's `botopink.json` |
| `examples/erika-linq/src/main.bp` | `erika "select …"` painted as a plain string | the Custom AST that drives sub-language highlight is a by-product of *expanding* the `erika` template; the cross-module template fn is unresolved in a one-file compile, so no expansion → no tokens |

## Scope

| Spec | Area | Files |
|---|---|---|
| [lsp-project-awareness](specs/lsp-project-awareness.md) | project-graph compile · local-scope bindings · decorator-body bindings · cross-module go-to-def · cross-module sub-language expansion | `modules/language-server/src/{server,compiler,engine,project_index}.zig`, `modules/compiler-core/src/comptime/infer.zig` |

This is **LSP-side** work plus one narrow `compiler-core` fix (the decorator early-return).
It adds no language surface — only makes existing features fire where they currently don't.

## Goal

Opening any `.bp` file in the repo — a lib source, an example app, a std module — gives
working completion, go-to-definition, hover, and (where applicable) sub-language
highlighting, regardless of how many modules it imports or whether its decorators emit.

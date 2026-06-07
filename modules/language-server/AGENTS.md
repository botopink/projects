# language-server

> Path: `modules/language-server/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../AGENTS.md`](../../AGENTS.md)
> Docs: [`./docs.md`](docs.md)

Package that builds the `botopink-lsp` executable. Wraps `compiler-core` and
implements the JSON-RPC / LSP protocol.

## Tree

```text
language-server/
├── AGENTS.md          ← you are here
├── docs.md            ← feature inventory, transport, dev loop
├── build.zig          ← build graph (`run`, `test`)
├── build.zig.zon      ← deps (compiler-core)
├── src/               ← server + protocol + features + tests
│   ├── AGENTS.md
│   ├── docs.md
│   └── project_index.zig ← project-level pub symbol index
└── snapshots/
    └── lsp/           ← LSP feature snapshots
        └── AGENTS.md
```

## Commands (run from this directory)

```bash
zig build               # produce ./zig-out/bin/botopink-lsp
zig build run           # launch over stdio
zig build test          # run LSP feature tests + snapshots
```

## Feature scope

The server currently handles `initialize` / `shutdown` plus these
`textDocument/*` methods:

- `publishDiagnostics` (with `$/progress`), `formatting`,
  `hover` (full signature + doc comments, incl. qualified `std` members),
  `definition` (same-file, cross-module, and into embedded `std` modules),
  `typeDefinition`,
  `documentSymbol` (hierarchical, incl. `test "name"` blocks as `Method`),
  `completion` (prefix + dot-trigger + `list.`/`io.` std members + labeled args + sortText + module names),
  `references` (cross-module with exact positions), `rename` (cross-module multi-file, with `prepareRename`, rejects keywords),
  `signatureHelp`, `inlayHint`,
  `codeAction` (add type annotation, remove unused import, add missing case patterns, add missing import),
  `foldingRange` (incl. `test` blocks).

The server maintains a **project index** (`src/project_index.zig`) that scans
`.bp` files from the workspace `rootUri`, caching `pub` symbols for cross-module
features (import suggestions, references, module completion).

`definition` resolves in three tiers: same file → workspace `pub` symbols
(project index) → embedded "std" package modules (`engine.definitionInStdModules`).
Std hits are materialized to `<XDG_CACHE_HOME|~/.cache>/botopink-lsp/std/<name>.bp`
so the editor can open them (needs `environ_map` from `std.process.Init`,
plumbed through `Server.init`).

Add a new feature → implement it in [`src/engine.zig`](src/AGENTS.md), add a
test under [`src/tests/`](src/tests/AGENTS.md) and a snapshot under
[`snapshots/lsp/`](snapshots/lsp/AGENTS.md).

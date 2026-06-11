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
  `hover` (full signature + doc comments, incl. qualified `std` members and
  builtin interface methods on primitives/arrays/strings),
  `definition` (same-file, cross-module, and into embedded `std` modules),
  `typeDefinition`,
  `documentSymbol` (hierarchical, incl. `test "name"` blocks as `Method`),
  `completion` (prefix + dot-trigger + `list.`/`io.` std members + builtin
  interface methods on primitive/array/string receivers + labeled args +
  sortText + module names),
  `references` (cross-module with exact positions), `rename` (cross-module multi-file, with `prepareRename`, rejects keywords),
  `signatureHelp` (incl. builtin interface methods, `self` dropped),
  `inlayHint` (inferred `val` types, call-site parameter names, lambda parameter types; `workspace/inlayHint/refresh` on edits),
  `semanticTokens` (`full` + `range`; token-driven legend distinguishing builtin `@Type`s, interface/struct methods vs free fns, `*fn` effect marker, comptime params, enum members; **plus a sub-language overlay inside string literals — see below**),
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

**Builtin interface methods** — `completion`/`hover`/`signatureHelp` on a
primitive/array/string receiver (`n.abs()`, `true.to_string()`, `xs.map(…)`,
`"s".len()`) resolve against the embedded interface declarations exposed by
`comptime_pipeline.{primitive_interfaces_src,array_interface_src,string_interface_src}`
(the `.d.bp` sources). The receiver's inferred type name (`i32`→`I32`,
`bool`→`Bool`, `array`→`Array`, `string`→`String`) selects the interface;
integer literals default to `I32`, `true`/`false` to `Bool`. `signatureHelp`
drops the leading `self`. Note: an integer *literal* receiver (`42.`) only
surfaces through the text-based engine path — a buffer containing `42.method()`
does not compile (the lexer reads `42.` as a float), so the editor reaches this
via a variable (`val n = 42; n.`).

**Sub-languages (`@ExprCustom`)** — an embedded query/markup literal like
`erika "select name from users"` or `html """…"""` lights up *from the
compiler*, not a hand-written SQL/HTML grammar. A template lib returns
`@ExprCustom<T> { code, ast }`; the `ast` is a generic `CustomNode` tree
(`{ kind, span, label, ref?, children }`) the lib built at comptime. The LSP
knows only `CustomNode` — it never branches on any sub-language:

- **Expansion** — `LspCompiler` runs with an opt-in template-eval context
  (`compileTypesOnly(…, eval_ctx)`), so `@ExprCustom` template bodies actually
  execute via `node` and surface their trees on `OkData.custom_ast`. The scratch
  root is `<XDG_CACHE_HOME|~/.cache>/botopink-lsp/template` (or `.botopinkbuild/lsp`).
  Spawning `node` per compile is the documented latency cost; tooling that must
  not touch the runtime passes `eval_ctx = null`.
- **Semantic tokens (F1)** — `engine.customSemanticTokens` maps each node's
  `label` (`keyword`/`property`/`string`/`number`/`operator` → legend indices
  11–13 appended in `protocol.zig`) and `span` (a byte offset into the literal)
  to an absolute range, then `mergeSemanticTokens` re-sorts them into the lexer
  stream. Unknown labels stay the opaque `string` token; a plain string is
  untouched.
- **Diagnostics (F2)** — a template's `q.failAt(span, msg)` maps through
  `template.failDiagnostic` to a `typeError` located **inside** the literal, so
  it surfaces as an ordinary diagnostic squiggle on the offending token.
- **Hover / go-to-definition (F3)** — a node may carry `ref` (a `q.lookup`
  result tying it to a caller-scope symbol). `engine.customRefNameAt` finds the
  deepest covering node under the cursor and resolves `ref.name` against the
  normal symbol table — `hoverCustomRef` renders the bound symbol's card,
  `definitionCustomRef` jumps to its declaration. Go-to-def is gated on
  `cursorInString` so the common path skips the extra compile.

The whole path is generic: any lib returning `@ExprCustom` lights up for free.
See [`src/tests/sublanguage.zig`](src/tests/sublanguage.zig).

Add a new feature → implement it in [`src/engine.zig`](src/AGENTS.md), add a
test under [`src/tests/`](src/tests/AGENTS.md) and a snapshot under
[`snapshots/lsp/`](snapshots/lsp/AGENTS.md).

# Front 05 — Tooling and docs

**Priority:** high — after F3 the editor still suggests and highlights `record`, `enum` and
`interface`, and the user docs teach a surface that no longer parses.
**Depends on:** F3 (final grammar; shares `language-server/src/engine.zig`) · F1 (shares
`engine.zig` and the tmLanguage grammar)
**Owns:** `modules/language-server/src/engine.zig` user-facing texts, keyword lists, symbol and
completion kinds · `repository/vscode-extension/**` · `repository/botopink-lang` user docs
(`docs.md`, `README.md`, `libs/std/AGENTS.md` prose, the other markdown files that teach syntax)
**Does not touch:** compiler-core, library repositories (F4), historical `specs/` and `tasks/`
documents (they record what was true then and are not rewritten)

---

## Current state

Measured at `botopink-lang` `41981e3` and `vscode-extension` `8b1c083`:

- **Hover texts** naming the declaration kind: `engine.zig:192,205,216,984,4575`.
- **Keyword token arrays**: `engine.zig:450,625,691,1040,1734,2187,3586` (compile-level changes land in F3; this front owns what they offer to the user).
- **Keyword completion list**: `engine.zig:1847–1855`.
- **Symbol / semantic-token / completion kinds** and `ContainerKind`: `engine.zig:934–936,3011,3145–3147,3259–3263,3549–3551,4780–4793`.
- **VS Code**: `syntaxes/botopink.tmLanguage.json:47` (keyword pattern), `snippets.json:67,84,94,152,161`, `README.md:6`, `docs.md:74`.
- **botopink-lang markdown** teaching the syntax: 5 files, 29 occurrences — plus the defect that `docs.md` shows `implement A for B { … }` without `val` (tracked in 1.0.2-beta, fixed here only if that item has closed).

## Steps

### Step 1 — Language server

- Hover: `type Point(x: i32, y: i32)`, `type Color { … }`, `behavior Printable`; labeled tuple types rendered `#(x: i32, y: i32)`.
- Completion: offer `type` and `behavior` at declaration start; drop `record`, `enum`, `interface`.
- Document symbols: record-shaped and enum-shaped `type` keep their LSP `SymbolKind` (`Struct` / `Enum`); `behavior` stays `Interface`.
- Snippets served by the server (if any) use the 1.0.3 separators.

**Acceptance:**
- [ ] LSP snapshots for hover, completion and document symbols re-recorded; `snap_audit.sh --mode=cutover` classes A/B only
- [ ] No user-visible string in `engine.zig` says `record`, `enum` or `interface` as a keyword

### Step 2 — VS Code extension

- tmLanguage: `type` (declaration position) and `behavior` as keywords; `record`, `enum`, `interface` removed; `#(` labeled-tuple labels scoped as property names.
- Snippets: `type` record (`type ${1:Name}(${2:field}: ${3:Type})`), `type` enum, `behavior`; bodyless members end with `;`.
- README and `docs.md` examples rewritten with `botopink migrate --syntax --markdown`.

**Acceptance:**
- [ ] Extension tests (`npm test`) green
- [ ] Grammar test fixture covers `type` record, `type` enum with sections, `behavior`, `#(x: 1)`

### Step 3 — User docs

`botopink migrate --syntax --markdown` over the owned markdown; hand-fix what it reports; add a
short "1.0.3 syntax changes" section to `docs.md` linking to
[`MIGRATION.md`](../MIGRATION.md).

**Acceptance:**
- [ ] `botopink migrate --syntax --markdown --check` exits 0 over the owned docs
- [ ] Every code fence in `docs.md` compiles (extracted and checked with `botopink check`)

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in this front's worktree
- [ ] vscode-extension `npm test` green
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Branches `fix/1.0.3-tooling` (botopink-lang) and `fix/1.0.3-syntax` (vscode-extension); no push, no merge

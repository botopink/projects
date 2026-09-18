# Front 14 — Tooling and docs

**Delivered** 2026-09-18, with two conditions it could not reach from its own files (named below).
Carried from 1.0.3-beta front 04. Landed in four waves: `botopink-lang` `26d4fdc` (hover and `renderType` in
the 1.0.3 surface), `dfc34a9` (completion while the file does not compile; the hover footer names the
declaring behavior), `758dae4` (the user-docs half and its gate stage), `84e493a` + `63dd882` (the
closeout: the project-graph diagnostics, enum sections in the outline, the two keyword completions,
the variant-on-a-value fix); `vscode-extension` `e6abeb3` (pattern ranges and tuple labels),
`1753104` + `b7c74c8` (the primitive-type list and the section fixture).

What it closed: after [`../12-surface-cutover/`](../12-surface-cutover/README.md) the editor still
suggested and highlighted `record`, `enum` and `interface`, and the user docs taught a surface that
no longer parses.

**Owned:** `modules/language-server/**` (source, tests, `snapshots/lsp/**`) ·
`repository/vscode-extension/**` · this directory.

> The user-docs half of step 3 landed with `758dae4`, which also moved its files out of this front:
> `docs.md`, `README.md`, `scripts/**`, `build.zig` and `.github/**` belong to 09 and 05 now. Step 3
> is audited here read-only.

---

## Current state

Re-measured 2026-09-18 at `botopink-lang` `63dd882` and `vscode-extension` `b7c74c8`. The
`file:line` inventory this section used to carry (measured at `41981e3` / `8b1c083`) is spent — every
row it named has either moved or closed. One of its readings was wrong and is worth recording,
because two of this front's conditions were written on top of it:

- **"Keyword completion list: `engine.zig:1847–1855`" was `isKeyword`** — the list `prepareRename`
  refuses and the import quick-fix skips, not a completion list. The server has never offered a
  keyword completion at all: `proto.CompletionItemKind.Keyword` had no use site anywhere in the
  engine until `63dd882`. So "drop `record`, `enum`, `interface`" was true from the start and
  "offer `type` and `behavior`" was a feature to write, not a list to edit. `9cdd513` re-derived
  `isKeyword` from `lexer.zig`.
- The remaining `record` / `enum` / `interface` occurrences in `engine.zig` are internal
  `TokenKind`s the lexer no longer produces (`lexer/token.zig:73-77` says so) plus the doc comments
  that explain it. No `title`, `detail`, `message` or hover text carries the words.

## Steps

### Step 1 — Language server

- Hover: `type Point(x: i32, y: i32)`, `type Color { … }`, `behavior Printable`; labeled tuple types rendered `#(x: i32, y: i32)`.
- Completion: offer `type` and `behavior` at declaration start; drop `record`, `enum`, `interface`.
- Document symbols: record-shaped and enum-shaped `type` keep their LSP `SymbolKind` (`Struct` / `Enum`); `behavior` stays `Interface`.
- Snippets served by the server (if any) use the 1.0.3 separators.

**Acceptance:**
- [x] LSP snapshots for hover, completion and document symbols re-recorded; manual classification (source-only vs output-changed)
      — hover `26d4fdc` (7 recorded), completion `dfc34a9` + `63dd882` (4 changed, 1 new),
      document symbols `63dd882` (5 new: the suite had only ever exercised the val-form
      `val Point = type(…)`, so the `Struct` / `Enum` / `Interface` mapping this step asks for was
      untested). Every one read by hand; none bulk-accepted.
- [x] No user-visible string in `engine.zig` says `record`, `enum` or `interface` as a keyword
      — **except one the front cannot reach**: see *Blocked* below.

Delivered detail:

- **Hover** — `042b80a`: `renderBindingHover` writes `pub type Point(x: i32, y: i32)` (no
  parentheses when a record has no fields), `pub type Shape { Circle(…), Square }` and
  `pub behavior Mappable<T>`, with the type parameters decision 8 §1.1 makes a written generic type
  carry. `f8bbc03`: `renderType` writes a type the way the source writes it — `i32[]`,
  `#(i32, string)`, `#(name: string, pop: i32)`.
- **Completion while the file does not compile** (the B6 investigation) — `53dad5c`: `server.zig`
  answered `null` whenever the module result was not `.ok`, so a file with any type error, or one
  being typed, got no completion at all and the engine's degraded path was never reached from the
  server. It calls `engine.completion` either way now, and `tests/completion_server.zig` drives the
  four scenarios the investigation named (failing `@emit`, a type error elsewhere, typing a prefix,
  the binding being defined) plus a `val` declared below the cursor.
- **`type` and `behavior` at declaration start** — `63dd882`: `atDeclarationStart` gates them
  (outside every `(…)`/`[…]`, right after nothing, `;`, `{`, `}` or `pub`), `CompletionItemKind.Keyword`,
  sorted after the names in scope. The rest of the keyword table is deliberately **not** offered —
  a later front that wants it takes the whole set at once rather than growing it two words at a time.
- **A section is a type in the outline** — `63dd882`, decision 8 §5.3b (decided after the hover work
  landed): `type Token { Text { Bold, Italic }, … }` gave `Text` an `EnumMember` and then skipped its
  body as a nested brace block, so `Bold` and `Italic` did not exist for the editor. A section is a
  `SymbolKind.Enum` with its own children now, at any depth. The same commit narrowed what counts as
  a member position (PascalCase, outside every `(…)`, right after `{` or `,`), closing a defect that
  predates the front: a method's return type (`-> Color {`) was read as a variant.
- **A variant is reached through the type, never a value** — `63dd882`: dot-completion on a value of
  an enum-shaped type offered every variant, which the compiler rejects
  (`fn a(c: Color) -> Color { return c.Red; }` is `error: unknown field 'Red' on type 'Color'`).
  A value receiver resolved to its named type and then reused the type-name member list unchanged.
- **Snippets served by the server** — none exist; the only `insertText` the engine writes is
  `"<label>: "` for a labeled argument. Condition met vacuously.

### Step 2 — VS Code extension

- tmLanguage: `type` (declaration position) and `behavior` as keywords; `record`, `enum`, `interface` removed; `#(` labeled-tuple labels scoped as property names.
- Snippets: `type` record (`type ${1:Name}(${2:field}: ${3:Type})`), `type` enum, `behavior`; bodyless members end with `;`.
- README and `docs.md` examples rewritten manually.

**Acceptance:**
- [x] Extension tests (`npm test`) green — 37/37 at `b7c74c8`; `npm run compiler-check` passes
      against a real checkout (lexer keywords, every snippet through `botopink check`, and now the
      primitive-type list)
- [x] Grammar test fixture covers `type` record, `type` enum with sections, `behavior`, `#(x: 1)`
      — `e6abeb3` for the tuple and the rest, `b7c74c8` for the section form

Delivered detail:

- `d00b1b3` / `eb870ac` / `a1216f5` / `53c4528`: the surface, the dead keywords, the snippets.
- `e6abeb3`: `A...B` was eaten by the `..` rule (two of three dots scoped, the third loose), and the
  tuple rule was a bare `#\(` match that scoped the opener and nothing else. Both are verified by
  **tokenizing** — `scripts/tokenize.ts` runs the grammar through `vscode-textmate` over
  `vscode-oniguruma`, the tokenizer VS Code itself uses — not by reading the regexes.
- `1753104`: the primitive-type list had drifted from the compiler in both directions. `never` was
  painted `support.type.primitive` and is registered nowhere (`fn c(x: never)` is
  `error: unknown type 'never'`), so the editor marked a word no program can name as a
  standard-library type; `isize`, `usize`, `v128` and `noreturn` are registered and were plain text.
  The rule is `Env.registerBuiltins` minus `Self` and minus `any` (decision 8 §2.5), plus `unknown`
  (decision 8 §2), and `npm run compiler-check` compares the two lists against a real checkout the
  way it already pinned the lexer keywords. Both deltas are asserted, so neither can rot into an
  accident.

### Step 3 — User docs

Migrate the owned markdown manually; add a short "1.0.3 syntax changes" section to `docs.md` linking to
[`MIGRATION.md`](../MIGRATION.md).

**Acceptance:**
- [x] No `record`, `enum`, `interface` keyword left in the owned docs (manual verification)
      — `758dae4` (`0e522ac`); re-verified 2026-09-18 over `docs.md`, `README.md` and
      `libs/std/AGENTS.md`
- [x] Every code fence in `docs.md` compiles (extracted and checked with `botopink check`)
      — `758dae4`: `scripts/check-docs.sh`, `zig build test-docs`, gate stage 9, a CI job;
      36 fences, 32 checked, 2 skipped, 0 failed on the closeout run
- [x] `docs.md:18` links `MIGRATION.md`

## Unowned items this front closed

- **`hover_interface_method`** — `dfc34a9`. The footer reads `*from `behavior Signed` (via I32)*`
  when the declaring behavior and the receiver's differ, `*from `behavior Array`*` when they agree:
  `InterfaceMember.owner` records which link of the `extends` chain declared the member. Naming only
  the receiver sent the reader to a behavior whose body has no such member.
- **`project_graph.zig` `:171` / `:210`** — `84e493a`. A dependency no library root carries and a
  `files` entry that cannot be read were both `catch continue`: the graph returned a shorter module
  list and the editor blamed the *user's* file — every symbol the missing library exports reported
  "unbound", pointing nowhere near the manifest line that is wrong. They are diagnostics now, the
  CLI's message word for word (05 step 5's `renderMissingFile`), located at the `"<entry>"` string
  inside the manifest that declares it, and published against **that manifest's** URI rather than the
  open document's. `clearGraphProblems` empties a manifest once it is fixed — the LSP clears a file
  only by publishing an empty list for it, and a manifest is never a document the client opened.
  Three tests in `tests/project_graph.zig`: a missing dependency, an unreadable `files` entry whose
  healthy sibling still loads, and a healthy project that must report none.

<a id="blocked"></a>

## What it left, and where

Three items, none of them reachable from this front's files.

| Item | Why | Owner in 1.0.5-beta |
|---|---|---|
| **A hover / completion `detail` still prints `record { name: string, count: i32 }`** (visible in `completion_decorator_record.snap.md`). `renderType` prints a type **name** verbatim, and the name is built by `comptime/infer.zig`'s `buildRecordDeclName` (`:1832`) and its two siblings `buildEnumDeclName` (`:1934`) / `buildInterfaceDeclName` (`:1891`), which spell a `type` declaration's constructor binding in the surface that no longer parses. This is the one exception to step 1's second acceptance condition | `infer.zig` is the checker's file; 14 owns no line of it | `01-checker` — rename the three builders' output, then re-record `completion_decorator_record` |
| **The `Case expression` snippet still teaches `pattern -> result;` arms** | Decision 8 §5.1 P1/P2 make an arm `Pattern { body }` with no `;`. Measured with `zig-out/bin/botopink check` at `2b098eda`: `case x { 0 { 1 } _ { 2 } }` was `error: Unexpected token` at the `{`, and `case x { 0 -> 1; _ -> 2; }` checked green. The grammar for the new arms landed later (`dff3446`), but the checker half did not, and `npm run compiler-check` runs every snippet through the compiler — so flipping the snippet reds the extension's own gate until N22 is enforced. Recorded in `vscode-extension/AGENTS.md` and `CHANGELOG.md` | `01-checker` N22, then a one-commit follow-up in `11-tooling` |
| **A type's methods keep `SymbolKind.Function`, not `Method`.** LSP-wise `Method` is the right kind for a member function, but the extension's Test Explorer classifies **every `Method` symbol as a test block** (`src/symbolNodes.ts:isTestSymbolNode`, a contract landed by tooling-update F3, since the LSP has no `Test` kind). Flipping the members without re-homing `test "…"` blocks onto some other kind would list every method as a runnable test. It is one coherent change across both repositories | deliberately left out of a closeout | `11-tooling` |

**Also left, and named here because nobody has ever owned it:** `project_graph.zig`'s third
`catch continue`, `loadSrcTree`'s read of a `.bp` under the project's own `src` (`:347` at
`aed8a60`). A file the server cannot read drops out of the graph with no diagnostic, and the editor
then blames whatever imported it. The fix is the `Problem` shape this front built, located at the
file itself. Reported by front 20's step 4 → `11-tooling`.

## Deliberately not done

- **The rest of the keyword completion table.** Step 1 asks for `type` and `behavior`; offering a
  slice of the remaining 36 would be arbitrary, and offering all of them changes what every
  completion request returns. A front that wants keyword completion takes the whole set at once.

## Gate

- [x] `scripts/gate.sh --staged` green before each `botopink-lang` commit (the pre-commit hook; every
      stage, `test-libs` / `test-language` / `test-docs` included) — never `--no-verify`
- [x] `zig build test` green in this front's worktree
- [x] vscode-extension `npm test` (37) + `npm run compiler-check` green; its own pre-commit hook ran
- [x] `AGENTS.md` of every directory touched, updated in the same commit
      (`modules/language-server/AGENTS.md`, `src/AGENTS.md`, `src/tests/AGENTS.md`;
      `vscode-extension/AGENTS.md`, `CHANGELOG.md`, `docs.md`)
- [x] Branch `fix/tooling-closeout` (botopink-lang, worktree `.tasks/tooling-closeout`) and `feat`
      (vscode-extension, committed directly), landed by the maintainer's sweep

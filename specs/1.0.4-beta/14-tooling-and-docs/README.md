# Front 14 — Tooling and docs

**Status:** **delivered** 2026-09-18, with two conditions **blocked on 06** (named below). Carried
from 1.0.3-beta front 04. Landed in four waves: `botopink-lang` `26d4fdc` (hover and `renderType` in
the 1.0.3 surface), `dfc34a9` (completion while the file does not compile; the hover footer names the
declaring behavior), `758dae4` (the user-docs half and its gate stage), `84e493a` + `63dd882` (the
closeout: the project-graph diagnostics, enum sections in the outline, the two keyword completions,
the variant-on-a-value fix); `vscode-extension` `e6abeb3` (pattern ranges and tuple labels),
`1753104` + `b7c74c8` (the primitive-type list and the section fixture).

**Priority:** high — after [`../12-surface-cutover/`](../12-surface-cutover/README.md) the editor still suggested and highlighted `record`, `enum` and
`interface`, and the user docs taught a surface that no longer parses.
**Depends on:** [`../12-surface-cutover/`](../12-surface-cutover/README.md) (final grammar; shares
`language-server/src/engine.zig`) — **met**, 12 delivered 2026-09-17
**Owns:** `modules/language-server/**` (source, tests, `snapshots/lsp/**`) · `repository/vscode-extension/**` · this directory
**Does not touch:** compiler-core, `modules/compiler-cli/**`, `docs.md`, `README.md`, `scripts/**`,
`build.zig`, `.github/**`, `libs/std/**`, `examples/**`, the library repositories
([`../13-ecosystem-migration/`](../13-ecosystem-migration/README.md)), historical `specs/` and
`tasks/` documents (they record what was true then and are not rewritten)

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

## Blocked — reported, not patched

Neither can be met from this front's files.

| Item | Why | Owner |
|---|---|---|
| **A hover / completion `detail` still prints `record { name: string, count: i32 }`** (visible in `completion_decorator_record.snap.md`). `renderType` prints a type **name** verbatim, and the name is built by `comptime/infer.zig`'s `buildRecordDeclName` (`:1832`) and its two siblings `buildEnumDeclName` (`:1934`) / `buildInterfaceDeclName` (`:1891`), which spell a `type` declaration's constructor binding in the surface that no longer parses. This is the one exception to step 1's second acceptance condition. | `modules/compiler-core/src/comptime/infer.zig` is **06's** file; 14 owns no line of it | **06** — rename the three builders' output to the 1.0.3 surface, then re-record `completion_decorator_record` |
| **The `Case expression` snippet still teaches `pattern -> result;` arms** | Decision 8 §5.1 P1/P2 (and `MIGRATION.md`'s `case` section) make an arm `Pattern { body }` with no `;`. Measured with `zig-out/bin/botopink check` at `2b098eda`: `case x { 0 { 1 } _ { 2 } }` is `error: Unexpected token` at the `{`, and `case x { 0 -> 1; _ -> 2; }` checks green. `npm run compiler-check` runs every snippet through the compiler, so flipping the snippet now reds the extension's own gate. Recorded in `vscode-extension/AGENTS.md` and `CHANGELOG.md`. | **06** (N22, the arm syntax) — then a one-commit follow-up in `vscode-extension` flips the snippet and adds the arm to the grammar fixture |

## Deliberately not done

- **A type's methods keep `SymbolKind.Function`, not `Method`.** LSP-wise `Method` is the right kind
  for a member function, but the extension's Test Explorer classifies **every `Method` symbol as a
  test block** (`src/symbolNodes.ts:isTestSymbolNode`, a contract landed by tooling-update F3, since
  the LSP has no `Test` kind). Flipping the members without re-homing `test "…"` blocks onto some
  other kind would list every method as a runnable test. It is one coherent change across both
  repositories and does not belong in a closeout — **left for whoever takes the Test Explorer next.**
- **The rest of the keyword completion table.** The step asks for `type` and `behavior`; offering a
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
      (vscode-extension, committed directly); no push, no merge, no submodule bump

---

## Rows to paste

The maintainer applies these; this front does not edit `fronts.md` or `overview.md`.

**[`../fronts.md`](../fronts.md) — Ownership table, replace row 14:**

```markdown
| **14** [`tooling-and-docs`](./14-tooling-and-docs/README.md) | `modules/language-server/src/**` (user-facing texts, completions, symbol kinds, completion in a non-compiling file, the project graph's own diagnostics), `repository/vscode-extension/**` | LSP hover/completion/symbol snapshots | **delivered** 2026-09-18 — two conditions blocked on 06 (the `record { … }` type name `infer.zig` builds; the `case` snippet's arms) |
```

**[`../fronts.md`](../fronts.md) — Unowned items, replace the two rows 14 held:**

```markdown
| ~~`hover_interface_method`~~ — **closed** 2026-09-17 by `dfc34a9`: `*from `behavior Signed` (via I32)*`, and `*from `behavior Array`*` when the declaring behavior is the receiver's | `modules/language-server/src/engine.zig` | 1.0.2-beta review-tooling (report 3.12) | 14, **done** |
| ~~A missing dependency (`:171`) and an unreadable `files` entry (`:210`) swallowed by the language server with `catch continue`~~ — **closed** 2026-09-18 by `84e493a`: both are diagnostics on the manifest that declares the entry, with the CLI's wording | `modules/language-server/src/project_graph.zig` | 1.0.2-beta library-repos, re-confirmed by 05 | 14, **done** |
```

**[`../fronts.md`](../fronts.md) — Unowned items, two new rows (both are 14's findings, neither is 14's to fix):**

```markdown
| **A `type` declaration's constructor binding is *named* `record { name: string, count: i32 }`** by `buildRecordDeclName` (and `enum {` / `interface ` by its two siblings), so hover and completion print a surface that no longer parses — the one user-visible string front 14 could not reach | `src/comptime/infer.zig` (`:1832`, `:1891`, `:1934`) | 1.0.4-beta 14 closeout, 2026-09-18 | 06 — then re-record `completion_decorator_record` |
| **A type's methods are `SymbolKind.Function`, not `Method`**, because the VS Code Test Explorer classifies every `Method` symbol as a `test "…"` block (the LSP has no `Test` kind) — the two must move together, across both repositories | `modules/language-server/src/engine.zig` (`collectChildren`) + `repository/vscode-extension/src/symbolNodes.ts` | 1.0.4-beta 14 closeout, 2026-09-18 | whoever takes the Test Explorer next |
```

**[`../fronts.md`](../fronts.md) — Conflict matrix:** drop column and row **14** (a delivered front
has no open row). The one residual interaction is the `case`-snippet follow-up, which is 06's to
hand on.

**[`../fronts.md`](../fronts.md) — Order:** in the diagram, `13 ecosystem-migration ∥ 14 tooling-and-docs — after 12`
becomes `13 ecosystem-migration — after 12 (13's decision-8 items after 06)`, and in **Critical path**
`13 ∥ 14 after 12` becomes `13 after 12`.

**[`../overview.md`](../overview.md) — the front table, replace the row for 14 (`:75`):**

```markdown
| [`14-tooling-and-docs`](./14-tooling-and-docs/README.md) | high | **delivered** — 2 conditions blocked on 06 | Language-server texts and completions (including completion in a file that does not compile and the project graph's own diagnostics), VS Code grammar and snippets, user docs. Left to 06: the `record { … }` type name `infer.zig` builds, and the `case` snippet's arms |
```

**[`../overview.md`](../overview.md) — the order diagram (`:120`):**

```
                     12 surface-cutover (alone) ──► 13 ecosystem-migration   (14 tooling-and-docs delivered)
```

**[`../overview.md`](../overview.md) — the 1.0.3-beta carry row (`:55`)** keeps naming 14 beside 06:
its grammar half (`eb870ac`, `a1216f5`) is delivered, and 06 still owns the lexer half.

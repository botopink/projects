# Front 11 — tooling

**Priority:** medium — one item is a red gate in the VS Code extension right now, one is a
cross-repository change nobody could take in a closeout, and one is a diagnostic the language server
still swallows.
**Depends on:** [`01-checker`](../01-checker/README.md) for step 4 only (the `record { … }` type name
`infer.zig` builds). Steps 1–3 and 5 can start now
**Owns:** `modules/language-server/**` **except** `src/tests/**`
([`07-review-backlog`](../07-review-backlog/README.md)) · `repository/vscode-extension/**` · the LSP
snapshot directory `modules/language-server/snapshots/lsp/` (114 files)
**Does not touch:** `modules/compiler-core/src/**` · `modules/compiler-cli/**`
([`10-cli-residuals`](../../../1.0.5-beta/10-cli-residuals/README.md)) · `docs.md`, `README.md`
([`08-hygiene`](../08-hygiene/README.md)) · the five libraries
([`09-ecosystem-residuals`](../09-ecosystem-residuals/README.md))

Paths are relative to `repository/botopink-lang/` or, where a row says `vscode-extension`, to
`repository/vscode-extension/`. Measured at `botopink-lang` `c2dd780` and `vscode-extension`'s
checked-out `feat`, 2026-09-18.

---

## Problem

1.0.4-beta's front 14 delivered and closed. It named four things it could not reach, and a fifth has
appeared since. Each is reproducible.

| # | Item | Reproduces at `c2dd780` |
|---|---|---|
| R1 | the extension's own compiler check is **red**: `test/lexerKeywords.json` does not list `unknown` | yes — quoted below |
| R2 | a type's methods are `SymbolKind.Function`, not `Method`, because the Test Explorer reads every `Method` as a `test "…"` block | yes — three sites |
| R3 | the `Case expression` snippet teaches `pattern -> result;` arms | yes — but **the blocker is gone**: `Pattern { body }` parses, checks and runs |
| R4 | hover and completion print `record { name: string, count: i32 }` as a type's name | yes — the fix is [`01-checker`](../01-checker/README.md)'s; the re-record is this front's |
| R5 | `loadSrcTree`'s `catch continue` drops an unreadable `.bp` from the project graph with no diagnostic | yes — `project_graph.zig:347` |

### R1 — the extension's compiler check is red

```
$ cd repository/vscode-extension
$ npm test                      # 37 pass, 0 fail — reads the pinned file, not the lexer
$ npm run compiler-check -- --lang …/botopink-lang --bin …/zig-out/bin/botopink
FAIL test/lexerKeywords.json is out of date with keywordOrIdent:
  lexer:  Self as assert await behavior break case catch comptime continue declare default else
          extend extends fn for from if implement import is loop mod null pub return syntax test
          throw try type unknown use val var yield
  pinned: Self as assert await behavior break case catch comptime continue declare default else
          extend extends fn for from if implement import is loop mod null pub return syntax test
          throw try type use val var yield
…
1 failure(s)
```

One word: `unknown`, which became a keyword at `botopink-lang` `6c849ae`. `npm test` passes because
its grammar test reads `test/lexerKeywords.json`; only `compiler-check`, which needs a
`--lang` pointing at a botopink-lang checkout, compares it with the lexer. **So the extension's gate
is red in exactly the configuration CI runs and green on a developer's `npm test`.**

### R2 — every `Method` symbol is a test block

`modules/language-server/src/engine.zig`, `collectChildren` (`:801`):

| Site | Emits | For |
|---|---|---|
| `:685` | `proto.SymbolKind.Method` | a `test "…"` block |
| `:924` | `proto.SymbolKind.Function` | a method inside an `enum` section |
| `:948` | `proto.SymbolKind.Function` (`const child_kind: u32 = proto.SymbolKind.Function;`) | a method on a `type` |
| `:976` | `proto.SymbolKind.Function` | a method declared in a `behavior` |

`vscode-extension/src/symbolNodes.ts:46-52`:

```ts
/**
 * Test blocks are exposed by the LSP as `Method` symbols whose name is the test
 * string (landed in tooling-update F3).
 */
export function isTestSymbolNode(symbol: SymbolNode): boolean {
  return symbol.kind === SYMBOL_KIND_METHOD;
}
```

LSP-wise `Method` is the right kind for a member function. Flipping `:924`, `:948` and `:976` without
re-homing `test "…"` onto some other kind lists **every method in the workspace as a runnable test**.
The LSP protocol has no `Test` kind, which is why the two sites were coupled in the first place. It is
one coherent change across two repositories — which is why a closeout could not take it.

### R3 — the `Case expression` snippet, and why it is no longer blocked

`vscode-extension/snippets.json:130`:

```json
"Case expression": {
  "prefix": "case",
  "body": ["case ${1:subject} {", "\t${2:pattern} -> ${3:result};", "\t_ -> ${0:fallback};", "}"],
  "description": "Pattern matching"
}
```

1.0.4-beta's front 14 measured, at `2b098eda`, that `case x { 0 { 1 } _ { 2 } }` was
`error: Unexpected token` at the `{`, so flipping the snippet would red `npm run compiler-check`.
**That is no longer true.** At `c2dd780`:

```
$ botopink check       # val y = case x { 0 { 1 } _ { 2 } };
   Checked in 61.32ms          → exit 0
$ botopink run
1
```

Both forms parse; the brace form runs and yields `1`. The blocker closed with `d0c27f6`
(decision 8's grammar). The snippet flip is now a one-commit change in this front, plus its fixture:
`vscode-extension/scripts/snippetFixtures.ts:131` fills the four tabstops
(`{1:"n", 2:"1", 3:'"one"', 0:'"other"'}`) for the arrow shape and has to fill the brace shape instead.

### R4 — `record { … }` as a type's name

```
$ grep -n 'record {' modules/language-server/snapshots/lsp/completion_decorator_record.snap.md
17:PostService  [Struct]  detail: record { name: string, count: i32 }
```

`renderType` prints a type **name** verbatim; the name is built by
`modules/compiler-core/src/comptime/infer.zig`'s `buildRecordDeclName` (`:1832` — `appendSlice(env.arena, "record")`
then ` { ` and the fields), `buildInterfaceDeclName` (`:1891`) and `buildEnumDeclName` (`:1934`). They
spell a `type` declaration's constructor binding in a surface that no longer parses.

`infer.zig` is [`01-checker`](../01-checker/README.md)'s file and this front owns no line of it. What is
this front's is the re-record afterwards, and checking that hover, completion, signature help and inlay
hints all pick it up.

### R5 — `loadSrcTree`'s swallowed read

```
$ grep -n 'catch continue' modules/language-server/src/project_graph.zig
 67:/// Both failures used to be `catch continue`: a dependency named in
347:            const source = entry.dir.readFileAlloc(self.io, entry.basename, a, .limited(10 * 1024 * 1024)) catch continue;
```

The two sites the comment at `:67` describes closed with `84e493a` — a missing dependency and an
unreadable `files` entry are now located `Problem`s on the manifest that declares the entry, with the
CLI's wording. `loadSrcTree`'s read of a `.bp` under the project's own `src` was never one of them: a
file the server cannot read drops out of the graph with no diagnostic, and the editor then blames
whatever imported it.

Found by 1.0.4-beta's front 20, which owned the CLI and not this file. **Claimed here** — this front
owns `modules/language-server/**`, and `84e493a` already built the `Problem` shape the fix uses.

## Steps

### Step 1 — the extension's gate is green in CI's configuration (R1)

Regenerate `vscode-extension/test/lexerKeywords.json` from the lexer, and make the drift impossible to
ship again: either `npm test` compares against the lexer when a botopink-lang checkout is reachable, or
CI runs `compiler-check` on every push and the README says so.

**Acceptance:**
- [ ] `npm run compiler-check -- --lang <botopink-lang> --bin <botopink>` reports `0 failure(s)`
- [ ] `unknown` is highlighted by a keyword rule in `syntaxes/botopink.tmLanguage.json` — checked by
      the existing `grammar: every lexer keyword is highlighted by some keyword rule` test, which reads
      the regenerated file
- [ ] A keyword added to the lexer and not to the extension fails a CI job, not only a local run with
      the right flag — asserted by making the check part of a workflow step and naming it in
      `vscode-extension/AGENTS.md`

### Step 2 — the `Case expression` snippet teaches decision 8 (R3)

Flip the snippet body to `Pattern { body }` arms and update its fixture.

**Acceptance:**
- [ ] `snippets.json`'s `Case expression` body is the `Pattern { body }` form with a `_ { … }` arm
- [ ] `scripts/snippetFixtures.ts` fills it, and `npm run compiler-check` compiles the filled snippet
      (`0 failure(s)`)
- [ ] The `case` arm shape is in the grammar fixture, so a regression in `botopink.tmLanguage.json`
      reds `npm test`
- [ ] `vscode-extension/CHANGELOG.md` and `AGENTS.md` record the flip and the commit that unblocked it
      (`botopink-lang` `d0c27f6`)

### Step 3 — `loadSrcTree` reports what it cannot read (R5)

Replace `project_graph.zig:347`'s `catch continue` with the `Problem` shape `84e493a` built, located at
the file itself.

**Acceptance:**
- [ ] A project whose `src/x.bp` is unreadable (mode `000`) publishes a diagnostic naming that file,
      not a diagnostic on whatever imported it
- [ ] `grep -n 'catch continue' modules/language-server/src/project_graph.zig` returns nothing but the
      comment at `:67`, which is updated to say all three closed
- [ ] An LSP unit test in `modules/language-server/src/tests/**` — **that directory is
      [`07-review-backlog`](../07-review-backlog/README.md)'s**; add the test as a named carve-out, or
      hand it over
- [ ] The row is struck from [`10-cli-residuals`](../../../1.0.5-beta/10-cli-residuals/README.md)'s step 4 table

### Step 4 — `SymbolKind.Method` for a type's methods (R2)

One change, two repositories, landed together. The extension must stop identifying a test block by its
symbol kind **before or in the same landing as** the server starts emitting `Method` for methods.

Options for re-homing `test "…"`:

| | What | Trade-off |
|---|---|---|
| A | The extension identifies a test by its **name shape** — a `Method` (or `Function`) symbol whose name is the test string, with the `detail` field carrying a marker the server writes | No protocol abuse; the marker is a server-side string the extension agrees on. Needs a marker the server sets and a snapshot re-record |
| B | The server emits `SymbolKind.Event` (or another unused kind) for `test "…"` blocks | One-line on each side; abuses a kind name that means something else in every other language server |
| C | Leave `test` as `Method`, emit `Method` for methods too, and have the extension distinguish by the **parent** symbol — a test block is a top-level symbol, a method is a child of a `type`/`behavior` | No new marker and no kind abuse. Depends on the extension seeing the tree, which `symbolNodes.ts` already does |

**Recommended: C**, with A as the fallback if a test block can ever be nested.

**Acceptance:**
- [ ] `engine.zig:924`, `:948` and `:976` emit `proto.SymbolKind.Method`
- [ ] The VS Code Test Explorer lists **only** `test "…"` blocks — driven, not read: open a file with a
      `type` that has methods and a `test` block and count the entries
- [ ] `isTestSymbolNode` no longer reads `kind === SYMBOL_KIND_METHOD` alone
- [ ] The 13 `symbols_*` LSP snapshots re-recorded and classified in the commit message (5 of them
      currently contain `Function`)
- [ ] `npm test` (37) and `npm run compiler-check` green; `zig build test` green
- [ ] Both repositories' commits land in the same sweep, with the meta submodule pointers bumped
      together

### Step 5 — re-record after the type name is fixed (R4)

After [`01-checker`](../01-checker/README.md) renames `buildRecordDeclName` and its two siblings.

**Acceptance:**
- [ ] `grep -rn 'record {' modules/language-server/snapshots/lsp/` returns nothing
- [ ] Hover, completion, signature help and inlay hints all print the 1.0.3 surface for a `type`, a
      `behavior` and an `enum` — one snapshot each, verified by reading the rendered text
- [ ] The row is struck from [`07-review-backlog`](../07-review-backlog/README.md)'s step 3 table

## Gate

- [ ] `scripts/gate.sh --cold` green in the `botopink-lang` worktree
- [ ] `vscode-extension`: `npm test` (37) **and** `npm run compiler-check -- --lang … --bin …` green —
      the second is the one that is red today
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
      (`modules/language-server/AGENTS.md`, `src/AGENTS.md`; `vscode-extension/AGENTS.md`,
      `CHANGELOG.md`)
- [ ] Branch `fix/tooling` in `botopink-lang`, `fix/tooling` in `vscode-extension`; no push, no merge,
      no submodule bump

## Blast radius

- **Step 1** changes one JSON file and, if the check moves into CI, one workflow. It turns a red gate
  green.
- **Step 2** changes two files in `vscode-extension` and no compiler behaviour.
- **Step 3** adds a diagnostic that did not exist. A project with an unreadable source file starts
  showing an error where it showed nothing; no existing LSP snapshot records that case, so none moves.
- **Step 4 re-records LSP document-symbol snapshots.** There are **114** snapshots in
  `modules/language-server/snapshots/lsp/`; 13 are `symbols_*` and 5 of those contain `Function`
  today. It also changes what the Test Explorer lists in every open workspace — the reason to drive it,
  not read it.
- **Step 5 re-records whatever prints a type name** — at least `completion_decorator_record`, and every
  hover/signature snapshot over a `type`. Count them after
  [`01-checker`](../01-checker/README.md) lands; do not scale the count from here.

## Notes

- `modules/language-server/src/tests/**` is [`07-review-backlog`](../07-review-backlog/README.md)'s,
  by the same rule that gives it every other test directory. This front needs one test in it (step 3)
  and re-records snapshots those tests write (step 4) — agree the carve-out before starting, or the two
  fronts fight over one directory for one file.
- Five stale `primitives.d.bp` comments live in this front's files
  (`language-server/src/engine.zig:1262`, `:1275`, `:4733`, `:5014`;
  `language-server/src/tests/hover.zig:181`). They are
  [`08-hygiene`](../08-hygiene/README.md) step 2's sweep — take them here in the same commit as any
  edit to those lines, or leave them.
- 1.0.4-beta's front 14 closed `hover_interface_method` (`dfc34a9`) and the two `project_graph.zig`
  diagnostics (`84e493a`). Both rows should be struck from the carried unowned table rather than
  carried into this milestone.

## Decisions the maintainer owes

1. **How a `test "…"` block is identified once methods are `Method`** — step 4's A, B or C. Until it is
   answered, the LSP keeps a wrong symbol kind for every method in the language, because the extension
   depends on the wrong one being wrong.

---

## Rows for `fronts.md`

**Ownership table:**

```markdown
| **11** [`tooling`](./README.md) | `modules/language-server/**` except `src/tests/**` (07's) · `repository/vscode-extension/**`; its meta submodule pointer | `modules/language-server/snapshots/lsp/` (114) | not started — steps 1–3, 5 ready; step 4 needs a decision, step 5 after 01 |
```

**Conflict notes** (against the other thirteen fronts):

| With | Verdict | Why |
|---|---|---|
| **01 checker** | **no** — 01 first for step 5 | `buildRecordDeclName` and its two siblings (`infer.zig:1832`, `:1891`, `:1934`) are 01's; this front re-records the LSP snapshots afterwards. 01 also re-records LSP completion snapshots when the checker changes what completion resolves |
| **02 erlang · 03 beam · 04 js · 05 wasm · 06 comptime-dedup** | yes | No shared file, no shared snapshot directory |
| **07 review-backlog** | **no** — carve-out both ways | 07 owns `modules/language-server/src/tests/**`; this front owns the source those tests drive and the snapshots they write. Step 3 needs one test in 07's directory; a 07 test rename moves an LSP snapshot this front may have just re-recorded |
| **08 hygiene** | **no** — 11 first | Five `primitives.d.bp` comments in `language-server/src/{engine.zig,tests/hover.zig}` are 08's sweep |
| **09 ecosystem-residuals** | yes | Different repositories; 09 owns the five libraries, 11 owns `vscode-extension` |
| **10 cli-residuals** | yes | 10 only *reported* `project_graph.zig:347`; this front claims the fix, and 10's step 4 strikes the row when it lands |
| **12 language-tests** | yes | No shared file. The `Case expression` snippet flip (step 2) and 12's `case` cells assert the same grammar from opposite ends |
| **13 module-identity** | yes | No shared file; the LSP does not read the erlang module atom |
| **14 comptime-on-beam** | yes | No shared file |

**Front-table row (`overview.md`):**

```markdown
| [`11-tooling`](./README.md) | medium | not started | The residuals 1.0.4-beta's tooling front could not reach: the extension's `compiler-check` is red because its pinned keyword list predates `unknown`; a type's methods are still `SymbolKind.Function` because the Test Explorer reads every `Method` symbol as a `test "…"` block, which is one change across two repositories; the `case` snippet still teaches the arrow arms whose replacement now parses and runs; and `loadSrcTree`'s third `catch continue`, which drops an unreadable source file from the project graph with no diagnostic |
```

---

## Landed — 2026-09-18

**The README's premise did not hold: steps 1–4 were already landed by the maintainer** on the morning
of 2026-09-18 — `vscode-extension` `94c1366` (step 1, the `unknown` keyword pin and its CI row),
`e553aa6` (step 2, the `case` snippet), `botopink-lang` `ae6476c` (step 3, the `loadSrcTree`
diagnostic) and `9589971` + `43eabe5` (step 4, `SymbolKind.Method`). Step 4's decision was **already
answered** too, at [decision 7](../../../1.0.5-beta/decisions-taken.md) — option (a), resolved onto the parent-in-tree
mechanism, which is this README's option C. Nothing was owed.

Each acceptance was re-verified rather than trusted: `npm run compiler-check` passes, `npm test` reads
**43/0** (this README's "37" is stale — the keyword-pin test *runs* rather than skips when
`BOTOPINK_LANG` is set), the CI runs `compiler` on every push and PR **plus** a daily schedule, and
`grep -n 'catch continue' modules/language-server/src/project_graph.zig` returns only the two
explanatory comments.

**What re-verifying found, and what landed for it** — `botopink-lang` `3c5e877`, `vscode-extension`
`dd46d1f`:

| | Before | After |
|---|---|---|
| hover | `val a : optional<i32>` | `?i32` |
| inlay hint | `: fn(optional<i32>) -> optional<string>` | `: fn(?i32) -> ?string` |
| signature help | `find(k: optional<string>, n: i32) -> optional<i32>` | `find(k: ?string, n: i32) -> ?i32` |
| code action | `newText: ": optional<i32>"` | `": ?i32"` |
| `a ?? b` in the grammar | **two** tokens, both `keyword.operator.optional` — the scope that paints the `?` of `?i32` | one `keyword.operator.nullish` |

`engine.zig:1106 renderType` had arms for `array` → `T[]` and `tuple` → `#(…)` and **none for
`optional`**, the checker's internal name (`infer.zig:4590`). The code-action row is the sharp one:
that string is written **into the user's file**, one line under a declaration the same server renders
as `fn find(k: ?string, …) -> ?i32`. **4 new LSP snapshots, 0 re-recorded** — none of the 114 existing
cells contained `optional<`, which is why it survived. The grammar fix orders `\?\?` ahead of the bare
`\?` exactly as `\.\.\.` is ordered ahead of `\.\.`.

**The two forms that landed today were walked through the server**: `??` is clean everywhere — hover,
definition, references, completion, semantic tokens, folding — and `__bp_nullish` never leaks into a
response; the index expression is clean except that **its type is `void`**, which is front 01's row
above.

**Step 5 stays blocked on front 01**, confirmed: `buildRecordDeclName` still appends `"record"` at
`comptime/infer.zig:1834`. A correction to this README's blast-radius estimate, measured rather than
projected: the re-record is **one line** — `snapshots/lsp/completion_decorator_record.snap.md:17` —
because hover and signature help over a `type`, a `behavior` and an `enum` already print the 1.0.3
surface through `renderBindingHover`. The defect surfaces only inside a decorator body, where there is
no source declaration to render from.

**Closed elsewhere:** [`10-cli-residuals`](../../../1.0.5-beta/10-cli-residuals/README.md)'s step-4 row about
`project_graph.zig:347` is closed by `ae6476c`.


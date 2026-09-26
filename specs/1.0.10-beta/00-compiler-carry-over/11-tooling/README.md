# Front 11 — tooling

**State:** closed — every step and the gate landed (C-19). Open work in the tooling area is the
process rows under `status.md` § Pending.
**Owns:** `modules/language-server/**` **except** `src/tests/**`
([`07-review-backlog`](../07-review-backlog/README.md); this front's tests there sit under the
`front 11 carve-out` banner `tests/AGENTS.md` names) · `repository/vscode-extension/**` · the LSP
snapshot directory `modules/language-server/snapshots/lsp/`
**Does not touch:** `modules/compiler-core/src/**` · `modules/compiler-cli/**`
([`10-cli-residuals`](../../../1.0.5-beta/10-cli-residuals/README.md)) · `docs.md`, `README.md`
([`08-hygiene`](../08-hygiene/README.md)) · the libraries
([`09-ecosystem-residuals`](../09-ecosystem-residuals/README.md))

Paths are relative to `repository/botopink-lang/` or, where a row says `vscode-extension`, to
`repository/vscode-extension/`.

---

## What exists

| # | Row | Today |
|---|---|---|
| R1 | the extension's keyword pin | `vscode-extension/test/lexerKeywords.json` agrees with the lexer; `npm run compiler-check -- --lang <botopink-lang> --bin <botopink>` compares them, and CI runs it on every push and PR plus a daily schedule |
| R2 | a type's methods are `SymbolKind.Method` | `engine.zig` emits `Method` at its three method sites (an `enum` section, a `type`, a `behavior`); the extension tells a `test "…"` block from a method by its parent in the symbol tree — a test block is top-level (decision 7 of 1.0.5-beta) |
| R3 | the `Case expression` snippet | teaches decision 8's `Pattern { body }` arms with a `_ { … }` arm; the filled snippet compiles under `compiler-check`, and the arm shape is in the grammar fixture |
| R4 | a type's name in hover / completion / signature help / inlay hints | the declaration-name builders in `comptime/infer.zig` (sharing `appendGenericParamsStr`) print `type Name<G>(…)`, `type Name<G> { … }`, `behavior Name<G> { … }` with every method's return type; `engine.recordCtorSignature` answers signature help over a `type` constructor (`Point(x: i32, y: i32) -> Point`) |
| R5 | `loadSrcTree` | an unreadable `.bp` under the project's `src` is a located `Problem` naming the file; `project_graph.zig` has no `catch continue` |
| — | `?T` in the server's output | `renderType` prints `?i32` in hover, inlay hints, signature help and the code action that writes a type into the user's file; `a ?? b` is one `keyword.operator.nullish` token in the grammar |

## Steps

### Step 1 — the extension's gate is green in CI's configuration (R1)

- [x] `npm run compiler-check -- --lang <botopink-lang> --bin <botopink>` reports `0 failure(s)`
- [x] `unknown` is highlighted by a keyword rule in `syntaxes/botopink.tmLanguage.json` — checked by
      the `grammar: every lexer keyword is highlighted by some keyword rule` test
- [x] A keyword added to the lexer and not to the extension fails a CI job, not only a local run with
      the right flag — the check is a workflow step, named in `vscode-extension/AGENTS.md`

### Step 2 — the `Case expression` snippet teaches decision 8 (R3)

- [x] `snippets.json`'s `Case expression` body is the `Pattern { body }` form with a `_ { … }` arm
- [x] `scripts/snippetFixtures.ts` fills it, and `npm run compiler-check` compiles the filled snippet
- [x] The `case` arm shape is in the grammar fixture, so a regression in `botopink.tmLanguage.json`
      reds `npm test`
- [x] `vscode-extension/CHANGELOG.md` and `AGENTS.md` record the flip

### Step 3 — `loadSrcTree` reports what it cannot read (R5)

- [x] A project whose `src/x.bp` is unreadable (mode `000`) publishes a diagnostic naming that file,
      not a diagnostic on whatever imported it
- [x] `grep -n 'catch continue' modules/language-server/src/project_graph.zig` returns nothing but
      the explanatory comments
- [x] An LSP unit test in `modules/language-server/src/tests/**` (07's directory, a named carve-out)
- [x] The row is struck from [`10-cli-residuals`](../../../1.0.5-beta/10-cli-residuals/README.md)'s step 4 table

### Step 4 — `SymbolKind.Method` for a type's methods (R2)

- [x] `engine.zig` emits `proto.SymbolKind.Method` at its three method sites
- [x] The VS Code Test Explorer lists **only** `test "…"` blocks — driven, not read
- [x] `isTestSymbolNode` no longer reads `kind === SYMBOL_KIND_METHOD` alone
- [x] The `symbols_*` LSP snapshots re-recorded and classified in the commit message
- [x] `npm test` and `npm run compiler-check` green; `zig build test` green
- [x] Both repositories' commits land in the same sweep, with the meta submodule pointers bumped
      together

### Step 5 — the type name in the LSP (R4, C-19)

- [x] `grep -rn 'record {' modules/language-server/snapshots/lsp/` returns nothing
- [x] Hover, completion, signature help and inlay hints all print the 1.0.3 surface for a `type`, a
      `behavior` and an `enum` — one snapshot each, verified by reading the rendered text
      (`hover_type_record`, `hover_type_enum`, `hover_behavior`, `completion_type_enum_detail`,
      `completion_behavior_detail`, `inlay_hints_val_record`, `inlay_hints_val_enum`,
      `sig_type_constructor`)
- [x] The row is struck from [`07-review-backlog`](../07-review-backlog/README.md)'s step 3 table

## Gate

- [x] `scripts/gate.sh --cold` green in the `botopink-lang` worktree
- [x] `vscode-extension`: `npm test` **and** `npm run compiler-check -- --lang … --bin …` green (the
      keyword-pin test runs when `BOTOPINK_LANG` is set and skips otherwise)
- [x] `AGENTS.md` of every directory touched, updated in the same commit
      (`modules/language-server/AGENTS.md`, `src/AGENTS.md`, `src/comptime/AGENTS.md`;
      `vscode-extension/AGENTS.md`, `CHANGELOG.md`)
- [x] Branch `front/11-tooling`; no push, no merge

## The gate's speed

`scripts/gate.sh` stays one ordered run that stops at the first failure; nothing is skipped, softened
or cached across runs. Time is saved inside the stages (`botopink-lang/scripts/AGENTS.md` § Where the
gate's time goes; the rest of the work is [`25-gate-perf`](../25-gate-perf/README.md)'s):

- **the `test-libs` worker pool** — `botopink-lib-test` runs cells on `--jobs` workers (one per CPU,
  bounded by `MemAvailable / 768 MiB`, a cell admitted only while `procs_running` ≤ CPUs) and emits
  them in discovery order from the captured output — byte for byte what `--jobs 1` prints
  (`test_tooling.sh` pins `--jobs 4` = `--jobs 1`);
- **the sidecar lookup once** — `shipErlSidecars` resolves each library's owner and probes each
  (owner, qualifier) pair once per run;
- **each `.erl` compiled once** — `botopink test --target erlang` compiles every `.erl` of the run once
  (`precompileErlang`); the test loader loads that `.beam` and compiles from source only a module with
  none, so a dead sibling is refused as before.

## Notes

- One stale `primitives.d.bp` comment is left in `language-server/src/tests/hover.zig` (the ones in
  `engine.zig` are gone) — [`08-hygiene`](../08-hygiene/README.md) step 2's sweep.

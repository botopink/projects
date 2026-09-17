# Front 11 — dead keywords, the residual

**Status:** **delivered** 2026-09-17 — jhonstart `bf868ca`, vscode-extension `eb870ac`, pushed to
both `feat`s with the meta bump. `botopink check` skips a library's `.d.bp`, so the parse was proven
with `botopink format --check` (the formatter's own rewrite of `pub interface` to
`val X = interface` was not adopted — a formatter question for 12/14).
**Priority:** low — two small edits in two sibling repositories, left behind when the compiler half
of 1.0.3-beta front 01 landed
**Status:** the compiler side **landed** in `botopink-lang` `ecac19d` (lexer, `isMemberName`, the
lexer/parser tests, the `.d.ts` reserved-word escape in `ts_emitter.zig`, the keyword tables in
`language-server/src/engine.zig`). The jhonstart and vscode-extension commits of that front
(`467505b`, `7256e25`) were never pushed and no longer exist; the meta repository kept the old
submodule pointers. This front redoes those two commits.
**Depends on:** every 1.0.2-derived front closed (01–10) — the surface fronts start on a settled
base. Shares no file with [`../12-surface-cutover/`](../12-surface-cutover/README.md) (the compiler
half it shared has landed), so the two may run together; it must land before
[`../13-ecosystem-migration/`](../13-ecosystem-migration/README.md) (jhonstart) and
[`../14-tooling-and-docs/`](../14-tooling-and-docs/README.md) (the grammar)
**Owns:** `repository/jhonstart/src/{router,server}.d.bp` and their call sites in jhonstart ·
`repository/vscode-extension/syntaxes/botopink.tmLanguage.json` (the keyword pattern only)
**Does not touch:** `repository/botopink-lang/**` (landed) · the rest of jhonstart
([`../13-ecosystem-migration/`](../13-ecosystem-migration/README.md)) · the rest of vscode-extension
([`../14-tooling-and-docs/`](../14-tooling-and-docs/README.md))

---

## Problem

`auto`, `derive`, `get`, `macro`, `opaque`, `private` and `set` lex as identifiers now. Two places
outside the compiler still treat them as keywords:

- **jhonstart's accessor declarations.** Measured 2026-09-17 in `repository/jhonstart` (`ceed5b8`):

  ```
  src/router.d.bp:20:    get pathname(self: Self) -> string
  src/router.d.bp:21:    get params(self: Self) -> Dict<string, string>
  src/server.d.bp:22:    get path(self: Self) -> string
  src/server.d.bp:23:    get params(self: Self) -> Dict<string, string>
  src/server.d.bp:24:    get query(self: Self) -> Dict<string, string>
  ```

  The interface parser rejected these before the keywords were removed; now `get` is an identifier
  followed by another identifier, which does not parse either. Values are immutable, so an accessor
  is a method with no arguments.
- **The VS Code grammar** still highlights the seven words as keywords —
  `syntaxes/botopink.tmLanguage.json:42` in `repository/vscode-extension` (`ecb44a2`):
  `…|private|…|macro|…|opaque|…|derive|…|auto|set|get|as)\b`.

## Steps

### Step 1 — jhonstart: accessors become methods

Every `get name(self: Self) -> T` in `src/router.d.bp` and `src/server.d.bp` becomes
`fn name(self: Self) -> T`. Update the call sites that read them as properties
(`router.pathname` → `router.pathname()`, `req.params` → `req.params()`, …) and the "STILL GATED"
comment in `router.d.bp` (~`:8–10`), which cites getters as a blocker.

**Acceptance:**
- [x] No `get name(self: Self)` or `set name(…)` accessor remains in any `.bp` / `.d.bp` in jhonstart
- [x] `botopink check` in `repository/jhonstart` reports no parse error in either file
- [x] `zig build test-libs` jhonstart cell no worse than before the front

### Step 2 — vscode-extension: the grammar stops highlighting the seven words

Drop `auto`, `derive`, `get`, `macro`, `opaque`, `private` and `set` from the keyword pattern. Keep
every other word — `record`, `enum`, `interface` leave with
[`../14-tooling-and-docs/`](../14-tooling-and-docs/README.md), not here.

**Acceptance:**
- [x] The pattern names none of the seven words
- [ ] The extension's test asserting the grammar's keyword list against the compiler's
      `keywordOrIdent` is green — or, if 1.0.2-beta 7e did not add one, it is added here
- [x] `npm ci && npm test` green

## Gate

- [ ] jhonstart: `botopink check` clean in the repo root with a compiler built from `botopink-lang`
      `feat`; its pre-commit hook passes (no `--no-verify`)
- [ ] vscode-extension: `npm test` green, and its CI `compiler` job green
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] One commit per repo on `fix/dead-keywords`; no push, no merge
- [ ] **Landing (the maintainer's step) includes the push of both repos and the meta submodule bump
      in one sweep** — the previous attempt was lost exactly there: the commits existed only locally
      and the meta merge kept the old pointers

## Notes

Open, carried from 1.0.3-beta front 01 and not decided here:
- `delegate` is equally dead (no parser code matches `.delegate`; delegates are `declare fn`) and
  survives only in `isReservedWord`.
- `new` is only skipped as an optional word after `throw`.
- The `.@"const"` token variant has no lexer mapping. Re-check whether `ecac19d` removed it.

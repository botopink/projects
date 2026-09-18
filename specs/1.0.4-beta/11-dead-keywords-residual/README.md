# Front 11 — dead keywords, the residual

**Delivered** 2026-09-17 — jhonstart `bf868ca`, vscode-extension `eb870ac`, pushed to both `feat`s
with the meta bump. The compiler side had landed in `botopink-lang` `ecac19d`; the jhonstart and
vscode-extension commits of 1.0.3-beta front 01 were never pushed, and this front redid them. It was
advanced ahead of 01–10 by the maintainer, sharing no file with them.

**Owned:** `repository/jhonstart/src/{router,server}.d.bp` and their call sites in jhonstart ·
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
- [x] The extension's test asserting the grammar's keyword list against the compiler's
      `keywordOrIdent` is green — or, if 1.0.2-beta 7e did not add one, it is added here
- [x] `npm ci && npm test` green

## Gate

- [x] jhonstart: `botopink check` clean in the repo root with a compiler built from `botopink-lang`
      `feat`; its pre-commit hook passes (no `--no-verify`)
- [x] vscode-extension: `npm test` green, and its CI `compiler` job green
- [x] `AGENTS.md` of every directory touched, updated in the same commit
- [x] One commit per repo on `fix/dead-keywords`; no push, no merge
- [x] **Landing (the maintainer's step) includes the push of both repos and the meta submodule bump
      in one sweep** — the previous attempt was lost exactly there: the commits existed only locally
      and the meta merge kept the old pointers

## What it left, and where

Nothing. The one item it handed on — **`delegate` and `new` stop being keywords**, decided by the
maintainer 2026-09-17 — closed inside 1.0.4-beta: the lexer/parser half as 06 N27 (`cab0bf7`: both
lex as identifiers, `throw new Error(…)` no longer parses, the unmapped `.@"const"` token variant is
deleted) and the grammar half as 14's `a1216f5` in `vscode-extension`.

The facts measured when the decision was taken, kept as the record: `delegate` was equally dead (no
parser code matched `.delegate`; delegates are `declare fn`) and survived only in `isReservedWord`;
`new` was only skipped as an optional word after `throw`; the `.@"const"` token variant had no lexer
mapping.

## Notes

`botopink check` skips a library's `.d.bp`, so the parse was proven with `botopink format --check`.
The formatter's own rewrite of `pub interface` to `val X = interface` (it dropped `pub`) was not
adopted — it was reported as a formatter question, and front 12's gate pins `pub behavior Router { … }`
round-tripping instead.

# Front 01 — Remove dead and accessor keywords

**Priority:** medium — the lexer carries seven keywords that no declaration form needs. Five are
never consumed by the parser (`auto`, `derive`, `macro`, `opaque`, `private`). Two (`get`, `set`)
are soft keywords left over from struct getters/setters — a construct that has no place in a
language whose values are immutable. All seven are noise in the keyword table and confusion for
language users.
**Depends on:** none — runs before F2 (surface cutover), which edits the same `lexer/token.zig`,
`lexer.zig`, `parser.zig` and `language-server/src/engine.zig`
**Owns:** `lexer/token.zig`, `lexer.zig`, `parser.zig` (`isMemberName` / `consumeMemberName` only),
`lexer/tests/**`, `parser/tests/{errors,declarations}.zig` (reserved-word cases) ·
`language-server/src/engine.zig` (keyword tables only) · `vscode-extension/syntaxes/botopink.tmLanguage.json` ·
`jhonstart/src/{router,server}.d.bp` · `codegen/js/ts_emitter.zig` (reserved-word escape only)
**Does not touch:** `parser/decls.zig`, `parser/exprs.zig` (call sites of `isMemberName` keep their
shape), `comptime/**`, `format.zig`, the rest of `codegen/**` (F2)

---

## Problem

The lexer maps 48 strings to keyword tokens. Seven of them serve no surface syntax:

| Keyword | TokenKind | Parser usage | .bp usage | Reserved (`isReservedWord`) |
|---|---|---|---|---|
| `auto` | `.auto` | only the reserved-word check | ❌ | ✅ |
| `derive` | `.derive` | only the reserved-word check | ❌ | ✅ |
| `macro` | `.macro` | only the reserved-word check | ❌ | ✅ |
| `opaque` | `.@"opaque"` | ❌ | ❌ | ❌ |
| `private` | `.private` | ❌ | ❌ | ❌ |
| `get` | `.get` | soft keyword: accepted as a member name (`parser.zig:1098–1100`) | as a name: `c.set(…)`, `req.params.get("id")`, field `set:`; as accessor: `get name(self: Self)` in two jhonstart `.d.bp` files | ❌ |
| `set` | `.set` | same as `get` | same as `get` | ❌ |

`get`/`set` exist to introduce struct getters/setters. Values are immutable, so a setter has
nothing to mutate and a getter is just a method with no arguments — `fn name(self: Self) -> T`
already says it. The only thing the soft keywords still do is force `isMemberName` to special-case
them so that `x.get(…)` and `x.set(…)` keep parsing.

## Current state

Measured at HEAD:

- `auto`, `derive`, `macro` — never matched by the parser; they live only in `isReservedWord`
  (`lexer.zig:753`), which the parser calls at `parser.zig:381`, `parser.zig:715` and
  `parser/exprs.zig:1003` to raise "This is a reserved word" (`print.zig:41`). The parser tests use
  `auto` as their reserved-word example (`parser/tests/errors.zig:105–135`,
  `parser/tests/declarations.zig:274–281`).
- `opaque`, `private` — mapped to tokens, never read.
- `get`, `set` — soft keywords. `isMemberName` (`parser.zig:1098`) accepts `identifier`, `.get`,
  `.set`; it is called from `parser/decls.zig:793,806,1231` and
  `parser/exprs.zig:313,408,550,693,761,909,1035,1133`.
  - Used as ordinary names: `jhonstart/src/hooks.bp:24,30,70,86`,
    `jhonstart/examples/jhonstart-counter/src/main.bp:56`, `…/posts/[id]/page.bp:27`.
  - Used as accessor syntax: `jhonstart/src/router.d.bp:20–21` (`Router.pathname`, `Router.params`)
    and `jhonstart/src/server.d.bp:22–24` (`Request.path`, `.params`, `.query`). The interface
    parser already rejects these (`parser/decls.zig:595–633`) — the files are broken today.
  - The struct getter/setter branches in `codegen/beam_asm.zig:212` and `comptime/infer.zig:419`
    reference `ast.StructDecl`, which no longer exists in `ast.zig` — dead code that is never
    compiled.
- Other references to the tokens: `language-server/src/engine.zig:3586` (switch listing every token
  by name — **does not compile** once the variants are deleted), `engine.zig:1847–1855` (keyword
  string list), `vscode-extension/syntaxes/botopink.tmLanguage.json:47` (highlighting),
  `lexer/tests/keywords.zig:54–96`, `lexer/tests/recognizes.zig:7,28,360,381,405,433,447,454,475`,
  `lexer/tests/tokenizes.zig:102` ("getter signature").
- `const` is not mapped in `keywordOrIdent`, but a `.@"const"` variant still exists in
  `lexer/token.zig:70` and is referenced at `engine.zig:3586`.

## Proposal

### Step 1 — Lexer: drop the seven keywords

In `lexer.zig:keywordOrIdent` delete the branches for `auto`, `derive`, `get`, `macro`, `opaque`,
`private`, `set`. In `lexer/token.zig` delete the variants `.auto`, `.derive`, `.get`, `.macro`,
`.@"opaque"`, `.private`, `.set`. In `isReservedWord` / `reservedWordLexeme` drop `.auto`,
`.derive`, `.macro`.

### Step 2 — Parser: member names are identifiers

`isMemberName` becomes `kind == .identifier`, and the doc comments on it and on
`consumeMemberName` drop the soft-keyword explanation. The eleven call sites keep their shape —
`x.get(…)`, `x.set(…)`, `{ value, set }` and the `set:` label now parse because `get`/`set` are
plain identifiers.

Rewrite the reserved-word parser tests (`parser/tests/errors.zig`, `parser/tests/declarations.zig`)
to use a word that is still reserved (`implement` or `test`).

### Step 3 — jhonstart: accessors become methods

In `jhonstart/src/router.d.bp` and `jhonstart/src/server.d.bp`, every `get name(self: Self) -> T`
becomes `fn name(self: Self) -> T`. Update the call sites that read them as properties
(`router.pathname` → `router.pathname()`) and the "STILL GATED" comment in `router.d.bp:8–10`,
which cites getters as a blocker.

### Step 4 — Tooling

- `language-server/src/engine.zig:3586` — drop the deleted variants from the switch (and `.@"const"`
  if it is removed with them).
- `engine.zig:1847–1855` — drop the words from the keyword completion list.
- `vscode-extension/syntaxes/botopink.tmLanguage.json:47` — drop the words from the keyword
  pattern.

### Step 5 — Tests

- `lexer/tests/keywords.zig`, `recognizes.zig`, `tokenizes.zig` — the seven words now lex as
  `.identifier`; the "getter signature" case is removed.
- New parser case: `val get = 42; val set = 1; val auto = 2;` parses, and `x.get(1)` still parses.

### Step 6 — TypeScript declarations escape reserved words

`codegen/js/ts_emitter.zig` writes every declared name and parameter name through the escape used by
`js_emitter.zig:28–38`, so `val private = 1` produces `private_` in both `main.js` and `main.d.ts`.

**Acceptance:**
- [ ] `pub val private = 1;` produces the same escaped name (`private_`) in the JS and the `.d.ts` output
- [ ] A commonJS snapshot pins it

**Front acceptance:**
- [ ] `auto`, `derive`, `macro`, `get`, `opaque`, `private`, `set` lex as `.identifier`
- [ ] `val get = 42;`, `val set = 99;`, `val auto = 10;` compile
- [ ] `x.get(k)`, `x.set(v)`, record field `set: fn(next: T)` and label `set:` still compile
- [ ] No `get name(self: Self)` accessor remains in any `.bp` / `.d.bp`
- [ ] `isReservedWord` covers only words the parser still reserves
- [ ] Language server compiles; completion list and tmLanguage grammar no longer offer the words

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in this front's worktree
- [ ] `zig build test-libs` cell for jhonstart no worse than before the front
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Commit on `fix/dead-keywords`; no push, no merge

## Blast radius

Small but not lexer-only: `parser.zig` (one predicate), two parser test files, the language server
keyword tables, the tmLanguage grammar, and two jhonstart `.d.bp` files whose accessors become
methods. No runtime behaviour changes.

Freeing `private` as an identifier reaches one emitter that does not escape reserved words: the
TypeScript declaration writer (`codegen/js/ts_emitter.zig:74,134–190`) would print
`export declare const private: …` while the JS emitter (`codegen/js/js_emitter.zig:28–38`) renames
the value to `private_`. This front routes the `.d.ts` names through the same escape table (step 6).

## Notes

The removed words can be re-added later if a feature needs them; the cost is one lexer branch and
one `TokenKind` variant.

Open, not decided here:
- `delegate` is equally dead (no parser code matches `.delegate`; delegates are `declare fn`) and
  survives only in `isReservedWord`.
- `new` is only skipped as an optional word after `throw` (`parser/exprs.zig:91`).
- The `.@"const"` variant in `lexer/token.zig:70` has no lexer mapping.

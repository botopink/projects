# Front 15 — language surface

**Priority:** high — a form the documents promise and the compiler rejects must be a named decision or
a named defect, never the catch-all `unexpectedToken`; decision 14 opened this front so the written
surface is reviewed as a whole rather than decided spelling by spelling under pressure.
**Depends on:** nothing. The hold-backs are other items': C-05 (module-level `var`), C-11 (the
trailing lambda's one-line body), C-13 (decision 29's parser half —
[`decision-29-parser-half.patch`](./decision-29-parser-half.patch), 76 lines, `isBlockShapedStmt` +
`blockStatementSemicolon`, uncommittable alone because rejecting the `;` rejects `libs/std`'s embedded
prelude).
**Owns:** `modules/compiler-core/src/parser/types.zig` · `modules/compiler-core/src/lexer.zig` and
`src/lexer/token.zig` · `src/print.zig`'s `errorMessages` table and the `ParseErrorType` enum in
`src/parser.zig` · **four named sites in `src/parser/exprs.zig`** — `parsePostfixChain`,
`parsePrimary`'s grouped-expression arm and the two block loops of the `if` then-branch and the lambda
body — a carve-out of [`01-checker`](../01-checker/README.md) · new cases in `src/parser/tests/**`, a
carve-out of [`07-review-backlog`](../07-review-backlog/README.md)
**Does not touch:** `src/comptime/**` and the rest of `src/parser/{decls,exprs,patterns}.zig`
([`01-checker`](../01-checker/README.md)) · `src/parser/decls.zig`'s member sites and `src/format.zig`
([`16-formatter`](../16-formatter/README.md)) · the loop keywords and `removedKeywordWhile`
([`22-loops`](../22-loops/README.md), decision 105) · `tests/language/**`
([`12-language-tests`](../12-language-tests/README.md)) · `docs.md`
([`08-hygiene`](../08-hygiene/README.md)) · `src/codegen/**` (fronts 02–05)

Paths are relative to `repository/botopink-lang/` unless a row says otherwise. Counts and `file:line`
were measured at `botopink-lang` `c2dd780` in a scratch worktree unless a row says otherwise.

---

## Problem

`ParseErrorType` has **48** variants and `print.zig` renders a named, located message for 47 of them;
the 48th, `unexpectedToken`, is what every unlisted form hits, so a form the language decided against
(`??`, settled by decision 14 as duplicating `catch` and `?.`) and a form a document writes as *the*
spelling (`(i32 | string)[]`, `decision-8:141`) read identically:

```
error: Unexpected token
 --> src/main.bp:1:36
  |
1 | fn main(a: ?i32) -> i32 { return a ?? 0; }
  |                                    ^ Unexpected token
  |
  = hint: Check the syntax around this position.
```

Walked deliberately — 268 probes over `decision-8-language.md`, `docs.md`, `MIGRATION.md`,
`EXAMPLES.md`, `libs/std/**`, `examples/**` and the five libraries — the surface held **24 forms
written and not parsing** and **22 that parse and then check against the document that writes them**.
The full table with an owner per row is [`surface-gaps.md`](./surface-gaps.md); decision 14's seven,
reproduced to their deciding line, are [`seven-forms.md`](./seven-forms.md).

## Current state

What parses, on `feat` — eight forms, 19 parser snapshots added and no existing snapshot re-recorded:

| Rule | Forms |
|---|---|
| **R1** — the `T[]` suffix is the type's, applied **once at the exit** of `parseBaseTypeRef` | `#(a: i32, b: string)[]`, `@Result<i32, string>[]`, `(i32 \| string)[]`, beside `Box<i32>[]`, `i32[][]`, `?i32[]`, `unknown[]` |
| **R2** — a chain link chains from **every** receiver | `("ab").length`, `(a == b).toString()`, `(sql """ab""").length`, `adder(3)(4)` |
| **R3** — a `.` continues a number only before a **digit** | `42.toString()`; `1..9`, `1.5`, `1_000`, `1e10`, `0xFF` unchanged |
| **R4** — one block body (`parseBlockBody`) | a `//` comment and a blank line inside an `if` then-branch or a lambda body — which is every collection-loop body (`for (…) { x -> … }` under decision 105; `loop (…)` until 22-loops lands) |
| **R5** — decision 30 | `xs[0]`, `d["k"]`, `s[0]`, `xs[0..2]`, `xs[0..]`, `rows(1)[0]` (typed as `at`/`slice` by C-02) |
| **R7** — decision 33 | a bodyless `fn` declares its return type, and says so when it does not |
| **R8** — decision 28 | `a ?? 0` |
| the catch-all names the token it stopped on | a deliberate refusal reads differently from a gap |

Two forms carry no new AST variant: an index is the builtin call `ast.index_builtin_name` (`"[]"`)
over `(receiver, index)`, and `a ?? b` desugars into the optional-binding `if` bound to
`ast.nullish_binding_name`.

| | Value |
|---|---|
| probes run | **268** |
| decision 14's seven | 6 distinct forms — two are one production, the seventh (a bare `if` not last in its block) is not a missing form: it parses with a `;` |
| forms written that did not parse | **24** — 18 beyond decision 14's; 8 judged defects, 10 judged decisions |
| forms that parse and check against their document | **22** — 17 owned by [`01-checker`](../01-checker/README.md), 5 by nobody |
| parser tests | **330** in 9 files, with an `expectError(src, kind, line, col)` harness (`parser/tests/surface.zig`) |
| `;` after a braced `if`/`loop`/`case` | required (`parser.zig:716-718`, `SemicolonPolicy.requiredExceptLast`) — decision 29 (c) removes it, C-13 |
| module-level `var` | C-05 (decision 28: it parses) |
| `xs[0] = 5` | an error — an index in write position needs assignment-target grammar (decision 37) |
| `val r = 1..9;` outside `for`/an index | an error |
| `1...9` in a pattern | parses and checks (decision 36); `for (a...b)` gives the token a value under decision 105 |

Two forms measured against `ead0b645` with a control beside each, found by library fronts paying
for them:

- **A negative integer literal cannot be a decorator argument, and the diagnostic blames the wrong
  token.** `#[mark(20)]` compiles and runs; `#[mark(-20)]` reds `this token cannot appear here ·
  unexpected `20`` with the caret on the **digits**. rakun front 07 ships `#[order("-100")]` through a
  `toI32` wrapper because of it; when the minus parses, that parameter goes back to `n: i32`.
- **A lambda body inside a collection loop needs a `;` the block shape says it should not.**
  `loop (xs) { x -> @print(x) };` reds `this token cannot appear here`; `loop (xs) { x -> @print(x); };`
  compiles (the form is `for (xs) { x -> … }` under decision 105; the `;` question is C-13's).

## Mechanism

The rules R1–R4 are hoisted, not per-arm: `parseBaseTypeRef` applies the `T[]` wrap on one exit path,
`parsePrimary` hands all eight receivers to `parsePostfixChain`, the lexer's number scanner requires a
digit after `.`, and both inlined block loops go through `parseStmtListInBraces`. What remains:

| Cause | Forms | Deciding line |
|---|---|---|
| no two-character `??` token — the absence is right, the message is the work | `??` | `lexer.zig:133-140` |
| a block-shaped statement does not terminate itself | `if`, `loop`, `case` followed by another statement without `;` | `parser.zig:716-718` — decision 29, C-13 |
| the decorator-argument parser consumes `-` as something else | `#[mark(-20)]` | `parser/decls.zig` (annotation arguments) |

## Steps

### Step 3 — a located message per decided-against form

Every form the language decides against gets a named `ParseErrorType` and a message that says what to
write instead, following the 47 that exist (`removedErrorUnion` and `patternRangeExclusive` are the
models; `removedKeywordWhile` leaves with decision 105). `??` is **not** among them: it parses
(decision 28, R8), so the kind this step once named for it was never written.

Landed at `botopink-lang` `8d6fa0e7` — one kind per form of [`surface-gaps.md`](./surface-gaps.md)
§ (b) that is a decision, raised **once at the site every spelling reaches**, never per arm
(`src/parser/AGENTS.md` § *A decided-against form is refused by name*):

| Form | Kind (code) | Raised at | Message names |
|---|---|---|---|
| `c ? 1 : 2` | `ternaryAbsent` | `parsePostfixChain`'s exit (`absentInfixKind`), at the `?` | `if (c) { a } else { b }` |
| `1 << 2`, `a >> 1`, `a & b`, `a ^ b` | `bitwiseOperatorAbsent` | the same exit, at the operator — `&` and `^` lex as `ampersand`/`caret` now instead of stopping the lexer | that there is none; `&&`/`\|\|`, and a host function |
| `'a'` | `charLiteralAbsent` | `parsePrimary`, at the literal — the lexer scans `'…'` as one `charLiteral` token | `"a"` |
| `fn inner(…) { … }` in a body | `nestedFnDecl` | `parsePrimary`'s `fn` arm, at the `fn` | `val inner = { x -> … };` |
| `[..a, 3]` | `listSpreadNotLast` (existed, never raised) | the array literal, at the element after the spread | `[1, 2, ..rest]` |
| `[...a]` | `listSpreadDotDotDot` | the array literal, at the `...` | `..` |
| `type P(…)` then `implement A for P { … }` | `implementClauseFor` | `types.zig` `parseImplementClause`, at the `for` — the bodyless type took `implement A` as its clause | `type P(…) implement A { … }` or `Impl implement A for P { … }` |
| `#(x: 1, y: 2)` | `tupleLiteralLabel` | the tuple literal, at the label — replaces `novalBinding` at the value | `#(1, 2)`; the labeled construction is `01-checker`'s §6 |

The call path of `parseExpr` (the statement-position chain) treats the infix tokens as "the
expression continues" in `isBinaryOpNext` and rolls back to the climber, so `g(1) ? 1 : 2` reaches
the one site. Two of `surface-gaps.md`'s step-3 rows needed nothing: `.Circle(radius: 1)` in
expression position **parses** at HEAD (it fails in the checker as `unbound variable ''` — 01's),
and a standalone `extend P { … }` already reports `anonymous-impl-extend`.

**Acceptance:**
- [x] each decided-against form has its own `ParseErrorType` variant and an `errorMessages` arm,
      asserted by `expectErrorAt(src, kind, line, col)` in `src/parser/tests/language_surface.zig`
      (R10; the harness is `tests/helpers.zig`'s, shared with `surface.zig`)
- [x] `grep -c unexpectedToken` over `src/parser/**` does not grow (13 before and after)
- [ ] a `reject/` cell per form, handed to [`12-language-tests`](../12-language-tests/README.md) with
      the `.expect` first line and location

### Step 4b — the two measured forms

**Acceptance:**
- [ ] `#[mark(-20)]` compiles and the annotation receives `-20`; if the form is instead **refused**,
      the message names the **sign**, not the digits — the present diagnostic is wrong under either
      answer
- [ ] `for (xs) { x -> f(x) };` (`loop (xs)` until 22-loops lands) parses, or reports a located
      message naming the missing `;`
- [ ] a cell for each, each proved able to fail by planting the pre-fix behaviour

### Step 5 — hand the surface over

- [ ] every form step 3 names has a `reject/` cell — specified here, written by
      [`12-language-tests`](../12-language-tests/README.md), which owns `tests/language/**`
- [ ] the `docs.md` rows that describe the surface are handed to
      [`08-hygiene`](../08-hygiene/README.md) with the replacement text — four rows of its
      "decided, not yet implemented" table describe as missing something that works
      ([`surface-gaps.md`](./surface-gaps.md) § *What the documents say is missing and is not*)
- [ ] `src/parser/AGENTS.md` and `src/lexer/AGENTS.md` state, for each hoisted rule, that it is
      applied **once at the exit** and not per-arm, so the next arm inherits it
- [ ] the rows that belong to other fronts are in those fronts' READMEs, not only in
      [`surface-gaps.md`](./surface-gaps.md)

## Gate

- [ ] `scripts/gate.sh --cold` green in this front's worktree
- [ ] every change strictly accepting or a named refusal — no existing snapshot re-records
- [ ] `zig build test-language` green, with the cells 12 writes from steps 3 and 5
- [ ] every decided-against form has a named kind, a located message and an `expectError` case
- [ ] `AGENTS.md` of every directory touched (`src/parser/`, `src/lexer/`, `src/parser/tests/`),
      updated in the same commit
- [ ] Commit on `fix/language-surface`; no push, no merge — landing is the maintainer's step

## Blast radius

- Step 3 adds error kinds nothing yet raises; step 4b changes what `#[mark(-20)]` and a one-line
  loop body parse to — both strictly accepting.
- [`16-formatter`](../16-formatter/README.md): each new form needs a printer arm, or `botopink format`
  drops it; a form arrives with its round-trip confirmed.
- [`11-tooling`](../11-tooling/README.md): the language server renders parse diagnostics; the LSP
  snapshot corpus (`modules/language-server/snapshots/lsp/`) is re-run after step 3.

## Notes

- The questions this front raised are decided: 14 (the seven forms), 28 (module-level `var` parses),
  29 (a block-shaped statement ends itself), 30 (the index expression), 31 (`any` is deleted — C-18),
  32 (no `Option` value names), 33 (a bodyless fn declares its return type), 36 (`...` is the inclusive
  pattern range), 37 (an index in write position is a question, not a gap).
- `libs/std` writes `E = any` as a default type argument on the generator wrappers
  (`@ResultGenerator<T, E = any>`, `@FutureGenerator<T, E = any>` under decision 103) — decision 31's
  deletion of `any` (C-18) needs a real default there first.

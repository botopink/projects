# Front 15 — language surface

**Priority:** high — not because any of it is red at run time, but because of **how the seven were
found**. Front 17 of 1.0.4-beta met them one at a time while writing test cells, routed around each,
and filed none; [decision 14](../decisions-taken.md#14-seven-forms-that-do-not-parse) settled them and
opened this front so that the rest of the surface is reviewed properly rather than decided spelling by
spelling under pressure. Walked deliberately, the surface holds **18 more** forms the documents write
and the compiler rejects — including one the language has no syntax for at all.
**Depends on:** nothing. **Steps 1 and 2 edit no source file** and can start immediately; steps 3–5
need the ownership below.
**Owns:** `modules/compiler-core/src/parser/types.zig` · `modules/compiler-core/src/lexer.zig` and
`src/lexer/token.zig` · `src/print.zig`'s `errorMessages` table and the `ParseErrorType` enum in
`src/parser.zig` (`:61-158`) · **four named sites in `src/parser/exprs.zig`** — `parsePostfixChain`
(`:845-877`), `parsePrimary`'s grouped-expression arm (`:1221-1227`) and the two inlined block loops
at `:162-179` (the `if` then-branch) and `:944-951` (a lambda body) — a carve-out of
[`01-checker`](../01-checker/README.md) · new cases in `src/parser/tests/**`, a carve-out
of [`07-review-backlog`](../07-review-backlog/README.md)
**Does not touch:** `src/comptime/**` and the rest of `src/parser/{decls,exprs,patterns}.zig`
([`01-checker`](../01-checker/README.md)) · `src/parser/decls.zig`'s member sites and `src/format.zig`
([`16-formatter`](../16-formatter/README.md)) · `tests/language/**`
([`12-language-tests`](../12-language-tests/README.md)) · `docs.md`
([`08-hygiene`](../08-hygiene/README.md)) · `src/codegen/**` (fronts 02–05)

Paths are relative to `repository/botopink-lang/` unless a row says otherwise. Every count and
`file:line` below was measured at `botopink-lang` `c2dd780` (2026-09-18) in a scratch worktree — never
in `repository/botopink-lang`, never in `.tasks/`.

---

## Problem

**A form the documents promise and the compiler rejects is either a decision or a defect, and today
they are indistinguishable.** Both produce:

```
error: Unexpected token
 --> src/main.bp:1:36
  |
1 | fn main(a: ?i32) -> i32 { return a ?? 0; }
  |                                    ^ Unexpected token
  |
  = hint: Check the syntax around this position.
```

`??` is a form the language does not want — [decision 14](../decisions-taken.md#14-seven-forms-that-do-not-parse)
settles that it duplicates `catch` and `?.`. `(i32 | string)[]` is a form `decision-8:141` writes as
*the* way to spell an array of a union. They give the same sentence. `ParseErrorType` has **48**
variants and `print.zig` renders a named, located message for 47 of them; the 48th,
`unexpectedToken`, is what every form in this front hits.

That is why seven of them were found by accident. Walked deliberately — 268 probes over
`decision-8-language.md`, `docs.md`, `MIGRATION.md`, `EXAMPLES.md`, `libs/std/**`, `examples/**` and
the five libraries — the count is **24 forms written and not parsing** and **22 more that parse and
then check against the document that writes them**. The full table is
[`surface-gaps.md`](./surface-gaps.md).

**And two of them are not forms at all — they are rules that were never hoisted:**

- `parseBaseTypeRef` applies the `T[]` array wrap on its named-type path (`parser/types.zig:293-300`)
  and again, copied, inside the `unknown` arm (`:88-95`). The tuple arm and the builtin-generic arm
  `return` first. So `Box<i32>[]` and `unknown[]` parse, and `#(a: i32)[]` and `@Result<i32, E>[]` do
  not.
- `parsePrimary` hands seven of its eight literal receivers to `parsePostfixChain`, whose own comment
  states the intent ("so a literal receiver chains the same way an identifier does",
  `parser/exprs.zig:838-843`). The grouped-expression arm is the eighth and does not.

**Neither gap is a decision anyone took.** Forms keep falling through them, and they are found one at
a time, forever.

## Current state

Measured at `c2dd780`; the probe harness is one scratch project per form, `botopink check`, exit code
and first diagnostic line recorded.

| | Value |
|---|---|
| probes run | **268** |
| decision 14's seven, reproduced | **7 rows → 6 distinct forms**: two of them are one production, and the seventh is not a missing form — see [`seven-forms.md`](./seven-forms.md#what-the-seven-really-are) |
| forms written in the documents that **do not parse** | **24** (the 6 above + **18 new**) |
| of the 18, the front judges a **defect** | **8** |
| of the 18, the front judges a **decision** | **10** |
| forms that parse and **check against their document** | **22** |
| of the 22, owned by [`01-checker`](../01-checker/README.md) | **17** |
| of the 22, owned by **nobody** | **5** |
| `ParseErrorType` variants | **48**; `print.zig` names 47 |
| sites that raise the catch-all | 11 explicit + the fallback at `parser.zig:345-347`, which covers every expression-level failure |
| parser tests | **330** in 9 files, with an `expectError(src, kind, line, col)` harness (`parser/tests/surface.zig`) |

The three sharpest new rows:

| Form | Written at | Today |
|---|---|---|
| `xs[0]` — **there is no index expression in the grammar** | `decision-8:112` lists indexing among the operations `unknown` refuses; `:447` says `..` is for "iteration **and slicing**" | `Unexpected token` at the `[`, in every position — read, write, string, dict |
| `(i32 \| string)[]` — and any parenthesised type | `decision-8:141`, as the way to spell an array of a union | `Unexpected token` at the `(` |
| `any` | `decision-8:129-133`: "**No `any`** — there is no type that turns the checker off" | parses and checks, and `libs/std/src/builtins.d.bp:88`, `:98` use it as a default type argument |

## Mechanism

[`seven-forms.md`](./seven-forms.md) traces decision 14's seven to their deciding line, one by one.
[`surface-gaps.md`](./surface-gaps.md) carries the full table with an owner per row. The summary:

| Cause | Forms | Deciding line |
|---|---|---|
| the `T[]` wrap is per-arm, not per-exit | `#(…)[]`, `@Result<…>[]`, and `(…)[]` which has no arm at all | `parser/types.zig:131-136`, `:230`, `:88-95`, `:293-300` |
| `parsePostfixChain` is not called from the grouped arm, and has no `(` link | `(expr).method`, `adder(3)(4)` | `parser/exprs.zig:1221-1227`, `:845-847` |
| the number scanner eats a `.` it should not | `42.toString()` — while `"ab".toUpperCase()` parses | `lexer.zig:544` — the guard tests `peekNext() != '.'` and not "is a digit" |
| no `.@"var"` arm in the top-level dispatch | module-level `var` | `parser.zig:441` |
| no two-character `??` token | `??` | `lexer.zig:133-140` |
| a block-shaped statement does not terminate itself | a bare `if`, `loop` or `case` followed by another statement — **all three parse with a `;`** | `parser.zig:716-718`, `SemicolonPolicy.requiredExceptLast` |
| two block loops inlined before `parseBlock` grew its options | a `//` comment inside an `if` **then**-branch or a lambda body — and every `loop (…) { x -> … }` body **is** a lambda body. A `//` in a fn body, a `test` body or an `if` **else**-branch parses | `parser/exprs.zig:162-179`, `:944-951` |
| a form nobody wrote a rule for | `xs[0]`, `xs[0..2]`, a bodyless top-level fn with no return type | — |

## Steps

### Step 1 — Establish the seven at this front's HEAD, and close decision 14's assignment

Re-run the seven probes in [`seven-forms.md`](./seven-forms.md), write the results in at the front's
own HEAD, and put the one thing decision 14 does not settle to the maintainer.

Decision 14 names two of the four to be made to parse (`adder(3)(4)`, `#(a: i32)[]`) and two of the
three to be recorded absent (`??`, module-level `var`). It leaves **two of the four** ("the two that
decision 8 already implies") and **the third absent form** ("the remaining form") unnamed. Measured,
the remaining candidates are `(sql """ab""").length`, `(a == b).toString()` — which are **one
production** — and the bare `if`, which **is not absent**: it parses with a `;`.

So the front's proposal is: the two are the paren-receiver pair, and the third absent slot is **empty**.
`toString` appears **zero** times in `decision-8-language.md`, so this is inference from what is left,
not a quotation, and the maintainer confirms it.

**Acceptance:**
- [ ] All seven probes re-run at HEAD; any that no longer reproduces is struck from
      [`seven-forms.md`](./seven-forms.md) with the commit that closed it
- [ ] The assignment is recorded in [`../decisions-pending.md`](../decisions-pending.md) as a new
      numbered question, with this front's proposal and the evidence for it
- [ ] `tests/language/test/closure_capture.bp:5-6` and `test/decorator_emit.bp:6-7` are named as the
      two cell headers that carry a now-incorrect description of the gap, and handed to
      [`12-language-tests`](../12-language-tests/README.md) — this front does not edit them

### Step 2 — Walk the rest, and say what is a decision and what is a defect

Re-derive [`surface-gaps.md`](./surface-gaps.md) at this front's HEAD. For every form the documents
write, one row: the spelling, where it is written (`file:line`), what the compiler does today, and
the front's judgement — **defect** (a document promises it and the compiler contradicts) or
**decision** (the language may simply not want it).

**This step produces decisions; it does not take them.** A form judged a decision leaves this front as
a question in [`../decisions-pending.md`](../decisions-pending.md) with a recommendation; a form
judged a defect leaves it as a step here, or as a row handed to the front that owns the file.

**Acceptance:**
- [ ] Every row carries a `file:line` where the form is written, or is struck for having no source
- [ ] Every row is **defect** or **decision**, with one clause of reasoning
- [ ] Every row names an owner — this front, another front, or "unowned", and every unowned row is
      opened in [`../decisions-pending.md`](../decisions-pending.md) in the same commit
- [ ] The 17 rows that belong to [`01-checker`](../01-checker/README.md) name its step, and are
      **registered with it** rather than restated: an audit that cannot tell "nobody is working on
      this" from "step 2 is working on this" produces noise
- [ ] The four stale rows of `docs.md`'s "decided, not yet implemented" table are handed to
      [`08-hygiene`](../08-hygiene/README.md); this front does not edit `docs.md`
- [ ] `xs[0]`, `xs[0..2]` and `any` are each raised as their own question — an index expression is a
      language feature, not a parser gap, and `any` is a type `libs/std` depends on and
      `decision-8:129-133` deletes

### Step 3 — A located message per form, so the next gap is filed and not routed around

The catch-all is the reason this front exists. Give every form the language **decides against** a
named `ParseErrorType` and a message that says what to write instead, following the 47 that already
exist (`removedKeywordWhile`, `removedErrorUnion`, `patternRangeExclusive` are the models).

| Form | Kind | Message names |
|---|---|---|
| `??` | `nullishCoalescingAbsent` | `?.` for chaining and `catch` for a fallback |
| `var` at module level | `moduleLevelVarAbsent` | `val`, and decision 2's "a module has no mutable state" |
| every other form step 2 records as a decision | one kind each | the form that replaces it, or that there is none |

And change the catch-all's own hint. "Check the syntax around this position." tells a reader nothing;
the compiler knows the token and the construct it was parsing.

**Acceptance:**
- [ ] Each decided-against form has its own `ParseErrorType` variant and an `errorMessages` arm
- [ ] Each is asserted by `expectError(src, kind, line, col)` in `src/parser/tests/` — the harness
      already exists (`parser/tests/surface.zig`)
- [ ] `grep -c unexpectedToken` over `src/parser/**` does not grow
- [ ] A `reject/` cell per form, handed to [`12-language-tests`](../12-language-tests/README.md) with
      the `.expect` first line and location — including the one front 17 wrote against a row that
      does not exist ([decision 15](../decisions-taken.md#15-a-lower-case-externalnode-)'s lower-case
      `#[@external]`, which is [`01-checker`](../01-checker/README.md)'s)

### Step 4 — Make them parse, by hoisting the rule rather than adding the form

Four changes, in this order. **Every one accepts a program that is a parse error today**, so no
existing program changes meaning — see [Blast radius](#blast-radius).

1. **The array-suffix family.** Hoist the `T[]` wrap loop to a single exit path of
   `parseBaseTypeRef` and delete the copy at `types.zig:88-95`. Closes `#(a: i32)[]` (decision 14),
   `@Result<…>[]`, and any arm added later. Then add the parenthesised-type arm — `(T)` and `(T)[]` —
   which is what makes `decision-8:141`'s `(i32 | string)[]` writable.
2. **The postfix chain.** Hand `parsePrimary`'s grouped arm to `parsePostfixChain`
   (`exprs.zig:1221-1227`, one line), and add a `.leftParenthesis` link to the chain's loop
   (`:845-847`) so `adder(3)(4)` parses. Both are decision 14's.
3. **The number scanner.** `lexer.zig:544` requires the character after the `.` to be a digit, so
   `42.toString()` lexes as `42` `.` `toString`. Keep the `..` guard.
4. **A comment inside an `if` then-branch or a lambda body** — which is every `loop (…) { x -> … }`
   body. `parseBlock` (`parser.zig:698-736`) takes `handleComments` and `trackEmptyLines` as options
   and `parseStmtListInBraces` (`:741-747`) sets both; **two blocks never reach it**, each carrying
   its own loop written before the options existed: the `if` then-branch (`exprs.zig:162-179`) and
   the lambda body (`:944-951`). Replace both with `parseStmtListInBraces` — the then-branch's
   `x ->` binding peek runs before the block and is unaffected. Check that the
   `useAfterBranchGuard` the shared parser applies does not red an existing program; if it does,
   call `parseBlock` with the guard off.

   **This also closes a formatter defect.** The same two loops leave `emptyLinesBefore` at 0, so
   `botopink format` **deletes** a blank line inside an `if` branch and inside a `loop` body.
   [`16-formatter`](../16-formatter/README.md) records it as its G5 and takes the printing half
   (its G6, the `if` else-branch, which the parser records and the printer drops).

**Acceptance:**
- [ ] `#(a: i32, b: string)[]`, `@Result<i32, string>[]`, `(i32 | string)[]`, `unknown[]`,
      `Box<i32>[]`, `i32[][]`, `?i32[]` all parse — the last four are regressions to guard, not new
- [ ] `("ab").length`, `(a == b).toString()`, `(sql """ab""").length` and `adder(3)(4)` parse
- [ ] `42.toString()` parses; `1..9`, `1.5`, `1_000`, `1e10`, `0xFF` are unchanged — asserted, since
      the lexer change is the riskiest line in the front
- [ ] A `//` comment parses inside an `if` then-branch, an `if` else-branch and a lambda body — and
      inside a `loop (…) { x -> … }` body, which is the same block
- [ ] A blank line inside an `if` then-branch and inside a `loop` body survives `botopink format` —
      the parser half is this step's; the else-branch's printer half is
      [`16-formatter`](../16-formatter/README.md)'s G6
- [ ] `zig build test` green from a cold cache; **no snapshot re-records** — if one does, the change
      altered an existing program and is wrong
- [ ] Each form arrives with its `src/parser/tests/` case and its `format.zig` round-trip confirmed
      with [`16-formatter`](../16-formatter/README.md) — a form the parser accepts and the printer
      cannot print back is a new defect, not a closed one

### Step 5 — Hand the surface over

Nothing here is finished until the language suite writes it and the documents say it.

**Acceptance:**
- [ ] Every form step 4 makes parse has a `test/` or `run/` cell, and every form step 3 names has a
      `reject/` cell — both specified here and written by
      [`12-language-tests`](../12-language-tests/README.md), which owns `tests/language/**`
- [ ] The `docs.md` rows that describe the surface — the four stale ones and any row step 4 changes —
      are handed to [`08-hygiene`](../08-hygiene/README.md) with the replacement text
- [ ] `src/parser/AGENTS.md` and `src/lexer/AGENTS.md` state, for each hoisted rule, that it is
      applied **once at the exit** and not per-arm, so the next arm inherits it
- [ ] The rows that belong to other fronts are in those fronts' READMEs, not only in
      [`surface-gaps.md`](./surface-gaps.md)

## Gate

- [ ] `scripts/gate.sh --cold` green in this front's worktree
- [ ] Step 4 lands **snapshot-byte-identical** — every change is strictly accepting, so nothing that
      compiles today may compile differently
- [ ] `zig build test-language` green, with the cells 12 writes from steps 3 and 5
- [ ] Every decided-against form has a named kind, a located message and an `expectError` case
- [ ] `AGENTS.md` of every directory touched (`src/parser/`, `src/lexer/`, `src/parser/tests/`),
      updated in the same commit
- [ ] Commit on `fix/language-surface`; no push, no merge — landing is the maintainer's step

## Blast radius

- **Near zero for step 4, by construction.** Every change accepts a program that is a parse error at
  `c2dd780`; none of them changes how an accepted program parses. The acceptance condition is exactly
  that: no snapshot re-records. The one line that could break this is the lexer's — `lexer.zig:544`
  currently produces the token `42.` for `42.toString`, and nothing else in the language writes a
  digit run followed by a non-digit `.`, which the float, range, underscore and radix cases assert.
- **Steps 1–3 have none.** They edit no source, or add error kinds nothing yet raises.
- **[`16-formatter`](../16-formatter/README.md).** Each new form needs a printer arm, or `botopink
  format` starts dropping it — the same class of defect that front is fixing. Step 4's acceptance
  requires the round-trip; see the conflict note. Step 4's fourth change is the shared one: replacing
  the two inlined block loops closes a parse error here **and** the blank-line loss 16 records as G5.
- **[`01-checker`](../01-checker/README.md).** `(i32 | string)[]` becoming writable makes a form
  reachable that 01's step 2 has to type. The parser change is safe alone (the form parses and then
  reports 01's existing union diagnostic), but the row should be in 01's step 2 before it lands, not
  after.
- **The documents.** 24 rows of `docs.md`, `MIGRATION.md` and `decision-8-language.md` describe the
  surface; step 5 hands the changed ones to 08. This front edits none of them.

## Notes

- **The front's output is decisions, not spellings.** Steps 1 and 2 produce questions with
  recommendations; only step 4 changes a grammar, and only for what decision 14 already settled plus
  what step 2 gets answered. A front that decides its own language questions is the thing decision 14
  opened this front to stop.
- **Two rules, not seven forms.** The array wrap and the postfix chain account for four of the six
  real forms of decision 14 and three of the new ones. Hoisting them is the difference between closing
  a list and closing the reason there was a list.
- **The seventh form is not a form.** A bare `if` that is not last parses with a `;`, and `loop` and
  `case` behave identically. Front 17's cell headers and decision 14's third "absent" slot both rest
  on a description that does not reproduce. What is left is a real question — does a block-shaped
  statement terminate itself? — and it is worth asking once, not inferring from a workaround.
- **`libs/std` writes forms a user cannot.** Three bodyless top-level fns with no return type
  (`builtins.d.bp:194`, `:309`) and `E = any` (`:88`, `:98`) — the second against
  `decision-8:129-133`. `builtins.d.bp` is doc-only, which is presumably why nobody met them.
- **Not done here:** typing anything (01), the cells (12), `docs.md` (08), the formatter's printer
  arms (16), and every (c) row in [`surface-gaps.md`](./surface-gaps.md) — this front reports them and
  routes them, and implements none.

## Decisions the maintainer owes

Each is written up with its evidence in [`surface-gaps.md`](./surface-gaps.md); they are listed here
so the step that waits on one can find it.

| # | Question | Blocks | This front's recommendation |
|---|---|---|---|
| A | **The assignment decision 14 leaves open** — which two of the seven are "the two that decision 8 already implies", and which is "the remaining form" recorded absent | step 1, step 4 | the two are `(sql """ab""").length` and `(a == b).toString()`, which are one production; the third absent slot is **empty** — the bare `if` parses with a `;` |
| B | **Does a block-shaped statement terminate itself?** `if`, `loop` and `case` all require a `;` when followed by another statement | step 2; it is what front 17 actually met | no recommendation — it is a taste question with no measured cost either way, and the front's job is to ask it once rather than let it be inferred from a workaround |
| C | **Is there an index expression?** `xs[0]` does not parse in any position, and `decision-8:112` and `:447` both presuppose it | unowned; nothing blocks on it today | **yes** — a language whose standard library has arrays, strings and dicts and no indexing syntax is not finished, and `..` is documented as slicing |
| D | **Does `any` exist?** `decision-8:129-133` says no; it parses, it checks, and `libs/std/src/builtins.d.bp:88`, `:98` use it as a default type argument | [`01-checker`](../01-checker/README.md)'s step 11 rewrite of `libs/std` | delete the type and give `Iterator<T, E, C>` a real default — a type that turns the checker off, reachable from the standard library's most-used behavior, is worse than the two lines it saves |
| E | **Is `Option` a value-level name?** `decision-8:66`, `:84` and `docs.md:396` write `Option.None` and `Some(1)`; neither is in scope, although `?T` and `.unwrapOr()` work | unowned | **the documents are wrong** — [decision 2](../decisions-taken.md#2-optiont-does-not-exist-either) already settled that `?T` is the only spelling of the type; the value-level names follow it |
| F | **A bodyless top-level `fn` with no return type** — `libs/std` declares three and a user cannot write one | step 2 | make it parse: `) F` and `) noreturn` already do, so the form is the odd one out rather than a deliberate absence |

---

## Rows for `fronts.md`

**Ownership table:**

```markdown
| **15** [`language-surface`](./15-language-surface/README.md) | `modules/compiler-core/src/parser/types.zig` · `src/lexer.zig`, `src/lexer/token.zig` · `src/print.zig` and the `ParseErrorType` enum in `src/parser.zig` · four named sites in `src/parser/exprs.zig` — `parsePostfixChain` (`:845-877`), `parsePrimary`'s grouped arm (`:1221-1227`) and the two inlined block loops (`:162-179`, `:944-951`) — a carve-out of **01** · new cases in `src/parser/tests/**` (a carve-out of **07**) | — (step 4 is strictly accepting: no snapshot may re-record) | not started — steps 1–2 edit no source and can start now; steps 3–5 need the two carve-outs |
```

**Conflict notes** (against the other fifteen fronts):

| With | Verdict | Why |
|---|---|---|
| **01 checker** | **seq — carve-out by function** | `src/parser/exprs.zig` is the shared file. 01's step 10 takes `prec.equality` at the **`if` condition** and the `_` binder; its step 4 takes the `case`-arm grammar in `decls.zig` and `patterns.zig`. 15 takes **two named functions**: `parsePostfixChain` (`:845-877`) and `parsePrimary`'s grouped-expression arm (`:1221-1227`). No function is shared. Recommended: grant 15 the two by name, as [`14-comptime-on-beam`](../14-comptime-on-beam/README.md) was granted two `infer.zig` call sites. If the maintainer prefers not to split a file, **15's step 4 runs after 01's step 10** — its other three changes (`types.zig`, `lexer.zig`, the `loop`-body comment) are unaffected either way. Separately, 15's step 2 registers **17 rows** with 01 rather than restating them, and `(i32 \| string)[]` becoming writable makes a form 01's step 2 must type |
| **02 erlang · 03 beam · 04 js · 05 wasm** | yes | No shared file. Step 4 is strictly accepting, so no `snapshots/codegen/**` file moves. Two (c) rows are theirs and are registered, not fixed here: `loop { break 1; }` yielding an array, and `$stringify` on node |
| **06 comptime-dedup** | yes | 06 owns `src/comptime/snapshot.zig` and the comptime snapshot layout; 15 writes neither, and re-records nothing |
| **07 review-backlog** | **carve-out** | 07 owns `src/parser/tests/**`. 15's steps 3 and 4 add `expectError` cases there — the same relationship every compiler front has with 07. Recommended: the new cases are 15's, the existing ones stay 07's, named in the commit message |
| **08 hygiene** | **seq — 15 before 08** | 08 owns `docs.md`. 15's step 2 finds **four stale rows** in its "decided, not yet implemented" table (`:532`, `:534`, `:535`, `:536` — all four describe as missing something that works) and step 5 hands over the rows step 4 changes. 08 edits; 15 supplies the text |
| **09 ecosystem-residuals** | yes | No shared file. A library source is not probed by this front, only read |
| **10 cli-residuals** | yes | No shared file |
| **11 tooling** | **seq, one row** | The language server renders parse diagnostics. Step 3's new `ParseErrorType` kinds change what it shows; 11 does not have to do anything, but the LSP snapshot corpus (`modules/language-server/snapshots/lsp/`, 114) should be re-run after step 3 — it is 11's directory |
| **12 language-tests** | **seq — 15 specifies, 12 writes** | `tests/language/**` is 12's, including the two cell headers (`test/closure_capture.bp:5-6`, `test/decorator_emit.bp:6-7`) that describe the gap incorrectly. Every cell steps 3 and 5 call for is specified here and written there. And `expected-failures.txt` is the shared file of the milestone: 12's step 1 re-points it before any front deletes a line |
| **13 module-identity** | yes | No shared file — 13 owns the emitters, the CLI layout and the module-atom sites |
| **14 comptime-on-beam** | yes | No shared file |
| **16 formatter** | **seq — 15 before 16, with one gap split down the middle** | No shared **function**: 15 takes `parser/{types,exprs}.zig` and the lexer, 16 takes `parser/decls.zig`'s member sites and `format.zig`. **The split is the two inlined block loops** (`exprs.zig:162-179`, `:944-951`): they refuse a `//` comment *and* drop a blank line, so 15 replaces them (a parse error is 15's) and 16 prints the result — its G6, the `if` else-branch's printer, which the parser records and `fmtBranchStmts` does not read. 16's G6 is half a fix without 15's, and 15's step 4 does not make a blank line survive without 16's. Separately, every form 15 makes parse needs a `format.zig` printer arm, or `botopink format` drops it — which is the exact class of defect 16 found in `pub default mod`. Recommended: **15 first**, each new form landing with its round-trip confirmed |

**Front-table row (`overview.md`):**

```markdown
| [`15-language-surface`](./15-language-surface/README.md) | high | An audit of the language's **written** surface against what the parser accepts — the front [decision 14](./decisions-taken.md#14-seven-forms-that-do-not-parse) opened so the rest is reviewed properly rather than decided spelling by spelling. Front 17 found seven forms by accident while writing cells; walked deliberately (268 probes over `decision-8-language.md`, `docs.md`, `MIGRATION.md`, `libs/std` and the five libraries), the surface holds **24** written forms that do not parse and **22** that parse and then contradict the document that writes them. Two of the gaps are one rule each that was never hoisted — the `T[]` wrap is applied per-arm, and `parsePostfixChain` is called from seven of eight receivers — and the reason they went unfiled is that all 48 `ParseErrorType` variants render a named message except the catch-all, which is the one every missing form hits. It produces decisions; it takes none |
```

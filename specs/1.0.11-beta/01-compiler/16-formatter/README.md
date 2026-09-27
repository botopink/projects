# Front 16 — formatter

**Priority:** medium — no program is wrong; the ecosystem writes a token the language does not want
(the `;` after a braced block) and the parser cannot refuse it until every tree stops writing it.
**Depends on:** `00-gate` (FC-1…4 — `libs/std`, `examples`, `compiler-cli/tests` and `tests/language`
reformatted and in `TREES`; FC-4 is the `tests/language` share of C-13 step 3) · the library
tracks' `c13-migrate.py` runs (rakun, jhonstart, onze; erika by 09) — step 3 lands after the last ·
`01-checker`'s parser rows (steps 10–12) — the patch rebases on them · maintainer decisions 16-a,
16-b (step 4), 16-c (step 5), 16-d (step 6).
**Owns:** `modules/compiler-core/src/format.zig` · `src/format/**` · the member-trivia and
member-order fields of `src/ast.zig` and their fill sites in `src/parser/decls.zig` (`parseEnumItem`,
`parseFieldList`, `parseMethodDecl`) — a carve-out of 01 · by carve-out from 01, for step 3 only:
`parser.zig`'s `isBracedBlockStmt` (`:969` at HEAD) and the `blockStatementSemicolon` kind, and its
`print.zig` message · [`c13-migrate.py`](./c13-migrate.py) · [`decision-29-parser-half.patch`](./decision-29-parser-half.patch)
· `scripts/format-check.sh` after 00-gate (the `TREES` list, with 25's `gate.sh` calling it)
**Does not touch:** `repository/{emilia,erika,jhonstart,onze,rakun}/**` (the tracks and 09 run the
script and the reformat; this front formats copies to measure) · the rest of `src/parser/**` and
`src/comptime/**` (01) · `src/codegen/**` · the `async` / `iter` / `stream` printer arms' semantics
(24's carve-out, landed) · `tests/language/**` (12; reformatted by the gate).
**Does not touch until 00-gate lands:** `scripts/format-check.sh` (FC-1…4 edit `TREES`).

Paths are relative to `repository/botopink-lang/` unless a row says otherwise.

## Carried from 1.0.10

| Item | 1.0.10 spec | Heading |
|---|---|---|
| C-13 step 3 (the siblings, then the refusal) | `16-formatter/README.md` · `00/README.md` | § Open, row 1 · § C-13, box 3 |
| the siblings' reformat at C-12's rules | `16-formatter/README.md` | § Open, row 2 (16-a / 16-b) |
| `commaList` and the one-step pipeline | `16-formatter/README.md` | § Open, row 3 |
| decision 61 rule 3 at `arrow_when_empty` | `16-formatter/README.md` · `00/README.md` | § Open, row 4 · § C-11, box 1 |
| C-11's trailing-lambda boxes | `00/README.md` | § C-11, boxes 1–2 (`{ -> 42 }`; `builtins.d.bp`'s `await`) |
| the patch | `15-language-surface/decision-29-parser-half.patch` | copied here (76 lines, `isBlockShapedStmt` + `blockStatementSemicolon`) |
| the script | `16-formatter/c13-migrate.py` | copied here |

## What holds

Nothing is lost (`assertLossless` over the whole corpus); the AST records the printer's trivia;
width is measured for the value constructs (C-12, decisions 61 and 65, 16-a / 16-b); a trailing
comma opens a list (decision 133); the `;` after a braced block is optional
(`Parser.isBracedBlockStmt`) and the printer writes none; the compiler's own trees are migrated;
`format --check` walks the whole project and `scripts/format-check.sh` holds the compiler's
canonical trees (`examples/modules`, two `.d.bp`, `libs/{routing,actions,validation}` at the open —
00-gate widens it). Measured at the open.

## Open

| Row | At the open | Waits on |
|---|---|---|
| **C-13 step 3.** The patch, narrowed to `isBracedBlockStmt`, would fail every tree that still writes the `;`: `tests/language` (199 files — 00-gate FC-4), rakun 454 / jhonstart 40 / erika 28 / onze 1 (1.0.10's count, unverified — re-count with the script's dry run) | decision 132's order: each library runs `c13-migrate.py` at the end of the threads writing in it; then the patch |
| **The siblings' reformat at C-12's rules** — emilia, rakun, jhonstart, erika, onze; compiling, cells equal | 16-a / 16-b confirmed; the tracks and 09 commit |
| `commaList` and the one-step pipeline pinned flat — none holds a call, so none is a wrong middle today | 16-d |
| decision 61 rule 3 stops at `arrow_when_empty` (`format.zig:1708-1730`): `h1 { "my blog" }` prints open over three lines | 16-c |
| C-11's boxes: `{ -> 42 }` / `calcular(fator: 2) { a, b -> a + b }` as a trailing lambda parse (landed: `run/loop_one_line_body`); the three `examples/jhonstart-app` files are no longer in the compiler tree (`ls examples/` at the open: `generic-loader-binding`, `modules`, `stdlib-tour`, `yamlconf`, `hello.bp`); `builtins.d.bp` formats (it is in `TREES` and green) | re-measure and close, or name what is left |

## Steps

### Step 1 — re-count the siblings' `;` sites

`c13-migrate.py --dry-run` (add the flag if absent: print the sites, write nothing) over
`repository/{rakun,jhonstart,erika,onze,emilia}/**/*.bp`; the counts written here, per library,
with the command.

**Acceptance:**
- [ ] a count per library at the open, in this README

### Step 2 — the migration in each tree (the tracks run it)

Each library track runs the script at the end of its last thread writing in that tree (09 for
erika); a run is verified as the script's docstring says — every changed line differs only by a
deleted `;`, `botopink format` of each file before and after byte-identical (the same program),
the cells green before and after. This front supplies the script and the verification command.

**Acceptance:**
- [ ] the five trees at 0 sites (step 1's command re-run answers 0)

### Step 3 — the parser refuses the `;` (decision 132)

The patch, narrowed to `isBracedBlockStmt` (the `;` after a braced `if` / loop / `case` statement
is `blockStatementSemicolon`, located at the `;`, the message naming the closing brace), rebased on
01's parser rows; the prelude, `libs/std`, `examples`, `tests/language` and the five libraries
compile; the `reject/` cell.

**Acceptance:**
- [ ] `reject/braced_block_trailing_semicolon` — the code and the caret at the `;`
- [ ] `zig build test`, `test-libs`, `test-language` green; no parser snapshot moves but the new error fixture's
- [ ] `docs.md`'s row moves from "optional" to "refused"; `src/parser/AGENTS.md` in the same commit

### Step 4 — the siblings' reformat at C-12's rules (after 16-a / 16-b)

Once confirmed, each track runs `botopink format` over its tree (this front measures on copies
first: token-identical, idempotent, cells equal; the per-library hunk counts of 16-a — emilia 18
files, rakun 47, jhonstart 19, erika 2, onze 2 — re-derived at the open).

**Acceptance:**
- [ ] the copies' measurement in this README; the tracks' commits; `botopink format --check` exit 0 in every member of every library

### Step 5 — the one-line trailing lambda (16-c)

Per 16-c (a): a one-expression trailing-lambda body that fits prints on one line, arrow or not;
the rule's canonical form written into `src/format/AGENTS.md` before it is turned on; measured on
the six trees.

**Acceptance:**
- [ ] `h1 { "my blog" }` round-trips on one line; `assertFormat` / `assertIdempotent` / `assertLossless` cases; the movement per tree measured and reported to the tracks

### Step 6 — `commaList` and the one-step pipeline (16-d)

Per 16-d (a): the exemption written into `src/format/AGENTS.md` as the rule; or (b) one
`groupMeasured` per construct, one commit each.

**Acceptance:**
- [ ] the answer's id recorded; under (b) the six trees measured before and after each construct

### Step 7 — C-11's boxes closed

`{ -> 42 }` re-measured (landed: `run/loop_one_line_body`); the `examples/jhonstart-app` clause
struck (the files are not in this tree; the jhonstart track's examples are formatted by their own
gate); `builtins.d.bp` formats.

**Acceptance:**
- [ ] the C-11 boxes ticked with the measurement, or the residual named

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in this front's worktree
- [ ] `scripts/format-check.sh` green over every tree in `TREES` (00-gate's widened list); a second pass moves nothing
- [ ] `zig build test-libs` at baseline after step 3 (every library compiles under the refusal)
- [ ] `AGENTS.md` of `src/format/`, `src/format/tests/`, `src/parser/` in the same commit as each step
- [ ] Commit on `fix/16-formatter`; no push, no merge

## Blast radius

Step 3 reds every `.bp` file anywhere that still writes the `;` — which is why it lands last and
after step 2's zero count; a library that has not migrated does not compile. Step 4 moves every
sibling file 16-a counted (+20 835 −7 292 across 142 files at 1.0.10's measurement, the compiler's
trees included and already landed). Step 5 moves every trailing-lambda call in jhonstart's trees.

## Notes

- A new form needs a printer arm here, or `botopink format` drops it: 01's step 10 (a lambda
  parameter annotation) and step 11 (a tuple after `??`) report their forms to this front, which
  adds the arms in the same milestone (`format/tests/expressions.zig`).
- `parser.zig` and `print.zig` are 01's by directory; this front's carve-out is the patch's three
  edits and nothing else — anything wider is reported.

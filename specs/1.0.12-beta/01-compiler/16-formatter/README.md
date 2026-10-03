# Front 16 — formatter: the ecosystem stops writing the `;` after a braced block, and the parser refuses it

**Priority:** medium · **State:** not started
**Depends on:** the library tracks' `c13-migrate.py` runs (rakun, jhonstart, onze; erika by
`07-residuals` step 10) — step 3 lands after the last · `01-checker`'s parser rows — the patch
rebases on them · 16-a, 16-b to confirm (step 4)
**Owns:** `modules/compiler-core/src/format.zig` · `src/format/**` · the member-trivia and
member-order fields of `src/ast.zig` and their fill sites in `src/parser/decls.zig` (`parseEnumItem`,
`parseFieldList`, `parseMethodDecl`) — a carve-out of 01 · for step 3 only, by carve-out from 01:
`parser.zig`'s `isBracedBlockStmt` and the `blockStatementSemicolon` kind, and its `print.zig`
message · [`c13-migrate.py`](./c13-migrate.py) · [`decision-29-parser-half.patch`](./decision-29-parser-half.patch)
· `scripts/format-check.sh` (the `TREES` list)
**Does not touch:** `repository/{emilia,erika,jhonstart,onze,rakun}/**` (the tracks and 07 run the
script and the reformat; this front formats copies to measure) · the rest of `src/parser/**` and
`src/comptime/**` (01) · `src/codegen/**` · `tests/language/**` (12)

Paths are relative to `repository/botopink-lang/`.

## Goal

No tree writes the `;` after a braced block statement and the parser refuses it
(`blockStatementSemicolon`); the five libraries are formatted at C-12's rules; the trailing-comma
rule of decisions 166/243 and the one-line trailing lambda of decision 165 are the printer's; every
form the parser takes has a printer arm.

## Mechanism

Nothing is lost (`assertLossless` over the whole corpus); width is measured for the value
constructs (C-12, decisions 61 and 65); the `;` after a braced block is optional
(`Parser.isBracedBlockStmt`) and the printer writes none; `scripts/format-check.sh` holds the
compiler's canonical trees (`libs/std`, `examples`, `compiler-cli/tests`, `tests/language` among
them since 00-gate/112). `c13-migrate.py` deletes the `;` after a statement that starts with `if`,
`for`, `while`, `loop`, `case`, an `iter`/`stream` prefixed loop or a `#[…]`-annotated loop and ends
with its `}` — nothing else.

## Open

### Step 1 — re-count the siblings' `;` sites

`c13-migrate.py --dry-run` (add the flag if absent: print the sites, write nothing) over
`repository/{rakun,jhonstart,erika,onze,emilia}/**/*.bp`; 1.0.10 counted rakun 454, jhonstart 40,
erika 28, onze 1.

- [ ] a count per library, with the command, in this README

### Step 2 — the migration in each tree (the tracks run it)

Each library track runs the script at the end of its last thread writing in that tree (07 for
erika); a run is verified as the script's docstring says — every changed line differs only by a
deleted `;`, `botopink format` of each file before and after byte-identical, the cells green before
and after.

- [ ] the five trees at 0 sites (step 1's command re-run answers 0)

### Step 3 — the parser refuses the `;`

The patch, narrowed to `isBracedBlockStmt` (the `;` after a braced `if` / loop / `case` statement
is `blockStatementSemicolon`, located at the `;`, the message naming the closing brace), rebased on
01's parser rows.

- [ ] `reject/braced_block_trailing_semicolon` — the code and the caret at the `;`
- [ ] `zig build test`, `test-libs`, `test-language` green; no parser snapshot moves but the new error fixture's
- [ ] `docs.md`'s row moves from "optional" to "refused"; `src/parser/AGENTS.md` in the same commit

### Step 4 — the siblings' reformat at C-12's rules (after 16-a / 16-b)

Once confirmed, each track runs `botopink format` over its tree; this front measures on copies first
(token-identical, idempotent, cells equal; 16-a's per-library hunk counts — emilia 18 files, rakun
47, jhonstart 19, erika 2, onze 2 — re-derived).

- [ ] the copies' measurement in this README; the tracks' commits; `botopink format --check` exit 0 in every member of every library

### Step 5 — the one-line trailing lambda (decision 165)

A one-expression trailing-lambda body that fits prints on one line, arrow or not; rule 3 stops at
`arrow_when_empty` today (`format.zig` `fmtLambdaAt`): `h1 { "my blog" }` prints over three lines.
The rule's canonical form written into `src/format/AGENTS.md` before it is turned on, as its own
commit after 16-a/16-b.

- [ ] `h1 { "my blog" }` round-trips on one line; `assertFormat` / `assertIdempotent` / `assertLossless` cases; the movement per tree measured and reported to the tracks

### Step 6 — a trailing comma decides (decisions 166, 243)

Every delimited list — generics, parameters, patterns, imports, types, arrays, record fields, enum
bodies, call arguments and tuples — written with a `,` after its last element prints one element
per line and keeps the comma; without it the width rules (16-a / 16-b) decide. A one-step pipeline
has no comma and stays horizontal.

- [ ] one `assertFormat` case per list kind, both spellings; the six trees measured before and after; `src/format/AGENTS.md` states the rule

### Step 7 — C-11's boxes closed

`{ -> 42 }` / `calcular(fator: 2) { a, b -> a + b }` as a trailing lambda parse
(`run/loop_one_line_body`); the `examples/jhonstart-app` clause is struck (the files are not in this
tree); `builtins.d.bp` is in `TREES` and green.

- [ ] the C-11 boxes ticked with the measurement, or the residual named

### Step 8 — the lambda parameter annotation's printer arm (for `01-checker` step 10)

`{ n: i32 -> f(n) }` prints with its annotation, so a `.bp` written with one survives `format
--check`. Lands before 01's parser half.

- [ ] `format/tests/expressions.zig`: the annotated form round-trips (`assertFormat`, `assertIdempotent`, `assertLossless`)

**Gate:** standard (fronts.md § Gate) + `scripts/format-check.sh` green over every tree in `TREES`, a
second pass moves nothing · `zig build test-libs` at baseline after step 3 (every library compiles
under the refusal)

## Notes

- A new form needs a printer arm here, or `botopink format` drops it: 01 reports each parser form
  it adds (step 8 is the one open).
- `parser.zig` and `print.zig` are 01's; this front's carve-out is the patch's three edits — anything
  wider is reported.
- Step 3 reds every `.bp` file anywhere that still writes the `;` — which is why it lands last.

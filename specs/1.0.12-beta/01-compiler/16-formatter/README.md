# Front 16 — formatter: the ecosystem stops writing the `;` after a braced block, and the parser refuses it

**Priority:** medium · **State:** not started
**Depends on:** library tracks' `c13-migrate.py` runs (rakun, jhonstart, onze; erika by
`07-residuals` step 10) — step 3 after the last · `01-checker`'s parser rows (patch rebases on them)
· 16-a, 16-b to confirm (step 4)
**Owns:** `modules/compiler-core/src/format.zig` · `src/format/**` · member-trivia and member-order
fields of `src/ast.zig` and their fill sites in `src/parser/decls.zig` (`parseEnumItem`,
`parseFieldList`, `parseMethodDecl`) — carve-out of 01 · step 3 only, carve-out of 01: `parser.zig`'s
`isBracedBlockStmt`, `blockStatementSemicolon` kind and its `print.zig` message ·
[`c13-migrate.py`](./c13-migrate.py) · [`decision-29-parser-half.patch`](./decision-29-parser-half.patch)
· `scripts/format-check.sh` (`TREES` list)
**Does not touch:** `repository/{emilia,erika,jhonstart,onze,rakun}/**` (tracks and 07 run script and
reformat; this front formats copies to measure) · rest of `src/parser/**` and `src/comptime/**` (01) ·
`src/codegen/**` · `tests/language/**` (12)

Paths relative to `repository/botopink-lang/`.

## Goal

No tree writes the `;` after a braced block statement, parser refuses it (`blockStatementSemicolon`);
five libraries formatted at C-12's rules; decisions 166/243 trailing comma and 165 one-line trailing
lambda in the printer; every parser form has a printer arm.

## Mechanism

- Lossless (`assertLossless` over the whole corpus); width measured for value constructs (C-12,
  decisions 61, 65).
- `;` after a braced block optional (`Parser.isBracedBlockStmt`), printer writes none.
- `scripts/format-check.sh` holds the canonical trees (`libs/std`, `examples`, `compiler-cli/tests`,
  `tests/language` among them since 00-gate/112).
- `c13-migrate.py` deletes the `;` after a statement starting with `if`, `for`, `while`, `loop`,
  `case`, an `iter`/`stream` prefixed loop or a `#[…]`-annotated loop and ending with its `}` —
  nothing else.

## Open

### Step 1 — re-count the siblings' `;` sites

`c13-migrate.py --dry-run` (add if absent: print sites, write nothing) over
`repository/{rakun,jhonstart,erika,onze,emilia}/**/*.bp`; 1.0.10: rakun 454, jhonstart 40, erika 28,
onze 1.

- [ ] a count per library, with the command, in this README

### Step 2 — the migration in each tree (the tracks run it)

Each track runs it at the end of its last thread in that tree (07 for erika); verified per the
script's docstring — changed lines differ only by a deleted `;`, `botopink format` before/after
byte-identical, cells green before and after.

- [ ] the five trees at 0 sites (step 1's command re-run answers 0)

### Step 3 — the parser refuses the `;`

The patch narrowed to `isBracedBlockStmt` (`;` after a braced `if` / loop / `case` statement =
`blockStatementSemicolon`, located at the `;`, message naming the closing brace), rebased on 01's
parser rows. Reds every `.bp` still writing it — hence last.

- [ ] `reject/braced_block_trailing_semicolon` — the code and the caret at the `;`
- [ ] `zig build test`, `test-libs`, `test-language` green; no parser snapshot moves but the new error fixture's
- [ ] `docs.md`'s row moves from "optional" to "refused"; `src/parser/AGENTS.md` in the same commit

### Step 4 — the siblings' reformat at C-12's rules (after 16-a / 16-b)

Once confirmed each track runs `botopink format` on its tree; this front measures copies first
(token-identical, idempotent, cells equal; 16-a's hunk counts — emilia 18 files, rakun 47, jhonstart
19, erika 2, onze 2 — re-derived).

- [ ] the copies' measurement in this README; the tracks' commits; `botopink format --check` exit 0 in every member of every library

### Step 5 — the one-line trailing lambda (decision 165)

A fitting one-expression trailing-lambda body prints on one line, arrow or not; today rule 3 stops at
`arrow_when_empty` (`format.zig` `fmtLambdaAt`): `h1 { "my blog" }` takes three lines. Canonical form
into `src/format/AGENTS.md` first; own commit after 16-a/16-b.

- [ ] `h1 { "my blog" }` round-trips on one line; `assertFormat` / `assertIdempotent` / `assertLossless` cases; movement per tree measured and reported to the tracks

### Step 6 — a trailing comma decides (decisions 166, 243)

Every delimited list (generics, parameters, patterns, imports, types, arrays, record fields, enum
bodies, call arguments, tuples) with a `,` after its last element prints one per line and keeps the
comma; without it width rules (16-a / 16-b) decide. One-step pipeline: no comma, horizontal.

- [ ] one `assertFormat` case per list kind, both spellings; the six trees measured before and after; `src/format/AGENTS.md` states the rule

### Step 7 — C-11's boxes closed

`{ -> 42 }` / `calcular(fator: 2) { a, b -> a + b }` as trailing lambdas parse
(`run/loop_one_line_body`); `examples/jhonstart-app` clause struck (files not in this tree);
`builtins.d.bp` in `TREES` and green.

- [ ] the C-11 boxes ticked with the measurement, or the residual named

### Step 8 — the lambda parameter annotation's printer arm (for `01-checker` step 10)

`{ n: i32 -> f(n) }` prints with its annotation (survives `format --check`). Before 01's parser half.

- [ ] `format/tests/expressions.zig`: the annotated form round-trips (`assertFormat`, `assertIdempotent`, `assertLossless`)

**Gate:** standard (fronts.md § Gate) + `scripts/format-check.sh` green over every `TREES` tree, a
second pass moves nothing · `zig build test-libs` at baseline after step 3 (every library compiles
under the refusal)

## Notes

- New parser form needs a printer arm here or `botopink format` drops it: 01 reports each (step 8
  the open one).
- `parser.zig`, `print.zig` are 01's; carve-out = the patch's three edits — anything wider reported.

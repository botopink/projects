# Front 16 — formatter: the ecosystem stops writing the `;` after a braced block, and the parser refuses it

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [144-botopink-lang](../README.md): s10 → B-02 · s11 → B-21 · s1 → B-28 · s2 → B-28 · s3 → B-28 · s4 → B-28 · s5 → B-28 · s6 → B-28 · s7 → B-28 · s9 → B-28. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** medium · **State:** not started
**Depends on:** library tracks' `c13-migrate.py` runs (rakun, jhonstart, onze; erika by
`07-residuals` step 10) — step 3 after the last · `01-checker`'s parser rows (patch rebases on them)
· decision 345 in the printer first (step 6, before step 4)
**Owns:** `modules/compiler-core/src/format.zig` · `src/format/**` · member-trivia and member-order
fields of `src/ast.zig` and their fill sites in `src/parser/decls.zig` (`parseEnumItem`,
`parseFieldList`, `parseMethodDecl`) — carve-out of 01 · step 3 only, carve-out of 01: `parser.zig`'s
`isBracedBlockStmt`, `blockStatementSemicolon` kind and its `print.zig` message ·
[`c13-migrate.py`](c13-migrate.py) · [`decision-29-parser-half.patch`](decision-29-parser-half.patch)
· `scripts/format-check.sh` (`TREES` list)
**Does not touch:** `repository/{emilia,erika,jhonstart,onze,rakun}/**` (tracks and 07 run script and
reformat; this front formats copies to measure) · rest of `src/parser/**` and `src/comptime/**` (01) ·
`src/codegen/**` · `tests/language/**` (12)

Paths relative to `repository/botopink-lang/`.

## Goal

No tree writes the `;` after a braced block statement, parser refuses it (`blockStatementSemicolon`);
five libraries formatted at C-12's rules; decisions 166/243 trailing comma and 165 one-line trailing
lambda in the printer; annotations printed as written (286); every parser form has a printer arm.

## Mechanism

- Lossless (`assertLossless` over the whole corpus); width measured for value constructs (C-12,
  decisions 61, 65).
- `;` after a braced block optional (`Parser.isBracedBlockStmt`), printer writes none.
- `scripts/format-check.sh` holds the canonical trees (`libs/std`, `examples`, `compiler-cli/tests`,
  `tests/language` among them since 00-gate/112).
- `c13-migrate.py` deletes the `;` after a statement starting with `if`, `for`, `while`, `loop`,
  `case`, an `iter`/`stream` prefixed loop or a `#[…]`-annotated loop and ending with its `}` —
  nothing else.

## Notes

- New parser form needs a printer arm here or `botopink format` drops it: 01 reports each (the
  template annotation `#[f "…"]`, 311, is step 9's).
- `parser.zig`, `print.zig` are 01's; carve-out = the patch's three edits — anything wider reported.

# Front 16 — formatter

**Track:** compiler (carry-over items **C-11**, **C-12**, **C-13**, **G7**)
**State:** landed. `botopink format` is lossless and idempotent, `format --check` walks the whole
project, the value constructs measure width, a trailing comma keeps a list open (decision 133), and
the `;` after a braced block is optional and not printed. Open: refusing that `;` once every source is
migrated (decision 132), the siblings' reformat, and the rows in § *Open*.
**Owns:** `modules/compiler-core/src/format.zig` · `modules/compiler-core/src/format/**` (the formatter
tests) · the member-trivia and member-order fields of `modules/compiler-core/src/ast.zig` and the sites
that fill them in `src/parser/decls.zig` (`parseEnumItem`, `parseFieldList`, `parseMethodDecl`) — a
carve-out of [`01-checker`](../01-checker/README.md) · [`c13-migrate.py`](./c13-migrate.py)
**Does not touch:** `repository/{emilia,erika,jhonstart,onze,rakun}/**` (this front formats copies;
[`09-ecosystem-residuals`](../09-ecosystem-residuals/README.md) commits) · the rest of `src/parser/**`
and `src/comptime/**` ([`01-checker`](../01-checker/README.md)) · `src/codegen/**` · the `while` /
`for` printer arms ([`22-loops`](../22-loops/README.md)'s carve-out)

Paths are relative to `repository/botopink-lang/` unless a row says otherwise.

---

## What holds

**Nothing is lost.** Every token of the source — keywords and comments alike — appears in the output:
`assertLossless` in `src/format/tests/helpers.zig` lexes input and output and asserts token
containment, with the written-out exemption `droppable_separators`; `assertIdempotent` calls it, so
idempotence and fidelity cannot come apart (a deletion is idempotent). `src/format/tests/AGENTS.md`
states the property. Order is not asserted: the canonical form may move a token.

**What the AST records for the printer** (additive optionals, omitted from the JSON dump when empty,
so no snapshot moves):

| Field | Holds |
|---|---|
| `EnumVariant.order`, `EnumSection.order` | the written order of an enum body's members; the printer merges `variants` and `sections` by it, so nothing hoists. No emitter may read `order`; wasm's all-unit enum is a variant's index among `variants`, which the formatter never permutes |
| `Field.trailingComment` | a record field's same-line comment, printed after the comma |
| `EnumVariant.comments`, `.trailingComment` | a variant's comments (`""` is a blank line, as on the other members) |
| `BehaviorMethod.trailingComment` | a method's same-line comment |
| `EnumSection.bodyComments`, `TypeDecl.bodyComments` | comments before a section's or an enum body's `}` |
| `trailingPerElem` on array and tuple literals | an element's same-line comment, kept on its line |

`ModDecl.isDefault` and `FnDecl.isDefault` are printed (`pub default mod X;`, `pub default fn f`);
an `if` branch keeps its blank lines (one statement-sequence printer); a comment continuing a trailing
comment from the same source column prints under the first comment's printed column
(`Doc.markColumn` / `Doc.alignToMark`); a handler-less `val assert P = e;` prints as written.

**Width** (C-12, decisions 61 and 65, `decisions-pending.md` 16-a / 16-b): the value constructs —
binary runs, a brace-less `if`, argument lists, array / tuple / behavior literals — measure width,
enclosing ones first. A trailing comma opens a list that fits (decision 133).

**The `;` after a braced block** (C-13, decision 29): a braced `if` / loop / `case` statement takes its
`;` or not (`Parser.isBracedBlockStmt`: the shape and a closing `}` as the last token), and the printer
writes none. The compiler's own trees are migrated (`libs/std`, `examples/`, the bundled libraries,
`docs.md`'s fences). [`c13-migrate.py`](./c13-migrate.py) deletes the `;` in a tree `botopink format`
does not own.

**`format --check`** walks the whole project; `scripts/format-check.sh` holds the compiler's trees.

## Open

| Row | Waits on |
|---|---|
| **C-13 — refusing the `;`.** Front 15's parked [`decision-29-parser-half.patch`](../15-language-surface/decision-29-parser-half.patch), narrowed to `isBracedBlockStmt`, would fail `tests/language` and the siblings until they migrate (rakun, jhonstart, erika and onze still write it; emilia does not) | [decision 132](../../decisions-taken.md#132-the--after-a-braced-block-becomes-an-error-once-every-source-is-migrated): each library runs `c13-migrate.py` at the end of the threads writing in it, `tests/language` in the language-tests front, then the patch |
| **The siblings' reformat at C-12's rules** — emilia, rakun, jhonstart, erika, onze; compiling, cells equal | 09, after the maintainer confirms 16-a / 16-b |
| `commaList` (generic, parameter, pattern, import and type lists) and the one-step pipeline are still pinned — none holds a call, so none is a wrong middle today | a construct-by-construct decision, as decision 65 part 4 stages them |
| Decision 61 rule 3's one-line rule stops at `arrow_when_empty`, so `h1 { "my blog" }` prints open over three lines (the parse error it guarded against is gone) | a formatter row — it moves every trailing-lambda call in the frontend library |

- [ ] `scripts/gate.sh --cold` green in this front's worktree — every stage but `test-libs`, which
      from a `.tasks/*` worktree reads the main checkout's `repository/rakun` (ahead of the worktree's
      compiler); with the worktree's own trees `test-libs` is green

## Delivered

- every red file of the five libraries classified; every information loss found named and fixed; the
  formatted copies of the five libraries compile and their cells pass as before; a second pass moves
  nothing
- `pub default mod` / `pub default fn` round-trip, with `assertFormat` cases in
  `src/format/tests/declarations.zig`; a package whose handle, module and handler names differ still
  resolves in its consumer after `format`
- the probes (an enum variant's comment, a field's trailing comment, a method's trailing comment)
  round-trip byte-identically; an `if` branch and a loop body keep their blank lines
- the parser/AST commits snapshot-byte-identical; the `.variants()` / `.sections()` call sites untouched
- `assertLossless` exists, fails on the pre-fix formatter, is defined over the whole token stream, and
  runs over the whole formatter corpus
- each canonical-form disagreement where the library was right implemented (decision 61 rules 4 and 2;
  C-12's comment column); none moved without the maintainer's decision
- emilia's `src/tokens.bp` formats without reordering; decisions 66 / 67 made the one exemption
  structural (`reject/**`), with no knob
- the printer arms for the forms 15 made parse: `(i32 | string)[]`, `adder(3)(4)`, `xs[0]`, `a ?? 0`
  print as written
- `AGENTS.md` of `src/format/`, `src/format/tests/`, `src/parser/` updated

## Handed over by `09-ecosystem-residuals` (2026-09-18)

Both information losses 09 found while formatting the libraries are fixed: `rakun/src/runtime.bp`'s
continuation comment keeps its column (C-12's comment column), and
`erika/examples/erika-linq/src/main.bp:111-113`'s array elements keep their trailing comments on their
lines (`trailingPerElem`).

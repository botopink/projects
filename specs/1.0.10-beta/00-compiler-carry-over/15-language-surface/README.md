# Front 15 — language surface

**State:** closed. Every form the language decided against is refused by name, located, with a
message that says what to write instead, and has its `reject/` cell. Decision 132's refusal of the
`;` after a braced block is not this front's: its parser half is parked here as
[`decision-29-parser-half.patch`](./decision-29-parser-half.patch) (`isBlockShapedStmt` +
`blockStatementSemicolon`, to be narrowed to `isBracedBlockStmt`) and lands with
[`16-formatter`](../16-formatter/README.md) once every library and `tests/language` is migrated.
**Owns:** `modules/compiler-core/src/parser/types.zig` · `src/lexer.zig` and `src/lexer/token.zig` ·
`src/print.zig`'s `errorMessages` table and the `ParseErrorType` enum in `src/parser.zig` · four named
sites in `src/parser/exprs.zig` — `parsePostfixChain`, `parsePrimary`'s grouped-expression arm and
the block loops of the `if` then-branch and the lambda body · its cases in `src/parser/tests/**`
**Does not touch:** `src/comptime/**` and the rest of `src/parser/{decls,exprs,patterns}.zig`
([`01-checker`](../01-checker/README.md)) · `src/parser/decls.zig`'s member sites and `src/format.zig`
([`16-formatter`](../16-formatter/README.md)) · the loop keywords ([`22-loops`](../22-loops/README.md))
· `tests/language/**` ([`12-language-tests`](../12-language-tests/README.md)) · `docs.md`
([`08-hygiene`](../08-hygiene/README.md)) · `src/codegen/**`

Paths are relative to `repository/botopink-lang/`.

---

## What holds

**The hoisted rules** — each applied once at the exit, never per arm (`src/parser/AGENTS.md`,
`src/lexer/AGENTS.md`):

| Rule | Forms |
|---|---|
| **R1** — the `T[]` suffix is the type's, applied once at the exit of `parseBaseTypeRef` | `#(a: i32, b: string)[]`, `@Result<i32, string>[]`, `(i32 \| string)[]`, `Box<i32>[]`, `i32[][]`, `?i32[]`, `unknown[]` |
| **R2** — a chain link chains from every receiver | `("ab").length`, `(a == b).toString()`, `(sql """ab""").length`, `adder(3)(4)` |
| **R3** — a `.` continues a number only before a digit | `42.toString()`; `1..9`, `1.5`, `1_000`, `1e10`, `0xFF` |
| **R4** — one block body (`parseBlockBody`) | a `//` comment and a blank line inside an `if` then-branch or a lambda body, every `for (xs) { x -> … }` body included |
| **R5** — decision 30 | `xs[0]`, `d["k"]`, `s[0]`, `xs[0..2]`, `xs[0..]`, `rows(1)[0]` (typed as `at`/`slice`) |
| **R7** — decision 33 | a bodyless `fn` declares its return type, and says so when it does not |
| **R8** — decision 28 | `a ?? 0` |

An index is the builtin call `ast.index_builtin_name` (`"[]"`) over `(receiver, index)`; `a ?? b`
desugars into the optional-binding `if` bound to `ast.nullish_binding_name`. The catch-all
`unexpectedToken` names the token it stopped on.

**A decided-against form is refused by name**, raised once at the site every spelling reaches:

| Form | Kind (code) | Raised at | Message names |
|---|---|---|---|
| `c ? 1 : 2` | `ternaryAbsent` | `parsePostfixChain`'s exit (`absentInfixKind`), at the `?` | `if (c) { a } else { b }` |
| `1 << 2`, `a >> 1`, `a & b`, `a ^ b` | `bitwiseOperatorAbsent` | the same exit, at the operator (`&` and `^` lex as `ampersand` / `caret`) | that there is none; `&&` / `\|\|`, and a host function |
| `'a'` | `charLiteralAbsent` | `parsePrimary`, at the literal (one `charLiteral` token) | `"a"` |
| `fn inner(…) { … }` in a body | `nestedFnDecl` | `parsePrimary`'s `fn` arm | `val inner = { x -> … };` |
| `[..a, 3]` | `listSpreadNotLast` | the array literal, at the element after the spread | `[1, 2, ..rest]` |
| `[...a]` | `listSpreadDotDotDot` | the array literal, at the `...` | `..` |
| `type P(…)` then `implement A for P { … }` | `implementClauseFor` | `types.zig` `parseImplementClause`, at the `for` | `type P(…) implement A { … }` or `Impl implement A for P { … }` |
| `#(x: 1, y: 2)` | `tupleLiteralLabel` | the tuple literal, at the label | `#(1, 2)` |

Each is asserted by `expectErrorAt(src, kind, line, col)` in `src/parser/tests/language_surface.zig`
and has its cell: `tests/language/reject/{ternary_absent,bitwise_operator_absent,char_literal_absent,nested_fn_decl,list_spread_not_last,list_spread_dot_dot_dot,implement_clause_for,tuple_literal_label}`.

**Two forms accepted:** `#[mark(-20)]` — `parseAnnotationCall` spans a `-` and the digits after it
into one argument lexeme, so the decorator receives `-20` (`run/decorator_negative_argument`); a
one-line trailing-lambda or loop body needs no `;` (`for (xs) { x -> f(x) }`, `xs.map { x -> f(x) }`,
`memo { -> 42 }`; `run/loop_one_line_body`). A body of several statements still separates them.

**Still refused:** `xs[0] = 5` (an index in write position needs assignment-target grammar —
decision 37); `val r = 1..9;` outside `for` or an index. `1...9` is the inclusive pattern range
(decision 36).

The forms written in documents that still fail, and their owners, are in
[`surface-gaps.md`](./surface-gaps.md).

## Notes

- Decided: 14 (the seven forms), 28 (module-level `var` and `??` parse), 29 (a block-shaped statement
  ends itself), 30 (the index expression), 31 (`any` is deleted — C-18), 32 (no `Option` value names),
  33 (a bodyless fn declares its return type), 36 (`...` is the inclusive pattern range), 37 (an index
  in write position is a question, not a gap), 132 (when the `;` after `}` is refused).
- A new form needs a printer arm in [`16-formatter`](../16-formatter/README.md), or `botopink format`
  drops it.

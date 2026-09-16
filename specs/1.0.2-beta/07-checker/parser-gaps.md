# Parser gaps — the rows that are grammar changes, not checker changes

Five grammar gaps. Four of them own **seven of the nine** `assertComptimeCompileError` documented
skips — `comptime/tests/variants.zig` (4: three `as`-pattern, one nested/unnamed payload) and
`comptime/tests/narrowing.zig` (3: two `assert … is`, one `&&`) — plus the two
`codegen/tests/narrowing.zig` skips (`assert_pattern` l.83, `and_condition` l.144). The fifth (`_`
as an `if` binder) owns no skip; it is named by [`narrowing.md`](./narrowing.md) step B6. The
remaining two comptime skips are the helper's own definition and the C4 `comptime <RecordCtor>`
rejection, which stays.

**No checker row can close any of these.** A stricter `infer.zig` does not make `if (a && b)`
parse. Two of the five carry a recommendation to delete the tests instead of implementing the
grammar, because the implementation crosses all four backends — code this front does not own.

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/` unless stated
otherwise. Line numbers are at `botopink-lang` HEAD; re-locate by the quoted symbol.

## Summary

| Gap | Site | Grammar change | Closes | Blast radius |
|---|---|---|---|---|
| `if (a \|\| b)` / `if (a && b)` | `parser/exprs.zig` l.136 — `parseBinaryExpr(alloc, prec.equality)` | `prec.lowest` at l.136 only | `comptime/tests/narrowing.zig:285`, `codegen/tests/narrowing.zig:144`, and `libs/std/src/reflect.bp` (see [`types-as-values.md`](./types-as-values.md)) | **few** — parser snapshots for `if` |
| `_` as an `if` binder | `parser/exprs.zig` l.145 — `this.check(.identifier) and this.peekAt(1).kind == .rightArrow` | also accept `.underscore` and set `binding = null` | the `if (x) { _ -> … }` form named in [`narrowing.md`](./narrowing.md) step B6 | **none** |
| `<Pattern> as <name>` | `parser/patterns.zig` `parseSimplePattern` l.160-262 (and `parsePattern` l.140-157) | `Pattern` gains a `.bound` variant | `comptime/tests/variants.zig:291`, `:309`, `:328` | **many** — a new AST node crosses every backend. **Recommend: delete the tests** |
| Unnamed variant payload + nested constructor patterns | declaration `parser/decls.zig` l.1167-1178; pattern `parser/patterns.zig` l.230-246 | declaration: optional field names; pattern: one recursive `[]Pattern` payload | `comptime/tests/variants.zig:343` | **many** (declaration) / **few** (pattern). **Recommend: implement the pattern half, drop the declaration half** |
| `assert <expr> is <Pattern>` | no production; `parser/exprs.zig` implements only `assert <Pattern> = <expr> catch <handler>` | a new statement form that binds into the enclosing scope | `comptime/tests/narrowing.zig:213`, `:230`, `codegen/tests/narrowing.zig:83` | **few** parser + **new** checker work. Depends on C8 |

---

## `if (a || b)` / `if (a && b)`

| | |
|---|---|
| **Site** | `parser/exprs.zig` l.136 — `const cond = try this.parseBinaryExpr(alloc, prec.equality);`. `prec.equality = 2` is documented at `parser.zig` l.1137-1139 as "the entry point for operand positions where `\|\|`/`&&` are not accepted (if-conditions, yields, ranges, assignments…)" — so the restriction on `if` conditions is written down, not accidental |
| **Grammar change** | `prec.lowest` at l.136 only |
| **Why that is safe** | The condition is parenthesised by the grammar — `consume(.leftParenthesis)` l.135, `consume(.rightParenthesis)` l.138 — so there is no ambiguity for the lower precedence to protect against. Verified at HEAD: `if ((a && b))` already parses and checks |
| **Closes** | `comptime/tests/narrowing.zig:285`, `codegen/tests/narrowing.zig:144`, and defect (2) of `libs/std/src/reflect.bp` |
| **Blast radius** | **few** — parser snapshots for `if` |
| **Not by itself enough** | Once it parses, `b && b.weight > 10` on `?Box` still reds: `inferBinaryOpExpr` narrows the optional LHS (l.5348-5359), then l.5374-5375 unifies the LHS with `bool` operand-first. That half is C3, in the last landing group ([`groups.md`](./groups.md#g4--diagnostics-why-it-lands-last)) |

### What is not safe to widen

The other `prec.equality` call sites are **not** delimited the way the `if` condition is and must
stay. The source analysis lists them as "the other four … (l.208, 254, 319, 330, 1643)" — five
line numbers under the word "four" — and the README's acceptance says "the other five". Re-counted
at HEAD with `grep -n 'prec.equality' parser/*.zig`, there are **eleven** other call sites:

| Site | Position | Delimited? | Change |
|---|---|---|---|
| `parser/exprs.zig` l.208 | `comptime <expr>` (the non-block form) | no | stays |
| `parser/exprs.zig` l.254 | the value after `yield [:label]` | no | stays |
| `parser/exprs.zig` l.319 | `ident.field = <expr>` | no | stays |
| `parser/exprs.zig` l.330 | `ident.field += <expr>` | no | stays |
| `parser/exprs.zig` l.1634 | range start in `parseRangeExpr` (missing from the source's list) | no | stays |
| `parser/exprs.zig` l.1643 | range end in `parseRangeExpr` | no | stays |
| `parser/decls.zig` l.812 | a parameter default | no | stays |
| `parser/decls.zig` l.1176 | an enum variant field default | no | stays |
| `parser/decls.zig` l.1350 | a field/parameter default | no | stays |
| `parser/patterns.zig` l.34 | a single parenthesised `case (<expr>)` subject | **yes** — `(` … `consume(.rightParenthesis)` | not analysed by the source; delimited like `if`, so the same widening would be safe, but no fixture or skip needs it — leave unchanged in this step and record it if widened |
| `parser/patterns.zig` l.40 | comma-separated `case a, b` subjects | no | stays |

**Acceptance:** `if (a && b)` and `if (a || b)` parse; every other `prec.equality` call site in the
table above is unchanged.

## `_` as an `if` binder

| | |
|---|---|
| **Site** | `parser/exprs.zig` l.145 — inside the `{` of an `if` then-branch, a binder is recognised only by `this.check(.identifier) and this.peekAt(1).kind == .rightArrow`; `_` is lexed as `.underscore`, so `if (x) { _ -> … }` does not parse |
| **Grammar change** | Also accept `.underscore` followed by `.rightArrow`, and set `binding = null`. The branch is still the null-check form — it just discards the value |
| **Why that is safe** | `_` is already a token (`lexer/token.zig` l.113 `underscore`); the same two-token lookahead (`_` then `->`) distinguishes a binder from a statement, and `binding = null` is the value the no-binder form produces today, so no AST change follows |
| **Closes** | the `if (x) { _ -> … }` form named in [`narrowing.md`](./narrowing.md) step B6 (no documented skip) |
| **Blast radius** | **none** |

**Acceptance:** `if (x) { _ -> … }` parses with `binding = null`.

## `<Pattern> as <name>`

| | |
|---|---|
| **Site** | `parser/patterns.zig` `parseSimplePattern` l.160-262 (and `parsePattern` l.140-157). The `as` keyword already exists in the lexer (`lexer.zig` l.695) |
| **Grammar change** | `Pattern` gains a `.bound = { pattern: *Pattern, name: []const u8 }` variant; `parsePattern` wraps its result when it sees `.as` |
| **What it drags in** | **Every** pattern consumer must handle the new variant: `infer.zig` `bindPatternNamesForSubject`, `patternIsCatchAll` (l.4926), `collectFullyCoveredVariants` (l.4962), `alreadyCoveredVariant` (l.4989), **and the pattern lowering in all four backends** |
| **Closes** | `comptime/tests/variants.zig:291`, `:309`, `:328` (one of them is also counted among C11's 5 record-update fixtures) |
| **Blast radius** | **many** — a new AST node crosses every backend |

### What is safe and what is not

The parser half is local and safe. The consumer half is not: the backend lowerings live in
`codegen/**`, owned by [`04-beam`](../04-beam/README.md), [`05-erlang`](../05-erlang/README.md),
[`06-wasm`](../06-wasm/README.md) and [`08-js-bridges`](../08-js-bridges/README.md). Landing the
parser half alone leaves a pattern the checker accepts and a backend cannot lower.

**Recommendation: delete the three tests and record the decision here.** It is the most expensive
of the gaps and the least valuable — no library uses the form. **Open question**, to be answered
before step 6 closes: implement or delete.

**Acceptance:** either `.bound` is implemented in the parser, the checker and all four backends
(coordinated with their fronts), or the three tests are deleted and the decision is recorded in
this section.

## Unnamed variant payload + nested constructor patterns

Two gaps under one skip (`comptime/tests/variants.zig:343`), with different costs.

| | Declaration half | Pattern half |
|---|---|---|
| **Site** | `parser/decls.zig` l.1167-1178 requires `identifier` `:` `TypeRef` per payload field | `parser/patterns.zig` l.230-246 — the `.fields` payload consumes bare identifiers (`consume(.identifier)` l.236), so `Single(Ok(v))` parses `Ok` as a binder and then chokes on `(` |
| **Grammar change** | `EnumVariantField.name` becomes optional with positional fallback names | merge `.fields` and `.literals` into one `[]Pattern` payload so `parseSimplePattern` recurses |
| **What it drags in** | every backend's variant lowering, and the `TypeInfo`/`EnumVariant` surface (`comptime.zig` `type_info_src`) — see [`types-as-values.md`](./types-as-values.md) | C8's `bindPatternNamesForSubject` already has to recurse with the payload field's type (`.literals` recursion at l.4874 today passes a *fresh* subject type) — the recursion is the same work |
| **Blast radius** | **many** | **few** |
| **Safe?** | no — crosses all four backends (not owned here) and a reflected surface | yes — parser plus the C8 recursion, both in this front |

**Recommendation: implement the pattern half** (nested constructor patterns are genuinely useful
and C8 needs the recursion anyway) **and drop the unnamed-payload half** — named payloads
(`name: Type`) are the language's convention. **Open question:** confirm, then delete the
declaration half of `comptime/tests/variants.zig:343` and keep the nested-pattern half.

**Acceptance:** `Single(Ok(v))` parses and binds `v` to the inner payload type (after C8); the
unnamed-payload half is either implemented or its test deleted, with the decision recorded here.

## `assert <expr> is <Pattern>`

| | |
|---|---|
| **Site** | No production exists. `parser/exprs.zig` implements only `assert <Pattern> = <expr> catch <handler>` (the `.assertPattern` node, consumed at `infer.zig` l.7544) |
| **Grammar change** | A new statement form that binds the pattern's names into the **enclosing** scope for the rest of the block — unlike `case`, which scopes them to an arm |
| **What it drags in** | a scope-extending binding site in `inferStmtsTyped`, plus C8 to type what it binds. Without C8 the bound names are fresh vars and the fixture asserts nothing — the same vacuity [`narrowing.md`](./narrowing.md) describes |
| **Closes** | `comptime/tests/narrowing.zig:213`, `:230`, `codegen/tests/narrowing.zig:83` |
| **Blast radius** | **few** parser + **new** checker work. Depends on C8 |

### What is safe and what is not

The parser production is local (`is` is already a token, `.@"is"`, used by the type-guard form at
`parser/decls.zig` l.351-353), but it is not free: `assert <Pattern> = …` and `assert <expr> is …`
both start with text that parses as a pattern *and* as an expression, so the parser needs
backtracking or a lookahead to the `=` / `is` to choose. The checker half is not
independent — it must land after C8 (G1 in [`groups.md`](./groups.md)). The codegen skip
(`codegen/tests/narrowing.zig:83`) additionally needs each backend to lower a scope-extending
binding, which is backend work.

**Acceptance:** with `enum E { A(v: i32), B }`, `assert e is A(v); val y: i32 = v;` checks and
`val s: string = v;` reds (after C8); or the three tests are deleted and the decision recorded
here.

---

## Grammar edits this front makes outside the five gaps

Recorded so a worker does not mistake them for scope creep:

| Edit | Site | Why here |
|---|---|---|
| C5 — a narrowed-type slot on `FnDecl` | `parser/decls.zig` l.349-357 sets `typeGuardParam = x` **and** `returnType = T`; `FnDecl` gains `typeGuardType: ?ast.TypeRef` and `returnType` becomes `bool` | an AST change, not a grammar change — the surface syntax `-> x is T` is unchanged. See [`rows.md`](./rows.md#c5--a-type-guard-fn-is-typed-as-the-narrowed-type-not-bool) |
| A2 — a call in TypeRef position | `val z: mk() = 1;` is a parse error today | needed by `#[@code]` (`val p: Point() = Point()(x: 1, y: 2)`); see [`types-as-values.md`](./types-as-values.md) |

## Ordering and parallelism

- The `parser/exprs.zig` half — `&&`/`||` and `_` — is independent of every checker row and of
  types-as-values; it can land at any time, including beside Part 0.
- `assert x is P` and the pattern half of nested payloads land after C8.
- `<Pattern> as name` and the declaration half of unnamed payloads, if implemented rather than
  deleted, need the four backend fronts and are therefore not this front's to finish alone.

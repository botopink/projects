# The seven forms of decision 14, reproduced

[Decision 14](../../../1.0.5-beta/decisions-taken.md#14-seven-forms-that-do-not-parse) settles the seven spellings
[front 17 of 1.0.4-beta](../../../1.0.4-beta/17-language-test-expansion/README.md#cells-not-written)
found while writing cells: four are made to parse, three are recorded as deliberately absent.

This file reproduces each one at `botopink-lang` `c2dd780` and names the deciding line. Every probe
was run through `botopink check` on a scratch project whose only source is `src/main.bp`; the
compiler was built in a scratch worktree, never in `repository/botopink-lang` and never in `.tasks/`.

**The reproduction changes the count.** Two of the seven are the *same* grammar production, one is
not a missing form at all, and one of the four is one member of a family of three. What the seven
actually are, measured, is in [What the seven really are](#what-the-seven-really-are) at the end.

---

## The uniform diagnostic

All seven produce the same thing:

```
error: Unexpected token
 --> src/main.bp:<L>:<C>
  |
L | <the line>
  | ^ Unexpected token
  |
  = hint: Check the syntax around this position.
```

`ParseErrorType` has **48** variants (`src/parser.zig:61-158`) and `print.zig`'s `errorMessages`
renders a located, form-specific message for 47 of them. `unexpectedToken` is the 48th — the
catch-all — and it is what the whole of this file hits. It is set at eleven sites plus one fallback:
`parser.zig:345-347` fills it from `this.peek()` when `parseDecls` returns `UnexpectedToken` with no
`parseError` recorded, which is every expression-level failure.

A reader who writes one of these forms is told the position and nothing else. **Whether a form is
absent by decision or missing by defect, the compiler says the same sentence** — which is why
seven of them were found by accident rather than filed.

---

## 1 — `adder(3)(4)`: calling the result of a call

**Decision 14: made to parse.**

```botopink
fn adder(n: i32) -> fn(x: i32) -> i32 { return { x -> x + n }; }
fn main() -> i32 { return adder(3)(4); }
```

```
error: Unexpected token
 --> src/main.bp:2:35
  |
2 | fn main() -> i32 { return adder(3)(4); }
  |                                   ^ Unexpected token
```

The caret is on the second `(`. `tests/language/test/closure_capture.bp:5-6` carries the workaround
in its header comment and binds `val f = adder(3);` before calling `f(4)`.

**Deciding line.** `parsePostfixChain` (`src/parser/exprs.zig:845-877`) loops on `.dot` and
`.questionDot` only:

```zig
while (this.check(.dot) or this.check(.questionDot)) {
```

A `(` after a completed call is not a link, so the chain ends and the enclosing expression parser
meets a token it cannot place. **Change:** a `.leftParenthesis` arm in the same loop that builds a
call whose callee is the chain so far. The AST already carries a callee expression — `makeCall` takes
a receiver pointer — so this is a parser change with no AST change.

## 2 and 3 — `(sql """ab""").length` and `(a == b).toString()`: a method on a parenthesised expression

**Decision 14: these are the front's reading of "the two that decision 8 already implies" — see
[the open assignment](#the-assignment-decision-14-leaves-open).**

Front 17 reported them as two separate shapes. They are one production, and it fails on **any**
parenthesised expression, with no template and no comparison involved:

```botopink
fn main() -> i32 { return ("ab").length; }
```

```
error: Unexpected token
 --> src/main.bp:1:33
  |
1 | fn main() -> i32 { return ("ab").length; }
  |                                 ^ Unexpected token
```

The two reported spellings fail identically, at the `.`:

| Probe | Caret |
|---|---|
| `println((a == b).toString());` | `1:51`, on the `.` |
| `val s = (a == b).toString();` | `1:53`, on the `.` |

**Deciding line.** `parsePrimary`'s grouped-expression arm, `src/parser/exprs.zig:1221-1227`:

```zig
if (this.check(.leftParenthesis)) {
    const parenTok = this.advance();
    const inner = try this.parseExpr(alloc);
    _ = try this.consume(.rightParenthesis);
    const innerPtr = try this.boxExpr(alloc, inner);
    return Expr{ .collection = .{ .loc = locFromToken(parenTok), .kind = .{ .grouped = innerPtr } } };
}
```

It `return`s. Every other literal receiver in the same function hands its result to
`parsePostfixChain` first — the array literal at `:1216-1218`, and the arms at `:1022`, `:1046`,
`:1052`, `:1058`, `:1206`, `:1213`. The grouped arm is the one that does not, and the comment above
`parsePostfixChain` (`:838-843`) states the intent it breaks: "so a literal receiver chains the same
way an identifier does".

**Change:** `return parsePostfixChain(this, alloc, <the grouped expr>);`. One line, one arm, and it
closes both reported spellings and every other receiver a reader might parenthesise.

## 4 — `#(a: i32, b: string)[]`: an array of labeled tuples

**Decision 14: made to parse.**

```botopink
fn main(rows: #(a: i32, b: string)[]) -> i32 { return rows.length; }
```

```
error: Unexpected token
 --> src/main.bp:1:35
  |
1 | fn main(rows: #(a: i32, b: string)[]) -> i32 { return rows.length; }
  |                                   ^ Unexpected token
```

The caret is on the `[`. The unlabeled form fails the same way (`#(i32, string)[]`, caret `1:23`) —
the labels are not what breaks it.

**Deciding line — and this is a family, not a form.** `parseBaseTypeRef`
(`src/parser/types.zig:73-301`) applies the `T[]` wrap in a loop at the **end** of its named-type
path (`:293-300`), and three earlier arms `return` before reaching it:

| Arm | Line | Probe | Result |
|---|---|---|---|
| tuple `#(…)` | `types.zig:131-136` | `#(a: i32, b: string)[]` | **does not parse** |
| builtin generic `@Name<…>` | `types.zig:230` | `@Result<i32, string>[]` | **does not parse** |
| `unknown` | `types.zig:88-95` | `unknown[]` | parses — the arm carries its **own copy** of the wrap loop |
| named / user generic | `types.zig:293-300` | `Box<i32>[]`, `i32[][]`, `?i32[]`, `fn(x: i32) -> i32[]` | parse |

So `unknown` works because the loop was duplicated into its arm; the tuple and builtin-generic arms
were not given a copy. **Change:** hoist the wrap loop to a single exit path of `parseBaseTypeRef`
and delete the duplicate at `:88-95`. That closes `#(…)[]`, `@Result<…>[]` and any arm added later,
which is the difference between fixing a form and fixing the reason forms keep going missing.

A fourth member of the family has no arm at all and is **written by decision 8** — see
[`surface-gaps.md`](./surface-gaps.md): `(i32 | string)[]`, `decision-8-language.md:141`.

## 5 — `??`

**Decision 14: deliberately absent.**

```botopink
fn main(a: ?i32) -> i32 { return a ?? 0; }
```

```
error: Unexpected token
 --> src/main.bp:1:36
  |
1 | fn main(a: ?i32) -> i32 { return a ?? 0; }
  |                                    ^ Unexpected token
```

**Deciding line.** `src/lexer.zig:133-140` — `?` produces `.questionDot` when followed by `.`, and
`.questionMark` otherwise. There is no two-character `??` token, so the second `?` starts a new
token the expression parser cannot place. Recording the form as absent costs nothing in the lexer;
it costs a **diagnostic**: a reader who writes `??` should be told `?.` and `catch`, not "Unexpected
token" — see step 3 of the [README](./README.md).

## 6 — `var` at module level

**Decision 28: it parses** (C-05). The cost is per backend — commonJS a module `let`, wasm a
mutable global, and erlang and beam the process dictionary, since neither has module-level mutable
storage.

```botopink
var counter = 0;
fn main() -> i32 { return counter; }
```

```
error: Unexpected token
 --> src/main.bp:1:1
  |
1 | var counter = 0;
  | ^^^ Unexpected token
```

**Deciding line.** `parseDecls` (`src/parser.zig:374-470`) dispatches on the leading token; its
binding arm is `this.checkShorthand(.val)` at `:441`. There is no `.@"var"` arm, so `var` falls
through every arm to the final `else` and takes the generic error. The arm is C-05's.

## 7 — a bare `if` that is not the last statement of its block

**Decision 14: this is the one candidate left for "the remaining form" recorded as absent — and the
reproduction says the form is not absent.**

Front 17 reported it as "a bare `if` inside a decorator body must be the last statement", and
`tests/language/test/decorator_emit.bp:6-7` writes that in its header. Measured, it is neither about
`if` nor about decorator bodies.

**It fails in any block:**

```botopink
fn f(a: i32) -> i32 {
    if (a > 0) { println("pos"); }
    return a;
}
```

```
error: Unexpected token
 --> src/main.bp:3:5
  |
3 |     return a;
  |     ^^^^^^ Unexpected token
```

**It fails for `loop` and `case` too**, at the same place:

| Probe | Caret |
|---|---|
| `loop ([1,2,3]) { x -> acc = acc + x; }` then `return acc;` | `4:5`, on `return` |
| `case s { .Circle { … } .Square { … } }` then `return 1;` | `4:5`, on `return` |

**And it parses with a `;`:**

```botopink
fn f(a: i32) -> i32 {
    if (a > 0) { println("pos"); };
    return a;
}
```

```
   Checked in 62.96ms
```

The decorator body front 17 routed around parses unchanged once the `if` takes a semicolon.

**Deciding line.** `parseBlock` (`src/parser.zig:698-720`) parses every statement as an expression
and then applies `SemicolonPolicy`. `parseStmtListInBraces` — fn bodies, test bodies, `if` branches,
`case` arms, lambda bodies — uses `.requiredExceptLast` (`:741-747`):

```zig
.requiredExceptLast => if (!this.match(.semicolon) and !this.check(.rightBrace))
    return ParseError.UnexpectedToken,
```

`if`, `loop` and `case` are expressions in this grammar, so a block-shaped statement terminates with
`;` like any other. **That is a language decision, not a gap**: either a block-shaped statement
terminates itself (as in Rust, Zig, C) or it does not, and today it does not. The question the front
puts to the maintainer is which, and the cost is measured in the [README](./README.md)'s step 2.

---

## What the seven really are

| Front 17's row | Reproduces as | Count |
|---|---|---|
| `adder(3)(4)` | itself — one missing arm in `parsePostfixChain` | 1 form |
| `(sql """ab""").length` | `(expr).method` — one missing call in the grouped arm | ⎱ 1 form, |
| `(a == b).toString()` | the same production, same line | ⎰ not 2 |
| `#(a: i32, b: string)[]` | one member of a **family of four**: `#(…)[]`, `@Result<…>[]`, `(A \| B)[]` (written by decision 8), and `unknown[]` which works only because the loop was copied | 1 of 4 |
| `??` | itself | 1 form |
| module-level `var` | itself | 1 form |
| bare `if` not last | **not a missing form** — `if`, `loop` and `case` all take a `;` as statements, and the spelling with `;` parses | 0 forms, 1 decision |

**Six forms, not seven**; two of decision 14's four are the same production; and the third absent
form is not absent.

## The assignment decision 14 leaves open

Decision 14 names two of the four to be made to parse (`adder(3)(4)`, `#(a: i32)[]`) and two of the
three to be recorded absent (`??`, module-level `var`). The other two of the four are "the two that
decision 8 already implies", and the third absent form is "the remaining form" — neither is named.

**The front's proposal**, with the evidence above:

| Slot | Proposed | Why |
|---|---|---|
| the two decision 8 implies | `(sql """ab""").length` and `(a == b).toString()` | they are the only pair left, they are one production, and decision 8 §3.1 writes the same "parenthesise, then suffix" shape at the type level (`(i32 \| string)[]`, `decision-8-language.md:141`), while §3.3 reads `.length` off a narrowed value (`:178`) |
| the third absent form | **none** | the only candidate left is the bare `if`, and it parses with a `;`. The slot is empty; what is left is the separate question of whether a block-shaped statement terminates itself |

`toString` appears **zero** times in `decision-8-language.md`, so the pairing above is inference from
what is left, not a quotation. It is written here as a proposal because decision 14's wording does
not settle it, and the front must not settle it alone.

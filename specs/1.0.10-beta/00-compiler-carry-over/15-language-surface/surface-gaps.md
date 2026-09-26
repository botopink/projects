# The written surface against the parser

Every concrete spelling the project's documents and sources write, probed with `botopink check` on a
scratch project. A form "parses" when the diagnostic is not a parse error; it "checks" when `check`
exits 0. What the parser does with each decided-against form is [`README.md`](./README.md)
§ *What holds*.

## Written and refused — the refusal is the answer

| Form | Answer |
|---|---|
| `x ?? 0` | **parses** (decision 28) |
| `var n = 0;` at module level | **parses** (decision 28, C-05) |
| a bare `if`, `loop` or `case` with no `;` before the next statement | parses: the `;` after a braced block is optional (C-13, decision 29). Refusing a written `;` is decision 132's — [`16-formatter`](../16-formatter/README.md) |
| `#(x: 1, y: 2)` — labeled tuple **construction** | `error[tuple-literal-label]` at the label; the form itself is [`01-checker`](../01-checker/README.md)'s §6 |
| `#[mark(-20)]` — a negative literal as a decorator argument | **parses**; the decorator receives the number |
| `[..a, 3]` / `[...a, 3]` | `error[list-spread-not-last]` / `error[list-spread-dot-dot-dot]`; `[1, ..a]` and `[..a]` parse |
| `implement A for P { … }` after a bodyless `type P(…)` | `error[implement-clause-for]` at the `for` |
| a standalone `extend P { … }` | `anonymous-impl-extend` at the `extend` |
| `1 << 2`, `a >> 1`, `a & b`, `a ^ b` | `error[bitwise-operator-absent]` at the operator |
| `'a'` | `error[char-literal-absent]` at the literal |
| `c ? 1 : 2` | `error[ternary-absent]` at the `?` |
| a nested `fn` inside a fn body | `error[nested-fn-decl]` at the `fn` |

## Still open, with their owner

| Form | Today | Owner |
|---|---|---|
| `Box<i32>(value: 1).get()` — explicit type arguments at a constructor call | `There must be a 'val' or 'var' to bind a variable to a value` | [`01-checker`](../01-checker/README.md) §1.3 |
| `.Circle(radius: 1)` in expression position | parses; in a typed array literal the checker answers `unbound variable ''` | [`01-checker`](../01-checker/README.md) |
| a `fn` inside an enum **section** body | `this token cannot appear here · unexpected `fn`` | [`01-checker`](../01-checker/README.md) step 4 |
| `val xs = [1, "a"]`; `[1, 2.5]` | `type mismatch` — no join of the element types | [`01-checker`](../01-checker/README.md) step 2 |
| `fn get(b: Box)` — a generic without its type arguments | accepted, no diagnostic | [`01-checker`](../01-checker/README.md) step 6 (C-15) |
| `var out = [];` / `pub val z = [];` unannotated | accepted, no warning | [`01-checker`](../01-checker/README.md) steps 1, 6 |
| `any` | accepted everywhere; decision 31 deletes it | C-18 |
| `Option.None`, `Some(1)` | `unbound variable 'Option'` — the documents are wrong: `?T` is the only spelling (decisions 2 and 32) | C-18's document corrections |
| `#[@External.Node("$stringify($0)")]` | `PrimOpStringifyUnsupported` on node; the erlang target accepts it | [`04-js`](../04-js/README.md) |

The brace-arm `case` forms (`case x { _ { 1 } }`, a binding arm, a type arm, a guard), the qualified
and leading-dot variant patterns' exhaustiveness, `x is i32` as a value, assignment into a union,
`unknown`, `first<string>([])` and a parameter default all check today; whether they type and lower
correctly on every backend is [`01-checker`](../01-checker/README.md)'s. `loop { break 1; }` is
refused (`break-value-outside-generator`, decision 105).

`docs.md`'s "Decided, not yet implemented" rows that the compiler already satisfies are
[`08-hygiene`](../08-hygiene/README.md)'s to correct.

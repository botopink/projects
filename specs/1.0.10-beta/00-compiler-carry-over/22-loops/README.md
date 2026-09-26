# Front 22 — loops: `loop` · `while` · `for`, and the loop that is an iterator

**Track:** compiler (carry-over item **C-30**)
**State:** closed. Decision 105 is in the language on commonJS, erlang, beam and wasm, and the
libraries are swept (no `loop (` left in rakun, jhonstart or erika). The generator loop is now
written with the `iter` / `stream` prefix of decision 125, landed by
[`24-effects-by-return`](../24-effects-by-return/README.md), which owns the prefixed loop
(`GenLoop`) and its typing. Nothing is open.
**Owns (still):** the loop forms in `parser/exprs.zig` (`while` / `for` / `for await` / `loop { }`,
labels, the `removed-loop-parenthesised` refusal) · `comptime/infer.zig`'s loop typing (statements
are `void`; the generator scope; `yield` / `break v` gating; ranges) · the loop lowering in
`codegen/{commonJS,erlang,beam_asm,wat}.zig` · the `while` / `for` printer arms in `format.zig` (a
named carve-out of [`16-formatter`](../16-formatter/README.md)) · `docs.md` § Loops · the
`tests/language` loop cells.

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/`.

---

## The surface — [decision 105](../../decisions-taken.md#105-three-loop-keywords-and-generator-loop-is-a-generator-scope), with 122 and 125

| Form | Does | Is an expression? |
|---|---|---|
| `loop { … }` | repeats until `break` | no (`void`) |
| `while (cond) { … }` | repeats while `cond` | no (`void`) |
| `for (coll) { x -> … }` | iterates a collection · a range · an `@Iterator` | no (`void`) |
| `for await (s) { x -> … }` | iterates a `@Stream`; needs an await channel | no |
| `iter loop` / `iter while` / `iter for` | the body is an iterator: `yield` / `break v` emit | **yes** — `@Iterator<T>` |
| `stream loop` / `stream while` / `stream for` | the same, asynchronous | **yes** — `@Stream<T>` |

- **`yield v` and `break v` need a generator scope** — an `@Iterator` / `@Stream` function or an
  `iter` / `stream` loop. `yield v` emits and continues; `break v` emits and ends. Outside a
  generator scope both are refused (`yield-without-generator`, `break-value-outside-generator`);
  only bare `break` and `continue` exist there. No loop answers `[v]`; collecting in a plain `fn` is
  `xs.map(…)` / `filter(…)` or a `var`.
- **`yield` inside an unprefixed `while` / `for` / `loop` feeds the nearest generator scope**;
  `yield :label` / `break :label v` choose another. An unprefixed `loop` inside a generator scope is
  an ordinary loop: bare `break` leaves it, `yield` passes through it.
- **A prefixed loop is closed**: its body has only the iterator's / stream's capabilities, never the
  enclosing function's — inside a `@Component` function an `iter loop` may neither `use` nor `await`
  (`generator-loop-closed-scope`; `iter-await` suggests `stream`), and `break :outer` /
  `continue :outer` across its border are refused like leaving a closure. Its item becomes
  `@Result<U, E>` when the body has `throw` / `try`.
- **`for` hands over the item** (122): over `@Iterator<@Result<T, E>>` the loop variable is the
  `@Result`; the `try` is explicit. `for` over any `@Iterator` is legal in any function.
- **Ranges:** `a..b` exclusive, `a...b` inclusive (the pattern token of decision 53). `start..end` is
  an AST node, not a value: no `Range`, no `.rev()`; counting down is a `while` or `xs.reverse()`.
- **Parentheses stay** (`while (cond) {`, `for (xs) {`): without them `while x {` cannot tell a body
  from a record literal or a block-with-parameter. The `for` parameter is `{ x -> … }`.
- **Refused by name:** `loop (xs) { … }` / `loop (cond) { … }` (`removed-loop-parenthesised`, naming
  `for` and `while`); a `for` over a condition (`for-over-condition`); `loop await` (removed).
- **Labels** on the three forms and on the prefixed loops: `for :outer (xs) { … }`,
  `iter loop :l { … yield :l x … }` — the label sits where decision 105 writes it.
- The one form decision 105 does not add is a `for` with an index; `for (0..xs.length) { i -> }` is
  the spelling.

```botopink
fn main() {
    var contador = 0;
    val dobros = iter loop {
        contador += 1;
        if (contador == 10) { break contador * 2; };   // last item: 20
        yield contador * 2;                             // 2 4 6 … 18
    };
    for (dobros) { d -> @println("Dobro: ${d}"); };
}

fn firstPair(xs: i32[], ys: i32[]) -> ?#(i32, i32) {
    for :outer (xs) { x ->
        for (ys) { y ->
            if (x + y == 10) { break :outer; };
        };
    };
    return null;
}
```

**Lowering.** Every loop is a statement. A prefixed loop is a `function*` / `async function*` IIFE
on commonJS and an eager list elsewhere: erlang keeps the items under a `make_ref()` key in the
process dictionary, so a `yield` reaches the nearest scope from any fun; beam keeps a y-slot
accumulator in the frame; wasm an array inside `(block $__gen<n>)`. `break v` ends the scope from any
depth. The `dobros` example prints `2 4 … 18 20` on all four.

## Cells

`run/loop_*.bp`, `run/loop_generator_dobros.bp`, `run/loop_range_inclusive.bp`,
`run/prefixed_loop_{forms,break_value,nearest_scope,result_item}.bp`, `run/generator_levels.bp`,
`test/loop_{break,collection,condition,range,generator,generator_expr,yield_nearest_scope}.bp`;
`reject/loop_{parenthesised,condition_parenthesised,condition_parameter,yield_plain_fn,break_value,await_removed}.bp`,
`reject/for_over_condition.bp`, `reject/generator_loop_{use,await,break_outer}.bp`,
`reject/prefixed_loop_break_outer.bp`, `reject/yield_label_loop.bp`, `reject/continue_outside_loop.bp`.

## Notes

- Decision 105 supersedes decisions 52 and 55 for the statement forms; decision 53 (`...` inclusive
  in a pattern) is unchanged and is what `for (a...b)` reuses.
- Width and breaking of the `while` / `for` printer arms are 16-formatter's.

# Front 22 — loops: `loop` · `while` · `for`, and the loop that is a generator

**Track:** compiler (carry-over item **C-30**)
**Priority:** high — `loop` is three statements under one keyword (collection, condition, infinite),
`break v` makes a loop answer `[v]` and `yield` inside `loop (…)` feeds "the loop's array" rather
than the function (`docs.md:1400`, `:1014`); nobody writes those semantics on purpose, and decision
55 pinned them on four backends before anyone asked whether they were wanted. Decision 105 replaces
them with one meaning per keyword.
**Depends on:** [`21-effect-chain`](../21-effect-chain/README.md) — `@Generator<T>` /
`@ResultGenerator<T, E>` / `@FutureGenerator<T, E>` with `yield v` / `break v` as emit /
emit-and-end are the types an annotated `loop` answers, and `parseAnnotations` accepting a keyword
after `#[@` lands there first. Runs after 21, never beside it (`parser/decls.zig`, `infer.zig` and
the four codegens are shared).
**Owns:** `lexer.zig` (`while` becomes a keyword; `for` already is, `lexer.zig:733`) ·
`parser/exprs.zig` (the loop forms; `removedKeywordWhile` at `:96` deleted; the annotated `loop` as
an expression; labels on the three forms) · `comptime/infer.zig`'s loop typing (statements are
`void`; the generator scope; `yield`/`break v` gating; the level a `for` over a generator needs;
ranges) · the loop lowering in `codegen/{commonJS,erlang,beam_asm,wat}.zig` (`while` / `for` /
`for await`; the annotated `loop` desugared to a local generator; the "loop array" and `[v]`
lowerings deleted) · the `while`/`for` printer arms in `format.zig` — a named carve-out of
[`16-formatter`](../16-formatter/README.md) · `docs.md` § loops · the `tests/language` loop cells
(`run/loop_*.bp`, `test/loop_collection.bp`) and the snapshots those re-record · in
`repository/rakun` and `repository/jhonstart`: the `loop (` → `for (` / `while (` rewrite, through
`scripts/known-red-libs.txt` as in 21 step 4.
**Does not touch:** `builtins.d.bp`, `EffectKind`, `effect_chain.zig` (21) · `parseImportItem`,
`libs/std/src/**` (23) · `parser/types.zig`, `print.zig`'s `ParseErrorType` table beyond the arms
this front adds (15) · `specs/1.0.10-beta/0{3,4}-*/**` (already spelled to decision 105) · the `;`
after a block-shaped statement (C-13).

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/`. Counts measured at
compiler `feat` `4fe1747e` (2026-09-25).

---

## Problem

`loop` is the only loop (`docs.md:689`): `loop (xs) { x -> }`, `loop (0..10) { i -> }`,
`loop (cond) { }`, `loop { }`, `loop await (gen) { x -> }`, `loop :label (…)`. `while (…)` is
refused (`removedKeywordWhile`, `parser/exprs.zig:96`); `for` is a keyword the lexer produces and
nothing consumes. A `break v` makes the loop's value `[v]` (`docs.md:1400`) and a `yield` inside
`loop (…)` appends to an array the loop answers rather than to the enclosing generator
(`docs.md:1014`) — so a loop is an expression whose value depends on which statements its body
happens to contain, and `run/loop_{break_value_then_yield,yield_then_bare_break,yield_then_break_value}.bp`
pin three different answers for one construct.

## Current state

| Spelling | Count | Where |
|---|---:|---|
| `loop (` | 231 | `repository/rakun` |
| `loop (` | 12 | `repository/jhonstart` |
| `break <value>` | 2 | `repository/rakun` — each reviewed by hand, not rewritten mechanically |
| `while` | refused | `parser/exprs.zig:96` |
| `.@"continue"` | in the AST | `ast.zig:466` |
| labels | parsed | `loop :name`, `break :name [v]`, `continue :name`, `yield :name v` (`parser/exprs.zig:263-300`, `:1807`); post-return label on a generator fn (`parser/decls.zig:397`) |

The rewrite `loop (xs) { x -> }` → `for (xs) { x -> }` is mechanical — the same block-with-parameter,
one keyword changed; `loop (cond) { }` → `while (cond) { }` likewise. The two `break <value>` sites
are the ones that change meaning.

## Mechanism — [decision 105](../../decisions-taken.md#105-three-loop-keywords-and-generator-loop-is-a-generator-scope)

| Form | Does | Is an expression? |
|---|---|---|
| `loop { … }` | repeats until `break` | no (`void`) |
| `#[@generator] loop { … }` | the body is a generator: `yield`/`break v` emit | **yes** — `@Generator<T>` |
| `while (cond) { … }` | repeats while `cond` | no (`void`) |
| `for (coll) { x -> … }` | iterates a collection · a range · a generator | no (`void`) |
| `for await (gen) { x -> … }` | iterates a `@FutureGenerator` | no |

- **`yield v` and `break v` need a generator scope** — an annotated `fn` or an annotated `loop`.
  `yield v` emits and continues; `break v` emits and ends. Outside a generator scope both are refused
  naming the three annotations; only bare `break` and `continue` exist there, and `loop`/`while`/`for`
  are statements. No loop answers `[v]`; the "loop array" is gone — collecting in a plain `fn` is
  `xs.map(…)`/`filter(…)` or a `var`.
- **`yield` inside an unannotated `while`/`for`/`loop` feeds the nearest generator scope**;
  `yield :label` / `break :label v` choose another. An unannotated `loop` inside a generator scope is
  an ordinary loop: bare `break` leaves it, `yield` passes through it.
- **An annotated `loop` answers the annotation's wrapper**: `#[@generator] loop` is `@Generator<T>`,
  `#[@resultGenerator] loop` is `@ResultGenerator<T, E>`, `#[@futureGenerator] loop` is
  `@FutureGenerator<T, E>`; `T` is the type of the body's `yield`/`break v`, `E` of its `throw`. The
  body runs on demand at each `next` and captures the enclosing scope as a closure; it is **closed** —
  only the annotation's capabilities, never the enclosing fn's: inside a `#[@use] fn`, a
  `#[@generator] loop` may neither `use` nor `await` (for `await`, write `#[@futureGenerator] loop`),
  and `break :outer` / `continue :outer` across the annotated border are refused like leaving a
  closure. A `#[@resultGenerator] loop` may `try`/`throw` and a `#[@futureGenerator] loop` may
  `await` **inside the body** without the enclosing fn having that level — the error or suspension
  surfaces at the consumer, whose `for` needs the level (21 step 1).
- **Only `loop` takes the annotation.** `#[@generator] for (xs) { … }` does not exist; write
  `#[@generator] loop { for (xs) { x -> yield f(x); }; break; }`.
- **`for` over a fallible generator is an implicit `try`/`await`** and needs the body's level:
  `@Generator<T>` in any body, `@ResultGenerator` in a `try`-granting body, `@FutureGenerator` (via
  `for await`) in an `await`-granting body.
- **Ranges:** `a..b` exclusive, `a...b` inclusive (the pattern token of decision 53, `docs.md:1403`,
  gains a value here instead of the backend-divergent one). `start..end` stays an AST node, not a
  value (`builtins.d.bp:187`): no `Range`, no `.rev()`; counting down is a `while` or `xs.reverse()`.
- **Parentheses stay** (`while (cond) {`, `for (xs) {`): `if (…)` already requires them, and without
  them `while x {` cannot tell a body from a record literal `{a: 1}` or a block-with-parameter
  `{ x -> … }`. The `for` parameter is `{ x -> … }`, the block closures and today's `loop (…)`
  already use — `for (xs) { x -> }` reads "for each of xs, called x".
- **Labels** extend to `while`/`for` and to `#[@generator] loop :name` with no change of form.

```botopink
fn main() {
    var contador = 0;
    val dobros = #[@generator] loop {
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

Desugar for the annotated loop: a local parameterless `#[@generator] fn` called in place — what the
backends already emit for a generator fn; what is new is the capture of a mutable `var`, which on
erlang/beam becomes generator state.

## Steps

### Step 1 — lexer and parser

`while` a keyword; `while (cond) { … }`, `for (coll) { x -> … }`, `for await (gen) { x -> … }`,
`loop { … }` parse; `loop (…)` is refused with a located `ParseErrorType` naming `for` and `while`
(front 15's rule: a form the language decided against gets a named message); `removedKeywordWhile`
and its `errorMessages` arm deleted; `#[@generator] loop { … }` / `#[@resultGenerator] loop` /
`#[@futureGenerator] loop` parse in expression position (`parseAnnotations` accepting a keyword
name is 21's; the three generator names are identifiers); labels and `continue` on all three forms.

**Acceptance:**
- [x] each form above has a `parser/tests/` case and a `format.zig` round-trip (`assertLossless`);
      `loop (xs) { x -> }` reports the located message naming `for`
- [x] no existing parser snapshot re-records except the ones that spell `loop (…)`, each classified
      as the rename
- [x] `src/parser/AGENTS.md`, `src/lexer/AGENTS.md`, `src/format/AGENTS.md` in the same commit

### Step 2 — the checker

Statements type `void`; a generator scope is an annotated fn **or** an annotated loop;
`yield`/`break v` outside one is refused naming `#[@generator]`, `#[@resultGenerator]`,
`#[@futureGenerator]`; the annotated loop types as its wrapper with `T`/`E` inferred from the body;
the closed-scope refusals (`use`/`await` in a `#[@generator] loop` inside a `#[@use] fn`;
`break :outer`/`continue :outer` across the border); `for` over a generator requires the level;
`a..b`/`a...b` in `for`; decision 52's `null` for an exhausted condition loop goes with the
expression (a `while` is `void`).

**Acceptance:**
- [x] a `reject/` cell per refusal, each naming what the message names; `test/` cells for
      `var i = #[@generator] loop { … }; for (i) { x -> … }` typed `@Generator<i32>`, for a
      `#[@futureGenerator] loop` awaiting in a plain `fn` body and consumed by a `#[@future]` body's
      `for await`, and for the nearest-scope rule with a labelled `yield :out`
- [x] `for (1..4)` and `for (1...4)` answer `1 2 3` and `1 2 3 4` on four targets

### Step 3 — the four backends

`while` / `for` / `for await` lowered on commonJS, erlang, beam and wasm; the annotated `loop`
desugared to a local generator fn with mutable-capture state on erlang/beam; the "loop array"
accumulator and the `[v]` of `break v` deleted from all four (C-06's decision-55 lowering in
`wat.zig` and its three siblings); the `KNOWN` notes in `src/codegen/tests/**` that explain the old
cells deleted with them.

**Acceptance:**
- [x] `run/loop_*.bp` and `test/loop_collection.bp::§10` re-specified to decision 105 — `break v`
      in a plain `fn` is a `reject/` cell, the generator forms are `run/` cells — and green on four
      targets by running, no `expected-failures.txt` line
- [x] a `#[@generator] loop` capturing a `var` runs on erlang and beam with the state carried across
      `next` — the `dobros` example above prints `2 4 … 18 20`
- [x] no collection form lowers under the old keyword in `codegen/**`; snapshots re-recorded and
      classified

### Step 4 — docs, cells, and the library sweep

`docs.md` § loops rewritten to the table above; `docs.md:1400` and `:1014` gone. rakun's 231 and
jhonstart's 12 `loop (` rewritten (`for` / `while`), rakun's 2 `break <value>` reviewed by hand and
rewritten to what they meant; through `known-red-libs.txt` as 21 step 4, one library per adjacent
pair of commits.

**Acceptance:** `grep -rn 'loop (' repository/rakun repository/jhonstart` returns nothing; both
libraries at their pre-sweep counts on both rows; `known-red-libs.txt` back to its header; the meta
pointers bumped.

## Gate

- [ ] `scripts/gate.sh --cold` green at every commit; `zig build test-language` green on four targets
      with the new and re-specified cells
- [x] `botopink format --check` green on the trees that are canonical, with the new keywords printed
      back
- [x] `AGENTS.md` of `src/lexer/`, `src/parser/`, `src/comptime/`, `src/codegen/`, `src/format/`,
      `tests/language/` in the same commit
- [ ] Commit on `fix/loops`; no push, no merge — landing is the maintainer's step

## Blast radius

243 library sites (mechanical), 2 by hand; the loop snapshots of four backends; C-06's three
`run/loop_*` cells, `run/loop_condition_no_break.bp` and `test/loop_collection.bp::§10`, whose
decision-52/55 answers are superseded; front 15's step-4b row (`loop (xs) { x -> f(x) };`) reads
`for` after this lands — the `;` question it raises is C-13's and does not move.

## Handoff

- **To C-06:** its decision-52/55 rows close by supersession, not by landing — the
  `expected-failures.txt` lines those cells carry go with the cells' re-specification here; decision
  53 stays C-06's.
- **To [`16-formatter`](../16-formatter/README.md):** the two printer arms land here under its
  carve-out; anything about their width or breaking is 16's.

## Notes

- Decision 105 closes `docs.md:1400` and `:1014`, and supersedes decisions 52 and 55 for the
  statement forms; decision 53 (`...` inclusive in a pattern) is unchanged and is what `for (a...b)`
  reuses.
- The one form decision 105 does not add is a `for` with an index; `for (0..xs.length) { i -> }` is
  the spelling.

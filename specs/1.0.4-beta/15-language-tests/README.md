# Front 15 — language tests (`case`, tuples, `loop`)

**Status:** **delivered** 2026-09-17 (`botopink-lang` `7dbe1ea`): 63 pass, 33 expected failures (owners 06 N19–N22/N26, 01 step 6), `zig build test-language` is gate stage 8 and a CI step. Open: the range-pattern tests move to the inclusive `1...9` with 06 N22. Created 2026-09-17 by the maintainer: a front **only for
tests written in botopink** that pin the language as
[decision 8](../08-review-backlog/decision-8-language.md) defines it — `case` and patterns (§5), tuples
and labels (§6), `loop` (§10), and what those scenarios need from `is` (§4), unions (§3), `unknown`
(§2) and printing (§7).

**Phase 2, authored 2026-09-17:** a gap analysis of the suite against the *whole* language, not only
decision 8, grounded in the compiler's own test suites, `libs/std`, `docs.md` and the five libraries.
Three documents, all measured at `botopink-lang` `1193d3c`:

| Document | What it holds |
|---|---|
| [`capability-inventory.md`](./capability-inventory.md) | every language capability that exists today, where its surface is defined, and whether `tests/language/**` pins it — plus what `docs.md` promises that nothing exercises |
| [`gap-analysis.md`](./gap-analysis.md) | the fifteen gaps, ranked by risk, each with the program that demonstrates it and its owner; ends with four items to report to the maintainer before 06 starts |
| [`example-programs.md`](./example-programs.md) | 21 concrete cells, 20 run to a measured result, each with the `expected-failures.txt` lines it needs |
| [`proposed-layout.md`](./proposed-layout.md) | area directories, two new kinds (`modules/`, `crash/`), the cell list with owners, and the amended gate |

The headline: outside `loop`, tuples and decision 8's `case`, the language has **no botopink-level
test at all** — generics, behaviors, effects, comptime, decorators, externals, modules, closures,
primitive methods and the printer are covered only by Zig unit tests and by snapshots that pin
emitted text rather than observed behaviour.

**Priority:** high — decision 8 is implemented across 12, 06 and 01 step 6; these tests are the
acceptance each of them runs against, written once, before the implementation.
**Depends on:** nothing to author. **Landing waits for [`../12-surface-cutover/`](../12-surface-cutover/README.md)**:
every test uses the 1.0.3 surface (`type`, `behavior`, `#(…)`), which parses only once 12 lands.
**Owns:** `repository/botopink-lang/tests/language/**` (new) · one `zig build test-language` step in
`build.zig` · one stage in `scripts/gate.sh` · the matching `AGENTS.md` lines
**Does not touch:** any compiler source, `libs/std/**`, `examples/**`, snapshots — a test that fails
is recorded as an expected failure owned by the front that implements it, never fixed here

---

## Problem

Decision 8 was written as prose and examples. Nothing executable says what `case x { i32 { n -> … } }`,
`#(name, pop)` or `loop (attempts < 3) { … }` must do, so each implementing front would re-derive the
semantics from the document — and 12, 06 and 01 step 6 implement different halves of the same rules.

## Layout

```
tests/language/
  botopink.json            targets: commonJS, erlang
  test/                    assert-based tests: `test "…" { … assert … }`, one scenario group per file
    case_*.bp  tuple_*.bp  loop_*.bp  is_*.bp  union_*.bp
  run/                     whole programs whose stdout is the assertion
    <name>.bp  <name>.out  (print text, §7)
  reject/                  programs that must NOT compile
    <name>.bp  <name>.expect  (the diagnostic substring and the line:col it must point at)
  expected-failures.txt    <path>[::<test name>]  <owner row>  <reason>
  run.sh                   the runner
```

- **One scenario group per file.** A parse error fails a whole module; files keep failures isolated.
- **`test/`** runs with `botopink test --target <t>` on commonJS and erlang.
- **`run/`** builds and runs each program (node for commonJS, the erlang runner for erlang) and
  compares stdout with `.out` byte for byte.
- **`reject/`** runs `botopink check` and requires exit 1, the `.expect` substring and its location.

## The runner and expected failures

`run.sh [--target commonJS|erlang]` runs the three kinds and reads `expected-failures.txt`:

| Case | Result |
|---|---|
| unlisted, passes | ok |
| unlisted, fails | **fail** |
| listed, fails | ok (expected) — printed with its owner |
| listed, passes | **fail**: "now passes — delete its line" |
| listed path that does not exist | **fail** |

Every line names an owner: a row of 06 (`06 N22`), `01 step 6`, `12 step 4`, or a registered unowned
item. The list shrinks as those fronts land; it is never used to hide a wrong test.

## Scenarios

Each bullet is at least one test; the section numbers are decision 8's.

### `case` and patterns (§5)

- Arms `Pattern { body }` and `{ n -> body }` binding the whole value; the arm's last expression is its
  value (P1, P3); arms take no `;` (P2).
- Primitive type arms on a union (`i32 { … } string { … }`) — exhaustive without `_` (§3.3, §5.4).
- Literal arms (`0`, `"a"`, `true`), inclusive range arms (`1...9` — decided 2026-09-17), `1..9` in a pattern rejected with "use `1...9`", an open end as a guard, `_` and `_ { v -> … }`.
- Variants by label and by position, `..` for the rest, `.Some(v)` / `.None` shorthand (P4, P7, P8);
  nested patterns (`Option.Some(#(a, b))`).
- The bound variable's type from the matched value (P5): `Option<string>`, a union, `unknown`.
- Tuple patterns positional only, literals inside, `..` (P6, P7).
- Guards `when (…)`, `is` narrowing inside a guard, guarded arms never counting (§5.3).
- Exhaustiveness (§5.4): enum/union/`bool` covered → no `_`; each "required" row of the table.
- A `case` whose arms have different types yields a union (§3.2).
- **reject/**: a lower-case name alone as an arm; a constant as a pattern; a label in a tuple pattern;
  a missing variant; `_` missing on `unknown`; only guarded arms; `.Some` on `unknown`; arity mismatch
  without `..`.

### Tuples and labels (§6)

- Construction `#("SP", 12)`; access `.0`; nested tuples; tuples in arrays; equality.
- Labels lent by construction variables (`#(name, pop)` → `row.name`) (T1).
- Labeled written types on parameters, returns and annotations (T2, T3); `row.label` works across a
  function boundary through a labeled type.
- Type comparison ignoring labels (T5): `#(city: string, pop: i32)` accepts `#(name: string, pop: i32)`.
- Run time positional (T6): a labeled and an unlabeled tuple with the same elements are `==`.
- `zip` producing `#(T, U)`; destructuring `val #(a, b) = …`.
- **run/**: printing `#(1, "a")`, a tuple nested in an array, labels never printed (§7).
- **reject/**: `row.label` on an unlabeled written type (`use .N`); a label that does not exist.

### `loop` (§10)

- `loop (xs) { x -> … }` over an array and over a generator; the empty collection.
- `loop (0..n) { i -> … }`; `loop (xs, 1..) { x, i -> … }` (index start honoured).
- `loop (condition) { … }` repeating while true, including a condition false on entry.
- `loop { … break; }`; `break` with a value (loop as an expression).
- Outer `var` reassigned inside each form survives the loop (the closure/loop threading rows).
- Nested loops; `break` out of the inner one only.
- **reject/**: `while (…)` (`use loop (condition)`); a parameter on a condition loop.

### What these scenarios need from §2–§4

Only as far as `case`, tuples and loops use them: `x is i32` by value (`2.0 is i32`), narrowing inside
`if`, a union from branches, `unknown` requiring `_`.

## Steps

### Step 1 — the runner and the gate

`tests/language/botopink.json`, `run.sh`, `expected-failures.txt` (empty), `zig build test-language`,
the `scripts/gate.sh` stage. One trivial test per kind proves the three paths and the four
expected-failure rules (a listed passing test must fail the runner).

### Step 2 — `case` and patterns

### Step 3 — tuples and labels

### Step 4 — `loop`

Each of steps 2–4: the scenarios above, run against the compiler built from `fix/surface-cutover`
(read-only — a scratch checkout of that branch's tip), every failure classified in
`expected-failures.txt` with its owner row. A failure that contradicts decision 8 rather than lagging
it is reported, not listed.

## Gate

- [ ] `zig build test-language` green on commonJS and erlang, with the compiler of `fix/surface-cutover`
- [ ] Every `expected-failures.txt` line names an owner row that exists in the specs
- [ ] Every scenario bullet above has at least one test (the test names cite the section)
- [ ] `AGENTS.md` for `tests/language/` (layout, how to add a scenario, the expected-failure rules)
- [ ] Commits on `test/language`; no push, no merge — landing is the orchestrator's step, after 12

## Notes

- Tests describe decision 8, not today's behaviour: a scenario the compiler gets wrong stays and is
  listed, never rewritten to match.
- beam and wasm are not runnable by `botopink test`; their coverage stays in the codegen snapshots
  (01 step 6 adds decision-8 fixtures there).

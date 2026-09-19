# Decisions the maintainer owes — 1.0.5-beta

**Five open — 52 to 56.** Questions 38 to 47 were answered on 2026-09-18, together with four the same
pass raised and answered (48, 49, 50, 51); all of them are in
[`decisions-taken.md`](./decisions-taken.md), which is the record the fronts implement against. The four
here were opened the same day by the fronts that landed: 52 by `02-erlang`, 53 and 54 by `08-hygiene`,
55 by `03-beam`, 56 by `10-cli-residuals`. The first four are each a form that **compiles and answers
differently per backend**, which is why none of them is a defect with an owner; 56 is a contract the
command documentation states and a fix is about to change.

Findings that sit below the level of a decision — defects with no row, not questions — recorded here
until a front claims them:

- **`src/comptime/**` has no warning channel at all** (`grep -rn warning comptime/*.zig` → 0), and
  three separate obligations want one: decision 8 §1.4, §2.4 and §4.3. It is a `warnings` list on the
  `Env`, rendered like a `TypeError`, and it unblocks all three at once.
- **An inline `implement <Behavior> { }` inside a `type` checks nothing.**
  `type Money(cents: i32) implement Display { }` passes — with a local `Display`, and with the
  long-registered `Generator`. Only the separate `implement X for Y` block is covered. No row exists.
- **`tests/language/expected-failures.txt`'s distribution paragraph runs two ahead of the file**
  (front 02, 2026-09-18): front 04's two deletions were never counted into it — `origin/feat` shows 68
  data lines under a `70 lines` header. Front 12's file; each front decrements its own lines and reports
  the drift rather than rewriting another front's number.
- **A yielding condition loop in expression position is still refused on erlang** (front 02):
  `val xs = loop (i < 3) { yield i; i = i + 1; };` gives `ConditionLoopValueUnsupported`, because it
  reaches `exprNode` rather than `mutatingExpr` and so has no variable group to join. commonJS collects
  there. No cell or fixture reaches it.
- **A stale comment in front 04's test** (front 02): `src/codegen/tests/control_flow.zig:517-525` says
  erlang "does not compile it at all (`ConditionLoopValueUnsupported`)", untrue since `a9e9d03`. It is
  04's file, so 02 left it.
- **A block-armed `case` types `void` when its subject is a function parameter** (front 08):
  `fn grade(n: i32) -> string { return case n { 90...100 { "A" } _ { "lower" } }; }` reds
  `type mismatch: expected string, got void`, while the same arms over a literal or a `val` local answer
  `A`, and the `->` arm form works with a parameter. It is the block-arm value path, i.e.
  [`01-checker`](./01-checker/README.md)'s step 4 — whose uncommitted half may already close it; verify
  before writing a row.
- **`Type.assoc()` gets no return type** (front 03): `val c = Counter.zero(); c.bump()` leaves
  `env.instanceLowerings` with no entry, so beam answers `{unresolved_method, bump, 1}` and wasm traps,
  while commonJS and erlang print `1` because neither needs the type. **Reproduces inside one module** —
  not an import row. `val c: Counter` fixes it; writing the return type as `Counter` instead of `Self`
  does not. Front 01.
- **A method on an imported `enum` is emitted as a bare local call on erlang** (front 03):
  `area({'Square',4})` while `geometry.erl` exports `area/1`, so the emitted program does not compile —
  the enum half of `7783fd6` / `1193d3c`. Front 02; pinned as `KNOWN-WRONG (erlang)` in the new fixture.
- **An imported enum's `case self` traps on wasm** (front 03) — `unreachable`, single-module, no
  named-type identity. Front 05, and the same ground as decision 22.
- **Step 5 of `08-hygiene` has no test for its diagnostic**, only for the message: nothing asserts the
  `the <template|decorator> evaluator's erl runtime failed (…): …` text, and the frame-cap failure is
  unreachable from a fixture. Front 07 (`comptime/tests/**`) or front 14 (`template_eval.zig`).
- **An associated `fn` on an `enum` is emitted as a tagged tuple named after it** (front 02, probing the
  neighbourhood of the imported-enum row): `memberCallNode`'s "qualified enum payload constructor" branch
  (`erlang.zig:5351`) fires on any `EnumName.callee(...)` without checking that `callee` names a variant,
  so `Shape.unit()` emits `{unit}` — `erlc` is clean and the program dies with
  `{case_clause,{unit}}` in `area/1`. It reproduces **inside one module** and with or without the
  `val s: Shape` annotation, so it is not an import row. commonJS with the annotation prints the right
  answer; without it, it fails differently (`Shape.unit(...).area is not a function`), which is the
  checker row `dispatch.zig` already pins. Owners: the erlang arm is front 02's or 13's depending on
  ordering, the unannotated half is 01's R6. No `expected-failures.txt` line, no `KNOWN` note and no step
  of front 02's nine covers it.
- **`main/0` is exported only when `main` is `pub`** (front 10): `main/1`, escript's entry, is always
  exported, so `examples/modules` (`fn main()`) carries just `-export(['_botopink_main'/0, main/1]).`
  while the three `tests/language/modules/*` cells (`pub fn main()`) carry both arities. A runner that
  calls `main:main()` therefore fails on the first and works on the other three. The asymmetry is in
  `erlang.zig` — front 02 / front 13 — and it is either a rule that should be written down or a bug; it
  is currently neither.
- **An attribution survived three milestones because nobody re-ran the cell** (front 10): two statements
  in `modules/compiler-cli/**` said `examples/modules` reds on erlang because "the backend emits
  cross-module calls as bare local calls", and that the erlang front would fix it. Both false — the
  emitted calls are qualified and correct, and the defect is the runner's. Corrected in `8babfa5`. The
  pattern is the finding: a `KNOWN` note with no re-run date is a claim, not a measurement.
- **Two `libs/std` headers still name 1.0.4 fronts** for gaps that now pass (front 08):
  `libs/std/test/primitives_gaps_test.bp` and `libs/std/src/primitives.bp:204` (`F5 erlang`,
  `F8 js-bridges`). `libs/std/**` beyond comments is front 01's step 11.

This file stays because the fronts will fill it again. A front that meets a question it cannot answer
from the code writes it here rather than guessing, in the shape the others used:

> **Measured.** What was observed, with the command or program that produced it and the file or commit
> that can be re-read.
>
> **Options.** Each one stated so that choosing between them is possible without reading the code.
>
> **Recommendation.** One, argued — a question with no recommendation is a question the front did not
> finish thinking about.
>
> **Blocks.** The step, front or landed work that waits on the answer.

Numbers are never reused: the next question added here is **57**.

---

## 52. What does a condition loop that never breaks answer?

**Measured** by [`02-erlang`](./02-erlang/README.md) at `f547f99f`, and newly observable — before
`a9e9d03` the program did not terminate:

```botopink
var n = 0;
val never = loop (n < 3) { n = n + 1; };
@print(never);
```

erlang prints **`3`** — the loop's variable group, which is what the new lowering answers when the
condition runs out. commonJS prints **`null`**, and front 04's landed test asserts that, citing decision
8 §10's "no value to give".

**Options.** (a) `null`/`undefined` everywhere: the loop that never breaks has no value, and erlang stops
answering its group. (b) The group is the value on every backend, and decision 8 §10 is amended. (c) The
form is refused in value position when the loop has no `break <value>`.

**Recommendation: (a).** It is the reading decision 8 §10 already has, the one front 04 implemented, and
the only one where `val x = loop …;` means the same thing on four targets. (b) makes the value depend on
which variables the loop happened to reassign; (c) is defensible but breaks programs that compile today
on commonJS.

**Blocks:** nothing today — no cell covers it. It needs one cell and erlang's spelling (`undefined`)
before [`12-language-tests`](./12-language-tests/README.md) can pin it.

---

## 53. The range spelling is reversed in the compiler, and the reversal has no owner

**Measured** by [`08-hygiene`](./08-hygiene/README.md) on 2026-09-18, by running each form.
[Decision 20](./decisions-taken.md#20-is-a-pattern-range-inclusive) and
[decision 36](./decisions-taken.md) are taken: `..` is the only spelling, it is exclusive, and `...`
leaves the grammar. The compiler does the opposite of both:

```botopink
case n { 1..9 { 1 } _ { 0 } }     // error[pattern-range-exclusive] — "write `...`"
case n { 1...9 { 1 } _ { 0 } }    // accepted, and inclusive
```

And as a value the accepted spelling answers three different things — `case 9 { 1...9 { 1 } _ { 0 } }`
prints **1** on commonJS (new; the other fronts measured `undefined` at `c2dd780`), **0** on erlang,
**256** on wasm, and beam emits only `out/main.S`.

**Options.** (a) A front owns the reversal this milestone — it is the diagnostic, the grammar and the
three value paths, so it is one row in `01-checker` plus one per backend. (b) The two decisions are
amended to what the compiler does (`...`, inclusive), which contradicts decision 36's "exclusive
everywhere" and Zig's spelling, the reason decision 20 gave. (c) It is scheduled for 1.0.6-beta with the
measurement above pinned by a cell.

**Recommendation: (c), with the cell now.** Three backends disagreeing on the *value* of an accepted
form is worse than the spelling being wrong, and a cell in `12-language-tests` makes it impossible to
land a backend change that silently moves one of the three. The spelling itself is cheap
(`01-checker` calls decision 36 "~10 lines") but it cannot land alone: flipping the diagnostic without
the value paths turns three wrong answers into three wrong answers on a form that now parses.

**Blocks:** nothing today — every front that met it (`12`, `15`, `01`) measured it and moved on, which
is why it is here.

---

## 54. What is the pattern surface of a `?T`?

**Measured** by [`08-hygiene`](./08-hygiene/README.md):

```botopink
val x: ?i32 = 5;
case x { .Some(v) { @print(v); } .None { @print("none"); } };   // compiles, prints NOTHING, exit 0
case x { Option.Some(value: v) { … } .None { … } };             // falls to `_`: prints "none"
```

So the optional has **no** working pattern form: one spelling matches nothing at all and the other
matches the wrong arm, both silently. [Decision 2](./decisions-taken.md#2-optiont-does-not-exist-either)
and [decision 32](./decisions-taken.md) removed `Option<T>` and `Option.Some` from the language, and the
`is-variant-binding` diagnostic's own hint still recommends the removed spelling
(*"use `case x { Option.Some(value: v) { … } }`"*).

**Options.** (a) `?T` is matched by `.Some(v)` / `.None` — the variant spelling the language kept — and
the arms are typed against the optional's payload. (b) `?T` is matched by `null` and a binder
(`case x { null { … } v { … } }`), which is what `??` and `?.` already do. (c) A member pattern on `?T`
is refused, and `if (x)`'s optional binding plus `??` stay the only readers — with the hint corrected.

**Recommendation: (a).** It is the form both decisions leave standing, it is what every author who read
the removed hint will write, and the payload type is already the thing `inferCaseArmBody` narrows. What
cannot stay is the present state: two spellings, both accepted, both wrong, neither diagnosed.

**Blocks:** a row of [`01-checker`](./01-checker/README.md) (its step 4/5 walk), the hint text, and any
cell `12-language-tests` writes for the optional.

---

## 55. Does `break <value>` out of a collection loop answer the value or a list?

**Measured** by [`03-beam`](./03-beam/README.md) once beam started assembling the form: `break 20` out
of `loop ([10, 20, 30]) { … }` answers **`[20]`**, not `20`, on **all four** backends.

Decision 8 §10 says a `break <value>` is the loop's value; it does not say what happens when the loop is
a collection loop whose body already accumulates. Four backends agreeing is not the same as four
backends being right — they share the accumulator shape.

**Options.** (a) `[20]`: a collection loop always answers a collection, and `break <value>` contributes
its argument as the last element. (b) `20`: `break` out of any loop answers its argument, and the
accumulator is discarded — then a value `break` and a `yield` cannot both appear in one loop. (c) The
form is refused in a collection loop, and only a condition loop takes a value `break`.

**Recommendation: (a)**, and write it into decision 8 §10 rather than leaving it to the emitters. It is
what all four do, it composes with `yield`, and it is the only reading where the *type* of a collection
loop does not depend on whether a `break` appears somewhere in its body.

**Blocks:** nothing today — no cell pins it, which is the risk. It should become a cell in
`12-language-tests` in the same pass that answers it.

---

## 56. Does `botopink run --target erlang` keep escript's exit status?

**Measured** by [`10-cli-residuals`](./10-cli-residuals/README.md) while turning its step 4 into an
implementable row. The runner runs `escript out/main.erl`, which compiles only the file it is handed, so
three `modules/*` language cells and `examples/modules` fail on erlang **with correct, qualified emitted
code**. The fix — front 13's, in `cli/run.zig` — is `erlc -o <out_dir>` over every emitted `.erl` found
recursively, then `erl -noshell -pa <out_dir> -eval "<module>:main([]), halt()."`; at that shape all four
projects print what they mean (`3`/`0`, `circle`/`7`, `1`, `12`/`circle`/`7`).

**The consequence.** A crashing erlang program's exit status changes from escript's **127** to `erl`'s
**1** (measured on a `1 / 0` program), and `modules/compiler-cli/AGENTS.md`'s command contract says `run`
exits with *"the program's own"* code.

**Options.** (a) Accept `1` and amend the contract: what a program "returns" on the BEAM is what `erl`
reports, and `127` was escript's artefact. (b) Preserve `127` by mapping `erl`'s failure exit onto it, so
the observable contract does not move. (c) Define a status per outcome — compile failure, run-time crash,
clean exit — and write all three into the contract, for every target.

**Recommendation: (a), with the line in the contract changed in the same commit.** `127` never meant
anything on purpose; it is what escript answers, and no test asserts it. (b) preserves an accident and
costs a mapping that the next person will read as meaningful. (c) is the right long-term shape but it is a
command-contract row across four targets, not a rider on a runner fix — and the right moment for it is
when someone actually needs a distinguishable status.

**Blocks:** nothing, but it should be answered **before** front 13 lands the runner fix, so the change of
status is intentional rather than discovered.


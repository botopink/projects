# Decisions the maintainer owes — 1.0.5-beta

**None open.** Every question this milestone raised — 38 to 62 — is answered and recorded in
[`decisions-taken.md`](./decisions-taken.md). What is left here is the list of defects with an owner and
no row, kept so they are not re-discovered; decision 62 says which three of them are this wave's. Questions 38 to 47 were answered on 2026-09-18, together with four the same
pass raised and answered (48, 49, 50, 51); all of them are in
[`decisions-taken.md`](./decisions-taken.md), which is the record the fronts implement against. The four
were opened the same day by the fronts that landed — 53 by `08-hygiene`, 55 by `03-beam`, 56 by
`10-cli-residuals` — and two more (52 and 54) were answered within hours of being written, so they are in
`decisions-taken.md` already. 53 and 55 are each a form that **compiles and answers differently per
backend**, which is why neither is a defect with an owner; 56 is a contract the command documentation
states and a fix is about to change, so it has a deadline: front 13 is implementing that fix now.

**53 and 55 both changed after they were opened**, and the new evidence is in their sections: Zig was
measured (it has *both* spellings, in different positions, so the compiler is the Zig-consistent side and
decisions 20/36 are not), and `yield` beside `break` in a collection loop was measured on all four
backends (four different answers, three of them order-dependent).

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
- **`libs/std` is no longer `format --check` clean** (front 16): `src/primitives.bp:549` (a braced
  single-statement `if` inside a `loop`) and `src/querystring.bp:37` (a chain that now fits one line).
  Both are canonical rules and lose no text, and **both predate front 16's commits** — verified by
  building `format.zig` at `f8d97f95` and re-running. `examples/**` and all five siblings are clean.
  `libs/std` is front 01's step 11 / front 08's.
- **The continuation line of a trailing comment re-emits at column 0** (front 16, front 09's last R1
  member): text intact, alignment lost. It needs a **recorded comment column**, not a printer arm — a
  comment reaches the AST as text with no column — and its site is `parseDecls`' top-level trailing
  comment, outside front 16's three named functions. No owner.
- **Four layout rows for front 16's step 6**, each measured against front 09's 861 changed lines: a
  lambda *argument*'s body indents 8 from the call line and its `});` lands at +4; `{ next -> }`
  explodes into three lines whose middle line is **whitespace-only**; `{ -> 3 + 4 }` explodes while
  `{ n -> n * 2 }` stays inline; and a hand-wrapped signature is joined into a **114-column** line
  against `LINE_WIDTH = 80`, because a `fn` signature has no break available.
- **Front 15's handover note is stale in one line** (front 16): it says a blank line inside an `if`
  branch does not round-trip "because `fmtBranchStmts` never reads `emptyLinesBefore`" — that function
  was deleted by `9d1d067`, and after 15's `28e447e` the then-branch, the else-branch and the `loop`
  body all round-trip. G5/G6 are closed, and `f1881b5` now asserts it.
- **beam drops `.length` on an index or slice receiver**, exit 0 (front 05, found by its second merge):
  `rows[0].length` answers `[1, 2]`, `xs[0..2].length` answers `[10, 20]`, `s[1..3].length` answers `el`
  — each meaning `2`. It is the beam twin of what front 05's `91b1553` fixed on wasm; `beam_asm.zig` is
  front 03's.
- **Two silent wrong answers left on wasm**, listed in `wat/AGENTS.md` (front 05): a string tuple element
  printed as its address — `@print(t.1)` → `256` (means `x`), `@print(row.name)` → `256` (means `SP`).
  The shape is known to `printShapeOf` and not to `isStringExpr`. Front 05's own.
- **Three wasm `expected-failures.txt` reason texts are now false** (front 05): `run/print_formatter.bp`,
  `run/display_print.bp` and `run/type_identity_print.bp` say "prints as its raw heap address"; they now
  **trap**. A line may only be deleted here, never rewritten, so the correction is front 12's.
- **Decision 47 has three backends to move** (front 05): it settled that absent has one spelling, `null`,
  and today wasm, erlang and beam print `undefined` while commonJS prints `null` — and decision 8 §7
  names neither. Also `index_an_index_past_the_end_answers_zero` answers `undefined` on three backends
  and `0` on wasm. Those are rows under 47, not new questions.
- **commonJS already answers §7's F2/F3** (front 05): a class instance carries its constructor's name, so
  `Point(x: 1, y: 2)`, `Shape.Square(side: 4)` and `Shape.Nothing` print correctly there — that backend
  needs no identity work from front 13 for the printed form; wasm, erlang and beam do.
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

Numbers are never reused: the next question added here is **63**.

---

# Decisions the maintainer owes — 1.0.5-beta

**None open.** All thirty-seven questions this milestone raised have been answered; the record the
fronts implement against is [`decisions-taken.md`](./decisions-taken.md).

Two findings from front 01 (2026-09-18) sit below the level of a decision — they are defects with no
row, not questions — and are recorded here until a front claims them:

- **`src/comptime/**` has no warning channel at all** (`grep -rn warning comptime/*.zig` → 0), and
  three separate obligations want one: decision 8 §1.4, §2.4 and §4.3. It is a `warnings` list on the
  `Env`, rendered like a `TypeError`, and it unblocks all three at once.
- **An inline `implement <Behavior> { }` inside a `type` checks nothing.**
  `type Money(cents: i32) implement Display { }` passes — with a local `Display`, and with the
  long-registered `Generator`. Only the separate `implement X for Y` block is covered. No row exists.

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

Numbers are never reused: the next question added here is **38**.

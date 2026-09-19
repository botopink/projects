# Decisions the maintainer owes — 1.0.5-beta

**Two open — 51 and 52.** Questions 38 to 47 were answered on 2026-09-18, together with three the
same pass raised and answered (48, 49, 50); all of them are in
[`decisions-taken.md`](./decisions-taken.md), which is the record the fronts implement against. What is
left open here are the two sub-questions those answers exposed: the key of a `List` under `keyed`, and
what a condition loop that never breaks answers.

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

Numbers are never reused: the next question added here is **53**.

---

## 51. `keyed = true` on a `List<T>` — is the key the index, or an element identity?

**Where it comes from.** Confirmation 1 of the maintainer's 2026-09-18 message: `List<T>` joins `Dict`
as a container that takes `keyed = true` ([decision 42](./decisions-taken.md#42-a-dict-under-ets-with-keyed-unwritten-keeps-the-default-with-no-warning)).
The `Dict` half is defined and measured; the list half is accepted and has no key.

**Measured.** The `keyed` benefit was measured on `Dict`, where the element's key *is* the user's key:
254 → 51 ns at 10 keys, 301 864 → 60 ns at 10 000 (**5 061×**), and `keyed = false` silently lost six of
40 000 writes from two processes. Nothing equivalent was measured for a list, because the row that would
be written depends on the answer below.

**Options.**

(a) **The index is the key** — `ets:insert(Tid, {{sheet, 0}, <<"x">>})`. Reads and writes of a known
position become one call each, which is the `Dict` win. But two processes appending at the same time
choose the same index, so one overwrites the other, and the list's length becomes the contended row the
`keyed` mode existed to remove. The mode would be honest only for positional update, not for append.

(b) **An element identity is the key** — `ets:insert(Tid, {{sheet, Id}, <<"x">>})`. Concurrent writes no
longer collide, but the value is no longer a list: it is a `Dict<Id, T>` with an order, and the language
would be answering `List<T>` for something with different semantics. That is a type question, not a
storage one.

(c) **`keyed` stays a `Dict`-only argument**, and a list under `Ets` keeps the blob default — the
refusal reusing decision 41's "`keyed` needs a keyed container" diagnostic.

**Recommendation: (c) unless a list workload is measured.** (a) promises atomicity it cannot give for the
operation lists are actually used for; (b) renames a type. (c) is one line and it is already the shape of
a diagnostic this milestone is writing — and it leaves (a) available later, for positional update, with
its own measurement.

**Blocks:** nothing now — the emission is deferred to after `13-module-identity`
([decision 50](./decisions-taken.md)). It blocks step 4 of
[`17-beam-memory`](./17-beam-memory/README.md) when that step opens.

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

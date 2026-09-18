# Front 15 — language tests (`case`, tuples, `loop`)

**Delivered** 2026-09-17 (`botopink-lang` `7dbe1ea`, on the tests of `de04962` … `efc7ad6`): the
harness, the layout, `expected-failures.txt` and **34 files — 31 cells plus three smoke files** —
pinning [decision 8](../08-review-backlog/decision-8-language.md)'s `case` and patterns (§5), tuples
and labels (§6), `loop` (§10), and what those scenarios need from `is` (§4), unions (§3), `unknown`
(§2) and printing (§7). At landing the suite read **63 pass, 33 expected failures** (owners 06
N19–N22/N26 and 01 step 6). `zig build test-language` is gate stage 8 and a CI step.

Created 2026-09-17 by the maintainer as a front **only for tests written in botopink**, running the
emitted program. Its **phase 2** — the gap analysis below — is the front that succeeded it
([`../17-language-test-expansion/`](../17-language-test-expansion/README.md)).

**Owned:** `repository/botopink-lang/tests/language/**` · one `zig build test-language` step in
`build.zig` · one stage in `scripts/gate.sh` · the matching `AGENTS.md` lines.
**Touched no compiler source, no `libs/std`, no `examples/`, no snapshot** — a test that fails is
recorded as an expected failure owned by the front that implements it, never fixed here.

---

## Problem

Decision 8 was written as prose and examples. Nothing executable said what
`case x { i32 { n -> … } }`, `#(name, pop)` or `loop (attempts < 3) { … }` must do, so each
implementing front would re-derive the semantics from the document — and 12, 06 and the backends
implement different halves of the same rules.

## Phase 2 — the analysis, measured at `botopink-lang` `1193d3c`

| Document | What it holds |
|---|---|
| [`capability-inventory.md`](./capability-inventory.md) | every language capability that exists today, where its surface is defined, and whether `tests/language/**` pins it — plus what `docs.md` promises that nothing exercises |
| [`gap-analysis.md`](./gap-analysis.md) | the fifteen gaps, ranked by risk, each with the program that demonstrates it and its owner |
| [`example-programs.md`](./example-programs.md) | 21 concrete cells, 20 run to a measured result, each with the `expected-failures.txt` lines it needs |
| [`proposed-layout.md`](./proposed-layout.md) | area directories, two new kinds (`modules/`, `crash/`), the cell list with owners, and the amended gate |

The headline: outside `loop`, tuples and decision 8's `case`, the language had **no botopink-level
test at all** — generics, behaviors, effects, comptime, decorators, externals, modules, closures,
primitive methods and the printer were covered only by Zig unit tests and by snapshots that pin
emitted text rather than observed behaviour. Front 17 wrote the 37 cells that answer it.

## The harness, as delivered

```
tests/language/
  botopink.json            targets: commonJS, erlang
  test/                    `test "…" { … assert … }` blocks, run by `botopink test --target <t> --json`
  run/                     `<name>.bp` + `<name>.out` — a whole program whose stdout is the assertion
  reject/                  `<name>.bp` + `<name>.expect` — a program that must not compile
  expected-failures.txt    the list of known failures, each naming an owner row
  run.sh                   the runner
```

Every cell is copied into its own scratch project, so a parse error fails only that cell. Test names
start with the decision-8 section they pin (`test "§5.4 …"`) when there is one.

`run.sh [--target commonJS|erlang]` reads `expected-failures.txt` by these rules:

| Case | Result |
|---|---|
| unlisted, passes | ok |
| unlisted, fails | **fail** |
| listed, fails | ok (expected) — printed with its owner |
| listed, passes | **fail**: "now passes — delete its line" |
| listed path that does not exist | **fail** |

Front 17 added a fourth kind, `modules/` (a whole project directory), and a third executable target,
wasm, for the `run/` and `modules/` kinds.

## Gate

- [x] `zig build test-language` green on commonJS and erlang, against the compiler of
      `fix/surface-cutover`
- [x] Every `expected-failures.txt` line names an owner row that exists in the specs
- [x] Every scenario bullet has at least one test, and the test names cite the section
- [x] `AGENTS.md` for `tests/language/` (layout, how to add a scenario, the expected-failure rules)
- [x] Landed by the maintainer after 12, as `7dbe1ea`

## What it left, and where

| Residual | Owner in 1.0.5-beta |
|---|---|
| The **range-pattern cells** were written around the edge because decision 8 did not say whether a range end is inclusive. The maintainer decided `A...B`, inclusive, Zig spelling, on 2026-09-17, and the **grammar** landed with 06's `dff3446`; the cells that assert it are listed against N22 until the checker half lands | `01-checker` N22, then `12-language-tests` deletes the lines |
| **The 33 expected-failure lines this front wrote name 1.0.4-beta rows** (`06 N19`…`N26`, `01 step 6`). Every one of them has to be re-pointed at the 1.0.5-beta front that now owns it — see the same handoff, with the full histogram, in [`../17-language-test-expansion/README.md`](../17-language-test-expansion/README.md#what-it-left-and-where) | `12-language-tests` |
| The two kinds [`proposed-layout.md`](./proposed-layout.md) proposed and front 17 did not take: **`crash/`** (a cell that aborts reports no result through `--json`) and area **sub-directories** | `12-language-tests` |

## Notes

- Tests describe decision 8, not today's behaviour: a scenario the compiler gets wrong stays and is
  listed, never rewritten to match.
- beam is not runnable: `botopink test` refuses it and `botopink run` writes `out/main.S` and stops.
  Its decision-8 coverage stays in `snapshots/codegen/beam/`.

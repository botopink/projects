# Front 22 — status

One line per landed step; the boxes are in [`README.md`](README.md).

- Step 1 (lexer and parser) — compiler `413af46b`: `while`/`for`/`loop { }` and the annotated
  `loop` parse into one `LoopExpr` (`keyword`, `generator`); `loop (…)` is
  `removed-loop-parenthesised`; `a...b` ranges; the formatter prints the three forms back;
  every fixture, cell, std site and docs fence rewritten; 120 snapshots re-recorded (106 source-only,
  8 parser column shifts, 1 `inclusive` field, 1 fixture without its index binder, 4 new).
- Step 2 (the checker) — compiler `ac77c808`: statements are `void`; the annotated `loop` is a
  closed generator scope worth its wrapper; `yield` / `break v` feed the nearest generator scope
  through every loop (annotated methods included); `for` over a generator under decision 103's
  level gate; ranges typed; ten `reject/` cells; the decision-52/55 cells and their
  `expected-failures.txt` block deleted; every fixture that made a loop a value re-specified. The
  `test/` cells that consume an annotated loop, and `for (1...4)` on four targets, land with the
  backends (step 3) — their boxes stay open until then.

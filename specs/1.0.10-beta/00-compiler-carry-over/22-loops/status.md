# Front 22 — status

One line per landed step; the boxes are in [`README.md`](README.md).

- Step 1 (lexer and parser) — compiler `413af46b`: `while`/`for`/`loop { }` and the annotated
  `loop` parse into one `LoopExpr` (`keyword`, `generator`); `loop (…)` is
  `removed-loop-parenthesised`; `a...b` ranges; the formatter prints the three forms back;
  every fixture, cell, std site and docs fence rewritten; 120 snapshots re-recorded (106 source-only,
  8 parser column shifts, 1 `inclusive` field, 1 fixture without its index binder, 4 new).

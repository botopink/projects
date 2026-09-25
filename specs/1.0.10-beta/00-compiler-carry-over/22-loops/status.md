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
- Step 3 (the four backends) — compiler `75b2311c` commonJS, `4f83aa6b` erlang, `e7e2f36d` beam,
  `d6c335be` wasm: every loop is a statement; `#[@generator] loop` is a `function*` IIFE on
  commonJS and an eager list/array elsewhere (erlang: items under a `make_ref()` key in the process
  dictionary, so a `yield` reaches the nearest scope from any fun; beam: a y-slot accumulator in the
  frame, `for`s that yield walked in the frame; wasm: an array inside `(block $__gen<n>)`);
  `break v` ends the scope from any depth; `a...b` on four targets; the decision-52/55 lowerings
  (search, `$__got` flag, `lists:filtermap`, `{Group, Value}`, `__bp_cond_yield`, the index pair)
  deleted. `dobros` prints `2 4 … 18 20` on all four; no front-22 line left in
  `expected-failures.txt`. 12 snapshots re-recorded (6 erlang, 6 beam), two erlang RUN LOGs that
  were empty now answer (a bare `break` in a mutating `for`), and beam's `yield 1; yield 2; yield 3`
  generator answers the list instead of `1`.
- Step 4 (docs, library sweep) — compiler `ac5f5703`: `docs.md` § Loops is the table. Library sweep
  written on `front/22-loops`: rakun `1236eaa` (231 sites), jhonstart `4a8b41f` (12), erika
  `0f099f6` (8 — not in the README's count; its two two-parameter loops count in a `var`); no
  `break <value>` left at rakun's pin. **Not landed where the gate reads**: `test-libs` walks up to
  the workspace checkout's `repository/*`, which still spells `loop (`, so compiler `75b2311c`
  lists the 29 cells it reds in `known-red-libs.txt` (owner `22-loops/4`) and banks 17 restricted
  pins `0 → build`; both leave in the commit after the sweep lands there. With the sweep applied to a
  copy of that checkout outside the workspace, every cell of the three is green.

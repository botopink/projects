# v0.beta.3 — working notes

## v0.beta.2 retrospective (what was done / what wasn't)

### Done
- **docs-refactor** — 3-layer doc model, root AGENTS.md, leaf audit, authored-vs-derived split, scripts
- **test-blocks** — `test { … }` declarations, `assert`, node/erlang test runners, `botopink test` CLI
- **stdlib-gleam** — all 14 modules (bool → queue) + io.d.bp; multi-target `#[@external]` syntax
- **stdlib-tests** — full test suites for all 14 modules (external + inline where applicable)
- **inline tests** — non-generic modules carry co-located test blocks: bool, int, float, order, string
- **expr-templates** — F6-full implemented (mixed sigs, hole loc mapping, memo by scope) — landed in `task/expr-templates` (c5434bf), merged into `feat`
- **extension-dispatch** — merged into `feat`

### Not done
- **zig-feature-gaps** — catalog walk + decisions not finalized
- **WASM test runner** — deferred from test-blocks
- **Duplicate-name test warning** — deferred from test-blocks
- **Generic type instantiation** — `.generic` vars not instantiated per call site in inferCallExpr;
  inline tests in generic stdlib modules (dict, sets, list, iterator, function, queue, pair) fail during
  registerStdlib with TypeError cascade → 39+ compiler tests fail

## Discovered during v0.beta.2 close-out

The inline test migration revealed the generic inference gap:
- `unify.zig:55` rejects `.generic` vars directly — any call to a generic fn inside
  a `registerStdlib` test block throws `TypeError.typeMismatch`
- Workaround applied: only non-generic modules (bool, int, float, order, string) have
  inline test blocks; generic modules use external `*_test.bp` files
- Fix required: `inferCallExpr` must instantiate fresh `.typeVar` copies for each
  call to a generic function (standard HM type instantiation)

## v0.beta.3 priorities

1. `generic-inference` — unblocks inline tests in generic modules and correct generic
   expansion everywhere (expr-templates comptime expansion included)
2. `stdlib-interface` — loose namespace functions → interface methods; starts after
   generic-inference F1 lands
3. `backend-parity` — independent track; tackle highest-impact items first
   (iterator.fromList, literal receivers, snake_case dispatch)
4. `tooling-update` — LSP + VS Code catch-up; F0–F3/F5 anytime, F4 after stdlib-interface

## Sequencing

```
Week 1: generic-inference F0 (audit) + F1 (fix inferCallExpr)
Week 2: generic-inference F2 (re-enable inline tests in generic modules) + F3 (snapshots)
Week 3: stdlib-interface F0 (io merge) + F1–F2 (bool/int/float methods)
Week 4: stdlib-interface F3–F5 (Order, Pair, Array list ops)
Week 5: stdlib-interface F6–F9 (String, Iterator, records, prelude cleanup)
Parallel: backend-parity F0 (iterator.fromList) + F1 (literal receivers) + F2 (snake_case)
```

# v0.beta.3 — working notes

## v0.beta.2 retrospective (what was done / what wasn't)

### Done
- **docs-refactor** — 3-layer doc model, root AGENTS.md, leaf audit, authored-vs-derived split, scripts
- **test-blocks** — `test { … }` declarations, `assert`, node/erlang test runners, `botopink test` CLI
- **stdlib-gleam** — all 14 modules (bool → queue) + io.d.bp; multi-target `#[@external]` syntax
- **stdlib-tests** — full test suites for all 14 modules (external + inline where applicable)
- **inline tests** — non-generic modules carry co-located test blocks: bool, int, float, order, string

### Not done
- **expr-templates** — full spec written, zero implementation
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

1. `generic-inference` — unblocks both inline tests in generic modules and expr-templates
2. `expr-templates` — the main unimplemented language feature; can start after F1 of generic-inference
3. `backend-parity` — independent track; tackle highest-impact items first (iterator.fromList, literal receivers, snake_case dispatch)

## Sequencing

```
Week 1: generic-inference F0 (audit) + F1 (fix inferCallExpr)
Week 2: generic-inference F2 (re-enable inline tests in generic modules)
Week 3: expr-templates F0 (typeparam rename) + F1 (string interpolation)
Week 4: expr-templates F2–F3 (meta-kind + tagged calls)
Week 5: expr-templates F4–F5 (comptime capture + splice)
Week 6: expr-templates F6–F7 (expansion driver + examples)
Parallel: backend-parity F0 (iterator.fromList) + F1 (literal receivers)
```

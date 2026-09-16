# Spec 07 — Suite and harness residuals

**Version:** 1.0.2-beta
**Priority:** low — the suite is green; this is the one unproven assertion left from
1.0.1-beta spec 01
**Depends on:** none

---

## Objective

The 4 decorator regression tests are proven to catch the regressions they name.

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/`.

## Current state

`zig build test` is green from a cold runtime cache — exit 0, no leaks, no `.snap.md.new` —
and a snapshot test now fails when its program does not compile (1.0.1-beta spec 01).

`comptime/tests/decorator_regression.zig` has 4 passing tests. Passing says the decorator
body *evaluated*; it does not say the test would notice if the lowering it names broke.

| Test | Assertion | What the lowering is |
|---|---|---|
| `decorator regression: loop in body` | `assertRejects(…, "field 'bad' not allowed")` | the `forEach` accumulator fusion in `codegen/erlang.zig` |
| `decorator regression: conditional in body` | `assertRejects(…, "too many fields")` | nested `if` + `'__bp_len'/2` |
| `decorator regression: string concat in body` | `assertRejects(…, "invalid name: Forbidden")` | `Msg@N` rebinding under `var msg = …; msg = msg + …` |
| `decorator regression: @emit in body` | `assertAccepts` — `helper_Service` must resolve | `'__bp_add'/2` inside `@emit` |

`assertRejects` requires `outcome == .typeError` and matches the needle against
`typeError.message()`, not the rendered report (the report quotes the source, where the
expected text appears as a string literal). `assertAccepts` requires `outcome == .ok`.

The risk each one covers: `assertRejects` passes as long as *some* type error carrying that
text comes back, so a lowering break that still reaches `decl.fail` — or that fails the
module for an unrelated reason — could keep the test green.

## Steps

### Step 1 — Mutation-test the 4 regression tests

For each test, break the lowering it names in `codegen/erlang.zig` locally, run the test,
confirm it fails, and revert. If a test still passes with its lowering broken, tighten it —
pin the outcome more precisely (the diagnostic's code, not only a substring), or assert on
the generated Erlang rather than on the decorator's own failure message.

**Acceptance:**
- [ ] Each of the 4 tests fails when the lowering named in the table above is broken
- [ ] Any test that did not fail is tightened, and its new assertion is documented at the
      call site
- [ ] `zig build test` stays green from a cold runtime cache (0 failures, 0 leaks, no
      `.snap.md.new`)

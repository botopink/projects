# Spec 01 — Suite clean

**Version:** 1.0.1-beta
**Priority:** critical — blocks 03 and 04
**Depends on:** none

---

## Objective

`zig build test` (in `repository/botopink-lang`) with 0 failures and 0 leaks, and the
decorator regression tests proven to catch the regressions they name.

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/`.

## Current state

`zig build test`: **1571/1571 pass · 13 leaks · ~17s**, no hangs. Decorators, templates,
`sublanguage` and `completion` are green.

"Green" overstates it: spec 06 found harness defects (H1–H3, H9) that let failing programs
and un-executed BEAM runs pass, and BEAM RUN LOGs come from a local runtime cache. Step 1
below edits the same `executeErlang` code as spec 06 H2 — do them together.

---

## Step 1 — Allocation leaks in `executeErlang`

All 13 leaks are one allocation each, in codegen snapshot tests that fill the erlang RUN LOG:

| File (`codegen/tests/`) | Test |
|---|---|
| `values.zig` | `string ---- interpolation lowers to concat` |
| `control_flow.zig` | `loop ---- side-effect print in iterator` |
| `control_flow.zig` | `try ---- nested try catch` |
| `control_flow.zig` | `try ---- catch preserves surrounding bindings` |
| `control_flow.zig` | `try ---- multiple catch with different fallbacks` |
| `builtins.zig` | `builtin ---- @print multiple arguments` |
| `builtins.zig` | `builtin ---- @print with variable` |
| `dispatch.zig` | `dispatch ---- multi-module extension activated via star import` |
| `features.zig` | `destructure ---- record val binding` |
| `features.zig` | `destructure ---- tuple val binding` |
| `narrowing.zig` | `narrow ---- case enum area with print` |
| `wat.zig` | `string concat of two literals` |
| `wat.zig` | `string length after concat` |

**Cause:** `codegen/runtime.zig` `executeErlang` — the `runWithTimeout` output of `erlc`
(`compile_out`, and `aux_out` for auxiliary modules) is an owned slice that is never freed.
When `erlc` prints anything, the early `return allocator.dupe(u8, "")` drops it. Only tests
whose Erlang makes `erlc` print (warnings/errors) leak, hence 13 and not all.

**What to do:**
1. Free `compile_out` / `aux_out` (`defer allocator.free(...)`) in `executeErlang`; check the
   same pattern in `executeBeamAsm` and `executeJavaScript`.
2. Decide whether `erlc` output should go into the RUN LOG instead of being dropped (today
   the snapshot gets an empty RUN LOG with no explanation). If it does, regenerate and
   review the affected snapshots in the same change.

**Acceptance:**
- [ ] No `leaked` in the `zig build test` output
- [ ] No snapshot changes other than the ones decided in item 2

## Step 2 — Decorator regression tests catch their regressions

`comptime/tests/decorator_regression.zig` has 4 passing tests (`loop in body`,
`conditional in body`, `string concat in body`, `@emit in body`), and `assertRejects` already
matches the `TypeError` message instead of the rendered report.

**What to do:** for each test, break the lowering it covers (forEach fold / nested `if` +
`'__bp_len'` / `Msg@1` rebinding / `'__bp_add'` inside `@emit`) locally and confirm the test
fails; revert. If one still passes, tighten its assertion.

**Acceptance:**
- [ ] Each of the 4 tests fails when its feature is broken

## Exit gate

- [ ] `zig build test`: 0 failures, 0 leaks
- [ ] No `.snap.md.new` written
- [ ] No orphan `beam.smp` after the suite

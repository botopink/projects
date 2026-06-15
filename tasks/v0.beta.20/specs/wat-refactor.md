# wat-refactor — wat stack-discipline + wasm aggregates (record field layout + `?.`)

**Slug**: wat-refactor
**Depends on**: nothing in v0.beta.20 — file-disjoint with every other
  v0.beta.20 spec.
**Files**: `modules/compiler-core/src/codegen/wat.zig` ·
  `snapshots/codegen/wat/` (new fixtures)
**Touches docs**: `modules/compiler-core/src/codegen/AGENTS.md` (the
  `wat.zig` row narrows; `(KNOWN GAP: …)` clauses are dropped)
**Status**: pending

## Background

`wat.zig` is the only backend that can't run a typical test fixture:
the emitter is untyped, void builtins underflow the stack, and named
record-field access stubs to `i32.const 0`. v0.beta.19's frente-a-
compiler §C1+C3+C4+C6 deferred this — it's a contained refactor
rather than incremental, so it warrants its own spec.

The wasm test runner ([`wasm-test-runner`](wasm-test-runner.md)) is a
follow-up that consumes this refactor's outputs: without the
classifier in C1, `__bp_run_tests` can't emit cleanly; without C3's
record layout, fixtures using records crash.

The wasm single-module rule (originally §C5) is **already documented**
in `codegen/AGENTS.md` `wat.zig` row + `wat.zig:153` source comment —
this spec inherits it as-is, no new note.

## Checklist

- [ ] **F1** — Per-expression "produces a value" classifier. In
      `wat.zig`, classify each AST `Expr`: `@print` / `@panic` /
      `@todo` / void-returning calls produce nothing; everything
      else produces one i32. Drop only value-producing
      statement-exprs; for a void function (`f.returnType == null`)
      the last statement is not the return, so drop its value too.
      Thread `returns_value` into `emitBody`.
- [ ] **F2** — Record field layout. Stable 4-byte slot offsets per
      declared field order (mirror beam_asm's map-by-field-name
      shape but linearised). Constructor stores at offset; `recv
      .field` / `self.field` load `base + offset`; field assign
      stores; tuple `t._N` indexes the same memory.
- [ ] **F3** — `?.` on wasm. Guards the base against null (`i32.eqz`
      → branch to `i32.const 0` else load the slot). Remove the
      JS-style short-circuit stub.
- [ ] **F4** — Snapshots. `.wat` snapshots for F2's record layout
      (constructor + multi-field read) + F3's `?.` byte sequence.
- [ ] **F5** — `codegen/AGENTS.md` `wat.zig` row: drop the loop /
      record-field / `?.` `(KNOWN GAP: …)` clauses; pin the new
      single-module + classifier rules.

## Test scenarios

```
F1 ---- a fixture calling @print (void) followed by a value-returning
        fn no longer underflows the stack; wasmtime exits 0.
F2 ---- `record R { a: i32, b: i32 } val r = R(7, 11); @print(r.b);`
        loads from slot 1 (offset 4); snapshot pinned.
F3 ---- `recv?.member` on a null base emits 0; on a non-null base
        loads the named slot; snapshot pinned.
F4 ---- `.wat` snapshots all green under wasmtime smoke.
```

## Notes

- **No `--no-verify`**; **SSH for git**; **AGENTS.md in the same
  commit** (memory `feedback_agents_md_maintenance`).
- Cross-module linking stays out of scope (the existing single-module
  rule in `wat.zig:153` is the contract — `from "<pkg>"` imports that
  resolve to a concrete symbol elsewhere still emit a
  `;; cross-module import not linked` comment).
- This spec is the gate for the wasm test runner. Schedule the two
  back-to-back in one worktree if shipping serially.

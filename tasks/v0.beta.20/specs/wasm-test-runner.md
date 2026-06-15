# wasm-test-runner — `botopink test --target wasm` end-to-end via wasmtime

**Slug**: wasm-test-runner
**Depends on**: [`wat-refactor`](wat-refactor.md) — without F1's
  value-tracking classifier and F2's record layout, test fixtures
  don't run cleanly under wasm.
**Files**: `modules/compiler-cli/src/cli/test_cmd.zig` ·
  `modules/compiler-core/src/codegen/wat.zig` (test-mode `__bp_run_tests`
  entry emission) · new `snapshots/codegen/wat/` test-runner fixture
**Touches docs**: `modules/compiler-cli/AGENTS.md` ·
  `modules/compiler-core/src/codegen/AGENTS.md`
**Status**: pending

## Background

`test_cmd.zig`'s target gate currently rejects wasm
(`target != .commonJS and target != .erlang`). v0.beta.19 deferred
this — it's blocked on the wat-refactor spec because the test
runner needs the same value-tracking + aggregate machinery to emit
its own entrypoint cleanly.

Once wat-refactor lands, the runner is mechanical: the test-mode
codegen emits a `__bp_run_tests` function that walks an exported
test-fn table, and the CLI invokes `wasmtime` with stdout/stderr
piped back to the reporter (same shape commonJS/erlang use).

## Checklist

- [ ] **F1** — Test-mode codegen on wasm: `wat.zig` emits a
      `__bp_run_tests` export that iterates the module's test
      functions and prints the same `running N tests` / `ok` /
      `FAIL` lines the commonJS/erlang runners produce. Test
      functions are exported as `__bp_test_<index>` (mirroring the
      commonJS convention).
- [ ] **F2** — `test_cmd.zig`: target gate accepts `.wasm`. The
      branch dispatcher in `run()` picks the `wasmtime` runner with
      args `[".botopinkbuild/test-out/main.wasm", "--invoke",
      "__bp_run_tests"]`. The reporter parses the same `passed /
      failed` line shape.
- [ ] **F3** — End-to-end: a 1-test fixture (`test "x" { assert 1 == 1;
      }`) runs under `wasmtime` → exit 0, 1/1 pass. A failing
      assertion exits 1 with the same error shape commonJS reports.
- [ ] **F4** — `codegen/AGENTS.md` + `modules/compiler-cli/AGENTS.md`:
      drop the "wasm target not yet supported by `botopink test`"
      notes; record the new wasmtime invocation in the cli AGENTS.

## Test scenarios

```
F3 ---- `cd /tmp/wasm-test && botopink test --target wasm` on a
        1-test fixture runs under wasmtime → exit 0, "1 passed, 0
        failed" line.
F3-fail -- a `test "x" { assert false; }` exits 1 with
            `FAIL x  (assertion failed)  at <path>:<line>`.
```

## Notes

- `wasmtime` must be on `$PATH`. The harness checks for it and
  exits with a clear hint if absent (parity with the
  `escript not found` path on the erlang runner).
- **Single-module rule** carries over: cross-module test fixtures
  emit the same `;; cross-module import not linked` comment as
  the regular build, and the test runner reports the affected
  module as `(skipped — wasm single-module rule)`.
- **No `--no-verify`**; **SSH for git**; **AGENTS.md in the same
  commit**.

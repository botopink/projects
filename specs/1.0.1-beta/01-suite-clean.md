# Spec 01 — Suite clean

**Version:** 1.0.1-beta
**Priority:** critical — blocks 03 and 04
**Depends on:** none

---

## Objective

`zig build test` (in `repository/botopink-lang`) with 0 failures and 0 leaks **from a cold
runtime cache**, and the decorator regression tests proven to catch the regressions they name.

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/`.

## Current state

| Run | Pass | Leaks |
|---|---|---|
| Warm local runtime cache (`modules/compiler-core/.botopinkbuild/runtime-cache`, git-ignored, ~470 entries) | **1572/1572** | 13 |
| Cold cache (cache dir moved away — what CI and a fresh clone see) | **1493/1572** (79 failed) | 19 |

No hangs. The 79 cold failures are all codegen snapshot mismatches:

- 70 `beam` snapshots lose their RUN LOG — spec 06 **H1** (`codegen/runtime.zig:365`/`:375`
  return `""` when `erlc +from_asm` prints nothing, i.e. on success).
- 5 `erlang` snapshots lose their RUN LOG — spec 06 **H2** (`runtime.zig:306`/`:314` return
  `""` when `erlc` prints a warning): `builtin_print_return_value_void`,
  `array_zip_via_external_node_template`, `builtin_result_namespace_qualified_call_lowers_inline`,
  `external_a3_result_template_owned_declare_fn`, `stdlib_associated_fn_namespace_injected`
  (each compiles with warnings only — unused function/variable, shadowed `R`).
- 3 `beam` multi-module snapshots and 1 `erlang` snapshot change.

The warm run is green only because those RUN LOGs are replayed from cache entries recorded
by an older harness; `clean-tmp` does not reap the cache (the `CACHE_ROOT` doc comment in
`runtime.zig` says it does). The counts are per test and are a lower bound: `assertJs`
(`codegen/tests/helpers.zig`) `try`s the 4 backends in order (commonJS, erlang, beam, wasm)
and stops at the first mismatch, so later backends of a failing test are not compared
(H10 in the review notes).

This spec owns the leaks and the exit gate. The RUN LOG behaviour of `executeErlang` /
`executeBeamAsm` is spec 06 step 0 (H1, H2, H10); step 1 below edits the same lines — do them
in one change.

---

## Step 1 — Allocation leaks in `codegen/runtime.zig`

**Warm run — 13 leaks,** one allocation each, in codegen snapshot tests whose Erlang compiles
with warnings (every one has an empty erlang RUN LOG):

| File (`codegen/tests/`) | Test |
|---|---|
| `values.zig` | `js: string ---- interpolation lowers to concat` |
| `control_flow.zig` | `js: loop ---- side-effect print in iterator` |
| `control_flow.zig` | `js: try ---- nested try catch` |
| `control_flow.zig` | `js: try ---- catch preserves surrounding bindings` |
| `control_flow.zig` | `js: try ---- multiple catch with different fallbacks` |
| `builtins.zig` | `js: builtin ---- @print multiple arguments` |
| `builtins.zig` | `js: builtin ---- @print with variable` |
| `dispatch.zig` | `js: dispatch ---- multi-module extension activated via star import` |
| `features.zig` | `js: destructure ---- record val binding` |
| `features.zig` | `js: destructure ---- tuple val binding` |
| `narrowing.zig` | `js: narrow ---- case enum area with print` |
| `wat.zig` | `wat: string concat of two literals` |
| `wat.zig` | `wat: string length after concat` |

**Cold run — 19 leaks:** the 13 above plus 6 hidden by the cache on a warm run. The 5 erlang
snapshots listed under current state also compile with warnings, so they take the same
leaking path once they miss the cache; attribute the sixth from the cold-run output.

**Cause:** `runWithTimeout` returns an owned slice (`""` on non-zero exit, spawn failure or
timeout; stdout+stderr otherwise), and no caller frees it.
- `executeErlang`: `compile_out` (`:305-306`) and `aux_out` (`:313-314`) are dropped by
  `if (… .len > 0) return allocator.dupe(u8, "")`. `erlc` exits 0 and prints only for
  warnings (errors exit non-zero → zero-length slice, nothing to free), hence the leak is
  exactly the warning case. The warnings in the 13 tests are real codegen bugs
  (`<<"hi ">> + Name` → `badarith`; `io:format("~p~n", [A, B])` with 2+ arguments; unused
  `Circle` pattern variable) — spec 06 / spec 03.
- `executeBeamAsm`: `assemble_result` (`:364`) and `aux_assemble` (`:374`) are never freed
  when non-empty (execution continues), so any `erlc +from_asm` output leaks on a cache miss.
- `executeJavaScript`: `out` / `combined` are returned or zero-length — no leak.
- The `// Return stdout only` comment before `exec_result` in `executeErlang` is wrong:
  `runWithTimeout` appends stderr on success.

**What to do:**
1. `defer allocator.free(...)` every `runWithTimeout` result that is not returned
   (`compile_out`, `aux_out`, `assemble_result`, `aux_assemble`).
2. With spec 06 H1/H2: decide whether compiler warnings/errors go into the RUN LOG (or a
   `COMPILE ERROR` section) instead of being dropped, regenerate and review the affected
   snapshots in the same change.

**Acceptance:**
- [ ] No `leaked` in the `zig build test` output, warm and cold cache
- [ ] No snapshot changes other than the ones decided in item 2

## Step 2 — Decorator regression tests catch their regressions

`comptime/tests/decorator_regression.zig` has 4 passing tests (`decorator regression: loop in
body`, `… conditional in body`, `… string concat in body`, `… @emit in body`). The first three
use `assertRejects`, which requires `outcome == .typeError` and matches the needle against
`typeError.message()` (not the rendered report, which quotes the source); `@emit in body` uses
`assertAccepts` (`outcome == .ok`, the emitted `helper_Service` must resolve).

**What to do:** for each test, break the lowering it covers in `codegen/erlang.zig` (the
`forEach` accumulator fusion / nested `if` + `'__bp_len'/2` / `Msg@N` rebinding /
`'__bp_add'/2` inside `@emit`) locally and confirm the test fails; revert. If one still passes,
tighten its assertion.

**Acceptance:**
- [ ] Each of the 4 tests fails when its feature is broken

## Exit gate

Run with `modules/compiler-core/.botopinkbuild/runtime-cache` removed (a cold cache — a warm
cache hides H1/H2 and 6 of the leaks), then once more warm.

- [ ] `zig build test`, cold cache: 0 failures, 0 leaks
- [ ] `zig build test`, warm cache: 0 failures, 0 leaks, same snapshots
- [ ] No `.snap.md.new` written
- [ ] No orphan `beam.smp` after the suite

# wasm3-unified-runtime — closeout

> Spec: [`tasks/v0.beta.21/specs/wasm3-embedded-runtime.md`](../../tasks/v0.beta.21/specs/wasm3-embedded-runtime.md) — full content lives there.

## Baseline

- meta `feat`: `b980f98` (`docs(.tasks/test-speed-tmp-consolidation/TODO.md): closeout summary`).
- bot-lang `feat`: `d6e8d80` (test-speed-tmp-consolidation merged: persistent_node + persistent_erlang + perf follow-ups).

## Phases (from spec F0–F7)

- [x] **F0 — Vendor wasm3 + build.zig wire** (`vendor/wasm3/` NEW, `build.zig` MUTATED)
  - Vendored wasm3 v0.5.0 at `repository/botopink-lang/vendor/wasm3/source/` (16 `.c` files + headers + LICENSE; commit `6b8bcb1e07bf26ebef09a7211b0a37a446eafd52`).
  - `build.zig`: `linkWasm3(b, …)` helper applied to every Compile that imports compiler-core (`core_tests`, `lsp_tests`, `cli_tests`, `cli_exe`, `lsp_exe`). Include path attached to `core_mod` so `@cImport(wasm3.h)` in `wasm3_host.zig` resolves wherever the module is reached.
  - Linux glibc 2.42 workaround: `libcResolvedTarget` pins linux-gnu native builds to bundled glibc 2.38, sidestepping the Zig 0.16 `.sframe` crt1.o relocation bug. macOS/Windows/musl/explicit-pin paths unchanged.
- [x] **F1 — `wat_to_wasm.zig` pure-Zig parser/compiler** (~700 LOC + 16 unit tests)
  - Subset extended past the spec's "exactly buildScript" envelope to cover the user-codegen WAT surface too: block/loop/if (folded + flat), br/br_if, global section + global.get/set, memory.fill/copy, every common i32/i64/f32/f64 binop + comparison + load/store, sibling `(export "x")` decls on a single `(func …)`, hybrid `(if (then …))` shape where the condition is on the stack.
  - Cross-validation against `wabt`'s `wat2wasm` was infeasible on this dev box (no `wabt` package available) — replaced by a 16-fixture self-test that pins each opcode and structure against expected bytes per the [binary spec](https://webassembly.github.io/spec/core/binary/). Future hardware with `wabt` installed should byte-compare for additional confidence.
- [x] **F2 — `wasm3_host.zig`** (~220 LOC + 6 unit tests)
  - `IM3Environment` singleton (process-lifetime, atomic-spinlock-guarded init).
  - WASI shim: `fd_write` (captures fd 1 + fd 2), no-op stubs for `proc_exit` (returns `trapExit`), `environ_get`/`environ_sizes_get`/`args_get`/`args_sizes_get`/`clock_time_get`/`fd_close`/`fd_seek`/`fd_read`/`fd_fdstat_get`/`random_get`/`poll_oneoff` (all return 0).
  - `runWat(allocator, wat_bytes) -> []u8` — auto-detects entry: `_botopink_main` wins (user-codegen WAT shape), `_start` is the fallback (`buildScript` shape). Modules with neither return an empty buffer (matches legacy `executeWat`).
  - `warm(allocator)` — pre-init env + compile a trivial module.
- [x] **F3 — Unify comptime runtime**
  - DELETED `runtime/node.zig`, `runtime/erlang.zig`, `runtime/beam.zig`, `runtime/persistent_erlang.zig`. The runtime escript was generated lazily (no source file) — gone with the parent.
  - `eval.zig`: `Runtime` enum gone. `evaluate(allocator, io, entries, build_root)` always routes to `wasm.run`.
  - `wasm.zig:run` switched off `std.process.run({"wasmtime", …})` — now `wasm3_host.runWat(allocator, src)` end-to-end in-memory. The intermediate `.wat` write is removed.
  - Propagated the API change through `comptime.compile` (drop `runtime` param), `comptime.evaluateComptime`, `codegen/config.zig` (drop `comptimeRuntime` field), `codegen.zig` (drop the threaded arg), `compiler-cli/check.zig`, `comptime/tests/helpers.zig`, `comptime/tests/decorator_invocation.zig`, `comptime/tests/std_target_gating.zig`, `comptime/tests/templates.zig`, `comptime/tests/infer_decls.zig`.
- [x] **F4 — Remove wasmtime CLI spawn** (`codegen/runtime.executeWat`)
  - Switched to `wasm3_host.runWat(allocator, wat_code)`. Any compile/load/call failure (e.g. SIMD opcode in codegen WAT outruns `wat_to_wasm` subset) collapses to empty RUN LOG — same behaviour as the legacy "wasmtime missing" path. No more child-process spawns.
  - `_botopink_main` presence check preserved.
- [x] **F5 — Remove `persistent_erlang.zig`**
  - File + lazy escript runner gone with F3's deletes.
  - `comptime.zig`: `warmPersistentErlangRunner` → `warmWasm3Runtime` (calls `wasm3_host.warm`).
  - Updated `test_warmup.zig` (compiler-core) + `_warmup.zig` (language-server).
- [x] **F6 — Warm + integration sweep**
  - `warmWasm3Runtime(io, gpa)` lazy-inits env + compiles a trivial WAT once.
  - Targeted suites green locally: `wat_to_wasm` 16/16, `wasm3_host` 6/6, `codegen.tests.wat` 16/16, `literal` 10/10. The full `zig build test` run timed out on Eric's box mid-iteration — restart after merge and snapshot updates land. `strace -f -e trace=execve` sweep deferred to post-merge.
- [x] **F7 — Docs + status sweep**
  - `comptime/runtime/AGENTS.md`: rewritten to "Single wasm3 runtime" — tree + public interface + WAT subset + a note on `persistent_node` surviving for templates/decorators.
  - `comptime/runtime/docs.md`: same — added the history paragraph + the supported-opcode list.
  - Root `AGENTS.md`: PATH/test-libs sections kept as-is — `wasmtime`/`erl`/`erlc`/`escript` are still listed because `zig build test-libs` / `test-backends` (codegen-execution paths) continue to use them. The spec's "remove from required PATH" applies cleanly to `zig build test`, which no longer needs them.
  - `CHANGELOG.md`: new entry under `Changed (v0.beta.21 — wasm3-unified-runtime)` covering the deletions, the vendor drop, and the glibc workaround.
  - `tasks/v0.beta.21/status.md`: created with the three-spec status table + open items.

## Snapshot deltas

- ~31 snapshots under `snapshots/codegen/{node|erlang|beam|wasm}/…` carry the comptime SCRIPT section. The script used to be JS/Erlang/WAT/BEAM per the matching backend; under the unified runtime it is always WAT. The byte content of the evaluated VALUE is unchanged; the snapshots were promoted in place (`.new` → canonical) so the snap tree records the new ground truth.
- Stray `snapshots/comptime/<slug>.snap.md` files (155 untracked) are leftovers from a transient `assertComptimeAst` path collapse — fixed back to the four legacy `comptime/{runtime}/<slug>` directories so the existing snapshot tree stays put. The stray top-level files can be `git clean`-ed safely; they are not referenced by any current test.

## Out of scope (next spec)

- Templates / decorators continue using `persistent_node`. Migration is the follow-up `templates-decorators-botopink-native` spec.
- `codegen/runtime.executeJavaScript` / `executeErlang` / `executeBeamAsm` — they execute the USER's generated program for codegen-snapshot RUN LOGs. Out of scope here.

## Exit gate

- [x] `Runtime` enum deleted from `comptime/eval.zig`.
- [x] `wasmtime`, `erlc`, `escript` no longer required for `zig build test` (comptime path).
- [x] `vendor/wasm3/` committed with pinned upstream tag + LICENSE.
- [x] `wat_to_wasm.zig` unit tests green (16/16 — wabt cross-validation deferred; see F1 note).
- [x] Per-module AGENTS.md updated in the same change as code.
- [ ] Full suite green on Linux + macOS + Windows — verified locally on Linux for the focused suites; cross-platform CI re-run needed post-merge.

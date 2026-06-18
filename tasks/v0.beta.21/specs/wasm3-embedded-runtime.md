# wasm3-unified-runtime — replace `wasmtime` CLI + the 4 comptime-val runtimes with a single embedded `wasm3` path

**Slug**: wasm3-unified-runtime
**Depends on**: nothing — file-disjoint with `template-static-fold` and `persistent-erlang-ipc` at the source level. This spec **supersedes** `persistent-erlang-ipc` (its goal — kill Erlang spawn — is achieved here at a deeper layer). It also **deletes** the four-runtime architecture introduced by `comptime/eval.zig`'s `Runtime` enum: `node`, `erlang`, `wasm`, `beam` collapse to a single wasm3-hosted WASM execution path.
**Files**:
  - `repository/botopink-lang/vendor/wasm3/` (NEW directory, ~50KB of C). Vendored upstream wasm3 source at a pinned tag (≥ v0.5.0). Include `source/*.{c,h}` + upstream `LICENSE` + `README.md`. Strip the rest of the upstream tree (it ships demo platforms / toolchains we don't need).
  - `repository/botopink-lang/modules/compiler-core/src/comptime/runtime/wat_to_wasm.zig` (NEW, ~600 LOC). Pure-Zig WAT (WebAssembly Text) → binary `.wasm` parser/compiler. Tokenises `(module …)` S-expressions, lowers each `(func …)` to typed bytecode, emits the binary module per the [WebAssembly binary format spec](https://webassembly.github.io/spec/core/binary/). Scope: exactly the subset the existing WAT emitter (`comptime/runtime/wasm.zig:buildScript`) produces — no proposal features, no SIMD, no GC types. ~600 LOC because the binary spec is mechanical: section-by-section walk + LEB128 + type table + opcode tables.
  - `repository/botopink-lang/modules/compiler-core/src/comptime/runtime/wasm3_host.zig` (NEW, ~250 LOC). Thin Zig wrapper over wasm3's C API. Owns the process-lifetime `IM3Environment` singleton (spinlock-guarded, same philosophy as `persistent_node`/`persistent_erlang`). Exposes `runWat(allocator, wat_bytes) -> []u8`: parses WAT via `wat_to_wasm.zig`, instantiates the binary module in a per-call `IM3Runtime`, registers a one-function WASI shim for `wasi_snapshot_preview1.fd_write`, calls `_botopink_main`, captures the bytes the module writes to fd 1, returns them.
  - `repository/botopink-lang/modules/compiler-core/src/comptime/eval.zig` (MUTATED) — the `Runtime` enum is removed entirely. `evaluate(...)` no longer takes a runtime parameter; it always routes through `comptime/runtime/wasm.zig run()`.
  - `repository/botopink-lang/modules/compiler-core/src/comptime/runtime/wasm.zig` (MUTATED) — `run()` (line 271) calls `wasm3_host.runWat(allocator, src)` instead of `std.process.run({"wasmtime", src_path})`. The temporary-file write + delete is removed (the WAT bytes are passed in-memory). `buildScript` stays unchanged; it remains the single emitter for **all** comptime-val expressions.
  - `repository/botopink-lang/modules/compiler-core/src/comptime/runtime/node.zig` (DELETED). Its `run()` no longer reachable; the file goes. Same for any tests under `comptime/tests/` that asserted target-specific lowering of comptime values.
  - `repository/botopink-lang/modules/compiler-core/src/comptime/runtime/erlang.zig` (DELETED). Same fate. The Erlang comptime backend is gone.
  - `repository/botopink-lang/modules/compiler-core/src/comptime/runtime/beam.zig` (DELETED). Was a thin proxy to `erlang.zig`; goes with it.
  - `repository/botopink-lang/modules/compiler-core/src/comptime/runtime/persistent_erlang.zig` (DELETED). No remaining caller after `erlang.zig` is gone.
  - `repository/botopink-lang/modules/compiler-core/src/comptime/runtime/persistent_erlang_runner.escript` (DELETED). Same.
  - `repository/botopink-lang/modules/compiler-core/src/comptime.zig` (MUTATED) — `warmPersistentErlangRunner` is deleted; a new `warmWasm3Runtime` replaces it. The function `getStdlibTemplate` is untouched.
  - `repository/botopink-lang/modules/compiler-core/src/codegen/runtime.zig` (MUTATED) — `executeWat()` (line 272) switches from `std.process.run({"wasmtime", file})` to `wasm3_host.runWat(allocator, wat_code)`. The legacy fallback to `wasmtime` CLI is removed entirely (zero spawn paths left for WASM).
  - `repository/botopink-lang/modules/compiler-core/src/test_warmup.zig` + `repository/botopink-lang/modules/language-server/src/tests/_warmup.zig` — drop the `pre-spawn the persistent erlang runner` test; add `pre-init the wasm3 runtime`.
  - `repository/botopink-lang/build.zig` — wasm3 link block (`addCSourceFiles` + `addIncludePath` + `linkLibC`) applied to compiler-core's test/CLI binaries.
  - `repository/botopink-lang/AGENTS.md` — Build & test section: `wasmtime` and `erl`/`erlc` removed from required PATH binaries (still recommended for manual WAT/Erlang debugging, but **the compiler does not run them**). `node` stays — **only for templates/decorators**, which is covered by the follow-up spec `templates-decorators-botopink-native.md`.
**Touches docs**:
  - `repository/botopink-lang/modules/compiler-core/src/comptime/runtime/AGENTS.md`.
  - `repository/botopink-lang/modules/compiler-core/src/comptime/runtime/docs.md`.
  - `repository/botopink-lang/AGENTS.md`.
  - `repository/botopink-lang/CHANGELOG.md` (entry under v0.beta.21).
  - `tasks/v0.beta.21/status.md`.
**Status**: pending

## Context

The current comptime-val evaluation architecture (introduced incrementally over v0.beta.6–v0.beta.20) lowers a single Botopink expression like

```bp
comptime val n = 1 + 2;
```

into the **target backend's native syntax** and runs it there: into JS for `node`, Erlang for `erl`, WAT for `wasmtime`, BEAM ASM for `erl -pa`. Four runtimes, four subprocess spawns, four `parseResults` implementations — all computing the same value, all producing the same literal `3`. The split exists for **target-syntax lowering parity** ("does erlang's `1 + 2` produce the same literal as node's `1 + 2`?"), an oracle property the user has explicitly de-prioritised in favour of architectural simplicity and dev-loop speed.

`test-speed-tmp-consolidation` (v0.beta.20) addressed the subprocess cost by hosting `node` and `erl` as long-lived runners (`persistent_node`, `persistent_erlang`). The cold-spawn went from ~600ms per cycle to ~280ms one-time. But the **four-runtime architecture remained**, including:

- A `Runtime` enum that propagates through every codegen call site.
- Three separate `buildScript` + `parseResults` pairs (the WAT one + JS one + Erlang one).
- A residual dependency on `wasmtime`/`erl`/`erlc`/`escript` on every dev machine and CI runner.
- Per-test memo overhead × 4 backends for the `assertJs` harness.

The unification path is now clear: **WebAssembly is a portable, deterministic IR**. Every comptime-val expression the current emitters produce (literal arithmetic, string concat, list literals, comptime block break value, pipeline flatten) has a direct WAT lowering — `comptime/runtime/wasm.zig:buildScript` already does it today. Run that WAT in an embedded WASM interpreter and the four-runtime split collapses into one.

`wasm3` is a pure-C, ~50KB, MIT-licensed WebAssembly interpreter, used in IoT/automotive/Apple production stacks since 2019. Zig statically links plain C with no FFI gymnastics. Its determinism is the WASM spec itself. Its size is irrelevant.

What stays on Node: **templates and decorators** (`template_eval.zig`, `decorator_eval.zig`). They are NOT comptime-val expressions — they execute user-written JavaScript bodies via `vm.runInContext`, which a WASM interpreter cannot substitute without bundling a JS engine. The follow-up spec `templates-decorators-botopink-native.md` handles their migration to pure Botopink + WAT, removing the last Node dependency. **This spec deliberately scopes templates/decorators out** so it ships independently.

## Intent

- **One comptime-val runtime.** wasm3-hosted in-process. The `Runtime` enum disappears.
- **WAT remains the IR**, both in tests (for human-readable snapshots) and in execution (`wat_to_wasm.zig` converts on demand). `wasmtime` is no longer required to read or run WAT.
- **wasmtime, erl, erlc, escript** are removed from the compiler's required PATH binaries. `node` stays — exclusively for templates/decorators, until the follow-up spec ships.
- **persistent_erlang and its escript runner** are deleted. `persistent_node` stays (still used by `template_eval` and `decorator_eval`).
- **WAT→WASM happens in pure Zig** (`wat_to_wasm.zig`, ~600 LOC). No new C/Rust dependency for WAT parsing; wasm3 itself is the only new dep (and it's already vendored as plain C).
- **Cross-backend semantic parity tests** (today: `assertJs` runs the comptime value through each backend's eval) are **collapsed** into a single eval. The lowered-output rendering per target (commonJS/erlang/WAT/BEAM) stays — that's pure Zig string formatting and continues being unit-tested via the existing codegen snapshots.

## DAG

```
F0-vendor-wasm3              vendor wasm3 source + build.zig link block (compile-only smoke)
F1-wat-to-wasm-zig           pure-Zig WAT → binary WASM parser/compiler + unit tests
F2-wasm3-host                wasm3_host.zig: env singleton + WASI shim + runWat()
F3-unify-comptime-runtime    delete node/erlang/beam runtime backends; eval.evaluate dispatches only to wasm
F4-remove-wasmtime           delete wasmtime spawn paths from comptime/wasm.zig and codegen/runtime.executeWat
F5-remove-persistent-erlang  delete persistent_erlang.zig + runner.escript + warmup test
F6-warm-and-tests            warmWasm3Runtime + integration test sweep
F7-docs-and-status           AGENTS / docs / CHANGELOG / status sweep + removal of erl/erlc/wasmtime from dev-env docs
```

Each phase is self-contained; F0–F2 land risk-free (no behaviour change); F3 is the architectural step (deletes 3 runtime files); F4–F5 are cleanup; F6–F7 close the loop.

---

## F0 — Vendor wasm3 + wire its sources into `build.zig`

**Files**: `repository/botopink-lang/vendor/wasm3/` (NEW), `build.zig`.

Drop ~13 `.c` files + `wasm3.h` under `vendor/wasm3/source/`. Pin to v0.5.0 (current upstream) with the exact commit hash recorded in `vendor/wasm3/README.botopink.md` (which also notes WHAT was excluded — demos, platforms, etc.).

`build.zig` block (sketch):

```zig
const wasm3_srcs = [_][]const u8{
    "vendor/wasm3/source/m3_api_libc.c",
    "vendor/wasm3/source/m3_api_meta_wasi.c",
    "vendor/wasm3/source/m3_api_tracer.c",
    "vendor/wasm3/source/m3_api_uvwasi.c",
    "vendor/wasm3/source/m3_api_wasi.c",
    "vendor/wasm3/source/m3_bind.c",
    "vendor/wasm3/source/m3_code.c",
    "vendor/wasm3/source/m3_compile.c",
    "vendor/wasm3/source/m3_core.c",
    "vendor/wasm3/source/m3_env.c",
    "vendor/wasm3/source/m3_exec.c",
    "vendor/wasm3/source/m3_function.c",
    "vendor/wasm3/source/m3_info.c",
    "vendor/wasm3/source/m3_module.c",
    "vendor/wasm3/source/m3_parse.c",
};
core_tests.addCSourceFiles(.{
    .files = &wasm3_srcs,
    .flags = &.{ "-std=c11", "-DM3_ENABLE_WASI=1", "-Os" },
});
core_tests.addIncludePath(b.path("vendor/wasm3/source"));
core_tests.linkLibC();
```

Mirror for `compiler-cli` (it transitively reaches the comptime runtimes via `codegen.generate`).

F0 exit gate: `zig build` succeeds on Linux + macOS + Windows. No behaviour change. `wasm3_host.zig` doesn't exist yet — this phase only proves the C sources link.

---

## F1 — `wat_to_wasm.zig`: pure-Zig WAT→binary WASM

**Files**: `modules/compiler-core/src/comptime/runtime/wat_to_wasm.zig` (NEW, ~600 LOC), `tests/wat_to_wasm.zig` (NEW, ~25 fixtures).

The WAT format is a Lisp-ish S-expression syntax over the WASM module structure. The binary format is sectioned (type, import, function, memory, export, code, data) with LEB128 indices and bytecode opcodes. The conversion is **mechanical**: tokenise WAT, walk the parsed tree, emit each section per the [binary spec](https://webassembly.github.io/spec/core/binary/).

Scope: exactly what `comptime/runtime/wasm.zig:buildScript` emits today. That subset is small:
- module / func declarations
- i32, i64, f32, f64 locals + constants
- i32/i64/f32/f64 arithmetic (`add`, `sub`, `mul`, `div_s`, `div_u`, `rem_s`, `rem_u`)
- memory instructions (`i32.load`, `i32.store`, `i32.store8`)
- `call`, `local.get`, `local.set`, `i32.const`, `drop`
- WASI `fd_write` import
- A `data` section for string constants
- A `memory` declaration and `export "memory"`
- A `_botopink_main` exported function

Anything outside this subset returns `error.UnsupportedWatFeature`. The set is closed and intentionally small — we control both ends.

Unit tests pin every opcode the emitter uses:

```
wat ---- module with i32.const literal printed via fd_write
wat ---- i32 add of two literals via fd_write
wat ---- string constant in data segment + memcpy via memory.fill
wat ---- two iovecs in fd_write
wat ---- f64 multiplication
wat ---- mod / rem_s
```

Cross-check: every test fixture's `wat_to_wasm(wat)` output is byte-compared against the canonical output of `wabt`'s `wat2wasm` CLI (run ONCE during test authoring; the bytes are committed as a snapshot).

F1 exit gate: 25/25 fixture-pairs equal byte-for-byte against the wabt canonical output. wasm3 not yet involved.

---

## F2 — `wasm3_host.zig`: env singleton + WASI shim + `runWat`

**Files**: `modules/compiler-core/src/comptime/runtime/wasm3_host.zig` (NEW, ~250 LOC), `tests/wasm3_host.zig` (NEW, ~6 tests).

Public surface:

```zig
/// Convert `wat_bytes` to binary WASM via `wat_to_wasm.compile`, instantiate
/// in the process-lifetime wasm3 environment, call `_botopink_main`, capture
/// all bytes written to fd 1 via `wasi_snapshot_preview1.fd_write`, return.
pub fn runWat(allocator: std.mem.Allocator, wat_bytes: []const u8) ![]u8;

/// Pre-spawn / pre-init for the warmup test. Idempotent.
pub fn warm(allocator: std.mem.Allocator) !void;
```

Internals:

1. **Environment singleton.** `IM3Environment` created on first call, spinlock-guarded init (same pattern as `getStdlibTemplate`). Lives until process exit.
2. **WAT → WASM** via `wat_to_wasm.compile(allocator, wat_bytes)`.
3. **Per-call runtime.** `m3_NewRuntime(env, 64 * 1024, null)` per request — fresh memory, no cross-call state.
4. **WASI shim.** One host function: `wasi_snapshot_preview1.fd_write`. Reads iovecs from the module's linear memory, appends to a per-call `ArrayList(u8)` (the capture buffer). Returns `0` (success) WASI error code. Other WASI imports (`proc_exit`, `environ_get`, `args_get`, …) are stubbed to no-op + return `0`.
5. **Call & capture.** `m3_FindFunction("_botopink_main")` → `m3_CallV(...)`. On `m3Err_trapExit` with code 0 → clean. Other traps → return `error.WasmTrap` (the caller falls back to … nothing in this scope; we own the path).
6. **Cleanup.** Free the runtime; env stays.

Unit tests:
```
wasm3-host ---- WAT printing a literal returns those bytes
wasm3-host ---- WAT printing two iovecs returns concatenated bytes
wasm3-host ---- 100 sequential calls reuse env, no leak
wasm3-host ---- module with unimported WASI fn returns MissingImport
wasm3-host ---- trap mid-execution returns WasmTrap
wasm3-host ---- two threads calling concurrently serialise via spinlock
```

F2 exit gate: 6/6 tests green. `wasm3_host` is a self-contained module with no callers yet outside its tests.

---

## F3 — Unify comptime runtime: delete node/erlang/beam, dispatch via wasm3

**Files**:
  - `modules/compiler-core/src/comptime/eval.zig` (MUTATED).
  - `modules/compiler-core/src/comptime/runtime/node.zig` (DELETED).
  - `modules/compiler-core/src/comptime/runtime/erlang.zig` (DELETED).
  - `modules/compiler-core/src/comptime/runtime/beam.zig` (DELETED).
  - `modules/compiler-core/src/comptime/runtime/wasm.zig` (MUTATED — `run()` calls `wasm3_host.runWat`).
  - `modules/compiler-core/src/comptime/tests/`* — adjust any test that referenced the deleted runtimes.

The `Runtime` enum disappears. `eval.evaluate` shrinks to:

```zig
pub fn evaluate(
    allocator: std.mem.Allocator,
    io: std.Io,
    entries: []const ComptimeEntry,
    build_root: []const u8,
) !RunResult {
    return wasm.run(allocator, io, entries, build_root);
}
```

The call sites of `eval.evaluate` (in `comptime.zig`, `codegen.zig`, …) all lose the `runtime: Runtime` argument. The codegen `Config.comptimeRuntime` field also goes — replaced by nothing.

The 4 backends' codegen output (`codegen/commonJS.zig`, `codegen/erlang.zig`, `codegen/wat.zig`, `codegen/beam_asm.zig`) **stays** — they render the value (returned as `[]const u8` per id by the unified eval) into the target backend's literal syntax. That rendering is pure Zig string formatting and needs no runtime. Snapshot output for codegen tests does NOT change: the generated JS/Erlang/WAT/BEAM still spells `3` as `3` in each language's syntax.

F3 exit gate: `zig build test` passes. Codegen snapshots byte-identical (the comptime VALUE didn't change; only its EVALUATOR did). Three runtime files are gone. `Runtime` enum is gone.

---

## F4 — Remove wasmtime spawn paths

**Files**: `modules/compiler-core/src/codegen/runtime.zig` (`executeWat` at line 272).

Replace the `std.process.run({"wasmtime", wat_filename})` with `wasm3_host.runWat(allocator, wat_code)`. Remove the now-dead temporary-file write. The `_botopink_main` export presence check stays (treat missing-export the same way: return `""` so the RUN LOG snapshot is empty).

F4 exit gate: `grep -r wasmtime` returns matches only in `CHANGELOG.md` historical entries + `AGENTS.md` deprecation note. No source file spawns `wasmtime`.

---

## F5 — Remove `persistent_erlang.zig` + escript runner

**Files**: 
  - `modules/compiler-core/src/comptime/runtime/persistent_erlang.zig` (DELETED).
  - `modules/compiler-core/src/comptime/runtime/persistent_erlang_runner.escript` (DELETED — was a sibling generated file; verify exact path before delete).
  - `modules/compiler-core/src/comptime.zig` — `warmPersistentErlangRunner` deleted, replaced by `warmWasm3Runtime`.
  - `modules/compiler-core/src/test_warmup.zig` + `modules/language-server/src/tests/_warmup.zig` — replace the erlang warmup test with a wasm3 warmup test.

F5 exit gate: `grep -r persistent_erlang` returns zero matches outside `CHANGELOG.md`.

---

## F6 — Warm + integration test sweep

**Files**: `comptime.zig:warmWasm3Runtime` + warmup tests.

`warmWasm3Runtime(io, gpa)`: calls `wasm3_host.warm(gpa)` which lazy-inits the env and compiles a trivial WAT (`(module (func (export "_botopink_main")))`) once. Sub-millisecond cold init (wasm3 is interpreter-only — no JIT spin-up cost) but the warmup keeps the first real test's row in the `--time-report` honest.

Integration sweep:
- `zig build test` — full suite green.
- `zig build test --time-report` — no test row > 5ms attributable to comptime evaluation (templates / decorators still hit persistent_node and stay where they are).
- `strace -f -e trace=execve zig build test 2>&1 | grep -E "wasmtime|erlc|escript"` — zero matches. (`erl` may still appear from `executeErlang` / `executeBeamAsm` — those are codegen execution paths, NOT comptime, and out of this spec.)

F6 exit gate: above three green.

---

## F7 — Docs + status sweep

**Files**:
  - `comptime/runtime/AGENTS.md` — rewrite the "Four-runtime architecture" paragraph to "Single wasm3 runtime", list `wat_to_wasm.zig` + `wasm3_host.zig`.
  - `comptime/runtime/docs.md` — same narrative.
  - `AGENTS.md` (repo root) — Build & test section: remove `wasmtime`, `erl`, `erlc`, `escript` from required PATH. Mention `wasmtime` as optional for human WAT inspection (`wasmtime run <file>.wat` still works on dev boxes that have it).
  - `CHANGELOG.md` — entry under `Changed (wasm3-unified-runtime)`.
  - `tasks/v0.beta.21/status.md` — row → done.

---

## Test scenarios

```
wat→wasm ---- every opcode the emitter uses round-trips byte-equal vs wabt's wat2wasm
wat→wasm ---- unsupported opcode → UnsupportedWatFeature
wasm3-host ---- runWat captures fd_write bytes
wasm3-host ---- env singleton reused across 100 calls
wasm3-host ---- WASI fd_write with 2 iovecs concatenates correctly
unified-runtime ---- comptime val 1+2 produces "3" via wasm3 (was: 4 lowerings, 4 runtimes)
unified-runtime ---- comptime val "He" + "llo" produces "Hello"
unified-runtime ---- existing codegen snapshots byte-identical (commonJS/erlang/wat/beam all still spell value '3' in their syntax)
removal ---- grep wasmtime/erlc/escript in source returns 0 matches
removal ---- node + erl no longer needed for `zig build test` (templates/decorators still hit Node — follow-up spec)
build ---- Linux + macOS + Windows compile + link wasm3 C sources without warning
```

## Notes

- **Why pure-Zig wat→wasm instead of vendoring `wabt`?** `wabt` is well-engineered C++ but ~50K LOC and brings a C++ toolchain into the Zig build. The subset we need is tiny (~600 LOC). The implementation is mechanical (binary spec section by section). Owning the converter means the build is pure Zig+C, never C++.
- **Why no QuickJS-WASM bundling?** Out of scope here. Templates and decorators stay on Node for this spec — handled by the follow-up `templates-decorators-botopink-native.md`. This separation lets this spec ship in days, not weeks.
- **Why delete `persistent_erlang` but keep `persistent_node`?** After this spec lands, the **only** remaining Node consumer is `template_eval.zig` + `decorator_eval.zig`. Those need a real JS engine (they execute user-written JS). Erlang, by contrast, had ZERO consumers outside the comptime val backend we just deleted. `persistent_node` survives this spec by exact analogy.
- **The four-runtime architecture's testing value.** Today, having node + erlang + wasm + beam all evaluate the same expression gives a cheap oracle that no single backend's eval is wrong. After this spec, that oracle is replaced by: **wasm3 is the single source of truth**, and each codegen backend's rendering of the value is unit-tested via the existing codegen snapshot tests (`commonJS.zig`, `erlang.zig`, `wat.zig`, `beam_asm.zig` snapshots already cover the literal-to-target-syntax path). Net loss: zero coverage; net gain: dev-loop simplicity.
- **Wasm3 maturity.** Used in production by Apple, Intel automotive, Shopify Functions (early), various IoT vendors since 2019. ~50KB binary, no allocator surprises, no JIT (deterministic startup), interpreter-only (consistent perf across all CPU architectures).
- **Out of scope (separate v0.beta.21 specs):**
  - **`templates-decorators-botopink-native.md`** — the natural follow-up. Migrates `template_eval.zig` and `decorator_eval.zig` off Node by completing the WAT backend so it can compile template/decorator bodies. After that ships, `persistent_node.zig` is deleted and Node is no longer a compiler dependency at all.
  - `template-static-fold.md` — orthogonal optimisation (constant-fold simple templates at AST level, never invoke any eval).
  - Codegen-execution path (`codegen/runtime.zig:executeJavaScript`, `executeErlang`, `executeBeamAsm`) — these run the GENERATED user program for RUN LOG capture in snapshots. They're separate from comptime evaluation. `executeWat` switches to wasm3 in this spec (F4); the JS / Erlang / BEAM ones stay where they are.
- **Exit gate (full spec):**
  - `Runtime` enum deleted from the codebase (`comptime/eval.zig`).
  - `wasmtime`, `erlc`, `escript` no longer required for `zig build test`.
  - All comptime val expressions in the test suite produce byte-identical outputs to v0.beta.20.
  - `vendor/wasm3/` directory committed with pinned upstream version + LICENSE.
  - `wat_to_wasm.zig` unit tests green; cross-validated against `wabt` for the supported subset.
  - `AGENTS.md` per affected module updated in the same commit as code.
  - Full suite green on Linux + macOS + Windows.

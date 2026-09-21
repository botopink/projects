# The browser build of compiler-core

What a `wasm32` build of the compiler needs, where the compiler uses what wasm does not have, the
host interface, the JS glue, the demo, and the budget. Measured 2026-09-20
([`evidence.md`](./evidence.md) E-11, E-10).

## 1. What exists

`src/root.zig` is the library root; `codegen.generate(allocator, modules, io, config)`
(`codegen.zig:44`) takes `[]const Module{ path, source }` and returns `ModuleOutput`s with the
generated text — the compiler's API is *bytes in, text out*. The CLI (`modules/compiler-cli`) does
the file walking, `botopink.json`, and the process spawns. Nothing in the tree builds for wasm today:
`build.zig` has no `wasm32` target, `libcResolvedTarget` (`:398-407`) pins glibc for linux-gnu and
passes every other target through unchanged.

## 2. Where compiler-core touches the OS

Census over `src/**/*.zig`, test files excluded (E-11):

| `std` surface | Files | Sites | Needed in the browser? |
|---|---|---|---|
| `std.process.*` (spawn, run, Child) | `codegen/runtime.zig`, `comptime/runtime/persistent_erl.zig`, `utils/snap.zig` (env var read) | 9 | **no** — RUN LOG executors, the erl child, the test env |
| `std.fs.*` (path join) | the same 3 | 9 | no |
| `std.Io.Dir.cwd()` (read/write/rename/delete/access) | the 3 above + `comptime/template_eval.zig` (`ensureModule`/`writeModule`, `:218-243`) | 27 | no — `.botopinkbuild/tmp/` module files, RUN LOG scratch dirs, snapshot files; the `.beam`/wasm bytes of steps 1–2 never touch disk |
| `io.random` | `runtime.zig`, `persistent_erl.zig`, `template_eval.zig` | 3 | no (staging nonces) |
| `std.time.*` | `runtime.zig`, `persistent_erl.zig` | 2 | no (spawn timeouts) |
| `std.Thread` | `codegen/erlang.zig:240` (`yield` in a spin), `comptime.zig:442` (a comment), `persistent_erl.zig` tests | 4 | no — `std.Thread.yield` on wasm32 single-threaded is a no-op or absent; replace the spin's `yield` with `std.atomic.spinLoopHint()` as `comptime.zig:445` already does |
| `std.heap.page_allocator` | `erlang.zig:230`, `template_eval.zig`, `comptime.zig`, `persistent_erl.zig` | 8 | works on wasm32 (`memory.grow`) |
| `std.posix` | `utils/snap.zig:127` | 1 | no (tests) |

Everything OS-bound is in **four files**, all on the comptime-runtime or RUN-LOG path this front
owns. The checker, parser, formatter, the four emitters and `eval.zig` are pure. That is the
measured reason the browser build is feasible without touching the language.

## 3. Target triple

| | `wasm32-wasi` | `wasm32-freestanding` |
|---|---|---|
| Zig `std.Io` | the WASI implementation of `std.Io` exists for files/clock/random through `wasi_snapshot_preview1`; **whether Zig 0.16's new `std.Io` interface is complete for `wasm32-wasi` is not verified here** (no wasm build was attempted; step 5's first task) | no `std.Io` backing; every `io.*` call the core makes (`std.Io.Dir.cwd()` in the 4 files, `io.random`) must be compiled out or given a custom `Io` |
| stdout/stderr | `fd_write` | a custom import |
| clock, random | `clock_time_get`, `random_get` | custom imports |
| process spawn, threads | absent — good | absent |
| JS side | a WASI shim (`@bjorn3/browser_wasi_shim` or ≈ 200 lines: `fd_write`, `clock_time_get`, `random_get`, `proc_exit`, `environ_*`, `args_*`, `fd_fdstat_get` on 1/2) | a hand-written import object |
| size | + the WASI libc-less start code (small; Zig's `std` for wasi is not libc) | smallest |

**Recommendation: `wasm32-wasi`**, so the four OS-touching files can stay compiled (behind
`if (runtime.active == .beam)` / `if (!builtin.cpu.arch.isWasm())`) and the rest of `std.Io` keeps
working unchanged; the shim is a known quantity. If Zig 0.16's `std.Io` proves incomplete on wasi,
fall back to `wasm32-freestanding` with a `std.Io` implementation over the same five imports —
that is the trade-off to record after step 5's first build, not before.

## 4. What is compiled out

```zig
// src/comptime/runtime/runtime.zig
pub const active: ComptimeRuntime = if (builtin.cpu.arch.isWasm()) .wat else build_options.comptime_runtime;
// every persistent_beam.* reference sits behind `if (active == .beam)` — comptime-false on wasm,
// so persistent_beam.zig is never analysed and std.process never resolves
```

- `codegen/runtime.zig`: not referenced when `generateWith(…, .{ .execute = false })` is the only
  caller (`codegen.zig:93` gates the executors); the wasm build passes `execute = false` and the
  file is dead code the compiler drops.
- `comptime/template_eval.zig` `ensureModule`/`writeModule`: dead after step 1a (bytes in-frame)
  and step 2 (bytes in memory); deleted, not gated.
- `utils/snap.zig`: test-only, not in `root.zig`'s reachable set.
- `persistent_wat.zig`'s executor: on native, wasm3; on wasm, a host import (§ 5) — a nested
  `WebAssembly.instantiate` cannot be done from inside wasm without the host.

## 5. The host interface

The compiler wasm imports, beyond WASI's five:

```
bp_host.run_module(wasm_ptr: i32, wasm_len: i32, arg_ptr: i32, arg_len: i32, out_ptr_ptr: i32, out_len_ptr: i32) -> i32 (status: 0 ok, 1 refused, 2 trapped)
```

The glue instantiates the comptime module's bytes with `{ wasi_snapshot_preview1: { fd_write } }`
(the one import § 1 of [`wat-runtime.md`](./wat-runtime.md) measured), copies `arg` into its memory,
calls `main`, copies the reply back into the compiler's memory (allocating through an exported
`bp_alloc`), returns the status. Synchronous: `WebAssembly.Module`/`Instance` constructors are
synchronous for small modules (< 4 KB in the main thread is allowed; a comptime module is ≈ 1–3 KB
by the `.beam` analogue — the size limit for synchronous compilation on the main thread is a
browser policy, so the glue runs the compiler in a **Worker** where it does not apply).

What the compiler needs from the host, and how each arrives:

| Need | Native | Browser |
|---|---|---|
| source files | the CLI reads them | handed in as `Module{path, source}` via an exported `bp_add_source(path_ptr, len, src_ptr, len)`; a virtual project, no fs walk — `project_graph.zig`'s `botopink.json` reading lives in the CLI/LSP, not the core |
| `libs/std` sources | embedded (`std_prelude` module, `build.zig:25-82`) | the same embedding — already in the binary |
| clock | `std.Io` | WASI `clock_time_get` via the shim |
| stdout/stderr | inherited | `fd_write` → `postMessage` to the page |
| comptime execution | wasm3 in-process | `bp_host.run_module` |
| process spawn | `erl`, `node`, `wasmtime` | none; `execute = false` |

## 6. The JS glue and the demo

`modules/compiler-web/`:

```
compiler-web/
├── build.zig            `zig build -Dtarget=wasm32-wasi compiler-web` → zig-out/web/botopink.wasm
├── src/web_root.zig     exports: bp_alloc, bp_free, bp_add_source, bp_compile(target: u8) → (ptr,len) JSON of ModuleOutputs
├── glue.js              WASI shim + bp_host.run_module + a Worker wrapper; ≈ 300 lines, no dependency
├── index.html           an editor textarea, a target select (commonJS | wasm | erlang | beam), output panes
└── AGENTS.md
```

The demo program has a decorator **and** a template (the two runtime-evaluated forms), compiles to
`commonJS` and to `wasm`; the `wasm` output is instantiated in the page and its `RUN LOG` shown —
the target program running in the browser beside the compiler that produced it. The `erlang`/`beam`
targets compile and show text; they do not run (no VM in the page — the README's *Notes*).

Acceptance (README step 5): no network request after `botopink.wasm` and `glue.js` load, the
`COMPTIME REPLY` of the decorator and the template equal to the native build's.

## 7. Size and time budget

| | Baseline | Budget |
|---|---|---|
| native CLI binary | not built in this checkout (`zig-out/` absent — E-12); measure in step 0 with `zig build` then `ls -la zig-out/bin/botopink` | — |
| `botopink.wasm` | — | ≤ 8 MB uncompressed, ≤ 2.5 MB gzip; `-OReleaseSmall`, `--strip`, no `std.debug` on wasm; the embedded `libs/std` sources are the known fixed cost (measure: `du -b libs/std/src`) |
| instantiate + compile a 20-line program | — | ≤ 300 ms in a Worker on a laptop; the comptime module's instantiate is ≈ 1 ms |
| build time | — | the wasm build is one more `zig build` step; CI adds one job |

Numbers in the *Budget* column are targets to hold the first measurement against, not measurements.

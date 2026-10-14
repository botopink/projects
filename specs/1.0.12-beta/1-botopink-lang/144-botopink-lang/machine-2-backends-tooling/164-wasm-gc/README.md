# Front 164 — wasm-gc: the comptime runtime on wasmtime, the wasm target on WasmGC, std-wasm in botopink and `.wat`

**Priority:** maximum — where new development is centred (the maintainer, 2026-10-14); beside 144, the second front that
edits `repository/botopink-lang` (amends 433). Opens after 144's B-00 group (done but its last box, which holds
nothing back, 479).
**Repository:** botopink-lang — worktree `--lang`. **Machine:** 2 — the backends-and-tooling machine runs this front,
in a `--lang` worktree of its own, ahead of every other open step of 144 it holds. **Model:** opus (every step designs or
changes a runtime).
**Gate:** standard (fronts.md § Gate) + every wasm `run/` cell's `.out` and every comptime snapshot unchanged at
each step — the engine and the memory are never a source of text (434 (5)).
**Owns:** `modules/compiler-core/src/comptime/runtime/**`, `modules/compiler-core/src/codegen/wat/**`,
`modules/{std-wasm,wasm3,beam-to-wasm}/**`, `modules/compiler-web/**`, `build.zig`'s wasm and engine steps,
`.github/workflows/release.yml`'s engine fetch; the wasm column of every cell. 144 keeps the rest of the repository;
a 144 step that reaches the wasm target, the comptime runtime or std-wasm waits on this front's s2, never edits them.
**Depends on:** nothing open. **Decisions:** 543 (wasmtime-a), 544 (wasmgc-a); amends 434, 440, 448, 449,
450, 452, 522; 518 (`needs`) and 392 (the scheduler) unchanged.

Until s2 lands a wasm program allocates as today (a bump heap, exhaustion a trap, 448 (4)) — a known limit of a long
task, written in the reference. The old model's steps are withdrawn: 144 B-30's open boxes, B-25's steps 9 and 11,
the linear-memory rows (B-22-c, B-25-d).

## Alias table

Old ids stay valid in `decisions-taken.md`'s *Where* column and the closed records: each resolves here.

| Old id | Step here |
|---|---|
| 144 B-82 | 164 s1 |
| 144 B-83 | 164 s2 |
| 144 B-84 | 164 s3 |
| 144 B-85 | 164 s4 |
| 144 B-30 box 3 (the program's `alloc` on `heap.zig`) | withdrawn — 164 s2 |
| 144 B-25 steps 9 and 11 (a prebuilt wasm library) | withdrawn as written — a question of 164's once s2 lands |

## Steps

### s1 — the comptime runtime's engine: wasmtime embedded, wasm3 removed (the maintainer, 2026-10-14; question wasmtime-a)

**Repository:** botopink-lang (`--lang`) · **Model:** opus · **After:** 144's B-00 group (479: its last box holds nothing back)

The comptime runtime's engine is the host's (wasmtime-a): wasmtime in the native compiler through its C API, the
page's `WebAssembly` in `compiler-web` as today (`bp_host`); wasm3 goes. std-wasm, the comptime module, its link and
every comptime answer are unchanged (440, 450): the same wasm, compiled instead of interpreted.

- [x] **the engine behind one interface** in `comptime/runtime/persistent_wat.zig`: compile and instantiate a linked
      comptime module, register the host imports (`env.bp_term_alloc`, `env.bp_term_static`, `env.bp_call<N>`, the
      `@embed` reader, every other `env.*` the module imports), call, read and write the module's memory, a trap an
      error — the same contract `compiler-web`'s `bp_host.run_module` serves, so the two engines are one interface
- [x] **wasmtime's C API** fetched by `build.zig.zon`, one prebuilt library per release target (`linux-{x86_64,aarch64}`,
      `macos-{x86_64,aarch64}`, `windows-x86_64`), pinned by hash, linked into `botopink` and `botopink-lsp`; no cargo
      in the toolchain; `release.yml` and `test.yml` fetch nothing more than `zig build` does
- [x] **wasm3 removed:** `modules/wasm3/` deleted, `build.zig`'s `link` / `exposeHeaders` and compiler-core's `@cImport`
      gone; `comptime/runtime/AGENTS.md` limit 1 (a runaway body) re-read for wasmtime (epoch interruption makes a
      Ctrl-C land; no budget, 380 (2))
- [x] **what wasm3 lacked is no longer refused at build:** exception handling (518) on — `attempt` in a decorator, a
      template or a `comptime` answers as in a wasm program, a cell proving it; any other refusal that stood only on
      wasm3's missing feature found and removed, each with its cell
- [x] **start-up measured:** a build with many small comptime modules (jhonstart's `html`, styled) before and after; the
      compiled-module cache under `.botopinkbuild/build/` (B-77's place) or Pulley chosen by the measurement, written
      in `comptime/runtime/AGENTS.md`, never a flag (67)
- [x] every comptime snapshot and every conformance cell unchanged — the answers are std-wasm's, the engine is not a
      source of text (434 (5)); `compiler-web`'s smoke test green
- [x] docs: 434 amended in the reference's "Decided" table; root `AGENTS.md` ("wasm3 inside the compiler",
      § The comptime runtime), `modules/AGENTS.md` (the wasm3 row), `compiler-core/src/comptime/runtime/AGENTS.md`,
      `compiler-web/AGENTS.md`

**Impacted tests:** every comptime snapshot (unchanged), `test-conformance`, `test-web`, `release.yml`'s five targets.
**Consumer commits:** none.

Measured (12 builds — jhonstart's 8 examples, styled's 4; the `instance` + `run` stages): wasm3 163–189 ms; wasmtime
cold 1.0–1.3 s; Pulley 1.5 s; wasmtime with the compiled-module cache under `.botopinkbuild/build/comptime/` warm 48 ms —
the cache is the choice. The binary grows from 53 MB to 74 MB; an artifact linking wasmtime on Linux links with LLD.
Open points: question 543-a.

### s2 — the wasm codegen emits WasmGC: every value a GC struct or array, no linear-memory value (the maintainer, 2026-10-14; wasmgc-a)

**Repository:** botopink-lang (`--lang`) · **Model:** opus · **After:** s1 (the engines run WasmGC; wasm3 did not)

The program's memory is the host's collector (wasmgc-a): wasmtime's and the browser's. The wasm codegen stops laying
values out in linear memory and emits WasmGC types; 522's own heap is never wired (B-30 closed as superseded).

- [ ] **the types:** one GC type per value shape — string (an `i8` array), array, tuple, record, enum and variant,
      closure, `@Task` record, `Dict` — declared in the module's type section; `unknown` a reference to any of them;
      `Bytes` an `i8` array (346); a value never has an address
- [ ] **the operations:** construction, field read, array get and length, comparison and `@print`'s text over GC
      values; the `wat_prelude` keeps representation, operators, output and runtime (442) in GC form; `alloc` and
      every linear-memory helper gone from the program
- [ ] **tasks and the scheduler** (392) over GC records: a settled value is shared, never copied (immutable); a
      mutable cell a GC struct with one mutable field; no heap per task, no copy at a send, no cycle to detect (the
      host's collector follows cycles)
- [ ] **`needs: [.Gc]`** (518) on every program emitting GC types — wasmtime `-W gc=y`, node and the browser by default
- [ ] **every `run/` cell's `.out` on wasm unchanged**; a long-running cell (a loop of 10M allocations, a recursion
      without a loop, a request loop) whose memory stays bounded; `std_wasm.wasm` still linked for the std's functions
      until s3 — values crossing into it marshalled at the boundary, measured, the boundary deleted by s3
- [ ] docs: 448, 449, 522 amended in the reference's "Decided" table (the program's memory is the host's);
      `codegen/wat/AGENTS.md`, `modules/std-wasm/AGENTS.md` § The heap (superseded)

**Impacted tests:** every wasm snapshot and `run/` cell; `test-libs` wasm column; `test-web`. **Consumer commits:** none.

### s3 — std-wasm rewritten: its logic in botopink, its leaves in hand-written `.wat`; `std_wasm.wasm`, `heap.zig` and beam-to-wasm deleted (the maintainer, 2026-10-14; wasmgc-a)

**Repository:** botopink-lang (`--lang`) · **Model:** opus · **After:** s2

- [ ] **the logic in botopink:** string, array, Dict, hash, Unicode (its tables build constants by `@embed`, 519),
      number text (441), the Erlang-term functions the comptime still needs — `.bp` modules of std compiled by the
      compiler itself, module by module, each module's cells green before the Zig function it replaces is deleted
- [ ] **the leaves in `.wat`:** `modules/std-wasm/wat/`, one file per leaf or small group, named functions, comments —
      a byte read or written, a GC array made, a float's text, what no `.bp` form reaches —, each function bound by a
      `std:` cell, proved by a conformance cell on the four targets, within 442's scope; no wat inside Zig, no wat
      generated for a fixed leaf (Zig builds `wat_ast` only where emission is parametrized: the codegen, `wat_prelude`)
- [ ] **the `.wat` reader:** the compiler reads a `.wat` file into its `wat_ast` — a reader of its own (s-expressions),
      no tool — and transpiles it as 440 transpiles std-wasm today; a `.wat` that does not read is a located error
- [ ] **deleted at the end:** `modules/std-wasm/src/*.zig` (`std_wasm.wasm`, `heap.zig`, the term library) and
      `modules/beam-to-wasm/` (452's standalone utility, built on the own heap, used by no botopink build); `zig build
      std-wasm` goes; `modules/std-wasm/` holds `wat/` alone
- [ ] every comptime snapshot and every conformance cell unchanged — one text on every target (434 (5))
- [ ] docs: 440, 450, 452 amended in the reference's "Decided" table; root `AGENTS.md`, `modules/AGENTS.md`,
      `modules/std-wasm/AGENTS.md`, `libs/std/AGENTS.md`

**Impacted tests:** every comptime snapshot (unchanged), `test-conformance`, `test-libs`, `test-web`. **Consumer commits:** none.

### s4 — Conformance, the front's last step (decisions 459, 474, 477, 478, 479, 480)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

After s1, s2 and s3 have landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the group landed (477): `scripts/gate.sh` with conformance, every cell on
      every target it declares; a red reproduced locally, fixed at once (430), pushed again; no cell edited to match
      the compiler
- [ ] for each red, the cheap test the hook already runs that would have caught it, red on the breaking commit and
      green on the fix (478) — or the report says why none can
- [ ] the group's changes analysed together against the cells (a table here); the cells they call for written in
      decision 457's shape (a bounded long task, an `attempt` at build, a `.wat` leaf's answer on four targets); the
      missing ones proposed as rows


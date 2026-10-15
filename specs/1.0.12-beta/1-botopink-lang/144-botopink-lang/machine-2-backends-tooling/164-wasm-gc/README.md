# Front 164 — wasm-gc: the comptime runtime on wasmtime, the wasm target on WasmGC, std-wasm in botopink and `.wat`

**Priority:** maximum — where new development is centred (the maintainer, 2026-10-14); beside 144, the second front that
edits `repository/botopink-lang` (amends 433). Opens after 144's B-00 group (done but its last box, which holds
nothing back, 479).
**Repository:** botopink-lang — worktree `--lang`. **Machine:** 2 — the backends-and-tooling machine runs this front,
in a `--lang` worktree of its own, ahead of every other open step of 144 it holds. **Model:** opus (every step designs or
changes a runtime).
**Gate:** standard (fronts.md § Gate) + every wasm `run/` cell's `.out` and every comptime snapshot's `COMPTIME REPLY` unchanged
at each step — the engine and the memory are never a source of text (434 (5)); a step that rewrites the comptime's
lowering re-records its `COMPTIME WAT` once per piece and reads the diff (decision 558).
**Owns:** `modules/compiler-core/src/comptime/runtime/**`, `modules/compiler-core/src/codegen/wat/**`,
`modules/{std-wasm,beam-to-wasm}/**`, `modules/compiler-web/**`, `build.zig`'s wasm and engine steps,
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
- [ ] **wasm3 gone from the tree** (the maintainer, 2026-10-15): no mention left in botopink-lang — the comments in
      `comptime/runtime/persistent_wat.zig` (the stack bound's two), `comptime/runtime/wat/lower.zig` and
      `comptime/tests/templates.zig`; the headers of the cells `comptime_attempt_at_build`,
      `comptime_deep_structure_equality` and `decorator_lambda_many_locals` (each states its answer, not the engine that
      once failed it); `comptime/runtime/AGENTS.md` (the engine table's wasm3 row and its prose), `runtime/wat/AGENTS.md`,
      `comptime/tests/AGENTS.md`; `git grep -iw wasm3` empty but `decisions-taken.md`

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

Order (each piece keeps every cell's answer; a module not yet lowerable in GC form falls back to the linear lowering,
deleted at P5): P0 a value representation (`Repr`) in place of the type strings, the two modes · P1 the GC core —
strings, the printers, the std-wasm boundary (an arena reset after each call, deleted by s3) · P2 arrays, tuples,
optionals, records and variants (one struct type per declaration), `case`, `unknown`, `Bytes`, `Dict` (scalars boxed
inside `anyref`, never `i31ref`) · P3 closures, `var` cells, components · P4 tasks · P5 the linear lowering deleted ·
P6 the bounded-memory cells and the docs. P6 follows decision 555: the codegen breaks its own cycles (a settled task drops its waiters and frame), the gate
pins the wasmtime CLI beside the C API, and a cycle a program builds may live until exit on wasmtime.

Landed: P0, P1, P2, P2b (`unknown`, `Dict`, generic records and enums, the arrays' and `@Result`'s methods, union
arrays, generators) and P3 (function values, closures, fn refs, `var` captures, components; generic static methods, a
float, array or function value in a type-parameter slot, `==` over a generic record whose type arguments are written, a
`yield` ending a `case` arm, a `try` inside a generator over a `@Result`, a function value in `unknown`) — 538 GC
modules of 1399. A function value is `$closure {idx, mark}`, each lifted lambda a subtype `$env<n>` with one mutable
field per capture, called through one boxed table entry per arity; a component is `scope_carry`'s `fn(unknown) ->
unknown` lambda. Left to the linear lowering: a tuple in a type-parameter slot (question 164-s2-a), `==` over a generic
record whose type arguments are not written (164-s2-b), a `try` inside a generator whose item is no `@Result`, a block
or `case` value typed apart from its function (`{ yield 5; 6 }`), a component that awaits (P4), and the refusal of a
generic body reached with nothing bound, which the GC lowering answers as commonJS does (`Box(n)`) — lifted with P5.
Writing a type-parameter field is lowered but no cell reaches it.

- [ ] **the types:** one GC type per value shape — string (an `i8` array), array, tuple, record, enum and variant,
      closure, `@Task` record, `Dict` — declared in the module's type section; `unknown` a reference to any of them;
      `Bytes` an `i8` array (346); a value never has an address
- [ ] **the operations:** construction, field read, array get and length, comparison and `@print`'s text over GC
      values; the `wat_prelude` keeps representation, operators, output and runtime (442) in GC form; `alloc` and
      every linear-memory helper gone from the program
- [ ] **tasks and the scheduler** (392) over GC records: a settled value is shared, never copied (immutable); a
      mutable cell a GC struct with one mutable field; no heap per task, no copy at a send, no cycle to detect (the
      host's collector follows cycles)
- [x] **`needs: [.Gc]`** (518) on every program emitting GC types — wasmtime `-W gc=y`, node and the browser by default
- [ ] **every `run/` cell's `.out` on wasm unchanged**; a long-running cell (a loop of 10M allocations, a recursion
      without a loop, a request loop) whose memory stays bounded; `std_wasm.wasm` still linked for the std's functions
      until s3 — values crossing into it marshalled at the boundary, measured, the boundary deleted by s3
- [ ] docs: 448, 449, 522 amended in the reference's "Decided" table (the program's memory is the host's);
      `codegen/wat/AGENTS.md`, `modules/std-wasm/AGENTS.md` § The heap (superseded)

**Impacted tests:** every wasm snapshot and `run/` cell; `test-libs` wasm column; `test-web`. **Consumer commits:** none.

### s2b — `defer` on wasm: every exit 539 (3) names (decision 539; found reviewing its build, 2026-10-14)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet · **After:** s2 (the same codegen)

539 landed on wasm with four gaps; each is a cell red on wasm (never a `snapshot/targets/` departure) until its box lands.

- [x] a panic in a block or `case` arm runs the arm's defers with exceptions on — today a panic region covers
      statement lists and the function's own body only
- [x] a `defer` inside an inlined higher-order lambda, or an `if` branch answering a value, built — today refused on
      wasm with a located error no decision states
- [x] a `val` shadowing, after the `defer` in the same block, a name the deferred code reads: the deferred code reads
      the binding in scope at the `defer` (names bind there, only the value is read late — 539's amendment)
- [x] a deferred statement that panics on an inline exit path inside an enclosing region runs once (`attempt` around
      a `return` with a panicking inner defer)
- [ ] question 539-b's answer: a `defer` and the program's `needs`

### s2c — 537 and 541 on wasm (found reviewing their build, 2026-10-14)

**Repository:** botopink-lang (`--lang`) · **Model:** sonnet · **After:** s2

Each box a cell on every target, out on wasm (never a `snapshot/targets/` departure) until it lands.

- [x] `continue` inside a block or a `case` arm in a loop builds (today `compilation failed UnknownName`); cell
      `block_continue_reaches_loop`
- [x] `await tasks[1]!` on an array of tasks answers the task's value; a `[]!` line in `await_postfix_binds_tighter`
- [x] an abort's text (535): `@panic` / `@todo` / `assert` write `panic: <message>` — cell `abort_text_panic` on the four
      targets, its `message` binding removed (144 B-90)
- [x] an integer overflow and an integer division by zero write 527 (3)'s checked message (the operator, the type,
      `file:line:col`), not a bare trap — the site handed to every checked-arithmetic helper, in both lowerings (after
      s2 P2b, which reworks the same helpers); a cell on the four targets; under `attempt` the trap answers
      `Error(panic)` and the program goes on (492) — `int_division_by_zero_is_panic`'s wasm departure, which records
      the trap, deleted and the cell red on wasm until then, and an overflow line in `std_failure_attempt_abort_kinds`
      — the site a message argument on each checked call, raised through `panic_raise` when the module has
      exceptions; `abort_text_overflow` for the uncaught text
- [ ] `INT_MIN / -1` writes 527 (3)'s overflow message (today a bare trap), and a GC module with exceptions keeps the
      checked site in GC (today it falls back to linear memory for it) — a line in `abort_text_overflow`
- [ ] a field read on a record the module does not declare is placed (today refused: cannot place `.path`) — cell
      `embed_field_read_other_module` and `declared_field_read_other_module` on wasm, their `through` host binding and
      `targets` narrowing removed (144 B-95, B-97)
- [x] a loop's label read (`break :outer`, `continue :outer`) — cells `block_jump_label_reaches_loop`,
      `block_jump_label_continue_reaches_loop`, `block_jump_label_continue_nested_shapes`; a bare `return` in a yielding arm ends the generator, not the arm — cell
      `case_arm_return_in_yielding_arm` (144 B-88)
- [ ] `val f: ?f64 = 5.0; f?.toString()` answers `5.0` (today `0.0`) — a line in `optional_chain_string_text`
      (144 B-78's Conformance)
- [ ] emilia's module lowers on wasm: every emilia cell fails the narrowing audit, wasm refusing it with `type mismatch:
      expected i32, got void` rather than a missing host binding (measured before s2 too) — emilia's cells (in rakun,
      front 165) audited green, wasm then in their targets

### s3 — std-wasm rewritten: its logic in botopink, its leaves in hand-written `.wat`; `std_wasm.wasm`, `heap.zig` and beam-to-wasm deleted (the maintainer, 2026-10-14; wasmgc-a)

**Repository:** botopink-lang (`--lang`) · **Model:** opus · **After:** s2

Order (each piece keeps every wasm cell's answer and every comptime reply): P0 the `.wat` reader, the leaf table and a
`std:` cell naming a leaf (beside s2) · P1 `text.*` in botopink over leaves · P2 `array.*`, an integer's text,
`encoding.*`, `hash.contentHash`, `random.*` · P3 a float's text (one leaf), `bigint.*` in botopink · P4 the comptime
compiled straight by the GC backend, its Erlang layer and term library deleted (550) · P5 `io.fs` on `wasi:filesystem` (after s2 P4) · P6 the deletions and the docs. P1–P4
flip wasm once s2 P5 has deleted the linear lowering. A leaf names the codegen's GC types (549); a piece re-records its `COMPTIME WAT` and reads the diff (558); a dependency's function, std's included, is one line with its hash in every snapshot (558 (1)). Questions 164-s3-e, f, g.

Landed: P0 — the reader, the leaf table, `text.length` and `text.charCodeAt` as leaves; a `std:` name that is a leaf
with no std-wasm export has its signature check written but unexercised until P1 adds such a leaf. P1-a — the leaves
`text.byteLength`, `text.byteAt`, `text.byteSlice` and `text.fromCodepoint`, each with a twin std-wasm export of the
same name and types (a module that falls back to linear memory still builds); proved by a GC-module unit test on wasm,
since 445 refuses a `std:` cell outside `libs/std` — their cells on the four targets come with the `String` method
that binds them (P1-b, P1-c; questions 164-s3-e, f, g).

- [ ] **the logic in botopink:** string, array, Dict, hash, Unicode (its case tables generated by `gen-unicode` and embedded by `@embed`, 559 — `@embed` inside std reading std's files first, if it does not),
      number text (441), the comptime's preludes and reply codecs (550: no Erlang layer) — `.bp` modules of std compiled by the
      compiler itself, module by module, each module's cells green before the Zig function it replaces is deleted
- [ ] **the language's runtime in `.wat` (560), after s2 P5:** `wat_prelude.zig`'s functions (printing, panic and
      abort, comparison, the task scheduler, `bp_ready`, the `unknown` and `Dict` helpers) moved to hand-written `.wat`
      files read by the `.wat` reader; Zig keeps the GC type table and the choice of what a program links; the reader
      reads imports, the exception tag and globals; every cell's answer the same
- [ ] **the leaves in `.wat`, written by hand — no generator writes one (559):** `modules/std-wasm/wat/`, one file per leaf or small group, named functions, comments —
      a byte read or written, a GC array made, a float's text, what no `.bp` form reaches —, each function bound by a
      `std:` cell, proved by a conformance cell on the four targets, within 442's scope; no wat inside Zig, no wat
      generated for a fixed leaf (Zig builds `wat_ast` only where emission is parametrized: the codegen, `wat_prelude`)
- [x] **the `.wat` reader:** the compiler reads a `.wat` file into its `wat_ast` — a reader of its own (s-expressions),
      no tool — and transpiles it as 440 transpiles std-wasm today; a `.wat` that does not read is a located error
- [ ] `io.fs` importable on wasm: a module whose body calls a host function with no wasm binding builds, and only the
      call is refused (518 (4)); `io.fs` on `wasi:filesystem` (540, `needs: [.Filesystem]`) — today the whole module is
      refused (`std_fs_walk_root_spellings`' wasm departure), and the six `fs_*` cells of 540 leave wasm out
- [ ] **deleted at the end:** `modules/std-wasm/src/*.zig` (`std_wasm.wasm`, `heap.zig`, the term library) and
      `modules/beam-to-wasm/` (452's standalone utility, built on the own heap, used by no botopink build); `zig build
      std-wasm` goes; `modules/std-wasm/` holds `wat/` alone
- [ ] every comptime snapshot's `COMPTIME REPLY` and every conformance cell unchanged — one text on every target (434 (5));
      each piece's `COMPTIME WAT` re-recorded and its diff read against what the piece changes (558)
- [ ] docs: 440, 450, 452 amended in the reference's "Decided" table; root `AGENTS.md`, `modules/AGENTS.md`,
      `modules/std-wasm/AGENTS.md`, `libs/std/AGENTS.md`

**Impacted tests:** every comptime snapshot (the reply unchanged, the listing re-recorded by piece, 558), `test-conformance`, `test-libs`, `test-web`. **Consumer commits:** none.

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


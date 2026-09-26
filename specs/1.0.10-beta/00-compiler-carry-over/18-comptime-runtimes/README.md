# Front 18 — comptime runtimes: BEAM direct, WAT, and the browser build

**Track:** compiler (carry-over item **C-26**; absorbs **C-20**, landed by
[`14-comptime-on-beam`](../14-comptime-on-beam/README.md))
**State:** landed. No Erlang compiler is on the comptime path, a commonJS / typescript / wasm build
spawns no process for comptime, and compiler-core builds for the browser. Open: the CI matrix run
and the bench table (§ *Open*).
**Owns:** `src/comptime/runtime/**` (`server_source.zig`, `render_resident.zig`, `persistent_beam.zig`,
`persistent_wat.zig`, `wat/`, `runtime.zig` the dispatcher, `parity.zig`, `reply_order.zig`) ·
`src/codegen/beam/beam_file.zig` + `opcodes.zig` + `gen_opcodes.sh` ·
`src/codegen/wat/wasm_binary_emitter.zig` · the snapshot directory selection
(`src/codegen/snapshot.zig`, `src/comptime/snapshot.zig`, `src/utils/snap.zig`) · root `build.zig`'s
`render-resident` + `erlc` step and `compiler-web` build · `modules/compiler-web/**` ·
`modules/wasm3/**` · `scripts/comptime_bench.sh`
**Does not touch:** the run-time halves of `beam_asm.zig`, `erlang.zig`, `wat.zig`, `commonJS.zig`
(this front adds modes, never edits a typed lowering) · the libraries · `src/comptime/eval.zig` ·
`src/comptime/infer.zig`

Paths are relative to `repository/botopink-lang/modules/compiler-core/` unless they start with
`modules/`, `scripts/` or `.github/`, which are relative to `repository/botopink-lang/`.

---

## What holds

### The two runtimes, and who picks

**Decision 84: the comptime runtime follows the target's VM, beam by default.** `erlang` / `beam`
targets evaluate on the BEAM runtime; `commonJS`, `typescript` and `wasm` on the wat runtime; no
target (the language server's type pass) on beam. A split project's client half is a separate
`--target commonJS` build over the client graph, so it evaluates on wat. No flag, no build option:
`comptime.compile` selects the runtime (`runtime.forTarget`: a harness's `force` pin or
`ofTargetName`), so every driver — `build`, `check`, the LSP — gets the rule.

```zig
// src/comptime/runtime/runtime.zig
pub const ComptimeRuntime = enum { beam, wat };
```

`decorator_eval.zig` and `template_eval.zig` call `runtime.evalWithArg` and import neither executor.
Both runtimes run **one program**: the Erlang text `erlang.zig`'s `emitComptimeModule` produces
(untyped mode), read back by `wat/erl_parse.zig`. Argument in: ETF (`etf.zig`). Reply out:
`json:encode` bytes, read in canonical key order (`reply_order.zig`) on both runtimes. Errors: the
three-way `Response` (`ok` / `compile_error` / `runtime_error`).

**The BEAM runtime** (`persistent_beam.zig`): the lowered module is assembled in Zig and loaded with
**cmd 4** (`<u16 BE namelen><module><beam bytes>` → `code:purge` + `code:load_binary/3`); cmd 3 runs
`main/1`. The lowering is front 14's.

- **The container** (`codegen/beam/beam_file.zig`, decision 83): `FOR1`/`BEAM` with `AtU8 Code StrT
  ImpT ExpT FunT LitT Line` from its own instruction model (`Module → Function → Instr → Arg`); the
  table rules and the `opcode_max` stamp are in the file's header. Validation is by loading
  (`beam_lib:info/1`, `beam_lib:chunks/2`, `code:load_binary/3`); `beam_validator` runs on the
  listings in `scripts/beam_export_audit.sh`.
- **The opcode table** (decision 86): generated from OTP 28's `genop.tab` (`opcodes.zig`,
  `gen_opcodes.sh`); the emitter writes only `Op.emittable()` — the opcodes present since OTP 24 and
  not obsolete. The bootstrap refuses an `erl` below OTP 28 (`__BP_ERL_BELOW_FLOOR__` naming both
  releases); a `.beam` from a newer `erlc` than the machine's `erl` is refused as `badfile`. Neither
  is configurable.
- **The residents** (decision 83): the server and the two preludes are `.beam` bytes compiled by
  `erlc +deterministic` at `zig build` (`render_resident` writes the sources) and embedded; the spawn
  is `erl -noshell -eval <bootstrap>`, one cmd-4 frame per resident. `erlc` (OTP 28+) is a
  dependency of *building* the compiler — every workflow that runs `zig build` installs OTP 28 first
  — and a user's machine needs `erl` only.

**The wat runtime** (`persistent_wat.zig`, specified in [`wat-runtime.md`](./wat-runtime.md)): the
Erlang text lowered over a tagged term heap (`wat/lower.zig`), linked into the embedded term library
(`wat/rt.zig` → `bp_wat_rt.wasm`, `wat/link.zig`) and run on wasm3 in-process (`modules/wasm3/`). The
linked module imports nothing; a body's prints stay in its own memory. Binary wasm comes from
`codegen/wat/wasm_binary_emitter.zig`, which also produces the wasm target's output (every wasm
RUN LOG is the binary emitter's answer).

**Parity.** `runtime.parity` runs every evaluation on the other runtime too; the codegen harness runs
every fixture under it and `parity.zig` pins that an edited helper is reported with both replies
printed. The BEAM runtime is the reference; a difference is fixed in `rt.zig`.

### The snapshot tree (decision 85)

```
snapshots/codegen/<comptime runtime>/<target>/<slug>.snap.md
snapshots/codegen/<comptime runtime>/errors/<target>/<slug>.snap.md
```

`<comptime runtime>` ∈ `{beam, wat}`. The listing section follows the runtime —
`COMPTIME BEAM ASSEMBLY` under `beam/`, `COMPTIME WAT` under `wat/`; `COMPTIME REPLY` keeps its name
in both. The harness generates `targets × runtimes`. `comptime/ast/` stays single (the AST is
runtime-independent); the five fixtures with a runtime exchange are recorded under
`comptime/runtime/{beam,wat}/<slug>`. `scripts/snap_audit.sh --mode=runtime-parity` diffs every pair
after stripping the listings; any other difference, or a missing pair member, exits non-zero. It runs
in `scripts/gate.sh` and CI. A difference is a defect in one runtime — never accepted by re-recording
`wat/` alone; the audit has no allow-list (decision 67).

### The browser build

`zig build compiler-web` builds compiler-core for `wasm32-wasi` (the target is fixed in root
`build.zig`) into `zig-out/web/` beside `glue.js` and `index.html`; `zig build test-web` runs
`tests/smoke.js`. `comptime/runtime/runtime.zig` (`can_spawn`, `active`) folds the BEAM path and the
RUN LOG executors out on wasm: an erlang/beam compile's comptime is refused naming the BEAM, and the
wat runtime's executor is the page's engine behind `bp_host.run_module` / `result_len` /
`result_copy`. The page names its project with `bp_set_package` (decision 109). The exports, the
glue's WASI shim and the Worker protocol are specified in `modules/compiler-web/AGENTS.md`.
Budget: `botopink.wasm` ReleaseSmall ≤ 8 MB, ≤ 2.5 MB gzip.

### Deliberately not done

The erlang and beam *run-time* targets still need `erl` (the RUN LOG, `botopink run`, `botopink
test`), and `node` / `wasmtime` stay for the commonJS / wasm targets' RUN LOG — the target's VM, not
the comptime path.

## Open

- [ ] The CI runners, after the push: test.yml's `zig build test` on `ubuntu-22.04`, `macos-14` and
      `windows-2022` (the windows job installs OTP 28: `zig build` runs `erlc`), and release.yml's
      `zig build -Doptimize=ReleaseSafe -Dtarget=${{ matrix.zigtarget }}` on its five rows
- [ ] The same on the CI matrix for the browser build: test.yml's `zig build test-web` step on
      `ubuntu-22.04`, `macos-14`, `windows-2022`
- [ ] `scripts/comptime_bench.sh` re-run at every step, its table recorded
- [ ] **not this front's:** the per-emission prelude re-parse in `emitErlangModule`
      (`collectPrimErlangDispatch`, `loadAutoImportedBifsFromPrelude`) keeps front 14 step 2's
      per-evaluation budget (≤ 1 ms/eval, N=200 ≤ 600 ms) unmet; the memo belongs in the shared body
      of `02-erlang`'s `emitErlangModule`

## Delivered

- `persistent_erl.zig` deleted; `persistent_beam.zig` holds the transport (cmds 3 and 4)
- an assembled module passes `beam_lib:info/1` / `beam_lib:chunks/2` and loads through cmd 4;
  `main/1` answers every `COMPTIME REPLY` byte-identically from assembled bytes
- no `erlc` on a user's machine; no `.erl` written for any declaration; `COMPTIME ERLANG` became
  `COMPTIME BEAM ASSEMBLY`; the fallback count is 0 over the suite and `test-libs`
- the wat runtime answers every `COMPTIME REPLY` fixture like the BEAM runtime — 0 disagreements,
  0 refusals, the five libraries' commonJS cells included
- no process spawned on the wat path (`strace -f -e execve`: botopink's own only), for `build` and
  `check`
- `modules/wasm3/build.zig` cross-builds for the five release targets from a linux host
  (`modules/wasm3/cimport/endian.h` on the `@cImport` path for macOS)
- no CLI flag or build option for the runtime; `parity.zig` green; a deliberate divergence fails it
- the doubled tree recorded and audited pair by pair; `snap_audit.sh` and `beam_export_audit.sh`
  read it; `BOTOPINK_SNAP_TRACE`: traced = on disk
- `zig build compiler-web` and `zig build test-web` green locally, within budget; the demo compiles
  a decorator + template program with no network request after load and its `COMPTIME REPLY` equals
  the native one; the `wasm` output runs in the page
- `std.process` / `std.fs` reach only files excluded from the wasm build
- `zig build test` from a cold runtime cache and `scripts/gate.sh --cold` green under both runtimes
- every workflow that runs `zig build` installs OTP 28 first
- `AGENTS.md` updated for every touched directory; `meta:architecture.md`'s "O que roda onde" table
  names both runtimes

# Front 18 — comptime runtimes: BEAM direct, WAT, and the browser build — the evidence and the limits

**Priority:** low · **State:** not started (`test-web` wasm32 fix and gate stage 12 on feat)
**Depends on:** maintainer (CI runs after a push) · `14-comptime-on-beam` step 2 (bench numbers
recorded here) · `05-wasm` step 5 (decision 261's opcodes)
**Owns:** `modules/compiler-core/src/comptime/runtime/**` except `beam/**`, `etf.zig`, `prelude.zig`
(14) — `server_source.zig`, `render_resident.zig`, `persistent_beam.zig`, `persistent_wat.zig`,
`wat/**`, `runtime.zig`, `parity.zig`, `reply_order.zig` · `src/codegen/beam/{beam_file,opcodes}.zig`,
`gen_opcodes.sh` · `src/codegen/wat/wasm_binary_emitter.zig` · `src/codegen/snapshot.zig`,
`src/comptime/snapshot.zig`, `src/utils/snap.zig`'s directory selection (07 renames files) · root
`build.zig`'s `render-resident` + `erlc` step and `compiler-web` build · `modules/compiler-web/**` ·
`modules/wasm3/**` · `release.yml`'s matrix · `scripts/comptime_bench.sh`'s table (14 measures)
**Does not touch:** run-time halves of `beam_asm.zig`, `erlang.zig`, `wat.zig`, `commonJS.zig`
(02–05) · the libraries · `src/comptime/eval.zig`, `infer.zig` (01) · `template_eval.zig`,
`decorator_eval.zig`, `runtime/beam/**` (14) · `test.yml` (`00-gate/114`)

Paths relative to `repository/botopink-lang/modules/compiler-core/src/`; those starting `modules/`,
`scripts/`, `.github/` relative to `repository/botopink-lang/`.

## Goal

Every CI row green after the push; wat runtime limits written with a fixture each; comptime bench
table; transport error tested; comptime evaluation within 14's budget; binary emitter has
`memory.size` / `memory.grow`.

## Mechanism

Decision 84: comptime runtime follows the target's VM, beam by default, no flag. BEAM runtime loads
assembled bytes via cmd 4; wat runtime runs the same program on wasm3 in-process; `runtime.parity`
on every fixture; doubled snapshot tree (`snapshots/codegen/{beam,wat}/<target>/`) audited pair by
pair; browser build within budget (`botopink.wasm` ReleaseSmall ≤ 8 MB, ≤ 2.5 MB gzip).

## Open

### Step 1 — the CI matrix (the maintainer's, after the push)

`test.yml` jobs: `../../00-gate/README.md` § Rules 5, 13 (decisions 231, 158); `release.yml`'s `zig
build -Doptimize=ReleaseSafe -Dtarget=${{ matrix.zigtarget }}` on its five rows.

- [ ] every row green on the CI after the milestone's first push; a red row is a step of this front
      (runner-specific fix in `build.zig` or a workflow), never a skipped row

### Step 2 — the four limits, written

`wat-runtime.md` §7 ([1.0.10](../../../1.0.10-beta/00-compiler-carry-over/18-comptime-runtimes/wat-runtime.md))
restated in `src/comptime/runtime/AGENTS.md` (no § Limits today), each with what a body meets:
`safe_call`'s isolation and 10 s timeout (runaway body = runaway wasm3 call; no generated module
spawns, receives or touches ETS); `~p` line breaking past 80 columns (long term prints on one line);
Unicode case mapping (`string:uppercase` / `lowercase` of a non-ASCII letter raises `{bp_wat_runtime,
…}`); integers beyond 64 bits (raise). BEAM runtime is the reference; a parity difference is fixed
in `rt.zig`.

- [ ] `runtime/AGENTS.md` § Limits carries the four with a fixture each pinning the raise (the second with none — its text says why)

### Step 3 — the bench table, and the evaluation's cost

`scripts/comptime_bench.sh` re-run (14 step 2), table recorded here at milestone open and close, on
the runner's machine, load noted. Runtime evaluation = largest remaining per-evaluation stage (wat:
fresh wasm3 environment, parse and load of the linked module, `persistent_wat.zig`; BEAM: frame round
trip — 45 % / 29 % of an N=200 build before decision 237).

- [ ] a table with the open's row; the close's row added by the last front to land
- [ ] the runtime's evaluation brought within 14's budget (≤ 1 ms per evaluation), or what remains named

### Step 4 — the transport test

Beside `evalBeam` (`runtime/runtime.zig`): drive a comptime body past the 16 MiB frame cap, assert
the diagnostic quotes `lastTransportError()`'s message, not `EvalFailed`; `erl` missing stays
`EvalFailed` with the `PATH` hint.

- [ ] the test in `runtime/**`'s test file

### Step 5 — `memory.size` / `memory.grow` in the binary emitter (decision 261)

- [ ] `wasm_binary_emitter.zig` encodes both (`0x3F 0x00`, `0x40 0x00`), with a fixture; `05-wasm`
      step 5 uses them

**Gate:** standard (fronts.md § Gate) + `zig build test` green under both runtimes ·
`scripts/snap_audit.sh --mode=runtime-parity` green · `zig build compiler-web` and `test-web` green
within budget

## Notes

- erlang/beam `build`/`run`/`test` need the right `erl` (OTP 28, decision 228); `node` / `wasmtime` stay for commonJS / wasm RUN
  LOGs. `erlc` (OTP 28+) needed to build the compiler; a user's machine needs `erl` only.

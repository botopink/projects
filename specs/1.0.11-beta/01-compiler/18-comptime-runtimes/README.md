# Front 18 — comptime runtimes: BEAM direct, WAT, and the browser build

**Priority:** low — landed (C-26); what is open is evidence the maintainer's CI produces, one
table, one test and four limits to write down.
**Depends on:** `00-gate` (nothing of this front's files is a gate item) · the maintainer (the CI
runs happen after a push) · `14-comptime-on-beam` step 2 (the bench numbers it measures land in
this front's table).
**Owns:** `modules/compiler-core/src/comptime/runtime/**` except `beam/**`, `etf.zig`, `prelude.zig`
(14) — `server_source.zig`, `render_resident.zig`, `persistent_beam.zig`, `persistent_wat.zig`,
`wat/**`, `runtime.zig`, `parity.zig`, `reply_order.zig` · `src/codegen/beam/{beam_file,opcodes}.zig`,
`gen_opcodes.sh` · `src/codegen/wat/wasm_binary_emitter.zig` · `src/codegen/snapshot.zig`,
`src/comptime/snapshot.zig`, `src/utils/snap.zig` (with 07: 07 renames files, this front owns the
directory selection) · root `build.zig`'s `render-resident` + `erlc` step and `compiler-web` build ·
`modules/compiler-web/**` · `modules/wasm3/**` · `.github/workflows/**` (the matrix rows) ·
[`wat-runtime.md`](../../../1.0.10-beta/00-compiler-carry-over/18-comptime-runtimes/wat-runtime.md)
stays in 1.0.10; its §7 is restated here as limits · `scripts/comptime_bench.sh`'s table (14 measures)
**Does not touch:** the run-time halves of `beam_asm.zig`, `erlang.zig`, `wat.zig`, `commonJS.zig`
(02–05) · the libraries · `src/comptime/eval.zig`, `infer.zig` (01) · `template_eval.zig`,
`decorator_eval.zig`, `runtime/beam/**` (14).

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/` unless they start with
`modules/`, `scripts/` or `.github/`, which are relative to `repository/botopink-lang/`.

## Carried from 1.0.10

| Item | 1.0.10 spec | Heading |
|---|---|---|
| the CI matrix, `test-web` on the matrix, the bench table | `18-comptime-runtimes/README.md` | § Open, boxes 1–3 (box 4 — the prelude re-parse — is **landed**: `erlang.zig:328` `prelude_cache`; the bullet is stale) |
| the four non-parity items | `18-comptime-runtimes/wat-runtime.md` | § 7 |
| the transport test | `08-hygiene/README.md` | § Open, item 4 |

## What holds

Decision 84 (the comptime runtime follows the target's VM, beam by default; no flag); the BEAM
runtime loads assembled bytes through cmd 4; the wat runtime runs the same program on wasm3
in-process; `runtime.parity` on every fixture; the doubled snapshot tree
(`snapshots/codegen/{beam,wat}/<target>/`) audited pair by pair with no allow-list; the browser
build within budget (`botopink.wasm` ReleaseSmall ≤ 8 MB, ≤ 2.5 MB gzip). Measured at 1.0.10's
close; `zig build test-web` re-run at the open.

## Steps

### Step 1 — the CI matrix (the maintainer's, after the push)

`test.yml`'s `zig build test` on `ubuntu-22.04`, `macos-14`, `windows-2022` (the windows job
installs OTP 28: `zig build` runs `erlc`); `release.yml`'s `zig build -Doptimize=ReleaseSafe
-Dtarget=${{ matrix.zigtarget }}` on its five rows; `zig build test-web` on the three runners.

**Acceptance:**
- [ ] every row green on the CI after the milestone's first push; a red row is a step of this front (a runner-specific fix in `build.zig` or a workflow), never a skipped row

### Step 2 — the four limits, written

`wat-runtime.md` §7 restated in `src/comptime/runtime/AGENTS.md` as the wat runtime's limits, each
with the behaviour a body meets: `safe_call`'s isolation and its 10 s timeout (a runaway body is a
runaway wasm3 call — no generated module spawns, receives or touches ETS); `~p`'s line breaking
past 80 columns (a long term in an error text prints on one line; no fixture carries one);
Unicode case mapping (`string:uppercase` / `lowercase` of a non-ASCII letter raises
`{bp_wat_runtime, …}`); integers beyond 64 bits (raise). The BEAM runtime is the reference; a
difference parity finds is fixed in `rt.zig` — a limit is a difference a body cannot reach without
the runtime naming it.

**Acceptance:**
- [ ] `runtime/AGENTS.md` § Limits carries the four with a fixture each pinning the raise (the second with none — its text says why)

### Step 3 — the bench table

`scripts/comptime_bench.sh` re-run (14 step 2) and its table recorded here, per milestone open and
close, on the runner's machine, with the load noted.

**Acceptance:**
- [ ] a table with the open's row; the close's row added by the last front to land

### Step 4 — the transport test (08 item 4)

A test beside `evalBeam` (`runtime/runtime.zig`) drives a comptime body past the 16 MiB frame cap
and asserts the diagnostic quotes `lastTransportError()`'s message, not `EvalFailed`; the
`erl`-missing case stays `EvalFailed` with the `PATH` hint.

**Acceptance:**
- [ ] the test in `runtime/**`'s test file; 08's box ticked

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green under both runtimes, in this front's worktree
- [ ] `scripts/snap_audit.sh --mode=runtime-parity` green; `zig build compiler-web` and `test-web` green within budget
- [ ] `AGENTS.md` of every touched directory in the same commit
- [ ] Commit on `fix/18-comptime-runtimes`; no push, no merge

## Blast radius

None on the language; step 4 adds a test.

## Notes

- The erlang and beam run-time targets still need `erl`; `node` / `wasmtime` stay for the
  commonJS / wasm RUN LOGs — the target's VM, not the comptime path.
- `erlc` (OTP 28+) is a dependency of building the compiler; a user's machine needs `erl` only.

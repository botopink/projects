# Front 18 — comptime runtimes: BEAM direct, WAT, and the browser build — the evidence and the limits

**Priority:** low · **State:** partial: steps 2, 4, 5 done, step 3's open row recorded; 1 and 3 open
(`test-web` wasm32 fix and gate stage 12 on feat)
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

## Done

Steps: 2 the four limits in `src/comptime/runtime/AGENTS.md` § Limits, a fixture each in
`persistent_wat.zig` (`limit 1`: `spawn/1`, `receive`, `ets:new/2` refused by name; `limit 3`: a
non-ASCII `string:uppercase` raises `{bp_wat_runtime, …}`; `limit 4`: `i64` overflow raises; the
second has none, its text says why) · 4 `runtime.zig`'s `a reply past the frame cap reaches the
evaluator as the transport message, not EvalFailed` (a body answering 16 MiB + 1 byte; the next
request respawns and answers). A missing `erl` is no longer `EvalFailed`: the release probe
(decision 228) leaves `` `erl` could not be run: … put it on PATH `` as the transport message —
`AGENTS.md`'s note says so · 5 `memory.size` / `memory.grow` (`0x3F 0x00` / `0x40 0x00`, on feat
since `d71b89f5`) pinned by `wasm_binary_emitter.zig`'s `memory.size and memory.grow encode with
their memory-index byte (decision 261)`.

## Open

### Step 1 — the CI matrix (the maintainer's, after the push)

`test.yml` jobs: `../../00-gate/README.md` § Rules 5, 13 (decisions 231, 158); `release.yml`'s `zig
build -Doptimize=ReleaseSafe -Dtarget=${{ matrix.zigtarget }}` on its five rows.

- [ ] every row green on the CI after the milestone's first push; a red row is a step of this front
      (runner-specific fix in `build.zig` or a workflow), never a skipped row

### Step 3 — the bench table, and the evaluation's cost

`scripts/comptime_bench.sh` re-run (14 step 2), table recorded here at milestone open and close, on
the runner's machine, load noted. Runtime evaluation = largest remaining per-evaluation stage (wat:
fresh wasm3 environment, parse and load of the linked module, `persistent_wat.zig`; BEAM: frame round
trip — 45 % / 29 % of an N=200 build before decision 237).

| Row | Date | Machine, load (1 min, before → after) | Target (runtime) | N=0 build | N=10 | N=200 | ms/eval 10→200 |
|---|---|---|---|---|---|---|---|
| open | 2026-10-09 | dev box, 16 threads, Debug `zig-out/bin/botopink`, load 56.7 → 77.6 | commonJS (wat) | 582 ms | 574 ms | 1045 ms | 2.5 |
| open | 2026-10-09 | same run | erlang (BEAM) | 1007 ms | 1509 ms | 1907 ms | 2.1 |

`scripts/comptime_bench.sh --no-build --target <t> --n 0,10,200 --repeat 3`, min of three builds.
The load (other worktrees' gates) makes the slope an upper bound; re-measure on an idle runner. The
script's E-2 half (in-node split) reports `no comptime module was written`: it reads
`.botopinkbuild/tmp/{template,decorator}`, which nothing writes since modules travel in-frame (front
14 step 3, decision 83) — the instrument needs `14`'s rewrite before it measures anything.

- [ ] a table with the open's row (above); the close's row added by the last front to land
- [ ] the runtime's evaluation brought within 14's budget (≤ 1 ms per evaluation), or what remains
      named — open: 2.1–2.5 ms/eval under load, both runtimes above the budget; the split between
      wasm3 setup / module load / frame round trip waits on E-2's rewrite

**Gate:** standard (fronts.md § Gate) + `zig build test` green under both runtimes ·
`scripts/snap_audit.sh --mode=runtime-parity` green · `zig build compiler-web` and `test-web` green
within budget

## Notes

- erlang/beam `build`/`run`/`test` need the right `erl` (OTP 28, decision 228); `node` / `wasmtime` stay for commonJS / wasm RUN
  LOGs. `erlc` (OTP 28+) needed to build the compiler; a user's machine needs `erl` only.

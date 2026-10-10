# Front 18 — comptime runtimes: BEAM direct, WAT, and the browser build — the evidence and the limits

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [144-botopink-lang](../README.md): s3 → B-00d · s1 → B-29. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** low · **State:** partial: steps 2, 4, 5 done, step 3's open row and the evaluation's
budget recorded; 1 and 3 open
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

## Notes

- erlang/beam `build`/`run`/`test` need the right `erl` (OTP 28, decision 228); `node` / `wasmtime` stay for commonJS / wasm RUN
  LOGs. `erlc` (OTP 28+) needed to build the compiler; a user's machine needs `erl` only.

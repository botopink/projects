# Front 14 — comptime-on-beam: the comptime pipeline's evidence and its cost per evaluation

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [144-botopink-lang](../README.md): s6 → B-12 · s8 → B-17. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** medium · **State:** partial: steps 1 (fixture half), 3, 4, 7, decision 237, step 2's
slope, step 6's 341 and 343, step 8's boxes 1–3, 5, its imported `val` and `contentHash` (T19);
step 2's N=200 wall clock on the BEAM runtime, step 6's 342, and step 8's `Any` calls and 380 open
**Depends on:** `18-comptime-runtimes` (step 2's runtime-evaluation stage) · `01-checker` (step 2's
memo key; body file name and T17 are 01's rows; step 36's stages for step 8's `Any` calls; 342's
builtins) · 346 (`Bytes`, for `@embedBytes`).
**Owns:** `modules/compiler-core/src/comptime/template_eval.zig`, `decorator_eval.zig`, `host_cells.zig` ·
`src/comptime/runtime/beam/**` (lowering) · `src/comptime/runtime/etf.zig` (term round trip) ·
`src/comptime/runtime/prelude.zig` (resident preludes) · `src/codegen/beam/asm_text.zig` (listing) ·
`scripts/comptime_bench.sh` (with 18: this front measures, 18 records the table) · `COMPTIME BEAM
ASSEMBLY` cells and `snapshots/comptime/runtime/beam/**` · its fixtures in
`codegen/tests/comptime_module.zig` and `comptime/tests/**` (carve-out of 07, named per commit)
**Does not touch:** `src/comptime/eval.zig`, `infer.zig` (01) · typed `beam_asm.zig` (03) ·
`erlang.zig`'s `emitComptimeModule` and `beam/erl_emitter.zig` (02) ·
`comptime/runtime/{runtime,persistent_beam,persistent_wat}.zig`, `runtime/wat/**` (18) · `libs/std/**`

Paths relative to `repository/botopink-lang/modules/compiler-core/src/`; those starting `modules/`,
`libs/`, `scripts/` relative to `repository/botopink-lang/`.

## Goal

Fixtures prove the promised comptime pipeline and it meets budget: ≤ 1 ms per evaluation, N=200
call-site project ≤ 600 ms on both runtimes.

## Mechanism

- One module per declaration (`bp@comptime__{tpl,dec}__<decl>__<hash>`, 01c-a); host glue resident
  (`bp_comptime_template` / `bp_comptime_decorator`).
- Body reaches the node as BEAM bytes: read back by `runtime/wat/erl_parse.zig`, lowered by
  `runtime/beam/lower.zig`, assembled by `codegen/beam/beam_file.zig`, loaded by cmd 4; `COMPTIME
  REPLY` byte-identical across both runtimes.
- Emitted once per declaration and plan (`template_eval.zig` `emitKey`).
- Template capture carries only bindings whose name is a **word** of its text (decision 237;
  `captureToTerm` / `appendWords`); `lookup` of a non-word fails at the literal (`runtime/prelude.zig`
  `lookup/2`).

## Notes

- **Resident node stays.** The Erlang compiler left the compile path, not `erl`; commonJS /
  typescript / wasm builds evaluate on the wat runtime, spawn nothing (decision 84).
- One Erlang lowering per runtime (BEAM here, wasm in 18), cross-checked by parity.

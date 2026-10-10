# Front 02 — erlang: the erlang target answers what decision 8 says, on every shape

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [144-botopink-lang](../README.md): s14 → B-13 · rows box 1 → B-22; [150-rakun](../../../2-libraries/150-rakun/README.md): rows box 2 → 150 s2. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** high · **State:** partial: steps 1–13 and 15 done; step 14 open
**Depends on:** `01-checker`'s `@block` tail-form refusal (step 10)
**Owns:** `modules/compiler-core/src/codegen/erlang.zig` · `src/codegen/crossModule.zig` ·
`src/codegen/beam/{erl_ast,erl_emitter}.zig` (Erlang-text renderer, carve-out from 03; erlang target
and comptime module text both use it) · `snapshots/codegen/<runtime>/erlang/**`,
`snapshots/codegen/<runtime>/errors/erlang/**` · `src/codegen/tests/erlang.zig` · its cells under
`tests/language/{run,modules}/`
**Does not touch:** `src/comptime/**`, `src/parser/**` (01, 14, 18) · `src/codegen/beam_asm.zig`,
rest of `src/codegen/beam/**` (03) · `src/codegen/{commonJS,typescript}.zig`, `codegen/js/**` (04) ·
`src/codegen/wat.zig`, `codegen/wat/**` (05) · `modules/compiler-cli/**` (26) · `libs/std/**` (std
track — handed measurement + cell) · `codegen/tests/**` other than `erlang.zig` (07)

Paths relative to `repository/botopink-lang/modules/compiler-core/src/`. `botopink build --target
erlang` never invokes `erlc`: steps run `botopink run --target erlang`.

## Goal

Every erlang row of the rakun sweep and C-07 = a four-target cell with one `.out`; erlang text never
leans on an auto-imported BIF name, a template binding or the host locale; decision 264's overflow
rule and 263's one `math` honoured.

## Notes

- **Erlang is not the oracle:** on disagreement assert decision 8's meaning, not erlang's output.
- **Only erlang snapshots move here.** Moving `snapshots/comptime/**` = crossed into 01; beam
  snapshots = 03 (shared renderer can move both; comptime listings under `snapshots/codegen/beam/**`
  are 14's — report, do not re-record).
- `crossModule.zig` carries decision 109's atoms and layout; no atom changes here.

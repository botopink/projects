# Front 03 — beam: the assembled target answers what erlang answers

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [144-botopink-lang](../README.md): s1 → B-22. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** high · **State:** partial: steps 1–9 done (every owned lowering) but step 1 box 3, which
waits on `01-checker` step 13's cells
**Depends on:** `01-checker` step 13 (step 1)
**Owns:** `modules/compiler-core/src/codegen/beam_asm.zig` · `src/codegen/beam/**` except
`{erl_ast,erl_emitter}.zig` (02), `beam_file.zig` / `opcodes.zig` / `gen_opcodes.sh` (18),
`asm_text.zig` (14) · `snapshots/codegen/<runtime>/beam/**`, `snapshots/codegen/<runtime>/errors/beam/**`
· `scripts/beam_export_audit.sh` · `src/codegen/tests/beam.zig` ·
[`pattern-binding.md`](pattern-binding.md) · its cells
**Does not touch:** `src/comptime/**`, `src/parser/**` (01, 14, 18) · `src/codegen/erlang.zig`,
`crossModule.zig`, `beam/{erl_ast,erl_emitter}.zig` (02) · `commonJS.zig`, `typescript.zig`, `js/**`
(04) · `wat.zig`, `wat/**` (05) · `modules/compiler-cli/**` (26) · keyed-`Ets` functions of
`beam_asm.zig` (`emitKeyedRowRead`, `emitKeyedRowWrite`, `emitKeyedHelpers` — 17's carve-out)

Paths relative to `repository/botopink-lang/modules/compiler-core/src/`. By hand: `botopink build
--target beam`, `erlc +from_asm out/beam/*.S`, `erl -noshell -pa out/beam -eval
"'<pkg>@main':'_botopink_main'(), halt()."`; `tests/language/run.sh --target beam` does every cell;
`botopink test --target beam` runs `test/` and test-kind `modules/` cells.

## Goal

beam is one of `run.sh --target all`'s four, no tolerated red: every binding pattern binds, C-07's
tables answer as erlang, the sidecar ships and loads, decisions 264 (overflow) and 263 (one `math`)
honoured.

## Notes

- **Run-time abort on an unbound name is a backstop, not a fix:** keep `{unresolved_identifier, N}`;
  the check is the checker's.
- **Only beam snapshots move here.** Erlang snapshots moving = crossed into 02's shared renderer —
  stop, report.
- Two rows from other fronts to re-measure (a step if either holds): module-level `val g = greet`
  called as `g()` prints `#Fun<…>` on beam (`05-wasm`; `run/fn_value_bound_by_val` keeps to
  locals); `throw` in a `case` arm's block form under `-> @Result` still throws on beam (`02-erlang`).

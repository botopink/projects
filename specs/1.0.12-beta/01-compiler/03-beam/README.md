# Front 03 — beam: the assembled target answers what erlang answers

**Priority:** high · **State:** partial: steps 1–9 done (every owned lowering) but step 1 box 3, which
waits on `01-checker` step 13's cells
**Depends on:** `01-checker` step 13 (step 1)
**Owns:** `modules/compiler-core/src/codegen/beam_asm.zig` · `src/codegen/beam/**` except
`{erl_ast,erl_emitter}.zig` (02), `beam_file.zig` / `opcodes.zig` / `gen_opcodes.sh` (18),
`asm_text.zig` (14) · `snapshots/codegen/<runtime>/beam/**`, `snapshots/codegen/<runtime>/errors/beam/**`
· `scripts/beam_export_audit.sh` · `src/codegen/tests/beam.zig` ·
[`pattern-binding.md`](./pattern-binding.md) · its cells
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

## Done

Steps: 1 boxes 1–2 JS-4 beam twin: constructor in a `val` binds (`emitPatternDestruct`,
`run/ctor_pattern_in_val_binding`) · 2 boxes 2–3 one beam fixture per tuple / `..` / type-pattern
shape; `beam_export_audit.sh` green · 3 sidecar's `.S` half (with 00-gate/111) · 4 captured-`var`
write (148): threaded forms answer · 5 `keyed: true` in assembly (`17-beam-memory`'s) · 6 entry
point sets `standard_io` unicode (`emitUnicodeStdio`) · 7 one `math` (263): `fn:` read on
`@External.Beam` (or `Erlang` without one; `hostFnBinding.Lowering.apply(…, .beam)`,
`tests/externals.zig`'s `beam: … fn: binds a declare fn to a private body`) —
`run/std_math_on_every_target` (`a443f52d`) · 8 an integer out of its type aborts (264):
`emitIntCheck` (two `is_ge` + inline `erlang:error({integer_overflow, …})`) — 02 step 13's cells with
`.beam.stderr`; beam snapshots move by the check and its labels only (`48a096ea`) · 9 a lambda a `case` arm
answers is the arm's value on beam (`codegen/tests/beam.zig`'s `a lambda literal that ends a case arm
is the arm's value`); `test/case_arm_lambda_value` moved to `run/case_arm_lambda_value`, `a?` / `b`
on all four targets; `language-gaps.md` row 28 deleted.
Rows from other fronts: an `@block`'s `return` is the block's value (decision 2) —
`lowerBlockWithReturn` jumps to the block's exit label with the value in `x0` instead of `return.`
from the enclosing function (`run/block_return_is_block_value`, four targets;
`block_block_builtin` beam snapshots move by the jump).
- Step 2 box 1 — C-07's cells on beam: `run/is_truth_table` (`02-erlang` step 7) green on beam;
  `run/unknown_stores_nothing` struck with 02 step 7 (§11 is a cost no program prints)
- A `case` no arm matches raises `{case_clause, V}` as erlang does: with no arm that takes every
  subject (`armCatchesAll`), the fall-through is `{case_end, {x,0}}` (`run/case_no_arm_matches_raises`
  — a host function answers an atom no variant is; beam printed the subject at exit 0 on the parent)
- An in-frame loop's head survives OTP's `beam_jump`: `writeLoopTop` puts a `{line, …}` anchor before
  `{label, Top}`, so tail sharing cannot turn the entry into a jump to an identical back edge and leave
  `Top` with backward references only (`erlc` stopped on `{undefined_label, Top}` in log's
  `stripLineNumbers`; `modules/import_bundled_package_beside_own_module` green on beam).
- A variant name declared by two enums with different fields: a positional pattern binds the payload, not
  the whole value — `beam_asm` registers an imported enum's name (`modules/variant_positional_payload_same_name`).

## Open

### Step 1 — the checker's two binding shapes on beam (box 3)

Lowering in (`emitPatternDestruct`); with the checker refusal lifted beam prints `val Pair(Circle(r),
n) = p` as `3 4`, nested one-variant enums as `7 x 9`, `val [..rest] = [1, 2, 3]`'s length as `3`.

- [ ] `run/val_nested_ctor_pattern` and `run/val_spread_only_list_pattern` (`01-checker` step 13)
      pass on beam

**Gate:** standard (fronts.md § Gate) + `scripts/beam_export_audit.sh` assembles every module before
and after each step · every re-recorded RUN LOG verified by running (`erlc +from_asm` + `erl`)

## Notes

- **Run-time abort on an unbound name is a backstop, not a fix:** keep `{unresolved_identifier, N}`;
  the check is the checker's.
- **Only beam snapshots move here.** Erlang snapshots moving = crossed into 02's shared renderer —
  stop, report.
- Two rows from other fronts to re-measure (a step if either holds): module-level `val g = greet`
  called as `g()` prints `#Fun<…>` on beam (`05-wasm`; `run/fn_value_bound_by_val` keeps to
  locals); `throw` in a `case` arm's block form under `-> @Result` still throws on beam (`02-erlang`).

# Front 03 — beam: the assembled target answers what erlang answers

**Priority:** high · **State:** partial: steps 1–6 on feat (every owned lowering); step 1 box 3 and
step 2 box 1 wait on other fronts' cells; steps 7–9 open
**Depends on:** `01-checker` step 13 (step 1) · `02-erlang` step 7 and `05-wasm` (step 2) ·
`02-std-and-packaging` (step 7's private `math` bodies)
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
write (148): threaded forms answer · 5 `keyed = true` in assembly (`17-beam-memory`'s) · 6 entry
point sets `standard_io` unicode (`emitUnicodeStdio`).

## Open

### Step 1 — the checker's two binding shapes on beam (box 3)

Lowering in (`emitPatternDestruct`); with the checker refusal lifted beam prints `val Pair(Circle(r),
n) = p` as `3 4`, nested one-variant enums as `7 x 9`, `val [..rest] = [1, 2, 3]`'s length as `3`.

- [ ] `run/val_nested_ctor_pattern` and `run/val_spread_only_list_pattern` (`01-checker` step 13)
      pass on beam

### Step 2 — C-07's `run/` cells on beam (box 1)

`codegen/tests/beam.zig` pins the truth table and `unknown` by value; the program prints the same
ten lines on commonJS, erlang, beam.

- [ ] `run/is_truth_table`, `run/unknown_stores_nothing` (`02-erlang` step 7's cells) green on beam

### Step 7 — one `math` on every OS (decision 263)

`02-erlang` step 12 on the `.S` side: `#[@External.Beam("fn:tanBody")]`, decision 259's `pow` body;
exact ops stay host calls.

- [ ] the `fn:` form read on `@External.Beam`; `run/std_math_on_every_target` green on beam on
      `ubuntu-22.04` and `macos-14`

### Step 8 — an integer that leaves its type aborts (decision 264)

`02-erlang` step 13 in assembly: range test after `+`, `-`, `*`, unary `-`, compound assignments of
every integer type, aborting as wasm's `int_chk`.

- [ ] the cells of `02-erlang` step 13 green on beam; `beam_export_audit.sh` green; beam snapshots
      move by the range test only

### Step 9 — a lambda produced by a `case` arm (`language-gaps.md` row 28)

Parses and checks everywhere (`test/case_arm_lambda_value`); on beam calling it is `{badfun, ok}`.

- [ ] a `run/` cell (the `test/` cell moved or mirrored) green on beam, printing what commonJS and
      erlang print; row 28 of `language-gaps.md` deleted with it

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

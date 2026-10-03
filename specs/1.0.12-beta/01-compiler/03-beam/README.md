# Front 03 — beam: the assembled target answers what erlang answers

**Priority:** high · **State:** partial: steps 1–6 on feat (every lowering this front owns); step 1
box 3 and step 2 box 1 wait on other fronts' cells; steps 7–8 open
**Depends on:** `01-checker` step 13 (step 1) · `02-erlang` step 7 and `05-wasm` (step 2) ·
`02-std-and-packaging` (step 7's private `math` bodies)
**Owns:** `modules/compiler-core/src/codegen/beam_asm.zig` · `src/codegen/beam/**` except
`{erl_ast,erl_emitter}.zig` (02), `beam_file.zig` / `opcodes.zig` / `gen_opcodes.sh` (18) and
`asm_text.zig` (14) · the beam snapshots under `snapshots/codegen/<runtime>/beam/**` and
`snapshots/codegen/<runtime>/errors/beam/**` · `scripts/beam_export_audit.sh` ·
`src/codegen/tests/beam.zig` · [`pattern-binding.md`](./pattern-binding.md) · the cells its steps add
**Does not touch:** `src/comptime/**`, `src/parser/**` (01, 14, 18) · `src/codegen/erlang.zig`,
`crossModule.zig`, `beam/{erl_ast,erl_emitter}.zig` (02) · `commonJS.zig`, `typescript.zig`, `js/**`
(04) · `wat.zig`, `wat/**` (05) · `modules/compiler-cli/**` (26) · the keyed-`Ets` functions of
`beam_asm.zig` (`emitKeyedRowRead`, `emitKeyedRowWrite`, `emitKeyedHelpers` — 17's carve-out)

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/`. A beam program by hand:
`botopink build --target beam`, `erlc +from_asm out/beam/*.S`, `erl -noshell -pa out/beam -eval
"'<pkg>@main':'_botopink_main'(), halt()."`; `tests/language/run.sh --target beam` does it for every
cell, and `botopink test --target beam` runs `test/` and test-kind `modules/` cells.

## Goal

beam is one of `run.sh --target all`'s four targets with no tolerated red: every pattern a binding
may hold binds, C-07's tables answer as on erlang, the sidecar ships and loads, and the target
honours decision 264's overflow rule and decision 263's one `math`.

## Done

- Step 1, boxes 1–2 — JS-4's beam twin: a constructor in a `val` binds its names (`emitPatternDestruct`, `run/ctor_pattern_in_val_binding`)
- Step 2, boxes 2–3 — one beam fixture per tuple / `..` / type-pattern shape; `beam_export_audit.sh` green
- Step 3 — the sidecar's `.S` half (with 00-gate/111)
- Step 4 — the captured-`var` write (decision 148): the threaded forms answer on beam
- Step 5 — `keyed = true` in assembly: `17-beam-memory`'s, landed
- Step 6 — the entry point sets `standard_io` to unicode (`emitUnicodeStdio`)

## Open

### Step 1 — the checker's two binding shapes on beam (box 3)

The beam lowering is in (`emitPatternDestruct`): with the checker's refusal lifted, beam prints
`val Pair(Circle(r), n) = p` as `3 4`, nested one-variant enums as `7 x 9`, and
`val [..rest] = [1, 2, 3]`'s length as `3`.

- [ ] `run/val_nested_ctor_pattern` and `run/val_spread_only_list_pattern` (`01-checker` step 13)
      pass on beam

### Step 2 — C-07's `run/` cells on beam (box 1)

`codegen/tests/beam.zig` pins the truth table and `unknown` by value; the table as a program prints
the same ten lines on commonJS, erlang and beam.

- [ ] `run/is_truth_table`, `run/unknown_stores_nothing` (`02-erlang` step 7's cells) green on beam

### Step 7 — one `math` on every OS (decision 263)

As `02-erlang` step 12, on the `.S` side: `#[@External.Beam("fn:tanBody")]` and decision 259's
`pow` body; the exact operations stay host calls.

- [ ] the `fn:` form read on `@External.Beam`; `run/std_math_on_every_target` green on beam on
      `ubuntu-22.04` and `macos-14`

### Step 8 — an integer that leaves its type aborts (decision 264)

As `02-erlang` step 13, in assembly: the range test after `+`, `-`, `*`, unary `-` and the compound
assignments of every integer type, aborting as wasm's `int_chk` does.

- [ ] the cells of `02-erlang` step 13 green on beam; `beam_export_audit.sh` green; beam snapshots
      move by the range test only

**Gate:** standard (fronts.md § Gate) + `scripts/beam_export_audit.sh` assembles every module before
and after each step · every re-recorded RUN LOG verified by running (`erlc +from_asm` + `erl`)

## Notes

- **beam's run-time abort on an unbound name is the backstop, not a fix.** Keep
  `{unresolved_identifier, N}`; the check is the checker's.
- **This front moves only beam snapshots.** A change that moves the erlang snapshots crossed into
  02's shared Erlang-text renderer — stop and report.
- A module-level `val g = greet` called as `g()` prints `#Fun<…>` on beam (found by `05-wasm`;
  `run/fn_value_bound_by_val` keeps to locals) — re-measure, and a step here if it holds.

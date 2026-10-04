# Front 02 — erlang: the erlang target answers what decision 8 says, on every shape

**Priority:** high · **State:** partial: steps 1–3, 5 (box 1), 6, 8, 9, 11–13 on feat; steps 4, 7,
10, 14 open
**Depends on:** `05-wasm` (step 7's wasm column) · `01-checker`'s `@block` tail-form refusal (step
10)
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

## Done

Steps: 1 every codegen BIF qualified; `no_auto_import` for a user fn shadowing one (T13) · 2 `while`
fun is `__BpLoop<depth>` (T14) · 3 `'_botopink_init'/0` walked for helpers: module-level `@print` in
a dependency (C-34) · 4 box 2 typing a `default fn` body of `primitives.bp` (C-35 erlang half) · 5
box 1 `\u{…}` and non-ASCII literals in Erlang text; entry point sets `standard_io` unicode (C-36) ·
6 `string.indexOf` counts codepoints (decisions 169, 240): `run/string_index_of_codepoints`, one
`.out` · 8 captured-`var` write: nothing lowers here (148) · 9 sibling loader under `build` (T1, with
`26-cli-tooling` step 1) · 10 box 1 block-as-value producers measured (`src/codegen/AGENTS.md`) · 11
C-06's `KNOWN` notes and `primitives.d.bp` / `@external(` sweep in `erlang.zig` · 12 one `math`
(263): `fn:` read on `@External.Erlang` (`codegen/hostFnBinding.zig`, `tests/externals.zig`'s
`erlang: … fn: binds a declare fn to a private body`), `std/math`'s transcendentals and `pow` run
std's bodies, exact ops host calls — `run/std_math_on_every_target` with the `pow` row (`a443f52d`) ·
13 an integer out of its type aborts (264): `intChecked` / `'__bp_int'/4` after `+ - * /`, unary `-`,
`+=` — `run/int_overflow_{add_i32,add_i8,sub_u32,mul_i64,negate_i32,plus_assign}`,
`run/int_division_min_by_minus_one` (`.exit` + `.erlang.stderr`), `run/int_arith_at_bounds` in
range; erlang snapshots move by the check only (`48a096ea`). Rows from other
fronts: `default fn` body's `unwrapOr`/method calls, `true`/`false` in a tuple pattern,
`Point(x: 0, ..)`, `throw` in a `case` arm of a `-> @Result` fn, host locale, lambda over an
enclosing name (205), a `default fn` two types adopt, `[..all]` alone, `test/` module calling its own
sidecar.

## Open

### Step 4 — `run/array_unique` (C-35)

Decision 217 (drop duplicates, keep first, `==`); std body on feat (`primitives.bp`, `Array.unique`
default fn); nothing left to lower on erlang. Cell is this front's.

- [ ] `run/array_unique` — `[1, 2, 1, 3, 2].unique()` prints `[1, 2, 3]` on four targets (wasm
      column with `05-wasm` step 1)

### Step 5 — a decorator body carrying `\u{…}` (box 2)

Renderer fix serves comptime module text too; fixture is `14-comptime-on-beam`'s (14 step 7).

### Step 7 — C-07's erlang tails as `run/` cells

§4.1's truth table per §4.2 form (`is` on a primitive, constructor, tuple, `Box<unknown>`) and §11's
"erlang: nothing". `test/is_truth_table` holds on commonJS, erlang, beam (same ten lines); wasm
refuses (`cannot box this value as unknown`, `05-wasm` row) — no four-target `.out` yet. §11 pinned
by `codegen/tests/control_flow.zig`'s needle (`A = 2.0,`): no program can tell stored from unboxed.

- [ ] `run/is_truth_table` — every row of §4.1 × §4.2, one `.out` for four targets
- [ ] `run/unknown_stores_nothing` (§11) on four targets, or box struck with a written reason
      (nothing a program prints differs)

### Step 10 — the block-as-value lowering (R7)

Only erlang site with a block in value position: `@block`'s applied `fun` (`builtinCallNode`), with
real producers (`@block { return 3; }`, `@block { … };`); decision 2's refused tail form uses the
same `fun`. Nothing in `erlang.zig` deleted.

- [ ] `@block { 1 + 2 }` refused by the checker (`01-checker` row) — `snapshots/codegen/*/erlang/**`
      then byte-identical

### Step 14 — a method declared `-> @Result` is lowered as a `@Result` (decision 304)

Measured by rakun (`rakun-data/src/sql/template.bp`, comment above `tryQuery`): on erlang a **method**
declared `-> @Result` is lowered as a plain function — a `throw` in it escapes as a raise and a returned
value is not wrapped in `{ok, V}` — while a module-level fn is lowered correctly.

- [ ] `run/` cell: a method `-> @Result<i32, string>` with `return 1`, `throw "x"` and `try other()` answers `{ok, 1}`, `{error, "x"}` and the propagated error — same as the module-level fn cell
- [ ] the same cell on js (no change expected; asserted)
- [ ] a behavior method (`KeyValueStore.get`) declared `-> @Result` dispatches and wraps the same

### Rows found by other fronts

- [ ] std module's module-level `var` lowers to `std@beam` on erlang, not imported by the module
      (from `05-wasm` step 5; re-measure)
- [ ] rakun's `codepointIndex` host cell (`autoconfig_registry.bp`) deletable since step 6 — rakun
      track's row, noted here

**Gate:** standard (fronts.md § Gate) + every re-recorded RUN LOG verified under `erl`, nothing
bulk-accepted · `zig build test-libs` erlang cells at baseline, rakun's members re-run

## Notes

- **Erlang is not the oracle:** on disagreement assert decision 8's meaning, not erlang's output.
- **Only erlang snapshots move here.** Moving `snapshots/comptime/**` = crossed into 01; beam
  snapshots = 03 (shared renderer can move both; comptime listings under `snapshots/codegen/beam/**`
  are 14's — report, do not re-record).
- `crossModule.zig` carries decision 109's atoms and layout; no atom changes here.

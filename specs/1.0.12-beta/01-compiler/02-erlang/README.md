# Front 02 — erlang: the erlang target answers what decision 8 says, on every shape

**Priority:** high · **State:** partial: steps 1–3, 5 (box 1), 6, 8, 9, 11 on feat; steps 4, 7, 10,
12, 13 open
**Depends on:** `05-wasm` (step 7's cells need a wasm column) · `01-checker`'s `@block` tail-form
refusal (step 10) · `02-std-and-packaging` (step 12's private `math` bodies)
**Owns:** `modules/compiler-core/src/codegen/erlang.zig` · `src/codegen/crossModule.zig` ·
`src/codegen/beam/{erl_ast,erl_emitter}.zig` (the Erlang-text renderer, a carve-out from 03 — the
erlang target and the comptime module text both go through it) · the erlang snapshots under
`snapshots/codegen/<runtime>/erlang/**` and `snapshots/codegen/<runtime>/errors/erlang/**` ·
`src/codegen/tests/erlang.zig` · the cells its steps add under `tests/language/{run,modules}/`
**Does not touch:** `src/comptime/**`, `src/parser/**` (01, 14, 18) · `src/codegen/beam_asm.zig`,
the rest of `src/codegen/beam/**` (03) · `src/codegen/{commonJS,typescript}.zig`, `codegen/js/**` (04)
· `src/codegen/wat.zig`, `codegen/wat/**` (05) · `modules/compiler-cli/**` (26) · `libs/std/**` (the
std track — this front hands it the measurement and the cell) · `codegen/tests/**` other than
`erlang.zig` (07)

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/`. `botopink build
--target erlang` never invokes `erlc`: every step runs `botopink run --target erlang`.

## Goal

Every erlang row the rakun sweep and C-07 found is a cell on four targets with one `.out`; the
erlang text never leans on an auto-imported BIF name, a template binding or the host locale; the
target honours decision 264's overflow rule and decision 263's one `math`.

## Done

- Step 1 — every BIF the codegen calls is qualified; `no_auto_import` for a user fn that shadows one (T13)
- Step 2 — the `while` fun is `__BpLoop<depth>` (T14)
- Step 3 — `'_botopink_init'/0` walked for helpers: a module-level `@print` in a dependency (C-34)
- Step 4, box 2 — the typing of a `default fn` body of `primitives.bp` (C-35's erlang half)
- Step 5, box 1 — `\u{…}` and non-ASCII literals in Erlang text; the entry point sets `standard_io` to unicode (C-36)
- Step 6 — `string.indexOf` counts codepoints (decisions 169, 240): `run/string_index_of_codepoints`, one `.out` for four targets
- Step 8 — the captured-`var` write: nothing lowers here (decision 148)
- Step 9 — the sibling loader under `build` (T1, with `26-cli-tooling` step 1)
- Step 10, box 1 — the producers of the block-as-value lowering measured (`src/codegen/AGENTS.md`)
- Step 11 — C-06's `KNOWN` notes and the `primitives.d.bp` / `@external(` sweep in `erlang.zig`
- Rows found by other fronts: a `default fn` body's `unwrapOr`/method calls, `true`/`false` in a
  tuple pattern, `Point(x: 0, ..)`, `throw` in a `case` arm of a `-> @Result` fn, the host locale,
  a lambda over an enclosing name (decision 205), a `default fn` two types adopt, `[..all]` alone,
  a `test/` module calling its own sidecar

## Open

### Step 4 — `run/array_unique` (C-35)

Decision 217: `unique` drops every duplicate, keeping first occurrences, compared with `==`. std's
new body is on feat (`primitives.bp`, the `Array.unique` default fn); on erlang nothing is left to
lower. The cell is this front's.

- [ ] `run/array_unique` — `[1, 2, 1, 3, 2].unique()` prints `[1, 2, 3]` on four targets (the wasm
      column with `05-wasm` step 1)

### Step 5 — a decorator body carrying `\u{…}` (box 2)

The renderer fix (step 5) serves the comptime module text too; the fixture is
`14-comptime-on-beam`'s file and is listed there (14 step 7).

### Step 7 — C-07's erlang tails as `run/` cells

§4.1's truth table answered by each §4.2 form (`is` on a primitive, a constructor, a tuple,
`Box<unknown>`) and §11's "erlang: nothing". `test/is_truth_table` holds on commonJS, erlang and
beam; the table as a program prints the same ten lines on commonJS, erlang and beam, and wasm
refuses it (`cannot box this value as unknown`, `05-wasm`'s row) — so no four-target `.out` can
land yet. §11 is pinned by `codegen/tests/control_flow.zig`'s needle (`A = 2.0,`): a program cannot
tell a stored value from an unboxed one.

- [ ] `run/is_truth_table` — every row of §4.1 × §4.2, one `.out` for four targets
- [ ] `run/unknown_stores_nothing` (§11) on four targets, or the box struck with a written reason
      (nothing a program prints differs)

### Step 10 — the block-as-value lowering (R7)

The only erlang site taking a block in value position is `@block`'s applied `fun`
(`builtinCallNode`), and it has genuine producers (`@block { return 3; }`, `@block { … };`); the
tail form decision 2 refuses goes through the same `fun`. Nothing in `erlang.zig` is deleted.

- [ ] `@block { 1 + 2 }` refused by the checker (`01-checker`'s row) — `snapshots/codegen/*/erlang/**`
      then byte-identical

### Step 12 — one `math` on every OS (decision 263)

The transcendental functions of `std/math` call std's own private botopink bodies (the fdlibm port)
on erlang too — `#[@External.Erlang("fn:tanBody")]` — and `pow` is decision 259's glibc port;
`sqrt`, `floor`, `abs` and the other exact operations stay host calls. Needs decision 238's `fn:`
form on the erlang binding (today `math.bp` binds `math:pow`, `math:tan`, … on erlang).

- [ ] the `fn:` form read on `@External.Erlang`; `run/std_math_on_every_target` green on erlang on
      `ubuntu-22.04` and `macos-14` with its exact values

### Step 13 — an integer that leaves its type aborts (decision 264)

`+`, `-`, `*`, unary `-` and the compound assignments of `i32` / `i64` / `u32` / `u64` (and the
narrower integer types) check the result against the declared type's range and abort — the abort
wasm already raises (`int_chk`). No target wraps, none answers a wider number.

- [ ] a `run/` cell per operator family whose overflow aborts on erlang as on wasm (`.exit`), and a
      result in range unchanged; erlang snapshots move by the range test only

### Rows found by other fronts

- [ ] a std module's module-level `var` lowers to `std@beam` on erlang, which the module does not
      import (found by `05-wasm` step 5; re-measure)

**Gate:** standard (fronts.md § Gate) + every re-recorded RUN LOG verified by running the program
under `erl`, nothing bulk-accepted · `zig build test-libs` erlang cells at baseline, rakun's members
re-run

## Notes

- **Erlang is not the oracle.** Where two backends disagree, the assertion is what the program
  means under decision 8, not what erlang prints.
- **This front moves only erlang snapshots.** A change that moves `snapshots/comptime/**` crossed
  into 01; one that moves the beam snapshots crossed into 03 (the shared renderer is the one place
  both can move: the comptime listings under `snapshots/codegen/beam/**` are 14's — report, do not
  re-record).
- `crossModule.zig` carries decision 109's atoms and layout; nothing here changes an atom.

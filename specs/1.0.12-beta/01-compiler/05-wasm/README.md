# Front 05 — wasm: no wrong answer at exit 0, and std builds on wasm

**Priority:** high · **State:** partial: steps 1–4 on feat (step 1's and step 3's last boxes wait on
02's cells); step 5 under way — vocabulary, codepoint unit, `math`, `escape`, `hash`, `io/random`,
heap growth, `String.fromCodepoint`, `pow`, astral `contentHash` on feat; `unicode`, `json`'s two
cells, the family cells and `wat/AGENTS.md` open
**Depends on:** `02-erlang` steps 4, 7 (cells) · `02-std-and-packaging` (`unicode.fromCodepoint`
over `String.fromCodepoint`, decision 262)
**Owns:** `modules/compiler-core/src/codegen/wat.zig` · `src/codegen/wat/**` except
`wasm_binary_emitter.zig` (18) · `snapshots/codegen/<runtime>/wasm/**`,
`snapshots/codegen/<runtime>/errors/wasm/**` · `src/codegen/tests/wat.zig` · its cells
**Does not touch:** `src/comptime/**`, `src/parser/**` (01, 14, 18) · `erlang.zig`, `crossModule.zig`,
`beam/{erl_ast,erl_emitter}.zig` (02) · `beam_asm.zig`, `beam/**` (03) · `commonJS.zig`,
`typescript.zig`, `js/**` (04) · `modules/compiler-cli/**` (26) · `libs/std/**` (std track) ·
`modules/wasm3/**`, `comptime/runtime/wat/**` (18)

Paths relative to `repository/botopink-lang/modules/compiler-core/src/`; run with `botopink run
--target wasm` (wasmtime).

## Goal

An impossible shape traps or is refused, never a wrong value at exit 0; `botopink build --target
wasm` in `libs/std` refuses only decision 241's group 3 (`io/clock`, `io/fs`, `testing/snapshots`);
std's `math` and `hash` answer commonJS's bits on every target.

## Mechanism

- **Primitive method table** — `primCallRes`, prelude groups `str_lines` … `arr_fill` (`wat/AGENTS.md`
  § The primitive method table); `newArrShape` for result shapes.
- **Host bindings** (decision 238) — `op:<wasm opcode>` (typed against the signature), `fn:<a
  private botopink fn of the same module>`, `wasi:<adapter>` (WASI preview1, list in `docs.md` §
  Host bindings); arguments = declared parameters in order; anything else a located error —
  `codegen/wat/host_binding.zig` (`parse`, `findOp`, `adapters`), `wat.zig` `checkHostBindings` /
  `emitHostBinding`. Read on a wasm build only; every-target reading = checker walk over
  `external_variants` (`01-checker`).
- **Numbers** (`wat/AGENTS.md` § Numbers) — float text = commonJS's; a float in a 4-byte slot is the
  address of its `f64` cell, `i64` is `i64`; `+ - *` trap when the result leaves its type
  (`int_chk`); nothing narrows silently (`lowerCoerced` / `emitConvert` refuse, located).

## Done

- Step 1 boxes 2–3 — primitive-method traps lowered (`run/string_lines_words`, `run/array_flat_forms`, `run/array_windows`, `run/array_fill`, `run/array_pop_removes`); no method listed as "trap"
- Step 2 — `==` between type-parameter values compares strings by content (`run/generic_string_equality`)
- Step 3 box 1 — one wasm fixture per tuple / `..` / type-pattern shape
- Step 4 — strict host-wrapper rule (decision 146; `run/external_wrapper_keeps_refusal`)
- Step 5 boxes 1–4 — `@External.Wasm` vocabulary (238); codepoint indices (240); `math`, `escape`, `hash`, `io/random` build (`run/std_{math,escape,hash,random}_on_every_target`)
- Step 5 — heap growth (261): every allocation through `$__alloc`, which calls `memory.grow` past `memory.size` and traps on a refused grow; `memory_size` / `memory_grow` in `wat_ast` and `wasm_binary_emitter.zig` (`run/heap_grows_past_one_page`; the hash cells one, `run/std_hash_on_every_target`, `pbkdf2Sha256(…, 9, 32)` in it) — `d71b89f5`
- Step 5 — `String.fromCodepoint` lowered (262): `$__str_from_cp`, a non-scalar value traps (`run/string_from_codepoint`, `run/string_from_codepoint_surrogate`); `json` and `encoding` build text with it through `fn:` bodies — `d71b89f5`
- Step 5 — `pow` is std's glibc port on four targets, transcendentals one body on every OS (259, 263): `run/std_math_on_every_target`'s `pow(158.42161580281933, 2.853827476501465)` row — `a443f52d`
- Step 5 — `contentHash` folds code points (260): `contentHashBody` without its surrogate step; `contentHash("🎉")`, `contentHash("a🎉b")` rows of `run/std_hash_on_every_target` — `d71b89f5`
- Floats, `i64`, overflow: `Float.toString` = V8's shortest digits, float slot keeps its `f64`, `i64` full width, overflow traps (`run/float_shortest_text`, `run/float_slot_keeps_f64`, `run/i64_full_width`; decision 264 for wasm)
- `val g = greet; g()` typed by the function's declaration (`run/fn_value_bound_by_val`)

## Open

### Step 8 — overflow for the unsigned and narrow integer types (decision 264)

`wat.zig` `emitArith` checks only `i32` / `i64`: `run/int_overflow_sub_u32` and
`run/int_overflow_add_i8` are red on wasm (`tests/language/AGENTS.md` says so), though d71b89f5
claims `i8` and `u32`.

- [ ] `u32`, `u64` and the narrow types (`i8`, `i16`, `u8`, `u16`) checked after `+`, `-`, `*`, unary
      `-` and `+=` on wasm; both cells green on wasm


### Step 1 — `Array.unique` on wasm (box 1)

`[3, 1, 1, 3].unique()` answers on four targets at feat; cell is 02's.

- [ ] `run/array_unique` (`02-erlang` step 4) green on wasm

### Step 3 — C-07's cells on wasm (box 2)

Truth-table program refused on wasm (`cannot box this value as unknown`) — blocks `02-erlang` step
7's four-target `.out`.

- [ ] `run/is_truth_table` and `run/unknown_stores_nothing` green on wasm, or a row wasm cannot
      answer traps and its `.wasm.expect` says so

### Step 5 — the rest of std on wasm (decisions 262, 241)

`unicode` binds nothing on wasm (`fromCodepoint`, `codepoints`, the four `normalize*` cells are Node /
Erlang templates; `unicode.fromCodepoint` a `fn:` over `String.fromCodepoint` is std's, decision
262); `json.parse` / `json.stringify` have no `@External.Wasm`. `run/std_module_imports_std_module`
keeps its `.wasm.expect`, `run/std_template_host_fns_across_modules` and
`run/std_default_fn_in_a_std_module` their `.targets`, though `encoding` now binds every cell on wasm.
The limits table of `wat/AGENTS.md` still carries the one-page row.

- [ ] `botopink build --target wasm` in `libs/std` refuses only group 3's modules (`unicode`,
      `json.parse` / `json.stringify` bound)
- [ ] a `run/` cell per remaining module family (`unicode`, `json`, `encoding`, `querystring`) on
      four targets, the commonJS answers
- [ ] `wat/AGENTS.md` § Where this backend refuses to answer lists only group 3; limits table loses
      the one-page row

### Rows found by other fronts

Each re-measured at the step that takes it; a holding row traps or is refused by name.

- [ ] `Array.range` / `Array.repeat` recurse per element through a spread (`primitives.bp`), O(n²)
      memory — `Array.repeat(0, 128)` exhausts the page; bodies double an array instead (std's file;
      limits table's open row)
- [ ] from `01-checker`: element read of a union array (`run/array_literal_union` reads `length`
      only), union of primitives a `case` produces (`test/case_value_union`), program-declared
      `default fn` of a primitive (`test/program_primitive_behavior_extends_std`), `?.b` on an absent
      element (`run/tuple_label_through_optional` keeps to the present half)
- [ ] nested constructor in a `val` binding (`val Pair(Circle(r), n) = p;`) refused on wasm —
      `01-checker` step 13's `run/val_nested_ctor_pattern` needs it lowered (each binding off its
      field's slot, as the one-level form)
- [ ] function read from a generic record's field, called through an untyped local, prints its
      pointer (`Box<T>(value: T)`; `modules/typeinfo_all_registration` uses a typed local — from
      `130-decorator-outputs`)

**Gate:** standard (fronts.md § Gate) + every re-recorded RUN LOG verified under wasmtime and
compared with commonJS's · no new RUN LOG answers at exit 0 a value another backend answers
differently · `RUNTIME TRAP` fixtures re-read: still impossible on wasm, or fixed

## Notes

- **`botopink test` refuses wasm**: only `run/` and `modules/` cells reach it.
- **Only wasm snapshots move here**; erlang/beam/commonJS moving = boundary crossed — stop, report.
- Comptime wat runtime non-parity = `18-comptime-runtimes`' limits, not this target's.

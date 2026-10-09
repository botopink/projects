# Front 05 — wasm: no wrong answer at exit 0, and std builds on wasm

**Priority:** high · **State:** partial: steps 1–4 on feat (step 1's and step 3's last boxes wait on
02's cells); step 5 under way — vocabulary, codepoint unit, `math`, `escape`, `hash`, `io/random`,
heap growth, `String.fromCodepoint`, `pow`, astral `contentHash`, `encoding` / `querystring` cells;
`unicode` waits on 05w-i (`normalize`), `json` on 05w-j (`parse` / `stringify`), the 305 spelling on
`01-checker` step 27
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
- **Host bindings** (decision 238; today's prefixed strings, labelled by 305 — `op: "…"`, `fn: name`,
  `wasi: .Adapter`, `01-checker` step 27) — `op:<wasm opcode>` (typed against the signature), `fn:<a
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
- Step 5 box 2 (part) — family cells on four targets: `run/std_encoding_on_every_target`,
  `run/std_querystring_on_every_target`; `run/std_module_imports_std_module` lost its `.wasm.expect`,
  `run/std_default_fn_in_a_std_module` its `.targets`; `unicode.codepoints` / `firstCodepoint` bound
  with `fn:` bodies; `run/std_json_on_every_target` and `run/std_unicode_on_every_target` on three
  targets, refused on wasm by name (`.wasm.expect`) until 05w-j / 05w-i
- Wrong answers at exit 0 the std cells found, closed: a namespace call to a mangled function
  (`url.parse` beside `querystring.parse`, `run/std_namespace_calls_same_name`); a `?T` tuple element —
  printed, read through `._N`, a generic method's `#(Q<T>, ?T)` (`run/tuple_optional_element`);
  `o.unwrapOr(d)` keeping the payload's tuple shape
- `wat/AGENTS.md`'s limits table lost the one-page row (decision 261)
- An `@block`'s `return` is the block's value (decision 2): `lowerBlockWithReturn` stores into
  `$__blk<n>` and branches out of `$__blkend<n>` instead of `return` from the enclosing function;
  the block's type and string/bool shape read off its returns (`run/block_return_is_block_value`,
  four targets; `block_block_builtin` wasm snapshots move)
- Step 8 — the narrow and unsigned integer types check their own range on wasm (264): `emitRangeCheck`
  after the carrier's checked `+`, `-`, `*`, unary `-`, `+=` (`$__i32_range_chk` for `i8`/`u8`/`i16`/
  `u16`, `$__i64_range_chk` for `u32`/`u64`; a `u64` ends at `2^63 − 1` in its `i64` carrier)
  (`run/int_overflow_add_i8`, `run/int_overflow_sub_u32` green on wasm)

## Open

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

- [ ] `botopink build --target wasm` in `libs/std` refuses only group 3's modules (`unicode` waits on
      `decisions-pending.md` 05w-i, `json.parse` / `json.stringify` on 05w-j)
- [ ] a `run/` cell per remaining module family on four targets, the commonJS answers — `unicode`
      and `json` drop their `.wasm.expect` once 05w-i / 05w-j land (`encoding`, `querystring` done)
- [ ] `wat/AGENTS.md` § Where this backend refuses to answer lists only group 3 (the limits table's
      one-page row is gone)
- [ ] the bindings this step adds written in 305's form — `@External.Wasm(fn: name)`, `op: "…"`,
      `wasi: .Adapter` — never the prefixed string: the parser refuses `fn: name` until `01-checker`
      step 27, so `unicode`'s two new bindings are prefixed strings that step migrates

### Rows found by other fronts

Each re-measured at the step that takes it; a holding row traps or is refused by name.

- [ ] `Array.range` / `Array.repeat` recurse per element through a spread (`primitives.bp`), O(n²)
      memory — `Array.repeat(0, 128)` exhausts the page; bodies double an array instead (std's file;
      limits table's open row)
- [ ] from `01-checker`: element read of a union array (`run/array_literal_union` reads `length`
      only), union of primitives a `case` produces (`test/case_value_union`), program-declared
      `default fn` of a primitive (`test/program_primitive_behavior_extends_std`), `?.b` on an absent
      element (`run/tuple_label_through_optional` keeps to the present half) — re-measured by `07`
      step 5: no trap, a wrong value at exit 0: `es.at(3)?.a ?? 0` and `rs.at(5)?.a ?? -1` over
      `#(a: i32, b: string)[]` print `8` on wasm where commonJS, erlang and beam print `0`, `-1`
      (`codegen/tests/beam.zig`'s `?. on an absent tuple element …` program)
- [ ] nested constructor in a `val` binding (`val Pair(Circle(r), n) = p;`) refused on wasm —
      `01-checker` step 13's `run/val_nested_ctor_pattern` needs it lowered (each binding off its
      field's slot, as the one-level form)
- [ ] function read from a generic record's field, called through an untyped local, prints its
      pointer (`Box<T>(value: T)`; `modules/typeinfo_all_registration` uses a typed local — from
      `130-decorator-outputs`)
- [ ] `@print` of a generic record prints a field typed by a type parameter as a word:
      `Q(items: [7])` over `Q<T>(items: Array<T>)` prints `Q(items: 308)`, `B(v: "s")` prints
      `B(v: 292)` at exit 0 (one descriptor per declaration, not per instantiation) — found by step 5
- [ ] a primitive `default fn` from `primitives.bp` reached on wasm (`"1.5".parseFloat()`) is refused
      at the PRELUDE's line under the caller's file name (`std/json.bp:341:13` for
      `primitives.bp:341`'s `stringSlice0`) — `ensurePrimDefault`'s copy carries no origin; and the
      refusal itself: `stringSlice0` / `stringToFloat` have no wasm cell — found by step 5
- [ ] `_` in a variant payload pattern binds `0` on wasm
- [ ] a nested variant pattern answers wrong on wasm
- [ ] unsigned compare and divide use the signed opcodes on wasm

**Gate:** standard (fronts.md § Gate) + every re-recorded RUN LOG verified under wasmtime and
compared with commonJS's · no new RUN LOG answers at exit 0 a value another backend answers
differently · `RUNTIME TRAP` fixtures re-read: still impossible on wasm, or fixed

## Notes

- **`botopink test` refuses wasm**: only `run/` and `modules/` cells reach it.
- **Only wasm snapshots move here**; erlang/beam/commonJS moving = boundary crossed — stop, report.
- Comptime wat runtime non-parity = `18-comptime-runtimes`' limits, not this target's.

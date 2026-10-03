# Front 05 — wasm: no wrong answer at exit 0, and std builds on wasm

**Priority:** high · **State:** partial: steps 1–4 on feat (step 1's and step 3's last boxes wait on
02's cells); step 5 under way — the vocabulary, the codepoint unit, `math`, `escape`, `hash`,
`io/random` build; decisions 259–263 to build
**Depends on:** `02-erlang` steps 4 and 7 (the cells) · `02-std-and-packaging` (the std bodies of
decisions 259, 260, 262) · `18-comptime-runtimes` (decision 261's two opcodes in the binary emitter)
**Owns:** `modules/compiler-core/src/codegen/wat.zig` · `src/codegen/wat/**` except
`wasm_binary_emitter.zig` (18's) · the wasm snapshots under `snapshots/codegen/<runtime>/wasm/**` and
`snapshots/codegen/<runtime>/errors/wasm/**` · `src/codegen/tests/wat.zig` · the cells its steps add
**Does not touch:** `src/comptime/**`, `src/parser/**` (01, 14, 18) · `erlang.zig`, `crossModule.zig`,
`beam/{erl_ast,erl_emitter}.zig` (02) · `beam_asm.zig`, `beam/**` (03) · `commonJS.zig`,
`typescript.zig`, `js/**` (04) · `modules/compiler-cli/**` (26) · `libs/std/**` (the std track) ·
`modules/wasm3/**`, `comptime/runtime/wat/**` (18)

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/`; programs run with
`botopink run --target wasm` (wasmtime).

## Goal

A shape wasm cannot do traps or is refused, never answers a wrong value at exit 0; `botopink build
--target wasm` in `libs/std` refuses only decision 241's group 3 (`io/clock`, `io/fs`,
`testing/snapshots`), and std's `math` and `hash` answer commonJS's bits on every target.

## Mechanism

- **The primitive method table** — `primCallRes` and the prelude groups `str_lines` … `arr_fill`
  (`wat/AGENTS.md` § The primitive method table); `newArrShape` for the results' shapes.
- **Host bindings** (decision 238) — `op:<wasm opcode>` (typed against the signature), `fn:<a
  private botopink fn of the same module>`, `wasi:<adapter>` (WASI preview1, the list in `docs.md`
  § Host bindings), the arguments the declared parameters in order, anything else a located error —
  `codegen/wat/host_binding.zig` (`parse`, `findOp`, `adapters`), `wat.zig` `checkHostBindings` /
  `emitHostBinding`. A wasm binding is read on a wasm build only; reading it on every target is the
  checker's walk over `external_variants` (`01-checker`).
- **Numbers** (`wat/AGENTS.md` § Numbers) — a float's text is commonJS's; every float in a 4-byte
  slot is the address of its `f64` cell, an `i64` is an `i64`; `+ - *` trap where the result leaves
  its type (`int_chk`); nothing narrows silently (`lowerCoerced` / `emitConvert` refuse, located).

## Done

- Step 1, boxes 2–3 — the primitive-method traps lowered (`run/string_lines_words`, `run/array_flat_forms`, `run/array_windows`, `run/array_fill`, `run/array_pop_removes`); no method listed as "trap"
- Step 2 — `==` between type-parameter values compares strings by content (`run/generic_string_equality`)
- Step 3, box 1 — one wasm fixture per tuple / `..` / type-pattern shape
- Step 4 — the strict host-wrapper rule holds (decision 146; `run/external_wrapper_keeps_refusal`)
- Step 5, boxes 1–4 — the `@External.Wasm` vocabulary (decision 238); codepoint indices (decision 240); `math`, `escape`, `hash`, `io/random` build (`run/std_{math,escape,hash_digests,hash_macs,hash_content,random}_on_every_target`)
- Floats, `i64` and integer overflow: `Float.toString` writes V8's shortest digits, a float slot keeps its `f64`, `i64` full width, overflow traps (`run/float_shortest_text`, `run/float_slot_keeps_f64`, `run/i64_full_width`; decision 264 for wasm)
- `val g = greet; g()` typed by the function's declaration (`run/fn_value_bound_by_val`)

## Open

### Step 1 — `Array.unique` on wasm (box 1)

`[3, 1, 1, 3].unique()` answers on four targets at feat; the cell is 02's.

- [ ] `run/array_unique` (`02-erlang` step 4) green on wasm

### Step 3 — C-07's cells on wasm (box 2)

The truth table as a program is refused on wasm (`cannot box this value as unknown`) — the row
that keeps `02-erlang` step 7's four-target `.out` from landing.

- [ ] `run/is_truth_table` and `run/unknown_stores_nothing` green on wasm, or a row wasm cannot
      answer traps and its `.wasm.expect` says so

### Step 5 — the rest of std on wasm (decisions 259–263)

| Item | Decision | What to build |
|---|---|---|
| heap growth | 261 | every allocation through a helper that calls `memory.grow` when the bump pointer passes `memory.size` (a failed grow traps); `wat_ast` gains `memory.size` / `memory.grow`, `wasm_binary_emitter.zig` its two opcodes (18). Today one 64 KiB page, `min_pages = 1` (`wat/AGENTS.md` § Host bindings, the limits table): `pbkdf2Sha256(…, 9, 32)` traps, the hash cells are three, not one |
| `String.fromCodepoint(cp: i32) -> string` | 262 | a primitive in `primitives.bp` (std's) — Node `String.fromCodePoint`, erlang `<<Cp/utf8>>`, wasm a prelude helper writing the UTF-8 bytes; `unicode.fromCodepoint` becomes a `fn:` over it. Unblocks `unicode`, `json`, `encoding` (and so `querystring`), each of which answers text built from code points |
| `pow` | 259 | std's private botopink port of glibc's `pow` (the algorithm since glibc 2.28, its 128-entry `log` and `exp` tables) replaces the double-double `powBody`; under 263 it is `pow` on every target, commonJS included |
| `contentHash` above U+FFFF | 260 | the code points: `contentHash("🎉")` is `djb2([127881])` on every target; the wasm body (`contentHashBody`) drops its surrogate step, the Node template folds `Array.from(s)` (std's) |
| one `math` on every OS | 263 | the transcendental functions call std's private bodies on erlang and beam too (`02-erlang` step 12, `03-beam` step 7); nothing left on wasm but 259's `pow` |

- [ ] `memory.grow`: an allocation past 64 KiB succeeds; `run/std_hash_*` may merge into one cell;
      `pbkdf2Sha256(…, 9, 32)` runs
- [ ] `String.fromCodepoint` lowered on wasm; `botopink build --target wasm` in `libs/std` refuses
      only group 3's modules
- [ ] a `run/` cell per remaining module family (`unicode`, `json`, `encoding`, `querystring`) on
      four targets, the commonJS answers
- [ ] `run/std_math_on_every_target` with decision 259's `pow`, green on `ubuntu-22.04` and `macos-14`
- [ ] `contentHash` of astral text equal on four targets (a row in `run/std_hash_content_on_every_target`)
- [ ] `wat/AGENTS.md` § Where this backend refuses to answer lists only group 3; the limits table
      loses the one-page row

### Rows found by other fronts

Each re-measured at the step that takes it; a row that holds traps or is refused by name.

- [ ] `Array.range` / `Array.repeat` recurse once per element through a spread (`primitives.bp`),
      O(n²) memory — `Array.repeat(0, 128)` exhausts the page; the bodies double an array instead
      (std's file; the limits table's open row)
- [ ] an element read of a union array (`run/array_literal_union` reads `length` only), a union of
      primitives a `case` produces (`test/case_value_union` is a `test/` cell for it), a
      program-declared `default fn` of a primitive (`test/program_primitive_behavior_extends_std`),
      `?.b` on an absent element (`run/tuple_label_through_optional` keeps to the present half) —
      registered by `01-checker`
- [ ] a function read from a generic record's field and called through an untyped local prints its
      pointer (`Box<T>(value: T)`; `modules/typeinfo_all_registration` calls through a typed local —
      registered by `130-decorator-outputs`)

**Gate:** standard (fronts.md § Gate) + every re-recorded RUN LOG verified under wasmtime and
compared with commonJS's for the same fixture · no new RUN LOG answers a value with exit 0 that
another backend answers differently · the `RUNTIME TRAP` fixtures re-read: each is still a shape
wasm cannot do, or it is fixed

## Notes

- **`botopink test` refuses wasm**, so only `run/` and `modules/` cells reach it.
- **This front moves only wasm snapshots.** A change that moves erlang, beam or commonJS snapshots
  crossed a boundary — stop and report.
- The comptime wat runtime's non-parity items are `18-comptime-runtimes`' limits, not this target's.

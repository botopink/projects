# Front 05 — wasm: no wrong answer at exit 0, and std builds on wasm

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [144-botopink-lang](../README.md): s5 → B-00e · rows → B-22 · s9 → B-25. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** high · **State:** partial: steps 1–4 on feat; step 5 under way — vocabulary, codepoint unit, `math`, `escape`, `hash`, `io/random`,
heap growth, `String.fromCodepoint`, `pow`, astral `contentHash`, `encoding` / `querystring` cells;
`unicode` waits on `02/97` step 16 (333 (A): `normalize` in botopink), `json` on `02/97` step 15 (336: `parse` / `stringify` go), the 305 spelling on
`01-checker` step 27
**Depends on:** `02-std-and-packaging` (`unicode.fromCodepoint`
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

## Notes

- **`botopink test` refuses wasm**: only `run/` and `modules/` cells reach it.
- **Only wasm snapshots move here**; erlang/beam/commonJS moving = boundary crossed — stop, report.
- Comptime wat runtime non-parity = `18-comptime-runtimes`' limits, not this target's.

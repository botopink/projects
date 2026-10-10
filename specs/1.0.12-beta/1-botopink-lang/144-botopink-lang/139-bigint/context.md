# Front 139 — `bigint`: an integer of any size, a primitive on the four targets

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [144-botopink-lang](../README.md): open → B-24. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** medium — `Json` (decision 332 (4)) and every exact integer past `i64` stand on it; no
library needs it to compile today · **State:** steps 1–5 built on `front/bigint-139` (patch, lands
through the coordinator); open: 139-a's alternatives, the wasm union row
**Depends on:** decision 332 · `04-js` step 9 (319's hybrid number, the commonJS pattern this front
extends) · `05-wasm` step 8 (the integer checks this front's wasm library sits beside)
**Owns:** the `bigint` arms of `src/lexer.zig` / `src/lexer/**` (the `n` suffix), `src/parser/**`,
`src/comptime/{infer,types,unify}.zig` — named carve-outs of `01-checker`'s files, one commit with
its cells · the `bigint` lowering in `codegen/erlang.zig`, `codegen/beam_asm.zig`,
`codegen/commonJS.zig` + `codegen/js/**`, `codegen/wat.zig` + `codegen/wat/**` — named carve-outs of
02, 03, 04, 05, each in its own commit after that front's open steps · `libs/std/src/primitives.bp`'s
`behavior BigInt` (with 134) · its `run/`, `reject/` and `modules/` cells under `tests/language/`
**Does not touch:** `Decimal` and `Json` (std, `02/97` step 15) · `#[validated]`'s bind
(`03-bundled-libs/125`) · the other numeric types

Paths relative to `repository/botopink-lang/modules/compiler-core/src/`.

## Goal

Decision 332 (1): `bigint` is a primitive integer of any size — the operators every integer has
(`+ - * / %`, unary `-`, `+=`, comparisons, `==`), never an overflow, a literal with the lowercase
suffix `n` (247's family): `123456789012345678901234567890n`. Erlang and beam use the VM's own integer
(already unbounded); commonJS uses `BigInt`; wasm uses a library in the module's runtime. One value on
the four targets.

```bp
val big: bigint = 2n;
var x = big;
var i = 0;
while (i < 100) {
    x = x * big;
    i += 1;
}
@print(x);                        // 2^101, the same digits on the four targets
val n: i64 = x.toI64();           // aborts: `toI64: 2535301200456458802993406410752 does not fit i64`
```

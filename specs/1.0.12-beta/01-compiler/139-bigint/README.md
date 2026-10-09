# Front 139 — `bigint`: an integer of any size, a primitive on the four targets

**Priority:** medium — `Json` (decision 332 (4)) and every exact integer past `i64` stand on it; no
library needs it to compile today · **State:** not started
**Depends on:** decision 332 · `04-js` step 9 (319's hybrid number, the commonJS pattern this front
extends) · `05-wasm` step 8 (the integer checks this front's wasm library sits beside)
**Owns:** the `bigint` arms of `src/lexer.zig` / `src/lexer/**` (the `n` suffix), `src/parser/**`,
`src/comptime/{infer,types,unify}.zig` — named carve-outs of `01-checker`'s files, one commit with
its cells · the `bigint` lowering in `codegen/erlang.zig`, `codegen/beam_asm.zig`,
`codegen/commonJS.zig` + `codegen/js/**`, `codegen/wat.zig` + `codegen/wat/**` — named carve-outs of
02, 03, 04, 05, each in its own commit after that front's open steps · `libs/std/src/builtins.d.bp`'s
`bigint` row (with 134) · its `run/` and `reject/` cells under `tests/language/`
**Does not touch:** `Decimal` and `Json` (std, `02/97` step 15) · `#[validated]`'s bind
(`03-bundled-libs/125`) · the other numeric types

Paths relative to `repository/botopink-lang/modules/compiler-core/src/`.

## Goal

Decision 332 (1): `bigint` is a primitive integer of any size — the operators every integer has
(`+ - * / %`, unary `-`, the compound assignments, comparisons, `==`), never an overflow, a literal
with the lowercase suffix `n` (247's family): `123456789012345678901234567890n`. Erlang and beam
use the VM's own integer (already unbounded); commonJS uses `BigInt`; wasm uses a library in the
module's runtime. One value on the four targets.

```bp
val big: bigint = 2n;
var x = big;
for (range(0, 100)) { _ -> x = x * big; }
@print(x);                        // 2^101, the same digits on the four targets
val n: i64 = x.toI64();           // aborts: past `i64` (264's located message)
```

## Open

### Step 1 — the type, the literal, the checker

- [ ] `bigint` in `builtins.d.bp` (252) with `toString()`, `toI64() -> i64` (aborts past the range, 264's
      text), `toF64() -> f64`, `of(n: i64) -> bigint` (associated), `parse(text: string) -> @Result<bigint, string>`
- [ ] lexer: the `n` suffix on an integer literal (no fraction, no exponent: `1.5n` is a located error);
      an unsuffixed literal never becomes `bigint` (247)
- [ ] checker: the integer operators over two `bigint`s; a `bigint` beside another integer type is the
      ordinary mismatch — the conversion is written (`bigint.of(x)`, `b.toI64()`); `/` truncates toward
      zero, `%` takes the dividend's sign, `/` or `%` by zero aborts (264's division text)
- [ ] `reject/` cells: `1.5n`, `2n + 1`, `val x: i64 = 2n`

### Step 2 — erlang and beam

- [ ] the VM's integer, no range check; `toI64` checks; the cells below green on both

### Step 3 — commonJS

- [ ] `BigInt` (`42n`), operators on `BigInt`; `/` as `BigInt` division (truncates toward zero, as the
      others); the emitted `.d.ts` types it `bigint`; `tsc-check.sh` green

### Step 4 — wasm

- [ ] a `bigint` library in the module's runtime (sign + magnitude limbs over linear memory; add, sub,
      mul, divmod, compare, to/from decimal text), linked only when a module uses `bigint`; the
      measured size recorded in `wat/AGENTS.md`

### Step 5 — one answer on four targets

- [ ] `run/bigint_arithmetic` (2^101, a product of two 40-digit numbers, a negative division, `%`,
      comparison, `toString`) one `.out` for the four targets; `run/bigint_to_i64_aborts`
- [ ] `docs.md` § Numeric types gains the row (07's prose)

**Gate:** standard (fronts.md § Gate) + `zig build test-language` (the four targets) and
`scripts/tsc-check.sh`.

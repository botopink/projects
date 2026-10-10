# Front 139 — `bigint`: an integer of any size, a primitive on the four targets

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

## Done

- Step 1 — the type, the literal, the checker. `n` in `lexer.number_suffixes` (`1.5n` / `1e3n` are
  `number-suffix-integer-on-float`, `42N` `number-suffix-uppercase`); the literal keeps its `n` in the
  program the backends lower (`lexer.isBigintText`). `bigint` a primitive (`Env.registerBuiltins`,
  `scalar_type_names`, the parser's and the language server's mirrors), outside `isIntType`: no
  promotion, a `bigint` beside another number is the ordinary mismatch; an unsuffixed literal where a
  `bigint` is expected is refused naming `<n>n`. An operator records `ArithKind.bigint` (no range).
  The surface is `primitives.bp`'s `behavior BigInt` (`PrimKind.bigint`): `toString()`, `toI64()`
  (aborts past the range, 264's text), `toF64()` (aborts unless exact), and `bigint.of(n: i64)` /
  `bigint.parse(text) -> @Result<bigint, string>` as associated host primitives of decision 262's form
  (choice 139-b ★), the receiver renamed `BigInt` for the backends. 139-a (a) ★ built: no widening to
  `unknown` (`bigint-widened`), no `is` / type pattern over one (`bigint-type-test`), no `comptime`
  computing one (`comptime-bigint`). Cells: `reject/bigint_literal_fraction`,
  `reject/bigint_plus_int_literal`, `reject/bigint_into_i64`, `reject/bigint_unsuffixed_literal`,
  `reject/bigint_type_test`, `reject/bigint_into_unknown`, `reject/bigint_comptime`.
- Step 2 — erlang and beam: the VM's integer, the literal without its `n` (`erl_emitter`
  `bigintNumeralDigits`), no range check; `toI64` / `toF64` / `parse` std's Erlang forms.
- Step 3 — commonJS: a `BigInt` always (never 319's hybrid), the native operators, `/` and `%` through
  `__bp_bdiv` / `__bp_bmod` (264's `integer division by zero` text); the `.d.ts` types it `bigint`
  (`modules/bigint_across_modules` through `scripts/tsc-check.sh`, green). `Integer.toI64`'s Node form
  answers the canonical form, one text with `BigInt.toI64`'s (both patch `BigInt.prototype`).
- Step 4 — wasm: the `bigint` helper group (`wat/wat_prelude.zig` § bigint: sign and `u32` limbs in an
  immutable block; add, sub, mul, divmod, compare, of/to `i64`, to `f64`, to and from decimal text),
  linked only when a module calls it — ≈ 2.9 KB, measured in `wat/AGENTS.md` § `bigint`; a literal a
  data segment; containers print by the `n` shape code and compare by value.
- Step 5 — `run/bigint_arithmetic` (2^101, a product of two 40-digit numbers, negative `/` and `%`,
  comparisons, `toString`, `bigint.of` / `parse`, `toI64`, `toF64`; checked against Python's integers)
  one `.out` for the four targets and both wasm hosts; `run/bigint_in_containers`,
  `run/bigint_to_i64_aborts`, `run/bigint_division_by_zero`, `modules/bigint_across_modules`;
  `docs.md` § Numbers (the row and its paragraph), § Numeric literals, § Primitives.

## Open

- [ ] 139-a's alternatives, if the maintainer answers (b) or (c): `is bigint` by value range, a
      `bigint` in `unknown`, compile-time `bigint` in the folder and the comptime runtimes (14 · 18)
- [ ] wasm: a `bigint` member of a union (`lowerAsUnknown` refuses it located, "has no `bigint` in a
      union yet"; erlang, beam and commonJS run it) — a `05-wasm` row

**Gate:** standard (fronts.md § Gate) + `zig build test-language` (the four targets) and
`scripts/tsc-check.sh`.

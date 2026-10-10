# Front 04 — js: commonJS keeps no dead lowering and no marker std alone may write

**Priority:** medium · **State:** partial: steps 1–5, 7, 8 and C-37 done; steps 9 and 10 done on commonJS but for
`Json` (332), the conversions (a std surface) and the string-read cost (+24 % against 10 %); steps 6, 11, 12 open
**Depends on:** step 6's typed AST (step 6)
**Owns:** `modules/compiler-core/src/codegen/commonJS.zig` · `src/codegen/typescript.zig` ·
`src/codegen/js/**` · `src/comptime/primOpTemplate.zig`'s `$stringify` arm (step 2, decision 239) ·
`snapshots/codegen/<runtime>/commonJS/**`, `snapshots/codegen/<runtime>/errors/commonJS/**` (each
carrying the TypeScript typedef; no `typescript/` dir) · `src/codegen/tests/commonjs.zig` ·
`scripts/tsc-check.sh` · its cells
**Does not touch:** rest of `src/comptime/**`, `src/parser/**` (01, 14, 18) · `erlang.zig`,
`crossModule.zig`, `beam/{erl_ast,erl_emitter}.zig` (02) · `beam_asm.zig`, `beam/**` (03) ·
`wat.zig`, `wat/**` (05) · `modules/compiler-cli/**` (26) · `libs/std/**` (std track)

Paths relative to `repository/botopink-lang/modules/compiler-core/src/`.

## Goal

No lowering whose only producer the checker should refuse; no template marker std alone may write;
`throw` in a `case` arm answers `Error` from the function; out-of-range integer aborts (decision 264); `i64` keeps the full range, a number below 2^53 and a `BigInt` above (319).

## Done

Step 3 `scripts/tsc-check.sh` (gate stage 11, `tsc` 7.0.2 via `npx`, every emitted module also
`node --check`ed); `run/number_method_call` · 4 redeclared binding has no producer (152, 205):
`run/sibling_blocks_bind_one_name` · 5 no `unwrapOrThrow` ships (179), in `js/AGENTS.md` · 7
`default fn` body lowered without the checker: `self` as the primitive, `Ok`/`Error` as the object ·
1 box 1 `@block` IIFE producers measured (`js/AGENTS.md` § The IIFE build sites) · C-37
`charCodeAt` prelude patch calls `codePointAt`, never itself · 8 an integer out of its type aborts
(264): `__bp_int` (`intChecked`, `js_prelude` `int_check`), `i64` range ±(2^53−1)
(`ArithKind.rangeExactDouble`), `/`·`%` by zero `integer division by zero` — 02 step 13's cells with
`.commonJS.stderr`, `run/int_overflow_mul_i64` past both bounds, `run/int_division_by_zero`
(`48a096ea`) · 1 the `@block` tail form never reaches commonJS: `01-checker`'s `block-tail-value`
refuses it (`reject/block_tail_value`, every target; it printed `null` here), the one IIFE lowering
serves the two shapes left (`@block { return 3; }`, statement `@block { … };`), no commonJS
snapshot moved (`js/AGENTS.md` § The IIFE build sites) · 2 `$stringify` is no marker (164, 239):
`primOpTemplate.render`'s arm and erlang's / beam's `emitStringifyOpen` / `emitStringifyClose`
deleted (carve-out into `erlang.zig`, `beam_asm.zig`), `render: $stringify is no marker — its bytes
pass through` red on the parent; the refusal is `reject/template_stringify_marker` (01-checker's,
every target); no snapshot moved. · 9 (most) `i64`/`isize`/`u64`/`usize` hybrid on commonJS (319):
`js_prelude` `wide_norm`/`wide_add`…`wide_neg` through `wideOp` (number fast path, `BigInt` past
±(2^53 − 1), aborts at the type's own bounds), a literal past 2^53 written `…n`, `__bp_show` prints a
`BigInt`'s digits, `x is i64` reads both forms, `.d.ts` `number | bigint`, `rangeExactDouble` deleted,
`refuseBeyondJsSafeInteger` deleted (checker patch); `run/i64_full_range`, `run/int_overflow_sub_i64_min`,
`run/int_overflow_add_u64_max` (`%` / `/` past 2^53), `run/i64_dict_key_across_safe_edge`; the loop
995 → 687 ms (`js/AGENTS.md` § 64-bit integers) · 10 (commonJS) string indices count codepoints (320):
`__bp_has_surrogate` + `__bp_str_length` / `__bp_string_char_at` / `__bp_str_index_of` /
`__bp_str_last_index_of`, std's Node `stringSlice0`/`stringSlice1`/`charCodeAt` cells;
`run/string_index_of_codepoints` (strcp-erl's) green on commonJS, `run/string_codepoint_slice_and_code`.

## Open

### Step 6 — `throw` in a `case` arm (after `01-checker` step 6)

Typed AST marks the arm's `throw` as the enclosing function's (today `JumpInValuePosition` at
codegen); the arm emits `return {Error: e}`.

- [ ] `run/throw_in_case_arm_result` green on commonJS; `isError()` true on the throw path

### Rows found by other fronts

- [ ] module with a module-level `val` initialised by a call (`val t = "a b".split(" ")`) fails a
      commonJS build with a bare `TypeError` when any of its functions calls `Float.floor` (from
      `05-wasm` step 5, comptime path; re-measure, name the owner)
- [ ] `Point(x: 0, ..)` in a `case` answers `null` on commonJS (from `02-erlang`; re-measure)
- [ ] an `@block` whose `return` is valued on some paths and that falls through to a tail on
      another checks: `val a = @block { if (c) return 3; 4 };` answers `null` on commonJS on the
      fall-through path and `4` (the tail) on erlang, beam and wasm — decision 2 gives that path no
      value, so the checker refuses it (owner `01-checker`; found by step 1)
- [ ] `return` inside an `@block` in value position leaves the enclosing function on beam and wasm:
      `pub fn main() { val b = @block { return 5; }; @print(b); @print(7); }` prints nothing there,
      `5` and `7` on commonJS and erlang (C1: the block owns its `return`s; owners `03-beam`,
      `05-wasm`; found by step 1)
- [x] `??` lowering defeats the self-tail-call loop: `a ?? b` lowers to an IIFE
      (`(() => { const __bp_nullish = a; if (__bp_nullish != null) … })()`) whose body reads the
      function's parameters, so `NameScan` (`commonJS.zig`, closure_only) counts a closure capture and
      the `while (true)` rewrite is refused. std `path.bp` `resolveAll(segments, i, state)`
      (`val seg = segments.at(i) ?? "";` then `return resolveAll(segments, i + 1, next);`) recursed in a
      loop before 330's migration (`.unwrapOr("")` lowered to `((_o) => …)(arg)`, its argument outside
      the arrow) and now recurses one JS frame per segment — stack depth on deep inputs (found by
      checker-330's integration; snapshot `std_package_a_root_module_importing_from_io_is_refused_at_the_item`)
      — an immediately invoked plain arrow or `function` is scanned in the caller's zone
      (`NameScan.immediateBody`); `resolveAll` / `applyPieces` loop again, the two snapshots re-recorded
      (bugs-sweep)

### Step 9 — `i64`, `u64`, `isize`, `usize`: a number, a `BigInt` past 2^53 (decision 319)

Today these four lower to JS numbers and 264's check bounds them at ±(2^53−1)
(`ArithKind.rangeExactDouble`): `9007199254740991l + 1l` aborts on commonJS and answers on the other
three targets. After, they keep the full range at a low cost: a value within ±(2^53−1) stays a JS
`number`, a value beyond it is a `BigInt`, always in that canonical form.

```js
function i64add(a, b) {
  if (typeof a === "number" && typeof b === "number") {
    const r = a + b;
    if (Number.isSafeInteger(r)) return r;        // the common case: today's cost
  }
  return norm(BigInt(a) + BigInt(b));             // promoted; checked against ±2^63, back to number when it fits
}
```

- [x] lowering: every operation on the four types (`+ - * / %`, unary `-`, the compound assignments,
      comparisons) through a prelude helper with the number fast path; the slow path computes in
      `BigInt`, aborts past −2^63 … 2^63 − 1 / 0 … 2^64 − 1 (`__bp_int`), and answers the canonical form;
      a literal is a number when safe, else `123…n`; `rangeExactDouble` deleted
- [ ] canonical form kept by every producer (operations, literals, conversions, `Json`, host templates)
      — operations and literals done; `Json` waits on 332 (`139`, then `02/97` step 15's `Json` integer); std's `Math.min`/`max`/`abs` cells and
      `Integer`'s `default fn`s (`isEven`, `clamp`) throw a `TypeError` on a `BigInt` (97 step 13):
      `==` stays `===`, a `Dict` / `Set` keyed by `i64` keys by value — one cell each across the 2^53 edge
- [ ] conversions explicit and exact (no `toF64()` / `toI32()` is declared anywhere yet — std surface first):
      widening `i32 → i64` is free (already canonical); `@print` and string interpolation print the digits
      (no `n`)
- [x] a Node host template taking or answering one of the four types sees `number | bigint` (canonical);
      the emitted `.d.ts` types them `number | bigint`; `scripts/tsc-check.sh` green
- [x] cost measured: a loop of i64 additions below 2^53 within 10% of today's `int_check` build (the
      number recorded in `js/AGENTS.md`)
- [x] `run/i64_full_range` (`9007199254740991l + 1l`, `9223372036854775807l`, `-9223372036854775808l`, the
      `u64` top, a value crossing back below 2^53, an overflow past each bound) answers alike on the four
      targets; `run/int_overflow_mul_i64` re-recorded — commonJS now aborts where the others do
      — the minimum is written `-9223372036854775807l - 1l` (the checker refuses
      `-9223372036854775808l`: the literal's digits are past `i64`, a `01-checker` row); the `u64` half is
      `run/int_overflow_add_u64_max`, red on wasm only (prints the top as `-1`, traps on
      `18446744073709551614ul + 1ul`; a `05-wasm` row)
- [ ] `docs.md` § Integer overflow's commonJS paragraph rewritten (handed to `07-residuals`, owner of the prose)

### Step 10 — a string index counts codepoints (decision 320)

Today commonJS answers JavaScript's UTF-16 units: `"👍".length` is 2 there, 1 on the other targets.
After, the same codepoint count, at a low cost:

```js
function strLength(s) {
  return HAS_PAIR.test(s) ? cpLength(s) : s.length;   // no surrogate pair: JavaScript's own answer
}
```

- [x] `length`, `at`, `slice`, `indexOf`, `lastIndexOf` (and every std primitive taking or answering a
      string index) through prelude helpers: a string without a surrogate pair uses the native index,
      one with a pair is walked by codepoint; an index past a pair is a codepoint index on input and output
- [x] a JS host template receives and answers codepoint indices
- [x] cost measured: the helpers on strings without a pair within 10% of the native calls (recorded in
      `js/AGENTS.md` § String indices, with the benchmark's source) — a read tests its BINDING, not
      itself (`js/str_slots.zig`: a parameter or `val` bound once gets a lazy `<name>$sp` slot; a
      surrogate-free literal or a `val` bound to one reads natively), and the length-keyed cache is
      two-way: 2·10^7 calls of four reads, best of three, native 590 ms → helpers 895 ms (+52 %) before,
      631 ms (+7 %) after; four non-colliding lengths 583 → 662 ms (+14 %) before, 625 ms (+7 %) after
      (loaded machine: further rounds +7–15 %)
- [x] `run/string_index_of_codepoints` (with `"👍"` and `"e\u{301}"`) one `.out` for the four targets

### Step 11 — the same wasm library from commonJS (decision 333 (B); after `05-wasm` step 9)

- [ ] a binding with `@External.Wasm(module: …)` and no `@External.Node` lowers on commonJS to the same
      library: the module instantiates the package's `.wasm` once (synchronously, from its bytes beside the
      emitted `.js`) and calls it through the same glue
- [ ] the emitted package ships the `.wasm` next to its `.js`; `tsc-check.sh` green; `run/wasm_library_binding`
      one answer on commonJS and wasm

### Step 12 — a synchronous component is a plain `function` (decision 375; after `01-checker` step 23's `HookNode.async`)

`effectShape`'s `.component => .{ .is_async = true }` (1.0.10's 104 (6)) gives way to the node's mark:

```js
function Card(map, titulo) { … }                       // HookNode.async == false
async function Post(map) { … Card(map, "x") … await Comments(map) … }
```

- [ ] a `@Component` function or hook whose node is synchronous emits `function` (a method, a lambda and a
      `default fn` alike); an asynchronous one `async function`; a call of a synchronous one emits no
      `await`, written or not; a call the checker cannot follow keeps the `await`
- [ ] the TypeScript typedef answers the value, not a `Promise`, for a synchronous one; `tsc-check.sh` green
- [ ] `run/component_sync_plain_function` (the emitted module holds `function Card(` and `async function
      Post(`) and every `run/context_*` / jhonstart and emilia cell green on commonJS; erlang, beam and wasm
      output unchanged

**Gate:** standard (fronts.md § Gate) + every re-recorded RUN LOG verified under `node` against
decision 8 §7 · `zig build test-libs` commonJS cells at baseline (jhonstart, emilia, onze, erika)

## Notes

- **`typescript.zig` is inseparable from `commonJS.zig`** for snapshots: the typedef is a section of
  the commonJS snapshot.
- **Only commonJS snapshots move here** (step 2's deletion moves none).

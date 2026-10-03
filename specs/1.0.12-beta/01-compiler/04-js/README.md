# Front 04 — js: commonJS keeps no dead lowering and no marker std alone may write

**Priority:** medium · **State:** partial: steps 3, 4, 5, 7, 8 and C-37 on feat; steps 1, 2, 6 open
**Depends on:** `01-checker`'s `@block` tail-form refusal (step 1), `$stringify` parser refusal (step
2), step 6's typed AST (step 6)
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
`throw` in a `case` arm answers `Error` from the function; out-of-range integer aborts (decision 264).

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
(`48a096ea`).

## Open

### Step 1 — the `@block` tail-form IIFE

`val a = @block { 1 + 2 };` prints `null`. IIFE stays for `@block { return 3; }` and `@block { … };`;
once the checker refuses the tail form nothing moves here.

- [ ] `@block { 1 + 2 }` refused by the checker (`01-checker`'s row); commonJS snapshots byte-identical

### Step 2 — `$stringify` in a template (decisions 164, 239)

After the parser refusal (`01-checker` row) and std's `Array.join` dropping it: delete
`primOpTemplate.render`'s `$stringify` arm and `emitStringifyOpen` / `emitStringifyClose`
(`erlang.zig`, `beam_asm.zig` — 02's/03's files, carve-out named in the commit).

- [ ] `reject/external_template_stringify_marker` — refused at the template, naming the marker, on
      every target
- [ ] `render`'s `$stringify` arm and every `emitStringify*` deleted; no snapshot moves

### Step 6 — `throw` in a `case` arm (after `01-checker` step 6)

Typed AST marks the arm's `throw` as the enclosing function's (today `JumpInValuePosition` at
codegen); the arm emits `return {Error: e}`.

- [ ] `run/throw_in_case_arm_result` green on commonJS; `isError()` true on the throw path

### Rows found by other fronts

- [ ] module with a module-level `val` initialised by a call (`val t = "a b".split(" ")`) fails a
      commonJS build with a bare `TypeError` when any of its functions calls `Float.floor` (from
      `05-wasm` step 5, comptime path; re-measure, name the owner)
- [ ] `Point(x: 0, ..)` in a `case` answers `null` on commonJS (from `02-erlang`; re-measure)

**Gate:** standard (fronts.md § Gate) + every re-recorded RUN LOG verified under `node` against
decision 8 §7 · `zig build test-libs` commonJS cells at baseline (jhonstart, emilia, onze, erika)

## Notes

- **`typescript.zig` is inseparable from `commonJS.zig`** for snapshots: the typedef is a section of
  the commonJS snapshot.
- **Only commonJS snapshots move here** (step 2's deletion moves none).

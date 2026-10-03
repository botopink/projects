# Front 04 — js: commonJS keeps no dead lowering and no marker std alone may write

**Priority:** medium · **State:** partial: steps 3, 4, 5, 7 and C-37 on feat; steps 1, 2, 6, 8 open
**Depends on:** `01-checker`'s `@block` tail-form refusal (step 1) and `$stringify` parser refusal
(step 2) · `01-checker` step 6's typed AST (step 6)
**Owns:** `modules/compiler-core/src/codegen/commonJS.zig` · `src/codegen/typescript.zig` ·
`src/codegen/js/**` · `src/comptime/primOpTemplate.zig`'s `$stringify` arm (step 2, decision 239) ·
the commonJS snapshots under `snapshots/codegen/<runtime>/commonJS/**` and
`snapshots/codegen/<runtime>/errors/commonJS/**` (each carrying the TypeScript typedef — there is no
`typescript/` directory) · `src/codegen/tests/commonjs.zig` · `scripts/tsc-check.sh` · the cells its
steps add
**Does not touch:** `src/comptime/**` otherwise, `src/parser/**` (01, 14, 18) · `erlang.zig`,
`crossModule.zig`, `beam/{erl_ast,erl_emitter}.zig` (02) · `beam_asm.zig`, `beam/**` (03) ·
`wat.zig`, `wat/**` (05) · `modules/compiler-cli/**` (26) · `libs/std/**` (the std track)

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/`.

## Goal

commonJS has no lowering left whose only producer is a program the checker should refuse, no
template marker std alone may write, a `throw` in a `case` arm answers `Error` from the function,
and an integer that leaves its type aborts (decision 264).

## Done

- Step 3 — `scripts/tsc-check.sh` (gate stage 11, `tsc` 7.0.2 through `npx`, every emitted module also `node --check`ed); `run/number_method_call`
- Step 4 — the redeclared binding has no producer (decisions 152, 205): `run/sibling_blocks_bind_one_name`
- Step 5 — no `unwrapOrThrow` ships (decision 179), recorded in `js/AGENTS.md`
- Step 7 — a `default fn` body lowered without the checker: `self` as the primitive, `Ok`/`Error` as the object
- Step 1, box 1 — the `@block` IIFE producers measured (`js/AGENTS.md` § The IIFE build sites)
- C-37 — the `charCodeAt` prelude patch calls `codePointAt`, never itself

## Open

### Step 1 — the `@block` tail-form IIFE

`val a = @block { 1 + 2 };` prints `null` on commonJS. The IIFE stays for `@block { return 3; }`
and `@block { … };`; once the checker refuses the tail form nothing here moves.

- [ ] `@block { 1 + 2 }` refused by the checker (`01-checker`'s row); commonJS snapshots byte-identical

### Step 2 — `$stringify` in a template (decisions 164, 239)

The parser refuses `$stringify` in every template, std included (`01-checker`'s row); std's
`Array.join` no longer writes it. Then `primOpTemplate.render`'s `$stringify` arm and the backends'
`emitStringifyOpen` / `emitStringifyClose` (`erlang.zig`, `beam_asm.zig` — 02's and 03's files, the
carve-out named in the commit) are deleted.

- [ ] `reject/external_template_stringify_marker` — refused at the template, naming the marker, on
      every target
- [ ] `render`'s `$stringify` arm and every `emitStringify*` deleted; no snapshot moves

### Step 6 — `throw` in a `case` arm (after `01-checker` step 6)

The typed AST marks a `throw` in a `case` arm as the enclosing function's; commonJS refuses the
program at code generation today (`JumpInValuePosition`). The arm emits `return {Error: e}`.

- [ ] `run/throw_in_case_arm_result` green on commonJS; `isError()` true on the throw path

### Step 8 — an integer that leaves its type aborts (decision 264)

`+`, `-`, `*`, unary `-` and the compound assignments of every integer type check the result
against the declared type's range and abort; an `i64`'s representable range is ±(2^53−1) (`docs.md`'s
cap; decision 247 refuses an `l` literal beyond it), so a result outside it aborts too, never a
rounded value.

- [ ] the cells of `02-erlang` step 13 green on commonJS, an `i64` past ±(2^53−1) included

### Rows found by other fronts

- [ ] a module with a module-level `val` initialised by a call (`val t = "a b".split(" ")`) fails a
      commonJS build with a bare `TypeError` when any function of it calls `Float.floor` (found by
      `05-wasm` step 5, a comptime path; re-measure and name the owner)
- [ ] `Point(x: 0, ..)` in a `case` answers `null` on commonJS (found by `02-erlang`; re-measure)

**Gate:** standard (fronts.md § Gate) + every re-recorded RUN LOG verified by running the program
under `node`, checked against decision 8 §7 · `zig build test-libs` commonJS cells at baseline
(jhonstart, emilia, onze, erika)

## Notes

- **`typescript.zig` cannot be separated from `commonJS.zig`** for snapshot purposes: the typedef
  is a section of the commonJS snapshot.
- **This front moves only commonJS snapshots** (step 2's deletion excepted, which moves none).
</content>
</invoke>

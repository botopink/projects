# Front 04 — js: commonJS keeps no dead lowering and no marker std alone may write

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [144-botopink-lang](../README.md): s13 → B-06 · s12 → B-17 · s6 → B-22 · rows → B-22 · s9 → B-24 · s11 → B-25. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

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

## Notes

- **`typescript.zig` is inseparable from `commonJS.zig`** for snapshots: the typedef is a section of
  the commonJS snapshot.
- **Only commonJS snapshots move here** (step 2's deletion moves none).

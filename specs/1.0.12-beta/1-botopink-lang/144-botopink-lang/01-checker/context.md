# Front 01 — checker: every program `botopink check` accepts runs the same on four targets

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [144-botopink-lang](../README.md): s42 box 3 → B-01 · s27 → B-02 · s42 box 1 → B-03 · s42 box 2 → B-05 · rows box 2 → B-10 · s30 → B-11 · s32 → B-12 · s33 → B-12 · s34 → B-14 · s24 → B-16 · s28 → B-16 · s23 → B-17 · s36 → B-17 · s29 → B-18 · s39 → B-18 · s40 → B-18 · s31 → B-20 · s37 → B-21 · s38 → B-21 · open → B-22 · s6 → B-22 · s13 → B-22 · s18 → B-23 · s19 → B-23 · rows boxes 1, 3, 4 → B-23 · s22 → B-27. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** high · **State:** partial: steps 1–9, 11, 12, 14–17, 19, 20 on feat; step 18 built on
feat (botopink-lang `49455602` merges `19d59508`, `6185db3c`) with one box open; step 24 built on
`front/checker-s24` but three boxes; step 23 built on `front/checker-s23` and `front/decl-hooks-371-372` (371, 372); step 28 built on `front/checker-s28` but `Type.keys` and the run-time `Type.Field<T>`; step 6
box 3, steps 13, 21, 22, 24–33 and ten rows open
**Depends on:** `04-js` step 6 (step 6 box 3) · `05-wasm` nested
constructor in a `val` (step 13) · `08-bpp/116` prelude list (step 22) · (lg2-q answered by 403, by design: `@Decl` carries no source location; lg2-a is step 32, decision 346;
lg2-e answered by 347 with nothing to build: a method's `@Decl` has no `owner`).
**Owns:** `modules/compiler-core/src/comptime/{infer,types,unify,env,transform,eval,error,diagnostics}.zig`
· `src/parser/**`, `src/parser.zig`, `src/print.zig`, `src/lexer.zig`, `src/lexer/**` · `src/ast.zig`
(node fields its steps add) · `snapshots/comptime/**`, `snapshots/parser/**` · its cells under
`tests/language/` (one file per cell)
**Does not touch:** `src/codegen/**` (02–05) · `src/comptime/runtime/**`, `template_eval.zig`,
`decorator_eval.zig` (14, 18) · `src/format.zig`, `src/format/**`, `ast.zig` trivia fields (16) ·
`parser.zig`'s `isBracedBlockStmt` and `blockStatementSemicolon` kind (16's C-13 patch, after this
front's parser rows) · `modules/compiler-cli/**`, `modules/language-server/src/**` (26) ·
`libs/std/**` (std track)

Paths relative to `repository/botopink-lang/modules/compiler-core/src/`.

## Goal

Accepted ⇒ every backend gives decision 8's answer; refused ⇒ located, by name. Open rows become
four-target cells; checker gains decisions 270 (prelude scope), 247 (suffixes), 255 (two forms).

## Notes

- Refusal steps (6's throw, 13, `@block` tail, `$stringify`, primitive name) run once against the
  four backend snapshot dirs before landing; jhonstart's and rakun's workarounds for steps 5, 7 hold.
- `parser.zig` shared with 16: this front's parser rows first; 16's `decision-29-parser-half.patch`
  rebases on them, lands last.

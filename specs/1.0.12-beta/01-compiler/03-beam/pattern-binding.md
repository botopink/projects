# JS-4 — a botopink pattern as a binding target: the contract

From 1.0.10's `04-js/pattern-binding.md`. commonJS, wasm, beam halves on feat (`03-beam` step 1);
open: the two shapes the checker still refuses (`01-checker` step 13). Paths relative to
`repository/botopink-lang/modules/compiler-core/`.

## The contract

`01-checker`'s R5: bare `val <Pattern> = e` checks **only where it cannot fail** — the variant of a
one-variant `type`, a record's own constructor, a spread-only list pattern. Refutable =
`refutable-val-pattern` at check time, naming `val assert` and `case` (`val assert <Pattern> = e`
without `catch` desugars to `@panic("assert pattern did not match")`). So no backend needs a
run-time test: `ctor` destructuring is a plain destructure.

```js
// val Circle(r) = s;
const { r } = s;
```

- commonJS: `buildPattern` (`src/codegen/commonJS.zig`) builds only JS destructuring targets, from
  `buildParam` and `buildDestructPattern`; nested constructor = nested object pattern
  (`ObjectPattern.Prop.nested`). Parameters never bring a constructor or list: `.list` / `.ctor`
  destructuring parses only in `val` position (`fn area(Circle(r): Circle)` does not parse).
- wasm: each binding read off its field's slot. beam: each sub-pattern bound to the matched tuple's
  element register (`beam_asm.zig` `emitPatternDestruct`).
- Fixture: `src/codegen/tests/aggregates.zig` "a constructor in binding position is a plain
  destructure (JS-4)", RUN LOG `x 2 5 hi! 7` on every backend.

## Open

`01-checker` step 13: `val [..rest] = xs;` checks but leaves `rest` unbound; `val Pair(Circle(r), n)
= p;` refused as refutable though no level can fail; wasm does not lower the nested form (`05-wasm` row).

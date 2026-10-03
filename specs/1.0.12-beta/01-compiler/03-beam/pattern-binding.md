# JS-4 — a botopink pattern as a binding target: the contract

Moved from 1.0.10's `04-js/pattern-binding.md`. The commonJS, wasm and beam halves are on feat
(`03-beam` step 1); what is open is the two shapes the checker still refuses (`01-checker` step 13).
Paths are relative to `repository/botopink-lang/modules/compiler-core/`.

## The contract

`01-checker`'s R5 decides what reaches this lowering: the bare `val <Pattern> = e` checks **only where
it cannot fail** — the one variant of a one-variant `type`, a record's own constructor, a spread-only
list pattern. Every refutable one is `refutable-val-pattern` at check time, naming `val assert` and
`case` (`val assert <Pattern> = e` without a `catch` desugars to `@panic("assert pattern did not
match")`). So no program that reaches a backend needs a run-time test: a `ctor` destructuring is a
plain destructure.

```js
// val Circle(r) = s;
const { r } = s;
```

On commonJS, `buildPattern` (`src/codegen/commonJS.zig`) builds only JS destructuring targets —
reached from `buildParam` and `buildDestructPattern`; a nested constructor is a nested object pattern
(`ObjectPattern.Prop.nested`). A parameter never reaches `buildPattern` with a constructor or a list:
the parser builds `.list` / `.ctor` destructuring only in `val` position (`fn area(Circle(r): Circle)`
does not parse). wasm reads each binding off its field's slot; beam binds each sub-pattern to the
matched tuple's element register (`beam_asm.zig` `emitPatternDestruct`). The fixture is
`src/codegen/tests/aggregates.zig`'s "a constructor in binding position is a plain destructure
(JS-4)", RUN LOG `x 2 5 hi! 7` on every backend.

## Open

`01-checker` step 13: `val [..rest] = xs;` checks but leaves `rest` unbound on erlang, and a nested
constructor (`val Pair(Circle(r), n) = p;`) is refused as refutable although no level can fail.

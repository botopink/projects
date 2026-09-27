# JS-4 — a botopink pattern as a binding target: the contract, and the beam twin

Moved from 1.0.10's `04-js/pattern-binding.md`: the commonJS half is closed and kept here as the
contract; the open half is beam's (this front's step 1). Paths are relative to
`repository/botopink-lang/modules/compiler-core/`.

## The contract

`01-checker`'s R5 decides what reaches this lowering: the bare `val <Pattern> = e` checks **only where
it cannot fail** — the one variant of a one-variant `type`, a record's own constructor, a spread-only
list pattern. Every refutable one is `refutable-val-pattern` at check time, naming `val assert` and
`case` (`val assert <Pattern> = e` without a `catch` desugars to `@panic("assert pattern did not
match")`). So no program that reaches a backend needs a run-time test: a `ctor` destructuring is a
plain destructure and the pattern spelling is gone.

```js
// val Circle(r) = s;
const { r } = s;
```

On commonJS, `buildPattern` (`src/codegen/commonJS.zig`) builds only JS destructuring targets —
reached from `buildParam` and `buildDestructPattern`; a nested constructor is a nested object pattern
(`ObjectPattern.Prop.nested`). `MatchPattern` and `writeMatchPattern` are deleted, and the bridge
table in `src/codegen/js/AGENTS.md` is gone with them. A parameter never reaches `buildPattern` with a
constructor or a list: the parser builds `.list` / `.ctor` destructuring only in `val` position
(`fn area(Circle(r): Circle)` does not parse). wasm reads each binding off its field's slot.

## What holds, and what is open

- [x] commonJS and wasm run the fixture (`src/codegen/tests/aggregates.zig:482` at HEAD, `a
      constructor in binding position is a plain destructure (JS-4)`, two RUN LOGs: `x 2 5 hi! 7`)
- [x] 0 `buildPattern` build sites reachable from `buildParam` / `buildDestructPattern` that write a
      pattern spelling; `MatchPattern` (`src/codegen/js/js_ast.zig`) and `writeMatchPattern`
      (`src/codegen/js/js_emitter.zig`) deleted; the bridge table gone
- [x] commonJS snapshots otherwise byte-identical — zero moved by the row
- [x] the decided failure behaviour of a bare `val <Pattern> = e` is the contract above (refutable is
      a check error, so no run-time test exists)
- [ ] **beam**: the fixture assembles and aborts with `{unresolved_identifier, r}` — `beam_asm.zig`'s
      `.ctor` destructure binds nothing. The 1.0.10 `02-erlang` README named an erlang twin
      (`variable 'R' is unbound`, `destructPatternExpr`); the audit did not re-measure erlang — step
      1's cell has an erlang column, and 02 takes the row if it still reproduces
- [ ] the fixture becomes the four-backend snapshot it was written to be (a beam RUN LOG added; an
      erlang one if 02's twin is open)

Two checker gaps, `01-checker` step 13's: `val [..rest] = xs;` checks but leaves `rest` unbound,
and a nested constructor (`val Pair(Circle(r), n) = p;`) is refused as refutable although neither
level can fail.

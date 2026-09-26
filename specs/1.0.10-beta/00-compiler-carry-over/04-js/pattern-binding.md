# JS-4 — a botopink pattern as a JS binding target (step 7)

Paths are relative to `repository/botopink-lang/modules/compiler-core/`.

## The contract

`01-checker`'s R5 decides what reaches this lowering: the bare `val <Pattern> = e` checks **only where
it cannot fail** — the one variant of a one-variant `type`, a record's own constructor, a spread-only
list pattern. Every refutable one is `refutable-val-pattern` at check time, naming `val assert` and
`case` (`val assert <Pattern> = e` without a `catch` desugars to `@panic("assert pattern did not
match")`). So no program that reaches this lowering needs a run-time test: a `ctor` destructuring is a
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
(`fn area(Circle(r): Circle)` does not parse). wasm reads each binding off its field's slot
([`05-wasm`](../05-wasm/README.md)).

## Acceptance

- [ ] a fixture destructures a variant in binding position and **runs**, on all four backends —
      commonJS and wasm run it (`src/codegen/tests/aggregates.zig` `a constructor in binding position
      is a plain destructure (JS-4)`, two RUN LOGs: `x 2 5 hi! 7`); **erlang does not compile it**
      (`variable 'R' is unbound` — `destructPatternExpr` in `src/codegen/erlang.zig` binds nothing)
      and **beam** assembles it and aborts with `{unresolved_identifier, r}`: both are
      [`02-erlang`](../02-erlang/README.md)'s and [`03-beam`](../03-beam/README.md)'s rows, which is
      why the fixture is two RUN LOGs and not a four-backend snapshot
- [x] 0 `buildPattern` build sites reachable from `buildParam` / `buildDestructPattern` that write a
      pattern spelling — `buildPattern` builds only JS destructuring targets; `MatchPattern`
      (`src/codegen/js/js_ast.zig`) and `writeMatchPattern` (`src/codegen/js/js_emitter.zig`) deleted
- [x] the row leaves the bridge table in `src/codegen/js/AGENTS.md` (the table is gone: no bridge left)
- [x] commonJS snapshots otherwise **byte-identical** — zero moved by this row
- [x] the decided failure behaviour of a bare `val <Pattern> = e` is written into this file —
      [The contract](#the-contract) (01 R5: refutable is a check error, so no run-time test exists)

Two checker gaps, for [`01-checker`](../01-checker/README.md): `val [..rest] = xs;` checks but leaves
`rest` unbound, and a nested constructor (`val Pair(Circle(r), n) = p;`) is refused as refutable
although neither level can fail.

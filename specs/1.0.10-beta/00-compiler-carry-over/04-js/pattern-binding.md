# JS-4 — a botopink pattern as a JS binding target (step 7)

The other five bridges landed with js-bridges (`bd7836c`); this one waits on the checker (01 R5).
Sites are located by symbol at `botopink-lang` `c2dd780`.

Paths are relative to `repository/botopink-lang/modules/compiler-core/`.

## The bridge

`buildPattern` in `src/codegen/commonJS.zig` (12 references at `c2dd780`) builds botopink's own
pattern spelling — variant binding, fields, nested patterns, number and string literals, a number
inside a list, `or` and multi — reached from `buildParam` and `buildDestructPattern`, i.e. a `ctor`
or `list` destructuring in parameter or `val` position. `writeMatchPattern`
(`src/codegen/js/js_emitter.zig:369`, dispatched at `:358`) then writes that spelling — `Circle(r)`,
`1 | 2` — straight into JavaScript, where it is not a binding target.

`src/codegen/js/AGENTS.md` names the blocker in its bridge table, and it is still accurate:

| Surface | At `c2dd780` |
|---|---|
| `val Circle(r) = s;` | parses; the checker reports `unbound variable 'r'` |
| `val [a, b] = xs;` | parses; the same |
| `assert x is Some(n)` | refused by the parser with a located `is-variant-binding` at the `(` — `3b491e3` moved the diagnostic, the form still does not parse |

No snapshot reaches a build site, which is why the bridge has survived four backend landings: there
is no program that exercises it.

Both surfaces are [`01-checker`](../01-checker/README.md) step 8's **R5** (a pattern in binding
position binds nothing) and step 10's `assert <expr> is <Pattern>` gap. This front's half starts
when R5 lands.

## After the checker

A `ctor` destructuring lowers to a real JS **test-plus-destructure**, not to a pattern spelling:

```js
// val Circle(r) = s;
if (!("Circle" === s.tag)) { /* the decided failure — see below */ }
const { radius: r } = s;
```

What "the decided failure" is depends on the shape the checker gives the construct: `val <Pattern> =`
over a subject that cannot fail is a plain destructure with no test at all, and over one that can is
either an error at check time or a fatal assert at run time. `d2b468d` already settled the neighbouring
form — `val assert <Pattern> = e` without a `catch` desugars to `@panic("assert pattern did not
match")` — so if R5 makes the bare `val <Pattern> =` legal only where it cannot fail, no test is
emitted and this row is pure deletion.

**Confirm that with the checker front before writing the lowering**, and record the answer here.

**Answered by the checker (01 R5):** the bare `val <Pattern> = e` checks **only where it cannot fail** —
the one variant of a one-variant `type`, a record's own constructor, a spread-only list pattern. Every
refutable one is `refutable-val-pattern` at check time, naming `val assert` and `case`. So no program
that reaches this lowering needs a test: the row is a plain destructure (`const { radius: r } = s;`)
and pure deletion of the pattern spelling.

## The erlang and beam twins

`destructPatternExpr` in `src/codegen/erlang.zig` (`:3219`, `:4109`) handles the same construct on
erlang; at the 1.0.2-beta measurement its `.list, .ctor` arm lowered to `_` and matched anything.
Re-check it when R5 lands — it is [`02-erlang`](../02-erlang/README.md)'s, not this front's. Beam's
`val assert` list pattern binds nothing, recorded in `src/codegen/AGENTS.md` by `d2b468d`; that is
[`03-beam`](../03-beam/README.md)'s.

## Acceptance

- [ ] a fixture destructures a variant in binding position and **runs**, on all four backends
- [ ] 0 `buildPattern` build sites reachable from `buildParam` / `buildDestructPattern`;
      `MatchPattern` (`src/codegen/js/js_ast.zig`) and `writeMatchPattern`
      (`src/codegen/js/js_emitter.zig`) deleted
- [ ] the row leaves the bridge table in `src/codegen/js/AGENTS.md`
- [ ] commonJS snapshots otherwise **byte-identical** — this is a shape-only bridge, so a diff
      outside the removed spelling is a bug found
- [ ] the decided failure behaviour of a bare `val <Pattern> = e` is written into this file

# JS-4 — a botopink pattern as a JS binding target

> Kept from `1.0.4-beta/04-js-bridges/bridges.md` (carried from 1.0.2-beta). The other five bridges
> landed with js-bridges (`bd7836c`); this one waits on the checker. `file:line` was measured at the
> 1.0.2-beta commit — re-locate by symbol.
> **Not delivered in 1.0.4-beta.** It waits on the checker's N11, which did not land either. Both go
> to 1.0.5-beta: the checker row to `01-checker`, this lowering to `04-js`.

Paths are relative to `repository/botopink-lang/modules/compiler-core/`.

## The bridge

Eight build sites in `buildPattern` (`src/codegen/commonJS.zig:1704-1743` — variant binding / fields
/ patterns, number and string literals, a number inside a list, `or` and multi), reached from
`buildParam` and `buildDestructPattern` — a `ctor` or `list` destructuring in parameter or `val`
position. `writeMatchPattern` (`src/codegen/js/js_emitter.zig`) then writes botopink's own spelling
(`Circle(r)`, `1 | 2`) into JS.

No snapshot reaches it. The js-bridges landing measured why, and named the blocker in
`src/codegen/js/AGENTS.md`:

| Surface | At `ed15323` |
|---|---|
| `val Circle(r) = shape` | parses; the checker reports `r` unbound |
| `assert x is Some(n)` | parse error (`narrow_assert_pattern_with_print`, one of the three `b/missing` fixtures) |

Both are [`../06-checker/`](../06-checker/README.md#step-0--rows-added-in-104-beta) N11 (with the
parser-gap step's `assert x is P` form and C8's pattern binding).

The erlang side of the same gap is `destructPatternExpr`'s `.list, .ctor` arm, which lowered to `_`
and matched anything at the 1.0.2-beta commit — re-check it when N11 lands.

## After the checker

A `ctor` destructuring lowers to a real JS test-plus-destructure, not to a pattern spelling. This is
a `commonJS.zig` change after 06 — this front's if it is still open, else the follow-up registered
in [`../fronts.md`](../fronts.md#unowned-items).

**Acceptance:**
- [ ] A fixture destructures a variant in binding position and runs, on all four backends
- [ ] 0 `Pattern.match` build sites; `MatchPattern` (`src/codegen/js/js_ast.zig`) and
      `writeMatchPattern` deleted; the row leaves the bridge table in `src/codegen/js/AGENTS.md`
- [ ] commonJS snapshots otherwise byte-identical — a shape-only bridge; a diff is a bug found

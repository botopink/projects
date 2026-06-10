# erika

> Path: `libs/erika/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../AGENTS.md`](../../AGENTS.md)
> Docs: [`./docs.md`](docs.md) · Examples: [`./examples.md`](examples.md)
> Spec: [`../../tasks/v0.beta.7/specs/erika.md`](../../tasks/v0.beta.7/specs/erika.md)

A **C#/LINQ-style query library** for botopink — a fluent, eager, immutable
`record Query<T>` over `Array<T>`, plus an `erika "…"` SQL-subset **template fn**
that expands (at comptime) to the same fluent pipeline. It is **pure botopink**:
zero compiler surface, no decorators, no host backing. erika is the proof that
the generic `from "<lib>"` loader works for an ordinary (non-framework) external
package, exactly as `rakun` is the proof for a decorator-driven one.

**Not std.** erika shipped *inside* `std` in v0.beta.6 only to dodge the per-lib
import machinery rakun then needed. v0.beta.7 replaced that with one generic
loader, so erika graduated to its own package: it is reached **only** through
`import {…} from "erika"` — no `std_pkg_files` entry, no `@embedFile`, no
`modules/compiler-core` mention (the lib-agnostic gate in `build.zig` covers
`erika` too).

## Tree

```text
erika/
├── AGENTS.md          ← you are here
├── docs.md            ← what this lib provides + the grammar + loading notes
├── examples.md        ← both forms (fluent + `erika "…"`), runnable
├── botopink.json      ← package metadata (files: ["erika.bp"])
└── src/
    └── erika.bp       ← the whole lib: `record Query<T>` + `Grouping<K,V>` +
                         constructors + the `erika "…"` template fn + 21 tests
```

## Design at a glance

- **`record Query<T> { items: Array<T> }`** — every operator returns a *new*
  `Query<U>` over a freshly materialized array (eager + immutable, like `sets`).
  Terminals return scalars, `?T`, or `Array<T>`.
- **Constructors** are top-level `pub fn` (`of`/`range`/`repeat`/`empty`). `from`
  is the import keyword and cannot name a function, so the wrapper is `of`.
- **No arity overloading** (the JS backend mangles same-named methods), so the
  predicate variants are spelled out: `count`/`countWhere`, `first`/`firstWhere`,
  `any`/`anyWhere`.
- **`erika "…"`** is a template fn: it captures a SQL-subset string as
  `@Expr<string>`, parses it in botopink at comptime, resolves the referenced
  collection against the caller's scope, and expands to unqualified fluent source
  via `q.build(...)`. Grammar:
  `select <* | f1[, f2…]> from <Name> [where <cond>] [order by <field> [asc|desc]]`.

## Conventions

- **Pure `.bp`, zero core surface.** The only compiler dependency is the
  *generic* loader; erika adds no Zig and is named nowhere in `compiler-core`.
- **Imported, never prelude.** Reached via `from "erika"` — the CLI's generic
  loader (`compiler-cli/src/cli/libs.zig`) resolves `dependencies: ["erika"]` to
  `libs/erika/src/erika.bp` as the `erika/erika` package module. No per-lib
  registry, no embed.
- **Tests live here.** 21 `test { … }` blocks inside `src/erika.bp`, run by
  `botopink test` from this directory — not in the compiler's Zig suites.
- Keep this file, `docs.md`, `examples.md`, and the spec in sync in the same
  change that touches the lib.

## Comptime-eval constraint (why the `erika "…"` parser is written the way it is)

The `erika "…"` body runs at comptime in `template_eval.zig`: the evaluator emits
**only the template fn itself** and runs it with `node` over a *minimal* prelude.
So the SQL→botopink translation may use only ops that lower to **native JS**:
`split` / `join` / `slice` / `trim` / `map` / `append` / `length` / `+` / `==`.
It must **not** use host-helper-backed ops — notably optional `.at(i).unwrapOr(…)`
is **undefined** in the eval script (it silently fails the expansion, surfacing as
a terse "parse error"). That is why the field list is built with `append` + `map`
+ `join` and never `fields.at(0).unwrapOr(…)`.

A second, language-wide quirk the body works around: a top-level binary boolean
**directly inside an `if (…)` condition fails to parse** (e.g. `if (a && b)`).
Extract the compound to a `val` first, then `if (theVal)` — the established style
throughout `erika.bp`.

## Status (v0.beta.7)

- **Fluent layer** — complete; all ops covered by tests.
- **`selectMany` (flatMap)** — **landed.** Selector typed `fn(item: T) -> Array<U>`;
  unblocked by `fn() -> T[]` in a function-type parameter (gap **G3**, landed in `feat`).
- **Multi-field projection** (`select a, b`) — **landed.** Two-or-more fields project
  an anonymous structural `record { a: row.a, b: row.b }` per row; unblocked by
  anonymous record types (gap **G2**, landed in `feat`). A single field projects
  the bare column; `*` returns whole rows. Commas may be attached (`a, b`) or
  spaced (`a , b`) — they are normalized to spaces before tokenizing.

### Recorded gaps

- **`erika "…"` after `import {erika} from "erika"` — still `unbound`.** This is
  the v0.beta.6 limit, and it is **not** erika-specific: the generic `from "<lib>"`
  loader binds the lib **namespace** (so `erika.of(...)` and any `lib.member`
  works) but does **not** bind bare imported values into value scope — confirmed
  with a throwaway probe lib where even a plain `import {plain} from "lib"` leaves
  bare `plain` unbound, and a non-colliding template fn `qq "…"` is unbound too.
  Paren-free template application (`erika "…"`) resolves its callee as a bare
  value, so it cannot resolve until the loader gains **generic bare-value /
  template-fn import binding** (bind a lib module's exports — and same-named
  template fns into `templateFns`/`exprParams` — into the importer's value scope).
  That is a generic compiler-core / loader add; it is **out of scope here** (the
  gate forbids erika in core, and this task adds no core code). The fluent API
  (`erika.of(...)`) is fully usable from user projects today; the `erika "…"` form
  is exercised by this lib's own in-file tests, where the template fn is a directly
  in-scope identifier.
- **Interpolated queries** (`erika "… where age >= ${min}"` via `q.parts()`
  Text/Interp) — the next extension, unchanged from v0.beta.6. Record, don't build.
- **`average`** takes an `f64` selector (no `i32 → f64` cast exists); `range` /
  `repeat` build their arrays by **recursion** (the `Array.range`/`Array.repeat`
  producers aren't lowered by the commonJS backend).

## See also

- The spec (intent, steps, test scenarios) → [`../../tasks/v0.beta.7/specs/erika.md`](../../tasks/v0.beta.7/specs/erika.md).
- The generic loader erika is a client of → [`../../modules/compiler-cli/src/cli/libs.zig`](../../modules/compiler-cli/src/cli/AGENTS.md).
- The decorator-driven sibling client → [`../rakun/AGENTS.md`](../rakun/AGENTS.md).

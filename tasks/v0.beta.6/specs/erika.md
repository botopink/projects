# erika — a LINQ-style query lib + an `erika "…"` query-string built on `@Expr`

**Slug**: erika
**Depends on**: **nothing** — pure botopink over `Array<T>`; the `erika "…"` syntax is built on the **existing `@Expr` template machinery** (`expr-templates`, already in `feat`). Fully parallel-touchable: it shares **no deliverable** with any other v0.beta.6 spec (see "Parallelism" below)
**Files** (no compiler surface — zero overlap with other specs): `libs/std/src/erika.bp` (new — both the fluent lib **and** the `erika` template fn live here) + root `build.zig` (add `"erika.bp"` to the `std_pkg_files` list). **`modules/compiler-core/src/**` is NOT touched** — see "Data-driven std registry" below: compiler-core must remain agnostic of every individual std lib (it names no module), so a lib's wiring lives only in `build.zig` + `libs/std/`.
**Touches docs**: `libs/std/src/docs.md`, `libs/std/src/examples.md`, `libs/std/AGENTS.md`
**Status**: done (see "Realized scope" below)

## Data-driven std registry (compiler-core stays lib-agnostic)

A std package module is wired in **one place only — `build.zig`**:

- `build.zig` keeps a `std_pkg_files` list (`order.bp`, `dict.bp`, …, `erika.bp`)
  and **generates** the package registry (`pub const pkg_modules = [_]{ path,
  source }{ … @embedFile(...) }`) into its own module, exposed to compiler-core
  via `std_prelude` (which re-exports `pkg_modules`).
- `modules/compiler-core/src/comptime.zig` consumes it generically
  (`std_pkg_modules = @import("std_prelude").pkg_modules`) and never names a
  module; `prelude.zig` re-exports the generated table and embeds only the core
  controller files (`primitives.d.bp`, `builtins.d.bp`).

**Adding a std module = drop `libs/std/src/<name>.bp` + add `"<name>.bp"` to
`std_pkg_files` in `build.zig`.** No `modules/compiler-core/src/**` edit. (This
generalised the previous per-module `prelude.zig`/`comptime.zig` enumeration, so
*the lib configures itself* and compiler-core is unaware of erika specifically.)

## Intent

Two layers, one lib named **erika**, both in pure botopink:

1. **The query library** — a C#/LINQ-style **fluent** operator vocabulary
   (`where`/`select`/`orderBy`/`groupBy`/`aggregate`/`first`/`any`/…) chained on a
   wrapper record and materialized back to `Array<T>`. Lands as a **std collection
   module** (`libs/std/src/erika.bp`), sibling of `sets.bp`/`queue.bp`/`dict.bp`:
   a pure-botopink `record Query<T>` over `items: Array<T>`, **no host backing**,
   importable `from "std"`.

2. **The `erika "…"` syntax** — `erika` is a **template function** that captures a
   SQL-subset query string as `@Expr<string>`, parses it **in botopink at
   comptime**, resolves the referenced collection + fields against the caller's
   **scope snapshot**, and **expands to the fluent layer** via `q.build(…)`. It is
   sugar implemented entirely with the existing `@Expr` machinery — no bespoke
   parser keyword, no new compiler surface. The paren-free call form
   (`erika "…"`) is already what `@Expr` template application parses (the
   templates suite captures `sql "SELECT 1"` today).

```bp
val list = erika "select * from PersonList";
//         └──────────────── expands (comptime) to ────────────────┘
//         of(PersonList).toArray()               // list : Array<Person>
```

**Eager, immutable, v1.** Every fluent operator returns a *new* `Query<T>` over a
freshly materialized array (like `sets.bp`'s `insert`/`union`). C#-style
deferred execution and an `IQueryable`/expression-tree provider are **out of
scope**; the names/shapes leave room for a later lazy backing.

## How `erika "…"` works (the `@Expr` template)

Exactly the `html(comptime q: @Expr<string>) -> @Expr<string>` pattern, but the
body parses SQL and emits fluent-API source. `erika` is **generic** so each call
site's expansion reveals its own result type (`@Expr<T>`):

```bp
// libs/std/src/erika.bp
pub fn erika<T>(comptime q: @Expr<string>) -> @Expr<T> {
    val sql = q.text();                       // the literal query text (no holes in v1)
    val ast = parseSelect(sql);               // botopink SQL-subset parser (in this file)

    // resolve `from <Name>` against the caller scope snapshot:
    val src = q.lookup(ast.source);
    if (src == null) { q.fail("erika: unknown collection '" + ast.source + "'"); };

    // build the fluent pipeline as source, then expand it. The constructor is
    // `of` (`from` is the import keyword), emitted UNQUALIFIED so it resolves
    // wherever the lib + collection are in scope (see "Realized scope"):
    var pipe = "of(" + ast.source + ")";
    if (ast.where != null) { pipe = pipe + ".where({ row -> " + ast.where + " })"; };
    if (ast.orderBy != null) {
        val op = if (ast.desc) { "orderByDescending" } else { "orderBy" };
        pipe = pipe + "." + op + "({ row -> row." + ast.orderBy + " })";
    };
    pipe = if (ast.star) { pipe + ".toArray()" }
           else { pipe + ".select({ row -> row." + ast.field + " }).toArray()" };

    return q.build(pipe);                      // @Expr<T> expansion
}
```

The template methods this leans on already exist (the templates suite exercises
`value`/`text`/`parts`/`source`/`context`/`bindings`/`lookup`/`build`/`failAt`/
`fail` + `Binding.ref`): `q.text()` for the literal, `q.lookup(name)` against the
scope snapshot, `q.build(src)` to expand, `q.fail`/`q.failAt` for scoped
diagnostics. Field-level type-checking falls out of the expansion: `row.missing`
in the built source is type-checked against `T`'s record fields **after** build,
so a bad field is a normal compile error at the call site's span.

## Fluent layer design

`record Query<T> { items: Array<T> }` — each operator is a `self`-method
returning `Query<U>`; terminals return scalars, `?T`, or `Array<T>`. Built on the
`Array<T>` interface (`map`/`filter`/`fold`/`forEach`/`indexOf`/`append`/`length`/
`slice`). Grouping uses `record Grouping<K, V> { key: K, items: Array<V> }`.
Element terminals return `?T` (the "…OrNull" forms — no exceptions until
panic/effect ergonomics land).

## Parallelism (touchable alongside every other v0.beta.6 spec)

erika is the **most isolated** spec in the set:

- **No compiler surface.** The `erika "…"` feature is a botopink `@Expr` template
  fn in `erika.bp` — it reuses the *already-shipped* template machinery. It does
  **not** touch `parser*.zig`, `comptime/*`, or `codegen/*`, so it never collides
  with `jhonstart-language-gaps` / `implement-completeness` / `mutual-recursion`
  (which all edit those) on merge.
- **No shared deliverable.** Multi-field projection is deferred *inside erika*
  (F5b), not borrowed from `jhonstart-language-gaps`'s G2 — erika ships complete
  without it, so it waits on nothing.
- **Files touched** are `libs/std/src/erika.bp` (new) plus one line in
  `build.zig` (`std_pkg_files`). `modules/compiler-core/src/**` is untouched (the
  registry is data-driven — see above). The only theoretical overlap is the
  single `build.zig` list if another std module is added concurrently — a
  one-line, trivially mergeable addition, not a logical dependency.

Run it on its own `task/erika` branch/worktree in parallel with all six others.

## Steps

### F0 — module skeleton + wiring
- [x] `libs/std/src/erika.bp`: `record Query<T> { items }` + `record Grouping<K,V>`,
      constructors (`of`/`range`/`repeat`/`empty`), `toArray`/`toList`.
- [x] Wire: add `"erika.bp"` to `std_pkg_files` in `build.zig` (data-driven
      registry — no `modules/compiler-core/src/**` edit). `import {erika} from
      "std"` resolves and `botopink test` sees the file.
- [x] Constructor spelling: `from` is the `import` keyword and is **rejected** as a
      fn name (`UnexpectedToken`), so the constructor is **`of`** (`Pair.of` shape),
      locked across the API and the F5 expansion.

### F1 — restriction / projection (fluent)
- [ ] `where(pred)`, `select(fn)`, `selectMany(fn)` (flatMap). `cast`/`ofType`
      *skipped* — no runtime type tags; note the omission.

### F2 — partitioning / ordering (fluent)
- [ ] `take(n)`, `skip(n)`, `takeWhile(pred)`, `skipWhile(pred)`, `reverse()`.
- [ ] `orderBy(keyFn)`, `orderByDescending(keyFn)` — stable sort by a projected
      comparable key. `thenBy` may defer to v2 — record if so.

### F3 — set ops / grouping / joining (fluent)
- [ ] `distinct()`, `distinctBy(keyFn)`, `concat`, `union`, `intersect`, `except`
      (structural equality, mirroring `sets.bp`).
- [ ] `groupBy(keyFn) -> Query<Grouping<K,T>>`.
- [ ] `zip(other, fn)`; `join` may defer to v2 — record if so.

### F4 — aggregation / element / quantifiers (fluent terminals)
- [ ] `count()`/`count(pred)`, `sum(fn)`, `min(fn)`, `max(fn)`, `average(fn)`,
      `aggregate(seed, fn)` (fold).
- [ ] `first()`/`first(pred)`, `last()`, `single()`, `elementAt(i)` → `?T`.
- [ ] `any()`/`any(pred)`, `all(pred)`, `contains(x)` → `bool`.

### F5 — the `erika "…"` template fn (over `@Expr`)
- [ ] `pub fn erika<T>(comptime q: @Expr<string>) -> @Expr<T>` in `erika.bp`,
      built with the `@Expr` API exactly like `html` (`q.text()`/`q.parts()`,
      `q.lookup()`, `q.build()`, `q.fail()`/`q.failAt()`).
- [ ] A botopink SQL-subset parser in the same file:
      `select <* | field> from <Name> [where <cond>] [order by <field> [asc|desc]]`.
      `<cond>` = comparisons over a field and a literal/field (`== != < <= > >=`,
      `and`/`or`).
- [ ] Resolve `from <Name>` via `q.lookup` against the scope snapshot; an unknown
      collection ⇒ `q.fail(...)`. Field type-errors fall out of expanding
      `row.<field>` (checked against `T`).
- [ ] Build + expand the fluent pipeline (`erika.from(Name).where(...).orderBy(...)
      .select(...).toArray()`); the call site's `@Expr<T>` reveals the result type
      (`select *` ⇒ `Array<T>`; `select field` ⇒ `Array<FieldType>`).
- [ ] **F5b (future erika version, not in v1)**: multi-field projection
      (`select name, age`) needs an anonymous record *type* / tuple to name the
      projected shape — botopink has neither today. v1 emits a clear
      `q.fail("erika: multi-field select not yet supported")`, never a silent
      wrong result. This is **erika's own** future scope, **not** a dependency on
      any other v0.beta.6 spec — erika ships complete without it.
- [ ] Confirm the existing `@Expr` machinery covers everything `erika` needs; if a
      template method is missing (e.g. a richer `lookup` result), note it as a
      small compiler add — but the goal is **zero new compiler surface**.

### F6 — docs
- [ ] `erika` row in `libs/std/src/docs.md` + a worked `examples.md` example (both
      the fluent and `erika "…"` forms); update `libs/std/src/AGENTS.md` in the
      **same commit** (per repo rule).

## Test scenarios

```
erika.fluent ---- where/select pipeline materializes the expected Array
erika.fluent ---- range(1,100) |> where even |> sum == 2550
erika.fluent ---- distinct removes structural duplicates; groupBy partitions
erika.fluent ---- first(pred) returns the match; first on no-match returns null (?T)
erika.fluent ---- aggregate(seed, fn) folds left identically to Array.fold
erika.query  ---- `select * from PersonList` expands and returns Array<Person>
erika.query  ---- `... where age >= 18` filters; result type stays Array<Person>
erika.query  ---- `... order by name asc` sorts ascending; `desc` reverses
erika.query  ---- `select name from PersonList` returns Array<string>
erika.query  ---- unknown collection ⇒ q.fail diagnostic at the call site
erika.query  ---- bad field (`order by missing`) ⇒ type error from the expansion
erika.query  ---- multi-field `select name, age` ⇒ clear not-yet diagnostic (v1)
```

## Notes / scope boundaries

- **`erika "…"` is an `@Expr` template fn, not new compiler surface.** It reuses
  the capture + scope-snapshot + `build`/`fail` machinery `expr-templates` already
  shipped (the templates suite captures `sql "SELECT 1"` paren-free today). The
  SQL parser is **botopink string code in `erika.bp`**. Only fall back to a Zig
  change if `@Expr` is genuinely missing a primitive — and record exactly which.
- **Std module, not a new package.** v1 ships under `from "std"` to avoid the
  `from "erika"` opt-in import-resolution machinery (`registerXLib`/`markXImports`)
  rakun needed. A standalone `libs/erika` package is a clean follow-up once that
  resolution is generalized — the source moves unchanged.
- **Holes in v1.** v1 parses a plain string literal (`q.text()`). Interpolated
  queries (`erika "… where age >= ${min}"`, via `q.parts()` Text/Interp like the
  `html` example) are a natural F5+ extension — splice the `Interp` `code` into the
  built predicate; record it as the next step rather than building it now.
- **Multi-field projection is a future erika version, not a dependency.** v1 =
  `select *` + single-field; multi-field is an explicit `q.fail` not-yet. Naming a
  projected multi-field shape needs anonymous record types / tuples, which
  botopink lacks today — when that lands (independently, whenever), erika gains
  multi-field for free. Until then erika ships **complete and self-contained**;
  it waits on no other spec.
- **No joins/aggregates/subqueries in the string grammar v1** — use the fluent API
  for those. Eager only; no `IQueryable`/expression-tree provider; no `ofType`/
  `cast` (no runtime type tags). Element terminals return `?T`, not exceptions.
- camelCase methods (`orderByDescending`, not Pascal); pure `.bp` (no `.d.bp`).
  Tests live in `libs/std/src/erika.bp`'s own `test "…"` blocks (`botopink test`),
  enforced by the pre-commit `.bp` step. The `erika "…"` expansion is covered the
  same way (a `test` that runs an `erika "…"` query and asserts the result) — its
  comptime behaviour also belongs in the `comptime/tests/templates.zig` family if
  any compiler-side adjustment is needed.

## Realized scope (what actually shipped + deviations)

Implemented with **zero compiler-logic surface** (wiring is one line in
`build.zig`; see "Data-driven std registry"). 19 inline `test` blocks pass under
`botopink test`; `zig build test` green. Deviations forced by current
language/compiler limits, each recorded (never silently worked around):

- **`of`, not `from`** — `from` is the `import` keyword (rejected as a fn name).
- **No arity overloading** (the JS backend collides same-named methods at
  runtime) → predicate variants are distinct names: `countWhere` / `firstWhere` /
  `anyWhere` (alongside `count` / `first` / `any`).
- **`selectMany` deferred to v2** — its selector needs an array/generic return
  inside a function-type parameter (`fn -> Query<U>` / `-> U[]`), which the parser
  rejects (catalogued `fn() -> T[]` gap). Workaround documented in AGENTS.
- **`average` takes an `f64` selector** (no `i32 → f64` cast); **`range`/`repeat`
  recurse** (associated `Array.range`/`Array.repeat` aren't lowered by commonJS).
- **The `erika "…"` body is self-contained** (no calls to sibling fns): the
  comptime evaluator (`template_eval.zig`) emits only the template fn and runs it
  with `node` over a minimal prelude, so method calls must lower to **native JS**
  (`split`/`slice`/`trim`/`join`) — host-helper ops (optional `.unwrapOr`,
  `.append`) are undefined there and are avoided; the SQL→botopink translation is
  inlined.
- **`erika "…"` import-resolution gap (the one user-facing limit).** The template
  form resolves only where `erika` is a directly in-scope template fn (e.g. this
  module's own tests, which is how it is covered). After `import {erika} from
  "std"` it is `unbound`: the import binds the `erika` *namespace* (so
  `erika.of(...)` works fully) but not the same-named template fn as a value, and
  paren-free template application resolves its callee as a bare value. Closing it
  is a **small, recorded compiler add** (bind a std module's same-named template fn
  into the importer's value scope + `templateFns`/`exprParams` in `infer.zig
  markStdImports` / `comptime.zig registerStdlib`) — intentionally **not** done
  here, to preserve the zero-compiler-surface / conflict-free-merge guarantee.
- **Recorded language findings** (general, surfaced while building erika):
  `&&`/`||` don't parse directly inside `if (...)` (pre-bind to a `val`);
  if-**expression** branch blocks need a trailing `;` (`{ x; }`); an `if/else`
  whose branches end in different-typed assignments unifies the branch types
  (false "expected bool, got string") — use separate guarded `if`s; optional
  `if (opt) { x -> … }` does **not** gate on absence at commonJS runtime (only its
  present-case is reliable; `at()`-OOB + `.unwrapOr(d)` is the safe absence path).

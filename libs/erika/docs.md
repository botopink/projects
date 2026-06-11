# erika — C#/LINQ-style queries

> Path: `libs/erika/`
> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md)
> Examples: [`./examples.md`](examples.md)
> Parent: [`../AGENTS.md`](../AGENTS.md)
> Spec: [`../../tasks/v0.beta.7/specs/erika.md`](../../tasks/v0.beta.7/specs/erika.md)

`erika` is botopink's answer to C#'s **LINQ**: a fluent query vocabulary over
`Array<T>`, plus a SQL-subset `erika "…"` template. It is **opt-in** — reached via
`from "erika"`, never auto-loaded into the type environment — and **pure
botopink**: the whole library is `src/erika.bp`, with zero compiler surface.

## Loading

erika is resolved by the generic external-lib loader. Declare it as a dependency
and import what you need:

```jsonc
// botopink.json
{ "name": "myapp", "target": "commonJS", "src": "src/",
  "dependencies": ["erika"] }
```

```bp
import {erika} from "erika";   // the `erika` namespace + the `erika "…"` template
import {Query} from "erika";   // the Query<T> type (for annotations)
```

The loader finds `libs/erika/src/erika.bp` (nearest ancestor `libs/` dir) and
compiles it as the `erika/erika` package module. There is no embed and no per-lib
registry — the compiler core never names erika.

## The fluent layer — `Query<T>`

Wrap an array with `erika.of(...)`, then chain. Every operator returns a fresh
`Query` (eager, immutable); terminals return a scalar, `?T`, or `Array<T>`.

| Group | Operators |
|---|---|
| **Constructors** | `of(xs)`, `empty()`, `range(start, stop)`, `repeat(value, times)` |
| **Materialize / size** | `toArray`, `toList`, `count`, `isEmpty` |
| **Restriction / projection** | `where(pred)`, `select(fn)`, `selectMany(fn → Array<U>)` |
| **Partition / order** | `take(n)`, `skip(n)`, `takeWhile`, `skipWhile`, `reverse`, `orderBy(keyFn)`, `orderByDescending(keyFn)` |
| **Set / group / join** | `distinct`, `distinctBy`, `concat`, `union`, `intersect`, `except`, `groupBy(keyFn)` → `Query<Grouping<K,T>>`, `zip(other, combine)` |
| **Aggregate (terminal)** | `countWhere`, `sum`, `average`, `min`, `max`, `aggregate(seed, step)` |
| **Element (terminal)** | `first`, `firstWhere`, `last`, `single`, `elementAt` → `?T` |
| **Quantifier (terminal)** | `any`, `anyWhere`, `all`, `contains` |

`selectMany` flattens: the per-item selector returns an `Array<U>` and the
results are concatenated into one `Query<U>`.

## The `erika "…"` query string

`erika` is also a **template function**: a SQL-subset string is parsed at comptime
and expanded into the fluent pipeline. Keywords are lowercase. Grammar:

```text
select <* | f1[, f2…]> from <Name> [where <cond>] [order by <field> [asc|desc]]
```

- **`select *`** → the whole rows (`Array<Row>`).
- **`select field`** → that column (`Array<FieldType>`).
- **`select a, b`** → an anonymous structural `record { a: …, b: … }` per row.
  Commas may be attached (`a, b`) or spaced (`a , b`).
- **`where <cond>`** — comparisons over a field and a literal/field
  (`== != < <= > >=`; `=` reads as `==`, `<>` as `!=`; `and`/`or`). String
  literals use single quotes (`name = 'Paris'`); bare digits are numbers.
- **`order by <field> [asc|desc]`** — stable sort by the projected key.

The referenced collection is resolved against the caller's top-level scope. The
expansion emits **unqualified** fluent source
(`of(Name).where(…).orderBy(…).select(…).toArray()`), so it resolves wherever
`of` / the collection are in scope. The query may be written single-line
(`erika "…"`) or triple-quoted multi-line (`erika """ … """`) — newlines and tabs
are normalized to spaces before tokenizing, so the two forms parse identically.

## Known gaps

- **Interpolated queries** (`erika "… where age >= ${min}"`) — not built yet.
- **`erika "…"` resolves only `val` collections, not `var`** — the template reads
  the caller's comptime scope snapshot, which captures immutable `val` bindings
  only. The fluent `of(listas)` / `erika.of(listas)` form queries any `var`/`val`.

> Cross-module `erika "…"` after `import {erika} from "erika"` now resolves — the
> generic-loader-binding keystone (v0.beta.8) binds the bare imported template fn.
> A runnable consumer lives at [`examples/erika-linq/`](../../examples/erika-linq/).

## See also

- Runnable examples → [`./examples.md`](examples.md).
- The package contract + comptime-eval constraints → [`./AGENTS.md`](AGENTS.md).
- Full language reference → [`../../docs.md`](../../docs.md).

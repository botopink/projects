# TODO — erika

> Live checklist for branch `task/erika` (worktree `.tasks/erika/`).
> Spec (intent, immutable): [`tasks/v0.beta.6/specs/erika.md`](tasks/v0.beta.6/specs/erika.md)

> **Goal**: a C#/LINQ-style query lib as a **pure-`.bp` std module**
> (`libs/std/src/erika.bp`) — a `record Query<T>` over `Array<T>` with fluent
> operators — **plus** an `erika "select … from …"` query-string built as an
> `@Expr` template fn (`q.text()`/`q.lookup()`/`q.build()`), reusing the
> already-shipped expr-templates machinery. **No compiler surface**: only
> `erika.bp` + one line each in `build.zig` (`std_bp_files`) and `prelude.zig`.
> Eager + immutable v1. Fully parallel-touchable — waits on no other spec.

## F0 — module skeleton + wiring
- [ ] `record Query<T> { items }` + `record Grouping<K,V>`; constructors
      (`from`/`range`/`repeat`/`empty`), `toArray`/`toList`
- [ ] Wire `build.zig` `std_bp_files` + `prelude.zig` `pub const erika`; confirm
      `import {erika} from "std"` resolves under `botopink test`
- [ ] Lock constructor spelling (`erika.from` vs `erika.of` — `from` keyword caveat)

## F1 — restriction / projection (fluent)
- [ ] `where`, `select`, `selectMany` (`cast`/`ofType` skipped — note why)

## F2 — partitioning / ordering (fluent)
- [ ] `take`, `skip`, `takeWhile`, `skipWhile`, `reverse`
- [ ] `orderBy`, `orderByDescending` (stable, by projected key); `thenBy` → v2?

## F3 — set ops / grouping / joining (fluent)
- [ ] `distinct`, `distinctBy`, `concat`, `union`, `intersect`, `except`
- [ ] `groupBy -> Query<Grouping<K,T>>`; `zip`; `join` → v2?

## F4 — aggregation / element / quantifiers (terminals)
- [ ] `count`/`count(pred)`, `sum`, `min`, `max`, `average`, `aggregate`
- [ ] `first`/`first(pred)`, `last`, `single`, `elementAt` → `?T`
- [ ] `any`/`all`/`contains` → `bool`

## F5 — the `erika "…"` template fn (over `@Expr`)
- [ ] `pub fn erika<T>(comptime q: @Expr<string>) -> @Expr<T>` in `erika.bp`
- [ ] botopink SQL-subset parser: `select <*|field> from <Name> [where <cond>]
      [order by <field> [asc|desc]]`
- [ ] resolve `from <Name>` via `q.lookup`; unknown collection ⇒ `q.fail`
- [ ] build + expand the fluent pipeline; `@Expr<T>` reveals the result type
- [ ] F5b (future erika version, NOT in v1, NOT a cross-spec dep): multi-field
      `select a, b` ⇒ clear `q.fail` not-yet (needs anon record types / tuples)
- [ ] confirm zero new compiler surface; record any missing `@Expr` primitive

## F6 — docs
- [ ] `erika` row in `libs/std/src/docs.md` + `examples.md`; update
      `libs/std/src/AGENTS.md` in the **same commit**

## Notes
- Tests live in `erika.bp`'s own `test "…"` blocks (`botopink test`), enforced by
  the pre-commit `.bp` step. The `erika "…"` expansion is covered the same way.
- `erika.md` was dropped into this worktree directly — it is **not yet committed
  on `feat`** (mixed with unrelated in-flight work there). Reconcile on merge.

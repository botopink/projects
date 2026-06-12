# erika — de-couple the LINQ lib into its own package on the generic loader

**Slug**: erika
**Depends on**: [`annotation-processors`](annotation-processors.md) — the generic `from "<lib>"` package loader + generic template-fn import binding erika becomes a client of
**Files**: `libs/erika/src/*.bp` (the LINQ fluent layer **and** the `erika "…"` template fn — moved unchanged out of `std`), `libs/erika/botopink.json` (new package manifest), root `build.zig` (**remove** `"erika.bp"` from `std_pkg_files`)
**Touches docs**: `libs/erika/AGENTS.md`, `libs/erika/docs.md`, `libs/erika/examples.md`, `libs/std/src/docs.md` + `libs/std/src/examples.md` + `libs/std/AGENTS.md` (drop the erika rows)
**Status**: pending

> **HARD RULE (2026-06-09).** erika stops being a `std` module. `std` is the one
> coupled exception (embedded prelude, core may name it); **erika is not std**, so
> it must live under `libs/erika/` and be reached **only** through the generic
> `from "erika"` loader [`annotation-processors`](annotation-processors.md) ships —
> no `std_pkg_files` entry, no `@embedFile`, no compiler-core mention of erika. The
> v0.beta.6 erika spec already flagged this move as the follow-up "once that
> resolution is generalized — the source moves unchanged." This spec is that move.

## Intent

v0.beta.6 shipped erika (a C#/LINQ-style fluent `Query<T>` + an `erika "…"`
SQL-subset template over `@Expr`) **inside `std`** purely to dodge the per-lib
`registerXLib`/`markXImports` import machinery rakun needed. v0.beta.7 deletes
that machinery and ships **one generic loader**, so erika no longer needs the std
shortcut. This spec:

- **moves erika into its own `libs/erika/` package**, resolved by the generic
  `from "erika"` loader — the `.bp` source moves essentially unchanged (it was
  written with zero compiler-logic surface);
- **closes the one recorded user-facing limit** — the `erika "…"` template form
  going `unbound` after an `import {erika}` — by leaning on the generic
  template-fn import binding the loader now provides (not an erika-specific add);
- **lands the fluent ops the language now allows** that v0.beta.6 deferred to
  language gaps, and re-confirms the ones still gated.

erika carries **no decorators** — it is a client of the *loader* half of
`annotation-processors`, not the `@Decl` half. It is the proof that the generic
loader works for an ordinary (non-framework) external lib, exactly as rakun is the
proof for a decorator-driven one.

## Target syntax

```bp
import {erika} from "erika";                 // generic loader — NOT from "std"
import {Query} from "erika";

record Person { name: string, age: i32 }
val people = [Person("ana", 30), Person("rui", 16)];

// fluent layer
val adults = erika.of(people)
    .where({ p -> p.age >= 18 })
    .orderBy({ p -> p.name })
    .select({ p -> p.name })
    .toArray();                              // Array<string>

// the erika "…" template form — now resolves AFTER the import (the v0.beta.6 gap)
val list = erika "select * from people where age >= 18 order by name asc";
//         └──────────── expands (comptime) to ────────────┘
//         of(people).where({ row -> row.age >= 18 }).orderBy({ row -> row.name }).toArray()
```

## Examples

### the package move (no logic change)
```bp
// before (v0.beta.6): libs/std/src/erika.bp, wired in build.zig std_pkg_files,
//                      reached with  import {erika} from "std";
// after  (v0.beta.7): libs/erika/src/erika.bp + libs/erika/botopink.json,
//                      reached with  import {erika} from "erika";
```
Same record `Query<T>`, same operators, same `erika "…"` body — only the package
boundary and the import path change. `modules/compiler-core/src/**` gains nothing.

### the closed gap (template fn as an imported value)
```bp
import {erika} from "erika";
test "erika string form resolves after import" {
    val xs = erika "select * from src";      // v0.beta.6: `unbound`; v0.beta.7: resolves
    assert(xs.length() == src.length());
}
```
The generic loader binds a lib's same-named template fn into the importer's value
scope + `templateFns`/`exprParams`, so paren-free template application resolves —
generically, for any lib, not a special case for erika.

## Steps

### F0 — package extraction + generic loader wiring
- [ ] Create `libs/erika/` with `botopink.json` (`files: ["erika.bp"]`), `src/erika.bp`
      (moved from `libs/std/src/erika.bp`, source unchanged), `AGENTS.md`, `docs.md`,
      `examples.md`.
- [ ] **Remove** `"erika.bp"` from `std_pkg_files` in `build.zig`; drop the erika
      rows from `libs/std/src/docs.md`/`examples.md`/`AGENTS.md`. `std` no longer
      ships erika.
- [ ] `import {erika} from "erika"` resolves through the **generic** `from "<lib>"`
      loader (no per-lib embed/registry); `botopink test` discovers
      `libs/erika/src/erika.bp`. Zero `modules/compiler-core/src/**` edit beyond the
      generic loader already landed by `annotation-processors`.

### F1 — close the `erika "…"` import-resolution limit
- [ ] After `import {erika} from "erika"`, the same-named **template fn** is bound
      as a value (not only the `erika` namespace), so `erika "…"` paren-free
      application resolves — via the loader's generic template-fn binding, **not** an
      erika-specific path in core.
- [ ] Confirm the eager comptime body still runs over the minimal `node` prelude
      (native-JS lowering only; no host-helper ops) now that it lives in its own
      package — no regression from the move.

### F2 — fluent ops the language now allows (v0.beta.6 deferrals)
- [ ] Re-evaluate `selectMany` (deferred in v0.beta.6: needed `fn -> Query<U>` /
      `-> U[]` in a function-type param — G3 `fn() -> T[]` landed in `feat`). Land it
      if G3 unblocks it; else re-record the precise remaining gap.
- [ ] Re-evaluate multi-field projection (`select name, age` ⇒ needs an anonymous
      record *type* / tuple — G2 landed in `feat`). Land it if G2 unblocks naming the
      projected shape; else keep the explicit `q.fail("multi-field not yet")`.
- [ ] Keep the v0.beta.6 distinct-name predicate variants (`countWhere`/`firstWhere`/
      `anyWhere`) — no arity overloading on the JS backend.

### F3 — docs + tests in the lib
- [ ] `libs/erika/docs.md` + `examples.md` cover both forms (fluent + `erika "…"`);
      `libs/erika/AGENTS.md` documents the package, the loader path, and the
      remaining gaps. Update in the **same commit** as the code (repo rule).
- [ ] All tests live in `libs/erika/src/erika.bp`'s own `test "…"` blocks
      (`botopink test`) — the 19 v0.beta.6 blocks move with the file; add the
      now-resolving `erika "…"`-after-import test.

## Test scenarios

```
loader  ---- import {erika} from "erika" resolves via the generic loader (not std)
loader  ---- libs/std no longer exports erika (build.zig std_pkg_files dropped it)
erika.fluent ---- where/select/orderBy pipeline materializes the expected Array
erika.fluent ---- range(1,100) |> where even |> sum == 2550 (after the move)
erika.query  ---- `select * from people` expands and returns Array<Person>
erika.query  ---- erika "…" resolves AFTER import {erika} from "erika" (v0.beta.6 gap closed)
erika.query  ---- unknown collection ⇒ q.fail diagnostic at the call site
erika.query  ---- multi-field select ⇒ lands on G2, else clear not-yet diagnostic
gate    ---- grep -riE "erika" modules/compiler-core/src returns nothing
```

## Notes

- **erika ≠ std.** The whole point of this spec is that the v0.beta.6 std shortcut
  was scaffolding for the missing generic loader. Once `annotation-processors`
  ships that loader, erika graduates to a normal external package and `std` sheds a
  module it never should have owned.
- **Pure `.bp`, zero core surface.** The fluent layer + SQL-subset parser are
  botopink string code; the only compiler dependency is the *generic* loader +
  template-fn binding from `annotation-processors`. erika adds **no** core code and
  is named nowhere in `compiler-core` (the gate covers `erika` too).
- **Holes still v1.** Interpolated queries (`erika "… where age >= ${min}"` via
  `q.parts()` Text/Interp) remain the next extension, unchanged from v0.beta.6 —
  record, don't build here.
- **BLOCKED on `annotation-processors`** (the generic loader). Until it lands in
  `feat`, erika cannot leave `std`; carry the ⛔ banner in `TODO.md` and port the
  move once the mechanism merges. No new compiler-core code in this task.

# erika — finish the port: a runnable consumer example + the cross-module `erika "…"` form

**Slug**: erika
**Depends on**: [`generic-loader-binding`](generic-loader-binding.md) — so a consumer's bare `import {erika} from "erika"` binds the `erika "…"` template fn (the in-`libs/erika` tests already pass; the gap is cross-module)
**Files**: `examples/erika-linq/{botopink.json, src/*.bp}` (new runnable example project), `libs/erika/examples.md`, `libs/erika/AGENTS.md`
**Touches docs**: `libs/erika/examples.md`, `libs/erika/AGENTS.md`, `examples/AGENTS.md`
**Status**: pending

> Lib-side / example-side only — **zero** core code. The `erika` library itself
> (`libs/erika/src/erika.bp`, ~30 in-file tests) landed in v0.beta.7; what is
> missing is a **runnable consumer example** (erika ships no `examples/erika-*`
> project, unlike jhonstart) and the **cross-module `erika "…"`** call form, which
> the keystone [`generic-loader-binding`](generic-loader-binding.md) unblocks.

## Context — what landed vs. what is missing (v0.beta.7)

**Done, in `feat`:** `libs/erika/` is a pure `.bp` lib reached via `from "erika"` —
the eager/immutable `Query<T>` fluent layer (`where`/`select`/`orderBy`/`groupBy`/
`aggregate`/element terminals, `selectMany`, multi-field projection) and the
`erika "…"` SQL-subset template fn, with ~30 `test {}` blocks that pass under
`botopink test` **inside the lib**.

**Missing (the "incomplete" the port left):**
1. **No runnable example.** Every other lib has an `examples/<lib>-*` project a user
   can build/run; erika has only `libs/erika/examples.md` (prose) + in-lib tests.
   There is nothing that exercises erika as a **consumer** through `from "erika"`.
2. **Cross-module `erika "…"` is unbound.** The template fn works in the lib's own
   tests (same module, comptime scope), but `import {erika} from "erika"; erika "…"`
   in a *consumer* leaves bare `erika` unbound — the generic-loader-binding gap.

**Verified while writing the example (2026-06-10):** the fluent layer works
cross-module via the **bare** import (`import {of} from "erika"; of(list)…`) — a
working `examples/erika-linq/` with 4 passing tests ships in this set. Two
pre-existing gaps surfaced and are recorded, NOT erika-specific: the **namespace**
form `erika.of(...)` does not codegen for a disk lib (`erika is not defined` at
runtime — the namespace object isn't emitted), and `Array.range` (an `@[external]`
associated fn) is not bundled cross-module on commonJS (covered by
[`stdlib-backends-parity`](stdlib-backends-parity.md) A2). The example uses the bare
`of` form + list literals to stay green today.

## Target — the runnable example

```bp
// examples/erika-linq/botopink.json
{ "name": "erika-linq", "version": "0.0.1", "target": "commonJS", "dependencies": ["erika"] }
```

```bp
// examples/erika-linq/src/main.bp  — the shipped, green form (bare import)
import {of} from "erika";

record Person { name: string, age: i32 }

val people = [
    Person(name: "Ann", age: 30), Person(name: "Bob", age: 17),
    Person(name: "Cy",  age: 22), Person(name: "Dan", age: 15),
];

// list → query → join (the fluent layer; `of` is the bare-imported constructor)
fn adultNames() -> string {
    return of(people).where({ p -> p.age >= 18 }).orderBy({ p -> p.name })
        .select({ p -> p.name }).toArray().join(", ");           // "Ann, Cy"
}

// the query result is an Array<T> = Iterator<T>, so iterator ops compose:
fn adultAgeSum() -> i32 {
    return of(people).where({ p -> p.age >= 18 }).select({ p -> p.age })
        .toArray().fold(0, { acc, a -> acc + a });               // 52
}

test "list → query → join" { assert adultNames() == "Ann, Cy"; }
test "iterator fold over the query result" { assert adultAgeSum() == 52; }
```

The **SQL form** is added in F1 once the keystone binds bare `erika`:
```bp
import {erika} from "erika";
val cities = [Person(name: "Paris", age: 9), Person(name: "Lyon", age: 5)];
test "erika \"…\" runs cross-module" {
    val names = erika "select name from cities where age >= 5 order by name asc";
    assert names.join(",") == "Lyon,Paris";
}
```

## Steps

### F0 — ship the runnable example  ✅ (done 2026-06-10)
- [x] `examples/erika-linq/` (`botopink.json` deps `["erika"]` + `src/main.bp`)
      imports `{of} from "erika"` (bare form), pipes **lists** through the fluent
      `Query<T>`, folds/joins the result as an **Iterator** (`fold`/`map`/`join`),
      and has a `main` + 4 `test {}` blocks — **`botopink test` green (4/4)**. Uses
      the bare `of` + list literals (not the namespace form, not `Array.range` —
      both hit pre-existing gaps; see Context).

### F1 — the cross-module `erika "…"` form
- [ ] Once [`generic-loader-binding`](generic-loader-binding.md) binds the bare
      imported template fn, add an `erika "select …"` SQL-form `test {}` to the
      example (a consumer module, not the lib). It expands + runs against a
      `val` collection in the caller's comptime scope.

### F2 — docs
- [ ] Point `libs/erika/examples.md` at the runnable `examples/erika-linq/` (the
      prose examples become a real project); note in `AGENTS.md` that the SQL form
      now works cross-module (drop the recorded "unbound after import" limit). Same
      commit as the example.

## Test scenarios

```
test   ---- botopink test green from examples/erika-linq/ (4/4 — done)
run    ---- examples/erika-linq: the fluent pipeline returns "Ann, Cy" (bare `of` import)
run    ---- examples/erika-linq: a list folded/joined as an Iterator (52 / "ANN / CY / DAN")
run    ---- examples/erika-linq: erika "select … order by name asc" runs cross-module (F1)
gate   ---- grep -riE "erika" modules/compiler-core/src returns nothing (std exempt)
```

## Notes

- **The lib is done; this finishes the *port*** — the user-facing deliverable (a
  runnable example) + the one cross-module gap. No new LINQ operators are required
  (the operator set + the `erika "…"` template already pass in-lib); if a gap
  surfaces while writing the example, fix it in `libs/erika/*.bp` (real `.bp`,
  memory: [[feedback_prefer_bp_over_dbp]]).
- **Cross-module `erika "…"` is the only language dependency** → the single DAG edge
  to `generic-loader-binding` (shared with `jhonstart-html`). The fluent form needs
  nothing new. Memory: [[project_generic_loader_namespace_only]].
- **SQL form needs a `val` collection** (it snapshots the caller's *comptime* scope,
  which captures immutable `val` only) — the example uses `val cities`, matching the
  in-lib tests. The fluent form queries any `val`/`var`.
- Zero core code; the compiler stays unaware of erika (gate). Memory:
  [[feedback_no_lib_specific_in_core]].

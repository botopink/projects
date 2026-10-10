# Front 137 — erika queries a database: holes, a SQL target, the template annotation

**Priority:** high — rakun-data's repositories (08 step 7) stand on it · **State:** not started
**Depends on:** decisions 311, 312, 313 · `01-compiler/01-checker` step 29 (step 5, and step 2's template method `query`, 397) · nat-d9 (erika's operator names; none of this front's steps waits on it)
**Owns:** `repository/erika/modules/erika/**` (`src/erika.bp`, its in-file tests, `botopink.json`,
`src/root.bp`), `repository/erika/{docs.md,examples.md,AGENTS.md}` · `modules/erika-test/**` for the
helpers its cells need
**Does not touch:** rakun (`DbContext` implementing `QueryContext` and `#[entity]` recording `QueryTable` are 08 step 7's) · the compiler
(the annotation form is `01-checker` step 29's) · `examples/erika-linq/**` beyond a new example file

## Goal

erika is botopink's LINQ (decision 312): one grammar, two targets picked by the type of the source.
Today `erika "select … from X where … order by …"` (`modules/erika/src/erika.bp:389`) parses at
comptime and lowers only to the fluent pipeline over an `Array<T>` `val`; holes are a listed gap
(`docs.md` § Known gaps). After this front:

```bp
import erika from "erika";
import {models.User};

// in memory, as today
val adults = erika "select * from people where age >= ${min}";

// a database query on the context (397): QueryContext — rakun-data's DbContext implements it;
// `User` an entity: its QueryTable meta (#[entity]) gives the table and the columns at build
type Report(db: DbContext) {
    fn active(self: Self) -> @Result<User[], StoreError> {
        return self.db.query "select * from User where active = true";
    }
}

// a repository method (313; #[repository] is rakun-data's side)
#[repository]
behavior Users {
    #[erika "select * from User where id = ${id} limit 1"]
    fn find(self: Self, id: i32) -> @Result<?User, StoreError>;
}
```

erika names no library (decision 113): the SQL target speaks to its own `QueryContext` behavior and
reads its own `QueryTable` meta, never `#[entity]`, `SqlTemplate` or rakun (397).

## Open

### Step 1 — holes `${…}` are bound values

- [ ] `erika "… where age >= ${min}"` in memory: the hole's expression is the comparison's operand,
      evaluated once at run time; any expression (`${self.minAge}`, `${limit + 1}`), type-checked against
      the field it is compared with (a mismatch is an error at the hole)
- [ ] a hole is never text: it cannot stand for a field, a keyword or a table — a hole outside a value
      position is a located error
- [ ] `docs.md` § Known gaps loses "Interpolated queries"; in-file tests on commonJS and erlang

### Step 2 — `QueryContext`, `QueryTable` and the SQL target (397)

- [ ] `pub behavior QueryContext` in `erika.bp`: running a statement (SQL text and bound parameters) answering
      `@Result<T[], E>`, the error a parameter of the behavior, so erika names no library's error (the exact
      signature in `docs.md`); `pub type QueryTable(name: string, columns: QueryColumn[])` and
      `QueryColumn(field, column)`, the meta a persistence library records on an entity
- [ ] `query`, erika's template method on every `QueryContext` (397 (3); the template method is
      `01-checker` step 29's): `self.db.query "select * from User where active = true"`; an `Array<T>`
      source keeps the in-memory form (`erika "…"`, today's fluent pipeline)
- [ ] `from User` names a type, resolved at the call site (`e.lookup`, 112): not imported is an error at the
      token; on a `QueryContext` it reads `@typeInfo(User).meta(QueryTable)` at build — no meta is an error at
      the query ("`User` is not an entity"), a field `User` lacks an error at the field —, and the SQL text with
      `$1…$n` parameters in hole order is built at build from the type's table and columns
- [ ] cells: the SQL text and parameters a recording `QueryContext` receives, for every clause; an entity
      read through two tables' types on one context

### Step 3 — the number of rows is written

- [ ] an answer `?T` requires `limit 1`, an answer `T[]` (or `Array<T>`) refuses it; a mismatch is a
      compile error at the query naming the declared answer (decision 312)
- [ ] in memory `limit n` is `take(n)`; `?T` answers `first()`

### Step 4 — the grammar grows

- [ ] `limit <n>` (a number or a hole), `join <Type> on <a.f> = <b.g>` (inner), the aggregates
      `count(*)`, `sum`, `avg`, `min`, `max` with `group by` — each on both targets, each with a located
      error for its malformed forms (`q.failAt`)
- [ ] the grammar block of `docs.md` rewritten; `examples.md` gains one example per clause

### Step 5 — the template annotation `#[erika "…"]` (after `01-checker` step 29)

- [ ] `erika` used as an annotation on a method (decision 311): the query checked against the
      method's parameters (each `${…}` a parameter, by name and type) and its declared answer (step 3);
      the result recorded as typed meta of the method (298) — the SQL text with its parameter order —
      for a type-level decorator to read (`#[repository]`, rakun 08 step 7)
- [ ] on anything but a method it is an error at the annotation; with `${…}` naming no parameter, the
      ordinary unbound-name error at the hole
- [ ] `run/` cell: a test behavior whose type-level test decorator reads the meta and asserts it

**Gate:** standard (fronts.md § Gate) + `botopink test` in `modules/erika` and `modules/erika-test` on
commonJS and erlang, `botopink build` of `examples/erika-linq`, erika's pre-commit hook green.

## Notes

- rakun 08 step 7 consumes steps 1–5; 09 waits on `erk-b` (a document target is that question's (b)).
- erika's in-memory names (`where`, `select`, …) are `nat-d9`'s; this front adds no fluent operator.

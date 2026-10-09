# Front 137 — erika queries a database: holes, a SQL target, the template annotation

**Priority:** high — rakun-data's repositories (08 step 7) stand on it · **State:** not started
**Depends on:** decisions 311, 312, 313 · `01-compiler/01-checker` step 29 (step 5 only) · `erk-a`
(step 2's body form) · nat-d9 (erika's operator names; none of this front's steps waits on it)
**Owns:** `repository/erika/modules/erika/**` (`src/erika.bp`, its in-file tests, `botopink.json`,
`src/root.bp`), `repository/erika/{docs.md,examples.md,AGENTS.md}` · `modules/erika-test/**` for the
helpers its cells need
**Does not touch:** rakun (`Table<T>` implementing `QuerySource<T>` is 08 step 7's) · the compiler
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

// a database source (QuerySource<T>; rakun-data's Table<T> implements it)
type Report(users: Table<User>) {
    fn active(self: Self) -> @Result<User[], StoreError> {
        return erika "select * from User where active = true";        // the source: erk-a
    }
}

// a repository method (313; #[repository] is rakun-data's side)
#[repository]
behavior Users {
    #[erika "select * from User where id = ${id} limit 1"]
    fn find(self: Self, id: i32) -> @Result<?User, StoreError>;
}
```

erika names no library (decision 113): the SQL target speaks to its own `QuerySource<T>` behavior and
never to `#[entity]`, `SqlTemplate` or rakun.

## Open

### Step 1 — holes `${…}` are bound values

- [ ] `erika "… where age >= ${min}"` in memory: the hole's expression is the comparison's operand,
      evaluated once at run time; any expression (`${self.minAge}`, `${limit + 1}`), type-checked against
      the field it is compared with (a mismatch is an error at the hole)
- [ ] a hole is never text: it cannot stand for a field, a keyword or a table — a hole outside a value
      position is a located error
- [ ] `docs.md` § Known gaps loses "Interpolated queries"; in-file tests on commonJS and erlang

### Step 2 — the `QuerySource<T>` behavior and the SQL target

- [ ] `pub behavior QuerySource<T>` in `erika.bp`: the table name, and running a statement (text and
      bound parameters) answering `@Result<…, StoreError-like>` — the error type a parameter of the
      behavior, so erika names no library's error (the exact signature recorded in `docs.md`)
- [ ] the target is the source's type: an `Array<T>` lowers to the fluent pipeline (today's), a
      `QuerySource<T>` to SQL text with `$1…$n` parameters in hole order plus the parameter list; any
      other source is an error at `from`
- [ ] `from User` names a type, resolved at the call site (`e.lookup`, decision 112: hover and
      go-to-definition reach `User`); not imported is an error at the token; a field `User` lacks is an
      error at the field; the table name comes from the source at run time, never from erika
- [ ] the body form's source per `erk-a` (recommended: the one field of `self` typed `QuerySource<User>`;
      none or two an error at the query)
- [ ] cells: the SQL text and parameters a recording `QuerySource<T>` receives, for every clause

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

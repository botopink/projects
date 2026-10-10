# Front 137 — erika queries a database: holes, a SQL target, the template annotation

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [145-erika](../README.md): s2 → 145 s1 · s3 → 145 s1 · s4 → 145 s1 · s5 → 145 s1. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** high — rakun-data's repositories (08 step 7) stand on it · **State:** not started
**Depends on:** decisions 311, 312, 313 · `01-compiler/01-checker` step 29 (step 5, and step 2's template method `query`, 397) · nat-d9 (erika's operator names; none of this front's steps waits on it)
**Owns:** `repository/erika/modules/erika/**` (`src/erika.bp`, its in-file tests, `botopink.json`,
`src/root.bp`), `repository/erika/{docs.md,examples.md,AGENTS.md}` · `modules/erika-test/**` for the
helpers its cells need
**Does not touch:** `dbcontext` (`DbContext` implementing `QueryContext` and `#[entity]` recording `QueryTable` are `04-rakun/143`'s, 398) · the compiler
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

// a database query on the context (397): QueryContext — dbcontext's DbContext implements it (398);
// `User` an entity: its QueryTable meta (#[entity]) gives the table and the columns at build
type Report(db: DbContext) {
    fn active(self: Self) -> @Result<User[], StoreError> {
        return self.db.query "select * from User where active = true";
    }
}

// a repository method (313, 398: the dbcontext library's)
#[repository]
behavior Users {
    #[query "select * from User where id = ${id} limit 1"]
    fn find(self: Self, id: i32) -> @Result<?User, StoreError>;
}
```

erika names no library (decision 113): the SQL target speaks to its own `QueryContext` behavior and
reads its own `QueryTable` meta, never `#[entity]`, `SqlTemplate` or rakun (397).

## Notes

- rakun 08 step 7 consumes steps 1–5; 09 waits on `erk-b` (a document target is that question's (b)).
- erika's in-memory names (`where`, `select`, …) are `nat-d9`'s; this front adds no fluent operator.

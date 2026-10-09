# Front 08 — SQL data access: lazy bootstrap, the migration lock, the ORM's two refusals

**Priority:** high — session, scheduling, security, cache, mail and merged tx/devtools stand on
`rakun-data`; its open boxes are small · **State:** not started
**Depends on:** 128 · 04 step 4 (`rkExcludeFromEager`, step 1 only) · decision 147 (`try` in a
lambda takes its expected type's return — tests written against it) · lg2-e/f (R78-1's field list) ·
decisions 311–313 (step 7: `01-checker` step 29, `137` steps 1–5, `erk-a` for the body-form cell, decision 318: `#[repository]` is rakun-data's, on a behavior only) · 03r-v (confirmation)
**Owns:** `modules/rakun-data/**` except 09's (`src/nosql/**`, `src/nosql_host.bp`,
`src/sidecars/rakun_nosql.erl`, `test/nosql/**`), 15's (`src/tx/**`, `test/tx/**`) and 65's line in
`src/devtools/devtools.bp`; edits neither `botopink.json` nor `src/root.bp` this milestone ·
`repository/rakun/AGENTS.md` § Data
**Does not touch:** 09's, 15's files · `src/devtools/**` beyond what a test needs · the core
(eager-pass hook is 04's) · `rakun-scheduling` (15's)

## Goal

`bootstrapMode: Lazy` (the `#[config("rakun.data")]` record, 299) keeps repositories out of the eager pass; the
migration lock gains a PostgreSQL advisory arm beside `global`; the ORM's unknown-field refusal and
join count asserted on what the code can show.

## Mechanism

- **R08-1.** Today `rakun.data.repositories.bootstrap-mode` (registered by `datasource.bp`, default
  `eager`; accepts `eager`, `deferred`, `lazy`). Under 299 (step 5) it is a field of the typed record
  `#[config("rakun.data")] pub type DataConfig(…, bootstrapMode: BootstrapMode = .Eager)`, its key the
  field's exact name and its value the variant (`bootstrapMode: Lazy`). Eager pass is the core's
  `eagerInitIn`; under `Lazy` this member excludes every `#[repository]` type via 04 step 4's
  `rkExcludeFromEager` (by type, 04 step 6 — 281) at boot, before the pass.
- **R77-1.** Advisory arm `pg_advisory_lock` on PostgreSQL, in `rakun_migration.erl` behind the
  `postgresql` scheme, asserted on the SQL issued (no server in the gate); `global` arm on the others
  (a node-local lock on multi-node PostgreSQL is the wrong default).
- **R78-1.** Since `01-compiler/130` (decision 216) the ORM decorators write members: `T.Columns`,
  `T.columns()`, `<Repo>.<m>Sql()`, `<Repo>.<m>Derived(…)`, and the meta
  `@typeInfo(T).meta(Entity)` (298: `Entity(table, columns)`). A derived finder naming no field fails at build with
  "unknown field 'ciudad'" naming `Columns` (`orm_build_test.bp`), without the field list.
  `#[entityRepository("City")]` names its entity by string today (step 4 takes the type, 281); whether it can read
  `@typeInfo(City).meta(Entity)?.columns` at comptime (decisions 216, 248) decides if the list prints
  without lg2-e/f.
- **R78-2.** ETS arm has no JOIN, PostgreSQL arm no server here; "nothing is fetched that the method
  did not name" asserted by statement count on ETS over a 100-row single-table fetch plus the join's SQL text.

PostgreSQL and MySQL arms: wire code, no server in the gate — SQL texts asserted, sockets not; no
cell claims to have reached a server.

## Open

### Step 1 — Lazy bootstrap (R08-1, R08-2; after 04 step 4)

- [ ] `sql_pool_test.bp`: with `bootstrapMode: Lazy` (`DataConfig`, step 5 — 299; `rakun.data.repositories.bootstrap-mode=lazy` until it lands), a recording-constructor `#[repository]` is not constructed by `Rakun.run`, is constructed on first resolution
- [ ] with the default (`Eager`) it is constructed before `Rakun.run` returns
- [ ] R08-2 ("named parameters, the repository queries, the pool and local transactions all behave as the acceptance lists" — `#[query]` reads as step 7's `#[repository]` forms, 313) ticked, the four lists re-run

### Step 2 — Migration lock (R77-1)

- [ ] `migration_test.bp`: under `postgresql` the lock arm issues `SELECT pg_advisory_lock(<key>)` before the first migration and `pg_advisory_unlock` after the last, on the recorded statement list (recording datasource, no server)
- [ ] under `ets:memory` and `mysql` the `global` arm is taken, the standalone-node warning emitted once
- [ ] member README states the two arms and which schemes take which

### Step 3 — ORM (R78-1, R78-2, RX-2)

- [ ] `orm_test.bp`: a 100-row fetch through a derived finder issues exactly one statement (recorded); the join finder's SQL names exactly the two tables and the join column
- [ ] R78-2 reworded to the statement-count-and-text assertion; the "100 joined rows on a real arm" half is a `deferred.md` row
- [ ] R78-1 ("`findByCiudad` is a compile error naming the entity and listing its fields"): re-measured on the post-130 decorators — if `#[entityRepository]` can read `meta(Entity)?.columns` (298), the refusal lists them and the box ticks; else the measured text recorded, box open on lg2-e/f naming the nearest form
- [ ] RX-2 (78): decorator-argument default re-measured in `orm_build_test.bp`

### Step 4 — references, not strings (decision 281)

- [ ] `#[entityRepository(City)]` takes the type; `derivedSql("CityRepo", "countByState")` takes the
      function; an operator is `Op`'s variant, never `">="`
- [ ] `index`, `unique` take `Type.Field<T>` (`.state`; 308); table and column names stay strings (SQL's, 280 example 6)
- [ ] `examples/city-entity-example.bp`, `examples/audit-and-revisions-example.bp` rewritten to decision 281 (`#[entityRepository(City)]`, `derivedSql` by function, `Op`'s variant) and 299 (no `rkProp` / `rkPropInt` import)

### Step 5 — configuration as a typed record (decision 299)

- [ ] this member's `#[value("…")]` / `rkProp*` reads and group configs become `#[config("<prefix>")]` records (`04` step 7)

### Step 6 — one API answering `@Result<T, StoreError>` (decision 304; after `01-compiler/02-erlang` step 14)

- [ ] `StoreError` declared in `src/datasource.bp` (already exported; this front edits neither `botopink.json` nor `src/root.bp`): `pub type StoreError { Unavailable(message: string), Timeout(ms: i32), Conflict(message: string), Constraint(name: string, message: string) }` — the draft cases, closed here with 09 (a case added only when a driver failure needs its own handling); exported for 09
- [ ] `SqlTemplate.query` / `update` / `single` answer `@Result<Rows | i32 | ?Row, StoreError>`; `raising` and the `@panic(o.error)` path go — a driver failure is `throw` of its case, never a raise
- [ ] `tryQuery`, `tryUpdate`, `tryQueryOn`, `tryUpdateOn` (`src/sql/template.bp:106-152`), `tryMigrate` (`src/migration/migrate.bp:414`) and every other `try*` twin in the member deleted; their callers use the one API (`case` or `try`)
- [ ] the ORM repository's generated methods (`save`, `update`, `byId`, derived queries) answer `@Result<…, StoreError>`; an optimistic-lock miss is `Error(Conflict(…))` (`audit-and-revisions-example.bp`'s `repo.tryUpdate(saved)` becomes `repo.update(saved)` matched on `Conflict`)
- [ ] `transaction(work)`: an `Error` the work returns rolls back, as a raise does today — one cell each
- [ ] `@panic` left only for a programming error: `single()` meeting more than one row keeps its message naming the statement
- [ ] the method forwarding comment in `template.bp` (a method `-> @Result` lowered as a plain function) gone with 02 step 14
- [ ] the front's examples and `repository/rakun/AGENTS.md` § SQL data access rewritten to `try` / `case`

### Step 7 — repositories: `#[repository] behavior` with `#[erika "…"]` or `#[nativeQuery("…")]` (decisions 311–313; after `01-checker` step 29 and `137` steps 1–5)

Today a repository is a `type` whose method carries `#[query("…")]` (`src/sql/query.bp`), which writes
`<Repo>.<m>Sql()` and registers the statement through `rkRegisterQuery`; the body calls the member by hand.

```bp
#[repository]
behavior Users {
    #[erika "select * from User where id = ${id} limit 1"]
    fn find(self: Self, id: i32) -> @Result<?User, StoreError>;

    #[nativeQuery("select * from users where email = :email limit 1")]
    fn byEmail(self: Self, email: string) -> @Result<?User, StoreError>;
}

val users: Users = Users.of(db);      // generated: Users.Sql(db: SqlTemplate) implement Users
```

- [ ] `#[repository]` is rakun-data's and annotates only a `behavior` (318; the core's type stereotype goes
      in 04 step 8): it reads each method's query meta (`#[erika]`'s, `#[nativeQuery]`'s — 298)
      and generates `Users.Sql(db: SqlTemplate) implement Users`, `Users.of(db)` and the by-type
      registration in the container (`Users` injectable); on anything but a behavior it is an error at
      the annotation; a method with neither query annotation is an error at the method
- [ ] `#[nativeQuery("…")]`: the driver's SQL as a comptime string, verbatim; `:name` placeholders
      matched by name to the method's parameters (an unanswered placeholder or an unused parameter is an
      error at the annotation); the leading-keyword and quote-next-to-placeholder checks of today's
      `#[query]` kept; rows decoded into the declared answer by column name
- [ ] a `?T` answer: erika's query must say `limit 1` (312, checked by erika); a native query meeting more
      than one row is the `single()` panic naming the statement (304)
- [ ] `Table<T>` implements erika's `QuerySource<T>` (`137` step 2): the table name from `#[entity]`
      (298), statements run on its `SqlTemplate`
- [ ] `SqlTemplate.query` / `update` / `single`: `sql` is `comptime` — a statement built at run time is
      refused at the argument (the injection rule `#[query]` kept by shape)
- [ ] `#[query]`, the `<m>Sql()` members, `rkRegisterQuery` / `rkRegisteredQueries` deleted; the statement
      inventory (`/actuator/sql`, 11) read from the query meta through `@TypeInfo.all` (253)
- [ ] `examples/city-entity-example.bp`, `examples/audit-and-revisions-example.bp` rewritten to the
      repository behavior; their `// LANGUAGE GAP` markers for the bodyless-method row go, and the row
      with them (`language-gaps.md`)
- [ ] cells: a `#[repository]` over ETS answering both forms; `Users.mock()` (`#[mocks.mock]`) on the same
      behavior; the body form (`erika "…"` in a `type` method — its source per `erk-a`); `reject/` cells
      for a `?T` without `limit 1`, a field `User` lacks, a placeholder no parameter answers
- [ ] `repository/rakun/AGENTS.md` § SQL data access and the member README rewritten to the two forms

- [ ] `#[transactional]` (`src/sql/transactional.bp`) a wrapper (316, 318 (7)): the hand-written `<Type>Tx`
      proxy deleted, its sites the annotation on the method

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-data`.

Blast radius: step 1 changes construction timing under `lazy` only; `rakun-session`'s SQL store,
`rakun-scheduling`'s job store and `src/tx/**` construct eagerly by default. Step 2 adds statements
on the PostgreSQL arm only.

Kept for open markers: `examples/city-entity-example.bp`, `examples/audit-and-revisions-example.bp`
(the bodyless-method row, by design since 311 — they go with step 7).

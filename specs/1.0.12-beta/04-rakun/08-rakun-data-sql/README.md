# Front 08 — SQL data access: lazy bootstrap, the migration lock, the ORM's two refusals

**Priority:** high — session, scheduling, security, cache, mail and merged tx/devtools stand on
`rakun-data`; its open boxes are small · **State:** not started
**Depends on:** 128 · 04 step 4 (`rkExcludeFromEager`, step 1 only) · decision 147 (`try` in a
lambda takes its expected type's return — tests written against it) · lg2-e/f (R78-1's field list) ·
lg2-r (decorator-supplied method body — `#[query]` shape stays) · 03r-v (confirmation)
**Owns:** `modules/rakun-data/**` except 09's (`src/nosql/**`, `src/nosql_host.bp`,
`src/sidecars/rakun_nosql.erl`, `test/nosql/**`), 15's (`src/tx/**`, `test/tx/**`) and 65's line in
`src/devtools/devtools.bp`; edits neither `botopink.json` nor `src/root.bp` this milestone ·
`repository/rakun/AGENTS.md` § Data
**Does not touch:** 09's, 15's files · `src/devtools/**` beyond what a test needs · the core
(eager-pass hook is 04's) · `rakun-scheduling` (15's)

## Goal

`rakun.data.repositories.bootstrap-mode=lazy` keeps repositories out of the eager pass; the
migration lock gains a PostgreSQL advisory arm beside `global`; the ORM's unknown-field refusal and
join count asserted on what the code can show.

## Mechanism

- **R08-1.** `rakun.data.repositories.bootstrap-mode` (registered by `datasource.bp`, default
  `eager`; accepts `eager`, `deferred`, `lazy`). Eager pass is the core's `eagerInitIn`; under `lazy`
  this member registers every `#[repository]` name via 04 step 4's `rkExcludeFromEager(name)` at
  boot, before the pass.
- **R77-1.** Advisory arm `pg_advisory_lock` on PostgreSQL, in `rakun_migration.erl` behind the
  `postgresql` scheme, asserted on the SQL issued (no server in the gate); `global` arm on the others
  (a node-local lock on multi-node PostgreSQL is the wrong default).
- **R78-1.** Since `01-compiler/130` (decision 216) the ORM decorators write members: `T.Columns`,
  `T.columns()`, `<Repo>.<m>Sql()`, `<Repo>.<m>Derived(…)`, and the meta
  `@typeInfo(T).meta(Entity)` (298: `Entity(table, columns)`). A derived finder naming no field fails at build with
  "unknown field 'ciudad'" naming `Columns` (`orm_build_test.bp`), without the field list.
  `#[entityRepository("City")]` names its entity by string; whether it can read
  `@typeInfo(City).meta(Entity)?.columns` at comptime (decisions 216, 248) decides if the list prints
  without lg2-e/f.
- **R78-2.** ETS arm has no JOIN, PostgreSQL arm no server here; "nothing is fetched that the method
  did not name" asserted by statement count on ETS over a 100-row single-table fetch plus the join's SQL text.

PostgreSQL and MySQL arms: wire code, no server in the gate — SQL texts asserted, sockets not; no
cell claims to have reached a server.

## Open

### Step 1 — Lazy bootstrap (R08-1, R08-2; after 04 step 4)

- [ ] `sql_pool_test.bp`: with `rakun.data.repositories.bootstrap-mode=lazy`, a recording-constructor `#[repository]` is not constructed by `Rakun.run`, is constructed on first `resolve`
- [ ] with the default (`eager`) it is constructed before `Rakun.run` returns
- [ ] R08-2 ("named parameters, `#[query]`, the pool and local transactions all behave as the acceptance lists") ticked, the four lists re-run

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
- [ ] `index`, `unique` take `Field<T>` (`.state`); table and column names stay strings (SQL's, 280 example 6)

### Step 5 — configuration as a typed record (decision 299)

- [ ] this member's `#[value("…")]` / `rkProp*` reads and group configs become `#[config("<prefix>")]` records (`04` step 7)

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-data`.

Blast radius: step 1 changes construction timing under `lazy` only; `rakun-session`'s SQL store,
`rakun-scheduling`'s job store and `src/tx/**` construct eagerly by default. Step 2 adds statements
on the PostgreSQL arm only.

Kept for open markers: `examples/city-entity-example.bp`, `examples/audit-and-revisions-example.bp`
(lg2-r, the self-field rule by design).

# Front 08 — SQL data access: lazy bootstrap, the migration lock, the ORM's two refusals

**Priority:** high — `rakun-data` is what session, scheduling, security, cache, mail and the merged
tx/devtools stand on; its open boxes are small · **State:** not started
**Depends on:** 128 · 04 step 4 (`rkExcludeFromEager`, for step 1 only) · decision 147 (`try` in a
lambda takes its expected type's return — the tests are written against it) · lg2-e/f (R78-1's
field list) · lg2-r (a decorator-supplied method body — the `#[query]` shape stays) · 03r-v (confirmation)
**Owns:** `modules/rakun-data/**` except 09's (`src/nosql/**`, `src/nosql_host.bp`,
`src/sidecars/rakun_nosql.erl`, `test/nosql/**`), 15's (`src/tx/**`, `test/tx/**`) and 65's line in
`src/devtools/devtools.bp`; edits neither `botopink.json` nor `src/root.bp` this milestone ·
`repository/rakun/AGENTS.md` § Data
**Does not touch:** 09's, 15's files · `src/devtools/**` beyond what a test needs · the core (the
eager-pass hook is 04's) · `rakun-scheduling` (15's)

## Goal

`rakun.data.repositories.bootstrap-mode=lazy` keeps repositories out of the boot's eager pass; the
migration lock has a PostgreSQL advisory arm beside the `global` one; the ORM's unknown-field refusal
and its join count are asserted on what the code can show.

## Mechanism

- **R08-1.** The property is `rakun.data.repositories.bootstrap-mode` (`datasource.bp` registers it,
  default `eager`; accepted `eager`, `deferred`, `lazy`). The eager pass is the core's `eagerInitIn`;
  under `lazy` this member registers every `#[repository]` name through 04 step 4's
  `rkExcludeFromEager(name)` at boot, before the pass.
- **R77-1.** The advisory arm is `pg_advisory_lock` on PostgreSQL, written in `rakun_migration.erl`
  behind the `postgresql` scheme and asserted on the SQL it issues (no server in the gate); the
  `global` arm on the others — a node-local lock on a multi-node PostgreSQL deployment is the wrong
  default.
- **R78-1.** Since `01-compiler/130` (decision 216) the ORM decorators write members: `T.Columns`,
  `T.columns()`, `<Repo>.<m>Sql()`, `<Repo>.<m>Derived(…)`, and the meta
  `@typeInfo(T).meta.entity.{table,columns}`. A derived finder naming no field fails at build with
  "unknown field 'ciudad'" naming `Columns` (`orm_build_test.bp`), without the field list.
  `#[entityRepository("City")]` names its entity by string; whether the repository decorator can read
  `@typeInfo(City).meta.entity.columns` at comptime (decisions 216, 248) is what decides if the list
  can be printed without lg2-e/f.
- **R78-2.** The ETS arm has no JOIN and the PostgreSQL arm has no server here; "nothing is fetched
  that the method did not name" is asserted by statement count on ETS over a 100-row single-table
  fetch plus the join's SQL text.

The PostgreSQL and MySQL arms are wire code with no server in the gate: their SQL texts are
asserted, their sockets are not — no cell claims to have reached a server.

## Open

### Step 1 — Lazy bootstrap (R08-1, R08-2; after 04 step 4)

- [ ] `sql_pool_test.bp`: with `rakun.data.repositories.bootstrap-mode=lazy`, a `#[repository]` whose constructor records is not constructed by `Rakun.run` and is constructed on its first `resolve`
- [ ] with the default (`eager`) it is constructed before `Rakun.run` returns
- [ ] R08-2 ("named parameters, `#[query]`, the pool and local transactions all behave as the acceptance lists") ticked, the four lists re-run

### Step 2 — Migration lock (R77-1)

- [ ] `migration_test.bp`: under the `postgresql` scheme the lock arm issues `SELECT pg_advisory_lock(<key>)` before the first migration and `pg_advisory_unlock` after the last, asserted on the recorded statement list (the recording datasource, no server)
- [ ] under `ets:memory` and `mysql` the `global` arm is taken and the standalone-node warning is emitted once
- [ ] the member README states the two arms and which schemes take which

### Step 3 — ORM (R78-1, R78-2, RX-2)

- [ ] `orm_test.bp`: a 100-row fetch through a derived finder issues exactly one statement (recorded), and the join finder's SQL text names exactly the two tables and the join column
- [ ] R78-2 reworded to the statement-count-and-text assertion; the "100 joined rows on a real arm" half is a `deferred.md` row
- [ ] R78-1 ("`findByCiudad` is a compile error naming the entity and listing its fields"): re-measured on the post-130 decorators — if `#[entityRepository]` can read the entity's `meta.entity.columns`, the refusal lists them and the box ticks; otherwise the measured text is recorded and the box stays open on lg2-e/f, naming the nearest form
- [ ] RX-2 (78): the decorator-argument default re-measured in `orm_build_test.bp`

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-data`.

Blast radius: step 1 changes when a repository is constructed under `lazy` only; `rakun-session`'s
SQL store, `rakun-scheduling`'s job store and `src/tx/**` construct eagerly by default. Step 2 adds
statements on the PostgreSQL arm only.

Kept for their open markers: `examples/city-entity-example.bp`, `examples/audit-and-revisions-example.bp`
(lg2-r, the self-field rule by design).

# Front 08 — SQL data access: lazy bootstrap, the migration lock, the ORM's two refusals

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [150-rakun](../README.md): s1 → 150 s4 · s2 → 150 s4 · s3 → 150 s4 · s4 → 150 s4 · s5 → 150 s4 · s6 → 150 s4 · s7 → 150 s4. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** high — session, scheduling, security, cache, mail and merged tx/devtools stand on
`rakun-data`; its open boxes are small · **State:** not started
**Depends on:** 128 · 04 step 4 (`rkExcludeFromEager`, step 1 only) · decision 147 (`try` in a
lambda takes its expected type's return — tests written against it) · decision 347 (R78-1's field list: the type-level generator reads it) ·
decisions 311–313, 397, 398 (step 7: `04-rakun/143` steps 1–2 — entities, the context and the repositories are `dbcontext`'s) · 03r-v (confirmation)
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
  `@typeInfo(City).meta(Entity)?.columns` at comptime (decisions 216, 248) decides if the list prints;
  under 347 the check is the type-level generator's (318's `#[repository]` on a behavior), never a
  method marker's.
- **R78-2.** ETS arm has no JOIN, PostgreSQL arm no server here; "nothing is fetched that the method
  did not name" asserted by statement count on ETS over a 100-row single-table fetch plus the join's SQL text.

PostgreSQL and MySQL arms: wire code, no server in the gate — SQL texts asserted, sockets not; no
cell claims to have reached a server.

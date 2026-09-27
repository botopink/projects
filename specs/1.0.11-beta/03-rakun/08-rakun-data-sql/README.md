# Front 08 — SQL Data Access (the data member's tail)

**Priority:** high — `rakun-data` is what session, scheduling, security, cache, tx, mail, stream and devtools stand on; its five open boxes are small and the member is otherwise closed
**Carries:** 77 · 78
**Depends on:** none in this track. Compiler: lg-a (`try` in a lambda — 08's own tests), lg2-e/f (R78-1's field list), lg2-r (a decorator-supplied method body — the `#[query]` shape stays)
**Owns:** `modules/rakun-data/**` except 09's (`src/nosql/**`, `src/nosql_host.bp`, `src/sidecars/rakun_nosql.erl`, `test/nosql/**`). In this milestone it edits neither `botopink.json` nor `src/root.bp`, so 09's appends do not wait on it
**Does not touch:** 09's files · `rakun-tx`, `rakun-scheduling` (15's) · `rakun-devtools`

---

## Carried from 1.0.10

| Id | From (`specs/1.0.10-beta/03-rakun/`) | Box, as written |
|---|---|---|
| R08-1 | `08-rakun-data-sql/README.md` § Step 3 — The pool | "`bootstrap-mode=lazy` additionally excludes every `#[repository]` from front 06's eager pass" |
| R08-2 | same § Definition of done | "Named parameters, `#[query]`, the pool and local transactions all behave as the acceptance lists" — ticks when R08-1 lands |
| R77-1 | `77-rakun-db-migrations/README.md` § Step 2 — the history table and the lock | "A node holding the lock that dies releases it — for the advisory-lock arm, by session end; for the `global` arm, by the lock owner's exit — open: … there is no advisory-lock arm — every driver takes the `global` lock, and a standalone node warns that it is node-local" |
| R78-1 | `78-rakun-orm-entities/README.md` § Step 2 — the name grammar and its comptime check | "`findByCiudad` is a compile error naming the entity and listing its fields — open: the build fails at the emitted `CityCol().ciudad` read, naming `CityColumns` and `ciudad` …, but a decorator cannot reflect another type's fields, so the message does not list them" |
| R78-2 | same § Step 5 — relations | "Nothing is fetched that the method did not name — a test asserts the statement count for a fetch of 100 joined rows is 1 — open: the ETS arm has no JOIN, so a 100-row joined fetch cannot run in the suite; the statement is one (asserted as a literal) and nothing else is issued" |

## Problem

`bootstrap-mode=lazy` is read (`sql_datasource_test.bp`) but does not reach the eager pass, so a
repository is still constructed at boot under lazy mode. The migration lock has one arm. The ORM's
unknown-field refusal does not list the fields, and the join count is asserted on a literal.

## Current state

`modules/rakun-data`: 9 test files, 128 tests green on erlang (`sql_*`, `migration_test`,
`orm_test`, `orm_build_test`). Arms: `ets:memory` (the test arm), PostgreSQL and MySQL by URL scheme
(`sql_datasource_test.bp:57-58`) over sidecar wires that no test exercises (no server in the gate).
`rakun_migration.erl`'s `global` lock is tested ("the lock holder's death releases the lock").

## Mechanism

- R08-1: the eager pass is 04's `bootSequenceFor`; it takes a predicate of names to skip. This front
  registers `#[repository]` names under `rakun.data.bootstrap-mode=lazy` through the existing
  `rkOnReset`-style hook (`rkExcludeFromEager(name)`), which 04 already exposes for lazy scopes.
- R77-1: the advisory arm is `pg_advisory_lock` on PostgreSQL; the ETS arm cannot run it. Two
  readings: (a) write the arm in `rakun_migration.erl` behind the `postgresql` scheme with a unit test
  of the SQL it issues (no server), and narrow the box to "issues `pg_advisory_lock`/`_unlock` on the
  PostgreSQL arm; the `global` arm on the others"; (b) narrow the box to the `global` arm only. This
  front takes (a): the SQL text is assertable without a server, and a node-local lock on a
  multi-node PostgreSQL deployment is the wrong default.
- R78-1: the decorator that emits `CityCol()` reads its own entity's `@Decl`, so the field list is
  in reach at the emission site; the refusal happens later, at the emitted read. Emitting a comptime
  `decl.fail` at the decorator with the list — when the method name's suffix matches no field — closes
  the box without lg2-e/f if the *same* decorator sees both the entity and the repository; it does
  not (the repository is another type). The nearest form: the repository decorator receives the
  entity's column list as an argument (`#[repository(CityMeta)]` is refused by lg2-f — a type
  argument; `#[repository("City")]` is a string the decorator cannot resolve). So: the box stays
  blocked on lg2-e/f, and this front records the measured refusal text and ticks nothing.
- R78-2: the ETS arm has no JOIN; the PostgreSQL arm does but has no server here. The box's
  substance — "nothing is fetched that the method did not name" — is assertable by statement count on
  the ETS arm over a 100-row single-table fetch plus the join's SQL text. The front rewords the box to
  that and asserts it.

## Gate stance

No env-gated cell. The PostgreSQL and MySQL arms are wire code with no server in the gate; their
SQL texts are asserted, their sockets are not — that stays, and is not a skip: no cell claims to
have reached a server.

## Steps

### Step 1 — Lazy bootstrap (R08-1, R08-2)

**Acceptance:**
- [ ] `sql_pool_test.bp`: with `rakun.data.bootstrap-mode=lazy`, a `#[repository]` whose constructor records is not constructed by `Rakun.run` and is constructed on its first `resolve`
- [ ] with the default (`eager`) it is constructed before `Rakun.run` returns
- [ ] R08-2 ticked, with the four acceptance lists re-run

### Step 2 — Migration lock (R77-1)

**Acceptance:**
- [ ] `migration_test.bp`: under the `postgresql` scheme the lock arm issues `SELECT pg_advisory_lock(<key>)` before the first migration and `pg_advisory_unlock` after the last, asserted on the recorded statement list (the recording datasource, no server)
- [ ] under `ets:memory` and `mysql` the `global` arm is taken and the standalone-node warning is emitted once
- [ ] the README of the member states the two arms and which schemes take which

### Step 3 — ORM (R78-1, R78-2)

**Acceptance:**
- [ ] `orm_test.bp`: a 100-row fetch through a derived finder issues exactly one statement (recorded), and the join finder's SQL text names exactly the two tables and the join column
- [ ] R78-2 reworded to the statement-count-and-text assertion; the "100 joined rows on a real arm" half is a `deferred.md` row
- [ ] R78-1: the measured refusal text is recorded in the README; the box stays open, blocked on lg2-e/f, with the nearest form named
- [ ] RX-2 for 78: the decorator-argument default case re-measured in `orm_build_test.bp`

## Gate

- [ ] `botopink test --target erlang` green in `modules/rakun-data`
- [ ] `botopink format --check` clean
- [ ] `AGENTS.md` § Data updated in the same commit
- [ ] commit on `fix/08-rakun-data-sql`

## Blast radius

Step 1 changes when a repository is constructed under lazy mode only; `rakun-session`'s SQL store,
`rakun-scheduling`'s job store and `rakun-tx` construct their repositories eagerly by default and are
unaffected. Step 2 adds statements on the PostgreSQL arm only.

## Notes

- `examples/city-entity-example.bp` and `examples/audit-and-revisions-example.bp` are copied here
  for their open `// LANGUAGE GAP:` markers (lg2-r, the self-field rule by design).
- 03r-v (`Op` enum) is implemented; confirmation only.

# Front 77 — rakun Database Migrations

**Track:** B rakun
**Priority:** high — front 08 can talk to a database and nothing can change its schema; every deploy would be a manual `psql` session, and the `flyway`/`liquibase` rows in the actuator's endpoint list have nothing behind them
**Target:** erlang (server)
**Wave:** 4
**Depends on:** 03 · 08 · 72 — and front 11 serves the endpoint it registers
**Owns:** `modules/rakun-data/src/migration/**` · `modules/rakun-data/test/migration/**`
**Does not touch:** `modules/rakun-data/src/datasource.bp` and `src/sql/**` — front 08's, consumed read-only · `modules/rakun-data/src/orm/**` — front 78's, consumed read-only for the schema generator · `modules/rakun-data/src/nosql/**` — front 09's
**Reference:** `09-actuator.md § Endpoints (flyway, liquibase)` · `05-data.md § Configuracao JPA` (`ddl-auto`, the mechanism this front replaces) · `11-topicos-avancados.md § Auto-configuration Classes` · <https://docs.spring.io/spring-boot/reference/howto/data-initialization.html#howto.data-initialization.migration-tool>

---

## Problem

Front 08 gives a `DataSource`, a pool, a `SqlTemplate` and transactions. It does not give the database a
shape. Every table those statements read has to exist already, and nothing in the milestone creates
one. The gap is not "rakun lacks a feature" — it is that a rakun application cannot be deployed twice:
the first deploy needs a schema somebody built by hand, and the second needs the same person to
remember what changed.

Upstream this is so much assumed that the reference barely discusses it: Flyway and Liquibase appear
only as two rows in the actuator's endpoint table (`09 § Endpoints`) and as two entries in the
auto-configuration class list (`11 § Auto-configuration Classes`). The one schema mechanism the
reference does describe in prose is `spring.jpa.hibernate.ddl-auto` (`05 § Configuracao JPA`), and its
own values give the game away: `create-drop` destroys the database on shutdown, `update` guesses. It is
a development convenience, and the production answer is versioned migrations.

There is a third thing, specific to this runtime, that makes the front non-optional rather than
merely important. On the BEAM a deploy is often N nodes starting at once. Every one of them will run
the migrations. Without a lock, N nodes execute `ALTER TABLE` concurrently and the outcome depends on
the database's own locking, which for some statements means one node succeeds and the rest crash at
boot.

## Current state

| Piece | Where it is today |
|---|---|
| `DataSource`, pool, `SqlTemplate`, `Param`, `transaction<T>` | front 08, `modules/rakun-data/src/sql/**` |
| Any schema management | none |
| Any schema history | none |
| Filesystem reads | `libs/std/src/fs.bp` — `readText` (`:33`), `list` (`:61`), `exists` (`:53`) |
| Content hashing | front 03, `hash.contentHash` (decision 106) |
| Entity metadata to generate a schema from | front 78 |
| `flyway`/`liquibase` actuator endpoints | listed upstream; nothing behind them |
| Cluster coordination | nothing; front 04's supervision tree is per node |

## Mechanism

### The file convention

Migrations live in `db/migration/` under the application root, discovered with `fs.list` at boot.
Two name shapes, both Flyway's, because they are the ones people already recognise:

```
V<version>__<description>.sql     versioned — applied once, in version order
R__<description>.sql              repeatable — re-applied whenever its checksum changes
```

`<version>` is dot- or underscore-separated numeric (`1`, `1.2`, `2026_09_19_1430`), compared
component-wise as integers so `V10` sorts after `V9` — a lexicographic sort here is the classic way a
migration set silently applies out of order. A file whose name does not match either shape is a boot
failure naming the file, not a file that is skipped: a migration nobody runs because it was misnamed is
the worst outcome available.

`rakun.migration.locations` overrides the directory. Multiple locations are a comma-separated list, and
two files declaring the same version in different locations is a boot failure naming both.

### The history table

```sql
create table rakun_schema_history (
  installed_rank integer not null primary key,
  version        varchar(50),          -- null for a repeatable migration
  description    varchar(200) not null,
  script         varchar(1000) not null,
  checksum       varchar(64) not null,
  installed_by   varchar(100) not null,
  installed_on   timestamp not null,
  execution_time integer not null,
  success        boolean not null
)
```

The table is created by the migrator itself, inside the same lock, before anything else runs.
`checksum` is front 03's content hash of the file's bytes — not a line count, not an mtime, because both
of those change for reasons that are not a change.

### The surface

```bp
pub type Migration(
    version: string,          // "" for a repeatable migration
    description: string,
    script: string,
    checksum: string,         // 64 hex characters, front 03's content hash
    installedRank: i32,       // 0 while pending
    installedOn: string,      // ISO-8601; "" while pending
    executionMillis: i32,     // 0 - 1 while pending
    success: bool,
)

pub type MigrationReport(
    applied: i32,
    skipped: i32,
    failed: i32,
    lockWaitMillis: i32,
)

pub fn migrate() -> MigrationReport;                              // raises on failure
#[@result]
pub fn tryMigrate() -> @Result<MigrationReport, string>;
pub fn pendingMigrations() -> Migration[];                        // in the order they will run
pub fn appliedMigrations() -> Migration[];                        // in installed_rank order
pub fn migrationReport() -> string;                               // front 11's endpoint body
```

`migrate` raises and `tryMigrate` returns a `@Result` because a function cannot forward a `@Result`
value ([`language-gaps.md`](../../language-gaps.md)); this is the same doubled surface front 08 ships for
`query`/`tryQuery`, and it is doubled for the same reason rather than by preference.

### Checksum validation, and why it is an error

At every boot, for every migration already recorded as applied, the file's current checksum is compared
with the recorded one. A difference is a **boot failure** naming the script, the recorded checksum and
the current one. It is not a warning and there is no property that downgrades it.

The reason is worth stating because the rule looks harsh in a development loop. A migration that has
run has already changed the database; editing its text does not un-run it. If the edit is accepted
silently, two environments that ran different text now report the same version, and the divergence is
invisible until something that depends on it breaks. The correct response to "I need to change an
applied migration" is a new migration, and `rakun.migration.repair` — an explicit, one-shot operation,
never a boot-time setting — is how a genuinely mistaken row is rewritten.

### The cluster lock

Before reading the history table, the migrator takes a lock, and it keeps it until the last migration
commits.

- **Where the driver has advisory locks, use them.** PostgreSQL's `pg_advisory_lock(key)` on a key
  derived from the history table name is the right primitive: it is held by the session, released
  automatically if the node dies, and it is visible to every node regardless of how they reach the
  database.
- **Where it does not, use `global:trans/2`.** OTP's `global` module gives a cluster-wide lock across
  connected nodes with no database support at all. It is correct only when every node is in the same
  cluster, which is the ordinary rakun deployment and is not the universal case.
- A driver with neither, in a deployment with no cluster, runs unlocked and **says so at boot**, once,
  naming the driver. Silent single-node behaviour that happens to work until the second replica is
  added is the failure mode this line exists to prevent.

A node that cannot take the lock within `rakun.migration.lock-timeout` (default 30000 ms) fails to
boot rather than proceeding. A node that waits and then finds every migration already applied — the
normal case for replicas two through N — proceeds immediately.

### The run

Each versioned migration runs inside its own transaction through front 08's `SqlTemplate.transaction`,
and the history row is written in the same transaction as the migration it records. That is the only
arrangement in which "applied" and "recorded" cannot disagree. A statement that a database cannot run
transactionally — `CREATE INDEX CONCURRENTLY` on PostgreSQL is the usual one — is opted out per file
with a `-- rakun:no-transaction` first line, and its history row is written immediately after, with
`success` false until it completes.

A failed migration stops the run: later migrations are not attempted, the failure is recorded with
`success=false`, and the node fails to boot. Booting with a half-applied schema is how an outage becomes
a data-loss incident.

### Modes

| Property | Values | Default | Effect |
|---|---|---|---|
| `rakun.migration.enabled` | bool | `true` when `db/migration` exists | Run at boot |
| `rakun.migration.validate-on-migrate` | bool | `true` | Checksum check before the run |
| `rakun.migration.baseline-on-migrate` | bool | `false` | Adopt an existing database |
| `rakun.migration.baseline-version` | version | `1` | Everything at or below is marked applied without running |
| `rakun.migration.dry-run` | bool | `false` | Report the plan, change nothing, and **exit non-zero if there is anything pending** |
| `rakun.migration.out-of-order` | bool | `false` | Permit a lower version to be applied after a higher one |

`dry-run` exiting non-zero when there is pending work is what makes it usable as a CI gate: "does this
deploy change the schema" is a yes/no question a pipeline can branch on.

### The actuator endpoint

Registered with front 11 as `migrations`, not as `flyway` or `liquibase`. Naming an endpoint after a
tool that is not present would make its output unreadable to the one person most likely to read it —
someone who knows what `/actuator/flyway` returns in Spring and would be handed something else. The
body lists applied, pending and failed migrations with version, description, checksum, install time and
execution time, and it is default-denied by front 76 like every other endpoint.

### `ddl-auto`, and where it is refused

Front 78 knows every entity's table, columns and types, so the schema can be generated from them. That
is `spring.jpa.hibernate.ddl-auto`, and it is genuinely useful for a test run and for the first hour of
a project.

`rakun.migration.ddl-auto` ∈ `none | validate | create | create-drop`, default `none`.

- `validate` compares the live schema against front 78's entity metadata and fails the boot on a
  mismatch, naming the table and the column. This one is safe everywhere and is the only value worth
  setting outside development.
- `create` drops and recreates every entity's table at boot.
- `create-drop` does that and drops them again at shutdown.

**`create` and `create-drop` are refused under a production profile.** If any active profile appears in
`rakun.migration.production-profiles` (default `prod,production`), a configured `create` or
`create-drop` is a **boot failure** naming the profile, the property and the value. It is not demoted
to `validate`, not warned about, and **there is no property that lifts the refusal** — a flag that
re-enables "drop every table" in production is precisely the flag that gets set in an incident and
forgotten. An operator who genuinely wants to rebuild a production schema removes the profile, which is
a deliberate act with a paper trail.

`ddl-auto` and versioned migrations are mutually exclusive in the same direction: with `create` or
`create-drop` set and migration files present, the boot fails naming both, because "which one owns the
schema" has no good default answer.

## Steps

### Step 1 — discovery and ordering

**Acceptance:**
- [ ] `V1__init.sql`, `V1.1__add_index.sql`, `V2__seed.sql`, `R__views.sql` are discovered and ordered `1`, `1.1`, `2`, then repeatables
- [ ] `V10__x.sql` sorts after `V9__x.sql` — the comparison is component-wise integer, not lexicographic
- [ ] A file named `init.sql` is a boot failure naming the file and the two accepted shapes
- [ ] Two files declaring version `2` fail at boot naming both paths
- [ ] `locations` with two directories merges them and still detects a duplicate version across them
- [ ] An empty or absent migration directory with `enabled` unset disables the front silently; with `enabled=true` it is a boot failure

### Step 2 — the history table and the lock

**Acceptance:**
- [ ] The history table is created inside the lock, so N nodes booting together create it once
- [ ] Two nodes started simultaneously against an empty database apply each migration exactly once — asserted with real concurrent processes, which is cheap on this runtime
- [ ] A node that cannot take the lock within `lock-timeout` fails to boot naming the timeout
- [ ] A node holding the lock that dies releases it — for the advisory-lock arm, by session end; for the `global` arm, by the lock owner's exit
- [ ] A driver with no advisory lock and no cluster logs the unlocked warning exactly once, naming the driver
- [ ] Replicas that find everything applied proceed without waiting for the full timeout

### Step 3 — applying, transactionally

**Acceptance:**
- [ ] A migration and its history row commit together: killing the node between them leaves neither
- [ ] A failing migration records `success=false`, stops the run, and fails the boot
- [ ] A later migration is not attempted after a failure
- [ ] `-- rakun:no-transaction` runs the file outside a transaction and still records a row
- [ ] `execution_time` is recorded in milliseconds and is non-zero for a migration that does real work
- [ ] `installed_rank` is contiguous and ascending across a run

### Step 4 — validation and repeatables

**Acceptance:**
- [ ] Editing an applied migration fails the next boot naming the script and both checksums
- [ ] No property downgrades that failure; a test enumerates the keys this front reads and asserts none of them does
- [ ] A repeatable migration re-runs when its checksum changes and does not when it has not
- [ ] Repeatables run after all pending versioned migrations, in filename order
- [ ] `validate-on-migrate=false` skips the check and is documented as a development-only setting
- [ ] `repair` rewrites the checksum of a named script and records that it did, and is reachable only as an explicit operation

### Step 5 — baseline, out-of-order and dry-run

**Acceptance:**
- [ ] `baseline-on-migrate=true` with `baseline-version=3` against a populated database marks 1–3 applied without running them and runs 4 onward
- [ ] Baseline against an empty database is a boot failure — baselining nothing is always a mistake
- [ ] `out-of-order=false` fails when a version lower than the highest applied appears; `true` applies it and records the true order in `installed_rank`
- [ ] `dry-run=true` changes nothing, prints the plan, and exits non-zero when anything is pending
- [ ] `dry-run=true` with nothing pending exits zero
- [ ] A dry run takes and releases the lock, so it cannot report a plan that another node is concurrently invalidating

### Step 6 — the actuator endpoint

**Acceptance:**
- [ ] `/actuator/migrations` lists applied, pending and failed, each with version, description, checksum, installed-on and execution time
- [ ] The endpoint is default-denied and requires front 76's explicit exposure
- [ ] Checksums are shown in full — they are not secrets and truncating them makes them useless for comparison
- [ ] The endpoint reads the history table, not an in-memory copy, so it is correct after another node migrated

### Step 7 — `ddl-auto` and the production refusal

**Acceptance:**
- [ ] `ddl-auto=validate` fails the boot naming the table and column when an entity and the live schema disagree
- [ ] `ddl-auto=create` with active profile `dev` recreates every entity table
- [ ] `ddl-auto=create` with active profile `prod` is a **boot failure** naming the profile, the property and the value
- [ ] `ddl-auto=create-drop` with `production-profiles=staging` and active profile `staging` is refused the same way
- [ ] No property lifts the refusal; a test enumerates this front's configuration keys and asserts that none of them does
- [ ] `ddl-auto=create` with migration files present is a boot failure naming both, whatever the profile
- [ ] `ddl-auto=validate` is permitted under a production profile, and is the value the documentation recommends there

## Examples

- [`examples/migration-run-example.bp`](./examples/migration-run-example.bp) — a two-migration
  application: what is discovered, in what order, what the history table holds afterwards, and what
  the endpoint reports.
- [`examples/checksum-and-ddl-guard-example.bp`](./examples/checksum-and-ddl-guard-example.bp) — the
  three refusals: an edited applied migration, `ddl-auto=create` under `prod`, and `ddl-auto` alongside
  migration files.

## Language gaps

None new — every construct in the examples parses today. Three rows already in
[`language-gaps.md`](../../language-gaps.md) shape this front and are not restated here:

- *A function cannot forward a `@Result`* — so `migrate()` raises and `tryMigrate()` returns
  `@Result<MigrationReport, string>`, the same doubled surface front 08 ships for `query`/`tryQuery`
  and for the same reason.
- *No bodyless method in a `type` body* — not hit here; this front has no generated methods.
- *`xs[0]` silently drops the index on the BEAM backend* — the version comparator walks components with
  `.at(i)` and `.slice(…)` throughout, never an index expression.

## Test plan

`modules/rakun-data/test/migration/` — `discovery_test.bp`, `apply_test.bp`, `validate_test.bp`,
`lock_test.bp`, `ddl_guard_test.bp` — run with `botopink test --target erlang` from
`modules/rakun-data/` and in the gate through `zig build test-libs -- --target erlang`.

**Every test runs against front 08's ETS arm**, which is the same rule front 08 set: a gate that needs
PostgreSQL is a gate that is red on somebody's laptop. The ETS arm has to answer enough SQL for the
history table and for the migrations the tests write, which is a bounded set that the test files
themselves define. The advisory-lock arm is therefore covered by the `global:trans/2` path in the gate
and by a manual check against a real PostgreSQL, recorded in the module's README — stated plainly
rather than implied by a green run.

Migration files for the tests are written into a scratch directory at test setup and deleted after, not
committed, so the discovery tests can assert on malformed names without a permanently broken-looking
fixture in the tree.

This front is erlang-only. `global:trans/2`, the driver connections and the filesystem reads have no
Node form in this module's manifest.

## Definition of done

- Versioned and repeatable migrations are discovered, ordered correctly for two-digit versions, and
  applied exactly once across N concurrently booting nodes
- A migration and its history row commit together
- An edited applied migration fails the boot, and nothing downgrades that
- `dry-run` is usable as a CI gate: it changes nothing and its exit status answers "is anything pending"
- `/actuator/migrations` reports applied, pending and failed, default-denied
- `ddl-auto=create` and `create-drop` are refused under a production profile, with no property that
  lifts the refusal, asserted by a test that enumerates the configuration keys
- `modules/README.md` records the migration surface in the same commit
- The front's tests are green on its assigned target


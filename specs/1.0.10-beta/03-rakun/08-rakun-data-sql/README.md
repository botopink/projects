# Front 08 — SQL Data Access

**Track:** B rakun
**Priority:** high — `#[repository]` is a stereotype with nothing behind it; every rakun application that needs to persist anything keeps its data in an array
**Target:** erlang (server)
**Wave:** 3
**Depends on:** 06
**Owns:** `modules/rakun-data/src/datasource.bp`, `modules/rakun-data/src/sql/**` · `modules/rakun-data/test/sql/**`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` — frozen · `modules/rakun-data/src/nosql/**`, which is front 09's · `modules/rakun-data/src/migration/**` (77) and `src/orm/**` (78)
**Reference:** `05-data.md § Bancos SQL` — DataSource, Connection Pools, JdbcTemplate, JdbcClient · <https://docs.spring.io/spring-boot/reference/data/sql.html>

---

## Problem

`#[repository]` exists and means nothing. It is byte-for-byte the same decorator as `#[service]`
(`decorators.bp:84-100` against `:66-82`) — scan, singleton factory, placement check — kept distinct
for intent. There is no `DataSource`, no connection, no pool, no statement, no transaction. rakun's
own example repository returns `["ana", "bob", "cleo"]` from a literal
(`examples/rakun/src/users.bp:16-24`), and that is not a simplification for the example: it is the
only thing a rakun repository can do today.

The gap is worth stating precisely because it is not "no ORM". It is no *connection*. A rakun service
cannot open a socket to PostgreSQL, cannot send a parameterized statement, and cannot bracket two
writes so they commit together. The first two are what a repository is; the third is what makes a
write correct when something fails in the middle.

There is a second, quieter problem: the Spring Data shape — bodyless methods inside a `type`
body — does not parse:

```bp
#[query("SELECT * FROM users WHERE id = $1")]
pub fn findById(self: Self, id: i32) -> @Result<?User, string>;
```

— and a method in a `type` body requires a body (`docs.md:183-196`; a bodyless function is a
module-level `declare fn`, `docs.md:565-567`). That is not a detail to fix later; it decides the whole
repository surface, so this front decides it once and front 09 follows.

## Current state

| Piece | Where | State |
|---|---|---|
| `#[repository]` | `decorators.bp:84-100` | a stereotype alias for `#[service]`; frozen |
| Data access | — | none |
| Connection pooling | — | none |
| Transactions | — | none |
| `modules/rakun-data/` | — | the directory does not exist |
| Config binding for `spring.datasource.*` | front 05's `#[configurationProperties]` | available once 05 lands |
| ETS | `libs/std/src/beam.bp:83-95`, and directly from a sidecar | available; the in-VM store is built on it |
| SQL drivers | — | none; `epgsql` and `mysql-otp` are third-party OTP applications, not in the distribution |

That last row constrains the front the same way cowboy constrained front 04. A sidecar `.erl` is
compiled and loaded at run time with no code path beyond the output directory
(`codegen/erlang.zig:1655-1668`), so a driver that is not on the machine is not available and cannot
be made available by this front. The consequence is a design decision, not an inconvenience: see
*Drivers, and what ships in the box*.

## Mechanism

### The repository shape, decided once

A method in a `type` body must have a body. So `#[query]` is a **method-level decorator that emits a
module-level helper**, and the method's body calls it:

```bp
#[repository]
#[managed]
pub type UserRepository(sql: SqlTemplate) {
    #[query("SELECT id, name, email FROM users WHERE id = :id")]
    pub fn findById(self: Self, id: i32) -> Rows {
        return self.sql.query(__rkQuery_findById(), [param("id", id.toString())]);
    }
}
```

`#[query]` emits, at module level:

```bp
pub fn __rkQuery_findById() -> string { return "SELECT id, name, email FROM users WHERE id = :id"; }
val __rkQueryReg_findById = rkRegisterQuery("findById", "SELECT id, name, email FROM users WHERE id = :id");
```

The obvious objection is that the SQL then appears once and is referenced once, so what does the
decorator buy. Three things, and they are the reason the shape is worth keeping over writing the
string inline:

1. **The statement is a declaration, not an expression.** It cannot be built by concatenation, because
   a decorator argument is a literal lexeme. That is the SQL-injection rule enforced by the shape
   rather than by a review comment.
2. **It is registered.** `rkRegisterQuery` gives `/actuator/sql` an inventory of every statement the
   application can issue, and gives front 77's migration linter something to check a schema against.
3. **It is checked at comptime** for the things the decorator can see: an empty statement, a leading
   keyword that is not one of `SELECT`/`INSERT`/`UPDATE`/`DELETE`/`WITH`/`CALL`, and a `'` immediately
   followed by a placeholder sigil (the concatenation smell) each fail the build with a located
   message.

What it cannot check is the placeholder count against the method's parameters, because a method-level
`@Decl` exposes no parameter list — `Param` lives only on the `Method` entries of a *type* decl
(`builtins.d.bp:459-477`). That is a language gap and it is in the table below.

Two methods with the same name in one module collide on `__rkQuery_<name>` and the build fails on a
duplicate definition. That is the right failure and it is documented rather than worked around.

**Front 09 uses the identical shape** with `#[documentQuery]`, for the same reasons and with the same
helper naming. The two decorators are separate only because the conflict rule gives F09 no access to
F08's `src/sql/**`.

### `SqlTemplate` and the fluent client

```bp
pub type Rows(columns: string[], rows: string[][]) {
    pub fn length(self: Self) -> i32;
    pub fn first(self: Self) -> ?Row;
    pub fn at(self: Self, i: i32) -> ?Row;
    pub fn toList(self: Self) -> Row[];
}

pub type Row(columns: string[], values: string[]) {
    pub fn get(self: Self, column: string) -> string;   // "" when absent
    pub fn int(self: Self, column: string) -> i32;
    pub fn bool(self: Self, column: string) -> bool;
}
```

Everything is a string at this layer. Typed row-to-record mapping is front 78's `#[entity]`, and
building a half version of it here would leave two. What this front owns is the wire: a column name,
a value, and coercion helpers on `Row` for the three cases a handler needs before an ORM exists.

```bp
pub type SqlTemplate(dataSourceName: string) {
    pub fn query(self: Self, sql: string, params: Param[]) -> Rows;
    pub fn update(self: Self, sql: string, params: Param[]) -> i32;
    pub fn single(self: Self, sql: string, params: Param[]) -> ?Row;
    pub fn transaction<T>(self: Self, work: fn(tx: Tx) -> T) -> T;

    pub fn tryQuery(self: Self, sql: string, params: Param[]) -> @Result<Rows, string>;
    pub fn tryUpdate(self: Self, sql: string, params: Param[]) -> @Result<i32, string>;
}
```

`query` and `update` **raise** on a driver error, the way `JdbcTemplate` throws, and front 07's error
entry turns the raise into a 500 problem detail. The `try*` pair returns `@Result` for the caller who
wants to branch. Both exist because botopink cannot forward a `@Result` value until front 24 lands decision 119:
inside a `-> @Result<…>` function `return r` wraps `r` again, so a repository that
returned `@Result` would force every caller up the stack to unwrap and re-wrap. The raising form keeps
the common path readable; the `try*` form keeps the branch possible. This is the same gap front 04
recorded and it is why the surface is doubled.

Parameters are named, not positional:

```bp
pub type Param(name: string, value: string)
pub fn param(name: string, value: string) -> Param;
```

`:name` in the statement is rewritten to the driver's own placeholder (`$1` for PostgreSQL, `?` for
MySQL) at execution, in the order the names first appear. Named parameters are Spring's `JdbcClient`
(`05-data.md § JdbcClient`) and they are the default here rather than an alternative, because a
positional list beside a multi-line statement is where the off-by-one lives.

A `:name` with no matching `Param`, or a `Param` no statement mentions, is an error naming both — not
a null bind.

### Pooling on the BEAM: processes, not threads

HikariCP exists because a JDBC connection is bound to a thread and threads are expensive. Neither
premise holds here. The BEAM's answer is a **supervised set of connection processes**:

- `rakun_pool_sup` is a `supervisor` (`one_for_one`) whose children are N connection processes, each
  a `gen_server` owning one socket to the database.
- A caller checks one out of an ETS free-list, uses it, checks it back in. A checkout that finds the
  list empty waits up to `connection-timeout` and then raises.
- A connection process that dies takes its socket with it and is restarted by the supervisor with a
  fresh connection. **There is no "test on borrow"** — the process either exists or it does not, and a
  dead socket kills its process. This is the one place where the BEAM version is simpler than the JVM
  one rather than merely different.
- A caller that dies mid-query does not leak the connection: the pool monitors the borrower and
  reclaims on `DOWN`, rolling back any open transaction.

Pool size is `spring.datasource.pool.size` (rakun spelling: `rakun.datasource.pool.size`), default 10,
with `minimum-idle` meaningless — a process costs a few kilobytes, so the pool is fixed-size and the
README says why the JVM's idle-shrinking knobs are not ported.

**Lazy acquisition**: `SqlTemplate` does not check a connection out until the first statement actually
runs. A request that touches a repository but takes a branch that issues nothing borrows nothing.

### Transactions, and why `#[transactional]` is a proxy

A decorator adds declarations; it cannot rewrite the body of the thing it annotates. Every rakun
decorator in existence emits module-level `val`s and `fn`s and touches no body
(`decorators.bp:48-240`). So `#[transactional]` on a method cannot open a transaction around that
method, and any spec that says it does is describing a compiler that is not this one.

What a **type-level** decorator can do is emit a proxy, which is also what Spring actually does at run
time:

```bp
#[service]
#[transactional]
#[managed]
pub type OrderService(sql: SqlTemplate, orders: OrderRepository) {
    pub fn place(self: Self, userId: i32, total: i32) -> i32 { … }
}
```

emits

```bp
pub type OrderServiceTx(inner: OrderService) {
    pub fn place(self: Self, userId: i32, total: i32) -> i32 {
        return rkTxRun("OrderService.place", "required", { -> self.inner.place(userId, total) });
    }
}
pub fn __rkMake_OrderServiceTx() -> OrderServiceTx {
    return rkSingleton("OrderServiceTx", { -> OrderServiceTx(inner: __rkMake_OrderService()) });
}
```

The decorator has everything it needs: `decl.name`, and `decl.methods` with each method's `params` and
`returnType`. A controller injects `OrderServiceTx` and gets the transactional version; injecting
`OrderService` gets the bare one, which is exactly the distinction Spring hides and this makes
visible. `#[noTransaction]` on a method emits it as a plain forward.

Inside the proxy, `rkTxRun` checks out one connection, marks it in the calling process's dictionary,
runs the thunk, and commits or rolls back on a raise. Every `SqlTemplate` call from that process then
finds the marked connection instead of checking out a second one, so nested calls join the same
transaction — `REQUIRED` propagation, and the only one this front ships. `REQUIRES_NEW` and `NESTED`
(savepoints) are named as absent rather than half-built.

**`sql.transaction({ tx -> … })` is the other form**, and it is the one the examples use for the
multi-statement case, because it makes the boundary visible at the place it matters. The proxy is for
the "every public method of this service is a unit of work" case.

### Drivers, and what ships in the box

Three arms behind one `DataSource` behavior:

| Arm | Selected by | Availability |
|---|---|---|
| **ETS** | `rakun.datasource.url=ets:memory` | always; ships with this front |
| PostgreSQL | `postgresql://…` | requires `epgsql` on the code path |
| MySQL | `mysql://…` | requires `mysql-otp` on the code path |

The ETS arm is a real deliverable and not a mock. It supports the subset a test needs: `CREATE TABLE`,
`INSERT`, `SELECT` with equality predicates and `ORDER BY`, `UPDATE`, `DELETE`, and transactions by
snapshot-and-restore. It is selected automatically when the active profile is `test` and no URL is
configured, which is Spring's embedded-database convenience
(`05-data.md § Banco Embutido`) with an honest scope note: it is not SQL, it is the subset this
front's tests and an application's unit tests use. A statement it cannot parse fails with a message
saying so, rather than returning an empty result set.

A configured PostgreSQL or MySQL URL whose driver module is not loadable is a **boot failure** naming
the driver and the application that supplies it. It does not fall back to ETS: silently running an
integration suite against an in-memory store that lies about SQL is worse than not starting.

### Deferred repository initialization

Spring's `spring.data.jpa.repositories.bootstrap-mode` exists because building repository proxies is
slow on the JVM. On the BEAM a repository is a record and `rkSingleton` is already lazy
(`runtime.mjs:73-78`), so the expensive part is not the repository — it is the **pool**, which opens N
sockets at boot.

`rakun.data.repositories.bootstrap-mode` therefore controls the pool, not the proxies:

| Value | Behaviour |
|---|---|
| `eager` (default) | the pool fills at boot, so an unreachable database fails the boot rather than the first request |
| `deferred` | the pool starts empty and fills on first checkout; boot does not touch the database |
| `lazy` | as `deferred`, and each `#[repository]` is also `#[lazy]` to front 06's eager pass |

`deferred` is what a development loop wants and what a production deploy must not have, so a
`production` profile with `deferred` configured is a boot **warning** naming the profile — not a
failure, because a legitimate blue/green start may precede the database, and not silence, because the
usual reason it is set in production is that someone was debugging a slow boot.

### Futures

Every call has a `@Task`-returning twin: `queryAsync`, `updateAsync`, `singleAsync`. This is the whole of
the R2DBC and reactive story and it costs one extra function each, because on the BEAM a "reactive"
query is a process doing a blocking call. Front 04's README states that position once for the track;
this front is where it becomes surface.

### Health

`#[healthIndicator("db")]`, imported from front 11's dependency-free `rakun-actuator-api` module,
on a component that checks out a connection, runs the driver's liveness
statement and returns it. Registered with front 11, which owns the endpoint. Front 08 ships the
indicator; the indicator list is not front 11's work, and the same rule holds for 09, 12, 15 and 18.

## Steps

### Step 1 — `modules/rakun-data/` and the `DataSource` behavior

**Acceptance:**
- [x] The module compiles with `"target": "erlang"` and its tests run — held: `modules/rakun-data/test/sql_datasource_test.bp` "datasource: rakun.datasource.url selects the arm" (the member's suite: 77 passed / 0 failed / 0 compile failures)
- [x] `DataSource` and `Connection` behaviors are declared — held: `modules/rakun-data/src/datasource.bp` `DataSource` / `Connection` / `PooledDataSource implement DataSource`; `modules/rakun-data/test/sql_datasource_test.bp` "datasource: a started datasource is a DataSource with connect, close and stats"
- [x] `rakun.datasource.url` selects the arm; an unknown scheme fails at boot naming the value — held: `modules/rakun-data/test/sql_datasource_test.bp` "datasource: an unknown scheme fails at boot naming the value"
- [x] A configured driver whose module is not loadable fails at boot naming the driver — it does not fall back — held: `modules/rakun-data/test/sql_datasource_test.bp` "datasource: a PostgreSQL URL whose driver is not loadable fails at boot naming it, with no fallback" · "datasource: a MySQL URL whose driver is not loadable fails at boot naming it, with no fallback"

### Step 2 — The ETS arm

**Acceptance:**
- [x] `CREATE TABLE`, `INSERT`, `SELECT … WHERE col = :p`, `ORDER BY`, `UPDATE`, `DELETE` all work — held: `modules/rakun-data/test/sql_template_test.bp` "ets: SELECT with WHERE col = :p answers the matching rows" · "ets: ORDER BY sorts numbers as numbers, ascending and descending" · "ets: UPDATE changes the matching rows and answers how many" · "ets: DELETE removes the matching rows and answers how many"
- [x] A statement outside the supported subset fails with a message naming the unsupported construct — held: `modules/rakun-data/test/sql_template_test.bp` "ets: a statement outside the subset fails naming the unsupported construct"
- [x] It is selected automatically under the `test` profile with no URL configured — held: `modules/rakun-data/test/sql_datasource_test.bp` "datasource: the ETS arm is selected under the test profile with no URL configured"
- [x] Two test blocks do not see each other's rows — held: `modules/rakun-data/test/sql_template_test.bp` "ets: a test block wrapped in withRollback leaves nothing behind (2 of 2)" (isolation is `SqlTemplate.withRollback`, a transaction that always rolls back)

### Step 3 — The pool

**Acceptance:**
- [x] The configured number of connection processes start under `rakun_pool_sup` — held: `modules/rakun-data/test/sql_pool_test.bp` "pool: the configured number of connection processes start under rakun_pool_sup"
- [x] A checkout with an empty free list waits and then raises after `connection-timeout` — held: `modules/rakun-data/test/sql_pool_test.bp` "pool: a checkout with an empty free list waits and then fails after connection-timeout" · "pool: the raising surface raises when the checkout times out"
- [x] A connection process killed mid-idle is restarted and the pool returns to full size — held: `modules/rakun-data/test/sql_pool_test.bp` "pool: a connection process killed while idle is restarted and the pool returns to full size"
- [x] A borrower that dies mid-query has its connection reclaimed and any open transaction rolled back — held: `modules/rakun-data/test/sql_pool_test.bp` "pool: a borrower that dies mid-query has its connection reclaimed and its transaction rolled back"
- [x] No connection is checked out until the first statement runs — held: `modules/rakun-data/test/sql_pool_test.bp` "pool: no connection is checked out until the first statement runs"
- [x] `rkPoolStats()` reports size, in-use and waiting, and front 11 can read it — held: `modules/rakun-data/test/sql_pool_test.bp` "pool: rkPoolStats reports size, in-use and waiting" (`rkPoolStats()` / `poolStats(name)` in `src/datasource.bp`, a `pub fn` over the `PoolStats` record)
- [x] `bootstrap-mode=eager` (the default) fails the boot when the database is unreachable — held: `modules/rakun-data/test/sql_datasource_test.bp` "bootstrap: eager (the default) fails the boot when the database is unreachable" · "bootstrap: the mode defaults to eager and an unknown mode is refused"
- [x] `bootstrap-mode=deferred` boots with the database down and opens the first connection on the first statement — held: `modules/rakun-data/test/sql_datasource_test.bp` "bootstrap: deferred boots with the database down and opens the first connection on the first statement"
- [ ] `bootstrap-mode=lazy` additionally excludes every `#[repository]` from front 06's eager pass
- [x] `deferred` under a `production` profile logs a warning naming the profile, and still boots — held: `modules/rakun-data/test/sql_datasource_test.bp` "bootstrap: deferred under a production profile logs a warning naming the profile, and still boots"

### Step 4 — `SqlTemplate`, named parameters and `Rows`

**Acceptance:**
- [x] `:name` binds from a `Param` of the same name — held: `modules/rakun-data/test/sql_template_test.bp` "params: :name binds from the Param of the same name, in first-appearance order" · `sql_query_test.bp` "query: a named parameter binds by name and the statement is emitted verbatim"
- [x] The same `:name` used twice binds once and is passed once — held: `modules/rakun-data/test/sql_template_test.bp` "params: the same :name used twice binds once and is passed once" · `sql_query_test.bp` "query: the same name used twice binds once and is passed once"
- [x] A `:name` with no `Param` fails naming the name; an unused `Param` fails naming it too — held: `modules/rakun-data/test/sql_template_test.bp` "params: a :name with no Param fails naming it, and so does an unused Param"
- [x] A parameter value containing `'; DROP TABLE users; --` is bound as a value and changes nothing — held: `modules/rakun-data/test/sql_template_test.bp` "params: a hostile value is bound as a value and changes nothing" · `sql_query_test.bp` "query: a hostile value is bound as a value and changes nothing"
- [x] `single` on an empty result answers `null`, and on two rows fails naming the statement — held: `modules/rakun-data/test/sql_template_test.bp` "template: single answers null on no row and fails naming the statement on two"
- [x] `query` raises on a driver error and `tryQuery` returns `Error(reason)` for the same input — held: `modules/rakun-data/test/sql_template_test.bp` "template: query raises on a driver error and tryQuery answers Error for the same input"
- [x] `Row.int` on a non-numeric column fails naming the column, rather than answering 0 — held: `modules/rakun-data/test/sql_template_test.bp` "rows: Row.int reads a number and fails naming a non-numeric column rather than answering 0"

### Step 5 — `#[query]`

**Acceptance:**
- [x] `#[query("SELECT …")]` emits `__rkQuery_<name>()` returning the statement verbatim — held: `modules/rakun-data/test/sql_query_test.bp` "query: #[query] emits __rkQuery_<name>() returning the statement verbatim"
- [x] It registers the statement, and `rkRegisteredQueries()` lists it — held: `modules/rakun-data/test/sql_query_test.bp` "query: every #[query] statement is registered and rkRegisteredQueries lists it" (registration is a module-body `val`: on erlang it runs for a module whose body runs — see the compiler findings in AGENTS.md)
- [x] An empty statement, an unknown leading keyword, and a `'` adjacent to a placeholder each fail the build with a located message — held: `modules/rakun-data/test/sql_build_test.bp` "build: an empty #[query] statement fails at the method" · "build: an unknown leading keyword fails naming it" · "build: a quote next to a placeholder fails as the concatenation smell"
- [x] `#[query]` on a non-method fails at comptime — held: `modules/rakun-data/test/sql_build_test.bp` "build: #[query] on a type fails at comptime"
- [x] Two methods of the same name in one module fail the build on the duplicate helper — held: `modules/rakun-data/test/sql_build_test.bp` "build: two #[query] methods of one name in one module fail on the duplicate helper" (the refusal is erlc's `function '__rkQuery_<name>'/0 already defined`, so it surfaces where erlc runs — `botopink test` / `run`; `botopink build` does not run erlc and exits 0)

### Step 6 — Transactions

**Acceptance:**
- [x] `sql.transaction({ tx -> … })` commits when the thunk returns — held: `modules/rakun-data/test/sql_query_test.bp` "query: sql.transaction commits when the thunk returns"
- [x] It rolls back when the thunk raises, and the raise propagates — held: `modules/rakun-data/test/sql_query_test.bp` "query: sql.transaction rolls back when the thunk raises, and the raise propagates" · "query: a raise inside the proxy rolls back and the raise propagates"
- [x] Two statements inside one transaction are both visible or neither is — held: `modules/rakun-data/test/sql_query_test.bp` "query: two statements in one transaction are both visible or neither is"
- [x] A nested `transaction` inside an open one joins it — one commit, not two — held: `modules/rakun-data/test/sql_query_test.bp` "query: a nested transaction joins the open one with a single commit" · "query: a nested transaction inside the proxy joins it with a single commit"
- [x] `#[transactional]` on a service emits `<Type>Tx` with one method per public method — held: `modules/rakun-data/test/sql_query_test.bp` "query: a transactional proxy call is wrapped in begin and commit" (every REFLECTED method is forwarded: `Method` carries no visibility, so a private one is forwarded too; a parameter whose type reflection loses is refused — `sql_build_test.bp` "build: a parameter whose type reflection loses is refused naming it")
- [x] Injecting `<Type>Tx` gets the transactional path; injecting `<Type>` gets the bare one — held: `modules/rakun-data/test/sql_query_test.bp` "query: injecting the Tx proxy gets the transaction and injecting the bare type does not"
- [x] `#[noTransaction]` on one method emits a plain forward — held: `modules/rakun-data/test/sql_query_test.bp` "query: noTransaction emits a plain forward"
- [x] `#[transactional]` on an enum-shaped `type` fails at comptime — held: `modules/rakun-data/test/sql_build_test.bp` "build: #[transactional] on an enum-shaped type fails at comptime"
- [x] `REQUIRES_NEW` and `NESTED` are rejected with a message saying they are not implemented — not accepted and ignored — held: `modules/rakun-data/test/sql_build_test.bp` "build: REQUIRES_NEW is refused as not implemented" · "build: NESTED is refused as not implemented" · `sql_query_test.bp` "query: REQUIRES_NEW and NESTED are refused at run time too, never ignored" (the method marker is `#[propagation("…")]`)

### Step 7 — Futures and health

**Acceptance:**
- [x] `await sql.queryAsync(…)` returns the same rows as `sql.query(…)` — held: `modules/rakun-data/test/sql_template_test.bp` "async: await queryAsync answers the same rows as query"
- [x] A raise inside an async query surfaces at the `await` — held: `modules/rakun-data/test/sql_template_test.bp` "async: a raise inside an async query surfaces at the await"
- [x] Two async queries from one request run concurrently and both complete — held: `modules/rakun-data/test/sql_template_test.bp` "async: two async queries from one request run concurrently and both complete"
- [x] `#[healthIndicator("db")]` answers `UP` with a reachable database and `DOWN` with the reason otherwise — held: `modules/rakun-data/test/sql_health_test.bp` "health: db answers UP with the arm and the liveness statement when the database is reachable" · "health: db answers DOWN with the reason when the database is unreachable"
- [x] The indicator appears in front 11's health report without front 11 knowing about SQL — held: `modules/rakun-data/test/sql_health_test.bp` "health: the db indicator is registered with the actuator contract without the host knowing SQL" (through `registerDbHealth()`: the decorator's module-body registration does not run for a library module on erlang — compiler finding in AGENTS.md)

## Examples

- [`examples/user-orders-example.bp`](./examples/user-orders-example.bp) — one realistic domain
  carried the whole way: a `users` and `orders` schema, two `#[repository]` types with `#[query]`
  statements, a `#[transactional]` service that places an order and writes an audit row in one unit
  of work, and the REST controller that exposes it.

## Language gaps

The milestone register is [`language-gaps.md`](../../language-gaps.md); the rows below are this front's entries in it, and the cross-front wire formats they touch are in [`contracts.md`](../../contracts.md).

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| A bodyless method in a `type` body does not parse (`docs.md:183-196`), so `#[query("…")] pub fn findById(…);` — the shape every Spring Data tutorial uses — is not writable. | `examples/user-orders-example.bp`, every repository method | A real body calling the emitted `__rkQuery_<name>()` helper | Abstract methods in a `type` body, filled in by the decorator's emission. This is the single change that would make the repository surface read like its upstream |
| A method-level `@Decl` exposes no parameter list, so `#[query]` cannot check its placeholders against the method's parameters. | same file — the check is documented as absent | Check only what the statement text shows | `decl.params` on a `DeclKind.Method` handle (also front 06's gap) |
| A decorator cannot rewrite the body it annotates (`decorators.bp:48-240`), so `#[transactional]` cannot open a transaction around the annotated method. | `examples/user-orders-example.bp`, `#[transactional]` on `OrderService` emitting `OrderServiceTx` | A type-level decorator emitting a proxy type, and injecting the proxy | `decl.wrapBody(expr)`, or a body-rewriting emission. Shared with fronts 06, 07 and 10 |
| A function cannot forward a `@Result` value: inside a `-> @Result<…>` fn `return r` re-wraps (until front 24 lands decision 119's pass-through). Every layer would have to unwrap and re-wrap. | `examples/user-orders-example.bp` — the repositories use the raising `query`, not `tryQuery` | Two surfaces: a raising form and a `try*` form | A forwarding return, or letting `return` pass an already-`@Result` value through unchanged |

## Test plan

`modules/rakun-data/test/sql/` — `template_test.bp`, `pool_test.bp`, `transaction_test.bp`,
`query_decorator_test.bp` — run with `botopink test --target erlang` from `modules/rakun-data/` and in
the gate through `zig build test-libs -- --target erlang`. The manifest declares `"target": "erlang"`,
so the commonJS cell reports *skipped*.

**Every test runs against the ETS arm.** No test in this front requires PostgreSQL or MySQL, because a
gate that needs a database is a gate that is red on somebody's laptop. The driver arms are covered by
a separate, opt-in suite gated on `RAKUN_TEST_PG_URL` / `RAKUN_TEST_MYSQL_URL` being set; with the
variable unset the suite reports *skipped* and says so in one line rather than passing vacuously. The
one thing the opt-in suite must assert that the ETS arm cannot is the placeholder rewriting — `:name`
to `$1` and to `?` — so that test is written twice, once per dialect.

The pool tests are the ones worth care: "a borrower that dies reclaims its connection" is asserted by
spawning a process that checks out and then exits, and observing the pool return to full size, not by
reading a counter the pool maintains for the test's benefit.

## Adjacent fronts

- **77-rakun-db-migrations** owns schema change, the history table and the boot-time lock. Front 08
  creates no schema and ships no `ddl-auto`.
- **78-rakun-orm-entities** owns `#[entity]`, derived query methods, `Page`/`Sort` and typed row
  mapping. Front 08 stops at `Row.get(column)`.
- **83-rakun-distributed-transactions** owns the outbox, sagas and anything spanning two resources.
  Front 08's transaction is local to one connection, and says so.
- **11-rakun-actuator** hosts the health endpoint; this front ships the `db` indicator and the pool
  metrics.
- The bundled library `validation` (formerly front 14's `rakun-validation`) is what turns a
  constraint violation into a 422 before a statement runs.
- **09-rakun-data-nosql** shares the module directory and consumes `datasource.bp` read-only.

## Contradictions with fronts.md

1. **Resolved:** `modules/rakun-data/botopink.json` and `src/root.bp` belong to **F08**, the
   lowest-numbered front in that module. F09, F77 and F78 append their `pub mod` lines in
   front-number order; none creates a second manifest.
2. The ownership row does not name a sidecar; the pool and the driver arms live in
   `modules/rakun-data/src/sidecars/rakun_sql.erl`, which must be allocated or the front cannot ship.
3. F09's row says it consumes `datasource.bp` read-only, which works only if `DataSource` is generic
   over SQL and document stores. This front declares it that way — `connect`, `close`, `stats` — and
   leaves the statement surface to each arm.

## Definition of done

- [x] `modules/rakun-data/` exists with a manifest, a root module, `datasource.bp`, `src/sql/**` and
      the sidecar — held: `modules/rakun-data/botopink.json`, `src/root.bp`, `src/datasource.bp`, `src/sql/{mod,params,rows,template,query,transactional,health}.bp`, `src/sidecars/rakun_sql.erl`
- [x] The ETS arm passes the whole suite with no external service — held: `modules/rakun-data/test/*` — 77 passed / 0 failed / 0 compile failures, no database
- [x] A configured-but-unloadable driver fails at boot instead of falling back — held: `modules/rakun-data/test/sql_datasource_test.bp` "datasource: the boot reads rakun.datasource.* and refuses a configured driver it cannot load"
- [ ] Named parameters, `#[query]`, the pool and local transactions all behave as the acceptance lists
      state
- [x] `#[transactional]` emits a proxy, and both the proxy and the bare type are injectable — held: `modules/rakun-data/test/sql_query_test.bp` "query: injecting the Tx proxy gets the transaction and injecting the bare type does not"
- [x] `REQUIRES_NEW` and `NESTED` are rejected rather than ignored — held: `modules/rakun-data/test/sql_build_test.bp` "build: REQUIRES_NEW is refused as not implemented"
- [x] The `db` health indicator registers with front 11 — held: `modules/rakun-data/test/sql_health_test.bp` "health: the db indicator is registered with the actuator contract without the host knowing SQL"
- [ ] `repository/rakun/AGENTS.md` documents the repository shape decided here, and front 09 follows it
- [x] The front's tests are green on its assigned target — held: `botopink test` in `modules/rakun-data/` (erlang) — 77 passed / 0 failed / 0 compile failures

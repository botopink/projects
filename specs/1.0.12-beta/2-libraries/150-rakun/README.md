# Front 150 — rakun: the 16 members' fronts, middleware and typed actions

**Priority:** high — the library tier (decision 433); runs after the 144 steps it names.
**Owns:** `repository/rakun/**` (the tree 128 left; `04-rakun/README.md` § Where a merged member's front works)
**Depends on:** 144 B-11 (318 wrappers, 12 s5), B-12 (13, 15, 22, 91, 92, 93), B-13 (08 s6, 09 s6, 65 s4), B-17, B-19 (281 sites, 130 s5); decision 299 config records; pending 03r-ab, 03r-ae, 03r-af, 03r-ak, 03r-al, 03r-am, 03r-an, erk-b, lg2-b, 04-a
**Does not touch:** `repository/botopink-lang/**` — a compiler or std gap is a `language-gaps.md` row and this
front pauses on the 144 step that fixes it (fronts.md rules 1, 9); another library's files except a consumer
commit (decision 188), producer first.
**Gate:** standard (fronts.md § Gate); a moved block keeps its own `**Gate:**` additions.

Group A (04, 74, 08, 15, 79, 81, 93, 73, 19 s1) → group B (13, 12, 22, 17, 11, 65, 09, 91, 92) → group C (88,
19 s2–7) → 123 → 127 (`04-rakun/README.md` § Parallel groups; fronts.md § Execution order). Inside the repository the
old fronts' rules hold: 04 s1 gates 13 and 12, 04 s4 gates 08 s1, 19 s2–5 and 88, 04 s5 gates 22, 19 s1 gates
12 and 09, 15 gates 91 and 92, 74 gates 92. Consumer commits it receives: B-02, B-08 (121), B-11, B-19, B-20
(129's imports), 142 (json, yaml), 143 s3 (dbcontext), 104 s5 (http). The rakun-websocket handshake row
(register the session before answering 101, status.md L2) is the rakun-websocket member's hygiene, taken with group B.

## Alias table

Old ids stay valid in `decisions-taken.md`'s *Where* column, `language-gaps.md`'s owners and the
closed records: each resolves here. A "box n" counts the old step's open boxes, in order.

| Old id | Step here |
|---|---|
| `04-rakun-erlang-runtime` s2 | 150 s1 |
| `04-rakun-erlang-runtime` s3 | 150 s1 |
| `04-rakun-erlang-runtime` s4 | 150 s1 |
| `04-rakun-erlang-runtime` s5 | 150 s1 |
| `04-rakun-erlang-runtime` s6 | 150 s1 |
| `04-rakun-erlang-runtime` s7 | 150 s1 |
| `04-rakun-erlang-runtime` s8 | 150 s1 |
| `103-actions-id` open | 150 s2 |
| `02-erlang` rows box 2 | 150 s2 |
| `97-std-dedupe` s2 residue box 2 | 150 s2 |
| `17-beam-memory` s2 box 3 | 150 s2 |
| `74-rakun-tls-ssl-bundles` s1 | 150 s3 |
| `74-rakun-tls-ssl-bundles` s2 | 150 s3 |
| `08-rakun-data-sql` s1 | 150 s4 |
| `08-rakun-data-sql` s2 | 150 s4 |
| `08-rakun-data-sql` s3 | 150 s4 |
| `08-rakun-data-sql` s4 | 150 s4 |
| `08-rakun-data-sql` s5 | 150 s4 |
| `08-rakun-data-sql` s6 | 150 s4 |
| `08-rakun-data-sql` s7 | 150 s4 |
| `15-rakun-messaging` s1 | 150 s5 |
| `15-rakun-messaging` s2 | 150 s5 |
| `15-rakun-messaging` s3 | 150 s5 |
| `15-rakun-messaging` s4 | 150 s5 |
| `15-rakun-messaging` s5 | 150 s5 |
| `15-rakun-messaging` s6 | 150 s5 |
| `15-rakun-messaging` s7 | 150 s5 |
| `15-rakun-messaging` s8 | 150 s5 |
| `79-rakun-oauth2-sso` s1 | 150 s6 |
| `79-rakun-oauth2-sso` s2 | 150 s6 |
| `79-rakun-oauth2-sso` s3 | 150 s6 |
| `79-rakun-oauth2-sso` s4 | 150 s6 |
| `81-rakun-packaging-release` s1 | 150 s7 |
| `81-rakun-packaging-release` s2 | 150 s7 |
| `81-rakun-packaging-release` s3 | 150 s7 |
| `81-rakun-packaging-release` s4 | 150 s7 |
| `93-rakun-soap-webservices` s2 | 150 s8 |
| `93-rakun-soap-webservices` s3 | 150 s8 |
| `93-rakun-soap-webservices` s4 | 150 s8 |
| `73-rakun-starters` s1 | 150 s9 |
| `73-rakun-starters` s2 | 150 s9 |
| `73-rakun-starters` s3 | 150 s9 |
| `19-rakun-test-utilities` s1 | 150 s10 |
| `13-rakun-http-clients` s1 | 150 s11 |
| `13-rakun-http-clients` s2 | 150 s11 |
| `13-rakun-http-clients` s3 | 150 s11 |
| `13-rakun-http-clients` s5 | 150 s11 |
| `13-rakun-http-clients` s6 | 150 s11 |
| `12-rakun-cache` s1 | 150 s12 |
| `12-rakun-cache` s2 | 150 s12 |
| `12-rakun-cache` s3 | 150 s12 |
| `12-rakun-cache` s4 | 150 s12 |
| `12-rakun-cache` s5 | 150 s12 |
| `12-rakun-cache` s6 | 150 s12 |
| `22-rakun-file-routing` s1 | 150 s13 |
| `22-rakun-file-routing` s2 | 150 s13 |
| `22-rakun-file-routing` s3 | 150 s13 |
| `22-rakun-file-routing` s4 | 150 s13 |
| `22-rakun-file-routing` s5 | 150 s13 |
| `22-rakun-file-routing` s6 | 150 s13 |
| `22-rakun-file-routing` s7 | 150 s13 |
| `22-rakun-file-routing` s8 | 150 s13 |
| `17-rakun-logging` s1 | 150 s14 |
| `17-rakun-logging` s2 | 150 s14 |
| `17-rakun-logging` s3 | 150 s14 |
| `17-rakun-logging` s4 | 150 s14 |
| `11-rakun-actuator` s1 | 150 s15 |
| `11-rakun-actuator` s2 | 150 s15 |
| `11-rakun-actuator` s3 | 150 s15 |
| `11-rakun-actuator` s4 | 150 s15 |
| `65-rakun-url-rules` s1 | 150 s16 |
| `65-rakun-url-rules` s2 | 150 s16 |
| `65-rakun-url-rules` s3 | 150 s16 |
| `65-rakun-url-rules` s4 | 150 s16 |
| `09-rakun-data-nosql` s1 | 150 s17 |
| `09-rakun-data-nosql` s2 | 150 s17 |
| `09-rakun-data-nosql` s3 | 150 s17 |
| `09-rakun-data-nosql` s4 | 150 s17 |
| `09-rakun-data-nosql` s5 | 150 s17 |
| `09-rakun-data-nosql` s6 | 150 s17 |
| `91-rakun-pulsar` s1 | 150 s18 |
| `91-rakun-pulsar` s2 | 150 s18 |
| `92-rakun-rsocket` s2 | 150 s19 |
| `92-rakun-rsocket` s3 | 150 s19 |
| `88-rakun-cli` s1 | 150 s20 |
| `88-rakun-cli` s2 | 150 s20 |
| `88-rakun-cli` s3 | 150 s20 |
| `88-rakun-cli` s4 | 150 s20 |
| `88-rakun-cli` s5 | 150 s20 |
| `19-rakun-test-utilities` s2 | 150 s21 |
| `19-rakun-test-utilities` s3 | 150 s21 |
| `19-rakun-test-utilities` s4 | 150 s21 |
| `19-rakun-test-utilities` s5 | 150 s21 |
| `19-rakun-test-utilities` s7 | 150 s21 |
| `123-bpp-middleware` s0 | 150 s22 |
| `123-bpp-middleware` s1 | 150 s22 |
| `123-bpp-middleware` s2 | 150 s22 |
| `123-bpp-middleware` s3 | 150 s22 |
| `123-bpp-middleware` s4 | 150 s22 |
| `123-bpp-middleware` s5 | 150 s22 |
| `123-bpp-middleware` s6 | 150 s22 |
| `123-bpp-middleware` s7 | 150 s22 |
| `127-bpp-actions` s0 | 150 s23 |
| `127-bpp-actions` s1 | 150 s23 |
| `127-bpp-actions` s2 | 150 s23 |
| `127-bpp-actions` s3 | 150 s23 |
| `127-bpp-actions` s4 | 150 s23 |
| `127-bpp-actions` s5 | 150 s23 |
| `127-bpp-actions` s6 | 150 s23 |
| `20-snap` s2 | 150 s24 |

## Steps

### 150 s1 — the core's open boxes (04)

#### Step 2 — Boot options and the cycle stack (R04-1, R04-2) (was `04-rakun-erlang-runtime` s2)

- [ ] `erlang_runtime_test.bp`: scratch project, `banner.txt` with `${application.version}`, `${rakun.version}`, `${otp.version}`, booted headless; captured output starts with the substituted banner, once, before any log line
- [ ] `rakun.main`'s `bannerMode` off prints nothing (299: the key is the field's name; `banner-mode` today); under `botopink test` nothing printed whatever the setting
- [ ] `rakun.main`'s `headless: true` + `keepAlive: true` does not halt within the test's budget; `keepAlive: false` halts with `0` (299; `keep-alive` today)
- [ ] a `fixtures/cycle` boot fails listing the construction stack, innermost last (`A -> B -> C -> A`), asserted line by line

#### Step 3 — Configuration (R05-1, R05-2, R14-1, RX-2) (was `04-rakun-erlang-runtime` s3)

- [ ] `typed_config_test.bp`: one bound record with a field of each of `bool`, `i32`, `i64`, `f64`, `string`, `string[]`, `Duration`, `DataSize`, each from a property source; an unparsable value of each refuses the boot naming the key
- [ ] `config_check_test.bp`: the refusal names key, offending value and source file, against `fixtures/typed`
- [ ] `config_check_test.bp`: the check over a valid 50-field record under 5 ms, `io.clock` over 100 iterations
- [ ] RX-2 (14, 72): the decorator-argument default (`#[configurationProperties("prefix")]` today, `#[config]` after step 7 — 299, argument omitted) re-measured in `config_check_test.bp` / `autoconfig_test.bp`; README records "applied" or "still the language-gaps decorator-default row"

#### Step 4 — Context (R06-1 … R06-7) (was `04-rakun-erlang-runtime` s4)

- [ ] `context_test.bp`: `ctx.beanNames()` equals `rkScannedNames()` filtered to `#[component]` types (318), order-insensitive, on `fixtures/tree`
- [ ] two unqualified `#[provides]` of one type fail the build at the entry point's bean table, naming both functions (343; `fixtures/phmissing` gains the case)
- [ ] `#[postConstruct]` runs after construction, before `eagerInit` returns — a hook recording the eager pass's state
- [ ] `#[scope("request")]` on a constructor-injected factory refused at compile time naming the injection site — where the entry point builds the bean table, which sees both declarations (343, 347: a method's `@Decl` has no `owner`)
- [ ] with defaults every registered bean constructed before `Rakun.run` returns; a missing required config key (`#[value]` today, a `#[config]` field after step 7 — 299) fails inside `Rakun.run` (a recording constructor)
- [ ] `scopes_test.bp` / `context_test.bp`: clean stop exits `0`; failed boot exits non-zero, a distinct code per failure kind (the table 19's `bootAndExit` consumes)
- [ ] `rakun.d.bp` leaves `botopink.json`'s `files` and the tree; `fixtures/imports` (a consumer naming `Context` in a signature) still compiles — the concrete type carries `resolve` / `has`
- [ ] the scan registry records each component's injected field names; `rkScannedDeps(name) -> string[]` answers them (88's `beans`)
- [ ] `rkExcludeFromEager(T)` (by type, step 6 — 281): a registered type skipped by `eagerInitIn`, constructed on first resolution (`context_test.bp`); `pub` from `src/root.bp` (08 step 1 consumes it)

#### Step 5 — Request context (R62-2, R62-3, R64-1's core half, RX-1) (was `04-rakun-erlang-runtime` s5)

- [ ] `request_context_test.bp`: a raising deferred function leaves the response as written, logged exactly once at `error` through the core's logger with the request id (decision 187 — no sink)
- [ ] `Request` behavior gains `headerNames()`, `headers()`, `queryDict()`, `rawQuery()`; `request_context_test.bp` asserts all four from a request with two headers and `?x=1&y=%20`, `rawQuery()` the bytes as received
- [ ] `config_test.bp:569`'s `?? Doc(…)` is an `if (x == null)` narrowing (RX-1)

R62-1 (`setPhase(RequestPhase.Action)` visible to `requestPhase()` and `rkCachePhase()`) asserted in
12's `revalidate_test.bp`, ticks here when 12 lands it. R64-1's filter half (i18n redirect reusing
`rawQuery()`) is 22's.

#### Step 6 — references, not strings (decision 281) (was `04-rakun-erlang-runtime` s6)

A bean, an event or a condition is named by its type or its function, never its text
(`examples/context-lifecycle-example.bp`).

- [ ] `ctx.resolve("OrderCache")` → resolution by type (`use bean(OrderCache)`, the shape of a
      context read by type, `use context(T)` — 354, 379); `resolveNamed("Clock", "fixed")` → `resolveNamed(Clock, "fixed")` (321: the type as a type,
      the label a `comptime` string checked against the registry at build; `resolveNamed(Clock)` the `#[primary]`);
      `#[qualifier("…")]` also on a constructor field; an unknown label, a duplicate label or two `#[primary]` a build error
- [ ] `#[eventListener("OrderPlaced")]` → `#[on] fn f(e: OrderPlaced)`, the event the parameter's type
      (280 example 2); the string form refused
- [ ] `#[conditionalOnMissingBean(MailSender)]` takes a `type` (280 example 3); `rkExcludeFromEager`
      takes the type
- [ ] `examples/context-lifecycle-example.bp` rewritten to decision 281 (`ctx.resolve("…")` /
      `resolveNamed` / `#[eventListener("…")]` / `has("…")` by type; its `// LANGUAGE GAP:` on
      `@typeName<T>()` goes with lg2-g, closed by 281); the qualifier half follows 321

#### Step 7 — configuration as a typed record (decision 299) (was `04-rakun-erlang-runtime` s7)

- [ ] `#[config("rakun.data")] pub type DataConfig(poolSize: i32 = 10, bootstrapMode: BootstrapMode =
      .Eager)`: bound at boot from the config file (and `#[env("…")]` fields from the environment),
      injected by type (`use config(DataConfig)` in a body under the request's `RequestContext` (354), or as a bean); `#[configurationProperties]`
      folds into it
- [ ] a field's key is its exact name (`poolSize`, `Lazy` — no case conversion, 280 (4)); `#[key("pool-size")]`
      names an existing file's spelling; a wrong type, an unknown variant, an unknown key or a malformed
      number (`"12abc"`) stops the boot naming the file, line and expected type (03r-b's lenient parse goes)
- [ ] `#[value("…")]` and `rkProp*` leave the rakun members; `rakun.profiles.active` is a field of a
      `#[config("rakun")]` record (`profiles: string[]`)

#### Step 8 — one decorator per role (decision 318; the core's `decorators.bp` through 130 step 5) (was `04-rakun-erlang-runtime` s8)

- [ ] `#[component(lazy: …, scope: …)]` the one type stereotype; `#[service]`, `#[managed]` and the core's
      `#[repository]` on a `type` deleted, their sites `#[component]` (the scan and `T.make()` unchanged)
- [ ] `#[provides]` on a free function the one way to provide a bean, reading 299's typed config;
      `#[configuration]`, `#[bean]` and their `rkRegisterBean` emission deleted; `examples/rakun/src/config.bp`
      and `test/{autoconfig,conditions,scopes,context}_test.bp` rewritten
- [ ] one `#[controller]`: the answer by the method's return type — `View` HTML, a record JSON, `Response`
      as is; `#[restController]` deleted, its sites `#[controller]`
- [ ] no Spring name left in the core's public surface (`grep` over `src/` for the deleted names is empty)

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` green in `modules/rakun`;
`botopink format --check` clean there; `modules/README.md` updated.

### 150 s2 — the rows handed in: the action secret, `codepointIndex`, the `Json` copies, the `@BeamMemory` migration

Each waits on the step it names: the action secret on 150 s1 (04 step 7, 299); the copies on std's methods (on
`feat`).

#### Open (was `103-actions-id` open)

- [ ] The secret from rakun-app's typed `#[config("rakun.actions")]` record (299), not `rkProp` —
      measured 9 Oct: no `#[config(…)]` record exists in rakun, so the one read sits at the two
      `deriveActionId` calls; the switch and the `rkProp` removal are `04-rakun/04` step 7's

**Gate:** standard (fronts.md § Gate) + `repository/actions/AGENTS.md` names `id`

#### Rows found by other fronts — part (was `02-erlang` rows box 2)

- [ ] rakun's `codepointIndex` host cell (`autoconfig_registry.bp`) deletable since step 6 — rakun
      track's row, noted here

#### Step 2 residue — no `Json` accessor copy left in the library repositories — part (was `97-std-dedupe` s2 residue box 2)

- [ ] rakun: `rakun-security/src/jwt.bp` (`membersOf`, `isObject`, `fieldOf`, `strOf`, `itemsOf`) and
      `rakun/src/autoconfig_registry.bp` (`membersOf`, `isObject`, `itemsOf`) — `04-rakun`'s rows

#### Step 2 — the text and the migration handed over — part (was `17-beam-memory` s2 box 3)

- [ ] the rakun track's README names the migration by its 1.0.10 path
      ([`rakun-migration.md`](../../../1.0.10-beta/00-compiler-carry-over/17-beam-memory/rakun-migration.md):
      the `rakun_runtime.erl` registry / `gen_server` half remains)

### 150 s3 — TLS and SSL bundles (74)

#### Step 1 — Client verification (R74-1, R74-2) (was `74-rakun-tls-ssl-bundles` s1)

- [ ] `ssl_bundle_test.bp`: a loopback server presenting a certificate for `other.test`, a `verify=full` client bundle for `localhost`: connect fails, the failure names the hostname mismatch
- [ ] `verify=full` against a matching certificate connects (positive control)
- [ ] with `verify=none` the same connect succeeds against both certificates; resolving the bundle writes one warning through the core's logger naming the bundle (the `sslWarnings()` cell stays)

#### Step 2 — Reload (R74-3, R74-4) (was `74-rakun-tls-ssl-bundles` s2)

- [ ] `tls_listener_test.bp`: a connection opened before `sslReload("b")` still exchanges bytes after it (existing cell "sslReload after replacing both files makes the next handshake present the new certificate" covers the new-connection half)
- [ ] `reloadOnUpdate: true`, `interval: 200ms` (299): rotated files on disk picked up, a new connection presents the new serial within 400 ms (`io.clock`)

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun` and `modules/rakun-web`.

Blast radius: none outside the owned files; 13, 92, 93 consume the unchanged registry API.

### 150 s4 — SQL data access (08)

#### Step 1 — Lazy bootstrap (R08-1, R08-2; after 04 step 4) (was `08-rakun-data-sql` s1)

- [ ] `sql_pool_test.bp`: with `bootstrapMode: Lazy` (`DataConfig`, step 5 — 299; `rakun.data.repositories.bootstrap-mode=lazy` until it lands), a recording-constructor `#[repository]` is not constructed by `Rakun.run`, is constructed on first resolution
- [ ] with the default (`Eager`) it is constructed before `Rakun.run` returns
- [ ] R08-2 ("named parameters, the repository queries, the pool and local transactions all behave as the acceptance lists" — `#[query]` reads as step 7's `#[repository]` forms, 313) ticked, the four lists re-run

#### Step 2 — Migration lock (R77-1) (was `08-rakun-data-sql` s2)

- [ ] `migration_test.bp`: under `postgresql` the lock arm issues `SELECT pg_advisory_lock(<key>)` before the first migration and `pg_advisory_unlock` after the last, on the recorded statement list (recording datasource, no server)
- [ ] under `ets:memory` and `mysql` the `global` arm is taken, the standalone-node warning emitted once
- [ ] member README states the two arms and which schemes take which

#### Step 3 — ORM (R78-1, R78-2, RX-2) (was `08-rakun-data-sql` s3)

- [ ] `orm_test.bp`: a 100-row fetch through a derived finder issues exactly one statement (recorded); the join finder's SQL names exactly the two tables and the join column
- [ ] R78-2 reworded to the statement-count-and-text assertion; the "100 joined rows on a real arm" half is a `deferred.md` row
- [ ] R78-1 ("`findByCiudad` is a compile error naming the entity and listing its fields"): the type-level generator (`#[repository]` on a behavior, 318) checks each `findBy<Field>` against `@typeInfo(<entity>).meta(Entity)?.columns` (298) and refuses, listing them (347) — re-measured on the post-130 decorators and ticked
- [ ] RX-2 (78): decorator-argument default re-measured in `orm_build_test.bp`

#### Step 4 — references, not strings (decision 281) (was `08-rakun-data-sql` s4)

- [ ] `#[entityRepository(City)]` takes the type; `derivedSql("CityRepo", "countByState")` takes the
      function; an operator is `Op`'s variant, never `">="`
- [ ] `index`, `unique` take `Type.Field<T>` (`.state`; 308); table and column names stay strings (SQL's, 280 example 6)
- [ ] `examples/city-entity-example.bp`, `examples/audit-and-revisions-example.bp` rewritten to decision 281 (`#[entityRepository(City)]`, `derivedSql` by function, `Op`'s variant) and 299 (no `rkProp` / `rkPropInt` import)

#### Step 5 — configuration as a typed record (decision 299) (was `08-rakun-data-sql` s5)

- [ ] this member's `#[value("…")]` / `rkProp*` reads and group configs become `#[config("<prefix>")]` records (`04` step 7)

#### Step 6 — one API answering `@Result<T, StoreError>` (decision 304; after `01-compiler/02-erlang` step 14) (was `08-rakun-data-sql` s6)

- [ ] `StoreError` declared in `src/datasource.bp` (already exported; this front edits neither `botopink.json` nor `src/root.bp`): `pub type StoreError { Unavailable(message: string), Timeout(ms: i32), Conflict(message: string), Constraint(name: string, message: string) }` — the draft cases, closed here with 09 (a case added only when a driver failure needs its own handling); exported for 09
- [ ] `SqlTemplate.query` / `update` / `single` answer `@Result<Rows | i32 | ?Row, StoreError>`; `raising` and the `@panic(o.error)` path go — a driver failure is `throw` of its case, never a raise
- [ ] `tryQuery`, `tryUpdate`, `tryQueryOn`, `tryUpdateOn` (`src/sql/template.bp:106-152`), `tryMigrate` (`src/migration/migrate.bp:414`) and every other `try*` twin in the member deleted; their callers use the one API (`case` or `try`)
- [ ] the ORM repository's generated methods (`save`, `update`, `byId`, derived queries) answer `@Result<…, StoreError>`; an optimistic-lock miss is `Error(Conflict(…))` (`audit-and-revisions-example.bp`'s `repo.tryUpdate(saved)` becomes `repo.update(saved)` matched on `Conflict`)
- [ ] `transaction(work)`: an `Error` the work returns rolls back, as a raise does today — one cell each
- [ ] `@panic` left only for a programming error: `single()` meeting more than one row keeps its message naming the statement
- [ ] the method forwarding comment in `template.bp` (a method `-> @Result` lowered as a plain function) gone with 02 step 14
- [ ] the front's examples and `repository/rakun/AGENTS.md` § SQL data access rewritten to `try` / `case`

#### Step 7 — rakun-data over `dbcontext` (decision 398; after `04-rakun/143` steps 1–2) (was `08-rakun-data-sql` s7)

Entities, the context and the repositories are the `dbcontext` library's (`04-rakun/143`); rakun-data keeps
the drivers, the container and the transactions. Today a repository is a `type` whose method carries
`#[query("…")]` (`src/sql/query.bp`), which writes `<Repo>.<m>Sql()` and registers the statement through
`rkRegisterQuery`.

- [ ] the PostgreSQL and ETS drivers implement `dbcontext`'s `Driver`; statements run on the driver's `SqlTemplate`
- [ ] the container registers `DbContext` and each `#[repository]` behavior's generated implementation
      by type (234): `Users` injectable, `Relatorio(db: DbContext)` built by the container
- [ ] `SqlTemplate.query` / `update` / `single`: `sql` is `comptime` — a statement built at run time is
      refused at the argument (the injection rule `#[query]` kept by shape)
- [ ] `#[query]`, the `<m>Sql()` members, `rkRegisterQuery` / `rkRegisteredQueries`, rakun-data's `#[entity]`
      mapping and repository code deleted (moved to `dbcontext`, 143 step 3); the statement inventory
      (`/actuator/sql`, 11) read from `dbcontext`'s query meta through `@TypeInfo.all` (253)
- [ ] `examples/city-entity-example.bp`, `examples/audit-and-revisions-example.bp` rewritten to
      `#[repository]`; their `// LANGUAGE GAP` markers for the bodyless-method row go, and the row
      with them (`language-gaps.md`)
- [ ] cells: a `#[repository]` over ETS answering both forms through the container; the body form
      (`self.db.query "…"`, 397) with an injected `DbContext`
- [ ] `repository/rakun/AGENTS.md` § SQL data access and the member README name `dbcontext` and the drivers

- [ ] `#[transactional]` (`src/sql/transactional.bp`) a wrapper (316, 318 (7)): the hand-written `<Type>Tx`
      proxy deleted, its sites the annotation on the method

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-data`.

Blast radius: step 1 changes construction timing under `lazy` only; `rakun-session`'s SQL store,
`rakun-scheduling`'s job store and `src/tx/**` construct eagerly by default. Step 2 adds statements
on the PostgreSQL arm only.

Kept for open markers: `examples/city-entity-example.bp`, `examples/audit-and-revisions-example.bp`
(the bodyless-method row, by design since 311 — they go with step 7).

### 150 s5 — messaging (15)

#### Step 1 — Registries on the reset hook (R19-1/2, this member's half) (was `15-rakun-messaging` s1)

- [ ] `registry_test.bp`: after `resetContext()` (through `rkOnReset`) the listener registry is empty and `rakun_listener_names` answers `[]`; a later registration visible in both
- [ ] `rakun-scheduling/test/registry_test.bp`: the same for the task registry

#### Step 2 — Acknowledgement (R86-1, R86-2, R90-4, R90-5) (was `15-rakun-messaging` s2)

- [ ] `reliability/ack_test.bp`: under `Auto` a `Retry` leaves the original unsettled, the broker redelivers it with `x-attempt` incremented; a `Done` settles it
- [ ] a stopping worker with a held batch of 3 settles them before exiting (broker's unsettled count 0 after the container stops)
- [ ] `jms/client_test.bp`: a STOMP redelivery carries `x-attempt`; the third `Retry` of a ceiling-2 policy dead-letters through 86
- [ ] `Auto` / `Manual` / `Batch(size)` map onto `client-individual` / `client` / `client` with an explicit ACK frame every `size`, on the fixture's frame log

#### Step 3 — `publishWithRetry` and the JMS tail (R86-3, R90-1/2/3/6/7/8) (was `15-rakun-messaging` s3)

- [ ] `reliability/backoff_test.bp`: `publishWithRetry` retries a failing publish with the policy's backoff, dead-letters at the ceiling; a succeeding publish called once
- [ ] `jms/client_test.bp`: `jmsSend` with a configured policy goes through it (a fixture failing twice is retried twice)
- [ ] `#[jmsListener("q")]` registers on the shared registry tagged `jms`; on a non-method fails with a located message (`build_test.bp` over a scratch project)
- [ ] heart-beat: fixture negotiates `heart-beat:1000,1000`; a fixture that stops beating closes the connection within two intervals (`io.clock`)
- [ ] request/reply: a reply after the timeout is discarded, the requester process alive; the reply subscription removed when the requester raises (fixture's subscription list)
- [ ] `jms` indicator hidden by default exposure, shown when 76 exposes `health` details (through the core's `actuator_api` registry and the exposure rule)

#### Step 4 — Streams (R89-1/2/3) (was `15-rakun-messaging` s4)

- [ ] `stream/runtime_test.bp`: with `Queue(prefetch: 1)` and a blocked first stage, the broker's fetched count is 1 (second message not fetched)
- [ ] `stream/stages_test.bp`: two events in one window emit once with the combined aggregate at watermark passage; two across a boundary emit twice
- [ ] a late event within `lateness` re-emits its window; one beyond it counted on the `late` branch, no re-emit

#### Step 5 — The outbox path in the producer transaction (R83-1, 03r-al) (was `15-rakun-messaging` s5)

- [ ] `tx/outbox_test.bp`: in-process broker transactional, a publish enrolled in a transaction goes through `withProducerTransaction`, writes no outbox row (outbox table count unchanged)
- [ ] an aborted transaction leaves no message visible to a `read_committed` consumer; a committed one delivered once
- [ ] R83-1's DoD ("broker-native transactions are used where available, through the same API, and which path ran is observable"): which path ran is in the log line the existing cell reads
- [ ] one `deferred.md` row: the same three assertions against a real Kafka broker

#### Step 6 — Scheduling and defaults (R16-1, RX-2) (was `15-rakun-messaging` s6)

- [ ] R16-1 ("the parser is an ordinary compiled function; the decorator body calls it") closes once `01-compiler/14` step 6 lands (341): a host cell it reaches needs `@External.Beam` only (rakun declares `["erlang"]`); until then README records the inlined parser's size and the one-line change
- [ ] RX-2 (15, 86, 90): decorator-argument default re-measured in `decorators_test.bp`, result recorded

#### Step 7 — configuration as a typed record (decision 299) (was `15-rakun-messaging` s7)

- [ ] this member's `#[value("…")]` / `rkProp*` reads and group configs become `#[config("<prefix>")]` records (`04` step 7)

#### Step 8 — one listener: `#[listen(dest)]` (decision 318 (5)) (was `15-rakun-messaging` s8)

- [ ] `pub val orders = Destination<OrderPlaced>("order-events")`: the destination declared once, typed,
      the broker's name a string (281); the transport and group from 299's typed config
- [ ] `#[listen(orders)]` on a method of a `#[component]`; the payload the method's parameter, checked
      against the destination's `T`; `#[amqpListener]`, `#[kafkaListener]`, `#[redisListener]`,
      `#[streamListener]` and the type-level `#[listener]` deleted, every site and test rewritten
- [ ] `#[retryable(…)]` on a publishing method a wrapper (316) over `publishWithRetry`;
      `publish-reliability-example.bp`'s marker rewritten

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `rakun-messaging` (`test/stream/` in the run), `rakun-data` (`test/tx/`) and
`rakun-scheduling`; `grep -rn RAKUN_TEST_ modules/rakun-messaging modules/rakun-data/src/tx modules/rakun-data/test/tx` empty.

### 150 s6 — OAuth2 and SSO (79)

#### Step 1 — The manager seam (R79-1, RX-1) (was `79-rakun-oauth2-sso` s1)

- [ ] `basic_test.bp`: with the LDAP manager installed, a reachable directory double authenticates a Basic request; an unreachable one answers 503 with a problem detail naming `ldap`, not 401
- [ ] with no manager installed the default over `UserDetailsService` behaves as today (existing cells)
- [ ] `basic_test.bp:137,174`'s `?? UserDetails(…)` narrowed with `if (x == null)` (RX-1)

#### Step 2 — Amendments (R79-3, R79-4) (was `79-rakun-oauth2-sso` s2)

- [ ] on 03r-w's confirmation: R79-3 reworded to "`withClientToken(id, call)` attaches a token to a front-13 call with no token mentioned in the service body", ticked against `oauth2_test.bp`'s existing cell; if 13's interceptor seam landed, `withClientToken` is one interceptor and the cell re-runs
- [ ] R79-4 reworded to "`repository/rakun/AGENTS.md` § OAuth2, OIDC, LDAP and SAML documents the boundary table" and ticked

#### Step 3 — SAML ACS (R79-2, 03r-ae) (was `79-rakun-oauth2-sso` s3)

- [ ] under (a): `test/saml2/acs_test.bp` — a fixture assertion with valid signature, in-window `Conditions`, matching audience and `InResponseTo` authenticates; each of the four checks failed alone rejects (four cells); a signature over a different document rejects; the canonicaliser reproduces the W3C exc-c14n test vectors checked in under `test/saml2/fixtures/c14n/`
- [ ] under (b): the three boxes deleted, `saml2.bp` keeps the 501 with a message naming the gap, one `deferred.md` row holds them

#### Step 4 — `#[secured]` and rakun's own names (decision 318 (7), (8)) (was `79-rakun-oauth2-sso` s4)

- [ ] `#[secured(…)]` a wrapper (316) on a function or method; the hand-written `<Type>Sec` proxy
      (`method_security.bp`) deleted, its sites the annotation
- [ ] `UserDetailsService` and the other Spring names renamed after their role (front's choice, e.g.
      `behavior UserStore`), recorded in the member README; no Spring alias

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-security`.

Blast radius: step 1 puts a behavior between `basic.bp` and its user store; `rakun-actuator`'s access
rules and `rakun-websocket` call `security_filter.bp`, signature unchanged. Step 3 (a) adds a
sidecar and fixtures only.

### 150 s7 — packaging and release (81)

#### Step 1 — The tarball boots (R81-1) (was `81-rakun-packaging-release` s1)

- [ ] `release_test.bp`: a release from `examples/rakun` has every `out/erl/*.erl` compiled into `lib/<app>/ebin` (`.beam` files listed in the tarball's tree) — measured first against today's `compile_dir` call; README records whether it already held
- [ ] unpacked under the scratch directory, `bin/<name> foreground` with `headless: true`, `keepAlive: false` (299; `keep-alive` today) starts, prints the banner, exits 0 within 10 s
- [ ] a non-compiling sidecar fails `rakun build` naming file and line

#### Step 2 — Upgrade and downgrade (R81-2) (was `81-rakun-packaging-release` s2)

- [ ] two versions from `examples/rakun` (one-line change in `users.bp`); the first boots with `-sname`; `install_release` of the second on the running node; 200 `GET /users` across the switch-over see zero failures
- [ ] the generated downgrade applied to the same node afterwards; loop again zero failures; `release_handler:which_releases/0` shows the expected states
- [ ] if the runner cannot start distribution, README records the measured refusal, both boxes stay open naming it; no cell written

#### Step 3 — SBOM validation (R81-3, R81-4, 03r-ak) (was `81-rakun-packaging-release` s3)

- [ ] `bom-1.5.schema.json` checked in under `test/release/fixtures/`; `release_test.bp` walks the rendered SBOM against it (`required`, `type`, `enum`, local `$ref`) and passes; a fixture SBOM missing `bomFormat` fails naming the path
- [ ] R81-4 reworded to "`src/` renders every file; there is no `templates/`" and ticked

#### Step 4 — the release manifest's marker against `@TypeInfo.all` (decisions 216, 253) (was `81-rakun-packaging-release` s4)

- [ ] `examples/release-manifest-example.bp` re-measured: if `@TypeInfo.all` builds the application
      list, marker, its Marker-index row and the `language-gaps.md` row go together
      (`scripts/language-gap-markers.sh` exits 0); else the row narrowed to what is missing (a
      package's module list or manifest), marker stays

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-cli` (`test/release/` in the run).

Blast radius: `rakun build` (88) delegates to the release; `scaffold_test` "build: the release
artefact is front 81's tarball, and exit 0" re-runs unchanged. Boot cell adds ~10 s to the suite.

### 150 s8 — SOAP web services (93)

#### Step 2 — The generator (R93-1) (was `93-rakun-soap-webservices` s2)

- [ ] `test/ws/generate_test.bp`: `fixtures/wsdl/targeted.wsdl` (every targeted construct) generates; the tree compiles with `botopink build --target erlang`, its generated tests pass with no hand edit
- [ ] thirteen fixtures, thirteen cells, each a located error naming the construct and its element
- [ ] `minOccurs="0"` → `?T`, `maxOccurs="unbounded"` → `T[]`, both → `?T[]`; an enumeration → an enum-shaped `type`, an unknown value in a response is an error
- [ ] a recursive type beyond depth 8 refused
- [ ] two runs over an unchanged WSDL byte-identical; header names the WSDL and its hash
- [ ] a network `xsd:import` refused; a local relative one followed

#### Step 3 — The client and the endpoint (R93-2, R93-3) (was `93-rakun-soap-webservices` s3)

- [ ] `test/ws/client_test.bp`: `WsClient` built with bundle `b` passes it to `rakun-client`; the TLS double sees the bundle's client certificate; a missing bundle name refuses the build
- [ ] `test/ws/client_test.bp`: `<path>?wsdl` serves the source unmodified, its hash equals the generated header's

#### Step 4 — rakun's own names (decision 318) (was `93-rakun-soap-webservices` s4)

- [ ] the generated client is a generator on a `behavior`, as `#[httpClient]` (318 (4)); the endpoint a
      `#[controller]` method (318 (6)); no Spring-WS name left

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` green in `modules/rakun-client`
(`test/ws/` in the run); `botopink format --check` clean, generator output included;
`modules/README.md` updated.

Blast radius: new files under `rakun-client/src/ws/` only. 88 adds `ws generate` and the
`rakun-cli → rakun-client` edge in its own front.

`examples/soap-client-example.bp` kept for its open marker (the comptime-file gap, answered by 342's
`@embedFile`, unbuilt).

### 150 s9 — starters and examples (73)

#### Step 1 — The starters (was `73-rakun-starters` s1)

- [ ] `starters/rakun-starter-app/{botopink.json,src/root.bp}` exist; `starter_manifest_test.bp` asserts the nine starters and their `brings` lists
- [ ] `starters/rakun-starter-test/botopink.json` names `rakun-starter` and `rakun-test` only; the lint's `allowList()` and its two asserting cells gone (no out-of-repo dependency allowed); the workflow's onze checkout gone; `grep -rn onze repository/rakun/starters` answers nothing
- [ ] `starters/README.md` lists nine, states the workspace rule (03r-r)

#### Step 2 — The examples run (was `73-rakun-starters` s2)

- [ ] `examples/rakun`: `botopink build --target erlang --out out` then `botopink run` headless exits 0, prints the banner — a cell in `modules/rakun/test/starter_manifest_test.bp` (renamed `consumer_surface_test.bp`) driving the compiler through `BOTOPINK_BIN` under `BOTOPINK_TEST_TMPDIR`, as `rakun-cli`'s tests do
- [ ] the same for `examples/rakun-container` and `examples/rakun-ssr` (ssr answers `/` over a loopback socket with its renderer's text)
- [ ] if any of the three fails on a sidecar load, the milestone's `language-gaps.md` toolchain row re-pinned with the measured text, box open naming it
- [ ] each example has a `README.md` (what it shows, how to run it) — PK-2

#### Step 3 — The seven (03r-af) (was `73-rakun-starters` s3)

- [ ] under (a): `modules/README.md` § Examples lists the three, says the seven were retired; the closed 1.0.10 map [`03-rakun/test-snap-examples.md`](../../../1.0.10-beta/03-rakun/test-snap-examples.md) referenced from no live document
- [ ] under (b)/(c): one front directory per example opened by the maintainer, each after the member fronts it exercises; nothing here

**Gate:** standard (fronts.md § Gate) + `zig build test-libs -- --target erlang --lib rakun` lists
the nine starter cells and three example cells green; `botopink format --check` clean in
`starters/**`, `examples/**`; `modules/README.md`, `starters/README.md`, `repository/rakun/README.md` updated.

Blast radius: deleting the onze edge affects no consumer in the repository. `run` cells add ~3 s
each to the core's suite (under its 60 s budget); if over, they move to a `consumer_surface` member
of their own, named here.

### 150 s10 — the Redis double (19 s1)

#### Step 1 — The Redis double (decision 160) (was `19-rakun-test-utilities` s1)

- [ ] `test/redis_double_test.bp`: `redisDoubleStart(0)` answers a port; `PING` → `PONG`; `SET`/`GET`/`DEL`/`INCRBY`/`HSET`/`HGET`/`LPUSH`/`RPOP`/`TTL`/`EXPIRE`/`SETEX` behave as Redis documents (one cell per command, asserting reply bytes)
- [ ] `SETEX k 1 v` gone after 1.1 s; `TTL k` reports `1` then `0` before that
- [ ] `redisDoubleFail(port, "GET")` closes the socket on the next `GET`; the following connection succeeds
- [ ] two doubles on two ports share no keys; `redisDoubleStop` frees the port
- [ ] `AGENTS.md` § Test utilities documents the double, its command set and limits ("not Redis: no `SCAN`, no pipelines, no pub/sub")

### 150 s11 — HTTP clients (13)

#### Step 1 — Tags (R13-1) (was `13-rakun-http-clients` s1)

- [ ] `cache_test.bp`: a cached `retrieve()` with tag `t`; `rkBumpTag("t")`; the next `retrieve()` reaches the transport (double's request count +1)
- [ ] a bump of another tag leaves the entry served from cache

#### Step 2 — Keep-alive pool (R13-2) (was `13-rakun-http-clients` s2)

- [ ] `builder_test.bp`: two sequential requests to one origin with the default builder produce one accepted connection on the double; `keepAlive(0, 0)` produces two
- [ ] an idle socket past `idleMillis` is closed, the next request opens a new one (accept count 2)
- [ ] a socket the double closed is not reused: the request succeeds on a fresh connection, no error surfaces
- [ ] pool bounded: 5 concurrent requests with `keepAlive(2, …)` never hold more than 2 idle sockets after finishing (`rkClientPoolSize(origin)`)

#### Step 3 — Interceptors and streaming (R13-3, R65-1's client half) (was `13-rakun-http-clients` s3)

- [ ] `request_test.bp`: a header-adding interceptor is seen by the double; two interceptors run in registration order
- [ ] `retrieveStream` hands a 1 MB body from the double in more than one chunk, concatenation equals the body; peak process heap during transfer under 256 KB (`erlang:process_info(memory)` through the sidecar)

#### Step 5 — configuration as a typed record (decision 299) (was `13-rakun-http-clients` s5)

- [ ] this member's `#[value("…")]` / `rkProp*` reads and group configs become `#[config("<prefix>")]` records (`04` step 7)

#### Step 6 — `#[httpClient]` (decision 318 (4)) (was `13-rakun-http-clients` s6)

- [ ] `#[httpClient(EchoConfig)] behavior EchoService { #[get("/users/${id}")] fn user(self: Self, id: string) -> @Result<User, HttpError>; }`:
      a generator on the behavior, as `#[repository]` is (313); the group a typed config record (299);
      path holes the method's parameters (311's template form where the spelling needs it)
- [ ] `#[httpExchange]`, `#[getExchange]` … `#[deleteExchange]` deleted; `exchange_build_test.bp`,
      `exchange_test.bp` and their refusal cells rewritten to the new names
- [ ] a method answers `@Result<T, HttpError>` with `T` decoded from the body (125's `#[validated]`
      decoder) — the `string`-only rule of `exchange.bp:47-49` goes with its gap note

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-client`.

Blast radius: a default pool of 2 changes connection behaviour for every consumer (17's exporter,
79's token fetch, 93's `WsClient`, 09's Elasticsearch arm): fewer handshakes, same requests. A
consumer asserting accept count per request re-records to per origin — 17's export cell, the front
that wanted it.

### 150 s12 — cache and session (12)

#### Step 1 — The session Redis arm (R18-1) (was `12-rakun-cache` s1)

- [ ] `store_test.bp`: "the suite runs on the Redis arm" starts the double, runs `suite(redisRepository(url, 60))`, asserts `out == ""` and the double's log has `SETEX` for the write and `DEL` for the removal; no env variable read
- [ ] ETS, SQL and Redis arms run the same `suite` unchanged ("the arms are interchangeable or one of them is wrong")
- [ ] `rotation_test.bp`: rotation on the Redis arm deletes the old id (one `DEL` in the log)
- [ ] the `deferred.md` row keeps only the real-server run

#### Step 2 — The cache Redis provider (was `12-rakun-cache` s2)

- [ ] `store_test.bp` (cache): provider suite (`put`, `get`, TTL, `revalidateTag` deletes, single flight) runs against the double
- [ ] an unreachable port runs the loader uncached, health `DOWN` naming redis (03r-i) — existing `endpoint_test.bp` cell "health is UP on ets and DOWN naming redis when Redis does not answer", kept
- [ ] `redisDoubleFail(port, "GET")` mid-suite: the read raises once, the next succeeds (retry rule stated in the member README)

#### Step 3 — The tag epoch (decision 185) and the phase assertion (R62-1, RX-2) (was `12-rakun-cache` s3)

- [ ] `revalidate_test.bp`: `revalidateTag("t")` bumps `rkTagEpoch("t")` by one; `revalidatePath("/p")` bumps the path's tag; `updateTag` bumps too
- [ ] `revalidate_test.bp`: after `setPhase(RequestPhase.Action)`, `requestPhase()` and `rkCachePhase()` both answer the action phase in the same process — cell "in a server action all three verbs are legal" (already asserts `rkCachePhase() == "action"` for a request opened in that phase) gains the `setPhase` call and the `requestPhase()` read; 04's R62-1 ticks with it
- [ ] RX-2: decorator-argument default of `#[cacheable]` / `#[cached]` re-measured in `consumer_test.bp`; README records the result

#### Step 4 — references, not strings (decision 281) (was `12-rakun-cache` s4)

- [ ] `#[cacheable(products)]` takes a `Cache<T>` value whose `T` is the function's return (280
      example 5); the cache's own name (`Cache<Product[]>("products")`) stays a string

#### Step 5 — the cache chosen per function: `#[useCache]` (decisions 315, 316; after `01-checker` step 30) (was `12-rakun-cache` s5)

- [ ] `#[useCache]` (`src/cache.bp`): a function decorator wrapping the function through
      `decl.wrapWith` (316) — the cache key from the function and its arguments, the policy from the
      decorator's typed arguments (`ttl:`, `tags:`, `scope:`; 280), never a string naming code (281)
- [ ] `#[useCache] pub fn posts() -> string { … }` caches on ETS and on the Redis double; two
      `#[useCache]` functions of one module keep separate entries; a wrong return type for the policy
      is an error at the decorator
- [ ] the module-level form stays (315): `val cached = cacheWith(cachePolicy(…))`; the member README
      shows both and says there is no module annotation
- [ ] the two `// LANGUAGE GAP` markers (`src/cache.bp:540`, `test/granularity_test.bp`) rewritten to
      cite 315/316; their marker-index rows and the row "No module-level annotation" deleted in the
      same commit (`language-gaps.md`)
- [ ] 280 example 5's `#[cacheable(products)]` (step 4) wraps through the same mechanism

#### Step 6 — the cache decorators as wrappers (decision 318 (7)) (was `12-rakun-cache` s6)

- [ ] `#[cached]` / `#[cacheable]` / the evict marks rewritten as wrappers on the method (316), not a
      generated `<Behavior>.Cached(inner: …)` twin; one cell per verb

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-cache` and `modules/rakun-session`; `grep -rn RAKUN_TEST_ modules/rakun-session modules/rakun-cache` empty.

Blast radius: none on consumers — provider and arm unchanged, their tests change. Tag bump: one call
per revalidation verb; `rakun-client` reads it in 13.

### 150 s13 — the app router (22)

#### Step 1 — The page `Request` and the scan hand-off (R62-3, R22-1) (was `22-rakun-file-routing` s1)

- [ ] `ssr_test.bp`: a `PageRenderer` receiving a request with two headers and `?a=1&b=%20` reads `headerNames()` (both), `headers()` (both values), `queryDict()` (`a=1`, `b= `), `rawQuery()` (`a=1&b=%20`)
- [ ] `file_router_scan_test.bp`: `fixtures/middleware` (root `middleware.bp`, no `pub mod` naming it) — a request through the app runs the file's entry (a header it sets is on the response); `fixtures/routing` (no root file) registers nothing, chain length unchanged

#### Step 2 — Handlers (R25-1 … R25-4) (was `22-rakun-file-routing` s2)

- [ ] `route_handler_test.bp`: inside a handler `requestPhase()` is `Handler`, previous phase restored after; a dispatch copy without `setPhase` makes `revalidateTag` inside the handler raise (negative case, via a test-only dispatcher flag)
- [ ] `fixtures/conflict-both` (`page.bp` + `route.bp`): the scan reports the segment, the handler registry holds nothing for it
- [ ] `OPTIONS /api/x` with no `#[optionsRoute]` answered by the chain's CORS entry (recording filter saw it, no handler ran); with one registered the handler runs, the filter's CORS arm does not
- [ ] a filter rejecting with 403 means a recording handler never ran

#### Step 3 — Regeneration and i18n (R60-1, R64-1) (was `22-rakun-file-routing` s3)

- [ ] `static_gen_test.bp`: a raising regeneration logged once through the core's logger with the request id (no sink); stale entry served; a later regeneration succeeds
- [ ] `i18n_test.bp`: the locale redirect for `/x?y=%20&z=a%2Fb#frag` is `/en/x?y=%20&z=a%2Fb`, byte for byte

#### Step 4 — The dynamic mark, interim bridge (R23-1, decision 186) (was `22-rakun-file-routing` s4)

Final state (decision 277): `static_gen.bp` reads the route's `S` / `D` from the `k` blob; the
interim boxes below hold until `05-jhonstart/26` step 8 lands.

- [ ] `ssr_test.bp`: a renderer reading `queryDict()` without `markDynamic` leaves the page static; one calling `markDynamic("searchParams")` makes it dynamic — through `static_gen.bp`'s decision
- [ ] `rakun_ssr.erl` has no implicit mark on any accessor (grep cell over the sidecar source)
- [ ] `AGENTS.md` § SSR states the rule and the `ChunkWriter` method; contract 5d in the milestone's `contracts.md` amended by the maintainer (named, not edited here)
- [ ] after `05-jhonstart/26` step 8: `static_gen.bp`'s "the trial render touched a dynamic API"
      reason deleted — the kind comes from the `k` blob; `ChunkWriter.markDynamic` deleted

#### Step 5 — Spans (R11-7) (was `22-rakun-file-routing` s5)

- [ ] `botopink.json` gains no dependency; `ssr_test.bp`, `actions_test.bp`, `route_handler_test.bp` each assert one span (`render`, `action`, `handler`) with the route as attribute, via the core's span test subscriber; with no subscriber nothing emitted

#### Step 6 — Actions (R24-1, R24-2, RX-2, RX-13) (was `22-rakun-file-routing` s6)

- [ ] `actions_test.bp`: literal `"refresh"` is `refreshValue()`; the envelope's `payload` parsed by bundled `actions`' contract-2 reader once jhonstart 30's reader is in `actions` — until then the cell asserts the pathname field by name and the box stays open naming 30
- [ ] R24-1 reworded before work starts: the file-level `pub val useServer = true;` form contradicts 282 (a role is said in a decorator, never by an export's name) — an action is `#[action] pub fn` (303) and onze 50 attaches no directive; the field-by-field comparison against a directive file goes (maintainer confirms the new wording)
- [ ] RX-2 (60, 61, 64, 66): decorator-argument default re-measured in `segment_config_test.bp`, `i18n_test.bp`; README records the result
- [ ] RX-13: `actions_test.bp` and the `actions-cache` fixture spell no `__bp_action` / `X-Bp-Action` (onze's defaults, decision 114); `grep -rn '__bp_action\|X-Bp-Action' modules/rakun-app` empty

#### Step 7 — file roles are the framework's (decision 285) (was `22-rakun-file-routing` s7)

The compiler applies nothing by file name: an unfolded `page.bpp` is a plain `pub default fn`. The
file-convention route table (this member's) is generated at build from `routing`'s kinds (102,
171) and calls jhonstart's `page` / `layout` / … as comptime functions on each default function.

- [ ] the generated table: `pub val routes = comptime [layout("", rootLayout), page("blog/[slug]",
      blogSlugPage), …]`, one entry per app file, by `routing`'s `kindOf(path)`; no `bppKinds` read
- [ ] a route file whose name is no identifier (`not-found.bpp`) imported with an alias by the
      generated table (289); the import form for such a path segment stated here before landing
- [ ] a page's `S` / `D` from `@typeInfo(f).hooks` (277) through that call, the same as the decorator
      form; `onze build`'s report unchanged (`07-onze/49` step 5)

#### Step 8 — no segment configuration — everything in `#[page]` (decision 290) (was `22-rakun-file-routing` s8)

- [ ] `segment_config.bp`'s `dynamic` / `DynamicMode`, `fetchCache` / `FetchCache`,
      `registerSegmentConfig(seg, …)` and the layout-to-page inheritance (03r-o's, closed by 290) deleted; nothing
      forces a stage (202) — `S` / `D` is `#[page]`'s, from `Decl.hooks` (277)
- [ ] `revalidate` and `dynamicParams` read from the page's `#[page]` meta (or the route table's
      `page(seg, f, …)` call, step 7); `static_gen.bp`'s regeneration and the unknown-param rule
      unchanged in behaviour; `segment_config_test.bp` and `static_gen_test.bp` rewritten to it

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-app`; `examples/rakun-ssr` still builds.

### 150 s14 — logging and metrics (17)

#### Step 1 — Correlation and the failure line (R17-3, R75-2, decision 187) (was `17-rakun-logging` s1)

- [ ] `logging/correlation_test.bp`: a request with no `traceparent`, no `X-Request-Id`, inside an edge span, gets `traceId()` as correlation id; with a `traceparent` that header's trace id (existing cell)
- [ ] `rakun-metrics/test/tracing_test.bp`: the logger formatter's line for a traced request carries the span's trace id (R75-2, from the metrics suite against `formats.bp`)
- [ ] `logging/level_test.bp`: the core's failure entry (`after`, request `r1`, text `boom`) produces one `error` line with `correlation=r1` — no sink installed
- [ ] `file_test.bp` and `endpoint_test.bp` write under `BOTOPINK_TEST_TMPDIR`, never `$HOME`

#### Step 2 — The digest and the sink (R17-1; after 106's package) (was `17-rakun-logging` s2)

- [ ] `grep -n "fn errorDigest" modules/rakun/src/logging` empty; `digest_test.bp` asserts the lines of `log`'s known-answer fixture through the imported `errorDigest` — fixture is `log`'s, not this member's
- [ ] the core installs `log`'s sink (configured from `rakun.logging.*`) and calls `log.captureRuntimeReports()` at boot; `cells.bp`'s sink and capture cells deleted (349, after `106` step 3); a record through `log`'s error-logging function produces one `error` line carrying the digest the call answered (`digest_test.bp`); README documents that onze installs `log`'s sink for the render (`07-onze/49` step 3) and that the box ticks when jhonstart 26 step 4's cell reads the same fixture

#### Step 3 — Endpoints and export (R17-2, R75-1) (was `17-rakun-logging` s3)

- [ ] `endpoint_test.bp`: `loggers`, `logfile` 403 under default exposure; still 403 with every `rakun.logging.*` key permissive; answer with 76's grant
- [ ] `rakun-metrics/test/export_test.bp`: one push cycle (metrics + traces) opens one connection on the double (accept count 1) after 13's pool; before it the cell is written, marked in the README as waiting on 13, not skipped

#### Step 4 — a deferred `after()` failure through the core's logger (decision 365; after 128) (was `17-rakun-logging` s4)

- [ ] `drainAfter` (04's `request_context.bp` and its sidecar) reports each deferred function that
      raised or overran through `logger("rakun.request.after").error("after: failed " + id + " " + reason)`,
      the request id as the correlation id; `afterLog()` kept as the request's own record
- [ ] `logging/after_failure_test.bp`: a deferred function that raises and one that overruns each
      produce one `error` line with `correlation=<request id>` (captured, `rkLogCaptureStart`)

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun` (`test/logging/` in the run) and `modules/rakun-metrics`;
`grep -rn '\.cache/bp-rakun' modules/rakun/src/logging modules/rakun/test/logging` empty.

Blast radius: an edge-minted request's id changes from fresh to the trace id (same length, format;
onze's `RequestData` reads it through the header). `after()` (04) and regeneration (22) failures
appear in the log at `error`, not on standard error.

### 150 s15 — actuator (11)

#### Step 1 — Inventory endpoints (R11-1, R11-2, R11-3) (was `11-rakun-actuator` s1)

- [ ] `registry_endpoints_test.bp`: `configprops` lists every registered key with `value` and `source` (`application.yaml`, `env`, `default`), one entry per key
- [ ] `mappings` lists a decorator route and a file-router route, each with `source: "decorator" | "file"` — from the host's `fixtures/`, one of each
- [ ] `startup` answers `config.load`, `eager.init`, one `postConstruct:<Type>` per hook and `listener.bind`, each with a duration

#### Step 2 — `shutdown` (R11-4, closes on tick) (was `11-rakun-actuator` s2)

- [ ] `endpoint_test.bp`: `POST /actuator/shutdown` with 76 granting access calls the drain; recorded order "response written" before "listener stopped"
- [ ] without the grant 405; `GET` 405; default exposure excludes it

#### Step 3 — Instrumentation and spans (R11-5 … R11-8) (was `11-rakun-actuator` s3)

- [ ] `instrumentation_test.bp`: an `#[instrumentation]` recorder runs before `config.load` and any constructor — or the box is reported to 04 with the measured order
- [ ] R11-6 ticked with a pointer to 13's `request_test.bp` cell (`rakun-client`'s `transport.bp` sends `traceparent` from `startSpan("http.client.request", …)`)
- [ ] R11-7 ticked when 22's `ssr_test.bp` / `actions_test.bp` / `route_handler_test.bp` assert one span each through the core's span API
- [ ] `actuator_api/span_test.bp`: no subscriber, 1 000 `startSpan`/`endSpan` pairs under 5 ms (`io.clock`)
- [ ] R11-8's three DoD boxes ticked, the first reworded to "the actuator API lives in the core (`modules/rakun/src/actuator_api/**`, decision 187) and is what 08 · 09 · 12 · 15 · 16 · 17 · 18 · 77 · 85 import"; the other two ("`modules/rakun-actuator/` exists with the endpoint host, the health and info registries, the four registry-reading endpoints, `shutdown`, `instrumentation.bp` and the sidecar"; "spans for request, render, action and handler, `:telemetry`-shaped, with W3C propagation, costing nothing with no subscriber") as written

#### Step 4 — Hygiene (RX-1) (was `11-rakun-actuator` s4)

- [ ] `endpoint_host.bp:136,152` narrowed with `if (x == null)`; the two `EndpointResponse(status: 0 …)` / `(status: 404 …)` dummies gone

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-actuator` and `modules/rakun` (`test/actuator_api/` in the run).

Blast radius: `mappings` and `configprops` bodies gain a field each; onze's `ONZ-71` shutdown cells
read `POST /actuator/shutdown`, unaffected. If R11-2 needs the registrar tag, 04 widens
`registerRoute`, every registrar passes it — a signature change 04 sequences.

### 150 s16 — URL rules and static assets (65)

#### Step 1 — The fall-through (R82-4, decision 201) (was `65-rakun-url-rules` s1)

- [ ] `static_test.bp`: root `/**` → `public/`; a path no root resolves reaches the next chain entry (a recording entry after the static one sees it); an existing file is served, recorder does not run
- [ ] a `POST` (and a `PUT`) to a path a root would serve reaches the chain, file not served; `HEAD` served (rule 2, asserting `staticEntry` as it is)
- [ ] traversal, encoded traversal and a bad segment still final refusals (400/404) at the first matching root, `rkStaticFsCalls()` unchanged for the first two
- [ ] `AGENTS.md` § Static assets states the three rules; onze 69's registration box named as the consumer

#### Step 2 — The relay (R65-1, R65-2) (was `65-rakun-url-rules` s2)

- [ ] `rules_test.bp`: a rewrite to the double answering a 4 MB body streams it — relay process's peak memory under 512 KB (`rkProcessPeakMemory`), client receives every byte
- [ ] `Connection`, `Transfer-Encoding`, `Upgrade`, `Keep-Alive`, `Proxy-Connection`, `TE`, `Trailer` and every name in the upstream's `Connection` value absent from the relayed response; same list absent from the relayed request (the double records it)

#### Step 3 — The dev default (R82-1, R80-1, R82-2, R82-3) (was `65-rakun-url-rules` s3)

- [ ] `rakun-data/src/devtools/devtools.bp`: dev property source sets `rakun.web.resources.cache.period=0`; `rakun-data/test/devtools/devtools_test.bp` asserts the key present under the dev profile, absent otherwise
- [ ] `static_test.bp`: under the dev profile every root answers `Cache-Control: no-cache`
- [ ] R82-2 reworded to "traversal and encoded traversal answer 404 without a filesystem call; a symlink escape by resolving the link, before any read" and ticked; symlink cell asserts the escape refused before any read (`rkStaticFsCalls()` grows by exactly the one `readlink`)
- [ ] R82-3 ("onze front 69's roots are served through `registerStaticRoot` with no second content-type table, ETag rule or traversal guard anywhere under `repository/`"): the grep (`fn contentTypeOf` only in `src/static.bp`) runs as a cell; onze registering is onze's (69)

#### Step 4 — a handler may answer `@Result<Response, E>` (decision 304) (was `65-rakun-url-rules` s4)

- [ ] a `#[getMapping]` / `#[postMapping]` / … method declared `-> @Result<Response, E>` is accepted; `Ok(r)` is sent as is
- [ ] an `Error(e)` of 08's `StoreError` answers a problem response: `Unavailable` 503, `Timeout` 504, `Conflict` 409, `Constraint` 409; any other `E` 500 with a digest, as an uncaught raise is today — one cell each
- [ ] the error is logged once, with the request id, by the same entry that logs a raise (`src/error.bp`)

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-web` and `modules/rakun-data` (`test/devtools/` in the run).

Blast radius: step 1 turns a static-matched miss from 404 into the router's answer — what onze
49/69 need; `examples/rakun-ssr` registers no `/**` root. onze then registers its public root;
ONZ-49-4.3's third box closes on onze's side.

### 150 s17 — document and key-value stores (09)

#### Step 1 — The two behaviors and the ETS arm (was `09-rakun-data-nosql` s1)

- [ ] `KeyValueStore`, `DocumentStore` declared in `src/nosql/mod.bp`; `rakun.nosql.url` selects an arm at boot
- [ ] unknown scheme fails at boot naming the value; known scheme with unloadable driver fails naming the driver
- [ ] `test/nosql/keyvalue_test.bp` and `document_test.bp` (store as a parameter) pass on the ETS arm
- [ ] `putExpiring` with 1-second TTL gone after 2 seconds, `ttl` reports remaining time before that (sweeper on a 100 ms tick under test)
- [ ] `increment` on an absent key starts at 0 and answers `by`
- [ ] `popRight` on an empty list answers `null`, not `""`
- [ ] two test blocks do not see each other's keys

#### Step 2 — The Mnesia arm (was `09-rakun-data-nosql` s2)

- [ ] a document written in one transaction plus an `Error` returned in it leaves nothing behind
- [ ] `disc_copies` survives a node restart within one run (sidecar stops and restarts `mnesia` on the same directory)
- [ ] a second node joining sees the existing documents — over `peer`; or, if the runner cannot start a peer, reworded to the `add_table_copy` call issued and its result asserted, README says why
- [ ] the supported filter subset works; anything else fails naming the operator

#### Step 3 — Redis and Elasticsearch, against the doubles (was `09-rakun-data-nosql` s3)

- [ ] every `KeyValueStore` method maps to the documented Redis command, asserted on the double's command log
- [ ] `fieldGet` / `fieldPut` use hashes, `pushLeft` / `popRight` lists
- [ ] a connection lost mid-call (`redisDoubleFail`) retried once, then answers `Error(Unavailable(…))`
- [ ] `redis` health indicator `UP` against the double, `DOWN` with the reason when the port is closed
- [ ] `index`, `get`, `search`, `delete` go through `rakun-client`; the HTTP double records paths and bodies; timeouts, the bundle and the SSRF filter apply (one negative test each)
- [ ] a 4xx from the double answers an `Error` carrying the double's error body, not a generic message
- [ ] no third-party OTP application required (manifest and sidecar list prove it)

#### Step 4 — `#[documentQuery]` (its shape: `erk-b`) (was `09-rakun-data-nosql` s4)

- [ ] writes the repository member answering the template verbatim (named as `#[query]`'s) and registers it
- [ ] empty template, and one with unbalanced braces, each fail the build with a located message (`test/nosql/query_build_test.bp` over a scratch project under `BOTOPINK_TEST_TMPDIR`)
- [ ] `bind` escapes every parameter for the dialect; a value containing the dialect's quote round-trips
- [ ] `#[documentQuery]` on a non-method fails at comptime
- [ ] registered templates appear in 08's statement inventory

#### Step 5 — The refusal cells (03r-ab (a)) (was `09-rakun-data-nosql` s5)

- [ ] `mongodb://`, `bolt://`, `cassandra://`, `couchbase://` each refuse the boot naming scheme and driver — four cells in `test/nosql/arms_test.bp`
- [ ] four `deferred.md` rows, each naming its box list and the unblocking gap
- [ ] member README's arm table says which arms run and which refuse

#### Step 6 — one API answering `@Result<T, StoreError>` (decision 304; after 08 step 6) (was `09-rakun-data-nosql` s6)

- [ ] `KeyValueStore` and `DocumentStore`: every method answers `@Result<T, StoreError>` (`get` → `@Result<?string, StoreError>`, a mutator → `@Result<i32, StoreError>`); no `try*` method on either behavior or any arm
- [ ] each arm maps its driver failure to a `StoreError` case — connection refused / lost → `Unavailable`, deadline → `Timeout`, version clash → `Conflict`; one cell per arm per case it can produce
- [ ] a refused filter operator stays a boot / call refusal naming the operator (a programming error, `@panic`)
- [ ] `examples/stores-example.bp` rewritten: `raiseProblem` gone, the controller `-> @Result<Response, StoreError>` with `try` (65 step 4)

**Gate:** standard (fronts.md § Gate) +
- [ ] `botopink test --target erlang` green in `modules/rakun-data` with the `nosql/` files; `botopink format --check` clean
- [ ] every configured arm registers a health indicator (asserted through the core's `actuator_api` registry)
- [ ] `AGENTS.md` § NoSQL documents arm table and filter subset; `modules/README.md` row updated

Blast radius: `nosql/*` appended to `rakun-data`'s `files` and `src/root.bp` after 08's lines; no
existing test changes. `rakun-session`, `rakun-cache` keep their own Redis wires this milestone.

### 150 s18 — Pulsar (91)

#### Step 1 — The refusal and the deferred row (decision 274) (was `91-rakun-pulsar` s1)

- [ ] `test/pulsar/refusal_test.bp` asserts the boot refusal's text for a `pulsar://` listener; the
      admin and topic suites stay green
- [ ] one `deferred.md` row for the data plane, naming this README, the fixture-broker approach and
      346's `Bytes`; `examples/pulsar-listener-example.bp` keeps its markers
- [ ] `repository/rakun/AGENTS.md` § Pulsar states the arm's scope (admin, settings, codec) and the
      refusal

#### Step 2 — the listener spelling (decision 318 (5)) (was `91-rakun-pulsar` s2)

- [ ] the refused Pulsar listener is `#[listen(dest)]` with a Pulsar transport in the typed config; the
      boot refusal of step 1 names that transport

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-messaging`.

Blast radius: none outside `rakun-messaging`; `rakun-starter-messaging` unchanged.

`examples/pulsar-listener-example.bp` kept for its open marker (the byte gap — 346 — and the bitwise rule).

### 150 s19 — RSocket (92)

#### Step 2 — Transports (R92-1, R92-2, R92-7) (was `92-rakun-rsocket` s2)

- [ ] per 03r-an: WebSocket transport mounts at the mapping path; `interaction_test.bp`'s suite runs twice, once per transport, byte-identical results
- [ ] a `tls` transport with bundle `b` from 74's registry serves the suite over `ssl`; a missing bundle name refuses the boot naming it
- [ ] requester connects from `tcp://`, `ws://`, `wss://` (the last against the TLS transport), one cell each

#### Step 3 — Channel, mapping, drops, vectors (R92-3, R92-4, R92-5, R92-8, R92-9) (was `92-rakun-rsocket` s3)

- [ ] `interaction_test.bp`: REQUEST_CHANNEL with a slow consumer on one side: the other side's credit keeps flowing (counts after 50 frames each way)
- [ ] `#[messageMapping("r")]` on a method registers in 15's registry; on a `val` fails at build with a located message (`build_test.bp` over a scratch project)
- [ ] a connection the transport closes mid-request fails that request with an error, caller process alive; a second request on a new connection succeeds
- [ ] `codec_test.bp` asserts each of the twelve frame types against its checked-in vector
- [ ] R92-5: two handlers claiming the same route refused at compile time where the entry point builds the route table (`@TypeInfo.all`, 343), naming both declarations, and ticked

R92-6 (`rakun routes` lists rsocket routes) is 88's.

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-messaging` (`test/rsocket/` in the run).

Blast radius: under 03r-an (a) every `rakun-messaging` consumer loads `rakun-websocket`'s tree;
under (b) the core gains the extension point, `rakun-websocket` one registration.

`examples/rsocket-service-example.bp` kept for open markers (the byte gap — 346 —, lg2-b, the `await`-in-lambda rule by design).

### 150 s20 — the CLI (88)

#### Step 1 — `rakun run` (R88-1) (was `88-rakun-cli` s1)

- [ ] `run_test.bp`: the profile reaches the app (`GET /profile` answers `test`), the `#[config("rakun")]` record's `profiles` reflects it (299); `--port` wins over `RAKUN_SERVER_PORT` wins over `application.yaml` (three runs, three ports)
- [ ] `--watch`: editing the scaffold's handler changes the answer within 2 s; a connection opened before the edit still answers
- [ ] SIGTERM to the child: drain path runs (an in-flight request completes), exit code 0

#### Step 2 — Build and inspect (R88-2, R88-3, R88-4, R92-6) (was `88-rakun-cli` s2)

- [ ] `scaffold_test.bp`: a broken sidecar makes `rakun build` exit 1, printing 81's message unmodified
- [ ] `inspect_test.bp`: `rakun beans` prints one line per component with type and injected fields (`fixtures/` with a two-field component)
- [ ] two `rakun routes` runs started at once both exit 0, neither binds a port (`ss -ltn` through the sidecar shows no new listener during the run)
- [ ] `rakun routes` lists an rsocket route from 92's fixture beside the HTTP routes, labelled

#### Step 3 — `ws generate` and the boundary (93, R88-6) (was `88-rakun-cli` s3)

- [ ] `rakun ws generate fixtures/rates.wsdl out/` writes the files 93's generator produces, prints them, exits 0; a WSDL with a network `xsd:import` exits 1 with 93's refusal text
- [ ] the boundary table below is in `AGENTS.md` § CLI; R88-6 ticks when `07-onze/50-onze-cli/README.md` carries the mirror (onze's step — source is here)

| | `rakun` (this front) | `onze` (onze 50) |
|---|---|---|
| Project shape | a BEAM server: controllers, services, data | a full-stack app: routes, server components, a client bundle |
| `new` / `create` | `rakun new` — server only | `onze create` — server plus client |
| Dev loop | `rakun run --watch`, hot-loading BEAM modules | `onze dev` — the browser, the bundler, and rakun's run path underneath |
| Build | `rakun build` — an OTP release | `onze build` — the release plus the client bundle |
| Owns the browser | never | always |

#### Step 4 — R88-5 (was `88-rakun-cli` s4)

- [ ] R88-5 ("two commands claiming the same name fail at comptime, naming both declarations"): refused where the entry point builds the command table with `@TypeInfo.all(with: command)` (343); `command_decorator_test.bp`'s load-time refusal becomes that compile refusal, and the box ticks

#### Step 5 — configuration as a typed record (decision 299) (was `88-rakun-cli` s5)

- [ ] this member's `#[value("…")]` / `rkProp*` reads and group configs become `#[config("<prefix>")]` records (`04` step 7)

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-cli`.

Blast radius: manifest gains `rakun-client` (nothing depends on `rakun-cli`; update
[`../modules.md`](04-rakun/modules.md) in the same commit); `beans`' output gains a column — `inspect_test.bp` re-records.

### 150 s21 — test utilities' rest (19 s2–s7)

#### Step 2 — Context control (R19-1, R19-2; after 15 step 1) (was `19-rakun-test-utilities` s2)

- [ ] `context_test.bp`: `resetContext()` empties listener and task registries (via `contextSnapshot()`); a later dispatch is 404
- [ ] `contextSnapshot()` reports listener destinations from `rakun_listener_names`, stable across two runs

#### Step 3 — The broker double (R19-3, 03r-am) (was `19-rakun-test-utilities` s3)

- [ ] loader measurement recorded in the README (cycle refused or accepted); the double's location follows it
- [ ] `deliver(broker, destination, payload)` reaches a `#[listener]` handler with no broker configured; `published(broker)` lists every destination and payload sent through that arm's template, in order; `clearPublished()` empties it; two tests do not see each other's publishes
- [ ] `rakun-messaging/test/container_test.bp` runs through the double — one container cell rewritten to it, the rest already on the in-process broker

#### Step 4 — `bootAndExit` (R19-4; after 04 step 4) (was `19-rakun-test-utilities` s4)

- [ ] `test/boot_test.bp`: `bootAndExit(app)` on `fixtures/ok` exits `0`; on `fixtures/{missing-bean,cycle,dup-route,dup-listener,bad-cron,bad-config}` six distinct non-zero codes, each message naming the declaration
- [ ] no port bound (no listening socket opened during the run — `rakun-messaging`'s `rkListenerCount()` counts message listeners, not sockets), no broker connection attempted (in-process broker's connect count 0)
- [ ] `fixtures/fifty` boots and exits in under 2 s (`io.clock`)

#### Step 5 — The pairing and the example (R19-5, STD-2) (was `19-rakun-test-utilities` s5)

- [ ] `mocks_pairing_test.bp` uses `testing.mocks`'s `#[mock]` with `#[bean]` if std's `#[mock]` fires outside `mocks.bp` this milestone; otherwise README states the hand-written pairing, box stays open naming the std row
- [ ] `examples/controller-test-example.bp` imports nothing `from "onze"`; compiles against `rakun-test` + `testing.mocks`

#### Step 7 — rakun's own names (decision 318 (8)) (was `19-rakun-test-utilities` s7)

- [ ] `MockMvc` and the `@MockBean`-style override renamed after their role in botopink (front's choice,
      recorded in the member README — e.g. `TestClient`, a container override taking a `#[mocks.mock]`
      double); no Spring name or alias left in `rakun-test`'s public surface; 135's `assertResponse`
      follows the new name

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-test`.

Blast radius: step 1 adds a sidecar and `pub` functions, nothing existing changes; step 3 may add a
manifest edge (measured first); step 4 adds fixtures under `test/fixtures/` only.

### 150 s22 — middleware: `locals`, `sequence`, `actionContext` (123)

#### Step 0 — Measure (was `123-bpp-middleware` s0)

- [ ] request to a path with no route, and a failing page: does `#[middleware]` run, in what order vs the not-found and error boundaries
- [ ] two concurrent requests: a value set in one frame invisible in the other (shape of
      `bindingIsolated()`, `libs/validation/src/binding.bp:79-81`)

#### Step 1 — `locals` (was `123-bpp-middleware` s1)

- [ ] `examples/locals-and-sequence-example.bp` passes on erlang
- [ ] a local set in middleware is read by a page, a route handler and an action in the same
      request; `null` in the next request on the same process
- [ ] a page reading a local is not prerendered: its kind is `D`, its `why` says `locals`
      (`@typeInfo(Page).meta(PageMeta)`, 277; jhonstart's hook carries `#[serverOnly]`, 295)

#### Step 2 — `sequence` (was `123-bpp-middleware` s2)

- [ ] the reference's three-middleware example logs `validation request`, `auth request`,
      `greeting request`, `greeting response`, `auth response`, `validation response`
- [ ] a middleware answering without `next` stops the later ones

#### Step 3 — `nextBuffered` (was `123-bpp-middleware` s3)

- [ ] the reference's redaction example: every `PRIVATE INFO` in the markup replaced; headers are the page's
- [ ] the same request through `chain.next` still streams — asserted on the chunk count

#### Step 4 — `actionContext`, and middleware around 404 and 500 (was `123-bpp-middleware` s4)

- [ ] `actionContext` distinguishes an RPC call from a form post of the same action
- [ ] step 0's measurement becomes two tests; if middleware skips a 404 today, it runs after this step

#### Step 5 — route parameters and page data are hooks (decision 293) (was `123-bpp-middleware` s5)

- [ ] `locals-and-sequence-example.bp`: pages take no `route: PageContext`; parameters through `use params<P>()`, page data through `use pageData<D>()`

#### Step 6 — a cookie is declared once, typed (decision 294) (was `123-bpp-middleware` s6)

- [ ] middleware writes and clears through hooks over the declaration: `val setSession = use
      cookieSetter(sessionCookie); setSession(SessionId(value: t))`, `use cookieReset(sessionCookie)` (295;
      rakun's response, `http`'s `cookie.write`); the example's login middleware rewritten

#### Step 7 — locals are atoms (decision 295) (was `123-bpp-middleware` s7)

- [ ] cardume's `Atom<T>` (296) through `rakun-cardume` (`09-cardume/136` step 7): rakun's `use atomSetter(atom) -> fn(T)` (296) and jhonstart's `use atomValue(atom)` (296; the cookie hooks in the same family, 400);
      `LocalKey`, `setLocal(key, value)`, `local(key)` gone
- [ ] `#[middleware]` functions, route handlers and actions return `@Component<Response>` (354)
      (`rakun-web/src/middleware.bp`, `convention.bp`); a plain `-> Response` keeps working without `use`
- [ ] two atoms of one `T` are distinct; an unset atom reads `null`; values die with the request
- [ ] `examples/locals-and-sequence-example.bp` and `examples/src/app/orders/page.bpp` rewritten to atoms (the page reads `use local(currentUser)` through jhonstart's hook, never `import {local} from "rakun"` — 113, 295)

**Gate:** standard (fronts.md § Gate), plus:
- [ ] `botopink test --target erlang` green in `modules/rakun` and `modules/rakun-web`
- [ ] `zig build test-libs`: rakun, onze green; the blog's dashboard gate unchanged

### 150 s23 — actions typed by a schema (127)

#### Step 0 — Measure (was `127-bpp-actions` s0)

- [ ] how the browser learns an action's id — payload `a` key (`jhonstart/src/render.bp:479-523`)
      or hand-threaded (`07-onze/53/examples/new-post-form-example.bp:45`: `val createPostId = "a_9f31…"`)
- [ ] what a form post carries besides user fields, by name — the list `bind<T>` must not see

#### Step 1 — `ActionError` and the envelope's typed payload (decision 303) (was `127-bpp-actions` s1)

- [ ] `libs/actions/src/outcome.bp`, both targets: `ActionError` (the sum type above) and the `@Result<T, ActionError>` ↔ `{data}` / `{error}` codec; no `ActionOutcome`, no `ActionErrorCode`; it travels in the envelope's existing `payload` field, no reader changes
- [ ] an `Error(Input(fields))` written and read back keeps every path and message; each other case keeps its status and message
- [ ] a payload with both `data` and `error`, or neither, is refused by the reader (never decoded into a `@Result`)

#### Step 2 — `#[action]` and the wrapper (was `127-bpp-actions` s2)

- [ ] `examples/typed-action-example.bp` passes on erlang
- [ ] invalid input never reaches the function — asserted with a counter the function bumps
- [ ] `#[action]` on a function not returning `@Task<@Result<T, ActionError>>`, or naming a type
      that is not `#[validated]` (`@typeInfo(T).meta(Validated)`, 306), fails at the annotation
- [ ] the function answers with `return v` / `throw e`; `throw Input(…)` from the function itself is allowed (a check only the server can make, e.g. a taken e-mail)

#### Step 3 — The client call and the form binding (was `127-bpp-actions` s3)

- [ ] `callAction` over `jhonstart-dom-test`'s fake transport answers `@Task<@Result<T, ActionError>>`: `Ok`, `Error(Input)` and each other `Error` case decode to their variant
- [ ] a form bound with `formAction(ref)` submits without JavaScript; the next render's `actionResult(ref)` holds the outcome — `?@Result<T, ActionError>`, `null` until posted
- [ ] `fieldError(name)` (`libs/actions/src/state.bp:21`) answers the path's first message, so
      existing form components work over a typed action

#### Step 4 — `actionContext` for middleware (was `127-bpp-actions` s4)

- [ ] 123's `actionContext(req)` names a typed action and how it was called

#### Step 5 — references, not strings (decision 281) (was `127-bpp-actions` s5)

- [ ] `#[action]` without a string: input and output from the signature (280 (2)); `actionRef("…",
      schemaOf…, schemaOf…)` replaced by the function value; the wire id derived at comptime
- [ ] input and output are `#[validated]` types (decision 306) — no `Schema<T>`, no `schemaOf…()`;
      `Signup` / `Subscribed` in the examples drop `#[schema]` for `#[validated]`

#### Step 6 — a cookie is declared once, typed (decision 294) (was `127-bpp-actions` s6)

- [ ] an action sets or clears a cookie through hooks over its declaration (`use cookieSetter(decl)` → a
      setter, `use cookieReset(decl)`; 295), the attributes from the declaration; actions return
      `@Component<…>` (354) so they may `use`
- [ ] `typed-action-example.bp` reads the session with `use cookieValue(sessionCookie)` over a declared
      `Cookie<T>` (294), not `ctx.cookie("user-session")`

**Gate:** standard (fronts.md § Gate), plus:
- [ ] `botopink test` green on both targets in `libs/actions` and `jhonstart-forms`; on erlang in `rakun-app`
- [ ] `zig build test-libs`: rakun, jhonstart, onze green; `#[serverAction]`'s tests unchanged

### 150 s24 — rakun-test's `assertResponse` (135 s2)

#### Step 2 — rakun-test (390) (was `20-snap` s2)

- [ ] `assertResponse(loc, res)` over `MockMvc.perform`, one `.snap` (§ 2, KEEP — contract 7, 98 check (2))
- [ ] `rakun-test/AGENTS.md` states the member ships that helper only

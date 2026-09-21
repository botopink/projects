# Front 09 — Document and Key-Value Stores

**Track:** B rakun
**Priority:** low — an application can ship without a document store; it cannot ship without the SQL one. This front is breadth, not critical path
**Target:** erlang (server)
**Wave:** 4
**Depends on:** 07 · 08
**Owns:** `modules/rakun-data/src/nosql/**` · `modules/rakun-data/test/nosql/**`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` — frozen · `modules/rakun-data/src/sql/**` and `datasource.bp`, which are front 08's (consumed read-only) · `modules/rakun-data/src/migration/**` (77) and `src/orm/**` (78)
**Reference:** `05-data.md § Bancos NoSQL` — Redis, MongoDB, Neo4j, Elasticsearch, Cassandra, Couchbase, LDAP · <https://docs.spring.io/spring-boot/reference/data/nosql.html>
**Replaces:** `1.0.6-beta/17-data-nosql`

---

## Problem

Front 08 gives rakun a relational connection. A great deal of what a web application actually stores is
not relational: a session, a rate-limit counter, a rendered fragment, a user profile document, a
search index. Today none of it has a home, and the workaround is the same one front 08 replaced —
an array in a component.

There is one thing this front has that no other data front has, and it is worth saying before the
list of drivers: **the BEAM already ships two stores**. ETS is an in-memory key-value and set store in
`erts`, and Mnesia is a distributed, optionally disk-backed, transactional store in OTP. Neither needs
a driver, a socket, a container or a CI service. A rakun application can have a real key-value store
and a real replicated document store with no dependency at all, and every other arm in this front is
an option on top of that rather than the price of entry.

## Current state

| Piece | Where | State |
|---|---|---|
| `DataSource` / `Connection` behaviors | front 08's `modules/rakun-data/src/datasource.bp` | consumed read-only; declared generic over SQL and non-SQL arms |
| `SqlTemplate`, pooling, `#[query]` shape | front 08 | the pattern this front follows |
| ETS | `erts`; `libs/std/src/beam.bp:83-95` exposes `etsNew`/`etsGet`/`etsPut`/`etsBump` as `any` | available; this front wraps it in a typed store |
| Mnesia | OTP `mnesia` application | available, unused by anything in the repository |
| `eredis`, `mongodb-erlang`, Cassandra and Couchbase drivers | — | third-party OTP applications, not in the distribution |
| Elasticsearch | HTTP + JSON | reachable through front 13's HTTP client — **no driver needed** |
| `modules/rakun-data/src/nosql/` | — | does not exist |

## Mechanism

### Two behaviors, many arms

```bp
pub behavior KeyValueStore {
    fn get(self: Self, key: string) -> ?string;
    fn put(self: Self, key: string, value: string) -> i32;
    fn putExpiring(self: Self, key: string, value: string, ttlSeconds: i32) -> i32;
    fn remove(self: Self, key: string) -> i32;
    fn increment(self: Self, key: string, by: i32) -> i32;
    fn fieldGet(self: Self, key: string, field: string) -> ?string;
    fn fieldPut(self: Self, key: string, field: string, value: string) -> i32;
    fn pushLeft(self: Self, key: string, value: string) -> i32;
    fn popRight(self: Self, key: string) -> ?string;
    fn ttl(self: Self, key: string) -> i32;
}

pub behavior DocumentStore {
    fn insert(self: Self, collection: string, id: string, doc: string) -> i32;
    fn findById(self: Self, collection: string, id: string) -> ?string;
    fn find(self: Self, collection: string, filter: string) -> string[];
    fn replace(self: Self, collection: string, id: string, doc: string) -> i32;
    fn remove(self: Self, collection: string, id: string) -> i32;
    fn count(self: Self, collection: string, filter: string) -> i32;
}
```

Documents are JSON **strings** in and out. std's `json` has no structured value
([`language-gaps.md`](../../language-gaps.md), *A std JSON walker*), so a typed document model cannot be
built in botopink today and building half of one here would collide with front 78's `#[entity]`. A
filter is a JSON string too, in the store's own dialect, and the store is responsible for translating
it — which for Mongo means passing it through and for ETS means parsing the equality subset.

`get`, `findById` and `popRight` return `?string`; every mutating call returns the number of documents
or keys it touched, so a caller can tell "removed nothing" from "removed one" without an
`@Result`. Driver failures **raise**, the way front 08's `query` does, and front 07's error entry
turns the raise into a 500 problem detail. Each behavior has a `try*` twin for the caller who wants to
branch; the reason for the doubled surface is the `@Result`-forwarding gap recorded in
[`language-gaps.md`](../../language-gaps.md).

### The arms, in the order they should be built

| Arm | URL | Dependency | Priority |
|---|---|---|---|
| **ETS** | `ets:memory` | none — `erts` | first; the default under the `test` profile |
| **Mnesia** | `mnesia:local` / `mnesia:cluster` | none — OTP | second; the only arm with transactions and replication out of the box |
| **Redis** | `redis://…` | `eredis` | third; what most applications actually deploy |
| **MongoDB** | `mongodb://…` | `mongodb-erlang` | fourth |
| **Elasticsearch** | `https://…` | none — front 13's HTTP client | fifth; cheapest of the four "lowest priority" arms because it is HTTP and JSON |
| Neo4j | `bolt://…` | Bolt protocol client | last four, in this order |
| Cassandra | `cassandra://…` | CQL driver | |
| Couchbase | `couchbase://…` | Couchbase SDK | |

The last four are the fold-in the audit assigned here and they are explicitly the **lowest priority
work in the front**. Elasticsearch is first among them and should be built even if the other three are
cut, because it costs an HTTP client and a JSON body and nothing else.

A configured driver whose module is not loadable is a **boot failure naming the driver**, never a
fallback to ETS — the same rule front 08 sets for SQL, and for the same reason: a test suite silently
running against an in-memory store that does not behave like the real one is worse than a suite that
will not start.

### ETS and Mnesia are not mocks

The ETS arm is a real key-value store with real TTL (a sweeper process expiring keys on a timer) and
real hash and list operations. The Mnesia arm is a real document store: `disc_copies` tables, a
transaction per write, and `mnesia:add_table_copy/3` when the node joins a cluster. Neither is a test
double, and the README says so because "in-memory store" usually means "fake". What they are not is
Redis- or Mongo-compatible on the wire; an application that needs `SCAN` cursors or an aggregation
pipeline needs the real thing.

The filter dialect the ETS and Mnesia arms accept is stated exactly: a flat JSON object of
field/value equality pairs, optionally with `$in`, `$gt`, `$lt` and `$exists`. Anything else fails
naming the operator, instead of matching everything or nothing.

### The repository shape, inherited from front 08

`#[documentQuery("…")]` is the same shape front 08 decided for `#[query]`, for the same reason — a
bodyless method in a `type` body does not parse ([`language-gaps.md`](../../language-gaps.md)) — and with
the same emission:

```bp
#[repository]
#[managed]
pub type ProfileRepository(docs: DocumentStore) {
    #[documentQuery("{\"email\": \":email\"}")]
    pub fn findByEmail(self: Self, email: string) -> ?string {
        return self.docs.find("profiles", bind(__rkQuery_findByEmail(), [param("email", email)])).first();
    }
}
```

It is a separate decorator from `#[query]` only because the conflict rule in
[`fronts.md`](../../fronts.md) gives this front no access to `modules/rakun-data/src/sql/**`. If that
boundary is ever relaxed, the two collapse into one decorator with a dialect argument, and this README
should be the thing that gets deleted.

`:name` placeholders are bound by `bind(template, params)`, which **escapes the value for the
store's dialect** — JSON string escaping for Mongo and the ETS/Mnesia arms, URI and JSON escaping for
Elasticsearch. String-concatenating a filter is the NoSQL injection, and the shape exists to make it
awkward: the template is a literal by construction, exactly as in front 08.

### Pooling

One supervised connection process per arm instance, pooled by front 08's `rakun_pool_sup` shape — the
pool is generic over what a connection process wraps, which is why `datasource.bp` is consumed
read-only rather than copied. ETS and Mnesia need no pool at all: an ETS read is a direct memory read
from the calling process, so the arm returns a zero-cost handle and the pool is bypassed. That is
stated rather than hidden, because "pool size" on an ETS store is a meaningless knob and configuring
it should say so.

### Health and metrics

`#[healthIndicator("redis")]`, `#[healthIndicator("mongo")]`, `#[healthIndicator("mnesia")]`, imported
from front 11's dependency-free `rakun-actuator-api` module — one per
configured arm, registered with front 11 through the contract front 11 defines. Front 09 ships its own
indicators; the indicator list is not front 11's work.

### Redis pub/sub

`#[redisListener("channel")]` is **front 15's**, as an arm on the listener registry. Front 09 delivers
the connection and the commands; it does not grow a second listener mechanism.

## Steps

### Step 1 — The two behaviors and the ETS arm

**Acceptance:**
- [ ] `KeyValueStore` and `DocumentStore` behaviors are declared and `rakun.nosql.url` selects an arm
- [ ] An unknown scheme fails at boot naming the value; a known scheme with an unloadable driver fails naming the driver
- [ ] The ETS arm passes the whole behavior suite
- [ ] `putExpiring` with a 1-second TTL is gone after 2 seconds and `ttl` reports the remaining time before that
- [ ] `increment` on an absent key starts at 0 and answers `by`
- [ ] `popRight` on an empty list answers `null`, not `""`
- [ ] Two test blocks do not see each other's keys

### Step 2 — The Mnesia arm

**Acceptance:**
- [ ] A document written in one transaction and a raise in the same transaction leaves nothing behind
- [ ] `disc_copies` survives a node restart within one test run
- [ ] A second node joining the cluster sees the existing documents
- [ ] The supported filter subset (`equality`, `$in`, `$gt`, `$lt`, `$exists`) works; anything else fails naming the operator

### Step 3 — Redis

**Acceptance:**
- [ ] Every `KeyValueStore` method maps to the documented Redis command
- [ ] `fieldGet`/`fieldPut` use hashes, `pushLeft`/`popRight` use lists
- [ ] A connection lost mid-call is retried once and then raises
- [ ] The `redis` health indicator answers `UP` on a reachable server and `DOWN` with the reason otherwise
- [ ] With `RAKUN_TEST_REDIS_URL` unset, the suite reports *skipped* in one line rather than passing vacuously

### Step 4 — MongoDB

**Acceptance:**
- [ ] `insert`, `findById`, `find`, `replace`, `remove` and `count` all work against a real server
- [ ] A filter built with `bind` escapes a value containing `"` and `}` so it stays a value
- [ ] `find` on a collection that does not exist answers an empty list rather than raising
- [ ] Opt-in suite, gated on `RAKUN_TEST_MONGO_URL`

### Step 5 — `#[documentQuery]`

**Acceptance:**
- [ ] It emits `__rkQuery_<name>()` returning the template verbatim and registers it
- [ ] An empty template, and a template whose braces do not balance, each fail the build with a located message
- [ ] `bind` escapes every parameter for the target dialect; a value containing the dialect's quote character round-trips
- [ ] `#[documentQuery]` on a non-method fails at comptime
- [ ] The registered templates appear in the same inventory front 08's statements do

### Step 6 — Elasticsearch, over front 13

**Acceptance:**
- [ ] `index`, `get`, `search` and `delete` work against a real cluster
- [ ] Requests go through front 13's client, so its timeouts, TLS bundle (front 74) and SSRF address filter all apply
- [ ] A 4xx from the cluster raises with the cluster's own error body, not a generic message
- [ ] No third-party OTP application is required

### Step 7 — Neo4j, Cassandra, Couchbase

The three remaining arms, in that order, and the first three things to cut if the front runs long.

**Acceptance:**
- [ ] Each implements the behavior it fits (`DocumentStore` for Couchbase, a store-specific query call for Neo4j and Cassandra)
- [ ] Each ships a health indicator
- [ ] Each opt-in suite is gated on its own environment variable and reports *skipped* when unset
- [ ] A store whose semantics do not fit the behavior says so in its README section instead of pretending — Neo4j's graph queries are not `find(collection, filter)`

## Examples

- [`examples/stores-example.bp`](./examples/stores-example.bp) — a developer using both behaviors in
  one application: a session counter in the key-value store and a user profile in the document store,
  with the repository shape front 08 decided, and ETS selected automatically under the `test` profile.

## Language gaps

None new. This front is bitten by three already recorded in
[`language-gaps.md`](../../language-gaps.md), and the example marks the lines:

- **No bodyless method in a `type` body** — decides the `#[documentQuery]` shape, exactly as it decides
  front 08's `#[query]`.
- **A std JSON walker does not exist** — decides that documents are strings and that there is no typed
  document model in this front.
- **A function cannot forward a `@Result`** — decides the doubled raising / `try*` surface.

## Test plan

`modules/rakun-data/test/nosql/` — `keyvalue_test.bp`, `document_test.bp`, `query_decorator_test.bp`,
`arms_test.bp` — run with `botopink test --target erlang` from `modules/rakun-data/` and in the gate
through `zig build test-libs -- --target erlang`. The module manifest is front 08's and declares
`"target": "erlang"`, so the commonJS cell reports *skipped*.

The behavior suite is written **once** and run against every arm that is available, which is the point
of having two behaviors rather than six templates: `keyvalue_test.bp` takes the store as a parameter
and the arm table decides which instantiations run. ETS and Mnesia always run; Redis, Mongo,
Elasticsearch, Neo4j, Cassandra and Couchbase each run only when their environment variable is set and
otherwise report *skipped* with the variable's name in the line, so a developer can see what was not
covered rather than reading a green run as full coverage.

## Adjacent fronts

- **08-rakun-data-sql** owns `datasource.bp`, the pool shape and the `#[query]` precedent; this front
  consumes all three and copies none.
- **12-rakun-cache** is the layer above: a cache is a key-value store with an eviction policy and a key
  protocol. Front 12 uses this front's `KeyValueStore` rather than opening its own Redis connection.
- **18-rakun-session** stores sessions through this front's key-value behavior.
- **15-rakun-messaging** owns `#[redisListener]`.
- **13-rakun-http-clients** is what the Elasticsearch arm is built on.
- **11-rakun-actuator** hosts the health endpoint; this front ships one indicator per configured arm.
- **78-rakun-orm-entities** owns typed mapping; when it lands, a document store should gain the same
  `#[entity]` surface rather than a second one here.

## Contradictions with fronts.md

1. The ownership row does not name a sidecar. The arms live in
   `modules/rakun-data/src/sidecars/rakun_nosql.erl`; it must be allocated to this front or it cannot
   ship.
2. **Resolved:** `modules/rakun-data/src/root.bp` belongs to **front 08**, the lowest-numbered front
   in that module, and this front appends its `pub mod nosql;` line in front-number order without
   reordering anything. The two fronts land in different waves, so the append is the whole of the
   interaction.

## Definition of done

- [ ] `modules/rakun-data/src/nosql/**` exists with both behaviors, the ETS and Mnesia arms, and the
      sidecar
- [ ] The behavior suite is written once and runs against every available arm
- [ ] An unavailable driver fails at boot instead of falling back
- [ ] `#[documentQuery]` follows front 08's shape exactly, and `bind` escapes for the target dialect
- [ ] Every configured arm registers a health indicator with front 11
- [ ] Opt-in suites report *skipped* with the missing variable named
- [ ] `repository/rakun/AGENTS.md` documents the arm table and the supported filter subset
- [ ] The front's tests are green on its assigned target

## Carried from 1.0.6-beta F17 data-nosql

Items in `specs/1.0.6-beta/17-data-nosql/README.md` with no counterpart above. Covered and not repeated:
Redis commands (`get`/`set`/`setEx`/`del`/`hGet`/`hSet`/`lPush`/`lPop` → `get`/`put`/`putExpiring`/`remove`/
`fieldGet`/`fieldPut`/`pushLeft`/`popRight`), `insert`/`find`/`findById` on documents, Elasticsearch
`index`/`get`/`search`/`delete` over HTTP (Step 6), `eredis` and `mongodb` drivers, health per arm,
"Reactive variants: separate front" → `04-rakun-erlang-runtime § One statement about reactive`.

| Item | 1.0.6 text | Status |
|---|---|---|
| Update / delete by filter | `pub fn update(self: Self, collection: string, query: string, update: string);` and `pub fn delete(self: Self, collection: string, query: string);` on `MongoTemplate` (Step 1) | absent: `DocumentStore` has `replace(collection, id, doc)` and `remove(collection, id)` — by id only; no partial update, no multi-document mutation by filter |
| Typed document API | `insert<T>(collection, doc: T)`, `find<T>(...) -> Array<T>`, `findById<T>(...) -> ?T`, `index<T>`, `get<T>`, `search<T>` | superseded by: *Two behaviors, many arms* (documents are JSON strings; std JSON walker gap) |
| Per-store configuration | `#[value("spring.mongodb.uri")] uri`, `#[value("spring.redis.host")] host` + `.port`, `#[value("spring.elasticsearch.uris")] uris` — three templates, three key sets, all live at once | absent: above, `rakun.nosql.url` "selects **an** arm" (singular); no key shape lets one application hold a Redis key-value store and a Mongo document store simultaneously, which the draft's per-template `#[value]` keys did |
| Redis Cluster | Step 2: "Erlang: use `eredis` or `eredis_cluster`." | absent: no cluster-mode client is named in any 1.0.9 rakun front |
| Positional query placeholder | `#[query("{email: $1}")]` on `UserRepository(template: MongoTemplate)` (Step 4) | superseded by: *The repository shape* (`#[documentQuery]` with `:name` placeholders and `bind`) |
| Node drivers | Notes: "`mongodb` (Node.js)", "`ioredis` (Node.js)", "HTTP REST API (both targets)"; Gate: both targets | superseded by: *Test plan* (manifest `"target": "erlang"`, commonJS cell skipped) |
| Module layout | Step 5 tree, below | absent: above names `src/nosql/**` and a `sidecars/rakun_nosql.erl` but no per-arm file names |

Step 5 — Module structure (verbatim):

```
modules/rakun-data/
└── src/
    └── nosql/
        ├── mongo_template.bp
        ├── redis_template.bp
        └── elasticsearch_template.bp
```

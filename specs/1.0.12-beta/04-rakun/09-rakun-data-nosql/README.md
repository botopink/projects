# Front 09 — Document and key-value stores

**Priority:** low — breadth; an application ships without a document store ·
**State:** not started (`modules/rakun-data/src/nosql/` does not exist)
**Depends on:** 128 · 19 step 1 (Redis RESP double — decision 160) · 13 (Elasticsearch arm via
`rakun-client` and 13's in-process HTTP double) · 03r-ab (four-arm scope; this README follows (a), only the record is missing) · lg2-a (the four
binary-protocol stores)
**Owns:** `modules/rakun-data/src/nosql/**`, `src/nosql_host.bp`, `src/sidecars/rakun_nosql.erl`,
`test/nosql/**`; appends to `modules/rakun-data/botopink.json` `files` and `src/root.bp` (08 does not
edit them this milestone) · `repository/rakun/AGENTS.md` § NoSQL
**Does not touch:** `datasource.bp`, `src/sql/**`, `src/orm/**`, `src/migration/**` (08's, read-only) ·
`rakun-test` (imports the double) · `rakun-client`

## Goal

`rakun-data` gains `KeyValueStore` and `DocumentStore`: four arms in the gate — ETS, Mnesia, Redis
(on the double), Elasticsearch (on an HTTP double) — and four recognised schemes refusing the boot
naming the gap (03r-ab (a)). The closed front's 41 boxes, narrowed by 03r-ab: closed step 3's
fifth box ("with `RAKUN_TEST_REDIS_URL` unset, the suite reports *skipped*") and the DoD's "opt-in
suites report *skipped*" deleted; closed steps 4 and 7 (Mongo; Neo4j, Cassandra, Couchbase) become
step 5's refusal cells + one `deferred.md` row each.

## Mechanism

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

Documents and filters are JSON strings; `get` / `findById` / `popRight` answer `?string`; mutators
answer a count. Under decision 304 every method answers `@Result<…, StoreError>` (08's `StoreError`) — no raise on a driver failure, no `try*` twin; the signatures above are the pre-304 shapes, rewritten in step 6.

| Arm | URL | In the gate | How |
|---|---|---|---|
| ETS | `ets:memory` | yes | `rakun_nosql.erl`: one table per store, a TTL sweeper; default under the `test` profile. std's `etsNew` / `etsGet` / `etsPut` / `etsBump` (`beam.bp`) are typed `unknown` |
| Mnesia | `mnesia:local` · `mnesia:cluster` | yes | `disc_copies` under `BOTOPINK_TEST_TMPDIR`, a transaction per write, `add_table_copy` on join; the two-node box runs two sidecar-started `peer` nodes, or is reworded to the single-node `add_table_copy` path if `peer` cannot start under the runner |
| Redis | `redis://…` | yes | RESP over `gen_tcp` (`rkSessRedis` wire of `rakun-session/src/store_redis.bp` lifted into `nosql/redis.bp`); suite connects to `rakun-test`'s double on a loopback port |
| Elasticsearch | `https://…` | yes | `rakun-client`; suite against 13's HTTP double answering the `_doc` and `_search` shapes |
| MongoDB · Neo4j · Cassandra · Couchbase | `mongodb://` · `bolt://` · `cassandra://` · `couchbase://` | refusal cell | recognised scheme; boot refusal names lg2-a and the driver the sidecar cannot load; one `deferred.md` row each |

- A configured driver whose module cannot load fails the boot naming it — never an ETS fallback.
- ETS / Mnesia filter dialect exact: flat JSON object of equality pairs with `$in`, `$gt`, `$lt`,
  `$exists`; anything else fails naming the operator.
- `#[documentQuery("…")]` — **open: `erk-b`** (313 deleted `#[query]`'s shape for SQL; recommended: the same
  `#[repository] behavior` shape, the string handed to the store as `#[nativeQuery]` hands SQL). Until answered it
  follows `#[query]`'s post-130 shape (decision 216): writes a member of the
  annotated repository type answering the template verbatim (as `#[query]` writes
  `<Repo>.<m>Sql()`), registers it in 08's statement inventory as `#[query]` does (load-time
  registration today, the boot's `@TypeInfo.all` catalogue once 130 lands);
  `bind(template, params)` escapes for the target dialect.
- Pooling reuses 08's `rakun_pool_sup`; ETS and Mnesia bypass it and say so when a pool size is
  configured. Each configured arm registers a `#[healthIndicator]` through the core's
  `actuator_api`. `#[redisListener]` is 15's.

**Open point (`ctr-w`):** `rakun-data` depends on `rakun`, `rakun-actuator` only; the Elasticsearch
arm over `rakun-client` adds a `rakun-data → rakun-client` edge every data consumer loads — the
kind decision 185 refuses. Measured first, reported before adding the edge (answered in 03r-ab's arm list).

No cell env-gated or *skipped*; refusal cells are green, asserting the refusal text.

## Open

### Step 1 — The two behaviors and the ETS arm

- [ ] `KeyValueStore`, `DocumentStore` declared in `src/nosql/mod.bp`; `rakun.nosql.url` selects an arm at boot
- [ ] unknown scheme fails at boot naming the value; known scheme with unloadable driver fails naming the driver
- [ ] `test/nosql/keyvalue_test.bp` and `document_test.bp` (store as a parameter) pass on the ETS arm
- [ ] `putExpiring` with 1-second TTL gone after 2 seconds, `ttl` reports remaining time before that (sweeper on a 100 ms tick under test)
- [ ] `increment` on an absent key starts at 0 and answers `by`
- [ ] `popRight` on an empty list answers `null`, not `""`
- [ ] two test blocks do not see each other's keys

### Step 2 — The Mnesia arm

- [ ] a document written in one transaction plus an `Error` returned in it leaves nothing behind
- [ ] `disc_copies` survives a node restart within one run (sidecar stops and restarts `mnesia` on the same directory)
- [ ] a second node joining sees the existing documents — over `peer`; or, if the runner cannot start a peer, reworded to the `add_table_copy` call issued and its result asserted, README says why
- [ ] the supported filter subset works; anything else fails naming the operator

### Step 3 — Redis and Elasticsearch, against the doubles

- [ ] every `KeyValueStore` method maps to the documented Redis command, asserted on the double's command log
- [ ] `fieldGet` / `fieldPut` use hashes, `pushLeft` / `popRight` lists
- [ ] a connection lost mid-call (`redisDoubleFail`) retried once, then answers `Error(Unavailable(…))`
- [ ] `redis` health indicator `UP` against the double, `DOWN` with the reason when the port is closed
- [ ] `index`, `get`, `search`, `delete` go through `rakun-client`; the HTTP double records paths and bodies; timeouts, the bundle and the SSRF filter apply (one negative test each)
- [ ] a 4xx from the double answers an `Error` carrying the double's error body, not a generic message
- [ ] no third-party OTP application required (manifest and sidecar list prove it)

### Step 4 — `#[documentQuery]` (its shape: `erk-b`)

- [ ] writes the repository member answering the template verbatim (named as `#[query]`'s) and registers it
- [ ] empty template, and one with unbalanced braces, each fail the build with a located message (`test/nosql/query_build_test.bp` over a scratch project under `BOTOPINK_TEST_TMPDIR`)
- [ ] `bind` escapes every parameter for the dialect; a value containing the dialect's quote round-trips
- [ ] `#[documentQuery]` on a non-method fails at comptime
- [ ] registered templates appear in 08's statement inventory

### Step 5 — The refusal cells (03r-ab (a))

- [ ] `mongodb://`, `bolt://`, `cassandra://`, `couchbase://` each refuse the boot naming scheme, driver and lg2-a — four cells in `test/nosql/arms_test.bp`
- [ ] four `deferred.md` rows, each naming its box list and the unblocking gap
- [ ] member README's arm table says which arms run and which refuse

### Step 6 — one API answering `@Result<T, StoreError>` (decision 304; after 08 step 6)

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

## Notes

- `examples/stores-example.bp` (closed front's example) kept whole: the front is all open and it is the consumer surface.
- Under 03r-ab (b) each binary protocol is its own front; this README gains a row per arm, not the boxes.

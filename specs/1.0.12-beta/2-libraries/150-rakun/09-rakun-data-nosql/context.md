# Front 09 — Document and key-value stores

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [150-rakun](../README.md): s1 → 150 s17 · s2 → 150 s17 · s3 → 150 s17 · s4 → 150 s17 · s5 → 150 s17 · s6 → 150 s17. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** low — breadth; an application ships without a document store ·
**State:** not started (`modules/rakun-data/src/nosql/` does not exist)
**Depends on:** 128 · 19 step 1 (Redis RESP double — decision 160) · 13 (Elasticsearch arm via
`rakun-client` and 13's in-process HTTP double) · 03r-ab (four-arm scope; this README follows (a), only the record is missing) · 346's `Bytes`, unbuilt
(the four binary-protocol stores, with their drivers)
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
| MongoDB · Neo4j · Cassandra · Couchbase | `mongodb://` · `bolt://` · `cassandra://` · `couchbase://` | refusal cell | recognised scheme; boot refusal names the driver the sidecar cannot load; one `deferred.md` row each |

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

## Notes

- `examples/stores-example.bp` (closed front's example) kept whole: the front is all open and it is the consumer surface.
- Under 03r-ab (b) each binary protocol is its own front; this README gains a row per arm, not the boxes.

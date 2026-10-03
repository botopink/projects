# Front 09 — Document and key-value stores

**Priority:** low — an application ships without a document store; the front is breadth ·
**State:** not started (`modules/rakun-data/src/nosql/` does not exist)
**Depends on:** 128 · 19 step 1 (the Redis RESP double — decision 160) · 13 (the Elasticsearch arm
goes through `rakun-client` and 13's in-process HTTP double) · 03r-ab (the four-arm scope) · lg2-a (the
four binary-protocol stores)
**Owns:** `modules/rakun-data/src/nosql/**`, `src/nosql_host.bp`, `src/sidecars/rakun_nosql.erl`,
`test/nosql/**`; appends to `modules/rakun-data/botopink.json` `files` and `src/root.bp` (08 does not
edit them this milestone) · `repository/rakun/AGENTS.md` § NoSQL
**Does not touch:** `datasource.bp`, `src/sql/**`, `src/orm/**`, `src/migration/**` (08's, read-only) ·
`rakun-test` (imports the double) · `rakun-client`

## Goal

`rakun-data` gains a `KeyValueStore` and a `DocumentStore` with four arms that run in the gate —
ETS, Mnesia, Redis (against the double), Elasticsearch (against an HTTP double) — and four
recognised schemes that refuse the boot naming the gap (03r-ab (a)). The whole closed front, its
41 boxes narrowed by 03r-ab: the closed step 3's fifth box ("with `RAKUN_TEST_REDIS_URL` unset, the
suite reports *skipped*") and the DoD's "opt-in suites report *skipped*" are deleted; the closed
steps 4 and 7 (Mongo; Neo4j, Cassandra, Couchbase) become step 5's refusal cells and one
`deferred.md` row each.

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

Documents and filters are JSON strings; `get` / `findById` / `popRight` answer `?string`; mutating
calls answer a count; driver failures raise, as 08's `query` does, with a `try*` twin each.

| Arm | URL | In the gate | How |
|---|---|---|---|
| ETS | `ets:memory` | yes | `rakun_nosql.erl`: one table per store, a sweeper for TTL; the default under the `test` profile. std's `etsNew` / `etsGet` / `etsPut` / `etsBump` (`beam.bp`) are typed `unknown` |
| Mnesia | `mnesia:local` · `mnesia:cluster` | yes | `disc_copies` under `BOTOPINK_TEST_TMPDIR`, a transaction per write, `add_table_copy` on join; the two-node box runs two `peer` nodes started by the sidecar, or is reworded to the single-node `add_table_copy` path if `peer` cannot start under the runner |
| Redis | `redis://…` | yes | RESP over `gen_tcp` (the `rkSessRedis` wire of `rakun-session/src/store_redis.bp` lifted into `nosql/redis.bp`); the suite connects to `rakun-test`'s double on a loopback port |
| Elasticsearch | `https://…` | yes | `rakun-client`; the suite runs against 13's HTTP double answering the `_doc` and `_search` shapes |
| MongoDB · Neo4j · Cassandra · Couchbase | `mongodb://` · `bolt://` · `cassandra://` · `couchbase://` | refusal cell | a recognised scheme whose boot refusal names lg2-a and the driver the sidecar cannot load; one `deferred.md` row each |

A configured driver whose module cannot load is a boot failure naming the driver — never a fallback
to ETS. The ETS / Mnesia filter dialect is exact: a flat JSON object of equality pairs with `$in`,
`$gt`, `$lt`, `$exists`; anything else fails naming the operator. `#[documentQuery("…")]` follows
`#[query]`'s post-130 shape (decision 216): it writes a member of the annotated repository type
answering the template verbatim — as `#[query]` writes `<Repo>.<m>Sql()` — and registers it in 08's
statement inventory the way `#[query]` registers (a load-time registration today, the boot's
`@TypeInfo.all` catalogue once 130 lands it); `bind(template, params)` escapes for the target dialect.
Pooling reuses 08's `rakun_pool_sup`; ETS and Mnesia bypass it and say so when a pool size is
configured. Each configured arm registers a `#[healthIndicator]` through the core's `actuator_api`.
`#[redisListener]` is 15's.

**Open point (no decision):** `rakun-data` depends on `rakun` and `rakun-actuator` only; the
Elasticsearch arm over `rakun-client` adds a `rakun-data → rakun-client` edge every data consumer
loads — the kind of edge decision 185's rule refuses. The front measures it first and reports to
the maintainer before adding the edge (03r-ab's arm list is where it is answered).

No cell is env-gated or reports *skipped*; the refusal cells are green, asserting the refusal text.

## Open

### Step 1 — The two behaviors and the ETS arm

- [ ] `KeyValueStore` and `DocumentStore` are declared in `src/nosql/mod.bp` and `rakun.nosql.url` selects an arm at boot
- [ ] an unknown scheme fails at boot naming the value; a known scheme with an unloadable driver fails naming the driver
- [ ] `test/nosql/keyvalue_test.bp` and `document_test.bp` — the suite takes the store as a parameter — pass on the ETS arm
- [ ] `putExpiring` with a 1-second TTL is gone after 2 seconds and `ttl` reports the remaining time before that (the sweeper on a 100 ms tick under test)
- [ ] `increment` on an absent key starts at 0 and answers `by`
- [ ] `popRight` on an empty list answers `null`, not `""`
- [ ] two test blocks do not see each other's keys

### Step 2 — The Mnesia arm

- [ ] a document written in one transaction and a raise in the same transaction leaves nothing behind
- [ ] `disc_copies` survives a node restart within one test run (the sidecar stops and restarts `mnesia` on the same directory)
- [ ] a second node joining the cluster sees the existing documents — over `peer`; or, if the runner cannot start a peer, the box is reworded to the `add_table_copy` call being issued and its result asserted, and the README says why
- [ ] the supported filter subset works; anything else fails naming the operator

### Step 3 — Redis and Elasticsearch, against the doubles

- [ ] every `KeyValueStore` method maps to the documented Redis command, asserted on the double's command log
- [ ] `fieldGet` / `fieldPut` use hashes, `pushLeft` / `popRight` use lists
- [ ] a connection lost mid-call (`redisDoubleFail`) is retried once and then raises
- [ ] the `redis` health indicator answers `UP` against the double and `DOWN` with the reason when the port is closed
- [ ] `index`, `get`, `search` and `delete` go through `rakun-client` and the HTTP double records the paths and bodies; timeouts, the bundle and the SSRF filter apply (one negative test each)
- [ ] a 4xx from the double raises with the double's error body, not a generic message
- [ ] no third-party OTP application is required (the manifest and the sidecar list prove it)

### Step 4 — `#[documentQuery]`

- [ ] it writes the repository member answering the template verbatim (named as `#[query]`'s member is) and registers it
- [ ] an empty template, and one whose braces do not balance, each fail the build with a located message (`test/nosql/query_build_test.bp` over a scratch project under `BOTOPINK_TEST_TMPDIR`)
- [ ] `bind` escapes every parameter for the target dialect; a value containing the dialect's quote character round-trips
- [ ] `#[documentQuery]` on a non-method fails at comptime
- [ ] the registered templates appear in 08's statement inventory

### Step 5 — The refusal cells (03r-ab)

- [ ] `mongodb://`, `bolt://`, `cassandra://`, `couchbase://` each refuse the boot with a message naming the scheme, the driver and lg2-a — four cells in `test/nosql/arms_test.bp`
- [ ] four `deferred.md` rows, each naming the box list it holds and the gap that unblocks it
- [ ] the member README's arm table says which arms run and which refuse

**Gate:** standard (fronts.md § Gate) +
- [ ] `botopink test --target erlang` green in `modules/rakun-data`, the `nosql/` files in the run; `botopink format --check` clean
- [ ] every configured arm registers a health indicator (asserted through the core's `actuator_api` registry)
- [ ] `AGENTS.md` § NoSQL documents the arm table and the filter subset; `modules/README.md` row updated

Blast radius: `nosql/*` appended to `rakun-data`'s `files` and `src/root.bp` after 08's lines; no
existing test changes. `rakun-session` and `rakun-cache` keep their own Redis wires this milestone.

## Notes

- `examples/stores-example.bp` is the closed front's example, kept whole: the front is entirely
  open and the example is its consumer surface.
- Under 03r-ab (b) each binary protocol is a front of its own and this README gains a row per arm,
  not the boxes.

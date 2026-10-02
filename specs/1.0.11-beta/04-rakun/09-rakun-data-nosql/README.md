# Front 09 — Document and Key-Value Stores

**Priority:** low — an application ships without a document store; the front is breadth. It is the one rakun front with nothing on disk
**Carries:** — (the whole 1.0.10 front, 41 boxes, narrowed by 03r-ab)
**Depends on:** `128-rakun-consolidation` · `19-rakun-test-utilities` step 1 (the Redis RESP double — decision 160) · `13-rakun-http-clients` (the Elasticsearch arm goes through `rakun-client`; the in-process HTTP double 13's tests already use) · maintainer 03r-ab (the four-arm scope) · compiler lg2-a (the four binary-protocol stores)
**Owns:** `modules/rakun-data/src/nosql/**`, `src/nosql_host.bp`, `src/sidecars/rakun_nosql.erl`, `test/nosql/**`; appends its lines to `modules/rakun-data/botopink.json` `files` and `src/root.bp` (08 does not edit them this milestone) · `repository/rakun/AGENTS.md` § NoSQL
**Does not touch:** `datasource.bp`, `src/sql/**`, `src/orm/**`, `src/migration/**` (08's, consumed read-only) · `rakun-test` (imports the double) · `rakun-client`

---

## Carried from 1.0.10

Every box of `specs/1.0.10-beta/03-rakun/09-rakun-data-nosql/README.md` is open. Under 03r-ab (a):

| Step there | Boxes | Here |
|---|---|---|
| Step 1 — The two behaviors and the ETS arm | 7 | step 1, as written |
| Step 2 — The Mnesia arm | 4 | step 2, as written |
| Step 3 — Redis | 5 | step 3; the fifth box ("With `RAKUN_TEST_REDIS_URL` unset, the suite reports *skipped*") is **deleted** — the suite runs against the double, always |
| Step 4 — MongoDB | 4 | step 5: one refusal cell; the four boxes are one `deferred.md` row |
| Step 5 — `#[documentQuery]` | 5 | step 4, as written |
| Step 6 — Elasticsearch, over front 13 | 4 | step 3, against the HTTP double |
| Step 7 — Neo4j, Cassandra, Couchbase | 4 | step 5: three refusal cells; three `deferred.md` rows |
| Definition of done | 8 | § Gate; "Opt-in suites report *skipped* with the missing variable named" is **deleted** |

The behaviors, the arm table, the repository shape and the pooling notes of the closed README are
carried below as the mechanism; the language-gap notes are unchanged (documents are JSON strings;
`#[documentQuery]` follows `#[query]`'s shape because a bodyless method in a `type` body is
host-backed only).

## Problem

`modules/rakun-data/src/nosql/` does not exist. A rakun application has a relational connection and
no home for a session counter, a rate limit, a rendered fragment or a profile document; the
workaround is an array in a component. The BEAM ships two stores (ETS, Mnesia) that need no driver,
and nothing wraps them.

## Current state

- `modules/rakun-data/src/` — `datasource.bp`, `sql/`, `orm/`, `migration/`, the three hosts, three
  sidecars; no `nosql/`.
- `libs/std/src/beam.bp` exposes `etsNew` / `etsGet` / `etsPut` / `etsBump` as `any`; Mnesia is in
  OTP and unused in the repository.
- `rakun-session/src/store_redis.bp` carries a RESP client (`rkSessRedis`), reused by `rakun-cache`
  (03r-i); `rakun-test` gains the RESP double in 19 step 1.
- `rakun-client` reaches HTTP + JSON with timeouts, TLS bundle and the SSRF filter; its tests run
  against an in-process HTTP double (`rkCacheRespDouble*` cells).

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
| ETS | `ets:memory` | yes | `rakun_nosql.erl`: one table per store, a sweeper process for TTL; the default under the `test` profile |
| Mnesia | `mnesia:local` · `mnesia:cluster` | yes | `disc_copies` under `BOTOPINK_TEST_TMPDIR`, a transaction per write, `add_table_copy` on join; the two-node box runs two `peer` nodes started by the sidecar — if `peer` cannot start under the runner, that one box is reworded to the single-node `add_table_copy` path and says so |
| Redis | `redis://…` | yes | RESP over `gen_tcp` (the `rkSessRedis` wire lifted into `nosql/redis.bp`); the suite connects to `rakun-test`'s double on a loopback port |
| Elasticsearch | `https://…` | yes | `rakun-client`; the suite runs against 13's HTTP double answering the `_doc` and `_search` shapes |
| MongoDB · Neo4j · Cassandra · Couchbase | `mongodb://` · `bolt://` · `cassandra://` · `couchbase://` | refusal cell | a recognised scheme whose boot refusal names lg2-a (no byte type) and the driver the sidecar cannot load; one `deferred.md` row each |

A configured driver whose module cannot load is a boot failure naming the driver — never a fallback
to ETS. The filter dialect for ETS and Mnesia is exact: a flat JSON object of equality pairs with
`$in`, `$gt`, `$lt`, `$exists`; anything else fails naming the operator. `#[documentQuery("…")]`
emits `__rkQuery_<name>()` and registers it in 08's statement inventory; `bind(template, params)`
escapes for the target dialect. Pooling reuses 08's `rakun_pool_sup`; ETS and Mnesia bypass it and
say so when a pool size is configured. Each configured arm registers a `#[healthIndicator]` through
`rakun-actuator-api`. `#[redisListener]` is 15's.

## Gate stance

No cell is env-gated or reports *skipped*. Four arms run in the gate against in-VM stores or
in-process doubles; the four binary-protocol arms are refusal cells (green, asserting the refusal's
text). The closed README's `report skipped` boxes are deleted, not carried.

## Steps

### Step 1 — The two behaviors and the ETS arm

**Acceptance:**
- [ ] `KeyValueStore` and `DocumentStore` are declared in `src/nosql/mod.bp` and `rakun.nosql.url` selects an arm at boot
- [ ] an unknown scheme fails at boot naming the value; a known scheme with an unloadable driver fails naming the driver
- [ ] `test/nosql/keyvalue_test.bp` and `document_test.bp` — the suite takes the store as a parameter — pass on the ETS arm
- [ ] `putExpiring` with a 1-second TTL is gone after 2 seconds and `ttl` reports the remaining time before that (the sweeper runs on a 100 ms tick under test)
- [ ] `increment` on an absent key starts at 0 and answers `by`
- [ ] `popRight` on an empty list answers `null`, not `""`
- [ ] two test blocks do not see each other's keys

### Step 2 — The Mnesia arm

**Acceptance:**
- [ ] a document written in one transaction and a raise in the same transaction leaves nothing behind
- [ ] `disc_copies` survives a node restart within one test run (the sidecar stops and restarts `mnesia` on the same directory)
- [ ] a second node joining the cluster sees the existing documents — over `peer`; or, if the runner cannot start a peer, the box is reworded to the `add_table_copy` call being issued and its result asserted, and the README says why
- [ ] the supported filter subset works; anything else fails naming the operator

### Step 3 — Redis and Elasticsearch, against the doubles

**Acceptance:**
- [ ] every `KeyValueStore` method maps to the documented Redis command, asserted on the double's command log
- [ ] `fieldGet` / `fieldPut` use hashes, `pushLeft` / `popRight` use lists
- [ ] a connection lost mid-call (the double closes the socket on a `FAIL` command) is retried once and then raises
- [ ] the `redis` health indicator answers `UP` against the double and `DOWN` with the reason when the port is closed
- [ ] `index`, `get`, `search` and `delete` go through `rakun-client` and the HTTP double records the paths and bodies; timeouts, the bundle and the SSRF filter apply (one negative test each)
- [ ] a 4xx from the double raises with the double's error body, not a generic message
- [ ] no third-party OTP application is required (the manifest and the sidecar list prove it)

### Step 4 — `#[documentQuery]`

**Acceptance:**
- [ ] it emits `__rkQuery_<name>()` returning the template verbatim and registers it
- [ ] an empty template, and one whose braces do not balance, each fail the build with a located message (`test/nosql/query_build_test.bp` over a scratch project under `BOTOPINK_TEST_TMPDIR`)
- [ ] `bind` escapes every parameter for the target dialect; a value containing the dialect's quote character round-trips
- [ ] `#[documentQuery]` on a non-method fails at comptime
- [ ] the registered templates appear in 08's statement inventory

### Step 5 — The refusal cells (03r-ab)

**Acceptance:**
- [ ] `mongodb://`, `bolt://`, `cassandra://`, `couchbase://` each refuse the boot with a message naming the scheme, the driver, and the language-gaps row lg2-a — four cells in `test/nosql/arms_test.bp`
- [ ] four `deferred.md` rows, each naming the box list it holds and the gap that unblocks it
- [ ] the member README's arm table says which arms run and which refuse

## Gate

- [ ] `botopink test --target erlang` green in `modules/rakun-data`, the `nosql/` files listed in the run
- [ ] every configured arm registers a health indicator (asserted through `rakun-actuator-api`'s registry)
- [ ] `botopink format --check` clean
- [ ] `repository/rakun/AGENTS.md` § NoSQL documents the arm table and the filter subset; `modules/README.md` row updated
- [ ] commit on `fix/09-rakun-data-nosql`

## Blast radius

Adds `nosql/*` to `rakun-data`'s `files` and `src/root.bp` (appended after 08's lines). No existing
test changes. `rakun-session` and `rakun-cache` keep their own Redis wires this milestone; folding
them onto `nosql/redis.bp` is a follow-up the member README names, not this front's.

## Notes

- `examples/stores-example.bp` is the closed front's example, copied whole: the front is entirely
  open and the example is its consumer surface.
- 03r-ab's alternative (b) — the four binary protocols in an Erlang sidecar — is four protocol
  clients; if the maintainer chooses it, each is a front of its own and this README gains a row per
  arm, not the boxes.

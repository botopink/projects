# Track 04 — rakun

**Repo:** `repository/rakun` · **Target:** erlang only (decision 113) · **Members:**
[`modules.md`](./modules.md) (the 16 members front 128 leaves, the 25 on disk until it lands) ·
**Closed record:** [`1.0.10-beta/03-rakun`](../../1.0.10-beta/03-rakun/) (frozen) · **History**
(1.0.10 → 1.0.11 carry map included): [`1.0.11-beta/04-rakun`](../../1.0.11-beta/04-rakun/)

## Goal

Close what 1.0.10 left open — the unticked boxes of its 51 fronts, carried into the 19 fronts
below, and hygiene RX-1 … RX-9 — on decision 187's 16-member cut; every cell a hard assertion, no
env-gated, skipped or "cannot be demonstrated" cell (decision 160).
[`128-rakun-consolidation`](./128-rakun-consolidation/README.md) merges nine members first;
**every path in this track's READMEs is post-128** (§ Where a merged member's front works).

**State:** on `feat`: 13 step 4 (RX-8 row) and 92 step 1 (same-node broadcast, landed by
`00-gate/99`; two-node run a `deferred.md` row). Nothing else. 128 not started; waits on the rakun
consumer commits of `03-bundled-libs` 102 step 3 and 103 step 2 (not landed). Open steps partly
true in code: 74, 15, 81, 12, 65, 73 (each front says which).

## The fronts

| Front | Priority | State | What (post-128 paths) | Group | Depends on |
|---|---|---|---|---|---|
| [`128`](./128-rakun-consolidation/README.md) | critical | not started | the nine merges; every manifest and import | first, alone | 102 step 3 + 103 step 2 rakun commits (decision 188) · the 130 rule (§ Order) |
| [`04`](./04-rakun-erlang-runtime/README.md) | critical | not started | `rakun` core, all but 74's, 11's, 17's files | A | 128 · decisions 343, 347 (R06-2, R06-4 at compile time; lg2-g closed by 281: by-type injection, step 6) |
| [`74`](./74-rakun-tls-ssl-bundles/README.md) | high | not started (two cells exist) | the core's four TLS files · `rakun-web/src/tls.bp` | A | 128 |
| [`08`](./08-rakun-data-sql/README.md) | high | not started | `rakun-data`: `sql/**`, `migration/**`, `orm/**`, `datasource.bp` | A (step 1 after 04 step 4) | 128 · 04 step 4 (step 1) · decisions 147, 347 |
| [`15`](./15-rakun-messaging/README.md) | high | not started (two premises already true) | `rakun-messaging` (not `pulsar/**`, `rsocket/**`) · `rakun-data/src/tx/**` · `rakun-scheduling` | A | 128 · 03r-al · `01-compiler/14` step 6 (341) |
| [`79`](./79-rakun-oauth2-sso/README.md) | high | not started | `rakun-security` | A | 128 · 03r-ae |
| [`81`](./81-rakun-packaging-release/README.md) | high | not started (compile step exists) | `rakun-cli/src/release/**` | A | 128 · 03r-ak |
| [`93`](./93-rakun-soap-webservices/README.md) | low | not started | `rakun-client/src/ws/**` | A | 128 · decision 342 |
| [`73`](./73-rakun-starters/README.md) | medium | not started | `starters/**`, `examples/**` | A (decision 189) | 128 · 03r-af · `02/98` step 4 (344) |
| [`19`](./19-rakun-test-utilities/README.md) | high (blocking) | not started | `rakun-test` | A (step 1) · C (steps 2–5) · step 6 → 20-snap | 128 · 15 step 1 · 04 step 4 · 03r-am |
| [`13`](./13-rakun-http-clients/README.md) | high | partial: step 4 on `feat`; 1–3 open | `rakun-client` (not `ws/**`) | B | 04 step 1 · lg2-b · 346 (unbuilt) |
| [`17`](./17-rakun-logging/README.md) | medium | not started | `rakun/src/logging/**` · `rakun-metrics` | B | 128 · `03-bundled-libs/106`'s package · 13 step 2 |
| [`22`](./22-rakun-file-routing/README.md) | critical | not started | `rakun-app` | B | 04 step 5 · decision 186 · onze 50 · 53 · jhonstart 30 · 32 · lg2-q |
| [`12`](./12-rakun-cache/README.md) | medium | not started (premise changed) | `rakun-cache` · `rakun-session` | B | 19 step 1 · 04 step 1 |
| [`11`](./11-rakun-actuator/README.md) | medium | not started | `rakun-actuator` · `rakun/src/actuator_api/**` | B | 128 · 22 (R11-7) |
| [`65`](./65-rakun-url-rules/README.md) | high | not started (rule 2 of decision 201 in code) | `rakun-web` (not `tls.bp`) · one line of `rakun-data/src/devtools/devtools.bp` | B | 128 · decision 201 |
| [`09`](./09-rakun-data-nosql/README.md) | low | not started | `rakun-data/src/nosql/**` | B | 19 step 1 · 13 · 03r-ab (record only) · 346 (unbuilt) |
| [`91`](./91-rakun-pulsar/README.md) | low | not started | `rakun-messaging/src/pulsar/**` (stays; data plane deferred — 274) | B | 15 · 346 (unbuilt) |
| [`92`](./92-rakun-rsocket/README.md) | low | partial: step 1 on `feat` | `rakun-messaging/src/rsocket/**` | B | 74 · 15 · 03r-an · 346 (unbuilt) |
| [`88`](./88-rakun-cli/README.md) | medium | not started | `rakun-cli` (not `release/**`) | C | 81 · 93 · 92 · 04 step 4 · 73's re-measure · onze 50 |
| [`137`](./137-erika-sql/README.md) | high | not started | **`repository/erika`** `modules/erika/**`: holes, the SQL target (`QueryContext`, `QueryTable`, 397), `limit`/`join`/aggregates, `#[erika "…"]` (311–313) | B (before 08 step 7) | 01-checker step 29 (its step 5) · 397 |
| [`143`](./143-dbcontext/README.md) | high | step 0 done (`botopink/dbcontext`, a submodule) | **`repository/dbcontext`**: botopink's JPA over erika — `#[dbcontext.entity]`, `DbContext` over a `Driver`, `#[dbcontext.repository]`, `#[dbcontext.sql "…"]`, `#[dbcontext.nativeQuery]` (398) | 137 s2 · 01-checker s29 · s3: 128 |

**critical** blocks another track (128 every rakun front; 22 onze 49/53 and jhonstart 27/32; 04
onze 49 via R62-3, and 13 and 12 via its tag epoch). **high** closes a member's contract or a gate
stance. **medium/low** breadth. Branch `front/<NN-name>` (e.g. `front/128-rakun-consolidation`);
landing is the maintainer's.

## Order

```
128 consolidation ── first, alone in the repository (after the rakun commits of 102 step 3 and 103 step 2)
   │
A  04 (step 1, the tag epoch, first and alone) · 74 · 08 · 15 · 79 · 81 · 93 · 73 · 19 step 1
   │
B  04 step 1 ──► 13 · 12
   04 step 4 ──► 08 step 1 (the eager-pass hook)
   04 step 5 ──► 22
   19 step 1 ──► 12 · 09
   13 ───────► 09 (Elasticsearch) · 17 (R75-1)
   15 ───────► 91 · 92
   74 ───────► 92
   22 ───────► 11 (R11-7 only)
   65 (waits on nothing in the track after 128: its relay streams through `httpc`, not 13)
   │
C  81 · 93 · 92 · 04 step 4 ──► 88
   15 step 1 · 04 step 4 ──► 19 steps 2–5      (19 step 6 is 20-snap's, on 390)
```

Concurrency and other tracks: [`../fronts.md`](../fronts.md) § Execution order of tracks 03–08. A
B front opens the day its named A step is on `feat`.

- **128 first** — moves nine members, rewrites other manifests and imports; after it the core holds
  the logger and span API, removing the old cut's two seams (decision 187).
- **04 step 1 first inside A** — the core's per-tag epoch, bumped by `rakun-cache`, read by
  `rakun-client` (no edge between them, decision 185); a few lines in `src/runtime.bp` and `rakun_runtime.erl`.
- **19 step 1 early** — the Redis RESP double (decision 160) that 12's session arm and cache
  provider and 09's Redis arm assert against; in `rakun-test`, which depends on the core only.

### 130 and 128 — the ordering rule (decision 339)

`01-compiler/130-decorator-outputs` step 5 (decision 216) still plans edits to files this track
owns or 128 moves: the core's `src/decorators.bp` (frozen for rakun fronts), `autoconfig.bp`,
`config.bp`, `context.bp`, `lifecycle.bp`, `conditions.bp` (04's) · `rakun-web/src/convention.bp`
(65's) · `rakun-app/src/{route_handler,actions}.bp` (22's) · `rakun-scheduling`,
`rakun-messaging` (15's) · `rakun-cli` (88's) · `rakun-data` `entity.bp`, `query.bp`,
`sql/transactional.bp` (08's) · `rakun-security/src/method_security.bp` (79's) ·
`rakun-websocket` · `rakun-client/src/exchange.bp` (13's) · `rakun-actuator-api` (128 moves it into
`modules/rakun/src/actuator_api/`). Landed edits (rakun-data's `#[entity]` /
`#[entityRepository]` / `#[belongsTo]` / `#[query]`, rakun-cache's `#[cached]`, rakun-hateoas'
`#[halResource]`) are on `feat` and move with their files. **The rule** — decision 339:

1. 128 does not wait on 130 (130's rakun sites reach nearly every front's files; rakun-client's
   also wait on a behavior-member gap).
2. No 130 rakun commit in flight while 128 is open; 130's sites re-pointed at post-128 paths.
3. After 128, each 130 rakun commit is a consumer commit (decision 188): never in a wave with the
   owning front — before it opens if ready, else after it lands.
4. The frozen-files rule (§ Rules) excepts 130's decision-216 rewrite of `src/decorators.bp`; no
   rakun front edits it.

## Parallel groups

Two fronts run together only with no shared source file or test directory; every pair in a group
is file-disjoint. Shared members:

| Member | Fronts | The cut |
|---|---|---|
| `rakun` | 04 · 74 · 17 · 11 | 74: `src/ssl_bundle.bp`, `src/sidecars/rakun_ssl.erl`, `test/ssl_bundle_test.bp`, `test/tls_listener_test.bp` · 17: `src/logging/**`, `test/logging/**`, `src/sidecars/rakun_logging.erl` · 11: `src/actuator_api/**`, `test/actuator_api/**`, `src/sidecars/rakun_actuator_api.erl` · 04: the rest, `botopink.json` and `src/root.bp` included; 74, 17, 11 add no file to the member |
| `rakun-web` | 65 · 74 | 74: `src/tls.bp`, `test/tls_test.bp`; 65: the rest, `src/hateoas/**` included (no open box) |
| `rakun-data` | 08 · 09 · 15 · 65 | 09: `src/nosql/**`, `src/nosql_host.bp`, `src/sidecars/rakun_nosql.erl`, `test/nosql/**` · 15: `src/tx/**`, `test/tx/**` · 65: one line of `src/devtools/devtools.bp` and `test/devtools/devtools_test.bp` · 08: the rest; 08 edits neither `botopink.json` nor `src/root.bp` this milestone, so 09 appends to both without waiting |
| `rakun-messaging` | 15 · 91 · 92 | 91: `src/pulsar/**`, `src/pulsar_host.bp`, `src/sidecars/rakun_pulsar.erl`, `test/pulsar/**` · 92: `src/rsocket/**`, `test/rsocket/**`, `src/sidecars/rakun_rsocket.erl` · 15: the rest, `src/stream/**` included. `botopink.json`, `src/root.bp` are 15's; 92 (only for R92-1's edge, 03r-an) edits them after 15 lands; 91 does not (274: no split) |
| `rakun-client` | 13 · 93 | 93: `src/ws/**`, `test/ws/**`, `src/sidecars/rakun_ws.erl`; `botopink.json`, `src/root.bp` are 13's, 93 appends when 13 does not hold them |
| `rakun-cli` | 81 · 88 | 81: `src/release/**`, `test/release/**`, `src/sidecars/rakun_release.erl`, and `botopink.json` / `src/root.bp` (lower number); 88 the rest, after 81 (group C) |
| `rakun-test` | 19 | 12's and 09's cells import the double; neither edits `rakun-test` |
| `starters/**`, `examples/**` | 73 | no member front touches them after 128 |

### Where a merged member's front works

Front numbers and directories do not move with decision 187. A name below (here, another track, or
code) means the path on the right after 128:

| Merged member | After 128 | Front |
|---|---|---|
| `rakun-actuator-api` | `modules/rakun/src/actuator_api/**` | 11 |
| `rakun-logging` | `modules/rakun/src/logging/**` | 17 |
| `rakun-hateoas` | `modules/rakun-web/src/hateoas/**` | — (no open box; its example file is under 13) |
| `rakun-ws` (SOAP) | `modules/rakun-client/src/ws/**` | 93 |
| `rakun-tx` | `modules/rakun-data/src/tx/**` | 15 |
| `rakun-devtools` | `modules/rakun-data/src/devtools/**` | 65 (one line) |
| `rakun-release` | `modules/rakun-cli/src/release/**` | 81 |
| `rakun-rsocket` | `modules/rakun-messaging/src/rsocket/**` | 92 |
| `rakun-stream` | `modules/rakun-messaging/src/stream/**` | 15 |

`from "rakun-<merged>"` = import from the absorbing member; test files keep their names under
`test/<merged>/`; sidecars keep their names.

## Gate stance, per cell

A cell is a hard assertion or does not exist (decision 160):

| Cell | Front | Stance |
|---|---|---|
| `rakun-session`'s store suite, Redis arm | 12 | absent: `00-gate/99` deleted the env-gated cell (`deferred.md` row "The Redis arm of `rakun-session`'s store suite"); 12 re-adds it against 19's RESP double; the row keeps only the real-server run |
| `rakun-websocket/test/broadcast_test.bp`, the two-node broadcast | 92 | done: same-node `pg` broadcast to two subscribers, no `skipped:`; two-node run a `deferred.md` row |
| `rakun-websocket/test/limits_test.bp:48`, the outbound-queue cap | **unowned** (`rakun-websocket` has no open front; handed by `00-gate`) | hard, event-synchronised (chores patch, after 128): the 1013 cell waits for its session's row before sending and for its close-log entry before asserting — it read the ids before the connection registered (close code 0) and slept 3 s for the close. The cap itself is atomic (`ets:update_counter`). Open: the sidecar answers 101 before it registers the session (status L2) |
| 15's three integration suites | 15 | never written: the in-process broker (03r-k) is the gate arm for every messaging cell; real drivers are `deferred.md` rows under the toolchain row "a sidecar cannot reach an external OTP application" |
| 09's six opt-in suites | 09 | four arms in the gate (ETS, Mnesia, Redis on the double, Elasticsearch on an HTTP double); the four binary-protocol stores are boot refusals naming the driver (03r-ab) |
| 83's Kafka producer transaction | 15 | 83's outbox path enrols in 86's producer transaction (`reliability/transaction.bp` `withProducerTransaction`, `read_committed` hold/drop); real broker a `deferred.md` row (03r-al) |
| 91's data plane | 91 | deferred (274): a boot refusal cell, one `deferred.md` row |
| the "toolchain row" boxes (R04, R81-1/2, R88-1) | 73 · 81 · 88 | re-measure: `botopink run` of the three examples after `botopink build --target erlang` (73); the release already compiles every `.erl` of an application directory into `ebin` (`rakun_release.erl` `compile_dir/1`) — 81 measures whether `out/erl` is among them |

## What the maintainer must decide

1.0.10's 24 choices (`03r-a` … `03r-x`, [`1.0.10-beta/decisions-pending.md`](../../1.0.10-beta/decisions-pending.md)
§ Track B) are implemented; those still awaiting confirmation, fronts building on them: 03r-c/e → 04 ·
03r-f…j → 12 · 03r-k/l/x → 15 · 03r-m/n/p/q → 22 · 03r-r → 73 · 03r-s → 17 · 03r-t/u → 11 · 03r-v →
08 · 03r-w → 79 and 13. Closed on 9 Oct: 03r-b (reversed by 299 — a malformed number stops the boot
naming file, line, type; 04 step 7), 03r-d (299 — config bound at boot into a typed
`#[config("prefix")]` record), 03r-o (290 — no segment config; 22 step 8). New questions continue the
letters; each recommendation is the most restrictive reading (decision 67). Answered: 03r-y (184,
superseded by 187), 03r-z (185), 03r-aa (160), 03r-ac (187), 03r-ad (274), 03r-ah (153), 03r-ai (186),
03r-aj (187).

**Open:** `03r-ae`, `03r-af`, `03r-ak`, `03r-am`, `03r-an`. **Only the record is missing** (the fronts
already follow the recommendation): `03r-ab` (09 is written to (a)), `03r-al` (15 step 5 is written
to (a)). `03r-ao` is decision 339 (the 130 rule, § Order).

### 03r-ab · Front 09 ships four arms; the binary-protocol stores are boot refusals (only the record is missing)

**Measured.** MongoDB (OP_MSG + BSON), Neo4j (Bolt), Cassandra (CQL binary), Couchbase (memcached
binary) are byte protocols; host cells marshal through `string` until 346's `Bytes` is built; each needs an OTP driver
a sidecar cannot load. ETS, Mnesia in the VM; Redis RESP over `gen_tcp` (text); Elasticsearch HTTP + JSON.
**Options.** (a) 09 ships `ets:memory`, `mnesia:local`/`mnesia:cluster`, `redis://`, `https://`
(Elasticsearch), behavior suite against all four in the gate; `mongodb://`, `bolt://`,
`cassandra://`, `couchbase://` recognised, boot refusal names the driver; closed steps 4
and 7's 12 boxes become the refusal cells + one `deferred.md` row each. (b) the four in an Erlang
sidecar, a front each. (c) defer 09 whole.
**Recommendation.** (a): refusal naming the gap is restrictive; ETS fallback under a Mongo URL is what 09 forbids.
09's README already applies (a).
**Blocks.** Only the record — 09 step 5 is written to (a).

### 03r-ae · SAML 2.0 ACS: Exclusive XML Canonicalisation in a sidecar, or the SP retired

**Measured.** IdP signature verification needs Exclusive C14N (`xml-exc-c14n`); neither OTP's
`xmerl` nor std has it; `saml2/saml2.bp` answers 501 at `/saml2/acs`.
**Options.** (a) exc-c14n over `xmerl`'s tree in `src/sidecars/rakun_saml2.erl` (~300 lines), three
boxes closed with fixture assertions signed by a checked-in key. (b) retire the SP: three boxes
deleted, `saml2/` keeps its 501 + a `deferred.md` row. (c) leave open.
**Recommendation.** (a) if 79 is staffed this milestone, else (b) — never (c).
**Blocks.** 79 step 3.

### 03r-af · The seven unbuilt example projects are retired from the plan

**Measured.** `examples/` holds `rakun`, `rakun-container`, `rakun-ssr`, each a `test-libs` build
cell; closed `modules.md` § Examples lists seven more (`rest-service`, `secured-api`,
`blog-server`, `order-pipeline`, `observed-service`, `realtime-gateway`, `release-kit`), none
started. Each member's contract is asserted by its own `test/**`.
**Options.** (a) retire the seven; the three gain a `README.md` each, stay the only example cells.
(b) build them, a front each, after every member front. (c) `rest-service` only.
**Recommendation.** (a).
**Blocks.** 73 step 3.

The snapshot layer is decision 390 (390), worked by [`20-snap`](../20-snap/README.md) step 2.

### 03r-ak · CycloneDX: a `required` / `type` validator over the checked-in schema

**Measured.** R81-3: "validates against the CycloneDX 1.5 schema — asserted against a checked-in
schema, with no network access". std has no JSON-schema validator; `sbom.bp` asserts required fields by name.
**Options.** (a) `release_test.bp` reads a checked-in `bom-1.5.schema.json` with `json.decode`,
walks the SBOM against `required`, `type`, `enum`, local `$ref`s (~120 lines). (b) amend the box to
the field list. (c) a `json.schema` in std (not rakun's).
**Recommendation.** (a).
**Blocks.** 81 step 3.

### 03r-al · 83's broker path enrols in 86's producer transaction (only the record is missing)

**Measured.** `rakun-data/src/tx` (`outbox_test.bp` "path choice: broker transactions skip the
outbox, otherwise the outbox is used") holds the choice minus the broker. Broker side exists:
`rakun-messaging/src/reliability/transaction.bp` `withProducerTransaction` holds publishes, releases
in order on commit, drops on a raise; a `read_committed` reader never sees an aborted one
(`transaction_test.bp`). Missing: 83's outbox path enrolling in it.
**Options.** (a) with the in-process broker transactional, the outbox path publishes through
`withProducerTransaction`, writes no outbox row; R83-1's boxes reworded to the in-process broker,
real-broker run a `deferred.md` row. (b) delete the two boxes. (c) leave open.
**Recommendation.** (a). 15 step 5 is already written to (a).
**Blocks.** Only the record (15 step 5).

### 03r-am · Where the broker and scheduler doubles live

**Measured.** `rakun-test` depends on `rakun` only; `rakun-messaging/test/*.bp` imports
`rakun-test`. `rakun-test → rakun-messaging` is a package cycle unless the loader honours test
scope (a `02-packaging` rule, not verified).
**Options.** (a) measure: add the edge in 19's worktree; if `botopink test` in
`modules/rakun-messaging` refuses the cycle, doubles live beside what they double
(`rakun-messaging/src/broker_double.bp` + `rakun_messaging_double.erl`,
`rakun-scheduling/src/task_double.bp`), documented by `rakun-test`. (b) the edge, assuming the rule
landed. (c) doubles in `rakun-test`, reaching registries through core hooks only (`rkOnReset`, the
`rakun_listener_names` term).
**Recommendation.** (a) with (c) as the shape either way: no `-test` member imports a member that imports it.
**Blocks.** 19 steps 3 and 4.

### 03r-an · RSocket's WebSocket transport: the `rakun-websocket` edge, or a core extension point

**Raised by:** 92 (R92-1). **Measured.** R92-1 mounts the RSocket connection on `rakun-websocket`'s
`#[wsEndpoint]`. After 128 RSocket is in `rakun-messaging`; the edge `rakun-messaging →
rakun-websocket` (acyclic) loads `rakun-websocket`'s tree (`rakun-security`, `rakun-session`,
`rakun-scheduling`) for every messaging consumer.
**Options.** (a) the edge. (b) a core transport extension point `rakun-websocket` plugs into, no
member edge (decision 185). (c) retire the WebSocket transport: R92-1's two boxes and R92-7's
`ws://` / `wss://` arms deleted, TCP and TLS only.
**Recommendation.** (b): decision 185's rule is for exactly this edge.
**Blocks.** 92 step 2's first and third boxes.

## Hygiene items

| Item | What | Front |
|---|---|---|
| RX-1 | `??`-with-a-dummy-record workarounds (`if (x == null)` narrowing exists) | 11 (`rakun-actuator/src/endpoint_host.bp:136,152`) · 79 (`rakun-security/test/basic_test.bp:137,174`) · 04 (`rakun/test/config_test.bp:569`) |
| RX-2 | "declared parameter defaults are never applied" (decorator-argument case) — re-measured in the owning member's tests, result recorded | 04 (14, 72) · 08 (78) · 12 · 15 (15, 86, 90) · 22 (60, 61, 64, 66); 21's corrected by 13 step 4 |
| RX-4 | the closed `status.md` L82 rows (static root, `Request` query/headers) | 65 (R82-4) · 04 (R62-3) |
| RX-5 | the snapshot layer | `20-snap` step 2 (390) |
| RX-6 | the seven example projects | 73 (03r-af) |
| RX-7 | `modules.md` vs the tree | 128 (the nine merges) |
| RX-10 | "consume std" (`02-std-and-packaging/97` § Consumers): `config.parseDuration` (`rakun/src/config.bp`) and `jwt.skewOf` (`rakun-security/src/jwt.bp`) → `clock.parseDuration` (one unit, digits only — not ISO `PT…`); number parsers answering a `@Result` (`rakun-metrics/src/registry.bp`, `rakun-scheduling/src/cron.bp`, `rakun/src/config.bp`) → `parseInt` / `parseFloat`; `Json` accessors (`jwt.bp`, `rakun/src/autoconfig_registry.bp`) → the `Json` methods; `rakun_security.erl`'s `pbkdf2` → `hash.pbkdf2Sha256` (salt as text, decision 175) | 04 (`config.bp`, `autoconfig_registry.bp`) · 79 (`jwt.bp`, `rakun_security.erl`) · 17 (`rakun-metrics`) · 15 (`cron.bp`) |
| RX-11 | "consume std": the four retry loops → `async.RetryPolicy` / `retry` — `rakun-messaging/src/reliability/policy.bp` (own `RetryPolicy` / `nextDelay`, decision 170; mind 97's residual 4), the outbox (`rakun-tx/src/outbox.bp`, `rakun-data/src/tx/` after 128), `rakun-scheduling/src/jobstore/scheduler.bp`, the `rakun-mail` sidecar | 15 (the first three) · `rakun-mail`: **unowned** (no open front) |
| RX-12 | "consume std": constant-time equality (`rakun/src/request_context.bp`) → `hash.equalsConstantTime`; `sha256` (`rakun-ws/src/ws.bp`, `rakun-client/src/ws/` after 128) → `hash.sha256`; `xmlEscape` (`config.bp`) → `escape.attribute`; `cron.rkFormatUtc`, the logger's `rkLogIso` → `clock.formatIso8601` | 04 · 93 · 15 · 17 |
| RX-13 | onze wire names `__bp_action` / `X-Bp-Action` as literals in rakun's tests (`rakun-app/test/actions_test.bp`, `rakun-app/test/fixtures/actions-cache/test/actions_cache_test.bp.fixture`) — decision 114: neither library spells onze's defaults; `07-onze/49` step 2's last box closes when gone | 22 |
| RX-14 | workarounds the integrated compiler made deletable: rakun-data `rows.bp`'s `longOf` (C2 fixed); `runtime.bp`'s named fn returning the lambda (`language-gaps.md` row 28 fixed — 89's consumer); rakun fronts 77/78's `src/orm_host.bp` (measured deletable by `01-compiler/26` step 2: moved to `src/orm/host.bp`, rakun-data 128 passed) | 08 · 89 |
| RX-15 | latent `i32` clocks: `migration_host.cellNowMs`, the test-only monotonic `nowMs` in `rakun-mail`, `rakun-rsocket` and `tls_listener_test`, `Duration.millis` typed `i32` | 08 · 92 · 04 · `rakun-mail`: **unowned** |
| RX-16 | stale `__rkMake_` text in rakun's `AGENTS.md` (factories are `T.make()`, 234) | 04 |

Done: RX-3 (decisions 113–117's rakun halves), RX-8 (`record ↔ Json` row, 13 step 4), RX-9 (READMEs state current state), RX-17 (the server test measures `Content-Length` in bytes, not
in string indices — decision 320's follow-up).

## Cross-track dependencies

| Direction | This track | Other track | What crosses |
|---|---|---|---|
| rakun ⇄ `01-compiler/130` | 04 · 08 · 11 · 13 · 15 · 22 · 65 · 79 · 88 · 128 | 130 step 5 (decision 216) | the decorator rewrite of the rakun sites — § Order, the 130 rule (decision 339) |
| rakun → onze | 65 (R82-4) | 49 step 4 (decision 201) | a static-root miss falls through to the router, only `GET` / `HEAD` served, a refusal stays final; onze registers `/**` → `public/` before the routes |
| rakun → onze | 04 (R62-3) · 22 | 49 (ONZ-49-4.3) | the page `Request` enumerates `queryDict()`, `headerNames()` / `headers()` so `RequestData.query` / `.headers` stop being `[]` |
| rakun ⇄ onze | 22 (R24-1, R24-2) | 50 (`useServer` — no longer a form: 282, 303; 22 step 6), 53 (`serveActions`, the `__bp_action` / `X-Bp-Action` literals) | an action is `#[action] pub fn` (303), no file-level directive; the refresh payload is contract 2 |
| rakun → onze | 22 (60) | 53 (prerender), 71 (`staticExport`) · jhonstart 27 | the route kind the build writes (decision 186) and the prerender store |
| rakun → onze | 22 (66) | 70 | default size and content type via route discovery |
| rakun → onze | 11 (R11-4) · 04 (R06-6) · 81 | 71 | `POST /actuator/shutdown`, exit codes, the release's stop path |
| rakun ⇄ jhonstart via `03-bundled-libs/106` | 17 (R17-1) | 26 step 4 | one digest, `log`'s `errorDigest` (decision 194); rakun's logger is `log`'s sink, onze sets the sink for the render (decision 195) |
| rakun → jhonstart | 22 (R64-2, 66) | 32 | `Alternate[]`, `manifestHref`, `imagesFor`, `iconsFor` consumed unchanged; boxes close when 32 ticks |
| rakun → onze | 88 (R88-6) | 50 | the CLI boundary table, mirrored in `07-onze/50-onze-cli/README.md` (onze's file) |
| rakun → std / packaging | 73 | 344 · PK-7 | a git dependency with a subdirectory, for an out-of-tree starter consumer |
| rakun → `01-compiler` | 04 · 08 · 09 · 13 · 15 · 22 · 65 · 88 · 91 · 92 · 93 | lg2-b · f · q · r · decisions 341, 342, 343, 346, 347 | named per front; a box blocked on a compiler decision stays open and says so |
| `03-bundled-libs` → rakun | 128 · 22 · 65 · 04 · 79 · 12 · 19 · 17 · 81 | 102 step 3 (`rakun-app/src/{file_router,static_gen}.bp`, `rakun-hateoas/src/hal.bp`) · 103 step 2 (`rakun-app/src/actions.bp`) · 104 step 5 (`rakun/src/request_context.bp`, `rakun-web/src/{negotiation,compression,static,error}.bp`, `rakun-security/src/csrf.bp`, `rakun-session/src/session_cookie.bp`, `rakun-test/src/fake_request.bp`, `rakun-app/src/i18n.bp`) · 105 (`rakun-app/src/i18n.bp`) · 106 (`rakun-web/src/error.bp`'s `problem_digest`; the logging files are 17's) · 107 (`rakun-cli/src/release/release.bp`) | consumer commits, never in a wave with the owning front (decision 188): 102 and 103 before 128; 104, 105, 107 and 106's one commit after the owning fronts land |
| `08-bpp` → rakun | 04 · 65 · 22 | 123 (new `rakun/src/locals.bp`; lines of `rakun-web/src/{middleware,filter}.bp`) · 117 (`rakun-app/src/static_gen.bp`) · 120 (new `rakun-app/src/server_islands.bp`) · 127 (new `rakun-app/src/typed_action.bp`, one line of `actions.bp`) | after the owning rakun front: 123 after 04 and 65 (decision 189); 117, then 120, then 127 after 22, one at a time on `rakun-app`'s `botopink.json` and `root.bp` |

## Rules

- The compiler knows no library: file a language-gaps row, work around it, never edit `repository/botopink-lang/**`.
- erlang-only (decision 113): no commonJS row, `.mjs` or node twin; a `#[@External.Erlang]` cell
  with no node binding is the design.
- Host modules: `src/sidecars/rakun_<name>.erl`; test-only: `_fixture.erl` / `_double.erl`.
- The core's `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp` are frozen for every rakun
  front; sole writer: `01-compiler/130`'s decision-216 rewrite (§ Order, decision 339).
- A shared member's `botopink.json` and `src/root.bp` belong to its lowest-numbered front; others
  append in number order, never reorder.
- A member another always needs is part of it (decision 187). Between mutually optional members, no
  edge that would cycle or drag a member into consumers that never configured it: the core defines
  the extension point (decision 185).
- rakun imports nothing from `jhonstart`, `emilia` or `onze` and builds no HTML.
- Most restrictive behaviour, no configuration that bypasses it (decision 67).
- `status.md` is the only status carrier.

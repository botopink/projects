# Track 04 — rakun

**Repo:** `repository/rakun` · **Target:** erlang only (decision 113) · **Members:**
[`modules.md`](./modules.md) (the 16 members front 128 leaves, and the 25 on disk until it lands) ·
**Closed record:** [`1.0.10-beta/03-rakun`](../../1.0.10-beta/03-rakun/) (frozen) · **History of
this track** (the 1.0.10 → 1.0.11 carry map included): [`1.0.11-beta/04-rakun`](../../1.0.11-beta/04-rakun/)

## Goal

rakun closes what 1.0.10 left open — the unticked boxes of its 51 fronts, carried into the 19 fronts
below, and the hygiene items RX-1 … RX-9 — on the 16-member cut of decision 187, with every cell a
hard assertion: no env-gated, skipped or "cannot be demonstrated" cell stays (decision 160).
[`128-rakun-consolidation`](./128-rakun-consolidation/README.md) merges nine members first; every
other front works on the tree it leaves, and **every path in this track's READMEs is a post-128
path** (§ Where a merged member's front works).

**State:** on `feat`: 13 step 4 (the RX-8 row) and 92 step 1 (the same-node broadcast,
landed by `00-gate/99`; the two-node run is a `deferred.md` row). Nothing else. 128 has not started; it waits on the rakun consumer commits
of `03-bundled-libs` 102 step 3 and 103 step 2, which have not landed. Several open steps are
already partly true in the code (74, 15, 81, 12, 65, 73); each front says which.

## The fronts

| Front | Priority | State | What (post-128 paths) | Group | Depends on |
|---|---|---|---|---|---|
| [`128`](./128-rakun-consolidation/README.md) | critical | not started | the nine merges; every manifest and import | first, alone | 102 step 3 + 103 step 2 rakun commits (decision 188) · the 130 rule (§ Order) |
| [`04`](./04-rakun-erlang-runtime/README.md) | critical | not started | `rakun` core, all but 74's, 11's, 17's files | A | 128 · lg2-e · lg2-g · lg2-j |
| [`74`](./74-rakun-tls-ssl-bundles/README.md) | high | not started (two cells exist) | the core's four TLS files · `rakun-web/src/tls.bp` | A | 128 |
| [`08`](./08-rakun-data-sql/README.md) | high | not started | `rakun-data`: `sql/**`, `migration/**`, `orm/**`, `datasource.bp` | A (step 1 after 04 step 4) | 128 · 04 step 4 (step 1) · lg2-e/f · decision 147 |
| [`15`](./15-rakun-messaging/README.md) | high | not started (two premises already true) | `rakun-messaging` (not `pulsar/**`, `rsocket/**`) · `rakun-data/src/tx/**` · `rakun-scheduling` | A | 128 · 03r-al · lg2-w |
| [`79`](./79-rakun-oauth2-sso/README.md) | high | not started | `rakun-security` | A | 128 · 03r-ae |
| [`81`](./81-rakun-packaging-release/README.md) | high | not started (compile step exists) | `rakun-cli/src/release/**` | A | 128 · 03r-ak |
| [`93`](./93-rakun-soap-webservices/README.md) | low | not started | `rakun-client/src/ws/**` | A | 128 · lg2-o |
| [`73`](./73-rakun-starters/README.md) | medium | not started | `starters/**`, `examples/**` | A (decision 189) | 128 · 03r-af · lg2-v |
| [`19`](./19-rakun-test-utilities/README.md) | high (blocking) | not started | `rakun-test` | A (step 1) · C (steps 2–5) · step 6 → 20-snap | 128 · 15 step 1 · 04 step 4 · 03r-am |
| [`13`](./13-rakun-http-clients/README.md) | high | partial: step 4 on `feat`; 1–3 open | `rakun-client` (not `ws/**`) | B | 04 step 1 · lg2-a/b |
| [`17`](./17-rakun-logging/README.md) | medium | not started | `rakun/src/logging/**` · `rakun-metrics` | B | 128 · `03-bundled-libs/106`'s package · 13 step 2 |
| [`22`](./22-rakun-file-routing/README.md) | critical | not started | `rakun-app` | B | 04 step 5 · decision 186 · onze 50 · 53 · jhonstart 30 · 32 · lg2-q |
| [`12`](./12-rakun-cache/README.md) | medium | not started (premise changed) | `rakun-cache` · `rakun-session` | B | 19 step 1 · 04 step 1 |
| [`11`](./11-rakun-actuator/README.md) | medium | not started | `rakun-actuator` · `rakun/src/actuator_api/**` | B | 128 · 22 (R11-7) |
| [`65`](./65-rakun-url-rules/README.md) | high | not started (rule 2 of decision 201 in code) | `rakun-web` (not `tls.bp`) · one line of `rakun-data/src/devtools/devtools.bp` | B | 128 · decision 201 |
| [`09`](./09-rakun-data-nosql/README.md) | low | not started | `rakun-data/src/nosql/**` | B | 19 step 1 · 13 · 03r-ab · lg2-a |
| [`91`](./91-rakun-pulsar/README.md) | low | not started | `rakun-messaging/src/pulsar/**` (→ `rakun-pulsar` under 03r-ad (a)/(b)) | B | 15 · 03r-ad · lg2-a |
| [`92`](./92-rakun-rsocket/README.md) | low | partial: step 1 on `feat` | `rakun-messaging/src/rsocket/**` | B | 74 · 15 · 03r-an · lg2-a |
| [`88`](./88-rakun-cli/README.md) | medium | not started | `rakun-cli` (not `release/**`) | C | 81 · 93 · 92 · 04 step 4 · 73's re-measure · lg2-j · onze 50 |

**critical** blocks another track (128 blocks every rakun front; 22 blocks onze 49/53 and jhonstart
27/32; 04 blocks onze 49 through R62-3, and 13 and 12 through its tag epoch). **high** closes a
member's own contract or a gate stance. **medium/low** is breadth. A front's branch is
`front/<NN-name>` (e.g. `front/128-rakun-consolidation`); landing is the maintainer's.

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
   15 step 1 · 04 step 4 ──► 19 steps 2–5      (19 step 6 is 20-snap's, on snap-a)
```

How many run at once, and beside which other tracks, is [`../fronts.md`](../fronts.md) § Execution
order of tracks 03–08. A B front opens the day the A step it names is on `feat`.

- **128 first** — it moves nine members and rewrites the other manifests and imports, so a front open
  beside it edits a path about to change. After it the core holds the logger and the span API, which
  removes the two seams the old cut needed (decision 187).
- **04 step 1 first inside A** — `rakun-cache` and `rakun-client` stay separate and must not depend
  on each other, so the core carries the per-tag epoch `rakun-cache` bumps and `rakun-client` reads
  (decision 185). A few lines in `src/runtime.bp` and `rakun_runtime.erl`.
- **19 step 1 early** — the Redis RESP double (decision 160) is what 12's session arm and cache
  provider and 09's Redis arm assert against; it lives in `rakun-test`, which depends on the core only.

### 130 and 128 — ordering rule to confirm (`03r-ao`)

`01-compiler/130-decorator-outputs` step 5 (decision 216) still plans edits to rakun files that
this track owns or that 128 moves: the core's `src/decorators.bp` (frozen for rakun fronts),
`autoconfig.bp`, `config.bp`, `context.bp`, `lifecycle.bp`, `conditions.bp` (04's) ·
`rakun-web/src/convention.bp` (65's) · `rakun-app/src/{route_handler,actions}.bp` (22's) ·
`rakun-scheduling`, `rakun-messaging` (15's) · `rakun-cli` (88's) · `rakun-data` `entity.bp`,
`query.bp`, `sql/transactional.bp` (08's) · `rakun-security/src/method_security.bp` (79's) ·
`rakun-websocket` · `rakun-client/src/exchange.bp` (13's) · `rakun-actuator-api`, which 128 moves
into `modules/rakun/src/actuator_api/`. Its landed rakun edits (rakun-data's `#[entity]` /
`#[entityRepository]` / `#[belongsTo]` / `#[query]`, rakun-cache's `#[cached]`, rakun-hateoas'
`#[halResource]`) are on `feat` and move with their files. **Proposed rule** (the maintainer
confirms; no decision covers it yet):

1. 128 does not wait on 130. 130's remaining rakun sites reach nearly every rakun front's files
   (rakun-client's also wait on a behavior-member gap); sequencing them before 128 would hold every
   rakun front on them.
2. No 130 rakun commit is in flight while 128 is open (128 holds all of rakun). 130's rakun sites
   are re-pointed at the post-128 paths.
3. After 128, each 130 rakun commit is a consumer commit under decision 188's rule: never in a wave
   with the rakun front that owns the file — before the owner opens if it is ready, otherwise after
   the owner lands.
4. The frozen-files rule (§ Rules) excepts 130's decision-216 rewrite of `src/decorators.bp`; no
   rakun front edits it.

## Parallel groups

Two fronts run together only when they share no source file and no test directory. Inside a group
every pair is file-disjoint. Where two fronts sit in one member:

| Member | Fronts | The cut |
|---|---|---|
| `rakun` | 04 · 74 · 17 · 11 | 74: `src/ssl_bundle.bp`, `src/sidecars/rakun_ssl.erl`, `test/ssl_bundle_test.bp`, `test/tls_listener_test.bp` · 17: `src/logging/**`, `test/logging/**`, `src/sidecars/rakun_logging.erl` · 11: `src/actuator_api/**`, `test/actuator_api/**`, `src/sidecars/rakun_actuator_api.erl` · 04: the rest, `botopink.json` and `src/root.bp` included; 74, 17 and 11 add no file to the member |
| `rakun-web` | 65 · 74 | 74: `src/tls.bp`, `test/tls_test.bp`; 65: the rest, `src/hateoas/**` included (no open box) |
| `rakun-data` | 08 · 09 · 15 · 65 | 09: `src/nosql/**`, `src/nosql_host.bp`, `src/sidecars/rakun_nosql.erl`, `test/nosql/**` · 15: `src/tx/**`, `test/tx/**` · 65: one line of `src/devtools/devtools.bp` and `test/devtools/devtools_test.bp` · 08: the rest; 08 edits neither `botopink.json` nor `src/root.bp` this milestone, so 09 appends to both without waiting |
| `rakun-messaging` | 15 · 91 · 92 | 91: `src/pulsar/**`, `src/pulsar_host.bp`, `src/sidecars/rakun_pulsar.erl`, `test/pulsar/**` · 92: `src/rsocket/**`, `test/rsocket/**`, `src/sidecars/rakun_rsocket.erl` · 15: the rest, `src/stream/**` included. `botopink.json` and `src/root.bp` are 15's; 91 (only if 03r-ad splits) and 92 (only for R92-1's edge, 03r-an) edit them after 15 lands |
| `rakun-client` | 13 · 93 | 93: `src/ws/**`, `test/ws/**`, `src/sidecars/rakun_ws.erl`; `botopink.json` and `src/root.bp` are 13's, 93 appends when 13 does not hold them |
| `rakun-cli` | 81 · 88 | 81: `src/release/**`, `test/release/**`, `src/sidecars/rakun_release.erl`, and `botopink.json` / `src/root.bp` (lower number); 88 the rest, after 81 (group C) |
| `rakun-test` | 19 | 12's and 09's cells import the double; neither edits `rakun-test` |
| `starters/**`, `examples/**` | 73 | no member front touches them after 128 |

### Where a merged member's front works

A front's number and directory do not move with decision 187's merges. A name below, met in this
track, in another track or in the code, means the path on the right after 128:

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

An import `from "rakun-<merged>"` is an import from the absorbing member; a test file keeps its
name under `test/<merged>/`; a sidecar keeps its name.

## Gate stance, per cell

A cell is a hard assertion or it does not exist (decision 160):

| Cell | Front | Stance |
|---|---|---|
| `rakun-session`'s store suite, Redis arm | 12 | absent: `00-gate/99` deleted the env-gated cell (`deferred.md` row "The Redis arm of `rakun-session`'s store suite"); 12 re-adds it against 19's RESP double, and the row keeps only the real-server run |
| `rakun-websocket/test/broadcast_test.bp`, the two-node broadcast | 92 | done: a same-node `pg` broadcast to two subscribers, no `skipped:`; the two-node run is a `deferred.md` row |
| `rakun-websocket/test/limits_test.bp:48`, the outbound-queue cap | **unowned** (`rakun-websocket` has no open front; handed by `00-gate`) | load-dependent today — a queue of 51 against a cap of 50 under load, 27 / 0 idle: a red the gate can meet. The cap is enforced in the websocket runtime, or the test's bound is what the runtime guarantees; the coordinator names the front |
| 15's three integration suites | 15 | never written: the in-process broker (03r-k) is the gate arm for every messaging cell; real drivers are `deferred.md` rows under the toolchain row "a sidecar cannot reach an external OTP application" |
| 09's six opt-in suites | 09 | four arms in the gate (ETS, Mnesia, Redis on the double, Elasticsearch on an HTTP double); the four binary-protocol stores are boot refusals naming lg2-a (03r-ab) |
| 83's Kafka producer transaction | 15 | 83's outbox path enrols in 86's existing producer transaction (`reliability/transaction.bp` `withProducerTransaction`, `read_committed` hold/drop); the real broker is a `deferred.md` row (03r-al) |
| 91's data plane | 91 | 03r-ad; no gated cell under any option |
| the "toolchain row" boxes (R04, R81-1/2, R88-1) | 73 · 81 · 88 | re-measure: `botopink run` of the three examples after `botopink build --target erlang` (73); the release already compiles every `.erl` of an application directory into `ebin` (`rakun_release.erl` `compile_dir/1`) — 81 measures whether `out/erl` is among them |

## What the maintainer must decide

The 24 choices of 1.0.10 (`03r-a` … `03r-x`, [`1.0.10-beta/decisions-pending.md`](../../1.0.10-beta/decisions-pending.md)
§ Track B) are implemented and await confirmation; the fronts build on them as written: 03r-b/c/d/e
→ 04 · 03r-f…j → 12 · 03r-k/l/x → 15 · 03r-m…q → 22 · 03r-r → 73 · 03r-s → 17 · 03r-t/u → 11 ·
03r-v → 08 · 03r-w → 79 and 13. The questions this track adds continue the letter sequence; each
recommendation is the most restrictive reading (decision 67). Answered: 03r-y (184, superseded by
187), 03r-z (185), 03r-aa (160), 03r-ac (187), 03r-ah (153), 03r-ai (186), 03r-aj (187).

**Open:** `03r-ab`, `03r-ad`, `03r-ae`, `03r-af`, `03r-ak`, `03r-al`, `03r-am`, `03r-an`, `03r-ao` (the 130 rule, § Order).

### 03r-ab · Front 09 ships four arms; the binary-protocol stores are boot refusals until lg2-a

**Measured.** MongoDB (OP_MSG + BSON), Neo4j (Bolt), Cassandra (CQL binary) and Couchbase (memcached
binary) are byte protocols; every host cell marshals through `string` (lg2-a), and each needs an OTP
driver a sidecar cannot load. ETS and Mnesia are in the VM; Redis is RESP over `gen_tcp` (text);
Elasticsearch is HTTP + JSON.
**Options.** (a) 09 ships `ets:memory`, `mnesia:local`/`mnesia:cluster`, `redis://`, `https://`
(Elasticsearch), the behavior suite run against all four in the gate; `mongodb://`, `bolt://`,
`cassandra://`, `couchbase://` are recognised schemes whose boot refusal names lg2-a and the driver;
the 12 boxes of the closed steps 4 and 7 become the refusal cells plus one `deferred.md` row each.
(b) the four in an Erlang sidecar — four protocol clients, a front each. (c) defer 09 whole.
**Recommendation.** (a): a refusal naming the gap is the restrictive behaviour; a fallback to ETS
under a Mongo URL is what 09 forbids.
**Blocks.** 09 step 5 (and the scope of steps 1–4).

### 03r-ad · Pulsar: the member split and where the data plane goes

**Measured.** 91's 20 open boxes are one thing — the binary data plane (CONNECT, LOOKUP, producers,
consumers, flow, transactions) over `gen_tcp` — and each says "there is no Pulsar broker here". The
codec's byte half is blocked by lg2-a in botopink; an Erlang sidecar has binaries. On disk Pulsar is
`rakun-messaging/src/pulsar/**`, and `pulsar.bp` is the only `rakun-client` importer in the member
(`rakun-client` stays transitive through `rakun-metrics`).
**Options.** (a) split the member now (`modules/rakun-pulsar/`, depends on `rakun`,
`rakun-messaging`, `rakun-client`, `rakun-security`, `rakun-data` — `rakun-tx` before 128) and defer
the data plane whole to one `deferred.md` row; 91 is the split and the refusal cell "a `pulsar://`
listener refuses the boot naming the data plane". (b) split and write the data plane against a
fixture-broker sidecar (`rakun_pulsar_fixture.erl`) — the largest front of the track, weeks.
(c) neither: it stays inside `rakun-messaging`.
**Recommendation.** (a): the split is a day and takes the direct `rakun-client` edge off
`rakun-messaging`; a data plane with no broker to capture frames from is a protocol written blind.
**Blocks.** 91 whole.

### 03r-ae · SAML 2.0 ACS: Exclusive XML Canonicalisation in a sidecar, or the SP retired

**Measured.** Verifying an IdP signature needs Exclusive C14N (`xml-exc-c14n`), which neither OTP's
`xmerl` nor std provides; `saml2/saml2.bp` answers 501 at `/saml2/acs`.
**Options.** (a) exc-c14n over `xmerl`'s tree in `src/sidecars/rakun_saml2.erl` (~300 lines) and the
three boxes closed with fixture assertions signed by a checked-in key. (b) retire the SP: the three
boxes deleted, `saml2/` keeps its 501 and a `deferred.md` row. (c) leave them open.
**Recommendation.** (a) if 79 is staffed this milestone, (b) if not — never (c).
**Blocks.** 79 step 3.

### 03r-af · The seven unbuilt example projects are retired from the plan

**Measured.** `examples/` holds `rakun`, `rakun-container`, `rakun-ssr`, each a `test-libs` build
cell; the closed `modules.md` § Examples lists seven more (`rest-service`, `secured-api`,
`blog-server`, `order-pipeline`, `observed-service`, `realtime-gateway`, `release-kit`), none
started. Every member's contract is asserted by its own `test/**`.
**Options.** (a) retire the seven; the three on disk gain a `README.md` each and stay the only
example cells. (b) build them, one front each, after every member front has landed. (c) build
`rest-service` only.
**Recommendation.** (a).
**Blocks.** 73 step 3.

The snapshot layer is [`decisions-pending.md`](../decisions-pending.md) `snap-a`, worked by [`20-snap`](../20-snap/README.md) step 2.

### 03r-ak · CycloneDX: a `required` / `type` validator over the checked-in schema

**Measured.** R81-3: "validates against the CycloneDX 1.5 schema — asserted against a checked-in
schema, with no network access". std has no JSON-schema validator; `sbom.bp` asserts the required
fields by name.
**Options.** (a) `release_test.bp` reads a checked-in `bom-1.5.schema.json` with `json.decode` and
walks the SBOM against `required`, `type`, `enum` and local `$ref`s (~120 lines). (b) amend the box
to the field-by-field list. (c) a `json.schema` in std (not rakun's).
**Recommendation.** (a).
**Blocks.** 81 step 3.

### 03r-al · 83's broker path enrols in 86's producer transaction

**Measured.** `rakun-data/src/tx` (`outbox_test.bp` "path choice: broker transactions skip the
outbox, otherwise the outbox is used") holds the choice minus the broker. The broker side exists:
`rakun-messaging/src/reliability/transaction.bp` `withProducerTransaction` holds a transaction's
publishes and releases them in order on commit, drops them on a raise, so a `read_committed` reader
never sees an aborted one (`transaction_test.bp`). What is missing is 83's outbox path enrolling in
it.
**Options.** (a) the outbox path, with the in-process broker configured transactional, publishes
through `withProducerTransaction` and writes no outbox row; R83-1's boxes are reworded to the
in-process broker and the real-broker run is a `deferred.md` row. (b) delete the two boxes. (c)
leave them open.
**Recommendation.** (a).
**Blocks.** 15 step 5.

### 03r-am · Where the broker and scheduler doubles live

**Measured.** `rakun-test` depends on `rakun` only, and `rakun-messaging/test/*.bp` imports
`rakun-test`. Adding `rakun-test → rakun-messaging` makes a package-level cycle unless the loader
honours test scope (a `02-packaging` rule, not verified).
**Options.** (a) measure first: add the edge in 19's worktree; if `botopink test` in
`modules/rakun-messaging` refuses the cycle, the doubles live beside the module they double
(`rakun-messaging/src/broker_double.bp` + `rakun_messaging_double.erl`,
`rakun-scheduling/src/task_double.bp`) and `rakun-test` documents them. (b) the edge, assuming the
rule landed. (c) the doubles in `rakun-test`, reaching the registries through core hooks only
(`rkOnReset`, the `rakun_listener_names` term).
**Recommendation.** (a) with (c) as the shape either way: no `-test` member imports a member that
imports it.
**Blocks.** 19 steps 3 and 4.

### 03r-an · RSocket's WebSocket transport: the `rakun-websocket` edge, or a core extension point

**Raised by:** 92 (R92-1). **Measured.** R92-1 mounts the RSocket connection on `rakun-websocket`'s
`#[wsEndpoint]`. After 128 RSocket lives in `rakun-messaging`, so the edge `rakun-messaging →
rakun-websocket` (acyclic) would load `rakun-websocket`'s tree (`rakun-security`, `rakun-session`,
`rakun-scheduling`) for every messaging consumer.
**Options.** (a) take the edge. (b) the core defines a transport extension point that
`rakun-websocket` plugs into, no member edge (decision 185's rule). (c) retire the WebSocket
transport: R92-1's two boxes and the `ws://` / `wss://` arms of R92-7 deleted, TCP and TLS only.
**Recommendation.** (b): decision 185's rule is written for exactly this edge.
**Blocks.** 92 step 2's first and third boxes.

## Hygiene items

| Item | What | Front |
|---|---|---|
| RX-1 | `??`-with-a-dummy-record workarounds (`if (x == null)` narrowing exists) | 11 (`rakun-actuator/src/endpoint_host.bp:136,152`) · 79 (`rakun-security/test/basic_test.bp:137,174`) · 04 (`rakun/test/config_test.bp:569`) |
| RX-2 | "declared parameter defaults are never applied" (the decorator-argument case) — re-measured in the owning member's tests, result recorded | 04 (14, 72) · 08 (78) · 12 · 15 (15, 86, 90) · 22 (60, 61, 64, 66); 21's was corrected by 13 step 4 |
| RX-4 | the closed `status.md` L82 rows (static root, `Request` query/headers) | 65 (R82-4) · 04 (R62-3) |
| RX-5 | the snapshot layer | `20-snap` step 2 (`snap-a`) |
| RX-6 | the seven example projects | 73 (03r-af) |
| RX-7 | `modules.md` vs the tree | 128 (the nine merges) · 91 (03r-ad) |
| RX-10 | "consume std" (`02-std-and-packaging/97` § Consumers): `config.parseDuration` (`rakun/src/config.bp`) and `jwt.skewOf` (`rakun-security/src/jwt.bp`) → `clock.parseDuration` (one unit, digits only — not ISO `PT…`); number parsers answering a `@Result` (`rakun-metrics/src/registry.bp`, `rakun-scheduling/src/cron.bp`, `rakun/src/config.bp`) → `parseInt` / `parseFloat`; `Json` accessors (`jwt.bp`, `rakun/src/autoconfig_registry.bp`) → the `Json` methods; `rakun_security.erl`'s `pbkdf2` → `hash.pbkdf2Sha256` (salt as text, decision 175) | 04 (`config.bp`, `autoconfig_registry.bp`) · 79 (`jwt.bp`, `rakun_security.erl`) · 17 (`rakun-metrics`) · 15 (`cron.bp`) |
| RX-11 | "consume std": the four retry loops → `async.RetryPolicy` / `retry` — `rakun-messaging/src/reliability/policy.bp` (its own `RetryPolicy` / `nextDelay`, decision 170; mind 97's residual 4), the outbox (`rakun-tx/src/outbox.bp`, `rakun-data/src/tx/` after 128), `rakun-scheduling/src/jobstore/scheduler.bp`, the `rakun-mail` sidecar | 15 (the first three) · `rakun-mail`: **unowned** (no open front) |
| RX-12 | "consume std": constant-time equality (`rakun/src/request_context.bp`) → `hash.equalsConstantTime`; `sha256` (`rakun-ws/src/ws.bp`, `rakun-client/src/ws/` after 128) → `hash.sha256`; `xmlEscape` (`config.bp`) → `escape.attribute`; `cron.rkFormatUtc`, the logger's `rkLogIso` → `clock.formatIso8601` | 04 · 93 · 15 · 17 |
| RX-13 | the onze wire names `__bp_action` / `X-Bp-Action` spelled as literals in rakun's tests (`rakun-app/test/actions_test.bp`, `rakun-app/test/fixtures/actions-cache/test/actions_cache_test.bp.fixture`) — decision 114: neither library spells onze's defaults; `07-onze/49` step 2's last box closes when they are gone | 22 |

RX-3 (decisions 113–117's rakun halves), RX-8 (the `record ↔ Json` row, 13 step 4) and RX-9 (READMEs
state current state) are done.

## Cross-track dependencies

| Direction | This track | Other track | What crosses |
|---|---|---|---|
| rakun ⇄ `01-compiler/130` | 04 · 08 · 11 · 13 · 15 · 22 · 65 · 79 · 88 · 128 | 130 step 5 (decision 216) | the decorator rewrite of the rakun sites — § Order, the 130 rule (to confirm) |
| rakun → onze | 65 (R82-4) | 49 step 4 (decision 201) | a static-root miss falls through to the router, only `GET` / `HEAD` are served, a refusal stays final; onze registers `/**` → `public/` before the routes |
| rakun → onze | 04 (R62-3) · 22 | 49 (ONZ-49-4.3) | the page `Request` enumerates `queryDict()`, `headerNames()` / `headers()` so `RequestData.query` / `.headers` stop being `[]` |
| rakun ⇄ onze | 22 (R24-1, R24-2) | 50 (`useServer`), 53 (`serveActions`, the `__bp_action` / `X-Bp-Action` literals) | the file-level directive attached by `onze build`; the refresh payload is contract 2 |
| rakun → onze | 22 (60) | 53 (prerender), 71 (`staticExport`) · jhonstart 27 | the route kind the build writes (decision 186) and the prerender store |
| rakun → onze | 22 (66) | 70 | default size and content type via route discovery |
| rakun → onze | 11 (R11-4) · 04 (R06-6) · 81 | 71 | `POST /actuator/shutdown`, exit codes, the release's stop path |
| rakun ⇄ jhonstart via `03-bundled-libs/106` | 17 (R17-1) | 26 step 4 | one digest, `log`'s `errorDigest` (decision 194); rakun's logger installs itself as `log`'s sink, onze sets the sink for the render (decision 195) |
| rakun → jhonstart | 22 (R64-2, 66) | 32 | `Alternate[]`, `manifestHref`, `imagesFor`, `iconsFor` consumed unchanged; those boxes close when 32 ticks |
| rakun → onze | 88 (R88-6) | 50 | the CLI boundary table, mirrored in `07-onze/50-onze-cli/README.md` (onze's file) |
| rakun → std / packaging | 73 | lg2-v · PK-7 | a git dependency with a subdirectory, for an out-of-tree starter consumer |
| rakun → `01-compiler` | 04 · 08 · 09 · 13 · 15 · 22 · 65 · 88 · 91 · 92 · 93 | lg2-a · b · e · f · g · j · o · q · r · w | named per front; a box blocked on a compiler decision stays open and says so |
| `03-bundled-libs` → rakun | 128 · 22 · 65 · 04 · 79 · 12 · 19 · 17 · 81 | 102 step 3 (`rakun-app/src/{file_router,static_gen}.bp`, `rakun-hateoas/src/hal.bp`) · 103 step 2 (`rakun-app/src/actions.bp`) · 104 step 5 (`rakun/src/request_context.bp`, `rakun-web/src/{negotiation,compression,static,error}.bp`, `rakun-security/src/csrf.bp`, `rakun-session/src/session_cookie.bp`, `rakun-test/src/fake_request.bp`, `rakun-app/src/i18n.bp`) · 105 (`rakun-app/src/i18n.bp`) · 106 (`rakun-web/src/error.bp`'s `problem_digest`; the logging files are 17's) · 107 (`rakun-cli/src/release/release.bp`) | consumer commits, never in a wave with the owning front (decision 188): 102 and 103 before 128; 104, 105, 107 and 106's one commit after the owning fronts land |
| `08-bpp` → rakun | 04 · 65 · 22 | 123 (new `rakun/src/locals.bp`; lines of `rakun-web/src/{middleware,filter}.bp`) · 117 (`rakun-app/src/static_gen.bp`) · 120 (new `rakun-app/src/server_islands.bp`) · 127 (new `rakun-app/src/typed_action.bp`, one line of `actions.bp`) | after the owning rakun front: 123 after 04 and 65 (decision 189); 117, then 120, then 127 after 22, one at a time on `rakun-app`'s `botopink.json` and `root.bp` |

## Rules

- The compiler knows no library; a rakun front files a language-gaps row and works around it, and
  never edits `repository/botopink-lang/**`.
- rakun is erlang-only (decision 113): no commonJS row, no `.mjs`, no node twin — a
  `#[@External.Erlang]` cell with no node binding is the design.
- Every host module is `src/sidecars/rakun_<name>.erl`; a test-only one is `_fixture.erl` or
  `_double.erl`.
- `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp` of the core are frozen for every rakun
  front; the one writer allowed is `01-compiler/130`'s decision-216 rewrite (§ Order, to confirm).
- A shared member's `botopink.json` and `src/root.bp` belong to the lowest-numbered front in it; the
  others append in number order and never reorder.
- A member another member always needs is part of that member (decision 187). Between members that
  stay optional to each other, no edge is added when it would be a cycle or would drag a member into
  consumers that never configured it: the core defines the extension point (decision 185).
- rakun imports nothing from `jhonstart`, `emilia` or `onze` and builds no HTML.
- The most restrictive behaviour, and no configuration that bypasses it (decision 67).
- `status.md` of the milestone is the only status carrier.

# Track 04 — rakun

**Track:** 04 — rakun · **Repo:** `repository/rakun` · **Target:** erlang only (decision 113) ·
**Cut:** [`modules.md`](./modules.md) (the 25 members on disk, and the cut front 128 consolidates them into — decision 187) · **Carry map:** [`carried.md`](./carried.md) ·
**Closed record:** `specs/1.0.10-beta/03-rakun/` (51 fronts, frozen — nothing there is edited again)

1.0.10 landed rakun as 25 erlang members with every acceptance box but 194 ticked. This track holds
what rakun still owes: those 194 boxes, the nine cross-front hygiene items of the closing audit
(RX-1 … RX-9), and the cells that are green today only because they skip. It inherits the rules of
[`../overview.md`](../overview.md) and the first priority of the milestone — [`../00-gate/`](../00-gate/):
**a 100 % green gate, zero tolerated reds, in every repository**. Every rakun cell that is env-gated,
skipped, or "cannot be demonstrated in the gate" is named below with the front that turns it into a
real assertion or asks the maintainer to delete it. None stays tolerated.

The track opens with one front that is not a tail: [`128-rakun-consolidation`](./128-rakun-consolidation/README.md)
merges nine members into the member that always loads or solely uses them (decision 187). Every
other front sequences after it and works on the tree it leaves.

| Document | Holds |
|---|---|
| [`modules.md`](./modules.md) | the member tree as it is on disk (25 members, 8 starters, 3 examples), the package graph read from the manifests, the cut after front 128, the member question still open (91), front → directory ownership for this milestone |
| [`carried.md`](./carried.md) | 1.0.10 front → 1.0.11 front, item by item: carried, closed-on-tick, closed-by-amendment, or owned by another track |
| `NN-<name>/README.md` | the 20 fronts — 19 carried, and 128, new in this milestone; `examples/*.bp` under a front are the 1.0.10 example files whose `// LANGUAGE GAP:` markers are still open, copied, not referenced |

## How the numbering works

A front number is an identifier: a carried front keeps its 1.0.10 number and name, and a front that
consolidates several tails is named after the **lowest** number it carries and lists the others in
its `Carries:` line. Rakun's 51 carried numbers (04–25, 60–66, 72–93) are all accounted for in
[`carried.md`](./carried.md): 19 are directories here, 32 are closed or absorbed. One number is
allocated new in this milestone: **128**, the consolidation.

## What rakun still owes

Measured on `repository/rakun` at the opening of this milestone (`grep -c '^\s*- \[ \]'` over the 51
READMEs of the closed record; `find repository/rakun -name '*.snap'`; `grep -rn RAKUN_TEST_ modules`):

| Kind | Count | Where it goes |
|---|---|---|
| Open acceptance boxes | 194 in 35 READMEs (09: 41 · 91: 21 · 11: 13 · 19: 11 · 93: 11 · 92: 10 · 88: 9 · 06: 8 · 90: 8 · 79: 6 · 04: 5 · 81: 5 · 25: 4 · 74: 4 · the rest 1–3) | one front per member group, below |
| Cells green only by skipping | 2: `rakun-session/test/store_test.bp` "the suite runs on the Redis arm when `RAKUN_TEST_REDIS_URL` is set" (prints `SKIPPED`, asserts an empty string); `rakun-websocket/test/broadcast_test.bp:102` (accepts `skipped: <why>` when the runner cannot start a peer node) | `12-rakun-cache` (the Redis double — decision 160) · `92-rakun-rsocket` (the single-node arm, carve-out) |
| Integration cells never written | 15's `RAKUN_TEST_AMQP_URL` / `RAKUN_TEST_KAFKA_BROKERS` / `RAKUN_TEST_REDIS_URL` suites; 09's six opt-in suites; 83's Kafka producer transaction; 91's whole data plane | never written as gated cells: the in-process broker and the doubles are the gate arms (decision 160); real-driver verification is a `deferred.md` row, not a cell |
| commonJS ledger lines | 18 in `repository/botopink-lang/scripts/restricted-targets.txt` (`rakun … commonJS … 03-rakun`, by design of decision 113) | not rakun's file; decision 153 deletes the ledger — a member runs on the targets its manifest declares (`00-gate/113`) |
| "Blocked on the toolchain" boxes | R04 (`botopink run` of the three examples), R81-1/2 (the booted tarball), R88-1 (`rakun run`) — all cite the language-gaps toolchain row "a built erlang program cannot load its `.erl` sidecars" | re-measure first: `botopink build --target erlang` now ships a package's sidecars into `out/erl/` and `botopink run` compiles them (03r-a's *compiler half*); the row is likely stale for `run` and still true for a release tarball, which must compile them itself (81) |
| Snapshot layer | 57 `assert<Subject>` helpers and ~1 900 `.snap` files mapped in the closed `test-snap.md`; 0 exist; `rakun-test` holds `assertions.bp` (`expect*`), `context.bp`, `fake_request.bp`, `mockmvc.bp` | 03r-ag (retire or build), owned by `19-rakun-test-utilities` |
| Example projects | 3 on disk (`rakun`, `rakun-container`, `rakun-ssr`); 7 in the closed `modules.md` never started | 03r-af, owned by `73-rakun-starters` |
| `modules.md` drift | no `rakun-pulsar` (91 lives in `rakun-messaging/src/pulsar/**`); `rakun-ws` never renamed `rakun-soap`; `rakun-validation` gone (decision 116); `rakun-starter-app` missing; three example names; the dependency graph on disk differs from the drawn one in 20 of 25 rows (`modules.md` § The graph lists every difference) | [`modules.md`](./modules.md) here is corrected to the tree; `rakun-ws` is merged into `rakun-client` by front 128, not renamed (decision 187); the member question left is 03r-ad (91) |
| `// LANGUAGE GAP:` markers without a row | `13/examples/http-exchange-example.bp:84` and `21/examples/hal-resource-example.bp:136` ("no record ↔ `Json` derivation") | `13-rakun-http-clients` files the row (RX-8) |
| `??`-with-a-dummy-record workarounds | `rakun-actuator/src/endpoint_host.bp:136,152` · `rakun-security/test/basic_test.bp:137,174` · `rakun/test/config_test.bp:548` | 11 · 79 · 04 (RX-1) |

## The fronts

| Front | Priority | Carries | Member(s) | Parallel group | Depends on |
|---|---|---|---|---|---|
| [`128-rakun-consolidation/`](./128-rakun-consolidation/README.md) | critical | — (new; decision 187) | every member: nine merged, the manifests and imports of the rest | first, alone | `00-gate/99` · the rakun consumer commits of `03-bundled-libs` 102 step 3 and 103 step 2 (decision 188) |
| [`04-rakun-erlang-runtime/`](./04-rakun-erlang-runtime/README.md) | critical | 05 · 06 · 14 · 62 | `rakun` (core) — all but 74's files, `actuator_api/**` (11) and `logging/**` (17) | A | 128 · its step 1 (the tag epoch, decision 185) is what 13 and 12 wait on · lg2-e · lg2-g · lg2-j |
| [`74-rakun-tls-ssl-bundles/`](./74-rakun-tls-ssl-bundles/README.md) | high | — | `rakun` (`ssl_bundle.bp`, `rakun_ssl.erl`) · `rakun-web/src/tls.bp` | A | 128 |
| [`08-rakun-data-sql/`](./08-rakun-data-sql/README.md) | high | 77 · 78 | `rakun-data` (`sql/**`, `migration/**`, `orm/**`, `datasource.bp`) | A | 128 · lg2-e/f · lg2-r (the `try`-in-a-lambda rule is decision 147) |
| [`15-rakun-messaging/`](./15-rakun-messaging/README.md) | high | 16 · 83 · 86 · 89 · 90 | `rakun-messaging` (all but `pulsar/**` and `rsocket/**`; `stream/**` after 128) · `rakun-data/src/tx/**` (was `rakun-tx`) · `rakun-scheduling` | A | 128 · 03r-al · lg2-w (one box) |
| [`79-rakun-oauth2-sso/`](./79-rakun-oauth2-sso/README.md) | high | 10 (files only, no open box) | `rakun-security` | A | 128 · 03r-ae |
| [`81-rakun-packaging-release/`](./81-rakun-packaging-release/README.md) | high | — | `rakun-cli/src/release/**` (was `rakun-release`) | A | 128 · 03r-ak · toolchain row re-measure |
| [`93-rakun-soap-webservices/`](./93-rakun-soap-webservices/README.md) | low | — | `rakun-client/src/ws/**` (was `rakun-ws`; merged, not renamed — decision 187) | A | 128 |
| [`19-rakun-test-utilities/`](./19-rakun-test-utilities/README.md) | high (blocking) | — | `rakun-test` | A (step 1) · C (steps 3–5) | 128 · 03r-ag · 03r-am · 15 · 04 (R06-6) · the double is decision 160 |
| [`73-rakun-starters/`](./73-rakun-starters/README.md) | medium | — | `starters/**` · `examples/**` | A (decision 189) | 128 · 03r-af · lg2-v · toolchain row re-measure |
| [`13-rakun-http-clients/`](./13-rakun-http-clients/README.md) | high | 21 (RX-8 file only) | `rakun-client` (all but `ws/**`) | B | 04 step 1 (the tag epoch, decision 185) · lg2-a/b (streaming body) |
| [`17-rakun-logging/`](./17-rakun-logging/README.md) | medium | 75 | `rakun/src/logging/**` (was `rakun-logging`) · `rakun-metrics` | B | 128 · `03-bundled-libs/106`'s package (decisions 194, 195) · 13 (R75-1) |
| [`22-rakun-file-routing/`](./22-rakun-file-routing/README.md) | critical | 23 · 24 · 25 · 60 · 61 · 63 · 64 · 66 | `rakun-app` | B | 04 step 5 (the core `Request`'s accessors) · decision 186 (step 4) · onze 50 · 53 · jhonstart 30 · 32 · lg2-q |
| [`12-rakun-cache/`](./12-rakun-cache/README.md) | medium | 18 | `rakun-cache` · `rakun-session` | B | 19 step 1 (Redis double) · 04 step 1 |
| [`11-rakun-actuator/`](./11-rakun-actuator/README.md) | medium | 76 · 87 (files only) | `rakun-actuator` · `rakun/src/actuator_api/**` (was `rakun-actuator-api`) | B | 128 · 04 (a boot hook for R11-5, if one is needed) · 22 (R11-7) |
| [`65-rakun-url-rules/`](./65-rakun-url-rules/README.md) | high | 07 · 82 (+ one line of the devtools property source) | `rakun-web` (all but `tls.bp`; `hateoas/**` holds no open box) · one line of `rakun-data/src/devtools/devtools.bp` | B | 13 (R65-1) · decision 201 (step 1) · lg2-a/b |
| [`09-rakun-data-nosql/`](./09-rakun-data-nosql/README.md) | low | — | `rakun-data/src/nosql/**` | B | 19 step 1 · 13 · 03r-ab · lg2-a (four arms) |
| [`91-rakun-pulsar/`](./91-rakun-pulsar/README.md) | low | — | `rakun-messaging/src/pulsar/**` → `rakun-pulsar` | B | 15 · 03r-ad · lg2-a |
| [`92-rakun-rsocket/`](./92-rakun-rsocket/README.md) | low | 20 (one test file, carve-out) | `rakun-messaging/src/rsocket/**` (was `rakun-rsocket`) | B | 74 · 15 (the member's manifest) · lg2-a |
| [`88-rakun-cli/`](./88-rakun-cli/README.md) | medium | — | `rakun-cli` (all but `release/**`) | C | 81 · 93 · 92 · 04 (R88-3) · lg2-j · onze 50 |

Priorities: **critical** blocks another track (128 blocks every rakun front; 22 blocks onze 49/53
and jhonstart 27/32; 04 blocks onze 49 through R62-3 and 13 and 12 through its tag epoch). **high**
closes a member's own contract or a gate stance. **medium/low** is breadth.

## Order

```
128 consolidation ── first, alone in the repository (after the rakun consumer commits of 102 step 3 and 103 step 2)
           │
A (9 in parallel once 128 has landed, no other rakun dependency)
  04 core ─┬─ step 1: the tag epoch (decision 185) lands first, alone
  74 tls   │  08 data-sql   15 messaging   79 oauth2   81 release   93 soap   73 starters
           │  19 test-utils step 1 (the Redis double)
           │
B (9 in parallel once A's named step has landed)
  04 step 1 ──► 13 client · 12 cache(+18 session)
  04 step 5 ──► 22 app
  19 step 1 ──► 12 cache · 09 nosql
  13 ─────────► 09 nosql (Elasticsearch over the client) · 65 web (streamed relay) · 17 logging (R75-1)
  15 ─────────► 91 pulsar · 92 rsocket (the member's manifest)
  74 ─────────► 92 rsocket
  22 ─────────► 11 actuator (R11-7 only; the other 12 boxes run beside 22)
           │
C (2, last)
  81 · 93 · 92 · 04 ──► 88 cli
  15 · 04 ───────────► 19 test-utils steps 3–5 (broker double, bootAndExit)
```

The groups say what may run together; how many do, and in which wave beside the other tracks, is
[`../fronts.md`](../fronts.md) § Execution order of tracks 03–08.

**Why 128 is first.** It moves nine members and rewrites the manifests and imports of the rest, so
any front open beside it edits a file at a path that is about to change. After it the core holds
the logger and the span API, which is what removes two seams the old cut needed (decision 187).

**Why 04 step 1 is first inside A.** `rakun-cache` and `rakun-client` stay separate members and
must not depend on each other (`rakun-cache`'s manifest pulls session, data and scheduling), so the
core carries what crosses between them: a per-tag epoch `rakun-cache` bumps and `rakun-client`
reads (decision 185 — when an edge would be a cycle or would drag a member into consumers that
never configured it, the core defines the extension point and the members plug into it). It is a
few lines in `modules/rakun/src/runtime.bp` and `rakun_runtime.erl`; landing it as 04's first step
lets 13 and 12 start on day two.

**Why 19 step 1 is first.** The Redis RESP double (decision 160) is what turns 18's skipped cell, 12's
untested Redis provider and 09's Redis arm into gate assertions. It lives in `rakun-test`
(`src/sidecars/rakun_redis_double.erl`), which depends on the core only, so it adds no edge.

## Parallel groups

Two fronts may run together only when they share no source file and no test directory. 128 runs
alone. After it the cut is by member, and by sub-directory where 128 put two fronts in one member;
the cases where two fronts sit in one member are:

| Member (after 128) | Fronts | Why they do not collide |
|---|---|---|
| `rakun` | 04 · 74 · 17 · 11 | 74 owns `src/ssl_bundle.bp`, `src/sidecars/rakun_ssl.erl`, `test/ssl_bundle_test.bp`, `test/tls_listener_test.bp`; 17 owns `src/logging/**`, `test/logging/**`, `src/sidecars/rakun_logging.erl`; 11 owns `src/actuator_api/**`, `test/actuator_api/**`, `src/sidecars/rakun_actuator_api.erl`; 04 owns the rest. `botopink.json` and `src/root.bp` are 04's; 74, 17 and 11 add no file to the member |
| `rakun-web` | 65 · 74 | 74 owns `src/tls.bp` and `test/tls_test.bp` only (its 1.0.10 carve-out); `src/hateoas/**` holds no open box and is 65's with the rest |
| `rakun-data` | 08 · 09 · 15 · 65 | 09 owns `src/nosql/**`, `test/nosql/**`, `src/sidecars/rakun_nosql.erl`; 15 owns `src/tx/**` and `test/tx/**` (carries 83); 65 owns one line of `src/devtools/devtools.bp` and `test/devtools/devtools_test.bp`; 08 edits neither `botopink.json` nor `src/root.bp` in this milestone (its three boxes add no file), so 09's append to both does not wait on 08 |
| `rakun-messaging` | 15 · 91 · 92 | 91 owns `src/pulsar/**`, `test/pulsar/**`, `src/sidecars/rakun_pulsar.erl`, `src/pulsar_host.bp`; 92 owns `src/rsocket/**`, `test/rsocket/**`, `src/sidecars/rakun_rsocket.erl`; 15 owns the rest, `src/stream/**` included. `botopink.json` and `src/root.bp` are 15's: 91 edits them only if 03r-ad splits the member, 92 only for the edge R92-1 needs, and each after 15 has landed — sequenced, not parallel |
| `rakun-client` | 13 · 93 | 93 owns `src/ws/**`, `test/ws/**`, `src/sidecars/rakun_ws.erl`; `botopink.json` and `src/root.bp` are 13's, and 93 appends its generator's lines when 13 does not hold them — sequenced, not parallel |
| `rakun-cli` | 88 · 81 | 81 owns `src/release/**`, `test/release/**`, `src/sidecars/rakun_release.erl`; 88 owns the rest and runs after 81 (group C). `botopink.json` and `src/root.bp` are 81's as the lower number; 88 appends after it lands. The `rakun ws generate` command is 88's step, after 93 |
| `rakun-websocket` | 92 (carve-out) | no other front touches the member; 92 owns `test/broadcast_test.bp` and the runner in `rakun_websocket.erl` § broadcast for the skipped arm |
| `rakun-test` | 19 | 12, 09 and 18's cells import the double; none edits `rakun-test` |
| `starters/**`, `examples/**` | 73 | no module front touches them after 128 |

### Where a merged member's front works

Decision 187 moves nine members; a front's directory and number do not move with them. Where a
front README names a merged member, it means the member's new home:

| Named in a README | After 128 it is | Front |
|---|---|---|
| `rakun-actuator-api` | `modules/rakun/src/actuator_api/**` (the core) | 11 |
| `rakun-logging` | `modules/rakun/src/logging/**` (the core) | 17 |
| `rakun-hateoas` | `modules/rakun-web/src/hateoas/**` | — (closed; its example file is under 13) |
| `rakun-ws` / `rakun-soap` | `modules/rakun-client/src/ws/**` | 93 |
| `rakun-tx` | `modules/rakun-data/src/tx/**` | 15 |
| `rakun-devtools` | `modules/rakun-data/src/devtools/**` | 65 (one line) |
| `rakun-release` | `modules/rakun-cli/src/release/**` | 81 |
| `rakun-rsocket` | `modules/rakun-messaging/src/rsocket/**` | 92 |
| `rakun-stream` | `modules/rakun-messaging/src/stream/**` | 15 |

An import `from "rakun-<merged>"` in a README's acceptance is an import from the absorbing member;
a test file keeps its name under `test/<merged>/`.

Groups A, B and C above are the parallel sets. Inside a group, every pair is file-disjoint. The
cross-group edges are the named steps, not whole fronts: a B front may open its worktree the day the
A step it names is on `feat`.

## Gate stance, per cell

The rule of this milestone: a cell is a hard assertion or it does not exist. For rakun:

| Cell today | Front | Stance |
|---|---|---|
| `rakun-session/test/store_test.bp` — Redis arm, `RAKUN_TEST_REDIS_URL` | 12 | **make green**: the suite runs against `rakun-test`'s RESP double on a loopback port; the env variable and the `SKIPPED` print are deleted (decision 160) |
| `rakun-websocket/test/broadcast_test.bp:102` — `skipped: ` when no peer node | 92 | **make green**: the cell asserts a same-node `pg` broadcast to two subscriber processes; the cross-node arm needs `erl` distribution the gate does not run and is deleted, with a `deferred.md` row (decision 160) |
| 15's three integration suites (never written) | 15 | **never written as gated cells**: the in-process broker (03r-k) is the gate arm for every messaging cell; a real driver is the language-gaps row "a sidecar cannot reach an external OTP application" and a `deferred.md` row |
| 09's six opt-in suites (never written) | 09 | **four arms in the gate** — ETS, Mnesia (in-VM), Redis (the double), Elasticsearch (13's client against an in-process HTTP double); Mongo/Neo4j/Cassandra/Couchbase are boot refusals naming lg2-a (03r-ab). No `report skipped` cell anywhere |
| 83's Kafka producer transaction (never written) | 15 | **make green** through the in-process broker gaining transactional visibility (03r-al) |
| 91's data plane (20 boxes, needs a broker) | 91 | **decision**: a fixture-broker sidecar, or the data plane deferred (03r-ad) — either way no gated cell |
| R04 / R81-1 / R81-2 / R88-1 "toolchain row" boxes | 73 · 81 · 88 | **re-measure**: `botopink run` of `examples/rakun` after `botopink build --target erlang`; the tarball compiles `out/erl/*.erl` into its `ebin` (81's own step) |
| 18 commonJS ledger lines | `00-gate/113` | **structurally absent** (decision 153): the ledger and `known-red-libs.txt` are deleted; a member is run on the targets its manifest declares, and a rakun member on a commonJS row is a manifest error |

## What the maintainer must decide

The 24 choices of 1.0.10 (`03r-a` … `03r-x`, in `specs/1.0.10-beta/decisions-pending.md` § Track B)
are implemented and await confirmation; the fronts here build on them as written and name the ones
they touch (03r-b/c/d → 04; 03r-e → 04; 03r-i/j → 12; 03r-k/l → 15; 03r-m/n → 22; 03r-r → 73;
03r-s → 17; 03r-v → 08; 03r-w → 79 and 13; 03r-x → 15). The questions this track adds continue the
letter sequence. Each is in the milestone's `decisions-pending.md` shape; the recommendation is the
most restrictive reading, with no configuration that bypasses it (decision 67).

Seven of the fifteen are answered and live in [`../decisions-taken.md`](../decisions-taken.md);
the fronts are written against the decision, not the question:

| Id | Decision | What the fronts implement |
|---|---|---|
| 03r-y | 184, superseded by 187 | no failure-report plugin: logging is in the core after 128, and the core and `rakun-app` log through it (04 step 5, 22 step 3, 17) |
| 03r-z | 185 | the core keeps a per-tag epoch (`rkTagEpoch` / `rkBumpTag`); `rakun-cache` bumps it, `rakun-client` reads it (04 step 1, 13 step 1, 12 step 3). The rule for every such seam: no member-to-member edge when it would be a cycle or drag a member into consumers that never configured it — the core defines the extension point |
| 03r-aa | 160 | a cell that needs an external service is not a gate cell: it runs against an in-process double; a cell that prints "skipped" has not passed (19 step 1, 12 steps 1–2, 09 step 3, 92 step 1) |
| 03r-ac | 187 | `rakun-ws` is not renamed: front 128 merges it into `rakun-client` (93) |
| 03r-ah | 153 | the ledger is deleted; a member runs on the targets its manifest declares (`00-gate/113`) |
| 03r-ai | 186 | the stage a page renders in is a compile-time fact; rakun only reads the route kind the build writes. Until the checker capability lands the renderer marks through `ChunkWriter.markDynamic(reason)` (22 step 4) |
| 03r-aj | 187 | the span API is the core's after 128; `rakun-app` reaches it through the dependency it has (22 step 5, 11's R11-7) |

Open: `03r-ab`, `03r-ad`, `03r-ae`, `03r-af`, `03r-ag`, `03r-ak`, `03r-al`, `03r-am`.

### 03r-ab · Front 09 ships four arms; the binary-protocol stores are boot refusals until lg2-a

**Raised by:** `09-rakun-data-nosql`.
**Measured.** MongoDB (OP_MSG + BSON), Neo4j (Bolt), Cassandra (CQL binary) and Couchbase (memcached
binary) are byte protocols; every host cell marshals through `string` (language-gaps row 2, lg2-a),
so none can be written in botopink today, and each needs an OTP driver a sidecar cannot load
(toolchain row 2). ETS and Mnesia are in the VM; Redis is RESP over `gen_tcp` (text); Elasticsearch
is HTTP + JSON over 13's client.
**Options.** (a) 09 ships `ets:memory`, `mnesia:local`/`mnesia:cluster`, `redis://`, `https://`
(Elasticsearch) with the behavior suite run against all four in the gate; `mongodb://`, `bolt://`,
`cassandra://`, `couchbase://` are recognised schemes whose boot refusal names lg2-a and the driver;
the 12 boxes of steps 4 and 7 are rewritten as the refusal cells plus one `deferred.md` row each.
(b) write the four in an Erlang sidecar (bytes are native there) — four protocol clients, each a
front of its own. (c) defer 09 whole.
**Recommendation.** (a). A refusal that names the gap is the restrictive behaviour; a fallback to ETS
under a Mongo URL is the one thing 09's own README forbids.
**Blocks.** 09 steps 4 and 7.

### 03r-ad · Pulsar: the member split and where the data plane goes

**Raised by:** `91-rakun-pulsar`.
**Measured.** 91 is 6 of 27 boxes: topic names, the admin arm over 13, settings checks and the codec's
CRC32C vector. The 20 open boxes are one thing — the binary data plane (CONNECT, LOOKUP, producers,
consumers, flow, transactions) over `gen_tcp` — and every one says "there is no Pulsar broker here".
The codec's "byte half" is blocked by lg2-a in botopink; an Erlang sidecar has binaries. The closed
`modules.md` makes `rakun-pulsar` its own member (its edges to 79, 83, 13 would otherwise reach every
AMQP consumer); on disk it is `rakun-messaging/src/pulsar/**`, and `rakun-messaging`'s manifest
already carries `rakun-client` for it.
**Options.** (a) split the member now (`modules/rakun-pulsar/`, depends on `rakun`, `rakun-messaging`,
`rakun-client`, `rakun-security`, `rakun-tx`) and defer the data plane whole to `deferred.md`, the 20
boxes moving there as one row; 1.0.11's front is the split and the refusal cell "a `pulsar://` listener
refuses the boot naming the data plane". (b) split and write the data plane against a fixture-broker
sidecar (`rakun_pulsar_fixture.erl` playing the broker side of the protocol) — the largest front of
the track, weeks. (c) neither: leave it inside `rakun-messaging`.
**Recommendation.** (a). The split is a day and removes three edges from every messaging consumer;
the data plane without a broker to capture frames from is a protocol written blind, and the gate
cannot hold it. A refusal cell keeps the surface honest.
**Blocks.** 91 whole.

### 03r-ae · SAML 2.0 ACS: Exclusive XML Canonicalisation in a sidecar, or the SP retired

**Raised by:** `79-rakun-oauth2-sso` (R79-2, three boxes).
**Measured.** Step 8 is cut at the ACS: verifying an IdP signature needs Exclusive C14N
(`xml-exc-c14n`), which neither OTP's `xmerl` nor std provides; `saml2/saml2.bp` answers 501 and
`ldap_test.bp`-style refusal cells are green.
**Options.** (a) implement exc-c14n over `xmerl`'s parse tree in `src/sidecars/rakun_saml2.erl`
(namespace visibility, attribute ordering, whitespace rules — a bounded, well-specified algorithm,
~300 lines) and close the three boxes with a fixture assertion signed by a checked-in key. (b) retire
the SP: delete the three boxes and `saml2/` keeps its 501 with a `deferred.md` row. (c) leave the
boxes open.
**Recommendation.** (a) if 79 is staffed this milestone, (b) if it is not — but never (c): an open box
whose closing needs nothing outside the repository is a box the plan must either schedule or delete.
**Blocks.** 79 step 3.

### 03r-af · The seven unbuilt example projects are retired from the plan

**Raised by:** `73-rakun-starters` (RX-6).
**Measured.** `examples/` holds `rakun`, `rakun-container`, `rakun-ssr`, each a `test-libs` cell; the
closed `modules.md` § Examples lists `rest-service`, `secured-api`, `blog-server`, `order-pipeline`,
`observed-service`, `realtime-gateway`, `release-kit` (and `test-snap-examples.md` maps ~90 cases over
them); none was started. Every member's contract is asserted by its own `test/**` (2 000+ tests).
**Options.** (a) retire the seven; `test-snap-examples.md` stays a closed record; the three on disk
gain a `README.md` each (packaging PK-2) and stay the only example cells. (b) build them, one front
each, after every member front has landed. (c) build `rakun-rest-service` only, as the one Spring-shaped
walkthrough.
**Recommendation.** (a). An example that is not a gate cell is prose; one that is a gate cell is a
second assertion of values the member suites already verify, at seven projects' cost.
**Blocks.** 73 step 3.

### 03r-ag · The 57-helper snapshot layer is retired; `test-snap.md` is a closed record

**Raised by:** `19-rakun-test-utilities` (RX-5).
**Measured.** The closed `test-snap.md` (11 647 lines) specifies 57 `assert<Subject>(loc, …)` helpers
and one `.snap` per acceptance box; `rakun-test/src` holds four files and no helper; no `.snap` exists
under `repository/rakun`. Every landed box is asserted by a named test in `modules/<member>/test/**`.
The same question stands in the other tracks (jhonstart JH-SNAP, emilia EM-4, std STD-5).
**Options.** (a) retire the layer for rakun: `rakun-test` keeps its four surfaces and grows the doubles
19 still owes; the contract copy in `19-rakun-test-utilities/test-snap-helpers.md` is deleted when
this is answered. (b) build it: 57 helpers, then re-record every acceptance box as a snapshot — a
milestone of its own. (c) build the helpers for new fronts only (09, 91).
**Recommendation.** (a), answered once for every library. A snapshot is evidence of a verified value;
the values are verified by the suites that exist, and a second recording of them adds ~1 900 files
that fail on every deliberate change.
**Blocks.** 19 step 6; the same box in the other tracks.

### 03r-ak · CycloneDX: a `required` / `type` validator over the checked-in schema

**Raised by:** `81-rakun-packaging-release` (R81-3).
**Measured.** The box: "validates against the CycloneDX 1.5 schema — asserted against a checked-in
schema, with no network access". std has no JSON-schema validator; `sbom.bp` asserts the required
fields by name.
**Options.** (a) `release_test.bp` reads the checked-in `bom-1.5.schema.json` with `json.decode` and
walks the SBOM against the schema's `required` arrays and `type` keywords (objects, arrays, strings,
enums) — a bounded subset (~120 lines), no `$ref` resolution beyond the local definitions the schema
uses. (b) amend the box to the field-by-field list. (c) a `json.schema` in std (not rakun's to write).
**Recommendation.** (a): the assertion the box asks for, from the file it names.
**Blocks.** 81 step 3.

### 03r-al · Kafka producer transactions run against the in-process broker

**Raised by:** `15-rakun-messaging` (R83-1, three boxes of 83).
**Measured.** `outbox_test.bp` "path choice: broker transactions skip the outbox, otherwise the outbox
is used" holds the path choice minus the broker; the two remaining boxes say "with a Kafka broker" and
"a consumer in `read_committed` mode". The in-process broker (03r-k) has no transaction.
**Options.** (a) the in-process broker gains `beginTx` / `commitTx` / `abortTx` with `read_committed`
visibility (an uncommitted publish is held back from consumers; an abort discards it), and 83's Kafka
path enrols in it; the boxes are reworded to the broker double, and the real-broker run is a
`deferred.md` row. (b) delete the two boxes. (c) leave them open.
**Recommendation.** (a): the outbox-skipping path is then exercised end to end, which is what the
boxes are for.
**Blocks.** 15 step 5.

### 03r-am · Where the broker and scheduler doubles live: `rakun-test`, or beside the module they double

**Raised by:** `19-rakun-test-utilities` (R19-1 … R19-3).
**Measured.** The closed `modules.md` gives `rakun-test` a test-only edge to every member and says the
resolver must treat `<lib>-test` as test-scope (a `02-packaging` rule, not verified landed). On disk
`rakun-test` depends on `rakun` only, and `rakun-messaging/test/*.bp` imports `rakun-test`. Adding
`rakun-test → rakun-messaging` makes `rakun-messaging ⇄ rakun-test` at package level unless the
loader honours test scope.
**Options.** (a) measure first: add the edge in 19's worktree; if `botopink test` in
`modules/rakun-messaging` refuses the cycle, the doubles live beside the module they double
(`rakun-messaging/src/broker_double.bp` + `rakun_messaging_fixture.erl`, `rakun-scheduling/src/task_double.bp`)
and `rakun-test` documents them without importing them. (b) the edge, on the assumption the rule
landed. (c) the doubles in `rakun-test` reaching the registries through core-level hooks only
(`rkOnReset`, a listener-names term) — the pattern R19-1/R19-2 already name.
**Recommendation.** (a) with (c) as the shape either way: the registries expose what a double needs
through the core, and no `-test` member imports a member that imports it.
**Blocks.** 19 steps 3 and 4.

## Hygiene items, assigned

| Item | What | Front |
|---|---|---|
| RX-1 | the five `??`-with-a-dummy-record workarounds (`if (x == null)` narrowing exists) | 11 (`endpoint_host.bp:136,152`) · 79 (`basic_test.bp:137,174`) · 04 (`config_test.bp:548`) |
| RX-2 | "declared parameter defaults are never applied" text in the closed READMEs of 12, 14, 15, 21, 60, 61, 64, 66, 72, 86, 90 — C-04 closed the plain case; the decorator-argument case is the language-gaps decorator-default row | the front owning the member re-measures the decorator-argument case in that member's tests and records the result in its README: 12 → 12 · 14/72 → 04 · 15/86/90 → 15 · 60/61/64/66 → 22 · 21 → 13 |
| RX-3 | decisions 113–117's rakun halves landed | `carried.md` § Closed; nothing to do |
| RX-4 | the closed `status.md` L82 rakun rows (static root, `Request` query/headers) | 65 (R82-4) · 04 (R62-3) |
| RX-5 | the snapshot layer | 19 (03r-ag) |
| RX-6 | the seven example projects | 73 (03r-af) |
| RX-7 | `modules.md` / `fronts.md` vs the tree | [`modules.md`](./modules.md) here; 128 for the nine merges (decision 187), 91 for the one member question left |
| RX-8 | two `// LANGUAGE GAP:` markers without a row (`13/…:84`, `21/…:136`) | 13 files one row, "no record ↔ `Json` derivation", in the milestone's `language-gaps.md`; both example files are copied under `13-rakun-http-clients/examples/` |
| RX-9 | landed READMEs carrying a pre-implementation "Current state" | every README here states the state measured at the opening of this milestone; the closed ones are not edited |

## Cross-track dependencies

| Direction | This track | Other track | What crosses |
|---|---|---|---|
| rakun → onze | 65 (R82-4) | 49 step 4 (69, decision 201) | a miss in a static root falls through to the router, only `GET` / `HEAD` are served, a refusal stays final; onze then registers `/**` → `public/` before the routes |
| rakun → onze | 04 (R62-3) | 49 (ONZ-49-4.3) | the page `Request` enumerates `queryDict()` and `headerNames()` / `headers()` so `RequestData.query` / `.headers` stop being `[]` |
| rakun ⇄ onze | 22 (R24-1, R24-2) | 50 (the `useServer` directive), 53 (`ONZ-53-5`: `serveActions`, the missing-key refusal, the `__bp_action` / `X-Bp-Action` literals) | the file-level directive is attached by `onze build`; the refresh payload is contract 2 |
| rakun → onze | 22 (60) | 53 (ONZ-53-3 prerender), 71 (ONZ-71-7 `staticExport`) · jhonstart 27 (JH-27-3b) | the route kind the build writes (decision 186 — a compile-time fact rakun only reads) and the prerender store |
| rakun → onze | 22 (66) | 70 (ONZ-70-1) | default size and content type via route discovery |
| rakun → onze | 11 (R11-4) · 04 (R06-6) · 81 | 71 (shutdown cells) | `POST /actuator/shutdown`, exit codes, the release's stop path |
| rakun ⇄ jhonstart, through `03-bundled-libs/106` | 17 (R17-1) | 26 step 4 (JH-31-digest) | one digest scheme with one implementation, `log`'s `errorDigest` (decision 194); both import the bundled `log`, rakun's logger installs itself as its sink and onze sets the sink for the render (decision 195) |
| rakun → jhonstart | 22 (R64-2, 66's two boxes) | 32 | `Alternate[]`, `manifestHref`, `imagesFor`, `iconsFor` consumed unchanged — rakun owns nothing in those boxes; they close when 32 ticks |
| rakun → onze | 88 (R88-6) | 50 | the CLI boundary table mirrored in `07-onze/50-onze-cli/README.md` — onze's file; 88 copies the table here so the mirror has a source |
| rakun → std / packaging | 73 | lg2-v · PK-7 | a git dependency with a subdirectory, for an out-of-tree consumer of a starter |
| rakun → `00-gate` | all | `113-gate-ledger-and-scripts` (decision 153) | the ledger lines, deleted; the restriction audit's rakun rows drop by nine with 128 |
| rakun → `01-compiler` | 04 · 08 · 15 · 22 · 88 · 09 · 91 · 92 · 65 | lg2-a · lg2-b · lg2-e · lg2-f · lg2-g · lg2-j · lg2-m · lg2-o · lg2-q · lg2-r · lg2-w | named per front; a box blocked on a compiler decision stays open and says so; the front never edits `repository/botopink-lang/modules/**` |
| `03-bundled-libs` → rakun | 128 (it moves two of the files) · 22 · 65 · 04 · 79 · 12 · 19 · 17 · 81 | 102 step 3 (`rakun-app/src/{file_router,static_gen}.bp`, `rakun-hateoas/src/hal.bp`) · 103 step 2 (`rakun-app/src/actions.bp`, the derivation) · 104's consumer sweep (`rakun/src/request_context.bp`, `rakun-web/src/{negotiation,compression,static,error}.bp`, `rakun-security/src/csrf.bp`, `rakun-session/src/session_cookie.bp`, `rakun-test/src/fake_request.bp`, `rakun-app/src/i18n.bp`) · 105 (`rakun-app/src/i18n.bp`) · 106 (`rakun-web/src/error.bp`, the `problem_digest` cell — the logging files are switched to `log` by 17 itself) · 107 (`rakun-cli/src/release/release.bp`) | consumer commits, never in a wave with the front that owns the member (decision 188): 102 and 103 before 128; 104, 105, 107 and 106's one commit after the owning fronts have landed |
| `08-bpp` → rakun | 04 · 65 · 22 | 123 (new `rakun/src/locals.bp`; lines of `rakun-web/src/{middleware,filter}.bp`) · 117 (`rakun-app/src/static_gen.bp`) · 120 (new `rakun-app/src/server_islands.bp`) · 127 (new `rakun-app/src/typed_action.bp`, one line of `actions.bp`) | each after the rakun front that owns the member: 123 after 04 and 65 (decision 189); 117, then 120, then 127 after 22, one at a time on `rakun-app`'s `botopink.json` and `root.bp` |

## Rules

- The compiler knows no library; a rakun front files a language-gaps row and works around it.
- rakun is erlang-only (decision 113): no commonJS row, no `.mjs`, no node twin, ever — a
  `#[@External.Erlang]` cell with no node binding is the design, not a red.
- Every host module is `src/sidecars/rakun_<name>.erl`; a test-only host module is
  `src/sidecars/rakun_<name>_fixture.erl` or `_double.erl`.
- `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp` of the core stay frozen.
- A shared member's `botopink.json` and `src/root.bp` belong to the lowest-numbered front in it;
  the others append in number order and never reorder.
- A member another member always needs is not a plugin, it is part of that member (decision 187).
  Between members that stay optional to each other, no edge is added when it would be a cycle or
  would drag a member into consumers that never configured it: the core defines the extension
  point and the members plug into it (decision 185).
- rakun imports nothing from `jhonstart`, `emilia` or `onze` and builds no HTML.
- The most restrictive behaviour, and no configuration that bypasses it (decision 67).
- Specs describe current state and remaining work; `status.md` of the milestone is the only status
  carrier.

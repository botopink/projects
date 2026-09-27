# Track 03 — rakun

**Track:** 03 — rakun · **Repo:** `repository/rakun` · **Target:** erlang only (decision 113) ·
**Cut:** [`modules.md`](./modules.md) (the 25 members on disk) · **Carry map:** [`carried.md`](./carried.md) ·
**Closed record:** `specs/1.0.10-beta/03-rakun/` (51 fronts, frozen — nothing there is edited again)

1.0.10 landed rakun as 25 erlang members with every acceptance box but 194 ticked. This track holds
what rakun still owes: those 194 boxes, the nine cross-front hygiene items of the closing audit
(RX-1 … RX-9), and the cells that are green today only because they skip. It inherits the rules of
[`../overview.md`](../overview.md) and the first priority of the milestone — [`../00-gate/`](../00-gate/):
**a 100 % green gate, zero tolerated reds, in every repository**. Every rakun cell that is env-gated,
skipped, or "cannot be demonstrated in the gate" is named below with the front that turns it into a
real assertion or asks the maintainer to delete it. None stays tolerated.

| Document | Holds |
|---|---|
| [`modules.md`](./modules.md) | the member tree as it is on disk (25 members, 8 starters, 3 examples), the package graph read from the manifests, the two naming decisions (91, 93), front → directory ownership for this milestone |
| [`carried.md`](./carried.md) | 1.0.10 front → 1.0.11 front, item by item: carried, closed-on-tick, closed-by-amendment, or owned by another track |
| `NN-<name>/README.md` | the 19 fronts; `examples/*.bp` under a front are the 1.0.10 example files whose `// LANGUAGE GAP:` markers are still open, copied, not referenced |

## How the numbering works

A front number is an identifier: a carried front keeps its 1.0.10 number and name, and a front that
consolidates several tails is named after the **lowest** number it carries and lists the others in
its `Carries:` line. No number above 96 is allocated. Rakun's 51 numbers (04–25, 60–66, 72–93) are all
accounted for in [`carried.md`](./carried.md): 19 are directories here, 32 are closed or absorbed.

## What rakun still owes

Measured on `repository/rakun` at the opening of this milestone (`grep -c '^\s*- \[ \]'` over the 51
READMEs of the closed record; `find repository/rakun -name '*.snap'`; `grep -rn RAKUN_TEST_ modules`):

| Kind | Count | Where it goes |
|---|---|---|
| Open acceptance boxes | 194 in 35 READMEs (09: 41 · 91: 21 · 11: 13 · 19: 11 · 93: 11 · 92: 10 · 88: 9 · 06: 8 · 90: 8 · 79: 6 · 04: 5 · 81: 5 · 25: 4 · 74: 4 · the rest 1–3) | one front per member group, below |
| Cells green only by skipping | 2: `rakun-session/test/store_test.bp` "the suite runs on the Redis arm when `RAKUN_TEST_REDIS_URL` is set" (prints `SKIPPED`, asserts an empty string); `rakun-websocket/test/broadcast_test.bp:102` (accepts `skipped: <why>` when the runner cannot start a peer node) | `12-rakun-cache` (Redis double, 03r-aa) · `92-rakun-rsocket` (the single-node arm, carve-out) |
| Integration cells never written | 15's `RAKUN_TEST_AMQP_URL` / `RAKUN_TEST_KAFKA_BROKERS` / `RAKUN_TEST_REDIS_URL` suites; 09's six opt-in suites; 83's Kafka producer transaction; 91's whole data plane | never written as gated cells: the in-process broker and the doubles are the gate arms (03r-aa); real-driver verification is a `deferred.md` row, not a cell |
| commonJS ledger lines | 18 in `repository/botopink-lang/scripts/restricted-targets.txt` (`rakun … commonJS … 03-rakun`, by design of decision 113) | not rakun's file; the stance is 03r-ah, addressed to `00-gate` |
| "Blocked on the toolchain" boxes | R04 (`botopink run` of the three examples), R81-1/2 (the booted tarball), R88-1 (`rakun run`) — all cite the language-gaps toolchain row "a built erlang program cannot load its `.erl` sidecars" | re-measure first: `botopink build --target erlang` now ships a package's sidecars into `out/erl/` and `botopink run` compiles them (03r-a's *compiler half*); the row is likely stale for `run` and still true for a release tarball, which must compile them itself (81) |
| Snapshot layer | 57 `assert<Subject>` helpers and ~1 900 `.snap` files mapped in the closed `test-snap.md`; 0 exist; `rakun-test` holds `assertions.bp` (`expect*`), `context.bp`, `fake_request.bp`, `mockmvc.bp` | 03r-ag (retire or build), owned by `19-rakun-test-utilities` |
| Example projects | 3 on disk (`rakun`, `rakun-container`, `rakun-ssr`); 7 in the closed `modules.md` never started | 03r-af, owned by `73-rakun-starters` |
| `modules.md` drift | no `rakun-pulsar` (91 lives in `rakun-messaging/src/pulsar/**`); `rakun-ws` never renamed `rakun-soap`; `rakun-validation` gone (decision 116); `rakun-starter-app` missing; three example names; the dependency graph on disk differs from the drawn one in 20 of 25 rows (`modules.md` § The graph lists every difference) | [`modules.md`](./modules.md) here is corrected to the tree; the member questions are 03r-ac (93) and 03r-ad (91) |
| `// LANGUAGE GAP:` markers without a row | `13/examples/http-exchange-example.bp:84` and `21/examples/hal-resource-example.bp:136` ("no record ↔ `Json` derivation") | `13-rakun-http-clients` files the row (RX-8) |
| `??`-with-a-dummy-record workarounds | `rakun-actuator/src/endpoint_host.bp:136,152` · `rakun-security/test/basic_test.bp:137,174` · `rakun/test/config_test.bp:548` | 11 · 79 · 04 (RX-1) |

## The fronts

| Front | Priority | Carries | Member(s) | Parallel group | Depends on |
|---|---|---|---|---|---|
| [`04-rakun-erlang-runtime/`](./04-rakun-erlang-runtime/README.md) | critical | 05 · 06 · 14 · 62 | `rakun` (core) | A | 03r-y · 03r-z (its step 1 is what B waits on) · lg2-e · lg2-g · lg2-j |
| [`74-rakun-tls-ssl-bundles/`](./74-rakun-tls-ssl-bundles/README.md) | high | — | `rakun` (`ssl_bundle.bp`, `rakun_ssl.erl`) · `rakun-web/src/tls.bp` | A | — |
| [`08-rakun-data-sql/`](./08-rakun-data-sql/README.md) | high | 77 · 78 | `rakun-data` (`sql/**`, `migration/**`, `orm/**`, `datasource.bp`) | A | lg-a · lg2-e/f · lg2-r |
| [`15-rakun-messaging/`](./15-rakun-messaging/README.md) | high | 16 · 83 · 86 · 89 · 90 | `rakun-messaging` (all but `pulsar/**`) · `rakun-tx` · `rakun-stream` · `rakun-scheduling` | A | 03r-al · lg2-w (one box) |
| [`79-rakun-oauth2-sso/`](./79-rakun-oauth2-sso/README.md) | high | 10 (files only, no open box) | `rakun-security` | A | 03r-ae |
| [`81-rakun-packaging-release/`](./81-rakun-packaging-release/README.md) | high | — | `rakun-release` | A | 03r-ak · toolchain row re-measure |
| [`93-rakun-soap-webservices/`](./93-rakun-soap-webservices/README.md) | low | — | `rakun-ws` → `rakun-soap` | A | 03r-ac |
| [`19-rakun-test-utilities/`](./19-rakun-test-utilities/README.md) | high (blocking) | — | `rakun-test` | A (step 1) · C (steps 3–5) | 03r-aa · 03r-ag · 03r-am · 15 · 04 (R06-6) |
| [`13-rakun-http-clients/`](./13-rakun-http-clients/README.md) | high | 21 (RX-8 file only) | `rakun-client` | B | 04 step 1 (03r-z seam) · lg2-a/b (streaming body) |
| [`17-rakun-logging/`](./17-rakun-logging/README.md) | medium | 75 | `rakun-logging` · `rakun-metrics` | B | 04 step 1 (03r-y seam) · 13 (R75-1) · 31-b |
| [`22-rakun-file-routing/`](./22-rakun-file-routing/README.md) | critical | 23 · 24 · 25 · 60 · 61 · 63 · 64 · 66 | `rakun-app` | B | 04 step 1 · 03r-ai · 03r-aj · onze 50 · 53 · jhonstart 30 · 32 · lg2-q |
| [`12-rakun-cache/`](./12-rakun-cache/README.md) | medium | 18 | `rakun-cache` · `rakun-session` | B | 19 step 1 (Redis double) · 04 step 1 |
| [`11-rakun-actuator/`](./11-rakun-actuator/README.md) | medium | 76 · 87 (files only) | `rakun-actuator` · `rakun-actuator-api` | B | 04 (a boot hook for R11-5, if one is needed) · 22 (R11-7) |
| [`65-rakun-url-rules/`](./65-rakun-url-rules/README.md) | high | 07 · 82 (+ one line of `rakun-devtools`) | `rakun-web` (all but `tls.bp`) | B | 13 (R65-1) · 69-b · lg2-a/b |
| [`09-rakun-data-nosql/`](./09-rakun-data-nosql/README.md) | low | — | `rakun-data/src/nosql/**` | B | 19 step 1 · 13 · 03r-ab · lg2-a (four arms) |
| [`91-rakun-pulsar/`](./91-rakun-pulsar/README.md) | low | — | `rakun-messaging/src/pulsar/**` → `rakun-pulsar` | B | 15 · 03r-ad · lg2-a |
| [`92-rakun-rsocket/`](./92-rakun-rsocket/README.md) | low | 20 (one test file, carve-out) | `rakun-rsocket` | B | 74 · lg2-a |
| [`73-rakun-starters/`](./73-rakun-starters/README.md) | medium | — | `starters/**` · `examples/**` | B | 03r-af · lg2-v · toolchain row re-measure |
| [`88-rakun-cli/`](./88-rakun-cli/README.md) | medium | — | `rakun-cli` | C | 81 · 93 · 92 · 04 (R88-3) · lg2-j · onze 50 |

Priorities: **critical** blocks another track (22 blocks onze 49/53 and jhonstart 27/32; 04 blocks
onze 49 through R62-3 and every B front through its seams). **high** closes a member's own contract
or a gate stance. **medium/low** is breadth.

## Order

```
A (8 in parallel, no rakun dependency)
  04 core ─┬─ step 1: the two seams (03r-y, 03r-z) lands first, alone
  74 tls   │  08 data-sql   15 messaging   79 oauth2   81 release   93 soap   19 test-utils step 1 (the Redis double)
           │
B (11 in parallel once A's named step has landed)
  04 step 1 ──► 13 client · 17 logging · 22 app · 12 cache(+18 session)
  19 step 1 ──► 12 cache · 09 nosql
  13 ─────────► 09 nosql (Elasticsearch over the client) · 65 web (streamed relay) · 17 (R75-1)
  15 ─────────► 91 pulsar
  74 ─────────► 92 rsocket
  22 ─────────► 11 actuator (R11-7 only; the other 12 boxes run beside 22)
  73 starters (waits on maintainer decisions only)
           │
C (2, last)
  81 · 93 · 92 · 04 ──► 88 cli
  15 · 04 ───────────► 19 test-utils steps 3–5 (broker double, bootAndExit)
```

**Why 04 step 1 is first.** Four B fronts need two seams that only the core can carry without a
package cycle: a failure-report sink rakun-logging installs (03r-y — the core's `after()` and
rakun-app's static regeneration both report through it; the core cannot depend on rakun-logging and
rakun-app should not) and a tag-epoch cell rakun-cache bumps and rakun-client reads (03r-z —
`rakun-client` must stay free of `rakun-cache`, whose manifest pulls session, data and scheduling).
Both are a few lines in `modules/rakun/src/runtime.bp` and `rakun_runtime.erl`; landing them as
04's first step lets 13, 17, 22 and 12 start on day two.

**Why 19 step 1 is first.** The Redis RESP double (03r-aa) is what turns 18's skipped cell, 12's
untested Redis provider and 09's Redis arm into gate assertions. It lives in `rakun-test`
(`src/sidecars/rakun_redis_double.erl`), which depends on the core only, so it adds no edge.

## Parallel groups

Two fronts may run together only when they share no source file and no test directory. The cut
above is by member; the cases where two fronts sit in one member are:

| Member | Fronts | Why they do not collide |
|---|---|---|
| `rakun` | 04 · 74 | 74 owns `src/ssl_bundle.bp`, `src/sidecars/rakun_ssl.erl`, `test/ssl_bundle_test.bp`, `test/tls_listener_test.bp`; 04 owns the rest. `botopink.json` and `src/root.bp` are 04's; 74 adds no file |
| `rakun-web` | 65 · 74 | 74 owns `src/tls.bp` and `test/tls_test.bp` only (its 1.0.10 carve-out) |
| `rakun-data` | 08 · 09 | 09 owns `src/nosql/**`, `test/nosql/**`, `src/sidecars/rakun_nosql.erl`; 08 edits neither `botopink.json` nor `src/root.bp` in this milestone (its three boxes add no file), so 09's append to both does not wait on 08 |
| `rakun-messaging` | 15 · 91 | 91 owns `src/pulsar/**`, `test/pulsar/**`, `src/sidecars/rakun_pulsar.erl`, `src/pulsar_host.bp`; it edits `botopink.json` only if 03r-ad splits the member, and then after 15 has landed — sequenced, not parallel |
| `rakun-cli` | 88 · 93 | 93's generator is library code in `rakun-ws`; the `rakun ws generate` command is 88's step, after 93 |
| `rakun-websocket` | 92 (carve-out) | no other front touches the member; 92 owns `test/broadcast_test.bp` and the runner in `rakun_websocket.erl` § broadcast for the skipped arm |
| `rakun-devtools` | 65 (carve-out) | one line: the dev-profile default `rakun.web.resources.cache.period=0` (R80-1 / R82-1) |
| `rakun-test` | 19 | 12, 09 and 18's cells import the double; none edits `rakun-test` |
| `starters/**`, `examples/**` | 73 | no module front touches them |

Groups A, B and C above are the parallel sets. Inside a group, every pair is file-disjoint. The
cross-group edges are the named steps, not whole fronts: a B front may open its worktree the day the
A step it names is on `feat`.

## Gate stance, per cell

The rule of this milestone: a cell is a hard assertion or it does not exist. For rakun:

| Cell today | Front | Stance |
|---|---|---|
| `rakun-session/test/store_test.bp` — Redis arm, `RAKUN_TEST_REDIS_URL` | 12 | **make green**: the suite runs against `rakun-test`'s RESP double on a loopback port; the env variable and the `SKIPPED` print are deleted (03r-aa) |
| `rakun-websocket/test/broadcast_test.bp:102` — `skipped: ` when no peer node | 92 | **make green**: the cell asserts a same-node `pg` broadcast to two subscriber processes; the cross-node arm needs `erl` distribution the gate does not run and is deleted, with a `deferred.md` row (03r-aa) |
| 15's three integration suites (never written) | 15 | **never written as gated cells**: the in-process broker (03r-k) is the gate arm for every messaging cell; a real driver is the language-gaps row "a sidecar cannot reach an external OTP application" and a `deferred.md` row |
| 09's six opt-in suites (never written) | 09 | **four arms in the gate** — ETS, Mnesia (in-VM), Redis (the double), Elasticsearch (13's client against an in-process HTTP double); Mongo/Neo4j/Cassandra/Couchbase are boot refusals naming lg2-a (03r-ab). No `report skipped` cell anywhere |
| 83's Kafka producer transaction (never written) | 15 | **make green** through the in-process broker gaining transactional visibility (03r-al) |
| 91's data plane (20 boxes, needs a broker) | 91 | **decision**: a fixture-broker sidecar, or the data plane deferred (03r-ad) — either way no gated cell |
| R04 / R81-1 / R81-2 / R88-1 "toolchain row" boxes | 73 · 81 · 88 | **re-measure**: `botopink run` of `examples/rakun` after `botopink build --target erlang`; the tarball compiles `out/erl/*.erl` into its `ebin` (81's own step) |
| 18 commonJS ledger lines | `00-gate` | **structurally absent** (03r-ah): a member is run on the targets its manifest declares; a rakun line in the ledger is a claim about a row rakun does not have |
| rakun line in `known-red-libs.txt` | — | none today; none is added |

## What the maintainer must decide

The 24 choices of 1.0.10 (`03r-a` … `03r-x`, in `specs/1.0.10-beta/decisions-pending.md` § Track B)
are implemented and await confirmation; the fronts here build on them as written and name the ones
they touch (03r-b/c/d → 04; 03r-e → 04; 03r-i/j → 12; 03r-k/l → 15; 03r-m/n → 22; 03r-r → 73;
03r-s → 17; 03r-v → 08; 03r-w → 79 and 13; 03r-x → 15). The questions this track adds continue the
letter sequence. Each is in the milestone's `decisions-pending.md` shape; the recommendation is the
most restrictive reading, with no configuration that bypasses it (decision 67).

### 03r-y · A failure-report seam in the core, installed by rakun-logging

**Raised by:** `04-rakun-erlang-runtime` (R62-2) and `22-rakun-file-routing` (R60-1).
**Measured.** `modules/rakun/src/request_context.bp`'s `after()` and `modules/rakun-app/src/static_gen.bp`'s
regeneration both write a failure to the node's standard error (`static_gen_test.bp` "a regeneration
that raises keeps the stale entry, is logged once, and a later one succeeds" reads
`regenerationFailures()`, not a log line). The boxes say "reported once to front 17 with the request
id" and "logs once through front 17". `rakun-logging` depends on `rakun` and `rakun-actuator-api`; a
core → rakun-logging edge is a cycle; a rakun-app → rakun-logging edge is legal but pulls the logger
into every app-router consumer that never configured one.
**Options.** (a) the core exports `rkReportFailure(kind: string, requestId: string, text: string) -> i32`
and `rkInstallFailureSink(sink: fn(string, string, string) -> i32)`; with no sink installed the
default writes the same line to standard error; rakun-logging's `setup.bp` installs its logger at
boot; core and rakun-app report through it. (b) a package edge `rakun-app → rakun-logging`, and the
core's `after()` box amended to "standard error". (c) leave both on standard error and amend the boxes.
**Recommendation.** (a). One reporting path, no new package edge, and the default is what happens
today, so an app without rakun-logging changes nothing. The test asserts the sink receives one call
per failure with the request id, from the core's and rakun-app's suites.
**Blocks.** 04 step 1; 17 step 2; 22 step 6.

### 03r-z · A tag-epoch seam in the core for rakun-client's response cache

**Raised by:** `13-rakun-http-clients` (R13-1).
**Measured.** `modules/rakun-client/src/cache.bp` caches responses "over front 12's store" by key and
TTL; `revalidateTag` is `rakun-cache`'s (`cache.bp`) and rakun-client never hears it — "`revalidateTag`
on one of the request's tags makes the next `retrieve()` reach the transport" is the one open box of
13. `rakun-cache`'s manifest depends on `rakun-web`, `rakun-actuator`, `rakun-session`; 13's own rule is
"12 soft — 13 lands without it".
**Options.** (a) the core keeps a per-tag epoch (`rkTagEpoch(tag) -> i32`, `rkBumpTag(tag) -> i32`,
in `rakun_runtime.erl`'s ETS); rakun-cache's `revalidateTag` bumps it, rakun-client stores the epochs
of a request's tags beside the cached response and treats a changed epoch as a miss. (b) the edge
`rakun-client → rakun-cache`. (c) amend the box: response caching has no tags.
**Recommendation.** (a). Two calls in the core, no edge, and rakun-cache and rakun-client stay
independent — the same shape as 03r-y.
**Blocks.** 04 step 1; 13 step 1; 12 step 3.

### 03r-aa · No rakun cell depends on an environment the gate does not provide

**Raised by:** the milestone's gate rule, against `rakun-session/test/store_test.bp` (the Redis arm),
`rakun-websocket/test/broadcast_test.bp:102` (the peer node), and the never-written opt-in suites of
09, 15, 83 and 91.
**Measured.** The session cell passes with `out == ""` when the variable is unset and prints
`SKIPPED`; the broadcast cell accepts `out.startsWith("skipped: ")`. Neither asserts the arm it names.
`rakun-mail` and `rakun-messaging` already ship fixture sidecars (`rakun_mail_fixture.erl`,
`rakun_jms_fixture.erl`) that play the remote side of a wire in-process; `rakun-session` carries a RESP
client (`rkSessRedis`) that 12 reuses (03r-i).
**Options.** (a) every such cell runs against an in-process double that speaks the wire — a RESP
double in `rakun-test` (`src/sidecars/rakun_redis_double.erl`: `GET SET SETEX DEL INCRBY HGET HSET
LPUSH RPOP TTL EXPIRE PING`, one ETS table per port) for 18, 12 and 09; the existing in-process broker
for 15, 83; a same-node `pg` arm for 20 — and the env-gated arms are deleted, with the real-service
verification recorded in `deferred.md`. (b) delete the env-gated cells and their arms outright.
(c) keep the gates and count a skip as a pass (refused by the milestone).
**Recommendation.** (a). A double that speaks the protocol asserts the arm's code; deleting the cell
asserts nothing. The double is test-only and ships no production path.
**Blocks.** 19 step 1; 12 steps 1–2; 09 step 3; 92 step 1.

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

### 03r-ac · `rakun-ws` is renamed `rakun-soap`

**Raised by:** `93-rakun-soap-webservices`.
**Measured.** The closed `modules.md` § Verdicts says *rename* ("`ws` reads as websocket now that
`rakun-websocket` exists"); on disk the member is `modules/rakun-ws/` with sidecar `rakun_ws.erl` and
`import … from "rakun-ws"` in its two tests; 93's own README says `rakun-soap`. Nothing depends on it
(`rakun-cli`'s optional edge was never written). No ledger line names it.
**Options.** (a) rename now, in 93's first commit: directory, manifest `name`, sidecar
`rakun_soap.erl`, the two test imports, `modules/README.md`, `AGENTS.md`. (b) keep `rakun-ws` and
correct `modules.md` to it.
**Recommendation.** (a). Zero consumers is the cheapest the rename will ever be, and a member whose
name says the wrong protocol is a defect in the consumer surface.
**Blocks.** 93 step 1.

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

### 03r-ah · rakun's eighteen commonJS ledger lines become structurally absent

**Raised by:** this track, addressed to `00-gate` (the ledger is
`repository/botopink-lang/scripts/restricted-targets.txt`, a compiler file rakun never edits).
**Measured.** Lines 60–82 of the ledger carry one `commonJS` line per rakun member and example
("`"targets": ["erlang"]` — rakun is erlang-only (decision 113)"), with a measured count or `build`.
Every rakun manifest, the workspace root included, declares `["erlang"]`. Ten members
(`rakun-ws`, `-websocket`, `-metrics`, `-mail`, `-tx`, `-stream`, `-rsocket`, `-release`, `-cli`,
`-devtools`) have no line, so the ledger is not even the full matrix.
**Options.** (a) `test-libs` runs a member on the targets its manifest declares and on no other; the
eighteen lines are deleted by `00-gate` in the commit that lands that rule; a rakun member on a
commonJS row is then a manifest error, not a ledger claim. (b) keep the lines and add ten.
(c) the lines become `build` for every member.
**Recommendation.** (a). A ledger line for a row a library does not have is a tolerated red by
another name, and the compiler knows no library — it should read the manifest.
**Blocks.** nothing in this track; the gate's own zero-red count.

### 03r-ai · One writer for the dynamic mark: the renderer, through `ChunkWriter.markDynamic()`

**Raised by:** `22-rakun-file-routing` (R23-1; `status.md` L123 of the closed milestone).
**Measured.** `rakun_ssr.erl`'s `markDynamic("searchParams")` fires on any read of the `Request`'s
query — which onze makes on every request when it builds `PageInput.query` / `RequestData.query` — so
rakun would mark every page dynamic; jhonstart's payload `d` is jhonstart's own mark (26-b) and
`PageContext` has no unmarked `query`. Two writers, one flag.
**Options.** (a) rakun's own reads never mark; `ChunkWriter` gains `markDynamic(reason: string)`, the
renderer (jhonstart, through onze) calls it when a page reads the query or a cookie, and 60's static
decision reads only that; `rakun_ssr.erl`'s implicit mark is deleted. (b) onze builds the input
without the marking read (a second, unmarked accessor on rakun's `Request`). (c) rakun reads
jhonstart's `d` back from the `Response`.
**Recommendation.** (a). One writer, explicit, on the contract both sides already implement
(contract 5d); (b) leaves two paths to the same data, (c) makes rakun read a jhonstart-shaped value.
**Blocks.** 22 step 4; onze 49's `pageInput`.

### 03r-aj · `rakun-app` depends on `rakun-actuator-api` for the render, action and handler spans

**Raised by:** `11-rakun-actuator` (R11-7) and `22-rakun-file-routing`.
**Measured.** `rakun-app` calls no `startSpan`; its manifest depends on `rakun`, `rakun-web`,
`rakun-cache`. `rakun-actuator-api` depends on the core only and is what `rakun-client` already imports
for `startSpan` / `traceparentOf` (`transport.bp:30`). The box: "`render`, `action` and `handler` spans
are emitted by fronts 23, 24 and 25 through this front's API, with no second hook into the request
path".
**Options.** (a) add the edge; `ssr.bp`, `actions.bp`, `route_handler.bp` open and end one span each
around the renderer, the action body and the handler body. (b) a span seam in the core like 03r-y.
(c) amend the box: no spans from rakun-app.
**Recommendation.** (a). The API module exists to be depended on; a second seam for the same purpose
is a second span API.
**Blocks.** 22 step 5; 11's R11-7 tick.

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
| RX-7 | `modules.md` / `fronts.md` vs the tree | [`modules.md`](./modules.md) here; 91 and 93 for the two member questions |
| RX-8 | two `// LANGUAGE GAP:` markers without a row (`13/…:84`, `21/…:136`) | 13 files one row, "no record ↔ `Json` derivation", in the milestone's `language-gaps.md`; both example files are copied under `13-rakun-http-clients/examples/` |
| RX-9 | landed READMEs carrying a pre-implementation "Current state" | every README here states the state measured at the opening of this milestone; the closed ones are not edited |

## Cross-track dependencies

| Direction | This track | Other track | What crosses |
|---|---|---|---|
| rakun → onze | 65 (R82-4) | 69 (69-b) | a miss in a static root falls through to the router; onze then registers `/**` → `public/` |
| rakun → onze | 04 (R62-3) | 49 (ONZ-49-4.3) | the page `Request` enumerates `queryDict()` and `headerNames()` / `headers()` so `RequestData.query` / `.headers` stop being `[]` |
| rakun ⇄ onze | 22 (R24-1, R24-2) | 50 (the `useServer` directive), 53 (`ONZ-53-5`: `serveActions`, the missing-key refusal, the `__bp_action` / `X-Bp-Action` literals) | the file-level directive is attached by `onze build`; the refresh payload is contract 2 |
| rakun → onze | 22 (60) | 53 (ONZ-53-3 prerender), 71 (ONZ-71-7 `staticExport`) · jhonstart 27 (JH-27-3b) | the static/dynamic decision (03r-ai) and the prerender store |
| rakun → onze | 22 (66) | 70 (ONZ-70-1) | default size and content type via route discovery |
| rakun → onze | 11 (R11-4) · 04 (R06-6) · 81 | 71 (shutdown cells) | `POST /actuator/shutdown`, exit codes, the release's stop path |
| rakun → jhonstart | 17 (R17-1) | 31 (JH-31-digest, 31-b) | one digest scheme; onze wires `onError` to `logErrorWithDigest` |
| rakun → jhonstart | 22 (R64-2, 66's two boxes) | 32 | `Alternate[]`, `manifestHref`, `imagesFor`, `iconsFor` consumed unchanged — rakun owns nothing in those boxes; they close when 32 ticks |
| rakun → onze | 88 (R88-6) | 50 | the CLI boundary table mirrored in `06-onze/50-onze-cli/README.md` — onze's file; 88 copies the table here so the mirror has a source |
| rakun → std / packaging | 73 | lg2-v · PK-7 | a git dependency with a subdirectory, for an out-of-tree consumer of a starter |
| rakun → `00-gate` | all | 03r-ah | the ledger lines |
| rakun → `00-compiler` | 04 · 08 · 15 · 22 · 88 · 09 · 91 · 92 · 65 | lg2-a · lg2-b · lg2-e · lg2-f · lg2-g · lg2-j · lg2-m · lg2-o · lg2-q · lg2-r · lg2-w · lg-a | named per front; a box blocked on a compiler decision stays open and says so; the front never edits `repository/botopink-lang/modules/**` |

## Rules

- The compiler knows no library; a rakun front files a language-gaps row and works around it.
- rakun is erlang-only (decision 113): no commonJS row, no `.mjs`, no node twin, ever — a
  `#[@External.Erlang]` cell with no node binding is the design, not a red.
- Every host module is `src/sidecars/rakun_<name>.erl`; a test-only host module is
  `src/sidecars/rakun_<name>_fixture.erl` or `_double.erl`.
- `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp` of the core stay frozen.
- A shared member's `botopink.json` and `src/root.bp` belong to the lowest-numbered front in it;
  the others append in number order and never reorder.
- rakun imports nothing from `jhonstart`, `emilia` or `onze` and builds no HTML.
- The most restrictive behaviour, and no configuration that bypasses it (decision 67).
- Specs describe current state and remaining work; `status.md` of the milestone is the only status
  carrier.

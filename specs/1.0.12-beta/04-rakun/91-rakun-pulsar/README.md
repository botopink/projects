# Front 91 — Pulsar: the member question and the data plane

**Priority:** low — a third broker behind an abstraction that has two; nothing depends on it; its 20
open boxes are one decision (03r-ad) · **State:** not started
**Depends on:** 128 · 15, landed (the split edits `rakun-messaging/{botopink.json,src/root.bp}`, 15's
until it lands; `publishWithRetry` and the `x-attempt` envelope) · 03r-ad · lg2-a (codec's byte half
in botopink; an Erlang sidecar has binaries)
**Owns:** `modules/rakun-messaging/src/pulsar/**`, `src/pulsar_host.bp`, `src/sidecars/rakun_pulsar.erl`,
`test/pulsar/**`; under 03r-ad (a)/(b): `modules/rakun-pulsar/**` and the removal lines in
`rakun-messaging/{botopink.json,src/root.bp}` · its `modules/README.md` row ·
`repository/rakun/AGENTS.md` § Pulsar
**Does not touch:** rest of `rakun-messaging` (15's; `src/rsocket/**` is 92's) · `rakun-security`,
`rakun-data`, `rakun-client` (consumed through their APIs) · the gate's files (a new member's
manifest `targets` is what `test-libs` reads — decision 153)

## Goal

The Pulsar arm stops pretending: under 03r-ad (a) its own member, a `pulsar://` listener refusing
the boot naming the deferred data plane; (b) data plane written against a fixture broker; (c)
nothing moves, the 20 boxes stay one open item.

## Mechanism

Today: `rakun-messaging/src/pulsar/{mod,pulsar}.bp`, `src/pulsar_host.bp`, `rakun_pulsar.erl`;
`test/pulsar/{admin_test,topic_test}.bp` green. Admin arm speaks Pulsar's HTTP admin API through
`rakun-client` (`pulsar.bp` the member's only `rakun-client` importer); codec's CRC32C matches the
Castagnoli vector; varint / length-prefix half marked `// LANGUAGE GAP:` in the example (lg2-a; no
bitwise operators by design). Closed front's 6 ticked boxes: topic names, admin arm, settings
checks, CRC vector; the 20 open (R91-1: closed steps 2–7, every wire box) each say "the data plane
is not written; there is no Pulsar broker here to capture frames from or run against".

- **Split (03r-ad (a)/(b)).** `modules/rakun-pulsar/` with `botopink.json` (`rakun`,
  `rakun-messaging`, `rakun-client`; `rakun-security`, `rakun-data` when the data plane exists —
  03r-ad (a) as written lists them from the start), `src/root.bp`, moved files and sidecar;
  `rakun-messaging` loses `pulsar/*`, `pulsar_host.bp`, the sidecar and its direct `rakun-client`
  edge (transitive through `rakun-metrics`).
- **Refusal cell (a).** `pulsar://` in `rakun.messaging.pulsar.url` refuses the boot: "the Pulsar
  data plane is not implemented (deferred: <row>); the admin arm is available".
- **Data plane (b).** `rakun_pulsar.erl` speaks the binary protocol (CONNECT, LOOKUP,
  PARTITIONED_METADATA, PRODUCER, SEND/SEND_RECEIPT, SUBSCRIBE, FLOW, ACK, NEGATIVE_ACK, PING/PONG,
  transaction commands) over `gen_tcp`; `rakun_pulsar_fixture.erl` plays the broker; botopink code
  sees strings. Weeks.

(a): one green refusal cell + one `deferred.md` row; (b): suite against the in-process fixture
broker. Never a cell waiting for a broker or reporting *skipped*.

## Open

### Step 1 — The member (only under 03r-ad (a) or (b); after 15 lands)

- [ ] `modules/rakun-pulsar/` exists with manifest, `src/root.bp`, moved files and sidecar; `rakun-messaging`'s manifest lists neither `pulsar/*` nor `rakun-client`; both suites green; `test-libs` lists the new cell
- [ ] `modules/README.md`, `AGENTS.md` § Pulsar and [`../modules.md`](../modules.md) list the member

### Step 2 — 03r-ad

- [ ] under (a): `test/refusal_test.bp` asserts the boot refusal's text for a `pulsar://` listener; the 20 boxes are one `deferred.md` row naming this README, the fixture-broker approach and lg2-a; `examples/pulsar-listener-example.bp` keeps its markers
- [ ] under (b): closed README's steps 2–7 copied here as steps 2–7, worked against `rakun_pulsar_fixture.erl`; "captured frames from a real broker" reworded to "frames the fixture accepts and the protocol's documented byte layout"
- [ ] under (c): step 1 not done, the 20 boxes stay open here naming lg2-a and the broker

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-messaging` (and `modules/rakun-pulsar` under (a)/(b)).

Blast radius: under (a)/(b) the split removes the direct `rakun-client` edge from `rakun-messaging`
and its consumers (merged `stream/**`, `rsocket/**` among them); `rakun-starter-messaging` keeps
`rakun-messaging` only; a Pulsar application adds `rakun-pulsar`.

`examples/pulsar-listener-example.bp` kept for its open marker (lg2-a and the bitwise rule).

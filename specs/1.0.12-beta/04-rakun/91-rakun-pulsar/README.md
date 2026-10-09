# Front 91 — Pulsar: the admin arm stays, the data plane is refused at boot and deferred

**Priority:** low — a third broker behind an abstraction that has two; nothing depends on it ·
**State:** not started
**Depends on:** 128 · 15, landed (`publishWithRetry` and the `x-attempt` envelope) · lg2-a (the
codec's byte half in botopink; an Erlang sidecar has binaries) · decision 274
**Owns:** `modules/rakun-messaging/src/pulsar/**`, `src/pulsar_host.bp`, `src/sidecars/rakun_pulsar.erl`,
`test/pulsar/**`, the new `test/pulsar/refusal_test.bp` · its `deferred.md` row ·
`repository/rakun/AGENTS.md` § Pulsar
**Does not touch:** rest of `rakun-messaging` (15's; `src/rsocket/**` is 92's) · `rakun-security`,
`rakun-data`, `rakun-client` (consumed through their APIs) · no member is created (274)

## Goal

Decision 274: Pulsar stays in `rakun-messaging/src/pulsar/` — no `rakun-pulsar` member, rakun keeps
16 members. What exists stays (topic names, the HTTP admin arm, the settings checks, the CRC32C
codec); a `pulsar://` listener refuses the boot naming the deferred data plane; the binary data
plane is one `deferred.md` row. A split is asked again only when a data plane exists and brings an
edge (`rakun-security`) no other messaging arm loads.

## Mechanism

Today: `rakun-messaging/src/pulsar/{mod,pulsar}.bp` (148 lines), `src/pulsar_host.bp`,
`rakun_pulsar.erl` (109 lines); `test/pulsar/{admin_test,topic_test}.bp` green. The admin arm speaks
Pulsar's HTTP admin API through `rakun-client` (`pulsar.bp` the member's only `rakun-client`
importer; the edge stays transitive through `rakun-metrics`, so no split would remove it). The
codec's CRC32C matches the Castagnoli vector; its varint / length-prefix half is marked
`// LANGUAGE GAP:` in the example (lg2-a; no bitwise operators by design).

- **Refusal cell.** `pulsar://` in `rakun.messaging.pulsar.url` refuses the boot: "the Pulsar data
  plane is not implemented (deferred: <row>); the admin arm is available".
- **Deferred.** The data plane — CONNECT, LOOKUP, PARTITIONED_METADATA, PRODUCER, SEND/SEND_RECEIPT,
  SUBSCRIBE, FLOW, ACK, NEGATIVE_ACK, PING/PONG, transaction commands over `gen_tcp` — is one
  `deferred.md` row naming this README, a fixture-broker sidecar (`rakun_pulsar_fixture.erl`) as the
  way to write it, and lg2-a. Never a cell waiting for a broker or reporting *skipped*.

## Open

### Step 1 — The refusal and the deferred row (decision 274)

- [ ] `test/pulsar/refusal_test.bp` asserts the boot refusal's text for a `pulsar://` listener; the
      admin and topic suites stay green
- [ ] one `deferred.md` row for the data plane, naming this README, the fixture-broker approach and
      lg2-a; `examples/pulsar-listener-example.bp` keeps its markers
- [ ] `repository/rakun/AGENTS.md` § Pulsar states the arm's scope (admin, settings, codec) and the
      refusal

### Step 2 — the listener spelling (decision 318 (5))

- [ ] the refused Pulsar listener is `#[listen(dest)]` with a Pulsar transport in the typed config; the
      boot refusal of step 1 names that transport

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-messaging`.

Blast radius: none outside `rakun-messaging`; `rakun-starter-messaging` unchanged.

`examples/pulsar-listener-example.bp` kept for its open marker (lg2-a and the bitwise rule).

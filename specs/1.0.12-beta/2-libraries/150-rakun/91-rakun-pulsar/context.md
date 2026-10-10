# Front 91 — Pulsar: the admin arm stays, the data plane is refused at boot and deferred

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [150-rakun](../README.md): s1 → 150 s18 · s2 → 150 s18. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** low — a third broker behind an abstraction that has two; nothing depends on it ·
**State:** not started
**Depends on:** 128 · 15, landed (`publishWithRetry` and the `x-attempt` envelope) · 346's `Bytes`, unbuilt (the
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
`// LANGUAGE GAP:` in the example (no byte type until 346's `Bytes`; no bitwise operators by design).

- **Refusal cell.** `pulsar://` in `rakun.messaging.pulsar.url` refuses the boot: "the Pulsar data
  plane is not implemented (deferred: <row>); the admin arm is available".
- **Deferred.** The data plane — CONNECT, LOOKUP, PARTITIONED_METADATA, PRODUCER, SEND/SEND_RECEIPT,
  SUBSCRIBE, FLOW, ACK, NEGATIVE_ACK, PING/PONG, transaction commands over `gen_tcp` — is one
  `deferred.md` row naming this README, a fixture-broker sidecar (`rakun_pulsar_fixture.erl`) as the
  way to write it, and 346's `Bytes`. Never a cell waiting for a broker or reporting *skipped*.

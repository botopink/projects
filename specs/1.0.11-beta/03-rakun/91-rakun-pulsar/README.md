# Front 91 — Pulsar

**Priority:** low — a third broker behind an abstraction that has two; nothing else depends on it. Its 20 open boxes are one decision (03r-ad)
**Carries:** —
**Depends on:** `15-rakun-messaging` (landed: the manifest edit that splits the member touches `rakun-messaging/{botopink.json,src/root.bp}`, which 15 owns until it lands; `publishWithRetry` and the `x-attempt` envelope) · maintainer 03r-ad · compiler lg2-a (the codec's byte half in botopink; an Erlang sidecar has binaries)
**Owns:** `modules/rakun-messaging/src/pulsar/**`, `src/pulsar_host.bp`, `src/sidecars/rakun_pulsar.erl`, `test/pulsar/**`; under 03r-ad (a) or (b): `modules/rakun-pulsar/**` and the removal lines in `rakun-messaging/{botopink.json,src/root.bp}` · `modules/README.md` row · `repository/rakun/AGENTS.md` § Pulsar
**Does not touch:** the rest of `rakun-messaging` (15's) · `rakun-security`, `rakun-tx`, `rakun-client` (consumed through their APIs) · `repository/botopink-lang/scripts/restricted-targets.txt` — a new member gets no commonJS line (03r-ah); if `00-gate` keeps the ledger, the line is the gate track's

---

## Carried from 1.0.10

Six of 27 boxes are ticked in `specs/1.0.10-beta/03-rakun/91-rakun-pulsar/README.md` (topic
names, the admin arm over 13, the settings checks, the CRC32C known-answer vector). The 20 open
boxes, verbatim in the closed record, are every box of steps 2–7 that touches the wire, each with
the same note: "the data plane (the connection, LOOKUP, producers, consumers) is not written;
there is no Pulsar broker here to capture frames from or run against". They are one item:

| Id | Boxes | Here |
|---|---|---|
| R91-1 | steps 2 (3), 3 (4), 4 (3), 5 (4), 6 (3), 7 (4) — 21 boxes less the ticked CRC vector | 03r-ad: (a) one `deferred.md` row and a refusal cell; (b) a fixture-broker sidecar and the boxes as written |
| member split | closed `modules.md` § Verdicts "`rakun-pulsar` — split from `rakun-messaging`" | step 1 |

## Problem

`rakun-messaging`'s manifest carries `rakun-client` for the Pulsar admin arm, and the data plane
would add `rakun-security` (OAuth2 client credentials) and `rakun-tx` (transactions) to every AMQP
consumer. A `pulsar://` listener boots today into an arm with no connection behind it.

## Current state

`rakun-messaging/src/pulsar/{mod,pulsar}.bp`, `src/pulsar_host.bp`, `rakun_pulsar.erl`;
`test/pulsar/{admin_test,topic_test}.bp` green (part of the member's 91). The admin arm speaks
Pulsar's HTTP admin API through `rakun-client`; the codec's CRC32C matches the Castagnoli vector;
the varint and length-prefix half is marked `// LANGUAGE GAP:` (lg2-a, and no bitwise operators by
design) in the example.

## Mechanism

- **The split (step 1).** `modules/rakun-pulsar/` with `botopink.json` (`rakun`, `rakun-messaging`,
  `rakun-client`; `rakun-security` and `rakun-tx` only when the data plane exists), `src/root.bp`,
  the moved files, the sidecar; `rakun-messaging` loses `pulsar/*`, `pulsar_host.bp`, the sidecar
  and its `rakun-client` edge; `modules/README.md` and `AGENTS.md` follow. The commonJS ledger is
  not edited (03r-ah).
- **The refusal cell (03r-ad (a)).** `pulsar://` in `rakun.messaging.pulsar.url` refuses the boot:
  "the Pulsar data plane is not implemented (deferred: <row>); the admin arm is available".
- **The data plane (03r-ad (b)).** `rakun_pulsar.erl` speaks the binary protocol (CONNECT,
  LOOKUP, PARTITIONED_METADATA, PRODUCER, SEND/SEND_RECEIPT, SUBSCRIBE, FLOW, ACK, NEGATIVE_ACK,
  PING/PONG, the transaction commands) over `gen_tcp`; `rakun_pulsar_fixture.erl` plays the broker
  side for the suite; botopink code sees strings. Weeks; the largest front of the track.

## Gate stance

Under (a) one refusal cell, green, and one `deferred.md` row; under (b) the suite runs against the
fixture broker in-process. In neither case a cell that waits for a broker or reports *skipped*.

## Steps

### Step 1 — The member (after 15 lands)

**Acceptance:**
- [ ] `modules/rakun-pulsar/` exists with its manifest, `src/root.bp`, the moved files and sidecar; `rakun-messaging`'s manifest no longer lists `pulsar/*` nor `rakun-client`; both members' suites green; `test-libs` lists the new cell
- [ ] `modules/README.md` and `AGENTS.md` § Pulsar updated; the closed `modules.md`'s verdict is now the tree

### Step 2 — 03r-ad

**Acceptance:**
- [ ] under (a): `test/refusal_test.bp` asserts the boot refusal's text for a `pulsar://` listener; the 20 boxes are one `deferred.md` row naming this README, the fixture-broker approach and lg2-a; `examples/pulsar-listener-example.bp` keeps its markers
- [ ] under (b): the closed README's steps 2–7 are copied into this file as steps 2–7 and worked against `rakun_pulsar_fixture.erl`; "captured frames from a real broker" is reworded to "frames the fixture accepts and the protocol's documented byte layout"

## Gate

- [ ] `botopink test --target erlang` green in `modules/rakun-pulsar` and `modules/rakun-messaging`
- [ ] `botopink format --check` clean
- [ ] `AGENTS.md` and `modules/README.md` updated
- [ ] commit on `fix/91-rakun-pulsar`

## Blast radius

The split removes `rakun-client` from every `rakun-messaging` consumer's transitive set
(`rakun-stream`, `rakun-rsocket`, `rakun-tx` through the seam). `rakun-starter-messaging` keeps
`rakun-messaging` only; an application on Pulsar adds `rakun-pulsar`.

## Notes

`examples/pulsar-listener-example.bp` is copied here for its open marker (lg2-a and the bitwise
rule).

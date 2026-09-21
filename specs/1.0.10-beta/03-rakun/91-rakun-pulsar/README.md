# Front 91 — Rakun Pulsar

**Track:** B rakun
**Priority:** low — a third broker behind an abstraction that already has two; valuable only to teams already on Pulsar, and nothing else in the milestone depends on it
**Target:** erlang (server)
**Wave:** 5
**Depends on:** 15 (the listener registry it becomes a fourth arm of), 86 (retry, dead-letter, acknowledgement), 79 (the client-credentials flow Pulsar's OAuth2 authentication is), 83 (the transaction coordinator Pulsar transactions hand off to), 74 (TLS), 13 (the HTTP client the admin arm uses), 05 (configuration)
**Owns:** `modules/rakun-messaging/src/pulsar/**`, `modules/rakun-messaging/test/pulsar/**`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` — frozen for the milestone. Inside `modules/rakun-messaging/`, `src/reliability/**` is front 86's, `src/jms/**` is front 90's, and everything else is front 15's; all three are read-only here.
**Reference:** `06-messaging.md § Apache Pulsar` (Conectando, Autenticacao OAuth2, Enviando Mensagens, Recebendo Mensagens, Lendo Mensagens, Transacoes) · https://docs.spring.io/spring-boot/reference/messaging/pulsar.html · https://pulsar.apache.org/docs/next/developing-binary-protocol/
**Replaces:** new

---

## Problem

Spring Boot 4 ships a Pulsar starter with a template, `@PulsarListener`, `@PulsarReader`, an admin
client and OAuth2 authentication (`06-messaging.md § Apache Pulsar`). rakun has none of it, and
unlike the JMS case there is no shortcut: Pulsar does not speak AMQP or STOMP. It speaks its own
binary protocol, and that protocol is the whole cost of this front.

**There is no mature BEAM Pulsar client.** This is the honest starting point, and it is the reason
this front is ranked last among the broker fronts rather than treated as a binding. The alternatives
were weighed and rejected: there is no protocol bridge worth relying on, the WebSocket gateway drops
most of the delivery semantics, and shelling out to a Java or Go client makes the BEAM node depend on
a runtime the milestone exists to avoid. What is left is to implement the client.

## Current state

- `repository/rakun/modules/rakun-messaging/src/root.bp` — a stub. Fronts 15 and 86 land first.
- There is no protobuf encoder or decoder anywhere in the workspace, and none in std
  (`libs/std/src/root.bp:13-36`).
- [`language-gaps.md`](../../language-gaps.md) records **no byte or binary type** and **no bitwise
  operators**. A length-prefixed, checksummed, protobuf-framed protocol needs both. That decides the
  architecture of this front before anything else does.

## Mechanism

**The wire lives in Erlang; botopink holds the surface.** Because there is no byte type and no shift
or mask operator, the frame codec cannot be written in botopink at all — not awkwardly, not at all.
So the protocol is one `#[@External.Erlang]` module and the botopink half is the façade: connection
configuration, the decorators, the destination model, the cursor model, and the registration into
front 15's registry. That split is not a workaround for this front only; it is the same shape every
socket-level front in the milestone takes, and it is the reason the two gap rows above are cited
rather than restated.

**How big the protocol half is, concretely.** A Pulsar frame is
`[totalSize][commandSize][BaseCommand][magic + CRC32C][metadataSize][MessageMetadata][payload]`. The
client needs roughly a dozen `BaseCommand` types and their responses:

| Purpose | Commands |
|---|---|
| Handshake | `CONNECT` / `CONNECTED`, `PING` / `PONG` |
| Topic resolution | `LOOKUP` / `LOOKUP_RESPONSE`, `PARTITIONED_METADATA` |
| Producing | `PRODUCER` / `PRODUCER_SUCCESS`, `SEND` / `SEND_RECEIPT`, `CLOSE_PRODUCER` |
| Consuming | `SUBSCRIBE` / `SUCCESS`, `FLOW`, `MESSAGE`, `ACK`, `REDELIVER_UNACKNOWLEDGED_MESSAGES`, `CLOSE_CONSUMER` |

Plus a hand-written encoder for the subset of `PulsarApi.proto` those commands use — protobuf's
wire format is varints, length-delimited fields and a field-number tag, and hand-encoding a fixed
known set of messages is tedious rather than difficult — a CRC32C implementation (`erlang:crc32` is
CRC-32, not CRC32C, so this is a table or the `crc32cer` NIF), a `gen_statem` per connection, and a
process per producer and per consumer. Two to three weeks of work for one engineer, and the largest
single piece in this milestone's tail apart from front 93's schema compiler. It is not a binding and
the README says so.

**The admin arm is cheap, so it lands first.** Pulsar's admin API is plain HTTP and JSON over front
13's client: topic creation, subscription listing, backlog inspection. Ordering the front
admin-first means there is something usable long before the data plane is finished, and it means the
data plane can be tested against topics the admin arm created. Responses are read by a
per-endpoint reader rather than a general walker, because std has no structured JSON value — the
*unowned surface* row in [`language-gaps.md`](../../language-gaps.md). Each reader extracts the two or
three fields its caller needs and is tested against a captured response body.

**Four arms, one registry.** `#[pulsarListener("topic")]` is the fourth arm on front 15's registry,
alongside AMQP, Kafka and JMS, with the same `Outcome` contract and the same retry and dead-letter
path from front 86. `#[pulsarReader("topic", "earliest")]` is different in kind and says so: a reader
is not a subscription, it holds a cursor and it does not acknowledge, so it is registered as a reader
and a message it processes is never dead-lettered — there is nothing to dead-letter it from.

**Subscription types are the semantics, not a tuning knob.** `exclusive`, `shared`, `failover` and
`key_shared` change who receives what, and `key_shared` is the only one that preserves per-key
ordering across consumers. The type is configuration per listener, it is reported by the health
indicator, and a change to it at runtime is a reconnect rather than a silent renegotiation.

**Authentication reuses front 79.** Pulsar's OAuth2 plugin is a client-credentials flow with an
issuer URL, a private key file and an audience — the three properties the reference names. Front 79
owns that flow; this front passes the token in `CONNECT` and refreshes it before expiry, closing and
reopening the connection when the broker rejects a stale token. Token authentication (a static
token) is the simpler second option and needs nothing from front 79.

**Transactions hand off.** `spring.pulsar.transaction.enabled` has a real analogue — Pulsar has
broker-side transactions — and front 83 owns the coordinator. This front exposes begin, commit and
abort over the protocol and registers Pulsar as a transaction-capable broker with 83; it does not
grow its own coordinator.

**Target.** Everything runs on the server. Host cells are `#[@External.Erlang]` over `gen_tcp`,
`ssl` and the protocol module. There is no `@External.Node` cell in this front.

## Steps

### Step 1 — Configuration, topic names and the admin arm

```bp
pub type TopicName(
    persistence: string,
    tenant: string,
    namespace: string,
    topic: string,
)

pub fn parseTopic(name: string) -> TopicName
pub fn renderTopic(name: TopicName) -> string
```

**Acceptance:**
- [ ] `parseTopic("persistent://public/default/orders")` fills all four fields; `parseTopic("orders")` fills the defaults `persistent`, `public`, `default` and round-trips through `renderTopic`.
- [ ] A non-persistent topic keeps `non-persistent` and is not silently promoted.
- [ ] The admin arm creates a topic, lists subscriptions and reports a backlog, each through front 13's client with the configured timeouts.
- [ ] Each admin response reader is tested against a captured body, and an unexpected shape is an error rather than a zero.

### Step 2 — The protocol module

**Acceptance:**
- [ ] Every command in the table above encodes and decodes, asserted against captured frames from a real broker.
- [ ] CRC32C matches the broker's expectation, verified by a frame the broker accepts and by a known-answer vector.
- [ ] A frame split across two TCP segments is reassembled; a frame larger than the configured maximum closes the connection with a named error rather than allocating.
- [ ] `PING` is answered with `PONG` and a missed keep-alive closes the connection.
- [ ] The whole codec lives in the Erlang cell: `grep` finds no byte or bit manipulation in the botopink sources of this front.

### Step 3 — Connection and lookup

**Acceptance:**
- [ ] A connection resolves a topic through `LOOKUP` and follows a redirect to the owning broker.
- [ ] A partitioned topic is discovered through `PARTITIONED_METADATA` and produces one producer per partition.
- [ ] A broker restart reconnects with backoff and re-establishes producers and consumers, with no message acknowledged twice.
- [ ] A connection failure surfaces as a health-indicator transition, not as a crashed application.

### Step 4 — Producing

```bp
pub fn pulsarSend(topic: string, body: string) -> i32
```

**Acceptance:**
- [ ] A send is confirmed by `SEND_RECEIPT` before `pulsarSend` returns; an unconfirmed send is retried through front 86's policy.
- [ ] A key supplied for a `key_shared` topic reaches the message metadata and two messages with the same key land on the same consumer.
- [ ] Batching, where enabled, does not reorder messages within a key.

### Step 5 — `#[pulsarListener]`

**Acceptance:**
- [ ] The emitted registration is the shape front 15's registry expects, asserted by reading the registry.
- [ ] Subscription type reaches `SUBSCRIBE` and is reported by the health indicator.
- [ ] `Outcome.Retry` re-delivers through Pulsar's negative acknowledgement, `Outcome.Reject` dead-letters through front 86, and `Outcome.Done` acknowledges — three separate protocol paths, three tests.
- [ ] Flow control is credit-based: with a permit of 1 and a blocked handler, the broker does not push a second message.

### Step 6 — `#[pulsarReader]`

**Acceptance:**
- [ ] `earliest`, `latest` and an explicit message id all position the cursor, and an unparseable start id fails at boot.
- [ ] A reader acknowledges nothing, and the module README says why a reader message is never dead-lettered.
- [ ] Two readers on one topic do not interfere; neither affects a subscription's backlog.

### Step 7 — Authentication and transactions

**Acceptance:**
- [ ] Token authentication connects with a static token from configuration.
- [ ] OAuth2 authentication obtains a token through front 79's client-credentials flow from the configured issuer, private key and audience, and refreshes before expiry.
- [ ] A rejected stale token reconnects once with a fresh token and does not loop.
- [ ] Pulsar registers with front 83 as transaction-capable, and a transaction that aborts leaves no message visible to a consumer.

## Examples

- [`examples/pulsar-listener-example.bp`](./examples/pulsar-listener-example.bp) — a listener, a
  cursor-positioned reader, and the topic, cursor and subscription-type decisions asserted as pure
  functions.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| **No byte or binary type** and **no bitwise operators** — both rows already in [`language-gaps.md`](../../language-gaps.md). A varint, a length prefix and a CRC32C are unwritable in botopink. | `examples/pulsar-listener-example.bp`, the header comment on the protocol seam | The entire frame codec is one `#[@External.Erlang]` module; botopink holds only the façade. | A `Bytes` primitive and the five bitwise operators |
| **No std JSON walker** — the *unowned surface* row in [`language-gaps.md`](../../language-gaps.md). The admin API returns JSON this front cannot traverse generically. | The admin arm, step 1 | A per-endpoint reader extracting the fields its caller needs, each tested against a captured body. | A structured JSON value in std |

## Test plan

`modules/rakun-messaging/test/pulsar/` on the **erlang** target, invoked as
`zig build test-libs -- --target erlang --lib rakun` from `repository/botopink-lang/`, and as
`botopink test --target erlang` from `repository/rakun/`.

| File | Asserts |
|---|---|
| `test/pulsar/topic_test.bp` | Topic parsing and rendering, defaults, non-persistent preservation |
| `test/pulsar/codec_test.bp` | Every command against captured frames, CRC32C vectors, segmentation, oversize refusal |
| `test/pulsar/admin_test.bp` | Each response reader against a captured body, and an unexpected shape failing loudly |
| `test/pulsar/listener_test.bp` | Registration shape, subscription types, the three outcome paths, credit-based flow |
| `test/pulsar/reader_test.bp` | Cursor positions, unparseable start id, non-interference |
| `test/pulsar/auth_test.bp` | Token and OAuth2 connect, refresh before expiry, single reconnect on rejection |

The codec and topic cells are pure and always run — the captured frames are checked into the test
directory, which is what makes a protocol implementation testable without a broker. Everything else
runs when `RAKUN_TEST_PULSAR_URL` is set and reports a *skipped* cell otherwise.

There is no commonJS row. This front is server-only by the milestone's target split.

## Definition of done

- `modules/rakun-messaging/src/pulsar/` exists, is declared from the module's `root.bp`, and holds no `@External.Node` cell.
- The module README states, in the first paragraph, that no mature BEAM Pulsar client exists and that this front implements the protocol.
- Captured frames for every supported command are checked in, and the codec is tested against them with no broker running.
- `#[pulsarListener]` registers through front 15's registry; `#[pulsarReader]` registers as a reader and never dead-letters.
- OAuth2 goes through front 79 and transactions through front 83; neither is reimplemented here.
- Both language-gap rows are cited from the example and already appear in [`language-gaps.md`](../../language-gaps.md).
- `repository/rakun/AGENTS.md` and `modules/README.md` record the arm in the same commit.
- The front's tests are green on erlang.

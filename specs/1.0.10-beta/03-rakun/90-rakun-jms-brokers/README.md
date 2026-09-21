# Front 90 — Rakun JMS Brokers

**Track:** B rakun
**Priority:** low — the JMS *API* is JVM-only, but ActiveMQ Classic and Artemis are common enough in enterprise estates that a rakun service may have to join one that already exists
**Target:** erlang (server)
**Wave:** 6
**Depends on:** 15 (the listener registry this becomes a third arm of, and the publish seam), 86 (retry, dead-letter and acknowledgement modes), 74 (TLS bundles for `amqps`/`stomp+ssl`), 05 (connection configuration), 11 (health indicator)
**Owns:** `modules/rakun-messaging/src/jms/**`, `modules/rakun-messaging/test/jms/**`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` — frozen for the milestone. Inside `modules/rakun-messaging/`, `src/reliability/**` is front 86's, `src/pulsar/**` is front 91's, and everything else is front 15's; all three are read-only here.
**Reference:** `06-messaging.md § JMS` (ActiveMQ Classic, ActiveMQ Artemis, JNDI ConnectionFactory, Enviando Mensagens JMS, Recebendo Mensagens JMS) · https://docs.spring.io/spring-boot/reference/messaging/jms.html
**Replaces:** new

---

## Problem

Front 15 gives rakun two brokers: RabbitMQ over AMQP 0-9-1 and Kafka. An enterprise estate that
already runs ActiveMQ Classic or Artemis has neither, and a rakun service asked to consume from the
queue that a Java service publishes to cannot reach it. That is the whole problem — not a missing
abstraction, a missing dialer.

What cannot be ported is the JMS API itself: `ConnectionFactory`, `Session`, `MessageProducer`,
`MessageConsumer`, `TextMessage` and the rest are a Jakarta EE interface hierarchy, and there is
nothing on BEAM for them to be compatible *with*. What can be ported is everything the API is a
façade over, because both brokers speak open wire protocols: Artemis speaks AMQP 1.0 natively, and
ActiveMQ Classic speaks STOMP (and AMQP 1.0). A message sent over AMQP 1.0 to an Artemis queue is
the same message a `@JmsListener` on the JVM receives; the interface hierarchy in between is not
part of the contract.

## Current state

- `repository/rakun/modules/rakun-messaging/src/root.bp` — a stub. Fronts 15 and 86 land first; this
  front adds a subtree under `src/jms/`.
- There is no socket client of any kind in `repository/rakun/` today. std's `net` module arrives with
  front 01 and is what both arms dial through.
- `libs/std/src/root.bp:13-36` — no AMQP, no STOMP, no broker anything. Nothing here exists yet.

## Mechanism

**Two protocol arms, chosen by the connection URL scheme.**

| Scheme | Arm | Broker | What it costs |
|---|---|---|---|
| `amqp://`, `amqps://` | AMQP 1.0 | Artemis (native), ActiveMQ Classic (via its AMQP transport) | A binding and a configuration layer. `amqp10_client` ships in the RabbitMQ Erlang client family and is maintained; this arm does not write a protocol |
| `stomp://`, `stomp+ssl://` | STOMP 1.2 | ActiveMQ Classic, and anything else that speaks it | A frame codec written here. There is no BEAM STOMP client worth depending on, and there does not need to be: the framing is text — a command line, a header block, a blank line, a body, a NUL terminator — and the client needs ten frames (`CONNECT`/`CONNECTED`, `SEND`, `SUBSCRIBE`/`UNSUBSCRIBE`, `ACK`/`NACK`, `MESSAGE`, `RECEIPT`, `ERROR`, `DISCONNECT`) plus heart-beating. A few hundred lines over `gen_tcp`/`ssl`, not a project |

Stating that honestly is the point of the table: one arm is a dependency, the other is an
implementation, and they are not the same size.

**Destinations are a two-variant enum, because the semantics differ.** `Destination.Queue(name)` is
point-to-point: one consumer gets each message. `Destination.Topic(name)` is publish-subscribe: every
subscription gets a copy, and a *durable* subscription keeps accumulating while the consumer is
away, which requires a client id and a subscription name that survive a restart. A durable
subscription configured without a stable client id is refused at boot rather than silently becoming
a non-durable one — that failure is otherwise invisible until the day a restart loses a day of
messages.

**Registration is a third arm on front 15's registry, not a second mechanism.** `#[jmsListener("q")]`
emits the same registration `#[rabbitListener]` and `#[kafkaListener]` emit, tagged with the JMS
transport. The dispatch loop, the `Outcome` contract, the retry policy, the dead-letter path and the
acknowledgement modes all come from fronts 15 and 86 unchanged. If this front needed its own dispatch
loop, the abstraction in front 15 would be wrong and that, not this front, would be the thing to fix.

**Selectors are broker-evaluated or refused.** JMS message selectors are a SQL-92 fragment the
*broker* applies. AMQP 1.0 carries them as a filter on the receiving link; STOMP carries them in a
`selector` header, which ActiveMQ honours. Where the broker does not support the selector, this front
refuses the subscription at registration. It does not fall back to filtering after delivery, and the
reason is worth writing down: a point-to-point consumer that receives a message, decides the selector
does not match, and acknowledges it has consumed a message that was meant for a different consumer.
A silent client-side fallback turns a filter into data loss.

**Request/reply is a temporary destination plus a correlation id.** The requester creates a
per-request reply destination, sends with `reply-to` and `correlation-id` set, and awaits the
matching reply. The reply consumer is one process, so correlation is a receive with a pattern rather
than a shared map — the one place where the BEAM model is simply shorter than the JVM one.

**What this front refuses, explicitly.**

- **The embedded broker** (`spring.artemis.mode=embedded`). Running a broker inside the application
  is a JVM convenience with no BEAM equivalent and no operational merit; a test that needs a broker
  uses front 19's in-process double or a container.
- **JNDI `ConnectionFactory`** (`spring.jms.jndi-name`). Deferred milestone-wide — see the deferred
  table in the coverage audit. A connection is configuration here, which is what JNDI was providing
  indirection over.
- **Binary message bodies on the STOMP arm.** The milestone has no byte type
  ([`language-gaps.md`](../../language-gaps.md), *No byte or binary type*), so a `BytesMessage` cannot be
  carried without a lossy round trip through UTF-8. The arm refuses a non-text body with a located
  error rather than corrupting it. The AMQP 1.0 arm has the same limit for the same reason.

**Target.** Both arms dial a socket while a request or a consumer loop is running, so both are
erlang. Host cells are `#[@External.Erlang]` over `amqp10_client`, `gen_tcp` and `ssl`. There is no
`@External.Node` cell in this front.

## Steps

### Step 1 — Connection configuration and arm selection

```bp
pub type Destination {
    Queue(name: string),
    Topic(name: string),
}

pub fn armFor(url: string) -> string
```

**Acceptance:**
- [ ] `armFor("amqp://host:5672")` is `"amqp10"`; `armFor("stomp://host:61613")` is `"stomp"`; an unknown scheme is a boot failure naming both supported schemes.
- [ ] `amqps://` and `stomp+ssl://` resolve their TLS material through front 74's bundle registry and fail at boot when the named bundle does not exist.
- [ ] Credentials come from configuration and never from the URL in a log line — a test asserts the redacted form is what is logged.
- [ ] A connection that drops is re-established with backoff, and the listener's subscriptions are re-declared on reconnect.

### Step 2 — The STOMP frame codec

**Acceptance:**
- [ ] Every one of the ten frames round-trips through encode and decode unchanged, asserted frame by frame.
- [ ] A frame with a `content-length` header is read by length; one without is read to the NUL terminator.
- [ ] Header values escape and unescape `\r`, `\n`, `:` and `\` per STOMP 1.2, and a header containing all four round-trips.
- [ ] Heart-beating negotiates from the `heart-beat` header and a missed beat closes the connection rather than hanging.
- [ ] A non-text body is refused with a located error naming the byte-type gap.

### Step 3 — Sending

```bp
pub fn jmsSend(destination: Destination, body: string) -> i32
```

**Acceptance:**
- [ ] A queue send reaches exactly one of two competing consumers; a topic send reaches both.
- [ ] Publishing to a topic with no subscriber is not an error and is not retried.
- [ ] `jmsSend` goes through front 86's `publishWithRetry` when a retry policy is configured for the destination.
- [ ] A send to a `Destination.Queue` whose name is empty fails before dialling.

### Step 4 — `#[jmsListener]`

```bp
#[jmsListener("someQueue")]
pub fn onMessage(self: Self, delivery: Delivery) -> Outcome
```

**Acceptance:**
- [ ] `#[jmsListener]` on anything but a method fails with a located message.
- [ ] The emitted registration is the same shape front 15 emits for its own arms — asserted by reading the registry, not by reading the emitted source.
- [ ] `Outcome.Retry` and `Outcome.Reject` route through front 86 exactly as they do on the AMQP 0-9-1 arm.
- [ ] The three acknowledgement modes behave as front 86 documents them, including `Batch` on a STOMP subscription with `ack: client`.

### Step 5 — Durable subscriptions and selectors

**Acceptance:**
- [ ] A durable topic subscription receives messages published while the consumer was down.
- [ ] A durable subscription without a stable client id fails at boot, naming the missing setting.
- [ ] A selector the broker accepts filters at the broker: the consumer's delivery count for
      non-matching messages is zero, not "delivered and discarded".
- [ ] A selector the broker rejects fails the subscription at registration, and the message says that
      client-side filtering is not a fallback.

### Step 6 — Request/reply

**Acceptance:**
- [ ] A reply is matched to its request by correlation id, with two requests in flight at once.
- [ ] A request that times out returns an error rather than blocking the caller's process forever, and the late reply is discarded without crashing the requester.
- [ ] The temporary reply destination is removed when the requester finishes, including when it raises.

### Step 7 — Health

**Acceptance:**
- [ ] A `jms` health indicator reports per configured connection: up, down, and the reason when down.
- [ ] The indicator checks the connection without sending an application message.
- [ ] It is registered with front 11 and hidden by default behind front 76's exposure rules.

## Examples

- [`examples/jms-listener-example.bp`](./examples/jms-listener-example.bp) — sending to a queue,
  consuming it with `#[jmsListener]`, request/reply over a temporary destination, and the arm,
  destination and selector decisions asserted as pure functions.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| **No byte or binary type** — the row already in [`language-gaps.md`](../../language-gaps.md). A JMS `BytesMessage`, and any STOMP frame whose body is not UTF-8, cannot be carried without corruption. | `examples/jms-listener-example.bp`, the body of `onOrderMessage` | Refuse a non-text body at the codec with a located error; text bodies are unaffected. | A `Bytes` primitive with a declared encoding boundary |
| **Declared parameter defaults are never applied** — the row already in [`language-gaps.md`](../../language-gaps.md). `#[jmsListener("q", selector: "...", durable: true)]` would force every listener to spell every argument. | `examples/jms-listener-example.bp`, the `#[jmsListener]` line | One required destination argument; selectors, durability and acknowledgement come from `rakun.messaging.listener.<name>.*`. | Apply declared defaults at call sites |

## Test plan

`modules/rakun-messaging/test/jms/` on the **erlang** target, invoked as
`zig build test-libs -- --target erlang --lib rakun` from `repository/botopink-lang/`, and as
`botopink test --target erlang` from `repository/rakun/`.

| File | Asserts |
|---|---|
| `test/jms/arm_test.bp` | Scheme to arm, unknown scheme failure, bundle resolution, credential redaction |
| `test/jms/stomp_codec_test.bp` | The ten frames, both body-length rules, header escaping, heart-beat negotiation, binary refusal |
| `test/jms/destination_test.bp` | Queue versus topic semantics, empty-name refusal, durable client-id refusal |
| `test/jms/listener_test.bp` | Placement failure, registration shape, outcome routing, ack modes |
| `test/jms/selector_test.bp` | Broker-side filtering, and the refusal when the broker will not |
| `test/jms/request_reply_test.bp` | Correlation with two in flight, timeout, late reply, destination cleanup |

The codec, arm-selection and destination cells are pure and always run. Everything that needs a
broker runs when `RAKUN_TEST_STOMP_URL` or `RAKUN_TEST_AMQP10_URL` is set and reports a *skipped*
cell otherwise.

There is no commonJS row. This front is server-only by the milestone's target split.

## Definition of done

- `modules/rakun-messaging/src/jms/` exists, is declared from the module's `root.bp`, and holds no `@External.Node` cell.
- `#[jmsListener]` registers through front 15's registry and adds no second dispatch loop, proven by a test that reads the registry.
- The STOMP codec round-trips all ten frames, and the AMQP 1.0 arm is a binding over `amqp10_client` rather than a second protocol implementation.
- A selector the broker cannot evaluate fails the subscription; no client-side filtering path exists in the source.
- The three refusals — embedded broker, JNDI, binary bodies — are in the module README with their reasons.
- Both language-gap rows are cited from the examples and already appear in [`language-gaps.md`](../../language-gaps.md).
- `repository/rakun/AGENTS.md` and `modules/README.md` record the arm in the same commit.
- The front's tests are green on erlang.

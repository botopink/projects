# Front 15 — Rakun Messaging

**Track:** B rakun
**Priority:** medium — a service that can only answer HTTP cannot be told anything; every asynchronous workflow in the ecosystem bottoms out here
**Target:** erlang (server)
**Wave:** 3
**Depends on:** 01 (`net`), 05 (config), 06 (context), 11 (health registry)
**Owns:** `modules/rakun-messaging/src/**`, `modules/rakun-messaging/test/**`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` — frozen for the milestone
**Reference:** `06-messaging.md § AMQP (RabbitMQ)` · `06-messaging.md § Apache Kafka` · https://docs.spring.io/spring-boot/reference/messaging/amqp.html · https://docs.spring.io/spring-boot/reference/messaging/kafka.html
**Replaces:** `1.0.6-beta/11-messaging-amqp` + `1.0.6-beta/16-messaging-kafka`

---

## Problem

Nothing in rakun receives a message. `modules/rakun-messaging/` is a `botopink.json` and a `src/root.bp`
holding a TODO comment; there is no broker connection, no listener, no publish call, and no way for one
service to tell another that something happened except by making an HTTP request and waiting for it.

The two drafts this replaces are the same document with the nouns swapped. 1.0.6-beta F11 proposed
`RabbitTemplate` plus `@rabbitListener` in four steps; 1.0.6-beta F16 proposed `KafkaTemplate` plus
`@kafkaListener` in four steps, and declared `Depends on: F11 (messaging-amqp)` without saying what it
depended on — because the answer was "nothing, it is a copy". Both had a `pub type` with bodyless
methods inside a `type` body, which does not parse (`docs.md:567`), and both proposed a module layout
(`src/amqp/**` and `src/kafka/**`) that puts the shared half — the registry, the dispatch loop, the
worker supervision, the acknowledgement policy — in neither.

One registry, one dispatch loop, one container model, and a broker arm per transport behind it. Adding
Redis pub/sub after that is a file, not a front.

## Current state

- `repository/rakun/modules/rakun-messaging/src/root.bp` — docblock and `// Module contents will be added by the respective fronts.`
- `repository/rakun/src/runtime.bp` — the only registry rakun has is the HTTP route table (`rkRegisterRoute`, `rkRouteCount`, `rkRoutePaths`, `rkDispatch`). It is a good model for this one and it is not reusable for it: routes are matched by verb and path, listeners by broker and destination.
- `libs/std/src/` has **no socket module**. Every broker connection in this front waits on front 01's `net`; there is nothing under it today.
- `repository/rakun/src/decorators.bp` — no listener markers, and frozen.
- No supervision surface is exposed to a rakun library today; front 04's BEAM runtime owns the supervision tree this front's containers attach to.

## Mechanism

### One registry, one loop

A listener is a triple — broker id, destination, handler — plus a container policy. `#[listener]` on a
type walks its methods exactly as `#[restController]` walks its methods for `#[getMapping]`
(`repository/rakun/src/decorators.bp:155-166`), reads each one's broker marker from `m.annotations`,
and `@emit`s one registration per annotated method:

```
val __rkListener_OrderListeners_onOrder =
    rkRegisterListener("amqp", "orders", "", "orders-container",
        { msg -> __rkMake_OrderListeners().onOrder(msg) });
```

Registration is module-load self-registration, the same shape the router already uses. Dispatch is one
loop per container: take a message off the broker arm, hand it to the handler, acknowledge according
to the container's ack mode. The broker arms differ in how a message is fetched and acknowledged and in
nothing else.

### The four broker arms

| Arm | Marker | BEAM driver | Destination means | Group means |
|---|---|---|---|---|
| AMQP | `#[amqpListener(queue)]` | `amqp_client` | a queue | — |
| Kafka | `#[kafkaListener(topic, groupId)]` | `brod` | a topic | the consumer group |
| Redis pub/sub | `#[redisListener(channel)]` | the Redis client front 13 configures | a channel | — |
| RabbitMQ Streams | `#[streamListener(stream, offset)]` | `rabbitmq_stream_client` | a stream | the starting offset (`first`, `last`, `next`, or a number) |

Redis pub/sub is fire-and-forget with no acknowledgement and no redelivery: a subscriber that is down
misses the message. That is a property of the transport, and the container refuses an ack mode other
than `none` for it rather than pretending otherwise. RabbitMQ Streams is an offset consumer, not a
queue consumer — it re-reads from a position instead of consuming and removing — which is why it is its
own marker and not a flag on `#[amqpListener]`.

### The listener container — a supervised worker set, not a future pool

Spring configures concurrency as threads (`spring.rabbitmq.listener.simple.concurrency`,
Kafka's `concurrency` on the container factory). The BEAM shape is a supervised worker set: a
`simple_one_for_one` supervisor per container, started under front 04's tree, with N child processes
each holding a channel or a partition assignment. A worker that crashes is restarted by its supervisor
with the connection re-established; the container does not catch the error, because catching it would
lose the restart.

This is not `@Future`. `@Future<T>` lowers **eagerly** on erlang (`libs/std/src/http.bp:16-18`), so a
handler returning a future gives no concurrency at all. Concurrency here is process count, and the only
knob is the worker count.

| Key | Default | Effect |
|---|---|---|
| `rakun.messaging.listener.<name>.concurrency` | `1` | Worker processes in the container |
| `rakun.messaging.listener.<name>.prefetch` | `10` | Unacknowledged messages a worker may hold (AMQP QoS; `max.poll.records` on Kafka) |
| `rakun.messaging.listener.<name>.ack-mode` | `auto` | `auto` \| `manual` \| `none`. `none` is refused for AMQP and Kafka and required for Redis. |
| `rakun.messaging.listener.<name>.enabled` | `true` | Start the container at boot |

A container with `concurrency = 1` preserves per-destination ordering; a container with more does not,
and the README of any application that raises it should say why it is allowed to. That is a sentence
this front prints in the startup log rather than a sentence it hopes someone reads.

### Broker configuration, and the passthrough

Named keys match Spring's, so an `application.properties` reader recognises them:
`rakun.messaging.amqp.host`, `.port`, `.username`, `.password`, `.addresses`;
`rakun.messaging.kafka.bootstrap-servers`, `.consumer.group-id`;
`rakun.messaging.redis.url`; `rakun.messaging.stream.name`.

Drivers have options no framework can enumerate, and Spring's answer is a passthrough map —
`spring.kafka.properties[prop.one]=first` (`06-messaging.md § Propriedades Adicionais`). Same here:
every key under `rakun.messaging.<arm>.properties.*` is handed to the driver verbatim, unparsed and
unvalidated, and the startup log lists exactly which keys were passed through. Silently ignoring an
unrecognised property is how a production incident starts; passing it on and saying so is not.

### Publishing

One template per arm, each an ordinary `#[component]` with `#[value]` fields, resolved by type:

```bp
#[component]
pub type AmqpTemplate(
    #[value("rakun.messaging.amqp.host")] host: string,
    #[value("rakun.messaging.amqp.port")] port: i32,
) {
    pub fn send(self: Self, queue: string, payload: string) -> i32 { … }
}
```

`KafkaTemplate.send(topic, key, payload)`, `RedisPubSubTemplate.publish(channel, payload)`,
`StreamTemplate.append(stream, payload)`. No fluent builder: a publish takes a destination, an optional
key and a payload, and a builder would be three types to express three arguments.

### Health indicator

Registered with front 11 under `messaging.<arm>`, one per configured arm: UP when the connection
process is alive and the last heartbeat is inside the driver's interval, DOWN naming the arm and the
last error. A container whose workers are all down while the connection is up reports DOWN with the
container named — an arm that can publish but cannot consume is not healthy.

### Target

erlang. Every driver is an OTP application, every container is a supervised process set, and there is
no `@External.Node` cell anywhere in the module.

## Steps

### Step 1 — The message shape and the broker behavior

```bp
pub type Message(
    broker: string,
    destination: string,
    key: string,
    payload: string,
    headersJson: string,
    offset: i64,
)

pub behavior MessageBroker {
    fn id(self: Self) -> string;
    fn publish(self: Self, destination: string, key: string, payload: string) -> i32;
    fn ack(self: Self, deliveryTag: string) -> i32;
    fn nack(self: Self, deliveryTag: string) -> i32;
}
```

**Acceptance:**
- [ ] `Message` carries the same fields whatever the arm; an arm that has no key sets `""` and one that has no offset sets `-1`.
- [ ] A handler written against `Message` compiles unchanged for all four arms.
- [ ] `MessageBroker` is a `behavior`, not a `type` with bodyless methods.

### Step 2 — The registry and the dispatch loop

```bp
pub declare fn rkRegisterListener(
    broker: string,
    destination: string,
    group: string,
    container: string,
    handler: fn(msg: Message) -> i32,
) -> i32;

pub declare fn rkListenerCount() -> i32;
pub declare fn rkListenerDestinations() -> string;
pub declare fn rkDeliver(broker: string, destination: string, payload: string) -> i32;
```

`rkDeliver` is the seam a test uses to push a message in without a broker; it is the same trick
`rkDispatch` plays for the router (`repository/rakun/test/router_test.bp:46-50`).

**Acceptance:**
- [ ] Registering two listeners on the same broker and destination is refused at boot with both handler names in the message — a silently shadowed listener is the worst failure mode here.
- [ ] `rkListenerCount()` equals the number of annotated methods across every `#[listener]` type in the build.
- [ ] `rkDeliver` reaches the handler and returns its result, with no broker running.
- [ ] A handler that raises does not take the container's other workers with it.

### Step 3 — `#[listener]` and the four markers

**Acceptance:**
- [ ] `#[listener]` on a type with no broker-annotated method emits nothing and fails with a message saying so.
- [ ] Each of `#[amqpListener]`, `#[kafkaListener]`, `#[redisListener]`, `#[streamListener]` on anything but a method fails with a located message.
- [ ] `#[kafkaListener("t", "g")]` takes both arguments; declared defaults are never applied, so there is no one-argument form.
- [ ] A `#[listener]` type is also a component (stacked `#[service]`), and the emitted handler closure builds it through `__rkMake_<Type>()` — one instance, not one per message.
- [ ] `#[streamListener("s", "first")]` rejects an offset that is neither `first`, `last`, `next` nor a decimal number, at comptime.

### Step 4 — Containers and concurrency

**Acceptance:**
- [ ] A container with `concurrency = 4` starts four worker processes, visible in the supervision tree.
- [ ] Killing one worker leaves the other three consuming and the killed one restarted within the supervisor's restart window.
- [ ] `prefetch` is honoured: a worker holds no more than that many unacknowledged messages.
- [ ] `ack-mode = manual` means a handler that returns without acking causes redelivery; `auto` acks on a non-raising return.
- [ ] `ack-mode = none` is refused for AMQP and Kafka at boot, and is the only value accepted for Redis.
- [ ] `enabled = false` starts no container and the application boots with the listener registered but idle.
- [ ] A container with `concurrency > 1` logs, at startup, that per-destination ordering is not preserved.

### Step 5 — Templates and the passthrough

**Acceptance:**
- [ ] Each template is resolvable by type from any `#[service]` that declares a field of it.
- [ ] A publish to a destination with no broker connection returns a non-zero result and does not raise — a failed publish is a decision for the caller.
- [ ] Every `rakun.messaging.<arm>.properties.*` key reaches the driver unmodified.
- [ ] The startup log lists the passed-through keys by name, and the list is empty when none were set.

### Step 6 — Health

**Acceptance:**
- [ ] Each configured arm contributes one indicator to front 11's report.
- [ ] Stopping the broker turns its indicator DOWN with the arm named, and restarting it turns it UP again without an application restart.
- [ ] An arm whose containers are all down reports DOWN with the container named, even when the connection is up.

## Examples

- [`examples/order-listeners-example.bp`](./examples/order-listeners-example.bp) — one service that consumes from AMQP, Kafka and Redis through one registry, and publishes to two of them.
- [`examples/stream-consumer-example.bp`](./examples/stream-consumer-example.bp) — a RabbitMQ Streams offset consumer, manual acknowledgement, and a container with raised concurrency.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| There is no byte or binary type — host cells marshal through `string` — so a broker payload that is not UTF-8 text (Avro, protobuf, a compressed batch) cannot be represented without corrupting it. Recorded by front 01. | `Message.payload` in both examples | Base64-encode at the arm and hand the handler text, or refuse a binary content-type header with a named error. Both examples carry text payloads. | A `bytes` primitive with explicit `string` conversions at the edges |
| Declared parameter defaults are never applied, so `#[kafkaListener]` cannot default its group id the way `@KafkaListener(topics = "t")` does. | `#[kafkaListener("order-events", "order-service")]` | Pass both arguments. | Apply declared defaults at call sites (`docs.md:502-505`) |

## Test plan

`modules/rakun-messaging/test/` on the **erlang** target, via
`zig build test-libs -- --target erlang --lib rakun`.

| File | Asserts |
|---|---|
| `test/registry_test.bp` | Registration count, duplicate refusal, `rkDeliver` reaching a handler with no broker running |
| `test/decorators_test.bp` | `#[listener]` synthesis, placement failures, the stream-offset comptime check, one component instance across many messages |
| `test/container_test.bp` | Worker count, restart after a kill, prefetch, the three ack modes and the two refusals, the ordering warning |
| `test/template_test.bp` | Publish through each template, failure without a connection, passthrough key delivery |
| `test/health_test.bp` | Per-arm indicators, DOWN on a stopped broker, DOWN on dead containers with a live connection |

Every test above runs against the in-process broker double that front 19 ships — `rkDeliver` on the
consume side and a recording publisher on the send side — so `zig build test-libs` needs no RabbitMQ,
no Kafka and no Redis. Integration against real brokers runs when `RAKUN_TEST_AMQP_URL`,
`RAKUN_TEST_KAFKA_BROKERS` or `RAKUN_TEST_REDIS_URL` is set, and reports a *skipped* cell otherwise.
A green suite with every integration cell skipped is reported as such and is not a pass of this front.

There is no commonJS row; this front is server-only by the milestone's target split.

## Out of scope

The messaging reference covers six transports and this front covers two. The other four were not
forgotten — each is its own front, and this is the map:

| Upstream section | Front |
|---|---|
| `06-messaging.md § JMS` (ActiveMQ Classic, Artemis, `JmsClient`, `@JmsListener`) | **90 — rakun-jms-brokers** |
| `06-messaging.md § Apache Pulsar` (`PulsarTemplate`, `@PulsarListener`, `@PulsarReader`, transactions) | **91 — rakun-pulsar** |
| `06-messaging.md § RSocket` (server transport, `RSocketRequester`) | **92 — rakun-rsocket** |
| `06-messaging.md § Spring Integration` (pollers, channels, JDBC store) | **89 — rakun-stream-pipelines**, as GenStage |
| `06-messaging.md § Kafka Streams` (`StreamsBuilder`, `@EnableKafkaStreams`) | **89 — rakun-stream-pipelines** |
| Retry, dead-letter queues, idempotent consumption | **86 — rakun-messaging-reliability** |
| Exchange topology, bindings, audit trails | **87 — rakun-audit-and-exchanges** |
| Transactional publish across a database write | **83 — rakun-distributed-transactions** |

Also out of scope here: message conversion beyond text (see *Language gaps*), and schema registries.

## Definition of done

- One registry and one dispatch loop, with four arms behind them and no arm-specific code in the loop.
- `#[listener]` emits a registration per annotated method and refuses a duplicate destination at boot.
- Containers are supervised worker sets with the four documented keys, and the word "thread" appears nowhere in the module.
- Passthrough properties reach the driver and are listed at startup.
- Each arm registers a health indicator with front 11.
- Every `// LANGUAGE GAP:` marker in the examples appears in the table above.
- `repository/rakun/AGENTS.md` and `modules/README.md` record the module's surface, including the out-of-scope map, in the same commit.
- The front's tests are green on erlang.

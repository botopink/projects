# Front 16 — Messaging (Kafka)

**Priority:** low — services need event streaming
**Depends on:** F11 (messaging-amqp)
**Owns:** `modules/rakun-messaging/src/kafka/**`
**Does not touch:** `src/runtime.mjs`, `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `modules/rakun-messaging/src/amqp/**`

---

## Problem

Beyond request-reply messaging (AMQP), services need event streaming for high-throughput, partitioned, replayable event logs. Spring Boot provides `spring-boot-starter-kafka` with `KafkaTemplate` and `@KafkaListener`.

## Mechanism

Spring Boot Kafka:
- `KafkaTemplate` → produce messages
- `@KafkaListener` → consume messages
- Kafka Streams support
- Auto-configuration from `spring.kafka.*`

Rakun will implement:
- **KafkaTemplate** → produce messages
- **@kafkaListener** → consume messages
- Consumer groups, partitions

## Steps

### Step 1 — KafkaTemplate

```bp
#[service]
pub type KafkaTemplate(
    #[value("spring.kafka.bootstrap-servers")] servers: string,
) {
    pub fn send(self: Self, topic: string, key: string, value: string);
    pub fn sendDefault(self: Self, topic: string, value: string);
}
```

### Step 2 — @kafkaListener

```bp
#[service]
pub type OrderEventProcessor {
    #[kafkaListener(topics: "orders", groupId: "order-service")]
    pub fn processOrder(self: Self, key: string, value: string) {
        print("Processing order: " + key + " = " + value);
    }
}
```

### Step 3 — Erlang implementation

Use `brod` (Erlang Kafka client):
```erlang
{ok, Client} = brod:start_client([{Host, Port}], client1),
{ok, Producer} = brod:start_producer(Client, Topic, _ProducerConfig=[]),
brod:produce_sync(Client, Topic, Partition, Key, Value).
```

### Step 4 — Module structure

```
modules/rakun-messaging/
└── src/
    └── kafka/
        ├── kafka_template.bp
        └── kafka_listener.bp
```

## Gate

- [ ] `botopink test` green on both targets
- [ ] `KafkaTemplate` produces messages
- [ ] `@kafkaListener` consumes messages
- [ ] Consumer groups work
- [ ] Auto-configuration from properties

## Notes

- Uses `brod` (Erlang), `kafkajs` (Node.js)
- Consumer groups for load balancing
- Partition awareness for ordering
- Kafka Streams: separate front

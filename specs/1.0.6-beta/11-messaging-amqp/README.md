# Front 11 — Messaging (AMQP/RabbitMQ)

**Priority:** medium — services need async messaging
**Depends on:** F03 (context-api)
**Owns:** `modules/rakun-messaging/src/amqp/**`
**Does not touch:** `src/runtime.mjs`, `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`

---

## Problem

Rakun has no messaging abstraction. Services that need async communication must implement their own AMQP/Kafka clients. Spring Boot provides `spring-boot-starter-amqp` with `RabbitTemplate` and `@RabbitListener`.

## Mechanism

Spring Boot AMQP:
- `RabbitTemplate` → send messages
- `@RabbitListener` → receive messages
- Auto-configuration for connection factory
- Message conversion (JSON)

Rakun will implement:
- **RabbitTemplate** → send messages
- **@rabbitListener** → receive messages
- Auto-configuration from `spring.rabbitmq.*`

## Steps

### Step 1 — RabbitTemplate

```bp
// amqp/rabbit_template.bp
#[service]
pub type RabbitTemplate(
    #[value("spring.rabbitmq.host")] host: string,
    #[value("spring.rabbitmq.port")] port: i32,
    #[value("spring.rabbitmq.username")] username: string,
    #[value("spring.rabbitmq.password")] password: string,
) {
    pub fn send(self: Self, queue: string, message: string);
    pub fn receive(self: Self, queue: string) -> ?string;
    pub fn convertAndSend<T>(self: Self, queue: string, message: T);
}
```

### Step 2 — @rabbitListener

```bp
#[service]
pub type OrderProcessor {
    #[rabbitListener("orders")]
    pub fn processOrder(self: Self, message: string) {
        print("Processing order: " + message);
    }
}
```

### Step 3 — Connection factory

```erlang
% amqp_connection in Erlang (amqp_client library)
{ok, Connection} = amqp_connection:start(#amqp_params_network{
    host = Host,
    port = Port,
    username = Username,
    password = Password
}).
```

### Step 4 — Module structure

```
modules/rakun-messaging/
├── botopink.json
├── src/
│   ├── root.bp
│   └── amqp/
│       ├── rabbit_template.bp
│       └── rabbit_listener.bp
└── test/
    └── amqp_test.bp
```

## Gate

- [ ] `botopink test` green on both targets
- [ ] `RabbitTemplate` sends/receives messages
- [ ] `@rabbitListener` receives messages
- [ ] Auto-configuration from properties

## Notes

- Uses `amqp_client` (Erlang), `amqplib` (Node.js)
- JSON message conversion
- Retry: not in this front

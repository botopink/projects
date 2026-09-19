# Front 86 — Rakun Messaging Reliability

**Track:** B rakun
**Priority:** medium — front 15 can deliver a message to a handler and has nowhere to put it when the handler fails; on BEAM that failure mode is silent, because supervision restarts the consumer and the consumer re-reads the same message forever
**Target:** erlang (server)
**Wave:** 4
**Depends on:** 15 (the listener registry and the dispatch loop it wraps), 05 (per-listener configuration), 01 (`clock` for the backoff timer), 83 (the outbox it hands off to when a broker has no transaction), 75 (registers its counters)
**Owns:** `modules/rakun-messaging/src/reliability/**`, `modules/rakun-messaging/test/reliability/**`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` — frozen for the milestone. Inside `modules/rakun-messaging/`, everything outside `src/reliability/**` belongs to front 15 and is read-only here.
**Reference:** `06-messaging.md § AMQP (RabbitMQ) · Enviando Mensagens · Retry no template` · `§ Recebendo Mensagens · Tipo de container` · `§ Recebendo Mensagens · Retry no listener` · `§ Apache Kafka · Enviando Mensagens · Transacoes` · https://docs.spring.io/spring-boot/reference/messaging/amqp.html · https://docs.spring.io/spring-boot/reference/messaging/kafka.html
**Replaces:** new

---

## Problem

Front 15 delivers one listener registry and one dispatch loop with AMQP and Kafka behind it. A
message arrives, a handler runs, and the handler either returns or it does not. There is no third
answer today: no retry, no attempt ceiling, no dead-letter destination, no acknowledgement policy.

On the JVM that gap is loud — an exception escapes the listener container and something logs a stack
trace. On BEAM it is quiet, and that is worse. A handler that crashes takes its consumer process with
it, the supervisor restarts the consumer, the consumer reconnects, the broker redelivers the
unacknowledged message, and the handler crashes again. The supervision tree is working exactly as
designed while the application makes no progress and the queue depth climbs. Nothing in the
milestone currently breaks that loop, and nothing records that it is happening.

The publish side has the mirror problem. `publish(destination, body)` either reaches the broker or it
raises, and a broker that is restarting for four seconds turns a successful HTTP request into a lost
side effect. Spring answers both halves with configuration —
`spring.rabbitmq.template.retry.enabled`, `spring.rabbitmq.listener.simple.retry.max-attempts`,
`spring.kafka.producer.transaction-id-prefix` — and a listener container that owns the redelivery
policy. This front is that policy, expressed as values a test can check without a broker.

## Current state

- `repository/rakun/modules/rakun-messaging/src/root.bp` — a four-line docblock and the comment
  *"Module contents will be added by the respective fronts."* No code, no `pub mod` line.
- `repository/rakun/modules/rakun-messaging/botopink.json` — `"targets": ["commonJS", "erlang"]`,
  depends on `rakun` by relative path. That is the whole module.
- `repository/rakun/src/decorators.bp:48-238` — fifteen decorators, none of them a listener. Every
  decorator this front adds lives under `modules/rakun-messaging/src/reliability/`.
- `repository/rakun/src/runtime.bp:19-117` — the runtime seams are HTTP and DI only
  (`rkScan`, `rkSingleton`, `rkRegisterRoute`, `rkDispatchHttp`, `rkServe`). Nothing publishes,
  nothing consumes, nothing sleeps.
- There is no dead-letter concept anywhere in `repository/rakun/`.

## Mechanism

Upstream splits reliability across two places: the template (publish) and the listener container
(consume). Both are configuration in Spring, and both become values here, for one reason — a policy
that is a value can be tested without a broker, and a policy that is a container setting cannot.

**Backoff is arithmetic, and arithmetic is testable.** `RetryPolicy` carries four integers and
`nextDelay(policy, attempt)` is a pure function over them. The multiplier is an integer percentage
(`multiplierPercent: 200` doubles), which keeps the whole calculation in `i32` and off the float
path — `spring.rabbitmq.template.retry.multiplier=1.5` becomes `multiplierPercent: 150` with no
rounding argument to have.

**The attempt counter travels with the message, not with the process.** This is the decision the
whole front turns on. An in-process counter is lost the moment the consumer crashes, which is
precisely the case retries exist for; a counter in a supervisor's state is lost when the node dies,
and lost differently when a partition moves to another node. So the attempt count is a message
header — `x-rakun-attempt`, mirroring the `x-death` convention AMQP brokers already use — written by
this front before redelivery and read back on the next delivery. It survives a consumer crash, a node
restart and a partition rebalance, because the broker is the thing that persists it.

**A handler answers with an outcome, not with a crash.** `Outcome` has three variants and each one
means something different to the dispatcher:

| Outcome | Meaning | What the dispatcher does |
|---|---|---|
| `Done` | processed | acknowledge, drop the attempt header |
| `Retry(reason)` | transient failure | if `attempt < maxAttempts`, nack with a delay of `nextDelay(policy, attempt)` and `attempt + 1`; otherwise dead-letter |
| `Reject(reason)` | the message is wrong and will always be wrong | dead-letter immediately, without consuming an attempt |

A handler that crashes anyway is treated as `Retry("crashed: " + reason)` — a crash is still handled,
it is just handled with less information. The distinction between `Retry` and `Reject` is the one
Spring does not draw and the one that matters most: a malformed payload retried three times is three
times the log volume for the same certain failure, and a decode failure is never transient.

**Dead-lettering is a publish, and its envelope is the point.** `deadLetterOf(delivery, reason,
attempt)` builds a `DeadLetter` record carrying the original destination, the original body, the
failure reason, the attempt count and the first-seen timestamp from front 01's clock. It is published
to `<destination>.dlq` by default, or to the destination named in configuration. The original is
acknowledged *after* the dead-letter publish is confirmed, never before — an unconfirmed
dead-letter followed by an ack loses the message, which is the one outcome worse than a retry loop.

**Acknowledgement modes.** `AckMode` is `Auto`, `Manual` or `Batch(size)`. `Auto` acknowledges when
the handler returns `Done`. `Manual` hands the handler an ack token and does nothing on its behalf —
the handler that forgets to ack is a bug this front makes visible rather than papering over, via a
warning when a `Manual` listener returns `Done` without having acked. `Batch(size)` acknowledges up
to the highest contiguous offset every `size` messages, which is the only mode where a crash replays
work that already succeeded; that cost is stated in the module's README, not hidden.

**Concurrency is a supervised worker set, not a pool size.** Spring's
`spring.rabbitmq.listener.simple.concurrency` and Kafka's consumer concurrency both size a thread
pool. On BEAM the equivalent is N consumer processes under one `simple_one_for_one` supervisor, each
holding its own channel or partition assignment, with prefetch as the per-process credit. The
configuration key keeps the upstream name so an operator's knowledge transfers; the README states
plainly that it sizes processes and not threads, and that setting it to 200 is not the mistake it
would be on the JVM.

**Producer transactions where the broker has them, the outbox where it does not.**
`withProducerTransaction(prefix, body)` begins a Kafka producer transaction, runs the body, commits
on a normal return and aborts on a raise. AMQP's channel transactions are weaker and slower than
their reputation, so the AMQP arm does not pretend: `withProducerTransaction` on an AMQP destination
raises with a located message telling the caller to use the transactional outbox from front 83. One
mechanism refusing to impersonate another is the whole reason this front and 83 are separate.

**Why the settings are configuration rather than decorator arguments.** `#[rabbitListener("orders",
maxAttempts: 3, ackMode: "manual", concurrency: 4)]` is the natural surface and it is not writable:
declared parameter defaults are never applied (ground truth §2.24), so every listener in the codebase
would have to spell every argument. The policy is therefore looked up by listener name from
configuration — `rakun.messaging.listener.<name>.retry.max-attempts` — with a module-level default,
and the decorator keeps its single destination argument. This is a language gap, recorded below, and
the design works around it rather than waiting for it.

**Target.** Every line runs while a message is in flight, so every line is erlang. The host cells are
`#[@External.Erlang]` over the broker clients front 15 owns, `timer` for the delay, and `ets` for the
per-listener attempt statistics. There is no `@External.Node` cell in this front.

## Steps

### Step 1 — The retry policy, and the arithmetic under it

```bp
pub type RetryPolicy(
    initialMs: i32,
    multiplierPercent: i32,
    maxMs: i32,
    maxAttempts: i32,
)

pub fn retryPolicy(initialMs: i32, multiplierPercent: i32, maxMs: i32, maxAttempts: i32) -> RetryPolicy {
    return RetryPolicy(
        initialMs: initialMs,
        multiplierPercent: multiplierPercent,
        maxMs: maxMs,
        maxAttempts: maxAttempts,
    );
}

pub fn nextDelay(policy: RetryPolicy, attempt: i32) -> i32 {
    var delay = policy.initialMs;
    var n = 1;
    loop (n < attempt) {
        delay = delay * policy.multiplierPercent / 100;
        n = n + 1;
    };
    return delay.min(policy.maxMs);
}
```

**Acceptance:**
- [ ] `nextDelay(p, 1)` is `initialMs` for every policy, including one whose `initialMs` exceeds `maxMs` — in which case it is `maxMs`.
- [ ] With `multiplierPercent: 200`, delays 1…5 are `2000, 4000, 8000, 16000, 30000` for `initialMs: 2000, maxMs: 30000`.
- [ ] `multiplierPercent: 100` produces a constant delay, and `multiplierPercent: 0` is rejected at construction rather than producing a zero-delay hot loop.
- [ ] The function is pure: no clock read, no host cell, callable from a test with no broker and no node.

### Step 2 — Outcomes, and the decision function

```bp
pub type Outcome {
    Done,
    Retry(reason: string),
    Reject(reason: string),
}

pub fn nextAction(outcome: Outcome, policy: RetryPolicy, attempt: i32) -> string {
    val out = case outcome {
        Done -> "ack";
        Reject(reason) -> "dead-letter";
        Retry(reason) -> retryOrDeadLetter(policy, attempt);
    };
    return out;
}

fn retryOrDeadLetter(policy: RetryPolicy, attempt: i32) -> string {
    val exhausted = attempt >= policy.maxAttempts;
    if (exhausted) {
        return "dead-letter";
    };
    return "retry";
}
```

**Acceptance:**
- [ ] `Reject` returns `"dead-letter"` at attempt 1, whatever `maxAttempts` says — a rejection consumes no attempts.
- [ ] `Retry` at `attempt == maxAttempts` returns `"dead-letter"`; at `maxAttempts - 1` it returns `"retry"`.
- [ ] `Done` returns `"ack"` and the attempt is irrelevant.
- [ ] The three-by-three table of (outcome × attempt position) is a test with nine cells.

### Step 3 — The attempt carrier

```bp
pub fn attemptOf(delivery: Delivery) -> i32 {
    val raw = delivery.header("x-rakun-attempt");
    if (raw == "") {
        return 1;
    };
    return parseCount(raw, 1);
}
```

`parseCount` is this front's own decimal walk with a fallback. std has no string-to-integer
conversion — `libs/std/src/url.bp:86-97` carries a private `parsePortWalk` for exactly this reason,
and it is private. The walk is copied rather than imported, and the module README says so; a fourth
copy of it in the tree is the signal that front 01 should promote one.

**Acceptance:**
- [ ] A delivery with no `x-rakun-attempt` header is attempt 1.
- [ ] A redelivery published by this front carries `x-rakun-attempt` one higher than the delivery that failed.
- [ ] Killing the consumer process between two deliveries does not reset the count — the assertion is made by restarting the listener supervisor mid-test and reading the header on the next delivery.
- [ ] A non-numeric header value is treated as attempt 1 and logged once, rather than raising inside the dispatcher.

### Step 4 — The dead-letter destination and its envelope

```bp
pub type DeadLetter(
    destination: string,
    body: string,
    reason: string,
    attempt: i32,
    firstSeenMs: i32,
)

pub fn deadLetterName(destination: string) -> string {
    return destination + ".dlq";
}
```

**Acceptance:**
- [ ] The envelope carries the original destination, not the dead-letter destination, in its `destination` field.
- [ ] The original message is acknowledged only after the dead-letter publish is confirmed; a test that fails the dead-letter publish asserts the original is still unacknowledged.
- [ ] `rakun.messaging.listener.<name>.dead-letter` overrides the `.dlq` suffix.
- [ ] A dead-lettered message is not re-consumed by the same listener — the DLQ is not subscribed by the listener that fills it.

### Step 5 — Acknowledgement modes

```bp
pub type AckMode {
    Auto,
    Manual,
    Batch(size: i32),
}
```

**Acceptance:**
- [ ] `Auto`: a `Done` acknowledges, a `Retry` does not.
- [ ] `Manual`: nothing is acknowledged by the dispatcher; a listener returning `Done` without acking logs a warning naming the listener.
- [ ] `Batch(size)`: acknowledgement happens every `size` messages and on listener shutdown, and the test asserts the replay window after a crash is at most `size - 1` messages.
- [ ] An unknown ack mode in configuration fails at boot with a located message, not at the first message.

### Step 6 — Concurrency and prefetch

```bp
// rakun.messaging.listener.orders.concurrency = 4
// rakun.messaging.listener.orders.prefetch    = 32
```

**Acceptance:**
- [ ] `concurrency: 4` starts four consumer processes under one supervisor, verified by counting children.
- [ ] Killing one consumer leaves the other three consuming, and the killed one is replaced.
- [ ] `prefetch` limits unacknowledged messages per consumer process; a test with `prefetch: 1` and a blocked handler asserts the second message is not delivered.
- [ ] The module README states that this sizes processes, not threads.

### Step 7 — Producer transactions, and the handoff

```bp
pub fn withProducerTransaction(prefix: string, body: fn() -> i32) -> i32
```

**Acceptance:**
- [ ] On Kafka, a body that raises leaves no message visible to a `read_committed` consumer.
- [ ] On Kafka, a body that returns commits all its sends atomically.
- [ ] On AMQP, the call raises with a message naming front 83's outbox, and the module README repeats the reason.
- [ ] The transaction id prefix reaches the producer configuration, matching `spring.kafka.producer.transaction-id-prefix`.

### Step 8 — What the operator sees

**Acceptance:**
- [ ] Counters registered with front 75: deliveries, retries, dead-letters and handler duration, each tagged by listener name.
- [ ] A `messaging` health indicator registered with front 11 reporting broker connectivity per configured listener.
- [ ] Every dead-letter emits one log record at warn with the listener name, the reason and the attempt count — and exactly one, not one per retry.

## Examples

- [`examples/retry-and-dlq-example.bp`](./examples/retry-and-dlq-example.bp) — an order-confirmation
  listener that distinguishes a transient failure from a poison message, and the backoff and routing
  decisions asserted as pure functions.
- [`examples/publish-reliability-example.bp`](./examples/publish-reliability-example.bp) — the publish
  side: retry around a single send, a Kafka producer transaction around a batch, and the AMQP refusal
  that points at front 83.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| Declared parameter defaults are never applied (ground truth §2.24), so a decorator cannot carry optional arguments. `#[rabbitListener("orders", maxAttempts: 3)]` would force every listener in the codebase to spell every setting. | `examples/retry-and-dlq-example.bp`, the `#[rabbitListener]` line | One required argument on the decorator; every other setting is a configuration key looked up by listener name. | Apply declared defaults at call sites (`docs.md:502-505`) |
| A decorator cannot replace or wrap the body of the declaration it annotates — `@Decl` is read-only and `@emit` only appends new module-level declarations. Publish-side retry therefore cannot be `#[retryable]` on a method. | `examples/publish-reliability-example.bp`, every `publishWithRetry` call | Call the combinator in the body: `publishWithRetry(dest, body, policy)`. | `decl.replaceBody(src)`, or an `@emit` whose output shadows the annotated declaration |

## Test plan

`modules/rakun-messaging/test/reliability/` on the **erlang** target, invoked as
`zig build test-libs -- --target erlang --lib rakun` from `repository/botopink-lang/`, and as
`botopink test --target erlang` from `repository/rakun/`.

| File | Asserts |
|---|---|
| `test/reliability/backoff_test.bp` | The delay series, the ceiling, the constant-multiplier case, rejection of `multiplierPercent: 0` |
| `test/reliability/decision_test.bp` | The nine cells of outcome × attempt position, and that `Reject` consumes no attempt |
| `test/reliability/attempt_test.bp` | Header round trip, default of 1, survival across a consumer restart, non-numeric tolerance |
| `test/reliability/dlq_test.bp` | Envelope contents, publish-before-ack ordering, the configured override, no self-consumption |
| `test/reliability/ack_test.bp` | The three modes, the manual-ack warning, the batch replay window |
| `test/reliability/transaction_test.bp` | Kafka commit and abort visibility, the AMQP refusal message |

Steps 1, 2 and 4 are pure and run with no broker. Steps 3, 5, 6, 7 and 8 need one: they run against a
broker when `RAKUN_TEST_AMQP_URL` or `RAKUN_TEST_KAFKA_BROKERS` is set and report a *skipped* cell
otherwise. A skipped broker cell is reported, never silently passed — a reliability front that passes
green with no broker present is asserting nothing.

There is no commonJS row. This front is server-only by the milestone's target split.

## Definition of done

- `modules/rakun-messaging/src/reliability/` exists, is declared from the module's `root.bp`, and holds no `@External.Node` cell.
- The attempt counter is carried in a message header and demonstrated to survive a consumer restart.
- `Retry` and `Reject` are distinguishable by a handler and routed differently by the dispatcher.
- A dead-letter publish that fails leaves the original unacknowledged, proven by a test.
- `withProducerTransaction` works on Kafka and refuses on AMQP with a message naming front 83.
- Both language gaps above appear as `// LANGUAGE GAP:` markers in the examples and in a `specs/1.0.10-beta/` spec.
- `repository/rakun/AGENTS.md` and `modules/README.md` record the surface in the same commit.
- The front's tests are green on erlang.

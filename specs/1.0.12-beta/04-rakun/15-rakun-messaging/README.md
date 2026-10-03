# Front 15 — Messaging: registry reset, acknowledgement, JMS, streams, transactions, scheduling

**Priority:** high — 19's broker double and `bootAndExit` wait on step 1; 91 and 92 wait on the
member; 86's `Retry` and 90's retry ceiling are correctness gaps in delivered code · **State:** not
started (two premises already true: the listener-names term and the producer transaction exist)
**Depends on:** 128 · 03r-al (step 5) · lg2-w (R16-1, one box) · 03r-k / 03r-l / 03r-x (confirmations)
**Owns:** `modules/rakun-messaging/**` except 91's (`src/pulsar/**`, `src/pulsar_host.bp`,
`src/sidecars/rakun_pulsar.erl`, `test/pulsar/**`) and 92's (`src/rsocket/**`, `test/rsocket/**`,
`src/sidecars/rakun_rsocket.erl`) — `src/stream/**`, `test/stream/**` are this front's ·
`modules/rakun-data/src/tx/**`, `test/tx/**` (carve-out in 08's member) · `modules/rakun-scheduling/**`
· `repository/rakun/AGENTS.md` § Messaging, § Scheduling, § Transactions, § Streams
**Does not touch:** 91's and 92's files · the rest of `rakun-data` (08's, 09's) · `rakun-test` (19
consumes the hooks) · `rakun-metrics` (17's)

## Goal

The listener and task registries reset with the context; a `Retry` under `Auto` is a broker
redelivery carrying its attempt count, on AMQP and STOMP alike; a stopping worker settles its batch;
`publishWithRetry` exists and `jmsSend` uses it; `#[jmsListener]` exists; the stream source honours
its demand and windows emit on a watermark; 83's outbox path enrols in the producer transaction.
Every cell runs on the in-process broker (03r-k) or the JMS fixture; real drivers are `deferred.md`
rows under the toolchain row "a sidecar cannot reach an external OTP application", and the three
`RAKUN_TEST_*` variables of the closed README never appear.

## Mechanism

- **Already in code.** `rakun_messaging.erl` puts `rakun_listener_names` on every registration and
  the core reads it (`rakun_runtime.erl`). `reliability/transaction.bp` `withProducerTransaction`
  holds a transaction's publishes and releases them in order on commit, drops them on a raise —
  `read_committed` visibility, tested in `reliability/transaction_test.bp`. JMS is STOMP over
  `rakun_jms.erl` with `rakun_jms_fixture.erl` playing the broker; the AMQP 1.0 arm refuses (no
  `amqp10_client`).
- **Registries for 19 (R19-1/2).** Neither `registry.bp` nor `rakun-scheduling/src/registry.bp`
  registers with the core's `rkOnReset`; each calls `rkOnReset("rakun-messaging" | "rakun-scheduling",
  reset)` at module load.
- **Broker semantics (R86-1, R89-1).** The in-process broker gains `nack(tag, requeue)` with a
  redelivery count on the envelope (`x-attempt`); `Auto` + `Retry` becomes `nack(requeue: true)`
  with the count carried. The stream source's prefetch is honoured by the stage not accepting
  until it has demand.
- **Batch flush (R86-2).** The worker loop gains a `stop` message; on shutdown the container sends
  it and the worker settles its held batch before exiting.
- **`publishWithRetry` (R86-3).** A combinator in `reliability/policy.bp`:
  `publishWithRetry(policy, publish: fn() -> i32) -> i32` — backoff from the policy, dead-letter at
  the ceiling; `jmsSend` and `templates.bp`'s publish call it when a policy is configured for the
  destination. Not a wrapping decorator (lg2-c does not block it).
- **STOMP attempt count (R90-4).** The fixture broker sets `x-attempt` on a NACK's redelivery (a real
  broker preserves headers); the arm reads it, so 86's ceiling applies.
- **Windows (R89-2/3).** `Window(size, lateness)` with a watermark advanced by event time; one
  emission per window at watermark passage; a late event within `lateness` re-emits, beyond it goes
  to the `late` branch and is counted.
- **Transactions (R83-1, 03r-al).** With the in-process broker configured transactional, 83's outbox
  path (`src/tx/**`) publishes through `withProducerTransaction` and writes no outbox row; today
  `outbox_test.bp` "path choice: broker transactions skip the outbox, otherwise the outbox is used"
  holds the choice minus the broker.

## Open

### Step 1 — Registries on the reset hook (R19-1/2, this member's half)

- [ ] `registry_test.bp`: after `resetContext()` (through the core's `rkOnReset`) the listener registry is empty and `rakun_listener_names` answers `[]`; a registration afterwards is visible in both
- [ ] `rakun-scheduling/test/registry_test.bp`: the same for the task registry

### Step 2 — Acknowledgement (R86-1, R86-2, R90-4, R90-5)

- [ ] `reliability/ack_test.bp`: under `Auto` a `Retry` leaves the original unsettled and the broker redelivers it with `x-attempt` incremented; a `Done` settles it
- [ ] a stopping worker with a held batch of 3 settles them before exiting (the broker's unsettled count is 0 after the container stops)
- [ ] `jms/client_test.bp`: a STOMP redelivery carries `x-attempt`, and the third `Retry` of a ceiling-2 policy dead-letters through 86
- [ ] `Auto` / `Manual` / `Batch(size)` map onto `client-individual` / `client` / `client` with an explicit ACK frame every `size`, asserted on the fixture's frame log

### Step 3 — `publishWithRetry` and the JMS tail (R86-3, R90-1/2/3/6/7/8)

- [ ] `reliability/backoff_test.bp`: `publishWithRetry` retries a failing publish with the policy's backoff and dead-letters at the ceiling; a succeeding publish is called once
- [ ] `jms/client_test.bp`: `jmsSend` with a configured policy goes through it (a fixture that fails twice is retried twice)
- [ ] `#[jmsListener("q")]` registers on the shared registry tagged `jms`; on a non-method it fails with a located message (`build_test.bp` over a scratch project)
- [ ] heart-beat: the fixture negotiates `heart-beat:1000,1000`; a fixture that stops beating closes the connection within two intervals, asserted with `io.clock`
- [ ] request/reply: a late reply after the timeout is discarded and the requester process is alive; the reply subscription is removed when the requester raises (the fixture's subscription list)
- [ ] the `jms` indicator is hidden by the default exposure and shown when 76 exposes `health` details (asserted through the core's `actuator_api` registry and the exposure rule)

### Step 4 — Streams (R89-1/2/3)

- [ ] `stream/runtime_test.bp`: with `Queue(prefetch: 1)` and a blocked first stage, the broker's fetched count is 1 (the second message is not fetched)
- [ ] `stream/stages_test.bp`: two events in one window emit once with the combined aggregate when the watermark passes; two across a boundary emit twice
- [ ] a late event within `lateness` re-emits its window; one beyond it is counted on the `late` branch and does not re-emit

### Step 5 — The outbox path in the producer transaction (R83-1, 03r-al)

- [ ] `tx/outbox_test.bp`: with the in-process broker configured transactional, a publish enrolled in a transaction goes through `withProducerTransaction` and writes no outbox row (the outbox table count is unchanged)
- [ ] an aborted transaction leaves no message visible to a `read_committed` consumer; a committed one is delivered once
- [ ] R83-1's DoD ("broker-native transactions are used where available, through the same API, and which path ran is observable"): which path ran is in the log line the existing cell reads
- [ ] one `deferred.md` row: the same three assertions against a real Kafka broker

### Step 6 — Scheduling and defaults (R16-1, RX-2)

- [ ] R16-1 ("the parser is an ordinary compiled function; the decorator body calls it") stays open on lg2-w; the README records the inlined parser's size and the one-line change that closes it when the decision lands
- [ ] RX-2 (15, 86, 90): the decorator-argument default re-measured in `decorators_test.bp`, result recorded

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `rakun-messaging` (the `test/stream/` files in the run), `rakun-data` (the `test/tx/` files)
and `rakun-scheduling`; `grep -rn RAKUN_TEST_ modules/rakun-messaging modules/rakun-data/src/tx modules/rakun-data/test/tx` empty.

## Blast radius

The `Auto` + `Retry` change alters redelivery: a handler that answered `Retry` sees the broker's
redelivery with the same payload and a higher `x-attempt` — 86's `attempt_test.bp` re-records. 91
reads the registry hooks and `publishWithRetry` after this lands; 19 consumes step 1.

## Notes

- 03r-k (in-process broker; a real address refuses the boot), 03r-l (container named after its
  destination; Redis ack-mode `none`), 03r-x (conditional-UPDATE claims, resumed coordinators) are
  implemented; confirmation only.
- Kept for their open markers: `examples/order-listeners-example.bp` (lg2-a),
  `publish-reliability-example.bp` (lg2-c), `jms-listener-example.bp` (lg2-a), `saga-example.bp` (lg2-d).

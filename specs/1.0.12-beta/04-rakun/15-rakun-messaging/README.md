# Front 15 — Messaging: registry reset, acknowledgement, JMS, streams, transactions, scheduling

**Priority:** high — 19's broker double and `bootAndExit` wait on step 1; 91, 92 on the member;
86's `Retry` and 90's retry ceiling are correctness gaps in delivered code · **State:** not started
(two premises already true: the listener-names term and the producer transaction exist)
**Depends on:** 128 · 03r-al (step 5) · `01-compiler/14` step 6 (R16-1, decision 341) · 03r-k / 03r-l / 03r-x (confirmations)
**Owns:** `modules/rakun-messaging/**` except 91's (`src/pulsar/**`, `src/pulsar_host.bp`,
`src/sidecars/rakun_pulsar.erl`, `test/pulsar/**`) and 92's (`src/rsocket/**`, `test/rsocket/**`,
`src/sidecars/rakun_rsocket.erl`) — `src/stream/**`, `test/stream/**` are this front's ·
`modules/rakun-data/src/tx/**`, `test/tx/**` (carve-out in 08's member) · `modules/rakun-scheduling/**`
· `repository/rakun/AGENTS.md` § Messaging, § Scheduling, § Transactions, § Streams
**Does not touch:** 91's, 92's files · rest of `rakun-data` (08's, 09's) · `rakun-test` (19
consumes the hooks) · `rakun-metrics` (17's)

## Goal

Listener and task registries reset with the context; under `Auto` a `Retry` is a broker
redelivery carrying its attempt count, AMQP and STOMP alike; a stopping worker settles its batch;
`publishWithRetry` exists, `jmsSend` uses it; `#[jmsListener]` exists; the stream source honours
demand, windows emit on a watermark; 83's outbox path enrols in the producer transaction. Every
cell on the in-process broker (03r-k) or the JMS fixture; real drivers are `deferred.md` rows under
the toolchain row "a sidecar cannot reach an external OTP application"; the closed README's three
`RAKUN_TEST_*` variables never appear.

## Mechanism

- **Already in code.** `rakun_messaging.erl` puts `rakun_listener_names` on every registration; the
  core reads it (`rakun_runtime.erl`). `reliability/transaction.bp` `withProducerTransaction` holds
  publishes, releases in order on commit, drops on a raise — `read_committed`, tested in
  `reliability/transaction_test.bp`. JMS: STOMP over `rakun_jms.erl`, `rakun_jms_fixture.erl` as
  broker; AMQP 1.0 arm refuses (no `amqp10_client`).
- **Registries for 19 (R19-1/2).** Neither `registry.bp` nor `rakun-scheduling/src/registry.bp`
  registers with `rkOnReset`; each calls `rkOnReset("rakun-messaging" | "rakun-scheduling", reset)` at module load.
- **Broker semantics (R86-1, R89-1).** In-process broker gains `nack(tag, requeue)` with a
  redelivery count on the envelope (`x-attempt`); `Auto` + `Retry` → `nack(requeue: true)`, count
  carried. Stream source's prefetch honoured: the stage does not accept until it has demand.
- **Batch flush (R86-2).** Worker loop gains a `stop` message; on shutdown the container sends it,
  the worker settles its held batch before exiting.
- **`publishWithRetry` (R86-3).** In `reliability/policy.bp`:
  `publishWithRetry(policy, publish: fn() -> i32) -> i32` — policy backoff, dead-letter at the
  ceiling; `jmsSend` and `templates.bp`'s publish call it when the destination has a policy. A
  `#[retryable]` wrapping decorator over it is possible since 316 (`01-checker` step 30); not this step.
- **STOMP attempt count (R90-4).** Fixture broker sets `x-attempt` on a NACK's redelivery (a real
  broker preserves headers); the arm reads it, so 86's ceiling applies.
- **Windows (R89-2/3).** `Window(size, lateness)`, watermark advanced by event time; one emission
  per window at watermark passage; late event within `lateness` re-emits, beyond it goes to the
  `late` branch, counted.
- **Transactions (R83-1, 03r-al).** In-process broker transactional → 83's outbox path
  (`src/tx/**`) publishes through `withProducerTransaction`, writes no outbox row; today
  `outbox_test.bp` "path choice: broker transactions skip the outbox, otherwise the outbox is used"
  holds the choice minus the broker.

## Open

### Step 1 — Registries on the reset hook (R19-1/2, this member's half)

- [ ] `registry_test.bp`: after `resetContext()` (through `rkOnReset`) the listener registry is empty and `rakun_listener_names` answers `[]`; a later registration visible in both
- [ ] `rakun-scheduling/test/registry_test.bp`: the same for the task registry

### Step 2 — Acknowledgement (R86-1, R86-2, R90-4, R90-5)

- [ ] `reliability/ack_test.bp`: under `Auto` a `Retry` leaves the original unsettled, the broker redelivers it with `x-attempt` incremented; a `Done` settles it
- [ ] a stopping worker with a held batch of 3 settles them before exiting (broker's unsettled count 0 after the container stops)
- [ ] `jms/client_test.bp`: a STOMP redelivery carries `x-attempt`; the third `Retry` of a ceiling-2 policy dead-letters through 86
- [ ] `Auto` / `Manual` / `Batch(size)` map onto `client-individual` / `client` / `client` with an explicit ACK frame every `size`, on the fixture's frame log

### Step 3 — `publishWithRetry` and the JMS tail (R86-3, R90-1/2/3/6/7/8)

- [ ] `reliability/backoff_test.bp`: `publishWithRetry` retries a failing publish with the policy's backoff, dead-letters at the ceiling; a succeeding publish called once
- [ ] `jms/client_test.bp`: `jmsSend` with a configured policy goes through it (a fixture failing twice is retried twice)
- [ ] `#[jmsListener("q")]` registers on the shared registry tagged `jms`; on a non-method fails with a located message (`build_test.bp` over a scratch project)
- [ ] heart-beat: fixture negotiates `heart-beat:1000,1000`; a fixture that stops beating closes the connection within two intervals (`io.clock`)
- [ ] request/reply: a reply after the timeout is discarded, the requester process alive; the reply subscription removed when the requester raises (fixture's subscription list)
- [ ] `jms` indicator hidden by default exposure, shown when 76 exposes `health` details (through the core's `actuator_api` registry and the exposure rule)

### Step 4 — Streams (R89-1/2/3)

- [ ] `stream/runtime_test.bp`: with `Queue(prefetch: 1)` and a blocked first stage, the broker's fetched count is 1 (second message not fetched)
- [ ] `stream/stages_test.bp`: two events in one window emit once with the combined aggregate at watermark passage; two across a boundary emit twice
- [ ] a late event within `lateness` re-emits its window; one beyond it counted on the `late` branch, no re-emit

### Step 5 — The outbox path in the producer transaction (R83-1, 03r-al)

- [ ] `tx/outbox_test.bp`: in-process broker transactional, a publish enrolled in a transaction goes through `withProducerTransaction`, writes no outbox row (outbox table count unchanged)
- [ ] an aborted transaction leaves no message visible to a `read_committed` consumer; a committed one delivered once
- [ ] R83-1's DoD ("broker-native transactions are used where available, through the same API, and which path ran is observable"): which path ran is in the log line the existing cell reads
- [ ] one `deferred.md` row: the same three assertions against a real Kafka broker

### Step 6 — Scheduling and defaults (R16-1, RX-2)

- [ ] R16-1 ("the parser is an ordinary compiled function; the decorator body calls it") closes once `01-compiler/14` step 6 lands (341): a host cell it reaches needs `@External.Beam` only (rakun declares `["erlang"]`); until then README records the inlined parser's size and the one-line change
- [ ] RX-2 (15, 86, 90): decorator-argument default re-measured in `decorators_test.bp`, result recorded

### Step 7 — configuration as a typed record (decision 299)

- [ ] this member's `#[value("…")]` / `rkProp*` reads and group configs become `#[config("<prefix>")]` records (`04` step 7)

### Step 8 — one listener: `#[listen(dest)]` (decision 318 (5))

- [ ] `pub val orders = Destination<OrderPlaced>("order-events")`: the destination declared once, typed,
      the broker's name a string (281); the transport and group from 299's typed config
- [ ] `#[listen(orders)]` on a method of a `#[component]`; the payload the method's parameter, checked
      against the destination's `T`; `#[amqpListener]`, `#[kafkaListener]`, `#[redisListener]`,
      `#[streamListener]` and the type-level `#[listener]` deleted, every site and test rewritten
- [ ] `#[retryable(…)]` on a publishing method a wrapper (316) over `publishWithRetry`;
      `publish-reliability-example.bp`'s marker rewritten

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `rakun-messaging` (`test/stream/` in the run), `rakun-data` (`test/tx/`) and
`rakun-scheduling`; `grep -rn RAKUN_TEST_ modules/rakun-messaging modules/rakun-data/src/tx modules/rakun-data/test/tx` empty.

## Blast radius

`Auto` + `Retry` alters redelivery: a handler answering `Retry` sees the redelivery with the same
payload and a higher `x-attempt` — 86's `attempt_test.bp` re-records. 91 reads the registry hooks
and `publishWithRetry` after this lands; 19 consumes step 1.

## Notes

- 03r-k (in-process broker; a real address refuses the boot), 03r-l (container named after its
  destination; Redis ack-mode `none`), 03r-x (conditional-UPDATE claims, resumed coordinators)
  implemented; confirmation only.
- Kept for open markers: `examples/order-listeners-example.bp` (the byte gap, 346),
  `publish-reliability-example.bp` (316: rewritten once `01-checker` step 30 lands), `jms-listener-example.bp` (the byte gap, 346), `saga-example.bp` (lg2-d).

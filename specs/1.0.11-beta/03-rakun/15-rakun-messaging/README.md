# Front 15 — Messaging (registry, reliability, JMS, transactions, streams, scheduling)

**Priority:** high — 19's broker double and `bootAndExit` wait on the registries this front hangs off `rkOnReset`; 91 waits on it whole; 83's broker path and 90's retry ceiling are correctness gaps in delivered code
**Carries:** 16 · 83 · 86 · 89 · 90
**Depends on:** maintainer 03r-al (transactional visibility on the in-process broker), 03r-k / 03r-l / 03r-x (confirmations) · compiler lg2-w (R16-1 — one box, stays open until answered), lg2-c (R86-3 is a combinator, not a wrapping decorator — not blocked)
**Owns:** `modules/rakun-messaging/**` except 91's (`src/pulsar/**`, `src/pulsar_host.bp`, `src/sidecars/rakun_pulsar.erl`, `test/pulsar/**`) · `modules/rakun-tx/**` · `modules/rakun-stream/**` · `modules/rakun-scheduling/**` · `repository/rakun/AGENTS.md` § Messaging, § Scheduling, § Transactions, § Streams
**Does not touch:** 91's files · `rakun-test` (19 consumes the registry hooks) · `rakun-metrics` (17's)

---

## Carried from 1.0.10

| Id | From (`specs/1.0.10-beta/03-rakun/`) | Box, as written |
|---|---|---|
| R15-1 | `15-rakun-messaging/README.md` (all boxes ticked; the tail is 03r-k) | "every arm runs on the in-process broker until a sidecar can load an OTP driver"; the integration cells (`RAKUN_TEST_AMQP_URL`, `RAKUN_TEST_KAFKA_BROKERS`, `RAKUN_TEST_REDIS_URL`) were never written |
| R19-1/2 (this member's half) | `19-rakun-test-utilities/README.md` § Step 4 | "the listener and task registries hang off the core's `rkOnReset` once fronts 15 and 16 register theirs" · "listener destinations read `[]` until front 15 keeps the `rakun_listener_names` term" |
| R16-1 | `16-rakun-scheduling/README.md` § Step 3 — The cron parser | "The parser is an ordinary compiled function; the decorator body calls it and does not inline a parser of its own." — blocked on lg2-w |
| R83-1 | `83-rakun-distributed-transactions/README.md` § Step 6 — Broker-native transactions | "With a Kafka broker configured for producer transactions, a publish enrolled in a transaction goes through the broker's transaction and writes no outbox row" · "A rolled-back transaction leaves no message readable by a consumer in `read_committed` mode" · DoD "Broker-native transactions are used where available, through the same API, and which path ran is observable" |
| R86-1 | `86-rakun-messaging-reliability/README.md` § Step 5 — Acknowledgement modes | "`Auto`: a `Done` acknowledges, a `Retry` does not. — open: … a `Retry` publishes the redelivery carrying the next attempt and then settles the original — front 15's in-process broker has no reject-without-requeue" |
| R86-2 | same § Step 5 | "`Batch(size)`: acknowledgement happens every `size` messages and on listener shutdown … — open: the flush on shutdown does not — front 15's worker loop takes no message but a delivery, so a stopping worker cannot be asked to settle its held batch" |
| R86-3 | `90-rakun-jms-brokers/README.md` § Step 3 (the blocker it names) | "front 86 has no `publishWithRetry` (a decorator cannot wrap a body, and the combinator was not written)" |
| R89-1 | `89-rakun-stream-pipelines/README.md` § Step 2 — Sources, sinks and demand | "with `Queue(prefetch: 1)` and a blocked pipeline, the second message is not fetched. — open: … the stage accepted the first, so the second is the one the source holds - it is fetched, the third is not" |
| R89-2 | same § Step 5 — Windows | "Two events in the same window produce one emission with the combined aggregate; two events across a boundary produce two. — open: … a per-window emission on a watermark is not implemented" |
| R89-3 | same § Step 5 | "A late event arriving within the lateness allowance updates its window's emission; one arriving after it goes to the late branch and is counted. — open: no watermark, lateness allowance or late branch" |
| R90-1 | `90-rakun-jms-brokers/README.md` § Step 2 — The STOMP frame codec | "Heart-beating negotiates from the `heart-beat` header and a missed beat closes the connection rather than hanging. — open: implemented (`rakun_jms.erl` …), not asserted" |
| R90-2 | same § Step 3 — Sending | "`jmsSend` goes through front 86's `publishWithRetry` when a retry policy is configured for the destination." |
| R90-3 | same § `#[jmsListener("someQueue")]` | "`#[jmsListener]` on anything but a method fails with a located message. — open: listeners register through `jmsListen`; there is no `#[jmsListener]` marker" |
| R90-4 | same | "`Outcome.Retry` and `Outcome.Reject` route through front 86 exactly as they do on the AMQP 0-9-1 arm. — open: … a STOMP redelivery carries no attempt count, so the retry ceiling of front 86 does not apply" |
| R90-5 | same | "The three acknowledgement modes behave as front 86 documents them, including `Batch` on a STOMP subscription with `ack: client`. — open: `auto`, `client` and `client-individual` are handed to the broker; front 86's modes are not mapped" |
| R90-6 | same § Step 6 — Request/reply | "A request that times out returns an error … and the late reply is discarded without crashing the requester. — open: … the late reply is not asserted" |
| R90-7 | same § Step 6 | "The temporary reply destination is removed when the requester finishes, including when it raises. — open: … not asserted for a raise" |
| R90-8 | same § Step 7 — Health | "It is registered with front 11 and hidden by default behind front 76's exposure rules. — open: … its visibility is `/actuator/health`'s, not asserted here" |
| RX-2 | closed READMEs of 15, 86, 90 | the "declared defaults" text — re-measure in `decorators_test.bp` |

## Problem

A `Retry` under `Auto` settles the original after publishing a redelivery — the message is never
redelivered by the broker, only re-published, so a crash between the two loses it. A batch held by
a stopping worker is redelivered instead of settled. A STOMP redelivery restarts its attempt count,
so 86's ceiling never fires on JMS. The stream source fetches one message more than its demand.
Nothing in the gate exercises a broker transaction. The broker double 19 owes cannot reach the
listener registry, which is not reset with the context.

## Current state

- `rakun-messaging`: 8 test files + `jms/` (2) + `pulsar/` (2, 91's) + `reliability/` (5), 91 tests
  green. The in-process broker is `rakun_messaging.erl` (03r-k); JMS is STOMP over `rakun_jms.erl`
  with `rakun_jms_fixture.erl` playing the broker; the AMQP 1.0 arm refuses (no `amqp10_client`).
- `rakun-tx`: `outbox_test.bp` "path choice: broker transactions skip the outbox, otherwise the
  outbox is used, and each is counted and logged" holds the choice minus the broker.
- `rakun-stream`: `runtime_test.bp` "with prefetch 1 and a blocked pipeline, the broker holds the
  rest" — one message unsettled, the rest held; the second is fetched.
- `rakun-scheduling`: 7 files + `jobstore/` (4), 67 tests green; the cron parser is inlined in the
  decorator body (lg2-w); the task registry does not register with `rkOnReset`.

## Mechanism

- **Broker semantics (R86-1, R83-1, R89-1).** The in-process broker gains `nack(tag, requeue:
  false)` with a redelivery count on the envelope (`x-attempt`), and `beginTx / commitTx / abortTx`
  with `read_committed` visibility (an uncommitted publish is invisible to consumers; abort discards).
  `Auto` + `Retry` becomes `nack(requeue: true)` with the count carried; the source's prefetch is
  honoured by the *stage* not accepting until it has demand.
- **Batch flush (R86-2).** The worker loop gains a `stop` message: on shutdown the container sends
  it and the worker settles its held batch before exiting.
- **`publishWithRetry` (R86-3).** A combinator in `reliability/policy.bp`:
  `publishWithRetry(policy, publish: fn() -> i32) -> i32`, backoff from the policy, dead-letter on
  the ceiling; `jmsSend` and `templates.bp`'s publish call it when a policy is configured for the
  destination.
- **STOMP attempt count (R90-4).** The `x-attempt` header is set on the NACK's redelivery by the
  fixture broker (a real broker preserves headers); the arm reads it, so 86's ceiling applies.
- **Registries for 19 (R19-1/2).** `registry.bp` calls `rkOnReset("rakun-messaging", reset)` at
  module load and keeps the `rakun_listener_names` term; `rakun-scheduling/src/registry.bp` does the
  same for tasks.
- **Windows (R89-2/3).** `Window(size, lateness)` stage with a watermark advanced by event time;
  an emission per window at watermark passage; a late event within `lateness` re-emits, beyond it
  goes to the `late` branch and is counted.

## Gate stance

No integration cell is written; the three environment variables of the closed README never appear
in the tree. The in-process broker is the gate arm for every messaging cell, including 83's
transaction path (03r-al). Real drivers (`amqp_client`, `brod`, Streams, `amqp10_client`) are
`deferred.md` rows under the toolchain row "a sidecar cannot reach an external OTP application".

## Steps

### Step 1 — Registries and the reset hook (R19-1/2 halves)

**Acceptance:**
- [ ] `registry_test.bp`: after `resetContext()` (through the core's `rkOnReset`) the listener registry is empty and `rakun_listener_names` is `[]`; a registration afterwards is visible in both
- [ ] `rakun-scheduling/test/registry_test.bp`: the same for the task registry

### Step 2 — Acknowledgement semantics (R86-1, R86-2, R90-4, R90-5)

**Acceptance:**
- [ ] `reliability/ack_test.bp`: under `Auto` a `Retry` leaves the original unsettled and the broker redelivers it with `x-attempt` incremented; a `Done` settles it
- [ ] a stopping worker with a held batch of 3 settles them before exiting (the broker's unsettled count is 0 after the container stops)
- [ ] `jms/client_test.bp`: a STOMP redelivery carries `x-attempt`, and the third `Retry` of a ceiling-2 policy dead-letters through 86
- [ ] `Auto` / `Manual` / `Batch(size)` map onto `client-individual` / `client` / `client` with an explicit ACK frame every `size`, asserted on the fixture's frame log

### Step 3 — `publishWithRetry` and the JMS tail (R86-3, R90-1/2/3/6/7/8)

**Acceptance:**
- [ ] `reliability/backoff_test.bp`: `publishWithRetry` retries a failing publish with the policy's backoff and dead-letters at the ceiling; a succeeding publish is called once
- [ ] `jms/client_test.bp`: `jmsSend` with a configured policy goes through it (a fixture that fails twice is retried twice)
- [ ] `#[jmsListener("q")]` registers on the shared registry tagged `jms`; on a non-method it fails with a located message (`build_test.bp` over a scratch project)
- [ ] heart-beat: the fixture negotiates `heart-beat:1000,1000`; a fixture that stops beating closes the connection within two intervals, asserted with `io.clock`
- [ ] request/reply: a late reply after the timeout is discarded and the requester process is alive; the reply subscription is removed when the requester raises (the fixture's subscription list)
- [ ] the `jms` indicator is hidden by the default exposure and shown when 76 exposes `health` details (asserted through `rakun-actuator-api`'s registry and the exposure rule)

### Step 4 — Streams (R89-1/2/3)

**Acceptance:**
- [ ] `runtime_test.bp`: with `Queue(prefetch: 1)` and a blocked first stage, the broker's fetched count is 1 (the second message is not fetched)
- [ ] `stages_test.bp`: two events in one window emit once with the combined aggregate when the watermark passes; two across a boundary emit twice
- [ ] a late event within `lateness` re-emits its window; one beyond it is counted on the `late` branch and does not re-emit

### Step 5 — Broker transactions (R83-1, 03r-al)

**Acceptance:**
- [ ] `outbox_test.bp`: with the in-process broker configured transactional, a publish enrolled in a transaction goes through `beginTx`/`commitTx` and writes no outbox row (the outbox table count is unchanged)
- [ ] an aborted transaction leaves no message visible to a `read_committed` consumer; a committed one is delivered once
- [ ] the DoD box ticked: which path ran is in the log line the existing cell reads
- [ ] one `deferred.md` row: the same three assertions against a real Kafka broker

### Step 6 — Scheduling (R16-1)

**Acceptance:**
- [ ] R16-1 stays open, blocked on lg2-w; the README records the inlined parser's size and the one-line change that closes the box when the decision lands
- [ ] RX-2 for 15/86/90: the decorator-argument default re-measured in `decorators_test.bp`, result recorded

## Gate

- [ ] `botopink test --target erlang` green in `rakun-messaging`, `rakun-tx`, `rakun-stream`, `rakun-scheduling`
- [ ] `grep -rn RAKUN_TEST_ modules/rakun-messaging modules/rakun-tx modules/rakun-stream` answers nothing
- [ ] `botopink format --check` clean in the four members
- [ ] `AGENTS.md` sections updated
- [ ] commit on `fix/15-rakun-messaging`

## Blast radius

The `Auto` + `Retry` change alters redelivery: a handler that answered `Retry` and relied on the
re-published copy now sees the broker's redelivery with the same payload and a higher
`x-attempt` — 86's own `attempt_test.bp` re-records. 91 (pulsar) reads the registry hooks and
`publishWithRetry` after this lands. 19 consumes step 1.

## Notes

- 03r-k (in-process broker; a real address refuses the boot), 03r-l (container named after its
  destination; Redis ack-mode `none`), 03r-x (conditional-UPDATE claims, resumed coordinators) are
  implemented; confirmation only.
- `examples/order-listeners-example.bp` (lg2-a), `publish-reliability-example.bp` (lg2-c),
  `jms-listener-example.bp` (lg2-a), `saga-example.bp` (lg2-d) are copied here for their open
  markers.

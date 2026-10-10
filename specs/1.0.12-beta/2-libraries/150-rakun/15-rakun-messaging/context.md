# Front 15 — Messaging: registry reset, acknowledgement, JMS, streams, transactions, scheduling

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [150-rakun](../README.md): s1 → 150 s5 · s2 → 150 s5 · s3 → 150 s5 · s4 → 150 s5 · s5 → 150 s5 · s6 → 150 s5 · s7 → 150 s5 · s8 → 150 s5. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

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

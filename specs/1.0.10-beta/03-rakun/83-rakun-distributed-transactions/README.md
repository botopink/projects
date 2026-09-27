# Front 83 — rakun Distributed Transactions

**Track:** B rakun
**Priority:** medium — every messaging front can already publish and every data front can already write, and nothing in the milestone stops those two from disagreeing after a crash
**Target:** erlang (server)
**Wave:** 5
**Depends on:** 08 (the local transaction every mechanism here is built on), 15 (the publisher and the listener registry), 16 (the relay's tick), 77 (the tables the outbox, the dedupe store and the decision log live in), 05 (configuration)
**Owns:** `modules/rakun-tx/botopink.json`, `modules/rakun-tx/src/**` · `modules/rakun-tx/test/**`
**Does not touch:** `modules/rakun-data/src/**` (front 08's, including `#[transactional]`), `modules/rakun-messaging/src/**` (front 15's), and the four frozen files in `repository/rakun/src/`
**Reference:** `07-io.md § JTA (Transacoes Distribuidas)`, `§ JMS com JTA` · `06-messaging.md § Apache Kafka · Enviando · Transacoes`, `§ Apache Pulsar · Transacoes` · <https://docs.spring.io/spring-boot/reference/io/jta.html>

---

## Problem

Front 08 gives a service `#[transactional]`: a block of database work that commits or rolls back as a
unit. Front 15 gives it a publisher: a message goes to a broker. Put the two in one method — which is
what almost every interesting service method does — and there is no unit at all.

```
#[transactional]
fn placeOrder(...) {
    orders.insert(...);          // committed at the end of the method
    events.publish("order.placed");  // sent immediately, whatever happens next
}
```

Two failure modes, both routine, neither survivable today. The publish succeeds and the transaction
then rolls back: consumers act on an order that does not exist. The transaction commits and the
process dies before the publish: the order exists and nothing downstream ever hears about it. There
is no ordering of those two operations that fixes it, which is the whole reason JTA exists on the JVM
and the whole reason the outbox pattern exists everywhere else.

Spring's answer in `07 § JTA` is a transaction manager coordinating XA resources. JTA is a JVM API and
there is no BEAM version of it — but the *semantics* are not JVM-specific, and BEAM's answer is
better understood than XA's: make the publish part of the local transaction by writing it to a table,
and relay it afterwards. That is what this front delivers, alongside the two mechanisms for the cases
where one local transaction is not enough: a saga with compensations, and a real two-phase commit for
the small number of cases that genuinely need one.

The boundary with front 08 is sharp and worth stating: **front 08 owns one resource, this front owns
more than one.** `#[transactional]` around two statements against the same database stays entirely in
front 08. The moment a second resource is involved — a broker, a second database, an external service
— it is this front.

## Current state

| Piece | Where it is today |
|---|---|
| `modules/rakun-tx/` | `outbox` (outbox, relay, inbox, path choice), `saga`, `twopc`; 32 tests on erlang |
| The local transaction | rakun-data's `sqlTemplate(ds).transaction(...)` (front 08) — what `publishAfterCommit` and `consumeOnce` enrol in |
| A publisher | a `fn(topic, key, payload) -> string` the relay is given — front 15's in-process broker or any other |
| Any outbox, saga, dedupe store or decision log | `rakun_outbox`, `rakun_inbox`, `rakun_saga`, `rakun_2pc`, created by `installOutbox` / `installSagas` / `install2pc` |
| The tables | created by the `install*` functions with `CREATE TABLE IF NOT EXISTS`, so they also run as a front 77 migration |
| Broker-native transactions | Kafka's producer transactions and Pulsar's transactions are named by the doc set; neither front 15 nor front 91 claims them |

## Mechanism

### Three mechanisms, and when each is the right one

| Mechanism | Use it when | Cost |
|---|---|---|
| **Outbox** | one database write plus one or more publishes | a table, a relay process, at-least-once delivery downstream |
| **Saga** | several services must each do their own local work, and there is a sensible undo for each | a persisted coordinator, a compensation per step, and eventual consistency in between |
| **2PC** | two resources must agree atomically and there is no sensible undo | a decision log, a recovery pass, and blocking if the coordinator dies between prepare and decide |

They are ordered by how often the answer is each one. The outbox covers most of it, the saga covers
most of the rest, and 2PC is for the residue — it is included because `07 § JTA` describes exactly
that residue, and excluded from being the default because a blocking protocol should never be the
thing a developer reaches for first.

### The outbox, and what makes it correct

```
inside the local transaction (front 08)
  ├─ INSERT INTO orders …
  └─ INSERT INTO rakun_outbox (aggregate, seq, topic, payload, state='pending')
COMMIT                                       ← both, or neither

relay process (supervised, one per partition)
  ├─ SELECT … WHERE state='pending' ORDER BY seq LIMIT n   FOR UPDATE SKIP LOCKED
  ├─ publish (front 15)
  └─ UPDATE … SET state='sent'
```

The correctness comes from one property: the intent to publish commits in the same transaction as the
data it describes. After that, the relay can crash at any point and the worst outcome is publishing
the same message twice — which is why the consumer half of this front exists.

`FOR UPDATE SKIP LOCKED` is what lets N nodes each run a relay without coordinating: each takes rows
nobody else holds. Per-aggregate ordering is preserved because rows for one aggregate carry a
monotonic `seq` and a relay claims an aggregate's rows in order; two aggregates are unordered with
respect to each other, which is the honest guarantee and the only one a partitioned system can offer.

### Effectively-once consumption

At-least-once plus a dedupe store equals effectively-once *processing*, which is the strongest thing
available without distributed consensus and is what everybody means when they say exactly-once.

```
inside the local transaction
  ├─ INSERT INTO rakun_inbox (consumer, message_id)   ← unique; conflict means seen
  │     conflict → commit, ack, do nothing else
  └─ the handler's own writes
COMMIT
ack
```

The insert and the handler's writes commit together, so a handler that ran and a message marked seen
are the same event. A handler that crashes rolls both back and the message is redelivered.

### The saga

A saga is a value, not a decorated block — see *Language gaps* for why. Each step carries a name, a
forward action and a compensation; the coordinator is a supervised `gen_statem` that persists its
position after every step and every compensation.

- Forward failure at step *k* runs compensations *k-1 … 1*, in reverse.
- A compensation that fails is retried with backoff, and after the configured attempts the saga is
  **parked** in a `needs_attention` state with its whole history. It is never dropped, never marked
  complete and never silently retried forever, because an unpaid refund that stops being retried
  without anybody knowing is the failure that ends up in the newspaper.
- A coordinator that dies is restarted by its supervisor and resumes from the persisted position. A
  step that was in flight when the node died is re-run, so every forward action and every
  compensation must be idempotent. That is a requirement on the application and the front states it
  loudly rather than pretending to remove it.

### Two-phase commit

A `gen_statem` per transaction: `prepare` every participant, write the decision to a log **before**
telling anyone, then `commit` or `abort` all of them, retrying until each acknowledges. On boot, the
log is replayed: a transaction with a recorded decision is carried out, one without is aborted.

The honest caveat, which belongs in a README rather than in a comment nobody reads: if the
coordinator dies after prepare and before the decision is logged, participants hold their locks until
it comes back. That is 2PC, not this implementation; it is the reason the outbox and the saga come
first in this front and in its documentation.

### Broker-native transactions

Kafka's producer transactions and Pulsar's transactions do inside the broker what the outbox does
outside it. Where the broker offers one, publishing goes through it and the outbox row is skipped —
one round trip instead of a table write plus a relay. Where it does not, the outbox is the fallback.
The API is the same either way; the choice is a property of the configured broker, not of the calling
code.

## Steps

### Step 1 — The outbox table and the write side

Schema through front 77. `publishAfterCommit` enrols a message in the current transaction; called
outside one it is an error, not a direct publish.

```bp
pub type OutboxMessage(
    aggregate: string,
    topic: string,
    key: string,
    payload: string,
    headers: Array<#(string, string)>,
)

pub fn publishAfterCommit(m: OutboxMessage) -> i32
```

**Acceptance:**
- [x] A message enrolled inside a transaction that commits appears in the outbox exactly once — `outbox_test` "a message enrolled in a committed transaction is stored with the business row"
- [x] A message enrolled inside a transaction that rolls back appears nowhere — `outbox_test` "a rolled-back transaction leaves neither the business row nor the message"
- [x] `publishAfterCommit` outside a transaction fails with a message naming the method, and publishes nothing — `outbox_test` "publishAfterCommit outside a transaction refuses"
- [x] Two messages for one aggregate carry increasing `seq` — `outbox_test` "the rows of one aggregate carry increasing seq"
- [x] The payload round-trips a value containing a quote, a newline and a four-byte UTF-8 character — `outbox_test` "a payload with a quote, a newline and a four-byte character round-trips"

### Step 2 — The relay

**Acceptance:**
- [x] A pending row is published and marked sent — `outbox_test` "the relay publishes pending rows in seq order per aggregate and marks them sent"
- [x] Two relays on two nodes never publish the same row — asserted with `SKIP LOCKED` under a concurrent run — `outbox_test` "two relays running together publish every row once, each aggregate in seq order" and "a claimed row is published by exactly one relay" — two relay processes, the claim a conditional UPDATE (03r-x)
- [x] A relay killed between publish and mark re-publishes on restart: the row is still pending, and the duplicate is the documented at-least-once behaviour — `outbox_test` "a relay killed between publish and mark leaves the row reclaimable - at-least-once" — the row is `claimed`, `reclaimStale` makes it pending
- [x] Messages for one aggregate are published in `seq` order under concurrency — `outbox_test` "two relays running together publish every row once, each aggregate in seq order"
- [x] A publish that fails is retried with backoff and does not block other aggregates — `outbox_test` "a failed publish backs off, blocks only its aggregate, and fails past max-attempts", "a failed publish waits out its backoff before the next attempt"
- [x] A row that exceeds its retry ceiling moves to `failed` with its last error, and the relay continues — `outbox_test` "a failed publish backs off, blocks only its aggregate, and fails past max-attempts"
- [x] Sent rows are pruned after a configured retention, and the prune is bounded per tick — `outbox_test` "pruning deletes only old sent rows, at most batch per call"

### Step 3 — The inbox and effectively-once consumption

**Acceptance:**
- [x] A message delivered twice runs its handler once — `outbox_test` "inbox: a redelivered message is acknowledged without running the handler again"
- [x] A handler that raises rolls back its writes *and* the inbox row, and the redelivery runs it again — `outbox_test` "inbox: a handler that raises rolls back its writes and the inbox row, so the redelivery runs"
- [x] Two consumer groups each process the same message once, independently — `outbox_test` "inbox: a redelivered message is acknowledged without running the handler again" (groups `billing` and `audit`)
- [x] The inbox is pruned after a retention that is longer than the broker's own redelivery window, and the front states the relationship rather than leaving an operator to discover it — `outbox_test` "inbox: pruning deletes old rows, bounded per call, and refuses a retention inside the redelivery window", "inbox: a retention shorter than the redelivery window is refused, naming both"
- [x] A duplicate is acked, not left to redeliver forever — `outbox_test` "inbox: a redelivered message is acknowledged without running the handler again" — `consumeOnce` answers `duplicate` and returns normally, so the consumer acks

### Step 4 — The saga coordinator

```bp
pub type SagaStep(
    name: string,
    run: fn(ctx: string) -> string,
    compensate: fn(ctx: string) -> string,
)

pub type Saga(
    name: string,
    steps: SagaStep[],
    retries: i32,
    backoffMs: i32,
)

pub fn startSaga(s: Saga, ctx: string) -> string
pub fn sagaState(id: string) -> SagaState
```

**Acceptance:**
- [x] A three-step saga where every step succeeds ends `completed`, with three forward entries and no compensation — `saga_test` "every step runs in order and the saga completes with its history"
- [x] A failure at step 3 compensates 2 then 1, in that order, and ends `compensated` — `saga_test` "a failed step compensates the completed ones in reverse and runs no later step"
- [x] A failure at step 1 compensates nothing and ends `compensated` — `saga_test` "a failure at step 1 compensates nothing and ends compensated"
- [x] A coordinator killed between steps 2 and 3 resumes at step 3 after restart — `saga_test` "a coordinator killed between steps 2 and 3 resumes at step 3, the step it had not finished" — `exit(Pid, kill)` while step 3 runs, then `resumeSagas`
- [x] A compensation that fails is retried to the configured ceiling and then parks in `needs_attention` with the full history — it never ends `completed` and never stops being visible — `saga_test` "a compensation that keeps failing is retried then parks in needs_attention with its history"
- [x] Two sagas of the same definition run concurrently without sharing state — `saga_test` "two runs of one definition keep separate state"
- [x] The persisted history is readable through `sagaState` for an operator, including the failure reason — `saga_test` "a failed step compensates the completed ones in reverse and runs no later step" (the history names `sg2.ship refused`), "startSaga and sagaState use rakun.tx.datasource"

### Step 5 — Two-phase commit

**Acceptance:**
- [x] Two participants that both prepare successfully both commit — `saga_test` "2pc: every participant prepares, the decision is logged, and all commit"
- [x] A participant that refuses prepare causes every participant to abort — `saga_test` "2pc: one participant voting no aborts every participant"
- [x] The decision is durable before any participant is told it — asserted by killing the coordinator between the log write and the first commit message, and observing a commit after recovery — `saga_test` "2pc: a coordinator killed after logging commit and before the first commit message commits on recovery"
- [x] A coordinator killed *before* the decision is logged aborts on recovery — `saga_test` "2pc: a coordinator killed before logging a decision aborts on recovery"
- [x] A participant that does not acknowledge is retried until it does, and the transaction is not considered finished before then — `saga_test` "2pc: a participant that does not acknowledge is retried until it does", "2pc: a transaction whose participant never acknowledges stays open for recovery"
- [x] The README states the blocking window, and the front's own defaults prefer the outbox — `repository/rakun/AGENTS.md` § Distributed transactions and `twopc.bp`'s header state the window; `publishTransactional` defaults to the outbox

### Step 6 — Broker-native transactions

**Acceptance:**
- [ ] With a Kafka broker configured for producer transactions, a publish enrolled in a transaction goes through the broker's transaction and writes no outbox row — open: no Kafka broker here, and no Kafka arm in front 15 (the broker path itself, minus the broker, is `outbox_test` "path choice: broker transactions skip the outbox…")
- [x] The same application code works against a broker without them, through the outbox, with no source change — `outbox_test` "path choice: one call site takes the broker or the outbox path by configuration alone"
- [ ] A rolled-back transaction leaves no message readable by a consumer in `read_committed` mode — open: needs a real Kafka broker
- [x] The choice of path is observable — a metric and a log line name which one ran, so an operator can tell which guarantee is in force — `outbox_test` "path choice: broker transactions skip the outbox, otherwise the outbox is used, and each is counted and logged"

## Examples

- [`examples/outbox-example.bp`](./examples/outbox-example.bp) — the order service the *Problem*
  section opens with, written correctly: one transaction covering the write and the intent to publish,
  and a consumer that processes a duplicate delivery once.
- [`examples/saga-example.bp`](./examples/saga-example.bp) — a three-step booking saga with
  compensations, what happens when step three fails, and what "parked" looks like when a compensation
  cannot be completed.

## Language gaps

Both rows below belong in [`../../language-gaps.md`](../../language-gaps.md). The second is already
there; this is the front that needs it. The first is new.

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| A decorator cannot read the body of the declaration it annotates — `@Decl` exposes kind, name, fields, methods, params and annotations, and no statements — so `#[saga]` cannot derive steps from a method body. A saga has to be a value whose steps are function pairs. | `examples/saga-example.bp` — the `Saga(steps: [...])` value, where Spring's shape would be a decorated method | Build the saga as a value and register it; it reads well, but the step order and the compensation pairing are no longer checkable against anything | `decl.body()` or a statement-level comptime view, so `#[saga]` on a method could pair each call with its declared compensation and fail at compile time when one is missing |
| There is no assignment to a `self` field: every record is immutable, so a saga's accumulated context cannot be mutated as it flows through the steps. | `examples/saga-example.bp` — each step takes a context and returns a new one | Thread the context through the return value, which is what the example does | Mutable fields, or a declared `var` field on a record. The workaround is arguably better here, so this is recorded as a limitation rather than a request |

## Test plan

`modules/rakun-tx/test/`, run with `botopink test --target erlang` from `modules/rakun-tx/`, and in
the gate as `zig build test-libs -- --target erlang --lib rakun`.

Almost every assertion in this front is about what happens *after a crash*, which makes the test
design the interesting part. Crashes are simulated by killing the process under test with
`exit(Pid, kill)` at a named point, not by sleeping and hoping: each step's coordinator exposes a
test-only injection point that kills it between two persisted states. That is how "killed between
publish and mark re-publishes on restart" becomes a test rather than a claim.

The database half runs against front 08's test datasource — the embedded store front 08's fold-in
selects under a test profile — so the suite needs no external server. The broker half runs against
front 19's in-process broker double for the ordinary paths; the Kafka producer-transaction path in
step 6 needs a real broker and is skipped with a named reason when one is not configured. A skipped
broker row is reported, never silently passed, because a green cell that tested nothing is worse than
a red one.

This front is erlang-only. The mechanisms here are server-side by definition: a browser has no
transaction to enrol in.

## Definition of done

- [x] `modules/rakun-tx/` exists with its manifest and module tree — `botopink.json`, `root.bp` · `outbox` · `saga` · `twopc`
- [x] `publishAfterCommit` inside a rolled-back transaction publishes nothing, and inside a committed
      one publishes exactly once per relay pass — steps 1 and 2
- [x] Two relays on two nodes never publish the same row — two relay processes on one node (step 2, 03r-x)
- [x] A duplicated delivery runs its handler once — step 3
- [x] A saga compensates in reverse, resumes after a coordinator crash, and parks rather than
      abandoning a failed compensation — step 4
- [x] The 2PC decision is durable before any participant hears it, and boot recovery carries out or
      aborts every logged transaction — step 5
- [ ] Broker-native transactions are used where available, through the same API, and which path ran is
      observable — the same API and the observability hold; no broker offers transactions yet (step 6)
- [x] `repository/rakun/AGENTS.md` records the boundary with front 08: one resource is front 08, more
      than one is here — § Distributed transactions
- [x] The front's tests are green on its assigned target — rakun-tx 32/0 on erlang


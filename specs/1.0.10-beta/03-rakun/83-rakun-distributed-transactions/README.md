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
| `modules/rakun-tx/` | does not exist — this front creates it |
| `#[transactional]` | front 08 delivers it; it does not exist today either (`src/decorators.bp` has fifteen decorators and none of them is it) |
| A publisher | front 15 delivers it |
| Any outbox, saga, dedupe store or decision log | nothing, in rakun or in std |
| Migrations for the tables these need | front 77 |
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
- [ ] A message enrolled inside a transaction that commits appears in the outbox exactly once
- [ ] A message enrolled inside a transaction that rolls back appears nowhere
- [ ] `publishAfterCommit` outside a transaction fails with a message naming the method, and publishes nothing
- [ ] Two messages for one aggregate carry increasing `seq`
- [ ] The payload round-trips a value containing a quote, a newline and a four-byte UTF-8 character

### Step 2 — The relay

**Acceptance:**
- [ ] A pending row is published and marked sent
- [ ] Two relays on two nodes never publish the same row — asserted with `SKIP LOCKED` under a concurrent run
- [ ] A relay killed between publish and mark re-publishes on restart: the row is still pending, and the duplicate is the documented at-least-once behaviour
- [ ] Messages for one aggregate are published in `seq` order under concurrency
- [ ] A publish that fails is retried with backoff and does not block other aggregates
- [ ] A row that exceeds its retry ceiling moves to `failed` with its last error, and the relay continues
- [ ] Sent rows are pruned after a configured retention, and the prune is bounded per tick

### Step 3 — The inbox and effectively-once consumption

**Acceptance:**
- [ ] A message delivered twice runs its handler once
- [ ] A handler that raises rolls back its writes *and* the inbox row, and the redelivery runs it again
- [ ] Two consumer groups each process the same message once, independently
- [ ] The inbox is pruned after a retention that is longer than the broker's own redelivery window, and the front states the relationship rather than leaving an operator to discover it
- [ ] A duplicate is acked, not left to redeliver forever

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
- [ ] A three-step saga where every step succeeds ends `completed`, with three forward entries and no compensation
- [ ] A failure at step 3 compensates 2 then 1, in that order, and ends `compensated`
- [ ] A failure at step 1 compensates nothing and ends `compensated`
- [ ] A coordinator killed between steps 2 and 3 resumes at step 3 after restart
- [ ] A compensation that fails is retried to the configured ceiling and then parks in `needs_attention` with the full history — it never ends `completed` and never stops being visible
- [ ] Two sagas of the same definition run concurrently without sharing state
- [ ] The persisted history is readable through `sagaState` for an operator, including the failure reason

### Step 5 — Two-phase commit

**Acceptance:**
- [ ] Two participants that both prepare successfully both commit
- [ ] A participant that refuses prepare causes every participant to abort
- [ ] The decision is durable before any participant is told it — asserted by killing the coordinator between the log write and the first commit message, and observing a commit after recovery
- [ ] A coordinator killed *before* the decision is logged aborts on recovery
- [ ] A participant that does not acknowledge is retried until it does, and the transaction is not considered finished before then
- [ ] The README states the blocking window, and the front's own defaults prefer the outbox

### Step 6 — Broker-native transactions

**Acceptance:**
- [ ] With a Kafka broker configured for producer transactions, a publish enrolled in a transaction goes through the broker's transaction and writes no outbox row
- [ ] The same application code works against a broker without them, through the outbox, with no source change
- [ ] A rolled-back transaction leaves no message readable by a consumer in `read_committed` mode
- [ ] The choice of path is observable — a metric and a log line name which one ran, so an operator can tell which guarantee is in force

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

- [ ] `modules/rakun-tx/` exists with its manifest and module tree
- [ ] `publishAfterCommit` inside a rolled-back transaction publishes nothing, and inside a committed
      one publishes exactly once per relay pass
- [ ] Two relays on two nodes never publish the same row
- [ ] A duplicated delivery runs its handler once
- [ ] A saga compensates in reverse, resumes after a coordinator crash, and parks rather than
      abandoning a failed compensation
- [ ] The 2PC decision is durable before any participant hears it, and boot recovery carries out or
      aborts every logged transaction
- [ ] Broker-native transactions are used where available, through the same API, and which path ran is
      observable
- [ ] `repository/rakun/AGENTS.md` records the boundary with front 08: one resource is front 08, more
      than one is here
- [ ] The front's tests are green on its assigned target


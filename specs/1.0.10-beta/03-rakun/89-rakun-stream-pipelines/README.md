# Front 89 — Rakun Stream Pipelines

**Track:** B rakun
**Priority:** low — real work, but an application that never builds a processing topology never misses it; front 15 and front 86 already cover consume-one-message-and-handle-it
**Target:** erlang (server)
**Wave:** 6
**Depends on:** 15 (the broker arms a source and a sink are built from), 86 (per-stage retry and the dead-letter path), 11 (hosts the graph endpoint), 08 (the durable state and metadata store arm), 05 (poller and topology configuration), 01/std `io.clock`
**Owns:** `modules/rakun-stream/src/**`, `modules/rakun-stream/test/**`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` — frozen for the milestone. `modules/rakun-messaging/**` belongs to fronts 15, 86, 90 and 91 and is read-only here.
**Reference:** `06-messaging.md § Spring Integration` (Configuracao, RSocket com Integration) · `§ Apache Kafka · Kafka Streams` · `09-actuator.md § Endpoints` (`integrationgraph`) · https://docs.spring.io/spring-boot/reference/messaging/spring-integration.html · https://docs.spring.io/spring-boot/reference/messaging/kafka.html#messaging.kafka.streams

---

## Problem

Front 15 delivers a listener: one message arrives, one handler runs. That covers most messaging and
it does not cover a topology. Two shapes upstream need something else, and Spring answers them with
two separate subsystems.

Spring Integration is channels, pollers and enterprise integration patterns — a message enters, is
transformed, filtered, split, aggregated and routed through a graph of stages, each with its own
concurrency, and the whole graph is visible at `/actuator/integrationgraph`
(`06-messaging.md § Spring Integration`). Kafka Streams is a topology over topics with keyed state
stores and windowing, declared as a `KStream` built from a `StreamsBuilder`
(`06-messaging.md § Kafka Streams`). Written as two front-ends they look unrelated. Written as
mechanisms they are the same thing: a directed graph of stages, exchanging demand rather than pushing
into unbounded buffers, with some stages keeping state.

Nothing in the milestone builds either. Today a rakun application that needs a pipeline writes a
listener whose handler calls the next listener's publish, which is a topology with no back-pressure,
no shared state and no way to see its own shape. When the producer outruns the slowest stage, the
failure is an unbounded process mailbox and a node that dies of memory pressure — a failure mode with
no error message.

## Current state

- `repository/rakun/modules/` holds no `rakun-stream`. The directory this front owns does not exist
  yet.
- `repository/rakun/modules/rakun-messaging/src/root.bp` — a stub; fronts 15 and 86 fill it, and this
  front consumes their source and sink arms rather than dialling a broker of its own.
- `repository/rakun/src/runtime.bp:19-117` — no process-topology surface of any kind. The only
  supervision rakun has today is whatever `rkServe` sets up for the listener.
- `libs/std/src/time.bp:56,80` — `time.nowMillis()` and `time.monotonicMillis()` exist today (`clock.nowMillis`/`clock.monotonicMillis` under `io.clock`, decision 106); windowing
  uses the first for event time and the second for poller intervals.

## Mechanism

**GenStage is the answer to both, which is why this is one front and not two.** A GenStage stage is a
process that asks the stage upstream for N events and receives at most N. Demand flows backwards,
events flow forwards, and no stage can be handed more work than it asked for. That is exactly
Spring Integration's channel with a poller in front of it, and exactly what a Kafka Streams topology
needs between its sub-topologies. Broadway is the supervised, batching, acknowledging layer usually
put on top; this front implements the same shape directly over front 15's consumer arms rather than
depending on an Elixir library, and it names Broadway in the module README so the lineage is visible.

**A pipeline is a value, and the stage vocabulary is an enum.**

```
Pipeline(name, source, stages, sink)
```

| Stage | Spring Integration name | Shape |
|---|---|---|
| `Transform(name, apply)` | transformer | one in, one out |
| `Filter(name, keep)` | filter | one in, zero or one out |
| `Split(name, explode)` | splitter | one in, many out |
| `Aggregate(name, key, windowMs)` | aggregator | many in, one out per key per window |
| `Route(name, pick)` | router | one in, one out, to a named branch |

Each stage is a process at run time and a value at compile time, and that split is what makes the
vocabulary testable: `runStages(stages, items)` applies the same stage list to a list of strings in
one process, with no broker and no supervision, and returns what the pipeline would have produced.
A pipeline whose stages are only exercised through a live broker is a pipeline nobody unit-tests.

**Payloads are strings.** Every stage is `fn(string) -> …`, and a structured payload is carried as
its serialized form. This is not laziness: a heterogeneous typed pipeline needs a stage's output type
to thread into the next stage's input type through a generic composition, and labelled tuples lose
their labels when a generic is instantiated (ground truth §2.39), so `#(key: string, count: i32)`
handed across a `Stage<T>` boundary is readable only positionally. The front takes the honest option —
one payload type, conversion at the edges — and records the gap below.

**Pollers resume where they stopped.** `Source.Poll(everyMs, cursor)` reads a cursor from the
metadata store, fetches, processes, and writes the new cursor back *after* the sink confirms.
`spring.integration.poller.fixed-delay` is the interval; `spring.integration.jdbc.initialize-schema`
becomes a front 77 migration rather than a boot-time DDL, for the same reason front 87's audit table
is a migration.

**Keyed state is the only thing that separates a Kafka Streams topology from an EIP pipeline.**
`StateStore` is a behavior with `lookup(key) -> ?string`, `put(key, value)` and `fold`. Two arms: ETS
for a topology whose state can be rebuilt, SQL for one whose state cannot. State is partitioned by
the same key the consumer group partitions by, so a rebalance that moves partition 3 to another node
moves the keys of partition 3 with it — the new owner reads them back from the store rather than
starting empty. A topology using the ETS arm across a rebalance loses state and says so at boot,
rather than quietly producing wrong counts.

**Windows are arithmetic.** `windowStart(atMs, windowMs)` truncates an event timestamp to its window;
`windowKey(key, start)` is the state-store key. Tumbling windows fall out directly; a sliding window
is N tumbling windows written per event. A window is emitted when the watermark — the highest event
time seen, minus the configured lateness allowance — passes its end. Late events after that are
routed to the pipeline's late branch rather than dropped, because silently dropping late data is the
defect that makes stream results untrustworthy.

**Failure is per-stage.** A stage that raises is restarted by its supervisor; the event that caused
it goes through front 86's retry and dead-letter policy, with the stage name in the dead-letter
envelope. Without that, a poison event in stage four of six restarts the whole pipeline forever,
which is the same supervision-succeeds-application-fails loop front 86 exists to break.

**The graph endpoint is a projection of the value.** `graphOf(pipeline)` returns the edge list, and
front 11 renders every registered pipeline's edges at `/actuator/integrationgraph`. Because the
pipeline is a value, the graph is exact rather than reconstructed — there is no possibility of the
documentation disagreeing with the topology.

**Target.** Stages are BEAM processes and every line runs on the server. The host cells are
`#[@External.Erlang]` over `gen_stage`-shaped process code and `ets`; there is no `@External.Node`
cell in this front.

## Steps

### Step 1 — The pipeline value and the stage vocabulary

```bp
pub type Stage {
    Transform(name: string, apply: fn(item: string) -> string),
    Filter(name: string, keep: fn(item: string) -> bool),
    Split(name: string, explode: fn(item: string) -> Array<string>),
    Aggregate(name: string, key: fn(item: string) -> string, windowMs: i32),
    Route(name: string, pick: fn(item: string) -> string),
}

pub fn runStages(stages: Array<Stage>, items: Array<string>) -> Array<string>
```

**Acceptance:**
- [ ] `runStages([], items)` returns `items` unchanged.
- [ ] A `Filter` that keeps nothing produces an empty array and does not raise.
- [ ] A `Split` producing three items feeds three items to the next stage, asserted by a following `Transform` that counts.
- [ ] Stage order matters: filter-then-transform and transform-then-filter over the same input produce different results, and both are asserted.
- [ ] Every stage carries a name, and two stages with the same name in one pipeline fail at registration.

### Step 2 — Sources, sinks and demand

```bp
pub type Source {
    Queue(destination: string, prefetch: i32),
    Topic(name: string, group: string),
    Poll(everyMs: i32, cursor: string),
}

pub type Sink {
    Publish(destination: string),
    Collect(name: string),
}
```

**Acceptance:**
- [ ] A source never delivers more than the demand the first stage asked for — asserted by a slow stage and a fast source, measuring the queue depth rather than the wall clock.
- [ ] Killing a middle stage does not lose the events already accepted downstream of it.
- [ ] `Sink.Collect` accumulates into a named store for tests, so a pipeline is assertable end to end without a broker.
- [ ] Back-pressure reaches the broker: with `Queue(prefetch: 1)` and a blocked pipeline, the second message is not fetched.

### Step 3 — Pollers and the metadata store

**Acceptance:**
- [ ] The cursor is written after the sink confirms, never before; a test that fails the sink asserts the cursor did not move.
- [ ] Restarting the poller resumes from the stored cursor rather than from the beginning.
- [ ] Two nodes running the same poller do not both fetch — the cursor row is the lease.
- [ ] `everyMs` is honoured as a fixed *delay* after completion, matching `spring.integration.poller.fixed-delay`, and the README says so rather than leaving fixed-rate ambiguity.

### Step 4 — Keyed state

```bp
pub behavior StateStore {
    fn lookup(self: Self, key: string) -> ?string;
    fn put(self: Self, key: string, value: string) -> i32;
    fn fold(self: Self, prefix: string, init: string, step: fn(acc: string, value: string) -> string) -> string;
}
```

**Acceptance:**
- [ ] A key written by one stage is readable by the same stage after a restart when the SQL arm is used, and is empty with the ETS arm — both asserted, so the trade is visible.
- [ ] Choosing the ETS arm logs one line at boot naming what is lost on a rebalance.
- [ ] `lookup` returns `null` for an absent key, matched as `case v { null { … } s { … } }` and never as a sentinel string.
- [ ] State keys are prefixed per pipeline, so two topologies cannot collide on `"count"`.

### Step 5 — Windows

```bp
pub fn windowStart(atMs: i64, windowMs: i32) -> i64
pub fn windowKey(key: string, start: i64) -> string
```

**Acceptance:**
- [ ] `windowStart` is exact at a boundary: an event at exactly `start + windowMs` belongs to the next window.
- [ ] Two events in the same window produce one emission with the combined aggregate; two events across a boundary produce two.
- [ ] A late event arriving within the lateness allowance updates its window's emission; one arriving after it goes to the late branch and is counted.
- [ ] A sliding window of width W and step S writes each event into exactly `W / S` windows.

### Step 6 — Rebalance and restart

**Acceptance:**
- [ ] A partition moving between nodes carries its keys: the new owner's first aggregate for an existing key continues the count rather than restarting it (SQL arm).
- [ ] A stage crash restarts that stage only; the supervisor tree is asserted by process count, not by absence of an error.
- [ ] A poison event exits through front 86's dead-letter path with the stage name in the envelope, and the pipeline keeps running.

### Step 7 — The graph endpoint

```bp
pub fn graphOf(pipeline: Pipeline) -> Array<#(string, string)>
```

**Acceptance:**
- [ ] The edge list is `source → stage1 → … → sink` with one edge per adjacent pair, in order.
- [ ] A registered pipeline appears at `/actuator/integrationgraph`, and is absent unless front 76's exposure list names the endpoint.
- [ ] Adding a stage changes the rendered graph with no other edit — the graph is derived, not maintained.

## Examples

- [`examples/order-pipeline-example.bp`](./examples/order-pipeline-example.bp) — the EIP case: a
  queue source, filter, transform, split and a publish sink, with the whole stage list exercised
  through `runStages` and no broker in sight.
- [`examples/windowed-counts-example.bp`](./examples/windowed-counts-example.bp) — the Kafka Streams
  case: keyed counts in a tumbling window, the window arithmetic, and the state-store keys.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| Tuple labels are lost through generic instantiation (`hooks.bp:75-77`, ground truth §2.39), so a stage cannot hand the next stage a labelled `#(key: …, count: …)` and have it read by name. A typed, heterogeneous pipeline needs exactly that. | `examples/windowed-counts-example.bp`, the aggregate step | Carry one payload type — a string — and read any pair positionally (`pair.0`, `pair.1`) at the edges. | Preserve labels through generic instantiation |
| Declared parameter defaults are never applied, so a stage constructor cannot offer an optional name or an optional window. | `examples/order-pipeline-example.bp`, every stage constructor | Pass every argument; a stage name is always written. | Apply declared defaults at call sites (`docs.md:502-505`) |

## Test plan

`modules/rakun-stream/test/` on the **erlang** target, invoked as
`zig build test-libs -- --target erlang --lib rakun` from `repository/botopink-lang/`, and as
`botopink test --target erlang` from `repository/rakun/`.

| File | Asserts |
|---|---|
| `test/stages_test.bp` | The five stage kinds, order sensitivity, empty results, duplicate-name rejection |
| `test/demand_test.bp` | Demand never exceeded, prefetch reaching the broker, no loss on a mid-stage kill |
| `test/poller_test.bp` | Cursor-after-confirm, resume, the two-node lease, fixed-delay semantics |
| `test/state_test.bp` | Both arms across a restart, the ETS warning, `?string` absence, per-pipeline prefixes |
| `test/window_test.bp` | Boundary exactness, one emission per window, late handling, sliding fan-out |
| `test/graph_test.bp` | Edge list shape, endpoint exposure, derivation from the value |

Steps 1, 5 and 7 are pure and always run. Steps 2, 3, 4 and 6 need a broker or a database and run
when `RAKUN_TEST_KAFKA_BROKERS`, `RAKUN_TEST_AMQP_URL` or `RAKUN_TEST_DATABASE_URL` is set, reporting
a *skipped* cell otherwise.

There is no commonJS row. This front is server-only by the milestone's target split.

## Definition of done

- `modules/rakun-stream/` exists, is declared from its `root.bp`, and holds no `@External.Node` cell.
- One abstraction covers both the Spring Integration and the Kafka Streams cases, and the module README says which upstream feature each stage answers.
- Back-pressure is demonstrated, not claimed: a test measures that a slow stage bounds a fast source.
- Late events are routed and counted, never dropped.
- The `integrationgraph` payload is derived from the pipeline value in the same process that runs it.
- Both language gaps above appear as `// LANGUAGE GAP:` markers in the examples and in a `specs/1.0.10-beta/` spec.
- `repository/rakun/AGENTS.md` and `modules/README.md` record the module in the same commit.
- The front's tests are green on erlang.


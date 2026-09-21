# Front 75 — rakun Observability: Metrics and Tracing Export

**Track:** B rakun
**Priority:** high — front 11 exposes a metrics endpoint and nothing exports to a scraper or a collector, so in production the numbers exist and nobody can see them; a metric that is only readable by `curl` on the box is not observability
**Target:** erlang (server)
**Wave:** 4
**Depends on:** 11 · 13 · 74 — and it reads front 17's correlation field without owning it
**Owns:** `modules/rakun-metrics/botopink.json`, `modules/rakun-metrics/src/**`, `modules/rakun-metrics/test/**`, `modules/rakun-metrics/src/sidecars/rakun_metrics.erl`
**Does not touch:** `modules/rakun-actuator/src/**` — front 11 owns the endpoint infrastructure and front 76 owns its exposure; `modules/rakun-logging/src/**` — front 17 owns logs; `modules/rakun-web/src/middleware.bp` — this front registers a filter into front 07's chain, it does not edit the chain
**Reference:** `09-actuator.md § Metrics` (Micrometer, Prometheus, Customizando, Tags Comuns via Properties, Per-Meter, Metricas Automaticas, Registrando Metricas Customizadas, MeterFilter, Endpoint Metrics), `§ JMX`, `§ Endpoints (prometheus, threaddump, heapdump)` · `02-desenvolvendo-com-spring-boot.md § DevTools (management.tracing.sampling.probability)` · <https://docs.spring.io/spring-boot/reference/actuator/metrics.html> · <https://docs.spring.io/spring-boot/reference/actuator/tracing.html>
**Replaces:** new — no front in `1.0.6-beta` proposed it

---

## Problem

Front 11 gives `/actuator/metrics` — a list of names and a value per name, read one at a time over
HTTP. That is Spring's `metrics` endpoint, and Spring is explicit that it is a debugging convenience,
not a monitoring system (`09 § Endpoint Metrics`). The monitoring system is the exporter: Micrometer
ships bindings for eighteen backends (`09 § Micrometer`) and the one that matters here is the
Prometheus scrape endpoint, because it is what turns a number into a graph and an alert.

Nothing in the milestone exports anything. There is also no registry with a real meter model — a
counter that only goes up, a gauge that is sampled, a timer that keeps a distribution, a summary — so
even the numbers front 11 can show are ad-hoc. And there is no tracing at all: a request that fans out
to three services produces four unrelated log files.

The BEAM-specific half is the part most easily got wrong. Spring's automatic instrumentation includes
JVM metrics — heap, GC, threads, classes, JIT (`09 § Metricas Automaticas`) — and none of those five
means anything here. The numbers that matter on the BEAM are different ones: run-queue length, process
count, memory by allocator, message-queue depth. Porting the JVM list verbatim would produce a
dashboard full of zeros and would leave out everything an operator actually pages on.

## Current state

| Piece | Where it is today |
|---|---|
| `rakun-metrics` module | does not exist |
| Metrics endpoint | front 11, `modules/rakun-actuator/src/**` — names and values, no registry model |
| HTTP request timing | front 11 ships `http.server.requests` per `1.0.6-beta` F07 step 5; it has nowhere to send it |
| Any exporter | none |
| Any tracing | none — no context propagation, no span, no sampler |
| `:telemetry` | not a dependency, and not in OTP |
| Erlang VM statistics | available in OTP (`erlang:memory/0`, `erlang:statistics/1`, `erlang:process_info/2`) and unused |
| HTTP client for pushing to a collector | front 13 |
| TLS for that client | front 74 |

## Mechanism

### The registry

Four meter kinds, which is Micrometer's set minus the ones that are compositions of them.

| Kind | Storage | Read |
|---|---|---|
| Counter | `ets:update_counter/3` on a named, tagged key | monotonic total |
| Gauge | a zero-argument closure, evaluated at scrape time | current value |
| Timer | count, total, max, plus a fixed bucket array | count, sum, max, quantiles, buckets |
| Distribution summary | the same as a timer without the time unit | same |

A meter's identity is its name plus its tag set, and the tag set is order-independent: `{method=GET,
status=200}` and `{status=200, method=GET}` are one meter. The registry sorts tags on registration so
that a mis-ordered tag list does not silently double a series — a class of bug that is invisible until
a dashboard's total is twice the truth.

Counters live in ETS and are incremented with `ets:update_counter/3`, which is an atomic operation
performed by the calling process with no message round trip. That is the only storage that is honest in
a hot path: a `gen_server` counter would serialise every request in the system through one mailbox.

Gauges are the opposite — a closure evaluated when the exporter asks, never on the hot path, because a
gauge measures a thing that already exists (`queue.size()`, the pool's idle count) and sampling it on
demand is both cheaper and more correct than pushing it.

### The instrumentation bus

Every subsystem needs to report, and none of them should depend on this module. The BEAM ecosystem's
answer is `:telemetry`: a subsystem executes an event, handlers subscribe. That shape is right and the
library is not available — `telemetry` is a hex package, not OTP, and front 04 established what happens
to a sidecar that calls a module the gate does not install: it compiles and dies at run time with
`undefined function`.

So `rakun_metrics` ships `rakun_telemetry`, an ETS-backed handler table with the same three functions
(`attach/4`, `detach/1`, `execute/3`) and the same event-name-as-a-list convention, and it delegates to
`telemetry` when `code:ensure_loaded(telemetry)` succeeds. A handler written against `:telemetry`
transliterates; a deployment that already has the real library gets it. This is the same adapter shape
front 04 used for cowboy, and for the same reason.

Events are named `[rakun, <subsystem>, <operation>, start | stop | exception]`, which is the ecosystem
convention, so a `telemetry_metrics`-style consumer written elsewhere works unchanged.

### Automatic instrumentation, and who ships it

Each owning front emits the event; this front subscribes and turns it into meters. That split is the
whole reason the bus exists — front 08 does not import `rakun-metrics`, it executes an event.

| Meter | Event | Emitted by |
|---|---|---|
| `http.server.requests` (timer; tags method, route, status) | `[rakun, http, request, stop]` | front 04's dispatcher |
| `http.client.requests` (timer; tags method, host, status) | `[rakun, client, request, stop]` | front 13 |
| `sql.connections.*`, `sql.query` (gauge, timer) | `[rakun, sql, query, stop]`, pool gauges | front 08 |
| `cache.gets`, `cache.puts`, `cache.evictions` (counters; tag `result`) | `[rakun, cache, get, stop]` | front 12 |
| `scheduled.tasks` (timer; tag task) | `[rakun, scheduled, run, stop]` | front 16 |
| `messaging.consumed`, `messaging.published` (counters) | `[rakun, messaging, *, stop]` | front 15 |
| `application.started.time`, `application.ready.time` (gauges) | `[rakun, application, ready]` | front 04 |

A front that has not landed yet simply produces no series, and the exporter emits nothing for it. There
is no placeholder meter reporting zero, because a zero is a claim.

### BEAM VM metrics, in place of JVM metrics

This is a substitution, not a port. The names follow Micrometer's `<area>.<thing>` convention so a
dashboard reads the same way.

| Meter | Source | Why an operator cares |
|---|---|---|
| `beam.schedulers.run_queue` | `erlang:statistics(run_queue)` and `total_run_queue_lengths` | The single best saturation signal the VM has |
| `beam.schedulers.utilization` | `erlang:statistics(scheduler_wall_time)`, sampled as a delta | Distinguishes "busy" from "blocked" |
| `beam.processes.count` / `.limit` | `erlang:system_info(process_count / process_limit)` | Approaching the limit is a hard stop, not a slowdown |
| `beam.ports.count` / `.limit` | `erlang:system_info(port_count / port_limit)` | Sockets and files share this budget |
| `beam.memory.<area>` | `erlang:memory/0` — total, processes, atom, binary, ets, code | Binary and ETS growth are the two leaks that happen |
| `beam.atoms.count` / `.limit` | `erlang:system_info(atom_count / atom_limit)` | Atom exhaustion kills the node and is always a bug |
| `beam.gc.count`, `beam.gc.words_reclaimed` | `erlang:statistics(garbage_collection)` | The BEAM's GC is per-process; the aggregate is still the trend |
| `beam.messages.queue_max` | max `message_queue_len` over processes, sampled | A growing mailbox is the BEAM's version of a thread pool backing up |

`scheduler_wall_time` is off by default in the VM and enabling it costs a little; the exporter turns it
on only when `rakun.metrics.beam.scheduler-utilization=true`, and says in the documentation that it is
not free.

### Exporters

| Exporter | Shape | Property |
|---|---|---|
| Prometheus | a scrape endpoint rendering the text exposition format, served by front 11 at `/actuator/prometheus` and gated by front 76 | `rakun.metrics.export.prometheus.enabled` |
| OTLP | HTTP/protobuf push to a collector on an interval, through front 13's client and front 74's bundle | `rakun.metrics.export.otlp.endpoint`, `.step` |
| StatsD | UDP datagrams, fire and forget | `rakun.metrics.export.statsd.host`, `.port` |

Prometheus first because it is pull-based: it needs no outbound connectivity, no credential and no
retry policy, so it works in the environment where everything else is still being set up. OTLP second
because it is where the ecosystem is going and because it carries traces on the same wire. StatsD third
because it is forty lines.

The text exposition format is rendered in Erlang, not in botopink, for one reason: it iterates every
series on every scrape and that is a tight loop over ETS.

### Common tags, filters and per-meter configuration

- Common tags: every property under `rakun.metrics.tags.*` becomes a tag on every meter
  (`09 § Tags Comuns via Properties`). Resolved once at boot.
- Filters: `rakun.metrics.enable.<prefix>=false` denies a name prefix;
  `rakun.metrics.rename.<from>=<to>` renames a tag key; both are `MeterFilter`'s two useful cases
  (`09 § MeterFilter`) expressed as properties, because a filter written as a bean would have to be
  resolved before the registry it filters.
- Distribution: `rakun.metrics.distribution.percentiles-histogram.<name>=true` and
  `rakun.metrics.distribution.slo.<name>=100ms,200ms,500ms,1s` (`09 § Per-Meter`). SLO buckets are
  cumulative, which is what Prometheus's `le` label means, and this front's test asserts the
  cumulative property rather than trusting it.

A denied meter is not registered at all, so its instrumentation costs a table lookup and not a write.

### Diagnostics in place of `threaddump` and `heapdump`

Both endpoints exist upstream (`09 § Endpoints`) and neither has a BEAM meaning. The replacements are
strictly more useful and this front ships both as front 11 endpoint contributions:

- `/actuator/processes` — the top N processes by reductions, memory or message-queue length, each with
  its registered name, initial call, current function and stack depth, from `erlang:process_info/2`.
  Where a thread dump gives you a frozen stack, this gives you which process is *spending* the node.
- `/actuator/vm` — `erlang:memory/0` broken down by area plus the allocator summary. A live number,
  not a multi-gigabyte file.

There is no `heapdump` equivalent and this front does not invent one. The BEAM's crash dump is written
by the VM on the way down, and retrieving it is a deployment concern (front 81), not an endpoint.

Both are `unrestricted`-class endpoints in front 76's model: they name internal functions and module
names, so they are default-denied like everything else.

### JMX

`09 § JMX` exposes endpoints over a JVM management protocol. The BEAM's equivalent is not a protocol to
implement, it is a capability that already exists: a distributed node accepts a remote shell, and
`observer`, `recon` and `etop` run against it. This front's contribution is to make that reachable
rather than to reimplement it — `rakun_metrics:snapshot/0` returns the whole registry as a term for a
remote shell, and the module's README documents `erl -remsh` with the cookie handling. No JMX property
is ported and no `jmx.exposure.include` exists.

### Tracing

Front 17 keeps logs; this front owns the ids that make them correlatable and the export of spans.

- **Propagation.** W3C Trace Context: `traceparent` in, `traceparent` out.
  `rakun-metrics` ships a filter that front 07's chain registers, which parses the incoming header,
  or mints a new trace id when there is none, and stores the trace id, span id and sampled flag in the
  request process's dictionary — per-process on the BEAM is per-request, so no context object has to be
  threaded through anything.
- **Sampling.** `rakun.tracing.sampling.probability` (default 0.1, matching the reference's value). The
  decision is made once per trace, at the edge, and carried in the `sampled` flag — a downstream
  service never re-decides, which is what makes a distributed trace complete rather than dotted.
- **Spans.** A span per inbound request and a span per outbound client call, the two boundaries where a
  span is free because the timing is already measured for `http.server.requests` and
  `http.client.requests`. There is no per-method span, because there is no way to wrap a method body —
  see front 12's language gap, which is the same one.
- **Export.** OTLP, over the same client and the same interval as metrics.
- **Correlation.** The trace id and span id are readable through `traceId()` / `spanId()`, which front
  17 puts in the log line. This front never formats a log line.

The tracing surface, in full:

```bp
pub fn traceId() -> string;        // 32 hex characters; "" outside a request
pub fn spanId() -> string;         // 16 hex characters
pub fn parentSpanId() -> string;   // "" when this span is the root
pub fn sampled() -> bool;
pub fn traceparent() -> string;    // the header to send onward
pub fn adoptTraceparent(header: string) -> bool;   // used by the filter and by tests
pub fn startSpan(name: string) -> string;          // returns the new span id
pub fn endSpan(span: string) -> i32;
pub fn exportedSpanCount() -> i32;                 // test and diagnostics only
```

`adoptTraceparent` is public rather than internal for one reason: `Request` is a `behavior` and no test
can construct one ([`language-gaps.md`](../../language-gaps.md), *Unowned surface*), so a test that cannot
set the incoming header directly cannot test propagation at all.

## Steps

### Step 1 — the module and the registry

`modules/rakun-metrics/` with its manifest, `src/root.bp`, the meter model and the ETS storage.

```bp
pub type Tag(key: string, value: string)

// The injectable handle. A `#[component]`, so a field of this type is wired by
// the container like any other dependency — the analogue of Spring injecting a
// `MeterRegistry` into a constructor.
pub type MeterRegistry(name: string)

pub type Counter(name: string, tagKey: string) {
    pub fn increment(self: Self, delta: i32) -> i32;
    pub fn count(self: Self) -> i32;
}

pub type Timer(name: string, tagKey: string) {
    pub fn record(self: Self, micros: i32) -> i32;
    pub fn count(self: Self) -> i32;
    pub fn totalMicros(self: Self) -> i32;
    pub fn maxMicros(self: Self) -> i32;
}

pub fn counter(name: string, tags: Tag[]) -> Counter;
pub fn gauge(name: string, tags: Tag[], read: fn() -> i32) -> i32;
pub fn timer(name: string, tags: Tag[]) -> Timer;
pub fn summary(name: string, tags: Tag[]) -> Timer;
pub fn timed<T>(name: string, tags: Tag[], run: fn() -> T) -> T;
pub fn meterNames() -> string[];
pub fn prometheusText() -> string;
```

`Counter` and `Timer` carry the sorted, encoded tag key rather than the tag list: the meter's identity
is resolved once at registration and the handle is a pointer into ETS, so incrementing costs one
`ets:update_counter/3` and no re-sorting. A distribution summary is a timer without the time unit, so
it is the same record and the same storage under a different constructor.

**Acceptance:**
- [ ] Two registrations of the same name and tag set return the same meter, and the second does not reset it
- [ ] Tag order does not create a second series: `[a, b]` and `[b, a]` are one meter
- [ ] A counter incremented from 1000 processes concurrently ends at exactly 1000
- [ ] A gauge's closure is not called during registration, and is called once per scrape
- [ ] `timed` returns the value the closure returned, and records a sample even when the closure raises — the sample is tagged `outcome=error`
- [ ] A meter name containing a character the exposition format cannot carry is rejected at registration, naming the character

### Step 2 — the telemetry bus and the automatic meters

`rakun_telemetry` plus the subscriptions that turn each event into a meter.

**Acceptance:**
- [ ] `execute/3` with no attached handler costs one ETS lookup and does not allocate a message
- [ ] A handler that raises is detached, logged once with the event name, and does not affect the emitting process
- [ ] With the real `telemetry` module loadable, `attach/4` delegates and a handler attached through either path receives the event exactly once
- [ ] `http.server.requests` is recorded with the matched route pattern, not the concrete path — `/api/users/:name`, never `/api/users/ana`, or cardinality is unbounded
- [ ] A subsystem whose front has not landed produces no series at all
- [ ] Every event name is `[rakun, <subsystem>, <operation>, start|stop|exception]`, asserted against the list above

### Step 3 — BEAM VM metrics

**Acceptance:**
- [ ] Every meter in the VM table above is present after boot, with a plausible value
- [ ] `beam.memory.*` areas sum to `beam.memory.total` within the rounding OTP itself reports
- [ ] `beam.schedulers.utilization` is absent unless `rakun.metrics.beam.scheduler-utilization=true`, and enabling it turns on `scheduler_wall_time` exactly once
- [ ] `beam.messages.queue_max` is computed by sampling, and sampling 100k processes does not block the scrape for more than the configured budget
- [ ] No JVM-named meter exists: a test asserts that no registered name begins with `jvm.`

### Step 4 — the Prometheus exporter

**Acceptance:**
- [ ] The rendered text parses as valid exposition format, asserted with a literal expected block for a fixed registry
- [ ] A counter renders as `_total` with type `counter`; a gauge as `gauge`; a timer as `_seconds_count`, `_seconds_sum` and `_seconds_bucket` with type `histogram`
- [ ] Histogram buckets are cumulative and the last bucket is `+Inf` with the total count
- [ ] Tag values containing `"`, `\` or a newline are escaped per the format
- [ ] Scraping twice in a row produces identical output for counters and identical-or-advanced output for gauges
- [ ] The endpoint is registered with front 11 and is default-denied by front 76 until exposed

### Step 5 — OTLP and StatsD

**Acceptance:**
- [ ] OTLP export uses front 13's client and front 74's bundle when the endpoint is `https`
- [ ] A collector that is unreachable causes one logged failure per interval, not per meter, and does not accumulate unbounded memory
- [ ] `step` controls the interval, and setting it to zero disables the push without disabling the registry
- [ ] StatsD datagrams are fire-and-forget: a closed UDP socket does not raise into the caller
- [ ] Metrics and spans share one OTLP connection

### Step 6 — common tags, filters, distribution

**Acceptance:**
- [ ] `rakun.metrics.tags.region=us-east-1` appears on every series, including the BEAM ones
- [ ] `rakun.metrics.enable.http.client=false` removes those series entirely — they are not registered, not registered-and-hidden
- [ ] A renamed tag key appears renamed in every exporter
- [ ] `slo=100ms,200ms,500ms,1s` produces four buckets plus `+Inf`, in ascending order, whatever order the property listed them in
- [ ] An SLO value the duration parser does not understand fails at boot naming the property and the value
- [ ] A common tag whose key collides with a meter's own tag is a boot failure, not a silent overwrite

### Step 7 — process and VM diagnostics

**Acceptance:**
- [ ] `/actuator/processes?sort=reductions&limit=20` returns twenty rows, each with pid, registered name, initial call, current function, reductions, memory and message-queue length
- [ ] `sort=memory` and `sort=message_queue_len` order by those, and an unknown sort is a 400 naming the accepted values
- [ ] The endpoint does not call `erlang:process_info/1` (the whole-info form) on every process — it asks for the specific keys, because the whole form on a large heap is expensive
- [ ] `/actuator/vm` reports the same totals `erlang:memory/0` does
- [ ] Both endpoints are default-denied and require front 76's explicit exposure

### Step 8 — tracing

**Acceptance:**
- [ ] A request with a valid `traceparent` continues the trace: same trace id, new span id, parent set to the incoming span id
- [ ] A request with a malformed `traceparent` starts a new trace and does not fail the request
- [ ] The sampled flag is honoured: an incoming `00` flag produces no exported span even when the local probability would have sampled it
- [ ] `probability=0` exports nothing and still propagates the header
- [ ] `probability=1` exports exactly one server span per request and one client span per outbound call
- [ ] `traceId()` inside a handler equals the id in the outgoing `traceparent` of a client call made from that handler
- [ ] Front 17's log line carries the same trace id, asserted from this front's test against front 17's formatter

## Examples

- [`examples/custom-metrics-example.bp`](./examples/custom-metrics-example.bp) — a service that
  registers a counter, a gauge and a timer, with common tags and a denied prefix. This is the
  translation of `09 § Registrando Metricas Customizadas`.
- [`examples/traced-request-example.bp`](./examples/traced-request-example.bp) — a controller that
  continues an incoming trace, makes an outbound call on it, and reads the ids back.

## Language gaps

None new — every construct in the examples parses today.

Two rows already in [`language-gaps.md`](../../language-gaps.md) decide this front's shape, and it works
within them rather than restating them:

- *A decorator cannot rewrite the body it annotates* (recorded against fronts 06/07/08/10/12). So there
  is no `#[timed]` and no `#[observed]`. Automatic instrumentation happens at the framework boundary —
  which is where Spring's own does — and explicit instrumentation takes the combinator form
  `timed(name, tags, { -> … })`, which is also how `09 § Registrando Metricas Customizadas` writes it.
- *A `Request` test double does not exist* (*Unowned surface*). It is why `adoptTraceparent` is part of
  the public surface: without it the propagation rules are untestable.

## Test plan

`modules/rakun-metrics/test/*_test.bp`, run with `botopink test --target erlang` from
`repository/rakun/modules/rakun-metrics/` and in the gate as
`zig build test-libs -- --target erlang --lib rakun`.

The exposition-format tests compare against literal expected blocks for a registry built by the test
itself, because "renders valid Prometheus" is not falsifiable and "equals this string" is. The VM-metric
tests assert relationships (areas sum to total, counts are within limits) rather than values, because
values are not reproducible. The concurrency test for counters spawns real processes — this is the one
place where the BEAM makes a test cheap that would be flaky anywhere else.

This front is erlang-only. `rakun_telemetry`, the ETS storage and every VM statistic are OTP calls with
no Node form. A commonJS run compiles and fails at the first registration, which is the target split
working as designed.

Sidecar atoms are `rakun_metrics` and `rakun_telemetry`. Neither collides with a module this build
emits, and `telemetry` is deliberately not used as an atom so the optional delegation to the real
library stays unambiguous.

## Definition of done

- A registry with four meter kinds, tag-order-independent identity, and ETS-backed counters
- An instrumentation bus that every other front can emit to without importing this module
- BEAM VM metrics, and no JVM-named meter anywhere
- A Prometheus endpoint whose output is asserted against a literal block
- OTLP and StatsD exporters, sharing one connection with tracing
- W3C trace context propagated, sampled once at the edge, and exported
- `/actuator/processes` and `/actuator/vm` in place of `threaddump` and `heapdump`, both default-denied
- `modules/README.md` and `repository/rakun/AGENTS.md` record the new module in the same commit
- The front's tests are green on its assigned target

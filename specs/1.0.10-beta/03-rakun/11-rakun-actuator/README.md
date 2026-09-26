# Front 11 — Actuator: Health, Info and the Endpoint Host

**Track:** B rakun
**Priority:** medium — an application nobody can ask "are you alive" is an application a load balancer cannot route to and an operator cannot diagnose
**Target:** erlang (server)
**Wave:** 3 (the host) · 1 (the API module)
**Depends on:** none (the API module) · 06 (the host)
**Owns:** `modules/rakun-actuator-api/src/**`, `modules/rakun-actuator-api/test/**` · `modules/rakun-actuator/src/*.bp`, `modules/rakun-actuator/src/sidecars/rakun_actuator.erl`, `modules/rakun-actuator/test/**`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` — frozen · `modules/rakun-actuator/src/exposure.bp`, `access.bp`, `management_listener.bp`, `probes.bp`, `sanitize.bp`, which are front 76's · the metrics registry and exporters, which are front 75's
**Reference:** `09-actuator.md` — Endpoints, Health, Info, Monitoramento HTTP, JMX · `03-recursos-principais.md § Disponibilidade da Aplicacao` · <https://docs.spring.io/spring-boot/reference/actuator/index.html>

---

## Scope, first — because this front was cut in three

"Actuator" is three fronts, and the boundary
is worth stating before the problem statement, because most of what a reader expects here is not here.

| Front | Owns |
|---|---|
| **11 (this one)** | The endpoint host: registration, routing, base path, per-endpoint path, response cache TTL, endpoint CORS. Health aggregation and indicators. Info contributors. The `beans`, `configprops`, `startup`, `shutdown` and `mappings` endpoints. `instrumentation.bp`: the startup hook and the tracing spans the whole server emits |
| **75-rakun-observability-metrics** | The meter registry, tags, filters, exporters (Prometheus, OTLP), BEAM VM metrics, the process and memory diagnostics that replace `threaddump`/`heapdump` |
| **76-rakun-actuator-security-probes** | Exposure (`include`/`exclude`), per-endpoint access levels, the management listener on its own port, value sanitization, health **groups**, and the Kubernetes liveness/readiness probes |

So: front 11 decides *what an endpoint is and how it is reached*; front 76 decides *who may reach it*;
front 75 decides *what the numbers are and where they go*. Front 11 exposes nothing by default beyond
`health` — that default belongs to 76 and this front honours it rather than restating it.

### Two modules, and why the markers land in wave 1

Eight fronts ship a health indicator or an endpoint of their own — 08, 09, 12, 15, 16, 17, 18, 77 and
85 — so every one of them depends on the `#[healthIndicator]` and `#[endpoint]` decorators. Several of
them are in wave 3 alongside the actuator host, which would be a cycle in the wave table.

The decorators and the contract are therefore a **separate, dependency-free module**:

| Module | Wave | Contains | Depended on by |
|---|---|---|---|
| **`modules/rakun-actuator-api`** | 1 | `Health`, `HealthIndicator`, `InfoContributor`, `Endpoint`, `EndpointResponse`, `Span`; the decorators `#[healthIndicator]`, `#[infoContributor]`, `#[endpoint]`, `#[instrumentation]`; the registration cells `rkRegisterHealthIndicator`, `rkRegisterInfoContributor`, `rkRegisterEndpoint`, `startSpan`, `endSpan`; the sidecar that owns the three ETS registries | 08 · 09 · 12 · 15 · 16 · 17 · 18 · 77 · 85 · and the host |
| **`modules/rakun-actuator`** | 3 | the endpoint host and routing, health aggregation, info merging, the `ping` and `diskSpace` indicators, `beans`/`configprops`/`mappings`/`startup`/`shutdown`, the span chain entry | applications; front 75 and front 76 build on it |

Both are owned by this front. The split is mechanical: **a registration is API, a decision is host.**
`rkRegisterHealthIndicator` writes into an ETS table the API module's sidecar owns; the aggregation
rule, the status order, the timeout and the HTTP mapping all live in the host and read that table. A
front shipping an indicator therefore depends on a wave-1 module with no dependencies of its own, and
an application with the API module but no host registers indicators that nothing reads — which is
exactly right, because nothing is exposing them.

The same applies to spans: `startSpan`/`endSpan` are in the API module, so fronts 23, 24 and 25 can
emit without depending on the host, and the `http.server.request` chain entry — a decision about the
request path — stays in the host.

## Problem

A rakun application in production is a black box. There is no way to ask whether it is healthy, what
version it is, which beans it wired, what configuration it resolved, how long it took to start, or
what routes it registered. A Kubernetes deployment has nothing to point a probe at. An operator
debugging a bad deploy has `erl -remsh` and guesswork.

Every one of those questions has an answer already sitting in the runtime — front 04's scan registry
and route table, front 05's binding registry, front 06's bean registry — and no way to read it over
HTTP. Most of this front is not new state; it is a door onto state that exists.

The one genuinely new thing is instrumentation. Nothing in the server emits an event when a request
starts, when a render begins, when an action runs. Without that seam, front 75 has nothing to export
and front 17 has nothing to correlate, and each of them would grow its own hook into the request path.
One seam, here, is the point.

## Current state

| Piece | Where | State |
|---|---|---|
| Scan registry | `rkScannedNames`/`rkScannedCount` (`runtime.bp:22-26`) | exists; `beans` reads it |
| Bean registry | front 06's `rkBeanNames`/`Context` | exists once 06 lands |
| Route table | `rkRoutePaths` (`runtime.bp:86-87`), front 22's file router | exists; `mappings` reads both |
| Configuration binding registry | front 05's `rkRegisterConfigKeys` | exists once 05 lands; `configprops` reads it |
| Chain to register into | front 07, order band +100 reserved for metrics and tracing | exists once 07 lands |
| Health, info, any endpoint | — | none |
| Startup step timing | — | none |
| Tracing spans | — | none |
| `:telemetry` | a third-party OTP library, and also a de-facto convention | see *Where Spring uses JMX* |
| `modules/rakun-actuator/` | — | does not exist |

## Mechanism

### An endpoint is a registration, not a controller

An endpoint written as a `#[restController]` with a `#[getMapping]` cannot work once front 76 exists: the
base path, the per-endpoint path and the management listener are all configuration, and a
`#[getMapping("/health")]` is a compile-time constant. It also means an application could not add an
endpoint without also owning a route prefix.

So an endpoint registers itself and front 11 owns the routing:

```bp
pub behavior Endpoint {
    fn id(self: Self) -> string;
    fn read(self: Self, req: Request) -> EndpointResponse;
}

pub type EndpointResponse(status: i32, contentType: string, body: string)
```

```bp
#[endpoint("health")]
#[managed]
pub type HealthEndpoint(registry: HealthRegistry) implement Endpoint { … }
```

`#[endpoint("health")]` is a type-level decorator emitting
`val __rkEp_HealthEndpoint = rkRegisterEndpoint("health", { req -> __rkMake_HealthEndpoint().read(req) });`.
At boot, front 11 registers **one** route — `<base-path>/:endpoint/:path*` — and dispatches by id.
One route, N endpoints, and the base path is a property (`management.endpoints.web.base-path`, default
`/actuator`) rather than a literal. `management.endpoints.web.path-mapping.health=healthcheck` renames
one endpoint's segment without touching its id.

A response may be cached: `management.endpoint.<id>.cache.time-to-live` (default `0`, no cache) keeps
the last `EndpointResponse` for that long, per endpoint, which matters because a health check that
opens a database connection on every probe is a health check that causes the outage it reports.

Endpoint CORS reuses **front 07's** `CorsPolicy` with its own configured origins
(`management.endpoints.web.cors.allowed-origins`), because a second CORS implementation is a second
place to get it wrong.

### The health-indicator registration contract

This is the contract the audit asked to be defined here, and it is the reason health is front 11's and
the indicators are not.

```bp
pub type Health(
    status: string,        // "UP" | "DOWN" | "OUT_OF_SERVICE" | "UNKNOWN"
    details: string,       // a JSON object string; "{}" when there is nothing to say
)

pub behavior HealthIndicator {
    fn check(self: Self) -> Health;
}
```

**Each owning front ships its own indicator and registers it here.** Front 08 ships `db`, front 09
ships one per configured store, front 12 ships `cache`, front 15 ships the broker indicators, front 18
ships `session`, front 74 ships `ssl`, a mail front ships `mail`. Front 11 ships exactly two — `ping`
(always `UP`) and `diskSpace` — plus the aggregation. Any other list would mean front 11 taking a
dependency on every module in the milestone, which is the opposite of what an actuator is for.

The registration is one decorator, exported from **`rakun-actuator-api`** (wave 1, no dependencies),
so a front shipping an indicator never depends on the host:

```bp
#[healthIndicator("db")]
#[managed]
pub type DataSourceHealth(sql: SqlTemplate) { pub fn check(self: Self) -> Health { … } }
```

emitting `val __rkHi_DataSourceHealth = rkRegisterHealthIndicator("db", { -> __rkMake_DataSourceHealth().check() });`.
The registry lives in the API module's sidecar and the aggregation lives in the host, which is the
whole of the split: a registration is API, a decision is host.

Rules the contract fixes, so that eight fronts do not each decide them:

- **An indicator must not raise.** A raise is caught by the registry and becomes
  `Health(status: "DOWN", details: "{\"error\": \"…\"}")`. A broken indicator degrades one component's
  status; it does not break the health endpoint.
- **An indicator must have a timeout.** `management.health.<id>.timeout` (default 2 s). Past it the
  indicator's answer is `UNKNOWN` and the check is abandoned — a hung database must not hang the probe.
- **Indicators run concurrently.** One BEAM process each, gathered by id. Ten indicators at 2 s each
  take 2 s, not 20.
- **`details` is a JSON object string** and must never contain a credential, a URL with a password, or
  a stack trace. Sanitization is front 76's, but the contract says an indicator does not put a secret
  there in the first place.

Aggregation takes the **worst** status present, ordered by
`management.endpoint.health.status.order` (default `down, out-of-service, unknown, up`), and maps it
to a status code through `management.endpoint.health.status.http-mapping.*` (default: `DOWN` → 503,
`OUT_OF_SERVICE` → 503, everything else → 200). Detail visibility
(`management.endpoint.health.show-details`) and health **groups** are front 76's.

### Info contributors

The same shape, one decorator lighter on rules:

```bp
pub behavior InfoContributor { fn contribute(self: Self) -> string; }  // a JSON object string
```

`#[infoContributor("build")]` registers one; front 11 ships `build` (name and version from
`botopink.json`), `otp` (release, ERTS version, schedulers — the `java` row's analogue), `os` and
`process` (PID, uptime). `env` reads keys under `info.*` from front 05. Contributions are merged by
top-level key; two contributors claiming one key is a boot failure naming both, not a silent
last-wins.

### The four registry-reading endpoints

None of these holds state; each is a view onto a registry another front owns, which is why they are
cheap and why they belong together.

| Endpoint | Reads | Note |
|---|---|---|
| `beans` | front 06's `ctx.beanNames()` plus each bean's qualifier, scope and lazy flag | no dependency graph — the registry does not hold one |
| `configprops` | front 05's `rkRegisterConfigKeys` inventory, with the bound values | sanitization is front 76's |
| `mappings` | front 04's `rkRoutePaths()` and front 22's file-router table | both, merged, with the source of each route named |
| `startup` | front 11's own boot-step timings | see below |
| `shutdown` | — | a `POST` that triggers front 07's drain; **access-controlled by front 76**, and refused with 405 when 76 has not granted it |

`startup` needs something nothing else records: the elapsed time of each boot step. `instrumentation.bp`
records them — `config.load`, `eager.init`, each `#[postConstruct]`, `listener.bind` — as a list of
`{step, startedAtMillis, durationMillis}`, which is also what front 17's one-line startup summary
reads.

### `instrumentation.bp`

The startup hook and the span seam, folded in here because scattering them would mean four fronts each
cutting into the request path.

```bp
#[instrumentation]
pub fn instrumentation() {
    // runs before configuration, before any bean, before the listener
}
```

One `#[instrumentation]` function per application, run first — Next's `instrumentation.ts`
(`NEXTJS-DOCS.md § 3`). Two in one build is a boot failure naming both.

Spans are emitted around the four things the server does:

```bp
pub type Span(name: string, traceId: string, spanId: string, parentId: string, startedAt: i64)

pub fn startSpan(name: string, attributes: string) -> Span;
pub fn endSpan(span: Span, outcome: string) -> i32;
```

- **`http.server.request`** — a chain entry at order +100 (front 07's band), wrapping everything after
  it, so the span covers the handler and every filter below it.
- **`render`** — front 23's SSR pipeline calls `startSpan`/`endSpan` around a page render.
- **`action`** — front 24 does the same around a server action.
- **`handler`** — front 25 around a route handler.

Each emission is a `:telemetry`-shaped event: `[rakun, http, server, stop]` with measurements and
metadata. **Front 11 emits; front 75 subscribes and exports.** Front 11 ships no exporter, no
Prometheus endpoint and no meter registry, and an application with front 11 alone can read spans in a
log and nothing more.

Trace context propagates through the W3C `traceparent` header: an inbound header continues the trace,
an absent one starts it, and front 13's HTTP client sends it outbound. The header format is stated in
this README because two fronts write it.

### Where Spring uses JMX

`09-actuator.md § JMX` configures an MBean domain and unique names, and there is no JMX on the BEAM and
no reason to want one. The analogue is better and already exists:

- **`:telemetry`** is the instrumentation bus — a published event with measurements and metadata,
  which is what Micrometer's meter registry consumes upstream. Front 11 emits `:telemetry`-shaped
  events; front 75 is the subscriber.
- **`observer` and a remote shell** (`erl -remsh node@host`) are the management console. A live node
  with a shell attached is a strict superset of what a JMX console offered: every process, its message
  queue, its memory, its current stack, and the ability to run code. It is also how BEAM operators
  already work, so it needs documenting rather than building.

`management.endpoints.jmx.*` is therefore **not ported**, and this README says so rather than mapping
it onto something it is not.

## Steps

### Step 0 — `modules/rakun-actuator-api` (wave 1)

The dependency-free module: the five types, the four decorators, the five registration cells and
`modules/rakun-actuator-api/src/sidecars/rakun_actuator_api.erl`, which creates and owns the health,
info and endpoint ETS tables.

**Acceptance:**
- [x] `modules/rakun-actuator-api/` compiles with `"target": "erlang"` and depends on no other rakun module — held: `modules/rakun-actuator-api/botopink.json` (dependencies: `rakun` only), 10 passed / 0 failed / 0 compile failures
- [x] A front can declare `#[healthIndicator("db")]` with `rakun-actuator-api` as its only actuator dependency — held: `modules/rakun-actuator-api/test/registration_test.bp` "registry: indicators, a contributor and endpoints register under their ids with the host absent, sorted by name"
- [x] Registration succeeds with the host absent, and nothing reads the table — held: `modules/rakun-actuator-api/test/registration_test.bp` "registry: indicators, a contributor and endpoints register under their ids with the host absent, sorted by name" (the member has no host dependency)
- [x] `startSpan`/`endSpan` work with no host and no subscriber, and cost nothing — held: `modules/rakun-actuator-api/test/span_test.bp` "span: a root span starts a trace, and a span started inside it is its child", "span: with no subscriber an emission costs under a microsecond"
- [x] The three registries are `named_table, public` and survive a host restart — held: `modules/rakun-actuator-api/test/registration_test.bp` "registry: the three registries are named, public and owned by the API process", `modules/rakun-actuator/test/health_test.bp` "health: the registries are the API's, so a host restart loses no registration"
- [x] Nothing in this module decides a status, a timeout, a route or an exposure — those are all host — held: `modules/rakun-actuator-api/src/registration.bp` (writes rows and answers ids/owners only; the duplicate-id refusal is the one rule, a registry property) and `rakun_actuator_api.erl`

### Step 1 — The endpoint host (wave 3)

**Acceptance:**
- [x] `modules/rakun-actuator/` compiles with `"target": "erlang"`, depends on `rakun-actuator-api`, and its tests run — held: `modules/rakun-actuator/botopink.json`, 38 passed / 0 failed / 0 compile failures
- [x] `#[endpoint("x")]` registers and is reachable at `/actuator/x` — held: `modules/rakun-actuator/test/endpoint_test.bp` "endpoint: an application endpoint is reachable by id under the base path" (with a front-76 stand-in exposure decision installed)
- [x] `management.endpoints.web.base-path=/manage` moves every endpoint — held: `modules/rakun-actuator/test/endpoint_test.bp` "endpoint: base-path moves every endpoint"
- [x] `management.endpoints.web.path-mapping.health=healthcheck` renames one segment, and the id stays `health` — held: `modules/rakun-actuator/test/endpoint_test.bp` "endpoint: path-mapping renames one segment and the id stays health"
- [x] Exactly one route is registered regardless of the number of endpoints — held: `modules/rakun-actuator/test/endpoint_test.bp` "endpoint: exactly one route is registered regardless of the number of endpoints"
- [x] An unknown endpoint id answers 404 through front 07's problem-detail shape — held: `modules/rakun-actuator/test/endpoint_test.bp` "endpoint: an unknown id answers 404 through the problem-detail shape"
- [x] Two endpoints with the same id fail at boot naming both — held: `modules/rakun-actuator/test/endpoint_test.bp` "endpoint: two endpoints with the same id fail at boot naming both"
- [x] With front 76 absent, only `health` is reachable — front 11 does not open the others by default — held: `modules/rakun-actuator/test/endpoint_test.bp` "endpoint: with front 76 absent only health is reachable, and a hidden endpoint answers exactly like an unknown one"

### Step 2 — Response cache and endpoint CORS

**Acceptance:**
- [x] `management.endpoint.health.cache.time-to-live=5s` serves the cached body for 5 seconds and the indicators run once — held: `modules/rakun-actuator/test/endpoint_test.bp` "endpoint: a cache time-to-live serves the cached response and the indicators run once"
- [x] A TTL of 0 (the default) runs the indicators on every request — held: `modules/rakun-actuator/test/endpoint_test.bp` "endpoint: a TTL of 0, the default, runs the indicators on every request"
- [x] The cache is per endpoint, not global — held: `modules/rakun-actuator/test/endpoint_test.bp` "endpoint: the cache is per endpoint, not global"
- [x] Endpoint CORS uses front 07's policy type and its own configured origins — held: `modules/rakun-actuator/test/endpoint_test.bp` "endpoint: endpoint CORS uses front 07's policy with its own origins, and a preflight never runs the endpoint"
- [x] A preflight to an endpoint is answered without running the endpoint — held: `modules/rakun-actuator/test/endpoint_test.bp` "endpoint: endpoint CORS uses front 07's policy with its own origins, and a preflight never runs the endpoint"

### Step 3 — Health aggregation and the indicator contract

**Acceptance:**
- [x] With only `ping`, `/actuator/health` answers `{"status":"UP"}` and 200 — held: `modules/rakun-actuator/test/health_test.bp` "health: with only ping the aggregate is UP and the endpoint answers 200"
- [x] One `DOWN` indicator makes the aggregate `DOWN` and the status code 503 — held: `modules/rakun-actuator/test/health_test.bp` "health: one DOWN indicator makes the aggregate DOWN and the code 503"
- [x] `management.endpoint.health.status.order` changes which status wins — held: `modules/rakun-actuator/test/health_test.bp` "health: status.order changes which status wins, and http-mapping changes the code"
- [x] An indicator that raises becomes `DOWN` with the reason in `details`, and the endpoint still answers — held: `modules/rakun-actuator/test/health_test.bp` "health: an indicator that raises becomes DOWN with the reason and the endpoint still answers"
- [x] An indicator that exceeds its timeout becomes `UNKNOWN` and is abandoned — the endpoint answers within the timeout — held: `modules/rakun-actuator/test/health_test.bp` "health: an indicator past its timeout becomes UNKNOWN, is abandoned, and the endpoint answers within the timeout"
- [x] Ten indicators at 1 s each complete in about 1 s, not 10 — they run in their own processes — held: `modules/rakun-actuator/test/health_test.bp` "health: ten indicators at 300 ms each complete in about 300 ms, not 3 s" (measured at 300 ms per indicator to keep the suite short)
- [x] `#[healthIndicator("db")]` in another module registers here with no change to front 11 — held: `modules/rakun-actuator/test/health_test.bp` "health: a #[healthIndicator] declared in another module registers here with no change to the host"
- [x] Two indicators with one id fail at boot naming both — held: `modules/rakun-actuator/test/health_test.bp` "health: two indicators with one id fail at boot naming both"

### Step 4 — Info contributors

**Acceptance:**
- [x] `/actuator/info` merges every contributor by top-level key — held: `modules/rakun-actuator/test/info_test.bp` "info: every contributor is merged by top-level key"
- [x] `build`, `otp`, `os` and `process` ship and report real values — held: `modules/rakun-actuator/test/info_test.bp` "info: build, otp, os and process report real values"
- [x] Keys under `info.*` in configuration appear — held: `modules/rakun-actuator/test/info_test.bp` "info: keys under info.* in configuration appear, nested by their dots"
- [x] Two contributors claiming one key fail at boot naming both — held: `modules/rakun-actuator/test/info_test.bp` "info: two contributors claiming one key fail at boot naming both"
- [x] `#[infoContributor]` in another module registers here — held: `modules/rakun-actuator/test/info_test.bp` "info: an #[infoContributor] declared in another module registers here"

### Step 5 — `beans`, `configprops`, `mappings`

**Acceptance:**
- [x] `beans` lists every registered bean with its qualifier, scope and lazy flag — held: `modules/rakun-actuator/test/registry_endpoints_test.bp` "beans: every registered bean is listed with its qualifier, scope and lazy flag"
- [ ] `configprops` lists every key front 05 registered, with the bound value and the source it came from
- [ ] `mappings` lists decorator routes and file-router routes, each labelled with its source
- [x] Each endpoint reads its registry and holds no state of its own — held: `modules/rakun-actuator/test/registry_endpoints_test.bp` "registry endpoints hold no state: a route registered after a read appears in the next read"
- [x] With front 05 or front 22 absent, the corresponding endpoint reports an empty list rather than failing — held: `modules/rakun-actuator/test/registry_endpoints_test.bp` "mappings: with front 22 absent the file-router half is an empty list, not a failure" (front 05's catalogue is in the core, so "absent" is an empty catalogue: `configpropsJson` folds over `configCatalogue()`)

### Step 6 — `startup` and boot-step timing

**Acceptance:**
- [x] Every boot step is recorded with a start time and a duration — held: `modules/rakun-actuator/test/instrumentation_test.bp` "startup: every boot step is recorded with a start and a duration, and the steps sum to the total"
- [ ] `config.load`, `eager.init`, each `#[postConstruct]` and `listener.bind` all appear
- [x] The steps sum to within a few milliseconds of the total boot time — held: `modules/rakun-actuator/test/instrumentation_test.bp` "startup: every boot step is recorded with a start and a duration, and the steps sum to the total" (contiguous marks: the sum equals the total)
- [x] Front 17 can read the same record for its startup summary line — held: `startupSteps()` in `modules/rakun-actuator/src/instrumentation.bp` (the record the `startup` endpoint renders)

### Step 7 — `shutdown`

**Acceptance:**
- [ ] `POST /actuator/shutdown` triggers front 07's drain sequence
- [ ] Without front 76 granting access it answers 405, and it is never enabled by front 11's own default
- [ ] A `GET` on it answers 405
- [ ] The response is written before the listener stops accepting

### Step 8 — `instrumentation.bp` and spans

**Acceptance:**
- [ ] `#[instrumentation]` runs before configuration is loaded and before any bean is constructed
- [x] Two `#[instrumentation]` functions fail at boot naming both — held: `modules/rakun-actuator/test/instrumentation_test.bp` "instrumentation: two #[instrumentation] functions fail at boot naming both"
- [x] An `http.server.request` span wraps the handler and every filter below order +100 — held: `modules/rakun-actuator/test/instrumentation_test.bp` "spans: the http.server.request entry sits at +100 and wraps the filters below it and the handler"
- [x] A span carries a trace id, a span id and a parent id, and a child span's parent is its caller's span — held: `modules/rakun-actuator-api/test/span_test.bp` "span: a root span starts a trace, and a span started inside it is its child"
- [x] An inbound `traceparent` continues the trace; an absent one starts a new one with a fresh trace id — held: `modules/rakun-actuator/test/instrumentation_test.bp` "spans: an absent traceparent starts a fresh trace, and the span parents on the inbound one when present", `modules/rakun-actuator-api/test/span_test.bp` "span: an inbound traceparent continues the trace, a malformed one is ignored"
- [ ] Front 13's outbound client sends `traceparent` carrying the current span
- [ ] `render`, `action` and `handler` spans are emitted by fronts 23, 24 and 25 through this front's API, with no second hook into the request path
- [x] Emitted events are `:telemetry`-shaped; front 75 can subscribe without front 11 changing — held: `modules/rakun-actuator-api/test/span_test.bp` "span: events are telemetry-shaped and reach a subscriber" (`telemetry:execute/3` is also called when the module is loaded)
- [x] With no subscriber, span emission is a no-op measured at under one microsecond — held: `modules/rakun-actuator-api/test/span_test.bp` "span: with no subscriber an emission costs under a microsecond"

## Examples

- [`examples/health-info-example.bp`](./examples/health-info-example.bp) — a developer shipping a
  custom health indicator, an info contributor, an application-specific endpoint, and the
  `#[instrumentation]` startup hook.

## Language gaps

None new. Two already in [`language-gaps.md`](../../language-gaps.md) shape this front:

- **A std JSON walker does not exist** — decides that `Health.details`, an info contribution and an
  `EndpointResponse` body are all JSON **strings** built by the contributor, rather than a structured
  value the endpoint serializes. It is why the "two contributors claiming one key" check is done on
  top-level keys parsed in the sidecar rather than in botopink.
- **`@Task<T>` lowers eagerly on erlang** — decides that concurrent indicator execution is one BEAM
  process per indicator gathered by id, not `all(futures)`. Front 02's unstarted-thunk shape is what
  this front uses.

## Test plan

`modules/rakun-actuator-api/test/registration_test.bp` plus `modules/rakun-actuator/test/` — `endpoint_test.bp`, `health_test.bp`, `info_test.bp`,
`registry_endpoints_test.bp`, `instrumentation_test.bp` — run with `botopink test --target erlang` and
in the gate through `zig build test-libs -- --target erlang`. The manifest declares
`"target": "erlang"`, so the commonJS cell reports *skipped*.

The indicator contract is the part most worth testing, because eight other fronts depend on it holding.
`health_test.bp` registers four deliberately badly behaved indicators — one that raises, one that
sleeps past its timeout, one that returns an unknown status string, one that returns malformed JSON in
`details` — and asserts that the endpoint still answers, within the timeout, with a sensible aggregate.
If that test is green, a front shipping an indicator cannot break the health endpoint, which is the
whole promise of the contract.

`instrumentation_test.bp` asserts span parenting by emitting a nested pair and comparing ids, and
asserts the no-subscriber cost by running a million emissions and bounding the elapsed time — the one
place in this front where a timing assertion is the honest test rather than a flake, because the claim
is about an order of magnitude and not a millisecond.

Erlang-only. There is no client half: a browser reads these endpoints over HTTP like any other client.

## Adjacent fronts

- **75-rakun-observability-metrics** subscribes to the events this front emits and owns every meter,
  exporter and VM metric. Front 11 ships no registry and no `/actuator/prometheus`.
- **76-rakun-actuator-security-probes** owns exposure, access levels, the management listener,
  sanitization, health groups and the Kubernetes probes. Front 11 registers endpoints; 76 decides who
  reaches them, and front 11's default reaches only `health`.
- **07-rakun-middleware** owns the chain the span entry registers into, the CORS type endpoint CORS
  reuses, and the drain the `shutdown` endpoint triggers.
- **06-rakun-context-api** owns the bean registry `beans` reads and the boot events `startup` times.
- **05-rakun-config-profiles** owns the key catalogue `configprops` reads.
- **17-rakun-logging** owns the `loggers` and `logfile` endpoints — it implements them and registers
  them here through `#[endpoint]`, the same way an indicator registers.
- **12-rakun-cache** owns the `caches` endpoint, **16** owns `scheduledtasks`, **18** owns `sessions`,
  **77** owns the migrations endpoint. Each ships its own and registers here.

## Contradictions with fronts.md

1. **Recorded:** this front owns `botopink.json` + `src/root.bp` for **both** of its modules, being the
   lowest-numbered front in each. Fronts 75 and 76 append their `pub mod` lines to
   `modules/rakun-actuator/src/root.bp` in front-number order.
2. **F11's row is `modules/rakun-actuator/src/**`, and front 76 later owns five files inside it**
   (`exposure.bp`, `access.bp`, `management_listener.bp`, `probes.bp`, `sanitize.bp`). The rows
   overlap; F11's should be narrowed to the files it actually owns, or 76's carved out by
   sub-directory as F07/F20 do.
3. **Resolved:** the sidecars are `modules/rakun-actuator-api/src/sidecars/rakun_actuator_api.erl`
   (the three registries and the span emitter) and `modules/rakun-actuator/src/sidecars/rakun_actuator.erl`
   (the host), per the mandated `src/sidecars/rakun_<name>.erl` form.
4. **Resolved:** the decorators and the registration contract moved to `modules/rakun-actuator-api/`,
   a wave-1 module with no dependencies, owned by this front alongside the host. Fronts 08, 09, 12,
   15–18, 77 and 85 depend on the API module, not on the host, so the wave table has no cycle.

## Definition of done

- [ ] `modules/rakun-actuator-api/` exists, depends on nothing, and is what fronts 08 · 09 · 12 · 15 ·
      16 · 17 · 18 · 77 · 85 import for their indicators and endpoints
- [ ] `modules/rakun-actuator/` exists with the endpoint host, the health and info registries, the
      four registry-reading endpoints, `shutdown`, `instrumentation.bp` and the sidecar
- [x] One route serves every endpoint, with a configurable base path and per-endpoint path — held: `modules/rakun-actuator/test/endpoint_test.bp` "endpoint: exactly one route is registered regardless of the number of endpoints", "endpoint: base-path moves every endpoint", "endpoint: path-mapping renames one segment and the id stays health"
- [x] The health-indicator contract is documented in this README and in `AGENTS.md`, and the
      badly-behaved-indicator suite is green — held: `repository/rakun/AGENTS.md` § The actuator (the contract table) + `modules/rakun-actuator/test/health_test.bp` "health: four badly behaved indicators cannot break the endpoint"
- [x] Indicators run concurrently, each with a timeout, and none can break the endpoint — held: `modules/rakun-actuator/test/health_test.bp` "health: four badly behaved indicators cannot break the endpoint", "health: ten indicators at 300 ms each complete in about 300 ms, not 3 s"
- [ ] Spans are emitted for request, render, action and handler, `:telemetry`-shaped, with W3C trace
      propagation, and cost nothing with no subscriber
- [x] `management.endpoints.jmx.*` is documented as not ported, with `:telemetry` and `erl -remsh`
      named as the analogues — held: `repository/rakun/AGENTS.md` § The actuator ("Not ported: … jmx")
- [x] Front 11 exposes only `health` by default and defers every access decision to front 76 — held: `modules/rakun-actuator/test/endpoint_test.bp` "endpoint: with front 76 absent only health is reachable, and a hidden endpoint answers exactly like an unknown one" (`installExposure` is front 76's seam)
- [x] The front's tests are green on its assigned target — held: `modules/rakun-actuator-api` 10/0/0 and `modules/rakun-actuator` 38/0/0 on erlang

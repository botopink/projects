# Front 87 — Rakun Audit and HTTP Exchanges

**Track:** B rakun
**Priority:** medium — a security decision nobody recorded cannot be reviewed, and an HTTP exchange log is the cheapest production-debugging tool there is; both are missing and neither is anyone else's work
**Target:** erlang (server)
**Wave:** 6
**Depends on:** 11 (endpoint infrastructure hosts the two endpoints), 10 (publishes the authentication and authorization events), 07 (the filter chain the recorder sits in), 76 (default-deny exposure and access control over both endpoints), 08 (the durable repository arm), 01/std `io.clock` (timestamps)
**Owns:** `modules/rakun-actuator/src/audit/**`, `modules/rakun-actuator/src/exchanges/**`, `modules/rakun-actuator/test/audit/**`, `modules/rakun-actuator/test/exchanges/**`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` — frozen for the milestone. Inside `modules/rakun-actuator/`, everything outside `src/audit/**` and `src/exchanges/**` belongs to front 11 or front 76 and is read-only here.
**Reference:** `09-actuator.md § Auditing` · `§ HTTP Exchanges` · `§ Endpoints` (`auditevents`, `httpexchanges`) · https://docs.spring.io/spring-boot/reference/actuator/auditing.html · https://docs.spring.io/spring-boot/reference/actuator/tracing.html

---

## Problem

Front 10 will authenticate a request, reject a bad password and deny an unauthorized path. Nothing
keeps a record of any of it. Ask "who logged in yesterday", "was this account brute-forced", "who
was denied access to `/admin` last week" and there is no place in the system that holds the answer.
Logs are not that place: a log line is free-form, it is rotated, and it is written at a level someone
can turn off. Spring separates the two deliberately — `AuditEvent` is a structured record with a
principal, a type and a data map, stored in a repository that a reviewer can query
(`09-actuator.md § Auditing`).

The second half is cheaper and just as absent. When a production request misbehaves, the fastest
diagnostic available is a ring buffer holding the last hundred exchanges — method, URI, status,
duration — with the headers that matter and none of the ones that must never be stored. Spring's
`InMemoryHttpExchangeRepository` is a hundred entries and an explicit include-list
(`09-actuator.md § HTTP Exchanges`). rakun has no such buffer, no filter position to install one in
yet, and no endpoint to read it from.

Both are owned by nobody in the milestone as it stands. The actuator front exposes health, info and
metrics; the metrics front counts and times; neither answers *who* or *what was the request*.

## Current state

- `repository/rakun/modules/rakun-actuator/src/root.bp` — a docblock and the comment *"Module
  contents will be added by the respective fronts."* No code.
- `repository/rakun/modules/rakun-security/src/root.bp` — the same stub. There is no authentication
  today, so there is nothing yet emitting the events this front stores; the wiring lands when front
  10 does.
- `repository/rakun/src/http.bp:35-43` — `Request` exposes `method`, `path`, `param`, `query`,
  `header` and `body`, all returning plain strings. That is enough to record an exchange and it is
  frozen, so the recorder reads it and adds nothing to it.
- `libs/std/src/time.bp:56` — `time.nowMillis() -> i64` and `time.formatIso8601(epochMillis)` exist today (`clock.nowMillis` and `clock.formatIso8601` under `io.clock`, decision 106)
  today; this front needs no new clock primitive.
- `libs/std/src/json.bp:9-16,36` — `json.parse` is `string -> @Result<string, string>`; the
  structured reader `json.decode -> @Result<Json, string>` is `01-std/01-std-lib-enablement`'s
  (decision 117). A blob would still have to be decoded on every read to be filtered, which shapes
  the event model below.

## Mechanism

Two recorders, one shape: a bounded in-memory ring with an optional durable arm behind the same
behavior, and an endpoint over each.

**An audit event is pairs, not a JSON blob.** Spring's `AuditEvent` carries a `Map<String, Object>`.
The obvious translation is a JSON string, and it is the wrong one: a stored blob has to be decoded
before every filter, so "show me the failures for this client address" would decode the whole ring. The data is therefore `Array<#(string, string)>` — queryable by
key, rendered to JSON at the endpoint, and lossless for the values audit events actually carry
(remote address, request path, denial reason, session id). A value that is genuinely structured is
stored as several pairs with dotted keys rather than as one escaped blob.

```
AuditEvent(atMs: i64, principal: string, kind: string, data: Array<#(string, string)>)
```

**The event types keep their upstream spelling.** `AUTHENTICATION_SUCCESS`,
`AUTHENTICATION_FAILURE`, `AUTHORIZATION_FAILURE` and `LOGOUT` are the four Spring emits, and an
operator moving from Spring should be able to filter by the string they already know. An application
adds its own types freely; the front reserves no namespace.

**The dependency points one way, and that is a design rule rather than a convenience.** Front 10
calls `audit(...)`; this front never imports front 10. If the arrow ran the other way, security could
not be tested without the actuator module present and the two would be one front pretending to be
two. The seam is a single function, and a security build with no actuator gets a no-op
implementation of it.

**Two repository arms behind one behavior.**

| Arm | Backing | Bound | For |
|---|---|---|---|
| `memoryAuditRepository(capacity)` | one ETS table, written as a ring | `capacity` events, default 1000 | development, and the default |
| `sqlAuditRepository(table)` | front 08's `SqlTemplate` | the table | anything where the answer must survive a restart |

The README of the module says, in those words, that in-memory audit is not audit. The default is the
memory arm because a default that needs a database is a default that does not work; the endpoint
reports which arm is active so nobody discovers it during an incident.

**Overflow is reported, not hidden.** The ring drops the oldest event when full and increments a
dropped counter. The `auditevents` endpoint returns that counter alongside the events. An audit
buffer that silently discards is worse than no buffer, because it looks like an answer.

**The exchange recorder is a filter, and it records after the response.** It installs in front 07's
chain at the outermost position, reads the clock before delegating and after returning, and appends
one `HttpExchange` to a bounded ring. Recording after the response is what makes the status and the
duration available; it also means an exchange that crashes the chain is recorded with the status the
error handler produced, not lost.

**The include-list is default-deny and keeps Spring's value names.**

| Include value | Off by default | Note |
|---|---|---|
| — (always recorded) | — | method, URI, status, time taken |
| `request-headers` | yes | never includes `authorization` or `cookie`, whatever this says |
| `response-headers` | yes | never includes `set-cookie` |
| `cookie-headers` | yes | its own switch, deliberately |
| `authorization-header` | yes | its own switch, deliberately |
| `principal` | yes | the resolved principal name from front 10 |
| `remote-address` | yes | a personal datum in most jurisdictions |
| `session-id` | yes | |

Two separate switches for cookies and the authorization header is Spring's shape and it is the right
one: "record the request headers" is a debugging wish and "record the credential" is a decision
somebody must make on purpose. The filter enforces the exclusion rather than documenting it —
turning `request-headers` on and reading back an `authorization` value is a test that must fail.

**Recording is off until it is switched on.** `rakun.management.httpexchanges.recording.enabled`
defaults to false, mirroring Spring's requirement that you declare the repository bean yourself. A
ring of the last hundred requests, including principals, is not something a framework should start
keeping without being asked.

**Where the line with front 75 runs.** Front 75 owns metrics and tracing. A counter says how many
authentications failed; an audit event says which principal failed, from which address, at which
instant, in order. A span says a request took 412 ms across four services; an exchange record says
this URI returned 500 with these headers. They answer different questions and share no storage. This
front emits no telemetry of its own — if front 75 wants an `audit.events` counter it registers it
there, over this front's public seam.

**Target.** Both recorders run while a request is in flight, so both are erlang. The host cells are
`#[@External.Erlang]` over `ets` for the rings; the SQL arm goes through front 08 and adds no host
cell of its own. There is no `@External.Node` cell in this front.

## Steps

### Step 1 — The event and the repository behavior

```bp
pub type AuditEvent(
    atMs: i64,
    principal: string,
    kind: string,
    data: Array<#(string, string)>,
)

pub behavior AuditRepository {
    fn record(self: Self, event: AuditEvent) -> i32;
    fn find(self: Self, principal: string, afterMs: i64, kind: string) -> Array<AuditEvent>;
    fn dropped(self: Self) -> i32;
}
```

An empty `principal` or `kind` in `find` means "any", matching the endpoint's optional query
parameters. The field is `kind` and not `type` because `type` is a keyword
(`modules/compiler-core/src/lexer.zig:721-767`); the endpoint's query parameter keeps the upstream
name `type`, so the HTTP surface is unchanged.

**Acceptance:**
- [ ] `find("", 0, "")` returns every retained event, newest last.
- [ ] `find("ana", 0, "")` returns only `ana`'s events; `find("", 0, "AUTHENTICATION_FAILURE")` only that kind; both together intersect rather than union.
- [ ] `afterMs` is exclusive, so paging by the last seen timestamp cannot re-read an event.
- [ ] An event with an empty `data` array round-trips through both arms unchanged.

### Step 2 — The in-memory ring

```bp
pub fn memoryAuditRepository(capacity: i32) -> AuditRepository
```

**Acceptance:**
- [ ] Writing `capacity + 5` events retains exactly `capacity`, and the five dropped are the oldest.
- [ ] `dropped()` reports 5 after that write, and is monotonic.
- [ ] The ETS table is owned by the module's supervisor, so a crashing recorder does not take the history with it — asserted by killing the recorder process and reading the history back.
- [ ] Two repositories built with different capacities do not share a table.

### Step 3 — The durable arm

```bp
pub fn sqlAuditRepository(table: string) -> AuditRepository
```

**Acceptance:**
- [ ] The schema is created by a front 77 migration, not by the repository at boot — a repository that mutates schema at boot is a repository that surprises a DBA.
- [ ] `find` pushes the principal, kind and timestamp filters into SQL; a test asserts the query text contains all three predicates rather than filtering in botopink after a full read.
- [ ] `dropped()` is always 0 for this arm, and the README says why.
- [ ] A write that fails does not raise into the caller's request — audit failure is logged at error and counted, because an unavailable audit database must not take the application down with it. Whether that trade is right is stated explicitly, not assumed.

### Step 4 — The events front 10 publishes

```bp
pub fn audit(kind: string, principal: string, data: Array<#(string, string)>) -> i32
```

**Acceptance:**
- [ ] Front 10 calls this and nothing in `src/audit/**` imports front 10.
- [ ] With no actuator module present, the seam is a no-op and front 10's tests still pass.
- [ ] A successful authentication produces one `AUTHENTICATION_SUCCESS` carrying the principal and the remote address; a failure produces one `AUTHENTICATION_FAILURE` carrying the attempted principal and *no* password field, asserted by a test that greps the stored data.
- [ ] A denied request produces one `AUTHORIZATION_FAILURE` carrying the path and the required role.

### Step 5 — The exchange recorder

```bp
pub type HttpExchange(
    atMs: i64,
    method: string,
    uri: string,
    status: i32,
    tookMs: i32,
    fields: Array<#(string, string)>,
)

pub fn unknownIncludes(names: Array<string>) -> Array<string>

pub fn exchangeFields(
    include: Array<string>,
    headers: Array<#(string, string)>,
    principal: string,
    remoteAddress: string,
    sessionId: string,
) -> Array<#(string, string)>
```

`unknownIncludes` returns the names that are not one of the eight; boot refuses when it returns
anything. `exchangeFields` is the projection itself and is pure, which is what makes the two
exclusions testable without a listener.

**Acceptance:**
- [ ] With recording disabled, the filter is not installed at all — verified by counting the chain's arms, not by checking an empty ring.
- [ ] With it enabled and no include list, an exchange carries exactly method, URI, status and duration.
- [ ] With `request-headers` included, an `authorization` header is absent from the record and a `cookie` header is absent from the record.
- [ ] With `authorization-header` included, it is present — the only way it can be.
- [ ] An unknown include name fails at boot with a located message listing the eight valid ones.
- [ ] A request that raises inside the chain is still recorded, with the status the error handler produced.

### Step 6 — The two endpoints

```
GET /actuator/auditevents?principal=&after=&type=
GET /actuator/httpexchanges
```

**Acceptance:**
- [ ] Both are registered with front 11 and both are absent from the discovery page unless front 76's exposure list names them.
- [ ] Both are read-only: no verb other than `GET` is routed.
- [ ] `auditevents` renders `dropped` alongside `events`.
- [ ] `httpexchanges` renders newest first, and the ring's capacity is reported with the payload.
- [ ] Sanitization from front 76 applies to both — a value in an audit `data` pair whose key matches the sanitize list is masked.

### Step 7 — Retention

**Acceptance:**
- [ ] `rakun.management.auditevents.capacity` and `rakun.management.httpexchanges.capacity` both take effect at boot and are reported by their endpoints.
- [ ] Capacity 0 is rejected at boot rather than producing a repository that records nothing.
- [ ] The SQL arm has a documented retention story — a scheduled prune via front 16 — and the README says that unbounded audit tables are the caller's decision to make.

## Examples

- [`examples/audit-events-example.bp`](./examples/audit-events-example.bp) — a service recording a
  domain audit event, a reviewer query, and a filtering repository wrapper that shows why the buffer
  cannot live in a record field.
- [`examples/http-exchanges-example.bp`](./examples/http-exchanges-example.bp) — the recording
  include list: what is kept by default, what is opt-in, and the two values that stay out however the
  list is written.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| A record cannot be mutated — there is no assignment to a `self` field anywhere in the real libraries, and every record in the ecosystem is immutable. A bounded buffer, which is by definition a value that changes in place, cannot be a field. | `examples/audit-events-example.bp`, `RedactingAuditRepository` | Keep the buffer in an `#[@External.Erlang]` ETS cell and let the record hold only the table name; a custom repository wraps another rather than accumulating. | Assignment to a `self` field in a method declared to mutate, or a first-class mutable cell type |

## Test plan

`modules/rakun-actuator/test/audit/` and `modules/rakun-actuator/test/exchanges/` on the **erlang**
target, invoked as `zig build test-libs -- --target erlang --lib rakun` from
`repository/botopink-lang/`, and as `botopink test --target erlang` from `repository/rakun/`.

| File | Asserts |
|---|---|
| `test/audit/event_test.bp` | Filter semantics, the exclusive `afterMs`, empty-data round trip |
| `test/audit/memory_test.bp` | Ring eviction order, the dropped counter, table survival across a recorder crash, table isolation |
| `test/audit/sql_test.bp` | Predicate pushdown, write-failure containment, `dropped()` of 0 |
| `test/audit/security_events_test.bp` | The four event types, the absent password field, the no-op seam with no actuator present |
| `test/exchanges/recording_test.bp` | Default fields, each include value, the authorization and cookie exclusions, the unknown-name boot failure |
| `test/exchanges/endpoint_test.bp` | Read-only verbs, ordering, capacity reporting, exposure through front 76 |

The SQL arm runs against a live database when `RAKUN_TEST_DATABASE_URL` is set and reports a
*skipped* cell otherwise. Everything else is in-process and always runs.

There is no commonJS row. This front is server-only by the milestone's target split.

## Definition of done

- `modules/rakun-actuator/src/audit/` and `src/exchanges/` exist, are declared from the module's `root.bp`, and hold no `@External.Node` cell.
- The dependency arrow runs from front 10 to this front and is enforced by a test that builds front 10 with the actuator module absent.
- Turning on `request-headers` cannot surface an authorization header or a cookie, proven by a test.
- Recording is off by default and the two endpoints are invisible until front 76's exposure list names them.
- Dropped events are counted and reported by the endpoint.
- Both language gaps above appear as `// LANGUAGE GAP:` markers in the examples and in a `specs/1.0.10-beta/` spec.
- `repository/rakun/AGENTS.md` and `modules/README.md` record the surface in the same commit.
- The front's tests are green on erlang.


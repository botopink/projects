# Front 76 — rakun Actuator Access Control and Kubernetes Probes

**Track:** B rakun
**Priority:** high — actuator defaults to exposing only `health` for a reason; an endpoint set reachable without authentication on the public listener is a production incident, not a feature gap. And without readiness, a rolling deploy drops requests every time
**Target:** erlang (server)
**Wave:** 5
**Depends on:** 10 · 11 · 74 — and it sequences against front 07's shutdown drain
**Owns:** `modules/rakun-actuator/src/exposure.bp`, `src/access.bp`, `src/management_listener.bp`, `src/probes.bp`, `src/sanitize.bp`, `src/availability.bp` · `modules/rakun-actuator/test/exposure_test.bp`, `test/access_test.bp`, `test/probes_test.bp`, `test/sanitize_test.bp`
**Does not touch:** the rest of `modules/rakun-actuator/src/**` — front 11 owns the endpoint infrastructure, the health and info registries and every endpoint body. This front owns who may reach them, on which listener, and what the response is allowed to contain
**Reference:** `09-actuator.md § Controlando Acesso`, `§ Expondo Endpoints`, `§ Path e Porta`, `§ SSL Diferente para Management`, `§ Sanitizacao`, `§ CORS`, `§ Seguranca`, `§ Health Groups`, `§ Kubernetes Probes` · `03-recursos-principais.md § Disponibilidade da Aplicacao` · <https://docs.spring.io/spring-boot/reference/actuator/endpoints.html> · <https://docs.spring.io/spring-boot/reference/deployment/cloud.html#deployment.cloud.kubernetes>
**Replaces:** new — no front in `1.0.6-beta` proposed it

---

## Problem

Front 11 builds the actuator: health, info, metrics, `env`, `beans`, and the endpoint infrastructure
behind them. What it does not build is the answer to "who may call these". Upstream that answer is
three separate mechanisms and every one of them is default-deny:

- **Exposure** decides whether an endpoint is reachable over HTTP at all. Only `health` is exposed by
  default (`09 § Expondo Endpoints`).
- **Access** decides what may be done with an exposed endpoint — `none`, `read-only`, `unrestricted`
  — with a global `max-permitted` ceiling that no per-endpoint setting can exceed
  (`09 § Controlando Acesso`).
- **The listener** decides where they are reachable from: `management.server.port` and `.address` put
  the whole set on a separate socket, with its own TLS (`09 § Path e Porta`, `§ SSL Diferente para
  Management`).

Without them front 11 ships a set of endpoints that dump the environment, the bean graph and the
property sources to anyone who can reach the port. `env` and `configprops` carry credentials; that is
what `09 § Sanitizacao` exists for, and `show-values` defaults to `never` for the same reason.

The second problem is unrelated to security and just as expensive. Kubernetes decides whether to send
a pod traffic by polling readiness, and whether to kill it by polling liveness
(`09 § Kubernetes Probes`). rakun has neither. A pod with no readiness probe receives traffic from the
moment its socket binds — before the DI graph is built, before migrations have run — and keeps
receiving it through the entire shutdown, because nothing tells the load balancer to stop. Front 07
drains in-flight requests on SIGTERM; draining is worthless if new requests keep arriving during the
drain.

## Current state

| Piece | Where it is today |
|---|---|
| Endpoint infrastructure, health and info registries | front 11, `modules/rakun-actuator/src/**` |
| Exposure rules | none — front 11 registers an endpoint and it is reachable |
| Access levels | none |
| Management listener | none; everything is on the application's listener |
| TLS material for a second listener | front 74's bundle registry |
| Security chain and role checks | front 10 |
| Sanitization | none |
| Liveness and readiness state | none |
| Application lifecycle events | front 06 |
| Shutdown drain | front 07's SIGTERM handler |
| `/actuator/processes`, `/actuator/vm`, `/actuator/prometheus` | front 75 registers them; nothing gates them |
| CORS | front 07 owns the implementation; nothing applies it to the actuator |

## Mechanism

### Three gates, in order, and none of them optional

A request to an actuator endpoint passes four checks before a body is produced. They are ordered so
that the cheapest and the least informative failure comes first — an unexposed endpoint must answer
exactly like an endpoint that does not exist, or the 404/403 difference is itself a disclosure.

1. **Listener.** If a management listener is configured, the endpoint is served only there. On the
   application listener the path is not registered at all.
2. **Exposure.** `rakun.endpoints.web.exposure.include` / `.exclude`, default `include=health`.
   Not exposed → 404, with no body and no log line that distinguishes it from an unknown path.
3. **Access.** `rakun.endpoint.<id>.access` ∈ `none | read-only | unrestricted`, capped by
   `rakun.endpoints.access.max-permitted`. `none` → 404. `read-only` permits `GET`; anything else →
   405. `unrestricted` permits the endpoint's own verbs.
4. **Authorization.** Front 10's chain, matched on the endpoint path set, with the roles the endpoint
   or its health group declares.

`max-permitted` is a ceiling, not a default: setting it to `read-only` makes every
`access=unrestricted` behave as `read-only`, and the effective level is what the `conditions`-style
report shows, not the configured one. There is no property that raises an endpoint above the ceiling —
that is the whole point of a ceiling, and this front admits no escape hatch for it, the same way front
24 admits none for its CSRF check ([`contracts.md`](../../contracts.md) §3).

### Default-deny, stated as a test

The defaults are `exposure.include=health`, `access.default=read-only`, `max-permitted=unrestricted`,
`show-values=never`. A test asserts, for a rakun application with **no actuator configuration at all**,
that every registered endpoint except `health` answers 404, that `health` answers without details, and
that `env` and `configprops` are unreachable. A default that is only documented is a default that
regresses.

### The management listener

`rakun.management.server.port` starts a second listener through front 04's acceptor — the same
acceptor, a second child of `rakun_sup`, with its own route table. `rakun.management.server.address`
binds it to an interface (`127.0.0.1` is the useful value) and `rakun.management.server.ssl.bundle`
gives it front 74 material that need not be the public certificate; the reference's own example runs
the application on TLS and management in plaintext on a private address
(`09 § SSL Diferente para Management`).

Port `-1` disables the actuator over HTTP entirely while leaving the registries live, which is the
shape an operator wants when everything is scraped over a sidecar.

`rakun.endpoints.web.base-path` defaults to `/actuator` on whichever listener serves it.

### Sanitization

`env` and `configprops` return property values. `rakun.endpoint.env.show-values` ∈
`never | always | when-authorized`, default `never`, with `rakun.endpoint.env.roles` naming the roles
`when-authorized` requires (`09 § Sanitizacao`).

`never` does not mean "omit". It means the key is shown and the value is `******`, because knowing that
`spring.datasource.password` is set is operationally useful and knowing its value is not. The redaction
is applied to the value by the endpoint's response filter, not by the property table, so nothing
downstream can accidentally read a sanitized value as the real one.

A key is sanitized when it matches the pattern set — `password`, `secret`, `key`, `token`,
`credentials`, `vcap_services`, `sun.java.command`, plus `rakun.endpoint.sanitize.additional-keys`.
The list is additive only: there is no property that removes a built-in pattern, because
"unsanitize `password`" is not a thing anybody needs and is exactly what an attacker would set.

### Health groups

`rakun.endpoint.health.group.<name>.include` selects a subset of front 11's indicators, with its own
`show-details`, `roles` and `additional-path` (`09 § Health Groups`). A group is reachable at
`/actuator/health/<name>`, and `additional-path=server:/healthz` also publishes it on the **application**
listener at a root path — which is what a Kubernetes probe needs when the management port is not
exposed in the pod spec.

### Liveness and readiness

This is the part that is first-class rather than a health group with a nice name.

**Liveness** answers "should this pod be killed and restarted". It must not depend on any external
system (`09 § Kubernetes Probes` says so in its own note): a database outage that flips liveness false
turns one failure into a restart storm across every replica. rakun's liveness is `BROKEN` only when the
node itself is unrecoverable — the root supervisor has exited, or the registry table owner has died
past its restart intensity. No indicator that reaches a socket may join the liveness group, and the
configuration is validated for that at boot: naming `db` in `management.endpoint.health.group.liveness.include`
is a startup failure naming the indicator and the rule.

**Readiness** answers "should this pod receive traffic". It is `ACCEPTING_TRAFFIC` only between two
events, and the state machine is the deliverable:

```
                    front 06 emits Ready
  REFUSING_TRAFFIC ──────────────────────► ACCEPTING_TRAFFIC
         ▲                                          │
         │                        SIGTERM received  │
         └──────────────────────────────────────────┘
                     (before front 07 drains)
```

**The ordering is the point of this front's existence.** On SIGTERM the sequence is fixed:

1. Readiness flips to `REFUSING_TRAFFIC`. `/actuator/health/readiness` starts answering 503.
2. `rakun.lifecycle.pre-drain-period` (default 5000 ms) elapses, unconditionally. This is the window in
   which the load balancer notices — a pod that stops accepting traffic before the endpoint controller
   has removed it still drops requests, and no amount of draining fixes that, because the requests
   arrive after the drain has started.
3. Front 07 drains: in-flight requests finish, new connections are refused.
4. Front 06 runs `#[preDestroy]`, the node halts.

Steps 1 and 2 are this front's; steps 3 and 4 are fronts 07 and 06. The contract between them is a
single call — front 07's drain begins by awaiting this front's `readinessDrained()`, which returns
after the pre-drain period. Front 07 does not re-implement the wait and this front does not drain.

Readiness is also settable from the application: a service that needs a warm cache before it takes
traffic calls `setReadiness(false)` at boot and `setReadiness(true)` when it is warm. Each transition
publishes an availability event through front 06's publisher, so a listener can react —
`03 § Disponibilidade da Aplicacao` is exactly this pair, and the event is the reason it is a state and
not a boolean somebody polls.

Probe paths, with `rakun.endpoint.health.probes.enabled=true` (default when a Kubernetes environment is
detected, off otherwise) and `.add-additional-paths=true`:

| Path | Listener | Answers |
|---|---|---|
| `/actuator/health/liveness` | management | 200 `CORRECT` / 503 `BROKEN` |
| `/actuator/health/readiness` | management | 200 `ACCEPTING_TRAFFIC` / 503 `REFUSING_TRAFFIC` |
| `/livez` | application | the same as liveness |
| `/readyz` | application | the same as readiness |

### CORS

`rakun.endpoints.web.cors.allowed-origins` and `.allowed-methods` (`09 § CORS`), implemented by calling
front 07's CORS filter with the actuator's own configuration rather than by writing a second one. With
no origins configured, no CORS headers are emitted and a cross-origin request fails — an actuator that
is CORS-open by default would let any page in a browser read `env`.

## Steps

### Step 1 — exposure

**Acceptance:**
- [ ] With no configuration, `health` answers and every other registered endpoint answers 404
- [ ] `include=*` exposes every registered endpoint, including ones front 75 registered
- [ ] `exclude` wins over `include`, including over `*`
- [ ] An unexposed endpoint and an unknown path produce byte-identical responses and identically-shaped log lines
- [ ] Exposure is evaluated against the registry at request time, so an endpoint registered by a late-landing front is covered without editing this front
- [ ] `include` naming an endpoint that does not exist is a boot failure listing the registered ids — a typo must not silently leave something unexposed

### Step 2 — access levels and the ceiling

**Acceptance:**
- [ ] `access=none` answers 404, not 403 — an endpoint turned off must not advertise that it exists
- [ ] `access=read-only` answers `GET` and refuses `POST`/`DELETE` with 405
- [ ] `access=unrestricted` on `shutdown` permits the `POST`
- [ ] `max-permitted=read-only` demotes every `unrestricted` endpoint, and the effective level is what the report shows
- [ ] No property raises an endpoint above `max-permitted`; a test asserts the absence of one by enumerating the configuration keys this front reads
- [ ] `access.default=none` with one endpoint set to `read-only` reproduces the reference's opt-in example exactly

### Step 3 — the management listener

**Acceptance:**
- [ ] With `management.server.port` set, no actuator path is registered on the application listener
- [ ] `management.server.address=127.0.0.1` refuses a connection from another interface
- [ ] `management.server.ssl.bundle` uses front 74 material independent of `server.ssl.bundle`; a plaintext management listener behind a TLS application listener works, which is the reference's own example
- [ ] `management.server.port=-1` leaves the registries live and serves nothing over HTTP
- [ ] `endpoints.web.base-path=/manage` moves every path on whichever listener serves it
- [ ] The management listener is a separate `rakun_sup` child: killing it does not affect the application listener, and vice versa

### Step 4 — sanitization

**Acceptance:**
- [ ] `show-values=never` shows every key with `******` as the value — the key is not omitted
- [ ] `show-values=when-authorized` with `roles=admin` shows values to a principal holding `admin` and `******` to one who does not
- [ ] `show-values=always` shows values and logs a warning naming the endpoint at boot
- [ ] A key matching any built-in pattern is sanitized under `always` too — `always` governs non-sensitive values, not the pattern set
- [ ] `additional-keys` adds patterns and nothing removes a built-in one; a test asserts no removal property exists
- [ ] `configprops` is sanitized by the same code path as `env`, asserted by a shared test rather than two

### Step 5 — health groups

**Acceptance:**
- [ ] A group includes exactly the named indicators and its status aggregates only those
- [ ] A group's `show-details` and `roles` override the global ones for that group alone
- [ ] `additional-path=server:/healthz` publishes the group on the application listener and leaves the management path in place
- [ ] A group naming an indicator that is not registered is a boot failure listing the registered keys
- [ ] An empty group is a boot failure — a group that checks nothing and answers `UP` is worse than no group

### Step 6 — liveness, readiness and the shutdown ordering

**Acceptance:**
- [ ] Before front 06 emits `Ready`, readiness answers 503 and liveness answers 200
- [ ] After `Ready`, readiness answers 200
- [ ] On SIGTERM, readiness answers 503 **before** front 07 refuses its first connection — asserted by a test that records the two timestamps, not by reading the code
- [ ] `lifecycle.pre-drain-period` elapses in full even when there are no in-flight requests
- [ ] Setting `pre-drain-period=0` is permitted and documented as correct only where the load balancer is known to react synchronously
- [ ] Liveness stays 200 while a database indicator is `DOWN`
- [ ] Naming an external-dependency indicator in the liveness group is a boot failure naming the indicator
- [ ] `setReadiness(false)` from the application flips the probe and publishes an availability event through front 06
- [ ] `/livez` and `/readyz` on the application listener answer identically to their management counterparts
- [ ] With probes disabled, none of the four paths exists and the group configuration is still validated

### Step 7 — CORS and the access report

**Acceptance:**
- [ ] With no `allowed-origins`, no CORS header is emitted on any actuator response
- [ ] Configured origins produce the same headers front 07's filter produces for the application, from one implementation
- [ ] `/actuator/access` — or the equivalent block in front 11's own report — lists every registered endpoint with exposed yes/no, configured level, effective level after the ceiling, and which listener serves it
- [ ] That report is itself gated by the rules it describes, and is not exposed by default

## Examples

- [`examples/management-exposure-example.bp`](./examples/management-exposure-example.bp) — the
  configuration an operator writes, and the assertions that prove default-deny holds: what an
  unconfigured application exposes, what the ceiling does, and what `env` shows.
- [`examples/kubernetes-probes-example.bp`](./examples/kubernetes-probes-example.bp) — the readiness
  state machine, the shutdown ordering against front 07, and an application that holds itself
  not-ready until a cache is warm.

## Language gaps

None new — every construct in the examples parses today. The relevant rows already in
[`language-gaps.md`](../../language-gaps.md) are *a decorator cannot rewrite the body it annotates* (which
is why authorization is a chain entry rather than a `#[secured]` wrapper, as front 10 records) and
*a `Request` test double does not exist* (*Unowned surface*), which is why this front's tests drive
endpoints through the dispatcher rather than by calling an endpoint function with a fabricated request.

## Test plan

`modules/rakun-actuator/test/exposure_test.bp`, `access_test.bp`, `probes_test.bp` and
`sanitize_test.bp`, run with `botopink test --target erlang` from `modules/rakun-actuator/` and in the
gate through `zig build test-libs -- --target erlang`.

Every test in this front is a **negative** test first: the assertion that matters is that something is
*not* reachable. Those are written by driving a real request through front 04's dispatcher against a
booted registry, because an access rule verified by calling the checking function directly verifies the
function and not the rule.

The shutdown-ordering test is the one with a real risk of being written to pass rather than to check.
It records two timestamps — the moment readiness first answers 503, and the moment front 07 refuses a
connection — from a single run, and asserts the first precedes the second by at least the configured
pre-drain period. A test that asserts only "readiness eventually goes false" would pass with the
ordering reversed, which is the bug.

This front is erlang-only: the listener, the supervision tree and the signal handling have no Node
form. A commonJS run compiles the `.bp` and fails at the first dispatch.

## Definition of done

- An unconfigured rakun application exposes `health` and nothing else, asserted by a test
- The three gates run in the documented order, and an unexposed endpoint is indistinguishable from an
  absent one
- `max-permitted` cannot be circumvented, and the absence of an escape hatch is a test
- A management listener with its own address and its own TLS bundle serves the actuator and the
  application listener serves none of it
- `env` and `configprops` are sanitized by one code path, with an additive-only pattern set
- Readiness flips false before front 07 drains, with the pre-drain window elapsed, asserted from
  recorded timestamps
- Liveness cannot be made to depend on an external system, enforced at boot
- `/livez` and `/readyz` exist on the application listener when probes are enabled
- The front's tests are green on its assigned target

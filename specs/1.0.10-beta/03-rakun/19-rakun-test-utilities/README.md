# Front 19 — Rakun Test Utilities

**Track:** B rakun
**Priority:** low as a feature, **blocking as a dependency** — `Request` is a `behavior`, so today no rakun front can test a handler without hand-rolling a fake, and front 25's example already does
**Target:** erlang (server)
**Wave:** 3
**Depends on:** 04 (the BEAM runtime it dispatches through), 06 (context), and `repository/onze` for mocking
**Owns:** `modules/rakun-test/src/**`, `modules/rakun-test/test/**`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` — frozen for the milestone
**Reference:** `11-topicos-avancados.md § Test Auto-configuration Annotations` · `06-messaging.md § Testes com Embedded Kafka` · https://docs.spring.io/spring-boot/reference/testing/

---

## Problem

`Request` is a `behavior` (`repository/rakun/src/http.bp:35-43`). A behavior has no constructor, so a
test cannot build one, so **no rakun front can call a handler directly**. Every handler test in the
milestone must either start a server and speak HTTP to it, or write its own `FakeRequest` — and front
25's example already writes one inline and flags it as this front's to own.
[`../../language-gaps.md`](../../language-gaps.md) records it under *Unowned surface*; this front is where it stops
being unowned.

That is the sharp edge. The blunt one is everything around it. `modules/rakun-test/` is a
`botopink.json` and a `src/root.bp` holding a TODO comment. There is no way to assert on a `Response`
beyond comparing two fields by hand; no way to clear the DI container between two tests in the same
file, so the second test sees the first one's singletons; no way to deliver a message to a listener
without a broker; and no way for CI to answer the one question that matters before a deploy — does
this application actually wire up.

## Current state

- `repository/rakun/modules/rakun-test/src/root.bp` — docblock and `// Module contents will be added by the respective fronts.`
- `repository/rakun/src/http.bp:35-43` — `Request` is a `behavior` with `method`, `path`, `param`, `query`, `header`, `body`. Constructible only by implementing it.
- `repository/rakun/src/runtime.bp:95-108` — `rkDispatch(verb, path)` and `rkDispatchHttp(verb, path, headersJson, queryJson, body)` already dispatch in-process with no socket. `repository/rakun/test/router_test.bp:46-56` already uses `rkDispatch` exactly the way a `MockMvc` would. The dispatch half of this front is thin because the seam is there.
- `repository/onze/src/onze.bp` — a working mocking library: `#[mock]`, `when(...).thenReturn`, `verify(mock, times(n))`, `eq`/`anyInt`/`anyString`, with an erlang arm as well as a node one.
- Tests in this ecosystem are in-file `test` blocks run by `botopink test` and gated by `zig build test-libs` (`repository/rakun/test/*.bp`). **This front does not ship a runner** and does not introduce a second way to run a test; it ships values and helpers used inside the `test` blocks that already work.

## Mechanism

### 1. The `Request` double — the deliverable everything else waits on

```bp
pub type FakeRequest(
    method: HttpMethod,
    path: string,
    params: Array<#(string, string)>,
    queries: Array<#(string, string)>,
    headers: Array<#(string, string)>,
    cookies: Array<#(string, string)>,
    bodyText: string,
) implement Request {
    pub fn param(self: Self, name: string) -> string { … }
    pub fn query(self: Self, name: string) -> string { … }
    pub fn header(self: Self, name: string) -> string { … }
    pub fn body(self: Self) -> string { … }
}
```

`implement Request` is the whole trick, and it works today: `Request` is a behavior, a record may
implement a behavior (`docs.md:243-251`), and a handler declares its parameter as `Request`, so the
double is accepted where the real one is.

Four rules make it a stable API rather than a convenience:

- **It returns `""` for anything absent**, matching the real `Request`'s own convention
  (`repository/rakun/src/http.bp:30-34`). A double that returns an optional where the real one returns
  a string is a double that passes tests the production path would fail.
- **Header lookup is case-insensitive**, because HTTP header names are.
- **Cookies are a first-class field**, not something the test writer has to encode into a `cookie`
  header by hand — front 18's tests need them on every request.
- **Builders, not defaults.** `fakeGet(path)` and `fakePost(path, body)` start it, and
  `.withQuery(n, v)`, `.withHeader(n, v)`, `.withCookie(n, v)`, `.withParam(n, v)` each return a new
  value, so a test names only what it sets.

### 2. Response assertions

```bp
pub fn expectStatus(res: Response, code: i32) -> bool
pub fn expectBodyContains(res: Response, needle: string) -> bool
pub fn expectBodyEquals(res: Response, body: string) -> bool
pub fn expectJsonField(res: Response, field: string, value: string) -> bool
```

Each returns `true` or raises with a message carrying the expected value, the actual value and the
status — `assert expectStatus(res, 200);` fails with *"expected 200, got 404, body: …"* rather than
with *"assertion failed"*. `Response` has only `status` and `body`
(`repository/rakun/src/http.bp:45-73`), so `expectHeader` lives on front 07's response-header
mechanism and is not faked here.

### 3. `MockMvc` — the dispatch helper

A thin typed shell over `rkDispatchHttp`, which already does in-process dispatch with no socket:

```bp
pub type MockMvc(basePath: string) {
    pub fn standalone() -> MockMvc
    pub fn perform(self: Self, req: FakeRequest) -> Response
}
```

`perform` encodes the double's headers and queries the way the real server does and calls
`rkDispatchHttp`, so a `MockMvc` test exercises the *registered route table*, not a method call —
which is the difference between testing a handler and testing routing.

### 4. Slices and context caching

Spring's test slices are annotations that start part of the context. In botopink the slice is already
the module graph: a test file that imports only `#[repository]` types registers only those, because
registration is module-load `@emit`ted `rkScan` (`repository/rakun/src/decorators.bp:48-49`). What is
missing is the other half — clearing it.

```bp
pub fn resetContext() -> i32      // drop singletons, routes, listeners, scheduled tasks
pub fn resetSingletons() -> i32   // drop instances, keep registrations
pub fn contextSnapshot() -> string // scanned names, route paths, listener destinations
```

`resetSingletons()` is what Spring calls context caching from the other end: the registrations are
expensive and stay, the instances are cheap and go, so two tests in a file do not share a counter.

### 5. The in-process broker double

Front 15 registers listeners and exposes `rkDeliver(broker, destination, payload)` — a message pushed
in with no broker running. This front wraps it and adds the send side:

```bp
pub fn deliver(broker: string, destination: string, payload: string) -> i32
pub fn published(broker: string) -> Array<#(string, string)>   // destination, payload
pub fn clearPublished() -> i32
```

so a listener test needs no RabbitMQ, no Kafka and no Redis, and a publish is asserted by reading it
back rather than by watching a queue.

### 6. Boot-and-exit — the CI smoke test

```bp
pub fn bootAndExit(app: App) -> i32
```

Starts the application exactly as `Rakun.run` does — the full component scan, every factory, every
route, listener and task registered, every `#[validated]` configuration record checked by front 14 —
then reports and exits without accepting a connection. Exit code `0` means the application wires up;
non-zero means it does not, with the first failure printed.

This is the check that catches the class of bug unit tests structurally cannot: a missing bean, a DI
cycle, a duplicate route, a listener on a destination two types both claim, an unparseable cron
expression, a configuration violation. All of those are discovered at *wiring* time, and no test that
constructs one component in isolation will ever see them.

### 7. The test-seam convention

A front that keeps mutable state keeps it in the host, where a test cannot read it. The convention for
the whole milestone, stated once here so that the other fronts follow it instead of each inventing
their own:

> **A front that mutates shared state exposes a read-only accessor for tests. It does not make the
> store public, and it does not let a test reach into the host.**

The accessor returns a value, never a handle; it does not clear anything; and it is part of the front's
public surface, so a change to it is a change a review sees. Front 12's `revalidatedPaths()` is the
first instance — a mutation test asserts *what a server action invalidated* without knowing how the
cache stores tags. Front 15's `published(broker)` above is the second. A front that needs a test to
observe its effects and has no such accessor has an untestable effect, which is a design problem rather
than a test problem.

### 8. Mocking is `onze`, not a second layer

`repository/onze` already synthesizes doubles from a `behavior` and verifies calls. Spring's
`@MockBean` is two existing pieces here: `#[mock]` from onze produces the double, and `#[bean]` from
rakun's `#[configuration]` makes it the injected implementation
(`repository/rakun/src/decorators.bp:186-190`). This front documents the pairing and ships no mocking
code. The one thing it adds is `resetSingletons()`, without which a mock registered by one test is
still the injected value in the next.

### Target

erlang. Test helpers that run on the server target, testing server code.

## Steps

### Step 1 — `FakeRequest`

**Acceptance:**
- [ ] `FakeRequest` implements `Request` and is accepted by a handler declaring a `Request` parameter, with no cast. — open on two compiler rows (`language-gaps.md`: an implementer does not convert to its behavior; a behavior method lowers to another type's same-named method on erlang). Today the double does not `implement Request` and a handler takes `fake.toRequest()` — the runtime's own request (`rkMakeRequest`)
- [x] Every accessor returns `""` for an absent name, never an optional. — `paramOf`/`queryOf`/`headerOf`/`cookieOf`/`bodyOf` answer `""` (`modules/rakun-test/test/fake_request_test.bp` "an absent name reads as the empty string"), rakun `203ddb9`
- [x] `header("Content-Type")` and `header("content-type")` return the same value. — `headerOf` lower-cases on store and lookup; the handler's `req.header("Cookie")` too (`fake_request_test.bp` "header names match case-insensitively")
- [x] `withQuery`/`withHeader`/`withCookie`/`withParam` each return a new value, leaving the receiver unchanged. — `fake_request_test.bp` "the builders leave the receiver unchanged"
- [x] `fakeGet("/x").method` is `HttpMethod.Get` and `fakePost("/x", "b").body()` is `"b"`. — `fakePost(…).bodyOf()`, not `body()` (see step 1's first box); `fake_request_test.bp` "fakeGet carries HttpMethod.Get and fakePost the body"
- [x] Front 25's inline `FakeRequest` is deleted and its example imports this one — the duplicate does not survive the milestone. — `25-rakun-route-handlers/examples/route-handler-example.bp` imports `fakeGet`/`fakePost` from `rakun-test` and builds its requests with `toRequest()`

### Step 2 — Response assertions

**Acceptance:**
- [x] Each helper returns `true` on success and raises on failure. — `modules/rakun-test/test/assertions_test.bp` (success block + one `asserts.throwsWith` per helper)
- [x] A failure message carries the expected value, the actual value and the response status. — `expected status 200, got 404, body: …`, `(status N)` on the others — `assertions_test.bp`
- [x] `expectJsonField` finds a top-level string field without a JSON walker, and says plainly in its own docblock that it is a substring check over a known shape rather than parsing — `std/json` has no structured value ([`../../language-gaps.md`](../../language-gaps.md), *Unowned surface*). — substring over `"field":"value"` / `": "`; the docblock in `src/assertions.bp` says so

### Step 3 — `MockMvc`

**Acceptance:**
- [x] `perform` on a registered route returns the handler's `Response`. — `modules/rakun-test/test/mockmvc_test.bp`
- [x] `perform` on an unregistered path returns 404 from the router, not from the helper. — the runtime's `not_found()` (empty body) — `mockmvc_test.bp`
- [x] A path parameter reaches the handler: `perform(fakeGet("/api/users/7"))` gives `req.param("id") == "7"` for a route registered as `/api/users/:id`. — `/mvc/users/:id` → `user 7` — `mockmvc_test.bp`
- [x] Query and header values from the double reach the handler through the real dispatch path. — query, header, cookie and body in one echo — `mockmvc_test.bp`
- [x] No socket is opened — asserted by running the whole suite with no port bound. — `tcp_inet` port count unchanged across `perform` and `rakun.server.bound-port` 0 — `mockmvc_test.bp` "perform opens no socket"

### Step 4 — Context control

**Acceptance:**
- [x] `resetSingletons()` makes the next resolution construct a fresh instance; `rkBuildCount` goes back to zero. — `modules/rakun-test/test/context_test.bp`; core `reset_singletons/0`
- [ ] `resetContext()` empties the scan registry, the route table, the listener registry and the task registry, and a dispatch afterwards returns 404. — scan registry and route table done (`context_test.bp`); the listener and task registries hang off the core's `rkOnReset` once fronts 15 and 16 register theirs
- [x] Two `test` blocks in one file do not share a singleton when the second calls `resetSingletons()` first. — `context_test.bp` "a second test calling resetSingletons first does not share the instance"
- [ ] `contextSnapshot()` reports scanned names, route paths and listener destinations, and is stable across runs. — scanned names and routes, stable (`context_test.bp`); listener destinations read `[]` until front 15 keeps the `rakun_listener_names` term

### Step 5 — The broker double

**Acceptance:**
- [ ] `deliver` reaches a `#[listener]` handler with no broker configured.
- [ ] `published(broker)` returns every destination and payload sent through that arm's template, in order.
- [ ] `clearPublished()` empties the record and two tests do not see each other's publishes.
- [ ] Front 15's container tests run green with every integration cell skipped, entirely through this double.

### Step 6 — `bootAndExit`

**Acceptance:**
- [ ] Exit `0` on an application that wires up; non-zero with the first failure printed otherwise.
- [ ] A missing bean, a DI cycle, a duplicate route, a duplicate listener destination, an unparseable cron expression and a configuration-constraint violation each produce a distinct non-zero exit with a message naming the offending declaration.
- [ ] No port is bound and no broker connection is attempted.
- [ ] The whole run is under two seconds for an application with fifty components — this is a CI gate, and a slow gate gets deleted.

### Step 7 — Documenting the onze pairing

**Acceptance:**
- [ ] The README and `AGENTS.md` show the `#[mock]` + `#[bean]` pairing as the `@MockBean` equivalent, and `modules/rakun-test/src/` contains no mocking implementation of its own. — `AGENTS.md` § Test utilities shows the std-mocks + `#[bean]` pairing and `src/` holds no mocking code; open on `#[mock]` firing outside `mocks.bp` (std), so the pairing is a hand-written double
- [x] A test proves the pairing: a mocked `behavior` is the injected implementation of a controller's dependency, and `verify` sees the handler's call. — `modules/rakun-test/test/mocks_pairing_test.bp` — a hand-written std-mocks double of `UserRepo` from a `#[bean]`, stubbed through `__rkMake_UserRepo()`, a `MockMvc` GET, `mocks.verify(…, times(1))`

## Examples

- [`examples/controller-test-example.bp`](./examples/controller-test-example.bp) — the shape every rakun handler test takes: a `FakeRequest`, a `MockMvc` dispatch, response assertions, an onze-mocked dependency injected by `#[bean]`, and `resetSingletons()` between tests.

## Language gaps

None — every construct in the example parses today. The gap this front exists to *close* — that
`Request` is a behavior and therefore not constructible — is a library gap, not a language one, and it
is closed here.

## Test plan

`modules/rakun-test/test/` on the **erlang** target, via
`zig build test-libs -- --target erlang --lib rakun`. This front's own tests test the helpers; every
other rakun front's tests use them, which is the real coverage.

| File | Asserts |
|---|---|
| `test/fake_request_test.bp` | Behavior conformance, absent-name convention, case-insensitive headers, builder immutability |
| `test/assertions_test.bp` | Success and failure of each helper, and the content of each failure message |
| `test/mockmvc_test.bp` | Registered dispatch, 404, path parameters, query and header propagation, no socket |
| `test/context_test.bp` | Both resets, cross-test isolation, snapshot stability |
| `test/broker_test.bp` | Delivery without a broker, publish recording and ordering, clearing |
| `test/boot_test.bp` | Exit zero, and one distinct non-zero per wiring failure class |
| `test/onze_pairing_test.bp` | A mocked behavior injected by `#[bean]` and verified through a dispatched request |

**This front ships no runner.** Tests here are in-file `test` blocks run by `botopink test` and gated
by `zig build test-libs`, exactly as `repository/rakun/test/*.bp` and `repository/onze/test/*.bp`
already are. A second runner would be a second answer to a question the ecosystem has answered.

There is no commonJS row; this front is server-only by the milestone's target split.

## Out of scope

- **A mocking library** — `repository/onze` is it. This front documents the pairing.
- **Testcontainers-style external services** — starting a real broker or database from a test. Integration cells are gated on an environment variable and reported as *skipped*; orchestrating the service is CI's job.
- **Property-based testing and fixtures/factories** — no consumer in this milestone.
- **Benchmarking** — front 75 owns measurement.
- **A browser test driver** — client fronts test in their own target; nothing here compiles for js.

## Definition of done

- `FakeRequest` exists, implements `Request`, and front 25's inline copy is deleted in the same milestone.
- `MockMvc` dispatches through the real route table with no socket.
- `resetContext` and `resetSingletons` exist and are used by at least two other fronts' suites.
- The broker double carries front 15's container tests with every integration cell skipped.
- `bootAndExit` distinguishes six wiring-failure classes and runs in under two seconds.
- The test-seam convention is stated in `repository/rakun/AGENTS.md`, with `revalidatedPaths()` and `published()` named as its instances.
- No runner, and no mocking implementation, is added by this front.
- The front's tests are green on erlang.

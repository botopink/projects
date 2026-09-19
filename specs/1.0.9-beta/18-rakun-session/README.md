# Front 18 — Rakun Session Management

**Track:** B rakun
**Priority:** low as a feature, high as a security surface — front 12's private cache scope keys on the session id, so a weak session here weakens the cache too
**Target:** erlang (server)
**Wave:** 4
**Depends on:** 01 (`random`, `hmac`, constant-time compare), 05 (config), 06 (context), 07 (the filter chain the session filter joins), 08 (`datasource`, for the SQL arm), 11 (endpoint host + health registry), 62 (per-request context)
**Owns:** `modules/rakun-session/src/**`, `modules/rakun-session/test/**`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` — frozen for the milestone
**Reference:** `04-web.md § Spring Session` · https://docs.spring.io/spring-boot/reference/web/spring-session.html
**Replaces:** `1.0.6-beta/14-session-management`

---

## Problem

rakun has no session. A handler that needs to remember anything between two requests from the same
browser has nowhere to put it, and `modules/rakun-session/` is a `botopink.json` and a `src/root.bp`
holding a TODO comment. `Request` can read a header (`repository/rakun/src/http.bp:39`) but has no
cookie accessor, and `Response` is a status and a body with no header surface at all
(`repository/rakun/src/http.bp:45-73`), so there is not even a way to set a cookie today.

The 1.0.6-beta draft this replaces had the right nouns and a design that cannot be built. Its
`InMemorySessionRepository` was a `#[component]` with one method and three unimplemented ones, its
session id was `generateUuid()` with no generator named, its signing was absent entirely — a session
cookie whose value is the raw store key lets anyone with a key guess another — and its `SessionFilter`
read `request.cookie("SESSION")`, an accessor that does not exist on a frozen interface.

The security properties are the deliverable here. A session store is easy; a session store whose ids are
unguessable, whose cookies are tamper-evident, whose comparison is not a timing oracle, and whose id
rotates on privilege change is the thing worth writing down.

## Current state

- `repository/rakun/modules/rakun-session/src/root.bp` — docblock and `// Module contents will be added by the respective fronts.`
- `repository/rakun/src/http.bp:35-43` — `Request` has `param`, `query`, `header`, `body`. No cookie accessor. The file is frozen, so cookie parsing happens in this module over `req.header("cookie")`.
- `repository/rakun/src/http.bp:45-73` — `Response` has six builders and no header surface. Setting `Set-Cookie` needs front 07's response-header mechanism; this front produces the header value and hands it over.
- `libs/std/src/crypto.bp:38` — `hmacSha256(key, data) -> string` already exists. `crypto.bp:77` — `randomBytes(n) -> string`. Both are usable today; front 01 adds base64url of a raw digest and a **constant-time compare**, which this front requires and which std does not have.
- `libs/std/src/time.bp:56` — `nowMillis()` exists, so expiry arithmetic needs no new primitive.

## Mechanism

### The session value is immutable, and that is a language gap

```bp
pub type Session(
    id: string,
    principal: string,
    attributes: Array<#(string, string)>,
    createdAt: i64,
    lastAccessedAt: i64,
    maxInactiveSeconds: i32,
) {
    pub fn attribute(self: Self, name: string) -> string
    pub fn withAttribute(self: Self, name: string, value: string) -> Session
    pub fn withoutAttribute(self: Self, name: string) -> Session
    pub fn isExpired(self: Self, nowMillis: i64) -> bool
}
```

Spring writes `session.setAttribute("cart", cart)`. botopink has no assignment to a `self` field —
there is not one in any real library in the tree, and every record in std is replaced rather than
mutated (`dict.insert` returns a new dict). So a mutation is `val next = session.withAttribute(…)`
followed by `store.save(next)`, and forgetting the save is a bug the compiler cannot catch. That is
recorded in *Language gaps*; it is not worked around, because the workarounds are worse than the
threading.

### Three store arms, one behavior

```bp
pub behavior SessionStore {
    fn create(self: Self, principal: string) -> Session;
    fn save(self: Self, session: Session) -> i32;
    fn findById(self: Self, id: string) -> ?Session;
    fn deleteById(self: Self, id: string) -> i32;
    fn findByPrincipal(self: Self, principal: string) -> Array<Session>;
    fn deleteExpired(self: Self, nowMillis: i64) -> i32;
}
```

| Arm | Key | Backing | Survives |
|---|---|---|---|
| `ets` (default) | `rakun.session.store=ets` | An ETS table under rakun's supervisor | nothing — a node restart drops every session |
| `redis` | `rakun.session.store=redis` | Front 13's Redis client, one key per session with a server-side TTL | a node restart, and shared across the cluster |
| `sql` | `rakun.session.store=sql` | Front 08's `datasource`, one row per session in `rakun.session.sql.table-name` (default `SESSIONS`) | everything, and it is queryable |

The three are Spring's three (`04-web.md § Spring Session`: Redis servlet, JDBC, Redis reactive), minus
the reactive/servlet split, which does not exist on the BEAM — see *Reactive variants* below. The SQL
arm owns its schema and ships the DDL; it does not create tables at run time unless
`rakun.session.sql.initialize-schema=always`, mirroring `spring.session.jdbc.initialize-schema`.

Expired rows are swept by a `#[fixedDelay]` task from front 16, not by a timer this module owns.

### Ids, signing and comparison

Three rules, and each of them exists because the obvious implementation is wrong.

1. **The id is 32 random bytes**, from front 01's `random`, rendered base64url. Not a UUID: a v4 UUID
   carries 122 bits in a shape that invites a v1 to be substituted later, and there is no reason to
   spend the ambiguity.
2. **The cookie is signed, not bare.** Its value is `<id>.<base64url(hmacSha256(secret, id))>` with the
   secret from `rakun.session.secret`. An unsigned cookie means the store must be probed for every
   forged value a scanner sends; a signed one is rejected before it reaches the store. The secret has
   no default — boot fails when the store is enabled and the key is unset, because a default signing
   key is the same as no signing.
3. **The comparison is constant time.** Verifying the signature with `==` leaks the matching prefix
   length through timing, which is a practical forgery oracle over enough requests. Front 01 provides
   the constant-time compare; this front uses it, and a test asserts that `==` does not appear in the
   verification path.

### Cookie attributes: restrictive, and not configurable down

| Attribute | Value | Configurable |
|---|---|---|
| `HttpOnly` | always set | no |
| `Secure` | always set, except structurally (below) | no |
| `SameSite` | `Lax` | `Lax` or `Strict` only; `None` is refused unless `Secure` is set, and is never the default |
| `Path` | `/` | `rakun.session.cookie.path` |
| `Max-Age` | `rakun.session.timeout` (default 30m) | yes |
| name | `SESSION` | `rakun.session.cookie.name` |

There is no `rakun.session.cookie.http-only=false` and no `rakun.session.cookie.secure=false`. The one
exemption to `Secure` is structural rather than a flag: it is omitted when the listener is not TLS
**and** it is bound to a loopback address — a condition the runtime knows without being told, which is
true on a developer's machine and false everywhere else. A deployment that terminates TLS at a proxy
sets `rakun.server.forwarded-proto=true` and keeps `Secure`; it does not get a switch that turns the
attribute off.

### Rotation on privilege change

`rotate(session)` issues a new id, copies the attributes, saves under the new id and deletes the old.
Front 10's authentication calls it on every successful login and on every privilege change. Without it,
an attacker who plants a known session id before login holds a valid authenticated session afterwards —
session fixation, and it is the one session bug that is invisible in normal use.

### The filter

A `SessionFilter` in front 07's chain, ordered before authentication: read `cookie`, verify the
signature, load the session, put it on front 62's per-request context, and on the way out write
`Set-Cookie` when the session is new or rotated. Handlers never parse a cookie and never write one; they
call `currentSession()`.

### Reactive variants

Spring documents a servlet session and a reactive session as separate starters. There is no such split
here, and not because it was skipped: on the BEAM a request is a process and a blocking store call
costs a process that waits, so the blocking API *is* the concurrent one. Where a future-returning form
is genuinely wanted it is one extra method on the same store, not a second stack — and `@Future` lowers
eagerly on erlang (`libs/std/src/http.bp:16-18`), so such a method would buy nothing at all today.

## Steps

### Step 1 — The session value and the store behavior

**Acceptance:**
- [ ] `withAttribute` returns a new session and leaves the receiver unchanged.
- [ ] `withAttribute` on an existing name replaces it rather than appending a second pair.
- [ ] `attribute` on a missing name returns `""`, matching `Request`'s convention rather than introducing a second one.
- [ ] `isExpired` is computed from `lastAccessedAt + maxInactiveSeconds`, against a clock passed in — not read inside, so it is testable without waiting.
- [ ] `SessionStore` is a `behavior`; no `type` body in this module contains a bodyless method.

### Step 2 — Ids, signing and verification

**Acceptance:**
- [ ] An id is 32 bytes of randomness rendered base64url; two ids generated in the same millisecond differ.
- [ ] A cookie whose signature does not match is rejected without the store being touched — asserted by a store double that counts lookups.
- [ ] A cookie with a valid signature for a deleted session is rejected as *not found*, distinctly from *bad signature*, and both produce the same response to the client.
- [ ] Verification uses front 01's constant-time compare; a test greps the verification path and fails on a `==` between the computed and supplied signatures.
- [ ] With the store enabled and `rakun.session.secret` unset, boot fails naming the key.
- [ ] Rotating the secret invalidates existing cookies and does not crash on them.

### Step 3 — The three store arms

**Acceptance:**
- [ ] The same store test suite runs against all three arms and passes unchanged — the arms are interchangeable or one of them is wrong.
- [ ] `findByPrincipal` returns every live session for a principal and no expired one.
- [ ] `deleteExpired` removes only expired sessions and reports how many.
- [ ] The SQL arm ships DDL and does not create its table unless `initialize-schema=always`.
- [ ] The Redis arm sets a server-side TTL equal to the session timeout, so an abandoned session expires even if the sweeper never runs.
- [ ] The ETS arm's table survives a worker crash — it is owned by the supervisor, not by a worker.

### Step 4 — Cookie emission

**Acceptance:**
- [ ] The emitted header carries `HttpOnly`, `Secure`, `SameSite=Lax`, `Path=/` and `Max-Age` by default.
- [ ] `Secure` is present when the listener is TLS, present when `forwarded-proto` is set, and absent only when the listener is plain and bound to loopback.
- [ ] `SameSite=None` without `Secure` refuses the boot.
- [ ] There is no configuration key in this module that removes `HttpOnly` or `Secure`; a grep for `http-only` and `secure` in the module finds documentation and tests, never a flag.

### Step 5 — Rotation and the filter

**Acceptance:**
- [ ] `rotate` produces a new id, preserves every attribute, and the old id is not found afterwards.
- [ ] A session fixation attempt — a request presenting a known id, then authenticating — ends with a different id in the response cookie. This test is the reason the function exists.
- [ ] The filter runs before authentication in front 07's chain.
- [ ] A handler reading `currentSession()` sees the loaded session without parsing a header.
- [ ] A request with no cookie gets a session only when a handler asks for one — an anonymous GET of a static route creates nothing.
- [ ] `lastAccessedAt` is updated at most once per request.

### Step 6 — The `sessions` endpoint and health

```bp
// GET    /actuator/sessions?principal=alice -> that principal's sessions, ids truncated
// DELETE /actuator/sessions/{id}            -> end one session
pub fn sessionsEndpoint(req: Request) -> Response

// Registered with front 11 under "session".
pub fn sessionHealth() -> HealthReport
```

Listing sessions is a disclosure surface and deleting one is a denial surface, so both sit behind front
11's access control with no separate opt-out here. Session ids are truncated in the listing — an
operator needs to count sessions and end one they were given, not to read a valid credential out of a
monitoring dashboard.

**Acceptance:**
- [ ] The listing reports creation time, last access, expiry and attribute *names* — never attribute values, which may hold anything an application put there.
- [ ] Ids appear truncated, and the untruncated id is never in a response body.
- [ ] `DELETE` ends the session and the next request with that cookie is unauthenticated.
- [ ] Both routes are refused with front 11's standard response when unauthorized.
- [ ] `sessionHealth()` reports DOWN naming the arm when the configured store is unreachable.

## Examples

- [`examples/session-cart-example.bp`](./examples/session-cart-example.bp) — a shopping cart across requests: reading the session, the immutable update, the save, and the rotation on login.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| There is no assignment to a `self` field, so `session.setAttribute("cart", v)` has no spelling and a mutation cannot be self-persisting. | `examples/session-cart-example.bp`, every `withAttribute` call | Return a new `Session` and save it explicitly: `val next = s.withAttribute(k, v); store.save(next);`. Forgetting the save is a bug the compiler cannot catch. | Mutable record fields, or a handle type whose methods write through to the store |
| Declared parameter defaults are never applied, so the cookie builder cannot default its attributes the way a fluent `ResponseCookie.from(name, value)` does. | `sessionCookieHeader(...)` in the example | One call, every argument named. | Apply declared defaults at call sites (`docs.md:502-505`) |

## Test plan

`modules/rakun-session/test/` on the **erlang** target, via
`zig build test-libs -- --target erlang --lib rakun`.

| File | Asserts |
|---|---|
| `test/session_test.bp` | Immutable updates, attribute replacement, expiry arithmetic against a passed-in clock |
| `test/signing_test.bp` | Id entropy, signature rejection without a store lookup, the two distinct failures, the constant-time grep, the missing-secret boot refusal, secret rotation |
| `test/store_test.bp` | One suite run three times, once per arm; `findByPrincipal`, `deleteExpired`, the SQL DDL guard, the Redis TTL, the ETS table owner |
| `test/cookie_test.bp` | Default attributes, the structural `Secure` exemption, the `SameSite=None` refusal, the no-flag grep |
| `test/rotation_test.bp` | Rotation, and the session-fixation scenario end to end |
| `test/endpoint_test.bp` | Listing shape and truncation, deletion, refusal when unauthorized, health UP and DOWN |

The Redis arm runs against a live Redis when `RAKUN_TEST_REDIS_URL` is set and reports *skipped*
otherwise; the SQL arm runs against front 08's test datasource; the ETS arm always runs. A suite in
which two of three arms are skipped is reported as such and is not a pass of this front.

There is no commonJS row; this front is server-only by the milestone's target split.

## Out of scope

- **Authentication and authorization** — who the principal is, and what they may do, is front 10. This front holds a session for whoever front 10 says is there.
- **CSRF tokens** — a session-bound token belongs with front 10's security filters, next to the rest of the request-forgery story.
- **Distributed session locking** — concurrent writes to one session from two nodes last-write-wins. A locking story needs a consumer and has none in this milestone.
- **Hazelcast and JDBC-reactive session arms** — the JVM clustering products have no BEAM meaning, for the same reasons front 12 records about cache providers.

## Definition of done

- Three arms behind one behavior, proven by one suite that runs against all three.
- Ids are 32 random bytes; cookies are HMAC-signed; verification is constant time and a test enforces it.
- `HttpOnly` and `Secure` have no off switch, and the one `Secure` exemption is structural.
- `rotate` exists and the session-fixation test passes.
- The `sessions` endpoint and the `session` health indicator are registered with front 11, refused when unauthorized, and never emit an untruncated id or an attribute value.
- Every `// LANGUAGE GAP:` marker in the example appears in the table above.
- `repository/rakun/AGENTS.md` and `modules/README.md` record the module's surface in the same commit.
- The front's tests are green on erlang.

# Front 20 — Rakun WebSocket

**Track:** B rakun
**Priority:** low — nothing else in the milestone depends on it, and an application that needs push today polls
**Target:** erlang (server)
**Wave:** 5
**Depends on:** 01 (`io.net`), 04 (the BEAM runtime and its supervision tree), 05 (config), 06 (context), 07 (the HTTP path the upgrade happens on), 10 (authorization at upgrade), 11 (health registry), 62 (per-request context)
**Owns:** `modules/rakun-web/src/websocket/**`, `modules/rakun-web/test/websocket/**`
**Does not touch:** `modules/rakun-web/src/*.bp` — front 07 owns those, and this front adds no arm to its filter chain. `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` are frozen for the milestone
**Reference:** `02-desenvolvendo-com-spring-boot.md § Starters` (`spring-boot-starter-websocket`) · `06-messaging.md § RSocket` (the WebSocket transport) · https://docs.spring.io/spring-framework/reference/web/websocket.html

---

## Problem

rakun speaks request and response. An application that needs to tell a browser something — a price
changed, a job finished, another user typed — has no way to do it except to have the browser ask
again. `modules/rakun-web/src/websocket/` does not exist; `modules/rakun-web/` is a `botopink.json` and
a `src/root.bp` with a TODO comment.

## Which side each API lives on

This is the first thing to settle, because the draft got it wrong and the milestone's target rule is
not negotiable per front.

| API | Side | Where it lives |
|---|---|---|
| `#[wsEndpoint("/ws/chat")]`, `WsHandler`, `WsSession`, `send`, `close` | **erlang (server)** | this front |
| `broadcast(topic, message)`, `subscribe(session, topic)`, `unsubscribe` | **erlang (server)** | this front |
| The upgrade handshake, the session registry, heartbeats, backpressure | **erlang (server)** | this front |
| The wire contract — subprotocol name, message envelope, heartbeat interval, close codes | **the boundary** | defined here, consumed by the browser |
| `new WebSocket(url)`, `onmessage`, `send`, reconnection with backoff | **js (client)** | **not this front** |

**This front ships no JavaScript.** Not one line, not a sidecar, not an `@External.Node` cell — the
exit gate checks for that. The browser half of a WebSocket is the browser's own `WebSocket` object,
which needs no library to use; what it needs is a documented contract, and that is what the *Wire
contract* section below is. A typed client helper — a hook that reconnects, a store that fans messages
into components — is jhonstart or onze surface and would be its own front, with its own target line
saying `js (client)`. Building it here would put a client front's code inside a server front's
directory, which is exactly the shape `overview.md` forbids.

## Current state

- `repository/rakun/modules/rakun-web/src/` holds front 07's chain; the `websocket/` subtree does not exist.
- `repository/rakun/src/runtime.bp:110-117` — `rkServe(port, dispatcher)` takes a dispatcher over five scalars and returns a `Response`. There is no upgrade path through it: a 101 response has no body and keeps the socket, which that signature cannot express. The upgrade is handled by front 04's BEAM listener before dispatch, not by returning a special `Response`.
- `repository/rakun/src/http.bp:12-20` — `HttpMethod` has seven variants and none of them is relevant; an upgrade is a GET with headers.
- Nothing in the tree tracks a long-lived connection. Every rakun process today lives for one request.

## Mechanism

### Upgrade

An upgrade is a GET carrying `Upgrade: websocket`, `Connection: Upgrade`, `Sec-WebSocket-Key` and
`Sec-WebSocket-Version: 13`. Front 04's listener recognises it before the router runs and hands the
socket to `cowboy_websocket`, whose `init/2` returns `{cowboy_websocket, Req, State}`. The route table
is consulted for a registered `#[wsEndpoint]` path; an unregistered path gets a 404 and the socket
closes normally rather than hanging.

Authorization happens **at the upgrade, once**, through front 10 on the HTTP request that carries it —
the last moment at which there are still headers and a cookie to authorize with. A frame arriving four
minutes later carries no credentials and cannot be re-authorized; a connection whose principal's
session is revoked is closed by front 18's revocation path rather than checked per frame.

### The handler

```bp
pub behavior WsHandler {
    fn onOpen(self: Self, session: WsSession) -> i32;
    fn onMessage(self: Self, session: WsSession, message: string) -> i32;
    fn onClose(self: Self, session: WsSession, code: i32, reason: string) -> i32;
}

pub type WsSession(id: string, principal: string, path: string) {
    pub fn send(self: Self, message: string) -> i32
    pub fn close(self: Self, code: i32, reason: string) -> i32
}
```

`WsSession` is a record with real method bodies over host cells keyed by the session id — not a record
with bodyless methods, which is what the draft wrote and what does not parse.

`#[wsEndpoint("/ws/chat")]` on a type walks its methods for `onOpen`/`onMessage`/`onClose` and
`@emit`s one registration, the same shape `#[restController]` uses for routes
(`repository/rakun/src/decorators.bp:155-166`). A type missing `onMessage` is refused at comptime; the
other two are optional and default to no-ops the decorator emits.

### One process per connection

A connection is a BEAM process. It holds the socket, the session id and the handler's component
instance reference, and it is supervised: a handler that raises kills its own connection and nobody
else's. There is no pool and no thread; `rakun.websocket.max-connections` caps how many may exist and
is enforced at upgrade, with a 503 rather than an accepted socket that is then closed.

### Topics and broadcast

```bp
pub fn subscribe(session: WsSession, topic: string) -> i32
pub fn unsubscribe(session: WsSession, topic: string) -> i32
pub fn broadcast(topic: string, message: string) -> i32
pub fn sessionsOn(topic: string) -> i32
```

Backed by OTP `pg` (process groups), which is distribution-aware out of the box: `broadcast` on one
node reaches subscribers on every connected node with no extra machinery. An ETS table would have been
the single-node answer and would have had to be replaced the first time the application scaled, so it
is not the starting point.

`broadcast` is fire-and-forget and returns how many sessions it was sent to. It does not wait for
delivery, because waiting for a slow client is how one slow client stalls a broadcast to a thousand
fast ones.

### Backpressure and heartbeats

A connection whose outbound queue exceeds `rakun.websocket.max-outbound-queue` (default 1000 frames)
is closed with code `1013` rather than allowed to grow — an unbounded mailbox on a process nobody is
draining is a memory leak with a timer on it.

The server sends a ping every `rakun.websocket.heartbeat-seconds` (default 30) and closes a connection
that has not answered within `rakun.websocket.idle-timeout-seconds` (default 90). Both are in the wire
contract, because a browser client that does not know them will reconnect on a schedule that fights
the server's.

### Wire contract

The part the browser has to agree with, stated once so both halves can be written against it:

| Item | Value |
|---|---|
| Subprotocol | `rakun.v1` — sent in `Sec-WebSocket-Protocol` and echoed; a client that omits it is accepted, one that offers an unknown one is refused at upgrade |
| Message frame | Text. `{"t":"<topic>","d":"<payload>"}` for a topic message; `{"t":"","d":"<payload>"}` for a direct one |
| Heartbeat | Server sends ping every 30s; client answers pong. No application-level ping frame |
| Close codes | `1000` normal · `1008` unauthorized · `1013` backpressure · `1011` handler error · `4001` session revoked |
| Max frame | `rakun.websocket.max-frame-bytes`, default 65536; a larger frame closes with `1009` |

Payloads are text. There is no byte or binary type in botopink
([`../../language-gaps.md`](../../language-gaps.md)), so a binary frame cannot be represented without corrupting it
and is refused at the arm rather than read lossily.

### Target

erlang. `cowboy_websocket` and `pg` are OTP; the module contains no `@External.Node` cell and no `.mjs`
sidecar, and the exit gate checks it.

## Steps

### Step 1 — Upgrade and the connection process

**Acceptance:**
- [ ] A GET with the four upgrade headers on a registered path answers 101 and keeps the socket.
- [ ] The same request on an unregistered path answers 404 and closes.
- [ ] An upgrade that front 10 refuses closes with `1008` and never reaches a handler.
- [ ] One connection is one supervised process; a handler that raises closes that connection with `1011` and leaves every other connection open.
- [ ] `max-connections` is enforced at upgrade with 503, not by closing an accepted socket.

### Step 2 — `#[wsEndpoint]` and the handler

**Acceptance:**
- [ ] `#[wsEndpoint]` on anything but a record-shaped type fails with a located message.
- [ ] A type without `onMessage` is refused at comptime, naming the missing method.
- [ ] Missing `onOpen` and `onClose` are emitted as no-ops.
- [ ] The emitted registration builds the component through `__rkMake_<Type>()`, so one instance serves every connection and a stacked `#[service]` shares it with the rest of the application.
- [ ] Two endpoints on the same path are refused at boot with both type names in the message.

### Step 3 — Sessions, topics and broadcast

**Acceptance:**
- [ ] `session.send` reaches exactly that connection.
- [ ] `broadcast(topic, msg)` reaches every subscriber and returns the count.
- [ ] A closed session is removed from every topic without the broadcaster noticing.
- [ ] `broadcast` on a two-node cluster reaches subscribers on both nodes.
- [ ] `subscribe` twice on the same topic is idempotent.

### Step 4 — Backpressure, heartbeats and limits

**Acceptance:**
- [ ] A connection that stops reading is closed with `1013` once its queue passes the cap, and the cap is reached in bounded memory.
- [ ] A connection that does not answer a ping is closed after the idle timeout.
- [ ] A frame over `max-frame-bytes` closes with `1009`.
- [ ] A binary frame is refused with a named error rather than decoded.
- [ ] Every close code in the wire-contract table is produced by a test that triggers its condition.

### Step 5 — Health

```bp
// Registered with front 11 under "websocket".
pub fn websocketHealth() -> HealthReport
```

**Acceptance:**
- [ ] The report carries open connections, topic count, and connections refused by the cap since boot.
- [ ] It is DOWN when the listener is not accepting upgrades and UP otherwise.

## Examples

- [`examples/chat-endpoint-example.bp`](./examples/chat-endpoint-example.bp) — a chat endpoint: upgrade, per-connection state, topic subscription, broadcast from a handler and from an HTTP controller, and the wire contract in the header comment for the browser half.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| There is no byte or binary type, so a binary WebSocket frame cannot be represented. Recorded in [`../../language-gaps.md`](../../language-gaps.md). | `onMessage` in the example | Text frames only; a binary frame is refused at the arm with a named error. | A `Bytes` primitive with a declared encoding boundary |

## Test plan

`modules/rakun-web/test/websocket/` on the **erlang** target, via
`zig build test-libs -- --target erlang --lib rakun`.

| File | Asserts |
|---|---|
| `test/websocket/upgrade_test.bp` | 101 on a registered path, 404 otherwise, `1008` on refusal, 503 at the cap |
| `test/websocket/endpoint_test.bp` | Decorator synthesis, the missing-`onMessage` refusal, no-op defaults, duplicate-path refusal, one component instance |
| `test/websocket/broadcast_test.bp` | Direct send, fan-out and count, removal on close, idempotent subscribe, the two-node case |
| `test/websocket/limits_test.bp` | Backpressure close, heartbeat timeout, oversize frame, binary refusal, every close code |
| `test/websocket/health_test.bp` | Report content, UP and DOWN |

Connections in tests are made by an in-process client built on front 01's `net` against a listener on
an ephemeral port, so the suite needs no browser and no external tool. The two-node broadcast test
starts a second BEAM node with `slave`/`peer` and is skipped with a reported cell when the runner
cannot start one.

**There is no js row, and its absence is not a coverage hole in this front.** The browser half is the
browser's own `WebSocket` object; what this front owes it is the wire contract, and the contract is
asserted here — subprotocol, frame shape, heartbeat interval and every close code are literals in
`limits_test.bp`. A client front that later ships a typed helper asserts the same literals on its
side, which is how the two halves are kept in step.

## Out of scope

- **The browser client** — `new WebSocket`, reconnection, backoff, a hook. That is `js (client)` surface and belongs to a jhonstart or onze front, not to a directory under `rakun/`.
- **STOMP** — a messaging protocol over the transport. If it is wanted it is front 15's registry with a WebSocket arm, not a second protocol stack here.
- **SockJS fallback** — long-polling emulation for browsers that predate WebSocket. Every browser in the milestone's support matrix has WebSocket.
- **RSocket** — front 92, which may use this transport.
- **Server-sent events** — one-directional push over plain HTTP. It shares nothing with this front's machinery and belongs with front 25's streaming responses.

## Definition of done

- Upgrade, one supervised process per connection, and authorization at the handshake.
- `#[wsEndpoint]` synthesis with the `onMessage` requirement enforced at comptime.
- Topics and broadcast over `pg`, working across two nodes.
- Every limit in the wire-contract table enforced and tested by triggering its condition.
- The wire contract recorded in `repository/rakun/AGENTS.md` so the browser half can be written against it.
- Not one line of JavaScript, no `.mjs` sidecar, and no `@External.Node` cell in the module.
- Every `// LANGUAGE GAP:` marker in the example appears in the table above.
- The front's tests are green on erlang.

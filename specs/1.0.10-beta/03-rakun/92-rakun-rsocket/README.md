# Front 92 — Rakun RSocket

**Track:** B rakun
**Priority:** low — an elegant protocol with modest adoption, and nothing else in the milestone depends on it
**Target:** erlang (server) — the browser half would be a client front and is out of this scope
**Wave:** 6
**Depends on:** 20 (the WebSocket transport and its upgrade path), 07 (the filter chain the WebSocket mapping path sits behind), 15 (the listener registry `#[messageMapping]` registers on), 86 (the outcome contract for fire-and-forget), 02 (the thunk-and-gather pattern a requester needs, because `@Future` carries no concurrency on BEAM), 01 (`net`), 74 (TLS)
**Owns:** `modules/rakun-rsocket/src/**`, `modules/rakun-rsocket/test/**`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` — frozen for the milestone. `modules/rakun-web/src/websocket/**` is front 20's and is consumed read-only.
**Reference:** `06-messaging.md § RSocket` (Server, Client) · `§ Spring Integration · RSocket com Integration` · https://docs.spring.io/spring-boot/reference/messaging/rsocket.html · https://rsocket.io/about/protocol
**Replaces:** new

---

## Problem

Spring Boot 4 ships an RSocket server on its own TCP port or over a WebSocket mapping path, plus an
`RSocketRequester` client (`06-messaging.md § RSocket`). rakun has neither. An application that must
speak to an existing RSocket endpoint — or expose one — has no path at all.

The interesting part is not the absence; it is the premise. RSocket exists because HTTP request/
response is one interaction model and reactive systems need four: fire-and-forget, request/response,
request/stream and channel. On the JVM that requires a reactive stack — `Mono`, `Flux`, a scheduler,
an operator library — and Spring's RSocket support is inseparable from Reactor. That is exactly the
kind of dependency this milestone does not port, and the reason is in the milestone's own
architecture: on BEAM the four models are four shapes of process, not four types in a library.

## Current state

- `repository/rakun/modules/` holds no `rakun-rsocket`. The directory this front owns does not exist.
- `repository/rakun/modules/rakun-web/src/root.bp` — a stub; front 20 lands the WebSocket upgrade
  this front's second transport stands on.
- [`language-gaps.md`](../../language-gaps.md) records **`@Future<T>` lowers eagerly on erlang** — the
  type carries no concurrency on the server target — and **no byte or binary type**. Both decide the
  design below rather than complicating it.
- There is no socket server in rakun other than whatever `rkServe` sets up for HTTP
  (`repository/rakun/src/runtime.bp:19-117`).

## Mechanism

**The four interaction models, on BEAM.** This is the whole design, and it needs no reactive stack.

| Model | RSocket frames | On BEAM | What the developer writes |
|---|---|---|---|
| Fire-and-forget | `REQUEST_FNF` | the connection process spawns a handler process and forgets it; nothing is sent back | a handler returning `Outcome` — the same contract front 86 defines for a broker message |
| Request/response | `REQUEST_RESPONSE` → one `PAYLOAD` | one process per stream id; the handler runs in it and its return value is framed back | a handler returning a plain value; the *requester* is handed `@Future<T>` and awaits it |
| Request/stream | `REQUEST_STREAM`, `REQUEST_N`, `PAYLOAD`… | one producer process holding a credit counter; `REQUEST_N` increments it, each emission decrements it | a handler returning a `StreamHandle`; the requester calls `request(n)` and `next()` |
| Channel | `REQUEST_CHANNEL` in both directions | two of the above over one stream id — a process pair, each holding the other's credit | a handler over a `StreamHandle` in and a `StreamHandle` out |

**`@Future` is the return shape, not the scheduler.** The milestone verified that `@Future<T>` lowers
eagerly on erlang: awaiting it does not make anything concurrent. So a requester issuing one call
gets `@Future<string>` because that is the honest type of "a value that is not here yet", and the
concurrency comes from where it always comes from on BEAM — the connection process spawned per
stream. A requester issuing *several* calls at once uses front 02's pattern directly: an array of
unstarted thunks `Array<fn() -> @Future<T>>`, one process per thunk, gathered by index. That is the
same workaround front 02 exists to provide, cited rather than reinvented, and it is why this front's
example builds its parallel calls as thunks instead of as three `await`s in a row.

**Reactive Streams' back-pressure is RSocket's `REQUEST_N`, and `REQUEST_N` is demand.** That is
literally the signal front 89's GenStage stages exchange. A request/stream handler is a producer with
a credit counter: it may emit only what has been asked for, and a consumer that stops asking stops
the producer without a cancellation race. Lease (`LEASE` frames) is the same idea one level up — a
responder grants a budget of requests over a window, and a requester that exceeds it is rejected
locally rather than at the responder. Neither needs an operator library; both are integer accounting
in a process.

**The wire lives in Erlang, like every other socket front here.** RSocket frames are a 24-bit length
prefix (on TCP; the WebSocket frame is the boundary over WS), a 31-bit stream id, a frame type, flags
and a payload split into metadata and data. With no byte type and no bitwise operators
([`language-gaps.md`](../../language-gaps.md)), the codec is one `#[@External.Erlang]` module and the
botopink half is the façade.

**How big.** No BEAM RSocket implementation exists, so this front writes one — but it is the small
end of protocol work: twelve frame types (`SETUP`, `KEEPALIVE`, `LEASE`, `REQUEST_FNF`,
`REQUEST_RESPONSE`, `REQUEST_STREAM`, `REQUEST_CHANNEL`, `REQUEST_N`, `CANCEL`, `PAYLOAD`, `ERROR`,
`METADATA_PUSH`), no protobuf, no checksum, and both transports already available — `gen_tcp`/`ssl`
from front 01 and the WebSocket upgrade from front 20. Roughly a week of protocol work plus the
process model, against Pulsar's two to three. `RESUME` and `RESUME_OK` are refused: session
resumption doubles the state machine for a case a BEAM responder rarely needs, and a refusal in the
`SETUP` response is a defined protocol answer rather than a silent gap.

**Routing is metadata, and `#[messageMapping]` is a fifth arm on front 15's registry.** RSocket's
routing metadata mime type `message/x.rsocket.routing.v0` carries a length-prefixed route tag;
`#[messageMapping("user.byId")]` registers that tag on the same registry AMQP, Kafka, JMS and Pulsar
register on, tagged `rsocket`. One registry holds every non-HTTP entry point, so `rakun routes`
(front 88) and the `mappings` endpoint see RSocket routes alongside the rest, and the dispatch,
concurrency and failure policy come from fronts 15 and 86 rather than from a second mechanism here.

**Target.** Server only. Host cells are `#[@External.Erlang]` over `gen_tcp`, `ssl` and front 20's
WebSocket. A browser RSocket client would be a `js` front and is explicitly out of scope — this front
ships no JavaScript.

## Steps

### Step 1 — The frame codec

**Acceptance:**
- [ ] All twelve frame types encode and decode, asserted against captured frames checked into the test directory.
- [ ] A frame split across TCP segments is reassembled; a frame exceeding the configured maximum closes the connection with a named error.
- [ ] The metadata and data split is preserved exactly, including an empty metadata section and an empty data section.
- [ ] `RESUME` in a `SETUP` is answered with a rejection naming resumption as unsupported, not ignored.
- [ ] No byte or bit manipulation appears in the botopink sources of this front.

### Step 2 — Transports

```
rakun.rsocket.server.port = 9898
rakun.rsocket.server.mapping-path = /rsocket
rakun.rsocket.server.transport = tcp | websocket
```

**Acceptance:**
- [ ] The TCP transport binds its own port, separate from the HTTP listener, and is absent when unconfigured.
- [ ] The WebSocket transport mounts at the mapping path through front 20 and shares the HTTP listener.
- [ ] Both transports run the same connection process — asserted by running the same interaction test twice, once per transport.
- [ ] TLS material comes from front 74's bundle registry, and a missing bundle fails at boot.

### Step 3 — Setup, keep-alive and lease

**Acceptance:**
- [ ] `SETUP` negotiates the keep-alive interval and the max lifetime, and a missed keep-alive closes the connection within the negotiated lifetime.
- [ ] A responder configured with a lease grants budget, and a requester that exceeds the budget is rejected locally without a frame on the wire.
- [ ] A connection closed by either side terminates every stream process it owned, asserted by process count.

### Step 4 — The four interaction models

**Acceptance:**
- [ ] Fire-and-forget returns nothing on the wire and the handler's `Outcome.Reject` reaches front 86's dead-letter path.
- [ ] Request/response returns exactly one `PAYLOAD` and the requester's `@Future` resolves to it.
- [ ] Request/stream emits no more than the credit granted: with `request(2)` the producer emits two and stops, and emits the third only after `request(1)`.
- [ ] `CANCEL` stops the producer process and no further `PAYLOAD` is sent.
- [ ] Channel carries demand in both directions independently: a slow consumer on one side does not stop the other.
- [ ] An error in a handler becomes an `ERROR` frame on that stream and leaves the connection and the other streams alive.

### Step 5 — Routing and `#[messageMapping]`

**Acceptance:**
- [ ] `#[messageMapping]` on anything but a method fails with a located message.
- [ ] The route tag is encoded and parsed as a length-prefixed entry in the composite metadata, and a request with no routing metadata is answered with an `ERROR` naming the missing route.
- [ ] Two handlers claiming the same route fail at comptime, naming both declarations.
- [ ] The registration is visible in front 15's registry and in `rakun routes`.

### Step 6 — The requester

```bp
pub fn rsocketRequester(url: string) -> Requester

#[@future]
pub fn requestResponse(requester: Requester, route: string, data: string) -> @Future<string>
```

**Acceptance:**
- [ ] A requester connects over either transport from one URL scheme (`tcp://`, `ws://`, `wss://`).
- [ ] Several concurrent calls are issued as front 02 thunks and gathered by index; a test asserts the results are in request order regardless of completion order.
- [ ] A request whose connection drops mid-flight fails that request and does not take the caller down.
- [ ] `fireAndForget` returns as soon as the frame is written and never blocks on a response.

## Examples

- [`examples/rsocket-service-example.bp`](./examples/rsocket-service-example.bp) — the four
  interaction models as a developer writes them, the requester issuing parallel calls as thunks, and
  the routing metadata and credit arithmetic asserted as pure functions.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| **`@Future<T>` lowers eagerly on erlang** — the row already in [`language-gaps.md`](../../language-gaps.md). Three `await`s in a row are three sequential calls, which is the opposite of what an RSocket requester is for. | `examples/rsocket-service-example.bp`, `fetchBoth` | Front 02's pattern: `Array<fn() -> @Future<T>>` thunks, one process per thunk, gathered by index. | A real scheduler behind `@Future` on BEAM, or an explicit `spawn`/`join` pair |
| **No byte or binary type** and **no bitwise operators** — both rows already in [`language-gaps.md`](../../language-gaps.md). The 24-bit length prefix, the 31-bit stream id and the flag bits are unwritable in botopink. | `examples/rsocket-service-example.bp`, the header comment on the protocol seam | The codec is one `#[@External.Erlang]` module; the botopink half never sees a frame. | A `Bytes` primitive and the five bitwise operators |
| **No `await` inside a closure** — the row already in [`language-gaps.md`](../../language-gaps.md). A thunk may *return* a future but may not await one. | `examples/rsocket-service-example.bp`, the thunk array | Each thunk returns the future; the gather awaits. | Allow the effect marker on a closure, or infer it |

## Test plan

`modules/rakun-rsocket/test/` on the **erlang** target, invoked as
`zig build test-libs -- --target erlang --lib rakun` from `repository/botopink-lang/`, and as
`botopink test --target erlang` from `repository/rakun/`.

| File | Asserts |
|---|---|
| `test/codec_test.bp` | Twelve frame types against captured frames, segmentation, oversize refusal, metadata/data split, resume rejection |
| `test/transport_test.bp` | Both transports running the same interaction suite, port separation, TLS bundle resolution |
| `test/interaction_test.bp` | The four models, credit limits, cancellation, per-stream error isolation |
| `test/routing_test.bp` | Metadata encoding and parsing, missing route, duplicate route, registry visibility |
| `test/requester_test.bp` | Thunk gather ordering, connection loss, fire-and-forget non-blocking |

The codec and routing-metadata cells are pure and always run against checked-in frames. The transport
and interaction cells run in-process — this front is both ends of the protocol, so the tests need no
external service at all, which is the one advantage of implementing a protocol over binding one.

There is no commonJS row, and no browser client. A JavaScript RSocket half is out of this front's
scope by the milestone's target split.

## Definition of done

- `modules/rakun-rsocket/` exists, is declared from its `root.bp`, and holds no `@External.Node` cell and no JavaScript.
- The module README states that no BEAM RSocket implementation exists and that this front writes one, with the twelve-frame scope and the `RESUME` refusal named.
- The four interaction models are explained in the README as process shapes, with `@Future` named as the return shape and front 02's thunks as the concurrency.
- `#[messageMapping]` registers on front 15's registry and appears in `rakun routes`.
- Credit accounting is tested as arithmetic, not observed as timing.
- All three language-gap rows are cited from the example and already appear in [`language-gaps.md`](../../language-gaps.md).
- `repository/rakun/AGENTS.md` and `modules/README.md` record the module in the same commit.
- The front's tests are green on erlang.

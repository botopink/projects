# Front 92 — RSocket: transports, TLS, channel, `#[messageMapping]`, dropped connections

**Priority:** low — modest adoption, nothing depends on it · **State:** partial: step 1 box 1 on
`feat` (`00-gate/99`); the rest open
**Depends on:** 128 (RSocket lives in `rakun-messaging` after it) · 15, landed (`botopink.json` and
`src/root.bp` of the member are 15's; R92-1's edge, if taken, is one line there) · 74 (R92-2 reads
the bundle registry; it waits for 74's hostname check before relying on `verify=full`) · 03r-an
(R92-1's transport) · lg2-a (the frame codec marshals through `string`; the sidecar holds the bytes)
**Owns:** `modules/rakun-messaging/src/rsocket/**`, `test/rsocket/**`, `src/sidecars/rakun_rsocket.erl`
· `repository/rakun/AGENTS.md` § RSocket
**Does not touch:** the rest of `rakun-messaging` (15's; `pulsar/**` is 91's) · `rakun-websocket` ·
`rakun-cli` (88 lists the routes)

## Goal

RSocket serves TCP, TLS and (per 03r-an) WebSocket from one connection process; channels carry
demand both ways; `#[messageMapping]` exists; a dropped connection fails only its request; the codec
is asserted against checked-in vectors.

## Mechanism

Today (`src/rsocket/{rsocket_host,rsocket}.bp`, `rakun_rsocket.erl`): TCP only — the WebSocket
transport is refused at boot, there is no TLS arm, REQUEST_CHANNEL is decoded but not served, routes
register through `rsocketRoute` with a second registration refused at load, the requester takes
`tcp://` only. `codec_test.bp` round-trips all twelve frame types; `interaction_test.bp` covers
fire-and-forget, request/response, request/stream with REQUEST_N credit, keep-alive, lease and
routing in 15's registry.

- **R92-9.** The protocol specification's documented frame layouts are checked in as known-answer
  vectors (`test/rsocket/fixtures/frames/*.hex`, one per frame type, the spec section cited) — no
  second implementation's captures are available.
- **R92-1 (03r-an).** The RSocket connection process reads frames from a WebSocket session instead of
  the socket — one process, two readers — mounted at the mapping path. Under 03r-an (a) through
  `rakun-websocket`'s `#[wsEndpoint]` with a `rakun-messaging → rakun-websocket` edge (acyclic, but it
  loads security, session and scheduling for every messaging consumer); under (b) through a core
  extension point `rakun-websocket` plugs into (decision 185's rule).
- **R92-2.** `ssl:listen` with 74's bundle options; a missing bundle name is a boot refusal.
- **R92-3.** Two credit counters per channel stream, one per direction.
- **R92-4.** `#[messageMapping("route")]` registers like `rsocketRoute` (in the post-130 shape —
  meta plus the entry point's catalogue — if 130 has reached the member); on a non-method `decl.fail`.

Nothing is env-gated.

## Done

- Step 1 box 1 — `rakun-websocket/test/broadcast_test.bp` asserts a same-node `pg` broadcast to two subscribers (`rakun_websocket.erl` `pg_broadcast/2`); no `skipped:` branch, no peer start (`00-gate/99`, decision 160)

## Open

### Step 1 — The broadcast record (decision 160)

- [ ] one `deferred.md` row: the two-node broadcast over `erl` distribution (the cell the gate cannot run)

### Step 2 — Transports (R92-1, R92-2, R92-7)

- [ ] per 03r-an: the WebSocket transport mounts at the mapping path and `interaction_test.bp`'s suite runs twice, once per transport, byte-identical results
- [ ] a `tls` transport with bundle `b` from 74's registry serves the suite over `ssl`; a missing bundle name refuses the boot naming it
- [ ] the requester connects from `tcp://`, `ws://`, `wss://` (the last against the TLS transport), one cell each

### Step 3 — Channel, mapping, drops, vectors (R92-3, R92-4, R92-5, R92-8, R92-9)

- [ ] `interaction_test.bp`: REQUEST_CHANNEL with a slow consumer on one side: the other side's credit keeps flowing (counts after 50 frames each way)
- [ ] `#[messageMapping("r")]` on a method registers in 15's registry; on a `val` it fails at build with a located message (`build_test.bp` over a scratch project)
- [ ] a connection the transport closes mid-request fails that request with an error and the caller process is alive; a second request on a new connection succeeds
- [ ] `codec_test.bp` asserts each of the twelve frame types against its checked-in vector
- [ ] R92-5 reworded to "two handlers claiming the same route are refused at load, naming both declarations" (lg2-j) and ticked

R92-6 (`rakun routes` lists rsocket routes) is 88's.

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-messaging` (the `test/rsocket/` files in the run).

Blast radius: under 03r-an (a) the edge makes every `rakun-messaging` consumer load `rakun-websocket`'s
tree; under (b) the core gains the extension point and `rakun-websocket` one registration.

`examples/rsocket-service-example.bp` is kept for its open markers (lg2-a, lg2-b, the `await`-in-lambda
rule by design).

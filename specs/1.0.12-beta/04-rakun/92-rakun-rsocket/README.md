# Front 92 — RSocket: transports, TLS, channel, `#[messageMapping]`, dropped connections

**Priority:** low — modest adoption, nothing depends on it · **State:** partial: step 1 on `feat`
(`00-gate/99`; its record a `deferred.md` row); steps 2–3 open
**Depends on:** 128 (RSocket in `rakun-messaging` after it) · 15, landed (the member's
`botopink.json`, `src/root.bp` are 15's; R92-1's edge, if taken, is one line there) · 74 (R92-2 reads
the bundle registry; waits for 74's hostname check before relying on `verify=full`) · 03r-an (R92-1's
transport) · lg2-a (frame codec marshals through `string`; the sidecar holds the bytes)
**Owns:** `modules/rakun-messaging/src/rsocket/**`, `test/rsocket/**`, `src/sidecars/rakun_rsocket.erl`
· `repository/rakun/AGENTS.md` § RSocket
**Does not touch:** rest of `rakun-messaging` (15's; `pulsar/**` is 91's) · `rakun-websocket` ·
`rakun-cli` (88 lists the routes)

## Goal

RSocket serves TCP, TLS and (per 03r-an) WebSocket from one connection process; channels carry
demand both ways; `#[messageMapping]` exists; a dropped connection fails only its request; codec
asserted against checked-in vectors.

## Mechanism

Today (`src/rsocket/{rsocket_host,rsocket}.bp`, `rakun_rsocket.erl`): TCP only — WebSocket transport
refused at boot, no TLS arm, REQUEST_CHANNEL decoded but not served, routes register through
`rsocketRoute` (second registration refused at load), requester takes `tcp://` only.
`codec_test.bp` round-trips all twelve frame types; `interaction_test.bp` covers fire-and-forget,
request/response, request/stream with REQUEST_N credit, keep-alive, lease and routing in 15's registry.

- **R92-9.** The spec's documented frame layouts checked in as known-answer vectors
  (`test/rsocket/fixtures/frames/*.hex`, one per frame type, spec section cited) — no second
  implementation's captures available.
- **R92-1 (03r-an).** The connection process reads frames from a WebSocket session instead of the
  socket — one process, two readers — mounted at the mapping path. (a) via `rakun-websocket`'s
  `#[wsEndpoint]` with a `rakun-messaging → rakun-websocket` edge (acyclic, but loads security,
  session, scheduling for every messaging consumer); (b) via a core extension point
  `rakun-websocket` plugs into (decision 185).
- **R92-2.** `ssl:listen` with 74's bundle options; missing bundle name is a boot refusal.
- **R92-3.** Two credit counters per channel stream, one per direction.
- **R92-4.** `#[messageMapping("route")]` registers like `rsocketRoute` (post-130 shape — meta plus
  the entry point's catalogue — if 130 has reached the member); on a non-method `decl.fail`.

Nothing env-gated.

## Done

- Step 1 — `rakun-websocket/test/broadcast_test.bp` asserts a same-node `pg` broadcast to two subscribers (`rakun_websocket.erl` `pg_broadcast/2`); no `skipped:` branch, no peer start (`00-gate/99`, decision 160); the two-node broadcast is a `deferred.md` row

## Open

### Step 2 — Transports (R92-1, R92-2, R92-7)

- [ ] per 03r-an: WebSocket transport mounts at the mapping path; `interaction_test.bp`'s suite runs twice, once per transport, byte-identical results
- [ ] a `tls` transport with bundle `b` from 74's registry serves the suite over `ssl`; a missing bundle name refuses the boot naming it
- [ ] requester connects from `tcp://`, `ws://`, `wss://` (the last against the TLS transport), one cell each

### Step 3 — Channel, mapping, drops, vectors (R92-3, R92-4, R92-5, R92-8, R92-9)

- [ ] `interaction_test.bp`: REQUEST_CHANNEL with a slow consumer on one side: the other side's credit keeps flowing (counts after 50 frames each way)
- [ ] `#[messageMapping("r")]` on a method registers in 15's registry; on a `val` fails at build with a located message (`build_test.bp` over a scratch project)
- [ ] a connection the transport closes mid-request fails that request with an error, caller process alive; a second request on a new connection succeeds
- [ ] `codec_test.bp` asserts each of the twelve frame types against its checked-in vector
- [ ] R92-5 reworded to "two handlers claiming the same route are refused at load, naming both declarations" (lg2-j) and ticked

R92-6 (`rakun routes` lists rsocket routes) is 88's.

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-messaging` (`test/rsocket/` in the run).

Blast radius: under 03r-an (a) every `rakun-messaging` consumer loads `rakun-websocket`'s tree;
under (b) the core gains the extension point, `rakun-websocket` one registration.

`examples/rsocket-service-example.bp` kept for open markers (lg2-a, lg2-b, the `await`-in-lambda rule by design).

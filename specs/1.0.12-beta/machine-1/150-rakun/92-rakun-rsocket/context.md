# Front 92 — RSocket: transports, TLS, channel, `#[messageMapping]`, dropped connections

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [150-rakun](../README.md): s2 → 150 s19 · s3 → 150 s19. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** low — modest adoption, nothing depends on it · **State:** partial: step 1 on `feat`
(`00-gate/99`; its record a `deferred.md` row); steps 2–3 open
**Depends on:** 128 (RSocket in `rakun-messaging` after it) · 15, landed (the member's
`botopink.json`, `src/root.bp` are 15's; R92-1's edge, if taken, is one line there) · 74 (R92-2 reads
the bundle registry; waits for 74's hostname check before relying on `verify=full`) · 03r-an (R92-1's
transport) · 346's `Bytes`, unbuilt (frame codec marshals through `string`; the sidecar holds the bytes)
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

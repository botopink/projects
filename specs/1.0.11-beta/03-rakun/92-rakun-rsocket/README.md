# Front 92 — RSocket

**Priority:** low — modest adoption, nothing depends on it; it also carries the one skipped-arm cell of a closed member (`rakun-websocket`'s two-node broadcast)
**Carries:** 20 (one test file and its runner, by carve-out)
**Depends on:** `74-rakun-tls-ssl-bundles` (R92-2 reads the bundle registry; the API exists, the front waits only for 74's hostname check to be asserted before relying on `verify=full`) · maintainer 03r-aa (the broadcast arm) · compiler lg2-a (the frame codec marshals through `string`; the sidecar holds the bytes)
**Owns:** `modules/rakun-rsocket/**` · `modules/rakun-websocket/test/broadcast_test.bp` and the broadcast runner in `modules/rakun-websocket/src/sidecars/rakun_websocket.erl` (the `skipped:` arm, lines ~507-539) — carve-out · `repository/rakun/AGENTS.md` § RSocket, § WebSocket (the broadcast paragraph)
**Does not touch:** the rest of `rakun-websocket` · `rakun-messaging` (15's; the registry is consumed) · `rakun-cli` (88 lists the routes)

---

## Carried from 1.0.10

| Id | From (`specs/1.0.10-beta/03-rakun/92-rakun-rsocket/README.md`) | Box, as written |
|---|---|---|
| R92-9 | § Step 1 — The frame codec | "All twelve frame types encode and decode, asserted against captured frames checked into the test directory. — open: all twelve round-trip …, but no captured frames from another implementation exist here to assert against" |
| R92-1 | § Step 2 — Transports | "The WebSocket transport mounts at the mapping path through front 20 and shares the HTTP listener. — open: the websocket transport is refused at boot - front 20's mount is not wired" |
| R92-1 | § Step 2 | "Both transports run the same connection process — asserted by running the same interaction test twice, once per transport. — open: TCP only" |
| R92-2 | § Step 2 | "TLS material comes from front 74's bundle registry, and a missing bundle fails at boot. — open: the TCP transport has no TLS arm yet" |
| R92-3 | § Step 4 — The four interaction models | "Channel carries demand in both directions independently: a slow consumer on one side does not stop the other. — open: REQUEST_CHANNEL is decoded, not served" |
| R92-4 | § Step 5 — Routing and `#[messageMapping]` | "`#[messageMapping]` on anything but a method fails with a located message. — open: routes register through `rsocketRoute`; there is no `#[messageMapping]`" |
| R92-5 | § Step 5 | "Two handlers claiming the same route fail at comptime, naming both declarations. — open: a second registration is refused at load, naming the route …, not at comptime" — closes by amendment (lg2-j): "at load, naming both" |
| R92-6 | § Step 5 | "The registration is visible in front 15's registry and in `rakun routes`. — open: … `rakun routes` lists HTTP routes only" — 88's |
| R92-7 | § Step 6 — The requester | "A requester connects over either transport from one URL scheme (`tcp://`, `ws://`, `wss://`). — open: `tcp://` only" |
| R92-8 | § Step 6 | "A request whose connection drops mid-flight fails that request and does not take the caller down. — open: not asserted" |
| 20's arm | `modules/rakun-websocket/test/broadcast_test.bp:102` | `assert out.startsWith("skipped: ") \|\| out == "1\|{\"t\":\"cluster\",\"d\":\"hi\"}"` — the two-node broadcast passes when the runner cannot start a peer |

## Problem

RSocket serves TCP only; the WebSocket transport is refused at boot, there is no TLS arm, no
channel, no marker decorator; the requester takes `tcp://` only and a dropped connection is not
asserted to fail only its request. In `rakun-websocket`, the cluster broadcast cell accepts
"skipped".

## Current state

`modules/rakun-rsocket`: `src/{rsocket_host,rsocket}.bp`, `rakun_rsocket.erl`; `codec_test.bp`
("all twelve frame types encode and decode"), `interaction_test.bp` (fire-and-forget,
request/response, request/stream with REQUEST_N credit, keep-alive, lease, routing in 15's
registry); manifest `rakun`, `rakun-messaging` — no `rakun-websocket` edge (the closed `modules.md`
drew one). `rakun-websocket`: 6 test files green; `rakun_websocket.erl:507-539` starts a peer for
the cluster arm and answers `skipped: <why>` when it cannot.

## Mechanism

- R92-9: the RSocket protocol specification's documented frame layouts are checked in as
  known-answer vectors (`test/fixtures/frames/*.hex`, one per frame type, with the spec section
  cited) — a second implementation's captures are not available; the vectors are.
- R92-1: `rakun-websocket`'s `#[wsEndpoint]` API mounts a handler at the mapping path; the
  RSocket connection process reads frames from the WebSocket session instead of the socket — one
  process, two readers. The manifest gains `rakun-websocket` (acyclic: it depends on `rakun-web`,
  `-security`, `-data`, `-api`; none depends on `rakun-rsocket`).
- R92-2: `ssl:listen` with 74's bundle options; a missing bundle name is a boot refusal.
- R92-3: two credit counters per channel stream, one per direction.
- R92-4: `#[messageMapping("route")]` emits the `rsocketRoute` registration; on a non-method
  `decl.fail`.
- The broadcast arm (03r-aa): the cell asserts a same-node `pg` broadcast to two subscriber
  processes; the peer-node arm and the `skipped:` branch are deleted; a `deferred.md` row holds the
  two-node run under distribution.

## Gate stance

The `skipped:` arm is deleted; no env-gated cell in either member.

## Steps

### Step 1 — The broadcast cell (03r-aa)

**Acceptance:**
- [ ] `rakun-websocket/test/broadcast_test.bp`: two subscriber processes on the same node receive the broadcast (`2|…`); `out.startsWith("skipped: ")` no longer appears; `rakun_websocket.erl`'s peer-start branch is deleted
- [ ] one `deferred.md` row: the two-node broadcast over distribution

### Step 2 — Transports (R92-1, R92-2, R92-7)

**Acceptance:**
- [ ] the manifest lists `rakun-websocket`; the WebSocket transport mounts at the mapping path and `interaction_test.bp`'s suite runs twice, once per transport, byte-identical results
- [ ] a `tls` transport with bundle `b` from 74's registry serves the suite over `ssl`; a missing bundle name refuses the boot naming it
- [ ] the requester connects from `tcp://`, `ws://`, `wss://` (the last against the TLS transport), one cell each

### Step 3 — Channel, mapping, drops (R92-3, R92-4, R92-8, R92-9, R92-5)

**Acceptance:**
- [ ] `interaction_test.bp`: REQUEST_CHANNEL with a slow consumer on one side: the other side's credit keeps flowing (asserted by counts after 50 frames each way)
- [ ] `#[messageMapping("r")]` on a method registers in 15's registry; on a `val` it fails at build with a located message (`build_test.bp` over a scratch project)
- [ ] a connection the transport closes mid-request fails that request with an error and the caller process is alive; a second request on a new connection succeeds
- [ ] `codec_test.bp` asserts each of the twelve frame types against its checked-in vector
- [ ] R92-5 reworded to the load-time refusal naming both declarations and ticked

## Gate

- [ ] `botopink test --target erlang` green in `modules/rakun-rsocket` and `modules/rakun-websocket`
- [ ] `botopink format --check` clean
- [ ] `AGENTS.md` sections updated
- [ ] commit on `fix/92-rakun-rsocket`

## Blast radius

The manifest edge makes `rakun-rsocket` pull `rakun-websocket`'s tree (security, data) — the cost
the closed cut accepted. The broadcast cell's change touches one closed member's test and one
sidecar branch; nothing else in `rakun-websocket` moves.

## Notes

`examples/rsocket-service-example.bp` is copied here for its open markers (lg2-a, lg2-b, the
`await`-in-lambda rule by design).

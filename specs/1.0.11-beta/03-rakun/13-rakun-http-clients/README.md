# Front 13 — rakun HTTP Clients (the client's tail)

**Priority:** high — R13-2's keep-alive pool unblocks 75's one-connection OTLP push and 65's streamed relay; R13-3's interceptor seam is 03r-w's second option; RX-8 is an exit-gate violation of the closed milestone
**Carries:** 21 (the RX-8 example file only; `rakun-hateoas` has no open box)
**Depends on:** `04-rakun-erlang-runtime` step 1 (`rkTagEpoch`, 03r-z) for R13-1 · compiler lg2-a / lg2-b for the streaming body (the relay of R65-1 streams only if the client can hand chunks; with `string` marshalling the chunk is a string, which is enough for a text relay and is what this front ships)
**Owns:** `modules/rakun-client/**` · `repository/rakun/AGENTS.md` § HTTP clients · the RX-8 row in the milestone's `language-gaps.md`
**Does not touch:** `rakun-cache` (12's) · `rakun-metrics` (17's) · `rakun-web/src/rules.bp` (65's relay consumes the streaming API)

---

## Carried from 1.0.10

| Id | From (`specs/1.0.10-beta/03-rakun/`) | Box, as written |
|---|---|---|
| R13-1 | `13-rakun-http-clients/README.md` § Step 4 — Response caching over front 12 | "`revalidateTag` on one of the request's tags makes the next `retrieve()` reach the transport." |
| R13-2 | `75-rakun-observability-metrics/README.md` § Step 5 (the blocker it names) | "front 13's client opens one connection per request and closes it (`transport.bp`), so a push is two requests on two connections; sharing one needs a keep-alive pool in front 13" |
| R13-3 | `79-rakun-oauth2-sso` 03r-w option 2 | "a client interceptor seam in front 13" — the request-interceptor hook `#[clientCredentials]` would need to wrap a client's calls |
| R65-1 (client half) | `65-rakun-url-rules/README.md` § Step 4 — Rewrites | "The relayed body is streamed: a 50 MB upstream response does not grow the server's heap by 50 MB" — the client must hand the body in chunks |
| RX-8 | closed `fronts.md` § Exit gate | `13/examples/http-exchange-example.bp:84` and `21/examples/hal-resource-example.bp:136` carry `// LANGUAGE GAP:` "std reads JSON into a structured `Json` … no record ↔ `Json` derivation" with no row in `language-gaps.md` |
| RX-2 (21) | closed `21-rakun-hateoas/README.md` | the "declared defaults" text and the broken "Unowned surface" link — the row this front files is the correction |

## Problem

A cached response is served until its TTL whatever `revalidateTag` says. Every request opens and
closes a connection (`transport.bp`), so a metrics push is two handshakes and a relay of a large
body is one `string`. Two example files name a gap the milestone never recorded.

## Current state

`modules/rakun-client`: 8 test files, 70 tests green; `transport.bp` speaks HTTP/1.1 over
`io.net` sockets, follows redirects (`follow(out, traceparentOf(span), 0)`, `transport.bp:236-237`),
sends `traceparent` from `rakun-actuator-api`'s span; `cache.bp` caches responses by key and TTL;
`exchange.bp` builds `#[httpExchange]` proxies. Tests run against an in-process HTTP double.

## Mechanism

- R13-1: `cache.bp` stores, beside a response, the `rkTagEpoch(tag)` of each tag at store time; a
  read compares and treats a changed epoch as a miss. No import of `rakun-cache`.
- R13-2: a per-origin pool in `rakun_client.erl` — `N` idle sockets per `scheme://host:port`, an
  idle timeout, `Connection: keep-alive` sent, a closed socket detected on reuse and replaced. The
  builder's `keepAlive(max, idleMillis)`; the default is a pool of 2 (the restrictive default is not
  "no pool": a pool bounded by 2 with an idle timeout is the one that does not leak).
- R13-3: `RestClient.builder().intercept(fn(ClientRequest) -> ClientRequest)`; interceptors run in
  registration order before the transport; `withClientToken` (79) becomes one interceptor.
- Streaming: `retrieveStream(fn(chunk: string) -> i32)` reads the body in `recv` chunks and hands
  each to the callback; the relay (65) writes each chunk to the reply as it arrives.

## Gate stance

No env-gated cell. The HTTP double answers everything in-process; the pool is asserted by the
double's accept count.

## Steps

### Step 1 — Tags (R13-1)

**Acceptance:**
- [ ] `cache_test.bp`: a cached `retrieve()` with tag `t`; `rkBumpTag("t")`; the next `retrieve()` reaches the transport (the double's request count grows by one)
- [ ] a bump of another tag leaves the entry served from cache

### Step 2 — Keep-alive pool (R13-2)

**Acceptance:**
- [ ] `builder_test.bp`: two sequential requests to one origin with the default builder produce one accepted connection on the double; `keepAlive(0, 0)` produces two
- [ ] an idle socket past `idleMillis` is closed and the next request opens a new one (accept count 2)
- [ ] a socket the double closed is not reused: the request succeeds on a fresh connection, no error surfaces
- [ ] the pool is bounded: 5 concurrent requests with `keepAlive(2, …)` never hold more than 2 idle sockets after they finish (asserted through `rkClientPoolSize(origin)`)

### Step 3 — Interceptors and streaming (R13-3, R65-1's client half)

**Acceptance:**
- [ ] `request_test.bp`: an interceptor that adds a header is seen by the double; two interceptors run in registration order
- [ ] `retrieveStream` hands a 1 MB body from the double in more than one chunk and the concatenation equals the body; peak process heap during the transfer stays under 256 KB (`erlang:process_info(memory)` through the sidecar)

### Step 4 — The RX-8 row

**Acceptance:**
- [ ] the milestone's `language-gaps.md` gains the row "no record ↔ `Json` derivation — a record cannot be serialised to or read from std's `Json` without hand-written field code; bites 13 (`#[httpExchange]` bodies), 21 (HAL documents); nearest form: hand-written `toJson` / `fromJson` per type; proposed surface: a comptime `@jsonOf(T)` pair; owner `00`"
- [ ] both example files under `examples/` here cite the row in their marker text

## Gate

- [ ] `botopink test --target erlang` green in `modules/rakun-client`
- [ ] `botopink format --check` clean
- [ ] `AGENTS.md` § HTTP clients updated
- [ ] commit on `fix/13-rakun-http-clients`

## Blast radius

A default pool of 2 changes connection behaviour for every consumer (75's exporter, 79's token
fetch, 93's `WsClient`, 09's Elasticsearch arm): fewer handshakes, the same requests. The double
in each consumer's tests accepts reused connections already (HTTP/1.1 framing); a consumer that
asserted an accept count per request re-records to per origin — 17 (metrics export) is the one
that does, and it is the front that wanted the change.

## Notes

- R11-6 (traceparent) is asserted here (`request_test.bp`) and ticked by 11.
- `examples/http-exchange-example.bp` and `examples/hal-resource-example.bp` are the two files RX-8
  names, copied whole.

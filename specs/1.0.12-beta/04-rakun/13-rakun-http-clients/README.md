# Front 13 — rakun HTTP clients: tag invalidation, a keep-alive pool, interceptors, a streamed body

**Priority:** high — the pool unblocks 17's one-connection OTLP push (R75-1); the interceptor seam is
03r-w's second option · **State:** partial: step 4 on `feat`; steps 1–3 open
**Depends on:** 128 (it moves the SOAP files into this member and the span API into the core) ·
04 step 1 (`rkTagEpoch` — decision 185: no `rakun-client → rakun-cache` edge) · lg2-a / lg2-b (the
streamed body is a `string` chunk — enough for a text stream, and what this front ships)
**Owns:** `modules/rakun-client/**` except 93's `src/ws/**`, `test/ws/**`, `src/sidecars/rakun_ws.erl` —
`botopink.json` and `src/root.bp` are this front's; 93 appends when this front does not hold them ·
`repository/rakun/AGENTS.md` § HTTP clients
**Does not touch:** 93's files · `rakun-cache` (12's) · `rakun-metrics` (17's) · `rakun-web` (65's relay
is OTP `httpc` inline, not this client)

## Goal

A cached response is invalidated by a bump of one of its tags; one origin reuses a bounded pool of
keep-alive sockets; interceptors wrap a client's calls; `retrieveStream` hands the body in chunks.

## Mechanism

Today `transport.bp` speaks HTTP/1.1 over `io.net` sockets, one connection per request, follows
redirects (`follow`), and sends `traceparent` from the core's span (`startSpan("http.client.request",
…)`); `cache.bp` caches by key and TTL; `exchange.bp` builds `#[httpExchange]` proxies (its
decision-216 member form is `01-compiler/130`'s, held). Tests run against an in-process HTTP double.

- **R13-1.** `cache.bp` stores, beside a response, the `rkTagEpoch(tag)` of each tag at store time; a
  read compares and treats a changed epoch as a miss. No import of `rakun-cache`.
- **R13-2.** A per-origin pool in `rakun_client.erl` — `N` idle sockets per `scheme://host:port`, an
  idle timeout, `Connection: keep-alive` sent, a socket closed by the peer detected on reuse and
  replaced. The builder's `keepAlive(max, idleMillis)`; the default is a pool of 2 (bounded, with an
  idle timeout — the default that does not leak).
- **R13-3.** `RestClient.builder().intercept(fn(ClientRequest) -> ClientRequest)`; interceptors run in
  registration order before the transport; 79's `withClientToken` can become one.
- **Streaming (R65-1's client half).** `retrieveStream(fn(chunk: string) -> i32)` reads the body in
  `recv` chunks and hands each to the callback. 65's relay does not consume it (`rakun-web` has no
  edge to this member, and adding one would drag the client into every web consumer — decision 185);
  the API stands for the client's own consumers.

No env-gated cell; the pool is asserted by the double's accept count.

## Done

- Step 4 — the RX-8 row "No `record ↔ Json` derivation" is in `language-gaps.md`, and both example files are in its Marker index; it is also RX-2's correction for 21

## Open

### Step 1 — Tags (R13-1)

- [ ] `cache_test.bp`: a cached `retrieve()` with tag `t`; `rkBumpTag("t")`; the next `retrieve()` reaches the transport (the double's request count grows by one)
- [ ] a bump of another tag leaves the entry served from cache

### Step 2 — Keep-alive pool (R13-2)

- [ ] `builder_test.bp`: two sequential requests to one origin with the default builder produce one accepted connection on the double; `keepAlive(0, 0)` produces two
- [ ] an idle socket past `idleMillis` is closed and the next request opens a new one (accept count 2)
- [ ] a socket the double closed is not reused: the request succeeds on a fresh connection, no error surfaces
- [ ] the pool is bounded: 5 concurrent requests with `keepAlive(2, …)` never hold more than 2 idle sockets after they finish (`rkClientPoolSize(origin)`)

### Step 3 — Interceptors and streaming (R13-3, R65-1's client half)

- [ ] `request_test.bp`: an interceptor that adds a header is seen by the double; two interceptors run in registration order
- [ ] `retrieveStream` hands a 1 MB body from the double in more than one chunk and the concatenation equals the body; peak process heap during the transfer stays under 256 KB (`erlang:process_info(memory)` through the sidecar)

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-client`.

Blast radius: a default pool of 2 changes connection behaviour for every consumer (17's exporter,
79's token fetch, 93's `WsClient`, 09's Elasticsearch arm): fewer handshakes, the same requests. A
consumer that asserted an accept count per request re-records to per origin — 17's export cell, the
front that wanted the change.

## Notes

- R11-6 (traceparent) is asserted here (`request_test.bp`) and ticked by 11.
- `examples/http-exchange-example.bp` and `examples/hal-resource-example.bp` are kept for their open markers (the RX-8 row).

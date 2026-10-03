# Front 13 — rakun HTTP clients: tag invalidation, a keep-alive pool, interceptors, a streamed body

**Priority:** high — the pool unblocks 17's one-connection OTLP push (R75-1); the interceptor seam is
03r-w's second option · **State:** partial: step 4 on `feat`; steps 1–3 open
**Depends on:** 128 (moves the SOAP files here, the span API into the core) · 04 step 1
(`rkTagEpoch` — decision 185: no `rakun-client → rakun-cache` edge) · lg2-a / lg2-b (streamed body is
a `string` chunk — enough for a text stream, what this front ships)
**Owns:** `modules/rakun-client/**` except 93's `src/ws/**`, `test/ws/**`, `src/sidecars/rakun_ws.erl` —
`botopink.json`, `src/root.bp` are this front's; 93 appends when this front does not hold them ·
`repository/rakun/AGENTS.md` § HTTP clients
**Does not touch:** 93's files · `rakun-cache` (12's) · `rakun-metrics` (17's) · `rakun-web` (65's
relay is inline OTP `httpc`, not this client)

## Goal

A cached response invalidated by a bump of one of its tags; one origin reuses a bounded keep-alive
pool; interceptors wrap a client's calls; `retrieveStream` hands the body in chunks.

## Mechanism

Today `transport.bp` speaks HTTP/1.1 over `io.net` sockets, one connection per request, follows
redirects (`follow`), sends `traceparent` from the core's span (`startSpan("http.client.request",
…)`); `cache.bp` caches by key and TTL; `exchange.bp` builds `#[httpExchange]` proxies (its
decision-216 member form is `01-compiler/130`'s, held). Tests run against an in-process HTTP double.

- **R13-1.** `cache.bp` stores beside a response each tag's `rkTagEpoch(tag)` at store time; a read
  treats a changed epoch as a miss. No `rakun-cache` import.
- **R13-2.** Per-origin pool in `rakun_client.erl` — `N` idle sockets per `scheme://host:port`, an
  idle timeout, `Connection: keep-alive` sent, a peer-closed socket detected on reuse and replaced.
  Builder `keepAlive(max, idleMillis)`; default a pool of 2 (bounded, idle timeout — does not leak).
- **R13-3.** `RestClient.builder().intercept(fn(ClientRequest) -> ClientRequest)`; interceptors run
  in registration order before the transport; 79's `withClientToken` can become one.
- **Streaming (R65-1's client half).** `retrieveStream(fn(chunk: string) -> i32)` reads the body in
  `recv` chunks, hands each to the callback. 65's relay does not consume it (no `rakun-web` edge to
  this member — decision 185); the API is for the client's own consumers.

No env-gated cell; the pool is asserted by the double's accept count.

## Done

- Step 4 — the RX-8 row "No `record ↔ Json` derivation" is in `language-gaps.md`, and both example files are in its Marker index; it is also RX-2's correction for 21

## Open

### Step 1 — Tags (R13-1)

- [ ] `cache_test.bp`: a cached `retrieve()` with tag `t`; `rkBumpTag("t")`; the next `retrieve()` reaches the transport (double's request count +1)
- [ ] a bump of another tag leaves the entry served from cache

### Step 2 — Keep-alive pool (R13-2)

- [ ] `builder_test.bp`: two sequential requests to one origin with the default builder produce one accepted connection on the double; `keepAlive(0, 0)` produces two
- [ ] an idle socket past `idleMillis` is closed, the next request opens a new one (accept count 2)
- [ ] a socket the double closed is not reused: the request succeeds on a fresh connection, no error surfaces
- [ ] pool bounded: 5 concurrent requests with `keepAlive(2, …)` never hold more than 2 idle sockets after finishing (`rkClientPoolSize(origin)`)

### Step 3 — Interceptors and streaming (R13-3, R65-1's client half)

- [ ] `request_test.bp`: a header-adding interceptor is seen by the double; two interceptors run in registration order
- [ ] `retrieveStream` hands a 1 MB body from the double in more than one chunk, concatenation equals the body; peak process heap during transfer under 256 KB (`erlang:process_info(memory)` through the sidecar)

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-client`.

Blast radius: a default pool of 2 changes connection behaviour for every consumer (17's exporter,
79's token fetch, 93's `WsClient`, 09's Elasticsearch arm): fewer handshakes, same requests. A
consumer asserting accept count per request re-records to per origin — 17's export cell, the front
that wanted it.

## Notes

- R11-6 (traceparent) asserted here (`request_test.bp`), ticked by 11.
- `examples/http-exchange-example.bp`, `examples/hal-resource-example.bp` kept for open markers (the RX-8 row).

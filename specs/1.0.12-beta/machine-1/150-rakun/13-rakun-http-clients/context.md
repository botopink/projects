# Front 13 — rakun HTTP clients: tag invalidation, a keep-alive pool, interceptors, a streamed body

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [150-rakun](../README.md): s1 → 150 s11 · s2 → 150 s11 · s3 → 150 s11 · s5 → 150 s11 · s6 → 150 s11. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** high — the pool unblocks 17's one-connection OTLP push (R75-1); the interceptor seam is
03r-w's second option · **State:** partial: step 4 on `feat`; steps 1–3 open
**Depends on:** 128 (moves the SOAP files here, the span API into the core) · 04 step 1
(`rkTagEpoch` — decision 185: no `rakun-client → rakun-cache` edge) · lg2-b · 346's `Bytes`, unbuilt (streamed body is
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

## Notes

- R11-6 (traceparent) asserted here (`request_test.bp`), ticked by 11.
- `examples/http-exchange-example.bp`, `examples/hal-resource-example.bp` kept for open markers (the RX-8 row).

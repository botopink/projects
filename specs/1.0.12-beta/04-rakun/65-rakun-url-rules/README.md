# Front 65 — URL rules and static assets: the fall-through, a streamed relay, the dev cache default

**Priority:** high — onze's public root waits on step 1 (a `/**` static root answers every page URL
404 today); an unasserted hop-by-hop rule is a proxy correctness gap · **State:** not started
(decision 201's rule 2 already in code)
**Depends on:** 128 · decision 201 (step 1) · lg2-a / lg2-b (relay carries the body as `string`
chunks — enough for the assertion)
**Owns:** `modules/rakun-web/**` except 74's `src/tls.bp`, `test/tls_test.bp` (`src/hateoas/**`
included, no open box) · one line of `modules/rakun-data/src/devtools/devtools.bp` — dev-profile
default `rakun.web.resources.cache.period=0` — and its assertion in
`modules/rakun-data/test/devtools/devtools_test.bp` (carve-out in 08's member) ·
`repository/rakun/AGENTS.md` § Web, § Static assets
**Does not touch:** 74's two files · `rakun-app` (22's) · devtools files beyond the one line ·
`rakun-client` (13's) · `repository/onze/**` (69's registration is onze's half) · after this front,
while their front holds them (decisions 188, 189): `src/{negotiation,compression,static,error}.bp`'s
codec lines (104's sweep), `src/{middleware,filter}.bp`'s lines (`08-bpp/123`) · 130's decision-216
sites in `src/convention.bp` (track README § Order)

## Goal

A static root behaves as Next and `express.static` (decision 201): a miss falls through to the
routes, only `GET` / `HEAD` served, a refusal stays final. The relay streams its body, asserted to
drop hop-by-hop headers both ways. The dev profile turns static caching off.

## Mechanism

- **Decision 201, three rules.** (1) Miss falls through: `static.bp`'s `serveFrom` answers
  `chain.next(req)` instead of `Response.notFound()` when no matching root resolves an existing file
  (today `static.bp`'s top doc: "a path some root matched but no root resolves is 404 from this
  entry"). (2) Only `GET`, `HEAD` served — **already in code**: `staticEntry` hands other methods to
  `chain.next`; a box asserts it. (3) Refusal final at the first matching root — 400 bad decode, 404
  refused segment. No configuration key. onze registers `public/` at `/**` before the routes (`07-onze/49` step 4).
- **R65-1.** The relay is an inline OTP `httpc` call in `rules.bp` (`relay(method, url)`, under
  `proxied`) reading the whole body (`{body_format, binary}`) into one `status\ncontent-type\nbody`
  string. Rewritten to stream via `httpc`'s `{sync, false}, {stream, self}`, writing each chunk as it
  arrives; heap assertion reads the relay process's memory through the sidecar. Stays off
  `rakun-client`: `rakun-web` has no edge to it; adding one drags the client into every web consumer (decision 185).
- **R65-2.** Today the relay forwards no request header and only the upstream's content type back:
  hop-by-hop dropped by construction, unasserted. Streaming forwards headers through a fixed
  hop-by-hop list stripped both ways, plus the names in the `Connection` value (RFC 9110 § 7.6.1).
- **R82-1 / R80-1.** Dev property source (`devtools/devtools.bp`) gains one entry; `static_test.bp`'s
  existing `period=0` cell then runs under the dev profile and asserts `no-cache`.
- `rkStaticFsCalls()` counts filesystem calls for traversal cells; the relay's test upstream is the
  in-process HTTP double; nothing env-gated.

## Open

### Step 1 — The fall-through (R82-4, decision 201)

- [ ] `static_test.bp`: root `/**` → `public/`; a path no root resolves reaches the next chain entry (a recording entry after the static one sees it); an existing file is served, recorder does not run
- [ ] a `POST` (and a `PUT`) to a path a root would serve reaches the chain, file not served; `HEAD` served (rule 2, asserting `staticEntry` as it is)
- [ ] traversal, encoded traversal and a bad segment still final refusals (400/404) at the first matching root, `rkStaticFsCalls()` unchanged for the first two
- [ ] `AGENTS.md` § Static assets states the three rules; onze 69's registration box named as the consumer

### Step 2 — The relay (R65-1, R65-2)

- [ ] `rules_test.bp`: a rewrite to the double answering a 4 MB body streams it — relay process's peak memory under 512 KB (`rkProcessPeakMemory`), client receives every byte
- [ ] `Connection`, `Transfer-Encoding`, `Upgrade`, `Keep-Alive`, `Proxy-Connection`, `TE`, `Trailer` and every name in the upstream's `Connection` value absent from the relayed response; same list absent from the relayed request (the double records it)

### Step 3 — The dev default (R82-1, R80-1, R82-2, R82-3)

- [ ] `rakun-data/src/devtools/devtools.bp`: dev property source sets `rakun.web.resources.cache.period=0`; `rakun-data/test/devtools/devtools_test.bp` asserts the key present under the dev profile, absent otherwise
- [ ] `static_test.bp`: under the dev profile every root answers `Cache-Control: no-cache`
- [ ] R82-2 reworded to "traversal and encoded traversal answer 404 without a filesystem call; a symlink escape by resolving the link, before any read" and ticked; symlink cell asserts the escape refused before any read (`rkStaticFsCalls()` grows by exactly the one `readlink`)
- [ ] R82-3 ("onze front 69's roots are served through `registerStaticRoot` with no second content-type table, ETag rule or traversal guard anywhere under `repository/`"): the grep (`fn contentTypeOf` only in `src/static.bp`) runs as a cell; onze registering is onze's (69)

### Step 4 — a handler may answer `@Result<Response, E>` (decision 304)

- [ ] a `#[getMapping]` / `#[postMapping]` / … method declared `-> @Result<Response, E>` is accepted; `Ok(r)` is sent as is
- [ ] an `Error(e)` of 08's `StoreError` answers a problem response: `Unavailable` 503, `Timeout` 504, `Conflict` 409, `Constraint` 409; any other `E` 500 with a digest, as an uncaught raise is today — one cell each
- [ ] the error is logged once, with the request id, by the same entry that logs a raise (`src/error.bp`)

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-web` and `modules/rakun-data` (`test/devtools/` in the run).

Blast radius: step 1 turns a static-matched miss from 404 into the router's answer — what onze
49/69 need; `examples/rakun-ssr` registers no `/**` root. onze then registers its public root;
ONZ-49-4.3's third box closes on onze's side.

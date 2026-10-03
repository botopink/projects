# Front 65 — URL rules and static assets: the fall-through, a streamed relay, the dev cache default

**Priority:** high — onze's public root waits on step 1 (a `/**` static root answers every page URL
404 today); an unasserted hop-by-hop rule is a correctness gap in a proxy · **State:** not started
(rule 2 of decision 201 is already in code)
**Depends on:** 128 · decision 201 (step 1) · lg2-a / lg2-b (the relay carries the body as `string`
chunks — enough for the assertion)
**Owns:** `modules/rakun-web/**` except 74's `src/tls.bp`, `test/tls_test.bp` (`src/hateoas/**`
included, no open box) · one line of `modules/rakun-data/src/devtools/devtools.bp` — the dev-profile
default `rakun.web.resources.cache.period=0` — and its assertion in
`modules/rakun-data/test/devtools/devtools_test.bp` (carve-out in 08's member) ·
`repository/rakun/AGENTS.md` § Web, § Static assets
**Does not touch:** 74's two files · `rakun-app` (22's) · the devtools files beyond the one line ·
`rakun-client` (13's) · `repository/onze/**` (69's registration is onze's half) · after this front,
while their front holds them (decisions 188, 189): `src/{negotiation,compression,static,error}.bp`'s
codec lines (104's sweep), `src/{middleware,filter}.bp`'s lines (`08-bpp/123`) · 130's decision-216
sites in `src/convention.bp` (track README § Order)

## Goal

A static root behaves as Next and `express.static` do (decision 201): a miss falls through to the
routes, only `GET` / `HEAD` are served, a refusal stays final. The relay streams its body and is
asserted to drop hop-by-hop headers both ways. The dev profile turns static caching off.

## Mechanism

- **Decision 201, three rules.** (1) A miss falls through: `static.bp`'s `serveFrom` answers
  `chain.next(req)` instead of `Response.notFound()` when no matching root resolves an existing
  file (today the doc at the top of `static.bp` says "a path some root matched but no root resolves
  is 404 from this entry"). (2) Only `GET` and `HEAD` are served — **already in code**: `staticEntry`
  hands any other method to `chain.next`; the box below asserts it. (3) A refusal stays final at the
  first matching root — 400 for a bad decode, 404 for a refused segment. No configuration key. onze
  registers `public/` at `/**` before the routes (`07-onze/49` step 4).
- **R65-1.** The relay is an inline OTP `httpc` call in `rules.bp` (`relay(method, url)`, under
  `proxied`) that reads the whole body (`{body_format, binary}`) into one `status\ncontent-type\nbody`
  string. It is rewritten to stream through `httpc`'s `{sync, false}, {stream, self}` options, writing
  each chunk to the reply as it arrives; the heap assertion reads the relay process's memory through
  the sidecar. It does not move onto `rakun-client`: `rakun-web` has no edge to it, and adding one
  would drag the client into every web consumer (decision 185's rule).
- **R65-2.** Today the relay forwards no request header and only the upstream's content type back,
  so hop-by-hop headers are dropped by construction, unasserted. With streaming, the relay forwards
  headers through a fixed hop-by-hop list stripped both ways, plus the names in the `Connection`
  header's value (RFC 9110 § 7.6.1).
- **R82-1 / R80-1.** The dev property source (`devtools/devtools.bp`) gains one entry; `static_test.bp`'s
  existing `period=0` cell then runs under the dev profile and asserts `no-cache`.
- `rkStaticFsCalls()` counts filesystem calls for the traversal cells; the relay's upstream in tests
  is the in-process HTTP double; nothing is env-gated.

## Open

### Step 1 — The fall-through (R82-4, decision 201)

- [ ] `static_test.bp`: a root `/**` → `public/` and a request for a path no root resolves reaches the next chain entry (a recording entry after the static one sees it); a request for an existing file is served and the recorder does not run
- [ ] a `POST` (and a `PUT`) to a path a root would serve reaches the chain and the file is not served; `HEAD` is served (rule 2, an assertion of `staticEntry` as it is)
- [ ] a traversal, an encoded traversal and a bad segment are still final refusals (400/404) at the first matching root, `rkStaticFsCalls()` unchanged for the first two
- [ ] `AGENTS.md` § Static assets states the three rules; onze 69's registration box is named as the consumer

### Step 2 — The relay (R65-1, R65-2)

- [ ] `rules_test.bp`: a rewrite to the double answering a 4 MB body streams it — the relay process's peak memory stays under 512 KB (asserted through `rkProcessPeakMemory`), and the client receives every byte
- [ ] `Connection`, `Transfer-Encoding`, `Upgrade`, `Keep-Alive`, `Proxy-Connection`, `TE`, `Trailer` and every name in the upstream's `Connection` value are absent from the relayed response; the same list is absent from the relayed request (the double records it)

### Step 3 — The dev default (R82-1, R80-1, R82-2, R82-3)

- [ ] `rakun-data/src/devtools/devtools.bp`: the dev property source sets `rakun.web.resources.cache.period=0`; `rakun-data/test/devtools/devtools_test.bp` asserts the key is present under the dev profile and absent otherwise
- [ ] `static_test.bp`: under the dev profile every root answers `Cache-Control: no-cache`
- [ ] R82-2 reworded to "traversal and encoded traversal answer 404 without a filesystem call; a symlink escape by resolving the link, before any read" and ticked; the symlink cell asserts the escape is refused before any read (`rkStaticFsCalls()` grows by exactly the one `readlink`)
- [ ] R82-3 ("onze front 69's roots are served through `registerStaticRoot` with no second content-type table, ETag rule or traversal guard anywhere under `repository/`"): the grep (`fn contentTypeOf` only in `src/static.bp`) runs as a cell; onze registering is onze's (69)

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-web` and in `modules/rakun-data` (the `test/devtools/` files in the run).

Blast radius: step 1 changes a static-matched miss from 404 to the router's answer — what onze
49/69 need; `examples/rakun-ssr` registers no `/**` root. onze then registers its public root and
ONZ-49-4.3's third box closes on onze's side.

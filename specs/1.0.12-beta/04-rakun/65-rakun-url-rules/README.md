# Front 65 — URL Rules and Static Assets (`rakun-web`'s tail)

**Priority:** high — onze's public root waits on step 1 (every page URL is answered 404 by a `/**` static root today); the relay's hop-by-hop headers are a correctness gap in a proxy
**Carries:** 07 · 82 (and one line of 80's member by carve-out)
**Depends on:** `128-rakun-consolidation` (decision 187 merges `rakun-hateoas` into `rakun-web` and `rakun-devtools` into `rakun-data`) · `13-rakun-http-clients` step 3 (`retrieveStream`) for R65-1 · step 1 is written against decision 201 (`69-b` (a)) · compiler lg2-a / lg2-b (the streamed relay carries `string` chunks — enough for the assertion)
**Owns:** `modules/rakun-web/**` except 74's (`src/tls.bp`, `test/tls_test.bp`) — `src/hateoas/**`, where `rakun-hateoas` lives after 128, is included and holds no open box · `modules/rakun-data/src/devtools/devtools.bp` — the one line that sets the dev-profile default `rakun.web.resources.cache.period=0` — and its assertion in `modules/rakun-data/test/devtools/devtools_test.bp` (carve-out in 08's member; `rakun-devtools` below reads as these) · `repository/rakun/AGENTS.md` § Web, § Static assets
**Does not touch:** `tls.bp`, `test/tls_test.bp` (74's) · `rakun-app` (22's) · the devtools files beyond the one line · `repository/onze/**` (69's registration is onze's half) · while its front holds them, after this one has landed (decisions 188, 189): `src/{negotiation,compression,static,error}.bp`'s codec lines (`03-bundled-libs/104`'s consumer sweep) and `src/{middleware,filter}.bp`'s lines (`08-bpp/123`)

---

## Carried from 1.0.10

| Id | From (`specs/1.0.10-beta/03-rakun/`) | Box, as written |
|---|---|---|
| R65-1 | `65-rakun-url-rules/README.md` § Step 4 — Rewrites | "The relayed body is streamed: a 50 MB upstream response does not grow the server's heap by 50 MB, …" |
| R65-2 | same § Step 4 | "Hop-by-hop headers (`Connection`, `Transfer-Encoding`, `Upgrade`) are not relayed in either …" direction |
| R82-1 | `82-rakun-static-assets/README.md` § Step 5 — Cache policy and fingerprints | "The dev property default from front 80 sets `cacheSeconds` to 0 for every root under a dev profile — open: the entry honours `rakun.web.resources.cache.period` (0 → `no-cache` on every root, `static_test.bp`); the dev-profile default that sets it is front 80's" |
| R80-1 | closed `80-rakun-devtools/README.md` (the owed line) | the dev-profile property source sets `rakun.web.resources.cache.period=0` |
| R82-2 | same § Definition of done | "Traversal, encoded traversal and symlink escape all answer 404 without a filesystem call — … a symlink escape is 404 but is found by resolving the link, which is a filesystem call by nature — open as worded" — closes by amendment: "traversal and encoded traversal without a filesystem call; a symlink escape by resolving the link, before any read" |
| R82-3 | same § Definition of done | "onze front 69's roots are served through `registerStaticRoot` with no second content-type table, ETag rule or traversal guard anywhere under `repository/` …" — the grep holds; onze registering is onze's (69) |
| R82-4 | closed `status.md` L82 (RX-4) · decision 201 (`69-b`) | "rakun-web front 82 answers every request its root's pattern admits and a miss is a 404, so a `/**` → `public/` root answers every page URL" (`static.bp:48-49`: "A path some root matched but no root resolves is 404 from this entry — it does not fall through to the router") |
| RX-2 (07's files) | — | none; 07 carries no stale text |

## Problem

```
static root "/**" -> public/   ;   GET /blog/hello   ->   404 (from the static entry; the router never sees it)
```

`static.bp:44-49` states the rule: a matched path that no root resolves is 404 from the entry.
Next's order is a public file first, the routes otherwise. The relay reads the upstream body as one
string and forwards `Connection`, `Transfer-Encoding` and `Upgrade` as received.

## Current state

`modules/rakun-web`: 15 test files + `fixtures/{errors-family,errors-full}`, 209 tests green.
`src/static.bp` (82): roots in registration order, first resolving root serves, refusals final at
the first matching root; `rkStaticFsCalls()` counts filesystem calls for the traversal cells.
`src/rules.bp` (65): rewrites, redirects, `basePath`, the relay over `rakun-client`. `src/tls.bp`
is 74's. `rakun-devtools/src/devtools.bp` holds the dev property source (80), which does not set
the cache period.

## Mechanism

- Decision 201 — three rules, as Next and `express.static` do: (1) a miss falls through —
  `serveFrom` answers `chain.next()` instead of `Response.notFound()` when no matching root
  resolves an existing file, so the routes run; (2) only `GET` and `HEAD` are served, and any
  other method goes to the chain; (3) a refusal stays final at the entry — 400 for a bad decode,
  404 for a refused segment: a path that was refused is not offered to a route. No configuration
  key: the rules are the entry's. onze registers `public/` at `/**` before the routes, beside the
  fingerprinted root (`07-onze/49` step 4).
- R65-1: the relay uses 13's `retrieveStream` and writes each chunk to the reply as it arrives;
  the heap assertion reads the relay process's memory through the sidecar.
- R65-2: a fixed list of hop-by-hop names stripped in both directions, plus the names listed in
  the `Connection` header's value (RFC 9110 § 7.6.1).
- R82-1 / R80-1: the dev property source (`devtools.bp`) gains one entry; `static_test.bp`'s
  existing cell for `period=0` then runs under the dev profile and asserts `no-cache`.

## Gate stance

No env-gated cell; the relay's upstream is the in-process HTTP double.

## Steps

### Step 1 — The fall-through (R82-4, decision 201)

The three rules of § Mechanism. The acceptance below predates decision 201 and has no box for its
second rule (a `POST` to a path a root would serve reaches the chain); the front adds it when it
opens.

**Acceptance:**
- [ ] `static_test.bp`: a root `/**` → `public/` and a request for a path no root resolves reaches the next chain entry (a recording entry after the static one sees it); a request for an existing file is served and the recorder does not run
- [ ] a traversal, an encoded traversal and a bad segment are still final refusals (400/404) at the first matching root, `rkStaticFsCalls()` unchanged for the first two
- [ ] `AGENTS.md` § Static assets states the rule; onze 69's registration box is named as the consumer

### Step 2 — The relay (R65-1, R65-2)

**Acceptance:**
- [ ] `rules_test.bp`: a rewrite to the double answering a 4 MB body streams it — the relay process's peak memory stays under 512 KB (asserted through `rkProcessPeakMemory`), and the client receives every byte
- [ ] `Connection`, `Transfer-Encoding`, `Upgrade`, `Keep-Alive`, `Proxy-Connection`, `TE`, `Trailer` and every name in the upstream's `Connection` value are absent from the relayed response; the same list is absent from the relayed request (the double records it)

### Step 3 — The dev default (R82-1, R80-1, R82-2)

**Acceptance:**
- [ ] `rakun-devtools/src/devtools.bp`: the dev property source sets `rakun.web.resources.cache.period=0`; `rakun-devtools/test/devtools_test.bp` asserts the key is present under the dev profile and absent otherwise
- [ ] `static_test.bp`: under the dev profile every root answers `Cache-Control: no-cache`
- [ ] R82-2 reworded and ticked; the symlink cell asserts the escape is refused before any read (`rkStaticFsCalls()` grows by exactly the one `readlink`)

## Gate

- [ ] `botopink test --target erlang` green in `modules/rakun-web` and in `modules/rakun-data` (the `test/devtools/` files in the run)
- [ ] `botopink format --check` clean in both
- [ ] `AGENTS.md` sections updated
- [ ] commit on `fix/65-rakun-url-rules`

## Blast radius

Step 1 changes the answer for a static-matched miss from 404 to "the router's answer" — the
behaviour onze 49/69 need; `examples/rakun-ssr` registers no `/**` root and is unaffected. Onze
then registers its public root (69's box) and ONZ-49-4.3's third box closes on onze's side.

## Notes

- 82's "symlink escape without a filesystem call" is impossible by construction; the amendment
  keeps the guarantee that matters (no read of the target).
- R82-3's grep (`fn contentTypeOf` only in `src/static.bp`) is re-run in the gate as a cell.

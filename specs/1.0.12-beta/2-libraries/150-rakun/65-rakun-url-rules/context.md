# Front 65 — URL rules and static assets: the fall-through, a streamed relay, the dev cache default

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [150-rakun](../README.md): s1 → 150 s16 · s2 → 150 s16 · s3 → 150 s16 · s4 → 150 s16. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** high — onze's public root waits on step 1 (a `/**` static root answers every page URL
404 today); an unasserted hop-by-hop rule is a proxy correctness gap · **State:** not started
(decision 201's rule 2 already in code)
**Depends on:** 128 · decision 201 (step 1) · lg2-b · 346's `Bytes`, unbuilt (relay carries the body as `string`
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

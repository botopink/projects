# Front 104 — http: a bundled `http`, the codecs of HTTP semantics

**Priority:** high — four `Cookie:` readers with three duplicate rules is a correctness defect under
cookie tossing · **State:** partial: steps 1–4 (the package) on feat; step 5 open
**Depends on:** step 5 — the fronts that own its consumer files landed: `04-rakun` 04, 65, 79, 12,
19, 22 and `08-bpp/123` (also in rakun-web), `07-onze` 49 and 51 (decision 188)
**Owns:** `repository/botopink-lang/libs/http/**` · the three registration lines (`build.zig`
`bundled_packages`, `libs/AGENTS.md` packages table, `scripts/format-check.sh` `TREES`) · consumers:
`repository/rakun/modules/rakun/src/request_context.bp` (the cookie lookup and `equalsConstantTime`
sites), `rakun-web/src/{negotiation,compression,static,error}.bp`, `rakun-security/src/csrf.bp`
(`cookieValue`), `rakun-session/src/session_cookie.bp`, `rakun-app/src/i18n.bp` (`cookieFrom`,
`qPerMille` only — 105 takes the rest of the generic half after), `rakun-test/src/fake_request.bp`,
`repository/onze/modules/onze-server/src/server.bp` (`cookiePairs`),
`repository/onze/modules/onze-assets/src/image_handler.bp` (its MIME table) · the reason-phrase
tables in `rakun/src/sidecars/rakun_runtime.erl`, `rakun_ssr.erl`, `rakun_websocket.erl` are
**read, not edited** (§ Mechanism)
**Does not touch:** the HTTP/1.1 wire parsers (`decode_packet` in `rakun_runtime.erl` and
`rakun_client.erl`) and compression bodies (`zlib`) — both wait on lg2-a (a byte type) · `hash.etag`
and friends (std owns them) · any other line of the members above

## Goal

One codec per piece of HTTP semantics, consumed by rakun and onze: first-wins cookies (decision 181),
the strict q-value (decision 182), one reason-phrase table, one MIME table, one HTTP-date, Range and
Cache-Control — `import {cookie, accept} from "http";` (decision 196).

## Mechanism

The copies step 5 deletes:

| Codec | Copies on feat | Divergence |
|---|---|---|
| `Cookie:` reader | `request_context.cookieLookup` (first-wins, percent-decoded, control chars refused) · `csrf.cookieValue` (first-wins, undecoded) · `i18n.cookieFrom` (first-wins, prefix match, no name trim) · `session_cookie.cookieFromHeader` (**last-wins**) · rakun-test `fake_request.bp` · onze-server `cookiePairs` (delegates to rakun's `cookieLookup`; it switches to `http.cookie`) | the session and CSRF readers disagree on the same header |
| `Set-Cookie` writer | `serializeCookie` · `sessionCookieHeader` / `expiredCookieHeader` | two attribute spellings |
| q-value | `negotiation.rangeQ` = `compression.qMillis` · `i18n.qPerMille` (stricter) | lenient vs strict |
| Reason phrase | `rakun-web/error.bp` `statusReason` · three `.erl` sidecars | four tables to keep equal |
| MIME | `rakun-web/static.bp` · `onze-assets/image_handler.bp` | two tables |
| HTTP-date | `rakun_static.erl` (via `static.bp`) | erlang-only; onze has none |
| Range, Cache-Control | `static.bp` | one each, hand-built |

`static.bp`'s `etagMatches` is a copy of std's `hash.matches`, deleted for it. The three `.erl`
reason-phrase tables are not edited: the sidecar functions that need a phrase receive it as an
argument from the `.bp` caller; a sidecar that computes a status with no `.bp` caller in the path is
reported to `04-rakun`, not patched here.

## Done

- Step 1 — `cookie`: `parse` (first-wins, decision 181), `get`, `serialize` over
  `CookieAttributes`, `formatHeader`
- Step 2 — `accept`: the strict `qValue` (decision 182), media / token / language negotiation
- Step 3 — `mime`, `status`, `date`, `byteRange`, `cacheControl`
- Step 4 — registration in `build.zig`, `libs/AGENTS.md`, `scripts/format-check.sh`; `libs/http/AGENTS.md`

## Open

### Step 5 — the consumer sweep

One commit per member, after the front that owns the member has landed.

- [ ] rakun-session's `cookieFromHeader` deleted; its store tests green with first-wins asserted
- [ ] `negotiation.rangeQ`, `compression.qMillis`, `i18n.qPerMille` deleted; the three members'
      tests green (the negotiation tests that relied on leniency are rewritten to refuse, per
      decision 182)
- [ ] one MIME table: `image_handler.bp` and `static.bp` import it; `static.bp` drops
      `etagMatches` for std `hash.matches`
- [ ] `error.bp`'s `statusReason` table deleted; the sidecars receive the phrase from the `.bp` side
- [ ] every consumer file above imports `http`; `grep -rn
      "cookieFromHeader\|rangeQ\|qMillis\|qPerMille" repository/{rakun,onze}/modules` is empty
- [ ] each touched member's `AGENTS.md` updated in its commit

**Gate:** standard (fronts.md § Gate), for the sweep

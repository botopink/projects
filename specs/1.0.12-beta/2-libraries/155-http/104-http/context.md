# Front 104 — http: a shared `http`, the codecs of HTTP semantics

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [155-http](../README.md): s6 → 155 s1 · s5 → 155 s2. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** high — four `Cookie:` readers with three duplicate rules: a correctness defect under
cookie tossing · **State:** partial: steps 1–4 (the package) on feat; step 5 open
**Depends on:** step 5 — owners of its consumer files landed: `04-rakun` 04, 65, 79, 12, 19, 22 and
`08-bpp/123` (also in rakun-web), `07-onze` 49 and 51 (decision 188)
**Owns:** `repository/http/**` (`botopink/http`, a repository of its own since 138 (decision 326)) · consumers:
`repository/rakun/modules/rakun/src/request_context.bp` (cookie lookup, `equalsConstantTime` sites),
`rakun-web/src/{negotiation,compression,static,error}.bp`, `rakun-security/src/csrf.bp`
(`cookieValue`), `rakun-session/src/session_cookie.bp`, `rakun-app/src/i18n.bp` (`cookieFrom`,
`qPerMille` only — 105 takes the rest of the generic half), `rakun-test/src/fake_request.bp`,
`repository/onze/modules/onze-server/src/server.bp` (`cookiePairs`),
`repository/onze/modules/onze-assets/src/image_handler.bp` (its MIME table) · reason-phrase tables in
`rakun/src/sidecars/rakun_runtime.erl`, `rakun_ssr.erl`, `rakun_websocket.erl` **read, not edited**
**Does not touch:** HTTP/1.1 wire parsers (`decode_packet` in `rakun_runtime.erl`,
`rakun_client.erl`) and compression bodies (`zlib`) — wait on 346's `Bytes` (`01-checker` step 32) · `hash.etag` and
friends (std) · other lines of those members

## Goal

One codec per piece of HTTP semantics, for rakun and onze: first-wins cookies (decision 181), strict
q-value (decision 182), one reason-phrase table, one MIME table, one HTTP-date, Range, Cache-Control
— `import {cookie, accept} from "http";` (decision 196).

## Mechanism

Copies step 5 deletes:

| Codec | Copies on feat | Divergence |
|---|---|---|
| `Cookie:` reader | `request_context.cookieLookup` (first-wins, percent-decoded, control chars refused) · `csrf.cookieValue` (first-wins, undecoded) · `i18n.cookieFrom` (first-wins, prefix match, no name trim) · `session_cookie.cookieFromHeader` (**last-wins**) · rakun-test `fake_request.bp` · onze-server `cookiePairs` (delegates to `cookieLookup`; switches to `http.cookie`) | session and CSRF readers disagree on one header |
| `Set-Cookie` writer | `serializeCookie` · `sessionCookieHeader` / `expiredCookieHeader` | two attribute spellings |
| q-value | `negotiation.rangeQ` = `compression.qMillis` · `i18n.qPerMille` (stricter) | lenient vs strict |
| Reason phrase | `rakun-web/error.bp` `statusReason` · three `.erl` sidecars | four tables |
| MIME | `rakun-web/static.bp` · `onze-assets/image_handler.bp` | two tables |
| HTTP-date | `rakun_static.erl` (via `static.bp`) | erlang-only; onze has none |
| Range, Cache-Control | `static.bp` | one each, hand-built |

- `static.bp`'s `etagMatches` copies std `hash.matches` → deleted for it.
- The three `.erl` phrase tables stay unedited: a sidecar function needing a phrase receives it as
  an argument from its `.bp` caller; a sidecar computing a status with no `.bp` caller in the path is
  reported to `04-rakun`, not patched here.

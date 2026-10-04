# Front 104 — http: a bundled `http`, the codecs of HTTP semantics

**Priority:** high — four `Cookie:` readers with three duplicate rules: a correctness defect under
cookie tossing · **State:** partial: steps 1–4 (the package) on feat; step 5 open
**Depends on:** step 5 — owners of its consumer files landed: `04-rakun` 04, 65, 79, 12, 19, 22 and
`08-bpp/123` (also in rakun-web), `07-onze` 49 and 51 (decision 188)
**Owns:** `repository/botopink-lang/libs/http/**` · the three registration lines (`build.zig`
`bundled_packages`, `libs/AGENTS.md` packages table, `scripts/format-check.sh` `TREES`) · consumers:
`repository/rakun/modules/rakun/src/request_context.bp` (cookie lookup, `equalsConstantTime` sites),
`rakun-web/src/{negotiation,compression,static,error}.bp`, `rakun-security/src/csrf.bp`
(`cookieValue`), `rakun-session/src/session_cookie.bp`, `rakun-app/src/i18n.bp` (`cookieFrom`,
`qPerMille` only — 105 takes the rest of the generic half), `rakun-test/src/fake_request.bp`,
`repository/onze/modules/onze-server/src/server.bp` (`cookiePairs`),
`repository/onze/modules/onze-assets/src/image_handler.bp` (its MIME table) · reason-phrase tables in
`rakun/src/sidecars/rakun_runtime.erl`, `rakun_ssr.erl`, `rakun_websocket.erl` **read, not edited**
**Does not touch:** HTTP/1.1 wire parsers (`decode_packet` in `rakun_runtime.erl`,
`rakun_client.erl`) and compression bodies (`zlib`) — wait on lg2-a (byte type) · `hash.etag` and
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

## Done

- Step 1 — `cookie`: `parse` (first-wins, decision 181), `get`, `serialize` over `CookieAttributes`,
  `formatHeader`
- Step 2 — `accept`: strict `qValue` (decision 182), media / token / language negotiation
- Step 3 — `mime`, `status`, `date`, `byteRange`, `cacheControl`
- Step 4 — registered in `build.zig`, `libs/AGENTS.md`, `scripts/format-check.sh`; `libs/http/AGENTS.md`

## Open

### Step 5 — the consumer sweep

One commit per member, after the member's owning front has landed.

- [ ] rakun-session's `cookieFromHeader` deleted; store tests green with first-wins asserted
- [ ] `negotiation.rangeQ`, `compression.qMillis`, `i18n.qPerMille` deleted; the three members'
      tests green (negotiation tests relying on leniency rewritten to refuse, decision 182)
- [ ] one MIME table: `image_handler.bp` and `static.bp` import it; `static.bp` drops
      `etagMatches` for std `hash.matches`
- [ ] `error.bp`'s `statusReason` table deleted; sidecars receive the phrase from the `.bp` side
- [ ] every consumer file above imports `http`; `grep -rn
      "cookieFromHeader\|rangeQ\|qMillis\|qPerMille" repository/{rakun,onze}/modules` is empty
- [ ] each touched member's `AGENTS.md` updated in its commit

### Step 6 — a cookie is declared once, typed (decision 294)

- [ ] `pub type Cookie<T>(name: string, httpOnly: bool = true, secure: bool = true, sameSite:
      SameSite = .Lax, maxAge: ?Duration = null, path: string = "/")` in `libs/http` (the package both
      jhonstart and rakun reach, 113); `T` one `http` can encode — `string`, numbers, `bool`, an enum,
      a one-field record — a value that does not decode reads as absent
- [ ] `pub type Local<T>()` — a request-scoped atom, its identity the declaration (295), no name
- [ ] `cookie.read(decl, header) -> ?T` (first-wins, 181) and `cookie.write(decl, value) -> string`
      (a `Set-Cookie` line carrying the declaration's attributes), `cookie.clear(decl)`; tests per `T` kind

**Gate:** standard (fronts.md § Gate), for the sweep

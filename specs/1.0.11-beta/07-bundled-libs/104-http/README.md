# Front 104 — a bundled `http`: the codecs of HTTP semantics

**Priority:** high — four `Cookie:` readers with three duplicate rules is a correctness defect
under cookie tossing, not a tidiness item.
**Depends on:** `00-gate` green · `02-std-and-packaging/97-std-dedupe` (`string.parseInt`,
`clock.parseDuration`) · `07-a`, `07-d`, `07-e`, `07-i`.
**Owns:** `repository/botopink-lang/libs/http/**` (new package) · the three registration lines:
`build.zig` `bundled_packages` (after `routing`), `libs/AGENTS.md` packages table,
`scripts/format-check.sh` `TREES` · consumers: `repository/rakun/modules/rakun/src/request_context.bp`
(the cookie lookup and `equalsConstantTime` sites), `rakun-web/src/{negotiation,compression,static,error}.bp`,
`rakun-security/src/csrf.bp` (`cookieValue`), `rakun-session/src/session_cookie.bp`,
`rakun-test/src/fake_request.bp` (`:136`), `repository/onze/modules/onze-server/src/server.bp` (`:61`),
`repository/onze/modules/onze-assets/src/image_handler.bp` (`:92-99`) · the reason-phrase tables in
`rakun/src/sidecars/rakun_runtime.erl:1372`, `rakun_ssr.erl:208`, `rakun_websocket.erl:178` are
**read, not edited**: the `.bp` side answers the phrase and the sidecar receives it (see Notes).
**Does not touch:** the HTTP/1.1 wire parsers (`decode_packet` in `rakun_runtime.erl` and
`rakun_client.erl`) · compression bodies (`zlib`) · `hash.etag` and friends (std owns them) · any
other line of the members above.

---

## Problem

| Codec | Copies | Divergence |
|---|---|---|
| `Cookie:` reader | `request_context.cookieLookup` (first-wins, percent-decoded, control chars refused) · `csrf.cookieValue` (first-wins, undecoded) · `i18n.cookieFrom` (first-wins, prefix match, no name trim) · `session_cookie.cookieFromHeader` (**last-wins**) · onze-server `server.bp:61` · rakun-test `fake_request.bp:136` | the session and CSRF readers disagree on the same header |
| `Set-Cookie` writer | `serializeCookie` · `sessionCookieHeader` / `expiredCookieHeader` | two attribute spellings |
| q-value | `negotiation.rangeQ` = `compression.qMillis` · `i18n.qPerMille` (stricter: ≤3 decimals, digits only) | lenient vs strict |
| Reason phrase | `rakun-web/error.bp:86` · three `.erl` sidecars | four tables to keep equal |
| MIME | `rakun-web/static.bp:225-256` · `onze-assets/image_handler.bp:92-99` | two tables |
| HTTP-date | `rakun_static.erl` (via `static.bp:113-116`) | erlang-only; onze has none |
| Range, Cache-Control | `static.bp:331`, `:558` | one each, hand-built |

## Current state

Every site above is pure `.bp` or a `.erl` table; none needs a byte type. `hash.etag` /
`weakEtag` / `matches` already live in std (`libs/std/src/hash.bp:202-230`); rakun-web's
`etagMatches` (`static.bp:503`) is a copy to delete, not a module to write.

## Steps

### Step 1 — `cookie`

`parse(header) -> Array<#(string, string)>` (first-wins, RFC 6265 § 5.4 — `07-d`), `get(header, name) -> ?string`,
`serialize(name, value, CookieAttrs) -> string`. Percent-decoding as `request_context` does today;
a control character in a value is refused (`07-d`).

**Acceptance:**
- [ ] `libs/http/test/cookie_test.bp`: tossing (`a=1; a=2` → `1`), an undecodable value refused,
      `serialize` byte-identical to today's `sessionCookieHeader` for the same attributes
- [ ] rakun-session's `cookieFromHeader` deleted; its store tests green with first-wins asserted

### Step 2 — `accept`

`qValue(text) -> i32` per mille (`07-e` strict), `parseAccept`, `mediaQuality`, `negotiateMedia`,
`negotiateToken` (encodings), `parseAcceptLanguage`.

**Acceptance:**
- [ ] known-answer tests over the RFC 9110 § 12 examples on both rows
- [ ] `negotiation.rangeQ`, `compression.qMillis`, `i18n.qPerMille` deleted; the three members'
      tests green (the negotiation tests that relied on leniency are rewritten to refuse, per `07-e`)

### Step 3 — `mime`, `status`, `date`, `range`, `cacheControl`

`mime.contentTypeOf(pathOrExt)`, `mime.isText`; `status.reasonPhrase(code)`;
`date.formatHttpDate(epochMillis)` and `parseHttpDate` (pure, over std `clock.toCivil` and a
days-from-civil function — no bitwise); `range.parseRange(header, size)`; a `cacheControl` builder.

**Acceptance:**
- [ ] one MIME table: `image_handler.bp` and `static.bp` import it; `static.bp` drops
      `etagMatches` for std `hash.matches`
- [ ] `formatHttpDate(0)` is `Thu, 01 Jan 1970 00:00:00 GMT` on both rows; `parseHttpDate` reads
      the three RFC 9110 § 5.6.7 forms
- [ ] `error.bp:86`'s table deleted; the sidecars receive the phrase from the `.bp` side (Notes)

### Step 4 — registration and the consumer sweep

- [ ] `build.zig` lists `http` after `routing`; `libs/AGENTS.md` row; `scripts/format-check.sh` tree
- [ ] every consumer file above imports `http`; `grep -rn "cookieFromHeader\|rangeQ\|qMillis\|qPerMille\|bracketToColon" repository/{rakun,onze}/modules` is empty

## Gate

- [ ] `zig build test` cold, green; `zig build test-libs` green, no new ledger line
- [ ] `libs/http/AGENTS.md` written; every touched `AGENTS.md` updated in the same commit
- [ ] Commit on `front/104-http`

## Blast radius

Nine consumer files across rakun and onze; rakun-session's duplicate rule changes (`07-d`);
negotiation's leniency ends (`07-e`). No snapshot directory is shared.

## Notes

- The three `.erl` reason-phrase tables are not edited by this front: the sidecar functions that
  need a phrase receive it as an argument from the `.bp` caller. If a sidecar computes a status
  with no `.bp` caller in the path, that site is reported to `03-rakun`, not patched here.
- Out of scope by design: the wire parser (twice, `decode_packet`) and compression — both wait on
  lg2-a (a byte type). ETag stays in std.

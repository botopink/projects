# Front 104 — a bundled `http`: the codecs of HTTP semantics

**Priority:** high — four `Cookie:` readers with three duplicate rules is a correctness defect
under cookie tossing, not a tidiness item.
**Depends on:** `00-gate` green · `02-std-and-packaging/97-std-dedupe` (`string.parseInt`,
`clock.parseDuration`). No open question: the package exists by decision 196 (`07-a` (a): a
bundled `http`, `import {cookie, accept} from "http";` — not std modules, not the copies), and the
codecs are written against decisions 181 (`07-d`: first-wins cookies), 182 (`07-e`: the strict
q-value) and 163 (`07-i`: no exported name std or a framework exports). The consumer sweep
(step 5) waits, besides, on the fronts that own its consumer files having landed — `04-rakun` 04,
65, 79, 12, 19, 22 and `08-bpp/123` (also in rakun-web), `07-onze` 49 and 51 (decision 188).
**Owns:** `repository/botopink-lang/libs/http/**` (new package) · the three registration lines:
`build.zig` `bundled_packages` (after `routing`), `libs/AGENTS.md` packages table,
`scripts/format-check.sh` `TREES` · consumers: `repository/rakun/modules/rakun/src/request_context.bp`
(the cookie lookup and `equalsConstantTime` sites), `rakun-web/src/{negotiation,compression,static,error}.bp`,
`rakun-security/src/csrf.bp` (`cookieValue`), `rakun-session/src/session_cookie.bp`,
`rakun-app/src/i18n.bp` (`cookieFrom`, `qPerMille` only — 105 takes the rest of the generic half after),
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

The front is cut in two step groups under one number (decision 189). The **package half** —
steps 1–4 — writes `libs/http/**` and the three registration lines; it edits no library file,
collides with no library front, and opens as soon as the gate is green and 97 has landed. The **consumer sweep** —
step 5 — is one commit per member on the lines § Owns names; it never shares a wave with a front
that owns one of those members and runs after they have landed (decision 188).

### Step 1 — `cookie` (package half)

`parse(header) -> Array<#(string, string)>` (first-wins, RFC 6265 § 5.4 — decision 181), `get(header, name) -> ?string`,
`serialize(name, value, CookieAttributes) -> string` (`maxAge: ?i32`, `null` omits `Max-Age`),
`formatHeader(pairs)` (a request `Cookie` header). Percent-decoding as `request_context` does
today; a value outside cookie-octet, a malformed escape or one decoding to a control character
is refused, and a refused first occurrence still claims its name (decision 181). The record is
`CookieAttributes`, not `CookieAttrs`: rakun exports `CookieAttrs` (decision 163).

**Acceptance:**
- [x] `libs/http/test/cookie_test.bp`: tossing (`a=1; a=2` → `1`), an undecodable value refused,
      `serialize` byte-identical to today's `sessionCookieHeader` for the same attributes

### Step 2 — `accept` (package half)

`qValue(text) -> i32` per mille (decision 182: strict — at most three decimals, digits only,
anything malformed reads as 0), `parseAccept -> Array<MediaRange>`, `mediaQuality`,
`negotiateMedia`, `tokenQuality` / `negotiateToken` (encodings, `identity` acceptable unless
excluded), `parseAcceptLanguage -> Array<LanguageRange>`.

**Acceptance:**
- [x] known-answer tests over the RFC 9110 § 12 examples on both rows

### Step 3 — `mime`, `status`, `date`, `byteRange`, `cacheControl` (package half)

`mime.contentTypeOf(pathOrExt)`, `mime.extensionOf`, `mime.isText`; `status.reasonPhrase(code)`
(`""` for an unregistered code); `date.formatHttpDate(epochMillis: i64)` and
`parseHttpDate(text, nowMillis: i64) -> @Result<i64, string>` (pure, over std `clock.toCivil` and
a days-from-civil function — no bitwise; `nowMillis` only places an RFC 850 two-digit year);
`byteRange.parseRange(header, size: i64) -> ByteRange(status, first, last)` and `contentRange`
(the module is `byteRange`: erika exports `range`, decision 163); a `cacheControl` builder
(`directives()`, `with*`, `render`, `staticFile`).

**Acceptance:**
- [x] `formatHttpDate(0)` is `Thu, 01 Jan 1970 00:00:00 GMT` on both rows; `parseHttpDate` reads
      the three RFC 9110 § 5.6.7 forms

### Step 4 — registration (package half)

- [x] `build.zig` lists `http` after `routing`; `libs/AGENTS.md` row; `scripts/format-check.sh` tree

### Step 5 — the consumer sweep

One commit per member, after the front that owns the member has landed.

**Acceptance:**
- [ ] rakun-session's `cookieFromHeader` deleted; its store tests green with first-wins asserted
- [ ] `negotiation.rangeQ`, `compression.qMillis`, `i18n.qPerMille` deleted; the three members'
      tests green (the negotiation tests that relied on leniency are rewritten to refuse, per
      decision 182)
- [ ] one MIME table: `image_handler.bp` and `static.bp` import it; `static.bp` drops
      `etagMatches` for std `hash.matches`
- [ ] `error.bp:86`'s table deleted; the sidecars receive the phrase from the `.bp` side (Notes)
- [ ] every consumer file above imports `http`; `grep -rn "cookieFromHeader\|rangeQ\|qMillis\|qPerMille\|bracketToColon" repository/{rakun,onze}/modules` is empty

## Gate

- [ ] `zig build test` cold, green (package half: green); `zig build test-libs` green, no new ledger line (package half: the `http` cells green)
- [x] `libs/http/AGENTS.md` written; every touched `AGENTS.md` updated in the same commit
- [x] Commit on `front/104-http` (package half)

## Blast radius

Ten consumer files across rakun and onze; rakun-session's duplicate rule changes (decision 181);
negotiation's leniency ends (decision 182). No snapshot directory is shared.

## Notes

- The three `.erl` reason-phrase tables are not edited by this front: the sidecar functions that
  need a phrase receive it as an argument from the `.bp` caller. If a sidecar computes a status
  with no `.bp` caller in the path, that site is reported to `04-rakun`, not patched here.
- Out of scope by design: the wire parser (twice, `decode_packet`) and compression — both wait on
  lg2-a (a byte type). ETag stays in std.

# Front 105 — a bundled `i18n`: one locale grammar for the server and the page

**Priority:** medium — jhonstart and rakun disagree on whether `zh-Hant-TW` is a locale.
**Depends on:** `104-http`, both halves (both edit `rakun-app/src/i18n.bp`; `parseAcceptLanguage`
comes from `http.accept`) · confirmation of 03r-q (which already anticipates this move). The
grammar is written against decision 180 (`07-c`: one BCP 47 subset) and the surface against
decision 163 (`07-i`); no open question of its own. Its consumer commits run after `04-rakun/22`
and `05-jhonstart/26` have landed, and the `messages.bp` commit lands between two steps of
`125-validation-zod`, which owns the file (decisions 188, 189).
**Owns:** `repository/botopink-lang/libs/i18n/**` (new) · the three registration lines (after 104
lands, this front appends — one front at a time, decision 189) · consumers: `repository/rakun/modules/rakun-app/src/i18n.bp` (lines
60-215, 347-357 — the generic half), `repository/jhonstart/modules/jhonstart/src/render.bp:453`
(`isLangTag`), `repository/botopink-lang/libs/validation/src/messages.bp:96` (`interpolate`).
**Does not touch:** rakun-app's `persistent_term` registry, the redirect filter, `setLocaleCookie`,
the dictionary loader and cache, the `rakun.i18n.exclude` key (they stay; `04-rakun` 64 owns
them) · the rest of `render.bp` (`05-jhonstart` 30).

---

## Problem

`rakun-app/i18n.bp` `wellFormedTag` accepts `ll(l)` plus an optional `-RR` / `-999`; jhonstart's
`isLangTag` accepts a script subtag. The `<html lang>` jhonstart writes and the locale rakun routes
can name different sets. validation's `{name}` `interpolate` is a third locale-adjacent helper
with no owner.

## Steps

### Step 1 — the package

`LocaleSet`, `wellFormedTag` / `normalizeTag` / `isSupported` under decision 180's grammar (BCP 47
subset: language 2–3 letters, optional script 4, optional region 2 letters or 3 digits; case
normalised; anything else refused), `negotiate(set, acceptLanguage, cookieValue) -> ?string`
(pure, over `http.accept.parseAcceptLanguage`), `localeOfPath` / `stripLocale` / `withLocale`,
`alternatesFor`, `interpolate(template, bindings)` (moved from validation; validation imports
`i18n` — bundled to bundled is allowed). **No plural rules**: none exist today and none are invented.

**Acceptance:**
- [ ] `libs/i18n/test/tag_test.bp`: `zh-Hant-TW`, `pt-BR`, `en-419` accepted and normalised;
      `x-private`, `en-US-u-ca-gregory` refused; both rows
- [ ] `negotiate` known-answers over RFC 4647 basic filtering examples

### Step 2 — consumers

- [ ] rakun-app keeps only its registry, filter, cookie and loader; the generic half deleted
- [ ] jhonstart `isLangTag` deleted; `render.bp` imports `i18n.wellFormedTag`
- [ ] validation's `interpolate` deleted; `messages.bp` imports `i18n.interpolate`; validation's 54
      tests unchanged

## Gate

- [ ] `zig build test` cold, green; `zig build test-libs` green
- [ ] `libs/i18n/AGENTS.md` written; touched `AGENTS.md` files updated
- [ ] Commit on `front/105-i18n`

## Blast radius

Three consumer files; `i18n` is a new bundled name (decision 163: it exports no name std or a framework
already exports — checked against `libs/std/src/root.bp` and each framework's root).

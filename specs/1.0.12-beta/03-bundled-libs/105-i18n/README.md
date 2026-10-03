# Front 105 — i18n: a bundled `i18n`, one locale grammar for the server and the page

**Priority:** medium — jhonstart and rakun disagree on whether `zh-Hant-TW` is a locale ·
**State:** not started
**Depends on:** `104-http` step 5 (both edit `rakun-app/src/i18n.bp`; `parseAcceptLanguage` comes
from `http.accept`, already on feat) · `04-rakun/22` and `05-jhonstart/26` landed (the consumer
commits) · confirmation of 03r-q (which anticipates this move). The grammar is decision 180's
(`07-c`); the surface is checked against decision 163.
**Owns:** `repository/botopink-lang/libs/i18n/**` (new) · the three registration lines (append,
after 106 and before 107 — decision 189) · consumers: `repository/rakun/modules/rakun-app/src/i18n.bp`
(the generic half: `wellFormedTag`, `normalizeTag`, `isSupported`, `parseAcceptLanguage`,
`negotiate`, `localeOfPath`, `stripLocale`, `withLocale`, `alternatesFor` and their private
helpers), `repository/jhonstart/modules/jhonstart/src/render.bp` (`isLangTag` only),
`repository/botopink-lang/libs/validation/src/messages.bp` (`interpolate` only — the commit lands
between two steps of `125-validation-zod`, which owns the file)
**Does not touch:** rakun-app's `persistent_term` registry, the redirect filter, `setLocaleCookie`,
the dictionary loader and cache, the `rakun.i18n.exclude` key (they stay; `04-rakun` owns them) ·
the rest of `render.bp` (`05-jhonstart` 26)

## Goal

rakun-app's `wellFormedTag` accepts `ll(l)` plus an optional `-RR` / `-999`; jhonstart's
`isLangTag` accepts a script subtag, so the `<html lang>` jhonstart writes and the locale rakun
routes can name different sets; validation's `{name}` `interpolate` is a third locale-adjacent
helper with no owner. When the front lands, all three read `i18n`.

## Open

### Step 1 — the package

`LocaleSet`, `wellFormedTag` / `normalizeTag` / `isSupported` under decision 180's grammar (language
2–3 letters, optional script 4, optional region 2 letters or 3 digits; case normalised; anything
else refused), `negotiate(set, acceptLanguage, cookieValue) -> ?string` (pure, over
`http.accept.parseAcceptLanguage`), `localeOfPath` / `stripLocale` / `withLocale`, `alternatesFor`,
`interpolate(template, bindings)` (moved from validation; validation imports `i18n` — bundled to
bundled is allowed). **No plural rules**: none exist today and none are invented. No exported name
std or a framework exports (decision 163, checked against `libs/std/src/root.bp` and each
framework's root).

- [ ] `libs/i18n/test/tag_test.bp`: `zh-Hant-TW`, `pt-BR`, `en-419` accepted and normalised;
      `x-private`, `en-US-u-ca-gregory` refused; both rows
- [ ] `negotiate` known-answers over RFC 4647 basic filtering examples

### Step 2 — consumers

- [ ] rakun-app keeps only its registry, filter, cookie and loader; the generic half deleted
- [ ] jhonstart `isLangTag` deleted; `render.bp` imports `i18n.wellFormedTag`
- [ ] validation's `interpolate` deleted; `messages.bp` imports `i18n.interpolate`; validation's
      tests unchanged

**Gate:** standard (fronts.md § Gate) + `libs/i18n/AGENTS.md` written

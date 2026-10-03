# Front 105 — i18n: a bundled `i18n`, one locale grammar for the server and the page

**Priority:** medium — jhonstart and rakun disagree on whether `zh-Hant-TW` is a locale ·
**State:** not started
**Depends on:** `104-http` step 5 (both edit `rakun-app/src/i18n.bp`; `parseAcceptLanguage` from
`http.accept`, on feat) · `04-rakun/22`, `05-jhonstart/26` landed (consumer commits) · 03r-q
confirmed. Grammar: decision 180 (`07-c`); surface checked against decision 163.
**Owns:** `repository/botopink-lang/libs/i18n/**` (new) · the three registration lines (append after
106, before 107 — decision 189) · consumers: `repository/rakun/modules/rakun-app/src/i18n.bp` (generic
half: `wellFormedTag`, `normalizeTag`, `isSupported`, `parseAcceptLanguage`, `negotiate`,
`localeOfPath`, `stripLocale`, `withLocale`, `alternatesFor` and private helpers),
`repository/jhonstart/modules/jhonstart/src/render.bp` (`isLangTag` only),
`repository/botopink-lang/libs/validation/src/messages.bp` (`interpolate` only — commit lands between
two steps of `125-validation-zod`, the file's owner)
**Does not touch:** rakun-app's `persistent_term` registry, redirect filter, `setLocaleCookie`,
dictionary loader and cache, `rakun.i18n.exclude` key (`04-rakun`) · rest of `render.bp`
(`05-jhonstart` 26)

## Goal

rakun-app `wellFormedTag`: `ll(l)` + optional `-RR` / `-999`; jhonstart `isLangTag` accepts a script
subtag — `<html lang>` and rakun's routed locale can name different sets; validation's `{name}`
`interpolate` is a third, ownerless locale-adjacent helper. After: all three read `i18n`.

## Open

### Step 1 — the package

- `LocaleSet`; `wellFormedTag` / `normalizeTag` / `isSupported` under decision 180 (language 2–3
  letters, optional script 4, optional region 2 letters or 3 digits; case normalised; else refused)
- `negotiate(set, acceptLanguage, cookieValue) -> ?string` (pure, over
  `http.accept.parseAcceptLanguage`)
- `localeOfPath` / `stripLocale` / `withLocale`, `alternatesFor`
- `interpolate(template, bindings)` (moved from validation, which imports `i18n` — bundled to bundled
  allowed)
- **No plural rules** (none today, none invented). No name std or a framework exports (decision
  163, checked against `libs/std/src/root.bp` and each framework's root).

- [ ] `libs/i18n/test/tag_test.bp`: `zh-Hant-TW`, `pt-BR`, `en-419` accepted and normalised;
      `x-private`, `en-US-u-ca-gregory` refused; both rows
- [ ] `negotiate` known-answers over RFC 4647 basic filtering examples

### Step 2 — consumers

- [ ] rakun-app keeps only its registry, filter, cookie and loader; generic half deleted
- [ ] jhonstart `isLangTag` deleted; `render.bp` imports `i18n.wellFormedTag`
- [ ] validation's `interpolate` deleted; `messages.bp` imports `i18n.interpolate`; validation's
      tests unchanged

**Gate:** standard (fronts.md § Gate) + `libs/i18n/AGENTS.md` written

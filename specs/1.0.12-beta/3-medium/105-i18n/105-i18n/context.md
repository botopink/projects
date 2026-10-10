# Front 105 — i18n: a shared `i18n`, one locale grammar for the server and the page

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [105-i18n](../README.md): s1 → 105 s1 · s2 → 105 s2. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** medium — jhonstart and rakun disagree on whether `zh-Hant-TW` is a locale ·
**State:** not started
**Depends on:** `104-http` step 5 (both edit `rakun-app/src/i18n.bp`; `parseAcceptLanguage` from
`http.accept`, on feat) · `04-rakun/22`, `05-jhonstart/26` landed (consumer commits) · 03r-q
confirmed. Grammar: decision 180 (`07-c`); surface checked against decision 163.
**Owns:** `repository/i18n/**` (new — `botopink/i18n`, born as a repository: decision 326; nothing in
the compiler registers it) · consumers: `repository/rakun/modules/rakun-app/src/i18n.bp` (generic
half: `wellFormedTag`, `normalizeTag`, `isSupported`, `parseAcceptLanguage`, `negotiate`,
`localeOfPath`, `stripLocale`, `withLocale`, `alternatesFor` and private helpers),
`repository/jhonstart/modules/jhonstart/src/render.bp` (`isLangTag` only),
`repository/validation/src/messages.bp` (`interpolate` only — commit lands between
two steps of `125-validation-zod`, the file's owner)
**Does not touch:** rakun-app's `persistent_term` registry, redirect filter, `setLocaleCookie`,
dictionary loader and cache, `rakun.i18n.exclude` key (`04-rakun`) · rest of `render.bp`
(`05-jhonstart` 26)

## Goal

rakun-app `wellFormedTag`: `ll(l)` + optional `-RR` / `-999`; jhonstart `isLangTag` accepts a script
subtag — `<html lang>` and rakun's routed locale can name different sets; validation's `{name}`
`interpolate` is a third, ownerless locale-adjacent helper. After: all three read `i18n`.

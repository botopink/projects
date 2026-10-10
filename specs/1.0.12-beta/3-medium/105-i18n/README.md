# Front 105 — i18n: a shared `i18n`, one locale grammar for the server and the page

**Priority:** medium (decision 433) — opens after the library tier, or in a free thread when nothing it needs
is open.
**Gate:** standard (fronts.md § Gate); a moved block keeps its own `**Gate:**` additions.
**Owns:** `repository/i18n/**` when born (`botopink/i18n`), the consumer lines step 2 names.
**Depends on:** 155 s2 (104 s5) · rakun 150 s13 (22) · jhonstart 149 s1 · `03r-q` confirmed. Goal and mechanism:
[`03-bundled-libs/105-i18n`](105-i18n/context.md).

## Alias table

Old ids stay valid in `decisions-taken.md`'s *Where* column, `language-gaps.md`'s owners and the
closed records: each resolves here. A "box n" counts the old step's open boxes, in order.

| Old id | Step here |
|---|---|
| `105-i18n` s1 | 105 s1 |
| `105-i18n` s2 | 105 s2 |

## Steps

### 105 s1 — the package

#### Step 1 — the package (was `105-i18n` s1)

- `LocaleSet`; `wellFormedTag` / `normalizeTag` / `isSupported` under decision 180 (language 2–3
  letters, optional script 4, optional region 2 letters or 3 digits; case normalised; else refused)
- `negotiate(set, acceptLanguage, cookieValue) -> ?string` (pure, over
  `http.accept.parseAcceptLanguage`)
- `localeOfPath` / `stripLocale` / `withLocale`, `alternatesFor`
- `interpolate(template, bindings)` (moved from validation, which then declares `i18n` in `dependencies` —
  a package-to-package edge like `actions` → `routing`)
- **No plural rules** (none today, none invented). No name std or a framework exports (decision
  163, checked against `libs/std/src/root.bp` and each framework's root).

- [ ] `repository/i18n/test/tag_test.bp`: `zh-Hant-TW`, `pt-BR`, `en-419` accepted and normalised;
      `x-private`, `en-US-u-ca-gregory` refused; both rows
- [ ] `negotiate` known-answers over RFC 4647 basic filtering examples

### 105 s2 — consumers

#### Step 2 — consumers (was `105-i18n` s2)

- [ ] rakun-app keeps only its registry, filter, cookie and loader; generic half deleted
- [ ] jhonstart `isLangTag` deleted; `render.bp` imports `i18n.wellFormedTag`
- [ ] validation's `interpolate` deleted; `messages.bp` imports `i18n.interpolate`; validation's
      tests unchanged

**Gate:** standard (fronts.md § Gate) + `repository/i18n/AGENTS.md` written

# Front 64 — Rakun i18n Routing

**Track:** B rakun
**Priority:** medium — a multilingual app has to hand-roll locale negotiation in its own middleware and
hand-roll dictionary loading, and `hreflang`/`alternates` metadata never appears. Not fatal to a
single-locale app, which is why it is medium and not high
**Target:** erlang (server)
**Wave:** 7
**Depends on:** 22 (the `[locale]` dynamic segment and the route table), 07 (the filter chain the
negotiation step installs into), 62 (reads `Accept-Language` and the locale cookie), 63 (the redirect
from an unprefixed path), 32 (the `alternates` entries it hands over), 12 (caching a dictionary when
the locale set is open), 01 (`encoding.percentEncode`/`percentDecode`, `path.glob`)
**Owns:** `repository/rakun/modules/rakun-i18n/botopink.json`,
`repository/rakun/modules/rakun-i18n/src/**`, `repository/rakun/modules/rakun-i18n/test/**` — a new
module, so it collides with no existing owner
**Does not touch:** `repository/rakun/src/**` in any form; `modules/rakun-web/**` (fronts 07 · 20 · 65);
`decorators.bp`, `http.bp`, `bootstrap.bp`, `runtime.mjs` — frozen
**Reference:** `NEXTJS-DOCS.md § 22. Internacionalização (i18n)` (Estrutura com route groups ·
Middleware de detecção de locale · Dicionários de tradução), `§ 18. Metadata e OG Images` (alternates) ·
<https://nextjs.org/docs/app/guides/internationalization>

---

## Problem

`§ 22` is a whole doc section and nothing in the milestone implements any of it. Front 22 will parse
`[locale]` as an ordinary dynamic segment, which is correct and insufficient: the segment captures
whatever is in the URL, so `/klingon/about` matches `[locale]/about` and the page renders in a locale
that does not exist. There is no declared locale set, so nothing can reject that. There is no
negotiation, so a visitor landing on `/` gets whatever the root layout hard-codes. There is no
dictionary mechanism, so every app invents one — and every hand-rolled one has the same bug, a missing
key rendering as an empty string in production.

The metadata half is missing too. `alternates`/`hreflang` is what tells a crawler that
`/pt/blog/hello` and `/en/blog/hello` are the same document in two languages; front 32 renders
metadata and has no source for those entries. And `<html lang>` is hard-coded in every root layout
that exists today, which is wrong the moment a second locale exists.

## Current state

- `repository/rakun/modules/` has no `rakun-i18n`; this front's directory is
  `modules/rakun-app/src/i18n/**` ([`modules.md`](../modules.md)).
- `repository/rakun/src/file_router.bp` (front 22) — `SegmentKind.Dynamic` for `[locale]`, the
  `kind|pattern|slot|verb` table of [`contracts.md` § 1](../../contracts.md), and `matchPath`. Nothing
  distinguishes a locale segment from any other dynamic segment.
- `repository/rakun/modules/rakun-web/src/middleware.bp` (front 07) — the filter chain this front
  installs one filter into; this front declares the filter and front 07 owns the chain.
- `libs/std/src/url.bp` and `querystring.bp` exist; neither parses `Accept-Language`, and
  `querystring.stringify` documents itself as not percent-encoding, which is why this front uses
  `encoding.percentEncode`/`percentDecode`.
- `repository/rakun/src/request_context.bp` (front 62) — `headers()` and `cookies()`, which is where
  `Accept-Language` and the locale cookie come from.

## Mechanism

### What Next.js does

An app nests every route under `[locale]` (`§ 22` Estrutura). Middleware checks whether the path
already carries a known locale; if not it reads `Accept-Language`, picks a supported locale or the
default, and redirects to the prefixed path (`§ 22` Middleware). Pages load a dictionary for the
resolved locale and read strings out of it (`§ 22` Dicionários).

### How it maps onto botopink

**The locale set is declared once and is closed.** `LocaleSet(locales, defaultLocale)` is registered at
startup. Anything not in it is not a locale, which is what turns `/klingon/about` from a render in the
wrong language into a 404. `registerLocales` validates that `defaultLocale` is in `locales` and that
every tag is a well-formed BCP 47 language or language-region subtag, and raises on either failure —
a typo in a locale list is discovered at boot, not by a crawler.

**Negotiation is one pure function.** `negotiate(set, acceptLanguage, cookieValue)` takes the two
inputs and answers a locale. The precedence is: an explicit locale cookie that names a supported
locale wins; otherwise the highest-q supported tag from `Accept-Language`; otherwise the default. It
is pure and total, so the q-value parsing — which is where every hand-rolled implementation is wrong —
is a truth table in a test rather than a comment.

`parseAcceptLanguage` answers `LocaleQ(tag, q)` with **q as a per-mille integer**, not a float.
`q=0.8` becomes `800`. The doc's own example sorts by q and botopink's float comparison across two
backends is not something this front wants to depend on; integers sort identically everywhere. A
malformed q is 0, not a raise — a header is attacker-controlled input and must not be able to fail a
request.

**The redirect is a filter, not a scanner.** The negotiation step is one filter in front 07's chain,
installed at the front of it, and it does exactly one thing: if the path is not locale-prefixed,
redirect to the prefixed path with front 63's `redirect`. Prefixing uses
`encoding.percentEncode` on each segment, because a path that survived a round trip through
`Accept-Language` may carry anything.

The filter never runs for a path the app should not translate. `rakun.i18n.exclude` is a list of path
prefixes — `/api`, `/sitemap.xml`, `/robots.txt` — and the default list is not empty: redirecting
`/sitemap.xml` to `/pt/sitemap.xml` breaks front 66 on day one. The default names no other package's
paths: onze appends its own asset prefix to `rakun.i18n.exclude` at boot, as it writes rakun's other
keys (decision 115 rule 4), and rakun spells no onze path (decision 116). Front 65's matcher is the general form
of this, and this front's filter takes a compiled matcher from it rather than growing a second one.

**Dictionaries are records, not JSON.** This is the one place this front deliberately departs from
`§ 22`, and the departure is the point. `§ 22` loads a JSON file and reads `dict.home.title`, which
means a missing key is an empty string at run time. botopink constructs a record by named arguments
and rejects a missing field at compile time (`docs.md:183-186`), so a dictionary is a record type the
app declares and one constructor per locale:

```bp
pub type HomeCopy(
    title: string,
    description: string,
)
```

A new key added to `HomeCopy` fails to compile every locale that has not supplied it. That is the
typed dictionary shape the audit asked for, and it costs the app a `case` over the locale instead of a
file read. The library's part is small on purpose: `localeOf()` answers the resolved locale for the
in-flight request, and the app's `case` does the rest.

For the case where the locale set is genuinely open — user-supplied translations, a CMS — the library
offers `dictionaryBlob(locale)`, a cached string read through front 12 under `CacheScope.Shared` with
namespace `rakun.i18n`. It is deliberately a string and deliberately second: a blob has no compile-time
key checking, and a front that offers the unsafe form first gets the unsafe form used.

**Dictionary discovery at build time** uses `path.glob("**/dictionaries/*.bp", appDir)` (front 01) and
checks that every declared locale has a file and that no file names an undeclared locale. That is the
check that catches a locale added to the set and never translated, and it runs in front 50's CLI, not
in the server.

**Alternates and `<html lang>`.** `alternatesFor(set, pathname)` answers one `Alternate(hreflang, href)`
per locale plus `x-default` for the default locale, which front 32 renders as `<link rel="alternate">`.
`htmlLang()` answers the resolved locale for the root layout, so `lang` stops being a literal.

### The route table is not changed

This front adds no field and no kind letter to [`contracts.md` § 1](../../contracts.md). A `[locale]`
segment is an ordinary `Dynamic` segment in the table and the locale set lives beside it, keyed by
nothing — there is one set per application. That keeps front 22's format untouched and keeps this
front removable.

### Target

erlang. Negotiation, the redirect, the cookie and the dictionary all happen while a request is in
flight. The resolved locale reaches the browser only as an ordinary param in front 23's payload `m`
key, which already exists, so this front declares no boundary artifact and no `@External.Node` cell.

The module's host cells live in `modules/rakun-i18n/src/sidecars/rakun_i18n.erl`; the atom carries the
`rakun_` prefix because `shipErlSidecars` skips a qualifier matching a module this build emitted
(`modules/compiler-cli/src/cli/libs.zig:596`), which is the rule front 04 established.

## Steps

### Step 1 — The locale set

```bp
pub type LocaleSet(
    locales: string[],
    defaultLocale: string,
)

pub fn registerLocales(set: LocaleSet) -> i32
pub fn locales() -> LocaleSet
pub fn isSupported(set: LocaleSet, tag: string) -> bool
pub fn normalizeTag(tag: string) -> string
```

`normalizeTag` lowercases the language subtag and uppercases the region — `pt-br` and `PT-br` both
become `pt-BR` — so a comparison is a string comparison and not a parser.

**Acceptance:**
- [ ] `registerLocales` with a `defaultLocale` not in `locales` raises, naming both.
- [ ] `registerLocales` with an empty `locales` raises.
- [ ] `registerLocales` with `"en_US"` raises, naming the tag — the separator is `-`, and accepting
      both spellings means two representations of one locale.
- [ ] `normalizeTag("pt-br")`, `normalizeTag("PT-BR")` and `normalizeTag("Pt-Br")` all answer `pt-BR`.
- [ ] `isSupported` compares normalized tags, so a request for `PT-br` matches a declared `pt-BR`.
- [ ] Registering twice raises rather than replacing.

### Step 2 — `Accept-Language` parsing and negotiation

```bp
pub type LocaleQ(
    tag: string,
    q: i32,
)

pub fn parseAcceptLanguage(header: string) -> LocaleQ[]
pub fn negotiate(set: LocaleSet, acceptLanguage: string, cookieValue: string) -> string
```

**Acceptance:**
- [ ] `parseAcceptLanguage("pt-BR,pt;q=0.9,en;q=0.8")` answers three entries with q 1000, 900, 800, in
      descending order.
- [ ] A tag with no `q` is 1000.
- [ ] `q=0` sorts last and is never selected, even when it is the only supported tag — RFC 9110 §12.5.4
      says `q=0` means not acceptable, and treating it as a weak preference is the common bug.
- [ ] A malformed q (`q=abc`, `q=`, `q=1.2.3`) answers 0 and does not raise.
- [ ] An empty header answers an empty array.
- [ ] A header with 500 entries parses without raising — it is attacker-controlled length.
- [ ] `negotiate` prefers a supported cookie value over the header.
- [ ] `negotiate` ignores an unsupported cookie value and falls through to the header.
- [ ] `negotiate` with a header naming only unsupported tags answers `defaultLocale`.
- [ ] `negotiate` falls back from `pt-PT` to a declared `pt` when the exact tag is unsupported but the
      language subtag is, and does **not** fall back from `pt` to `pt-BR` — widening is safe,
      narrowing is a guess.

### Step 3 — Path prefixing

```bp
pub fn localeOfPath(set: LocaleSet, pathname: string) -> ?string
pub fn stripLocale(set: LocaleSet, pathname: string) -> string
pub fn withLocale(set: LocaleSet, locale: string, pathname: string) -> string
```

**Acceptance:**
- [ ] `localeOfPath(set, "/pt/about")` answers `pt`; `localeOfPath(set, "/klingon/about")` answers
      `null`; `localeOfPath(set, "/about")` answers `null`.
- [ ] `localeOfPath(set, "/pt")` answers `pt` — the bare prefix is a locale root, not a page named
      after a locale.
- [ ] `stripLocale(set, "/pt/about")` answers `/about`; `stripLocale(set, "/about")` answers `/about`.
- [ ] `withLocale(set, "pt", "/about")` answers `/pt/about`; `withLocale(set, "pt", "/")` answers
      `/pt`.
- [ ] `withLocale` percent-encodes each segment with `encoding.percentEncode` (front 01): a path
      containing a space or a non-ASCII character round-trips through `stripLocale`.
- [ ] `withLocale(set, "pt", "/pt/about")` answers `/pt/about` and does not double-prefix.

### Step 4 — The negotiation filter

```bp
pub fn localeFilter(set: LocaleSet, exclude: Matcher[]) -> Filter
pub fn localeOf() -> string
pub fn setLocaleCookie(locale: string) -> i32
```

`Filter` is front 07's type and `Matcher` is front 65's; this front constructs one of each and owns
neither.

**Acceptance:**
- [ ] A request for `/about` with `Accept-Language: pt` redirects 307 to `/pt/about`.
- [ ] A request for `/pt/about` is not redirected and `localeOf()` answers `pt`.
- [ ] A request for `/api/posts` is not redirected — `/api` is on the default exclude list.
- [ ] `/sitemap.xml` and `/robots.txt` are not redirected: the default exclude list carries them, and
      the test names them, because front 66 breaks silently otherwise.
- [ ] A prefix appended to `rakun.i18n.exclude` at boot (the test appends `/_assets`) is not
      redirected; `grep -rn "_onze\|onze" modules/rakun-i18n/src` is empty.
- [ ] `localeOf()` outside a request raises — front 62's rule, inherited not restated.
- [ ] `setLocaleCookie("pt")` from a server action writes a cookie the next request's `negotiate`
      prefers; called from a render it raises, which is front 62's phase rule.
- [ ] The redirect preserves the query string and the fragment-free remainder of the URL byte for byte.

### Step 5 — Dictionaries

```bp
pub fn dictionaryBlob(locale: string) -> string
pub fn declaredLocaleFiles(appDir: string) -> string[]
```

The typed form needs no library function at all — it is the app's record and the app's `case` — so
this step's deliverable is the open-set fallback plus the build-time check.

**Acceptance:**
- [ ] `dictionaryBlob` reads through front 12 under `CacheScope.Shared`, namespace `rakun.i18n`, and a
      second call in the same second does not re-read.
- [ ] `dictionaryBlob` for an unsupported locale raises, naming the locale and the declared set.
- [ ] `declaredLocaleFiles` uses `path.glob("**/dictionaries/*.bp", appDir)` (front 01) and answers one
      entry per file found.
- [ ] A declared locale with no dictionary file fails the check, naming the locale.
- [ ] A dictionary file naming an undeclared locale fails the check, naming the file.
- [ ] The typed path is demonstrated in the example and needs no library call, which the example's
      comment says in one line.

### Step 6 — Metadata and `<html lang>`

```bp
pub type Alternate(
    hreflang: string,
    href: string,
)

pub fn alternatesFor(set: LocaleSet, pathname: string) -> Alternate[]
pub fn htmlLang() -> string
```

**Acceptance:**
- [ ] `alternatesFor` over a three-locale set answers four entries: one per locale plus `x-default`
      pointing at the default locale's URL.
- [ ] The `href` values are absolute when `rakun.i18n.origin` is set and root-relative when it is not —
      a crawler needs absolute, and inventing an origin is worse than omitting one.
- [ ] `alternatesFor` strips the locale from the incoming pathname before rebuilding, so calling it
      from `/pt/about` and from `/about` answers the same set.
- [ ] `htmlLang()` answers the resolved locale, and raises outside a request.
- [ ] Front 32 consumes `Alternate[]` unchanged — the record is declared here and cited there, not
      re-declared.

## Examples

- [`examples/locale-routing-example.bp`](./examples/locale-routing-example.bp) — the whole `§ 22`
  scenario: the locale set, the filter installed into front 07's chain, and a `[locale]` page that
  reads the resolved locale.
- [`examples/typed-dictionary-example.bp`](./examples/typed-dictionary-example.bp) — the typed
  dictionary: a record per copy block, one constructor per locale, and the `case` that selects. Adding
  a field to the record breaks every locale that has not supplied it, which is the property this shape
  exists for.

## Language gaps

Every gap this front hits is already in [`language-gaps.md`](../../language-gaps.md) and is cited rather
than re-filed: **declared parameter defaults are never applied** (so `negotiate` takes both inputs
explicitly and `LocaleSet` is written out in full at every registration), **no array destructuring in a
binding** (so `parseAcceptLanguage` splits and indexes with `.at(i)`), and **`xs[0]` silently drops the
index on the BEAM backend** (so every path-segment read is `.at(i)`).

No new gap. Every construct in this front's examples parses today.

## Test plan

`repository/rakun/modules/rakun-i18n/test/locales_test.bp`, `negotiate_test.bp` and `paths_test.bp`,
run by `botopink test --target erlang` from `modules/rakun-i18n/` and by
`zig build test-libs -- --target erlang --lib rakun` in the ecosystem gate.

erlang only. There is no client half: the resolved locale reaches the browser as an ordinary route
param in the payload's existing `m` key ([`contracts.md` § 2](../../contracts.md)), so nothing here needs
a second implementation and the absence of a commonJS row costs no coverage. `parseAcceptLanguage`,
`negotiate` and the three path functions are pure and carry the bulk of the assertions; they would run
on commonJS unchanged, and the test file does not claim that row because the module's manifest declares
`erlang` only.

What the tests assert, by step: locale-set validation and tag normalization; the q-value truth table
including `q=0`, malformed q and the 500-entry header; the three path functions including the
double-prefix and percent-encoding cases; the filter's redirect, its exclusions and its phase rules;
the dictionary cache, its unsupported-locale raise and the build-time file check; and the alternates
set including `x-default` and the origin-absent case.

The build-time dictionary check is a CLI failure, not a runtime assert, so it lives in front 50's suite
with the message text specified above — the same split fronts 22 and 61 use.

## Definition of done

- `modules/rakun-i18n/` exists with a `botopink.json` declaring `"targets": ["erlang"]`, a `src/root.bp`
  listing its `pub mod` lines, and no `@External.Node` cell anywhere in it.
- `src/sidecars/rakun_i18n.erl` compiles under `erlc` with `-Werror` and its atom does not collide with
  a module rakun emits.
- The route-table format of [`contracts.md` § 1](../../contracts.md) is unchanged by this front, and the
  README says so.
- The negotiation precedence, the `q=0` rule and the default exclude list are written down here once
  and cited by fronts 07, 32, 50 and 66 rather than re-derived.
- `repository/rakun/AGENTS.md` and `modules/README.md` name `rakun-i18n`.
- The front's tests are green on its assigned target — here, erlang.


# Front 65 — Rakun URL Rules

**Track:** B rakun
**Priority:** high — `middleware.bp` exists but matches every request, so the auth middleware runs on
`/favicon.ico`; there is no way to rewrite, no way to retire an old URL, no way to set a security
header per path, no `basePath` for an app served from a sub-path, and `proxy.bp` — a top-level file
convention in `§ 3` — has no implementation. These are the rules that decide whether a request reaches
the app at all, so they sit in front of everything
**Target:** erlang, with one boundary file. Rules are **executed** on BEAM by front 07's chain
(`rakun-web`); `basePath`, `trailingSlash` and the redirect table are **mirrored** in the browser so
`<Link>` produces the href the server would have produced, through pure botopink in the bundled
library `routing` (`libs/routing`, erlang and commonJS, decision 115), written by
`01-std/04-routing-lib` to this front's Steps 2–3 and imported here. The two halves are named below
**Wave:** 7
**Depends on:** 07 (the filter chain these rules install into — this front defines them, that front
runs them), 22 (the route table a rewrite target is checked against), `01-std/04-routing-lib` (the
boundary half's code), 62 (the request frame a rule
reads a header from), 63 (the redirect signal), 13 (the HTTP client an external rewrite proxies
through), 01 (`regex.compile`, `regex.captures`, `encoding.percentEncode`/`percentDecode`)
**Owns:** `repository/rakun/modules/rakun-web/src/rules/**`,
`repository/rakun/modules/rakun-web/test/rules/**` — the same sub-directory carve-out front 20 uses
for websockets, so front 07 keeps `modules/rakun-web/src/*.bp` untouched. The boundary half —
`PathRules`, `canonicalize`, `clientHref`, `RedirectRule` and the redirect-blob codec — is
`libs/routing/src/url_rules.bp`, `01-std/04-routing-lib`'s, written to Steps 2–3's specification
**Does not touch:** `modules/rakun-web/src/*.bp` (front 07) and `src/websocket/**` (front 20);
`repository/rakun/src/**` in any form; `decorators.bp`, `http.bp`, `bootstrap.bp`, `runtime.mjs` —
frozen
**Reference:** `NEXTJS-DOCS.md § 20. Middleware e Proxy` (Middleware matcher · Proxy),
`§ 28. Configuração` (`redirects` · `rewrites` · `headers` · `basePath` · `trailingSlash`) ·
<https://nextjs.org/docs/app/api-reference/file-conventions/middleware> ·
<https://nextjs.org/docs/app/api-reference/config/next-config-js/redirects> ·
<https://nextjs.org/docs/app/api-reference/config/next-config-js/rewrites> ·
<https://nextjs.org/docs/app/api-reference/config/next-config-js/basePath>

---

## Problem

Front 07 gives rakun a filter chain. A chain with no matcher runs every filter on every request, which
is how an auth check ends up on `/favicon.ico` and a CORS filter ends up on a server-rendered page.
`§ 20`'s own middleware example is half `config.matcher` for exactly that reason, and the matcher form
it uses — `'/((?!api|_next/static|_next/image|favicon.ico).*)'` — is a negative-lookahead regex, not a
glob, so a hand-rolled prefix check does not substitute for it.

Four more things in `§ 28` have no owner and are not optional for a real deployment. `redirects()` is
how a URL is retired without breaking a link someone bookmarked. `rewrites()` is how `/api/:path*`
reaches another origin without the browser learning about it, and it is also what `proxy.bp` is.
`headers()` is where a per-path `Content-Security-Policy` goes. And `basePath` decides every URL the
app emits — a wrong answer there breaks every link on the site at once, which is why it cannot live in
two implementations that might disagree.

Nothing in the milestone owns any of them. Front 07 owns the chain and says so; front 22 owns the
table and matches within it. The rules that run *before* a route is matched belong here.

## Current state

- `repository/rakun/modules/rakun-web/src/root.bp` — a docblock and a TODO comment. Front 07 will add
  `middleware.bp`, `cors.bp`, `error.bp`, `filter.bp` and `convention.bp`; `src/rules/` is empty and
  this front creates it.
- `repository/rakun/src/runtime.bp:76-104` — `rkRegisterRoute`/`rkDispatch`. Matching is
  segment-by-segment with `:name` parameters and no regex, no lookahead, and no notion of a rule that
  runs before matching.
- `libs/std/src/regex.bp` — `matches`, `replace`, `replaceAll`, `splitOn`, `match`, `matchAll` and a
  `Match(value, index)` record, already wrapping `re:run/3` on erlang. `compile`, `runCompiled`,
  `captures`, `namedCaptures` and `escapeLiteral` are added by front 01, and this front is the reason
  `compile` exists: without it a matcher re-parses its pattern on every request inside the hot path.
- `libs/std/src/querystring.bp` documents itself as not percent-encoding; front 01's
  `encoding.percentEncode`/`percentDecode` are what this front uses for interpolation.
- `repository/rakun/modules/rakun-web/src/rules/` does not exist.

## Mechanism

### What Next.js does

`config.matcher` restricts which paths middleware sees, accepting path globs, `:param`, `:path*` and a
raw regex (`§ 20`). `redirects()` maps a source to a destination with `permanent` choosing 308 over
307. `rewrites()` maps a source to a destination that may be another origin, without the browser
seeing it. `headers()` attaches response headers per path. `basePath` prefixes every route and every
emitted URL; `trailingSlash` normalizes the other end (`§ 28`). `proxy.ts` is a file convention over
the rewrite machinery (`§ 20` Proxy).

### How it maps onto botopink

**Rules are values; front 07 runs them.** This front defines `Matcher`, `RedirectRule`, `RewriteRule`,
`HeaderRule` and the one function that decides what a request becomes. Front 07 owns the chain and
installs a single filter — `urlRulesFilter(compiled)` — at the front of it. That division is the
reason the two fronts do not collide on a file: this front writes `src/rules/**` and front 07 writes
`src/*.bp`, and the only thing crossing is a `Filter` value, which front 07 declares.

The order inside that one filter is fixed and is not configurable:

```
1. canonicalize   basePath strip, trailingSlash normalize, percent-decode
2. redirects      first match wins -> 307/308, done
3. rewrites       first match wins -> the request continues at the new target
4. (the rest of front 07's chain, then the route match, then the handler)
5. headers        applied to the response, after the handler
```

Redirects before rewrites is the order `§ 28` implies and the only one that terminates: a rewrite that
fed back into the redirect table would loop. Headers last, because a header rule must see the final
path and must not be undone by a rewrite.

**A matcher is compiled once.** `matcher(source)` answers `@Result<Matcher, string>` — a bad pattern is
a startup failure with the pattern named, not a per-request exception. Three source forms, decided by
the first character and then by shape:

| Source | Meaning |
|---|---|
| `/dashboard` | exact path |
| `/dashboard/:path*` | `:name` captures one segment, `:name*` captures the rest |
| `/((?!api\|_next).*)` | a raw regex, recognized by the source being wrapped in `(` … `)` |

The `:name` forms are translated into a regex once, at compile time, with `regex.escapeLiteral`
(front 01) over every literal run — a source containing a `.` must match a literal dot, and the bug
where `/a.b` matches `/axb` is the one that ships silently. The compiled handle is `regex.compile`'s,
and matching is `regex.runCompiled`, so nothing re-parses in the hot path.

**Interpolation is explicit and encoded.** `interpolate(destination, m, pathname)` substitutes
`:name` occurrences in the destination from the matcher's captures, percent-encoding each with
`encoding.percentEncode` (front 01). A destination naming a capture the source does not have fails at
**compile** time, when the rule is registered, not when a request happens to hit it.

**An external rewrite streams.** A `RewriteRule` whose destination starts with `http://` or `https://`
is a reverse proxy: the request goes out through front 13's client and the response body is relayed
chunk by chunk rather than buffered, because buffering a proxied download is how a server runs out of
memory. The destination host must be on `rakun.rules.allowedOrigins`; an empty list means external
rewrites are disabled, and that is the default. This is the same shape front 63 uses for redirect
targets, for the same reason, and there is no property that disables the check.

**An internal rewrite is checked against the route table.** A rewrite to `/does/not/exist` is a 404
discovered in production. Front 22's table exists, so the target is matched at registration and a miss
raises with both patterns named.

**`proxy.bp` is a file convention over the same engine.** `registerProxy(fn)` takes one function of the
`§ 20` shape; the CLI (front 50) generates the registration from the file's presence, the way front 22
generates its decorator arguments. There is no second rule engine behind it — `§ 20`'s `proxy.ts`
example rewrites and sets a header, and both verbs are the ones above.

### The boundary, and its two halves

**Server half (erlang).** Matcher compilation, the five-step order, redirect and rewrite execution,
the external proxy, header application, and the registration-time checks.

**Boundary half (erlang and js).** Two pure functions and one table, because `<Link href="/about">` in
an app with `basePath: "/docs"` must emit `/docs/about` and the server must strip it back:

```bp
// routing — the `url_rules` module, both targets
pub type PathRules(basePath: string, trailingSlash: bool)
pub fn canonicalize(rules: PathRules, pathname: string) -> string
pub fn clientHref(rules: PathRules, pathname: string) -> string
```

`canonicalize` strips `basePath` and normalizes the trailing slash; `clientHref` is its inverse and is
what front 27's `Link` calls — jhonstart imports it from the bundled library `routing`, which names
no rakun module (decision 115). They are one botopink implementation in `routing`, compiled twice,
which is the same
arrangement [`contracts.md` § 1](../../contracts.md) fixes for the route table, and for the same reason:
if the two sides disagree about what a URL is, every fix downstream is a guess.

The redirect table crosses with them, as a third blob:

```
source|destination|permanent
```

one record per line, `permanent` being `1` or `0`. `|` and newline are illegal in a source or a
destination, matching the rule [`contracts.md` § 1](../../contracts.md) already applies to segment names.
It rides in the payload (contract 2, written by jhonstart front 30 from the string onze hands it) so
a client navigation to a retired URL is redirected without a round trip. **This front adds no field and no kind letter to the route table**; the blob is separate and
joined by nothing.

### Target and sidecar naming

The server half declares `#[@External.Erlang]` cells only. `canonicalize`, `clientHref` and the blob
codec are pure botopink with no host cell in `routing`, so they compile for both targets
without a second implementation; the matcher translator is server-only and stays in `rakun-web`. The module's host cells live in
`modules/rakun-web/src/rules/sidecars/rakun_url_rules.erl`; the atom carries the `rakun_` prefix
because `shipErlSidecars` skips a qualifier matching a module this build emitted
(`modules/compiler-cli/src/cli/libs.zig:596`) — the rule front 04 established.

## Steps

### Step 1 — Matchers

```bp
pub type Matcher(
    source: string,
    pattern: string,
    params: string[],
    compiled: Regex,
)

pub fn matcher(source: string) -> @Result<Matcher, string>
pub fn matches(m: Matcher, pathname: string) -> bool
pub fn capturesOf(m: Matcher, pathname: string) -> Array<#(string, string)>
pub fn sourceToPattern(source: string) -> @Result<#(string, string[]), string>
```

`sourceToPattern` is the pure translator — source in, regex plus capture names out — and it carries
most of this step's assertions because it needs no compiled handle.

**Acceptance:**
- [ ] `matcher("/dashboard")` matches `/dashboard` and does not match `/dashboard/x` or `/dashboardx`.
- [ ] `matcher("/dashboard/:path*")` matches `/dashboard`, `/dashboard/a` and `/dashboard/a/b`.
- [ ] `matcher("/blog/:slug")` matches `/blog/hello` and does **not** match `/blog/a/b` — one segment
      means one segment.
- [ ] `matcher("/a.b")` matches `/a.b` and does not match `/axb` — literal runs go through
      `regex.escapeLiteral`.
- [ ] `matcher("/((?!api|_next/static|_next/image|favicon.ico).*)")` — `§ 20`'s own example — matches
      `/dashboard` and does not match `/api/posts`, `/_next/static/x` or `/favicon.ico`.
- [ ] `matcher("/(")` answers an `Error` naming the source; it does not raise and does not match
      everything.
- [ ] `capturesOf` answers the named captures in declaration order.
- [ ] `matches` runs `regex.runCompiled` and never `regex.compile` — asserted by a test that compiles
      one matcher and runs it 10 000 times inside a budget a per-request compile would blow.

### Step 2 — `canonicalize` and `clientHref`

```bp
// rakun-web — the whole rule set, server-side
pub type UrlRules(
    basePath: string,
    trailingSlash: bool,
    redirects: Array<RedirectRule>,
    rewrites: Array<RewriteRule>,
    headers: Array<HeaderRule>,
)
pub fn pathRulesOf(rules: UrlRules) -> PathRules

// routing — the boundary half, both targets
pub type PathRules(basePath: string, trailingSlash: bool)
pub fn canonicalize(rules: PathRules, pathname: string) -> string
pub fn clientHref(rules: PathRules, pathname: string) -> string
```

`PathRules` is the two fields the browser needs, so `routing` carries no rewrite, header or
origin rule; the server passes `pathRulesOf(rules)`.

**Acceptance:**
- [ ] With `basePath: "/docs"`, `canonicalize(rules, "/docs/about")` answers `/about` and
      `clientHref(rules, "/about")` answers `/docs/about`.
- [ ] `clientHref(canonicalize(rules, p)) == p` for twenty paths including `/`, `/docs`, `/docs/`,
      a path with a query string, and a percent-encoded path.
- [ ] With `basePath: ""` both functions are identity apart from the trailing-slash rule.
- [ ] `canonicalize(rules, "/other/about")` with `basePath: "/docs"` answers `/other/about` unchanged —
      a path outside the base path is not this app's and is not rewritten into it.
- [ ] `trailingSlash: false` maps `/about/` to `/about` and leaves `/` alone.
- [ ] `trailingSlash: true` maps `/about` to `/about/` and leaves `/` alone.
- [ ] Percent-decoding happens once: `/a%252Fb` decodes to `/a%2Fb` and not to `/a/b`, because
      double-decoding is a path-traversal primitive.
- [ ] Every assertion in this step runs green on `--target erlang` and `--target commonJS` from
      `libs/routing/test/url_rules_test.bp`. This is the boundary half.

### Step 3 — Redirects

```bp
pub type RedirectRule(
    source: string,
    destination: string,
    permanent: bool,
)

pub fn interpolate(destination: string, m: Matcher, pathname: string) -> string
pub fn redirectFor(rules: CompiledRules, pathname: string) -> ?RedirectRule
// routing — RedirectRule and its codec cross to the browser
pub fn writeRedirectTable(rs: Array<RedirectRule>) -> string
pub fn parseRedirectTable(wire: string) -> Array<RedirectRule>
```

**Acceptance:**
- [ ] `{source: "/old", destination: "/new", permanent: true}` answers 308; `permanent: false` answers
      307. The status mapping is asserted against front 63's `permanentRedirect`/`redirect`, not
      duplicated.
- [ ] `{source: "/blog/:slug", destination: "/posts/:slug"}` sends `/blog/hello` to `/posts/hello`.
- [ ] A destination naming `:missing` for a source with no `missing` capture fails at registration,
      naming both.
- [ ] `interpolate` percent-encodes the substituted value: a slug containing a space produces `%20` and
      not a second path segment.
- [ ] The first matching rule wins and later ones are not evaluated.
- [ ] A rule whose source matches its own destination fails at registration — a self-redirect is an
      infinite loop and there is no reason to allow one.
- [ ] `parseRedirectTable(writeRedirectTable(rs))` recovers every rule field by field, on both targets.
- [ ] A source or destination containing `|` fails at registration, naming the rule.

### Step 4 — Rewrites

```bp
pub type RewriteRule(
    source: string,
    destination: string,
)

pub fn rewriteFor(rules: CompiledRules, pathname: string) -> ?string
pub fn isExternal(destination: string) -> bool
```

**Acceptance:**
- [ ] An internal rewrite `{source: "/a/:p*", destination: "/b/:p*"}` makes a request for `/a/x` render
      the route registered at `/b/[...p]`, and the browser's URL is unchanged.
- [ ] An internal rewrite whose target is not in front 22's table fails at registration, naming both
      patterns.
- [ ] `isExternal("https://api.example.com/:path*")` is true; `isExternal("/api/:path*")` is false;
      `isExternal("//api.example.com/x")` is **true** — the protocol-relative form is external, and
      treating it as a path is how an SSRF gets through.
- [ ] An external rewrite to a host not on `rakun.rules.allowedOrigins` fails at registration, naming
      the host. With the property unset the list is empty and every external rewrite fails.
- [ ] An allowed external rewrite relays the upstream status, content type and body.
- [ ] The relayed body is streamed: a 50 MB upstream response does not grow the server's heap by 50 MB,
      asserted by a memory reading around the call.
- [ ] A rewrite never feeds back into the redirect table — asserted with a rule pair that would loop.
- [ ] Hop-by-hop headers (`Connection`, `Transfer-Encoding`, `Upgrade`) are not relayed in either
      direction.

### Step 5 — Header rules and `proxy.bp`

```bp
pub type HeaderRule(
    source: string,
    name: string,
    value: string,
)

pub fn headersFor(rules: CompiledRules, pathname: string) -> Array<#(string, string)>
pub fn registerProxy(handler: fn(req: Request) -> RuleOutcome) -> i32
```

**Acceptance:**
- [ ] A header rule on `/api/:path*` sets its header on `/api/posts` and not on `/about`.
- [ ] Two rules matching one path both apply; two rules setting the same header name apply in
      declaration order and the later value wins.
- [ ] Headers are applied **after** the handler, so a handler that set the same name is overridden by
      the rule — stated here because the opposite choice is equally defensible and only one can be
      true.
- [ ] `registerProxy` accepts one function; a second registration raises.
- [ ] `§ 20`'s `proxy.ts` example ports line for line: a rewrite of `/api/external` to an external
      origin plus a header set on everything else, and the test asserts both halves.

### Step 6 — Compilation and the filter

```bp
pub type CompiledRules(
    basePath: string,
    trailingSlash: bool,
    redirects: Array<#(Matcher, RedirectRule)>,
    rewrites: Array<#(Matcher, RewriteRule)>,
    headers: Array<#(Matcher, HeaderRule)>,
)

pub type RuleOutcome(
    kind: string,
    location: string,
    status: i32,
    target: string,
)

pub fn compileRules(rules: UrlRules) -> @Result<CompiledRules, string>
pub fn applyRules(compiled: CompiledRules, pathname: string) -> RuleOutcome
pub fn urlRulesFilter(compiled: CompiledRules) -> Filter
```

`RuleOutcome.kind` is `""` (continue), `"redirect"`, `"rewrite"` or `"proxy"`.

**Acceptance:**
- [ ] `compileRules` compiles every matcher once and answers an `Error` naming the first bad rule,
      with no partial registration left behind.
- [ ] `applyRules` follows the five-step order of *Mechanism*, asserted with a fixture where a
      different order would give a different answer.
- [ ] `urlRulesFilter` is installed at the front of front 07's chain and short-circuits it on a
      redirect: no later filter runs and no route is matched.
- [ ] A request matching no rule produces `RuleOutcome(kind: "", ...)` and the chain continues
      unchanged.
- [ ] `applyRules` allocates no regex — the assertion is the same 10 000-iteration budget as *Step 1*.

## Examples

- [`examples/url-rules-example.bp`](./examples/url-rules-example.bp) — an app served from `/docs` with
  a retired URL, an internal rewrite, an external API proxy and a CSP header, registered once at
  startup. The developer's whole contact with this front is one `UrlRules` value.
- [`examples/base-path-example.bp`](./examples/base-path-example.bp) — the boundary half, from
  `routing`: `canonicalize`/`clientHref` asserted as inverses in a `test` block that runs on both targets, which
  is what keeps a `<Link>` href and a server match from disagreeing.

## Language gaps

Every gap this front hits is already in [`language-gaps.md`](../../language-gaps.md) and is cited rather
than re-filed: **declared parameter defaults are never applied** (so `UrlRules` is written out in full
at every construction and `matcher` takes its source explicitly), **no array destructuring in a
binding** (so the redirect blob is parsed with `split` and `.at(i)`), and **no byte or binary type**
(so the external rewrite's relayed body marshals through `string`, which means this front's proxy is
correct for text and, like front 25's body readers, cannot carry an arbitrary binary payload today —
the same gap, named in the same row).

No new gap. Every construct in this front's examples parses today.

## Test plan

`repository/rakun/modules/rakun-web/test/rules/matcher_test.bp`, `redirects_test.bp`,
`rewrites_test.bp` and `apply_test.bp`, run by `botopink test --target erlang`
from `modules/rakun-web/` and by `zig build test-libs -- --target erlang --lib rakun`.

`libs/routing/test/url_rules_test.bp` — `canonicalize`/`clientHref` and the redirect-blob
round trip — runs on `--target erlang` and `--target commonJS`: that is the boundary half, it carries
no host cell, and a `basePath` the two sides disagree about breaks every link in the app at once. Everything that touches a socket, the route
registry or the request frame is erlang only.

What the tests assert, by step: the three matcher source forms, the literal-escaping case, `§ 20`'s
lookahead example, the bad-pattern `Error` and the compile-once budget; `canonicalize`/`clientHref` as
inverses over twenty paths on both targets, plus the double-decode refusal; redirect status mapping,
interpolation and its encoding, first-match-wins, the self-redirect refusal and the blob round trip;
rewrite targeting, the three `isExternal` cases, the origin allow-list, streaming and hop-by-hop
stripping; header rule ordering and the `proxy.bp` port; and the five-step order plus the
short-circuit.

The registration-time failures (a bad pattern, an unknown capture, a missing rewrite target, a
disallowed origin) are startup failures rather than runtime asserts wherever they abort boot; the ones
expressible as an `Error` return are asserted here, and the ones that abort are specified above with
their message text for front 50's CLI suite. That split follows front 22's precedent.

## Definition of done

- `modules/rakun-web/src/rules/**` compiles on erlang and imports `canonicalize`, `clientHref` and
  the blob codec from `routing`'s `url_rules`, which carries no host cell and builds for both
  targets.
- `src/rules/sidecars/rakun_url_rules.erl` compiles under `erlc` with `-Werror` and its atom does not
  collide with a module rakun emits.
- Front 07's `src/*.bp` is untouched: the only thing this front hands it is one `Filter` value.
- The route-table format of [`contracts.md` § 1](../../contracts.md) is unchanged by this front, and the
  README says so.
- The five-step order, the redirect blob format and the `allowedOrigins` rule are written down here
  once and cited by fronts 07, 23, 27, 50 and 64 rather than re-derived.
- An external rewrite to an unlisted origin is impossible, and there is no property that turns the
  check off.
- `repository/rakun/AGENTS.md` names `modules/rakun-web/src/rules/`.
- The front's tests are green on its assigned target — here, erlang for the rule engine and both for
  the canonicalization and redirect-blob halves.


# Cross-front contracts — 1.0.12-beta

Formats the fronts must agree on. Each contract: one owner, several consumers, a test asserting a
literal. **The same literal is asserted on both sides** (a one-sided contract drifts). A contract
whose code is in a bundled package (`03-bundled-libs`: `routing`, `actions`, the cookie and q-value
readers) is also asserted from that package's own tests. Front numbers are global (front 22 is
`04-rakun/22-rakun-file-routing/`).

## 1 · Route table — owned by front 22

Line-oriented, not JSON:

```
kind|pattern|slot|verb
```

- `kind`: `L` layout · `T` template · `P` page · `D` default · `R` route handler · `S` loading ·
  `E` error · `N` not-found.
- Pattern keeps bracket spelling (`/blog/[slug]`, `/shop/[...slug]`, `/docs/[[...slug]]`); groups
  and slots never appear. `|` and newline illegal in a segment name. Precedence: static > dynamic >
  catch-all > optional catch-all.
- `parseTable`, `writeTable`, `matchPath`: **one implementation**, compiler-bundled library
  `routing` (`libs/routing`, `["erlang", "commonJS"]`, decision 115); format is 22's. `routing` also
  holds the pure codecs of 60, 61, 65 the browser reads (`k`, `z` blobs, URL rules).
- rakun imports it on erlang; jhonstart's router (26) and `Link` (27) on commonJS, parsing the
  payload's `t` themselves. `routing` names neither library → no jhonstart–rakun edge (decision
  113); onze hands no matcher. No second parser or precedence rule.
- Module atoms per decision 109 (`routing@match`, `routing@table@@RouteEntry`).
- `P` records carry no function: rakun calls an opaque `PageRenderer` registered by onze (decision
  114); `L` / `T` / `P` / `D` records come from jhonstart's UI conventions (front 30), copied into
  rakun's table by onze at boot.

## 2 · Payload envelope — owned by jhonstart front 30

One `<script>window.__bp0 = {…}</script>`, last in `<body>`, before the bundle, written by
jhonstart's render. `__bp0` never hand-spelled: `globals.payload` from jhonstart's globals registry,
read by the writing render and the reading client entry (decision 113). Rakun values (route table
`t`, actions `a`) and build id `b` reach the render as strings from onze; jhonstart names no rakun
module.

| Key | Meaning |
|---|---|
| `v` | 1 |
| `b` | build id |
| `p` | pathname |
| `r` | matched pattern |
| `m` | params, querystring-encoded |
| `q` | search params |
| `t` | the route-table blob |
| `i` | islands, `[id, component, props]` |
| `a` | actions, `[name, id]` |
| `s` | emilia class names already in the server-emitted `<style>` — render-plugin key (§ 6a) from `jhonstart-styled`'s sink (`jhonstart-emilia` until `08-bpp/119` step 5, decision 338) |
| `h` | open streaming holes |
| `d` | dynamic flag — `true` only when the render read the query (`searchParams()`) or the request (`request()`, `cookies()`, `headers()`), a boundary's read included (26-b, answered by decision 186: compile-time mark at `05-jhonstart/26` step 8) |
| `k` | route kinds — front 60 (static / dynamic / revalidate per pattern), joined on `pattern` |
| `z` | slot states — front 61 (which `@slot` rendered for which pattern), joined on `pattern` |

`k`, `z` use `routing`'s codecs (`route_kinds`, `slot_states`); contract 1 untouched. Script written
with std's `json.quote` / `json.array` / `json.object` (every control character escaped) and
escaped with `escape.scriptJson` — `&`, `<`, `>` as `&`, `<`, `>`, U+2028 / U+2029 as ` ` / ` ` — so `</script` is **unrepresentable by construction**;
jhonstart keeps no escaper (decision 116).

**Markers** — prefix = the writing package (decision 113). jhonstart writes every marker in use →
all `data-jh-*`, none `data-onze-*` (an example with `data-onze-*` on a framework marker is stale).
Full registry (no front invents one):

| Marker | Written by | Meaning |
|---|---|---|
| `data-jh-i="i0"` | jhonstart · 29 | an island; ids by 30's render, render order; component and props in `i`, not on the element |
| `data-jh-s` | jhonstart · 29 | server-rendered slot inside an island — the Context-Provider hole; only it |
| `data-jh-h="h1"` / `data-jh-f="h1"` | jhonstart · 30 | streaming hole and its fill; ids = ordinals in shell order, **not** route-derived. Fill = `<template data-jh-f="h1">…</template><script>__bp1("h1")</script>`; a boundary's CSS, if any, a bare `<style>` first inside that `<template>` (§ 6a) |
| `data-jh-root` / `data-jh-t="<pattern>#<nav>"` | jhonstart · 30 | document root element; a `template` segment's per-navigation key |
| `data-jh-e` / `data-jh-reset` | jhonstart · 31 | error boundary and its reset control |
| `data-jh-l` / `-prefetch` / `-replace` / `-scroll` | jhonstart · 27 | client link and its options |
| `data-jh-on-click` | jhonstart · 29 | a handler id |
| `data-jh-a` | jhonstart · 67 | form bound to a server action; id is 24's (§ 3), handed over by onze |
| `data-jh-sf="1"` | jhonstart · 67 | client-enhanced search form (GET, no action) |
| `data-jh-g="redirect"` + `data-jh-to` / `data-jh-g="not-found"` | jhonstart · 30 | navigation signal raised after the first chunk: `<template>` then `<script>__bp2()</script>`. Client navigates to `data-jh-to` as its router does (relative: `history.replaceState` + client navigation; listed absolute: `location.replace`), or swaps the template's not-found markup into `data-jh-root`; status stays 200 (decisions 115, 117, § 5b) |

**Browser globals** — a global only for a value two builds must agree on by name. Four, indexed
aliases from jhonstart's globals registry (front 30), in this order: `globals.payload` (`__bp0`),
`globals.fill` (`__bp1`, called by a fill's `<script>`), `globals.signal` (`__bp2`, called by a late
signal's `<script>`; decisions 115, 117), `globals.starters` (`__bp3`, island starter table filled by
29's `registerStarter` / `registerRouteStarters`, read by `hydrate()`). One job each; the fill never
reads a signal. No hand-written `__jh*` / `__onze*` global; link and form mount are the imports
`linkMount`, `formMount`. A host cell (`declare fn` bound by `#[@External.…]`) is a module function,
not a global; keeps its owner's `__jh` prefix.

Router state (26) maps 1:1 onto `p` / `m` / `q` / `r`; `segments` derived from `r` (split on `/`,
bracket spelling kept), never transported. `selected` (layout depth) has no key; 30's render passes
it into each layout.

Consumed by fronts 26, 27, 28, 29, 31, 60, 61, 68.

## 3 · Action id and envelope — owned by front 24

```
id = "a_" + hash.hmacSha256(buildSecret, module + "." + name + ":" + buildId).slice(0, 24)
```

Server-only, echoed by the client, never derived in the browser (`hash` std's, decision 106).

- **Form binding** (jhonstart 67, id from onze): `<form method="post" action="<pathname>"
  data-jh-a="<id>">` + hidden field named `actionField`. Scripted: same POST with header named
  `actionHeader`, or JSON-RPC body `{"v":1,"id":…,"args":[…]}` written by jhonstart 67 from an event
  handler — same auth path, not a second door. A POST whose header carries `refresh` and no id
  re-renders the current route (26's `refresh()`).
- **Every text is one implementation**: bundled library `actions` (`libs/actions`, `["erlang",
  "commonJS"]`, decision 116): `state` grammar and `ActionState` (`state`), envelope and
  `parseActionState` (`envelope`), JSON-RPC body (`rpc`), `refresh` value (`refresh`). rakun 24
  writes envelope / reads body on erlang; jhonstart 67 reads envelope / writes body on commonJS.
  Literals — the envelope below and the `state` fixture
  `message=Title%20must%20be%20at%20least%203%20characters&f.title=Too%20short` — asserted once, in
  `libs/actions`, both targets; no framework keeps a copy. The library names no field, no header.
- **The two wire names are onze's** (decision 114): onze passes `actionField` / `actionHeader` to
  jhonstart's form binding and sets the same values as rakun's `rakun.actions.field` /
  `rakun.actions.header` (front 05), read by 24's dispatcher. Neither library spells a name; rakun
  with either key unset refuses to start the dispatcher, naming the key. Defaults `__bp_action`,
  `X-Bp-Action`; every track's fixtures assert them.

Response envelope:

```json
{"v":1,"ok":…,"state":"<querystring>","revalidated":[…],"redirect":"…","n":"…","payload":"…"}
```

- `state` grammar: `message` (form-level), `f.<name>` (one field), percent-encoded with std's
  `encoding`. Envelope and JSON-RPC body read with std's `json.decode` (decision 117), both targets;
  no per-target JSON template, no sidecar. `ok: false` is **data handled by front 67**, never caught
  by a front-31 boundary; only a raised POST reaches a boundary.
- **`n`** = navigation signal (§ 5b) in `routing`'s `signalToWire` form: `""` none · `"N"` notFound ·
  `"R|307|/login"` redirect · `"R|308|/new"` permanentRedirect. `location` = rest of the line (a `|`
  in a path round-trips); browser reads with `signalFromWire` (26). **`redirect` derived from `n`,
  never set independently** — `writeEnvelope` takes no `redirect` argument. An action's
  `redirect(loc)` is **rakun's** (front 63, decision 117 rule 4): rakun writes `n`, jhonstart's client
  reads and navigates, neither imports the other. jhonstart's `redirect`: pages, layouts, templates
  only.
- **Front 24 admits no configuration key weakening the CSRF `Origin` / `Host` check**; a test
  asserts there is none. Nothing downstream may add one.

Consumed by fronts 26, 31, 67, 68.

## 4 · Class-name scheme — owned by front 48

```
class = "e_" + hash.contentHash(<the class's rules, as styled renders them>)
```

Decision 367 (338's class, one rule for every component), landed by `06-emilia/34` step 5: the code is
`"e_" + hash.contentHash(classRules(tokensToSheet(tokens, theme)))` (`output.bp` `classRules`: the
class's rules as the document writes them — layer order, plain rules before conditioned ones, runs of
one context folded — the class written `\u{1}`, the text `styled` hashes for a component; no
`prefix` / `important` option enters it). The codec payload is what emilia's cell stores, not what is
hashed. `contentHash` = std's djb2 fold in `hash`: lowercase hex, seed 5381, multiplier 33, masked to
32 bits, over the class's rules (the `e_` prefix is emilia's layer's), `tokens` in author order. emilia and onze
68 use this one function; emilia keeps no private hasher (decision 116). Nothing else enters the
hash — no counter, salt, request id. With a static class: `<static> + " " + <emilia class>`.

Five clauses, each a test:

1. Pure function of the token list **and the theme** — same tokens under another `Theme` = another
   class.
2. **Token order is class identity** → both halves build the list from one shared function; `styled`'s
   reader keeps source order (368), so a selector variant between two plain tokens stays where it was
   written and two lists that differ only there are two classes.
3. ASCII-only rule bodies — JS cell folds UTF-16 units, erlang cell codepoints; diverge above
   U+10000. Front 48 gates payload leaves on this.
4. Merge: static-first, one ASCII space, no sorting, no de-duplication, one implementation
   (`mergeClass`, `emilia/modules/emilia/src/attributes.bp`), nowhere else.
5. Attribute array order fixed (`renderToString` writes attrs in array order).

**Shared fixture:** `className(cardTokens(), defaultTheme()) == "e_f51c2501"` (367; re-derived once in 34
step 5, every reader re-recorded in that landing — it was `e_39b87d03`; the hashed text
`\u{1}{background:#ffffff;padding:calc(var(--spacing) * 4);font-weight:bold}@media (hover: hover){\u{1}:hover{background-color:var(--color-gray-100)}}`
is asserted beside it) (`cardTokens()` =
`[.Bg.White, .Pad.All.__4, .Text.Bold, Token.Hover([.Bg.Color.Gray.__100])]`), a **literal hex string**
on commonJS and erlang (`emilia/modules/emilia/src/emilia.bp`, test "class: attributes — the shared fixture", no HTML); the
`jhonstart-emilia` bridge test (30, `bridge_test.bp:165-186`; the member is deleted by `08-bpp/119`, and the reader moves to `jhonstart-styled`'s test, decision 338) and 68's bundle test assert the same literal; the payload's `s` key makes it checkable at run time.

## 4a · Emilia dispatcher shape — owned by fronts 54 and 56, consumed by 33–48, 57, 58

Every token front returns a **declaration string**, never sees a `Rule`:

```bp
fn <section>TokenToCss(t: Token.<Section>, th: Theme) -> string
```

- Adapted by `declSheet(...)` in its one `tokenToSheet` arm. **Every sub-dispatcher takes
  `th: Theme`.** Tokens needing a selector outside the class (`space-*`, `divide-*`): write
  `fn <section>TokenToSheet(t, th) -> Sheet` instead, and say so. Multi-declaration tokens
  (`truncate`, `line-clamp-*`): a `;`-joined string.
- Theme accessors (54): value accessor **`themeValue(th, name)`** (`theme` is the module name);
  `themeVar(name)` returns `var(--name)`, which utilities emit. **`spacing(n)` returns
  `calc(var(--spacing) * n)`, never a resolved `rem`.** `defaultTheme()` carries only
  `--color-black` / `--color-white`; front 33 owes `paletteEntries() -> ThemeEntry[]`, composed via
  `extend`.
- **Payload-carrying tokens are top-level variants, never section leaves**, builtin-typed fields:
  57's arbitrary values, 33's `Alpha`, 34's `Nth`, colour payloads of 46/47 (`InteractAccent`,
  `InteractCaret`, `InteractScrollbarColor`, `SvgFill`, `SvgStroke`). Colour payloads come from 33's
  `paletteVar(family, shade)` → `var(--color-indigo-500)`, never a hand-written hex.
- Variants (34): whole emission interface = `Variant(atRule, selector)`, one `Variant`-returning
  function per variant name, applied by `nestVariant`; 34 owns no wrapping logic. `hover` =
  `Variant(atRule: "@media (hover: hover)", selector: "&:hover")`. `Rule.selector` is a nesting
  template with **exactly one `&`**; two or more refused, no opt-out.

Binding on every token front:

- **Exhaustive dispatch, no `_` catch-all.** Every `<section>TokenToCss` `case` names every leaf of
  its section, `tokenToSheet` every top-level variant; checkable by the exhaustiveness walk (1.0.5
  decision 58).
- **Naming.** camelCase functions (`gridTokenToCss`), PascalCase sections and variants
  (`Token.Grid.Cols`). Numeric leaves bare digits (`.Pad.All.4`, `.Color.Red.500`) — see
  [`language-gaps.md`](./language-gaps.md)'s negative-leaf row.

## 5 · Request context — owned by front 62

Consumed by fronts 12, 18, 23, 25, 60 and the auth pattern. jhonstart does not read it: front 28's
`request()` / `headers()` / `cookies()` read the `RequestData` onze builds from rakun's `Request`
(decision 114). **Any accessor read outside a request raises** — no `headersOr(default)`, no lenient
property, no predicate.

A keep-alive connection process serves many requests (process ≠ request identity). Scope = explicit
frame with a monotonic epoch under one process-dictionary key, `rakun_request`.

```bp
pub type RequestPhase { Middleware, Render, Action, Handler, After }
pub type RequestScope(id: string, phase: RequestPhase, method: string, path: string,
                      query: string, headersWire: string, strict: bool)

pub fn beginRequest(scope: RequestScope) -> i64   // returns the epoch; nesting raises
pub fn endRequest() -> string                     // Set-Cookie lines; spawns after-work; erases the key
pub fn setPhase(phase: RequestPhase) -> i32
pub fn requestPhase() -> RequestPhase             // the same word front 12's rkCachePhase() reads
pub fn requestId() -> string
pub fn requestEpoch() -> i64

pub type Headers(epoch: i64) { get(name) -> ?string; has(name) -> bool; names() -> string[] }
pub type Cookies(epoch: i64) { get/has/names; set(name, value, attrs) -> i32; delete(name) -> i32 }
pub type DraftMode(epoch: i64) { isEnabled() -> bool; enable() -> i32; disable() -> i32 }

pub fn headers() -> Headers
pub fn cookies() -> Cookies
pub fn draftMode() -> DraftMode                   // HMAC-signed __rakun_draft, constant-time compare
pub fn connection() -> i32
pub fn isDynamic() -> bool
pub fn markDynamic(reason: string) -> i32         // front 23 calls this for searchParams
pub fn after(work: fn() -> i32) -> i32

pub fn memoKey(name: string, parts: Array<string>) -> string
pub fn memoize<T>(key: string, load: fn() -> T) -> T
pub fn preload<T>(key: string, load: fn() -> T) -> i32   // spawns a BEAM process — @Task is eager
```

Every handle carries its minting epoch; mismatch raises (a keep-alive leak is loud). `headersWire`:
`name\tvalue` lines, names lowercased.

**The phase table is enforced**; it is the phase word front 12 reads to decide whether
`revalidatePath` / `revalidateTag` / `updateTag` are legal → **fronts 23 and 24 call `setPhase`**:

| | read headers/cookies | `cookies().set/delete` | `after()` | marks dynamic |
|---|---|---|---|---|
| Middleware | yes | yes | yes | n/a |
| Render | yes | **raises** | yes | yes |
| Action | yes | yes | yes | n/a |
| Handler | yes | yes | yes | yes |
| After (frozen copy) | yes | **raises** | **raises** | n/a |

`strict` set only by front 60's prerenderer: a dynamic read raises instead of marking, failing a
static export's build.

## 5b · Navigation signals — vocabulary `routing`'s, page signals jhonstart's, action and handler signals front 63's

```bp
// routing/navigation — bundled, pure, both targets (decision 116)
pub type NavKind { None, NotFound, Redirect }
pub type NavOutcome(kind: NavKind, location: string, status: i32)
pub fn signalReason(out: NavOutcome) -> string / signalFromReason(reason: string) -> NavOutcome
pub fn isSignalReason(reason: string) -> bool
pub fn signalPrefixes() -> string[]
pub fn signalToWire(out: NavOutcome) -> string / signalFromWire(wire: string) -> NavOutcome

// rakun front 63 — server actions (24) and route handlers (25) only, erlang
pub fn notFound() -> i32                           // never returns
pub fn redirect(location: string) -> i32           // 307
pub fn permanentRedirect(location: string) -> i32  // 308
pub fn captureSignals<T>(body: fn() -> T, fallback: T) -> T
pub fn takeSignal() -> NavOutcome
```

- A signal is a raised **prefixed string** (`nav:`), not a tagged tuple; vocabulary in `routing`
  (names no framework) → rakun and jhonstart raise and read the same reasons without importing each
  other (decision 116).
- **A page signal is jhonstart's from raise to response** (decision 117). Page, layout, template
  import `notFound`, `redirect(url)`, `cookies()` from `"jhonstart"` (31, 28); they raise via
  `signalReason`; the render (30) writes the outcome to § 5d's `Response`: **before the first chunk**
  `redirect` = `status(307)` + `header("location", to)`, `notFound` = `status(404)` with the route's
  not-found boundary as document; **after it** the reason as markup (`data-jh-g`, § 2) its client
  executes, status 200. Client-only app (`clientApp`, 26), same signals in the browser: `notFound`
  renders the not-found boundary, URL unchanged; `redirect` navigates with `history.replaceState`
  (listed absolute target: `location.replace`). onze has no `case` on a signal; rakun knows no page
  signal — a reason raised out of a rakun page renderer is that request's error (500).
- **jhonstart checks a page redirect's target**, identically before/after the first chunk and in the
  browser: relative → must be found by `routing`'s `matchPath` in the handed route table; absolute →
  only when listed in `app(allowedRedirects: [...])` / `clientApp(allowedRedirects: [...])`, empty
  default refuses all. Anything else fails the render (decision 67).
- **Front 63 keeps rakun's own signals** — server actions (24; `redirect` reaches the browser as
  envelope `n`, § 3) and route handlers (25): throw host cell (`rakun_navigation`), per-request
  capture, redirect checks, response status and `Location`. Relative target matched against 22's
  table at raise time, miss raises; absolute checked against `rakun.navigation.allowedHosts`, empty
  default disables absolute redirects. No property turns either check off, either side.
- `try … catch` unwraps an `@Result` only → **no construct can swallow a signal** (asserted).
  Front 31's boundary matches with `isSignalReason`, its test asserts `signalPrefixes()`; no front
  copies the table:

| Raised by | Reason, literally | Status | `n` wire form |
|---|---|---|---|
| `notFound()` — rakun's (63) and jhonstart's (31) | `nav:not-found` | 404 | `N` |
| `redirect(loc)` — rakun's (63) and jhonstart's (31) | `nav:redirect:<loc>` | 307 | `R\|307\|<loc>` |
| `permanentRedirect(loc)` | `nav:permanent-redirect:<loc>` | 308 | `R\|308\|<loc>` |
| `redirectWithStatus(loc, 303)` | `nav:see-other:<loc>` | 303 | `R\|303\|<loc>` |

- `<loc>` = rest after the reason's second `:` (a `:` needs no escaping). A boundary re-raises any
  signal reason unchanged — never renders, logs or puts it in `error.digest`.
- Bare `nav:` is **not** a signal; an unknown `nav:` verb raises, not renders (version skew must be
  loud). Reason crosses a stack frame, `n` wire form crosses to the browser (§ 3, read by 26 with
  `signalFromWire`); `routing`'s test asserts they agree case for case.

## 5c · Small contracts between rakun fronts

- **05 ↔ 14:** 05 calls `validate<TypeName>(bound)` **by name** at boot, refuses to start on
  violations. The name is the contract.
- **07 → 18 · 21 · 62:** `http.bp` frozen, `Response` has no header surface. 07 provides
  `withHeader`; 04 provides `rkSetReplyHeader/2`, which **replaces by name** → `endRequest` returns
  `Set-Cookie` as lines the caller emits one by one.
- **76 → 07:** graceful shutdown is one call. 07's drain begins awaiting 76's `readinessDrained()`
  (returns after `rakun.lifecycle.pre-drain-period`, default 5000 ms): readiness false, in-flight
  requests finish, then 06's pre-destroy pass. 07 does not re-implement the wait; 76 does not drain.
  One test records two timestamps from one run, asserts the order.
- **72 → 06:** the app calls `autoConfigure()` before `Rakun.run`, not inside it (`bootstrap.bp`
  frozen). Conditions on one declaration conjunctive; a disjunction = two configurations.
  `rkAutoApply` sorts topologically before evaluating — the only reason `#[conditionalOnMissingBean]`
  means anything.
- **11 → 08 · 09 · 12 · 15 · 16 · 17 · 18 · 77 · 85:** `#[healthIndicator]`, `#[endpoint]` live in
  the small **`rakun-actuator-api`** module (no dependencies) → indicator fronts do not wait on the
  actuator host. Front 11 owns both modules.

## 5d · Page response — jhonstart's `Response`, adapted by onze over rakun's `ChunkWriter`

```bp
// jhonstart front 30 — what the render writes to
pub type Response(
    status: fn(code: i32) -> void,
    header: fn(name: string, value: string) -> void,
    write:  fn(chunk: string) -> @Task<void>,
    close:  fn() -> @Task<void>,
);

// rakun front 23 — what a page renderer is handed
pub type ChunkWriter(setStatus: fn(code: i32) -> void, setHeader: fn(name: string, value: string) -> void,
                     write: fn(string) -> @Task<void>, close: fn() -> @Task<void>);
pub type PageRenderer = fn(req: Request, out: ChunkWriter) -> @Task<@Result<void, string>>;

// onze front 49 — the whole adapter; no `case` on a signal
rakun.page(pattern, fn(req: Request, out: ChunkWriter) -> @Task<@Result<void, string>> {
    return site.renderStream(input(req), requestData(req), Response(
        status: fn(c) { out.setStatus(c); },
        header: fn(n, v) { out.setHeader(n, v); },
        write:  fn(chunk) { return out.write(chunk); },
        close:  fn() { return out.close(); },
    ));
});
```

- Status and headers legal only before the first `write`; after it `status` / `setStatus`, `header`
  / `setHeader` fail (the render on jhonstart's side, the request on rakun's).
- jhonstart calls `close` exactly once on every path (page, signal before first chunk, late signal);
  rakun closes only when the renderer's Task resolves with it still open; any call after `close`
  fails the request.
- Renderer `Error(msg)` answered like a raise: `500` when nothing written, else response closed;
  message to the log, never the wire (decision 130).
- No signal → `200`, `Content-Type: text/html; charset=utf-8`, set by the render before its first
  `write`. Neither type names the other package.
- Asserted literal (both sides): the socket bytes for a page, a pre-first-chunk `redirect("/login")`
  (`307`, `location: /login`, empty body), a pre-first-chunk `notFound()` (`404`, not-found
  document) — rakun 23 with a stub renderer, jhonstart 30 with a recording `Response`. Owned by
  jhonstart 30; consumed by rakun 23, onze 49 (decision 117).

## 6 · Client bundle — owned by front 68

Consumed by fronts 26, 27, 29, 31, 67, 69, 71 and front 50's `build`.

**Manifest** (`onze-bundler/src/manifest.bp`, both targets — build host writes, BEAM server reads on
every render):

```bp
pub type ChunkRef(id: string, url: string, hash: string, bytes: i32)
pub type ClientBundleManifest(
    version: string,                     // "1"; anything else is a hard error
    buildId: string,                     // front 03's; equals the payload's `b` and front 71's BUILD_ID
    entry: ChunkRef, shared: Array<ChunkRef>, chunks: Array<ChunkRef>,
    routes: Array<#(string, string)>,    // route pattern -> chunk id
    styles: Array<ChunkRef>,             // front 69 hands these in
    publicEnv: Array<#(string, string)>, // ONZE_PUBLIC_ names only
)
```

On disk: `<outDir>/client-manifest.txt`, `|`-delimited, one record per line (contract 1's shape).
Kinds: `V` version · `E` entry · `S` shared · `C` chunk · `H` `beforeInteractive` script (the only
tags in `<head>`) · `R` route → chunk · `Y` style · `P` public env. A field escapes `%`, `|`, LF, CR
as `%25`, `%7C`, `%0A`, `%0D`, read back with std's `encoding.percentDecode`; unknown kind byte
ignored (69, 71 may add records); `V` other than `1` is a hard error.

```
V|1|<buildId>
E|entry|/_onze/static/<buildId>/entry.<hash>.js|<hash>|<bytes>
S|shared|/_onze/static/<buildId>/shared.<hash>.js|<hash>|<bytes>
C|route:/blog/[slug]|/_onze/static/<buildId>/r1.<hash>.js|<hash>|<bytes>
H|script:analytics|/a.js|<hash>|<bytes>
R|/blog/[slug]|route:/blog/[slug]
Y|styles|/_onze/static/<buildId>/app.<hash>.css|<hash>|<bytes>
P|ONZE_PUBLIC_API_URL|https://api.example.com
```

`<hash>` = std's `hash.contentHash` of the linked chunk, eight hex digits.
`parseManifest(formatManifest(m)) == m` asserted on both targets, same literal.

**Emission order** in the document 30's render writes: 1 `beforeInteractive` chunks in `<head>` ·
2 body · 3 payload `<script>window.__bp0 = …</script>` last in `<body>` — **30's, never 68's** ·
4 `shared` `defer` · 5 route chunk `defer` · 6 `entry` `defer`, last. Groups 1 and 4–6 =
`headScriptTags(m)`, `scriptTags(m, route)`, never called by the render: onze installs them as
jhonstart's `RenderHooks.headExtra` / `RenderHooks.bodyExtra`, the render writes what they return
(decisions 77, 113).

**Hydration entry** (`<outDir>/client/entry.bp`, botopink source), in order:
- reads the payload via `readPayload(globals.payload)` (26's router reads `t`, matches with `routing`
  itself → entry builds no matcher); takes `i`;
- registers one starter per eagerly bundled client component (29's `registerStarter(name, start)`)
  and one loader per split route (`registerRouteStarters(pattern, load)`, manifest `R` → chunk);
- calls 29's `hydrate()`; registers the fill function under `globals.fill` for every `h`, the signal
  function under `globals.signal`;
- calls `linkMount()` and `formMount(actionHeader)` once each (`actionHeader` = onze's wire name,
  § 3); sets the browser's validation message source (`setMessageSource`, bundled `validation`,
  decision 116).
No hand-written `__` name in it. 29 owns the per-island hydrate point; 68 the module calling it. A
DOM id with no payload entry, or the reverse: hard run-time error naming the id.

**Three refusals, no opt-out**, each asserted by an adversarial-config test setting every config
field and still refused:
- `server-only` anywhere in the client graph → build fails with the full import chain.
- Only `env.read("ONZE_PUBLIC_…")` with a literal name is inlined; any other name, a non-literal
  name, `env.vars()`, `env.write`, `env.clear` → build fails naming variable, module, chain. 49
  declares the prefix; 68 enforces it.
- `emilia(...)` in a client module with a token list not statically resolvable, or any `flush()`
  reference → build fails naming the call site. Rule bodies come from the function emilia exports
  for build-time evaluation (onze imports emilia directly, decision 116); `contentHash` recomputed
  per rule body on both targets, build fails when JS and erlang disagree (§ 4 clause 3); the entry
  checks every class it computes against the payload's `s` at run time.

## 6a · Style insertion — jhonstart's `RenderPlugin`, implemented by `jhonstart-styled`, owned by front 30

**Render, then flush, then serialize — once per chunk.** A flush clears the sheet (`emilia.flush()` today) → exactly
one consumer per render phase: the render plugin. jhonstart declares the point, is its only caller;
member `repository/jhonstart/modules/jhonstart-styled` implements it — its sink writes the render's
one sheet (`styled`'s: emilia's layers, then scoped styles in render order) in the head and each
boundary fill; onze registers it at boot; emilia imports `styled` and std, no framework (decisions
113, 338). Today the bridge member `jhonstart-emilia` implements it over emilia's `flush()` (its
flush plugin, `root.bp:95`); `08-bpp/119` step 5 deletes the member and moves the implementation
to `jhonstart-styled`'s sink.

```bp
// jhonstart/src/plugin.bp
pub behavior RenderPlugin {
    fn head(self: Self) -> @Task<string>;                    // once, after the shell
    fn chunk(self: Self, holeId: string) -> @Task<string>;   // per boundary, before its markup
    fn close(self: Self) -> @Task<@Result<void, string>>;    // at the end: nothing may be left
    fn payload(self: Self) -> @Task<?#(string, Json)>;       // once, after close
}

// onze, at boot
val site = app(plugins: [styledSink()]);             // {app} from "jhonstart"; the sink from "jhonstart-styled" (named by 119 step 5)
```

| Call | When front 30's render makes it | Its result goes |
|---|---|---|
| `head()` | **once**, after the shell renders to a string, before head serialization | into `<head>`; `""` if nothing registered |
| `chunk(holeId)` | after a streamed boundary renders, **before** its markup hits the wire | first inside that boundary's fill: `<template data-jh-f="<holeId>"><style>…</style>…markup…</template>` — no own marker; `""` writes no `<style>` |
| `close()` | after the last chunk | error fails the render; a non-empty pending sheet is that error |
| `payload()` | **once**, after `close` | into the payload (§ 2) under the plugin's key; `null` writes nothing. A key the render writes itself (every § 2 key but `s`), or given by two plugins, fails the render. `Json` = JSON text from std's `json` writers (decision 116), written verbatim |

- Ordering rules (`head` once, CSS before the markup it styles, nothing left at `close`) are
  jhonstart's (the caller); adaptation to the sheet is the sink's. "Never an unstyled paint" holds
  by construction: a fill's style and markup reach the document together.
- The plugin never recomputes, re-hashes, sorts or dedups a class (§ 4 untouched); the client bundle
  never calls `flush()` (68 enforces).
- Every method asynchronous (decision 114): the render awaits each call; the sink awaits the
  sheet's `@Task`-returning flush in `head` and `chunk`.
- The sink's `payload()` returns `#("s", <the class names it flushed>)` — the payload's `s` — checked
  by 68's entry with `checkStyles(payload.s)`. jhonstart names no plugin key.

## 7 · Test and snapshot contract — owned by `snap` (391; `SourceLocation` std's), consumed by every `-test` submodule

Specified by [`src-builtin.md`](../1.0.10-beta/01-std/src-builtin.md),
[`snapshots.md`](../1.0.10-beta/01-std/snapshots.md),
[`asserts-api.md`](../1.0.10-beta/01-std/asserts-api.md), and the shape every library's
`modules/<lib>-test/` exposes ([`02-packaging/README.md`](../1.0.10-beta/02-packaging/README.md)).

```bp
type SourceLocation(file: string, line: i32, column: i32, fnName: string)   // @src(), comptime

test "css: modifiers ---- hover on md breakpoint" {
    try assertCss(@src(), [.Md([.Hover([.Bg.Color.Red.500])])]);
}
```

- `snap`'s `path(loc)` (`import {path} from "snap"`, 391) = `<dir of loc.file>/__snapshots__/<suite>/<slug>.snap`; `suite` = text
  before the first `": "` of the test name, `slug` = slugified rest. Same literal path asserted by
  `snap`'s inline tests and one test per `-test` submodule.
- Mismatch or missing file → writes `<path>.new`, fails the test. Only a person renaming `.new`
  accepts a snapshot; **there is no update flag**, no `-test` submodule adds one.
- Every library, module, submodule, example owns the `__snapshots__/` beside its tests and exposes,
  from `<lib>-test`, the `assert<Subject>(loc, …) -> @Result<void, string>` helpers writing them. A
  `-test` helper never re-implements `snap`'s `path` or an `asserts.*` predicate.
- `@src()` is a compiler builtin — the one contract with a compiler half: the `SourceLocation`
  record is asserted by std on every target the tests run on.

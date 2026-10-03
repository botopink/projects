# Cross-front contracts — 1.0.12-beta

The formats the fronts must agree on. Each contract is owned by one front, consumed by several, and
checked by a test that asserts a literal. **The same literal is asserted on both sides** — a
contract only one side tests drifts. A contract whose code lives in a bundled package
(`03-bundled-libs`: `routing`, `actions`, the cookie and q-value readers) is asserted from that
package's own tests as well as from both consumers'. Front numbers are global (front 22 is
`04-rakun/22-rakun-file-routing/`).

## 1 · Route table — owned by front 22

Line-oriented, not JSON:

```
kind|pattern|slot|verb
```

`kind`: `L` layout · `T` template · `P` page · `D` default · `R` route handler · `S` loading ·
`E` error · `N` not-found. The pattern keeps the bracket spelling (`/blog/[slug]`,
`/shop/[...slug]`, `/docs/[[...slug]]`); groups and slots never appear in it. `|` and newline are
illegal inside a segment name. Precedence: static > dynamic > catch-all > optional catch-all.

`parseTable`, `writeTable` and `matchPath` are **one implementation**, in the compiler-bundled
library `routing` (`libs/routing`, `["erlang", "commonJS"]`, decision 115); the format is front
22's. `routing` also holds the pure codecs of fronts 60, 61 and 65 the browser reads (the `k` and
`z` blobs, the URL rules). rakun imports it on erlang; jhonstart's router (26) and `Link` (27) import
it on commonJS and parse the payload's `t` themselves. `routing` names neither library, so neither
import is an edge between jhonstart and rakun (decision 113); onze hands no matcher. Nobody writes a
second parser or precedence rule. Module atoms follow decision 109 (`routing@match`,
`routing@table@@RouteEntry`). `P` records carry no function: the renderer rakun calls for a page is
an opaque `PageRenderer` registered by onze (decision 114); `L` / `T` / `P` / `D` records come from
jhonstart's UI conventions (front 30), copied into rakun's table by onze at boot.

## 2 · Payload envelope — owned by jhonstart front 30

One `<script>window.__bp0 = {…}</script>`, last in `<body>`, before the bundle, written by
jhonstart's render. `__bp0` is never spelled by hand: it is `globals.payload` from jhonstart's
globals registry, read by the render that writes it and the client entry that reads it (decision
113). The rakun values — the route table `t`, the actions `a` — and the build id `b` reach the render
as strings handed in by onze; jhonstart names no rakun module.

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
| `s` | emilia class names already in the server-emitted `<style>` — a render-plugin key (§ 6a), given by `jhonstart-emilia` |
| `h` | open streaming holes |
| `d` | dynamic flag — `true` only when the render read the query (`searchParams()`) or the request (`request()`, `cookies()`, `headers()`), a boundary's read included (26-b) |
| `k` | route kinds — front 60 (static / dynamic / revalidate per pattern), joined on `pattern` |
| `z` | slot states — front 61 (which `@slot` rendered for which pattern), joined on `pattern` |

`k` and `z` are written and read with `routing`'s codecs (`route_kinds`, `slot_states`), so contract
1 stays untouched. The script is written with std's `json.quote` / `json.array` / `json.object`
(every control character escaped) and escaped with `escape.scriptJson` — `&`, `<`, `>` as `&`,
`<`, `>`, U+2028 / U+2029 as ` ` / ` ` — so `</script` is **unrepresentable by
construction**; jhonstart keeps no escaper of its own (decision 116).

**Markers** — the prefix is the package that writes the marker (decision 113). jhonstart writes
every marker in use, so every one is `data-jh-*`; none is `data-onze-*`, and an example carrying
`data-onze-*` on a framework marker is stale. The full registry, so no front invents one:

| Marker | Written by | Meaning |
|---|---|---|
| `data-jh-i="i0"` | jhonstart · 29 | an island; ids assigned by front 30's render in render order; component and props are in `i`, not on the element |
| `data-jh-s` | jhonstart · 29 | a server-rendered slot inside an island — the Context-Provider hole; nothing else carries it |
| `data-jh-h="h1"` / `data-jh-f="h1"` | jhonstart · 30 | a streaming hole and its fill; ids are ordinals in shell order, **not** route-derived. A fill is `<template data-jh-f="h1">…</template><script>__bp1("h1")</script>`; a boundary's CSS, if any, is a bare `<style>` first inside that `<template>` (§ 6a) |
| `data-jh-root` / `data-jh-t="<pattern>#<nav>"` | jhonstart · 30 | the document's root element; a `template` segment's per-navigation key |
| `data-jh-e` / `data-jh-reset` | jhonstart · 31 | an error boundary and its reset control |
| `data-jh-l` / `-prefetch` / `-replace` / `-scroll` | jhonstart · 27 | a client link and its options |
| `data-jh-on-click` | jhonstart · 29 | a handler id |
| `data-jh-a` | jhonstart · 67 | a form bound to a server action; the id is front 24's (§ 3), handed over by onze |
| `data-jh-sf="1"` | jhonstart · 67 | a client-enhanced search form (GET, no action) |
| `data-jh-g="redirect"` + `data-jh-to` / `data-jh-g="not-found"` | jhonstart · 30 | a navigation signal raised after the first chunk: a `<template>` then `<script>__bp2()</script>`. The client navigates to `data-jh-to` as its router does (a relative target by `history.replaceState` and a client navigation, a listed absolute one by `location.replace`), or swaps the template's not-found markup into `data-jh-root`; the status stays 200 (decisions 115, 117, § 5b) |

**Browser globals** — only a value two builds must agree on by name is a global, and there are four,
indexed aliases from jhonstart's globals registry (front 30) declared and numbered in this order:
`globals.payload` (`__bp0`), `globals.fill` (`__bp1`, called by a fill's `<script>`),
`globals.signal` (`__bp2`, called by a late signal's `<script>`; decisions 115, 117) and
`globals.starters` (`__bp3`, the island starter table front 29's `registerStarter` /
`registerRouteStarters` fill and `hydrate()` reads). Each does one thing; the fill never reads a
signal. No hand-written `__jh*` or `__onze*` global exists; link and form mount are the imports
`linkMount` and `formMount`. A host cell (`declare fn` bound by `#[@External.…]`) is a module
function, not a global, and keeps its owner's `__jh` prefix.

Router state (26) maps one-to-one onto `p` / `m` / `q` / `r`; `segments` is derived from `r` by
splitting on `/` with the bracket spelling kept, never transported. `selected` (the layout depth)
has no payload key; front 30's render passes it into each layout.

Consumed by fronts 26, 27, 28, 29, 31, 60, 61, 68.

## 3 · Action id and envelope — owned by front 24

```
id = "a_" + hash.hmacSha256(buildSecret, module + "." + name + ":" + buildId).slice(0, 24)
```

Computed only on the server, echoed by the client, never derived in the browser (`hash` is std's,
decision 106).

Form binding (jhonstart 67, with the id onze hands it): `<form method="post" action="<pathname>"
data-jh-a="<id>">` plus a hidden field named `actionField`. Scripted invocation: the same POST with
the header named `actionHeader`, or a JSON-RPC body `{"v":1,"id":…,"args":[…]}` written by jhonstart
67 from an event handler — the same auth path, not a second door. A POST whose header carries
`refresh` and no id re-renders the current route (26's `refresh()`).

**Every text of this contract is one implementation**, the bundled library `actions`
(`libs/actions`, `["erlang", "commonJS"]`, decision 116): the `state` grammar and `ActionState`
(`state`), the envelope and `parseActionState` (`envelope`), the JSON-RPC body (`rpc`), the
`refresh` value (`refresh`). rakun 24 writes the envelope and reads the body on erlang; jhonstart 67
reads the envelope and writes the body on commonJS. Its literals — the envelope below and the
`state` fixture `message=Title%20must%20be%20at%20least%203%20characters&f.title=Too%20short` — are
asserted once, in `libs/actions`, on both targets; neither framework keeps a copy. The library names
no field and no header.

**The two wire names are onze's** (decision 114): onze passes `actionField` / `actionHeader` to
jhonstart's form binding and sets the same values as rakun's `rakun.actions.field` /
`rakun.actions.header` (front 05), which 24's dispatcher reads. Neither library spells a name; rakun
with either key unset refuses to start the dispatcher, naming the key. onze's defaults are
`__bp_action` and `X-Bp-Action`, and every track's fixtures assert them.

Response envelope:

```json
{"v":1,"ok":…,"state":"<querystring>","revalidated":[…],"redirect":"…","n":"…","payload":"…"}
```

`state` grammar: `message` (form-level) and `f.<name>` (one field), percent-encoded with std's
`encoding`. Envelope and JSON-RPC body are read with std's `json.decode` (decision 117) on both
targets; `actions` has no per-target JSON template and no sidecar. An `ok: false` envelope is **data
handled by front 67**, never caught by a front-31 boundary; only a raised POST reaches a boundary.

**`n`** is the navigation signal (§ 5b) in `routing`'s `signalToWire` form: `""` none · `"N"`
notFound · `"R|307|/login"` redirect · `"R|308|/new"` permanentRedirect. `location` is the rest of the
line, so a `|` in a path round-trips; the browser reads it with `signalFromWire` (26). **`redirect` is
derived from `n`, never set independently** — `writeEnvelope` takes no `redirect` argument. An
action's `redirect(loc)` is **rakun's** (front 63, decision 117 rule 4): rakun writes `n`, jhonstart's
client reads it and navigates, neither imports the other. jhonstart's `redirect` is for pages,
layouts and templates only.

**Front 24 admits no configuration key that weakens the CSRF `Origin` / `Host` check**, and a test
asserts there is none. Nothing downstream may add one.

Consumed by fronts 26, 31, 67, 68.

## 4 · Class-name scheme — owned by front 48

```
class = "e_" + hash.contentHash(encodeSheet(tokensToSheet(tokens, theme)))
```

`contentHash` is std's djb2 fold in `hash`: lowercase hex, seed 5381, multiplier 33, masked to 32
bits, over the encoded rule body (front 56's rule model), `tokens` in author order. emilia and onze
68 compute the class with this one function; emilia keeps no private hasher (decision 116). Nothing
else enters the hash — no counter, salt or request id. With a static class present the attribute is
`<static> + " " + <emilia class>`.

Five clauses, each a test:

1. A pure function of the token list **and the theme** — the same tokens under another `Theme` are
   another class.
2. **Token order is class identity**, so both halves build the list from one shared function.
3. ASCII-only rule bodies — the JS cell folds UTF-16 units, the erlang cell codepoints, and they
   diverge above U+10000. Front 48 gates payload leaves on this.
4. Merge order is static-first, one ASCII space, no sorting, no de-duplication, one implementation
   (`mergeClass`, `emilia/modules/emilia/src/attributes.bp`) and nowhere else.
5. Attribute array order is fixed, because `renderToString` writes attrs in array order.

**Shared fixture:** `emilia/modules/emilia/test/attributes_test.bp` (renders no HTML) asserts the
class for a fixed token list as a **literal hex string** on commonJS and erlang; the
`jhonstart-emilia` bridge test (30) asserts the same literal for the same list, and front 68's bundle
test asserts the client produces it. The payload's `s` key makes it checkable at run time too.

## 4a · Emilia dispatcher shape — owned by fronts 54 and 56, consumed by 33–48, 57, 58

Every token front returns a **declaration string** and never sees a `Rule`:

```bp
fn <section>TokenToCss(t: Token.<Section>, th: Theme) -> string
```

adapted by `declSheet(...)` in its one `tokenToSheet` arm. **Every sub-dispatcher takes
`th: Theme`.** A front whose tokens need a selector outside the class (`space-*`, `divide-*`) writes
`fn <section>TokenToSheet(t, th) -> Sheet` instead and says so. Multi-declaration tokens
(`truncate`, `line-clamp-*`) are a `;`-joined string.

Theme accessors (54): the value accessor is **`themeValue(th, name)`** (`theme` is the module name);
`themeVar(name)` returns `var(--name)`, which utilities emit. **`spacing(n)` returns
`calc(var(--spacing) * n)`, never a resolved `rem`.** `defaultTheme()` carries only `--color-black` /
`--color-white`; front 33 owes `paletteEntries() -> ThemeEntry[]`, composed by a consumer via
`extend`.

**Payload-carrying tokens are top-level variants, never section leaves**, with builtin-typed fields:
front 57's arbitrary values, 33's `Alpha`, 34's `Nth` and the colour payloads of 46/47
(`InteractAccent`, `InteractCaret`, `InteractScrollbarColor`, `SvgFill`, `SvgStroke`). Colour payloads
come from 33's `paletteVar(family, shade)` → `var(--color-indigo-500)`, never a hand-written hex.

Variants (34): the whole emission interface is `Variant(atRule, selector)`, one `Variant`-returning
function per variant name, applied by `nestVariant`; 34 owns no wrapping logic. `hover` is
`Variant(atRule: "@media (hover: hover)", selector: "&:hover")`. `Rule.selector` is a nesting template
with **exactly one `&`**; two or more is refused, no opt-out.

Binding on every token front:

- **Exhaustive dispatch, no `_` catch-all.** Every `<section>TokenToCss` `case` names every leaf of
  its section, and `tokenToSheet` every top-level variant; the checker's exhaustiveness walk (1.0.5
  decision 58) makes it checkable.
- **Naming.** camelCase functions (`gridTokenToCss`), PascalCase sections and variants
  (`Token.Grid.Cols`). Numeric leaves are bare digits (`.Pad.All.4`, `.Color.Red.500`) — see
  [`language-gaps.md`](./language-gaps.md)'s negative-leaf row.

## 5 · Request context — owned by front 62

Consumed by fronts 12, 18, 23, 25, 60 and the auth pattern. jhonstart does not read it: front 28's
`request()` / `headers()` / `cookies()` read the `RequestData` onze builds from rakun's `Request`
(decision 114). **Reading any accessor outside a request raises** — no `headersOr(default)`, no
lenient property, no predicate to branch on.

A keep-alive connection process serves many requests, so process identity is not request identity.
The scope is an explicit frame with a monotonic epoch under one process-dictionary key,
`rakun_request`.

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

Every handle carries the epoch it was minted with; a mismatch raises (a keep-alive leak is loud).
`headersWire` is `name\tvalue` lines, names lowercased.

**The phase table is enforced**, and it is the phase word front 12 reads to decide whether
`revalidatePath` / `revalidateTag` / `updateTag` are legal, so **fronts 23 and 24 call `setPhase`**:

| | read headers/cookies | `cookies().set/delete` | `after()` | marks dynamic |
|---|---|---|---|---|
| Middleware | yes | yes | yes | n/a |
| Render | yes | **raises** | yes | yes |
| Action | yes | yes | yes | n/a |
| Handler | yes | yes | yes | yes |
| After (frozen copy) | yes | **raises** | **raises** | n/a |

`strict` is set only by front 60's prerenderer: a dynamic read then raises instead of marking, which
fails a static export's build.

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

A signal is a raised **prefixed string** (`nav:`), not a tagged tuple; the vocabulary lives in
`routing`, which names no framework, so rakun and jhonstart raise and read the same reasons without
importing each other (decision 116).

**A page signal is jhonstart's from raise to response** (decision 117). A page, layout or template
imports `notFound`, `redirect(url)` and `cookies()` from `"jhonstart"` (31, 28); they raise through
`signalReason`, and the render (30) writes the outcome to the `Response` of § 5d: **before the first
chunk** a `redirect` is `status(307)` + `header("location", to)` and a `notFound` is `status(404)`
with the route's not-found boundary as the document; **after it** the render writes the reason as
markup (`data-jh-g`, § 2) its client executes, status 200. A client-only app (`clientApp`, 26)
handles the same signals in the browser: `notFound` renders the not-found boundary with the URL
unchanged, `redirect` navigates with `history.replaceState` (a listed absolute target with
`location.replace`). onze has no `case` on a signal; rakun knows no page signal — a reason raised out
of a rakun page renderer is an error of that request (500).

**jhonstart checks a page redirect's target**, identically before and after the first chunk and in
the browser: a relative target must be found by `routing`'s `matchPath` in the route table it was
handed; an absolute target only when listed in `app(allowedRedirects: [...])` /
`clientApp(allowedRedirects: [...])`, whose empty default refuses every absolute target. Anything
else fails the render (decision 67).

**Front 63 keeps the signals of rakun's own code** — server actions (24, whose `redirect` reaches the
browser as the envelope's `n`, § 3) and route handlers (25): the throw host cell
(`rakun_navigation`), the per-request capture, the redirect checks and the response's status and
`Location`. A relative target is matched against front 22's table at raise time and a miss raises;
an absolute target is checked against `rakun.navigation.allowedHosts`, whose empty default disables
absolute redirects. No property turns either check off, on either side.

`try … catch` unwraps an `@Result` and nothing else, so **no construct can swallow a signal** —
asserted by a test. Front 31's boundary matches with `isSignalReason` and its test asserts
`signalPrefixes()`; no front keeps a copy of the table:

| Raised by | Reason, literally | Status | `n` wire form |
|---|---|---|---|
| `notFound()` — rakun's (63) and jhonstart's (31) | `nav:not-found` | 404 | `N` |
| `redirect(loc)` — rakun's (63) and jhonstart's (31) | `nav:redirect:<loc>` | 307 | `R\|307\|<loc>` |
| `permanentRedirect(loc)` | `nav:permanent-redirect:<loc>` | 308 | `R\|308\|<loc>` |
| `redirectWithStatus(loc, 303)` | `nav:see-other:<loc>` | 303 | `R\|303\|<loc>` |

`<loc>` is the rest after the reason's second `:`, so a destination with `:` needs no escaping. A
boundary re-raises any signal reason unchanged — never renders, logs or puts it in `error.digest`.
The bare prefix `nav:` is **not** a signal, and an unknown `nav:` verb raises rather than rendering
(version skew between packages must be loud). The reason crosses a stack frame, the `n` wire form
crosses to the browser (§ 3, read by 26 with `signalFromWire`); `routing`'s test asserts they agree
case for case.

## 5c · Small contracts between rakun fronts

- **05 ↔ 14:** front 05 calls `validate<TypeName>(bound)` **by name** at boot and refuses to start on
  violations. The name is the contract.
- **07 → 18 · 21 · 62:** `http.bp` is frozen and `Response` has no header surface. 07 provides
  `withHeader`; 04 provides `rkSetReplyHeader/2`, which **replaces by name** — so `endRequest`
  returns `Set-Cookie` as a list of lines the caller emits one by one.
- **76 → 07:** graceful shutdown is one call. 07's drain begins by awaiting 76's
  `readinessDrained()`, which returns after `rakun.lifecycle.pre-drain-period` (default 5000 ms):
  readiness flips false, in-flight requests finish, then 06's pre-destroy pass. 07 does not
  re-implement the wait; 76 does not drain. One test records two timestamps from one run and
  asserts the order.
- **72 → 06:** the application calls `autoConfigure()` before `Rakun.run`, not from inside it
  (`bootstrap.bp` is frozen). Conditions on one declaration are conjunctive; a disjunction is two
  configurations. `rkAutoApply` sorts topologically before evaluating — the only reason
  `#[conditionalOnMissingBean]` means anything.
- **11 → 08 · 09 · 12 · 15 · 16 · 17 · 18 · 77 · 85:** `#[healthIndicator]` and `#[endpoint]` live in
  the small **`rakun-actuator-api`** module (no dependencies), so the fronts that ship an indicator do
  not wait on the actuator host. Front 11 owns both modules.

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

Status and headers are legal only before the first `write`; after it, `status` / `setStatus` and
`header` / `setHeader` fail (the render on jhonstart's side, the request on rakun's). jhonstart calls
`close` exactly once on every path (a page, a signal before the first chunk, a late signal); rakun
closes the response only when the renderer's Task resolves with it still open, and any call after
`close` fails the request. A renderer's `Error(msg)` is answered like a raise: `500` when nothing was
written, otherwise the response is closed; the message goes to the log, never on the wire (decision
130). A page with no signal is `200` with `Content-Type: text/html; charset=utf-8`, set by the render
before its first `write`. Neither type names the other package. The literal both sides assert is the
byte sequence on the socket for a page, a pre-first-chunk `redirect("/login")` (`307`,
`location: /login`, empty body) and a pre-first-chunk `notFound()` (`404`, the not-found document) —
rakun 23 with a stub renderer, jhonstart 30 with a recording `Response`. Owned by jhonstart 30;
consumed by rakun 23 and onze 49 (decision 117).

## 6 · Client bundle — owned by front 68

Consumed by fronts 26, 27, 29, 31, 67, 69, 71 and front 50's `build`.

**Manifest** (`onze-bundler/src/manifest.bp`, compiled for both targets — the build host writes it,
the BEAM server reads it on every render):

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

On disk: `<outDir>/client-manifest.txt`, `|`-delimited, one record per line (the shape of contract
1). Kinds: `V` version · `E` entry · `S` shared · `C` chunk · `H` `beforeInteractive` script (the only
tags in `<head>`) · `R` route → chunk · `Y` style · `P` public env. A field escapes `%`, `|`, LF and CR
as `%25`, `%7C`, `%0A`, `%0D`, read back with std's `encoding.percentDecode`; an unknown kind byte is
ignored (69 and 71 may add records); a `V` line other than `1` is a hard error.

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

`<hash>` is std's `hash.contentHash` of the linked chunk, eight hex digits.
`parseManifest(formatManifest(m)) == m` is asserted on both targets with the same literal.

**Emission order** in the document front 30's render writes: 1 `beforeInteractive` chunks in
`<head>` · 2 body · 3 the payload `<script>window.__bp0 = …</script>` last in `<body>` — **30's, never
68's** · 4 `shared` `defer` · 5 route chunk `defer` · 6 `entry` `defer`, last. Groups 1 and 4–6 are
`headScriptTags(m)` and `scriptTags(m, route)`, which the render never calls: onze installs them as
jhonstart's `RenderHooks.headExtra` / `RenderHooks.bodyExtra` and the render writes what they return
(decisions 77, 113).

**Hydration entry** (`<outDir>/client/entry.bp`, botopink source): reads the payload through
`readPayload(globals.payload)` (26's router reads `t` and matches with `routing` itself, so the entry
builds no matcher); takes `i`; registers one starter per eagerly bundled client component with 29's
`registerStarter(name, start)` and one loader per split route with `registerRouteStarters(pattern,
load)` (the manifest's `R` → chunk); calls 29's `hydrate()`; registers the fill function under
`globals.fill` for every `h` and the signal function under `globals.signal`; calls `linkMount()` and
`formMount(actionHeader)` once each (`actionHeader` is onze's wire name, § 3); and sets the browser's
validation message source (`setMessageSource`, bundled `validation`, decision 116). No `__` name is
written by hand in it. Front 29 owns the per-island hydrate point; 68 owns the module that calls it.
An id in the DOM with no payload entry, or the reverse, is a hard run-time error naming the id.

**Three refusals, no opt-out**, each asserted by an adversarial-config test that sets every config
field and still gets the refusal:
- `server-only` anywhere in the client graph → the build fails with the full import chain.
- Only `env.read("ONZE_PUBLIC_…")` with a literal name is inlined; any other name, a non-literal
  name, `env.vars()`, `env.write`, `env.clear` → the build fails naming variable, module and chain.
  Front 49 declares the prefix; 68 enforces it.
- `emilia(...)` in a client module with a token list not statically resolvable, or any `flush()`
  reference → the build fails naming the call site. Rule bodies come from the function emilia
  exports for build-time evaluation (onze imports emilia directly, decision 116); `contentHash` is
  recomputed per rule body on both targets and the build fails when JS and erlang disagree (§ 4
  clause 3); the entry checks every class it computes against the payload's `s` at run time.

## 6a · Style insertion — jhonstart's `RenderPlugin`, implemented by `jhonstart-emilia`, owned by front 30

**Render, then flush, then serialize — once per chunk.** `emilia.flush()` clears the sheet, so there
is exactly one consumer per render phase: the render plugin. jhonstart declares the point and is its
only caller; the bridge member `repository/jhonstart/modules/jhonstart-emilia` implements it over
emilia's `flush()`; onze registers it at boot; emilia imports nobody (decision 113).

```bp
// jhonstart/src/plugin.bp
pub behavior RenderPlugin {
    fn head(self: Self) -> @Task<string>;                    // once, after the shell
    fn chunk(self: Self, holeId: string) -> @Task<string>;   // per boundary, before its markup
    fn close(self: Self) -> @Task<@Result<void, string>>;    // at the end: nothing may be left
    fn payload(self: Self) -> @Task<?#(string, Json)>;       // once, after close
}

// onze, at boot
val site = app(plugins: [emiliaPlugin()]);           // {app} from "jhonstart", {plugin as emiliaPlugin} from "jhonstart-emilia"
```

| Call | When front 30's render makes it | Its result goes |
|---|---|---|
| `head()` | **once**, after the shell rendered to a string, before the head is serialized | into `<head>`; `""` when nothing registered |
| `chunk(holeId)` | after a streamed boundary renders, **before** its markup goes to the wire | first inside that boundary's fill: `<template data-jh-f="<holeId>"><style>…</style>…markup…</template>` — no marker of its own; `""` writes no `<style>` |
| `close()` | after the last chunk | an error fails the render; a non-empty pending sheet is that error |
| `payload()` | **once**, after `close` | written into the payload (§ 2) under the key the plugin gives; `null` writes nothing. A key the render writes itself (every § 2 key but `s`), or given by two plugins, fails the render. `Json` is JSON text serialised with std's `json` writers (decision 116), written verbatim |

The ordering rules — `head` once, CSS before the markup it styles, nothing left at `close` — are
jhonstart's (the caller); the adaptation to `flush()` is the bridge's. "Never an unstyled paint"
holds by construction: a fill's style and markup reach the document together. The plugin never
recomputes, re-hashes, sorts or dedups a class (§ 4 untouched); the client bundle never calls
`flush()` (68 enforces it). Every method is asynchronous (decision 114): the render awaits each
call, and the bridge awaits emilia's `@Task`-returning `flush()` in `head` and `chunk`. The bridge's
`payload()` returns `#("s", <the class names it flushed>)` — the payload's `s` — checked by 68's entry
with `checkStyles(payload.s)`. jhonstart names no plugin key.

## 7 · Test and snapshot contract — owned by std, consumed by every `-test` submodule

Specified by [`src-builtin.md`](../1.0.10-beta/01-std/src-builtin.md),
[`snapshots.md`](../1.0.10-beta/01-std/snapshots.md) and
[`asserts-api.md`](../1.0.10-beta/01-std/asserts-api.md), and the shape every library's
`modules/<lib>-test/` exposes ([`02-packaging/README.md`](../1.0.10-beta/02-packaging/README.md)).

```bp
type SourceLocation(file: string, line: i32, column: i32, fnName: string)   // @src(), comptime

test "css: modifiers ---- hover on md breakpoint" {
    try assertCss(@src(), [.Md([.Hover([.Bg.Color.Red.500])])]);
}
```

- `snapshots.path(loc)` = `<dir of loc.file>/__snapshots__/<suite>/<slug>.snap`, `suite` the text
  before the first `": "` of the test name, `slug` the slugified rest. The same literal path is
  asserted by std's inline tests and by one test in each `-test` submodule.
- A mismatch or a missing file writes `<path>.new` and fails the test. Only a person renaming the
  `.new` file accepts a snapshot; **there is no update flag**, and no `-test` submodule adds one.
- Every library, module, submodule and example owns the `__snapshots__/` beside its own tests and
  exposes, from `<lib>-test`, the `assert<Subject>(loc, …) -> @Result<void, string>` helpers that
  write them. A `-test` helper never re-implements `snapshots.path` or an `asserts.*` predicate.
- `@src()` is a compiler builtin — the one contract with a compiler half: the `SourceLocation`
  record is asserted by std on every target the tests run on.

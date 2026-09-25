# Cross-front contracts — 1.0.10-beta

The fronts live under `01-std/`, `03-rakun/`, `04-jhonstart/`, `05-emilia/`, `06-onze/` (map in
[`unification.md`](./unification.md)).

Ninety-six fronts stay coherent only where they agree on a format. This file is the list of those
agreements. Each one is owned by a single front, consumed by several, and checkable by a test that
asserts a literal — not by a paragraph asking everyone to be careful.

The rule for every contract here: **the same literal is asserted on both sides.** A contract that
only one side tests is a contract that drifts.

## 1 · Route table — owned by front 22

Line-oriented, not JSON, and deliberately so: `std/json` has no structured value and the parser has
to run on BEAM.

```
kind|pattern|slot|verb
```

`kind` is one of `L` layout · `T` template · `P` page · `D` default · `R` route handler ·
`S` loading · `E` error · `N` not-found. The pattern keeps the bracket spelling — `/blog/[slug]`,
`/shop/[...slug]`, `/docs/[[...slug]]` — and groups and slots never appear in it. `|` and newline
are illegal inside a segment name. Match precedence is static > dynamic > catch-all > optional
catch-all.

`parseTable`, `writeTable` and `matchPath` are **one botopink implementation compiled twice**. The
server matches with it; front 26's client router prefetches with it. Neither writes a second parser.

## 2 · Payload envelope — owned by front 23

One `<script id="__onze" type="application/json">`, placed last in `<body>`, before the bundle.

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
| `s` | emilia class names already present in the server-emitted `<style>` |
| `h` | open streaming holes |
| `d` | dynamic flag |

Escaping inside that script: `<`, `>` and `&` become `<`, `>`, `&`, plus U+2028 and
U+2029. `</script` is therefore **unrepresentable by construction** rather than filtered.

Two more keys, allocated by front 23 for fronts that publish a separate blob joined on `pattern` so
that contract 1 stays untouched: `k` — route kinds (front 60: static/dynamic/revalidate per pattern);
`z` — slot states (front 61: which `@slot` rendered for which pattern).

Markers — all `data-onze-*`, and the full registry is here so no front invents a prefix:

| Marker | Owner | Meaning |
|---|---|---|
| `data-onze-i="i0"` | 29 | an island; ids assigned by front 23 in render order; component name and props are in `i`, not on the element |
| `data-onze-s` | 29 | a server-rendered slot inside an island — the Context-Provider hole |
| `data-onze-h="h1"` / `data-onze-f="h1"` | 30 | a streaming hole and its fill; ids are ordinals in shell order, assigned by front 23, **not** route-derived. A fill is `<template data-onze-f="h1">…</template><script>__onzeFill("h1")</script>` |
| `data-onze-e` / `data-onze-reset` | 31 | an error boundary and its reset control |
| `data-onze-l` / `-prefetch` / `-replace` / `-scroll` | 27 | a client link and its options |
| `data-onze-on-click` | 29 | a handler id |
| `data-onze-a` | 24 | a form bound to a server action (contract 3) |
| `data-onze-sf="1"` | 67 | a client-enhanced search form (GET, no action) |

`data-jh-*` is not a marker prefix; an example carrying it is stale.

Router state (front 26) maps one-to-one onto `p`/`m`/`q`/`r`; `segments` is derived from `r` by
splitting on `/` with the bracket spelling kept, never transported. The one router value with no
payload key is `selected` — the layout depth — which front 23 passes into each layout render.

Consumed by fronts 26, 27, 28, 29, 30, 31, 60, 61, 68.

## 3 · Action id and envelope — owned by front 24

```
id = "a_" + hash.hmacSha256(buildSecret, module + "." + name + ":" + buildId).slice(0, 24)
```

Computed only on the server, echoed by the client, never derived in the browser. `hash` is std's
hashing module under decision 106 (`crypto` until `00 · 23-std-purity` lands).

Form binding: `<form method="post" action="<pathname>" data-onze-a="<id>">` plus a hidden
`__onze_action` field. Scripted invocation: the same POST carrying `X-Onze-Action`, or a JSON-RPC
body `{"v":1,"id":…,"args":[…]}` — the same auth path, not a second door.

Response envelope:

```json
{"v":1,"ok":…,"state":"<querystring>","revalidated":[…],"redirect":"…","payload":"…"}
```

`state` is querystring-encoded rather than JSON because `std/json` has no walker. An `ok: false`
envelope is **data handled by front 67**, never caught by a front-31 boundary; only a raised POST
reaches a boundary.

The envelope carries one more field, **`n`** — the navigation signal from front 63 (contract 5b)
in `signalToWire` form: `""` no signal · `"N"` notFound · `"R|307|/login"` redirect ·
`"R|308|/new"` permanentRedirect. `location` is the remainder of the line, so a `|` in a path
round-trips. **`redirect` is derived from `n`, never set independently.**

**Front 24 admits no configuration key that weakens the CSRF `Origin`/`Host` check**, and asserts
the absence of one in a test. Nothing downstream may add one.

Consumed by fronts 67, 31, 68.

## 4 · Class-name scheme — owned by front 48

```
class = "e_" + djb2hex(encodeSheet(tokensToSheet(tokens, theme)))
```

Lowercase hex, seed 5381, multiplier 33, masked to 32 bits, folded over the encoded rule body, with
`tokens` in author order. Nothing else enters the hash — no counter, no salt, no request id. With a
static class present, the attribute value is `<static> + " " + <emilia class>`.

The body hashed is `encodeSheet(tokensToSheet(tokens, th))` — front 56's rule model; the expected
literal in the shared fixture is one value, and fronts 23 and 68 assert that value.

Five clauses, each of them a test:

1. A pure function of the token list **and the theme** — a themed value changes the rendered body,
   so the same tokens under a different `Theme` are a different class.
2. **Token order is class identity**, so both halves must build the same list from one shared function.
3. ASCII-only rule bodies — the JS cell folds UTF-16 units and the erlang cell folds codepoints, and
   they diverge above U+10000. Front 48 gates payload leaves on this.
4. Merge order is static-first, one ASCII space, no sorting and no de-duplication, with one
   implementation (`mergeClass` in `emilia/modules/emilia/src/attributes.bp`) and nowhere else.
5. Attribute array order is fixed, because `renderToString` writes attrs in array order.

**The shared fixture:** `emilia/modules/emilia/test/integration_test.bp` asserts the class for a fixed token list as
a **literal hex string**, on both commonJS and erlang. Front 23's SSR test asserts the same literal
for the same list, and front 68's bundle test asserts the client produces it too. If the three ever
differ, hydration is broken and a test is red before a user sees it.

The `s` key in the payload envelope is what makes this checkable at runtime as well as at test time.

## 4a · Emilia dispatcher shape — owned by fronts 54 and 56, consumed by 33–48, 57, 58

Every token front returns a **declaration string** and never sees a `Rule`:

```bp
fn <section>TokenToCss(t: Token.<Section>, th: Theme) -> string
```

adapted by `declSheet(...)` in its one `tokenToSheet` arm. **Every sub-dispatcher takes
`th: Theme`** — a README showing a one-argument dispatcher is stale. A front whose tokens need a
selector outside the class (`space-*`, `divide-*`) writes `fn <section>TokenToSheet(t, th) -> Sheet`
instead and says so. Multi-declaration tokens (`truncate`, `line-clamp-*`) are a `;`-joined string.

Theme accessors (front 54): the value accessor is **`themeValue(th, name)`**, not `theme(...)` —
`theme` is the module name. `themeVar(name)` returns `var(--name)`, which is what utilities emit.
**`spacing(n)` returns `calc(var(--spacing) * n)`, never a resolved `rem`** — a front that writes
`"1rem"` is wrong. `defaultTheme()` carries only `--color-black`/`--color-white`; front 33 owes a
`paletteEntries() -> ThemeEntry[]` that a consumer composes via `extend`.

**Payload-carrying tokens are top-level variants, never section leaves** — verified against the
real compiler (see [`language-gaps.md`](./language-gaps.md)): a leaf inside a section cannot be constructed by any
spelling, so front 57's arbitrary values, front 33's `Alpha`, front 34's `Nth` and the five colour
payloads in 46/47 (`InteractAccent`, `InteractCaret`, `InteractScrollbarColor`, `SvgFill`,
`SvgStroke`) all live at the top of `Token`, with builtin-typed fields. Colour payloads are produced
by front 33's `paletteVar(family, shade)` → `var(--color-indigo-500)`, never a hand-written hex.

Variants (front 34): the entire emission interface is `Variant(atRule, selector)`, one
`Variant`-returning function per variant name, applied by `nestVariant`. Front 34 owns no wrapping
logic. `hover` is `Variant(atRule: "@media (hover: hover)", selector: "&:hover")`, not bare `:hover`.
`Rule.selector` is a nesting template with **exactly one `&`**; two or more is refused, no opt-out.


Two dispatcher rules binding on every token front:

- **Exhaustive dispatch, no `_` catch-all.** Every `<section>TokenToCss` `case` names every leaf of
  its section, and the top-level `tokenToSheet` `case` names every top-level variant. A `_` arm is a
  refusal that compiles, and the checker's exhaustiveness walk (1.0.5-beta decision 58) is what
  makes the rule checkable rather than reviewed.
- **Naming.** camelCase for functions (`gridTokenToCss`), PascalCase for sections and variants
  (`Token.Grid.Cols`). Numeric leaves are bare digits (`.Pad.All.4`, `.Color.Red.500`), which is what
  [`language-gaps.md`](./language-gaps.md)'s negative-leaf row measures against.

## 5 · Request context — owned by front 62

Consumed by fronts 12, 18, 23, 25, 28, 60 and the auth pattern. **Reading any accessor outside a
request raises.** No `headersOr(default)`, no lenient property, no predicate to branch on — a
predicate is an escape hatch with a different spelling.

A request is served by a connection process, and a keep-alive process serves many requests in
sequence, so process identity is not request identity. The scope is an explicit frame with a
monotonic epoch under one process-dictionary key, `rakun_request`.

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
pub fn preload<T>(key: string, load: fn() -> T) -> i32   // spawns a BEAM process — @Future is eager
```

Every handle carries the epoch it was minted with; a mismatch raises, which is what makes a
keep-alive leak loud. `headersWire` is `name\tvalue` lines, names lowercased.

**The phase table is enforced, not documented** — and it is the same phase word front 12 reads to
decide whether `revalidatePath`/`revalidateTag`/`updateTag` are legal, so **fronts 23 and 24 must
call `setPhase`** or every revalidation from an action raises:

| | read headers/cookies | `cookies().set/delete` | `after()` | marks dynamic |
|---|---|---|---|---|
| Middleware | yes | yes | yes | n/a |
| Render | yes | **raises** | yes | yes |
| Action | yes | yes | yes | n/a |
| Handler | yes | yes | yes | yes |
| After (frozen copy) | yes | **raises** | **raises** | n/a |

`strict` is set only by front 60's prerenderer: a dynamic read then raises instead of marking, which
is how static export fails the build.

## 5b · Navigation signals — owned by front 63

```bp
pub type NavKind { None, NotFound, Redirect }
pub type NavOutcome(kind: NavKind, location: string, status: i32)

pub fn notFound() -> i32                           // never returns
pub fn redirect(location: string) -> i32           // 307
pub fn permanentRedirect(location: string) -> i32  // 308
pub fn captureSignals<T>(body: fn() -> T, fallback: T) -> T
pub fn takeSignal() -> NavOutcome
pub fn signalToWire(out: NavOutcome) -> string / signalFromWire(wire: string) -> NavOutcome
```

A signal is a raised **prefixed string**, not a tagged tuple — a tuple could not be matched from
jhonstart without a rakun dependency. botopink's `try … catch` unwraps an `@Result` and nothing
else, so **no construct can swallow a signal** — asserted by a test. Front 63 owns the list; front
31 matches it through `signalPrefixes()` rather than a copy of the table:

| Raised by | Reason, literally | Status |
|---|---|---|
| `notFound()` | `jhonstart:not-found` | 404 |
| `redirect(loc)` | `jhonstart:redirect:<loc>` | 307 |
| `permanentRedirect(loc)` | `jhonstart:permanent-redirect:<loc>` | 308 |
| `redirectWithStatus(loc, 303)` | `jhonstart:see-other:<loc>` | 303 |

`<loc>` is the remainder after the third `:`, so a destination containing `:` needs no escaping.
A boundary re-raises any reason beginning `jhonstart:` unchanged — never renders it, never logs it,
never puts it in `error.digest`. The bare prefix `jhonstart:` is **not** a signal, and an unknown
`jhonstart:` verb raises rather than rendering: that case is rakun/jhonstart version skew, and
silence is how skew stays invisible. The prefix list and the action wire form (`""`/`"N"`/`"R|…"`)
are different artefacts — one crosses a stack frame, the other crosses to the browser.

A relative redirect target is matched against front 22's table at raise time and a miss raises. An
absolute target is checked against `rakun.navigation.allowedHosts`, whose empty default disables
absolute redirects entirely. No property turns either check off.

## 5c · Two small contracts between rakun fronts

- **05 ↔ 14:** front 05 calls `validate<TypeName>(bound)` **by name** at boot and refuses to start
  on violations. The name is the contract.
- **07 → 18 · 21 · 62:** `http.bp` is frozen and `Response` has no header surface. Front 07 provides
  `withHeader`; front 04 provides `rkSetReplyHeader/2`, which **replaces by name** — so `endRequest`
  returns `Set-Cookie` as a list of lines for the caller to emit one by one.
- **76 → 07:** graceful shutdown is one call. Front 07's drain begins by awaiting front 76's
  `readinessDrained()`, which returns after `rakun.lifecycle.pre-drain-period` (default 5000 ms) —
  readiness flips false first, then in-flight requests finish, then front 06's pre-destroy pass.
  07 does not re-implement the wait; 76 does not drain. One test records two timestamps from one
  run and asserts the order.
- **72 → 06:** `autoConfigure()` is called by the application before `Rakun.run`, not from inside
  it (`bootstrap.bp` is frozen). Conditions on one declaration are conjunctive; a disjunction splits
  into two configurations. `rkAutoApply` sorts topologically before it evaluates, which is the only
  reason `#[conditionalOnMissingBean]` means anything.
- **11 → 08 · 09 · 12 · 15 · 16 · 17 · 18 · 77 · 85:** `#[healthIndicator]` and `#[endpoint]` live in
  a small **`rakun-actuator-api`** module (wave 1, no dependencies) so the fronts that ship an
  indicator do not wait on the actuator host (wave 3). Front 11 owns both modules.

## 6 · Client bundle — owned by front 68

Consumed by fronts 26, 27, 29, 31, 67, 69, 71, and by front 50's `build`.

**Manifest** (`onze-bundler/src/manifest.bp`, compiled for both targets — the build host writes
it, the BEAM server reads it on every render):

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

On disk: `<outDir>/client-manifest.txt`, `|`-delimited, one record per line — the same shape as
contract 1 and for the same reason. Kinds `V` version · `E` entry · `S` shared · `C` chunk ·
`R` route → chunk · `Y` style · `P` public env. Values percent-encoded; an unknown kind byte is
ignored so 69 and 71 may add records; a `V` line other than `1` is a hard error.
`parseManifest(formatManifest(m)) == m` is asserted on both targets with the same literal.

**Emission order** in the document front 23 writes: 1 `beforeInteractive` chunks in `<head>` ·
2 body · 3 `<script id="__onze">` last in `<body>` — **front 23's, never 68's** · 4 `shared` `defer` ·
5 route chunk `defer` · 6 `entry` `defer`, last. Groups 1 and 4–6 are `headScriptTags(m)` and
`scriptTags(m, route)`, which front 23 never calls: `Onze.run` installs them as
`RenderHooks.headExtra` / `RenderHooks.bodyExtra` and the pipeline writes what the fields return
(decision 77).

**Hydration entry** (`<outDir>/client/entry.bp`, botopink source): reads `#__onze`, takes `i`,
queries `[data-onze-i]` in document order, calls front 29's hydrate point per island, registers
`__onzeFill(holeId)` for every `h`, then calls `__jhLinkMount()` and `__jhFormMount()` once each.
Front 29 owns the per-island hydrate point; front 68 owns the module that calls it. An id in the
DOM with no payload entry, or the reverse, is a hard runtime error naming the id.

**Three refusals, no opt-out**, each asserted by an adversarial-config test that sets every config
field and still gets the refusal:
- `server-only` anywhere in the client graph → build fails with the full import chain.
- Only `env.read("ONZE_PUBLIC_…")` with a literal name is inlined; any other name, any non-literal
  name, `env.vars()`, `env.write`, `env.clear` → build fails naming variable, module and chain.
  Front 49 declares the prefix; front 68 enforces it.
- `emilia(...)` in a client module with a non-statically-resolvable token list, or any `flush()`
  reference → build fails naming the call site. Both djb2 folds are recomputed per rule body and the
  build fails when JS and erlang disagree (contract 4 clause 3); the entry checks every class it
  computes against the payload's `s` at run time.

## 6a · Style insertion seam — four fields of front 23's `RenderHooks`, filled by front 69

**Render, then flush, then serialize — once per chunk.** `emilia.flush()` clears the sheet, so
there is exactly one correct consumer per render phase, and the sink is it.

Front 23 does not call front 69. The four calls are **fields of the `RenderHooks` record front 23
declares and reads** ([`03-rakun/23-rakun-ssr-pipeline/README.md`](./03-rakun/23-rakun-ssr-pipeline/README.md)
§ *`RenderHooks`*), with working defaults that flush once into the head; front 69 implements them and
`Onze.run` (front 49) installs its values at boot, so `repository/rakun/` names no module of onze
(decision 77). The fields, as 23 declares them:

```bp
openSink: fn() -> void,                  // called before anything renders
collectHead: fn() -> string,             // once, after the shell, before the head is serialised
collectChunk: fn(string) -> string,      // holeId -> the block that precedes that chunk
closeSink: fn() -> string,               // after the last chunk; "" when nothing was dropped
```

No field carries a sink value: the installed wrapper holds the `StyleSink` — and the manifest's
stylesheet `<link>`s it opens with — in the request's own BEAM process, which is where emilia's sheet
already lives. Front 69's module surface, which those wrappers close over:

```bp
pub type StyleChunk(id: string, css: string, classes: Array<string>)
pub type StyleSink(chunks: Array<StyleChunk>, links: Array<#(string,string)>,
                   emitted: Array<string>, headWritten: bool)

pub fn openSink(links: Array<#(string, string)>) -> StyleSink
#[@future] pub fn collectHead(sink: StyleSink) -> @Future<#(StyleSink, string)>
#[@future] pub fn collectChunk(sink: StyleSink, holeId: string) -> @Future<#(StyleSink, string)>
pub fn closeSink(sink: StyleSink) -> #(StyleSink, string)
pub fn emittedClasses(sink: StyleSink) -> Array<string>
```

| Hook | When the pipeline calls it | Returns |
|---|---|---|
| `openSink` | before anything renders | nothing; the wrapper opens a sink carrying the manifest's stylesheet `<link>`s |
| `collectHead` | **once**, after the shell rendered to a string, before the head is serialized | `<link>`s + one `<style>`; nothing when nothing registered |
| `collectChunk(holeId)` | after a streamed boundary renders, **before** its markup goes to the wire | `<style data-onze-s="<holeId>">…</style>` or `""` |
| `closeSink` | after the last chunk | `""`; a non-empty pending sheet is an error |

`emittedClasses(sink)` is what the wrapper hands front 23 for the payload's `s` key — recorded as the
sink fills, never re-scanned out of the CSS. The sink never recomputes, re-hashes, sorts or dedups a
class; contract 4 is untouched. The client bundle never calls `flush()`, which front 68 enforces.

## 7 · Test and snapshot contract — owned by 01-std, consumed by every `-test` submodule

Specified by [`01-std/src-builtin.md`](./01-std/src-builtin.md), [`01-std/snapshots.md`](./01-std/snapshots.md)
and [`01-std/asserts-api.md`](./01-std/asserts-api.md), and the shape every library's
`modules/<lib>-test/` exposes ([`02-packaging/README.md`](./02-packaging/README.md)).

```bp
type SourceLocation(file: string, line: i32, column: i32, fnName: string)   // @src(), comptime

test "css: modifiers ---- hover on md breakpoint" {
    try assertCss(@src(), [.Md([.Hover([.Bg.Color.Red.500])])]);
}
```

- `snapshots.path(loc)` = `<dir of loc.file>/__snapshots__/<suite>/<slug>.snap`, where `suite` is the
  text before the first `": "` of the test name and `slug` is the slugified rest. The same literal
  path is asserted by `01-std`'s inline tests and by one test in each `-test` submodule.
- A mismatch or a missing file writes `<path>.new` and fails the test. Nothing accepts a snapshot
  but a person renaming the `.new` file; **there is no update flag**, and no `-test` submodule adds
  one.
- Every library, module, submodule and example owns the `__snapshots__/` beside its own tests and
  exposes, from `<lib>-test`, the `assert<Subject>(loc, …) -> @Result<void, string>` helpers that
  write them. A `-test` helper never re-implements `snapshots.path` or an `asserts.*` predicate.
- `@src()` is a compiler builtin, so this is the one contract with a compiler half: the
  `SourceLocation` record above is asserted by `01-std` on every target the tests run on.

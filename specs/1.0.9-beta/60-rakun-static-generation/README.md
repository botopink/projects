# Front 60 — Rakun Static Generation

**Track:** B rakun
**Priority:** critical — without it `onze13` can only ever serve dynamically: every page re-renders per
request, a `generateStaticParams` in an app's source is silently ignored, a blog with 10 000 posts hits
the database 10 000 times an hour, and the exit gate's claim that the example app "builds, serves, and
renders its routes" is true only in the SSR sense
**Target:** both — boundary. The two halves are named below and neither is optional
**Wave:** 4
**Depends on:** 22 (the route table), 23 (the renderer), 62 (the definition of dynamic), 12 (the store
the prerendered entries live in), 03 (content hash), 02 (unstarted tasks, for the build fan-out),
01 (`path.walk`, `path.glob`, `fs`, `clock`)
**Owns:** `repository/rakun/src/static_gen.bp`, `repository/rakun/src/segment_config.bp`,
`repository/rakun/src/sidecars/rakun_static_gen.erl`,
`repository/rakun/test/static_gen_test.bp`, `repository/rakun/test/segment_config_test.bp`, and two
`pub mod` lines in `repository/rakun/src/root.bp`
**Does not touch:** `repository/rakun/src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`,
`src/runtime.mjs` — frozen for the milestone; `src/file_router.bp` (front 22), `src/ssr.bp` (front 23)
and `modules/rakun-cache/**` (front 12) are read-only here
**Reference:** `NEXTJS-DOCS.md § 6. Rotas Dinâmicas` (generateStaticParams · Search Params),
`§ 11. Cache` (Modelo anterior — route segment config), `§ 12. Revalidação` (Time-based),
`§ 19. Route Handlers` (Caching), `§ 24. Deploy` (Static Export), `§ 28. Configuração` (`output`) ·
<https://nextjs.org/docs/app/api-reference/functions/generate-static-params> ·
<https://nextjs.org/docs/app/api-reference/file-conventions/route-segment-config> ·
<https://nextjs.org/docs/app/guides/static-exports>
**Replaces:** `new` — 1.0.7-beta covered SSR only

---

## Problem

Front 23 renders a route when a request arrives. That is the whole model, and it has no other mode.
There is no way to say "this route's output does not depend on the request, so compute it once", no
way to enumerate the concrete paths a `[slug]` route can take, no way to say "recompute this at most
hourly", and no way to produce a directory of HTML files at all.

The gap is not a performance nicety. Three separate things in the milestone are already written as if
it exists. Front 27's prefetcher is supposed to behave differently for a static route than for a
dynamic one (`§ 8` Prefetching) and has nothing to read. Front 12's cache store has a `revalidate`
field and no producer for entries at page granularity. Front 66's `sitemap.xml` and `robots.txt` are
constant for most sites and would be regenerated on every crawler hit. And front 62 exists in part to
answer one question — *did this render touch a request-specific value?* — which has no consumer until
this front asks it.

`generateStaticParams` is the sharpest case. A developer who writes it today gets no error and no
effect: nothing scans for it, nothing calls it, and the route stays dynamic. A feature that silently
does nothing is worse than one that is missing.

## Current state

- `repository/rakun/src/file_router.bp` (front 22) — the route table: a line-oriented
  `kind|pattern|slot|verb` blob, `parseTable`, `matchPath`, `layoutChain`. No route kind, no
  revalidation deadline, no per-segment configuration.
- `repository/rakun/src/ssr.bp` (front 23) — renders a matched route to HTML plus the client payload.
  One entry point, one mode.
- `repository/rakun/modules/rakun-cache/src/**` (front 12) — `CachePolicy`, `CacheLife(stale,
  revalidate, expire)`, `cacheThrough`, `revalidateTag`/`revalidatePath`, an ETS-backed store owned by
  rakun's supervisor. Everything this front needs to *store* an entry exists; nothing produces a page-
  sized one.
- `repository/rakun/src/request_context.bp` (front 62) — `isDynamic()`, `dynamicReason()`, and the
  `strict` frame flag that makes a dynamic read raise during a prerender.
- `libs/std/src/path.bp` — the posix calculator; `walk` and `glob` are added by front 01 and this
  front is one of their two consumers (front 66 is the other).
- `repository/rakun/src/static_gen.bp` does not exist. Neither does `segment_config.bp`.

## Mechanism

### What Next.js does

A route is static unless something makes it dynamic. `generateStaticParams` returns the parameter rows
to prerender for a dynamic segment (`§ 6`). Reading `searchParams`, `cookies()`, `headers()` or
`connection()` opts the route into dynamic rendering (`§ 6` nota, `§ 26`). Route segment config —
`export const dynamic`, `dynamicParams`, `revalidate`, `fetchCache` — overrides the inference
(`§ 11` Modelo anterior, `§ 19` Caching). A `revalidate` value re-renders prerendered output on a timer
(`§ 12` Time-based). `output: 'export'` writes the whole thing to a directory of HTML files (`§ 24`).

### How it maps onto botopink

**The decision, in the order it is taken.** One function, four inputs, no ambiguity:

```
1. segment config says ForceDynamic          -> Dynamic
2. segment config says ForceStatic           -> Static, and a dynamic read during prerender raises
3. the pattern has a dynamic segment and
   no generateStaticParams is registered
   and dynamicParams is true                 -> Dynamic
4. the prerender touched a dynamic API
   (front 62's isDynamic())                  -> Dynamic, with dynamicReason() recorded
5. otherwise                                 -> Static
```

Rule 4 is the one that cannot be decided statically, which is why the decision is taken **after** a
trial render rather than before one. The build renders every candidate route once with front 62's
frame in place, and asks the frame afterwards. A route that turns out dynamic is not prerendered and
costs one wasted render at build time; that is cheaper than a wrong answer, and it is the only way to
get rule 4 right without a compiler analysis the milestone forbids.

**Segment config is a value, not a decorator.** `decorators.bp` is frozen and a fifth file-convention
decorator would duplicate front 22's four for no gain. A segment declares its configuration with a
module-level `val`, which is the rakun idiom for registration already
(`repository/rakun/src/decorators.bp:49` emits exactly this shape):

```bp
val _cfg = registerSegmentConfig("blog/[slug]", SegmentConfig(
    dynamic: DynamicMode.Auto,
    dynamicParams: true,
    revalidate: 3600,
    fetchCache: FetchCache.Auto,
));
```

`generateStaticParams` is registered the same way, with the function as the argument, so the build can
call it and the compiler checks its type:

```bp
val _params = registerStaticParams("blog/[slug]", blogStaticParams);
```

**Enumeration.** `registerStaticParams` takes a `#[@future] fn() -> @Future<StaticParams[]>`. Each row
is a list of `ParamBinding(name, value)` rather than a `Dict`, because a row is small, ordered, and
must survive being written into a manifest — and because `Dict` is immutable and iterating it to
rebuild a path is more code than the array form. `expandParams(pattern, rows)` turns the rows into
concrete paths and is pure, so the path-building rule is unit-testable without a build.

A catch-all row carries its segments as one binding whose value contains `/`; `expandParams` splits it
back. A row that does not bind every dynamic segment of the pattern fails the build, naming the
pattern and the missing segment — a partially-bound row would silently prerender a path with a
literal `[slug]` in it.

**The build fan-out spawns; it does not await.** `@Future<T>` lowers eagerly on erlang
(`libs/std/src/http.bp:17-19`), so prerendering N routes by mapping `await render(path)` over them is
exactly N sequential renders. The fan-out uses front 02's unstarted-task form —
`Array<fn() -> @Future<T>>` gathered by index — so a 10 000-post blog prerenders across schedulers
instead of one at a time. Concurrency is bounded by `rakun.static.concurrency` (default: the scheduler
count), because an unbounded fan-out over a connection pool is a self-inflicted outage.

**The prerender manifest** is a record per path, stored through front 12's store under
`CacheScope.Shared` with namespace `rakun.prerender`:

```bp
pub type PrerenderEntry(
    path: string,
    html: string,
    payload: string,
    tags: Array<string>,
    revalidateAt: i64,
    buildHash: string,
)
```

`revalidateAt` is an absolute epoch reading from front 01's `clock.deadline`, so it survives being
handed to another process — the same reason front 12 stores deadlines that way. `buildHash` is front
03's content hash over `html + payload`, and it is what front 66 uses to fingerprint an OG image URL
and what an `ETag` is built from.

**Revalidation is stale-while-revalidate with a single-flight guard.** A request for a path whose
`revalidateAt` has passed is answered from the stale entry **immediately**, and one regeneration is
started. "One" is enforced by registering the regenerating process under a name derived from the path:
the second of fifty concurrent requests finds the name taken and starts nothing. A regeneration that
raises leaves the stale entry in place and logs through front 17 — serving stale is strictly better
than serving an error, and a permanently failing regeneration surfaces as a metric, not as a 500.
`revalidate: -1` means never, and `revalidate: 0` means "always dynamic", which is the same answer as
`DynamicMode.ForceDynamic` and is normalized to it at registration so there is one representation.

The doc revision this front implements does not contain the term ISR. The mechanism above is what
`§ 11`/`§ 12`/`§ 30` call `revalidate`, and this README uses that name.

**Static export.** `staticExport(outDir)` walks every route the table holds, takes the static/dynamic
decision for each with `strict = true` on the frame, and writes `outDir/<path>/index.html` plus the
payload beside it. A route that reaches a dynamic API raises — front 62 does the raising, because the
frame is `strict` — and the export **fails the build**, naming the route and the function. There is no
flag that downgrades that to a warning and no per-route opt-out: an export that silently omits a route
is a site with holes in it, discovered by a crawler.

### The boundary, and its two halves

**Server half (erlang).** Everything above: the decision, the enumeration, the manifest, the
regeneration, the export.

**Boundary half (erlang and js).** One artifact: the route-kind blob, so front 27's prefetcher can do
what `§ 8` describes — prefetch a static route's full payload, and for a dynamic route prefetch only
as far as its `loading` boundary.

```
pattern|K
```

one record per line, `K` being `S` for static or `D` for dynamic. It is a **second** blob, not a fifth
field on front 22's `kind|pattern|slot|verb` record, because front 22 owns that format and this front
owns this one; the two are joined on `pattern`. The server publishes it with `routeKinds()`, front 23
carries it as the `"k"` field of the payload beside front 22's `"t"`, and `routeKindOf(wire, pattern)`
is one botopink function compiled for both targets — the same arrangement front 22 uses for
`parseTable`/`matchPath`, and for the same reason.

**A missing or unparsable blob means `Dynamic`.** Front 27 runs before this front in the wave order, so
it must have a defined answer when the blob is absent, and the defined answer is the conservative one:
no prefetch short-circuit, no assumption that a payload is reusable. That default is stated here so
front 27 cites it rather than inventing one.

### Target and sidecar naming

The server half declares `#[@External.Erlang]` cells only. The boundary half —
`routeKinds`/`routeKindOf`/`parseKinds`/`writeKinds` — is pure botopink with no host cell at all, so it
compiles for both targets without a second implementation.

**The sidecar module atom is `rakun_static_gen`**, not `static_gen`: `shipErlSidecars` skips a
qualifier whose atom matches a module this build emitted
(`modules/compiler-cli/src/cli/libs.zig:596`) and rakun emits `rakun/static_gen` — basename
`static_gen`. Same rule as front 04's `rakun_runtime`.

## Steps

### Step 1 — `segment_config.bp`

```bp
pub type DynamicMode {
    Auto,
    ForceStatic,
    ForceDynamic,
    ErrorOnDynamic,
}

pub type FetchCache {
    Auto,
    DefaultCache,
    ForceCache,
    DefaultNoStore,
    ForceNoStore,
}

pub type SegmentConfig(
    dynamic: DynamicMode,
    dynamicParams: bool,
    revalidate: i32,
    fetchCache: FetchCache,
)

pub fn defaultSegmentConfig() -> SegmentConfig
pub fn registerSegmentConfig(seg: string, config: SegmentConfig) -> i32
pub fn configFor(pattern: string) -> SegmentConfig
```

`configFor` resolves the nearest ancestor when a segment declares nothing, which is how `§ 11`'s
`export const revalidate` on a layout reaches the pages below it.

**Acceptance:**
- [ ] `defaultSegmentConfig()` is `Auto`, `dynamicParams: true`, `revalidate: -1`, `FetchCache.Auto`.
- [ ] `configFor("/blog/[slug]")` inherits a `revalidate` declared at `/blog` and not at `/blog/[slug]`.
- [ ] A config declared at `/blog/[slug]` overrides the one at `/blog` field by field, not wholesale —
      a segment that sets only `revalidate` keeps the ancestor's `dynamic`.
- [ ] `revalidate: 0` is normalized to `DynamicMode.ForceDynamic` at registration, and `configFor`
      answers the normalized value.
- [ ] `registerSegmentConfig` for a pattern that is not in front 22's table raises, naming the pattern.
- [ ] Registering two configs for one pattern raises rather than taking the last one.

### Step 2 — The static/dynamic decision

```bp
pub type RouteKind {
    Static,
    Dynamic,
}

pub type KindDecision(
    kind: RouteKind,
    reason: string,
)

pub fn decideKind(config: SegmentConfig, hasParams: bool, patternIsDynamic: bool, touchedDynamic: bool, touchedReason: string) -> KindDecision
```

Pure, total, five inputs, and the five numbered rules of *Mechanism* in that order. Keeping it pure is
the point: the rule table is a truth table and it is tested as one.

**Acceptance:**
- [ ] The full truth table is asserted — thirty-two rows over the five inputs, with the expected kind
      and reason for each. Not a sample.
- [ ] `ForceDynamic` wins over a registered `generateStaticParams`.
- [ ] `ForceStatic` with `touchedDynamic: true` answers `Static` and a reason naming the conflict; the
      raise for that case happens in front 62's `strict` frame, not here.
- [ ] A dynamic pattern with no params and `dynamicParams: false` answers `Static` — the route exists
      only for the paths that were enumerated, and there are none.
- [ ] `reason` is `""` exactly when the kind is `Static` by rule 5.

### Step 3 — Enumeration

```bp
pub type ParamBinding(name: string, value: string)
pub type StaticParams(bindings: Array<ParamBinding>)

pub fn registerStaticParams(seg: string, produce: fn() -> @Future<StaticParams[]>) -> i32
pub fn expandParams(pattern: string, rows: StaticParams[]) -> string[]
```

**Acceptance:**
- [ ] `expandParams("/blog/[slug]", [one row binding slug=hello])` answers `["/blog/hello"]`.
- [ ] `expandParams("/shop/[...slug]", [one row binding slug="a/b"])` answers `["/shop/a/b"]`.
- [ ] `expandParams("/docs/[[...slug]]", [one row binding slug=""])` answers `["/docs"]`.
- [ ] A row that binds no `slug` for `/blog/[slug]` raises, naming the pattern and `slug`.
- [ ] A row that binds a name the pattern does not have raises, naming the extra binding.
- [ ] A value containing `/` in a `[slug]` (not catch-all) segment raises — it would produce a path the
      router matches to a different route.
- [ ] Two rows producing the same path raise, naming the path — a duplicate would be prerendered twice
      and served nondeterministically.
- [ ] `expandParams` is pure: the test calls it with literal rows and never starts a build.

### Step 4 — The prerender pass

```bp
pub type PrerenderEntry(
    path: string,
    html: string,
    payload: string,
    tags: Array<string>,
    revalidateAt: i64,
    buildHash: string,
)

pub type PrerenderReport(
    stored: i32,
    skippedDynamic: i32,
    failed: i32,
    lines: string[],
)

pub fn prerenderAll(strict: bool) -> PrerenderReport
pub fn prerenderPath(path: string, strict: bool) -> PrerenderEntry
pub fn lookupPrerendered(path: string) -> ?PrerenderEntry
```

**Acceptance:**
- [ ] `prerenderAll(false)` over a table with one static page and one cookie-reading page stores one
      entry and reports one `skippedDynamic`, with the skipped route's `dynamicReason()` in `lines`.
- [ ] The fan-out uses front 02's unstarted-task form, and a test asserts that prerendering N routes
      whose renderers each sleep `d` completes in well under `N * d` — the assertion that catches an
      accidental `await` in a loop, which the eager `@Future` lowering makes invisible otherwise.
- [ ] Concurrency never exceeds `rakun.static.concurrency`, asserted by a renderer that records its own
      high-water mark in ETS.
- [ ] `prerenderPath` for a path whose route does not exist raises, naming the path.
- [ ] `buildHash` is stable across two prerenders of the same unchanged route and differs when the
      rendered HTML differs by one byte.
- [ ] Entries are readable through front 12's store under `CacheScope.Shared` and namespace
      `rakun.prerender`, asserted through front 12's own API rather than by reaching into ETS.

### Step 5 — Revalidation and single flight

```bp
pub fn serveStatic(path: string) -> ?PrerenderEntry
pub fn isStale(entry: PrerenderEntry) -> bool
pub fn regenerate(path: string) -> i32
```

**Acceptance:**
- [ ] A fresh entry is served with no regeneration started.
- [ ] A stale entry is served **immediately** — the response does not wait for the regeneration,
      asserted by a regenerating renderer that sleeps longer than the test's own budget.
- [ ] Fifty concurrent requests for one stale path start exactly one regeneration, asserted by a
      counter in the renderer.
- [ ] After the regeneration completes, the next request is served the new entry and `isStale` is
      false.
- [ ] A regeneration that raises leaves the stale entry in place, logs once through front 17, and does
      not prevent a later regeneration from succeeding.
- [ ] `revalidateTag` (front 12) over a tag an entry carries marks it stale, so the two revalidation
      paths meet in one store rather than two.
- [ ] `revalidate: -1` never goes stale, whatever the clock says.
- [ ] Draft mode (front 62) bypasses `serveStatic` entirely: a draft request renders fresh and stores
      nothing.

### Step 6 — The route-kind blob

```bp
pub fn routeKinds() -> string
pub fn parseKinds(wire: string) -> Array<#(string, RouteKind)>
pub fn writeKinds(kinds: Array<#(string, RouteKind)>) -> string
pub fn routeKindOf(wire: string, pattern: string) -> RouteKind
```

**Acceptance:**
- [ ] `parseKinds(writeKinds(xs))` equals `xs` compared element by element on `.0` and `.1` — never
      with `==` on the arrays, which is reference equality.
- [ ] `routeKindOf(wire, "/blog/[slug]")` answers the recorded kind.
- [ ] `routeKindOf("", "/anything")` answers `RouteKind.Dynamic` — the documented default when the blob
      is absent.
- [ ] `routeKindOf("garbage", "/x")` answers `RouteKind.Dynamic` and does not raise.
- [ ] Every assertion in this step runs green on `--target erlang` and on `--target commonJS`, from the
      same test file. This is the boundary half and a format only one side can read is the bug this
      step exists to prevent.

### Step 7 — Static export

```bp
pub fn staticExport(outDir: string) -> PrerenderReport
```

**Acceptance:**
- [ ] `staticExport` writes `outDir/index.html` for `/` and `outDir/blog/hello/index.html` for
      `/blog/hello`.
- [ ] The payload is written beside each HTML file under a fixed name, so a client can reconnect to an
      exported page.
- [ ] A route that reaches `cookies()` fails the export with a message naming the route and `cookies`.
      The message comes from front 62's `strict` frame and is asserted verbatim here.
- [ ] A route with a `route.bp` handler (kind `R`) fails the export, naming it — an endpoint cannot be
      a file.
- [ ] The export refuses to write outside `outDir`, checked with front 01's `path.isInside`.
- [ ] Re-running the export over an unchanged tree produces byte-identical files.

## Deferred

**Partial Prerendering is not specified here and is not a gap.** PPR needs a prerendered shell whose
Suspense holes are resumed within the same response, which means this front and front 30 must agree on
a resume protocol before either can implement it — a protocol neither front has, and one that would
change front 23's payload format. It is also absent from the doc revision this milestone tracks: `PPR`
and `partial` have zero occurrences in `NEXTJS-DOCS.md`. It is recorded for **1.0.10-beta**, gated on
fronts 60 and 30 being landed and stable, and it is written here so the omission reads as a decision
rather than an oversight.

The Edge runtime (`export const runtime`) is absent from the doc revision for the same reason and is
likewise not specified. Its BEAM analogue would be a supervised lightweight process pool, which front
04's runtime already is.

## Examples

- [`examples/static-params-example.bp`](./examples/static-params-example.bp) — a blog: a segment config
  with `revalidate`, a `generateStaticParams` that enumerates slugs, and the page that consumes the
  bound param. The route that stays dynamic is in the same file, so the contrast is visible.
- [`examples/route-kinds-example.bp`](./examples/route-kinds-example.bp) — the boundary artifact: the
  kind blob, `writeKinds`/`parseKinds`/`routeKindOf`, and the `Dynamic`-when-absent default that front
  27 relies on, asserted in a `test` block that runs on both targets.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| Declared parameter defaults are never applied, so `SegmentConfig` cannot be partially specified and every registration writes all four fields | `static-params-example.bp`, the `registerSegmentConfig` call | write every field, or start from `defaultSegmentConfig()` and rebuild | apply a declared default at the call site when the argument is omitted |
| A record field cannot be assigned, so "override the ancestor config field by field" cannot be written as a mutation and is a constructor over seven `case` results | `configFor` in *Step 1* | rebuild the record with one expression per field | a record-update expression, `SegmentConfig(base, revalidate: 60)` |

Two gaps front 01 already recorded apply and are cited rather than re-filed: there is no array
destructuring in a binding, so the kind blob is parsed with `split` and `.at(i)`; and there are no
bitwise operators and no `toString(radix)`, so `buildHash` is front 03's function and this front does
not compute a hash of its own.

## Test plan

`repository/rakun/test/segment_config_test.bp` and `repository/rakun/test/static_gen_test.bp`, run by
`botopink test --target erlang` from `repository/rakun/` and by
`zig build test-libs -- --target erlang --lib rakun` in the ecosystem gate.

*Step 6* — and only step 6 — additionally runs on `--target commonJS`, because the route-kind blob is
the boundary half and the browser parses it. That is the same split front 22 uses for its route table,
and it is why `static_gen.bp` keeps the kind functions free of host cells: a pure function compiles
for both targets, a host cell does not.

What the tests assert, by step: the config default, inheritance, field-wise override, normalization and
duplicate-registration failure; the thirty-two-row decision truth table; path expansion including
catch-all, optional catch-all and every failure mode; the prerender pass's storage, skip accounting,
concurrency bound and fan-out timing; staleness, single flight, failure isolation and draft bypass; the
blob round-trip on both targets plus the absent-blob default; and the export's file layout, refusal
cases and reproducibility.

Two things cannot be runtime assertions and are specified rather than tested here: the message text of
the `strict`-frame raise (front 62 owns it and asserts it) and the CLI wiring of `onze13 build`
(front 50 owns it). Both are named above with the exact strings so neither front has to guess.

## Definition of done

- `src/static_gen.bp` and `src/segment_config.bp` compile, and the route-kind functions carry no host
  cell so they build for both targets.
- `src/sidecars/rakun_static_gen.erl` compiles under `erlc` with `-Werror` and its atom does not
  collide with a module rakun emits.
- The five decision rules, the kind blob's format and the `Dynamic`-when-absent default are written
  down here once and cited by fronts 12, 23, 27, 50 and 66 rather than re-derived.
- A static export that reaches a dynamic API fails, and there is no property, flag or per-route opt-out
  that changes that.
- PPR's deferral is recorded above rather than left implicit.
- `repository/rakun/AGENTS.md` names `static_gen.bp`, `segment_config.bp` and the kind blob.
- The front's tests are green on its assigned target — here, erlang for the server half and both for
  the boundary half.

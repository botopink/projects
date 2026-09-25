# Front 66 — Rakun Metadata File Routes

**Track:** B rakun
**Priority:** medium — without it an `onze` site is invisible to crawlers and uninstallable as a PWA.
`sitemap`, `robots`, `manifest` and the icon family are **routes** in Next's model — a file that
produces a response at a fixed URL — so they belong to the router, not to the metadata renderer, which
is why folding them into front 32 would be wrong
**Target:** erlang (server)
**Wave:** 6
**Depends on:** 22 (registering synthetic routes into the table), 32 (the metadata model whose `<link>`
and `<meta>` tags this front feeds), 62 (the request frame a dynamic sitemap reads from), 03 (the
content hash that fingerprints an image URL), 01 (`path.walk`, `path.glob`, `escape.attribute`,
`encoding.percentEncode`). Optional: 60 (prerendering these routes), 70 (dynamic OG image bodies) —
neither blocks this front, and both are named where they attach
**Owns:** `repository/rakun/src/metadata_routes.bp`,
`repository/rakun/src/sidecars/rakun_metadata_routes.erl`,
`repository/rakun/test/metadata_routes_test.bp`, and one `pub mod` line in
`repository/rakun/src/root.bp`
**Does not touch:** `repository/rakun/src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`,
`src/runtime.mjs` — frozen; `src/file_router.bp` (front 22) is read-only, and this front registers
through its public API rather than editing its table format; `repository/jhonstart/src/metadata.bp` is
front 32's
**Reference:** `NEXTJS-DOCS.md § 18. Metadata e OG Images` (Metadata Files · OG Images dinâmicas),
`§ 3. Estrutura do Projeto` (Exemplo de estrutura — `opengraph-image.tsx`) ·
<https://nextjs.org/docs/app/api-reference/file-conventions/metadata/sitemap> ·
<https://nextjs.org/docs/app/api-reference/file-conventions/metadata/robots> ·
<https://nextjs.org/docs/app/api-reference/file-conventions/metadata/manifest> ·
<https://nextjs.org/docs/app/api-reference/file-conventions/metadata/app-icons> ·
<https://nextjs.org/docs/app/api-reference/file-conventions/metadata/opengraph-image>

---

## Problem

`§ 18`'s Metadata Files table lists eight conventions and the milestone implements none of them. A
site built on `onze` today has no `robots.txt`, so a crawler applies its own defaults; no
`sitemap.xml`, so discovery is link-walking only; no `manifest.webmanifest`, so the site cannot be
installed; and no favicon, because `favicon.ico` is a file in `app/` that nothing serves.

The reason this is a front and not a fold-in is a modelling one. Front 32 renders `<head>`: it turns a
`Metadata` record into tags. Every item in `§ 18`'s table is something else — a file that **is** a
route, answering at a fixed URL with its own content type. `/sitemap.xml` is not a tag; it is a
response. Putting response-producing conventions inside a tag renderer would give front 32 a router,
and rakun already has one.

The subtle half is segment scoping. `opengraph-image` in `app/blog/[slug]/` must override the one in
`app/`, per segment, and the `<meta property="og:image">` the page emits must point at whichever one
won. That resolution is the part every hand-rolled implementation gets wrong, and it is the part that
needs the route tree — which front 22 has and front 32 does not.

## Current state

- `repository/rakun/src/file_router.bp` (front 22) — the `kind|pattern|slot|verb` table of
  [`contracts.md` § 1](../../contracts.md), with `R` reserved for route handlers. Its *Definition of done*
  names front 66 as a consumer. Nothing registers a synthetic route today.
- `repository/jhonstart/src/metadata.bp` (front 32) — the `Metadata` record and `generateMetadata`.
  Front 32 keeps both; this front hands it `<link>` and `<meta>` entries and takes none of its surface.
- `repository/rakun/src/http.bp:45-73` — `Response.ok/json/created/withStatus/notFound/badRequest`.
  There is no `Response` builder with a content type, which is why every route this front registers
  sets its content type through front 04's `rkSetReplyHeader`.
- `libs/std/src/path.bp` — the posix calculator. `walk` and `glob` are added by front 01 and this front
  is one of their two consumers (front 60 is the other); `escape.attribute` is likewise new in front 01
  and is what keeps a `<`-bearing title out of an XML attribute.
- `repository/rakun/src/metadata_routes.bp` does not exist.

## Mechanism

### What Next.js does

Eight file names in `app/` produce responses at fixed URLs (`§ 18` Metadata Files). `sitemap.ts`
exports entries rendered as XML at `/sitemap.xml`; `robots.ts` exports rules rendered at
`/robots.txt`; `manifest.ts` produces the PWA manifest. `favicon.ico`, `icon.*` and `apple-icon.*` are
static files that are both served and emitted as `<link>` tags. `opengraph-image` and `twitter-image`
exist in two forms — a static image beside the segment, or a module whose default export renders one
(`§ 18` OG Images dinâmicas) — and both produce a URL plus a `<meta>` tag, resolved per segment.

### How it maps onto botopink

**Each convention is a registration, and the registration produces a route.** The registration shape is
rakun's own — a module-level `val` calling a host cell, which is what the component decorators already
emit (`repository/rakun/src/decorators.bp:49`) — and the route it produces goes into front 22's table
through that front's public registration API as an `R` entry with verb `GET`. **No new kind letter and
no new field**: [`contracts.md` § 1](../../contracts.md) is unchanged by this front, which is what keeps
it removable.

```bp
val _sitemap = registerSitemap(sitemap);
val _robots = registerRobots(robots);
val _manifest = registerManifest(manifest);
val _ogBlog = registerImageRoute(ImageKind.OpenGraph, "blog/[slug]", blogOgImage);
val _icon = registerIconFile(IconKind.Icon, "", "icon.png", "image/png", "512x512");
```

**Rendering is pure botopink.** XML, `robots.txt` and the manifest JSON are built by functions that
take a record and answer a string, with no host cell between them. That makes the output byte-testable
against a literal, which is the only way to be sure a crawler will accept it — and `std/json` has no
structured value (`libs/std/src/json.bp:9-16`), so a hand-built manifest string is the only option
anyway. Every interpolated value goes through `escape.attribute` or `escape.html` (front 01): a post
title containing `&` in a sitemap is malformed XML, and a title containing `"` in a manifest is
malformed JSON.

**Discovery is a build-time scan, not a runtime one.** `path.glob("**/{icon,apple-icon,favicon,opengraph-image,twitter-image}.*", appDir)`
and `path.walk` (both front 01) find the static files under `appDir`; the CLI (front 50) turns each hit
into a `registerIconFile` / `registerImageRoute` call, the same way it turns a directory into front
22's decorator argument. The server never scans a directory to answer a request.

**Segment-scoped resolution is nearest-ancestor.** `resolveImage(kind, pattern)` walks from the
pattern up to `/` and takes the first registration. `metaTagsFor(pattern)` and `iconLinksFor(pattern)`
answer what front 32 puts in `<head>`. The rule is stated once here and cited by front 32 rather than
implemented twice.

**Image URLs carry a content hash.** An OG image at `/blog/[slug]/opengraph-image` is served as
`/blog/hello/opengraph-image?<hash>`, with the hash from front 03 over the file's bytes (static form)
or over the rendered body (dynamic form). That is what lets the route carry a long-lived cache header
without a stale card surviving a redeploy, and it matches what Next does with the same convention.

**The two image forms, and what each needs.** A static file beside the segment is served directly and
needs nothing beyond front 01's `fs`. A `.bp` module whose exported function renders one is handed to
front 70, which turns an element tree into SVG and optionally rasterizes it. Front 70 is optional here:
with it absent, `registerImageRoute` still registers the route and the URL and the `<meta>` tag are
still produced, and the route answers 501 with a message naming front 70 rather than a broken image.
An explicit failure at one route is better than a site that half-works and better than blocking this
front on a low-priority one.

**Prerendering is optional too.** Every route this front registers is static unless its producer reads
the request frame. Front 60 prerenders it when front 60 is present; when it is not, the route is
rendered per request and `sitemap.xml` costs one database read per crawler hit. Front 60's
`decideKind` needs no special case for these routes — they are pages as far as it is concerned — and
this front adds none.

**The sitemap index rule.** A sitemap may hold 50 000 URLs and 50 MB. Above either bound the output
must be split into shards with an index at `/sitemap.xml` pointing at `/sitemap/0.xml`,
`/sitemap/1.xml` and so on. This is not an optimization: a crawler rejects an oversized sitemap
outright, and the failure mode is silence. `shardEntries` and `renderSitemapIndex` implement it and the
bound is not configurable upward.

### Target

erlang. Every route here answers a request. The rendering functions are pure botopink and carry no
host cell, so they would compile for commonJS too, but this front declares no boundary artifact: none
of these URLs is fetched by the client router, and nothing about them enters front 23's payload. The
module's host cells are `#[@External.Erlang]` over the file reads and the route registration.

**The sidecar module atom is `rakun_metadata_routes`**, not `metadata_routes`: `shipErlSidecars` skips
a qualifier whose atom matches a module this build emitted
(`modules/compiler-cli/src/cli/libs.zig:596`) and rakun emits `rakun/metadata_routes`. Same rule as
front 04's `rakun_runtime`.

## Steps

### Step 1 — `sitemap.bp`

```bp
pub type SitemapEntry(
    loc: string,
    lastModified: string,
    changeFrequency: string,
    priority: string,
)

pub fn registerSitemap(produce: fn() -> @Future<SitemapEntry[]>) -> i32
pub fn renderSitemap(entries: SitemapEntry[]) -> string
pub fn shardEntries(entries: SitemapEntry[]) -> Array<SitemapEntry[]>
pub fn renderSitemapIndex(shards: i32, origin: string) -> string
```

`priority` and `changeFrequency` are strings, not enums, because the sitemap protocol's vocabulary is
closed and small and a string compared against a fixed list in one validation function is less surface
than four enum types. An out-of-vocabulary value fails at registration.

**Acceptance:**
- [ ] `renderSitemap` of two entries answers the exact XML document, asserted as a literal including
      the declaration and the `urlset` namespace — a crawler parses bytes, so the test does too.
- [ ] An entry whose `loc` contains `&` renders `&amp;` and the document stays well-formed.
- [ ] An entry whose `lastModified` is `""` omits the element rather than emitting an empty one.
- [ ] `changeFrequency: "sometimes"` fails at registration, naming the value and the accepted set.
- [ ] `priority: "1.5"` fails at registration.
- [ ] `shardEntries` of 50 001 entries answers two shards; of 50 000 answers one.
- [ ] With more than one shard, `/sitemap.xml` renders the index and `/sitemap/0.xml` renders the first
      shard; with one shard, `/sitemap.xml` renders the shard itself and no index exists.
- [ ] The bound is not readable from a property: a test asserts there is no configuration key that
      raises it.
- [ ] The response carries `Content-Type: application/xml`.

### Step 2 — `robots.bp`

```bp
pub type RobotRule(
    userAgent: string,
    allow: string[],
    disallow: string[],
)

pub type Robots(
    rules: Array<RobotRule>,
    sitemap: string,
    host: string,
)

pub fn registerRobots(produce: fn() -> @Future<Robots>) -> i32
pub fn renderRobots(r: Robots) -> string
```

**Acceptance:**
- [ ] `renderRobots` answers the exact text, asserted as a literal with `\n` line endings.
- [ ] A rule with an empty `allow` and one `disallow` emits only the `Disallow:` line.
- [ ] `sitemap: ""` omits the `Sitemap:` line.
- [ ] A user agent or path containing a newline fails at registration — an injected line is an injected
      rule.
- [ ] The response carries `Content-Type: text/plain`.
- [ ] With no `registerRobots`, `/robots.txt` answers 404 rather than an empty file: an empty
      `robots.txt` means "crawl everything" and inventing that answer is a policy decision this front
      does not get to make.

### Step 3 — `manifest.bp`

```bp
pub type ManifestIcon(
    src: string,
    sizes: string,
    contentType: string,
)

pub type WebManifest(
    name: string,
    shortName: string,
    startUrl: string,
    display: string,
    backgroundColor: string,
    themeColor: string,
    icons: Array<ManifestIcon>,
)

pub fn registerManifest(produce: fn() -> @Future<WebManifest>) -> i32
pub fn renderManifest(m: WebManifest) -> string
```

**Acceptance:**
- [ ] `renderManifest` answers the exact JSON, asserted as a literal — built by string composition,
      because `std/json` has no structured value ([`language-gaps.md`](../../language-gaps.md), *Unowned
      surface*).
- [ ] A name containing `"` is escaped and the document stays parseable.
- [ ] `display: "fullscreen-ish"` fails at registration, naming the accepted set.
- [ ] An empty `icons` array renders `"icons": []` rather than omitting the key.
- [ ] The route is `/manifest.webmanifest` and carries
      `Content-Type: application/manifest+json`.
- [ ] Front 32 emits `<link rel="manifest" href="/manifest.webmanifest">` when a manifest is
      registered and nothing when one is not.

### Step 4 — The icon family

```bp
pub type IconKind {
    Favicon,
    Icon,
    AppleIcon,
}

pub fn registerIconFile(kind: IconKind, seg: string, file: string, contentType: string, sizes: string) -> i32
pub fn iconLinksFor(pattern: string) -> Array<#(string, string)>
```

**Acceptance:**
- [ ] `favicon.ico` in `app/` is served at `/favicon.ico` with `image/x-icon`.
- [ ] `icon.png` in `app/` is served at `/icon.png` with a content hash in the query and a one-year
      cache header.
- [ ] `apple-icon.png` produces `<link rel="apple-touch-icon">` with its `sizes` attribute.
- [ ] `iconLinksFor` answers the tags for the resolved set at a pattern, and the attribute values go
      through `escape.attribute` (front 01).
- [ ] A registered file that does not exist under `appDir` fails the scan, naming the file.
- [ ] A registration whose `file` escapes `appDir` fails, checked with `path.isInside` (front 01).

### Step 5 — `opengraph-image` and `twitter-image`

```bp
pub type ImageKind {
    OpenGraph,
    Twitter,
}

pub type ImageRoute(
    kind: ImageKind,
    pattern: string,
    width: i32,
    height: i32,
    contentType: string,
)

pub fn registerImageFile(kind: ImageKind, seg: string, file: string, contentType: string, width: i32, height: i32) -> i32
pub fn registerImageRoute(kind: ImageKind, seg: string, render: fn(route: PageContext) -> @Future<Element>) -> i32
pub fn resolveImage(kind: ImageKind, pattern: string) -> ?ImageRoute
pub fn imageUrlFor(kind: ImageKind, pathname: string) -> ?string
pub fn metaTagsFor(pattern: string) -> Array<#(string, string)>
```

`width`/`height` default to 1200×630 and the content type to `image/png` in the sense that
`§ 18`'s `size` and `contentType` exports do — but they are written out at every call site, because a
declared parameter default is never applied ([`language-gaps.md`](../../language-gaps.md)).

**Acceptance:**
- [ ] An `opengraph-image` registered at `blog/[slug]` overrides one registered at the root, for
      `/blog/hello` and not for `/about`.
- [ ] With no registration at any ancestor, `resolveImage` answers `null` and `metaTagsFor` emits no
      `og:image` — an absent card is better than one pointing at a 404.
- [ ] `imageUrlFor(OpenGraph, "/blog/hello")` answers `/blog/hello/opengraph-image?<hash>`, and the
      hash changes when the underlying file or rendered body changes by one byte.
- [ ] `metaTagsFor` emits `og:image`, `og:image:width`, `og:image:height` and `og:image:type`, and the
      Twitter kind emits `twitter:image` and `twitter:card`.
- [ ] A dynamic image route with front 70 absent answers 501 with a body naming front 70; the `<meta>`
      tag is still emitted, so the failure is one route and not a missing head.
- [ ] A static image file is served with its own bytes and a one-year cache header.
- [ ] Front 32 consumes `metaTagsFor` and `iconLinksFor` unchanged; the resolution rule is cited from
      here and implemented once.

### Step 6 — Route registration and the scan

```bp
pub fn metadataRoutePatterns() -> string[]
pub fn scanMetadataFiles(appDir: string) -> string[]
```

**Acceptance:**
- [ ] Every registration adds exactly one `R` entry with verb `GET` to front 22's table, and
      [`contracts.md` § 1](../../contracts.md)'s four-field format is unchanged — asserted by round-tripping
      the table through `parseTable`/`writeTable` with these entries in it.
- [ ] A metadata route and an application `route.bp` claiming the same URL fail the scan, naming both —
      front 22 already fails a segment holding both `page.bp` and `route.bp`, and this is the same rule
      reaching the synthetic routes.
- [ ] `scanMetadataFiles` uses `path.glob` and `path.walk` (front 01) and finds an `icon.png` nested
      three directories deep.
- [ ] A metadata file inside a `_private` folder is not registered — front 22 excludes those from
      routing and a synthetic route must not smuggle one back in.
- [ ] Registering two sitemaps, two robots or two manifests raises rather than taking the last one.

## Examples

- [`examples/metadata-files-example.bp`](./examples/metadata-files-example.bp) — the four
  response-producing conventions for one blog: `sitemap`, `robots`, `manifest` and the icon
  registration, each as the developer writes it.
- [`examples/og-image-example.bp`](./examples/og-image-example.bp) — the segment-scoped image: a root
  `opengraph-image` and a per-post one that overrides it, plus the `<meta>` tags front 32 emits for
  each.

## Language gaps

Every gap this front hits is already in [`language-gaps.md`](../../language-gaps.md) and is cited rather
than re-filed: **declared parameter defaults are never applied** (so `size` and `contentType` are
written out at every `registerImageRoute` call), **no byte or binary type** (so a static icon's bytes
marshal through `string` — the file is read and written by host cells at both ends and never touched by
botopink, which is the only shape that is correct today), and **no array destructuring in a binding**
(so the shard walk indexes with `.at(i)`). The **std JSON walker** row under *Unowned surface* is why
`renderManifest` composes a string rather than building a value.

No new gap. Every construct in this front's examples parses today.

## Test plan

`repository/rakun/test/metadata_routes_test.bp`, run by `botopink test --target erlang` from
`repository/rakun/` and by `zig build test-libs -- --target erlang --lib rakun` in the ecosystem gate.

erlang only. The four render functions are pure and would compile for commonJS, but no client fetches
these URLs and nothing about them enters front 23's payload, so a second target row would assert the
same literals twice for no consumer. That is the one difference between this front and fronts 60, 61
and 65, and it is why this front declares no boundary artifact.

What the tests assert, by step: the sitemap XML as a literal, its escaping, its vocabulary validation
and the shard/index switch including the non-raisable bound; the robots text as a literal, its omission
rules, the newline-injection refusal and the 404-when-absent rule; the manifest JSON as a literal, its
escaping and its display validation; the icon family's URLs, content types, hashed query and traversal
refusal; segment-scoped image resolution including the no-registration case, the URL hash, the meta tag
set and the front-70-absent 501; and the route registration's table round trip, its collision failure
and its `_private` exclusion.

The scan-time failures (a registered file that does not exist, a collision with an application route,
a duplicate registration that aborts boot) are startup failures rather than runtime asserts; they go in
front 50's CLI suite with the message text specified above, which is the split fronts 22, 61 and 65
also use.

## Definition of done

- `src/metadata_routes.bp` compiles with no `@External.Node` cell, and the four render functions carry
  no host cell.
- `src/sidecars/rakun_metadata_routes.erl` compiles under `erlc` with `-Werror` and its atom does not
  collide with a module rakun emits.
- The route-table format of [`contracts.md` § 1](../../contracts.md) is unchanged by this front, and the
  README says so.
- Front 32 keeps `generateMetadata` and the `Metadata` record; it consumes `metaTagsFor` and
  `iconLinksFor` from here and cites the nearest-ancestor rule rather than implementing it again.
- The 50 000-entry sitemap bound cannot be raised by configuration, and a test asserts the absence of
  the key.
- `repository/rakun/AGENTS.md` names `metadata_routes.bp` and the eight conventions it serves.
- The front's tests are green on its assigned target — here, erlang.


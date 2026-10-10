# Front 162 — onze: stand-up, CLI, image, release, Astro's routing, content, data, CLI — and the example app, last

**Priority:** high — the library tier (decision 433); runs after the 144 steps it names.
**Owns:** `repository/onze/**`
**Depends on:** every other library front (53 needs them); 144 B-17 (293), B-19 (281), B-27 (116); 146 (306); 150 s13 / s1 / s16; 149 s1 / s2 / s3; pending std-d, 50-b, 52-a, 49-e, 49-g, nat-f2
**Does not touch:** `repository/botopink-lang/**` — a compiler or std gap is a `language-gaps.md` row and this
front pauses on the 144 step that fixes it (fronts.md rules 1, 9); another library's files except a consumer
commit (decision 188), producer first.
**Gate:** standard (fronts.md § Gate); a moved block keeps its own `**Gate:**` additions.

Order: 49 → 50 → 51 → 71 s1–s2 → 117 → 121 → 122 → 124 s1–s4 → 53 → 71 s5 → 124 s5. Consumer commits it
receives: B-02, B-08 (158), B-20, 142 (json, yaml, markdown).

## Alias table

Old ids stay valid in `decisions-taken.md`'s *Where* column, `language-gaps.md`'s owners and the
closed records: each resolves here. A "box n" counts the old step's open boxes, in order.

| Old id | Step here |
|---|---|
| `49-onze-stand-up` s2 | 162 s1 |
| `49-onze-stand-up` s3 | 162 s1 |
| `49-onze-stand-up` s4 | 162 s1 |
| `49-onze-stand-up` s5 | 162 s1 |
| `49-onze-stand-up` gate | 162 s1 |
| `50-onze-cli` s2 | 162 s2 |
| `50-onze-cli` s3 | 162 s2 |
| `50-onze-cli` s4 | 162 s2 |
| `50-onze-cli` s5 | 162 s2 |
| `50-onze-cli` s6 | 162 s2 |
| `50-onze-cli` s7 | 162 s2 |
| `50-onze-cli` s9 | 162 s2 |
| `50-onze-cli` s10 | 162 s2 |
| `51-onze-image` s2 | 162 s3 |
| `51-onze-image` s3 | 162 s3 |
| `51-onze-image` s4 | 162 s3 |
| `51-onze-image` s5 | 162 s3 |
| `51-onze-image` s6 | 162 s3 |
| `51-onze-image` s8 | 162 s3 |
| `71-onze-release-packaging` s1 | 162 s4 |
| `71-onze-release-packaging` s2 | 162 s4 |
| `71-onze-release-packaging` s3 | 162 s4 |
| `71-onze-release-packaging` s4 | 162 s4 |
| `71-onze-release-packaging` s5 | 162 s4 |
| `71-onze-release-packaging` gate | 162 s4 |
| `117-bpp-routing` s0 box 1 | 162 s5 |
| `117-bpp-routing` s1 boxes 2, 3 | 162 s5 |
| `117-bpp-routing` s2 | 162 s5 |
| `117-bpp-routing` s3 | 162 s5 |
| `117-bpp-routing` s4 | 162 s5 |
| `117-bpp-routing` s6 | 162 s5 |
| `117-bpp-routing` s7 | 162 s5 |
| `117-bpp-routing` s8 | 162 s5 |
| `121-bpp-content` s3 | 162 s6 |
| `121-bpp-content` s4 | 162 s6 |
| `121-bpp-content` s5 | 162 s6 |
| `121-bpp-content` s6 | 162 s6 |
| `121-bpp-content` s7 | 162 s6 |
| `121-bpp-content` s8 | 162 s6 |
| `121-bpp-content` s9 | 162 s6 |
| `121-bpp-content` s10 | 162 s6 |
| `121-bpp-content` gate | 162 s6 |
| `122-bpp-data` s0 box 1 | 162 s7 |
| `122-bpp-data` s3 | 162 s7 |
| `124-bpp-cli` s1 | 162 s8 |
| `124-bpp-cli` s2 | 162 s8 |
| `124-bpp-cli` s3 | 162 s8 |
| `124-bpp-cli` s4 | 162 s8 |
| `124-bpp-cli` s5 | 162 s8 |
| `124-bpp-cli` gate | 162 s8 |
| `53-onze-example-app` s1 | 162 s9 |
| `53-onze-example-app` s2 | 162 s9 |
| `53-onze-example-app` s3 | 162 s9 |
| `53-onze-example-app` s4 | 162 s9 |
| `53-onze-example-app` s5 | 162 s9 |
| `53-onze-example-app` s6 | 162 s9 |
| `53-onze-example-app` s7 | 162 s9 |
| `53-onze-example-app` s8 | 162 s9 |
| `53-onze-example-app` s9 | 162 s9 |
| `53-onze-example-app` s10 | 162 s9 |
| `53-onze-example-app` s11 | 162 s9 |
| `53-onze-example-app` s12 | 162 s9 |
| `53-acceptance` s3 | 162 s9 |
| `53-acceptance` s4 | 162 s9 |
| `53-acceptance` s5 | 162 s9 |
| `53-acceptance` s6 | 162 s9 |
| `53-acceptance` s7 | 162 s9 |
| `53-acceptance` definition of done | 162 s9 |
| `20-snap` s5 | 162 s10 |

## Steps

### 162 s1 — stand-up tail (49)

#### Step 2 — the query, the headers, the dispatcher (was `49-onze-stand-up` s2)

- [ ] `requestData` fills `query` from `queryDict(req.query)` (malformed component → the `Error`
      `queryDict` answers → 400 via `responseFor`, asserted) and `headers` from `headerNames` /
      `req.header(name)`; `server_test.bp`: a page reading the query's `q` (`use searchParams()`)
      and the `x-test` header (`use request()`, 291) answers both over the socket
- [ ] `Onze.run` installs `serveActions` with the wire names it set; `server_test.bp`: `POST` with
      `X-Bp-Action` reaches the action, answers the envelope; a boot with the action keys removed
      fails naming `rakun.actions.field` (refusal rakun's, test here)
- [ ] two-file boot (49-e) stated in `docs.md` and true: "`integration.bp` imports jhonstart
      and the bridge; `onze-server/src/server.bp` imports rakun; no third file imports any of
      them"
- [ ] `__bp_action` and `X-Bp-Action` in onze's defaults, nowhere under `repository/rakun/` or
      `repository/jhonstart/` — closes when owners drop the literals (today:
      `rakun-app/test/actions_test.bp` + `actions-cache` fixture, `04-rakun` RX-13 → 22;
      `jhonstart-forms/test/form_test.bp` + `examples/forms`, `05-jhonstart/67` step 4); onze's
      part is the grep

#### Step 3 — the error digest reaches the log (was `49-onze-stand-up` s3)

After `05-jhonstart/26` step 4 and `04-rakun/17`: the boundary logs/digests via bundled `log` (on
`feat`); onze only installs one of `log`'s sinks (349; no `RenderHooks.onError`, 195).

- [ ] `Onze.run` installs `log`'s sink and calls `log.captureRuntimeReports()` (349; via `onze-server`; core `integration.bp`
      imports no rakun type); `server_test.bp`: a throwing page answers 500 with a 16-hex digest
      in the body, same digest in the captured log line
- [ ] `docs.md` § Errors states the one scheme (`log`'s `errorDigest`, decision 194) and where
      the sink is set

#### Step 4 — the public root (decision 201) (was `49-onze-stand-up` s4)

After `04-rakun/65` step 1 (miss falls through, only `GET` / `HEAD` served, refusal final):
`servedRoots` answers both roots; `Onze.run` registers `public/` at `/**` before the routes,
beside the fingerprinted root — no per-entry root, no `/public` prefix.

- [ ] `server_test.bp`: `/robots.txt` from `public/` served with rakun-web's headers; a page URL
      with no file under `public/` renders the page (no 404 from the static entry); exactly two
      roots registered, `docs.md` states there is no third
- [ ] until `04-rakun/65` step 1 lands, `docs.md` says `public/` is not served — no per-entry
      root, no `/public` prefix meanwhile

#### Step 5 — the dynamic mark (decision 186) (was `49-onze-stand-up` s5)

Final state (decision 277): no run-time mark — `onze build` reads each `#[page]`'s `kind` meta
(`S` / `D`) and writes it to `routing`'s `k` blob. The bridge below holds until
`05-jhonstart/26` step 8 lands.

- [ ] `responseFor` calls `ChunkWriter.markDynamic(reason)` when jhonstart's render reports `d`
      (`04-rakun/22` step 4 adds the method, removes rakun's implicit mark); `pageInput` /
      `requestData` build the query without a marking read; `server_test.bp`: a page never
      reading the query is prerenderable (rakun's `isDynamic()` false), one with
      `use searchParams()` is not
- [ ] after `05-jhonstart/26` step 8: `onze build` writes the `k` blob from the `kind` meta, prints
      `S prerendered` / `D per request (why)` per route; `responseFor`'s `markDynamic` call deleted

#### Gate additions (was `49-onze-stand-up` gate)

**Gate:** standard (fronts.md § Gate) +
- [ ] `zig build test-libs` — `onze` 23+, `onze-server` 10+, `onze-test` 7+, on every target its
      manifest declares (`onze-server`: erlang)
- [ ] `grep -rn "flush()" modules/onze modules/onze-server` empty (no style sink)

### 162 s2 — CLI tail (50)

#### Step 2 — `onze dev` (50-b (a)) (was `50-onze-cli` s2)

- [ ] `onze dev` on `examples/scaffold` serves `/`, prints `http://localhost:3000` (`dev_test.bp`,
      real socket like `start_test.bp`)
- [ ] editing `app/page.bp` changes the next response after rebuild; adding `app/about/page.bp`
      makes `/about` resolve (manifest and `onze_routes.bp` regenerated)
- [ ] a compile error prints the compiler's own message; the previous build keeps answering
- [ ] `-p` does not write `onze.json`; `-H <addr>` binds that address (`reference-holes.md` § 29)
- [ ] `main.bp` dispatches `dev` to `dev.bp`; the "not available yet" text (and its stale "front 50
      step 6") gone

#### Step 3 — `prerender/` (was `50-onze-cli` s3)

- [ ] `onze build` on the blog writes `prerender/blog/<slug>/index.html` per static post, nothing
      for a dynamic route; the five output entries of 1.0.10's step 7 exist
- [ ] `start` serves a prerendered route without invoking the page (53 step 2 asserts the counter)

#### Step 4 — the signal (`std-d`) (was `50-onze-cli` s4)

- [ ] under (b): `start` execs `bin/onze`, absent from the process tree while the node runs;
      `start_test.bp` sends `SIGTERM` to the node, observes the drain order 71 pins
- [ ] under (a): `start` forwards `SIGTERM` via `process.forwardSignals`

#### Step 5 — `start` calls `bin/onze`; `build` passes `includeErts` (after 71 step 2) (was `50-onze-cli` s5)

- [ ] `start.bp` runs `<outDir>/release/bin/onze` when it exists, else refuses naming it — one
      start path
- [ ] `build.bp` passes `ReleaseSpec.includeErts` through to 71's `assembleRelease`

#### Step 6 — the bundler tail (68) (was `50-onze-cli` s6)

- [ ] entry registers one loader per route pattern (`registerRouteStarters`), imports no island
      statically; `chunk_test.bp`: an island used by one route is in that route's chunk, not
      `shared`; the blog's `LikeButton` leaves `shared`
- [ ] `OnzeConfig.assetPrefix` (default `""`) threaded through `ChunkRef.url` and the served
      prefixes; `manifest_test.bp` round-trips it on both rows; `config_test.bp` refuses a prefix
      not an absolute URL or `""`
- [ ] `<Script onReady / onError>`: `script_test.bp` asserts both callbacks scheduled per strategy
- [ ] entry calls `jhonstart-link`'s `applyTransition` on client navigation, supplying the four
      `DomOps`; `entry_test.bp` asserts the generated call

#### Step 7 — the defaults table, `--example`, the prompts, `resolve_test.bp` (was `50-onze-cli` s7)

- [ ] `docs.md`'s `create` table is `createHelp()`'s output, compared by a `check-docs` cell
      (`--help` and parser already read `createDefaults()`); `create_test.bp` asserts the three
      agree
- [ ] `onze create --example scaffold` copies `examples/scaffold`; under `std-d` (b) `create`
      without `--yes` refused listing the flags; under (a) prompts via `readLine`
- [ ] `test/resolve_test.bp` exists with `resolve.bp`'s cases moved from `scan_test` / `create_test`
      (total counts preserved)
- [ ] `examples/scaffold/README.md` names `create`'s table and `NEXTJS-DOCS.md` § 29

#### Step 9 — the `@/` alias goes (decision 218, handed by `01-compiler/129`) (was `50-onze-cli` s9)

Apps import own modules by path in braces (`import {lib.db.findPost};`, decision 206); staging
no longer resolves `from "@/…"` — `module-import-with-from` like any other. Today: `onze-bundler`'s
`AliasMap` resolves `@/…` (`graph.bp` `edgesOf` → `resolveAlias`, `rebuild.bp`
`BundleSetup.aliases`); `src/fixture.bp`, `graph_test` / `rebuild_test` import through it;
`examples/scaffold/botopink.json` declares `"alias"`; `docs.md` documents it.

- [ ] `AliasMap`, `resolveAlias` gone; bundler tests and `fixture.bp` import by path
- [ ] `examples/scaffold/botopink.json` has no `"alias"` key; `docs.md` names the brace form, not
      the alias (blog's half: 53 step 1)
- [ ] `grep -rn '"@/' repository/onze/modules repository/onze/examples/scaffold --include=*.bp` is empty
- [ ] `onze-test`'s `assertAlias` (`src/core.bp`, its two `test/helpers_test.bp` cases and `.snap`)
      deleted — 49's files, one carve-out commit

#### Step 10 — `<Script>`'s strategy is an enum (decision 292) (was `50-onze-cli` s10)

- [ ] `onze-bundler/src/script.bp`: `pub type ScriptStrategy { BeforeInteractive, AfterInteractive,
      LazyOnload, Worker }`; `<Script src=… strategy={.LazyOnload} />` takes it as a prop;
      `strategies() -> string[]` and `scriptPlacement(strategy: string)` go (281); an unknown one is the
      missing-variant error at the prop
- [ ] `script_test.bp` per variant; the strategies stay separate from the islands' `Hydrate` (120)

**Gate:** standard (fronts.md § Gate) +
- [ ] `zig build test-libs` — `onze-cli` 31+ and `onze-bundler` 42+ on every target its manifest
      declares; `scaffold` green

### 162 s3 — image, font and image response (51)

#### Step 2 — single flight, and the route (was `51-onze-image` s2)

- [ ] `image_test.bp`: two concurrent identical requests (two spawned `imageResponse` calls over
      a sleeping stand-in encoder) → one encoder invocation, counted from the stand-in's log
- [ ] `/_onze/image` registration line (front 25's `getRoute` over the handler, erlang) written
      here, handed to 49 for `Onze.run`; `server_test.bp` (49's) serves a resized fixture with
      `Cache-Control: public, max-age=31536000, immutable`
- [ ] remote sources: 501 stays, `docs.md` says so (no fetch without a decision)

#### Step 3 — the § 16 prop table (was `51-onze-image` s3)

- [ ] `docs.md` § Image holds § 16's table row by row: honoured (`src`, `width`, `height`,
      `alt`, `sizes`, `priority`, `quality`, `fill`, `placeholder`, `style`, `className`,
      `loading`), or out of scope with reason (`loader`, `unoptimized` per image, `overrideSrc`,
      `onLoad`, `onError`, `getImageProps`) — per `../reference-holes.md` § 16
- [ ] `defaultImageConfig().remotePatterns == []` asserted; the blog README sentence handed to 53

#### Step 4 — the metrics generator (52-a) (was `51-onze-image` s4)

- [ ] `modules/onze-assets/scripts/font-metrics.py` (or `.bp` over `io.process` if `fontTools`
      is invoked as a command) reads a font file, prints one `font_metrics.bp` row; file header
      carries the command, source URLs, date; the five rows re-derived match the transcribed ones
      or those are corrected
- [ ] `localFont`'s probe bound to the same reader over a local file; `font_test.bp` covers a
      fixture `.ttf` (small open font committed under `test/fixtures/`)

#### Step 5 — the OG defaults, the 2 % test, one table (was `51-onze-image` s5)

- [ ] a route whose `#[ogImage]` gives no size or type (step 8; today: one exporting neither `size`
      nor `contentType`) renders 1200×630 PNG via rakun 66's discovery; `og_test.bp` asserts
      through the discovered record
- [ ] `measure` agrees with `rsvg-convert`'s layout of a fixture string within 2 % — runs when
      the rasterizer is installed; hard failure without it only in the gate's environment (a dev
      machine prints the skip reason; `00-gate` decides whether a skip is red)
- [ ] `supportedProperties()` is the one list; `docs.md`'s table generated from it; `margin` and
      `border` in both or neither

#### Step 6 — one render per post (was `51-onze-image` s6)

- [ ] `og_test.bp`: N concurrent requests for one post spawn one rasterizer process, write one
      file (`rkCacheFlight` around `response.bp`'s render)

#### Step 8 — a role in the decorator, not in an export's name (decision 282) (was `51-onze-image` s8)

- [ ] the OG route's `pub val size` / `pub val contentType` → `#[ogImage(size: ImageSize(1200, 630),
      type: .Svg)] pub fn image(…)`; rakun 66's discovery reads the decorator's meta, not export names;
      no decorator argument = the 1200×630 PNG default

**Gate:** standard (fronts.md § Gate) +
- [ ] `zig build test-libs` — `onze-assets` at its counts or above (image 8, font 7, styling 13)
      and `onze-og` 10+, on every target its manifest declares

### 162 s4 — release packaging (71)

#### Step 1 — `includeErts` copies the runtime (was `71-onze-release-packaging` s1)

- [ ] `package_test.bp`: `includeErts: true` → release holds `erts-<vsn>/bin/erl`; `false` → not
- [ ] `release_text_test.bp`: the two Dockerfile texts differ only in the runner `FROM` line
      (`alpine:3.20` with ERTS, `erlang:<otpRelease>-alpine` without — as `docker.bp` and its
      snapshot)

#### Step 2 — `bin/onze` (was `71-onze-release-packaging` s2)

- [ ] runs `verifyBuildId` before the boot script; exits non-zero naming the mismatch when the
      manifest's id, the stamped id or the payload's differ (`package_test.bp` tampers each in a
      scratch release)
- [ ] `exec`s the OTP boot script (PID 1 = the VM); `PORT` defaults to 3000
- [ ] 50 step 5's box ("`start` calls this script and adds no second start path") closable on
      this step

#### Step 3 — the shutdown against real cells (was `71-onze-release-packaging` s3)

- [ ] `lifecycle.bp`'s five steps run over rakun's real cells (readiness down, listener
      stop/drain — rakun 11 and 62's `after()`) once they land; until then the recording double
      stays, box open, named "rakun 11 / 62 / 81"

#### Step 4 — static export to disk and `examples/static-site/` (was `71-onze-release-packaging` s4)

- [ ] `static_export.bp` writes `<outDir>/export/<route>/index.html` per prerendered route, the
      static asset tree under `_onze/static/<buildId>/`, `public/` copied; no boot script, no
      `releases/`
- [ ] `examples/static-site/` — three static routes, `onze.json` `output: "export"`, a
      `README.md`; `test/export_test.bp` builds it, asserts the tree; a fourth, dynamic route
      added in a test fails the export naming itself
- [ ] `zig build test-libs` lists `static-site` green on both rows

#### Step 5 — the four gate boxes over the blog (was `71-onze-release-packaging` s5)

After 50 and 53; asserted by `package_test.bp` over the blog's real release in the gate's
environment (container runtime present).

- [ ] `onze build` on the blog produces `docs.md`'s release layout; `onze start` boots it from a
      directory with no source tree and no `botopink` binary, answering `/` — hard failure while
      the sidecar-loading row is open, named as such
- [ ] build id derived once; `verifyBuildId` passes across release, client manifest, payload
- [ ] the Dockerfile builds; the container runs non-root on `PORT` (gate's environment provides
      `docker` or `podman`; `00-gate` decides how a missing runtime reads)
- [ ] `scanForSecrets` over the real release finds only the `ONZE_PUBLIC_` table 68 inlined

#### Gate additions (was `71-onze-release-packaging` gate)

**Gate:** standard (fronts.md § Gate) +
- [ ] `zig build test-libs` — `onze-release` 9+ on both rows; `static-site` green

### 162 s5 — Astro's routing, onze's and rakun-app's half (117)

#### Step 0 — Measure — part (was `117-bpp-routing` s0 box 1)

- [ ] a `page.bp` whose decorator names another directory: what `onze build` does. If it builds,
      the comparison is this step's first change and `07-onze/50` is told

#### Step 1 — `.bpp`, `.md` and `.html` as app files (a page takes no parameter: 293) — part (was `117-bpp-routing` s1 boxes 2, 3)

- [ ] two forms of one kind in a directory fail the scan with both paths
- [ ] `page.html` served byte for byte, with its extension's content type

#### Step 2 — The exports (was `117-bpp-routing` s2)

Per decision 202 (no `prerender` export).

- [ ] `examples/static-paths-example.bp` passes; scan finds `staticPaths` and `partial` in a `.bp`
      and a `.bpp` page; no `prerender` read
- [ ] a page reading a cookie (`use cookieValue(sessionCookie)`, 294) is not prerendered (rendered per request): its kind is `D` and its
      `why` names the read (`@typeInfo(Page).meta(PageMeta)`, recorded by `#[page]` from `Decl.hooks`, 277)
- [ ] a dynamic route `#[page]` prerenders with no `staticPaths` fails the build (`prerenderAll(strict)`)

#### Step 3 — `StaticPath.data`, `paginate`, `Page<T>` (was `117-bpp-routing` s3)

- [ ] `examples/pagination-example.bp` passes: four items, size two → `/astronauts/1`,
      `/astronauts/2`; `url.prev` `null` on the first, `url.next` on the last
- [ ] data survives `staticExport` and a restart: exported page renders without calling the loader

#### Step 4 — Partials and endpoints with an extension (was `117-bpp-routing` s4)

- [ ] partial response = page markup alone — no `<!DOCTYPE`, no `data-jh-root`, no payload script
- [ ] `app/rss.xml/route.bp` is served per request with its extension's content type; `onze build`
      writes no `<outDir>/rss.xml` (decisions 222, 273)
- [ ] `examples/partial-and-endpoint-example.bp` passes

#### Step 6 — a role in the decorator, not in an export's name (decision 282) (was `117-bpp-routing` s6)

- [ ] `pub fn staticPaths()` and `pub val partial = true` are no longer read: `#[page("dogs/[dog]",
      paths: dogPaths, partial: true)]`, `paths` typed against the page's `PageContext<P, D>`
      (`fn() -> @Task<#(P, D)[]>`, 280 example 4); the scan stops looking for export names
- [ ] a `staticPaths` left in a page module is refused, naming `#[page(…, paths: …)]`

#### Step 7 — route parameters and page data are hooks (decision 293) (was `117-bpp-routing` s7)

- [ ] `StaticPath.data: Json` and `pageData(route, schemaOf…)` go: `paths: fn() -> @Task<#(P, D)[]>`
      (282), the page reads `use params<P>()` / `use pageData<D>()`
- [ ] `static-paths-example.bp`, `pagination-example.bp`, `partial-and-endpoint-example.bp` and the
      `.bpp` tree rewritten to the hooks; a `page.bpp` header with `type Props(route: …)` no longer needed

#### Step 8 — page data typed by the type, not a schema value (decision 306) (was `117-bpp-routing` s8)

- [ ] `paginate(…, schemaOfAstronaut())`, `pageOf(route, schemaOfAstronaut())` take the `#[validated]`
      type (`paginate(astronauts(), 2, "/astronauts", Astronaut)`; with 293, `use pageData<Astronaut>()`);
      `pagination-example.bp`, `static-paths-example.bp` and the two `page.bpp` rewritten

### 162 s6 — content: frontmatter, collections, Markdown pages (121)

#### Step 3 — Frontmatter (396: through the `yaml` library, `03-bundled-libs/142` step 2) (was `121-bpp-content` s3)

- [ ] `test/frontmatter_test.bp`: the reference's five frontmatter blocks decode to the meant
      `Json`; an anchor, a tag, a second document each refused with the line
- [ ] `examples/markdown-example.bp` passes on both targets — its Markdown tests run today as
      `test/markdown_test.bp`; the frontmatter ones wait here
- [ ] no fence → empty object, whole text as body; unclosed fence → `Error`

#### Step 4 — Collections (the rest) (was `121-bpp-content` s4)

- [ ] `examples/content-collection-example.bp` passes on erlang — waits on step 3 (its posts and
      the `fixtures` kit are `.md`), 125 steps 5–6 (`#[orElse]`, `#[coerce]` over `#[isoDatetime]`),
      293's page hooks (step 9) and an onze `StaticPath` (117)
- [ ] the build fails on a sync problem — `writeStore` refuses; `onze build` running it is 124's

#### Step 5 — the editor's schema; the marker; the endpoint (was `121-bpp-content` s5)

- [ ] `#[reference("authors")]` on the field replaces `.reference(…)` — step 10 (the gap row's owner)
- [ ] `<name>.schema.json` validates the entries it came from — waits on 125 step 9 (`jsonSchema`,
      its JSON Schema test tool)
- [ ] `examples/rss-endpoint-example.bp` passes — waits on rakun's `#[getRoute]` under 117 step 4,
      `site` (122/124) and step 3 (its collection is `.md`); the feed itself is `feeds_test.bp`'s

#### Step 6 — Markdown pages and layouts; images (was `121-bpp-content` s6)

- [ ] `page.md` with and without `layout:`; the layout receives frontmatter and heading list
- [ ] `![alt](../../08-bpp/121-bpp-content/cover.png)` beside the document becomes `onze-assets`' image element; `/public`
      paths and remote URLs left as written

#### Step 7 — The blog reads Markdown (was `121-bpp-content` s7)

- [ ] `onze/examples/blog/content/posts/*.md` carry frontmatter; `lib/db.bp`'s `parsePost` deleted,
      pages read `getCollection(posts())`
- [ ] blog's existing tests green with a post holding a heading, a list and a link

#### Step 8 — a role in the decorator, not in an export's name (decision 282) (was `121-bpp-content` s8)

- [ ] `pub fn collections()` found in `src/content.bp` by its name → each collection declared by a
      decorator (`#[collection(glob("content/blog", "**/*.md"))]`), gathered with
      `@TypeInfo.all(with: collection)`; the schema's own shape is decision 306 (step 10)

#### Step 9 — route parameters and page data are hooks (decision 293) (was `121-bpp-content` s9)

- [ ] `content-collection-example.bp`: pages take no `route: PageContext`; parameters through `use params<P>()`, page data through `use pageData<D>()`

#### Step 10 — the collection takes the type (decision 306) (was `121-bpp-content` s10)

- [ ] a collection's schema is a `#[validated]` type, never a `Schema<T>` value: `defineCollection("blog",
      glob(…), schemaOfBlogPost())` → the decorator on the type itself —
      `#[validated] #[collection(glob("content/blog", "**/*.md"))] pub type BlogPost(…)` — or
      `collection(BlogPost)` (`comptime source: type T`, refused unless `@typeInfo(T).meta(Validated)`)
- [ ] a frontmatter field only a value could check (a list of slugs, a date codec) is a field marker
      (`#[each(…)]`, `#[codec(…)]`); `content-collection-example.bp` rewritten
- [ ] `markdown-example.bp`'s `Meta` is `#[validated]`, decoded by its own member (no `#[schema]`, no `schemas.Schema` import)
- [ ] `<name>.schema.json` comes from the type's `jsonSchema` (125 step 9)

#### Gate additions (was `121-bpp-content` gate)

**Gate:** standard (fronts.md § Gate), plus:
- [ ] `botopink test` green on both targets in `modules/onze-content`
- [ ] `zig build test-libs`: onze green, the new member's cells among them
- [ ] `onze/modules.md` and the workspace manifest updated in the same commit

### 162 s7 — the `Astro` global, onze's half (122)

#### Step 0 — Measure — part (was `122-bpp-data` s0 box 1)

- [ ] what a page gets for `request().query`, `.headers` in `onze/examples/blog` (expected `[]`, `onze-server/src/server.bp:76-77`)

#### Step 3 — `site`, `currentUrl` (was `122-bpp-data` s3)

- [ ] `site()` is `""` when unset, and `absoluteUrl(path)` then refuses rather than emit a relative canonical link

### 162 s8 — the CLI: config keys, `sync`, `create-key`, scripts, the scaffold (124)

#### Step 1 — The config keys (after `nat-f2`) (was `124-bpp-cli` s1)

- [ ] § Mechanism keys read and validated; unknown key still refused; `docs.md`'s table generated
      from the one source `--help` and `create` read (ONZ-50-DoD's "defaults table from one source")
- [ ] `trailingSlash: "always"` redirects `/about` to `/about/` with 308; `"never"` the reverse
- [ ] `redirects` to an absolute URL and to a path; a redirect whose source is also a page fails the
      build, naming both (the reference's rule 7, as a refusal)

#### Step 2 — `onze sync` (was `124-bpp-cli` s2)

- [ ] `examples/sync-and-build-session-example.md` — its session is a `compiler-cli`-style shell test under `onze-cli/test/`
- [ ] `onze build` fails on a content violation before compiling anything

#### Step 3 — `onze create-key` and the key in the build (was `124-bpp-cli` s3)

- [ ] two builds with the same `ONZE_KEY` unseal each other's island URLs; two without it do not

#### Step 4 — Component scripts and the style sheet (was `124-bpp-cli` s4)

- [ ] a component used three times on a page contributes its script once
- [ ] a route with no island and no component script loads no JavaScript — asserted on the prerendered file
- [ ] scoped ids rewritten identically in sheet and prerendered markup; test fails if one side stays long

#### Step 5 — The scaffold, and the second blog (was `124-bpp-cli` s5)

- [ ] `onze create --example bpp` (50's `--example` tail) writes a project with `.bpp` pages and a
      posts collection — `examples/scaffold/`: manifest carries `"bpp": {"default": "jhonstart"}` (116, 338), `app/`
      holds `layout.bpp`, `page.bpp`, `not-found.bpp`; `onze build && onze start` serves it
- [ ] `07-onze/53`'s acceptance script runs against it — same routes, same assertions as `examples/blog`

#### Gate additions (was `124-bpp-cli` gate)

**Gate:** standard (fronts.md § Gate), plus:
- [ ] `botopink test` green on both targets in `onze-cli`, `onze-bundler`, `onze`
- [ ] `zig build test-libs`: onze green; `examples/blog` builds unchanged
- [ ] `onze/docs.md` § Configuration, § CLI

### 162 s9 — the example app — the proof (53)

#### Step 1 — the runner and the README (was `53-onze-example-app` s1)

- [ ] runner = five harness functions (`bootApp`, `stopApp`, `buildApp`, `request`, …), no
      snapshot writers; blog E2E cases are asserts over `request(…)`, dev/start gate an equality
      property; one `helpers_test` case per harness function, erlang for `bootApp` / `request`
      (the form `20-snap` § 9 evaluated)

- [ ] `examples/blog/README.md` names `NEXTJS-DOCS.md`'s sections, the fronts, the four commands,
      and that `remotePatterns` is empty (51's sentence)
- [ ] `examples/blog/botopink.json` has no `"alias"` key, no source imports `from "@/…"`
      (decision 218; bundler half 50 step 9)

#### Step 2 — prerender and metadata (after 50 step 3, rakun 60) (was `53-onze-example-app` s2)

- [ ] the four boxes of `acceptance.md` § Step 3, via the dev/start equality property and a
      `pages_test.bp` case reading the `lib/db.bp` counter

#### Step 3 — streaming and boundaries (after jhonstart 26 steps 3–4, 49 step 3) (was `53-onze-example-app` s3)

- [ ] `app/loading.bp`, `app/error.bp` exist; § Step 4's two open boxes (shell before the list;
      500 with the digest — equal to the captured log line's, 49 step 3)

#### Step 4 — the write path (after 49 step 2, jhonstart 67, rakun 24 · 12, the middleware) (was `53-onze-example-app` s4)

- [ ] `src/middleware.bp`, `src/lib/actions.bp`, `src/app/api/posts/route.bp` exist;
      `app/dashboard/posts/new/page.bp` binds its form to the action; § Step 5's five open boxes
      via `write_path_test.bp` and `api_test.bp`, erlang over the socket; the no-JS POST row via
      a request with no script executed

#### Step 5 — the browser (after 50 step 6, jhonstart 27) (was `53-onze-example-app` s5)

- [ ] `test/serve.sh` boots the built app, drives a headless browser through the like button and
      a `Link` navigation; asserts no document request on the navigation, no request on the
      click; `assets_test.bp` asserts the chunk names 50 step 6 produces

#### Step 6 — the commands and the DoD (after 50 step 2, 50-b) (was `53-onze-example-app` s6)

- [ ] `gate_test.bp`: `onze dev` serves every route of the script; `dev` and `start` replies equal
      for every static route (a property over `request`)
- [ ] every `// front NN` comment in `examples/blog/src/**` names a directory under
      `specs/1.0.12-beta/` (a `unit_test.bp` case walks the tree and comments)
- [ ] `acceptance.md` § Assumed API shapes reconciled row by row against landed surfaces; every
      row matches or is changed here
- [ ] the remaining boxes of `acceptance.md` § Definition of done
- [ ] `zig build test-libs` — `blog` green on both rows, `serve.sh` green on erlang in the gate's
      environment

#### Step 7 — references, not strings (decision 281) (was `53-onze-example-app` s7)

- [ ] the examples rewritten: the action passed as a reference — `createPost`, never `"createPost"`
      (done in `new-post-form-example.bp` and `components/new_post_form.bpp`; the hook's name,
      `useActionState` vs `actionState`, is `nat-d8`'s, open) —, `<form action={createPost}>` (no
      `formAction("a_9f31…", …, "__bp_action")`), starters and client props from the catalogue
      found by type at comptime (`#[clientProps]`, 120 step 6; `68-c` → 280, 281 — no
      `registerStarter("…")`, no `Island(component: "LikeButton", …)` in `client-island-example.bp`;
      the payload's wire spelling stays), handlers `#[onClick(…)]`

#### Step 8 — a role in the decorator, not in an export's name (decision 282) (was `53-onze-example-app` s8)

- [ ] the examples rewritten: `generateStaticParams` / `blogStaticParams` + `registerStaticParams("blog/[slug]", …)`
      → `#[page("blog/[slug]", paths: allPosts)]`; `generateMetadata` → `head: postHead`;
      `acceptance.md`'s rows (122, 126) name the decorator arguments

#### Step 9 — no segment configuration (decision 290) (was `53-onze-example-app` s9)

- [ ] `registerSegmentConfig` gone from the examples (`app/page.bpp`, `app-page-example.bp`,
      `app/blog/[slug]/page.bpp`, `blog-slug-page-example.bp` — rewritten with 290);
      `acceptance.md` row 60 names `#[page("blog/[slug]", revalidate: hours(1), dynamicParams: true)]`;
      the home page prerendered by its hooks alone

#### Step 10 — route parameters and page data are hooks (decision 293) (was `53-onze-example-app` s10)

- [ ] `app-page-example.bp`, `app-tree-example.bp`, `blog-list-page-example.bp`, `blog-slug-page-example.bp`, `new-post-form-example.bp`, `acceptance.md`: pages take no `route: PageContext` (`fn() -> View`, 276); parameters through `use params<P>()`, page data through `use pageData<D>()`
- [ ] `app/blog/[slug]/page.bpp`: `params` no longer bound by the bracket segment — the header reads
      `use params<P>()` (`P` with a `slug: string` field)

#### Step 11 — a cookie is declared once, typed (decision 294) (was `53-onze-example-app` s11)

- [ ] `lib/cookies.bp` declares `sessionCookie = Cookie<SessionId>("session", …)`; the dashboard
      layout reads `use cookieValue(sessionCookie)` (no `pairValue(jar, "session")`), the login action
      and the logout action write and clear it with `use cookieSetter` / `use cookieReset` (295)

#### Step 12 — emilia through `#[emilia(…)]` (decisions 301, 369) (was `53-onze-example-app` s12)

- [ ] every `class={emilia(xTokens())}` in the examples (`post_card.bpp`, the layouts, `error.bpp`,
      `not-found.bpp`, the blog pages) becomes `#[emilia(…)]` with the tokens inline; the `fn
      xTokens() -> Token[]` helpers go; `classList(["onze-font-inter", emilia(…)])` becomes
      `class="onze-font-inter" #[emilia(…)]` (369: emilia has no run-time entry point)

**Gate:** standard (fronts.md § Gate) +
- [ ] `zig build test-libs` green for `blog`, `onze-test`; `serve.sh` exit 0

#### Step 3 — static generation and metadata (was `53-acceptance` s3)

`generateStaticParams` and `generateMetadata` on `app/blog/[slug]/page.bp`.

- [ ] `onze build` prerenders `/blog/<slug>` for each of the three posts and no others
- [ ] A prerendered post served without invoking the page fn — counter in `lib/db.bp`
- [ ] `generateMetadata` produces `<title>` and the OG tags for the post, not for the blog index
- [ ] `/blog/<slug>`'s metadata merges with the root layout's, not replacing it

#### Step 4 — streaming and boundaries (was `53-acceptance` s4)

`app/loading.bp`, `app/error.bp`, `app/blog/loading.bp`, `app/blog/[slug]/loading.bp`.

- [ ] A deliberately slow `loadPosts` flushes the shell and the fallback before the list
- [ ] A throwing page renders `app/error.bp`, status 500, response contains the digest, not the
      message

#### Step 5 — the write path (was `53-acceptance` s5)

`app/dashboard/posts/new/page.bp`, `lib/actions.bp`, `middleware.bp`.

- [ ] `/dashboard` with no session cookie redirects to `/login` from the middleware, before the
      layout runs
- [ ] New-post form with an empty title re-renders with the message beside the field, creates
      nothing
- [ ] A valid form writes the file; the next `/blog` request shows the new post — fails if
      `revalidateTag("posts")` did not reach the store `loadPosts` reads
- [ ] Form works with scripting disabled: plain POST, full re-render, same outcome
- [ ] Action request with `Origin` not matching `Host` rejected with 403

#### Step 6 — the client half (was `53-acceptance` s6)

`components/like_button.bp`, `components/nav.bp`.

- [ ] Like button click increments without a request — hook live, so hydration happened
- [ ] `Link` navigation between `/blog` and `/blog/<slug>` does not re-request the document; blog
      layout not remounted

#### Step 7 — the gate (was `53-acceptance` s7)

- [ ] `onze dev` serves every route in the acceptance script
- [ ] `onze build && onze start` serves the same bytes for every static route
- [ ] Every `// front NN` comment in the app names an existing front delivering what it says —
      checked by a script, not by reading

#### Definition of done (was `53-acceptance` definition of done)

- [ ] Every acceptance-script file exists; every row's *Proves* is a green assertion
- [ ] `onze dev` and `onze build && onze start` both serve every route
- [ ] *Assumed API shapes* reconciled against each owning front; every row matches or was changed
      here
- [ ] Every `// front NN` comment names a front that exists (a directory under `specs/1.0.12-beta/`)
- [ ] Every `// LANGUAGE GAP` marker in `examples/blog/**` is a row of
      `specs/1.0.12-beta/language-gaps.md` § Marker index (CI check 5, `scripts/language-gap-markers.sh`)
- [ ] Front's tests green on its assigned target — both, here

### 162 s10 — the E2E runner (135 s5, before 162 s9's steps 2–6)

#### Step 5 — onze (390) (was `20-snap` s5)

- [ ] onze-release: the release tree as a path table in `package_test.bp` (§ 8, CONVERT)
- [ ] onze 53's runner: written by `07-onze/53` step 1 in the plain form § 9 gives (no snapshot writers)
- [ ] `repository/onze/AGENTS.md`: the inline literals and the existing `__snapshots__/` (onze-cli
      5, onze-assets 10, onze-og 4, onze-release 5) are the evidence of §§ 50 · 51 · 52 · 70 · 71
      (50 step 8, 51 step 7)

**Gate:** standard (fronts.md § Gate) · no `.snap` recorded that this README does not name

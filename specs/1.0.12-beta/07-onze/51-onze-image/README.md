# Front 51 — onze image, font and image response tail (carries 52 · 70)

**Priority:** low — every box is a tail of a landed feature; blocks no front except 53's OG row ·
**State:** not started
**Depends on:** `04-rakun/22-rakun-file-routing` carrying 25 (route handler registration, step 2)
and 66 (route discovery, step 5) · maintainer `52-a` (step 4) · `07-onze/49` step 6 (the `assets`
/ `og` group files)
**Owns:** `repository/onze/modules/onze-assets/**` (`root.bp`, `botopink.json` included),
`modules/onze-og/**`, `modules/onze-assets/scripts/` (new), `modules/onze-test/src/{assets,og}.bp`
· this directory
**Does not touch:** `modules/onze-server/**` (49 — route line handed to it) ·
`modules/onze-{cli,bundler}/**` (50) · `examples/blog/README.md` (53 — the `remotePatterns`
sentence is a hand-off) · `onze-assets/src/image_handler.bp`'s MIME table (`03/104`, after) ·
`onze-assets/src/{style_module,stylesheet,assets,preprocess,head}.bp` beyond what a test needs

## Goal

One encoder and one rasterizer run per key under concurrency; `/_onze/image` registered;
`NEXTJS-DOCS.md` § 16's prop table walked in `docs.md`; font metrics generated, not transcribed;
OG defaults applied by route discovery; `measure` checked against a rasterizer; `onze-og` reads
std's number parsing.

## Mechanism

- **Today.** `image_handler.bp`'s `imageResponse → ImageOutcome` is pure; its rakun route
  (`#[getRoute("_onze/image")]`, front 25) unregistered; rakun-cache's `rkCacheFlight` unused in
  onze. `font_metrics.bp`'s five rows transcribed (52-a); `localFont` takes a metrics probe nothing
  binds. `card_style.bp`'s `supportedProperties()` lists `margin`, `border`; the README table does
  not. `onze-og/src/svg.bp`, `metrics.bp` each declare a local `intOf` cell. Remote image sources
  pass the allowlist, answer 501.
- **Single flight**: `rkCacheFlight(key, work)` around the encoder call in `image_handler.bp` and
  the render in `onze-og/src/response.bp`; key = the content hash the cache already uses. Route =
  one registration line in `Onze.run`, handed to 49.
- **OG defaults** = rakun 66's route-discovery record: `response.bp` reads `size` / `contentType`
  from discovered exports or `defaultSize()` / `"image/png"`.
- **2 % test**: a fixture string through the rasterizer to SVG with `getBBox`-equivalent metrics
  (rsvg's `--export-id` bounds), compared with `measure`.

## Open

### Step 1 — consume std (97)

- [ ] `svg.bp`, `metrics.bp` use `string.parseInt()` / `parseFloat()`; `grep -n "fn intOf"
      modules/onze-og/src` empty; `og_test.bp` unchanged

### Step 2 — single flight, and the route

- [ ] `image_test.bp`: two concurrent identical requests (two spawned `imageResponse` calls over
      a sleeping stand-in encoder) → one encoder invocation, counted from the stand-in's log
- [ ] `/_onze/image` registration line (front 25's `getRoute` over the handler, erlang) written
      here, handed to 49 for `Onze.run`; `server_test.bp` (49's) serves a resized fixture with
      `Cache-Control: public, max-age=31536000, immutable`
- [ ] remote sources: 501 stays, `docs.md` says so (no fetch without a decision)

### Step 3 — the § 16 prop table

- [ ] `docs.md` § Image holds § 16's table row by row: honoured (`src`, `width`, `height`,
      `alt`, `sizes`, `priority`, `quality`, `fill`, `placeholder`, `style`, `className`,
      `loading`), or out of scope with reason (`loader`, `unoptimized` per image, `overrideSrc`,
      `onLoad`, `onError`, `getImageProps`) — per `../reference-holes.md` § 16
- [ ] `defaultImageConfig().remotePatterns == []` asserted; the blog README sentence handed to 53

### Step 4 — the metrics generator (52-a)

- [ ] `modules/onze-assets/scripts/font-metrics.py` (or `.bp` over `io.process` if `fontTools`
      is invoked as a command) reads a font file, prints one `font_metrics.bp` row; file header
      carries the command, source URLs, date; the five rows re-derived match the transcribed ones
      or those are corrected
- [ ] `localFont`'s probe bound to the same reader over a local file; `font_test.bp` covers a
      fixture `.ttf` (small open font committed under `test/fixtures/`)

### Step 5 — the OG defaults, the 2 % test, one table

- [ ] a route exporting neither `size` nor `contentType` renders 1200×630 PNG via rakun 66's
      discovery; `og_test.bp` asserts through the discovered record
- [ ] `measure` agrees with `rsvg-convert`'s layout of a fixture string within 2 % — runs when
      the rasterizer is installed; hard failure without it only in the gate's environment (a dev
      machine prints the skip reason; `00-gate` decides whether a skip is red)
- [ ] `supportedProperties()` is the one list; `docs.md`'s table generated from it; `margin` and
      `border` in both or neither

### Step 6 — one render per post

- [ ] `og_test.bp`: N concurrent requests for one post spawn one rasterizer process, write one
      file (`rkCacheFlight` around `response.bp`'s render)

### Step 7 — §§ 51 · 52 · 70 of the snapshot map

→ 20-snap (front 135) step 5

## Notes

- `onze-og` keeps parsing the metrics sidecar itself (no `onze-assets` edge).
- Rasterizer stays a port; a NIF opt-in is 71's packaging concern.
- Nothing outside onze moves; step 2's route line lands through 49.

### Step 8 — a role in the decorator, not in an export's name (decision 282)

- [ ] the OG route's `pub val size` / `pub val contentType` → `#[ogImage(size: ImageSize(1200, 630),
      type: .Svg)] pub fn image(…)`; rakun 66's discovery reads the decorator's meta, not export names;
      no decorator argument = the 1200×630 PNG default

**Gate:** standard (fronts.md § Gate) +
- [ ] `zig build test-libs` — `onze-assets` at its counts or above (image 8, font 7, styling 13)
      and `onze-og` 10+, on every target its manifest declares

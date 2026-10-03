# Front 51 — onze image, font and image response tail (carries 52 · 70)

**Priority:** low — every open box is a tail of a landed feature; none blocks another front
except 53's OG row · **State:** not started
**Depends on:** `04-rakun/22-rakun-file-routing` carrying 25 (the route handler registration,
step 2) and 66 (route discovery, step 5) · maintainer `52-a` (step 4), `53-b` (step 7) ·
`07-onze/49` step 6 (the `assets` / `og` group files)
**Owns:** `repository/onze/modules/onze-assets/**` (its `root.bp` and `botopink.json` included),
`modules/onze-og/**`, `modules/onze-assets/scripts/` (new), `modules/onze-test/src/{assets,og}.bp`
· this directory
**Does not touch:** `modules/onze-server/**` (49 — the route registration line is handed to it)
· `modules/onze-{cli,bundler}/**` (50) · `examples/blog/README.md` (53 — the `remotePatterns`
sentence is a hand-off) · `onze-assets/src/image_handler.bp`'s MIME table (`03/104`, after this
front) · `onze-assets/src/{style_module,stylesheet,assets,preprocess,head}.bp` beyond what a test
needs

## Goal

One encoder run and one rasterizer run per key under concurrency; the `/_onze/image` route
registered; `NEXTJS-DOCS.md` § 16's prop table walked in `docs.md`; the font metrics generated,
not transcribed; OG defaults applied by route discovery; `measure` checked against a rasterizer;
`onze-og` reads std's number parsing.

## Mechanism

- **Today.** `image_handler.bp`'s `imageResponse → ImageOutcome` is pure and its rakun route
  (`#[getRoute("_onze/image")]`, front 25) is not registered; rakun-cache's `rkCacheFlight`
  exists and nothing in onze uses it. `font_metrics.bp`'s five rows are transcribed (52-a);
  `localFont` takes a metrics probe that nothing binds. `card_style.bp`'s
  `supportedProperties()` lists `margin` and `border`, which the README table does not.
  `onze-og/src/svg.bp` and `metrics.bp` each declare a local `intOf` cell. Remote image sources
  pass the allowlist and answer 501.
- **Single flight** is `rkCacheFlight(key, work)` around the encoder call in `image_handler.bp`
  and around the render in `onze-og/src/response.bp` — the key is the content hash the cache
  already uses. The route is one registration line in `Onze.run`, handed to 49.
- **OG defaults** are rakun 66's route-discovery record: `response.bp` reads `size` /
  `contentType` from the discovered exports or `defaultSize()` / `"image/png"`.
- **The 2 % test** renders a fixture string through the rasterizer to SVG with
  `getBBox`-equivalent metrics (rsvg's `--export-id` bounds) and compares with `measure`.

## Open

### Step 1 — consume std (97)

- [ ] `svg.bp` and `metrics.bp` use `string.parseInt()` / `parseFloat()`; `grep -n "fn intOf"
      modules/onze-og/src` empty; `og_test.bp` unchanged

### Step 2 — single flight, and the route

- [ ] `image_test.bp`: two concurrent identical requests (two spawned `imageResponse` calls over
      a sleeping stand-in encoder) produce one encoder invocation — the count read from the
      stand-in's log
- [ ] the `/_onze/image` route's registration line (front 25's `getRoute` over the handler,
      erlang) is written in this front and handed to 49 for `Onze.run`; `server_test.bp` (49's)
      serves a resized fixture with `Cache-Control: public, max-age=31536000, immutable`
- [ ] remote sources: the 501 stays and `docs.md` says so (no fetch without a decision)

### Step 3 — the § 16 prop table

- [ ] `docs.md` § Image holds § 16's table row by row: honoured (`src`, `width`, `height`,
      `alt`, `sizes`, `priority`, `quality`, `fill`, `placeholder`, `style`, `className`,
      `loading`), or out of scope with the reason (`loader`, `unoptimized` per image, `overrideSrc`,
      `onLoad`, `onError`, `getImageProps`) — per `../reference-holes.md` § 16
- [ ] `defaultImageConfig().remotePatterns == []` asserted; the sentence for the blog's README
      handed to 53

### Step 4 — the metrics generator (52-a)

- [ ] `modules/onze-assets/scripts/font-metrics.py` (or `.bp` over `io.process` if `fontTools`
      is invoked as a command) reads a font file and prints one `font_metrics.bp` row; the file's
      header carries the command, the source URLs and the date; the five rows re-derived by it
      match the transcribed ones or the transcribed ones are corrected
- [ ] `localFont`'s probe is bound to the same reader over a local file; `font_test.bp` covers
      a fixture `.ttf` (a small open font committed under `test/fixtures/`)

### Step 5 — the OG defaults, the 2 % test, one table

- [ ] a route exporting neither `size` nor `contentType` renders 1200×630 PNG through rakun 66's
      discovery; `og_test.bp` asserts through the discovered record
- [ ] `measure` agrees with `rsvg-convert`'s layout of a fixture string within 2 % — the test
      runs when the rasterizer is installed and is a hard failure otherwise only in the gate's
      environment (a developer machine without it prints the skip reason; `00-gate` decides
      whether a skip is a red)
- [ ] `supportedProperties()` is the one list; `docs.md`'s table is generated from it;
      `margin` and `border` are in both or in neither

### Step 6 — one render per post

- [ ] `og_test.bp`: N concurrent requests for one post spawn one rasterizer process and write
      one file (`rkCacheFlight` around `response.bp`'s render)

### Step 7 — conditional on `53-b` (b): record §§ 51 · 52 · 70 of the map

Map: [`test-snap.md`](./test-snap.md). Struck under (a) or (c).

## Notes

- `onze-og` keeps parsing the metrics sidecar itself (no `onze-assets` edge).
- The rasterizer stays a port; a NIF opt-in is 71's packaging concern.
- Nothing outside onze moves; step 2's route line lands through 49.

**Gate:** standard (fronts.md § Gate) +
- [ ] `zig build test-libs` — `onze-assets` at its counts or above (image 8, font 7, styling 13)
      and `onze-og` 10+, on every target its manifest declares

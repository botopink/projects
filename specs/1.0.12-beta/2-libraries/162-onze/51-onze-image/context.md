# Front 51 — onze image, font and image response tail (carries 52 · 70)

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [162-onze](../README.md): s2 → 162 s3 · s3 → 162 s3 · s4 → 162 s3 · s5 → 162 s3 · s6 → 162 s3 · s8 → 162 s3. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** low — every box is a tail of a landed feature; blocks no front except 53's OG row ·
**State:** step 1 done (onze-wave patch; lands with the coordinator)
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
  not. Remote image sources
  pass the allowlist, answer 501.
- **Single flight**: `rkCacheFlight(key, work)` around the encoder call in `image_handler.bp` and
  the render in `onze-og/src/response.bp`; key = the content hash the cache already uses. Route =
  one registration line in `Onze.run`, handed to 49.
- **OG defaults** = rakun 66's route-discovery record: `response.bp` reads size and type from the
  route's `#[ogImage(…)]` meta (282, step 8) or `defaultSize()` / `"image/png"` — never from
  exports named `size` / `contentType` (today's form).
- **2 % test**: a fixture string through the rasterizer to SVG with `getBBox`-equivalent metrics
  (rsvg's `--export-id` bounds), compared with `measure`.

## Notes

- `onze-og` keeps parsing the metrics sidecar itself (no `onze-assets` edge).
- Rasterizer stays a port; a NIF opt-in is 71's packaging concern.
- Nothing outside onze moves; step 2's route line lands through 49.

# Front 51 — onze image, font and image response (carries 52 · 70)

**Priority:** low — every open box is a tail of a landed feature; none blocks another front
except 53's OG row
**Depends on:** `02-std-and-packaging/97` (step 1) · the `03-rakun` track: `12-rakun-cache`
(`rkCacheFlight`, landed — steps 2 and 6), `22-rakun-file-routing` carrying 25 (the route
handler registration) and 66 (route discovery for the OG defaults) · maintainer `52-a` (step 4)
and `53-b` (step 7) · `00-gate` for the `onze-og commonJS` ledger line
**Owns:** `repository/onze/modules/onze-assets/**` (its `root.bp` and `botopink.json` included:
the lowest-numbered front owning the member in this milestone; 69's items live in 49 and touch
only `onze-server`), `modules/onze-og/**`, `modules/onze-assets/scripts/` (new),
`modules/onze-test/src/{assets,og}.bp` · this directory
**Does not touch:** `modules/onze-server/**` (49 — the route registration lines are handed to it)
· `modules/onze-{cli,bundler}/**` (50) · `examples/blog/README.md` (53 — the `remotePatterns`
sentence is a hand-off) · `onze-assets/src/image_handler.bp:92-99` (the MIME table, `07/104` —
never at the same time) · `onze-assets/src/{style_module,stylesheet,assets,preprocess,head}.bp`
beyond what a test needs (69's, landed)
**Carried from 1.0.10:** `51-onze-image/README.md` § Step 5 box 3, § Definition of done boxes 2–3,
§ Where it stands · `52-onze-font/README.md` § Step 2 / DoD (the generator), § Where it stands
(the local-font probe) · `70-onze-image-response/README.md` § Step 1 box 2, § Step 6 box 2, § Step
7 box 1, § Definition of done box 2, § Where it stands · `test-snap.md` §§ 51 · 52 · 70 (copied
as [`test-snap.md`](./test-snap.md), conditional on 53-b) · `70/examples/og-image-example.bp`
(copied)

---

## Problem

1. Two concurrent identical requests to `/_onze/image` run the encoder twice; rakun-cache's
   `rkCacheFlight` exists and is not used. The same for an OG image: one file per post, but N
   processes under N concurrent requests.
2. The `/_onze/image` handler is a pure outcome (`imageResponse → ImageOutcome`) — its rakun
   route (`#[getRoute("_onze/image")]`, front 25) is not registered in `Onze.run`.
3. `NEXTJS-DOCS.md § 16`'s prop table is not walked: `loader`, `unoptimized`, `overrideSrc`,
   `onLoad` / `onError` are neither honoured nor listed out of scope; the blog's README does not
   say the allowlist is empty.
4. `font_metrics.bp`'s five rows are transcribed (52-a); the generator (`fontTools` over the
   font files) and the date do not exist; `localFont` takes a metrics probe that nothing binds.
5. An OG route exporting neither `size` nor `contentType` gets no default (rakun 66's discovery
   applies them; not wired); `measure` is not checked against a rasterizer's layout; the README's
   supported-property table and `supportedProperties()` differ (`card_style.bp:39` adds `margin`,
   `border`).
6. `onze-og/src/svg.bp:19` and `metrics.bp:12` hand-roll number parsing std now provides.

## Current state

`onze-assets` image 7 tests, font 7, styling 12 — all on both rows; `onze-og` 10 on erlang, one
producing a real PNG when `rsvg-convert` is installed. Remote image sources pass the allowlist and
answer 501.

## Mechanism

Single flight is `rkCacheFlight(key, work)` around the encoder call in `image_handler.bp` and
around the render in `onze-og/src/response.bp` — the key is the content hash the cache already
uses. The route registration is one `page`-like line in `Onze.run`, handed to 49. The OG
defaults are rakun 66's route-discovery record: `response.bp` reads `size` / `contentType` from
the discovered exports or `defaultSize()` / `"image/png"`. The 2 % test renders a fixture string
through the rasterizer to SVG with `getBBox`-equivalent metrics (rsvg's `--export-id` bounds) and
compares with `measure`.

## Steps

### Step 1 — consume std (97)

**Acceptance:**
- [ ] `svg.bp:19` and `metrics.bp:12` use `parseInt` / `parseFloat`; `grep -n "fn parse"
      modules/onze-og/src` empty; `og_test.bp` unchanged

### Step 2 — single flight, and the route

**Acceptance:**
- [ ] `image_test.bp`: two concurrent identical requests (two spawned `imageResponse` calls over
      a sleeping stand-in encoder) produce one encoder invocation — the count read from the
      stand-in's log
- [ ] the `/_onze/image` route's registration line (front 25's `getRoute` over the handler,
      erlang) is written in this front and handed to 49 for `Onze.run`; `server_test.bp` (49's)
      serves a resized fixture with `Cache-Control: public, max-age=31536000, immutable`
- [ ] remote sources: the 501 stays and `docs.md` says so (no fetch without a decision)

### Step 3 — the § 16 prop table

**Acceptance:**
- [ ] `docs.md` § Image holds § 16's table row by row: honoured (`src`, `width`, `height`,
      `alt`, `sizes`, `priority`, `quality`, `fill`, `placeholder`, `style`, `className`,
      `loading`), or out of scope with the reason (`loader`, `unoptimized` per image, `overrideSrc`,
      `onLoad`, `onError`, `getImageProps`) — per `../reference-holes.md` § 16
- [ ] `defaultImageConfig().remotePatterns == []` asserted; the sentence for the blog's README
      handed to 53

### Step 4 — the metrics generator (52-a)

**Acceptance:**
- [ ] `modules/onze-assets/scripts/font-metrics.py` (or `.bp` over `io.process` if `fontTools`
      is invoked as a command) reads a font file and prints one `font_metrics.bp` row; the file's
      header carries the command, the source URLs and the date; the five rows re-derived by it
      match the transcribed ones or the transcribed ones are corrected
- [ ] `localFont`'s probe is bound to the same reader over a local file; `font_test.bp` covers
      a fixture `.ttf` (a small open font committed under `test/fixtures/`)

### Step 5 — the OG defaults, the 2 % test, one table

**Acceptance:**
- [ ] a route exporting neither `size` nor `contentType` renders 1200×630 PNG through rakun 66's
      discovery; `og_test.bp` asserts through the discovered record
- [ ] `measure` agrees with `rsvg-convert`'s layout of a fixture string within 2 % — the test
      runs when the rasterizer is installed and is a hard failure otherwise only in the gate's
      environment (the gate installs it; a developer machine without it prints the skip reason —
      `00-gate` decides whether a skip is a red)
- [ ] `supportedProperties()` is the one list; this README's table is generated from it in
      `docs.md`; `card_style.bp:39`'s `margin` and `border` are in both or in neither

### Step 6 — one render per post

**Acceptance:**
- [ ] `og_test.bp`: N concurrent requests for one post spawn one rasterizer process and write
      one file (`rkCacheFlight` around `response.bp`'s render)

### Step 7 — conditional on `53-b` (b): record §§ 51 · 52 · 70 of the map

Struck under (a) or (c).

## Gate

- [ ] `zig build test-libs` — `onze-assets` at its counts or above on both rows; `onze-og` 10+
      on erlang (commonJS per the ledger)
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Commit on `fix/51-onze-image`; no push, no merge — landing is the maintainer's step

## Blast radius

None outside onze. Step 2's route line lands through 49.

## Notes

- `onze-og` keeps parsing the metrics sidecar itself (no `onze-assets` edge) — the 1.0.10
  choice stands.
- The rasterizer stays a port; the NIF opt-in is 71's packaging concern.

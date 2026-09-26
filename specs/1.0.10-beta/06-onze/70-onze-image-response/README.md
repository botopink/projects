# Front 70 — onze Image Response

**Track:** E onze
**Priority:** low — without it `opengraph-image` can only be a static file and every post of a blog
shares one social card. Visible, not structural; and it is the one front in track E with a genuine
external dependency
**Target:** erlang (server) — the element-tree→SVG half is pure botopink on BEAM; only SVG→PNG leaves
the VM
**Wave:** 9
**Depends on:** 66 (which registers `opengraph-image.bp` as a route) · 32 (the metadata that links the
card's URL) · 52 (the font files, and the metrics sidecar this front measures with) · 12 (cache — a
card is rendered once per content hash) · 03 (that content hash) · 49 (`Params`, `RouteContext`) ·
01 (`io.process.run`, `io.fs`, `path`)
**Owns:** `repository/onze/modules/onze-og/src/**`, `repository/onze/modules/onze-og/test/**`
**Does not touch:** `repository/onze/modules/onze-assets/src/image.bp` (front 51 — the `Image` component and the
optimizer, a different front for a different problem), `repository/onze/modules/onze-assets/**`
(front 69), `repository/jhonstart/**`, `repository/emilia/**`
**Reference:** `NEXTJS-DOCS.md § 18. Metadata e OG Images` (OG Images dinâmicas — ImageResponse ·
Metadata Files) ·
<https://nextjs.org/docs/app/api-reference/functions/image-response> ·
<https://nextjs.org/docs/app/api-reference/file-conventions/metadata/opengraph-image> ·
<https://github.com/vercel/satori>

---

## Problem

`NEXTJS-DOCS.md § 18` ends with `ImageResponse`: a route file that returns an image built from a
component tree, so every post gets a social card with its own title. `§ 18`'s *Metadata Files* table
lists `opengraph-image.{jpg,png}` as the static alternative, and static is all this ecosystem can do —
front 66 can register the route, front 32 can link it, and nothing can produce the bytes.

The honest version of the problem is that **BEAM cannot rasterize**. There is no Erlang library that
lays out text and draws glyphs, and writing one is not a front, it is a project. Anything that claims
otherwise is claiming to have written a text-shaping engine. What BEAM *can* do is the part that is
actually hard to get right in JavaScript: turn a tree of elements and styles into an SVG document,
deterministically, with no browser. Upstream splits the same way — satori does tree→SVG, resvg does
SVG→PNG — so this front splits there too and is explicit about which half leaves the VM.

## Current state

- `repository/onze/modules/` does not exist; this front creates `modules/onze-og/` inside it.
- Nothing in the workspace emits SVG, measures text, or spawns a rendering process.
- `repository/jhonstart/modules/jhonstart/src/element.bp` — `Element(tag, value, children, attrs)`
  and `renderToString`, which emits HTML. An OG card is a different serialization of
  the same tree, which is why this front takes an `Element` and not a private structure.
- `repository/emilia/modules/emilia/src/emilia.bp` — `emilia(tokens)` returns a class name, and a class name is
  useless in an SVG: SVG has no stylesheet the crawler will fetch. This front reads a **style record**,
  not a class, and that is a deliberate divergence stated in *Mechanism*.
- Front 01 records that there is **no byte or binary type** in botopink. That single fact shapes this
  whole front: a PNG cannot be a value here.

## Mechanism

### The route surface

An image route is a module with two values and one function, mirroring `§ 18` exactly:

```bp
pub val size: ImageSize = ImageSize(width: 1200, height: 630);
pub val contentType: string = "image/png";

pub fn image(ctx: RouteContext) -> @Task<ImageResponse>
```

Front 66 discovers the file and registers the route; this front owns what `image` returns and how it
becomes a response. `ImageResponse` carries the tree, the size, the content type and the fonts it
needs — not bytes, because there are none to carry.

### Tree → SVG, entirely on BEAM

The input is an `Element` tree whose `attrs` carry a style string, and the output is an SVG document.
Three passes, all pure botopink, all testable without any external tool:

1. **Parse styles.** `parseStyle(attrValue) -> Style` turns `display:flex;padding:48px;…` into a
   record. The supported property set is closed and listed below; an unknown property is dropped and
   reported once at build time, never silently honoured with a guess.
2. **Measure and place.** `layout(tree, box, fonts) -> LayoutBox` computes a position and a size for
   every node, top-down for constraints and bottom-up for intrinsic sizes.
3. **Emit.** `toSvg(layout) -> string` writes `<svg>` with `<rect>`, `<text>`, `<tspan>`, `<image>`
   and `<defs>`/`<linearGradient>`. Every attribute value goes through front 01's `escape.attribute`
   and every text node through `escape.html` — a post title is user input and this is a document.

**The supported subset, stated so it can be refused rather than discovered:**

| Supported | Not supported |
|---|---|
| `display: flex` with `flexDirection` row/column | `display: grid`, `table`, `inline` |
| `justifyContent`, `alignItems`, `gap` | `alignSelf`, `flexWrap`, `order` |
| `position: absolute` with `top`/`right`/`bottom`/`left` | `sticky`, `fixed` |
| `width`, `height`, `padding`, `margin` in `px` and `%` | `em`, `rem`, `vh`, `vw`, `calc()` |
| `background` solid and `linear-gradient(<angle>, a, b)` | radial and conic gradients, images as background |
| `borderRadius`, `border` solid | dashed/dotted borders, per-corner radius |
| `color`, `fontSize`, `fontWeight`, `fontFamily`, `lineHeight`, `textAlign` | `letterSpacing`, `textTransform`, `textShadow` |
| word wrapping at spaces, `maxLines` with an ellipsis | hyphenation, justification, RTL and complex-script shaping |
| `<img>` by absolute file path or `data:` URI | remote URLs — a render must not make a network call |
| `opacity` | `filter`, `boxShadow`, `transform`, `zIndex` beyond document order |

An unsupported property in a card fails the **build**, naming the property and the route, because a
card that silently ignores `boxShadow` is a card whose author thinks they have a shadow.

### Text measurement, and why it needs front 52

Wrapping needs glyph advance widths, and advance widths live in a font file's `hmtx` table.
Botopink cannot read one: there is no byte type. So front 52, which already downloads and fingerprints
the font files, also emits a **metrics sidecar** next to each face — a line-oriented table of
`codepoint|advance` in font units plus `unitsPerEm`, produced by the same external tool that
subsetted the font. This front reads that table with `fs.readText` and measures in pure botopink.

A font used by an image route with no sidecar fails the build, naming the face. The alternative — a
monospace approximation — produces cards whose text overflows on some titles and not others, which is
worse than a refusal because it is intermittent.

### SVG → PNG: name the tool, do not hand-wave

An SVG social card is already valid for most consumers, and `contentType: "image/svg+xml"` needs
nothing external. `image/png` does, and there are exactly two ways to get it:

| Approach | What it is | Cost |
|---|---|---|
| **Port (the default)** | `resvg` (or `rsvg-convert`) invoked through front 01's `process.run`, SVG on stdin, PNG written to a file | one OS process per uncached card; a crash kills the process, not the node |
| **NIF (opt-in)** | a native module linking the same rasterizer, called from the BEAM scheduler | faster and no process spawn; a segfault takes the **whole VM** down, and it needs a compiled artifact per platform, which front 71 then has to ship |

The port is the default and the NIF is a configuration choice a deployment makes deliberately. This
front implements the port and defines the NIF's interface (`rasterize(svg, width, height, outPath)`)
so both sit behind one function. It does not ship a NIF; building one is a native-toolchain project,
and pretending it is a line of configuration is how a "low priority" front eats a milestone.

**If neither is available and a route declares `image/png`, the build fails at that route**, naming
the missing command. It does not fall back to SVG with a PNG content type, and it does not serve a
1×1 placeholder. A broken social card is invisible until somebody shares a link, which is the worst
time to find out.

### Bytes, and where they are not

The rasterizer writes a file; this front returns its path; the HTTP layer streams it from disk. A PNG
is never a botopink value, because there is no type it could have. The same is true of the font files.
This is front 01's byte-type gap and it is the load-bearing constraint of the whole front, not a
footnote.

### Caching

A card is a pure function of its inputs, so it is rendered once. The cache key is front 03's content
hash of `route pattern + params + the SVG document + the font set + the size`, and the entry is the
rasterized file's path, stored through front 12. Hashing the SVG rather than the props means a change
to the template invalidates the card without anyone remembering to bump a version. A crawler hitting
the same URL a hundred times spawns one process.

`@Task` lowers eagerly on erlang, so rendering N cards is sequential
unless it is handed to front 02's task runner over unstarted tasks. This front does not claim
parallelism it does not have; the build-time prerender of every card is where front 02 is worth using
and the README says so rather than implying a future is a thread.

## Steps

### Step 1 — The route surface and `ImageResponse`

```bp
pub type ImageSize(width: i32, height: i32)
pub type FontRef(family: string, weight: i32, path: string, metricsPath: string)
pub type ImageResponse(tree: Element, size: ImageSize, contentType: string, fonts: Array<FontRef>)

pub fn defaultSize() -> ImageSize
pub fn imageResponse(tree: Element, size: ImageSize) -> ImageResponse
```

**Acceptance:**
- [ ] `defaultSize()` is 1200×630 and the default content type is `image/png`, matching `§ 18`
- [ ] A route that exports neither `size` nor `contentType` gets both defaults
- [ ] Whether the exports are `pub val` or `pub fn` is settled with front 32, which has the same
      question for `metadata`, and both fronts use the same answer
- [ ] An `ImageResponse` with no fonts and a tree containing text fails the build naming the route
- [ ] `ImageResponse` carries no bytes — asserted structurally, since there is no byte type to carry

### Step 2 — `parseStyle` and the closed property set

```bp
pub type Style(display: string, flexDirection: string, justifyContent: string, alignItems: string, gap: i32, width: string, height: string, padding: string, background: string, color: string, fontSize: i32, fontWeight: i32, fontFamily: string, lineHeight: i32, textAlign: string, borderRadius: i32, opacity: i32, position: string, top: string, left: string, right: string, bottom: string, maxLines: i32)

pub fn parseStyle(value: string) -> Style
pub fn unsupportedProperties(value: string) -> Array<string>
```

**Acceptance:**
- [ ] Every property in the *Supported* column parses into its field
- [ ] Every property in the *Not supported* column is reported by `unsupportedProperties`
- [ ] A malformed declaration (`padding:`) is reported, not silently zero
- [ ] `parseStyle` is total: it never fails, it reports — so one bad card does not take the build's
      error reporting with it
- [ ] Property order does not change the result

### Step 3 — Layout

```bp
pub type LayoutBox(x: i32, y: i32, width: i32, height: i32, style: Style, text: string, lines: Array<string>, children: Array<LayoutBox>)

pub fn layout(tree: Element, size: ImageSize, fonts: Array<FontMetrics>) -> LayoutBox
pub fn wrapText(text: string, widthPx: i32, metrics: FontMetrics, fontSize: i32, maxLines: i32) -> Array<string>
```

**Acceptance:**
- [ ] A row of two children with `justifyContent: space-between` places the first at the left edge and
      the second flush right
- [ ] A column with `gap: 16` separates siblings by exactly 16
- [ ] `padding` shrinks the content box on all four sides
- [ ] An absolutely positioned child with `top`/`left` ignores flow and its siblings ignore it
- [ ] `wrapText` breaks at spaces, never mid-word, and a single word wider than the box overflows
      rather than being cut — asserted, so the behaviour is chosen instead of accidental
- [ ] `maxLines` truncates with `…` on the last line and the ellipsis fits inside the width
- [ ] Layout is deterministic: the same inputs give the same boxes, asserted on a coordinate literal

### Step 4 — SVG emission

```bp
pub fn toSvg(box: LayoutBox, size: ImageSize, fonts: Array<FontRef>) -> string
```

**Acceptance:**
- [ ] The document opens with `<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630">`
- [ ] A title containing `<script>alert(1)</script>` appears escaped and produces no element —
      asserted, because a post title is user input and this is a document
- [ ] A `linear-gradient` background emits one `<defs><linearGradient>` and references it once
- [ ] Every `<text>` carries an explicit `font-family`, `font-size` and `fill`; nothing inherits from
      a stylesheet that will not exist
- [ ] Two renders of the same tree are byte-identical — the cache key depends on it

### Step 5 — Rasterization

```bp
pub type Rasterizer(kind: string, command: string)

pub fn rasterize(r: Rasterizer, svg: string, size: ImageSize, outPath: string) -> @Task<string>
pub fn requireRasterizer(contentType: string, r: Rasterizer) -> Array<string>
```

**Acceptance:**
- [ ] `contentType: "image/svg+xml"` needs no rasterizer and `requireRasterizer` returns no error
- [ ] `contentType: "image/png"` with `kind: "none"` returns one error naming the route and the
      commands that would satisfy it
- [ ] There is no fallback: no configuration makes a PNG route serve SVG, and a test asserts the
      absence
- [ ] A rasterizer exiting non-zero fails the render with its stderr attached, and the partial file is
      removed
- [ ] The NIF interface is declared with the same signature as the port path, and the module compiles
      with `kind: "nif"` configured and no NIF present — failing at call time, naming it

### Step 6 — Fonts and metrics

```bp
pub type FontMetrics(family: string, weight: i32, unitsPerEm: i32, advances: Array<#(i32, i32)>)

pub fn parseMetrics(text: string) -> FontMetrics
pub fn advanceOf(m: FontMetrics, codepoint: i32) -> i32
pub fn measure(m: FontMetrics, text: string, fontSize: i32) -> i32
```

**Acceptance:**
- [ ] `parseMetrics` reads front 52's sidecar format, including `unitsPerEm`
- [ ] `advanceOf` of a codepoint absent from the table returns the face's `.notdef` advance, not zero
- [ ] `measure` of the empty string is 0 and is monotonic in the text's length
- [ ] A font used by an image route with no sidecar fails the build naming the face
- [ ] `measure` agrees with the rasterizer's own layout within 2% on a fixture string — the one test
      that catches a metrics table describing a different font than the one embedded

### Step 7 — Caching

```bp
pub fn cardKey(pattern: string, params: Params, svg: string, fonts: Array<FontRef>, size: ImageSize) -> string
```

**Acceptance:**
- [ ] The same post renders one file and spawns one process, however many times it is requested
- [ ] A change to the template changes the key, without a version bump anywhere
- [ ] A change to the font set changes the key
- [ ] Two different posts do not collide, asserted on a fixture pair

## Examples

- [`examples/og-image-example.bp`](./examples/og-image-example.bp) — a blog post's
  `opengraph-image.bp`: the two exports, the card's tree, and the SVG assertions including the
  escaped-title one.
- [`examples/layout-subset-example.bp`](./examples/layout-subset-example.bp) — what the layout engine
  does and what it refuses, as tests: wrapping, truncation, gaps, and an unsupported property being
  reported rather than honoured.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| No byte or binary type — also recorded by front 01 | the PNG is never a value: the rasterizer writes a file and this front returns a path; font tables are read from a text sidecar instead of the font file | keep binary out of botopink and move it by path | a `bytes` primitive with indexing and a length, plus `fs.readBytes` — which would also delete the metrics sidecar |
| No assignment to a `self` field | `layout` rebuilds each `LayoutBox` rather than positioning nodes in place | return a new record per node | mutable record fields, or a `with` expression |
| Tuple labels are lost through generic instantiation | the metrics table is `Array<#(i32, i32)>` read as `p._0` / `p._1` | read positionally | preserve written labels through instantiation |
| Declared parameter defaults are never applied | `imageResponse` takes the size explicitly even though `§ 18` defaults it | pass every argument; `defaultSize()` supplies the value | apply the declared default at the call site |
| A module-level `pub val` of a user-defined type is **unverified** — no library in the checkout declares one, and `§ 18`'s route surface is two such exports | `pub val size: ImageSize = …` in `examples/og-image-example.bp` | `pub fn size() -> ImageSize`, with front 66 calling rather than reading | confirm or fix `pub val` of a record type at module level; front 32's `metadata` export has the same shape and the same exposure |

## Test plan

`repository/onze/modules/onze-og/test/` — four files, `botopink test --target erlang`, plus
`zig build test-libs`.

| File | What it asserts |
|---|---|
| `style_test.bp` | Every supported property parses; every unsupported one is reported; malformed input is reported and total |
| `layout_test.bp` | Coordinate literals for row, column, gap, padding and absolute placement; wrapping, overflow and `maxLines` truncation; determinism |
| `svg_test.bp` | The document header, the escaped-title case, gradients emitted once, explicit text attributes, byte-identical repeats |
| `rasterize_test.bp` | `requireRasterizer`'s two outcomes, the absence of a fallback, the non-zero-exit path, and the cache key's four sensitivities |

**Erlang only, and everything but one step runs with no external tool.** Steps 1–4, 6 and 7 are pure
functions over strings and records; they are the bulk of the front and they are fully covered offline.
Step 5 is the only one that needs `resvg` on the machine, and `rasterize_test.bp` skips the actual
rasterization when the command is absent while still asserting `requireRasterizer`'s refusals — which
are the part that can be wrong in a way users notice.

The metrics-agreement test (step 6's last item) is the one test that needs both a font and a
rasterizer. It is worth its cost: it is the only thing that catches a sidecar describing a different
font than the one embedded, and that failure looks like "the text sometimes overflows".

## Definition of done

- [ ] `repository/onze/modules/onze-og/` exists with `botopink.json`, `src/root.bp`,
      `src/style.bp`, `src/layout.bp`, `src/svg.bp`, `src/raster.bp`, `src/metrics.bp`
- [ ] The supported-property table in this README is the same list the code refuses against — one
      table, cited by the test, not two lists that drift
- [ ] `image/svg+xml` works with no external tool on a clean machine
- [ ] `image/png` with no rasterizer fails the build naming the route and the commands, with no
      fallback path anywhere in the source
- [ ] Front 66 registers the route and front 32 links the URL; this front formats neither
- [ ] `repository/onze/docs.md` records the rasterizer decision — port by default, NIF opt-in, and
      why — because front 71 has to package whichever one a deployment chose
- [ ] The front's tests are green on its assigned target — `erlang`


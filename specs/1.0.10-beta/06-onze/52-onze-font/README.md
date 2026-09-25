# Front 52 — onze Font

**Track:** E onze
**Priority:** low — a page with an unoptimized webfont still works; it reflows once, leaks the
visitor's IP to a third party, and blocks the first paint, and none of those block another front
**Target:** both, and the halves are named. **erlang (server / build time)** — resolving a family to
font files, downloading and self-hosting them, reading their metrics, generating the `@font-face` and
the metric-adjusted fallback, and emitting the `<link rel="preload">` tags into the document head.
**js (client)** — the behaviour those bytes describe: the browser paints with the adjusted fallback,
swaps to the real face when it arrives, and the swap moves nothing
**Wave:** 8
**Depends on:** 49 (config, `outDir`, `publicDir`), 01 (`process` spawner for the fetch and the
metrics probe, `path`), 03 (content hash for the self-hosted filename), 69 (the asset manifest the files are listed in and
`public/` serving) — the CSS reaches the head through jhonstart's `RenderHooks.headExtra`, which
front 49 fills
**Owns:** `modules/onze-assets/src/font.bp`, `modules/onze-assets/src/font_metrics.bp`, `modules/onze-assets/test/font_test.bp` (the member cut of [`../modules.md`](../modules.md))
**Does not touch:** `repository/onze/modules/onze/**` (F49), `repository/onze/modules/onze-assets/src/root.bp` and its `botopink.json`
(F69 — except the `pub mod font; pub mod font_metrics;` lines, handed to F69), `modules/onze-assets/src/image.bp` (F51),
`repository/emilia/src/**` (track D), every other repository
**Reference:** `NEXTJS-DOCS.md § 17. Otimização de Fontes`, `§ 15. Estilização (CSS)` (where the CSS
lands) · <https://nextjs.org/docs/app/api-reference/components/font> ·
<https://nextjs.org/docs/app/getting-started/fonts>

---

## Problem

A page that loads a webfont the ordinary way does three bad things in one line of CSS. It sends the
visitor's IP address and `User-Agent` to a third-party font host on every page view. It blocks the
first paint on a network round trip to that host. And when the font finally arrives, every line of
text re-measures and the page jumps — a layout shift that arrives after the visitor has started
reading, which is the worst possible moment for one.

`font-display: swap` fixes the blocking and makes the shift worse: now the page paints immediately in
a fallback face with different metrics, and then reflows — that is not "zero layout shift".

Nothing in the workspace addresses fonts at all. `emilia`'s `Font` token section
(`repository/emilia/src/tokens.bp:59-70`) offers `Sans`, `Serif`, `Mono` and five weights — three
generic stacks, no webfont, no `@font-face`, and no mechanism that could produce one, because emilia
emits declarations and a font is a file.

## Current state

Examples use the pre-118 effect annotations; front 24's codemod rewrites them ([`00 · 24-effects-by-return`](../../00-compiler-carry-over/24-effects-by-return/README.md)).

- `repository/onze/src/font.bp` does not exist; `repository/onze/` does not exist until front 49.
- `repository/emilia/src/tokens.bp:59-70` — `Font { Sans, Serif, Mono }` plus
  `Font.Weight { Light, Normal, Medium, Bold, Black }`. These map to generic CSS stacks. This front
  does not extend them and does not need to: a font produced here is applied by its own class name,
  the way `next/font` applies one, and emilia's `Font` section keeps meaning "a generic stack".
- `libs/std/src/fs.bp` reads and writes text, not bytes (`fs.bp:33`, `:42`). A `.woff2` file never
  passes through botopink — see *Mechanism*.
- `libs/std/src/http.bp:55` declares `fetch(url) -> @Future<Response>`; front 01's process spawner is
  what actually pulls the font files, for the reason below.

## Mechanism

### Where the shift actually comes from, and how it is removed

Between first paint and font arrival the browser renders text in a fallback face. If the fallback's
glyphs are a different size, or its ascent and descent differ, every line box has a different height
and every run has a different width. When the real font swaps in, all of that changes at once.

The fix is not to hide the text and it is not `font-display: optional`. It is to make the fallback
occupy the same space as the real font. CSS has four descriptors for exactly this, and they take the
real font's metrics as input:

```css
@font-face {
  font-family: "Inter Fallback";
  src: local("Arial");
  size-adjust: 107.06%;
  ascent-override: 90.44%;
  descent-override: 22.52%;
  line-gap-override: 0.00%;
}
```

`size-adjust` is the ratio of the two fonts' average character widths; the three overrides are the
real font's `hhea`/`OS/2` ascent, descent and line gap divided by its units-per-em. With those set,
the fallback's line boxes and run widths match the real face to within a rounding error, and the swap
is invisible. This front's output is that block plus the real `@font-face`, and the acceptance
criteria are about those numbers, not about "no layout shift" as an adjective.

### Where the metrics come from

Reading them means parsing the `head`, `hhea` and `OS/2` tables out of a binary font file. std has no
binary reader and this front does not add one. Two sources, in order:

1. **A checked-in metrics table** for the Google Fonts families, generated once at library-build time
   and committed as a botopink module. This is what `next/font` does, and it is why a Google font
   needs no tooling on the developer's machine. The table is data: family → per-weight
   `#(unitsPerEm, ascent, descent, lineGap, avgWidth)` plus the recommended local fallback.
2. **An external probe** for a local font, through front 01's process spawner — the same port pattern
   front 51 uses for its encoder. `fc-query` or an equivalent prints the metrics; onze parses the
   text. If the probe is absent, `localFont` still works and emits the `@font-face` without the
   adjusted fallback, logging once that CLS mitigation is off for that family. It does not guess
   metrics, because a wrong `size-adjust` is worse than none.

The font bytes never enter botopink in either case.

### Self-hosting, and why the fetch is a spawn

Google's CSS endpoint returns different `@font-face` blocks per `User-Agent`, and the font files it
points at live on `fonts.gstatic.com`. At build time onze fetches the CSS once with a fixed modern
`User-Agent`, extracts the `woff2` URLs, downloads them, names each by its content hash (front 03),
and writes them under `<outDir>/static/fonts/`. The generated `@font-face` points at those local
paths. Nothing at request time touches Google.

The download is a spawn (`curl`, or the host's equivalent, resolved once) rather than `http.fetch`,
for one reason: `http.fetch` returns a `Response` whose body is a string, and a `.woff2` is not one.
A spawn writes the bytes straight to a file and returns an exit code. Where the js half is doing the
build, the same seam binds to the platform's own fetch-to-file.

### What a font value is

```bp
pub type Font(
    family: string,       // "Inter"
    className: string,    // "onze-font-a1b2c3" — apply this to an element
    variable: string,     // "--font-inter" — or "" when not requested
    css: string,          // @font-face + the adjusted fallback + the class rule
    preload: string,      // <link rel="preload" …> tags, or "" when preload is off
    style: string,        // font-family:"Inter","Inter Fallback",… — for a style attribute
)
```

`className` is a plain class, not an emilia token, and that is deliberate: emilia's `Token` enum is a
closed, comptime-walked surface, and a font family discovered at build time cannot be a variant of it.
An app writes `attrs: [#("class", inter.className)]`, or asks for `variable` and references
`var(--font-inter)` from its own CSS, exactly as `NEXTJS-DOCS.md § 17`'s *Uso com CSS* does.

`css` and `preload` reach the document head through jhonstart's `RenderHooks.headExtra`, which front
49 fills at boot; emilia's block reaches the same head through the `jhonstart-emilia` render plugin
(decision 113). The order matters: preload links first, then font CSS, then the component styles, so
the font request starts before the style that will use it is parsed. Within `fontHead` the first two
are this front's; placing the `headExtra` markup ahead of the plugin's `head()` block is jhonstart's
render's (front 30).

`style` is the `font-family` declaration as a plain string, for a `style` attribute when a class is
not applicable (an email template, an SVG `<text>` for front 70); `font_test.bp` asserts it. Variable
fonts (`axes: ["wght"]`, one file for a weight range) are not chartered — `../../deferred.md`.

## Steps

### Step 1 — `googleFont`

```bp
pub type GoogleFontOptions(
    weights: string[],     // ["400", "700"]; [] means the family's default
    styles: string[],      // ["normal"] | ["normal", "italic"]
    subsets: string[],     // ["latin"]
    display: string,       // "swap" | "block" | "fallback" | "optional"
    preload: bool,
    variable: string,      // "--font-inter", or "" for none
    fallback: string[],    // ["system-ui", "sans-serif"]
    adjustFontFallback: bool,
)

#[@future]
pub fn googleFont(family: string, opts: GoogleFontOptions) -> @Future<Font>
```

**Acceptance:**
- [ ] `css` contains one `@font-face` per requested weight × style
- [ ] Every `src:` URL in `css` is a local path under `<outDir>/static/fonts/`; no
      `fonts.googleapis.com` or `fonts.gstatic.com` string survives into the output — asserted by a
      substring check, because this is the privacy property
- [ ] `display` reaches `font-display:` verbatim; `"swap"` is the default and anything outside the
      four values reds
- [ ] `subsets: []` reds, naming the option — an unsubsetted font is a 300 kB font
- [ ] `variable: "--font-inter"` emits a `:root` rule defining it; `variable: ""` emits none
- [ ] `preload: true` emits one `<link rel="preload" as="font" type="font/woff2" crossorigin>` per
      preloaded file; `preload: false` emits `""`
- [ ] A family not in the metrics table with `adjustFontFallback: true` reds naming the family,
      rather than silently emitting an unadjusted fallback

### Step 2 — The adjusted fallback

```bp
pub type FontMetrics(
    unitsPerEm: i32,
    ascent: i32,
    descent: i32,
    lineGap: i32,
    avgCharWidth: i32,
)

pub fn fallbackFace(family: string, localFamily: string, real: FontMetrics, fallback: FontMetrics) -> string
```

**Acceptance:**
- [ ] `fallbackFace` emits `size-adjust`, `ascent-override`, `descent-override` and
      `line-gap-override`, each as a percentage with two decimals
- [ ] `ascent-override` equals `ascent / unitsPerEm` as a percentage — asserted against a
      hand-computed value for Inter, so the formula is pinned, not paraphrased
- [ ] `size-adjust` equals the ratio of the two fonts' `avgCharWidth`, normalized by `unitsPerEm`
- [ ] Identical metrics produce `size-adjust: 100.00%` and three `0.00%`/exact overrides, and the
      generated CSS still parses
- [ ] `adjustFontFallback: false` omits the whole block and the family list falls back to `opts.fallback`

### Step 3 — `localFont`

```bp
pub type LocalFontSource(
    path: string,     // "./fonts/Brand-Bold.woff2", relative to the module
    weight: string,
    style: string,
)

pub type LocalFontOptions(
    sources: LocalFontSource[],
    display: string,
    preload: bool,
    variable: string,
    fallback: string[],
    adjustFontFallback: bool,
)

#[@future]
pub fn localFont(family: string, opts: LocalFontOptions) -> @Future<Font>
```

**Acceptance:**
- [ ] Each source file is copied to `<outDir>/static/fonts/` under its content hash and referenced
      from there
- [ ] A source path that normalizes outside the project root reds, naming the path
- [ ] A missing source file reds naming the file, at build time, not at first request
- [ ] With the metrics probe absent and `adjustFontFallback: true`, the build logs once and emits the
      unadjusted face — and the log names the family, so the degradation is attributable

### Step 4 — Head output

```bp
pub fn fontHead(fonts: Font[]) -> string
```

Concatenates every font's `preload` then every font's `css`, deduplicating identical `@font-face`
blocks so two components asking for the same family emit one.

**Acceptance:**
- [ ] Preload links precede all font CSS in the output
- [ ] Two `Font` values for the same family and weight produce one `@font-face`
- [ ] The output is a string `headExtra` can carry without re-parsing it

## Examples

- [`examples/font-example.bp`](./examples/font-example.bp) — a root layout loading Inter from Google
  and a local brand face, applying one by class and one by CSS variable.
- [`examples/font-fallback-example.bp`](./examples/font-fallback-example.bp) — the metric-adjusted
  fallback as a value: the four descriptors, the numbers they come from, and the identity case.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| Declared parameter defaults are never applied | `GoogleFontOptions` has eight fields and every call writes all eight; `defaultGoogleFontOptions` exists only for that | a `default*` constructor plus `with*` copies | apply the declared default at the call site (ground truth §2.24) |
| `#[@future]` is required on any fn returning `@Future<T>` | `googleFont` and `localFont` (a layout that awaits them is `#[@use] … -> @Component<Element>`, decision 117) | write the marker | infer the effect from the return type |
| No assignment to a `self` field | option records are copied, never mutated | return a new record | mutable record fields |

## Test plan

`test/font_test.bp`, on **both** targets. Everything this front computes is string and arithmetic —
the metrics table is data, the descriptors are division, the CSS is concatenation — so both backends
must produce identical output, and a divergence is a real bug in one of them rather than a platform
difference.

The network and filesystem halves are tested against a fixture: a checked-in copy of one Google CSS
response and one small `.woff2`, so the suite never reaches the network. The spawn seam is exercised
with a command that succeeds and one that fails, asserting the error text carries the command's
stderr.

What it asserts: every acceptance box above; the Inter metrics arithmetic against hand-computed
constants; and the negative substring check for `fonts.gstatic.com`, which is the privacy claim and
therefore the one most worth a test that can fail.

Coverage this front does not have: whether the swap is actually invisible in a browser. That is a
visual property and the test asserts the four descriptors that cause it, not the pixels.

## Definition of done

- [ ] `src/font.bp` and `test/font_test.bp` exist; the `pub mod font;` line is handed to front 49
- [ ] The metrics table is committed, with the script that generated it and the date it was generated
- [ ] No output of this front references a Google host at request time
- [ ] `docs.md` states the probe-absent degradation and names it as a degradation
- [ ] Front 70's README can point at this front for glyph metrics without this front changing shape
- [ ] The front's tests are green on its assigned target — both, here

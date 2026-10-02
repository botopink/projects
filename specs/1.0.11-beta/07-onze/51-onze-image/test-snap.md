# Front 51 — the 1.0.10 snapshot map, `06-onze/test-snap.md` §§ 51 · 52 · 70 (open: see README, conditional on decision 53-b)

## 51 — image · `modules/onze-assets/test/image_test.bp` (both)

```bp
import {assertImage, assertImageSource, assertImageHandler} from "onze-test";
import {ImageProps, ImageConfig, RemotePattern, defaultImageProps, defaultImageConfig, withSizes, withPriority, withFill} from "onze-assets";

test "image: markup ---- lazy card with sizes" {
    val props = withSizes(defaultImageProps("/images/card.jpg", "A card", 640, 480), "(max-width: 768px) 100vw, 50vw");
    try assertImage(@src(), props, defaultImageConfig());
}
```

`modules/onze-assets/test/__snapshots__/image/markup-lazy-card-with-sizes.snap`

```
<img src="/_onze/image?src=%2Fimages%2Fcard.jpg&w=640&q=75&f=webp" alt="A card" width="640" height="480" loading="lazy" decoding="async" sizes="(max-width: 768px) 100vw, 50vw" srcset="/_onze/image?src=%2Fimages%2Fcard.jpg&w=640&q=75&f=webp 640w">
```

```bp
test "image: priority ---- eager hero with the two-candidate srcset" {
    val props = withPriority(defaultImageProps("/images/hero.jpg", "Hero", 1200, 600), true);
    try assertImage(@src(), props, defaultImageConfig());
}
```

`modules/onze-assets/test/__snapshots__/image/priority-eager-hero-with-the-two-candidate-srcset.snap`

```
<img src="/_onze/image?src=%2Fimages%2Fhero.jpg&w=1200&q=75&f=webp" alt="Hero" width="1200" height="600" loading="eager" fetchpriority="high" decoding="async" srcset="/_onze/image?src=%2Fimages%2Fhero.jpg&w=1200&q=75&f=webp 1x, /_onze/image?src=%2Fimages%2Fhero.jpg&w=2048&q=75&f=webp 2x">
```

```bp
test "image: fill ---- the box is reserved by style, not attributes" {
    val props = withFill(defaultImageProps("/images/bg.jpg", "", 0, 0), true);
    try assertImage(@src(), props, defaultImageConfig());
}
```

`modules/onze-assets/test/__snapshots__/image/fill-the-box-is-reserved-by-style-not-attributes.snap`

```
<img src="/_onze/image?src=%2Fimages%2Fbg.jpg&w=3840&q=75&f=webp" alt="" loading="lazy" decoding="async" style="position:absolute;inset:0;width:100%;height:100%;object-fit:cover" srcset="/_onze/image?src=%2Fimages%2Fbg.jpg&w=640&q=75&f=webp 640w, /_onze/image?src=%2Fimages%2Fbg.jpg&w=750&q=75&f=webp 750w, /_onze/image?src=%2Fimages%2Fbg.jpg&w=828&q=75&f=webp 828w, /_onze/image?src=%2Fimages%2Fbg.jpg&w=1080&q=75&f=webp 1080w, /_onze/image?src=%2Fimages%2Fbg.jpg&w=1200&q=75&f=webp 1200w, /_onze/image?src=%2Fimages%2Fbg.jpg&w=1920&q=75&f=webp 1920w, /_onze/image?src=%2Fimages%2Fbg.jpg&w=2048&q=75&f=webp 2048w, /_onze/image?src=%2Fimages%2Fbg.jpg&w=3840&q=75&f=webp 3840w" sizes="100vw">
```

```bp
test "image: sources ---- the allowlist matrix" {
    val cdn = RemotePattern(protocol: "https", hostname: "*.example.com", pathPrefix: "/photos/", port: "");
    val cfg = ImageConfig(remotePatterns: [cdn], formats: ["image/webp"], deviceWidths: [640, 1200], encoder: "vips", encoderTimeoutMs: 5000);
    try assertImageSource(@src(), cfg, [
        "/images/hero.jpg",
        "/images/../../etc/passwd",
        "images/hero.jpg",
        "https://cdn.example.com/photos/a.jpg",
        "https://example.com/photos/a.jpg",
        "https://a.b.example.com/photos/a.jpg",
        "http://cdn.example.com/photos/a.jpg",
        "https://cdn.example.com:8443/photos/a.jpg",
        "https://cdn.example.com/private/a.jpg",
        "https://cdn.example.com/photos/../private/a.jpg",
        "data:image/png;base64,AAAA",
        "file:///etc/passwd",
    ]);
}
```

`modules/onze-assets/test/__snapshots__/image/sources-the-allowlist-matrix.snap`

```
/images/hero.jpg                                   ok        local  public/images/hero.jpg
/images/../../etc/passwd                           refused   local path escapes public/
images/hero.jpg                                    refused   relative path
https://cdn.example.com/photos/a.jpg               ok        remote *.example.com
https://example.com/photos/a.jpg                   refused   host example.com not in remotePatterns
https://a.b.example.com/photos/a.jpg               refused   host a.b.example.com not in remotePatterns
http://cdn.example.com/photos/a.jpg                refused   protocol http (pattern is https)
https://cdn.example.com:8443/photos/a.jpg          refused   port 8443 (pattern is default)
https://cdn.example.com/private/a.jpg              refused   path /private/a.jpg outside /photos/
https://cdn.example.com/photos/../private/a.jpg    refused   path /private/a.jpg outside /photos/
data:image/png;base64,AAAA                         refused   scheme data
file:///etc/passwd                                 refused   scheme file
== defaultImageConfig().remotePatterns
[]  -> https://cdn.example.com/photos/a.jpg refused: host cdn.example.com not in remotePatterns
== hostname "*"
error: remotePatterns[0].hostname "*" is not allowed (refused at config load)
```

```bp
test "image: handler ---- cache hit headers and the 400s" {
    try assertImageHandler(@src(), defaultImageConfig(), [
        "src=%2Fimages%2Fhero.jpg&w=1200&q=75&f=webp",
        "src=%2Fimages%2Fhero.jpg&w=1200&q=75&f=webp",
        "src=%2Fimages%2Fhero.jpg&w=999&q=75&f=webp",
        "src=%2Fimages%2Fhero.jpg&w=1200&q=101&f=webp",
        "src=https%3A%2F%2Fcdn.example.com%2Fa.jpg&w=640&q=75&f=webp",
    ]);
}
```

`modules/onze-assets/test/__snapshots__/image/handler-cache-hit-headers-and-the-400s.snap`

```
encoder: /bin/true (test double)
#1  200  image/webp  Cache-Control: public, max-age=31536000, immutable  ETag: "a91e3c"  encoder invocations: 1
#2  200  image/webp  Cache-Control: public, max-age=31536000, immutable  ETag: "a91e3c"  encoder invocations: 1
#3  400  w=999 is not a configured device width
#4  400  q=101 is outside 1..100
#5  400  host cdn.example.com not in remotePatterns
== cache key
hash(src, w, q, f, encoderVersion)
```

---

## 52 — font · `modules/onze-assets/test/font_test.bp` (both)

```bp
import {assertFontCss, assertFontHead, assertFontRefusals} from "onze-test";
import {GoogleFontOptions, googleFont, Font} from "onze-assets";

fn interOpts() -> GoogleFontOptions {
    return GoogleFontOptions(
        weights: ["400", "700"], styles: ["normal"], subsets: ["latin"], display: "swap",
        preload: true, variable: "--font-inter", fallback: ["system-ui", "sans-serif"], adjustFontFallback: true,
    );
}

test "font: google ---- Inter 400 and 700, latin, swap, adjusted" {
    try assertFontCss(@src(), "Inter", interOpts());
}
```

`modules/onze-assets/test/__snapshots__/font/google-inter-400-and-700-latin-swap-adjusted.snap`

```
== family / className / variable
Inter / onze-font-inter / --font-inter
== css
@font-face{font-family:"Inter";font-style:normal;font-weight:400;font-display:swap;src:url(/_onze/static/b7f2a1/fonts/inter-400.6e1a90.woff2) format("woff2");unicode-range:U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+0304,U+0308,U+0329,U+2000-206F,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD}
@font-face{font-family:"Inter";font-style:normal;font-weight:700;font-display:swap;src:url(/_onze/static/b7f2a1/fonts/inter-700.12c4f7.woff2) format("woff2");unicode-range:U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+0304,U+0308,U+0329,U+2000-206F,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD}
@font-face{font-family:"Inter Fallback";src:local("Arial");size-adjust:107.00%;ascent-override:96.88%;descent-override:24.15%;line-gap-override:0.00%}
:root{--font-inter:"Inter","Inter Fallback",system-ui,sans-serif}
.onze-font-inter{font-family:"Inter","Inter Fallback",system-ui,sans-serif}
== style
font-family:"Inter","Inter Fallback",system-ui,sans-serif
== preload
<link rel="preload" as="font" type="font/woff2" href="/_onze/static/b7f2a1/fonts/inter-400.6e1a90.woff2" crossorigin>
<link rel="preload" as="font" type="font/woff2" href="/_onze/static/b7f2a1/fonts/inter-700.12c4f7.woff2" crossorigin>
== contains fonts.googleapis.com or fonts.gstatic.com
false
== sidecars
.onze/static/b7f2a1/fonts/inter-400.6e1a90.metrics.txt
.onze/static/b7f2a1/fonts/inter-700.12c4f7.metrics.txt
```

```bp
test "font: head ---- preload before faces, one face per family and weight" {
    val inter = await googleFont("Inter", interOpts());
    val again = await googleFont("Inter", interOpts());
    try assertFontHead(@src(), [inter, again]);
}
```

`modules/onze-assets/test/__snapshots__/font/head-preload-before-faces-one-face-per-family-and-weight.snap`

```
<link rel="preload" as="font" type="font/woff2" href="/_onze/static/b7f2a1/fonts/inter-400.6e1a90.woff2" crossorigin>
<link rel="preload" as="font" type="font/woff2" href="/_onze/static/b7f2a1/fonts/inter-700.12c4f7.woff2" crossorigin>
<style>@font-face{font-family:"Inter";font-style:normal;font-weight:400;font-display:swap;src:url(/_onze/static/b7f2a1/fonts/inter-400.6e1a90.woff2) format("woff2");unicode-range:U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+0304,U+0308,U+0329,U+2000-206F,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD}@font-face{font-family:"Inter";font-style:normal;font-weight:700;font-display:swap;src:url(/_onze/static/b7f2a1/fonts/inter-700.12c4f7.woff2) format("woff2");unicode-range:U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+0304,U+0308,U+0329,U+2000-206F,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD}@font-face{font-family:"Inter Fallback";src:local("Arial");size-adjust:107.00%;ascent-override:96.88%;descent-override:24.15%;line-gap-override:0.00%}:root{--font-inter:"Inter","Inter Fallback",system-ui,sans-serif}.onze-font-inter{font-family:"Inter","Inter Fallback",system-ui,sans-serif}</style>
== @font-face count
3
```

```bp
test "font: refusals ---- empty subsets, unknown display, unknown family" {
    val base = interOpts();
    try assertFontRefusals(@src(), [
        #("Inter", GoogleFontOptions(weights: ["400"], styles: ["normal"], subsets: [], display: "swap", preload: false, variable: "", fallback: [], adjustFontFallback: false)),
        #("Inter", GoogleFontOptions(weights: ["400"], styles: ["normal"], subsets: ["latin"], display: "eventually", preload: false, variable: "", fallback: [], adjustFontFallback: false)),
        #("Nonexistent Sans", base),
    ]);
}
```

`modules/onze-assets/test/__snapshots__/font/refusals-empty-subsets-unknown-display-unknown-family.snap`

```
#1 Inter              error: subsets is empty — an unsubsetted font is a 300 kB font
#2 Inter              error: display "eventually" is not one of swap, block, fallback, optional
#3 Nonexistent Sans   error: family "Nonexistent Sans" is not in the metrics table and adjustFontFallback is true
```

---

## 70 — image response · `modules/onze-og/test/` (erlang)

```bp
import {assertStyleParse, assertLayout, assertSvg, assertRasterizer} from "onze-test";
import {Element, div, span, text} from "jhonstart";
import {ImageSize, FontRef, Rasterizer} from "onze-og";

test "og: style ---- supported parse and unsupported report" {
    try assertStyleParse(@src(),
        "display:flex;flexDirection:column;gap:16;padding:48px;background:linear-gradient(90deg,#4f46e5,#7c3aed);fontSize:64px;maxLines:3;boxShadow:0 0 4px #000;transform:rotate(3deg);padding:"
    );
}
```

`modules/onze-og/test/__snapshots__/og/style-supported-parse-and-unsupported-report.snap`

```
display        flex
flexDirection  column
gap            16
padding        48px
background     linear-gradient(90deg,#4f46e5,#7c3aed)
fontSize       64
maxLines       3
unsupported: boxShadow, transform
malformed: "padding:" (empty value)
```

```bp
fn card() -> Element {
    val frame = "display:flex;flexDirection:row;justifyContent:space-between;alignItems:center;width:1200px;height:630px;padding:64px;background:#111827;color:#ffffff";
    return div([
        span([text("Left", attrs: [])], attrs: [#("style", "fontSize:48px;fontFamily:Inter;fontWeight:700")]),
        span([text("Right", attrs: [])], attrs: [#("style", "fontSize:48px;fontFamily:Inter;fontWeight:700")]),
    ], attrs: [#("style", frame)]);
}

test "og: layout ---- row space-between inside 64px padding" {
    try assertLayout(@src(), card(), ImageSize(width: 1200, height: 630));
}
```

`modules/onze-og/test/__snapshots__/og/layout-row-space-between-inside-64px-padding.snap`

```
div    x=0    y=0    w=1200  h=630
  span x=64   y=286  w=100   h=58   lines: Left
  span x=1002 y=286  w=134   h=58   lines: Right
== wrapText("Hydration is a contract, not a hope", 400, Inter/700, 48, 2)
Hydration is a
contract, not a…
== wrapText("Supercalifragilistic", 100, Inter/700, 48, 1)
Supercalifragilistic   (overflows: 1 word wider than the box)
```

```bp
test "og: svg ---- the card, with a hostile title escaped" {
    val inter = FontRef(family: "Inter", weight: 700, path: "public/fonts/inter-700.woff2", metricsPath: "public/fonts/inter-700.metrics.txt");
    val tree = div([
        span([text("<script>alert(1)</script>", attrs: [])], attrs: [#("style", "fontSize:64px;fontFamily:Inter;fontWeight:700;color:#ffffff")]),
    ], attrs: [#("style", "display:flex;width:1200px;height:630px;padding:64px;background:linear-gradient(90deg,#4f46e5,#7c3aed)")]);
    try assertSvg(@src(), tree, ImageSize(width: 1200, height: 630), [inter]);
}
```

`modules/onze-og/test/__snapshots__/og/svg-the-card-with-a-hostile-title-escaped.snap`

```
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630" viewBox="0 0 1200 630"><defs><linearGradient id="g0" gradientTransform="rotate(0)"><stop offset="0" stop-color="#4f46e5"/><stop offset="1" stop-color="#7c3aed"/></linearGradient></defs><rect x="0" y="0" width="1200" height="630" fill="url(#g0)"/><text x="64" y="125" font-family="Inter" font-weight="700" font-size="64" fill="#ffffff">&lt;script&gt;alert(1)&lt;/script&gt;</text></svg>
== second render identical
true
```

```bp
test "og: rasterizer ---- png with no tool fails at the route, svg needs none" {
    try assertRasterizer(@src(), "image/png", Rasterizer(kind: "none", command: ""));
}
```

`modules/onze-og/test/__snapshots__/og/rasterizer-png-with-no-tool-fails-at-the-route-svg-needs-none.snap`

```
image/svg+xml  kind=none   ok
image/png      kind=none   error: route app/blog/[slug]/opengraph-image.bp declares image/png and no rasterizer is available; install resvg or rsvg-convert, or set contentType to image/svg+xml
image/png      kind=nif    error: rasterizer kind "nif" configured and no NIF is loaded
== fallback to svg under a png content type
none (asserted absent)
```

---


# Front 21 — Onze13 Font Optimization

**Referência Next.js:** [Font Optimization](https://nextjs.org/docs/app/getting-started/fonts) · [next/font](https://nextjs.org/docs/app/api-reference/components/font)

**Priority:** low — font optimization prevents layout shift
**Depends on:** F01 (onze13-stand-up)
**Owns:** `repository/onze13/src/font.bp`
**Does not touch:** `onze13/src/config.bp`, `onze13/src/types.bp`, `onze13/src/image.bp`, jhonstart, rakun, emilia

---

## Problem

Fonts cause layout shift (CLS) when they load. Next.js has `next/font` to optimize fonts: preload, self-host, zero layout shift. Onze13 needs an equivalent.

## Current state

- No font optimization in onze13
- Fonts are loaded via CSS `@font-face` or `<link>`
- Layout shift when fonts load

## Mechanism

Create font optimization utilities:
- `googleFont(name, options)` — optimize Google Fonts
- `localFont(options)` — optimize local fonts
- Automatically preload fonts
- Generate `@font-face` with `font-display: swap`
- Inline critical font CSS

```bp
import {googleFont, localFont} from "onze13";

val inter = googleFont("Inter", subsets: ["latin"]);
val myFont = localFont(src: "./fonts/MyFont.woff2");

pub fn RootLayout(children: Element) -> Element {
    return html([
        head([
            style([text(inter.css + myFont.css, attrs: [])], attrs: []),
        ], attrs: []),
        body([
            div([children], attrs: [#("class", inter.className)]),
        ], attrs: []),
    ], attrs: []);
}
```

## Exemplos em bp

### Google Fonts

```bp
import {googleFont} from "onze13";

val inter = googleFont("Inter", subsets: ["latin"]);

pub fn RootLayout(children: Element) -> Element {
    return html([
        head([style([text(inter.css)])]),
        body([div([children], attrs: [#("class", inter.className)])]),
    ], attrs: []);
}
```

### Local Font

```bp
val myFont = localFont(LocalFontOptions(
    src: "./fonts/BrandFont.woff2",
    display: "swap",
));
```

## Steps

### Step 1 — googleFont function

```bp
// src/font.bp
pub type GoogleFontOptions(
    subsets: string[],
    weight: string[],
    style: string[],
    display: string,  // "swap" | "block" | "fallback" | "optional"
)

pub type Font(
    className: string,
    css: string,
    style: string,
)

pub fn googleFont(family: string, options: GoogleFontOptions) -> Font {
    // Generate optimized font CSS
    // Preload font files
    // Return className and CSS
}
```

**Acceptance:**
- [ ] `googleFont` generates optimized CSS
- [ ] Fonts are preloaded
- [ ] `font-display: swap` prevents layout shift

### Step 2 — localFont function

```bp
pub type LocalFontOptions(
    src: string,
    weight: string,
    style: string,
    display: string,
)

pub fn localFont(options: LocalFontOptions) -> Font {
    // Self-host the font
    // Generate @font-face
    // Return className and CSS
}
```

**Acceptance:**
- [ ] `localFont` self-hosts fonts
- [ ] Generates `@font-face` CSS
- [ ] Fonts are preloaded

### Step 3 — Font CSS generation

```bp
pub fn generateFontCss(font: Font) -> string {
    return "@font-face { font-family: '" + font.family + "'; src: url('" + font.src + "'); font-display: swap; }";
}
```

**Acceptance:**
- [ ] CSS includes `font-display: swap`
- [ ] CSS is inlined in `<head>`

### Step 4 — Tests

```bp
test "googleFont generates CSS" {
    val font = googleFont("Inter", GoogleFontOptions(subsets: ["latin"], weight: [], style: [], display: "swap"));
    assert font.css.contains("@font-face");
    assert font.css.contains("font-display:swap");
}
```

**Acceptance:**
- [ ] Tests pass on commonJS + erlang

## Gate

- [ ] `botopink test` green
- [ ] `font.bp` in place
- [ ] Font optimization works end-to-end
- [ ] AGENTS.md updated
- [ ] Commit on `fix/onze13-font-optimization`

## Blast radius

- New file `font.bp`
- No changes to existing onze13 core
- Apps can use font optimization to prevent CLS

## Notes

- Google Fonts are downloaded at build time and self-hosted (privacy + performance).
- Local fonts are copied to `.onze13/fonts/` and served statically.
- Future: variable fonts, font subsetting, preconnect hints.

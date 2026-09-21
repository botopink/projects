# Front 20 — Onze13 Image Optimization

**Referência Next.js:** [Image Optimization](https://nextjs.org/docs/app/getting-started/images) · [Image Component](https://nextjs.org/docs/app/api-reference/components/image)

**Priority:** low — image optimization improves performance
**Depends on:** F01 (onze13-stand-up)
**Owns:** `repository/onze13/src/image.bp`
**Does not touch:** `onze13/src/config.bp`, `onze13/src/types.bp`, jhonstart, rakun, emilia

---

## Problem

Images need to be optimized for web: resized, compressed, lazy-loaded, served in modern formats. Next.js has `<Image>` component. Onze13 needs an equivalent.

## Current state

- No image optimization in onze13
- jhonstart has no `<Image>` component
- Images are served as-is from `public/`

## Mechanism

Create `Image` component that:
- Resizes images on-demand
- Converts to WebP/AVIF
- Lazy loads by default
- Generates responsive sizes

```bp
import {Image} from "onze13";

pub fn Page() -> Element {
    return Image(
        src: "/photos/hero.jpg",
        alt: "Hero image",
        width: 1200,
        height: 600,
        priority: true,  // eager load
    );
}
```

## Exemplos em bp

### Componente Image

```bp
import {Image} from "onze13";

pub fn HeroSection() -> Element {
    return div([
        Image(ImageProps(
            src: "/images/hero.jpg",
            alt: "Hero",
            width: 1200,
            height: 600,
            priority: true,
            quality: 80,
        )),
    ], attrs: []);
}
```

## Steps

### Step 1 — Image component

```bp
// src/image.bp
import {Element} from "jhonstart";

pub type ImageProps(
    src: string,
    alt: string,
    width: i32,
    height: i32,
    priority: bool,
    quality: i32,
    sizes: string,
)

pub fn Image(props: ImageProps) -> Element {
    val optimizedSrc = optimizeImage(props.src, props.width, props.height, props.quality);
    val loading = if (props.priority) "eager" else "lazy";
    return Element(
        tag: "img",
        value: "",
        children: [],
        attrs: [
            #("src", optimizedSrc),
            #("alt", props.alt),
            #("width", props.width.toString()),
            #("height", props.height.toString()),
            #("loading", loading),
            #("decoding", "async"),
        ],
    );
}
```

**Acceptance:**
- [ ] `Image` component compiles
- [ ] Renders `<img>` with optimized src
- [ ] Lazy loads by default

### Step 2 — Image optimization (host runtime)

```bp
// src/image.mjs (sidecar)
import sharp from "sharp";
import fs from "fs";
import path from "path";

export async function optimizeImage(src, width, height, quality) {
    const inputPath = path.join("public", src);
    const outputPath = path.join(".onze13/images", `${src}-${width}x${height}.webp`);
    
    // Check cache
    if (fs.existsSync(outputPath)) return `/_onze13/image?src=${src}&w=${width}&h=${height}`;
    
    // Optimize
    await sharp(inputPath)
        .resize(width, height)
        .webp({ quality })
        .toFile(outputPath);
    
    return `/_onze13/image?src=${src}&w=${width}&h=${height}`;
}
```

**Acceptance:**
- [ ] Images are resized and converted to WebP
- [ ] Optimized images are cached
- [ ] Served via `/_onze13/image` endpoint

### Step 3 — Image endpoint

```bp
// Route handler for optimized images
pub fn GET(request: Request) -> @Future<Response> {
    val src = request.query("src");
    val width = request.query("w").toInt();
    val height = request.query("h").toInt();
    val optimized = await optimizeImage(src, width, height, 80);
    return Response.redirect(optimized);
}
```

**Acceptance:**
- [ ] `/_onze13/image` serves optimized images
- [ ] Caches optimized versions

### Step 4 — Tests

```bp
test "Image component renders img tag" {
    val el = Image(ImageProps(
        src: "/photo.jpg",
        alt: "Photo",
        width: 800,
        height: 600,
        priority: false,
        quality: 80,
        sizes: "",
    ));
    val html = renderToString(el);
    assert html.contains("<img");
    assert html.contains("loading=\"lazy\"");
}
```

**Acceptance:**
- [ ] Tests pass on commonJS + erlang

## Gate

- [ ] `botopink test` green
- [ ] `image.bp` and `image.mjs` in place
- [ ] Image optimization works end-to-end
- [ ] AGENTS.md updated
- [ ] Commit on `fix/onze13-image-optimization`

## Blast radius

- New files `image.bp`, `image.mjs`
- No changes to existing onze13 core
- Apps can use `<Image>` for optimized images

## Notes

- Image optimization requires `sharp` (Node.js) or equivalent on Erlang.
- Optimized images are cached in `.onze13/images/`.
- Future: support for AVIF, blur placeholders, responsive images.

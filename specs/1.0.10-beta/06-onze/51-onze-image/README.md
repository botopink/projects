# Front 51 — onze Image

**Track:** E onze
**Priority:** low — an unoptimized image is slow, not broken; the front is low because nothing else
depends on it, and it is not lower because its remote-image allowlist is a server-side request
forgery control that the app cannot add afterwards
**Target:** both, and the halves are named. **erlang (server)** — the optimizer: path validation, the
allowlist check, the resize/re-encode call, the cache lookup and the `/_onze/image` route handler.
**js (client)** — the lazy behaviour: `loading="lazy"` handed to the browser, the blur placeholder
swapped for the decoded image, and the `sizes`-driven `srcset` selection. The component itself renders
on the server and emits markup both halves agree on
**Wave:** 8
**Depends on:** 49 (config, `publicDir`, `outDir`), 01 (`process` spawner, `path`), 03 (content hash
for the cache key and the asset name), 12 (the cache store the optimized bytes live in), 25 (the route
handler shape), 69 (the asset manifest and `public/` serving)
**Owns:** `modules/onze-assets/src/image.bp`, `modules/onze-assets/src/image_handler.bp`, `modules/onze-assets/test/image_test.bp` (the member cut of [`../modules.md`](../modules.md))
**Does not touch:** `repository/onze/modules/onze/**` (F49), `repository/onze/modules/onze-assets/src/root.bp` and its `botopink.json`
(F69 — except the `pub mod image; pub mod image_handler;` lines, handed to F69), `modules/onze-assets/src/font.bp` (F52),
`repository/onze/modules/onze-og/**` (F70), `repository/jhonstart/src/element.bp` (frozen),
every other repository
**Reference:** `NEXTJS-DOCS.md § 16. Otimização de Imagens`, `§ 28. Configuração (next.config.js)`
(`images.remotePatterns`, `images.formats`) ·
<https://nextjs.org/docs/app/api-reference/components/image> ·
<https://nextjs.org/docs/app/getting-started/images>

---

## Problem

An onze app serves images the way a 1998 site did: the author writes the path, the browser fetches
whatever bytes are on disk, at whatever dimensions the camera produced, in whatever format the author
happened to export. A 4 MB JPEG in a 320-pixel-wide card costs the visitor 4 MB. Nothing reserves the
element's box before the bytes arrive, so the page reflows when they do.

There is a second problem, and it is a security one rather than a performance one. The moment an image
component accepts a remote `src` and fetches it server-side to optimize it, the server will fetch any
URL an attacker can get into a page — including `http://169.254.169.254/` and every internal host the
server can reach. Next.js answers this with `images.remotePatterns` and refuses to optimize a host
that is not listed (`NEXTJS-DOCS.md § 28`). An app cannot add that control afterwards, because by then
the fetch has already happened.

Nothing in the workspace addresses either. `repository/jhonstart/src/element.bp:10-53` has eight
element constructors and `img` is not among them, so there is not even a way to emit an `<img>` tag
through the builder API today.

## Current state

- `repository/onze/src/image.bp` does not exist; `repository/onze/` does not exist until front 49.
- `repository/jhonstart/src/element.bp` is **frozen** for this milestone (`fronts.md`, track C). It
  provides `text, fragment, div, span, p, h1, ul, li` and no `img`. What it does provide is the
  `Element` record itself — `pub type Element(tag, value, children, attrs)` at `element.bp:3-8` — so
  `Element(tag: "img", value: "", children: [], attrs: […])` is a legal, public construction, and that
  is what this front uses. No front adds `img` to jhonstart, and this front does not ask for one.
- `libs/std/src/process.bp:28-62` is introspection only — no spawner. Front 01 adds it.
- `libs/std/src/fs.bp` has `readText`/`writeText`/`stat`, all string-oriented. There is no binary read
  in std and this front does not need one: the bytes never enter botopink (see *Mechanism*).
- `libs/std/src/path.bp:95` has `normalize`, which is what the traversal check is built on.

## Mechanism

### The honest answer about resizing on BEAM

Resizing a JPEG and re-encoding it as WebP is signal processing. The BEAM does not do that, and it
should not: a NIF that runs for more than a millisecond blocks its scheduler, and a NIF that
segfaults on a malformed image file takes the whole node down with it — which is exactly what a
malformed image file is for. There is no pure-Erlang image codec worth shipping.

So the pixels never enter the VM. The approach is **an external encoder invoked through a port**, and
the port is std's process spawner from front 01:

- The encoder is a single external binary, resolved once at startup from a configured name
  (`vips` by default, `magick` and `ffmpeg` accepted) plus `PATH`.
- The optimizer builds an argument vector and spawns it. Input path in, output path out. No image
  bytes cross the botopink/host boundary — only file paths, dimensions, a quality integer and an exit
  code.
- The call happens on a BEAM process dedicated to it, so a slow or hung encoder blocks one request,
  not a scheduler. A timeout kills the port.
- **No NIF.** This is stated as a rule, not a default: a NIF binding to libvips would be faster and
  would make an image-decoder bug a node crash, and the milestone's standing principle is the most
  restrictive option with no knob to get around it.
- If the binary is absent, the optimizer degrades to pass-through — it serves the original bytes at
  the original format and logs once at startup that optimization is off. It does **not** fail the
  build, because an image encoder is an operational dependency and a missing one should not make an
  app unservable. This is the one place in track E where degrade beats fail, and the reason is stated
  so it is arguable rather than assumed.

The same reasoning on the js half is shorter: there, `sharp` or the platform's own codecs are
available, and the same `ImageEncoder` seam is bound to them. The seam exists so the two halves have
one interface, not so the encoder is portable.

### The component

`Image(props)` returns an `Element` with `tag: "img"`, built from the public `Element` record. What it
computes before doing so:

1. **Validate the source.** A `/`-rooted path is local: `path.normalize` it, and refuse it if the
   result escapes `config.publicDir`. An absolute URL is remote: check it against the allowlist below.
   Anything else — a relative path, a `data:` URL, a `file:` URL — is refused, naming the `src`.
2. **Compute the optimized URL.** `/_onze/image?src=<src>&w=<w>&q=<q>&f=<fmt>`, with the parameter
   set hashed by front 03 so the URL is content-addressed and cacheable forever.
3. **Compute `srcset`.** One candidate per configured device width that is ≤ the declared `width`,
   each pointing at the same handler with a different `w`. `sizes` is passed through verbatim; the
   browser picks. When `sizes` is absent and `fill` is off, `srcset` is emitted with the 1× and 2×
   candidates only, because a `sizes`-less responsive `srcset` is a slower way to download the largest
   image.
4. **Reserve the box.** `width` and `height` become attributes, and when `fill` is set they are
   replaced by the absolute-positioning style that makes the element fill its positioned ancestor.
   Either way the box exists before the bytes do, which is the whole layout-shift story.
5. **Decide loading.** `priority: true` emits `loading="eager"` and `fetchpriority="high"`;
   otherwise `loading="lazy"` and `decoding="async"`. An explicit `loading` prop overrides, and
   `priority` with `loading: "lazy"` is an error rather than a silent precedence rule.

### The allowlist is a control, not a convenience

```bp
pub type RemotePattern(
    protocol: string,   // "https" — "http" is legal but must be written
    hostname: string,   // "cdn.example.com", or "*.example.com"
    pathPrefix: string, // "/photos/" — "" means any path under the host
    port: string,       // "" means the protocol default
)
```

The default allowlist is **empty**, so by default every remote `src` is refused and the refusal names
the host. There is no wildcard entry that means "any host": `hostname: "*"` is rejected at config load.
A leading-label wildcard (`*.example.com`) matches exactly one label, not a suffix — so it does not
match `example.com` itself and does not match `a.b.example.com`. The port must match. The path must
start with `pathPrefix` after normalization, and the normalization happens before the comparison so
`/photos/../../etc/passwd` does not pass a `/photos/` prefix check.

A refused remote image does not fall back to fetching it unoptimized. It renders nothing and the
render reports the URL — a silent fallback would turn the control into a delay.

### The route handler

`/_onze/image` is a built-in route carrying front 25's `#[getRoute("_onze/image")]`, registered when `onze`'s own module tree loads rather than from the app's `app/` directory. It takes `src`, `w`, `q` and `f` — no `h`: the height follows the source's aspect ratio at `w`, as `next/image` does, and a height the caller could set independently is a way to request a distorted image — revalidates them against the same rules the component applied
(the component's checks are for the author, the handler's are for the request), looks the result up in
front 12's cache by content hash, and on a miss spawns the encoder and stores the output. The cache key
is the hash of `#(src, w, q, f, encoderVersion)` so an encoder upgrade does not serve stale artifacts.
The encoded files live under `<outDir>/images/<hash>.<ext>` and front 12's store holds the key → path
mapping, so `onze build` clears them with the rest of `<outDir>` and front 71 leaves them out of the
release (they are regenerated on demand).

## Steps

### Step 1 — `ImageProps` and the prop surface

Every prop in `NEXTJS-DOCS.md § 16`'s table is honoured. Botopink applies no declared parameter
defaults (ground truth §2.24), so the record is constructed with every field and `defaultImageProps`
supplies the baseline a caller modifies.

```bp
pub type ImageProps(
    src: string,
    alt: string,
    width: i32,
    height: i32,
    fill: bool,
    sizes: string,          // "" = none
    priority: bool,
    quality: i32,           // 1..100, default 75
    placeholder: string,    // "empty" | "blur"
    blurDataURL: string,    // required when placeholder == "blur"
    loading: string,        // "" = derive from priority, else "lazy" | "eager"
)

pub fn defaultImageProps(src: string, alt: string, width: i32, height: i32) -> ImageProps
```

**Acceptance:**
- [ ] `alt` is not optional and an empty `alt` is legal only when it is written — the record has no
      default, so omitting it is a compile error, which is the accessibility property this buys
- [ ] `quality` outside 1..100 reds, naming the value
- [ ] `placeholder: "blur"` with an empty `blurDataURL` reds
- [ ] `fill: true` with a non-zero `width`/`height` reds — the two layouts are exclusive
- [ ] `priority: true` with `loading: "lazy"` reds

### Step 2 — Source validation and the remote allowlist

```bp
pub type ImageConfig(
    remotePatterns: RemotePattern[],
    formats: string[],          // ["image/webp"] by default; "image/avif" opt-in
    deviceWidths: i32[],        // [640, 750, 828, 1080, 1200, 1920, 2048, 3840]
    encoder: string,            // "vips"
    encoderTimeoutMs: i32,      // 5000
)

#[@result]
pub fn validateSource(cfg: ImageConfig, publicDir: string, src: string) -> @Result<string, string>
```

**Acceptance:**
- [ ] `defaultImageConfig().remotePatterns` is empty, and `validateSource` refuses
      `https://cdn.example.com/a.jpg` against it, naming the host
- [ ] A matching pattern accepts; a pattern differing only in port, protocol or path prefix refuses
- [ ] `*.example.com` matches `cdn.example.com`, refuses `example.com`, refuses `a.b.example.com`
- [ ] `hostname: "*"` is refused at config load, not at request time
- [ ] `/photos/../../../etc/passwd` refuses after normalization, for both the local and the remote path
- [ ] `data:image/png;base64,…` and `file:///etc/passwd` both refuse

### Step 3 — The component

```bp
pub fn Image(props: ImageProps, cfg: ImageConfig, publicDir: string) -> Element
```

**Acceptance:**
- [ ] Renders `<img>` with `src`, `alt`, `width`, `height`, `loading`, `decoding`
- [ ] `priority: true` renders `loading="eager"` and `fetchpriority="high"`
- [ ] Default renders `loading="lazy"` and `decoding="async"`
- [ ] `sizes` present renders a `srcset` with one candidate per `deviceWidths` entry ≤ `width`
- [ ] `sizes` absent renders a two-candidate `srcset` (1× and 2×) and no `sizes` attribute
- [ ] `fill: true` renders no `width`/`height` and a `style` reserving the box
- [ ] `placeholder: "blur"` renders the `blurDataURL` as the initial `src` and the optimized URL in
      `data-src`, which is the attribute front 68's hydration entry swaps
- [ ] A refused `src` renders nothing and the render reports the URL

### Step 4 — The optimizer and its port

```bp
pub type EncodeRequest(
    inputPath: string,
    outputPath: string,
    width: i32,
    quality: i32,
    format: string,
)

#[@future]
pub fn encode(cfg: ImageConfig, req: EncodeRequest) -> @Future<@Result<i32, string>>
```

**Acceptance:**
- [ ] `encode` spawns the configured binary with an argument vector; the input path is passed as an
      argument and never interpolated into a shell string
- [ ] A missing binary returns a named error once at startup and the optimizer switches to
      pass-through; subsequent calls do not re-probe
- [ ] An encoder exceeding `encoderTimeoutMs` is killed and the request returns a timeout error; the
      node stays up, asserted by a test that runs a deliberately slow command
- [ ] A non-zero exit returns the encoder's stderr in the error, truncated
- [ ] No NIF is loaded anywhere in this front — checked by grep in the test plan, not by intention

### Step 5 — The `/_onze/image` handler

```bp
#[@future]
pub fn imageHandler(req: Request, cfg: ImageConfig, publicDir: string) -> @Future<HandlerResponse>
```

**Acceptance:**
- [ ] Re-validates `src` against the allowlist — a URL the component would have refused is refused
      here too, even though the component already checked
- [ ] `w` outside `deviceWidths` and `q` outside 1..100 return 400, not a clamped image
- [ ] A cache hit returns the stored bytes with `Cache-Control: public, max-age=31536000, immutable`
      and the content hash as `ETag`
- [ ] A cache miss encodes once — two concurrent identical requests produce one encoder invocation
- [ ] The response `Content-Type` is the negotiated format from `cfg.formats`, falling back to the
      original when the browser accepts nothing configured

## Examples

- [`examples/image-example.bp`](./examples/image-example.bp) — the component from the app author's
  side: a local hero with `priority`, a lazy card image with `sizes`, and a `fill` image inside a
  positioned box.
- [`examples/image-config-example.bp`](./examples/image-config-example.bp) — the allowlist as a value:
  the empty default refusing a remote host, one pattern admitting a CDN, and the four ways a
  near-miss pattern still refuses.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| Declared parameter defaults are never applied | `ImageProps` has eleven fields and every construction writes all eleven; `defaultImageProps` exists only because of this | a `default*` constructor fn plus `with*` copies | apply the declared default at the call site (ground truth §2.24) |
| No assignment to a `self` field | `withQuality`, `withSizes` return new `ImageProps` values | return a new record | mutable record fields, or a `with` expression |
| `xs[0]` silently drops the index on the BEAM backend | the `deviceWidths` walk in `srcset` generation uses `.at(i)` and `.filter` throughout | `.at(i)` / `.filter` / `.map` | fix the beam lowering (ground truth §8.1) |

## Test plan

`test/image_test.bp`, on **both** targets. The component half is pure string building and must agree
byte-for-byte across backends — that is the cheapest check that the erlang half of onze is real. The
encoder half runs on both too, with the spawned command replaced by `/bin/true` and `/bin/false`
equivalents resolved through the config's `encoder` field, so the tests assert the port protocol and
the failure paths without depending on `vips` being installed.

What it asserts: every acceptance box above; the allowlist matrix as a table-driven test with one row
per refusal reason; and a grep assertion that no `@External` cell in `src/image.bp` names a NIF entry
point, because "we decided not to use a NIF" is worth exactly as much as the test that checks.

Coverage this front does not have: actual pixel output. Whether `vips` produced a valid WebP is
`vips`'s test suite, not this one. The test asserts the arguments, the exit code handling, the cache
key and the response headers.

## Definition of done

- [ ] `src/image.bp` and `test/image_test.bp` exist; the `pub mod image;` line is handed to front 49
- [ ] `defaultImageConfig()` has an empty `remotePatterns`, and the README of the example app says so
- [ ] Every prop in `NEXTJS-DOCS.md § 16`'s table is honoured or explicitly listed as out of scope
- [ ] `docs.md` documents the pass-through degradation and the no-NIF rule
- [ ] The front's tests are green on its assigned target — both, here

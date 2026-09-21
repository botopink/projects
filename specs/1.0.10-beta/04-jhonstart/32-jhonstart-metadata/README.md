# Front 32 — Jhonstart Metadata

**Track:** C jhonstart
**Priority:** medium — a page with no `<title>` and no `og:image` is a page that cannot be shared or found; nothing else breaks without it
**Target:** erlang (server)
**Wave:** 5
**Depends on:** 28 · 01 (escaping) · 26 (`pairValue`, the package's one pair-list decoder) · 66 (metadata file routes, read-only)
**Owns:** `repository/jhonstart/src/metadata.bp`, `repository/jhonstart/test/metadata_test.bp`
**Does not touch:** `src/element.bp`, `src/hooks.bp`, `src/html.bp` (frozen), `src/router.bp` (26), `src/link.bp` (27), `src/server.bp` (28), `src/client.bp` (29), `src/suspense.bp`/`src/streaming.bp` (30), `src/error_boundary.bp` (31), `src/root.bp` and `botopink.json` (front 94)
**Reference:** `NEXTJS-DOCS.md § 18. Metadata e OG Images` · https://nextjs.org/docs/app/getting-started/metadata-and-og-images · https://nextjs.org/docs/app/api-reference/functions/generate-metadata
**Replaces:** `1.0.7-beta/08-jhonstart-metadata`

---

## Problem

`renderToString` renders a tree of elements, and `<head>` is not one of them. `element.bp` ships
eight builders and none is `title`, `meta` or `link` (`element.bp:10-53`), so there is no way for a
page to say what its title is — let alone what its Open Graph image is, or whether the segment it
sits in has already set one.

The absence is not only "no `<title>`". Metadata is the only part of a page whose value is composed
down the layout chain: a root layout sets the site name and the Twitter card type, a section layout
sets the section, and the page sets its own title, and the result is one merged object
(`NEXTJS-DOCS.md § 18`). Nothing in jhonstart composes anything down a chain today; front 23 nests
layouts for *rendering*, but metadata is not markup and does not nest — it merges, with a rule per
field kind.

And metadata is the most common place a site injects unescaped attacker text into markup. A post
title becomes `<meta property="og:title" content="…">`. std has no HTML escaping today at all — that
is one of the seven absences front 01 closes — so a metadata front written before front 01 would
have had to hand-roll it.

## Current state

- No metadata of any kind in `repository/jhonstart/src/`. `root.bp:15-17` declares three modules.
- `element.bp:10-53` — eight builders, none of them a head tag.
- `libs/std/src/` has nineteen modules and **no escaping**. `escape.html` and `escape.attribute` are
  front 01's, new, in pure botopink.
- `pub val` of a primitive is real (`libs/std/src/math.bp:16`, `libs/std/src/path.bp:13`); a `pub val`
  of a user record type is unexercised anywhere in the tree — which decides the export shape below.
- The 1.0.7 draft proposed `pub val metadata: Metadata = Metadata(...)` and a `collectMetadata()`
  host cell. Both are dropped; see *Mechanism*.
- `sitemap`, `robots`, `manifest` and `opengraph-image` are **file routes**, and file routes are
  front 66's (`rakun-metadata-file-routes`). This front owns `generateMetadata` and the head tags it
  emits, and nothing that is addressed by a URL.

## Mechanism

Upstream gives a segment two ways to declare metadata: a static `export const metadata` and an
`export async function generateMetadata(props, parent)` for the case where the values come from data
(`NEXTJS-DOCS.md § 18`). Both produce the same object, and the objects merge down the segment chain.

### Exports are functions, both of them

jhonstart's static form is `pub fn metadata() -> Metadata`, not `pub val metadata: Metadata`. Two
reasons, and the first is enough: a `pub val` of a user record type is not exercised anywhere in the
tree, and a spec should not be the first place a construct is tried. The second is that front 23
resolves a segment's metadata by name, and resolving one name that is always a zero-argument call is
one code path instead of two.

```bp
pub fn metadata() -> Metadata                                  // static
#[@future] pub fn generateMetadata(params, parent) -> @Future<Metadata>   // dynamic
```

A segment may export either. Exporting both is a front-23 error, not a silent precedence rule.

### The record, and the absence convention

```bp
pub type Metadata(
    title: string,
    titleTemplate: string,
    description: string,
    openGraph: OpenGraph,
    twitter: TwitterCard,
    icons: Icons,
)
```

There are no optionals. An absent string is `""` and an absent list is `[]`, the same convention
front 26 and front 28 use for request and route values, and the same one rakun's `Request` uses
(`repository/rakun/src/http.bp:30-34`). `emptyMetadata()` is the constructor a segment starts from,
so a page that only sets a title writes one field's worth of difference and not six of `""`.

### The merge rule

This is the part the 1.0.7 draft did not have, and it is the part with actual semantics. Merging a
child segment's metadata onto its parent's:

| Field kind | Rule | Example |
|---|---|---|
| string | a non-empty child replaces; an empty child inherits | child `title: ""` keeps the parent's title |
| array | a non-empty child replaces **wholesale**; an empty child inherits | one `og:image` on the page replaces the layout's three, it does not append |
| nested record | merged field by field, by the same two rules | `openGraph.title` from the page, `openGraph.siteName` from the layout |
| `titleTemplate` | applied by the parent to the **child's** title, once | parent `"%s | botopink"` + child `"Hello"` → `"Hello | botopink"` |

"Arrays replace, objects merge" is upstream's rule and it is the one people get wrong in the other
direction: appending images is almost never what a page wants, because the page's image is the
specific one.

`titleTemplate` is applied at merge time and is not inherited further down: a template that applied
at every level would compose into `"Hello | Docs | botopink | botopink"`.

### Rendering the head

`renderHead(m) -> string` produces the tags, in a fixed order so that two renders of the same
metadata are byte-identical (which is what makes an ETag over the page worth anything):

```
<title>…</title>
<meta name="description" content="…">
<meta property="og:title" content="…">      … og:description, og:url, og:type, og:image (one per image)
<meta name="twitter:card" content="…">      … twitter:title, twitter:description, twitter:image
<link rel="icon" href="…">                  … apple-touch-icon
```

Every value goes through front 01: `escape.html` for element text, `escape.attribute` for attribute
values. A field that is `""` emits no tag — not an empty one. Front 23 splices the returned string
into the document; this front does not build a document and does not know what one looks like.

The head is markup, not payload. The `__onze` script's own escaping rule — `<`, `>`, `&`, U+2028 and
U+2029, so that `</script` is unrepresentable — is `contracts.md § 2` and front 23's; it does not
apply here and this front must not reimplement it. The two escapings are different problems and
using the wrong one is how a `<title>` ends up with `&amp;lt;` in it.

### `generateViewport`

Viewport and theme colour are a **second** export upstream, not fields of `Metadata`
(`generateViewport`). jhonstart keeps them separate for the same reason: they merge, but they merge
independently, and folding them into `Metadata` would make a page that sets a theme colour inherit a
title template it never asked for.

```bp
pub type Viewport(width: string, initialScale: string, themeColor: string)
pub fn viewport() -> Viewport
#[@future] pub fn generateViewport(params) -> @Future<Viewport>
```

`renderViewport(v) -> string` emits `<meta name="viewport" …>` and `<meta name="theme-color" …>`.

### What this front does not own

`sitemap.bp`, `robots.bp`, `manifest.bp` and `opengraph-image.bp` are file routes: a URL, a handler,
a content type, and for the OG image a rendered PNG. All four are **front 66**'s. What this front
owes front 66 is the `openGraph.images` list, so that a page pointing at `/og/hello.png` and a file
route serving `/og/hello.png` agree; the path convention is written down once, in front 66's README,
and cited here.

## Steps

### Step 1 — The records and `emptyMetadata`

```bp
// src/metadata.bp
import {escape} from "std";

pub type OpenGraph(
    title: string,
    description: string,
    url: string,
    ogType: string,
    siteName: string,
    images: string[],
)

pub type TwitterCard(
    card: string,
    title: string,
    description: string,
    images: string[],
)

pub type Icons(icon: string, apple: string)

pub type Metadata(
    title: string,
    titleTemplate: string,
    description: string,
    openGraph: OpenGraph,
    twitter: TwitterCard,
    icons: Icons,
)

pub fn emptyOpenGraph() -> OpenGraph {
    return OpenGraph(title: "", description: "", url: "", ogType: "", siteName: "", images: []);
}

pub fn emptyMetadata() -> Metadata {
    return Metadata(
        title: "",
        titleTemplate: "",
        description: "",
        openGraph: emptyOpenGraph(),
        twitter: TwitterCard(card: "", title: "", description: "", images: []),
        icons: Icons(icon: "", apple: ""),
    );
}
```

The field is `ogType`, not `type`: `type` is a keyword (`modules/compiler-core/src/lexer.zig:721-767`).

**Acceptance:**
- [ ] `emptyMetadata()` has every string `""` and every list `[]`
- [ ] no field is named with a keyword
- [ ] no field is optional; the absence convention is documented in the file header

### Step 2 — `mergeMetadata`

```bp
pub fn pick(parent: string, child: string) -> string {
    if (child != "") return child;
    return parent;
}

pub fn pickList(parent: string[], child: string[]) -> string[] {
    if (child.length > 0) return child;
    return parent;
}

pub fn applyTemplate(template: string, title: string) -> string {
    if (template == "") return title;
    if (title == "") return "";
    return template.replace("%s", title);
}
```

`mergeMetadata(parent, child)` applies `pick` to each string, `pickList` to each list, merges
`openGraph`, `twitter` and `icons` field by field, and sets `title` to
`applyTemplate(parent.titleTemplate, pick(parent.title, child.title))`. The result's
`titleTemplate` is the **child's**, so it applies to the next level down and not to this one.

**Acceptance:**
- [ ] a child with an empty title inherits the parent's, untemplated
- [ ] a child with a title gets the parent's template applied exactly once
- [ ] a child with one image replaces the parent's three, and the result has length one
- [ ] a child with no images inherits the parent's list unchanged
- [ ] `openGraph.title` from the child and `openGraph.siteName` from the parent survive the same merge
- [ ] merging three levels applies the template once, not twice

### Step 3 — `renderHead`

**Acceptance:**
- [ ] the tag order is the fixed order in *Mechanism*, and two renders of equal metadata are
      byte-identical
- [ ] a `""` field emits no tag at all
- [ ] a title containing `<` is escaped with `escape.html`; a description containing `"` is escaped
      with `escape.attribute`
- [ ] `renderHead(emptyMetadata())` is `""`
- [ ] one `<meta property="og:image">` per image, in list order

### Step 4 — `Viewport`, `renderViewport`, `mergeViewport`

**Acceptance:**
- [ ] `Viewport` is a separate record and a separate export; it is not a field of `Metadata`
- [ ] `mergeViewport` uses the same `pick` rule
- [ ] `renderViewport(Viewport(width: "device-width", initialScale: "1", themeColor: "#0b0b0b"))`
      emits both tags, escaped
- [ ] an empty `Viewport` renders `""`

### Step 5 — The export contract, written down

`repository/jhonstart/docs.md` gains the contract front 23 resolves against:

| Segment export | Kind | Front 23 does |
|---|---|---|
| `metadata()` | static | calls it, merges onto the parent's |
| `generateMetadata(params, parent)` | `#[@future]` | awaits it, merges onto the parent's |
| both present | error | fails the build with a located message |
| `viewport()` / `generateViewport(params)` | as above | merged independently of `Metadata` |

**Acceptance:**
- [ ] the table is in `repository/jhonstart/docs.md` and front 23's README cites it
- [ ] the merge rule table from *Mechanism* is in the same place
- [ ] `pub mod metadata;` and the `metadata.bp` `files` entry are handed to front 94, which owns
      `src/root.bp` and the `files` list; this front edits neither
- [ ] front 66's README cites the `openGraph.images` path convention, and this README links to it
- [ ] `repository/jhonstart/AGENTS.md` updated in the same commit

## Examples

- [`examples/post-metadata-example.bp`](./examples/post-metadata-example.bp) — a blog post's
  `generateMetadata`, the layout's static `metadata()` above it, and the merge of the two.
- [`examples/viewport-example.bp`](./examples/viewport-example.bp) — `generateViewport` for a theme
  colour that follows the reader's saved preference.

## Reference gaps

`generateViewport` does not appear in `/home/ericfillipe/develop/nextjs/NEXTJS-DOCS.md` — zero hits;
the word `viewport` occurs once, as a prefetch trigger in § 8. It is upstream API
(https://nextjs.org/docs/app/api-reference/functions/generate-viewport) and this front implements it
from the upstream page, because theme colour and viewport are the two head tags a mobile site cannot
ship without and neither has a home in `Metadata`.

The title template (`title.template`, `title.default`, `title.absolute`) is also absent from the
local doc's § 18, which shows only a flat `title: string`. This front implements the template form
from https://nextjs.org/docs/app/api-reference/functions/generate-metadata, in the reduced shape
described above: one `titleTemplate` string with a `%s` hole, applied once at merge. `title.absolute`
is not implemented — a child that wants to bypass the template sets `titleTemplate: ""` on its own
segment, which has the same effect with one field instead of three.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| A `pub val` of a user record type is unexercised; only primitive `pub val`s exist in the tree (`libs/std/src/math.bp:16`) | the static export is `pub fn metadata() -> Metadata`, not `pub val metadata: Metadata` | a zero-argument function | verify and document a `pub val` of a record, or say it is not supported |
| No assignment to a `self` field; a record has no copy-with-update | `mergeMetadata` respells all six fields, and `mergeOpenGraph` all six of its own, to change any of them | a merge function per record | a `Record(base, field: value)` copy-update expression |
| Declared parameter defaults are never applied | `emptyMetadata()` exists precisely because a six-field constructor cannot default five of them | a constructor per empty record | apply the declared default when an argument is omitted |

## Test plan

`repository/jhonstart/test/metadata_test.bp`, run by `botopink test --target erlang` from
`repository/jhonstart`, and in the ecosystem gate by
`zig build test-libs -- --target erlang --lib jhonstart`.

Assertions:

1. `emptyMetadata()` — every field empty; `renderHead` of it is `""`.
2. The merge rule, one test per row of the table: string inherit, string replace, list replace
   wholesale, list inherit, nested-record field-by-field, template applied once.
3. A three-level merge (root layout, section layout, page) applying the template exactly once.
4. `renderHead` tag order, byte-identical across two calls.
5. Escaping: a title containing `<script>`, a description containing `"`, an image URL containing
   `&`. Each asserts both that the dangerous form is absent and that the escaped form is present.
6. `renderViewport` both tags, and the empty case.

There is no js row and none is needed: metadata is produced during the server render and reaches the
browser as already-rendered head markup. A client navigation updates the title through front 26's
payload, and asserting that is front 26's and front 68's, not this front's.

## Definition of done

- [ ] `metadata.bp` in the build tree, its `root.bp` and `files` lines handed to front 94
- [ ] the merge rule table is implemented field for field and tested row for row
- [ ] every rendered value passes through front 01's `escape.html` / `escape.attribute`; this front
      hand-rolls no escaping
- [ ] `Viewport` is a separate export and merges independently
- [ ] `sitemap`, `robots`, `manifest` and `opengraph-image` are **not** in this file, and the README
      names front 66
- [ ] the two reference gaps are recorded under *Reference gaps* with their upstream URLs
- [ ] all three language gaps appear in a `specs/1.0.10-beta/` spec
- [ ] the front's tests are green on its assigned target

## Carried from 1.0.7-beta F08 jhonstart-metadata

Items of the 1.0.7 draft not restated above, quoted so nothing is lost; where the milestone decided differently the 1.0.9 decision stands and the old text is kept for the record.

### Static export as `pub val` (1.0.7 F08 README · *Exemplos em bp › Metadata estático*, lines 24-32)

Different decision — *Mechanism › Exports are functions, both of them*: the static form is `pub fn metadata() -> Metadata`; a `pub val` of a user record type is unexercised anywhere in the tree. The draft also built `OpenGraph` with two of its five fields; 1.0.9 has no optionals, so every field is spelled and `emptyOpenGraph()` is the starting point.

```bp
pub val metadata: Metadata = Metadata(
    title: "Sobre Nós",
    description: "Saiba mais sobre nossa empresa.",
    openGraph: OpenGraph(title: "Sobre", images: ["/og.png"]),
);
```

### `generateMetadata(params: Dict<string, string>)` (lines 34-42)

Different decision — `generateMetadata(params, parent)`: `params` is `Array<#(string, string)>` read through front 26's `pairValue`, and the parent's resolved metadata is the second argument (*Mechanism*, Step 5 table).

```bp
#[@future]
pub fn generateMetadata(params: Dict<string, string>) -> @Future<Metadata> {
    val post = await fetchPost(params.get("slug"));
    return Metadata(title: post.title, description: post.excerpt);
}
```

### Both exports in one segment (*Mechanism*, lines 44-74)

Different decision — "A segment may export either. Exporting both is a front-23 error, not a silent precedence rule." The draft's mechanism block exported both from the same `page.bp`. Its three bullets — `metadata` static object exported from `page.bp` or `layout.bp`; `generateMetadata` async for dynamic pages; the SSR pipeline (then F09, now front 23) collects metadata and renders it into `<head>` — are covered above.

```bp
// app/blog/[slug]/page.bp
import {Metadata} from "jhonstart";

pub val metadata: Metadata = Metadata(
    title: "My Blog Post",
    description: "A great blog post",
    openGraph: OpenGraph(
        title: "My Blog Post",
        description: "A great blog post",
        images: ["/og/blog-post.png"],
    ),
);

#[@future]
pub fn generateMetadata(params: Dict<string, string>) -> @Future<Metadata> {
    val slug = params.get("slug");
    val post = await fetchPost(slug);
    return Metadata(
        title: post.title,
        description: post.excerpt,
    );
}
```

### The 1.0.7 record set (*Step 1 — Metadata types*, lines 78-113)

Different decision — `OpenGraph.type` is `ogType` (`type` is a keyword); `OpenGraph.siteName` and `Metadata.titleTemplate` are added. The `TwitterCard.card` value list (`"summary" | "summary_large_image" | "app" | "player"`) is not restated above. Acceptance "All fields are optional (use defaults)" is replaced by the absence convention (`""` / `[]`, `emptyMetadata()`); see also *Language gaps*, declared defaults are never applied.

```bp
// src/metadata.bp
pub type Metadata(
    title: string,
    description: string,
    openGraph: OpenGraph,
    twitter: TwitterCard,
    icons: Icons,
)

pub type OpenGraph(
    title: string,
    description: string,
    images: string[],
    url: string,
    type: string,
)

pub type TwitterCard(
    card: string,    // "summary" | "summary_large_image" | "app" | "player"
    title: string,
    description: string,
    images: string[],
)

pub type Icons(
    icon: string,
    apple: string,
)
```

| Old acceptance | 1.0.9 |
|---|---|
| Metadata types compile | Step 1 |
| All fields are optional (use defaults) | different decision — no optionals; `emptyMetadata()` |

### `collectMetadata()` host cell (*Step 2 — Metadata collection*, lines 115-126)

Different decision — dropped (*Current state*): front 23 resolves the segment export by name and merges it down the chain; there is no host cell and no runtime collection step.

```bp
// During SSR, collect metadata from page/layout exports
#[@External.Node("onze13/runtime", "collectMetadata")]
#[@External.Erlang("onze13_runtime", "collect_metadata")]
declare fn collectMetadata() -> Metadata;
```

| Old acceptance | 1.0.9 |
|---|---|
| Host cells declared for both targets | dropped |
| SSR pipeline can collect metadata | front 23 calls `metadata()` / awaits `generateMetadata(params, parent)` (Step 5 table) |

### `renderMetadataToHtml` (*Step 3 — Render metadata to HTML*, lines 128-146)

Different decision — renamed `renderHead(m) -> string`; a fixed tag order; every value through front 01's `escape.html` / `escape.attribute`. The draft concatenated raw field values. Its two acceptance items (valid HTML; empty/missing fields handled) are Step 3 above.

```bp
pub fn renderMetadataToHtml(metadata: Metadata) -> string {
    var html = "";
    if (metadata.title != "") {
        html = html + "<title>" + metadata.title + "</title>";
    };
    if (metadata.description != "") {
        html = html + "<meta name=\"description\" content=\"" + metadata.description + "\">";
    };
    // ... OG, Twitter, icons
    return html;
}
```

### Tests on both targets (*Step 4 — Tests*, lines 148-165)

Different decision — this front's target is erlang only (*Test plan*: "There is no js row and none is needed"). The draft's acceptance was "Tests pass on commonJS + erlang".

```bp
test "renderMetadataToHtml produces title tag" {
    val meta = Metadata(
        title: "My Page",
        description: "",
        openGraph: OpenGraph(title: "", description: "", images: [], url: "", type: ""),
        twitter: TwitterCard(card: "", title: "", description: "", images: []),
        icons: Icons(icon: "", apple: ""),
    );
    val html = renderMetadataToHtml(meta);
    assert html.contains("<title>My Page</title>");
}
```

### Gate items (lines 167-172)

| Old gate | 1.0.9 |
|---|---|
| `botopink test` green | Definition of done |
| `metadata.bp` in `botopink.json` and `root.bp` | different decision — lines handed to front 94, which owns both files (Step 5) |
| AGENTS.md updated | Step 5 |
| Commit on `fix/jhonstart-metadata` | not restated |

### Reference rows from 1.0.7 overview/fronts

| Source | Row | 1.0.9 |
|---|---|---|
| `overview.md:14` | `08-jhonstart-metadata` · medium · jhonstart · jhonstart-core · "Metadata API: generateMetadata, OG images, SEO tags" | `generateMetadata` and the head tags are here; OG images are file routes, front 66 |
| `overview.md:151` | Next.js `generateMetadata` → `generateMetadata fn` → jhonstart | covered |
| `overview.md:152` | Next.js `ImageResponse (OG)` → "OG image generation" → jhonstart + onze13 | different decision — `opengraph-image` is a file route owned by front 66 (rakun); this front owes it only `openGraph.images` |
| `overview.md:84` | "decorator-based metadata" listed under convention over configuration | different decision — named segment exports `metadata()` / `generateMetadata()`, no decorator |
| `fronts.md:14` | F08 owns `repository/jhonstart/src/metadata.bp`; tests `repository/jhonstart/test/metadata_test.bp` | header **Owns** |
| `fronts.md:76,87` | F08 in Phase 3, parallel with F13 · F16 · F18–F21 | Wave 3 |

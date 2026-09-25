# Front 32 — Jhonstart Metadata

**Track:** C jhonstart
**Priority:** medium — a page with no `<title>` and no `og:image` is a page that cannot be shared or found; nothing else breaks without it
**Target:** erlang (server)
**Wave:** 5
**Depends on:** 28 · 01 (escaping) · 26 (`pairValue`, the package's one pair-list decoder) · 66 (metadata file routes, read-only)
**Owns:** `repository/jhonstart/src/metadata.bp`, `repository/jhonstart/test/metadata_test.bp`
**Does not touch:** `src/element.bp`, `src/hooks.bp`, `src/html.bp` (frozen), `src/router.bp` (26), `src/link.bp` (27), `src/server.bp` (28), `src/client.bp` (29), `src/suspense.bp`/`src/streaming.bp` (30), `src/error_boundary.bp` (31), `src/root.bp` and `botopink.json` (front 94)
**Reference:** `NEXTJS-DOCS.md § 18. Metadata e OG Images` · https://nextjs.org/docs/app/getting-started/metadata-and-og-images · https://nextjs.org/docs/app/api-reference/functions/generate-metadata

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

This is the part with actual semantics. Merging a child segment's metadata onto its parent's:

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

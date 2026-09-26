# Front 32 — Jhonstart Metadata

**Track:** C jhonstart
**Priority:** medium — a page with no `<title>` and no `og:image` is a page that cannot be shared or found; nothing else breaks without it
**Target:** erlang (server); the module is pure and its tests run on both rows
**Wave:** 5
**Depends on:** 28 · 01 (escaping) · 26 (`pairValue`, the package's one pair-list decoder) · 66 (metadata file routes, read-only)
**Owns:** `repository/jhonstart/modules/jhonstart/src/metadata.bp`, `modules/jhonstart/test/metadata_test.bp`
**Reference:** `NEXTJS-DOCS.md § 18. Metadata e OG Images` · https://nextjs.org/docs/app/getting-started/metadata-and-og-images · https://nextjs.org/docs/app/api-reference/functions/generate-metadata

---

## Outcome

A segment declares its metadata; the metadata of the segment chain merges down it with one rule per
field kind (`NEXTJS-DOCS.md § 18`); front 30's document splices the merged result into `<head>` as
escaped markup. `metadata.bp` is pure — no host cell — and hand-rolls no escaping: every value goes
through std's `escape`.

### The surface — `metadata.bp`

```bp
pub type OpenGraph(title: string, description: string, url: string, ogType: string, siteName: string, images: string[])
pub type TwitterCard(card: string, title: string, description: string, images: string[])
pub type Icons(icon: string, apple: string)
pub type Metadata(
    title: string,
    titleTemplate: string,
    description: string,
    openGraph: OpenGraph,
    twitter: TwitterCard,
    icons: Icons,
)
pub type Viewport(width: string, initialScale: string, themeColor: string)

pub fn emptyMetadata() -> Metadata        // also emptyOpenGraph / emptyTwitter / emptyIcons / emptyViewport
pub fn pick(parent: string, child: string) -> string
pub fn pickList(parent: string[], child: string[]) -> string[]
pub fn applyTemplate(template: string, title: string) -> string
pub fn mergeMetadata(parent: Metadata, child: Metadata) -> Metadata   // mergeOpenGraph / mergeTwitter / mergeIcons per record
pub fn mergeViewport(parent: Viewport, child: Viewport) -> Viewport
pub fn renderHead(m: Metadata) -> string
pub fn renderViewport(v: Viewport) -> string
```

There are no optionals: an absent string is `""` and an absent list is `[]`, the convention front 26
and front 28 use, documented in the file header. `emptyMetadata()` is the constructor a segment
starts from. The Open Graph type field is `ogType`, because `type` is a keyword.

### Exports are functions, both of them

| Segment export | Kind | Front 30 does |
|---|---|---|
| `pub fn metadata() -> Metadata` | static | calls it, merges onto the parent's |
| `pub fn generateMetadata(params: Array<#(string, string)>) -> @Task<Metadata>` | dynamic | awaits it, merges onto the parent's |
| both present | error | fails the build with a located message |
| `pub fn viewport() -> Viewport` / `pub fn generateViewport(params: Array<#(string, string)>) -> @Task<Viewport>` | as above | merged independently of `Metadata` |

The static form is a zero-argument function, not a `pub val` of a record: a `pub val` of a user
record type is unexercised in the tree, and resolving one name that is always a call is one code path
instead of two. onze calls `metadata()` / awaits `generateMetadata` per segment and hands the results
to front 30's render in `PageInput.metadata` / `PageInput.viewports`, root-first, the page's last.
This table and the merge rule are in `repository/jhonstart/docs.md` § *Metadata*.

### The merge rule

| Field kind | Rule | Example |
|---|---|---|
| string | a non-empty child replaces; an empty child inherits | child `title: ""` keeps the parent's title |
| array | a non-empty child replaces **wholesale**; an empty child inherits | one `og:image` on the page replaces the layout's three, it does not append |
| nested record | merged field by field, by the same two rules | `openGraph.title` from the page, `openGraph.siteName` from the layout |
| `titleTemplate` | applied by the parent to the **child's** title, once | parent `"%s | botopink"` + child `"Hello"` → `"Hello | botopink"` |

`mergeMetadata(parent, child)` sets `title` to `applyTemplate(parent.titleTemplate,
pick(parent.title, child.title))`; the result's `titleTemplate` is the **child's**, so it applies to
the next level down and not to this one — a template that applied at every level would compose into
`"Hello | Docs | botopink | botopink"`.

### Rendering the head

`renderHead(m)` writes one tag per line in a fixed order, so two renders of the same metadata are
byte-identical:

```
<title>…</title>
<meta name="description" content="…">
<meta property="og:title" content="…">      … og:description, og:url, og:type, og:image (one per image)
<meta name="twitter:card" content="…">      … twitter:title, twitter:description, twitter:image
<link rel="icon" href="…">                  … apple-touch-icon
```

Element text goes through `escape.html`, attribute values through `escape.attribute`. A `""` field
emits no tag; `renderHead(emptyMetadata())` is `""`. `renderViewport(v)` writes
`<meta name="viewport" …>` and `<meta name="theme-color" …>`, and `""` for an empty `Viewport`.
The head is markup, not payload: the payload script's escaping (`contracts.md § 2`, front 30's) does
not apply here, and using the wrong one is how a `<title>` ends up with `&amp;lt;` in it.

`Viewport` is a separate record and export (upstream's `generateViewport`): it merges independently,
so a page that sets a theme colour does not inherit a title template it never asked for.

### What this front does not own

`sitemap.bp`, `robots.bp`, `manifest.bp` and `opengraph-image.bp` are file routes and are all **front
66**'s. What this front owes front 66 is the `openGraph.images` list, so that a page pointing at
`/og/hello.png` and a file route serving `/og/hello.png` agree; the path convention is written once,
in [`66-rakun-metadata-file-routes/README.md`](../../03-rakun/66-rakun-metadata-file-routes/README.md)
§ *Image URLs carry a content hash*.

The markup for those file routes is this front's (decision 116): rakun resolves the icons and images
of a pattern as data (`iconsFor`, `imagesFor`) and builds no HTML; onze copies them into the
segment's `Metadata` (`icons`, `openGraph.images`) before the render, and `renderHead` writes the
tags with its own escaping. jhonstart names no rakun type.

## Delivered

Held by `modules/jhonstart/test/metadata_test.bp` on both rows:

- the records and `emptyMetadata` (every string `""`, every list `[]`, no keyword field, no optional
  field) — Step 1;
- `mergeMetadata`: string inherit and replace, list replace wholesale and inherit, nested records
  field by field, the template applied once over three levels — Step 2;
- `renderHead`: the fixed order, byte-identical renders, no tag for `""`, escaping of `<` in a title
  and `"` in a description, one `og:image` per image in list order — Step 3;
- `Viewport`, `mergeViewport` (the same `pick` rule), `renderViewport` (both tags, escaped; `""` when
  empty) — Step 4;
- `docs.md` § *Metadata* holds the export table and the merge rule; front 66's README carries the
  image path convention; `repository/jhonstart/AGENTS.md` records the module — Step 5.

## Open

Step 5 — the export contract:

- [ ] `pub mod metadata;` and the `metadata.bp` `files` entry are handed to front 94, which owns
      `src/root.bp` and the `files` list; this front edits neither

## Examples

- [`examples/post-metadata-example.bp`](./examples/post-metadata-example.bp) — a blog post's
  `generateMetadata`, the layout's static `metadata()` above it, and the merge of the two.
- [`examples/viewport-example.bp`](./examples/viewport-example.bp) — `generateViewport` for a theme
  colour that follows the reader's saved preference.

## Reference gaps

`generateViewport` does not appear in `/home/ericfillipe/develop/nextjs/NEXTJS-DOCS.md`; the word
`viewport` occurs once, as a prefetch trigger in § 8. It is upstream API
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
| A `pub val` of a user record type is unexercised; only primitive `pub val`s exist in the tree | the static export is `pub fn metadata() -> Metadata`, not `pub val metadata: Metadata` | a zero-argument function | verify and document a `pub val` of a record, or say it is not supported |
| No assignment to a `self` field; a record has no copy-with-update | `mergeMetadata` respells all six fields, and `mergeOpenGraph` all six of its own, to change any of them | a merge function per record | a `Record(base, field: value)` copy-update expression |

Both are rows of `language-gaps.md`.

## Test plan

`modules/jhonstart/test/metadata_test.bp`, run by `botopink test` in `modules/jhonstart/` and by
`zig build test-libs -- --lib jhonstart`: `emptyMetadata()` and its empty head; one test per row of
the merge table; a three-level merge applying the template once; the tag order, byte-identical
across two calls; escaping of a `<script>` title, a `"` description and an `&` image URL, asserting
both that the dangerous form is absent and that the escaped form is present; `renderViewport`'s two
tags and the empty case.

A client navigation updates the title through front 26's payload; asserting that is front 26's and
front 68's, not this front's.

## Definition of done

- [ ] `metadata.bp` in the build tree, its `root.bp` and `files` lines handed to front 94
- [x] the merge rule table is implemented field for field and tested row for row
- [x] every rendered value passes through front 01's `escape.html` / `escape.attribute`; this front
      hand-rolls no escaping
- [x] `Viewport` is a separate export and merges independently — `mergeViewport`
- [x] `sitemap`, `robots`, `manifest` and `opengraph-image` are **not** in this file, and the README
      names front 66
- [x] the two reference gaps are recorded under *Reference gaps* with their upstream URLs
- [x] both language gaps appear in a `specs/1.0.10-beta/` spec
- [x] the front's tests are green on its assigned target — on both rows

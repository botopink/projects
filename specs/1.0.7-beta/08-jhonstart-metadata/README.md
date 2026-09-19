# Front 08 — Jhonstart Metadata

**Referência Next.js:** [Metadata and OG Images](https://nextjs.org/docs/app/getting-started/metadata-and-og-images) · [generateMetadata](https://nextjs.org/docs/app/api-reference/functions/generate-metadata)

**Priority:** medium — metadata is essential for SEO and social sharing
**Depends on:** F04 (jhonstart-server-components)
**Owns:** `repository/jhonstart/src/metadata.bp`
**Does not touch:** `router.bp`, `link.bp`, `server.bp`, `client.bp`, `suspense.bp`, `error_boundary.bp`, `element.bp`, `hooks.bp`

---

## Problem

Pages need metadata (title, description, OG images) for SEO and social sharing. Next.js provides a `metadata` export and `generateMetadata` function. jhonstart needs an equivalent mechanism.

## Current state

- No metadata API in jhonstart
- No way to set `<title>`, `<meta>` tags from components
- `renderToString` only renders the body, not `<head>`

## Exemplos em bp

### Metadata estático

```bp
pub val metadata: Metadata = Metadata(
    title: "Sobre Nós",
    description: "Saiba mais sobre nossa empresa.",
    openGraph: OpenGraph(title: "Sobre", images: ["/og.png"]),
);
```

### Metadata dinâmico

```bp
#[@future]
pub fn generateMetadata(params: Dict<string, string>) -> @Future<Metadata> {
    val post = await fetchPost(params.get("slug"));
    return Metadata(title: post.title, description: post.excerpt);
}
```

## Mechanism

Introduce metadata exports:
- `metadata` — static metadata object exported from `page.bp` or `layout.bp`
- `generateMetadata` — async function that returns metadata (for dynamic pages)
- The SSR pipeline (F09) collects metadata and renders it into `<head>`

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

## Steps

### Step 1 — Metadata types

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

**Acceptance:**
- [ ] Metadata types compile
- [ ] All fields are optional (use defaults)

### Step 2 — Metadata collection

```bp
// During SSR, collect metadata from page/layout exports
#[@External.Node("onze13/runtime", "collectMetadata")]
#[@External.Erlang("onze13_runtime", "collect_metadata")]
declare fn collectMetadata() -> Metadata;
```

**Acceptance:**
- [ ] Host cells declared for both targets
- [ ] SSR pipeline can collect metadata

### Step 3 — Render metadata to HTML

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

**Acceptance:**
- [ ] `renderMetadataToHtml` produces valid HTML
- [ ] Handles empty/missing fields gracefully

### Step 4 — Tests

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

**Acceptance:**
- [ ] Tests pass on commonJS + erlang

## Gate

- [ ] `botopink test` green
- [ ] `metadata.bp` in `botopink.json` and `root.bp`
- [ ] AGENTS.md updated
- [ ] Commit on `fix/jhonstart-metadata`

## Blast radius

- New file `metadata.bp` — no changes to existing files
- Consumers can export metadata from pages/layouts

## Notes

- The SSR pipeline (F09) is responsible for calling `collectMetadata` and injecting it into `<head>`.
- `generateMetadata` is async because it may need to fetch data (e.g., post title from DB).

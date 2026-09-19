# Front 09 — Rakun SSR Pipeline

**Referência Next.js:** [Layouts and Pages](https://nextjs.org/docs/app/getting-started/layouts-and-pages) · [Rendering](https://nextjs.org/docs/app/building-your-application/rendering)

**Priority:** critical — SSR is how pages are rendered on the server
**Depends on:** F14 (rakun-file-routing)
**Owns:** `repository/rakun/src/ssr.bp`, `repository/rakun/src/ssr.mjs`
**Does not touch:** `runtime.bp`, `runtime.mjs`, `decorators.bp`, `http.bp`, `bootstrap.bp`, `file_router.bp`

---

## Problem

Rakun serves API responses (JSON), but doesn't render pages (HTML). The SSR pipeline takes a route, loads the corresponding page component, renders it to HTML (using jhonstart's `renderToString`), collects metadata, and returns a full HTML document.

## Current state

- Rakun's HTTP server returns JSON responses
- No HTML rendering pipeline
- No integration with jhonstart's `renderToString`
- No metadata collection

## Exemplos em bp

### Página SSR completa

```bp
#[@future]
pub fn HomePage() -> @Future<Element> {
    val stats = await fetchStats();
    val styles = await flush();
    return html([
        head([style([text(styles)])]),
        body([
            h1([text("Minha Aplicação")]),
            p([text("Visitantes: " + stats.visitors.toString())]),
        ]),
    ], attrs: []);
}
```

## Mechanism

The SSR pipeline:
1. Receives an HTTP request
2. Matches the route (via file router, F14)
3. Loads the page component (and layouts)
4. Renders the component tree to HTML (`renderToString`)
5. Collects metadata (from page/layout exports)
6. Wraps in a full HTML document (`<html><head>...</head><body>...</body></html>`)
7. Returns the HTML response

```bp
// src/ssr.bp
#[@future]
pub fn renderPage(path: string) -> @Future<string> {
    val route = await matchRoute(path);
    val component = await loadPageComponent(route);
    val html = await renderToString(component);
    val metadata = await collectMetadata(route);
    return wrapInHtmlDocument(html, metadata);
}
```

## Steps

### Step 1 — SSR render function

```bp
// src/ssr.bp
import {Element, renderToString} from "jhonstart";

#[@future]
pub fn renderPageToHtml(path: string) -> @Future<string> {
    // 1. Match route
    val route = await matchRoute(path);
    // 2. Load page component
    val page = await loadPageComponent(route);
    // 3. Render to HTML
    val bodyHtml = renderToString(page);
    // 4. Collect metadata
    val metadata = await collectMetadata(route);
    // 5. Wrap in HTML document
    return wrapInHtmlDocument(bodyHtml, metadata);
}
```

**Acceptance:**
- [ ] `renderPageToHtml` compiles
- [ ] Returns full HTML document

### Step 2 — HTML document wrapper

```bp
pub fn wrapInHtmlDocument(body: string, metadata: Metadata) -> string {
    val headHtml = renderMetadataToHtml(metadata);
    return "<!DOCTYPE html><html><head>" + headHtml + "</head><body>" + body + "</body></html>";
}
```

**Acceptance:**
- [ ] Produces valid HTML5 document
- [ ] Includes metadata in `<head>`

### Step 3 — Host runtime for SSR

```bp
// src/ssr.mjs (sidecar)
import { renderToString } from "jhonstart/element";

export async function renderPage(path) {
    // Match route, load component, render
    const route = matchRoute(path);
    const component = await loadPageComponent(route);
    const html = renderToString(component);
    return html;
}
```

**Acceptance:**
- [ ] `ssr.mjs` sidecar created
- [ ] Exports `renderPage` function

### Step 4 — Integration with HTTP server

Update `bootstrap.bp` to use SSR for HTML requests:

```bp
pub fn run(app: App) {
    val _port = rkServe(app.port, { method, path, headersJson, queryJson, body ->
        // Check if request wants HTML (Accept: text/html)
        val accept = rkGetHeader(headersJson, "accept");
        if (accept.contains("text/html")) {
            // SSR pipeline
            val html = await renderPageToHtml(path);
            return Response(status: 200, body: html);
        } else {
            // API route
            rkDispatchHttp(method, path, headersJson, queryJson, body);
        };
    });
}
```

**Acceptance:**
- [ ] HTML requests go through SSR pipeline
- [ ] API requests go through route handlers

### Step 5 — Tests

```bp
test "wrapInHtmlDocument produces valid HTML" {
    val body = "<div>Hello</div>";
    val meta = Metadata(title: "Test", description: "", ...);
    val html = wrapInHtmlDocument(body, meta);
    assert html.startsWith("<!DOCTYPE html>");
    assert html.contains("<title>Test</title>");
    assert html.contains("<div>Hello</div>");
}
```

**Acceptance:**
- [ ] Tests pass on commonJS + erlang

## Gate

- [ ] `botopink test` green
- [ ] `ssr.bp` and `ssr.mjs` in place
- [ ] Integration with HTTP server works
- [ ] AGENTS.md updated
- [ ] Commit on `fix/rakun-ssr-pipeline`

## Blast radius

- New files `ssr.bp`, `ssr.mjs`
- `bootstrap.bp` updated to route HTML requests through SSR
- No breaking changes to existing API routes

## Notes

- SSR is async because page components may be `#[@future]` (server components that await data).
- The SSR pipeline uses jhonstart's `renderToString` — it doesn't reimplement rendering.
- Metadata collection is a separate step; the pipeline orchestrates it.

# Front 14 — Rakun File Routing

**Referência Next.js:** [Project Structure](https://nextjs.org/docs/app/getting-started/project-structure) · [Dynamic Routes](https://nextjs.org/docs/app/api-reference/file-conventions/dynamic-routes) · [Route Groups](https://nextjs.org/docs/app/api-reference/file-conventions/route-groups) · [Parallel Routes](https://nextjs.org/docs/app/api-reference/file-conventions/parallel-routes)

**Priority:** critical — file-system routing is the foundation of the app directory
**Depends on:** F01 (onze13-stand-up)
**Owns:** `repository/rakun/src/file_router.bp`, `repository/rakun/src/file_router.mjs`
**Does not touch:** `runtime.bp`, `ssr.bp`, `actions.bp`, `middleware.bp`, `route_handler.bp`

---

## Problem

Next.js uses file-system routing: the `app/` directory structure defines routes. Folders are URL segments, `page.bp` is a page, `layout.bp` is a layout, `[slug]` is a dynamic segment, `(group)` is a route group. Rakun needs an equivalent.

## Current state

- Rakun has decorator-based routing (`#[restController]` + `#[getMapping]`)
- No file-system routing convention
- No `app/` directory scanning

## Mechanism

Introduce file-system router:
- Scans `app/` directory at startup
- Maps folder structure to URL paths
- Detects special files: `page.bp`, `layout.bp`, `loading.bp`, `error.bp`, `not-found.bp`, `route.bp`
- Handles dynamic segments `[slug]`, catch-all `[...slug]`, route groups `(group)`

```
app/
├── page.bp                    → /
├── layout.bp                  → root layout
├── blog/
│   ├── page.bp                → /blog
│   ├── layout.bp              → /blog layout
│   └── [slug]/
│       └── page.bp            → /blog/:slug
├── (marketing)/
│   └── about/page.bp          → /about (group ignored in URL)
└── api/
    └── posts/route.bp         → /api/posts (API endpoint)
```

## Exemplos em bp

### Estrutura de arquivos

```
app/
├── layout.bp           → Root layout
├── page.bp             → /
├── blog/
│   ├── layout.bp       → Blog layout
│   ├── page.bp         → /blog
│   └── [slug]/
│       └── page.bp     → /blog/:slug
└── (marketing)/
    └── about/page.bp   → /about
```

### Layout aninhado

```bp
// app/blog/layout.bp
pub fn BlogLayout(children: Element) -> Element {
    return div([
        nav([Link("/blog", [text("Posts")])]),
        div([children]),
    ], attrs: []);
}
```

### Dynamic segment

```bp
// app/blog/[slug]/page.bp
#[@future]
pub fn BlogPost(params: Dict<string, string>) -> @Future<Element> {
    val post = await fetchPost(params.get("slug"));
    return div([h1([text(post.title)])], attrs: []);
}
```

## Steps

### Step 1 — Directory scanner

```bp
// src/file_router.bp
#[@External.Node("rakun/file_router", "scanAppDir")]
#[@External.Erlang("rakun_file_router", "scan_app_dir")]
declare fn scanAppDir(appDir: string) -> RouteNode[];

pub type RouteNode(
    path: string,           // URL path
    filePath: string,       // File system path
    segment: string,        // Folder name
    isDynamic: bool,        // [slug]
    isCatchAll: bool,       // [...slug]
    isGroup: bool,          // (group)
    children: RouteNode[],
    hasPage: bool,
    hasLayout: bool,
    hasLoading: bool,
    hasError: bool,
    hasNotFound: bool,
    hasRoute: bool,
)
```

**Acceptance:**
- [ ] `scanAppDir` scans directory recursively
- [ ] Returns tree of `RouteNode`
- [ ] Detects special files

### Step 2 — Route matching

```bp
pub fn matchRoute(path: string, routes: RouteNode[]) -> ?RouteMatch {
    // Walk the route tree
    // Match static segments exactly
    // Match dynamic segments ([slug]) and capture params
    // Match catch-all ([...slug]) and capture remaining
    // Skip route groups ((group))
}

pub type RouteMatch(
    node: RouteNode,
    params: Dict<string, string>,
)
```

**Acceptance:**
- [ ] Static routes match exactly
- [ ] Dynamic routes capture params
- [ ] Catch-all routes capture remaining segments
- [ ] Route groups are transparent

### Step 3 — Layout nesting

Layouts wrap their children. The root layout wraps everything:

```bp
pub fn renderWithLayouts(node: RouteNode, page: Element) -> Element {
    // Start with the page
    var content = page;
    // Wrap in each layout from root to leaf
    loop (node.layouts) { layout ->
        content = layout(content);
    };
    return content;
}
```

**Acceptance:**
- [ ] Layouts nest correctly
- [ ] Root layout wraps all pages
- [ ] Segment layouts wrap their children

### Step 4 — Host runtime for file scanning

```bp
// src/file_router.mjs (sidecar)
import fs from "fs";
import path from "path";

export function scanAppDir(appDir) {
    const routes = [];
    function scan(dir, node) {
        const files = fs.readdirSync(dir);
        // Detect special files
        node.hasPage = files.includes("page.bp");
        node.hasLayout = files.includes("layout.bp");
        // ... etc
        // Scan subdirectories
        files.filter(f => fs.statSync(path.join(dir, f)).isDirectory()).forEach(subdir => {
            const child = createNode(subdir);
            node.children.push(child);
            scan(path.join(dir, subdir), child);
        });
    }
    const root = createNode(appDir);
    scan(appDir, root);
    return root;
}
```

**Acceptance:**
- [ ] `scanAppDir` implemented in JS
- [ ] Erlang equivalent implemented
- [ ] Both targets work

### Step 5 — Integration with SSR

The SSR pipeline uses the file router to match routes and load components:

```bp
// In ssr.bp
#[@future]
pub fn renderPageToHtml(path: string) -> @Future<string> {
    val routes = scanAppDir("app");
    val match = matchRoute(path, routes);
    if (match == null) {
        return renderNotFound();
    };
    val page = await loadPageComponent(match.node);
    val withLayouts = renderWithLayouts(match.node, page);
    return renderToString(withLayouts);
}
```

**Acceptance:**
- [ ] SSR uses file router
- [ ] Pages are loaded from file system
- [ ] Layouts are applied

### Step 6 — Tests

```bp
test "matchRoute matches static routes" {
    val routes = [RouteNode(path: "/blog", ...), RouteNode(path: "/about", ...)];
    val match = matchRoute("/blog", routes);
    assert match != null;
    assert match.node.path == "/blog";
}

test "matchRoute captures dynamic params" {
    val routes = [RouteNode(path: "/blog/[slug]", isDynamic: true, ...)];
    val match = matchRoute("/blog/hello", routes);
    assert match.params.get("slug") == "hello";
}
```

**Acceptance:**
- [ ] Tests pass on commonJS + erlang

## Gate

- [ ] `botopink test` green
- [ ] `file_router.bp` and `file_router.mjs` in place
- [ ] SSR integration works
- [ ] AGENTS.md updated
- [ ] Commit on `fix/rakun-file-routing`

## Blast radius

- New files `file_router.bp`, `file_router.mjs`
- SSR pipeline uses file router
- No breaking changes to existing decorator-based routing

## Notes

- File-system routing is the foundation — everything else (SSR, actions, middleware) builds on it.
- Dynamic segments `[slug]` become route params.
- Route groups `(group)` are transparent in the URL but can have their own layouts.
- The file router scans at startup; changes require restart (dev mode can watch).

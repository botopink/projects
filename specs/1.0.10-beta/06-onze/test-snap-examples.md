# onze — snapshot-test map of `repository/onze/examples/**`

Same contract as [`test-snap.md`](./test-snap.md). The example apps are packages; their tests live
in `examples/<app>/test/` and write `examples/<app>/test/__snapshots__/<suite>/<slug>.snap`.

Three example projects ([`modules.md`](./modules.md)): `blog` (front 53 — the acceptance app),
`scaffold` (front 50 — the committed `onze create --yes` output), `static-site` (front 71 — the
`output: export` proof).

## The E2E runner (`onze-test`)

```bp
pub type RunningApp(dir: string, mode: string, origin: string, buildId: string)
pub type Reply(status: i32, headers: Array<#(string, string)>, body: string)
pub type BuildReport(exitCode: i32, log: string)

#[@future] pub fn bootApp(exampleDir: string, mode: string) -> @Future<RunningApp>   // mode: "dev" | "start"
#[@future] pub fn stopApp(app: RunningApp) -> @Future<void>
#[@future] pub fn buildApp(exampleDir: string) -> @Future<BuildReport>                 // onze build only; never boots
#[@future] pub fn request(app: RunningApp, method: string, path: string, headers: Array<#(string, string)>, body: string) -> @Future<Reply>
#[@future] pub fn requestChunks(app: RunningApp, method: string, path: string) -> @Future<string[]>   // one entry per flushed chunk

pub fn assertResponse(loc: SourceLocation, reply: Reply) -> @Result<void, string>
pub fn assertResponseStream(loc: SourceLocation, chunks: string[]) -> @Result<void, string>
pub fn assertBundle(loc: SourceLocation, app: RunningApp) -> @Result<void, string>
pub fn assertCss(loc: SourceLocation, app: RunningApp, path: string) -> @Result<void, string>
pub fn assertServeGate(loc: SourceLocation, exampleDir: string, paths: string[]) -> @Result<void, string>
pub fn assertScaffoldEquals(loc: SourceLocation, committedDir: string) -> @Result<void, string>
pub fn assertExport(loc: SourceLocation, exampleDir: string) -> @Result<void, string>
```

`assertResponse` renders `status`, the headers it is given in the order the server sent them, a
blank line, then the body verbatim. `bootApp(dir, "start")` runs `onze build` once per test file
(cached by build id) and boots the release; `"dev"` runs `onze dev`. The blog fixture is frozen:
three posts (`hello-world`, `second-post`, `third-post`), build id `b7f2a1`, chunk and class hashes
as in `test-snap.md`. `assertServeGate` is the only helper that masks the build id (`<buildId>`), so
the same snapshot holds for both modes.

Every `e2e:` test below runs on **erlang** (that is what serves) and boots in `"start"` mode unless
it says `"dev"`.

---

## `examples/blog/test/`

### `pages_test.bp`

```bp
import {bootApp, stopApp, request, requestChunks, Reply, assertResponse, assertResponseStream} from "onze-test";

test "e2e: home ---- GET / renders the hero, the nav and one style block" {
    val app = await bootApp("examples/blog", "start");
    val reply = await request(app, "GET", "/", [], "");
    await stopApp(app);
    try assertResponse(@src(), reply);
}
```

`examples/blog/test/__snapshots__/e2e/home-get-renders-the-hero-the-nav-and-one-style-block.snap`

```
200
content-type: text/html; charset=utf-8
cache-control: private, no-store

<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Notes</title><meta name="description" content="A blog."><link rel="icon" href="/favicon.ico"><link rel="preload" as="font" type="font/woff2" href="/_onze/static/b7f2a1/fonts/inter-400.6e1a90.woff2" crossorigin><link rel="preload" as="font" type="font/woff2" href="/_onze/static/b7f2a1/fonts/inter-700.12c4f7.woff2" crossorigin><style>@font-face{font-family:"Inter";font-style:normal;font-weight:400;font-display:swap;src:url(/_onze/static/b7f2a1/fonts/inter-400.6e1a90.woff2) format("woff2")}@font-face{font-family:"Inter";font-style:normal;font-weight:700;font-display:swap;src:url(/_onze/static/b7f2a1/fonts/inter-700.12c4f7.woff2) format("woff2")}@font-face{font-family:"Inter Fallback";src:local("Arial");size-adjust:107.00%;ascent-override:96.88%;descent-override:24.15%;line-gap-override:0.00%}.onze-font-inter{font-family:"Inter","Inter Fallback",system-ui,sans-serif}</style><link rel="stylesheet" href="/_onze/static/b7f2a1/app.2b91cc.css"><style>.e_3f9a1c{background-color:#fff;color:#111827;padding:1rem}.e_77b0d4{display:flex;gap:1rem;padding-top:.5rem;padding-bottom:.5rem}.e_a4d0e1{font-size:1.875rem;font-weight:700}</style></head><body><div class="onze-font-inter e_3f9a1c"><header><nav class="e_77b0d4"><a href="/" data-jh-l="1">Home</a><a href="/blog" class="nav-item" data-jh-l="1">Blog</a><a href="/about" data-jh-l="1">About</a></nav></header><main><img src="/_onze/image?src=%2Fimages%2Fhero.jpg&w=1200&q=75&f=webp" alt="Hero" width="1200" height="600" loading="eager" fetchpriority="high" decoding="async" srcset="/_onze/image?src=%2Fimages%2Fhero.jpg&w=1200&q=75&f=webp 1x, /_onze/image?src=%2Fimages%2Fhero.jpg&w=2048&q=75&f=webp 2x"><h1 class="e_a4d0e1">Notes</h1></main></div><script>window.__bp0 = {"b":"b7f2a1","r":"/","i":[],"h":[],"s":["e_3f9a1c","e_77b0d4","e_a4d0e1"]}</script><script src="/_onze/static/b7f2a1/shared.41ab08.js" defer></script><script src="/_onze/static/b7f2a1/entry.9c1d40.js" defer></script></body></html>
```

```bp
test "e2e: blog post ---- GET /blog/hello-world with the island and its chunk" {
    val app = await bootApp("examples/blog", "start");
    val reply = await request(app, "GET", "/blog/hello-world", [], "");
    await stopApp(app);
    try assertResponse(@src(), reply);
}
```

`examples/blog/test/__snapshots__/e2e/blog-post-get-blog-hello-world-with-the-island-and-its-chunk.snap`

```
200
content-type: text/html; charset=utf-8
cache-control: private, no-store
x-onze-prerendered: b7f2a1

<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Hello, world | Notes</title><meta name="description" content="The first post."><meta property="og:title" content="Hello, world"><meta property="og:description" content="The first post."><meta property="og:url" content="https://example.dev/blog/hello-world"><meta property="og:type" content="article"><meta property="og:site_name" content="Notes"><meta property="og:image" content="/blog/hello-world/opengraph-image"><meta name="twitter:card" content="summary_large_image"><meta name="twitter:title" content="Hello, world"><meta name="twitter:description" content="The first post."><link rel="icon" href="/favicon.ico"><link rel="preload" as="font" type="font/woff2" href="/_onze/static/b7f2a1/fonts/inter-400.6e1a90.woff2" crossorigin><link rel="preload" as="font" type="font/woff2" href="/_onze/static/b7f2a1/fonts/inter-700.12c4f7.woff2" crossorigin><style>@font-face{font-family:"Inter";font-style:normal;font-weight:400;font-display:swap;src:url(/_onze/static/b7f2a1/fonts/inter-400.6e1a90.woff2) format("woff2")}@font-face{font-family:"Inter";font-style:normal;font-weight:700;font-display:swap;src:url(/_onze/static/b7f2a1/fonts/inter-700.12c4f7.woff2) format("woff2")}@font-face{font-family:"Inter Fallback";src:local("Arial");size-adjust:107.00%;ascent-override:96.88%;descent-override:24.15%;line-gap-override:0.00%}.onze-font-inter{font-family:"Inter","Inter Fallback",system-ui,sans-serif}</style><link rel="stylesheet" href="/_onze/static/b7f2a1/app.2b91cc.css"><style>.e_3f9a1c{background-color:#fff;color:#111827;padding:1rem}.e_77b0d4{display:flex;gap:1rem;padding-top:.5rem;padding-bottom:.5rem}.e_b2c8f0{font-size:1.875rem;font-weight:700;color:#111827}.e_5d61aa{font-size:.875rem;color:#6b7280}.e_8e04c3{padding-top:1rem;padding-bottom:1rem;color:#374151}.e_c5e2a0{font-size:.875rem;color:#374151;padding-left:.5rem;padding-right:.5rem}</style></head><body><div class="onze-font-inter e_3f9a1c"><header><nav class="e_77b0d4"><a href="/" data-jh-l="1">Home</a><a href="/blog" class="nav-item" data-jh-l="1">Blog</a><a href="/about" data-jh-l="1">About</a></nav></header><main><section class="blog_container_4f21ab"><article><h1 class="e_b2c8f0">Hello, world</h1><time datetime="2026-01-04" class="e_5d61aa">2026-01-04</time><p class="e_8e04c3">The first post, at length.</p><div data-jh-i="i0"><button class="e_c5e2a0" data-jh-on-click="LikeButton:like" data-onze-post="hello-world" data-onze-api="https://api.example.com">0 likes</button></div></article></section></main></div><script>window.__bp0 = {"b":"b7f2a1","r":"/blog/[slug]","i":[["i0","LikeButton","postSlug=hello-world&likes=0"]],"h":[],"s":["e_3f9a1c","e_77b0d4","e_b2c8f0","e_5d61aa","e_8e04c3","e_c5e2a0"]}</script><script src="/_onze/static/b7f2a1/shared.41ab08.js" defer></script><script src="/_onze/static/b7f2a1/r2.7e0055.js" defer></script><script src="/_onze/static/b7f2a1/entry.9c1d40.js" defer></script></body></html>
```

```bp
test "e2e: not found ---- GET /blog/nope lands in the segment boundary with 404" {
    val app = await bootApp("examples/blog", "start");
    val reply = await request(app, "GET", "/blog/nope", [], "");
    await stopApp(app);
    try assertResponse(@src(), reply);
}
```

`examples/blog/test/__snapshots__/e2e/not-found-get-blog-nope-lands-in-the-segment-boundary-with-404.snap`

```
404
content-type: text/html; charset=utf-8
cache-control: private, no-store

<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Notes</title><meta name="description" content="A blog."><link rel="icon" href="/favicon.ico"><link rel="preload" as="font" type="font/woff2" href="/_onze/static/b7f2a1/fonts/inter-400.6e1a90.woff2" crossorigin><link rel="preload" as="font" type="font/woff2" href="/_onze/static/b7f2a1/fonts/inter-700.12c4f7.woff2" crossorigin><style>@font-face{font-family:"Inter";font-style:normal;font-weight:400;font-display:swap;src:url(/_onze/static/b7f2a1/fonts/inter-400.6e1a90.woff2) format("woff2")}@font-face{font-family:"Inter";font-style:normal;font-weight:700;font-display:swap;src:url(/_onze/static/b7f2a1/fonts/inter-700.12c4f7.woff2) format("woff2")}@font-face{font-family:"Inter Fallback";src:local("Arial");size-adjust:107.00%;ascent-override:96.88%;descent-override:24.15%;line-gap-override:0.00%}.onze-font-inter{font-family:"Inter","Inter Fallback",system-ui,sans-serif}</style><link rel="stylesheet" href="/_onze/static/b7f2a1/app.2b91cc.css"><style>.e_3f9a1c{background-color:#fff;color:#111827;padding:1rem}.e_77b0d4{display:flex;gap:1rem;padding-top:.5rem;padding-bottom:.5rem}.e_b2c8f0{font-size:1.875rem;font-weight:700;color:#111827}</style></head><body><div class="onze-font-inter e_3f9a1c"><header><nav class="e_77b0d4"><a href="/" data-jh-l="1">Home</a><a href="/blog" class="nav-item" data-jh-l="1">Blog</a><a href="/about" data-jh-l="1">About</a></nav></header><main><section class="blog_container_4f21ab"><h1 class="e_b2c8f0">No such post</h1><p>There is no post at /blog/nope.</p><a href="/blog" data-jh-l="1">Back to the blog</a></section></main></div><script>window.__bp0 = {"b":"b7f2a1","r":"/blog/[slug]","i":[],"h":[],"s":["e_3f9a1c","e_77b0d4","e_b2c8f0"]}</script><script src="/_onze/static/b7f2a1/shared.41ab08.js" defer></script><script src="/_onze/static/b7f2a1/r2.7e0055.js" defer></script><script src="/_onze/static/b7f2a1/entry.9c1d40.js" defer></script></body></html>
```

```bp
test "e2e: route group ---- GET /about serves, GET /(marketing)/about does not" {
    val app = await bootApp("examples/blog", "start");
    val about = await request(app, "GET", "/about", [], "");
    val grouped = await request(app, "GET", "/(marketing)/about", [], "");
    await stopApp(app);
    try assertResponse(@src(), Reply(status: about.status, headers: [], body: about.body.split("<main>").at(1).unwrapOr("").split("</main>").at(0).unwrapOr("") + "\n" + grouped.status.toString()));
}
```

`examples/blog/test/__snapshots__/e2e/route-group-get-about-serves-get-marketing-about-does-not.snap`

```
200

<section><h1 class="e_b2c8f0">About</h1><p>Three posts and a like button.</p></section>
404
```

```bp
test "e2e: streaming ---- a slow list flushes the shell, then the chunk with its own style" {
    val app = await bootApp("examples/blog", "dev");
    val chunks = await requestChunks(app, "GET", "/blog?slow=1");
    await stopApp(app);
    try assertResponseStream(@src(), chunks);
}
```

`examples/blog/test/__snapshots__/e2e/streaming-a-slow-list-flushes-the-shell-then-the-chunk-with-its-own-style.snap`

```
== chunk 1
<!doctype html><html lang="en"><head>…<style>.e_3f9a1c{background-color:#fff;color:#111827;padding:1rem}.e_77b0d4{display:flex;gap:1rem;padding-top:.5rem;padding-bottom:.5rem}.e_19ee42{opacity:.5}</style></head><body><div class="onze-font-inter e_3f9a1c"><header>…</header><main><section class="blog_container_4f21ab"><div data-jh-h="h0"><p class="e_19ee42">Loading posts…</p></div></section></main></div>
== chunk 2
<template data-jh-f="h0"><style>.e_6c2d90{padding:1rem;background-color:#fff;border-radius:.5rem;border-width:1px;border-color:#f3f4f6}</style><ul><li><article class="e_6c2d90"><h2><a href="/blog/third-post" data-jh-l="1">Third post</a></h2><p>The third.</p></article></li><li><article class="e_6c2d90"><h2><a href="/blog/second-post" data-jh-l="1">Second post</a></h2><p>The second.</p></article></li><li><article class="e_6c2d90"><h2><a href="/blog/hello-world" data-jh-l="1">Hello, world</a></h2><p>The first post.</p></article></li></ul></template><script>__bp1("h0")</script>
== chunk 3
<script>window.__bp0 = {"b":"b7f2a1","r":"/blog","i":[],"h":["h0"],"s":["e_3f9a1c","e_77b0d4","e_19ee42","e_6c2d90"]}</script><script src="/_onze/static/b7f2a1/shared.41ab08.js" defer></script><script src="/_onze/static/b7f2a1/entry.9c1d40.js" defer></script></body></html>
== the style block for h0 is inside its fill template, before the markup
true
```

### `write_path_test.bp`

```bp
import {bootApp, stopApp, request, requestChunks, Reply, assertResponse, assertResponseStream} from "onze-test";

test "e2e: middleware ---- /dashboard without a cookie redirects before the layout" {
    val app = await bootApp("examples/blog", "start");
    val reply = await request(app, "GET", "/dashboard", [], "");
    await stopApp(app);
    try assertResponse(@src(), reply);
}
```

`examples/blog/test/__snapshots__/e2e/middleware-dashboard-without-a-cookie-redirects-before-the-layout.snap`

```
307
location: /login
x-onze-middleware: dashboard-gate

```

```bp
test "e2e: middleware ---- /images/hero.jpg is not matched at all" {
    val app = await bootApp("examples/blog", "start");
    val reply = await request(app, "GET", "/images/hero.jpg", [], "");
    await stopApp(app);
    try assertResponse(@src(), Reply(status: reply.status, headers: reply.headers.filter({ h -> h._0.startsWith("x-onze") || h._0 == "content-type" }), body: ""));
}
```

`examples/blog/test/__snapshots__/e2e/middleware-images-hero-jpg-is-not-matched-at-all.snap`

```
200
content-type: image/jpeg

```

```bp
test "e2e: action ---- an empty title re-renders the form with the message beside the field" {
    val app = await bootApp("examples/blog", "start");
    val page = await request(app, "GET", "/dashboard/posts/new", [#("cookie", "session=test-session")], "");
    val actionId = page.body.split("name=\"__onze_action\" value=\"").at(1).unwrapOr("").split("\"").at(0).unwrapOr("");
    val reply = await request(app, "POST", "/dashboard/posts/new",
        [#("cookie", "session=test-session"), #("origin", app.origin), #("content-type", "application/x-www-form-urlencoded")],
        "__onze_action=" + actionId + "&title=&body=Some+text");
    await stopApp(app);
    try assertResponse(@src(), Reply(status: reply.status, headers: [], body: reply.body.split("<form").at(1).unwrapOr("").split("</form>").at(0).unwrapOr("")));
}
```

`examples/blog/test/__snapshots__/e2e/action-an-empty-title-re-renders-the-form-with-the-message-beside-the-field.snap`

```
200

 method="post" data-jh-a="a1"><input type="hidden" name="__onze_action" value="a1"><label for="title">Title</label><input id="title" name="title" value=""><p class="e_f00d11" data-onze-field-error="title">Title is required</p><label for="body">Body</label><textarea id="body" name="body">Some text</textarea><button type="submit">Publish</button>
```

```bp
test "e2e: action ---- a valid post writes the file, redirects, and the list shows it" {
    val app = await bootApp("examples/blog", "start");
    val page = await request(app, "GET", "/dashboard/posts/new", [#("cookie", "session=test-session")], "");
    val actionId = page.body.split("name=\"__onze_action\" value=\"").at(1).unwrapOr("").split("\"").at(0).unwrapOr("");
    val posted = await request(app, "POST", "/dashboard/posts/new",
        [#("cookie", "session=test-session"), #("origin", app.origin), #("content-type", "application/x-www-form-urlencoded")],
        "__onze_action=" + actionId + "&title=Fourth+post&body=The+fourth.");
    val list = await request(app, "GET", "/blog", [], "");
    val forged = await request(app, "POST", "/dashboard/posts/new",
        [#("cookie", "session=test-session"), #("origin", "https://evil.example"), #("content-type", "application/x-www-form-urlencoded")],
        "__onze_action=" + actionId + "&title=X&body=Y");
    await stopApp(app);
    val titles = list.body.split("<h2>").drop(1).map({ s -> s.split("</h2>").at(0).unwrapOr("") });
    try assertResponse(@src(), Reply(status: posted.status, headers: posted.headers.filter({ h -> h._0 == "location" }), body: titles.join("\n") + "\nforged: " + forged.status.toString()));
}
```

`examples/blog/test/__snapshots__/e2e/action-a-valid-post-writes-the-file-redirects-and-the-list-shows-it.snap`

```
303
location: /blog/fourth-post

<a href="/blog/fourth-post" data-jh-l="1">Fourth post</a>
<a href="/blog/third-post" data-jh-l="1">Third post</a>
<a href="/blog/second-post" data-jh-l="1">Second post</a>
<a href="/blog/hello-world" data-jh-l="1">Hello, world</a>
forged: 403
```

### `api_test.bp`

```bp
import {bootApp, stopApp, request, requestChunks, Reply, assertResponse, assertResponseStream} from "onze-test";

test "e2e: api ---- GET /api/posts returns JSON and multipart is 415" {
    val app = await bootApp("examples/blog", "start");
    val get = await request(app, "GET", "/api/posts", [], "");
    val multipart = await request(app, "POST", "/api/posts", [#("content-type", "multipart/form-data; boundary=x")], "--x--");
    await stopApp(app);
    try assertResponse(@src(), Reply(status: get.status, headers: get.headers.filter({ h -> h._0 == "content-type" }), body: get.body + "\n" + multipart.status.toString()));
}
```

`examples/blog/test/__snapshots__/e2e/api-get-api-posts-returns-json-and-multipart-is-415.snap`

```
200
content-type: application/json

[{"slug":"third-post","title":"Third post","published":"2026-01-06"},{"slug":"second-post","title":"Second post","published":"2026-01-05"},{"slug":"hello-world","title":"Hello, world","published":"2026-01-04"}]
415
```

```bp
test "e2e: og ---- GET /blog/hello-world/opengraph-image is an SVG card" {
    val app = await bootApp("examples/blog", "start");
    val reply = await request(app, "GET", "/blog/hello-world/opengraph-image", [], "");
    await stopApp(app);
    try assertResponse(@src(), reply);
}
```

`examples/blog/test/__snapshots__/e2e/og-get-blog-hello-world-opengraph-image-is-an-svg-card.snap`

```
200
content-type: image/svg+xml
cache-control: public, max-age=31536000, immutable
etag: "0c7b3e"

<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630" viewBox="0 0 1200 630"><defs><linearGradient id="g0" gradientTransform="rotate(0)"><stop offset="0" stop-color="#4f46e5"/><stop offset="1" stop-color="#7c3aed"/></linearGradient></defs><rect x="0" y="0" width="1200" height="630" fill="url(#g0)"/><text x="64" y="277" font-family="Inter" font-weight="700" font-size="64" fill="#ffffff">Hello, world</text><text x="64" y="389" font-family="Inter" font-weight="700" font-size="32" fill="#ffffff" fill-opacity="0.8">ana</text></svg>
```

### `assets_test.bp`

```bp
import {bootApp, stopApp, request, buildApp, Reply, assertResponse, assertBundle, assertCss} from "onze-test";

test "e2e: assets ---- favicon is served, content/ and .onze/ are not" {
    val app = await bootApp("examples/blog", "start");
    val icon = await request(app, "GET", "/favicon.ico", [], "");
    val post = await request(app, "GET", "/content/posts/hello-world.md", [], "");
    val manifest = await request(app, "GET", "/.onze/client-manifest.txt", [], "");
    val source = await request(app, "GET", "/app/page.bp", [], "");
    val up = await request(app, "GET", "/../onze.json", [], "");
    await stopApp(app);
    val lines = [
        "/favicon.ico " + icon.status.toString() + " " + icon.headers.lookup("content-type").unwrapOr(""),
        "/content/posts/hello-world.md " + post.status.toString(),
        "/.onze/client-manifest.txt " + manifest.status.toString(),
        "/app/page.bp " + source.status.toString(),
        "/../onze.json " + up.status.toString(),
    ];
    try assertResponse(@src(), Reply(status: 0, headers: [], body: lines.join("\n")));
}
```

`examples/blog/test/__snapshots__/e2e/assets-favicon-is-served-content-and-onze-are-not.snap`

```
0

/favicon.ico 200 image/x-icon
/content/posts/hello-world.md 404
/.onze/client-manifest.txt 404
/app/page.bp 404
/../onze.json 404
```

```bp
test "bundle: chunks ---- like_button in the route chunk, db nowhere, hashes in the URLs" {
    val app = await bootApp("examples/blog", "start");
    try assertBundle(@src(), app);
    await stopApp(app);
}
```

`examples/blog/test/__snapshots__/bundle/chunks-like-button-in-the-route-chunk-db-nowhere-hashes-in-the-urls.snap`

```
== .onze/client-manifest.txt
V|1|b7f2a1
E|entry|/_onze/static/b7f2a1/entry.9c1d40.js|9c1d40|2480
S|shared|/_onze/static/b7f2a1/shared.41ab08.js|41ab08|18320
C|route:/blog/[slug]|/_onze/static/b7f2a1/r2.7e0055.js|7e0055|5120
R|/blog/[slug]|route:/blog/[slug]
Y|styles|/_onze/static/b7f2a1/app.2b91cc.css|2b91cc|940
P|ONZE_PUBLIC_API_URL|https%3A%2F%2Fapi.example.com
== shared.41ab08.js defines
components.nav, lib.format, jhonstart.client_runtime, jhonstart.link, jhonstart.form
== r2.7e0055.js defines
components.like_button
== entry.9c1d40.js mounts
Nav, LikeButton
== any chunk contains "lib.db" / "listPosts" / "content/posts"
false / false / false
== any chunk contains "flush("
false
== GET each chunk URL
200 text/javascript public, max-age=31536000, immutable  (x4)
```

```bp
test "css: stylesheet ---- globals before the blog module, served immutable" {
    val app = await bootApp("examples/blog", "start");
    try assertCss(@src(), app, "/_onze/static/b7f2a1/app.2b91cc.css");
    await stopApp(app);
}
```

`examples/blog/test/__snapshots__/css/stylesheet-globals-before-the-blog-module-served-immutable.snap`

```
200
content-type: text/css
cache-control: public, max-age=31536000, immutable
etag: "2b91cc"

*,*::before,*::after{box-sizing:border-box}
body{margin:0}
.blog_container_4f21ab{max-width:48rem;margin:0 auto}
.blog_title_4f21ab{font-size:2rem}
```

```bp
test "e2e: build refusal ---- like_button importing lib/db fails onze build with the chain" {
    val report = await buildApp("examples/blog-broken");
    try assertResponse(@src(), Reply(status: report.exitCode, headers: [], body: report.log));
}
```

`examples/blog/test/__snapshots__/e2e/build-refusal-like-button-importing-lib-db-fails-onze-build-with-the-chain.snap`

```
1

onze build
refused: server-only module lib.db reached from client root components.like_button
  components.like_button > lib.db
build failed: 1 refusal
```

(`examples/blog-broken/` is `examples/blog` plus one import line, generated by the test into a temp
copy — not a committed example.)

### `gate_test.bp` (the exit gate as a snapshot; erlang only)

```bp
import {assertServeGate} from "onze-test";

test "gate: dev vs start ---- the same bytes for every static route" {
    try assertServeGate(@src(), "examples/blog", [
        "/", "/about", "/blog", "/blog/hello-world", "/blog/second-post", "/blog/third-post",
        "/blog/nope", "/blog/hello-world/opengraph-image", "/api/posts", "/favicon.ico", "/dashboard",
    ]);
}
```

`examples/blog/test/__snapshots__/gate/dev-vs-start-the-same-bytes-for-every-static-route.snap`

```
build id: <buildId> (dev) / <buildId> (start) — equal
/                                   200 200  identical
/about                              200 200  identical
/blog                               200 200  identical
/blog/hello-world                   200 200  identical  (start: x-onze-prerendered)
/blog/second-post                   200 200  identical  (start: x-onze-prerendered)
/blog/third-post                    200 200  identical  (start: x-onze-prerendered)
/blog/nope                          404 404  identical
/blog/hello-world/opengraph-image   200 200  identical
/api/posts                          200 200  identical
/favicon.ico                        200 200  identical
/dashboard                          307 307  identical
prerendered on start: 4 (/, /blog/hello-world, /blog/second-post, /blog/third-post); page fn invoked: 0
```

### `unit_test.bp` (both targets — the pure functions, no server)

These are plain `assert` tests over the app's pure functions (`lib/db.bp` parse/list/read/write,
`post_card` class, `generateStaticParams`, `generateMetadata`, the middleware decision, each page fn
given a `PageContext`) and are listed here because they run under `zig build test-libs` beside the
snapshots. One of them is a snapshot:

```bp
import {Reply, assertResponse} from "onze-test";
import {postMetadata, mergeMetadata, rootMetadata} from "@/app.blog.d_slug.page";
import {renderHead} from "jhonstart";
import {readPost} from "@/lib.db";

test "metadata: merged head ---- the post over the root layout" {
    val post = readPost("hello-world").unwrapOr(missingPost("hello-world"));
    val head = renderHead(mergeMetadata(rootMetadata(), postMetadata(post)));
    try assertResponse(@src(), Reply(status: 0, headers: [], body: head));
}
```

`examples/blog/test/__snapshots__/metadata/merged-head-the-post-over-the-root-layout.snap`

```
0

<title>Hello, world | Notes</title><meta name="description" content="The first post."><meta property="og:title" content="Hello, world"><meta property="og:description" content="The first post."><meta property="og:url" content="https://example.dev/blog/hello-world"><meta property="og:type" content="article"><meta property="og:site_name" content="Notes"><meta property="og:image" content="/blog/hello-world/opengraph-image"><meta name="twitter:card" content="summary_large_image"><meta name="twitter:title" content="Hello, world"><meta name="twitter:description" content="The first post."><link rel="icon" href="/favicon.ico">
```

---

## `examples/scaffold/test/scaffold_test.bp` (commonJS)

```bp
import {assertScaffoldEquals, bootApp, stopApp, request, Reply, assertResponse} from "onze-test";

test "scaffold: create ---- a fresh create --yes equals the committed tree" {
    try assertScaffoldEquals(@src(), "examples/scaffold");
}
```

`examples/scaffold/test/__snapshots__/scaffold/create-a-fresh-create-yes-equals-the-committed-tree.snap`

```
onze create scaffold --yes   (in .botopinkbuild/tmp/…)
diff -r examples/scaffold …/scaffold
(no differences)
files: botopink.json, onze.json, app/layout.bp, app/page.bp, public/favicon.ico
botopink check: ok
```

```bp
test "e2e: scaffold ---- GET / from the scaffolded app" {
    val app = await bootApp("examples/scaffold", "start");
    val reply = await request(app, "GET", "/", [], "");
    await stopApp(app);
    try assertResponse(@src(), reply);
}
```

`examples/scaffold/test/__snapshots__/e2e/scaffold-get-from-the-scaffolded-app.snap`

```
200
content-type: text/html; charset=utf-8
cache-control: private, no-store

<!doctype html><html lang="en"><head><meta charset="utf-8"><title>scaffold</title><link rel="icon" href="/favicon.ico"><style>.e_d41a02{padding:2rem}.e_0f8c3b{font-size:2.25rem;font-weight:700}.e_92ab60{font-size:1.125rem;color:#6b7280}</style></head><body><div class="e_d41a02"><h1 class="e_0f8c3b">Welcome to onze</h1><p class="e_92ab60">Edit app/page.bp to get started.</p></div><script>window.__bp0 = {"b":"1d9e77","r":"/","i":[],"h":[],"s":["e_d41a02","e_0f8c3b","e_92ab60"]}</script><script src="/_onze/static/1d9e77/entry.5a0b2e.js" defer></script></body></html>
```

---

## `examples/static-site/test/export_test.bp` (erlang)

```bp
import {assertExport} from "onze-test";

test "export: tree ---- three routes as index.html and no boot script" {
    try assertExport(@src(), "examples/static-site");
}
```

`examples/static-site/test/__snapshots__/export/tree-three-routes-as-index-html-and-no-boot-script.snap`

```
onze build   (onze.json: "output": "export")
out/
  index.html
  about/
    index.html
  docs/
    index.html
  favicon.ico
  _onze/
    static/
      6b30c2/
        app.9d7e01.css
        entry.5a0b2e.js
no bin/, no releases/, no server/
== out/about/index.html contains
<h1 class="e_0f8c3b">About</h1>
== every <a href> in the three pages resolves to a file in out/
true
```

```bp
test "export: refusal ---- a dynamic route added to the tree fails the export naming itself" {
    try assertExport(@src(), "examples/static-site+dynamic");
}
```

`examples/static-site/test/__snapshots__/export/refusal-a-dynamic-route-added-to-the-tree-fails-the-export-naming-itself.snap`

```
onze build   (onze.json: "output": "export"; temp copy with app/items/[id]/page.bp added)
error: static export refused — route /items/:id (app/items/[id]/page.bp) cannot be prerendered: no static params registered
exit 1
out/: not written
```

(`examples/static-site+dynamic` is a temp copy the test makes; only `examples/static-site` is
committed.)

---

## What these prove, per front 53 row

| Acceptance-script row | Snapshot |
|---|---|
| `botopink.json` alias, `onze.json` read once | `gate/…` (both modes agree), `scaffold/…` |
| `middleware.bp` | `e2e/middleware-…` ×2 |
| `app/layout.bp` — fonts, nav, sheet once, in order | `e2e/home-…` (preload → font faces → stylesheet link → emilia block; one `<style>` for emilia) |
| `app/page.bp` — hero eager, prerendered | `e2e/home-…`, `gate/…` (page fn invoked: 0) |
| `app/loading.bp`, `app/blog/loading.bp` | `e2e/streaming-…` |
| `app/not-found.bp`, `app/blog/[slug]/not-found.bp` | `e2e/not-found-…` (the segment boundary, 404) |
| `app/blog/page.bp` — cached list, streamed | `e2e/streaming-…`, `e2e/action-a-valid-post-…` (revalidation reaches the same store) |
| `app/blog/[slug]/page.bp` — params, static params, metadata | `e2e/blog-post-…`, `metadata/…`, `gate/…` |
| `app/(marketing)/about/page.bp` | `e2e/route-group-…` |
| `app/dashboard/layout.bp`, `app/dashboard/posts/new/page.bp`, `lib/actions.bp` | `e2e/middleware-…`, `e2e/action-…` ×2 (invalid, valid, forged origin 403) |
| `app/api/posts/route.bp` | `e2e/api-…` |
| `app/blog/[slug]/opengraph-image.bp` (carried row) | `e2e/og-…` |
| `components/nav.bp`, `components/post_card.bp`, `components/like_button.bp` | `e2e/home-…`, `e2e/streaming-…`, `e2e/blog-post-…`, `bundle/…` |
| `content/` unreachable, `public/` served | `e2e/assets-…` |
| The four commands | `scaffold/…` (create), `gate/…` (dev, build, start), `e2e/build-refusal-…` (build fails, does not warn) |

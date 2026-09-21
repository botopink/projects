# Track C — jhonstart · snapshot-test map (examples)

The same map as [`test-snap.md`](./test-snap.md) for `repository/jhonstart/examples/**` — the five projects `modules.md § 8` creates. Contract, helpers and style rules are `test-snap.md § 0`; nothing is restated here. Each project has `botopink.json` (dependencies as listed), `src/` or `app/`, `test/`, and `test/__snapshots__/` beside its tests. The paths under each case are relative to `repository/jhonstart/examples/<project>/test/`.

The v0 projects `jhonstart-counter/`, `jhonstart-html/`, `jhonstart-todo/` keep their inline `assert` tests and gain no snapshots; `jhonstart-app/` is removed when `blog-ssr` lands (its three aspirational files are what `blog-ssr/app/` makes real).

---

## `examples/blog-ssr/` — fronts 26 · 28 · 30 · 31 · 32 · 94 — depends on `jhonstart`, `jhonstart-test`, `std` — target erlang

```
app/
├── layout.bp          RootLayout(page) · metadata() · viewport()
├── loading.bp         Loading()
├── error.bp           ErrorPage(info)
├── not-found.bp       NotFound()
├── global-error.bp    GlobalError(info)
└── blog/[slug]/
    ├── page.bp        PostPage(params) — two sequential loaders
    └── metadata.bp    generateMetadata(params, parent)
src/repo.bp            loadPost · loadComments (pure fixtures standing in for front 08's rows)
test/blog_test.bp
```

```bp
// test/blog_test.bp
import { Element, RouterState, Boundary, Suspense, holeId, ErrorInfo, catchError, mergeMetadata, renderToString } from "jhonstart";
import { RootLayout, metadata, viewport } from "app/layout";
import { Loading } from "app/loading";
import { ErrorPage } from "app/error";
import { NotFound } from "app/not-found";
import { GlobalError } from "app/global-error";
import { PostPage, postPanel } from "app/blog/[slug]/page";
import { generateMetadata } from "app/blog/[slug]/metadata";
import { assertHtml, assertHtmlLines, assertStream, assertErrorBoundary, assertMetadata, assertViewport, assertRoute, renderToStream, fixtureRouter } from "jhonstart-test";

test "blog: the post page ---- hello" {
    val tree = await PostPage([#("slug", "hello")]);
    try assertHtml(@src(), tree);
}
```
`__snapshots__/blog/the-post-page-hello.snap`
```
<article data-post="p-hello"><h1>Hello</h1><p>The first post, with a &lt;tag&gt; in it.</p><section class="comments"><h2>Comments</h2><ul><li><span class="author">ana</span>welcome</li><li><span class="author">bob</span>&lt;3</li></ul></section></article>
```

```bp
test "blog: the root layout wraps the page and the nav marks the section" {
    val r = fixtureRouter("/blog/hello", "/blog/[slug]", "slug=hello", "");
    val page = await PostPage(r.params);
    try assertHtmlLines(@src(), RootLayout(r, page));
}
```
`__snapshots__/blog/the-root-layout-wraps-the-page-and-the-nav-marks-the-section.snap` — `RootLayout` reads `r.segments().at(0)` for the active section; the document head is front 23's, so the layout starts at `body`'s content
```
<div class="site">
<header class="site-header">
<nav>
<a href="/" class="nav">Home</a>
<a href="/blog" class="nav active">Blog</a>
<a href="/docs" class="nav">Docs</a>
</nav>
</header>
<main>
<article data-post="p-hello">
<h1>Hello</h1>
<p>The first post, with a &lt;tag&gt; in it.</p>
<section class="comments">
<h2>Comments</h2>
<ul>
<li>
<span class="author">ana</span>welcome</li>
<li>
<span class="author">bob</span>&lt;3</li>
</ul>
</section>
</article>
</main>
</div>
```

```bp
test "blog: streamed ---- shell with the loading boundary then the page" {
    val params = [#("slug", "hello")];
    val b = Boundary(id: holeId(0), fallback: Loading(), child: { ->
        PostPage(params);
    });
    val chunks = await renderToStream(Suspense(b), [b]);
    try assertStream(@src(), chunks);
}
```
`__snapshots__/blog/streamed-shell-with-the-loading-boundary-then-the-page.snap`
```
--- chunk 0 (shell)
<div data-onze-h="h0"><div class="loading"><span class="spinner">Loading post…</span></div></div>
--- chunk 1
<template data-onze-f="h0"><article data-post="p-hello"><h1>Hello</h1><p>The first post, with a &lt;tag&gt; in it.</p><section class="comments"><h2>Comments</h2><ul><li><span class="author">ana</span>welcome</li><li><span class="author">bob</span>&lt;3</li></ul></section></article></template><script>__onzeFill("h0")</script>
```

```bp
test "blog: a missing slug raises the not-found signal through the boundary" {
    try assertErrorBoundary(@src(), catchError("post", ErrorPage, postPanel("nope")));
}
```
`__snapshots__/blog/a-missing-slug-raises-the-not-found-signal-through-the-boundary.snap` — `postPanel(slug)` returns the `#[@result]` thunk; the signal is front 63's, re-raised, and front 23 renders `NotFound()`
```
outcome: error jhonstart:not-found
```

```bp
test "blog: a failing comment service shows the segment error page" {
    try assertErrorBoundary(@src(), catchError("comments", ErrorPage, postPanel("broken-comments")));
}
```
`__snapshots__/blog/a-failing-comment-service-shows-the-segment-error-page.snap`
```
outcome: ok
<div data-onze-e="comments"><section class="segment-error"><h2>This section is unavailable</h2><p>Reference: <digest></p><button data-onze-reset="comments">Retry</button></section></div>
```

`<digest>` stands for `digestOf("comment service down")` — `content_hash.short` is front 03's and its hex is front 03's snapshot, not this track's. The first run writes the `.snap.new` with the real hex; it is accepted only after that hex is checked against front 03's `__snapshots__`. The message itself is asserted absent by construction (`infoFor` blanks it).

```bp
test "blog: not-found page" {
    try assertHtml(@src(), NotFound());
}

test "blog: global error owns its document" {
    try assertHtmlLines(@src(), GlobalError(ErrorInfo(message: "", digest: "a3f19c2b")));
}
```
`__snapshots__/blog/not-found-page.snap`
```
<section class="not-found"><h2>No such post</h2><p><a href="/blog">Back to the index</a></p></section>
```
`__snapshots__/blog/global-error-owns-its-document.snap`
```
<html lang="en">
<head>
<title>Something went wrong</title>
</head>
<body>
<main class="global-error">
<h1>Something went wrong</h1>
<p>Reference: a3f19c2b</p>
<button data-onze-reset="root">Reload</button>
</main>
</body>
</html>
```

```bp
test "blog: metadata ---- post merged onto the root layout" {
    val page = await generateMetadata([#("slug", "hello")], metadata());
    try assertMetadata(@src(), mergeMetadata(metadata(), page));
}

test "blog: viewport of the root layout" {
    try assertViewport(@src(), viewport());
}
```
`__snapshots__/blog/metadata-post-merged-onto-the-root-layout.snap`
```
<title>Hello | botopink blog</title>
<meta name="description" content="The first post, with a &lt;tag&gt; in it.">
<meta property="og:title" content="Hello">
<meta property="og:url" content="https://blog.botopink.dev/blog/hello">
<meta property="og:type" content="article">
<meta property="og:site_name" content="botopink blog">
<meta property="og:image" content="/og/hello.png">
<meta name="twitter:card" content="summary_large_image">
<link rel="icon" href="/favicon.ico">
```
`__snapshots__/blog/viewport-of-the-root-layout.snap`
```
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="theme-color" content="#111111">
```

```bp
test "blog: the route snapshot the layout reads" {
    try assertRoute(@src(), fixtureRouter("/blog/hello", "/blog/[slug]", "slug=hello", "ref=home"));
}
```
`__snapshots__/blog/the-route-snapshot-the-layout-reads.snap`
```
path: /blog/hello
pattern: /blog/[slug]
params: slug=hello
search: ref=home
selected: 0
segments: blog [slug]
segment: blog
```

---

## `examples/nav-shell/` — fronts 26 · 27 · 94 — depends on `jhonstart`, `jhonstart-link`, `jhonstart-test` — target both (link gate commonJS)

```
src/
├── sidebar.bp      Sidebar(r: RouterState) — pathname/selectedLayoutSegment shape, Link rows
├── index.bp        DocsIndex(pages) — two hundred rows with prefetch off, two nav links with it on
└── checkout.bp     CheckoutLink(status: LinkStatus)
test/nav_test.bp
```

```bp
// test/nav_test.bp
import { RouterState, renderToString } from "jhonstart";
import { LinkStatus, prefetchMode } from "jhonstart-link";
import { Sidebar } from "src/sidebar";
import { DocsIndex, Page } from "src/index";
import { CheckoutLink } from "src/checkout";
import { assertActiveLink, assertHtml, assertHtmlLines, assertNavigation, assertText, simulateNavigation, fixtureRouter } from "jhonstart-test";

test "nav: sidebar ---- guides selected" {
    val r = RouterState(path: "/docs/guides/intro", params: [], search: [], pattern: "/docs/guides/[page]", selected: 1);
    try assertActiveLink(@src(), Sidebar(r), r.path);
}
```
`__snapshots__/nav/sidebar-guides-selected.snap` — every row is a `Link`, so each anchor also carries `data-onze-l`; `assertActiveLink` prints href and class only
```
path: /docs/guides/intro
[ ] /docs/api row
[*] /docs/guides row active
[ ] /docs/faq row
```

```bp
test "nav: a sidebar row is a link with the two default attributes" {
    val r = RouterState(path: "/docs/api", params: [], search: [], pattern: "/docs/api", selected: 1);
    try assertHtmlLines(@src(), Sidebar(r));
}
```
`__snapshots__/nav/a-sidebar-row-is-a-link-with-the-two-default-attributes.snap`
```
<nav class="sidebar">
<ul>
<li>
<a href="/docs/api" data-onze-l="1" class="row active">API</a>
</li>
<li>
<a href="/docs/guides" data-onze-l="1" class="row">Guides</a>
</li>
<li>
<a href="/docs/faq" data-onze-l="1" class="row">FAQ</a>
</li>
</ul>
</nav>
```

```bp
test "nav: the index switches prefetch off for its rows and leaves the header on" {
    val pages = [Page(slug: "a", title: "Alpha"), Page(slug: "b", title: "Beta")];
    try assertHtmlLines(@src(), DocsIndex(pages));
}
```
`__snapshots__/nav/the-index-switches-prefetch-off-for-its-rows-and-leaves-the-header-on.snap`
```
<div class="index">
<nav>
<a href="/" data-onze-l="1">Home</a>
<a href="/docs" data-onze-l="1">Docs</a>
</nav>
<ul class="archive">
<li>
<a href="/docs/a" data-onze-l="1" data-onze-prefetch="0">Alpha</a>
</li>
<li>
<a href="/docs/b" data-onze-l="1" data-onze-prefetch="0">Beta</a>
</li>
</ul>
</div>
```

```bp
test "nav: prefetch policy per route kind" {
    try assertText(@src(), "docs=" + prefetchMode("static", false, true) + "\nguide-page=" + prefetchMode("dynamic", true, true) + "\nsearch=" + prefetchMode("dynamic", false, true));
}
```
`__snapshots__/nav/prefetch-policy-per-route-kind.snap`
```
docs=full
guide-page=partial
search=skip
```

```bp
test "nav: moving between two guides keeps the docs and guides layouts" {
    val from = fixtureRouter("/docs/guides/intro", "/docs/guides/[page]", "page=intro", "");
    val to = fixtureRouter("/docs/guides/setup", "/docs/guides/[page]", "page=setup", "");
    try assertNavigation(@src(), simulateNavigation(from, to));
}
```
`__snapshots__/nav/moving-between-two-guides-keeps-the-docs-and-guides-layouts.snap` — keys come from the pattern, so two pages of one dynamic segment share every layout and remount only the leaf
```
from: / /docs /docs/guides /docs/guides/[page]
to: / /docs /docs/guides /docs/guides/[page]
shared: 4
keep: / /docs /docs/guides /docs/guides/[page]
remount: 
```

```bp
test "nav: checkout link ---- idle and busy" {
    val idle = renderToString(CheckoutLink(LinkStatus(pending: false, href: "")));
    val busy = renderToString(CheckoutLink(LinkStatus(pending: true, href: "/checkout")));
    val other = renderToString(CheckoutLink(LinkStatus(pending: true, href: "/cart")));
    try assertText(@src(), idle + "\n" + busy + "\n" + other);
}
```
`__snapshots__/nav/checkout-link-idle-and-busy.snap`
```
<a href="/checkout" data-onze-l="1" class="cta">Checkout</a>
<a href="/checkout" data-onze-l="1" class="cta busy"><span class="spinner"></span>Checking out…</a>
<a href="/checkout" data-onze-l="1" class="cta">Checkout</a>
```

---

## `examples/islands/` — fronts 28 · 29 · 94 — depends on `jhonstart`, `jhonstart-test` — target both

```
src/
├── like_button.bp   #[clientProps] LikeProps · #[client] LikeButton · likeIsland(id, props)
├── theme.bp         #[clientProps] ThemeProps · #[client] ThemeProvider · themeIsland(id, theme)
└── page.bp          PostList(posts) — one island per post · RootLayout(theme, page)
test/islands_test.bp
```

```bp
// test/islands_test.bp
import { Element, Island, clientMount, serverSlot, islandEntry, renderToString } from "jhonstart";
import { LikeProps, LikeButton, likeIsland } from "src/like_button";
import { ThemeProps, ThemeProvider, themeIsland } from "src/theme";
import { Post, PostList, RootLayout } from "src/page";
import { assertHtml, assertHtmlLines, assertClientBundleEntry, assertText } from "jhonstart-test";

test "islands: both markers are emitted" {
    try assertText(@src(), __jhClient_LikeButton() + " " + __jhClient_ThemeProvider());
}
```
`__snapshots__/islands/both-markers-are-emitted.snap`
```
LikeButton ThemeProvider
```

```bp
test "islands: one island per post numbered in render order" {
    val posts = [Post(id: "p1", title: "One", likes: 3), Post(id: "p2", title: "Two", likes: 0)];
    try assertHtmlLines(@src(), PostList(posts));
}
```
`__snapshots__/islands/one-island-per-post-numbered-in-render-order.snap` — the component and its props are not in the markup
```
<ul class="posts">
<li>
<h2>One</h2>
<div data-onze-i="i0">
</div>
</li>
<li>
<h2>Two</h2>
<div data-onze-i="i1">
</div>
</li>
</ul>
```

```bp
test "islands: the payload rows for the list" {
    val islands = [likeIsland("i0", LikeProps(postId: "p1", likes: 3)), likeIsland("i1", LikeProps(postId: "p2", likes: 0))];
    try assertClientBundleEntry(@src(), islands);
}
```
`__snapshots__/islands/the-payload-rows-for-the-list.snap`
```
--- payload i
i0 LikeButton postId=p1&likes=3
i1 LikeButton postId=p2&likes=0
--- markup
<div data-onze-i="i0"></div>
<div data-onze-i="i1"></div>
```

```bp
test "islands: the client component's own render is what hydration produces" {
    try assertHtml(@src(), LikeButton(LikeProps(postId: "p1", likes: 3)));
}
```
`__snapshots__/islands/the-client-component-s-own-render-is-what-hydration-produces.snap` — rendered directly (no `use` in the body), the markup the browser paints inside `i0`
```
<button class="like" data-post="p1">♥ 3</button>
```

```bp
test "islands: the theme provider wraps the whole server tree in a slot" {
    val page = PostList([Post(id: "p1", title: "One", likes: 3)]);
    try assertHtml(@src(), RootLayout("dark", page));
}
```
`__snapshots__/islands/the-theme-provider-wraps-the-whole-server-tree-in-a-slot.snap` — island `i0` is the provider; the like island inside the slot is numbered after it by front 23 (here the example passes `i1`)
```
<div data-onze-i="i0"><div data-onze-s="1"><ul class="posts"><li><h2>One</h2><div data-onze-i="i1"></div></li></ul></div></div>
```

---

## `examples/forms/` — fronts 67 · 29 · 26 · 27 · 94 — depends on `jhonstart`, `jhonstart-link`, `jhonstart-forms`, `jhonstart-test`, `std` — target commonJS

```
src/
├── create_post.bp   createPostForm(binding, state, pending) · CreatePostForm(actionId)
├── like.bp          likeWidget(binding, shown, status) · LikeWidget(serverCount)
└── search.bp        searchForm(props) · SearchForm()
test/forms_test.bp
```

```bp
// test/forms_test.bp
import { Element, renderToString } from "jhonstart";
import { ActionState, actionState, parseActionState, formAction, FormStatus, applyOptimistic, searchFormProps } from "jhonstart-forms";
import { createPostForm } from "src/create_post";
import { likeWidget, addLike } from "src/like";
import { searchForm } from "src/search";
import { querystring } from "std";
import { assertForm, assertActionState, assertOptimistic, assertText, stubEnvelope } from "jhonstart-test";

val actionId = "a_9f31c0d7a4b2e5081c6fa3d2";
val goldenState = "message=Title%20must%20be%20at%20least%203%20characters&f.title=Too%20short";

test "forms: create post ---- empty" {
    try assertForm(@src(), createPostForm(formAction(actionId, "/blog/new"), actionState(""), false));
}
```
`__snapshots__/forms/create-post-empty.snap`
```
<form method="post" action="/blog/new" data-onze-a="a_9f31c0d7a4b2e5081c6fa3d2">
<input type="hidden" name="__onze_action" value="a_9f31c0d7a4b2e5081c6fa3d2">
</input>
<label for="title">Title</label>
<input id="title" name="title" required="required">
</input>
<label for="content">Content</label>
<input id="content" name="content" required="required">
</input>
<button type="submit">Create post</button>
</form>
```

```bp
test "forms: create post ---- returned message beside the title" {
    val state = parseActionState(stubEnvelope(false, goldenState, ""));
    try assertForm(@src(), createPostForm(formAction(actionId, "/blog/new"), state, false));
}
```
`__snapshots__/forms/create-post-returned-message-beside-the-title.snap`
```
<form method="post" action="/blog/new" data-onze-a="a_9f31c0d7a4b2e5081c6fa3d2">
<input type="hidden" name="__onze_action" value="a_9f31c0d7a4b2e5081c6fa3d2">
</input>
<label for="title">Title</label>
<input id="title" name="title" required="required">
</input>
<p class="field-error">Too short</p>
<label for="content">Content</label>
<input id="content" name="content" required="required">
</input>
<button type="submit">Create post</button>
</form>
```

```bp
test "forms: the golden state as the page sees it" {
    try assertActionState(@src(), parseActionState(stubEnvelope(false, goldenState, "")));
}
```
`__snapshots__/forms/the-golden-state-as-the-page-sees-it.snap`
```
ok: false
message: Title must be at least 3 characters
redirectTo: 
f.title: Too short
```

```bp
test "forms: like widget ---- server pass shows the server's count" {
    val idle = FormStatus(pending: false, actionId: "", method: "post");
    try assertForm(@src(), likeWidget(formAction(actionId, "/blog/hello"), 41, idle));
}
```
`__snapshots__/forms/like-widget-server-pass-shows-the-server-s-count.snap`
```
<form method="post" action="/blog/hello" data-onze-a="a_9f31c0d7a4b2e5081c6fa3d2">
<input type="hidden" name="__onze_action" value="a_9f31c0d7a4b2e5081c6fa3d2">
</input>
<span class="count">41</span>
<button type="submit">♥</button>
</form>
```

```bp
test "forms: like widget ---- optimistic count with a busy nested button" {
    val busy = FormStatus(pending: true, actionId: actionId, method: "post");
    val shown = applyOptimistic(41, [1, 1], addLike);
    try assertForm(@src(), likeWidget(formAction(actionId, "/blog/hello"), shown, busy));
}
```
`__snapshots__/forms/like-widget-optimistic-count-with-a-busy-nested-button.snap` — the nested button reads its own form's status; the count is the fold, not the server's
```
<form method="post" action="/blog/hello" data-onze-a="a_9f31c0d7a4b2e5081c6fa3d2">
<input type="hidden" name="__onze_action" value="a_9f31c0d7a4b2e5081c6fa3d2">
</input>
<span class="count">43</span>
<button type="submit" disabled="disabled">♥</button>
</form>
```

```bp
test "forms: optimistic fold and its collapse" {
    try assertOptimistic(@src(), 41, [1, 1]);
}
```
`__snapshots__/forms/optimistic-fold-and-its-collapse.snap` — after the envelope the actions are dropped and the value is the new base; both outcomes end at `assertOptimistic(@src(), newBase, [])`
```
base: 41
actions: 1 1
value: 43
```

```bp
test "forms: search form and the URL a plain GET produces" {
    val props = searchFormProps("/search");
    val fields = [#("q", "botopink lang"), #("sort", "new")];
    val url = "/search?" + querystring.stringify(fields);
    try assertText(@src(), renderToString(searchForm(props)) + "\n" + url);
}
```
`__snapshots__/forms/search-form-and-the-url-a-plain-get-produces.snap` — `querystring` does not percent-encode (`querystring.bp:9-16`); the space survives, which is the literal that front 01's encoder changes when it lands and this snapshot is regenerated deliberately
```
<form method="get" action="/search" data-onze-sf="1"><input name="q"></input><select name="sort"><option value="new">Newest</option><option value="top">Top</option></select><button type="submit">Search</button></form>
/search?q=botopink lang&sort=new
```

---

## `examples/document-shell/` — front 94 + the DSL — depends on `jhonstart`, `jhonstart-html`, `jhonstart-test` — target both

```
src/
├── shell.bp        documentShell(lang, pageTitle, styleHref, content) with constructors
└── shell_dsl.bp    documentBody(content) written as html """…""" over the same tags
test/shell_test.bp
```

```bp
// test/shell_test.bp
import { Element, text, p, main, h2, el, renderToString } from "jhonstart";
import { html } from "jhonstart-html";
import { documentShell, doctype } from "src/shell";
import { documentBody } from "src/shell_dsl";
import { assertHtml, assertHtmlLines, assertText } from "jhonstart-test";

test "shell: constructors ---- head before body" {
    val content = main([h2([text("Welcome", attrs: [])], attrs: [])], attrs: []);
    try assertHtmlLines(@src(), documentShell("en", "botopink", "/app.css", content));
}
```
`__snapshots__/shell/constructors-head-before-body.snap`
```
<html lang="en">
<head>
<meta charset="utf-8">
</meta>
<title>botopink</title>
<link rel="stylesheet" href="/app.css">
</link>
</head>
<body>
<main>
<h2>Welcome</h2>
</main>
</body>
</html>
```

```bp
test "shell: the doctype is a string prefix, not an element" {
    val content = main([], attrs: []);
    try assertText(@src(), doctype() + renderToString(documentShell("en", "x", "/a.css", content)));
}
```
`__snapshots__/shell/the-doctype-is-a-string-prefix-not-an-element.snap`
```
<!doctype html><html lang="en"><head><meta charset="utf-8"></meta><title>x</title><link rel="stylesheet" href="/a.css"></link></head><body><main></main></body></html>
```

```bp
test "shell: the dsl body equals the constructor body" {
    val fromDsl = renderToString(documentBody("Welcome"));
    val fromCtor = renderToString(main([h2([text("Welcome", attrs: [])], attrs: [])], attrs: [#("class", "page")]));
    try assertText(@src(), fromDsl + "\n" + fromCtor);
}
```
`__snapshots__/shell/the-dsl-body-equals-the-constructor-body.snap` — `documentBody` is `html """<main [class]={cls}><h2>${title}</h2></main>"""`; `<html>` itself cannot be authored in the DSL (the tag resolves to the template fn), which is why only the body has a DSL twin
```
<main class="page"><h2>Welcome</h2></main>
<main class="page"><h2>Welcome</h2></main>
```

```bp
test "shell: the main caveat ---- el keeps a module that declares main" {
    val tree = el("main", [p([text("entry", attrs: [])], attrs: [])], attrs: []);
    try assertHtml(@src(), tree);
}
```
`__snapshots__/shell/the-main-caveat-el-keeps-a-module-that-declares-main.snap` — this test file declares no `fn main()`; the example's `src/entry.bp` does and uses `el("main", …)` because a package import alias is parsed and ignored
```
<main><p>entry</p></main>
```

---

## Coverage — projects to fronts

| Project | Snapshots | Fronts' criteria exercised end-to-end |
|---|---|---|
| `blog-ssr` | 10 | 26 snapshot + active section · 28 two loaders + escaping · 30 `loading.bp` boundary + fill · 31 signal pass-through, segment error, `global-error` document, not-found · 32 static + dynamic merge, viewport · 94 `htmlTag`/`body`/`main`/`nav` |
| `nav-shell` | 6 | 26 active segment · 27 default anchor, prefetch off, `prefetchMode`, layout reuse across a dynamic segment, `linkStatus` render · 94 `nav`/`a` |
| `islands` | 5 | 29 markers, placeholders, payload rows, provider + slot · 28 server tree inside the slot · 94 `button`/`h2` |
| `forms` | 7 | 67 binding, field message, pending, optimistic + nested status, GET form · 94 `form`/`input`/`label`/`button`/`select`/`option` · 26/27 by the search form's navigation (asserted as the URL) |
| `document-shell` | 4 | 94 document builders, doctype prefix, `main` caveat · DSL parity |

The browser-side behaviour none of these can reach — hydration, click interception, `__onzeFill` adoption, submit interception, `redirectTo → push` — is `../../06-onze/53-onze-example-app/`'s, the first project with a browser in the loop.

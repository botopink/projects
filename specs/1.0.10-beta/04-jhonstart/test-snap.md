# Track C — jhonstart · snapshot-test map (modules)

The preventive snapshot map of `repository/jhonstart/modules/**`: the `jhonstart-test` helpers, then per front the `.bp` test cases and the exact `.snap` each produces. Written before the code so that every acceptance criterion in the nine READMEs has a literal it must reproduce. The contract is `../../01-std/{src-builtin,snapshots,asserts-api}.md`.

## 0 · Contract and helpers

### 0.1 The contract every case below assumes

| Item | Rule |
|---|---|
| `SourceLocation(file, line, column, fnName)` | `@src()`, comptime |
| Test name | `"<suite>: <rest>"` — `suite` is the text before the first `": "`; `slug` is the slugified rest: lowercase, every run of characters outside `[a-z0-9]` collapsed to one `-`, leading/trailing `-` dropped. `"stream: shell then one fill ---- two chunks"` → suite `stream`, slug `shell-then-one-fill-two-chunks` |
| Path | `snapshots.path(loc)` = `<dir of loc.file>/__snapshots__/<suite>/<slug>.snap` |
| Content | exactly the text the helper hands to `snapshots.match(loc, text)`; helpers end the text with one `\n`; an empty subject produces an empty file |
| Mismatch / missing | `<path>.new` is written and the test fails; no update flag; acceptance is a person renaming the file |
| Helper shape | `pub fn assert<Subject>(loc: SourceLocation, …) -> @Result<void, string>`; called as `try assert<Subject>(@src(), …);` |

### 0.2 `jhonstart-test` — signatures and the text each one produces

All in `modules/jhonstart-test/src/`. Every helper serialises and calls `snapshots.match`; none formats HTML beyond the two splits named here.

| Helper (file) | Text |
|---|---|
| `assertText(loc, text: string)` (`harness.bp`) | `text` verbatim — the escape hatch for a pure value already rendered to a string |
| `assertHtml(loc, e: Element)` (`assert_html.bp`) | `renderToString(e)`, one line |
| `assertHtmlLines(loc, e: Element)` (`assert_html.bp`) | `renderToString(e)` with every `><` boundary broken into `>\n<` — one tag per line, for documents and forms |
| `assertRoute(loc, r: RouterState)` (`assert_route.bp`) | seven `key: value` lines — `path`, `pattern`, `params` (querystring), `search` (querystring), `selected`, `segments` (space-joined), `segment` |
| `assertActiveLink(loc, nav: Element, path: string)` (`assert_route.bp`) | line 1 `path: <path>`; then one line per `a` in tree order: `[*]` if its `class` contains `active` else `[ ]`, the `href`, the `class` |
| `assertNavigation(loc, n: Navigation)` (`assert_link.bp`) | `from`, `to` (space-joined layout keys), `shared` (depth), `keep` (keys kept mounted), `remount` (keys replaced) |
| `simulateNavigation(from: RouterState, to: RouterState) -> Navigation` (`harness.bp`) | pure: `layoutKeys(from.segments())`, `layoutKeys(to.segments())`, `sharedDepth`, and the two partitions |
| `fixtureRouter(path, pattern, params, search) -> RouterState` (`harness.bp`) | `RouterState(path, querystring.parse(params), querystring.parse(search), pattern, selected: 0)` |
| `assertRequest(loc, r: RequestData)` (`assert_server.bp`) | six `key: value` lines — `method`, `path`, `params`, `query`, `headers`, `cookies` (querystring each) |
| `fixtureRequest(method, path, params, query, headers, cookies) -> RequestData` (`harness.bp`) | all six querystring-decoded |
| `assertClientBundleEntry(loc, islands: Array<Island>)` (`assert_island.bp`) | `--- payload i` then one `<id> <component> <props>` line per island (the `islandEntry` tuple, space-joined); `--- markup` then `renderToString(clientMount(island, []))` per island |
| `assertStream(loc, chunks: Array<string>)` (`assert_stream.bp`) | for each chunk `--- chunk <n>` (`--- chunk 0 (shell)` for the first) followed by the chunk |
| `assertDocument(loc, doc: string)` (`assert_render.bp`) | the document split one tag per line after `<body>`; the payload script's JSON one key per line |
| `renderStreamCollect(a: App, input: PageInput, req: RequestData) -> @Future<Array<string>>` (`harness.bp`) | `renderStream` with a `write` (`fn(string) -> @Future<void>`) that appends to an array — the chunks in the order `write` received them |
| `fixtureRequest(path) -> RequestData` (`harness.bp`) | a `GET` `RequestData` for `path` with no params, query, headers or cookies — the value onze would build from rakun's `Request` |
| `fixturePageOver(path, shell: Element, child: fn() -> @Component<Element>) -> PageInput` (`harness.bp`) | a `PageInput` over one root segment whose page is `shell` with one boundary over `child`, build id `build-0001` |
| `renderToStream(shell: Element, boundaries: Array<Boundary>) -> @Future<Array<string>>` (`harness.bp`) | `[shellHtml(shell)] ++ [fillHtml(await resolve(b), "") …]` in **declaration** order, no plugin — the harness has no scheduler; completion order is front 30's `render_test.bp` |
| `assertErrorBoundary(loc, b: ErrorBoundary)` (`assert_error_boundary.bp`) | `renderBoundaryChecked(b)`: `outcome: ok` + newline + markup, or `outcome: error <message>` |
| `assertMetadata(loc, m: Metadata)` · `assertViewport(loc, v: Viewport)` (`assert_metadata.bp`) | `renderHead(m)` / `renderViewport(v)` one tag per line (the `><` split) |
| `assertForm(loc, f: Element)` (`assert_form.bp`) | `assertHtmlLines` under the `form` name |
| `assertActionState(loc, s: ActionState)` (`assert_form.bp`) | `ok`, `message`, `redirectTo` lines, then one `f.<name>: <message>` line per field |
| `assertOptimistic(loc, base: i32, actions: i32[])` (`assert_form.bp`) | `base`, `actions` (space-joined), `value` = `applyOptimistic(base, actions, { c, a -> c + a })` |
| `stubEnvelope(ok: bool, state: string, redirect: string) -> string` (`harness.bp`) | the flat string `__jhFormSubmit` hands botopink: `ok=<1|0>&redirect=<pct>&state=<pct>&payload=` |

Three facts the map relies on and states rather than assumes silently: `renderToString` is the frozen renderer, so a void element renders `<input …></input>` in every snapshot below (front 94 *Blocked*; front 30's `renderNode` is the shipping renderer and has its own section below, § 30 · render); `renderHead`/`renderViewport` write their own tags and emit no closing tag for `meta`/`link`; a fixture standing in for a server component is `#[@use] fn … -> @Component<Element>` even when it awaits nothing, because that is the thunk type `Boundary.child` and `renderServerComponent` take (decision 104), while a component that activates nothing is a bare `fn … -> Element` (question 92-b).

Style rules every case follows: `if` is an expression and carries an `else`; no `//` inside a closure, template or enum body; `(expr).method()` is not written; a compound condition is bound to a `val` first; every constructor call spells `attrs:`; multiline text is leading-`\\` lines.

---

## 94 · element-surface — `modules/jhonstart/test/elements_test.bp`

```bp
import { Element, text, a, nav, section, h2, main, input, htmlTag, head, body, title, meta, link, timeTag, el, isVoidTag, isRawTextTag, renderToString } from "jhonstart";
import { assertHtml, assertHtmlLines, assertText } from "jhonstart-test";

test "elements: section with a heading" {
    val tree = section([h2([text("Posts", attrs: [])], attrs: [])], attrs: []);
    try assertHtml(@src(), tree);
}
```
`modules/jhonstart/test/__snapshots__/elements/section-with-a-heading.snap`
```
<section><h2>Posts</h2></section>
```

```bp
test "elements: attribute order is array order" {
    val tree = a([text("x", attrs: [])], attrs: [#("href", "/p"), #("rel", "next")]);
    try assertHtml(@src(), tree);
}
```
`__snapshots__/elements/attribute-order-is-array-order.snap`
```
<a href="/p" rel="next">x</a>
```

```bp
test "elements: a void constructor drops its children" {
    val tree = input([text("x", attrs: [])], attrs: [#("name", "title")]);
    try assertHtml(@src(), tree);
}
```
`__snapshots__/elements/a-void-constructor-drops-its-children.snap` — the frozen renderer's closing tag, spelled out so the day `element.bp` is unfrozen this file is the one that fails
```
<input name="title"></input>
```

```bp
test "elements: renamed constructors render their real tag" {
    val tree = htmlTag([timeTag([text("today", attrs: [])], attrs: [#("datetime", "2026-09-20")])], attrs: [#("lang", "en")]);
    try assertHtml(@src(), tree);
}
```
`__snapshots__/elements/renamed-constructors-render-their-real-tag.snap`
```
<html lang="en"><time datetime="2026-09-20">today</time></html>
```

```bp
test "elements: attribute values are stored verbatim" {
    val tree = a([text("x", attrs: [])], attrs: [#("href", "/a&b")]);
    try assertHtml(@src(), tree);
}
```
`__snapshots__/elements/attribute-values-are-stored-verbatim.snap` — escaping is front 30's walker's, not the constructor's
```
<a href="/a&b">x</a>
```

```bp
test "elements: the escape hatch builds an unnamed tag" {
    try assertHtml(@src(), el("figure", [text("x", attrs: [])], attrs: []));
}
```
`__snapshots__/elements/the-escape-hatch-builds-an-unnamed-tag.snap`
```
<figure>x</figure>
```

```bp
test "elements: document shell ---- head before body" {
    val doc = htmlTag([
        head([
            title([text("botopink", attrs: [])], attrs: []),
            meta([], attrs: [#("charset", "utf-8")]),
            link([], attrs: [#("rel", "stylesheet"), #("href", "/app.css")]),
        ], attrs: []),
        body([main([h2([text("hi", attrs: [])], attrs: [])], attrs: [])], attrs: []),
    ], attrs: [#("lang", "en")]);
    try assertHtmlLines(@src(), doc);
}
```
`__snapshots__/elements/document-shell-head-before-body.snap`
```
<html lang="en">
<head>
<title>botopink</title>
<meta charset="utf-8">
</meta>
<link rel="stylesheet" href="/app.css">
</link>
</head>
<body>
<main>
<h2>hi</h2>
</main>
</body>
</html>
```

```bp
test "elements: void and raw-text predicates" {
    val voids = ["area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "param", "source", "track", "wbr", "div", "form", ""];
    val lines = voids.map({ t -> t + "=" + isVoidTag(t).toString() });
    val raws = ["script", "style", "title", "textarea"].map({ t -> t + "=" + isRawTextTag(t).toString() });
    try assertText(@src(), "void " + lines.join(" ") + "\nraw " + raws.join(" "));
}
```
`__snapshots__/elements/void-and-raw-text-predicates.snap`
```
void area=true base=true br=true col=true embed=true hr=true img=true input=true link=true meta=true param=true source=true track=true wbr=true div=false form=false =false
raw script=true style=true title=false textarea=false
```

### 94 · DSL resolution — `modules/jhonstart-html/test/elements_dsl_test.bp`

```bp
import { html } from "jhonstart-html";
import { nav, section, p, span, text, renderToString } from "jhonstart";
import { assertHtml } from "jhonstart-test";

test "html-dsl: a surface tag resolves inside a template" {
    val bar = html """<nav><span>home</span></nav>""";
    try assertHtml(@src(), bar);
}

test "html-dsl: a v0 tag and a surface tag nest" {
    val tree = html """<section><p>hi</p></section>""";
    try assertHtml(@src(), tree);
}

test "html-dsl: a bracket prop reaches attrs on a surface tag" {
    val c = "card";
    val tree = html """<nav [class]={c}><span>x</span></nav>""";
    try assertHtml(@src(), tree);
}
```
`modules/jhonstart-html/test/__snapshots__/html-dsl/a-surface-tag-resolves-inside-a-template.snap`
```
<nav><span>home</span></nav>
```
`__snapshots__/html-dsl/a-v0-tag-and-a-surface-tag-nest.snap`
```
<section><p>hi</p></section>
```
`__snapshots__/html-dsl/a-bracket-prop-reaches-attrs-on-a-surface-tag.snap`
```
<nav class="card"><span>x</span></nav>
```

---

## 26 · router — `modules/jhonstart/test/router_test.bp`

```bp
import { Element, span, ul, li, text, a, nav, renderToString } from "jhonstart";
import { RouterState, pairValue } from "jhonstart";
import { assertRoute, assertActiveLink, assertText, fixtureRouter } from "jhonstart-test";

test "route: snapshot ---- blog slug" {
    val r = RouterState(path: "/blog/hi", params: [#("slug", "hi")], search: [], pattern: "/blog/[slug]", selected: 0);
    try assertRoute(@src(), r);
}
```
`modules/jhonstart/test/__snapshots__/route/snapshot-blog-slug.snap` — the bracket spelling is kept in `segments`
```
path: /blog/hi
pattern: /blog/[slug]
params: slug=hi
search: 
selected: 0
segments: blog [slug]
segment: blog
```

```bp
test "route: search params round-trip through the snapshot" {
    val r = fixtureRouter("/products", "/products", "", "sort=price&page=2");
    try assertRoute(@src(), r);
}
```
`__snapshots__/route/search-params-round-trip-through-the-snapshot.snap`
```
path: /products
pattern: /products
params: 
search: sort=price&page=2
selected: 0
segments: products
segment: products
```

```bp
test "route: an out-of-range selected depth yields an empty segment" {
    val r = RouterState(path: "/", params: [], search: [], pattern: "/", selected: 3);
    try assertRoute(@src(), r);
}
```
`__snapshots__/route/an-out-of-range-selected-depth-yields-an-empty-segment.snap`
```
path: /
pattern: /
params: 
search: 
selected: 3
segments: 
segment: 
```

```bp
test "route: a duplicated key takes the first match and an absent key is empty" {
    val pairs = [#("slug", "a"), #("slug", "b")];
    try assertText(@src(), "slug=" + pairValue(pairs, "slug") + "\nmissing=" + pairValue(pairs, "missing"));
}
```
`__snapshots__/route/a-duplicated-key-takes-the-first-match-and-an-absent-key-is-empty.snap`
```
slug=a
missing=
```

```bp
fn navItem(href: string, label: string, active: bool) -> Element {
    val cls = if (active) { "row active" } else { "row" };
    return li([a([text(label, attrs: [])], attrs: [#("href", href), #("class", cls)])], attrs: []);
}

fn sidebarFor(segment: string) -> Element {
    return nav([ul([
        navItem("/docs/api", "API", segment == "api"),
        navItem("/docs/guides", "Guides", segment == "guides"),
        navItem("/docs/faq", "FAQ", segment == "faq"),
    ], attrs: [])], attrs: [#("class", "sidebar")]);
}

test "route: active nav ---- api selected" {
    val r = RouterState(path: "/docs/api", params: [], search: [], pattern: "/docs/api", selected: 1);
    try assertActiveLink(@src(), sidebarFor(r.segment()), r.path);
}
```
`__snapshots__/route/active-nav-api-selected.snap`
```
path: /docs/api
[*] /docs/api row active
[ ] /docs/guides row
[ ] /docs/faq row
```

```bp
test "route: active nav ---- nobody selected" {
    val r = RouterState(path: "/docs", params: [], search: [], pattern: "/docs", selected: 1);
    try assertActiveLink(@src(), sidebarFor(r.segment()), r.path);
}
```
`__snapshots__/route/active-nav-nobody-selected.snap`
```
path: /docs
[ ] /docs/api row
[ ] /docs/guides row
[ ] /docs/faq row
```

```bp
test "route: hooks called directly return the field they name" {
    val r = fixtureRouter("/blog/hi", "/blog/[slug]", "slug=hi", "");
    try assertText(@src(), "segments=" + r.segments().join(",") + "\nparam=" + r.param("slug") + "\nsearch=" + r.searchParam("q"));
}
```
`__snapshots__/route/hooks-called-directly-return-the-field-they-name.snap`
```
segments=blog,[slug]
param=hi
search=
```

Not snapshotted here: `snapshot()` over the five `#[@External.Erlang]` cells and the six navigation verbs — they need a stubbed `jhonstart_router` erlang module beside the test and assert only that they return (items 2 and 5 of the front's test plan, plain `assert`).

---

## 27 · link — `modules/jhonstart-link/test/link_test.bp` and `reconcile_test.bp`

```bp
import { Element, text, span, renderToString, RouterState } from "jhonstart";
import { Link, LinkProps, linkProps, withPrefetch, withReplace, withScroll, withTarget, withClass, prefetchMode, linkStatus } from "jhonstart-link";
import { assertHtml, assertText } from "jhonstart-test";

test "link: default props render two attributes" {
    try assertHtml(@src(), Link(linkProps("/about"), [text("About", attrs: [])]));
}
```
`modules/jhonstart-link/test/__snapshots__/link/default-props-render-two-attributes.snap`
```
<a href="/about" data-jh-l="1">About</a>
```

```bp
test "link: prefetch off adds one marker" {
    try assertHtml(@src(), Link(withPrefetch(linkProps("/blog/x"), false), [text("x", attrs: [])]));
}
```
`__snapshots__/link/prefetch-off-adds-one-marker.snap`
```
<a href="/blog/x" data-jh-l="1" data-jh-prefetch="0">x</a>
```

```bp
test "link: replace and no scroll" {
    val props = withScroll(withReplace(linkProps("/settings"), true), false);
    try assertHtml(@src(), Link(props, [text("Settings", attrs: [])]));
}
```
`__snapshots__/link/replace-and-no-scroll.snap`
```
<a href="/settings" data-jh-l="1" data-jh-replace="1" data-jh-scroll="0">Settings</a>
```

```bp
test "link: target and class are real attributes" {
    val props = withClass(withTarget(linkProps("/docs"), "_blank"), "ext");
    try assertHtml(@src(), Link(props, [text("docs", attrs: [])]));
}
```
`__snapshots__/link/target-and-class-are-real-attributes.snap`
```
<a href="/docs" data-jh-l="1" target="_blank" class="ext">docs</a>
```

```bp
test "link: prefetch mode table" {
    val rows = [
        "static/-/requested=" + prefetchMode("static", false, true),
        "dynamic/loading/requested=" + prefetchMode("dynamic", true, true),
        "dynamic/none/requested=" + prefetchMode("dynamic", false, true),
        "static/-/off=" + prefetchMode("static", false, false),
        "unknown/loading/requested=" + prefetchMode("unknown", true, true),
    ];
    try assertText(@src(), rows.join("\n"));
}
```
`__snapshots__/link/prefetch-mode-table.snap` — one line per row of § 8 *Prefetching*
```
static/-/requested=full
dynamic/loading/requested=partial
dynamic/none/requested=skip
static/-/off=skip
unknown/loading/requested=partial
```

```bp
test "link: idle status" {
    // the plain call, on purpose: the server-pass value. `use` is illegal in a `test` body
    // (it carries no `#[@use]`, decision 104) — 00-compiler-carry-over/19 § rule 3.
    val s = linkStatus();
    try assertText(@src(), "pending=" + s.pending.toString() + "\nhref=" + s.href);
}
```
`__snapshots__/link/idle-status.snap`
```
pending=false
href=
```

```bp
// reconcile_test.bp
import { RouterState } from "jhonstart";
import { layoutKey, layoutKeys, sharedDepth } from "jhonstart-link";
import { assertNavigation, assertText, simulateNavigation, fixtureRouter } from "jhonstart-test";

test "reconcile: layout keys are root-first and include the root" {
    try assertText(@src(), layoutKeys(["docs", "api"]).join(" ") + "\n" + layoutKey([], 0));
}
```
`modules/jhonstart-link/test/__snapshots__/reconcile/layout-keys-are-root-first-and-include-the-root.snap`
```
/ /docs /docs/api
/
```

```bp
test "reconcile: docs api to docs guides keeps the docs layout" {
    val from = fixtureRouter("/docs/api", "/docs/api", "", "");
    val to = fixtureRouter("/docs/guides", "/docs/guides", "", "");
    try assertNavigation(@src(), simulateNavigation(from, to));
}
```
`__snapshots__/reconcile/docs-api-to-docs-guides-keeps-the-docs-layout.snap`
```
from: / /docs /docs/api
to: / /docs /docs/guides
shared: 2
keep: / /docs
remount: /docs/guides
```

```bp
test "reconcile: docs to blog keeps only the root" {
    val from = fixtureRouter("/docs", "/docs", "", "");
    val to = fixtureRouter("/blog", "/blog", "", "");
    try assertNavigation(@src(), simulateNavigation(from, to));
}
```
`__snapshots__/reconcile/docs-to-blog-keeps-only-the-root.snap`
```
from: / /docs
to: / /blog
shared: 1
keep: /
remount: /blog
```

```bp
test "reconcile: the same route remounts nothing" {
    val here = fixtureRouter("/blog/hi", "/blog/[slug]", "slug=hi", "");
    try assertNavigation(@src(), simulateNavigation(here, here));
}
```
`__snapshots__/reconcile/the-same-route-remounts-nothing.snap` — layout keys are built from the pattern, so the bracket segment is the key
```
from: / /blog /blog/[slug]
to: / /blog /blog/[slug]
shared: 3
keep: / /blog /blog/[slug]
remount: 
```

Not snapshotted: `linkMount` idempotence and the island mount count across a transition — browser-only, front 53's example app.

---

## 28 · server-components — `modules/jhonstart/test/server_test.bp`

```bp
import { Element, div, span, p, h1, ul, li, article, section, h2, text, renderToString } from "jhonstart";
import { RequestData, request, cookies, headers, renderServerComponent, pairValue } from "jhonstart";
import { escape } from "std";
import { assertRequest, assertHtml, assertText, fixtureRequest } from "jhonstart-test";

test "request: fixture with a locale cookie and an auth header" {
    val r = fixtureRequest("GET", "/blog/hi", "slug=hi", "ref=home", "authorization=Bearer%20x", "locale=pt-BR");
    try assertRequest(@src(), r);
}
```
`modules/jhonstart/test/__snapshots__/request/fixture-with-a-locale-cookie-and-an-auth-header.snap`
```
method: GET
path: /blog/hi
params: slug=hi
query: ref=home
headers: authorization=Bearer%20x
cookies: locale=pt-BR
```

```bp
test "request: absent keys read as empty strings" {
    val r = fixtureRequest("GET", "/", "", "", "", "");
    val tree = span([text(r.param("slug") + "|" + r.queryParam("q") + "|" + r.header("x") + "|" + r.cookie("c"), attrs: [])], attrs: []);
    try assertHtml(@src(), tree);
}
```
`__snapshots__/request/absent-keys-read-as-empty-strings.snap`
```
<span>|||</span>
```

```bp
pub type Post(id: string, title: string, body: string)
pub type Comment(author: string, body: string)

#[@future]
fn loadPost(slug: string) -> @Future<Post> {
    return Post(id: "p1", title: "Hello, " + slug, body: "First <b>post</b>");
}

#[@future]
fn loadComments(postId: string) -> @Future<Array<Comment>> {
    return [Comment(author: "ana", body: "nice"), Comment(author: "bob", body: "<script>x</script>")];
}

fn commentRow(c: Comment) -> Element {
    return li([span([text(escape.html(c.author), attrs: [])], attrs: [#("class", "author")]), text(escape.html(c.body), attrs: [])], attrs: []);
}

#[@use]
pub fn PostPage(params: Array<#(string, string)>) -> @Component<Element> {
    val post = await loadPost(pairValue(params, "slug"));
    val comments = await loadComments(post.id);
    return article([
        h1([text(escape.html(post.title), attrs: [])], attrs: []),
        p([text(escape.html(post.body), attrs: [])], attrs: []),
        section([h2([text("Comments", attrs: [])], attrs: []), ul(comments.map({ c -> commentRow(c) }), attrs: [])], attrs: []),
    ], attrs: [#("data-post", escape.attribute(post.id))]);
}

test "ssr: server component ---- async page with params" {
    val tree = await PostPage([#("slug", "world")]);
    try assertHtml(@src(), tree);
}
```
`__snapshots__/ssr/server-component-async-page-with-params.snap` — two sequential awaits at statement level; every untrusted value through front 01's `escape`
```
<article data-post="p1"><h1>Hello, world</h1><p>First &lt;b&gt;post&lt;/b&gt;</p><section><h2>Comments</h2><ul><li><span class="author">ana</span>nice</li><li><span class="author">bob</span>&lt;script&gt;x&lt;/script&gt;</li></ul></section></article>
```

```bp
#[@use]
fn emptyPage() -> @Component<Element> {
    return div([text("ready", attrs: [])], attrs: [#("class", "done")]);
}

test "ssr: renderServerComponent awaits once and renders" {
    val html = await renderServerComponent({ ->
        emptyPage();
    });
    try assertText(@src(), html);
}
```
`__snapshots__/ssr/renderservercomponent-awaits-once-and-renders.snap`
```
<div class="done">ready</div>
```

```bp
test "ssr: a page with no comments still renders its heading" {
    val tree = article([h1([text("Solo", attrs: [])], attrs: []), section([h2([text("Comments", attrs: [])], attrs: []), ul([], attrs: [])], attrs: [])], attrs: []);
    try assertHtml(@src(), tree);
}
```
`__snapshots__/ssr/a-page-with-no-comments-still-renders-its-heading.snap`
```
<article><h1>Solo</h1><section><h2>Comments</h2><ul></ul></section></article>
```

Not snapshotted: `request()` over the six `jhonstart_server` cells (`enterRequest` beside the test; `assertRequest` over its result reproduces the first snapshot above once it is filled with the same six strings), and the compile-error case for a missing `#[@use]` (compiler suite).

---

## 29 · client-directive — `modules/jhonstart/test/client_test.bp`

```bp
import { Element, div, h1, p, span, button, text, renderToString } from "jhonstart";
import { client, clientProps, Island, clientMount, serverSlot, islandEntry, propsFor, serverOnly } from "jhonstart";
import { assertHtml, assertClientBundleEntry, assertText } from "jhonstart-test";

#[clientProps]
pub type LikeProps(postId: string, likes: i32)

#[client]
pub fn LikeButton(props: LikeProps) -> Element {
    return button([text("♥ " + props.likes.toString(), attrs: [])], attrs: [#("data-post", props.postId)]);
}

test "island: the marker is a pure function returning the name" {
    try assertText(@src(), __jhClient_LikeButton());
}
```
`modules/jhonstart/test/__snapshots__/island/the-marker-is-a-pure-function-returning-the-name.snap` — proves `@emit` fired; only under `botopink test`
```
LikeButton
```

```bp
test "island: the placeholder carries the id and nothing else" {
    val island = Island(id: "i0", component: "LikeButton", props: [#("postId", "p1"), #("likes", "3")]);
    try assertHtml(@src(), clientMount(island, []));
}
```
`__snapshots__/island/the-placeholder-carries-the-id-and-nothing-else.snap`
```
<div data-jh-i="i0"></div>
```

```bp
test "island: payload rows for two islands in render order" {
    val islands = [
        Island(id: "i0", component: "LikeButton", props: [#("postId", "p1"), #("likes", "3")]),
        Island(id: "i1", component: "Footer", props: []),
    ];
    try assertClientBundleEntry(@src(), islands);
}
```
`__snapshots__/island/payload-rows-for-two-islands-in-render-order.snap` — the `i` rows are `[id, component, props]`; the props are `querystring.stringify`
```
--- payload i
i0 LikeButton postId=p1&likes=3
i1 Footer 
--- markup
<div data-jh-i="i0"></div>
<div data-jh-i="i1"></div>
```

```bp
test "island: a provider wraps a server slot" {
    val page = div([h1([text("Dashboard", attrs: [])], attrs: []), p([text("3 open tickets", attrs: [])], attrs: [])], attrs: []);
    val island = Island(id: "i0", component: "ThemeProvider", props: [#("theme", "dark")]);
    try assertHtml(@src(), clientMount(island, [serverSlot([page])]));
}
```
`__snapshots__/island/a-provider-wraps-a-server-slot.snap` — the server subtree is inside the island, marked, and never re-rendered by the client
```
<div data-jh-i="i0"><div data-jh-s="1"><div><h1>Dashboard</h1><p>3 open tickets</p></div></div></div>
```

```bp
test "island: children of a placeholder render unmodified" {
    val island = Island(id: "i2", component: "Tabs", props: []);
    try assertHtml(@src(), clientMount(island, [span([text("first", attrs: [])], attrs: [])]));
}
```
`__snapshots__/island/children-of-a-placeholder-render-unmodified.snap`
```
<div data-jh-i="i2"><span>first</span></div>
```

```bp
test "island: server-only is a value nobody reads" {
    try assertText(@src(), "serverOnly=" + serverOnly().toString());
}
```
`__snapshots__/island/server-only-is-a-value-nobody-reads.snap`
```
serverOnly=1
```

Not snapshotted: `#[client]` on a `type`, on a `#[@future] fn … -> @Future<T>` loader, `#[clientProps]` with an `Element` field — compile failures, recorded as comments naming the expected message (`rakun/test/di_test.bp:14-16` style). `propsFor` and `hydrate()` need the browser cell.

---

## 30 · streaming — `modules/jhonstart/test/streaming_test.bp`

```bp
import { Element, div, h1, ul, li, span, header, section, text, renderToString } from "jhonstart";
import { Boundary, Suspense, holeId, Chunk, resolve, fillHtml, shellHtml } from "jhonstart";
import { assertHtml, assertStream, assertText, renderToStream } from "jhonstart-test";

#[@use]
fn postList() -> @Component<Element> {
    return ul([li([text("one", attrs: [])], attrs: []), li([text("two", attrs: [])], attrs: [])], attrs: [#("class", "posts")]);
}

fn skeleton(label: string) -> Element {
    return div([text(label, attrs: [])], attrs: [#("class", "skeleton")]);
}

fn postsBoundary(ordinal: i32) -> Boundary {
    return Boundary(id: holeId(ordinal), fallback: skeleton("Loading posts…"), child: { ->
        postList();
    });
}

fn page(b: Boundary) -> Element {
    return div([header([text("botopink", attrs: [])], attrs: []), h1([text("Blog", attrs: [])], attrs: []), section([Suspense(b)], attrs: [#("class", "main")])], attrs: [#("class", "page")]);
}

test "stream: the shell shows the fallback and not the child" {
    try assertHtml(@src(), page(postsBoundary(1)));
}
```
`modules/jhonstart/test/__snapshots__/stream/the-shell-shows-the-fallback-and-not-the-child.snap`
```
<div class="page"><header>botopink</header><h1>Blog</h1><section class="main"><div data-jh-h="h1"><div class="skeleton">Loading posts…</div></div></section></div>
```

```bp
test "stream: shell then one fill" {
    val b = postsBoundary(1);
    val chunks = await renderToStream(page(b), [b]);
    try assertStream(@src(), chunks);
}
```
`__snapshots__/stream/shell-then-one-fill.snap` — chunk 0 is `shellHtml`, chunk 1 is `fillHtml(await resolve(b), "")`; the `<template>`/`__bp1` literal is `contracts.md § 2`'s
```
--- chunk 0 (shell)
<div class="page"><header>botopink</header><h1>Blog</h1><section class="main"><div data-jh-h="h1"><div class="skeleton">Loading posts…</div></div></section></div>
--- chunk 1
<template data-jh-f="h1"><ul class="posts"><li>one</li><li>two</li></ul></template><script>__bp1("h1")</script>
```

```bp
#[@use]
fn sidebar() -> @Component<Element> {
    return div([text("related", attrs: [])], attrs: [#("class", "related")]);
}

test "stream: two boundaries ---- declaration order in the harness" {
    val posts = postsBoundary(1);
    val aside = Boundary(id: holeId(2), fallback: skeleton("Loading related…"), child: { ->
        sidebar();
    });
    val shell = div([Suspense(posts), Suspense(aside)], attrs: []);
    val chunks = await renderToStream(shell, [posts, aside]);
    try assertStream(@src(), chunks);
}
```
`__snapshots__/stream/two-boundaries-declaration-order-in-the-harness.snap` — front 30's `renderStream` hands fills over in completion order; the harness pins declaration order because it has no scheduler
```
--- chunk 0 (shell)
<div><div data-jh-h="h1"><div class="skeleton">Loading posts…</div></div><div data-jh-h="h2"><div class="skeleton">Loading related…</div></div></div>
--- chunk 1
<template data-jh-f="h1"><ul class="posts"><li>one</li><li>two</li></ul></template><script>__bp1("h1")</script>
--- chunk 2
<template data-jh-f="h2"><div class="related">related</div></template><script>__bp1("h2")</script>
```

```bp
pub fn Loading() -> Element {
    return div([span([text("Loading…", attrs: [])], attrs: [#("class", "spinner")])], attrs: [#("class", "loading")]);
}

#[@use]
fn segmentPage(params: Array<#(string, string)>) -> @Component<Element> {
    return h1([text("Page", attrs: [])], attrs: []);
}

test "stream: loading convention ---- segment shell" {
    val params: Array<#(string, string)> = [];
    val b = Boundary(id: holeId(0), fallback: Loading(), child: { ->
        segmentPage(params);
    });
    try assertText(@src(), shellHtml(Suspense(b)));
}
```
`__snapshots__/stream/loading-convention-segment-shell.snap` — what front 30's `compose` builds around a segment that has a `loading.bp` (front 22 discovers it)
```
<div data-jh-h="h0"><div class="loading"><span class="spinner">Loading…</span></div></div>
```

```bp
test "stream: hole ids are ordinals" {
    try assertText(@src(), [holeId(0), holeId(1), holeId(12)].join(" "));
}
```
`__snapshots__/stream/hole-ids-are-ordinals.snap`
```
h0 h1 h12
```

```bp
test "stream: a fill is a template plus the call that applies it" {
    try assertText(@src(), fillHtml(Chunk(id: "h1", html: "<ul></ul>"), ""));
}
```
`__snapshots__/stream/a-fill-is-a-template-plus-the-call-that-applies-it.snap`
```
<template data-jh-f="h1"><ul></ul></template><script>__bp1("h1")</script>
```

The eager-`@Future` assertion ("constructing a `Boundary` runs nothing") is the first snapshot above: a shell that contained `class="posts"` would fail it.

---

## 30 · render — `modules/jhonstart/test/render_test.bp`

The escaping walker, the composition order, the document and the payload (`contracts.md § 2`) —
the render decision 113 places in jhonstart. rakun front 23's `ssr` cases (`../03-rakun/test-snap.md`
§ 23) are the same expectations written against rakun's copy of this code; when front 30 lands they
become cases of this file, rendered through `render` with a `PageInput` fixture instead of a request.

```bp
import { Element, div, p, input, style, text } from "jhonstart";
import { renderNode, raw, compose, Segment, Payload, writePayload, globals } from "jhonstart";
import { assertText, assertDocument } from "jhonstart-test";

test "render: text is escaped" {
    try assertText(@src(), renderNode(p([text("<script>alert(1)</script>", attrs: [])], attrs: [])));
}
```
`__snapshots__/render/text-is-escaped.snap`
```
<p>&lt;script&gt;alert(1)&lt;/script&gt;</p>
```

```bp
test "render: an attribute value is escaped and a void tag is not closed" {
    try assertText(@src(), renderNode(input([], attrs: [#("value", "a \" b & c")])));
}
```
`__snapshots__/render/an-attribute-value-is-escaped-and-a-void-tag-is-not-closed.snap`
```
<input value="a &quot; b &amp; c">
```

```bp
test "render: a raw-text body is verbatim" {
    try assertText(@src(), renderNode(style([text(".a > .b{color:red}", attrs: [])], attrs: [])));
}
```
`__snapshots__/render/a-raw-text-body-is-verbatim.snap`
```
<style>.a > .b{color:red}</style>
```

```bp
test "render: raw is the one escape hatch" {
    try assertText(@src(), renderNode(raw("<b>x</b>")));
}
```
`__snapshots__/render/raw-is-the-one-escape-hatch.snap`
```
<b>x</b>
```

```bp
test "render: the payload is one script assigning the registry's global" {
    val pl = Payload(build: "build-0001", pathname: "/", pattern: "/", params: "", query: "q=</script>",
                     table: "L|/||\nP|/||", islands: [], actions: [], styles: "", holes: [], dynamic: false);
    try assertText(@src(), "<script>window." + globals.payload + " = " + writePayload(pl) + "</script>");
}
```
`__snapshots__/render/the-payload-is-one-script-assigning-the-registry-s-global.snap` — `</script` is unrepresentable (`<`), the global is `__bp0`
```
<script>window.__bp0 = {"v":1,"b":"build-0001","p":"/","r":"/","m":"","q":"q=</script>","t":"L|/||\nP|/||","i":[],"a":[],"s":"","h":[],"d":false,"k":"","z":""}</script>
```

The remaining render cases map one-to-one onto rakun's § 23 cases, with the markers and globals of
decision 113 — each asserts the document through `assertDocument` over `render(app([]), input)`:

| Case | Asserts |
|---|---|
| `render: a static page renders inside the root layout` | `<div data-jh-root="">` wraps the root layout; the payload script is last before `RenderHooks.bodyExtra` |
| `render: layouts nest root-first and the page is innermost` | `compose` order over a two-layout chain |
| `render: one segment holding all six conventions nests layout template error loading not-found page` | `data-jh-t`, `data-jh-e`, `data-jh-h`, `data-jh-n` in that nesting |
| `render: a segment without a template contributes no wrapper` | no `data-jh-t` |
| `render: a nested not-found boundary wins over the root one` | outcome `jhonstart:not-found`, the nearest `not-found` markup |
| `render: a param from the url is escaped on the way into the document` | `&lt;script&gt;` in the body, the escaped `m` in the payload |
| `render: a three-deep layout chain receives depths 0 1 2` | `selected` per layout |
| `render: fills are handed over in completion order` | two boundaries resolving in reverse order reach `write` as `h2` then `h1` |
| `render: plugins are called head once, chunk per boundary, close, then payload` | a recording plugin's call log: `head`, `chunk h1`, `chunk h2`, `close`, `payload` |
| `render: a plugin key the render owns fails` | a plugin returning `#("t", …)` fails the render naming `t`; two plugins returning `s` fail it naming both |

---

## 30 · bridge — `modules/jhonstart-emilia/test/bridge_test.bp`

The `jhonstart-emilia` member: emilia's `#[@future] flush()` adapted to the asynchronous
`RenderPlugin`, and the payload's `s` contributed through `payload` (decisions 113 and 114). The only
test file in the repository that imports both jhonstart and emilia — emilia's integration test is
this file (decision 114, item 6), and so are emilia front 48's rendered cells (builders and `html` DSL round trip with an emilia class slot, `withAttrs` / `attrValue`, static-first class order).

```bp
import { Element, div, text } from "jhonstart";
import { app, render, renderStream, holeId } from "jhonstart";
import { plugin } from "jhonstart-emilia";
import { emilia } from "emilia";
import { assertStream, renderStreamCollect, fixturePageOver, fixtureRequest } from "jhonstart-test";

// The page is built here, not in `jhonstart-test`: only this member may import emilia.
// Its outer `div` carries `emilia([.Pad.All.4])`; its one boundary's `ul` carries `emilia([.Border.Width.1])`.
test "bridge: a streamed boundary carries its style first, inside the fill" {
    val chunks = await renderStreamCollect(app([plugin()]), fixturePageOver("/blog", styledShell(), styledList), fixtureRequest("/blog"));
    try assertStream(@src(), chunks);
}
```
`__snapshots__/bridge/a-streamed-boundary-carries-its-style-first-inside-the-fill.snap` — `head` once into `<head>`; the boundary's CSS as a bare `<style>` first inside `<template data-jh-f>`; no marker on the `<style>`
```
--- chunk 0 (shell)
<!DOCTYPE html><html lang="pt-BR"><head><meta charset="utf-8"><style>.e_3f9a1c{padding:1rem}</style></head><body><div data-jh-root=""><div class="e_3f9a1c"><div data-jh-h="h1"><p>Loading…</p></div></div></div>
--- chunk 1
<template data-jh-f="h1"><style>.e_6c2d90{border-width:1px}</style><ul class="e_6c2d90"><li>one</li></ul></template><script>__bp1("h1")</script>
--- chunk 2
<script>window.__bp0 = {…,"s":["e_3f9a1c","e_6c2d90"]}</script></body></html>
```

| Case | Asserts |
|---|---|
| `bridge: head is called once` | one `<style>` in `<head>` for a non-streamed page |
| `bridge: payload carries s` | the payload's `s` lists exactly the classes of the document's `<style>` blocks, in flush order; a page with no emilia class writes `"s":[]` |
| `bridge: close refuses a leftover sheet` | a class registered after the last `chunk` makes `close` answer `Error`, and the render fails |
| `bridge: the contract-4 class literal` | the fixed token list of `contracts.md § 4` renders the same literal hex class emilia's `modules/emilia/test/attributes_test.bp` asserts without HTML — jhonstart core cannot import emilia, so this is where the rendered document and emilia's class meet |

The class names in the snapshot above are placeholders until front 56 fixes the body being hashed;
`renderStreamCollect` is the harness helper that passes a collecting `write` (`fn(string) -> @Future<void>`) and a `RequestData` to `renderStream`.

---

## 31 · error-boundaries — `modules/jhonstart/test/error_boundary_test.bp`

```bp
import { Element, div, p, h1, section, h2, button, main, htmlTag, head, body, title, a, text, renderToString } from "jhonstart";
import { ErrorInfo, ErrorBoundary, renderBoundary, renderBoundaryChecked, catchError, infoFor, serverInfoFor, isSignal, wrap } from "jhonstart";
import { assertErrorBoundary, assertHtml, assertHtmlLines, assertText } from "jhonstart-test";

fn fallback(info: ErrorInfo) -> Element {
    return div([p([text("Something went wrong" + info.message, attrs: [])], attrs: []), button([text("Try again", attrs: [])], attrs: [#("data-jh-reset", "metrics")])], attrs: [#("class", "error")]);
}

#[@result]
fn healthyPanel() -> @Result<Element, string> {
    return section([h2([text("Metrics", attrs: [])], attrs: []), p([text("99.9%", attrs: [])], attrs: [])], attrs: []);
}

#[@result]
fn failingPanel() -> @Result<Element, string> {
    throw "metrics service down: postgres://user:secret@db/metrics";
}

#[@result]
fn signallingPanel() -> @Result<Element, string> {
    throw "jhonstart:not-found";
}

#[@result]
fn panelWithHandler() -> @Result<Element, string> {
    return button([text("Like", attrs: [])], attrs: [#("data-jh-on-click", "like")]);
}

test "boundary: a healthy child renders inside the wrapper" {
    try assertErrorBoundary(@src(), catchError("metrics", fallback, healthyPanel));
}
```
`modules/jhonstart/test/__snapshots__/boundary/a-healthy-child-renders-inside-the-wrapper.snap`
```
outcome: ok
<div data-jh-e="metrics"><section><h2>Metrics</h2><p>99.9%</p></section></div>
```

```bp
test "boundary: a failing child renders the fallback and leaks nothing" {
    try assertErrorBoundary(@src(), catchError("metrics", fallback, failingPanel));
}
```
`__snapshots__/boundary/a-failing-child-renders-the-fallback-and-leaks-nothing.snap` — `info.message` is `""`, so the connection string cannot appear; the reset control is inert until hydration
```
outcome: ok
<div data-jh-e="metrics"><div class="error"><p>Something went wrong</p><button data-jh-reset="metrics">Try again</button></div></div>
```

```bp
test "boundary: a signal passes through uncaught" {
    try assertErrorBoundary(@src(), catchError("post", fallback, signallingPanel));
}
```
`__snapshots__/boundary/a-signal-passes-through-uncaught.snap` — it leaves front 30's render as the outcome onze turns into rakun's 404; the boundary never renders a fallback for it
```
outcome: error jhonstart:not-found
```

```bp
test "boundary: an event handler is outside the catch channel" {
    try assertErrorBoundary(@src(), catchError("like", fallback, panelWithHandler));
}
```
`__snapshots__/boundary/an-event-handler-is-outside-the-catch-channel.snap` — the handler is an attribute; nothing for `renderBoundary` to branch on
```
outcome: ok
<div data-jh-e="like"><button data-jh-on-click="like">Like</button></div>
```

```bp
test "boundary: the reader's digest is the server's digest" {
    val m = "boom";
    val same = infoFor(m).digest == serverInfoFor(m).digest;
    val nonEmpty = infoFor(m).digest != "";
    try assertText(@src(), "same-digest=" + same.toString() + "\nnon-empty=" + nonEmpty.toString() + "\nclient-message=" + infoFor(m).message + "\nserver-message=" + serverInfoFor(m).message + "\nsignal=" + isSignal(m).toString() + " " + isSignal("jhonstart:redirect").toString());
}
```
`__snapshots__/boundary/the-reader-s-digest-is-the-server-s-digest.snap` — the digest literal itself is front 03's snapshot, not this one
```
same-digest=true
non-empty=true
client-message=
server-message=boom
signal=false true
```

```bp
pub fn GlobalError(info: ErrorInfo) -> Element {
    return htmlTag([
        head([title([text("Error", attrs: [])], attrs: [])], attrs: []),
        body([main([p([text("Something went wrong", attrs: [])], attrs: []), p([text("Reference: " + info.digest, attrs: [])], attrs: [#("class", "digest")]), button([text("Try again", attrs: [])], attrs: [#("data-jh-reset", "root")])], attrs: [])], attrs: []),
    ], attrs: [#("lang", "en")]);
}

test "boundary: global error owns its document" {
    try assertHtmlLines(@src(), GlobalError(ErrorInfo(message: "", digest: "a3f19c2b")));
}
```
`__snapshots__/boundary/global-error-owns-its-document.snap` — `htmlTag` and `body` exactly once, both from front 94
```
<html lang="en">
<head>
<title>Error</title>
</head>
<body>
<main>
<p>Something went wrong</p>
<p class="digest">Reference: a3f19c2b</p>
<button data-jh-reset="root">Try again</button>
</main>
</body>
</html>
```

```bp
pub fn NotFound() -> Element {
    return section([h2([text("Not found", attrs: [])], attrs: []), p([a([text("Back to the blog", attrs: [])], attrs: [#("href", "/blog")])], attrs: [])], attrs: [#("class", "not-found")]);
}

test "boundary: not-found page" {
    try assertHtml(@src(), NotFound());
}
```
`__snapshots__/boundary/not-found-page.snap` — a plain `a` here: `Link` is `jhonstart-link`, which core tests do not import (dependency direction, `modules.md § 3`)
```
<section class="not-found"><h2>Not found</h2><p><a href="/blog">Back to the blog</a></p></section>
```

---

## 32 · metadata — `modules/jhonstart/test/metadata_test.bp`

```bp
import { Metadata, OpenGraph, TwitterCard, Icons, Viewport } from "jhonstart";
import { emptyMetadata, emptyOpenGraph, mergeMetadata, renderHead, viewport, mergeViewport, renderViewport, applyTemplate } from "jhonstart";
import { assertMetadata, assertViewport, assertText } from "jhonstart-test";

fn rootMetadata() -> Metadata {
    return Metadata(
        title: "botopink",
        titleTemplate: "%s | botopink",
        description: "A language and its libraries",
        openGraph: OpenGraph(title: "", description: "", url: "https://botopink.dev", ogType: "website", siteName: "botopink", images: ["/og/default.png", "/og/wide.png", "/og/square.png"]),
        twitter: TwitterCard(card: "summary_large_image", title: "", description: "", images: []),
        icons: Icons(icon: "/favicon.ico", apple: "/apple-touch-icon.png"),
    );
}

fn pageMetadata() -> Metadata {
    return Metadata(
        title: "Hello",
        titleTemplate: "",
        description: "",
        openGraph: OpenGraph(title: "Hello", description: "", url: "", ogType: "article", siteName: "", images: ["/og/hello.png"]),
        twitter: TwitterCard(card: "", title: "", description: "", images: []),
        icons: Icons(icon: "", apple: ""),
    );
}

test "metadata: empty renders nothing" {
    try assertMetadata(@src(), emptyMetadata());
}
```
`modules/jhonstart/test/__snapshots__/metadata/empty-renders-nothing.snap` — an empty file (zero bytes)
```
```

```bp
test "metadata: root layout head in fixed order" {
    try assertMetadata(@src(), rootMetadata());
}
```
`__snapshots__/metadata/root-layout-head-in-fixed-order.snap` — the template is not applied to the segment that declares it; `""` fields emit no tag
```
<title>botopink</title>
<meta name="description" content="A language and its libraries">
<meta property="og:url" content="https://botopink.dev">
<meta property="og:type" content="website">
<meta property="og:site_name" content="botopink">
<meta property="og:image" content="/og/default.png">
<meta property="og:image" content="/og/wide.png">
<meta property="og:image" content="/og/square.png">
<meta name="twitter:card" content="summary_large_image">
<link rel="icon" href="/favicon.ico">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
```

```bp
test "metadata: page merged onto root ---- template once and images wholesale" {
    try assertMetadata(@src(), mergeMetadata(rootMetadata(), pageMetadata()));
}
```
`__snapshots__/metadata/page-merged-onto-root-template-once-and-images-wholesale.snap` — strings: non-empty child replaces; lists: replace wholesale (one image, not four); nested records field by field (`og:site_name` from the root, `og:title`/`og:type` from the page)
```
<title>Hello | botopink</title>
<meta name="description" content="A language and its libraries">
<meta property="og:title" content="Hello">
<meta property="og:url" content="https://botopink.dev">
<meta property="og:type" content="article">
<meta property="og:site_name" content="botopink">
<meta property="og:image" content="/og/hello.png">
<meta name="twitter:card" content="summary_large_image">
<link rel="icon" href="/favicon.ico">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
```

```bp
fn sectionMetadata() -> Metadata {
    val m = emptyMetadata();
    return Metadata(title: "Docs", titleTemplate: "", description: "", openGraph: m.openGraph, twitter: m.twitter, icons: m.icons);
}

test "metadata: three levels apply the template once" {
    val merged = mergeMetadata(mergeMetadata(rootMetadata(), sectionMetadata()), pageMetadata());
    try assertText(@src(), merged.title + "\n" + merged.titleTemplate + "|");
}
```
`__snapshots__/metadata/three-levels-apply-the-template-once.snap` — the result's `titleTemplate` is the child's (empty), so nothing composes into `Hello | Docs | botopink | botopink`
```
Hello | botopink
|
```

```bp
test "metadata: a child with no title inherits the parent's untemplated" {
    val child = emptyMetadata();
    try assertText(@src(), mergeMetadata(rootMetadata(), child).title + "\n" + applyTemplate("%s | x", "") + "|" + applyTemplate("", "Plain"));
}
```
`__snapshots__/metadata/a-child-with-no-title-inherits-the-parent-s-untemplated.snap`
```
botopink
|Plain
```

```bp
test "metadata: markup in a title and a quote in a description are escaped" {
    val m = emptyMetadata();
    val hostile = Metadata(title: "<script>alert(1)</script> & co", titleTemplate: "", description: "She said \"hi\"", openGraph: m.openGraph, twitter: m.twitter, icons: m.icons);
    try assertMetadata(@src(), hostile);
}
```
`__snapshots__/metadata/markup-in-a-title-and-a-quote-in-a-description-are-escaped.snap` — `escape.html` for the element text, `escape.attribute` for the attribute
```
<title>&lt;script&gt;alert(1)&lt;/script&gt; &amp; co</title>
<meta name="description" content="She said &quot;hi&quot;">
```

```bp
test "metadata: viewport renders both tags" {
    try assertViewport(@src(), Viewport(width: "device-width", initialScale: "1", themeColor: "#0b0b0b"));
}
```
`__snapshots__/metadata/viewport-renders-both-tags.snap`
```
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="theme-color" content="#0b0b0b">
```

```bp
test "metadata: viewport merge picks the child colour and keeps the parent width" {
    val parent = Viewport(width: "device-width", initialScale: "1", themeColor: "#ffffff");
    val child = Viewport(width: "", initialScale: "", themeColor: "#0b0b0b");
    try assertViewport(@src(), mergeViewport(parent, child));
}
```
`__snapshots__/metadata/viewport-merge-picks-the-child-colour-and-keeps-the-parent-width.snap`
```
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="theme-color" content="#0b0b0b">
```

```bp
test "metadata: an empty viewport renders nothing" {
    try assertViewport(@src(), Viewport(width: "", initialScale: "", themeColor: ""));
}
```
`__snapshots__/metadata/an-empty-viewport-renders-nothing.snap` — empty file
```
```

---

## 67 · forms — `modules/jhonstart-forms/test/form_state_test.bp` and `form_test.bp`

Front 67 Step 1 names `parseActionState`'s parameter `envelope`; its example passes the bare `state` string. This map takes the README's signature — the flat string `__jhFormSubmit` returns — and `stubEnvelope` builds it.

```bp
// form_state_test.bp
import { ActionState, actionState, parseActionState } from "jhonstart-forms";
import { assertActionState, assertText, stubEnvelope } from "jhonstart-test";

val goldenState = "message=Title%20must%20be%20at%20least%203%20characters&f.title=Too%20short";

test "form-state: golden fixture decodes to a message and a field error" {
    try assertActionState(@src(), parseActionState(stubEnvelope(false, goldenState, "")));
}
```
`modules/jhonstart-forms/test/__snapshots__/form-state/golden-fixture-decodes-to-a-message-and-a-field-error.snap` — the same literal front 24's encoder test asserts it produces
```
ok: false
message: Title must be at least 3 characters
redirectTo: 
f.title: Too short
```

```bp
test "form-state: an empty envelope is idle, not a failure" {
    try assertActionState(@src(), parseActionState(""));
}
```
`__snapshots__/form-state/an-empty-envelope-is-idle-not-a-failure.snap` — equals `actionState("")`
```
ok: true
message: 
redirectTo: 
```

```bp
test "form-state: ok and redirect come from the envelope, never from state" {
    val state = "ok=0&message=Saved&redirect=%2Fevil";
    try assertActionState(@src(), parseActionState(stubEnvelope(true, state, "/blog/hello")));
}
```
`__snapshots__/form-state/ok-and-redirect-come-from-the-envelope-never-from-state.snap` — the `ok` and `redirect` keys inside `state` are neither `message` nor `f.`-prefixed and are ignored
```
ok: true
message: Saved
redirectTo: /blog/hello
```

```bp
test "form-state: a percent-encoded value with ampersand and equals round-trips" {
    val state = "message=a%26b%3Dc&f.q=x%3Dy%26z";
    try assertActionState(@src(), parseActionState(stubEnvelope(false, state, "")));
}
```
`__snapshots__/form-state/a-percent-encoded-value-with-ampersand-and-equals-round-trips.snap`
```
ok: false
message: a&b=c
redirectTo: 
f.q: x=y&z
```

```bp
// form_test.bp
import { Element, text, fragment, p, form, input, label, button, renderToString } from "jhonstart";
import { FormBinding, formAction, formAttrs, hiddenActionField, actionState, FormStatus, formStatus, applyOptimistic, SearchFormProps, searchFormProps, searchFormAttrs, ActionState, newActionState, parseActionState } from "jhonstart-forms";
import { assertForm, assertText, assertOptimistic, stubEnvelope } from "jhonstart-test";

val actionId = "a_9f31c0d7a4b2e5081c6fa3d2";
val goldenState = "message=Title%20must%20be%20at%20least%203%20characters&f.title=Too%20short";

fn createPostForm(binding: FormBinding, state: ActionState, pending: bool) -> Element {
    val message = state.fieldError("title");
    val line = if (message == "") { fragment([], attrs: []) } else { p([text(message, attrs: [])], attrs: [#("class", "field-error")]) };
    val submit = if (pending) { [#("type", "submit"), #("disabled", "disabled")] } else { [#("type", "submit")] };
    val caption = if (pending) { "Creating…" } else { "Create post" };
    return form([
        hiddenActionField(binding),
        label([text("Title", attrs: [])], attrs: [#("for", "title")]),
        input([], attrs: [#("id", "title"), #("name", "title"), #("required", "required")]),
        line,
        button([text(caption, attrs: [])], attrs: submit),
    ], attrs: formAttrs(binding));
}

test "form: binding attributes and the hidden action field" {
    try assertForm(@src(), createPostForm(formAction(actionId, "/blog/new"), actionState(""), false));
}
```
`modules/jhonstart-forms/test/__snapshots__/form/binding-attributes-and-the-hidden-action-field.snap` — `contracts.md § 3`'s markup: `method`, `action` (the current pathname), `data-jh-a`, then the hidden `__bp_action`; this is the un-hydrated POST
```
<form method="post" action="/blog/new" data-jh-a="a_9f31c0d7a4b2e5081c6fa3d2">
<input type="hidden" name="__bp_action" value="a_9f31c0d7a4b2e5081c6fa3d2">
</input>
<label for="title">Title</label>
<input id="title" name="title" required="required">
</input>
<button type="submit">Create post</button>
</form>
```

```bp
test "form: a field message lands beside its field" {
    val state = parseActionState(stubEnvelope(false, goldenState, ""));
    try assertForm(@src(), createPostForm(formAction(actionId, "/blog/new"), state, false));
}
```
`__snapshots__/form/a-field-message-lands-beside-its-field.snap` — an `ok: false` envelope re-renders the form in place; no boundary, no lost input
```
<form method="post" action="/blog/new" data-jh-a="a_9f31c0d7a4b2e5081c6fa3d2">
<input type="hidden" name="__bp_action" value="a_9f31c0d7a4b2e5081c6fa3d2">
</input>
<label for="title">Title</label>
<input id="title" name="title" required="required">
</input>
<p class="field-error">Too short</p>
<button type="submit">Create post</button>
</form>
```

```bp
test "form: an in-flight submit disables and renames the button" {
    try assertForm(@src(), createPostForm(formAction(actionId, "/blog/new"), actionState(""), true));
}
```
`__snapshots__/form/an-in-flight-submit-disables-and-renames-the-button.snap`
```
<form method="post" action="/blog/new" data-jh-a="a_9f31c0d7a4b2e5081c6fa3d2">
<input type="hidden" name="__bp_action" value="a_9f31c0d7a4b2e5081c6fa3d2">
</input>
<label for="title">Title</label>
<input id="title" name="title" required="required">
</input>
<button type="submit" disabled="disabled">Creating…</button>
</form>
```

```bp
test "form: the server pass of actionState is the initial state and not pending" {
    // the plain call, on purpose: the server-pass value (`use` is illegal in a `test` body)
    val s = actionState(actionId, newActionState(""));
    val state = s.0;
    val binding = s.1;
    val pending = s.2;
    try assertText(@src(), "ok=" + state.ok.toString() + " message=" + state.message + "\naction=" + binding.actionId + " path=" + binding.pathname + "\npending=" + pending.toString());
}
```
`__snapshots__/form/the-server-pass-of-actionstate-is-the-initial-state-and-not-pending.snap` — read positionally (tuple labels are lost through generic instantiation); the pathname is the current route's, supplied by the binding
```
ok=true message=
action=a_9f31c0d7a4b2e5081c6fa3d2 path=/blog/new
pending=false
```

```bp
test "form: idle form status" {
    // the plain call, on purpose: the server-pass value
    val s = formStatus();
    try assertText(@src(), "pending=" + s.pending.toString() + " actionId=" + s.actionId + " method=" + s.method);
}
```
`__snapshots__/form/idle-form-status.snap`
```
pending=false actionId= method=post
```

```bp
test "form: optimistic fold ---- three likes" {
    try assertOptimistic(@src(), 0, [1, 1, 1]);
}

test "form: optimistic fold ---- no prediction is the identity" {
    try assertOptimistic(@src(), 41, []);
}
```
`__snapshots__/form/optimistic-fold-three-likes.snap`
```
base: 0
actions: 1 1 1
value: 3
```
`__snapshots__/form/optimistic-fold-no-prediction-is-the-identity.snap`
```
base: 41
actions: 
value: 41
```

```bp
fn searchForm(props: SearchFormProps) -> Element {
    return form([input([], attrs: [#("name", "q")]), button([text("Search", attrs: [])], attrs: [#("type", "submit")])], attrs: searchFormAttrs(props));
}

test "form: a search form is a GET form the action interceptor does not claim" {
    try assertForm(@src(), searchForm(searchFormProps("/search")));
}
```
`__snapshots__/form/a-search-form-is-a-get-form-the-action-interceptor-does-not-claim.snap` — `data-jh-sf`, not `data-jh-a`; un-hydrated the browser's own GET produces the same URL
```
<form method="get" action="/search" data-jh-sf="1">
<input name="q">
</input>
<button type="submit">Search</button>
</form>
```

Not snapshotted: `__jhFormSubmit`/`__jhFormPending`/`__jhFormState`/`__jhFormMount` (no DOM under `botopink test`); a `redirectTo` driving `push` once; two concurrent submits — front 53's example app. `formAction` refusing a malformed id is a plain `assert` on the rejection, not a snapshot.

---

## Coverage — acceptance criteria to snapshots

| Front | Criteria answered by a snapshot above | Left to plain `assert` or another front |
|---|---|---|
| 94 | signature parity (tag/attrs), attribute order, verbatim attribute, void drop + frozen `</input>`, renamed tags, `el`, both predicates, DSL resolution ×3 | escaping (01/30), self-closing in markup (frozen) |
| 26 | `RouterState` accessors, absent key, first-match, `segments` bracket spelling, out-of-range `segment`, active nav ×2, search round-trip | `snapshot()` over the stub module, verbs return, `use` type-check |
| 27 | seven attribute rows, `linkProps` defaults, `with*`, `prefetchMode` ×5, `layoutKey`/`layoutKeys`, `sharedDepth` ×3, idle `linkStatus` | mount idempotence, island mount count, route-kind flag read |
| 28 | `RequestData` accessors present/absent, two sequential awaits, escaping at entry, `renderServerComponent` | `request()` over the filled context, missing-`#[@use]` compile error |
| 29 | emitted marker, placeholder id-only, payload rows, `serverSlot` hole, children unmodified, `serverOnly` | decorator rejections (compile), `propsFor`, `hydrate` |
| 30 | shell without child, fill literal, hole ids, two boundaries, `loading.bp` shell, `resolve` via the stream | adoption rules (`render.mjs`, 68's entry) |
| 30 · render | escaping walker ×6, composition order, document + payload, payload escaping, plugin order, globals registry, completion-order fills | the concurrency timing cell (plain `assert`), `render.mjs` DOM idempotence (browser) |
| 30 · bridge | head once, fill carries its style first, `close` refuses a leftover, contract-4 class literal | emilia's own rule bodies (05-emilia) |
| 31 | ok/error branches, empty client message, signal pass-through, handler outside the channel, digest agreement, `global-error` document, not-found page | `data-jh-e` routing of a transition failure (68), digest literal (03) |
| 32 | empty, fixed order, template once, images wholesale, nested merge, three levels, inherit untemplated, escaping, viewport ×3 | — |
| 67 | golden fixture, idle envelope, envelope-vs-state keys, percent round-trip, binding markup, field message in place, pending button, server pass of `actionState`, idle `formStatus`, optimistic ×2, GET form | browser cells, `redirectTo → push`, malformed id refusal |

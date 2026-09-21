# Front 23 — Rakun SSR Pipeline

**Track:** B rakun
**Priority:** critical — this is the front where "Erlang is the server" stops being a slogan: the
render Next.js performs on the server happens here, on BEAM, and everything the browser later does
starts from the bytes this front writes
**Target:** both — boundary. The render, the escaping and the chunk writer are erlang; the payload
reader and the streaming-hole swapper are js; the payload format is the contract between them
**Wave:** 5
**Depends on:** 04 (BEAM runtime), 22 (route table and layout chain), 06 (scopes), 62 (request
context — `headers()`, `cookies()`, `after()`, per-request memoization), 28 (server components), 02
(`async.all` over unstarted thunks), 01 (`escape.html` / `escape.attribute`), 03 (content hash for the
build id), 94 (`isVoidTag`, `isRawTextTag`, and the element surface the walker renders)
**Owns:** `repository/rakun/src/ssr.bp` — including the `RenderHooks` record, its no-op default and
every call site that reads it (decision 77: the head extras, the body scripts, the style sink and
`islandAttr` are *fields of this record*, declared here and filled by whoever boots the app) —
`repository/rakun/src/ssr.mjs`, `repository/rakun/src/sidecars/rakun_ssr.erl`,
`repository/rakun/test/ssr_test.bp`
**Does not touch:** `repository/rakun/src/http.bp`, `src/decorators.bp`, `src/bootstrap.bp`,
`src/runtime.mjs` (frozen), `repository/jhonstart/src/element.bp` (frozen), the files owned by
22 · 24 · 25, and `repository/onze/**` — no file of this front names a bundler, a stylesheet
pipeline or the framework that installs them; they arrive as `RenderHooks` values
**Reference:** `NEXTJS-DOCS.md § 5. Layouts e Páginas`, `§ 7. Server e Client Components`,
`§ 13. Streaming`, `§ 4. Hierarquia de renderização` ·
<https://nextjs.org/docs/app/getting-started/layouts-and-pages> ·
<https://nextjs.org/docs/app/getting-started/server-and-client-components> ·
<https://nextjs.org/docs/app/api-reference/file-conventions/loading>
**Replaces:** `1.0.7-beta/09-rakun-ssr-pipeline`

---

## Problem

`rakun` answers requests with `Response(status, body)` where the body is whatever string a handler
returned (`repository/rakun/src/http.bp:45-73`). `jhonstart` can turn an `Element` tree into markup
with `renderToString` (`repository/jhonstart/src/element.bp:55-67`). Nothing joins the two: there is
no function that takes a URL, finds the page, wraps it in its layouts, renders the tree, wraps the
result in a document, and hands back bytes. That function is this front.

It is also the front where a security requirement gets decided, and the current answer is wrong.
`renderToString` concatenates: a `#text` node returns `e.value` verbatim and an attribute becomes
`" " + a._0 + "=\"" + a._1 + "\""` with no escaping anywhere
(`repository/jhonstart/src/element.bp:56-66`). Render a post title containing `<script>` through it
and you have shipped it. `element.bp` is frozen for this milestone (`fronts.md`), so this front cannot
fix `renderToString`; it must render with its own walker and never call the unescaped one on anything
that came from a request, a database or a file.

And it is where the two halves of the milestone meet. The server render produces markup a browser can
display before any JavaScript arrives — that is the whole point of rendering on BEAM. But a client
component needs to find its own server-rendered DOM, know which props it was given, and know which
route it is on, without re-fetching the page. That requires a serialized payload with a format both
sides agree on, and there is no such format today, in any of the three drafts.

## Current state

- `repository/jhonstart/src/element.bp:55-67` — `renderToString`. No escaping, no void elements
  (`<input>` would render as `<input></input>`), no document shell.
- `repository/jhonstart/src/element.bp:10-53` — eight constructors: `text, fragment, div, span, p,
  h1, ul, li`, plus `bracketPair`. `Element` itself is a public record, so any tag can be built
  through the constructor even where a named builder is missing.
- `repository/jhonstart/src/server.d.bp:9-18` — server components are declared and gated: "not yet
  expressible". Front 28 promotes that file; this front consumes what it promotes.
- `repository/rakun/src/http.bp:45-78` — `Response` has `status` and `body` and nothing else. No
  headers, no streaming body, no cookie jar.
- `repository/emilia/src/emilia.bp:62-65` — `flush()` is `#[@future]`, serialises the sheet into
  `<style>…</style>` and clears it. Calling it twice yields an empty second block, so the pipeline has
  exactly one place it may be called.
- `repository/rakun/src/ssr.bp` does not exist.

## Mechanism

### What Next.js does

A request resolves to a segment chain. Each segment contributes, in a fixed order
(`§ 4. Hierarquia de renderização`): `layout`, then `template`, then the `error` boundary, then the
`loading` boundary, then `not-found`, then `page` or the next nested layout. Server components run on
the server and never reach the browser; client components render once on the server for markup and
again in the browser for behaviour (`§ 7`). Anything slow sits behind a Suspense boundary and its
markup arrives in a later chunk (`§ 13`).

### How it maps onto botopink

**The pipeline, end to end, on BEAM:**

```
request
  -> 22  matchPath(table, pathname)            the entry + params + rest
  -> 22  layoutChain(table, pattern)           the layouts, root-first
  -> 62  request scope opens, setPhase(Render)   headers, cookies, memo cache
  -> 28  await the page's @Future<Element>     server components resolve here
  -> 23  compose(chain, page)                  layout > template > error > loading > not-found > page
  -> 23  renderNode(tree)                      escaping walker, void-aware
  -> 23  document(shell, payload, chunks)      the bytes
  -> 04  the BEAM transport writes them
```

**Composition order is a single function and it is tested, not asserted in prose.**

```bp
pub fn compose(chain: RouteEntry[], page: Element) -> Element
```

Front 26's router state maps one-to-one onto `p`/`m`/`q`/`r`, with one exception: `selected`, the
layout depth, has no payload key because it is per-layout rather than per-document. This front passes
it into each layout render — the root layout receives `0`, the next one down `1`, and so on — so a
layout can tell how deep it sits without re-deriving it from the pattern.

For each segment, root-first, the page is wrapped from the inside out: the `page` is innermost, then
`not-found`, then `loading`, then `error`, then `template`, then `layout`. So the outermost element of
the finished tree is the root layout, and the order in which the boundaries nest matches
`§ 4` exactly. `template.bp` sits inside its own `layout.bp` and carries a fresh key per navigation
(`data-onze-t="<pattern>#<nav>"`), which is what makes it re-mount on the client while the layout
around it does not.

**Awaiting children, and why `@Future` is not concurrency here.** Two constraints stack, and getting
either wrong makes the pipeline wrong in the place it is hardest to notice.

First: `@Future<T>` **lowers eagerly on erlang**. `libs/std/src/http.bp:16-18` says it outright —
"Erlang is eager: `@Future<T>` resolves to `T` in the eager-lowering arm documented in
`codegen/erlang.zig`, so the caller's `await fetch(url)` is identity on that backend." A `@Future` on
the target this front compiles for is a value that has already been computed. Calling two loaders and
awaiting both afterwards runs them one after the other, at full latency, and no test that only checks
the markup will ever say so.

Second: a `#[@future]` fn cannot `await` inside a `loop` or a `.map` closure — the effect marker
attaches to the function, not to the closure, and no library in the checkout does it.

So the pipeline never awaits in a loop, and it never hands anything an already-started future. It
builds an `Array<fn() -> @Future<Element>>` — **unstarted thunks**, one per unit of work — and passes
that to front 02's `async.all`, which spawns a BEAM process per thunk and gathers the results by
index. Concurrency on the server comes from spawned processes, not from the `@Future` type. Front 30's
streaming has the same constraint, and this front hands it thunks for the same reason.

```bp
var tasks: Array<fn() -> @Future<Element>> = [];
loop (children) { c ->
    tasks.push({ -> renderChild(c) });
};
val rendered = await async.all(tasks);
```

**The phase word.** The pipeline calls front 62's `setPhase(RequestPhase.Render)` before it renders
anything and restores the previous phase when it is done. That is not bookkeeping: it is the same
word front 12's `rkCachePhase()` reads to decide whether a revalidation is legal, so a pipeline that
skips it makes `revalidatePath` raise from inside an action (front 24 sets `Action`, front 25 sets
`Handler`). The phase table in `contracts.md § 5` is enforced, which also means `cookies().set(...)`
from a render raises — see step 6. `searchParams` marks the render dynamic through
`markDynamic("searchParams")`, not through a flag this front keeps.

**Escaping is the render, not a step before it.** `renderNode` is a full re-implementation of the
walk in `element.bp:55-67` with four differences, and it is what every path in this front calls:

| Node | `renderToString` today | `renderNode` here |
|---|---|---|
| `#text` | `e.value` verbatim | `escape.html(e.value)` — front 01 |
| `#text` inside a raw-text tag | `e.value` verbatim | `e.value` verbatim, and a body containing `</script` or `</style` is **refused** |
| attribute | `name="value"` verbatim | `name="` + `escape.attribute(value)` + `"` |
| a void tag | `<input></input>` | `<input …>`, no closing tag |
| `#raw` | renders `<#raw>` | `e.value` verbatim, the single documented escape hatch |

`escape.html` covers `&`, `<`, `>`; `escape.attribute` adds `"` and `'`. Both are new in front 01 and
written in pure botopink. `#raw` is built through the public
`Element` record — `Element(tag: "#raw", value: html, children: [], attrs: [])` — so this front adds
it without touching the frozen `element.bp`. Every use of `#raw` in the milestone is a place a
reviewer must look at, and there are exactly two: the emilia `<style>` block and the payload script.

**Two tag predicates, and neither of them is a list kept here.** `isVoidTag(tag)` and
`isRawTextTag(tag)` are **front 94's** and are imported. The void set is not restated in this file:
two lists that must agree and are written twice will not agree for long, and the second one is always
the stale one.

`isRawTextTag` covers `script` and `style`, whose bodies are not parsed as markup. Escaping them
would silently change the program — `escape.html` applied to a CSS body turns `a > b` into
`a &gt; b`, and applied to a script body it turns working code into text — so `renderNode` emits a
raw-text body verbatim. That is safe only because the one sequence that can close the element early
is refused rather than escaped: a `script` or `style` body containing `</script` or `</style`
(case-insensitive, matching the HTML parser's own rule) fails the render with the tag named, instead
of being quietly rewritten into something that no longer runs. Refusing is the restrictive answer and
there is no flag that turns it into escaping.

Note what this means for the frozen renderer: `renderToString` still writes `</input>` and still
escapes nothing, so the assertion in front 24's example that `</input>` is absent holds **through
`renderNode` only**. A test that renders a form with `renderToString` will see `</input>` and is
testing the wrong function, not finding a bug.

**The document.**

```html
<!DOCTYPE html><html lang="pt-BR"><head><meta charset="utf-8">…metadata from front 32…
<style>…emilia flush()…</style>…RenderHooks.headExtra(route)…</head><body>
<div data-onze-root="">…composed tree…</div>
…fill chunks…
<script id="__onze" type="application/json">{…payload…}</script>
…RenderHooks.bodyExtra(route)…
</body></html>
```

`emilia.flush()` is called exactly once per document, after the tree is rendered and before the head
is written, because flushing clears the sheet (`repository/emilia/src/emilia.bp:53-56`). Rendering
first and writing the head second is why the pipeline builds the body string before the document
string rather than streaming the head first — except in streaming mode, where the head must go out
early and the sheet is instead flushed into the shell's `<style>` with the class names of the
already-rendered part, and later chunks carry their own `<style>` blocks.

### `RenderHooks` — the one seam, and it points inwards

A full-stack framework built on this pipeline has three things to add to a document: stylesheet
`<link>`s and blocking scripts in the head, the deferred bundle tags after the payload, and a style
sink that decides *when* the sheet is serialised in a streamed response. None of that may be reached
for from here: an edge from `rakun` to a bundler would make the server depend on the toolchain that
packages it, and `rakun` would stop being usable without one.

So this front declares a record of function values and reads it; it never imports an implementation.

```bp
pub type RenderHooks(
    headExtra: fn(string) -> string,           // route -> extra <head> markup; default ""
    bodyExtra: fn(string) -> string,           // route -> markup after the payload tag; default ""
    islandAttr: fn(i32) -> #(string, string),  // ordinal -> the marker pair; default per contracts.md § 2
    openSink: fn() -> void,                    // called before anything renders
    collectHead: fn() -> string,               // once, after the shell, before the head is serialised
    collectChunk: fn(string) -> string,        // holeId -> the block that precedes that chunk
    closeSink: fn() -> string,                 // after the last chunk; "" when nothing was dropped
)

pub fn defaultHooks() -> RenderHooks
pub fn setHooks(h: RenderHooks) -> void
```

The four sink fields carry no state in their signatures: the sheet is already process-local
(`emilia.bp:23-30`) and rakun serves each request in its own BEAM process, so the implementation
holds whatever it needs and rakun holds nothing it would have to name a type for.

`defaultHooks()` is a working document: no extra tags, the marker pair of `contracts.md § 2`, and a
sink that flushes once into the head. An app with no bundler renders correctly through it. A
framework installs its own at boot — the call is one line in *its* code, not in this front's — and
the record is the whole of the seam: `ssr.bp` names no library that fills it, and the fronts that
do (onze [68](../../06-onze/68-onze-client-bundle/README.md) for the tags,
[69](../../06-onze/69-onze-styling-pipeline/README.md) for the sink) depend on this front, not the
other way round. `islandAttr` is a field because the marker belongs to whoever decides *which*
components are islands — jhonstart [29](../../04-jhonstart/29-jhonstart-client-directive/README.md)
— while the ordinals are assigned here; one definition, passed in, never two that must agree.

**Rules, checked by this front's gate:**
- A document rendered with `defaultHooks()` contains no `<script src>` and exactly one `<style>`.
- `grep` over `repository/rakun/src/` finds no occurrence of `onze` outside the `data-onze-*` marker
  names and `__onzeFill`, which are `contracts.md § 2` strings, not module references.
- Replacing one field leaves the others at their defaults — the record is filled field by field, not
  all or nothing.

### The payload — the exact boundary format

One `<script id="__onze" type="application/json">` element, the last thing in `<body>` before the
client bundle. JSON is the right choice here precisely because only the browser parses it: the server
writes it by concatenation and `std/json`'s lack of a structured walker never comes up.

| Key | Type | Meaning |
|---|---|---|
| `v` | int | payload version. `1`. A client that does not recognise it refuses to hydrate rather than guessing |
| `b` | string | build id — front 03's content hash of the build. Also the salt for front 24's action ids |
| `p` | string | the request pathname, already matched |
| `r` | string | the matched page pattern, e.g. `/blog/[slug]` |
| `m` | string | path params, querystring-encoded: `slug=hello-world` |
| `q` | string | search params, querystring-encoded |
| `t` | string | the route table, front 22's `kind\|pattern\|slot\|verb` blob, `\n`-separated |
| `i` | array | islands: `[id, component, props]`, props querystring-encoded |
| `a` | array | actions this document references: `[name, id]` — front 24 fills it |
| `s` | string | the emilia class names already in the document's `<style>`, space-separated, so the client never re-flushes them |
| `h` | array | streaming hole ids still open when the shell was flushed |
| `d` | bool | whether this render was dynamic (front 60 reads it; `searchParams`, `cookies()` or `headers()` set it) |
| `k` | string | route kinds — front 60's static/dynamic/revalidate blob, joined on `pattern` |
| `z` | string | slot states — front 61's "which `@slot` rendered for which pattern" blob, joined on `pattern` |

`k` and `z` are allocated by this front and written by fronts 60 and 61. They are **separate blobs
joined on `pattern`** rather than extra columns in `t`, so contract 1 — the route table — stays
untouched and its round-trip test keeps testing four fields. A front that wants a per-pattern fact
gets a key here; it does not widen the table.

`m`, `q` and island props are querystring-encoded rather than nested JSON because both halves must be
able to read them with the same botopink code (std's `querystring`), and because a flat string is the
only shape that survives the BEAM side without a JSON walker.

**Payload escaping.** `<`, `>` and `&` are written as `<`, `>`, `&`, and U+2028/U+2029
as ` `/` `. `</script` is therefore unrepresentable inside the block, which is the property
that makes an inert `type="application/json"` script safe to carry attacker-controlled strings.

**Island markers.** A client component renders on the server inside a marker element the client can
find:

```html
<div data-onze-i="i0">…server-rendered markup…</div>
```

`i0` indexes the payload's `i` array. **Island ids are assigned by this front, in render order**:
`i0`, `i1`, `i2`, … The component name and the props live in `i`, never on the element. The client
bundle (front 68) walks `[data-onze-i]` in document order, looks each id up, and mounts. Front 29
decides *which* components are islands and defines the attribute pair; this front assigns the
ordinals, reads the pair through `RenderHooks.islandAttr`, and guarantees the marker and the index
agree. The marker registry for every `data-onze-*` prefix is `contracts.md § 2`; no front invents
one.

### Streaming

`§ 13`. The response goes out as an ordered list of chunks; front 04's transport writes them.

1. **Shell.** Doctype, head, open body, the composed tree with each Suspense boundary rendered as
   `<div data-onze-h="h1">…fallback…</div>`. The payload's `h` lists every hole still open.
2. **Fill.** One per resolved boundary, in resolution order:
   `<template data-onze-f="h1">…markup…</template><script>__onzeFill("h1")</script>`.
   `__onzeFill` lives in `ssr.mjs` and is part of the client bundle; it moves the template's content
   into the hole and removes the marker.
3. **Tail.** The payload script, the bundle script, `</body></html>`.

A boundary that resolves before the shell is flushed is inlined and never becomes a hole. **Hole ids
are assigned by this front as ordinals in shell order** — `h1`, `h2`, `h3`, … — and are not derived
from the route, the pattern or the boundary's position in the tree; front 30 designed against that.
Front 30 owns the Suspense boundaries; this front owns the ids and the chunk protocol, and guarantees
that a hole id in `h` is filled by exactly one fill chunk.

### `searchParams` and dynamic rendering

Reading `route.query` marks the render dynamic: the pipeline sets payload `d` to true and tells front
60 not to serve or store a prerendered entry. The same applies to any of front 62's request APIs. The
marking is done by the accessor, not by a developer remembering to declare it, because the one that
is remembered is not the one that leaks.

## Steps

### Step 1 — The rendered page, and why it is not a `Response`

```bp
pub type RenderedPage(
    status: i32,
    headers: Array<#(string, string)>,
    chunks: string[],
)

pub fn toResponse(page: RenderedPage) -> Response
```

**Acceptance:**
- [ ] `RenderedPage` carries headers and an ordered chunk list; `toResponse` joins the chunks and is
      used only on the non-streaming path.
- [ ] `Content-Type: text/html; charset=utf-8` is present on every `RenderedPage` this front produces.

### Step 2 — Composition order

```bp
pub fn compose(chain: RouteEntry[], page: Element) -> Element
```

**Acceptance:**
- [ ] For a chain of one segment holding all six conventions, the rendered nesting is
      `layout > template > error > loading > not-found > page`, asserted on the markup string.
- [ ] For `/blog/[slug]`, the root layout is the outermost element and the page is innermost.
- [ ] A segment with no `template.bp` contributes no wrapper — the nesting shrinks, it does not gain
      an empty `div`.
- [ ] A `template` wrapper carries `data-onze-t` with the segment pattern and the navigation counter;
      two renders of the same route produce two different values.
- [ ] Layout props are a record, not three positional arguments: `LayoutProps(route, children, slots)`
      — parameter defaults are never applied, so one uniform arity is the only shape that survives.

### Step 3 — The escaping walker

```bp
pub fn renderNode(e: Element) -> string
pub fn raw(html: string) -> Element
```

**Acceptance:**
- [ ] `renderNode(text("<script>alert(1)</script>", attrs: []))` contains no `<`.
- [ ] An attribute value containing `"` renders as `&quot;` and the produced tag re-parses.
- [ ] `renderNode(Element(tag: "input", value: "", children: [], attrs: [...]))` emits no closing tag.
      The void set is front 94's `isVoidTag`; this front keeps no list of its own, checked by grep in
      its own gate.
- [ ] A `style` body containing `a > b` renders verbatim — `renderNode` does not turn it into
      `a &gt; b` — and the same holds for a `script` body containing `&&`.
- [ ] A `script` or `style` body containing `</script` or `</style`, in any case, **fails the render**
      with the tag named. It is not escaped, and no configuration makes it escaped.
- [ ] `isRawTextTag` is front 94's; a raw-text body is the only text this walker does not escape, and
      `#raw` is the only element.
- [ ] `renderNode(raw("<b>x</b>"))` is `<b>x</b>` exactly.
- [ ] `renderNode` and `renderToString` produce the same string for a tree with no special characters
      — the walker is a superset, not a divergence.
- [ ] No path in `ssr.bp` calls `renderToString`. Checked by grep in the front's own gate, because a
      single call is the whole hole.

### Step 4 — The document and the payload

```bp
pub type Payload(
    build: string,
    pathname: string,
    pattern: string,
    params: string,
    query: string,
    table: string,
    islands: Array<#(string, string, string)>,
    actions: Array<#(string, string)>,
    styles: string,
    holes: string[],
    dynamic: bool,
)

pub fn writePayload(p: Payload) -> string
pub fn payloadEscape(json: string) -> string
#[@future]
pub fn document(head: string, body: string, p: Payload) -> @Future<string>
```

**Acceptance:**
- [ ] `writePayload` emits `v` first and `1` as its value.
- [ ] `payloadEscape` leaves no literal `<`, `>` or `&` in its output, and a payload whose params
      contain `</script>` produces a document with exactly two `</script>` occurrences — the two real
      script closers.
- [ ] `document` calls `emilia.flush()` exactly once; a second render in the same process produces a
      non-empty `<style>` again, proving the sheet was not drained by a stray earlier flush.
- [ ] The payload's `t` equals `rkAppTable()` verbatim, with `\n` escaped by the JSON writer.
- [ ] The payload's `s` lists exactly the class names present in the document's `<style>` block.
- [ ] For the fixed token list of contract 4's shared fixture, the document's `<style>` and the `s`
      key carry the **same literal hex class** that `emilia/test/integration_test.bp` asserts — the
      literal, not a recomputation. Front 68's bundle test asserts the same one. If the three differ,
      hydration is broken and this test is red before a user sees it. The literal is regenerated
      exactly once, when front 56 lands and changes the body being hashed.
- [ ] Parsing the emitted JSON in `ssr.mjs` and re-serialising it yields the same field set — the
      round trip is the test, not two half-tests.

### Step 5 — Streaming chunks

```bp
#[@future]
pub fn renderStreaming(pathname: string, query: string) -> @Future<RenderedPage>
```

**Acceptance:**
- [ ] A page with one boundary produces at least three chunks and the first one ends inside `<body>`.
- [ ] Every id in the payload's `h` appears in exactly one `data-onze-f` template in a later chunk.
- [ ] Hole ids are `h1`, `h2`, … in shell order, and a page whose boundaries resolve in reverse order
      still numbers them in shell order.
- [ ] Island ids are `i0`, `i1`, … in render order, and the payload's `i` array is in the same order.
- [ ] A boundary that resolves before the shell flush produces no hole and no fill chunk.
- [ ] Two boundaries that resolve out of order produce fill chunks in resolution order, and the
      markup each carries is the markup of its own boundary.
- [ ] `__onzeFill` in `ssr.mjs` is idempotent: calling it twice for one id leaves the DOM unchanged.

### Step 6 — The non-streaming entry point

```bp
#[@future]
pub fn render(pathname: string, query: string) -> @Future<RenderedPage>
```

**Acceptance:**
- [ ] A URL with no matching page returns status 404 and the `not-found` boundary's markup, not an
      empty body.
- [ ] Sibling server components are handed to `async.all` (front 02) as **unstarted thunks**, in one
      await. The test measures two 50 ms loaders finishing in well under 100 ms on `--target erlang`.
      The same test written over already-started `@Future` values must fail, and is kept as a
      regression case — because `@Future` is eager on erlang, that version takes 100 ms and looks
      correct in every other respect.
- [ ] No `ssr.bp` call site passes an already-started `@Future` where front 02 expects a thunk. The
      types make this checkable; the test that it stays checkable is the type.
- [ ] Reading `route.query` sets the payload's `d` to true; not reading it leaves `d` false.
- [ ] The whole pipeline runs inside one request scope from front 62, with
      `setPhase(RequestPhase.Render)` entered before the first render and the previous phase restored
      after. A `cookies().set(...)` from a render raises, per the phase table in `contracts.md § 5`.
- [ ] Reading `route.query` calls `markDynamic("searchParams")`; front 60's prerenderer with
      `strict` set then raises instead of marking, which is how a static export fails the build.
- [ ] Each layout render receives its `selected` depth, root layout `0`, and a three-deep chain
      yields `0, 1, 2`.

## Examples

- [`examples/server-render-example.bp`](./examples/server-render-example.bp) — a page that loads its
  data on the server, renders through the escaping walker, and produces the document plus the payload
  a client reconnects to. Includes the escaping assertion, because that is the point.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| A `#[@future]` fn cannot `await` inside a `loop` or a closure — the effect marker attaches to the function, not the closure, and no library in the checkout does it | rendering N sibling server components in `compose` / the example's list render | build `Array<fn() -> @Future<T>>` in the loop and await front 02's `async.all` once | allow `await` in a closure whose enclosing fn carries `#[@future]`, or an `#[@future]` marker on a closure |
| `@Future<T>` lowers eagerly on erlang (`libs/std/src/http.bp:16-18`), so the type carries no concurrency on the target every server front compiles for | anywhere the pipeline wants two loaders to overlap | spawn a BEAM process per unit of work through front 02's `async.all`, over unstarted thunks | a real scheduler behind `@Future` on erlang, or an explicit `@Task<T>` that is honest about the difference |
| Declared parameter defaults are never applied | every `attrs:` in the example | write `attrs:` at every call | apply declared defaults at call sites |
| `xs[0]` silently drops the index on the BEAM backend | avoided throughout: the pipeline uses `.at(i)`, `.first()` and `.slice(…)` and never an index expression | `.at(i)` then `.unwrapOr(…)` | make the beam backend lower index expressions, or reject them |

## Blocked

- `repository/rakun/src/http.bp` is frozen and `Response(status, body)` has no header list and no
  streaming body. This front therefore defines `RenderedPage` in its own file and converts at the
  boundary. When `http.bp` unfreezes, `RenderedPage` should collapse into `Response` and `toResponse`
  should disappear.
- `repository/jhonstart/src/element.bp` is frozen and `renderToString` does not escape. This front
  ships `renderNode` and every path in the milestone that renders untrusted data must use it. That is
  a duplicated walker for the length of this milestone, and it should be resolved by moving the
  escaping walker into `element.bp` in 1.0.10-beta, not by keeping two.

## Test plan

`repository/rakun/test/ssr_test.bp`. The render, the escaping and the chunk protocol run on
`botopink test --target erlang`; the payload reader and `__onzeFill` are exercised from
`botopink test --target commonJS` against the same fixture strings. The exit gate names 23 as a
boundary front, so both rows are required.

The payload round trip is one test, not two: the erlang row writes the document into a fixture and the
commonJS row parses it and asserts the field set. A test that only writes, or only reads, proves
nothing about the boundary — which is the failure mode this front exists to prevent.

Streaming assertions are string assertions over the chunk list, not timing assertions, except the one
that proves `async.all` is concurrent.

One test in this file is shared rather than local: the contract-4 class-name fixture. It asserts the
same literal hex class for the same fixed token list as `repository/emilia/test/integration_test.bp`,
on both targets. It belongs here because the SSR document is where a divergence between the server's
class and the client's would first become visible, and where it is cheapest to catch.

## Definition of done

- The composition order is one function, one test, and the table in *Mechanism* above.
- No path in `ssr.bp` calls `renderToString`; the grep is part of the gate.
- The payload key table above is final for the milestone and is cited by fronts 24, 27, 29, 30, 60,
  61, 63 and 68 rather than re-derived. A change to it is a change to every one of them.
- `repository/rakun/AGENTS.md` names `ssr.bp`, the payload version and the chunk protocol.
- `RenderHooks`, its defaults and `setHooks` exist here, and `ssr.bp` imports nothing from
  `repository/onze/` — the grep is part of the gate (decision 77).
- The front's tests are green on its assigned target — here, on both.

## Carried from 1.0.7-beta F09 rakun-ssr-pipeline

Source: `specs/1.0.7-beta/09-rakun-ssr-pipeline/README.md` and `specs/1.0.7-beta/examples-bp.md § F09`.
Items below are absent from the 1.0.9 text above; items the merge already covers elsewhere are listed
at the end with the front that holds them.

### Reference rows

| 1.0.7 reference | 1.0.9 status |
|---|---|
| `[Rendering](https://nextjs.org/docs/app/building-your-application/rendering)` (header, line 3) | URL not cited by any rakun front; the topic is split across 23 (render), 28 (server components), 29 (client directive) |

### Requirements and API names (quoted)

| # | 1.0.7 item | Where in 1.0.7 | Note |
|---|---|---|---|
| 1 | `Accept`-based split at the transport: "Check if request wants HTML (`Accept: text/html`)" — `val accept = rkGetHeader(headersJson, "accept"); if (accept.contains("text/html")) { … renderPageToHtml(path) … } else { rkDispatchHttp(method, path, headersJson, queryJson, body); }` inside `pub fn run(app: App)` in `bootstrap.bp`; acceptance "HTML requests go through SSR pipeline · API requests go through route handlers" | Step 4 | Not carried. 1.0.9 decides page-vs-handler from the route-table kind (`P` vs `R`, front 22 § What crosses the boundary; 25 § Coexistence with pages), not from `Accept`; `bootstrap.bp` is frozen (23 **Does not touch**). No 1.0.9 front states what a `GET /api/posts` with `Accept: text/html` receives — open row |
| 2 | `pub fn wrapInHtmlDocument(body: string, metadata: Metadata) -> string { val headHtml = renderMetadataToHtml(metadata); return "<!DOCTYPE html><html><head>" + headHtml + "</head><body>" + body + "</body></html>"; }` — acceptance "Produces valid HTML5 document · Includes metadata in `<head>`" | Step 2 | superseded by: 23 § The document (`document(head, body, p)`) + 32 § Mechanism (`renderHead(m) -> string`) |
| 3 | `val metadata = await collectMetadata(route);` — "Collects metadata (from page/layout exports)"; Note: "Metadata collection is a separate step; the pipeline orchestrates it." | Mechanism steps 5–6, Notes | superseded by: 32 § Current state — "The 1.0.7 draft proposed `pub val metadata: Metadata = Metadata(...)` and a `collectMetadata()` host cell. Both are dropped" |
| 4 | Test: `val meta = Metadata(title: "Test", description: "", ...); val html = wrapInHtmlDocument(body, meta); assert html.startsWith("<!DOCTYPE html>"); assert html.contains("<title>Test</title>"); assert html.contains("<div>Hello</div>");` | Step 5 | No 1.0.9 acceptance asserts `startsWith("<!DOCTYPE html>")` on the finished document or `<title>` presence from 23's side; 32 Step acceptance covers `renderHead`. Open assertion for 23's `document` |
| 5 | `// src/ssr.mjs (sidecar) — import { renderToString } from "jhonstart/element"; export async function renderPage(path) { const route = matchRoute(path); const component = await loadPageComponent(route); const html = renderToString(component); return html; }` — acceptance "`ssr.mjs` sidecar created · Exports `renderPage` function" | Step 3 | superseded by: 23 header **Target** ("The render, the escaping and the chunk writer are erlang; the payload reader and the streaming-hole swapper are js") and Step 3 ("No path in `ssr.bp` calls `renderToString`") |
| 6 | `val route = await matchRoute(path); val page = await loadPageComponent(route);` — "Loads the page component (and layouts)" by path at request time | Mechanism, Step 1 | superseded by: 22 § Problem ("a `.bp` file is not loadable at runtime … A file-convention router in botopink therefore has to be registration-driven") |
| 7 | `#[@future] pub fn renderPageToHtml(path: string) -> @Future<string>` — a single-string return | Step 1 | superseded by: 23 Step 1 (`RenderedPage(status, headers, chunks)` + `toResponse`) |
| 8 | Note: "The SSR pipeline uses jhonstart's `renderToString` — it doesn't reimplement rendering." | Notes | superseded by: 23 § Escaping is the render ("`renderNode` is a full re-implementation of the walk in `element.bp:55-67`") and *Blocked* |
| 9 | Gate: "Commit on `fix/rakun-ssr-pipeline`" | Gate | Branch-naming convention; 1.0.9 fronts name no branch |
| 10 | Blast radius: "`bootstrap.bp` updated to route HTML requests through SSR" | Blast radius | Not carried; see row 1 |

### Example material (quoted from `examples-bp.md § F09`)

Carried verbatim to [`examples/ssr-page-and-layout-carried-example.bp`](./examples/ssr-page-and-layout-carried-example.bp). What differs from the 1.0.9 shape:

| 1.0.7 example | 1.0.9 counterpart |
|---|---|
| The page builds the whole shell itself: `return html([head([style([text(styles, attrs: [])], attrs: [])], attrs: []), body([...], attrs: [])], attrs: []);` and calls `val styles = await flush();` inside `HomePage` | superseded by: 23 § The document — "`emilia.flush()` is called exactly once per document, after the tree is rendered and before the head is written … the pipeline has exactly one place it may be called". The shell is `document(head, body, p)`; a page returns its subtree |
| `import {Element, html, head, body, div, h1, p, style, text} from "jhonstart";` | 94 § tag table: the `<html>` constructor is `htmlTag` ("`html` is already a `pub fn` in the same package — the `html """…"""` template fn"); `head`/`body`/`style` are 94's |
| `val inter = googleFont("Inter", subsets: ["latin"]); … attrs: [#("class", inter.className)]` in `RootLayout` | 52 § `pub fn googleFont(family: string, opts: GoogleFontOptions) -> @Future<Font>` (awaited; options record — parameter-defaults gap) |
| `pub fn RootLayout(children: Element) -> @Future<Element>` with `html([...], attrs: [#("lang", "pt-BR")])` | 22 Step 2 `LayoutProps(route, children, slots)`; `lang="pt-BR"` is written by 23 § The document |
| `#("class", titleClass)` attribute pairs | 1.0.9 examples spell `bracketPair("class", x)`; both are `#(string, string)` |

### Covered elsewhere (not carried)

- "SSR is async because page components may be `#[@future]`" → 22 Step 2 (`#[@future] fn(route: PageContext) -> @Future<Element>` is the pinned page shape).
- "Returns full HTML document" / `<!DOCTYPE html>…</html>` shape → 23 § The document.
- "Tests pass on commonJS + erlang" → 23 § Test plan (both rows required).
- Layout nesting → 22 `layoutChain` + 23 `compose`.

# Front 23 — Rakun SSR Pipeline

**Track:** B rakun
**Priority:** critical — this is the front where "Erlang is the server" stops being a slogan: the
render Next.js performs on the server happens here, on BEAM, and everything the browser later does
starts from the bytes this front writes
**Target:** both — boundary. The render, the escaping and the chunk writer are erlang; the payload
reader and the streaming-hole swapper are js; the payload format is the contract between them
**Wave:** 2
**Depends on:** 04 (BEAM runtime), 22 (route table and layout chain), 06 (scopes), 62 (request
context — `headers()`, `cookies()`, `after()`, per-request memoization), 28 (server components), 02
(`async.all` over unstarted thunks), 01 (`escape.html` / `escape.attribute`), 03 (content hash for the
build id)
**Owns:** `repository/rakun/src/ssr.bp`, `repository/rakun/src/ssr.mjs`,
`repository/rakun/src/ssr.erl`, `repository/rakun/test/ssr_test.bp`
**Does not touch:** `repository/rakun/src/http.bp`, `src/decorators.bp`, `src/bootstrap.bp`,
`src/runtime.mjs` (frozen), `repository/jhonstart/src/element.bp` (frozen), and the files owned by
22 · 24 · 25
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
  -> 62  request scope opens                   headers, cookies, memo cache
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

**Escaping is the render, not a step before it.** `renderNode` is a full re-implementation of the
walk in `element.bp:55-67` with three differences, and it is what every path in this front calls:

| Node | `renderToString` today | `renderNode` here |
|---|---|---|
| `#text` | `e.value` verbatim | `escape.html(e.value)` — front 01 |
| attribute | `name="value"` verbatim | `name="` + `escape.attribute(value)` + `"` |
| `input`, `br`, `img`, `meta`, `link`, `hr`, `source` | `<input></input>` | `<input …>`, no closing tag |
| `#raw` | renders `<#raw>` | `e.value` verbatim, the single documented escape hatch |

`escape.html` covers `&`, `<`, `>`; `escape.attribute` adds `"` and `'`. Both are new in front 01 and
written in pure botopink. `#raw` is built through the public
`Element` record — `Element(tag: "#raw", value: html, children: [], attrs: [])` — so this front adds
it without touching the frozen `element.bp`. Every use of `#raw` in the milestone is a place a
reviewer must look at, and there are exactly two: the emilia `<style>` block and the payload script.

**The document.**

```html
<!DOCTYPE html><html lang="pt-BR"><head><meta charset="utf-8">…metadata from front 32…
<style>…emilia flush()…</style></head><body>
<div data-onze-root="">…composed tree…</div>
…fill chunks…
<script id="__onze" type="application/json">{…payload…}</script>
<script src="/_onze/client-<hash>.js" defer></script>
</body></html>
```

`emilia.flush()` is called exactly once per document, after the tree is rendered and before the head
is written, because flushing clears the sheet (`repository/emilia/src/emilia.bp:53-56`). Rendering
first and writing the head second is why the pipeline builds the body string before the document
string rather than streaming the head first — except in streaming mode, where the head must go out
early and the sheet is instead flushed into the shell's `<style>` with the class names of the
already-rendered part, and later chunks carry their own `<style>` blocks.

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

`i0` indexes the payload's `i` array. The client bundle (front 68) walks `[data-onze-i]` in document
order, looks each id up, and mounts. Front 29 decides *which* components are islands; this front only
guarantees the marker and the index agree.

### Streaming

`§ 13`. The response goes out as an ordered list of chunks; front 04's transport writes them.

1. **Shell.** Doctype, head, open body, the composed tree with each Suspense boundary rendered as
   `<div data-onze-h="h1">…fallback…</div>`. The payload's `h` lists every hole still open.
2. **Fill.** One per resolved boundary, in resolution order:
   `<template data-onze-f="h1">…markup…</template><script>__onzeFill("h1")</script>`.
   `__onzeFill` lives in `ssr.mjs` and is part of the client bundle; it moves the template's content
   into the hole and removes the marker.
3. **Tail.** The payload script, the bundle script, `</body></html>`.

A boundary that resolves before the shell is flushed is inlined and never becomes a hole. Front 30
owns the Suspense boundaries and the hole ids; this front owns the chunk protocol and guarantees that
a hole id in `h` is filled by exactly one fill chunk.

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
- [ ] `renderNode(Element(tag: "input", value: "", children: [], attrs: [...]))` emits no closing tag;
      the void set is `input, br, img, meta, link, hr, source, area, base, col, embed, param, track, wbr`.
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
- [ ] The whole pipeline runs inside one request scope from front 62, and a `cookies().set(...)` from
      a render fails rather than silently doing nothing.

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

## Definition of done

- The composition order is one function, one test, and the table in *Mechanism* above.
- No path in `ssr.bp` calls `renderToString`; the grep is part of the gate.
- The payload key table above is final for the milestone and is cited by fronts 24, 27, 29, 30, 60,
  61, 63 and 68 rather than re-derived. A change to it is a change to every one of them.
- `repository/rakun/AGENTS.md` names `ssr.bp`, the payload version and the chunk protocol.
- The front's tests are green on its assigned target — here, on both.

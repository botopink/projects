# Front 30 — Jhonstart Render and Streaming

**Track:** C jhonstart
**Priority:** high — jhonstart is the package that writes HTML (decision 113): without this front there is no escaping walker, no document and no payload in the package that owns them, and one slow loader holds the whole page
**Target:** both — boundary. The render, the escaping, the document, the payload writer and the chunk production are erlang; the fill function and the payload reader (`render.mjs`) are js; the payload format and the globals registry are the contract between them
**Boundary:** the server produces the shell, the fills and the payload; the browser consumes them. Every marker and global the HTML carries is written here or by another jhonstart front: `data-jh-*` markers (`contracts.md § 2`) and the three `__bp<N>` globals of this front's registry (decisions 113 and 115)
**Wave:** 5
**Depends on:** 28 (`RequestData`, `enterRequest` / `leaveRequest`) · 29 (`islandAttr`, `islandEntry`) · 31 (`renderBoundaryChecked`) · 32 (`renderHead`, `mergeMetadata`) · 02 (spawn/gather over unstarted tasks) · 01 (`escape.html` / `escape.attribute`) · `01-std/01-std-lib-enablement` (`json.quote` / `json.array` / `json.object`, `escape.scriptJson`, `json.decode` for the payload reader — decision 117 rule 7) · 94 (`isVoidTag`, `isRawTextTag`, element builders) · `01-std/04-routing-lib` (`matchPath` for the redirect-target check, Step 7's `navigation.isSignalReason` / `signalFromReason` for the late signal, `parsePath` / `parseTable` for Step 10's round trip) — and no rakun, onze or emilia module: onze hands in the route data, the request, the `Response` adapted over rakun's response and the plugins (decisions 113, 114 and 117); `routing` is the compiler-bundled library jhonstart imports directly (decision 115)
**Owns:** `repository/jhonstart/modules/jhonstart/src/render.bp` (the escaping walker, `compose`, the document, `Payload` and its writer — contract 2 — the island and hole ordinals, `Response`, `render`/`renderStream`, the navigation-signal translation and the redirect-target check, the `RenderHooks` record and `app`), `repository/jhonstart/modules/jhonstart/src/plugin.bp` (`RenderPlugin` and the order it is called in), `repository/jhonstart/modules/jhonstart/src/globals.bp` (the globals registry, `readPayload`, `registerFill`, `registerSignal`), `repository/jhonstart/modules/jhonstart/src/routes.bp` (the UI file conventions — `#[page]`, `#[layout]`, `#[template]`, `#[defaultView]`, `PageContext`, `LayoutProps`, the per-route parameter accessors and the UI registry, decision 114) with its sidecars `src/sidecars/jhonstart_routes.erl` and `src/routes.mjs`, `repository/jhonstart/modules/jhonstart/src/render.mjs` (the browser fill function and payload reader), `repository/jhonstart/modules/jhonstart/src/streaming.bp`, `repository/jhonstart/modules/jhonstart/src/suspense.bp`, their tests (`test/render_test.bp`, `test/streaming_test.bp`, `test/routes_test.bp`), and the bridge member `repository/jhonstart/modules/jhonstart-emilia/**`
**Does not touch:** `src/element.bp`, `src/hooks.bp`, `src/html.bp` (frozen), `src/router.bp` (26), `src/link.bp` (27), `src/server.bp` (28), `src/client.bp` (29), `src/error_boundary.bp` (31), `src/metadata.bp` (32), `src/root.bp` and `botopink.json` (front 94); `repository/emilia/**` (emilia does not change — decision 113), `repository/rakun/**`, `repository/onze/**`
**Reference:** `NEXTJS-DOCS.md § 13. Streaming` · `§ 3. Convenções de nomenclatura` · `§ 5. Layouts e Páginas` · `§ 7. Server e Client Components` · `§ 4. Hierarquia de renderização` · https://nextjs.org/docs/app/guides/streaming · https://nextjs.org/docs/app/api-reference/file-conventions/loading · [decision 113](../../decisions-taken.md#113-the-libraries-split-by-concern-emilia-is-css-jhonstart-is-html-rakun-is-the-service-on-erlang-onze-wires-them) · [decision 114](../../decisions-taken.md#114-the-seams-decision-113-left-open-rakun-routing-an-async-renderplugin-with-a-payload-rakuns-opaque-page-renderer-examples-in-onze-action-names-and-the-request-handed-in-by-onze) · [decision 115](../../decisions-taken.md#115-routing-is-a-bundled-library-a-signal-after-the-first-chunk-is-markup-jhonstart-gains-redirect-rakuns-keys-are-rakun) · [decision 117](../../decisions-taken.md#117-navigation-signals-are-jhonstarts-end-to-end-pages-and-layouts-are-components-std-reads-json-bundled-libraries-are-bp-only)

---

## Problem

**jhonstart writes the HTML, and today it has no renderer that is safe to ship.** `renderToString`
concatenates: a `#text` node returns `e.value` verbatim and an attribute becomes
`" " + a._0 + "=\"" + a._1 + "\""` with no escaping anywhere (`element.bp:55-67`), and it closes
void tags (`<input></input>`). `element.bp` is frozen for the milestone, so the escaping walker, the
document shell and the payload the browser reconnects to are a new file in this package —
decision 113 puts the whole HTML render in jhonstart: *"quem deve ser responsável pelo html é o
jhonstart"*. rakun (front 23) routes, opens the request scope, calls the opaque `PageRenderer` onze
registered for the route and puts on the socket what the render writes through its response; it
builds no markup, names no page, layout or `Element` (decision 114) and knows no page signal —
`notFound` and `redirect` in a page are turned into a status here (decision 117). The UI file conventions — `#[page]`, `#[layout]`, `#[template]`,
`#[defaultView]`, `PageContext`, `LayoutProps` and the per-route parameter accessors — are this
front's for the same reason: they are typed over `Element`. The render that `repository/rakun/src/ssr.bp` carries today —
`renderNode`, `raw`, `compose`, `document`, `Payload`, `RenderHooks` — is the code this front
receives; rakun front 23 removes its copy when this front lands.

emilia's CSS reaches the document through this front too: jhonstart declares an asynchronous
render-plugin point and awaits it at the three moments CSS has to be written (the head, each
streamed boundary, the end) and once more for the plugin's payload contribution, and the
`jhonstart-emilia` bridge — a member of this workspace — adapts emilia's `@Task`-returning `flush()` to it
and contributes the payload's `s` key. jhonstart never names emilia.

**Streaming.** Front 28 gives a page one `await` per loader and one tree at the end. That is all-or-nothing: a blog
index whose header is free and whose post list takes 900ms sends nothing for 900ms, because
`renderToString` walks a tree that does not exist yet (`element.bp:55-67`). The reader gets a white
page, and the measurement that matters — when the first byte carries something readable — is as bad
as the slowest query on the page.

Streaming is the fix, and it is not a rendering trick: it is a change in what the render *produces*.
Instead of one string, the render produces a shell plus an ordered sequence of chunks, each keyed to
a hole in the shell. jhonstart has no vocabulary for any part of that. There is no boundary type, no
fallback concept, no chunk, and `renderToString` has no seam where a second flush could attach.

The `loading.bp` convention is the other half. Upstream, a `loading.tsx` in a segment automatically
wraps that segment's `page.tsx` in a `<Suspense>` (`NEXTJS-DOCS.md § 13`) — the developer writes one
file and never writes a boundary by hand. That wrapping is done by the file router, so this front
owes front 22 a shape it can wrap things in, not a second file convention.

## Current state

- `element.bp:55-67` — `renderToString`, synchronous, one pass, no seam, no escaping, void tags
  closed.
- `repository/rakun/src/ssr.bp` — the escaping walker, the composition order, the document, the
  payload writer and `RenderHooks`, landed by rakun front 23 with `data-onze-*` markers, the
  `<script id="__onze">` payload and `__onzeFill`. Its cells are the acceptance this front ports.
- `repository/jhonstart/modules/jhonstart-emilia/` does not exist.
- `repository/rakun/src/file_router.bp` (rakun front 22) carries `#[page]` / `#[layout]` /
  `#[template]` / `#[defaultView]`, `PageContext`, `LayoutProps` and `rkAppRegisterPage` over
  `Element`; this front's Step 10 is where they live, and rakun front 22 removes its copy when it lands
  (decision 114).
- `src/root.bp:15-17` — no `suspense`, no `streaming`.
- a `@Task` return + `await` work and are exercised (`repository/emilia/src/emilia.bp:62-65`,
  `:475-480`).
- Nothing in the repository emits more than one string per render, and nothing reads a partial one.
- `libs/std/src/http.bp:16-18` — "Erlang is eager: `@Task<T>` resolves to `T` … so the caller's
  `await fetch(url)` is identity on that backend." There is no concurrent scheduler behind `@Task`
  on the BEAM, which is the single most important fact about this front.

## Mechanism

Upstream splits a streamed page into a shell that flushes immediately and one `<Suspense>` boundary
per slow subtree; each boundary's fallback goes out with the shell and is replaced when its content
arrives (`NEXTJS-DOCS.md § 13`). jhonstart keeps that model and makes the two halves explicit,
because an `Element` cannot carry a deferred child: `Children` coerces from arrays, elements and
strings (`infer.zig:4228-4239`), never from a thunk.

### The render — `render.bp`

The pipeline, end to end, on BEAM. Everything that builds markup is this file; the lines marked
*onze* and *rakun* are values handed in, never imports:

```
rakun   match the request (`routing`'s matchPath), open front 62's request scope, setPhase(Render),
        call the PageRenderer onze registered for the route with (Request, ChunkWriter)
onze    turn the match into a `PageInput` (route data + jhonstart `Segment`s), rakun's `Request` into a
        `RequestData`, and rakun's `ChunkWriter` into a jhonstart `Response` (status, header, write, close)
30      enterRequest(req)             front 28's request() / headers() / cookies() read it
30      compose(chain, page)          layout > template > error > loading > not-found > page
30      renderNode(tree)              escaping walker, void-aware; a navigation signal becomes a status
                                      before the first chunk, markup after it (*Navigation signals*)
30      plugins: head / chunk / close the CSS moments, then payload (`plugin.bp`), each awaited
30      document(head, body, payload) the bytes, as an ordered chunk list, each through res.write
30      res.close()                   once, on every path
rakun   put each chunk on the socket as it is written
```

**Escaping is the render, not a step before it.** `renderNode` re-implements the walk of
`element.bp:55-67` with four differences, and it is what every path in this front calls:

| Node | `renderToString` | `renderNode` |
|---|---|---|
| `#text` | `e.value` verbatim | `escape.html(e.value)` — front 01 |
| `#text` inside a raw-text tag | `e.value` verbatim | `e.value` verbatim; a body containing `</script` or `</style` is **refused** |
| attribute | `name="value"` verbatim | `name="` + `escape.attribute(value)` + `"` |
| a void tag | `<input></input>` | `<input …>`, no closing tag |
| `#raw` | renders `<#raw>` | `e.value` verbatim, the single documented escape hatch |

`isVoidTag` and `isRawTextTag` are front 94's and are called, never restated. A raw-text body is
emitted verbatim because escaping a CSS or script body changes the program; the one sequence that
can close the element early is refused (case-insensitive, the HTML parser's own rule), and no flag
turns the refusal into escaping. `#raw` is built through the public `Element` record, so this front
adds it without touching `element.bp`; its two uses in the milestone are the plugin's `<style>`
blocks and the payload script.

**Composition order is one function, tested.** `compose(chain: Array<Segment>, page: Element)`
wraps the page from the inside out — `page`, then `not-found`, `loading`, `error`, `template`,
`layout` — per segment, root-first, so the outermost element is the root layout (`§ 4`). `Segment`
is **jhonstart's own record** of one segment's conventions and its pattern; onze builds the list
from `routing`'s `layoutChain` and this front's UI registry (Step 10), so jhonstart never names
a rakun type (decisions 113 and 114). A `template`
wrapper carries `data-jh-t="<pattern>#<nav>"`, a fresh key per navigation. Each layout render
receives its `selected` depth (root `0`) — front 26's per-layout value.

**The document.**

```html
<!DOCTYPE html><html lang="pt-BR"><head><meta charset="utf-8">…front 32's head…
…plugin head()…RenderHooks.headExtra(route)…</head><body>
<div data-jh-root="">…composed tree…</div>
…fill chunks…
<script>window.__bp0 = {…payload…}</script>
…RenderHooks.bodyExtra(route)…
</body></html>
```

**The payload — contract 2, owned here.** One executable script, the last thing in `<body>` before
the bundle tags, assigning the payload global — `globals.payload`, `__bp0` — rather than an element
the client looks up by a hand-written id. The key table is `contracts.md § 2` (`v`, `b`, `p`, `r`,
`m`, `q`, `t`, `i`, `a`, `s`, `h`, `d`, `k`, `z`); `t` (front 22's table blob), `a` (front 24's
action rows) and `b` (the build id) arrive from onze as strings — this front writes them, it does not
know where they come from. `s` is not the render's: it is the `jhonstart-emilia` bridge's
contribution through `RenderPlugin.payload` (decision 114, item 2), written under the key the plugin
gives, like any plugin key. `m`, `q` and island props are percent-encoded with std's
`encoding.formStringify` (decision 116 rule 4). **Writing and escaping the payload are std's**
(decision 116 rules 3 and 8): the JSON is built with `json.quote`, `json.array` and `json.object`
(`01-std/01-std-lib-enablement`, which escape every control character), and the finished text passes
through `escape.scriptJson` — `<`, `>` and `&` as `\u003c`, `\u003e`, `\u0026`, U+2028/U+2029 as
`\u2028`/`\u2029` — so `</script` is unrepresentable inside the block. The render keeps no JSON
writer and no escaper of its own; rakun's `jsonString` family (`ssr.bp:641-676`) is not ported.

**Ordinals.** Island ids are `i0`, `i1`, … in render order, written through front 29's
`islandAttr` — one definition in one package, so no hook carries it. Hole ids are `h1`, `h2`, … in
shell order (*Hole ids* below). Both are assigned here, once per response.

**`RenderHooks` and `app`.** The record moved here with the render (decision 113, amending 77). It
keeps the two fields that carry markup another package writes — the bundle tags of onze front 68 —
and nothing else:

```bp
pub type RenderHooks(
    headExtra: fn(string) -> string,   // route -> extra <head> markup; default ""
    bodyExtra: fn(string) -> string,   // route -> markup after the payload script; default ""
)
pub fn defaultHooks() -> RenderHooks
pub fn setHooks(h: RenderHooks) -> void

pub type App(plugins: Array<RenderPlugin>, allowedRedirects: string[])
pub fn app(plugins: Array<RenderPlugin>, allowedRedirects: string[] = []) -> App
```

The four style-sink fields of rakun's `ssr.bp` record are replaced by the plugin list, and `islandAttr`
leaves: the render that writes the island is jhonstart's, and it calls front 29's function directly.
onze fills `RenderHooks` and calls `app(plugins: [...], allowedRedirects: [...])` at boot (the list
is the application's `OnzeConfig.allowedRedirects`, decision 117); this file names neither onze nor
any plugin. `allowedRedirects` is the one list of absolute redirect targets the render accepts
(*Navigation signals*); empty, every absolute target is refused.

### The render plugin — `plugin.bp`

```bp
pub type Json = string;   // JSON text the plugin serialised; written verbatim

pub behavior RenderPlugin {
    fn head(self: Self) -> @Task<string>;                    // once, after the shell
    fn chunk(self: Self, holeId: string) -> @Task<string>;   // per boundary, before its markup
    fn close(self: Self) -> @Task<@Result<void, string>>;    // at the end: nothing may be left
    fn payload(self: Self) -> @Task<?#(string, Json)>;       // once, after close
}
```

Every method is asynchronous (decision 114, item 3): the render returns a `@Task` and is streaming
already, so awaiting a plugin is its normal shape, and a plugin that reads a file or flushes a
sheet through a `@Task` needs it. std has no structured JSON value — the reason contract 1 is not JSON —
so `Json` is the JSON text the plugin serialised, which `writePayload` writes verbatim as it writes
`t`, `a` and `b`.

The rules belong to the caller, so they are this front's:

1. **`head` once**, after the shell (or the whole page, when not streaming) has rendered and before
   the head is serialised; its string goes into `<head>`.
2. **`chunk(holeId)` per streamed boundary**, after the boundary rendered and before its markup is
   written; its string goes **inside** the fill's `<template>`, before the markup, with no marker of
   its own — the CSS is identified by the fill it sits in (question 94, decision 113):

   ```html
   <template data-jh-f="h1"><style>.e_1a2b3c{…}</style>…the boundary's markup…</template><script>__bp1("h1")</script>
   ```

   "CSS before the markup, never an unstyled paint" holds by construction: the template's content
   enters the document when the fill inserts style and markup together. `data-jh-s` stays the server
   slot of front 29 only.
3. **`close` at the end**, after the last chunk; an `Error` fails the render — nothing may be left
   unwritten.
4. **`payload` once, after `close`**, before the payload script is serialised. A `null` contributes
   nothing; `#(key, value)` writes `value` under `key`. A key the render writes itself — every key of
   `contracts.md § 2` but `s` — or a key two plugins give fails the render, naming the key and the
   plugins. jhonstart names no key a plugin may give; `s` is the `jhonstart-emilia` bridge's.

Each call is awaited before the next moment begins. Plugins are called in the order `app` received
them. A render with no plugin writes no `<style>` and no plugin key.

### The globals registry — `globals.bp` and `render.mjs`

Only three values exist in `window`, because the HTML names them by text: the payload variable,
the fill function a fill's `<script>` calls, and the signal function a late navigation signal's
`<script>` calls (decisions 115 and 117, *Navigation signals* below). Each gets an indexed alias `__bp<N>` from this
registry, `N` counting up in **declaration order in this file**, so the server build and the client
build agree without exchanging anything:

```bp
// src/globals.bp — one entry per global the HTML names; the order is the contract
val registry = ["payload", "fill", "signal"];

pub fn alias(name: string) -> string    // "__bp" + the name's index; an unknown name fails
pub val payload = alias("payload");     // "__bp0"
pub val fill = alias("fill");           // "__bp1"
pub val signal = alias("signal");       // "__bp2"
```

No alias is spelled by hand: adding a global is one registry entry, and its name follows from its
position.

`render.bp` writes `window.<globals.payload> = …` and `<script><globals.fill>("h1")</script>`;
`render.mjs` defines the fill function under `globals.fill` and `readPayload(name)` /
`registerFill(name, holes)` read the same names, and `registerSignal(name, allowedRedirects)` defines
the signal function under `globals.signal`, checking a redirect against the same list `app(…)`
received on the server (decision 117). No global is written by hand anywhere in the
milestone, and link and form mount are ordinary imports (`linkMount`, `formMount` — fronts 27 and
67). `registerFill` and `registerSignal` are `#[@External.Node]` cells, and `readPayload(name)` is
`.bp` over one: the cell answers the payload script's JSON text and `readPayload` decodes it with
std's `json.decode` (decision 117 rule 7), so the payload has one reader and no hand slicing. All
three are called only by onze's generated client entry; nothing on the erlang row calls them.

### What makes it actually stream

`@Task` is eager on the BEAM (`libs/std/src/http.bp:16-18`). A list of futures is therefore a list
of results that have *already* been computed, in order, before anything was flushed — and a
"progressive flush" driven by awaiting such a list flushes everything at once, after the slowest
boundary, having paid the sum of all of them. It would pass a test that checks the chunks and fail
the only thing a reader can see.

So a boundary in this design holds an **unstarted task** — `fn() -> @Component<ElementBase, Element>`, a thunk
over a server component (decision 104: a component that awaits is `fn … -> @Component<ElementBase, Element>`,
and `@Component ⊃ @Task`, so `await b.child()` is legal in a `@Task` body) — and progressive
flush is driven by the completion of **spawned work**, one BEAM process per boundary, gathered by
index. Front 02 owns spawning and gathering, and its surface takes exactly
that shape: `Array<fn() -> @Task<T>>`. `renderStream` spawns the boundaries, hands the shell to
`res.write` (the `Response` onze built over rakun's `ChunkWriter`) immediately, and hands each fill
to it as its process reports.

The division of labour follows from it:

| Who | Does what |
|---|---|
| this front | defines `Boundary` (a thunk, not a future), the placeholder markup and `Chunk`; `renderStream` produces the shell, then each completion's fill (with its plugin CSS), in completion order |
| front 02 | spawns the thunks and reports completions by index |
| rakun (front 23), through onze | puts each chunk `res.write` hands it on the socket (`ChunkWriter.write`) and applies the status and headers `res.status` / `res.header` set before it; the render calls `res.close()` |
| `render.mjs` / onze front 68's entry | adopts each fill in the browser |

`renderStream` never awaits a list: `resolve(b)` awaits **one** boundary, inside each spawned
process.

### The erlang half — this front

A boundary is a record, not an element:

```bp
pub type Boundary(
    id: string,
    fallback: Element,
    child: fn() -> @Component<ElementBase, Element>,
)
```

`Suspense(b)` renders only the **hole**: the fallback, wrapped in the marker `contracts.md § 2`
pins. That goes out with the shell.

```
<div data-jh-h="h1"><div class="skeleton">Loading posts…</div></div>
```

`resolve(b)` returns a `@Task<Chunk>` and awaits the child exactly once, at statement level, returning a
`Chunk`. Nothing in this file awaits inside a closure — the lambda rule (`§2.38`) makes that a poor
bet and no file in the tree does it.

```bp
pub type Chunk(id: string, html: string)
```

`fillHtml(c)` wraps a resolved chunk in the form the browser looks for — again `contracts.md § 2`,
not a local invention, and the trailing script is part of the contract:

```
<template data-jh-f="h1"><ul class="posts">…</ul></template><script>__bp1("h1")</script>
```

The list of holes still open when the shell flushes is the payload's `h` key, written by this
front's render from its own boundaries.

**Ordering is this front's; writing is rakun's.** `renderStream` produces the shell, then one fill
per boundary in **completion** order, and hands each to `res.write`, awaiting each write; it never holds a completed fill back. rakun decides nothing about the markup.

### The js half — `render.mjs`, called from onze front 68's entry

The browser half is three rules, implemented by the fill function `render.mjs` registers under
`globals.fill`:

1. `__bp1("h1")` replaces the contents of `[data-jh-h="h1"]` with the contents of
   `[data-jh-f="h1"]`, then removes the template. The call is in the flushed markup; the browser
   does not poll and does not scan.
2. A fill for a hole id that is not present is dropped, not an error — the boundary may have been
   navigated away from. The id also leaves the payload's `h` list when it is filled.
3. Adoption happens before hydration of anything inside the chunk, so a client component inside a
   streamed subtree starts once, not twice.

4. A late signal (*Navigation signals* below) runs the function registered under `globals.signal`
   (`__bp2`, decision 117 rule 2), which acts as front 26's client-only router does: for
   `data-jh-g="redirect"` a relative `data-jh-to` is a client navigation (`history.replaceState`,
   no reload) and a listed absolute one is `location.replace`; for `data-jh-g="not-found"` it
   replaces the contents of `[data-jh-root]` with the template's contents, then removes the
   template. Any later fill is dropped (rule 2).

`render.mjs` implements it; front 68's generated entry calls `registerFill(globals.fill, payload.h)`
and `registerSignal(globals.signal, allowedRedirects: …)` before any island hydrates. `streaming.bp` and `render.bp` carry **no** `#[@External.Node]` cell;
the browser cells are `globals.bp`'s three, called only from the entry.

### Navigation signals — jhonstart turns them into a status or markup

A navigation signal — `notFound()` or `redirect(to)`, front 31's, raised by a page, a layout, a
template or a boundary — is handled entirely here, and the same page behaves the same way with a
server and in a client-only app (front 26's `clientApp`) (decision 117 rule 1). onze has no `case`
on a signal and rakun knows no page signal: the render writes to a generic response and translates
the signal itself.

```bp
// src/render.bp
pub type Response(
    status: fn(code: i32) -> void,                 // before the first write only
    header: fn(name: string, value: string) -> void, // before the first write only
    write:  fn(chunk: string) -> @Task<void>,
    close:  fn() -> @Task<void>,
);
```

`status` or `header` called after the first `write` fails the render, naming the call (decision
67). onze builds the `Response` over rakun's `ChunkWriter` (`setStatus`, `setHeader`, `write`,
`close`, rakun front 23); jhonstart never sees the `ChunkWriter`.

| A signal raised | The render writes |
|---|---|
| `redirect(to)` before the first chunk | `res.status(307)`, `res.header("location", to)`, `res.close()` — no body |
| `notFound()` before the first chunk | `res.status(404)`, a whole document whose body is the nearest `not-found` boundary of the segment that raised it (front 31), `res.close()` |
| either, after the first chunk | the late-signal markup below as the last chunk, no further fill, `res.close()`; the status stays 200 |

The layout renders before the page (`compose`'s order), so a signal a layout raises before the first
chunk means the page never runs. `res.close()` is called once on every path — a normal render, a
signal before or after the first chunk, a failed render.

**After the first chunk, a signal is markup** (decision 115 rule 2), as Next.js does: the status
and the headers are gone, so the render writes the signal into the stream for its own client:

```html
<template data-jh-g="redirect" data-jh-to="/login"></template><script>__bp2()</script>
<template data-jh-g="not-found">…the nearest not-found boundary's markup…</template><script>__bp2()</script>
```

`__bp2` is `globals.signal`, the third registry global (decision 117 rule 2). `data-jh-to` is written
through `escape.attribute`; the not-found markup is the nearest `not-found` boundary of the segment
that raised it, rendered by the same walker, with its plugin CSS first inside the template as a
fill's is (`contracts.md § 6a`). The client half is rule 4 of *The js half*.

**The redirect target is checked here**, because jhonstart writes the 307 and the late markup
(decision 117 rule 1). The check is the same before and after the first chunk:

- a **relative** target is accepted when `routing`'s `matchPath` finds it in the table the render
  was handed (`PageInput.table`);
- an **absolute** target is accepted only when it is listed in `app(allowedRedirects: [...])`; with
  the list empty (its default) every absolute target is refused;
- anything else fails the render — logged as a render error, the response closed, no `location`
  header and no signal markup written — with no option that writes it anyway (decision 67).

**This front owns the translation** — no other package sees a page signal. The render recognises a
raised reason with `routing`'s `navigation.isSignalReason` and reads it with `signalFromReason`
(decision 116 rule 1) — the `nav:` reasons of `contracts.md § 5b`, which front 31's `notFound` /
`redirect` raise — and anything that is not a signal reason is an error for the nearest error
boundary, as before. It keeps no reason table of its own. Step 8 owns the translation before the
first chunk, Step 12 after it.

### Hole ids

`contracts.md § 2` spells a hole id `h1` — an ordinal, not a path. The render assigns them in shell
render order, exactly as it assigns `i0`, `i1` to islands, and the ordinal is what ties the hole, the
fill and the payload's `h` entry together. The spelling:

```bp
pub fn holeId(index: i32) -> string {
    return "h" + index.toString();
}
```

The ordinal is assigned once per response, so a boundary's id is stable between the shell and its
fill and cannot collide with another boundary on the same page. It is deliberately **not** derived
from the route: a client navigation produces a new response and a new set of ordinals, and a hole
that survived a navigation would be a hole whose fill belongs to the previous page.

### `loading.bp`

A segment's `loading.bp` exports `pub fn Loading() -> Element` — it activates nothing, so it carries
no annotation (decision 104); it is not one of the three markers of decision 117 rule 3. Front 22 discovers the file (kind `S`
in the route table, `contracts.md § 1`) and onze hands it to jhonstart inside the segment chain;
`compose` builds
`Boundary(id: holeId(n), fallback: Loading(), child: { -> Page(params) })` around the segment's page,
with `n` the next ordinal. This front asserts nothing about file discovery, which is front 22's.

The developer writing `loading.bp` writes one function and never names a boundary. The developer who
wants a boundary *inside* a page writes `Suspense` by hand, with a name.

## Steps

### Step 1 — `Boundary`, `Suspense`, `holeId`

```bp
// src/suspense.bp
import {Element} from "element";

pub type Boundary(
    id: string,
    fallback: Element,
    child: fn() -> @Component<ElementBase, Element>,
)

pub fn Suspense(b: Boundary) -> Element {
    return Element(
        tag: "div",
        value: "",
        children: [b.fallback],
        attrs: [#("data-jh-h", b.id)],
    );
}

pub fn holeId(index: i32) -> string {
    return "h" + index.toString();
}
```

**Acceptance:**
- [x] `renderNode(Suspense(b))` emits the fallback inside `<div data-jh-h="h1">` and nothing else —
      the child is not rendered and does not appear in the shell — `test/render_test.bp` "render: Suspense renders the fallback in the hole and never the child" (jhonstart `89a1528`)
- [x] `holeId(1) == "h1"`, `holeId(0) == "h0"` — the spelling `contracts.md § 2` pins — `test/render_test.bp` "render: holeId spells h<n> and nothing outside [h0-9]"
- [x] a `Boundary` carries the ordinal the render assigned it, in shell order — `compose` assigns `nextHoleOrdinal()`; `test/streaming_test.bp` "stream: fills come in completion order…" (`"h":["h1","h2"]`)
- [ ] `Suspense` reaches no host cell

### Step 2 — `Chunk`, `resolve`, `fillHtml`

```bp
// src/streaming.bp
import {Element} from "element";
import {Boundary} from "suspense";
import {renderNode} from "render";
import {globals} from "globals";

pub type Chunk(id: string, html: string)

pub fn resolve(b: Boundary) -> @Task<Chunk> {
    val tree = await b.child();
    return Chunk(id: b.id, html: renderNode(tree));
}

// `css` is what the plugins' `chunk(c.id)` returned, "" when none.
pub fn fillHtml(c: Chunk, css: string) -> string {
    return "<template data-jh-f=\"" + c.id + "\">" + css + c.html
        + "</template><script>" + globals.fill + "(\"" + c.id + "\")</script>";
}
```

**Acceptance:**
- [x] `resolve` awaits exactly once, at statement level, never inside a closure — `streaming.bp` `resolve`
- [x] `resolve` of a boundary whose child returns immediately produces the rendered child, through
      `renderNode` — `test/render_test.bp` "render: resolve awaits the child once and renders it through the walker"
- [x] `fillHtml(Chunk(id: "h1", html: "<ul></ul>"), "")` is exactly
      `<template data-jh-f="h1"><ul></ul></template><script>__bp1("h1")</script>` — the literal
      `contracts.md § 2` pins, asserted here and on the browser side — `test/render_test.bp` "render: a fill is the contract-2 template plus the fill call"
- [x] `fillHtml(Chunk(id: "h1", html: "<ul></ul>"), "<style>.e_1{}</style>")` puts the `<style>`
      first inside the `<template>`, with no attribute of its own — `test/render_test.bp` "render: a fill's CSS goes first inside the template, with no marker"
- [x] a chunk id is always `h<n>` from `holeId`, so the quote and `</script` cases cannot arise —
      a test asserts `holeId` produces nothing outside `[h0-9]` — `test/render_test.bp` "render: holeId spells h<n>…"

### Step 3 — The escaping walker

```bp
// src/render.bp
pub fn renderNode(e: Element) -> string
pub fn raw(html: string) -> Element
pub fn shellHtml(page: Element) -> string   // renderNode(page): the shell, every boundary showing its fallback
```

**Acceptance:**
- [x] `renderNode(text("<script>alert(1)</script>", attrs: []))` contains no `<` — `test/render_test.bp` "render: a text node is escaped — no < survives"
- [x] an attribute value containing `"` renders as `&quot;` and the produced tag re-parses — `test/render_test.bp` "render: an attribute value holding a quote renders &quot; and re-parses"
- [x] `renderNode(Element(tag: "input", value: "", children: [], attrs: [...]))` emits no closing
      tag; the void set is front 94's `isVoidTag` and this front keeps no list of its own, checked
      by grep in its gate — `test/render_test.bp` "render: a void tag has no closing tag"; `render.bp` keeps no void list
- [x] a `style` body containing `a > b` renders verbatim — not `a &gt; b` — and so does a `script`
      body containing `&&` — `test/render_test.bp` "render: a style and a script body are raw text, verbatim"
- [x] a `script` or `style` body containing `</script` or `</style`, in any case, **fails the
      render** with the tag named; it is not escaped, and no configuration makes it escaped — `test/render_test.bp` "render: a raw-text body that would close its element fails the render, naming the tag"
- [x] a raw-text body (front 94's `isRawTextTag`) is the only text this walker does not escape, and
      `#raw` is the only element — `render.bp` `renderNode`
- [x] `renderNode(raw("<b>x</b>"))` is `<b>x</b>` exactly — `test/render_test.bp` "render: #raw is the one element written verbatim"
- [x] `renderNode` and `renderToString` produce the same string for a tree with no special
      characters and no void tag — the walker is a superset, not a divergence — `test/render_test.bp` "render: renderNode is renderToString on a tree with nothing to escape"
- [x] `shellHtml` of a page containing two boundaries emits both placeholders and neither child,
      and adds no doctype and no head — the document is Step 4's — `test/render_test.bp` "render: the shell carries every placeholder and no child, and no document"
- [x] no path in `render.bp`, `streaming.bp` or `suspense.bp` calls `renderToString` — checked by
      grep in the gate, because a single call is the whole hole — the name appears only in `render.bp`'s header comment

### Step 4 — Composition and the document

```bp
pub type Segment(…)   // one segment's conventions and its pattern — jhonstart's record
pub fn compose(chain: Array<Segment>, page: Element) -> Element
```

**Acceptance:**
- [x] for a chain of one segment holding all six conventions, the rendered nesting is
      `layout > template > error > loading > not-found > page`, asserted on the markup string — `test/streaming_test.bp` "compose: layout > template > error > loading > not-found > page, in the markup"
- [x] for `/blog/[slug]`, the root layout is the outermost element and the page innermost — `test/streaming_test.bp` "compose: each layout receives its selected depth, root-first"
- [x] a segment with no `template.bp` contributes no wrapper — the nesting shrinks, it does not gain
      an empty `div` — `test/streaming_test.bp` "compose: a segment with no template contributes no wrapper"
- [x] a `template` wrapper carries `data-jh-t` with the pattern and the navigation counter; two
      renders of one route produce two values — `test/streaming_test.bp` "compose: two renders of one route give the template two keys"
- [x] each layout render receives its `selected` depth: a three-deep chain yields `0, 1, 2` — `test/streaming_test.bp` "compose: each layout receives its selected depth, root-first"
- [x] the composed tree sits inside `<div data-jh-root="">`, and an unmatched not-found boundary
      renders as `data-jh-n` — `test/streaming_test.bp` "compose: a segment with no template…"; the not-found level writes `data-jh-n` ("compose: layout > …")
- [ ] `Segment` and `compose` name no rakun type; `grep -rn rakun modules/jhonstart/src` is empty

### Step 5 — The payload (contract 2)

```bp
pub type Payload(
    build: string, pathname: string, pattern: string, params: string, query: string,
    table: string, islands: Array<#(string, string, string)>, actions: Array<#(string, string)>,
    holes: string[], dynamic: bool,
    extras: Array<#(string, Json)>,   // the plugins' `payload` contributions, in plugin order
)

pub fn writePayload(p: Payload) -> string   // json.object / json.quote, then escape.scriptJson
```

**Acceptance:**
- [x] the document carries exactly one `<script>window.__bp0 = {…}</script>`, last in `<body>`
      before `RenderHooks.bodyExtra`, and the name comes from `globals.payload` — `documentEnd`; `test/streaming_test.bp` "stream: fills come in completion order…"
- [x] `writePayload` emits `v` first and `1` as its value — `test/render_test.bp` "render: the payload starts with v, and v is 1"
- [x] the payload block leaves no literal `<`, `>` or `&` — it is `escape.scriptJson` of the JSON —
      and a payload whose params contain `</script>` produces a document with exactly the real
      script closers and no `<img` — `test/render_test.bp` "render: the payload leaves no literal <, > or &, and </script> cannot close it"
- [x] a param holding U+0001 produces a payload `JSON.parse` accepts (std's `json.quote`) — `test/render_test.bp` "render: a control character in a param is escaped by std's json.quote"
- [x] `render.bp` defines no `payloadEscape`, `jsonString` or other JSON escaper;
      `grep -n "fn payloadEscape\|fn jsonString" modules/jhonstart/src/render.bp` is empty
- [x] `t`, `a` and `b` are written verbatim from the strings the caller passed; the render derives
      none of them — `writePayload`
- [x] each `extras` entry is written verbatim under its key; `s` appears in the payload only when a
      plugin contributed it — the render has no `styles` field of its own — `test/render_test.bp` "render: an extra is written verbatim under its key, and s only when given"
- [x] island ids are `i0`, `i1`, … in render order, written through front 29's `islandAttr`, and
      the payload's `i` array is in the same order — `test/render_test.bp` "render: islands take i0, i1 in render order, and the i rows follow"
- [x] parsing the emitted value with `JSON.parse` (commonJS) and `json:decode/1` (erlang) yields the
      same field set — the round trip is the test, not two half-tests — `test/render_test.bp` "render: the payload decodes with std's json.decode to the contract-2 field set" — std's one reader, on both rows

### Step 6 — `RenderPlugin` and the order it is called in

```bp
// src/plugin.bp
pub type Json = string;

pub behavior RenderPlugin {
    fn head(self: Self) -> @Task<string>;
    fn chunk(self: Self, holeId: string) -> @Task<string>;
    fn close(self: Self) -> @Task<@Result<void, string>>;
    fn payload(self: Self) -> @Task<?#(string, Json)>;
}
```

**Acceptance:**
- [x] with a recording plugin, a streamed render with two boundaries calls `head` once, `chunk`
      once per boundary (`h1`, `h2`, in completion order), `close` once and `payload` once, last — `test/streaming_test.bp` "plugin: head once, chunk per boundary in completion order, close once, payload last" (`chunk(id)` runs in the boundary's own process — `decisions-pending.md` 30-b)
- [x] each call is awaited: a plugin whose `chunk` resolves after a delay still has its `<style>`
      inside the right fill, and the fill is not written before it resolves — `test/streaming_test.bp` "plugin: head lands in <head>, each chunk first inside its fill…" (the recording `chunk` delays 5 ms)
- [x] a plugin returning `#("x", "[1]")` puts `"x":[1]` in the payload; returning `null` adds no key — `test/streaming_test.bp` "plugin: head lands in <head>…"; `test/render_test.bp` "render: an extra is written verbatim…" (a plugin answers `[]`, not `null` — 30-b)
- [x] a plugin key that is a render key (`v`, `t`, `h`, … — every contract-2 key but `s`) fails the
      render naming the key; two plugins giving one key fail it naming both — `test/streaming_test.bp` "plugin: a render key, or one key from two plugins, fails the render naming them"
- [x] `head`'s string lands in `<head>`; each `chunk`'s string lands first inside its fill's
      `<template data-jh-f="…">`, before the boundary's markup, with no marker — `test/streaming_test.bp` "plugin: head lands in <head>, each chunk first inside its fill, the payload key verbatim"
- [x] a plugin whose `close` returns `Error(…)` fails the render with that message — `test/streaming_test.bp` "plugin: a close answering Error fails the render with that message"
- [x] a render with no plugin emits no `<style>`, no plugin key, and calls nothing — `test/streaming_test.bp` "plugin: a render with no plugin writes no <style> and no plugin key"
- [x] the word `emilia` appears in no file under `modules/jhonstart/` — jhonstart knows the
      contract only (decision 113)

### Step 7 — The globals registry and `render.mjs`

**Acceptance:**
- [x] `globals.payload == "__bp0"`, `globals.fill == "__bp1"` and `globals.signal == "__bp2"`,
      derived from the registry's declaration order, on both targets — `test/render_test.bp` "render: the three globals come from the registry's declaration order" (spelled `globals().payload` — 30-a)
- [x] no `__bp` literal appears in `render.bp`, `streaming.bp` or `render.mjs` outside the registry
      — the render and the client read the same names
- [ ] `render.mjs`'s fill function, registered under `globals.fill`, is idempotent: calling it twice
      for one id leaves the DOM unchanged; a fill for an absent hole is dropped
- [ ] `readPayload(globals.payload)` returns the payload the render assigned, decoded with std's
      `json.decode` (decision 117 rule 7) — `render.mjs`'s cell hands over only the payload
      script's JSON text (the text after `window.<globals.payload> = `); a text `json.decode`
      refuses is an `Error`, never a partial payload
- [x] no `__onze*` or hand-written `__jh*` global is referenced by any HTML this front writes — every global through `globals()`

### Step 8 — `RenderHooks`, `app`, `render` and `renderStream`

```bp
pub type PageInput(build: string, pathname: string, pattern: string, params: string, query: string,
                   table: string, actions: Array<#(string, string)>, chain: Array<Segment>,
                   page: fn() -> @Component<ElementBase, Element>)

pub fn render(self: App, input: PageInput, req: RequestData, res: Response) -> @Task<void>
pub fn renderStream(self: App, input: PageInput, req: RequestData, res: Response) -> @Task<void>
```

onze calls `renderStream` inside the `PageRenderer` it registers with rakun (decision 114, item 5),
handing it a `Response` built over rakun's `ChunkWriter` (decision 117 rule 1):

```bp
// onze, at boot — not jhonstart code
rakun.page(pattern, fn(req: Request, out: ChunkWriter) -> @Task<void> {
    return site.renderStream(input(req), requestData(req), Response(
        status: fn(c) { out.setStatus(c); },
        header: fn(n, v) { out.setHeader(n, v); },
        write:  fn(chunk) { return out.write(chunk); },
        close:  fn() { return out.close(); },
    ));
});
```

`req` is the `RequestData` onze built from rakun's `Request` (item 8); the render enters it through
front 28's `enterRequest` before the tree is built and leaves it at the end. `renderStream` awaits
`res.write` for the shell and then for each fill as its boundary completes. `render` is the
non-streaming form: it resolves every boundary before it writes anything and hands the whole
document to `res.write` once, so every signal it meets is before the first chunk. Both answer no
reason: they resolve when the response is closed, and a failed render — a refused redirect target,
a plugin's `close` answering `Error`, `status` / `header` after the first write — fails the render.
Under decision 120 a `@Task` never fails, so that failure has to be a `@Result` inside the value:
which `E` the two functions answer (`-> @Task<@Result<void, E>>`) and whether `Response.write` stays an
infallible `@Task<void>` is front 24's open point 8, settled with this library's E7 sweep. The signal translation is *Navigation signals* above.

**Acceptance:**
- [x] a page with one boundary produces at least three `write` calls, the first ending inside
      `<body>`, each awaited before the next — `test/streaming_test.bp` "stream: a page with boundaries writes the shell, then each fill, each awaited"
- [x] a component calling front 28's `request()` / `headers()` / `cookies()` reads the `req` the
      render received; after the render ends, `request()` outside a render raises — `test/streaming_test.bp` "stream: a component reads the req the render received, and nothing after it ends"
- [x] every id in the payload's `h` appears in exactly one `data-jh-f` template in a later chunk — `test/streaming_test.bp` "stream: fills come in completion order…"
- [x] hole ids are `h1`, `h2`, … in shell order, and a page whose boundaries resolve in reverse
      order still numbers them in shell order — `test/streaming_test.bp` "stream: fills come in completion order…" (h2 resolves first, keeps its id)
- [ ] a boundary that resolves before the shell is written produces no hole and no fill
- [x] two boundaries that resolve out of order produce fills in resolution order, each carrying its
      own markup — `test/streaming_test.bp` "stream: fills come in completion order, each carrying its own markup"
- [ ] sibling server components are handed to front 02 as **unstarted thunks** in one await; two
      50 ms loaders finish in well under 100 ms on `--target erlang`, and the same test over
      already-started `@Task` values is kept as the regression case
- [x] `defaultHooks()` renders a working document with no `<script src>`; replacing one field leaves
      the other at its default — `test/streaming_test.bp` "stream: defaultHooks renders a working document with no <script src>; one field replaced keeps the other"
- [x] a page raising jhonstart's `notFound()` (front 31) before the first chunk makes the render
      call `res.status(404)` and write a document whose body is the nearest `not-found` boundary,
      then `res.close()` once — asserted by a recording `Response` — `test/streaming_test.bp` "signal: notFound before the first chunk is a 404 with the nearest not-found boundary"
- [x] `redirect("/login")` raised before the first chunk, with `/login` in `PageInput.table`, calls
      `res.status(307)`, `res.header("location", "/login")`, `res.close()`, and `res.write` zero
      times — `test/streaming_test.bp` "signal: redirect(\"/login\") before the first chunk is a 307 with no body"
- [x] a layout whose `use cookies()` finds no session and raises `redirect("/login")` produces the
      same 307, and the page's function is never called (a marker the page appends stays empty) — `test/streaming_test.bp` "signal: a layout's redirect means the page never runs"
- [x] `redirect("/nowhere")` (not in the table) and `redirect("https://evil.example")` with
      `allowedRedirects` empty fail the render before the first chunk: no status, no `location`,
      the render's failure names the target; `redirect("https://accounts.example/")` with that
      target listed in `app(allowedRedirects: [...])` is a 307 to it — `test/streaming_test.bp` "signal: a target outside the table, or an unlisted absolute one, fails the render"
- [x] `res.status` or `res.header` after the first `write` fails the render, naming the call — `test/streaming_test.bp` "response: status after the first write fails, naming the call"
- [x] `res.close()` is called exactly once on every path; a normal render answers `Ok` and a
      failed render answers its failure — neither answers a reason string — `test/streaming_test.bp` (`countOf("close") == 1` on every path)
- [x] a signal raised after the first `write` is Step 12's, not this step's

### Step 9 — The `jhonstart-emilia` bridge

A member of this workspace, `repository/jhonstart/modules/jhonstart-emilia/`, versioned with the
contract it implements (decision 113, item 7). It is the only package that knows jhonstart and
emilia; emilia does not change and imports nobody.

```
modules/jhonstart-emilia/
├── botopink.json      "dependencies": { "jhonstart": { "workspace": true }, "emilia": … }
├── src/root.bp        pub fn plugin() -> RenderPlugin — head and chunk await emilia's flush(); payload is #("s", …)
└── test/bridge_test.bp   the emilia + jhonstart test: contract 4's literal, rendered
```

```bp
// jhonstart-emilia/src/root.bp
import {RenderPlugin} from "jhonstart";
import {flush} from "emilia";

pub fn plugin() -> RenderPlugin { … }
// head():      await flush(), recording the class names it flushed
// chunk(id):   await flush(), the same
// close():     Error if await flush() is not ""
// payload():   #("s", the recorded class names as a JSON array)
```

The bridge keeps the list of class names it has flushed for this render, and `payload` returns it
under `s` (decision 114, item 2) — the list the client checks with `checkStyles(payload.s)` (front
68).

onze registers it at boot — `app(plugins: [emiliaPlugin()])` — and that is onze's whole part in the
CSS moment.

**Acceptance:**
- [x] `botopink.json` declares `jhonstart` as `{ "workspace": true }` (decision 75) and `emilia` as
      a dependency; the member's `targets` match jhonstart core's — `modules/jhonstart-emilia/botopink.json` (`emilia` by `path` into the sibling library; no `targets`, so it inherits the workspace's, as the core does)
- [x] a page styled with `emilia([...])` and rendered with `app(plugins: [plugin()])` has one
      `<style>` in `<head>` — `head` was called once — `jhonstart-emilia/test/bridge_test.bp` "bridge: a styled page has one <style> in <head>, carrying its class"
- [x] a streamed boundary whose subtree registers a new class carries its CSS as
      `<template data-jh-f="h1"><style>…</style>…</template><script>__bp1("h1")</script>`, style
      before markup — `jhonstart-emilia/test/bridge_test.bp` "bridge: a streamed boundary's new class is its fill's style, before the markup"
- [x] after the last chunk `close` is `Ok`; a class registered after the last `chunk` makes it
      `Error` and the render fails — `jhonstart-emilia/test/bridge_test.bp` "bridge: close is Ok after the last chunk and Error for a class registered later"; `test/streaming_test.bp` "plugin: a close answering Error…"
- [x] the payload's `s` lists exactly the class names in the document's `<style>` blocks (head and
      fills), in flush order, and a render with no emilia class writes `"s":[]` — `jhonstart-emilia/test/bridge_test.bp` "bridge: the payload's s lists the flushed classes, and [] when there were none"
- [ ] the contract-4 class literal (`contracts.md § 4`'s shared fixture) is asserted here, on a
      rendered document — the bridge's test is the one test that renders emilia classes with
      jhonstart (decision 114, item 6), and emilia's own `modules/emilia/test/attributes_test.bp`
      asserts the same literal without HTML
- [ ] the builders and the `html` DSL render an element with an emilia class slot byte for byte
      the same, and `withAttrs` / `attrValue` over a built tree read that class back — front 48's
      rendered cells, which need jhonstart and therefore live here
- [ ] a rendered element with a static class and an emilia class writes `class="<static> <emilia>"`:
      static first, one ASCII space, no sorting, attributes in array order (contract 4, clauses 4
      and 5)
- [x] `grep -rn emilia modules/jhonstart/src` is empty — the bridge is the only member naming emilia
- [x] no file of `repository/emilia/` changes for this step

### Step 10 — The UI file conventions — `routes.bp`

`src/routes.bp`. A folder under `app/` is a URL segment and a file in it gives the segment its UI
(`NEXTJS-DOCS.md § 3`). The four file conventions that return an `Element` are this front's
(decision 114, item 4); rakun registers only an opaque `PageRenderer` per route and never names
them. One decorator per file, taking the app-relative directory of the file it sits in:

| File in `app/` | Decorator | Signature the registry pins |
|---|---|---|
| `layout.bp` | `#[layout(seg)]` | `fn(props: LayoutProps) -> @Component<ElementBase, Element>` |
| `template.bp` | `#[template(seg)]` | `fn(props: LayoutProps) -> @Component<ElementBase, Element>` |
| `page.bp` | `#[page(seg)]` | `fn(route: PageContext) -> @Component<ElementBase, Element>` |
| `default.bp` | `#[defaultView(seg)]` | `fn(props: LayoutProps) -> Element` |

A layout, a template and a page are components (decision 117 rule 3, over decision 102): each may
`await` and `use` hooks — `use cookies()` and the other request hooks of front 28 read the
`RequestData` the render was handed (decision 114 item 8) — and each may raise a navigation signal,
which *Navigation signals* handles the same way wherever it was raised. A function under
`#[layout]`, `#[template]` or `#[page]` without a `-> @Component<ElementBase, Element>` return is a compile
error the marker raises, naming the function and the form it needs; there is no plain-layout form
(decision 67):

```bp
import {redirect, cookies, pairValue, Element, LayoutProps, div} from "jhonstart";

#[layout("dashboard")]
pub fn DashboardLayout(props: LayoutProps) -> @Component<ElementBase, Element> {
    val jar = use cookies();                                     // front 28, over the RequestData
    if (pairValue(jar, "session") == "") { redirect("/login"); } // before the first chunk: a 307
    return div([Sidebar(), props.children], attrs: []);
}
```

`default` is a reserved keyword, so the `default.bp` marker is spelled `#[defaultView]`. `route.bp`
is not a UI convention: its handlers are rakun front 25's. `loading.bp`, `error.bp` and
`not-found.bp` export an undecorated `Loading()` / `Error(…)` / `NotFound()` (this front and front
31) and reach `compose` through the same registry.

```bp
pub type PageContext(
    pathname: string,
    pattern: string,
    params: Array<#(string, string)>,
    query: Array<#(string, string)>,
    rest: string[],
)

pub type LayoutProps(
    route: PageContext,
    children: Element,
    slots: Array<#(string, Element)>,
)

pub fn page(comptime decl: @Decl, seg: string)
pub fn layout(comptime decl: @Decl, seg: string)
pub fn template(comptime decl: @Decl, seg: string)
pub fn defaultView(comptime decl: @Decl, seg: string)

#[@External.Erlang("jhonstart_routes", "register_page")]
#[@External.Node("./routes.mjs", "registerPage")]
pub declare fn jhRegisterPage(seg: string, render: fn(route: PageContext) -> @Component<ElementBase, Element>) -> i32;
// … `jhRegisterLayout`, `jhRegisterTemplate` the same shape over `LayoutProps`;
// `jhRegisterDefault` over `fn(props: LayoutProps) -> Element`

pub fn uiTable() -> string   // this registry's records as contract-1 lines (`L`, `T`, `P`, `D`, `S`, `E`, `N`)
```

`PageContext`'s plural fields are pair lists, the shape front 26's snapshot and front 28's
`RequestData` use, read with front 26's `pairValue`. `LayoutProps` is one record rather than three
parameters because declared parameter defaults are never applied: a layout that uses no slot would
otherwise spell an empty `slots:` at every call site the registry generates.

Each decorator body `@emit`s its registration — a module-level `val` calling a registry cell, so it
runs at module load — then the per-route parameter accessor, then enforces placement with
`decl.fail`:

```bp
val __jhPage_blogPostPage = jhRegisterPage("blog/[slug]", blogPostPage);

pub fn blogPostPageParams(route: PageContext) -> #(slug: string) {
    val slug = pairValue(route.params, "slug");
    return #(slug);
}
```

A catch-all emits `val slug = route.rest;` and types the field `string[]`; a route with no dynamic
segment emits `-> #()`. A decorator body cannot call a sibling function, a `//` comment in it breaks
the flattened emit, and nothing optional works in a comptime body — so the segment decoding is
inlined in each body, comment-free, over `split` / `forEach` / `push` / `join` / `indexOf` / `length`.
The segment grammar the decorators decode is contract 1's; the canonical parser is `routing`'s
`parsePath` — a decorator body cannot call it at comptime, so the decoding is inlined, and the round
trip below, in this front's own test, is what keeps the two equal.

**onze wires the registry to rakun.** At boot onze reads `uiTable()`, registers each record in
rakun's route table (so the table the server matches and the payload's `t` are one table, contract
1), and for every `P` pattern registers one `PageRenderer` with rakun's `page(pattern, render)` that
builds the `PageInput` from this registry and calls `renderStream`. Nothing in this file names rakun
or onze.

**Acceptance:**
- [x] `#[page("blog")]` on a `fn(route: PageContext) -> @Component<ElementBase, Element>` compiles and
      puts one `P|/blog||` record in `uiTable()` — `test/routes_test.bp` "routes: each marker puts its contract-1 line in uiTable…" (the line is `P|/blog`: `routing`'s `writeTable` drops trailing empty fields)
- [x] `#[page("blog")]` on a type fails with `#[page] must annotate a function`; `#[page]`,
      `#[layout]` and `#[template]` on a function returning `Element` /
      `@Task<Element>` rather than `@Component<ElementBase, Element>`, fail at compile time naming the function
      and `fn … -> @Component<ElementBase, Element>` (decision 117 rule 3) — `test/routes_test.bp` header records each refusal's message
- [x] `#[layout("")]` registers the root layout at `/`; `#[layout("(marketing)")]` contributes no
      segment to the pattern — `test/routes_test.bp` "routes: a group contributes no segment — (marketing) is the root pattern"
- [x] `#[page("blog/[slug]")] pub fn blogPostPage(...)` makes `blogPostPageParams` available in the
      same module with a `slug: string` field; `#[page("shop/[...slug]")]` types it `string[]`;
      `#[page("about")]` returns `#()` — `test/routes_test.bp` "routes: blogPostPageParams…", "routes: a catch-all's field is string[]", "routes: a page with no dynamic segment answers the empty tuple"
- [x] `uiTable()` is asserted as contract-1 literals (`L|/||`, `P|/blog/[slug]||`, …), the same
      literals `routing`'s tests pin, and `test/routes_test.bp` round-trips it through `routing`'s
      `parseTable` and `patternOf(parsePath(seg))` — jhonstart imports the bundled library directly
      (decision 115) — `test/routes_test.bp` "routes: the table round-trips through routing's parseTable and parsePath"
- [x] no `rakun` identifier appears in `routes.bp`, `routes.mjs` or `jhonstart_routes.erl`
- [x] the tests that exercise the decorators run under `botopink test`, not `botopink check` —
      `check` skips decorator invocation and reports every `@emit`ted name as unbound — `test/routes_test.bp` header

### Step 11 — Module wiring

front 94 owns `src/root.bp` and `botopink.json`'s `files` list; this front hands it the lines rather
than editing either file, and front 94 appends in front-number order: `pub mod suspense;`,
`pub mod streaming;`, `pub mod render;`, `pub mod plugin;`, `pub mod globals;`, `pub mod routes;`,
and the file names (with `render.mjs`, `routes.mjs` and `sidecars/jhonstart_routes.erl` as shipped
sidecars). The `jhonstart-emilia` member is added to the workspace
manifest's `workspaces` by this front, in its own commit.

**Acceptance:**
- [ ] the `pub mod` lines and `files` entries are handed to front 94; this front edits neither
      `src/root.bp` nor `botopink.json` of the core member
- [x] `streaming.bp` imports `Boundary` from `"suspense"` by explicit module name, not the bare
      shorthand — the bare form lowers to `require("../suspense")` and breaks when jhonstart is
      consumed as a dependency (`html.bp:87-92`)
- [x] `repository/jhonstart/AGENTS.md` names `render.bp`, the payload version, the plugin order,
      the globals registry and the UI conventions of `routes.bp`, in the same commit — `AGENTS.md` tree + `src/AGENTS.md`

### Step 12 — Late signals: a signal after the first chunk (decisions 115 rule 2 and 117)

The after-the-first-chunk half of *Navigation signals* above. `streaming.bp` wraps each boundary's resolution: a raised reason
for which `navigation.isSignalReason` holds is read with `navigation.signalFromReason` and, once the
shell has been written, turned into the last chunk; a reason that is not a signal goes to the
nearest error boundary unchanged.

**Acceptance:**
- [x] a boundary raising `notFound()` after the shell was written produces a last chunk
      `<template data-jh-g="not-found">…</template><script>__bp2()</script>` carrying that
      boundary's nearest not-found markup (plugin CSS first inside the template), writes no later
      fill, closes the plugins, and calls `res.close()` once — `test/streaming_test.bp` "late: a notFound after the shell is the last chunk, status 200, no later fill"
- [x] a boundary raising `redirect("/blog")` after the shell, with `/blog` found by `routing`'s
      `matchPath` in `PageInput.table`, produces
      `<template data-jh-g="redirect" data-jh-to="/blog"></template><script>__bp2()</script>` and
      `data-jh-to` goes through `escape.attribute`; an absolute target listed in
      `app(allowedRedirects: [...])` is written the same way — `test/streaming_test.bp` "late: a redirect after the shell is data-jh-g markup through escape.attribute"
- [x] `redirect("/nowhere")` (not in the table) and `redirect("https://evil.example")` (absolute,
      not listed) after the shell fail the render and write no signal markup — no option writes
      them anyway (decision 67) — `test/streaming_test.bp` "late: a refused target after the shell fails the render and writes no markup"
- [x] the status the caller observes is 200 in every late case: the render calls `res.status` /
      `res.header` never once a chunk is out — asserted by a recording `Response` — `test/streaming_test.bp` "late: …" (`countOf("status") == 1`)
- [x] the signal script's name comes from `globals.signal` (`__bp2`), never a literal — `notFoundSignalHtml` / `redirectSignalHtml`
- [x] `render.bp` and `streaming.bp` spell no `nav:` or `jhonstart:` literal and define no
      `signalFromReason`: `grep -rn '"nav:\|"jhonstart:' modules/jhonstart/src/{render,streaming}.bp`
      is empty
- [ ] `render.mjs`'s signal function, on `redirect`, navigates to `data-jh-to` through front 26's
      client router (`history.replaceState`, no reload) for a relative target and with
      `location.replace` for a listed absolute one; on `not-found`, replaces `[data-jh-root]`'s
      content with the template's and drops any later fill

## Examples

- [`examples/streamed-blog-page-example.bp`](./examples/streamed-blog-page-example.bp) — a blog index
  whose header flushes immediately and whose post list arrives in a second chunk.
- [`examples/loading-convention-example.bp`](./examples/loading-convention-example.bp) — the
  `loading.bp` a developer writes, and the boundary `compose` builds around it.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| `Children` coerces from an array, an `Element` or a string (`infer.zig:4228-4239`) but not from a deferred value, so a boundary's child cannot be a child | `Boundary` is a record holding a `fn() -> @Component<ElementBase, Element>` beside the fallback, instead of `Suspense(fallback, child)` taking the child as `Children` | a record | let `Children` accept a thunk, resolved by the renderer |
| `await` is not safe as a lambda's last statement — a lambda's last statement must be an implicit-return expression, and nothing in the tree awaits in one | `resolve(b)` awaits one boundary; `renderStream` spawns, it does not map | one await per call, at statement level | an awaiting lambda, so `boundaries.map({ b -> await resolve(b) })` types |
| Declared parameter defaults are never applied | every `Element` builder call in both examples spells `attrs: []`; `LayoutProps` is one record | write every argument | apply the declared default when an argument is omitted |
| `@Decl` carries no source location, so a decorator cannot learn which file it annotates | every `#[page(...)]` / `#[layout(...)]` (Step 10) | the app-relative directory is an explicit decorator argument, verified against the tree by rakun front 22's scan | `decl.source() -> Source` |

## Test plan

`modules/jhonstart/test/render_test.bp` and `test/streaming_test.bp`, run by `botopink test
--target erlang` from `repository/jhonstart`, and in the ecosystem gate by
`zig build test-libs -- --target erlang --lib jhonstart`; `render.mjs` and the payload reader run on
`--target commonJS` against the same fixture strings the erlang row writes — the payload round trip
is one test across both rows. `modules/jhonstart-emilia/test/bridge_test.bp` runs on the targets its
manifest declares.

Streaming assertions are string assertions over the chunks handed to `write`, not timing
assertions, except the one that proves front 02's spawn is concurrent. Constructing a `Boundary`
runs nothing — a thunk that appends to a module-level marker proves the child has not started, which
is the assertion that catches the eager-`@Task` mistake.

## Definition of done

- [ ] `render.bp`, `plugin.bp`, `globals.bp`, `routes.bp`, `suspense.bp`, `streaming.bp`,
      `render.mjs` and `routes.mjs` in the
      build tree, their `root.bp` and `files` lines handed to front 94
- [x] no path in the render calls `renderToString`; the grep is part of the gate
- [ ] the payload key table of `contracts.md § 2` is this front's, and the fronts that cite it
      (24, 26, 27, 29, 60, 61, 63, 68) cite `contracts.md`, not a re-derivation
- [x] every marker the render writes is `data-jh-*` and every global comes from `globals.bp`
- [x] a navigation signal is translated here and nowhere else (decision 117): before the first
      chunk a 307 + `location` or a 404 with the not-found document through `Response`, after it
      markup with status 200 — Steps 8 and 12, reading the `nav:` reasons with `routing`'s
      `navigation` (decision 116) — `streaming.bp` `early` / `writeLateSignal`
- [x] every redirect target is checked before anything is written: relative through `matchPath` on
      `PageInput.table`, absolute only when listed in `allowedRedirects` (decision 117) — `redirectAllowed`
- [x] `#[layout]`, `#[template]` and `#[page]` accept only `fn … -> @Component<ElementBase, Element>`
      (decision 117 rule 3) — `routes.bp`
- [x] the payload is written with std's `json` writers and `escape.scriptJson`; `render.bp` has no
      JSON escaper of its own (decision 116)
- [x] `RenderHooks` carries `headExtra` and `bodyExtra` only; the style moments and the plugin
      payload keys are `RenderPlugin`'s four asynchronous methods
- [x] `routes.bp` carries the four UI decorators, `PageContext`, `LayoutProps` and the accessors;
      rakun names none of them
- [x] the `jhonstart-emilia` member exists, its tests are green, and `repository/emilia/` is
      unchanged — 6/6 on both rows
- [x] nothing under `repository/jhonstart/` imports `rakun`, `onze` or (outside the bridge) `emilia`
- [x] all four language gaps appear in a `specs/1.0.10-beta/` spec — `language-gaps.md` rows "`Children` coerces…", "`await` is unusable as a lambda's last statement", "Declared parameter defaults…", "`@Decl` carries no source location"
- [x] the front's tests are green on both rows — core 181/181, `jhonstart-emilia` 6/6 on commonJS and erlang

# Front 30 — Jhonstart Render and Streaming

**Track:** C jhonstart
**Priority:** high — jhonstart is the package that writes HTML (decision 113): without this front there is no escaping walker, no document and no payload in the package that owns them, and one slow loader holds the whole page
**Target:** both — boundary. The render, the escaping, the document, the payload writer and the chunk production are erlang; the fill function and the payload reader (`render.mjs`) are js; the payload format and the globals registry are the contract between them
**Boundary:** the server produces the shell, the fills and the payload; the browser consumes them. Every marker and global the HTML carries is written here or by another jhonstart front: `data-jh-*` markers (`contracts.md § 2`) and the two `__bp<N>` globals of this front's registry (decision 113)
**Wave:** 5
**Depends on:** 28 · 29 (`islandAttr`, `islandEntry`) · 31 (`renderBoundaryChecked`) · 32 (`renderHead`, `mergeMetadata`) · 02 (spawn/gather over unstarted tasks) · 01 (`escape.html` / `escape.attribute`) · 94 (`isVoidTag`, `isRawTextTag`, element builders) — and no rakun, onze or emilia module: onze hands in the route data, the chunk writer and the plugins
**Owns:** `repository/jhonstart/modules/jhonstart/src/render.bp` (the escaping walker, `compose`, the document, `Payload` and its writer — contract 2 — the island and hole ordinals, `render`/`renderStream`, the `RenderHooks` record and `app`), `repository/jhonstart/modules/jhonstart/src/plugin.bp` (`RenderPlugin` and the order it is called in), `repository/jhonstart/modules/jhonstart/src/globals.bp` (the globals registry, `readPayload`, `registerFill`), `repository/jhonstart/modules/jhonstart/src/render.mjs` (the browser fill function and payload reader), `repository/jhonstart/modules/jhonstart/src/streaming.bp`, `repository/jhonstart/modules/jhonstart/src/suspense.bp`, their tests (`test/render_test.bp`, `test/streaming_test.bp`), and the bridge member `repository/jhonstart/modules/jhonstart-emilia/**`
**Does not touch:** `src/element.bp`, `src/hooks.bp`, `src/html.bp` (frozen), `src/router.bp` (26), `src/link.bp` (27), `src/server.bp` (28), `src/client.bp` (29), `src/error_boundary.bp` (31), `src/metadata.bp` (32), `src/root.bp` and `botopink.json` (front 94); `repository/emilia/**` (emilia does not change — decision 113), `repository/rakun/**`, `repository/onze/**`
**Reference:** `NEXTJS-DOCS.md § 13. Streaming` · `§ 5. Layouts e Páginas` · `§ 7. Server e Client Components` · `§ 4. Hierarquia de renderização` · https://nextjs.org/docs/app/guides/streaming · https://nextjs.org/docs/app/api-reference/file-conventions/loading · [decision 113](../../decisions-taken.md#113-the-libraries-split-by-concern-emilia-is-css-jhonstart-is-html-rakun-is-the-service-on-erlang-onze-wires-them)

---

## Problem

**jhonstart writes the HTML, and today it has no renderer that is safe to ship.** `renderToString`
concatenates: a `#text` node returns `e.value` verbatim and an attribute becomes
`" " + a._0 + "=\"" + a._1 + "\""` with no escaping anywhere (`element.bp:55-67`), and it closes
void tags (`<input></input>`). `element.bp` is frozen for the milestone, so the escaping walker, the
document shell and the payload the browser reconnects to are a new file in this package —
decision 113 puts the whole HTML render in jhonstart: *"quem deve ser responsável pelo html é o
jhonstart"*. rakun (front 23) routes, opens the request scope, calls the function onze hands it and
writes the chunks; it builds no markup. The render that `repository/rakun/src/ssr.bp` carries today —
`renderNode`, `raw`, `compose`, `document`, `Payload`, `RenderHooks` — is the code this front
receives; rakun front 23 removes its copy when this front lands.

emilia's CSS reaches the document through this front too: jhonstart declares a render-plugin point
and calls it at the three moments CSS has to be written (the head, each streamed boundary, the end),
and the `jhonstart-emilia` bridge — a member of this workspace — adapts emilia's `flush()` to it.
jhonstart never names emilia.

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
- `src/root.bp:15-17` — no `suspense`, no `streaming`.
- `#[@future]` + `await` work and are exercised (`repository/emilia/src/emilia.bp:62-65`,
  `:475-480`).
- Nothing in the repository emits more than one string per render, and nothing reads a partial one.
- `libs/std/src/http.bp:16-18` — "Erlang is eager: `@Future<T>` resolves to `T` … so the caller's
  `await fetch(url)` is identity on that backend." There is no concurrent scheduler behind `@Future`
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
rakun   match the request against front 22's table, open front 62's request scope, setPhase(Render)
onze    turn the match into a `PageInput` (route data + jhonstart `Segment`s), pass rakun's chunk writer
30      compose(chain, page)          layout > template > error > loading > not-found > page
30      renderNode(tree)              escaping walker, void-aware
30      plugins: head / chunk / close the CSS moments (`plugin.bp`)
30      document(head, body, payload) the bytes, as an ordered chunk list
rakun   write each chunk as it is produced
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
from front 22's layout chain, so jhonstart never names a rakun type (decision 113). A `template`
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
know where they come from. `m`, `q` and island props are querystring-encoded. **Payload escaping:**
`<`, `>` and `&` are written as `\u003c`, `\u003e`, `\u0026`, and U+2028/U+2029 as `\u2028`/`\u2029`,
so `</script` is unrepresentable inside the block.

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

pub type App(plugins: Array<RenderPlugin>)
pub fn app(plugins: Array<RenderPlugin>) -> App
```

The four style-sink fields of rakun's `ssr.bp` record are replaced by the plugin list, and `islandAttr`
leaves: the render that writes the island is jhonstart's, and it calls front 29's function directly.
onze fills `RenderHooks` and calls `app(plugins: [...])` at boot; this file names neither onze nor
any plugin.

### The render plugin — `plugin.bp`

```bp
pub behavior RenderPlugin {
    fn head(self: Self) -> string;                   // once, after the shell
    fn chunk(self: Self, holeId: string) -> string;  // per boundary, before its markup
    fn close(self: Self) -> @Result<void, string>;   // at the end: nothing may be left
}
```

The rules belong to the caller, so they are this front's (they were onze front 69's sink rules):

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

Plugins are called in the order `app` received them. A render with no plugin writes no `<style>`.

### The globals registry — `globals.bp` and `render.mjs`

Only two values exist in `window`, because the HTML names them by text: the payload variable and
the fill function the fill's `<script>` calls. Each gets an indexed alias `__bp<N>` from this
registry, `N` counting up in **declaration order in this file**, so the server build and the client
build agree without exchanging anything:

```bp
// src/globals.bp — one entry per global the HTML names; the order is the contract
val registry = ["payload", "fill"];

pub fn alias(name: string) -> string    // "__bp" + the name's index; an unknown name fails
pub val payload = alias("payload");     // "__bp0"
pub val fill = alias("fill");           // "__bp1"
```

No alias is spelled by hand: adding a global is one registry entry, and its name follows from its
position.

`render.bp` writes `window.<globals.payload> = …` and `<script><globals.fill>("h1")</script>`;
`render.mjs` defines the fill function under `globals.fill` and `readPayload(name)` /
`registerFill(name, holes)` read the same names. No global is written by hand anywhere in the
milestone, and link and form mount are ordinary imports (`linkMount`, `formMount` — fronts 27 and
67). `readPayload` and `registerFill` are `#[@External.Node]` cells called only by onze's generated
client entry; nothing on the erlang row calls them.

### What makes it actually stream

`@Future` is eager on the BEAM (`libs/std/src/http.bp:16-18`). A list of futures is therefore a list
of results that have *already* been computed, in order, before anything was flushed — and a
"progressive flush" driven by awaiting such a list flushes everything at once, after the slowest
boundary, having paid the sum of all of them. It would pass a test that checks the chunks and fail
the only thing a reader can see.

So a boundary in this design holds an **unstarted task** — `fn() -> @Component<Element>`, a thunk
over a server component (decision 104: a component that awaits is `#[@use] fn … -> @Component<Element>`,
and `@Component ⊃ @Future`, so `await b.child()` is legal in a `#[@future]` body) — and progressive
flush is driven by the completion of **spawned work**, one BEAM process per boundary, gathered by
index. Front 02 owns spawning and gathering, and its surface takes exactly
that shape: `Array<fn() -> @Future<T>>`. `renderStream` spawns the boundaries, hands the shell to
rakun's chunk writer immediately, and hands each fill to it as its process reports.

The division of labour follows from it:

| Who | Does what |
|---|---|
| this front | defines `Boundary` (a thunk, not a future), the placeholder markup and `Chunk`; `renderStream` produces the shell, then each completion's fill (with its plugin CSS), in completion order |
| front 02 | spawns the thunks and reports completions by index |
| rakun (front 23), through onze | writes each chunk it is handed, and closes the response |
| `render.mjs` / onze front 68's entry | adopts each fill in the browser |

`renderStream` never awaits a list: `resolve(b)` awaits **one** boundary, inside each spawned
process.

### The erlang half — this front

A boundary is a record, not an element:

```bp
pub type Boundary(
    id: string,
    fallback: Element,
    child: fn() -> @Component<Element>,
)
```

`Suspense(b)` renders only the **hole**: the fallback, wrapped in the marker `contracts.md § 2`
pins. That goes out with the shell.

```
<div data-jh-h="h1"><div class="skeleton">Loading posts…</div></div>
```

`resolve(b)` is `#[@future]` and awaits the child exactly once, at statement level, returning a
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
per boundary in **completion** order, and hands each to the chunk writer onze passed in (rakun's);
it never holds a completed fill back. rakun decides nothing about the markup.

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

`render.mjs` implements it; front 68's generated entry calls `registerFill(globals.fill, payload.h)`
before any island hydrates. `streaming.bp` and `render.bp` carry **no** `#[@External.Node]` cell;
the browser cells are `globals.bp`'s two, called only from the entry.

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
no annotation (decision 104). Front 22 discovers the file (kind `S`
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
    child: fn() -> @Component<Element>,
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
- [ ] `renderNode(Suspense(b))` emits the fallback inside `<div data-jh-h="h1">` and nothing else —
      the child is not rendered and does not appear in the shell
- [ ] `holeId(1) == "h1"`, `holeId(0) == "h0"` — the spelling `contracts.md § 2` pins
- [ ] a `Boundary` carries the ordinal the render assigned it, in shell order
- [ ] `Suspense` reaches no host cell

### Step 2 — `Chunk`, `resolve`, `fillHtml`

```bp
// src/streaming.bp
import {Element} from "element";
import {Boundary} from "suspense";
import {renderNode} from "render";
import {globals} from "globals";

pub type Chunk(id: string, html: string)

#[@future]
pub fn resolve(b: Boundary) -> @Future<Chunk> {
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
- [ ] `resolve` awaits exactly once, at statement level, never inside a closure
- [ ] `resolve` of a boundary whose child returns immediately produces the rendered child, through
      `renderNode`
- [ ] `fillHtml(Chunk(id: "h1", html: "<ul></ul>"), "")` is exactly
      `<template data-jh-f="h1"><ul></ul></template><script>__bp1("h1")</script>` — the literal
      `contracts.md § 2` pins, asserted here and on the browser side
- [ ] `fillHtml(Chunk(id: "h1", html: "<ul></ul>"), "<style>.e_1{}</style>")` puts the `<style>`
      first inside the `<template>`, with no attribute of its own
- [ ] a chunk id is always `h<n>` from `holeId`, so the quote and `</script` cases cannot arise —
      a test asserts `holeId` produces nothing outside `[h0-9]`

### Step 3 — The escaping walker

```bp
// src/render.bp
pub fn renderNode(e: Element) -> string
pub fn raw(html: string) -> Element
pub fn shellHtml(page: Element) -> string   // renderNode(page): the shell, every boundary showing its fallback
```

**Acceptance:**
- [ ] `renderNode(text("<script>alert(1)</script>", attrs: []))` contains no `<`
- [ ] an attribute value containing `"` renders as `&quot;` and the produced tag re-parses
- [ ] `renderNode(Element(tag: "input", value: "", children: [], attrs: [...]))` emits no closing
      tag; the void set is front 94's `isVoidTag` and this front keeps no list of its own, checked
      by grep in its gate
- [ ] a `style` body containing `a > b` renders verbatim — not `a &gt; b` — and so does a `script`
      body containing `&&`
- [ ] a `script` or `style` body containing `</script` or `</style`, in any case, **fails the
      render** with the tag named; it is not escaped, and no configuration makes it escaped
- [ ] a raw-text body (front 94's `isRawTextTag`) is the only text this walker does not escape, and
      `#raw` is the only element
- [ ] `renderNode(raw("<b>x</b>"))` is `<b>x</b>` exactly
- [ ] `renderNode` and `renderToString` produce the same string for a tree with no special
      characters and no void tag — the walker is a superset, not a divergence
- [ ] `shellHtml` of a page containing two boundaries emits both placeholders and neither child,
      and adds no doctype and no head — the document is Step 4's
- [ ] no path in `render.bp`, `streaming.bp` or `suspense.bp` calls `renderToString` — checked by
      grep in the gate, because a single call is the whole hole

### Step 4 — Composition and the document

```bp
pub type Segment(…)   // one segment's conventions and its pattern — jhonstart's record
pub fn compose(chain: Array<Segment>, page: Element) -> Element
```

**Acceptance:**
- [ ] for a chain of one segment holding all six conventions, the rendered nesting is
      `layout > template > error > loading > not-found > page`, asserted on the markup string
- [ ] for `/blog/[slug]`, the root layout is the outermost element and the page innermost
- [ ] a segment with no `template.bp` contributes no wrapper — the nesting shrinks, it does not gain
      an empty `div`
- [ ] a `template` wrapper carries `data-jh-t` with the pattern and the navigation counter; two
      renders of one route produce two values
- [ ] each layout render receives its `selected` depth: a three-deep chain yields `0, 1, 2`
- [ ] the composed tree sits inside `<div data-jh-root="">`, and an unmatched not-found boundary
      renders as `data-jh-n`
- [ ] `Segment` and `compose` name no rakun type; `grep -rn rakun modules/jhonstart/src` is empty

### Step 5 — The payload (contract 2)

```bp
pub type Payload(
    build: string, pathname: string, pattern: string, params: string, query: string,
    table: string, islands: Array<#(string, string, string)>, actions: Array<#(string, string)>,
    styles: string, holes: string[], dynamic: bool,
)

pub fn writePayload(p: Payload) -> string
pub fn payloadEscape(json: string) -> string
```

**Acceptance:**
- [ ] the document carries exactly one `<script>window.__bp0 = {…}</script>`, last in `<body>`
      before `RenderHooks.bodyExtra`, and the name comes from `globals.payload`
- [ ] `writePayload` emits `v` first and `1` as its value
- [ ] `payloadEscape` leaves no literal `<`, `>` or `&`, and a payload whose params contain
      `</script>` produces a document with exactly the real script closers and no `<img`
- [ ] `t`, `a` and `b` are written verbatim from the strings the caller passed; the render derives
      none of them
- [ ] island ids are `i0`, `i1`, … in render order, written through front 29's `islandAttr`, and
      the payload's `i` array is in the same order
- [ ] parsing the emitted value with `JSON.parse` (commonJS) and `json:decode/1` (erlang) yields the
      same field set — the round trip is the test, not two half-tests

### Step 6 — `RenderPlugin` and the order it is called in

```bp
// src/plugin.bp
pub behavior RenderPlugin {
    fn head(self: Self) -> string;
    fn chunk(self: Self, holeId: string) -> string;
    fn close(self: Self) -> @Result<void, string>;
}
```

**Acceptance:**
- [ ] with a recording plugin, a streamed render with two boundaries calls `head` once, `chunk`
      once per boundary (`h1`, `h2`, in completion order) and `close` once, last
- [ ] `head`'s string lands in `<head>`; each `chunk`'s string lands first inside its fill's
      `<template data-jh-f="…">`, before the boundary's markup, with no marker
- [ ] a plugin whose `close` returns `Error(…)` fails the render with that message
- [ ] a render with no plugin emits no `<style>` and calls nothing
- [ ] the word `emilia` appears in no file under `modules/jhonstart/` — jhonstart knows the
      contract only (decision 113)

### Step 7 — The globals registry and `render.mjs`

**Acceptance:**
- [ ] `globals.payload == "__bp0"` and `globals.fill == "__bp1"`, derived from the registry's
      declaration order, on both targets
- [ ] no `__bp` literal appears in `render.bp`, `streaming.bp` or `render.mjs` outside the registry
      — the render and the client read the same names
- [ ] `render.mjs`'s fill function, registered under `globals.fill`, is idempotent: calling it twice
      for one id leaves the DOM unchanged; a fill for an absent hole is dropped
- [ ] `readPayload(globals.payload)` returns the object the render assigned
- [ ] no `__onze*` or hand-written `__jh*` global is referenced by any HTML this front writes

### Step 8 — `RenderHooks`, `app`, `render` and `renderStream`

```bp
pub type PageInput(build: string, pathname: string, pattern: string, params: string, query: string,
                   table: string, actions: Array<#(string, string)>, chain: Array<Segment>,
                   page: fn() -> @Component<Element>)

#[@future] pub fn render(a: App, input: PageInput) -> @Future<string>
#[@future] pub fn renderStream(a: App, input: PageInput, write: fn(string) -> i32) -> @Future<string>
```

`write` is the chunk writer onze hands through from rakun; `renderStream` calls it for the shell and
then for each fill as its boundary completes. Both answer the render's outcome — `""`, or the
navigation-signal reason (`contracts.md § 5b`) a boundary re-raised, which onze translates into
rakun's status.

**Acceptance:**
- [ ] a page with one boundary produces at least three `write` calls, the first ending inside
      `<body>`
- [ ] every id in the payload's `h` appears in exactly one `data-jh-f` template in a later chunk
- [ ] hole ids are `h1`, `h2`, … in shell order, and a page whose boundaries resolve in reverse
      order still numbers them in shell order
- [ ] a boundary that resolves before the shell is written produces no hole and no fill
- [ ] two boundaries that resolve out of order produce fills in resolution order, each carrying its
      own markup
- [ ] sibling server components are handed to front 02 as **unstarted thunks** in one await; two
      50 ms loaders finish in well under 100 ms on `--target erlang`, and the same test over
      already-started `@Future` values is kept as the regression case
- [ ] `defaultHooks()` renders a working document with no `<script src>`; replacing one field leaves
      the other at its default
- [ ] a page raising jhonstart's `notFound()` (front 31) answers the outcome `jhonstart:not-found`
      and renders the nearest `not-found` boundary

### Step 9 — The `jhonstart-emilia` bridge

A member of this workspace, `repository/jhonstart/modules/jhonstart-emilia/`, versioned with the
contract it implements (decision 113, item 7). It is the only package that knows jhonstart and
emilia; emilia does not change and imports nobody.

```
modules/jhonstart-emilia/
├── botopink.json      "dependencies": { "jhonstart": { "workspace": true }, "emilia": … }
├── src/root.bp        pub fn plugin() -> RenderPlugin — head and chunk return emilia's flush()
└── test/bridge_test.bp
```

```bp
// jhonstart-emilia/src/root.bp
import {RenderPlugin} from "jhonstart";
import {flush} from "emilia";

pub fn plugin() -> RenderPlugin { … }   // head(): flush() · chunk(id): flush() · close(): Error if flush() is not ""
```

onze registers it at boot — `app(plugins: [emiliaPlugin()])` — and that is onze's whole part in the
CSS moment.

**Acceptance:**
- [ ] `botopink.json` declares `jhonstart` as `{ "workspace": true }` (decision 75) and `emilia` as
      a dependency; the member's `targets` match jhonstart core's
- [ ] a page styled with `emilia([...])` and rendered with `app(plugins: [plugin()])` has one
      `<style>` in `<head>` — `head` was called once
- [ ] a streamed boundary whose subtree registers a new class carries its CSS as
      `<template data-jh-f="h1"><style>…</style>…</template><script>__bp1("h1")</script>`, style
      before markup
- [ ] after the last chunk `close` is `Ok`; a class registered after the last `chunk` makes it
      `Error` and the render fails
- [ ] the contract-4 class literal (`contracts.md § 4`'s shared fixture) is asserted here, on the
      jhonstart side — jhonstart core cannot import emilia, so the bridge's test is where the
      rendered document and emilia's class meet
- [ ] no file of `repository/emilia/` changes for this step

### Step 10 — Module wiring

front 94 owns `src/root.bp` and `botopink.json`'s `files` list; this front hands it the lines rather
than editing either file, and front 94 appends in front-number order: `pub mod suspense;`,
`pub mod streaming;`, `pub mod render;`, `pub mod plugin;`, `pub mod globals;`, and the file names
(with `render.mjs` as a shipped sidecar). The `jhonstart-emilia` member is added to the workspace
manifest's `workspaces` by this front, in its own commit.

**Acceptance:**
- [ ] the `pub mod` lines and `files` entries are handed to front 94; this front edits neither
      `src/root.bp` nor `botopink.json` of the core member
- [ ] `streaming.bp` imports `Boundary` from `"suspense"` by explicit module name, not the bare
      shorthand — the bare form lowers to `require("../suspense")` and breaks when jhonstart is
      consumed as a dependency (`html.bp:87-92`)
- [ ] `repository/jhonstart/AGENTS.md` names `render.bp`, the payload version, the plugin order and
      the globals registry, in the same commit

## Examples

- [`examples/streamed-blog-page-example.bp`](./examples/streamed-blog-page-example.bp) — a blog index
  whose header flushes immediately and whose post list arrives in a second chunk.
- [`examples/loading-convention-example.bp`](./examples/loading-convention-example.bp) — the
  `loading.bp` a developer writes, and the boundary `compose` builds around it.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| `Children` coerces from an array, an `Element` or a string (`infer.zig:4228-4239`) but not from a deferred value, so a boundary's child cannot be a child | `Boundary` is a record holding a `fn() -> @Component<Element>` beside the fallback, instead of `Suspense(fallback, child)` taking the child as `Children` | a record | let `Children` accept a thunk, resolved by the renderer |
| `await` is not safe as a lambda's last statement — a lambda's last statement must be an implicit-return expression, and nothing in the tree awaits in one | `resolve(b)` awaits one boundary; `renderStream` spawns, it does not map | one await per call, at statement level | an awaiting lambda, so `boundaries.map({ b -> await resolve(b) })` types |
| Declared parameter defaults are never applied | every `Element` builder call in both examples spells `attrs: []` | write every argument | apply the declared default when an argument is omitted |
| emilia's `flush()` is `#[@future]` (`-> @Future<string>`), while `RenderPlugin.head` / `chunk` return `string` — a behavior method cannot `await` | the bridge's `head` and `chunk` | on erlang `@Future` is eager, so the value is already computed; the bridge reads it through the eager lowering | a `#[@future]` behavior method, or `RenderPlugin` methods answering `@Future<string>` — not decided by 113 |

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
is the assertion that catches the eager-`@Future` mistake.

## Definition of done

- [ ] `render.bp`, `plugin.bp`, `globals.bp`, `suspense.bp`, `streaming.bp` and `render.mjs` in the
      build tree, their `root.bp` and `files` lines handed to front 94
- [ ] no path in the render calls `renderToString`; the grep is part of the gate
- [ ] the payload key table of `contracts.md § 2` is this front's, and the fronts that cite it
      (24, 26, 27, 29, 60, 61, 63, 68) cite `contracts.md`, not a re-derivation
- [ ] every marker the render writes is `data-jh-*` and every global comes from `globals.bp`
- [ ] `RenderHooks` carries `headExtra` and `bodyExtra` only; the style moments are `RenderPlugin`
- [ ] the `jhonstart-emilia` member exists, its tests are green, and `repository/emilia/` is
      unchanged
- [ ] nothing under `repository/jhonstart/` imports `rakun`, `onze` or (outside the bridge) `emilia`
- [ ] all four language gaps appear in a `specs/1.0.10-beta/` spec
- [ ] the front's tests are green on both rows

## Notes

- **The payload's `s` key has no producer under `RenderPlugin`.** Contract 2's `s` lists the emilia
  class names already in the document's `<style>`, so the client never re-flushes them; front 69's
  sink recorded them (`emittedClasses`). Decision 113's three-method contract carries CSS text, not
  a class list, so which package hands `s` to `writePayload` is not decided — this front writes the
  key from `Payload.styles` and does not invent a fourth plugin method.
- **Where the browser-side matcher comes from is not decided here.** Front 26 receives `match` from
  onze; front 22's matcher lives in rakun, whose core targets erlang only under decision 113. This
  front consumes the route data onze passes and does not assert how onze obtains it on commonJS.

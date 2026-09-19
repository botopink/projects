# Front 30 — Jhonstart Streaming

**Track:** C jhonstart
**Priority:** high — without it, one slow loader holds the whole page; the reader sees nothing until the slowest query returns
**Target:** erlang (server)
**Boundary:** the server produces the chunks; the browser consumes them. The chunk markup contract is defined here and read by front 29's `hydrate()`. This front carries no browser cell.
**Wave:** 3
**Depends on:** 28 · 23 (flush transport, read-only)
**Owns:** `repository/jhonstart/src/streaming.bp`, `repository/jhonstart/src/suspense.bp`, `repository/jhonstart/test/streaming_test.bp`
**Does not touch:** `src/element.bp`, `src/hooks.bp`, `src/html.bp` (frozen), `src/router.bp` (26), `src/link.bp` (27), `src/server.bp` (28), `src/client.bp` (29)
**Reference:** `NEXTJS-DOCS.md § 13. Streaming` · `§ 5. Layouts e Páginas` · https://nextjs.org/docs/app/guides/streaming · https://nextjs.org/docs/app/api-reference/file-conventions/loading
**Replaces:** `1.0.7-beta/06-jhonstart-streaming`

---

## Problem

Front 28 gives a page one `await` per loader and one tree at the end. That is all-or-nothing: a blog
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

- `element.bp:55-67` — `renderToString`, synchronous, one pass, no seam.
- `src/root.bp:15-17` — no `suspense`, no `streaming`.
- `#[@future]` + `await` work and are exercised (`repository/emilia/src/emilia.bp:62-65`,
  `:475-480`).
- Nothing in the repository emits more than one string per render, and nothing reads a partial one.
- `libs/std/src/http.bp:16-18` — "Erlang is eager: `@Future<T>` resolves to `T` … so the caller's
  `await fetch(url)` is identity on that backend." There is no concurrent scheduler behind `@Future`
  on the BEAM, which is the single most important fact about this front.
- The 1.0.7 draft's `Suspense` rendered the fallback into an attribute
  (`data-jhonstart-fallback: renderToString(props.fallback)`) *and* the children into the same
  element. That is not streaming — it sends both halves in the first flush, which costs more bytes
  than sending neither.

## Mechanism

Upstream splits a streamed page into a shell that flushes immediately and one `<Suspense>` boundary
per slow subtree; each boundary's fallback goes out with the shell and is replaced when its content
arrives (`NEXTJS-DOCS.md § 13`). jhonstart keeps that model and makes the two halves explicit,
because an `Element` cannot carry a deferred child: `Children` coerces from arrays, elements and
strings (`infer.zig:4228-4239`), never from a thunk.

### What makes it actually stream

`@Future` is eager on the BEAM (`libs/std/src/http.bp:16-18`). A list of futures is therefore a list
of results that have *already* been computed, in order, before anything was flushed — and a
"progressive flush" driven by awaiting such a list flushes everything at once, after the slowest
boundary, having paid the sum of all of them. It would pass a test that checks the chunks and fail
the only thing a reader can see.

So a boundary in this design holds an **unstarted task** — `fn() -> @Future<Element>`, a thunk —
and progressive flush is driven by the completion of **spawned work**, one BEAM process per
boundary, gathered by index. Front 02 owns spawning and gathering, and its surface takes exactly
that shape: `Array<fn() -> @Future<T>>`. Front 23 spawns the boundaries, flushes the shell
immediately, and flushes each chunk as its process reports.

The division of labour follows from it:

| Who | Does what |
|---|---|
| this front | defines `Boundary` (a thunk, not a future), the placeholder markup, and `Chunk` |
| front 02 | spawns the thunks and reports completions by index |
| front 23 | flushes the shell, then each completion, and closes the response |
| front 29 | adopts each chunk in the browser |

This front never spawns and never awaits a list. `resolve(b)` awaits **one** boundary, which is what
front 23 calls inside each spawned process.

### The erlang half — this front

A boundary is a record, not an element:

```bp
pub type Boundary(
    id: string,
    fallback: Element,
    child: fn() -> @Future<Element>,
)
```

`Suspense(b)` renders only the **placeholder**: the fallback, wrapped in a node carrying the
boundary's id. That goes out with the shell.

```
<div data-jh-suspense="blog.posts"><div class="skeleton">Loading posts…</div></div>
```

`resolve(b)` is `#[@future]` and awaits the child exactly once, at statement level, returning a
`Chunk`. Nothing in this file awaits inside a closure — the lambda rule (`§2.38`) makes that a poor
bet and no file in the tree does it.

```bp
pub type Chunk(id: string, html: string)
```

`chunkHtml(c)` wraps a resolved chunk in the form the browser looks for:

```
<template data-jh-chunk="blog.posts"><ul class="posts">…</ul></template>
```

**Ordering and flushing are front 23's.** This front produces the shell markup and one `Chunk` per
boundary; front 23 decides when each goes on the wire, and whether a chunk that resolves out of
order is flushed early or held. Saying so here is the point — the 1.0.7 draft left "the actual
streaming transport is rakun's job" as a footnote after designing an API that could not be flushed
at all.

### The js half — front 29 and front 68

The browser half is three lines of contract and no code in this repository:

1. On seeing `<template data-jh-chunk="ID">`, replace the contents of `[data-jh-suspense="ID"]`
   with the template's contents and remove the template.
2. A chunk for an id that is not present is dropped, not an error — the boundary may have been
   navigated away from.
3. Adoption happens before hydration of anything inside the chunk, so a client component inside a
   streamed subtree starts once, not twice.

Front 29's `hydrate()` implements it; front 68 ships it. `streaming.bp` carries **no**
`#[@External.Node]` cell, which is what keeps this an erlang front.

### Boundary ids

An id must be stable across the shell render and the chunk render, and unique within a page. It is
derived from the route segments plus a name the developer gives the boundary:

```bp
pub fn boundaryId(segments: Array<string>, name: string) -> string {
    return segments.append([name]).join(".");
}
```

Segments come from front 26's snapshot, so two boundaries named `posts` under `/blog` and `/docs`
do not collide, and the same boundary keeps its id across a client navigation that reuses the
layout.

### `loading.bp`

A segment's `loading.bp` exports `pub fn Loading() -> Element`. Front 22 discovers the file; front
23 builds `Boundary(id: boundaryId(segments, "page"), fallback: Loading(), child: { -> Page(params) })`
around the segment's page. This front defines the record they build and asserts nothing about file
discovery, which is front 22's.

The developer writing `loading.bp` writes one function and never names a boundary. The developer who
wants a boundary *inside* a page writes `Suspense` by hand, with a name.

## Steps

### Step 1 — `Boundary`, `Suspense`, `boundaryId`

```bp
// src/suspense.bp
import {Element} from "element";

pub type Boundary(
    id: string,
    fallback: Element,
    child: fn() -> @Future<Element>,
)

pub fn Suspense(b: Boundary) -> Element {
    return Element(
        tag: "div",
        value: "",
        children: [b.fallback],
        attrs: [#("data-jh-suspense", b.id)],
    );
}

pub fn boundaryId(segments: Array<string>, name: string) -> string {
    return segments.append([name]).join(".");
}
```

**Acceptance:**
- [ ] `renderToString(Suspense(b))` emits the fallback inside `<div data-jh-suspense="ID">` and
      nothing else — the child is not rendered and does not appear in the shell
- [ ] `boundaryId(["blog"], "posts") == "blog.posts"`
- [ ] `boundaryId([], "page") == "page"`
- [ ] `Suspense` reaches no host cell

### Step 2 — `Chunk`, `resolve`, `chunkHtml`

```bp
// src/streaming.bp
import {Element} from "element";
import {Boundary} from "suspense";

pub type Chunk(id: string, html: string)

#[@future]
pub fn resolve(b: Boundary) -> @Future<Chunk> {
    val tree = await b.child();
    return Chunk(id: b.id, html: renderToString(tree));
}

pub fn chunkHtml(c: Chunk) -> string {
    return "<template data-jh-chunk=\"" + c.id + "\">" + c.html + "</template>";
}
```

**Acceptance:**
- [ ] `resolve` awaits exactly once, at statement level, never inside a closure
- [ ] `resolve` of a boundary whose child returns immediately produces the rendered child
- [ ] `chunkHtml(Chunk(id: "blog.posts", html: "<ul></ul>"))` is exactly
      `<template data-jh-chunk="blog.posts"><ul></ul></template>`
- [ ] a chunk id containing a quote is refused at construction, or escaped — the test says which

### Step 3 — The shell

The shell is the page's own tree with every `Suspense` placeholder in it, rendered once. This front
adds no shell renderer: it is `renderToString` on the page's `Element`, which already works.

```bp
pub fn shellHtml(page: Element) -> string {
    return renderToString(page);
}
```

`shellHtml` exists only so that the flush contract has a named first step and front 23 does not have
to reach into `element.bp` for it.

**Acceptance:**
- [ ] `shellHtml` of a page containing two boundaries emits both placeholders and neither child
- [ ] `shellHtml` is `renderToString` and nothing more — no wrapper, no doctype, no head; those are
      front 23's and front 32's

### Step 4 — The flush contract, written down

`repository/jhonstart/docs.md` gains the four-row table front 23 implements against:

| Step | Produced by | Emitted |
|---|---|---|
| 0 | front 23, via front 02 | one spawned process per `Boundary`, over its **thunk** — never over an already-resolved future |
| 1 | `shellHtml(page)` | the full document shell, every boundary showing its fallback, flushed before any boundary completes |
| 2..n | `chunkHtml(await resolve(b))` inside each spawned process | `<template data-jh-chunk="ID">…</template>` |
| order | front 23 | completion order, not declaration order |
| end | front 23 | close the response when every boundary has flushed |

**Acceptance:**
- [ ] the table is in `repository/jhonstart/docs.md` and front 23's README cites it
- [ ] the browser-side three rules from *The js half* are in the same place and front 29 cites them
- [ ] the README states that ordering and flushing are front 23's, in *Mechanism*
- [ ] the table's row 0 names front 02 and the word "thunk", and the doc cites
      `libs/std/src/http.bp:16-18` for why

### Step 5 — Module wiring

`src/root.bp` gains `pub mod suspense;` and `pub mod streaming;`; `botopink.json` `files` gains both.

**Acceptance:**
- [ ] `src/root.bp` declares both modules
- [ ] `botopink.json` lists `suspense.bp` and `streaming.bp`
- [ ] `streaming.bp` imports `Boundary` from `"suspense"` by explicit module name, not the bare
      shorthand — the bare form lowers to `require("../suspense")` and breaks when jhonstart is
      consumed as a dependency (`html.bp:87-92`)
- [ ] `repository/jhonstart/AGENTS.md` updated in the same commit

## Examples

- [`examples/streamed-blog-page-example.bp`](./examples/streamed-blog-page-example.bp) — a blog index
  whose header flushes immediately and whose post list arrives in a second chunk.
- [`examples/loading-convention-example.bp`](./examples/loading-convention-example.bp) — the
  `loading.bp` a developer writes, and the boundary front 22 and front 23 build around it.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| `Children` coerces from an array, an `Element` or a string (`infer.zig:4228-4239`) but not from a deferred value, so a boundary's child cannot be a child | `Boundary` is a record holding a `fn() -> @Future<Element>` beside the fallback, instead of `Suspense(fallback, child)` taking the child as `Children` | a record | let `Children` accept a thunk, resolved by the renderer |
| `await` is not safe as a lambda's last statement — a lambda's last statement must be an implicit-return expression, and nothing in the tree awaits in one | `resolve(b)` awaits one boundary; front 23 loops, this front does not | one await per call, at statement level | an awaiting lambda, so `boundaries.map({ b -> await resolve(b) })` types |
| Declared parameter defaults are never applied | every `Element` builder call in both examples spells `attrs: []` | write every argument | apply the declared default when an argument is omitted |

## Test plan

`repository/jhonstart/test/streaming_test.bp`, run by `botopink test --target erlang` from
`repository/jhonstart`, and in the ecosystem gate by
`zig build test-libs -- --target erlang --lib jhonstart`.

Assertions:

1. `Suspense` renders the fallback and not the child — the assertion that proves the shell is cheap.
2. `boundaryId` for a nested segment list, a single segment, and none.
3. `resolve` over a boundary whose child is an immediately-returning `#[@future]` fn; `await` works
   directly in a `test` block, so no host render loop is needed.
4. `chunkHtml` exact string.
5. `shellHtml` of a page with two boundaries: both placeholders present, neither child present.
6. Constructing a `Boundary` runs nothing — a thunk that appends to a module-level marker proves the
   child has not been started, which is the assertion that catches the eager-`@Future` mistake.

There is no js row for this front and that is a real coverage limit, stated rather than hidden: the
adoption rules in *The js half* are asserted by front 29's `test/client_test.bp`, which renders a
shell produced here and applies a chunk produced here. If front 29's tests do not cover chunk
adoption, this front's contract is untested on the side that consumes it, and the milestone should
treat that as a red.

## Definition of done

- [ ] `suspense.bp` and `streaming.bp` in the build tree, `root.bp` and `botopink.json` updated
- [ ] `Suspense` emits the placeholder only; a test proves the child is absent from the shell
- [ ] the flush contract table and the three browser rules are in `repository/jhonstart/docs.md`
- [ ] front 23 cites the flush table; front 29 cites the browser rules
- [ ] no `#[@External.Node]` cell in either file
- [ ] `Boundary.child` is a thunk, and a test asserts that constructing a `Boundary` runs nothing
- [ ] the eager-`@Future` fact and the front-02 spawn requirement are in the flush contract, and
      front 23's README cites them
- [ ] all three language gaps appear in a `specs/1.0.10-beta/` spec
- [ ] the front's tests are green on its assigned target

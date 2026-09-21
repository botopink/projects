# Front 30 — Jhonstart Streaming

**Track:** C jhonstart
**Priority:** high — without it, one slow loader holds the whole page; the reader sees nothing until the slowest query returns
**Target:** erlang (server)
**Boundary:** the server produces the fills; the browser consumes them. The hole and fill markers are pinned in `contracts.md § 2` and owned by front 23; this front produces markup that matches them and carries no browser cell.
**Wave:** 5
**Depends on:** 28 · 02 (spawn/gather over unstarted tasks) · 23 (hole markers + flush transport, read-only) · 94 (element builders used by the examples)
**Owns:** `repository/jhonstart/src/streaming.bp`, `repository/jhonstart/src/suspense.bp`, `repository/jhonstart/test/streaming_test.bp`
**Does not touch:** `src/element.bp`, `src/hooks.bp`, `src/html.bp` (frozen), `src/router.bp` (26), `src/link.bp` (27), `src/server.bp` (28), `src/client.bp` (29), `src/root.bp` and `botopink.json` (front 94)
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

`Suspense(b)` renders only the **hole**: the fallback, wrapped in the marker `contracts.md § 2`
pins. That goes out with the shell.

```
<div data-onze-h="h1"><div class="skeleton">Loading posts…</div></div>
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
<template data-onze-f="h1"><ul class="posts">…</ul></template><script>__onzeFill("h1")</script>
```

The list of holes still open when the shell flushes is the payload's `h` key, built by front 23 from
the boundaries this front handed it.

**Ordering and flushing are front 23's.** This front produces the shell markup and one `Chunk` per
boundary; front 23 decides when each goes on the wire, and whether a chunk that resolves out of
order is flushed early or held. Saying so here is the point — the 1.0.7 draft left "the actual
streaming transport is rakun's job" as a footnote after designing an API that could not be flushed
at all.

### The js half — front 29 and front 68

The browser half is three lines of contract and no code in this repository:

1. `__onzeFill("h1")` replaces the contents of `[data-onze-h="h1"]` with the contents of
   `[data-onze-f="h1"]`, then removes the template. The call is in the flushed markup; the browser
   does not poll and does not scan.
2. A fill for a hole id that is not present is dropped, not an error — the boundary may have been
   navigated away from. The id also leaves the payload's `h` list when it is filled.
3. Adoption happens before hydration of anything inside the chunk, so a client component inside a
   streamed subtree starts once, not twice.

Front 29's `hydrate()` implements it; front 68 ships it. `streaming.bp` carries **no**
`#[@External.Node]` cell, which is what keeps this an erlang front.

### Hole ids

`contracts.md § 2` spells a hole id `h1` — an ordinal, not a path. Front 23 assigns them in shell
render order, exactly as it assigns `i0`, `i1` to islands, and the ordinal is what ties the hole, the
fill and the payload's `h` entry together. This front provides only the spelling:

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

A segment's `loading.bp` exports `#[@context] pub fn Loading() -> Element`. Front 22 discovers the file (kind `S`
in the route table, `contracts.md § 1`); front 23 builds
`Boundary(id: holeId(n), fallback: Loading(), child: { -> Page(params) })` around the segment's page,
with `n` the next ordinal. This front defines the record they build and asserts nothing about file
discovery, which is front 22's.

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
    child: fn() -> @Future<Element>,
)

#[@context]
pub fn Suspense(b: Boundary) -> Element {
    return Element(
        tag: "div",
        value: "",
        children: [b.fallback],
        attrs: [#("data-onze-h", b.id)],
    );
}

pub fn holeId(index: i32) -> string {
    return "h" + index.toString();
}
```

**Acceptance:**
- [ ] `renderToString(Suspense(b))` emits the fallback inside `<div data-onze-h="h1">` and
      nothing else — the child is not rendered and does not appear in the shell
- [ ] `holeId(1) == "h1"`, `holeId(0) == "h0"` — the spelling `contracts.md § 2` pins
- [ ] a `Boundary` carries the ordinal front 23 assigned it; this front assigns none
- [ ] `Suspense` reaches no host cell

### Step 2 — `Chunk`, `resolve`, `fillHtml`

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

pub fn fillHtml(c: Chunk) -> string {
    return "<template data-onze-f=\"" + c.id + "\">" + c.html
        + "</template><script>__onzeFill(\"" + c.id + "\")</script>";
}
```

**Acceptance:**
- [ ] `resolve` awaits exactly once, at statement level, never inside a closure
- [ ] `resolve` of a boundary whose child returns immediately produces the rendered child
- [ ] `fillHtml(Chunk(id: "h1", html: "<ul></ul>"))` is exactly
      `<template data-onze-f="h1"><ul></ul></template><script>__onzeFill("h1")</script>` — the
      literal `contracts.md § 2` pins, asserted here and on the browser side
- [ ] a chunk id is always `h<n>` from `holeId`, so the quote and `</script` cases cannot arise —
      a test asserts `holeId` produces nothing outside `[h0-9]`

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
| 2..n | `fillHtml(await resolve(b))` inside each spawned process | `<template data-onze-f="ID">…</template>` |
| order | front 23 | completion order, not declaration order |
| end | front 23 | close the response when every boundary has flushed |

**Acceptance:**
- [ ] the table is in `repository/jhonstart/docs.md` and front 23's README cites it
- [ ] the browser-side three rules from *The js half* are in the same place and front 29 cites them
- [ ] the README states that ordering and flushing are front 23's, in *Mechanism*
- [ ] the table's row 0 names front 02 and the word "thunk", and the doc cites
      `libs/std/src/http.bp:16-18` for why

### Step 5 — Module wiring

front 94 owns `src/root.bp` and `botopink.json`'s `files` list; this front hands it the line(s) below rather than editing either file, and front 94 appends in front-number order: `pub mod suspense;`, `pub mod streaming;`, and both file names.

**Acceptance:**
- [ ] both `pub mod` lines and both `files` entries are handed to front 94; this front edits
      neither `src/root.bp` nor `botopink.json`
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
2. `holeId` for ordinals 0, 1 and 12 — the exact spelling in `contracts.md § 2`.
3. `resolve` over a boundary whose child is an immediately-returning `#[@future]` fn; `await` works
   directly in a `test` block, so no host render loop is needed.
4. `fillHtml` exact string.
5. `shellHtml` of a page with two boundaries: both placeholders present, neither child present.
6. Constructing a `Boundary` runs nothing — a thunk that appends to a module-level marker proves the
   child has not been started, which is the assertion that catches the eager-`@Future` mistake.

There is no js row for this front and that is a real coverage limit, stated rather than hidden: the
adoption rules in *The js half* are asserted by front 29's `test/client_test.bp`, which renders a
shell produced here and applies a chunk produced here. If front 29's tests do not cover chunk
adoption, this front's contract is untested on the side that consumes it, and the milestone should
treat that as a red.

## Definition of done

- [ ] `suspense.bp` and `streaming.bp` in the build tree, their `root.bp` and `files` lines handed
      to front 94
- [ ] `Suspense` emits the placeholder only; a test proves the child is absent from the shell
- [ ] the flush contract table and the three browser rules are in `repository/jhonstart/docs.md`
- [ ] front 23 cites the flush table; front 29 cites the browser rules
- [ ] no `#[@External.Node]` cell in either file
- [ ] `Boundary.child` is a thunk, and a test asserts that constructing a `Boundary` runs nothing
- [ ] the eager-`@Future` fact and the front-02 spawn requirement are in the flush contract, and
      front 23's README cites them
- [ ] all three language gaps appear in a `specs/1.0.10-beta/` spec
- [ ] the front's tests are green on its assigned target

## Carried from 1.0.7-beta F06 jhonstart-streaming

Items of the 1.0.7 draft not restated above, quoted so nothing is lost; where the milestone decided differently the 1.0.9 decision stands and the old text is kept for the record.

### `SuspenseProps` / `Suspense(props)` — children as `Children`, fallback in an attribute

`1.0.7-beta/06-jhonstart-streaming/README.md § Mechanism`, `§ Steps › Step 1 — Suspense component`. Superseded by `Boundary` (a record holding a thunk) and the `data-onze-h` hole marker in *Mechanism › The erlang half* and *Step 1* above; the reason is recorded in *Current state*.

> Introduce `Suspense` boundary (analogous to React's `<Suspense>`):
> - `Suspense` wraps a component and provides a fallback UI
> - During SSR, if the wrapped component is still loading, the fallback is rendered
> - The actual content is streamed later (or hydrated on the client)

```bp
pub fn BlogPage() -> Element {
    return div([
        h1([text("Blog", attrs: [])], attrs: []),
        Suspense(
            fallback: div([text("Loading posts...", attrs: [])], attrs: []),
            children: [PostList()],
        ),
    ], attrs: []);
}
```

```bp
// src/suspense.bp
import {Element} from "element";

pub type SuspenseProps(
    fallback: Element,
    children: Children,
)

pub fn Suspense(props: SuspenseProps) -> Element {
    // During SSR, render the fallback immediately
    // The actual content is streamed/hydrated later
    return Element(
        tag: "div",
        value: "",
        children: props.children,
        attrs: [
            #("data-jhonstart-suspense", "true"),
            #("data-jhonstart-fallback", renderToString(props.fallback)),
        ],
    );
}
```

Old acceptance (replaced by Step 1's acceptance above):

| Old item | Status |
|---|---|
| `Suspense` component compiles | replaced — `Suspense(b: Boundary)` |
| Renders children with fallback metadata | reversed — the child is **not** rendered in the shell |
| `renderToString(Suspense(...))` produces HTML with data attributes | replaced — `data-onze-h="h<n>"` only |

### `Suspense` with `children: [await PostList()]` (Exemplos em bp)

`1.0.7-beta/06-jhonstart-streaming/README.md § Exemplos em bp › Suspense com fallback`. Superseded: awaiting the child before building the boundary is the eager-`@Future` mistake named in *Mechanism › What makes it actually stream*.

```bp
#[@future]
pub fn BlogPage() -> @Future<Element> {
    return div([
        h1([text("Blog")]),
        Suspense(SuspenseProps(
            fallback: div([text("Carregando...")]),
            children: [await PostList()],
        )),
    ], attrs: []);
}
```

### `loading.bp` styled with emilia

`1.0.7-beta/06-jhonstart-streaming/README.md § Exemplos em bp › loading.bp`. The convention is restated in *Mechanism › `loading.bp`*; the emilia-token styling of the fallback is not shown in either example above.

```bp
// app/blog/loading.bp
pub fn Loading() -> Element {
    return div([text("Carregando...")], attrs: [#("class", emilia([.Bg.Gray100]))]);
}
```

### Step 3 — Streaming render deferred as a follow-up to rakun F09

`1.0.7-beta/06-jhonstart-streaming/README.md § Steps › Step 3 — Streaming render (future)` and `§ Notes`. Superseded: *Mechanism › The erlang half* assigns ordering and flushing to front 23 and Step 4 writes the flush contract down, instead of deferring the transport.

> Full streaming SSR (sending HTML chunks as they render) requires async I/O and is a recorded follow-up. This front provides the `Suspense` boundary mechanism; the actual streaming transport is rakun's job (F09).
>
> Acceptance: streaming transport documented as follow-up.

> Full streaming (sending HTML chunks over the wire) is rakun's job (F09). This front provides the component-level boundary.

### Note — fallback and children rendered together, client swaps

`1.0.7-beta/06-jhonstart-streaming/README.md § Notes`. Reversed by *Current state* (last bullet) and Step 1's acceptance: the shell carries the fallback only.

> `Suspense` during SSR renders the fallback + children together; the client runtime can swap them if needed.

### Step 4 — old test, and the commonJS + erlang test target

`1.0.7-beta/06-jhonstart-streaming/README.md § Steps › Step 4 — Tests`. The assertion `html.contains("Content")` is reversed above (test plan item 1). The target list `commonJS + erlang` is narrowed to erlang (*Target*, *Test plan*).

```bp
test "Suspense renders children with fallback metadata" {
    val el = Suspense(SuspenseProps(
        fallback: div([text("Loading...", attrs: [])], attrs: []),
        children: [div([text("Content", attrs: [])], attrs: [])],
    ));
    val html = renderToString(el);
    assert html.contains("data-jhonstart-suspense=\"true\"");
    assert html.contains("Content");
}
```

| Old acceptance | Status |
|---|---|
| Tests pass on commonJS + erlang | narrowed — erlang only; no js row for this front |

### Gate — branch name

`1.0.7-beta/06-jhonstart-streaming/README.md § Gate`. Not restated above.

| Old gate item | Status |
|---|---|
| Commit on `fix/jhonstart-streaming` | absent — no branch convention in the new front |
| `suspense.bp` in `botopink.json` and `root.bp` | covered — handed to front 94 (Step 5) |
| `botopink test` green · AGENTS.md updated | covered — *Definition of done*, Step 5 |

### Reference rows from 1.0.7 overview/fronts

| Source | Row | Status |
|---|---|---|
| `1.0.7-beta/overview.md` front table | `06-jhonstart-streaming` · **high** · jhonstart · jhonstart-core · "Streaming SSR: Suspense boundary, loading states, progressive render" | covered — header block above |
| `1.0.7-beta/overview.md` Next.js mapping | `loading.tsx` → `loading.bp` → jhonstart (streaming) | covered — *Mechanism › `loading.bp`* |
| `1.0.7-beta/overview.md` app tree | `app/loading.bp` — "Global loading UI" (root-segment `loading.bp`) | absent — only segment-level `loading.bp` is described above; root wrapping is front 22/23's |
| `1.0.7-beta/overview.md` app tree | `app/blog/loading.bp` — "Blog loading"; `app/blog/[slug]/loading.bp` (nested segment) | covered — per-segment `Boundary` built by front 23 |
| `1.0.7-beta/fronts.md` ownership | owns `repository/jhonstart/src/streaming.bp`, `repository/jhonstart/src/suspense.bp`; tests `repository/jhonstart/test/streaming_test.bp` | covered — *Owns* |
| `1.0.7-beta/fronts.md` conflict matrix | F06 row: `yes` (parallel-safe) against every other front | covered in spirit — *Does not touch* |
| `1.0.7-beta/fronts.md` phases | Phase 2 (Core features — 7 in parallel): F05 ∥ F06 ∥ F07 ∥ F10 ∥ F11 ∥ F12 ∥ F15 | different decision — *Wave 3*, depends on 28 · 02 · 23 · 94 |
| `1.0.7-beta/06-…/README.md` header | Depends on: F04 (jhonstart-server-components) | covered — depends on 28 |

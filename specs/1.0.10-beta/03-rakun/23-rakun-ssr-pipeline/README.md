# Front 23 — Rakun SSR Pipeline

**Track:** B rakun
**Priority:** critical — this is the front where "Erlang is the server" stops being a slogan: a page
request is matched, scoped and answered on BEAM, and every byte the browser later works from leaves
through the chunk writer this front owns
**Target:** erlang (server)
**Wave:** 5
**Depends on:** 04 (BEAM runtime, the transport that writes chunks), 22 (route table and layout
chain), 06 (scopes), 62 (request context — the request scope, `setPhase`, `markDynamic`), 03
(content hash for the build id). The page renderers arrive at boot from onze 49, which depends on
this front — not the reverse
**Owns:** `repository/rakun/src/ssr.bp` — `ChunkWriter`, `PageRenderer`, `page(pattern, render)`
through which onze hands it one renderer per page pattern, and the page dispatch —
`repository/rakun/src/sidecars/rakun_ssr.erl` (the chunk writer), `repository/rakun/test/ssr_test.bp`
**Does not touch:** `repository/rakun/src/http.bp`, `src/decorators.bp`, `src/bootstrap.bp`
(frozen), the files owned by 22 · 24 · 25, and every file outside `repository/rakun/` — rakun
builds no HTML and imports nothing from `jhonstart`, `emilia` or `onze` (decision 113). The walker,
the escaping, the composition of the segment chain, the document, the payload (contract 2), the
island and hole ordinals, the fill protocol, `RenderHooks` and the render plugins are jhonstart
[front 30](../../04-jhonstart/30-jhonstart-streaming/README.md)'s
**Reference:** `NEXTJS-DOCS.md § 5. Layouts e Páginas`, `§ 7. Server e Client Components`,
`§ 13. Streaming`, `§ 4. Hierarquia de renderização` ·
<https://nextjs.org/docs/app/getting-started/layouts-and-pages> ·
<https://nextjs.org/docs/app/getting-started/server-and-client-components> ·
<https://nextjs.org/docs/app/api-reference/file-conventions/loading>

---

## Problem

`rakun` answers requests with `Response(status, body)` where the body is whatever string a handler
returned (`repository/rakun/src/http.bp:45-73`). A page of the `app/` router needs more than that: the
URL has to be matched against front 22's table, the request scope of front 62 has to be open with the
`Render` phase set while the page renders, the markup has to go out as an ordered list of chunks so a
slow boundary does not hold the shell, and a URL with no page has to answer 404. That is this front.

What it does **not** do is build the markup. Under decision 113 HTML is jhonstart's: the walker, the
escaping, the layout composition, the document and the payload live in jhonstart front 30. rakun and
jhonstart never import each other, so the two meet through onze, which hands this front one opaque
renderer per page pattern (decision 114). The renderer writes its chunks through the `ChunkWriter`
rakun gives it; rakun writes them to the socket and knows nothing else about them.

## Current state

- `repository/rakun/src/http.bp:45-78` — `Response` has `status` and `body` and nothing else. No
  headers, no streaming body, no cookie jar.
- `repository/rakun/src/ssr.bp` exists and carries the render as well as the dispatch: the escaping
  walker (`renderNode`, `raw`), `compose`, `Payload` / `writePayload` / `payloadEscape` / `document`,
  the `RenderHooks` record with `defaultHooks` / `setHooks`, island and hole ordinals, and
  `render` / `renderStreaming`, and the dispatch's first seam, `RenderedPage` and
  `setPageRender(fn(PageContext) -> @Future<RenderedPage>)`. `repository/rakun/src/ssr.mjs` carries
  the fill function and the payload reader. The render is jhonstart's under decision 113 and leaves
  rakun in Step 5; the seam becomes `ChunkWriter` / `PageRenderer` in Steps 1–2 (decision 114).

## Mechanism

**The page path, end to end, on BEAM:**

```
request
  -> 22  matchPath(table, pathname)            rakun-routing; the entry + params + rest; no entry -> 404
  -> 22  the renderer registered for the matched pattern
  -> 62  request scope opens, setPhase(Render)   headers, cookies, memo cache
  -> 23  render(req, out)                       the renderer onze registered: it writes through `out`
  -> 23  out.close() when the renderer's future resolves
  -> 62  previous phase restored, scope closed
```

**One seam, and it points inwards.** This front declares the types and the registration, and never
imports what fills them (decision 114):

```bp
pub type ChunkWriter(write: fn(string) -> @Future<void>, close: fn() -> @Future<void>);
pub type PageRenderer = fn(req: Request, out: ChunkWriter) -> @Future<void>;

pub fn page(pattern: string, render: PageRenderer) -> i32     // front 22's rkAppRegisterPage
#[@future]
pub fn servePage(req: Request, out: ChunkWriter) -> @Future<i32>   // the status written
```

onze registers one renderer per page pattern at boot; inside it jhonstart renders the page (front 30)
and hands each chunk to a `fn(string) -> @Future<void>` writer onze builds over `out.write`:

```bp
// onze, at boot — not rakun code
rakun.page(route, fn(req, out) {
    return site.renderStream(page(req), requestData(req), fn(chunk) { return out.write(chunk); });
});
```

rakun sees strings. `out.write` puts a chunk on the socket as it is handed over — shell first, then
one fill per resolved boundary, then the tail, in the order jhonstart produced them — and this front
writes them without reading them. When the renderer's future resolves the dispatch calls
`out.close()`; the renderer never closes the response itself.

**Status.** A page is `200` with `Content-Type: text/html; charset=utf-8`, sent with the first chunk.
A URL that matches no page is this front's 404, answered before any renderer runs. A renderer that
raises one of front 63's navigation signals before its first `out.write` is answered with that
signal's status (404, 307, 308, 303); that is how onze translates jhonstart's own not-found into
rakun's 404 — it raises front 63's `notFound()` inside the renderer (decision 113). rakun names no
jhonstart signal.

**The phase word.** The dispatch calls front 62's `setPhase(RequestPhase.Render)` before the renderer
runs and restores the previous phase when its future resolves. That is not bookkeeping: it is the
same word front 12's `rkCachePhase()` reads to decide whether a revalidation is legal, so a dispatch
that skips it makes `revalidatePath` raise from inside an action (front 24 sets `Action`, front 25
sets `Handler`). The phase table in `contracts.md § 5` is enforced, which also means
`cookies().set(...)` from a render raises. A read of the query marks the render dynamic through
`markDynamic("searchParams")`, and `isDynamic()` is what onze reads to fill the payload's `d` key.

**What the payload needs from rakun.** The payload is jhonstart's (contract 2), but three of its
values are rakun's: `t` is `rkAppTable()` (front 22), `a` lists the action ids a page references
(front 24), `d` is `isDynamic()` (front 62). onze reads them and hands them to jhonstart's render;
nothing in rakun serialises a payload.

## Steps

### Step 1 — `ChunkWriter`, `PageRenderer` and `page`

**Acceptance:**
- [ ] `ChunkWriter` and `PageRenderer` are declared exactly as above; neither names a jhonstart,
      emilia or onze type.
- [ ] `page(pattern, render)` registers the renderer through front 22's `rkAppRegisterPage`; a second
      `page` for one pattern fails at registration, naming the pattern.
- [ ] The dispatch never builds a chunk: every byte of a page body on the socket came through
      `out.write`.

### Step 2 — The dispatch

**Acceptance:**
- [ ] A URL with no matching page answers 404 without calling any renderer.
- [ ] A renderer that raises front 63's `notFound()` before its first `out.write` is answered 404;
      `redirect(loc)` is answered 307 with `Location: loc`.
- [ ] The whole call runs inside one request scope from front 62, with `setPhase(RequestPhase.Render)`
      entered before the renderer and the previous phase restored after its future resolves. A
      `cookies().set(...)` from inside the renderer raises, per the phase table in `contracts.md § 5`.
- [ ] A read of the request's query from the renderer calls `markDynamic("searchParams")`; front
      60's prerenderer with `strict` set then raises instead of marking, which is how a static export
      fails the build.
- [ ] `out.close()` is called once, by the dispatch, after the renderer's future resolves — a renderer
      that calls it itself fails the request, naming `ChunkWriter.close`.

### Step 3 — Writing the chunks

**Acceptance:**
- [ ] The chunks reach the socket in the order the renderer wrote them, byte for byte; a test over a
      renderer writing a fixed list asserts the bytes on the socket.
- [ ] The first chunk reaches the socket before the last one is written when the renderer streams —
      asserted over `rakun_ssr.erl` with a renderer that delays its second `out.write`.
- [ ] `Content-Type: text/html; charset=utf-8` and status 200 go out with the first chunk.

### Step 4 — The route data the renderer reads

**Acceptance:**
- [ ] The `Request` handed to the renderer answers `param(name)` for the matched pattern's dynamic
      segments and `query(name)` for the search params; onze builds jhonstart's `RequestData` and the
      segment chain from it and from front 22's `layoutChain`, never from a rakun type jhonstart
      would have to name.
- [ ] Nothing in `ssr.bp` builds an element: the composition of the chain into a tree is jhonstart
      front 30's `compose`.

### Step 5 — The render leaves `ssr.bp` (decision 113)

`ssr.bp` and `ssr.mjs` carry the render today (see *Current state*). It moves to jhonstart front 30,
which receives the walker's escaping rules, the composition order, the document, the payload key
table and escaping, the island and hole ordinals, the fill protocol and their acceptance boxes.

**Acceptance:**
- [ ] `renderNode`, `raw`, `compose`, `Payload`, `writePayload`, `payloadEscape`, `document`,
      `RenderHooks` / `defaultHooks` / `setHooks` and the island/hole ordinal code are gone from
      `repository/rakun/src/`, once jhonstart front 30 lands them.
- [ ] `repository/rakun/src/ssr.mjs` is deleted; the fill function and the payload reader are
      jhonstart's (`render.mjs`).
- [ ] `rtk proxy grep -rn 'from "jhonstart' repository/rakun/src` and
      `rtk proxy grep -rni 'onze' repository/rakun/src` are both empty — the grep is part of the gate.
- [ ] `modules/rakun-app/botopink.json` lists neither `jhonstart` nor `emilia`.
- [ ] A `PageRenderer` registered through `page(pattern, render)` is the only way HTML enters a
      rakun response on the page path; `RenderedPage`, `setPageRender` and `toResponse` are gone from
      `ssr.bp` (decision 114).

## Examples

- [`examples/server-render-example.bp`](./examples/server-render-example.bp) — a page dispatch with a
  renderer that writes plain text through the `ChunkWriter`: the route is matched, the phase is set,
  the chunks are written verbatim and the response closed once, and an unmatched URL answers 404. No
  HTML is built in rakun. A page rendered by jhonstart through this seam is onze front 53's example.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| `xs[0]` silently drops the index on the BEAM backend | avoided throughout: the pipeline uses `.at(i)`, `.first()` and `.slice(…)` and never an index expression | `.at(i)` then `.unwrapOr(…)` | make the beam backend lower index expressions, or reject them |

## Blocked

- `repository/rakun/src/http.bp` is frozen and `Response(status, body)` has no header list and no
  streaming body. The page path therefore writes through `ChunkWriter` over `rakun_ssr.erl` rather
  than through `Response`; when `http.bp` unfreezes, a streaming `Response` body can carry the same
  writer.

## Test plan

`repository/rakun/test/ssr_test.bp`, on `botopink test --target erlang`. The renderer is a stub that
writes fixed text chunks, so every assertion is about dispatch, scope, phase, status and the
bytes written — never about markup. The markup, the escaping and the payload round trip are tested
where they are built, in jhonstart front 30.

## Definition of done

- The dispatch is one function, `servePage`, and a page's renderer reaches it only through
  `page(pattern, render)`; the renderer's type is `PageRenderer` over `ChunkWriter` (decision 114).
- `repository/rakun/src/` builds no HTML and imports nothing from `jhonstart`, `emilia` or `onze`;
  the greps of Step 5 are part of the gate.
- `repository/rakun/AGENTS.md` names `ssr.bp`, the dispatch and the chunk writer.
- The front's tests are green on its assigned target — erlang.

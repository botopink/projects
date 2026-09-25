# Front 23 — Rakun SSR Pipeline

**Track:** B rakun
**Priority:** critical — this is the front where "Erlang is the server" stops being a slogan: a page
request is matched, scoped and answered on BEAM, and every byte the browser later works from leaves
through the chunk writer this front owns
**Target:** erlang (server)
**Wave:** 5
**Depends on:** 04 (BEAM runtime, the transport that writes chunks), 22 (route table and layout
chain), 06 (scopes), 62 (request context — the request scope, `setPhase`, `markDynamic`), 03
(content hash for the build id). The page-render function arrives at boot from onze 49, which
depends on this front — not the reverse
**Owns:** `repository/rakun/src/ssr.bp` — `RenderedPage`, `toResponse`, the page dispatch and the
one setter through which onze hands it the page-render function —
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
jhonstart never import each other, so the two meet through onze, which hands this front the function
that turns a matched request into chunks. rakun writes what that function returns and nothing else.

## Current state

- `repository/rakun/src/http.bp:45-78` — `Response` has `status` and `body` and nothing else. No
  headers, no streaming body, no cookie jar.
- `repository/rakun/src/ssr.bp` exists and carries the render as well as the dispatch: the escaping
  walker (`renderNode`, `raw`), `compose`, `Payload` / `writePayload` / `payloadEscape` / `document`,
  the `RenderHooks` record with `defaultHooks` / `setHooks`, island and hole ordinals, and
  `render` / `renderStreaming`. `repository/rakun/src/ssr.mjs` carries the fill function and the
  payload reader. All of that is jhonstart's under decision 113 and leaves rakun in Step 5.

## Mechanism

**The page path, end to end, on BEAM:**

```
request
  -> 22  matchPath(table, pathname)            the entry + params + rest; no entry -> 404
  -> 22  layoutChain(table, pattern)           the layouts, root-first, handed on as data
  -> 62  request scope opens, setPhase(Render)   headers, cookies, memo cache
  -> 23  pageRender(ctx)                        the function onze handed at boot: status, headers, chunks
  -> 62  previous phase restored, scope closed
  -> 04  the BEAM transport writes the chunks, in order
```

**One seam, and it points inwards.** This front declares the slot and never imports what fills it:

```bp
pub type RenderedPage(
    status: i32,
    headers: Array<#(string, string)>,
    chunks: string[],
)

pub fn setPageRender(render: fn(PageContext) -> @Future<RenderedPage>) -> void
#[@future]
pub fn servePage(pathname: string, query: string) -> @Future<RenderedPage>
pub fn toResponse(page: RenderedPage) -> Response
```

onze installs the function at boot; inside it jhonstart renders the page (front 30) and onze adapts
the chunks into a `RenderedPage`. rakun sees strings. The chunks arrive in the order jhonstart
produced them — shell first, then one fill per resolved boundary, then the tail — and this front
writes them in that order without reading them.

**Not found.** A URL that matches no page is this front's 404, answered before any render. A page
that raises jhonstart's own not-found signal is translated by onze into a `RenderedPage` with status
404 (decision 113); rakun names no jhonstart signal.

**The phase word.** The dispatch calls front 62's `setPhase(RequestPhase.Render)` before the render
function runs and restores the previous phase when it returns. That is not bookkeeping: it is the
same word front 12's `rkCachePhase()` reads to decide whether a revalidation is legal, so a dispatch
that skips it makes `revalidatePath` raise from inside an action (front 24 sets `Action`, front 25
sets `Handler`). The phase table in `contracts.md § 5` is enforced, which also means
`cookies().set(...)` from a render raises. `searchParams` marks the render dynamic through
`markDynamic("searchParams")`, and `isDynamic()` is what onze reads to fill the payload's `d` key —
the accessor marks it, not a flag this front keeps.

**What the payload needs from rakun.** The payload is jhonstart's (contract 2), but three of its
values are rakun's: `t` is `rkAppTable()` (front 22), `a` lists the action ids a page references
(front 24), `d` is `isDynamic()` (front 62). onze reads them and hands them to jhonstart's render;
nothing in rakun serialises a payload.

## Steps

### Step 1 — The rendered page, and why it is not a `Response`

**Acceptance:**
- [ ] `RenderedPage` carries headers and an ordered chunk list; `toResponse` joins the chunks and is
      used only on the non-streaming path.
- [ ] `Content-Type: text/html; charset=utf-8` is present on every `RenderedPage` this front writes.

### Step 2 — The dispatch

**Acceptance:**
- [ ] A URL with no matching page answers 404 without calling the render function.
- [ ] A `RenderedPage` the render function returns with status 404 is written with status 404 — the
      not-found translation is onze's, the status is honoured here.
- [ ] The whole call runs inside one request scope from front 62, with `setPhase(RequestPhase.Render)`
      entered before the render function and the previous phase restored after. A
      `cookies().set(...)` from inside the render raises, per the phase table in `contracts.md § 5`.
- [ ] Reading `route.query` calls `markDynamic("searchParams")`; front 60's prerenderer with
      `strict` set then raises instead of marking, which is how a static export fails the build.
- [ ] With no render function installed, `servePage` fails loudly naming `setPageRender`; there is
      no default page renderer in rakun.

### Step 3 — Writing the chunks

**Acceptance:**
- [ ] The chunks are written in the order the render function returned them, byte for byte; a test
      over a fixed chunk list asserts the bytes on the socket.
- [ ] The first chunk reaches the socket before the last one is produced when the render function
      streams — asserted over `rakun_ssr.erl` with a render function that delays its second chunk.

### Step 4 — The layout chain as data

**Acceptance:**
- [ ] The `PageContext` handed to the render function carries the pattern, the params, the query and
      front 22's layout chain root-first; a three-deep chain arrives as three entries in that order.
- [ ] Nothing in `ssr.bp` builds an element: the composition of that chain into a tree is jhonstart
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
- [ ] The function handed through `setPageRender` is the only way HTML enters a rakun response on
      the page path.

## Examples

- [`examples/server-render-example.bp`](./examples/server-render-example.bp) — a page dispatch with a
  stub render function: the route is matched, the phase is set, the chunks the function returns are
  written verbatim, and an unmatched URL answers 404. No HTML is built in rakun.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| `xs[0]` silently drops the index on the BEAM backend | avoided throughout: the pipeline uses `.at(i)`, `.first()` and `.slice(…)` and never an index expression | `.at(i)` then `.unwrapOr(…)` | make the beam backend lower index expressions, or reject them |

## Blocked

- `repository/rakun/src/http.bp` is frozen and `Response(status, body)` has no header list and no
  streaming body. This front therefore defines `RenderedPage` in its own file and converts at the
  boundary. When `http.bp` unfreezes, `RenderedPage` should collapse into `Response` and `toResponse`
  should disappear.

## Test plan

`repository/rakun/test/ssr_test.bp`, on `botopink test --target erlang`. The render function is a
stub that returns fixed chunks, so every assertion is about dispatch, scope, phase, status and the
bytes written — never about markup. The markup, the escaping and the payload round trip are tested
where they are built, in jhonstart front 30.

## Definition of done

- The dispatch is one function, `servePage`, and the render function reaches it only through
  `setPageRender`.
- `repository/rakun/src/` builds no HTML and imports nothing from `jhonstart`, `emilia` or `onze`;
  the greps of Step 5 are part of the gate.
- `repository/rakun/AGENTS.md` names `ssr.bp`, the dispatch and the chunk writer.
- The front's tests are green on its assigned target — erlang.

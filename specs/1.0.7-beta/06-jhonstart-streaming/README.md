# Front 06 — Jhonstart Streaming

**Referência Next.js:** [Streaming](https://nextjs.org/docs/app/guides/streaming) · [Loading UI](https://nextjs.org/docs/app/api-reference/file-conventions/loading)

**Priority:** high — streaming enables progressive rendering for better UX
**Depends on:** F04 (jhonstart-server-components)
**Owns:** `repository/jhonstart/src/streaming.bp`, `repository/jhonstart/src/suspense.bp`
**Does not touch:** `router.bp`, `link.bp`, `server.bp`, `client.bp`, `element.bp`, `hooks.bp`

---

## Problem

Server components block the entire page until all data is fetched. For pages with slow data sources, users see a blank page. Streaming allows parts of the page to render progressively as data becomes available.

## Current state

- `renderToString` is synchronous — renders the entire tree at once
- No `<Suspense>` boundary concept
- No `loading.bp` convention
- `#[@future]` functions can `await` data, but the result is blocking

## Exemplos em bp

### Suspense com fallback

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

### loading.bp

```bp
// app/blog/loading.bp
pub fn Loading() -> Element {
    return div([text("Carregando...")], attrs: [#("class", emilia([.Bg.Gray100]))]);
}
```

## Mechanism

Introduce `Suspense` boundary (analogous to React's `<Suspense>`):
- `Suspense` wraps a component and provides a fallback UI
- During SSR, if the wrapped component is still loading, the fallback is rendered
- The actual content is streamed later (or hydrated on the client)

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

## Steps

### Step 1 — Suspense component

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

**Acceptance:**
- [ ] `Suspense` component compiles
- [ ] Renders children with fallback metadata
- [ ] `renderToString(Suspense(...))` produces HTML with data attributes

### Step 2 — loading.bp convention

Document the `loading.bp` file convention:
- `loading.bp` in a route segment provides the fallback for that segment
- The file router (F14) automatically wraps `page.bp` in a `Suspense` with `loading.bp` as fallback

```bp
// app/blog/loading.bp
pub fn Loading() -> Element {
    return div([text("Loading...", attrs: [])], attrs: []);
}
```

**Acceptance:**
- [ ] Convention documented
- [ ] File router integration (F14) will wire it up

### Step 3 — Streaming render (future)

Full streaming SSR (sending HTML chunks as they render) requires async I/O and is a recorded follow-up. This front provides the `Suspense` boundary mechanism; the actual streaming transport is rakun's job (F09).

**Acceptance:**
- [ ] Streaming transport documented as follow-up

### Step 4 — Tests

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

**Acceptance:**
- [ ] Tests pass on commonJS + erlang

## Gate

- [ ] `botopink test` green
- [ ] `suspense.bp` in `botopink.json` and `root.bp`
- [ ] AGENTS.md updated
- [ ] Commit on `fix/jhonstart-streaming`

## Blast radius

- New files `suspense.bp`, `streaming.bp` — no changes to existing files
- Consumers can use `Suspense` for progressive rendering

## Notes

- Full streaming (sending HTML chunks over the wire) is rakun's job (F09). This front provides the component-level boundary.
- `Suspense` during SSR renders the fallback + children together; the client runtime can swap them if needed.

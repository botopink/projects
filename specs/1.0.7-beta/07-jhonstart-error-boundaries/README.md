# Front 07 — Jhonstart Error Boundaries

**Referência Next.js:** [Error Handling](https://nextjs.org/docs/app/getting-started/error-handling) · [error.js](https://nextjs.org/docs/app/api-reference/file-conventions/error) · [not-found.js](https://nextjs.org/docs/app/api-reference/file-conventions/not-found)

**Priority:** high — error boundaries catch rendering errors and show fallback UI
**Depends on:** F04 (jhonstart-server-components)
**Owns:** `repository/jhonstart/src/error_boundary.bp`
**Does not touch:** `router.bp`, `link.bp`, `server.bp`, `client.bp`, `suspense.bp`, `element.bp`, `hooks.bp`

---

## Problem

When a component throws during rendering, the entire page crashes. Error boundaries catch errors in their child components and show fallback UI instead of the crashed component tree.

## Current state

- No error boundary mechanism in jhonstart
- Errors during `renderToString` propagate up and crash the render
- No `error.bp` or `not-found.bp` conventions

## Exemplos em bp

### error.bp

```bp
#[client]
pub fn Error(error: string, retry: fn()) -> Element {
    return div([
        h2([text("Algo deu errado!")]),
        button([text("Tentar novamente")], attrs: [#("onClick", "retry")]),
    ], attrs: []);
}
```

### notFound()

```bp
#[@future]
pub fn BlogPost(params: Dict<string, string>) -> @Future<Element> {
    val post = await getPost(params.get("slug"));
    if (post == null) { notFound(); };
    return div([h1([text(post.title)])], attrs: []);
}
```

## Mechanism

Introduce error boundary components:
- `ErrorBoundary` wraps children and catches rendering errors
- `error.bp` convention: file router wraps each route segment in an error boundary
- `not-found.bp` convention: 404 UI when a route is not found
- `global-error.bp` convention: root-level error boundary

```bp
pub fn ErrorBoundary(props: ErrorBoundaryProps) -> Element {
    // During SSR, try to render children; if they throw, render fallback
    // On the client, the error boundary catches runtime errors
    return Element(
        tag: "div",
        value: "",
        children: props.children,
        attrs: [#("data-jhonstart-error-boundary", "true")],
    );
}
```

## Steps

### Step 1 — ErrorBoundary component

```bp
// src/error_boundary.bp
import {Element} from "element";

pub type ErrorBoundaryProps(
    fallback: fn(error: string) -> Element,
    children: Children,
)

pub fn ErrorBoundary(props: ErrorBoundaryProps) -> Element {
    return Element(
        tag: "div",
        value: "",
        children: props.children,
        attrs: [#("data-jhonstart-error-boundary", "true")],
    );
}

pub fn NotFoundBoundary(props: ErrorBoundaryProps) -> Element {
    return Element(
        tag: "div",
        value: "",
        children: props.children,
        attrs: [#("data-jhonstart-not-found-boundary", "true")],
    );
}
```

**Acceptance:**
- [ ] `ErrorBoundary` and `NotFoundBoundary` compile
- [ ] Render children with boundary metadata

### Step 2 — error.bp / not-found.bp conventions

Document file conventions:
- `error.bp`: exports `fn Error() -> Element` — fallback UI for errors in this segment
- `not-found.bp`: exports `fn NotFound() -> Element` — 404 UI
- `global-error.bp`: root-level error boundary (must include `<html>` and `<body>`)

```bp
// app/blog/error.bp
pub fn Error() -> Element {
    return div([
        h1([text("Something went wrong", attrs: [])], attrs: []),
        p([text("Please try again later.", attrs: [])], attrs: []),
    ], attrs: []);
}
```

**Acceptance:**
- [ ] Conventions documented
- [ ] File router integration (F14) will wire them up

### Step 3 — notFound() function

```bp
// Throw a special error to trigger not-found UI
#[@External.Node("onze13/runtime", "notFound")]
#[@External.Erlang("onze13_runtime", "not_found")]
declare fn notFound() -> void;
```

**Acceptance:**
- [ ] `notFound()` declared for both targets
- [ ] Throws an error the error boundary catches

### Step 4 — Tests

```bp
test "ErrorBoundary renders children" {
    val el = ErrorBoundary(ErrorBoundaryProps(
        fallback: { error -> div([text(error, attrs: [])], attrs: []) },
        children: [div([text("Content", attrs: [])], attrs: [])],
    ));
    val html = renderToString(el);
    assert html.contains("Content");
    assert html.contains("data-jhonstart-error-boundary");
}
```

**Acceptance:**
- [ ] Tests pass on commonJS + erlang

## Gate

- [ ] `botopink test` green
- [ ] `error_boundary.bp` in `botopink.json` and `root.bp`
- [ ] AGENTS.md updated
- [ ] Commit on `fix/jhonstart-error-boundaries`

## Blast radius

- New file `error_boundary.bp` — no changes to existing files
- Consumers can use error boundaries for graceful error handling

## Notes

- During SSR, error boundaries catch errors and render fallback. On the client, they catch runtime errors (requires client runtime support).
- `notFound()` throws a special error; the file router catches it and renders `not-found.bp`.

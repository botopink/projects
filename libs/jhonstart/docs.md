# jhonstart — reference

> A React/Next-style UI framework written in botopink, on the language's own
> primitives. Status: **scaffold** (declarations only). Spec:
> `tasks/v0.beta.5/specs/jhonstart.md`.

## Component model

A **component** is any `fn(...) -> Element`. A **hook** is any function whose
return implements `@Context<Element, _>`; `use` is only legal inside a component
body (enforced by the language's context-inference).

```bp
import { div, p, button, state } from "jhonstart";

fn Counter() -> Element {
    val {value, set} = use state(0);
    div {
        [
            p { "count: " + value },
            button({ -> set(value + 1) }) { "+" },
        ]
    }
}
```

## Hooks

| Hook | Returns | Notes |
|---|---|---|
| `state<T>(initial)` | `@Context<Element, {value: T, set: fn(T)}>` | local state + setter |
| `effect(run, deps)` | `@Context<Element, {}>` | side effect after render (void) |
| `memo<T>(compute, deps)` | `@Context<Element, T>` | memoized value |
| `ref<T>(initial)` | `@Context<Element, {current: T}>` | mutable handle |
| `reducer<S,A>(reduce, init)` | `@Context<Element, {state, dispatch}>` | reducer state |

Custom hooks compose the primitives — their return implements
`@Context<Element, _>`, propagated transitively.

## DOM builders

`div`/`span`/`p`/`h1`/`ul`/`li` take children as a trailing lambda; `button`
takes `onClick` first; `input(value, onInput)`; `text(value)` is an explicit text
node. A `string` child coerces to text; a single `Element` coerces to a
one-element `Children`.

## The `html` DSL

`html` captures markup unevaluated and expands it to an `Element` tree at compile
time: lowercase tags → builders, `<Component/>` → caller-scope lookup, `${expr}`
→ typed hole. Zero runtime cost.

```bp
import { html } from "jhonstart";
import { Page1 };
val name = "world";
val page = html
    \\<div>
    \\  <p>${name}</p>
    \\  <Page1/>
    \\</div>
;
```

## App layer (Next-style)

- `useRouter() -> @Context<Element, Router>`, `Link(href) { … }` — client navigation.
- `request() -> @Context<Http, Request>` — server hook; use inside a server
  component (`*fn … -> @Future<Element>`).
- File routing (`app/`, `page.bp`, `layout.bp`, `[id]`) is a **convention** (V1),
  wired manually in `main.bp` until a CLI/build step lands.
- `mount(app, selector)` (client) / `renderToString(app)` (SSR).

## V1 limits

Scaffold: signatures only, host-bound via `@[external]`. `use`/`await`/`*fn`
require the pending language work (`use-await-prefix`, `async-generators`); the
`html` DSL needs only the shipped `expr-templates`.

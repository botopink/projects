# jhonstart — reference

> A React/Next-style UI framework written in botopink, on the language's own
> primitives. Status: **core + hooks implemented in real `.bp`** (`Element` tree,
> builders, synchronous `renderToString`, and the `state`/`effect`/`memo`/`ref`/
> `reducer` family — compiled & runtime-tested). The `html` markup DSL, the
> router, and the Http server context remain declarative (`.d.bp`), each gated on
> a generic language gap (see **V1 limits**). Spec:
> `tasks/v0.beta.7/specs/jhonstart.md`.

## Component model

A **component** is any `fn(...) -> Element`. A **hook** is any function whose
return implements `@Context<Element, _>`; the `use` prefix is only legal inside a
component body (enforced by the language's context-inference, not by jhonstart).

```bp
import { div, p, text, state, renderToString } from "jhonstart";

fn Counter() -> Element {
    val c = use state(0);
    return div([
        p([text("count: " + c.value.toString())]),
    ]);
}

fn main() {
    print(renderToString(Counter()));   // synchronous SSR — a pure string
}
```

Children are written as a **list** (`div([a, b])`). A hook yields its value via
`use`: `val c = use state(0)` binds `c : State<i32>` (`c.value`, `c.set(n)`); the
`{value, set}` form also destructures — `val {value, set} = use state(0)`.

## Hooks

Hook **bodies are pure and synchronous** — they model the first render (SSR):
`state` yields its initial value, `memo` computes eagerly, `effect` is a no-op,
`ref`/`reducer` seed their boxes. Client re-render reactivity is the host
runtime's job: the `use` prefix lowers to the target's hook convention (React
`useState`/`useEffect`/… on `commonJS`).

| Hook | Returns (via `use`) | Notes |
|---|---|---|
| `state<T>(initial)` | `State<T>` = `{value: T, set: fn(next: T)}` | local state + setter |
| `effect(run, deps)` | `{}` | side effect after render (void) |
| `memo<T>(compute, deps)` | `T` | memoized value (computed eagerly in SSR) |
| `ref<T>(initial)` | `{current: T}` | mutable handle |
| `reducer<S,A>(reduce, init)` | `{state: S, dispatch: fn(action: A)}` | reducer state |

Custom hooks compose the primitives — their return implements
`@Context<Element, _>`, propagated transitively:

```bp
fn useCounter(start: i32) -> @Context<Element, State<i32>> {
    return state(start);
}
```

## DOM builders & rendering

`text(value)` is an explicit text node; `fragment(children)` groups siblings
with no wrapper; `div`/`span`/`p`/`h1`/`ul`/`li` are element builders. Each takes
a `Children` argument, so the call site can pass a **list** (`div([a, b])`), a
single `Element`, or a `string` (the G4 coercion). The **list form is what V1
renders** (and what the `html` DSL emits); a lone-child / `string` argument
type-checks but its render is a recorded follow-up.

`renderToString(e)` serializes a tree to HTML, purely and synchronously:

```bp
renderToString(div([p([text("hi")]), text("!")]))   // "<div><p>hi</p>!</div>"
```

## The `html` DSL — declared, gated (F2)

`html` is meant to capture markup unevaluated and expand it to an `Element` tree
at compile time (lowercase tags → builders, `<Component/>` → caller-scope lookup,
`${expr}` → typed hole), at zero runtime cost — the expr-templates machinery
applied to elements. The real body is **not yet shipped**: it is blocked by two
generic language gaps (a comptime template body sees only a native-JS prelude;
the generic loader doesn't bind a bare imported template-fn — so
`import {html} from "jhonstart"` leaves `html "…"` unbound). Authored trees use
the builders (`div([…])`) until it lands.

## App layer (Next-style) — declared, host-bound

- `useRouter() -> @Context<Element, Router>`, `Link(href, …)` — client navigation
  (host runtime; `Link` also needs an Element attribute slot for `href`).
- `request() -> @Context<Http, Request>` — server hook; used inside a server
  component (`*fn … -> @Future<Element>`).
- File routing (`app/`, `page.bp`, `layout.bp`, `[id]`) is a **convention** (V1),
  wired manually until a CLI/build step lands.
- `renderToString(app)` (SSR, real `.bp`) / client `mount` (host).

## V1 limits

- **Implemented now** (`element.bp` + `hooks.bp`, compiled + `test {}`-checked):
  the `Element` record, builders (`Children` args, list-form render), a
  synchronous `renderToString`, and the `state`/`effect`/`memo`/`ref`/`reducer`
  hook family (real SSR bodies). Author trees as `div([…])`.
- **Gated / declarative** (each a generic core gap, none jhonstart-specific):
  - the `html` markup body — comptime native-JS template prelude + the generic
    loader-bare gap;
  - `router`/`server` host hooks (`useRouter`/`request`, `#[@external]`), `Link`
    and form controls (the `Element` model has no attribute slot for
    `href`/`value`/`onClick`), and `get`-accessor interfaces (`.d.bp` syntax);
  - the `*fn`/`await` data-loading path (`use-await-prefix`, `async-generators`);
  - the trailing-lambda children sugar (`div { … }`) and lone-child / `string`
    `Children` *rendering* (type-checks today; render needs normalization).

# libs/jhonstart/src/

> Path: `libs/jhonstart/src/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Source for the `jhonstart` package. All files are `.d.bp` **declaration** files
today (signatures only, scanner-skipped, host-bound via `@[external]`) — the
scaffold stage. Bodies (`html.bp`, `fragment.bp`, custom hooks) arrive in the
spec's F3.

| File | Provides |
|---|---|
| `element.d.bp` | `Element` (UI node / hook ContextBase), `Children` |
| `dom.d.bp` | DOM builders: `div`, `span`, `p`, `h1`, `ul`, `li`, `button`, `input`, `text` |
| `hooks.d.bp` | `state`, `effect`, `memo`, `ref`, `reducer` (all `@Context<Element, _>`) |
| `html.d.bp` | `html(comptime q: @Expr<string>) -> @Expr<Element>` — the JSX-like DSL |
| `render.d.bp` | `mount` (client), `renderToString` (SSR, `*fn`) |
| `router.d.bp` | `Router`, `useRouter`, `Link` (Next-style navigation) |
| `server.d.bp` | `Http` ContextBase: `Request`, `request()` |

Keep declarations declarative — no bodies in `.d.bp`. Update this index in the
same change that adds/renames a file.

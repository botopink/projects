# libs/jhonstart/src/

> Path: `libs/jhonstart/src/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Source for the `jhonstart` package. The UI **core is real botopink** — an
`Element` tree, builders, and a synchronous SSR renderer implemented in `.bp`
(no host intrinsics, no async). Only the genuinely host-bound / gap-blocked
surface (interactive hooks, client navigation, the Http context) stays as
`.d.bp` **declarations**. `botopink.json` compiles only the `.bp` core; the
`.d.bp` files are illustrative until their language prerequisites land.

| File | Kind | Provides |
|---|---|---|
| `element.bp` | **compiled** | `record Element implement @Context<Element, Element>` (the UI node AND the hook ContextBase), builders (`text`, `fragment`, `div`/`span`/`p`/`h1`/`ul`/`li` — take `Element[]`), `renderToString` (pure, synchronous), `test {}` asserting the rendered HTML |
| `hooks.d.bp` | declarative | `state`, `effect`, `memo`, `ref`, `reducer` (`@Context<Element, _>`) — **blocked**: record callback-field returns `{value, set}` are inexpressible (gap G1) |
| `html.d.bp` | declarative | `html(comptime q: @Expr<string>) -> @Expr<Element>` — JSX-like DSL; body (markup scanner) pending |
| `router.d.bp` | declarative | `Router`, `useRouter`, `Link` (Next-style navigation) |
| `server.d.bp` | declarative | `Http` ContextBase: `Request`, `request()` |

Builders take `Element[]` directly (not a `fn() -> Children` trailing lambda):
the trailing-lambda children form needs `fn() -> T[]` parsing + an
`Element[]`→`Children` coercion the toolchain lacks (gaps G3/G4) — see the spec
Notes. The array form sidesteps both and lets the renderer (and a future
`html.bp`) build nested trees today.

Update this index in the same change that adds/renames a file, and keep
`botopink.json`'s `files` list in sync with the compiled `.bp` set.

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
| `hooks.d.bp` | declarative | `state`, `effect`, `memo`, `ref`, `reducer` (`@Context<Element, _>`) — the `{value, set}` callback-field return shape is now expressible (gap G1 closed); the bodies remain declarative pending the runtime |
| `html.d.bp` | declarative | `html(comptime q: @Expr<string>) -> @Expr<Element>` — JSX-like DSL; body (markup scanner) pending |
| `router.d.bp` | declarative | `Router`, `useRouter`, `Link` (Next-style navigation) |
| `server.d.bp` | declarative | `Http` ContextBase: `Request`, `request()` |

The four language gaps the framework surfaced are now closed (spec
`jhonstart-language-gaps`): records carry function-typed fields (`set: fn(T)`,
G1), anonymous record types annotate hook shapes (G2), a function type returns
an array (`fn() -> Element[]`, G3), and `Element[]`/`Element`/`string` coerce
into a `Children` parameter (G4) — so `div([a, b])`, `div(child)`, and a
`Children`-typed builder all type-check. `element.bp`'s builders still take
`Element[]` directly; migrating them to a `Children` parameter is follow-up
framework work on `task/jhonstart`.

Update this index in the same change that adds/renames a file, and keep
`botopink.json`'s `files` list in sync with the compiled `.bp` set.

# libs/jhonstart/src/

> Path: `libs/jhonstart/src/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Source for the `jhonstart` package. The UI **core and hooks are real botopink** —
an `Element` tree, builders, a synchronous SSR renderer, and the hook family,
all implemented in `.bp` (no host intrinsics, no async). Only the genuinely
host-bound / still-gated surface (client navigation, the Http context, the `html`
markup body) stays as `.d.bp` **declarations**, each carrying an explicit
"STILL GATED" note naming the gap. `botopink test` compiles the `.bp` files and
runs their `test {}` blocks; the `.d.bp` files are type surface for consumers.

| File | Kind | Provides |
|---|---|---|
| `element.bp` | **compiled** | `record Element implement @Context<Element, Element>` with a `Children` `children` field (the UI node AND the hook ContextBase), builders (`text`, `fragment`, `div`/`span`/`p`/`h1`/`ul`/`li` — take `Children`), `renderToString` (pure, synchronous), `test {}` (render + the G4 coercion) |
| `hooks.bp` | **compiled** | `record State<T> { value, set: fn(next: T) }` (G1) + `state`/`effect`/`memo`/`ref`/`reducer` returning `@Context<Element, _>` with real SSR bodies (G2 anon shapes for `{current}`/`{state,dispatch}`), `test {}` calling the bodies directly + a `use`-component that type-checks the capability |
| `html.d.bp` | declarative (GATED) | `html(comptime q: @Expr<string>) -> @Expr<Element>` — JSX-like DSL; body deferred (F2): comptime native-JS prelude + the loader-bare gap |
| `router.d.bp` | declarative (GATED) | `Router`, `useRouter`, `Link` — host-bound navigation; getters + `#[@external]` + no Element attribute slot |
| `server.d.bp` | declarative (GATED) | `Http` ContextBase: `Request`, `request()` — host-bound + async loaders |

The four language gaps the framework surfaced are closed (spec
`jhonstart-language-gaps`, v0.beta.6) and now **used** here: records carry
function-typed fields (`set: fn(next: T)`, G1 — `State<T>` in `hooks.bp`),
anonymous record types annotate transient hook shapes (G2 — `{current}`,
`{state, dispatch}`), a function type returns an array (G3), and
`Element[]`/`Element`/`string` coerce into a `Children` parameter (G4 — the
builders' `children` arg and the `Element.children` field). The list form
(`div([a, b])`) is the rendering contract; the single/`string` forms type-check
(asserted in `element.bp`) but their render is the recorded normalization
follow-up (no runtime type tags to branch a lone child vs a list on).

This port also relies on a generic **cross-module** fix (a local component
returning an imported `Element`, fed to an imported `renderToString`/`use`, now
type-checks) — see `modules/compiler-core/src/comptime/AGENTS.md`
(`type_decl_registry` + `resolveTypeName`). It is lib-agnostic; the
`grep -riE "rakun|jhonstart"` gate stays clean.

Update this index in the same change that adds/renames a file, and keep
`botopink.json`'s `files` list in sync.

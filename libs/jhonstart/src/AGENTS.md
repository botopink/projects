# libs/jhonstart/src/

> Path: `libs/jhonstart/src/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Source for the `jhonstart` package. The UI **core, hooks, and the `html` markup
DSL are real botopink** — an `Element` tree, builders, a synchronous SSR renderer,
the hook family, and the `html """…"""` comptime expander, all implemented in
`.bp` (no host intrinsics, no async). Only the genuinely host-bound surface
(client navigation, the Http context) stays as `.d.bp` **declarations**, each
carrying an explicit "STILL GATED" note naming the gap. `botopink test` compiles
the `.bp` files and runs their `test {}` blocks; the `.d.bp` files are type
surface for consumers.

| File | Kind | Provides |
|---|---|---|
| `element.bp` | **compiled** | `record Element implement @Context<Element, Element>` with a `Children` `children` field (the UI node AND the hook ContextBase), builders (`text`, `fragment`, `div`/`span`/`p`/`h1`/`ul`/`li` — take `Children`), `renderToString` (pure, synchronous), `test {}` (render + the G4 coercion) |
| `hooks.bp` | **compiled** | `record State<T> { value, set: fn(next: T) }` (G1) + `state`/`effect`/`memo`/`ref`/`reducer` returning `@Context<Element, _>` with real SSR bodies (G2 anon shapes for `{current}`/`{state,dispatch}`), `test {}` calling the bodies directly + a `use`-component that type-checks the capability |
| `html.bp` | **compiled** | `html(comptime template: @Expr<string>) -> @Expr<Element>` — the JSX-like `html """…"""` DSL: a native-JS-only comptime parser walks `template.parts()` and `build()`s the builder pipeline (`<tag>` → `tag([...])`, text → `text("…")`, `${expr}` → `text(<code>)`), resolving lowercase tags in the **caller's** scope. Exercised by `examples/jhonstart-html` (`.bp` tests). See the file header for the comptime-eval constraints (no `?T`, no in-body comments, `.forEach` not a nested `loop`, root tracking by array length) |
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

# Track C — jhonstart

**Track:** C — jhonstart · **Repo:** `repository/jhonstart` · **Reference:** Next.js docs (`/home/ericfillipe/develop/nextjs/NEXTJS-DOCS.md`), the React half — the HTML render, App Router hooks, `<Link>`, Server/Client Components, streaming, error boundaries, metadata, forms, `'use client'` — plus the `html """…"""` DSL and the element surface that half renders through.

**jhonstart writes the HTML** (decision 113): the render, its escaping, the document, the payload, islands, streaming, links, hydration, the client router (with `clientApp`, the client-only entry), the navigation signals end to end and the UI file conventions (`#[page]`, `#[layout]`, `#[template]` — each a `fn … -> @Component<ElementBase, Element>` — `PageContext`, `LayoutProps`; decisions 114 and 117) are this track's, and emilia's CSS enters through the render-plugin point and the `jhonstart-emilia` bridge member. jhonstart and rakun never import each other; onze is the only package that names both.

Front numbers are stable identifiers: `26` is `26-jhonstart-router` here and everywhere else. New work gets a new number, never a renumbering.

| File | Holds |
|---|---|
| [`modules.md`](./modules.md) | The package cut: `modules/jhonstart`, `-html`, `-link`, `-forms`, `-emilia` (the bridge), `-test`; dependency graph; targets; front → directory ownership; relations to emilia/rakun/onze; `examples/**` |
| [`unification.md`](./unification.md) | How the coordinates the READMEs cite resolve in this milestone; the Next.js rows no front owns yet |
| [`test-snap.md`](./test-snap.md) | The preventive snapshot-test map of the modules — helper signatures, `.bp` cases, exact `.snap` files |
| [`test-snap-examples.md`](./test-snap-examples.md) | The same map for `repository/jhonstart/examples/**` |

## 1 · Fronts — in blocking order

Ordered by the level each front occupies in the dependency graph; *(ro)* = read-only citation, not an edge. **Wave (milestone)** is the level [`../fronts.md`](../fronts.md) § *Waves* computes across all five tracks from the unannotated `Depends on` edges — not a track-internal numbering, which is only a lower bound. It is regenerated there and copied here; a wave is corrected in `fronts.md` first.

| # | Front | Priority | Wave (milestone) | Submodule | Depends on (track C) | Depends on (other tracks) | Gate |
|---|---|---|---|---|---|---|---|
| **94** | [`94-jhonstart-element-surface`](./94-jhonstart-element-surface/README.md) | critical | 0 | `jhonstart` | — | — | both |
| **26** | [`26-jhonstart-router`](./26-jhonstart-router/README.md) | critical | 1 | `jhonstart` | 94 (examples) | 01 std (`encoding`) · std `04-routing-lib` (`matchPath` / `parseTable`, `navigation.signalFromWire`, imported from the bundled `routing`) · std `05-actions-lib` (`refreshValue`) · 22 rakun file-routing (the format) *(ro)* | erlang · commonJS (`clientApp`) |
| **28** | [`28-jhonstart-server-components`](./28-jhonstart-server-components/README.md) | critical | 2 | `jhonstart` | 26 (`pairValue`) · 94 (examples) | 01 std (`escape`) · 30 (the render enters the `RequestData` onze hands it) | erlang |
| **27** | [`27-jhonstart-link`](./27-jhonstart-link/README.md) | critical | 2 | `jhonstart-link` | 26 · 94 (examples) | 60 rakun static-generation *(ro)* · 68 onze client-bundle *(ro)* | commonJS |
| **29** | [`29-jhonstart-client-directive`](./29-jhonstart-client-directive/README.md) | high | 3 | `jhonstart` | 28 · 94 (examples) | 68 *(soft — enforces the boundary)* | commonJS |
| **30** | [`30-jhonstart-streaming`](./30-jhonstart-streaming/README.md) — render and streaming | high | 4 | `jhonstart` · `jhonstart-emilia` | 28 · 29 · 31 · 32 · 94 | 01 std (`escape`, `json.*`, `escape.scriptJson`, `json.decode` — `01-std-lib-enablement`) · 02 std async (spawn/gather over thunks) · std `04-routing-lib` (`navigation`, `matchPath` for the redirect-target check) · emilia `flush()` (bridge only) | both |
| **31** | [`31-jhonstart-error-boundaries`](./31-jhonstart-error-boundaries/README.md) | high | 3 | `jhonstart` | 28 · 94 (`htmlTag`/`body`) | 03 std content-hash · std `04-routing-lib` (`navigation` — the `nav:` reasons) · 17 rakun logging *(ro)* · 24 *(ro)* · 63 rakun navigation-signals *(ro)* | erlang |
| **32** | [`32-jhonstart-metadata`](./32-jhonstart-metadata/README.md) | medium | 3 | `jhonstart` | 28 · 26 (`pairValue`) | 01 std (`escape`) · 66 rakun metadata-file-routes *(ro)* | erlang |
| **67** | [`67-jhonstart-forms`](./67-jhonstart-forms/README.md) | high | 7 | `jhonstart-forms` | 29 · 94 · 26 (`push`) · 27 (prefetch) · 31 *(ro)* | std `05-actions-lib` (`ActionState`, envelope, RPC body) · 24 rakun server-actions *(ro — wire names handed in by onze)* · std `06-validation-lib` *(ro — the application imports it)* · 63 *(ro)* · 01 std (percent encoding) | commonJS |

Cross-track fronts that deliver **into** this repo or consume it: 48 emilia-attributes (owns `modules/jhonstart/src/html_attrs.bp`; depends on 26); 23 rakun-ssr-pipeline (puts on the socket the status, headers and chunks front 30's render writes through the `Response` onze adapts over rakun's `ChunkWriter` — it imports nothing from jhonstart); 24 rakun-server-actions (owns the action id and envelope that 67's form carries, through onze, with the wire names onze passes both sides); 49 onze-stand-up (registers the `jhonstart-emilia` plugin, registers one rakun `PageRenderer` per page over front 30's `renderStream`, and wires jhonstart to rakun); 68 onze-client-bundle (generated entry calls 29's `hydrate()`, 27's `linkMount()`, 67's `formMount()`); 53 onze-example-app (the browser-in-the-loop proof).

## 2 · Critical path

`94 → 26 → 28 → {27 · 29 · 31 · 32} → 30`, and `{29 · 27} → 67`, with the cross-track gates `01 → 26`, `02 → 30`, `03 → 31`, `24 + 68 → 67`. Front 30 renders what 29, 31 and 32 produce (`islandAttr`, `renderBoundaryChecked`, `renderHead`), so it follows them; its wave in the table is `fronts.md`'s and moves when that file is regenerated. Front 94 is wave 0 and blocks nothing by ordering — every other front cites it only for the builders its examples use, except 31 (`global-error.bp` needs `htmlTag`/`body`) and 67 (`form`/`input`/`button`/`label`).

## 3 · Dependency graph

```
                 01 std                                       94 element-surface
              (escape,                                      (elements.bp, root.bp)
             querystring)                                           │
                  │                                                 │ examples only
                  └────────┬────────────────────────────────────────┘
                           ▼                                        │
                    26 router  ◄────────────────────────────────────┘
                 (RouterState, hooks, pairValue, __jhNavigate)
                           │
            ┌──────────────┼──────────────────────────────┐
            ▼              ▼                              │
   27 link ── 60 (ro)   28 server-components ◄── 62 (ro)  │
 (Link, prefetchMode,   (RequestData, request,            │
  reconcile)             loader convention)               │
            │              │                              │
            │     ┌────────┼─────────────┬────────────────┤
            │     ▼        ▼             ▼                ▼
            │  29 client  30 render +   31 error-bound.  32 metadata
            │  (#[client],   streaming  (ErrorBoundary,  (Metadata, merge,
            │   Island,   (renderNode,   digest, signals, renderHead, Viewport)
            │   hydrate)   payload,      notFound)        ▲
            │              RenderPlugin, ▲                │
            │              globals)      │                │
            │     │           ▲              │                │
            │     │        02 std          03 std          66 (ro)
            │     │                                           
            └─────┴───────────► 67 forms ◄──── 24 rakun server-actions (envelope) · 68 (entry)
                             (ActionState, formAttrs,
                              actionState, formStatus,
                              optimistic, <Form>)

   48 emilia-attributes ──► html_attrs.bp (core)
   30 ──► jhonstart-emilia (bridge: RenderPlugin over emilia's flush(); payload `s`)
   rakun and onze are not in this graph: onze imports jhonstart, rakun imports neither way
```

## 4 · Targets

| Fronts | Target | Why |
|---|---|---|
| 28 · 32 | erlang | render on the server only |
| 26 · 30 · 31 · 94 | both — boundary | 26's `__jhNavigate` is the one dual-target cell in an erlang router; 30 renders the document and produces chunks on BEAM that `render.mjs` adopts in the browser; 31 catches on both sides; 94's constructors must produce the identical `Element` on both |
| 27 · 29 · 67 | js | run in the browser; their pure halves (`Link`, `clientMount`, `formAttrs`) still render in the server pass |

Every front's tests assert string literals so that a divergence between the two targets is a red cell rather than a hydration mismatch discovered by a reader. The snapshot form of those literals is `test-snap.md`.

## 5 · Frozen for the milestone

`modules/jhonstart/src/element.bp`, `modules/jhonstart/src/hooks.bp`, `modules/jhonstart-html/src/html.bp` — content frozen (`html.bp` imports `Element` from `"jhonstart"`, `modules.md § 1.3`) but for decision 138's respelling of the phantom base as `type ElementBase()`. The consequences that shape every front: `renderToString` neither escapes nor knows void elements (front 30's `renderNode` does both; 94's `isVoidTag`/`isRawTextTag` feed it); a self-closing tag cannot be authored inside `html """…"""`. A builder's `attrs` defaults to `[]` and the default travels with the imported function, so `attrs:` is written only when there are attributes.

## 6 · Written with `use`, under a `@Component` return

Every hook and every component in this track follows decisions 118–128 (front
[`00 · 24-effects-by-return`](../00-compiler-carry-over/24-effects-by-return/README.md) and its
[`guide.md`](../00-compiler-carry-over/24-effects-by-return/guide.md) § 4):

1. `Element` is the context owner: `pub type Element(…) implement @Context<ElementBase>` (decision 102). `ElementBase` is the base every hook in this track anchors on.
2. A hook is `pub fn <noun>(…) -> @Component<ElementBase, R>` — `router`, `pathname`, `params`, `searchParams`, `selectedLayoutSegment(s)`, `linkStatus`, `formStatus`, `actionState`, `optimistic`, `request` — with **no `use` prefix in its name**; the keyword is the activation. A hook composing hooks has the same shape. There is no annotation: the return is the declaration of the effect (decision 118).
3. It is activated as `val x = use <noun>(…)` in the static prefix of a `@Component` body; never the doubled `use` + `use<Noun>()`. Only a `@Component<C, T>` return grants `use`: a body that activates a hook without one is `use-without-context-effect`, and the base of every `use` in one body is the same `ElementBase` (decision 96).
4. **A component that activates a hook or awaits is `fn … -> @Component<ElementBase, Element>`** — one wrapper for hooks and components (decision 128), the base always written, and `@Component ⊃ @Task`, so a server component awaits its loaders and activates `request()` under the one return. A component is **called** (`Card()`), never `use`d.
5. **A component never propagates an error** (decision 121): `throw` and `try` are legal only when the return carries a `@Result`, and `Element` is not one. A page, layout or component handles a failure in its own body — `try await load() catch fallback`, a `case`, `notFound()` or an error screen.
6. **A component that activates nothing returns bare `Element`**: `Loading`, `NotFound`, `GlobalError`, `ErrorPage`, `Link`, `Suspense` and every pure twin (`sidebarFor`, `checkoutLinkFor`, `greetingBar`) are ordinary functions.
7. Called without `use` a hook is an ordinary call — the server-pass value; that is what every `test` uses, since a `test` body has no `@Component` return.
8. The binding never reuses the hook's name (`val r = use router()`); type constructors stay PascalCase (`RouterState`, `LinkStatus`, `FormStatus`, `ActionState`) and helpers take a verb (`newActionState`, `parseActionState`). The Next.js names appear only where a text names Next's API as the reference.
9. On the commonJS target every `@Component` body is emitted as `async function` (decision 104): a component and a hook return a Promise there, and a caller `await`s. On erlang `@Task` is eager and `await` is identity.

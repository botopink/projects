# Track C — jhonstart

**Track:** C — jhonstart · **Repo:** `repository/jhonstart` · **Reference:** Next.js docs (`/home/ericfillipe/develop/nextjs/NEXTJS-DOCS.md`), the React half — the HTML render, App Router hooks, `<Link>`, Server/Client Components, streaming, error boundaries, metadata, forms, `'use client'` — plus the `html """…"""` DSL and the element surface that half renders through.

**jhonstart writes the HTML** (decision 113): the render, its escaping, the document, the payload, islands, streaming, links, hydration and the client router are this track's, and emilia's CSS enters through the render-plugin point and the `jhonstart-emilia` bridge member. jhonstart and rakun never import each other; onze is the only package that names both.

Front numbers are stable identifiers: `26` is `26-jhonstart-router` here and everywhere else. New work gets a new number, never a renumbering.

| File | Holds |
|---|---|
| [`modules.md`](./modules.md) | The package cut: `modules/jhonstart`, `-html`, `-link`, `-forms`, `-emilia` (the bridge), `-test`; dependency graph; targets; front → directory ownership; relations to emilia/rakun/onze; `examples/**` |
| [`unification.md`](./unification.md) | How the coordinates the READMEs cite resolve in this milestone; the Next.js rows no front owns yet |
| [`test-snap.md`](./test-snap.md) | The preventive snapshot-test map of the modules — helper signatures, `.bp` cases, exact `.snap` files |
| [`test-snap-examples.md`](./test-snap-examples.md) | The same map for `repository/jhonstart/examples/**` |

## 1 · Fronts — in blocking order

Ordered by the level each front occupies in the dependency graph; *(ro)* = read-only citation, not an edge. **Wave (milestone)** is the level [`../../fronts.md`](../../fronts.md) § *Waves* computes across all five tracks from the unannotated `Depends on` edges — not a track-internal numbering, which is only a lower bound. It is regenerated there and copied here; a wave is corrected in `fronts.md` first.

| # | Front | Priority | Wave (milestone) | Submodule | Depends on (track C) | Depends on (other tracks) | Gate |
|---|---|---|---|---|---|---|---|
| **94** | [`94-jhonstart-element-surface`](./94-jhonstart-element-surface/README.md) | critical | 0 | `jhonstart` | — | — | both |
| **26** | [`26-jhonstart-router`](./26-jhonstart-router/README.md) | critical | 3 | `jhonstart` | 94 (examples) | 01 std · 22 rakun file-routing (`match`, handed in by onze) *(ro)* | erlang |
| **28** | [`28-jhonstart-server-components`](./28-jhonstart-server-components/README.md) | critical | 4 | `jhonstart` | 26 (`pairValue`) · 94 (examples) | 01 std (`escape`) · 62 rakun request-context *(ro)* | erlang |
| **27** | [`27-jhonstart-link`](./27-jhonstart-link/README.md) | critical | 4 | `jhonstart-link` | 26 · 94 (examples) | 60 rakun static-generation *(ro)* · 68 onze client-bundle *(ro)* | commonJS |
| **29** | [`29-jhonstart-client-directive`](./29-jhonstart-client-directive/README.md) | high | 5 | `jhonstart` | 28 · 94 (examples) | 68 *(soft — enforces the boundary)* | commonJS |
| **30** | [`30-jhonstart-streaming`](./30-jhonstart-streaming/README.md) — render and streaming | high | 5 | `jhonstart` · `jhonstart-emilia` | 28 · 29 · 31 · 32 · 94 | 01 std (`escape`) · 02 std async (spawn/gather over thunks) · emilia `flush()` (bridge only) | both |
| **31** | [`31-jhonstart-error-boundaries`](./31-jhonstart-error-boundaries/README.md) | high | 5 | `jhonstart` | 28 · 94 (`htmlTag`/`body`) | 03 std content-hash · 17 rakun logging *(ro)* · 24 *(ro)* · 63 rakun navigation-signals *(ro)* | erlang |
| **32** | [`32-jhonstart-metadata`](./32-jhonstart-metadata/README.md) | medium | 5 | `jhonstart` | 28 · 26 (`pairValue`) | 01 std (`escape`) · 66 rakun metadata-file-routes *(ro)* | erlang |
| **67** | [`67-jhonstart-forms`](./67-jhonstart-forms/README.md) | high | 8 | `jhonstart-forms` | 29 · 94 · 26 (`push`) · 27 (prefetch) · 31 *(ro)* | 24 rakun server-actions (envelope) · 14 rakun validation *(ro)* · 63 *(ro)* · 01 std (percent encoding) | commonJS |

Cross-track fronts that deliver **into** this repo or consume it: 48 emilia-attributes (owns `modules/jhonstart-html/src/html_attrs.bp`; depends on 26); 23 rakun-ssr-pipeline (writes the chunks front 30's render produces, through onze — it imports nothing from jhonstart); 24 rakun-server-actions (owns the action id and envelope that 67's form carries, through onze); 49 onze-stand-up (registers the `jhonstart-emilia` plugin and wires jhonstart to rakun); 68 onze-client-bundle (generated entry calls 29's `hydrate()`, 27's `linkMount()`, 67's `formMount()`); 53 onze-example-app (the browser-in-the-loop proof).

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

   48 emilia-attributes ──► html_attrs.bp (jhonstart-html)
   30 ──► jhonstart-emilia (bridge: RenderPlugin over emilia's flush())
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

`modules/jhonstart/src/element.bp`, `modules/jhonstart/src/hooks.bp`, `modules/jhonstart-html/src/html.bp` — content frozen; the one relocation edit each of `html.bp` and 48's `html_attrs.bp` needs is listed in `modules.md § 1.3`. The consequences that shape every front: `renderToString` neither escapes nor knows void elements (front 30's `renderNode` does both; 94's `isVoidTag`/`isRawTextTag` feed it); declared parameter defaults are never applied, so every constructor call spells `attrs:`; a self-closing tag cannot be authored inside `html """…"""`.

## 6 · Written with `use`, under `#[@use]`

Every hook and every component in this track follows [`00-compiler-carry-over/19-use-activation`](../00-compiler-carry-over/19-use-activation/README.md) § *The rule for libraries* and decisions 102 and 104:

1. `Element` is the context owner: `pub type Element(…) implement @Context<ElementBase>` (decision 102). `ElementBase` is the base every hook in this track anchors on.
2. A hook is `#[@use] pub fn <noun>(…) -> @Use<ElementBase, R>` — `router`, `pathname`, `params`, `searchParams`, `selectedLayoutSegment(s)`, `linkStatus`, `formStatus`, `actionState`, `optimistic`, `request` — with **no `use` prefix in its name**; the keyword is the activation. A hook composing hooks has the same shape.
3. It is activated as `val x = use <noun>(…)` in the static prefix of a `#[@use]` body; never the doubled `use` + `use<Noun>()`. Only `#[@use]` grants `use` (decision 104): a body that activates a hook without it is `use-without-context-effect`, and the base of every `use` in one body is the same `ElementBase` (decision 96).
4. **A component that activates a hook or awaits is `#[@use] fn … -> @Component<Element>`** — `@Component<Element>` is `@Use<ElementBase, Element>` for `Element: @Context<ElementBase>`, and `@Component ⊃ @Future`, so a server component awaits its loaders and activates `request()` under the one annotation (decisions 102, 104). A component is **called** (`Card()`), never `use`d.
5. **A component that activates nothing carries no annotation and returns bare `Element`** (decision 104, question 92-b): `Loading`, `NotFound`, `GlobalError`, `ErrorPage`, `Link`, `Suspense` and every pure twin (`sidebarFor`, `checkoutLinkFor`, `greetingBar`) are ordinary functions.
6. Called without `use` a hook is an ordinary call — the server-pass value; that is what every `test` uses, since a `test` body carries no `#[@use]`.
7. The binding never reuses the hook's name (`val r = use router()`); type constructors stay PascalCase (`RouterState`, `LinkStatus`, `FormStatus`, `ActionState`) and helpers take a verb (`newActionState`, `parseActionState`). The Next.js names appear only where a text names Next's API as the reference.
8. On the commonJS target every `#[@use]` body is emitted as `async function` (decision 104): a component and a hook return a Promise there, and a caller `await`s. On erlang `@Future` is eager and `await` is identity.

Rules 1–4 and 8 are written in the specs and not yet in the compiler: the effect-chain task (front 19 step 2) lands `#[@use]`, `@Use`, `@Component` and `@Context<Base>`, and until then front 28's `request()` is a plain function and every hook in the tree is called, not `use`d.

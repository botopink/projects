# Track C — jhonstart

**Track:** C — jhonstart · **Repo:** `repository/jhonstart` · **Reference:** Next.js docs (`/home/ericfillipe/develop/nextjs/NEXTJS-DOCS.md`), the React half — App Router hooks, `<Link>`, Server/Client Components, streaming, error boundaries, metadata, forms, `'use client'` — plus the `html """…"""` DSL and the element surface that half renders through.

Front numbers are **1.0.9-beta identifiers** and are preserved: `26` is `26-jhonstart-router` in both milestones, and the directories keep their exact 1.0.9 names. New work in this milestone gets a new number, never a renumbering.

| File | Holds |
|---|---|
| [`modules.md`](./modules.md) | The package cut: `modules/jhonstart`, `-html`, `-link`, `-forms`, `-test`; dependency graph; targets; front → directory ownership; relations to emilia/rakun/onze; `examples/**` |
| [`unification.md`](./unification.md) | Proof of lossless carry from 1.0.9 and absorption of the 1.0.7 draft; the Next.js rows still missed |
| [`test-snap.md`](./test-snap.md) | The preventive snapshot-test map of the modules — helper signatures, `.bp` cases, exact `.snap` files |
| [`test-snap-examples.md`](./test-snap-examples.md) | The same map for `repository/jhonstart/examples/**` |

## 1 · Fronts — in blocking order

Ordered by the level each front occupies in the dependency graph (`../../fronts.md` computes waves from the unannotated `Depends on` edges; *(ro)* = read-only citation, not an edge). Priority and wave are the 1.0.9 values.

| # | Front | Priority | Wave | Submodule | Depends on (track C) | Depends on (other tracks) | Gate |
|---|---|---|---|---|---|---|---|
| **94** | [`94-jhonstart-element-surface`](./94-jhonstart-element-surface/README.md) | critical | 0 | `jhonstart` | — | — | both |
| **26** | [`26-jhonstart-router`](./26-jhonstart-router/README.md) | critical | 2 | `jhonstart` | 94 (examples) | 01 std · 22 rakun file-routing (`matchPath`) · 23 rakun ssr *(ro)* | erlang |
| **28** | [`28-jhonstart-server-components`](./28-jhonstart-server-components/README.md) | critical | 3 | `jhonstart` | 26 (`pairValue`) · 94 (examples) | 01 std (`escape`) · 62 rakun request-context *(ro)* · 23 *(ro)* | erlang |
| **27** | [`27-jhonstart-link`](./27-jhonstart-link/README.md) | critical | 4 | `jhonstart-link` | 26 · 94 (examples) | 60 rakun static-generation *(ro)* · 68 onze client-bundle *(ro)* · 23 *(ro)* | commonJS |
| **29** | [`29-jhonstart-client-directive`](./29-jhonstart-client-directive/README.md) | high | 4 | `jhonstart` | 28 · 94 (examples) | 23 *(ro)* · 68 *(soft — enforces the boundary)* | commonJS |
| **30** | [`30-jhonstart-streaming`](./30-jhonstart-streaming/README.md) | high | 4 | `jhonstart` | 28 · 94 (examples) | 02 std async (spawn/gather over thunks) · 23 *(ro)* | erlang |
| **31** | [`31-jhonstart-error-boundaries`](./31-jhonstart-error-boundaries/README.md) | high | 6 | `jhonstart` | 28 · 94 (`htmlTag`/`body`) | 03 std content-hash · 17 rakun logging *(ro)* · 24 *(ro)* · 63 rakun navigation-signals *(ro)* | erlang |
| **32** | [`32-jhonstart-metadata`](./32-jhonstart-metadata/README.md) | medium | 6 | `jhonstart` | 28 · 26 (`pairValue`) | 01 std (`escape`) · 66 rakun metadata-file-routes *(ro)* | erlang |
| **67** | [`67-jhonstart-forms`](./67-jhonstart-forms/README.md) | high | 6 | `jhonstart-forms` | 29 · 94 · 26 (`push`) · 27 (prefetch) · 31 *(ro)* | 24 rakun server-actions (envelope) · 14 rakun validation *(ro)* · 63 *(ro)* · 01 std (percent encoding) | commonJS |

Cross-track fronts that deliver **into** this repo or consume it: 48 emilia-attributes (owns `modules/jhonstart-html/src/html_attrs.bp`; depends on 26); 23 rakun-ssr-pipeline (renders every core module); 24 rakun-server-actions (builds its form from 94's constructors); 68 onze-client-bundle (generated entry calls 29's `hydrate()`, 27's `__onzeLinkMount()`, 67's `__jhFormMount()`); 53 onze-example-app (the browser-in-the-loop proof).

## 2 · Critical path

`94 → 26 → 28 → {27 · 29 · 30} → {31 · 32} → 67`, with the cross-track gates `01 → 26`, `22 → 26`, `02 → 30`, `03 → 31`, `24 + 68 → 67`. Front 94 is wave 0 and blocks nothing by ordering — every other front cites it only for the builders its examples use, except 31 (`global-error.bp` needs `htmlTag`/`body`) and 67 (`form`/`input`/`button`/`label`).

## 3 · Dependency graph

```
                 01 std       22 rakun file-routing           94 element-surface
              (escape,         (route table, matchPath)     (elements.bp, root.bp)
             querystring)             │                             │
                  │                   │                             │ examples only
                  └────────┬──────────┘                             │
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
            │  29 client  30 streaming  31 error-bound.  32 metadata
            │  (#[client],(Boundary,    (ErrorBoundary,  (Metadata, merge,
            │   Island,    Chunk,        digest, signals) renderHead, Viewport)
            │   hydrate)   fillHtml)         ▲                ▲
            │     │           ▲              │                │
            │     │        02 std          03 std          66 (ro)
            │     │                                           
            └─────┴───────────► 67 forms ◄──── 24 rakun server-actions (envelope) · 68 (entry)
                             (ActionState, formAttrs,
                              actionState, formStatus,
                              optimistic, <Form>)

   48 emilia-attributes ──► html_attrs.bp (jhonstart-html)     23 rakun ssr ──► renders 26 · 28 · 29 · 30 · 31 · 32 · 94
```

## 4 · Targets

| Fronts | Target | Why |
|---|---|---|
| 28 · 32 | erlang | render on the server only |
| 26 · 30 · 31 · 94 | both — boundary | 26's `__jhNavigate` is the one dual-target cell in an erlang router; 30 produces chunks on BEAM that the browser adopts; 31 catches on both sides; 94's constructors must produce the identical `Element` on both |
| 27 · 29 · 67 | js | run in the browser; their pure halves (`Link`, `clientMount`, `formAttrs`) still render in the server pass |

Every front's tests assert string literals so that a divergence between the two targets is a red cell rather than a hydration mismatch discovered by a reader. The snapshot form of those literals is `test-snap.md`.

## 5 · Frozen for the milestone

`modules/jhonstart/src/element.bp`, `modules/jhonstart/src/hooks.bp`, `modules/jhonstart-html/src/html.bp` — content frozen; the one relocation edit each of `html.bp` and 48's `html_attrs.bp` needs is listed in `modules.md § 1.3`. The consequences that shape every front: `renderToString` neither escapes nor knows void elements (front 23's `renderNode` does both; 94's `isVoidTag`/`isRawTextTag` feed it); declared parameter defaults are never applied, so every constructor call spells `attrs:`; a self-closing tag cannot be authored inside `html """…"""`.

## 6 · Written with `use`, under `#[@context]`

Every hook and every component in this track follows [`00-compiler-carry-over/19-use-activation`](../00-compiler-carry-over/19-use-activation/README.md) § *The rule for libraries*, as decisions 87–90 settled it:

1. A hook is `pub fn <noun>(…) -> @Context<Element, R>` — `router`, `pathname`, `params`, `searchParams`, `selectedLayoutSegment(s)`, `linkStatus`, `formStatus`, `actionState`, `optimistic`, `request` — with **no `use` prefix in its name** and no annotation of its own; the keyword is the activation.
2. It is activated as `val x = use <noun>(…)` in the static prefix of an activating body; never the doubled `use` + `use<Noun>()`.
3. **A component is `#[@context] fn … -> Element`** — no longer "any `fn … -> Element`" (decision 88). The annotation is the lowercase effect; a capital `#[@Context]` is an unknown annotation the compiler silently ignores, and a body that activates a hook without it is `use-without-context-effect`. A custom hook composing hooks carries it too: `#[@context] fn <noun>(…) -> @Context<Element, _>`.
4. **A server component is `#[@future] fn … -> @Future<Element>`, with no second annotation** (decision 90): one effect annotation per fn, and the wrapper effect activates on its own because `@Future<Element>` unwraps to the owner `Element` (decision 89). `#[@future] #[@context]` is `effect-duplicate-annotation`.
5. Called without `use` a hook is an ordinary call — the server-pass value; that is what every `test` and every `sidebarFor`/`checkoutLinkFor`-style pure twin uses, and the caller needs no annotation for it.
6. The binding never reuses the hook's name (`val r = use router()`); type constructors stay PascalCase (`RouterState`, `LinkStatus`, `FormStatus`, `ActionState`) and helpers take a verb (`newActionState`, `parseActionState`). The Next.js names appear only where a text names Next's API as the reference.

Item 4 is written in the specs and not yet in the compiler: front 19 step 2 is what makes `use request()` infer inside a `#[@future]` body, and front 28's `server.d.bp` stays gated until it lands.

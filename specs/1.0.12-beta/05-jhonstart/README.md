# Track 05 — jhonstart

**Repo:** `repository/jhonstart` · **Reference:** Next.js docs, the React half · tree on disk:
[`modules.md`](./modules.md).

jhonstart writes the HTML (decision 113): render, document, payload, islands, streaming, links,
hydration, client router, navigation signals, UI file conventions. All exist and are green
(`jhonstart` 204 tests on both rows, seven members, eight example members, no `// LANGUAGE GAP`
marker). Left: a tail of code and spec items, three fronts by the member each edits.

## What jhonstart still owes

| Id | Item | Where | Front |
|---|---|---|---|
| JH-26-6 | late-signal handler twice: `registerSignal` in `render.mjs:199` (`globals().signal`, `replaceState` at `:213`) and `handleSignal` in `client_app.bp:219` | core | 26 step 2 |
| JH-30-4 | 26 lines naming rakun in the core's `src/` (`grep -rni rakun modules/jhonstart/src`): `router.bp:59,103,164,313,373,375,404`, `server.bp:23,34,49,50,115,116,187,307`, `streaming.bp:18`, `metadata.bp:12,34,35`, `client.bp:87`, `src/AGENTS.md:44,45,62`, sidecars `sidecars/jhonstart_server.erl:17,26` and `sidecars/jhonstart_router.erl:20` | core | 26 step 1 |
| JH-30-8a | a boundary resolving before the shell is written produces no hole and no fill — untested | core | 26 step 3 |
| JH-30-8b | sibling server components gathered by the render's own `__jhEachCompleted` (`streaming.bp:136,810,834`), not std `async.runAll`; no erlang timing test; no regression for an already-started `@Task` | core | 26 step 3 |
| JH-31-digest | `digestOf(message)` (`error_boundary.bp:77`) is `contentHash` (8 hex), on no log line. Decisions 194, 195: `digestOf` deleted; the boundary digests and logs through bundled `log` (landed) | core | 26 step 4 |
| JH-stage | dynamic mark written at run time (`markDynamic`: `router.bp:186,198,276`, `server.bp:87,254`, `streaming.bp:52,703`). Decision 186: stage is compile-time — `#[serverOnly]` / `#[clientOnly]` on the hooks, validated in `#[page]` / `#[client]` | core | 26 step 8 |
| JH-29-doc | `docs.md:371,393` say "front 23" for the payload envelope (jhonstart 30's since decision 117); 29-a's starter-table row; `islandAttr` wording | `docs.md` | 26 step 5 |
| JH-28-ex | `request-scope-example.bp` (escaping) and `blog-post-page-example.bp` (sequential awaits) break the README's own rules | `26/examples/` | 26 step 6 |
| PK-2 | the eight example members have no `README.md` | `examples/*/` | 26 step 6 |
| JH-SNAP | module-level snapshot layer (390) | every member's `test/` | `20-snap` step 3 |
| JH-27-3b | `reconcile(current, target)` has no driver: a shared layout's islands re-hydrate on every transition; route-kind flag unread | `jhonstart-link` | 27 step 1 |
| JH-27-4 | `use linkStatus()` inside a `fn … -> @Component<Element>` untested | `jhonstart-link` | 27 step 2 |
| JH-67-dom | five DOM-side forms boxes (1.0.10's 3a, 3b, 4, 5): `fieldError` after `__jhFormState`, `ok: false` envelope re-rendering in place, `pending` / `actionId` for two forms at once, optimistic commit and roll-back, `push` after the envelope | `jhonstart-forms` | 67 steps 1–3 |
| JH-49-4.6 | `__bp_action` / `X-Bp-Action` as literals — onze's defaults, spelled by neither library (decision 114): `jhonstart-forms/test/form_test.bp` (18 lines), `examples/forms/src/like.bp:23`, `examples/forms/src/main.bp:14`, `examples/forms/test/forms_test.bp:16,21,30,36`, four recorded `.snap` files under `examples/forms/test/__snapshots__/forms/` | `jhonstart-forms`, `examples/forms` | 67 step 4 |

## Fronts

| Front | Priority | State | What | Depends on |
|---|---|---|---|---|
| [`26-jhonstart-router/`](./26-jhonstart-router/README.md) | **high** — the boundary's digest is what `07-onze/49` step 3 completes; the rakun-free `src/` is a gate grep | not started | the core member: step 0 merges `jhonstart-html` into it (decision 200); one late-signal handler; no rakun in `src/`; the streaming tests; the digest and log line through `log` (194, 195); `docs.md`; the spec examples and eight READMEs; step 7 → `20-snap`; step 8 the stage markers (186) | `08-bpp/118` landed; `03-bundled-libs/102` step 3; `01-compiler/01-checker` (step 8); 29-a |
| [`27-jhonstart-link/`](./27-jhonstart-link/README.md) | medium | not started | the reconciler driver in `jhonstart-link`; `use linkStatus()` only in a `#[client]` component, `data-jh-pending` (363) | `04-rakun/22` (step 1 box 2 only) |
| [`67-jhonstart-forms/`](./67-jhonstart-forms/README.md) | medium-high — the forms are the write path of onze 53's proof | not started | the DOM-side boxes in `jhonstart-dom-test`; the wire-name literals gone | 26 (`fake_dom.mjs`); `03-bundled-libs/103` step 2; 67-a |

## Order

```
03-bundled-libs: 102 step 3 (routes.bp) · 103 step 2 (form.bp) ──► before 26 / 67 open (decision 188)
08-bpp/118 (in jhonstart-html, plus its carve-outs in the core) ──► before 26 opens (decision 189);
             26 step 0 then merges jhonstart-html into the core (decision 200)

26-jhonstart-router ──┐  (core member; 27 in parallel in jhonstart-link)
27-jhonstart-link ────┤
                      └──► 67-jhonstart-forms  (needs 26's fake_dom.mjs and 103's form.bp lines)

01-compiler/01-checker (the hooks a function activates, readable from its @Decl) ──► 26 step 8

outbound: 26 step 4 ──► 07-onze/49 step 3 sets the sink · 27 step 1 ──► 07-onze/50 step 6 adopts applyTransition
          26 step 8 ──► 07-onze/49 step 5 and 04-rakun/22 step 4 delete the run-time mark
inbound (08-bpp, after the owning front, one at a time): 116 · 120 · 122 in the core · 126 after 27 · 127 after 67 · 119: new member jhonstart-styled, deletes jhonstart-emilia, one arm in html.bp
```

## Ownership notes

Files per front, frozen files, `jhonstart-dom-test`'s rule and other tracks' edits:
[`modules.md`](./modules.md) § Front → files.

### Handed to this track by `08-bpp/118`

Lines 118 reports to the owner, not steps of 26, 27 or 67:

| Hand-off | Where | Decision |
|---|---|---|
| `Children` renamed `Node`: text, a number, a `bool`, a component of the same base, a list of them | `modules/jhonstart/src/element.bp` and every signature spelling `Children` | 193, 223 |
| a `(props, children)` component moves children into its props: the first parameter's type declares a `children` field, the second parameter goes | every component in `modules/jhonstart*/` and `examples/` | 193 |
| a component's attributes are the fields of its first parameter's type | components written as functions of labelled parameters | 192 |

118 also writes, as core carve-outs landed before 26 opens: its step-1 bracket-attribute lines (in
the core only comments of `root.bp` / `elements.bp` name the DSL), the core's `src/prelude.bp`
(imported by every `.bpp` file implicitly — decision 270), the `Node` declaration (decision 223) the
prelude imports; and rewrites its examples' `Children` to `Node`. The core's own `Children`
signatures stay the hand-off above.

## Decisions

Confirmations kept from 1.0.10 ([`../../1.0.10-beta/decisions-pending.md`](../../1.0.10-beta/decisions-pending.md) § Track C):

| Id | Choice | Closes |
|---|---|---|
| 26-a | every router cell is dual-target | — |
| 27-a → 363 | a browser-only cell is `#[clientOnly]`, no erlang twin; a server `Link` styled by `data-jh-pending` | 27 |
| 29-a | reduced (open, `decisions-pending.md`): the island starter table is `globals.starters`, filled per route by `registerRouteStarters(pattern, load)`; the per-name `registerStarter` goes — 281 builds the table at comptime (`@TypeInfo.all(with: client)`, `08-bpp/120` step 6, `07-onze/53` step 7) | 26 step 5's starter-table row |
| 30-b … 30-g | `RenderPlugin` as a record of async functions; `render` / `App` in `streaming.bp`, `compose` taking the page as a thunk (a page is `fn() -> View`, no `route` parameter — 293); `Suspense(b)` registers its `Boundary(id, fallback, child)` with the render (`child` the unstarted thunk); `UiSegment`; `app(…, lang:)`; the browser half in `jhonstart-dom-test` | — |
| 31-a | `notFound()` / `redirect(url)` raise through one host cell | — |

Module-level snapshot map: decision 390 (390), worked by [`20-snap`](../20-snap/README.md) step 3.

### 67-a · Where the DOM-side forms boxes are asserted

> **Raised by:** front 67, from its five DOM-side boxes (1.0.10's 3a, 3b, 4, 5).
> **Measured.** `fieldError` after `__jhFormState`, in-place re-render on `ok: false`, two forms'
> `pending`, optimistic commit / roll-back all read `document` and `FormData`; `botopink test` runs
> on node and the BEAM; `jhonstart-dom-test` (`fake_dom.mjs`, commonJS only — 30-g) covers the
> render's browser half; the forms' half has the same need. No browser before onze 53.
> **Options.** (a) extend `fake_dom.mjs` with `<form>` / `<input>` / `FormData` / `submit`, assert
> in `jhonstart-dom-test/test/forms_dom_test.bp` now and again in onze 53's browser; (b) onze 53's
> browser only (jhonstart's gate never runs them); (c) a real DOM library as a dev dependency.
> **Recommendation.** (a) — asserted in jhonstart's own gate against its writers' markup, no
> dependency; 53 proves them in a browser besides.
> **Blocks.** 67 steps 1–3's shape (acceptance written for (a)). Still open: the front already
> applies (a); only the record is missing (`decisions-pending.md` `67-a`).

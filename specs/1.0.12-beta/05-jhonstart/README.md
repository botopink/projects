# Track 05 — jhonstart

**Repo:** `repository/jhonstart` · **Reference:** Next.js docs, the React half · the tree on disk
is [`modules.md`](./modules.md).

jhonstart writes the HTML (decision 113): the render, the document, the payload, islands,
streaming, links, hydration, the client router, the navigation signals and the UI file
conventions. All of it exists and is green (`jhonstart` 204 tests on both rows, seven members,
eight example members, no `// LANGUAGE GAP` marker in the code). What is left is a tail of code
items and spec items, cut into three fronts by the member each edits.

## What jhonstart still owes

| Id | Item | Where | Front |
|---|---|---|---|
| JH-26-6 | the late-signal handler exists twice: `registerSignal` in `render.mjs:199` (`globals().signal`, its `replaceState` at `:213`) and `handleSignal` in `client_app.bp:219` | core | 26 step 2 |
| JH-30-4 | 26 lines naming rakun in the core's `src/` (`grep -rni rakun modules/jhonstart/src`): `router.bp:59,103,164,313,373,375,404`, `server.bp:23,34,49,50,115,116,187,307`, `streaming.bp:18`, `metadata.bp:12,34,35`, `client.bp:87`, `src/AGENTS.md:44,45,62`, and the sidecars `sidecars/jhonstart_server.erl:17,26` and `sidecars/jhonstart_router.erl:20` | core | 26 step 1 |
| JH-30-8a | a boundary that resolves before the shell is written produces no hole and no fill — untested | core | 26 step 3 |
| JH-30-8b | sibling server components are gathered by the render's own `__jhEachCompleted` (`streaming.bp:136,810,834`), not std `async.runAll`; no erlang timing test; no regression for an already-started `@Task` | core | 26 step 3 |
| JH-31-digest | `digestOf(message)` (`error_boundary.bp:77`) is `contentHash` (8 hex) and no log line carries it. Decisions 194, 195: `digestOf` is deleted; the boundary digests and logs through the bundled `log` (landed) | core | 26 step 4 |
| JH-stage | the dynamic mark is written at run time (`markDynamic`: `router.bp:186,198,276`, `server.bp:87,254`, `streaming.bp:52,703`). Decision 186: the stage is a compile-time fact — `#[serverOnly]` / `#[clientOnly]` on the hooks, validated in `#[page]` / `#[client]` | core | 26 step 8 |
| JH-29-doc | `docs.md:371,393` say "front 23" for the payload envelope (jhonstart 30's since decision 117); the starter-table row of 29-a; the `islandAttr` wording | `docs.md` | 26 step 5 |
| JH-28-ex | `request-scope-example.bp` (escaping) and `blog-post-page-example.bp` (sequential awaits) break the README's own rules | `26/examples/` | 26 step 6 |
| PK-2 | the eight example members have no `README.md` | `examples/*/` | 26 step 6 |
| JH-SNAP | the module-level snapshot map (`26/test-snap.md`) has no `.snap` files | every member's `test/` | 26 step 7, on 30-h |
| JH-27-3b | the reconciler decision `reconcile(current, target)` has no driver: a shared layout's islands are re-hydrated on every transition; the route-kind flag is not read | `jhonstart-link` | 27 step 1 |
| JH-27-4 | `use linkStatus()` inside a `fn … -> @Component<ElementBase, Element>` is not tested | `jhonstart-link` | 27 step 2 |
| JH-67-dom | the five DOM-side forms boxes (1.0.10's 3a, 3b, 4, 5): `fieldError` after `__jhFormState`, an `ok: false` envelope re-rendering in place, `pending` / `actionId` for two forms at once, optimistic commit and roll-back, `push` after the envelope | `jhonstart-forms` | 67 steps 1–3 |
| JH-49-4.6 | `__bp_action` / `X-Bp-Action` spelled as literals — onze's defaults, which neither library spells (decision 114): `jhonstart-forms/test/form_test.bp` (18 lines), `examples/forms/src/like.bp:23`, `examples/forms/src/main.bp:14`, `examples/forms/test/forms_test.bp:16,21,30,36` and four recorded `.snap` files under `examples/forms/test/__snapshots__/forms/` | `jhonstart-forms`, `examples/forms` | 67 step 4 |

## Fronts

| Front | Priority | State | What | Depends on |
|---|---|---|---|---|
| [`26-jhonstart-router/`](./26-jhonstart-router/README.md) | **high** — the boundary's digest is what `07-onze/49` step 3 completes; the rakun-free `src/` is a gate grep | not started | the core member: step 0 merges `jhonstart-html` into it (decision 200); one late-signal handler; no rakun in `src/`; the streaming tests; the digest and log line through `log` (194, 195); `docs.md`; the spec examples and eight READMEs; step 7 the snapshot map (on 30-h); step 8 the stage markers (186) | `08-bpp/118` landed; `03-bundled-libs/102` step 3; `01-compiler/01-checker` (step 8); 30-h, 29-a |
| [`27-jhonstart-link/`](./27-jhonstart-link/README.md) | medium | not started | the reconciler driver in `jhonstart-link`; the `use linkStatus()` test | `04-rakun/22` (step 1 box 2 only); 27-a |
| [`67-jhonstart-forms/`](./67-jhonstart-forms/README.md) | medium-high — the forms are the write path of onze 53's proof | not started | the DOM-side boxes in `jhonstart-dom-test`; the wire-name literals gone | 26 (`fake_dom.mjs`); `03-bundled-libs/103` step 2; 67-a |

## Order

```
03-bundled-libs: 102 step 3 (routes.bp) · 103 step 2 (form.bp) ──► before 26 / 67 open (decision 188)
08-bpp/118 (in jhonstart-html, plus its carve-outs in the core) ──► before 26 opens (decision 189);
             26 step 0 then merges jhonstart-html into the core (decision 200)

26-jhonstart-router ──┐  (core member; 27 in parallel in jhonstart-link)
27-jhonstart-link ────┤
                      └──► 67-jhonstart-forms  (needs 26's fake_dom.mjs and 103's form.bp lines)
                                  └──► 26 step 7 (on 30-h (b): re-records every member's test/ — runs alone, last)

01-compiler/01-checker (the hooks a function activates, readable from its @Decl) ──► 26 step 8

outbound: 26 step 4 ──► 07-onze/49 step 3 sets the sink · 27 step 1 ──► 07-onze/50 step 6 adopts applyTransition
          26 step 8 ──► 07-onze/49 step 5 and 04-rakun/22 step 4 delete the run-time mark
inbound (08-bpp, after the owning front, one at a time): 116 · 120 · 122 in the core · 126 after 27 · 127 after 67 · 119 in jhonstart-emilia
```

## Ownership notes

- `modules/jhonstart-dom-test` is 26's. A front that needs the fake document adds a test file of
  its own there and owns it (67, and `08-bpp`'s 119, 120, 126, 127); `fake_dom.mjs` stays 26's
  and is edited by one front at a time after 26 has landed (decision 189).
- Frozen, edited by no front of this track: `element.bp`, `hooks.bp`. `html_attrs.bp` is
  emilia-facing (front 48's, closed). `routes.bp`'s segment walk in `page` (`:233-251`) is
  `03-bundled-libs/102`'s; `render.bp:539` `isLangTag` is `105-i18n`'s; `form.bp:117-121`
  (`formAction`'s id check) is `103-actions-id`'s.

### Handed to this track by `08-bpp/118`

Lines 118 reports to the owner, not steps of 26, 27 or 67:

| Hand-off | Where | Decision |
|---|---|---|
| the type jhonstart calls `Children` is renamed `Node`: text, a number, a `bool`, a component of the same base, a list of them | `modules/jhonstart/src/element.bp` and every signature that spells `Children` | 193, 223 |
| a component that takes `(props, children)` moves the children into its props: the first parameter's type declares a `children` field, the second parameter goes | every component in `modules/jhonstart*/` and `examples/` | 193 |
| a component's attributes are the fields of its first parameter's type | the components written as functions of labelled parameters | 192 |

118 also writes, as carve-outs in the core landed before 26 opens: its step-1 bracket-attribute
lines (in the core only comments of `root.bp` / `elements.bp` name the DSL), the core's `src/prelude.bp` (what every `.bpp` file imports
without writing it — decision 266) and the type `Children` the track's examples use.

## Decisions

Confirmations kept from 1.0.10 ([`../../1.0.10-beta/decisions-pending.md`](../../1.0.10-beta/decisions-pending.md) § Track C):

| Id | Choice | Closes |
|---|---|---|
| 26-a | every router cell is dual-target | — |
| 26-b | the query is reachable only through a marking hook; the payload's `d` is the mark | superseded by decision 186 once 26 step 8 lands; until then `d` stays the mark |
| 27-a | a browser cell in a two-target member is dual-target, the erlang twin answering the server's truth | — |
| 29-a | the island starter table is `globals.starters`, filled by `registerStarter` / `registerRouteStarters` | 26 step 5's starter-table row |
| 30-b … 30-g | `RenderPlugin` as a record of async functions; `render` / `App` in `streaming.bp`; `Suspense` registers with the render; `UiSegment`; `app(…, lang:)`; the browser half in `jhonstart-dom-test` | — |
| 31-a | `notFound()` / `redirect(url)` raise through one host cell | — |

### 30-h · The module-level snapshot map of `test-snap.md` — realise or retire

> **Raised by:** this track, from [`26-jhonstart-router/test-snap.md`](./26-jhonstart-router/test-snap.md).
> **Measured.** The map names one `.snap` per case for every member's `test/` (`elements_test`,
> `router_test`, `link_test`, `reconcile_test`, `server_test`, `client_test`, `streaming_test`,
> `render_test`, `bridge_test`, `error_boundary_test`, `metadata_test`, `form_test`). None exists.
> What exists: every case asserts its literal inline on both rows (204 tests in the core);
> `jhonstart-test`'s `helpers_test.bp` (20 tests, 7 accepted snapshots); the example projects hold
> 32 snapshots through those helpers; the two contracts another library reads — the payload keys
> (`contracts.md` § 2) and the contract-4 class literal `e_39b87d03` — are asserted by
> `render_test`'s literal, `bridge_test.bp` and onze's `build_test.bp:104`.
> **Options.** (a) retire the map: the inline literals, the helper snapshots and the example
> snapshots are the evidence; (b) realise it: ~150 `.snap` files under `modules/*/test/__snapshots__/`,
> each a second copy of a literal the inline test already pins, re-recorded together on any
> change to the render.
> **Recommendation.** (a). A module-level snapshot is realised only where it proves a contract
> another library reads, and both such contracts already have a snapshot or a literal on the
> reading side.
> **Blocks.** 26 step 7.

### 67-a · Where the DOM-side forms boxes are asserted

> **Raised by:** front 67, from its five DOM-side boxes (1.0.10's 3a, 3b, 4, 5).
> **Measured.** `fieldError` after `__jhFormState`, the in-place re-render on `ok: false`, two
> forms' `pending`, and optimistic commit / roll-back all read `document` and `FormData`; `botopink
> test` runs on node and on the BEAM; `jhonstart-dom-test` (`fake_dom.mjs`, commonJS only — 30-g)
> covers the render's browser half, and the forms' browser half has the same need. No browser is
> in the loop before onze 53.
> **Options.** (a) extend `fake_dom.mjs` with `<form>` / `<input>` / `FormData` / `submit` and
> assert the boxes in `jhonstart-dom-test/test/forms_dom_test.bp` now, and again in onze 53's
> browser; (b) leave them to onze 53's browser only (jhonstart's own gate never runs them);
> (c) a real DOM library as a dev dependency.
> **Recommendation.** (a) — the boxes are asserted in jhonstart's own gate against the markup
> its writers produce, with no dependency; 53 proves them in a browser besides.
> **Blocks.** 67 steps 1–3's shape (their acceptance is written for (a)).

# Track 04 — jhonstart

**Repo:** `repository/jhonstart` · **Reference:** Next.js docs, the React half · **Carried from:**
`specs/1.0.10-beta/04-jhonstart/` (nine fronts: 26–32 · 67 · 94) — the mapping is
[`carried.md`](./carried.md); the tree as it is on disk is [`modules.md`](./modules.md).

jhonstart writes the HTML (decision 113): the render, the document, the payload, islands,
streaming, links, hydration, the client router, the navigation signals end to end and the UI file
conventions. 1.0.10 landed all nine fronts — `jhonstart` 204 / 204 on both rows, seven members,
eight example members, no known red, no `// LANGUAGE GAP` marker in the code. What is left is a
tail of eleven code items and a spec tail, cut here into three fronts by the member each edits.

## What jhonstart still owes

| Id | Item | Where | Front |
|---|---|---|---|
| JH-26-6 | the late-signal handler exists twice — `render.mjs:194-208` (`globals().signal`) and `client_app.bp:177-193` (`handleSignal`) | core | 26 |
| JH-30-4 | comments naming rakun in the core's `src/` (`router.bp:59,104,165,314,374,376,405`, `server.bp:23,34,49,50,115,116,187,305`, `streaming.bp:18`, `metadata.bp:12,34,35`, `client.bp:86`, `src/AGENTS.md:45,62`); front 30's box "`grep -rn rakun modules/jhonstart/src` is empty" | core | 26 |
| JH-30-8a | a boundary that resolves before the shell is written produces no hole and no fill — untested | core | 26 |
| JH-30-8b | sibling server components are gathered by the render's own `__jhEachCompleted`, not std `async.runAll`; no erlang timing test (two 50 ms loaders in under 100 ms); no regression for an already-started `@Task` | core | 26 |
| JH-31-digest | `digestOf(message)` is `contentHash` (8 hex); rakun-logging's `errorDigest` is 16 hex of `strongHash` over four parts; no log line carries the digest a fallback shows — decision 31-b | core (`error_boundary.bp:77`, `streaming.bp` `app`) | 26 |
| JH-29-doc | `docs.md` says "front 23" where it means 30 (`docs.md:371,393` name rakun's 23 — the payload envelope is jhonstart 30's since decision 117); the starter-table row of 29-a; the `islandAttr` DoD wording | `docs.md` | 26 |
| JH-28-ex | the spec examples `request-scope-example.bp` (escaping) and `blog-post-page-example.bp` (sequential awaits) do not follow the README's own rules | spec (copied to `26/examples/`) | 26 |
| JH-27-3b | the client-navigation reconciler `reconcile(current, target)` has no driver: a shared layout's islands are re-hydrated across a transition; the route-kind flag is not read; the DoD box that claims it is ticked wrongly | `jhonstart-link` | 27 |
| JH-27-4 | `use linkStatus()` inside a `fn … -> @Component<ElementBase, Element>` is not tested | `jhonstart-link` | 27 |
| JH-67-3a/3b/4/5 | the DOM-side forms boxes: `fieldError` after `__jhFormState`, an `ok: false` envelope re-rendering in place, `pending` / `actionId` for two forms at once, optimistic commit and roll-back, `push` after the envelope | `jhonstart-forms` | 67 |
| JH-49-4.6 | `__bp_action` / `X-Bp-Action` spelled as literals in `jhonstart-forms/test/form_test.bp` and `examples/forms/src/like.bp:23` — onze's defaults, which neither library spells (decision 114) | `jhonstart-forms`, `examples/forms` | 67 |
| JH-SNAP | the module-level snapshot map (`test-snap.md` §§ 94–67) does not exist as `.snap` files | every member's `test/` | 26 step 7, conditional on 30-h |
| PK-2 | eight example members without `README.md` | `examples/*/` | 26 |

Not carried as work: the "handed to front 94" boxes of every front (`pub mod` lines and `files`
entries — true on disk, closed on tick), the four compiler repros (closed in the compiler), and
the stale gap rows `carried.md` lists.

## Fronts

| Front | Priority | Carries | Parallel group | What |
|---|---|---|---|---|
| [`26-jhonstart-router/`](./26-jhonstart-router/README.md) | **high** — 31-b's `onError` is what onze 49 wires, and the rakun-free `src/` is a gate grep | 28 · 29 · 30 · 31 (+ 94's tick) | A | the core member: one late-signal handler, no rakun in `src/`, the streaming tests, the error digest through `RenderHooks.onError`, `docs.md`, the spec examples, the eight READMEs; step 7 the snapshot map (conditional) |
| [`27-jhonstart-link/`](./27-jhonstart-link/README.md) | medium — blocked on onze 68's DOM primitives and rakun 60's route-kind flag | — | A (file-disjoint from 26) | the reconciler driver in `jhonstart-link`; the `use linkStatus()` test |
| [`67-jhonstart-forms/`](./67-jhonstart-forms/README.md) | medium-high — the forms are the write path of onze 53's proof | — | B (after 26 for `fake_dom.mjs`; after `07-bundled-libs/103-actions-id` for `form.bp:117-121`) | the DOM-side boxes asserted in `jhonstart-dom-test`; the wire-name literals gone |

## Order

```
97-std-dedupe (track 02) ─── nothing here waits on it (jhonstart holds no std copy)

26-jhonstart-router ──┐  (A: core member; 27 in parallel — jhonstart-link)
27-jhonstart-link ────┤
                      └──► 67-jhonstart-forms  (B: needs 26's fake_dom.mjs and 103-actions-id's form.bp lines)
                                  │
                                  └──► 26 step 7 (conditional, 30-h: re-records every member's test/ — runs alone, last)

outbound: 26 step 4 (onError) ──► 06-onze/49 step 3 wires it · 27 ◄── 06-onze/50 (68's DOM primitives) · rakun 22-front (60's route kind)
```

26 is first because its `RenderHooks.onError` is the seam onze 49 and the `07-f` decision (a
bundled `log`, or only 31-b (a)) both wait on, and because the gate's `grep -rn rakun
modules/jhonstart/src` is a box of its own. 27 runs beside it in another member. 67 waits: its
DOM boxes need the minimal document 26 extends, and its `form.bp:117-121` is `103-actions-id`'s.

## Handed to 00-gate

| Item | File | Fix |
|---|---|---|
| JH-LEDGER — two stale ledger lines: `jhonstart-counter erlang 0` and `jhonstart-todo erlang 0` (`restricted-targets.txt:53-54`; both reasons say "the restriction outlived its reason") | `repository/botopink-lang/scripts/restricted-targets.txt:53-54`; `repository/jhonstart/examples/jhonstart-counter/botopink.json` and `jhonstart-todo/botopink.json` (`"targets": ["commonJS"]`) | delete `targets` from the two manifests (both rows inherit the workspace's two) and the two lines, in the same gate run |
| JH-LEDGER — `jhonstart-dom-test erlang 1` (`:55`) is a tolerated red by construction (30-g: there is no DOM on the BEAM) | `restricted-targets.txt:55`; `repository/jhonstart/modules/jhonstart-dom-test/test/dom_test.bp` | the gate's rule for a restricted cell decides: either the erlang row of `dom_test.bp` asserts the erlang twins' empty answers (count 0, line stays with `0`) or the ledger stops pinning a failing count; both are the gate track's call — 26 does not touch the member's `targets` |
| PK-5 — `botopink format --check` drift in `modules/jhonstart` and `modules/jhonstart-link` | those two trees | reformat in one commit (decision 132's refusal waits on it) |
| STD-1 — no `*.snap.new` guard | `repository/jhonstart/.gitignore`, `scripts/git-hooks/pre-commit` | the `02-std-and-packaging` track's row |
| the spec markers — `67-jhonstart-forms` DoD "every `// LANGUAGE GAP:` marker in the three example files appears in the table" | `specs/1.0.10-beta/04-jhonstart/67-jhonstart-forms/examples/*.bp` (frozen) | the gate's marker grep excludes `specs/1.0.10-beta/**`; the copies under `67/examples/` here carry no marker (measured: `grep -c 'LANGUAGE GAP'` is 0 in both) |

## Maintainer decisions

Ids kept from 1.0.10 (`specs/1.0.10-beta/decisions-pending.md` § Track C); new questions continue
the per-front letter sequence. Numbered decisions continue from 144 when answered.

### To confirm

| Id | Choice | Closes |
|---|---|---|
| 26-a | every router cell is dual-target | — |
| 26-b | the query is reachable only through a marking hook; the payload's `d` is the mark | rakun's half is `06-onze` 49-f |
| 27-a | a browser cell in a two-target member is dual-target, the erlang twin answering the server's truth | — |
| 29-a | the island starter table is `globals.starters`, filled by `registerStarter` / `registerRouteStarters` | 26 step 5's starter-table row in `docs.md` |
| 30-b … 30-g | `RenderPlugin` as a record of async functions; `render` / `App` in `streaming.bp`; `Suspense` registers with the render; `UiSegment`; `app(…, lang:)`; the browser half in `jhonstart-dom-test` | — |
| 31-a | `notFound()` / `redirect(url)` raise through one host cell | — |

### To answer

**31-b · the error digest — one scheme, and the render's way to the logger.** Open since 1.0.10;
the question and its options stand as written there. **Recommendation (a)**: `app(…)` /
`RenderHooks` gains `onError: fn(message: string) -> string`, the default `contentHash(message)`,
onze sets it to rakun-logging's `logErrorWithDigest`. Front 26 step 4 implements (a); the
`07-bundled-libs` question `07-f` (a bundled `log` instead) is the alternative and, if chosen,
`106-log` lands after 26 and replaces the default only. **Blocks:** 26 step 4; onze 49 step 3.

### 30-h · The module-level snapshot map of `test-snap.md` §§ 94–67 — realise or retire

> **Raised by:** this track, from `test-snap.md` (copied to `26-jhonstart-router/test-snap.md`)
> **Measured.** The map names one `.snap` per case for every member's `test/` (`elements_test`,
> `router_test`, `link_test`, `reconcile_test`, `server_test`, `client_test`, `streaming_test`,
> `render_test`, `bridge_test`, `error_boundary_test`, `metadata_test`, `form_test`). None exists.
> What exists: every case asserts its literal inline on both rows (204 tests); `jhonstart-test`'s
> eleven helpers each have a `helpers_test.bp` case with one accepted snapshot per family (21
> tests); the five example projects hold 32 snapshots through those helpers; the two contracts
> another library reads — the payload keys (`contracts.md § 2`) and the contract-4 class literal
> `e_39b87d03` — are asserted by `render_test`'s literal, `bridge_test.bp` and onze's
> `build_test.bp:104`.
> **Options.** (a) retire the map: the inline literals, the helper snapshots and the example
> snapshots are the evidence; (b) realise it: ~150 `.snap` files under `modules/*/test/__snapshots__/`,
> each a second copy of a literal the inline test already pins, re-recorded together on any
> change to the render.
> **Recommendation.** (a). A module-level snapshot is realised only where it proves a contract
> another library reads, and both such contracts already have a snapshot or a literal on the
> reading side.
> **Blocks.** 26 step 7 (conditional).

### 67-a · Where the DOM-side forms boxes are asserted

> **Raised by:** front 67, from its four open DOM boxes (3a, 3b, 4, 5)
> **Measured.** `fieldError` after `__jhFormState`, the in-place re-render on `ok: false`, two
> forms' `pending`, and optimistic commit / roll-back all read `document` and `FormData`; `botopink
> test` runs on node and on the BEAM; 30-g built `jhonstart-dom-test` (`fake_dom.mjs`, commonJS
> only) for the render's browser half, and the forms' browser half has the same need. No browser is
> in the loop before onze 53.
> **Options.** (a) extend `fake_dom.mjs` with `<form>` / `<input>` / `FormData` / `submit` and
> assert the four boxes in `jhonstart-dom-test/test/forms_dom_test.bp` now, and again in onze 53's
> browser; (b) leave the four boxes to onze 53's browser only (jhonstart's own gate never runs
> them); (c) a real DOM library as a dev dependency.
> **Recommendation.** (a) — the most restrictive: the boxes are asserted in jhonstart's own gate
> against the markup its writers produce, with no dependency; 53 proves them in a browser besides.
> **Blocks.** 67 steps 1–3's shape (their acceptance is written for (a)).

# Track 05 — jhonstart

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
| JH-31-digest | `digestOf(message)` is `contentHash` (8 hex); rakun-logging's `errorDigest` is 16 hex of `strongHash` over four parts; no log line carries the digest a fallback shows. Decisions 194 and 195: `digestOf` is deleted, and the boundary digests and logs through the bundled `log` (`03-bundled-libs/106`) | core (`error_boundary.bp:77`) | 26 step 4, after 106's package |
| JH-stage | the dynamic mark is written at run time (`markDynamic` in `router.bp`). Decision 186: the stage a page renders in is a compile-time fact — the library defines `#[serverOnly]` and `#[clientOnly]`, marks its hooks, validates in `#[page]` / `#[client]`, and `markDynamic` goes | core (`router.bp`, `routes.bp`, `client.bp`, the hooks) | 26 step 8, on the checker capability (`language-gaps.md`) |
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
| [`26-jhonstart-router/`](./26-jhonstart-router/README.md) | **high** — the boundary's digest through `log` is what onze 49 step 3 completes, and the rakun-free `src/` is a gate grep | 28 · 29 · 30 · 31 (+ 94's tick) | A | the core member: step 0 merges `jhonstart-html` into it and makes `html` its default function (decision 200); one late-signal handler, no rakun in `src/`, the streaming tests, the error digest and log line through the bundled `log` (decisions 194, 195), `docs.md`, the spec examples, the eight READMEs; step 7 the snapshot map (conditional); step 8 the two stage markers (decision 186) |
| [`27-jhonstart-link/`](./27-jhonstart-link/README.md) | medium — one box waits on the route-kind flag the build writes (rakun 22) | — | A (file-disjoint from 26; no dependency on onze 50 — decision 189) | the reconciler driver in `jhonstart-link`; the `use linkStatus()` test |
| [`67-jhonstart-forms/`](./67-jhonstart-forms/README.md) | medium-high — the forms are the write path of onze 53's proof | — | B (after 26 for `fake_dom.mjs`; after `03-bundled-libs/103-actions-id` for `form.bp:117-121`) | the DOM-side boxes asserted in `jhonstart-dom-test`; the wire-name literals gone |

## Order

```
97-std-dedupe (track 02) ─── nothing here waits on it (jhonstart holds no std copy)

03-bundled-libs: 102 step 3 (routes.bp) · 103 step 2 (form.bp) ──► before 26 and 67 open (decision 188)
08-bpp/118, landed in jhonstart-html (with step 1's carve-out in the core) ──► before 26 opens (decision 189);
             26 step 0 then merges jhonstart-html into the core (decision 200)
03-bundled-libs/106 package (`log`) ──► 26 step 4

26-jhonstart-router ──┐  (A: core member; 27 in parallel — jhonstart-link)
27-jhonstart-link ────┤
                      └──► 67-jhonstart-forms  (B: needs 26's fake_dom.mjs and 103-actions-id's form.bp lines)
                                  │
                                  └──► 26 step 7 (conditional, 30-h: re-records every member's test/ — runs alone, last)

01-compiler/01-checker (the hooks a function activates, readable from its @Decl) ──► 26 step 8

outbound: 26 step 4 (the digest through log) ──► 07-onze/49 step 3 sets the sink · 27 step 1 ──► 07-onze/50 step 6 adopts applyTransition
          26 step 8 (the stage markers) ──► 07-onze/49 step 5 and 04-rakun/22 step 4 delete the run-time mark
inbound, after the front that owns the member (08-bpp): 116 · 120 · 122 in the core, one at a time · 126 after 27 · 127 after 67 · 119 in jhonstart-emilia
```

26 is first because the boundary's digest is what onze 49 step 3 completes, and because the
gate's `grep -rn rakun modules/jhonstart/src` is a box of its own. 27 runs beside it in another
member. 67 waits: its DOM boxes need the minimal document 26 extends, and its `form.bp:117-121`
is `103-actions-id`'s.

`modules/jhonstart-dom-test` is 26's. A front that needs the fake document adds a test file of
its own there and owns it (67, and `08-bpp`'s 119, 120, 126, 127); `fake_dom.mjs` stays 26's and
is edited by one front at a time after 26 has landed (decision 189).

### Handed to this track by `08-bpp/118`

Decisions 191–193 fix what a template of `jhonstart-html` accepts, and two of their consequences
land in members this track owns. They are hand-offs — lines 118 reports to the owner — not steps
of 26, 27 or 67:

| Hand-off | Where | Decision |
|---|---|---|
| the type jhonstart calls `Children` is renamed `JhonstartNode` — the node type: text, a number, a `bool`, a component of the same base, a list of them | `modules/jhonstart/src/element.bp` and every signature that spells `Children` | 193 |
| a component that takes `(props, children)` moves the children into its props: the first parameter's type declares a `children` field, and the second parameter goes away | every component in `modules/jhonstart*/` and `examples/` | 193 |
| a component's attributes are the fields of its first parameter's type | the components written as functions of labelled parameters | 192 |

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
the per-front letter sequence. Numbered decisions continue from 214 when answered.

### To confirm

| Id | Choice | Closes |
|---|---|---|
| 26-a | every router cell is dual-target | — |
| 26-b | the query is reachable only through a marking hook; the payload's `d` is the mark | superseded by decision 186 once 26 step 8 lands: the hook is `#[serverOnly]` and the page's stage is known at compile time, so nothing is marked at run time; until then `d` stays the mark |
| 27-a | a browser cell in a two-target member is dual-target, the erlang twin answering the server's truth | — |
| 29-a | the island starter table is `globals.starters`, filled by `registerStarter` / `registerRouteStarters` | 26 step 5's starter-table row in `docs.md` |
| 30-b … 30-g | `RenderPlugin` as a record of async functions; `render` / `App` in `streaming.bp`; `Suspense` registers with the render; `UiSegment`; `app(…, lang:)`; the browser half in `jhonstart-dom-test` | — |
| 31-a | `notFound()` / `redirect(url)` raise through one host cell | — |

### Answered

| Id | Decision | What the fronts implement |
|---|---|---|
| 31-b | 194 | one digest scheme with one implementation, `errorDigest` in the bundled `log`; `digestOf` is deleted (26 step 4) |
| 07-f (`03-bundled-libs`) | 195 | the bundled `log` exists and the boundary logs through it; `RenderHooks.onError` is not added (26 step 4) |
| 49-f (`07-onze`) / 03r-ai (`04-rakun`) | 186 | the stage a page renders in is a compile-time fact; jhonstart defines `#[serverOnly]` and `#[clientOnly]` (26 step 8) |
| what a template accepts | 190 – 193 | `08-bpp/118`; the hand-offs above |

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

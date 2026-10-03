# Front 27 — jhonstart link: the reconciler driver

**Priority:** medium — a shared layout's islands are re-hydrated on every client transition; a
correctness gap in the browser only, unobservable in the gate until a DOM primitive exists ·
**State:** not started
**Depends on:** nothing for step 1's first box, step 2 and step 3 — the driver is pure over a
record of four functions the entry supplies, so it does not wait on `07-onze/50` (50 step 6
depends on this front — decision 189) · `04-rakun/22-rakun-file-routing` for step 1's second box:
the route-kind flag in the payload's `k` blob, written by the build (decision 186) and read
through `routing.routeKindOf` · `27-a` confirmed (the erlang twins' shape) · `05-jhonstart/26` step 2 only if the driver needs the
signal path (it should not)
**Owns:** `repository/jhonstart/modules/jhonstart-link/**` (`link.bp`, `link_runtime.mjs`,
`sidecars/jhonstart_link.erl`, `reconcile.bp`, `test/**`, `AGENTS.md`) ·
`modules/jhonstart-test/src/assert_link.bp` · this directory
**Does not touch:** `modules/jhonstart/**` (26) · `modules/jhonstart-forms/**` (67; it imports
`linkPrefetch` from here — additive changes only) · `modules/jhonstart-dom-test/**` (26; a driver
test needing the minimal document is written as a case 26 accepts, or the front stops and
reports) · after this front has landed: `transitions.bp`, `sidecars/transitions_runtime.mjs` and
two call sites of `link_runtime.mjs` (`08-bpp/126`)

## Goal

`reconcile.bp` computes the pure decision (`layoutKeys`, `sharedDepth`, the remounted depth —
`simulateNavigation` in `jhonstart-test/harness.bp:93` exercises it) but nothing applies it:
after a client navigation the entry re-hydrates every island of the new document, so a stateful
island above the changed segment loses its state. When this front lands, a driver applies the
decision (only the changed subtree is replaced and its islands started), and `use linkStatus()`
is tested under a `@Component` return. `jhonstart-link` has 38 tests today (`link_test` 28,
`reconcile_test` 10); `reconcile.bp:24-44` explains why the driver is not there yet — that
comment goes with step 1.

## Mechanism

A transition is `RouterState` → `RouterState`; `reconcile(current, target)` answers which depth
remounts. The driver takes that depth and (1) replaces only the subtree from that depth down
(`replaceChildren` on the segment root the render marks), (2) starts islands only for the new
subtree (the starters of 29-a, per route through `registerRouteStarters`), (3) leaves the islands
above untouched — their mount count is the observable. Whether the target payload had to be
fetched is the route-kind flag `04-rakun/22` writes (static → the document is cacheable, the
payload was prefetched), read through `routing.routeKindOf`, not recomputed. `DomOps` as a record
keeps the member free of a DOM and of `jhonstart-dom-test`; the browser proof is onze 53's "Link
navigation between `/blog` and `/blog/<slug>` does not re-request the document".

## Open

### Step 1 — the driver

`reconcile.bp` gains `applyTransition(current, target, dom: DomOps) -> Navigation` where `DomOps`
is a record of the four functions the entry supplies (`replaceSubtree(depth, html)`,
`startIslands(depth)`, `mountCount(name)`, `scrollTo`), so the driver is pure over a record and
testable without a document. Additive: the entry (`07-onze/50` step 6) adopts it in its own step.

- [ ] `reconcile_test.bp`: over a recording `DomOps`, a transition `/blog` → `/blog/x` sharing the
      root layout calls `replaceSubtree(1, …)` once and `startIslands(1)` once; `mountCount("Nav")`
      stays at 1 — the island whose mount count is observable
- [ ] a transition to a route of a different kind (the `k` flag differs) reads the flag from the
      target payload through `routing.routeKindOf`; `grep -n "kindOf\|routeKind" reconcile.bp`
      shows one call and no recomputation (until `04-rakun/22`'s flag is in the payload this box
      waits; the driver reads `k` as the router already does)
- [ ] 1.0.10's DoD box "the reconciler decides remount vs re-render" is re-ticked only when the
      two cases above are green on both rows (the erlang twin answers "no transition")

### Step 2 — `use linkStatus()` under a `@Component` return

- [ ] `link_test.bp`: a `fn Pending() -> @Component<ElementBase, Element>` body with
      `val s = use linkStatus();` renders; a twin without the `@Component` return is a
      `use-without-context-effect` fixture under `refusals/` (decisions 118 and 128)

### Step 3 — the example

[`examples/post-list-links-example.bp`](./examples/post-list-links-example.bp) shows
`prefetchMode` per route kind and the checkout link's pending state (`examples/src/**/*.bpp` show
the same page as `.bpp` files); it is corrected here if step 1 changes the surface it uses.

- [ ] `botopink check` over the example against `modules/jhonstart-link` passes

**Gate:** standard (fronts.md § Gate) + `jhonstart-link` 38 or more on both rows;
`jhonstart-forms` and `jhonstart-test` unchanged

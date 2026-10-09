# Front 27 — jhonstart link: the reconciler driver

**Priority:** medium — a shared layout's islands re-hydrate on every client transition; browser-only
correctness gap, unobservable in the gate until a DOM primitive exists · **State:** not started
**Depends on:** nothing for step 1 box 1, steps 2 and 3 — the driver is pure over a record of four
entry-supplied functions, so no wait on `07-onze/50` (50 step 6 depends on this front — decision
189) · `04-rakun/22-rakun-file-routing` for step 1 box 2: the route-kind flag in the payload's `k`
blob, build-written (decision 186), read through `routing.routeKindOf` · decision 363 (a browser-only cell is
`#[clientOnly]`, no erlang twin) · `05-jhonstart/26` step 2 only if the driver needs the signal path (it should not)
**Owns:** `repository/jhonstart/modules/jhonstart-link/**` (`link.bp`, `link_runtime.mjs`,
`sidecars/jhonstart_link.erl` (deleted, 363), `reconcile.bp`, `test/**`, `AGENTS.md`) ·
`modules/jhonstart-test/src/assert_link.bp` · this directory
**Does not touch:** `modules/jhonstart/**` (26) · `modules/jhonstart-forms/**` (67; imports
`linkPrefetch` from here — additive changes only) · `modules/jhonstart-dom-test/**` (26; a driver
test needing the minimal document is a case 26 accepts, or stop and report) · after landing:
`transitions.bp`, `sidecars/transitions_runtime.mjs`, two call sites of `link_runtime.mjs`
(`08-bpp/126`)

## Goal

`reconcile.bp` computes the pure decision (`layoutKeys`, `sharedDepth`, remounted depth —
exercised by `simulateNavigation` in `jhonstart-test/harness.bp:93`) but nothing applies it: after a
client navigation the entry re-hydrates every island, so a stateful island above the changed segment
loses state. After: a driver applies the decision (only the changed subtree replaced, its islands
started), and `use linkStatus()` is tested under a `@Component` return. `jhonstart-link` has 38
tests (`link_test` 28, `reconcile_test` 10); `reconcile.bp:24-44`'s comment on the missing driver
goes with step 1.

## Mechanism

Transition: `RouterState` → `RouterState`; `reconcile(current, target)` answers the remounting
depth. The driver (1) replaces only the subtree from that depth (`replaceChildren` on the segment
root the render marks), (2) starts islands only for the new subtree (29-a's starters, per route via
`registerRouteStarters`), (3) leaves islands above untouched — their mount count is the observable.
Whether the target payload had to be fetched = `04-rakun/22`'s route-kind flag (static → cacheable
document, payload prefetched), read through `routing.routeKindOf`, not recomputed. `DomOps` as a
record keeps the member free of a DOM and of `jhonstart-dom-test`; browser proof is onze 53's "Link
navigation between `/blog` and `/blog/<slug>` does not re-request the document".

## Open

### Step 1 — the driver

`reconcile.bp` gains `applyTransition(current, target, dom: DomOps) -> Navigation`; `DomOps` is a
record of the entry's four functions (`replaceSubtree(depth, html)`, `startIslands(depth)`,
`mountCount(name)`, `scrollTo`) — pure, testable without a document. Additive: the entry
(`07-onze/50` step 6) adopts it in its own step.

- [ ] `reconcile_test.bp`: over a recording `DomOps`, `/blog` → `/blog/x` sharing the root layout
      calls `replaceSubtree(1, …)` once and `startIslands(1)` once; `mountCount("Nav")` stays at 1
- [ ] a transition to a route of a different kind (`k` flag differs) reads the flag from the target
      payload through `routing.routeKindOf`; `grep -n "kindOf\|routeKind" reconcile.bp` shows one
      call, no recomputation (waits until `04-rakun/22`'s flag is in the payload; the driver reads
      `k` as the router already does)
- [ ] 1.0.10's DoD box "the reconciler decides remount vs re-render" re-ticked only when both cases
      above are green on both rows (the driver is pure; no erlang twin — 363)
- [ ] `sidecars/jhonstart_link.erl` deleted; `linkStatus` declared `#[clientOnly]` (186, 363); the
      member's erlang build emits neither the hook nor its cell

### Step 2 — `use linkStatus()` only in the client (decisions 354, 363)

- [ ] `link_test.bp` (commonJS row): a `#[client] fn Pending() -> @Component<Element>` body with
      `val s = use linkStatus();` (→ `LinkStatus(pending, href)`, `link.bp:187`) renders
- [ ] `refusals/`: `use linkStatus()` in a component that is not `#[client]` refused at the `use`
      (186's check, 363)
- [ ] a server-rendered `Link` reads no hook: the client router sets `data-jh-pending` on the
      active link and clears it when the transition ends; a test over a recording `DomOps` asserts it

### Step 3 — the example

[`examples/post-list-links-example.bp`](./examples/post-list-links-example.bp): `prefetchMode` per
route kind, the checkout link's pending state (`examples/src/**/*.bpp` show the same page as
`.bpp`); corrected here if step 1 changes its surface.

- [ ] the example gains the checkout link's pending state — styled through `[data-jh-pending]`
      (no hook); and one `#[client]` island reading `use linkStatus()` for a progress indicator
- [ ] `botopink check` over the example against `modules/jhonstart-link` passes

**Gate:** standard (fronts.md § Gate) + `jhonstart-link` 38 or more on both rows;
`jhonstart-forms` and `jhonstart-test` unchanged

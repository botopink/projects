# Front 27 — jhonstart link: the reconciler driver

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [149-jhonstart](../README.md): s1 → 149 s2 · s2 → 149 s2. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** medium — a shared layout's islands re-hydrate on every client transition; browser-only
correctness gap, unobservable in the gate until a DOM primitive exists · **State:** in progress (step 1 box 1, step 2 boxes 1 and 3, step 3 done; `27-b` ★)
**Depends on:** nothing for step 1 box 1, steps 2 and 3 — the driver is pure over a record of six
entry-supplied functions (`27-b` ★), so no wait on `07-onze/50` (50 step 6 depends on this front — decision
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

`reconcile.bp` computes the pure decision (`layoutKeys`, `sharedDepth`, `navigationOf`) and its
driver `applyTransition` applies it through the entry's `DomOps` — only the changed subtree replaced,
its islands started, the active link marked `data-jh-pending` while the transition runs. Until the
entry adopts it (`07-onze/50` step 6) the entry still re-hydrates every island after a client
navigation. `jhonstart-link` has 46 tests (`link_test` 28, `reconcile_test` 18), on both rows.

## Mechanism

Transition: `RouterState` → `RouterState`; `navigationOf(current, target)` answers the decision and
`replaceDepth(nav) = shared - 1` the depth whose segment root has its CHILDREN replaced (the deepest
shared segment, so the root layout is never replaced; `/blog` → `/blog/x` answers 1, `/blog/a` →
`/blog/b` the leaf). The driver (`27-b` ★) marks the links to the target pending, awaits the
target's markup, (1) replaces only that subtree (`replaceChildren` on the segment root the render
marks), (2) starts islands only for it (29-a's starters, per route via `registerRouteStarters`),
(3) leaves islands above untouched — their mount count is the observable —, scrolls, and clears the
mark; a failed markup replaces nothing, clears the mark and is the answer. A navigation to the
current path touches nothing.
Whether the target payload had to be fetched = `04-rakun/22`'s route-kind flag (static → cacheable
document, payload prefetched), read through `routing.routeKindOf`, not recomputed. `DomOps` as a
record keeps the member free of a DOM and of `jhonstart-dom-test`; browser proof is onze 53's "Link
navigation between `/blog` and `/blog/<slug>` does not re-request the document".

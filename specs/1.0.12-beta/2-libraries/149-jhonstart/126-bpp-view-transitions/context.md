# Front 126 — bpp view transitions

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [149-jhonstart](../README.md): s1 → 149 s8 · s2 → 149 s8 · s3 → 149 s8 · s4 → 149 s8. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** low — pages work without navigation animation; only 127 and 124 wait on it
(`fronts.md`). · **State:** not started
**Depends on:** `05-jhonstart/27-jhonstart-link` (JH-27-3b: driver `reconcile()` has no body — no
swap to animate yet) · `118-bpp-components` (tag annotations, 278 — this front appends the transition arm) · 120 (previous arm in
`html.bp`; `fake_dom.mjs` before this front).
**Owns:** in `repository/jhonstart/modules/jhonstart-link/src`: new `transitions.bp`,
`sidecars/transitions_runtime.mjs`; step 2's two call sites in `link_runtime.mjs` ·
`jhonstart-link/test/transitions_test.bp` · `jhonstart-dom-test` — the `startViewTransition`
double · one arm appended to `html.bp` (`jhonstart/src/html.bp`, after 120's)
**Does not touch:** `reconcile.bp` (27's); `link.bp`'s `Link` and prefetch; the core member.

Reference: `astro-docs/20-view-transitions.md`.

## Goal

A layout rendering `<ViewTransitions />` gets animated client-side navigations via the View
Transition API: `#[transitionName]` / `#[transitionAnimate]` / `#[transitionPersist]` (278), `navigate()`, five lifecycle events, a
route announcer; apps that do not are unchanged.

## Problem

Astro's `<ClientRouter />` (1) turns clicks into client navigations, (2) animates the swap.
(1) exists: `linkMount` intercepts clicks, calls `pushState` (`jhonstart-link/src/link_runtime.mjs:41-71`),
prefetch by `IntersectionObserver` and `x-jh-prefetch` (`link.bp:163`, `:221-227`) — but
`reconcile(current, target)` (what survives the swap) has no driver (`reconcile.bp:40`;
`05-jhonstart/README.md`, JH-27-3b), so shared-layout islands re-hydrate on every navigation.
(2) is absent: nothing calls `startViewTransition`; `05-jhonstart/27` is the reconciler only, no
front covers animation.

## What exists

At `repository/jhonstart/modules/jhonstart-link/src/`:

| | |
|---|---|
| `Link(props, children) -> Element`, `LinkProps` | `link.bp:51`, `:123` |
| `prefetchMode(kind, hasLoading, requested)` | `link.bp:163` |
| `linkMount`, `linkPrefetch` | `link.bp:221`, `:227` |
| click interception, `pushState`, `popstate` | `link_runtime.mjs:41-71` |
| `layoutKeys`, `sharedDepth` — and no `reconcile` body | `reconcile.bp:40` |
| `startViewTransition`, a navigation event, a route announcer | not found |

## Mechanism

**Opt-in by a component.** `<ViewTransitions />` in a layout's `<head>` writes the transition
stylesheet (`fade`, `slide` keyframes, reduced-motion rule) and sets one payload flag; with it the
runtime wraps the swap in `document.startViewTransition(…)`, without it navigation is today's. No
API: swap without animating, content never held back.

**Annotations are data attributes** (278, 302; the template only lowers them). Each is
`(comptime decl: @Decl, …)` — any element or component tag — declared in `transitions.bp`, recording
its own meta type (`TransitionName`, `TransitionAnimate`, `TransitionPersist`, `TransitionPersistProps`),
so one tag may carry several, one of each:

| Annotation | Attribute | The runtime |
|---|---|---|
| `#[transitionName("hero")]` | `data-jh-vt-name` | sets `view-transition-name`, pairing with the same name on the next page |
| `#[transitionAnimate(.Slide)]` — `fade` (default), `slide`, `none`, `initial` | `data-jh-vt-animate` | picks the keyframes; `slide` reverses on back navigation |
| `#[transitionAnimate(fade(duration: "0.4s"))]` — argument `Animate \| TransitionAnimation` (281) | `data-jh-vt-animate` + inline custom properties | `TransitionAnimation(name, delay, duration, easing, fillMode, direction)`, the reference's record |
| `#[transitionPersist]` · `#[transitionPersist("player")]` | `data-jh-vt-persist` | element **moved** into the new document, not replaced — a playing `<video>`, a stateful island |
| `#[transitionPersistProps]` | `data-jh-vt-persist-props` | a persisted island keeps its old props too |

Meets 27 here: `reconcile` answers which layouts are shared; `#[transitionPersist]` adds named elements to what survives.

**Per link: two tag annotations** (292). `#[reload]` on `<a>` / `<form>` forces a document load;
`#[history(.Push | .Replace | .Auto)]` picks the history call (`History` enum). They take `comptime
decl: @Decl`, record `LinkReload` / `LinkHistory` metas for this front's arm (302), and lower to the wire attributes
`data-jh-reload` / `data-jh-history="replace"` the runtime reads — the attributes are output, never
written by hand (a written `data-jh-reload` is refused, naming the annotation).

**`navigate(href, options)`**: public, for non-click navigations (a `<select>` change, a finished action).

**Five lifecycle hooks** (292), in order, cancelable where the reference's events are:
`use onBeforePreparation({ e -> … })` (with a `loader` to wrap), `use onAfterPreparation(…)`,
`use onBeforeSwap({ e -> … })` (`e.newDocument`), `use onAfterSwap(…)`, `use onPageLoad(…)` — each
`#[clientOnly]` (186, 278), its event a typed record. The `document` events `jh:before-swap` … stay the
runtime's wire, never named by botopink code.

**Accessibility.** After a swap an `aria-live="assertive"` element announces the `<title>`, else
first `<h1>`, else the pathname. `prefers-reduced-motion: reduce` disables every transition animation in the stylesheet.

## Blast radius

- **Nothing changes without `<ViewTransitions />`.** The payload flag is the only switch — one more
  `contracts.md` § 2 key, added in the commit that reads it.
- **Fake DOM grows.** `fake_dom.mjs` stays `05-jhonstart/26`'s, one front at a time after 26
  (189): this front appends its one double after 120's three; its `jhonstart-dom-test` test file
  is its own. 67 adds a test file there without editing `fake_dom.mjs`.

## Notes

- **Not added.** A separate client router (`linkMount` is it). `fallback: "animate"` (simulated
  animations): the swap happens, nothing simulated.
- **Names.** Events and attributes `jh:` / `data-jh-` like all runtime names; annotation names are
  Astro's directive joined (`transition:persist-props` → `transitionPersistProps`, 278).

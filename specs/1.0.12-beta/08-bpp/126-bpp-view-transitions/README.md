# Front 126 — bpp view transitions

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

**Annotations are data attributes** (278; the template only lowers them). Each is
`(comptime tag: Tag, …)` — any element or component tag — declared in `transitions.bp`, returning
its own type (`TransitionName`, `TransitionAnimate`, `TransitionPersist`, `TransitionPersistProps`),
so one tag may carry several, one of each:

| Annotation | Attribute | The runtime |
|---|---|---|
| `#[transitionName("hero")]` | `data-jh-vt-name` | sets `view-transition-name`, pairing with the same name on the next page |
| `#[transitionAnimate("slide")]` — `fade` (default), `slide`, `none`, `initial` | `data-jh-vt-animate` | picks the keyframes; `slide` reverses on back navigation |
| `#[transitionAnimate(fade(duration: "0.4s"))]` — argument `string \| TransitionAnimation` | `data-jh-vt-animate` + inline custom properties | `TransitionAnimation(name, delay, duration, easing, fillMode, direction)`, the reference's record |
| `#[transitionPersist]` · `#[transitionPersist("player")]` | `data-jh-vt-persist` | element **moved** into the new document, not replaced — a playing `<video>`, a stateful island |
| `#[transitionPersistProps]` | `data-jh-vt-persist-props` | a persisted island keeps its old props too |

Meets 27 here: `reconcile` answers which layouts are shared; `#[transitionPersist]` adds named elements to what survives.

**Per link.** `data-jh-reload` on `<a>` / `<form>` forces a document load;
`data-jh-history="push" | "replace" | "auto"` picks the history call.

**`navigate(href, options)`**: public, for non-click navigations (a `<select>` change, a finished action).

**Five `document` events**, in order, cancelable where the reference's are:
`jh:before-preparation` (with a `loader` to wrap), `jh:after-preparation`, `jh:before-swap` (with
`newDocument`), `jh:after-swap`, `jh:page-load`.

**Accessibility.** After a swap an `aria-live="assertive"` element announces the `<title>`, else
first `<h1>`, else the pathname. `prefers-reduced-motion: reduce` disables every transition animation in the stylesheet.

## Open

### Step 1 — `transitions.bp` and the stylesheet

- [ ] `ViewTransitions()`, `TransitionAnimation`, `fade(…)`, `slide(…)`, the four annotations
      `transitionName`, `transitionAnimate`, `transitionPersist`, `transitionPersistProps` with their
      return types, both targets
- [ ] `transitions_test.bp`: the stylesheet is one literal; an annotation's attributes are literals

### Step 2 — The runtime

- [ ] swap wrapped in `startViewTransition` when flagged — `link_runtime.mjs`'s two document-replacing call sites
- [ ] `jhonstart-dom-test`: a `startViewTransition` double recording its callback; cases forward,
      back, `data-jh-reload`, `data-jh-history="replace"`, a browser without the API
- [ ] the five events fire in order, once per navigation; `before-preparation`'s wrapped loader runs around the fetch

### Step 3 — `#[transitionPersist]`

- [ ] a persisted element is the **same node** after the swap (identity, not equality) in the fake DOM; a persisted island is not re-hydrated
- [ ] `#[transitionPersistProps]` keeps old props; without it the island re-renders with the new page's props and keeps its state

### Step 4 — The transition arm of `html`, `navigate`, the announcer

- [ ] `examples/view-transitions-example.bp` passes
- [ ] an unknown animation (`#[transitionAnimate("spin")]`) fails at the argument, listing the four built-ins
- [ ] `<Counter #[clientLoad, transitionPersist] />` carries both (two types); two
      `#[transitionName]` on one tag fail at the second
- [ ] announcer text for a page with a title, without one, and with neither

**Gate:** standard (fronts.md § Gate), plus:
- [ ] `botopink test` green on both targets in `jhonstart-link`; on commonJS in `jhonstart-dom-test`
- [ ] `zig build test-libs`: jhonstart, onze green
- [ ] in `07-onze/53`'s browser run: two pages sharing a `#[transitionName]` animate, no page load triggered

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

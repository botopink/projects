# Front 126 — bpp view transitions

**Priority:** low — a page works without an animation between itself and the next one; only 127
and 124 wait on it (`fronts.md`). · **State:** not started
**Depends on:** `05-jhonstart/27-jhonstart-link` (JH-27-3b: the transition driver `reconcile()`
has no body — there is no swap to animate until it has one) · `118-bpp-components` (the
`transition:` directives are a template arm) · 120 (the arm before this one in `html.bp`, and
`fake_dom.mjs` before this front).
**Owns:** in `repository/jhonstart/modules/jhonstart-link/src`: new `transitions.bp`,
`sidecars/transitions_runtime.mjs`; the two call sites in `link_runtime.mjs` named in step 2 ·
`jhonstart-link/test/transitions_test.bp` · `jhonstart-dom-test` — the `startViewTransition`
double · one arm appended to `html.bp` (`jhonstart/src/html.bp`, after 120's)
**Does not touch:** `reconcile.bp` (27's); `link.bp`'s `Link` and prefetch; the core member.

Reference: `astro-docs/20-view-transitions.md`.

## Goal

A layout that renders `<ViewTransitions />` gets animated client-side navigations through the View
Transition API: `transition:name` / `animate` / `persist`, `navigate()`, the five lifecycle
events and a route announcer — and nothing changes for an application that does not.

## Problem

Astro's `<ClientRouter />` does two jobs: it turns link clicks into client-side navigations, and
it animates the swap with the browser's View Transition API.

The first job exists here: `linkMount` intercepts clicks and calls `pushState`
(`jhonstart-link/src/link_runtime.mjs:41-71`), with prefetch by `IntersectionObserver` and the
`x-jh-prefetch` header (`link.bp:163`, `:221-227`). Its last piece does not: `reconcile(current,
target)` — which decides what of the old page survives the swap — has no driver
(`reconcile.bp:40`; `05-jhonstart/README.md`, JH-27-3b), so a shared layout's islands are
re-hydrated on every navigation.

The second job does not exist at all: no file in the six repositories calls
`startViewTransition`. `05-jhonstart/27` is the reconciler and says nothing about animation, so
no existing front covers it.

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

**Opt-in by a component, as in the reference.** `<ViewTransitions />` in a layout's `<head>`
writes the transition stylesheet (the `fade` and `slide` keyframes, the reduced-motion rule) and
sets one payload flag. With the flag, the navigation runtime wraps its swap in
`document.startViewTransition(…)`; without it, navigation is what it is today. A browser without
the API swaps without animating — the content is never held back for an animation it cannot play.

**The directives are data attributes.** The template lowers them and knows nothing else:

| Directive | Attribute | The runtime |
|---|---|---|
| `transition:name="hero"` | `data-jh-vt-name` | sets `view-transition-name`, pairing the element with the same name on the next page |
| `transition:animate="slide"` — `fade` (default), `slide`, `none`, `initial` | `data-jh-vt-animate` | picks the keyframes; `slide` reverses on a back navigation |
| `transition:animate={fade(duration: "0.4s")}` | `data-jh-vt-animate` + inline custom properties | `TransitionAnimation(name, delay, duration, easing, fillMode, direction)`, the reference's record |
| `transition:persist` · `transition:persist="player"` | `data-jh-vt-persist` | the element is **moved** into the new document instead of replaced — a playing `<video>`, an island with its state |
| `transition:persist-props` | `data-jh-vt-persist-props` | a persisted island keeps its old props too |

Persisting an island is where this front meets 27: `reconcile` already answers which layouts are
shared; `transition:persist` adds elements by name to what survives.

**Per link.** `data-jh-reload` on an `<a>` or a `<form>` forces a document load;
`data-jh-history="push" | "replace" | "auto"` picks the history call.

**`navigate(href, options)`** is the public function for a navigation that does not start from a
click — a `<select>` changing, an action that finished.

**Five events on `document`**, in order, each cancelable where the reference's is:
`jh:before-preparation` (with a `loader` to wrap), `jh:after-preparation`, `jh:before-swap` (with
`newDocument`), `jh:after-swap`, `jh:page-load`.

**Accessibility.** After a swap the runtime announces the new page from an `aria-live="assertive"`
element: the `<title>`, else the first `<h1>`, else the pathname. Under
`prefers-reduced-motion: reduce` every transition animation is disabled by the stylesheet.

## Open

### Step 1 — `transitions.bp` and the stylesheet

- [ ] `ViewTransitions()`, `TransitionAnimation`, `fade(…)`, `slide(…)`, and the three attribute
      writers, both targets
- [ ] `transitions_test.bp`: the stylesheet is one literal; the attributes a directive lowers to
      are literals

### Step 2 — The runtime

- [ ] the swap wrapped in `startViewTransition` when the flag is set — the two call sites in
      `link_runtime.mjs` where the document is replaced
- [ ] `jhonstart-dom-test`: a double for `startViewTransition` that records its callback; cases
      for forward, back, `data-jh-reload`, `data-jh-history="replace"`, and a browser without the
      API
- [ ] the five events fire in order, once per navigation; `before-preparation`'s wrapped loader
      runs around the fetch

### Step 3 — `transition:persist`

- [ ] a persisted element is the **same node** after the swap (identity, not equality) in the fake
      DOM; a persisted island is not re-hydrated
- [ ] `transition:persist-props` keeps the old props; without it the island re-renders with the
      new page's props and keeps its state

### Step 4 — The directive arm, `navigate`, the announcer

- [ ] `examples/view-transitions-example.bp` passes
- [ ] an unknown animation name (`transition:animate="spin"`) fails at the directive, listing the
      four built-ins
- [ ] the announcer's text for a page with a title, without one, and with neither

**Gate:** standard (fronts.md § Gate), plus:
- [ ] `botopink test` green on both targets in `jhonstart-link`; on commonJS in
      `jhonstart-dom-test`
- [ ] `zig build test-libs`: jhonstart, onze green
- [ ] in `07-onze/53`'s browser run: two pages sharing a `transition:name` animate, and a page
      load is not triggered

## Blast radius

- **Nothing changes for an application that does not render `<ViewTransitions />`.** The flag is
  the only switch, and it is in the payload — one more key of `contracts.md` § 2, added in the
  commit that reads it.
- **The fake DOM grows.** `fake_dom.mjs` stays `05-jhonstart/26`'s and is edited by one front at
  a time after 26 (decision 189): this front appends its one double after 120's three; the test
  file it adds to `jhonstart-dom-test` is its own. 67 adds a test file there and does not edit
  `fake_dom.mjs`.

## Notes

- **Not added.** A separate client router — `linkMount` is the router. `fallback: "animate"` for
  browsers without the API (simulated animations): the swap happens and nothing is simulated.
- **Names.** The events and attributes are `jh:` / `data-jh-`, like every other name the runtime
  owns; the directive names are Astro's, since the stack had none.

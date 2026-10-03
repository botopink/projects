# Front 120 — bpp islands: hydration strategies and server islands

**Priority:** high — "load this when it is seen" and "render this part per visitor, cache the
rest" are the two things an islands architecture is for, and the tree has neither.
**Depends on:** `118-bpp-components` (the `client:` and `server:` directives are template arms) ·
`05-jhonstart/26` (it owns the core member, and carries front 29's island work) · `07-onze/50`
(ONZ-68-split: lazy starters — without them a deferred island's code is still downloaded up front)
· `04-rakun/22` (rakun-app) · decision
[`08-e`](../README.md#08-e--what-a-server-island-does-with-its-props).
**Owns:** in `repository/jhonstart/modules/jhonstart/src`: new `island_strategy.bp`,
`deferred.bp`; the lines named in the steps of `client.bp`, `render.bp:218`,
`island_runtime.mjs` · new `repository/rakun/modules/rakun-app/src/server_islands.bp` +
`sidecars/` cell (after `04-rakun/22`, and after 117 on that member's `botopink.json` and
`root.bp`) · one arm appended to `jhonstart-html/src/html.bp` (after 119's) · one line of
`onze-server/src/server.bp` (the route; after `07-onze/49`) · in `jhonstart-dom-test`: the test
file step 2 adds, and step 2's three additions to `fake_dom.mjs` — the file stays
`05-jhonstart/26`'s and is edited by one front at a time after 26, this front before 126
(decision 189)
**Does not touch:** `onze-bundler` (50's — this front states what it needs from it);
`streaming.bp`, `suspense.bp`.

Reference: `astro-docs/02-islands-architecture.md`, `12-framework-components.md`,
`22-server-islands.md`.

---

## Problem

**Client islands hydrate one way.** `#[client]` marks a component (`client.bp:102`), the server
writes `data-jh-i` (`clientMount`, `client.bp:218`), and `hydrate()` walks every `[data-jh-i]` on
load and starts it (`island_runtime.mjs`). There is no "when idle", "when visible", "when this
media query matches" or "do not render on the server at all": the only strategy vocabulary in the
six repositories is `<Script>`'s (`onze-bundler/src/script.bp:18-21`). And the bundle is one chunk —
"every island is in `shared`" (`onze-cli/AGENTS.md:24-26`) — so even an island nobody scrolls to
is downloaded with the page.

**There are no server islands.** A `Suspense` boundary defers a slow subtree *inside the same
response* (`suspense.bp:19-45`, `streaming.bp:935-957`). That keeps the first byte fast; it does
not make the page cacheable, because the personalised bytes are still in it. A server island is a
second request: the page is static, the island is fetched by the browser and rendered per visitor.
Nothing in the tree does that.

## Current state

Measured 2026-10-01 at `repository/jhonstart/modules/jhonstart/src/`:

| | |
|---|---|
| marker | `#[client]` emits a pure `__jhClient_<Name>()` (`client.bp:102`) |
| props | `#[clientProps]` whitelists `string`, `i32`, `f64`, `bool` fields (`client.bp:137`) |
| the island | `Island(id, component, props)` (`:206`); `clientMount(island, children)` (`:218`); `mountIsland(component, props, children)` assigns render ordinals (`render.bp:218`) |
| the wire | payload key `i`: rows `#(id, component, "k=v&…")` (`client.bp:237`, `render.bp:479-523`) |
| the runtime | `hydrate()` — every island, at once, by `commit(html)` setting `innerHTML` (`island_runtime.mjs`) |
| server children | `serverSlot(children)` — `data-jh-s="1"` (`client.bp:277`) |
| the entry | registers starters, checks islands and holes, calls `hydrate()`, `linkMount()`, `formMount()` (`onze-bundler/src/entry.bp:1-31`) |
| server islands, strategies | not found |

## Mechanism

### Client directives

A `client:` directive is legal on a component tag whose function is `#[client]`. The template
lowers it to the mount with a strategy:

| Directive | Strategy | The runtime starts the island |
|---|---|---|
| `client:load` | `Hydrate.Load` | at once — today's behaviour, now asked for by name |
| `client:idle` · `client:idle="500"` | `Hydrate.Idle(timeoutMs)` | in `requestIdleCallback`; where the browser has none, after the timeout (200 ms when none is given) |
| `client:visible` · `client:visible="200px"` | `Hydrate.Visible(rootMargin)` | when an `IntersectionObserver` reports it |
| `client:media="(max-width: 50em)"` | `Hydrate.Media(query)` | when `matchMedia(query)` matches — at once if it already does |
| `client:only` | `Hydrate.Only` | at once, and the server renders **nothing** of the component: only its `slot="fallback"` children |

A component tag with no `client:` directive is rendered on the server and never started — a
`#[client]` function used that way is static markup, as in Astro.

The strategy travels in the island's payload row: `#(id, component, props, when)`. That is a
change to `contracts.md` § 2, made in the commit that makes it.

**The strategy must defer the download, not only the start.** For every strategy but `Load`, the
starter is registered through `registerRouteStarters` as a function that imports the island's
chunk, so the bytes are requested when the strategy fires. That needs one chunk per island, which
is `07-onze/50`'s ONZ-68-split; until it lands, this front's strategies defer execution only, and
the acceptance box that watches the network stays open and says why.

**Props.** `<LikeButton postSlug={s} likes={0} client:visible />` lowers to
`mountIslandWhen("LikeButton", <encoded props>, children, Hydrate.Visible(""))`. The props are
encoded by the function `#[clientProps]` emits for the props record, reached by name —
`<Component>Props` — the way `parse<TypeName>` is reached in `validation`. Step 0 measures what
`#[clientProps]` emits today.

### Server islands

```
<Avatar server:defer><GenericAvatar slot="fallback" /></Avatar>
```

1. The component is marked `#[deferred]`, which registers `"Avatar" → renderer` at module load
   (the shape `#[page]`'s `jhPage` registration has, `routes.bp:221-229`), and its props are a
   `#[clientProps]` record — serialisable by construction.
2. The page render writes the fallback inside `<div data-jh-d="<id>" data-jh-src="<url>">` and
   **does not call the component**. The page stays whatever it was: a prerendered page with a
   server island is still prerendered.
3. `<url>` is `<prefix>/Avatar?p=<sealed props>`. When it would exceed 2 048 bytes the element
   carries `data-jh-body` instead and the runtime sends a `POST`.
4. The browser fetches it; the endpoint unseals the props, renders the component in a request
   frame of its own — `cookies()` and `headers()` are this request's — and answers the markup
   alone. The runtime replaces the fallback.
5. The island's response headers are the component's to set (`Cache-Control`); the page's URL is
   the request's `Referer`.

**Sealing** (decision `08-e`): AES-256-GCM over the encoded props, key from `ONZE_KEY` or
generated at build and written into the server bundle. The cipher is one Erlang host cell in
rakun-app — rakun is erlang-only by manifest, so it needs no node twin.

**The prefix is onze's.** rakun-app exposes `serveIslands(prefix)`; onze-server passes
`/_onze/island` — the way it passes the action field and header names (decision 114).

**Without a client bundle.** A page with a server island and no client island gets a small inline
loader — one `<script>` per page, deduplicated — because the island must load with no bundle.

## Steps

### Step 0 — Measure

- [ ] what `#[clientProps]` emits (`client.bp:137`): whether an encoder exists or the pairs are
      hand-written as in `examples/islands/src/like_button.bp:17-19`
- [ ] an island inside an island's `serverSlot` — hydrated once, twice or not at all
- [ ] `hydrate()` re-run after a client navigation: does it start an island twice

### Step 1 — `Hydrate`, `mountIslandWhen`, the payload column

- [ ] `island_strategy.bp`; `mountIsland` is `mountIslandWhen(…, Hydrate.Load)`
- [ ] the payload row's fourth column on both targets; `contracts.md` § 2 and onze's
      `build_test.bp:104` literal amended together
- [ ] `client_test.bp`: one case per strategy, asserting the row

### Step 2 — The runtime scheduler

- [ ] `island_runtime.mjs`: one scheduler per strategy; an island is started at most once
- [ ] `jhonstart-dom-test`: `fake_dom.mjs` gains `IntersectionObserver`, `matchMedia`,
      `requestIdleCallback`; five cases, each asserting that the island is **not** started before
      its trigger and is started after
- [ ] `client:only` renders the fallback on the server and the component in the browser

### Step 3 — The directives

- [ ] `examples/hydration-directives-example.bp` passes
- [ ] `client:visible` on an element, and on a component the template can see is not `#[client]`,
      fail at the directive; a component it cannot see fails the build in the bundler's island
      check (`entry.bp`) with the component's name — never a mount that starts nothing
- [ ] two `client:` directives on one tag fail at the second

### Step 4 — Server islands

- [ ] `examples/server-island-example.bp` passes on erlang
- [ ] `server_islands.bp`: `serveIslands(prefix)`, `seal` / `unseal`; a tampered or truncated
      `p` answers 400 and renders nothing
- [ ] a `GET` under 2 048 bytes and a `POST` over it answer the same markup
- [ ] the page that contains the island reads no cookie: `dynamicReason()` is empty and the page
      prerenders (`static_gen.bp`)
- [ ] `server:defer` on a component that is not `#[deferred]` fails at boot, naming it

### Step 5 — The network (waits on ONZ-68-split)

- [ ] in `07-onze/53`'s browser run: the chunk of a `client:visible` island below the fold is not
      requested until it is scrolled to; the chunk of a `client:media` island that does not match
      is never requested

## Gate

- [ ] `botopink test` green on both targets in `modules/jhonstart`; on commonJS in
      `jhonstart-dom-test`; on erlang in `rakun-app`
- [ ] `zig build test-libs`: jhonstart, rakun, onze green; the blog's hydrated island still hydrates
- [ ] `scripts/gate.sh --cold` green
- [ ] `AGENTS.md` of every directory touched; `contracts.md` § 2
- [ ] Commit on `front/120-bpp-islands`; landing is the maintainer's step

## Blast radius

- **The payload contract changes** (`i` rows gain a column). Every reader — the island runtime,
  onze's entry, `jhonstart-test`'s helpers — moves in one commit.
- **`hydrate()` stops being "everything now".** A test that asserts an island is started after
  `hydrate()` holds only for `Load`.
- **A new public route prefix** on every onze application, answering rendered markup for sealed
  props. It is `GET`-reachable by design; the seal is what makes its input the server's own.
- **`<Script>`'s strategies are untouched** — they load scripts, not components.

## Notes

- **Not added.** `client:only="react"` — the argument names a framework and there is one.
  Mixing frameworks. `transition:persist` on an island is 126's.
- **`#[clientProps]` is narrower than Astro's list** (`string`, `i32`, `f64`, `bool` against
  objects, arrays, `Map`, `Set`, `Date`, …). Step 1 widens it to arrays of those and nested
  `#[clientProps]` records, encoded through `validation`'s `encode<T>` once 125 lands; `Dict`,
  `Set` and dates-as-`i64` follow from the same encoder.
- **Event handlers.** An island's markup names its handlers (`data-jh-on-click="LikeButton:like"`)
  and the runtime binds none today (`island_runtime.mjs:98` is the only listener). That is
  `05-jhonstart/26`'s; this front's tests start islands and do not click them.
- **Suspense is not replaced.** A boundary streams within a response; a server island is a second
  response. A page may use both.

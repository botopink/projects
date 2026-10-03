# Front 120 — bpp islands: hydration strategies and server islands

**Priority:** high — "load when seen" and "render per visitor, cache the rest" are what islands
are for; the tree has neither. · **State:** not started
**Depends on:** `118-bpp-components` (`client:` / `server:` are template arms) · `119-bpp-styling`
(previous arm in `html.bp`) · `05-jhonstart/26` (owns the core, carries front 29's island work) ·
`07-onze/50` (ONZ-68-split: lazy starters — without them deferred code still downloads up front)
· `07-onze/49` (island route in `onze-server`) · `04-rakun/22` (rakun-app), 117 before it on that
member · Written against decisions 224, 271, 272.
**Owns:** in `repository/jhonstart/modules/jhonstart/src`: new `island_strategy.bp`,
`deferred.bp`; the step-named lines of `client.bp`, `render.bp:218`, `island_runtime.mjs` · new
`repository/rakun/modules/rakun-app/src/server_islands.bp` + `sidecars/` cell (after
`04-rakun/22`, after 117 on the member's `botopink.json`, `root.bp`) · one arm appended to
`html.bp` (`jhonstart/src/html.bp`, after 119's) · one line of `onze-server/src/server.bp` (the
route; after `07-onze/49`) · in `jhonstart-dom-test`: step 2's test file and its three
`fake_dom.mjs` additions (file stays `05-jhonstart/26`'s, one front at a time after 26, this
before 126 — 189)
**Does not touch:** `onze-bundler` (50's — needs stated here); `streaming.bp`, `suspense.bp`.

Reference: `astro-docs/02-islands-architecture.md`, `12-framework-components.md`, `22-server-islands.md`.

## Goal

`client:idle` / `visible` / `media` / `only` start an island — and download its code — when the
strategy fires; `server:defer` renders a component per visitor in a second request while the page
stays prerendered and cacheable, props sealed by default.

## Problem

**One hydration mode.** `#[client]` marks a component (`client.bp:102`), the server writes
`data-jh-i` (`clientMount`, `client.bp:218`), `hydrate()` starts every `[data-jh-i]` on load
(`island_runtime.mjs`). No idle / visible / media / client-only; the only strategy vocabulary in
the six repos is `<Script>`'s (`onze-bundler/src/script.bp:18-21`). One chunk — "every island is in
`shared`" (`onze-cli/AGENTS.md:24-26`) — so unseen islands download with the page.

**No server islands.** `Suspense` defers a subtree *within the response* (`suspense.bp:19-45`,
`streaming.bp:935-957`): fast first byte, not cacheable (personalised bytes inside). A server
island is a second, browser-fetched, per-visitor request; nothing does that.

## What exists

At `repository/jhonstart/modules/jhonstart/src/`:

| | |
|---|---|
| marker | `#[client]` emits a pure `__jhClient_<Name>()` (`client.bp:102`) |
| props | `#[clientProps]` whitelists `string`, `i32`, `f64`, `bool` fields (`client.bp:137`) |
| the island | `Island(id, component, props)` (`:206`); `clientMount(island, children)` (`:218`); `mountIsland(component, props, children)` assigns render ordinals (`render.bp:218`) |
| the wire | payload key `i`: rows `#(id, component, "k=v&…")` (`client.bp:237`, `render.bp:479-523`) |
| the runtime | `hydrate()` — every island at once, `commit(html)` setting `innerHTML` (`island_runtime.mjs`) |
| server children | `serverSlot(children)` — `data-jh-s="1"` (`client.bp:277`) |
| the entry | registers starters, checks islands and holes, calls `hydrate()`, `linkMount()`, `formMount()` (`onze-bundler/src/entry.bp:1-31`) |
| server islands, strategies | not found |

## Mechanism

### Client directives

Legal on a component tag whose function is `#[client]`; lowered to the mount with a strategy:

| Directive | Strategy | The runtime starts the island |
|---|---|---|
| `client:load` | `Hydrate.Load` | at once — today's behaviour, by name |
| `client:idle` · `client:idle="500"` | `Hydrate.Idle(timeoutMs)` | in `requestIdleCallback`; without it, after the timeout (200 ms default) |
| `client:visible` · `client:visible="200px"` | `Hydrate.Visible(rootMargin)` | when an `IntersectionObserver` reports it |
| `client:media="(max-width: 50em)"` | `Hydrate.Media(query)` | when `matchMedia(query)` matches — at once if it does |
| `client:only` | `Hydrate.Only` | at once; the server renders **nothing** of it, only its `slot="fallback"` children |

No `client:` directive: server-rendered, never started (static markup, as in Astro).

Payload row becomes `#(id, component, props, when)` — `contracts.md` § 2 changed in the same commit.

**Defer the download, not only the start.** For all but `Load`, the starter is registered via
`registerRouteStarters` as a function importing the island's chunk. Needs one chunk per island
(`07-onze/50`'s ONZ-68-split); until then strategies defer execution only and the network box stays
open, saying why.

**Props.** `<LikeButton postSlug={s} likes={0} client:visible />` lowers to
`mountIslandWhen("LikeButton", <encoded props>, children, Hydrate.Visible(""))`; props encoded by
the function `#[clientProps]` emits, reached by name `<Component>Props` (as `parse<TypeName>` in
`validation`). Step 0 measures what it emits.

### Server islands

```
<Avatar server:defer><GenericAvatar slot="fallback" /></Avatar>
```

1. Component marked `#[deferred]` registers `"Avatar" → renderer` at module load (shape of
   `#[page]`'s `jhPage` registration, `routes.bp:221-229`); props are a `#[clientProps]` record.
2. Page render writes the fallback in `<div data-jh-d="<id>" data-jh-src="<url>">`, **does not
   call the component**; a prerendered page stays prerendered.
3. `<url>` = `<prefix>/Avatar?p=<sealed props>`; over 2 048 bytes the element carries
   `data-jh-body` and the runtime sends a `POST`.
4. Endpoint unseals, renders in its own request frame (`cookies()`, `headers()` are this
   request's), answers the markup alone; runtime replaces the fallback.
5. Response headers are the component's (`Cache-Control`); page URL = the request's `Referer`.

**Sealing** (224): mode per project in `onze.json` (`"islands": {"props": "sealed"}`), no
per-request/per-environment override; default **sealed** — AES-256-GCM over the encoded props; key
`ONZE_KEY` or build-generated (`onze create-key`, 124) into the server bundle. Cipher: one Erlang
host cell in rakun-app (erlang-only by manifest, no node twin). Modes (decision 272): `"sealed"` (default) or `"server"` — the props stored server-side under a random id, nothing in the URL (`?id=9f3a…`), the shell not cacheable across instances; no mode exposes the props (no `"signed"`); anything else is a config error.
The variable is always `ONZE_KEY` (decision 271).

**Prefix is onze's.** rakun-app exposes `serveIslands(prefix)`; onze-server passes `/_onze/island`
(as with action field/header names, decision 114).

**Without a client bundle**: a small inline loader, one deduplicated `<script>` per page.

## Open

### Step 0 — Measure

- [ ] what `#[clientProps]` emits (`client.bp:137`): an encoder, or pairs hand-written as in `examples/islands/src/like_button.bp:17-19`
- [ ] an island inside an island's `serverSlot` — hydrated once, twice or not at all
- [ ] `hydrate()` re-run after client navigation: does an island start twice

### Step 1 — `Hydrate`, `mountIslandWhen`, the payload column

- [ ] `island_strategy.bp`; `mountIsland` is `mountIslandWhen(…, Hydrate.Load)`
- [ ] payload row's fourth column on both targets; `contracts.md` § 2 and onze's `build_test.bp:104` literal amended together
- [ ] `client_test.bp`: one case per strategy, asserting the row

### Step 2 — The runtime scheduler

- [ ] `island_runtime.mjs`: one scheduler per strategy; an island started at most once
- [ ] `jhonstart-dom-test`: `fake_dom.mjs` gains `IntersectionObserver`, `matchMedia`,
      `requestIdleCallback`; five cases, each asserting **not** started before its trigger, started after
- [ ] `client:only` renders the fallback on the server, the component in the browser

### Step 3 — The directives

- [ ] `examples/hydration-directives-example.bp` passes
- [ ] `client:visible` on an element, or on a component the template sees is not `#[client]`,
      fails at the directive; an unseen one fails the build in the bundler's island check
      (`entry.bp`) with its name — never a mount that starts nothing
- [ ] two `client:` directives on one tag fail at the second

### Step 4 — Server islands (modes `sealed` and `server`, decision 272)

- [ ] `examples/server-island-example.bp` passes on erlang
- [ ] `server_islands.bp`: `serveIslands(prefix)`, `seal` / `unseal`; tampered or truncated `p` answers 400, renders nothing
- [ ] `GET` under 2 048 bytes and `POST` over it answer the same markup
- [ ] the containing page reads no cookie: `dynamicReason()` empty, page prerenders (`static_gen.bp`)
- [ ] `server:defer` on a non-`#[deferred]` component fails at boot, naming it
- [ ] `seal` / `unseal` take the mode as a plain value — `onze.json`'s `"islands": {"props": …}`,
      read by onze's config (124) — default `sealed` (224)
- [ ] mode `server`: the props stored server-side under a random id, the URL carries only `?id=…`;
      an unknown or expired id answers 400 and renders nothing; two instances without a shared
      store do not serve each other's ids (stated in `AGENTS.md`)

### Step 5 — The network (waits on ONZ-68-split)

- [ ] in `07-onze/53`'s browser run: a below-the-fold `client:visible` island's chunk is not
      requested until scrolled to; a non-matching `client:media` island's chunk is never requested

## Decisions

None open (224, 271, 272 answered the server-island ones).

**Gate:** standard (fronts.md § Gate), plus:
- [ ] `botopink test` green on both targets in `modules/jhonstart`; on commonJS in `jhonstart-dom-test`; on erlang in `rakun-app`
- [ ] `zig build test-libs`: jhonstart, rakun, onze green; the blog's hydrated island still hydrates
- [ ] `contracts.md` § 2

## Blast radius

- **Payload contract changes** (`i` rows gain a column); every reader — island runtime, onze's
  entry, `jhonstart-test`'s helpers — moves in one commit.
- **`hydrate()` no longer "everything now"**; "started after `hydrate()`" holds only for `Load`.
- **New public route prefix** on every onze app, answering markup for sealed props; `GET`-reachable
  by design, the seal makes its input the server's own.
- **`<Script>`'s strategies untouched** — scripts, not components.

## Notes

- **Not added.** `client:only="react"` (names a framework; there is one); mixing frameworks.
  `transition:persist` on an island is 126's.
- **`#[clientProps]` narrower than Astro** (`string`, `i32`, `f64`, `bool` vs objects, arrays,
  `Map`, `Set`, `Date`, …). Step 1 widens it to arrays of those and nested `#[clientProps]`
  records via `validation`'s `encode<T>` (125); `Dict`, `Set`, dates-as-`i64` follow.
- **Event handlers.** Markup names handlers (`data-jh-on-click="LikeButton:like"`), runtime binds
  none (`island_runtime.mjs:98` the only listener) — `05-jhonstart/26`'s; tests here start islands, never click.
- **Suspense not replaced**: streams within a response; a server island is a second one; both may coexist.

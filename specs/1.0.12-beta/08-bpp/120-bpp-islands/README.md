# Front 120 — bpp islands: hydration strategies and server islands

**Priority:** high — "load when seen" and "render per visitor, cache the rest" are what islands
are for; the tree has neither. · **State:** not started
**Depends on:** `118-bpp-components` (tag annotations, 278 — this front appends the `Hydrate` / `Defer` arms) · `119-bpp-styling`
(previous arm in `html.bp`) · `05-jhonstart/26` (owns the core, carries front 29's island work) ·
`07-onze/50` (ONZ-68-split: lazy starters — without them deferred code still downloads up front)
· `07-onze/49` (island route in `onze-server`) · `04-rakun/22` (rakun-app), 117 before it on that
member · `05-jhonstart/26` step 8 (`stage.bp`'s `clientOnly`, `pathsTo`) · Written against decisions 224,
271, 272, 277, 278, 280, 281, 287, 302.
**Owns:** in `repository/jhonstart/modules/jhonstart/src`: new `island_strategy.bp`,
`deferred.bp`; the step-named lines of `client.bp`, `clientOnly`'s return in `stage.bp` (26's file, step 1), `render.bp:218`, `island_runtime.mjs` · new
`repository/rakun/modules/rakun-app/src/server_islands.bp` + `sidecars/` cell (after
`04-rakun/22`, after 117 on the member's `botopink.json`, `root.bp`) · one arm appended to
`html.bp` (`jhonstart/src/html.bp`, after 119's) · one line of `onze-server/src/server.bp` (the
route; after `07-onze/49`) · in `jhonstart-dom-test`: step 2's test file and its three
`fake_dom.mjs` additions (file stays `05-jhonstart/26`'s, one front at a time after 26, this
before 126 — 189)
**Does not touch:** `onze-bundler` (50's — needs stated here); `streaming.bp`, `suspense.bp`.

Reference: `astro-docs/02-islands-architecture.md`, `12-framework-components.md`, `22-server-islands.md`.

## Goal

`#[clientIdle]` / `#[clientVisible]` / `#[clientMedia]` / `#[clientOnly]` on a component's tag start an
island — and download its code — when the strategy fires; `#[serverDefer]` renders a component per visitor in a second request while the page
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

### Client annotations (278)

> **Since 302** an annotation returns nothing: `clientVisible(comptime decl: @Decl, comptime rootMargin)`
> records `decl.setMeta(Hydrate.Visible(rootMargin))`; "returns `Hydrate`" below reads "records the
> `Hydrate` meta" (one per tag), `serverDefer` records `Defer(fallback)`. `#[clientOnly]` is one
> function for hook and tag with no union: both are a `@Decl` (on the hook a marker; on a tag it records
> `Hydrate.Only`). The checks below run where `html` reads the `Hydrate` meta.

Tag annotations (118's arm): a function in the caller's scope, `comptime decl: @Decl` first — the
tag's component — recording a `Hydrate` meta (302); `html` turns a `Hydrate` into the mount with that strategy.
All live in `island_strategy.bp` except `clientOnly` (`stage.bp`, below); the prelude imports them.

| Annotation | Records (302) | The runtime starts the island |
|---|---|---|
| `#[clientLoad]` | `Hydrate.Load` | at once — today's behaviour, by name |
| `#[clientIdle]` · `#[clientIdle(500)]` | `Hydrate.Idle(timeoutMs)` | in `requestIdleCallback`; without it, after the timeout (200 ms default) |
| `#[clientVisible]` · `#[clientVisible("200px")]` | `Hydrate.Visible(rootMargin)` | when an `IntersectionObserver` reports it |
| `#[clientMedia("(max-width: 50em)")]` | `Hydrate.Media(query)` | when `matchMedia(query)` matches — at once if it does |
| `#[clientOnly]` · `#[clientOnly(fallback: <p>Loading…</p>)]` | `Hydrate.Only` | at once; the server renders **nothing** of it, only the annotation's `fallback` (287) |

No `Hydrate` on the tag: server-rendered, never started (static markup, as in Astro).

**The fallback is an annotation argument** (287): `serverDefer(comptime decl: @Decl, comptime
fallback: ?View = null) -> Defer`, `clientOnly(comptime decl: @Decl, comptime fallback: ?View = null)`.
It shows until the component arrives — the island's second request, or the browser's mount — so it
is comptime (280): static markup or a component without request data; `fallback: <span>{user.name}</span>`
is refused at the argument; a `slot="fallback"` child is refused (no `slot="…"`, `props-e`); on a hook
declaration `#[clientOnly]` takes no `fallback`.

**`#[clientOnly]` is one function** (278): decision 186's marker on a hook declaration and, on a
tag, the instance rendered only on the client — both "only on the client". `05-jhonstart/26` step 8
declares it a marker (`{}`); step 1 here makes it record `Hydrate.Only` on a tag (302); on a
declaration it records nothing. A `#[clientOnly]` tag lowers to the mount without calling the component on
the server, so the component's nodes do not enter the page's `hooks` (277).

**Checks by type, in `html`** — every `Hydrate`, whoever declared the annotation:
- the component carries `#[client]` (`a.decorator.is(client)`, 277) — else "`Footer` is not a
  `#[client]` component";
- `pathsTo(decl.hooks, clientOnly)` (26 step 8) non-empty: refused under any `Hydrate` but `Only`,
  and on a tag with no `Hydrate` — "`Map` reaches `geolocation` (#[clientOnly]) via …; use
  #[clientOnly]";
- two `Hydrate` on one tag: error at the second.

A library may declare its own (`pub fn clientMobile(comptime decl: @Decl) { clientMedia(decl,
"(max-width: 50em)"); }` — it records the same meta); it gets the checks above and adds no strategy —
the runtime knows `Hydrate`'s five cases only.

Payload row becomes `#(id, component, props, when)` — `contracts.md` § 2 changed in the same commit.

**Defer the download, not only the start.** For all but `Load`, the starter is registered via
`registerRouteStarters` as a function importing the island's chunk. Needs one chunk per island
(`07-onze/50`'s ONZ-68-split); until then strategies defer execution only and the network box stays
open, saying why.

**Props.** `<LikeButton #[clientVisible] postSlug={s} likes={0} />` lowers to a
`mountIslandWhen` of the component — the function itself, never its name in text — with its encoded
props, children and `Hydrate.Visible("")`; props encoded by the member of the `#[clientProps]`
record (`LikeButtonProps.encode`), starters and props reached by type at comptime (280, 281; `68-c`
closed). Today `client.bp` reaches `<Component>Props` by name — step 6. Step 0 measures what it emits.

### Server islands

```
<Avatar #[serverDefer(fallback: <GenericAvatar size={48} />)] size={48} />
```

1. Component marked `#[deferred]` enters a catalogue built at comptime (`@TypeInfo.all(with:
   deferred)`, 281; step 6) — not a `"Avatar" → renderer` registration at module load (today's
   shape, `#[page]`'s `jhPage`, `routes.bp:221-229`); props are a `#[clientProps]` record; the URL
   keeps the component's name as the wire id.
2. Page render writes the annotation's `fallback` (287) in `<div data-jh-d="<id>" data-jh-src="<url>">`, **does not
   call the component**; a prerendered page stays prerendered.
3. `<url>` = `<prefix>/Avatar?p=<sealed props>`; over 2 048 bytes the element carries
   `data-jh-body` and the runtime sends a `POST`.
4. Endpoint unseals, renders in its own request frame (`use cookie(decl)`, 294, and `use request()`,
   291, read this request), answers the markup alone; runtime replaces the fallback.
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

- [ ] `island_strategy.bp`: `Hydrate`, `mountIslandWhen`; `mountIsland` is `mountIslandWhen(…, Hydrate.Load)`
- [ ] the annotations `clientLoad`, `clientIdle(comptime timeoutMs: i32 = 200)`, `clientVisible(comptime
      rootMargin: string = "")`, `clientMedia(comptime query: string)` — each `(comptime decl: @Decl,
      …)`, returning nothing and recording a `Hydrate` meta (280, 302) — and `stage.bp`'s `clientOnly`
      recording `Hydrate.Only` on a tag, still the hook marker `05-jhonstart/26` step 8 reads (278);
      all imported by `prelude.bp`
- [ ] payload row's fourth column on both targets; `contracts.md` § 2 and onze's `build_test.bp:104` literal amended together
- [ ] `client_test.bp`: one case per strategy, asserting the row

### Step 2 — The runtime scheduler

- [ ] `island_runtime.mjs`: one scheduler per strategy; an island started at most once
- [ ] `jhonstart-dom-test`: `fake_dom.mjs` gains `IntersectionObserver`, `matchMedia`,
      `requestIdleCallback`; five cases, each asserting **not** started before its trigger, started after
- [ ] `#[clientOnly(fallback: …)]` on a tag renders the fallback on the server, the component in the
      browser (287)

### Step 3 — The `Hydrate` arm of `html` (278)

- [ ] `examples/hydration-directives-example.bp` passes
- [ ] `#[clientVisible]` on an element fails at the annotation (its first parameter is `@Decl`); on
      a component without `#[client]` fails at the annotation, checked by `Decorator.is`; an unseen
      island fails the build in the bundler's island check (`entry.bp`) with its name — never a
      mount that starts nothing
- [ ] two `Hydrate` annotations on one tag fail at the second
- [ ] a component whose `hooks` reach `#[clientOnly]`: refused under `#[clientLoad]`, `#[clientIdle]`,
      `#[clientVisible]`, `#[clientMedia]` and with no annotation, the message naming the chain and
      `#[clientOnly]`; accepted under `#[clientOnly]`
- [ ] a `#[clientOnly]` tag adds no node of its component to the page's `hooks` (a `refusals/` cell
      in 26's form: the page stays `S`)
- [ ] a library annotation recording `Hydrate` (`clientMobile` in the example) mounts and gets the
      same checks

### Step 4 — Server islands (modes `sealed` and `server`, decision 272)

- [ ] `examples/server-island-example.bp` passes on erlang
- [ ] `server_islands.bp`: `serveIslands(prefix)`, `seal` / `unseal`; tampered or truncated `p` answers 400, renders nothing
- [ ] `GET` under 2 048 bytes and `POST` over it answer the same markup
- [ ] the containing page reads no cookie: its kind is `S` (`@typeInfo(Page).meta(PageMeta)?.kind`, 277), page prerenders (`static_gen.bp`)
- [ ] `serverDefer(comptime decl: @Decl, comptime fallback: ?View = null)` recording `Defer` (287, 302;
      `deferred.bp`, imported by the prelude); on a
      non-`#[deferred]` component it fails at the annotation, at compile time, naming it
- [ ] `seal` / `unseal` take the mode as a plain value — `onze.json`'s `"islands": {"props": …}`,
      read by onze's config (124) — default `sealed` (224)
- [ ] mode `server`: the props stored server-side under a random id, the URL carries only `?id=…`;
      an unknown or expired id answers 400 and renders nothing; two instances without a shared
      store do not serve each other's ids (stated in `AGENTS.md`)

### Step 5 — The network (waits on ONZ-68-split)

- [ ] in `07-onze/53`'s browser run: a below-the-fold `#[clientVisible]` island's chunk is not
      requested until scrolled to; a non-matching `#[clientMedia]` island's chunk is never requested

### Step 6 — references, not strings (decision 281)

- [ ] `Island(component: "LikeButton", props: [#("likes", "3")])` → the function and its typed
      `#[clientProps]` record; the starter table built at comptime (`@TypeInfo.all(with: client)`);
      `mountIslandWhen("Carousel", …)` in `hydration-directives-example.bp` likewise
- [ ] the `<Component>Props` encoder reached as a member (`LikeButtonProps.encode`, 216), not by name
- [ ] `#[deferred]`'s registration (`"Avatar"` → renderer at module load) → the comptime catalogue
      (`@TypeInfo.all(with: deferred)`); the URL keeps the component's name as the wire id

### Step 7 — route parameters and page data are hooks (decision 293)

- [ ] `server-island-example.bp`: pages take no `route: PageContext`; parameters through `use params<P>()`, page data through `use pageData<D>()`

## Decisions

None open (224, 271, 272 answered the server-island ones; 278, 302 the annotations; 287 the
fallback, an annotation argument; `68-c` → 280, 281: starters and props by type at comptime).

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
- **`<Script>`'s strategies stay their own** — scripts, not components: a `ScriptStrategy` enum (292), not `Hydrate`.

## Notes

- **Not added.** Astro's `client:only="react"` (names a framework; there is one); mixing frameworks.
  `#[transitionPersist]` on an island is 126's. A new strategy ("on hover") is a `Hydrate` case,
  this front's — a library annotation can only combine the five.
- **`#[clientProps]` narrower than Astro** (`string`, `i32`, `f64`, `bool` vs objects, arrays,
  `Map`, `Set`, `Date`, …). Step 1 widens it to arrays of those and nested `#[clientProps]`
  records via `validation`'s encode (a `#[validated]` type's member since 306, spelling `ctr-u`); `Dict`, `Set`, dates-as-`i64` follow.
- **Event handlers.** Markup names handlers (`data-jh-on-click="LikeButton:like"`), runtime binds
  none (`island_runtime.mjs:98` the only listener) — `05-jhonstart/26`'s; tests here start islands, never click.
- **Suspense not replaced**: streams within a response; a server island is a second one; both may coexist.

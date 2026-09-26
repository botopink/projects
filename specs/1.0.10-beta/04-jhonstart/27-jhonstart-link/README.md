# Front 27 — Jhonstart Link

**Track:** C jhonstart
**Priority:** critical — without `Link` every navigation is a full page load, and the client half of the milestone has nothing to intercept
**Target:** js (client) — the member declares both targets and its code runs on both rows
**Wave:** 4
**Depends on:** 26 · `01-std/04-routing-lib` (`matchPath`, `routeKindOf`, `parseSlotStates`, `clientHref`) · 60 (route-kind flag, read-only) · 30 (payload envelope, read-only) · 68 (generated entry + DOM primitives, read-only) · 94 (element builders used by the examples)
**Owns:** the `jhonstart-link` member (`modules.md` § 1): `modules/jhonstart-link/src/link.bp`, `src/reconcile.bp`, `src/link_runtime.mjs`, `src/sidecars/jhonstart_link.erl`, `test/link_test.bp`, `test/reconcile_test.bp`, its `root.bp` and `botopink.json`
**Does not touch:** `element.bp`, `hooks.bp`, `jhonstart-html/src/html.bp` (frozen), `router.bp` (front 26), `client.bp` (front 29)
**Reference:** `NEXTJS-DOCS.md § 8. Navegação e Linking` · `§ 25. Referência de Componentes` · https://nextjs.org/docs/app/api-reference/components/link · https://nextjs.org/docs/app/getting-started/linking-and-navigating

---

## Outcome

A `<Link>` is the entry point to client-side transitions: an anchor rendered identically on both
rows, a prefetch decision, a remount decision, and a browser half over four host cells. A consumer
writes `import {Link, linkProps} from "jhonstart-link";` beside `import {div, a} from "jhonstart";`.

| What | Shape |
|---|---|
| The props | `LinkProps(href, prefetch, replace, scroll, target, className)` — a record. `linkProps(href)` fills Next's defaults (prefetch true, replace false, scroll true); `withPrefetch` / `withReplace` / `withScroll` / `withTarget` / `withClass` each return a new record with one field changed |
| The anchor | `Link(props, children: Children) -> Element` — pure, reaches no host cell |
| The prefetch decision | `prefetchMode(kind, hasLoading, requested) -> string` — `"full"` / `"partial"` / `"skip"` |
| The layout key | `layoutKey(segments, depth)` = `"/" + segments.take(depth).join("/")`; `segments` is front 26's `RouterState.segments()`, so client and server compute the same string |
| The remount decision | `layoutKeys(segments)` (root-first, root included) · `sharedDepth(current, target)` (common-prefix length; `[0, keep)` stays mounted, the rest is replaced; never `0`) — `reconcile.bp`, pure |
| The in-flight status | `LinkStatus(pending, href)` · `linkStatusOf(href)` (pure) · `linkStatus() -> @Component<ElementBase, LinkStatus>` (the hook) |
| The browser half | `linkMount()` · `linkPrefetch(href, mode)` · `linkRouteKind(href)` over `__jhLinkMount`, `__jhLinkPrefetch`, `__jhLinkStatus`, `__jhLinkRouteKind` |

`Link` has no pass-through `attrs` list — only `target` and `className`, through `LinkProps`: an
anchor that accepted any attribute could be handed its own `data-jh-l`, the marker the browser half
queries on.

### The anchor's attributes

Emitted only when they differ from the default, so the common link is
`<a href="/blog" data-jh-l="1">Blog</a>`.

| Prop | Attribute emitted | Emitted when |
|---|---|---|
| `href` | `href="…"` | always |
| — | `data-jh-l="1"` | always — this is what the runtime queries for |
| `prefetch` | `data-jh-prefetch="0"` | only when `false`; absent means "decide by route kind" |
| `replace` | `data-jh-replace="1"` | only when `true` |
| `scroll` | `data-jh-scroll="0"` | only when `false` |
| `target` | `target="…"` | only when non-empty |
| `className` | `class="…"` | only when non-empty |

The `data-jh-` prefix is the marker family of the HTML jhonstart writes (`contracts.md § 2`,
decision 113); these are the link markers and the whole vocabulary this front adds.

### The runtime half

The four cells are dual-target — `#[@External.Node("./link_runtime.mjs", …),
@External.Erlang("jhonstart_link", …)]` — because the member compiles on both rows and a called
single-target cell reds the other row's compile at its caller (pending decision 27-a). The erlang
twins answer what is true on a server: no link in flight, nothing prefetched, route kind
`"unknown"`.

- `linkMount()` — delegated click interception plus an intersection observer over every
  `[data-jh-l]`; idempotent. An ordinary import, not a browser global (decision 113). The entry
  module **front 68 generates** calls it once, after hydrating the islands, alongside one call to
  front 67's `formMount()`. Front 29 owns the per-island hydrate point, not the entry, and does not
  call this.
- `linkPrefetch(href, mode)` — warms the client route cache; `mode` is `prefetchMode`'s answer.
- `linkStatus()` — the href of the navigation in flight, `""` when idle, through `linkStatusOf`.
- `linkRouteKind(href)` — `"static"`, `"dynamic"` or `"unknown"`, read from the route-kind table
  **front 60** emits into the client bundle; `"unknown"` without one.

### Prefetch strategy

`NEXTJS-DOCS.md § 8` *Prefetching*, as a pure function:

| Route kind | `loading` boundary present | Mode |
|---|---|---|
| static | — | `full` — the whole route is prefetched |
| dynamic | yes | `partial` — prefetch up to the nearest `loading` boundary |
| dynamic | no | `skip` |
| any | `prefetch: false` | `skip` |

Both inputs come from front 60's table; this front computes neither. The route an href resolves
against is the payload's `t`, matched with `routing`'s `matchPath`; the route-kind blob is read
with `routeKindOf`, the slot states with `parseSlotStates`, an href built with `clientHref` — one
implementation of each, in `routing` (decision 115).

### Layout state preservation

A client transition must not remount a layout the two routes share (`NEXTJS-DOCS.md § 5`). A layout
is keyed by its **segment path**, not its position in the tree: two routes under `/docs` share the
key `"/docs"`; a route under `/blog` unmounts the docs layout. This front owns the reconciler that
consumes the keys (front 68 builds the bundle; diffing two route trees is navigation behaviour).

The transition driver `reconcile(current, target)` is not written yet. It is four steps:

1. `layoutKeys` of the current and the target route.
2. `sharedDepth` of the two lists; everything above it stays mounted, DOM and islands untouched.
3. Unmount the current subtree below that depth and mount the target's from the payload the
   prefetcher has — or fetch it, front 60's route-kind flag deciding whether a fetch was needed.
4. Adopt `data-jh-s` slots as-is (front 29) and re-anchor `data-jh-e` boundaries (front 31).

It touches no host cell of its own: it drives `linkPrefetch` and front 68's DOM primitives.

### Delivered

- `LinkProps`, `linkProps`, the five `with*` helpers (each builds a new record), `Link`, `prefetchMode`, `layoutKey`, `LinkStatus`, `linkStatusOf` in `link.bp`; `layoutKeys` / `sharedDepth` in `reconcile.bp` — pure; `reconcile.bp` declares no cell.
- The anchor literal `<a href="/about" data-jh-l="1">About</a>` is the snapshot; each attribute row has its test; `target` is a real attribute, not `data-`.
- Every row of the prefetch table is one assertion; `layoutKey(["docs", "api", "use-router"], 1) == "/docs"`, `layoutKey([], 0) == "/"`.
- `layoutKeys(["docs", "api"]) == ["/", "/docs", "/docs/api"]`; `sharedDepth` is 2 for `/docs/api` → `/docs/guides`, 1 for `/docs` → `/blog`, the full length for the same route.
- The four cells `__jhLinkMount`, `__jhLinkPrefetch`, `__jhLinkStatus`, `__jhLinkRouteKind`; `linkStatus()` idle when nothing is in flight; `linkMount()` idempotent; `linkRouteKind` reads front 60's table and answers `"unknown"` without one.
- No `data-onze-` string under `modules/jhonstart*/src/`; no `__onze*` spelling; `git grep -n "declare fn Link"` finds nothing.
- `repository/jhonstart/AGENTS.md` records the member; front 68's README (step 8) calls `linkMount()` once.
- The language gap below is a row of `language-gaps.md`. The member's tests are green on both rows.

## Steps

Only the open boxes are listed; everything else is under *Delivered*.

### Step 1 — `LinkProps` and its builders

Done.

### Step 2 — `Link`

Done.

### Step 3 — Prefetch strategy and layout keys

Done.

### Step 3b — The client-navigation reconciler

- [ ] a shared layout's islands are not re-hydrated across a transition, asserted by an island whose
      mount count is observable
- [ ] the reconciler reads front 60's route-kind flag to decide whether the target payload had to be
      fetched, and does not recompute it

### Step 4 — The browser runtime cells and `linkStatus`

- [x] every cell in the file is dual-target — `link_runtime.mjs` beside
      `sidecars/jhonstart_link.erl`, whose twin answers the server's truth (no link in flight,
      nothing prefetched, route kind unknown): a called node-only cell reds the erlang compile of
      the member at its caller, and the member declares both targets (`decisions-pending.md` 27-a)
      — held: `link.bp:249-262`
- [ ] `use linkStatus()` type-checks inside a `fn … -> @Component<ElementBase, Element>` body — never the doubled `use` + `useLinkStatus()`; without a `@Component` return the body is `use-without-context-effect` (decisions 118 and 128)

### Step 5 — Module wiring

- [ ] `pub mod link;` and the `files` entry are handed to front 94; this front edits neither file

### Step 6 — Decision 113's spellings

Done.

## Examples

- [`examples/post-list-links-example.bp`](./examples/post-list-links-example.bp) — a blog index with
  two hundred posts: prefetch is switched off for the list and left on for the two navigation links,
  which is the case § 8 *Prefetching* says to switch off.
- [`examples/pending-link-example.bp`](./examples/pending-link-example.bp) — a checkout link that
  shows a spinner while its own navigation is in flight, via `linkStatus`.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| No assignment to a `self` field; a record has no copy-with-update | each `with*` helper respells all six fields to change one | a `with*` helper per field | a `Record(base, field: value)` copy-update expression |

## Test plan

`modules/jhonstart-link/test/link_test.bp` and `reconcile_test.bp`, both rows, in the gate through
`zig build test-libs -- --lib jhonstart-link`: `linkProps` defaults and each `with*`; the seven
attribute rows (exact string for the common case); the prefetch table; `layoutKey`, `layoutKeys`,
`sharedDepth` for reuse, partial reuse, full replace and same route; `linkStatus()` idle, called
without `use`; `linkMount()` idempotent. Open: the island mount count across a transition and the
route-kind flag read by the reconciler (Step 3b), both with the transition driver.

## Definition of done

- [ ] `link.bp` in the build tree, its `root.bp` and `files` lines handed to front 94
- [x] `Link` renders the documented anchor and reaches no host
- [x] `prefetchMode` implements § 8's table exactly, with a test per row
- [x] the client-navigation reconciler ships in `src/reconcile.bp` with its own test file, and
      `layoutKeys`/`sharedDepth` are pure and asserted without a DOM
- [x] front 68's generated entry calls `linkMount()` once, and this README says so rather than
      attributing it to front 29 — § *The runtime half*
- [x] the route-kind flag is read from front 60 and not recomputed here
- [x] the language gap appears in a `specs/1.0.10-beta/` spec
- [x] the front's tests are green on its assigned target

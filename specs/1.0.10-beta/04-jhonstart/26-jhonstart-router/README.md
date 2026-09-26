# Front 26 — Jhonstart Router

**Track:** C jhonstart
**Priority:** critical — `Link`, server components, streaming, error boundaries and metadata all read the route this front produces
**Target:** erlang (server) · commonJS for `clientApp`, the client-only entry (decision 117)
**Boundary:** the route snapshot is one of the three things `overview.md` says crosses. The server fills it; the client rebuilds it from the payload (`globals().payload`, front 30) after a client navigation. The payload envelope and the route table are **not** defined here — they are front 30's and front 22's; the matcher comes from the compiler-bundled library `routing` (decision 115), neutral like std — jhonstart and rakun never import each other (decision 113).
**Wave:** 3
**Depends on:** 01 (`encoding.formParse` / `formStringify`; `json.decode` for the payload `clientApp` reads — decision 117 rule 7) · `01-std/04-routing-lib` (`parseTable`, `matchPath`, `attempt`; `navigation.signalFromWire` / `signalFromReason`) · `01-std/05-actions-lib` (`refresh.refreshValue`) · 30 (payload envelope, `compose`, `redirectAllowed`) · 31 (`notFound` / `redirect`, the not-found boundary) · 94 (element builders used by the examples)
**Owns:** `modules/jhonstart/src/router.bp` (with `router_runtime.mjs` / `sidecars/jhonstart_router.erl`), `modules/jhonstart/src/client_app.bp` (with `client_app.mjs` / `sidecars/jhonstart_client_app.erl`), `modules/jhonstart/test/router_test.bp`, `modules/jhonstart/test/client_app_test.bp`
**Does not touch:** `element.bp`, `hooks.bp`, `jhonstart-html/src/html.bp` (frozen), `jhonstart-link` (front 27), `server.bp` (front 28)
**Reference:** `NEXTJS-DOCS.md § 8. Navegação e Linking` · `§ 26. Referência de Funções` · https://nextjs.org/docs/app/api-reference/functions/use-router · https://nextjs.org/docs/app/api-reference/functions/use-params · https://nextjs.org/docs/app/api-reference/functions/use-search-params · [decision 117](../../decisions-taken.md#117-navigation-signals-are-jhonstarts-end-to-end-pages-and-layouts-are-components-std-reads-json-bundled-libraries-are-bp-only)

---

## Outcome

A component asks which route it renders through six hooks over one immutable snapshot, and
navigates through six free functions over one host cell. Everything is reached as
`import {…} from "jhonstart"`.

| What | Shape |
|---|---|
| The snapshot | `RouterState(path, params, search, pattern, selected)` — a plain record. `params`/`search` are `Array<#(string, string)>`; `selected` is the layout depth (root layout `0`) |
| Its accessors | `r.param(n)` · `r.searchParam(n)` · `r.segments()` · `r.segment()` — plain `string` / `Array<string>`, `""` when absent or out of range, never `?string`. Field names and method names are disjoint |
| The pair decoder | `pairValue(pairs, name)` — the package's one pair-list decoder, first match of a duplicated key |
| The segment readers | `patternSegments(pattern)` · `segmentAt(segments, i)`. `segments` is derived from `pattern` (split on `/`, empty parts dropped, bracket spelling kept), never transported |
| The pair codec | std's `encoding.formParse` / `formStringify` (decision 116 rule 4); the package carries no copy |
| The build | `snapshot()` — five cells in, the record out; no `?T` unwrap that can fail |
| The writer | `fill(path, params, search, pattern, selected)` — the one way route state is installed, every field at once; `params`/`search` querystring-encoded as the payload's `m`/`q` carry them |
| The hooks | `router` · `pathname` · `params` · `searchParams` (the only reader of the query — `PageContext` has no `query` field — and it marks the render dynamic, 26-b) · `selectedLayoutSegment` · `selectedLayoutSegments` — each `-> @Component<ElementBase, T>`, activated with `use`; `selectedLayoutSegments()` is root-first |
| The verbs | `push` · `replace` · `back` · `forward` · `refresh` · `prefetch` — free functions over `__jhNavigate`, `-> i32` nobody reads; `lastNavigation()` answers `"<kind> <href>"` |
| The envelope's signal | `navigationFor(wire)` (pure: `""`, `"not-found"`, `"replace <location>"`) · `applySignal(wire)` — the `n` field read with `routing`'s `signalFromWire` |
| The route of a URL | `resolveRoute(tableWire, path, search)` — `routing`'s `parseTable` + `matchPath` over the payload's `t`; unmatched answers `pattern: ""`, `params: []` |
| Client-only app | `clientApp(routes, mount, allowedRedirects = []).start() -> @Task<@Result<void, string>>` (`client_app.bp`) |

Why navigation is not a method: records are immutable and there is no assignment to a `self`
field, so a verb is a call against host state and `RouterState` is a read-only snapshot of it.

### The cells and the payload keys

| `RouterState` field | cell | payload key (front 30) |
|---|---|---|
| `path` | `__jhRoutePath()` | `p` — pathname |
| `params` | `__jhRouteParams()` | `m` — querystring-encoded |
| `search` | `__jhRouteSearch()` | `q` — querystring-encoded |
| `pattern` | `__jhRoutePattern()` | `r` — the matched pattern, bracket spelling kept |
| `selected` | `__jhRouteSelected()` | — per-layout, supplied by front 30's render |

Every cell in `router.bp` and `client_app.bp` is dual-target today
(`#[@External.Node("./router_runtime.mjs", …), @External.Erlang("jhonstart_router", …)]`): the core
member compiles on both rows, and a called single-target cell reds the other row's compile at its
call site. The BEAM store is the calling process's dictionary, so a request's snapshot dies with
its process. Steps 2 and 4 and the *Definition of done* still carry the single-target wording as
open boxes.

### The verbs on each side

| Verb | erlang (during a server render) | js (in the browser) |
|---|---|---|
| `push(href)` | records a 307 redirect on the response | `history.pushState` + re-render |
| `replace(href)` | records a 307 redirect on the response | `history.replaceState` + re-render |
| `back()` / `forward()` | no-op — there is no history on the server | `history.back()` / `history.forward()` |
| `refresh()` | no-op | re-requests the current route's payload and re-reconciles without a reload |
| `prefetch(href)` | no-op | warms the client route cache; front 27 drives it |

`refresh()` is shared with front 24: the request carries the action header onze names with
`refreshValue()` from the bundled library `actions` (decision 116 rule 2); the router spells no
`refresh` literal. An action or refresh envelope's `n` is read with `routing`'s `signalFromWire` —
`""` nothing, `"N"` the nearest not-found, `"R|307|/login"` a `replace` to `/login`; a malformed
`n` reads as `None`. A server action's `redirect` is rakun's, a page's is jhonstart's (decision 117
rule 4); the router reads both through the same codec without importing rakun.

Native History API use (`popstate`, a `pushState` the application performs) rebuilds `RouterState`
through `resolveRoute` over `window.location` and the payload's `t`, so `searchParams()` reacts to
a bare `pushState` without a reload, a second parser or a second precedence rule.

### `clientApp`

```bp
import {clientApp} from "jhonstart";

clientApp(routes: routeTable, mount: "#root", allowedRedirects: []).start();
```

`routes` is contract 1's wire (the text a server writes into the payload's `t`); `start()` matches
the location, composes the matched chain with front 30's `compose` and writes it into `mount`
through `__jhMount(selector, html)`. A signal a page, layout or template raises is handled as front
30's render handles it on the server, with front 30's `redirectAllowed`:

| Raised | `clientApp` does |
|---|---|
| `notFound()` | renders the matched route's nearest not-found boundary (front 31) into `mount`; the URL does not change |
| `redirect(to)`, relative and matched in `routes` | `history.replaceState` to `to` and a client navigation, no reload |
| `redirect(to)`, absolute and listed in `allowedRedirects` | `location.replace(to)` |
| any other target | `start()` answers the error; nothing navigates (decision 67) |

A server-rendered app does not call `clientApp`: onze front 68's entry hydrates the server's
document, reading the payload with `readPayload(globals().payload)` (std `json.decode`).

### Delivered

- `RouterState`, the six hooks, the six verbs, `pairValue`, `snapshot`, `fill` all `pub` and tested (`router_test.bp`); `clientApp` in `client_app.bp` (`client_app_test.bp`) — both rows.
- `router.d.bp` is gone; `router.bp` is in the build tree; `modules/jhonstart/AGENTS.md` records the promotion.
- The cell → payload-key table is in `docs.md` § *The snapshot, the five cells and `fill`*.
- The router has no matcher, table parser, pair codec or signal-wire decoder of its own: `routing` (`parseTable`, `matchPath`, `signalFromWire`) and std `encoding`; no `rakun` identifier under `modules/jhonstart/src/`, no `routing` entry in `botopink.json` (bundled, like std); no `__onze` literal — the client reads `globals().payload` (`__bp0`).
- A percent-encoded search value is decoded (`q=a%20b` → `"a b"`) and written back encoded, on both rows.
- `refresh()` sends `refreshValue()` from `"actions"`; `"refresh"` remains only as the navigation cell's verb name.
- `clientApp` renders the matched route layout-first; `notFound` and the three `redirect` cases behave as the table above (a layout's redirect means the page never runs — `compose`'s order).
- The language gap below is a row of `language-gaps.md`.

## Steps

Only the open boxes are listed; everything else in each step is under *Delivered*.

### Step 1 — `RouterState` and its accessors

- [x] `pairValue` is `pub` and is the only pair-list decoder in the package: front 28 (`server.bp`)
      and front 30 (`routes.bp`) import it — front 32's `metadata.bp` decodes no pair list — and
      `git grep -n "fn pairValue" -- '*.bp'` finds exactly one definition — held: `router.bp:60`,
      `server.bp:87`, `routes.bp:44`

### Step 2 — The five host cells and the snapshot builder

- [x] every cell — the five reads, `fill`, `navigate`, `lastNavigation` — is dual-target, an
      `#[@External.Node("./router_runtime.mjs", …)]` twin beside `#[@External.Erlang("jhonstart_router", …)]`:
      an erlang-only cell reds the commonJS compile of the core member at its call site, and the core
      is compiled on both rows (`decisions-pending.md` 26-a) — held: `router.bp:139-304`, the reason in
      its header (`router.bp:125-135`) and in `docs.md` § *The snapshot, the five cells and `fill`*

### Step 3 — The five hooks

Done: `use pathname()` type-checks in a `fn … -> @Component<ElementBase, Element>` body (decisions
118 and 128); a hook called without `use` answers the server-pass value.

### Step 4 — Navigation verbs

- [x] `__jhNavigate` is dual-target like every cell of the file (Step 2's reason, 26-a) — held:
      `router.bp:293`

### Step 5 — Module promotion

- [ ] `pub mod router;` and the `files` swap are handed to front 94; this front edits neither
      `src/root.bp` nor `botopink.json`

### Step 6 — `clientApp` (decision 117)

- [ ] the late-signal function front 30 registers under `globals().signal` and `clientApp` share one
      handler: a `data-jh-g="redirect"` template and a raised `redirect` with the same target take
      the same path

## Examples

- [`examples/active-nav-example.bp`](./examples/active-nav-example.bp) — a sidebar that highlights
  the section the reader is in, using `pathname` and `selectedLayoutSegment`.
- [`examples/search-params-example.bp`](./examples/search-params-example.bp) — a sort control that
  reads `searchParams` and rewrites the URL with `replace`, the shape §8's *History API nativa*
  describes.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| No assignment to a `self` field; a record has no in-place update | `push`/`replace` cannot be methods on `RouterState` — they are free functions over a host cell | free functions + an immutable snapshot | a `var` field or a `with`-style copy update |

## Reference gaps

Next's `useSelectedLayoutSegment(s)` (here `selectedLayoutSegment()` / `selectedLayoutSegments()`)
does not appear in `NEXTJS-DOCS.md`; it is upstream API
(https://nextjs.org/docs/app/api-reference/functions/use-selected-layout-segment), implemented from
the upstream page.

## Test plan

`modules/jhonstart/test/router_test.bp` and `client_app_test.bp`, both rows, in the gate through
`zig build test-libs -- --lib jhonstart`. They cover: `RouterState` and each accessor (absent key,
out of range); `snapshot()` over `fill`; the `encoding` round-trip including `a b` ↔ `a%20b`; the
four `n` forms of `contracts.md § 5b` through `navigationFor`; `refreshValue()`; each hook called
without `use`; each verb callable and returning; `resolveRoute` over `routing`; `clientApp`'s
rendered route, both signals and the target check. Open: the shared late-signal handler (Step 6).

## Definition of done

- [ ] `router.d.bp` removed, `router.bp` in the build tree, its `root.bp` and `files` lines handed
      to front 94
- [x] `RouterState`, six hooks, six navigation verbs, `pairValue`, `snapshot` all `pub` and tested
- [ ] `pairValue` is defined once, here, and fronts 28 and 32 cite front 26 for it
- [x] the five cells map one-to-one onto payload keys `p`/`m`/`q`/`r` plus the per-layout
      `selected`, and the mapping table is in `repository/jhonstart/docs.md`
- [x] `segments` is derived from `pattern`, never transported
- [x] the router has no matcher and no table parser of its own; it imports both from `routing`
- [x] the router has no pair codec and no signal-wire decoder of its own: std `encoding` and
      `routing`'s `navigation` (decision 116)
- [x] `clientApp` renders through `__jhMount(selector, html)` and moves history through
      `__jhNavigate`; both are dual-target (`client_app.mjs` / `sidecars/jhonstart_client_app.erl`,
      the erlang twin a module store the tests read) — a called node-only cell reds the erlang
      compile of the core (26-a) — held: `client_app.bp:49-51`, `client_app_test.bp`
- [x] `clientApp` handles `notFound` / `redirect` in a client-only app as front 30's render does on
      the server, with the same target check (decision 117)
- [x] the language gap appears in a `specs/1.0.10-beta/` spec
- [x] the front's tests are green on its assigned target

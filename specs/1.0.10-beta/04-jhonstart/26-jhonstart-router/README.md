# Front 26 — Jhonstart Router

**Track:** C jhonstart
**Priority:** critical — nothing downstream can ask "which route is this?"; `Link`, server components, streaming, error boundaries and metadata all read the answer this front produces
**Target:** erlang (server) · commonJS for `clientApp`, the client-only entry (decision 117)
**Boundary:** the route snapshot is one of the three things `overview.md` says crosses. The server matches and fills it; the client rebuilds it from the payload (`globals.payload`, front 30) after a client navigation. The payload envelope and the route table are **not** defined here — they are front 30's and front 22's; this front consumes the envelope and imports the matcher from the compiler-bundled library `routing` (decision 115), which is neutral like std — jhonstart and rakun never import each other (decision 113), and both import `routing`.
**Wave:** 3
**Depends on:** 01 (`encoding.formParse` / `formStringify`; `json.decode` for the payload `clientApp` reads — decision 117 rule 7) · `01-std/04-routing-lib` (`parseTable`, `matchPath`; Step 7's `navigation.signalFromWire` / `isSignalReason` / `signalFromReason`) · `01-std/05-actions-lib` (`refresh.refreshValue`) · 30 (payload envelope, read-only; the `Response` translation `clientApp` mirrors) · 31 (`notFound` / `redirect`, the not-found boundary) · 94 (element builders used by the examples)
**Owns:** `repository/jhonstart/src/router.bp` (promoted from `router.d.bp`, and the package's one `pairValue` pair-list decoder; `clientApp` and its signal handling), `repository/jhonstart/test/router_test.bp`
**Does not touch:** `src/element.bp`, `src/hooks.bp`, `src/html.bp` (frozen), `src/link.bp` (front 27), `src/server.bp` (front 28), `src/root.bp` and `botopink.json` (front 94)
**Reference:** `NEXTJS-DOCS.md § 8. Navegação e Linking` · `§ 26. Referência de Funções` · https://nextjs.org/docs/app/api-reference/functions/use-router · https://nextjs.org/docs/app/api-reference/functions/use-params · https://nextjs.org/docs/app/api-reference/functions/use-search-params · [decision 117](../../decisions-taken.md#117-navigation-signals-are-jhonstarts-end-to-end-pages-and-layouts-are-components-std-reads-json-bundled-libraries-are-bp-only)

---

## Problem

A jhonstart component cannot ask what route it is rendering. `src/router.d.bp` is a declaration
file: it declares a `Router` behavior with four bodyless methods and two `#[@External.Node]` cells,
and its own header says why none of it is promotable — "`useRouter` is a host-bound `@Context`
capability … not in pure `.bp`" (`router.d.bp:8-15`). Because `.d.bp` modules are not resolved by
`mod` paths (`src/root.bp:9-13`), nothing in the build tree can even name `Router`. A developer
writing a nav bar today has no pathname, no params, no query, and no way to know which child segment
is active.

The two reasons the header gives for the gate have both closed. `Element` grew an `attrs` slot
(`element.bp:7`), so a router-aware component can emit a class. And the route itself now has a
producer: front 22 matches the URL against the `app/` tree before the render starts. What is missing
is the piece in between — a record the render can read, filled by the server, and rebuilt by the
client after a client-side navigation so that the same component code produces the same markup on
both sides.

The second problem is that navigation cannot be a method on the record. botopink records are
immutable and there is no assignment to a `self` field anywhere in the tree; `Dict.insert` (std
`collections`) returning a new dict is the ecosystem's shape. So a navigation verb is a call against
host state, and the record is a read-only snapshot of that state.

## Current state

- `src/router.d.bp` — 28 lines, declaration-only: `behavior Router` with `pathname`/`params`/`push`/
  `replace` (`:17-22`), `useRouter()` (`:24-25`), `Link()` (`:27-28`). Both cells are
  `#[@External.Node]` — Node-only, which the milestone's target split forbids for a server front.
- `src/root.bp:15-17` declares exactly three modules: `element`, `hooks`, `html`. `router` is not
  one of them.
- `botopink.json` ships `router.d.bp` in `files` as a declaration.
- `libs/std/src/querystring.bp:35,48` has `parse(query) -> Array<#(string, string)>` and
  `stringify(pairs) -> string`, pure botopink on every backend, but escape-naive: it neither
  percent-encodes nor decodes. The landed `router.bp` carries a stand-in pair codec,
  `decodePairs` / `encodePairs` (`modules/jhonstart/src/router.bp:123-162`), which does not decode
  either — the server writes the payload's `m` / `q` percent-encoded, so a space arrives as `a%20b`.
  Decision 116 rule 4 makes std's `encoding.formParse` / `formStringify` (`01-std-lib-enablement`
  Step 3) the one codec on both sides and deletes the stand-in.
- `repository/rakun/src/http.bp:35-43` is the precedent for the accessor shape: `param`, `query`,
  `header` all return a plain `string`, `""` when absent — never `?string` (`http.bp:30-34`).

## Mechanism

Next.js splits route state into five hooks over one internal router record: `useRouter` for the
navigation verbs, `usePathname`, `useParams`, `useSearchParams` for the three views of the URL, and
`useSelectedLayoutSegment(s)` for the child segment a layout is currently rendering
(`NEXTJS-DOCS.md § 26`). The record is produced on the server during the first render and rebuilt on
the client on every client-side transition, so a component that highlights the active link works
identically in both places.

jhonstart spells the five as `router`, `pathname`, `params`, `searchParams` and
`selectedLayoutSegment(s)`: the keyword `use` is the activation and the name is the noun
([`19-use-activation`](../../00-compiler-carry-over/19-use-activation/README.md)). The Next.js names in this section are the reference, not the API.

jhonstart keeps that split and makes the record concrete.

### The erlang half — this front

`router.bp` defines `RouterState`, a plain record with five fields and no `Router` behavior. A
behavior with `val` members has no verified implementor anywhere in the tree, and a concrete record
is what `use` has to yield anyway — the indirection buys nothing and risks a construct nobody has
exercised.

The snapshot is filled from five `#[@External.Erlang]` cells that read what front 22 put in the
request's process dictionary before dispatch. Every one of them returns a `string`, and each maps
one-to-one onto a key of front 30's payload envelope, so the server record and the client record are
built from the same five values:

| `RouterState` field | cell | payload key (front 30) |
|---|---|---|
| `path` | `__jhRoutePath()` | `p` — pathname |
| `params` | `__jhRouteParams()` | `m` — querystring-encoded |
| `search` | `__jhRouteSearch()` | `q` — querystring-encoded |
| `pattern` | `__jhRoutePattern()` | `r` — the matched pattern, bracket spelling kept |
| `selected` | `__jhRouteSelected()` | — per-layout, supplied by front 30's render |

`segments` is **derived**, not transported: it is `pattern` split on `/` with the empty parts
dropped. One value, one source; a transported segment list could disagree with the pattern it came
from.

The two pair-shaped values are decoded with std's `encoding.formParse` (percent-aware,
`01-std-lib-enablement` Step 3) on both sides, and a URL the router rewrites is written with
`encoding.formStringify` — the codec rakun uses on the server (decision 116 rule 4). No JSON, no record serialization, nothing that has
to agree between an Erlang term and a JS object.

### The route table is front 22's, and there is one parser

`matchPath`, `parseTable` and `writeTable` are specified by front 22 and implemented once, in the
compiler-bundled library `routing` (`libs/routing`, erlang and commonJS, `contracts.md § 1`,
decision 115). The table is line-oriented (`kind|pattern|slot|verb`, kinds `L T P D R S E N`) and
travels in the payload's `t` key. **The router imports the matcher** — `import {table.parseTable,
match.matchPath} from "routing";` — parses the payload's `t` itself and matches with the function
rakun's server matches with, on erlang and on commonJS alike. `routing` names neither jhonstart nor
rakun, so the import is not an edge between the two (decision 113); onze hands the router nothing
(decision 115). The router contains no second matcher and no second table parser. A router with its own matcher is a router that disagrees with the
server on precedence (static > dynamic > catch-all > optional catch-all), and the disagreement shows
up only on the routes nobody tested.

The five hooks are thin. Each is `fn … -> @Component<ElementBase, T>` (decision 128): the wrapper
names the base the hook anchors on, and `use` on it is legal inside a `@Component` body whose base is
`ElementBase` — a `fn … -> @Component<ElementBase, Element>` component, or another hook (decision 104).
It is the same shape `hooks.bp` uses for `state`/`memo` (`hooks.bp:30-60`).

### The js half — front 27 and front 29

The four navigation verbs (`push`, `replace`, `back`, `forward`, `refresh`, `prefetch`) are declared
here because `router()` is where a developer reaches for them, but their bodies are host cells
carrying **both** targets. They are the one part of this front that is not erlang-only, and the
reason is that they mean different things on each side rather than the same thing twice:

| Verb | erlang (during a server render) | js (in the browser) |
|---|---|---|
| `push(href)` | records a 307 redirect on the response | `history.pushState` + re-render |
| `replace(href)` | records a 307 redirect on the response | `history.replaceState` + re-render |
| `back()` / `forward()` | no-op — there is no history on the server | `history.back()` / `history.forward()` |
| `refresh()` | no-op | re-requests the current route's payload and re-reconciles without a reload |
| `prefetch(href)` | no-op | warms the client route cache; front 27 drives it |

`refresh()` is shared with front 24: a server action that mutates data calls the same re-request
path, so the payload endpoint and its revalidation semantics are rakun's (fronts 23/24), reached through
onze, and this front only calls it. The request carries the action header onze names with the value
`refreshValue()` from the bundled library `actions` (decision 116 rule 2) — the router spells no
`refresh` literal of its own.

**The envelope's navigation signal.** When the router applies an action envelope (front 67 hands it
the parsed result) or the envelope a `refresh()` answers, it reads the `n` field with `routing`'s
`navigation.signalFromWire` (decision 116 rule 1) — `""` nothing, `"N"` the nearest not-found,
`"R|307|/login"` a `replace` to `/login` — and navigates from that, never from a second copy of the
grammar. The `n` of an action envelope is written by rakun's `redirect`: a server action's
`redirect` is rakun's, a page's is jhonstart's (decision 117 rule 4), and the router reads both
through the same codec without importing rakun. A malformed `n` reads as `None`, so a bad field from the network cannot crash a render.

Native History API use is also supported: the browser half listens for `popstate` and for a
`pushState` the application performs itself (`NEXTJS-DOCS.md § 8`, *History API nativa*), rebuilds
`RouterState` by running `routing`'s `matchPath` against `window.location` and the table in the
payload's `t` key, and re-renders. Because the rebuild goes through the same matcher and the same
`encoding.formParse`, `searchParams()` reacts to a bare `pushState` without a reload, without a
second parser, and without a second precedence rule.

### Client-only apps — `clientApp`

An application with no server runs the same pages under this router alone (decision 117 rule 1):

```bp
import {clientApp} from "jhonstart";

clientApp(routes: routeTable, mount: "#root", allowedRedirects: []).start();
```

```bp
pub type ClientApp(routes: string, mount: string, allowedRedirects: string[])
pub fn clientApp(routes: string, mount: string, allowedRedirects: string[] = []) -> ClientApp
pub fn start(self: ClientApp) -> @Task<void>
```

`routes` is the route table in contract 1's wire (the text a server writes into the payload's
`t`), parsed once with `routing`'s `parseTable`; `mount` is the selector of the element the app
renders into, written through the one browser-only cell `__jhMount(selector, html)`; history moves
through `__jhNavigate`. `start()` matches `window.location` with `matchPath`, renders the matched chain with
front 30's `compose` into `mount`, and listens for the navigations of *The js half*. A page, layout
or template is the same `fn … -> @Component<ElementBase, Element>` it is with a server, and a navigation
signal it raises is handled here, as front 30's render handles it on the server:

| Raised | `clientApp` does |
|---|---|
| `notFound()` | renders the matched route's nearest not-found boundary (front 31) into `mount`; the URL does not change |
| `redirect(to)`, relative | `history.replaceState` to `to` and a client navigation to it, no reload |
| `redirect(to)`, absolute and listed | `location.replace(to)` |

The target check is front 30's rule with the table `clientApp` was given: a relative target must be
found by `matchPath` in `routes`, an absolute one must be listed in `allowedRedirects` (empty by
default, so every absolute target is refused), and anything else fails the render — the failure is
the error `start()` answers or the nearest error boundary's, never a navigation (decision 67). The
late-signal markup a server stream carries (`__bp2`, front 30) calls the same handler, so a signal
behaves identically whether it was raised in the browser or written by a server.

A server-rendered app does not call `clientApp`: onze front 68's entry hydrates the server's
document instead, reading the payload with `readPayload(globals.payload)` — decoded with std's
`json.decode` (decision 117 rule 7) — and taking the table from its `t`.

### What crosses

One direction, one format. The server writes `p`, `m`, `q`, `r` and `t` into the payload
front 30's render writes (`globals.payload`); the client reads them on hydration and recomputes `p`/`m`/`q`/`r` from `t` on
every transition. A component sees `RouterState` and cannot tell which side it is on.

## Steps

### Step 1 — `RouterState` and its accessors

Field names and method names are kept disjoint (`params` the field, `param(name)` the method) so a
record field never shadows a method.

```bp
// src/router.bp
import {Element} from "element";
import {encoding} from "std";

pub type RouterState(
    path: string,
    params: Array<#(string, string)>,
    search: Array<#(string, string)>,
    pattern: string,
    selected: i32,
) {
    pub fn param(self: Self, name: string) -> string {
        return pairValue(self.params, name);
    }

    pub fn searchParam(self: Self, name: string) -> string {
        return pairValue(self.search, name);
    }

    pub fn segments(self: Self) -> Array<string> {
        return self.pattern.split("/").filter({ part -> part != "" });
    }

    pub fn segment(self: Self) -> string {
        return self.segments().at(self.selected).unwrapOr("");
    }
}

// The package's one pair-list decoder. Fronts 28 and 32 import it from here
// rather than each growing a copy: three implementations of "the value of
// `slug`, or the empty string" is three chances to disagree about a duplicate
// key.
pub fn pairValue(pairs: Array<#(string, string)>, name: string) -> string {
    val hit = pairs.find({ p -> p._0 == name });
    val fallback = #("", "");
    return hit.unwrapOr(fallback)._1;
}
```

**Acceptance:**
- [x] `RouterState(path: "/blog/hi", params: [#("slug", "hi")], search: [], pattern: "/blog/[slug]", selected: 0).param("slug") == "hi"` — `test/router_test.bp` "router: a param is read by name"
- [x] `param` of an absent key is `""`, not a runtime error — `test/router_test.bp` "router: an absent param is the empty string, not a runtime error"
- [ ] `pairValue` is `pub` and is the only pair-list decoder in the package: fronts 28 and 32 import
      it, and `git grep -n "fn pairValue"` finds exactly one definition
- [x] `pairValue` of a duplicated key returns the first match, and the test asserts it — `test/router_test.bp` "router: pairValue answers the FIRST match of a duplicated key"
- [x] `segments()` of `"/blog/[slug]"` is `["blog", "[slug]"]` — the bracket spelling is kept — `test/router_test.bp` "router: segments keep the bracket spelling and drop the empty parts"
- [x] `segment()` of an out-of-range `selected` is `""` — `test/router_test.bp` "router: segment answers the layout depth, and out of range is empty"
- [x] no field of `RouterState` shares a name with a method of `RouterState` — fields `path/params/search/pattern/selected`, methods `param/searchParam/segments/segment`

### Step 2 — The five host cells and the snapshot builder

```bp
#[@External.Erlang("jhonstart_router", "path")]
pub declare fn __jhRoutePath() -> string;

#[@External.Erlang("jhonstart_router", "params")]
pub declare fn __jhRouteParams() -> string;

#[@External.Erlang("jhonstart_router", "search")]
pub declare fn __jhRouteSearch() -> string;

#[@External.Erlang("jhonstart_router", "pattern")]
pub declare fn __jhRoutePattern() -> string;

#[@External.Erlang("jhonstart_router", "selected")]
pub declare fn __jhRouteSelected() -> i32;

pub fn snapshot() -> RouterState {
    return RouterState(
        path: __jhRoutePath(),
        params: encoding.formParse(__jhRouteParams()),
        search: encoding.formParse(__jhRouteSearch()),
        pattern: __jhRoutePattern(),
        selected: __jhRouteSelected(),
    );
}
```

**Acceptance:**
- [ ] all five cells are `#[@External.Erlang]`; none is `#[@External.Node]`
- [x] `snapshot()` of `("/blog/hi", "slug=hi", "", "/blog/[slug]", 0)` round-trips to the record in step 1 — `test/router_test.bp` "router: the five cells round-trip into the record of step 1"
- [x] each cell maps to exactly one payload key, and the mapping table is in `docs.md` — `docs.md` § *The snapshot, the five cells and `fill`*
- [x] an empty params string yields `[]`, not `[#("", "")]` — `test/router_test.bp` "router: an empty params string yields the empty list, not one empty pair"
- [x] `snapshot()` of search `q=a%20b` has `searchParam("q") == "a b"` — the value decoded, not
      `a%20b` (the landed stand-in's answer) — and `encoding.formStringify([#("q", "a b")])`, the
      form the router writes back into a URL, is `q=a%20b`; one cell asserts both directions — `test/router_test.bp` "router: a percent-encoded search value is decoded, and written back encoded" (jhonstart `0101ad1`)
- [x] `snapshot()` performs no `?T` unwrap that can fail — `router.bp` `snapshot()`

### Step 3 — The five hooks

```bp
pub fn router() -> @Component<ElementBase, RouterState> {
    return snapshot();
}

pub fn pathname() -> @Component<ElementBase, string> {
    return snapshot().path;
}

pub fn params() -> @Component<ElementBase, Array<#(string, string)>> {
    return snapshot().params;
}

pub fn searchParams() -> @Component<ElementBase, Array<#(string, string)>> {
    return snapshot().search;
}

pub fn selectedLayoutSegment() -> @Component<ElementBase, string> {
    return snapshot().segment();
}

pub fn selectedLayoutSegments() -> @Component<ElementBase, Array<string>> {
    return snapshot().segments();
}
```

**Acceptance:**
- [x] `use pathname()` type-checks inside a `fn … -> @Component<ElementBase, Element>` body — never the doubled `use` + `usePathname()`: the keyword is the activation, the name is the noun; without a `@Component` return the body is `use-without-context-effect` (decisions 118 and 128) — `test/router_test.bp` "router: a component activating the hooks renders the server pass"
- [x] every hook returns `@Component<ElementBase, T>` with the base written (decision 128); `@Component<T>` with one argument is a type-arity error — `router.bp` step 3; the one-argument form is the compiler's arity refusal (front 24)
- [x] `pathname()` called WITHOUT `use` also type-checks and returns the string — the server render calls hooks directly, as `jhonstart-counter`'s `StatefulBadge` does — `test/router_test.bp` "router: each hook answers the field it names, called without `use`"
- [x] `selectedLayoutSegments()` returns the segments root-first — `test/router_test.bp` "router: selectedLayoutSegment(s) answer the layout depth, root-first"
- [x] all six are `pub` — `router.bp` step 3

### Step 4 — Navigation verbs

```bp
#[@External.Node("jhonstart/client-runtime", "navigate"),
  @External.Erlang("jhonstart_router", "navigate")]
declare fn __jhNavigate(kind: string, href: string) -> i32;

pub fn push(href: string) -> i32 { return __jhNavigate("push", href); }
pub fn replace(href: string) -> i32 { return __jhNavigate("replace", href); }
pub fn back() -> i32 { return __jhNavigate("back", ""); }
pub fn forward() -> i32 { return __jhNavigate("forward", ""); }
pub fn refresh() -> i32 { return __jhNavigate("refresh", ""); }
pub fn prefetch(href: string) -> i32 { return __jhNavigate("prefetch", href); }
```

The `-> i32` return is the ecosystem's shape for a host cell whose value is not used
(`rakun/src/runtime.bp` does the same for `rkScan`/`rkEnter`/`rkDone`). It is not a status code and
callers ignore it.

**Acceptance:**
- [ ] `__jhNavigate` is the only dual-target cell in the file, and the README says why
- [x] `push("/x")` on erlang records a redirect and does not raise — `test/router_test.bp` "router: push and replace record what the dispatcher turns into a 307"
- [x] `back()`, `forward()`, `refresh()`, `prefetch()` on erlang are no-ops that return — `test/router_test.bp` "router: the four server no-ops are callable and return"
- [x] a test asserts each verb is callable on the erlang target without a host stub crash — `test/router_test.bp` "router: the four server no-ops are callable and return"

### Step 5 — Module promotion

Delete `router.d.bp`. front 94 owns `src/root.bp` and `botopink.json`'s `files` list; this front hands it the line(s) below rather than editing either file, and front 94 appends in front-number order: `pub mod router;`, and `router.bp` in place of
`router.d.bp` in `files`. `Link` does **not** come along — it moves to front 27's `src/link.bp`.

**Acceptance:**
- [x] `router.d.bp` is gone; `git grep -n "router.d.bp"` finds nothing outside the changelog — `git grep -n "router.d.bp"` in jhonstart finds only `CHANGELOG.md` / `AGENTS.md` history
- [ ] `pub mod router;` and the `files` swap are handed to front 94; this front edits neither
      `src/root.bp` nor `botopink.json`
- [x] `repository/jhonstart/AGENTS.md` records the promotion in the same commit — jhonstart `2bb6fd9`

### Step 6 — `clientApp` (decision 117)

**Acceptance:**
- [x] `clientApp(routes, mount, allowedRedirects).start()` renders the route `window.location`
      matches into `mount`, with the layouts before the page, on `--target commonJS` — `test/client_app_test.bp` "clientApp: start renders the matched route into mount, the layout before the page" (jhonstart `9d7f28d`, `client_app.bp`)
- [x] a page raising `notFound()` renders the route's not-found boundary into `mount` and leaves
      `location.pathname` unchanged — `test/client_app_test.bp` "clientApp: notFound renders the route's not-found boundary and leaves the URL alone"
- [x] a page or layout raising `redirect("/login")`, with `/login` in `routes`, performs
      `history.replaceState` and a client navigation to `/login` with no reload; a layout's
      redirect means the page's function is never called — `test/client_app_test.bp` "clientApp: a relative redirect in routes is a replaceState and a client navigation"; the layout-first order is `compose`'s (front 30 "signal: a layout's redirect means the page never runs")
- [x] `redirect("/nowhere")` (not in `routes`) and `redirect("https://evil.example")` with
      `allowedRedirects` empty fail the render and navigate nowhere; the same absolute target listed
      in `allowedRedirects` is a `location.replace` — `test/client_app_test.bp` "clientApp: an unlisted target fails the start and navigates nowhere; a listed absolute one is location.replace"
- [ ] the late-signal function front 30 registers under `globals.signal` and `clientApp` share one
      handler: a `data-jh-g="redirect"` template and a raised `redirect` with the same target take
      the same path
- [x] `clientApp` reads the table with `routing`'s `parseTable` and matches with `matchPath`; it
      defines neither — through `resolveRoute`

## Examples

- [`examples/active-nav-example.bp`](./examples/active-nav-example.bp) — a sidebar that highlights
  the section the reader is in, using `pathname` and `selectedLayoutSegment`.
- [`examples/search-params-example.bp`](./examples/search-params-example.bp) — a sort control that
  reads `searchParams` and rewrites the URL with `replace`, the shape §8's *History API nativa*
  describes.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| Declared parameter defaults are never applied (`tests/language/expected-failures.txt`, `commonJS \| test/fn_defaults.bp`) | every `Element` builder call in both examples must spell `attrs: []`, inner `text(…)` included | write every argument at every call site | apply the declared default when an argument is omitted |
| No assignment to a `self` field; a record has no in-place update | `push`/`replace` cannot be methods on `RouterState` — they are free functions over a host cell | free functions + an immutable snapshot | a `var` field or a `with`-style copy update |

## Reference gaps

`useSelectedLayoutSegment` and `useSelectedLayoutSegments` [now `selectedLayoutSegment()` / `selectedLayoutSegments()`] do not appear in
`/home/ericfillipe/develop/nextjs/NEXTJS-DOCS.md` — zero hits across all 30 sections. They are
upstream API (https://nextjs.org/docs/app/api-reference/functions/use-selected-layout-segment) and
this front implements them from the upstream page, because active-nav highlighting is the one thing
a router is asked for most and neither `pathname()` nor `params()` answers it for a layout.

## Test plan

`repository/jhonstart/test/router_test.bp`, run by `botopink test --target erlang` from
`repository/jhonstart`, and in the ecosystem gate by
`zig build test-libs -- --target erlang --lib jhonstart`.

Assertions:

1. `RouterState` construction and each accessor, including the absent-key and out-of-range paths.
2. `snapshot()` over a stubbed host module: the five strings in, the record out.
3. `encoding.formParse` / `formStringify` round-trip for `params` and `search`, including empty and
   single-pair inputs and the `a b` ↔ `a%20b` cell (decision 116 rule 4).
6. `navigation.signalFromWire` over the four `n` forms of `contracts.md § 5b` picks the navigation
   the router performs; `refresh()`'s header value is `refreshValue()`.
4. Each hook returns the field it names, called directly (no `use` prefix) so the test runs in a
   plain `botopink test` process — the same technique `jhonstart-counter` uses for `StatefulBadge`.
5. Each navigation verb is callable and returns.
7. `clientApp` (Step 6) on `--target commonJS`: the rendered route, the two signals, the target
   check against `routes` and `allowedRedirects`, and one handler for raised and late signals.

The `commonJS` row is this front's gate for `clientApp` only. The navigation cell builds for both, so its js body is
exercised by front 27's `test/link_test.bp` on the js target; this front's erlang row proves the
snapshot and the hooks, which is what the server render needs. The `use`-prefixed call form is
type-checked, not executed, exactly as `hooks.bp:104-117` does for `Counter`.

### Decisions 113 and 115's spellings

jhonstart names no rakun symbol (decision 113); the matcher is `routing`'s (decision 115).

- [x] `router.bp` imports `parseTable` and `matchPath` from `"routing"` and defines neither; the
      router takes no `match` parameter; no `rakun` identifier appears under
      `modules/jhonstart/src/`, and jhonstart's `botopink.json` lists no `routing` dependency
      (bundled, like std) — `resolveRoute`; `test/router_test.bp` "router: resolveRoute matches with routing's matchPath over the payload's t"
- [x] the payload the client half reads is `globals.payload` (front 30's registry), never a literal
      `__onze` — `hydrate()` / `propsFor` / `readPayload` read `globals().payload` (`__bp0`); no `__onze` literal in the tree

### Decision 116's spellings

- [x] `decodePairs` and `encodePairs` (`router.bp:123-162`) are deleted; `router.bp` and front 28's
      `server.bp` decode with `encoding.formParse` and encode with `encoding.formStringify`, and
      `git grep -n "fn decodePairs\|fn encodePairs"` under `modules/jhonstart/` is empty — jhonstart `0101ad1`
- [x] the `a b` cell above is green on erlang (and on commonJS through front 27's row) — both rows
- [x] an action or refresh envelope's `n` is read with `routing`'s `signalFromWire`; `router.bp`
      defines no `signalFromWire` and no `"R|"` parser of its own — `navigationFor` / `applySignal`; `test/router_test.bp` "router: the four n forms pick the navigation the router performs"
- [x] `refresh()` sends `refreshValue()` imported from `"actions"`; no `"refresh"` header literal
      under `modules/jhonstart/src/` — `test/router_test.bp` "router: refresh() carries actions' refreshValue, spelled nowhere here" (`"refresh"` remains only as the navigation cell's verb name)

## Definition of done

- [ ] `router.d.bp` removed, `router.bp` in the build tree, its `root.bp` and `files` lines handed
      to front 94
- [x] `RouterState`, six hooks, six navigation verbs, `pairValue`, `snapshot` all `pub` and tested — `test/router_test.bp`, 24 blocks
- [ ] `pairValue` is defined once, here, and fronts 28 and 32 cite front 26 for it
- [x] the five cells map one-to-one onto payload keys `p`/`m`/`q`/`r` plus the per-layout
      `selected`, and the mapping table is in `repository/jhonstart/docs.md` — `docs.md` § *The snapshot, the five cells and `fill`*
- [x] `segments` is derived from `pattern`, never transported — `RouterState.segments()` = `patternSegments(self.pattern)`
- [x] the router has no matcher and no table parser of its own; it imports both from `routing` — `router.bp` imports both from `routing`
- [x] the router has no pair codec and no signal-wire decoder of its own: std `encoding` and
      `routing`'s `navigation` (decision 116) — std `encoding`, `routing`'s `navigation`
- [ ] one `#[@External.Node]`-only cell in the file, `__jhMount(selector, html)`, which `clientApp`
      renders through; history goes through `__jhNavigate`, the one dual-target cell
- [x] `clientApp` handles `notFound` / `redirect` in a client-only app as front 30's render does on
      the server, with the same target check (decision 117) — `client_app.bp` `handleSignal`, front 30's `redirectAllowed`
- [x] both language gaps appear in a `specs/1.0.10-beta/` spec — `language-gaps.md` rows "Declared parameter defaults are never applied" and "No assignment to a `self` field"
- [x] the front's tests are green on its assigned target — core 187/187 on erlang and commonJS (`router_test.bp` 29, `client_app_test.bp` 4)

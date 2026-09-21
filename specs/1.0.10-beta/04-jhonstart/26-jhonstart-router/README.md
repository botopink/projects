# Front 26 — Jhonstart Router

**Track:** C jhonstart
**Priority:** critical — nothing downstream can ask "which route is this?"; `Link`, server components, streaming, error boundaries and metadata all read the answer this front produces
**Target:** erlang (server)
**Boundary:** the route snapshot is one of the three things `overview.md` says crosses. The server matches and fills it; the client rebuilds it from front 23's `__onze` payload after a client navigation. The payload envelope and the route table are **not** defined here — they are fronts 23 and 22; this front consumes both.
**Wave:** 3
**Depends on:** 01 · 22 (route table + `matchPath`, read-only) · 23 (payload envelope, read-only) · 94 (element builders used by the examples)
**Owns:** `repository/jhonstart/src/router.bp` (promoted from `router.d.bp`, and the package's one `pairValue` pair-list decoder), `repository/jhonstart/test/router_test.bp`
**Does not touch:** `src/element.bp`, `src/hooks.bp`, `src/html.bp` (frozen), `src/link.bp` (front 27), `src/server.bp` (front 28), `src/root.bp` and `botopink.json` (front 94)
**Reference:** `NEXTJS-DOCS.md § 8. Navegação e Linking` · `§ 26. Referência de Funções` · https://nextjs.org/docs/app/api-reference/functions/use-router · https://nextjs.org/docs/app/api-reference/functions/use-params · https://nextjs.org/docs/app/api-reference/functions/use-search-params
**Replaces:** `1.0.7-beta/02-jhonstart-router`

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

The second problem is one the 1.0.7 draft did not see. That draft made every navigation verb a
method on `Router` (`push`, `replace`) whose implementation mutated the record. botopink records are
immutable and there is no assignment to a `self` field anywhere in the tree; `dict.insert` returning
a new dict is the ecosystem's shape. So navigation cannot be a method at all — it is a call against
host state, and the record is a read-only snapshot of that state.

## Current state

- `src/router.d.bp` — 28 lines, declaration-only: `behavior Router` with `pathname`/`params`/`push`/
  `replace` (`:17-22`), `useRouter()` (`:24-25`), `Link()` (`:27-28`). Both cells are
  `#[@External.Node]` — Node-only, which the milestone's target split forbids for a server front.
- `src/root.bp:15-17` declares exactly three modules: `element`, `hooks`, `html`. `router` is not
  one of them.
- `botopink.json` ships `router.d.bp` in `files` as a declaration.
- `libs/std/src/querystring.bp:35,48` already has `parse(query) -> Array<#(string, string)>` and
  `stringify(pairs) -> string`, pure botopink on every backend. That is the snapshot encoding.
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

`router.bp` defines `RouterState`, a plain record with five fields and no behavior. The 1.0.7 draft
kept `behavior Router` and had `RouterState implement Router`; this front drops the behavior. A
behavior with `val` members has no verified implementor anywhere in the tree, and a concrete record
is what the `use` capability has to yield anyway — the indirection buys nothing and risks a
construct nobody has exercised.

The snapshot is filled from five `#[@External.Erlang]` cells that read what front 22 put in the
request's process dictionary before dispatch. Every one of them returns a `string`, and each maps
one-to-one onto a key of front 23's payload envelope, so the server record and the client record are
built from the same five values:

| `RouterState` field | cell | payload key (front 23) |
|---|---|---|
| `path` | `__jhRoutePath()` | `p` — pathname |
| `params` | `__jhRouteParams()` | `m` — querystring-encoded |
| `search` | `__jhRouteSearch()` | `q` — querystring-encoded |
| `pattern` | `__jhRoutePattern()` | `r` — the matched pattern, bracket spelling kept |
| `selected` | `__jhRouteSelected()` | — per-layout, supplied by front 23 during the render |

`segments` is **derived**, not transported: it is `pattern` split on `/` with the empty parts
dropped. One value, one source; a transported segment list could disagree with the pattern it came
from.

The two pair-shaped values are decoded with `querystring.parse`
(`libs/std/src/querystring.bp:35`) on both sides. No JSON, no record serialization, nothing that has
to agree between an Erlang term and a JS object.

### The route table is front 22's, and there is one parser

`matchPath`, `parseTable` and `writeTable` are front 22's, written once in botopink and compiled
twice. The table is line-oriented (`kind|pattern|slot|verb`, kinds `L T P D R S E N`) and travels in
the payload's `t` key. This front **calls** `matchPath`; it does not contain a second matcher and
does not parse the table itself. A router with its own matcher is a router that disagrees with the
server on precedence (static > dynamic > catch-all > optional catch-all), and the disagreement shows
up only on the routes nobody tested.

The five hooks are thin. Each returns `@Context<Element, T>`, which is what makes `use` legal on it
inside a `#[@context]` body whose owner is `Element` — the same capability `hooks.bp` uses for `state`/`memo`
(`hooks.bp:30-60`).

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
path, so the payload endpoint and its revalidation semantics are front 23/24's, and this front only
calls it.

Native History API use is also supported: the browser half listens for `popstate` and for a
`pushState` the application performs itself (`NEXTJS-DOCS.md § 8`, *History API nativa*), rebuilds
`RouterState` by running front 22's `matchPath` against `window.location` and the table in the
payload's `t` key, and re-renders. Because the rebuild goes through the same matcher and the same
`querystring.parse`, `searchParams()` reacts to a bare `pushState` without a reload, without a
second parser, and without a second precedence rule.

### What crosses

One direction, one format. The server writes `p`, `m`, `q`, `r` and `t` into the `__onze` payload
front 23 serializes; the client reads them on hydration and recomputes `p`/`m`/`q`/`r` from `t` on
every transition. A component sees `RouterState` and cannot tell which side it is on.

## Steps

### Step 1 — `RouterState` and its accessors

Field names and method names are kept disjoint (`params` the field, `param(name)` the method) so a
record field never shadows a method.

```bp
// src/router.bp
import {Element} from "element";
import {querystring} from "std";

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
- [ ] `RouterState(path: "/blog/hi", params: [#("slug", "hi")], search: [], pattern: "/blog/[slug]", selected: 0).param("slug") == "hi"`
- [ ] `param` of an absent key is `""`, not a runtime error
- [ ] `pairValue` is `pub` and is the only pair-list decoder in the package: fronts 28 and 32 import
      it, and `git grep -n "fn pairValue"` finds exactly one definition
- [ ] `pairValue` of a duplicated key returns the first match, and the test asserts it
- [ ] `segments()` of `"/blog/[slug]"` is `["blog", "[slug]"]` — the bracket spelling is kept
- [ ] `segment()` of an out-of-range `selected` is `""`
- [ ] no field of `RouterState` shares a name with a method of `RouterState`

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
        params: querystring.parse(__jhRouteParams()),
        search: querystring.parse(__jhRouteSearch()),
        pattern: __jhRoutePattern(),
        selected: __jhRouteSelected(),
    );
}
```

**Acceptance:**
- [ ] all five cells are `#[@External.Erlang]`; none is `#[@External.Node]`
- [ ] `snapshot()` of `("/blog/hi", "slug=hi", "", "/blog/[slug]", 0)` round-trips to the record in step 1
- [ ] each cell maps to exactly one payload key, and the mapping table is in `docs.md`
- [ ] an empty params string yields `[]`, not `[#("", "")]`
- [ ] `snapshot()` performs no `?T` unwrap that can fail

### Step 3 — The five hooks

```bp
pub fn router() -> @Context<Element, RouterState> {
    return snapshot();
}

pub fn pathname() -> @Context<Element, string> {
    return snapshot().path;
}

pub fn params() -> @Context<Element, Array<#(string, string)>> {
    return snapshot().params;
}

pub fn searchParams() -> @Context<Element, Array<#(string, string)>> {
    return snapshot().search;
}

pub fn selectedLayoutSegment() -> @Context<Element, string> {
    return snapshot().segment();
}

pub fn selectedLayoutSegments() -> @Context<Element, Array<string>> {
    return snapshot().segments();
}
```

**Acceptance:**
- [ ] `use pathname()` type-checks inside a `#[@context] fn … -> Element` body — never the doubled `use` + `usePathname()`: the keyword is the activation, the name is the noun; without the annotation the body is `use-without-context-effect` ([`19-use-activation`](../../00-compiler-carry-over/19-use-activation/README.md))
- [ ] `pathname()` called WITHOUT `use` also type-checks and returns the string — the server render calls hooks directly, as `jhonstart-counter`'s `StatefulBadge` does
- [ ] `selectedLayoutSegments()` returns the segments root-first
- [ ] all six are `pub`

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
- [ ] `push("/x")` on erlang records a redirect and does not raise
- [ ] `back()`, `forward()`, `refresh()`, `prefetch()` on erlang are no-ops that return
- [ ] a test asserts each verb is callable on the erlang target without a host stub crash

### Step 5 — Module promotion

Delete `router.d.bp`. front 94 owns `src/root.bp` and `botopink.json`'s `files` list; this front hands it the line(s) below rather than editing either file, and front 94 appends in front-number order: `pub mod router;`, and `router.bp` in place of
`router.d.bp` in `files`. `Link` does **not** come along — it moves to front 27's `src/link.bp`.

**Acceptance:**
- [ ] `router.d.bp` is gone; `git grep -n "router.d.bp"` finds nothing outside the changelog
- [ ] `pub mod router;` and the `files` swap are handed to front 94; this front edits neither
      `src/root.bp` nor `botopink.json`
- [ ] `repository/jhonstart/AGENTS.md` records the promotion in the same commit

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
3. `querystring.parse` round-trip for `params` and `search`, including empty and single-pair inputs.
4. Each hook returns the field it names, called directly (no `use` prefix) so the test runs in a
   plain `botopink test` process — the same technique `jhonstart-counter` uses for `StatefulBadge`.
5. Each navigation verb is callable and returns.

The `commonJS` row is not this front's gate. The navigation cell builds for both, so its js body is
exercised by front 27's `test/link_test.bp` on the js target; this front's erlang row proves the
snapshot and the hooks, which is what the server render needs. The `use`-prefixed call form is
type-checked, not executed, exactly as `hooks.bp:104-117` does for `Counter`.

## Definition of done

- [ ] `router.d.bp` removed, `router.bp` in the build tree, its `root.bp` and `files` lines handed
      to front 94
- [ ] `RouterState`, six hooks, six navigation verbs, `pairValue`, `snapshot` all `pub` and tested
- [ ] `pairValue` is defined once, here, and fronts 28 and 32 cite front 26 for it
- [ ] the five cells map one-to-one onto payload keys `p`/`m`/`q`/`r` plus the per-layout
      `selected`, and the mapping table is in `repository/jhonstart/docs.md`
- [ ] `segments` is derived from `pattern`, never transported
- [ ] the router calls front 22's `matchPath` and contains no second matcher and no table parser
- [ ] no `#[@External.Node]`-only cell in the file; the one dual-target cell is `__jhNavigate`
- [ ] both language gaps appear in a `specs/1.0.10-beta/` spec
- [ ] the front's tests are green on its assigned target

## Carried from 1.0.7-beta F02 jhonstart-router

Items of the 1.0.7 draft not restated above, quoted so nothing is lost; where the milestone decided differently the 1.0.9 decision stands and the old text is kept for the record.

### Examples — `useRouter` as the one hook, `pathname()` / `params().get()` (different decision)

`1.0.7-beta/02-jhonstart-router/README.md § Examples in bp` (the draft's `useRouter` [now `router()`]). The draft read the path and the params through methods of a `Router` behavior, with `params` a `Dict<string, string>`. Front 26 has `pathname()` / `RouterState.path`, `param(name)` over `Array<#(string, string)>`, and no `.get`. The two blocks are respelled under the `use` rule — the draft's `use`-prefixed `useRouter()` call → `use router()`, binding `r` — and keep the draft's call shape (`r.pathname()`, `r.params().get()`) as the record.

```bp
#[client]
import {router} from "jhonstart";

#[@context]
pub fn Breadcrumb() -> Element {
    val r = use router();
    return div([span([text("Path: " + r.pathname())])], attrs: []);
}
```

```bp
#[@context]
pub fn BlogPost() -> Element {
    val r = use router();
    val slug = r.params().get("slug");
    return div([h1([text("Post: " + slug)])], attrs: []);
}
```

### Mechanism — behavior + one host cell per target + navigation as methods (different decision)

`1.0.7-beta/02-jhonstart-router/README.md § Mechanism`. Old text:

> Promote `router.d.bp` → `router.bp` with a real implementation:
> - `Router` behavior gets a concrete type `RouterState` holding pathname + params
> - `useRouter()` [now `router()`] returns `@Context<Element, Router>` backed by a host cell (commonJS: module-global state; erlang: process dictionary)
> - Navigation (`push`/`replace`) updates the host cell
> - The host runtime (rakun SSR pipeline, F09) provides the initial Router state from the HTTP request

| Old item | Front 26 decision |
|---|---|
| `Router` behavior with `RouterState` implementor | behavior dropped; `RouterState` is a plain five-field record (§ Mechanism, *The erlang half*) |
| `@Context<Element, Router>` | `@Context<Element, RouterState>` (§ Step 3) |
| commonJS host cell = module-global state | client rebuilds the snapshot from front 23's `__onze` payload / `window.location` via `matchPath` (§ *Native History API*, § *What crosses*) |
| erlang host cell = process dictionary | kept: five `#[@External.Erlang]` cells read the request's process dictionary (§ Step 2) |
| `push`/`replace` mutate the host cell | free functions over `__jhNavigate(kind, href)`; on erlang they record a 307 redirect (§ Step 4) |
| initial state from rakun SSR pipeline (F09) | fronts 22 (match) and 23 (payload) fill it; the front numbering changed |

### Step 1 — `RouterState implement Router` with `Dict` fields and four methods (different decision)

`1.0.7-beta/02-jhonstart-router/README.md § Step 1 — Concrete RouterState type`

```bp
// src/router.bp
import {Element} from "element";

pub type RouterState(
    pathname: string,
    params: Dict<string, string>,
    searchParams: Dict<string, string>,
) implement Router

pub fn pathname(self: Self) -> string { return self.pathname; }
pub fn params(self: Self) -> Dict<string, string> { return self.params; }
pub fn push(self: Self, href: string) { routerPush(href); }
pub fn replace(self: Self, href: string) { routerReplace(href); }
```

Old acceptance: `RouterState` implements `Router` behavior · all 4 methods have real bodies · compiles on commonJS + erlang. Front 26: no behavior; fields `path`/`params`/`search`/`pattern`/`selected` with `param`/`searchParam`/`segments`/`segment` methods; target erlang only (the commonJS row is not this front's gate).

### Step 2 — `onze13/runtime` cells, dual-target, three verbs (different decision; one item absent)

`1.0.7-beta/02-jhonstart-router/README.md § Step 2 — Host cells for navigation`

```bp
// In router.bp
#[@External.Node("onze13/runtime", "routerPush")]
#[@External.Erlang("onze13_runtime", "router_push")]
declare fn routerPush(href: string) -> void;

#[@External.Node("onze13/runtime", "routerReplace")]
#[@External.Erlang("onze13_runtime", "router_replace")]
declare fn routerReplace(href: string) -> void;

#[@External.Node("onze13/runtime", "routerGetState")]
#[@External.Erlang("onze13_runtime", "router_get_state")]
declare fn routerGetState() -> RouterState;
```

| Old item | Front 26 |
|---|---|
| host module `onze13/runtime` / `onze13_runtime` | `jhonstart_router` (erlang) and `jhonstart/client-runtime` (js) |
| `routerGetState() -> RouterState` as a host cell | `snapshot()` is pure botopink over five `string`/`i32` cells; no record crosses the host boundary |
| `routerPush`/`routerReplace` as two cells | one dual-target `__jhNavigate(kind, href) -> i32` |
| `-> void` cells | `-> i32`, the ecosystem's shape for an unused host value |
| acceptance "Host cells declared for both targets" | only `__jhNavigate` is dual-target; the five read cells are erlang-only |
| acceptance "`botopink check` passes" | **absent** — not restated as a gate |

### Step 3 — `useRouter() -> @Context<Element, Router>` (different decision)

`1.0.7-beta/02-jhonstart-router/README.md § Step 3 — useRouter hook` [now `router()`]

```bp
pub fn router() -> @Context<Element, Router> {
    return routerGetState();
}
```

Old acceptance: returns `@Context<Element, Router>` · usable with `use` prefix in components · test `val r = useRouter(); r.pathname()` returns current path. Front 26: returns `@Context<Element, RouterState>` from `snapshot()`; the `use` form is type-checked; `r.pathname()` has no equivalent — the path is `r.path` or `pathname()`.

### Step 4 — this front edits `botopink.json` and `root.bp` (different decision; one item absent)

`1.0.7-beta/02-jhonstart-router/README.md § Step 4 — Remove router.d.bp`

> Delete `router.d.bp` (replaced by `router.bp`). Update `botopink.json` `files` list. Update `root.bp` to include `pub mod router;`.

Front 26 deletes `router.d.bp` but hands the `pub mod router;` line and the `files` swap to front 94 and edits neither file. Old acceptance "All existing tests still pass" is **absent** — front 26 asserts only "the front's tests are green on its assigned target".

### Step 5 — tests built on `dict` (different decision)

`1.0.7-beta/02-jhonstart-router/README.md § Step 5 — Tests`

```bp
test "RouterState holds pathname and params" {
    val r = RouterState(pathname: "/blog/hello", params: dict.fromList([#("slug", "hello")]), searchParams: dict.empty());
    assert r.pathname() == "/blog/hello";
    assert r.params() == dict.fromList([#("slug", "hello")]);
}
```

Old acceptance: construction and method access tested · tests pass on commonJS + erlang. Front 26: pair-list construction (`params: [#("slug", "hi")]`), `param("slug") == "hi"`, absent-key `""`; erlang row only.

### Gate (different decision; one item absent)

`1.0.7-beta/02-jhonstart-router/README.md § Gate`

| Old gate line | Front 26 |
|---|---|
| `botopink test` green (commonJS + erlang) | `botopink test --target erlang`; commonJS is exercised through front 27's `test/link_test.bp` |
| `router.d.bp` removed, `router.bp` in its place | present (§ Step 5, § Definition of done) |
| `botopink.json` and `root.bp` updated | handed to front 94 |
| AGENTS.md updated | present (§ Step 5 acceptance) |
| Commit on `fix/jhonstart-router` | **absent** — no branch name in the new README |

### Blast radius (two items absent / different)

`1.0.7-beta/02-jhonstart-router/README.md § Blast radius`

> - `router.d.bp` → `router.bp` promotion: no API change for consumers (same `from "jhonstart"` import)
> - `botopink.json` files list changes
> - `root.bp` gains `pub mod router;`
> - Examples that used `router.d.bp` declarations still compile

The first bullet is **superseded**: consumers do see an API change (`Router` behavior gone, `router.pathname()` → the `pathname()` hook / `RouterState.path`, `params()` Dict → `param(name)` over pairs, `push`/`replace` free functions, `Link` moved to front 27). The last bullet is **absent** and no longer holds for the same reason. Bullets 2–3 are present as the hand-off to front 94.

### Notes (different decision)

`1.0.7-beta/02-jhonstart-router/README.md § Notes`

> - The actual navigation (push/replace) is a no-op during SSR — the host runtime (rakun) provides the initial state. Client-side navigation is the browser runtime's job (recorded follow-up for client hydration).
> - `Router` behavior stays the same interface — only the implementation changes from declaration to concrete.

Front 26: `push`/`replace` on erlang **record a 307 redirect** on the response (only `back`/`forward`/`refresh`/`prefetch` are server no-ops); client-side navigation is in-milestone (fronts 27 and 29), not a follow-up; the `Router` behavior is dropped, not kept.

### Reference rows from 1.0.7 overview/fronts

| Source | Row | In front 26? |
|---|---|---|
| `overview.md` § front table | `02-jhonstart-router/` · **critical** · jhonstart · jhonstart-core · "Real router (useRouter, pathname, params, push/replace) — promote router.d.bp → .bp" | substance yes; `push`/`replace` are free functions, not `Router` methods |
| `overview.md` § Next.js → onze13 mapping | `next/navigation (useRouter)` → `useRouter behavior` → jhonstart | different: `router()` [Next's `useRouter`] yields the `RouterState` record; no behavior; `pathname`/`params`/`searchParams`/`selectedLayoutSegment(s)` added |
| `overview.md` § dependency sketch | `… ──► 02-jhonstart-router ──┐ ├──► 03-jhonstart-link` | present as front 27 **Depends on:** 26 |
| `fronts.md` § ownership | F02 · jhonstart · jhonstart-core · owns `repository/jhonstart/src/router.bp` (promote from .d.bp) · tests `repository/jhonstart/test/router_test.bp` | present in **Owns** (both paths) |
| `fronts.md` § Conflict Notes 1 | "F02 ↔ F03: Both touch `router.d.bp`/`router.bp` (F02 promotes it to real .bp, F03 adds Link). Sequence: F02 first (router foundation), then F03 (Link uses router)." | substance present (26 deletes `router.d.bp`; 27 "adds nothing to it and reads nothing from it"); the note itself is not restated |
| `fronts.md` § dependency graph / critical path | `F17 ──┴──► F02 ──┐ └──► F03 · F04 · F09 (3 in parallel)`; critical path `F01 → F02 → F03/F04/F09`; Phase 1 `F01 ∥ F17, then F02 ∥ F14, then F03 ∥ F04 ∥ F09` | absent; replaced by **Wave:** 1 and **Depends on:** 01 · 22 · 23 · 94 |
| `README.md` header | **Depends on:** F01 (onze13-stand-up) | present as `01` |
| `README.md` header | **Does not touch:** `server.d.bp` | not listed; `src/server.bp` (front 28) is |

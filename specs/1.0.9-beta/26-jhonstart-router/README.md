# Front 26 — Jhonstart Router

**Track:** C jhonstart
**Priority:** critical — nothing downstream can ask "which route is this?"; `Link`, server components, streaming, error boundaries and metadata all read the answer this front produces
**Target:** erlang (server)
**Boundary:** the route snapshot is one of the three things `overview.md` says crosses. The server matches and fills it; the client rebuilds it from front 23's `__onze` payload after a client navigation. The payload envelope and the route table are **not** defined here — they are fronts 23 and 22; this front consumes both.
**Wave:** 1
**Depends on:** 01 · 22 (route table + `matchPath`, read-only) · 23 (payload envelope, read-only)
**Owns:** `repository/jhonstart/src/router.bp` (promoted from `router.d.bp`), `repository/jhonstart/test/router_test.bp`
**Does not touch:** `src/element.bp`, `src/hooks.bp`, `src/html.bp` (frozen), `src/link.bp` (front 27), `src/server.bp` (front 28)
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
inside a `-> Element` body — the same capability `hooks.bp` uses for `state`/`memo`
(`hooks.bp:30-60`).

### The js half — front 27 and front 29

The four navigation verbs (`push`, `replace`, `back`, `forward`, `refresh`, `prefetch`) are declared
here because `useRouter()` is where a developer reaches for them, but their bodies are host cells
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
`querystring.parse`, `useSearchParams` reacts to a bare `pushState` without a reload, without a
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

pub fn pairValue(pairs: Array<#(string, string)>, name: string) -> string {
    val hit = pairs.find({ p -> p._0 == name });
    val fallback = #("", "");
    return hit.unwrapOr(fallback)._1;
}
```

**Acceptance:**
- [ ] `RouterState(path: "/blog/hi", params: [#("slug", "hi")], search: [], pattern: "/blog/[slug]", selected: 0).param("slug") == "hi"`
- [ ] `param` of an absent key is `""`, not a runtime error
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
pub fn useRouter() -> @Context<Element, RouterState> {
    return snapshot();
}

pub fn usePathname() -> @Context<Element, string> {
    return snapshot().path;
}

pub fn useParams() -> @Context<Element, Array<#(string, string)>> {
    return snapshot().params;
}

pub fn useSearchParams() -> @Context<Element, Array<#(string, string)>> {
    return snapshot().search;
}

pub fn useSelectedLayoutSegment() -> @Context<Element, string> {
    return snapshot().segment();
}

pub fn useSelectedLayoutSegments() -> @Context<Element, Array<string>> {
    return snapshot().segments();
}
```

**Acceptance:**
- [ ] `use usePathname()` type-checks inside a `fn … -> Element` body
- [ ] `usePathname()` called WITHOUT `use` also type-checks and returns the string — the server render calls hooks directly, as `jhonstart-counter`'s `StatefulBadge` does
- [ ] `useSelectedLayoutSegments()` returns the segments root-first
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

Delete `router.d.bp`; add `pub mod router;` to `src/root.bp`; replace `router.d.bp` with `router.bp`
in `botopink.json` `files`. `Link` does **not** come along — it moves to front 27's `src/link.bp`.

**Acceptance:**
- [ ] `router.d.bp` is gone; `git grep -n "router.d.bp"` finds nothing outside the changelog
- [ ] `src/root.bp` declares `pub mod router;`
- [ ] `botopink.json` `files` lists `router.bp` and no longer lists `router.d.bp`
- [ ] `repository/jhonstart/AGENTS.md` records the promotion in the same commit

## Examples

- [`examples/active-nav-example.bp`](./examples/active-nav-example.bp) — a sidebar that highlights
  the section the reader is in, using `usePathname` and `useSelectedLayoutSegment`.
- [`examples/search-params-example.bp`](./examples/search-params-example.bp) — a sort control that
  reads `useSearchParams` and rewrites the URL with `replace`, the shape §8's *History API nativa*
  describes.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| Declared parameter defaults are never applied (`tests/language/expected-failures.txt`, `commonJS \| test/fn_defaults.bp`) | every `Element` builder call in both examples must spell `attrs: []`, inner `text(…)` included | write every argument at every call site | apply the declared default when an argument is omitted |
| No assignment to a `self` field; a record has no in-place update | `push`/`replace` cannot be methods on `RouterState` — they are free functions over a host cell | free functions + an immutable snapshot | a `var` field or a `with`-style copy update |

## Reference gaps

`useSelectedLayoutSegment` and `useSelectedLayoutSegments` do not appear in
`/home/ericfillipe/develop/nextjs/NEXTJS-DOCS.md` — zero hits across all 30 sections. They are
upstream API (https://nextjs.org/docs/app/api-reference/functions/use-selected-layout-segment) and
this front implements them from the upstream page, because active-nav highlighting is the one thing
a router is asked for most and neither `usePathname` nor `useParams` answers it for a layout.

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

- [ ] `router.d.bp` removed, `router.bp` in the build tree, `root.bp` and `botopink.json` updated
- [ ] `RouterState`, six hooks, six navigation verbs, `pairValue`, `snapshot` all `pub` and tested
- [ ] the five cells map one-to-one onto payload keys `p`/`m`/`q`/`r` plus the per-layout
      `selected`, and the mapping table is in `repository/jhonstart/docs.md`
- [ ] `segments` is derived from `pattern`, never transported
- [ ] the router calls front 22's `matchPath` and contains no second matcher and no table parser
- [ ] no `#[@External.Node]`-only cell in the file; the one dual-target cell is `__jhNavigate`
- [ ] both language gaps appear in a `specs/1.0.10-beta/` spec
- [ ] the front's tests are green on its assigned target

# Front 27 — Jhonstart Link

**Track:** C jhonstart
**Priority:** critical — without `Link` every navigation is a full page load, and the client half of the milestone has nothing to intercept
**Target:** js (client)
**Wave:** 4
**Depends on:** 26 · 60 (route-kind flag, read-only) · 23 (payload envelope, read-only) · 68 (generated entry + DOM primitives, read-only) · 94 (element builders used by the examples)
**Owns:** `repository/jhonstart/src/link.bp`, `repository/jhonstart/src/reconcile.bp` (the client-navigation reconciler), `repository/jhonstart/test/link_test.bp`, `repository/jhonstart/test/reconcile_test.bp`
**Does not touch:** `src/element.bp`, `src/hooks.bp`, `src/html.bp` (frozen), `src/router.bp` (front 26), `src/client.bp` (front 29), `src/root.bp` and `botopink.json` (front 94)
**Reference:** `NEXTJS-DOCS.md § 8. Navegação e Linking` · `§ 25. Referência de Componentes` · https://nextjs.org/docs/app/api-reference/components/link · https://nextjs.org/docs/app/getting-started/linking-and-navigating
**Replaces:** `1.0.7-beta/03-jhonstart-link`

---

## Problem

`Link` exists as one line of declaration: `pub declare fn Link(href: string, children: fn() ->
Children) -> Element;` behind `#[@External.Node("jhonstart/runtime", "link")]`
(`router.d.bp:27-28`). Its own file explains why it never became real: "`Link` must render `<a
href=…>`, but the `Element` model is `tag`/`value`/`children` with NO attribute slot … A real `.bp`
`Link` would silently drop `href`" (`router.d.bp:12-15`). That reason expired. `Element` carries
`attrs: Array<#(string, string)>` (`element.bp:7`) and `renderToString` emits every pair as
`name="value"` (`element.bp:62-66`). An anchor with an href is four lines of ordinary botopink.

What is still missing is everything around the anchor. A `<Link>` is not a styled `<a>`; it is the
entry point to client-side transitions. It prefetches when it enters the viewport, it decides
*whether* to prefetch based on whether the target route is static or dynamic, it swaps the page
without a reload and without remounting shared layouts, and it exposes whether its own navigation is
still in flight so the link can show a spinner. None of that exists, and none of it can be faked by
a host stub that returns an `Element`.

The 1.0.7 draft also wrote `Link("/about", [text("About")])` and
`Link("/blog", [text("Blog")], prefetch: false, attrs: [])` — six parameters with five defaults.
Declared parameter defaults are never applied (`tests/language/expected-failures.txt`), so every one
of those call sites would have to spell all six arguments. That is not an API anyone writes twice.

## Current state

- `src/router.d.bp:27-28` — the one-line `declare fn Link`, Node-only, gated.
- `src/element.bp:3-8` — `Element` with `attrs`; `:55-67` — `renderToString` renders them.
- `src/element.bp:10-12` — `bracketPair(name, value) -> #(string, string)`, the pair constructor.
- `repository/jhonstart/examples/jhonstart-app/app/page.bp` uses `Link("/posts/1") { "first post" }`
  — a brace-call form that does not parse today. The whole example is marked
  "⛔ GATED / ASPIRATIONAL EXAMPLE — does not build yet" in its own header.
- No prefetch, no client route cache, no navigation status anywhere in the repository.

## Mechanism

Next.js splits `<Link>` into a render-time part and a runtime part. The render-time part emits an
anchor with the props encoded on it; the runtime part, in the browser, intercepts the click,
prefetches on viewport entry, and performs the transition (`NEXTJS-DOCS.md § 8`). jhonstart keeps
that split, and it is what lets a client front render correctly during the server pass.

### The render half — pure botopink, no host

`Link` is an ordinary function returning `Element(tag: "a", …)`. It touches no host cell, so it
produces the same anchor on every backend, including during front 23's server render. The props
travel to the browser as `data-` attributes on the anchor itself — there is no second channel and no
registry the server has to serialize.

| Prop | Attribute emitted | Emitted when |
|---|---|---|
| `href` | `href="…"` | always |
| — | `data-onze-l="1"` | always — this is what the runtime queries for |
| `prefetch` | `data-onze-prefetch="0"` | only when `false`; absent means "decide by route kind" |
| `replace` | `data-onze-replace="1"` | only when `true` |
| `scroll` | `data-onze-scroll="0"` | only when `false` |
| `target` | `target="…"` | only when non-empty |
| `className` | `class="…"` | only when non-empty |

Attributes are emitted only when they differ from the default, so the common link is
`<a href="/blog" data-onze-l="1">Blog</a>` and the HTML does not carry five redundant pairs per
link on a page with two hundred of them.

Because declared defaults are not applied, the props are a record and `linkProps(href)` is the
constructor that fills the Next defaults. Overriding one is `withPrefetch(props, false)` — a helper
that returns a new record, since there is no assignment to a `self` field. The call site reads
`Link(withPrefetch(linkProps(href), false), children)`, which is the honest cost of the gap and
still shorter than spelling six arguments.

The `data-onze-` prefix is the milestone's marker family — front 23's islands and streaming holes
use it (`contracts.md § 2`). This front owns the link markers inside it and nothing else; the
attribute names above are the whole vocabulary it adds.

### The runtime half — the browser, `#[@External.Node]` only

Four cells, all Node, none with an erlang twin, because none of them means anything on a server:

- `__onzeLinkMount()` — delegated click interception plus an intersection observer over every
  `[data-onze-l]`. The entry module **front 68 generates** calls it once, after it has hydrated the
  islands, alongside one call to front 67's `__jhFormMount()`. Front 29 owns the per-island hydrate
  point, not the entry, and does not call this.
- `__onzeLinkPrefetch(href, mode)` — warms the client route cache. `mode` is `"full"`, `"partial"` or
  `"skip"`.
- `__onzeLinkStatus() -> string` — the href of the navigation currently in flight, `""` when idle.
- `__onzeLinkRouteKind(href) -> string` — `"static"`, `"dynamic"` or `"unknown"`, read from the
  route-kind table **front 60** emits into the client bundle.

### Prefetch strategy

`NEXTJS-DOCS.md § 8` *Prefetching* states the rule and this front implements it literally, as a pure
function so that it is testable without a browser:

| Route kind | `loading` boundary present | Mode |
|---|---|---|
| static | — | `full` — the whole route is prefetched |
| dynamic | yes | `partial` — prefetch up to the nearest `loading` boundary |
| dynamic | no | `skip` |
| any | `prefetch: false` | `skip` |

`prefetchMode(kind, hasLoading, requested)` is the function; `__onzeLinkPrefetch` is the consumer. The
two inputs `kind` and `hasLoading` both come from front 60's table, which is why this front depends
on it read-only and owns none of it.

The route the prefetcher resolves an href against is the table in the payload's `t` key, matched
with front 22's `matchPath` (`contracts.md § 1`). There is one matcher in the milestone and this
front is not a second one.

### Layout state preservation

A client transition must not remount a layout the two routes share, or the sidebar scroll position
and every client component's state inside it are lost (`NEXTJS-DOCS.md § 5`, *Características dos
layouts*: "Preservam estado entre navegações"). The reconciler keys a layout by its **segment
path** — the `/`-joined prefix of the route's segments down to that layout's depth — not by its
position in the tree. Two routes under `/docs` produce the same key `"/docs"` for the docs layout,
so it is reused; a route under `/blog` produces `"/blog"` and the docs layout is unmounted.

`layoutKey(segments, depth)` is pure, and **this front also owns the reconciler that consumes it**.
Front 68 declined it and was right to: front 68 builds a bundle, and diffing two route trees is
navigation behaviour, not packaging. Track C has exactly three js-side fronts — 27, 29 and 67 — and
of those only this one already owns a transition.

The reconciler (`src/reconcile.bp`) is the client half of a navigation, and it is four steps:

1. Compute `layoutKey(segments, depth)` for every depth of the **current** route and of the
   **target** route. Segments come from front 26's `RouterState.segments()`, derived from the matched
   pattern — so the key a client transition computes and the key the server rendered under are the
   same string.
2. Find the deepest depth at which the two key lists agree. Everything above it is shared and is
   left mounted, with its DOM and its islands untouched.
3. Unmount the current route's subtree below that depth, and mount the target's from the payload the
   prefetcher already has — or fetch it, with front 60's route-kind flag deciding whether a fetch
   was needed at all.
4. Adopt `data-onze-s` slots as-is (front 29's rule) and re-anchor `data-onze-e` boundaries
   (front 31's), because both are keyed to the response and not to the layout.

The reconciler touches no host cell of its own: it drives `__onzeLinkPrefetch` and front 68's DOM
primitives, and everything it decides is a pure function of two key lists.

### `linkStatus`

`linkStatus()` returns `LinkStatus(pending: bool, href: string)` from `__onzeLinkStatus()`, so a
link can render a spinner while its own navigation is in flight. It is a hook —
`@Context<Element, LinkStatus>` — and is legal under `use` inside a `#[@context] fn … -> Element` body, the same
capability `hooks.bp` uses.

## Steps

### Step 1 — `LinkProps` and its builders

```bp
// src/link.bp
import {Element} from "element";

pub type LinkProps(
    href: string,
    prefetch: bool,
    replace: bool,
    scroll: bool,
    target: string,
    className: string,
)

pub fn linkProps(href: string) -> LinkProps {
    return LinkProps(
        href: href,
        prefetch: true,
        replace: false,
        scroll: true,
        target: "",
        className: "",
    );
}

pub fn withPrefetch(p: LinkProps, prefetch: bool) -> LinkProps {
    return LinkProps(
        href: p.href,
        prefetch: prefetch,
        replace: p.replace,
        scroll: p.scroll,
        target: p.target,
        className: p.className,
    );
}
```

`withReplace`, `withScroll`, `withTarget`, `withClass` follow the same shape.

**Acceptance:**
- [ ] `linkProps("/x")` yields Next's documented defaults: prefetch true, replace false, scroll true
- [ ] each `with*` helper changes exactly one field and copies the other five
- [ ] no helper assigns to a field of its argument

### Step 2 — `Link`

```bp
#[@context]
pub fn Link(props: LinkProps, children: Children) -> Element {
    var pairs: Array<#(string, string)> = [#("href", props.href), #("data-onze-l", "1")];
    if (!props.prefetch) pairs = pairs.append([#("data-onze-prefetch", "0")]);
    if (props.replace) pairs = pairs.append([#("data-onze-replace", "1")]);
    if (!props.scroll) pairs = pairs.append([#("data-onze-scroll", "0")]);
    if (props.target != "") pairs = pairs.append([#("target", props.target)]);
    if (props.className != "") pairs = pairs.append([#("class", props.className)]);
    return Element(tag: "a", value: "", children: children, attrs: pairs);
}
```

**Acceptance:**
- [ ] `renderToString(Link(linkProps("/about"), [text("About", attrs: [])]))` is
      `<a href="/about" data-onze-l="1">About</a>` — two attributes, in that order, matching the
      `data-onze-` family in `contracts.md § 2`
- [ ] `prefetch: false` adds `data-onze-prefetch="0"` and nothing else
- [ ] `target: "_blank"` emits a real `target` attribute, not a `data-` one
- [ ] `Link` reaches no host cell and renders identically on erlang and js

### Step 3 — Prefetch strategy and layout keys

```bp
pub fn prefetchMode(kind: string, hasLoading: bool, requested: bool) -> string {
    if (!requested) return "skip";
    if (kind == "static") return "full";
    if (hasLoading) return "partial";
    return "skip";
}

pub fn layoutKey(segments: Array<string>, depth: i32) -> string {
    return "/" + segments.take(depth).join("/");
}
```

**Acceptance:**
- [ ] every row of the prefetch table above is one assertion
- [ ] `layoutKey(["docs", "api", "use-router"], 1) == "/docs"`
- [ ] `layoutKey([], 0) == "/"`
- [ ] `prefetchMode` and `layoutKey` are pure — no host cell, no `?T` unwrap that can fail

### Step 3b — The client-navigation reconciler

```bp
// src/reconcile.bp
pub fn layoutKeys(segments: Array<string>) -> Array<string>

pub fn sharedDepth(current: Array<string>, target: Array<string>) -> i32
```

`layoutKeys` is `layoutKey` applied at every depth, root-first. `sharedDepth` is the length of the
common prefix of two such lists: everything strictly above it stays mounted, everything from it down
is replaced. Both are pure, so the whole remount decision is testable without a DOM.

The transition driver (`reconcile(current, target)`) calls them, then unmounts and mounts through
front 68's DOM primitives, adopting `data-onze-s` slots and re-anchoring `data-onze-e` boundaries.

**Acceptance:**
- [ ] `layoutKeys(["docs", "api"]) == ["/", "/docs", "/docs/api"]` — root-first, root included
- [ ] `sharedDepth(layoutKeys(["docs","api"]), layoutKeys(["docs","guides"])) == 2` — the docs layout
      is reused
- [ ] `sharedDepth(layoutKeys(["docs"]), layoutKeys(["blog"])) == 1` — only the root layout survives
- [ ] `sharedDepth` of two identical routes is the full length: a navigation to the current route
      remounts nothing
- [ ] a shared layout's islands are not re-hydrated across a transition, asserted by an island whose
      mount count is observable
- [ ] the reconciler reads front 60's route-kind flag to decide whether the target payload had to be
      fetched, and does not recompute it
- [ ] `reconcile.bp` declares no `#[@External.Erlang]` cell

### Step 4 — The browser runtime cells and `linkStatus`

```bp
#[@External.Node("jhonstart/client-runtime", "linkMount")]
pub declare fn __onzeLinkMount() -> i32;

#[@External.Node("jhonstart/client-runtime", "linkPrefetch")]
pub declare fn __onzeLinkPrefetch(href: string, mode: string) -> i32;

#[@External.Node("jhonstart/client-runtime", "linkStatus")]
declare fn __onzeLinkStatus() -> string;

#[@External.Node("jhonstart/client-runtime", "routeKind")]
declare fn __onzeLinkRouteKind(href: string) -> string;

pub type LinkStatus(pending: bool, href: string)

pub fn linkStatus() -> @Context<Element, LinkStatus> {
    val href = __onzeLinkStatus();
    return LinkStatus(pending: href != "", href: href);
}
```

**Acceptance:**
- [ ] every cell in the file is `#[@External.Node]`; there is no `#[@External.Erlang]` cell
- [ ] `linkStatus()` is idle (`pending == false`, `href == ""`) when nothing is in flight
- [ ] `use linkStatus()` type-checks inside a `#[@context] fn … -> Element` body — never the doubled `use` + `useLinkStatus()`; without the annotation the body is `use-without-context-effect` ([`19-use-activation`](../../00-compiler-carry-over/19-use-activation/README.md))
- [ ] `__onzeLinkMount()` is idempotent — calling it twice registers one listener

### Step 5 — Module wiring

front 94 owns `src/root.bp` and `botopink.json`'s `files` list; this front hands it the line(s) below rather than editing either file, and front 94 appends in front-number order: `pub mod link;` and `link.bp`. The `Link` declaration is removed from `router.d.bp` by
front 26, which deletes that file entirely — this front adds nothing to it and reads nothing from
it.

**Acceptance:**
- [ ] `pub mod link;` and the `files` entry are handed to front 94; this front edits neither file
- [ ] `git grep -n "declare fn Link"` finds nothing
- [ ] `repository/jhonstart/AGENTS.md` updated in the same commit

## Examples

- [`examples/post-list-links-example.bp`](./examples/post-list-links-example.bp) — a blog index with
  two hundred posts: prefetch is switched off for the list and left on for the two navigation links,
  which is the case § 8 *Prefetching* says to switch off.
- [`examples/pending-link-example.bp`](./examples/pending-link-example.bp) — a checkout link that
  shows a spinner while its own navigation is in flight, via `linkStatus`.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| Declared parameter defaults are never applied (`tests/language/expected-failures.txt`, `commonJS \| test/fn_defaults.bp`; `docs.md:502-505`) | `Link` would naturally be `Link(href, children, prefetch = true, replace = false, scroll = true)`; instead the props are a record and `linkProps(href)` fills the defaults | `Link(linkProps("/x"), children)` and `withPrefetch(p, false)` | apply the declared default when an argument is omitted |
| No assignment to a `self` field; a record has no copy-with-update | each `with*` helper respells all six fields to change one | a `with*` helper per field | a `Record(base, field: value)` copy-update expression |

## Test plan

`repository/jhonstart/test/link_test.bp`, run by `botopink test --target commonJS` from
`repository/jhonstart` (the default target), and in the ecosystem gate by
`zig build test-libs -- --target commonJS --lib jhonstart`.

Assertions:

1. `linkProps` defaults, and each `with*` helper changing exactly one field.
2. `renderToString(Link(…))` for each of the seven attribute rows in the table above, asserting the
   exact string for the common case and `contains` for the optional ones.
3. `prefetchMode` — four rows, four assertions.
4. `layoutKey` — shared prefix, divergent prefix, empty segments; and `layoutKeys` / `sharedDepth`
   for the reuse, partial-reuse, full-replace and same-route cases, in `test/reconcile_test.bp`.
5. `linkStatus()` idle, called directly without the `use` prefix.

The erlang row is not this front's gate, but `Link` itself is pure and does render there: one
assertion in `test/link_test.bp` renders an anchor and is expected to pass on both targets, which is
how the front proves that the server pass emits the anchor the browser runtime later finds. The four
host cells have no erlang body and are never called from the erlang row.

## Definition of done

- [ ] `link.bp` in the build tree, its `root.bp` and `files` lines handed to front 94
- [ ] `Link` renders the documented anchor and reaches no host
- [ ] `prefetchMode` implements § 8's table exactly, with a test per row
- [ ] the client-navigation reconciler ships in `src/reconcile.bp` with its own test file, and
      `layoutKeys`/`sharedDepth` are pure and asserted without a DOM
- [ ] front 68's generated entry calls `__onzeLinkMount()` once, and this README says so rather than
      attributing it to front 29
- [ ] the route-kind flag is read from front 60 and not recomputed here
- [ ] both language gaps appear in a `specs/1.0.10-beta/` spec
- [ ] the front's tests are green on its assigned target

## Carried from 1.0.7-beta F03 jhonstart-link

Items of the 1.0.7 draft not restated above, quoted so nothing is lost; where the milestone decided differently the 1.0.9 decision stands and the old text is kept for the record.

### Examples — positional `Link(href, children, prefetch: …)` (different decision)

`1.0.7-beta/03-jhonstart-link/README.md § Examples in bp`. The draft's call shape relied on declared parameter defaults, which are never applied; front 27 takes a `LinkProps` record — `Link(linkProps(href), children)` and `withPrefetch(props, false)`.

```bp
import {Link} from "jhonstart";

pub fn NavBar() -> Element {
    return nav([
        Link("/", [text("Home")]),
        Link("/blog", [text("Blog")]),
    ], attrs: []);
}
```

```bp
Link("/blog/" + post.slug, [text(post.title)], prefetch: false)
```

### Mechanism — `data-onze13-link` marker and pass-through `attrs` (different decision; one item absent)

`1.0.7-beta/03-jhonstart-link/README.md § Mechanism`. Old text:

> `Link` is a real `.bp` function that:
> 1. Renders an `<a>` element with `href` in attrs
> 2. Adds `data-onze13-link` attribute for client-side interception
> 3. Accepts `prefetch`, `replace`, `scroll` props (analogous to Next.js)

```bp
pub fn Link(href: string, children: Children, attrs: Array<#(string, string)> = []) -> Element {
    val linkAttrs = attrs + [
        #("href", href),
        #("data-onze13-link", "true"),
    ];
    return Element(tag: "a", value: "", children: children, attrs: linkAttrs);
}
```

| Old item | Front 27 |
|---|---|
| marker `data-onze13-link="true"` | `data-onze-l="1"` — the milestone's `data-onze-` family (`contracts.md § 2`) |
| `prefetch`, `replace`, `scroll` props | present as `LinkProps` fields; `target` and `className` added |
| pass-through `attrs: Array<#(string, string)> = []` merged into the anchor | **absent** — `Link` has no arbitrary-attribute parameter; only `target` and `class` can be set, through `LinkProps` |
| marker order `attrs + [href, marker]` (caller attrs first) | `[href, data-onze-l]` first, then the optional pairs |

### Step 1 — expected anchor string (different decision)

`1.0.7-beta/03-jhonstart-link/README.md § Step 1 — Link component in real .bp`

> Create `src/link.bp` with the `Link` function above.
> - `Link` renders `<a href="...">...</a>`
> - `renderToString(Link("/about", [text("About")]))` produces `<a href="/about" data-onze13-link="true">About</a>`
> - Compiles on commonJS + erlang

Front 27: `renderToString(Link(linkProps("/about"), [text("About", attrs: [])]))` is `<a href="/about" data-onze-l="1">About</a>`; renders identically on erlang and js.

### Step 2 — defaults as parameters, `data-onze13-*` attribute names and `"true"`/`"false"` values (different decision)

`1.0.7-beta/03-jhonstart-link/README.md § Step 2 — Props: prefetch, replace, scroll`

```bp
pub fn Link(
    href: string,
    children: Children,
    prefetch: bool = true,
    replace: bool = false,
    scroll: bool = true,
    attrs: Array<#(string, string)> = [],
) -> Element {
    var linkAttrs = attrs + [#("href", href), #("data-onze13-link", "true")];
    if (!prefetch) {
        linkAttrs = linkAttrs + [#("data-onze13-prefetch", "false")];
    };
    if (replace) {
        linkAttrs = linkAttrs + [#("data-onze13-replace", "true")];
    };
    if (!scroll) {
        linkAttrs = linkAttrs + [#("data-onze13-scroll", "false")];
    };
    return Element(tag: "a", value: "", children: children, attrs: linkAttrs);
}
```

| Old acceptance | Front 27 |
|---|---|
| `prefetch={false}` adds `data-onze13-prefetch="false"` | `data-onze-prefetch="0"` |
| `replace={true}` adds `data-onze13-replace="true"` | `data-onze-replace="1"` |
| `scroll={false}` adds `data-onze13-scroll="false"` | `data-onze-scroll="0"` |
| defaults `prefetch = true`, `replace = false`, `scroll = true` as parameter defaults | same values, filled by `linkProps(href)` (§ Step 1) |

### Step 3 — "or delete the file entirely" (covered; recorded for the wording)

`1.0.7-beta/03-jhonstart-link/README.md § Step 3 — Remove Link from router.d.bp`

> Remove the `Link` declaration from `router.d.bp` (or delete the file entirely if router is also promoted). Update `botopink.json`.

Front 27: front 26 deletes `router.d.bp`; `pub mod link;` and the `files` entry are handed to front 94. Acceptance rows (`Link` no longer in `router.d.bp` · `link.bp` in `botopink.json` · `root.bp` declares `pub mod link;`) are present under § Step 5 — Module wiring.

### Step 4 — tests against the old API (different decision)

`1.0.7-beta/03-jhonstart-link/README.md § Step 4 — Tests`

```bp
test "Link renders an anchor with href" {
    val el = Link("/about", [text("About")], attrs: []);
    assert renderToString(el) == "<a href=\"/about\" data-onze13-link=\"true\">About</a>";
}

test "Link with prefetch=false adds data attribute" {
    val el = Link("/blog", [text("Blog")], prefetch: false, attrs: []);
    val html = renderToString(el);
    assert html.contains("data-onze13-prefetch=\"false\"");
}
```

Old acceptance "All tests pass on commonJS + erlang". Front 27: gate is `botopink test --target commonJS`; one anchor assertion is expected on both targets; the four host cells are never called from the erlang row.

### Gate (one item absent)

`1.0.7-beta/03-jhonstart-link/README.md § Gate`

| Old gate line | Front 27 |
|---|---|
| `botopink test` green | present (§ Test plan, § Definition of done) |
| `link.bp` in `botopink.json` and `root.bp` | handed to front 94 |
| AGENTS.md updated | present (§ Step 5 acceptance) |
| Commit on `fix/jhonstart-link` | **absent** — no branch name in the new README |

### Blast radius (different decision)

`1.0.7-beta/03-jhonstart-link/README.md § Blast radius`

> - New file `link.bp` — no changes to existing files (except removing Link from router.d.bp)
> - Consumers get a real `Link` component instead of a host-bound stub

Front 27 adds two files (`src/link.bp`, `src/reconcile.bp`) and two test files; the `router.d.bp` removal belongs to front 26. The second bullet is present in § Problem.

### Notes — client interception and prefetch deferred to "a client runtime" (different decision)

`1.0.7-beta/03-jhonstart-link/README.md § Notes`

> - Client-side navigation interception (clicking the `<a>` and using `history.pushState` instead of full page load) is a client runtime concern — not implemented here. The `data-onze13-link` attribute is the hook for the client runtime to intercept.
> - Prefetching (loading the next page's data when Link enters viewport) is also a client runtime concern. The `data-onze13-prefetch` attribute signals intent.

Front 27 implements both halves in this front: `__onzeLinkMount()` (delegated click interception + intersection observer over `[data-onze-l]`), `__onzeLinkPrefetch(href, mode)` with the `prefetchMode` table, and the `src/reconcile.bp` transition. The markers are `data-onze-l` / `data-onze-prefetch`.

### Reference rows from 1.0.7 overview/fronts

| Source | Row | In front 27? |
|---|---|---|
| `overview.md` § front table | `03-jhonstart-link/` · **critical** · jhonstart · jhonstart-core · "Link component with prefetch, scroll, client-side navigation" | present in substance (§ Mechanism props table, § runtime half) |
| `overview.md` § Next.js → onze13 mapping | `next/link` → `Link component` → jhonstart | present in substance; `linkStatus` (upstream `useLinkStatus`, `use-link-status`) added |
| `overview.md` § dependency sketch | `02-jhonstart-router ──┐ ├──► 03-jhonstart-link` | present as **Depends on:** 26 |
| `fronts.md` § ownership | F03 · jhonstart · jhonstart-core · owns `repository/jhonstart/src/link.bp` · tests `repository/jhonstart/test/link_test.bp` | present in **Owns** (both paths, plus `reconcile.bp` / `reconcile_test.bp`) |
| `fronts.md` § Conflict Notes 1 | "F02 ↔ F03: Both touch `router.d.bp`/`router.bp` … Sequence: F02 first, then F03 (Link uses router)." | substance present (§ Step 5: front 26 deletes the file; this front adds nothing to it); the note itself is not restated |
| `fronts.md` § dependency graph / critical path | `F02 ──┐ └──► F03 · F04 · F09 (3 in parallel)`; critical path `F01 → F02 → F03/F04/F09`; Phase 1 `… then F03 ∥ F04 ∥ F09` | absent; replaced by **Wave:** 2 and **Depends on:** 26 · 60 · 23 · 68 · 94 |
| `README.md` header | **Does not touch:** `server.d.bp` | not listed; `src/client.bp` (front 29), `src/root.bp`, `botopink.json` are |

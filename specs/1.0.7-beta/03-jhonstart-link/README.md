# Front 03 — Jhonstart Link

**Referência Next.js:** [Link Component](https://nextjs.org/docs/app/api-reference/components/link) · [Linking and Navigating](https://nextjs.org/docs/app/getting-started/linking-and-navigating)

**Priority:** critical — Link is the primary navigation mechanism
**Depends on:** F02 (jhonstart-router)
**Owns:** `repository/jhonstart/src/link.bp`
**Does not touch:** `router.bp`, `element.bp`, `hooks.bp`, `html.bp`, `server.d.bp`

---

## Problem

`Link` is declared in `router.d.bp` as a host-bound stub. With `Element` now having an `attrs` slot and the router promoted to real `.bp` (F02), `Link` can be implemented as a real component that renders `<a href=…>` with prefetch and client-side navigation.

## Current state

- `Link` is a `declare fn` in `router.d.bp` with `#[@External.Node]` — no real implementation
- `Element` has `attrs: Array<#(string, string)>` — can carry `href`
- `renderToString` already renders attrs (`<a href="...">...</a>`)

## Exemplos em bp

### Link básico

```bp
import {Link} from "jhonstart";

pub fn NavBar() -> Element {
    return nav([
        Link("/", [text("Home")]),
        Link("/blog", [text("Blog")]),
    ], attrs: []);
}
```

### Link com prefetch

```bp
Link("/blog/" + post.slug, [text(post.title)], prefetch: false)
```

## Mechanism

`Link` is a real `.bp` function that:
1. Renders an `<a>` element with `href` in attrs
2. Adds `data-onze13-link` attribute for client-side interception
3. Accepts `prefetch`, `replace`, `scroll` props (analogous to Next.js)

```bp
pub fn Link(href: string, children: Children, attrs: Array<#(string, string)> = []) -> Element {
    val linkAttrs = attrs + [
        #("href", href),
        #("data-onze13-link", "true"),
    ];
    return Element(tag: "a", value: "", children: children, attrs: linkAttrs);
}
```

## Steps

### Step 1 — Link component in real .bp

Create `src/link.bp` with the `Link` function above.

**Acceptance:**
- [ ] `Link` renders `<a href="...">...</a>`
- [ ] `renderToString(Link("/about", [text("About")]))` produces `<a href="/about" data-onze13-link="true">About</a>`
- [ ] Compiles on commonJS + erlang

### Step 2 — Props: prefetch, replace, scroll

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

**Acceptance:**
- [ ] `prefetch={false}` adds `data-onze13-prefetch="false"`
- [ ] `replace={true}` adds `data-onze13-replace="true"`
- [ ] `scroll={false}` adds `data-onze13-scroll="false"`

### Step 3 — Remove Link from router.d.bp

Remove the `Link` declaration from `router.d.bp` (or delete the file entirely if router is also promoted). Update `botopink.json`.

**Acceptance:**
- [ ] `Link` no longer in `router.d.bp`
- [ ] `link.bp` in `botopink.json` files
- [ ] `root.bp` declares `pub mod link;`

### Step 4 — Tests

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

**Acceptance:**
- [ ] All tests pass on commonJS + erlang

## Gate

- [ ] `botopink test` green
- [ ] `link.bp` in `botopink.json` and `root.bp`
- [ ] AGENTS.md updated
- [ ] Commit on `fix/jhonstart-link`

## Blast radius

- New file `link.bp` — no changes to existing files (except removing Link from router.d.bp)
- Consumers get a real `Link` component instead of a host-bound stub

## Notes

- Client-side navigation interception (clicking the `<a>` and using `history.pushState` instead of full page load) is a client runtime concern — not implemented here. The `data-onze13-link` attribute is the hook for the client runtime to intercept.
- Prefetching (loading the next page's data when Link enters viewport) is also a client runtime concern. The `data-onze13-prefetch` attribute signals intent.

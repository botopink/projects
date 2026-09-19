# Front 02 — Jhonstart Router

**Referência Next.js:** [useRouter](https://nextjs.org/docs/app/api-reference/functions/use-router) · [useParams](https://nextjs.org/docs/app/api-reference/functions/use-params)

**Priority:** critical — without a real router, there is no navigation
**Depends on:** F01 (onze13-stand-up)
**Owns:** `repository/jhonstart/src/router.bp` (promote from `router.d.bp`)
**Does not touch:** `element.bp`, `hooks.bp`, `html.bp`, `server.d.bp`, `server.bp`

---

## Problem

jhonstart's router is declaration-only (`router.d.bp`). `useRouter` and `Link` are host-bound stubs with no real implementation. Client-side navigation, pathname tracking, and params access are all gated on generic language gaps that have since closed or can be worked around.

## Current state

- `src/router.d.bp` declares `Router` behavior + `useRouter()` + `Link()` as `#[@External.Node]` stubs
- No real `.bp` implementation exists
- `Element` model now has an `attrs` slot (landed in element.bp), so `Link` can render `href`
- Context-inference (`@Context`/`use`) is landed, so `useRouter()` can work as a hook

## Exemplos em bp

### useRouter em um componente

```bp
#[client]
import {useRouter} from "jhonstart";

pub fn Breadcrumb() -> Element {
    val router = use useRouter();
    return div([span([text("Path: " + router.pathname())])], attrs: []);
}
```

### Acessando params

```bp
pub fn BlogPost() -> Element {
    val router = use useRouter();
    val slug = router.params().get("slug");
    return div([h1([text("Post: " + slug)])], attrs: []);
}
```

## Mechanism

Promote `router.d.bp` → `router.bp` with a real implementation:
- `Router` behavior gets a concrete type `RouterState` holding pathname + params
- `useRouter()` returns `@Context<Element, Router>` backed by a host cell (commonJS: module-global state; erlang: process dictionary)
- Navigation (`push`/`replace`) updates the host cell
- The host runtime (rakun SSR pipeline, F09) provides the initial Router state from the HTTP request

## Steps

### Step 1 — Concrete RouterState type

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

**Acceptance:**
- [ ] `RouterState` implements `Router` behavior
- [ ] All 4 methods have real bodies
- [ ] Compiles on commonJS + erlang

### Step 2 — Host cells for navigation

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

**Acceptance:**
- [ ] Host cells declared for both targets
- [ ] `botopink check` passes

### Step 3 — useRouter hook

```bp
pub fn useRouter() -> @Context<Element, Router> {
    return routerGetState();
}
```

**Acceptance:**
- [ ] `useRouter()` returns `@Context<Element, Router>`
- [ ] Usable with `use` prefix in components
- [ ] Test: `val r = useRouter(); r.pathname()` returns current path

### Step 4 — Remove router.d.bp

Delete `router.d.bp` (replaced by `router.bp`). Update `botopink.json` `files` list. Update `root.bp` to include `pub mod router;`.

**Acceptance:**
- [ ] `router.d.bp` removed
- [ ] `router.bp` in `botopink.json` files
- [ ] `root.bp` declares `pub mod router;`
- [ ] All existing tests still pass

### Step 5 — Tests

```bp
test "RouterState holds pathname and params" {
    val r = RouterState(pathname: "/blog/hello", params: dict.fromList([#("slug", "hello")]), searchParams: dict.empty());
    assert r.pathname() == "/blog/hello";
    assert r.params() == dict.fromList([#("slug", "hello")]);
}
```

**Acceptance:**
- [ ] RouterState construction and method access tested
- [ ] Tests pass on commonJS + erlang

## Gate

- [ ] `botopink test` green (commonJS + erlang)
- [ ] `router.d.bp` removed, `router.bp` in its place
- [ ] `botopink.json` and `root.bp` updated
- [ ] AGENTS.md updated
- [ ] Commit on `fix/jhonstart-router`

## Blast radius

- `router.d.bp` → `router.bp` promotion: no API change for consumers (same `from "jhonstart"` import)
- `botopink.json` files list changes
- `root.bp` gains `pub mod router;`
- Examples that used `router.d.bp` declarations still compile

## Notes

- The actual navigation (push/replace) is a no-op during SSR — the host runtime (rakun) provides the initial state. Client-side navigation is the browser runtime's job (recorded follow-up for client hydration).
- `Router` behavior stays the same interface — only the implementation changes from declaration to concrete.
